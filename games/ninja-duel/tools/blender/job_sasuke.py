# Build the rig, author Sasuke's clips, save the .blend, export, render previews.
import bpy, importlib, os, sys, math, json
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
for m in ("nd_rig", "nd_anim", "nd_io", "clips_sasuke"):
    if m in sys.modules:
        importlib.reload(sys.modules[m])
import nd_rig, nd_anim, nd_io, clips_sasuke
nd_rig.clear_scene()
bpy.context.scene.render.fps = nd_anim.FPS
arm = nd_rig.build_rig("Sasuke", "Lion")
print("frames", nd_rig.check_frames(arm))
dummy = nd_rig.build_rig("Dummy", "Dummy", offset=(0, 4.4, 0))
dummy.rotation_euler = (0, 0, math.pi)
acts = clips_sasuke.author(arm)
data = nd_io.export(arm, acts, os.path.join(OUT, "clips_sasuke.json"))
print("exported", {k: v["frames"] for k, v in data.items()})
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "NinjaDuel_Sasuke.blend"))
os.makedirs(os.path.join(OUT, "sheets"), exist_ok=True)
for act in acts:
    if act.name == "Lion.Idle":
        continue
    for view in ("side", "game"):
        frames = nd_io.render(arm, act, os.path.join(OUT, "frames"), view, 3)
        nd_io.sheet(frames, os.path.join(OUT, "sheets", "%s_%s.png" % (act.name, view)), 6, 240)
print("done")
