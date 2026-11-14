"""Konoha, the hub, in modelled pieces (14/11, François: the decor at the
level of the weapons and dragons; contract: docs/systems/HUB_DRESS.md).

  python3 konoha_models.py render OUT_DIR [names...]   preview renders
  python3 konoha_models.py write ../../src/Client      HubMeshData + chunks

Same chain as fx_models.py (nd_mesh pieces, packed, built at run time by
Client/MeshKit). Everything is modelled here in the ROBLOX frame (x, y up, z;
studs) because the unique pieces sit at Hub.luau's coordinates (relative to
HubMap.Origin) and the repeated ones in their own frame; `blender()` turns a
piece into nd_mesh's Blender frame (x, y = Roblox -z, z up) for the export.
Architecture is flat-shaded, one material per piece; the detail is geometry
and vertex colours (grime at the foot of walls, varied tiles), no UVs.
Art direction: modern anime, not cartoon; little white, more detail; tiles,
beams, rafters under the eaves, paper lanterns, weathered wood. No logos.
"""
import math, os, sys, random
import bpy  # (also brings mathutils)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Vector, Matrix, noise
from nd_mesh import Piece, rgb, lerp, smooth, loft, tube, ellipsoid, torus, model_luau, stats

# ---------------------------------------------------------------- palette
# Hub.luau's colours, a little darker and less white (« moins de blanc »).
C = {
    "plaster": rgb(196, 186, 166), "plasterWarm": rgb(204, 182, 150), "plasterGreen": rgb(172, 182, 154),
    "wood": rgb(112, 78, 50), "woodDark": rgb(70, 48, 32), "woodLight": rgb(150, 112, 74), "woodGrey": rgb(118, 108, 96),
    "red": rgb(160, 52, 38), "redDark": rgb(118, 36, 28), "green": rgb(92, 120, 80),
    "roofBlue": rgb(64, 84, 120), "roofGreen": rgb(70, 100, 80), "roofTerra": rgb(150, 80, 54), "roofDark": rgb(58, 62, 64),
    "roofTile": rgb(56, 68, 66), "stone": rgb(160, 156, 148), "stoneDark": rgb(104, 100, 96), "rock": rgb(138, 122, 104),
    "rockDark": rgb(100, 88, 76), "cloth": rgb(224, 218, 204), "lantern": rgb(196, 58, 42), "black": rgb(36, 38, 42),
    "leaf": rgb(64, 102, 54), "leafDark": rgb(46, 80, 42), "leafLight": rgb(92, 128, 66), "bark": rgb(88, 64, 46),
    "paper": rgb(232, 214, 176), "iron": rgb(58, 58, 62), "rope": rgb(150, 122, 82), "water": rgb(70, 104, 118),
}


def jitter(c, p, amount=.06, f=.7):
    n = noise.noise(Vector(p) * f)
    return tuple(max(0, min(1, x * (1 + n * amount * 2))) for x in c)


def grime(c, p, base=0.0, height=2.2, k=.38):
    """Darker at the foot of a wall (splashes, dirt), fading up."""
    t = 1 - smooth((p.y - base) / height)
    return lerp(c, (c[0] * .45, c[1] * .42, c[2] * .38), t * k)


# ---------------------------------------------------------------- transforms (Roblox frame)
def T(x, y=0, z=0):
    return Matrix.Translation((x, y, z))


def Rx(a):
    return Matrix.Rotation(a, 4, "X")


def Ry(a):
    return Matrix.Rotation(a, 4, "Y")


def Rz(a):
    return Matrix.Rotation(a, 4, "Z")


def colour(col, p, face):
    return col(p, face) if callable(col) else col


def box(pc, m, size, col, cell=0.0, top=True, bottom=False):
    """A box of `size` round the transform m. Each face is its own grid (flat
    shading); `cell` > 0 subdivides big faces so the vertex colours can carry
    grime and variation. col(p_world, face_name) or a colour."""
    sx, sy, sz = size[0] / 2, size[1] / 2, size[2] / 2
    faces = {
        "px": (Vector((sx, 0, 0)), Vector((0, 0, -sz)), Vector((0, sy, 0))),
        "nx": (Vector((-sx, 0, 0)), Vector((0, 0, sz)), Vector((0, sy, 0))),
        "pz": (Vector((0, 0, sz)), Vector((sx, 0, 0)), Vector((0, sy, 0))),
        "nz": (Vector((0, 0, -sz)), Vector((-sx, 0, 0)), Vector((0, sy, 0))),
        "py": (Vector((0, sy, 0)), Vector((sx, 0, 0)), Vector((0, 0, -sz))),
        "ny": (Vector((0, -sy, 0)), Vector((sx, 0, 0)), Vector((0, 0, sz))),
    }
    for name, (c, u, v) in faces.items():
        if name == "py" and not top:
            continue
        if name == "ny" and not bottom:
            continue
        nu = max(1, int(round(u.length * 2 / cell))) if cell else 1
        nv = max(1, int(round(v.length * 2 / cell))) if cell else 1
        nu, nv = min(nu, 24), min(nv, 24)
        idx = []
        for j in range(nv + 1):
            row = []
            for i in range(nu + 1):
                lp = c + u * (2 * i / nu - 1) + v * (2 * j / nv - 1)
                wp = m @ lp
                row.append(pc.add(wp, colour(col, wp, name)))
            idx.append(row)
        for j in range(nv):
            for i in range(nu):
                pc.face(idx[j][i], idx[j][i + 1], idx[j + 1][i + 1], idx[j + 1][i])


def cyl(pc, m, r, h, col, sides=10, r2=None, cap=True):
    """A cylinder along y (base at 0, top at h) under transform m."""
    r2 = r if r2 is None else r2
    rings = []
    for y, rr in ((0, r), (h, r2)):
        rings.append([m @ Vector((math.cos(a) * rr, y, math.sin(a) * rr)) for a in [i / sides * math.tau for i in range(sides)]])
    loft(pc, rings, col if not callable(col) else (lambda p, k: col(p, k)), cap0=cap, cap1=cap)


def prism(pc, pts2d, m, depth, col):
    """An extruded polygon (x, y points) along z (-depth/2..depth/2) under m."""
    a = [m @ Vector((x, y, -depth / 2)) for x, y in pts2d]
    b = [m @ Vector((x, y, depth / 2)) for x, y in pts2d]
    loft(pc, [a, b], col)


# ---------------------------------------------------------------- the house kit
def tiled_roof(tiles, under, m, w, d, pitch=24, over=1.6, along="z", color=None, thick=.9, rib=1.3, course=1.5, tiles2=None):
    """Hub.roof(): two slopes from a ridge over a w (x) by d (z) body whose top
    is at m's origin, the slabs .9 thick centred on the slope line, an
    overhang `over`. Modelled: courses of round tiles (ribs down the slope,
    a step at each course), the ridge capped, rafter ends under the eaves,
    the gables closed by boarded triangles."""
    color = color or C["roofTile"]
    p = math.radians(pitch)
    span = d if along == "x" else w
    length = (w if along == "x" else d) + over * 2
    half = span / 2 + over
    rise = math.tan(p) * half
    slope = half / math.cos(p)
    rng = random.Random(int(w * 7 + d * 3))
    # local frame: s across the span (-half..half), L along the ridge
    def to(s, L, up):
        y = rise - abs(s) * math.tan(p) + up
        return m @ (Vector((s, y, L)) if along == "z" else Vector((L, y, s)))
    nrib = int(length / rib)
    for side in (-1, 1):
        tl = tiles2 if (tiles2 is not None and side > 0) else tiles
        ncourse = max(2, int(slope / course))
        for ci in range(ncourse):
            s0 = side * half * ci / ncourse
            s1 = side * half * (ci + 1) / ncourse
            for ri in range(nrib):
                L0 = -length / 2 + ri * rib
                L1 = L0 + rib
                tone = jitter(color, (ri * 3.1, ci * 1.7, side), .12, 1.3)
                tone = lerp(tone, rgb(30, 32, 34), .25 * (ri % 2))
                # a tile: a low arched strip whose lower edge lifts (the step)
                lift = .14 * course / 1.1
                pts = []
                for k in range(4):
                    u = k / 3  # (arched: 3 strips)
                    L = L0 + (L1 - L0) * u
                    arch = .12 * rib / .9 * math.sin(u * math.pi)
                    pts.append((L, arch))
                ring0 = [to(s0, L, thick / 2 + a) for L, a in pts]
                ring1 = [to(s1, L, thick / 2 + a + lift) for L, a in pts]
                idx0 = [tl.add(v, tone) for v in ring0]
                idx1 = [tl.add(v, lerp(tone, (0, 0, 0), .3)) for v in ring1]
                for k in range(3):
                    tl.face(idx0[k], idx0[k + 1], idx1[k + 1], idx1[k])
                # the lip under the step
                lo = [to(s1, pts[0][0], thick / 2), to(s1, pts[-1][0], thick / 2)]
                idx2 = [tl.add(v, rgb(24, 26, 28)) for v in lo]
                tl.face(idx1[0], idx1[3], idx2[1], idx2[0])
        # the slab under the tiles (its underside shows under the eaves)
        a = [to(0, -length / 2, -thick / 2), to(0, length / 2, -thick / 2), to(side * half, length / 2, -thick / 2), to(side * half, -length / 2, -thick / 2)]
        b = [to(0, -length / 2, thick / 2), to(0, length / 2, thick / 2), to(side * half, length / 2, thick / 2), to(side * half, -length / 2, thick / 2)]
        loft(under, [a, b], C["woodDark"])
        # rafter ends under the eave
        for ri in range(int(length / 1.3)):
            L = -length / 2 + .65 + ri * 1.3
            if abs(L) > length / 2 - .4:
                continue
            e0 = to(side * (half - 1.4), L, -thick / 2 - .05)
            e1 = to(side * (half - .05), L, -thick / 2 - .05)
            dv = (e1 - e0)
            mm = Matrix.Translation((e0 + e1) / 2) @ (dv.to_track_quat("Y", "Z").to_matrix().to_4x4())
            box(under, mm, (.32, dv.length, .32), lerp(C["wood"], C["woodDark"], .4))
    # ridge cap: a row of round caps
    for ri in range(int(length / (.8 * rib / .9)) + 1):
        L = -length / 2 + ri * .8 * rib / .9
        c = to(0, L, thick / 2 + .25)
        ellipsoid(tiles, c, (.55 * rib / .9, .35 * rib / .9, .45 * rib / .9), jitter(rgb(40, 44, 46), (L, 0, 0), .1), seg=6, rings=3)
    # gables: boarded triangles with a beam under
    for end in (-1, 1):
        Lg = end * ((w if along == "x" else d) / 2 - .3)
        tri = [to(-span / 2, Lg, -thick / 2), to(span / 2, Lg, -thick / 2), to(0, Lg, -thick / 2 - .02)]
        tri[2] = m @ (Vector((0, rise - .2, Lg)) if along == "z" else Vector((Lg, rise - .2, 0)))
        tri[0] = m @ (Vector((-span / 2, 0, Lg)) if along == "z" else Vector((Lg, 0, -span / 2)))
        tri[1] = m @ (Vector((span / 2, 0, Lg)) if along == "z" else Vector((Lg, 0, span / 2)))
        off = (Vector((0, 0, end * .3)) if along == "z" else Vector((end * .3, 0, 0)))
        back = [v - off for v in tri]
        loft(under, [back, tri], lambda q, k: lerp(C["woodDark"], C["wood"], .3 + .2 * math.sin(q.x * 3 + q.z * 3)))
    return rise


def wall_col(base):
    def f(p, face):
        c = jitter(base, p, .05, .35)
        return grime(c, p, 0, 2.6, .45)
    return f


def window(frame, glass, m, w=3.2, h=2.6):
    """A window set in the wall (m: its centre, facing +x): a dark recess, a
    frame, a wooden lattice (shōji grid)."""
    box(glass, m @ T(-.02, 0, 0), (.1, h, w), rgb(48, 44, 40))
    for y in (-h / 2, h / 2):
        box(frame, m @ T(.1, y, 0), (.25, .22, w + .4), C["woodDark"])
    for z in (-w / 2, w / 2):
        box(frame, m @ T(.1, 0, z), (.25, h + .2, .22), C["woodDark"])
    box(frame, m @ T(.12, -h / 2 - .2, 0), (.5, .16, w + .6), C["wood"])
    for k in range(1, 4):
        box(frame, m @ T(.07, 0, -w / 2 + w * k / 4), (.08, h, .08), C["woodLight"])
    box(frame, m @ T(.07, 0, 0), (.08, .08, w), C["woodLight"])


def paper_lantern(pc, cap, m, w=1.6, h=2.2, color=None):
    """A paper lantern: ribbed, bulging, a black cap and foot, centred at m."""
    color = color or C["lantern"]
    rings = []
    n = 9
    for j in range(n):
        v = j / (n - 1)
        y = -h / 2 + h * v
        r = (w / 2) * (.62 + .38 * math.sin(v * math.pi))
        rings.append([m @ Vector((math.cos(a) * r, y, math.sin(a) * r)) for a in [i / 14 * math.tau for i in range(14)]])
    loft(pc, rings, lambda p, k: lerp(color, rgb(250, 220, 160), .18 * (k % 2)))
    for y in (h / 2, -h / 2):
        cyl(cap, m @ T(0, y - .08, 0), w * .34, .18, C["black"], sides=10)


def door(frame, m, w=3.6, h=6.4, color=None):
    """A sliding wooden door with its frame and panels (m: centre of its foot, facing +x)."""
    color = color or C["woodDark"]
    box(frame, m @ T(0, h / 2, 0), (.16, h, w), color)
    for z in (-w / 4, w / 4):
        for y in (h * .3, h * .72):
            box(frame, m @ T(.1, y, z), (.06, h * .3, w * .36), lerp(color, C["wood"], .3))
    box(frame, m @ T(.12, h + .2, 0), (.35, .4, w + .8), C["wood"])
    for z in (-w / 2 - .2, w / 2 + .2):
        box(frame, m @ T(.12, h / 2, z), (.35, h + .4, .4), C["wood"])


def noren(cloth, m, color, n=3, w=1.1, h=2.2):
    """The split curtain over a door (m: its top centre, facing +x)."""
    for k in range(n):
        z = (k - (n - 1) / 2) * (w + .08)
        rows = []
        for j in range(6):
            v = j / 5
            sway = .05 * math.sin(v * 3 + k)
            rows.append([m @ Vector((sway, -h * v, z - w / 2)), m @ Vector((sway, -h * v, z + w / 2))])
        loft(cloth, rows, lambda p, kk: lerp(color, rgb(20, 20, 24), .15 * (kk / 6)), closed=False, cap0=False, cap1=False)
    box(cloth, m @ T(0, .1, 0), (.12, .12, n * (w + .08) + .4), C["woodDark"])


def house(kind, w, d, floors):
    """The repeated houses: origin at the centre of the foot, the street face
    to +x, the ridge along z. Walls w x 8*floors x d."""
    rng = random.Random(hash((kind, w, d, floors)) & 0xffff)
    h = 8 * floors
    base = {"Gable": C["plaster"], "Shop": C["plasterWarm"], "Back": C["plasterWarm"], "Uchiha": C["plaster"], "Flat": C["plasterGreen"]}[kind]
    walls = Piece("Walls", "Concrete", flat=True)
    timber = Piece("Timber", "Wood", flat=True)
    glass = Piece("Openings", "SmoothPlastic", flat=True)
    roofp = Piece("Tiles", "Slate", flat=True)
    under = Piece("Eaves", "Wood", flat=True)
    cloth = Piece("Cloth", "Fabric", flat=True)
    lamp = Piece("Lantern", "Fabric")
    caps = Piece("LanternCap", "SmoothPlastic")
    I = Matrix.Identity(4)
    box(walls, T(0, h / 2, 0), (w, h, d), wall_col(base), cell=2.0)
    # a stone plinth and the timber frame: sills, floor bands, posts, braces
    box(timber, T(0, .5, 0), (w + .3, 1, d + .3), lambda p, f: grime(C["stoneDark"], p, 0, 1, .3))
    for fl in range(1, floors):
        box(timber, T(0, fl * 8, 0), (w + .3, .6, d + .3), C["wood"])
    box(timber, T(0, h - .25, 0), (w + .3, .5, d + .3), C["woodDark"])
    for sx in (-1, 1):
        for sz in (-1, 1):
            box(timber, T(sx * w / 2, h / 2, sz * d / 2), (.9, h, .9), lambda p, f: grime(C["wood"], p, 0, 2, .4))
        for zz in (-d / 4, d / 4):
            box(timber, T(sx * (w / 2 + .05), h / 2, zz), (.3, h, .5), C["woodDark"])
    # windows on every face; the street face keeps the door's place
    for fl in range(floors):
        y = fl * 8 + 4.4
        for z in (-d / 4, d / 4):
            if fl == 0 and kind not in ("Back",) and abs(z) < 1:
                continue
            window(timber, glass, T(w / 2 + .06, y, z), 3.2, 2.6)
        window(timber, glass, T(-w / 2 - .06, y, d / 4) @ Ry(math.pi), 3.0, 2.4)
        window(timber, glass, T(-w / 2 - .06, y, -d / 4) @ Ry(math.pi), 3.0, 2.4)
        for x in (-w / 4, w / 4):
            window(timber, glass, T(x, y, d / 2 + .06) @ Ry(-math.pi / 2), 3.0, 2.4)
            window(timber, glass, T(x, y, -d / 2 - .06) @ Ry(math.pi / 2), 3.0, 2.4)
    if kind not in ("Back",):
        door(timber, T(w / 2 + .08, 0, 0))
        paper_lantern(lamp, caps, T(w / 2 + .9, 6, 2.6), 1.4, 1.9)
        box(timber, T(w / 2 + .5, 7.2, 2.6), (1.2, .2, .2), C["woodDark"])
    if kind == "Shop":
        noren(cloth, T(w / 2 + .3, 6.4, 0), C["roofBlue"])
    if kind == "Uchiha":
        box(timber, T(0, h + .2, 0), (w + .6, .4, d + .6), C["redDark"])
    pieces = [walls, timber, glass]
    if kind == "Flat":
        top = h + 1.0
        box(roofp, T(0, h + .5, 0), (w + 1.2, 1, d + 1.2), lambda p, f: jitter(C["roofDark"], p, .08, .5), cell=2.4)
        # the low decorative lip round the edge (no taller than .5: they run here)
        for sx, sz, lx, lz in ((0, 1, w + 1.6, .4), (0, -1, w + 1.6, .4), (1, 0, .4, d + 1.6), (-1, 0, .4, d + 1.6)):
            box(timber, T(sx * (w + 1.2) / 2, top + .2, sz * (d + 1.2) / 2), (lx, .4, lz), C["woodDark"])
        # gravel, a vent, a hatch on the roof: things a runner jumps over
        box(timber, T(-w / 4, top + .35, d / 5), (1.6, .7, 1.6), C["woodGrey"])
        box(timber, T(w / 5, top + .1, -d / 4), (2.4, .2, 2.0), C["wood"])
        pieces += [roofp]
    else:
        tiled_roof(roofp, under, T(0, h, 0), w, d, 24, 1.6, "z", {"Gable": C["roofBlue"], "Shop": C["roofTerra"], "Back": C["roofDark"], "Uchiha": C["roofDark"]}[kind])
        pieces += [roofp, under]
    if cloth.v:
        pieces.append(cloth)
    if lamp.v:
        pieces += [lamp, caps]
    return pieces


# ---------------------------------------------------------------- street furniture
def lantern_model():
    pc = Piece("Paper", "Fabric")
    cap = Piece("Cap", "SmoothPlastic", flat=True)
    paper_lantern(pc, cap, T(0, 0, 0), 1.6, 2.2)
    cyl(cap, T(0, 1.1, 0), .12, .5, C["iron"], sides=6)
    return [pc, cap]


def lamp_post():
    wood = Piece("Post", "Wood", flat=True)
    box(wood, T(0, 3.5, 0), (.6, 7, .6), lambda p, f: grime(jitter(C["woodDark"], p, .08, 2), p, 0, 1.5))
    box(wood, T(0, .25, 0), (1.0, .5, 1.0), C["stoneDark"])
    # the iron hook the lantern hangs from (its centre at y 7.6, on the post)
    box(wood, T(0, 7.1, 0), (.8, .2, .8), C["woodDark"])
    box(wood, T(0, 8.05, 0), (.1, 1.9, .1), C["iron"])
    box(wood, T(0, 9.0, 0), (.5, .12, .12), C["iron"])
    return [wood]


def stone_lantern():
    st = Piece("Stone", "Slate", flat=True)
    sc = lambda p, f: grime(jitter(C["stone"], p, .1, 1.5), p, 0, 1.6, .4)
    box(st, T(0, .3, 0), (2.6, .6, 2.6), sc)
    cyl(st, T(0, .6, 0), .55, 1.8, sc, sides=8)
    box(st, T(0, 2.7, 0), (2.0, .5, 2.0), sc)
    box(st, T(0, 3.8, 0), (1.6, 1.7, 1.6), sc)
    win = Piece("Light", "Neon", flat=True)
    for a in range(4):
        box(win, T(0, 3.8, 0) @ Ry(a * math.pi / 2) @ T(.81, 0, 0), (.04, .9, .8), rgb(255, 196, 120))
    # the roof: 3.6 wide at y 5.4, curved up at the corners
    rings = []
    for y, r, lift in ((5.0, 2.55, .25), (5.6, 1.4, 0), (6.1, .3, 0)):
        rings.append([Vector((math.cos(a) * r, y + lift * abs(math.cos(2 * a)), math.sin(a) * r)) for a in [i / 8 * math.tau + math.pi / 8 for i in range(8)]])
    loft(st, rings, lambda p, k: jitter(C["stoneDark"], p, .1, 1.5), tip1=Vector((0, 6.4, 0)))
    ellipsoid(st, (0, 6.5, 0), (.3, .3, .3), C["stoneDark"], seg=6, rings=4)
    return [st, win]


def bench():
    wd = Piece("Wood", "Wood", flat=True)
    for k in range(4):
        box(wd, T(0, 1.6 + .02 * (k % 2), -.9 + k * .6), (8, .25, .5), jitter(C["wood"], (k, 0, 0), .1))
    for x in (-3, 3):
        box(wd, T(x, .7, 0), (.5, 1.4, 2.0), C["woodDark"])
        box(wd, T(x, .3, 0), (.6, .2, 2.2), C["woodDark"])
    return [wd]


def crate():
    wd = Piece("Planks", "Wood", flat=True)
    for k in range(5):
        y = -2 + .8 * k + .4
        for f, m in (("px", T(2, y, 0)), ("nx", T(-2, y, 0))):
            box(wd, m, (.1, .74, 4), jitter(C["woodLight"], (k, 1, 0), .14))
        for m in (T(0, y, 2), T(0, y, -2)):
            box(wd, m, (4, .74, .1), jitter(C["woodLight"], (k, 2, 0), .14))
    box(wd, T(0, 1.95, 0), (4, .1, 4), C["woodLight"])
    box(wd, T(0, -1.95, 0), (4, .1, 4), C["woodDark"])
    for sx in (-1, 1):
        for sz in (-1, 1):
            box(wd, T(sx * 1.9, 0, sz * 1.9), (.35, 4.1, .35), C["wood"])
    for sz in (-1, 1):
        mm = T(0, 0, sz * 2.06) @ Rz(math.atan2(4, 4))
        box(wd, mm, (5.4, .4, .12), C["wood"])
    return [wd]


def stump():
    wd = Piece("Bark", "Wood", flat=True)
    rings = []
    for y in (0, 2.5, 5):
        rings.append([Vector((math.cos(a) * (1.5 + .1 * math.sin(a * 7)) * (1.12 if y == 0 else 1), y, math.sin(a) * (1.5 + .1 * math.sin(a * 7)) * (1.12 if y == 0 else 1))) for a in [i / 16 * math.tau for i in range(16)]])
    loft(wd, rings, lambda p, k: jitter(C["bark"], p, .12, 3), cap1=False)
    top = Piece("Cut", "Wood")
    rr = [[Vector((math.cos(a) * r, 5.01, math.sin(a) * r)) for a in [i / 16 * math.tau for i in range(16)]] for r in (1.5, 1.0, .5)]
    loft(top, rr, lambda p, k: lerp(rgb(196, 160, 112), rgb(160, 120, 80), .5 + .5 * math.sin(math.hypot(p.x, p.z) * 14)), cap0=False, tip1=Vector((0, 5.01, 0)))
    # gashes of practice blows
    for k in range(3):
        box(wd, T(0, 2 + k * .9, 0) @ Ry(k * 1.3) @ T(1.55, 0, 0) @ Rx(.3), (.12, .1, .9), rgb(196, 160, 112))
    return [wd, top]


def fence():
    wd = Piece("Wood", "Wood", flat=True)
    col = lambda p, f: grime(jitter(C["wood"], p, .1, 2), p, 0, 1, .3)
    box(wd, T(0, 2.4, 0), (8, .5, .4), col)
    box(wd, T(0, 1.2, 0), (8, .35, .3), col)
    box(wd, T(-4, 1.5, 0), (.6, 3, .6), lambda p, f: grime(C["woodDark"], p, 0, 1, .3))
    ellipsoid(wd, (-4, 3.05, 0), (.32, .12, .32), C["woodDark"], seg=6, rings=3)
    return [wd]


def village_wall(height):
    """A segment of wall along z (10 long, 2 thick), plaster on a stone
    footing, a tiled coping 3 wide x .8 on top."""
    pl = Piece("Plaster", "Concrete", flat=True)
    tiles = Piece("Coping", "Slate", flat=True)
    box(pl, T(0, height / 2, 0), (2, height, 10), wall_col(C["plasterWarm"] if height > 20 else C["plaster"]), cell=2.0)
    box(pl, T(0, .8, 0), (2.3, 1.6, 10), lambda p, f: jitter(C["stoneDark"], p, .12, 1.2), cell=2.0)
    for y in (height * .55,):
        box(pl, T(0, y, 0), (2.15, .4, 10), C["woodDark"])
    box(tiles, T(0, height + .2, 0), (3, .4, 10.02), C["roofTile"])
    for k in range(13):
        z = -5 + k * .8 + .4
        for s in (-1, 1):
            box(tiles, T(s * .75, height + .55, z) @ Rz(s * -.35), (1.6, .25, .7), jitter(C["roofTile"], (k, s, 0), .15, 1))
    box(tiles, T(0, height + .75, 0), (.6, .35, 10.02), rgb(40, 44, 46))
    return [pl, tiles]


def ladder():
    wd = Piece("Wood", "Wood", flat=True)
    for x in (-.85, .85):
        box(wd, T(x, 0, 0), (.3, 16, .3), lambda p, f: jitter(C["woodLight"], p, .1, 1))
    for k in range(16):
        box(wd, T(0, -7.5 + k, 0), (1.7, .16, .2), C["woodLight"])
        box(wd, T(0, -7.5 + k, 0), (1.9, .1, .26), C["rope"]) if k % 4 == 0 else None
    return [wd]


def water_tank():
    """A wooden tank of radius 3, 5 high, on legs of 2: staves, iron hoops, a lid."""
    wd = Piece("Staves", "Wood", flat=True)
    ir = Piece("Hoops", "Metal")
    for x in (-2, 2):
        for z in (-2, 2):
            box(wd, T(x, 1, z), (.6, 2, .6), C["woodDark"])
    box(wd, T(0, 2.1, 0), (6.2, .3, .5), C["woodDark"])
    box(wd, T(0, 2.1, 0), (.5, .3, 6.2), C["woodDark"])
    n = 28
    for i in range(n):
        a = i / n * math.tau
        box(wd, T(math.cos(a) * 2.88, 4.5, math.sin(a) * 2.88) @ Ry(-a), (.26, 5, .66), jitter(C["woodLight"], (i, 0, 0), .15, 1.3))
    for y in (2.8, 4.5, 6.3):
        cyl(ir, T(0, y, 0), 3.06, .22, C["iron"], sides=24, cap=False)
    rings = [[Vector((math.cos(a) * r, y, math.sin(a) * r)) for a in [i / 16 * math.tau for i in range(16)]] for y, r in ((7.0, 3.1), (7.6, 1.6))]
    loft(wd, rings, C["woodDark"], tip1=Vector((0, 7.9, 0)))
    return [wd, ir]


def tree(variant):
    """Origin at the foot of the trunk: height 14, trunk ~2.2 across, the crown
    centred near y 15, radius 6..9. Leaves are clusters of faceted clumps
    (no balls): an anime tree, its trunk curving, roots on the ground."""
    rng = random.Random(variant * 13 + 5)
    bark = Piece("Trunk", "Wood", flat=True)
    leaves = Piece("Leaves", "Grass", flat=True)
    lean = Vector((rng.uniform(-.8, .8), 0, rng.uniform(-.8, .8)))
    pts = [Vector((0, 0, 0)) + lean * (u * u) + Vector((0, 14 * u, 0)) for u in [i / 8 for i in range(9)]]
    tube(bark, pts, lambda k: 1.15 * (1 - .45 * k) + .1, lambda p, k: jitter(C["bark"], p, .14, 2.5), sides=9)
    for k in range(5):
        a = k / 5 * math.tau + rng.uniform(0, .6)
        tube(bark, [Vector((math.cos(a) * .6, .8, math.sin(a) * .6)), Vector((math.cos(a) * 1.6, .2, math.sin(a) * 1.6)), Vector((math.cos(a) * 2.4, -.1, math.sin(a) * 2.4))],
             lambda kk: .45 * (1 - kk) + .05, C["bark"], sides=5)
    top = pts[-1]
    for k in range(4):
        a = k / 4 * math.tau + rng.uniform(0, 1)
        b0 = pts[5 + k % 3]
        tube(bark, [b0, b0 + Vector((math.cos(a) * 2.5, 2.2, math.sin(a) * 2.5)), b0 + Vector((math.cos(a) * 4.5, 3.4, math.sin(a) * 4.5))],
             lambda kk: .45 * (1 - kk) + .08, C["bark"], sides=5)
    shades = (C["leafDark"], C["leaf"], C["leafLight"])
    n = {1: 15, 2: 12, 3: 18}[variant]
    for k in range(n):
        u = rng.random()
        a = rng.uniform(0, math.tau)
        r = rng.uniform(0, 1) ** .5
        cx = top.x + math.cos(a) * r * 5.6
        cz = top.z + math.sin(a) * r * 5.6
        cy = 15 + rng.uniform(-2.2, 2.8) - r * 1.6 + (1.5 if variant == 3 else 0)
        s = rng.uniform(2.2, 3.6) * (1.15 if variant == 2 else 1)
        tone = shades[min(2, int((cy - 12) / 3 + rng.random()))]
        ellipsoid(leaves, (cx, cy, cz), (s, s * .72, s), lambda p, kk, tone=tone: lerp(jitter(tone, p, .12, .9), C["leafDark"], .35 * smooth((15 - p.y) / 4)),
                  seg=8, rings=5, bump=lambda d, k=k: .3 * noise.noise(d * 2.2 + Vector((k, k * .3, 1))))
    return [bark, leaves]



# ---------------------------------------------------------------- unique pieces (Hub.luau coordinates, origin = HubMap.Origin)
def wood(p, f=None, base=None):
    return grime(jitter(base or C["wood"], p, .1, 1.4), p, 0, 1.8, .35)


def konoha_gate():
    """Piers, feet, beam, roof, the two open doors. GatePlate (y 38, z 202.7,
    14 x 4.2) stays a Part: its place in front of the beam is left free."""
    red = Piece("Lacquer", "Wood", flat=True)
    stone = Piece("Stone", "Slate", flat=True)
    doors = Piece("Doors", "Wood", flat=True)
    iron = Piece("Iron", "Metal", flat=True)
    tiles_a = Piece("TilesN", "Slate", flat=True)
    tiles_b = Piece("TilesS", "Slate", flat=True)
    under = Piece("Eaves", "Wood", flat=True)
    rc = lambda p, f: grime(jitter(C["red"], p, .06, .6), p, 0, 4, .45)
    for x in (-21, 21):
        box(red, T(x, 22, 206), (6, 44, 6), rc, cell=3)
        box(stone, T(x, 1.5, 206), (7.4, 3, 7.4), lambda p, f: grime(jitter(C["stone"], p, .12, 1), p, 0, 1.5, .4))
        box(stone, T(x, 3.3, 206), (6.6, .6, 6.6), C["stoneDark"])
        for y in (14, 30):
            box(iron, T(x, y, 206), (6.3, .7, 6.3), C["iron"])
        # bracket arms (masugumi) under the beam
        for sz in (-1, 1):
            box(red, T(x, 39, 206 + sz * 3.6), (2, 1.2, 1.4), C["redDark"])
            box(red, T(x, 40.2, 206 + sz * 4.4), (3, 1.0, 1.2), C["redDark"])
    box(red, T(0, 42.5, 206), (54, 5, 6), rc, cell=3)
    box(red, T(0, 37.2, 206), (44, 1.4, 4.4), C["redDark"])
    for x in (-14, 14):
        box(red, T(x, 38.4, 206), (1.2, 1.2, 4.8), C["redDark"])
    box(stone, T(0, 45.4, 206), (60, .6, 10), C["woodDark"])
    tiled_roof(tiles_a, under, T(0, 45.6, 206), 54, 6.5, 16, 3.0, "x", C["roofTile"], thick=.8, rib=1.6, course=1.6, tiles2=tiles_b)
    for side in (-1, 1):
        hinge = T(side * 18, 19, 206)
        dc = lambda p, f: jitter(C["green"], p, .08, .8)
        box(doors, hinge @ T(0, 0, -9), (1.4, 36, 18), dc, cell=3)
        for y in (-14, -8, 0, 8, 14):
            box(iron, hinge @ T(0, y, -9), (1.6, .8, 18.2), C["woodDark"])
        for zz in range(6):
            for y in (-8, 8):
                ellipsoid(iron, (side * 18 + (.85 if side < 0 else -.85), 19 + y, 206 - 1.5 - zz * 3), (.25, .25, .25), C["iron"], seg=5, rings=3)
    return [red, stone, doors, iron, tiles_a, tiles_b, under]


def gate_booth():
    wdp = Piece("Wood", "Wood", flat=True)
    tiles = Piece("Tiles", "Slate", flat=True)
    under = Piece("Eaves", "Wood", flat=True)
    cloth = Piece("Cloth", "Fabric", flat=True)
    box(wdp, T(34, 1.7, 188), (10, 3.4, 4), lambda p, f: wood(p, f, C["wood"]), cell=1.5)
    box(wdp, T(34, 3.55, 188), (10.6, .3, 4.6), C["woodDark"])
    for k in range(9):
        box(wdp, T(29.5 + k * 1.1, 1.7, 185.95), (.12, 3.0, .1), C["woodDark"])
    for x in (29.5, 38.5):
        box(wdp, T(x, 4.5, 190), (.8, 9, .8), lambda p, f: wood(p, f, C["woodDark"]))
        box(wdp, T(x, 4.5, 186.2), (.6, 9, .6), C["woodDark"])
    tiled_roof(tiles, under, T(34, 8.8, 189), 10, 5, 14, 1.2, "x", C["roofTile"], thick=.6)
    box(wdp, T(34, 8.4, 189), (11, .4, 6), C["woodDark"])
    # papers and a ledger on the counter, a stool behind
    box(cloth, T(32, 3.75, 188.6), (1.4, .1, 1), C["paper"])
    box(cloth, T(35.5, 3.8, 188.4), (1, .2, .8), rgb(120, 52, 40))
    box(wdp, T(35, .9, 190.5), (1.2, 1.8, 1.2), C["woodLight"])
    return [wdp, tiles, under, cloth]


def ichiraku():
    """Kitchen, counter, 5 stools, posts, the sloping awning, the noren. The
    IchirakuSign (x -19.1, y 9.6, 12 long) stays a Part, its place free."""
    walls = Piece("Walls", "Concrete", flat=True)
    wdp = Piece("Wood", "Wood", flat=True)
    cloth = Piece("Noren", "Fabric", flat=True)
    red = Piece("Stools", "SmoothPlastic")
    tiles = Piece("Awning", "Slate", flat=True)
    lamp = Piece("Lanterns", "Fabric")
    caps = Piece("Caps", "SmoothPlastic", flat=True)
    steel = Piece("Kitchen", "Metal", flat=True)
    box(walls, T(-37, 4.5, 110), (10, 9, 22), wall_col(C["plasterWarm"]), cell=2)
    for z in (99, 121):
        box(wdp, T(-37, 4.5, z), (10.4, 9, .7), C["woodDark"])
    box(wdp, T(-37, 8.8, 110), (10.6, .5, 22.6), C["woodDark"])
    box(wdp, T(-24, 1.7, 110), (2.6, 3.4, 20), lambda p, f: wood(p, f, C["woodLight"]), cell=1.5)
    for k in range(10):
        box(wdp, T(-22.66, 1.7, 100.6 + k * 2), (.1, 3.2, .14), C["wood"])
    box(wdp, T(-24, 3.6, 110), (3.4, .4, 20.6), C["wood"])
    # the kitchen behind the counter: pots, a steam hood, shelves, bowls
    box(steel, T(-30.5, 3.0, 110), (2.4, 1.2, 16), rgb(120, 124, 128))
    for z in (104, 108, 112):
        cyl(steel, T(-30.5, 3.6, z), .9, 1.4, rgb(150, 154, 160), sides=12)
    box(steel, T(-31.5, 7.6, 110), (3, .4, 12), rgb(90, 92, 96))
    for z in range(102, 119, 2):
        cyl(red, T(-24.2, 3.8, z + .5), .35, .28, C["cloth"], sides=8, r2=.45)
    for y in (5.6, 7.0):
        box(wdp, T(-31.9, y, 110), (.8, .15, 14), C["woodDark"])
    for k in range(5):
        z = 102 + k * 4
        cyl(red, T(-21, 1.8, z), .82, .38, C["red"], sides=14)
        cyl(red, T(-21, 0, z), .16, 1.8, C["iron"], sides=6)
        cyl(red, T(-21, 0, z), .6, .08, C["iron"], sides=10)
    for z in (100, 120):
        box(wdp, T(-19.5, 4.5, z), (.8, 9, .8), lambda p, f: wood(p, f, C["woodDark"]))
    m = T(-30, 9.6, 110) @ Rz(math.radians(-8))
    box(wdp, m @ T(0, -.3, 0), (24, .3, 26), C["woodDark"])
    for k in range(13):
        box(wdp, m @ T(0, -.6, -12 + k * 2), (24, .3, .3), C["wood"])
    for k in range(27):
        z = -13 + k
        box(tiles, m @ T(0, .15, z + .5), (24, .3 + .1 * (k % 2), .95), jitter(C["roofTerra"], (k, 0, 0), .12, 1))
    for k in range(-4, 5):
        rows = []
        for j in range(6):
            v = j / 5
            rows.append([Vector((-19.3 + .04 * math.sin(v * 3 + k), 8.8 - 2.4 * v, 110 + k * 2.2 - 1)), Vector((-19.3 + .04 * math.sin(v * 3 + k), 8.8 - 2.4 * v, 110 + k * 2.2 + 1))])
        loft(cloth, rows, lerp(C["cloth"], rgb(196, 188, 172), .4 if k % 2 else 0), closed=False, cap0=False, cap1=False)
        box(cloth, T(-19.3, 7.2, 110 + k * 2.2), (.1, .8, 1.6), rgb(150, 40, 32))
    for z in (99.4, 120.6):
        paper_lantern(lamp, caps, T(-18.6, 7, z), 1.6, 2.2)
    return [walls, wdp, cloth, red, tiles, lamp, caps, steel]


def exam_hall():
    """The hall without HallFloor, HallPlate, HallLight."""
    walls = Piece("Walls", "Concrete", flat=True)
    wdp = Piece("Timber", "Wood", flat=True)
    red = Piece("Lacquer", "Wood", flat=True)
    tiles_a = Piece("TilesW", "Slate", flat=True)
    tiles_b = Piece("TilesE", "Slate", flat=True)
    under = Piece("Eaves", "Wood", flat=True)
    cloth = Piece("Banners", "Fabric", flat=True)
    stat = Piece("Statue", "Concrete", flat=True)
    glass = Piece("Openings", "SmoothPlastic", flat=True)
    H = 30
    wc = wall_col(C["plaster"])
    box(walls, T(-56, H / 2, -72), (2, H, 100), wc, cell=3)
    box(walls, T(56, H / 2, -72), (2, H, 100), wc, cell=3)
    box(walls, T(0, H / 2, -122), (114, H, 2), wc, cell=3)
    box(walls, T(-32.5, H / 2, -22), (47, H, 2), wc, cell=3)
    box(walls, T(32.5, H / 2, -22), (47, H, 2), wc, cell=3)
    box(walls, T(0, 14 + (H - 14) / 2, -22), (18, H - 14, 2), wc, cell=3)
    for x in (-10, 10):
        box(red, T(x, 7, -22), (2, 14, 3), lambda p, f: grime(C["red"], p, 0, 2, .4))
    box(red, T(0, 15, -21.4), (24, 2, 3.4), C["red"])
    box(red, T(0, 16.4, -21.0), (26, .6, 3.0), C["redDark"])
    # bands and sills round the hall
    for y in (1, 12, H - .5):
        for (x, z, sx, sz) in ((-56, -72, 2.3, 100.3), (56, -72, 2.3, 100.3), (0, -122, 114.3, 2.3)):
            box(wdp, T(x, y, z), (sx, .8 if y > 1 else 2, sz), C["woodDark"] if y > 1 else C["stoneDark"])
        for x in (-32.5, 32.5):
            box(wdp, T(x, y, -22), (47.3, .8 if y > 1 else 2, 2.3), C["woodDark"] if y > 1 else C["stoneDark"])
    for z in range(-34, -113, -13):
        for x in (-57.2, 57.2):
            box(wdp, T(x, H / 2, z), (1.4, H, 1.4), lambda p, f: wood(p, f, C["wood"]))
            window(wdp, glass, T(x, 20, z + 6.5) @ Ry(0 if x > 0 else math.pi), 4, 5)
    for x in range(-48, 49, 16):
        if abs(x) > 12:
            box(wdp, T(x, H / 2, -20.8), (1.4, H, 1.4), lambda p, f: wood(p, f, C["wood"]))
    tiled_roof(tiles_a, under, T(0, H, -72), 114, 102, 22, 4, "z", C["roofTile"], thick=.9, rib=2.8, course=3.2, tiles2=tiles_b)
    for side in (-1, 1):
        bx = side * 50
        box(wdp, T(bx, 12, -69), (10, 1, 90), lambda p, f: jitter(C["woodLight"], p, .1, .8), cell=3)
        for k in range(30):
            box(wdp, T(bx, 12.52, -113 + k * 3), (10, .04, .1), C["woodDark"])
        box(wdp, T(side * 44.7, 15.3, -74), (.6, .4, 80), C["woodDark"])
        box(wdp, T(side * 44.7, 13.5, -74), (.4, .3, 80), C["woodDark"])
        for z in range(-112, -35, 10):
            box(wdp, T(side * 44.7, 14, z), (.9, 4, .9), C["woodDark"])
        for z in range(-112, -35, 3):
            box(wdp, T(side * 44.7, 14.4, z), (.2, 1.4, .2), C["wood"])
        for k in range(12):
            y = 12 * (k + 1) / 12
            box(wdp, T(bx, 11, -36 - 0) @ T(0, 0, 0), (.1, .1, .1), C["wood"]) if False else None
        for step in range(1, 13):
            x = side * (30 + (step - 1) * 1.25)
            box(wdp, T(x, step / 2, -27.5), (1.3, step, 6), lambda p, f: wood(p, f, C["woodLight"]))
            box(wdp, T(x, step + .03, -27.5), (1.32, .06, 6.05), C["woodDark"])
        for z in range(-110, -33, 19):
            col = C["red"] if (z // 19) % 2 == 0 else rgb(46, 64, 96)
            rows = [[Vector((side * 54.8, 25 - 14 * v, z - 2.5)), Vector((side * 54.8, 25 - 14 * v, z + 2.5))] for v in [j / 6 for j in range(7)]]
            loft(cloth, rows, lambda p, k, col=col: lerp(col, rgb(20, 20, 24), .12 * (k % 2)), closed=False, cap0=False, cap1=False)
            box(cloth, T(side * 54.75, 25.2, z), (.3, .3, 5.6), C["woodDark"])
            box(cloth, T(side * 54.7, 18, z), (.12, 2.2, 2.2), rgb(214, 196, 150))
    # the hand-sign statue: two forearms rising, the hands in a seal
    box(stat, T(0, 2, -114), (22, 4, 10), lambda p, f: jitter(C["stoneDark"], p, .1, .9), cell=2)
    box(stat, T(0, 4.2, -114), (20, .4, 8.6), C["stone"])
    sc = lambda p, k: jitter(C["stone"], p, .08, .6)
    for side in (-1, 1):
        m = T(side * 3.6, 14, -114) @ Rz(side * math.radians(9))
        a0 = m @ Vector((0, -11, 0))
        a1 = m @ Vector((0, 9, 0))
        tube(stat, [a0, (a0 + a1) / 2, a1], lambda k: 2.6 - .5 * k, sc, sides=12)
        hand = m @ Vector((0, 13, 0))
        ellipsoid(stat, hand, (2.6, 3.2, 2.1), sc, seg=12, rings=8)
        for j, (dx, L) in enumerate(((-1.2, 6.0), (.4, 5.2))):
            b = m @ Vector((side * dx, 15.6, 0))
            t = m @ Vector((side * dx * .6, 15.6 + L, 0))
            tube(stat, [b, t], lambda k: .75 - .15 * k, sc, sides=8)
            ellipsoid(stat, t, (.62, .62, .62), sc, seg=8, rings=5)
        for j in range(3):
            b = m @ Vector((side * (-1.2 + j * .9), 14.4, 1.6))
            tube(stat, [b, b + Vector((side * -.4, 1.2, .8))], lambda k: .6, sc, sides=7)
    return [walls, wdp, red, tiles_a, tiles_b, under, cloth, stat, glass]


def training_props():
    wdp = Piece("Wood", "Wood", flat=True)
    rope = Piece("Rope", "Fabric")
    tgt = Piece("Target", "Wood", flat=True)
    metal = Piece("Kunai", "Metal", flat=True)
    box(wdp, T(-150, 3.5, 16), (1.4, 7, 1.4), lambda p, f: wood(p, f, C["wood"]))
    box(wdp, T(-150, 5.4, 16), (6, 1, 1), lambda p, f: wood(p, f, C["wood"]))
    ellipsoid(wdp, (-150, 7.6, 16), (.9, 1, .9), C["woodLight"], seg=8, rings=5)
    for y in (2.5, 4.0, 6.2):
        cyl(rope, T(-150, y, 16), .78, .35, C["rope"], sides=10)
    for k in range(5):
        box(wdp, T(-150, 1.5 + k * 1.1, 16) @ Ry(k * 1.1) @ T(.72, 0, 0), (.08, .12, .7), rgb(196, 160, 112))
    box(wdp, T(-162, 3, 30), (.8, 6, .8), lambda p, f: wood(p, f, C["woodDark"]))
    rings = []
    for r in (2.5, 1.8, 1.1, .5):
        rings.append([Vector((-161.6, 5.6 + math.sin(a) * r, 30 + math.cos(a) * r)) for a in [i / 20 * math.tau for i in range(20)]])
    for ci, r in enumerate((2.5, 1.8, 1.1, .5)):
        col = (C["cloth"], C["red"], C["cloth"], C["red"])[ci]
        rr = [[Vector((-161.6 + .2 + .01 * ci, 5.6 + math.sin(a) * rad, 30 + math.cos(a) * rad)) for a in [i / 20 * math.tau for i in range(20)]] for rad in (r, r - .7 if r > .5 else .01)]
        loft(tgt, rr, col, closed=True, cap0=False, cap1=False)
    cyl(tgt, T(-161.6, 5.6, 30) @ Rz(math.pi / 2) @ T(0, -.2, 0), 2.6, .4, C["woodLight"], sides=20)
    for k, (dy, dz) in enumerate(((.4, -.6), (-.8, .9), (1.3, .5))):
        b = Vector((-161.4 + .2, 5.6 + dy, 30 + dz))
        tube(metal, [b, b + Vector((.9, .1, 0))], .05, C["iron"], sides=5)
        torus(metal, (b.x + 1.05, b.y + .1, b.z), Matrix.Rotation(math.pi / 2, 3, "Z"), .1, .025, C["iron"], seg=10, sides=4)
    return [wdp, rope, tgt, metal]


def memorial_stone():
    st = Piece("Base", "Slate", flat=True)
    mb = Piece("Stone", "Marble", flat=True)
    box(st, T(-172, .5, 78), (8, 1, 6), lambda p, f: jitter(C["stoneDark"], p, .12, 1), cell=1.5)
    box(st, T(-172, 1.15, 78), (6, .3, 4.6), C["stone"])
    m = T(-172, 4.5, 78) @ Ry(math.radians(-20))
    # a cut slab, its top bevelled, names engraved in rows (darker grooves)
    pts = [(-.8, -3.5), (.8, -3.5), (.8, 3.1), (.5, 3.5), (-.5, 3.5), (-.8, 3.1)]
    a = [m @ Vector((x, y, -2.3)) for x, y in pts]
    b = [m @ Vector((x, y, 2.3)) for x, y in pts]
    loft(mb, [a, b], lambda p, k: jitter(C["black"], p, .1, 2))
    for r in range(10):
        for side in (-1, 1):
            for c in range(3):
                box(mb, m @ T(side * .81, 2.4 - r * .55, -1.4 + c * 1.4), (.03, .18, 1.1), rgb(70, 72, 78))
    return [st, mb]


def hyuga_compound():
    walls = Piece("Walls", "Concrete", flat=True)
    wdp = Piece("Timber", "Wood", flat=True)
    tiles_a = Piece("TilesW", "Slate", flat=True)
    tiles_b = Piece("TilesE", "Slate", flat=True)
    under = Piece("Eaves", "Wood", flat=True)
    glass = Piece("Shoji", "SmoothPlastic", flat=True)
    gtiles = Piece("GateTiles", "Slate", flat=True)
    cx, cz, w, d = -186, -107, 34, 96
    box(walls, T(cx, 4, cz), (w, 8, d), wall_col(C["plaster"]), cell=3)
    box(wdp, T(cx, .5, cz), (w + .3, 1, d + .3), C["stoneDark"])
    box(wdp, T(cx, 7.75, cz), (w + .3, .5, d + .3), C["woodDark"])
    for z in range(int(cz - d / 2), int(cz + d / 2) + 1, 6):
        for x in (cx - w / 2, cx + w / 2):
            box(wdp, T(x, 4, z), (.8, 8, .8), lambda p, f: wood(p, f, C["wood"]))
    # sliding shōji panels along the garden face (+x), the engawa in front
    for z in range(int(cz - d / 2) + 3, int(cz + d / 2) - 2, 6):
        box(glass, T(cx + w / 2 + .05, 4, z), (.1, 5.6, 5.2), C["paper"])
        for k in range(1, 4):
            box(wdp, T(cx + w / 2 + .12, 4, z - 2.6 + k * 1.3), (.06, 5.6, .08), C["woodDark"])
        for y in (2, 3.4, 4.8, 6.2):
            box(wdp, T(cx + w / 2 + .12, y, z), (.06, .08, 5.2), C["woodDark"])
    tiled_roof(tiles_a, under, T(cx, 8, cz), w, d, 20, 1.6, "z", C["roofDark"], thick=.9, rib=2.3, course=2.5, tiles2=tiles_b)
    box(wdp, T(-167, 1, -107), (4, 1, 90), lambda p, f: jitter(C["woodLight"], p, .1, .9), cell=2)
    for z in range(-151, -62, 2):
        box(wdp, T(-167, 1.51, z), (4, .03, .08), C["woodDark"])
    for z in range(-150, -63, 6):
        box(wdp, T(-165.3, .25, z), (.5, .5, .5), C["woodDark"])
    for z in (-112, -94):
        box(wdp, T(-108, 6.5, z), (2, 13, 2), lambda p, f: wood(p, f, C["woodDark"]))
    box(wdp, T(-108, 12.4, -103), (2.6, 1, 21), C["woodDark"])
    tiled_roof(gtiles, under, T(-108, 12.9, -103), 3, 22, 26, 1.4, "z", C["roofDark"], thick=.6, rib=.9, course=1.0)
    box(wdp, T(-132, 3.2, -104), (1.4, 6.4, 1.4), lambda p, f: wood(p, f, C["wood"]))
    for k in range(8):
        box(wdp, T(-132, 1.2 + k * .6, -104), (1.5, .25, 1.5), C["woodDark"])
    return [walls, wdp, tiles_a, tiles_b, under, glass, gtiles]


def uchiha_gate():
    red = Piece("Lacquer", "Wood", flat=True)
    for z in (-52, -38):
        box(red, T(96, 7, z), (2.2, 14, 2.2), lambda p, f: grime(jitter(C["redDark"], p, .06, 1), p, 0, 2, .4))
        box(red, T(96, .6, z), (2.8, 1.2, 2.8), C["stoneDark"])
    box(red, T(96, 14, -45), (3, 1.6, 20), C["redDark"])
    box(red, T(96, 15.0, -45), (3.6, .5, 22), C["black"])
    box(red, T(96, 11.6, -45), (1.4, .8, 14), C["redDark"])
    return [red]


def uchiha_pier():
    wdp = Piece("Planks", "Wood", flat=True)
    for k in range(30):
        box(wdp, T(150.5 + k + .5, 1.2 + .03 * (k % 3), -60), (.94, .8, 5), jitter(C["woodGrey"], (k, 0, 0), .15, 1))
    for x in (150.5, 179.5):
        pass
    box(wdp, T(165, .9, -62.3), (30, .3, .3), C["woodDark"])
    box(wdp, T(165, .9, -57.7), (30, .3, .3), C["woodDark"])
    for x in range(152, 179, 6):
        for z in (-62.2, -57.8):
            cyl(wdp, T(x, -3, z), .42, 4.2, lambda p, k: lerp(rgb(50, 60, 54), C["woodDark"], smooth((p.y + 1.2) / 2)), sides=8)
    return [wdp]


def naka_shrine():
    st = Piece("Base", "Slate", flat=True)
    walls = Piece("Walls", "Concrete", flat=True)
    wdp = Piece("Timber", "Wood", flat=True)
    tiles = Piece("Tiles", "Slate", flat=True)
    under = Piece("Eaves", "Wood", flat=True)
    box(st, T(182, .8, -138), (34, 1.6, 26), lambda p, f: jitter(C["stoneDark"], p, .12, 1), cell=2)
    for k in range(4):
        box(st, T(182 + 17.4 + k * .0, .2 + k * .4, -138), (.0, .0, .0), C["stone"]) if False else None
    for k in range(3):
        box(st, T(199.4 - k * .0 + .6, .27 * (k + 1), -138), (1.2, .54 * (k + 1), 8 - k), C["stone"])
    box(walls, T(182, 1.6 + 4, -140), (24, 8, 18), wall_col(C["plaster"]), cell=2)
    for x in (170, 182, 194):
        for z in (-149, -131):
            box(wdp, T(x, 5.6, z), (.9, 8, .9), C["redDark"])
    box(wdp, T(182, 9.35, -140), (24.4, .5, 18.4), C["woodDark"])
    box(wdp, T(194.08, 5, -140), (.16, 6.4, 6), C["redDark"])
    tiled_roof(tiles, under, T(182, 9.6, -140), 24, 18, 26, 2.2, "x", C["roofDark"], thick=.9, rib=1.4, course=1.6)
    cyl(wdp, T(194.6, 8.2, -140) @ Rx(0), .02, .02, C["rope"], sides=3) if False else None
    tube(wdp, [Vector((194.4, 8.4, -143)), Vector((194.6, 7.9, -140)), Vector((194.4, 8.4, -137))], .22, C["rope"], sides=7)
    return [st, walls, wdp, tiles, under]


def torii():
    red = Piece("Lacquer", "Wood", flat=True)
    blk = Piece("Kasagi", "Wood", flat=True)
    for x in (171, 185):
        cyl(red, T(x, 0, -108), .8, 14, lambda p, k: grime(C["red"], p, 0, 1.5, .4), sides=12, r2=.72)
        cyl(blk, T(x, 0, -108), 1.0, .8, C["black"], sides=12)
    # the top beam: flat on top at y 14.9 over the posts, its ends sweeping up
    rows = []
    for i in range(13):
        u = i / 12
        x = 178 - 11 + 22 * u
        up = .9 * (abs(2 * u - 1) ** 3)
        rows.append([Vector((x, 13.5 + up * .6, -109.1)), Vector((x, 13.5 + up * .6, -106.9)), Vector((x, 14.9 + up, -106.9)), Vector((x, 14.9 + up, -109.1))])
    loft(blk, rows, C["black"])
    box(red, T(178, 13.2, -108), (20, .6, 1.8), C["red"])
    box(red, T(178, 11.6, -108), (16, 1, 1.4), C["red"])
    box(red, T(178, 12.4, -108), (1.2, 1.4, 1.2), C["red"])
    return [red, blk]


def hokage_cliff():
    """The cliff alone (its solid box stays 330 x 92 x 32, front at z -232):
    a real rock silhouette. Its face has buttresses and cracks, a ledge set
    back above the heads, an irregular crest with boulders and notches, its
    top broken (seen from the sky it is no flat striped wall), and mountains
    behind. The heads are separate (HeadFunny1..4, or the avatars)."""
    rock = Piece("Cliff", "Rock", flat=True)
    top = Piece("Crest", "Rock", flat=True)
    far = Piece("Mountains", "Rock", flat=True)
    grass = Piece("Moss", "Grass", flat=True)
    def rc(p, k=0):
        strata = math.sin(p.y * .38 + noise.noise(p * .02) * 2.5)
        c = lerp(C["rockDark"], C["rock"], .5 + .28 * strata + .25 * noise.noise(p * .07))
        return grime(c, p, 0, 10, .3)
    def crest(x):
        return 92 + 9 * noise.noise(Vector((x * .018, 3.1, 0))) + 4 * noise.noise(Vector((x * .06, 7.7, 0))) \
            + 7 * max(0, math.sin(x * .021 + 1.2)) ** 3
    # the face: a grid (x, y) pushed out by buttresses and in by cracks, a
    # ledge set back 5 above y 80 (over the heads), rounded where it meets the top
    X, Y = 66, 26
    rows = []
    for j in range(Y + 1):
        v = j / Y
        row = []
        for i in range(X + 1):
            x = -165 + 330 * i / X
            yt = crest(x)
            y = yt * v
            butt = 5.0 * max(0, math.cos(x * .062)) ** 4 if not any(abs(x - hx) < 15 for hx in (-75, -25, 25, 75)) else 0
            crack = -4.0 * max(0, 1 - abs(math.sin(x * .047 + 2)) * 7)
            back = 5 * smooth((y - 78) / 4) + 3 * smooth((y - yt + 6) / 6)
            dz = 2.4 * noise.noise(Vector((x * .045, y * .05, 0))) + 1.2 * noise.noise(Vector((x * .15, y * .15, 3))) + butt + crack - back
            row.append(Vector((x, y, -232 + dz)))
        rows.append(row)
    loft(rock, rows, rc, closed=False, cap0=False, cap1=False)
    # the top: from the crest back to z -264, broken, a few boulders, moss in hollows
    Zs = 6
    trows = [rows[-1]]
    for k in range(1, Zs + 1):
        z = -232 - 7 - 25 * k / Zs
        trows.append([Vector((p.x, crest(p.x) + 3 * noise.noise(Vector((p.x * .05, z * .1, 2))) + 2 * k / Zs, z)) for p in rows[-1]])
    loft(top, trows, lambda p, kk: lerp(rc(p), C["leafDark"], .55 * max(0, noise.noise(p * .06))), closed=False, cap0=False, cap1=False)
    rng = random.Random(9)
    for k in range(18):
        x = rng.uniform(-160, 160)
        z = rng.uniform(-262, -238)
        y = crest(x) + 1
        s_ = rng.uniform(2.5, 6)
        ellipsoid(top, (x, y, z), (s_ * 1.3, s_, s_), rc, seg=7, rings=4, bump=lambda d, k=k: .3 * noise.noise(d * 2 + Vector((k, 0, 0))))
    for k in range(10):
        x = rng.uniform(-150, 150)
        ellipsoid(grass, (x, crest(x) + 1.5, rng.uniform(-258, -242)), (rng.uniform(6, 12), 1.6, rng.uniform(4, 7)),
                  lambda p, kk: jitter(C["leafDark"], p, .15, .2), seg=8, rings=3)
    # the ends: closed, rough
    for i in (0, X):
        loft(rock, [[rows[j][i] for j in range(Y + 1)], [Vector((rows[j][i].x, rows[j][i].y, -264)) for j in range(Y + 1)]], rc, closed=False, cap0=False, cap1=False)
    # mountains behind, bluer with the distance
    for k, (x, z, h, w) in enumerate(((-130, -340, 150, 70), (-40, -380, 185, 90), (60, -350, 165, 75), (150, -370, 140, 70), (5, -320, 118, 55), (-190, -390, 130, 60), (200, -400, 125, 60))):
        n = 14
        lv = 6
        rings = []
        rr = random.Random(k * 31)
        tipx, tipz = x + rr.uniform(-12, 12), z + rr.uniform(-8, 8)
        for j in range(lv):
            v = j / lv
            y = 30 + (h - 30) * v
            ring = []
            for i in range(n):
                a = i / n * math.tau
                ridge = 1 + .35 * math.cos(a * 3 + k) * (1 - v) + .2 * noise.noise(Vector((math.cos(a) * 2, math.sin(a) * 2, k + v * 3)))
                r = w * (1 - v) ** 1.25 * ridge
                cx = x + (tipx - x) * v
                cz = z + (tipz - z) * v
                ring.append(Vector((cx + math.cos(a) * r, y + 6 * noise.noise(Vector((a, v * 4, k))), cz + math.sin(a) * r * .7)))
            rings.append(ring)
        def mc(p, kk, k=k):
            c = lerp(rgb(98, 106, 112), rgb(132, 146, 160), .4 + .2 * (k % 3) / 2)
            c = lerp(c, rgb(84, 90, 92), .35 * max(0, math.sin(p.y * .25 + noise.noise(p * .02) * 3)))
            return lerp(c, rgb(176, 184, 192), smooth((p.y - 135) / 40) * .7)
        loft(far, rings, mc, cap0=False, tip1=Vector((tipx, h, tipz)))
    return [rock, top, far, grass]


# ---------------------------------------------------------------- the carved heads (HeadFunny1..4)
# François 14/11: the cartoon heads « ne vont pas du tout, sois moins
# enfant »: four heads carved in the cliff like a monument, real anatomy as a
# relief (brow ridge, sockets, the nose's bridge and wings, cheekbones, the
# folds, lips, chin, jaw), weathered stone, each its own person: an elder with
# a beard, a scarred warrior, a calm young man, a woman with her hair up.
# Generic: nobody's portrait, no symbol. (The names stay HeadFunny1..4: the
# placeholders until the server carves the avatars.) Origin at the centre,
# face to +z, inside 26 x 30 x 8; hair may run over and behind into the rock.
STONE_FACE = rgb(156, 142, 124)
STONE_SHADE = rgb(92, 82, 70)


def g2(x, y, cx, cy, sx, sy):
    return math.exp(-(((x - cx) / sx) ** 2 + ((y - cy) / sy) ** 2))


def relief_face(pc, p):
    """The face as a carved relief z(x, y) on a dense grid, colour darkening
    in hollows and with rain stains under the brows."""
    old, jaw, smile, brow_in, scar, soft = p["old"], p["jaw"], p["smile"], p["brow_in"], p["scar"], p["soft"]
    W, Hh = 11.6 + jaw * .6, 14.6
    def z_at(x, y):
        e = (x / W) ** 2 + (y / Hh) ** 2
        if e >= 1:
            return -3.6, 0.0
        base = -3.6 + 6.0 * (1 - e) ** .42
        # the jaw: wider and squarer low on the face for a strong jaw
        base += jaw * .5 * g2(x, y, 0, -11, 9, 3)
        f = 0.0
        f += (1.0 - .3 * soft) * math.exp(-((y - 4.6 + brow_in * abs(x) * .06) / 1.0) ** 2) * math.exp(-(x / 8.5) ** 6)   # brow ridge
        for sx in (-1, 1):
            f -= 1.7 * g2(x, y, sx * 4.3, 2.4, 2.4, 1.5)                    # eye socket
            f += .9 * g2(x, y, sx * 4.3, 2.3, 1.3, .75)                      # the eye
            f += .25 * g2(x, y, sx * 4.3, 3.15, 1.6, .25)                    # upper lid
            f += (.9 - .4 * soft) * g2(x, y, sx * 6.6, -.4, 2.6, 1.8)        # cheekbone
            f -= (.5 + .3 * old) * g2(x * 1.0 + sx * 0, y, sx * (3.0 + .25 * (-5 - y)), -6.4, .5, 2.4)  # nasolabial fold
            f -= .4 * g2(x, y, sx * 9.6, 4.0, 1.4, 3)                        # temple
            if old:
                for k in range(3):
                    f -= .18 * g2(x, y, sx * (6.6 + .6 * k), 1.6 + .7 * k, .9, .12)  # crow's feet
            f += .3 * g2(x, y, sx * (3.1 + smile * .5), -8.2 + smile * .6, .7, .6)  # mouth corners
        # the nose: bridge, tip, wings, nostrils
        bridge = math.exp(-((x) / (.8 + .1 * (3 - y))) ** 2) if -4.6 < y < 3.4 else 0
        f += (1.3 + .7 * (3.4 - y) / 8) * bridge * smooth((3.4 - y) / 1.5)
        f += 2.6 * g2(x, y, 0, -4.4, 1.3, 1.1)
        for sx in (-1, 1):
            f += 1.25 * g2(x, y, sx * 1.55, -4.9, .85, .75)
            f -= .7 * g2(x, y, sx * 1.0, -5.5, .45, .3)
        # philtrum, lips, mouth line, chin
        f += .35 * g2(x, y, 0, -6.4, .5, .8)
        f += .75 * g2(x, y, 0, -7.55 + smile * .1, 2.9, .5) * (1 - .3 * smile * abs(x) / 3)
        f += .85 * g2(x, y, 0, -9.0, 2.5, .6)
        f -= .9 * g2(x, y, 0, -8.25 + smile * .08 * x * x / 3, 3.3, .2)
        f -= .45 * g2(x, y, 0, -10.2, 2.4, .4)
        f += 1.1 * g2(x, y, 0, -12.3, 3.4 + jaw, 1.4)
        # forehead lines for the old one
        if old:
            for k in range(3):
                f -= .2 * g2(x, y, 0, 6.6 + .9 * k, 5.5, .14)
        # the scar: a deep diagonal cut across the cheek and brow
        if scar:
            d = abs((y - 1.0) - (-1.15) * (x - 4.5)) / 1.52
            if -4 < x - 4.5 < 4.5:
                f -= .55 * math.exp(-(d / .25) ** 2)
                f += .25 * math.exp(-((d - .4) / .2) ** 2)
        z = base + 1.45 * f * smooth((1 - e) * 3) ** .5
        return min(z, 3.95), f
    X, Y = 64, 74
    idx = []
    for j in range(Y + 1):
        y = -15 + 30 * j / Y
        row = []
        for i in range(X + 1):
            x = -13 + 26 * i / X
            z, f = z_at(x, y)
            hollow = smooth(-f / 1.2) * .7
            stain = .25 * smooth((4.0 - y) / 6) * smooth((y + 6) / 4) * max(0, noise.noise(Vector((x * .9, 0, 3)))) if abs(x) < 9 else 0
            c = lerp(jitter(STONE_FACE, Vector((x, y, z)), .05, .35), STONE_SHADE, min(.85, hollow + stain + (.6 if z <= -3.9 else 0)))
            row.append(pc.add(Vector((x, y, z)), c))
        idx.append(row)
    for j in range(Y):
        for i in range(X):
            q = (idx[j][i], idx[j][i + 1], idx[j + 1][i + 1], idx[j + 1][i])
            if all(pc.v[k].z <= -3.59 for k in q):
                continue
            pc.face(*q)
    return z_at


def hair_mass(pc, center, radii, col, strands=22, depth=.18, y_min=None, part=False, seg=40, rings=18):
    """A carved mass of hair: an ellipsoid (its poles up and down, so no pole
    faces the village) with grooves running down along the strands, like a
    stone bust; optionally parted in the middle."""
    c = Vector(center)
    def bump(d):
        # built with y and z swapped: here d.z is up, d.y is to the front
        th = math.atan2(d.x, d.y)
        g = depth * .5 * (abs(math.sin(th * strands * 1.6)) ** .5 - .5) + .04 * noise.noise(Vector((d.x * 6, d.y * 6, d.z * 2)))
        if part:
            g -= .45 * math.exp(-(d.x / .07) ** 2) * max(0, d.z)
        return g
    i0 = len(pc.v)
    ellipsoid(pc, (0, 0, 0), (radii[0], radii[2], radii[1]), col, seg=seg, rings=rings, bump=bump)
    for i in range(i0, len(pc.v)):
        v = pc.v[i]
        pc.v[i] = c + Vector((v.x, v.z, v.y))
    for i in range(i0, len(pc.v)):
        pc.c[i] = col(pc.v[i], 0) if callable(col) else col


def carved_hair(pc, style, z_at):
    hc = lambda p, k=0: lerp(jitter(lerp(STONE_FACE, STONE_SHADE, .2), p, .06, .3), STONE_SHADE, .35 * smooth((-p.z - 1) / 3))
    deep = lambda p, k=0: lerp(STONE_SHADE, rgb(60, 54, 48), .3)
    if style == "elder":
        hair_mass(pc, (0, 9.4, -2.4), (12.8, 7.8, 4.6), hc, strands=26, y_min=8.0, part=False)
        for sx in (-1, 1):
            hair_mass(pc, (sx * 11.6, -1, -1.2), (2.6, 12.5, 2.8), hc, strands=10, depth=.25, seg=14, rings=10)
            tube(pc, [Vector((sx * .5, -6.5, z_at(0, -6.5)[0] - .1)), Vector((sx * 3.2, -7.4, 2.9)), Vector((sx * 5.2, -10.0, 2.0))],
                 lambda kk: .9 * (1 - .45 * kk) + .2, hc, sides=8)
        hair_mass(pc, (0, -11.6, .6), (6.0, 4.6, 2.8), hc, strands=40, depth=.25, seg=20, rings=10)
    elif style == "warrior":
        hair_mass(pc, (0, 10.0, -2.6), (12.4, 6.6, 4.4), hc, strands=34, depth=.22, y_min=9.0)
        band = []
        for j in range(3):
            y = 8.4 + .7 * j
            band.append([Vector((x, y, max(z_at(x, y)[0], -3.4) + .3)) for x in [-11.8 + 23.6 * i / 18 for i in range(19)]])
        loft(pc, band, deep, closed=False, cap0=False, cap1=False)
        for k in range(6):
            x0 = -9 + 3.6 * k
            b0 = Vector((x0, 13.4, -1.0))
            tip = b0 + Vector((x0 * .25, 3.6 + .8 * math.sin(k * 2.1), -3.6))
            tube(pc, [b0, (b0 + tip) / 2 + Vector((0, .5, .3)), tip], lambda kk: 2.4 * (1 - kk) + .2, hc, sides=8)
    elif style == "calm":
        hair_mass(pc, (0, 9.4, -2.4), (13.0, 7.8, 4.8), hc, strands=28, y_min=7.6, part=True)
        for sx in (-1, 1):
            hair_mass(pc, (sx * 11.2, -.5, -1.0), (2.4, 10.5, 3.0), hc, strands=12, depth=.25, seg=14, rings=10)
    else:
        hair_mass(pc, (0, 9.4, -2.5), (12.4, 7.2, 4.6), hc, strands=30, y_min=8.2)
        hair_mass(pc, (0, 16.4, -2.4), (4.4, 3.4, 3.2), hc, strands=16, depth=.3, seg=16, rings=8)
        tube(pc, [Vector((-5.2, 17.8, -1)), Vector((5.6, 15.8, -2.8))], .35, deep, sides=6)
        for sx in (-1, 1):
            b0 = Vector((sx * 10.2, 6.5, max(z_at(sx * 10.2, 6.5)[0], -2) + .1))
            tube(pc, [b0, b0 + Vector((sx * .6, -6, .3)), b0 + Vector((-sx * .4, -11, -.4))], lambda kk: .9 * (1 - .5 * kk), hc, sides=7)


def carved_head(params, style):
    pc = Piece("Head", "Rock", flat=True)
    z_at = relief_face(pc, params)
    # ears, carved in the side of the head
    for sx in (-1, 1):
        ellipsoid(pc, (sx * 12.0, 1.5, -1.2), (1.2, 3.4, 1.8), lambda p, k: jitter(STONE_FACE, p, .06, .3), seg=8, rings=6)
        ellipsoid(pc, (sx * 12.3, 1.5, -.6), (.5, 2.2, .7), STONE_SHADE, seg=6, rings=4)
    hair = Piece("Hair", "Rock", flat=True)
    carved_hair(hair, style, z_at)
    return [pc, hair]


HEADS = {
    "HeadFunny1": ({"old": 1, "jaw": .6, "smile": 0, "brow_in": 1.0, "scar": 0, "soft": 0}, "elder"),
    "HeadFunny2": ({"old": 0, "jaw": 1.2, "smile": -.4, "brow_in": 1.4, "scar": 1, "soft": 0}, "warrior"),
    "HeadFunny3": ({"old": 0, "jaw": .3, "smile": .2, "brow_in": .2, "scar": 0, "soft": .3}, "calm"),
    "HeadFunny4": ({"old": 0, "jaw": -.6, "smile": .5, "brow_in": -.3, "scar": 0, "soft": 1}, "bun"),
}

def faces_terrace():
    st = Piece("Stone", "Slate", flat=True)
    wdp = Piece("Rails", "Wood", flat=True)
    lamp = Piece("Lanterns", "Fabric")
    caps = Piece("Caps", "SmoothPlastic", flat=True)
    sc = lambda p, f: grime(jitter(C["stone"], p, .1, .3), p, 0, 3, .3)
    box(st, T(0, 12, -219), (84, 24, 26), sc, cell=3)
    for y in range(3, 24, 3):
        box(st, T(0, y, -205.95), (84, .12, .1), C["stoneDark"])
    box(st, T(0, 24.15, -219), (84.6, .3, 26.6), C["stoneDark"])
    for x in (-41, 41):
        box(wdp, T(x, 25.5, -219), (1, .5, 26), C["woodDark"])
        for z in range(-231, -206, 4):
            box(wdp, T(x, 25, z), (.7, 2, .7), C["woodDark"])
    for x in (-26, 26):
        box(wdp, T(x, 26.7, -206.5), (30, .4, 1), C["woodDark"])
        box(wdp, T(x, 25.4, -206.5), (30, .3, .6), C["wood"])
        for xx in range(int(x - 15), int(x + 16), 3):
            box(wdp, T(xx, 25.4, -206.5), (.6, 2.6, .6), C["woodDark"])
    for step in range(1, 25):
        z = -140 - (step - 1) * 2.8
        box(st, T(0, step / 2, z), (20, step, 2.8), sc)
        box(st, T(0, step + .06, z + 1.25), (20.2, .12, .4), C["stoneDark"])
    for x in (-11, 11):
        box(st, T(x, 12.5, -172), (2, 26, 67), lambda p, f: jitter(C["stoneDark"], p, .1, .4), cell=4) if False else None
    for x in (-11, 11):
        for step in range(4, 25, 4):
            z = -140 - (step - 1) * 2.8
            box(wdp, T(x, step + 1.5, z), (.4, 3, .4), C["woodDark"])
            paper_lantern(lamp, caps, T(x, step + 3, z), 1.6, 2.2)
    return [st, wdp, lamp, caps]

def blender(pieces):
    """Roblox frame (x, y up, z) -> nd_mesh's Blender frame (x, y = -z, z = y)."""
    for pc in pieces:
        pc.v = [Vector((v.x, -v.z, v.y)) for v in pc.v]
    return pieces


MODELS = {
    "KonohaGate": konoha_gate,
    "GateBooth": gate_booth,
    "Ichiraku": ichiraku,
    "ExamHall": exam_hall,
    "TrainingProps": training_props,
    "MemorialStone": memorial_stone,
    "HyugaCompound": hyuga_compound,
    "UchihaGate": uchiha_gate,
    "UchihaPier": uchiha_pier,
    "NakaShrine": naka_shrine,
    "Torii": torii,
    "HokageCliff": hokage_cliff,
    **{name: (lambda name=name: carved_head(*HEADS[name])) for name in HEADS},
    "FacesTerrace": faces_terrace,
    "HouseGable_24x20x2": lambda: house("Gable", 24, 20, 2),
    "HouseShop_24x20x2": lambda: house("Shop", 24, 20, 2),
    "HouseShop_24x20x1": lambda: house("Shop", 24, 20, 1),
    "HouseBack_22x20x2": lambda: house("Back", 22, 20, 2),
    "HouseUchiha_26x20x2": lambda: house("Uchiha", 26, 20, 2),
    "HouseFlat_24x20x2": lambda: house("Flat", 24, 20, 2),
    "HouseFlat_22x18x3": lambda: house("Flat", 22, 18, 3),
    "WaterTank": water_tank,
    "TreeA": lambda: tree(1),
    "TreeB": lambda: tree(2),
    "TreeC": lambda: tree(3),
    "PaperLantern": lantern_model,
    "LampPost": lamp_post,
    "StoneLantern": stone_lantern,
    "Bench": bench,
    "Crate": crate,
    "Stump": stump,
    "FenceSegment": fence,
    "VillageWall": lambda: village_wall(26),
    "CompoundWall": lambda: village_wall(10),
    "Ladder": ladder,
}


def write(src_dir, limit=110000):
    """HubMeshData.luau (the index) and HubMeshData1..n: chunks under `limit`
    bytes; a big model's pieces may span chunks (the index joins them)."""
    from nd_mesh import piece_luau, q
    chunks, cur, size = [], [], 0
    report = []
    for name, fn in MODELS.items():
        pieces = blender(fn())
        v, t = stats(pieces)
        worst = max(len(p.tris()) for p in pieces)
        assert worst < 20000 and max(len(p.v) for p in pieces) < 60000, (name, worst)
        report.append((name, v, t))
        for pc in pieces:
            text = "\t{%s,%s}," % (q(name), piece_luau(pc))
            if cur and size + len(text) > limit:
                chunks.append(cur)
                cur, size = [], 0
            cur.append(text)
            size += len(text)
    if cur:
        chunks.append(cur)
    head = "-- Generated by tools/blender/konoha_models.py. Do not edit: re-run the script.\n"
    for f in os.listdir(src_dir):
        if f.startswith("HubMeshData") and f.endswith(".luau"):
            os.remove(os.path.join(src_dir, f))
    for i, c in enumerate(chunks, 1):
        with open(os.path.join(src_dir, "HubMeshData%d.luau" % i), "w") as fh:
            fh.write(head + "-- {model, piece} pairs, in order.\nreturn {\n" + "\n".join(c) + "\n}\n")
    with open(os.path.join(src_dir, "HubMeshData.luau"), "w") as fh:
        fh.write(head + "-- Konoha's modelled pieces (docs/systems/HUB_DRESS.md), in MeshData's\n"
                 "-- format: model name -> its pieces. A big model spans several chunks.\n"
                 "local all={}\n"
                 "for _,name in {%s} do\n"
                 "\tfor _,pair in require(script.Parent[name]) do\n"
                 "\t\tlocal list=all[pair[1]]\n"
                 "\t\tif not list then list={};all[pair[1]]=list end\n"
                 "\t\ttable.insert(list,pair[2])\n"
                 "\tend\n"
                 "end\nreturn all\n" % ",".join('"HubMeshData%d"' % i for i in range(1, len(chunks) + 1)))
    total = sum(t for _, _, t in report)
    for r in report:
        print("%-22s %6d verts %6d tris" % r)
    print("wrote", len(chunks), "chunks; templates", total, "tris; bytes", sum(len(t) for c in chunks for t in c))


def render(out_dir, names=None):
    from nd_mesh import to_blender, render_set, clear
    os.makedirs(out_dir, exist_ok=True)
    for name, fn in MODELS.items():
        if names and name not in names:
            continue
        clear()
        pieces = blender(fn())
        objs = [to_blender(p) for p in pieces]
        render_set(objs, os.path.join(out_dir, name + ".png"), size=(560, 420), view=(1.1, -.8, .55), fill=.95, world=(.66, .7, .76))
        v, t = stats(pieces)
        print("rendered", name, v, "verts", t, "tris", flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "write":
        write(sys.argv[2])
    else:
        render(sys.argv[2], sys.argv[3:] or None)
