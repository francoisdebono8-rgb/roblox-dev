# É9 (03/11): Grab, Throw, ThrowUp for the eight and the salto heel kick
# (AirFlip) for the six who drew it procedurally (common_e9). Export
# clips_<F>_common.json + contact sheets.
import bpy, os, sys, importlib
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
import nd_rig, nd_anim, nd_ctrl, nd_shot, nd_io, common_e9
import clips_lion2, clips_flash2, itachi_p3, naruto_p5, kakashi_p6, gaara_p7, lee_p8, neji_p9
importlib.reload(common_e9)
from mathutils import Vector
S = bpy.context.scene
folder = os.path.join(OUT, "common8"); os.makedirs(folder, exist_ok=True)
FIGHTERS = (
    ("Sasuke", "Lion", clips_lion2.STANCE, None),          # his AirFlip exists
    ("Minato", "Flashstep", clips_flash2.STANCE, clips_flash2.AIR),
    ("Itachi", "Mirage", itachi_p3.STANCE, itachi_p3.AIR),
    ("Naruto", "Legion", naruto_p5.STANCE, naruto_p5.AIR),
    ("Kakashi", "Copycat", kakashi_p6.STANCE, kakashi_p6.AIR),
    ("Gaara", "Sand", gaara_p7.STANCE, None),               # his air heavy is the Slam
    ("Lee", "Leaf", lee_p8.STANCE, lee_p8.AIR),
    ("Neji", "GentleFist", neji_p9.STANCE, neji_p9.AIR),
)
def sheet(arm, act):
    nd_anim.use(arm, act)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    step = max(2, (end - start) // 7)
    cam = bpy.data.objects["PreviewCam"]
    paths = []
    for i, f in enumerate(range(start, end + 1, step)):
        S.frame_set(f)
        root = arm.matrix_world @ arm.pose.bones["root"].matrix.translation
        tgt = Vector((root.x, root.y, 2.6)); cam.location = tgt + Vector((7.0, -8.0, 2.4))
        cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
        p = os.path.join(folder, "%s_%03d.png" % (act.name, i)); S.render.filepath = p
        bpy.ops.render.render(write_still=True); paths.append(p)
    nd_io.sheet(paths, os.path.join(OUT, "sheet_common_%s.png" % act.name), 8, 180)
for name, fid, stance, air in FIGHTERS:
    nd_rig.clear_scene(); S.render.fps = 60
    arm = nd_ctrl.build(name, fid)
    acts = common_e9.author(arm, fid, stance, air, flip=air is not None)
    for act in acts:
        if "AirFlip" not in act.name:
            rep = nd_shot.check(arm, act)
            print("CHECK %-24s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    data = nd_shot.export(arm, acts, os.path.join(OUT, "clips_%s_common.json" % fid))
    print("exported", fid, {k: (v["frames"], v["markers"]) for k, v in data.items()})
    nd_shot.stage(300)
    S.render.resolution_x = 220; S.render.resolution_y = 260
    bpy.data.objects["PreviewCam"].data.lens = 30
    for act in acts: sheet(arm, act)
print("done")
