#!/usr/bin/env python3
"""The village as the game builds it, rendered in grey without Studio (23/11): reads the parts
tools/syphodev/konoha_dump.luau writes (Server/Hub.build at its real scale: every wall, roof,
deck, walkway and prop a body touches), puts the rooftop race's rings over their roofs, and
renders the views a player sees. It is the greybox, not the dressed village: what is run on.

    python3 tools/village/render_village.py DUMP.json OUT_DIR [--rings RINGS.json] [view ...]

Views (world studs from HubMap.Origin): air, gate, rooftop, residences, market_lane.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

S = 1.3  # HubMap.Scale (the dump is at the real scale; the rings are in base studs)

# eye, target: world studs relative to HubMap.Origin (north = -Z, the gate at +Z)
VIEWS = {
    "air": ((330, 260, 420), (0, 0, -10)),
    "gate": ((0, 9, 262), (0, 22, 120)),
    "rooftop": ((52, 42, 132), (300, 14, 118)),
    "residences": ((-60, 34, 128), (-300, 14, 160)),
    "market_lane": ((40, 8, 73), (300, 14, 73)),
}


def rbx_to_bl(v):
    return Vector((v[0], -v[2], v[1]))


def matrix_of(part):
    look, up = Vector(part["look"]), Vector(part["up"])
    z = -look
    x = up.cross(z)
    r = Matrix(((x[0], up[0], z[0]), (x[1], up[1], z[1]), (x[2], up[2], z[2])))
    t = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox (x, y up, z) -> Blender (x, -z, y)
    rb = t @ r @ t.inverted()
    m = rb.to_4x4()
    m.translation = rbx_to_bl(part["pos"])
    return m


MATS = {}


def material(color, alpha=1.0):
    key = (tuple(color), round(alpha, 2))
    if key in MATS:
        return MATS[key]
    m = bpy.data.materials.new(f"c{len(MATS)}")
    m.diffuse_color = (color[0] / 255, color[1] / 255, color[2] / 255, alpha)
    MATS[key] = m
    return m


def build(dump, rings):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    cube = bpy.data.meshes.new("cube")
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(cube)
    bm.free()
    cyl = bpy.data.meshes.new("cyl")
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=16, radius1=.5, radius2=.5, depth=1.0)
    bm.to_mesh(cyl)
    bm.free()
    ball = bpy.data.meshes.new("ball")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=.5)
    bm.to_mesh(ball)
    bm.free()
    scene = bpy.context.scene
    n = 0
    for p in dump["parts"]:
        if p["transparency"] >= 0.95 or p["name"] in ("Edge",):
            continue
        shape = p["shape"]
        mesh = cube
        size = Vector(p["size"])
        m = matrix_of(p)
        if shape == "Cylinder":
            # a Roblox cylinder lies along its X: the cone mesh stands along Z (Blender)
            mesh = cyl
            m = m @ Matrix.Rotation(math.radians(90), 4, "Y")
            size = Vector((size[1], size[2], size[0]))
            scale = Vector((size[0], size[1], size[2]))
        elif shape == "Ball":
            mesh = ball
            scale = Vector((size[0], size[2], size[1]))
        else:
            scale = Vector((size[0], size[2], size[1]))
        ob = bpy.data.objects.new(p["name"], mesh)
        ob.matrix_world = m @ Matrix.Diagonal(scale.to_4d())
        ob.color = (p["color"][0] / 255, p["color"][1] / 255, p["color"][2] / 255, 1 - p["transparency"])
        scene.collection.objects.link(ob)
        n += 1
    if dump.get("lake"):
        lk = dump["lake"]
        ob = bpy.data.objects.new("Water", cube)
        ob.matrix_world = Matrix.Translation(rbx_to_bl(lk["pos"])) @ Matrix.Diagonal(Vector((lk["size"][0], lk["size"][2], lk["size"][1], 1)))
        ob.color = (0.25, 0.45, 0.55, 1)
        scene.collection.objects.link(ob)
    # the race: an orange ring over each roof, its number's order in its size
    for i, r in enumerate(rings or []):
        bpy.ops.mesh.primitive_torus_add(major_radius=4.2, minor_radius=.45, location=rbx_to_bl((r[0] * S, r[1] * S + 3 * S, r[2] * S)))
        ob = bpy.context.active_object
        ob.rotation_euler = (math.radians(90), 0, 0)
        ob.color = (1.0, .45, .05, 1)
    return n


def scene_setup(w=1600, h=900):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "STUDIO"
    sh.color_type = "OBJECT"
    sh.show_shadows = True
    sh.show_cavity = True
    sh.cavity_type = "WORLD"
    sh.show_object_outline = True
    sh.object_outline_color = (0.12, 0.1, 0.09)
    sc.display.shadow_focus = 0.4
    sc.display.light_direction = (0.45, 0.35, 0.82)
    sh.background_type = "VIEWPORT"
    sh.background_color = (0.72, 0.82, 0.9)
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.lens = 24
    cam.data.clip_end = 4000
    sc.collection.objects.link(cam)
    sc.camera = cam
    return cam


def render(cam, out_dir, view):
    eye, target = VIEWS[view]
    e, t = rbx_to_bl(eye), rbx_to_bl(target)
    cam.location = e
    cam.rotation_euler = (t - e).to_track_quat("-Z", "Y").to_euler()
    path = os.path.join(out_dir, f"village_{view}.png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def main(argv):
    rings = None
    if "--rings" in argv:
        i = argv.index("--rings")
        rings = json.load(open(argv[i + 1]))
        argv = argv[:i] + argv[i + 2:]
    dump, out_dir = argv[0], argv[1]
    views = argv[2:] or list(VIEWS)
    os.makedirs(out_dir, exist_ok=True)
    n = build(json.load(open(dump)), rings)
    cam = scene_setup()
    for v in views:
        print(render(cam, out_dir, v), flush=True)
    print(f"{n} parts")


if __name__ == "__main__":
    main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
