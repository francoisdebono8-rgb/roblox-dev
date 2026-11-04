"""The seal jutsu, the strings' middle hits and the reworked clips (04/11).

Builds each fighter's control rig, authors its clips (jutsu_<fighter>.py
modules: author(arm) -> actions), checks them (feet, balance), exports
tools/blender/exports/clips_<Fighter>_jutsu.json and renders a review sheet
per clip. The game reads the exports through src/Client/AuthoredJutsu*.luau
(clips_to_luau.py), merged over AuthoredClips (Client/AuthoredMotion).

Runs anywhere bpy runs: Blender (blender -b --python job_jutsu.py) or the bpy
module (python job_jutsu.py).
  ND_ONLY=Flashstep,Lion   only these fighters
  ND_REVIEW=<folder>       where the review sheets go (default: none)
"""
import bpy, os, sys, json, importlib, math
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import nd_rig, nd_anim, nd_ctrl, nd_shot, nd_io
from mathutils import Vector

EXPORTS = os.path.join(HERE, "exports")
os.makedirs(EXPORTS, exist_ok=True)
ONLY = [f for f in os.environ.get("ND_ONLY", "").split(",") if f]
REVIEW = os.environ.get("ND_REVIEW", "")
S = bpy.context.scene
FIGHTERS = (("Sasuke", "Lion", "jutsu_sasuke"), ("Naruto", "Legion", "jutsu_naruto"), ("Gaara", "Sand", "jutsu_gaara"),
            ("Lee", "Leaf", "jutsu_lee"), ("Neji", "GentleFist", "jutsu_neji"), ("Itachi", "Mirage", "jutsu_itachi"),
            ("Kakashi", "Copycat", "jutsu_kakashi"), ("Minato", "Flashstep", "jutsu_minato"))


def review(arm, act, folder):
    """A sheet of the clip seen from the game's side camera, every 2 frames."""
    nd_anim.use(arm, act)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    step = max(2, (end - start) // 11)
    cam = bpy.data.objects["PreviewCam"]
    paths = []
    for i, f in enumerate(range(start, end + 1, step)):
        S.frame_set(f)
        root = arm.matrix_world @ arm.pose.bones["root"].matrix.translation
        tgt = Vector((root.x, root.y, 2.4))
        cam.location = tgt + Vector((float(os.environ.get("ND_CAMX", "5.6")), float(os.environ.get("ND_CAMY", "7.6")), 1.6))
        cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
        p = os.path.join(folder, "frames", "%s_%03d.png" % (act.name, i))
        S.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    nd_io.sheet(paths, os.path.join(folder, "%s.png" % act.name), 6, 260)


for name, fid, module in FIGHTERS:
    if ONLY and fid not in ONLY:
        continue
    try:
        mod = importlib.import_module(module)
    except ImportError:
        continue
    importlib.reload(mod)
    nd_rig.clear_scene()
    S.render.fps = 60
    arm = nd_ctrl.build(name, fid)
    acts = mod.author(arm)
    for act in acts:
        rep = nd_shot.check(arm, act)
        print("CHECK %-34s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    path = os.path.join(EXPORTS, "clips_%s_jutsu.json" % fid)
    data = nd_shot.export(arm, acts, path)
    print("exported", fid, {k: (v["frames"], v["markers"]) for k, v in data.items()})
    if REVIEW:
        os.makedirs(os.path.join(REVIEW, "frames"), exist_ok=True)
        nd_shot.stage(300)
        S.render.resolution_x = 260
        S.render.resolution_y = 300
        bpy.data.objects["PreviewCam"].data.lens = 32
        for act in acts:
            review(arm, act, REVIEW)
print("done")
