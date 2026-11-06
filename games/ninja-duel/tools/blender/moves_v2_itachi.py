"""Moveset pass v2: Itachi (Mirage) - his strings, heavy blows, air attacks,
jumps and landings re-authored on the control rig (06/11, user: « vérifie
les poses de saut, les impacts des gros coups, même les attaques que tu
crois bonnes »).

His body (itachi_p3.STANCE, docs/characters/ITACHI.md): upright and quiet,
left foot forward, the left hand open in front, the right low by the pouch.
Economy of the torso, the gaze before the body, no full turn without
reason, a calm pose after the impact - a SMALLER gesture than the
opponent's, but every blow carried by the whole body: the hips lead, the
shoulder follows, the hand or the foot arrives last, then overshoots a hair
and settles. Heavy blows load visibly, land with the whole weight, hold the
contact 3-4 frames and recover heavily. The Mixamo captures (jab, cross,
hadouken, kick_side, uppercut, front_flip, land, jump_up...) are the timing
references: the shape of their velocity (slow load, fast drive, decelerating
follow-through) is keyed with nd_shot spacings, in his own small shapes,
instead of being retargeted as is (their silhouettes were generic and
wide). Every clip keeps the length and the contact / recover markers the
server and the engine are timed on (see SLOTS; the timing came from the
clip the game plays now, src/Client/AuthoredClips3x.luau).

Server string (Brawler: the last hit always throws): Light1 -> Light2 ->
Light4 -> Light3; heavyAfterOne / readCounter = CounterPalm; routes up
Launcher, down Sweep, side FeintStep, air up AirDrive, down AirSpike, side
AirSwitch.

  Light1      the deflection: the left knife-hand cocks outside, then snaps
              across to the jaw on a half step of the front foot; the hips
              turn in first, the shoulder after, the hand last; it carries a
              hair past the line and comes back to it while the rear foot
              follows the half step.
  Light2      the palm: the left hand presses the guard down while the hips
              coil; the front foot steps, the hips square and the RIGHT palm
              heel drives to the sternum under the left hand (pull-push),
              the rear heel turns out; held a beat, then the rear foot follows.
  Light4      the spear hand under the guard: he dips, the left hand pushes
              the guard down, the right fingers go in under it to the solar
              plexus on a half step - lower and shorter than L2.
  Light3      the finisher (a kick, it throws): the weight rocks onto the
              front foot, the rear knee comes up to the chest, the hips
              thrust a straight push kick into the belly while the chest
              leans back over the support foot (head to heel one line), the
              hit is held, then the leg re-chambers and goes back to its
              place - he ends in his stance, facing him.
  Heavy       the crossing palm: the left hand reaches out and intercepts,
              the hips sit deep onto the rear leg (the wind-up reads: right
              palm far back at the ribs, chest coiled), then a long step and
              the whole body drives through - hips, shoulder, the RIGHT palm
              last, rear leg straight behind it; held four frames on the
              contact, the hips sink back heavily and the rear foot steps up.
  Launcher    the rising palm: he dips deep under the guard (palm cocked low
              by the knee, the left hand pressing down), then unfolds all at
              once - legs, hips, chest - onto his toes, the RIGHT palm
              rising under the chin to the sky; held, then he sinks back.
  Slam        in the air: both hands rise clasped over the head, the back
              arches, then the whole body whips down over them and plunges
              (the active window is the fall); he lands in a deep crouch,
              right knee down, the right palm on the floor, holds it, rises.
  Sweep       the reap: he drops onto the front leg, the left hand to the
              floor, and the RIGHT foot reaps low from behind across the
              ankles (outside to inside) with the hips turning through; the
              hips withdraw and he rises out of reach. No ground spin.
  DashAttack  the arrival: the body glides in low, the right hand reaching
              first, a long lunge onto the front foot, left arm trailing;
              the rear foot catches up.
  CounterPalm the answer: the palm is already loaded at the ribs, one frame
              and it drives through on a half step - smaller than the blow
              it punishes, held while it pushes him away.
  FeintStep   the side route: the left hand fakes a jab (the eyes go with
              it), the rear foot swings 30 deg round to his flank and the
              RIGHT palm touches the arm from there; the left foot follows.
  Air1        the short side palm in the air: hips wind right, the LEFT
              palm snaps out sideways, knees stay gathered.
  Air2        the air kick to the head: the right knee chambers across, the
              hips turn over and the shin whips round at head height, the
              chest leaning away; re-chambers.
  AirDrive    the air side kick (route up): the knee to the chest, the body
              turns side-on and leans back, the heel drives straight out
              (head to heel one line), held.
  AirFlip     the flip kick: he tucks and turns over backward, the right
              leg whips up over the top (contact upside down), a full and
              clean 360, he opens back into the air pose.
  AirSpike    the hammer drop (route down): hands clasp high, the back
              arches, the whole body closes and the hands fall on the head.
  AirSwitch   the hook switch (route aside): the left knee crosses, the hips
              swing the other way and the heel hooks out at head height,
              the body tilting away.
  Grab        the left hand shoots to the collar on a half step, the right
              takes the arm, he clamps and pulls the body in to his chest.
  ThrowUp     from the hold: he sinks under the body and heaves it up with
              both arms, rising onto his toes; held, then the stance.
  Guard.Impact the forearms are driven into the face, the hips are pushed
              back over the rear heel, the knees take it, a little rebound,
              back to the guard.
  Flip        the tuck the engine turns over (it adds the 360 itself):
              arms swing up off the floor, knees to the chest, hands on the
              shins, held, then it opens to land.
  Jump.Leap   the running jump along its arc (the engine samples it by the
              vertical speed, frame 0 = take-off): the push-off leg extended
              behind, the lead knee driving up, the arms swung; the hurdle
              at the apex; the lead foot reaching for the floor.
  Jump.Air    the hop along its arc: legs extended off the floor, knees
              drawn up at the apex without spreading the arms, then the
              legs open down to find the floor, the free hand watching it.
  Land        forefoot then heel, the knees bend deep and the hips sink,
              the arms come forward to balance, the gaze stays up; he
              rises with a small overshoot into the stance.
  PhoenixFlower.Channel / Release / Recover   the seal brought to the lips
              (inhale: the chest rises, the head tips back), three separate
              puffs, two-handed at the mouth, the head sweeping a little
              between them; then the hands lower into the stance.
"""
import bpy, os, re, math
from mathutils import Matrix, Vector, Quaternion
import nd_rig, nd_ctrl, nd_anim, nd_shot
from nd_shot import Shot, merge
from itachi_p3 import STANCE as P3_STANCE

HERE = os.path.dirname(os.path.abspath(__file__))
CLIENT = os.path.normpath(os.path.join(HERE, "..", "..", "src", "Client"))
N = "Mirage."
FPS = 60

# Every channel explicit, so that a key written from the stance resets all
# of them (Shot merges each key onto the previous one).
ZERO = {"travel": {"x": 0, "z": 0, "yaw": 0},
        "root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0, "tuck": 0},
        "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
        "ra": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "la": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "rf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0},
        "lf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}}
STANCE = merge(ZERO, P3_STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]
# In the air: hips a little under, knees drawn up and forward, the left hand
# in front, the right low - compact (bible: knees up without spreading arms).
AIR = merge(STANCE, {"root": {"y": -.45, "z": 0, "pitch": 8, "yaw": 6}, "torso": {"pitch": 6, "yaw": -4},
                     "head": {"pitch": -12, "yaw": -4},
                     "la": {"raise": 56, "out": 10, "twist": -4, "elbow": 56, "wrist": 6},
                     "ra": {"raise": 18, "out": 20, "twist": -16, "elbow": 66, "wrist": 0},
                     "rf": {"x": .12, "z": -.3, "y": 1.0, "toe": -26, "yaw": 6},
                     "lf": {"x": -.1, "z": -.5, "y": 1.15, "toe": -22, "yaw": -4}})
PALM_R = {"raise": 86, "out": -8, "twist": -40, "elbow": 3, "wrist": 56}


def s(over=None):
    return merge(STANCE, over or {})


def at(T, over=None):
    """The stance T studs along z (feet with it)."""
    return merge(s({"travel": {"z": T}, "rf": {"z": RF["z"] + T}, "lf": {"z": LF["z"] + T}}), over or {})


def air(over=None):
    return merge(AIR, over or {})


def heel(deg, **kw):
    """A foot on its ball: the heel up `deg`, the ankle lifted with it."""
    out = {"toe": -deg, "y": .5 * math.sin(math.radians(deg))}
    out.update(kw)
    return out


def ms(frames):
    return {k: v / FPS for k, v in frames.items()}


class Take(Shot):
    """nd_shot.Shot that warns when a planted foot is out of the leg's reach
    (the IK would lift it off the floor)."""
    def key(self, frame, spec, spacing="ease"):
        full = merge(getattr(self, "_full", {}), spec)
        self._full = full
        for side, k, sx in (("R", "rf", 1), ("L", "lf", -1)):
            f = full.get(k, {})
            if f.get("y", 0) > .3:
                continue
            r, t = full.get("root", {}), full.get("travel", {})
            if r.get("tuck"):
                continue
            Rr = nd_anim.R(0, -t.get("yaw", 0), 0) @ nd_anim.ori(r)
            hip = Vector((t.get("x", 0) + r.get("x", 0), 3.0 + r.get("y", 0), t.get("z", 0) + r.get("z", 0))) + Rr @ Vector((.5 * sx, -.55, 0))
            ank = Vector((.5 * sx + f.get("x", 0), .4 + f.get("y", 0), f.get("z", 0)))
            d = (ank - hip).length
            if d > 2.04:
                print("REACH %s f%d %s %.2f" % (self.name, frame, k, d))
        return Shot.key(self, frame, spec, spacing)


# ================================================================ strings
def light1(arm):
    sh = Take(arm, N + "Light1")
    sh.key(0, s(), "ease")
    # cock: hips coil back a little, the left hand draws out and up outside
    sh.key(3, s({"root": {"y": -.34, "z": .06, "yaw": 34}, "torso": {"yaw": -6}, "head": {"yaw": -20},
                 "la": {"raise": 80, "out": 48, "twist": -36, "elbow": 96, "wrist": 12},
                 "ra": {"raise": 8, "out": 14, "elbow": 72}, "lf": {"y": .07, "z": -.62, "toe": 6}}), "ease")
    # the hips are already turning in, the hand still back (hips lead)
    sh.key(5, s({"root": {"y": -.36, "z": -.04, "yaw": 24, "pitch": 5}, "torso": {"yaw": -4}, "head": {"yaw": -14},
                 "la": {"raise": 82, "out": 22, "twist": -18, "elbow": 54, "wrist": 4},
                 "ra": {"raise": 10, "out": 12, "elbow": 74}, "lf": {"y": .05, "z": -.8, "toe": 2}}), "pass")
    hit = s({"root": {"y": -.38, "z": -.14, "x": -.04, "pitch": 7, "yaw": 16}, "torso": {"pitch": 4, "yaw": -16},
             "head": {"yaw": -10},
             "la": {"raise": 84, "out": -26, "twist": 14, "elbow": 6, "wrist": -14},
             "ra": {"raise": 12, "out": 12, "twist": -24, "elbow": 76, "wrist": -6},
             "lf": {"z": -.86, "y": 0, "toe": 0}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"root": {"z": -.17, "yaw": 13}, "torso": {"yaw": -20}, "la": {"out": -36, "elbow": 12}}), "ease")
    sh.key(12, merge(hit, {"root": {"z": -.15, "yaw": 15}, "torso": {"yaw": -17}, "la": {"out": -30, "elbow": 16}}), "ease")
    # the hand returns to the line, the rear foot follows the half step
    sh.key(17, merge(hit, {"travel": {"z": -.15}, "root": {"z": -.1, "yaw": 22, "pitch": 5}, "torso": {"yaw": -12},
                           "la": {"raise": 62, "out": -2, "twist": -4, "elbow": 34, "wrist": 6},
                           "rf": heel(10, z = .48)}), "pass")
    sh.key(24, at(-.3), "ease")
    sh.drag(["neck"], 1).drag(["hand.R", "forearm.R"], 2)
    return sh.build(markers=ms({"contact": 6, "recover": 12}))


def light2(arm):
    sh = Take(arm, N + "Light2")
    sh.key(0, s(), "ease")
    # load: hips coil, the right palm chambered at the ribs, the left hand
    # reaches forward and down onto his guard, the front foot unweights
    sh.key(3, s({"root": {"y": -.4, "z": .06, "yaw": 36}, "torso": {"yaw": -4, "pitch": 3},
                 "ra": {"raise": -12, "out": 14, "twist": -12, "elbow": 112, "wrist": 44},
                 "la": {"raise": 58, "out": -8, "twist": 8, "elbow": 26, "wrist": 30},
                 "lf": {"y": .06, "toe": 4}}), "ease")
    sh.key(5, s({"root": {"y": -.42, "z": -.08, "yaw": 22, "pitch": 6}, "torso": {"yaw": -2, "pitch": 4},
                 "ra": {"raise": 34, "out": 4, "twist": -26, "elbow": 82, "wrist": 50},
                 "la": {"raise": 46, "out": -16, "twist": 12, "elbow": 48, "wrist": 26},
                 "lf": {"y": .06, "z": -.72}, "rf": heel(8)}), "pass")
    hit = s({"root": {"y": -.44, "z": -.26, "x": -.04, "pitch": 9, "yaw": 4}, "torso": {"pitch": 5, "yaw": -6},
             "head": {"yaw": -6, "pitch": -2},
             "ra": PALM_R,
             "la": {"raise": 30, "out": -24, "twist": 16, "elbow": 82, "wrist": 22},
             "lf": {"z": -.81, "y": 0, "toe": 0}, "rf": heel(18, yaw=14)})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"z": -.3}, "ra": {"raise": 89}, "torso": {"yaw": -8}}), "ease")
    sh.key(13, merge(hit, {"root": {"z": -.28}, "ra": {"raise": 87, "elbow": 8}}), "ease")
    sh.key(17, merge(hit, {"travel": {"z": -.12}, "root": {"z": -.12, "yaw": 18, "pitch": 6}, "torso": {"yaw": -8},
                           "ra": {"raise": 40, "out": 10, "elbow": 70, "wrist": 20},
                           "la": {"raise": 48, "out": -4, "elbow": 44},
                           "rf": {"z": .5, "y": .1, "toe": -6, "yaw": 24}}), "pass")
    sh.key(22, at(-.25), "ease")
    sh.drag(["neck"], 1).drag(["hand.L"], 1)
    return sh.build(markers=ms({"contact": 7, "recover": 13}))


def light4(arm):
    sh = Take(arm, N + "Light4")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.5, "z": .02, "yaw": 32, "pitch": 8}, "torso": {"pitch": 4, "yaw": -6},
                 "ra": {"raise": -14, "out": 12, "twist": 10, "elbow": 104, "wrist": -6},
                 "la": {"raise": 64, "out": -4, "twist": 6, "elbow": 22, "wrist": 30},
                 "lf": {"y": .07, "z": -.66}}), "ease")
    hit = s({"root": {"y": -.6, "z": -.26, "x": -.04, "pitch": 15, "yaw": 8}, "torso": {"pitch": 6, "yaw": -10},
             "head": {"pitch": -8, "yaw": -6},
             "ra": {"raise": 66, "out": -12, "twist": -6, "elbow": 2, "wrist": -4},
             "la": {"raise": 26, "out": -20, "twist": 14, "elbow": 66, "wrist": 48},
             "lf": {"z": -.86, "y": 0}, "rf": heel(16, yaw=16)})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.3, "pitch": 16}, "ra": {"raise": 70}}), "ease")
    sh.key(13, merge(hit, {"root": {"z": -.28, "y": -.56}, "ra": {"raise": 68, "elbow": 8}}), "ease")
    sh.key(20, merge(hit, {"travel": {"z": -.15}, "root": {"y": -.42, "z": -.1, "yaw": 20, "pitch": 7}, "torso": {"pitch": 3, "yaw": -8},
                           "ra": {"raise": 24, "out": 12, "elbow": 72, "wrist": 0},
                           "la": {"raise": 50, "out": 0, "elbow": 40, "wrist": 8},
                           "rf": {"z": .46, "y": .1, "toe": -4, "yaw": 26}}), "pass")
    sh.key(29, at(-.3), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 5, "recover": 13}))


def light3(arm):
    sh = Take(arm, N + "Light3")
    sh.key(0, s(), "ease")
    # the weight rocks onto the front foot, the rear heel peels
    sh.key(4, s({"root": {"y": -.34, "z": -.16, "x": -.1, "yaw": 18, "pitch": 4}, "torso": {"yaw": -6},
                 "la": {"raise": 58, "elbow": 52}, "ra": {"raise": 14, "elbow": 80},
                 "rf": heel(30)}), "ease")
    # chamber: the knee to the chest, the chest stays over the support foot
    sh.key(7, s({"root": {"y": -.22, "z": -.3, "x": -.16, "yaw": 8, "pitch": -4}, "torso": {"pitch": -2, "yaw": -6},
                 "head": {"pitch": 2},
                 "la": {"raise": 48, "out": 4, "elbow": 84}, "ra": {"raise": 6, "out": 20, "elbow": 86},
                 "rf": {"x": .16, "y": 1.3, "z": -.5, "toe": -10, "yaw": 6}, "lf": {"yaw": -14}}), "pass")
    hit = s({"root": {"y": -.24, "z": -.32, "x": -.18, "yaw": 4, "pitch": -16}, "torso": {"pitch": -4, "yaw": -4},
             "head": {"pitch": 10, "yaw": -6},
             "la": {"raise": 40, "out": 8, "twist": 0, "elbow": 104, "wrist": 0},
             "ra": {"raise": -26, "out": 22, "twist": -10, "elbow": 34, "wrist": 0},
             "rf": {"x": .06, "y": 1.25, "z": -2.15, "toe": 14, "yaw": 0}, "lf": {"yaw": -18}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"root": {"pitch": -18, "z": -.34}, "rf": {"z": -2.2}}), "ease")
    sh.key(15, merge(hit, {"root": {"pitch": -15}, "rf": {"z": -2.12, "y": 1.22}}), "ease")
    # re-chamber, then the foot goes back to its place
    sh.key(19, s({"root": {"y": -.24, "z": -.24, "x": -.14, "yaw": 10, "pitch": -4}, "torso": {"pitch": -2, "yaw": -6},
                  "la": {"raise": 48, "elbow": 70}, "ra": {"raise": 6, "out": 18, "elbow": 76},
                  "rf": {"x": .18, "y": 1.1, "z": -.3, "toe": -14, "yaw": 10}, "lf": {"yaw": -14}}), "pass")
    sh.key(23, s({"root": {"y": -.34, "z": -.02}, "rf": {"y": .06, "toe": -6}, "lf": {"yaw": -8}}), "ease")
    sh.key(26, s(), "ease")
    sh.drag(["neck"], 1).drag(["hand.L", "hand.R"], 1)
    return sh.build(markers=ms({"contact": 9, "recover": 15}))


# ============================================================ heavy blows
def heavy(arm):
    sh = Take(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    # the left hand reaches and intercepts; the hips start to sit back
    sh.key(5, s({"root": {"y": -.4, "z": .1, "yaw": 34}, "torso": {"yaw": -4},
                 "la": {"raise": 88, "out": 28, "twist": -20, "elbow": 24, "wrist": 0},
                 "ra": {"raise": -8, "out": 14, "elbow": 96, "wrist": 30}}), "ease")
    # the wind-up: deep onto the rear leg, coiled, palm far back, the left
    # hand pulls the guard aside; the eyes stay on him
    load = s({"root": {"y": -.62, "z": .26, "x": .1, "pitch": -2, "yaw": 50}, "torso": {"pitch": 0, "yaw": 8},
              "head": {"yaw": -34, "pitch": -2},
              "la": {"raise": 62, "out": -28, "twist": 12, "elbow": 64, "wrist": 12},
              "ra": {"raise": -34, "out": 22, "twist": -10, "elbow": 112, "wrist": 52},
              "lf": {"toe": 10, "y": .05}})
    sh.key(12, load, "ease")
    sh.key(14, merge(load, {"root": {"y": -.64, "z": .24}, "lf": {"y": .14, "z": -.74, "toe": 6}}), "ease")
    # the step and the drive: the hips first
    sh.key(16, s({"root": {"y": -.6, "z": -.3, "x": -.04, "pitch": 8, "yaw": 20}, "torso": {"pitch": 4, "yaw": 2},
                  "head": {"yaw": -18},
                  "la": {"raise": 46, "out": -30, "twist": 14, "elbow": 96, "wrist": 10},
                  "ra": {"raise": 36, "out": 4, "twist": -28, "elbow": 82, "wrist": 54},
                  "lf": {"z": -1.12, "y": .04, "toe": 0}, "rf": heel(12)}), "pass")
    hit = s({"root": {"y": -.66, "z": -.68, "x": -.08, "pitch": 15, "yaw": -4}, "torso": {"pitch": 8, "yaw": -14},
             "head": {"yaw": -4, "pitch": 2},
             "ra": {"raise": 88, "out": -14, "twist": -40, "elbow": 2, "wrist": 60},
             "la": {"raise": 30, "out": -32, "twist": 16, "elbow": 120, "wrist": 10},
             "lf": {"z": -1.16, "y": 0, "toe": 0}, "rf": heel(32, yaw=22)})
    sh.key(18, hit, "impact")
    sh.key(20, merge(hit, {"root": {"z": -.73, "pitch": 16}, "ra": {"raise": 90}, "torso": {"yaw": -16}}), "ease")
    sh.key(23, merge(hit, {"root": {"z": -.72, "pitch": 16}, "ra": {"raise": 90}, "torso": {"yaw": -16}}), "ease")
    sh.key(26, merge(hit, {"root": {"z": -.62, "y": -.64}, "ra": {"raise": 84, "elbow": 8}}), "ease")
    # heavy recovery: the pelvis withdraws and sinks, then the rear foot steps up
    sh.key(31, s({"travel": {"z": -.25}, "root": {"y": -.56, "z": -.34, "pitch": 7, "yaw": 16}, "torso": {"pitch": 4, "yaw": -8},
                  "ra": {"raise": 36, "out": 10, "elbow": 74, "wrist": 20},
                  "la": {"raise": 46, "out": -8, "elbow": 52},
                  "lf": {"z": -1.16}, "rf": {"z": .3, "y": .16, "toe": -8, "yaw": 26}}), "pass")
    sh.key(35, at(-.6, {"root": {"y": -.4}, "rf": {"y": .02}}), "ease")
    sh.key(40, at(-.6), "ease")
    sh.drag(["neck"], 2).drag(["hand.L"], 1)
    return sh.build(markers=ms({"contact": 18, "recover": 26}))


def launcher(arm):
    sh = Take(arm, N + "Launcher")
    sh.key(0, s(), "ease")
    dip = s({"root": {"y": -.95, "z": .02, "pitch": 22, "yaw": 22}, "torso": {"pitch": 10, "yaw": -6},
             "head": {"pitch": -16, "yaw": -12},
             "ra": {"raise": -18, "out": 18, "twist": -20, "elbow": 26, "wrist": 64},
             "la": {"raise": 52, "out": -12, "twist": 10, "elbow": 26, "wrist": 34},
             "lf": {"z": -.62}})
    sh.key(5, dip, "ease")
    sh.key(6, merge(dip, {"root": {"y": -.97}}), "ease")
    sh.key(8, s({"root": {"y": -.55, "z": -.08, "pitch": 8, "yaw": 14}, "torso": {"pitch": 2, "yaw": -6},
                 "head": {"pitch": -16},
                 "ra": {"raise": 62, "out": 2, "twist": -24, "elbow": 52, "wrist": 66},
                 "la": {"raise": 30, "out": 0, "elbow": 50, "wrist": 20},
                 "lf": {"z": -.62}, "rf": heel(10)}), "pass")
    hit = s({"root": {"y": -.2, "z": -.16, "pitch": -8, "yaw": 8}, "torso": {"pitch": -12, "yaw": -6},
             "head": {"pitch": -24, "yaw": -6},
             "ra": {"raise": 162, "out": -6, "twist": -20, "elbow": 6, "wrist": 70},
             "la": {"raise": -14, "out": 22, "twist": 0, "elbow": 34, "wrist": 0},
             "lf": {"z": -.62}, "rf": heel(36, z=.5)})
    sh.key(10, hit, "impact")
    sh.key(13, merge(hit, {"root": {"y": -.17}, "ra": {"raise": 168}, "torso": {"pitch": -14}}), "ease")
    sh.key(16, merge(hit, {"root": {"y": -.2}, "ra": {"raise": 162, "elbow": 12}}), "ease")
    sh.key(21, s({"root": {"y": -.46, "pitch": 6, "yaw": 18}, "torso": {"pitch": 2},
                  "ra": {"raise": 70, "out": 14, "elbow": 44, "wrist": 20}, "la": {"raise": 36, "elbow": 40},
                  "rf": heel(6, z=.56)}), "pass")
    sh.key(26, s(), "ease")
    sh.drag(["neck"], 1).drag(["hand.L"], 1)
    return sh.build(markers=ms({"contact": 10, "recover": 16}))


def slam(arm):
    sh = Take(arm, N + "Slam")
    sh.key(0, air(), "ease")
    clasp = {"raise": 172, "out": -16, "twist": 0, "elbow": 36, "wrist": 10}
    sh.key(6, air({"root": {"y": -.3, "pitch": -16}, "torso": {"pitch": -16}, "head": {"pitch": -6},
                   "la": clasp, "ra": clasp,
                   "rf": {"y": 1.3, "z": .1, "toe": -30}, "lf": {"y": 1.4, "z": -.2, "toe": -30}}), "ease")
    down = {"raise": 52, "out": -14, "twist": 0, "elbow": 6, "wrist": 12}
    hit = air({"root": {"y": -.3, "pitch": 30}, "torso": {"pitch": 30}, "head": {"pitch": -34},
               "la": down, "ra": down,
               "rf": {"y": .9, "z": .55, "toe": -40}, "lf": {"y": 1.1, "z": .2, "toe": -36}})
    sh.key(9, hit, "impact")
    sh.key(13, merge(hit, {"root": {"pitch": 34}, "torso": {"pitch": 34}, "la": {"raise": 44}, "ra": {"raise": 44}}), "ease")
    # the plunge: the legs come under to meet the floor
    sh.key(19, air({"root": {"y": -.5, "pitch": 24}, "torso": {"pitch": 22}, "head": {"pitch": -26},
                    "ra": {"raise": 60, "out": -6, "elbow": 10, "wrist": 30}, "la": {"raise": 20, "out": 40, "elbow": 20},
                    "rf": {"x": .3, "y": .5, "z": .5, "toe": -30}, "lf": {"x": -.1, "y": .35, "z": -.6, "toe": -10}}), "pass")
    land = s({"root": {"y": -1.32, "z": .1, "pitch": 30, "yaw": 20}, "torso": {"pitch": 18, "yaw": -8},
              "head": {"pitch": -30, "yaw": -10},
              "ra": {"raise": 34, "out": -4, "twist": -10, "elbow": 6, "wrist": 60},
              "la": {"raise": -10, "out": 52, "twist": 0, "elbow": 16, "wrist": 0},
              "rf": {"x": .34, "y": .12, "z": .85, "toe": -60, "yaw": 20}, "lf": {"z": -.62, "yaw": -4}})
    sh.key(22, land, "impact")
    sh.key(25, merge(land, {"root": {"y": -1.38}, "torso": {"pitch": 20}}), "ease")
    sh.key(30, merge(land, {"root": {"y": -1.34}}), "ease")
    sh.key(37, s({"root": {"y": -.62, "pitch": 10, "yaw": 22}, "torso": {"pitch": 4},
                  "ra": {"raise": 20, "out": 18, "elbow": 50}, "la": {"raise": 40, "out": 14, "elbow": 40},
                  "rf": heel(10)}), "pass")
    sh.key(44, s(), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 9, "recover": 22}))


def sweep(arm):
    sh = Take(arm, N + "Sweep")
    sh.key(0, s(), "ease")
    drop = s({"root": {"y": -1.12, "z": -.12, "x": -.16, "pitch": 26, "yaw": 42}, "torso": {"pitch": 16, "yaw": -12},
              "head": {"pitch": -24, "yaw": -18},
              "la": {"raise": 56, "out": 24, "twist": 0, "elbow": 10, "wrist": 40},
              "ra": {"raise": 20, "out": 56, "twist": 0, "elbow": 20, "wrist": 0},
              "rf": {"x": .7, "y": .1, "z": .8, "toe": -10, "yaw": 50}, "lf": {"yaw": -10}})
    sh.key(4, drop, "ease")
    sh.key(6, merge(drop, {"root": {"y": -1.18, "yaw": 14}, "torso": {"yaw": -2},
                           "rf": {"x": .9, "z": -.3, "y": .1, "yaw": 0}}), "pass")
    hit = s({"root": {"y": -1.2, "z": -.14, "x": -.2, "pitch": 26, "yaw": -14}, "torso": {"pitch": 16, "yaw": 8},
             "head": {"pitch": -24, "yaw": 6},
             "la": {"raise": 50, "out": 18, "twist": 0, "elbow": 6, "wrist": 44},
             "ra": {"raise": -24, "out": 48, "twist": 0, "elbow": 24, "wrist": 0},
             "rf": {"x": .1, "y": .09, "z": -1.55, "toe": 6, "yaw": -72}, "lf": {"yaw": -14}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"yaw": -22}, "rf": {"x": -.32, "z": -1.42, "yaw": -82}}), "ease")
    sh.key(14, merge(hit, {"root": {"yaw": -20, "y": -1.16}, "rf": {"x": -.26, "z": -1.3, "yaw": -80}}), "ease")
    sh.key(20, s({"root": {"y": -.72, "z": .1, "pitch": 12, "yaw": 20}, "torso": {"pitch": 6, "yaw": -6},
                  "la": {"raise": 56, "out": 10, "elbow": 30}, "ra": {"raise": 14, "out": 30, "elbow": 50},
                  "rf": {"x": .3, "y": .2, "z": .3, "toe": -10, "yaw": 20}}), "pass")
    sh.key(28, s(), "ease")
    sh.drag(["neck"], 2).drag(["hand.R"], 1)
    return sh.build(markers=ms({"contact": 7, "recover": 14}))


def dash_attack(arm):
    sh = Take(arm, N + "DashAttack")
    glide = s({"root": {"y": -.62, "z": -.1, "pitch": 18, "yaw": 16}, "torso": {"pitch": 8, "yaw": -6},
               "head": {"pitch": -10},
               "ra": {"raise": 20, "out": 12, "twist": -20, "elbow": 96, "wrist": 40},
               "la": {"raise": 10, "out": 20, "elbow": 30},
               "lf": {"z": -.62}, "rf": heel(20, z=.72)})
    sh.key(0, glide, "ease")
    sh.key(2, merge(glide, {"root": {"y": -.66, "z": -.26}, "ra": {"raise": 52, "elbow": 60},
                            "lf": {"y": .16, "z": -1.0, "toe": 8}}), "pass")
    hit = s({"root": {"y": -.76, "z": -.66, "x": -.06, "pitch": 18, "yaw": 4}, "torso": {"pitch": 10, "yaw": -12},
             "head": {"pitch": -8, "yaw": -4},
             "ra": PALM_R,
             "la": {"raise": -38, "out": 22, "twist": 0, "elbow": 22, "wrist": 0},
             "lf": {"z": -1.3, "y": 0, "toe": 0}, "rf": heel(34, z=.72, yaw=20)})
    sh.key(4, hit, "impact")
    sh.key(7, merge(hit, {"root": {"z": -.72}, "ra": {"raise": 89}}), "ease")
    sh.key(10, merge(hit, {"root": {"z": -.7, "y": -.72}, "ra": {"elbow": 8}}), "ease")
    sh.key(14, s({"travel": {"z": -.4}, "root": {"y": -.5, "z": -.36, "pitch": 8, "yaw": 16}, "torso": {"pitch": 4, "yaw": -6},
                  "ra": {"raise": 34, "out": 10, "elbow": 72, "wrist": 20}, "la": {"raise": 40, "elbow": 40},
                  "lf": {"z": -1.3}, "rf": {"z": .1, "y": .14, "toe": -8}}), "pass")
    sh.key(20, at(-.7, {"lf": {"z": -1.3}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 4, "recover": 10}))


def counter_palm(arm):
    sh = Take(arm, N + "CounterPalm")
    sh.key(0, s({"root": {"y": -.36, "yaw": 32}, "ra": {"raise": -8, "out": 14, "elbow": 104, "wrist": 44}}), "ease")
    sh.key(2, s({"root": {"y": -.4, "z": -.12, "yaw": 18, "pitch": 5},
                 "ra": {"raise": 40, "out": 4, "twist": -26, "elbow": 66, "wrist": 52},
                 "la": {"raise": 44, "out": -10, "elbow": 56}, "lf": {"y": .07, "z": -.74}}), "pass")
    hit = s({"root": {"y": -.44, "z": -.34, "x": -.05, "pitch": 9, "yaw": 3}, "torso": {"pitch": 5, "yaw": -8},
             "ra": PALM_R, "la": {"raise": 34, "out": -16, "twist": 12, "elbow": 88, "wrist": 16},
             "lf": {"z": -.92, "y": 0}, "rf": heel(20, yaw=16)})
    sh.key(3, hit, "impact")
    sh.key(6, merge(hit, {"root": {"z": -.39, "pitch": 10}, "ra": {"raise": 89}}), "ease")
    sh.key(9, merge(hit, {"root": {"z": -.37}, "ra": {"raise": 88, "elbow": 6}}), "ease")
    sh.key(14, merge(hit, {"travel": {"z": -.18}, "root": {"y": -.38, "z": -.18, "pitch": 6, "yaw": 18},
                           "ra": {"raise": 30, "out": 12, "elbow": 74, "wrist": 16}, "la": {"raise": 48, "out": 0, "elbow": 42},
                           "rf": {"z": .44, "y": .1, "toe": -6, "yaw": 26}}), "pass")
    sh.key(20, at(-.36), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 3, "recover": 9}))


def feint_step(arm):
    sh = Take(arm, N + "FeintStep")
    sh.key(0, s(), "ease")
    # the fake: the left hand shoots, the eyes go with it
    sh.key(3, s({"root": {"y": -.34, "yaw": 34, "z": -.04}, "head": {"yaw": -24},
                 "la": {"raise": 86, "out": 6, "twist": -4, "elbow": 14, "wrist": -8}}), "launch")
    # the rear foot swings round to the flank
    sh.key(5, s({"travel": {"x": .2}, "root": {"y": -.4, "x": .2, "z": -.06, "yaw": 4}, "torso": {"yaw": -4},
                 "head": {"yaw": 4},
                 "la": {"raise": 60, "out": 4, "elbow": 60},
                 "ra": {"raise": 40, "out": -6, "twist": -20, "elbow": 66, "wrist": 30},
                 "rf": {"x": .85, "z": .16, "y": .2, "yaw": -6}}), "pass")
    hit = s({"travel": {"x": .3}, "root": {"y": -.44, "x": .34, "z": -.12, "pitch": 7, "yaw": -26},
             "torso": {"pitch": 4, "yaw": -8}, "head": {"yaw": 18},
             "ra": {"raise": 82, "out": -24, "twist": -32, "elbow": 8, "wrist": 34},
             "la": {"raise": 40, "out": 6, "elbow": 92},
             "rf": {"x": 1.05, "z": -.22, "y": 0, "yaw": -30}})
    sh.key(6, hit, "impact")
    sh.key(9, merge(hit, {"ra": {"raise": 86}, "root": {"z": -.15}}), "ease")
    sh.key(12, merge(hit, {"ra": {"raise": 84, "elbow": 10}}), "ease")
    # the left foot follows; he faces him again from the new side
    sh.key(16, merge(hit, {"travel": {"x": .5}, "root": {"x": .5, "yaw": 0, "y": -.36}, "torso": {"yaw": -8},
                           "ra": {"raise": 30, "out": 12, "elbow": 66, "wrist": 0}, "la": {"raise": 50, "elbow": 40},
                           "lf": {"x": .2, "z": -.5, "y": .12}}), "pass")
    sh.key(20, s({"travel": {"x": .55}, "root": {"x": .0}, "rf": {"x": RF["x"] + .55}, "lf": {"x": LF["x"] + .55}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 6, "recover": 12}))


# ===================================================================== air
def air1(arm):
    sh = Take(arm, N + "Air1")
    sh.key(0, air(), "ease")
    sh.key(5, air({"root": {"yaw": 30}, "torso": {"yaw": 6}, "head": {"yaw": -26},
                   "la": {"raise": 66, "out": -40, "twist": 10, "elbow": 118, "wrist": 30},
                   "ra": {"raise": 30, "out": 26, "elbow": 70}}), "ease")
    hit = air({"root": {"yaw": -24, "roll": 4}, "torso": {"yaw": -12}, "head": {"yaw": 4},
               "la": {"raise": 88, "out": 26, "twist": -10, "elbow": 4, "wrist": 56},
               "ra": {"raise": 6, "out": 30, "elbow": 84},
               "rf": {"y": 1.1, "z": -.2}, "lf": {"y": .95, "z": -.4}})
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"root": {"yaw": -28}, "la": {"raise": 90, "out": 30}}), "ease")
    sh.key(14, merge(hit, {"root": {"yaw": -26}, "la": {"raise": 86, "elbow": 10}}), "ease")
    sh.key(20, air(), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 8, "recover": 14}))


def air2(arm):
    sh = Take(arm, N + "Air2")
    sh.key(0, air(), "ease")
    sh.key(5, air({"root": {"yaw": 34, "pitch": 4}, "torso": {"yaw": 4}, "head": {"yaw": -30},
                   "la": {"raise": 60, "out": 20, "elbow": 70}, "ra": {"raise": 30, "out": 40, "elbow": 60},
                   "rf": {"x": .1, "y": 1.7, "z": -.5, "toe": -20, "yaw": 30}}), "ease")
    hit = air({"root": {"yaw": -30, "pitch": -6, "roll": -18}, "torso": {"yaw": -10, "roll": -8}, "head": {"yaw": 0, "roll": 10},
               "la": {"raise": 46, "out": 40, "elbow": 66}, "ra": {"raise": -10, "out": 50, "elbow": 30},
               "rf": {"x": -.3, "y": 2.3, "z": -1.55, "toe": -30, "yaw": -60}, "lf": {"y": .9, "z": .1}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"root": {"yaw": -36}, "rf": {"x": -.6, "z": -1.45}}), "ease")
    sh.key(15, merge(hit, {"root": {"yaw": -34}, "rf": {"x": -.5, "y": 2.1, "z": -1.3}}), "ease")
    sh.key(19, air({"root": {"yaw": -10}, "rf": {"x": .0, "y": 1.6, "z": -.5, "yaw": -10}}), "pass")
    sh.key(22, air(), "ease")
    sh.drag(["neck"], 1).drag(["hand.L", "hand.R"], 1)
    return sh.build(markers=ms({"contact": 9, "recover": 15}))


def air_drive(arm):
    sh = Take(arm, N + "AirDrive")
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": {"yaw": 40, "pitch": -4}, "torso": {"yaw": -10}, "head": {"yaw": -36},
                   "la": {"raise": 60, "out": 10, "elbow": 80}, "ra": {"raise": 20, "out": 30, "elbow": 80},
                   "rf": {"x": .1, "y": 1.75, "z": -.2, "toe": 0, "yaw": 60}}), "ease")
    hit = air({"root": {"yaw": 70, "pitch": -24, "roll": -6}, "torso": {"pitch": -6, "yaw": -24}, "head": {"yaw": -56, "pitch": 4},
               "la": {"raise": 40, "out": 30, "elbow": 70}, "ra": {"raise": -20, "out": 46, "elbow": 20},
               "rf": {"x": 0, "y": 1.7, "z": -2.15, "toe": 4, "yaw": 80}, "lf": {"y": .9, "z": .2, "toe": -30}})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"pitch": -26}, "rf": {"z": -2.2}}), "ease")
    sh.key(13, merge(hit, {"root": {"pitch": -22}, "rf": {"z": -2.1, "y": 1.65}}), "ease")
    sh.key(17, air({"root": {"yaw": 34}, "rf": {"y": 1.6, "z": -.4, "yaw": 40}}), "pass")
    sh.key(22, air(), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 7, "recover": 13}))


def air_flip(arm):
    sh = Take(arm, N + "AirFlip")
    T = {"tuck": 1}
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": dict(T, pitch=-40, y=-.4), "torso": {"pitch": 14}, "head": {"pitch": 10},
                   "la": {"raise": 60, "out": 20, "elbow": 100}, "ra": {"raise": 60, "out": 20, "elbow": 100},
                   "rf": {"y": 1.5, "z": -.6, "x": .1}, "lf": {"y": 1.6, "z": -.6}}), "pass")
    hit = air({"root": dict(T, pitch=-165, y=-.2), "torso": {"pitch": -6}, "head": {"pitch": 18},
               "la": {"raise": 20, "out": 60, "elbow": 20}, "ra": {"raise": 20, "out": 60, "elbow": 20},
               "rf": {"x": .1, "y": 3.9, "z": -1.0, "toe": 10, "yaw": 0}, "lf": {"y": 2.0, "z": .9, "toe": -20}})
    sh.key(10, hit, "impact")
    sh.key(13, merge(hit, {"root": dict(T, pitch=-200)}), "ease")
    sh.key(16, air({"root": dict(T, pitch=-270, y=-.4), "torso": {"pitch": 18},
                    "la": {"raise": 60, "out": 20, "elbow": 100}, "ra": {"raise": 60, "out": 20, "elbow": 100},
                    "rf": {"y": 1.5, "z": -.6, "x": .1}, "lf": {"y": 1.6, "z": -.6}}), "pass")
    sh.key(20, air({"root": dict(T, pitch=-335)}), "pass")
    sh.key(24, air({"root": dict(T, pitch=-360)}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 10, "recover": 16}))


def air_spike(arm):
    sh = Take(arm, N + "AirSpike")
    sh.key(0, air(), "ease")
    clasp = {"raise": 174, "out": -16, "twist": 0, "elbow": 34, "wrist": 10}
    sh.key(6, air({"root": {"pitch": -14, "y": -.36}, "torso": {"pitch": -16}, "head": {"pitch": -10},
                   "la": clasp, "ra": clasp, "rf": {"y": 1.3, "z": .05}, "lf": {"y": 1.4, "z": -.25}}), "ease")
    down = {"raise": 50, "out": -14, "twist": 0, "elbow": 4, "wrist": 14}
    hit = air({"root": {"pitch": 32}, "torso": {"pitch": 30}, "head": {"pitch": -36},
               "la": down, "ra": down, "rf": {"y": 1.2, "z": .7, "toe": -40}, "lf": {"y": 1.0, "z": .45, "toe": -40}})
    sh.key(9, hit, "impact")
    sh.key(12, merge(hit, {"root": {"pitch": 36}, "la": {"raise": 42}, "ra": {"raise": 42}}), "ease")
    sh.key(15, merge(hit, {"root": {"pitch": 33}, "la": {"raise": 46}, "ra": {"raise": 46}}), "ease")
    sh.key(24, air(), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 9, "recover": 15}))


def air_switch(arm):
    sh = Take(arm, N + "AirSwitch")
    sh.key(0, air(), "ease")
    sh.key(4, air({"root": {"yaw": -30, "roll": 6}, "torso": {"yaw": 6}, "head": {"yaw": 20},
                   "la": {"raise": 50, "out": 30, "elbow": 80}, "ra": {"raise": 40, "out": 20, "elbow": 90},
                   "lf": {"x": .3, "y": 1.6, "z": -.55, "toe": -20, "yaw": -40}}), "ease")
    hit = air({"root": {"yaw": 34, "roll": 20, "pitch": -4}, "torso": {"yaw": 8, "roll": 8}, "head": {"yaw": -30, "roll": -10},
               "la": {"raise": 20, "out": 60, "elbow": 30}, "ra": {"raise": 50, "out": 30, "elbow": 80},
               "lf": {"x": -1.4, "y": 2.1, "z": -1.1, "toe": -10, "yaw": 60}, "rf": {"y": .9, "z": .1}})
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"root": {"yaw": 40}, "lf": {"x": -1.5, "z": -.8}}), "ease")
    sh.key(13, merge(hit, {"root": {"yaw": 38}, "lf": {"x": -1.4, "z": -.7, "y": 2.0}}), "ease")
    sh.key(20, air(), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 8, "recover": 13}))


# ============================================================ grab, throw
HOLD = s({"root": {"y": -.42, "z": -.06, "yaw": 20, "pitch": 4}, "torso": {"pitch": 3, "yaw": -6}, "head": {"yaw": -10},
          "la": {"raise": 60, "out": -14, "twist": 10, "elbow": 80, "wrist": -10},
          "ra": {"raise": 50, "out": -12, "twist": 0, "elbow": 86, "wrist": -10},
          "lf": {"z": -.86}, "rf": {"z": .44}})


def grab(arm):
    sh = Take(arm, N + "Grab")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.38, "z": .06, "yaw": 32}, "head": {"yaw": -18},
                 "la": {"raise": 70, "out": 14, "elbow": 50}, "ra": {"raise": 20, "out": 10, "elbow": 90}}), "ease")
    sh.key(8, s({"root": {"y": -.42, "z": -.14, "yaw": 22, "pitch": 6},
                 "la": {"raise": 84, "out": -2, "elbow": 26, "wrist": -10}, "ra": {"raise": 50, "out": -6, "elbow": 66},
                 "lf": {"y": .08, "z": -.76}}), "pass")
    hit = s({"root": {"y": -.46, "z": -.32, "x": -.04, "pitch": 10, "yaw": 10}, "torso": {"pitch": 6, "yaw": -8},
             "head": {"yaw": -8},
             "la": {"raise": 88, "out": -10, "twist": 10, "elbow": 12, "wrist": -24},
             "ra": {"raise": 78, "out": -22, "twist": 10, "elbow": 28, "wrist": -20},
             "lf": {"z": -.9, "y": 0}, "rf": heel(16, yaw=20)})
    sh.key(11, hit, "impact")
    sh.key(15, merge(hit, {"la": {"elbow": 22}, "ra": {"elbow": 38}, "root": {"z": -.3}}), "ease")
    sh.key(19, merge(hit, {"la": {"elbow": 30}, "ra": {"elbow": 44}, "root": {"z": -.26}}), "ease")
    # the pull: the weight goes back, the hands come to his chest
    sh.key(28, merge(HOLD, {"root": {"z": .02, "y": -.46}, "rf": {"z": .62}}), "ease")
    sh.key(34, merge(HOLD, {"travel": {"z": -.18}, "root": {"z": -.12}, "rf": {"z": .44, "y": .12, "toe": -6}}), "pass")
    sh.key(40, merge(HOLD, {"travel": {"z": -.18}}), "ease")
    sh.key(50, merge(HOLD, {"travel": {"z": -.18}, "root": {"y": -.4}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers=ms({"contact": 11, "recover": 19}))


def throw_up(arm):
    sh = Take(arm, N + "ThrowUp")
    sh.key(0, merge(HOLD, {"root": {"y": -.4}}), "ease")
    dip = merge(HOLD, {"root": {"y": -.86, "z": .04, "pitch": 18, "yaw": 14}, "torso": {"pitch": 10},
                       "head": {"pitch": -14},
                       "la": {"raise": 34, "out": -10, "elbow": 70, "wrist": 30},
                       "ra": {"raise": 30, "out": -10, "elbow": 76, "wrist": 30}})
    sh.key(4, dip, "ease")
    hit = merge(HOLD, {"root": {"y": -.16, "z": -.12, "pitch": -10, "yaw": 8}, "torso": {"pitch": -12},
                       "head": {"pitch": -26},
                       "la": {"raise": 156, "out": -8, "twist": 0, "elbow": 14, "wrist": 50},
                       "ra": {"raise": 162, "out": -8, "twist": 0, "elbow": 12, "wrist": 50},
                       "rf": heel(34, z=.44)})
    sh.key(7, hit, "impact")
    sh.key(10, merge(hit, {"root": {"y": -.14}, "la": {"raise": 162}, "ra": {"raise": 168}}), "ease")
    sh.key(13, merge(hit, {"root": {"y": -.16}, "la": {"raise": 158, "elbow": 20}, "ra": {"raise": 164, "elbow": 18}}), "ease")
    sh.key(21, merge(HOLD, {"root": {"y": -.44, "pitch": 6}, "la": {"raise": 70, "out": 10, "elbow": 40},
                            "ra": {"raise": 40, "out": 16, "elbow": 60}, "rf": heel(6, z=.44)}), "pass")
    sh.key(31, at(-.18, {"lf": {"z": -.86}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.L"], 1)
    return sh.build(markers=ms({"contact": 7, "recover": 13}))


# ============================================================ defence
GUARD_DELTA = {"root": {"y": -.14, "z": .1, "pitch": -2}, "torso": {"pitch": 6, "yaw": 4}, "head": {"pitch": 14, "yaw": 6}}


def guard_pose():
    """Mirage.Guard as clips_react2 makes it (tempo .88, give 1.1): the
    forearms crossed before the face, the weight a little back."""
    g = s()
    for part, vals in GUARD_DELTA.items():
        g[part] = dict(g[part])
        for k, v in vals.items():
            g[part][k] = g[part].get(k, 0) + v
    return merge(g, {"ra": {"raise": 92, "out": -34, "twist": 42, "elbow": 114, "wrist": -10, "wroll": 0},
                     "la": {"raise": 96, "out": -30, "twist": 40, "elbow": 110, "wrist": -10, "wroll": 0}})


def guard_impact(arm):
    g = guard_pose()
    sh = Take(arm, N + "Guard.Impact")
    sh.key(0, g, "ease")

    def d(delta):
        out = merge(g, {})
        for part, vals in delta.items():
            out[part] = dict(out[part])
            for k, v in vals.items():
                out[part][k] = out[part].get(k, 0) + v
        return out
    hit = d({"root": {"y": -.22, "z": .3, "pitch": -6}, "torso": {"pitch": -8}, "head": {"pitch": 8},
             "ra": {"raise": -10, "elbow": 12}, "la": {"raise": -12, "elbow": 12}})
    hit = merge(hit, {"lf": {"toe": 14, "y": .04}})
    sh.key(2, hit, "impact")
    sh.key(5, d({"root": {"y": -.3, "z": .34, "pitch": -2}, "torso": {"pitch": -2}, "head": {"pitch": 4},
                 "ra": {"raise": -6, "elbow": 6}, "la": {"raise": -7, "elbow": 6}}), "ease")
    sh.key(10, d({"root": {"y": -.16, "z": .1}, "torso": {"pitch": 3}, "ra": {"raise": 3}, "la": {"raise": 3}}), "pass")
    sh.key(19, g, "ease")
    sh.drag(["neck"], 1).drag(["shoulder.L", "shoulder.R"], 1)
    return sh.build()


# ===================================================== jumps and landings
def flip(arm):
    sh = Take(arm, N + "Flip")
    sh.key(0, air({"root": {"y": -.2, "pitch": -4}, "torso": {"pitch": -6}, "head": {"pitch": -6},
                   "la": {"raise": 150, "out": 20, "elbow": 20}, "ra": {"raise": 150, "out": 20, "elbow": 20},
                   "rf": {"y": .5, "z": .1, "toe": -40}, "lf": {"y": .55, "z": -.05, "toe": -40}}), "ease")
    tuck = air({"root": {"y": -.5, "pitch": 30}, "torso": {"pitch": 34}, "head": {"pitch": 20},
                "la": {"raise": 80, "out": -6, "twist": 0, "elbow": 110, "wrist": 0},
                "ra": {"raise": 80, "out": -6, "twist": 0, "elbow": 110, "wrist": 0},
                "rf": {"x": .05, "y": 1.75, "z": -.75, "toe": -30, "yaw": 0},
                "lf": {"x": -.05, "y": 1.85, "z": -.7, "toe": -30, "yaw": 0}})
    sh.key(10, tuck, "ease")
    sh.key(24, merge(tuck, {"root": {"pitch": 34}, "rf": {"y": 1.85}, "lf": {"y": 1.9}}), "ease")
    sh.key(34, tuck, "ease")
    sh.key(42, air({"root": {"y": -.3, "pitch": 6}, "torso": {"pitch": 4}, "head": {"pitch": -14},
                    "la": {"raise": 70, "out": 34, "elbow": 40}, "ra": {"raise": 50, "out": 40, "elbow": 40},
                    "rf": {"y": .5, "z": .1, "toe": -16}, "lf": {"y": .55, "z": -.3, "toe": -16}}), "pass")
    sh.key(48, air({"root": {"y": -.4}, "rf": {"y": .55, "z": .1}, "lf": {"y": .6, "z": -.35},
                    "la": {"raise": 60, "out": 24}, "ra": {"raise": 30, "out": 30}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build()


def jump_air(arm):
    sh = Take(arm, N + "Jump.Air")
    # take-off: legs just extended off the floor, the arms rising
    sh.key(0, air({"root": {"y": -.08, "pitch": 2, "yaw": 10}, "torso": {"pitch": -2}, "head": {"pitch": -8},
                   "la": {"raise": 80, "out": 10, "elbow": 40}, "ra": {"raise": 40, "out": 18, "elbow": 50},
                   "rf": {"x": .2, "y": .25, "z": .3, "toe": -46, "yaw": 20}, "lf": {"x": -.1, "y": .2, "z": -.25, "toe": -40}}), "launch")
    # apex: knees drawn up, compact
    sh.key(8, air({"root": {"y": -.5, "pitch": 10, "yaw": 6}, "torso": {"pitch": 8}, "head": {"pitch": -14},
                   "la": {"raise": 52, "out": 6, "elbow": 66}, "ra": {"raise": 14, "out": 16, "elbow": 74},
                   "rf": {"x": .1, "y": 1.25, "z": -.25, "toe": -26}, "lf": {"x": -.1, "y": 1.4, "z": -.55, "toe": -24}}), "ease")
    # falling: the legs open down to the floor, the free hand out
    sh.key(16, air({"root": {"y": -.22, "pitch": 4, "yaw": 16}, "torso": {"pitch": 2}, "head": {"pitch": -18},
                    "la": {"raise": 58, "out": 26, "elbow": 36}, "ra": {"raise": 26, "out": 34, "elbow": 40},
                    "rf": {"x": .24, "y": .3, "z": .5, "toe": -24, "yaw": 26}, "lf": {"x": -.1, "y": .22, "z": -.5, "toe": -20}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.L", "hand.R"], 1)
    return sh.build()


def jump_leap(arm):
    sh = Take(arm, N + "Jump.Leap")
    # push-off: the rear leg extended behind, the lead knee driving up, the
    # left arm swung forward-up, the right back (opposition)
    sh.key(0, air({"root": {"y": -.12, "pitch": 18, "yaw": 0}, "torso": {"pitch": 8, "yaw": 0}, "head": {"pitch": -16, "yaw": 0},
                   "la": {"raise": -24, "out": 14, "elbow": 40}, "ra": {"raise": 90, "out": 10, "elbow": 70},
                   "lf": {"x": -.06, "y": 1.2, "z": -.85, "toe": -10, "yaw": 0},
                   "rf": {"x": .1, "y": .5, "z": 1.35, "toe": -50, "yaw": 0}}), "launch")
    # the hurdle at the apex: lead leg out in front, trailing leg folded
    sh.key(12, air({"root": {"y": -.36, "pitch": 14, "yaw": 0}, "torso": {"pitch": 8, "yaw": 0}, "head": {"pitch": -16, "yaw": 0},
                    "la": {"raise": 10, "out": 26, "elbow": 50}, "ra": {"raise": 70, "out": 16, "elbow": 80},
                    "lf": {"x": -.06, "y": 1.1, "z": -1.25, "toe": -6, "yaw": 0},
                    "rf": {"x": .12, "y": 1.35, "z": .55, "toe": -40, "yaw": 0}}), "ease")
    # reaching for the floor: the lead foot down in front, arms balancing
    sh.key(26, air({"root": {"y": -.3, "pitch": 6, "yaw": 0}, "torso": {"pitch": 2, "yaw": 0}, "head": {"pitch": -12, "yaw": 0},
                    "la": {"raise": 46, "out": 24, "elbow": 40}, "ra": {"raise": 30, "out": 30, "elbow": 50},
                    "lf": {"x": -.06, "y": .3, "z": -.95, "toe": -10, "yaw": 0},
                    "rf": {"x": .14, "y": .65, "z": .45, "toe": -30, "yaw": 6}}), "ease")
    sh.drag(["neck"], 1).drag(["hand.L", "hand.R"], 1)
    return sh.build()


def land(arm):
    sh = Take(arm, N + "Land")
    # touch: forefoot first, the legs still long
    sh.key(0, s({"root": {"y": -.2, "pitch": 4}, "head": {"pitch": -10},
                 "la": {"raise": 60, "out": 24, "elbow": 36}, "ra": {"raise": 28, "out": 30, "elbow": 40},
                 "rf": heel(24), "lf": heel(20)}), "impact")
    sh.key(3, s({"root": {"y": -.7, "pitch": 14}, "torso": {"pitch": 6}, "head": {"pitch": -12},
                 "la": {"raise": 64, "out": 20, "elbow": 30}, "ra": {"raise": 34, "out": 26, "elbow": 36}}), "pass")
    low = s({"root": {"y": -1.12, "z": .04, "pitch": 22, "yaw": 22}, "torso": {"pitch": 10, "yaw": -6}, "head": {"pitch": -24},
             "la": {"raise": 70, "out": 14, "twist": -6, "elbow": 26, "wrist": 10},
             "ra": {"raise": 44, "out": 22, "twist": -10, "elbow": 34, "wrist": 0}})
    sh.key(7, low, "ease")
    sh.key(11, merge(low, {"root": {"y": -1.08}}), "ease")
    sh.key(18, s({"root": {"y": -.5, "pitch": 8}, "torso": {"pitch": 4}, "la": {"raise": 56, "elbow": 36}}), "pass")
    sh.key(23, s({"root": {"y": -.25}}), "ease")
    sh.key(28, s(), "ease")
    sh.drag(["neck"], 1).drag(["hand.L", "hand.R"], 2)
    return sh.build()


# ===================================================== Phoenix Flower
SEAL = {"la": {"raise": 96, "out": -40, "twist": 30, "elbow": 128, "wrist": 10},
        "ra": {"raise": 96, "out": -40, "twist": 30, "elbow": 128, "wrist": 10}}


def phoenix(arm):
    out = []
    ch = Take(arm, N + "PhoenixFlower.Channel")
    ch.key(0, s(), "ease")
    ch.key(8, s(merge(SEAL, {"root": {"y": -.34, "yaw": 20}, "torso": {"pitch": -2}, "head": {"pitch": 0}})), "ease")
    ch.key(18, s(merge(SEAL, {"root": {"y": -.3, "z": .08, "yaw": 18}, "torso": {"pitch": -8}, "head": {"pitch": -12}})), "ease")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers=ms({"release": 18})))
    rel = Take(arm, N + "PhoenixFlower.Release")
    base = s(merge(SEAL, {"root": {"y": -.3, "z": .08, "yaw": 18}, "torso": {"pitch": -8}, "head": {"pitch": -12}}))
    rel.key(0, base, "ease")
    for i, (f, yaw) in enumerate(((3, -10), (9, 0), (15, 10))):
        rel.key(f, merge(base, {"root": {"z": -.04, "yaw": 18 + yaw * .4}, "torso": {"pitch": 6, "yaw": yaw * .5},
                                "head": {"pitch": 4, "yaw": yaw}}), "impact")
        if f + 3 <= 19:
            rel.key(f + 3, merge(base, {"root": {"yaw": 18 + yaw * .4}, "torso": {"pitch": -4, "yaw": yaw * .5},
                                        "head": {"pitch": -6, "yaw": yaw}}), "ease")
    rel.key(19, merge(base, {"head": {"yaw": 6}}), "ease")
    out.append(rel.build(markers=ms({"release": 3})))
    rc = Take(arm, N + "PhoenixFlower.Recover")
    rc.key(0, merge(base, {"head": {"yaw": 6}}), "ease")
    rc.key(8, s({"root": {"y": -.34}, "la": {"raise": 70, "out": -10, "elbow": 70}, "ra": {"raise": 30, "out": 0, "elbow": 90}}), "pass")
    rc.key(18, s(), "ease")
    rc.drag(["neck"], 1)
    out.append(rc.build())
    return out


# ================================================================ Luau rows
# (the clips the game plays now: read back for review, old vs new)
CURRENT = {
    "Air1": "AuthoredClips34", "Air2": "AuthoredClips34", "AirDrive": "AuthoredClips34", "AirFlip": "AuthoredClips34",
    "AirSpike": "AuthoredClips34", "AirSwitch": "AuthoredClips34", "CounterPalm": "AuthoredClips34",
    "DashAttack": "AuthoredClips34", "FeintStep": "AuthoredClips35", "Flip": "AuthoredClips35", "Grab": "AuthoredClips35",
    "Guard.Impact": "AuthoredClips35", "Heavy": "AuthoredClips36", "Jump.Air": "AuthoredClips37",
    "Jump.Leap": "AuthoredClips37", "Land": "AuthoredClips37", "Launcher": "AuthoredClips37", "Light1": "AuthoredClips37",
    "Light2": "AuthoredClips37", "Light3": "AuthoredClips37", "Light4": "AuthoredJutsu4",
    "PhoenixFlower.Channel": "AuthoredClips38", "PhoenixFlower.Recover": "AuthoredClips38",
    "PhoenixFlower.Release": "AuthoredClips38", "Slam": "AuthoredClips38", "Sweep": "AuthoredClips38",
    "ThrowUp": "AuthoredClips38",
}
ORDER = list(nd_ctrl.MOTORS.keys())
_cache = {}


def _luau_text(module):
    if module not in _cache:
        with open(os.path.join(CLIENT, module + ".luau")) as fh:
            _cache[module] = fh.read()
    return _cache[module]


def load_current(slot):
    """The clip the game plays now: {fps, frames, length, loop, markers, joints}."""
    name = N + slot
    text = _luau_text(CURRENT[slot])
    i = text.index('["%s"]=' % name)
    j = text.index("}},", i)
    block = text[i:j + 2]
    head = re.match(r'\["[^"]+"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(\w+),markers=\{([^}]*)\}', block)
    fps, frames, length, loop, marks = head.groups()
    markers = {}
    for kv in marks.split(","):
        if "=" in kv:
            k, v = kv.split("=")
            markers[k.strip()] = float(v)
    joints = {}
    for m in re.finditer(r"(\w+)=\{([-\d.,e]+)\}", block[block.index("joints={"):]):
        vals = [float(x) for x in m.group(2).split(",") if x]
        w = 7 if m.group(1) == "Root" else 4
        joints[m.group(1)] = [vals[k:k + w] for k in range(0, len(vals), w)]
    return {"fps": int(fps), "frames": int(frames), "length": float(length), "loop": loop == "true",
            "markers": markers, "joints": joints}


def row_T(row):
    """A Motor6D row -> 4x4 transform (Roblox axes)."""
    if len(row) == 7:
        x, y, z, qx, qy, qz, qw = row
    else:
        x = y = z = 0.0
        qx, qy, qz, qw = row
    m = Quaternion((qw, qx, qy, qz)).normalized().to_matrix().to_4x4()
    m.translation = Vector((x, y, z))
    return m


# ------------------------------------------- Motor6D rows -> control rig
# (no such path in the framework: nd_mocap bakes onto the deform rig of
# nd_rig, job_moves_v2 exports from the control rig; this replays rows -
# a game clip or a capture track - onto nd_ctrl's bones, legs through
# foot_ik + knee_pole; round trip within ~5 deg at the knees, the rig's own
# 0.05 knee offset)
CARRIED = {"cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head"}
for _s, _n in (("R", "Right"), ("L", "Left")):
    CARRIED["shoulder." + _s] = _n + "UpperArm"
    CARRIED["forearm." + _s] = _n + "LowerArm"
    CARRIED["hand." + _s] = _n + "Hand"
    CARRIED["thigh." + _s] = _n + "UpperLeg"
    CARRIED["shin." + _s] = _n + "LowerLeg"
    CARRIED["foot." + _s] = _n + "Foot"
HRP0 = []


def _from_roblox(F):
    out = Matrix.Identity(4)
    out.translation = nd_rig.B @ F.translation
    rot = nd_rig.B @ F.to_3x3()
    for i in range(3):
        for j in range(3):
            out[i][j] = rot[i][j]
    return out


def part_world(T):
    """Motor6D transforms {joint: 4x4} -> part CFrames (Roblox world)."""
    if not HRP0:
        HRP0.append(nd_ctrl._to_roblox(nd_ctrl.part_rest("HRP")))
    F = {"HRP": HRP0[0]}
    for joint in ORDER:
        p0, p1 = nd_ctrl.MOTORS[joint]
        pivot = Vector(nd_rig.JOINTS[joint][0])
        c0 = Matrix.Translation(pivot - nd_ctrl.CENTRE[p0])
        c1 = Matrix.Translation(pivot - nd_ctrl.CENTRE[p1])
        F[p1] = F[p0] @ c0 @ T[joint] @ c1.inverted()
    return F


def bone_targets(arm, F):
    out = {}
    for s_, n in (("R", "Right"), ("L", "Left")):
        out["fwd." + s_] = (nd_rig.B @ (F[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1)) +
                                        F[n + "LowerLeg"].to_3x3() @ Vector((0, 0, -1)))).normalized()
    for bone, part in CARRIED.items():
        out[bone] = _from_roblox(F[part]) @ nd_ctrl.part_rest(part).inverted() @ arm.data.bones[bone].matrix_local
    return out


def basis_from(arm, M):
    bones = arm.data.bones
    out = {"root": (Quaternion(), Vector())}
    M = dict(M)
    M["root"] = bones["root"].matrix_local.copy()
    for b in ("cog", "spine", "neck", "shoulder.R", "forearm.R", "hand.R", "shoulder.L", "forearm.L", "hand.L"):
        par = bones[b].parent.name
        rel = bones[par].matrix_local.inverted() @ bones[b].matrix_local
        basis = (M[par] @ rel).inverted() @ M[b]
        out[b] = (basis.to_quaternion().normalized(), basis.translation.copy() if b == "cog" else None)
    for s_ in ("R", "L"):
        ik = bones["foot_ik." + s_]
        basis = ik.matrix_local.inverted() @ M["foot." + s_]
        out["foot_ik." + s_] = (basis.to_quaternion().normalized(), basis.translation.copy())
        hip, ankle = M["thigh." + s_].translation, M["foot." + s_].translation
        d = M["fwd." + s_].copy()
        leg = ankle - hip
        if leg.length > 1e-4:
            u = leg.normalized()
            e = d - u * d.dot(u)
            d = e.normalized() if e.length > 1e-4 else d
        pole_world = (hip + ankle) * .5 + d * 3.0
        pole = bones["knee_pole." + s_]
        out["knee_pole." + s_] = (None, pole.matrix_local.to_3x3().transposed() @ (pole_world - pole.head_local))
    return out


def bake_frames(arm, name, frames_T, step, markers=None, meta=None, loop=False):
    """[{joint: 4x4}] per sample (every `step` frames at 60 fps) -> a control-rig action."""
    act = nd_anim.new_action(arm, name)
    last_q = {}
    for i, T in enumerate(frames_T):
        for bone, (q, loc) in basis_from(arm, bone_targets(arm, part_world(T))).items():
            pb = arm.pose.bones[bone]
            if q is not None:
                prev = last_q.get(bone)
                if prev is not None and prev.dot(q) < 0:
                    q = -q
                last_q[bone] = q
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=i * step, group=bone)
            if loc is not None:
                pb.location = loc
                pb.keyframe_insert("location", frame=i * step, group=bone)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = dict(markers or {})
    act["nd_loop"] = bool(loop)
    act["nd_meta"] = dict(meta or {})
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, (len(frames_T) - 1) * step)
    return act


def port(arm, slot, name=None):
    """The clip the game plays now, unchanged, on the control rig."""
    clip = load_current(slot)
    frames = [{j: row_T(clip["joints"][j][i]) for j in ORDER} for i in range(clip["frames"])]
    return bake_frames(arm, name or N + slot, frames, FPS // clip["fps"], clip["markers"], {"source": "v1"}, clip["loop"])


# ================================================================== author
SLOTS = ["Light1", "Light2", "Light4", "Light3", "Heavy", "Launcher", "Slam", "Sweep", "DashAttack",
         "CounterPalm", "FeintStep", "Air1", "Air2", "AirDrive", "AirFlip", "AirSpike", "AirSwitch",
         "Grab", "ThrowUp", "Guard.Impact", "Flip", "Jump.Leap", "Jump.Air", "Land",
         "PhoenixFlower.Channel", "PhoenixFlower.Release", "PhoenixFlower.Recover"]
AUTHORED = {"Light1": light1, "Light2": light2, "Light4": light4, "Light3": light3, "Heavy": heavy,
            "Launcher": launcher, "Slam": slam, "Sweep": sweep, "DashAttack": dash_attack,
            "CounterPalm": counter_palm, "FeintStep": feint_step, "Air1": air1, "Air2": air2,
            "AirDrive": air_drive, "AirFlip": air_flip, "AirSpike": air_spike, "AirSwitch": air_switch,
            "Grab": grab, "ThrowUp": throw_up, "Guard.Impact": guard_impact, "Flip": flip,
            "Jump.Leap": jump_leap, "Jump.Air": jump_air, "Land": land}
KEEP = set()   # slots shipped as the game plays them now (port)


def author(arm):
    only = [x for x in os.environ.get("ND_CLIPS", "").split(",") if x]
    acts = []
    done_phoenix = False
    for slot in SLOTS:
        if only and slot not in only and N + slot not in only:
            continue
        if slot in KEEP:
            acts.append(port(arm, slot))
        elif slot.startswith("PhoenixFlower"):
            if not done_phoenix:
                acts += phoenix(arm)
                done_phoenix = True
        else:
            acts.append(AUTHORED[slot](arm))
    if only:
        acts = [a for a in acts if a.name in only or a.name[len(N):] in only]
    return acts


def old(arm):
    """The current clips, as the game plays them (review: old vs new)."""
    only = [x for x in os.environ.get("ND_CLIPS", "").split(",") if x]
    return [port(arm, slot) for slot in SLOTS if not only or slot in only]
