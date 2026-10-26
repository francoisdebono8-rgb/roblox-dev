"""Sasuke (fighter id "Lion") authored clips.

Each clip is keyed at 60 fps with anticipation -> action -> overshoot ->
settle. Markers tell the runtime where the server's phases fall:
  attacks:  contact (start of the active window), recover (its end)
  casts:    release (the jutsu leaves)
The runtime time-warps each segment onto the server's real timing, so the
contact frame always lands on the hit.
"""
from nd_anim import clip, lag, merge

# Low and forward, lead (left) hand out, rear hand by the chin, coiled.
STANCE = {"root": {"y": -.5, "pitch": 10, "yaw": 30}, "torso": {"pitch": 6, "yaw": -14}, "head": {"pitch": -6, "yaw": -14},
          "la": {"raise": 66, "out": 6, "twist": 10, "elbow": 64}, "ra": {"raise": 52, "out": -16, "twist": 24, "elbow": 118},
          "rf": {"x": .26, "z": .84, "yaw": 38}, "lf": {"x": -.1, "z": -.76, "yaw": -6}}


def s(over):
    return merge(STANCE, over)


def author(arm):
    acts = []
    # ---------------------------------------------------------- idle (loop)
    acts.append(clip(arm, "Lion.Idle", [
        (0, STANCE),
        (36, s({"root": {"y": -.56, "pitch": 11}, "torso": {"pitch": 8}, "la": {"raise": 63, "elbow": 68}, "ra": {"raise": 50, "elbow": 121}})),
        (72, STANCE),
    ], loop=True))

    # ------------------------------------------------------- Light1: the jab
    acts.append(clip(arm, "Lion.Light1", [
        (0, STANCE),
        # Load: the lead fist draws in, the hips coil away, weight drops.
        (3, s({"root": {"y": -.58, "yaw": 38}, "torso": {"yaw": 14}, "la": {"raise": 54, "out": 6, "twist": 22, "elbow": 116}})),
        # Snap: hips square up, the lead foot slides in, the fist goes straight out.
        (7, s({"root": {"y": -.5, "z": -.45, "yaw": -8, "pitch": 9}, "torso": {"yaw": -22, "pitch": 6}, "head": {"yaw": 2},
               "la": {"raise": 94, "out": -6, "twist": -16, "elbow": 0, "wrist": 0}, "ra": {"raise": 52, "out": -16, "elbow": 122},
               "lf": {"z": -1.05}}), "LINEAR"),
        # Overshoot: the shoulder rolls through.
        (10, s({"root": {"y": -.52, "z": -.5, "yaw": -12, "pitch": 10}, "torso": {"yaw": -26, "pitch": 7},
                "la": {"raise": 92, "out": -8, "twist": -14, "elbow": 6}, "ra": {"raise": 52, "out": -16, "elbow": 122}, "lf": {"z": -1.05}})),
        (16, s({"root": {"z": -.25, "yaw": 14}, "torso": {"yaw": -10}, "la": {"raise": 72, "elbow": 60}, "lf": {"z": -.9}})),
        (28, STANCE),
    ], markers={"contact": 7, "recover": 12}))
    lag(arm, ["Neck"], 1)

    # -------------------------------------------- Light2: rear-leg roundhouse
    acts.append(clip(arm, "Lion.Light2", [
        (0, STANCE),
        (6, s({"root": {"y": -.56, "yaw": -24, "pitch": 6}, "torso": {"yaw": -16}, "ra": {"raise": 50, "out": -10, "elbow": 110},
               "la": {"raise": 60, "out": 10, "elbow": 90}, "rl": {"lift": 64, "out": 22, "knee": 116, "ankle": -10}, "lf": {"yaw": -24}})),
        (11, s({"root": {"y": -.4, "yaw": 74, "pitch": -6, "roll": -20}, "torso": {"yaw": 10, "roll": -18}, "head": {"yaw": -42, "roll": 12},
                "ra": {"raise": -12, "out": 38, "elbow": 36}, "la": {"raise": 64, "out": -8, "twist": 20, "elbow": 112},
                "rl": {"lift": 80, "out": 64, "twist": -26, "knee": 6, "ankle": -22}, "lf": {"yaw": 54, "toe": -8}}), "LINEAR"),
        (15, s({"root": {"y": -.42, "yaw": 84, "pitch": -5, "roll": -18}, "torso": {"yaw": 13, "roll": -16},
                "ra": {"raise": -8, "out": 36, "elbow": 42}, "la": {"raise": 64, "out": -8, "twist": 20, "elbow": 112},
                "rl": {"lift": 74, "out": 66, "twist": -26, "knee": 14, "ankle": -20}, "lf": {"yaw": 62}})),
        (22, s({"root": {"y": -.5, "yaw": 50}, "rl": {"lift": 42, "out": 22, "knee": 74}, "lf": {"yaw": 30}})),
        (34, STANCE),
    ], markers={"contact": 11, "recover": 16}))
    lag(arm, ["Right", "RightElbow", "Neck"], 1)

    # ---------------------------------- Light3: spinning heel kick (finisher)
    acts.append(clip(arm, "Lion.Light3", [
        (0, STANCE),
        (5, s({"root": {"y": -.64, "yaw": -22, "pitch": 6}, "torso": {"yaw": -22}, "ra": {"raise": 40, "out": 30, "elbow": 90}, "la": {"raise": 40, "out": 30, "elbow": 90}})),
        (10, s({"root": {"y": -.45, "yaw": 92, "roll": 8}, "torso": {"yaw": -10}, "head": {"yaw": -62},
                "ra": {"raise": 40, "out": 24, "elbow": 100}, "la": {"raise": 40, "out": 24, "elbow": 100},
                "rl": {"lift": 42, "out": 30, "knee": 90}, "lf": {"yaw": 90, "x": .4, "z": 0}})),
        (15, s({"root": {"y": -.22, "yaw": 198, "pitch": -10, "roll": 18}, "torso": {"yaw": 16, "roll": 12}, "head": {"yaw": 52},
                "ra": {"raise": 22, "out": 48, "elbow": 48}, "la": {"raise": 32, "out": 42, "elbow": 58},
                "rl": {"lift": 100, "out": 54, "twist": 20, "knee": 4, "ankle": -22}, "lf": {"yaw": 198, "x": .4, "z": 0, "toe": -10}}), "LINEAR"),
        (20, s({"root": {"y": -.26, "yaw": 216, "pitch": -7, "roll": 15}, "torso": {"yaw": 18, "roll": 10},
                "ra": {"raise": 24, "out": 48, "elbow": 52}, "la": {"raise": 34, "out": 42, "elbow": 60},
                "rl": {"lift": 90, "out": 54, "twist": 20, "knee": 10, "ankle": -20}, "lf": {"yaw": 214, "x": .4, "z": 0}})),
        (28, s({"root": {"y": -.46, "yaw": 290}, "rl": {"lift": 40, "out": 20, "knee": 70}, "lf": {"yaw": 290, "x": .3, "z": 0}})),
        (40, s({"root": {"yaw": 390}, "rf": {"yaw": 398}, "lf": {"yaw": 354}})),
    ], markers={"contact": 15, "recover": 20}))
    lag(arm, ["Right", "Left", "RightElbow", "LeftElbow"], 2)

    # ------------------------------------- Heavy: driving front (push) kick
    acts.append(clip(arm, "Lion.Heavy", [
        (0, STANCE),
        (9, s({"root": {"y": -.8, "z": .28, "pitch": 13}, "torso": {"pitch": 9}, "ra": {"raise": 40, "out": 20, "elbow": 100},
               "la": {"raise": 60, "out": 10, "elbow": 90}, "lf": {"z": -1.0}})),
        (13, s({"root": {"y": -.5, "z": -.15, "pitch": 2}, "rl": {"lift": 92, "knee": 124, "ankle": -12},
                "ra": {"raise": 10, "out": 30, "elbow": 70}, "la": {"raise": 66, "out": -4, "elbow": 100}, "lf": {"z": -1.15}})),
        (17, s({"root": {"y": -.3, "z": -.62, "pitch": -15}, "torso": {"pitch": -6, "yaw": -8}, "head": {"pitch": 10},
                "ra": {"raise": -20, "out": 40, "elbow": 40}, "la": {"raise": 70, "out": -10, "elbow": 100},
                "rl": {"lift": 98, "out": 4, "knee": 2, "ankle": -30}, "lf": {"z": -1.2, "toe": -10}}), "LINEAR"),
        (24, s({"root": {"y": -.33, "z": -.65, "pitch": -12}, "torso": {"pitch": -6, "yaw": -8},
                "ra": {"raise": -18, "out": 40, "elbow": 42}, "la": {"raise": 70, "out": -10, "elbow": 100},
                "rl": {"lift": 92, "knee": 8, "ankle": -28}, "lf": {"z": -1.2}})),
        (32, s({"root": {"y": -.55, "z": -.3}, "rl": {"lift": 48, "knee": 84}, "lf": {"z": -1.1}})),
        (44, STANCE),
    ], markers={"contact": 17, "recover": 24}))
    lag(arm, ["Right", "Left", "Neck"], 1)

    # -------------------------------------- Katon: Great Fireball (4 parts)
    seal_a = s({"root": {"y": -.42, "pitch": 4, "yaw": 20}, "torso": {"pitch": 6, "yaw": -6}, "head": {"pitch": 6, "yaw": -6},
                "ra": {"raise": 56, "out": -30, "twist": 32, "elbow": 104, "wrist": 8}, "la": {"raise": 56, "out": -30, "twist": 32, "elbow": 104, "wrist": 8},
                "rf": {"x": .3, "z": .6, "yaw": 30}, "lf": {"x": -.2, "z": -.5}})
    seal_b = merge(seal_a, {"ra": {"raise": 66, "out": -26, "twist": 44, "elbow": 92, "wrist": 24}, "la": {"raise": 62, "out": -28, "twist": 20, "elbow": 100, "wrist": -10}})
    seal_c = merge(seal_a, {"ra": {"raise": 50, "out": -34, "twist": 18, "elbow": 116, "wrist": -16}, "la": {"raise": 54, "out": -32, "twist": 40, "elbow": 110, "wrist": 14}})
    tiger = merge(seal_a, {"ra": {"raise": 62, "out": -28, "twist": 36, "elbow": 98, "wrist": 30}, "la": {"raise": 62, "out": -28, "twist": 36, "elbow": 98, "wrist": 30}})
    inhale = merge(tiger, {"root": {"y": -.36, "pitch": -6, "z": .15}, "torso": {"pitch": -16}, "head": {"pitch": -14},
                           "ra": {"raise": 112, "out": -36, "twist": 22, "elbow": 146, "wrist": -10}, "la": {"raise": 30, "out": 12, "elbow": 70}})
    acts.append(clip(arm, "Lion.FireBloom.Channel", [
        (0, STANCE), (5, seal_a), (11, seal_b), (17, seal_c), (23, tiger), (30, inhale),
    ], markers={"release": 30}))
    deep = merge(inhale, {"root": {"y": -.7, "z": .4, "pitch": -14}, "torso": {"pitch": -26}, "head": {"pitch": -22},
                          "la": {"raise": 46, "elbow": 66}, "rf": {"z": .95}, "lf": {"z": -.7}})
    acts.append(clip(arm, "Lion.FireBloom.Hold", [
        (0, inhale), (30, deep), (45, merge(deep, {"torso": {"pitch": -28}, "head": {"pitch": -24}})), (60, deep),
    ], markers={"loop": 30}))
    blow = s({"root": {"y": -.66, "z": -.45, "pitch": 18, "yaw": 8}, "torso": {"pitch": 14, "yaw": -6}, "head": {"pitch": 14, "yaw": -4},
              "ra": {"raise": 112, "out": -36, "twist": 22, "elbow": 146, "wrist": -10}, "la": {"raise": 8, "out": 30, "elbow": 30},
              "lf": {"z": -1.15}, "rf": {"z": 1.05, "yaw": 30}})
    acts.append(clip(arm, "Lion.FireBloom.Release", [
        (0, inhale),
        (5, blow, "LINEAR"),
        (12, merge(blow, {"root": {"z": -.55, "pitch": 20}, "torso": {"pitch": 16}})),
        (24, merge(blow, {"root": {"z": -.4, "pitch": 16}})),
    ], markers={"release": 5}))
    acts.append(clip(arm, "Lion.FireBloom.Recover", [
        (0, merge(blow, {"root": {"z": -.4, "pitch": 16}})),
        (8, s({"root": {"y": -.56, "z": -.1}, "ra": {"raise": 80, "elbow": 120}, "la": {"raise": 40, "elbow": 60}})),
        (22, STANCE),
    ]))

    # ----------------------------------------------------- Chidori: form
    grip = s({"root": {"y": -.95, "pitch": 22, "yaw": 34}, "torso": {"pitch": 16, "yaw": 4}, "head": {"pitch": -16, "yaw": -18},
              "ra": {"raise": 8, "out": 10, "twist": 30, "elbow": 40, "wrist": -40},
              "la": {"raise": 24, "out": -34, "twist": 50, "elbow": 72, "wrist": 10},
              "rf": {"x": .4, "z": 1.05, "yaw": 46}, "lf": {"x": -.2, "z": -.95, "yaw": -4}})
    acts.append(clip(arm, "Lion.Chidori.Form", [
        (0, STANCE),
        (8, merge(grip, {"root": {"y": -.75}, "ra": {"raise": 30, "elbow": 70, "wrist": -20}})),
        (18, grip),
        (28, merge(grip, {"root": {"y": -1.0}, "ra": {"raise": 4, "elbow": 34, "wrist": -46}})),
        (37, grip),
    ], markers={"release": 37}))
    # Carried: the lightning hand low and back, the free hand forward.
    carry = s({"root": {"y": -.7, "pitch": 18, "yaw": 10}, "torso": {"pitch": 12, "yaw": 8}, "head": {"pitch": -14, "yaw": -6},
               "ra": {"raise": -30, "out": 20, "twist": 40, "elbow": 24, "wrist": -30}, "la": {"raise": 60, "out": -10, "elbow": 60}})
    acts.append(clip(arm, "Lion.Chidori.Hold", [
        (0, grip), (10, carry), (40, merge(carry, {"ra": {"raise": -26, "wrist": -24}})), (70, carry),
    ], markers={"loop": 10}))
    acts.append(clip(arm, "Lion.ChidoriThrust", [
        (0, carry),
        (3, s({"root": {"y": -1.0, "z": .25, "pitch": 26, "yaw": 22}, "torso": {"pitch": 14, "yaw": 12}, "head": {"pitch": -16},
               "ra": {"raise": -24, "out": 22, "twist": 40, "elbow": 26, "wrist": -32}, "la": {"raise": 30, "out": -30, "twist": 40, "elbow": 90},
               "lf": {"z": -1.2}, "rf": {"z": 1.1, "yaw": 40}})),
        (7, s({"root": {"y": -.7, "z": -1.3, "pitch": 30, "yaw": -14}, "torso": {"pitch": 12, "yaw": -16}, "head": {"pitch": -18},
               "ra": {"raise": 96, "out": -4, "twist": -20, "elbow": 2, "wrist": -10}, "la": {"raise": 36, "out": -24, "twist": 30, "elbow": 104},
               "lf": {"z": -1.9}, "rf": {"z": 1.6, "y": .25, "toe": -26}}), "LINEAR"),
        (18, s({"root": {"y": -.72, "z": -1.32, "pitch": 28, "yaw": -16}, "torso": {"pitch": 12, "yaw": -18},
                "ra": {"raise": 92, "out": -4, "twist": -20, "elbow": 6}, "la": {"raise": 36, "out": -24, "twist": 30, "elbow": 104},
                "lf": {"z": -1.9}, "rf": {"z": 1.6, "y": .2, "toe": -24}})),
        (34, s({"root": {"y": -.6, "z": -.5}, "ra": {"raise": 60, "elbow": 60}})),
        (48, STANCE),
    ], markers={"contact": 7, "recover": 18}))

    # ---------------------------------------------------- hit reactions
    acts.append(clip(arm, "Lion.HitFront", [
        (0, STANCE),
        (3, s({"root": {"y": -.56, "z": .35, "pitch": -12}, "torso": {"pitch": -14, "yaw": 6}, "head": {"pitch": -26, "yaw": 10},
               "ra": {"raise": 30, "out": 26, "elbow": 70}, "la": {"raise": 40, "out": 30, "elbow": 50}}), "LINEAR"),
        (8, s({"root": {"y": -.6, "z": .4, "pitch": -8}, "torso": {"pitch": -8}, "head": {"pitch": -10}})),
        (22, STANCE),
    ]))
    lag(arm, ["Neck", "Right", "Left"], 1)
    return acts
