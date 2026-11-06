"""Sasuke's jutsu, pass v2 (06/11, user: « refais-les toutes avec les nouveaux
outils », « des animations fluides comme un film »).

Authored on his body (clips_lion2.STANCE: low, coiled, side-on with the left
foot leading, the chest over the front foot). His bible (docs/characters/
SASUKE.md): the legs explain the entry, the pivot foot stays down, the free
hand keeps the wire, fire and lightning have distinct gestures, he reads more
aggressive than Itachi. So every jutsu here sinks him lower than his guard,
loads the rear leg before it fires, and lets the hips lead the shoulder and
the hand. Hands that must meet are placed by solving the arm on the rig
(solve(): a hand at the mouth for the fire, on the other wrist for the
Chidori, at the neck for the curse mark), not guessed; the seals are
jutsu_sasuke.SEAL (the hands pressed together).

  FireBloom        (Great Fireball) ram - tiger snapped at the chest while the
                   whole body sinks and squares; then the inhale is a real
                   breath: the hips roll back over the loaded rear leg, the
                   chest swells and arches, the head tips back, the ringed
                   right hand comes up to the mouth with the elbow high and
                   the left fist pulls back to the hip, opening the chest.
                   Hold keeps drawing in (the chest rises in two swells, the
                   hips settle lower, the elbow lifts) and loops. Release:
                   the hips drive forward first, then the chest and the head
                   are thrown over the front foot in one long line from the
                   rear heel (lifted, pivoting) to the mouth, the left arm
                   flung back to balance; it overshoots, and the breath keeps
                   pushing in two pumps while the fire pours. Recover: he
                   rocks back up out of the lunge and settles into the guard
                   with a small dip.
  PhoenixFlower    rat - tiger, a shorter, sharper inhale (the head snaps
                   back, the left hand goes to the back pouch); the release
                   is three quick pumps of the head and chest, each one
                   turned to its own lane - left, centre, right - the hips
                   swinging under them; on the third the left hand flicks
                   the two hidden shuriken out underneath the flames. A
                   rhythm, not the Fireball's single drive.
  WireTrap         the throwing hand dives behind the hip, the hips coil away
                   and the left arm aims; the hips unwind first and the arm
                   whips the wired shuriken out flat, the rear heel pivoting.
                   Recover: the left hand catches the wire out in front, then
                   the HAUL - the body drops and sits back against the wire,
                   the right fist yanked to the hip, the front toes lifting -
                   the wire bites back, and the right fist brings it up to the
                   teeth while the left holds the line taut out in front (the
                   Dragon Flame is ready).
  Chidori          Form: he hops his feet wide, the right hand drops in front
                   of the knees, opens palm-down - the lightning catches - and
                   the left hand clamps on the right wrist to hold it down;
                   the jolt throws the shoulders, then he sinks lower and lower
                   while the arm shakes against the grip; at the end the grip
                   lets go and the arm is drawn back low: the carry. Hold
                   (laid by the engine over his run or his guard, upper body
                   only): the lightning hand trails low behind, palm down, the
                   chest pitched forward, the left arm forward for balance,
                   the arm crackling (short shudders, never still).
  Soshuha          tiger - snake, the hands dive and cross low in front of
                   the hips (a shuriken in each), the body folded over them;
                   the throw flings both arms open into a wide V on a lunge;
                   Recover: the wires taut, both elbows driven back past the
                   ribs, the weight sitting back against them, then a second
                   shorter tug.
  WindmillBlades   snake - ram, the right hand goes to the back pouch, the
                   body turns side-on over the loaded rear leg, the left arm
                   aiming, the blades cocked by the ear; the hips unwind
                   first, the arm whips the three blades flat across with a
                   step in and follows through; Recover: the left hand holds
                   the line out front, the right fist yanks it taut to the hip.
  SharinganCounter ram - rat snapped, then the reading stance (the cat
                   stance: lower, the weight back so the front leg is light -
                   the answer is a kick - the lead hand open forward, the
                   head still), then the guard.
  SharinganCopy    rat - tiger, two fingers come up beside the right eye (the
                   head dips, then lifts), the other hand gathers at the hip;
                   the mirrored cast: a step of the hips and the open palm
                   thrown at him, the fingers still at the eye.
  Awaken           (curse mark) the seal burns: a jolt, the right hand claws
                   at the left side of his neck and the body folds over the
                   pain until a knee nearly touches the floor, shaking; then
                   the marks spread - he rises arching, head back, arms
                   flung out and down, fingers clawed - and drops into the
                   curse guard, lower and more forward than his own, breathing.
  Throw.Shuriken   (the tool throw, upper body only: the engine keeps the
                   legs) the lead hand cocks across the chest to the far
                   shoulder (the chest turns away), the chest unwinds and the
                   forearm whips out flat; the wrist snaps twice - the pair.
  Throw            (the grab's throw, shared with the basic moveset) from the
                   hold: a short load to the right (the hips drop), then the
                   hips turn through first and the arms heave him across and
                   down, the rear heel pivoting; the arms open as he lets go
                   and the body rises back into the guard.

Seal channels (Shared/SealJutsu.Lion): the player sees the first seal as he
presses it (the engine's sealing pose); the Channel starts on that seal,
snaps the second and goes straight into the act, so the authored Channel
stays within 1.0-1.3x of the server's channel (the earlier ones were 1.6-2.5x
and played the two seals at double speed):
  Soshuha .16 -> 12 f    WindmillBlades .24 -> 18 f
  SharinganCounter .04 -> 3 f    SharinganCopy .18 -> 13 f
Quick techniques (Shared/Fighters.Lion, Channel / Active / Recovery):
  FireBloom .32/.40/.36 (Hold up to .9 s)   PhoenixFlower .28/.32/.30
  WireTrap .18/.08/.30   Chidori .62 (Form) then the carry (Hold)
The engine plays the Release only while TechniqueActive lasts, then the
Recover from its frame 0: each act is one timeline cut on the Active frame
(cut() / jutsu_sasuke.act), so the Recover goes on from that very pose.
"""
import math
from mathutils import Vector
import nd_anim
from nd_shot import Shot, merge
from jutsu_sasuke import s, at, seal, act, SEAL, ZERO, RF, LF, CROSS_R, CROSS_L, READ, EYE_R
from common_e9 import _hold
from clips_lion2 import STANCE

N = "Lion."


# ================================================================== helpers
def arm_points(side, a):
    """Elbow, wrist and hand centre of an arm spec, in the chest frame
    (UpperTorso axes, origin at the waist pivot): nd_rig.JOINTS / PARTS."""
    sgn = 1 if side == "R" else -1
    sh, el, wr = nd_anim.arm_rot(side, a)
    elbow = Vector((1.05 * sgn, .95, 0)) + sh @ Vector((.4 * sgn, -1.05, 0))
    wrist = elbow + sh @ el @ Vector((0, -.93, 0))
    hand = wrist + sh @ el @ wr @ Vector((0, -.25, 0))
    return elbow, wrist, hand


def solve(side, target, init, keys=("raise", "out", "twist", "elbow"), reg=.004):
    """The arm spec closest to `init` that puts the hand centre on `target`
    (chest frame): a hand that must touch something touches it."""
    a = merge(ZERO["ra"], init)

    def cost(b):
        c = (arm_points(side, b)[2] - target).length_squared
        for k in keys:
            c += reg * ((b[k] - a0[k]) / 10.0) ** 2
        return c
    a0 = dict(a)
    best, step = cost(a), 8.0
    while step > .2:
        better = False
        for k in keys:
            for d in (step, -step):
                b = dict(a)
                b[k] = b[k] + d
                if k == "elbow":
                    b[k] = max(0.0, min(150.0, b[k]))
                c = cost(b)
                if c < best:
                    a, best, better = b, c, True
        if not better:
            step *= .5
    return {k: round(v, 1) for k, v in a.items()}


def mouth(head, ahead=.32):
    """Where a hand held at the mouth sits (chest frame) for a head spec."""
    return Vector((0, 1.4, 0)) + nd_anim.ori(head) @ Vector((0, .3, -.75 - ahead))


def ring(pose, init=None):
    """The right hand brought to the mouth (the fire's ring of fingers)."""
    ra = solve("R", mouth(pose.get("head")), init or {"raise": 100, "out": -36, "twist": 60, "elbow": 132, "wrist": 0})
    return merge(pose, {"ra": ra})


def cut(arm, prefix, keys, fa, end, marker, drags=()):
    """Release = the timeline up to `end`, Recover = from the Active frame
    `fa` on (both need a key): one act seen as the engine plays it."""
    keys = sorted(keys, key=lambda k: k[0])
    frames = [k[0] for k in keys]
    if fa not in frames or end not in frames:
        raise ValueError("%s: keys %s need %d and %d" % (prefix, frames, fa, end))
    full, poses = {}, []
    for f, p, sp in keys:
        full = merge(full, p)
        poses.append((f, full, sp))
    re = Shot(arm, prefix + ".Release")
    rc = Shot(arm, prefix + ".Recover")
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
    return [re.build(markers={"release": marker / 60}), rc.build()]


def lean(pose, **parts):
    """A pose with a few channels nudged by deltas (a breath, a shudder)."""
    out = merge(pose, {})
    for part, deltas in parts.items():
        d = dict(out.get(part, {}))
        for k, v in deltas.items():
            d[k] = d.get(k, 0) + v
        out[part] = d
    return out


# ================================================================ FireBloom
def firebloom(arm):
    out = []
    ch = Shot(arm, N + "FireBloom.Channel")
    ch.key(0, s(), "ease")
    # The seals at the chest while the body sinks and squares to the target.
    b1 = s({"root": {"y": -.62, "z": -.02, "pitch": 12, "yaw": 26}, "torso": {"pitch": 8, "yaw": -10}, "head": {"pitch": -4, "yaw": -16}})
    ch.key(4, seal(3, b1), "impact")
    b2 = merge(b1, {"root": {"y": -.74, "z": 0, "pitch": 14, "yaw": 24}, "torso": {"pitch": 10, "yaw": -8}})
    ch.key(8, seal(1, b2), "impact")
    # The breath starts: the hands part (the right one rising, the left
    # dropping), the hips start back, the chest lifts.
    pre = s({"root": {"y": -.8, "z": .14, "pitch": 2, "yaw": 34}, "torso": {"pitch": -8, "yaw": -14}, "head": {"pitch": -6, "yaw": -20},
             "la": {"raise": 6, "out": 26, "twist": -10, "elbow": 96, "wrist": 0}})
    pre = ring(pre, {"raise": 90, "out": -30, "twist": 56, "elbow": 126, "wrist": 0})
    ch.key(13, pre, "pass")
    # The inhale: sat back over the loaded rear leg, chest arched and full,
    # head back, the elbow high at the mouth, the left fist pulled to the hip.
    inhale = s({"root": {"y": -.84, "z": .32, "pitch": -12, "yaw": 42, "roll": 4}, "torso": {"pitch": -22, "yaw": -18, "roll": -2},
                "head": {"pitch": -12, "yaw": -24},
                "la": {"raise": -26, "out": 34, "twist": -20, "elbow": 100, "wrist": -10},
                "rf": {"toe": 0}, "lf": {"toe": 12}})
    inhale = ring(inhale)
    ch.key(19, inhale, "ease")
    ch.drag(["neck"], 1).drag(["forearm.L", "hand.L"], 1)
    out.append(ch.build(markers={"release": 19 / 60}))

    # Hold: two swells of the chest per loop, the hips settling lower, the
    # elbow lifting with the breath (never still).
    ho = Shot(arm, N + "FireBloom.Hold")
    swell = ring(lean(inhale, root={"y": -.05, "z": .04, "pitch": -2}, torso={"pitch": -5}, head={"pitch": -3},
                      la={"raise": -6, "elbow": 6}))
    mid = ring(lean(inhale, root={"y": -.02, "z": .02}, torso={"pitch": -2, "roll": 2}, head={"pitch": -1}))
    ho.key(0, inhale, "ease")
    ho.key(12, swell, "ease")
    ho.key(20, mid, "ease")
    ho.key(31, ring(lean(swell, torso={"pitch": -2, "roll": -2}, root={"y": -.02})), "ease")
    ho.key(40, inhale, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))

    # Release (Active .40 = 24 f, the ball leaves at 4 f) and Recover.
    hips = merge(inhale, {"root": {"y": -.86, "z": .06, "pitch": 8, "yaw": 30, "roll": 0}, "torso": {"pitch": -12, "yaw": -12},
                          "lf": {"toe": 0}})
    hips = ring(hips)
    blow = s({"root": {"y": -.9, "z": -.5, "pitch": 30, "yaw": 16, "roll": 0}, "torso": {"pitch": 18, "yaw": -4, "roll": 0},
              "head": {"pitch": -30, "yaw": -12},
              "la": {"raise": -52, "out": 30, "twist": 0, "elbow": 18, "wrist": 0},
              "rf": {"y": .12, "toe": -34, "yaw": 30}, "lf": {"toe": 0}})
    blow = ring(blow, {"raise": 120, "out": -30, "twist": 60, "elbow": 128, "wrist": 0})
    over = ring(lean(blow, root={"z": -.07, "pitch": 5, "y": -.03}, torso={"pitch": 4}, head={"pitch": -4}, la={"raise": -8}))
    pump1 = ring(lean(blow, root={"z": .03, "pitch": -2}, torso={"pitch": -3}))
    pump2 = ring(lean(blow, root={"z": -.05, "pitch": 3}, torso={"pitch": 3}, head={"pitch": -2}))
    keys = [(0, inhale, "launch"), (2, hips, "pass"), (4, blow, "impact"), (8, over, "ease"), (13, pump1, "ease"),
            (18, pump2, "ease"), (24, pump1, "ease")]
    # Recover (.36): he rocks back up out of the lunge, the arm comes down
    # from the mouth, a small dip into the guard.
    back = s({"root": {"y": -.7, "z": -.12, "pitch": 12, "yaw": 26}, "torso": {"pitch": 0, "yaw": -10}, "head": {"pitch": -8, "yaw": -16},
              "ra": {"raise": 80, "out": -24, "twist": 40, "elbow": 112, "wrist": 0},
              "la": {"raise": 20, "out": 20, "twist": 0, "elbow": 70, "wrist": 0},
              "rf": {"y": 0, "toe": 0, "yaw": 38}})
    keys += [(31, back, "pass"), (39, s({"root": {"y": -.58}}), "pass"), (46, s(), "ease")]
    out += cut(arm, N + "FireBloom", keys, 24, 24, 4, drags=[(["neck"], 1), (["forearm.L", "hand.L"], 2)])
    return out


# ============================================================ PhoenixFlower
def phoenix(arm):
    out = []
    ch = Shot(arm, N + "PhoenixFlower.Channel")
    ch.key(0, s(), "ease")
    b1 = s({"root": {"y": -.6, "pitch": 12, "yaw": 28}, "torso": {"pitch": 8, "yaw": -12}, "head": {"pitch": -4, "yaw": -16}})
    ch.key(4, seal(4, b1), "impact")
    ch.key(8, seal(1, merge(b1, {"root": {"y": -.68}})), "impact")
    # A short, sharp inhale: the head snaps back, the left hand goes to the
    # back pouch for the two hidden shuriken.
    inhale = s({"root": {"y": -.72, "z": .18, "pitch": -6, "yaw": 36}, "torso": {"pitch": -14, "yaw": -14},
                "head": {"pitch": -16, "yaw": -22},
                "la": {"raise": -36, "out": 26, "twist": 30, "elbow": 74, "wrist": 20}})
    inhale = ring(inhale)
    ch.key(17, inhale, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 17 / 60}))

    def puff(aim, lean_, la=None):
        """A pump of the chest aimed `aim` degrees right of the target."""
        p = s({"root": {"y": -.8, "z": -.26, "pitch": 16 + lean_, "yaw": 30 + aim * .5, "roll": 0},
               "torso": {"pitch": 12 + lean_, "yaw": -14 + aim * .3, "roll": 0},
               "head": {"pitch": -22 - lean_ * .5, "yaw": -16 + aim * .2},
               "la": la or {"raise": -36, "out": 26, "twist": 30, "elbow": 74, "wrist": 20},
               "rf": {"y": .06, "toe": -18}})
        return ring(p, {"raise": 112, "out": -32, "twist": 60, "elbow": 130, "wrist": 0})
    flick0 = {"raise": 10, "out": 20, "twist": 10, "elbow": 60, "wrist": 30}
    flick = {"raise": 72, "out": 30, "twist": -20, "elbow": 6, "wrist": -34}
    keys = [(0, inhale, "launch"),
            (3, puff(-26, 8), "impact"), (6, puff(-20, -2), "ease"),
            (9, puff(0, 10), "impact"), (12, puff(2, -2), "ease"),
            (15, puff(26, 8, flick0), "impact"),
            (19, puff(30, 2, flick), "pass"),
            (24, puff(28, 0, merge(flick, {"raise": 62, "out": 40, "elbow": 14, "wrist": -20})), "ease"),
            (31, s({"root": {"y": -.64, "z": -.08}, "ra": {"raise": 72, "out": -20, "elbow": 112},
                    "la": {"raise": 56, "out": 16, "elbow": 54}}), "pass"),
            (39, s(), "ease")]
    out += cut(arm, N + "PhoenixFlower", keys, 19, 24, 3, drags=[(["neck"], 1), (["hand.L"], 1)])
    return out


# ================================================================= WireTrap
def wire_trap(arm):
    out = []
    ch = Shot(arm, N + "WireTrap.Channel")
    ch.key(0, s(), "ease")
    reach = s({"root": {"y": -.66, "z": .1, "pitch": 12, "yaw": 46}, "torso": {"pitch": 8, "yaw": 4}, "head": {"pitch": -8, "yaw": -48},
               "ra": {"raise": -30, "out": 30, "twist": 30, "elbow": 70, "wrist": 20},
               "la": {"raise": 60, "out": 40, "twist": 0, "elbow": 40}})
    ch.key(5, reach, "pass")
    # Side-on over the loaded rear leg, the throwing hand cocked behind the
    # hip, the left arm aiming at him, the front foot light.
    wind = s({"root": {"y": -.8, "z": .2, "pitch": 12, "yaw": 64, "roll": 4}, "torso": {"pitch": 6, "yaw": 20},
              "head": {"pitch": -8, "yaw": -80},
              "ra": {"raise": 6, "out": 52, "twist": -10, "elbow": 96, "wrist": 40},
              "la": {"raise": 20, "out": 74, "twist": 0, "elbow": 12, "wrist": -10},
              "rf": {"yaw": 50}, "lf": {"toe": -10, "y": .04}})
    ch.key(10, wind, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 10 / 60}))

    # The throw (Active .08 = 5 f; the shuriken leaves at 4 f): the hips
    # unwind first (the arm stays back), then the arm whips out flat.
    hips = merge(wind, {"root": {"y": -.76, "z": .1, "yaw": 38, "roll": 0}, "torso": {"yaw": 30}, "head": {"yaw": -66},
                        "ra": {"raise": 20, "out": 62, "elbow": 80}, "lf": {"toe": 0, "y": 0}})
    throw = s({"root": {"y": -.72, "z": -.28, "pitch": 16, "yaw": -8, "roll": -4}, "torso": {"pitch": 10, "yaw": -30},
               "head": {"pitch": -12, "yaw": 34},
               "ra": {"raise": 84, "out": 30, "twist": -20, "elbow": 4, "wrist": -34},
               "la": {"raise": 16, "out": 40, "twist": 0, "elbow": 64, "wrist": 0},
               "rf": {"y": .1, "toe": -34, "yaw": 20}, "lf": {"y": 0, "toe": 0}})
    follow = merge(throw, {"root": {"yaw": -14}, "torso": {"yaw": -38}, "head": {"yaw": 40},
                           "ra": {"raise": 72, "out": 2, "elbow": 14, "wrist": -20}})
    # Recover (.30): the left hand catches the wire out in front, then the
    # haul - he drops and sits back against it, the right fist yanked to the
    # hip; the wire bites back; the fist brings it up to the teeth, the left
    # hand holding the line taut out in front.
    catch = s({"root": {"y": -.76, "z": -.14, "pitch": 12, "yaw": 4, "roll": 0}, "torso": {"pitch": 6, "yaw": -22},
               "head": {"pitch": -10, "yaw": 18},
               "ra": {"raise": 78, "out": 0, "twist": -10, "elbow": 20, "wrist": 0},
               "la": {"raise": 84, "out": 14, "twist": -10, "elbow": 8, "wrist": 0},
               "rf": {"y": 0, "toe": 0, "yaw": 38}, "lf": {"toe": 0}})
    haul = s({"root": {"y": -1.0, "z": .38, "pitch": -10, "yaw": 50, "roll": 6}, "torso": {"pitch": -14, "yaw": -14, "roll": 0},
              "head": {"pitch": -2, "yaw": -36},
              "ra": {"raise": -18, "out": 26, "twist": 0, "elbow": 98, "wrist": 0},
              "la": {"raise": 62, "out": 22, "twist": -10, "elbow": 30, "wrist": -10},
              "rf": {"toe": 0}, "lf": {"toe": 16}})
    bite = lean(haul, root={"y": .06, "z": -.1, "pitch": 6}, torso={"pitch": 6}, la={"raise": 8, "elbow": -12}, ra={"raise": 10},
                lf={"toe": -16})
    teeth = s({"root": {"y": -.92, "z": .3, "pitch": -4, "yaw": 46, "roll": 2}, "torso": {"pitch": -8, "yaw": -14},
               "head": {"pitch": 4, "yaw": -32},
               "la": {"raise": 84, "out": 16, "twist": -10, "elbow": 4, "wrist": -6}, "lf": {"toe": 6}})
    teeth = ring(teeth, {"raise": 100, "out": -36, "twist": 60, "elbow": 134, "wrist": 0})
    taut = ring(lean(teeth, root={"y": -.03, "z": .03}, torso={"pitch": -2}, la={"raise": -2}))
    keys = [(0, wind, "ease"), (2, hips, "pass"), (4, throw, "impact"), (5, merge(throw, {"torso": {"yaw": -33}, "ra": {"out": 22}}), "pass"),
            (8, follow, "ease"), (10, merge(follow, {"la": {"raise": 40, "elbow": 40}}), "pass"),
            (13, catch, "pass"), (18, haul, "impact"), (21, bite, "ease"), (25, teeth, "impact"), (27, taut, "ease")]
    out += cut(arm, N + "WireTrap", keys, 5, 10, 4, drags=[(["neck"], 1), (["hand.R"], 1)])
    return out


# ================================================================== Chidori
def chidori(arm):
    out = []
    fo = Shot(arm, N + "Chidori.Form")
    fo.key(0, s(), "ease")
    WR = {"x": .48, "z": 1.0, "yaw": 52}
    WL = {"x": -.34, "z": -.98, "yaw": -8}
    # the feet hop wide one after the other while he drops
    fo.key(4, s({"root": {"y": -.62, "pitch": 16, "yaw": 28}, "torso": {"pitch": 10},
                 "ra": {"raise": 20, "out": 6, "twist": -20, "elbow": 50, "wrist": 10},
                 "la": {"raise": 50, "out": -14, "twist": 30, "elbow": 80},
                 "rf": {"x": .38, "z": .94, "y": .24, "yaw": 46}}), "pass")
    fo.key(7, s({"root": {"y": -.84, "z": .02, "pitch": 20, "yaw": 28}, "torso": {"pitch": 12},
                 "ra": {"raise": 22, "out": -4, "twist": -30, "elbow": 30, "wrist": 24},
                 "la": {"raise": 40, "out": -20, "twist": 36, "elbow": 80},
                 "rf": dict(WR, y=0), "lf": {"x": -.24, "z": -.9, "y": .18}}), "pass")
    # The lightning catches: the right hand low in front of the knees, palm
    # down; the left hand clamps on the right wrist. The jolt.
    low = s({"root": {"y": -1.08, "z": -.04, "pitch": 28, "yaw": 26, "roll": 0}, "torso": {"pitch": 16, "yaw": -6, "roll": 0},
             "head": {"pitch": -36, "yaw": -18},
             "rf": dict(WR, y=0), "lf": dict(WL, y=0)})
    ra = solve("R", Vector((.25, -1.25, -1.15)), {"raise": 30, "out": -8, "twist": -30, "elbow": 18, "wrist": 0})
    ra["wrist"] = 38
    grip_at = arm_points("R", ra)[1] + Vector((-.42, .28, -.05))
    la = solve("L", grip_at, {"raise": 40, "out": -30, "twist": 40, "elbow": 60, "wrist": 0})
    low = merge(low, {"ra": ra, "la": la})
    fo.key(10, low, "impact")
    jolt = lean(low, root={"y": .1, "pitch": -6, "roll": 4}, torso={"pitch": -6, "roll": -6}, head={"pitch": 6, "roll": 4},
                ra={"raise": 8, "elbow": 10})
    jolt["la"] = solve("L", arm_points("R", jolt["ra"])[1] + Vector((-.42, .28, -.05)), la)
    fo.key(13, jolt, "impact")

    def shake(dy, droll, dra, dtw):
        p = lean(low, root={"y": dy, "roll": droll}, torso={"roll": -droll}, ra={"raise": dra, "twist": dtw})
        p["la"] = solve("L", arm_points("R", p["ra"])[1] + Vector((-.42, .28, -.05)), la)
        return p
    fo.key(18, shake(-.06, -2, -4, 6), "ease")
    fo.key(22, shake(-.09, 2, 3, -4), "ease")
    fo.key(26, shake(-.12, -2, -5, 6), "ease")
    fo.key(29, shake(-.14, 2, 4, -6), "ease")
    fo.key(32, shake(-.16, -1, -3, 4), "ease")
    # the grip lets go: the arm is drawn back low into the carry, set to run
    carry_arm = {"raise": -38, "out": 30, "twist": -20, "elbow": 22, "wrist": -12}
    fo.key(37, merge(low, {"root": {"y": -1.02, "z": -.1, "pitch": 30, "yaw": 22}, "torso": {"pitch": 14, "yaw": -4},
                           "head": {"pitch": -34, "yaw": -18},
                           "ra": carry_arm, "la": {"raise": 46, "out": 4, "twist": 0, "elbow": 78, "wrist": 0}}), "ease")
    fo.drag(["neck"], 2).drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(fo.build(markers={"release": 37 / 60}))

    # Hold: the carry (upper body over his run or guard). The lightning hand
    # trails low behind, palm down; it shudders (the birds' chirp).
    ho = Shot(arm, N + "Chidori.Hold")
    carry = s({"torso": {"pitch": 16, "yaw": -2, "roll": 0}, "head": {"pitch": -14, "yaw": -14},
               "ra": carry_arm, "la": {"raise": 50, "out": 6, "twist": 0, "elbow": 80, "wrist": 0}})
    ho.key(0, carry, "ease")
    ho.key(3, lean(carry, ra={"raise": -4, "out": 3, "wrist": 6}, torso={"roll": -2}), "ease")
    ho.key(6, lean(carry, ra={"raise": 3, "out": -2, "wrist": -4, "twist": 4}, la={"elbow": 4}), "ease")
    ho.key(9, lean(carry, ra={"raise": -2, "out": 2, "wrist": 4}, torso={"roll": 2}), "ease")
    ho.key(12, carry, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))
    return out


# ================================================================== Soshuha
def soshuha(arm):
    out = []
    ch = Shot(arm, N + "Soshuha.Channel")
    base = s({"root": {"y": -.56, "pitch": 8}, "head": {"pitch": -2}})
    ch.key(0, seal(1, base), "ease")
    ch.key(3, seal(2, merge(base, {"root": {"y": -.64}})), "impact")
    # the hands dive for the pouches, then cross low in front of the hips
    dive = s({"root": {"y": -.78, "z": .04, "pitch": 16, "yaw": 26}, "torso": {"pitch": 12, "yaw": -10}, "head": {"pitch": -16, "yaw": -14},
              "ra": {"raise": -14, "out": 30, "twist": 30, "elbow": 60, "wrist": 10},
              "la": {"raise": -10, "out": 30, "twist": 30, "elbow": 60, "wrist": 10}})
    ch.key(7, dive, "pass")
    cross = s({"root": {"y": -.94, "z": .08, "pitch": 24, "yaw": 24}, "torso": {"pitch": 20, "yaw": -8},
               "head": {"pitch": -28, "yaw": -14}, "ra": CROSS_R, "la": CROSS_L, "rf": {"toe": 0}})
    ch.key(12, cross, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 12 / 60}))

    fling = s({"root": {"y": -.64, "z": -.38, "pitch": 18, "yaw": 22}, "torso": {"pitch": 0, "yaw": -6},
               "head": {"pitch": -14, "yaw": -14},
               "ra": {"raise": 106, "out": 58, "twist": -16, "elbow": 6, "wrist": -30},
               "la": {"raise": 74, "out": 52, "twist": -16, "elbow": 6, "wrist": -30},
               "rf": {"y": .1, "toe": -30}})
    over = merge(fling, {"root": {"z": -.44, "pitch": 16}, "torso": {"pitch": -6}, "head": {"pitch": -16},
                         "ra": {"raise": 114, "out": 68, "wrist": -38}, "la": {"raise": 80, "out": 64, "wrist": -38}})
    taut = merge(over, {"root": {"y": -.62, "z": -.36}, "ra": {"raise": 100, "out": 58, "elbow": 22, "wrist": 0},
                        "la": {"raise": 72, "out": 54, "elbow": 22, "wrist": 0}})
    pull = s({"root": {"y": -.8, "z": .28, "pitch": -6, "yaw": 32}, "torso": {"pitch": -10, "yaw": -14},
              "head": {"pitch": -2, "yaw": -18},
              "ra": {"raise": -26, "out": 22, "twist": 10, "elbow": 106},
              "la": {"raise": -20, "out": 22, "twist": 10, "elbow": 106},
              "rf": {"y": 0, "toe": 0}, "lf": {"toe": 18}})
    give = merge(pull, {"root": {"y": -.7, "z": .14, "pitch": 0}, "torso": {"pitch": -4}, "ra": {"raise": -4, "elbow": 94},
                        "la": {"raise": 2, "elbow": 94}, "lf": {"toe": 4}})
    tug = merge(give, {"root": {"y": -.74, "z": .2}, "ra": {"raise": -16, "elbow": 102}, "la": {"raise": -10, "elbow": 102}})
    out += act(arm, N + "Soshuha", [(0, cross, "ease"), (2, fling, "impact"), (5, over, "ease"), (8, taut, "ease"),
                                    (11, pull, "impact"), (13, give, "ease"), (15, tug, "ease"), (17, s(), "ease")],
               .04, .24, drags=[(["hand.R", "hand.L"], 1), (["neck"], 1)])
    return out


# =========================================================== WindmillBlades
def windmill(arm):
    out = []
    ch = Shot(arm, N + "WindmillBlades.Channel")
    base = s({"root": {"y": -.54}, "head": {"pitch": -2}})
    ch.key(0, seal(2, base), "ease")
    ch.key(3, seal(3, merge(base, {"root": {"y": -.62}})), "impact")
    draw = s({"root": {"y": -.68, "z": .1, "pitch": 8, "yaw": 52}, "torso": {"pitch": 4, "yaw": 2},
              "head": {"pitch": -6, "yaw": -44},
              "ra": {"raise": -40, "out": 26, "twist": -20, "elbow": 64, "wrist": 20},
              "la": {"raise": 60, "out": 30, "twist": 0, "elbow": 40},
              "rf": {"yaw": 50}, "lf": {"yaw": 6}})
    ch.key(9, draw, "pass")
    coil = s({"root": {"y": -.84, "z": .28, "pitch": 4, "yaw": 80, "roll": 8}, "torso": {"pitch": 0, "yaw": 14},
              "head": {"pitch": -6, "yaw": -90},
              "ra": {"raise": 44, "out": 80, "twist": -20, "elbow": 108, "wrist": 44},
              "la": {"raise": 14, "out": 80, "twist": 0, "elbow": 8, "wrist": -10},
              "rf": {"yaw": 68}, "lf": {"yaw": 24, "toe": -8}})
    ch.key(15, coil, "ease")
    coil2 = lean(coil, root={"y": -.03, "z": .02}, ra={"out": 3, "wrist": 3})
    ch.key(18, coil2, "ease")
    ch.drag(["neck"], 1).drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": 18 / 60}))

    hips = merge(coil2, {"root": {"yaw": 46, "z": .08, "roll": 2}, "torso": {"yaw": 26}, "head": {"yaw": -64},
                         "ra": {"out": 88}, "lf": {"y": .2, "z": -.96, "toe": 0}})
    throw = s({"root": {"y": -.68, "z": -.36, "pitch": 18, "yaw": -12, "roll": -4}, "torso": {"pitch": 10, "yaw": -30},
               "head": {"pitch": -12, "yaw": 22},
               "ra": {"raise": 86, "out": 18, "twist": -30, "elbow": 6, "wrist": -34},
               "la": {"raise": 26, "out": 44, "twist": 0, "elbow": 90},
               "rf": {"y": .1, "toe": -36, "yaw": 14}, "lf": {"z": -1.16, "yaw": -10}})
    follow = merge(throw, {"root": {"yaw": -26}, "torso": {"yaw": -44}, "head": {"yaw": 32},
                           "ra": {"raise": 58, "out": -38, "twist": -10, "elbow": 26, "wrist": -10}})
    rest = merge(follow, {"root": {"y": -.62, "z": -.28}, "ra": {"raise": 62}})
    lift = merge(rest, {"root": {"y": -.6, "z": -.1, "yaw": 0}, "torso": {"yaw": -28},
                        "la": {"raise": 60, "out": 20, "elbow": 40},
                        "lf": {"y": .22, "z": -.86, "yaw": -8}, "rf": {"y": 0, "toe": 0}})
    yank = s({"root": {"y": -.76, "z": .14, "pitch": 8, "yaw": 34}, "torso": {"pitch": 0, "yaw": -20},
              "head": {"pitch": -6, "yaw": -14},
              "ra": {"raise": -28, "out": 26, "twist": -10, "elbow": 98},
              "la": {"raise": 78, "out": 8, "twist": -10, "elbow": 20, "wrist": -14}})
    taut = merge(yank, {"root": {"y": -.72, "z": .08}, "ra": {"raise": -30}, "la": {"raise": 80}})
    out += act(arm, N + "WindmillBlades", [(0, coil2, "ease"), (2, hips, "pass"), (4, throw, "impact"), (7, follow, "ease"),
                                           (10, rest, "ease"), (12, lift, "pass"), (14, yank, "impact"), (17, taut, "ease"),
                                           (21, s(), "ease")],
               .06, .26, drags=[(["hand.R"], 1), (["neck"], 1)])
    return out


# ========================================================= SharinganCounter
def counter(arm):
    out = []
    ch = Shot(arm, N + "SharinganCounter.Channel")
    base = s({"root": {"y": -.56}, "head": {"pitch": -2}})
    ch.key(0, seal(3, base), "ease")
    pose = merge(base, {"root": {"y": -.66}})
    sealed = seal(4, pose)
    ch.key(3, sealed, "impact")
    out.append(ch.build(markers={"release": 3 / 60}))

    read = s(READ)
    keys = [(0, sealed, "ease"),
            (2, merge(sealed, {"root": {"y": -.76, "z": .12}, "head": {"pitch": -6},
                               "la": {"raise": 70, "out": -6, "twist": -10, "elbow": 70}, "ra": {"raise": 46, "elbow": 100},
                               "lf": {"z": -.64, "y": .16, "toe": -20}}), "pass"),
            (5, merge(read, {"root": {"y": -1.0}}), "impact"),
            (8, read, "ease"),
            (10, merge(read, {"root": {"y": -.97, "z": .32}, "head": {"roll": -1, "yaw": -20}, "la": {"raise": 98}}), "ease"),
            (12, merge(read, {"root": {"y": -.78, "z": .16}, "la": {"raise": 80, "elbow": 50},
                              "lf": {"z": -.66, "y": .2, "toe": -16}}), "pass"),
            (15, s(), "ease")]
    out += act(arm, N + "SharinganCounter", keys, .04, .2, drags=[(["neck"], 1)], marker=2)
    return out


# ============================================================ SharinganCopy
def copy(arm):
    out = []
    ch = Shot(arm, N + "SharinganCopy.Channel")
    base = s({"root": {"y": -.54}, "head": {"pitch": 0}})
    ch.key(0, seal(4, base), "ease")
    ch.key(3, seal(1, merge(base, {"root": {"y": -.6}})), "impact")
    focus = s({"root": {"y": -.66, "z": .06, "pitch": 6, "yaw": 34}, "torso": {"pitch": 4, "yaw": -18},
               "head": {"pitch": 12, "yaw": -14},
               "ra": EYE_R, "la": {"raise": 44, "out": -20, "twist": 40, "elbow": 100, "wrist": 10}})
    ch.key(8, focus, "ease")
    gather = merge(focus, {"root": {"y": -.74, "z": .2, "pitch": 2}, "head": {"pitch": -12},
                           "la": {"raise": -12, "out": 22, "twist": -60, "elbow": 100, "wrist": -20}})
    ch.key(13, gather, "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": 13 / 60}))

    cast = s({"root": {"y": -.64, "z": -.38, "pitch": 16, "yaw": 22}, "torso": {"pitch": 8, "yaw": -6},
              "head": {"pitch": -10, "yaw": -14},
              "la": {"raise": 92, "out": 0, "twist": -72, "elbow": 4, "wrist": -62},
              "ra": EYE_R, "rf": {"y": .08, "toe": -24}})
    keys = [(0, gather, "ease"),
            (2, merge(gather, {"root": {"y": -.7, "z": .02, "pitch": 8}, "torso": {"pitch": 6},
                               "la": {"raise": 40, "out": 10, "twist": -50, "elbow": 70, "wrist": -30}}), "pass"),
            (4, cast, "impact"),
            (7, merge(cast, {"root": {"z": -.44}, "la": {"raise": 94, "elbow": 0}}), "ease"),
            (10, merge(cast, {"root": {"z": -.38}}), "ease"),
            (14, s({"root": {"y": -.58, "z": -.16}, "la": {"raise": 70, "elbow": 50},
                    "ra": {"raise": 76, "out": 4, "twist": 34, "elbow": 112}}), "pass"),
            (20, s(), "ease")]
    out += act(arm, N + "SharinganCopy", keys, .06, .26, drags=[(["neck"], 1), (["shoulder.R", "forearm.R", "hand.R"], 1)])
    return out


# =================================================================== Awaken
def awaken(arm):
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    neck_l = Vector((-.62, 1.5, -.3))
    jolt = s({"root": {"y": -.42, "z": .04, "pitch": 4, "yaw": 26, "roll": 0}, "torso": {"pitch": -2, "yaw": -12, "roll": -12},
              "head": {"pitch": -6, "yaw": -10, "roll": -16},
              "la": {"raise": 24, "out": 52, "twist": 0, "elbow": 30, "wrist": 0}})
    jolt["ra"] = solve("R", neck_l, {"raise": 110, "out": -60, "twist": 40, "elbow": 140, "wrist": 20})
    sh.key(3, jolt, "impact")
    # folded over the pain, a knee nearly to the floor
    fold = s({"root": {"y": -1.3, "z": .1, "pitch": 34, "yaw": 22, "roll": -4}, "torso": {"pitch": 30, "yaw": -6, "roll": -14},
              "head": {"pitch": 18, "yaw": -10, "roll": -10},
              "la": {"raise": 30, "out": 14, "twist": 0, "elbow": 50, "wrist": 30},
              "rf": {"y": .14, "toe": -44}})
    fold["ra"] = solve("R", neck_l, jolt["ra"])
    sh.key(9, fold, "impact")
    sh.key(14, lean(fold, root={"y": -.05, "roll": -2}, torso={"roll": -5}, head={"roll": -3}), "ease")
    sh.key(18, lean(fold, root={"y": .02, "roll": 1}, torso={"roll": 2, "pitch": 2}), "ease")
    # the marks spread: he rises arching, head back, arms flung out and down
    surge = s({"root": {"y": -.46, "z": .08, "pitch": -14, "yaw": 20, "roll": 0}, "torso": {"pitch": -28, "yaw": -6, "roll": 0},
               "head": {"pitch": -30, "yaw": -6, "roll": 0},
               "ra": {"raise": -8, "out": 72, "twist": 0, "elbow": 28, "wrist": 30},
               "la": {"raise": -8, "out": 72, "twist": 0, "elbow": 28, "wrist": 30},
               "rf": {"y": 0, "toe": 0}})
    sh.key(24, surge, "impact")
    sh.key(30, lean(surge, torso={"pitch": -4}, head={"pitch": -4}, ra={"out": 5}, la={"out": 5}, root={"y": .03}), "ease")
    curse = s({"root": {"y": -1.04, "z": -.16, "pitch": 32, "yaw": 26, "roll": 0}, "torso": {"pitch": 22, "yaw": -8, "roll": 0},
               "head": {"pitch": -36, "yaw": -18, "roll": 0},
               "la": {"raise": 52, "out": 32, "twist": 0, "elbow": 40, "wrist": 26},
               "ra": {"raise": 30, "out": 42, "twist": 0, "elbow": 62, "wrist": 26},
               "lf": {"toe": 0}})
    sh.key(37, curse, "impact")
    sh.key(42, lean(curse, root={"y": .05, "pitch": -2}, torso={"pitch": -3}), "ease")
    sh.key(48, lean(curse, root={"y": -.02}), "ease")
    sh.drag(["neck"], 1).drag(["forearm.L", "hand.L"], 1)
    return sh.build()


# =================================================================== throws
def throw_shuriken(arm):
    sh = Shot(arm, N + "Throw.Shuriken")
    sh.key(0, s(), "ease")
    cock = s({"torso": {"yaw": 24, "pitch": 4}, "head": {"yaw": -32},
              "la": {"raise": 70, "out": -62, "twist": 40, "elbow": 130, "wrist": 24},
              "ra": {"raise": 30, "out": -6, "twist": 20, "elbow": 110}})
    sh.key(5, cock, "ease")
    sh.key(7, merge(cock, {"torso": {"yaw": 4}, "head": {"yaw": -18}, "la": {"raise": 80, "out": -20, "elbow": 80, "wrist": 30}}), "pass")
    rel = s({"torso": {"yaw": -18, "pitch": 6}, "head": {"yaw": -10},
             "la": {"raise": 86, "out": 34, "twist": -20, "elbow": 10, "wrist": -26},
             "ra": {"raise": 40, "out": 10, "twist": 20, "elbow": 100}})
    sh.key(8, rel, "impact")
    sh.key(10, merge(rel, {"la": {"wrist": 4, "elbow": 16}}), "ease")
    sh.key(12, merge(rel, {"torso": {"yaw": -24}, "la": {"out": 46, "wrist": -32, "elbow": 6}}), "impact")
    sh.key(16, merge(rel, {"torso": {"yaw": -22}, "la": {"raise": 78, "out": 52, "wrist": -20, "elbow": 14}}), "ease")
    sh.key(24, s(), "ease")
    sh.drag(["neck"], 1).drag(["hand.L"], 1)
    return sh.build(markers={"release": 8 / 60})


def grab_throw(arm):
    S = STANCE
    hold = _hold(S)
    sh = Shot(arm, N + "Throw")
    sh.key(0, hold, "ease")
    y = S["root"]["y"]
    load = merge(hold, {"root": {"y": y - .3, "z": -.06, "pitch": 14, "yaw": 36}, "torso": {"pitch": 8, "yaw": 18},
                        "head": {"yaw": -26},
                        "ra": {"raise": 60, "out": 22, "twist": 0, "elbow": 96}, "la": {"raise": 82, "out": -34, "twist": 0, "elbow": 66},
                        "rf": {"toe": 10}})
    sh.key(4, load, "ease")
    sh.key(6, merge(load, {"root": {"yaw": 6, "y": y - .28}, "torso": {"yaw": 14}}), "pass")
    heave = merge(hold, {"root": {"y": y - .22, "z": -.34, "pitch": 18, "yaw": -40}, "torso": {"pitch": 14, "yaw": -26},
                         "head": {"yaw": 26, "pitch": -4},
                         "ra": {"raise": 84, "out": -40, "twist": 20, "elbow": 22},
                         "la": {"raise": 36, "out": 44, "twist": 0, "elbow": 34},
                         "rf": {"y": .1, "toe": -30, "yaw": S["rf"]["yaw"] - 34}})
    sh.key(8, heave, "impact")
    sh.key(13, merge(heave, {"root": {"yaw": -54, "pitch": 22, "y": y - .3}, "torso": {"yaw": -34, "pitch": 18}, "head": {"yaw": 34},
                             "ra": {"raise": 56, "out": -50, "elbow": 30}, "la": {"raise": 22, "out": 56, "elbow": 30}}), "ease")
    sh.key(21, merge(s({"root": {"y": y - .14, "yaw": 10}, "torso": {"yaw": -6}}),
                     {"rf": {"y": .04, "toe": -8, "yaw": S["rf"]["yaw"] - 10}}), "pass")
    sh.key(34, s(), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R"], 1)
    return sh.build(markers={"contact": 7 / 60, "recover": 13 / 60})


def author(arm):
    acts = []
    acts += firebloom(arm)
    acts += phoenix(arm)
    acts += wire_trap(arm)
    acts.append(awaken(arm))
    acts += chidori(arm)
    acts.append(throw_shuriken(arm))
    acts.append(grab_throw(arm))
    acts += soshuha(arm)
    acts += windmill(arm)
    acts += counter(arm)
    acts += copy(arm)
    return acts
