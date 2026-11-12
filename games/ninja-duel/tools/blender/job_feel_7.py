# Feel audit 07/11, the animator's part (12/11): reactions by the side of the
# blow, guard chassé steps and skid, strike pivots, relocation arrivals, for
# the eight beta fighters (clips_feel). Export clips_<F>_feel.json; contact
# sheets of the new reactions. Each fighter keeps his react2 tempo and give.
import bpy, os, sys, importlib
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
import nd_rig, nd_anim, nd_ctrl, nd_shot, nd_io, clips_feel
import clips_lion2, clips_flash2, itachi_p3, naruto_p5, kakashi_p6, gaara_p7, lee_p8, neji_p9
importlib.reload(clips_feel)
from mathutils import Vector
S = bpy.context.scene
folder = os.path.join(OUT, "feel7"); os.makedirs(folder, exist_ok=True)
NEJI_BLOCK = {"la": {"raise": 92, "out": -8, "twist": -40, "elbow": 52, "wrist": -30},
              "ra": {"raise": 112, "out": -16, "twist": -40, "elbow": 100, "wrist": -30}}
GAARA_BLOCK = {"ra": gaara_p7.FOLD_R, "la": gaara_p7.FOLD_L}
FIGHTERS = (
    ("Sasuke", "Lion", clips_lion2.STANCE, 1.0, 1.0, None),
    ("Minato", "Flashstep", clips_flash2.STANCE, .82, .85, None),
    ("Itachi", "Mirage", itachi_p3.STANCE, .88, 1.1, None),
    ("Naruto", "Legion", naruto_p5.STANCE, 1.05, 1.2, None),
    ("Kakashi", "Copycat", kakashi_p6.STANCE, .9, 1.1, None),
    ("Gaara", "Sand", gaara_p7.STANCE, 1.1, 1.0, GAARA_BLOCK),
    ("Lee", "Leaf", lee_p8.STANCE, .8, 1.15, None),
    ("Neji", "GentleFist", neji_p9.STANCE, .85, 1.1, NEJI_BLOCK),
)
AIR = ("Knockback", "Launched")
SHEET = ("Knockback.Back", "Knockback.Side", "Launched.Back", "Launched.Side", "Grabbed", "Grabbed.Back", "Grabbed.Side",
         "Guard.Step.B", "Guard.Step.L", "Guard.Skid", "Pivot.R180", "LightningStrike.Arrive", "LightningCut.Arrive")
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
    nd_io.sheet(paths, os.path.join(OUT, "sheet_feel_%s.png" % act.name), 8, 180)
only = os.environ.get("ND_ONLY")
sheets = os.environ.get("ND_SHEETS", "1") == "1"
for name, fid, stance, tempo, give, block in FIGHTERS:
    if only and fid not in only.split(","):
        continue
    nd_rig.clear_scene(); S.render.fps = 60
    arm = nd_ctrl.build(name, fid)
    acts = clips_feel.author(arm, fid, stance, tempo, give, block)
    for act in acts:
        if not any(a in act.name for a in AIR):
            rep = nd_shot.check(arm, act)
            print("CHECK %-34s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    data = nd_shot.export(arm, acts, os.path.join(OUT, "clips_%s_feel.json" % fid))
    print("exported", fid, len(data))
    if sheets:
        nd_shot.stage(300)
        S.render.resolution_x = 220; S.render.resolution_y = 260
        bpy.data.objects["PreviewCam"].data.lens = 30
        for act in acts:
            if any(act.name.endswith(n) for n in SHEET):
                sheet(arm, act)
print("done")
