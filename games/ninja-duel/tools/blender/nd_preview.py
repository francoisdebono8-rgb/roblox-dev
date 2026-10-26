"""Preview films of authored clips: a checkered floor, the camera riding with
the fighter, the body travelling at its real stride so planted feet read as
planted. Every rendered frame is tiled into one sheet per clip (plus a JSON
manifest) and turned into a looping video outside Blender."""
import bpy, bmesh, json, math, os
from mathutils import Vector
import nd_anim, nd_io


def floor():
    if "Checker" in bpy.data.objects:
        return bpy.data.objects["Checker"]
    old = bpy.data.objects.get("Floor")
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new("Checker")
    bm = bmesh.new()
    n, size = 30, 2.0
    for i in range(n):
        for j in range(n):
            x0, y0 = (i - n / 2) * size, (j - n / 2) * size
            vs = [bm.verts.new((x0, y0, 0)), bm.verts.new((x0 + size, y0, 0)), bm.verts.new((x0 + size, y0 + size, 0)), bm.verts.new((x0, y0 + size, 0))]
            f = bm.faces.new(vs)
            f.material_index = (i + j) % 2
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("Checker", me)
    bpy.context.scene.collection.objects.link(ob)
    for name, rgb in (("TileA", (.55, .5, .44)), ("TileB", (.42, .38, .33))):
        m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
        m.diffuse_color = rgb + (1,)
        me.materials.append(m)
    return ob


def setup(res=320):
    scene = bpy.context.scene
    nd_io.stage(None)
    old = bpy.data.objects.get("Floor")
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    floor()
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.display.shading.light = "STUDIO"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_object_outline = True
    world = scene.world
    if world:
        world.color = (.62, .68, .74)
    cam = bpy.data.objects["PreviewCam"]
    cam.data.type = "PERSP"
    cam.data.lens = 50
    return cam


VIEWS = {"front34": Vector((-10.2, 7.6, 2.4)), "side": Vector((13, 2, 2.6)), "back34": Vector((8, -9, 4.2))}


def film(arm, act, folder, view="front34", travel=(0.0, 0.0), every=2, rise=None, cam=None, spin=None):
    """Render `act`; the rig moves by `travel` (Blender x, y studs over the
    clip) and the camera keeps its offset from the rig. `rise(u)` lifts the
    rig (jump arcs). Returns the frame paths."""
    scene = bpy.context.scene
    cam = cam or bpy.data.objects["PreviewCam"]
    nd_anim.use(arm, act)
    os.makedirs(folder, exist_ok=True)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    base = arm.location.copy()
    paths = []
    f, i = start, 0
    last = end - (every if act.get("nd_loop") else 0)
    while f <= max(start, last):
        u = (f - start) / max(1, end - start)
        arm.location = base + Vector((travel[0] * u, travel[1] * u, rise(u) if rise else 0))
        arm.rotation_euler = (spin(u) if spin else 0, 0, 0)
        target = arm.location + Vector((0, 0, .1))
        cam.location = target + VIEWS[view]
        cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.frame_set(f)
        path = os.path.join(folder, "%s_%s_%03d.png" % (act.name, view, i))
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append(path)
        f += every
        i += 1
    arm.location = base
    arm.rotation_euler = (0, 0, 0)
    return paths


def sheet_with_manifest(paths, out_png, fps, cell=256, columns=8):
    nd_io.sheet(paths, out_png, columns, cell)
    with open(out_png[:-4] + ".json", "w") as fh:
        json.dump({"frames": len(paths), "columns": columns, "cell": cell, "fps": fps}, fh)
