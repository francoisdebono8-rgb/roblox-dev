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
        # Load: the lead shoulder draws back a hair, weight onto the front foot.
        (4, s({"root": {"y": -.56, "yaw": 38, "z": .05}, "torso": {"yaw": -4}, "la": {"raise": 60, "elbow": 96, "twist": 22}})),
        # Snap: hips turn in, the fist goes straight to the face.
        (8, s({"root": {"y": -.5, "z": -.35, "yaw": 18, "pitch": 9}, "torso": {"yaw": -26, "pitch": 8}, "head": {"yaw": -6},
                "la": {"raise": 94, "out": -6, "twist": -16, "elbow": 2, "wrist": -4}, "ra": {"raise": 56, "out": -18, "elbow": 122},
                "lf": {"z": -.9}}), "LINEAR"),
        # Overshoot and recoil of the arm.
        (11, s({"root": {"z": -.38, "yaw": 16, "pitch": 10}, "torso": {"yaw": -28, "pitch": 9},
                 "la": {"raise": 92, "out": -6, "twist": -14, "elbow": 10}, "ra": {"raise": 56, "out": -18, "elbow": 122}, "lf": {"z": -.9}})),
        (18, s({"root": {"z": -.1, "yaw": 26}, "torso": {"yaw": -18}, "la": {"raise": 74, "elbow": 54}})),
        (30, STANCE),
    ], markers={"contact": 8, "recover": 14}))
    lag(arm, ["Neck"], 1)

    # -------------------------------------------- Light2: rear-leg roundhouse
    acts.append(clip(arm, "Lion.Light2", [
        (0, STANCE),
        # Chamber: weight onto the lead foot, the rear knee comes up and across.
        (6, s({"root": {"y": -.46, "yaw": 4, "pitch": 4, "z": -.15}, "torso": {"yaw": -10, "roll": 4}, "head": {"yaw": -4},
                "ra": {"raise": 46, "out": -8, "elbow": 112}, "la": {"raise": 70, "out": 14, "elbow": 84},
                "rl": {"lift": 70, "out": 24, "twist": -10, "knee": 124, "ankle": -10}, "lf": {"yaw": -10, "z": -.6}})),
        # Contact: the hip turns over, the shin snaps out flat at rib height.
        (11, s({"root": {"y": -.38, "yaw": 74, "pitch": -6, "roll": -18, "z": -.2}, "torso": {"yaw": 12, "roll": -16}, "head": {"yaw": -44, "roll": 12},
                 "ra": {"raise": -12, "out": 36, "elbow": 36}, "la": {"raise": 66, "out": -10, "twist": 22, "elbow": 112},
                 "rl": {"lift": 80, "out": 66, "twist": -28, "knee": 6, "ankle": -24}, "lf": {"yaw": 54, "z": -.6, "toe": -10}}), "LINEAR"),
        (15, s({"root": {"y": -.4, "yaw": 84, "pitch": -5, "roll": -16, "z": -.2}, "torso": {"yaw": 14, "roll": -14}, "head": {"yaw": -46, "roll": 10},
                 "ra": {"raise": -8, "out": 38, "elbow": 40}, "la": {"raise": 66, "out": -10, "twist": 22, "elbow": 112},
                 "rl": {"lift": 76, "out": 66, "twist": -28, "knee": 14, "ankle": -24}, "lf": {"yaw": 62, "z": -.6, "toe": -10}})),
        # Re-chamber, then the foot comes down back where it started.
        (22, s({"root": {"y": -.5, "yaw": 54, "z": -.15}, "torso": {"yaw": 0}, "rl": {"lift": 54, "out": 30, "knee": 104}, "lf": {"yaw": 34, "z": -.6}})),
        (34, STANCE),
    ], markers={"contact": 11, "recover": 16}))
    lag(arm, ["Right", "RightElbow", "Neck"], 1)

    # ---------------------------------- Light3: spinning heel kick (finisher)
    acts.append(clip(arm, "Lion.Light3", [
        (0, STANCE),
        (6, s({"root": {"y": -.66, "yaw": -24, "pitch": 6}, "torso": {"yaw": -22}, "head": {"yaw": -8},
                "ra": {"raise": 40, "out": 30, "elbow": 92}, "la": {"raise": 40, "out": 30, "elbow": 92}})),
        (11, s({"root": {"y": -.46, "yaw": 100, "roll": 8}, "torso": {"yaw": -14}, "head": {"yaw": -64},
                 "ra": {"raise": 38, "out": 30, "elbow": 96}, "la": {"raise": 38, "out": 30, "elbow": 96},
                 "rl": {"lift": 40, "out": 30, "knee": 92}, "lf": {"yaw": 100, "x": .4, "z": 0}})),
        (16, s({"root": {"y": -.24, "yaw": 198, "pitch": -8, "roll": 18}, "torso": {"yaw": 16, "roll": 12}, "head": {"yaw": 52},
                 "ra": {"raise": 20, "out": 52, "elbow": 46}, "la": {"raise": 30, "out": 46, "elbow": 56},
                 "rl": {"lift": 96, "out": 54, "twist": 20, "knee": 4, "ankle": -22}, "lf": {"yaw": 198, "x": .4, "z": 0, "toe": -12}}), "LINEAR"),
        (21, s({"root": {"y": -.27, "yaw": 222, "pitch": -6, "roll": 14}, "torso": {"yaw": 20, "roll": 10},
                 "ra": {"raise": 22, "out": 50, "elbow": 50}, "la": {"raise": 32, "out": 44, "elbow": 58},
                 "rl": {"lift": 86, "out": 56, "twist": 20, "knee": 12, "ankle": -20}, "lf": {"yaw": 222, "x": .4, "z": 0}})),
        (30, s({"root": {"y": -.5, "yaw": 300}, "rl": {"lift": 40, "out": 20, "knee": 76}, "lf": {"yaw": 300, "x": .3, "z": 0}})),
        (42, s({"root": {"yaw": 390}, "rf": {"yaw": 398}, "lf": {"yaw": 354}})),
    ], markers={"contact": 16, "recover": 21}))
    lag(arm, ["Right", "Left", "RightElbow", "LeftElbow"], 2)

    # ------------------------------------- Heavy: driving front (push) kick
    acts.append(clip(arm, "Lion.Heavy", [
        (0, STANCE),
        (10, s({"root": {"y": -.82, "z": .3, "pitch": 14}, "torso": {"pitch": 10}, "head": {"pitch": -10},
                 "ra": {"raise": 36, "out": 22, "elbow": 104}, "la": {"raise": 60, "out": 12, "elbow": 92}, "lf": {"z": -1.0}})),
        (14, s({"root": {"y": -.5, "z": -.1, "pitch": 0}, "rl": {"lift": 86, "knee": 120, "ankle": -10},
                 "ra": {"raise": 10, "out": 30, "elbow": 70}, "la": {"raise": 66, "out": -4, "elbow": 100}, "lf": {"z": -1.1}})),
        (18, s({"root": {"y": -.3, "z": -.65, "pitch": -16}, "torso": {"pitch": -8, "yaw": -8}, "head": {"pitch": 12},
                 "ra": {"raise": -22, "out": 42, "elbow": 38}, "la": {"raise": 72, "out": -12, "elbow": 102},
                 "rl": {"lift": 98, "out": 4, "knee": 2, "ankle": -32}, "lf": {"z": -1.25, "toe": -12}}), "LINEAR"),
        (25, s({"root": {"y": -.33, "z": -.68, "pitch": -13}, "torso": {"pitch": -6, "yaw": -8},
                 "ra": {"raise": -18, "out": 40, "elbow": 40}, "la": {"raise": 70, "out": -10, "elbow": 100},
                 "rl": {"lift": 90, "knee": 10, "ankle": -28}, "lf": {"z": -1.25}})),
        (34, s({"root": {"y": -.55, "z": -.3}, "rl": {"lift": 46, "knee": 80}, "lf": {"z": -1.1}})),
        (46, STANCE),
    ], markers={"contact": 18, "recover": 25}))
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
