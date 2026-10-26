"""Export Blender clips to the game and render preview frames.

Export format (JSON, consumed by tools/blender/clips_to_luau.py):
  {clip: {fps, frames, loop, markers: {name: seconds}, joints: {joint: [[...], ...]}}}
  Root rows: [x, y, z, qx, qy, qz, qw]; other joints: [qx, qy, qz, qw].
Values are in Roblox axes (the rig's bone frames are Roblox frames), so a row
is directly CFrame.new(x, y, z, qx, qy, qz, qw) for Motor6D.Transform.
"""
import bpy, json, math, os
from mathutils import Vector
from nd_rig import ORDER, rb
import nd_anim

SAMPLE = 30


def export(arm, actions, path):
    scene = bpy.context.scene
    data = {}
    step = nd_anim.FPS // SAMPLE
    for act in actions:
        nd_anim.use(arm, act)
        start, end = int(act.frame_range[0]), int(act.frame_range[1])
        rows = {j: [] for j in ORDER}
        f = start
        while True:
            scene.frame_set(f)
            for j in ORDER:
                pb = arm.pose.bones[j]
                q = pb.rotation_quaternion.normalized()
                quat = [round(q.x, 4), round(q.y, 4), round(q.z, 4), round(q.w, 4)]
                if j == "Root":
                    l = pb.location
                    rows[j].append([round(l.x, 3), round(l.y, 3), round(l.z, 3)] + quat)
                else:
                    rows[j].append(quat)
            if f >= end:
                break
            f = min(end, f + step)
        markers = {k: round((v - start) / nd_anim.FPS, 4) for k, v in dict(act.get("nd_markers", {})).items()}
        data[act.name] = {"fps": SAMPLE, "frames": len(rows["Root"]), "length": round((end - start) / nd_anim.FPS, 4),
                          "loop": bool(act.get("nd_loop", False)), "markers": markers, "joints": rows}
    with open(path, "w") as fh:
        json.dump(data, fh, separators=(",", ":"))
    return data


def stage(fighter_arm, dummy=None):
    """Camera, light, floor and Workbench settings for previews."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "MATERIAL"
    shading.show_shadows = True
    shading.show_cavity = False
    shading.show_object_outline = True
    shading.object_outline_color = (0.05, 0.05, 0.07)
    scene.render.resolution_x = 420
    scene.render.resolution_y = 420
    scene.render.film_transparent = False
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    scene.render.fps = nd_anim.FPS
    if "Floor" not in bpy.data.objects:
        bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
        floor = bpy.context.active_object
        floor.name = "Floor"
        mat = bpy.data.materials.get("FloorMat") or bpy.data.materials.new("FloorMat")
        mat.diffuse_color = (.42, .38, .33, 1)
        floor.data.materials.append(mat)
    cam = bpy.data.objects.get("PreviewCam")
    if not cam:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 11
    scene.camera = cam
    return cam


def aim_camera(cam, view="side"):
    # The fighter faces Blender +Y (Roblox -Z). Side: from his right.
    target = Vector((0, 1.2, 2.6))
    pos = {"side": Vector((14, 1.2, 3.4)), "front34": Vector((-10, 9, 4.5)), "back34": Vector((9, -9, 4.5)),
           "game": Vector((4.5, -11, 7.5))}[view]
    if view == "game":
        target = Vector((0, 3, 2.2))
    cam.location = pos
    direction = target - pos
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render(arm, act, folder, view="side", every=3):
    scene = bpy.context.scene
    cam = stage(arm)
    aim_camera(cam, view)
    nd_anim.use(arm, act)
    os.makedirs(folder, exist_ok=True)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    paths = []
    f = start
    i = 0
    while f <= end:
        scene.frame_set(f)
        path = os.path.join(folder, "%s_%s_%03d.png" % (act.name, view, i))
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append(path)
        f += every
        i += 1
    return paths


def sheet(paths, out_path, columns=6, cell=300):
    """Tile rendered frames into one PNG (Blender's image API + numpy)."""
    import numpy as np
    imgs = []
    for p in paths:
        img = bpy.data.images.load(p, check_existing=False)
        w, h = img.size
        px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
        bpy.data.images.remove(img)
        # nearest resample to `cell`
        ys = (np.arange(cell) * h // cell)
        xs = (np.arange(cell) * w // cell)
        imgs.append(px[ys][:, xs])
    rows = (len(imgs) + columns - 1) // columns
    canvas = np.zeros((rows * cell, columns * cell, 4), dtype=np.float32)
    canvas[..., 3] = 1
    for i, im in enumerate(imgs):
        r, c = divmod(i, columns)
        # Blender pixels start at the bottom row: place rows from the top.
        y0 = (rows - 1 - r) * cell
        canvas[y0:y0 + cell, c * cell:(c + 1) * cell] = im
    out = bpy.data.images.new("sheet", columns * cell, rows * cell, alpha=True)
    out.pixels = canvas.ravel()
    out.filepath_raw = out_path
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    return out_path
