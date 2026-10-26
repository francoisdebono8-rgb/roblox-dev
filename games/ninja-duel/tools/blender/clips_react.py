"""Defence, reactions and pursuit for each fighter, authored in Blender.

Clip set per fighter id F (runtime names):
  F.Guard            loop: forearms crossed, weight down
  F.Guard.Impact     a blow absorbed on the guard
  F.Hit.Head         struck in the face (blow from the right; mirrored in game)
  F.Hit.Body         struck in the body from the front: folds over it
  F.Hit.Side         struck on the right side: bends away (mirrored in game)
  F.Hit.Back         struck from behind: arches
  F.Hit.Legs         low blow: the knee buckles
  F.Knockback        thrown back off the feet (ends on the flying pose)
  F.Knockback.Land   the skid and recovery once the feet find the floor
  F.Launched         launched: whip, fold, carried up (loops its tail)
  F.Knockdown        falling to the floor
  F.Down             lying, breathing (loop)
  F.Getup            back onto the feet into the stance
  F.Dash.F           forward dodge: push, low glide, brake
  F.Cartwheel        side dodge body shape under the engine's roll
  F.Handspring       back dodge body shape under the engine's pitch
  F.Chase            the dash after a launched body (loop)
Reactions peak within two or three frames, then recover: the hit reads at
once, the recovery tells how hard it was.
"""
from nd_anim import merge
from nd_cycle import arc, bake, add

LYING = {"root": {"y": -2.45, "z": .6, "pitch": -84, "roll": 14}, "torso": {"pitch": -8, "roll": 6}, "head": {"pitch": -14, "yaw": 20},
         "ra": {"raise": 20, "out": 62, "elbow": 24}, "la": {"raise": 14, "out": 56, "elbow": 30},
         "rl": {"lift": 18, "out": 8, "knee": 30}, "ll": {"lift": 6, "out": 10, "knee": 12}}


def feet(stance):
    return {"rf": dict(stance["rf"]), "lf": dict(stance["lf"])}


def hits(stance):
    s = lambda over: merge(stance, over)
    out = {}
    # Face, from the right: the head whips away and back, the chest follows
    # over the hips, the arms fly open; one step of recovery.
    out["Head"] = [(0, stance),
                   (.1, s({"root": {"y": stance["root"]["y"] - .25, "z": .55, "pitch": -12, "yaw": stance["root"]["yaw"] + 18, "roll": -9},
                           "torso": {"pitch": -22, "yaw": 26, "roll": -10}, "head": {"pitch": -38, "yaw": 56, "roll": 22},
                           "ra": {"raise": -6, "out": 74, "twist": 0, "elbow": 36}, "la": {"raise": -4, "out": 70, "twist": 0, "elbow": 34}}), "snap"),
                   (.3, s({"root": {"y": stance["root"]["y"] - .2, "z": .45, "pitch": -6, "yaw": stance["root"]["yaw"] + 12},
                           "torso": {"pitch": -12, "yaw": 16}, "head": {"pitch": -18, "yaw": 30, "roll": 10},
                           "ra": {"raise": 20, "out": 46, "elbow": 50}, "la": {"raise": 22, "out": 44, "elbow": 50}})),
                   (1, stance)]
    # Body, from the front: hips driven back, the chest folds hard over the
    # blow, the head goes down with it, the arms wrap the stomach.
    out["Body"] = [(0, stance),
                   (.1, s({"root": {"y": stance["root"]["y"] - .5, "z": .8, "pitch": 16, "yaw": stance["root"]["yaw"] + 10},
                           "torso": {"pitch": 46, "yaw": 14}, "head": {"pitch": 30},
                           "ra": {"raise": 52, "out": -14, "twist": 10, "elbow": 128}, "la": {"raise": 46, "out": -12, "twist": 10, "elbow": 124}}), "snap"),
                   (.35, s({"root": {"y": stance["root"]["y"] - .4, "z": .6, "pitch": 14}, "torso": {"pitch": 32}, "head": {"pitch": 16},
                            "ra": {"raise": 44, "out": -6, "elbow": 112}, "la": {"raise": 40, "out": -6, "elbow": 110}})),
                   (1, stance)]
    # Side, from the right: bends and turns away from the blow.
    out["Side"] = [(0, stance),
                   (.1, s({"root": {"y": stance["root"]["y"] - .35, "z": .4, "roll": -22, "yaw": stance["root"]["yaw"] - 28},
                           "torso": {"roll": -22, "yaw": -30, "pitch": 12}, "head": {"roll": -18, "yaw": -28},
                           "ra": {"raise": 20, "out": 66, "elbow": 50}, "la": {"raise": 18, "out": 64, "elbow": 48}}), "snap"),
                   (.35, s({"root": {"y": stance["root"]["y"] - .25, "z": .3, "roll": -12, "yaw": stance["root"]["yaw"] - 16},
                            "torso": {"roll": -12, "yaw": -16, "pitch": 8}, "head": {"roll": -8, "yaw": -14},
                            "ra": {"raise": 30, "out": 40, "elbow": 60}, "la": {"raise": 30, "out": 40, "elbow": 60}})),
                   (1, stance)]
    # Back: the blow arches the spine, the head is thrown back, arms behind.
    out["Back"] = [(0, stance),
                   (.1, s({"root": {"y": stance["root"]["y"] - .3, "z": -.5, "pitch": -14}, "torso": {"pitch": -28}, "head": {"pitch": -36},
                           "ra": {"raise": -40, "out": 40, "elbow": 30}, "la": {"raise": -36, "out": 38, "elbow": 30}}), "snap"),
                   (.35, s({"root": {"y": stance["root"]["y"] - .2, "z": -.35, "pitch": 4}, "torso": {"pitch": -6}, "head": {"pitch": -8},
                            "ra": {"raise": 10, "out": 30, "elbow": 50}, "la": {"raise": 10, "out": 30, "elbow": 50}})),
                   (1, stance)]
    # Legs: the struck knee buckles, the body drops toward it, arms out.
    out["Legs"] = [(0, stance),
                   (.12, s({"root": {"y": stance["root"]["y"] - .85, "roll": 18, "pitch": 12}, "torso": {"pitch": 14, "roll": -14}, "head": {"pitch": 10, "yaw": 12},
                            "ra": {"raise": 52, "out": 58, "elbow": 40}, "la": {"raise": 48, "out": 58, "elbow": 38},
                            "rf": {"z": stance["rf"]["z"] + .2, "toe": -30}}), "snap"),
                   (.4, s({"root": {"y": stance["root"]["y"] - .5, "roll": 8}, "torso": {"pitch": 8}, "ra": {"raise": 40, "out": 30}, "la": {"raise": 40, "out": 30}})),
                   (1, stance)]
    return out


def guard(stance):
    g = merge(stance, {"root": {"y": stance["root"]["y"] - .15, "pitch": 8}, "torso": {"pitch": 10, "yaw": -4}, "head": {"pitch": 12},
                       "ra": {"raise": 92, "out": -34, "twist": 42, "elbow": 114, "wrist": -10},
                       "la": {"raise": 96, "out": -30, "twist": 40, "elbow": 110, "wrist": -10}})
    breathe = add(g, {"root": {"y": -.03}, "torso": {"pitch": 1.5}, "ra": {"elbow": 2}, "la": {"elbow": 2}})
    impact = merge(g, {"root": {"y": g["root"]["y"] - .25, "z": .45, "pitch": 2}, "torso": {"pitch": -2}, "head": {"pitch": 18},
                       "ra": {"raise": 84, "elbow": 122}, "la": {"raise": 88, "elbow": 118},
                       "lf": {"z": stance["lf"]["z"] + .25}})
    return g, breathe, impact


def author(arm, fighter, stance):
    F = fighter + "."
    acts = []
    g, breathe, impact = guard(stance)
    acts.append(arc(arm, F + "Guard", [(0, g), (.5, breathe), (1, g)], 72, loop=True))
    acts.append(arc(arm, F + "Guard.Impact", [(0, g), (.15, impact, "snap"), (1, g)], 24))
    for name, keys in hits(stance).items():
        acts.append(arc(arm, F + "Hit." + name, keys, 24 if name != "Legs" else 30))
    # Thrown back: the hips go first, the chest is thrown back almost flat,
    # arms and legs trailing toward the striker; held while it flies.
    fly = {"root": {"y": 0, "pitch": -52, "roll": 6}, "torso": {"pitch": -24, "yaw": 8}, "head": {"pitch": 10},
           "ra": {"raise": 106, "out": 50, "elbow": 30}, "la": {"raise": 96, "out": 46, "elbow": 28},
           "rl": {"lift": 50, "knee": 44}, "ll": {"lift": 22, "knee": 30}}
    fly2 = add(fly, {"root": {"pitch": -4}, "ra": {"raise": 8, "elbow": 6}, "la": {"raise": -6, "elbow": 10}, "rl": {"lift": -8}, "ll": {"lift": 8}})
    hit0 = merge(stance, {"rl": {"lift": 10, "knee": 20}, "ll": {"lift": 0, "knee": 10}})
    hit0.pop("rf", None); hit0.pop("lf", None)
    acts.append(arc(arm, F + "Knockback", [(0, hit0), (.15, fly, "snap"), (.6, fly2), (1, fly)], 36,
                    markers={"loop": 12}))
    skid = merge(stance, {"root": {"y": stance["root"]["y"] - .7, "pitch": -10, "z": .3}, "torso": {"pitch": -6}, "head": {"pitch": 6},
                          "ra": {"raise": 60, "out": 50, "elbow": 40}, "la": {"raise": 56, "out": 48, "elbow": 40},
                          "rf": {"z": stance["rf"]["z"] + .3}, "lf": {"z": stance["lf"]["z"] - .3}})
    acts.append(arc(arm, F + "Knockback.Land", [(0, skid), (.2, add(skid, {"root": {"y": -.2}}), "snap"), (.55, merge(stance, {"root": {"y": stance["root"]["y"] - .3}})), (1, stance)], 24))
    whip = {"root": {"pitch": -30}, "torso": {"pitch": -46}, "head": {"pitch": -56},
            "ra": {"raise": -20, "out": 40, "elbow": 30}, "la": {"raise": -20, "out": 38, "elbow": 26}, "rl": {"lift": 10, "knee": 30}, "ll": {"lift": -10, "knee": 20}}
    folded = {"root": {"pitch": -16, "roll": 8}, "torso": {"pitch": -22, "yaw": 14}, "head": {"pitch": -20},
              "ra": {"raise": -40, "out": 44, "elbow": 32}, "la": {"raise": -36, "out": 40, "elbow": 26}, "rl": {"lift": 36, "knee": 64}, "ll": {"lift": -4, "knee": 36}}
    trail = add(folded, {"ra": {"raise": 14, "out": 6}, "la": {"raise": -10}, "rl": {"lift": -12, "knee": 10}, "ll": {"lift": 12, "knee": -8}, "torso": {"roll": 6}})
    acts.append(arc(arm, F + "Launched", [(0, whip), (.25, folded), (.6, trail), (1, folded)], 48, markers={"loop": 12}))
    acts.append(arc(arm, F + "Knockdown", [(0, merge(hit0, {"root": {"pitch": -10}})),
                                           (.4, {"root": {"pitch": -40, "roll": 10, "y": -.4}, "torso": {"pitch": -16}, "head": {"pitch": 10},
                                                 "ra": {"raise": 80, "out": 58, "elbow": 34}, "la": {"raise": 70, "out": 54, "elbow": 30},
                                                 "rl": {"lift": 40, "knee": 56}, "ll": {"lift": 18, "knee": 40}}),
                                           (1, merge(LYING, {"root": {"y": -1.6}}))], 24))
    acts.append(arc(arm, F + "Down", [(0, LYING), (.5, add(LYING, {"torso": {"pitch": -3}, "head": {"pitch": -3}, "ra": {"elbow": 4}})), (1, LYING)], 90, loop=True))
    kneel = {"root": {"y": -1.5, "pitch": 30, "z": .2}, "torso": {"pitch": 20}, "head": {"pitch": -14},
             "ra": {"raise": 40, "out": 24, "elbow": 60}, "la": {"raise": -10, "out": 30, "elbow": 20}, "lf": {"z": -.8}, "rf": {"z": .8, "y": .0, "toe": -40}}
    sit = {"root": {"y": -2.1, "z": .4, "pitch": -40, "roll": 6}, "torso": {"pitch": 24}, "head": {"pitch": 10},
           "ra": {"raise": -30, "out": 30, "elbow": 10}, "la": {"raise": -30, "out": 34, "elbow": 10}, "rl": {"lift": 60, "knee": 100}, "ll": {"lift": 30, "knee": 60}}
    acts.append(arc(arm, F + "Getup", [(0, LYING), (.3, sit), (.6, kneel), (1, stance)], 24))
    # Forward dodge: push off, low glide, brake.
    load = merge(stance, {"root": {"y": -1.2, "pitch": 22, "yaw": 0}, "torso": {"pitch": 14, "yaw": 0}, "head": {"pitch": -18, "yaw": 0},
                          "ra": {"raise": 20, "out": 24, "elbow": 60}, "la": {"raise": 30, "out": 24, "elbow": 70}, "lf": {"z": -.5, "x": 0}, "rf": {"z": 1.5, "x": 0, "toe": -30}})
    glide = merge(stance, {"root": {"y": -1.0, "pitch": 40, "yaw": 0}, "torso": {"pitch": 12, "yaw": 0}, "head": {"pitch": -34, "yaw": 0},
                           "ra": {"raise": -50, "out": 20, "elbow": 14}, "la": {"raise": -50, "out": 20, "elbow": 14}, "lf": {"z": -1.3, "x": 0}, "rf": {"z": 1.3, "y": .25, "x": 0, "toe": -24}})
    brake = merge(stance, {"root": {"y": -.95, "pitch": 6}, "torso": {"pitch": 4}, "ra": {"raise": 46, "out": 40, "elbow": 40}, "la": {"raise": 52, "out": 36, "elbow": 50},
                           "lf": {"z": -.9}, "rf": {"z": 1.0}})
    acts.append(arc(arm, F + "Dash.F", [(0, load), (.25, glide, "snap"), (.75, add(glide, {"root": {"y": .05}})), (1, brake)], 20))
    # Acrobatic dodges: only the body shape; the engine turns it over.
    cart = [(0, {"root": {"y": -.5}, "ra": {"raise": 60, "out": 60, "elbow": 20}, "la": {"raise": 60, "out": 60, "elbow": 20}, "rl": {"lift": 20, "out": 30, "knee": 20}, "ll": {"lift": 10, "out": 20, "knee": 10}}),
            (.35, {"root": {"y": -.3}, "torso": {"pitch": 4}, "ra": {"raise": 170, "out": 30, "elbow": 6}, "la": {"raise": 170, "out": 30, "elbow": 6}, "rl": {"lift": 10, "out": 80, "knee": 6}, "ll": {"lift": 10, "out": 80, "knee": 6}}),
            (.7, {"root": {"y": -.3}, "ra": {"raise": 160, "out": 40, "elbow": 10}, "la": {"raise": 160, "out": 40, "elbow": 10}, "rl": {"lift": 10, "out": 70, "knee": 10}, "ll": {"lift": 10, "out": 74, "knee": 14}}),
            (1, {"root": {"y": -.7, "pitch": 10}, "torso": {"pitch": 6}, "ra": {"raise": 50, "out": 50, "elbow": 40}, "la": {"raise": 50, "out": 50, "elbow": 40}, "rl": {"lift": 40, "out": 20, "knee": 60}, "ll": {"lift": 20, "out": 20, "knee": 50}})]
    acts.append(arc(arm, F + "Cartwheel", cart, 20))
    hand = [(0, {"root": {"y": -.6, "pitch": -6}, "torso": {"pitch": -8}, "head": {"pitch": 14}, "ra": {"raise": 120, "out": 20, "elbow": 30}, "la": {"raise": 120, "out": 20, "elbow": 30}, "rl": {"lift": 20, "knee": 60}, "ll": {"lift": 10, "knee": 50}}),
            (.35, {"root": {"y": -.4}, "torso": {"pitch": -18}, "head": {"pitch": 30}, "ra": {"raise": 172, "out": 22, "elbow": 6}, "la": {"raise": 172, "out": 22, "elbow": 6}, "rl": {"lift": 30, "knee": 20}, "ll": {"lift": 50, "knee": 40}}),
            (.7, {"root": {"y": -.4}, "torso": {"pitch": -6}, "head": {"pitch": 16}, "ra": {"raise": 160, "out": 26, "elbow": 14}, "la": {"raise": 160, "out": 26, "elbow": 14}, "rl": {"lift": 70, "knee": 40}, "ll": {"lift": 80, "knee": 50}}),
            (1, {"root": {"y": -.8, "pitch": 14}, "torso": {"pitch": 10}, "head": {"pitch": -10}, "ra": {"raise": 60, "out": 40, "elbow": 50}, "la": {"raise": 60, "out": 40, "elbow": 50}, "rl": {"lift": 60, "knee": 90}, "ll": {"lift": 40, "knee": 80}})]
    acts.append(arc(arm, F + "Handspring", hand, 20))
    # The chase: a flat ninja dash, legs cycling under, arms swept back.
    def chase(u):
        import math
        sw = math.sin(2 * math.pi * u)
        return {"root": {"pitch": 50, "y": -.2 + .06 * abs(sw)}, "torso": {"pitch": 14}, "head": {"pitch": -50},
                "ra": {"raise": -72 + 4 * sw, "out": 18, "twist": -10, "elbow": 10}, "la": {"raise": -72 - 4 * sw, "out": 18, "twist": -10, "elbow": 10},
                "rl": {"lift": 40 + 34 * sw, "knee": 60 - 24 * sw, "ankle": -20}, "ll": {"lift": 40 - 34 * sw, "knee": 60 + 24 * sw, "ankle": -20}}
    acts.append(bake(arm, F + "Chase", chase, 24, 2, True, None, {"rate": 3.0}))
    return acts
