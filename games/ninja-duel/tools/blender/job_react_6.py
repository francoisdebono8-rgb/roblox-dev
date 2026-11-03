# É8/É9 (03/11): the defence, reactions, dodges and chase of the six fighters
# who still had procedural ones (only Sasuke and Minato had them authored):
# Itachi, Naruto, Kakashi, Gaara, Lee, Neji. Same pose-first set as ANIM-005
# (clips_react2), each on its own stance, with its own tempo and, for
# Gaara and Neji, its own block. Export clips_<F>_react2.json + contact sheets.
import bpy, os, sys, importlib
ROOT = os.environ['ND_ROOT']; OUT = os.environ['ND_OUT']; LIB = os.environ['ND_LIB']
if LIB not in sys.path: sys.path.insert(0, LIB)
import nd_rig, nd_anim, nd_ctrl, nd_shot, nd_io, clips_react2
import itachi_p3, naruto_p5, kakashi_p6, gaara_p7, lee_p8, neji_p9
importlib.reload(clips_react2)
from mathutils import Vector
S = bpy.context.scene
folder = os.path.join(OUT, "react6"); os.makedirs(folder, exist_ok=True)
AIR = ("Knockback", "Launched", "Knockdown", "Down", "Getup", "Cartwheel", "Handspring", "Chase", "Dash")
# Neji blocks with his palms up before the face (Gentle Fist deflects);
# Gaara keeps his arms folded (the sand takes the blow).
NEJI_BLOCK = {"la": {"raise": 92, "out": -8, "twist": -40, "elbow": 52, "wrist": -30},
              "ra": {"raise": 112, "out": -16, "twist": -40, "elbow": 100, "wrist": -30}}
GAARA_BLOCK = {"ra": gaara_p7.FOLD_R, "la": gaara_p7.FOLD_L}
FIGHTERS = (
    # name, fighter id, stance module, tempo (lower: quicker), give (amplitude), block
    # (gives: a light blow plays ~55 % of the clip; CombatFeel wants a jab to
    # fold the body > 24 degrees at game speed: the first pass at .55-.9 read 9-19)
    ("Itachi", "Mirage", itachi_p3, .88, 1.1, None),      # composed: back at once (a jab still reads: CombatFeel)
    ("Naruto", "Legion", naruto_p5, 1.05, 1.2, None),     # takes it big, bounces back
    ("Kakashi", "Copycat", kakashi_p6, .9, 1.1, None),    # economical, quick
    ("Gaara", "Sand", gaara_p7, 1.1, 1.0, GAARA_BLOCK),   # the armour: slow to give, slow back
    ("Lee", "Leaf", lee_p8, .8, 1.15, None),              # springs back fastest
    ("Neji", "GentleFist", neji_p9, .85, 1.1, NEJI_BLOCK),
)
SHEET = ("Guard", "Guard.Impact", "Hit.Head", "Hit.Body", "Knockdown", "Getup", "Dash.F", "Chase")
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
    nd_io.sheet(paths, os.path.join(OUT, "sheet_react_%s.png" % act.name), 8, 180)
only = os.environ.get("ND_ONLY")
for name, fid, mod, tempo, give, block in FIGHTERS:
    if only and fid != only:
        continue
    nd_rig.clear_scene(); S.render.fps = 60
    arm = nd_ctrl.build(name, fid)
    acts = clips_react2.author(arm, fid, mod.STANCE, tempo, give, block)
    for act in acts:
        if not any(a in act.name for a in AIR):
            rep = nd_shot.check(arm, act)
            print("CHECK %-28s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    data = nd_shot.export(arm, acts, os.path.join(OUT, "clips_%s_react2.json" % fid))
    print("exported", fid, len(data), {k: v["frames"] for k, v in data.items()})
    nd_shot.stage(300)
    S.render.resolution_x = 220; S.render.resolution_y = 260
    bpy.data.objects["PreviewCam"].data.lens = 30
    for act in acts:
        if any(act.name == fid + "." + n for n in SHEET):
            sheet(arm, act)
print("done")
