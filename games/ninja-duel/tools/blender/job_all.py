# Build each fighter's rig, author its clips, export, save its .blend and
# render contact sheets (front34 + game camera).
import bpy, importlib, os, sys, math
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
import nd_rig, nd_anim, nd_io
ONLY = os.environ.get("ND_ONLY", "")
RENDER = os.environ.get("ND_RENDER", "1") == "1"
for name, fighter, module in (("Sasuke", "Lion", "clips_sasuke"), ("Minato", "Flashstep", "clips_minato")):
    if ONLY and ONLY != fighter:
        continue
    mod = importlib.import_module(module)
    nd_rig.clear_scene()
    bpy.context.scene.render.fps = nd_anim.FPS
    arm = nd_rig.build_rig(name, fighter)
    dummy = nd_rig.build_rig("Dummy", "Dummy", offset=(0, 4.4, 0))
    dummy.rotation_euler = (0, 0, math.pi)
    acts = mod.author(arm)
    data = nd_io.export(arm, acts, os.path.join(OUT, "clips_%s.json" % fighter))
    print(fighter, {k: v["frames"] for k, v in data.items()})
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "NinjaDuel_%s.blend" % name))
    if not RENDER:
        continue
    os.makedirs(os.path.join(OUT, "sheets"), exist_ok=True)
    for act in acts:
        if act.name.endswith(".Idle"):
            continue
        for view in ("front34", "game"):
            frames = nd_io.render(arm, act, os.path.join(OUT, "frames"), view, 3)
            nd_io.sheet(frames, os.path.join(OUT, "sheets", "%s_%s.png" % (act.name, view)), 6, 240)
print("done")
