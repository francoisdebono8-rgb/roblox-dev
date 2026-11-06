"""Gaara (Sand), moveset pass v2 (06/11, user: « vérifie les poses de saut, les
impacts des gros coups, même les attaques que tu crois bonnes »).

In play he read as never moving at all: the commands of his hands were small
pokes in front of the chest, invisible from the duel camera (three-quarter
behind him, ~14 studs), and five slots still played generic captures (a
boxer's jab, a hadouken, a capoeira floor spin, a flying kick). The body
still barely moves - the feet stay where they are, the head stays on the
opponent, the gourd keeps him planted - but every command is now made with
the whole arm, out of the silhouette: it starts from the fold, travels on a
wide arc (out to the side, over the head, low across the floor) so it reads
from behind, lands on a held command (2-4 frames, the sand obeys) and folds
back slowly. The chest and the knees answer the arm a little (a turn of the
chest, a give of the knees under the heavy commands): the weight of what he
moves is felt, not his own. Authored on his body (gaara_p7.STANCE); each
clip keeps its length and its contact / recover markers (the server's).

  Light1      forehand lash: the right hand rises by the ear, the arm swings
              out wide to his right and whips in on a flat arc until it points
              at him, palm open; the wrist cracks, held, the arm folds back
  Light2      backhand lash: the left hand crosses to the right shoulder, then
              the arm sweeps flat across and out wide to his left, the back of
              the hand leading; the chest turns with it a little
  Light3      the wave: both hands drop low at his sides, palms forward, the
              knees give; then both arms swing up and drive forward and open,
              the chest leaning in - the wave throws him (impulse 56)
  Light4      the cross lash: the right hand comes up over the left shoulder,
              high, and cuts down on a long diagonal out to his right side,
              the knees giving on the cut
  SandHand    heavy: the left arm rises out of the fold straight up over his
              head, hand clawed, the chest opening, then the fist closes and
              is dragged down to his hip: the knees give, the chest bows, the
              hand of sand slams him into the floor and holds; slow return
  SandFist    launcher: the right fist set into the left palm at the chest,
              the chest coiled back to the right; then both arms drive
              straight out as the chest uncoils and the weight goes onto the
              front foot; held while the fist of sand carries him
  SandLowWave away route: both palms come up flat to his face, then push
              down and out low at the floor ahead, the knees bending, the
              chest bowing over them; held while the wave rolls
  SandPillar  launcher (up route): the right hand scoops low by the knee, palm
              up, the knees giving; then it rises fast past the face and on,
              straight overhead, the body lifting with it, the chin up: the
              pillar erupts under him
  Sweep       the right arm crosses high to his left, then sweeps down and
              out flat, low, to his right, palm down, the knees giving: the
              sand rolls along the floor (Gaara never kicks)
  DashAttack  arrival of the re-engage glide: leaning on the sand, the right
              hand cocked by the ear whips out at him, held, he straightens
  Air1/Air2   in the air (legs together, hanging): the right arm chops down
              from over the head (Air1); the left arm sweeps flat from across
              the chest out wide (Air2)
  Slam        air heavy: both arms rise over the head, the body arching back,
              knees drawn; then both hands are driven down to the floor ahead,
              the legs drop to land, the chest bowing - he lands into the
              crouch of the blow and rises
  SandGlide   side route: carried sideways on the sand, leaning into it, the
              right arm swung wide and whipped across at him
  Grab        the sand grips: the right arm shoots out, palm open, the fingers
              close on the contact and the fist is drawn back to the chest,
              holding him; then back to the fold
  ThrowUp     the fist dropped low to the hip, palm up, then flung straight up
              overhead, the fingers opening, the body lifting
  Guard.Impact  the blow hits the sand shield: the shoulders rock back over
              the heels, the knees take it, the folded arms pushed in; slow back
  Jump.Leap   (sampled along the arc of a running jump) stretched off the
              push-off foot, the lead knee driven up, then both knees drawn
              in, the legs reaching down for the floor; arms folded
  Jump.Air    (sampled along the arc) rising stretched, toes pointed; at the
              apex the knees come up together, compact; then the legs reach
              down; arms folded, the head level
  Land        touch-down on stretched legs, the knees bend deep, the chest
              over them, the folded arms loosen out a little for balance, held,
              then he rises back into the stance
  Flip        (the engine turns the body) arms folded, the knees pulled tight
              to the chest and the chin tucked through the turn, then the legs
              open and reach down for the landing

Server timings (Shared/Attacks + his AttackProfile): Light1-2 startup .162,
Light3 .228, Light4 .162, SandHand .24 / .16 / .48, SandFist .342 / .14,
SandLowWave .16 / .16 / .4, SandPillar .27 / .14 / .5, SandGlide .12 / .12,
Sweep .12, DashAttack .077, Air1 .088, Air2 .099, Slam .165, Grab, ThrowUp
.12 / .1 / .3 - every contact marker sits on them (unchanged lengths).
"""
import bpy
from nd_shot import merge
from jutsu_gaara import Take, BASE
from gaara_p7 import STANCE, FOLD_R, FOLD_L
import clips_react2

N = "Sand."
F = 60.0
Y0 = BASE["root"]["y"]
WANT = ("Sand.Air1", "Sand.Air2", "Sand.DashAttack", "Sand.Flip", "Sand.Grab", "Sand.Guard.Impact", "Sand.Jump.Air",
        "Sand.Jump.Leap", "Sand.Land", "Sand.Light1", "Sand.Light2", "Sand.Light3", "Sand.Light4", "Sand.SandFist",
        "Sand.SandGlide", "Sand.SandHand", "Sand.SandLowWave", "Sand.SandPillar", "Sand.Slam", "Sand.Sweep", "Sand.ThrowUp")


def s(over=None):
    """The stance (every channel set), with changes."""
    return merge(BASE, over or {})


def arm_(raise_, out, twist, elbow, wrist=0, wroll=0):
    return {"raise": raise_, "out": out, "twist": twist, "elbow": elbow, "wrist": wrist, "wroll": wroll}


def hold(sh, f0, pose, f1, delta):
    """A held command: the contact pose, then the same pose pushed a hair
    further (the sand still obeying) - a hit-stop that still lives."""
    sh.key(f0, pose, "impact")
    sh.key(f1, merge(pose, delta), "ease")


def done(sh, contact, recover):
    return sh.build(markers={"contact": contact / F, "recover": recover / F})


# ================================================================== strings
def light1(arm):
    """30 f, contact 10, recover 16."""
    sh = Take(arm, N + "Light1")
    sh.key(0, s(), "ease")
    # the hand rises out of the fold by the ear, the elbow up and out
    sh.key(4, s({"torso": {"yaw": 8, "roll": -2}, "head": {"yaw": -10},
                 "ra": arm_(118, 40, -20, 112, 20)}), "ease")
    # the arm swings out wide to his right, unfolding ...
    sh.key(7, s({"torso": {"yaw": 6}, "head": {"yaw": -8},
                 "ra": arm_(100, 70, -20, 40, 10)}), "pass")
    # ... and whips in flat until it points at him, palm open
    hit = s({"root": {"y": Y0 - .04}, "torso": {"yaw": -6, "roll": 1, "pitch": 2}, "head": {"yaw": 2},
             "ra": arm_(90, 6, -10, 2, -18)})
    hold(sh, 10, hit, 14, {"ra": {"out": 0, "wrist": -30}, "torso": {"yaw": -8}})
    sh.key(21, s({"ra": arm_(80, -10, 20, 60, 0), "torso": {"yaw": -3}}), "pass")
    sh.key(30, s(), "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 10, 16)


def light2(arm):
    """32 f, contact 11, recover 17."""
    sh = Take(arm, N + "Light2")
    sh.key(0, s(), "ease")
    # the left hand crosses high to his right shoulder, the chest turning in
    sh.key(5, s({"torso": {"yaw": 10, "roll": 2}, "head": {"yaw": -12},
                 "la": arm_(104, -64, 30, 118, 30)}), "ease")
    sh.key(8, s({"torso": {"yaw": 2}, "head": {"yaw": -6},
                 "la": arm_(96, -20, 10, 50, 10)}), "pass")
    # the sweep ends out wide to his left, the back of the hand leading
    hit = s({"root": {"y": Y0 - .04}, "torso": {"yaw": -12, "roll": -2}, "head": {"yaw": 4},
             "la": arm_(92, 58, -20, 4, -26)})
    hold(sh, 11, hit, 15, {"la": {"out": 64, "wrist": -36}, "torso": {"yaw": -14}})
    sh.key(23, s({"la": arm_(72, 0, 30, 70, 0), "torso": {"yaw": -4}}), "pass")
    sh.key(32, s(), "ease")
    sh.drag(["hand.L"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 11, 17)


def light3(arm):
    """34 f, contact 14, recover 20."""
    sh = Take(arm, N + "Light3")
    sh.key(0, s(), "ease")
    # both hands drop low at his sides, palms forward, the knees give
    low = s({"root": {"y": Y0 - .12, "z": .04}, "torso": {"pitch": -3}, "head": {"pitch": 8},
             "ra": arm_(-6, 34, -30, 24, -30), "la": arm_(-6, 34, -30, 24, -30)})
    sh.key(7, low, "ease")
    sh.key(11, s({"root": {"y": Y0 - .08}, "torso": {"pitch": 2},
                  "ra": arm_(52, 30, -20, 20, -20), "la": arm_(52, 30, -20, 20, -20)}), "pass")
    # both arms drive forward and open, the chest leaning in: the wave
    hit = s({"root": {"y": Y0 - .1, "z": -.08, "pitch": 4}, "torso": {"pitch": 8}, "head": {"pitch": 2},
             "ra": arm_(96, 24, -20, 2, -36), "la": arm_(96, 24, -20, 2, -36)})
    hold(sh, 14, hit, 19, {"ra": {"out": 30, "raise": 100}, "la": {"out": 30, "raise": 100}, "root": {"y": Y0 - .12}})
    sh.key(26, s({"root": {"y": Y0 - .04}, "ra": arm_(70, 0, 30, 70), "la": arm_(68, -4, 30, 74)}), "pass")
    sh.key(34, s(), "ease")
    sh.drag(["hand.R", "hand.L"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 14, 20)


def light4(arm):
    """41 f, contact 10, recover 17."""
    sh = Take(arm, N + "Light4")
    sh.key(0, s(), "ease")
    # the right hand comes up over the left shoulder, high
    sh.key(6, s({"torso": {"yaw": 12, "roll": 3}, "head": {"yaw": -12},
                 "ra": arm_(140, -50, 30, 100, 30)}), "ease")
    sh.key(8, s({"torso": {"yaw": 4}, "head": {"yaw": -8},
                 "ra": arm_(120, 0, 0, 40, 0)}), "pass")
    # the long diagonal cut out to his right side, the knees giving
    hit = s({"root": {"y": Y0 - .1}, "torso": {"yaw": -10, "roll": -3, "pitch": 4}, "head": {"yaw": 4, "pitch": 8},
             "ra": arm_(54, 70, -20, 4, -30)})
    hold(sh, 10, hit, 15, {"ra": {"raise": 48, "out": 76}, "root": {"y": Y0 - .12}})
    sh.key(26, s({"root": {"y": Y0 - .04}, "ra": arm_(66, 10, 20, 80, -10)}), "pass")
    sh.key(41, s(), "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 10, 17)


# ============================================================ heavy blows
def sand_hand(arm):
    """53 f, contact 14, recover 24."""
    sh = Take(arm, N + "SandHand")
    sh.key(0, s(), "ease")
    sh.key(5, s({"head": {"pitch": 2}, "la": arm_(120, 20, -10, 100, -10)}), "pass")
    # straight up over his head, clawed, the chest opening
    claw = s({"root": {"y": Y0 + .03}, "torso": {"pitch": -6, "roll": 4, "yaw": -4}, "head": {"pitch": -4, "yaw": -2},
              "la": arm_(176, 16, -20, 10, -44)})
    sh.key(9, claw, "ease")
    # the fingers close (a hair lower: the grip takes)
    sh.key(11, merge(claw, {"la": {"raise": 172, "elbow": 22, "wrist": 30}}), "ease")
    # dragged down to his hip: the knees give, the chest bows
    slam = s({"root": {"y": Y0 - .2, "pitch": 6}, "torso": {"pitch": 14, "roll": -3, "yaw": -6}, "head": {"pitch": 6, "yaw": -2},
              "la": arm_(10, 30, 0, 30, 30)})
    sh.key(13, merge(slam, {"la": {"raise": 40, "elbow": 20}}), "pass")
    hold(sh, 14, slam, 18, {"root": {"y": Y0 - .23}, "la": {"raise": 6}, "torso": {"pitch": 16}})
    sh.key(24, merge(slam, {"root": {"y": Y0 - .22}, "torso": {"pitch": 15}, "la": {"raise": 8}}), "ease")
    # the fist opens, the body rises, the arm comes back into the fold
    sh.key(38, s({"root": {"y": Y0 - .06}, "torso": {"pitch": 4}, "head": {"pitch": 8},
                  "la": arm_(46, -10, 20, 84, -10)}), "pass")
    sh.key(53, s(), "ease")
    sh.drag(["hand.L"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 14, 24)


def sand_fist(arm):
    """65 f, contact 20, recover 29."""
    sh = Take(arm, N + "SandFist")
    sh.key(0, s(), "ease")
    gather = s({"torso": {"pitch": -2, "yaw": 10}, "head": {"pitch": 6, "yaw": -12},
                "ra": arm_(44, -44, 30, 104, 10), "la": arm_(46, -40, 30, 96, -24)})
    sh.key(9, gather, "ease")
    # coiled back to the right, the weight on the back foot
    coil = merge(gather, {"root": {"y": Y0 - .06, "z": .1, "yaw": 14}, "torso": {"pitch": -6, "yaw": 22},
                          "head": {"yaw": -26}, "ra": {"raise": 36, "out": -24, "elbow": 118}, "la": {"raise": 38, "out": -20, "elbow": 110}})
    sh.key(16, coil, "ease")
    # both arms drive straight out as the chest uncoils
    drive = s({"root": {"y": Y0 - .1, "z": -.14, "pitch": 6, "yaw": -4}, "torso": {"pitch": 10, "yaw": -8}, "head": {"pitch": 2, "yaw": 6},
               "ra": arm_(92, -10, 0, 2, 0), "la": arm_(90, -12, 10, 8, -24)})
    sh.key(19, merge(drive, {"ra": {"raise": 80, "elbow": 40}, "la": {"raise": 80, "elbow": 44}, "torso": {"yaw": 0}}), "pass")
    hold(sh, 20, drive, 25, {"root": {"z": -.16}, "ra": {"raise": 94}, "la": {"raise": 92}})
    sh.key(29, merge(drive, {"root": {"z": -.15}, "ra": {"raise": 93}, "la": {"raise": 91}}), "ease")
    sh.key(45, s({"root": {"y": Y0 - .03}, "ra": arm_(66, 0, 10, 60), "la": arm_(60, 4, 10, 66)}), "pass")
    sh.key(65, s(), "ease")
    sh.drag(["hand.R", "hand.L"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 20, 29)


def sand_low_wave(arm):
    """43 f, contact 10, recover 19."""
    sh = Take(arm, N + "SandLowWave")
    sh.key(0, s(), "ease")
    up = s({"root": {"y": Y0 + .03}, "torso": {"pitch": -5}, "head": {"pitch": 4},
            "ra": arm_(118, 14, -40, 104, -30), "la": arm_(118, 14, -40, 104, -30)})
    sh.key(6, up, "ease")
    push = s({"root": {"y": Y0 - .26, "pitch": 10, "z": .04}, "torso": {"pitch": 18}, "head": {"pitch": 4},
              "ra": arm_(30, 22, -20, 4, -50), "la": arm_(30, 22, -20, 4, -50)})
    sh.key(9, merge(push, {"ra": {"raise": 56, "elbow": 40}, "la": {"raise": 56, "elbow": 40}, "root": {"y": Y0 - .18}}), "pass")
    hold(sh, 10, push, 15, {"root": {"y": Y0 - .29}, "ra": {"raise": 26, "out": 28}, "la": {"raise": 26, "out": 28}})
    sh.key(19, merge(push, {"root": {"y": Y0 - .28}, "ra": {"raise": 28, "out": 27}, "la": {"raise": 28, "out": 27}}), "ease")
    sh.key(31, s({"root": {"y": Y0 - .06}, "torso": {"pitch": 4},
                  "ra": arm_(50, -16, 20, 80, -10), "la": arm_(48, -18, 20, 80, -10)}), "pass")
    sh.key(43, s(), "ease")
    sh.drag(["hand.R", "hand.L"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 10, 19)


def sand_pillar(arm):
    """42 f, contact 16, recover 24."""
    sh = Take(arm, N + "SandPillar")
    sh.key(0, s(), "ease")
    scoop = s({"root": {"y": Y0 - .14}, "torso": {"pitch": 8, "yaw": 6, "roll": -3}, "head": {"pitch": 10, "yaw": -6},
               "ra": arm_(-4, 30, -70, 30, -10)})
    sh.key(9, scoop, "ease")
    sh.key(13, s({"root": {"y": Y0 - .02}, "torso": {"pitch": 0, "yaw": 2}, "head": {"pitch": 0},
                  "ra": arm_(100, 18, -70, 70, 0)}), "pass")
    rise = s({"root": {"y": Y0 + .06}, "torso": {"pitch": -8, "roll": 3, "yaw": -2}, "head": {"pitch": -12, "yaw": -2},
              "ra": arm_(178, 10, -70, 4, -20)})
    hold(sh, 16, rise, 21, {"ra": {"raise": 182}, "root": {"y": Y0 + .07}})
    sh.key(24, merge(rise, {"ra": {"raise": 180}, "head": {"pitch": -9}}), "ease")
    sh.key(33, s({"ra": arm_(88, -10, 10, 90, 0), "head": {"pitch": 4}}), "pass")
    sh.key(42, s(), "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 16, 24)


def sweep(arm):
    """24 f, contact 7, recover 14."""
    sh = Take(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    sh.key(4, s({"torso": {"yaw": 10, "roll": 2}, "head": {"yaw": -10},
                 "ra": arm_(110, -54, 30, 90, 20)}), "ease")
    sh.key(6, s({"root": {"y": Y0 - .1}, "torso": {"yaw": 2, "pitch": 6}, "ra": arm_(50, 0, 0, 20, 0)}), "pass")
    hit = s({"root": {"y": Y0 - .2, "pitch": 6}, "torso": {"pitch": 14, "yaw": -12, "roll": -3}, "head": {"pitch": 6, "yaw": 6},
             "ra": arm_(22, 66, -10, 4, 30)})
    hold(sh, 7, hit, 11, {"ra": {"out": 74}, "root": {"y": Y0 - .22}})
    sh.key(16, s({"root": {"y": Y0 - .08}, "torso": {"pitch": 4}, "ra": arm_(60, 10, 20, 70, 0)}), "pass")
    sh.key(24, s(), "ease")
    sh.drag(["hand.R"], 1)
    return done(sh, 7, 14)


def dash_attack(arm):
    """22 f, contact 5, recover 11."""
    sh = Take(arm, N + "DashAttack")
    lean = s({"root": {"pitch": 8, "z": -.04}, "torso": {"pitch": 4, "yaw": 8}, "head": {"pitch": -2, "yaw": -8},
              "ra": arm_(124, 36, -20, 112, 20)})
    sh.key(0, lean, "ease")
    sh.key(3, merge(lean, {"ra": arm_(100, 60, -20, 40, 10)}), "pass")
    hit = s({"root": {"pitch": 4, "z": -.06, "y": Y0 - .04}, "torso": {"pitch": 4, "yaw": -8}, "head": {"yaw": 4},
             "ra": arm_(92, 4, -10, 2, -24)})
    hold(sh, 5, hit, 9, {"ra": {"wrist": -34}})
    sh.key(15, s({"ra": arm_(80, -10, 20, 60)}), "pass")
    sh.key(22, s(), "ease")
    sh.drag(["hand.R"], 1)
    return done(sh, 5, 11)


# ================================================================== in the air
AIRB = s({"root": {"y": -.12, "pitch": 0, "yaw": 0}, "torso": {"pitch": 2, "yaw": 0}, "head": {"pitch": 6, "yaw": 0},
          "rf": {"x": .06, "y": .55, "z": -.05, "toe": -30, "yaw": 0, "knee": 4},
          "lf": {"x": -.06, "y": .5, "z": .08, "toe": -30, "yaw": 0, "knee": 4}})


def air(over=None):
    return merge(AIRB, over or {})


def air1(arm):
    """18 f, contact 5, recover 11."""
    sh = Take(arm, N + "Air1")
    sh.key(0, air(), "ease")
    sh.key(3, air({"torso": {"pitch": -4, "yaw": 6}, "ra": arm_(168, 20, -20, 40, 10)}), "ease")
    hit = air({"torso": {"pitch": 10, "yaw": -4}, "head": {"pitch": 12}, "ra": arm_(48, 14, -10, 2, 30),
               "rf": {"y": .7}, "lf": {"y": .62}})
    hold(sh, 5, hit, 9, {"ra": {"raise": 42}})
    sh.key(18, air(), "ease")
    sh.drag(["hand.R"], 1)
    return done(sh, 5, 11)


def air2(arm):
    """18 f, contact 6, recover 12."""
    sh = Take(arm, N + "Air2")
    sh.key(0, air(), "ease")
    sh.key(4, air({"torso": {"yaw": 10}, "head": {"yaw": -10}, "la": arm_(98, -66, 30, 110, 30)}), "ease")
    hit = air({"torso": {"yaw": -12}, "head": {"yaw": 4}, "la": arm_(90, 62, -20, 4, -26)})
    hold(sh, 6, hit, 10, {"la": {"out": 68}})
    sh.key(18, air(), "ease")
    sh.drag(["hand.L"], 1)
    return done(sh, 6, 12)


def slam(arm):
    """30 f, contact 10, recover 22: from the air into the floor."""
    sh = Take(arm, N + "Slam")
    up = air({"torso": {"pitch": -10}, "head": {"pitch": -2}, "root": {"pitch": -4},
              "ra": arm_(170, 18, -20, 30, -20), "la": arm_(170, 18, -20, 30, -20),
              "rf": {"y": .9, "z": .1}, "lf": {"y": .85, "z": .15}})
    sh.key(0, up, "ease")
    sh.key(6, merge(up, {"ra": {"raise": 176}, "la": {"raise": 176}, "torso": {"pitch": -12}}), "ease")
    sh.key(8, air({"torso": {"pitch": 4}, "ra": arm_(110, 18, -20, 10), "la": arm_(110, 18, -20, 10),
                   "rf": {"y": .35, "z": -.05}, "lf": {"y": .3, "z": .1}}), "pass")
    hit = s({"root": {"y": Y0 - .42, "pitch": 14, "z": .04}, "torso": {"pitch": 20}, "head": {"pitch": 0},
             "ra": arm_(24, 20, -20, 4, 40), "la": arm_(24, 20, -20, 4, 40)})
    hold(sh, 10, hit, 15, {"root": {"y": Y0 - .46}, "ra": {"raise": 20}, "la": {"raise": 20}})
    sh.key(22, merge(hit, {"root": {"y": Y0 - .36, "pitch": 10}, "torso": {"pitch": 14}}), "ease")
    sh.key(30, s(), "ease")
    sh.drag(["hand.R", "hand.L"], 1)
    sh.drag(["neck"], 1)
    return done(sh, 10, 22)


# ================================================================ routes
def sand_glide(arm):
    """30 f, contact 7, recover 16: carried sideways on the sand."""
    sh = Take(arm, N + "SandGlide")
    sh.key(0, s(), "ease")
    lean = s({"root": {"y": Y0 - .12, "roll": -8, "yaw": 14}, "torso": {"roll": -4, "yaw": 10}, "head": {"yaw": -14, "roll": 4},
              "ra": arm_(110, 76, -20, 50, 10), "la": arm_(40, 30, 0, 60)})
    sh.key(4, lean, "ease")
    hit = s({"root": {"y": Y0 - .14, "roll": -6, "yaw": 6}, "torso": {"roll": -2, "yaw": -12}, "head": {"yaw": 0, "roll": 2},
             "ra": arm_(90, -20, -10, 4, -24), "la": arm_(36, 36, 0, 50)})
    hold(sh, 7, hit, 12, {"ra": {"out": -28}})
    sh.key(16, merge(hit, {"ra": {"out": -26}, "root": {"y": Y0 - .12}}), "ease")
    sh.key(30, s(), "ease")
    sh.drag(["hand.R"], 1)
    return done(sh, 7, 16)


def grab(arm):
    """50 f, contact 11, recover 19."""
    sh = Take(arm, N + "Grab")
    sh.key(0, s(), "ease")
    sh.key(5, s({"torso": {"yaw": 6}, "ra": arm_(90, 30, -20, 110, 10)}), "ease")
    reach = s({"root": {"z": -.06, "pitch": 4}, "torso": {"pitch": 4, "yaw": -6}, "head": {"yaw": 2},
               "ra": arm_(90, 2, -40, 2, -30)})
    sh.key(9, reach, "pass")
    grip = merge(reach, {"ra": {"elbow": 10, "wrist": 30, "twist": -10}})
    hold(sh, 11, grip, 14, {"ra": {"wrist": 34}})
    pull = s({"root": {"z": .06, "y": Y0 - .06}, "torso": {"pitch": -2, "yaw": 6}, "head": {"pitch": 4},
              "ra": arm_(70, -6, 0, 100, 30)})
    sh.key(20, pull, "ease")
    sh.key(36, merge(pull, {"root": {"z": .04}, "ra": {"raise": 68}}), "ease")
    sh.key(50, s(), "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 11, 19)


def throw_up(arm):
    """31 f, contact 7, recover 13."""
    sh = Take(arm, N + "ThrowUp")
    sh.key(0, s(), "ease")
    low = s({"root": {"y": Y0 - .16}, "torso": {"pitch": 8, "yaw": 8}, "head": {"pitch": 8, "yaw": -8},
             "ra": arm_(0, 26, -70, 40, 20)})
    sh.key(4, low, "ease")
    sh.key(6, s({"root": {"y": Y0 - .04}, "torso": {"pitch": 0}, "ra": arm_(110, 16, -70, 50, 0)}), "pass")
    fling = s({"root": {"y": Y0 + .06}, "torso": {"pitch": -8, "yaw": -2}, "head": {"pitch": -14},
               "ra": arm_(178, 12, -70, 4, -30)})
    hold(sh, 7, fling, 12, {"ra": {"raise": 182, "wrist": -40}})
    sh.key(22, s({"ra": arm_(90, -10, 10, 90), "head": {"pitch": 2}}), "pass")
    sh.key(31, s(), "ease")
    sh.drag(["hand.R"], 1)
    sh.drag(["neck"], 2)
    return done(sh, 7, 13)


# ================================================================ guard
def guard_impact(arm):
    """24 f (the Guard loop of clips_react2 on his folded arms)."""
    g = clips_react2.add(BASE, {"root": {"y": -.14, "z": .1, "pitch": -2}, "torso": {"pitch": 6, "yaw": 4}, "head": {"pitch": 14, "yaw": 6}})
    g = clips_react2.setv(g, {"ra": FOLD_R, "la": FOLD_L})
    sh = Take(arm, N + "Guard.Impact")
    sh.key(0, g, "ease")
    hit = clips_react2.add(g, {"root": {"y": -.12, "z": .34, "pitch": -8}, "torso": {"pitch": -10, "yaw": -6}, "head": {"pitch": -6, "yaw": 4},
                               "ra": {"raise": 14, "elbow": -8}, "la": {"raise": 14, "elbow": -8}})
    hit = merge(hit, {"lf": {"toe": 16}})
    sh.key(2, hit, "impact")
    sh.key(5, merge(hit, {"root": {"z": g["root"]["z"] + .36}}), "ease")
    sh.key(10, clips_react2.add(g, {"root": {"y": -.1, "z": .18, "pitch": -2}, "torso": {"pitch": 2}}), "ease")
    sh.key(24, g, "ease")
    sh.drag(["neck"], 1)
    return sh.build()


# ============================================================== jumps
def legs(ry, rz, ly, lz, rtoe=-30, ltoe=-30, rx=.06, lx=-.06):
    return {"rf": {"x": rx, "y": ry, "z": rz, "toe": rtoe, "yaw": 0, "knee": 4},
            "lf": {"x": lx, "y": ly, "z": lz, "toe": ltoe, "yaw": 0, "knee": 4}}


AIR_BODY = s({"root": {"y": 0, "pitch": 0, "yaw": 0}, "torso": {"pitch": 2, "yaw": 0}, "head": {"pitch": 4, "yaw": 0}})


def jump_air(arm):
    """16 f along the arc: take-off (0), apex (8), reaching for the floor (16)."""
    sh = Take(arm, N + "Jump.Air")
    sh.key(0, merge(AIR_BODY, merge({"root": {"y": .05}, "head": {"pitch": -2}}, legs(.1, .12, .2, .02, -55, -50))), "ease")
    sh.key(4, merge(AIR_BODY, merge({"root": {"y": .05}}, legs(.6, -.05, .7, .05, -40, -40))), "pass")
    sh.key(8, merge(AIR_BODY, merge({"root": {"y": 0, "pitch": 4}, "torso": {"pitch": 4}}, legs(1.05, -.25, 1.0, -.15, -30, -30))), "ease")
    sh.key(12, merge(AIR_BODY, merge({"root": {"y": -.05}, "head": {"pitch": 10}}, legs(.7, -.15, .62, -.02, -20, -20))), "pass")
    sh.key(16, merge(AIR_BODY, merge({"root": {"y": -.1}, "head": {"pitch": 12}}, legs(.22, -.12, .3, .04, -8, -8))), "ease")
    return sh.build()


def jump_leap(arm):
    """26 f along the arc of a running jump."""
    sh = Take(arm, N + "Jump.Leap")
    lean = merge(AIR_BODY, {"root": {"pitch": 10}, "torso": {"pitch": 4}, "head": {"pitch": -6}})
    sh.key(0, merge(lean, legs(1.0, -.85, .15, .95, -20, -60)), "ease")
    sh.key(8, merge(lean, legs(1.1, -.7, .7, .6, -20, -40)), "pass")
    sh.key(13, merge(lean, merge({"root": {"pitch": 8}}, legs(1.1, -.45, 1.0, -.1, -30, -30))), "ease")
    sh.key(20, merge(lean, merge({"root": {"pitch": 4}, "head": {"pitch": 4}}, legs(.7, -.4, .6, -.05, -20, -20))), "pass")
    sh.key(26, merge(AIR_BODY, merge({"root": {"pitch": 2, "y": -.1}, "head": {"pitch": 10}}, legs(.25, -.35, .35, .1, -8, -8))), "ease")
    return sh.build()


def land(arm):
    """28 f: touch-down, absorb, back to the stance."""
    sh = Take(arm, N + "Land")
    sh.key(0, s({"root": {"y": Y0 + .04}, "head": {"pitch": 10}}), "ease")
    deep = s({"root": {"y": Y0 - .62, "pitch": 12, "z": .06}, "torso": {"pitch": 12}, "head": {"pitch": -4},
              "ra": arm_(52, -20, 40, 112), "la": arm_(48, -24, 36, 108)})
    sh.key(5, deep, "impact")
    sh.key(9, merge(deep, {"root": {"y": Y0 - .64}}), "ease")
    sh.key(17, s({"root": {"y": Y0 - .18, "pitch": 4}, "torso": {"pitch": 3}, "head": {"pitch": 4}}), "pass")
    sh.key(28, s(), "ease")
    sh.drag(["shoulder.R", "shoulder.L"], 1)
    sh.drag(["neck"], 2)
    return sh.build()


def flip(arm):
    """48 f, the tuck the engine turns over (no spin in the clip)."""
    sh = Take(arm, N + "Flip")
    open_ = merge(AIR_BODY, legs(.25, .1, .3, .05, -50, -50))
    sh.key(0, open_, "ease")
    tuck = merge(AIR_BODY, merge({"root": {"y": .2, "pitch": 10}, "torso": {"pitch": 22}, "head": {"pitch": 24}},
                                 legs(1.45, -.35, 1.4, -.3, -20, -20)))
    sh.key(10, tuck, "ease")
    sh.key(32, merge(tuck, {"root": {"y": .22}, "torso": {"pitch": 24}}), "ease")
    sh.key(41, merge(AIR_BODY, merge({"root": {"y": 0, "pitch": 4}, "head": {"pitch": 8}}, legs(.7, -.2, .65, -.05, -20, -20))), "pass")
    sh.key(48, merge(AIR_BODY, merge({"root": {"y": -.08}, "head": {"pitch": 10}}, legs(.25, -.1, .3, .05, -8, -8))), "ease")
    return sh.build()


def author(arm):
    acts = [light1(arm), light2(arm), light3(arm), light4(arm),
            sand_hand(arm), sand_fist(arm), sand_low_wave(arm), sand_pillar(arm), sweep(arm), dash_attack(arm),
            air1(arm), air2(arm), slam(arm), sand_glide(arm), grab(arm), throw_up(arm), guard_impact(arm),
            jump_leap(arm), jump_air(arm), land(arm), flip(arm)]
    names = {a.name for a in acts}
    missing = [n for n in WANT if n not in names]
    if missing:
        print("MISSING", missing)
    return acts
