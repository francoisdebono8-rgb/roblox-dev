"""Neji's seal jutsu and the string's middle hit (04/11, user: « fais-moi de
belles animations, applique-toi bien »). Authored on his body (neji_p9.STANCE:
deep and side-on, the lead palm forward low and open, the rear palm high by
the ear; the body moves as one block on the feet, the strikes are short,
straight and exact - fingers and palm heels, never a fist). The player has
woven the two seals already (the engine draws them as they are pressed); a
channel long enough picks up from the last one, snapped (nd_seals), then the
act:

  LegPoints.Channel   (.06 s, no seal) the Byakugan drops to the legs: the
                      head dips, the lead hand's two fingers turn down, the
                      rear hand drops to the hip, chambered
  LowPalm             (strike) he drops in one block, almost onto the rear
                      knee, and the two fingers go into the front thigh; the
                      rear hand follows into the other leg (two points, one
                      per leg, inside the active window)
  Hasangeki.*         the snake snapped, then both arms draw one big circle and
                      bring the two palms, heel to heel, back to the right
                      hip; released, they are driven out together at full
                      reach on a lunge (the mountain crusher's wave)
  GentleCounter.*     the rat snapped, and the reading guard: the weight
                      sinks back, the lead foot draws a half circle in, both
                      palms open in front, crossed to turn a blow aside; held,
                      still, the Byakugan on the attacker
  TrigramField.*      the tiger snapped, then the lead foot draws the circle round
                      him on the floor while the arms circle up; released, he
                      drops into a wide square stance and presses both palms
                      down and out: the trigrams spread under him
  Light4              (string, body) the lead palm rolls the guard aside and
                      the rear palm heel drives in under it, into the ribs,
                      on a half step to the outside

Limbs are aimed with the calibrated helpers of jutsu_lee (aim, leg, reach,
face: exact on the control rig).

Server timings (Shared/SealJutsu, Shared/Attacks):
  LegPoints     channel .06   LowPalm .08 / .10 / .26   contact 5 recover 11 end 28
  Hasangeki     channel .30 act .08 rec .32
  GentleCounter channel .04 act .04 rec .20 (stance window .7; the answer
                is PalmThrust, his own clip)
  TrigramField  channel .30 act .12 rec .26
  Light4        .09 / .12 / .28 (x.92)   contact 5 recover 12 end 29
"""
from mathutils import Vector
from nd_shot import Shot, merge
import nd_seals
import neji_p9
import jutsu_lee as J
from jutsu_lee import aim, reach, face, act, RF, LF, hip_at, shoulder_at, body_rot, chest_rot, hand_at

N = "GentleFist."
STANCE = merge(neji_p9.STANCE, {"travel": {"x": 0, "z": 0, "yaw": 0}})
PALM = neji_p9.PALM
FINGERS = neji_p9.FINGERS
FEET = {"rf": RF(.88, .8, yaw=64), "lf": LF(-.64, -.8, yaw=26)}


def s(over=None):
    return merge(merge(STANCE, FEET), over or {})


def at(T, over=None):
    return s(merge({"travel": {"z": T}, "rf": RF(.88, .8 + T, yaw=64), "lf": LF(-.64, -.8 + T, yaw=26)}, over or {}))


def pose(over, **limbs):
    return J.pose(merge(FEET, over or {}), base=STANCE, **limbs)


def seal(sh, sign, frame=3):
    """The jutsu's last seal snapped from his stance, the head level (the
    player wove the two seals already: Client/VelmoraMotionEngine draws them
    as they are pressed; the channel picks up from the second). Returns the
    frame of the seal."""
    sh.key(frame, pose(merge({"root": {"y": -.72}}, nd_seals.seal(sign)), head=lambda p: face(p, 0, elev=-2)), "impact")
    return frame


# ================================================== leg points / low palm
def leg_points_channel(arm):
    sh = Shot(arm, N + "LegPoints.Channel")
    sh.key(0, s(), "ease")
    last = 0
    # (.06 s: no room for a seal) The Byakugan drops to the legs: the head dips, the two fingers of the
    # lead hand turn down at them, the rear hand drops to the hip.
    look = pose({"root": {"y": -.8, "z": .04, "pitch": 10, "yaw": 48}, "torso": {"pitch": 8, "yaw": -22},
                 "ra": {"raise": 14, "out": 12, "twist": -30, "elbow": 104, "wrist": 0}},
                la=lambda p: aim(p, "L", -2, -34, twist=-10, elbow=26, wrist=0),
                head=lambda p: face(p, 0, elev=-24))
    sh.key(last + 4, look, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"release": (last + 4) / 60}), look


def low_palm(arm, look):
    """The strike (.08 / .10 / .26: contact 5, recover 11, end 28). One block
    down onto the rear knee as the front foot slides: the lead hand's two
    fingers into the front thigh (contact), then the rear hand's into the
    other leg, the hips turning behind it; he rises back into his stance."""
    sh = Shot(arm, N + "LowPalm")
    T = -.7
    sh.key(0, look, "ease")
    drop = pose({"travel": {"z": T * .5}, "root": {"y": -1.1, "z": -.12, "pitch": 14, "yaw": 46}, "torso": {"pitch": 12, "yaw": -20},
                 "ra": {"raise": 10, "out": 12, "twist": -30, "elbow": 108, "wrist": 0},
                 "lf": LF(-.64, -1.3, y=.16, toe=6, yaw=24), "rf": RF(.88, .8, toe=-20, yaw=64)},
                la=lambda p: aim(p, "L", -2, -30, twist=-10, elbow=48, wrist=0),
                head=lambda p: face(p, 0, elev=-28))
    sh.key(3, drop, "pass")
    hit = pose({"travel": {"z": T}, "root": {"y": -1.38, "z": -.3, "pitch": 16, "yaw": 44}, "torso": {"pitch": 14, "yaw": -16},
                "ra": {"raise": 12, "out": 12, "twist": -30, "elbow": 110, "wrist": 0},
                "lf": LF(-.64, -1.75, yaw=24), "rf": RF(.88, .8, toe=-44, yaw=64)},
               la=lambda p: aim(p, "L", -2, -30, twist=-10, elbow=0, wrist=0),
               head=lambda p: face(p, 0, elev=-28))
    sh.key(5, hit, "impact")
    # the second point: the rear hand's two fingers into the other leg, the
    # hips turning in behind them, the lead hand drawn back to the guard
    two = pose({"travel": {"z": T}, "root": {"y": -1.4, "z": -.34, "pitch": 16, "yaw": 26}, "torso": {"pitch": 14, "yaw": -18},
                "la": {"raise": 54, "out": 8, "twist": -40, "elbow": 70, "wrist": -30},
                "lf": LF(-.64, -1.75, yaw=22), "rf": RF(.88, .8, toe=-46, yaw=50)},
               ra=lambda p: aim(p, "R", 4, -28, twist=-10, elbow=0, wrist=0),
               head=lambda p: face(p, 0, elev=-28))
    sh.key(8, two, "impact")
    sh.key(11, merge(two, {"root": {"z": -.37, "y": -1.42}}), "ease")
    # he rises in one block, the hands climbing back into the guard
    up = pose({"travel": {"z": T}, "root": {"y": -.9, "z": -.72, "pitch": 10, "yaw": 42}, "torso": {"pitch": 6, "yaw": -22},
               "la": {"raise": 62, "out": 6, "twist": -40, "elbow": 30, "wrist": -30},
               "ra": {"raise": 76, "out": -6, "twist": -40, "elbow": 104, "wrist": -30},
               "lf": LF(-.64, -1.75, yaw=24), "rf": RF(.88, .5, y=.12, toe=-16, yaw=60)},
              head=lambda p: face(p, 0, elev=-8))
    sh.key(18, up, "pass")
    sh.key(28, at(T - .25, {"lf": LF(-.64, -1.75, yaw=26), "rf": RF(.88, .05, yaw=64)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["hand.L", "hand.R"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 11 / 60})


# =============================================================== hasangeki
def _load():
    """Both palms drawn to the right hip, heel to heel (the left over the
    right), the hips coiled back to the right, low, the weight on the rear
    foot; the head stays on him."""
    p = pose({"root": {"y": -1.0, "z": .14, "pitch": 8, "yaw": 74}, "torso": {"pitch": 6, "yaw": -14},
              "lf": LF(-.64, -1.1, yaw=30), "rf": RF(.88, .8, yaw=70)},
             head=lambda p: face(p, 0, elev=-4))
    h = hip_at(p, "R") + body_rot(p) @ Vector((.2, .45, -.55))
    p["ra"] = reach(p, "R", h, start={"raise": 20, "out": 20, "twist": -60, "elbow": 100}, wrist=-60)
    p["la"] = reach(p, "L", h + body_rot(p) @ Vector((-.05, .42, -.1)), start={"raise": 40, "out": -40, "twist": -40, "elbow": 110}, wrist=-60)
    return p


def _thrust():
    """Both palms driven out together at full reach, heels first, on a lunge:
    the hips square behind them, the rear leg long."""
    return pose({"travel": {"z": 0}, "root": {"y": -1.0, "z": -.62, "pitch": 14, "yaw": 16}, "torso": {"pitch": 6, "yaw": -14},
                 "lf": LF(-.64, -1.1, yaw=24), "rf": RF(.88, .8, toe=-22, yaw=46)},
                la=lambda p: aim(p, "L", 11, 4, twist=-60, elbow=4, wrist=-62),
                ra=lambda p: aim(p, "R", -11, 0, twist=-60, elbow=4, wrist=-62),
                head=lambda p: face(p, 0, elev=-4))


def hasangeki(arm):
    out = []
    ch = Shot(arm, N + "Hasangeki.Channel")
    ch.key(0, s(), "ease")
    last = seal(ch, 2)
    # the circle: both arms sweep out and up, the chest opening, the lead
    # foot sliding out a little further
    wide = pose({"root": {"y": -.8, "z": .04, "pitch": 0, "yaw": 40}, "torso": {"pitch": -4, "yaw": -12},
                 "lf": LF(-.64, -1.0, y=.14, yaw=28)},
                la=lambda p: aim(p, "L", -70, 34, twist=-40, elbow=16, wrist=-30),
                ra=lambda p: aim(p, "R", 70, 44, twist=-40, elbow=16, wrist=-30),
                head=lambda p: face(p, 0, elev=-2))
    ch.key(last + 4, wide, "pass")
    # ... over and down: the arms come round behind toward the right hip
    round_ = pose({"root": {"y": -.92, "z": .1, "pitch": 4, "yaw": 62}, "torso": {"pitch": 2, "yaw": -14},
                   "lf": LF(-.64, -1.1, yaw=30), "rf": RF(.88, .8, yaw=70)},
                  la=lambda p: aim(p, "L", 10, 30, twist=-40, elbow=40, wrist=-40),
                  ra=lambda p: aim(p, "R", 120, 10, twist=-40, elbow=40, wrist=-40),
                  head=lambda p: face(p, 0, elev=-4))
    ch.key(last + 8, round_, "pass")
    load = _load()
    ch.key(last + 13, load, "ease")
    # gathering: a breath lower
    ch.key(last + 17, merge(load, {"root": {"y": -1.04, "z": .16}}), "ease")
    ch.drag(["neck"], 1)
    ch.drag(["hand.L", "hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 17) / 60}))

    # The act (Active .08: frame 5, Recovery .32): the palms driven out by
    # frame 3, still pushing on the Active frame, held while the wave goes,
    # then back into the guard.
    gathered = merge(load, {"root": {"y": -1.04, "z": .16}})
    th = _thrust()
    held = merge(th, {"root": {"z": -.66, "y": -1.0}, "la": {"elbow": 6}, "ra": {"elbow": 6}})
    # the palms come down and back into the guard, the lead foot slides back
    back = pose({"travel": {"z": 0}, "root": {"y": -.8, "z": -.06, "pitch": 8, "yaw": 40}, "torso": {"pitch": 4, "yaw": -22},
                 "la": {"raise": 64, "out": 6, "twist": -40, "elbow": 30, "wrist": -30},
                 "ra": {"raise": 84, "out": -6, "twist": -40, "elbow": 100, "wrist": -30},
                 "lf": LF(-.64, -.92, y=.12, yaw=26), "rf": RF(.88, .8, yaw=60)},
                head=lambda p: face(p, 0, elev=-4))
    keys = [(0, gathered, "launch"), (3, th, "impact"), (5, merge(th, {"root": {"z": -.68, "y": -1.02}}), "ease"),
            (11, held, "ease"), (17, merge(held, {"root": {"z": -.62}}), "ease"), (24, back, "pass"), (30, s(), "ease")]
    out += act(arm, N + "Hasangeki", keys, .08, marker=3,
               drags=[(["hand.L", "hand.R"], 1), (["neck"], 1)])
    return out


# ========================================================== gentle counter
def _reading():
    """The reading guard: the weight sunk back onto the rear foot, the lead
    foot drawn in, both palms open in front on the centre line, the lead one
    high before the chin, the rear one crossing under it (they turn a blow
    aside, they do not take it)."""
    p = pose({"root": {"y": -.9, "z": .16, "pitch": 2, "yaw": 44}, "torso": {"pitch": 0, "yaw": -18},
              "lf": LF(-.5, -.5, yaw=22, toe=-8), "rf": RF(.88, .8, yaw=64)},
             head=lambda p: face(p, 0, elev=0))
    p["la"] = reach(p, "L", shoulder_at(p, "L") + chest_rot(p) @ Vector((.75, -.1, -1.55)),
                    start={"raise": 80, "out": -10, "twist": -74, "elbow": 60}, wrist=-52)
    p["ra"] = reach(p, "R", shoulder_at(p, "R") + chest_rot(p) @ Vector((-1.15, -.75, -1.25)),
                    start={"raise": 60, "out": -30, "twist": -66, "elbow": 86}, wrist=-48)
    return p


def gentle_counter(arm):
    out = []
    ch = Shot(arm, N + "GentleCounter.Channel")
    ch.key(0, s(), "ease")
    # (.04 s) a snapped rat, the head level: the Byakugan opens
    seal(ch, 4)
    snap = pose(merge({"root": {"y": -.72}}, nd_seals.seal(4)), head=lambda p: face(p, 0, elev=-2))
    out.append(ch.build(markers={"release": 3 / 60}))

    # The act (Active .04: frame 2, Recovery .20): the lead foot draws its
    # half circle in (just off the floor), the weight goes back, the palms
    # open out of the seal into the reading guard, held, still.
    mid = pose({"root": {"y": -.82, "z": .08, "pitch": 4, "yaw": 46}, "torso": {"pitch": 2, "yaw": -20},
                "lf": LF(-.78, -.66, y=.2, toe=-6, yaw=24)},
               la=lambda p: aim(p, "L", -12, 10, twist=-60, elbow=70, wrist=-40),
               ra=lambda p: aim(p, "R", -24, 0, twist=-60, elbow=96, wrist=-40),
               head=lambda p: face(p, 0, elev=0))
    rd = _reading()
    held = merge(rd, {"root": {"y": -.92}})
    keys = [(0, snap, "ease"), (2, mid, "pass"), (5, rd, "impact"), (7, held, "ease"),
            (12, merge(held, {"root": {"y": -.9}, "la": {"twist": -66, "wrist": -46}}), "ease"),
            (17, s({"root": {"y": -.72, "z": .04}}), "ease")]
    out += act(arm, N + "GentleCounter", keys, .04, marker=2,
               drags=[(["hand.L", "hand.R"], 1), (["neck"], 1)])
    return out


# =========================================================== trigram field
def _gather():
    """The arms up and open above, palms up, the body risen a little out of
    the wide stance: the field is gathered."""
    return pose({"root": {"y": -.66, "z": .06, "pitch": -2, "yaw": 24}, "torso": {"pitch": -4, "yaw": -12},
                 "lf": LF(-1.45, -.2, yaw=10)},
                la=lambda p: aim(p, "L", -40, 62, twist=40, elbow=20, wrist=-20),
                ra=lambda p: aim(p, "R", 40, 62, twist=40, elbow=20, wrist=-20),
                head=lambda p: face(p, 0, elev=0))


def _press():
    """Both palms pressed down and out beside the hips, the wide stance
    dropped deep, the back upright, the head level (it sees all round)."""
    return pose({"root": {"y": -1.22, "z": .1, "pitch": 4, "yaw": 22}, "torso": {"pitch": 2, "yaw": -10},
                 "lf": LF(-1.45, -.2, yaw=6), "rf": RF(.88, .8, yaw=50)},
                la=lambda p: aim(p, "L", -66, -34, twist=-20, elbow=26, wrist=-80),
                ra=lambda p: aim(p, "R", 66, -34, twist=-20, elbow=26, wrist=-80),
                head=lambda p: face(p, 0, elev=0))


def trigram_field(arm):
    out = []
    ch = Shot(arm, N + "TrigramField.Channel")
    ch.key(0, s(), "ease")
    last = seal(ch, 1)
    # the lead foot sweeps round on the floor (just above it), drawing the
    # circle out to his left, the lead palm following it, the rear one up
    sweep = pose({"root": {"y": -.86, "z": 0, "pitch": 4, "yaw": 36}, "torso": {"pitch": 2, "yaw": -16},
                  "lf": LF(-1.2, -.75, y=.13, toe=-6, yaw=14)},
                 la=lambda p: aim(p, "L", -60, -10, twist=-40, elbow=20, wrist=-30),
                 ra=lambda p: aim(p, "R", 20, 30, twist=-40, elbow=70, wrist=-30),
                 head=lambda p: face(p, 0, elev=-6))
    ch.key(last + 6, sweep, "pass")
    plant = pose({"root": {"y": -.9, "z": .06, "pitch": 2, "yaw": 26}, "torso": {"pitch": 0, "yaw": -12},
                  "lf": LF(-1.45, -.2, yaw=10)},
                 la=lambda p: aim(p, "L", -80, 30, twist=0, elbow=20, wrist=-20),
                 ra=lambda p: aim(p, "R", 60, 44, twist=0, elbow=30, wrist=-20),
                 head=lambda p: face(p, 0, elev=0))
    ch.key(last + 11, plant, "pass")
    g = _gather()
    ch.key(last + 17, g, "ease")
    ch.drag(["neck"], 1)
    ch.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 17) / 60}))

    # The act (Active .12: frame 7, Recovery .26): the press lands at 4 and
    # holds through the Active frame; he rises, the lead foot sliding back
    # round to the front.
    pr = _press()
    rise = pose({"root": {"y": -.84, "z": .04, "pitch": 4, "yaw": 38}, "torso": {"pitch": 2, "yaw": -20},
                 "la": {"raise": 50, "out": 20, "twist": -40, "elbow": 30, "wrist": -30},
                 "ra": {"raise": 80, "out": 0, "twist": -40, "elbow": 100, "wrist": -30},
                 "lf": LF(-1.1, -.6, y=.13, toe=-4, yaw=18)},
                head=lambda p: face(p, 0, elev=-4))
    keys = [(0, g, "launch"), (4, pr, "impact"), (7, merge(pr, {"root": {"y": -1.25}}), "ease"),
            (13, merge(pr, {"root": {"y": -1.24}}), "ease"), (20, rise, "pass"), (28, s(), "ease")]
    out += act(arm, N + "TrigramField", keys, .12, marker=4,
               drags=[(["hand.L", "hand.R"], 1), (["neck"], 1)])
    return out


# ================================================================ light 4
def light4(arm):
    """Body, the string's third hit (L1 lead fingers, L2 rear fingers, L4,
    L3 lead palm): .09 / .12 / .28 (x.92): contact 5, recover 12, end 29. A
    half step out to the left, the lead palm rolls over his guard and turns
    it aside while the rear palm, dropped from the ear to the hip, drives its
    heel in under it into the floating ribs; the hips turn in behind it."""
    sh = Shot(arm, N + "Light4")
    T = -.45
    sh.key(0, s(), "ease")
    roll = pose({"travel": {"z": T * .4}, "root": {"y": -.76, "z": 0, "pitch": 8, "yaw": 52}, "torso": {"pitch": 6, "yaw": -24},
                 "ra": {"raise": 16, "out": 12, "twist": -50, "elbow": 104, "wrist": -50},
                 "lf": LF(-.84, -1.0, y=.1, toe=6, yaw=22)},
                la=lambda p: aim(p, "L", -16, 14, twist=-80, elbow=34, wrist=-40),
                head=lambda p: face(p, 0, elev=-6))
    sh.key(3, roll, "pass")
    hit = pose({"travel": {"z": T}, "root": {"y": -.82, "z": -.26, "pitch": 10, "yaw": 24}, "torso": {"pitch": 6, "yaw": -24},
                "lf": LF(-.96, -1.4, yaw=18), "rf": RF(.88, .8, toe=-18, yaw=48)},
               la=lambda p: aim(p, "L", -36, 14, twist=-74, elbow=22, wrist=-40),
               ra=lambda p: aim(p, "R", -2, -8, twist=-50, elbow=4, wrist=-56),
               head=lambda p: face(p, 0, elev=-6))
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.3}}), "ease")
    # the rear palm comes back up by the ear, the lead palm forward low
    sh.key(16, pose({"travel": {"z": T}, "root": {"y": -.72, "z": -.6, "pitch": 8, "yaw": 42}, "torso": {"pitch": 4, "yaw": -24},
                     "la": {"raise": 66, "out": 6, "twist": -40, "elbow": 24, "wrist": -30},
                     "ra": {"raise": 90, "out": -8, "twist": -40, "elbow": 108, "wrist": -30},
                     "lf": LF(-.96, -1.4, yaw=22), "rf": RF(.88, .6, y=.1, toe=-10, yaw=58)},
                    head=lambda p: face(p, 0, elev=-6)), "pass")
    sh.key(29, at(T, {"lf": LF(-.96, -1.4, yaw=26), "rf": RF(.88, .35, yaw=64)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 12 / 60})


def author(arm):
    ch, look = leg_points_channel(arm)
    acts = [ch, low_palm(arm, look)]
    acts += hasangeki(arm)
    acts += gentle_counter(arm)
    acts += trigram_field(arm)
    acts.append(light4(arm))
    return acts
