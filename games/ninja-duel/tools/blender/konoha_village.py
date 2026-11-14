"""Konoha assembled, rendered without Studio (14/11, HUB_DRESS): reads the
layout tools/hub_layout.luau writes (every dressed copy as Client/HubDress
places it, and the parts that stay seen), builds each konoha_models.py model
once and instances it, then renders views of the village. It checks the
contract between the two sides (a house turned the wrong way, a wall too
short, a tree too big) before anyone opens Studio.

  python3 konoha_village.py LAYOUT.json OUT_DIR [view ...]

Views: gate, street, plaza, hall, uchiha, faces, rooftops, air, market, residences.
"""
import json, math, os, sys
import bpy
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Matrix, Vector
import nd_mesh
import konoha_models as K

# Roblox (x, y up, z) <-> the model frame of nd_mesh (x, y = Roblox -z, z up).
TO_RBX = Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, -1, 0, 0), (0, 0, 0, 1)))
TO_BL = TO_RBX.inverted()

# Camera (eye, target) in village coordinates (relative to HubMap.Origin).
VIEWS = {
    "gate": ((0, 7, 234), (0, 18, 150)),
    "street": ((0, 6, 190), (0, 10, 60)),
    "plaza": ((-30, 8, 52), (6, 12, -40)),
    "hall": ((0, 8, -28), (0, 12, -115)),
    "uchiha": ((106, 9, -36), (180, 8, -112)),
    "faces": ((0, 10, -131), (0, 50, -232)),
    "rooftops": ((30, 24, 206), (34, 16, 92)),
    "air": ((240, 210, 300), (0, 0, -30)),
    "market": ((76, 7, 56), (240, 9, 56)),
    "residences": ((-92, 7, 150), (-246, 9, 150)),
}


def cframe(c):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c
    return Matrix(((r00, r01, r02, x), (r10, r11, r12, y), (r20, r21, r22, z), (0, 0, 0, 1)))


def material(name, color):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*[c ** 2.2 for c in color], 1)
    b.inputs["Roughness"].default_value = .9
    return m


def build(layout):
    nd_mesh.clear()
    origin = Vector(layout["origin"])
    shift = Matrix.Translation(-origin)
    col = bpy.context.scene.collection
    protos = {}
    for name in sorted({c["name"] for c in layout["copies"]}):
        # konoha_models builds in the Roblox frame; blender() is its export turn
        protos[name] = [nd_mesh.to_blender(p, link=False) for p in K.blender(K.MODELS[name]())]
    for c in layout["copies"]:
        s = c["scale"]
        m = TO_BL @ shift @ cframe(c["cf"]) @ Matrix.Diagonal((s[0], s[1], s[2], 1)) @ TO_RBX
        for proto in protos[c["name"]]:
            ob = bpy.data.objects.new(c["name"], proto.data)
            ob.matrix_world = m
            col.objects.link(ob)
    # the parts that stay seen: boxes, discs, balls (unit primitives placed
    # as Roblox does: CFrame * size; a Roblox cylinder lies along its x)
    for p in layout["parts"]:
        size = p["size"]
        if p["shape"] == "Cylinder":
            bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=.5, depth=1)
            local = Matrix.Diagonal((size[0], size[1], size[2], 1)) @ Matrix.Rotation(math.pi / 2, 4, "Y")
        elif p["shape"] == "Ball":
            bpy.ops.mesh.primitive_uv_sphere_add(radius=.5)
            local = Matrix.Diagonal((size[0], size[1], size[2], 1))
        else:
            bpy.ops.mesh.primitive_cube_add(size=1)
            local = Matrix.Diagonal((size[0], size[1], size[2], 1)) @ TO_RBX
        ob = bpy.context.object
        ob.matrix_world = TO_BL @ shift @ cframe(p["cf"]) @ local
        ob.data.materials.append(material("m_%s_%d_%d_%d" % (p["material"], *[int(v * 255) for v in p["color"]]), p["color"]))
    # the Uchiha lake (Terrain water in the game)
    bpy.ops.mesh.primitive_plane_add(size=1)
    lake = bpy.context.object
    lake.matrix_world = TO_BL @ Matrix.Translation((179, -.45, -67)) @ Matrix.Diagonal((54, 1, 58, 1)) @ TO_BL.inverted()
    lake.data.materials.append(material("water", (.22, .36, .42)))
    # the hall's warm lights under its roof (Server/Hub: HallLight, range 48)
    for z in (-40, -70, -100):
        light = bpy.data.objects.new("HallLight", bpy.data.lights.new("HallLight", "POINT"))
        light.data.energy = 60000
        light.data.color = (1, .84, .67)
        light.data.shadow_soft_size = 2
        light.location = TO_BL @ Vector((0, 24, z))
        col.objects.link(light)


def scene_setup():
    S = bpy.context.scene
    S.render.engine = "CYCLES"
    S.cycles.device = "CPU"
    S.cycles.samples = 48
    try:
        S.cycles.use_denoising = True
    except Exception:
        pass
    S.render.resolution_x, S.render.resolution_y = 1280, 720
    w = bpy.data.worlds.new("Sky")
    S.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (.55, .68, .86, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = .8
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.4
    sun.data.angle = math.radians(3)
    sun.rotation_euler = (math.radians(48), math.radians(12), math.radians(-38))
    S.collection.objects.link(sun)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = 24
    cam.data.clip_end = 3000
    S.collection.objects.link(cam)
    S.camera = cam
    return cam


def bl(p):
    return Vector((p[0], -p[2], p[1]))


def render(cam, out_dir, view):
    eye, target = VIEWS[view]
    cam.location = bl(eye)
    cam.rotation_euler = (bl(target) - bl(eye)).to_track_quat("-Z", "Y").to_euler()
    S = bpy.context.scene
    S.render.filepath = os.path.join(out_dir, "village_%s.png" % view)
    bpy.ops.render.render(write_still=True)
    print("rendered", view, flush=True)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    layout = json.load(open(args[0]))
    out = args[1]
    os.makedirs(out, exist_ok=True)
    build(layout)
    cam = scene_setup()
    for view in (args[2:] or list(VIEWS)):
        render(cam, out, view)
