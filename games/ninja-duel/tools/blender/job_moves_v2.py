"""Moveset pass v2 (06/11, user: « vérifie les poses de saut, les impacts des
gros coups, même les attaques que tu crois bonnes »): every strike, air
attack, jump and landing of the beta's eight fighters re-authored, one module
per fighter (moves_v2_<name>.py: author(arm) -> actions), from Mixamo
captures (nd_mocap, job_mocap_strikes' timing warp) and key poses, checked
and exported to exports/clips_<fid>_moves2.json.

  ND_ONLY=Mirage python3 job_moves_v2.py
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
FIGHTERS = (("Sasuke", "Lion", "moves_v2_sasuke"), ("Naruto", "Legion", "moves_v2_naruto"), ("Gaara", "Sand", "moves_v2_gaara"),
            ("Lee", "Leaf", "moves_v2_lee"), ("Neji", "GentleFist", "moves_v2_neji"), ("Itachi", "Mirage", "moves_v2_itachi"),
            ("Kakashi", "Copycat", "moves_v2_kakashi"), ("Minato", "Flashstep", "moves_v2_minato"))

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
    path = os.path.join(EXPORTS, "clips_%s_moves2.json" % fid)
    data = nd_shot.export(arm, acts, path)
    print("exported", fid, len(data), "clips ->", path)
print("done")
