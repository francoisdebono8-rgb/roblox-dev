"""Contact sheets of authored clips, rendered with Cycles on the CPU (jutsu
pass, 05/11). Works headless where Workbench/EEVEE have no GPU (the cloud
workspace): Blender 5.2's bpy module renders a few hundred frames a minute
at sheet size.

  python3 review_clips.py OUT_DIR Fighter:fid:module[:clip,clip...] ...
    e.g. Itachi:Mirage:jutsu_itachi  or  Itachi:Mirage:json=exports/clips_Mirage_p3.json:Mirage.FireBloom.Channel

A clip set comes from a jutsu module (author(arm) -> actions) or from an
exported JSON (json=path; replayed onto the rig through nd_shot.load_json
when present, else skipped). One sheet per clip: COUNT frames across the
clip, from the duel camera's three-quarter front (VIEW env: front34 | side).
"""
import bpy, os, sys, json, importlib, math
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import nd_rig, nd_anim, nd_ctrl, nd_shot, nd_io
from mathutils import Vector

COUNT = int(os.environ.get("COUNT", "8"))
VIEW = os.environ.get("VIEW", "front34")
OFFSET = {"front34": Vector((5.2, 9.0, 1.4)), "side": Vector((11.0, .6, 1.2)), "front": Vector((0, 11.0, 1.2))}
S = bpy.context.scene


def stage():
    nd_shot.stage(300)
    S.render.engine = "CYCLES"
    S.cycles.device = "CPU"
    S.cycles.samples = int(os.environ.get("SAMPLES", "8"))
    S.cycles.use_denoising = False
    S.render.resolution_x, S.render.resolution_y = 240, 240
    w = S.world
    w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (.78, .8, .84, 1)
    bg.inputs[1].default_value = .9
    sun = bpy.data.lights.new("ReviewSun", "SUN")
    sun.energy = 3.2
    so = bpy.data.objects.new("ReviewSun", sun)
    S.collection.objects.link(so)
    so.rotation_euler = (.75, .15, .5)
    # every material shows its viewport colour under Cycles (the rig's
    # materials carry it in diffuse_color; their node trees are default white)
    for mat in bpy.data.materials:
        if not mat.node_tree:
            continue
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = mat.diffuse_color
            bsdf.inputs["Roughness"].default_value = .8
    cam = bpy.data.objects["PreviewCam"]
    S.camera = cam
    cam.data.lens = 30
    return cam


def render_clip(arm, act, cam, folder):
    nd_anim.use(arm, act)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    frames = sorted({round(start + (end - start) * k / max(1, COUNT - 1)) for k in range(COUNT)})
    paths = []
    for i, f in enumerate(frames):
        S.frame_set(f)
        root = arm.matrix_world @ arm.pose.bones["root"].matrix.translation
        tgt = Vector((root.x, root.y, 2.6))
        cam.location = tgt + OFFSET[VIEW]
        cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
        p = os.path.join(folder, "frames", "%s_%03d.png" % (act.name, i))
        S.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    out = os.path.join(folder, "%s.png" % act.name)
    nd_io.sheet(paths, out, COUNT, 240)
    return out


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    folder, specs = args[0], args[1:]
    os.makedirs(os.path.join(folder, "frames"), exist_ok=True)
    for spec in specs:
        parts = spec.split(":")
        name, fid, module = parts[0], parts[1], parts[2]
        only = set(parts[3].split(",")) if len(parts) > 3 and parts[3] else None
        nd_rig.clear_scene()
        S.render.fps = 60
        arm = nd_ctrl.build(name, fid)
        mod = importlib.import_module(module)
        acts = mod.author(arm)
        cam = stage()
        for act in acts:
            if only and act.name not in only:
                continue
            print("sheet", render_clip(arm, act, cam, folder), flush=True)


main()
