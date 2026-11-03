# É8/É9 (03/11): the jump flip (F.Flip, the tuck the engine turns over) for the
# four fighters whose body flips (Motion ACRO >= TRICK_AT.back) and still drew
# it procedurally: Lee, Naruto, Kakashi, Neji. Same shape as Sasuke's and
# Minato's (clips_loco.flip_keys on the FK rig).
import bpy, os, sys, importlib
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
import nd_rig, nd_anim, nd_io, clips_loco
for name, fid in (("Lee", "Leaf"), ("Naruto", "Legion"), ("Kakashi", "Copycat"), ("Neji", "GentleFist")):
    nd_rig.clear_scene()
    bpy.context.scene.render.fps = nd_anim.FPS
    arm = nd_rig.build_rig(name, fid)
    act = clips_loco.arc(arm, fid + ".Flip", clips_loco.flip_keys(), 36)
    data = nd_io.export(arm, [act], os.path.join(OUT, "clips_%s_flip.json" % fid))
    print("exported", fid, {k: v["frames"] for k, v in data.items()})
print("done")
