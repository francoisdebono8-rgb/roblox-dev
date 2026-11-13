"""Render the parts dumped by dump.luau (13/11): one image per creature or
object, three-quarter front (its front is -Z in Roblox), Cycles on the CPU.

  python3 render.py DUMP.json OUT_DIR [name ...]
"""
import bpy, json, math, os, sys
from mathutils import Vector, Matrix

src, out = sys.argv[1], sys.argv[2]
only = set(sys.argv[3:])
data = json.load(open(src))
os.makedirs(out, exist_ok=True)
S = bpy.context.scene


def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    S.render.engine = "CYCLES"; S.cycles.device = "CPU"; S.cycles.samples = 12; S.cycles.use_denoising = False
    S.render.resolution_x, S.render.resolution_y = 360, 360
    w = S.world or bpy.data.worlds.new("W"); S.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (.72, .76, .82, 1)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sun.data.energy = 3.5
    sun.rotation_euler = (.7, .2, .6); S.collection.objects.link(sun)


mats = {}
def mat(col, tr):
    key = (tuple(col), round(tr, 2))
    if key not in mats:
        m = bpy.data.materials.new(str(key)); m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs[0].default_value = tuple((c / 255) ** 2.2 for c in col) + (1,)
        b.inputs["Alpha"].default_value = 1 - tr
        mats[key] = m
    return mats[key]


R = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # roblox (x, y up, z back) -> blender (x, y fwd... ) z up


def part(p):
    shape, mesh = p["shape"], p.get("mesh")
    sx, sy, sz = p["size"]
    if mesh and "Sphere" in mesh:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=.5); scale = (sx, sy, sz)
    elif "Ball" in shape:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=.5); d = min(sx, sy, sz); scale = (d, d, d)
    elif "Cylinder" in shape:
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=.5, depth=1, rotation=(0, math.pi / 2, 0))
        bpy.ops.object.transform_apply(rotation=True); d = min(sy, sz); scale = (sx, d, d)
    elif p["class"] == "WedgePart":
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.object
        # roblox wedge: slope from top-back to bottom-front (-z front, low)
        for v in o.data.vertices:
            if v.co.z > 0 and v.co.y > 0:  # top & front (blender +y = roblox -z)
                v.co.y = -.5
        scale = (sx, sy, sz)
    else:
        bpy.ops.mesh.primitive_cube_add(size=1); scale = (sx, sy, sz)
    o = bpy.context.object
    bpy.ops.object.shade_smooth()
    o.data.materials.append(mat(p["color"], p["transparency"]))
    r, u, b = Vector(p["r"]), Vector(p["u"]), Vector(p["b"])
    rot = Matrix((r, u, b)).transposed()          # roblox columns
    pos = Vector(p["pos"])
    # roblox frame -> blender: x, y_up -> z, z_back -> -y
    conv = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
    M = (conv @ rot).to_4x4()
    # local axes: roblox local (x,y,z) -> blender primitive local (x, z?, ...) handled by building the
    # primitive in roblox-local terms: local y is up -> blender local z
    local = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0))).to_4x4()   # blender-local -> roblox-local
    M = M @ local
    M.translation = conv @ pos
    o.matrix_world = M @ Matrix.Diagonal((scale[0], scale[2], scale[1], 1))
    return o


cam = None
for name, parts in data.items():
    if only and name not in only:
        continue
    if not parts:
        continue
    reset()
    objs = [part(p) for p in parts]
    lo = Vector((min(min((o.matrix_world @ Vector(c))[i] for c in o.bound_box) for o in objs) for i in range(3)))
    hi = Vector((max(max((o.matrix_world @ Vector(c))[i] for c in o.bound_box) for o in objs) for i in range(3)))
    ctr = (lo + hi) / 2; size = max((hi - lo).length, 1)
    bpy.ops.mesh.primitive_plane_add(size=size * 6, location=(ctr.x, ctr.y, lo.z - .02))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); S.collection.objects.link(cam); S.camera = cam
    cam.data.lens = 45
    cam.location = ctr + Vector((.55, 1.0, .45)).normalized() * size * float(os.environ.get("DIST", "1.25"))
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    S.render.filepath = os.path.join(out, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("rendered", name, flush=True)
