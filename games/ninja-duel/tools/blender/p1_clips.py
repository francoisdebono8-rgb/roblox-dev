#!/usr/bin/env python3
"""Passe commune 1 (DEC-051), ANIMATEUR: the rogue ninjas' clips (Server/Thugs; played on this
client by Client/KonohaRogueFX on their own dressed rig), on the duel's skeleton (syph_author).

    python3 tools/blender/p1_clips.py OUT_DIR [--write]
      --write: src/Client/AuthoredJutsu20.luau (a layer of its own, listed in AuthoredJutsu.luau)

  Rogue.Idle     loop: he loiters by the duel place, arms crossed, weight on one leg, looking about
  Rogue.Racket   loop: he blocks the way, leans in, one hand out for the Ryō, the other a fist
  Rogue.Taunt    once: he cracks his knuckles and beckons (the racket turns into a fight)
  Rogue.Leave    once: paid or beaten, a crouch and a leap back and away (the client puffs him out)

  Copycat.Raikiri  (DEC-048, RAIKIRI: TRACKED) the Lightning Blade sent at the dogs' mark: a body
                   almost flat over a long low stride, the blade arm driven straight through,
                   the other arm thrown back (its effect: Client/LightningFX, raikiri_trail)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import syph_author as SA  # noqa: E402
from e2_strikes import key, merge  # noqa: E402
from e3_clips import STAND  # noqa: E402

CROSS = {"LA": {"chest": [0.45, -0.35, -0.8], "hint": [40, 30, 20, 120]},
         "RA": {"chest": [-0.45, -0.25, -0.85], "hint": [40, 30, -20, 120]}}
LEAN = {"root": {"turn": 12, "lean": 3, "sink": .1}, "LL": {"foot": [-0.6, 0.05], "yaw": 14},
        "RL": {"foot": [0.5, -0.1], "yaw": -18}}


def rogue_idle():
    L = 2.8
    a = merge(merge(LEAN, CROSS), {"Neck": {"turn": -25, "pitch": 4}, "Waist": {"lean": -3}})
    b = merge(merge(LEAN, CROSS), {"Neck": {"turn": 20, "pitch": -2}, "Waist": {"lean": 2}, "root": {"turn": 8, "lean": 1, "sink": .12}})
    return {"keys": [key(0, STAND, "smooth", **a), key(L / 2, STAND, "smooth", **b), key(L, STAND, "smooth", **a)],
            "length": L, "markers": {}, "loop": True}


def rogue_racket():
    L = 1.2
    base = {"root": {"pitch": 8, "sink": .2}, "Waist": {"pitch": 6}, "Neck": {"pitch": -12},
            "LL": {"foot": [-0.6, 0.25], "yaw": 10}, "RL": {"foot": [0.55, -0.3], "yaw": -12},
            "LA": {"chest": [-1.15, -1.15, -0.05], "hint": [-10, 20, 0, 50]}}
    a = merge(base, {"RA": {"hand": [0.45, 0.55, -1.75], "hint": [80, 20, -20, 30], "wrist": {"twist": 90, "swing": 10}}})
    b = merge(base, {"Neck": {"pitch": -6}, "RA": {"hand": [0.45, 0.62, -1.6], "hint": [80, 20, -20, 45], "wrist": {"twist": 90, "swing": -35}}})
    return {"keys": [key(0, STAND, "smooth", **a), key(L / 2, STAND, "smooth", **b), key(L, STAND, "smooth", **a)],
            "length": L, "markers": {}, "loop": True}


def rogue_taunt():
    L = 1.1
    crack = {"root": {"sink": .15}, "Neck": {"pitch": 6},
             "LA": {"chest": [-0.08, -0.2, -1.0], "hint": [60, 20, 30, 110]}, "RA": {"chest": [0.08, -0.15, -1.0], "hint": [60, 20, -30, 110]}}
    crack2 = merge(crack, {"LA": {"chest": [-0.1, -0.25, -0.95], "hint": [60, 20, 40, 120], "wrist": {"swing": 40}},
                           "RA": {"chest": [0.1, -0.2, -0.95], "hint": [60, 20, -40, 120], "wrist": {"swing": -40}}})
    guard = {"root": {"sink": .7, "turn": -20, "pitch": 6}, "Waist": {"turn": 10}, "Neck": {"turn": 15, "pitch": -4},
             "LL": {"foot": [-0.75, -0.45], "yaw": 25}, "RL": {"foot": [0.7, 0.5], "yaw": -10},
             "LA": {"chest": [-0.3, 0.1, -1.1], "hint": [70, 20, 20, 100]}}
    beckon = merge(guard, {"RA": {"hand": [0.6, 0.9, -1.5], "hint": [80, 30, -20, 40], "wrist": {"twist": 90, "swing": 30}}})
    beckon2 = merge(guard, {"RA": {"hand": [0.6, 0.95, -1.4], "hint": [80, 30, -20, 60], "wrist": {"twist": 90, "swing": -50}}})
    return {"keys": [key(0, STAND, "out"), key(.2, STAND, "smooth", **crack), key(.38, STAND, "out", **crack2),
                     key(.62, STAND, "out", **beckon), key(.82, STAND, "smooth", **beckon2), key(L, STAND, "smooth", **beckon)],
            "length": L, "markers": {}, "loop": False}


def rogue_leave():
    L = .9
    crouch = {"root": {"sink": 1.0, "pitch": 12}, "Waist": {"pitch": 10}, "Neck": {"pitch": -10},
              "LL": {"foot": [-0.6, 0.1], "yaw": 8}, "RL": {"foot": [0.6, 0.1], "yaw": -8},
              "LA": {"swing": -40, "spread": 20, "bend": 30}, "RA": {"swing": -40, "spread": 20, "bend": 30}}
    tuck = {"air": True, "root": {"y": 3.0, "z": 3.0, "pitch": -40}, "Waist": {"pitch": -10}, "Neck": {"pitch": 10},
            "LL": {"swing": 80, "spread": 10, "bend": 120}, "RL": {"swing": 70, "spread": 10, "bend": 110},
            "LA": {"swing": 120, "spread": 30, "bend": 40}, "RA": {"swing": 120, "spread": 30, "bend": 40}}
    away = {"air": True, "root": {"y": 4.6, "z": 6.5, "pitch": -110}, "Waist": {"pitch": -14}, "Neck": {"pitch": 18},
            "LL": {"swing": 90, "spread": 10, "bend": 130}, "RL": {"swing": 85, "spread": 10, "bend": 125},
            "LA": {"swing": 60, "spread": 40, "bend": 80}, "RA": {"swing": 60, "spread": 40, "bend": 80}}
    return {"keys": [key(0, STAND, "out"), key(.22, STAND, "out", **crouch), key(.55, STAND, "smooth", **tuck),
                     key(L, STAND, "smooth", **away)], "length": L, "markers": {"puff": .6}, "loop": False}


def copycat_raikiri():
    """On Kakashi's guard (e4_strikes.GUARD4), the e2 contract: guard -> wind -> contact -> through -> guard."""
    import e4_strikes  # noqa: F401  (merges Kakashi's guard into GUARD)
    from e2_strikes import blow
    old = {"markers": {"contact": .12, "recover": .36}, "length": .62}
    spec = blow("Copycat", old,
                antic={"root": {"turn": 35, "sink": .55, "z": 0.25}, "Waist": {"turn": 8}, "Neck": {"turn": -30},
                       "RA": {"chest": [0.9, -0.45, 0.25], "hint": [20, 40, 0, 110], "wrist": {"swing": -30}},
                       "LA": {"chest": [-0.55, 0.1, -1.0], "hint": [50, 20, 10, 100]}},
                hit={"root": {"turn": -15, "z": -0.6, "sink": .6, "pitch": 14}, "Waist": {"turn": -8, "pitch": 8}, "Neck": {"pitch": -12, "turn": 12},
                     "RA": {"hand": [0.35, 0.6, -2.7], "hint": [92, 8, 0, 6]},
                     "LA": {"swing": -50, "spread": 25, "bend": 25}},
                through={"root": {"turn": -12, "z": -0.75, "sink": .62, "pitch": 15}, "Waist": {"turn": -8, "pitch": 8}, "Neck": {"pitch": -12, "turn": 12},
                         "RA": {"hand": [0.33, 0.62, -2.85], "hint": [92, 8, 0, 3]},
                         "LA": {"swing": -55, "spread": 25, "bend": 25}},
                back={"root": {"turn": 0, "z": -0.3, "sink": .45}},
                antic_at=.5, through_dt=.1)
    spec["markers"] = dict(old["markers"])
    spec["length"] = old["length"]
    spec["loop"] = False
    return spec


def all_specs():
    return {"Rogue.Idle": rogue_idle(), "Rogue.Racket": rogue_racket(), "Rogue.Taunt": rogue_taunt(), "Rogue.Leave": rogue_leave(),
            "Copycat.Raikiri": copycat_raikiri()}


def main(out_dir, write=False):
    os.makedirs(out_dir, exist_ok=True)
    built, rows = {}, []
    for name, spec in all_specs().items():
        clip, errs = SA.make_clip(dict(spec), None)
        clip["markers"] = dict(spec.get("markers") or {})
        g = SA.grade(name, clip)
        times = sorted({round(k["t"], 4) for k in spec["keys"]})
        SA.sheet(clip, os.path.join(out_dir, "sheet_%s.png" % name), "%s  %.1f" % (name, g["score"]), times)
        rows.append({"name": name, "score": g["score"], "why": g["why"]})
        print("%-16s %4.1f  %s" % (name, g["score"], " ; ".join(g["why"])[:160]), flush=True)
        built[name] = clip
    json.dump(rows, open(os.path.join(out_dir, "grades.json"), "w"), indent=1, ensure_ascii=False)
    if write:
        path = os.path.join(HERE, "..", "..", "src", "Client", "AuthoredJutsu20.luau")
        open(path, "w").write(SA.to_luau(built, "passe commune 1: the rogue ninjas, tools/blender/p1_clips.py"))
        print("wrote AuthoredJutsu20", len(built))


if __name__ == "__main__":
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    main(a[0], "--write" in sys.argv)
