"""Passe commune 2 (26/11), ANIMATEUR: every blow of the 8 kits in the new method, the ones the
étapes 2 and 4 left behind (François, 26/11: « retravaille les animations de combat, kit,
déplacement avec la nouvelle méthode ... pas qu'une partie », « les différences de kit ne se
voient pas assez bien dans leurs attaques »).

Measured before (tools/blender/kit_distinct.py on the game's clips): Kakashi, Itachi and Naruto
were each other's nearest kit on most blows; Air1, Air2, Launcher, DashAttack and Grab were the
same gesture in 5 to 8 kits (3 to 9 degrees apart), the idles too. So every slot still "old" is
authored here, each with the kit's own way of hitting (FICHES_MOUVEMENT.md):

  NARUTO  wild: cocked far back, thrown with the whole body, overshoots, the free arm flails
  SASUKE  side-on, still then dry; kicks that rise; the rear hand never leaves the chin
  LEE     kicks first, the hand behind his back; the Dynamic Entry; bouncing on his toes
  NEJI    open palms and two fingers from the hips; the feet hardly move; no fists, no kicks
  GAARA   he does not move: the hand points, sweeps, closes; the sand hits
  KAKASHI hunched and economical: the reversed kunai, low kicks, the left hand out; the book
  ITACHI  upright, one hand in the robe: one hand or one kick, a clean stop, nothing more
  MINATO  low and forward, the reversed three-pronged kunai: cuts, knees, a palm that marks

The DEV's timing is kept (each clip keeps the length and markers of the one it replaces).
Space as in e2_strikes: root space, x right, y up, -z forward; the floor at -3.01, the hip at
0, the head at +2.6; the target's chest about 2.7 studs ahead of the hand's shoulder.
"""
import copy

import e2_strikes as E
import e4_strikes as E4  # noqa: F401  (merges the five other guards into E.GUARD)
from e2_strikes import merge, key, pivot

G = E.GUARD


def blow2(kit, old, antic, hit, through, back=None, antic_at=.55, through_dt=.06, rest=None, end=None, air=False):
    """e2_strikes.blow with a rest pose of its own (an air blow starts and ends tucked, not in
    the standing guard) and an end pose (a slam ends crouched over the body)."""
    g = merge(G[kit], rest or {})
    for limb, v in (rest or {}).items():     # a limb the rest pose gives is replaced whole (a tucked
        if limb in ("RA", "LA", "RL", "LL"):  # leg must not keep the guard's planted foot)
            g[limb] = copy.deepcopy(v)
    m = old["markers"]
    c, r, L = m["contact"], m.get("recover", m["contact"] + .1), old["length"]
    flag = {"air": True} if air else {}
    keys = [key(0, g, "in2", **flag)]
    if c >= .07:
        keys.append(key(round(c * antic_at, 4), g, "in", **merge(antic, flag)))
    keys.append(key(c, g, "out", **merge(hit, flag)))
    keys.append(key(round(min(r, c + through_dt), 4), g, "smooth", **merge(through, flag)))
    if back:
        keys.append(key(round(r + (L - r) * .45, 4), g, "smooth", **merge(back, flag)))
    keys.append(key(L, merge(g, end or {}), "smooth", **flag))
    if not air:
        _lift_feet(keys, g)
    keys.sort(key=lambda k: k["t"])
    return {"keys": keys}


def _lift_feet(keys, g):
    """A foot that leaves the floor lifts where it stands first, and comes down from above its
    spot (no sole dragged) - e2_strikes.blow's rule."""
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


# the body in the air between blows: knees up, the kit's arms
TUCK = {"LL": {"swing": 70, "spread": 8, "bend": 95}, "RL": {"swing": 40, "spread": 8, "bend": 110}}


def air(kit, old, antic, hit, through, arms=None, **kw):
    rest = merge(TUCK, arms or {}, {"root": {"sink": 0, "pitch": 4}})
    return blow2(kit, old, antic, hit, through, rest=rest, air=True, **kw)


def loop(kit, old, poses, base):
    """An idle: the poses spread over the clip's length, closed on the first."""
    L = old["length"]
    n = len(poses)
    keys = [key(round(L * i / n, 4), base, "smooth", **p) for i, p in enumerate(poses)]
    keys.append(key(L, base, "smooth", **poses[0]))
    return {"keys": keys, "loop": True}


STRAIGHT = [92, 4, 0, 4]
STRAIGHT2 = [92, 4, 0, 2]


# ================================================================== NARUTO (Legion)
def legion_light2(old):     # the rear straight thrown from too far back: it lands, he keeps going
    RL0, y0 = [0.85, 0.55], -28
    return blow2("Legion", old,
                 antic={"root": {"turn": -40, "z": 0.15}, "Waist": {"turn": -10},
                        "RA": {"chest": [1.15, 0.55, 0.45], "hint": [10, 60, -10, 120]}},
                 hit={"root": {"turn": 12, "z": -0.42, "pitch": 14}, "Waist": {"turn": 14, "pitch": 6}, "Neck": {"turn": -6},
                      "RL": pivot(RL0, y0, 10, -26),
                      "RA": {"hand": [0.1, 1.55, -2.85], "hint": STRAIGHT},
                      "LA": {"chest": [-1.65, -0.1, 0.2], "hint": [0, 75, 0, 60]}},
                 through={"root": {"turn": 22, "z": -0.52, "pitch": 19}, "Waist": {"turn": 18, "pitch": 9}, "Neck": {"turn": -10},
                          "RL": pivot(RL0, y0, 22, -30),
                          "RA": {"hand": [-0.15, 1.4, -3.1], "hint": [90, 8, 0, 2]},
                          "LA": {"chest": [-1.7, 0.05, 0.35], "hint": [-15, 85, 0, 50]}},
                 back={"root": {"turn": -10, "z": -0.25, "pitch": 10}, "RL": pivot(RL0, y0, -10, -12)},
                 antic_at=.5, through_dt=.07)


def legion_light4(old):     # a shove-kick off the rear leg, arms thrown back for balance
    return blow2("Legion", old,
                 antic={"root": {"z": 0.1, "pitch": -6}, "RL": {"swing": 80, "spread": 10, "bend": 110, "ankle": -15},
                        "LA": {"chest": [-1.3, -0.1, 0.1], "hint": [10, 60, 0, 70]}},
                 hit={"root": {"z": 0.25, "pitch": -16, "turn": -5}, "Waist": {"pitch": -6},
                      "RL": {"foot": [0.25, 0.1, -2.6], "hint": [88, 6, 0, 8, -10, 0], "orient": False},
                      "LA": {"chest": [-1.6, -0.2, 0.45], "hint": [-20, 80, 0, 40]},
                      "RA": {"chest": [1.6, -0.15, 0.4], "hint": [-20, 80, 0, 40]}},
                 through={"root": {"z": 0.28, "pitch": -19, "turn": -3}, "Waist": {"pitch": -7},
                          "RL": {"foot": [0.25, 0.15, -2.8], "hint": [90, 6, 0, 4, -10, 0], "orient": False},
                          "LA": {"chest": [-1.65, -0.1, 0.55], "hint": [-30, 85, 0, 30]},
                          "RA": {"chest": [1.65, -0.05, 0.5], "hint": [-30, 85, 0, 30]}},
                 back={"RL": {"foot": [0.85, 0.2], "yaw": -20, "lift": .3}}, through_dt=.08)


def legion_dash(old):       # the flying shoulder-first punch: the whole body thrown, the legs trailing
    return blow2("Legion", old,
                 antic={},
                 hit={"root": {"pitch": 38, "turn": -8, "sink": .2, "z": -0.4}, "Waist": {"pitch": 10}, "Neck": {"pitch": -24},
                      "RA": {"hand": [0.25, 1.1, -3.0], "hint": STRAIGHT},
                      "LA": {"chest": [-1.4, 0.3, 0.9], "hint": [-50, 50, 0, 40]},
                      "RL": {"foot": [0.6, 0.4, 2.0], "hint": [-60, 10, 0, 50, 0, 0], "orient": False},
                      "LL": {"foot": [-0.6, -1.0], "yaw": 5, "toe": -30}},
                 through={"root": {"pitch": 42, "turn": -4, "sink": .25, "z": -0.55}, "Waist": {"pitch": 12}, "Neck": {"pitch": -26},
                          "RA": {"hand": [0.15, 1.0, -3.2], "hint": STRAIGHT2},
                          "LA": {"chest": [-1.5, 0.5, 1.0], "hint": [-60, 55, 0, 30]},
                          "RL": {"foot": [0.6, 0.6, 2.1], "hint": [-65, 10, 0, 45, 0, 0], "orient": False},
                          "LL": {"foot": [-0.6, -1.0], "yaw": 5, "toe": -34}},
                 back={"root": {"pitch": 18, "z": -0.3}, "RL": {"foot": [0.85, 0.55], "yaw": -28, "lift": .3}},
                 through_dt=.07)


NARUTO_AIR = {"LA": {"chest": [-1.2, 0.6, -0.6], "hint": [40, 55, 0, 80]}, "RA": {"chest": [1.2, 0.5, -0.5], "hint": [40, 55, 0, 80]}}


def legion_air1(old):       # in the air: a big overhand hammer of the right fist, legs kicking under him
    return air("Legion", old,
               antic={"RA": {"hand": [0.9, 2.6, 0.4], "hint": [170, 30, 0, 80]}, "root": {"pitch": -12}},
               hit={"RA": {"hand": [0.15, 0.7, -2.6], "hint": [60, 5, 0, 10]}, "root": {"pitch": 22}, "Waist": {"pitch": 10},
                    "LA": {"chest": [-1.6, 0.0, 0.4], "hint": [-20, 85, 0, 40]},
                    "RL": {"swing": -20, "spread": 15, "bend": 60}, "LL": {"swing": 90, "spread": 10, "bend": 80}},
               through={"RA": {"hand": [0.1, 0.2, -2.4], "hint": [45, 5, 0, 12]}, "root": {"pitch": 28}, "Waist": {"pitch": 12},
                        "LA": {"chest": [-1.65, 0.1, 0.5], "hint": [-30, 90, 0, 30]},
                        "RL": {"swing": -30, "spread": 15, "bend": 55}, "LL": {"swing": 95, "spread": 10, "bend": 70}},
               arms=NARUTO_AIR, through_dt=.07)


def legion_air2(old):       # a wild scissor kick: both legs fly out one after the other, the arms everywhere
    return air("Legion", old,
               antic={"root": {"pitch": -10, "turn": -20}, "RL": {"swing": 100, "spread": 10, "bend": 120}},
               hit={"root": {"pitch": -24, "turn": 10, "lean": -12}, "Waist": {"pitch": -6},
                    "RL": {"swing": 95, "spread": 12, "bend": 5, "ankle": 10}, "LL": {"swing": -25, "spread": 10, "bend": 70},
                    "LA": {"chest": [-1.6, 1.0, 0.4], "hint": [-30, 90, 0, 30]}, "RA": {"chest": [1.55, 0.2, 0.6], "hint": [-40, 70, 0, 50]}},
               through={"root": {"pitch": -28, "turn": 24, "lean": -14}, "Waist": {"pitch": -7},
                        "RL": {"swing": 105, "spread": 12, "bend": 5, "ankle": 15}, "LL": {"swing": -35, "spread": 10, "bend": 60},
                        "LA": {"chest": [-1.6, 1.2, 0.5], "hint": [-40, 95, 0, 20]}, "RA": {"chest": [1.6, 0.0, 0.7], "hint": [-50, 70, 0, 40]}},
               arms=NARUTO_AIR, through_dt=.08)


def legion_slam(old):       # both fists locked over his head, brought down with everything
    both_up = {"LA": {"hand": [-0.15, 3.1, 0.2], "hint": [175, 10, 0, 40]}, "RA": {"hand": [0.15, 3.1, 0.2], "hint": [175, 10, 0, 40]}}
    return blow2("Legion", old,
                 antic=merge(both_up, {"root": {"pitch": -14, "sink": .1}, "Waist": {"pitch": -10}, "Neck": {"pitch": -12}}),
                 hit={"root": {"pitch": 30, "sink": .7, "z": -0.3}, "Waist": {"pitch": 18}, "Neck": {"pitch": 6},
                      "LA": {"hand": [-0.12, -0.4, -2.4], "hint": [40, 8, 0, 8]}, "RA": {"hand": [0.12, -0.4, -2.4], "hint": [40, 8, 0, 8]}},
                 through={"root": {"pitch": 36, "sink": .85, "z": -0.35}, "Waist": {"pitch": 20}, "Neck": {"pitch": 8},
                          "LA": {"hand": [-0.12, -0.9, -2.3], "hint": [30, 8, 0, 8]}, "RA": {"hand": [0.12, -0.9, -2.3], "hint": [30, 8, 0, 8]}},
                 back={"root": {"pitch": 18, "sink": .5}, "Waist": {"pitch": 8}}, antic_at=.55, through_dt=.09)


def legion_launcher(old):   # the uppercut from a crouch: he jumps into it, feet leave the floor
    return blow2("Legion", old,
                 antic={"root": {"sink": 1.0, "pitch": 18, "turn": -30}, "Waist": {"pitch": 10},
                        "RA": {"hand": [0.85, -0.7, -0.6], "hint": [20, 35, 0, 100]}},
                 hit={"root": {"sink": -.35, "pitch": -12, "turn": 8, "z": -0.3}, "Waist": {"pitch": -8, "turn": 10}, "Neck": {"pitch": 18},
                      "RA": {"hand": [0.1, 2.7, -1.75], "hint": [150, 15, 0, 40]},
                      "LA": {"chest": [-1.5, -0.3, 0.4], "hint": [-20, 60, 0, 70]},
                      "LL": {"foot": [-0.8, -0.6], "yaw": 12, "toe": -40}, "RL": {"foot": [0.85, 0.55], "yaw": -28, "toe": -40}},
                 through={"root": {"sink": -.45, "pitch": -16, "turn": 14, "z": -0.35}, "Waist": {"pitch": -10, "turn": 12}, "Neck": {"pitch": 22},
                          "RA": {"hand": [0.0, 3.1, -1.3], "hint": [165, 15, 0, 30]},
                          "LA": {"chest": [-1.55, -0.4, 0.6], "hint": [-30, 60, 0, 60]},
                          "LL": {"foot": [-0.8, -0.6], "yaw": 12, "toe": -40}, "RL": {"foot": [0.85, 0.55], "yaw": -28, "toe": -40}},
                 antic_at=.5, through_dt=.07)


def legion_grab(old):       # arms wide, a bear hug, and he heaves him over his hip
    wide = {"LA": {"chest": [-1.9, 0.5, -1.0], "hint": [70, 85, 0, 30]}, "RA": {"chest": [1.9, 0.5, -1.0], "hint": [70, 85, 0, 30]}}
    return blow2("Legion", old,
                 antic=merge(wide, {"root": {"z": 0.1, "pitch": 4}}),
                 hit={"root": {"z": -0.45, "pitch": 16}, "Waist": {"pitch": 6},
                      "LA": {"hand": [-0.45, 1.0, -2.45], "hint": [80, 40, 0, 80]}, "RA": {"hand": [0.45, 1.0, -2.45], "hint": [80, 40, 0, 80]}},
                 through={"root": {"z": -0.5, "pitch": 18}, "Waist": {"pitch": 8},
                          "LA": {"hand": [-0.3, 1.0, -2.3], "hint": [80, 40, 0, 95]}, "RA": {"hand": [0.3, 1.0, -2.3], "hint": [80, 40, 0, 95]}},
                 back={"root": {"turn": 50, "pitch": 14, "sink": .55}, "Waist": {"turn": 18, "pitch": 8},
                       "LA": {"hand": [0.4, 1.0, -2.0], "hint": [80, 30, 20, 70]}, "RA": {"hand": [1.6, 0.7, -0.9], "hint": [40, 60, 0, 60]}},
                 antic_at=.5, through_dt=.1)


def legion_idle(old):       # can't stand still: rocking heel to toe, a hand rubbing the back of his neck, looking about
    base = {"root": {"sink": .05}, "LL": {"foot": [-0.6, 0.05], "yaw": 14}, "RL": {"foot": [0.62, -0.05], "yaw": -16},
            "LA": {"swing": 6, "spread": 14, "bend": 25}, "RA": {"swing": 6, "spread": 14, "bend": 25}, "Neck": {"pitch": -2}}
    neck = {"RA": {"hand": [0.3, 2.0, 0.75], "hint": [140, 80, 0, 140]}}
    return loop("Legion", old, [
        {"Neck": {"turn": -22, "pitch": -4}, "root": {"pitch": -3, "lean": 3}},
        {"Neck": {"turn": 0, "pitch": -8}, "root": {"pitch": 3, "sink": .1, "lean": -3}, "LL": {"toe": -14}, "RL": {"toe": -14}},
        merge(neck, {"Neck": {"turn": 18, "pitch": 6, "lean": -6}, "root": {"pitch": -1, "lean": 2}}),
        merge(neck, {"Neck": {"turn": 10, "pitch": 10, "lean": -8}, "root": {"pitch": 1, "lean": 2}}),
        {"Neck": {"turn": 26, "pitch": -2}, "root": {"pitch": -2, "turn": 6, "lean": -2}}], base)


def lion_light4(old):       # a side kick off the lead leg, already side-on: it rises to the head, the body tips away
    return blow2("Lion", old,
                 antic={"root": {"turn": -70, "z": 0.05}, "LL": {"swing": 90, "spread": 25, "twist": 60, "bend": 125, "ankle": -10}},
                 hit={"root": {"turn": -82, "pitch": -8, "lean": -22, "z": 0.12}, "Waist": {"lean": -8}, "Neck": {"turn": 70, "lean": 14},
                      "LL": {"foot": [-0.2, 1.35, -2.4], "hint": [110, 30, 70, 4, -10, 0], "orient": False},
                      "LA": {"chest": [-1.2, -0.35, -0.5], "hint": [20, 40, 10, 80]}},
                 through={"root": {"turn": -84, "pitch": -9, "lean": -24, "z": 0.12}, "Waist": {"lean": -9}, "Neck": {"turn": 72, "lean": 14},
                          "LL": {"foot": [-0.2, 1.4, -2.55], "hint": [112, 30, 72, 2, -10, 0], "orient": False},
                          "LA": {"chest": [-1.22, -0.4, -0.45], "hint": [20, 40, 10, 80]}},
                 back={"LL": {"swing": 80, "spread": 20, "twist": 50, "bend": 120}}, through_dt=.07)


def lion_heavy(old):        # the hook kick: the lead leg chambers, rises past the head and whips back across
    LL0, y0 = [-0.25, -0.7], 35
    RL0 = [0.45, 0.55]
    return blow2("Lion", old,
                 antic={"root": {"turn": -70, "sink": .3, "lean": -8}, "Neck": {"turn": 55},
                        "RL": pivot(RL0, -60, -80, -3),
                        "LL": {"swing": 100, "spread": 30, "twist": 20, "bend": 120, "ankle": -15}},
                 hit={"root": {"turn": -78, "lean": -26, "z": 0.12}, "Waist": {"lean": -8}, "Neck": {"turn": 62, "lean": 10},
                      "RL": pivot(RL0, -60, -84, -4),
                      "LL": {"foot": [0.4, 1.7, -1.9], "hint": [120, 40, 30, 10, -20, 0], "orient": False},
                      "LA": {"chest": [-1.4, -0.3, -0.5], "hint": [20, 45, 10, 70]}},
                 through={"root": {"turn": -84, "lean": -28, "z": 0.12}, "Waist": {"lean": -9}, "Neck": {"turn": 66, "lean": 10},
                          "RL": pivot(RL0, -60, -86, -4),
                          "LL": {"foot": [1.25, 1.5, -1.35], "hint": [110, 55, 40, 20, -20, 0], "orient": False},
                          "LA": {"chest": [-1.45, -0.35, -0.45], "hint": [15, 45, 10, 70]}},
                 back={"root": {"turn": -55, "lean": -6}, "LL": {"foot": LL0, "yaw": y0, "lift": .35}, "RL": pivot(RL0, -60, -68, -2)},
                 antic_at=.55, through_dt=.08)


def lion_dash(old):         # the dash ends in a flying knee, the rear hand still at the chin
    return blow2("Lion", old,
                 antic={},
                 hit={"root": {"turn": -20, "pitch": -6, "sink": -.25, "z": -0.3}, "Waist": {"pitch": -4}, "Neck": {"turn": 18, "pitch": 6},
                      "RL": {"foot": [0.25, -0.15, -1.6], "hint": [110, 5, 0, 5, -40, 0], "orient": False},
                      "LL": {"foot": [-0.25, -0.7], "yaw": 35, "toe": -40},
                      "LA": {"hand": [-0.2, 1.7, -2.0], "hint": [80, 20, 10, 60]}},
                 through={"root": {"turn": -18, "pitch": -8, "sink": -.3, "z": -0.38}, "Waist": {"pitch": -5}, "Neck": {"turn": 16, "pitch": 7},
                          "RL": {"foot": [0.25, 0.05, -1.65], "hint": [115, 5, 0, 5, -40, 0], "orient": False},
                          "LL": {"foot": [-0.25, -0.7], "yaw": 35, "toe": -44},
                          "LA": {"hand": [-0.2, 1.75, -2.05], "hint": [80, 20, 10, 60]}},
                 back={"RL": {"foot": [0.45, 0.55], "yaw": -60, "lift": .3}}, through_dt=.08)


SASUKE_AIR = {"LA": {"chest": [-1.2, -0.2, -0.7], "hint": [30, 40, 10, 80]}, "RA": {"chest": [-0.5, 0.5, -1.0], "hint": [70, 30, -20, 120]}}


def lion_air1(old):         # a snap kick rising from the tuck: the toes to the chin, the body leans back
    return air("Lion", old,
               antic={"root": {"pitch": -6}, "LL": {"swing": 110, "spread": 6, "bend": 130}},
               hit={"root": {"pitch": -22}, "Waist": {"pitch": -6}, "Neck": {"pitch": 12},
                    "LL": {"swing": 135, "spread": 6, "bend": 8, "ankle": 25}, "RL": {"swing": 10, "spread": 8, "bend": 80}},
               through={"root": {"pitch": -26}, "Waist": {"pitch": -7}, "Neck": {"pitch": 14},
                        "LL": {"swing": 145, "spread": 6, "bend": 5, "ankle": 25}, "RL": {"swing": 5, "spread": 8, "bend": 75}},
               arms=SASUKE_AIR, antic_at=.6, through_dt=.06)


def lion_air2(old):         # an aerial roundhouse: the hips turn over, the instep across the head
    return air("Lion", old,
               antic={"root": {"turn": -40}, "RL": {"swing": 60, "spread": 40, "twist": -20, "bend": 120}},
               hit={"root": {"turn": 30, "lean": 30, "pitch": -4}, "Waist": {"turn": 10, "lean": 8}, "Neck": {"turn": -20, "lean": -12},
                    "RL": {"swing": 80, "spread": 75, "twist": -40, "bend": 5, "ankle": 15}, "LL": {"swing": 20, "spread": 5, "bend": 90}},
               through={"root": {"turn": 55, "lean": 32, "pitch": -4}, "Waist": {"turn": 14, "lean": 9}, "Neck": {"turn": -34, "lean": -12},
                        "RL": {"swing": 70, "spread": 80, "twist": -50, "bend": 8, "ankle": 15}, "LL": {"swing": 15, "spread": 5, "bend": 90}},
               arms=SASUKE_AIR, antic_at=.55, through_dt=.07)


def lion_slam(old):         # from the air, the axe kick: the leg high over the head, the heel on the body
    return blow2("Lion", old,
                 antic={"root": {"pitch": -16, "sink": -.2, "turn": -30}, "Waist": {"pitch": -6},
                        "RL": {"foot": [0.3, 2.3, -1.2], "hint": [165, 5, 0, 5, -20, 0], "orient": False},
                        "LL": {"foot": [-0.25, -0.7], "yaw": 35, "toe": -30}},
                 hit={"root": {"pitch": 14, "sink": .35, "turn": -30, "z": -0.2}, "Waist": {"pitch": 10},
                      "RL": {"foot": [0.3, -0.2, -2.3], "hint": [85, 5, 0, 3, 15, 0], "orient": False},
                      "LA": {"chest": [-1.3, 0.3, -0.5], "hint": [30, 50, 10, 80]}},
                 through={"root": {"pitch": 20, "sink": .55, "turn": -30, "z": -0.25}, "Waist": {"pitch": 12},
                          "RL": {"foot": [0.3, -1.6, -2.0], "hint": [55, 5, 0, 20, 15, 0], "orient": False},
                          "LA": {"chest": [-1.3, 0.2, -0.5], "hint": [30, 50, 10, 80]}},
                 back={"root": {"pitch": 8, "sink": .4}, "RL": {"foot": [0.45, -0.2], "yaw": -50, "lift": .25}},
                 antic_at=.55, through_dt=.1)


def lion_grab(old):         # one hand on the collar, the other on the arm, a short turn of the hip
    return blow2("Lion", old,
                 antic={"LA": {"hand": [-0.5, 1.2, -1.9], "hint": [70, 25, 10, 60]}},
                 hit={"root": {"turn": -36, "z": -0.35, "pitch": 6}, "Waist": {"turn": 4},
                      "LA": {"hand": [-0.2, 1.6, -2.55], "hint": [85, 15, 10, 30]},
                      "RA": {"hand": [0.45, 1.0, -2.3], "hint": [70, 25, -10, 60]}},
                 through={"root": {"turn": -32, "z": -0.38, "pitch": 7}, "Waist": {"turn": 5},
                          "LA": {"hand": [-0.2, 1.55, -2.4], "hint": [85, 15, 10, 45]},
                          "RA": {"hand": [0.42, 0.95, -2.15], "hint": [70, 25, -10, 75]}},
                 back={"root": {"turn": -5, "sink": .35, "pitch": 10}, "Waist": {"turn": 12, "pitch": 6},
                       "LA": {"hand": [0.3, 1.3, -2.0], "hint": [80, 20, 30, 70]}, "RA": {"hand": [1.1, 0.7, -1.2], "hint": [50, 45, -10, 80]}},
                 antic_at=.6, through_dt=.1)


def lion_idle(old):         # aloof: weight on one leg, hands in his pockets, the chin up
    pockets = {"LA": {"hand": [-0.85, -0.15, 0.15], "hint": [-10, 20, 0, 40]}, "RA": {"hand": [0.85, -0.15, 0.15], "hint": [-10, 20, 0, 40]}}
    base = merge(pockets, {"root": {"sink": .05, "lean": 4, "turn": -10}, "Waist": {"lean": -3},
                           "LL": {"foot": [-0.5, 0.05], "yaw": 14}, "RL": {"foot": [0.62, -0.15], "yaw": -20, "toe": -6},
                           "Neck": {"pitch": 6, "turn": 12}})
    return loop("Lion", old, [
        {"Neck": {"pitch": 6, "turn": 12}},
        {"Neck": {"pitch": 3, "turn": 22}, "Waist": {"pitch": 1, "lean": -2}},
        {"Neck": {"pitch": 8, "turn": -6}, "root": {"lean": 3}}], base)


# ================================================================== LEE (Leaf)
LEE_AIR = {"LA": {"hand": [-0.2, 1.4, -1.6], "hint": [80, 10, 20, 40]}, "RA": {"hand": [0.6, 0.2, 0.8], "hint": [-40, 15, 0, 90]}}


def leaf_dash(old):         # the Dynamic Entry: flying in feet first, the lead leg locked out, the arms back
    return blow2("Leaf", old,
                 antic={},
                 hit={"root": {"pitch": -38, "turn": -55, "sink": -.5, "z": 0.2}, "Waist": {"pitch": -8}, "Neck": {"pitch": 22, "turn": 45},
                      "LL": {"foot": [-0.2, 0.9, -2.7], "hint": [95, 5, 0, 3, -10, 0], "orient": False},
                      "RL": {"foot": [0.45, -1.4, 0.3], "hint": [-20, 5, 0, 110, 0, 0], "orient": False},
                      "LA": {"chest": [-1.0, -0.45, 0.9], "hint": [-40, 40, 0, 40]}, "RA": {"chest": [1.0, -0.45, 0.9], "hint": [-40, 40, 0, 40]}},
                 through={"root": {"pitch": -40, "turn": -55, "sink": -.5, "z": 0.1}, "Waist": {"pitch": -9}, "Neck": {"pitch": 24, "turn": 45},
                          "LL": {"foot": [-0.2, 0.95, -2.85], "hint": [95, 5, 0, 2, -10, 0], "orient": False},
                          "RL": {"foot": [0.45, -1.4, 0.4], "hint": [-25, 5, 0, 105, 0, 0], "orient": False},
                          "LA": {"chest": [-1.05, -0.4, 1.0], "hint": [-45, 40, 0, 35]}, "RA": {"chest": [1.05, -0.4, 1.0], "hint": [-45, 40, 0, 35]}},
                 back={"root": {"pitch": -10, "sink": .3}, "LL": {"foot": [-0.4, -1.1], "yaw": 8, "lift": .4},
                       "RL": {"foot": [0.6, 0.9], "yaw": -35, "lift": .3}},
                 through_dt=.07)


def leaf_air1(old):         # a flying side kick from the tuck, the hand behind the back
    return air("Leaf", old,
               antic={"root": {"turn": -30}, "LL": {"swing": 100, "spread": 10, "bend": 135}},
               hit={"root": {"turn": -75, "lean": -30}, "Waist": {"lean": -8}, "Neck": {"turn": 70, "lean": 12},
                    "LL": {"swing": 90, "spread": 15, "twist": 70, "bend": 3, "ankle": -10}, "RL": {"swing": 60, "spread": 5, "bend": 120}},
               through={"root": {"turn": -80, "lean": -32}, "Waist": {"lean": -9}, "Neck": {"turn": 74, "lean": 12},
                        "LL": {"swing": 92, "spread": 18, "twist": 75, "bend": 2, "ankle": -10}, "RL": {"swing": 55, "spread": 5, "bend": 120}},
               arms=LEE_AIR, antic_at=.5, through_dt=.06)


def leaf_air2(old):         # two kicks in one jump: the left, then the right turning over it
    return air("Leaf", old,
               antic={"root": {"turn": -20}, "LL": {"swing": 120, "spread": 6, "bend": 10}},
               hit={"root": {"turn": 40, "lean": 26, "pitch": -6}, "Waist": {"turn": 14, "lean": 8}, "Neck": {"turn": -30},
                    "RL": {"swing": 85, "spread": 70, "twist": -40, "bend": 4, "ankle": 15}, "LL": {"swing": -10, "spread": 8, "bend": 60}},
               through={"root": {"turn": 70, "lean": 28, "pitch": -6}, "Waist": {"turn": 18, "lean": 9}, "Neck": {"turn": -46},
                        "RL": {"swing": 75, "spread": 80, "twist": -50, "bend": 6, "ankle": 15}, "LL": {"swing": -15, "spread": 8, "bend": 55}},
               arms=LEE_AIR, antic_at=.5, through_dt=.07)


def leaf_slam(old):         # the heel drop out of the air (his LeafHeel, sent down on the body)
    s = E.leaf_heel(old)
    return s


def leaf_grab(old):         # the open lead hand takes the collar and yanks him in, the hand behind the back stays
    return blow2("Leaf", old,
                 antic={"root": {"z": 0.08}, "LA": {"hand": [-0.3, 1.3, -2.0], "hint": [85, 10, 30, 40]}},
                 hit={"root": {"z": -0.4, "pitch": 8}, "LA": {"hand": [-0.1, 1.7, -2.6], "hint": [90, 8, 10, 20]}},
                 through={"root": {"z": -0.42, "pitch": 9}, "LA": {"hand": [-0.1, 1.65, -2.45], "hint": [90, 8, 10, 35]}},
                 back={"root": {"turn": 15, "sink": .55, "pitch": 12, "z": -0.2}, "Waist": {"turn": 10, "pitch": 6},
                       "LA": {"hand": [-0.9, 0.9, -1.2], "hint": [50, 45, 0, 70]}},
                 antic_at=.6, through_dt=.1)


def leaf_idle(old):         # bouncing on his toes, a shoulder roll, never still
    g = G["Leaf"]
    base = {"root": {"sink": .1}, "LL": {"foot": [-0.55, -0.1], "yaw": 8}, "RL": {"foot": [0.55, 0.1], "yaw": -10},
            "LA": {"chest": [-0.7, -0.4, -0.9], "hint": [30, 20, 10, 100]}, "RA": {"chest": [0.7, -0.4, -0.9], "hint": [30, 20, -10, 100]}}
    del g
    return loop("Leaf", old, [
        {"root": {"sink": .1}},
        {"root": {"sink": -.05}, "LL": {"toe": -25}, "RL": {"toe": -25}, "LA": {"chest": [-0.9, 0.6, -0.3], "hint": [60, 70, 0, 120]}},
        {"root": {"sink": .12}},
        {"root": {"sink": -.05}, "LL": {"toe": -25}, "RL": {"toe": -25}, "RA": {"chest": [0.9, 0.6, -0.3], "hint": [60, 70, 0, 120]}},
        {"root": {"sink": .1}, "Neck": {"pitch": -6}},
        {"root": {"sink": -.05}, "LL": {"toe": -25}, "RL": {"toe": -25}}], base)


# ================================================================== NEJI (GentleFist)
NEJI_AIR = {"LA": {"chest": [-0.75, 0.35, -1.7], "hint": [80, 15, 20, 30], "wrist": {"swing": -70}},
            "RA": {"chest": [0.8, -0.6, -1.0], "hint": [40, 25, -10, 60], "wrist": {"swing": -55}}}


def gentle_dash(old):       # the long gliding lunge, palm first, the rear palm low: the feet barely lift
    return blow2("GentleFist", old,
                 antic={},
                 hit={"root": {"turn": -20, "sink": .75, "pitch": 14, "z": -0.4}, "Waist": {"turn": 10, "pitch": 6},
                      "LL": {"foot": [-0.5, -1.55], "yaw": 20}, "RL": {"foot": [0.85, 1.15], "yaw": -60, "toe": -25},
                      "LA": {"hand": [-0.1, 1.1, -3.1], "hint": STRAIGHT, "wrist": {"swing": -85}},
                      "RA": {"chest": [0.95, -0.8, -0.4], "hint": [15, 30, 0, 60], "wrist": {"swing": -50}}},
                 through={"root": {"turn": -16, "sink": .78, "pitch": 15, "z": -0.46}, "Waist": {"turn": 12, "pitch": 7},
                          "LL": {"foot": [-0.5, -1.55], "yaw": 20}, "RL": {"foot": [0.85, 1.15], "yaw": -60, "toe": -28},
                          "LA": {"hand": [-0.1, 1.12, -3.22], "hint": STRAIGHT2, "wrist": {"swing": -85}},
                          "RA": {"chest": [0.95, -0.82, -0.35], "hint": [15, 30, 0, 60], "wrist": {"swing": -50}}},
                 through_dt=.08)


def gentle_air1(old):       # in the air, one palm struck straight down at the body below
    return air("GentleFist", old,
               antic={"LA": {"chest": [-0.6, 0.9, -0.6], "hint": [130, 20, 0, 90], "wrist": {"swing": -60}}},
               hit={"root": {"pitch": 26, "turn": -20}, "Waist": {"pitch": 8},
                    "LA": {"hand": [-0.1, 0.2, -2.5], "hint": [55, 6, 0, 6], "wrist": {"swing": -90}}},
               through={"root": {"pitch": 30, "turn": -18}, "Waist": {"pitch": 9},
                        "LA": {"hand": [-0.1, 0.0, -2.55], "hint": [50, 6, 0, 4], "wrist": {"swing": -90}}},
               arms=NEJI_AIR, through_dt=.07)


def gentle_air2(old):       # both palms pushed out together, the knees drawn up
    return air("GentleFist", old,
               antic={"LA": {"chest": [-0.5, 0.0, -0.8], "hint": [50, 20, 10, 100], "wrist": {"swing": -80}},
                      "RA": {"chest": [0.5, -0.1, -0.8], "hint": [50, 20, -10, 100], "wrist": {"swing": -80}}},
               hit={"root": {"pitch": 10}, "LA": {"hand": [-0.35, 1.2, -2.6], "hint": [90, 8, 0, 6], "wrist": {"swing": -85}},
                    "RA": {"hand": [0.35, 1.15, -2.6], "hint": [90, 8, 0, 6], "wrist": {"swing": -85}},
                    "LL": {"swing": 95, "spread": 10, "bend": 120}, "RL": {"swing": 90, "spread": 10, "bend": 120}},
               through={"root": {"pitch": 12}, "LA": {"hand": [-0.35, 1.22, -2.72], "hint": [90, 8, 0, 3], "wrist": {"swing": -85}},
                        "RA": {"hand": [0.35, 1.17, -2.72], "hint": [90, 8, 0, 3], "wrist": {"swing": -85}},
                        "LL": {"swing": 95, "spread": 10, "bend": 120}, "RL": {"swing": 90, "spread": 10, "bend": 120}},
               arms=NEJI_AIR, through_dt=.08)


def gentle_slam(old):       # down on one knee, the palm driven flat into the body on the ground
    return blow2("GentleFist", old,
                 antic={"root": {"sink": .5, "pitch": 6}, "RA": {"chest": [0.6, 0.9, -0.5], "hint": [130, 25, 0, 90], "wrist": {"swing": -60}}},
                 hit={"root": {"sink": 1.25, "pitch": 26, "z": -0.2}, "Waist": {"pitch": 14},
                      "LL": {"foot": [-0.5, -1.0], "yaw": 25}, "RL": {"foot": [0.85, 0.75], "yaw": -62, "toe": -40},
                      "RA": {"hand": [0.1, -2.1, -2.1], "hint": [30, 8, 0, 6], "wrist": {"swing": -90}},
                      "LA": {"chest": [-1.1, 0.3, -0.4], "hint": [20, 50, 0, 70], "wrist": {"swing": -60}}},
                 through={"root": {"sink": 1.3, "pitch": 28, "z": -0.22}, "Waist": {"pitch": 15},
                          "LL": {"foot": [-0.5, -1.0], "yaw": 25}, "RL": {"foot": [0.85, 0.75], "yaw": -62, "toe": -40},
                          "RA": {"hand": [0.1, -2.3, -2.1], "hint": [25, 8, 0, 4], "wrist": {"swing": -90}},
                          "LA": {"chest": [-1.12, 0.25, -0.35], "hint": [20, 50, 0, 70], "wrist": {"swing": -60}}},
                 back={"root": {"sink": .8, "pitch": 12}}, antic_at=.5, through_dt=.1)


def gentle_launcher(old):   # the rising palm: heel of the hand up under the chin, the hips lift it
    return blow2("GentleFist", old,
                 antic={"root": {"sink": .7, "turn": -55}, "RA": {"chest": [0.6, -1.0, -0.6], "hint": [20, 25, 0, 60], "wrist": {"swing": -80}}},
                 hit={"root": {"sink": .1, "turn": -10, "z": -0.3, "pitch": -4}, "Waist": {"turn": 12, "pitch": -4},
                      "RA": {"hand": [0.1, 2.3, -2.3], "hint": [135, 8, 0, 10], "wrist": {"swing": -95}}},
                 through={"root": {"sink": .05, "turn": -6, "z": -0.33, "pitch": -6}, "Waist": {"turn": 14, "pitch": -5},
                          "RA": {"hand": [0.1, 2.6, -2.15], "hint": [145, 8, 0, 6], "wrist": {"swing": -95}}},
                 antic_at=.5, through_dt=.07)


def gentle_grab(old):       # the lead hand takes the wrist, the rear palm into the heart
    return blow2("GentleFist", old,
                 antic={"root": {"turn": -50}, "RA": {"chest": [0.7, -0.4, -0.5], "hint": [25, 35, 0, 100], "wrist": {"swing": -70}}},
                 hit={"root": {"turn": -40, "z": -0.3}, "LA": {"hand": [-0.3, 0.9, -2.45], "hint": [80, 20, 10, 30], "wrist": {"swing": 10}}},
                 through={"root": {"turn": -20, "z": -0.35, "pitch": 6}, "Waist": {"turn": 10},
                          "LA": {"hand": [-0.55, 0.6, -1.9], "hint": [60, 30, 10, 60]},
                          "RA": {"hand": [0.1, 1.35, -2.55], "hint": STRAIGHT, "wrist": {"swing": -85}}},
                 back={"root": {"turn": 0, "z": -0.38, "pitch": 8}, "RA": {"hand": [0.1, 1.37, -2.75], "hint": STRAIGHT2, "wrist": {"swing": -85}}},
                 antic_at=.6, through_dt=.1)


def gentle_idle(old):       # upright and still, the hands loose at his sides; only the eyes go about
    base = {"root": {"sink": .03}, "LL": {"foot": [-0.5, 0.0], "yaw": 8}, "RL": {"foot": [0.5, 0.0], "yaw": -8},
            "LA": {"swing": 2, "spread": 6, "bend": 6}, "RA": {"swing": 2, "spread": 6, "bend": 6}, "Neck": {"pitch": 2}}
    return loop("GentleFist", old, [
        {"Neck": {"pitch": 2, "turn": 0}},
        {"Neck": {"pitch": 1, "turn": 14}, "Waist": {"pitch": 1}},
        {"Neck": {"pitch": 3, "turn": -12}}], base)


# ================================================================== GAARA (Sand)
GAARA_AIR = {"LA": {"chest": [0.45, -0.1, -1.1], "hint": [45, 10, 0, 115]}, "RA": {"chest": [-0.45, 0.05, -1.22], "hint": [45, 10, 0, 115]},
             "LL": {"swing": 20, "spread": 5, "bend": 30}, "RL": {"swing": 10, "spread": 5, "bend": 25}}


def sand_dash(old):         # he does not run at you: one arm flung out, the body leaning after it
    s = E4.sand_gesture(old, "R", (0.3, 1.3, -2.6), wrist={"swing": -40}, lean=14)
    return s


def sand_air1(old):         # in the air, the arms uncross: a hand flung down at the target
    return air("Sand", old,
               antic={"RA": {"chest": [0.7, 0.5, -0.3], "hint": [60, 40, 0, 110]}},
               hit={"RA": {"hand": [0.3, 0.6, -2.4], "hint": [60, 15, 0, 10], "wrist": {"swing": -60}}, "root": {"pitch": 10}},
               through={"RA": {"hand": [0.3, 0.45, -2.45], "hint": [55, 15, 0, 6], "wrist": {"swing": -60}}, "root": {"pitch": 11}},
               arms=GAARA_AIR, through_dt=.08)


def sand_air2(old):         # both arms thrown wide: the sand bursts from round him
    return air("Sand", old,
               antic={"LA": {"chest": [0.2, -0.3, -0.7], "hint": [40, 10, 0, 120]}, "RA": {"chest": [-0.2, -0.3, -0.7], "hint": [40, 10, 0, 120]}},
               hit={"LA": {"hand": [-1.9, 1.3, -1.0], "hint": [80, 80, 0, 10], "wrist": {"swing": -60}},
                    "RA": {"hand": [1.9, 1.3, -1.0], "hint": [80, 80, 0, 10], "wrist": {"swing": -60}}, "root": {"pitch": -4}},
               through={"LA": {"hand": [-2.0, 1.4, -0.8], "hint": [80, 85, 0, 6], "wrist": {"swing": -60}},
                        "RA": {"hand": [2.0, 1.4, -0.8], "hint": [80, 85, 0, 6], "wrist": {"swing": -60}}, "root": {"pitch": -5}},
               arms=GAARA_AIR, through_dt=.08)


def sand_grab(old):         # Sand Coffin: the hand reaches out open, then closes slowly into a fist
    return blow2("Sand", old,
                 antic={"RA": {"chest": [0.7, 0.4, -0.6], "hint": [40, 30, 0, 110], "wrist": {"swing": 10}}},
                 hit={"RA": {"hand": [0.3, 1.5, -2.45], "hint": [88, 12, 0, 8], "wrist": {"swing": -70}}, "Neck": {"pitch": 4}},
                 through={"RA": {"hand": [0.3, 1.55, -2.4], "hint": [88, 12, 0, 12], "wrist": {"swing": -40}}, "Neck": {"pitch": 6}},
                 back={"RA": {"hand": [0.3, 1.65, -2.3], "hint": [88, 12, 0, 20], "wrist": {"swing": 25}}, "Neck": {"pitch": 8}, "root": {"pitch": 2}},
                 antic_at=.5, through_dt=.12)


def sand_idle(old):         # the arms crossed, the gourd on his back; the head tilts a little, nothing else
    g = G["Sand"]
    return loop("Sand", old, [
        {"Neck": {"turn": 6, "pitch": 4}},
        {"Neck": {"turn": 2, "pitch": 8, "lean": 4}, "Waist": {"pitch": 1}},
        {"Neck": {"turn": 12, "pitch": 3}}], g)


# ================================================================== KAKASHI (Copycat)
KAKASHI_AIR = {"LA": {"chest": [-0.85, 0.15, -1.4], "hint": [70, 20, 10, 60]},
               "RA": {"chest": [0.5, -0.25, -1.15], "hint": [55, 25, -10, 100], "wrist": {"twist": 80}}}


def copy_light1(old):       # the left palm pushed into the face: short, the shoulders hunched, the kunai kept back
    return blow2("Copycat", old,
                 antic={"LA": {"chest": [-0.7, 0.1, -1.1], "hint": [70, 20, 10, 80]}},
                 hit={"root": {"turn": -36, "z": -0.15, "pitch": 10}, "Waist": {"pitch": 8},
                      "LA": {"hand": [-0.15, 1.8, -2.6], "hint": [92, 6, 10, 6], "wrist": {"swing": -75}}},
                 through={"root": {"turn": -37, "z": -0.18, "pitch": 11}, "Waist": {"pitch": 9},
                          "LA": {"hand": [-0.12, 1.82, -2.7], "hint": [92, 6, 10, 3], "wrist": {"swing": -75}}},
                 through_dt=.05)


def copy_light3(old):       # a low lead-leg kick to the knee, nothing above the waist moves much
    return blow2("Copycat", old,
                 antic={"root": {"z": 0.06}, "LL": {"swing": 45, "spread": 10, "bend": 80, "ankle": -10}},
                 hit={"root": {"z": 0.08, "lean": -8, "pitch": 4}, "Waist": {"lean": -4},
                      "LL": {"foot": [0.1, -1.95, -2.35], "hint": [55, 20, 30, 5, -10, 0], "orient": False}},
                 through={"root": {"z": 0.08, "lean": -9, "pitch": 4}, "Waist": {"lean": -4},
                          "LL": {"foot": [0.45, -2.05, -2.3], "hint": [55, 25, 35, 4, -10, 0], "orient": False}},
                 back={"LL": {"foot": [-0.5, -0.75], "yaw": 15, "lift": .25}}, through_dt=.07)


def copy_dash(old):         # ducking in low, the reversed kunai drawn across the belly as he passes
    return blow2("Copycat", old,
                 antic={},
                 hit={"root": {"turn": -40, "sink": .8, "pitch": 26, "z": -0.3}, "Waist": {"pitch": 10, "turn": -6},
                      "LL": {"foot": [-0.5, -1.2], "yaw": 15}, "RL": {"foot": [0.75, 1.1], "yaw": -40, "toe": -35},
                      "RA": {"hand": [0.6, 0.25, -2.6], "hint": [80, 35, -40, 20], "wrist": {"twist": 90}},
                      "LA": {"chest": [-1.2, -0.4, 0.2], "hint": [0, 40, 0, 70]}},
                 through={"root": {"turn": -10, "sink": .85, "pitch": 28, "z": -0.38}, "Waist": {"pitch": 11, "turn": 6},
                          "LL": {"foot": [-0.5, -1.2], "yaw": 15}, "RL": {"foot": [0.75, 1.1], "yaw": -40, "toe": -38},
                          "RA": {"hand": [-0.7, 0.2, -2.35], "hint": [70, 40, -60, 30], "wrist": {"twist": 90}},
                          "LA": {"chest": [-1.25, -0.45, 0.35], "hint": [-5, 40, 0, 70]}},
                 through_dt=.08)


def copy_air1(old):         # in the air, the reversed kunai brought down across, short
    return air("Copycat", old,
               antic={"RA": {"hand": [0.85, 1.4, -1.2], "hint": [80, 40, -20, 70], "wrist": {"twist": 80}}},
               hit={"root": {"pitch": 14}, "RA": {"hand": [0.2, 0.7, -2.45], "hint": [65, 25, -30, 20], "wrist": {"twist": 90}}},
               through={"root": {"pitch": 16}, "RA": {"hand": [-0.5, 0.35, -2.3], "hint": [55, 30, -40, 25], "wrist": {"twist": 90}}},
               arms=KAKASHI_AIR, through_dt=.07)


def copy_air2(old):         # a short low side-kick in the air, the left hand out, economical
    return air("Copycat", old,
               antic={"RL": {"swing": 90, "spread": 15, "bend": 125}},
               hit={"root": {"turn": 55, "lean": 18}, "Neck": {"turn": -45},
                    "RL": {"swing": 70, "spread": 25, "twist": -70, "bend": 4, "ankle": -10}},
               through={"root": {"turn": 58, "lean": 19}, "Neck": {"turn": -47},
                        "RL": {"swing": 72, "spread": 28, "twist": -72, "bend": 3, "ankle": -10}},
               arms=KAKASHI_AIR, through_dt=.06)


def copy_slam(old):         # he drops on one knee and plants the kunai in the body on the ground
    return blow2("Copycat", old,
                 antic={"root": {"sink": .4, "pitch": 4}, "RA": {"hand": [0.6, 2.2, -0.6], "hint": [150, 25, -10, 80], "wrist": {"twist": 90}}},
                 hit={"root": {"sink": 1.3, "pitch": 24, "z": -0.15}, "Waist": {"pitch": 12},
                      "LL": {"foot": [-0.5, -0.9], "yaw": 15}, "RL": {"foot": [0.75, 0.75], "yaw": -40, "toe": -45},
                      "RA": {"hand": [0.25, -1.9, -2.0], "hint": [30, 10, 0, 10], "wrist": {"twist": 90}},
                      "LA": {"hand": [-0.6, -2.0, -1.5], "hint": [40, 20, 0, 30]}},
                 through={"root": {"sink": 1.35, "pitch": 26, "z": -0.17}, "Waist": {"pitch": 13},
                          "LL": {"foot": [-0.5, -0.9], "yaw": 15}, "RL": {"foot": [0.75, 0.75], "yaw": -40, "toe": -45},
                          "RA": {"hand": [0.25, -2.25, -1.95], "hint": [25, 10, 0, 8], "wrist": {"twist": 90}},
                          "LA": {"hand": [-0.6, -2.05, -1.5], "hint": [40, 20, 0, 30]}},
                 back={"root": {"sink": .8, "pitch": 10}}, antic_at=.5, through_dt=.1)


def copy_launcher(old):     # the clinch: the left hand pulls the head down, the rear knee drives up
    return blow2("Copycat", old,
                 antic={"root": {"z": -0.1}, "LA": {"hand": [-0.1, 2.0, -2.3], "hint": [100, 15, 10, 30]}},
                 hit={"root": {"z": -0.3, "pitch": -6, "sink": -.1}, "Waist": {"pitch": -4},
                      "LA": {"hand": [-0.1, 1.2, -2.0], "hint": [70, 20, 10, 60]},
                      "RL": {"foot": [0.2, -0.2, -1.5], "hint": [115, 5, 0, 5, -40, 0], "orient": False},
                      "LL": {"foot": [-0.5, -0.75], "yaw": 15, "toe": -30}},
                 through={"root": {"z": -0.32, "pitch": -9, "sink": -.2}, "Waist": {"pitch": -5},
                          "LA": {"hand": [-0.1, 1.25, -1.9], "hint": [70, 20, 10, 70]},
                          "RL": {"foot": [0.2, 0.15, -1.55], "hint": [125, 5, 0, 5, -40, 0], "orient": False},
                          "LL": {"foot": [-0.5, -0.75], "yaw": 15, "toe": -36}},
                 back={"RL": {"foot": [0.75, 0.6], "yaw": -40, "lift": .3}}, antic_at=.5, through_dt=.07)


def copy_grab(old):         # the left hand on the collar, the reversed kunai laid against the throat
    return blow2("Copycat", old,
                 antic={"root": {"z": 0.05}, "LA": {"hand": [-0.45, 1.2, -1.9], "hint": [80, 20, 10, 50]}},
                 hit={"root": {"z": -0.35, "pitch": 8}, "LA": {"hand": [-0.15, 1.55, -2.55], "hint": [88, 12, 10, 30]}},
                 through={"root": {"z": -0.38, "pitch": 8}, "LA": {"hand": [-0.15, 1.5, -2.4], "hint": [88, 12, 10, 45]},
                          "RA": {"hand": [0.25, 1.75, -2.5], "hint": [85, 30, -40, 30], "wrist": {"twist": 90}}},
                 back={"root": {"z": -0.4, "pitch": 9, "sink": .2},
                       "LA": {"hand": [-0.15, 1.45, -2.35], "hint": [88, 12, 10, 50]},
                       "RA": {"hand": [0.15, 1.7, -2.45], "hint": [85, 30, -40, 35], "wrist": {"twist": 90}}},
                 antic_at=.6, through_dt=.1)


def copy_idle(old):         # slouched, the left hand in his pocket, the right holding his book up to read
    book = {"RA": {"hand": [0.1, 1.5, -1.5], "hint": [60, 25, -20, 110], "wrist": {"swing": -30}},
            "LA": {"hand": [-0.85, -0.15, 0.15], "hint": [-10, 20, 0, 40]}}
    base = merge(book, {"root": {"sink": .1, "pitch": 6, "lean": -3}, "Waist": {"pitch": 6},
                        "LL": {"foot": [-0.55, -0.05], "yaw": 12}, "RL": {"foot": [0.5, 0.1], "yaw": -14},
                        "Neck": {"pitch": 18}})
    return loop("Copycat", old, [
        {"Neck": {"pitch": 18, "turn": 0}},
        {"Neck": {"pitch": 20, "turn": 6}, "RA": {"hand": [0.14, 1.48, -1.5], "hint": [60, 25, -20, 110], "wrist": {"swing": -30}}},
        {"Neck": {"pitch": 17, "turn": -4}}], base)


# ================================================================== ITACHI (Mirage)
ITACHI_ROBE = {"LA": {"chest": [-0.2, 0.0, -0.9], "hint": [35, 15, 0, 120]}}
ITACHI_AIR = merge(ITACHI_ROBE, {"RA": {"chest": [0.95, -0.9, -0.5], "hint": [20, 15, 0, 25]}})


def mirage_light3(old):     # one low front snap-kick into the body, then set down where it was
    return blow2("Mirage", old,
                 antic={"RL": {"swing": 70, "spread": 6, "bend": 110, "ankle": -15}},
                 hit={"root": {"pitch": -6, "z": 0.08}, "RL": {"foot": [0.2, -0.6, -2.6], "hint": [80, 5, 0, 8, -15, 0], "orient": False}},
                 through={"root": {"pitch": -7, "z": 0.08}, "RL": {"foot": [0.2, -0.55, -2.72], "hint": [82, 5, 0, 4, -15, 0], "orient": False}},
                 back={"RL": {"swing": 65, "spread": 6, "bend": 110}}, through_dt=.06)


def mirage_light4(old):     # the knife-hand dropped on the collarbone; the robe hand stays in
    return blow2("Mirage", old,
                 antic={"RA": {"hand": [0.7, 2.6, -0.8], "hint": [150, 30, -10, 70], "wrist": {"twist": 80}}},
                 hit={"root": {"turn": -24, "z": -0.15, "pitch": 6}, "RA": {"hand": [0.2, 1.75, -2.5], "hint": [100, 10, 0, 12], "wrist": {"twist": 90}}},
                 through={"root": {"turn": -24, "z": -0.17, "pitch": 7}, "RA": {"hand": [0.2, 1.55, -2.45], "hint": [95, 10, 0, 10], "wrist": {"twist": 90}}},
                 through_dt=.05)


def mirage_dash(old):       # he is simply there: one step, upright, the back of the hand across the face
    return blow2("Mirage", old,
                 antic={"RA": {"hand": [0.2, 1.0, -1.7], "hint": [70, 20, 30, 60]}},
                 hit={"root": {"turn": -50, "z": -0.2}, "Waist": {"turn": -4},
                      "RA": {"hand": [-0.35, 1.9, -2.4], "hint": [90, 30, 40, 30], "wrist": {"swing": 20}}},
                 through={"root": {"turn": -40, "z": -0.22}, "Waist": {"turn": -2},
                          "RA": {"hand": [0.6, 1.85, -2.3], "hint": [85, 40, -20, 30], "wrist": {"swing": 10}}},
                 through_dt=.06)


def mirage_air1(old):       # in the air, one knee, the robe hand never leaves
    return air("Mirage", old,
               antic={"RL": {"swing": 60, "spread": 6, "bend": 120}},
               hit={"root": {"pitch": -4}, "RL": {"swing": 105, "spread": 6, "bend": 125}},
               through={"root": {"pitch": -6}, "RL": {"swing": 110, "spread": 6, "bend": 125}},
               arms=ITACHI_AIR, through_dt=.06)


def mirage_air2(old):       # one clean side-kick, the body flat behind it
    return air("Mirage", old,
               antic={"RL": {"swing": 85, "spread": 15, "bend": 130}},
               hit={"root": {"turn": 70, "lean": 35}, "Neck": {"turn": -60, "lean": -12},
                    "RL": {"swing": 85, "spread": 30, "twist": -70, "bend": 2, "ankle": -10}},
               through={"root": {"turn": 72, "lean": 36}, "Neck": {"turn": -62, "lean": -12},
                        "RL": {"swing": 86, "spread": 32, "twist": -72, "bend": 1, "ankle": -10}},
               arms=ITACHI_AIR, through_dt=.06)


def mirage_slam(old):       # one palm laid down flat on the fallen body, the robe hand in, he hardly bends
    return blow2("Mirage", old,
                 antic={"RA": {"chest": [0.8, 0.8, -0.6], "hint": [120, 25, 0, 90], "wrist": {"swing": -60}}},
                 hit={"root": {"sink": .9, "pitch": 20}, "Waist": {"pitch": 10},
                      "LL": {"foot": [-0.45, -0.75], "yaw": 18}, "RL": {"foot": [0.6, 0.55], "yaw": -40, "toe": -20},
                      "RA": {"hand": [0.2, -1.8, -2.2], "hint": [30, 8, 0, 6], "wrist": {"swing": -90}}},
                 through={"root": {"sink": .95, "pitch": 21}, "Waist": {"pitch": 11},
                          "LL": {"foot": [-0.45, -0.75], "yaw": 18}, "RL": {"foot": [0.6, 0.55], "yaw": -40, "toe": -20},
                          "RA": {"hand": [0.2, -2.0, -2.2], "hint": [25, 8, 0, 4], "wrist": {"swing": -90}}},
                 back={"root": {"sink": .4, "pitch": 6}}, antic_at=.5, through_dt=.1)


def mirage_launcher(old):   # a single straight front kick rising under the chin, the body upright
    return blow2("Mirage", old,
                 antic={"RL": {"swing": 80, "spread": 6, "bend": 120, "ankle": -10}},
                 hit={"root": {"pitch": -12, "z": 0.1}, "Neck": {"pitch": 8},
                      "RL": {"foot": [0.2, 2.0, -1.9], "hint": [145, 5, 0, 5, -25, 0], "orient": False}},
                 through={"root": {"pitch": -15, "z": 0.12}, "Neck": {"pitch": 10},
                          "RL": {"foot": [0.2, 2.35, -1.6], "hint": [155, 5, 0, 4, -25, 0], "orient": False}},
                 back={"RL": {"swing": 70, "spread": 6, "bend": 110}}, antic_at=.55, through_dt=.07)


def mirage_grab(old):       # one hand round the throat, lifted; the other stays in the robe
    return blow2("Mirage", old,
                 antic={"RA": {"hand": [0.55, 1.0, -1.7], "hint": [70, 30, -10, 60]}},
                 hit={"root": {"z": -0.3, "turn": -26}, "RA": {"hand": [0.1, 1.95, -2.55], "hint": [95, 10, 0, 15], "wrist": {"swing": -30}}},
                 through={"root": {"z": -0.32, "turn": -26}, "RA": {"hand": [0.1, 2.05, -2.5], "hint": [100, 10, 0, 18], "wrist": {"swing": -30}}},
                 back={"root": {"z": -0.3, "turn": -26, "pitch": -4}, "RA": {"hand": [0.1, 2.2, -2.45], "hint": [110, 10, 0, 20], "wrist": {"swing": -30}}},
                 antic_at=.6, through_dt=.1)


def mirage_idle(old):       # completely still, the hand in the robe; a slow breath, the eyes half closed
    base = merge(ITACHI_ROBE, {"root": {"sink": .03}, "LL": {"foot": [-0.48, -0.05], "yaw": 8}, "RL": {"foot": [0.5, 0.05], "yaw": -8},
                               "RA": {"swing": 3, "spread": 5, "bend": 8}, "Neck": {"pitch": 8}})
    return loop("Mirage", old, [
        {"Neck": {"pitch": 8}},
        {"Neck": {"pitch": 10, "turn": 3}, "Waist": {"pitch": 1.5}}], base)


# ================================================================== MINATO (Flashstep)
MINATO_AIR = {"LA": {"chest": [-1.05, -0.55, -0.55], "hint": [30, 35, 0, 70]},
              "RA": {"chest": [0.3, 0.05, -1.6], "hint": [70, 25, -10, 70], "wrist": {"twist": 90}}}


def flash_light2(old):      # the rising cut, low to high, the reversed kunai's edge first
    return blow2("Flashstep", old,
                 antic={"root": {"sink": .6, "turn": -40}, "RA": {"hand": [0.9, -0.6, -1.0], "hint": [30, 40, -20, 60], "wrist": {"twist": 90}}},
                 hit={"root": {"sink": .4, "turn": -10, "z": -0.3, "pitch": 6}, "Waist": {"turn": 10},
                      "RA": {"hand": [0.25, 1.4, -2.55], "hint": [90, 25, -30, 15], "wrist": {"twist": 90}}},
                 through={"root": {"sink": .35, "turn": -2, "z": -0.33, "pitch": 4}, "Waist": {"turn": 12},
                          "RA": {"hand": [0.1, 2.3, -2.1], "hint": [130, 25, -30, 15], "wrist": {"twist": 90}}},
                 through_dt=.07)


def flash_dash(old):        # the yellow flash: almost flat over a long low stride, the cut drawn past
    return blow2("Flashstep", old,
                 antic={},
                 hit={"root": {"pitch": 40, "turn": -15, "sink": .9, "z": -0.5}, "Waist": {"pitch": 14, "turn": 8}, "Neck": {"pitch": -28},
                      "LL": {"foot": [-0.6, -1.7], "yaw": 14}, "RL": {"foot": [0.8, 1.6], "yaw": -36, "toe": -40},
                      "RA": {"hand": [0.5, 0.05, -2.95], "hint": [80, 30, -40, 15], "wrist": {"twist": 90}},
                      "LA": {"chest": [-1.2, -0.5, 0.8], "hint": [-40, 35, 0, 40]}},
                 through={"root": {"pitch": 42, "turn": 0, "sink": .92, "z": -0.6}, "Waist": {"pitch": 15, "turn": 12}, "Neck": {"pitch": -30},
                          "LL": {"foot": [-0.6, -1.7], "yaw": 14}, "RL": {"foot": [0.8, 1.6], "yaw": -36, "toe": -44},
                          "RA": {"hand": [-0.8, -0.05, -2.6], "hint": [70, 40, -60, 25], "wrist": {"twist": 90}},
                          "LA": {"chest": [-1.25, -0.55, 0.95], "hint": [-45, 35, 0, 35]}},
                 through_dt=.07)


def flash_air1(old):        # in the air, the kunai cut down and across
    return air("Flashstep", old,
               antic={"RA": {"chest": [1.0, 0.8, -0.2], "hint": [90, 45, -20, 90], "wrist": {"twist": 90}}},
               hit={"root": {"pitch": 18, "turn": 8}, "RA": {"hand": [0.0, 0.9, -2.5], "hint": [70, 25, -30, 15], "wrist": {"twist": 90}}},
               through={"root": {"pitch": 20, "turn": 16}, "RA": {"hand": [-0.9, 0.5, -2.1], "hint": [60, 35, -60, 25], "wrist": {"twist": 90}}},
               arms=MINATO_AIR, through_dt=.07)


def flash_air2(old):        # a turn in the air, the kunai at arm's length round him at waist height
    return air("Flashstep", old,
               antic={"root": {"turn": -50}, "RA": {"hand": [1.4, 0.6, 0.0], "hint": [20, 70, -20, 40], "wrist": {"twist": 90}}},
               hit={"root": {"turn": 20, "pitch": 6}, "RA": {"hand": [0.1, 0.6, -2.7], "hint": [75, 45, -50, 8], "wrist": {"twist": 90}},
                    "LA": {"chest": [-1.3, -0.4, 0.4], "hint": [-15, 55, 0, 50]}},
               through={"root": {"turn": 55, "pitch": 6}, "RA": {"hand": [-1.4, 0.5, -2.0], "hint": [70, 60, -70, 10], "wrist": {"twist": 90}},
                        "LA": {"chest": [-1.35, -0.4, 0.6], "hint": [-20, 55, 0, 50]}},
               arms=MINATO_AIR, antic_at=.5, through_dt=.08)


def flash_slam(old):        # he lands on the body: the kunai driven down two-handed
    return blow2("Flashstep", old,
                 antic={"root": {"sink": .3, "pitch": -6},
                        "RA": {"hand": [0.15, 2.6, -0.4], "hint": [165, 15, 0, 60], "wrist": {"twist": 90}},
                        "LA": {"hand": [-0.1, 2.5, -0.4], "hint": [165, 15, 0, 60]}},
                 hit={"root": {"sink": 1.2, "pitch": 30, "z": -0.2}, "Waist": {"pitch": 14},
                      "RA": {"hand": [0.1, -1.6, -2.0], "hint": [35, 10, 0, 10], "wrist": {"twist": 90}},
                      "LA": {"hand": [-0.1, -1.5, -1.95], "hint": [35, 10, 0, 10]}},
                 through={"root": {"sink": 1.25, "pitch": 32, "z": -0.22}, "Waist": {"pitch": 15},
                          "RA": {"hand": [0.1, -1.95, -1.95], "hint": [28, 10, 0, 8], "wrist": {"twist": 90}},
                          "LA": {"hand": [-0.1, -1.85, -1.9], "hint": [28, 10, 0, 8]}},
                 back={"root": {"sink": .7, "pitch": 14}}, antic_at=.5, through_dt=.1)


def flash_launcher(old):    # the rising cut out of a crouch, the body follows it up onto the toes
    return blow2("Flashstep", old,
                 antic={"root": {"sink": 1.0, "pitch": 20}, "RA": {"hand": [0.7, -1.4, -1.0], "hint": [20, 35, -20, 40], "wrist": {"twist": 90}}},
                 hit={"root": {"sink": -.15, "pitch": -8, "z": -0.3}, "Waist": {"pitch": -4}, "Neck": {"pitch": 12},
                      "RA": {"hand": [0.2, 2.2, -2.2], "hint": [130, 20, -30, 15], "wrist": {"twist": 90}},
                      "LL": {"foot": [-0.65, -0.95], "yaw": 14, "toe": -35}, "RL": {"foot": [0.8, 0.7], "yaw": -36, "toe": -40}},
                 through={"root": {"sink": -.25, "pitch": -10, "z": -0.32}, "Waist": {"pitch": -5}, "Neck": {"pitch": 14},
                          "RA": {"hand": [0.15, 2.9, -1.6], "hint": [155, 20, -30, 10], "wrist": {"twist": 90}},
                          "LL": {"foot": [-0.65, -0.95], "yaw": 14, "toe": -38}, "RL": {"foot": [0.8, 0.7], "yaw": -36, "toe": -42}},
                 antic_at=.5, through_dt=.07)


def flash_grab(old):        # no hold: the left palm laid flat on the chest (the seal goes in), the kunai ready
    return blow2("Flashstep", old,
                 antic={"LA": {"chest": [-0.8, 0.2, -1.2], "hint": [70, 25, 10, 70]}},
                 hit={"root": {"z": -0.35, "turn": -36, "pitch": 12}, "LA": {"hand": [-0.1, 1.35, -2.55], "hint": STRAIGHT, "wrist": {"swing": -85}}},
                 through={"root": {"z": -0.37, "turn": -36, "pitch": 12}, "LA": {"hand": [-0.1, 1.37, -2.62], "hint": STRAIGHT2, "wrist": {"swing": -85}}},
                 back={"root": {"turn": 10, "sink": .5}, "LA": {"hand": [-1.0, 1.0, -1.4], "hint": [60, 40, 0, 60]},
                       "RA": {"hand": [0.2, 1.5, -2.4], "hint": [85, 30, -40, 20], "wrist": {"twist": 90}}},
                 antic_at=.6, through_dt=.1)


def flash_idle(old):        # relaxed, a hand on his hip, the kunai turning in the other's fingers
    base = {"root": {"sink": .05, "lean": -3}, "LL": {"foot": [-0.55, 0.05], "yaw": 10}, "RL": {"foot": [0.55, -0.05], "yaw": -12},
            "LA": {"hand": [-0.95, 0.25, -0.15], "hint": [10, 60, 0, 110]},
            "RA": {"hand": [0.55, 0.55, -0.9], "hint": [40, 25, -10, 100], "wrist": {"twist": 0}}, "Neck": {"pitch": 2}}
    return loop("Flashstep", old, [
        {"RA": {"hand": [0.55, 0.55, -0.9], "hint": [40, 25, -10, 100], "wrist": {"twist": 0}}},
        {"RA": {"hand": [0.55, 0.6, -0.9], "hint": [40, 25, -10, 100], "wrist": {"twist": 120}}, "Neck": {"turn": 10}},
        {"RA": {"hand": [0.55, 0.55, -0.9], "hint": [40, 25, -10, 100], "wrist": {"twist": 240}}},
        {"RA": {"hand": [0.55, 0.6, -0.9], "hint": [40, 25, -10, 100], "wrist": {"twist": 355}}, "Neck": {"turn": -6}}], base)


CLIPS = {
    "Legion.Light4": legion_light4, "Legion.DashAttack": legion_dash,
    "Legion.Air1": legion_air1, "Legion.Air2": legion_air2, "Legion.Slam": legion_slam, "Legion.Launcher": legion_launcher,
    "Legion.Grab": legion_grab, "Legion.Idle": legion_idle,
    "Lion.Light4": lion_light4, "Lion.DashAttack": lion_dash, "Lion.Air1": lion_air1,
    "Lion.Air2": lion_air2, "Lion.Slam": lion_slam, "Lion.Launcher": E.lion_lionkick, "Lion.Grab": lion_grab, "Lion.Idle": lion_idle,
    "Leaf.DashAttack": leaf_dash, "Leaf.Air1": leaf_air1, "Leaf.Air2": leaf_air2,
    "Leaf.Grab": leaf_grab, "Leaf.Idle": leaf_idle,
    "GentleFist.Light1": E4.gentle_light1, "GentleFist.Light2": E4.gentle_light2, "GentleFist.Heavy": E4.gentle_heavy,
    "GentleFist.Sweep": E4.gentle_sweep,
    "GentleFist.DashAttack": gentle_dash, "GentleFist.Air1": gentle_air1, "GentleFist.Air2": gentle_air2,
    "GentleFist.Slam": gentle_slam, "GentleFist.Launcher": gentle_launcher, "GentleFist.Grab": gentle_grab, "GentleFist.Idle": gentle_idle,
    "Sand.DashAttack": sand_dash, "Sand.Air1": sand_air1, "Sand.Air2": sand_air2, "Sand.Grab": sand_grab, "Sand.Idle": sand_idle,
    "Copycat.Light1": copy_light1,
    "Copycat.DashAttack": copy_dash, "Copycat.Air1": copy_air1, "Copycat.Air2": copy_air2, "Copycat.Slam": copy_slam,
    "Copycat.Launcher": copy_launcher, "Copycat.Grab": copy_grab, "Copycat.Idle": copy_idle,
    "Mirage.Air1": mirage_air1, "Mirage.Air2": mirage_air2, "Mirage.Slam": mirage_slam,
    "Mirage.Launcher": mirage_launcher, "Mirage.Idle": mirage_idle,
    "Flashstep.Light2": flash_light2, "Flashstep.Air1": flash_air1, "Flashstep.Air2": flash_air2,
    "Flashstep.Launcher": flash_launcher, "Flashstep.Grab": flash_grab, "Flashstep.Idle": flash_idle,
}


# The idles above are each kit's way of standing about in the village (Kakashi's book, Sasuke's
# pockets...). In the duel the engine eases from <kit>.Idle into the walk over the first studs
# per second (VelmoraMotionEngine.authoredLocomotion): a hand behind the neck or in a pocket
# snapped there (tests/Animation: 49 degrees in a frame), and the narrower stance let the
# planted feet skate on a turn (tests/BodyRange, Film10Feet). So they are <kit>.Rest, built over
# <kit>.Idle's timing: HubBody plays them when the walker stands still in Konoha, the duel keeps
# its Idle.
def _rest(fn):
    def r(old):
        return fn(old)
    return r


for _name in [n for n in CLIPS if n.endswith(".Idle")]:
    _fn = _rest(CLIPS.pop(_name))
    _fn.base = _name
    CLIPS[_name[:-len("Idle")] + "Rest"] = _fn
