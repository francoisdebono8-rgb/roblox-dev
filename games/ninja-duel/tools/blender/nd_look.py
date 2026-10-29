# Ninja Duel — costume modelling helpers (user 29/10 14:37: "produis les
# designs sur Blender"). Everything is written in ROBLOX rest-pose space
# (studs, root at the origin, the fighter facing -Z, +X his right, +Y up) and
# converted on the way in: Blender (X,Y,Z) = (-x, z, y) (measured with the
# axis probe, job_096). One object per costume piece, named
# "<BodyPart>__<Piece>", coloured by the manifest written next to the FBX.
import bpy, bmesh, math, json, os
from mathutils import Vector

# Rest pose of the Ninja Duel rig after Looks.form (joint-solved centres).
REST = {
    "LowerTorso": (0, 0, 0), "UpperTorso": (0, 1.15, 0), "Head": (0, 2.75, 0),
    "LeftUpperArm": (-1.24, 1.1, 0), "RightUpperArm": (1.24, 1.1, 0),
    "LeftLowerArm": (-1.24, .1, 0), "RightLowerArm": (1.24, .1, 0),
    "LeftHand": (-1.24, -.63, 0), "RightHand": (1.24, -.63, 0),
    "LeftUpperLeg": (-.5, -1.05, 0), "RightUpperLeg": (.5, -1.05, 0),
    "LeftLowerLeg": (-.5, -2.1, 0), "RightLowerLeg": (.5, -2.1, 0),
    "LeftFoot": (-.5, -2.8, -.15), "RightFoot": (.5, -2.8, -.15),
}
MANIFEST = {}

def R(x, y, z):
    return Vector((-x, z, y))

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MANIFEST.clear()

def _material(rgb):
    key = "C_%02x%02x%02x" % tuple(int(c) for c in rgb)
    m = bpy.data.materials.get(key)
    if not m:
        m = bpy.data.materials.new(key)
        m.diffuse_color = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1)
    return m

def finish(obj, body, piece, rgb, smooth=40, material="SmoothPlastic", reflect=0):
    """Name, colour, shade (smooth below `smooth` degrees, sharp above)."""
    obj.name = body + "__" + piece
    obj.data.name = obj.name
    obj.data.materials.clear()
    obj.data.materials.append(_material(rgb))
    obj.color = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1)
    for p in obj.data.polygons:
        p.use_smooth = True
    try:
        obj.data.set_sharp_from_angle(angle=math.radians(smooth))
    except Exception:
        pass
    MANIFEST[obj.name] = {"body": body, "color": list(rgb), "material": material, "reflectance": reflect}
    return obj

def _object(name, verts, faces):
    me = bpy.data.meshes.new(name)
    me.from_pydata([R(*v) for v in verts], [], faces)
    me.validate()
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob

def superellipse(hx, hz, n, sides, phase=0.0):
    pts = []
    for i in range(sides):
        a = 2 * math.pi * i / sides + phase
        c, s = math.cos(a), math.sin(a)
        x = hx * math.copysign(abs(c) ** (2 / n), c)
        z = hz * math.copysign(abs(s) ** (2 / n), s)
        pts.append((x, z))
    return pts

def loft(sections, sides=32, center=(0, 0, 0), cap_top=True, cap_bottom=True, wobble=None, name="loft"):
    """sections: list of (y, hx, hz, n[, dz]) bottom to top, relative to center.
    wobble(angle, y) -> radial offset (cloth folds)."""
    cx, cy, cz = center
    verts, faces = [], []
    for (y, hx, hz, n, *rest) in sections:
        dz = rest[0] if rest else 0
        for i, (x, z) in enumerate(superellipse(hx, hz, n, sides)):
            a = 2 * math.pi * i / sides
            if wobble:
                w = wobble(a, y)
                l = math.hypot(x, z) or 1
                x += x / l * w
                z += z / l * w
            verts.append((cx + x, cy + y, cz + z + dz))
    rings = len(sections)
    for r in range(rings - 1):
        for i in range(sides):
            a, b = r * sides + i, r * sides + (i + 1) % sides
            c, d = (r + 1) * sides + (i + 1) % sides, (r + 1) * sides + i
            faces.append((a, b, c, d))
    if cap_bottom:
        faces.append(tuple(reversed(range(sides))))
    if cap_top:
        faces.append(tuple((rings - 1) * sides + i for i in range(sides)))
    ob = _object(name, verts, faces)
    _outward(ob)
    return ob

def _outward(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()

def band(y, height, hx, hz, thick=.04, sides=48, center=(0, 0, 0), n=2, name="band"):
    """A hollow ring (cloth band, collar, cuff): outer and inner walls."""
    cx, cy, cz = center
    outer = superellipse(hx, hz, n, sides)
    inner = superellipse(hx - thick, hz - thick, n, sides)
    verts = []
    for ring_y, pts in ((y - height / 2, outer), (y + height / 2, outer), (y + height / 2, inner), (y - height / 2, inner)):
        for (x, z) in pts:
            verts.append((cx + x, cy + ring_y, cz + z))
    faces = []
    for r in range(4):
        r2 = (r + 1) % 4
        for i in range(sides):
            a, b = r * sides + i, r * sides + (i + 1) % sides
            faces.append((a, b, r2 * sides + (i + 1) % sides, r2 * sides + i))
    ob = _object(name, verts, faces)
    _outward(ob)
    return ob

def spike(base, direction, length, width, depth=None, bend=(0, 0, 0), sides=6, twist=0.0, rings=6, name="spike", root=1.0):
    """A tapered, slightly curved lock: rings along a bent spine, a sharp tip."""
    base = Vector(base)
    d = Vector(direction).normalized()
    bendv = Vector(bend)
    up = Vector((0, 1, 0)) if abs(d.y) < .9 else Vector((0, 0, 1))
    side = d.cross(up).normalized()
    nrm = side.cross(d).normalized()
    depth = depth or width
    verts, faces = [], []
    for k in range(rings):
        t = k / rings
        p = base + d * length * t + bendv * (t * t) * length
        r = root * (1 - t) ** .85
        for i in range(sides):
            a = 2 * math.pi * i / sides + twist * t
            off = side * math.cos(a) * width / 2 * r + nrm * math.sin(a) * depth / 2 * r
            verts.append(tuple(p + off))
    tip = base + d * length + bendv * length
    verts.append(tuple(tip))
    for k in range(rings - 1):
        for i in range(sides):
            a, b = k * sides + i, k * sides + (i + 1) % sides
            faces.append((a, b, (k + 1) * sides + (i + 1) % sides, (k + 1) * sides + i))
    t = len(verts) - 1
    for i in range(sides):
        faces.append(((rings - 1) * sides + i, (rings - 1) * sides + (i + 1) % sides, t))
    faces.append(tuple(reversed(range(sides))))
    ob = _object(name, verts, faces)
    _outward(ob)
    return ob

def ellipsoid(center, radii, segments=24, rings=16, name="ellipsoid"):
    cx, cy, cz = center
    rx, ry, rz = radii
    verts, faces = [], []
    for j in range(rings + 1):
        v = math.pi * j / rings
        for i in range(segments):
            u = 2 * math.pi * i / segments
            verts.append((cx + rx * math.sin(v) * math.cos(u), cy + ry * math.cos(v), cz + rz * math.sin(v) * math.sin(u)))
    for j in range(rings):
        for i in range(segments):
            a, b = j * segments + i, j * segments + (i + 1) % segments
            faces.append((a, b, (j + 1) * segments + (i + 1) % segments, (j + 1) * segments + i))
    ob = _object(name, verts, faces)
    bpy.context.view_layer.objects.active = ob
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data); bm.free()
    return ob

def box(center, size, bevel=.04, segments=2, name="box"):
    cx, cy, cz = center
    sx, sy, sz = (s / 2 for s in size)
    verts = [(cx + x * sx, cy + y * sy, cz + z * sz) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    ob = _object(name, verts, faces)
    _outward(ob)
    if bevel > 0:
        m = ob.modifiers.new("bevel", "BEVEL"); m.width = bevel; m.segments = segments
        apply_modifiers(ob)
    return ob

def cut_below(ob, point, normal):
    """Remove the part of a mesh on the -normal side of a plane (Roblox space)."""
    bm = bmesh.new(); bm.from_mesh(ob.data)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=R(*point), plane_no=R(*normal) , clear_inner=True)
    bm.to_mesh(ob.data); bm.free()

def solidify(ob, thick):
    m = ob.modifiers.new("solid", "SOLIDIFY"); m.thickness = thick; m.offset = 1
    apply_modifiers(ob)

def subdivide(ob, levels=1):
    m = ob.modifiers.new("subd", "SUBSURF"); m.levels = levels; m.render_levels = levels
    apply_modifiers(ob)

def apply_modifiers(ob):
    deps = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(deps)
    me = bpy.data.meshes.new_from_object(ev)
    old = ob.data
    ob.modifiers.clear()
    ob.data = me
    bpy.data.meshes.remove(old)

def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    return o

def export(stem, out):
    """FBX of every piece (rest-pose positions; the importer keeps them
    relative to the scene origin) + the colour/body manifest."""
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(out, stem + ".fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="OFF", use_mesh_modifiers=True, add_leaf_bones=False)
    with open(os.path.join(out, stem + ".json"), "w") as f:
        json.dump({"rest": REST, "pieces": MANIFEST}, f, indent=1)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print("exported", path, len(MANIFEST), "pieces", tris, "tris")

def preview(stem, out, stand_in=True):
    """Workbench renders (front, three-quarter, back) for review, with grey
    stand-ins for the Roblox head and hands."""
    if stand_in:
        h = ellipsoid((0, 2.75, 0), (.89, .93, .89), name="StandInHead")
        h.color = (1, .87, .76, 1)
        for s in (-1, 1):
            e = ellipsoid((s * 1.24, -.6, 0), (.31, .4, .29), name="StandInHand")
            e.color = (1, .87, .76, 1)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "OBJECT"
    shading.show_cavity = True
    shading.show_object_outline = True
    shading.object_outline_color = (0.05, 0.05, 0.07)
    scene.render.resolution_x, scene.render.resolution_y = 900, 1200
    scene.world = scene.world or bpy.data.worlds.new("W")
    cam_data = bpy.data.cameras.new("cam"); cam_data.type = "ORTHO"; cam_data.ortho_scale = 7.2
    cam = bpy.data.objects.new("cam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
    shots = {"front": (0, .3, -12), "three": (-8, 1.2, -9), "back": (0, .3, 12), "face": (0, 2.7, -12)}
    for key, (x, y, z) in shots.items():
        target = R(0, 2.6 if key == "face" else .2, 0)
        cam.location = R(x, y, z)
        cam_data.ortho_scale = 3.2 if key == "face" else 7.2
        direction = target - cam.location
        cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(out, "%s_%s.png" % (stem, key))
        bpy.ops.render.render(write_still=True)
    for o in list(bpy.data.objects):
        if o.name.startswith("StandIn") or o.name == "cam":
            bpy.data.objects.remove(o)

def clump(cap_center, cap_radii, az0, el0, az1, el1, width, thick, lift=.4, rings=12, sides=8, tip_curl=0.0, name="clump"):
    """An anime hair lock that lies on the skull: it follows the cap surface
    from (az0, el0) to (az1, el1) (degrees; az 0 = front, +90 = his right),
    flat (width across, thick off the surface), and lifts off toward its
    sharp tip by `lift` studs."""
    c = Vector(cap_center); rx, ry, rz = cap_radii
    def surf(az, el):
        a, e = math.radians(az), math.radians(el)
        n = Vector((math.sin(a) * math.cos(e) / rx, math.sin(e) / ry, -math.cos(a) * math.cos(e) / rz))
        p = c + Vector((rx * math.sin(a) * math.cos(e), ry * math.sin(e), -rz * math.cos(a) * math.cos(e)))
        return p, n.normalized()
    verts, faces = [], []
    centers = []
    for k in range(rings + 1):
        t = k / rings
        az = az0 + (az1 - az0) * t
        el = el0 + (el1 - el0) * t
        p, n = surf(az, el)
        centers.append((p, n, t))
    for k in range(rings):
        p, n, t = centers[k]
        q = centers[k + 1][0]
        tangent = (q - p).normalized()
        side = n.cross(tangent).normalized()
        nn = tangent.cross(side).normalized()
        r = (1 - t) ** .75 * (.55 + .45 * min(1, t * 6))
        mid = p + nn * (thick * .5 * r + lift * t * t) + tangent * 0
        for i in range(sides):
            a = 2 * math.pi * i / sides
            off = side * math.cos(a) * width * .5 * r + nn * math.sin(a) * thick * .5 * r
            verts.append(tuple(mid + off))
    p, n, t = centers[-1]
    tip = p + n * (lift + thick * .1) + (p - centers[-2][0]).normalized() * tip_curl
    verts.append(tuple(tip))
    for k in range(rings - 1):
        for i in range(sides):
            a, b = k * sides + i, k * sides + (i + 1) % sides
            faces.append((a, b, (k + 1) * sides + (i + 1) % sides, (k + 1) * sides + i))
    last = len(verts) - 1
    for i in range(sides):
        faces.append(((rings - 1) * sides + i, (rings - 1) * sides + (i + 1) % sides, last))
    faces.append(tuple(reversed(range(sides))))
    ob = _object(name, verts, faces)
    _outward(ob)
    return ob

# ---------------------------------------------------------------- the head
# One head shape for everything that touches it (user 29/10 14:52: "toujours
# un problème sur les cheveux et le bandeau"): a rounded box with a narrower
# chin. Bands, hair caps and masks are this same profile scaled out, so they
# can never cut through it or float off it. Shared/Face reads the same table.
# (y above the head centre, half-width, half-depth, squareness)
HEAD_PROFILE = [(-.95, .55, .56, 2.6), (-.82, .74, .74, 2.8), (-.55, .86, .83, 3.2), (-.2, .9, .86, 3.4),
                (.25, .9, .86, 3.4), (.6, .86, .83, 3.2), (.84, .72, .72, 2.8), (.95, .45, .46, 2.4)]

def head_section(y):
    P = HEAD_PROFILE
    if y <= P[0][0]:
        return P[0][1:]
    for (y0, a0, b0, n0), (y1, a1, b1, n1) in zip(P, P[1:]):
        if y <= y1:
            t = (y - y0) / (y1 - y0)
            return (a0 + (a1 - a0) * t, b0 + (b1 - b0) * t, n0 + (n1 - n0) * t)
    return P[-1][1:]

def head_loft(center, y0, y1, grow=0.0, steps=12, sides=48, cap_top=True, cap_bottom=True, dz=0.0, name="headloft"):
    """The head profile between heights y0..y1 (head space), grown outward by
    `grow` studs all round."""
    secs = []
    for k in range(steps + 1):
        y = y0 + (y1 - y0) * k / steps
        a, b, n = head_section(y)
        secs.append((y, a + grow, b + grow, n, dz))
    return loft(secs, sides=sides, center=center, cap_top=cap_top, cap_bottom=cap_bottom, name=name)

def head_point(center, x, y, out=0.0):
    """Front surface point of the head at (x across, y up), pushed `out`."""
    a, b, n = head_section(y)
    a += out; b += out
    t = min(.999, abs(x) / a)
    z = -b * (1 - t ** n) ** (1 / n)
    return Vector((center[0] + x, center[1] + y, center[2] + z))

def lock_path(points, outward, width, thick, sides=7, name="lock", taper=.8):
    """A flat lock along a polyline (Roblox space); `outward` gives, per point,
    the direction its flat face looks (away from the head)."""
    pts = [Vector(p) for p in points]
    verts, faces = [], []
    n = len(pts)
    for k in range(n - 1):
        t = k / (n - 1)
        tangent = (pts[k + 1] - pts[k]).normalized()
        o = Vector(outward(pts[k])).normalized()
        side = o.cross(tangent).normalized()
        nn = tangent.cross(side).normalized()
        r = (1 - t) ** taper * (.6 + .4 * min(1, t * 5))
        for i in range(sides):
            a = 2 * math.pi * i / sides
            verts.append(tuple(pts[k] + side * math.cos(a) * width * .5 * r + nn * (math.sin(a) + .6) * thick * .5 * r))
    verts.append(tuple(pts[-1]))
    for k in range(n - 2):
        for i in range(sides):
            a, b = k * sides + i, k * sides + (i + 1) % sides
            faces.append((a, b, (k + 1) * sides + (i + 1) % sides, (k + 1) * sides + i))
    last = len(verts) - 1
    for i in range(sides):
        faces.append(((n - 2) * sides + i, (n - 2) * sides + (i + 1) % sides, last))
    faces.append(tuple(reversed(range(sides))))
    ob = _object(name, verts, faces)
    _outward(ob)
    return ob

def head_panel(center, x0, x1, y0, y1, out0, out1, nx=12, ny=3, name="panel"):
    """A curved plate lying on the head front between two offsets."""
    verts, faces = [], []
    grid = []
    for layer, out in enumerate((out0, out1)):
        for j in range(ny + 1):
            for i in range(nx + 1):
                x = x0 + (x1 - x0) * i / nx
                y = y0 + (y1 - y0) * j / ny
                verts.append(tuple(head_point(center, x, y, out)))
    W = nx + 1
    L = W * (ny + 1)
    def idx(l, j, i): return l * L + j * W + i
    for j in range(ny):
        for i in range(nx):
            faces.append((idx(1, j, i), idx(1, j, i + 1), idx(1, j + 1, i + 1), idx(1, j + 1, i)))
            faces.append((idx(0, j, i), idx(0, j + 1, i), idx(0, j + 1, i + 1), idx(0, j, i + 1)))
    for i in range(nx):
        faces.append((idx(0, 0, i), idx(0, 0, i + 1), idx(1, 0, i + 1), idx(1, 0, i)))
        faces.append((idx(0, ny, i), idx(1, ny, i), idx(1, ny, i + 1), idx(0, ny, i + 1)))
    for j in range(ny):
        faces.append((idx(0, j, 0), idx(1, j, 0), idx(1, j + 1, 0), idx(0, j + 1, 0)))
        faces.append((idx(0, j, nx), idx(0, j + 1, nx), idx(1, j + 1, nx), idx(1, j, nx)))
    ob = _object(name, verts, faces)
    _outward(ob)
    return ob

def solidify_in(ob, thick):
    m = ob.modifiers.new("solid", "SOLIDIFY"); m.thickness = thick; m.offset = -1
    apply_modifiers(ob)
