"""Minato (fighter id "Flashstep") authored clips: economical, geometric.
Values share the runtime vocabulary (nd_anim); markers as in clips_sasuke."""
from nd_anim import clip, lag, merge

STANCE = {"root": {"y": -.42, "pitch": 9, "yaw": 24}, "torso": {"pitch": 5, "yaw": -14}, "head": {"pitch": -6, "yaw": -11},
          "ra": {"raise": 34, "out": 14, "twist": 24, "elbow": 98, "wrist": -22}, "la": {"raise": 58, "out": 2, "twist": 12, "elbow": 78, "wrist": 8},
          "rf": {"x": .22, "z": .78, "yaw": 32}, "lf": {"x": -.08, "z": -.72, "yaw": -4}}


def m(over):
    return merge(STANCE, over)


def author(arm):
    acts = []
    acts.append(clip(arm, "Flashstep.Idle", [
        (0, STANCE),
        (40, m({"root": {"y": -.47}, "torso": {"pitch": 7}, "ra": {"elbow": 102}, "la": {"elbow": 82}})),
        (80, STANCE),
    ], loop=True))

    # Light1: reverse-grip kunai, cross-body load, outward slash.
    acts.append(clip(arm, "Flashstep.Light1", [
        (0, STANCE),
        (4, m({"root": {"y": -.56, "yaw": 8, "pitch": 12}, "torso": {"yaw": -30, "pitch": 8},
               "ra": {"raise": 72, "out": -44, "twist": 40, "elbow": 114, "wrist": -32}, "la": {"raise": 40, "out": 12, "elbow": 70}, "lf": {"z": -.95}})),
        (8, m({"root": {"y": -.5, "z": -.4, "yaw": 38, "pitch": 14}, "torso": {"yaw": 26, "pitch": 6}, "head": {"yaw": -22},
               "ra": {"raise": 86, "out": 30, "twist": -14, "elbow": 20, "wrist": 12}, "la": {"raise": 20, "out": 24, "elbow": 58},
               "lf": {"z": -1.2}, "rf": {"z": .95}}), "LINEAR"),
        (12, m({"root": {"y": -.48, "z": -.42, "yaw": 44, "pitch": 12}, "torso": {"yaw": 36},
                "ra": {"raise": 70, "out": 60, "twist": -28, "elbow": 34}, "la": {"raise": 26, "out": 26, "elbow": 64}, "lf": {"z": -1.2}, "rf": {"z": .95}})),
        (26, STANCE),
    ], markers={"contact": 8, "recover": 13}))
    lag(arm, ["RightWrist", "Neck"], 1)

    # Light2: body-turned palm strike with the lead hand.
    acts.append(clip(arm, "Flashstep.Light2", [
        (0, STANCE),
        (4, m({"root": {"y": -.52, "yaw": 42, "pitch": 10}, "torso": {"yaw": 20}, "la": {"raise": 46, "out": 34, "twist": -18, "elbow": 100},
               "ra": {"raise": 40, "out": 18, "elbow": 100}})),
        (8, m({"root": {"y": -.48, "z": -.45, "yaw": -10, "pitch": 14}, "torso": {"yaw": -32, "pitch": 8}, "head": {"yaw": 8},
               "la": {"raise": 90, "out": -14, "twist": 22, "elbow": 22, "wrist": 30}, "ra": {"raise": 22, "out": 22, "elbow": 92},
               "rf": {"x": .36, "z": .2}, "lf": {"z": -1.05}}), "LINEAR"),
        (12, m({"root": {"y": -.46, "z": -.48, "yaw": -16, "pitch": 12}, "torso": {"yaw": -38},
                "la": {"raise": 82, "out": -28, "elbow": 36}, "ra": {"raise": 26, "out": 24, "elbow": 92}, "rf": {"x": .36, "z": .2}, "lf": {"z": -1.05}})),
        (26, STANCE),
    ], markers={"contact": 8, "recover": 13}))

    # Light3: spinning roundhouse, right leg.
    acts.append(clip(arm, "Flashstep.Light3", [
        (0, STANCE),
        (6, m({"root": {"y": -.62, "yaw": -40, "pitch": 8}, "torso": {"yaw": -22}, "ra": {"raise": 52, "out": -8, "elbow": 112},
               "la": {"raise": 52, "out": -4, "elbow": 112}, "rl": {"lift": 74, "out": 18, "knee": 108, "ankle": -10}, "lf": {"z": -.35, "yaw": -30}})),
        (11, m({"root": {"y": -.3, "yaw": 66, "pitch": -7, "roll": -22}, "torso": {"yaw": 12, "roll": -24}, "head": {"roll": 14, "yaw": -30},
                "ra": {"raise": -8, "out": 42, "elbow": 44}, "la": {"raise": 62, "out": -6, "twist": 18, "elbow": 104},
                "rl": {"lift": 88, "out": 58, "twist": -28, "knee": 8, "ankle": -24}, "lf": {"z": -.3, "yaw": 42}}), "LINEAR"),
        (16, m({"root": {"y": -.33, "yaw": 78, "pitch": -4, "roll": -18}, "torso": {"yaw": 16, "roll": -20},
                "ra": {"raise": -4, "out": 40, "elbow": 48}, "la": {"raise": 60, "out": -6, "twist": 18, "elbow": 104},
                "rl": {"lift": 80, "out": 60, "twist": -30, "knee": 16, "ankle": -20}, "lf": {"z": -.3, "yaw": 55}})),
        (24, m({"root": {"y": -.5, "yaw": 60}, "rl": {"lift": 42, "out": 20, "knee": 76}, "lf": {"z": -.3, "yaw": 40}})),
        (36, STANCE),
    ], markers={"contact": 11, "recover": 17}))
    lag(arm, ["Right", "Left"], 1)

    # Heavy: coiled whole-body lunge, straight right.
    acts.append(clip(arm, "Flashstep.Heavy", [
        (0, STANCE),
        (10, m({"root": {"y": -.76, "z": .32, "yaw": 48, "pitch": 13}, "torso": {"yaw": 28, "pitch": 9},
                "ra": {"raise": -20, "out": 22, "twist": 22, "elbow": 122}, "la": {"raise": 74, "out": -4, "elbow": 56}, "lf": {"z": -1.1}, "rf": {"z": 1.0, "yaw": 46}})),
        (15, m({"root": {"y": -.86, "z": .38, "yaw": 54, "pitch": 15}, "torso": {"yaw": 32, "pitch": 10},
                "ra": {"raise": -26, "out": 24, "twist": 24, "elbow": 128}, "la": {"raise": 78, "out": -6, "elbow": 52}, "lf": {"z": -1.15}, "rf": {"z": 1.05, "yaw": 48}})),
        (19, m({"root": {"y": -.5, "z": -.95, "yaw": -28, "pitch": 22}, "torso": {"yaw": -24, "pitch": 10}, "head": {"yaw": 16},
                "ra": {"raise": 90, "out": -4, "twist": -10, "elbow": 2}, "la": {"raise": -14, "out": 18, "elbow": 112},
                "lf": {"z": -1.7}, "rf": {"z": 1.25, "yaw": 10}}), "LINEAR"),
        (26, m({"root": {"y": -.52, "z": -.98, "yaw": -30, "pitch": 20}, "torso": {"yaw": -26, "pitch": 10},
                "ra": {"raise": 88, "out": -6, "twist": -10, "elbow": 8}, "la": {"raise": -10, "out": 18, "elbow": 110},
                "lf": {"z": -1.7}, "rf": {"z": 1.25, "yaw": 10}})),
        (42, STANCE),
    ], markers={"contact": 19, "recover": 26}))
    lag(arm, ["Left", "LeftElbow", "Neck"], 1)

    # Rasengan: forming (the left hand shapes it over the right palm)...
    form = m({"root": {"y": -.7, "z": .15, "pitch": 18, "yaw": 20}, "torso": {"pitch": 10, "yaw": 6}, "head": {"pitch": -12},
              "ra": {"raise": 60, "out": 8, "twist": -70, "elbow": 74, "wrist": 10}, "la": {"raise": 74, "out": -32, "twist": 44, "elbow": 86, "wrist": -10},
              "lf": {"z": -1.1}, "rf": {"z": 1.1, "yaw": 34}})
    acts.append(clip(arm, "Flashstep.BurstStrike.Channel", [
        (0, STANCE),
        (8, merge(form, {"la": {"raise": 82, "elbow": 70}})),
        (14, merge(form, {"la": {"raise": 70, "out": -28, "elbow": 92}, "ra": {"elbow": 70}})),
        (18, form),
    ], markers={"release": 18}))
    # ...and the strike that drives it in (attack variant "Rasengan").
    acts.append(clip(arm, "Flashstep.Rasengan", [
        (0, form),
        (3, m({"root": {"y": -.78, "z": .25, "pitch": 26}, "ra": {"raise": 72, "out": 8, "twist": -70, "elbow": 66, "wrist": 10},
               "la": {"raise": 78, "out": -30, "twist": 40, "elbow": 82}, "lf": {"z": -1.2}, "rf": {"z": 1.2}})),
        (7, m({"root": {"y": -.6, "z": -1.1, "pitch": 26, "yaw": -16}, "torso": {"yaw": -18}, "head": {"pitch": -14},
               "ra": {"raise": 94, "out": -2, "twist": -40, "elbow": 0, "wrist": -20}, "la": {"raise": 36, "out": 34, "elbow": 48},
               "lf": {"z": -1.8}, "rf": {"z": 1.55, "y": .2, "toe": -18}}), "LINEAR"),
        (16, m({"root": {"y": -.6, "z": -1.12, "pitch": 22, "yaw": -18}, "torso": {"yaw": -20},
                "ra": {"raise": 90, "out": -2, "twist": -40, "elbow": 6}, "la": {"raise": 40, "out": 30, "elbow": 50},
                "lf": {"z": -1.8}, "rf": {"z": 1.55, "y": .2, "toe": -18}})),
        (34, STANCE),
    ], markers={"contact": 7, "recover": 16}))
    return acts
