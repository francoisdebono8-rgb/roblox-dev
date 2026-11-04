"""Rock Lee's seal jutsu and the string's middle hits (04/11, user: « les
animations pour toutes les attaques en plus ne sont pas faites... fais-moi de
belles animations, applique-toi bien »). Authored on his body (lee_p8.STANCE:
side-on, low and springy, the lead hand open at the opponent, the rear hand
folded behind the small of the back).

Lee cannot mould chakra: none of these opens with hand seals. Each Channel is
a short preparation of his own instead (the nunchaku drawn from the belt, a
coil of the hips, a crouch, a swig).

  Nunchaku.Channel     the rear hand, behind the back, finds the nunchaku in
                       the belt and draws it out low behind the hip
  Nunchaku             (strike) the weapon whirled up behind him and over the
                       top, the overhand blow at full reach on a lunge; it
                       carries on down across the body and up onto the left
                       shoulder (Bruce Lee's catch), then back into the belt
  GorikiSenpu.Channel  the coil (the hips wound the wrong way, low, the head
                       left on the opponent) and its release: the first kick,
                       a low right roundhouse, ends it
  GorikiSenpu          (strike) the turn goes on: the left leg spun out at the
                       ribs, then off the floor, the right leg thrown straight
                       up under the chin (the contact that launches)
  DancingLeafShadow.*  a spring crouch; then he is in the air right under and
                       behind the body: stretched from the leap, folding
                       small, the eyes up; held there, the right hand finds
                       the bandage of the left forearm (the lotus is coming)
  DrunkenFist.*        a long swig from the gourd, a hiccup that jolts the
                       whole body, the knees going, and the loose sway taking
                       over before he finds his stance again
  Light4               (string, body) a skip-in, the lead hand closes into a
                       straight punch under the guard
  Light5               (string, head) the rear hand comes out from behind the
                       back for once: the hips square and drive a straight to
                       the face, then it folds back behind him

Limbs are aimed, not guessed (04/11 calibration: the arm and leg vocabulary
measured on the control rig, nd_ctrl). `aim` turns a WORLD direction into the
shoulder's raise/out under the pose's hips and chest; `leg` puts the ankle of a
kicking leg along a world direction from the real hip joint, `reach` >= 1
locking it straight (the first pass kicked with bent legs because the targets
sat inside the leg's length).

Server timings (Shared/SealJutsu, Shared/Attacks) and the engine's mapping
(VelmoraMotionEngine: the contact lands on the server's startup, a wind-up
played at most 1.25x; the active window spans contact..recover; the recovery
plays at the clip's own speed):
  Nunchaku     channel .10 (7 fr, x1.17)  strike .14 / .20 / .32   contact 8  recover 20  end 39
  GorikiSenpu  channel .12 (9 fr, x1.25)  strike .16 / .26 / .36   contact 10 recover 26  end 48
  DancingLeafShadow  channel .04 (3 fr) act .04 rec .10   (act(): Active key frame 2)
  DrunkenFist        channel .24 (16 fr) act .05 rec .20  (act(): Active key frame 3)
  Light4 .09 / .12 / .28 (x.85)   contact 5  recover 12  end 29
  Light5 .10 / .12 / .27 (x.86)   contact 6  recover 13  end 29
"""
import math
from mathutils import Vector
import nd_anim
from nd_shot import Shot, merge
import lee_p8

N = "Leaf."
BACK = lee_p8.BACK
STANCE = merge(lee_p8.STANCE, {"travel": {"x": 0, "z": 0, "yaw": 0}})


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    return s(merge({"travel": {"z": T}, "rf": {"z": .7 + T}, "lf": {"z": -.7 + T}}, over or {}))


# ------------------------------------------------------------- geometry
# (exact: checked against the evaluated rig, part frames, 04/11)
H, LEG, ANKLE = 3.0, 2.05, .4


def body_rot(spec):
    tr = spec.get("travel", {})
    return nd_anim.R(0, -tr.get("yaw", 0), 0) @ nd_anim.ori(spec.get("root", {}))


def chest_rot(spec):
    return body_rot(spec) @ nd_anim.ori(spec.get("torso", {}))


def centre(spec):
    tr, r = spec.get("travel", {}), spec.get("root", {})
    return Vector((tr.get("x", 0), H, tr.get("z", 0))) + nd_anim.R(0, -tr.get("yaw", 0), 0) @ Vector((r.get("x", 0), r.get("y", 0), r.get("z", 0)))


def hip_at(spec, side):
    k = 1 if side == "R" else -1
    return centre(spec) + body_rot(spec) @ Vector((.5 * k, -.55, 0))


def shoulder_at(spec, side):
    k = 1 if side == "R" else -1
    return centre(spec) + body_rot(spec) @ (Vector((0, .65, 0)) + nd_anim.ori(spec.get("torso", {})) @ Vector((1.05 * k, .95, 0)))


def mouth_at(spec, fwd=.4, up=0):
    """World point in front of the mouth (fwd/up in the head's own frame)."""
    neck = centre(spec) + body_rot(spec) @ (Vector((0, .65, 0)) + nd_anim.ori(spec.get("torso", {})) @ Vector((0, 1.4, 0)))
    return neck + chest_rot(spec) @ nd_anim.ori(spec.get("head", {})) @ Vector((0, .2 + up, -.75 - fwd))


def wdir(yaw, elev):
    """World direction: yaw from straight ahead toward the right, elev up."""
    y, e = math.radians(yaw), math.radians(elev)
    return Vector((math.sin(y) * math.cos(e), math.sin(e), -math.cos(y) * math.cos(e)))


def aim(spec, side, yaw, elev, **kw):
    """The upper arm along a world direction under this pose's hips and chest
    (raise/out; twist, elbow, wrist as given)."""
    k = 1 if side == "R" else -1
    d = chest_rot(spec).transposed() @ wdir(yaw, elev)
    out = {"raise": round(math.degrees(math.atan2(-d.z, -d.y)), 1),
           "out": round(math.degrees(math.asin(max(-1.0, min(1.0, k * d.x)))), 1)}
    out.update(kw)
    return out


def aim_at(spec, side, point, **kw):
    """The upper arm pointed at a world point (x right, y up, z back)."""
    d = Vector(point) - shoulder_at(spec, side)
    e = math.degrees(math.asin(max(-1.0, min(1.0, d.normalized().y))))
    return aim(spec, side, math.degrees(math.atan2(d.x, -d.z)), e, **kw)


def hand_at(spec, side, a=None):
    """World centre of the hand for arm controls `a` (default: the pose's)."""
    k = 1 if side == "R" else -1
    a = a if a is not None else spec["ra" if side == "R" else "la"]
    S, E, W = nd_anim.arm_rot(side, a)
    local = S @ (Vector((.4 * k, -1.05, 0)) + E @ (Vector((0, -.93, 0)) + W @ Vector((0, -.25, 0))))
    return shoulder_at(spec, side) + chest_rot(spec) @ local


def fore_dir(spec, side, a):
    """World direction of the forearm (elbow -> wrist) for arm controls `a`."""
    S, E, W = nd_anim.arm_rot(side, a)
    return (chest_rot(spec) @ (S @ (E @ Vector((0, -1, 0))))).normalized()


def reach(spec, side, point, fore=None, start=None, wrist=0, twist=None, wfore=1.0):
    """Arm controls that put the hand at a world point (and, with `fore`, the
    forearm along a world direction): a small numeric solve (coordinate
    descent) on raise/out/twist/elbow from `start`."""
    point = Vector(point)
    fd = fore.normalized() if fore is not None else None
    a = dict(start or {"raise": 60, "out": 0, "twist": 0, "elbow": 60})
    a["wrist"] = wrist
    if twist is not None:
        a["twist"] = twist
    keys = ["raise", "out", "elbow"] + ([] if twist is not None else ["twist"])

    a0 = dict(a)

    def cost(c):
        e = (hand_at(spec, side, c) - point).length_squared
        if fd is not None:
            e += wfore * (1 - fore_dir(spec, side, c).dot(fd)) * 4
        # (stay near the start: the same hand place has many arm solutions,
        # the natural one is the author's)
        e += 2e-5 * sum((c[k] - a0[k]) ** 2 for k in keys)
        if not 0 <= c["elbow"] <= 150 or abs(c["out"]) > 100 or abs(c["twist"]) > 130:
            e += 10
        return e
    def descend(a):
        best = cost(a)
        step = 24.0
        while step > .2:
            moved = False
            for kname in keys:
                for d in (step, -step):
                    c = dict(a)
                    c[kname] += d
                    v = cost(c)
                    if v < best:
                        a, best, moved = c, v, True
            if not moved:
                step *= .5
        return best, a
    tries = [descend(dict(a))]
    for dr, do, de in ((40, 0, 0), (-40, 0, 0), (0, 40, 30), (0, -40, 30), (0, 0, 60)):
        c = dict(a)
        c["raise"] += dr
        c["out"] += do
        c["elbow"] = min(140, c["elbow"] + de)
        tries.append(descend(c))
    a = min(tries, key=lambda t: t[0])[1]
    return {k: round(v, 1) for k, v in a.items()}


def leg(spec, side, yaw, elev, reach=1.06, toe=None, fyaw=None, knee=0):
    """A leg off the floor: the ankle `reach` leg-lengths from the hip joint
    along a world direction (reach >= 1: locked straight, pointing there; the
    foot points along the leg unless toe/fyaw say otherwise)."""
    k = 1 if side == "R" else -1
    a = hip_at(spec, side) + wdir(yaw, elev) * (LEG * reach)
    # (the knee pole aims half-way between the pelvis's yaw and the foot's,
    # nd_ctrl: in a spin both must be counted in the same turn, or the knee
    # swings to the far side of the circle and the leg flips)
    fy = yaw if fyaw is None else fyaw
    ry = spec.get("travel", {}).get("yaw", 0) + spec.get("root", {}).get("yaw", 0)
    while fy - ry > 180:
        fy -= 360
    while fy - ry < -180:
        fy += 360
    return {"x": round(a.x - .5 * k, 3), "y": round(a.y - ANKLE, 3), "z": round(a.z, 3),
            "yaw": fy, "toe": elev if toe is None else toe, "knee": knee}


def foot(X, Z, **kw):
    """A planted foot at WORLD (X, Z); says y/toe/knee so it never keeps a
    kick's (a key merges onto the previous one)."""
    out = {"y": 0, "toe": 0, "knee": 0}
    out.update(kw)
    out["x"], out["z"] = X, Z
    return out


def RF(X, Z, **kw):
    f = foot(X, Z, **kw)
    f["x"] = X - .5
    return f


def LF(X, Z, **kw):
    f = foot(X, Z, **kw)
    f["x"] = X + .5
    return f


def face(spec, yaw=0, pitch=None, elev=None):
    """The head turned so the face looks along world yaw `yaw` (the opponent:
    0) and `elev` degrees up, solved exactly under the hips and chest; with
    `pitch` instead of `elev`, the head's own pitch is kept as given."""
    d = chest_rot(spec).transposed() @ wdir(yaw, elev if elev is not None else 0)
    h = dict(spec["head"])
    h["yaw"] = round(max(-85, min(85, math.degrees(math.asin(max(-1.0, min(1.0, d.x)))))), 1)
    if elev is not None:
        h["pitch"] = round(max(-60, min(60, math.degrees(math.atan2(-d.y, -d.z)))), 1)
    elif pitch is not None:
        h["pitch"] = pitch
    return h


def pose(over, base=None, **limbs):
    """A full pose from the stance (or `base`); limbs are functions of the
    body pose (lambda p: leg(p, ...)) so they are aimed from its own hips
    and chest."""
    p = merge(base or STANCE, over or {})
    for part, f in limbs.items():
        p[part] = f(p) if callable(f) else f
    return p


def act(arm, prefix, keys, active, drags=(), marker=None, tail=6):
    """One continuous act after the channel, split the way the game plays it
    (04/11, the coordinator's note from the Sasuke pass: Combat holds
    TechniqueActive for exactly spec.Active seconds and the client plays
    `.Release` only then, then `.Recover` from ITS frame 0 for spec.Recovery,
    with a 0.1 s blend). The act is authored once as one timeline; a key sits
    on the Active frame; Release = the timeline up to Active + `tail` frames,
    Recover = the timeline from Active on: both meet on the same pose and
    speed (a pose passed through there leaves the Recover at speed)."""
    fa = round(active * 60)
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    if fa not in frames:
        raise ValueError("%s: no key on the Active frame %d (keys %s)" % (prefix, fa, frames))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    end = min((f for f in frames if f > fa), key=lambda f: abs(f - fa - tail), default=fa)
    re, rc = Shot(arm, prefix + ".Release"), Shot(arm, prefix + ".Recover")
    for f, p, sp in poses:
        if f <= end:
            re.key(f, p, sp)
        if f == fa:
            rc.key(0, p, "launch" if sp == "pass" else "ease")
        elif f > fa:
            rc.key(f - fa, p, sp)
    for bones, n in drags:
        re.drag(bones, n)
        rc.drag(bones, n)
    m = min(end, fa if marker is None else marker)
    return [re.build(markers={"release": m / 60}), rc.build()]


# ============================================================== nunchaku
def nunchaku_channel(arm):
    sh = Shot(arm, N + "Nunchaku.Channel")
    sh.key(0, s(), "ease")
    # The hand behind the back slides along the belt to the hip and closes
    # on the sticks; the shoulders turn a little to free the arm.
    grip = pose({"root": {"y": -.56, "yaw": 50}, "torso": {"yaw": -10, "pitch": 6},
                 "ra": {"raise": -30, "out": 18, "twist": 70, "elbow": 52, "wrist": 20}},
                head=lambda p: face(p, 0, elev=-4))
    sh.key(3, grip, "pass")
    # Drawn: out and down past the hip, the arm swinging back long (the sticks
    # hang from the hand behind him); the lead hand stays out, a sight.
    drawn = pose({"root": {"y": -.6, "z": .02, "pitch": 10, "yaw": 52}, "torso": {"yaw": -12, "pitch": 6},
                  "la": {"raise": 84, "out": 2, "twist": -10, "elbow": 14, "wrist": -24}},
                 ra=lambda p: aim(p, "R", 155, -52, twist=20, elbow=18, wrist=-4),
                 head=lambda p: face(p, 0, elev=-4))
    sh.key(7, drawn, "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 1)
    return sh.build(markers={"release": 7 / 60}), drawn


def nunchaku(arm, drawn):
    """The strike (.14 / .20 / .32: contact 8, recover 20, end 39). The right
    arm draws one circle, up behind, over the top and down at the face (the
    sticks extend the hand, FamilyFX); the weight rocks back with the whirl
    and goes forward with the blow, the lead foot stepping as it lands."""
    sh = Shot(arm, N + "Nunchaku")
    T = -.6
    sh.key(0, drawn, "ease")
    # the whirl: the arm swings back and up, the weight rocks onto the rear
    # foot, the lead hand reaches for the target
    w1 = pose({"travel": {"z": .04}, "root": {"y": -.62, "z": .1, "pitch": 4, "yaw": 60}, "torso": {"yaw": -16, "pitch": 2},
               "la": {"raise": 90, "out": 0, "twist": -10, "elbow": 6, "wrist": -12}},
              ra=lambda p: aim(p, "R", 172, 4, twist=10, elbow=26, wrist=10),
              head=lambda p: face(p, 0, elev=-4))
    sh.key(2, w1, "pass")
    # up behind the head, the chest opening; the lead foot unweights
    w2 = pose({"travel": {"z": 0}, "root": {"y": -.56, "z": .06, "pitch": -2, "yaw": 56}, "torso": {"yaw": -18, "pitch": -8},
               "la": {"raise": 88, "out": 0, "twist": -10, "elbow": 10, "wrist": -12},
               "lf": LF(-.6, -.82, y=.14, toe=10, yaw=20)},
              ra=lambda p: aim(p, "R", 176, 66, twist=0, elbow=30, wrist=24),
              head=lambda p: face(p, 0, elev=-4))
    sh.key(4, w2, "pass")
    # over the top: the lunge starts, the lead foot travelling, the chest
    # turning in, the lead hand drawn back to make room
    w3 = pose({"travel": {"z": T * .45}, "root": {"y": -.52, "z": -.12, "pitch": 6, "yaw": 36}, "torso": {"yaw": -24, "pitch": -2},
               "la": {"raise": 66, "out": 10, "twist": -10, "elbow": 52, "wrist": -6},
               "lf": LF(-.62, -1.25, y=.2, toe=12, yaw=14), "rf": RF(.82, .7, toe=-10, yaw=52)},
              ra=lambda p: aim(p, "R", 6, 82, twist=0, elbow=12, wrist=-16),
              head=lambda p: face(p, 0, elev=-4))
    sh.key(6, w3, "pass")
    # the blow: overhand at full reach, the hips square, the right shoulder
    # driving, the lead foot lands with it, the rear heel comes up
    hit = pose({"travel": {"z": T}, "root": {"y": -.72, "z": -.34, "pitch": 16, "yaw": 8}, "torso": {"pitch": 6, "yaw": -26, "roll": 0},
                "la": {"raise": 46, "out": 30, "twist": -24, "elbow": 112, "wrist": 0},
                "lf": LF(-.62, -1.75, yaw=8), "rf": RF(.82, .7, toe=-26, yaw=36)},
               ra=lambda p: aim(p, "R", -4, 6, twist=0, elbow=0, wrist=0),
               head=lambda p: face(p, 0, elev=-4))
    sh.key(8, hit, "impact")
    # it carries on: down and across the body ...
    thr = pose({"travel": {"z": T}, "root": {"y": -.78, "z": -.38, "pitch": 22, "yaw": 0}, "torso": {"pitch": 12, "yaw": -34, "roll": -2},
                "la": {"raise": 34, "out": 36, "twist": -24, "elbow": 100, "wrist": 0},
                "lf": LF(-.62, -1.75, yaw=8), "rf": RF(.82, .7, toe=-28, yaw=34)},
               ra=lambda p: aim(p, "R", -38, -42, twist=10, elbow=8, wrist=0),
               head=lambda p: face(p, 0, elev=-4))
    sh.key(11, thr, "pass")
    # ... past the left hip and up behind the left shoulder
    low = pose({"travel": {"z": T}, "root": {"y": -.72, "z": -.34, "pitch": 18, "yaw": 4}, "torso": {"pitch": 8, "yaw": -30, "roll": -4},
                "la": {"raise": 30, "out": 34, "twist": -30, "elbow": 110, "wrist": 0},
                "lf": LF(-.62, -1.75, yaw=8), "rf": RF(.82, .7, toe=-24, yaw=36)},
               ra=lambda p: aim(p, "R", -92, -36, twist=-30, elbow=40, wrist=-10),
               head=lambda p: face(p, 0, elev=-4))
    sh.key(14, low, "pass")
    # the catch: the right hand by the left shoulder, the sticks over it,
    # the left hand under the armpit taking the free stick; he comes up
    catch = pose({"travel": {"z": T}, "root": {"y": -.56, "z": -.26, "pitch": 8, "yaw": 18}, "torso": {"pitch": 2, "yaw": -14, "roll": 0},
                  "la": {"raise": 22, "out": 30, "twist": -44, "elbow": 118, "wrist": 0},
                  "lf": LF(-.62, -1.75, yaw=10), "rf": RF(.82, .7, toe=-16, yaw=40)},
                 # the hand in front of the left shoulder, the forearm across
                 # and rising: the sticks (along it) lie over the shoulder
                 ra=lambda p: reach(p, "R", shoulder_at(p, "L") + chest_rot(p) @ Vector((.3, -.3, -.8)),
                                    fore=chest_rot(p) @ Vector((-1, .55, .25)),
                                    start={"raise": 70, "out": -50, "twist": -30, "elbow": 120}, wrist=-20),
                 head=lambda p: face(p, 0, elev=-4))
    sh.key(19, catch, "ease")
    sh.key(22, merge(catch, {"root": {"y": -.6, "z": -.27}, "ra": {"elbow": 136}}), "ease")
    # back into the stance: the sticks brought down the right side and into
    # the belt behind the back, the hips turning side-on, the rear foot up
    down = pose({"travel": {"z": T}, "root": {"y": -.58, "z": -.18, "pitch": 12, "yaw": 30}, "torso": {"yaw": -10, "pitch": 6},
                 "la": {"raise": 66, "out": 4, "twist": -10, "elbow": 40, "wrist": -10},
                 "lf": LF(-.62, -1.75, yaw=14), "rf": RF(.82, .7, toe=-12, yaw=48)},
                ra=lambda p: aim(p, "R", 70, -62, twist=40, elbow=50, wrist=0),
                head=lambda p: face(p, 0, elev=-4))
    sh.key(28, down, "pass")
    stow = pose({"travel": {"z": T}, "root": {"y": -.55, "z": -.62, "pitch": 8, "yaw": 42}, "torso": {"yaw": -16},
                 "ra": {"raise": -34, "out": 14, "twist": 80, "elbow": 62, "wrist": 10},
                 "la": {"raise": 76, "out": 4, "twist": -10, "elbow": 26, "wrist": -16},
                 "lf": LF(-.62, -1.75, yaw=18), "rf": RF(.82, .4, y=.18, toe=-10, yaw=54)},
                head=lambda p: face(p, 0, elev=-4))
    sh.key(33, stow, "pass")
    sh.key(39, at(T - .4, {"lf": LF(-.62, -1.75, yaw=20), "rf": RF(.82, .1, yaw=58)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    sh.drag(["hand.R"], 1)
    return sh.build(markers={"contact": 8 / 60, "recover": 20 / 60})


# ========================================================== goriki senpu
TUCK = {"la": {"raise": 72, "out": -30, "twist": 10, "elbow": 112, "wrist": 0},
        "ra": {"raise": 62, "out": -26, "twist": 10, "elbow": 116, "wrist": 0}}


def _k1():
    """The first kick: a low right roundhouse at the knee, the hips turned
    over, the body leaning off it, the arms flung open (the spin brakes)."""
    return pose({"travel": {"z": -.2}, "root": {"x": -.3, "y": -.62, "z": -.34, "pitch": -4, "roll": -14, "yaw": -52},
                 "torso": {"pitch": 0, "yaw": 8, "roll": -4},
                 "lf": LF(-.6, -.7, yaw=-30, toe=-12)},
                rf=lambda p: leg(p, "R", -14, -10, toe=-14),
                la=lambda p: aim(p, "L", -46, 14, twist=0, elbow=64, wrist=0),
                ra=lambda p: aim(p, "R", 128, -30, twist=0, elbow=40, wrist=0),
                head=lambda p: face(p, 0, elev=-4))


def goriki_channel(arm):
    """The coil and its release (.12 s): the hips wind the wrong way, the
    fists close and fold, he sinks, the head left on the opponent; then the
    hips unwind and the right leg comes round low: the first kick."""
    sh = Shot(arm, N + "GorikiSenpu.Channel")
    sh.key(0, s(), "ease")
    wind = pose({"root": {"y": -.7, "yaw": 66, "pitch": 10}, "torso": {"yaw": -4, "pitch": 6},
                 "la": {"raise": 70, "out": -22, "twist": 10, "elbow": 70, "wrist": 0},
                 "ra": {"raise": -12, "out": 32, "twist": 50, "elbow": 56, "wrist": 0}},
                head=lambda p: face(p, 0, elev=-4))
    sh.key(2, wind, "pass")
    coil = pose({"root": {"y": -.86, "z": .06, "pitch": 12, "yaw": 84}, "torso": {"pitch": 8, "yaw": 4},
                 "la": {"raise": 62, "out": -40, "twist": 20, "elbow": 92, "wrist": 0},
                 "ra": {"raise": 4, "out": 52, "twist": 30, "elbow": 36, "wrist": 0},
                 "rf": RF(.82, .7, toe=-8, yaw=66), "lf": LF(-.6, -.7, yaw=40)},
                head=lambda p: face(p, 0, elev=-4))
    sh.key(4, coil, "ease")
    # the release: the right knee comes round from behind, high, the hips over
    # the lead foot which pivots on its ball
    whip = pose({"travel": {"z": -.1}, "root": {"x": -.2, "y": -.66, "z": -.26, "pitch": 4, "roll": -6, "yaw": 16},
                 "torso": {"pitch": 4, "yaw": -2, "roll": -2},
                 "lf": LF(-.6, -.7, yaw=6, toe=-10)},
                rf=lambda p: leg(p, "R", 62, -8, reach=.6, toe=-30, knee=10),
                la=TUCK["la"], ra=TUCK["ra"],
                head=lambda p: face(p, 0, elev=-4))
    sh.key(6, whip, "pass")
    sh.key(9, _k1(), "impact")
    sh.drag(["neck"], 1)
    return sh.build(markers={"release": 9 / 60})


def goriki_senpu(arm):
    """The strike (.16 / .26 / .36: contact 10, recover 26, end 48), from the
    first kick (the channel's last pose) on through one left turn of the body:
    -52 (k1) -> -262 (k2: the left leg spun out at the ribs) -> -350 (k3:
    off the floor, the right leg thrown straight up under the chin, the
    contact) -> landing back in the stance (-312 = 48). Between the kicks the
    arms fold in (the spin speeds up), at each kick they open (it brakes);
    the head leaves the opponent last and finds him first."""
    sh = Shot(arm, N + "GorikiSenpu")
    k1 = _k1()
    sh.key(0, k1, "launch")
    # through: the leg sweeps past and folds, coming down crossing in front
    # of the left foot; the back turns to him, the arms fold
    sweep = pose({"travel": {"z": -.4}, "root": {"x": -.55, "y": -.56, "z": -.5, "pitch": 4, "roll": -4, "yaw": -118},
                  "torso": {"pitch": 4, "yaw": -14, "roll": 0}, "lf": LF(-.6, -.7, yaw=-80, toe=-16)},
                 rf=lambda p: leg(p, "R", -70, -48, reach=.84, toe=-30, knee=10),
                 la=TUCK["la"], ra=TUCK["ra"], head=lambda p: face(p, -150, elev=-4))
    sh.key(2, sweep, "pass")
    plant = pose({"travel": {"z": -.55}, "root": {"x": -.75, "y": -.6, "z": -.62, "pitch": 6, "roll": 2, "yaw": -176},
                  "torso": {"pitch": 4, "yaw": -18, "roll": 0},
                  "rf": RF(-1.0, -1.55, yaw=-160, toe=-10), "lf": LF(-.6, -.82, y=.22, toe=-20, yaw=-150, knee=8)},
                 la=TUCK["la"], ra=TUCK["ra"], head=lambda p: face(p, -260, elev=-4))
    sh.key(3, plant, "pass")
    # the left leg leaves the floor and comes round with the spin, out to
    # his right, rising
    hook = pose({"travel": {"z": -.65}, "root": {"x": -.85, "y": -.54, "z": -.62, "pitch": 0, "roll": 14, "yaw": -218},
                 "torso": {"pitch": 2, "yaw": -18, "roll": 2},
                 "rf": RF(-1.0, -1.55, yaw=-198, toe=-12)},
                lf=lambda p: leg(p, "L", 96, 4, reach=.86, toe=0, fyaw=-218),
                la=lambda p: aim(p, "L", 100, 0, twist=0, elbow=50, wrist=0),
                ra=TUCK["ra"], head=lambda p: face(p, -330, elev=-4))
    sh.key(4, hook, "pass")
    # k2: the left leg spun out at the ribs, pivoting on the right foot, the
    # body tipped right off it, the left arm along the leg, the right flung back
    k2 = pose({"travel": {"z": -.75}, "root": {"x": -.95, "y": -.48, "z": -.6, "pitch": -2, "roll": 30, "yaw": -262},
               "torso": {"pitch": 0, "yaw": -16, "roll": 6},
               "rf": RF(-1.0, -1.55, yaw=-236, toe=-14)},
              # (the blade of the foot: the toes along the pelvis, so the foot turns
              # with the spin and not back against it)
              lf=lambda p: leg(p, "L", -2, 26, toe=6, fyaw=-250),
              la=lambda p: aim(p, "L", -10, 14, twist=0, elbow=24, wrist=0),
              ra={"raise": 70, "out": -16, "twist": 10, "elbow": 104, "wrist": 0},
              head=lambda p: face(p, -360, elev=-4))
    sh.key(5, k2, "impact")
    # the heel carries on across and folds
    sh.key(6, pose({"travel": {"z": -.85}, "root": {"x": -.8, "y": -.56, "z": -.7, "pitch": 4, "roll": 18, "yaw": -284},
                    "torso": {"pitch": 4, "yaw": -12, "roll": 2},
                    "rf": RF(-1.0, -1.55, yaw=-252, toe=-20)},
                   lf=lambda p: leg(p, "L", -40, 8, reach=.74, toe=0, fyaw=-284),
                   la=lambda p: aim(p, "L", -60, -10, twist=0, elbow=34, wrist=0),
                   ra={"raise": 40, "out": 0, "twist": 10, "elbow": 80, "wrist": 0},
                   head=lambda p: face(p, -360, elev=-4)), "pass")
    # the leg folds back and comes down in front: the take-off foot; he drops
    # for the jump, the arms swinging down, the right heel already up
    load = pose({"travel": {"z": -1.0}, "root": {"x": -.6, "y": -.8, "z": -.82, "pitch": 12, "roll": 2, "yaw": -306},
                 "torso": {"pitch": 8, "yaw": -8, "roll": 0},
                 "rf": RF(-1.0, -1.55, toe=-36, yaw=-268), "lf": LF(-.7, -2.1, yaw=-310)},
                la=lambda p: aim(p, "L", -110, -50, twist=0, elbow=34, wrist=0),
                ra=lambda p: aim(p, "R", 150, -55, twist=0, elbow=34, wrist=0),
                head=lambda p: face(p, -360, elev=-4))
    sh.key(7, load, "pass")
    # take-off: the left foot drives, the right leg swings through under him,
    # the arms sweep up
    take = pose({"travel": {"z": -1.1}, "root": {"x": -.5, "y": -.34, "z": -.78, "pitch": -2, "roll": -2, "yaw": -334},
                 "torso": {"pitch": -2, "yaw": -4, "roll": 0},
                 "lf": LF(-.7, -2.1, toe=-46, yaw=-326)},
                rf=lambda p: leg(p, "R", -6, -30, reach=.9, toe=-30, knee=0),
                la=lambda p: aim(p, "L", -60, 0, twist=0, elbow=30, wrist=0),
                ra=lambda p: aim(p, "R", 60, -10, twist=0, elbow=40, wrist=0),
                head=lambda p: face(p, -360, elev=-4))
    sh.key(8, take, "pass")
    # the leg swinging up through the front, straight (the arc of the kick)
    swing = pose({"travel": {"z": -1.15}, "root": {"x": -.45, "y": -.08, "z": -.72, "pitch": -12, "roll": -3, "yaw": -342},
                  "torso": {"pitch": -6, "yaw": -2, "roll": -1}},
                 rf=lambda p: leg(p, "R", -5, 18, reach=1.02, toe=4),
                 lf=lambda p: leg(p, "L", -8, -70, reach=.8, toe=-44, knee=0),
                 la=lambda p: aim(p, "L", -56, 30, twist=0, elbow=26, wrist=0),
                 ra=lambda p: aim(p, "R", 70, -12, twist=0, elbow=34, wrist=0),
                 head=lambda p: face(p, -360, elev=6))
    sh.key(9, swing, "pass")
    # k3, the contact: off the floor, the right leg straight up under the
    # chin, the chest falling back behind it, the left knee tucked, the left
    # arm flung up and back
    k3 = pose({"travel": {"z": -1.2}, "root": {"x": -.4, "y": .22, "z": -.66, "pitch": -24, "roll": -4, "yaw": -350},
               "torso": {"pitch": -12, "yaw": 0, "roll": -2}},
              rf=lambda p: leg(p, "R", -4, 70, toe=64, knee=180),
              lf=lambda p: leg(p, "L", -8, -62, reach=.62, toe=-40, knee=0),
              la=lambda p: aim(p, "L", -60, 50, twist=0, elbow=24, wrist=0),
              ra=lambda p: aim(p, "R", 80, -14, twist=0, elbow=30, wrist=0),
              head=lambda p: face(p, -360, elev=14))
    sh.key(10, k3, "impact")
    # it follows through upward: the apex
    apex = pose({"travel": {"z": -1.2}, "root": {"x": -.4, "y": .4, "z": -.62, "pitch": -30, "roll": -4, "yaw": -352},
                 "torso": {"pitch": -14, "yaw": 0, "roll": -2}},
                rf=lambda p: leg(p, "R", -4, 84, toe=80, knee=180),
                lf=lambda p: leg(p, "L", -8, -58, reach=.58, toe=-40, knee=0),
                la=lambda p: aim(p, "L", -70, 60, twist=0, elbow=24, wrist=0),
                ra=lambda p: aim(p, "R", 86, -6, twist=0, elbow=34, wrist=0),
                head=lambda p: face(p, -360, elev=18))
    sh.key(15, apex, "ease")
    # the leg comes down through the horizontal, the kneecap up again
    down = pose({"travel": {"z": -1.2}, "root": {"x": -.36, "y": .2, "z": -.56, "pitch": -16, "roll": -2, "yaw": -348},
                 "torso": {"pitch": -6, "yaw": -2, "roll": -1}},
                rf=lambda p: leg(p, "R", -2, 12, reach=.86, toe=0, knee=0),
                lf=lambda p: leg(p, "L", -8, -66, reach=.7, toe=-36, knee=0),
                la=lambda p: aim(p, "L", -70, 36, twist=0, elbow=30, wrist=0),
                ra=lambda p: aim(p, "R", 80, -8, twist=0, elbow=40, wrist=0),
                head=lambda p: face(p, -360, elev=6))
    sh.key(18, down, "pass")
    # coming down: the kicking leg folds, the left foot reaches for the floor
    fall = pose({"travel": {"z": -1.2}, "root": {"x": -.3, "y": -.06, "z": -.5, "pitch": -4, "roll": 0, "yaw": -344},
                 "torso": {"pitch": 0, "yaw": -4, "roll": 0}},
                rf=lambda p: leg(p, "R", 0, -20, reach=.7, toe=-20, knee=10),
                lf=lambda p: leg(p, "L", -6, -82, reach=.84, toe=-24, knee=0),
                la=lambda p: aim(p, "L", -70, 10, twist=0, elbow=40, wrist=0),
                ra=lambda p: aim(p, "R", 70, -10, twist=0, elbow=50, wrist=0),
                head=lambda p: face(p, -360, elev=-4))
    sh.key(21, fall, "pass")
    # the landing: on the left foot, absorbed deep, the right foot down behind
    land = pose({"travel": {"z": -1.2}, "root": {"y": -.96, "z": -.16, "pitch": 18, "yaw": -322}, "torso": {"pitch": 10, "yaw": -12},
                 "la": {"raise": 64, "out": 26, "twist": -10, "elbow": 40, "wrist": -10},
                 "ra": {"raise": -20, "out": 40, "twist": 40, "elbow": 60, "wrist": 0},
                 "lf": LF(-.62, -1.9, yaw=-334), "rf": RF(.7, -.75, y=.3, toe=-20, yaw=-306)},
                head=lambda p: face(p, -360, elev=-4))
    sh.key(25, land, "impact")
    settle = merge(land, {"root": {"y": -.7, "z": -.08, "pitch": 10}, "ra": BACK, "rf": RF(.82, -.5, yaw=-302)})
    settle["head"] = face(settle, -360, elev=-4)
    sh.key(32, settle, "ease")
    sh.key(48, at(-1.2, {"lf": LF(-.62, -1.9, yaw=20), "rf": RF(.82, -.5, yaw=58)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["hand.L", "hand.R"], 1)
    return sh.build(markers={"contact": 10 / 60, "recover": 26 / 60})


# ==================================================== dancing leaf shadow
def _crouch():
    return pose({"root": {"y": -1.12, "z": .1, "pitch": 28, "yaw": 30}, "torso": {"pitch": 14, "yaw": -8},
                 "rf": RF(.82, .7, toe=-26, yaw=50), "lf": LF(-.6, -.7, toe=-20, yaw=20)},
                la=lambda p: aim(p, "L", -150, -40, twist=0, elbow=18, wrist=0),
                ra=lambda p: aim(p, "R", 160, -40, twist=0, elbow=18, wrist=0),
                head=lambda p: face(p, 0, elev=-4))


AIRBASE = {"travel": {"z": 0}, "root": {"x": 0, "z": 0, "roll": 0, "yaw": 0}, "torso": {"yaw": 0, "roll": 0}}


def _shadow():
    """Small and folded under the body, the knees drawn up, the back upright
    so the eyes can stay up on it, the hands open and ready."""
    return pose(merge(AIRBASE, {"root": {"y": -.3, "pitch": -4}, "torso": {"pitch": 2}}),
                rf=lambda p: leg(p, "R", 4, -20, reach=.5, toe=-40, knee=6),
                lf=lambda p: leg(p, "L", -4, -36, reach=.52, toe=-40, knee=6),
                la=lambda p: aim(p, "L", -10, 62, twist=-20, elbow=30, wrist=-12),
                ra=lambda p: aim(p, "R", 16, 24, twist=20, elbow=96, wrist=0),
                head=lambda p: face(p, 0, elev=52))


def dancing_leaf(arm):
    """Channel .04 (3 frames, a spring crouch); Active .04, Recovery .10:
    the act is one timeline (act()): he is up there already, stretched from
    the leap (frame 0), folding small under the body by the end of the
    recovery and held there, the right hand going to the bandage of the left
    forearm (what is left of it plays if the air state lets it)."""
    out = []
    ch = Shot(arm, N + "DancingLeafShadow.Channel")
    ch.key(0, s(), "ease")
    ch.key(3, _crouch(), "ease")
    out.append(ch.build(markers={"release": 3 / 60}))

    # stretched from the leap: arms swept up past the head, legs long under him
    leap = pose(merge(AIRBASE, {"root": {"y": -.02, "pitch": -8}, "torso": {"pitch": -6}}),
                rf=lambda p: leg(p, "R", 0, -86, reach=1.0, toe=-70),
                lf=lambda p: leg(p, "L", 0, -80, reach=.98, toe=-70),
                la=lambda p: aim(p, "L", -14, 72, twist=0, elbow=8, wrist=0),
                ra=lambda p: aim(p, "R", 14, 70, twist=0, elbow=10, wrist=0),
                head=lambda p: face(p, 0, elev=40))
    # (the Active frame) the knees start up, the arms already coming down
    tuck = pose(merge(AIRBASE, {"root": {"y": -.1, "pitch": 2}, "torso": {"pitch": -2}}),
                rf=lambda p: leg(p, "R", 0, -70, reach=.82, toe=-56, knee=4),
                lf=lambda p: leg(p, "L", 0, -74, reach=.84, toe=-56, knee=4),
                la=lambda p: aim(p, "L", -13, 68, twist=-6, elbow=16, wrist=-4),
                ra=lambda p: aim(p, "R", 13, 58, twist=6, elbow=34, wrist=0),
                head=lambda p: face(p, 0, elev=46))
    # folding small under it, the eyes staying on the body above
    fold = pose(merge(AIRBASE, {"root": {"y": -.22, "pitch": 0}, "torso": {"pitch": 0}}),
                rf=lambda p: leg(p, "R", 2, -45, reach=.62, toe=-46, knee=4),
                lf=lambda p: leg(p, "L", -2, -58, reach=.64, toe=-46, knee=4),
                la=lambda p: aim(p, "L", -11, 64, twist=-14, elbow=26, wrist=-8),
                ra=lambda p: aim(p, "R", 15, 36, twist=14, elbow=74, wrist=0),
                head=lambda p: face(p, 0, elev=50))
    shadow = _shadow()
    # held there: the left forearm comes across, the right fingers find the
    # bandage at its wrist
    band = pose(merge(AIRBASE, {"root": {"y": -.34, "pitch": -2}, "torso": {"pitch": 4}}),
                rf=shadow["rf"], lf=shadow["lf"],
                la={"raise": 100, "out": -14, "twist": 60, "elbow": 88, "wrist": 0},
                head=lambda p: face(p, 0, elev=48))
    band["ra"] = reach(band, "R", hand_at(band, "L") - fore_dir(band, "L", band["la"]) * .3 + Vector((.15, -.2, -.1)),
                       start={"raise": 70, "out": -34, "twist": 20, "elbow": 96}, wrist=10)
    keys = [(0, leap, "launch"), (2, tuck, "pass"), (4, fold, "pass"), (8, shadow, "ease"), (14, band, "ease")]
    out += act(arm, N + "DancingLeafShadow", keys, .04, marker=1,
               drags=[(["hand.L", "hand.R"], 1), (["neck"], 1)])
    return out


# =========================================================== drunken fist
def drunken_fist(arm):
    out = []
    ch = Shot(arm, N + "DrunkenFist.Channel")
    ch.key(0, s(), "ease")
    # the gourd comes up from behind the back, he straightens
    up = pose({"root": {"y": -.44, "pitch": 2, "yaw": 40}, "torso": {"pitch": -2, "yaw": -12},
               "ra": {"raise": 70, "out": 26, "twist": -10, "elbow": 110, "wrist": 10},
               "la": {"raise": 30, "out": 26, "twist": -30, "elbow": 70, "wrist": 0}},
              head=lambda p: face(p, 0, -12))
    ch.key(5, up, "pass")
    # the swig: head back, elbow high, the free hand on the hip, the weight
    # rocking back onto the rear foot
    swig = pose({"root": {"y": -.36, "z": .06, "pitch": -6, "yaw": 34, "roll": -3}, "torso": {"pitch": -16, "yaw": -8}},
                head=lambda p: dict(face(p, -6, elev=52), roll=-4))
    swig["ra"] = reach(swig, "R", mouth_at(swig, .45, .25), start={"raise": 140, "out": 30, "twist": -30, "elbow": 120}, wrist=30)
    swig["la"] = reach(swig, "L", hip_at(swig, "L") + body_rot(swig) @ Vector((-.55, .35, .1)),
                       start={"raise": -8, "out": 32, "twist": -40, "elbow": 96}, wrist=0)
    ch.key(10, swig, "ease")
    # a long pull: the head goes further back, the hips sway under it
    pull = merge(swig, {"root": {"y": -.34, "roll": 2, "x": .04}})
    pull["head"] = dict(face(pull, -6, elev=60), roll=2)
    pull["ra"] = reach(pull, "R", mouth_at(pull, .4, .35), start=swig["ra"], wrist=36)
    ch.key(16, pull, "ease")
    ch.drag(["neck"], 2)
    ch.drag(["shoulder.L", "forearm.L", "hand.L"], 2)
    out.append(ch.build(markers={"release": 16 / 60}))

    # The act (Active .05: 3 frames, Recovery .20): the hiccup on the Active
    # frame, the knees going, the sway, his stance found again.
    # the hiccup: the whole body jolts up, shoulders hunch, the head snaps
    # forward, the gourd hand drops
    hic = merge(pull, {"root": {"y": -.22, "pitch": 6, "roll": 0, "x": 0}, "torso": {"pitch": 12, "yaw": -10}, "head": {"pitch": 18, "roll": -6},
                       "ra": {"raise": 80, "out": 30, "twist": -10, "elbow": 110, "wrist": 30},
                       "la": {"raise": 20, "out": 40, "twist": -30, "elbow": 80, "wrist": 30},
                       "rf": RF(.82, .7, yaw=58, toe=-14), "lf": LF(-.6, -.7, yaw=20, toe=-12)})
    # and the knees go: he sinks loose to one side, everything hanging
    sag = pose({"root": {"y": -.88, "x": -.14, "pitch": 14, "roll": -12, "yaw": 30}, "torso": {"pitch": 10, "roll": 8, "yaw": -6},
                "la": {"raise": 28, "out": 30, "twist": -20, "elbow": 56, "wrist": 56},
                "ra": {"raise": 34, "out": 26, "twist": -10, "elbow": 74, "wrist": 60},
                "rf": RF(.82, .7, yaw=58), "lf": LF(-.6, -.7, yaw=20, knee=-10)},
               head=lambda p: dict(face(p, -20, 10), roll=16))
    # the sway takes over: the body rolls over to the other side, the arms
    # float up loose (the drunken boxer's cupped hands), the head lolling
    # behind the body
    sway = pose({"root": {"y": -.6, "x": .16, "pitch": 4, "roll": 10, "yaw": 54}, "torso": {"pitch": -2, "roll": -10, "yaw": -16},
                 "la": {"raise": 84, "out": 14, "twist": -40, "elbow": 70, "wrist": 50},
                 "ra": {"raise": 110, "out": 20, "twist": -30, "elbow": 120, "wrist": 50},
                 "rf": RF(.82, .7, yaw=58), "lf": LF(-.6, -.7, yaw=20, toe=-10)},
                head=lambda p: dict(face(p, 10, -8), roll=-14))
    keys = [(0, pull, "ease"), (3, hic, "impact"), (8, sag, "ease"), (13, sway, "pass"), (18, s({"root": {"roll": 3, "x": .04}}), "ease")]
    out += act(arm, N + "DrunkenFist", keys, .05,
               drags=[(["neck"], 1), (["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)])
    return out


# ============================================================ lights
def light4(arm):
    """Body punch, the lead hand (.09 / .12 / .28: contact 5, recover 12,
    end 29). A skip-in, the Strong Fist's spring: both feet leave the floor,
    the rear foot lands first behind the front one, the front one lands with
    the fist; he drops under the guard as it lands."""
    sh = Shot(arm, N + "Light4")
    T = -.7
    sh.key(0, s(), "ease")
    hop = pose({"travel": {"z": T * .4}, "root": {"y": -.44, "z": .02, "pitch": 6, "yaw": 56}, "torso": {"pitch": 2, "yaw": -20},
                "la": {"raise": 56, "out": 12, "twist": -20, "elbow": 118, "wrist": 0},
                "rf": RF(.82, .45, y=.3, toe=-20, yaw=58), "lf": LF(-.6, -1.0, y=.16, toe=10, yaw=20)},
               head=lambda p: face(p, 0, elev=-4))
    sh.key(2, hop, "launch")
    land = pose({"travel": {"z": T * .7}, "root": {"y": -.6, "z": -.08, "pitch": 10, "yaw": 56}, "torso": {"pitch": 6, "yaw": -24},
                 "la": {"raise": 62, "out": 8, "twist": -12, "elbow": 104, "wrist": 0},
                 "rf": RF(.82, .25, toe=-14, yaw=58), "lf": LF(-.6, -1.2, y=.1, toe=6, yaw=20)},
                head=lambda p: face(p, 0, elev=-4))
    sh.key(3, land, "pass")
    hit = pose({"travel": {"z": T}, "root": {"y": -.9, "z": -.3, "pitch": 14, "yaw": 60}, "torso": {"pitch": 6, "yaw": -30, "roll": -4},
                "rf": RF(.82, .25, toe=-20, yaw=58), "lf": LF(-.6, -1.45, yaw=20)},
               la=lambda p: aim(p, "L", 2, -14, twist=0, elbow=0, wrist=0),
               head=lambda p: face(p, 0, elev=-4))
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.31, "y": -.86}, "la": {"elbow": 2}}), "ease")
    # the hand snaps back open (the beckoning guard), he comes up springy
    sh.key(15, s({"travel": {"z": T}, "root": {"y": -.56, "z": -.1}, "la": {"raise": 76, "elbow": 36, "wrist": -10},
                  "rf": RF(.82, .25, yaw=58, toe=-6), "lf": LF(-.6, -1.45, yaw=20)}), "pass")
    sh.key(29, at(T, {"rf": RF(.82, .25, yaw=58), "lf": LF(-.6, -1.45, yaw=20)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 12 / 60})


def light5(arm):
    """Straight to the face, the REAR hand (.10 / .12 / .27: contact 6,
    recover 13, end 29): out from behind the back, the hips square through
    it, the lead hand pulled in; then folded behind the back again."""
    sh = Shot(arm, N + "Light5")
    T = -.35
    sh.key(0, s(), "ease")
    # a tiny wind the other way: the hips close, the hand leaves the back
    sh.key(3, pose({"travel": {"z": T * .4}, "root": {"y": -.56, "z": .04, "pitch": 8, "yaw": 58}, "torso": {"yaw": -20},
                    "ra": {"raise": -20, "out": 20, "twist": 40, "elbow": 110, "wrist": 0},
                    "rf": RF(.82, .7, toe=-10, yaw=58), "lf": LF(-.6, -.9, y=.16, toe=8, yaw=12)}, head=lambda p: face(p, 0, elev=-4)), "pass")
    hit = pose({"travel": {"z": T}, "root": {"y": -.48, "z": -.28, "pitch": 10, "yaw": -2}, "torso": {"pitch": 4, "yaw": -8, "roll": 2},
                "la": {"raise": 56, "out": 6, "twist": -20, "elbow": 118, "wrist": 0},
                "rf": RF(.82, .7, toe=-30, yaw=10), "lf": LF(-.6, -1.05, yaw=4)},
               ra=lambda p: aim(p, "R", -2, 8, twist=0, elbow=0, wrist=0),
               head=lambda p: face(p, 0, elev=-4))
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"root": {"z": -.31}}), "ease")
    # the hips turn back side-on, the fist comes back round the hip to the
    # small of the back, the rear foot follows
    sh.key(14, merge(hit, {"root": {"z": -.4, "y": -.5}, "rf": RF(.82, .7, toe=-30, yaw=20)}), "pass")
    sh.key(19, pose({"travel": {"z": T}, "root": {"y": -.5, "z": -.42, "yaw": 34}, "torso": {"yaw": -14},
                     "ra": {"raise": 0, "out": 24, "twist": 60, "elbow": 80, "wrist": 0},
                     "la": {"raise": 70, "elbow": 40},
                     "rf": RF(.8, .5, y=.18, toe=-10, yaw=40), "lf": LF(-.6, -1.05, yaw=14)},
                    head=lambda p: face(p, 0, elev=-4)), "pass")
    sh.key(29, at(T, {"rf": RF(.82, .35, yaw=58), "lf": LF(-.6, -1.05, yaw=20)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 13 / 60})


def author(arm):
    ch, drawn = nunchaku_channel(arm)
    acts = [ch, nunchaku(arm, drawn), goriki_channel(arm), goriki_senpu(arm)]
    acts += dancing_leaf(arm)
    acts += drunken_fist(arm)
    acts += [light4(arm), light5(arm)]
    return acts
