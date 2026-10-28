"""Sasuke (Lion), authored on the control rig (nd_ctrl / nd_shot), DEC-028.

Every clip is blocked pose to pose: what carries the weight, what starts the
motion, what follows late, where the spacing is fastest and where the body
absorbs. Feet are WORLD positions (Roblox axes: x right of the rest foot,
z back, y lift); a planted foot keeps the same value on consecutive keys, so
it cannot slide. "travel" is the body's real displacement; the export plays
it in place (the server owns travel). The reasoning is written next to the
keys (docs/research/ANIMATION_CRAFT.md).
"""
from nd_shot import Shot, cycle, merge, mirror

# The fighting stance. Low, coiled, left lead: hips turned 30 deg right so the
# left side faces the opponent, chest a little less (it squares up to see),
# lead hand out at chin height, rear hand guarding the jaw. Weight 55% on the
# front foot (hips slightly ahead of centre: root z -.08).
STANCE = {"root": {"y": -.5, "z": -.08, "pitch": 10, "yaw": 30}, "torso": {"pitch": 6, "yaw": -14},
          "head": {"pitch": -6, "yaw": -16},
          "la": {"raise": 66, "out": 6, "twist": 10, "elbow": 64}, "ra": {"raise": 52, "out": -16, "twist": 24, "elbow": 118},
          "rf": {"x": .26, "z": .84, "yaw": 38}, "lf": {"x": -.1, "z": -.76, "yaw": -6}}
# Right-lead stance (after the rear roundhouse): the mirror of the stance.
STANCE_R = mirror(STANCE)


def s(over=None):
    return merge(STANCE, over or {})


# ================================================================== idle
def idle(arm):
    """Exercise 1 - weight shift. The weight rocks from the front foot to the
    back foot and back (2.4 s). The hips lead (they carry the centre of mass
    over the support foot), the chest follows 3 frames later, the head stays
    level on the opponent (it counters). On the back foot the rear knee loads
    and the hip on that side rises (contrapposto), the front heel lightens."""
    sh = Shot(arm, "Lion.Idle")
    sh.key(0, s(), "ease")
    sh.key(72, s({"root": {"y": -.56, "z": .1, "pitch": 7, "yaw": 33, "roll": 2}, "torso": {"pitch": 4, "roll": -1},
                  "head": {"pitch": -4}, "la": {"raise": 63, "elbow": 68}, "ra": {"raise": 50, "elbow": 121},
                  "lf": {"toe": 6}}), "ease")
    sh.key(144, s(), "ease")
    sh.drag(["spine"], 3).drag(["neck", "shoulder.L", "shoulder.R"], 5)
    return sh.build(loop=True)


# ============================================================ locomotion
RUN_ARMS_F = {"la": {"raise": 46, "out": 10, "twist": 10, "elbow": 94}, "ra": {"raise": -48, "out": 16, "elbow": 74}}


def run(arm):
    """The run (19 studs/s). Stride 10 studs per cycle, 32 frames: each foot
    holds the floor 22% of the cycle (2.2 studs under the body), then a
    flight. Right step: contact (the foot lands ahead of the hip, on the
    midfoot, knee soft) -> down 2 f later (lowest, the stance knee absorbs,
    the free heel folds high behind) -> passing (the free knee drives through)
    -> toe-off (the stance leg extends behind, the body rises) -> peak (both
    feet off, the trailing heel kicks up, the lead leg reaches). The pelvis
    turns with the forward leg, the chest counters it, the arms swing
    opposite to the legs, the head stays level."""
    keys = [
        (0.0, merge(RUN_ARMS_F, {"root": {"y": -.46, "pitch": 20, "yaw": -9}, "torso": {"pitch": 10, "yaw": 13}, "head": {"pitch": -24, "yaw": -4},
                                 "rf": {"x": .02, "z": -1.05, "toe": 8}, "lf": {"x": -.04, "z": 1.25, "y": .9, "toe": -50}}), "impact"),
        (0.07, {"root": {"y": -.66, "pitch": 21, "yaw": -6}, "torso": {"pitch": 12, "yaw": 10},
                "lf": {"x": -.04, "z": .95, "y": 1.1, "toe": -60},
                "la": {"raise": 40, "elbow": 96}, "ra": {"raise": -40, "elbow": 78}}, "ease"),
        (0.15, {"root": {"y": -.52, "pitch": 21, "yaw": -1}, "torso": {"pitch": 11, "yaw": 3},
                "lf": {"x": -.04, "z": -.3, "y": .8, "toe": -32, "knee": 4},
                "la": {"raise": 18, "elbow": 92}, "ra": {"raise": -8, "elbow": 80}}, "pass"),
        (0.22, {"root": {"y": -.38, "pitch": 20, "yaw": 6}, "torso": {"pitch": 10, "yaw": -5},
                "lf": {"x": -.03, "z": -1.05, "y": .95, "toe": -8},
                "la": {"raise": -12, "elbow": 84}, "ra": {"raise": 22, "elbow": 88}}, "launch"),
        (0.34, {"root": {"y": -.3, "pitch": 19, "yaw": 9}, "torso": {"pitch": 10, "yaw": -12}, "head": {"pitch": -24, "yaw": 4},
                "rf": {"x": .03, "z": 1.35, "y": .75, "toe": -50}, "lf": {"x": -.03, "z": -1.3, "y": .38, "toe": 4},
                "la": {"raise": -44, "elbow": 74}, "ra": {"raise": 42, "elbow": 94}}, "pass"),
        (0.45, {"root": {"y": -.38, "pitch": 20, "yaw": 9}, "torso": {"pitch": 10, "yaw": -13},
                "rf": {"x": .04, "z": 1.2, "y": .95, "toe": -50}, "lf": {"x": -.02, "z": -1.08, "y": .08, "toe": 8},
                "la": {"raise": -48, "elbow": 72}, "ra": {"raise": 46, "elbow": 94}}, "ease"),
    ]
    sh = cycle(arm, "Lion.Run.F", 10.0, 48, keys, {"R": (0, .22)})
    sh.drag(["neck"], 2).drag(["shoulder.L", "shoulder.R", "forearm.L", "forearm.R"], 1)
    return sh.build(loop=True, meta={"stride": 10.0})


def run_back(arm):
    """Backpedal at run speed: short quick steps on the balls of the feet, the
    hips sit back over the landing foot (the body never leans away from its
    feet, it would fall), the guard stays up, eyes on the opponent. Stride 6,
    duty .34 (more time on the floor: balance first)."""
    guard = {"la": {"raise": 70, "out": -8, "twist": 20, "elbow": 96}, "ra": {"raise": 62, "out": -14, "twist": 26, "elbow": 112}}
    keys = [
        (0.0, merge(guard, {"root": {"y": -.5, "pitch": -4, "yaw": 6}, "torso": {"pitch": 8, "yaw": -4}, "head": {"pitch": -2},
                            "rf": {"x": .04, "z": .95, "toe": -12}, "lf": {"x": -.04, "z": -.7, "y": .3, "toe": -24}}), "impact"),
        (0.1, {"root": {"y": -.62, "pitch": -3}, "lf": {"z": -.1, "y": .55, "toe": -30}}, "ease"),
        (0.25, {"root": {"y": -.5, "pitch": -4, "yaw": 2}, "lf": {"z": .6, "y": .4, "toe": -22}}, "pass"),
        (0.34, {"root": {"y": -.44, "yaw": -2}, "lf": {"z": .95, "y": .14, "toe": -14}}, "launch"),
        (0.45, {"root": {"y": -.46, "yaw": -6}, "rf": {"z": -.7, "y": .3, "toe": -24}, "lf": {"x": -.04, "z": .95, "y": .04, "toe": -12}}, "ease"),
    ]
    sh = cycle(arm, "Lion.Run.B", 6.0, 30, keys, {"R": (0, .34)}, direction=(0.0, 1.0))
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"stride": 6.0})


def run_side(arm, side):
    """Running sideways round the opponent: the hips and legs turn toward the
    travel and run (a real run, not a shuffle), the chest twists back to keep
    the shoulders and the eyes on the opponent (a circling run). Stride 8,
    duty .26, a whole cycle (the two steps differ: the inside leg leads)."""
    sgn = 1 if side == "R" else -1
    hip = 58 * sgn
    base = {"root": {"y": -.44, "pitch": 14, "yaw": hip, "roll": 4 * sgn}, "torso": {"pitch": 6, "yaw": -hip * .72},
            "head": {"pitch": -14, "yaw": -hip * .28},
            "la": {"raise": 40, "out": 12, "elbow": 90}, "ra": {"raise": 36, "out": 14, "elbow": 90}}
    a, b = ("rf", "lf") if side == "R" else ("lf", "rf")

    def f(x, z, y=0.0, toe=0.0):
        return {"x": x * sgn, "z": z, "y": y, "toe": toe, "yaw": hip}
    keys = [
        (0.0, merge(base, {a: f(1.0, -.1, 0, 6), b: f(-1.15, .2, .8, -46)}), "impact"),
        (0.08, merge(base, {"root": {"y": -.6}, b: f(-.45, .15, 1.15, -54)}), "ease"),
        (0.18, merge(base, {"root": {"y": -.46}, b: f(.55, 0, .95, -18)}), "pass"),
        (0.26, merge(base, {"root": {"y": -.36}, b: f(1.0, -.05, .45, 0)}), "launch"),
        (0.38, merge(base, {"root": {"y": -.34}, a: f(-1.2, -.1, .7, -46), b: f(1.05, -.05, .1, 4)}), "pass"),
        (0.5, merge(base, {b: f(1.0, -.05, 0, 6), a: f(-1.15, -.1, .8, -46)}), "impact"),
        (0.58, merge(base, {"root": {"y": -.6}, a: f(-.45, -.1, 1.15, -54)}), "ease"),
        (0.68, merge(base, {"root": {"y": -.46}, a: f(.55, -.1, .95, -18)}), "pass"),
        (0.76, merge(base, {"root": {"y": -.36}, a: f(1.0, -.1, .45, 0)}), "launch"),
        (0.88, merge(base, {"root": {"y": -.34}, b: f(-1.2, -.05, .7, -46), a: f(1.05, -.1, .1, 4)}), "pass"),
    ]
    lead, trail = ("R", "L") if side == "R" else ("L", "R")
    sh = cycle(arm, "Lion.Run." + side, 8.0, 30, keys, {lead: (0, .26), trail: (.5, .76)},
               direction=(float(sgn), 0.0), mirror_half=False)
    sh.drag(["neck"], 2)
    return sh.build(loop=True, meta={"stride": 8.0})


GUARD_WALK = {"la": {"raise": 62, "out": 4, "twist": 12, "elbow": 74}, "ra": {"raise": 56, "out": -14, "twist": 24, "elbow": 112}}


def walk(arm):
    """The guarded walk (stepping in, < 8 studs/s): the hands stay up;
    contact -> down -> passing -> up; the front foot reaches heel first, the
    weight rolls over it, the rear foot peels off. Stride 3.4, duty .58 (a
    walk always has a foot down)."""
    keys = [
        (0.0, merge(GUARD_WALK, {"root": {"y": -.46, "pitch": 8, "yaw": -4}, "torso": {"pitch": 6, "yaw": 4}, "head": {"pitch": -8},
                                 "rf": {"x": .04, "z": -.82, "toe": 10}, "lf": {"x": -.04, "z": .82, "y": .02, "toe": -18}}), "ease"),
        (0.1, {"root": {"y": -.56, "pitch": 9}, "lf": {"z": .55, "y": .12, "toe": -26}}, "ease"),
        (0.25, {"root": {"y": -.42, "pitch": 8, "yaw": 0}, "torso": {"yaw": 0}, "lf": {"z": 0, "y": .4, "toe": -10}}, "pass"),
        (0.4, {"root": {"y": -.4, "pitch": 8, "yaw": 4}, "torso": {"yaw": -4}, "lf": {"z": -.6, "y": .16, "toe": 6}}, "pass"),
    ]
    sh = cycle(arm, "Lion.Walk.F", 3.4, 44, keys, {"R": (0, .58)})
    sh.drag(["neck"], 3)
    return sh.build(loop=True, meta={"stride": 3.4})


def walk_back(arm):
    keys = [
        (0.0, {"root": {"y": -.5, "pitch": 4, "yaw": 4}, "torso": {"pitch": 8, "yaw": -2}, "head": {"pitch": -4},
               "la": {"raise": 68, "out": -6, "twist": 18, "elbow": 92}, "ra": {"raise": 60, "out": -14, "twist": 26, "elbow": 112},
               "rf": {"x": .04, "z": .7, "toe": -8}, "lf": {"x": -.04, "z": -.7, "y": .02, "toe": -6}}, "ease"),
        (0.15, {"root": {"y": -.56}, "lf": {"z": -.4, "y": .14, "toe": -14}}, "ease"),
        (0.3, {"root": {"y": -.46, "yaw": 0}, "lf": {"z": .1, "y": .3, "toe": -14}}, "pass"),
        (0.42, {"root": {"y": -.44, "yaw": -3}, "lf": {"z": .55, "y": .12, "toe": -10}}, "pass"),
    ]
    sh = cycle(arm, "Lion.Walk.B", 2.8, 44, keys, {"R": (0, .62)}, direction=(0.0, 1.0))
    sh.drag(["neck"], 3)
    return sh.build(loop=True, meta={"stride": 2.8})


def walk_side(arm, side):
    """Side step: the leading foot opens the step, the other closes behind it
    (never crossing: the stance stays ready), the hips lean into the step."""
    sgn = 1 if side == "R" else -1
    lead, trail = ("rf", "lf") if side == "R" else ("lf", "rf")
    LS, TS = ("R", "L") if side == "R" else ("L", "R")
    g = merge(GUARD_WALK, {"root": {"y": -.5, "pitch": 8, "yaw": 22}, "torso": {"pitch": 6, "yaw": -10}, "head": {"pitch": -6, "yaw": -12}})
    zl, zt = (.1, -.2) if side == "R" else (-.2, .1)

    def f(x, z, y=0.0, toe=0.0):
        return {"x": x * sgn, "z": z, "y": y, "toe": toe, "yaw": 20}
    keys = [
        (0.0, merge(g, {lead: f(0, zl, .0), trail: f(0, zt)}), "ease"),
        (0.15, merge(g, {"root": {"y": -.56, "roll": -3 * sgn}, lead: f(.45, zl, .2, -8)}), "pass"),
        (0.35, merge(g, {"root": {"y": -.52, "roll": 2 * sgn}, lead: f(1.04, zl)}), "impact"),
        (0.5, merge(g, {"root": {"y": -.48}, trail: f(-.8, zt)}), "ease"),
        (0.65, merge(g, {"root": {"y": -.46}, trail: f(-.25, zt, .18, -8)}), "pass"),
        (0.8, merge(g, {"root": {"y": -.5}, trail: f(.32, zt)}), "impact"),
    ]
    sh = cycle(arm, "Lion.Walk." + side, 1.6, 36, keys, {LS: (.35, 1.0), TS: (.8, 1.5)},
               direction=(float(sgn), 0.0), mirror_half=False)
    return sh.build(loop=True, meta={"stride": 1.6})


def sprint(arm):
    """The ninja run (45 studs/s): chest thrown forward over the feet, arms
    swept back and still (they would brake the body), the head up to see.
    Stride 14, 20 frames, the foot holds the floor 18% (2.5 studs); the legs
    cycle hard - heel to the seat behind, knee high in front."""
    arms = {"la": {"raise": -62, "out": 16, "twist": -12, "elbow": 12}, "ra": {"raise": -62, "out": 16, "twist": -12, "elbow": 12}}
    keys = [
        (0.0, merge(arms, {"root": {"y": -.72, "pitch": 34, "yaw": -6}, "torso": {"pitch": 22, "yaw": 7}, "head": {"pitch": -48, "yaw": -3},
                           "rf": {"x": .04, "z": -1.0, "toe": 4}, "lf": {"x": -.04, "z": 1.3, "y": .9, "toe": -56}}), "impact"),
        (0.06, merge(arms, {"root": {"y": -.84, "pitch": 35, "yaw": -4}, "torso": {"pitch": 24, "yaw": 5},
                            "lf": {"x": -.04, "z": 1.0, "y": 1.1, "toe": -60}}), "ease"),
        (0.12, merge(arms, {"root": {"y": -.76, "pitch": 34, "yaw": 0}, "torso": {"pitch": 23, "yaw": 1},
                            "lf": {"x": -.04, "z": .05, "y": .42, "toe": -40}}), "pass"),
        (0.18, merge(arms, {"root": {"y": -.66, "pitch": 34, "yaw": 3}, "torso": {"pitch": 23, "yaw": -2},
                            "lf": {"x": -.03, "z": -1.05, "y": 1.1, "toe": -20},
                            "la": {"raise": -58}, "ra": {"raise": -66}}), "launch"),
        (0.32, merge(arms, {"root": {"y": -.58, "pitch": 33, "yaw": 6}, "torso": {"pitch": 22, "yaw": -6}, "head": {"pitch": -48, "yaw": 3},
                            "rf": {"x": .04, "z": 1.5, "y": .7, "toe": -52}, "lf": {"x": -.03, "z": -1.3, "y": .45, "toe": -4},
                            "la": {"raise": -60}, "ra": {"raise": -64}}), "pass"),
        (0.45, merge(arms, {"root": {"y": -.64, "pitch": 34, "yaw": 6}, "torso": {"pitch": 22, "yaw": -7},
                            "rf": {"x": .04, "z": 1.3, "y": .95, "toe": -56}, "lf": {"x": -.04, "z": -1.05, "y": .08, "toe": 4}}), "ease"),
    ]
    sh = cycle(arm, "Lion.Sprint", 14.0, 40, keys, {"R": (0, .18)})
    sh.drag(["neck"], 1)
    return sh.build(loop=True, meta={"stride": 14.0})


def start(arm):
    """Exercise 2 (acceleration): leaving the stance into the run. The body
    falls forward first (the hips go ahead of the feet), the rear foot drives
    off the floor (heel up, the leg straightening behind), the first steps are
    short and low under a steep lean; the chest rises over the next steps."""
    sh = Shot(arm, "Lion.Start")
    sh.key(0, s(), "ease")
    sh.key(4, s({"travel": {"z": -.4}, "root": {"y": -.7, "z": -.5, "pitch": 30, "yaw": 10}, "torso": {"pitch": 16, "yaw": 0}, "head": {"pitch": -30, "yaw": -4},
                 "rf": {"y": .1, "toe": -36}, "la": {"raise": 30, "out": 10, "elbow": 90}, "ra": {"raise": -30, "out": 12, "elbow": 70}}), "launch")
    sh.key(7, s({"travel": {"z": -1.0}, "root": {"y": -.68, "z": -.4, "pitch": 30, "yaw": 0}, "torso": {"pitch": 15, "yaw": 4},
                 "rf": {"x": .1, "z": -.6, "y": .65, "toe": -20, "yaw": 10}, "lf": {"toe": -20}}), "pass")
    sh.key(9, s({"travel": {"z": -1.6}, "root": {"y": -.64, "z": -.2, "pitch": 28, "yaw": -6}, "torso": {"pitch": 14, "yaw": 10}, "head": {"pitch": -28, "yaw": -2},
                 "rf": {"x": .02, "z": -1.9, "y": 0, "toe": 6, "yaw": 0}, "lf": {"y": .2, "toe": -40},
                 "la": {"raise": -36, "out": 12, "elbow": 72}, "ra": {"raise": 46, "out": 10, "elbow": 94}}), "impact")
    sh.key(12, s({"travel": {"z": -2.6}, "root": {"y": -.6, "z": -.1, "pitch": 26, "yaw": 0},
                  "rf": {"x": .02, "z": -1.9, "y": 0, "toe": -10, "yaw": 0}, "lf": {"x": -.02, "z": -2.8, "y": .75, "toe": -20, "yaw": 0}}), "pass")
    sh.key(14, s({"travel": {"z": -3.3}, "root": {"y": -.56, "z": -.1, "pitch": 24, "yaw": 6}, "torso": {"pitch": 12, "yaw": -8}, "head": {"pitch": -26, "yaw": 2},
                  "rf": {"x": .02, "z": -1.9, "y": 0, "toe": -30, "yaw": 0}, "lf": {"x": -.02, "z": -4.4, "y": 0, "toe": 6, "yaw": 0},
                  "la": {"raise": 46, "out": 10, "elbow": 94}, "ra": {"raise": -40, "out": 14, "elbow": 72}}), "impact")
    sh.key(18, s({"travel": {"z": -4.8}, "root": {"y": -.46, "z": 0, "pitch": 20, "yaw": -6}, "torso": {"pitch": 10, "yaw": 10},
                  "rf": {"x": .02, "z": -5.1, "y": .7, "toe": -20, "yaw": 0}, "lf": {"x": -.02, "z": -4.4, "y": 0, "toe": -20, "yaw": 0},
                  "la": {"raise": -20}, "ra": {"raise": 30}}), "pass")
    sh.drag(["neck"], 2)
    return sh.build(meta={"ready": 9 / 60})


def brake(arm):
    """Exercise 2 (braking): from the run to the stance. The penultimate step
    (left) lands far ahead, heel first; the hips drop and the chest sits back
    (the front leg catches the body's momentum); the last step (right) plants
    behind it and the weight rocks back onto it: that is the stance, left
    lead. The head and hands arrive last. 0.38 s."""
    sh = Shot(arm, "Lion.Brake")
    T = -1.64
    sh.key(0, {"root": {"y": -.4, "pitch": 18, "yaw": 9}, "torso": {"pitch": 10, "yaw": -10}, "head": {"pitch": -22},
               "ra": {"raise": 40, "out": 10, "elbow": 92}, "la": {"raise": -40, "out": 14, "elbow": 74},
               "lf": {"x": -.02, "z": -1.2, "y": .25, "toe": 14, "yaw": 0}, "rf": {"x": .04, "z": .9, "y": .25, "toe": -40, "yaw": 0}}, "pass")
    sh.key(4, {"travel": {"z": -1.0}, "root": {"y": -.7, "pitch": -4, "yaw": 16}, "torso": {"pitch": -2, "yaw": -10}, "head": {"pitch": -2},
               "ra": {"raise": 60, "out": 24, "elbow": 70}, "la": {"raise": 20, "out": 30, "elbow": 80},
               "lf": {"x": -.1, "z": -2.4, "y": 0, "toe": 22, "yaw": -6}, "rf": {"x": .04, "z": -.4, "y": .3, "toe": -30, "yaw": 10}}, "impact")
    sh.key(9, s({"travel": {"z": T}, "root": {"y": -.72, "z": -.25, "pitch": 4, "yaw": 34}, "torso": {"pitch": 2, "yaw": -18}, "head": {"pitch": -8},
                 "lf": {"z": -2.4, "toe": 0}, "rf": {"z": .84 + T, "y": 0}}), "impact")
    sh.key(15, s({"travel": {"z": T}, "root": {"y": -.56, "z": .02}, "lf": {"z": -2.4}, "rf": {"z": .84 + T}}), "pass")
    sh.key(23, s({"travel": {"z": T}, "lf": {"z": -2.4}, "rf": {"z": .84 + T}}), "ease")
    sh.drag(["neck"], 3).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(meta={"ready": 12 / 60})


# ===================================================================== air
def jump_air(arm):
    """Exercise 3 (air). Time axis = arc progress: 0 take-off (rising fast),
    .5 apex, 1 falling fast just above the floor (the game picks the frame
    from the vertical speed). The body extends at take-off (the push is still
    in the legs: ankles pointed, arms thrown up), gathers at the top (knees
    up, compact: weightless), then opens and the feet search for the floor:
    legs reach down, arms out for balance, the head looks at the landing."""
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


def jump_leap(arm):
    """Running jump: the take-off foot drives the body forward-up, the other
    knee drives through high: a split stride through the air, the arms swept
    back (ninja), gathering before the landing: the lead leg reaches."""
    sh = Shot(arm, "Lion.Jump.Leap")
    take = {"root": {"y": -.2, "pitch": 24, "yaw": 0}, "torso": {"pitch": 14, "yaw": 0}, "head": {"pitch": -34, "yaw": 0},
            "la": {"raise": -52, "out": 14, "elbow": 16}, "ra": {"raise": -52, "out": 14, "elbow": 16},
            "rf": {"x": 0, "z": -1.0, "y": .9, "toe": -20, "yaw": 0}, "lf": {"x": 0, "z": 1.2, "y": .2, "toe": -50, "yaw": 0}}
    split = merge(take, {"root": {"y": -.3, "pitch": 22}, "rf": {"z": -1.5, "y": .9, "toe": 0}, "lf": {"z": 1.45, "y": .7, "toe": -44}})
    gather = merge(take, {"root": {"y": -.5, "pitch": 16}, "torso": {"pitch": 10}, "rf": {"z": -.9, "y": 1.1, "toe": -10}, "lf": {"z": .2, "y": 1.2, "toe": -40},
                          "la": {"raise": -30, "out": 30, "elbow": 30}, "ra": {"raise": -30, "out": 30, "elbow": 30}})
    reach = merge(take, {"root": {"y": -.2, "pitch": 8}, "torso": {"pitch": 6}, "head": {"pitch": -16},
                         "rf": {"z": -1.0, "y": .15, "toe": 6}, "lf": {"z": .4, "y": .5, "toe": -30},
                         "la": {"raise": 20, "out": 44, "elbow": 30}, "ra": {"raise": 14, "out": 46, "elbow": 30}})
    sh.key(0, take, "launch").key(18, split, "pass").key(38, gather, "ease").key(60, reach, "ease")
    sh.drag(["neck"], 2)
    return sh.build(meta={"axis": "arc"})


def land(arm):
    """Exercise 3 (landing). The front foot touches first, the hips keep
    falling: the knees take it (deepest at frame 5, the chest folds forward
    over the knees so the centre of mass stays over the feet, the arms swing
    forward to balance), then the legs push the body back up into the stance
    - the head arrives last. Ready to leave from frame 10."""
    sh = Shot(arm, "Lion.Land")
    touch = s({"root": {"y": -.3, "z": 0, "pitch": 6, "yaw": 10}, "torso": {"pitch": 4, "yaw": -4}, "head": {"pitch": -16, "yaw": -6},
               "la": {"raise": 52, "out": 62, "elbow": 26}, "ra": {"raise": 46, "out": 64, "elbow": 28},
               "rf": {"x": .2, "z": .6, "yaw": 26}, "lf": {"x": -.12, "z": -.55, "yaw": -4}})
    deep = merge(touch, {"root": {"y": -1.15, "z": -.15, "pitch": 26, "yaw": 16}, "torso": {"pitch": 18, "yaw": -8}, "head": {"pitch": -32},
                         "la": {"raise": 70, "out": 40, "elbow": 60}, "ra": {"raise": 30, "out": 50, "elbow": 70}})
    rebound = merge(deep, {"root": {"y": -.66, "pitch": 14, "yaw": 26}, "torso": {"pitch": 9, "yaw": -12}, "head": {"pitch": -12},
                           "la": {"raise": 64, "out": 14, "elbow": 62}, "ra": {"raise": 50, "out": -6, "elbow": 108}})
    sh.key(0, touch, "impact").key(5, deep, "ease").key(14, rebound, "pass").key(26, s({"rf": {"x": .2, "z": .6}, "lf": {"x": -.12, "z": -.55}}), "ease")
    sh.drag(["neck"], 3).drag(["shoulder.L", "shoulder.R"], 2)
    return sh.build(markers={"ready": 10 / 60})


# ================================================================= strikes
def light1(arm):
    """Exercise 4 - committed strike: the lead jab, stepping in.
    Weight: front foot; the step carries it further. Initiation: the rear
    foot pushes (heel up) and the lead foot steps - the hips start before the
    arm, the chest snaps round past them, the arm extends last and fastest:
    the fist arrives at full speed on the frame the lead foot lands (impact).
    Overshoot: the shoulder rolls through for 2 frames. Recovery: the fist
    comes back faster than it went, the rear foot drags up, the head last."""
    sh = Shot(arm, "Lion.Light1")
    sh.key(0, s(), "ease")
    sh.key(3, s({"root": {"y": -.6, "z": .04, "yaw": 34, "pitch": 8}, "torso": {"yaw": -20},
                 "la": {"raise": 58, "elbow": 82}, "lf": {"y": .14, "z": -.92, "toe": 6}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.56, "z": -.46, "yaw": 40, "pitch": 16}, "torso": {"pitch": 12, "yaw": 22},
             "head": {"yaw": -44, "pitch": 2},
             "la": {"raise": 92, "out": 0, "twist": -20, "elbow": 0, "wrist": 0},
             "ra": {"raise": 60, "out": -22, "twist": 30, "elbow": 124},
             "lf": {"z": -1.36, "y": 0, "toe": 0}, "rf": {"y": .14, "toe": -30}})
    sh.key(6, hit, "impact")
    sh.key(8, merge(hit, {"root": {"z": -.5, "yaw": 42}, "torso": {"yaw": 26}, "la": {"raise": 93}}), "ease")
    sh.key(12, merge(hit, {"travel": {"z": -.45}, "root": {"z": -.28, "yaw": 34}, "torso": {"yaw": -4},
                           "la": {"raise": 70, "out": 6, "twist": 8, "elbow": 72}, "rf": {"y": .16, "z": .62, "toe": -10}}), "pass")
    sh.key(16, merge(s({"travel": {"z": -.6}}), {"lf": {"z": -1.36}, "rf": {"z": .24, "y": 0}}), "ease")
    sh.key(26, merge(s({"travel": {"z": -.6}}), {"lf": {"z": -1.36}, "rf": {"z": .24}}), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.R", "forearm.R"], 1)
    return sh.build(markers={"contact": 6 / 60, "recover": 12 / 60})


def light2(arm):
    """The rear-leg roundhouse. Weight onto the lead (left) foot, which pivots
    on its ball until the heel points at the target (the hips can turn over
    only if the support foot turns). The right knee chambers high toward the
    target, the hips roll over (the pelvis turns left and tilts), the chest
    leans away to counterbalance, the kicking-side arm sweeps down and back,
    the lead hand guards. Fastest: the shin unfolding through the target at
    frame 11. It follows through across, re-chambers, and sets down in
    front: a right-lead stance 1.6 studs on, ready for the spinning kick."""
    sh = Shot(arm, "Lion.Light2")
    sh.key(0, s(), "ease")
    load = s({"travel": {"z": -.2}, "root": {"y": -.6, "z": -.3, "yaw": 18, "pitch": 12}, "torso": {"yaw": -6},
              "rf": {"y": .1, "toe": -30}, "lf": {"yaw": -30}, "ra": {"raise": 44, "elbow": 110}})
    sh.key(4, load, "ease")
    cham = merge(load, {"root": {"y": -.4, "z": -.35, "yaw": -24, "pitch": 4, "roll": -10}, "torso": {"pitch": -2, "yaw": 6, "roll": -10},
                        "head": {"yaw": 10, "pitch": -2},
                        "rf": {"x": -.3, "z": -.5, "y": 1.3, "toe": -30, "knee": 40, "yaw": -40},
                        "lf": {"yaw": -100}, "ra": {"raise": 0, "out": 40, "elbow": 40}, "la": {"raise": 84, "out": -16, "twist": 20, "elbow": 110}})
    sh.key(8, cham, "pass")
    hit = merge(cham, {"root": {"y": -.32, "z": -.4, "yaw": -62, "pitch": -2, "roll": -22}, "torso": {"pitch": -6, "yaw": 16, "roll": -12},
                       "head": {"yaw": 40, "pitch": 0},
                       "rf": {"x": -1.5, "z": -2.55, "y": 1.8, "toe": -40, "knee": 70, "yaw": -90},
                       "lf": {"yaw": -140}, "ra": {"raise": -30, "out": 46, "elbow": 20}})
    sh.key(11, hit, "impact")
    sh.key(14, merge(hit, {"root": {"yaw": -74}, "rf": {"x": -2.1, "z": -1.9, "y": 1.65, "yaw": -110}}), "ease")
    rech = merge(cham, {"root": {"yaw": -60, "roll": -8, "y": -.42}, "torso": {"yaw": 10, "roll": -6},
                        "rf": {"x": -.7, "z": -1.3, "y": 1.1, "toe": -30, "knee": 30, "yaw": -80}, "lf": {"yaw": -130}})
    sh.key(20, rech, "pass")
    end = merge(STANCE_R, {"travel": {"z": -1.6}, "rf": {"x": .1, "z": -2.36}, "lf": {"x": -.1, "z": -.76}})
    sh.key(28, merge(end, {"root": {"y": -.62}, "lf": {"yaw": -90}}), "impact")
    sh.key(38, merge(end, {"lf": {"yaw": -38}}), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "forearm.L"], 2)
    return sh.build(markers={"contact": 11 / 60, "recover": 20 / 60})


def light3(arm):
    """The spinning back heel kick (finisher), from the right-lead stance the
    roundhouse left. The spin starts from the support (right) foot pivoting
    and the hips; the head whips round FIRST to find the target (spotting);
    the left knee stays tucked during the turn (a small radius spins fast),
    then the leg opens and the heel sweeps through the target at frame 14,
    the body leaning away. It keeps turning to land left-lead, square."""
    sh = Shot(arm, "Lion.Light3")
    st = merge(STANCE_R, {"rf": {"x": .1, "z": -.76, "yaw": 6}, "lf": {"x": -.26, "z": .84, "yaw": -38}})
    sh.key(0, st, "ease")
    sh.key(4, merge(st, {"root": {"y": -.62, "yaw": -10, "z": -.2}, "torso": {"yaw": 0}, "head": {"yaw": 10},
                         "rf": {"yaw": 40}, "lf": {"y": .1, "toe": -26}}), "ease")
    sh.key(6, merge(st, {"root": {"y": -.52, "yaw": 70, "z": -.25}, "torso": {"yaw": 6}, "head": {"yaw": 40},
                         "rf": {"yaw": 90}, "lf": {"x": .1, "z": .2, "y": .7, "toe": -20, "yaw": 70}}), "pass")
    sh.key(8, merge(st, {"root": {"y": -.44, "yaw": 150, "z": -.3, "pitch": 4}, "torso": {"yaw": 10, "pitch": 4}, "head": {"yaw": 70},
                         "rf": {"yaw": 150}, "lf": {"x": .3, "z": -.2, "y": 1.1, "toe": -20, "knee": -30, "yaw": 150},
                         "la": {"raise": 30, "out": 30, "elbow": 90}, "ra": {"raise": 60, "out": -10, "elbow": 110}}), "pass")
    sh.key(11, merge(st, {"root": {"y": -.36, "yaw": 210, "z": -.35, "pitch": -4, "roll": 14}, "torso": {"yaw": 0, "roll": 8}, "head": {"yaw": 120},
                          "rf": {"yaw": 210}, "lf": {"x": 1.4, "z": -.9, "y": 1.5, "toe": 10, "knee": 0, "yaw": 210},
                          "la": {"raise": -10, "out": 50, "elbow": 30}, "ra": {"raise": 70, "out": -20, "elbow": 110}}), "pass")
    hit = merge(st, {"root": {"y": -.32, "yaw": 265, "z": -.4, "pitch": -8, "roll": 22}, "torso": {"yaw": -10, "roll": 12, "pitch": -4}, "head": {"yaw": 100},
                     "rf": {"yaw": 265}, "lf": {"x": .2, "z": -2.3, "y": 1.9, "toe": 20, "knee": 0, "yaw": 265},
                     "la": {"raise": -30, "out": 56, "elbow": 20}, "ra": {"raise": 76, "out": -20, "elbow": 112}})
    sh.key(14, hit, "impact")
    sh.key(17, merge(hit, {"root": {"yaw": 300, "roll": 16}, "lf": {"x": -.9, "z": -1.9, "y": 1.6, "yaw": 300}, "rf": {"yaw": 300}}), "ease")
    sh.key(22, merge(st, {"root": {"y": -.5, "yaw": 340, "z": -.3, "roll": 4}, "torso": {"yaw": -8}, "head": {"yaw": 10},
                          "rf": {"yaw": 340}, "lf": {"x": -.4, "z": -1.6, "y": .5, "toe": -10, "yaw": 340}}), "pass")
    T = -1.6
    fin = s({"travel": {"z": T}, "root": {"yaw": 390}, "rf": {"x": .1, "z": -.76, "yaw": 398}, "lf": {"x": -.1, "z": -.76 + T, "yaw": 354}})
    sh.key(26, merge(fin, {"root": {"y": -.66}}), "impact")
    sh.key(40, fin, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 14 / 60, "recover": 22 / 60})


def heavy(arm):
    """Exercise 4 - the heavy: a driving push kick with the rear leg.
    Weight onto the lead foot first (the support leg, turned out on its
    ball). Initiation: hips forward and up, the rear knee chambers high (the
    thigh before the shin). Fastest: the hip thrust and the shin unfolding
    into the target at frame 18 (heel drives through). The arms counter (the
    kicking-side arm sweeps back, the guard stays up), the chest leans back
    over the support foot so the mass stays over it. Re-chamber, then the foot
    is set down behind, a little ahead of where it left."""
    sh = Shot(arm, "Lion.Heavy")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.66, "z": -.3, "pitch": 12, "yaw": 22}, "torso": {"pitch": 8, "yaw": -10},
              "ra": {"raise": 60, "elbow": 112}, "la": {"raise": 70, "elbow": 72}, "rf": {"y": .08, "toe": -26}, "lf": {"yaw": -18}})
    sh.key(8, load, "ease")
    cham = merge(load, {"root": {"y": -.42, "z": -.46, "pitch": -2, "yaw": 6}, "torso": {"pitch": -6, "yaw": -2}, "head": {"pitch": 2, "yaw": -8},
                        "rf": {"x": -.3, "z": -1.45, "y": .9, "toe": -20, "knee": -6},
                        "lf": {"yaw": -36}, "ra": {"raise": 30, "out": 30, "elbow": 80}, "la": {"raise": 78, "out": -10, "elbow": 84}})
    sh.key(14, cham, "pass")
    hit = merge(cham, {"root": {"y": -.34, "z": -.56, "pitch": -12, "yaw": 0}, "torso": {"pitch": -10, "yaw": 0}, "head": {"pitch": 10, "yaw": -4},
                       "rf": {"x": -.4, "z": -2.55, "y": 1.6, "toe": 30, "knee": 0},
                       "ra": {"raise": -20, "out": 36, "elbow": 40}, "la": {"raise": 84, "out": -16, "elbow": 92}})
    sh.key(18, hit, "impact")
    sh.key(22, merge(hit, {"root": {"z": -.62, "pitch": -14}, "rf": {"z": -2.65}}), "ease")
    ret = merge(cham, {"travel": {"z": -.3}, "root": {"z": -.3, "pitch": 4, "yaw": 8}, "rf": {"x": -.25, "z": -1.5, "y": .9, "toe": -16},
                       "ra": {"raise": 30, "out": 26, "elbow": 86}})
    sh.key(28, ret, "pass")
    down = s({"travel": {"z": -.32}, "root": {"y": -.62, "z": -.12, "yaw": 26}, "torso": {"yaw": -8},
              "rf": {"z": .52, "toe": -10}, "lf": {"z": -.76, "yaw": -24}})
    sh.key(36, down, "impact")
    sh.key(40, merge(down, {"lf": {"z": -.92, "y": .06, "yaw": -10}}), "pass")
    sh.key(52, s({"travel": {"z": -.32}, "rf": {"z": .52}, "lf": {"z": -1.08}}), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "forearm.L"], 2)
    return sh.build(markers={"contact": 18 / 60, "recover": 28 / 60})


AIR = {"root": {"y": -.5, "pitch": 14, "yaw": 0}, "torso": {"pitch": 12, "yaw": 0}, "head": {"pitch": -20, "yaw": 0},
       "la": {"raise": 60, "out": 40, "elbow": 90}, "ra": {"raise": 56, "out": 42, "elbow": 94},
       "rf": {"x": 0, "z": -.7, "y": 1.2, "toe": -24, "yaw": 0, "knee": 8}, "lf": {"x": 0, "z": -.45, "y": 1.05, "toe": -26, "yaw": 0, "knee": 6}}


def air1(arm):
    """Air drive kick: in the air there is no floor to push from - the force
    comes from folding and unfolding the body. The kicking knee comes to the
    chest (the body compacts), then the hips thrust and the leg drives down-
    forward straight while the chest and arms go back (action / reaction)."""
    sh = Shot(arm, "Lion.Air1")
    sh.key(0, AIR, "ease")
    sh.key(4, merge(AIR, {"root": {"pitch": 24}, "torso": {"pitch": 18}, "rf": {"z": -.2, "y": 1.7, "toe": -10, "knee": 0}, "lf": {"z": .2, "y": .7}}), "ease")
    hit = merge(AIR, {"root": {"y": -.3, "pitch": -16}, "torso": {"pitch": -10}, "head": {"pitch": 6},
                      "rf": {"x": -.1, "z": -2.3, "y": .4, "toe": 30, "knee": 0}, "lf": {"z": .6, "y": .9, "toe": -40},
                      "la": {"raise": 30, "out": 60, "elbow": 30}, "ra": {"raise": -10, "out": 50, "elbow": 30}})
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"root": {"pitch": -18}, "rf": {"z": -2.4}}), "ease")
    sh.key(22, AIR, "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 8 / 60, "recover": 14 / 60})


def air2(arm):
    """Air axe kick: the straight right leg swings up in front above the
    head (the body opens, arms wide), hangs, then the hips crunch and the
    heel falls through the target at frame 12 - the chest folds over the leg."""
    sh = Shot(arm, "Lion.Air2")
    sh.key(0, AIR, "ease")
    up = merge(AIR, {"root": {"y": -.2, "pitch": -24}, "torso": {"pitch": -10}, "head": {"pitch": 10},
                     "rf": {"x": -.1, "z": -1.3, "y": 3.3, "toe": 10, "knee": 0}, "lf": {"z": .5, "y": .3, "toe": -40},
                     "la": {"raise": 20, "out": 70, "elbow": 20}, "ra": {"raise": 10, "out": 74, "elbow": 20}})
    sh.key(6, up, "launch")
    sh.key(8, merge(up, {"rf": {"z": -1.6, "y": 3.2}}), "ease")
    hit = merge(AIR, {"root": {"y": -.5, "pitch": 30}, "torso": {"pitch": 26}, "head": {"pitch": -4},
                      "rf": {"x": -.1, "z": -2.2, "y": .7, "toe": 20, "knee": 0}, "lf": {"z": .6, "y": .8, "toe": -40},
                      "la": {"raise": 30, "out": 40, "elbow": 40}, "ra": {"raise": 20, "out": 44, "elbow": 40}})
    sh.key(12, hit, "impact")
    sh.key(15, merge(hit, {"root": {"pitch": 34}, "rf": {"y": .5}}), "ease")
    sh.key(26, AIR, "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": 12 / 60, "recover": 17 / 60})


def launcher(arm):
    """The rising kick that opens the Lion Combo: from a dip, the right leg
    swings straight up under the opponent's chin while the support leg
    extends onto its toes - the whole body rises behind the kick (he follows
    it into the air). Arms swing up with it, chest back."""
    sh = Shot(arm, "Lion.Launcher")
    sh.key(0, s(), "ease")
    sh.key(5, s({"root": {"y": -.8, "z": -.2, "pitch": 18, "yaw": 20}, "torso": {"pitch": 12}, "rf": {"y": .12, "toe": -30},
                 "la": {"raise": 30, "elbow": 80}, "ra": {"raise": 20, "elbow": 90}}), "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.1, "z": -.3, "pitch": -18, "yaw": 6}, "torso": {"pitch": -12, "yaw": -4}, "head": {"pitch": 8},
             "rf": {"x": -.3, "z": -1.7, "y": 2.9, "toe": 10, "knee": 0, "yaw": 0}, "lf": {"y": .18, "toe": -50, "yaw": -10},
             "la": {"raise": 150, "out": 20, "elbow": 30}, "ra": {"raise": 120, "out": 30, "elbow": 40}})
    # (The leg swings through a breakdown: knee height in front at 8 f.)
    sh.key(8, s({"travel": {"z": -.15}, "root": {"y": -.4, "z": -.25, "pitch": -2, "yaw": 12}, "torso": {"pitch": -2},
                 "rf": {"x": -.2, "z": -1.3, "y": 1.2, "toe": -10, "knee": 0, "yaw": 0}, "lf": {"y": .1, "toe": -30},
                 "la": {"raise": 100, "elbow": 50}, "ra": {"raise": 80, "elbow": 60}}), "pass")
    sh.key(11, hit, "impact")
    sh.key(14, merge(hit, {"root": {"y": 0, "pitch": -22}, "rf": {"y": 3.1, "z": -1.4}}), "ease")
    sh.key(19, merge(hit, {"root": {"y": -.3, "pitch": -6}, "rf": {"y": 1.4, "z": -1.2, "toe": -10}}), "pass")
    sh.key(24, merge(s({"travel": {"z": -.3}}), {"root": {"y": -.6}, "rf": {"z": .54, "y": 0}}), "impact")
    sh.key(34, s({"travel": {"z": -.3}}), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"contact": 11 / 60, "recover": 17 / 60})


# ============================================================== techniques
WIDE = {"root": {"y": -.72, "z": 0, "pitch": 6, "yaw": 34}, "torso": {"pitch": 2, "yaw": -18}, "head": {"pitch": -4, "yaw": -14}}
SEAL = {"la": {"raise": 62, "out": -34, "twist": 34, "elbow": 112, "wrist": 10}, "ra": {"raise": 62, "out": -34, "twist": 34, "elbow": 112, "wrist": 10}}


def katon(arm):
    """Great Fireball. The body tells it: seals at the chest (the stance
    sinks, the gaze fixes), the inhale (the chest rises and opens, the head
    goes back, the body sits back over the rear foot), the hand brings its
    ring to the mouth, then the projection: everything goes forward at once
    over the front foot, the head pushes forward, the chest empties.
    Channel 0.5 s / Hold (loop) / Release / Recover."""
    out = []
    ch = Shot(arm, "Lion.FireBloom.Channel")
    ch.key(0, s(), "ease")
    ch.key(8, s(merge(WIDE, SEAL)), "ease")
    ch.key(14, s(merge(WIDE, merge(SEAL, {"la": {"twist": 50, "elbow": 118}, "ra": {"raise": 70, "elbow": 104}}))), "pass")
    ch.key(20, s(merge(WIDE, SEAL)), "pass")
    inhale = s(merge(WIDE, {"root": {"y": -.66, "z": .18, "pitch": -6}, "torso": {"pitch": -12}, "head": {"pitch": 14},
                            "ra": {"raise": 96, "out": -40, "twist": 60, "elbow": 128, "wrist": 0},
                            "la": {"raise": 58, "out": -30, "twist": 40, "elbow": 100}}))
    ch.key(30, inhale, "ease")
    ch.drag(["neck"], 2)
    out.append(ch.build(markers={"release": 30 / 60}))
    ho = Shot(arm, "Lion.FireBloom.Hold")
    ho.key(0, inhale, "ease")
    ho.key(20, merge(inhale, {"root": {"y": -.7, "z": .22}, "torso": {"pitch": -15}, "head": {"pitch": 16}}), "ease")
    ho.key(40, inhale, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))
    re = Shot(arm, "Lion.FireBloom.Release")
    blow = s(merge(WIDE, {"root": {"y": -.72, "z": -.38, "pitch": 22}, "torso": {"pitch": 18}, "head": {"pitch": -8},
                          "ra": {"raise": 100, "out": -36, "twist": 60, "elbow": 128},
                          "la": {"raise": 40, "out": -10, "twist": 20, "elbow": 90}, "rf": {"y": .1, "toe": -24}}))
    re.key(0, inhale, "launch")
    re.key(5, blow, "impact")
    re.key(14, merge(blow, {"root": {"z": -.42, "pitch": 24}, "torso": {"pitch": 20}}), "ease")
    re.key(24, merge(blow, {"root": {"z": -.4, "pitch": 22}}), "ease")
    out.append(re.build(markers={"release": 5 / 60}))
    rc = Shot(arm, "Lion.FireBloom.Recover")
    rc.key(0, merge(blow, {"root": {"z": -.4, "pitch": 22}}), "ease")
    rc.key(12, s(merge(WIDE, {"root": {"y": -.6}, "rf": {"y": 0, "toe": 0}})), "pass")
    rc.key(22, s(), "ease")
    rc.drag(["neck"], 2)
    out.append(rc.build())
    return out


CHIDORI_CARRY = {"ra": {"raise": -40, "out": 30, "twist": -20, "elbow": 22, "wrist": -10}, "la": {"raise": 50, "out": 6, "elbow": 80}}


def chidori(arm):
    """Chidori. Form: he drops low and wide (a step out with each foot), the
    right arm down by his side, palm open to the floor, the left hand grips
    the right wrist to steady it (the lightning fights him), the head down,
    eyes up at the target. Hold: the carried arm trails low and back (the
    engine lays it over his run), the left arm forward for balance. Thrust:
    the drive - a long step, the whole body behind the arm, a straight line
    from the rear heel to the fingertips at contact; then the carry past."""
    out = []
    fo = Shot(arm, "Lion.Chidori.Form")
    fo.key(0, s(), "ease")
    fo.key(5, s({"root": {"y": -.7, "pitch": 16}, "rf": {"x": .38, "z": .9, "y": .2}, "lf": {"x": -.22, "z": -.86, "y": .15}}), "pass")
    low = s({"root": {"y": -1.05, "z": .05, "pitch": 26, "yaw": 26}, "torso": {"pitch": 18, "yaw": -6}, "head": {"pitch": -36, "yaw": -16},
             "ra": {"raise": -6, "out": 30, "twist": -40, "elbow": 20, "wrist": 30},
             "la": {"raise": 10, "out": -10, "twist": 40, "elbow": 70, "wrist": 0},
             "rf": {"x": .5, "z": .95, "yaw": 50}, "lf": {"x": -.35, "z": -.95, "yaw": -10}})
    fo.key(10, low, "impact")
    fo.key(20, merge(low, {"root": {"y": -1.12}, "ra": {"twist": -50, "wrist": 36}}), "ease")
    fo.key(37, merge(low, {"root": {"y": -1.0}, "head": {"pitch": -40}}), "ease")
    fo.drag(["neck"], 3)
    out.append(fo.build(markers={"release": 37 / 60}))
    ho = Shot(arm, "Lion.Chidori.Hold")
    carry = merge(STANCE, merge(CHIDORI_CARRY, {"torso": {"pitch": 14, "yaw": 0}}))
    ho.key(0, carry, "ease")
    ho.key(6, merge(carry, {"ra": {"wrist": 4, "elbow": 26}}), "ease")
    ho.key(12, carry, "ease")
    out.append(ho.build(markers={"loop": 0.0}, loop=True))
    th = Shot(arm, "Lion.ChidoriThrust")
    th.key(0, merge(carry, {"root": {"y": -.7, "pitch": 24}}), "ease")
    th.key(4, s({"root": {"y": -.86, "z": .1, "pitch": 30, "yaw": 40}, "torso": {"yaw": -30, "pitch": 16},
                 "ra": {"raise": -50, "out": 30, "elbow": 40}, "la": {"raise": 70, "elbow": 60}, "lf": {"y": .2, "z": -1.4}}), "ease")
    hit = s({"travel": {"z": -1.4}, "root": {"y": -.76, "z": -.7, "pitch": 30, "yaw": -24}, "torso": {"pitch": 10, "yaw": -12}, "head": {"pitch": -14, "yaw": 20},
             "ra": {"raise": 96, "out": -2, "twist": -10, "elbow": 0, "wrist": 10},
             "la": {"raise": -40, "out": 30, "elbow": 30},
             "lf": {"z": -3.0, "y": 0, "toe": 0, "yaw": 10}, "rf": {"y": .12, "toe": -40, "yaw": 20}})
    th.key(7, hit, "impact")
    th.key(11, merge(hit, {"root": {"z": -.82}, "ra": {"raise": 98}}), "ease")
    th.key(18, merge(hit, {"travel": {"z": -1.8}, "root": {"z": -.5, "y": -.66, "yaw": 0}, "ra": {"raise": 70, "elbow": 40},
                           "rf": {"z": -.4, "y": .3, "toe": -20}}), "pass")
    th.key(25, s({"travel": {"z": -2.24}, "lf": {"z": -3.0}, "rf": {"z": -1.4}}), "ease")
    th.drag(["neck"], 2)
    out.append(th.build(markers={"contact": 7 / 60, "recover": 18 / 60}))
    return out


def throw_shuriken(arm):
    """Shuriken pair (upper body; the engine keeps the legs). The throwing
    hand cocks across the chest at the opposite shoulder (the chest turns
    away: the windup), then the chest unwinds and the forearm whips out flat
    - the wrist snaps last at the release frame; follow-through across."""
    sh = Shot(arm, "Lion.Throw.Shuriken")
    sh.key(0, s(), "ease")
    sh.key(5, s({"torso": {"yaw": 22, "pitch": 4}, "head": {"yaw": -30},
                 "la": {"raise": 70, "out": -62, "twist": 40, "elbow": 128, "wrist": 20}}), "ease")
    rel = s({"torso": {"yaw": -18, "pitch": 6}, "head": {"yaw": -10},
             "la": {"raise": 86, "out": 36, "twist": -20, "elbow": 10, "wrist": -24}})
    sh.key(8, rel, "impact")
    sh.key(12, merge(rel, {"torso": {"yaw": -24}, "la": {"out": 50, "wrist": -30}}), "ease")
    sh.key(24, s(), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"release": 8 / 60})


def author(arm):
    acts = [idle(arm), run(arm), run_back(arm), run_side(arm, "R"), run_side(arm, "L"), walk(arm), walk_back(arm),
            walk_side(arm, "R"), walk_side(arm, "L"), sprint(arm), start(arm), brake(arm),
            jump_air(arm), jump_leap(arm), land(arm),
            light1(arm), light2(arm), light3(arm), heavy(arm), air1(arm), air2(arm), launcher(arm)]
    acts += katon(arm)
    acts += chidori(arm)
    acts.append(throw_shuriken(arm))
    return acts
