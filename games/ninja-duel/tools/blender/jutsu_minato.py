"""Minato's seal jutsu (04/11, user: his seal jutsu repeated his kunai and his
teleports; « fais-moi de belles animations »). Authored on his body
(clips_flash2.STANCE: upright, light, the kunai in reverse grip low in the
right hand). Each jutsu opens with its two seals (nd_seals), then the act:

  BurstStrike.Channel   tiger - snake, then the right palm opens upward at
                        the hip and the spiral is shaped in it, the left hand
                        cupped over it (he is still inventing it: one-handed,
                        the left hand steadying it, eyes on it)
  SealingTrap.*         snake - ram, then down onto the front knee and the
                        palm slapped flat on the floor: the formula runs out
                        from under it to the point he chose
  SpaceTimeBarrier.*    a snapped tiger, then both palms thrown open toward
                        the threat, the stance wide and low, held while the
                        barrier stands (the jutsu's recovery is its window)
  FlashTouch            Flying Thunder God level two: no wind-up, the lead
                        hand laid flat on the body (the formula is in the
                        palm), the weight following it in

Server timings (Shared/SealJutsu, Shared/Attacks):
  BurstStrike  channel .42      SealingTrap  channel .32 act .1 rec .26
  SpaceTimeBarrier channel .04 act .04 rec .7      FlashTouch .06 / .1 / .24
"""
from nd_shot import Shot, merge
from clips_flash2 import STANCE, s
import nd_seals

N = "Flashstep."
# Reverse grip at rest: the right hand keeps the kunai along the forearm.
PALM_R = {"raise": 90, "out": -2, "twist": 72, "elbow": 2, "wrist": -62}
PALM_L = {"raise": 90, "out": -4, "twist": -72, "elbow": 2, "wrist": -62}


def rasengan_channel(arm):
    sh = Shot(arm, N + "BurstStrike.Channel")
    sh.key(0, s(), "ease")
    base = s({"root": {"y": -.5, "pitch": 6}, "head": {"pitch": 8, "yaw": -4}})
    last = nd_seals.weave(sh, 0, (1, 2), base, beat=5)
    # The palm opens upward at the hip, in front of him; the left hand comes
    # over it, cupped: the spiral is shaped between the two.
    shape = s({"root": {"y": -.62, "z": .05, "pitch": 12, "yaw": 14}, "torso": {"pitch": 14, "yaw": -14},
               "head": {"pitch": 22, "yaw": -10},
               "ra": {"raise": 54, "out": 2, "twist": -88, "elbow": 92, "wrist": 6},
               "la": {"raise": 40, "out": -30, "twist": 44, "elbow": 112, "wrist": 40},
               "rf": {"x": .3, "z": .9, "yaw": 38}, "lf": {"x": -.1, "z": -.8, "yaw": -4}})
    sh.key(last + 6, shape, "ease")
    # It grows: the hands part a little, the chest lifts as the chakra spins.
    grow = merge(shape, {"root": {"y": -.58}, "torso": {"pitch": 10},
                         "la": {"raise": 48, "elbow": 104, "wrist": 46}, "ra": {"raise": 56, "elbow": 86}})
    sh.key(last + 12, grow, "ease")
    sh.drag(["neck"], 2)
    sh.drag(["shoulder.L", "forearm.L", "hand.L"], 1)
    return sh.build(markers={"release": (last + 12) / 60})


def sealing_trap(arm):
    out = []
    ch = Shot(arm, N + "SealingTrap.Channel")
    ch.key(0, s(), "ease")
    base = s({"root": {"y": -.48}, "head": {"pitch": 6}})
    last = nd_seals.weave(ch, 0, (2, 3), base, beat=5)
    # Down onto the front leg, the right hand leaving the seal to reach for
    # the floor in front (the left keeps half the ram at the chest).
    reach = s({"root": {"y": -1.12, "z": -.18, "pitch": 32, "yaw": 8}, "torso": {"pitch": 22, "yaw": -6},
               "head": {"pitch": -16, "yaw": -4},
               "ra": {"raise": 26, "out": 8, "twist": 4, "elbow": 22, "wrist": -66},
               "la": {"raise": 58, "out": -32, "twist": 36, "elbow": 118, "wrist": 10},
               "lf": {"x": -.12, "z": -1.02, "yaw": -6}, "rf": {"x": .26, "z": .98, "yaw": 30, "toe": -30}})
    ch.key(last + 6, reach, "ease")
    ch.key(last + 9, merge(reach, {"root": {"y": -1.22}, "ra": {"raise": 14, "elbow": 14}}), "pass")
    ch.drag(["neck"], 1)
    out.append(ch.build(markers={"release": (last + 9) / 60}))

    re = Shot(arm, N + "SealingTrap.Release")
    slap = merge(reach, {"root": {"y": -1.3, "z": -.22, "pitch": 36}, "torso": {"pitch": 26},
                         "ra": {"raise": 6, "out": 6, "elbow": 8, "wrist": -78}})
    re.key(0, merge(reach, {"root": {"y": -1.22}, "ra": {"raise": 14, "elbow": 14}}), "ease")
    re.key(2, slap, "impact")
    # the shoulders give a little with the slap, then press
    re.key(5, merge(slap, {"root": {"y": -1.34}, "torso": {"pitch": 28}}), "ease")
    re.key(8, merge(slap, {"root": {"y": -1.32}}), "ease")
    out.append(re.build(markers={"release": 2 / 60}))

    rc = Shot(arm, N + "SealingTrap.Recover")
    rc.key(0, merge(slap, {"root": {"y": -1.32}}), "ease")
    rc.key(6, s({"root": {"y": -.86, "z": -.08, "pitch": 18}, "torso": {"pitch": 12},
                 "ra": {"raise": 22, "out": 16, "twist": 20, "elbow": 70, "wrist": -24},
                 "la": {"raise": 52, "out": 0, "elbow": 82},
                 "lf": {"x": -.1, "z": -.9}, "rf": {"x": .24, "z": .86}}), "pass")
    rc.key(16, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


def space_time_barrier(arm):
    out = []
    ch = Shot(arm, N + "SpaceTimeBarrier.Channel")
    ch.key(0, s(), "ease")
    ch.key(3, s(merge({"root": {"y": -.5}}, nd_seals.seal(1))), "impact")
    out.append(ch.build(markers={"release": 3 / 60}))

    wide = {"root": {"y": -.74, "z": .12, "pitch": -2, "yaw": 0}, "torso": {"pitch": 8, "yaw": 0}, "head": {"pitch": -8, "yaw": 0},
            "rf": {"x": .62, "z": .5, "yaw": 26}, "lf": {"x": -.5, "z": -.55, "yaw": -18}}
    open_ = s(merge(wide, {"ra": PALM_R, "la": PALM_L}))
    re = Shot(arm, N + "SpaceTimeBarrier.Release")
    re.key(0, s(merge({"root": {"y": -.5}}, nd_seals.seal(1))), "ease")
    re.key(3, merge(open_, {"root": {"y": -.78, "z": .1}}), "impact")
    re.key(6, open_, "ease")
    out.append(re.build(markers={"release": 3 / 60}))

    rc = Shot(arm, N + "SpaceTimeBarrier.Recover")
    rc.key(0, open_, "ease")
    # held: the palms press against something unseen, the body breathes
    rc.key(14, merge(open_, {"root": {"y": -.76}, "ra": {"raise": 92, "elbow": 6}, "la": {"raise": 92, "elbow": 6}}), "ease")
    rc.key(28, merge(open_, {"root": {"y": -.7}, "torso": {"pitch": 4}}), "ease")
    rc.key(42, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


def flash_touch(arm):
    sh = Shot(arm, N + "FlashTouch")
    sh.key(0, s(), "ease")
    touch = s({"root": {"y": -.5, "z": -.36, "pitch": 16, "yaw": -18}, "torso": {"pitch": 10, "yaw": 22}, "head": {"pitch": -4, "yaw": 16},
               "la": {"raise": 92, "out": 2, "twist": -76, "elbow": 6, "wrist": -64},
               "ra": {"raise": 30, "out": 24, "twist": 28, "elbow": 96, "wrist": -24},
               "lf": {"x": -.04, "z": -1.08, "yaw": -12}, "rf": {"x": .26, "z": .74, "yaw": 34}})
    sh.key(4, touch, "impact")
    # the palm stays on the body a beat (the formula takes), the weight follows
    sh.key(8, merge(touch, {"root": {"z": -.46, "y": -.54}, "la": {"raise": 90, "elbow": 2}}), "ease")
    sh.key(13, merge(touch, {"root": {"z": -.4}, "la": {"raise": 84, "elbow": 14}}), "ease")
    sh.key(24, s(), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.R", "forearm.R", "hand.R"], 2)
    return sh.build(markers={"contact": 4 / 60, "recover": 10 / 60})


def light4(arm):
    """The string's third hit (L1 cross cut, L2 lead palm, L4, L3 spinning
    kick): the reverse-grip blade rising. He sinks with the palm's recoil, the
    blade low by the inside hip, then rises out of it in one line - a short
    step through, the chest lifting, the kunai carried up the centre and out
    over his right shoulder. Vertical where his first cut is flat; it leaves
    the hips turned for the spin that follows. Light4 = .09 / .12 / .28."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.62, "z": -.08, "pitch": 20, "yaw": 30}, "torso": {"pitch": 12, "yaw": -20}, "head": {"pitch": -12, "yaw": -6},
              "ra": {"raise": -4, "out": -20, "twist": 70, "elbow": 66, "wrist": -40},
              "la": {"raise": 62, "out": -4, "twist": 10, "elbow": 92},
              "lf": {"z": -.92, "y": .08, "toe": -10}})
    sh.key(3, load, "ease")
    hit = s({"travel": {"z": -.4}, "root": {"y": -.36, "z": -.12, "pitch": -2, "yaw": 8, "roll": -4}, "torso": {"pitch": -6, "yaw": 18},
             "head": {"pitch": -14, "yaw": -8},
             "ra": {"raise": 110, "out": 12, "twist": -18, "elbow": 18, "wrist": 22},
             "la": {"raise": 40, "out": 22, "twist": 20, "elbow": 104},
             "lf": {"z": -1.12, "y": 0}, "rf": {"toe": -22}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"y": -.32}, "torso": {"yaw": 22}, "ra": {"raise": 142, "out": 30, "elbow": 12}}), "ease")
    # the blade comes back down outside, the back foot follows the step
    sh.key(16, s({"travel": {"z": -.4}, "root": {"y": -.46, "z": -.12}, "ra": {"raise": 64, "out": 30, "twist": 10, "elbow": 74, "wrist": -14},
                  "lf": {"z": -1.12}, "rf": {"z": .58, "y": .12, "toe": -14}}), "pass")
    sh.key(29, merge(s({"travel": {"z": -.4}}), {"lf": {"z": -1.12}, "rf": {"z": .38}}), "ease")
    sh.drag(["neck"], 1)
    sh.drag(["shoulder.R", "forearm.R", "hand.R"], 1)
    return sh.build(markers={"contact": 5 / 60, "recover": 13 / 60})


def author(arm):
    acts = [rasengan_channel(arm)]
    acts += sealing_trap(arm)
    acts += space_time_barrier(arm)
    acts.append(flash_touch(arm))
    acts.append(light4(arm))
    return acts
