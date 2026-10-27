"""Sasuke (Lion), authored on the control rig (nd_ctrl / nd_shot), DEC-028.

Every clip is blocked pose to pose: what carries the weight, what starts the
motion, what follows late, where the spacing is fastest and where the body
absorbs. Feet are WORLD positions (Roblox axes: x right of the rest foot,
z back, y lift); a planted foot is the same value on consecutive keys, so it
cannot slide. The root bone ("travel") is the body's real displacement;
export plays it in place (the server owns travel).

Reasoning per clip is written next to its keys (the competency gate,
docs/research/ANIMATION_CRAFT.md).
"""
from nd_shot import Shot, cycle, merge, mirror

# The fighting stance. Low, coiled, left lead: hips turned 30 deg right so
# the left side faces the opponent, chest slightly less (it squares up to see),
# lead hand out at chin height, rear hand guarding the jaw. Weight 55% on
# the front foot (hips slightly ahead of centre: root z -.08).
STANCE = {"root": {"y": -.5, "z": -.08, "pitch": 10, "yaw": 30}, "torso": {"pitch": 6, "yaw": -14},
          "head": {"pitch": -6, "yaw": -16},
          "la": {"raise": 66, "out": 6, "twist": 10, "elbow": 64}, "ra": {"raise": 52, "out": -16, "twist": 24, "elbow": 118},
          "rf": {"x": .26, "z": .84, "yaw": 38}, "lf": {"x": -.1, "z": -.76, "yaw": -6}}


def s(over):
    return merge(STANCE, over)


def idle(arm):
    """Exercise 1 - weight shift. The weight rocks from the front foot to the
    back foot and back (2.4 s). The hips lead (they carry the centre of mass
    over the support foot), the chest follows 3 frames later, the head stays
    level on the opponent (it counters). On the back foot the rear hip rises
    and the knees load; the hands drift a little with the chest."""
    sh = Shot(arm, "Lion.Idle")
    sh.key(0, s({}), "ease")
    # Weight back: hips over the rear foot, rear knee loads (hips lower), front
    # heel light. Chest sits back a touch.
    sh.key(72, s({"root": {"y": -.56, "z": .1, "pitch": 7, "yaw": 33, "roll": 2}, "torso": {"pitch": 4},
                  "head": {"pitch": -4}, "la": {"raise": 63, "elbow": 68}, "ra": {"raise": 50, "elbow": 121},
                  "lf": {"toe": 6}}), "ease")
    sh.key(144, s({}), "ease")
    sh.drag(["spine"], 3).drag(["neck", "shoulder.L", "shoulder.R"], 5)
    return sh.build(loop=True)


# ------------------------------------------------------------ locomotion
def run(arm):
    """The run (19 studs/s). Stride 10 studs per cycle, 32 frames: each foot
    holds the floor for 22% of the cycle (2.2 studs under the body), then a
    flight phase. Poses of the right step:
      contact: the foot lands ahead of the hip on the midfoot, knee soft;
      down (2 f later): lowest point, the stance knee absorbs, the free heel
        folds up behind;
      passing: the free knee drives through under the hips;
      toe-off: the stance leg extends behind, the body rises;
      peak: both feet off, the trailing heel kicks up, the lead leg reaches.
    The pelvis turns with the forward leg, the chest counters it, the arms
    swing opposite to the legs (left arm forward with the right foot)."""
    half = [
        (0.0, {"root": {"y": -.44, "pitch": 15, "yaw": -8}, "torso": {"pitch": 6, "yaw": 12}, "head": {"pitch": -14, "yaw": -4},
               "rf": {"x": .02, "z": -1.0, "toe": 6}, "lf": {"x": -.04, "z": 1.15, "y": .62, "toe": -42},
               "la": {"raise": 46, "out": 10, "twist": 10, "elbow": 84}, "ra": {"raise": -34, "out": 14, "elbow": 66}}, "impact"),
        (0.07, {"root": {"y": -.6, "pitch": 16, "yaw": -6}, "torso": {"pitch": 8, "yaw": 9}, "head": {"pitch": -15, "yaw": -3},
                "lf": {"x": -.04, "z": .55, "y": 1.0, "toe": -52},
                "la": {"raise": 40, "out": 10, "elbow": 88}, "ra": {"raise": -28, "out": 14, "elbow": 70}}, "ease"),
        (0.15, {"root": {"y": -.5, "pitch": 16, "yaw": -1}, "torso": {"pitch": 7, "yaw": 3},
                "lf": {"x": -.04, "z": -.35, "y": 1.02, "toe": -30, "knee": 4},
                "la": {"raise": 22, "elbow": 86}, "ra": {"raise": -6, "elbow": 74}}, "pass"),
        (0.22, {"root": {"y": -.38, "pitch": 16, "yaw": 5}, "torso": {"pitch": 6, "yaw": -4},
                "lf": {"x": -.03, "z": -.95, "y": .8, "toe": -8},
                "la": {"raise": -4, "elbow": 80}, "ra": {"raise": 22, "elbow": 80}}, "launch"),
        (0.34, {"root": {"y": -.32, "pitch": 15, "yaw": 8}, "torso": {"pitch": 6, "yaw": -11}, "head": {"pitch": -14, "yaw": 4},
                "rf": {"x": .03, "z": 1.3, "y": .55, "toe": -46}, "lf": {"x": -.03, "z": -1.2, "y": .32, "toe": 2},
                "la": {"raise": -30, "elbow": 68}, "ra": {"raise": 42, "elbow": 84}}, "pass"),
        (0.45, {"root": {"y": -.38, "pitch": 15, "yaw": 8}, "torso": {"pitch": 6, "yaw": -12},
                "rf": {"x": .04, "z": 1.12, "y": .66, "toe": -44}, "lf": {"x": -.02, "z": -1.04, "y": .06, "toe": 6},
                "la": {"raise": -34, "elbow": 66}, "ra": {"raise": 46, "elbow": 84}}, "ease"),
    ]
    sh = cycle(arm, "Lion.Run.F", 10.0, 32, half, .22)
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R", "forearm.L", "forearm.R"], 1)
    return sh.build(loop=True, meta={"stride": 10.0})


def sprint(arm):
    """The ninja run (45 studs/s): chest thrown forward over the feet, arms
    swept back and still (they would brake the body), the head up to see.
    Stride 14, 20 frames, the foot holds the floor 18% (2.5 studs); the legs
    cycle hard - heel to the seat behind, knee high in front."""
    arms = {"la": {"raise": -62, "out": 16, "twist": -12, "elbow": 12}, "ra": {"raise": -62, "out": 16, "twist": -12, "elbow": 12}}
    half = [
        (0.0, merge(arms, {"root": {"y": -.72, "pitch": 32, "yaw": -6}, "torso": {"pitch": 20, "yaw": 7}, "head": {"pitch": -44, "yaw": -3},
                           "rf": {"x": .04, "z": -1.0, "toe": 4}, "lf": {"x": -.04, "z": 1.3, "y": .9, "toe": -56}}), "impact"),
        (0.06, merge(arms, {"root": {"y": -.84, "pitch": 33, "yaw": -4}, "torso": {"pitch": 22, "yaw": 5},
                            "lf": {"x": -.04, "z": .5, "y": 1.35, "toe": -60}}), "ease"),
        (0.18, merge(arms, {"root": {"y": -.66, "pitch": 32, "yaw": 3}, "torso": {"pitch": 21, "yaw": -2},
                            "lf": {"x": -.03, "z": -1.05, "y": 1.1, "toe": -20},
                            "la": {"raise": -58}, "ra": {"raise": -66}}), "launch"),
        (0.32, merge(arms, {"root": {"y": -.58, "pitch": 31, "yaw": 6}, "torso": {"pitch": 20, "yaw": -6}, "head": {"pitch": -44, "yaw": 3},
                            "rf": {"x": .04, "z": 1.5, "y": .7, "toe": -52}, "lf": {"x": -.03, "z": -1.3, "y": .45, "toe": -4},
                            "la": {"raise": -60}, "ra": {"raise": -64}}), "pass"),
        (0.45, merge(arms, {"root": {"y": -.64, "pitch": 32, "yaw": 6}, "torso": {"pitch": 20, "yaw": -7},
                            "rf": {"x": .04, "z": 1.3, "y": .95, "toe": -56}, "lf": {"x": -.04, "z": -1.05, "y": .08, "toe": 4}}), "ease"),
    ]
    sh = cycle(arm, "Lion.Sprint", 14.0, 20, half, .18)
    sh.drag(["neck"], 1)
    return sh.build(loop=True, meta={"stride": 14.0})


# ----------------------------------------------------------------- air
def jump_air(arm):
    """Exercise 3 (air part). Time axis = arc progress: 0 take-off (rising
    fast), .5 apex, 1 falling fast just above the floor (the game picks the
    frame from the vertical speed). The body extends at take-off (the push is
    still in the legs: ankles pointed, arms thrown up), gathers at the top
    (knees up, a compact shape, the moment of weightlessness), then opens and
    the feet search for the floor: legs reach down and slightly forward, arms
    out for balance, head down to see the landing."""
    sh = Shot(arm, "Lion.Jump.Air")
    take = {"root": {"y": -.1, "pitch": 4, "yaw": 0}, "torso": {"pitch": -6, "yaw": 0}, "head": {"pitch": -16, "yaw": 0},
            "la": {"raise": 140, "out": 18, "twist": 0, "elbow": 26}, "ra": {"raise": 128, "out": 22, "twist": 0, "elbow": 30},
            "rf": {"x": 0, "z": .1, "y": -.25, "toe": -55, "yaw": 0}, "lf": {"x": 0, "z": .25, "y": -.15, "toe": -50, "yaw": 0}}
    rise = merge(take, {"root": {"y": -.3, "pitch": 8}, "torso": {"pitch": 4}, "head": {"pitch": -10},
                        "la": {"raise": 90, "out": 34, "elbow": 54}, "ra": {"raise": 84, "out": 36, "elbow": 58},
                        "rf": {"z": -.55, "y": .65, "toe": -30, "knee": 6}, "lf": {"z": .4, "y": .3, "toe": -46}})
    apex = merge(take, {"root": {"y": -.5, "pitch": 18}, "torso": {"pitch": 16}, "head": {"pitch": -24},
                        "la": {"raise": 62, "out": 44, "elbow": 92}, "ra": {"raise": 58, "out": 46, "elbow": 96},
                        "rf": {"z": -.7, "y": 1.25, "toe": -24, "knee": 10}, "lf": {"z": -.45, "y": 1.1, "toe": -26, "knee": 8}})
    fall = merge(take, {"root": {"y": -.25, "pitch": 8}, "torso": {"pitch": 6}, "head": {"pitch": -20},
                        "la": {"raise": 72, "out": 64, "elbow": 34}, "ra": {"raise": 66, "out": 66, "elbow": 36},
                        "rf": {"z": -.5, "y": .55, "toe": -14, "knee": 6}, "lf": {"z": .1, "y": .35, "toe": -18}})
    reach = merge(take, {"root": {"y": -.08, "pitch": 6}, "torso": {"pitch": 6}, "head": {"pitch": -18},
                         "la": {"raise": 46, "out": 70, "elbow": 22}, "ra": {"raise": 42, "out": 72, "elbow": 24},
                         "rf": {"x": .12, "z": -.45, "y": .1, "toe": -6, "knee": 4}, "lf": {"x": -.1, "z": .3, "y": 0, "toe": -10}})
    sh.key(0, take, "launch").key(12, rise, "pass").key(30, apex, "ease").key(46, fall, "pass").key(60, reach, "ease")
    sh.drag(["neck", "shoulder.L", "shoulder.R"], 2)
    return sh.build(meta={"axis": "arc"})


def land(arm):
    """Exercise 3 (landing). The feet were searching for the floor; the front
    foot touches first, the hips keep falling: the knees take it (deepest at
    frame 5, the chest folds forward over the knees so the centre of mass
    stays over the feet, arms swing forward to balance), then the legs push
    the body back up into the stance (it releases, it does not stop dead) -
    the head arrives last. Ready to leave from frame 10."""
    sh = Shot(arm, "Lion.Land")
    touch = s({"root": {"y": -.3, "z": 0, "pitch": 6, "yaw": 10}, "torso": {"pitch": 4, "yaw": -4}, "head": {"pitch": -16, "yaw": -6},
               "la": {"raise": 52, "out": 62, "elbow": 26}, "ra": {"raise": 46, "out": 64, "elbow": 28},
               "rf": {"x": .2, "z": .6, "yaw": 26}, "lf": {"x": -.12, "z": -.55, "yaw": -4}})
    deep = merge(touch, {"root": {"y": -1.15, "z": -.15, "pitch": 26, "yaw": 16}, "torso": {"pitch": 18, "yaw": -8}, "head": {"pitch": -32},
                         "la": {"raise": 70, "out": 40, "elbow": 60}, "ra": {"raise": 30, "out": 50, "elbow": 70}})
    rebound = merge(deep, {"root": {"y": -.66, "pitch": 14, "yaw": 26}, "torso": {"pitch": 9, "yaw": -12}, "head": {"pitch": -12},
                           "la": {"raise": 64, "out": 14, "elbow": 62}, "ra": {"raise": 50, "out": -6, "elbow": 108}})
    sh.key(0, touch, "impact").key(5, deep, "ease").key(14, rebound, "pass").key(26, s({}), "ease")
    sh.drag(["neck"], 3).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(markers={"ready": 10})


# ---------------------------------------------------------------- strikes
def light1(arm):
    """Exercise 4 - committed strike: the lead jab, stepping in.
    Weight: on the front foot; the step carries it further forward.
    Initiation: the rear foot pushes (heel up) and the lead foot steps - the
    hips start before the arm. Then the hips turn in, the shoulder drives,
    the arm extends last and fastest: the fist arrives at full speed (impact
    spacing) on the frame the lead foot lands. Overshoot: the shoulder rolls
    through 2 frames past contact. Recovery: the fist comes back faster than
    it went (the guard matters more), the rear foot drags up to rebuild the
    stance, the head last."""
    sh = Shot(arm, "Lion.Light1")
    sh.key(0, s({}), "ease")
    # Anticipation (3 f): a small sink and coil - knees load, the lead hand
    # draws in a few centimetres, the lead foot unweights.
    sh.key(3, s({"root": {"y": -.58, "z": .02, "yaw": 33, "pitch": 9}, "torso": {"yaw": -18},
                 "la": {"raise": 60, "elbow": 78}, "lf": {"y": .12, "z": -.9, "toe": 4}}), "ease")
    # Contact (6 f): lead foot lands 0.5 forward, hips forward over it and
    # turned in, chest snapped round, arm straight at the chin line.
    hit = s({"travel": {"z": -.25}, "root": {"y": -.54, "z": -.34, "yaw": 38, "pitch": 13}, "torso": {"pitch": 7, "yaw": 6},
             "head": {"yaw": -34, "pitch": -4},
             "la": {"raise": 88, "out": 2, "twist": -14, "elbow": 2, "wrist": 0},
             "ra": {"raise": 58, "out": -20, "twist": 30, "elbow": 122},
             "lf": {"z": -1.26, "y": 0, "toe": 0}, "rf": {"y": .1, "toe": -24}})
    sh.key(6, hit, "impact")
    # Overshoot (8 f): the shoulder rolls through, the fist a hair further.
    sh.key(8, merge(hit, {"root": {"z": -.38, "yaw": 40}, "torso": {"yaw": 10}, "la": {"raise": 90, "elbow": 0}}), "ease")
    # Recovery: the fist comes home fast (12 f), the rear foot drags up (16 f).
    sh.key(12, merge(hit, {"travel": {"z": -.35}, "root": {"z": -.2, "yaw": 33}, "torso": {"yaw": -8},
                           "la": {"raise": 70, "out": 6, "twist": 8, "elbow": 70}, "rf": {"y": .14, "z": .7, "toe": -10}}), "pass")
    sh.key(16, merge(s({"travel": {"z": -.45}}), {"lf": {"z": -1.26}, "rf": {"z": .4, "y": 0}}), "ease")
    sh.key(26, merge(s({"travel": {"z": -.45}}), {"lf": {"z": -1.26}, "rf": {"z": .4}}), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.R", "forearm.R"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def heavy(arm):
    """Exercise 4 - the heavy: a driving push kick with the rear leg.
    Weight: shifted onto the lead foot first (the support leg), which turns
    out on its ball. Initiation: hips forward and up, the rear knee chambers
    high (the thigh before the shin). Fastest spacing: the hip thrust and the
    shin unfolding into the target on frame 18 (the heel drives through).
    The arms counter (the kicking-side arm sweeps back, the guard stays up),
    the chest leans back over the support foot so the mass stays over it.
    The kick lands forward (a step down), the stance is rebuilt facing the
    other way round - then turned back."""
    sh = Shot(arm, "Lion.Heavy")
    sh.key(0, s({}), "ease")
    # Load (8 f): weight onto the lead foot, hips drop and slide forward,
    # the rear heel lifts, the arms close the guard.
    load = s({"root": {"y": -.66, "z": -.3, "pitch": 12, "yaw": 22}, "torso": {"pitch": 8, "yaw": -10},
              "ra": {"raise": 60, "elbow": 112}, "la": {"raise": 70, "elbow": 72}, "rf": {"y": .08, "toe": -26}, "lf": {"yaw": -18}})
    sh.key(8, load, "ease")
    # Chamber (14 f): the rear knee rises high in front, the support foot
    # pivots out, the chest starts to lean back.
    cham = merge(load, {"root": {"y": -.42, "z": -.46, "pitch": -2, "yaw": 6}, "torso": {"pitch": -6, "yaw": -2}, "head": {"pitch": 2, "yaw": -8},
                        "rf": {"x": -.3, "z": -.9, "y": 1.75, "toe": -10, "knee": -6},
                        "lf": {"yaw": -36}, "ra": {"raise": 30, "out": 30, "elbow": 80}, "la": {"raise": 78, "out": -10, "elbow": 84}})
    sh.key(14, cham, "pass")
    # Contact (18 f): hip thrust, the leg extends straight forward at belly
    # height, heel first; chest back, the right arm swept back for balance.
    hit = merge(cham, {"root": {"y": -.34, "z": -.56, "pitch": -12, "yaw": 0}, "torso": {"pitch": -10, "yaw": 0}, "head": {"pitch": 10, "yaw": -4},
                       "rf": {"x": -.4, "z": -2.45, "y": 1.75, "toe": 18, "knee": 0},
                       "ra": {"raise": -20, "out": 36, "elbow": 40}, "la": {"raise": 84, "out": -16, "elbow": 92}})
    sh.key(18, hit, "impact")
    # Overshoot / hold (22 f): the hips push a little further, then it hangs.
    sh.key(22, merge(hit, {"root": {"z": -.62, "pitch": -14}, "rf": {"z": -2.55}}), "ease")
    # Retract (28 f): the knee folds back before the foot comes down.
    ret = merge(cham, {"travel": {"z": -.6}, "root": {"z": -.3, "pitch": 4, "yaw": 8}, "rf": {"x": -.25, "z": -1.6, "y": 1.2, "toe": -6},
                       "ra": {"raise": 30, "out": 26, "elbow": 86}})
    sh.key(28, ret, "pass")
    # Set down behind (36 f): the kicking foot comes back to the rear, a
    # little ahead of where it left (the body moved in); the lead foot turns
    # back from its pivot and slides in with it (40 f), stance (52 f).
    down = s({"travel": {"z": -.32}, "root": {"y": -.62, "z": -.12, "yaw": 26}, "torso": {"yaw": -8},
              "rf": {"z": .52, "toe": -10}, "lf": {"z": -.76, "yaw": -24}})
    sh.key(36, down, "impact")
    sh.key(40, merge(down, {"lf": {"z": -.92, "y": .06, "yaw": -10}}), "pass")
    sh.key(52, s({"travel": {"z": -.32}, "rf": {"z": .52}, "lf": {"z": -1.08}}), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "forearm.L"], 2)
    return sh.build(markers={"contact": 18 / 60, "recover": 28 / 60})


def author(arm):
    return [idle(arm), run(arm), sprint(arm), jump_air(arm), land(arm), light1(arm), heavy(arm)]
