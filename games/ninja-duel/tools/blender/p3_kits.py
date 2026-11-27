"""Passe commune 3 (27/11), ANIMATEUR: what the OUTILLEUR's kit bench showed on the 8 kits
(tools/kitbench, mesures/2026-11-26_6c673043, « Robots de la passe 3 »):

  * Gaara's heavy was Sasuke's (Lion.Heavy, the only borrowed blow): Sand.Heavy is his own.
  * the forward dodge (Dash.F) was one silhouette for all 8 (leaning forward, an arm back):
    each kit gets its own way of slipping in.
  * the guard looked like the rest pose: GUARD[kit] is the stance every blow starts from, and
    <kit>.Guard only breathed in it. Each kit now BLOCKS: the arms come up into a cover of its
    own, the weight drops behind it. Its steps, its skid and the blow taken on it
    (Guard.Step.*, Guard.Skid, Guard.Impact) take the same arms, so the cover holds while it
    moves and when it is hit.
  * Light1 came out small on Sasuke, Neji, Kakashi and Minato, and Gaara's lights barely moved
    the body: a real step in, the shoulder behind the arm, and the arm still out at the
    "recover" marker (the bench samples every 0.13 s: a 0.3 s jab with its contact at 0.08 s
    showed only the stance).

The DEV's timing is kept: each clip is built over the one it replaces (Sand.Heavy over
Lion.Heavy, which Gaara played until now), same length, same markers. Space as in e2_strikes.
"""
import copy

import e2_strikes as E
import e4_strikes as E4  # noqa: F401  (the five other guards)
from e2_strikes import merge, key
from p2_strikes import blow2

G = E.GUARD
KITS = ("Legion", "Lion", "Leaf", "GentleFist", "Sand", "Copycat", "Mirage", "Flashstep")


# ================================================================== the guards: a block each
# root/Waist/Neck changes from the stance, and the two arms (in the chest's frame: x right,
# y up, -z forward from the UpperTorso's centre; a forearm across the face is y ~ .7).
BLOCK = {
    "Legion": {   # NARUTO: the boxer's shell, both fists high by the temples, elbows in, hunched
        "root": {"turn": -10, "pitch": 14, "sink": .5}, "Waist": {"turn": 0, "pitch": 12}, "Neck": {"turn": 6, "pitch": 14},
        "LA": {"chest": [-0.34, 0.82, -0.95], "hint": [120, 5, 20, 140], "wrist": {"swing": 20}},
        "RA": {"chest": [0.34, 0.78, -0.92], "hint": [120, 5, -20, 140], "wrist": {"swing": 20}},
    },
    "Lion": {     # SASUKE: the forearms crossed in an X before the face, side-on kept, chin tucked
        "root": {"turn": -38, "pitch": 6, "sink": .32}, "Waist": {"turn": 4, "pitch": 6}, "Neck": {"turn": 30, "pitch": 12},
        "LA": {"chest": [0.25, 0.6, -1.02], "hint": [100, -10, 40, 115], "wrist": {"swing": -10}},
        "RA": {"chest": [-0.25, 0.48, -1.05], "hint": [95, -10, -40, 110], "wrist": {"swing": -10}},
    },
    "Leaf": {     # LEE: one forearm up and vertical before him (the Goken block), the other behind the back
        "root": {"turn": -30, "pitch": 4, "sink": .5}, "Waist": {"turn": 10, "pitch": 2}, "Neck": {"turn": 18, "pitch": 6},
        "LA": {"chest": [-0.05, 0.7, -1.05], "hint": [80, 0, 70, 95], "wrist": {"swing": 0}},
        "RA": {"chest": [0.3, -0.75, 0.98], "hint": [-45, 10, 0, 75]},
    },
    "GentleFist": {  # NEJI: square to him, both palms spread wide at the shoulders (the Hakkesho's start)
        "root": {"turn": -8, "pitch": 4, "sink": .48}, "Waist": {"turn": 0, "pitch": 2}, "Neck": {"turn": 4, "pitch": 2},
        "LA": {"chest": [-1.25, 0.55, -0.95], "hint": [80, 60, 0, 40], "wrist": {"swing": -80}},
        "RA": {"chest": [1.25, 0.55, -0.95], "hint": [80, 60, 0, 40], "wrist": {"swing": -80}},
        "LL": {"foot": [-0.75, -0.5], "yaw": 20}, "RL": {"foot": [0.8, 0.45], "yaw": -25},
    },
    "Sand": {     # GAARA: still crossed with the left arm; the right palm opens out before him (the sand wall)
        "root": {"turn": -8, "pitch": -2, "sink": .08}, "Neck": {"turn": 4, "pitch": 6},
        "RA": {"chest": [0.2, 0.55, -1.75], "hint": [88, 10, 0, 15], "wrist": {"swing": -85}},
        "LA": {"chest": [0.45, -0.1, -1.1], "hint": [45, 10, 0, 115]},
    },
    "Copycat": {  # KAKASHI: the reversed kunai held flat across the chest, the left palm braced behind its blade
        "root": {"turn": -24, "pitch": 12, "sink": .4}, "Waist": {"turn": 6, "pitch": 10}, "Neck": {"turn": 18, "pitch": 4},
        "RA": {"chest": [-0.1, 0.4, -1.15], "hint": [85, 30, -30, 95], "wrist": {"twist": 80, "swing": -20}},
        "LA": {"chest": [-0.45, 0.42, -1.05], "hint": [80, 20, 20, 90], "wrist": {"swing": -80}},
    },
    "Mirage": {   # ITACHI: upright; one forearm raised across the face, the other hand stays in the robe
        "root": {"turn": -30, "pitch": -2, "sink": .14}, "Neck": {"turn": 22, "pitch": 4},
        "RA": {"chest": [-0.2, 0.72, -1.02], "hint": [110, 40, -10, 100], "wrist": {"swing": 0}},
        "LA": {"chest": [-0.2, 0.0, -0.9], "hint": [35, 15, 0, 120]},
    },
    "Flashstep": {  # MINATO: crouched right down, the kunai arm and the open hand crossed low before the chest
        "root": {"turn": -18, "pitch": 20, "sink": .7}, "Waist": {"turn": 2, "pitch": 10}, "Neck": {"turn": 12, "pitch": -16},
        "RA": {"chest": [-0.25, 0.15, -1.25], "hint": [75, 20, -30, 90], "wrist": {"twist": 90}},
        "LA": {"chest": [0.28, 0.05, -1.2], "hint": [75, 20, 30, 90], "wrist": {"swing": -40}},
    },
}


def block_pose(kit):
    g = copy.deepcopy(G[kit])
    for part, v in BLOCK[kit].items():
        if part in ("RA", "LA", "RL", "LL"):
            g[part] = copy.deepcopy(v)
        else:
            g[part] = merge(g.get(part, {}), v)
    return g


def nudge(pose, arm, dy=0.0, dz=0.0):
    a = copy.deepcopy(pose[arm])
    c = list(a["chest"]); c[1] += dy; c[2] += dz; a["chest"] = c
    return a


def guard(kit):
    def fn(old):
        b = block_pose(kit)
        L = old["length"]
        breath = {"root": {"pitch": b["root"].get("pitch", 0) + 1.5}, "Neck": {"pitch": b["Neck"].get("pitch", 0) + 2},
                  "RA": nudge(b, "RA", -.03), "LA": nudge(b, "LA", -.03)}
        return {"keys": [key(0, b), key(round(L * .5, 4), b, **breath), key(L, b)], "loop": True}
    fn.kit = kit
    return fn


def guard_impact(kit):
    """A blow on the cover: knocked back half a step, the arms crushed into the body, then up again."""
    def fn(old):
        b = block_pose(kit)
        L = old["length"]
        hit = {"root": {"z": 0.28, "pitch": b["root"].get("pitch", 0) - 6, "sink": b["root"].get("sink", 0) + .1},
               "Neck": {"pitch": b["Neck"].get("pitch", 0) + 6},
               "RA": nudge(b, "RA", -.08, .22), "LA": nudge(b, "LA", -.08, .22)}
        return {"keys": [key(0, b, "out"), key(round(L * .18, 4), b, "out", **hit),
                         key(round(L * .45, 4), b, "smooth", root={"z": 0.18}), key(L, b)]}
    return fn


# ================================================================== the forward dodge
def dash(kit, push, glide, land=None):
    """0 stance -> the push-off (a dip, the arms set) -> the glide (held: the dodge is quick)
    -> landing back into the stance."""
    def fn(old):
        g = G[kit]
        L = old["length"]
        keys = [key(0, g, "in"), key(round(L * .18, 4), g, "out", **push), key(round(L * .42, 4), g, "smooth", **glide),
                key(round(L * .72, 4), g, "smooth", **merge(glide, land or {})), key(L, g, "smooth")]
        return {"keys": keys}
    return fn


DASH = {
    # NARUTO: the head-down ninja run, both arms flung straight back
    "Legion": dash("Legion",
                   {"root": {"turn": -6, "pitch": 18, "sink": .6}, "LA": {"chest": [-0.55, -0.2, 0.6], "hint": [-20, 30, 0, 40]},
                    "RA": {"chest": [0.55, -0.2, 0.6], "hint": [-20, 30, 0, 40]}},
                   {"root": {"turn": 0, "pitch": 34, "sink": .5}, "Waist": {"pitch": 10}, "Neck": {"turn": 0, "pitch": -26},
                    "LA": {"chest": [-0.55, -1.0, 1.25], "hint": [-55, 20, 0, 10]}, "RA": {"chest": [0.55, -1.0, 1.25], "hint": [-55, 20, 0, 10]},
                    "LL": {"foot": [-0.3, -1.3], "yaw": 0}, "RL": {"foot": [0.35, 1.05], "yaw": -5, "toe": -30}}),
    # SASUKE: low and side-on, the rear hand still at the chin, the lead hand low and open
    "Lion": dash("Lion",
                 {"root": {"turn": -45, "pitch": 10, "sink": .5}},
                 {"root": {"turn": -42, "pitch": 18, "sink": .62}, "Waist": {"pitch": 6}, "Neck": {"turn": 36, "pitch": -10},
                  "RA": {"chest": [-0.45, 0.55, -0.85], "hint": [70, 30, -20, 125]},
                  "LA": {"chest": [-1.25, -0.75, -0.6], "hint": [25, 30, 20, 25], "wrist": {"swing": 20}},
                  "LL": {"foot": [-0.35, -1.45], "yaw": 30}, "RL": {"foot": [0.55, 0.95], "yaw": -60, "toe": -20}}),
    # LEE: a sprinter's start, the lead hand a blade before him, the other behind the back
    "Leaf": dash("Leaf",
                 {"root": {"turn": -14, "pitch": 24, "sink": .7}},
                 {"root": {"turn": -10, "pitch": 38, "sink": .62}, "Waist": {"pitch": 6}, "Neck": {"turn": 8, "pitch": -24},
                  "LA": {"chest": [-0.35, -0.35, -1.45], "hint": [60, 10, 0, 15], "wrist": {"swing": -10}},
                  "RA": {"chest": [0.3, -0.75, 0.98], "hint": [-45, 10, 0, 75]},
                  "LL": {"foot": [-0.25, -1.55], "yaw": 5}, "RL": {"foot": [0.35, 1.15], "yaw": -10, "toe": -30}}),
    # NEJI: upright, he glides in on his feet, both palms forward and down
    "GentleFist": dash("GentleFist",
                       {"root": {"turn": -34, "pitch": 4, "sink": .42}},
                       {"root": {"turn": -28, "pitch": 6, "sink": .36}, "Neck": {"turn": 24, "pitch": 2},
                        "LA": {"chest": [-0.55, -0.55, -1.45], "hint": [55, 20, 0, 20], "wrist": {"swing": -85}},
                        "RA": {"chest": [0.55, -0.65, -1.3], "hint": [55, 20, 0, 25], "wrist": {"swing": -85}},
                        "LL": {"foot": [-0.45, -0.95], "yaw": 25}, "RL": {"foot": [0.8, 0.6], "yaw": -55, "toe": -8}}),
    # GAARA: he does not run: carried upright on the sand, arms crossed, leaning back a little
    "Sand": dash("Sand",
                 {"root": {"turn": -8, "pitch": -3, "sink": .1}},
                 {"root": {"turn": -4, "pitch": -8, "sink": .05}, "Neck": {"turn": 0, "pitch": 10},
                  "LA": {"chest": [0.42, 0.05, -1.0], "hint": [45, 10, 0, 125]}, "RA": {"chest": [-0.42, 0.18, -1.12], "hint": [45, 10, 0, 125]},
                  "LL": {"foot": [-0.3, -0.25], "yaw": 2}, "RL": {"foot": [0.32, 0.25], "yaw": -4}}),
    # KAKASHI: ducked, the left hand out before him, the right going to the pouch on his hip
    "Copycat": dash("Copycat",
                    {"root": {"turn": -24, "pitch": 18, "sink": .55}},
                    {"root": {"turn": -18, "pitch": 26, "sink": .58}, "Waist": {"pitch": 10}, "Neck": {"turn": 14, "pitch": -14},
                     "LA": {"chest": [-0.45, 0.05, -1.45], "hint": [80, 15, 10, 25], "wrist": {"swing": -60}},
                     "RA": {"chest": [0.65, -1.05, 0.45], "hint": [-10, 35, 0, 70], "wrist": {"twist": 80}},
                     "LL": {"foot": [-0.4, -1.15], "yaw": 12}, "RL": {"foot": [0.6, 0.85], "yaw": -35, "toe": -22}}),
    # ITACHI: one step, upright, the robe hand stays in, the other loose at his side
    "Mirage": dash("Mirage",
                   {"root": {"turn": -34, "pitch": 2, "sink": .16}},
                   {"root": {"turn": -36, "pitch": 3, "sink": .18}, "Neck": {"turn": 30, "pitch": 8},
                    "RA": {"chest": [1.0, -1.15, 0.25], "hint": [-5, 15, 0, 15]},
                    "LA": {"chest": [-0.2, 0.0, -0.9], "hint": [35, 15, 0, 120]},
                    "LL": {"foot": [-0.35, -0.7], "yaw": 18}, "RL": {"foot": [0.45, 0.5], "yaw": -40, "toe": -10}}),
    # MINATO: nearly flat over a long stride, the reversed kunai out in front, the left arm trailing
    "Flashstep": dash("Flashstep",
                      {"root": {"turn": -20, "pitch": 26, "sink": .8}},
                      {"root": {"turn": -14, "pitch": 44, "sink": .78}, "Waist": {"pitch": 10}, "Neck": {"turn": 10, "pitch": -30},
                       "RA": {"chest": [0.2, 0.05, -1.75], "hint": [80, 15, -10, 10], "wrist": {"twist": 90}},
                       "LA": {"chest": [-0.85, -0.65, 0.75], "hint": [-30, 40, 0, 30]},
                       "LL": {"foot": [-0.35, -1.75], "yaw": 10}, "RL": {"foot": [0.45, 1.35], "yaw": -20, "toe": -32}}),
}


# ================================================================== Light1, bigger
def held(old):
    """The follow-through's time: the arm is still out at the recover marker."""
    m = old["markers"]
    return round(m.get("recover", m["contact"] + .1) - m["contact"], 4)


def lion_light1(old):       # a held beat, then the lead hand shot out with a step: the whole side behind it
    return blow2("Lion", old,
                 antic={"root": {"turn": -40, "z": 0.12, "sink": .3}, "Neck": {"turn": 40},
                        "LA": {"chest": [-1.0, 0.25, -0.55], "hint": [60, 30, 30, 120]}},
                 hit={"root": {"turn": -72, "z": -0.5, "pitch": 6, "sink": .32}, "Waist": {"turn": -8}, "Neck": {"turn": 58},
                      "LL": {"foot": [-0.25, -1.25], "yaw": 35},
                      "LA": {"hand": [-0.05, 1.8, -3.15], "hint": [95, 5, 15, 2], "wrist": {"swing": 0}}},
                 through={"root": {"turn": -74, "z": -0.55, "pitch": 7, "sink": .32}, "Waist": {"turn": -9}, "Neck": {"turn": 60},
                          "LL": {"foot": [-0.25, -1.25], "yaw": 35},
                          "LA": {"hand": [-0.02, 1.82, -3.25], "hint": [95, 5, 15, 0]}},
                 back={"LL": {"foot": [-0.25, -0.7], "yaw": 35, "lift": .2}},
                 antic_at=.6, through_dt=held(old))


def gentle_light1(old):     # the lead palm driven from the hip into the chest, the lead foot sliding in
    return blow2("GentleFist", old,
                 antic={"root": {"turn": -50, "z": 0.1}, "LA": {"chest": [-0.7, -0.4, -0.6], "hint": [40, 25, 20, 110], "wrist": {"swing": -80}}},
                 hit={"root": {"turn": -24, "z": -0.55, "pitch": 8, "sink": .42}, "Waist": {"turn": 4, "pitch": 6}, "Neck": {"turn": 22},
                      "LL": {"foot": [-0.45, -1.45], "yaw": 20},
                      "LA": {"hand": [-0.25, 1.45, -3.2], "hint": [92, 8, 0, 4], "wrist": {"swing": -88}},
                      "RA": {"chest": [0.85, -0.85, -0.9], "hint": [35, 30, -10, 60], "wrist": {"swing": -60}}},
                 through={"root": {"turn": -22, "z": -0.6, "pitch": 9, "sink": .42}, "Waist": {"turn": 5, "pitch": 7}, "Neck": {"turn": 20},
                          "LL": {"foot": [-0.45, -1.45], "yaw": 20},
                          "LA": {"hand": [-0.22, 1.45, -3.3], "hint": [92, 8, 0, 2], "wrist": {"swing": -88}},
                          "RA": {"chest": [0.85, -0.85, -0.9], "hint": [35, 30, -10, 60], "wrist": {"swing": -60}}},
                 back={"LL": {"foot": [-0.5, -1.0], "yaw": 25, "lift": .15}},
                 antic_at=.5, through_dt=held(old))


CK_Z = -3.55


def copy_light1(old):       # the left palm shoved into the face, the shoulder behind it, the kunai kept back
    return blow2("Copycat", old,
                 antic={"root": {"turn": -20, "z": 0.1}, "LA": {"chest": [-0.6, 0.25, -0.65], "hint": [70, 25, 10, 120]}},
                 hit={"root": {"turn": -46, "z": -0.45, "pitch": 12}, "Waist": {"turn": -6, "pitch": 10}, "Neck": {"turn": 30},
                      "LL": {"foot": [-0.45, -1.2], "yaw": 15},
                      "LA": {"hand": [-0.05, 1.75, CK_Z], "hint": [94, 6, 10, 3], "wrist": {"swing": -80}},
                      "RA": {"chest": [0.6, -0.4, -0.7], "hint": [40, 30, -10, 110], "wrist": {"twist": 80}}},
                 through={"root": {"turn": -48, "z": -0.5, "pitch": 13}, "Waist": {"turn": -7, "pitch": 11}, "Neck": {"turn": 32},
                          "LL": {"foot": [-0.45, -1.2], "yaw": 15},
                          "LA": {"hand": [-0.03, 1.77, CK_Z - .08], "hint": [94, 6, 10, 1], "wrist": {"swing": -80}},
                          "RA": {"chest": [0.6, -0.4, -0.7], "hint": [40, 30, -10, 110], "wrist": {"twist": 80}}},
                 back={"LL": {"foot": [-0.5, -0.75], "yaw": 15, "lift": .18}},
                 antic_at=.5, through_dt=held(old))


def flash_light1(old):      # the reversed kunai cocked by the ear, cut across with a lunge, the body turning through it
    return blow2("Flashstep", old,
                 antic={"root": {"turn": -50, "z": 0.1}, "RA": {"chest": [1.05, 0.3, -0.45], "hint": [40, 40, -20, 100], "wrist": {"twist": 90}}},
                 hit={"root": {"turn": 2, "z": -0.6, "pitch": 18, "sink": .52}, "Waist": {"turn": 12, "pitch": 8},
                      "LL": {"foot": [-0.65, -1.5], "yaw": 14},
                      "RA": {"hand": [0.2, FL_Y, FL_Z], "hint": [85, 30, -40, 15], "wrist": {"twist": 90}},
                      "LA": {"chest": [-1.15, -0.5, 0.1], "hint": [10, 40, 0, 70]}},
                 through={"root": {"turn": 16, "z": -0.65, "pitch": 19, "sink": .54}, "Waist": {"turn": 16, "pitch": 9},
                          "LL": {"foot": [-0.65, -1.5], "yaw": 14},
                          "RA": {"hand": [-0.85, FL_Y - .1, FL_Z + .3], "hint": [75, 30, -60, 20], "wrist": {"twist": 90}},
                          "LA": {"chest": [-1.2, -0.55, 0.2], "hint": [5, 40, 0, 70]}},
                 back={"LL": {"foot": [-0.65, -0.95], "yaw": 14, "lift": .2}},
                 antic_at=.55, through_dt=held(old))


FL_Y, FL_Z = 1.45, -2.9


# ================================================================== Gaara: the sand moves, so does he
def sand_push(old, side, at, lean, turn, step=None, wrist=None, both=False, antic_hand=None):
    """Gaara's blow, bigger: the arm thrown out to full length with the shoulder behind it,
    the body turning and leaning into the gesture, the lead foot sliding half a step."""
    h, o = ("RA", "LA") if side == "R" else ("LA", "RA")
    sx = 1 if side == "R" else -1
    w = wrist or {"swing": -70}
    arm = {"hand": [at[0] * sx, at[1], at[2]], "hint": [88, 10, 0, 4], "wrist": w}
    arm2 = {"hand": [at[0] * sx, at[1] + .03, at[2] - .08], "hint": [88, 10, 0, 4], "wrist": w}
    body = {"root": {"turn": -8 + turn * sx, "pitch": lean, "z": -0.35, "sink": .22}, "Waist": {"turn": 6 * sx, "pitch": lean * .6},
            "Neck": {"turn": 6 - turn * .6 * sx, "pitch": 4}}
    if step:
        body["LL" if side == "L" else "RL"] = step
    hit = merge(body, {h: arm})
    through = merge(body, {h: arm2, "root": {"pitch": lean * 1.1, "z": -0.4}})
    if both:
        hit[o] = {"hand": [-at[0] * sx, at[1] - .05, at[2]], "hint": [88, 10, 0, 4], "wrist": w}
        through[o] = {"hand": [-at[0] * sx, at[1] - .02, at[2] - .08], "hint": [88, 10, 0, 4], "wrist": w}
    else:
        hit[o] = {"chest": [0.4 * sx, -0.15, -0.8], "hint": [40, 10, 0, 125]}
        through[o] = hit[o]
    antic = {h: antic_hand or {"chest": [0.95 * sx, 0.1, -0.35], "hint": [35, 50, 0, 120], "wrist": {"swing": 15}},
             "root": {"turn": -8 - turn * .4 * sx, "z": 0.1, "pitch": -4}, "Waist": {"turn": -8 * sx}, "Neck": {"pitch": -2}}
    return blow2("Sand", old, antic=antic, hit=hit, through=through,
                 back={"root": {"z": -0.15}}, antic_at=.5, through_dt=held(old))


SL1, SL2, SL3 = -2.95, -2.85, -2.85


def sand_light1(old):       # the right hand thrown open at him, the body leaning after it
    return sand_push(old, "R", (0.3, 1.5, SL1), lean=12, turn=22, step={"foot": [0.6, -0.25], "yaw": -12})


def sand_light2(old):       # the left arm swept wide across, the hips turning with it
    return sand_push(old, "L", (0.5, 1.35, SL2), lean=10, turn=34, step={"foot": [-0.55, -0.6], "yaw": 6},
                     wrist={"swing": -20, "twist": 40},
                     antic_hand={"chest": [0.9, 0.4, -0.5], "hint": [50, 10, 60, 120], "wrist": {"twist": 40}})


def sand_light3(old):       # both palms shoved forward, the whole body behind them
    return sand_push(old, "R", (0.38, 1.4, SL3), lean=16, turn=4, step={"foot": [0.6, -0.3], "yaw": -12}, both=True,
                     wrist={"swing": -80},
                     antic_hand={"chest": [0.55, 0.0, -0.4], "hint": [40, 20, 0, 125], "wrist": {"swing": -60}})


def sand_heavy(old):        # the sand wave: both hands gathered up by the head, flung down and out at the ground before him
    gather = {"root": {"turn": 6, "pitch": -12, "z": 0.18, "sink": .1}, "Waist": {"turn": 14, "pitch": -8}, "Neck": {"turn": -6, "pitch": -10},
              "RA": {"chest": [1.0, 1.25, -0.55], "hint": [150, 30, 0, 70], "wrist": {"swing": 40}},
              "LA": {"chest": [0.45, 1.4, -0.8], "hint": [150, 10, 0, 70], "wrist": {"swing": 40}}}
    fling = {"root": {"turn": -12, "pitch": 22, "z": -0.55, "sink": .55}, "Waist": {"turn": -6, "pitch": 14}, "Neck": {"turn": 6, "pitch": -8},
             "RL": {"foot": [0.65, -0.4], "yaw": -14},
             "RA": {"hand": [0.6, -0.4, -3.0], "hint": [55, 20, 0, 4], "wrist": {"swing": -85}},
             "LA": {"hand": [-0.55, -0.45, -3.0], "hint": [55, 20, 0, 4], "wrist": {"swing": -85}}}
    spread = merge(fling, {"root": {"pitch": 24, "z": -0.6},
                           "RA": {"hand": [1.15, -0.55, -2.85], "hint": [50, 35, 0, 2], "wrist": {"swing": -85}},
                           "LA": {"hand": [-1.1, -0.6, -2.85], "hint": [50, 35, 0, 2], "wrist": {"swing": -85}}})
    return blow2("Sand", old, antic=gather, hit=fling, through=spread,
                 back={"root": {"pitch": 6, "z": -0.25, "sink": .2}, "RL": {"foot": [0.6, 0.15], "yaw": -12, "lift": .2}},
                 antic_at=.6, through_dt=.1)


sand_heavy.base = "Lion.Heavy"


# ================================================================== the list
CLIPS = {"Sand.Heavy": sand_heavy,
         "Lion.Light1": lion_light1, "GentleFist.Light1": gentle_light1,
         "Copycat.Light1": copy_light1, "Flashstep.Light1": flash_light1,
         "Sand.Light1": sand_light1, "Sand.Light2": sand_light2, "Sand.Light3": sand_light3}
for _k in KITS:
    CLIPS[_k + ".Guard"] = guard(_k)
    CLIPS[_k + ".Guard.Impact"] = guard_impact(_k)
    CLIPS[_k + ".Dash.F"] = DASH[_k]


# ================================================================== the run along a wall
# (27/11, François: « course latérale sur les murs ») The walker (Client/HubBody) and the duel's
# fighter running ALONG a wall: the body leans into the wall (the feet on it, the head off it), a
# long fast stride in the air, the arm on the wall's side low and back, the far arm pumping, the
# head turned along the run. R: the wall on his right; L the mirror.
def wall_run_side(f):
    def fn(old):
        L, a = old["length"], {"air": True}
        lean = 36 * f

        def stride(lead):
            g = 1 if lead == "L" else -1
            return {"root": {"pitch": 14, "lean": lean}, "Waist": {"pitch": 6, "turn": 8 * g, "lean": 6 * f}, "Neck": {"pitch": -8, "turn": -6 * g, "lean": -18 * f},
                    "LL": {"swing": 78 if g > 0 else -42, "spread": 4, "bend": 100 if g > 0 else 32, "ankle": 8 if g > 0 else -30},
                    "RL": {"swing": -42 if g > 0 else 78, "spread": 4, "bend": 32 if g > 0 else 100, "ankle": -30 if g > 0 else 8},
                    "LA": {"swing": -55 if g > 0 else 80, "spread": 22 if f > 0 else 10, "bend": 80},
                    "RA": {"swing": 80 if g > 0 else -55, "spread": 10 if f > 0 else 22, "bend": 80}}
        pass_ = {"root": {"pitch": 16, "lean": lean}, "Waist": {"pitch": 6, "lean": 6 * f}, "Neck": {"pitch": -8, "lean": -18 * f},
                 "LL": {"swing": 24, "spread": 4, "bend": 112}, "RL": {"swing": 24, "spread": 4, "bend": 112},
                 "LA": {"swing": 12, "spread": 16, "bend": 88}, "RA": {"swing": 12, "spread": 16, "bend": 88}}
        return {"keys": [key(0, stride("L"), "smooth", **a), key(L * .25, pass_, "smooth", **a), key(L * .5, stride("R"), "smooth", **a),
                         key(L * .75, pass_, "smooth", **a), key(L, stride("L"), "smooth", **a)], "loop": True}
    fn.base = "Lion.Parkour.WallRun"
    return fn


CLIPS["Lion.Parkour.WallRunSideR"] = wall_run_side(1)
CLIPS["Lion.Parkour.WallRunSideL"] = wall_run_side(-1)


# ================================================================== the « vol plané »
# (27/11, François: « créer des vraies animations de coups subis selon la situation : vol plané,
# recul, etc. », first the vol plané) A heavy blow sends the body flying back off its feet
# (the server's « flung » Knockback, Config.Flight): Knockback.Flung is the flight, laid out flat, the hips
# leading away from the blow, chin tucked, arms and legs trailing toward the attacker and
# drifting (loops from "loop"). Knockdown.Flung is the end of it: the back hits the floor, the
# body bounces once, slides on its back with the arms out and comes to rest exactly on the
# kit's Down (its first frame), where the get-up takes over. Each kit falls its own way
# (SIG): Naruto sprawls and flails, Lee and Minato tuck their knees in, Gaara stays stiff with
# his arms close, Neji keeps his composure.
SIG = {
    "Legion": {"flail": 1.25, "tuck": .25, "bounce": 1.15, "roll": 10},
    "Lion": {"flail": .8, "tuck": .5, "bounce": .9, "roll": -6},
    "Leaf": {"flail": 1.0, "tuck": .85, "bounce": 1.05, "roll": 8},
    "GentleFist": {"flail": .6, "tuck": .45, "bounce": .8, "roll": -4},
    "Sand": {"flail": .35, "tuck": .1, "bounce": .7, "roll": 0},
    "Copycat": {"flail": .7, "tuck": .6, "bounce": .9, "roll": -8},
    "Mirage": {"flail": .6, "tuck": .5, "bounce": .85, "roll": 6},
    "Flashstep": {"flail": .7, "tuck": .75, "bounce": .9, "roll": -6},
}


def _layout(s, phase):
    """Flying back, laid out. phase 0/1: the two ends of the limbs' drift."""
    fl, tk = s["flail"], s["tuck"]
    g = 1 if phase == 0 else -1
    return {"root": {"pitch": -62, "lean": s["roll"] * g * .5, "y": .3},
            "Waist": {"pitch": -12, "turn": 6 * g * fl}, "Neck": {"pitch": 26, "turn": -4 * g},
            "RA": {"swing": 62 + 24 * min(fl, 1) + 12 * g * fl, "spread": 30 + 20 * fl, "bend": 30 + 10 * fl},
            "LA": {"swing": 62 + 24 * min(fl, 1) - 12 * g * fl, "spread": 30 + 20 * fl, "bend": 34 + 10 * fl},
            "RL": {"swing": 40 + 40 * tk + 8 * g * fl, "spread": 8 + 6 * fl, "bend": 25 + 70 * tk, "ankle": -20},
            "LL": {"swing": 30 + 40 * tk - 8 * g * fl, "spread": 8 + 6 * fl, "bend": 15 + 70 * tk, "ankle": -25}}


def flung(kit):
    s = SIG[kit]

    def fn(old):
        a = {"air": True}
        whip = {"root": {"pitch": -32, "y": .1}, "Waist": {"pitch": -22}, "Neck": {"pitch": -24},
                "RA": {"swing": 95, "spread": 30, "bend": 20}, "LA": {"swing": 90, "spread": 34, "bend": 24},
                "RL": {"swing": 30, "spread": 6, "bend": 20, "ankle": -10}, "LL": {"swing": 12, "spread": 6, "bend": 10, "ankle": -10}}
        A0, A1 = _layout(s, 0), _layout(s, 1)
        return {"keys": [key(0, whip, "out", **a), key(.08, A0, "smooth", **a), key(.2, A0, "smooth", **a),
                         key(.4, A1, "smooth", **a), key(.6, A0, "smooth", **a)]}
    fn.base = kit + ".Knockback"
    return fn


DUMP = {}   # the game's clips (p3_build sets it): Knockdown.Flung ends on the kit's Down


def flung_land(kit):
    """Built over the kit's Knockdown, its own length (0.9 s); ends on Down's first frame."""
    s = SIG[kit]
    fl, tk, bo = s["flail"], s["tuck"], s["bounce"]

    def fn(old):
        import syph_author as SA
        a = {"air": True}
        down = DUMP.get(kit + ".Down")
        # the back takes the floor: the shoulders and hips on it, the limbs still up from the flight
        hit = {"root": {"pitch": -80, "y": -2.0, "z": .7, "lean": s["roll"]}, "Waist": {"pitch": -10}, "Neck": {"pitch": 28},
               "RA": {"swing": 75 + 15 * fl, "spread": 34, "bend": 24}, "LA": {"swing": 70 + 15 * fl, "spread": 38, "bend": 28},
               "RL": {"swing": 70 + 20 * tk, "spread": 10, "bend": 40 + 50 * tk, "ankle": -20}, "LL": {"swing": 60 + 20 * tk, "spread": 12, "bend": 30 + 50 * tk, "ankle": -20}}
        # it bounces once: the hips come off the floor, the knees fly up, the arms open
        bounce = {"root": {"pitch": -68, "y": -2.0 + .6 * bo, "z": .7, "lean": -s["roll"]}, "Waist": {"pitch": -6}, "Neck": {"pitch": 22},
                  "RA": {"swing": 40 + 30 * fl, "spread": 62, "bend": 30}, "LA": {"swing": 36 + 30 * fl, "spread": 66, "bend": 34},
                  "RL": {"swing": 95, "spread": 12, "bend": 75 + 25 * tk, "ankle": -30}, "LL": {"swing": 85, "spread": 14, "bend": 65 + 25 * tk, "ankle": -30}}
        # then slides on its back, the arms out wide along the floor, the knees up
        slide = {"root": {"pitch": -84, "y": -2.05, "z": .7, "lean": s["roll"] * 1.6}, "Waist": {"pitch": -4, "turn": s["roll"]}, "Neck": {"pitch": 16, "turn": -s["roll"] * 2},
                 "RA": {"swing": 14, "spread": 30 + 45 * fl, "bend": 22}, "LA": {"swing": 12, "spread": 28 + 45 * fl, "bend": 26},
                 "RL": {"swing": 20 + 50 * tk, "spread": 6 + 12 * fl, "bend": 20 + 80 * tk, "ankle": 10}, "LL": {"swing": 10 + 45 * tk, "spread": 8 + 12 * fl, "bend": 10 + 70 * tk, "ankle": 10}}
        if kit == "Sand":
            # Gaara even on his back: the arms stay folded on the chest
            for arm, sw in (("RA", 70), ("LA", 64)):
                slide[arm] = {"swing": sw, "spread": -10, "twist": 30, "bend": 115}
                bounce[arm] = {"swing": sw, "spread": -6, "twist": 30, "bend": 110}
                hit[arm] = {"swing": sw + 10, "spread": -6, "twist": 30, "bend": 105}
        keys = [key(0, hit, "out", **a), key(.13, bounce, "out", **a), key(.3, merge(slide, {"root": {"y": -2.0}}), "in2", **a),
                key(.62, slide, "smooth", **a)]
        if down:
            keys.append({"t": .9, "ease": "smooth", "raw": SA.frame_of(down, 0)})
        return {"keys": keys, "length": .9}
    fn.base = kit + ".Knockdown"
    return fn


for _k in KITS:
    CLIPS[_k + ".Knockback.Flung"] = flung(_k)
    CLIPS[_k + ".Knockdown.Flung"] = flung_land(_k)
