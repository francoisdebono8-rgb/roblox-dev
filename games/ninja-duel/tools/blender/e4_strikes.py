"""Neji, Gaara, Kakashi, Itachi and Minato re-authored (23/11, étape 4 ANIMATEUR 1, DEC-048).

The same method as the three first (e2_strikes): each blow is rest, anticipation, contact,
follow-through, return, with the DEV's length and markers kept; a clip is written only when it
grades better than the one it replaces (e4_build). Started from the worst clips of the étape 1
audit and of the grades of 23/11 (Sand.Sweep 3.3, Flashstep.Sweep 3.3, Mirage.Sweep 3.3,
Copycat.AirFlip 4.8, Flashstep.AirFlip 4.8, Flashstep.Heavy 5.1, Sand.Light1 5.5...).

The kits' signatures (Naruto part I):
  NEJI (GentleFist)   the Juken stance: wide and deep, the lead palm open in front, fingers up,
                      the rear palm low by the hip; every blow is an open palm or two fingers,
                      driven from the hips turning, the feet hardly move; no punches.
  GAARA (Sand)        he barely moves: upright, the arms crossed; the sand strikes, his hand
                      only points, sweeps, pushes or closes. A blow is a gesture, never a lunge.
  KAKASHI (Copycat)   relaxed and economical, a little hunched, the kunai in a reverse grip in
                      the right hand, the left open in front; short, exact blows, low kicks.
  ITACHI (Mirage)     calm, upright, one hand in his robe: he hits with the other only, or
                      a single kick; minimal motion, a clean stop after each blow.
  MINATO (Flashstep)  low, leaning forward, the three-pronged kunai reversed in the right hand:
                      fast slashes and knees, a spin, nothing wasted.

Space as in e2_strikes: the HumanoidRootPart's (x right, y up, -z forward), the floor at -3.01,
a standing hip at 0, the head's centre at +2.6; a hit lands about 4 studs ahead.
"""
import e2_strikes as E
from e2_strikes import merge, key, pivot, blow

GUARD4 = {
    "GentleFist": {   # the Juken: wide, deep, side-on; lead palm up and open, rear palm low
        "root": {"turn": -42, "pitch": 4, "sink": .38},
        "Waist": {"turn": 6, "pitch": 4},
        "Neck": {"turn": 30, "pitch": 0},
        "LL": {"foot": [-0.5, -1.0], "yaw": 25},
        "RL": {"foot": [0.85, 0.65], "yaw": -62},
        "LA": {"chest": [-0.75, 0.35, -1.85], "hint": [80, 15, 20, 30], "wrist": {"swing": -70}},
        "RA": {"chest": [0.8, -0.75, -1.15], "hint": [40, 25, -10, 60], "wrist": {"swing": -55}},
    },
    "Sand": {         # upright and still, the feet planted, the arms crossed over the chest
        "root": {"turn": -8, "pitch": 0, "sink": .05},
        "Waist": {"turn": 2, "pitch": 0},
        "Neck": {"turn": 6, "pitch": 4},
        "LL": {"foot": [-0.55, -0.15], "yaw": 6},
        "RL": {"foot": [0.6, 0.15], "yaw": -12},
        "LA": {"chest": [0.45, -0.1, -1.1], "hint": [45, 10, 0, 115]},
        "RA": {"chest": [-0.45, 0.05, -1.22], "hint": [45, 10, 0, 115]},
    },
    "Copycat": {      # relaxed, a little hunched; left hand open in front, kunai reversed in the right
        "root": {"turn": -30, "pitch": 8, "sink": .28},
        "Waist": {"turn": 6, "pitch": 6},
        "Neck": {"turn": 22, "pitch": -4},
        "LL": {"foot": [-0.5, -0.75], "yaw": 15},
        "RL": {"foot": [0.75, 0.6], "yaw": -40, "toe": -6},
        "LA": {"chest": [-0.85, 0.15, -1.45], "hint": [70, 20, 10, 60], "wrist": {"swing": -25}},
        "RA": {"chest": [0.5, -0.25, -1.15], "hint": [55, 25, -10, 100], "wrist": {"twist": 80}},
    },
    "Mirage": {       # calm and upright; the left hand inside the robe, the right low and loose
        "root": {"turn": -34, "pitch": 0, "sink": .12},
        "Waist": {"turn": 4, "pitch": 0},
        "Neck": {"turn": 26, "pitch": 6},
        "LL": {"foot": [-0.45, -0.6], "yaw": 18},
        "RL": {"foot": [0.6, 0.45], "yaw": -40},
        "LA": {"chest": [-0.2, 0.0, -0.9], "hint": [35, 15, 0, 120]},
        "RA": {"chest": [0.95, -1.05, -0.55], "hint": [20, 15, 0, 25]},
    },
    "Flashstep": {    # low, leaning in; the kunai reversed forward in the right, the left back
        "root": {"turn": -26, "pitch": 14, "sink": .45},
        "Waist": {"turn": 4, "pitch": 8},
        "Neck": {"turn": 18, "pitch": -12},
        "LL": {"foot": [-0.65, -0.95], "yaw": 14},
        "RL": {"foot": [0.8, 0.7], "yaw": -36, "toe": -10},
        "LA": {"chest": [-1.05, -0.55, -0.55], "hint": [30, 35, 0, 70]},
        "RA": {"chest": [0.3, 0.05, -1.6], "hint": [70, 25, -10, 70], "wrist": {"twist": 90}},
    },
}
E.GUARD.update(GUARD4)
G = GUARD4


def guard_loop4(kit, old):
    g = G[kit]
    L = old["length"]
    if kit == "Sand":           # nothing moves but the breath
        keys = [key(0, g), key(L * .35, g, Waist={"pitch": 2.5, "turn": 4}, Neck={"pitch": 1, "turn": 10}, root={"sink": .1}),
                key(L * .7, g, Waist={"pitch": 1, "turn": 0}, Neck={"pitch": 5, "turn": 2}), key(L, g)]
    elif kit == "GentleFist":   # the lead palm drifts, the weight settles
        keys = [key(0, g), key(L * .5, g, root={"sink": .6}, LA={"chest": [-0.68, 0.3, -1.82]}), key(L, g)]
    elif kit == "Flashstep":    # a light bounce, ready to go
        keys = [key(0, g), key(L * .5, g, root={"sink": .5}, RL={"toe": -16}), key(L, g)]
    else:
        keys = [key(0, g), key(L * .5, g, Waist={"pitch": (g["Waist"].get("pitch", 0) + 1.5)}), key(L, g)]
    return {"keys": keys, "loop": True}


# ------------------------------------------------------------------ NEJI (GentleFist)
def gentle_palm(old, side="L", y=1.35, reach=2.75, low=False, two_finger=False):
    """A Juken palm: the hips turn the hand in, the palm opens at the end, fingers up."""
    lead = side == "L"
    hand = "LA" if lead else "RA"
    other = "RA" if lead else "LA"
    x = -0.1 if lead else 0.1
    yy = -0.2 if low else y
    wrist = {"swing": -80} if not two_finger else {"swing": -10}
    return blow("GentleFist", old,
                antic={"root": {"turn": -52 if lead else -60, "sink": .42}, "Waist": {"turn": -4},
                       hand: {"chest": [x * 3, 0.1, -1.2], "hint": [60, 25, 10, 90], "wrist": wrist}},
                hit={"root": {"turn": -24 if lead else 0, "z": -0.32, "sink": .42 if not low else .62, "pitch": 6 if not low else 18},
                     "Waist": {"turn": 12, "pitch": 4},
                     hand: {"hand": [x, yy, -reach], "hint": [92, 6, 0, 6], "wrist": wrist},
                     other: {"chest": [0.9 if lead else -0.9, -0.75, -0.85], "hint": [25, 30, 0, 70], "wrist": {"swing": -50}}},
                through={"root": {"turn": -18 if lead else 8, "z": -0.36, "sink": .42 if not low else .62, "pitch": 7 if not low else 19},
                         "Waist": {"turn": 14, "pitch": 5},
                         hand: {"hand": [x, yy + .02, -reach - .12], "hint": [92, 6, 0, 3], "wrist": wrist},
                         other: {"chest": [0.9 if lead else -0.9, -0.77, -0.75], "hint": [20, 30, 0, 70], "wrist": {"swing": -50}}},
                through_dt=.07)


def gentle_light1(old):
    return gentle_palm(old, "L", 1.45, 2.7)


def gentle_light2(old):
    return gentle_palm(old, "R", 1.3, 2.75)


def gentle_light3(old):
    return gentle_palm(old, "L", 1.2, 2.85, two_finger=True)


def gentle_light4(old):
    return gentle_palm(old, "R", 1.55, 2.9)


def gentle_palm_thrust(old):     # both palms driven together into the chest, the hips square
    return blow("GentleFist", old,
                antic={"root": {"turn": -55, "sink": .42, "z": 0.12}, "Waist": {"turn": -8},
                       "LA": {"chest": [-0.55, 0.0, -0.9], "hint": [50, 20, 10, 100], "wrist": {"swing": -80}},
                       "RA": {"chest": [0.55, -0.1, -0.9], "hint": [50, 20, -10, 100], "wrist": {"swing": -80}}},
                hit={"root": {"turn": -10, "z": -0.4, "sink": .42, "pitch": 8}, "Waist": {"turn": 8, "pitch": 6},
                     "LA": {"hand": [-0.35, 1.3, -2.7], "hint": [92, 8, 0, 6], "wrist": {"swing": -85}},
                     "RA": {"hand": [0.35, 1.25, -2.7], "hint": [92, 8, 0, 6], "wrist": {"swing": -85}}},
                through={"root": {"turn": -6, "z": -0.45, "sink": .42, "pitch": 9}, "Waist": {"turn": 9, "pitch": 7},
                         "LA": {"hand": [-0.35, 1.32, -2.82], "hint": [92, 8, 0, 3], "wrist": {"swing": -85}},
                         "RA": {"hand": [0.35, 1.27, -2.82], "hint": [92, 8, 0, 3], "wrist": {"swing": -85}}},
                antic_at=.5, through_dt=.08)


def gentle_heavy(old):           # the deep lunge palm: the rear foot turns on its ball, the whole body behind it
    RL0, y0 = [0.85, 0.65], -62
    return blow("GentleFist", old,
                antic={"root": {"turn": -70, "sink": .48, "z": 0.2}, "Waist": {"turn": -12},
                       "RA": {"chest": [0.9, -0.4, -0.3], "hint": [20, 40, 0, 110], "wrist": {"swing": -60}},
                       "LA": {"chest": [-0.8, 0.4, -1.7], "hint": [80, 15, 20, 30], "wrist": {"swing": -70}}},
                hit={"root": {"turn": 6, "z": -0.55, "sink": .48, "pitch": 12}, "Waist": {"turn": 14, "pitch": 8},
                     "RL": pivot(RL0, y0, -40, -28),
                     "RA": {"hand": [0.05, 1.3, -3.0], "hint": [92, 5, 0, 4], "wrist": {"swing": -85}},
                     "LA": {"chest": [-0.8, -0.5, -0.4], "hint": [20, 35, 0, 80], "wrist": {"swing": -50}}},
                through={"root": {"turn": 12, "z": -0.6, "sink": .48, "pitch": 13}, "Waist": {"turn": 16, "pitch": 9},
                         "RL": pivot(RL0, y0, -36, -30),
                         "RA": {"hand": [0.05, 1.32, -3.12], "hint": [92, 5, 0, 2], "wrist": {"swing": -85}},
                         "LA": {"chest": [-0.8, -0.52, -0.3], "hint": [15, 35, 0, 80], "wrist": {"swing": -50}}},
                back={"root": {"turn": -30, "z": -0.2}, "RL": pivot(RL0, y0, -50, -12)},
                antic_at=.5, through_dt=.08)


def gentle_low_palm(old):        # dropped low, the lead palm into the knee
    return gentle_palm(old, "L", 1.0, 2.6, low=True)


def gentle_sweep(old):           # down on the rear leg, the lead leg turns flat through the ankles, palms out for balance
    LL0 = [-0.5, -1.0]
    return blow("GentleFist", old,
                antic={"root": {"turn": -40, "sink": 1.0, "pitch": 14}, "Waist": {"pitch": 8},
                       "LA": {"chest": [-0.9, -0.2, -1.2], "hint": [40, 30, 0, 50], "wrist": {"swing": -70}}},
                hit={"root": {"turn": -5, "sink": 1.15, "pitch": 16}, "Waist": {"pitch": 10, "turn": 6},
                     "LL": {"foot": [0.4, -2.3, -1.9], "hint": [50, 80, -40, 5, -5, 0], "orient": False},
                     "RL": {"foot": [0.85, 0.65], "yaw": -40, "toe": -25},
                     "LA": {"hand": [-1.2, -2.35, -0.6], "hint": [25, 45, 0, 20], "wrist": {"swing": -80}},
                     "RA": {"chest": [1.2, 0.2, 0.1], "hint": [0, 60, 0, 40], "wrist": {"swing": -60}}},
                through={"root": {"turn": 25, "sink": 1.15, "pitch": 16}, "Waist": {"pitch": 10, "turn": 10},
                         "LL": {"foot": [1.3, -2.3, -1.0], "hint": [40, 85, -60, 5, -5, 0], "orient": False},
                         "RL": {"foot": [0.85, 0.65], "yaw": -40, "toe": -25},
                         "LA": {"hand": [-1.25, -2.35, -0.2], "hint": [20, 45, 0, 20], "wrist": {"swing": -80}},
                         "RA": {"chest": [1.25, 0.25, 0.25], "hint": [-5, 60, 0, 40], "wrist": {"swing": -60}}},
                back={"root": {"turn": -30, "sink": .8}, "LL": {"foot": LL0, "yaw": 25, "lift": .25}},
                antic_at=.5, through_dt=.07)


def gentle_airflip(old):
    s = E.leaf_airflip(old, "GentleFist")
    for k in s["keys"][1:-1]:
        k["LA"] = {"swing": 60, "spread": 50, "bend": 20}
        k["RA"] = {"swing": 30, "spread": 60, "bend": 20}
    return s


# ------------------------------------------------------------------ GAARA (Sand)
def sand_gesture(old, side="R", hand_at=(0.3, 1.5, -2.3), wrist=None, lean=0, sweep_to=None, both=False):
    """Gaara's blow: the arms uncross, one hand opens toward the target (the sand does the
    rest); the body hardly turns, a small lean behind the gesture."""
    h = "RA" if side == "R" else "LA"
    o = "LA" if side == "R" else "RA"
    sx = 1 if side == "R" else -1
    w = wrist or {"swing": -30}
    hit_arm = {"hand": [hand_at[0] * sx, hand_at[1], hand_at[2]], "hint": [85, 15, 0, 10], "wrist": w}
    thr = sweep_to or [hand_at[0] * sx, hand_at[1] + .05, hand_at[2] - .12]
    hit = {"root": {"turn": -2 * sx, "pitch": lean}, "Waist": {"turn": 4 * sx, "pitch": lean * .5}, "Neck": {"pitch": 2},
           h: hit_arm}
    through = {"root": {"turn": -3 * sx, "pitch": lean * 1.1}, "Waist": {"turn": 5 * sx, "pitch": lean * .6}, "Neck": {"pitch": 2},
               h: {"hand": thr, "hint": [85, 15, 0, 6], "wrist": w}}
    if both:
        hit[o] = {"hand": [-hand_at[0] * sx, hand_at[1] - .05, hand_at[2]], "hint": [85, 15, 0, 10], "wrist": w}
        through[o] = {"hand": [-thr[0], thr[1] - .05, thr[2]], "hint": [85, 15, 0, 6], "wrist": w}
    else:
        hit[o] = {"chest": [0.35 * sx, -0.1, -0.85], "hint": [40, 10, 0, 120]}
        through[o] = {"chest": [0.35 * sx, -0.1, -0.85], "hint": [40, 10, 0, 120]}
    return blow("Sand", old,
                antic={h: {"chest": [0.7 * sx, 0.3, -0.6], "hint": [40, 30, 0, 110], "wrist": {"swing": 10}}, "Neck": {"pitch": -2}},
                hit=hit, through=through, antic_at=.5, through_dt=.08)


def sand_light1(old):
    return sand_gesture(old, "R", (0.25, 1.45, -2.35))


def sand_light2(old):            # the left hand sweeps across
    return sand_gesture(old, "L", (0.6, 1.3, -2.2), sweep_to=[0.6, 1.3, -2.15], wrist={"swing": -10, "twist": 40})


def sand_light3(old):            # both palms pushed forward
    return sand_gesture(old, "R", (0.35, 1.4, -2.35), both=True, lean=4, wrist={"swing": -75})


def sand_light4(old):            # the right hand rises from low, sand climbing under the target
    return sand_gesture(old, "R", (0.35, 1.9, -2.1), wrist={"swing": -60}, lean=-3)


def sand_fist(old):              # the hand closes in front of him: Sand Fist, the sand clenching with it
    s = sand_gesture(old, "R", (0.3, 1.55, -2.35), wrist={"swing": 10})
    return s


def sand_hand(old):              # the arm thrown up and forward, the hand spread wide
    return sand_gesture(old, "R", (0.45, 2.2, -2.0), wrist={"swing": -80}, lean=-4)


def sand_low_wave(old):          # the arm sweeps low across the ground in front
    return sand_gesture(old, "R", (0.7, -0.6, -2.0), sweep_to=[-0.8, -0.6, -2.05], wrist={"swing": -10, "twist": -60}, lean=8)


def sand_sweep(old):             # no kick: a low hand sweep, the sand cuts the ankles; he only bends a little
    return sand_low_wave(old)


def sand_slam(old):              # the arm raised high, then brought down: the sand crashes on the target
    return blow("Sand", old,
                antic={"RA": {"hand": [0.6, 2.9, -0.6], "hint": [160, 20, 0, 20], "wrist": {"swing": -20}}, "Neck": {"pitch": -12},
                       "root": {"pitch": -4}},
                hit={"RA": {"hand": [0.35, 0.9, -2.3], "hint": [70, 15, 0, 8], "wrist": {"swing": -70}}, "Neck": {"pitch": 10},
                     "root": {"pitch": 8}, "Waist": {"pitch": 6}},
                through={"RA": {"hand": [0.35, 0.6, -2.25], "hint": [60, 15, 0, 6], "wrist": {"swing": -75}}, "Neck": {"pitch": 12},
                         "root": {"pitch": 9}, "Waist": {"pitch": 7}},
                antic_at=.5, through_dt=.09)


# ------------------------------------------------------------------ KAKASHI (Copycat)
def copy_light2(old):            # the reversed kunai cuts across from the right, short and flat
    return blow("Copycat", old,
                antic={"root": {"turn": -46}, "RA": {"chest": [0.95, 0.35, -0.6], "hint": [40, 40, -20, 100], "wrist": {"twist": 80}}},
                hit={"root": {"turn": -6, "z": -0.25, "pitch": 10}, "Waist": {"turn": 10},
                     "RA": {"hand": [0.15, 1.45, -2.45], "hint": [85, 30, -40, 25], "wrist": {"twist": 90}},
                     "LA": {"chest": [-0.95, -0.1, -0.9], "hint": [40, 30, 0, 80]}},
                through={"root": {"turn": 8, "z": -0.28, "pitch": 11}, "Waist": {"turn": 14},
                         "RA": {"hand": [-0.7, 1.35, -2.25], "hint": [75, 30, -60, 30], "wrist": {"twist": 90}},
                         "LA": {"chest": [-1.0, -0.15, -0.8], "hint": [40, 30, 0, 80]}},
                through_dt=.07)


def copy_heavy(old):             # the low roundhouse: the rear leg turns into the thigh, the kunai hand guards
    LL0, y0 = [-0.5, -0.75], 15
    return blow("Copycat", old,
                antic={"root": {"turn": -45, "z": 0.05}, "LL": pivot(LL0, y0, 45, -14),
                       "RL": {"swing": 50, "spread": 40, "twist": -20, "bend": 110, "ankle": -15},
                       "LA": {"chest": [-1.2, 0.2, -0.9], "hint": [50, 40, 0, 80]}},
                hit={"root": {"turn": 18, "lean": 14, "z": 0.1}, "Waist": {"turn": 10, "lean": 6},
                     "LL": pivot(LL0, y0, 95, -22),
                     "RL": {"foot": [-0.15, -0.95, -1.95], "hint": [60, 80, -40, 5, -20, 0], "orient": False},
                     "LA": {"chest": [-1.35, 0.1, -0.6], "hint": [40, 45, 0, 90]},
                     "RA": {"chest": [0.4, 0.2, -1.0], "hint": [60, 25, -10, 110], "wrist": {"twist": 80}}},
                through={"root": {"turn": 38, "lean": 14, "z": 0.1}, "Waist": {"turn": 14, "lean": 6},
                         "LL": pivot(LL0, y0, 115, -22),
                         "RL": {"foot": [-0.95, -0.95, -1.45], "hint": [55, 85, -55, 5, -20, 0], "orient": False},
                         "LA": {"chest": [-1.4, 0.05, -0.4], "hint": [35, 45, 0, 90]},
                         "RA": {"chest": [0.45, 0.15, -0.95], "hint": [60, 25, -10, 110], "wrist": {"twist": 80}}},
                back={"root": {"turn": -10}, "LL": pivot(LL0, y0, 50, -12), "RL": {"foot": [0.75, 0.55], "yaw": -35, "lift": .3}},
                antic_at=.5, through_dt=.08)


def copy_sweep(old):             # crouched, the lead leg cuts the ankles; the left hand on the floor
    LL0 = [-0.5, -0.75]
    return blow("Copycat", old,
                antic={"root": {"turn": -35, "sink": 1.0, "pitch": 18}, "LA": {"hand": [-0.9, -2.4, -0.9], "hint": [40, 30, 0, 20]}},
                hit={"root": {"turn": 0, "sink": 1.15, "pitch": 20}, "Waist": {"pitch": 10},
                     "LL": {"foot": [0.3, -2.3, -2.0], "hint": [50, 80, -40, 5, -5, 0], "orient": False},
                     "RL": {"foot": [0.75, 0.6], "yaw": -40, "toe": -25},
                     "LA": {"hand": [-1.0, -2.45, -0.6], "hint": [30, 40, 0, 15]}},
                through={"root": {"turn": 28, "sink": 1.15, "pitch": 20}, "Waist": {"pitch": 10, "turn": 8},
                         "LL": {"foot": [1.25, -2.3, -1.05], "hint": [40, 85, -60, 5, -5, 0], "orient": False},
                         "RL": {"foot": [0.75, 0.6], "yaw": -40, "toe": -25},
                         "LA": {"hand": [-1.05, -2.45, -0.3], "hint": [25, 40, 0, 15]}},
                back={"root": {"turn": -20, "sink": .8}, "LL": {"foot": LL0, "yaw": 15, "lift": .25}},
                antic_at=.5, through_dt=.07)


def copy_knee(old):              # the clinch: the left hand pulls, the rear knee drives up
    return blow("Copycat", old,
                antic={"root": {"turn": -24, "z": 0.05}, "LA": {"hand": [-0.3, 1.6, -2.2], "hint": [85, 10, 10, 25]}},
                hit={"root": {"turn": -12, "z": -0.3, "pitch": -6}, "Waist": {"pitch": -4},
                     "RL": {"foot": [0.25, -0.75, -1.4], "hint": [95, 5, 0, 5, -40, 0], "orient": False},
                     "LL": {"foot": [-0.5, -0.75], "yaw": 15, "toe": -18},
                     "LA": {"hand": [-0.2, 1.3, -1.5], "hint": [70, 15, 10, 70]}},
                through={"root": {"turn": -10, "z": -0.34, "pitch": -8}, "Waist": {"pitch": -5},
                         "RL": {"foot": [0.25, -0.55, -1.45], "hint": [100, 5, 0, 5, -40, 0], "orient": False},
                         "LL": {"foot": [-0.5, -0.75], "yaw": 15, "toe": -22},
                         "LA": {"hand": [-0.2, 1.25, -1.4], "hint": [70, 15, 10, 75]}},
                back={"RL": {"foot": [0.75, 0.6], "yaw": -40, "lift": .3}},
                through_dt=.07)


def copy_blade_light1(old):      # the tanto: a short thrust from the guard
    return blow("Copycat", old,
                antic={"RA": {"chest": [0.6, -0.1, -0.7], "hint": [40, 25, 0, 110], "wrist": {"swing": 0}}},
                hit={"root": {"turn": -14, "z": -0.3, "pitch": 8}, "Waist": {"turn": 8},
                     "RA": {"hand": [0.2, 1.3, -2.6], "hint": [90, 10, 0, 6], "wrist": {"swing": 10}}},
                through={"root": {"turn": -10, "z": -0.34, "pitch": 9}, "Waist": {"turn": 10},
                         "RA": {"hand": [0.2, 1.32, -2.72], "hint": [90, 10, 0, 3], "wrist": {"swing": 10}}},
                through_dt=.06)


def copy_blade_light2(old):
    return copy_light2(old)


def copy_blade_light3(old):      # the rising cut, low to high across the body
    return blow("Copycat", old,
                antic={"root": {"turn": -50, "sink": .4}, "RA": {"hand": [0.9, -0.4, -1.2], "hint": [30, 40, -20, 60], "wrist": {"twist": 60}}},
                hit={"root": {"turn": -8, "z": -0.3, "pitch": 4, "sink": .2}, "Waist": {"turn": 10, "pitch": -2},
                     "RA": {"hand": [0.0, 1.6, -2.4], "hint": [100, 25, -30, 15], "wrist": {"twist": 60}}},
                through={"root": {"turn": 4, "z": -0.32, "pitch": 2, "sink": .15}, "Waist": {"turn": 14, "pitch": -4},
                         "RA": {"hand": [-0.6, 2.2, -1.9], "hint": [130, 25, -40, 20], "wrist": {"twist": 60}}},
                antic_at=.5, through_dt=.07)


def copy_blade_heavy(old):       # both hands: the overhead cut, the whole body down with it
    return blow("Copycat", old,
                antic={"root": {"turn": -20, "pitch": -6, "z": 0.15}, "Neck": {"pitch": -10},
                       "RA": {"hand": [0.2, 2.9, -0.3], "hint": [160, 15, 0, 25]},
                       "LA": {"hand": [-0.05, 2.8, -0.35], "hint": [160, 15, 0, 25]}},
                hit={"root": {"turn": -6, "pitch": 16, "z": -0.4, "sink": .45}, "Waist": {"pitch": 12}, "Neck": {"pitch": 6},
                     "RA": {"hand": [0.15, 1.1, -2.6], "hint": [80, 10, 0, 6]},
                     "LA": {"hand": [-0.05, 1.05, -2.5], "hint": [80, 10, 0, 8]}},
                through={"root": {"turn": -4, "pitch": 20, "z": -0.45, "sink": .5}, "Waist": {"pitch": 14}, "Neck": {"pitch": 8},
                         "RA": {"hand": [0.15, 0.6, -2.5], "hint": [65, 10, 0, 6]},
                         "LA": {"hand": [-0.05, 0.55, -2.4], "hint": [65, 10, 0, 8]}},
                antic_at=.5, through_dt=.09)


def copy_blade_sweep(old):
    return copy_sweep(old)


def copy_airflip(old):
    s = E.leaf_airflip(old, "Copycat")
    for k in s["keys"][1:-1]:
        k["LA"] = {"swing": 50, "spread": 40, "bend": 40}
        k["RA"] = {"swing": 20, "spread": 30, "bend": 90}
    return s


# ------------------------------------------------------------------ ITACHI (Mirage)
def mirage_light1(old):          # the right back-hand flicked to the face, nothing else moves
    return blow("Mirage", old,
                antic={"RA": {"chest": [0.25, 0.55, -1.15], "hint": [60, 30, -20, 110], "wrist": {"swing": 20}}},
                hit={"root": {"turn": -28, "z": -0.15}, "Waist": {"turn": 6},
                     "RA": {"hand": [0.55, 1.55, -2.45], "hint": [85, 35, -40, 20], "wrist": {"swing": -10}}},
                through={"root": {"turn": -26, "z": -0.17}, "Waist": {"turn": 7},
                         "RA": {"hand": [0.95, 1.5, -2.3], "hint": [80, 40, -50, 25], "wrist": {"swing": -10}}},
                through_dt=.06)


def mirage_light2(old):          # a straight palm to the chest, the robe hand stays in
    return blow("Mirage", old,
                antic={"root": {"turn": -40}, "RA": {"chest": [0.85, -0.2, -0.4], "hint": [20, 35, 0, 110], "wrist": {"swing": -40}}},
                hit={"root": {"turn": -12, "z": -0.3, "pitch": 6}, "Waist": {"turn": 10, "pitch": 3},
                     "RA": {"hand": [0.15, 1.35, -2.75], "hint": [92, 6, 0, 5], "wrist": {"swing": -70}}},
                through={"root": {"turn": -8, "z": -0.33, "pitch": 7}, "Waist": {"turn": 12, "pitch": 4},
                         "RA": {"hand": [0.15, 1.37, -2.85], "hint": [92, 6, 0, 3], "wrist": {"swing": -70}}},
                through_dt=.07)


def mirage_heavy(old):           # one high roundhouse, clean, and set down where it started
    LL0, y0 = [-0.45, -0.6], 18
    return blow("Mirage", old,
                antic={"root": {"turn": -48}, "LL": pivot(LL0, y0, 45, -14),
                       "RL": {"swing": 55, "spread": 40, "twist": -25, "bend": 115, "ankle": -15}},
                hit={"root": {"turn": 20, "lean": 24, "z": 0.1}, "Waist": {"turn": 10, "lean": 8}, "Neck": {"turn": -12, "lean": -10},
                     "LL": pivot(LL0, y0, 98, -22),
                     "RL": {"foot": [-0.1, 0.25, -1.85], "hint": [55, 80, -45, 5, -25, 0], "orient": False},
                     "RA": {"chest": [1.3, -0.2, -0.3], "hint": [10, 50, 0, 60]}},
                through={"root": {"turn": 40, "lean": 24, "z": 0.1}, "Waist": {"turn": 14, "lean": 8}, "Neck": {"turn": -24, "lean": -10},
                         "LL": pivot(LL0, y0, 118, -22),
                         "RL": {"foot": [-0.95, 0.2, -1.4], "hint": [50, 85, -55, 10, -25, 0], "orient": False},
                         "RA": {"chest": [1.35, -0.25, -0.1], "hint": [5, 50, 0, 60]}},
                back={"root": {"turn": -10}, "LL": pivot(LL0, y0, 50, -12), "RL": {"foot": [0.6, 0.45], "yaw": -40, "lift": .3}},
                antic_at=.5, through_dt=.08)


def mirage_sweep(old):           # he drops on the rear leg, the lead leg cuts, the robe hand stays in
    LL0 = [-0.45, -0.6]
    return blow("Mirage", old,
                antic={"root": {"turn": -40, "sink": .95, "pitch": 12},
                       "RA": {"hand": [0.95, -2.35, -0.5], "hint": [20, 35, 0, 15]}},
                hit={"root": {"turn": -5, "sink": 1.1, "pitch": 14}, "Waist": {"pitch": 8},
                     "LL": {"foot": [0.3, -2.3, -1.95], "hint": [50, 80, -40, 5, -5, 0], "orient": False},
                     "RL": {"foot": [0.6, 0.45], "yaw": -40, "toe": -25},
                     "RA": {"hand": [1.0, -2.4, -0.3], "hint": [20, 35, 0, 15]}},
                through={"root": {"turn": 22, "sink": 1.1, "pitch": 14}, "Waist": {"pitch": 8, "turn": 8},
                         "LL": {"foot": [1.2, -2.3, -1.05], "hint": [40, 85, -60, 5, -5, 0], "orient": False},
                         "RL": {"foot": [0.6, 0.45], "yaw": -40, "toe": -25},
                         "RA": {"hand": [1.05, -2.4, 0.0], "hint": [15, 35, 0, 15]}},
                back={"root": {"turn": -24, "sink": .7}, "LL": {"foot": LL0, "yaw": 18, "lift": .25}},
                antic_at=.5, through_dt=.07)


def mirage_airflip(old):
    s = E.leaf_airflip(old, "Mirage")
    for k in s["keys"][1:-1]:
        k["LA"] = {"chest": [-0.2, 0.0, -0.9], "hint": [35, 15, 0, 120]}
        k["RA"] = {"swing": 30, "spread": 50, "bend": 20}
    return s


# ------------------------------------------------------------------ MINATO (Flashstep)
def flash_slash(old, high=1.5, across=True):
    """The reversed kunai: a fast cut across, the body turns behind it, the left hand back."""
    return blow("Flashstep", old,
                antic={"root": {"turn": -46}, "RA": {"chest": [1.0, 0.3, -0.5], "hint": [40, 40, -20, 100], "wrist": {"twist": 90}}},
                hit={"root": {"turn": -4, "z": -0.3, "pitch": 16}, "Waist": {"turn": 10, "pitch": 8},
                     "RA": {"hand": [0.1, high, -2.5], "hint": [85, 30, -40, 25], "wrist": {"twist": 90}},
                     "LA": {"chest": [-1.15, -0.5, -0.2], "hint": [10, 40, 0, 70]}},
                through={"root": {"turn": 12, "z": -0.34, "pitch": 17}, "Waist": {"turn": 14, "pitch": 9},
                         "RA": {"hand": [-0.75 if across else 0.1, high - .1, -2.25], "hint": [75, 30, -60, 30], "wrist": {"twist": 90}},
                         "LA": {"chest": [-1.2, -0.55, -0.1], "hint": [5, 40, 0, 70]}},
                through_dt=.07)


def flash_light1(old):
    return flash_slash(old, 1.5)


def flash_light3(old):           # the knee: the rear knee rises into the body, the kunai guards
    return blow("Flashstep", old,
                antic={"root": {"turn": -20, "z": 0.05}},
                hit={"root": {"turn": -10, "z": -0.32, "pitch": -2}, "Waist": {"pitch": 0},
                     "RL": {"foot": [0.25, -0.7, -1.45], "hint": [95, 5, 0, 5, -40, 0], "orient": False},
                     "LL": {"foot": [-0.65, -0.95], "yaw": 14, "toe": -20},
                     "LA": {"chest": [-1.1, -0.2, -0.6], "hint": [30, 40, 0, 80]}},
                through={"root": {"turn": -8, "z": -0.36, "pitch": -4}, "Waist": {"pitch": -1},
                         "RL": {"foot": [0.25, -0.5, -1.5], "hint": [100, 5, 0, 5, -40, 0], "orient": False},
                         "LL": {"foot": [-0.65, -0.95], "yaw": 14, "toe": -24},
                         "LA": {"chest": [-1.12, -0.22, -0.55], "hint": [30, 40, 0, 80]}},
                back={"RL": {"foot": [0.8, 0.7], "yaw": -36, "lift": .3}},
                through_dt=.07)


def flash_light4(old):           # the backhand return cut, high
    return flash_slash(old, 1.9, across=True)


def flash_heavy(old):            # the spinning cut: a full turn on the lead foot, the kunai at arm's length
    LL0, y0 = [-0.65, -0.95], 14
    return blow("Flashstep", old,
                antic={"root": {"turn": -70, "sink": .5}, "LL": pivot(LL0, y0, -10, -14),
                       "RA": {"chest": [1.1, 0.2, 0.2], "hint": [10, 50, -20, 90], "wrist": {"twist": 90}}},
                hit={"root": {"turn": 30, "z": -0.35, "pitch": 12, "sink": .4}, "Waist": {"turn": 14, "pitch": 6},
                     "LL": pivot(LL0, y0, 60, -22),
                     "RA": {"hand": [-0.2, 0.95, -2.6], "hint": [80, 40, -60, 15], "wrist": {"twist": 90}},
                     "LA": {"chest": [-1.2, -0.3, 0.3], "hint": [-10, 50, 0, 60]}},
                through={"root": {"turn": 60, "z": -0.38, "pitch": 12, "sink": .4}, "Waist": {"turn": 18, "pitch": 6},
                         "LL": pivot(LL0, y0, 85, -22),
                         "RA": {"hand": [-1.35, 0.85, -1.9], "hint": [70, 50, -70, 20], "wrist": {"twist": 90}},
                         "LA": {"chest": [-1.25, -0.35, 0.45], "hint": [-15, 50, 0, 60]}},
                back={"root": {"turn": 0, "z": -0.2}, "LL": pivot(LL0, y0, 30, -12)},
                antic_at=.5, through_dt=.09)


def flash_sweep(old):            # low, the lead leg cuts, the kunai hand on the floor for the pivot
    LL0 = [-0.65, -0.95]
    return blow("Flashstep", old,
                antic={"root": {"turn": -36, "sink": 1.0, "pitch": 18}, "RA": {"hand": [0.9, -2.4, -0.7], "hint": [30, 35, 0, 20]}},
                hit={"root": {"turn": -2, "sink": 1.15, "pitch": 20}, "Waist": {"pitch": 10},
                     "LL": {"foot": [0.3, -2.3, -2.0], "hint": [50, 80, -40, 5, -5, 0], "orient": False},
                     "RL": {"foot": [0.8, 0.7], "yaw": -40, "toe": -25},
                     "RA": {"hand": [1.0, -2.45, -0.4], "hint": [25, 35, 0, 15]}},
                through={"root": {"turn": 26, "sink": 1.15, "pitch": 20}, "Waist": {"pitch": 10, "turn": 8},
                         "LL": {"foot": [1.25, -2.3, -1.05], "hint": [40, 85, -60, 5, -5, 0], "orient": False},
                         "RL": {"foot": [0.8, 0.7], "yaw": -40, "toe": -25},
                         "RA": {"hand": [1.05, -2.45, -0.1], "hint": [20, 35, 0, 15]}},
                back={"root": {"turn": -20, "sink": .8}, "LL": {"foot": LL0, "yaw": 14, "lift": .25}},
                antic_at=.5, through_dt=.07)


def flash_strike(old):           # FlashStrike: the cut out of the teleport, low and long
    return flash_slash(old, 1.2, across=True)


def flash_airflip(old):
    s = E.leaf_airflip(old, "Flashstep")
    for k in s["keys"][1:-1]:
        k["LA"] = {"swing": 40, "spread": 60, "bend": 30}
        k["RA"] = {"swing": 60, "spread": 30, "bend": 70}
    return s


CLIPS = {
    "GentleFist.Guard": lambda o: guard_loop4("GentleFist", o),
    "Sand.Guard": lambda o: guard_loop4("Sand", o),
    "Copycat.Guard": lambda o: guard_loop4("Copycat", o),
    "Mirage.Guard": lambda o: guard_loop4("Mirage", o),
    "Flashstep.Guard": lambda o: guard_loop4("Flashstep", o),
    "GentleFist.Light1": gentle_light1, "GentleFist.Light2": gentle_light2, "GentleFist.Light3": gentle_light3,
    "GentleFist.Light4": gentle_light4, "GentleFist.Heavy": gentle_heavy, "GentleFist.PalmThrust": gentle_palm_thrust,
    "GentleFist.LowPalm": gentle_low_palm, "GentleFist.Sweep": gentle_sweep, "GentleFist.AirFlip": gentle_airflip,
    "Sand.Light1": sand_light1, "Sand.Light2": sand_light2, "Sand.Light3": sand_light3, "Sand.Light4": sand_light4,
    "Sand.SandFist": sand_fist, "Sand.SandHand": sand_hand, "Sand.SandLowWave": sand_low_wave, "Sand.Sweep": sand_sweep,
    "Sand.Slam": sand_slam,
    "Copycat.Light2": copy_light2, "Copycat.Heavy": copy_heavy, "Copycat.Sweep": copy_sweep, "Copycat.KneeStrike": copy_knee,
    "Copycat.AirFlip": copy_airflip, "Copycat.Blade.Light1": copy_blade_light1, "Copycat.Blade.Light2": copy_blade_light2,
    "Copycat.Blade.Light3": copy_blade_light3, "Copycat.Blade.Heavy": copy_blade_heavy, "Copycat.Blade.Sweep": copy_blade_sweep,
    "Mirage.Light1": mirage_light1, "Mirage.Light2": mirage_light2, "Mirage.Heavy": mirage_heavy, "Mirage.Sweep": mirage_sweep,
    "Mirage.AirFlip": mirage_airflip,
    "Flashstep.Light1": flash_light1, "Flashstep.Light3": flash_light3, "Flashstep.Light4": flash_light4,
    "Flashstep.Heavy": flash_heavy, "Flashstep.Sweep": flash_sweep, "Flashstep.FlashStrike": flash_strike,
    "Flashstep.AirFlip": flash_airflip,
}
