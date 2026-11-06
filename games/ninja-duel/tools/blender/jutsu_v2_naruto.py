"""Naruto (Legion) jutsu pass v2 -- WORK IN PROGRESS (the current clips are
ported so every clip name exists; each jutsu is replaced by its v2 version,
one by one).
"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import bpy
from mathutils import Matrix, Vector, Quaternion
import nd_anim, nd_rig, nd_ctrl, nd_mocap
from nd_shot import Shot, merge
import naruto_p5, jutsu_naruto, common_e9
from naruto_p5 import STANCE
from jutsu_naruto import Take, heel, SEAL, BASE, RF, LF, s, at

N = "Legion."
F = 60.0
MIXAMO = os.environ.get("ND_MIXAMO", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo")
WANT = ("Legion.Awaken", "Legion.CloneAmbush.Channel", "Legion.CloneAmbush.Recover", "Legion.CloneAmbush.Release",
        "Legion.CloneRasengan.Channel", "Legion.CloneThrow.Channel", "Legion.HiddenFuma.Channel", "Legion.HiddenFuma.Recover",
        "Legion.HiddenFuma.Release", "Legion.MassShadowClone.Channel", "Legion.MassShadowClone.Recover",
        "Legion.MassShadowClone.Release", "Legion.NarutoRendan", "Legion.ShadowClone.Channel", "Legion.ShadowClone.Recover",
        "Legion.ShadowClone.Release", "Legion.SummonGamakichi.Channel", "Legion.SummonGamakichi.Recover",
        "Legion.SummonGamakichi.Release", "Legion.Throw", "Legion.Throw.Kunai")


# ======================================================== pose arithmetic
def mix(a, b, w):
    """a -> b by w (0..1), channel by channel (the vocabulary is linear
    enough between two nearby poses: degrees and studs)."""
    a, b = merge(BASE, a), merge(BASE, b)
    out = {}
    for part in set(a) | set(b):
        pa, pb = a.get(part, {}), b.get(part, {})
        if not isinstance(pa, dict) or not isinstance(pb, dict):
            out[part] = pb if w >= .5 else pa
            continue
        out[part] = {k: pa.get(k, 0) + (pb.get(k, 0) - pa.get(k, 0)) * w for k in set(pa) | set(pb)}
    return out


def add(a, d, k=1.0):
    """a + k * d (d: offsets on any channels)."""
    out = merge(BASE, a)
    for part, v in d.items():
        if isinstance(v, dict):
            q = dict(out.get(part, {}))
            for c, x in v.items():
                q[c] = q.get(c, 0) + x * k
            out[part] = q
    return out


def smooth(u):
    u = max(0.0, min(1.0, u))
    return u * u * (3 - 2 * u)


# ============================================================ captures
# A Mixamo capture (nd_mocap.track, in place) read back into the authoring
# vocabulary, frame by frame: root/torso/head turns, arms (raise/out/twist/
# elbow/wrist), and the feet as ankle targets (HumanoidRootPart space). The
# clips below take from it what a real body does better than key poses (the
# hips leading the throw, the weight shifting under it, the arm's whip) and
# put it on Naruto's own stance, timed to the game.
_CAPS = {}


def _ori_inv(q, prev):
    e = q.to_matrix().to_euler("ZYX", prev) if prev else q.to_matrix().to_euler("ZYX")
    return e, {"pitch": -math.degrees(e.x), "yaw": -math.degrees(e.y), "roll": -math.degrees(e.z)}


def _arm_inv(side, qs, qe, qw, prev):
    sgn = 1 if side == "R" else -1
    e = qs.to_matrix().to_euler("YZX", prev[0]) if prev else qs.to_matrix().to_euler("YZX")
    if qe.w < 0:
        qe = -qe
    elbow = math.degrees(2 * math.atan2(qe.x, qe.w))
    ew = qw.to_matrix().to_euler("ZYX", prev[1]) if prev else qw.to_matrix().to_euler("ZYX")
    a = {"raise": math.degrees(e.x), "out": math.degrees(e.z) * sgn, "twist": math.degrees(e.y) * sgn,
         "elbow": elbow, "wrist": math.degrees(ew.x), "wroll": math.degrees(ew.z) * sgn}
    return (e, ew), a


def _fk(qs, loc):
    frames = {"HRP": Matrix.Identity(4)}
    for j in nd_rig.ORDER:
        p0, p1 = nd_ctrl.MOTORS[j]
        pivot = Vector(nd_rig.JOINTS[j][0])
        T = qs[j].to_matrix().to_4x4()
        if j == "Root":
            T.translation = loc
        frames[p1] = frames[p0] @ Matrix.Translation(pivot - nd_ctrl.CENTRE[p0]) @ T @ Matrix.Translation(nd_ctrl.CENTRE[p1] - pivot)
    return frames


def capture(key):
    """[spec per capture frame (30 fps)] of mixamo_<key>.fbx (cached)."""
    if key in _CAPS:
        return _CAPS[key]["specs"]
    before = set(bpy.data.objects)
    acts_before = set(bpy.data.actions)
    src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
    tr = nd_mocap.track(src, s0, s1, "inplace")
    for o in set(bpy.data.objects) - before:
        bpy.data.objects.remove(o, do_unlink=True)
    for a in set(bpy.data.actions) - acts_before:
        bpy.data.actions.remove(a)
    specs, hands = [], []
    prev = {}
    for i in range(len(tr["loc"])):
        qs = {j: tr["q"][j][i] for j in nd_rig.ORDER}
        loc = tr["loc"][i]
        sp = {"root": {"x": 0, "y": loc.y, "z": 0}}
        for part, j in (("root", "Root"), ("torso", "Waist"), ("head", "Neck")):
            prev[part], d = _ori_inv(qs[j], prev.get(part))
            sp[part] = dict(sp.get(part, {}), **d)
        for side, key2, n in (("R", "ra", "Right"), ("L", "la", "Left")):
            prev[key2], sp[key2] = _arm_inv(side, qs[n], qs[n + "Elbow"], qs[n + "Wrist"], prev.get(key2))
        fr = _fk(qs, loc)
        for side, key2, n in (("R", "rf", "Right"), ("L", "lf", "Left")):
            sgn = 1 if side == "R" else -1
            m = fr[n + "Foot"]
            piv = Vector(nd_rig.JOINTS[n + "Ankle"][0])
            ank = m @ (piv - nd_ctrl.CENTRE[n + "Foot"])
            e = m.to_3x3().to_euler("XYZ", prev.get(key2)) if prev.get(key2) else m.to_3x3().to_euler("XYZ")
            prev[key2] = e
            sp[key2] = {"x": ank.x - .5 * sgn, "y": ank.y + 2.6, "z": ank.z, "yaw": -math.degrees(e.y), "toe": math.degrees(e.x), "knee": 0}
        hands.append((fr["RightHand"] @ Vector((0, -.25, 0)), fr["LeftHand"] @ Vector((0, -.25, 0))))
        specs.append(sp)
    _CAPS[key] = {"specs": specs, "hands": hands}
    return specs


def cap_hand_track(key, side="R"):
    capture(key)
    return [h[0 if side == "R" else 1] for h in _CAPS[key]["hands"]]


def cap_at(key, x):
    """The capture's pose at (fractional) capture frame x."""
    specs = capture(key)
    x = max(0.0, min(len(specs) - 1.0, x))
    a = int(math.floor(x))
    b = min(len(specs) - 1, a + 1)
    return mix(specs[a], specs[b], x - a)


def warp(marks_src, marks_dst, f):
    """Piecewise-linear: output frame f -> capture frame."""
    for (a0, a1), (b0, b1) in zip(zip(marks_src, marks_src[1:]), zip(marks_dst, marks_dst[1:])):
        if b0 <= f <= b1:
            return a0 + (a1 - a0) * (f - b0) / max(b1 - b0, 1e-6)
    return marks_src[0] if f < marks_dst[0] else marks_src[-1]


# ============================================================ hand solver
# Arms are FK: a pose where the hands must meet (a seal, the cupped orb) is
# solved on the rig, in CHEST space (the arms hang from the upper torso, so
# the hands stay together whatever the hips and the chest do).
_ZB = {"root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0}, "torso": {}, "head": {}}


def hand_at(side, a):
    """Centre of the hand block (chest space at rest: HRP space, body zero)
    and the elbow, for arm spec a."""
    n = "Right" if side == "R" else "Left"
    sh, el, wr = nd_anim.arm_rot(side, a)
    q = {j: Quaternion() for j in nd_rig.ORDER}
    q[n], q[n + "Elbow"], q[n + "Wrist"] = sh.to_quaternion(), el.to_quaternion(), wr.to_quaternion()
    fr = _fk(q, Vector())
    elbow = fr[n + "LowerArm"] @ (Vector(nd_rig.JOINTS[n + "Elbow"][0]) - nd_ctrl.CENTRE[n + "LowerArm"])
    return fr[n + "Hand"].translation.copy(), elbow


_SOLVED = {}


def reach(side, target, hint, elbow_goal=None, w_elbow=.15, w_hint=.0004):
    """Arm spec (raise/out/twist/elbow, wrist from hint) whose hand block
    reaches `target` (chest space at rest, studs); elbow_goal pulls the elbow
    toward a point (a flared, readable silhouette)."""
    k = (side, tuple(round(c, 3) for c in target), tuple(sorted(hint.items())), tuple(elbow_goal or ()))
    if k in _SOLVED:
        return dict(_SOLVED[k])
    t = Vector(target)
    eg = Vector(elbow_goal) if elbow_goal else None
    cur = {c: hint.get(c, 0) for c in ("raise", "out", "twist", "elbow")}
    fixed = {c: hint.get(c, 0) for c in ("wrist", "wroll")}

    def cost(p):
        h, e = hand_at(side, dict(p, **fixed))
        c = (h - t).length_squared
        if eg is not None:
            c += w_elbow * (e - eg).length_squared
        c += w_hint * sum((p[x] - hint.get(x, 0)) ** 2 for x in p) / 100.0
        return c
    best = cost(cur)
    step = 16.0
    while step > .05:
        moved = False
        for c in ("raise", "out", "twist", "elbow"):
            for d in (step, -step):
                p = dict(cur)
                p[c] += d
                if c == "elbow":
                    p[c] = max(0.0, min(150.0, p[c]))
                v = cost(p)
                if v < best:
                    best, cur, moved = v, p, True
        if not moved:
            step *= .5
    out = dict(cur, **fixed)
    out = {c: round(v, 1) for c, v in out.items()}
    _SOLVED[k] = out
    return dict(out)


# ============================================================ splitting
def split(arm, prefix, keys, fa, rel_end, rel_markers=None, drags=(), rec_end=None):
    """One continuous act from the channel's last pose, cut the way the game
    plays it (jutsu_naruto.act, with the Release's own end and markers kept
    as they were): `.Release` is the timeline 0..rel_end, `.Recover` the
    timeline from the Active frame fa on (the two meet on the same pose)."""
    keys = sorted(keys, key=lambda k: k[0])
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    frames = [f for f, _, _ in poses]
    for need in (fa, rel_end):
        if need not in frames:
            raise ValueError("%s: no key on frame %d (keys %s)" % (prefix, need, frames))
    re, rc = Take(arm, prefix + ".Release"), Take(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= rel_end:
            re.key(f, p, sp)
        if f == fa:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif f > fa:
            rc.key(f - fa, p, sp)
    for bones, n in drags:
        rc.drag(bones, n)
    return [re.build(markers=rel_markers or {}), rc.build()]


# ======================================================= the cross seal
# Kage Bunshin's cross, BIG: the two hands meet in front of the chin, the
# right crossed in front of the left, the elbows flared out level with the
# hands (a diamond of arms that reads from behind him at duel distance).
def cross(height=1.62, fwd=-1.5, flare=1.62, elbow_y=1.3, gap=.3):
    ra = reach("R", (gap * .5, height + .06, fwd - .12), {"raise": 70, "out": -20, "twist": 40, "elbow": 100, "wrist": 10},
               (flare, elbow_y, fwd * .35))
    la = reach("L", (-gap * .5, height - .06, fwd + .06), {"raise": 70, "out": -20, "twist": 40, "elbow": 100, "wrist": 10},
               (-flare, elbow_y - .05, fwd * .35))
    return {"ra": ra, "la": la}


SQUARE = {"root": {"x": 0, "y": -.84, "z": 0, "pitch": 16, "yaw": 6, "roll": 0}, "torso": {"pitch": 8, "yaw": -2, "roll": 0},
          "head": {"pitch": 6, "yaw": -4, "roll": 0}}


# ============================================================ ShadowClone
def shadow_clone(arm):
    out = []
    ch = Take(arm, N + "ShadowClone.Channel")
    ch.key(0, s(), "ease")
    # the breath in: the fists drop and pull apart to the hips, the chest
    # lifts, the hips rise a little - all of it loading the snap
    load = s({"root": {"y": -.38, "z": .04, "pitch": 4, "yaw": 14}, "torso": {"pitch": -5, "yaw": -4},
              "head": {"pitch": -16, "yaw": -8},
              "ra": {"raise": -8, "out": 36, "twist": 10, "elbow": 86, "wrist": 0},
              "la": {"raise": -4, "out": 34, "twist": 10, "elbow": 86, "wrist": 0}})
    ch.key(3, load, "ease")
    # KAGE BUNSHIN: the cross snapped in front of his chin, elbows out, the
    # hips dropped into a deep squat over knees driven out
    seal = s(merge(merge(SQUARE, cross()), {"rf": dict(RF, knee=16), "lf": dict(LF, knee=14)}))
    ch.key(7, seal, "impact")
    ch.key(9, merge(seal, {"root": {"y": -.92, "pitch": 19}, "torso": {"pitch": 11}, "head": {"pitch": 9}}), "ease")
    hold = merge(seal, merge({"root": {"y": -.87, "pitch": 16}, "torso": {"pitch": 8, "roll": 1.5}, "head": {"pitch": 5}},
                             cross(fwd=-1.56, gap=.26)))
    ch.key(11, hold, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 11 / F}))
    # the act (Active .05, recovery .12): "no jutsu!" - he pops up out of the
    # squat with the shout, the seal shoved up at the smoke; then the hands
    # burst apart and fall back into his guard
    pop = merge(hold, merge({"root": {"y": -.6, "pitch": 6}, "torso": {"pitch": -6, "roll": 0}, "head": {"pitch": -12}},
                            cross(height=1.8, fwd=-1.6)))
    pop2 = merge(pop, {"root": {"y": -.56}, "torso": {"pitch": -8}, "head": {"pitch": -14}})
    burst = s({"root": {"y": -.5, "pitch": 8, "yaw": 12}, "torso": {"pitch": 0, "yaw": -4}, "head": {"pitch": -12, "yaw": -8},
               "ra": {"raise": 62, "out": 66, "twist": -10, "elbow": 52, "wrist": 0},
               "la": {"raise": 66, "out": 62, "twist": -10, "elbow": 48, "wrist": 0}})
    out += split(arm, N + "ShadowClone", [(0, hold, "ease"), (3, pop, "impact"), (4, pop2, "pass"), (7, burst, "ease"),
                                          (11, s(), "ease")], 3, 4, drags=((["neck"], 1),))
    return out


# ========================================================= MassShadowClone
def mass_clone(arm):
    out = []
    ch = Take(arm, N + "MassShadowClone.Channel")
    ch.key(0, s(), "ease")
    # gathered: the hands crossed low at the belly, the body coiled down over
    # them, the eyes up on the opponent
    gather = s({"root": {"y": -.74, "z": .08, "pitch": 26, "yaw": 12}, "torso": {"pitch": 16, "yaw": 0},
                "head": {"pitch": -24, "yaw": -8},
                "ra": {"raise": 34, "out": -38, "twist": 30, "elbow": 46, "wrist": 0},
                "la": {"raise": 28, "out": -34, "twist": 30, "elbow": 50, "wrist": 0},
                "lf": heel(LF, -14)})
    ch.key(4, gather, "ease")
    # he springs up off it, the weight onto the back leg, the front knee
    # pulled high for the stamp, the hands rising up the centre line
    rise = s(merge({"root": {"x": .22, "y": -.3, "z": .26, "pitch": 0, "yaw": 6, "roll": -4}, "torso": {"pitch": -6, "yaw": 0, "roll": 2},
                    "head": {"pitch": -6, "yaw": -4},
                    "lf": {"x": -.4, "y": .62, "z": -.56, "yaw": -22, "toe": 14, "knee": 26}}, cross(height=1.3, fwd=-1.3)))
    ch.key(8, rise, "pass")
    # TAJU KAGE BUNSHIN: the stamp, a horse stance twice his width, the seal
    # thrown up to the forehead with the elbows high
    big = s(merge({"root": {"x": -.04, "y": -.94, "z": .02, "pitch": 10, "yaw": 4, "roll": 3}, "torso": {"pitch": 2, "yaw": 0, "roll": -2},
                   "head": {"pitch": -4, "yaw": -2},
                   "lf": {"x": -.74, "y": 0, "z": -.74, "yaw": -32, "toe": 0, "knee": 20}, "rf": dict(RF, knee=20)},
                  cross(height=2.25, fwd=-1.35, flare=1.75, elbow_y=1.95)))
    ch.key(11, big, "impact")
    ch.key(14, merge(big, {"root": {"y": -1.02, "pitch": 12, "roll": 1}, "torso": {"pitch": 5, "roll": 0}, "head": {"pitch": -1}}), "ease")
    hold = merge(big, merge({"root": {"y": -.98, "pitch": 11, "roll": -1}, "torso": {"pitch": 3, "roll": 1.5}, "head": {"pitch": -3}},
                            cross(height=2.28, fwd=-1.4, flare=1.78, elbow_y=1.98, gap=.24)))
    ch.key(18, hold, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 18 / F}))
    # the act (Active .08, recovery .2): the clones burst out on both sides -
    # his arms fly open wide and up with them, the chest thrown open, the
    # roar; they overshoot, fall, and the stamping foot comes back under him
    fling = merge(hold, {"root": {"y": -.74, "pitch": 0, "roll": 0}, "torso": {"pitch": -12, "roll": 0}, "head": {"pitch": -22},
                         "ra": {"raise": 128, "out": 74, "twist": -20, "elbow": 16, "wrist": -20},
                         "la": {"raise": 124, "out": 76, "twist": -20, "elbow": 18, "wrist": -20}})
    over = merge(fling, {"root": {"y": -.68}, "torso": {"pitch": -15}, "head": {"pitch": -24},
                         "ra": {"raise": 140, "out": 84, "elbow": 22}, "la": {"raise": 136, "out": 86, "elbow": 24}})
    gather_foot = merge(s({"root": {"x": .18, "y": -.58, "z": .14, "pitch": 8, "yaw": 12, "roll": -2}, "torso": {"pitch": 4, "yaw": -4},
                           "head": {"pitch": -10, "yaw": -8},
                           "ra": {"raise": 66, "out": 46, "twist": 10, "elbow": 70}, "la": {"raise": 70, "out": 40, "twist": 10, "elbow": 66}}),
                        {"rf": dict(RF, knee=6), "lf": {"x": -.44, "y": .3, "z": -.72, "yaw": -16, "toe": 8, "knee": 10}})
    down = s({"root": {"y": -.56, "z": -.02, "pitch": 14}, "ra": {"raise": 40, "elbow": 104}, "la": {"raise": 46, "elbow": 92}})
    out += split(arm, N + "MassShadowClone", [(0, hold, "ease"), (4, fling, "impact"), (8, over, "ease"), (11, gather_foot, "pass"),
                                              (13, down, "impact"), (16, s(), "ease")], 4, 4,
                 drags=((["neck"], 1), (["hand.R", "hand.L"], 1)))
    return out


# ============================================================ CloneRasengan
# The orb: in front of his right hip, the right palm under it, the left over
# it (chest space); it grows as the hands work it.
ORB = Vector((.5, .45, -1.25))


def orb_hands(r, stir=0.0, spin=.16):
    """The two hands cupped round an orb of radius r; the left one stirring
    round over it (stir: the angle of its circle, radians)."""
    c = ORB
    ra = reach("R", (c.x + .05, c.y - r - .25, c.z), {"raise": 40, "out": 10, "twist": 70, "elbow": 80, "wrist": -10, "wroll": 0},
               (1.55, .2, -.3))
    lt = (c.x - .05 + spin * math.cos(stir), c.y + r + .25, c.z + spin * math.sin(stir))
    la = reach("L", lt, {"raise": 70, "out": -40, "twist": 10, "elbow": 90, "wrist": 20, "wroll": 0}, (-.9, 1.0, -.9))
    return {"ra": ra, "la": la}


def clone_rasengan(arm):
    ch = Take(arm, N + "CloneRasengan.Channel")
    ch.key(0, s(), "ease")
    body = lambda y, yaw, pitch, z=.0, roll=0: {"root": {"y": y, "z": z, "pitch": pitch, "yaw": yaw, "roll": roll},
                                                "torso": {"pitch": pitch * .9, "yaw": 6, "roll": -roll},
                                                "head": {"pitch": -pitch * .7, "yaw": -yaw - 6}}
    feet = {"rf": dict(RF, knee=10), "lf": dict(LF, knee=6)}
    # he turns his right side back and drops over his hands: the palms come
    # together round the first spark
    ch.key(5, s(merge(merge(body(-.62, 34, 14), feet), orb_hands(.12, 0.0))), "ease")
    # working it: the left hand circles over the right, the orb grows between
    # them, he sinks and winds further back with every turn
    for i, f in enumerate((9, 13, 17, 21)):
        u = (i + 1) / 4.0
        p = s(merge(merge(body(-.66 - .16 * u, 36 + 16 * u, 15 + 5 * u, .04 * u, 2 if i % 2 else -2), feet),
                    orb_hands(.12 + .2 * u, (i + 1) * math.pi * .5)))
        ch.key(f, p, "pass")
    # coiled: the weight back over the rear leg, the orb held out at his
    # side, the eyes on the opponent - the lunge is next
    end = s(merge(merge(body(-.9, 54, 18, .14), {"rf": dict(RF, knee=12), "lf": heel(LF, -14)}), orb_hands(.34, 2.5 * math.pi)))
    ch.key(24, end, "ease")
    ch.drag(["neck"], 1)
    ch.drag(["hand.L", "forearm.L"], 1)
    return [ch.build(markers={"release": 24 / F})]


# ================================================================ author
def author(arm):
    acts = []
    acts += shadow_clone(arm) + mass_clone(arm) + clone_rasengan(arm)
    acts += [naruto_p5.rendan(arm), naruto_p5.throw_kunai(arm)]
    acts += jutsu_naruto.clone_ambush(arm) + jutsu_naruto.hidden_fuma(arm) + jutsu_naruto.summon(arm)
    acts += [jutsu_naruto.clone_throw(arm), jutsu_naruto.awaken(arm)]
    acts.append(common_e9.throw(arm, N, naruto_p5.STANCE))
    keep = [a for a in acts if a.name in WANT]
    missing = [n for n in WANT if n not in {a.name for a in keep}]
    if missing:
        print("MISSING", missing)
    return keep
