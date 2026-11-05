"""Jutsu pass v2 (05/11, user: « inspecte toutes les animations de jutsus et
refais-les toutes avec les nouveaux outils »): every jutsu clip of the beta's
eight fighters re-authored, one module per fighter (jutsu_v2_<name>.py:
author(arm) -> actions), from Mixamo captures retargeted onto our rig
(nd_mocap) and key poses (nd_shot / jutsu_sasuke helpers), checked (feet,
balance) and exported to exports/clips_<fid>_jutsu2.json. The game reads them
through src/Client/AuthoredJutsu*.luau (clips_to_luau.py, laid last so they
replace the earlier clips of the same name).

  ND_ONLY=Mirage python3 job_jutsu_v2.py
"""
import bpy, os, sys, importlib
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import nd_rig, nd_ctrl, nd_shot

EXPORTS = os.path.join(HERE, "exports")
os.makedirs(EXPORTS, exist_ok=True)
ONLY = [f for f in os.environ.get("ND_ONLY", "").split(",") if f]
S = bpy.context.scene
FIGHTERS = (("Sasuke", "Lion", "jutsu_v2_sasuke"), ("Naruto", "Legion", "jutsu_v2_naruto"), ("Gaara", "Sand", "jutsu_v2_gaara"),
            ("Lee", "Leaf", "jutsu_v2_lee"), ("Neji", "GentleFist", "jutsu_v2_neji"), ("Itachi", "Mirage", "jutsu_v2_itachi"),
            ("Kakashi", "Copycat", "jutsu_v2_kakashi"), ("Minato", "Flashstep", "jutsu_v2_minato"))

for name, fid, module in FIGHTERS:
    if ONLY and fid not in ONLY:
        continue
    try:
        mod = importlib.import_module(module)
    except ImportError as e:
        print("skip", fid, e)
        continue
    importlib.reload(mod)
    nd_rig.clear_scene()
    S.render.fps = 60
    arm = nd_ctrl.build(name, fid)
    acts = mod.author(arm)
    for act in acts:
        rep = nd_shot.check(arm, act)
        print("CHECK %-36s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    path = os.path.join(EXPORTS, "clips_%s_jutsu2.json" % fid)
    data = nd_shot.export(arm, acts, path)
    print("exported", fid, len(data), "clips ->", path)
print("done")
