"""Style passes: a capture (nd_mocap.track) becomes a fighter's own movement.

DEC-032, user 03/11: Mixamo is raw material, "pas des trucs génériques que
tout le monde aura dans son jeu". The capture keeps what it is good at (the
weight shift, the balance, the timing of the legs and hips); each fighter
then carries his body his own way (the arms, the torso, the head, the height
of the hips, the amplitude of each segment):
  pose(tr, joints, w)    held arms/torso (Sasuke's hands in his pockets,
                         Gaara's crossed arms, Lee's hand behind his back)
  offset(tr, joint, q)   a constant turn on a segment (in its parent's frame)
  amp(tr, joint, k)      more or less of the capture's own motion
  lean(tr, deg), drop()  the torso's lean, the hips' height
  window(), trim_loop()  the part of the capture a clip keeps
Poses use nd_anim's anatomical vocabulary (raise/out/twist/elbow/wrist), the
same as the runtime engine.
"""
import math
from mathutils import Quaternion, Vector
import nd_anim, nd_rig


def arms(ra=None, la=None):
    """Arm specs (nd_anim vocabulary) -> {joint: local Quaternion}."""
    out = {}
    for side, spec, name in (("R", ra, "Right"), ("L", la, "Left")):
        if spec is None:
            continue
        sh, el, wr = nd_anim.arm_rot(side, spec)
        out[name], out[name + "Elbow"], out[name + "Wrist"] = sh.to_quaternion(), el.to_quaternion(), wr.to_quaternion()
    return out


def turn(pitch=0, yaw=0, roll=0):
    """A torso/head/root turn (nd_anim.ori convention: pitch + leans forward)."""
    return nd_anim.ori({"pitch": pitch, "yaw": yaw, "roll": roll}).to_quaternion()


def _frames(tr):
    return len(tr["loc"])


def _log(q):
    """Rotation vector (axis * signed angle, radians) of a unit quaternion."""
    axis, angle = q.to_axis_angle()
    if angle > math.pi:
        angle -= 2 * math.pi
    return Vector(axis) * angle


def _exp(v):
    angle = v.length
    return Quaternion() if angle < 1e-9 else Quaternion(v / angle, angle)


def _mean(qs):
    """Mean rotation (log-average around the first frame)."""
    ref = qs[0]
    acc = Vector((0, 0, 0))
    for q in qs:
        acc += _log(ref.rotation_difference(q))
    return (ref @ _exp(acc / len(qs))).normalized()


def pose(tr, joints, w=1.0):
    """Every frame turns toward the held pose `joints` ({joint: Quaternion})."""
    for j, q in joints.items():
        tr["q"][j] = [a.slerp(q, w) for a in tr["q"][j]]
    return tr


def offset(tr, joint, q):
    tr["q"][joint] = [q @ a for a in tr["q"][joint]]
    return tr


def amp(tr, joint, k):
    """k < 1: less of the capture's motion on this segment; k > 1: more."""
    qs = tr["q"][joint]
    m = _mean(qs)
    tr["q"][joint] = [(m @ _exp(_log(m.rotation_difference(a)) * k)).normalized() for a in qs]
    return tr


def lean(tr, pitch):
    """Leans the whole body forward (+) from the hips, head kept level."""
    offset(tr, "Root", turn(pitch=pitch))
    offset(tr, "Neck", turn(pitch=-pitch * .6))
    return tr


def drop(tr, dy):
    tr["loc"] = [v + Vector((0, dy, 0)) for v in tr["loc"]]
    return tr


def still_root(tr, keep_rotation=True):
    """The hips' height leaves the clip (the engine's jump moves the body)."""
    tr["loc"] = [Vector((0, 0, 0)) for _ in tr["loc"]]
    if not keep_rotation:
        tr["q"]["Root"] = [Quaternion() for _ in tr["q"]["Root"]]
    return tr


def window(tr, a, b):
    """Keeps capture frames a..b (inclusive)."""
    tr["q"] = {j: v[a:b + 1] for j, v in tr["q"].items()}
    tr["loc"] = tr["loc"][a:b + 1]
    return tr


def trim_loop(tr):
    """Drops a last frame that repeats the first (a seamless cycle)."""
    if _frames(tr) > 2:
        window(tr, 0, _frames(tr) - 2)
    return tr


def airborne(tr, rise=.6):
    """(takeoff, touchdown) capture frames: the hips above standing height
    (the first frames' height)."""
    ys = [v.y for v in tr["loc"]]
    base = sorted(ys[:5])[2]
    up = [i for i, y in enumerate(ys) if y > base + rise]
    if not up:
        return None
    return up[0], up[-1]


def retime(tr, k):
    """Plays the track k times faster (k > 1: snappier, anime timing)."""
    n = _frames(tr)
    m = max(2, int(round((n - 1) / k)) + 1)
    out_q = {j: [] for j in tr["q"]}
    out_l = []
    for i in range(m):
        x = i * (n - 1) / (m - 1)
        a = int(math.floor(x)); b = min(n - 1, a + 1); u = x - a
        for j, qs in tr["q"].items():
            qa, qb = qs[a], qs[b]
            if qa.dot(qb) < 0:
                qb = -qb
            out_q[j].append(qa.slerp(qb, u))
        out_l.append(tr["loc"][a].lerp(tr["loc"][b], u))
    tr["q"], tr["loc"] = out_q, out_l
    return tr


def copy(tr):
    return {"q": {j: list(v) for j, v in tr["q"].items()}, "loc": [v.copy() for v in tr["loc"]],
            "fps": tr.get("fps", 30), "travel": tr.get("travel", (0, 0))}


# ---------------------------------------------------------------- fighters
# How each prodigy carries his body (the capture keeps his legs and weight).
ARMS_BACK = {"raise": -58, "out": 14, "twist": 0, "elbow": 18, "wrist": 12}      # the ninja run
POCKETS = {"raise": -6, "out": 9, "twist": 28, "elbow": 38, "wrist": 4}          # hands in the pockets
CROSSED_R = {"raise": 30, "out": -10, "twist": 82, "elbow": 96, "wrist": 0}      # Gaara's crossed arms
CROSSED_L = {"raise": 26, "out": -8, "twist": 86, "elbow": 100, "wrist": 0}
BEHIND_BACK = {"raise": -22, "out": 18, "twist": 62, "elbow": 104, "wrist": 10}  # Lee's left hand
# Lee's rear hand behind his back: the joints of his key-posed stance (p8)
LEE_REAR = {"Right": Quaternion((0.6215, -0.2483, 0.669, -0.3234)), "RightElbow": Quaternion((0.829, 0.5592, 0, 0)),
            "RightWrist": Quaternion()}
JUKEN_R = {"raise": 72, "out": 8, "elbow": 14, "wrist": -72}                     # Neji: lead palm out
JUKEN_L = {"raise": 22, "out": 30, "elbow": 64, "wrist": -54}


def style(fighter, kind, tr):
    """Applies the fighter's carriage to a locomotion track.
    kind: Idle, Walk, Run, Sprint, Air, Leap, Land, Flip."""
    F, K = fighter, kind
    run = K in ("Run", "Sprint")
    if K == "Sprint" and F != "Sand":
        # every ninja but Gaara runs arms swept back, chest low
        pose(tr, arms(ARMS_BACK, ARMS_BACK), .85)
        # (the capture's sprint already leans: a touch more, not a dive)
        lean(tr, 8 if F in ("Legion", "Flashstep", "Leaf") else 4)
    if F == "Lion":            # Sasuke: cool, hands in his pockets when he walks
        if K in ("Walk", "Idle"):
            pose(tr, arms(POCKETS, POCKETS), .9 if K == "Walk" else .0)
            amp(tr, "Waist", .6)
        if K == "Idle":
            pose(tr, arms({"raise": 18, "out": 6, "elbow": 70, "wrist": 0}, {"raise": 6, "out": 10, "elbow": 25}), .5)
    elif F == "Legion":        # Naruto: all energy, big swings
        for j in ("Right", "Left", "RightElbow", "LeftElbow"):
            amp(tr, j, 1.3 if K in ("Walk", "Run") else 1.1)
        if K == "Walk":
            offset(tr, "Neck", turn(pitch=-6))
    elif F == "Sand":          # Gaara: arms crossed, the sand does the work
        if K not in ("Flip",):
            pose(tr, arms(CROSSED_R, CROSSED_L), .95)
        for j in ("Waist", "Neck"):
            amp(tr, j, .35)
        if K in ("Walk", "Run", "Sprint"):
            for j in ("RightHip", "LeftHip", "RightKnee", "LeftKnee"):
                amp(tr, j, .75)      # shorter, heavier steps
    elif F == "Leaf":          # Lee: the rear (right) hand behind his back, the lead palm out
        if K in ("Walk", "Idle", "Run"):
            pose(tr, LEE_REAR, .95)     # only his sprint swings both arms
        if K == "Idle":
            pose(tr, arms(None, {"raise": 48, "out": 4, "elbow": 52, "wrist": -58}), .8)
            drop(tr, -.25)
        if K == "Run":
            for j in ("Left", "LeftElbow"):
                amp(tr, j, 1.4)
            lean(tr, 10)
    elif F == "GentleFist":    # Neji: upright, still arms, the Juken stance
        for j in ("Right", "Left"):
            amp(tr, j, .55)
        if K == "Idle":
            pose(tr, arms(JUKEN_R, JUKEN_L), .85)
            drop(tr, -.45)
            offset(tr, "Root", turn(yaw=-28))
            offset(tr, "Neck", turn(yaw=22))
    elif F == "Mirage":        # Itachi: economy of motion, upright
        if K == "Idle":
            offset(tr, "Waist", turn(pitch=-14))
            offset(tr, "Neck", turn(pitch=6))
        for j in ("Right", "Left", "RightElbow", "LeftElbow"):
            amp(tr, j, .45)
        amp(tr, "Waist", .5)
        amp(tr, "Neck", .4)
    elif F == "Copycat":       # Kakashi: slouched, left hand in his pocket
        if K in ("Walk", "Idle"):
            pose(tr, arms(None, POCKETS), .9)
            offset(tr, "Waist", turn(pitch=7))
            offset(tr, "Neck", turn(pitch=5))
        amp(tr, "Right", .7)
    elif F == "Flashstep":     # Minato: light, on the balls of his feet
        drop(tr, .1)
        if K == "Run":
            lean(tr, 12)
    return tr
