"""Naruto's seal jutsu, his string's middle hits and his awakening (04/11,
user: the new jutsu had no animations of their own, « fais-moi de belles
animations, applique-toi bien »; the awakening was « un peu léger »).

Authored on his body (naruto_p5.STANCE: low, wide, fists a little low, the
shoulders forward, left foot ahead). His bible: an impulsive, expressive body
(more than Minato's), real feet, the clones carry the blows from real places.
Every jutsu opens with its two seals (nd_seals), snapped, the knees dropping
on each; then the act:

  CloneAmbush        tiger - snake, the cross seal (Kage Bunshin), then two
                     fingers stabbed at the floor in front: the clone dives
                     under it; his eyes run along the floor to the target,
                     the hand following, and a fist pump as it bursts out
                     (the way he beat Neji)
  HiddenFuma         snake - ram, the right hand reaches over his shoulder for
                     the folded Fuma, the hips coil far round, the left hand
                     aims; the throw unwinds hips -> chest -> arm (each one
                     later than the last) and the arm wraps across, the back
                     foot torn off the floor; he rocks back into his stance
  SummonGamakichi    ram - rat, the thumb bitten, the open palm thrown high
                     (up on his toes), slammed flat on the floor in a deep
                     crouch; the smoke puff pushes him back up, grinning
  CloneThrow         rat - tiger, then down into a sprinter's crouch, arms
                     swept back for the clone behind him: the flight is his
                     running heavy (Legion.HeadDive, gaps_e6), whose first
                     pose this crouch leads into
  Light4             a wild left haymaker over the top: the fist cocked by
                     the ear on a hop, the whole body falling in behind it,
                     the rear foot dragged after - L1 is a compact right hook
  Light5             the clinch knee: both hands grab the head and yank it
                     down onto a rising right knee, then shove off
  Awaken             the Nine-Tails: the seal burns (he folds over, hands on
                     his stomach, shaking), the chakra bursts (thrown back,
                     arms flung open, the roar to the sky), then thrown
                     forward onto his claws, low, feral

Server timings (Shared/SealJutsu.Legion, Shared/Attacks with his profile):
  CloneAmbush  channel .2  act .06 rec .24     HiddenFuma  .26 / .06 / .28
  SummonGamakichi .34 / .08 / .3               CloneThrow channel .12
  Light4 (Light1 profile) .085 / .12 / .27     Light5 (Light2) .096 / .12 / .254
  Awaken: the same 46 frames (0.767 s) as the clip it replaces, no markers.
"""
from nd_shot import Shot, merge
from naruto_p5 import STANCE, CROSS, s, at
import nd_seals

N = "Legion."
F = 60.0
# The seal base: he squares up a little to the front, chin down on the hands.
SEAL_BASE = {"root": {"y": -.5, "pitch": 8, "yaw": 10}, "torso": {"pitch": 6, "yaw": -4}, "head": {"pitch": 0, "yaw": -6}}
FIST_GUARD = {"la": dict(STANCE["la"]), "ra": dict(STANCE["ra"])}


def seals(shot, signs, beat, over=None):
    base = s(merge(SEAL_BASE, over or {}))
    return nd_seals.weave(shot, 0, signs, base, beat=beat, sink=.07)


# ================================================================ CloneAmbush
def clone_ambush(arm):
    out = []
    ch = Shot(arm, N + "CloneAmbush.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (1, 2), 4)                                   # 4, 8
    # the hands come apart a little (the chakra kneaded) ...
    ch.key(last + 2, s(merge(SEAL_BASE, {"root": {"y": -.6}, "head": {"pitch": -4},
                                         "ra": {"raise": 72, "out": -14, "twist": 30, "elbow": 104, "wrist": 0},
                                         "la": {"raise": 70, "out": -16, "twist": 30, "elbow": 106, "wrist": 0}})), "pass")
    # ... and snap into the cross seal, the knees dropping with it
    cross = s(merge(CROSS, {"root": {"y": -.7, "pitch": 10, "yaw": 6}, "torso": {"pitch": 8, "yaw": 0},
                            "head": {"pitch": -8, "yaw": -4}}))
    ch.key(last + 5, cross, "impact")                             # 13
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 5) / F}))

    re = Shot(arm, N + "CloneAmbush.Release")
    re.key(0, cross, "ease")
    # the right hand leaves the seal, up by the ear ...
    re.key(2, merge(cross, {"root": {"y": -.64, "pitch": 4}, "torso": {"pitch": 2},
                            "ra": {"raise": 128, "out": 16, "twist": 10, "elbow": 96, "wrist": 0}}), "ease")
    # ... and two fingers are stabbed at the floor a stud in front: GO
    stab = s({"root": {"y": -.84, "z": -.12, "pitch": 22, "yaw": -6}, "torso": {"pitch": 14, "yaw": -16},
              "head": {"pitch": 18, "yaw": 10},
              "ra": {"raise": 82, "out": 14, "twist": 6, "elbow": 4, "wrist": 22},
              "la": {"raise": 52, "out": -20, "twist": 36, "elbow": 124, "wrist": 0}})
    re.key(5, stab, "impact")
    stab2 = merge(stab, {"root": {"y": -.88}, "ra": {"raise": 78}, "head": {"pitch": 8}})
    re.key(10, stab2, "ease")
    re.drag(["neck"], 1)
    re.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(re.build(markers={"release": 5 / F}))

    rc = Shot(arm, N + "CloneAmbush.Recover")
    rc.key(0, stab2, "ease")
    # his eyes run along the floor to the target, the hand following the line
    look = s({"root": {"y": -.7, "z": -.06, "pitch": 18, "yaw": 6}, "torso": {"pitch": 12, "yaw": -2},
              "head": {"pitch": -14, "yaw": -6},
              "ra": {"raise": 96, "out": 4, "twist": 0, "elbow": 14, "wrist": 0},
              "la": {"raise": 44, "out": 6, "twist": 20, "elbow": 110}})
    rc.key(6, look, "pass")
    # it bursts out under him: the fist pulled back, "yosh!"
    pump = s({"root": {"y": -.5, "z": .02, "pitch": 8, "yaw": 14}, "torso": {"pitch": 2, "yaw": -6},
              "head": {"pitch": -14, "yaw": -10},
              "ra": {"raise": 34, "out": 40, "twist": 30, "elbow": 140, "wrist": 0},
              "la": {"raise": 46, "out": 10, "twist": 20, "elbow": 98}})
    rc.key(10, pump, "impact")
    rc.key(15, s(), "ease")
    rc.key(17, s(), "ease")
    rc.drag(["neck"], 1)
    rc.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(rc.build())
    return out


# ================================================================ HiddenFuma
def hidden_fuma(arm):
    out = []
    ch = Shot(arm, N + "HiddenFuma.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (2, 3), 4)                                   # 4, 8
    # the right hand reaches over the shoulder for the folded Fuma
    reach = s({"root": {"y": -.5, "pitch": 6, "yaw": 26}, "torso": {"pitch": 0, "yaw": 16},
               "head": {"pitch": -6, "yaw": -30},
               "ra": {"raise": 156, "out": 34, "twist": -10, "elbow": 128, "wrist": 0},
               "la": {"raise": 62, "out": -10, "twist": 20, "elbow": 70, "wrist": 0}})
    ch.key(last + 3, reach, "pass")                               # 11
    # coiled: hips and chest wound far round, the blade held out behind him,
    # the weight on the back leg, the left hand aiming at him
    coil = s({"root": {"y": -.64, "z": .14, "pitch": 2, "yaw": 50, "roll": -3}, "torso": {"pitch": -2, "yaw": 34, "roll": -4},
              "head": {"pitch": -8, "yaw": -66},
              "ra": {"raise": 14, "out": 84, "twist": 10, "elbow": 26, "wrist": -10},
              "la": {"raise": 82, "out": -62, "twist": 0, "elbow": 14, "wrist": 0},
              "lf": {"toe": 8}})
    ch.key(last + 8, coil, "ease")                                # 16
    ch.drag(["neck"], 1)
    ch.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 8) / F}))

    re = Shot(arm, N + "HiddenFuma.Release")
    re.key(0, coil, "ease")
    # the hips unwind first, the chest after, the arm trails (the whip)
    re.key(2, merge(coil, {"root": {"z": .04, "pitch": 8, "yaw": 22, "roll": 0}, "torso": {"pitch": 2, "yaw": 34, "roll": 0},
                           "head": {"yaw": -48},
                           "ra": {"raise": 24, "out": 96, "elbow": 40},
                           "la": {"raise": 60, "out": -20, "elbow": 40}, "lf": {"toe": 0}}), "pass")
    rel = s({"root": {"y": -.6, "z": -.22, "pitch": 18, "yaw": -6}, "torso": {"pitch": 12, "yaw": -16},
             "head": {"pitch": -16, "yaw": 16},
             "ra": {"raise": 114, "out": 12, "twist": 0, "elbow": 6, "wrist": -16},
             "la": {"raise": 10, "out": 34, "twist": 0, "elbow": 40},
             "rf": {"toe": -26}})
    re.key(4, rel, "impact")
    # follow-through: the arm wraps across, the back foot torn off the floor
    follow = s({"root": {"y": -.58, "z": -.3, "pitch": 26, "yaw": -32, "roll": 4}, "torso": {"pitch": 16, "yaw": -40},
                "head": {"pitch": -14, "yaw": 34},
                "ra": {"raise": 84, "out": -62, "twist": 10, "elbow": 42, "wrist": 0},
                "la": {"raise": -14, "out": 40, "twist": -10, "elbow": 36},
                "rf": {"x": .26, "z": .34, "y": .34, "toe": -34, "yaw": 10}})
    re.key(10, follow, "ease")
    re.drag(["neck"], 1)
    re.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(re.build(markers={"release": 4 / F}))

    rc = Shot(arm, N + "HiddenFuma.Recover")
    rc.key(0, follow, "ease")
    # the back foot comes down, he rocks back over it into his stance
    rc.key(6, s({"root": {"y": -.6, "z": -.12, "pitch": 16, "yaw": -6}, "torso": {"pitch": 12, "yaw": -22},
                 "head": {"pitch": -14, "yaw": 14},
                 "ra": {"raise": 46, "out": -14, "twist": 20, "elbow": 80},
                 "la": {"raise": 20, "out": 24, "twist": 10, "elbow": 80},
                 "rf": {"x": .32, "z": .66, "y": 0, "toe": 0, "yaw": 30}}), "impact")
    rc.key(12, s({"root": {"y": -.52, "z": -.02}, "torso": {"yaw": -10}}), "ease")
    rc.key(17, s(), "ease")
    rc.drag(["neck"], 1)
    rc.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(rc.build())
    return out


# =========================================================== SummonGamakichi
def summon(arm):
    out = []
    ch = Shot(arm, N + "SummonGamakichi.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (3, 4), 5)                                   # 5, 10
    # the thumb bitten: the hand to the mouth, the head ducking into it
    bite = s({"root": {"y": -.56, "pitch": 10, "yaw": 16}, "torso": {"pitch": 10, "yaw": -6},
              "head": {"pitch": 16, "yaw": 8, "roll": -6},
              "ra": {"raise": 104, "out": -18, "twist": 34, "elbow": 150, "wrist": 10},
              "la": {"raise": 24, "out": 20, "twist": 10, "elbow": 70}})
    ch.key(last + 4, bite, "ease")                                # 14
    # torn away, and the open palm thrown high: up on his toes
    high = s({"root": {"y": -.22, "z": .06, "pitch": -4, "yaw": 10}, "torso": {"pitch": -10, "yaw": -4},
              "head": {"pitch": -18, "yaw": -8},
              "ra": {"raise": 168, "out": 18, "twist": 0, "elbow": 20, "wrist": -20},
              "la": {"raise": 30, "out": 30, "twist": 0, "elbow": 40},
              "rf": {"toe": -22}, "lf": {"toe": -14}})
    ch.key(last + 10, high, "ease")                               # 20
    ch.drag(["neck"], 1)
    ch.drag(["shoulder.L", "forearm.L", "hand.L"], 2)
    out.append(ch.build(markers={"release": (last + 10) / F}))

    re = Shot(arm, N + "SummonGamakichi.Release")
    re.key(0, high, "ease")
    # KUCHIYOSE: the palm comes down through a big arc, flat on the floor in
    # front of the lead foot, the body dropped into a deep crouch behind it
    re.key(2, s({"root": {"y": -.7, "z": -.04, "pitch": 18, "yaw": 8}, "torso": {"pitch": 10, "yaw": -4},
                 "head": {"pitch": -10, "yaw": -6},
                 "ra": {"raise": 118, "out": 10, "twist": 0, "elbow": 14, "wrist": -30},
                 "la": {"raise": 10, "out": 40, "twist": 0, "elbow": 40},
                 "rf": {"toe": -10}, "lf": {"toe": 0}}), "pass")
    slam = s({"root": {"y": -1.3, "z": -.26, "pitch": 28, "yaw": 6}, "torso": {"pitch": 18, "yaw": -4},
              "head": {"pitch": -34, "yaw": -6},
              "ra": {"raise": 66, "out": 6, "twist": 4, "elbow": 6, "wrist": -70},
              "la": {"raise": 14, "out": 54, "twist": -10, "elbow": 40},
              "rf": {"toe": -40}, "lf": {"toe": 0}})
    re.key(4, slam, "impact")
    # the shoulders give with the slap, then press
    re.key(7, merge(slam, {"root": {"y": -1.36}, "torso": {"pitch": 22}, "ra": {"raise": 70, "elbow": 16}}), "ease")
    held = merge(slam, {"root": {"y": -1.34}, "torso": {"pitch": 20}, "ra": {"raise": 68, "elbow": 12}})
    re.key(11, held, "ease")
    re.drag(["neck"], 1)
    re.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(re.build(markers={"release": 4 / F}))

    rc = Shot(arm, N + "SummonGamakichi.Recover")
    rc.key(0, held, "ease")
    # the smoke bursts in front of him: pushed back up, the head comes up
    rc.key(5, s({"root": {"y": -1.0, "z": .1, "pitch": 14, "yaw": 10}, "torso": {"pitch": 2, "yaw": -6},
                 "head": {"pitch": -22, "yaw": -10},
                 "ra": {"raise": 62, "out": 16, "twist": 10, "elbow": 40, "wrist": -10},
                 "la": {"raise": 10, "out": 36, "twist": 0, "elbow": 60},
                 "rf": {"toe": -12}}), "pass")
    rc.key(11, s({"root": {"y": -.56, "z": .02, "pitch": 6}, "torso": {"pitch": 4},
                  "head": {"pitch": -14},
                  "ra": {"raise": 34, "out": 18, "twist": 26, "elbow": 100}, "rf": {"toe": 0}}), "pass")
    rc.key(18, s(), "ease")
    rc.key(20, s(), "ease")
    rc.drag(["neck"], 2)
    rc.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    out.append(rc.build())
    return out


# ================================================================ CloneThrow
def clone_throw(arm):
    ch = Shot(arm, N + "CloneThrow.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (4, 1), 3)                                   # 3, 6
    # a sprinter's crouch, arms swept back for the clone behind him; the head
    # up on the target (Legion.HeadDive's first pose continues it)
    crouch = s({"root": {"y": -1.02, "z": .04, "pitch": 34, "yaw": 0}, "torso": {"pitch": 20, "yaw": 0},
                "head": {"pitch": -30, "yaw": 0},
                "ra": {"raise": -38, "out": 20, "twist": 0, "elbow": 30, "wrist": 0},
                "la": {"raise": -38, "out": 20, "twist": 0, "elbow": 30, "wrist": 0},
                "rf": {"toe": -26}, "lf": {"toe": -6}})
    ch.key(last + 3, merge(crouch, {"root": {"y": -.86, "pitch": 24}, "ra": {"raise": 0, "out": 24}, "la": {"raise": 0, "out": 24}}), "pass")
    ch.key(last + 6, crouch, "ease")                              # 12
    ch.drag(["neck"], 1)
    return ch.build(markers={"release": (last + 6) / F})


# ================================================================ string
def light4(arm):
    """L4, the wild left over the top (head): after the body straight, the
    left fist cocked high by his ear on a little hop, then the whole body
    falls in behind a looping overhand that lands from above; it overshoots
    down across him and the rear foot is dragged after. L1/L2 are a compact
    right hook and a left straight: this one is all commitment."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    cock = s({"root": {"y": -.5, "z": .04, "pitch": 4, "yaw": 2}, "torso": {"pitch": 0, "yaw": -26},
              "head": {"pitch": -12, "yaw": 0},
              "la": {"raise": 132, "out": 58, "twist": -24, "elbow": 112, "wrist": 0},
              "ra": {"raise": 44, "out": 6, "twist": 30, "elbow": 112},
              "lf": {"y": .14, "z": -.8, "toe": -8}})
    sh.key(3, cock, "ease")
    hit = s({"travel": {"z": -.45}, "root": {"y": -.6, "z": -.22, "pitch": 24, "yaw": 36, "roll": 5},
             "torso": {"pitch": 18, "yaw": 22}, "head": {"pitch": -4, "yaw": -28},
             "la": {"raise": 118, "out": -16, "twist": 6, "elbow": 30, "wrist": 0},
             "ra": {"raise": 52, "out": 8, "twist": 30, "elbow": 118},
             "lf": {"y": 0, "z": -1.12, "toe": 0}, "rf": {"toe": -18}})
    sh.key(5, hit, "impact")
    sh.key(9, merge(hit, {"root": {"y": -.66, "pitch": 30, "yaw": 44}, "torso": {"pitch": 22, "yaw": 30},
                          "head": {"pitch": 4},
                          "la": {"raise": 66, "out": -40, "elbow": 50}}), "ease")
    # the rear foot skips up behind him, the fists come back up
    sh.key(16, s({"travel": {"z": -.45}, "root": {"x": -.12, "y": -.56, "z": -.36, "pitch": 18, "yaw": 26}, "torso": {"pitch": 12, "yaw": 2},
                  "head": {"pitch": -8, "yaw": -18},
                  "la": {"raise": 40, "out": 6, "twist": 20, "elbow": 90},
                  "lf": {"z": -1.12}, "rf": {"z": .46, "y": .14, "toe": -14}}), "pass")
    sh.key(28, at(-.45, {"lf": {"z": -1.11}}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    return sh.build(markers={"contact": 5 / F, "recover": 12 / F})


def light5(arm):
    """L5, the clinch knee (body): both hands shoot out and hook behind the
    head, yank it down onto the right knee driving up, then a shove off to
    make room for the last blow."""
    sh = Shot(arm, N + "Light5")
    sh.key(0, s(), "ease")
    hook = {"raise": 102, "out": -4, "twist": 10, "elbow": 40, "wrist": 34}
    grab = s({"travel": {"z": -.24}, "root": {"x": -.2, "y": -.42, "z": -.12, "pitch": 10, "yaw": 10}, "torso": {"pitch": 6, "yaw": -6},
              "head": {"pitch": -12, "yaw": -8},
              "la": hook, "ra": merge(hook, {"out": -2}),
              "rf": {"toe": -18}})
    sh.key(3, grab, "ease")
    knee = s({"travel": {"z": -.24}, "root": {"x": -.36, "y": -.34, "z": -.28, "pitch": -4, "yaw": 2, "roll": -4}, "torso": {"pitch": 22, "yaw": 0},
              "head": {"pitch": 6, "yaw": -2},
              "la": merge(hook, {"raise": 64, "elbow": 74, "wrist": 44}), "ra": merge(hook, {"raise": 62, "elbow": 76, "wrist": 44}),
              "rf": {"x": .02, "y": 1.06, "z": -.1, "toe": 40, "yaw": 0}})
    sh.key(6, knee, "impact")
    sh.key(10, merge(knee, {"root": {"y": -.32}, "torso": {"pitch": 24}, "rf": {"y": 1.16, "z": -.16}}), "ease")
    # the foot comes back down behind, the hands shove him off
    sh.key(16, s({"travel": {"z": -.24}, "root": {"x": -.14, "y": -.52, "z": -.02, "pitch": 14, "yaw": 14}, "torso": {"pitch": 8, "yaw": -6},
                  "head": {"pitch": -10, "yaw": -10},
                  "la": {"raise": 80, "out": -4, "twist": 0, "elbow": 22, "wrist": 30},
                  "ra": {"raise": 74, "out": 0, "twist": 0, "elbow": 30, "wrist": 30},
                  "rf": {"x": .3, "y": .12, "z": .5, "toe": -10, "yaw": 26}}), "pass")
    sh.key(28, s({"travel": {"z": -.24}, "root": {"z": -.04}, "rf": {"z": .52}, "lf": {"z": -.66}}), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 6 / F, "recover": 13 / F})


# ================================================================ awakening
def awaken(arm):
    """The Nine-Tails chakra (46 frames, as the clip it replaces): the seal
    on his stomach burns - he folds over it, both hands clutching it, shaking;
    the chakra bursts out of him and throws him back (arms flung open behind,
    the roar to the sky); then it throws him forward, down onto his claws,
    low, the eyes up on the opponent: the feral crouch he fights from."""
    sh = Shot(arm, N + "Awaken")
    sh.key(0, s(), "ease")
    clutch = {"root": {"y": -.84, "z": .06, "pitch": 30, "yaw": 8}, "torso": {"pitch": 32, "yaw": -2, "roll": 4},
              "head": {"pitch": 26, "yaw": -4},
              "ra": {"raise": 24, "out": -26, "twist": 34, "elbow": 104, "wrist": 30},
              "la": {"raise": 30, "out": -28, "twist": 34, "elbow": 98, "wrist": 30}}
    sh.key(6, s(clutch), "ease")
    sh.key(9, s(merge(clutch, {"root": {"roll": -3}, "torso": {"roll": -5}, "head": {"roll": 6}})), "pass")
    # gathering: the deepest fold, everything pulled in
    sh.key(13, s(merge(clutch, {"root": {"y": -1.0, "pitch": 36}, "torso": {"pitch": 40, "roll": 2}, "head": {"pitch": 34, "roll": -2},
                                "ra": {"elbow": 112}, "la": {"elbow": 108}})), "ease")
    # BURST: thrown back, arms flung open behind him, the roar to the sky
    back = s({"root": {"y": -.5, "z": .16, "pitch": -14, "yaw": 0, "roll": 0}, "torso": {"pitch": -28, "yaw": 0, "roll": 0},
              "head": {"pitch": -38, "yaw": 0, "roll": 0},
              "ra": {"raise": -8, "out": 78, "twist": -30, "elbow": 26, "wrist": -34},
              "la": {"raise": -8, "out": 78, "twist": -30, "elbow": 26, "wrist": -34},
              "rf": {"toe": 0}, "lf": {"toe": 10}})
    sh.key(18, back, "impact")
    sh.key(23, merge(back, {"root": {"y": -.46, "z": .18}, "torso": {"pitch": -32}, "head": {"pitch": -44},
                            "ra": {"raise": -16, "out": 88}, "la": {"raise": -16, "out": 88}}), "ease")
    sh.key(26, merge(back, {"root": {"y": -.5, "roll": 3}, "torso": {"pitch": -30, "roll": -4}, "head": {"pitch": -42, "roll": 4},
                            "ra": {"raise": -14, "out": 86}, "la": {"raise": -12, "out": 84}}), "pass")
    # the claws drawn up by the shoulders as the chakra pitches him forward ...
    sh.key(30, s({"root": {"y": -.72, "z": .04, "pitch": 14}, "torso": {"pitch": 0},
                  "head": {"pitch": -24},
                  "ra": {"raise": 84, "out": 46, "twist": -10, "elbow": 96, "wrist": 30},
                  "la": {"raise": 84, "out": 46, "twist": -10, "elbow": 96, "wrist": 30},
                  "rf": {"toe": -10}, "lf": {"toe": 0}}), "pass")
    # ... and down onto them: low, the hands on the floor, the eyes up
    down = s({"root": {"y": -1.26, "z": -.3, "pitch": 40, "yaw": 4}, "torso": {"pitch": 18, "yaw": -2},
              "head": {"pitch": -58, "yaw": -6},
              "ra": {"raise": 78, "out": 24, "twist": 0, "elbow": 20, "wrist": 52},
              "la": {"raise": 82, "out": 22, "twist": 0, "elbow": 18, "wrist": 52},
              "rf": {"toe": -34}, "lf": {"toe": -4}})
    sh.key(35, down, "impact")
    sh.key(39, merge(down, {"root": {"y": -1.2, "pitch": 37}, "head": {"pitch": -56}}), "ease")
    feral = s({"root": {"y": -1.04, "z": -.12, "pitch": 36, "yaw": 6}, "torso": {"pitch": 22, "yaw": -4},
               "head": {"pitch": -50, "yaw": -8},
               "ra": {"raise": 64, "out": 30, "twist": 0, "elbow": 44, "wrist": 42},
               "la": {"raise": 68, "out": 30, "twist": 0, "elbow": 42, "wrist": 42},
               "rf": {"toe": -20}, "lf": {"toe": 0}})
    sh.key(46, feral, "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.L", "forearm.L", "hand.L", "shoulder.R", "forearm.R", "hand.R"], 1)
    return sh.build()


def author(arm):
    acts = clone_ambush(arm)
    acts += hidden_fuma(arm)
    acts += summon(arm)
    acts.append(clone_throw(arm))
    acts += [light4(arm), light5(arm), awaken(arm)]
    return acts
