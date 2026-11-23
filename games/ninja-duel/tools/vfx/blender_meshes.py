"""Ninja Duel — formes VFX en volume, générées dans Blender (06/11/2026).

À lancer dans Blender (fenêtre ou arrière-plan) :
    blender --background --python blender_meshes.py -- ~/Documents/NinjaDuelVFX/meshes/nd_vfx_meshes.fbx

Produit un FBX (axe Y en haut) avec une MeshPart par forme :
ND_RingBlade (anneau-lame, onde de choc), ND_Crown (couronne qui jaillit du sol),
ND_Crescent (lame en croissant), ND_Spiral (ruban hélicoïdal), ND_Spike (pique),
ND_Rock1..3 (rochers anguleux), ND_Slab1..3 (dalles de sol pour les cratères),
ND_Dome (dôme de souffle). Le code client est src/Client/VfxMesh.luau.
"""
import math, os, random, sys
import bpy, bmesh

random.seed(7)


def obj(name, verts, faces, smooth=False):
    old = bpy.data.objects.get(name)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.validate(); me.update()
    for p in me.polygons:
        p.use_smooth = smooth
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def double_sided(verts, faces):
    n = len(verts)
    return verts + list(verts), faces + [tuple(i + n for i in reversed(f)) for f in faces]


def revolve(profile, seg):
    verts, faces, P = [], [], len(profile)
    for s in range(seg):
        a = 2 * math.pi * s / seg
        verts += [(r * math.cos(a), r * math.sin(a), z) for r, z in profile]
    for s in range(seg):
        s2 = (s + 1) % seg
        for k in range(P):
            k2 = (k + 1) % P
            faces.append((s * P + k, s * P + k2, s2 * P + k2, s2 * P + k))
    return verts, faces


def ring_blade():
    v, f = revolve([(0.82, 0.0), (0.91, 0.045), (1.0, 0.0), (0.91, -0.045)], 72)
    obj("ND_RingBlade", v, f, smooth=True)


def crown(seg=64):
    verts, faces = [], []
    for s in range(seg + 1):
        a = 2 * math.pi * s / seg
        top = [1.0, 0.62, 0.82, 0.55][s % 4] * random.uniform(0.85, 1.05)
        verts += [(math.cos(a), math.sin(a), 0.0), (1.28 * math.cos(a), 1.28 * math.sin(a), top)]
    faces = [(s * 2, s * 2 + 2, s * 2 + 3, s * 2 + 1) for s in range(seg)]
    obj("ND_Crown", *double_sided(verts, faces))


def crescent(U=56):
    verts, faces = [], []
    for i in range(U + 1):
        u = i / U
        a = math.radians(-100 + 200 * u)
        w = 0.3 * math.sin(math.pi * u) ** 1.3
        t = 0.035 * math.sin(math.pi * u) ** 0.8
        ro, ri = 1.0, 1.0 - w
        rm = (ro + ri) / 2
        ca, sa = math.cos(a), math.sin(a)
        verts += [(ro * ca, ro * sa, 0), (rm * ca, rm * sa, t), (ri * ca, ri * sa, 0), (rm * ca, rm * sa, -t)]
    for i in range(U):
        b, c = i * 4, (i + 1) * 4
        faces += [(b + k, c + k, c + (k + 1) % 4, b + (k + 1) % 4) for k in range(4)]
    obj("ND_Crescent", verts, faces)


def spiral(U=120):
    verts = []
    for i in range(U + 1):
        u = i / U
        a = 2 * math.pi * 1.5 * u
        w = 0.22 * math.sin(math.pi * u) ** 0.9
        r = 1.0 - 0.25 * u
        verts += [(r * math.cos(a), r * math.sin(a), 2 * u - w), (r * math.cos(a), r * math.sin(a), 2 * u + w)]
    faces = [(i * 2, i * 2 + 2, i * 2 + 3, i * 2 + 1) for i in range(U)]
    obj("ND_Spiral", *double_sided(verts, faces))


def spike():
    verts = [(0, 0, 1.0)]
    for s in range(6):
        a = 2 * math.pi * s / 6
        r = 0.22 * random.uniform(0.8, 1.15)
        verts.append((r * math.cos(a), r * math.sin(a), 0))
    verts.append((0, 0, -0.05))
    faces = []
    for s in range(6):
        i, j = 1 + s, 1 + (s + 1) % 6
        faces += [(0, i, j), (7, j, i)]
    obj("ND_Spike", verts, faces)


def rocks():
    for n in range(1, 4):
        r = random.Random(20 + n)
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=0, radius=0.5)
        sx, sy, sz = r.uniform(0.8, 1.2), r.uniform(0.7, 1.0), r.uniform(0.9, 1.4)
        for v in bm.verts:
            k = r.uniform(0.7, 1.15)
            v.co.x *= k * sx; v.co.y *= k * sy; v.co.z *= k * sz
        me = bpy.data.meshes.new(f"ND_Rock{n}"); bm.to_mesh(me); bm.free()
        ob = bpy.data.objects.new(f"ND_Rock{n}", me); bpy.context.scene.collection.objects.link(ob)


def slab(name, n, thick, sx, sy, seed):
    r = random.Random(seed)
    top, bot = [], []
    for i in range(n):
        a = 2 * math.pi * i / n + r.uniform(-0.25, 0.25)
        rad = r.uniform(0.75, 1.0)
        x, y = math.cos(a) * rad * sx, math.sin(a) * rad * sy
        top.append((x, y, thick / 2 + r.uniform(-0.04, 0.04)))
        bot.append((x * 0.9, y * 0.9, -thick / 2))
    verts = top + bot + [(0, 0, thick / 2 + 0.05), (0, 0, -thick / 2)]
    cT, cB = 2 * n, 2 * n + 1
    faces = []
    for i in range(n):
        j = (i + 1) % n
        faces += [(cT, i, j), (cB, n + j, n + i), (i, n + i, n + j, j)]
    obj(name, verts, faces)


def dome():
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=40, v_segments=16, radius=1.0)
    for face in list(bm.faces):
        if face.calc_center_median().z < -0.01:
            bm.faces.remove(face)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    me = bpy.data.meshes.new("ND_Dome"); bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("ND_Dome", me); bpy.context.scene.collection.objects.link(ob)


def main(out):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ring_blade(); crown(); crescent(); spiral(); spike(); rocks(); dome()
    slab("ND_Slab1", 5, 0.35, 1.0, 0.7, 1)
    slab("ND_Slab2", 6, 0.4, 0.9, 0.6, 2)
    slab("ND_Slab3", 4, 0.3, 1.0, 0.8, 3)
    for ob in bpy.context.scene.objects:
        if not ob.name.startswith(("ND_Crown", "ND_Spiral", "ND_Dome")):
            bm = bmesh.new(); bm.from_mesh(ob.data)
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
            bm.to_mesh(ob.data); bm.free()
    for i, ob in enumerate(sorted(bpy.context.scene.objects, key=lambda o: o.name)):
        ob.location = (i * 3.0, 0, 0)
        ob.select_set(True)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=out, use_selection=True, apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL",
                             axis_forward="-Z", axis_up="Y", add_leaf_bones=False, mesh_smooth_type="FACE",
                             bake_space_transform=True)


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    main(os.path.expanduser(args[0] if args else "~/Documents/NinjaDuelVFX/meshes/nd_vfx_meshes.fbx"))
