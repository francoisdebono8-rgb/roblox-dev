"""Small mesh kit for the game's modelled props (13/11, user: « on va passer sur
des gros travaux ... il va nous falloir des vrais modèles 3D »).

Meshes are built in pure Python (vertices, faces, one colour per vertex) so a
model is a few readable functions, then either
  - written as Luau data for Client/MeshKit (the game builds them at run time
    with AssetService:CreateEditableMesh: nothing to upload), or
  - turned into Blender objects and rendered (preview sheets).

Blender frame while modelling: x right, y = the object's front (Roblox -z),
z up. The export converts to Roblox (x, z, -y).
"""
import math
from mathutils import Vector, Matrix, noise


def rgb(r, g, b):
    return (r / 255, g / 255, b / 255)


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


class Piece:
    """One mesh of a model: its own material (Metal, Fabric, Sand, Neon...)."""

    def __init__(self, name, mat="SmoothPlastic", flat=False, alpha=0.0, reflect=0.0):
        self.name, self.mat, self.flat, self.alpha, self.reflect = name, mat, flat, alpha, reflect
        self.v, self.c, self.f = [], [], []

    def add(self, p, col):
        self.v.append(Vector(p))
        self.c.append(tuple(col))
        return len(self.v) - 1

    def face(self, *idx):
        self.f.append(tuple(idx))

    def transform(self, mat):
        self.v = [mat @ v for v in self.v]
        return self

    def tris(self):
        out = []
        for f in self.f:
            for k in range(1, len(f) - 1):
                out.append((f[0], f[k], f[k + 1]))
        return out


def col_of(col, p, k=0):
    return col(p, k) if callable(col) else col


def loft(pc, rings, col, cap0=True, cap1=True, closed=True, tip0=None, tip1=None):
    """Joins rings of equal length into a surface. col(p, ring_index) or a colour.
    tip0/tip1: a point to close that end on (a cone), else a flat cap."""
    idx = []
    for ri, ring in enumerate(rings):
        idx.append([pc.add(p, col_of(col, p, ri)) for p in ring])
    n = len(rings[0])
    for r in range(len(rings) - 1):
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            pc.face(idx[r][i], idx[r][j], idx[r + 1][j], idx[r + 1][i])
    for end, tip, cap in ((0, tip0, cap0), (len(rings) - 1, tip1, cap1)):
        ring = idx[end]
        if tip is not None:
            t = pc.add(tip, col_of(col, Vector(tip), end))
            for i in range(n):
                j = (i + 1) % n
                pc.face(ring[i], ring[j], t) if end == len(rings) - 1 else pc.face(ring[j], ring[i], t)
        elif cap and closed:
            c = sum((pc.v[i] for i in ring), Vector()) / n
            ci = pc.add(c, col_of(col, c, end))
            for i in range(n):
                j = (i + 1) % n
                pc.face(ring[i], ring[j], ci) if end == len(rings) - 1 else pc.face(ring[j], ring[i], ci)
    return idx


def frames(points):
    """Parallel-transport frames (tangent, normal, binormal) along a polyline."""
    pts = [Vector(p) for p in points]
    tans = []
    for i in range(len(pts)):
        a = pts[max(0, i - 1)]
        b = pts[min(len(pts) - 1, i + 1)]
        tans.append((b - a).normalized())
    up = Vector((0, 0, 1)) if abs(tans[0].z) < .9 else Vector((1, 0, 0))
    n = tans[0].cross(up).normalized()
    out = []
    for i, t in enumerate(tans):
        if i > 0:
            n = (n - t * n.dot(t)).normalized()
        out.append((t, n, t.cross(n).normalized()))
    return pts, out


def tube(pc, points, radius, col, sides=10, cap0=True, cap1=True, tip1=False, shape=None, twist=0.0):
    """A tube along points. radius(k in 0..1) or number; shape(theta,k) -> (sx, sy) scale of the section."""
    pts, fr = frames(points)
    rings = []
    m = len(pts)
    for i, (p, (t, n, b)) in enumerate(zip(pts, fr)):
        k = i / (m - 1)
        r = radius(k) if callable(radius) else radius
        ring = []
        for s in range(sides):
            a = s / sides * math.tau + twist * k
            sx, sy = shape(a, k) if shape else (1, 1)
            ring.append(p + (n * math.cos(a) * sx + b * math.sin(a) * sy) * r)
        rings.append(ring)
    # colour callbacks get k in 0..1 along the tube
    kcol = (lambda p, i: col(p, i / max(1, m - 1))) if callable(col) else col
    if tip1:
        tipp = pts[-1] + fr[-1][0] * 0.0
        return loft(pc, rings[:-1], kcol, cap0=cap0, tip1=tipp)
    return loft(pc, rings, kcol, cap0=cap0, cap1=cap1)


def ellipsoid(pc, center, radii, col, seg=16, rings=10, bump=None):
    c = Vector(center)
    top = c + Vector((0, 0, radii[2]))
    bot = c - Vector((0, 0, radii[2]))
    rs = []
    for i in range(1, rings):
        phi = math.pi * i / rings
        ring = []
        for s in range(seg):
            th = s / seg * math.tau
            d = Vector((math.sin(phi) * math.cos(th), math.sin(phi) * math.sin(th), math.cos(phi)))
            k = 1 + (bump(d) if bump else 0)
            ring.append(c + Vector((d.x * radii[0], d.y * radii[1], d.z * radii[2])) * k)
        rs.append(ring)
    return loft(pc, rs, col, tip0=top, tip1=bot)


def torus(pc, center, axis_mat, major, minor, col, seg=24, sides=8):
    rings = []
    for i in range(seg + 1):
        a = i / seg * math.tau
        cdir = Vector((math.cos(a), math.sin(a), 0))
        ring = []
        for s in range(sides):
            b = s / sides * math.tau
            p = cdir * (major + minor * math.cos(b)) + Vector((0, 0, minor * math.sin(b)))
            ring.append(Vector(center) + axis_mat @ p)
        rings.append(ring)
    idx = loft(pc, rings[:-1] + [rings[0]], col, cap0=False, cap1=False)
    return idx


# ---------------------------------------------------------------- export
def to_roblox(v):
    return Vector((v.x, v.z, -v.y))


def outward(pc):
    """Faces turned outward (bmesh recalc), so the game's culling shows the outside."""
    import bmesh
    bm = bmesh.new()
    vs = [bm.verts.new(v) for v in pc.v]
    for f in pc.f:
        try:
            bm.faces.new([vs[i] for i in f])
        except ValueError:
            pass
    bm.verts.index_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    pc.f = [tuple(v.index for v in f.verts) for f in bm.faces]
    bm.free()


def piece_luau(pc, scale=1.0):
    """One piece as packed data: vertices quantised to 16 bits over the piece's
    half extents, then the colours (bytes), then the triangles (16-bit,
    0-based), little-endian, base64 (Client/MeshKit decodes it)."""
    import struct, base64
    outward(pc)
    vs = [to_roblox(v) * scale for v in pc.v]
    lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    ctr = (lo + hi) / 2
    half = Vector((max(1e-4, (hi.x - lo.x) / 2), max(1e-4, (hi.y - lo.y) / 2), max(1e-4, (hi.z - lo.z) / 2)))
    tris = pc.tris()
    assert len(vs) < 65536
    raw = bytearray()
    for v in vs:
        d = v - ctr
        for a, h in ((d.x, half.x), (d.y, half.y), (d.z, half.z)):
            raw += struct.pack("<H", int(round((a / h * .5 + .5) * 65535)))
    for c in pc.c:
        raw += bytes(int(round(max(0, min(1, x)) * 255)) for x in c)
    for t in tris:
        raw += struct.pack("<HHH", *t)
    extra = ""
    if pc.alpha:
        extra += ",alpha=%.2f" % pc.alpha
    if pc.reflect:
        extra += ",reflect=%.2f" % pc.reflect
    return "{name=%s,mat=%s,flat=%s,o={%.4f,%.4f,%.4f},h={%.4f,%.4f,%.4f},n=%d,m=%d%s,\n\t\t\td=\"%s\"}" % (
        q(pc.name), q(pc.mat), "true" if pc.flat else "false", ctr.x, ctr.y, ctr.z, half.x, half.y, half.z,
        len(vs), len(tris), extra, base64.b64encode(bytes(raw)).decode())


def q(s):
    return '"%s"' % s


def model_luau(name, pieces):
    body = []
    for pc in pieces:
        body.append("\t\t" + piece_luau(pc))
    return "\t[%s]={\n%s,\n\t}," % (q(name), ",\n".join(body))


def stats(pieces):
    return sum(len(p.v) for p in pieces), sum(len(p.tris()) for p in pieces)


# ---------------------------------------------------------------- blender
def to_blender(pc, link=True):
    import bpy
    outward(pc)
    me = bpy.data.meshes.new(pc.name)
    me.from_pydata([tuple(v) for v in pc.v], [], [list(f) for f in pc.f])
    me.validate()
    attr = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    for i, c in enumerate(pc.c):
        attr.data[i].color = tuple(max(0.0, min(1.0, x)) ** 2.2 for x in c) + (1,)
    for p in me.polygons:
        p.use_smooth = not pc.flat
    ob = bpy.data.objects.new(pc.name, me)
    if link:
        bpy.context.collection.objects.link(ob)
    mat = bpy.data.materials.new(pc.name + "_m")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    rough = {"Metal": .32, "Fabric": .95, "Sand": 1, "Slate": .95, "Rock": .95, "Glass": .05, "Neon": .5, "Wood": .8}.get(pc.mat, .55)
    bsdf.inputs["Roughness"].default_value = rough
    if pc.mat == "Metal":
        bsdf.inputs["Metallic"].default_value = .75
    if pc.mat == "Neon":
        nt.links.new(vc.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 3
    if pc.alpha:
        bsdf.inputs["Alpha"].default_value = 1 - pc.alpha
    me.materials.append(mat)
    return ob


def render_set(objs, path, size=(480, 360), view=(1, -1.25, .7), world=(.62, .66, .72), lens=50, fill=1.15):
    """Renders the objects framed by their bounds from direction `view`."""
    import bpy
    S = bpy.context.scene
    S.render.engine = "CYCLES"
    S.cycles.device = "CPU"
    S.cycles.samples = 24
    S.cycles.use_denoising = False
    S.render.resolution_x, S.render.resolution_y = size
    S.render.film_transparent = False
    w = S.world or bpy.data.worlds.new("W")
    S.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (*world, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = .9
    for o in list(S.objects):
        if o.type in ("LIGHT", "CAMERA"):
            bpy.data.objects.remove(o)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.2
    sun.rotation_euler = (.75, .15, 2.2)
    S.collection.objects.link(sun)
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (lo + hi) / 2
    rad = (hi - lo).length / 2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = lens
    S.collection.objects.link(cam)
    S.camera = cam
    d = Vector(view).normalized()
    fov = 2 * math.atan(36 / 2 / lens) * min(1, size[1] / size[0])
    dist = rad * fill / math.sin(fov / 2)
    cam.location = ctr + d * dist
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.clip_end = dist * 4
    S.render.filepath = path
    bpy.ops.render.render(write_still=True)


def clear():
    import bpy
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)
