# Ninja Duel — the stadium's scenery in Blender (stage 5, user 29/10:
# "l'arène, stade Chûnin, original"). Visual pieces only: the field, the wall
# fighters run on, the balcony, cover and breakables stay real parts in
# Server/World. Every asset is modelled around its own origin in ROBLOX space
# (studs, +Y up, -Z toward the field for buildings) and placed by
# Server/ArenaMeshes from World's layout:
#   WallSector / StandSector : one 45-degree slice of the bowl, centred on +Z,
#                              arena origin at the field's centre (y 0);
#   Pavilion, KageBox, Gate, GateTower : buildings, base centre, facing -Z;
#   Crown, PineTree, BroadTree, Bush : vegetation.
# Named "<Asset>__<Piece>", merged per asset and colour, exported to one FBX.
import sys, os, math, random
sys.path.insert(0, os.environ.get("ND_LIB", os.path.dirname(__file__)))
import importlib, nd_look
importlib.reload(nd_look)
from nd_look import *
from mathutils import Vector
V = nd_look.R

OUT = os.environ.get("ND_OUT", os.path.dirname(__file__))
reset()

# ---------------------------------------------------------------- layout
RW = 145           # World.WALL_RADIUS: inner face of the wall
WALL_H = 40
TIERS, RISE, DEPTH = 7, 2.9, 3.6
BACK_R = RW + 2.6 + (TIERS + 1) * DEPTH
BACK_TOP = WALL_H + TIERS * RISE + 6
HALF = math.radians(22.5)

# ---------------------------------------------------------------- palette
STONE = (196, 184, 160); STONE_L = (210, 198, 174); STONE_D = (170, 158, 136)
MORTAR = (128, 118, 102); BASE = (112, 106, 96); BASE_L = (128, 122, 110)
PLASTER = (238, 232, 216); TIMBER = (74, 50, 36); TIMBER_L = (104, 72, 50)
SEAT = (138, 98, 62); SEAT_D = (112, 78, 50); STEP = (176, 168, 150)
ROOF = (60, 70, 82); ROOF_L = (78, 90, 104); RIDGE = (44, 50, 60)
LACQUER = (168, 46, 38); LACQUER_D = (128, 34, 30); GOLD = (214, 170, 70)
LEAF = (78, 124, 62); LEAF_D = (56, 98, 52); LEAF_L = (104, 150, 72)
PINE = (46, 92, 64); PINE_D = (34, 72, 52); BARK = (98, 72, 52)
CLOTH = (176, 44, 40); CLOTH_W = (236, 228, 208)

rng = random.Random(29)

def frame(a):
    """Tangent, up and inward normal at azimuth a (0 = +Z)."""
    return Vector((math.cos(a), 0, -math.sin(a))), Vector((0, 1, 0)), Vector((-math.sin(a), 0, -math.cos(a)))

def obox(center, size, t, u, n, name="obox"):
    """Box along the axes t (x), u (y), n (z) at center (Roblox space)."""
    c = Vector(center)
    sx, sy, sz = (s / 2 for s in size)
    verts = [tuple(c + t * (x * sx) + u * (y * sy) + n * (z * sz)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    ob = nd_look._object(name, verts, faces)
    nd_look._outward(ob)
    return ob

def arc_box(radius, a, y, size, name="arcbox"):
    """A box tangent to the circle of `radius` at azimuth a; size =
    (along the arc, height, radial depth), y = its centre height."""
    t, u, n = frame(a)
    c = Vector((math.sin(a) * radius, y, math.cos(a) * radius))
    return obox(c, size, t, u, n, name)

def arc_sweep(profile, a0, a1, steps, name="sweep"):
    """Sweep a closed (radius, y) polygon round the Y axis from a0 to a1."""
    m = len(profile)
    verts, faces = [], []
    for k in range(steps + 1):
        a = a0 + (a1 - a0) * k / steps
        for r, y in profile:
            verts.append((math.sin(a) * r, y, math.cos(a) * r))
    for k in range(steps):
        for i in range(m):
            j = (i + 1) % m
            faces.append((k * m + i, k * m + j, (k + 1) * m + j, (k + 1) * m + i))
    faces.append(tuple(range(m)))
    faces.append(tuple(steps * m + i for i in reversed(range(m))))
    ob = nd_look._object(name, verts, faces)
    nd_look._outward(ob)
    return ob

def rect(r0, r1, y0, y1):
    return [(r0, y0), (r1, y0), (r1, y1), (r0, y1)]

def put(objs, asset, piece, rgb, smooth=30, material="SmoothPlastic"):
    if not isinstance(objs, list):
        objs = [objs]
    objs = [o for o in objs if o]
    if not objs:
        return
    o = join(objs, asset + "__" + piece) if len(objs) > 1 else objs[0]
    finish(o, asset, piece, rgb, smooth=smooth, material=material)

def cylinder(center, radius, height, sides=12, name="cyl"):
    cx, cy, cz = center
    return loft([(0, radius, radius, 2), (height, radius, radius, 2)], sides=sides, center=(cx, cy, cz), name=name)

def lumpy(center, radii, seed, amount=.18, segments=10, rings=7, name="lump"):
    """A faceted, irregular ball (leaves, bushes)."""
    o = ellipsoid(center, radii, segments=segments, rings=rings, name=name)
    r = random.Random(seed)
    c = V(*center)
    for v in o.data.vertices:
        d = v.co - c
        v.co = c + d * (1 + r.uniform(-amount, amount))
    o.data.update()
    return o

# ---------------------------------------------------------------- the wall
def wall_sector():
    A = "WallSector"
    a0, a1 = -HALF, HALF
    # Mortar behind the stones, the dark base course, the top cornice.
    put(arc_sweep(rect(RW - .12, RW + .05, 4, WALL_H - 2.2), a0, a1, 24), A, "Mortar", MORTAR, 60)
    put([arc_sweep([(RW - .9, 0), (RW + .05, 0), (RW + .05, 4), (RW - .55, 4), (RW - .9, 3.4)], a0, a1, 24)], A, "Base", BASE, 50)
    put(arc_sweep([(RW - .55, 4), (RW + .05, 4), (RW + .05, 4.5), (RW - .45, 4.5)], a0, a1, 24), A, "BaseCap", BASE_L, 50)
    put(arc_sweep([(RW - .3, WALL_H - 2.3), (RW + .05, WALL_H - 2.3), (RW + .05, WALL_H + .2), (RW - 1.5, WALL_H + .2),
                   (RW - 1.5, WALL_H - .5), (RW - .9, WALL_H - .9), (RW - .9, WALL_H - 1.6), (RW - .3, WALL_H - 1.6)], a0, a1, 24),
        A, "Cornice", STONE_L, 50)
    # Parapet with a railing of short posts on the cornice.
    put(arc_sweep(rect(RW - .2, RW + 1.0, WALL_H + .2, WALL_H + 1.6), a0, a1, 24), A, "Parapet", STONE_D, 50)
    posts = []
    for k in range(18):
        a = a0 + (a1 - a0) * (k + .5) / 18
        posts.append(arc_box(RW + .4, a, WALL_H + 2.6, (.5, 2.0, .5)))
    put(posts, A, "RailPost", TIMBER, 40)
    put(arc_sweep(rect(RW + .2, RW + .6, WALL_H + 3.3, WALL_H + 3.7), a0, a1, 24), A, "Rail", TIMBER_L, 40)
    # Cut stone courses, irregular lengths, staggered joints.
    tones = {0: [], 1: [], 2: []}
    y = 4.6
    course = 0
    while y < WALL_H - 2.6:
        h = 2.3 + rng.uniform(-.25, .35)
        if y + h > WALL_H - 2.4:
            h = WALL_H - 2.4 - y
        if h < 1.2:
            break
        s = (RW) * (a1 - a0)
        x = -rng.uniform(0, 3) if course % 2 else 0
        while x < s:
            L = rng.uniform(4.2, 7.6)
            x1 = min(s, x + L)
            mid = (max(0, x) + x1) / 2
            ln = x1 - max(0, x) - .16
            if ln > .6:
                a = a0 + mid / RW
                depth = rng.uniform(.18, .34)
                tones[rng.choice((0, 0, 1, 1, 2))].append(arc_box(RW - depth / 2 - .1, a, y + h / 2, (ln, h - .16, depth)))
            x = x1
        y += h
        course += 1
    put(tones[0], A, "Stone", STONE, 30)
    put(tones[1], A, "StoneLight", STONE_L, 30)
    put(tones[2], A, "StoneDark", STONE_D, 30)
    # Pilasters (4 per slice) and the plinth/capital of each.
    pil, cap = [], []
    for k in range(4):
        a = a0 + (a1 - a0) * (k + .5) / 4
        pil.append(arc_box(RW - .55, a, (4.5 + WALL_H - 2.3) / 2, (2.6, WALL_H - 2.3 - 4.5, .9)))
        cap.append(arc_box(RW - .75, a, WALL_H - 2.9, (3.4, 1.2, 1.3)))
        cap.append(arc_box(RW - .75, a, 5.1, (3.2, 1.2, 1.3)))
    put(pil, A, "Pilaster", STONE_L, 30)
    put(cap, A, "PilasterCap", STONE_D, 30)

# ---------------------------------------------------------------- the stands
def stand_sector():
    A = "StandSector"
    a0, a1 = -HALF, HALF
    tiers, seats, fronts = [], [], []
    for t in range(1, TIERS + 1):
        rc = RW + 2.6 + t * DEPTH
        floor = WALL_H + t * RISE
        r0, r1 = rc - DEPTH / 2, rc + DEPTH / 2 + .1
        tiers.append(arc_sweep(rect(r0, r1, WALL_H, floor), a0, a1, 24))
        # A wooden bench along the front of each step, on the step's floor.
        seats.append(arc_sweep(rect(r0 + .25, r0 + 1.45, floor, floor + .55), a0, a1, 24))
        fronts.append(arc_sweep(rect(r0 + .15, r0 + .35, floor - .1, floor + .2), a0, a1, 24))
    put(tiers, A, "Tiers", STEP, 50)
    put(seats, A, "Benches", SEAT, 40)
    put(fronts, A, "BenchFront", SEAT_D, 40)
    # Two stone stairways per slice (World.isAisle: 16 round the bowl).
    stairs = []
    for a in (-HALF / 2, HALF / 2):
        for t in range(1, TIERS + 1):
            rc = RW + 2.6 + t * DEPTH
            floor = WALL_H + t * RISE
            for half in (0, 1):
                rr = rc - DEPTH / 2 + DEPTH * (.25 + .5 * half)
                stairs.append(arc_box(rr, a, floor - RISE / 2 * (1 - half) - .05 + .02, (3.6, RISE * (.5 + .5 * half) + .1, DEPTH / 2 + .05)))
    put(stairs, A, "Stairs", STONE_L, 30)
    # The back wall: timbered plaster inside, brick-red outside, and a tiled
    # roof on posts over the top rows.
    put(arc_sweep(rect(BACK_R - .7, BACK_R + .7, WALL_H, BACK_TOP), a0, a1, 24), A, "BackWall", PLASTER, 50)
    put(arc_sweep(rect(BACK_R + .7, BACK_R + 1.4, WALL_H - 6, BACK_TOP + .4), a0, a1, 24), A, "BackOuter", LACQUER_D, 50)
    beams = []
    for k in range(13):
        a = a0 + (a1 - a0) * k / 12
        beams.append(arc_box(BACK_R - .8, a, (BACK_TOP + WALL_H + TIERS * RISE) / 2, (.6, BACK_TOP - WALL_H - TIERS * RISE, .25)))
    for yy in (WALL_H + TIERS * RISE + 1.2, BACK_TOP - .6):
        beams.append(arc_sweep(rect(BACK_R - .95, BACK_R - .7, yy - .3, yy + .3), a0, a1, 24))
    put(beams, A, "BackTimber", TIMBER, 40)
    # Roof: from the back wall's top, out over the top three rows, eaves up.
    roof_in, roof_out = BACK_R - 15, BACK_R + 2.2
    y_in, y_out = BACK_TOP - 1.8, BACK_TOP + 3.0
    prof = [(roof_in, y_in), (roof_in + 1.2, y_in + .05), (roof_out, y_out), (roof_out, y_out + .7), (roof_in + 1.2, y_in + .75), (roof_in, y_in + .9)]
    put(arc_sweep(prof, a0, a1, 32), A, "Roof", ROOF, 35)
    ribs = []
    for k in range(25):
        a = a0 + (a1 - a0) * (k + .5) / 25
        t, u, n = frame(a)
        p0 = Vector((math.sin(a) * (roof_in + .6), y_in + .9, math.cos(a) * (roof_in + .6)))
        p1 = Vector((math.sin(a) * roof_out, y_out + .7, math.cos(a) * roof_out))
        mid = (p0 + p1) / 2
        d = (p1 - p0)
        ribs.append(obox(mid, (.35, .3, d.length), t, d.cross(t).normalized() * -1, d.normalized()))
    put(ribs, A, "RoofRib", ROOF_L, 30)
    put(arc_sweep(rect(roof_in - .1, roof_in + .5, y_in - .3, y_in + 1.1), a0, a1, 32), A, "RoofEdge", RIDGE, 30)
    posts = []
    for k in range(6):
        a = a0 + (a1 - a0) * (k + .5) / 6
        floor = WALL_H + 5 * RISE
        posts.append(arc_box(roof_in + .5, a, (floor + y_in) / 2, (.7, y_in - floor, .7)))
    put(posts, A, "RoofPost", TIMBER, 40)
    # The ground ring behind the stands (the bowl's outside), so the slice
    # never shows a gap from a high camera.
    put(arc_sweep(rect(BACK_R + 1.4, BACK_R + 9, -1, WALL_H - 6), a0, a1, 16), A, "Plinth", BASE, 50)

# ---------------------------------------------------------------- roofs
def hip_roof(ax, az, h, y0, lift=1.2, thick=.5, name="roof"):
    """Japanese hip roof: concave slopes, corners turned up. ax, az are the
    eave half-sizes (ax >= az); the ridge runs along X."""
    K, S = 12, 64
    verts, faces = [], []
    for k in range(K + 1):
        s = k / K
        d = az * .94 * s
        hx, hz = max(.05, ax - d), max(.05, az - d)
        yy = y0 + h * s ** 1.7
        for i, (x, z) in enumerate(superellipse(hx, hz, 10, S)):
            xn, zn = abs(x) / ax, abs(z) / az
            corner = (min(xn, 1) * min(zn / max(hz / az, 1e-3), 1)) ** 3
            up = lift * (1 - s) ** 2.5 * corner * 1.0 + lift * .25 * (1 - s) ** 3
            verts.append((x, yy + up, z))
    for k in range(K):
        for i in range(S):
            j = (i + 1) % S
            faces.append((k * S + i, k * S + j, (k + 1) * S + j, (k + 1) * S + i))
    faces.append(tuple(K * S + i for i in range(S)))
    ob = nd_look._object(name, verts, faces)
    nd_look._outward(ob)
    solidify(ob, thick)
    return ob

def ridge(ax, az, h, y0, w=.7, name="ridge"):
    top = y0 + h + .2
    rl = ax - az * .94
    parts = [box((0, top, 0), (2 * rl + 1.2, w, w), bevel=.1, segments=1)]
    for s in (-1, 1):
        parts.append(box((s * (rl + .6), top + .7, 0), (.6, 1.6, .5), bevel=.12, segments=1))
    return join(parts, name)

# ---------------------------------------------------------------- pavilion
def pavilion(A="Pavilion", width=18, depth=10, height=8, tiers=1):
    parts_w, timber, lattice, base = [], [], [], []
    base.append(box((0, .5, 0), (width + 1.4, 1, depth + 1.4), bevel=.15, segments=1))
    parts_w.append(box((0, 1 + height / 2, 0), (width, height, depth), bevel=0))
    for x in [-width / 2 + .3 + (width - .6) * k / 4 for k in range(5)]:
        for z in (-depth / 2 - .05, depth / 2 + .05):
            timber.append(box((x, 1 + height / 2, z), (.6, height, .3), bevel=0))
    for z in [-depth / 2 + .3 + (depth - .6) * k / 2 for k in range(3)]:
        for x in (-width / 2 - .05, width / 2 + .05):
            timber.append(box((x, 1 + height / 2, z), (.3, height, .6), bevel=0))
    for y in (1.3, 1 + height * .45, 1 + height - .3):
        timber.append(box((0, y, -depth / 2 - .08), (width + .2, .4, .3), bevel=0))
        timber.append(box((0, y, depth / 2 + .08), (width + .2, .4, .3), bevel=0))
    # Lattice windows on the front.
    for k in range(4):
        x = -width / 2 + (width) * (k + .5) / 4
        lattice.append(box((x, 1 + height * .72, -depth / 2 - .12), (width / 4 - 1.4, height * .38, .12), bevel=0))
    put(base, A, "Base", BASE_L, 40)
    put(parts_w, A, "Walls", PLASTER, 40)
    put(timber, A, "Timber", TIMBER, 30)
    put(lattice, A, "Lattice", (54, 40, 32), 30)
    y = 1 + height
    roofs, ridges = [], []
    for tier in range(tiers):
        ax, az = width / 2 + 3.2 - tier * 3, depth / 2 + 3.2 - tier * 2
        roofs.append(hip_roof(ax, az, 4.2 - tier * .6, y - .2, lift=1.3))
        ridges.append(ridge(ax, az, 4.2 - tier * .6, y - .2))
        if tier < tiers - 1:
            parts = [box((0, y + 2.2, 0), (width - 6 - tier * 2, 4, depth - 4), bevel=0)]
            put(parts, A, "Upper%d" % tier, PLASTER, 40)
            y += 4.4
    put(roofs, A, "Roof", ROOF, 35)
    put(ridges, A, "Ridge", RIDGE, 30)
    put([box((0, y + 4.6, 0), (1.2, 1.2, 1.2), bevel=.3, segments=2)], A, "Finial", GOLD, 30)

# ---------------------------------------------------------------- Kage box
def kage_box():
    A = "KageBox"
    # Podium on the stands (World: "Kage base" 30x16x22 at (0,-8,4)).
    put([box((0, -8, 4), (30, 16, 22), bevel=.3, segments=1)], A, "Podium", BASE_L, 40)
    put([box((0, -.6, 4), (31.5, 1.2, 23.5), bevel=.2, segments=1)], A, "PodiumCap", STONE_L, 40)
    # Hall: red pillars round a white hall, two tiers of roof.
    put([box((0, 5.5, 2), (28, 11, 12), bevel=0)], A, "Hall", PLASTER, 40)
    pillars = []
    for x in (-14.5, -9.5, -4.8, 4.8, 9.5, 14.5):
        for z in (-8.2, 8.2):
            pillars.append(cylinder((x, 0, z), .75, 11.2, 12))
    put(pillars, A, "Pillars", LACQUER, 40)
    put([box((0, 11.2, 0), (31, 1, 18), bevel=0)], A, "Lintel", LACQUER_D, 30)
    roofs = [hip_roof(20, 12.5, 5.4, 11.4, lift=1.6, thick=.6), hip_roof(13, 8, 4.4, 17.6, lift=1.3, thick=.5)]
    put(roofs, A, "Roof", ROOF, 35)
    put([box((0, 15.2, 0), (20, 3.8, 10), bevel=0)], A, "Upper", PLASTER, 40)
    put([ridge(13, 8, 4.4, 17.6, w=.9), ridge(20, 12.5, 5.4, 11.4, w=.8)], A, "Ridge", RIDGE, 30)
    put([box((0, 23.0, 0), (1.6, 1.6, 1.6), bevel=.4, segments=2)], A, "Finial", GOLD, 30)
    # Balcony out over the field (World: the box floor at (0,.5,-10.5)).
    rail = [box((0, 1.9, -13.4), (17, .35, .35), bevel=0), box((0, 1.05, -13.4), (17, .25, .25), bevel=0)]
    for x in [-8 + 16 * k / 8 for k in range(9)]:
        rail.append(box((x, 1.3, -13.4), (.35, 1.6, .35), bevel=0))
    for z in (-8, -13):
        for x in (-8.3, 8.3):
            rail.append(box((x, 1.3, (z - 13.4) / 2 if z == -13 else -10.7), (.35, 1.6, 5.4 if z == -8 else .35), bevel=0))
    put(rail, A, "Rail", LACQUER, 30)
    put([box((0, .45, -10.5), (17, .9, 6.4), bevel=.1, segments=1)], A, "BalconyFloor", TIMBER_L, 30)
    # Hanging cloth either side of the hall front.
    put([box((s * 11.5, 6.2, -6.4), (4.2, 8.6, .15), bevel=0) for s in (-1, 1)], A, "Hanging", CLOTH, 30)

# ---------------------------------------------------------------- gates
def gate():
    A = "Gate"
    # The competitors' gate: a stone frame with a carved lintel, heavy doors.
    put([box((0, 0, .25), (18, 16, .3), bevel=0)], A, "Dark", (26, 24, 22), 40)
    doors, bands = [], []
    for x in (-4.4, 4.4):
        doors.append(box((x, -.2, -.15), (8.4, 15.4, .6), bevel=.1, segments=1))
        for y in (-5.2, 0, 5.2):
            bands.append(box((x, y, -.5), (8.5, .45, .12), bevel=0))
        for y in (-5.2, 0, 5.2):
            for xx in (x - 3.4, x - 1.2, x + 1.2, x + 3.4):
                bands.append(box((xx, y, -.6), (.3, .3, .1), bevel=0))
    put(doors, A, "Doors", (112, 76, 48), 30)
    put(bands, A, "Bands", (50, 48, 48), 30)
    frame_parts = [box((0, 9.0, -.7), (23, 2.6, 2.0), bevel=.2, segments=1), box((0, 10.8, -.9), (25.5, .9, 2.6), bevel=.15, segments=1)]
    for x in (-10.6, 10.6):
        frame_parts.append(box((x, .4, -.7), (2.4, 17.4, 2.0), bevel=.2, segments=1))
        frame_parts.append(box((x, -7.6, -.9), (3.2, 1.4, 2.6), bevel=.15, segments=1))
    put(frame_parts, A, "Frame", STONE_D, 30)
    put([box((0, 9.0, -1.75), (5, 2.0, .2), bevel=0)], A, "Plaque", GOLD, 30)
    # A small tiled awning over the gate.
    put([hip_roof(13.5, 2.6, 1.6, 11.2, lift=.6, thick=.35)], A, "Awning", ROOF, 35)

# ---------------------------------------------------------------- gate tower
def gate_tower():
    """An original landmark: a timber drum tower (yagura) behind the south
    gate, rising over the stands, three storeys, a drum on the top floor."""
    A = "GateTower"
    legs, braces, floors, rails, walls = [], [], [], [], []
    put([box((0, 3, 0), (20, 6, 20), bevel=.3, segments=1)], A, "Footing", BASE_L, 40)
    for x in (-8, 8):
        for z in (-8, 8):
            legs.append(box((x, 6 + 30, z), (1.6, 60, 1.6), bevel=.1, segments=1))
    for y in (18, 36, 54):
        floors.append(box((0, y, 0), (21, 1.2, 21), bevel=.1, segments=1))
        for s in (-1, 1):
            rails.append(box((0, y + 2.2, s * 10.3), (21, .4, .4), bevel=0))
            rails.append(box((s * 10.3, y + 2.2, 0), (.4, .4, 21), bevel=0))
            for k in range(7):
                v = -9 + 18 * k / 6
                rails.append(box((v, y + 1.2, s * 10.3), (.35, 2.0, .35), bevel=0))
                rails.append(box((s * 10.3, y + 1.2, v), (.35, 2.0, .35), bevel=0))
    for y0, y1 in ((6, 18), (18, 36), (36, 54)):
        for s in (-1, 1):
            for axis in ("x", "z"):
                p0 = Vector((-8, y0, s * 8)) if axis == "x" else Vector((s * 8, y0, -8))
                p1 = Vector((8, y1, s * 8)) if axis == "x" else Vector((s * 8, y1, 8))
                d = p1 - p0
                t = d.normalized()
                side = Vector((0, 0, 1)) if axis == "x" else Vector((1, 0, 0))
                braces.append(obox((p0 + p1) / 2, (.8, .8, d.length), side.cross(t), side, t))
    put(legs, A, "Legs", TIMBER, 30)
    put(braces, A, "Braces", TIMBER_L, 30)
    put(floors, A, "Floors", TIMBER_L, 30)
    put(rails, A, "Rails", LACQUER, 30)
    # The top room with its drum, and the roof.
    walls.append(box((0, 58, 0), (15, 7, 15), bevel=0))
    put(walls, A, "Room", PLASTER, 40)
    put([box((0, 58, -7.6), (10, 4.4, .2), bevel=0)], A, "RoomOpen", (40, 30, 26), 30)
    put([loft([(0, 2.6, 2.6, 2), (.4, 2.9, 2.9, 2), (3.6, 2.9, 2.9, 2), (4, 2.6, 2.6, 2)], sides=16, center=(0, 55.5, -3))], A, "Drum", LACQUER_D, 40)
    put([cylinder((0, 55.3, -3), 2.95, .3, 16), cylinder((0, 59.3, -3), 2.95, .3, 16)], A, "DrumSkin", (226, 208, 170), 40)
    put([hip_roof(11.5, 11.5, 6.5, 61.4, lift=1.6, thick=.6)], A, "Roof", ROOF, 35)
    put([box((0, 68.5, 0), (1.6, 2.4, 1.6), bevel=.4, segments=2)], A, "Finial", GOLD, 30)
    # Long banners down the front.
    put([box((s * 5.5, 40, -10.5), (3.2, 26, .15), bevel=0) for s in (-1, 1)], A, "Banner", CLOTH, 30)
    put([box((0, 44, -10.5), (3.2, 18, .15), bevel=0)], A, "BannerW", CLOTH_W, 30)

# ---------------------------------------------------------------- vegetation
def crown():
    """Field-tree crown for spread 10 (scaled per tree): clustered facets."""
    A = "Crown"
    lumps = {LEAF: [], LEAF_D: [], LEAF_L: []}
    spots = [((0, 3, 0), (9.5, 7, 9.5), LEAF), ((-6, 0, 2), (6.5, 5, 6.5), LEAF_D), ((5.5, .6, -2.5), (6.5, 5.2, 6.5), LEAF_D),
             ((1, -.5, 6), (6, 4.6, 6), LEAF), ((-2, 1, -6), (6.2, 4.8, 6.2), LEAF), ((2, 7, 1), (6, 4.4, 6), LEAF_L),
             ((-4, 5.5, -2), (5, 4, 5), LEAF_L), ((6, 4.5, 3), (4.6, 3.6, 4.6), LEAF)]
    for k, (c, r, col) in enumerate(spots):
        lumps[col].append(lumpy(c, r, 100 + k, amount=.16))
    put(lumps[LEAF], A, "Leaves", LEAF, 20, "Grass")
    put(lumps[LEAF_D], A, "LeavesDark", LEAF_D, 20, "Grass")
    put(lumps[LEAF_L], A, "LeavesLight", LEAF_L, 20, "Grass")
    br = []
    for k in range(4):
        a = k / 4 * math.pi * 2 + .4
        p0 = Vector((0, -7, 0)); p1 = Vector((math.sin(a) * 5, -1.5, math.cos(a) * 5))
        d = p1 - p0; t = d.normalized()
        side = Vector((math.cos(a), 0, -math.sin(a)))
        br.append(obox((p0 + p1) / 2, (.9, .9, d.length), side, t.cross(side), t))
    put(br, A, "Branches", BARK, 30)

def pine_tree():
    A = "PineTree"
    put([cylinder((0, 0, 0), 1.4, 20, 8)], A, "Trunk", BARK, 30)
    tiers = []
    for k, (y, r, h) in enumerate(((12, 11, 12), (20, 9, 11), (27, 7, 10), (33, 4.6, 9))):
        tiers.append(loft([(0, r, r, 2), (h * .25, r * .8, r * .8, 2), (h, .3, .3, 2)], sides=9, center=(0, y, 0)))
    put(tiers[0::2], A, "Needles", PINE, 20, "Grass")
    put(tiers[1::2], A, "NeedlesDark", PINE_D, 20, "Grass")

def broad_tree():
    A = "BroadTree"
    put([loft([(0, 2.4, 2.4, 2), (3, 1.7, 1.7, 2), (24, 1.3, 1.3, 2)], sides=8)], A, "Trunk", BARK, 30)
    lumps = {LEAF: [], LEAF_D: []}
    for k, (c, r) in enumerate((((0, 30, 0), (14, 10, 14)), ((-9, 26, 4), (9, 7, 9)), ((8, 27, -4), (9, 7, 9)), ((3, 36, 2), (8, 6, 8)), ((-2, 25, -9), (8, 6, 8)))):
        lumps[LEAF if k % 2 == 0 else LEAF_D].append(lumpy(c, r, 200 + k, amount=.15))
    put(lumps[LEAF], A, "Leaves", LEAF, 20, "Grass")
    put(lumps[LEAF_D], A, "LeavesDark", LEAF_D, 20, "Grass")

def bush():
    A = "Bush"
    put([lumpy((0, 0, 0), (2.2, 1.7, 2.2), 300, .18, 8, 6), lumpy((1.4, -.3, .6), (1.6, 1.3, 1.6), 301, .18, 8, 6)], A, "Leaves", LEAF, 20, "Grass")
    put([lumpy((-1.3, -.2, -.5), (1.5, 1.2, 1.5), 302, .18, 8, 6)], A, "LeavesDark", LEAF_D, 20, "Grass")

wall_sector()
stand_sector()
pavilion()
kage_box()
gate()
gate_tower()
crown()
pine_tree()
broad_tree()
bush()
export("Arena_Assets", OUT)

# ------------------------------------------------ review render (not exported)
def placed(asset, pos, yaw, scale=1.0):
    for o in [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(asset + "__") and "#" not in o.name]:
        d = o.copy(); d.name = o.name + "#"; bpy.context.scene.collection.objects.link(d)
        d.location = V(*pos); d.rotation_euler = (0, 0, yaw); d.scale = (scale, scale, scale)

originals = [o for o in bpy.data.objects if o.type == "MESH"]
for k in range(8):
    placed("WallSector", (0, 0, 0), k * math.pi / 4)
    placed("StandSector", (0, 0, 0), k * math.pi / 4)
for k in range(12):
    a = k / 12 * math.pi * 2 + math.pi / 12
    if abs(math.sin(a / 2)) > .18:
        placed("Pavilion", (math.sin(a) * (BACK_R + 5), BACK_TOP - .5, math.cos(a) * (BACK_R + 5)), a)
placed("KageBox", (0, WALL_H + 16, -(RW + 12)), math.pi)
placed("Gate", (0, 8, RW - .4), 0)
placed("Gate", (-(RW - .4), 8, 0), -math.pi / 2)
placed("GateTower", (0, 0, BACK_R + 16), 0)
for spot in ((.55, 112, 38, 10), (1.6, 104, 33, 9), (2.4, 110, 36, 9.5), (3.3, 98, 31, 8.5), (3.9, 116, 40, 10.5), (5.3, 106, 35, 9.5), (6.0, 92, 29, 8)):
    at = (math.sin(spot[0]) * spot[1], spot[2] + spot[3] * .3, math.cos(spot[0]) * spot[1])
    placed("Crown", at, spot[0], spot[3] / 10)
for k in range(48):
    a = k / 48 * math.pi * 2 + .07
    r = RW + 62 + ((k * 53) % 5) * 7
    placed("PineTree" if k % 3 else "BroadTree", (math.sin(a) * r, 0, math.cos(a) * r), a * 3, 1.0 + ((k * 31) % 4) * .12)
for k in range(66):
    a = k / 66 * math.pi * 2
    placed("Bush", (math.sin(a) * (RW - 2.2), 1.2, math.cos(a) * (RW - 2.2)), a * 5, 1.0 + (k % 3) * .2)
for o in originals:
    o.hide_render = True
ground = box((0, -.5, 0), (1400, 1, 1400), bevel=0); ground.color = (.4, .55, .3, 1)
field = cylinder((0, -.4, 0), RW, .5, 64); field.color = (.62, .55, .4, 1)
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
sh = scene.display.shading
sh.light = "STUDIO"; sh.color_type = "OBJECT"; sh.show_cavity = True; sh.show_shadows = True
sh.show_object_outline = True; sh.object_outline_color = (0.05, 0.05, 0.07)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
cd = bpy.data.cameras.new("cam"); cd.lens = 24
cam = bpy.data.objects.new("cam", cd); scene.collection.objects.link(cam); scene.camera = cam
for key, (eye, target) in {"overview": ((0, 150, -300), (0, 20, 40)), "field": ((40, 9, -60), (-10, 40, 120)), "kage": ((20, 30, 40), (0, 62, -150))}.items():
    cam.location = V(*eye)
    cam.rotation_euler = (V(*target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT, "Arena_%s.png" % key)
    bpy.ops.render.render(write_still=True)
print("done")
