"""Passe commune 2 (26/11), ANIMATEUR 3: the moves in the village and the duel, each in three
stages that follow the player's progress (« débutant maladroit, entraîné, ninja »), and the
ninja stage in each kit's own way (measured before: the 8 kits walked, ran, sprinted, jumped
and landed the same, 0 to 4 degrees apart).

How: the legs, the hips and the root of each gait stay the game's (their stride is the one
the engine and HubBody lock the planted foot to: changing them is what makes feet slide);
everything above the waist is authored again over them - the chest's lean and turn, the head,
both arms - in time with the legs (the arm opposite the forward leg swings forward). For the
gaits the arms follow the leg phase measured on the clip itself; for the one-shot moves
(Jump.Air, Land, Start, Brake) they follow keys over the clip's time.

Names (the contract with the DEV, Client/HubBody.clipName):
  <kit>.<Move>        the ninja stage, the kit's own (replaces the clip of that name)
  Trained.<Move>      the trained stage, everyone's (a clean athletic body, no style yet)
  Novice.<Move>       the beginner, everyone's: arms everywhere, stiff, the head down at the feet
Moves: Walk.F, Run.F, Sprint, Jump.Air, Land, Start, Brake.
"""
import math

import numpy as np

import syph_author as SA

KITS = ("Legion", "Lion", "Leaf", "GentleFist", "Sand", "Copycat", "Mirage", "Flashstep")
GAITS = ("Walk.F", "Run.F", "Sprint")
ONCE = ("Jump.Air", "Land", "Start", "Brake")
UPPER = ("Waist", "Neck", "Right", "Left", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist")
ARM_J = {"RA": ("RightShoulder", "RightElbow", "RightWrist"), "LA": ("LeftShoulder", "LeftElbow", "LeftWrist")}


# ------------------------------------------------------------------ frames
def rows_of(clip):
    w = {k: (7 if k == "Root" else 4) for k in clip["joints"]}
    return {k: [v[i:i + w[k]] for i in range(0, len(v), w[k])] for k, v in clip["joints"].items()}


def resample(clip, fps=None):
    """The clip's own samples, as they are: the engine plays a loop over (frames - 1) / fps
    (AuthoredMotion.sample), which is not always its "length"; resampling to another rate moved
    the planted feet off the beat the engine locks them to (tests/Film10Feet). Only the upper
    body is written over them."""
    R = rows_of(clip)
    return clip["frames"], {k: [list(r) for r in v] for k, v in R.items()}


def leg_forward(rows, i, key="RightHip"):
    """How far forward (-z) the leg's knee direction points at sample i."""
    R = SA.q_to_R(rows[key][i])
    return float(-(R @ np.array([0, -1, 0]))[2])


def phase0(rows, n):
    """The clip's time (0..1) where the right leg is furthest forward."""
    best = max(range(n - 1), key=lambda i: leg_forward(rows, i) - leg_forward(rows, i, "LeftHip"))
    return best / max(1, n - 1)


# ------------------------------------------------------------------ the upper body
def q_of(joint, sem):
    return [round(float(x), 4) for x in SA.R_to_q(SA.sem_R(joint, sem))]


def arm_quats(side, a):
    """a: {swing, spread, twist, bend, wrist{}} -> {clip key: quaternion}."""
    up, mid, wr = ARM_J[side]
    T = SA._limb_T(side, [a.get("swing", 0), a.get("spread", 0), a.get("twist", 0), a.get("bend", 0)])
    k = SA.KEYS
    return {k[up]: [round(float(x), 4) for x in SA.R_to_q(T[up][1])],
            k[mid]: [round(float(x), 4) for x in SA.R_to_q(T[mid][1])],
            k[wr]: q_of(wr, a.get("wrist", {}))}


_IK = {}


def held(side, chest, hint, wrist=None):
    """A held arm (a hand in a pocket, the arms crossed, a book read): solved once on a plain
    standing body, kept as its angles (it then moves with the chest)."""
    key = (side, tuple(chest), tuple(hint))
    if key not in _IK:
        k = {"root": {"sink": .05}, "LL": {"foot": [-0.5, 0.0]}, "RL": {"foot": [0.5, 0.0]},
             side: {"chest": list(chest), "hint": list(hint)}}
        T, _ = SA.build_key(k)
        x = T["_x"][side]
        _IK[key] = {"swing": float(x[0]), "spread": float(x[1]), "twist": float(x[2]), "bend": float(x[3])}
    a = dict(_IK[key])
    if wrist:
        a["wrist"] = wrist
    return a


def lerp_sem(a, b, u):
    out = {}
    for k in set(a) | set(b):
        va, vb = a.get(k, 0), b.get(k, 0)
        if isinstance(va, dict) or isinstance(vb, dict):
            out[k] = lerp_sem(va if isinstance(va, dict) else {}, vb if isinstance(vb, dict) else {}, u)
        else:
            out[k] = va + (vb - va) * u
    return out


def smooth(u):
    return u * u * (3 - 2 * u)


# ------------------------------------------------------------------ styles
# A gait style: the chest's lean (Waist pitch), its counter-turn, the head, and for each arm
# either a swing (base angles + "amp" fore/aft in time with the legs) or a held pose.
def swing(amp, bend, spread=10, base=0, twist=0, bend_amp=0, wrist=None):
    return {"amp": amp, "swing": base, "spread": spread, "twist": twist, "bend": bend, "bend_amp": bend_amp, "wrist": wrist or {}}


def NINJA_BACK(lift=0, spread=14, bend=12, side=None):
    """The ninja run's arms: the hands trailing behind the hips (solved as held hands, so they
    stay behind the body whatever its lean); `lift` raises them, `spread` opens them."""
    return {"back": (lift, spread, bend), "amp": 5}
POCKET_R = ("RA", (0.85, -1.55, 0.15), (-10, 20, 0, 40))
POCKET_L = ("LA", (-0.85, -1.55, 0.15), (-10, 20, 0, 40))
CROSS_R = ("RA", (-0.45, 0.05, -1.22), (45, 10, 0, 115))
CROSS_L = ("LA", (0.45, -0.1, -1.1), (45, 10, 0, 115))
ROBE_L = ("LA", (-0.2, 0.0, -0.9), (35, 15, 0, 120))
BOOK_R = ("RA", (0.1, 0.05, -1.45), (60, 25, -20, 110))
BACK_R = ("RA", (0.3, -0.75, 0.98), (-45, 10, 0, 75))
HIP_L = ("LA", (-0.95, -1.25, -0.15), (10, 60, 0, 110))


def hold(spec):
    return {"held": spec}


STYLE = {
    # stage: everyone's
    "Novice": {
        "Walk.F": {"pitch": 10, "turn": 4, "neck": {"pitch": 22}, "bob": 6,
                   "RA": swing(38, 4, 16), "LA": swing(38, 4, 16)},
        "Run.F": {"pitch": -6, "turn": 10, "neck": {"pitch": 8}, "bob": 10, "lag": .12,
                  "RA": swing(70, 10, 38, base=15), "LA": swing(70, 10, 38, base=15)},
        "Sprint": {"pitch": -10, "turn": 14, "neck": {"pitch": 4}, "bob": 12, "lag": .18,
                   "RA": swing(85, 15, 50, base=30, bend_amp=30), "LA": swing(85, 15, 50, base=30, bend_amp=30)},
    },
    "Trained": {
        "Walk.F": {"pitch": 2, "turn": 4, "neck": {"pitch": 2}, "RA": swing(24, 22, 8), "LA": swing(24, 22, 8)},
        "Run.F": {"pitch": 8, "turn": 8, "neck": {"pitch": -4}, "RA": swing(48, 85, 10), "LA": swing(48, 85, 10)},
        "Sprint": {"pitch": 14, "turn": 9, "neck": {"pitch": -8}, "RA": swing(62, 92, 8, base=5), "LA": swing(62, 92, 8, base=5)},
    },
    # the ninja stage, kit by kit
    "Legion": {   # Naruto: cocky in the walk, and THE run: thrown forward, arms straight back, flapping
        "Walk.F": {"pitch": -2, "turn": 8, "neck": {"pitch": -6}, "bob": 3, "RA": swing(40, 15, 16), "LA": swing(40, 15, 16)},
        "Run.F": {"pitch": 30, "turn": 3, "neck": {"pitch": -26}, "RA": dict(NINJA_BACK(spread=20), amp=14), "LA": dict(NINJA_BACK(spread=20), amp=14)},
        "Sprint": {"pitch": 38, "turn": 3, "neck": {"pitch": -32}, "RA": dict(NINJA_BACK(-4, 22), amp=16), "LA": dict(NINJA_BACK(-4, 22), amp=16)},
    },
    "Lion": {     # Sasuke: hands in his pockets on foot; a tight, clean ninja run, the head up
        "Walk.F": {"pitch": -3, "turn": 2, "neck": {"pitch": 4, "turn": 8}, "RA": hold(POCKET_R), "LA": hold(POCKET_L)},
        "Run.F": {"pitch": 24, "turn": 2, "neck": {"pitch": -18}, "RA": NINJA_BACK(0, 8, 8), "LA": NINJA_BACK(0, 8, 8)},
        "Sprint": {"pitch": 30, "turn": 2, "neck": {"pitch": -24}, "RA": NINJA_BACK(-6, 8, 6), "LA": NINJA_BACK(-6, 8, 6)},
    },
    "Leaf": {     # Lee: the sprinter: big pumping arms, upright and driving, never the ninja run
        # walking and running in his stance, the rear hand stays behind his back (tests/Lee); the
        # sprint lets both arms go
        "Walk.F": {"pitch": 4, "turn": 6, "neck": {"pitch": -2}, "bob": 4, "RA": hold(BACK_R), "LA": swing(40, 70, 10)},
        "Run.F": {"pitch": 12, "turn": 8, "neck": {"pitch": -6}, "RA": hold(BACK_R), "LA": swing(80, 95, 6, base=10, bend_amp=12)},
        "Sprint": {"pitch": 16, "turn": 14, "neck": {"pitch": -10}, "RA": swing(95, 100, 6, base=15, bend_amp=15), "LA": swing(95, 100, 6, base=15, bend_amp=15)},
    },
    "GentleFist": {   # Neji: upright and quiet, the arms hardly move; the run: palms open, arms back, chest up
        "Walk.F": {"pitch": -2, "turn": 1, "neck": {"pitch": 2}, "RA": swing(8, 8, 6), "LA": swing(8, 8, 6)},
        "Run.F": {"pitch": 14, "turn": 1, "neck": {"pitch": -10}, "RA": NINJA_BACK(10, 26, 4), "LA": NINJA_BACK(10, 26, 4)},
        "Sprint": {"pitch": 20, "turn": 1, "neck": {"pitch": -14}, "RA": NINJA_BACK(4, 26, 4), "LA": NINJA_BACK(4, 26, 4)},
    },
    "Sand": {     # Gaara: the arms crossed, always; the chest does not turn
        "Walk.F": {"pitch": 0, "turn": 0, "neck": {"pitch": 4}, "RA": hold(CROSS_R), "LA": hold(CROSS_L)},
        "Run.F": {"pitch": 6, "turn": 0, "neck": {"pitch": 0}, "RA": hold(CROSS_R), "LA": hold(CROSS_L)},
        "Sprint": {"pitch": 10, "turn": 0, "neck": {"pitch": -4}, "RA": hold(CROSS_R), "LA": hold(CROSS_L)},
    },
    "Copycat": {  # Kakashi: walking while he reads, the other hand in his pocket; a loose, low run
        "Walk.F": {"pitch": 8, "turn": 1, "neck": {"pitch": 20}, "RA": hold(BOOK_R), "LA": hold(POCKET_L)},
        "Run.F": {"pitch": 26, "turn": 3, "neck": {"pitch": -18}, "RA": NINJA_BACK(8, 12, 30), "LA": NINJA_BACK(8, 12, 30)},
        "Sprint": {"pitch": 32, "turn": 3, "neck": {"pitch": -24}, "RA": NINJA_BACK(2, 12, 24), "LA": NINJA_BACK(2, 12, 24)},
    },
    "Mirage": {   # Itachi: the hand in the robe even running; the other arm barely moves, or goes back
        "Walk.F": {"pitch": 0, "turn": 0, "neck": {"pitch": 6}, "LA": hold(ROBE_L), "RA": swing(6, 6, 5)},
        "Run.F": {"pitch": 20, "turn": 1, "neck": {"pitch": -14}, "LA": hold(ROBE_L), "RA": NINJA_BACK(0, 10, 6)},
        "Sprint": {"pitch": 26, "turn": 1, "neck": {"pitch": -20}, "LA": hold(ROBE_L), "RA": NINJA_BACK(-4, 10, 6)},
    },
    "Flashstep": {    # Minato: a light walk, a hand on the hip; the lowest run of all, the kunai hand forward
        "Walk.F": {"pitch": 2, "turn": 4, "neck": {"pitch": 0}, "LA": hold(HIP_L), "RA": swing(18, 18, 8)},
        "Run.F": {"pitch": 36, "turn": 2, "neck": {"pitch": -30}, "LA": NINJA_BACK(-6, 12, 10),
                  "RA": {"amp": 4, "swing": 30, "spread": 8, "twist": 60, "bend": 70, "bend_amp": 0, "wrist": {"twist": 90}}},
        "Sprint": {"pitch": 44, "turn": 2, "neck": {"pitch": -36}, "LA": NINJA_BACK(-10, 12, 8),
                   "RA": {"amp": 4, "swing": 25, "spread": 8, "twist": 60, "bend": 60, "bend_amp": 0, "wrist": {"twist": 90}}},
    },
}


def arm_at(spec, side, c):
    """c = cos of the leg phase (+1: the right leg furthest forward)."""
    if "held" in spec:
        s, chest, hint = spec["held"]
        return held(s, chest, hint)
    if "back" in spec:
        lift, spread, bend = spec["back"]
        sx = 1 if side == "RA" else -1
        a = held(side, (sx * (0.75 + spread / 100), -1.25 + lift / 50, 1.05), (-40, 20, 0, max(5, bend)))
        a = dict(a)
        a["swing"] += (-1 if side == "RA" else 1) * spec.get("amp", 0) * c
        a["wrist"] = {"swing": -25}
        return a
    sign = -1 if side == "RA" else 1          # the right arm back when the right leg is forward
    return {"swing": spec["swing"] + sign * spec["amp"] * c, "spread": spec["spread"], "twist": spec["twist"],
            "bend": max(0, spec["bend"] + spec.get("bend_amp", 0) * sign * c), "wrist": spec.get("wrist", {})}


def gait(old, style):
    n, rows = resample(old)
    u0 = phase0(rows, n)
    for i in range(n):
        u = i / max(1, n - 1)
        th = 2 * math.pi * (u - u0)
        c = math.cos(th)
        c2 = math.cos(2 * th)
        lag = style.get("lag", 0)
        cR, cL = math.cos(th - lag * 2 * math.pi), math.cos(th + lag * 2 * math.pi)
        up = {"Waist": q_of("Waist", {"pitch": style["pitch"] + style.get("bob", 0) * .3 * c2, "turn": style.get("turn", 0) * c}),
              "Neck": q_of("Neck", {"pitch": style["neck"].get("pitch", 0) + style.get("bob", 0) * .5 * c2,
                                    "turn": style["neck"].get("turn", 0) - style.get("turn", 0) * .6 * c})}
        up.update(arm_quats("RA", arm_at(style["RA"], "RA", cR)))
        up.update(arm_quats("LA", arm_at(style["LA"], "LA", cL)))
        for k, q in up.items():
            rows[k][i] = q
    # a loop closes on itself
    for k in UPPER:
        rows[k][-1] = list(rows[k][0])
    return {"fps": old["fps"], "frames": n, "length": old["length"], "loop": True, "markers": dict(old.get("markers") or {}),
            "meta": dict(old.get("meta") or {}), "joints": rows}


# ------------------------------------------------------------------ the one-shot moves
def A(swing_, spread, bend, twist=0, wrist=None):
    return {"swing": swing_, "spread": spread, "twist": twist, "bend": bend, "wrist": wrist or {}}


def held_a(spec):
    s, chest, hint = spec
    return held(s, chest, hint)


# keys over the clip's time: (u, {"Waist": {...}, "Neck": {...}, "RA": arm, "LA": arm})
def once_keys(stage, move):
    if stage == "Novice":
        return {
            "Jump.Air": [(0, {"Waist": {"pitch": -8}, "Neck": {"pitch": -14}, "RA": A(150, 55, 10), "LA": A(150, 55, 10)}),
                         (.5, {"Waist": {"pitch": -12}, "Neck": {"pitch": -6}, "RA": A(120, 80, 30), "LA": A(170, 40, 20)}),
                         (1, {"Waist": {"pitch": 10}, "Neck": {"pitch": 24}, "RA": A(60, 85, 20), "LA": A(80, 80, 25)})],
            "Land": [(0, {"Waist": {"pitch": 18}, "Neck": {"pitch": 26}, "RA": A(80, 70, 20), "LA": A(70, 70, 20)}),
                     (.3, {"Waist": {"pitch": 34}, "Neck": {"pitch": 30}, "RA": A(140, 60, 10), "LA": A(20, 80, 10)}),
                     (.6, {"Waist": {"pitch": 20}, "Neck": {"pitch": 10}, "RA": A(30, 75, 20), "LA": A(130, 60, 15)}),
                     (1, {"Waist": {"pitch": 6}, "Neck": {"pitch": 10}, "RA": A(5, 15, 10), "LA": A(5, 15, 10)})],
            "Start": [(0, {"Waist": {"pitch": -6}, "RA": A(-40, 30, 10), "LA": A(-40, 30, 10)}),
                      (.5, {"Waist": {"pitch": -14}, "Neck": {"pitch": -10}, "RA": A(70, 50, 15), "LA": A(-50, 50, 15)}),
                      (1, {"Waist": {"pitch": 0}, "RA": A(20, 30, 20), "LA": A(-20, 30, 20)})],
            "Brake": [(0, {"Waist": {"pitch": -10}, "RA": A(60, 50, 10), "LA": A(60, 50, 10)}),
                      (.4, {"Waist": {"pitch": 22}, "Neck": {"pitch": 20}, "RA": A(150, 70, 10), "LA": A(40, 80, 10)}),
                      (.75, {"Waist": {"pitch": 10}, "RA": A(40, 75, 15), "LA": A(150, 70, 10)}),
                      (1, {"Waist": {"pitch": 4}, "Neck": {"pitch": 8}, "RA": A(5, 15, 10), "LA": A(5, 15, 10)})],
        }[move]
    if stage == "Trained":
        return {
            "Jump.Air": [(0, {"Waist": {"pitch": -4}, "RA": A(110, 15, 30), "LA": A(110, 15, 30)}),
                         (1, {"Waist": {"pitch": 8}, "Neck": {"pitch": 6}, "RA": A(40, 30, 40), "LA": A(40, 30, 40)})],
            "Land": [(0, {"Waist": {"pitch": 20}, "Neck": {"pitch": -10}, "RA": A(55, 30, 40), "LA": A(55, 30, 40)}),
                     (1, {"Waist": {"pitch": 4}, "RA": A(10, 12, 25), "LA": A(10, 12, 25)})],
            "Start": [(0, {"Waist": {"pitch": 10}, "RA": A(-35, 10, 80), "LA": A(40, 10, 80)}),
                      (1, {"Waist": {"pitch": 10}, "RA": A(35, 10, 85), "LA": A(-35, 10, 85)})],
            "Brake": [(0, {"Waist": {"pitch": -12}, "RA": A(40, 20, 50), "LA": A(40, 20, 50)}),
                      (1, {"Waist": {"pitch": 2}, "RA": A(10, 12, 25), "LA": A(10, 12, 25)})],
        }[move]
    return None


# the ninja stage's one-shot moves, kit by kit: what each does with his arms in the air and
# on the way down (the legs are the game's)
def ninja_once(kit, move):
    back = arm_at(NINJA_BACK(), "RA", 0)
    back_l = arm_at(NINJA_BACK(), "LA", 0)
    tuck = A(40, 25, 100)
    styl = {
        "Legion": {"air": (arm_at(NINJA_BACK(-6, 24), "RA", 0), arm_at(NINJA_BACK(-6, 24), "LA", 0)), "land": (A(60, 70, 30), A(-40, 60, 20)), "pitch": 18},
        "Lion": {"air": (back, back_l), "land": (A(-30, 20, 30), A(60, 30, 60)), "pitch": 14},
        "Leaf": {"air": (A(80, 15, 95), A(-30, 15, 95)), "land": (A(50, 25, 90), A(-40, 20, 90)), "pitch": 10},
        "GentleFist": {"air": (A(-40, 50, 5, wrist={"swing": -60}), A(-40, 50, 5, wrist={"swing": -60})),
                       "land": (A(70, 30, 10, wrist={"swing": -80}), A(-20, 40, 10)), "pitch": 6},
        "Sand": {"air": (held_a(CROSS_R), held_a(CROSS_L)), "land": (held_a(CROSS_R), held_a(CROSS_L)), "pitch": 2},
        "Copycat": {"air": (tuck, A(-50, 15, 20)), "land": (A(30, 30, 40), A(-10, 20, 30)), "pitch": 16},
        "Mirage": {"air": (A(-50, 15, 10), held_a(ROBE_L)), "land": (A(-20, 15, 10), held_a(ROBE_L)), "pitch": 4},
        "Flashstep": {"air": (A(30, 10, 70, 60, {"twist": 90}), back_l), "land": (A(40, 15, 70, 60, {"twist": 90}), back_l), "pitch": 22},
    }[kit]
    ra, la = styl["air"]
    lra, lla = styl["land"]
    p = styl["pitch"]
    rest = (A(4, 10, 15), A(4, 10, 15))
    if kit == "Sand":
        rest = (held_a(CROSS_R), held_a(CROSS_L))
    if kit == "Mirage":
        rest = (A(3, 6, 8), held_a(ROBE_L))
    return {
        "Jump.Air": [(0, {"Waist": {"pitch": p * .5}, "Neck": {"pitch": -p * .4}, "RA": ra, "LA": la}),
                     (1, {"Waist": {"pitch": p}, "Neck": {"pitch": -p * .3}, "RA": ra, "LA": la})],
        "Land": [(0, {"Waist": {"pitch": p + 12}, "Neck": {"pitch": -p * .6}, "RA": lra, "LA": lla}),
                 (.45, {"Waist": {"pitch": p + 6}, "Neck": {"pitch": -p * .4}, "RA": lra, "LA": lla}),
                 (1, {"Waist": {"pitch": 2}, "RA": rest[0], "LA": rest[1]})],
        "Start": [(0, {"Waist": {"pitch": p * .6}, "Neck": {"pitch": -p * .5}, "RA": rest[0], "LA": rest[1]}),
                  (1, {"Waist": {"pitch": p}, "Neck": {"pitch": -p * .7}, "RA": ra, "LA": la})],
        "Brake": [(0, {"Waist": {"pitch": p}, "Neck": {"pitch": -p * .7}, "RA": ra, "LA": la}),
                  (.5, {"Waist": {"pitch": -6}, "Neck": {"pitch": 4}, "RA": lra, "LA": lla}),
                  (1, {"Waist": {"pitch": 0}, "RA": rest[0], "LA": rest[1]})],
    }[move]


def once(old, keys):
    n, rows = resample(old)
    for i in range(n):
        u = i / max(1, n - 1)
        j = max(idx for idx, (uk, _) in enumerate(keys) if uk <= u + 1e-9)
        k2 = min(len(keys) - 1, j + 1)
        ua, a = keys[j]; ub, b = keys[k2]
        w = 0.0 if k2 == j else smooth((u - ua) / (ub - ua))
        s = lerp_sem(a, b, w)
        up = {"Waist": q_of("Waist", s.get("Waist", {})), "Neck": q_of("Neck", s.get("Neck", {}))}
        up.update(arm_quats("RA", s["RA"]))
        up.update(arm_quats("LA", s["LA"]))
        for kk, q in up.items():
            rows[kk][i] = q
    return {"fps": old["fps"], "frames": n, "length": old["length"], "loop": bool(old.get("loop")), "markers": dict(old.get("markers") or {}),
            "meta": dict(old.get("meta") or {}), "joints": rows}


# ------------------------------------------------------------------ the list p2_build reads
def _gait_fn(stage, move):
    def fn(old):
        return {"clip": gait(old, STYLE[stage][move])}
    return fn


def _once_fn(stage, move):
    def fn(old):
        keys = ninja_once(stage, move) if stage in KITS else once_keys(stage, move)
        return {"clip": once(old, keys)}
    return fn


def _side_fn(kit, move):
    """Walk/Run backwards and sideways: the same arms and head as the kit's forward gait (the
    engine blends the directions: arms in one style forward and another sideways snapped
    when the direction turned), the chest's lean a third of it."""
    def fn(old):
        st = dict(STYLE[kit]["Walk.F" if move.startswith("Walk") else "Run.F"])
        st["pitch"] = st["pitch"] * (.3 if not move.endswith(".B") else 0)
        return {"clip": gait(old, st)}
    return fn


CLIPS = {}      # name -> fn(old) ; fn.base: the game's clip it is built over
for _kit in KITS:
    for _move in ("Walk.B", "Walk.L", "Walk.R", "Run.B", "Run.L", "Run.R"):
        _fn = _side_fn(_kit, _move)
        _fn.base = "%s.%s" % (_kit, _move)
        CLIPS[_fn.base] = _fn
for _stage in KITS + ("Trained", "Novice"):
    for _move in GAITS + ONCE:
        _fn = _gait_fn(_stage, _move) if _move in GAITS else _once_fn(_stage, _move)
        if _stage in KITS:
            _fn.base = "%s.%s" % (_stage, _move)
            CLIPS[_fn.base] = _fn
        else:
            _fn.base = "Lion.%s" % _move
            CLIPS["%s.%s" % (_stage, _move)] = _fn
