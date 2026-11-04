"""Gaara's seal jutsu and his own string hits (04/11, user: the new jutsu had
no animations of their own, « fais-moi de belles animations, applique-toi
bien »).

Authored on his body (gaara_p7.STANCE: upright, arms folded high, feet
close). His bible: he does not fight with his body - the sand moves, he
barely does. Every gesture is a small, exact command of a hand (an arm
unfolds, a palm opens or presses, the fingers close), the head stays level,
the eyes do not leave the opponent, the hips almost never turn; the weight
of the gourd keeps him planted. Each seal is made at the chest with no sink
of the knees (he does not gather himself: the sand does). Then the act:

  ShukakuArm     tiger - snake, the right arm unfolds and rises high out to
                 his right side, clawed (the giant arm grows from that
                 shoulder); the release brings it down to shoulder height
                 and sweeps it flat across the field, right to left, the
                 chest turning with it a little; it carries on across and
                 folds back slowly
  SandSpikes     snake - ram, the left hand drops open, palm to the floor
                 ahead; it presses once, then the fingers snap up: three
                 lines of spikes burst
  Quicksand      ram - rat, the right hand reaches low at the target, palm
                 down, and stirs a slow circle; the release is a heavy press
                 down, held - the floor gives way under him
  ThirdEye       rat - tiger, two fingers raised to the right eye (the left
                 arm folds back); the eye of sand floats up as his chin lifts
  SandClone      ram - tiger, the seal held at the chin, then the hands open
                 down by his sides, palms back: the sand pours down over him
                 (the clone that will take the blow), and the arms fold again
  SandHand       heavy: both arms reach out, the hands open like claws, the
                 fingers close on him and both fists are pulled down: the
                 sand hand slams him into the floor and holds him there
  SandFist       launcher: the right fist set into the left palm at the
                 chest (the sand gathers into a fist), drawn back a hair,
                 then both arms drive straight out: the fist of sand throws
                 him away
  SandLowWave    away route: both palms brought up flat, then pushed down
                 and out low, the knees giving a little: the wave rolls
                 along the floor at his ankles
  Light4         the string's third lash: a backhand - the right hand comes
                 across to his left shoulder and snaps out to the right,
                 back of the hand leading (L1 is a forehand reach inward)

Server timings (Shared/SealJutsu.Sand; Shared/Attacks with his profile):
  ShukakuArm  .3 / .12 / .34    SandSpikes .24 / .06 / .28   Quicksand .4 / .15 / .3
  ThirdEye .2 / .04 / .12       SandClone .04 / .04 / .2 (window .9)
  SandHand .24 / .16 / .48      SandFist (Light3 profile) .342 / .14 / .6
  SandLowWave .16 / .16 / .4    Light4 (Light1 profile) .162 / .12 / .406
"""
from nd_shot import Shot, merge
from gaara_p7 import STANCE, FOLD_R, FOLD_L, s
import nd_seals

N = "Sand."
F = 60.0
SEAL_BASE = {"head": {"pitch": 4}}


def seals(shot, signs, beat):
    # no sink: the seals are made at the chest, the body does not gather
    return nd_seals.weave(shot, 0, signs, s(SEAL_BASE), beat=beat, sink=.012)


# ================================================================ ShukakuArm
def shukaku_arm(arm):
    out = []
    ch = Shot(arm, N + "ShukakuArm.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (1, 2), 5)                                   # 5, 10
    # the right hand leaves the seal, the elbow lifting first ...
    ch.key(last + 4, s({"ra": {"raise": 70, "out": 60, "twist": 0, "elbow": 96, "wrist": 0},
                        "torso": {"yaw": 4, "roll": -2}, "head": {"yaw": -6}}), "pass")
    # ... and the arm opens high out to his right side, clawed
    raised = s({"root": {"yaw": 8}, "torso": {"pitch": -3, "yaw": 12, "roll": -5},
                "head": {"pitch": 2, "yaw": -14, "roll": 3},
                "ra": {"raise": 40, "out": 132, "twist": -30, "elbow": 26, "wrist": -34}})
    ch.key(last + 8, raised, "ease")                              # 18
    ch.drag(["neck"], 2)
    ch.drag(["hand.R"], 1)
    out.append(ch.build(markers={"release": (last + 8) / F}))

    re = Shot(arm, N + "ShukakuArm.Release")
    re.key(0, raised, "ease")
    # it comes down to shoulder height on his right (the arm of sand
    # landing on the field) ...
    right = s({"root": {"yaw": 8}, "torso": {"pitch": 0, "yaw": 14, "roll": -2},
               "head": {"pitch": 4, "yaw": -14},
               "ra": {"raise": 96, "out": 84, "twist": -20, "elbow": 14, "wrist": -26}})
    re.key(3, right, "impact")
    # ... and sweeps flat across, right to left, the chest turning with it
    re.key(8, s({"root": {"yaw": 4}, "torso": {"yaw": 0, "roll": 0}, "head": {"pitch": 4, "yaw": -6},
                 "ra": {"raise": 98, "out": 6, "twist": -10, "elbow": 10, "wrist": -14}}), "pass")
    left = s({"root": {"yaw": 0}, "torso": {"yaw": -16, "roll": 2}, "head": {"pitch": 4, "yaw": 2},
              "ra": {"raise": 96, "out": -46, "twist": 0, "elbow": 14, "wrist": -6}})
    re.key(13, left, "ease")
    re.drag(["neck"], 2)
    re.drag(["hand.R"], 1)
    out.append(re.build(markers={"release": 3 / F}))

    rc = Shot(arm, N + "ShukakuArm.Recover")
    rc.key(0, left, "ease")
    # it carries on across, slowing, then folds back (no hurry)
    rc.key(6, merge(left, {"torso": {"yaw": -20}, "ra": {"raise": 92, "out": -60, "elbow": 22, "wrist": 0}}), "ease")
    rc.key(14, s({"torso": {"yaw": -8}, "ra": {"raise": 72, "out": -36, "twist": 30, "elbow": 84}}), "pass")
    rc.key(20, s(), "ease")
    rc.key(22, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


# ================================================================ SandSpikes
def sand_spikes(arm):
    out = []
    ch = Shot(arm, N + "SandSpikes.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (2, 3), 4)                                   # 4, 8
    # the left hand drops open, palm to the floor ahead of him
    ready = s({"head": {"pitch": 10, "yaw": -2}, "torso": {"roll": -2},
               "la": {"raise": 36, "out": 16, "twist": -10, "elbow": 8, "wrist": 26}})
    ch.key(last + 3, s({"head": {"pitch": 8}, "la": {"raise": 52, "out": 6, "twist": 10, "elbow": 70, "wrist": 10}}), "pass")
    ch.key(last + 6, ready, "ease")                               # 14
    ch.drag(["neck"], 2)
    ch.drag(["hand.L"], 1)
    out.append(ch.build(markers={"release": (last + 6) / F}))

    re = Shot(arm, N + "SandSpikes.Release")
    re.key(0, ready, "ease")
    # one press ...
    press = merge(ready, {"root": {"y": -.08}, "torso": {"roll": -4}, "la": {"raise": 28, "wrist": 40}})
    re.key(2, press, "impact")
    # ... and the fingers snap up: the spikes burst
    snap = s({"root": {"y": -.05}, "head": {"pitch": 2, "yaw": -2}, "torso": {"roll": 0},
              "la": {"raise": 58, "out": 18, "twist": -10, "elbow": 24, "wrist": -44}})
    re.key(5, snap, "impact")
    held = merge(snap, {"la": {"raise": 62, "wrist": -50}})
    re.key(10, held, "ease")
    re.drag(["neck"], 1)
    out.append(re.build(markers={"release": 5 / F}))

    rc = Shot(arm, N + "SandSpikes.Recover")
    rc.key(0, held, "ease")
    rc.key(8, s({"la": {"raise": 48, "out": -14, "twist": 24, "elbow": 74, "wrist": 0}}), "pass")
    rc.key(16, s(), "ease")
    rc.key(18, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


# ================================================================= Quicksand
def quicksand(arm):
    out = []
    ch = Shot(arm, N + "Quicksand.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (3, 4), 5)                                   # 5, 10
    # the right hand reaches low toward him, palm down ...
    reach = s({"head": {"pitch": 8, "yaw": -4},
               "ra": {"raise": 52, "out": 8, "twist": -20, "elbow": 12, "wrist": -12}})
    ch.key(last + 5, reach, "ease")                               # 15
    # ... and stirs a slow circle over the place
    ch.key(last + 10, merge(reach, {"torso": {"yaw": -3}, "ra": {"raise": 46, "out": -8}}), "pass")
    stir = merge(reach, {"torso": {"yaw": 2}, "ra": {"raise": 50, "out": 12, "wrist": -16}})
    ch.key(last + 14, stir, "ease")                               # 24
    ch.drag(["neck"], 2)
    ch.drag(["hand.R"], 2)
    out.append(ch.build(markers={"release": (last + 14) / F}))

    re = Shot(arm, N + "Quicksand.Release")
    re.key(0, stir, "ease")
    # the press: slow and heavy, the palm flat, the shoulders give a hair
    press = s({"root": {"y": -.1}, "torso": {"pitch": 4, "yaw": 1}, "head": {"pitch": 10, "yaw": -4},
               "ra": {"raise": 30, "out": 8, "twist": -20, "elbow": 6, "wrist": -30}})
    re.key(6, press, "ease")
    held = merge(press, {"root": {"y": -.11}, "ra": {"raise": 27}})
    re.key(15, held, "ease")
    re.drag(["hand.R"], 1)
    out.append(re.build(markers={"release": 6 / F}))

    rc = Shot(arm, N + "Quicksand.Recover")
    rc.key(0, held, "ease")
    rc.key(7, merge(held, {"root": {"y": -.08}, "ra": {"raise": 34, "wrist": -10}}), "ease")
    rc.key(18, s(), "ease")
    rc.key(20, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


# ================================================================== ThirdEye
TWO_FINGERS = {"raise": 84, "out": -12, "twist": 50, "elbow": 98, "wrist": 6}


def third_eye(arm):
    out = []
    ch = Shot(arm, N + "ThirdEye.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (4, 1), 4)                                   # 4, 8
    # the left arm folds back, two fingers of the right raised to the eye
    eye = s({"head": {"pitch": 6, "yaw": -2, "roll": -3}, "torso": {"roll": -1},
             "ra": TWO_FINGERS, "la": FOLD_L})
    ch.key(last + 4, eye, "ease")                                 # 12
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 4) / F}))

    re = Shot(arm, N + "ThirdEye.Release")
    re.key(0, eye, "ease")
    # focus: the fingers press to the eye, the chin lifts, he stands taller
    focus = s({"root": {"y": -.03}, "head": {"pitch": -2, "yaw": -2, "roll": -2},
               "ra": merge(TWO_FINGERS, {"raise": 88, "elbow": 102}), "la": FOLD_L})
    re.key(3, focus, "impact")
    re.key(8, merge(focus, {"head": {"pitch": -4}}), "ease")
    out.append(re.build(markers={"release": 3 / F}))

    rc = Shot(arm, N + "ThirdEye.Recover")
    rc.key(0, merge(focus, {"head": {"pitch": -4}}), "ease")
    rc.key(8, s(), "ease")
    rc.drag(["neck"], 2)
    rc.drag(["forearm.R", "hand.R"], 1)
    out.append(rc.build())
    return out


# ================================================================= SandClone
def sand_clone(arm):
    out = []
    ch = Shot(arm, N + "SandClone.Channel")
    ch.key(0, s(), "ease")
    last = seals(ch, (3, 1), 3)                                   # 3, 6
    tiger = s(merge(SEAL_BASE, nd_seals.seal(1)))
    out.append(ch.build(markers={"release": last / F}))

    re = Shot(arm, N + "SandClone.Release")
    re.key(0, tiger, "ease")
    # the hands open down by his sides, palms back: the sand pours over him
    pour = s({"root": {"y": -.1}, "head": {"pitch": 12, "yaw": -4},
              "ra": {"raise": 10, "out": 24, "twist": -40, "elbow": 12, "wrist": -26},
              "la": {"raise": 10, "out": 24, "twist": -40, "elbow": 12, "wrist": -26}})
    re.key(3, pour, "impact")
    held = merge(pour, {"root": {"y": -.11}, "ra": {"out": 28}, "la": {"out": 28}})
    re.key(8, held, "ease")
    re.drag(["neck"], 1)
    out.append(re.build(markers={"release": 3 / F}))

    rc = Shot(arm, N + "SandClone.Recover")
    rc.key(0, held, "ease")
    rc.key(5, merge(held, {"head": {"pitch": 8}}), "ease")
    rc.key(13, s(), "ease")
    rc.drag(["neck"], 2)
    rc.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    out.append(rc.build())
    return out


# ================================================================= strikes
def sand_hand(arm):
    """Heavy (.24 / .16 / .48): both arms reach out, the hands open like
    claws; the fingers close on him and both fists are pulled down - the
    hand of sand slams him into the floor and holds him; then the hands open
    and the arms fold back."""
    sh = Shot(arm, N + "SandHand")
    sh.key(0, s(), "ease")
    claw = {"raise": 90, "out": 6, "twist": -10, "elbow": 16, "wrist": -38}
    reach = s({"torso": {"pitch": -3}, "head": {"pitch": 4},
               "ra": claw, "la": merge(claw, {"out": 8})})
    sh.key(5, s({"ra": {"raise": 72, "out": 10, "twist": 0, "elbow": 70, "wrist": -10},
                 "la": {"raise": 70, "out": 12, "twist": 0, "elbow": 72, "wrist": -10}}), "pass")
    sh.key(10, reach, "ease")
    # the seize: the fingers close
    sh.key(12, merge(reach, {"ra": {"raise": 88, "elbow": 22, "wrist": 30}, "la": {"raise": 88, "elbow": 22, "wrist": 30}}), "ease")
    slam = s({"root": {"y": -.14}, "torso": {"pitch": 8}, "head": {"pitch": 12},
              "ra": {"raise": 36, "out": 6, "twist": 0, "elbow": 34, "wrist": 34},
              "la": {"raise": 36, "out": 8, "twist": 0, "elbow": 34, "wrist": 34}})
    sh.key(14, slam, "impact")
    sh.key(19, merge(slam, {"root": {"y": -.12}, "ra": {"raise": 33}, "la": {"raise": 33}}), "ease")
    sh.key(24, merge(slam, {"root": {"y": -.12}, "ra": {"raise": 34}, "la": {"raise": 34}}), "ease")
    # the hands open, rise, and fold
    sh.key(36, s({"root": {"y": -.08}, "head": {"pitch": 8},
                  "ra": {"raise": 48, "out": -10, "twist": 20, "elbow": 80, "wrist": -10},
                  "la": {"raise": 46, "out": -12, "twist": 20, "elbow": 80, "wrist": -10}}), "pass")
    sh.key(51, s(), "ease")
    sh.key(53, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 14 / F, "recover": 24 / F})


def sand_fist(arm):
    """Launcher (.342 / .14 / .6): the right fist set into the left palm at
    the chest - the sand gathers into one great fist - drawn back a hair,
    then both arms drive straight out together; held while it carries him,
    then they part and fold."""
    sh = Shot(arm, N + "SandFist")
    sh.key(0, s(), "ease")
    gather = s({"torso": {"pitch": -2, "yaw": 6}, "head": {"pitch": 6, "yaw": -8},
                "ra": {"raise": 44, "out": -44, "twist": 30, "elbow": 104, "wrist": 10},
                "la": {"raise": 46, "out": -40, "twist": 30, "elbow": 96, "wrist": -24}})
    sh.key(10, gather, "ease")
    sh.key(16, merge(gather, {"root": {"y": -.1, "z": .04}, "torso": {"pitch": -4, "yaw": 9},
                              "ra": {"raise": 38, "elbow": 112}, "la": {"raise": 40, "elbow": 104}}), "ease")
    drive = s({"root": {"y": -.1, "z": -.06}, "torso": {"pitch": 6, "yaw": -4}, "head": {"pitch": 4, "yaw": -2},
               "ra": {"raise": 90, "out": -12, "twist": 0, "elbow": 6, "wrist": 0},
               "la": {"raise": 88, "out": -14, "twist": 10, "elbow": 14, "wrist": -24}})
    sh.key(20, drive, "impact")
    sh.key(25, merge(drive, {"ra": {"raise": 92}, "la": {"raise": 90}}), "ease")
    sh.key(29, merge(drive, {"ra": {"raise": 91}, "la": {"raise": 89}}), "ease")
    sh.key(44, s({"root": {"y": -.08}, "ra": {"raise": 66, "out": 0, "twist": 10, "elbow": 60}, "la": {"raise": 60, "out": 4, "twist": 10, "elbow": 66}}), "pass")
    sh.key(63, s(), "ease")
    sh.key(65, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 20 / F, "recover": 29 / F})


def sand_low_wave(arm):
    """Away route (.16 / .16 / .4): both palms brought up flat at the chest,
    then pushed down and out low, the knees giving a little - the wave
    rolls along the floor at his ankles."""
    sh = Shot(arm, N + "SandLowWave")
    sh.key(0, s(), "ease")
    up = s({"root": {"y": -.04}, "torso": {"pitch": -2}, "head": {"pitch": 6},
            "ra": {"raise": 70, "out": 8, "twist": -30, "elbow": 96, "wrist": -24},
            "la": {"raise": 70, "out": 8, "twist": -30, "elbow": 96, "wrist": -24}})
    sh.key(6, up, "ease")
    push = s({"root": {"y": -.2}, "torso": {"pitch": 12}, "head": {"pitch": 12},
              "ra": {"raise": 36, "out": 16, "twist": -20, "elbow": 8, "wrist": -44},
              "la": {"raise": 36, "out": 16, "twist": -20, "elbow": 8, "wrist": -44}})
    sh.key(10, push, "impact")
    sh.key(15, merge(push, {"root": {"y": -.22}, "ra": {"raise": 40, "wrist": -50}, "la": {"raise": 40, "wrist": -50}}), "ease")
    sh.key(19, merge(push, {"root": {"y": -.21}, "ra": {"raise": 40, "wrist": -48}, "la": {"raise": 40, "wrist": -48}}), "ease")
    sh.key(30, s({"root": {"y": -.1}, "torso": {"pitch": 4},
                  "ra": {"raise": 50, "out": -16, "twist": 20, "elbow": 80, "wrist": -10},
                  "la": {"raise": 48, "out": -18, "twist": 20, "elbow": 80, "wrist": -10}}), "pass")
    sh.key(41, s(), "ease")
    sh.key(43, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"contact": 10 / F, "recover": 19 / F})


def light4(arm):
    """L4 (.162 / .12 / .406), the backhand lash: the right hand comes across
    to his left shoulder (back of the hand out) and snaps out to his right,
    the wrist cracking last; the stream curls out that side. The head never
    leaves the opponent."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    across = s({"torso": {"yaw": -6}, "head": {"yaw": -2},
                "ra": {"raise": 72, "out": -56, "twist": 30, "elbow": 118, "wrist": 34}})
    sh.key(6, across, "ease")
    out_ = s({"torso": {"yaw": 6}, "head": {"yaw": -8},
              "ra": {"raise": 86, "out": 46, "twist": -20, "elbow": 14, "wrist": -32}})
    sh.key(9, merge(out_, {"ra": {"out": 18, "elbow": 40, "wrist": 10}}), "pass")
    sh.key(10, out_, "impact")
    sh.key(14, merge(out_, {"ra": {"out": 54, "wrist": -44}}), "ease")
    sh.key(17, merge(out_, {"ra": {"out": 52, "wrist": -40}}), "ease")
    sh.key(28, s({"ra": {"raise": 70, "out": 10, "twist": 20, "elbow": 80, "wrist": -10}}), "pass")
    sh.key(39, s(), "ease")
    sh.key(41, s(), "ease")
    sh.drag(["neck"], 2)
    sh.drag(["hand.R"], 1)
    return sh.build(markers={"contact": 10 / F, "recover": 17 / F})


def author(arm):
    acts = shukaku_arm(arm)
    acts += sand_spikes(arm)
    acts += quicksand(arm)
    acts += third_eye(arm)
    acts += sand_clone(arm)
    acts += [sand_hand(arm), sand_fist(arm), sand_low_wave(arm), light4(arm)]
    return acts
