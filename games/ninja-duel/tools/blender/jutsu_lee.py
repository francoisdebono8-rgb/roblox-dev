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
  Nunchaku             (strike) the weapon whirled in a full circle up behind
                       and over the shoulder, then the overhand blow at full
                       reach on a lunge; it carries on down across the body
                       and up the other side onto the left shoulder (Bruce
                       Lee's catch), then back behind the back into the belt
  GorikiSenpu.Channel  the coil: the hips wind the wrong way, low, the fists
                       closed, the head left on the opponent
  GorikiSenpu          (strike) three spinning kicks, rising, in one turn of
                       the body: a low right roundhouse, the left heel spun
                       through at the ribs, then the right leg thrown up from
                       a jump under the chin (the contact that launches)
  DancingLeafShadow.*  a crouch; then he is in the air right under and behind
                       the body: stretched from the leap, folding small, the
                       eyes up; held there, the right hand pulls the bandage
                       off the left forearm (the lotus is coming)
  DrunkenFist.*        a long swig from the gourd, a hiccup that jolts the
                       whole body, the knees going, and the loose sway taking
                       over before he finds his stance again
  Light4               (string, body) the lead hand closes: a skip-in and a
                       straight punch to the body, the rear hand never leaves
                       the back
  Light5               (string, head) the rear hand comes out from behind the
                       back for once: the hips square and drive a straight to
                       the face, then it folds back behind him

Server timings (Shared/SealJutsu, Shared/Attacks):
  Nunchaku     channel .10  strike .14 / .20 / .32
  GorikiSenpu  channel .12  strike .16 / .26 / .36
  DancingLeafShadow  channel .04 act .04 rec .10
  DrunkenFist        channel .24 act .05 rec .20
  Light4 .09 / .12 / .28      Light5 .10 / .12 / .27
"""
import math
from nd_shot import Shot, merge
from lee_p8 import STANCE, BACK, AIR, s, at, air

N = "Leaf."


# --------------------------------------------------------------- helpers
def _foot(x, z, kw):
    # (a foot dict is merged key by key onto the previous one: a planted
    # foot must say y/toe/knee or it keeps the kick's)
    out = {"y": 0, "toe": 0, "knee": 0}
    out.update(kw)
    out["x"], out["z"] = x, z
    return out


def RF(X, Z, **kw):
    """Right foot at WORLD (X, Z) (Roblox: x right, z back)."""
    return _foot(X - .5, Z, kw)


def LF(X, Z, **kw):
    """Left foot at WORLD (X, Z)."""
    return _foot(X + .5, Z, kw)


def turn(vx, vz, deg):
    """A floor vector (x right, z back) turned `deg` to the right (yaw +)."""
    a = math.radians(deg)
    return vx * math.cos(a) - vz * math.sin(a), vx * math.sin(a) + vz * math.cos(a)


# The open lead hand and the fist (the Strong Fist's two hands).
FIST_L = {"raise": 88, "out": -6, "twist": 0, "elbow": 2, "wrist": 0}


# ============================================================== nunchaku
def nunchaku_channel(arm):
    sh = Shot(arm, N + "Nunchaku.Channel")
    sh.key(0, s(), "ease")
    # The hand behind the back slides along the belt to the hip and closes
    # on the sticks; the shoulders turn a little to free the arm.
    grip = s({"root": {"y": -.56, "yaw": 46}, "torso": {"yaw": -12, "pitch": 6}, "head": {"yaw": -34},
              "ra": {"raise": -34, "out": 16, "twist": 74, "elbow": 46, "wrist": 24}})
    sh.key(3, grip, "pass")
    # Drawn: pulled out and down past the hip, the arm swinging back long
    # (the sticks hang from the hand behind him); the lead hand stays out.
    drawn = s({"root": {"y": -.6, "z": .02, "pitch": 10, "yaw": 42}, "torso": {"yaw": -10, "pitch": 6}, "head": {"yaw": -32, "pitch": -8},
               "ra": {"raise": -58, "out": 24, "twist": 30, "elbow": 22, "wrist": -6},
               "la": {"raise": 82, "out": 2, "elbow": 24, "wrist": -24}})
    sh.key(8, drawn, "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 1)
    return sh.build(markers={"release": 8 / 60}), drawn


def nunchaku(arm, drawn):
    """The strike (.14 / .20 / .32: contact 9, recover 21, end 40)."""
    sh = Shot(arm, N + "Nunchaku")
    T = -.6
    sh.key(0, drawn, "ease")
    # The whirl: the arm circles up behind him, the weight going back onto
    # the rear foot, the hips coiling, the lead hand aiming at the target.
    up = merge(drawn, {"root": {"y": -.64, "z": .12, "pitch": 4, "yaw": 58}, "torso": {"yaw": -22, "pitch": 0}, "head": {"yaw": -36, "pitch": -6},
                       "ra": {"raise": -128, "out": 22, "twist": 20, "elbow": 26, "wrist": 0},
                       "la": {"raise": 92, "out": -2, "twist": -10, "elbow": 8, "wrist": -10}})
    sh.key(3, up, "pass")
    # Over the top: the weapon above and behind the head, the chest arched,
    # the lead foot already lifting to step.
    over = merge(up, {"travel": {"z": T * .3}, "root": {"y": -.5, "z": .02, "pitch": -2, "yaw": 50}, "torso": {"pitch": -10, "yaw": -18},
                      "head": {"pitch": -2, "yaw": -32},
                      "ra": {"raise": -186, "out": 26, "twist": 10, "elbow": 58, "wrist": 10},
                      "lf": LF(-.6, -.95, y=.22, toe=12), "rf": RF(.82, .7, toe=-8, yaw=58)})
    sh.key(6, over, "pass")
    # The blow: overhand at full reach, the lunge carrying the hips through,
    # the right shoulder driving forward (hips square), the lead hand pulled
    # in to the chest as the counterweight.
    hit = s({"travel": {"z": T}, "root": {"y": -.66, "z": -.32, "pitch": 18, "yaw": 6}, "torso": {"pitch": 8, "yaw": -22, "roll": 4},
             "head": {"pitch": -14, "yaw": 16},
             "ra": {"raise": -262, "out": 6, "twist": 0, "elbow": 2, "wrist": -14},
             "la": {"raise": 44, "out": 26, "twist": -24, "elbow": 112, "wrist": 0},
             "lf": LF(-.62, -1.4, yaw=8), "rf": RF(.82, .7, toe=-26, yaw=40)})
    sh.key(9, hit, "impact")
    # It carries on: down and across the body to the left hip ...
    through = merge(hit, {"root": {"y": -.7, "z": -.36, "pitch": 22, "yaw": -2}, "torso": {"yaw": -30, "pitch": 12, "roll": 2},
                          "head": {"yaw": 30},
                          "ra": {"raise": -330, "out": -30, "twist": 14, "elbow": 12, "wrist": 0},
                          "la": {"raise": 30, "out": 40, "elbow": 96}})
    sh.key(13, through, "pass")
    # ... and up the left side onto the shoulder: the catch (the arm across
    # the chest, the hand by the left ear, the sticks over the shoulder).
    catch = merge(through, {"root": {"y": -.56, "z": -.24, "pitch": 12, "yaw": 18}, "torso": {"yaw": -12, "pitch": 4, "roll": 0},
                            "head": {"yaw": -6, "pitch": -8},
                            "ra": {"raise": -220, "out": -56, "twist": -24, "elbow": 138, "wrist": 10},
                            "la": {"raise": 62, "out": -6, "twist": -10, "elbow": 96, "wrist": -10}})
    sh.key(18, catch, "ease")
    sh.key(21, merge(catch, {"root": {"y": -.58}, "ra": {"elbow": 142}}), "ease")
    # Back into the stance: the hand brings the sticks down the right side
    # and behind the back (the belt), the rear foot steps up, the hips turn
    # side-on again.
    down = s({"travel": {"z": T}, "root": {"y": -.58, "z": -.18, "pitch": 12, "yaw": 30}, "torso": {"yaw": -8, "pitch": 6},
              "head": {"yaw": -24, "pitch": -8},
              "ra": {"raise": 46, "out": 14, "twist": 20, "elbow": 84, "wrist": 0},
              "la": {"raise": 66, "out": 4, "twist": -10, "elbow": 40, "wrist": -10},
              "lf": LF(-.62, -1.4, yaw=10), "rf": RF(.82, .7, toe=-14, yaw=48)})
    sh.key(26, down, "pass")
    stow = s({"travel": {"z": T}, "root": {"y": -.56, "z": -.12, "yaw": 40}, "torso": {"yaw": -14},
              "head": {"yaw": -26},
              "ra": {"raise": -34, "out": 16, "twist": 76, "elbow": 60, "wrist": 10},
              "la": {"raise": 74, "out": 4, "twist": -10, "elbow": 28, "wrist": -14},
              "lf": LF(-.62, -1.4, yaw=14), "rf": RF(.8, .36, y=.2, toe=-10, yaw=54)})
    sh.key(32, stow, "pass")
    sh.key(40, at(T, {"lf": LF(-.62, -1.4, yaw=20), "rf": RF(.82, .1, yaw=58)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    sh.drag(["hand.R"], 1)
    return sh.build(markers={"contact": 9 / 60, "recover": 21 / 60})


# ========================================================== goriki senpu
COIL = s({"root": {"y": -.84, "z": .06, "pitch": 12, "yaw": 76}, "torso": {"pitch": 8, "yaw": 6}, "head": {"pitch": -10, "yaw": -78},
          "la": {"raise": 62, "out": -38, "twist": 20, "elbow": 84, "wrist": 0},
          "ra": {"raise": 6, "out": 50, "twist": 30, "elbow": 34, "wrist": 0},
          "rf": RF(.82, .7, toe=-6, yaw=62), "lf": LF(-.6, -.7, yaw=42)})


def goriki_channel(arm):
    sh = Shot(arm, N + "GorikiSenpu.Channel")
    sh.key(0, s(), "ease")
    # The fists close and the hips wind the wrong way: the lead arm folds
    # across the chest, the rear arm swings out of the back, he sinks.
    sh.key(4, s({"root": {"y": -.7, "yaw": 64, "pitch": 10}, "torso": {"yaw": -6, "pitch": 6}, "head": {"yaw": -58},
                 "la": {"raise": 70, "out": -20, "twist": 10, "elbow": 60, "wrist": 0},
                 "ra": {"raise": -20, "out": 34, "twist": 60, "elbow": 50}}), "pass")
    sh.key(8, COIL, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"release": 8 / 60})


def goriki_senpu(arm):
    """Three kicks in one left turn of the body: 48 -> -30 (low right
    roundhouse) -> -250 (the left leg spun out sideways at the ribs) -> -384
    (the jumping right kick up under the chin, the contact) -> back to the
    stance. Authored with contact 18 / recover 34 / end 56 (server .16 / .26
    / .36: the startup plays ~1.8x). Between the kicks the arms fold in (the
    spin speeds up), at each kick they open (it brakes); the head leaves the
    opponent last and finds him first."""
    sh = Shot(arm, N + "GorikiSenpu")
    sh.key(0, COIL, "ease")
    tuck = {"la": {"raise": 70, "out": -30, "twist": 10, "elbow": 104, "wrist": 0},
            "ra": {"raise": 60, "out": -26, "twist": 10, "elbow": 112, "wrist": 0}}
    # unwinding: the right knee comes up from behind, the hips over the lead
    # foot, which pivots on its ball
    sh.key(3, merge(COIL, merge(tuck, {"travel": {"z": -.15}, "root": {"x": -.35, "y": -.62, "z": -.35, "pitch": 4, "roll": -4, "yaw": 20},
                                       "torso": {"pitch": 2, "yaw": -6, "roll": 0}, "head": {"pitch": -6, "yaw": -14},
                                       "rf": RF(.55, 0, y=.75, toe=-30, yaw=0, knee=10), "lf": LF(-.6, -.7, yaw=10, toe=-8)})), "pass")
    # k1: the low roundhouse (knee height), the body leaning off it, the
    # arms flung open
    k1 = merge(COIL, {"travel": {"z": -.3}, "root": {"x": -.42, "y": -.6, "z": -.32, "pitch": -6, "roll": -12, "yaw": -30},
                      "torso": {"pitch": -2, "yaw": 6, "roll": -4}, "head": {"pitch": -10, "yaw": 24},
                      "la": {"raise": 40, "out": 72, "twist": 0, "elbow": 20, "wrist": 0},
                      "ra": {"raise": 56, "out": 40, "twist": 0, "elbow": 50, "wrist": 0},
                      "rf": RF(-.2, -1.95, y=.6, toe=20, yaw=-90), "lf": LF(-.6, -.7, yaw=-30, toe=-12)})
    sh.key(5, k1, "impact")
    # through: the leg sweeps past and comes down crossing in front of the
    # left foot, the back turns to him, the arms fold, the head whips round
    sh.key(8, merge(k1, merge(tuck, {"travel": {"z": -.45}, "root": {"x": -.6, "y": -.52, "z": -.5, "pitch": 4, "roll": 0, "yaw": -140},
                                     "torso": {"pitch": 4, "yaw": -20, "roll": 0}, "head": {"pitch": -8, "yaw": -70},
                                     "rf": RF(-.95, -1.5, y=.16, yaw=-150), "lf": LF(-.6, -.7, y=.05, toe=-30, yaw=-110)})), "pass")
    sh.key(9, merge(k1, merge(tuck, {"travel": {"z": -.5}, "root": {"x": -.7, "y": -.5, "z": -.55, "pitch": 4, "roll": 4, "yaw": -170},
                                     "torso": {"pitch": 2, "yaw": -20, "roll": 2}, "head": {"pitch": -8, "yaw": -76},
                                     "rf": RF(-.95, -1.5, yaw=-170), "lf": LF(-.6, -1.0, y=.45, toe=-20, yaw=-160, knee=10)})), "pass")
    # k2: the left leg spun out sideways at the ribs, pivoting on the right
    # foot, the body leaning right off it, the left arm along the leg
    k2 = merge(k1, {"travel": {"z": -.7}, "root": {"x": -.85, "y": -.42, "z": -.55, "pitch": -4, "roll": 26, "yaw": -250},
                    "torso": {"pitch": 0, "yaw": -20, "roll": 8}, "head": {"pitch": -6, "yaw": -80, "roll": -14},
                    "la": {"raise": 30, "out": 64, "twist": 0, "elbow": 10, "wrist": 0},
                    "ra": {"raise": 84, "out": 26, "twist": 10, "elbow": 118, "wrist": 0},
                    "rf": RF(-.95, -1.5, yaw=-230, toe=-12), "lf": LF(-.5, -3.5, y=2.0, toe=10, yaw=-250)})
    sh.key(11, k2, "impact")
    # the heel folds back and comes down in front: the take-off foot; the
    # arms swing down for the jump, the right heel already up
    sh.key(14, merge(k2, {"travel": {"z": -1.0}, "root": {"x": -.55, "y": -.66, "z": -.8, "pitch": 10, "roll": 0, "yaw": -300},
                          "torso": {"pitch": 8, "yaw": -10, "roll": 0}, "head": {"pitch": -12, "yaw": -40, "roll": 0},
                          "la": {"raise": -24, "out": 40, "elbow": 40}, "ra": {"raise": -24, "out": 40, "elbow": 40},
                          "rf": RF(-.95, -1.5, toe=-34, yaw=-260), "lf": LF(-.65, -2.0, yaw=-300)}), "pass")
    # take-off: the right leg swinging through, the arms sweeping up
    sh.key(16, merge(k2, {"travel": {"z": -1.1}, "root": {"x": -.45, "y": -.36, "z": -.7, "pitch": 0, "roll": -2, "yaw": -340},
                          "torso": {"pitch": 0, "yaw": -4, "roll": 0}, "head": {"pitch": -16, "yaw": -10, "roll": 0},
                          "la": {"raise": 70, "out": 50, "elbow": 40}, "ra": {"raise": 40, "out": 50, "elbow": 40},
                          "rf": RF(-.4, -1.7, y=1.0, toe=-10, yaw=-340, knee=10), "lf": LF(-.65, -2.0, toe=-40, yaw=-330)}), "pass")
    # k3, the contact: off the floor, the right leg thrown up under the chin,
    # the chest falling back behind it, the left arm flung up with it
    k3 = merge(k2, {"travel": {"z": -1.2}, "root": {"x": -.4, "y": .15, "z": -.6, "pitch": -26, "roll": -6, "yaw": -384},
                    "torso": {"pitch": -16, "yaw": 0, "roll": -4}, "head": {"pitch": -30, "yaw": 24, "roll": 0},
                    "la": {"raise": 130, "out": 50, "twist": 0, "elbow": 24, "wrist": 0},
                    "ra": {"raise": 10, "out": 70, "twist": 0, "elbow": 30, "wrist": 0},
                    "rf": RF(-.25, -3.0, y=3.45, toe=24, yaw=-400), "lf": LF(-.6, -1.8, y=1.0, toe=-30, yaw=-380, knee=10)})
    sh.key(18, k3, "impact")
    # it follows through upward: the apex
    apex = merge(k3, {"root": {"y": .28, "pitch": -30}, "head": {"pitch": -34},
                      "la": {"raise": 146}, "rf": RF(-.25, -2.85, y=3.7, toe=24, yaw=-400), "lf": LF(-.6, -1.75, y=1.15, toe=-30, yaw=-380, knee=10)})
    sh.key(23, apex, "ease")
    # coming down: the kicking leg folds, the left foot reaches for the floor
    sh.key(29, merge(apex, {"root": {"y": -.12, "pitch": -2, "roll": 0, "yaw": -360}, "torso": {"pitch": 0, "yaw": -6, "roll": 0}, "head": {"pitch": -12, "yaw": 10},
                            "la": {"raise": 70, "out": 50, "elbow": 40}, "ra": {"raise": 40, "out": 60, "elbow": 40},
                            "rf": RF(-.1, -1.9, y=1.2, toe=-10, yaw=-330, knee=10), "lf": LF(-.6, -1.8, y=.3, toe=10, yaw=-345)}), "pass")
    # the landing: on the left foot, absorbed deep, the right foot down
    # behind (the stance comes back)
    land = s({"travel": {"z": -1.2}, "root": {"y": -.92, "z": -.12, "pitch": 16, "yaw": 40}, "torso": {"pitch": 10, "yaw": -10}, "head": {"pitch": -14, "yaw": -30},
              "la": {"raise": 60, "out": 30, "elbow": 40, "wrist": -10}, "ra": {"raise": -20, "out": 40, "twist": 40, "elbow": 60},
              "lf": LF(-.6, -1.8, yaw=30), "rf": RF(.62, -.7, y=.35, toe=-20, yaw=50)})
    sh.key(34, land, "impact")
    sh.key(42, merge(land, {"root": {"y": -.66, "z": -.06, "pitch": 10}, "ra": BACK, "rf": RF(.82, -.5, yaw=58)}), "ease")
    sh.key(56, at(-1.2, {"lf": LF(-.6, -1.8, yaw=20), "rf": RF(.82, -.5, yaw=58)}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    return sh.build(markers={"contact": 18 / 60, "recover": 34 / 60})


# ==================================================== dancing leaf shadow
CROUCH = s({"root": {"y": -1.08, "z": .1, "pitch": 26, "yaw": 30}, "torso": {"pitch": 14, "yaw": -8}, "head": {"pitch": -34, "yaw": -20},
            "la": {"raise": -40, "out": 26, "twist": 0, "elbow": 20, "wrist": 0}, "ra": {"raise": -50, "out": 26, "twist": 20, "elbow": 20, "wrist": 0},
            "rf": RF(.82, .7, toe=-24, yaw=50), "lf": LF(-.6, -.7, toe=-18, yaw=20)})
# In the air under the body: small, folded, the eyes up at it, the hands
# open and ready.
SHADOW = air({"root": {"y": -.36, "pitch": 22, "roll": 0, "yaw": 0}, "torso": {"pitch": 6, "yaw": 0}, "head": {"pitch": -40, "yaw": 0},
              "la": {"raise": 120, "out": 18, "twist": -20, "elbow": 40, "wrist": -10},
              "ra": {"raise": 96, "out": -16, "twist": 30, "elbow": 96, "wrist": 0},
              "rf": {"x": .05, "z": -.3, "y": 1.35, "toe": -30, "yaw": 0, "knee": 8}, "lf": {"x": -.05, "z": -.1, "y": 1.2, "toe": -30, "yaw": 0, "knee": 6}})


def dancing_leaf(arm):
    out = []
    ch = Shot(arm, N + "DancingLeafShadow.Channel")
    ch.key(0, s(), "ease")
    ch.key(4, CROUCH, "ease")
    out.append(ch.build(markers={"release": 4 / 60}))

    re = Shot(arm, N + "DancingLeafShadow.Release")
    # He is already up there (the body followed): stretched from the leap,
    # arms swept up past the head, legs long under him ...
    leap = air({"root": {"y": -.1, "pitch": -8, "yaw": 0}, "torso": {"pitch": -8}, "head": {"pitch": -30},
                "la": {"raise": 160, "out": 20, "elbow": 10}, "ra": {"raise": 150, "out": 24, "elbow": 14},
                "rf": {"x": .1, "z": .35, "y": .35, "toe": 40, "knee": 0}, "lf": {"x": -.05, "z": .2, "y": .3, "toe": 40, "knee": 0}})
    re.key(0, leap, "launch")
    # ... folding small under it: the knees come up, the arms come down in
    # front, the eyes stay on the body above
    re.key(4, merge(SHADOW, {"root": {"y": -.3, "pitch": 14}, "la": {"raise": 140, "elbow": 26}, "ra": {"raise": 120, "out": 0, "elbow": 70}}), "pass")
    re.key(9, SHADOW, "ease")
    re.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    re.drag(["neck"], 1)
    out.append(re.build(markers={"release": 1 / 60}))

    rc = Shot(arm, N + "DancingLeafShadow.Recover")
    rc.key(0, SHADOW, "ease")
    # Held there: the right hand pulls the bandage off the left forearm
    # along the arm, the left arm reaching up at the body.
    rc.key(6, merge(SHADOW, {"root": {"y": -.4, "pitch": 18}, "head": {"pitch": -38},
                             "la": {"raise": 128, "out": 22, "elbow": 30},
                             "ra": {"raise": 70, "out": 10, "twist": 30, "elbow": 110, "wrist": 10}}), "ease")
    rc.key(12, merge(SHADOW, {"root": {"y": -.44, "pitch": 16}, "head": {"pitch": -36},
                              "la": {"raise": 120, "out": 26, "elbow": 34},
                              "ra": {"raise": 40, "out": 30, "twist": 20, "elbow": 80, "wrist": 0}}), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


# =========================================================== drunken fist
SWIG = s({"root": {"y": -.36, "z": .04, "pitch": -6, "yaw": 34, "roll": -3}, "torso": {"pitch": -16, "yaw": -8}, "head": {"pitch": -44, "yaw": -18, "roll": -4},
          "ra": {"raise": 128, "out": 24, "twist": -34, "elbow": 146, "wrist": 30},
          "la": {"raise": -8, "out": 32, "twist": -40, "elbow": 96, "wrist": 0},
          "rf": RF(.82, .7, yaw=58), "lf": LF(-.6, -.7, yaw=20)})


def drunken_fist(arm):
    out = []
    ch = Shot(arm, N + "DrunkenFist.Channel")
    ch.key(0, s(), "ease")
    # the gourd comes up from behind the back, he straightens
    ch.key(5, s({"root": {"y": -.44, "pitch": 2, "yaw": 40}, "torso": {"pitch": -2, "yaw": -12}, "head": {"pitch": -12, "yaw": -24},
                 "ra": {"raise": 70, "out": 26, "twist": -10, "elbow": 110, "wrist": 10},
                 "la": {"raise": 30, "out": 26, "twist": -30, "elbow": 70, "wrist": 0}}), "pass")
    # the swig: head back, elbow high, the free hand on the hip
    ch.key(10, SWIG, "ease")
    # a long pull: the head goes further back, the hips sway under it
    ch.key(16, merge(SWIG, {"root": {"y": -.34, "roll": 2, "x": .04}, "head": {"pitch": -50, "roll": 2}, "ra": {"raise": 136, "elbow": 150}}), "ease")
    ch.drag(["neck"], 2)
    ch.drag(["shoulder.L", "forearm.L", "hand.L"], 2)
    out.append(ch.build(markers={"release": 16 / 60}))

    after = merge(SWIG, {"root": {"y": -.34, "roll": 2, "x": .04}, "head": {"pitch": -50, "roll": 2}, "ra": {"raise": 136, "elbow": 150}})
    re = Shot(arm, N + "DrunkenFist.Release")
    re.key(0, after, "ease")
    # the hiccup: the whole body jolts up, shoulders hunch, the head snaps
    # forward, the gourd hand drops
    hic = merge(after, {"root": {"y": -.22, "pitch": 6, "roll": 0, "x": 0}, "torso": {"pitch": 12, "yaw": -10}, "head": {"pitch": 18, "roll": -6},
                        "ra": {"raise": 80, "out": 30, "twist": -10, "elbow": 110, "wrist": 30},
                        "la": {"raise": 20, "out": 40, "twist": -30, "elbow": 80, "wrist": 30},
                        "rf": RF(.82, .7, yaw=58, toe=-14), "lf": LF(-.6, -.7, yaw=20, toe=-12)})
    re.key(3, hic, "impact")
    # and the knees go: he sinks loose to one side, everything hanging
    sag = s({"root": {"y": -.86, "x": -.12, "pitch": 14, "roll": -12, "yaw": 30}, "torso": {"pitch": 10, "roll": 8, "yaw": -6},
             "head": {"pitch": 10, "roll": 16, "yaw": -20},
             "la": {"raise": 28, "out": 30, "twist": -20, "elbow": 56, "wrist": 56},
             "ra": {"raise": 34, "out": 26, "twist": -10, "elbow": 74, "wrist": 60},
             "rf": RF(.82, .7, yaw=58), "lf": LF(-.6, -.7, yaw=20, knee=-10)})
    re.key(9, sag, "ease")
    re.drag(["neck"], 1)
    re.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(re.build(markers={"release": 3 / 60}))

    rc = Shot(arm, N + "DrunkenFist.Recover")
    rc.key(0, sag, "ease")
    # the sway takes over: the body rolls over to the other side, the
    # arms float up loose (the cupped hands of the drunken boxer), the head
    # lolling behind the body
    sway = s({"root": {"y": -.6, "x": .16, "pitch": 4, "roll": 10, "yaw": 54}, "torso": {"pitch": -2, "roll": -10, "yaw": -16},
              "head": {"pitch": -8, "roll": -14, "yaw": -30},
              "la": {"raise": 84, "out": 14, "twist": -40, "elbow": 70, "wrist": 50},
              "ra": {"raise": 110, "out": 20, "twist": -30, "elbow": 120, "wrist": 50},
              "rf": RF(.82, .7, yaw=58), "lf": LF(-.6, -.7, yaw=20, toe=-10)})
    rc.key(7, sway, "pass")
    rc.key(14, s({"root": {"roll": 3, "x": .04}}), "ease")
    rc.drag(["neck"], 2)
    rc.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(rc.build())
    return out


# ============================================================ lights
def light4(arm):
    """Body punch, the lead hand (.09 / .12 / .28: contact 5, recover 12,
    end 29). A skip-in, the Strong Fist's spring: both feet leave the floor,
    the rear foot lands first behind the front one, the front one lands with
    the fist; he drops under the guard as it lands."""
    sh = Shot(arm, N + "Light4")
    T = -.5
    sh.key(0, s(), "ease")
    # the hop: up off the floor, the rear foot drawn in under him, the hand
    # closing and drawn back a little
    sh.key(2, s({"travel": {"z": T * .4}, "root": {"y": -.48, "z": .0, "pitch": 8, "yaw": 54}, "torso": {"pitch": 4, "yaw": -22}, "head": {"pitch": -8, "yaw": -32},
                 "la": {"raise": 72, "out": 0, "twist": -4, "elbow": 62, "wrist": 0},
                 "rf": RF(.82, .45, y=.3, toe=-20, yaw=58), "lf": LF(-.6, -1.0, y=.16, toe=10, yaw=20)}), "launch")
    # the rear foot lands, the front one still in the air
    sh.key(3, s({"travel": {"z": T * .7}, "root": {"y": -.6, "z": -.08, "pitch": 10, "yaw": 56}, "torso": {"pitch": 6, "yaw": -24}, "head": {"pitch": -10, "yaw": -32},
                 "la": {"raise": 76, "out": -2, "twist": -2, "elbow": 40, "wrist": 0},
                 "rf": RF(.82, .25, toe=-14, yaw=58), "lf": LF(-.6, -1.2, y=.1, toe=6, yaw=20)}), "pass")
    hit = s({"travel": {"z": T}, "root": {"y": -.82, "z": -.26, "pitch": 12, "yaw": 60}, "torso": {"pitch": 6, "yaw": -26, "roll": -4},
             "head": {"pitch": -10, "yaw": -34},
             "la": {"raise": 90, "out": -6, "twist": 0, "elbow": 0, "wrist": 0},
             "rf": RF(.82, .25, toe=-20, yaw=58), "lf": LF(-.6, -1.3, yaw=20)})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.3, "y": -.84}, "la": {"raise": 92, "elbow": 2}}), "ease")
    # the hand snaps back open (the beckoning guard), he comes up springy
    sh.key(15, s({"travel": {"z": T}, "root": {"y": -.56, "z": -.1}, "la": {"raise": 76, "elbow": 36, "wrist": -10},
                  "rf": RF(.82, .25, yaw=58, toe=-6), "lf": LF(-.6, -1.3, yaw=20)}), "pass")
    sh.key(29, at(T, {"rf": RF(.82, .25, yaw=58), "lf": LF(-.6, -1.3, yaw=20)}), "ease")
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
    sh.key(3, s({"root": {"y": -.58, "z": .04, "pitch": 8, "yaw": 58}, "torso": {"yaw": -20}, "head": {"yaw": -36},
                 "ra": {"raise": -20, "out": 20, "twist": 40, "elbow": 110, "wrist": 0},
                 "rf": RF(.82, .7, toe=-10, yaw=58)}), "pass")
    hit = s({"travel": {"z": T}, "root": {"y": -.46, "z": -.26, "pitch": 10, "yaw": -4}, "torso": {"pitch": 4, "yaw": -6, "roll": 2},
             "head": {"pitch": -10, "yaw": 10},
             "ra": {"raise": 98, "out": -4, "twist": 0, "elbow": 0, "wrist": 0},
             "la": {"raise": 56, "out": 6, "twist": -20, "elbow": 118, "wrist": 0},
             "rf": RF(.82, .7, toe=-30, yaw=10), "lf": LF(-.6, -1.05, yaw=4)})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"root": {"z": -.29}, "ra": {"raise": 100}}), "ease")
    # the hips turn back side-on, the fist comes back round the hip to the
    # small of the back, the rear foot follows
    sh.key(17, s({"travel": {"z": T}, "root": {"y": -.52, "z": -.1, "yaw": 34}, "torso": {"yaw": -14}, "head": {"yaw": -24},
                  "ra": {"raise": 0, "out": 24, "twist": 60, "elbow": 80, "wrist": 0},
                  "la": {"raise": 70, "elbow": 40},
                  "rf": RF(.8, .5, y=.16, toe=-10, yaw=40), "lf": LF(-.6, -1.05, yaw=14)}), "pass")
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
