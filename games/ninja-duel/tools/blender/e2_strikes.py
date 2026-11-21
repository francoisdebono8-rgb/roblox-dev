"""Naruto, Sasuke and Lee re-authored (21/11, étape 2 ANIMATEUR 1, DEC-045).

Written from FICHES_MOUVEMENT.md (the references: Naruto part I) and the worst clips of the
étape 1 audit (docs/reports/audit-clips-2026-11-20). Each blow is its five poses - rest,
anticipation, contact, follow-through, return - with the kit's own way of moving:

  NARUTO (Legion)  fast and messy: low open guard on the balls of the feet, big readable
                   wind-ups, blows that go too far (he overshoots) and a clumsy catch.
  SASUKE (Lion)    held, then explosive: side-on guard, rear hand by the chin, front hand
                   low and open; a short pause, a dry start, a clean end; kicks that rise.
  LEE (Leaf)       the fastest, in bursts: the Goken guard (open hand forward, the other
                   behind his back), a deep lunge, kicks before fists; the hand behind his
                   back only comes out for the big blows.

The timings are the DEV's: every clip keeps the length and the markers of the one it replaces
(syph_author.make_clip); keys are placed around "contact" and "recover".

Space: the HumanoidRootPart's (x right, y up, -z forward); the floor at -3.01, a standing
hip at 0, the head's centre at +2.6 standing; a hit lands about 4 studs ahead (Attacks.contact).
"""
import copy


def merge(*parts):
    out = {}
    for p in parts:
        for k, v in p.items():
            if isinstance(v, dict) and isinstance(out.get(k), dict):
                d = dict(out[k]); d.update(v); out[k] = d
            else:
                out[k] = copy.deepcopy(v)
    return out


FULL = ("foot", "hand", "chest", "swing", "spread", "twist", "bend")


def key(t, base, ease="smooth", **over):
    """A key: the base pose with some parts changed. A limb given a new target or new angles
    is replaced whole; a limb given only modifiers (toe, yaw, lift, wrist, hint) keeps the
    rest of its base."""
    over = dict(over)
    full = {n: over.pop(n) for n in ("RA", "LA", "RL", "LL") if n in over and any(f in over[n] for f in FULL)}
    k = merge(base, over)
    for n, v in full.items():
        k[n] = copy.deepcopy(v)
    k["t"] = t
    k["ease"] = ease
    return k


# ------------------------------------------------------------------ guards
# (orthodox: left foot forward, the body turned to its right - Root turn < 0)
GUARD = {
    "Legion": {   # low and open, elbows out, chin down, weight forward on the balls of the feet
        "root": {"turn": -18, "pitch": 8, "sink": .35},
        "Waist": {"turn": 4, "pitch": 10},
        "Neck": {"turn": 14, "pitch": -6},
        "LL": {"foot": [-0.8, -0.6], "yaw": 12, "toe": 0},
        "RL": {"foot": [0.85, 0.55], "yaw": -28, "toe": -8},
        "LA": {"chest": [-0.95, 0.15, -1.35], "hint": [70, 25, 10, 80], "wrist": {"swing": -10}},
        "RA": {"chest": [0.6, 0.0, -1.3], "hint": [55, 25, -10, 95], "wrist": {"swing": -10}},
    },
    "Lion": {     # side-on, narrow; rear hand by the chin, front hand low and open
        "root": {"turn": -50, "pitch": 2, "sink": .2},
        "Waist": {"turn": 8, "pitch": 2},
        "Neck": {"turn": 36, "pitch": 4},
        "LL": {"foot": [-0.25, -0.7], "yaw": 35},
        "RL": {"foot": [0.45, 0.55], "yaw": -60},
        "LA": {"chest": [-1.4, -0.5, -0.85], "hint": [45, 15, 20, 45], "wrist": {"swing": 15}},
        "RA": {"chest": [-0.55, 0.5, -1.1], "hint": [70, 30, -20, 120]},
    },
    "Leaf": {     # the Goken: deep lunge, open hand forward, the other behind the back
        "root": {"turn": -24, "pitch": 0, "sink": .45},
        "Waist": {"turn": 8, "pitch": -2},
        "Neck": {"turn": 16, "pitch": 2},
        "LL": {"foot": [-0.4, -1.1], "yaw": 8},
        "RL": {"foot": [0.6, 0.9], "yaw": -35, "toe": -14},
        "LA": {"chest": [-0.76, 0.37, -1.96], "hint": [85, 10, 30, 25], "wrist": {"swing": -60}},
        "RA": {"chest": [0.3, -0.75, 0.98], "hint": [-45, 10, 0, 75]},
    },
}


def guard_loop(kit, old):
    """The guard idle: the stance breathing (Lee and Sasuke) or bouncing (Naruto)."""
    g = GUARD[kit]
    L = old["length"]
    if kit == "Legion":       # bounces on his toes, twice a loop, the hands fidget
        up = {"RL": {"toe": -16}, "LL": {"toe": -6}}
        keys = [key(0, g), key(L * .25, g, **merge(up, {"Waist": {"pitch": 6}, "LA": {"chest": [-0.9, 0.25, -1.3]}})),
                key(L * .5, g), key(L * .75, g, **merge(up, {"Waist": {"pitch": 7}, "RA": {"chest": [0.55, 0.1, -1.25]}})), key(L, g)]
    elif kit == "Lion":       # still; the chest breathes, the front hand drifts
        keys = [key(0, g), key(L * .5, g, **{"Waist": {"pitch": 0, "turn": 6}, "LA": {"chest": [-1.38, -0.42, -0.85]},
                                            "Neck": {"turn": 38, "pitch": 2}}), key(L, g)]
    else:                     # Lee bounces lightly in his lunge
        keys = [key(0, g), key(L * .5, g, **{"root": {"pitch": 2}, "LA": {"chest": [-0.76, 0.3, -1.94]}, "RL": {"toe": -20}}), key(L, g)]
    return {"keys": keys, "loop": True}


def pivot(foot, yaw0, yaw, toe=-22, ball=.55):
    """A foot turning on its ball (heel up): its centre moves round the ball so the ball stays
    where it is on the floor (no sliding sole)."""
    import math
    h0 = (-math.sin(math.radians(yaw0)), -math.cos(math.radians(yaw0)))
    h = (-math.sin(math.radians(yaw)), -math.cos(math.radians(yaw)))
    bx, bz = foot[0] + h0[0] * ball, foot[1] + h0[1] * ball
    return {"foot": [round(bx - h[0] * ball, 3), round(bz - h[1] * ball, 3)], "yaw": yaw, "toe": toe}


# ------------------------------------------------------------------ the five poses
def blow(kit, old, antic, hit, through, back=None, antic_at=.55, through_dt=.06, start=None, air=False):
    """rest (the guard) -> anticipation -> contact -> follow-through -> (back) -> guard.
    The anticipation eases IN (the limb accelerates into the contact), the contact eases OUT
    into the follow-through (it carries on, then settles). A foot that leaves the floor first
    lifts where it stands, and comes back down from above its spot (no sole dragged)."""
    g = GUARD[kit]
    m = old["markers"]
    c, r, L = m["contact"], m.get("recover", m["contact"] + .1), old["length"]
    base = merge(g, start or {})
    flag = {"air": True} if air else {}
    keys = [key(0, base, "in2", **flag)]
    ta = round(c * antic_at, 4)
    if c >= .07:
        keys.append(key(ta, g, "in", **merge(antic, flag)))
    keys.append(key(c, g, "out", **merge(hit, flag)))
    keys.append(key(round(min(r, c + through_dt), 4), g, "smooth", **merge(through, flag)))
    if back:
        keys.append(key(round(r + (L - r) * .45, 4), g, "smooth", **merge(back, flag)))
    keys.append(key(L, g, "smooth", **flag))
    if not air:
        for leg in ("RL", "LL"):
            gf = g[leg]
            first_free = next((k for k in keys[1:] if len(k.get(leg, {}).get("foot", [])) != 2), None)
            if first_free is not None and keys.index(first_free) >= 1:
                i = keys.index(first_free)
                t = round(keys[i - 1]["t"] + (keys[i]["t"] - keys[i - 1]["t"]) * .3, 4)
                prev = keys[i - 1]
                lifted = dict(prev.get(leg, gf))
                if len(lifted.get("foot", [])) == 2:
                    lifted["lift"] = lifted.get("lift", 0) + .16
                    keys.insert(i, dict(merge(prev, {leg: lifted}), t=t, ease="smooth"))
            last_free = None
            for k in keys[:-1]:
                if len(k.get(leg, {}).get("foot", [])) != 2:
                    last_free = k
            if last_free is not None:
                i = keys.index(last_free)
                nxt = keys[i + 1]
                if len(nxt.get(leg, {}).get("foot", [])) == 2:
                    t = round(last_free["t"] + (nxt["t"] - last_free["t"]) * .7, 4)
                    above = dict(nxt[leg]); above["lift"] = above.get("lift", 0) + .2
                    keys.insert(i + 1, dict(merge(nxt, {leg: above}), t=t, ease="smooth"))
    keys.sort(key=lambda k: k["t"])
    return {"keys": keys}


# ------------------------------------------------------------------ LEE (Leaf)
def leaf_light1(old):      # the open lead hand snaps out to the face and back: a jab, no wind-up
    return blow("Leaf", old,
                antic={"LA": {"hand": [-0.15, 1.0, -1.7], "hint": [70, 10, 20, 60]}},
                hit={"root": {"z": -0.18, "pitch": 6, "turn": -32}, "Waist": {"turn": 2, "pitch": 4},
                     "LA": {"hand": [-0.05, 1.75, -2.75], "hint": [95, 5, 10, 5], "wrist": {"swing": -20}}},
                through={"root": {"z": -0.24, "pitch": 7, "turn": -34}, "Waist": {"turn": 0, "pitch": 5},
                         "LA": {"hand": [-0.02, 1.8, -2.88], "hint": [95, 5, 10, 2]}})


def leaf_light2(old):      # the lead leg snaps a front kick into the body, hands stay in the Goken
    return blow("Leaf", old,
                antic={"root": {"z": 0.12, "pitch": -4}, "LL": {"swing": 75, "spread": 4, "bend": 105, "ankle": -10},
                       "LA": {"hand": [-0.3, 1.1, -1.7], "hint": [80, 10, 20, 40]}},
                hit={"root": {"z": 0.2, "pitch": -10, "turn": -30}, "Waist": {"pitch": 6},
                     "LL": {"foot": [-0.3, -0.1, -2.6], "hint": [85, 4, 0, 10, -20, 0]},
                     "LA": {"hand": [-0.35, 1.2, -1.75], "hint": [80, 10, 20, 40]}},
                through={"root": {"z": 0.22, "pitch": -11, "turn": -30}, "Waist": {"pitch": 6},
                         "LL": {"foot": [-0.3, -0.05, -2.75], "hint": [88, 4, 0, 5, -20, 0]},
                         "LA": {"hand": [-0.35, 1.2, -1.75], "hint": [80, 10, 20, 40]}},
                back={"LL": {"swing": 80, "spread": 4, "bend": 100, "ankle": -10}})


def leaf_light3(old, high=False):
    """The 3rd hit (the infused one): the rear leg comes round in a roundhouse while the lead
    foot turns on its ball; the body leans away from the kick. high=True: Konoha Senpu, the
    same turn sent to the head."""
    LL0, y0 = [-0.4, -1.1], 8
    lift = 0.95 if high else 0.0
    lean = 30 if high else 18
    return blow("Leaf", old,
                antic={"root": {"turn": -42, "z": 0.05}, "Waist": {"turn": -8},
                       "LL": pivot(LL0, y0, 40, -16),
                       "RL": {"swing": 45, "spread": 45, "twist": -25, "bend": 120, "ankle": -20},
                       "LA": {"chest": [-1.3, 0.45, -0.95], "hint": [70, 35, 10, 90]}},
                hit={"root": {"turn": 22, "lean": lean, "z": 0.12}, "Waist": {"turn": 12, "lean": 8},
                     "Neck": {"turn": -10, "lean": -10},
                     "LL": pivot(LL0, y0, 95, -22),
                     "RL": {"foot": [-0.1, 0.25 + lift, -1.85], "hint": [55, 80, -45, 5, -25, 0], "orient": False},
                     "LA": {"chest": [-1.45, 0.25, -0.7], "hint": [55, 45, 10, 95]}},
                through={"root": {"turn": 44, "lean": lean, "z": 0.12}, "Waist": {"turn": 16, "lean": 8},
                         "Neck": {"turn": -26, "lean": -10},
                         "LL": pivot(LL0, y0, 118, -22),
                         "RL": {"foot": [-0.95, 0.2 + lift, -1.45], "hint": [50, 85, -55, 10, -25, 0], "orient": False},
                         "LA": {"chest": [-1.5, 0.15, -0.5], "hint": [45, 50, 10, 95]}},
                back={"root": {"turn": -8}, "LL": pivot(LL0, y0, 50, -14),
                      "RL": {"foot": [0.75, 0.55], "yaw": -35, "lift": .35}},
                through_dt=.07)


def leaf_heavy(old):       # the hand behind his back comes out: the Goken's hard straight, full lunge
    return blow("Leaf", old,
                antic={"root": {"turn": -48, "z": 0.18, "sink": .6}, "Waist": {"turn": -10, "pitch": -2},
                       "RA": {"hand": [1.15, 0.2, 0.7], "hint": [-30, 35, 0, 110]},
                       "LA": {"hand": [-0.1, 1.25, -2.25], "hint": [95, 5, 30, 10], "wrist": {"swing": -60}}},
                hit={"root": {"turn": 12, "z": -0.42, "pitch": 12, "sink": .55}, "Waist": {"turn": 16, "pitch": 8},
                     "Neck": {"turn": -6, "pitch": 0},
                     "LL": {"foot": [-0.4, -1.25], "yaw": 5}, "RL": {"foot": [0.6, 0.95], "yaw": -20, "toe": -30},
                     "RA": {"hand": [0.12, 1.15, -2.9], "hint": [92, 4, 0, 4]},
                     "LA": {"hand": [-1.35, 0.35, -0.2], "hint": [10, 45, 0, 110]}},
                through={"root": {"turn": 18, "z": -0.5, "pitch": 14, "sink": .55}, "Waist": {"turn": 20, "pitch": 9},
                         "Neck": {"turn": -8, "pitch": 0},
                         "LL": {"foot": [-0.4, -1.25], "yaw": 5}, "RL": {"foot": [0.6, 0.95], "yaw": -15, "toe": -34},
                         "RA": {"hand": [0.1, 1.1, -3.05], "hint": [92, 4, 0, 2]},
                         "LA": {"hand": [-1.4, 0.3, -0.1], "hint": [5, 45, 0, 110]}},
                back={"root": {"turn": -10, "z": -0.2}, "RA": {"hand": [1.0, 0.5, -0.9], "hint": [40, 30, 0, 90]}},
                antic_at=.5, through_dt=.08)


def leaf_whirlwind(old):   # Konoha Senpu: the spinning roundhouse sent to the head
    return leaf_light3(old, high=True)


def leaf_hurricane(old):   # Konoha Reppu: dropped low on the lead leg, the rear leg sweeps the ankles
    LL0, y0 = [-0.4, -1.1], 8
    return blow("Leaf", old,
                antic={"root": {"turn": -46, "pitch": 16, "sink": .75}, "Waist": {"pitch": 10},
                       "LL": pivot(LL0, y0, 30, -10),
                       "RL": {"foot": [1.05, 0.85], "yaw": -55},
                       "LA": {"hand": [-1.0, -1.5, -1.3], "hint": [45, 30, 0, 30]}},
                hit={"root": {"turn": 30, "pitch": 18, "lean": 6, "sink": .3}, "Waist": {"pitch": 10, "turn": 10},
                     "LL": pivot(LL0, y0, 95, -22),
                     "RL": {"foot": [0.2, -2.3, -2.1], "hint": [60, 82, -60, 5, -10, 0], "orient": False},
                     "LA": {"hand": [-1.35, -2.3, -0.4], "hint": [25, 45, 0, 20]}},
                through={"root": {"turn": 58, "pitch": 18, "lean": 6, "sink": .3}, "Waist": {"pitch": 10, "turn": 14},
                         "LL": pivot(LL0, y0, 120, -22),
                         "RL": {"foot": [-1.1, -2.3, -1.6], "hint": [55, 88, -70, 5, -10, 0], "orient": False},
                         "LA": {"hand": [-1.4, -2.3, 0.1], "hint": [15, 45, 0, 20]}},
                back={"root": {"turn": 0, "sink": .6}, "LL": pivot(LL0, y0, 50, -12),
                      "RL": {"foot": [0.95, 0.45], "yaw": -40}},
                antic_at=.5, through_dt=.07)


def leaf_rising(old):      # Konoha Shofu: from the crouch, the rear leg rises straight up under the chin
    return blow("Leaf", old,
                antic={"root": {"sink": .9, "pitch": 12, "z": 0.05}, "Waist": {"pitch": 8},
                       "RL": {"foot": [0.55, 1.15], "yaw": -35, "toe": -20, "lift": .22},
                       "LA": {"hand": [-0.75, -0.6, -1.4], "hint": [40, 25, 0, 40]}},
                hit={"root": {"sink": .1, "pitch": -16, "z": 0.2, "turn": -10}, "Waist": {"pitch": -8},
                     "Neck": {"pitch": 14},
                     "RL": {"foot": [0.25, 2.2, -1.7], "hint": [150, 5, 0, 5, -30, 0], "orient": False},
                     "LL": {"foot": [-0.4, -1.1], "yaw": 8, "toe": -18},
                     "LA": {"hand": [-1.35, 0.4, 0.2], "hint": [-15, 60, 0, 40]}},
                through={"root": {"sink": .05, "pitch": -20, "z": 0.22, "turn": -10}, "Waist": {"pitch": -9},
                         "Neck": {"pitch": 16},
                         "RL": {"foot": [0.25, 2.55, -1.25], "hint": [160, 5, 0, 5, -30, 0], "orient": False},
                         "LL": {"foot": [-0.4, -1.1], "yaw": 8, "toe": -22},
                         "LA": {"hand": [-1.4, 0.3, 0.45], "hint": [-25, 60, 0, 40]}},
                back={"root": {"sink": .3}, "RL": {"swing": 40, "spread": 8, "bend": 110, "ankle": -15}},
                antic_at=.5, through_dt=.06)


def leaf_heel(old):        # the heel drop: the lead leg goes up past the head, then axes down
    return blow("Leaf", old,
                antic={"root": {"pitch": -14, "z": 0.25, "sink": .25}, "Waist": {"pitch": -6},
                       "LL": {"foot": [-0.35, 1.9, -1.4], "hint": [160, 5, 0, 5, -20, 0], "orient": False},
                       "RL": {"foot": [0.6, 0.9], "yaw": -30, "toe": -20},
                       "LA": {"hand": [-1.4, 0.7, 0.1], "hint": [-10, 60, 0, 50]}},
                hit={"root": {"pitch": 16, "z": -0.15, "sink": .4}, "Waist": {"pitch": 12},
                     "LL": {"foot": [-0.35, 0.3, -2.4], "hint": [95, 5, 0, 3, 10, 0], "orient": False},
                     "LA": {"hand": [-1.35, 0.5, -0.5], "hint": [30, 50, 0, 80]}},
                through={"root": {"pitch": 20, "z": -0.2, "sink": .5}, "Waist": {"pitch": 14},
                         "LL": {"foot": [-0.35, -0.9, -2.2], "hint": [65, 5, 0, 15, 10, 0], "orient": False},
                         "LA": {"hand": [-1.35, 0.4, -0.5], "hint": [30, 50, 0, 80]}},
                antic_at=.6, through_dt=.08)


def leaf_airflip(old, kit="Leaf"):     # in the air: a front flip that ends in an axe kick
    m = old["markers"]
    c, L = m["contact"], old["length"]
    tuck = {"LL": {"swing": 110, "spread": 6, "bend": 130}, "RL": {"swing": 100, "spread": 6, "bend": 130},
            "LA": {"swing": 40, "spread": 30, "bend": 100}, "RA": {"swing": 40, "spread": 30, "bend": 100}}
    g = key(0, GUARD[kit], **tuck)
    del g["t"], g["ease"]
    keys = [key(0, GUARD[kit], "in2", air=True, **tuck),
            key(c * .5, g, "in", air=True, root={"pitch": 100}, Waist={"pitch": 20}),
            key(c, g, "out", air=True, root={"pitch": 185, "turn": 0}, Waist={"pitch": 10},
                LL={"swing": 160, "spread": 4, "bend": 5, "ankle": 20}, RL={"swing": 20, "spread": 4, "bend": 60}),
            key(c + .06, g, "smooth", air=True, root={"pitch": 270, "turn": 0}, Waist={"pitch": 6},
                LL={"swing": 100, "spread": 4, "bend": 10, "ankle": 20}, RL={"swing": 10, "spread": 4, "bend": 50}),
            key(L * .85, g, "smooth", air=True, root={"pitch": 350, "turn": -20},
                LL={"swing": 40, "spread": 6, "bend": 40}, RL={"swing": -10, "spread": 6, "bend": 50},
                LA={"swing": 70, "spread": 20, "bend": 60}, RA={"swing": -20, "spread": 15, "bend": 80}),
            key(L, GUARD[kit], "smooth", air=True, root={"pitch": 360, "turn": -24},
                LL={"swing": 30, "spread": 6, "bend": 40}, RL={"swing": -15, "spread": 6, "bend": 50},
                LA={"swing": 80, "spread": 10, "bend": 30}, RA={"swing": -40, "spread": 10, "bend": 70})]
    return {"keys": keys}


# ------------------------------------------------------------------ SASUKE (Lion)
def lion_light1(old):      # a held beat, then the lead hand snaps straight out: precise, no waste
    return blow("Lion", old,
                antic={"root": {"turn": -46, "z": 0.05}, "LA": {"chest": [-1.3, -0.2, -1.0], "hint": [50, 20, 20, 60]}},
                hit={"root": {"turn": -64, "z": -0.22, "pitch": 4}, "Waist": {"turn": -4},
                     "Neck": {"turn": 52},
                     "LA": {"hand": [-0.12, 1.75, -2.7], "hint": [95, 5, 15, 5], "wrist": {"swing": 0}}},
                through={"root": {"turn": -66, "z": -0.27, "pitch": 5}, "Waist": {"turn": -5}, "Neck": {"turn": 54},
                         "LA": {"hand": [-0.1, 1.77, -2.82], "hint": [95, 5, 15, 2]}},
                antic_at=.7, through_dt=.05)


def lion_light2(old):      # the rear hand leaves the chin: a straight cross, the back foot turns on its ball
    RL0, y0 = [0.45, 0.55], -60
    return blow("Lion", old,
                antic={"root": {"turn": -60, "z": 0.08}, "Waist": {"turn": -6},
                       "RA": {"chest": [-0.35, 0.45, -0.9], "hint": [65, 25, -20, 120]}},
                hit={"root": {"turn": -5, "z": -0.32, "pitch": 7}, "Waist": {"turn": 12, "pitch": 4}, "Neck": {"turn": 4},
                     "RL": pivot(RL0, y0, -15, -24),
                     "RA": {"hand": [0.08, 1.8, -2.75], "hint": [92, 4, 0, 4]},
                     "LA": {"chest": [-1.0, 0.45, -0.95], "hint": [60, 25, 10, 100]}},
                through={"root": {"turn": 2, "z": -0.38, "pitch": 8}, "Waist": {"turn": 14, "pitch": 5}, "Neck": {"turn": 0},
                         "RL": pivot(RL0, y0, -8, -26),
                         "RA": {"hand": [0.05, 1.78, -2.9], "hint": [92, 4, 0, 2]},
                         "LA": {"chest": [-1.0, 0.45, -0.95], "hint": [60, 25, 10, 100]}},
                back={"root": {"turn": -40}, "RL": pivot(RL0, y0, -45, -10)},
                antic_at=.65, through_dt=.06)


def lion_light3(old):      # the 3rd hit (infused): the rear leg snaps up into the chin while he leans back
    return blow("Lion", old,
                antic={"root": {"turn": -40, "pitch": -4, "z": 0.08}, "Waist": {"pitch": -2},
                       "RL": {"swing": 95, "spread": 8, "twist": 10, "bend": 125, "ankle": -15},
                       "LA": {"chest": [-1.3, 0.2, -0.8], "hint": [50, 30, 10, 80]}},
                hit={"root": {"turn": -20, "pitch": -18, "z": 0.22}, "Waist": {"pitch": -6}, "Neck": {"pitch": 12, "turn": 20},
                     "LL": {"foot": [-0.25, -0.7], "yaw": 30, "toe": -10},
                     "RL": {"foot": [0.15, 1.45, -1.75], "hint": [140, 5, 0, 5, -30, 0], "orient": False},
                     "LA": {"chest": [-1.45, 0.0, -0.5], "hint": [30, 45, 10, 70]},
                     "RA": {"chest": [1.35, 0.1, -0.3], "hint": [20, 45, -10, 70]}},
                through={"root": {"turn": -20, "pitch": -22, "z": 0.25}, "Waist": {"pitch": -7}, "Neck": {"pitch": 14, "turn": 20},
                         "LL": {"foot": [-0.25, -0.7], "yaw": 30, "toe": -14},
                         "RL": {"foot": [0.15, 1.8, -1.35], "hint": [155, 5, 0, 5, -30, 0], "orient": False},
                         "LA": {"chest": [-1.5, -0.1, -0.4], "hint": [25, 45, 10, 70]},
                         "RA": {"chest": [1.4, 0.0, -0.2], "hint": [15, 45, -10, 70]}},
                back={"root": {"pitch": -4}, "RL": {"foot": [0.45, 0.4], "yaw": -55, "lift": .4}},
                antic_at=.6, through_dt=.06)


def lion_lionkick(old):    # the launcher of the Lion Combo: the lead leg rises under the chin
    return blow("Lion", old,
                antic={"root": {"turn": -50, "sink": .5, "pitch": 10}, "Waist": {"pitch": 6},
                       "LA": {"chest": [-1.3, -0.4, -0.8], "hint": [40, 30, 10, 60]}},
                hit={"root": {"turn": -45, "sink": .05, "pitch": -20, "z": 0.2}, "Waist": {"pitch": -8}, "Neck": {"pitch": 14},
                     "RL": {"foot": [0.45, 0.55], "yaw": -60, "toe": -20},
                     "LL": {"foot": [-0.25, 1.6, -1.6], "hint": [145, 5, 0, 5, -30, 0], "orient": False},
                     "LA": {"chest": [-1.4, -0.2, 0.3], "hint": [-10, 50, 0, 50]}},
                through={"root": {"turn": -45, "sink": 0.0, "pitch": -24, "z": 0.22}, "Waist": {"pitch": -9}, "Neck": {"pitch": 16},
                         "RL": {"foot": [0.45, 0.55], "yaw": -60, "toe": -26},
                         "LL": {"foot": [-0.25, 2.0, -1.15], "hint": [160, 5, 0, 5, -30, 0], "orient": False},
                         "LA": {"chest": [-1.45, -0.3, 0.45], "hint": [-20, 50, 0, 50]}},
                back={"root": {"pitch": -2}, "LL": {"foot": [-0.25, -0.7], "yaw": 35, "lift": .45}},
                antic_at=.55, through_dt=.06)


def lion_sweep(old):       # down on the back leg, one hand on the floor, the lead leg cuts the ankles
    LL0, y0 = [-0.25, -0.7], 35
    RL0, r0 = [0.45, 0.55], -60
    return blow("Lion", old,
                antic={"root": {"turn": -70, "pitch": 14, "sink": .55}, "Waist": {"pitch": 8},
                       "RL": pivot(RL0, r0, -40, -12),
                       "RA": {"hand": [0.9, -2.3, -0.3], "hint": [30, 35, 0, 20]}},
                hit={"root": {"turn": -10, "pitch": 18, "lean": -6, "sink": .45}, "Waist": {"pitch": 10, "turn": -8},
                     "RL": pivot(RL0, r0, 10, -22),
                     "LL": {"foot": [-0.4, -2.3, -2.1], "hint": [60, 80, 60, 5, -10, 0], "orient": False},
                     "RA": {"hand": [1.2, -2.35, -0.2], "hint": [25, 45, 0, 20]},
                     "LA": {"chest": [-1.2, 0.2, -0.9], "hint": [60, 30, 10, 90]}},
                through={"root": {"turn": 20, "pitch": 18, "lean": -6, "sink": .45}, "Waist": {"pitch": 10, "turn": -10},
                         "RL": pivot(RL0, r0, 35, -22),
                         "LL": {"foot": [1.0, -2.3, -1.7], "hint": [55, 85, 70, 5, -10, 0], "orient": False},
                         "RA": {"hand": [1.25, -2.35, 0.1], "hint": [20, 45, 0, 20]},
                         "LA": {"chest": [-1.2, 0.2, -0.9], "hint": [60, 30, 10, 90]}},
                back={"root": {"turn": -40, "sink": .35}, "RL": pivot(RL0, r0, -20, -10),
                      "LL": {"foot": [-0.45, -0.55], "yaw": 30, "lift": .3}},
                antic_at=.5, through_dt=.07)


def lion_vaultkick(old):   # a short hop and a crescent kick from the lead leg that cuts across the head
    m = old["markers"]
    c, r, L = m["contact"], m["recover"], old["length"]
    g = GUARD["Lion"]
    air = {"air": True}
    tuck_r = {"swing": 70, "spread": 10, "bend": 120, "ankle": -10}
    keys = [key(0, g, "in2"),
            key(c * .45, g, "in", root={"turn": -65, "sink": .4, "pitch": 6}),
            key(c, g, "out", root={"turn": -15, "lean": -16, "pitch": -6, "y": 0.25}, Waist={"turn": -10}, Neck={"turn": 20},
                RL=tuck_r, LL={"foot": [0.2, 1.6, -1.55], "hint": [120, 40, 40, 5, -20, 0], "orient": False},
                LA={"chest": [-1.45, 0.4, 0.2], "hint": [20, 60, 0, 40]}, RA={"chest": [1.4, 0.3, -0.4], "hint": [40, 50, 0, 60]}, **air),
            key(c + .06, g, "smooth", root={"turn": 10, "lean": -18, "pitch": -6, "y": 0.22}, Waist={"turn": -12}, Neck={"turn": 0},
                RL=tuck_r, LL={"foot": [1.1, 1.2, -1.2], "hint": [110, 60, 50, 5, -20, 0], "orient": False},
                LA={"chest": [-1.45, 0.3, 0.35], "hint": [15, 60, 0, 40]}, RA={"chest": [1.4, 0.2, -0.3], "hint": [35, 50, 0, 60]}, **air),
            key(r + .03, g, "out", root={"turn": -30, "sink": .35}, LL={"foot": [-0.25, -0.75], "yaw": 25}),
            key(L, g, "smooth")]
    return {"keys": keys}


def lion_airflip(old):     # in the air: a backflip whose kick rises in front (the flash kick)
    m = old["markers"]
    c, L = m["contact"], old["length"]
    g = GUARD["Lion"]
    a = {"air": True}
    arms = {"LA": {"swing": 20, "spread": 45, "bend": 40}, "RA": {"swing": 20, "spread": 45, "bend": 40}}
    keys = [key(0, g, "in2", **a, LL={"swing": 60, "spread": 6, "bend": 100}, RL={"swing": 40, "spread": 6, "bend": 110}),
            key(c * .5, g, "in", **a, root={"pitch": -40}, LL={"swing": 70, "spread": 6, "bend": 120}, RL={"swing": 30, "spread": 6, "bend": 100}, **arms),
            key(c, g, "out", **a, root={"pitch": -110}, Neck={"pitch": 20},
                RL={"swing": 150, "spread": 4, "bend": 3, "ankle": -20}, LL={"swing": 40, "spread": 6, "bend": 110}, **arms),
            key(c + .07, g, "smooth", **a, root={"pitch": -200}, Neck={"pitch": 20},
                RL={"swing": 120, "spread": 4, "bend": 20}, LL={"swing": 80, "spread": 6, "bend": 120}, **arms),
            key(L * .82, g, "smooth", **a, root={"pitch": -300},
                RL={"swing": 70, "spread": 6, "bend": 90}, LL={"swing": 75, "spread": 6, "bend": 100}, **arms),
            key(L, g, "smooth", **a, root={"pitch": -360, "turn": -50},
                RL={"swing": 30, "spread": 6, "bend": 60}, LL={"swing": 45, "spread": 6, "bend": 70},
                LA={"swing": 50, "spread": 30, "bend": 40}, RA={"swing": 30, "spread": 30, "bend": 60})]
    return {"keys": keys}


# ------------------------------------------------------------------ NARUTO (Legion)
def legion_light1(old):    # a wild lead hook: the elbow flies out, it goes a bit too far
    return blow("Legion", old,
                antic={"root": {"turn": -34, "z": 0.05}, "LA": {"chest": [-1.45, 0.1, -0.7], "hint": [50, 55, -20, 95]}},
                hit={"root": {"turn": 4, "z": -0.28, "pitch": 8}, "Waist": {"turn": 10, "pitch": 6}, "Neck": {"pitch": -12},
                     "LA": {"hand": [-0.15, 1.05, -2.5], "hint": [80, 40, -30, 75]},
                     "RA": {"chest": [0.9, -0.3, -1.0], "hint": [40, 30, 0, 100]}},
                through={"root": {"turn": 14, "z": -0.32, "pitch": 9}, "Waist": {"turn": 16, "pitch": 6}, "Neck": {"pitch": -12},
                         "LA": {"hand": [0.3, 1.0, -2.35], "hint": [78, 35, -40, 80]},
                         "RA": {"chest": [0.95, -0.35, -0.9], "hint": [35, 30, 0, 100]}},
                through_dt=.07)


def legion_light3(old):    # the 3rd hit (infused): a big front kick that overshoots, arms flailing for balance
    return blow("Legion", old,
                antic={"root": {"turn": -10, "pitch": -6, "z": 0.12}, "Waist": {"pitch": 2},
                       "RL": {"swing": 90, "spread": 10, "bend": 120, "ankle": -10},
                       "LA": {"chest": [-1.55, 0.2, -0.5], "hint": [40, 60, 0, 80]}, "RA": {"chest": [1.5, 0.2, 0.2], "hint": [10, 60, 0, 80]}},
                hit={"root": {"turn": 0, "pitch": -16, "z": 0.2}, "Waist": {"pitch": -4}, "Neck": {"pitch": 6, "turn": 0},
                     "LL": {"foot": [-0.8, -0.6], "yaw": 5, "toe": -16},
                     "RL": {"foot": [0.35, 0.1, -2.05], "hint": [100, 8, 0, 5, -40, 0], "orient": False},
                     "LA": {"chest": [-1.6, 0.3, -0.1], "hint": [10, 75, 0, 40]}, "RA": {"chest": [1.6, 0.25, 0.25], "hint": [0, 75, 0, 40]}},
                through={"root": {"turn": 6, "pitch": -24, "z": 0.25, "lean": 6}, "Waist": {"pitch": -6, "lean": 4}, "Neck": {"pitch": 10},
                         "LL": {"foot": [-0.8, -0.6], "yaw": 5, "toe": -20},
                         "RL": {"foot": [0.3, 0.7, -2.0], "hint": [115, 8, 0, 5, -40, 0], "orient": False},
                         "LA": {"chest": [-1.65, 0.5, 0.15], "hint": [-10, 90, 0, 30]}, "RA": {"chest": [1.65, 0.4, 0.45], "hint": [-20, 80, 0, 30]}},
                back={"root": {"pitch": 4, "z": -0.05}, "RL": {"foot": [0.75, -0.1], "yaw": -20, "lift": .3}},
                antic_at=.55, through_dt=.07)


def legion_heavy(old):     # the haymaker: the arm cocked far back, the whole body thrown in, it goes past
    return blow("Legion", old,
                antic={"root": {"turn": -62, "z": 0.25, "pitch": -2}, "Waist": {"turn": -18, "pitch": 0}, "Neck": {"turn": 40},
                       "RA": {"hand": [1.45, 1.3, 1.0], "hint": [-40, 60, 0, 100]},
                       "LA": {"hand": [-0.6, 1.3, -1.9], "hint": [80, 20, 10, 40]}},
                hit={"root": {"turn": 18, "z": -0.45, "pitch": 16}, "Waist": {"turn": 18, "pitch": 12}, "Neck": {"turn": -10},
                     "RL": {"foot": [0.85, 0.55], "yaw": -10, "toe": -30},
                     "RA": {"hand": [0.0, 1.55, -2.85], "hint": [85, 15, 0, 10]},
                     "LA": {"chest": [-1.4, 0.1, -0.2], "hint": [10, 50, 0, 100]}},
                through={"root": {"turn": 40, "z": -0.5, "pitch": 20}, "Waist": {"turn": 22, "pitch": 14}, "Neck": {"turn": -20},
                         "RL": {"foot": [0.85, 0.55], "yaw": 10, "toe": -34},
                         "RA": {"hand": [-0.9, 1.2, -2.45], "hint": [70, 10, -30, 20]},
                         "LA": {"chest": [-1.45, 0.0, 0.2], "hint": [-10, 55, 0, 90]}},
                back={"root": {"turn": 20, "z": -0.3, "pitch": 12}, "RL": {"foot": [0.6, -0.05], "yaw": -10},
                      "RA": {"chest": [0.2, 0.0, -1.2], "hint": [50, 20, 0, 90]}},
                antic_at=.5, through_dt=.09)


def legion_airflip(old):   # Naruto's version of the flip kick: the same turn, arms everywhere
    s = leaf_airflip(old, "Legion")
    for k in s["keys"][1:-1]:
        k["LA"] = {"swing": 100, "spread": 70, "bend": 30}
        k["RA"] = {"swing": -30, "spread": 80, "bend": 30}
    return s


# ------------------------------------------------------------------ the three transformations
# (DEC-045: the node at the top of each tree changes a technique on sight.) New clips, so
# their length and markers are proposals the DEV can time-warp (AuthoredMotion markers).
TRANSFORM_TIMING = {
    "Legion.RasenganThrow": {"length": .55, "markers": {"contact": .22, "recover": .36}},
    "Lion.WallChidori.Channel": {"length": .3, "markers": {}},
    "Leaf.LotusEntry": {"length": .7, "markers": {"contact": .48, "recover": .6}},
}


def legion_rasengan_throw(old):
    """Naruto's top node: the Rasengan thrown (by a clone, or by him): the sphere held up
    by the shoulder, the whole body behind an overhand throw, then he overshoots."""
    old = old or TRANSFORM_TIMING["Legion.RasenganThrow"]
    return blow("Legion", old,
                antic={"root": {"turn": -60, "z": 0.3, "pitch": -8}, "Waist": {"turn": -20, "pitch": -6}, "Neck": {"turn": 45, "pitch": -6},
                       "RA": {"hand": [1.1, 2.2, 0.9], "hint": [-20, 70, 20, 100]},
                       "LA": {"hand": [-0.5, 1.4, -1.9], "hint": [85, 20, 10, 30]}},
                hit={"root": {"turn": 20, "z": -0.45, "pitch": 18}, "Waist": {"turn": 18, "pitch": 14}, "Neck": {"turn": -12},
                     "RL": {"foot": [0.85, 0.55], "yaw": -5, "toe": -32},
                     "RA": {"hand": [0.2, 1.6, -2.7], "hint": [100, 10, 0, 10]},
                     "LA": {"chest": [-1.45, 0.0, 0.2], "hint": [0, 55, 0, 90]}},
                through={"root": {"turn": 34, "z": -0.55, "pitch": 24}, "Waist": {"turn": 20, "pitch": 16}, "Neck": {"turn": -18},
                         "RL": {"foot": [0.85, 0.55], "yaw": 10, "toe": -36},
                         "RA": {"hand": [-0.4, 0.4, -2.4], "hint": [70, 10, -20, 15]},
                         "LA": {"chest": [-1.5, -0.1, 0.4], "hint": [-10, 60, 0, 90]}},
                back={"root": {"turn": 10, "z": -0.3, "pitch": 12}, "RL": {"foot": [0.6, -0.1], "yaw": -10}},
                antic_at=.45, through_dt=.08)


def lion_wall_chidori(old):
    """Sasuke's top node: on the wall, crouched against it, the Chidori dragged low and back
    in the right hand while the left hand keeps him on the wall; 0.3 s, then the dive."""
    L = (old or TRANSFORM_TIMING["Lion.WallChidori.Channel"])["length"]
    g = GUARD["Lion"]
    a = {"air": True}
    crouch = {"root": {"pitch": 26, "turn": -20}, "Waist": {"pitch": 10, "turn": -10}, "Neck": {"pitch": -24, "turn": 20},
              "LL": {"swing": 95, "spread": 20, "bend": 130, "ankle": 10}, "RL": {"swing": 60, "spread": 25, "bend": 135, "ankle": 10},
              "LA": {"swing": 40, "spread": 70, "twist": 0, "bend": 30},
              "RA": {"swing": -55, "spread": 25, "twist": 30, "bend": 25, "wrist": {"swing": 30}}}
    k0 = key(0, g, "out", **a, **crouch)
    k1 = key(L * .5, g, "smooth", **a, **merge(crouch, {"RA": {"swing": -65, "spread": 30, "twist": 30, "bend": 20},
                                                      "root": {"pitch": 30, "turn": -24}}))
    k2 = key(L, g, "in", **a, **merge(crouch, {"RA": {"swing": -70, "spread": 30, "twist": 35, "bend": 15},
                                                "root": {"pitch": 34, "turn": -26}, "LL": {"swing": 85, "spread": 20, "bend": 115, "ankle": 10}}))
    return {"keys": [k0, k1, k2], "loop": False}


def leaf_lotus_entry(old):
    """Lee's top node: the Lotus lands, and instead of standing up he springs off the crater
    and comes back in feet first - the Dynamic Entry. From the landing crouch, a back spring
    (tucked), then the flying side kick, then down into his guard."""
    old = old or TRANSFORM_TIMING["Leaf.LotusEntry"]
    m, L = old["markers"], old["length"]
    c = m["contact"]
    g = GUARD["Leaf"]
    a = {"air": True}
    land = {"root": {"sink": 1.0, "pitch": 24}, "Waist": {"pitch": 14},
            "LL": {"foot": [-0.6, -0.7], "yaw": 10}, "RL": {"foot": [0.7, 0.5], "yaw": -20, "toe": -20},
            "LA": {"hand": [-1.1, -2.35, -1.0], "hint": [40, 35, 0, 20]}, "RA": {"chest": [0.3, -0.75, 0.98], "hint": [-45, 10, 0, 75]}}
    tuck = {"root": {"pitch": -40}, "LL": {"swing": 110, "spread": 8, "bend": 135}, "RL": {"swing": 100, "spread": 8, "bend": 135},
            "LA": {"swing": 30, "spread": 40, "bend": 90}, "RA": {"chest": [0.3, -0.75, 0.98], "hint": [-45, 10, 0, 75]}}
    kick = {"root": {"pitch": -10, "turn": -70, "lean": -35}, "Waist": {"lean": -10, "turn": -10}, "Neck": {"turn": 70, "lean": 20},
            "LL": {"swing": 15, "spread": 80, "twist": 0, "bend": 3, "ankle": 10}, "RL": {"swing": 30, "spread": 10, "bend": 120},
            "LA": {"swing": 60, "spread": 30, "bend": 20}, "RA": {"chest": [0.3, -0.75, 0.98], "hint": [-45, 10, 0, 75]}}
    keys = [key(0, g, "out", **land),
            key(c * .35, g, "in2", **merge(land, {"root": {"sink": 1.25, "pitch": 30}})),
            key(c * .65, g, "out", **a, **tuck),
            key(c, g, "out", **a, **kick),
            key(c + .07, g, "smooth", **a, **merge(kick, {"LL": {"swing": 18, "spread": 86, "bend": 0, "ankle": 10}})),
            key(m["recover"] + .04, g, "out", root={"sink": .7, "pitch": 10}),
            key(L, g, "smooth")]
    return {"keys": keys}
