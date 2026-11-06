"""Itachi (Mirage) jutsu pass v2 - WORK IN PROGRESS (first save: the current
clips ported so every clip name exists; each jutsu is then re-authored in
place)."""
import math, os
import bpy
from mathutils import Matrix, Vector
import nd_mocap, nd_anim
import itachi_p3, jutsu_itachi, common_e9
from itachi_p3 import STANCE
from jutsu_sasuke import ZERO, SEAL, seal, weave, stance_fn
from nd_shot import Shot, merge

N = "Mirage."
WANT = ("Mirage.Awaken", "Mirage.CrowGenjutsu.Channel", "Mirage.CrowGenjutsu.Recover", "Mirage.CrowGenjutsu.Release",
        "Mirage.ExplodingClone.Channel", "Mirage.ExplodingClone.Recover", "Mirage.ExplodingClone.Release",
        "Mirage.FireBloom.Channel", "Mirage.FireBloom.Hold", "Mirage.FireBloom.Recover", "Mirage.FireBloom.Release",
        "Mirage.MirageCast.Channel", "Mirage.MirageCast.Recover", "Mirage.MirageCast.Release",
        "Mirage.NeedleFan.Channel", "Mirage.NeedleFan.Recover", "Mirage.NeedleFan.Release",
        "Mirage.PhoenixSageFire.Channel", "Mirage.PhoenixSageFire.Recover", "Mirage.PhoenixSageFire.Release",
        "Mirage.Read.Channel", "Mirage.Read.Recover", "Mirage.Read.Release", "Mirage.Throw", "Mirage.Throw.Shuriken")
s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]


# ================================================== captures -> control rig
# nd_mocap bakes a capture onto the DEFORM rig (joint quaternions); the jutsu
# are authored on the CONTROL rig (nd_ctrl: root/torso/head angles, arm
# raise/out/twist, world feet). cap() reads the same track and inverts the
# control rig's own formulas (nd_anim.ori = Rx Ry Rz of the negated angles,
# nd_anim.arm_rot = Rx(raise) Rz(out) Ry(twist)), so a capture frame becomes
# an ordinary pose spec: it can be keyed, merged with Itachi's carriage and
# blended with key poses like any other.
MIXAMO = os.environ.get("ND_MIXAMO", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo")
_CAPS = {}
D = math.degrees


def _ori(m):
    e = m.to_euler("ZYX")          # m = Rx(x) Ry(y) Rz(z)
    return {"pitch": -D(e.x), "yaw": -D(e.y), "roll": -D(e.z)}


def _arm(side, qs, qe, qw):
    k = 1 if side == "R" else -1
    e = qs.to_matrix().to_euler("YZX")     # Rx(raise) Rz(out) Ry(twist)
    el = qe.to_matrix().to_euler("YZX")
    w = qw.to_matrix().to_euler("ZYX")
    return {"raise": D(e.x), "out": D(e.z) * k, "twist": D(e.y) * k, "elbow": D(el.x), "wrist": D(w.x), "wroll": D(w.z) * k}


def _foot(side, root, Rr, qh, qk, qa):
    k = 1 if side == "R" else -1
    Rh = Rr @ qh.to_matrix()
    Rk = Rh @ qk.to_matrix()
    Ra = Rk @ qa.to_matrix()
    hip = root + Rr @ Vector((.5 * k, -.55, 0))
    ank = hip + Rh @ Vector((0, -nd_anim.L1, 0)) + Rk @ Vector((0, -nd_anim.L2, 0))
    e = Ra.to_euler("XYZ")                 # Ry(-yaw) Rx(toe)
    return {"x": ank.x - .5 * k, "y": ank.y + 2.6, "z": ank.z, "yaw": -D(e.y), "toe": D(e.x)}


def cap(key, yaw=0.0):
    """The capture `key` as a list of control-rig specs (one per capture
    frame, 30 fps), turned `yaw` degrees about the vertical; the hips' x/z
    are relative to the first frame."""
    if (key, yaw) in _CAPS:
        return _CAPS[(key, yaw)]
    scene = bpy.context.scene
    fps, frame = scene.render.fps, scene.frame_current
    objs, acts = set(bpy.data.objects), set(bpy.data.actions)
    src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
    tr = nd_mocap.track(src, s0, s1, "full")
    for o in set(bpy.data.objects) - objs:
        bpy.data.objects.remove(o, do_unlink=True)
    for a in set(bpy.data.actions) - acts:
        bpy.data.actions.remove(a)
    scene.render.fps = fps
    scene.frame_set(frame)
    turn = nd_anim.R(0, -yaw, 0)
    q = tr["q"]
    x0, z0 = tr["loc"][0].x, tr["loc"][0].z
    out = []
    for i in range(len(tr["loc"])):
        loc = tr["loc"][i]
        p = turn @ Vector((loc.x - x0, loc.y, loc.z - z0))
        Rr = turn @ q["Root"][i].to_matrix()
        spec = {"root": dict(_ori(Rr), x=p.x, y=p.y, z=p.z),
                "torso": _ori(q["Waist"][i].to_matrix()), "head": _ori(q["Neck"][i].to_matrix()),
                "ra": _arm("R", q["Right"][i], q["RightElbow"][i], q["RightWrist"][i]),
                "la": _arm("L", q["Left"][i], q["LeftElbow"][i], q["LeftWrist"][i])}
        for side, f, n in (("R", "rf", "Right"), ("L", "lf", "Left")):
            spec[f] = _foot(side, p, Rr, q[n + "Hip"][i], q[n + "Knee"][i], q[n + "Ankle"][i])
        out.append(spec)
    _CAPS[(key, yaw)] = out
    return out


def mix(a, b, w):
    """a -> b by w (0..1), channel by channel (numbers only)."""
    out = {}
    for part in set(a) | set(b):
        pa, pb = a.get(part, {}), b.get(part, {})
        out[part] = {}
        for k in set(pa) | set(pb):
            va, vb = pa.get(k, pb.get(k, 0)), pb.get(k, pa.get(k, 0))
            out[part][k] = va + (vb - va) * w
    return out


def sample(c, x):
    """Capture spec at fractional capture frame x."""
    x = min(max(x, 0), len(c) - 1)
    i = int(math.floor(x))
    j = min(len(c) - 1, i + 1)
    return mix(c[i], c[j], x - i)


def warp_time(src, dst, t):
    """Piecewise-linear: output frame t -> capture frame (src/dst marks)."""
    for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
        if b0 <= t <= b1:
            return a0 + (a1 - a0) * (t - b0) / max(b1 - b0, 1e-6)
    return src[-1] if t > dst[-1] else src[0]


# ================================================================ helpers
def cut(arm, prefix, keys, fa, rel_end, marker=None, drags=()):
    """One continuous act after the channel (frame 0 = the channel's last
    pose), cut the way the game plays it (jutsu_sasuke.act, with the clip
    lengths and markers kept exactly): the Release is frames 0..rel_end, the
    Recover the same timeline from the Active frame `fa` to the last key,
    re-based at 0 - both clips meet on the same pose at the same speed."""
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    for need in (fa, rel_end):
        if need not in frames:
            raise ValueError("%s: no key on frame %d (keys %s)" % (prefix, need, frames))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    re = Shot(arm, prefix + ".Release")
    rc = Shot(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= rel_end:
            re.key(f, p, sp)
        if f == fa:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif f > fa:
            rc.key(f - fa, p, sp)
    for bones, n in drags:
        re.drag(bones, n)
        rc.drag(bones, n)
    return [re.build(markers={} if marker is None else {"release": marker / 60}), rc.build()]


def facing(spec):
    """The head yaw that keeps the eyes on him (world yaw 0) over this body."""
    r, t = spec.get("root", {}), spec.get("torso", {})
    return -(r.get("yaw", 0) + t.get("yaw", 0))


def look(spec, extra=0.0, pitch=None):
    """spec with the head turned back onto him (+ extra)."""
    h = {"yaw": facing(spec) + extra}
    if pitch is not None:
        h["pitch"] = pitch
    return merge(spec, {"head": h})


# One-hand tiger (index and middle fingers up) at the sternum, either hand.
TIGER_R = {"raise": 32.2, "out": -20.2, "twist": 58.6, "elbow": 102.7, "wrist": 0}
TIGER_L = dict(TIGER_R)
# The right hand's two fingers before the lips (the fire is breathed through them).
MOUTH_R = {"raise": 84, "out": -34, "twist": 52, "elbow": 134, "wrist": 10}


# ============================================================ FireBloom
def fire_bloom(arm):
    """Katon: Great Fireball (ch .3, Hold while charged, act .42, rec .36)."""
    out = []
    ch = Shot(arm, N + "FireBloom.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.36, "z": .04, "pitch": 6}, "torso": {"pitch": 4}, "head": {"pitch": -2}})
    last = weave(ch, 0, (2, 1), base, beat=5)        # snake (5), tiger (10)
    # the tiger rises with the breath: the chest fills, the hips sit back over
    # the anchored rear foot, the chin lifts; the front toes come off the floor
    rise = s({"root": {"y": -.34, "z": .12, "pitch": -2, "yaw": 30}, "torso": {"pitch": -8, "yaw": -12},
              "head": {"pitch": -12, "yaw": -16}, "ra": merge(SEAL[1]["ra"], {"raise": 56}), "la": merge(SEAL[1]["la"], {"raise": 56})})
    ch.key(last + 4, rise, "pass")
    inhale = s({"root": {"y": -.32, "z": .2, "pitch": -8, "yaw": 32}, "torso": {"pitch": -16, "yaw": -14},
                "head": {"pitch": -20, "yaw": -16}, "ra": merge(SEAL[1]["ra"], {"raise": 64}), "la": merge(SEAL[1]["la"], {"raise": 64}),
                "lf": {"toe": 10}})
    ch.key(18, inhale, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 18 / 60}))

    # Hold (charging, loops): the breath keeps filling - two slow swells, the
    # chest higher and further back on each, the hands rising with it.
    ho = Shot(arm, N + "FireBloom.Hold")
    deeper = merge(inhale, {"root": {"y": -.3, "z": .24, "pitch": -10}, "torso": {"pitch": -19}, "head": {"pitch": -24},
                            "ra": {"raise": 68}, "la": {"raise": 68}, "lf": {"toe": 12}})
    ho.key(0, inhale, "ease")
    ho.key(20, deeper, "ease")
    ho.key(40, inhale, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))

    # The blow: the hips drive forward over the front foot, the chest and the
    # head follow (the head last), the right hand brings two fingers to the
    # lips while the left arm swings back and out for the balance; the rear
    # heel comes up. The fire pours through the whole Active window: the body
    # keeps pushing into it (two pushes), then it lifts out of the lean.
    blow = s({"root": {"y": -.5, "z": -.26, "pitch": 16, "yaw": 22}, "torso": {"pitch": 12, "yaw": -6},
              "head": {"pitch": -22, "yaw": -14},
              "ra": MOUTH_R, "la": {"raise": -26, "out": 34, "twist": 10, "elbow": 26, "wrist": 10},
              "rf": {"y": .06, "toe": -16}, "lf": {"toe": 0}})
    push = merge(blow, {"root": {"z": -.32, "pitch": 19, "y": -.52}, "torso": {"pitch": 14}, "head": {"pitch": -24},
                        "la": {"raise": -32, "out": 38}})
    give = merge(blow, {"root": {"z": -.24, "pitch": 15}, "torso": {"pitch": 10}, "head": {"pitch": -20}})
    keys = [(0, inhale, "ease"),
            (2, merge(inhale, {"root": {"z": .08, "pitch": 2, "y": -.38}, "torso": {"pitch": -6},
                               "ra": {"raise": 72, "out": -26, "twist": 48, "elbow": 124}, "la": {"raise": 30, "out": 0, "elbow": 70}}), "pass"),
            (4, blow, "impact"),
            (8, push, "ease"),
            (13, give, "ease"),
            (19, merge(push, {"root": {"z": -.34, "pitch": 20}, "torso": {"pitch": 15}}), "ease"),
            (24, merge(push, {"root": {"z": -.3, "pitch": 16, "y": -.5}, "torso": {"pitch": 10}, "head": {"pitch": -18}}), "pass"),
            (31, s({"root": {"y": -.38, "z": -.06, "pitch": 4}, "torso": {"pitch": 0}, "head": {"pitch": -8},
                    "ra": {"raise": 46, "out": -6, "twist": 10, "elbow": 96, "wrist": 0},
                    "la": {"raise": 20, "out": 20, "twist": 0, "elbow": 44, "wrist": 0}, "rf": {"y": 0, "toe": 0}}), "pass"),
            (39, s({"root": {"y": -.27, "z": .06, "pitch": 2}, "head": {"pitch": -6}}), "ease"),
            (46, s(), "ease")]
    out += cut(arm, N + "FireBloom", keys, 24, 24, marker=4,
               drags=[(["neck"], 1), (["shoulder.L", "forearm.L", "hand.L"], 1)])
    return out


# ======================================================= PhoenixSageFire
def breath(sweep, pump):
    """Phoenix Sage Fire's breath: `sweep` -1 (far left) .. 1 (right) across
    the fan - the head leads, the chest and hips follow less - and `pump`
    0..1 the push of one puff (the chest snaps forward, the chin drops)."""
    return s({"root": {"y": -.42 - .03 * pump, "z": -.06 - .06 * pump, "pitch": 6 + 4 * pump, "yaw": 22 + 16 * sweep},
              "torso": {"pitch": 4 + 6 * pump, "yaw": -14 + 22 * sweep},
              "head": {"pitch": -14 - 4 * pump, "yaw": -8 + 24 * sweep},
              "ra": MOUTH_R,
              "la": {"raise": 26 - 14 * sweep, "out": 30 - 10 * sweep, "twist": 0, "elbow": 40 + 20 * sweep, "wrist": 0}})


def phoenix(arm):
    """Katon: Phoenix Sage Fire (ch .3, act .2, rec .3)."""
    out = []
    ch = Shot(arm, N + "PhoenixSageFire.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.36}, "head": {"pitch": -2}})
    last = weave(ch, 0, (4, 1), base, beat=5)        # rat (5), tiger (10)
    # the left hand falls away, the right keeps two fingers up and carries
    # them to the lips; the inhale winds the body to the far left of the fan
    ch.key(last + 5, s({"root": {"y": -.4, "z": .08, "pitch": -2, "yaw": 12}, "torso": {"pitch": -8, "yaw": -24},
                        "head": {"pitch": -8, "yaw": -18}, "ra": MOUTH_R,
                        "la": {"raise": 30, "out": 20, "twist": 10, "elbow": 60, "wrist": 0}}), "pass")
    wind = s({"root": {"y": -.4, "z": .12, "pitch": -4, "yaw": 4}, "torso": {"pitch": -12, "yaw": -34},
              "head": {"pitch": -16, "yaw": -28}, "ra": MOUTH_R,
              "la": {"raise": 34, "out": 44, "twist": 0, "elbow": 30, "wrist": 0}, "lf": {"toe": 6}})
    ch.key(21, wind, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.L", "forearm.L", "hand.L"], 2)
    out.append(ch.build(markers={"release": 21 / 60}))

    # ONE breath swept left to right (Active .2), three pushes of the chest
    # riding on it: the fireballs fan out with the sweep. The left arm
    # swings across the other way (it balances the turn).
    keys = [(0, wind, "ease"),
            (2, breath(-1.0, 1.0), "impact"),
            (4, breath(-.6, .2), "pass"),
            (6, breath(-.1, 1.0), "impact"),
            (8, breath(.3, .2), "pass"),
            (10, breath(.75, 1.0), "impact"),
            (12, breath(1.0, .4), "pass"),
            (16, breath(1.1, 0), "ease"),
            (22, s({"root": {"y": -.36, "z": .0, "yaw": 30}, "torso": {"yaw": -4}, "head": {"pitch": -6, "yaw": -12},
                    "ra": {"raise": 40, "out": -4, "twist": 20, "elbow": 96, "wrist": 0},
                    "la": {"raise": 40, "out": 6, "twist": 0, "elbow": 46, "wrist": 4}}), "pass"),
            (30, s(), "ease")]
    out += cut(arm, N + "PhoenixSageFire", keys, 12, 16, marker=2, drags=[(["neck"], 1), (["shoulder.L", "forearm.L", "hand.L"], 1)])
    return out


# ============================================================ NeedleFan
def needle_fan(arm):
    """Shadow Shuriken (ch .26, act .08, rec .26)."""
    out = []
    ch = Shot(arm, N + "NeedleFan.Channel")
    ch.key(0, s(), "ease")
    # both hands to the pouches: the right draws five blades, the left two
    ch.key(5, s({"root": {"y": -.4, "z": .04, "pitch": 6, "yaw": 22}, "torso": {"pitch": 6, "yaw": -14},
                 "head": {"pitch": -2, "yaw": -8},
                 "ra": {"raise": -24, "out": 22, "twist": -10, "elbow": 70, "wrist": 10},
                 "la": {"raise": -6, "out": 4, "twist": 30, "elbow": 80, "wrist": 0}}), "pass")
    # the coil: the hips turn away, the chest further, the right arm wound
    # flat across the body (the blades fanned at the left hip), the left hand
    # low behind it; the knees sink, the eyes stay on him
    coil = look(s({"root": {"y": -.54, "z": .06, "pitch": 10, "yaw": 2, "roll": -2}, "torso": {"pitch": 8, "yaw": -26, "roll": -2},
                   "head": {"pitch": -8},
                   "ra": {"raise": 46, "out": -54, "twist": 30, "elbow": 112, "wrist": 26},
                   "la": {"raise": -16, "out": 20, "twist": 20, "elbow": 56, "wrist": 0},
                   "lf": {"toe": 0}, "rf": {"toe": 0}}), -4)
    ch.key(11, coil, "ease")
    tight = merge(coil, {"root": {"y": -.57}, "torso": {"yaw": -30}, "head": {"yaw": facing(coil) + 2},
                         "ra": {"out": -58, "elbow": 116}})
    ch.key(15, tight, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 15 / 60}))

    # The fan (Active .08): the hips unwind first, the chest after, the arm
    # last - it whips out flat and wide across the front and the wrist snaps
    # (the five leave on the snap); the weight goes onto the front foot, the
    # rear heel lifts. The arm stays out a beat (the blades fly), then the
    # LEFT hand flicks the two hidden ones low, and he gathers into the stance.
    unwind = s({"root": {"y": -.5, "z": -.02, "pitch": 10, "yaw": 22}, "torso": {"pitch": 6, "yaw": -18},
                "head": {"pitch": -8, "yaw": -4},
                "ra": {"raise": 70, "out": -30, "twist": 20, "elbow": 84, "wrist": 30},
                "la": {"raise": -24, "out": 24, "twist": 20, "elbow": 44, "wrist": 0}})
    fan = look(s({"root": {"y": -.46, "z": -.14, "pitch": 10, "yaw": 36}, "torso": {"pitch": 4, "yaw": 2},
                  "head": {"pitch": -8},
                  "ra": {"raise": 86, "out": 46, "twist": -10, "elbow": 8, "wrist": -30},
                  "la": {"raise": -34, "out": 30, "twist": 10, "elbow": 30, "wrist": 0},
                  "rf": {"y": .04, "toe": -14}}))
    follow = merge(fan, {"root": {"yaw": 40, "z": -.16}, "torso": {"yaw": 6}, "head": {"yaw": facing(fan) - 8},
                         "ra": {"raise": 84, "out": 66, "wrist": -40, "elbow": 4}})
    over = merge(follow, {"root": {"yaw": 42}, "torso": {"yaw": 8}, "ra": {"raise": 80, "out": 74, "wrist": -44}})
    held = merge(over, {"root": {"y": -.47, "z": -.14}, "ra": {"raise": 78, "out": 72, "elbow": 10, "wrist": -36}})
    hidden = look(merge(held, {"root": {"yaw": 30, "z": -.1}, "torso": {"yaw": -6},
                               "ra": {"raise": 56, "out": 56, "elbow": 30, "wrist": -14},
                               "la": {"raise": 64, "out": 18, "twist": -16, "elbow": 10, "wrist": -34},
                               "rf": {"y": 0, "toe": 0}}))
    keys = [(0, tight, "ease"),
            (2, unwind, "pass"),
            (4, fan, "impact"),
            (5, follow, "pass"),
            (7, over, "ease"),
            (10, held, "ease"),
            (14, hidden, "impact"),
            (17, merge(hidden, {"la": {"raise": 60, "out": 22, "wrist": -40}, "ra": {"raise": 40, "out": 40, "elbow": 44}}), "ease"),
            (21, s(), "ease")]
    out += cut(arm, N + "NeedleFan", keys, 5, 10, marker=4, drags=[(["neck"], 1), (["hand.R"], 1)])
    return out


# ========================================================= CrowGenjutsu
def crows(arm):
    """Genjutsu: Crows (ch .14, act .1, rec .3)."""
    out = []
    ch = Shot(arm, N + "CrowGenjutsu.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.36}, "head": {"pitch": -2}})
    last = weave(ch, 0, (1, 2), base, beat=4)        # tiger (4), snake (8)
    # the left hand keeps a one-hand seal at the sternum (the genjutsu); the
    # right gathers low across to the left hip, the body coils over it
    gather = look(s({"root": {"y": -.46, "z": .06, "pitch": 8, "yaw": 12}, "torso": {"pitch": 8, "yaw": -22, "roll": -3},
                     "head": {"pitch": 2},
                     "ra": {"raise": 18, "out": -40, "twist": 64, "elbow": 74, "wrist": 16},
                     "la": TIGER_L}), 4)
    ch.key(14, gather, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 14 / 60}))

    # The release (Active .1): the hips rise and turn first, the elbow leads
    # the arm up across the body, the forearm follows, the hand opens last -
    # one rising arc from the left hip to high on the right, the palm turned
    # out as the crows pour from the sleeve. The chest opens with it; the head
    # does not move (the genjutsu is in the eyes). The arm hangs there, then
    # floats down like a wing settling.
    lead = look(s({"root": {"y": -.4, "z": .02, "pitch": 4, "yaw": 22}, "torso": {"pitch": 4, "yaw": -12},
                   "head": {"pitch": 0},
                   "ra": {"raise": 70, "out": -16, "twist": 40, "elbow": 96, "wrist": 30},
                   "la": TIGER_L}))
    sweep = look(s({"root": {"y": -.28, "z": -.06, "pitch": 0, "yaw": 34}, "torso": {"pitch": -6, "yaw": 2},
                    "head": {"pitch": -2},
                    "ra": {"raise": 128, "out": 42, "twist": -30, "elbow": 22, "wrist": 0},
                    "la": TIGER_L, "rf": {"y": .02, "toe": -8}}))
    open_ = merge(sweep, {"root": {"y": -.26}, "torso": {"pitch": -8},
                          "ra": {"raise": 138, "out": 54, "twist": -40, "elbow": 10, "wrist": -34}})
    over = merge(open_, {"ra": {"raise": 142, "out": 60, "elbow": 6, "wrist": -42}})
    hang = merge(open_, {"root": {"y": -.28}, "ra": {"raise": 136, "out": 60, "elbow": 10, "wrist": -36}})
    keys = [(0, gather, "ease"),
            (2, lead, "pass"),
            (4, sweep, "impact"),
            (6, open_, "pass"),
            (8, over, "ease"),
            (10, hang, "ease"),
            (15, merge(hang, {"root": {"y": -.32}, "torso": {"pitch": -4},
                              "ra": {"raise": 104, "out": 72, "twist": -30, "elbow": 22, "wrist": -12}}), "pass"),
            (19, s({"root": {"y": -.32}, "ra": {"raise": 46, "out": 46, "twist": -20, "elbow": 40, "wrist": 0},
                    "la": {"raise": 46, "out": -4, "twist": 20, "elbow": 60, "wrist": 0}}), "pass"),
            (24, s(), "ease")]
    out += cut(arm, N + "CrowGenjutsu", keys, 6, 10, marker=4,
               drags=[(["hand.R"], 2), (["forearm.R"], 1), (["neck"], 1)])
    return out


# ===================================================== SharinganParalysis
def paralysis(arm):
    """Sharingan: Paralysis (ch .3, act .06, rec .24)."""
    out = []
    ch = Shot(arm, N + "SharinganParalysis.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.34}, "head": {"pitch": -2}})
    last = weave(ch, 0, (3, 4), base, beat=5)        # ram (5), rat (10)
    # the left hand leaves the seal and draws back by the ear, open; the
    # weight sits back, the chin lowers (he looks from under the brow)
    ch.key(last + 5, look(s({"root": {"y": -.38, "z": .08, "pitch": 0, "yaw": 22}, "torso": {"pitch": -2, "yaw": -10},
                             "head": {"pitch": 4},
                             "la": {"raise": 104, "out": 26, "twist": -20, "elbow": 112, "wrist": -10},
                             "ra": {"raise": 6, "out": 18, "twist": -24, "elbow": 58, "wrist": -6}})), "pass")
    cock = look(s({"root": {"y": -.4, "z": .14, "pitch": -2, "yaw": 20}, "torso": {"pitch": -4, "yaw": -12},
                   "head": {"pitch": 8},
                   "la": {"raise": 118, "out": 34, "twist": -36, "elbow": 118, "wrist": -20},
                   "ra": {"raise": 0, "out": 18, "twist": -24, "elbow": 54, "wrist": -6}, "lf": {"toe": 6}}))
    ch.key(20, cock, "ease")
    ch.drag(["neck"], 2)
    out.append(ch.build(markers={"release": 20 / 60}))

    # The stare (Active .06): the open hand is thrust at his eyes, fingers
    # spread, the body leaning in behind it and the chin down - then held,
    # the hand pressing a hair further, and it comes back slowly, the head last.
    thrust = look(s({"root": {"y": -.44, "z": -.2, "pitch": 9, "yaw": 16}, "torso": {"pitch": 5, "yaw": -4},
                     "head": {"pitch": 10},
                     "la": {"raise": 96, "out": -4, "twist": -70, "elbow": 6, "wrist": -62},
                     "ra": {"raise": -6, "out": 20, "twist": -24, "elbow": 50, "wrist": -6},
                     "rf": {"y": .03, "toe": -10}, "lf": {"toe": 0}}))
    press = merge(thrust, {"root": {"z": -.24, "pitch": 11}, "la": {"elbow": 0, "raise": 98, "wrist": -66}})
    keys = [(0, cock, "ease"),
            (2, merge(cock, {"root": {"z": .02, "pitch": 4}, "la": {"raise": 104, "out": 14, "twist": -50, "elbow": 60, "wrist": -40}}), "pass"),
            (4, thrust, "impact"),
            (7, press, "ease"),
            (9, merge(press, {"root": {"z": -.23}}), "ease"),
            (14, merge(thrust, {"root": {"z": -.08, "pitch": 5}, "head": {"pitch": 8},
                                "la": {"raise": 74, "out": -2, "twist": -46, "elbow": 40, "wrist": -26}, "rf": {"y": 0, "toe": 0}}), "pass"),
            (19, s(), "ease")]
    out += cut(arm, N + "SharinganParalysis", keys, 4, 9, marker=4, drags=[(["neck"], 3), (["hand.L"], 1)])
    return out


# ========================================================= ExplodingClone
def clone(arm):
    """Exploding Clone (ch .04, act .04, rec .2; the counter stance .9)."""
    out = []
    ch = Shot(arm, N + "ExplodingClone.Channel")
    ch.key(0, s(), "ease")
    # (a .04 s channel: the seals were woven on the presses; here the ram
    # snaps shut on a dip of the knees)
    ch.key(3, s({"root": {"y": -.38}, "torso": {"pitch": 4}, "head": {"pitch": 2},
                 "ra": {"raise": 40, "out": -8, "twist": 40, "elbow": 100, "wrist": 0},
                 "la": {"raise": 26, "out": -10, "twist": 40, "elbow": 104, "wrist": 0}}), "pass")
    sealed = merge(s({"root": {"y": -.46}}), seal(3, s({"root": {"y": -.46}})))
    ch.key(6, sealed, "impact")
    out.append(ch.build(markers={"release": 6 / 60}))

    # The bait: the seal parts, he rises tall and opens - chest up, chin a
    # touch high, the left hand low and open to the side (« come »), the
    # right keeping its one-hand seal hidden at the hip (the clone is primed)
    # - a breath of stillness, then the stance.
    bait = look(s({"root": {"y": -.12, "z": .04, "pitch": -3, "yaw": 22}, "torso": {"pitch": -6, "yaw": -6},
                   "head": {"pitch": -6},
                   "la": {"raise": 12, "out": 36, "twist": -36, "elbow": 20, "wrist": -14},
                   "ra": {"raise": -8, "out": 6, "twist": 46, "elbow": 92, "wrist": 0}}))
    keys = [(0, sealed, "ease"),
            (2, merge(sealed, {"root": {"y": -.36}, "torso": {"pitch": 2},
                               "la": {"raise": 30, "out": 10, "twist": 0, "elbow": 60, "wrist": 0},
                               "ra": {"raise": 20, "out": -4, "twist": 44, "elbow": 96, "wrist": 0}}), "pass"),
            (5, merge(bait, {"root": {"y": -.1}, "torso": {"pitch": -7}, "la": {"out": 40}}), "impact"),
            (9, bait, "ease"),
            (14, s(), "ease")]
    out += cut(arm, N + "ExplodingClone", keys, 2, 9, marker=2, drags=[(["neck"], 1), (["shoulder.L", "forearm.L", "hand.L"], 1)])
    return out


# ============================================================ MirageCast
def mirage_cast(arm):
    """Genjutsu: Mirage (ch .42, act .06, rec .2): his image stays, he
    withdraws behind it (the server carries him back)."""
    out = []
    ch = Shot(arm, N + "MirageCast.Channel")
    ch.key(0, s(), "ease")
    seal1 = look(s({"root": {"y": -.32, "z": .02, "yaw": 24}, "torso": {"yaw": -8}, "head": {"pitch": 2},
                    "ra": {"raise": 100, "out": -40, "twist": 30, "elbow": 128, "wrist": 0},
                    "la": {"raise": 6, "out": 16, "twist": 0, "elbow": 22, "wrist": 0}}))
    ch.key(6, s({"root": {"y": -.34}, "ra": {"raise": 56, "out": -6, "twist": 30, "elbow": 112, "wrist": 10},
                 "la": {"raise": 28, "out": 10, "twist": 0, "elbow": 30, "wrist": 0}}), "pass")
    ch.key(12, merge(seal1, {"ra": {"raise": 104, "elbow": 132}, "root": {"y": -.34}}), "ease")
    ch.key(19, merge(seal1, {"root": {"y": -.36}, "head": {"pitch": 5}}), "ease")
    still = merge(seal1, {"root": {"y": -.37}, "head": {"pitch": 6}, "ra": {"raise": 104, "elbow": 124}})
    ch.key(25, still, "ease")
    ch.drag(["neck"], 2)
    out.append(ch.build(markers={"release": 25 / 60}))

    # The withdrawal: the hips go back first, the chest after, the hand
    # holding the seal stays on the image's line a beat, then lowers.
    away = merge(still, {"root": {"z": .22, "pitch": -6, "y": -.38}, "torso": {"pitch": -4}, "head": {"pitch": 8},
                         "lf": {"toe": 12}})
    keys = [(0, still, "ease"),
            (4, merge(still, {"root": {"z": .14, "pitch": -4}, "torso": {"pitch": -2}, "lf": {"toe": 8}}), "pass"),
            (8, away, "ease"),
            (12, merge(away, {"root": {"z": .1, "pitch": -2}, "ra": {"raise": 60, "out": -10, "elbow": 100},
                              "lf": {"toe": 0}}), "pass"),
            (18, s(), "ease")]
    out += cut(arm, N + "MirageCast", keys, 4, 8, marker=None, drags=[(["neck"], 1)])
    return out


# ================================================================== Read
def read(arm):
    """Sharingan Read (ch .1, act 1.0 held, rec .2)."""
    out = []
    ch = Shot(arm, N + "Read.Channel")
    ch.key(0, s(), "ease")
    invite = look(s({"root": {"y": -.36, "z": .1, "pitch": 0, "yaw": 30}, "torso": {"pitch": -2, "yaw": -8},
                     "head": {"pitch": -4},
                     "la": {"raise": 58, "out": 20, "twist": 64, "elbow": 18, "wrist": -26},
                     "ra": {"raise": -2, "out": 16, "twist": -20, "elbow": 74, "wrist": 0}}))
    ch.key(6, invite, "ease")
    out.append(ch.build(markers={"release": 6 / 60}))
    # Held for the read (1 s): the open hand beckons him twice (the fingers
    # curl and open), the weight drifts back onto the rear leg, ready to slip.
    re = Shot(arm, N + "Read.Release")
    beck = merge(invite, {"la": {"elbow": 34, "wrist": 30}})
    re.key(0, invite, "ease")
    re.key(10, beck, "ease")
    re.key(18, merge(invite, {"root": {"z": .12}}), "ease")
    re.key(30, merge(beck, {"root": {"z": .14, "y": -.37}, "la": {"elbow": 28, "wrist": 16}}), "ease")
    re.key(40, merge(invite, {"root": {"z": .15, "y": -.37}}), "ease")
    re.key(60, merge(invite, {"root": {"z": .16, "y": -.38}, "head": {"pitch": -2}}), "ease")
    re.drag(["hand.L"], 2).drag(["neck"], 3)
    out.append(re.build())
    rc = Shot(arm, N + "Read.Recover")
    rc.key(0, merge(invite, {"root": {"z": .16, "y": -.38}, "head": {"pitch": -2}}), "ease")
    rc.key(5, merge(invite, {"root": {"z": .08, "y": -.34}, "la": {"raise": 56, "out": 8, "twist": 20, "elbow": 30, "wrist": 0}}), "pass")
    rc.key(12, s(), "ease")
    out.append(rc.build())
    return out


# ================================================================ Awaken
def awaken(arm):
    """Sharingan focus (0.8 s)."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    sh.key(8, s({"root": {"y": -.34, "pitch": 4}, "head": {"pitch": 8},
                 "la": {"raise": 90, "out": -22, "twist": 20, "elbow": 112, "wrist": 0}}), "pass")
    cover = s({"root": {"y": -.38, "pitch": 7}, "torso": {"pitch": 6}, "head": {"pitch": 18},
               "la": {"raise": 118, "out": -44, "twist": 20, "elbow": 140, "wrist": 0},
               "ra": {"raise": -6, "out": 18, "twist": -24, "elbow": 56, "wrist": -6}})
    sh.key(15, cover, "ease")
    sh.key(22, merge(cover, {"root": {"y": -.4}, "head": {"pitch": 20}}), "ease")
    sh.key(29, s({"root": {"y": -.44, "pitch": 3}, "torso": {"pitch": -2}, "head": {"pitch": -10},
                  "la": {"raise": 72, "out": 52, "twist": -20, "elbow": 24, "wrist": -20}}), "impact")
    sh.key(35, s({"root": {"y": -.45, "pitch": 3}, "torso": {"pitch": -3}, "head": {"pitch": -9},
                  "la": {"raise": 62, "out": 56, "twist": -20, "elbow": 26, "wrist": -24}}), "ease")
    sh.key(48, s({"root": {"y": -.42}, "head": {"pitch": -6}}), "ease")
    sh.drag(["neck"], 2).drag(["hand.L"], 1)
    return sh.build()


# ====================================================== Throw.Shuriken
def throw_shuriken(arm):
    """The tool throw (upper body over the legs' own motion; release .1167):
    the right hand takes the blades across to the left shoulder, the chest
    winds, then a flat backhand flick opens the arm at him; the left hand
    points the line and pulls back as the right goes."""
    sh = Shot(arm, N + "Throw.Shuriken")
    sh.key(0, s(), "ease")
    wind = s({"root": {"yaw": 32}, "torso": {"pitch": 6, "yaw": -30}, "head": {"yaw": 14},
              "ra": {"raise": 52, "out": -50, "twist": 10, "elbow": 120, "wrist": 30},
              "la": {"raise": 70, "out": 12, "twist": -6, "elbow": 20, "wrist": 0}})
    sh.key(4, wind, "ease")
    rel = s({"root": {"yaw": 22}, "torso": {"pitch": 4, "yaw": 4}, "head": {"yaw": -20},
             "ra": {"raise": 86, "out": 36, "twist": -6, "elbow": 6, "wrist": -34},
             "la": {"raise": 40, "out": -8, "twist": 0, "elbow": 56, "wrist": 0}})
    sh.key(7, rel, "impact")
    sh.key(10, merge(rel, {"torso": {"yaw": 10}, "ra": {"raise": 82, "out": 48, "wrist": -44}}), "ease")
    sh.key(18, s(), "ease")
    sh.drag(["hand.R"], 1)
    return sh.build(markers={"release": 7 / 60})


def author(arm):
    acts = []
    acts += read(arm)
    acts += needle_fan(arm)
    acts += mirage_cast(arm)
    acts += fire_bloom(arm)
    acts.append(throw_shuriken(arm))
    acts.append(awaken(arm))
    acts += crows(arm)
    acts += clone(arm)
    acts += paralysis(arm)
    acts += phoenix(arm)
    acts.append(common_e9.throw(arm, N, merge(ZERO, STANCE)))
    names = {a.name for a in acts}
    missing = [n for n in WANT if n not in names]
    if missing:
        print("MISSING", missing)
    return [a for a in acts if a.name in WANT]
