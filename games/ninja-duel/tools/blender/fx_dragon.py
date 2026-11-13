"""Kakashi's dragons, modelled (13/11, user: « les dragons ça va pas trop,
cherche des modèles de dragons en 3D »). The free models found online are
western winged dragons, paid, or of unclear licence, and none can be
downloaded or uploaded from here; so the eastern dragon of the anime (the
Suiryūdan: a long serpent, a big open mouth, fangs, whiskers, horns, a mane)
is modelled here, from scratch, in Blender.

  python3 fx_dragon.py render OUT_DIR         preview (water and earth)
  python3 fx_dragon.py luau > src/Client/DragonMeshes.luau

The game builds the meshes at run time (AssetService:CreateEditableMesh, the
same way VfxKit builds its textures): nothing to upload. Three meshes per
dragon: HEAD (skull, upper jaw, horns, whiskers, mane, eyes), JAW (the lower
jaw and its fangs, hinged so it can open) and SEG (one body segment with its
dorsal fin and belly plates; the body is a chain of them following the path,
as before). Vertex colours carry the paint. Units: studs at size 1 (the game
scales by the look's width). Roblox frame: x right, y up, front -z.
"""
import bpy, bmesh, math, os, sys, random
from mathutils import Vector, Matrix, noise

STYLES = {
    "water": {"base": (0.33, 0.62, 0.95), "dark": (0.10, 0.30, 0.70), "belly": (0.80, 0.92, 1.0), "accent": (0.92, 0.98, 1.0),
              "eye": (0.95, 0.98, 1.0), "rough": 0.0},
    "earth": {"base": (0.55, 0.43, 0.30), "dark": (0.33, 0.25, 0.18), "belly": (0.66, 0.56, 0.42), "accent": (0.78, 0.70, 0.56),
              "eye": (1.0, 0.62, 0.20), "rough": 0.14},
}


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)


def paint(obj, fn):
    """Vertex colour per vertex: fn(co) -> (r,g,b)."""
    me = obj.data
    if not me.color_attributes:
        me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    attr = me.color_attributes["Col"]
    for v in me.vertices:
        c = fn(obj.matrix_world @ v.co)
        # stored as sRGB (what Roblox colours are); the preview converts
        attr.data[v.index].color = (c[0], c[1], c[2], 1)


def apply_all(obj):
    bpy.context.view_layer.objects.active = obj
    for m in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def roughen(obj, amount, scale=3.0, seed=0):
    if amount <= 0:
        return
    for v in obj.data.vertices:
        p = obj.matrix_world @ v.co
        n = noise.noise(p * scale + Vector((seed, seed * 2, seed * 3)))
        v.co += v.normal * n * amount
    # faceted rock: flat shading
    for f in obj.data.polygons:
        f.use_smooth = False


def tube(points, radii, ring=10, name="Tube"):
    """A tube along `points` (Blender coords) with per-point radii (rx, rz)."""
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(points):
        a = points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]
        t = a.normalized()
        up = Vector((0, 0, 1))
        side = t.cross(up).normalized()
        nup = side.cross(t).normalized()
        rx, rz = radii[i]
        rr = []
        for k in range(ring):
            th = 2 * math.pi * k / ring
            rr.append(bm.verts.new(p + side * math.cos(th) * rx + nup * math.sin(th) * rz))
        rings.append(rr)
    for i in range(len(rings) - 1):
        for k in range(ring):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % ring], rings[i + 1][(k + 1) % ring], rings[i + 1][k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    for f in me.polygons:
        f.use_smooth = True
    return ob


def cone(base, tip, r, segs=8, name="Cone", bend=None, steps=6):
    """A tapering horn/fang from base to tip (optionally bent toward `bend`)."""
    pts, rad = [], []
    for i in range(steps + 1):
        u = i / steps
        p = base.lerp(tip, u)
        if bend is not None:
            p = p + bend * math.sin(u * math.pi * .9) * .5 * u
        pts.append(p)
        rr = r * (1 - u * .96)
        rad.append((rr, rr))
    return tube(pts, rad, segs, name)


def skull(st):
    """The head (Blender coords: x right, y FRONT, z up): a long skull, the
    upper jaw tapering into a raised snout, brows, cheek fins."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, radius=1)
    ob = bpy.context.object
    ob.name = "Skull"
    for v in ob.data.vertices:
        x, y, z = v.co
        # length: front stretched long, back short
        y = y * (1.75 if y > 0 else .85)
        # snout: narrows and flattens toward the front, nose tip lifts
        f = max(0.0, y / 1.75)
        x *= 1 - .45 * f
        z *= 1 - .38 * f
        z += .18 * f * f
        # the underside is cut flat where the lower jaw sits
        if z < -.25:
            z = -.25 + (z + .25) * .35
        # brow ridges over the eyes
        if z > .35 and -.1 < y < .7:
            z += .12 * math.exp(-((abs(x) - .45) ** 2) / .04) * math.exp(-((y - .3) ** 2) / .08)
        v.co = Vector((x * .82, y, z * .78))
    apply_all(ob)
    return ob


def jaw(st):
    pts = [Vector((0, -.35, -.32)), Vector((0, .3, -.38)), Vector((0, .95, -.36)), Vector((0, 1.45, -.28))]
    rad = [(.55, .2), (.5, .18), (.36, .14), (.18, .09)]
    j = tube(pts, rad, 12, "Jaw")
    fangs = []
    for s in (-1, 1):
        for y, h in ((1.3, .28), (.95, .2), (.6, .16)):
            fangs.append(cone(Vector((s * .16 * (1.6 - y * .6), y, -.22)), Vector((s * .16 * (1.6 - y * .6), y + .04, -.22 + h)), .06, 6, "Fang"))
    tongue = tube([Vector((0, .1, -.24)), Vector((0, .8, -.25)), Vector((0, 1.15, -.18))], [(.22, .05), (.2, .05), (.1, .04)], 8, "Tongue")
    return j, fangs, tongue


def head_parts(st):
    parts = []
    sk = skull(st)
    parts.append(("skull", sk))
    for s in (-1, 1):
        # upper fangs
        for y, h in ((1.35, .32), (1.0, .22)):
            parts.append(("tooth", cone(Vector((s * .15 * (1.7 - y * .6), y, -.12)), Vector((s * .15 * (1.7 - y * .6), y + .03, -.12 - h)), .065, 6, "Tooth")))
        # horns: swept back and up, curving
        parts.append(("horn", cone(Vector((s * .32, -.1, .45)), Vector((s * .75, -1.9, 1.15)), .14, 8, "Horn", bend=Vector((s * .2, 0, .6)))))
        parts.append(("horn", cone(Vector((s * .52, -.3, .32)), Vector((s * 1.0, -1.3, .5)), .08, 6, "HornTine")))
        # whiskers: long, wavy, from the snout sides
        pts, rad = [], []
        for i in range(14):
            u = i / 13
            pts.append(Vector((s * (.32 + 1.3 * u), 1.2 - 1.8 * u, -.05 + .35 * math.sin(u * 5.5) * u)))
            rad.append((.045 * (1 - u * .85), .045 * (1 - u * .85)))
        parts.append(("whisker", tube(pts, rad, 6, "Whisker")))
        # cheek fins
        for k in range(3):
            parts.append(("fin", cone(Vector((s * .62, .05 - k * .25, -.05)), Vector((s * (1.15 + k * .1), -.35 - k * .35, -.1 + k * .1)), .12, 6, "CheekFin")))
        # eyes and their dark slit
        # a fierce almond eye, slanted, under a heavy brow
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=.17, location=(s * .45, .45, .36))
        e = bpy.context.object; e.scale = (.9, 1.7, .55); e.rotation_euler = (0, s * .25, s * -.35); apply_all(e); parts.append(("eye", e))
        bpy.ops.mesh.primitive_cube_add(size=1, location=(s * .52, .5, .37))
        sl = bpy.context.object; sl.scale = (.03, .04, .16); apply_all(sl); parts.append(("pupil", sl))
        parts.append(("brow", cone(Vector((s * .2, .78, .5)), Vector((s * .7, .05, .62)), .11, 6, "Brow")))
        # nostrils
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=.07, location=(s * .17, 1.62, .14))
        n = bpy.context.object; apply_all(n); parts.append(("pupil", n))
    # the mane: a fan of spikes down the back of the head
    for k in range(7):
        a = (k - 3) / 3
        parts.append(("mane", cone(Vector((a * .45, -.35, .45 - abs(a) * .2)), Vector((a * 1.1, -1.7 - (1 - abs(a)) * .5, .65 + (1 - abs(a)) * .35)), .16, 6, "Mane", bend=Vector((0, 0, .4)))))
    return parts


def colorize(parts, st, rough):
    for kind, ob in parts:
        if kind in ("skull", "jaw"):
            def fn(p, kind=kind):
                # belly-pale underside, dark ridge on top, base in between
                if p.z < -.15 or kind == "jaw":
                    return st["belly"]
                if p.z > .35 and abs(p.x) < .25:
                    return st["dark"]
                return st["base"]
            paint(ob, fn)
            roughen(ob, rough, 2.5, 1)
        elif kind in ("tooth", "fang"):
            paint(ob, lambda p: (.98, .98, .95))
        elif kind == "tongue":
            paint(ob, lambda p: (.85, .3, .38))
        elif kind == "eye":
            paint(ob, lambda p: st["eye"])
        elif kind == "pupil":
            paint(ob, lambda p: (.03, .03, .06))
        elif kind in ("horn", "mane", "fin", "brow"):
            paint(ob, lambda p, kind=kind: st["dark"] if kind in ("horn", "brow") else st["accent"])
            roughen(ob, rough * .5, 4, 2)
        elif kind == "whisker":
            paint(ob, lambda p: st["accent"])


def segment(st, rough):
    """One body segment, 1 long (along the path), radius .5, with a dorsal
    fin and a belly plate."""
    pts = [Vector((0, -.7, 0)), Vector((0, -.35, 0)), Vector((0, 0, 0)), Vector((0, .35, 0)), Vector((0, .7, 0))]
    body = tube(pts, [(.36, .33), (.47, .43), (.5, .46), (.47, .43), (.38, .35)], 16, "Seg")
    fin = cone(Vector((0, .1, .38)), Vector((0, -.45, 1.0)), .14, 6, "SegFin", bend=Vector((0, -.2, .1)))
    def fn(p):
        if p.z < -.2:
            return st["belly"]
        if p.z > .3:
            return st["dark"]
        return st["base"]
    paint(body, fn)
    roughen(body, rough, 3, 5)
    paint(fin, lambda p: st["accent"])
    return [("seg", body), ("fin", fin)]


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    ob = bpy.context.object
    ob.name = name
    return ob


def build(style):
    st = STYLES[style]
    rough = st["rough"]
    hp = head_parts(st)
    colorize(hp, st, rough)
    j, fangs, tongue = jaw(st)
    jp = [("jaw", j)] + [("fang", f) for f in fangs] + [("tongue", tongue)]
    colorize(jp, st, rough)
    sp = segment(st, rough)
    head = join([o for _, o in hp], style + "_HEAD")
    jaw_o = join([o for _, o in jp], style + "_JAW")
    seg = join([o for _, o in sp], style + "_SEG")
    return head, jaw_o, seg


def triangulate(ob):
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(ob.data); bm.free()


def export(ob):
    """Roblox frame (x, y up, front -z) vertices, triangles, per-vertex colour."""
    triangulate(ob)
    me = ob.data
    col = me.color_attributes["Col"].data
    vs = [(v.co.x, v.co.z, -v.co.y) for v in me.vertices]
    cs = [tuple(int(max(0, min(1, c)) * 255) for c in col[v.index].color[:3]) for v in me.vertices]
    flat = [not p.use_smooth for p in me.polygons]
    tris = [tuple(p.vertices) for p in me.polygons]
    return vs, tris, cs, flat


def luau():
    out = ["-- Generated by tools/blender/fx_dragon.py (13/11): Kakashi's dragons, modelled.",
           "-- Per style: head, jaw (hinge at its origin) and one body segment; v = vertices",
           "-- (studs at width 1, x right, y up, front -z), t = triangles (1-based), c = colours.",
           "return {"]
    for style in STYLES:
        clear()
        head, jaw_o, seg = build(style)
        out.append("\t%s={" % style)
        for key, ob in (("head", head), ("jaw", jaw_o), ("seg", seg)):
            vs, tris, cs, flat = export(ob)
            out.append("\t\t%s={flat=%s,v={%s}," % (key, "true" if any(flat) else "false", ",".join("%.3f,%.3f,%.3f" % v for v in vs)))
            out.append("\t\t\tt={%s}," % ",".join("%d,%d,%d" % (a + 1, b + 1, c + 1) for a, b, c in tris))
            out.append("\t\t\tc={%s}}," % ",".join("%d,%d,%d" % c for c in cs))
        out.append("\t},")
    out.append("}")
    return "\n".join(out) + "\n"


def render(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    S = bpy.context.scene
    for style in STYLES:
        clear()
        head, jaw_o, seg = build(style)
        # open the jaw a little, lay a chain of segments behind on a curve
        jaw_o.rotation_euler = (math.radians(-22), 0, 0)
        segs = []
        for i in range(10):
            s = seg.copy(); s.data = seg.data; bpy.context.collection.objects.link(s)
            k = 1 - i * .06
            s.scale = (k * 1.25, k * 1.25, k * 1.25)
            s.location = (math.sin(i * .6) * 1.1, -1.5 - i * 1.25, math.cos(i * .5) * .4 - .2)
            s.rotation_euler = (0, 0, math.cos(i * .6) * .5)
            segs.append(s)
        seg.hide_render = True
        mat = bpy.data.materials.new("vc"); mat.use_nodes = True
        nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
        a = nt.nodes.new("ShaderNodeVertexColor"); a.layer_name = "Col"
        g = nt.nodes.new("ShaderNodeGamma"); g.inputs[1].default_value = 2.2
        nt.links.new(a.outputs["Color"], g.inputs[0]); nt.links.new(g.outputs[0], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = .35 if style == "water" else .9
        for o in [head, jaw_o] + segs:
            o.data.materials.clear(); o.data.materials.append(mat)
        S.render.engine = "CYCLES"; S.cycles.device = "CPU"; S.cycles.samples = 16; S.cycles.use_denoising = False
        S.render.resolution_x, S.render.resolution_y = 520, 400
        w = S.world or bpy.data.worlds.new("W"); S.world = w; w.use_nodes = True
        w.node_tree.nodes["Background"].inputs[0].default_value = (.7, .75, .82, 1)
        sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sun.data.energy = 3.5
        sun.rotation_euler = (.6, .1, 2.4); bpy.context.collection.objects.link(sun)
        cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam")); bpy.context.collection.objects.link(cam); S.camera = cam
        for label, loc, tgt in (("34", (4.5, 5.5, 2.4), (0, -1.5, 0)), ("side", (8.5, -2, 1.2), (0, -3, 0))):
            cam.location = loc
            cam.rotation_euler = (Vector(tgt) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
            S.render.filepath = os.path.join(out_dir, "dragon_%s_%s.png" % (style, label))
            bpy.ops.render.render(write_still=True)
        print("rendered", style, len(head.data.polygons), len(jaw_o.data.polygons), len(seg.data.polygons), flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "luau":
        sys.stdout.write(luau())
    else:
        render(sys.argv[2])
