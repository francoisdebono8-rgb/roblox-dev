"""Étape 3 (DEC-047), ANIMATEUR 2 and 3: the clips of the ninja parkour, the second jump, the
quick rise, the victory poses and the emotes, on the player's own skeleton (syph_author).

    python3 tools/blender/e3_clips.py CLIPS.json OUT_DIR [--write]
      CLIPS.json: lune run tools/syphodev/clips_dump.luau CLIPS.json (the game's clips now)
      --write: src/Client/AuthoredJutsu9.luau (+10..) over the other layers

  <kit>.AirJump       the second jump (events.AirJump, the ninja tree's Cloud Step): a kick
                      off the air and a turn in each kit's own way (0.42 s, the engine's trick
                      time), body rotation included
  <kit>.Getup.Quick   the quick rise (ninja.rise): from the kit's Down to its stance like its
                      Getup, but a kip-up (the acrobats) or a push up in one move (the others);
                      the engine plays it in 0.24 s whatever its length
  Lion.Parkour.*      Leap (a long jump between roofs), LandRoll (a shoulder roll out of a
                      high fall), LandHard (a three-point landing), Vault (a hand on a ledge):
                      shared by the 8 kits (AuthoredMotion SHARED "Parkour")
  Victory.<Id>        the 8 victory poses of the shop (2.5 s, held at the end)
  Emote.<Id>          the emotes of Konoha (loops)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import syph_author as SA  # noqa: E402
from e2_strikes import key, merge  # noqa: E402

KITS = ("Legion", "Lion", "Leaf", "GentleFist", "Sand", "Copycat", "Mirage", "Flashstep")
ACRO = {"Legion", "Lion", "Leaf", "Flashstep", "Copycat"}   # they kip up; the others push up

# A plain standing body (the victory poses and emotes start from it)
STAND = {"root": {"sink": .08}, "LL": {"foot": [-0.55, 0.0], "yaw": 6}, "RL": {"foot": [0.55, 0.0], "yaw": -6},
         "LA": {"swing": 4, "spread": 8, "bend": 12}, "RA": {"swing": 4, "spread": 8, "bend": 12}}


def raw_key(t, rows, ease="smooth"):
    return {"t": t, "ease": ease, "raw": rows}


# ------------------------------------------------------------------ the quick rise
def getup_quick(kit, clips):
    g = clips[kit + ".Getup"]
    start = SA.frame_of(g, 0)
    end = SA.frame_of(g, g["length"])
    L = .5
    a = {"air": True}
    if kit in ACRO:   # the kip-up: legs over the head, the snap, feet under him
        roll = {"root": {"pitch": -140, "y": -0.45, "z": 0.85}, "Waist": {"pitch": 10}, "Neck": {"pitch": 25},
                "LL": {"swing": 135, "spread": 6, "bend": 110}, "RL": {"swing": 135, "spread": 6, "bend": 110},
                "LA": {"chest": [-1.3, 1.45, 0.4], "hint": [160, 50, 0, 90]}, "RA": {"chest": [1.3, 1.45, 0.4], "hint": [160, 50, 0, 90]}}
        snap = {"root": {"pitch": -45, "y": -0.2, "z": 0.25}, "Waist": {"pitch": -14}, "Neck": {"pitch": 10},
                "LL": {"swing": -5, "spread": 6, "bend": 70}, "RL": {"swing": -5, "spread": 6, "bend": 70},
                "LA": {"chest": [-1.85, 0.5, 0.3], "hint": [110, 80, 0, 20]}, "RA": {"chest": [1.85, 0.5, 0.3], "hint": [110, 80, 0, 20]}}
        crouch = {"root": {"pitch": 22, "sink": .9}, "Waist": {"pitch": 12},
                  "LL": {"foot": [-0.55, 0.15], "yaw": 8}, "RL": {"foot": [0.6, 0.2], "yaw": -12},
                  "LA": {"swing": 50, "spread": 45, "bend": 30}, "RA": {"swing": 45, "spread": 45, "bend": 30}}
        keys = [raw_key(0, start, "in2"), key(L * .3, {}, "out", **a, **roll), key(L * .55, {}, "out", **a, **snap),
                key(L * .78, {}, "smooth", **crouch), raw_key(L, end)]
    else:             # one push: a hand and a knee, up in one move (no flip: Gaara, Neji, Itachi)
        knee = {"root": {"pitch": 30, "y": -0.85, "turn": 10}, "Waist": {"pitch": 14},
                "LL": {"foot": [-0.5, -0.4], "yaw": 5}, "RL": {"swing": 10, "spread": 6, "bend": 95, "ankle": 20},
                "RA": {"hand": [0.9, -2.6, -0.2], "hint": [40, 30, 0, 10]}, "LA": {"swing": 40, "spread": 20, "bend": 50}}
        rise = {"root": {"pitch": 8, "sink": .35}, "Waist": {"pitch": 4},
                "LL": {"foot": [-0.55, -0.2], "yaw": 5}, "RL": {"foot": [0.55, 0.25], "yaw": -10},
                "LA": {"swing": 20, "spread": 15, "bend": 30}, "RA": {"swing": 10, "spread": 15, "bend": 20}}
        keys = [raw_key(0, start, "in2"), key(L * .4, {}, "out", **knee), key(L * .72, {}, "smooth", **rise), raw_key(L, end)]
    return {"keys": keys, "length": L, "markers": {}}


# ------------------------------------------------------------------ the second jump
ARMS_AIR = {
    "Legion": ({"swing": 120, "spread": 70, "bend": 30}, {"swing": -40, "spread": 80, "bend": 20}),   # flailing
    "Lion": ({"swing": 40, "spread": 20, "bend": 110}, {"swing": 40, "spread": 20, "bend": 110}),     # tight
    "Leaf": ({"swing": 60, "spread": 15, "bend": 90}, {"swing": -50, "spread": 10, "bend": 80}),      # one behind the back
    "GentleFist": ({"swing": 70, "spread": 40, "bend": 20}, {"swing": 70, "spread": 40, "bend": 20}), # open palms
    "Sand": ({"swing": 30, "spread": 10, "twist": 40, "bend": 100}, {"swing": 30, "spread": 10, "twist": -40, "bend": 100}),
    "Copycat": ({"swing": 20, "spread": 10, "bend": 60}, {"swing": 20, "spread": 10, "bend": 60}),
    "Mirage": ({"swing": 10, "spread": 8, "bend": 30}, {"swing": 10, "spread": 8, "bend": 30}),
    "Flashstep": ({"swing": 80, "spread": 20, "bend": 40}, {"swing": -30, "spread": 20, "bend": 30}),
}


def air_jump(kit):
    """The kick off the air (one foot stamps down on nothing: the push), then the kit's turn.
    The acrobats roll forward (a full 360); Gaara, Neji and Itachi rise straight, a half
    twist of the body instead (they do not flip)."""
    L = .42
    a = {"air": True}
    la, ra = ARMS_AIR[kit]
    push = {"root": {"pitch": 6, "y": .45}, "Waist": {"pitch": 6},
            "LL": {"swing": 60, "spread": 6, "bend": 100}, "RL": {"swing": -10, "spread": 6, "bend": 5, "ankle": -30},
            "LA": {"swing": 100, "spread": 30, "bend": 30}, "RA": {"swing": -30, "spread": 30, "bend": 20}}
    tuck = {"root": {"y": .45}, "Waist": {"pitch": 18}, "Neck": {"pitch": 20},
            "LL": {"swing": 125, "spread": 8, "bend": 135}, "RL": {"swing": 120, "spread": 8, "bend": 135}, "LA": la, "RA": ra}
    open_ = {"root": {"y": .45}, "Waist": {"pitch": 4}, "LL": {"swing": 45, "spread": 8, "bend": 60}, "RL": {"swing": 10, "spread": 8, "bend": 40},
             "LA": {"swing": 50, "spread": 35, "bend": 30}, "RA": {"swing": 30, "spread": 35, "bend": 30}}
    if kit in ("Sand", "GentleFist", "Mirage"):
        keys = [key(0, push, "out", **a), key(L * .3, merge(push, {"root": {"turn": 60, "pitch": -4}}), "smooth", **a),
                key(L * .6, merge(open_, {"root": {"turn": 150}}), "smooth", **a),
                key(L * .85, merge(open_, {"root": {"turn": 260}}), "smooth", **a), key(L, merge(open_, {"root": {"turn": 360}}), "smooth", **a)]
    else:
        keys = [key(0, push, "out", **a), key(L * .2, merge(tuck, {"root": {"pitch": 70}}), "linear", **a),
                key(L * .45, merge(tuck, {"root": {"pitch": 180}}), "linear", **a),
                key(L * .7, merge(tuck, {"root": {"pitch": 280}}), "out", **a),
                key(L, merge(open_, {"root": {"pitch": 360}}), "smooth", **a)]
    return {"keys": keys, "length": L, "markers": {}}


# ------------------------------------------------------------------ the parkour (shared)
def parkour_leap():
    """A long jump between roofs (the take-off has been pushed): stretched, the lead knee up,
    the arms reaching, then gathered for the landing."""
    L, a = .6, {"air": True}
    reach = {"root": {"pitch": 18}, "Waist": {"pitch": 6}, "Neck": {"pitch": -14},
             "LL": {"swing": 75, "spread": 6, "bend": 95}, "RL": {"swing": -35, "spread": 6, "bend": 40, "ankle": -30},
             "LA": {"swing": 150, "spread": 25, "bend": 10}, "RA": {"swing": -40, "spread": 30, "bend": 20}}
    gather = {"root": {"pitch": 4}, "Waist": {"pitch": 10},
              "LL": {"swing": 70, "spread": 8, "bend": 90}, "RL": {"swing": 55, "spread": 8, "bend": 100},
              "LA": {"swing": 70, "spread": 40, "bend": 30}, "RA": {"swing": 60, "spread": 40, "bend": 30}}
    return {"keys": [key(0, reach, "out", **a), key(L * .5, merge(reach, {"root": {"pitch": 12}}), "smooth", **a),
                     key(L, gather, "smooth", **a)], "length": L, "markers": {}, "loop": False}


def parkour_land_roll():
    """Out of a high fall: feet, then over the shoulder and up, without losing the run."""
    L = .7
    crouch = {"root": {"pitch": 30, "sink": 1.0}, "Waist": {"pitch": 20},
              "LL": {"foot": [-0.5, -0.2], "yaw": 5}, "RL": {"foot": [0.55, 0.2], "yaw": -5},
              "LA": {"hand": [-0.6, -2.4, -1.4], "hint": [60, 20, 0, 20]}, "RA": {"hand": [0.5, -2.2, -1.6], "hint": [60, 20, 0, 20]}}
    a = {"air": True}
    keys = [key(0, crouch, "out"),
            key(L * .25, {}, "linear", **a, root={"pitch": 100, "y": -0.95, "z": -0.8, "lean": 20}, Waist={"pitch": 30},
                Neck={"pitch": 40, "turn": -30}, LL={"swing": 110, "spread": 10, "bend": 130}, RL={"swing": 100, "spread": 10, "bend": 130},
                LA={"swing": 90, "spread": 40, "bend": 60}, RA={"swing": 60, "spread": 20, "bend": 90}),
            key(L * .5, {}, "linear", **a, root={"pitch": 220, "y": -0.3, "z": -1.4, "lean": 15}, Waist={"pitch": 30},
                Neck={"pitch": 40}, LL={"swing": 120, "spread": 10, "bend": 140}, RL={"swing": 115, "spread": 10, "bend": 140},
                LA={"swing": 80, "spread": 40, "bend": 60}, RA={"swing": 60, "spread": 20, "bend": 90}),
            key(L * .75, {}, "out", root={"pitch": 345, "sink": .9, "z": -1.6}, Waist={"pitch": 20},
                LL={"foot": [-0.5, -1.5], "yaw": 5}, RL={"foot": [0.55, -1.1], "yaw": -5, "toe": -20},
                LA={"swing": 60, "spread": 30, "bend": 40}, RA={"swing": 40, "spread": 30, "bend": 40}),
            key(L, {}, "smooth", root={"pitch": 368, "sink": .3, "z": -1.6}, Waist={"pitch": 10},
                LL={"foot": [-0.5, -1.8], "yaw": 5}, RL={"foot": [0.55, -1.0], "yaw": -8, "toe": -25},
                LA={"swing": 50, "spread": 15, "bend": 70}, RA={"swing": -20, "spread": 15, "bend": 70})]
    return {"keys": keys, "length": L, "markers": {}}


def parkour_land_hard():
    """The three-point landing: knee, foot and fist, the other arm out; then up."""
    L = .8
    impact = {"root": {"pitch": 34, "sink": 1.15, "turn": -10}, "Waist": {"pitch": 18}, "Neck": {"pitch": -30},
              "LL": {"foot": [-0.55, -0.7], "yaw": 10}, "RL": {"foot": [0.6, 0.75], "yaw": -20, "toe": -40},
              "RA": {"hand": [0.45, -2.5, -1.2], "hint": [70, 15, 0, 5]}, "LA": {"swing": 40, "spread": 80, "bend": 20}}
    return {"keys": [key(0, impact, "out"), key(.08, merge(impact, {"root": {"sink": 1.25}}), "out"),
                     key(.45, impact, "smooth"),
                     key(L, STAND, "smooth", root={"sink": .2})], "length": L, "markers": {}}


def parkour_vault():
    """Over a ledge or a fence: the left hand on it, the legs swing through sideways."""
    L, a = .45, {"air": True}
    return {"keys": [
        key(0, {}, "out", **a, root={"pitch": 30, "lean": 10}, LA={"hand": [-0.4, -1.4, -1.3], "hint": [80, 10, 0, 10]},
            RA={"swing": 60, "spread": 50, "bend": 20}, LL={"swing": 60, "spread": 8, "bend": 90}, RL={"swing": 20, "spread": 8, "bend": 70}),
        key(L * .45, {}, "smooth", **a, root={"pitch": 10, "lean": 40, "turn": 20}, LA={"hand": [-1.2, -1.6, 0.0], "hint": [10, 30, 0, 10]},
            RA={"swing": 30, "spread": 80, "bend": 20}, LL={"swing": 70, "spread": 50, "bend": 20}, RL={"swing": 65, "spread": 50, "bend": 25}),
        key(L, {}, "smooth", **a, root={"pitch": 6, "lean": 4}, LA={"swing": 40, "spread": 40, "bend": 30},
            RA={"swing": 30, "spread": 40, "bend": 30}, LL={"swing": 40, "spread": 8, "bend": 60}, RL={"swing": 5, "spread": 8, "bend": 30})],
        "length": L, "markers": {}}


# (23/11, étape 4, DEV: « un vrai clip Parkour.WallRun serait mieux ; ajoute Parkour.Ledge ») The
# DEV's walker (Client/HubBody) leans the whole body 70 degrees off the wall, the feet on it: in the
# body's own frame this is a run, in the air (no floor under the feet), a long fast stride, knees
# high, the arms pumping hard, the head turned up the wall's length. Symmetric: either wall side.
def parkour_wall_run():
    L, a = .46, {"air": True}
    def stride(side):
        f = 1 if side == "L" else -1
        return {"root": {"pitch": 16, "lean": 0}, "Waist": {"pitch": 6, "turn": 6 * f}, "Neck": {"pitch": -12, "turn": -4 * f},
                "LL": {"swing": 80 if f > 0 else -40, "spread": 6, "bend": 100 if f > 0 else 35, "ankle": 10 if f > 0 else -30},
                "RL": {"swing": -40 if f > 0 else 80, "spread": 6, "bend": 35 if f > 0 else 100, "ankle": -30 if f > 0 else 10},
                "LA": {"swing": -50 if f > 0 else 75, "spread": 14, "bend": 85},
                "RA": {"swing": 75 if f > 0 else -50, "spread": 14, "bend": 85}}
    pass_ = {"root": {"pitch": 18}, "Waist": {"pitch": 6}, "Neck": {"pitch": -12},
             "LL": {"swing": 25, "spread": 6, "bend": 110}, "RL": {"swing": 25, "spread": 6, "bend": 110},
             "LA": {"swing": 10, "spread": 14, "bend": 90}, "RA": {"swing": 10, "spread": 14, "bend": 90}}
    return {"keys": [key(0, stride("L"), "smooth", **a), key(L * .25, pass_, "smooth", **a), key(L * .5, stride("R"), "smooth", **a),
                     key(L * .75, pass_, "smooth", **a), key(L, stride("L"), "smooth", **a)], "length": L, "markers": {}, "loop": True}


def parkour_ledge():
    """Hanging from a roof's edge by both hands, the body under them, the legs loose, a slow
    sway (a loop)."""
    L, a = 1.6, {"air": True}
    hang = {"root": {"pitch": -4}, "Waist": {"pitch": -2}, "Neck": {"pitch": -18},
            "LA": {"swing": 168, "spread": 18, "bend": 12}, "RA": {"swing": 168, "spread": 18, "bend": 12},
            "LL": {"swing": 12, "spread": 6, "bend": 25, "ankle": -20}, "RL": {"swing": -6, "spread": 6, "bend": 12, "ankle": -20}}
    sway = merge(hang, {"root": {"pitch": 4}, "LL": {"swing": -4, "bend": 15}, "RL": {"swing": 14, "bend": 30}})
    return {"keys": [key(0, hang, "smooth", **a), key(L * .5, sway, "smooth", **a), key(L, hang, "smooth", **a)],
            "length": L, "markers": {}, "loop": True}


def parkour_ledge_up():
    """Up from the hang: the pull, a knee over the edge, standing on the roof."""
    L, a = .55, {"air": True}
    return {"keys": [
        key(0, {}, "out", **a, root={"pitch": -4}, Neck={"pitch": -18},
            LA={"swing": 168, "spread": 18, "bend": 12}, RA={"swing": 168, "spread": 18, "bend": 12},
            LL={"swing": 12, "spread": 6, "bend": 25}, RL={"swing": -6, "spread": 6, "bend": 12}),
        key(L * .4, {}, "out", **a, root={"pitch": 25, "y": 1.4}, Waist={"pitch": 20}, Neck={"pitch": -10},
            LA={"hand": [-0.55, 0.9, -0.9], "hint": [60, 20, 0, 20]}, RA={"hand": [0.55, 0.9, -0.9], "hint": [60, 20, 0, 20]},
            LL={"swing": 95, "spread": 8, "bend": 120}, RL={"swing": 10, "spread": 6, "bend": 40}),
        key(L * .75, {}, "smooth", **a, root={"pitch": 20, "y": 2.4, "z": -0.6}, Waist={"pitch": 12},
            LA={"swing": 30, "spread": 20, "bend": 40}, RA={"swing": 20, "spread": 20, "bend": 40},
            LL={"swing": 50, "spread": 8, "bend": 70}, RL={"swing": 30, "spread": 8, "bend": 90}),
        key(L, {}, "smooth", **a, root={"pitch": 6, "y": 2.9, "z": -1.0}, Waist={"pitch": 4},
            LA={"swing": 15, "spread": 12, "bend": 25}, RA={"swing": 10, "spread": 12, "bend": 25},
            LL={"swing": 10, "spread": 6, "bend": 15}, RL={"swing": -5, "spread": 6, "bend": 10})],
        "length": L, "markers": {}}


# ------------------------------------------------------------------ the victory poses (shop)
def _pose(final, mid=None, L=2.5):
    """A victory: from a plain stance into the pose (with a beat on the way), held, breathing."""
    keys = [key(0, STAND, "out")]
    if mid:
        keys.append(key(.35, STAND, "out", **mid))
    keys += [key(.75, STAND, "out", **final), key(1.6, STAND, "smooth", **merge(final, {"Waist": {"pitch": (final.get("Waist") or {}).get("pitch", 0) + 2}})),
             key(L, STAND, "smooth", **final)]
    return {"keys": keys, "length": L, "markers": {}, "loop": False}


VICTORY = {
    # (id, name in the shop, the pose)
    "NiceGuy": ("NICE GUY", lambda: _pose(
        {"root": {"turn": 15}, "Neck": {"turn": -15, "pitch": -6}, "RL": {"foot": [0.75, -0.2], "yaw": -20},
         "RA": {"hand": [0.7, 1.4, -1.4], "hint": [90, 30, -60, 40], "wrist": {"twist": 90}},
         "LA": {"chest": [-1.2, -0.9, -0.1], "hint": [0, 40, 0, 120]}},
        {"RA": {"swing": -30, "spread": 20, "bend": 60}})),
    "CalmSeal": ("CALM SEAL", lambda: _pose(
        {"Neck": {"pitch": 4}, "RA": {"chest": [0.0, 0.9, -1.0], "hint": [80, 10, -30, 110], "wrist": {"swing": -20}},
         "LA": {"swing": 0, "spread": 6, "bend": 10}})),
    "TooEasy": ("TOO EASY", lambda: _pose(
        {"root": {"turn": -20, "lean": -6}, "Waist": {"pitch": -8, "lean": -4}, "Neck": {"turn": 30, "pitch": -10},
         "LL": {"foot": [-0.4, 0.2], "yaw": 25}, "RL": {"foot": [0.75, 0.0], "yaw": -20},
         "LA": {"chest": [-1.25, -1.2, 0.05], "hint": [-10, 20, 0, 50]}, "RA": {"chest": [1.25, -1.2, 0.05], "hint": [-10, 20, 0, 50]}})),
    "ToTheSky": ("TO THE SKY", lambda: _pose(
        {"root": {"sink": .15}, "Waist": {"pitch": -10}, "Neck": {"pitch": -25},
         "RA": {"swing": 175, "spread": 5, "bend": 5}, "LA": {"chest": [-1.0, -0.2, -0.9], "hint": [40, 20, 0, 110]}},
        {"RA": {"swing": 60, "spread": 20, "bend": 120}, "root": {"sink": .5}})),
    "Bow": ("THE BOW", lambda: _pose(
        {"root": {"pitch": 35}, "Waist": {"pitch": 15}, "Neck": {"pitch": 15},
         "LL": {"foot": [-0.35, 0.0], "yaw": 0}, "RL": {"foot": [0.35, 0.0], "yaw": 0},
         "RA": {"chest": [1.2, -1.3, -0.1], "hint": [5, 10, 0, 15]}, "LA": {"chest": [-1.2, -1.3, -0.1], "hint": [5, 10, 0, 15]}})),
    "NotTired": ("NOT EVEN TIRED", lambda: _pose(
        {"root": {"turn": 160}, "Waist": {"turn": 15}, "Neck": {"turn": 60, "pitch": -4},
         "LL": {"foot": [-0.5, 0.0], "yaw": 160}, "RL": {"foot": [0.5, 0.05], "yaw": 155},
         "RA": {"chest": [-0.55, 0.1, -0.85], "hint": [60, 20, -40, 130]}, "LA": {"chest": [0.55, 0.0, -0.8], "hint": [60, 20, 40, 130]}})),
    "StillHungry": ("STILL HUNGRY", lambda: _pose(
        {"root": {"pitch": 25, "sink": 1.25}, "Waist": {"pitch": 14}, "Neck": {"pitch": -24},
         "LL": {"foot": [-0.7, -0.5], "yaw": 10}, "RL": {"foot": [0.6, 0.55], "yaw": -15, "toe": -35},
         "LA": {"hand": [-0.6, -2.55, -1.3], "hint": [70, 20, 0, 10]}, "RA": {"swing": 20, "spread": 40, "bend": 30}})),
    "KunaiTwirl": ("KUNAI TWIRL", lambda: _pose(
        {"root": {"turn": 10}, "Neck": {"pitch": 10, "turn": -10},
         "RA": {"chest": [0.6, 0.3, -1.2], "hint": [70, 20, -20, 100], "wrist": {"swing": -40}},
         "LA": {"chest": [-1.2, -0.9, -0.1], "hint": [0, 40, 0, 120]}},
        {"RA": {"chest": [0.9, 0.9, -1.0], "hint": [100, 30, -20, 80], "wrist": {"swing": 40}}})),
}


# ------------------------------------------------------------------ the emotes (Konoha, loops)
def _loop(a, b, L):
    """A loop between two poses (back where it started)."""
    return {"keys": [key(0, STAND, "smooth", **a), key(L / 2, STAND, "smooth", **b), key(L, STAND, "smooth", **a)],
            "length": L, "markers": {}, "loop": True}


EMOTES = {
    "Wave": ("WAVE", lambda: _loop({"RA": {"swing": 125, "spread": 70, "bend": 30}, "Neck": {"turn": -6}},
                                   {"RA": {"swing": 125, "spread": 45, "bend": 55}, "Neck": {"turn": 6}}, 1.0)),
    "Meditate": ("MEDITATE", lambda: _loop(
        {"root": {"y": -1.7}, "air": True, "LL": {"swing": 70, "spread": 60, "twist": -50, "bend": 140},
         "RL": {"swing": 70, "spread": 60, "twist": 50, "bend": 140},
         "LA": {"chest": [-0.15, -1.1, -0.9], "hint": [30, 10, 30, 100]}, "RA": {"chest": [0.15, -1.1, -0.9], "hint": [30, 10, -30, 100]}},
        {"root": {"y": -1.68}, "air": True, "Waist": {"pitch": -3}, "LL": {"swing": 70, "spread": 60, "twist": -50, "bend": 140},
         "RL": {"swing": 70, "spread": 60, "twist": 50, "bend": 140},
         "LA": {"chest": [-0.15, -1.05, -0.92], "hint": [30, 10, 30, 100]}, "RA": {"chest": [0.15, -1.05, -0.92], "hint": [30, 10, -30, 100]}}, 3.0)),
    "PushUps": ("PUSH-UPS", lambda: _loop(
        {"root": {"pitch": 88, "y": -1.4}, "air": True, "Neck": {"pitch": -40},
         "LL": {"swing": 0, "spread": 4, "bend": 0, "ankle": -60}, "RL": {"swing": 0, "spread": 4, "bend": 0, "ankle": -60},
         "LA": {"hand": [-0.85, -2.75, -1.2], "hint": [90, 10, 0, 5]}, "RA": {"swing": -20, "spread": 10, "bend": 90}},
        {"root": {"pitch": 88, "y": -1.75}, "air": True, "Neck": {"pitch": -40},
         "LL": {"swing": 0, "spread": 4, "bend": 0, "ankle": -60}, "RL": {"swing": 0, "spread": 4, "bend": 0, "ankle": -60},
         "LA": {"hand": [-0.85, -2.75, -1.2], "hint": [60, 40, 0, 90]}, "RA": {"swing": -20, "spread": 10, "bend": 90}}, 1.1)),
    "Laugh": ("LAUGH", lambda: _loop({"root": {"pitch": -6}, "Waist": {"pitch": -10}, "Neck": {"pitch": -20},
                                      "LA": {"chest": [-0.5, -0.6, -0.9], "hint": [30, 20, 0, 110]}, "RA": {"chest": [0.6, -0.4, -0.9], "hint": [30, 20, 0, 110]}},
                                     {"root": {"pitch": 6}, "Waist": {"pitch": 14}, "Neck": {"pitch": 10},
                                      "LA": {"chest": [-0.5, -0.8, -0.8], "hint": [30, 20, 0, 110]}, "RA": {"chest": [0.6, -0.6, -0.8], "hint": [30, 20, 0, 110]}}, .8)),
    "Stretch": ("STRETCH", lambda: _loop({"Waist": {"lean": 18}, "RA": {"swing": 170, "spread": -10, "bend": 10}, "LA": {"chest": [-1.2, -0.6, -0.2], "hint": [0, 40, 0, 90]}},
                                         {"Waist": {"lean": -18}, "LA": {"swing": 170, "spread": -10, "bend": 10}, "RA": {"chest": [1.2, -0.6, -0.2], "hint": [0, 40, 0, 90]}}, 2.4)),
    "HandSeals": ("HAND SEALS", lambda: _loop({"Neck": {"pitch": 10}, "LA": {"chest": [-0.12, 0.2, -1.0], "hint": [70, 10, 30, 120]},
                                               "RA": {"chest": [0.12, 0.25, -1.0], "hint": [70, 10, -30, 120]}},
                                              {"Neck": {"pitch": 12}, "LA": {"chest": [-0.1, 0.45, -1.05], "hint": [80, 10, 50, 110]},
                                               "RA": {"chest": [0.1, 0.0, -1.0], "hint": [60, 10, -50, 125]}}, .6)),
}


def all_specs(clips):
    out = {}
    for kit in KITS:
        out[kit + ".Getup.Quick"] = getup_quick(kit, clips)
        out[kit + ".AirJump"] = air_jump(kit)
    out["Lion.Parkour.Leap"] = parkour_leap()
    out["Lion.Parkour.LandRoll"] = parkour_land_roll()
    out["Lion.Parkour.LandHard"] = parkour_land_hard()
    out["Lion.Parkour.Vault"] = parkour_vault()
    out["Lion.Parkour.WallRun"] = parkour_wall_run()
    out["Lion.Parkour.Ledge"] = parkour_ledge()
    out["Lion.Parkour.LedgeUp"] = parkour_ledge_up()
    for vid, (_, fn) in VICTORY.items():
        out["Victory." + vid] = fn()
    for eid, (_, fn) in EMOTES.items():
        out["Emote." + eid] = fn()
    return out


def main(clips_path, out_dir, write=False):
    clips = json.load(open(clips_path))
    os.makedirs(out_dir, exist_ok=True)
    built, rows = {}, []
    for name, spec in all_specs(clips).items():
        clip, errs = SA.make_clip(dict(spec), None)
        clip["markers"] = dict(spec.get("markers") or {})
        g = SA.grade(name, clip)
        times = sorted({round(k["t"], 4) for k in spec["keys"]})
        SA.sheet(clip, os.path.join(out_dir, "sheet_%s.png" % name), "%s  %.1f" % (name, g["score"]), times)
        rows.append({"name": name, "score": g["score"], "why": g["why"]})
        print("%-26s %4.1f  %s" % (name, g["score"], " ; ".join(g["why"])[:140]))
        built[name] = clip
    json.dump(rows, open(os.path.join(out_dir, "grades.json"), "w"), indent=1, ensure_ascii=False)
    if write:
        base = os.path.join(HERE, "..", "..", "src", "Client")
        names, chunks, cur, size = sorted(built), [], {}, 0
        for n in names:
            text = SA.to_luau({n: built[n]}, "")
            if cur and size + len(text) > 170000:
                chunks.append(cur); cur, size = {}, 0
            cur[n] = built[n]; size += len(text)
        chunks.append(cur)
        for i, part in enumerate(chunks):
            path = os.path.join(base, "AuthoredJutsu%d.luau" % (9 + i))
            open(path, "w").write(SA.to_luau(part, "étape 3: parkour, second jump, quick rise, victory poses, emotes, tools/blender/e3_clips.py"))
            print("wrote", os.path.basename(path), len(part))


if __name__ == "__main__":
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    main(a[0], a[1], "--write" in sys.argv)
