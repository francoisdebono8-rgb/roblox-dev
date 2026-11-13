"""The game's modelled props (13/11, user: « refais les modèles de kunai, de
shuriken utilisés en jeu ... revois tous les ultimes ... il va nous falloir des
vrais modèles 3D »). Each model is a list of nd_mesh.Piece (one material each).

  python3 fx_models.py render OUT_DIR [names...]   preview sheet
  python3 fx_models.py luau > ../../src/Client/MeshData.luau

The game builds them at run time (Client/MeshKit, EditableMesh): nothing to
upload. Blender frame: x right, y = the front (Roblox -z), z up. Units: studs.
Weapons keep the frames of the part-built ones they replace (Client/Effects):
the grip centre at the origin, the point to the front.
"""
import math, os, sys, random
import bpy  # (also brings mathutils)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Vector, Matrix, noise
from nd_mesh import Piece, rgb, lerp, smooth, loft, tube, ellipsoid, torus, model_luau, stats

STEEL = rgb(70, 74, 84)
STEEL_HI = rgb(122, 128, 140)
EDGE = rgb(206, 212, 222)
CLOTH = rgb(38, 34, 38)
CLOTH_HI = rgb(74, 64, 60)
SAND = rgb(214, 176, 112)
SAND_DARK = rgb(160, 122, 76)
SAND_HI = rgb(236, 206, 150)


# ---------------------------------------------------------------- weapons
def blade_leaf(pc, y0, y1, wmax, wbase, thick, at_max=.3, x0=0.0, steps=18, sweep=None):
    """A double-edged leaf blade along +y with a diamond section and bevelled edges."""
    rings = []
    for i in range(steps):
        s = i / (steps - 1) * .985
        y = y0 + (y1 - y0) * s
        if s < at_max:
            w = wbase + (wmax - wbase) * smooth(s / at_max) ** .8
        else:
            u = (s - at_max) / (1 - at_max)
            w = wmax * (1 - u) ** 1.05 * (1 - .12 * math.sin(u * math.pi))
        t = thick * (1 - .55 * s)
        dx = sweep(s) if sweep else 0
        sec = [(w, 0), (.62 * w, .5 * t), (0, t), (-.62 * w, .5 * t), (-w, 0), (-.62 * w, -.5 * t), (0, -t), (.62 * w, -.5 * t)]
        rings.append([Vector((x0 + dx + a, y, b)) for a, b in sec])
    tip = Vector((x0 + (sweep(1) if sweep else 0), y1, 0))

    def col(p, k):
        # the sharpened bevel bright, the flats dark steel, the ridge in between
        w = max(abs(q.x - x0 - (sweep(k / (steps - 1)) if sweep else 0)) for q in rings[min(k, steps - 1)]) or 1
        e = abs(p.x - x0 - (sweep(k / (steps - 1)) if sweep else 0)) / w
        if e > .97:
            return EDGE
        if e > .55:
            return lerp(STEEL, STEEL_HI, .35)
        return lerp(STEEL, STEEL_HI, .15 if abs(p.z) > 1e-4 else 0)
    loft(pc, rings, col, cap0=True, tip1=tip)


def wrapped_grip(pc, y0, y1, r, col_a, col_b, sides=16, steps=36, pitch=.085, diamond=False):
    rings = []
    cols = []
    for i in range(steps + 1):
        y = y0 + (y1 - y0) * i / steps
        ring = []
        for s in range(sides):
            a = s / sides * math.tau
            if diamond:
                u = a / math.tau * 6
                v = (y - y0) / pitch
                d1 = abs(((u + v) % 1) - .5)
                d2 = abs(((u - v) % 1) - .5)
                band = max(0, 1 - min(d1, d2) / .2)
                rr = r * (1 + .07 * band)
            else:
                ph = (a / math.tau + (y - y0) / pitch) % 1
                band = smooth(1 - abs(ph - .5) * 2.4)
                rr = r * (1 + .1 * band)
            ring.append(Vector((math.cos(a) * rr, y, math.sin(a) * rr)))
        rings.append(ring)
    def col(p, k):
        rr = math.hypot(p.x, p.z) / r
        return lerp(col_a, col_b, smooth((rr - 1) / (.07 if diamond else .1)))
    loft(pc, rings, col)


def collar(pc, y0, y1, r, col, sides=16):
    loft(pc, [[Vector((math.cos(a) * r, y, math.sin(a) * r)) for a in [s / sides * math.tau for s in range(sides)]] for y in (y0, y1)], col)


def kunai(marked=False):
    metal = Piece("Blade", "Metal", flat=True)
    grip = Piece("Grip", "Fabric")
    fit = Piece("Fittings", "Metal")
    blade_leaf(metal, .24, .98 if not marked else 1.04, .17, .065, .05)
    wrapped_grip(grip, -.42, .2, .058, CLOTH, CLOTH_HI)
    collar(fit, .19, .26, .074, STEEL_HI)
    collar(fit, -.45, -.41, .05, STEEL)
    torus(fit, (0, -.555, 0), Matrix.Rotation(math.pi / 2, 3, "Y"), .118, .03, lerp(STEEL, STEEL_HI, .4))
    pieces = [metal, grip, fit]
    if marked:
        # Minato's kunai: two prongs swept forward from the guard, and the
        # sealing formula tag on the grip
        for side in (-1, 1):
            pts = []
            for i in range(9):
                u = i / 8
                pts.append((side * (.07 + .17 * math.sin(u * 1.35)), .22 + .34 * u - .05 * u * u, 0))
            tube(metal, pts, lambda k: .038 * (1 - k) + .004, lambda p, k: lerp(STEEL, EDGE, k * .7), sides=6,
                 shape=lambda a, k: (1, .45), tip1=False)
        tag = Piece("SealTag", "SmoothPlastic", flat=True)
        paper, ink = rgb(236, 226, 196), rgb(28, 30, 40)
        for i in range(10):
            pass
        rings = []
        for y in (-.36, .12):
            ring = []
            for s in range(13):
                a = math.radians(-70 + 140 * s / 12) + math.pi / 2
                ring.append(Vector((math.cos(a) * .072, y, math.sin(a) * .072)))
            rings.append(ring)
        def tcol(p, k):
            a = math.degrees(math.atan2(p.z, p.x)) - 90
            line = (abs(a) < 8) or (abs(abs(a) - 38) < 6)
            return ink if line and -.32 < p.y < .08 else paper
        # denser rows so the formula lines read
        rows = [[Vector((math.cos(math.radians(-70 + 140 * s / 28) + math.pi / 2) * .072, y,
                         math.sin(math.radians(-70 + 140 * s / 28) + math.pi / 2) * .072)) for s in range(29)]
                for y in [-.36 + .48 * j / 12 for j in range(13)]]
        loft(tag, rows, tcol, closed=False, cap0=False, cap1=False)
        pieces.append(tag)
    return pieces


def shuriken():
    """Four points, concave sides, a real hole, bevelled to sharp edges."""
    pc = Piece("Shuriken", "Metal", flat=False)
    N = 96
    def outline(a):
        # straight-ish flanks from a valley (r .19 at 45 deg) to a sharp point
        # (r .62), slightly hollowed
        u = abs(((a % (math.pi / 2)) / (math.pi / 2)) - .5) * 2  # 1 at a point, 0 at a valley
        return .19 + .43 * (u ** 1.6)
    hole, t = .068, .055
    rings_top = []
    for ring_kind in ("hole_b", "hole_t", "mid_t", "edge", "mid_b", "hole_b2"):
        ring = []
        for i in range(N):
            a = i / N * math.tau + math.pi / 4
            R = outline(a)
            d = Vector((math.cos(a), math.sin(a), 0))
            if ring_kind in ("hole_b", "hole_b2"):
                p = d * hole + Vector((0, 0, -t * .75))
            elif ring_kind == "hole_t":
                p = d * hole + Vector((0, 0, t * .75))
            elif ring_kind == "mid_t":
                p = d * max(hole + .05, R * .5) + Vector((0, 0, t))
            elif ring_kind == "mid_b":
                p = d * max(hole + .05, R * .5) + Vector((0, 0, -t))
            else:
                p = d * R
            ring.append(p)
        rings_top.append(ring)
    def col(p, k):
        r = math.hypot(p.x, p.y)
        if k == 3:
            return EDGE
        if k in (2, 4):
            return lerp(STEEL, STEEL_HI, .2)
        return rgb(30, 30, 36)
    loft(pc, rings_top, col, cap0=False, cap1=False)
    # a ring engraved round the hole
    eng = Piece("Ring", "Metal")
    torus(eng, (0, 0, 0), Matrix.Identity(3), .118, .018, rgb(96, 100, 112), seg=32, sides=6)
    eng.v = [Vector((v.x, v.y, v.z * 3.1)) for v in eng.v]
    return [pc, eng]


def tanto():
    """Kakashi's White Light Chakra Sabre: diamond-wrapped grip, lobed guard,
    a single-edged blade with its ridge line and a chakra edge."""
    blade = Piece("Blade", "Metal", flat=True)
    grip = Piece("Grip", "Fabric")
    fit = Piece("Fittings", "Metal")
    glow = Piece("ChakraEdge", "Neon", alpha=.35)
    wrapped_grip(grip, -.47, .12, .075, rgb(36, 38, 48), rgb(232, 230, 222), sides=18, steps=40, pitch=.1, diamond=True)
    ellipsoid(fit, (0, -.5, 0), (.085, .05, .085), rgb(70, 72, 80), seg=14, rings=6)
    # tsuba: a four-lobed disc
    rings = []
    for y in (.13, .17):
        rings.append([Vector((math.cos(a) * (.16 + .025 * math.cos(4 * a)), y, math.sin(a) * (.16 + .025 * math.cos(4 * a))))
                      for a in [s / 32 * math.tau + math.pi / 4 for s in range(32)]])
    loft(fit, rings, rgb(46, 46, 54))
    collar(fit, .17, .25, .062, rgb(170, 150, 90))
    y0, y1, H, T = .25, 1.9, .17, .05
    rs = []
    steps = 22
    for i in range(steps):
        s = i / (steps - 1)
        y = y0 + (y1 - y0) * s
        top = H / 2
        bot = -H / 2
        kis = .82
        if s > kis:
            u = (s - kis) / (1 - kis)
            bot = -H / 2 + H * (u ** 1.5) * .96
        h = top - bot
        sh = bot + h * .62
        tt = T * (1 - .3 * s)
        rs.append([Vector((0, y, bot)), Vector((tt * .55, y, sh)), Vector((tt * .5, y, top)), Vector((-tt * .5, y, top)), Vector((-tt * .55, y, sh))])
    def bcol(p, k):
        ring = rs[min(k, len(rs) - 1)]
        bot, top = ring[0].z, ring[2].z
        u = (p.z - bot) / max(1e-4, top - bot)
        return rgb(236, 244, 255) if u < .05 else (rgb(214, 220, 230) if u < .64 else rgb(150, 156, 168))
    loft(blade, rs, bcol, tip1=Vector((0, y1 + .04, H / 2 - .005)))
    # the chakra edge: a thin glowing strip under the edge
    erings = []
    for i in range(steps):
        p = rs[i][0]
        erings.append([p + Vector((.012, 0, -.012)), p + Vector((-.012, 0, -.012)), p + Vector((0, 0, .02))])
    loft(glow, erings, rgb(225, 240, 255))
    return [blade, grip, fit, glow]


# ---------------------------------------------------------------- Gaara
def sand_col(p, k=0, base=SAND):
    n = noise.noise(p * 2.3)
    return lerp(SAND_DARK, SAND_HI, max(0, min(1, .5 + n * .9)))


def sand_coffin():
    """Sabaku Kyū: the sand wrapped round a standing body in thick spiral
    bands, lumpy, the head's shape still showing. 2.6 x 5.6 studs, centred."""
    pc = Piece("Coffin", "Sand")
    rings = []
    Z = 60
    S = 40
    for i in range(Z + 1):
        u = i / Z
        z = -2.8 + 5.6 * u
        # body profile: feet, knees, hips, chest, shoulders, neck, head
        prof = [(0, .55), (.08, .92), (.3, 1.02), (.45, 1.18), (.62, 1.22), (.72, 1.3), (.79, 1.02), (.84, .78), (.9, .9), (.97, .7), (1, .25)]
        for j in range(len(prof) - 1):
            if prof[j][0] <= u <= prof[j + 1][0]:
                a, b = prof[j], prof[j + 1]
                r = a[1] + (b[1] - a[1]) * smooth((u - a[0]) / (b[0] - a[0]))
                break
        ring = []
        for s in range(S):
            th = s / S * math.tau
            ph = (th / math.tau + z * .62) % 1
            bump = .16 * ph ** 1.5 + .05 * noise.noise(Vector((math.cos(th) * 2, math.sin(th) * 2, z * 1.7)))
            rr = r * (1 + bump)
            ring.append(Vector((math.cos(th) * rr, math.sin(th) * rr * .82, z)))
        rings.append(ring)
    def col(p, k):
        th = math.atan2(p.y / .82, p.x)
        ph = ((th / math.tau) + p.z * .62) % 1
        lip = smooth((ph - .8) / .2)
        return lerp(lerp(SAND, SAND_HI, ph * .8), SAND_DARK, max(lip * .8, 0) + max(0, noise.noise(p * 4)) * .25)
    loft(pc, rings, col, tip0=Vector((0, 0, -2.86)), tip1=Vector((0, 0, 2.86)))
    return [pc]


def sand_pillar():
    """The column that lifts the coffin: a twisting rope of sand that flares
    into the floor and opens into a cup at the top. 6 studs high, base at 0."""
    pc = Piece("Pillar", "Sand")
    rings = []
    Z, S = 40, 30
    for i in range(Z + 1):
        u = i / Z
        z = -.3 + 6.3 * u
        r = 1.05 + 1.5 * (1 - smooth(u / .22)) ** 2 + .45 * smooth((u - .82) / .18)
        ring = []
        for s in range(S):
            th = s / S * math.tau
            ridge = .16 * math.sin(th * 5 + z * 1.25)
            r2 = r * (1 + ridge * (1 - .6 * smooth((u - .85) / .15)) + .06 * noise.noise(Vector((math.cos(th) * 3, math.sin(th) * 3, z))))
            ring.append(Vector((math.cos(th) * r2, math.sin(th) * r2, z)))
        rings.append(ring)
    def col(p, k):
        th = math.atan2(p.y, p.x)
        ridge = math.sin(th * 5 + p.z * 1.25)
        dark = 1 - smooth(p.z / 2.5)
        return lerp(lerp(SAND, SAND_HI, max(0, ridge) * .7), SAND_DARK, dark * .6 + max(0, -ridge) * .35)
    loft(pc, rings, col, cap0=False, cap1=True)
    return [pc]


def sand_wave():
    """A wall of sand rearing up (the flood that runs to the body), front -y,
    3 wide x 2.4 high x 2 deep, base at 0."""
    pc = Piece("Wave", "Sand")
    rows = []
    X, Z = 24, 14
    for i in range(Z + 1):
        v = i / Z
        row = []
        for j in range(X + 1):
            u = j / X
            x = -1.5 + 3 * u
            env = math.sin(u * math.pi) ** .6
            h = 2.4 * env
            z = v * h
            # the crest curls forward
            y = .9 * (v ** 2.2) * env + .25 * noise.noise(Vector((x * 1.3, z, 0)))
            row.append(Vector((x, -y, z)))
        rows.append(row)
    back = [[Vector((p.x, p.y + .9 * (1 - i / Z) + .15, p.z)) for p in row] for i, row in enumerate(rows)]
    def col(p, k):
        return lerp(SAND_DARK, SAND_HI, max(0, min(1, p.z / 2.4 + noise.noise(p * 3) * .25)))
    # front sheet and back sheet joined along the edges = a closed shell
    loft(pc, [r for r in rows], col, closed=False, cap0=False, cap1=False)
    loft(pc, [list(reversed(r)) for r in back], col, closed=False, cap0=False, cap1=False)
    return [pc]


def sand_clump():
    """One clod of sand (the grains of the flood): a lumpy flattened lump, 1 stud."""
    pc = Piece("Clump", "Sand")
    ellipsoid(pc, (0, 0, 0), (.5, .45, .36), lambda p, k: lerp(SAND_DARK, SAND_HI, max(0, min(1, .55 + p.z + noise.noise(p * 5) * .4))),
              seg=10, rings=7, bump=lambda d: .22 * noise.noise(d * 2.2 + Vector((3, 1, 2))))
    return [pc]




# ---------------------------------------------------------------- ultimates
def rock():
    """A broken stone (craters, the floor Lee's gates lift): faceted, 1 stud."""
    pc = Piece("Rock", "Slate", flat=True)
    ellipsoid(pc, (0, 0, 0), (.55, .45, .38), lambda p, k: lerp(rgb(96, 88, 78), rgb(150, 140, 124), max(0, min(1, .5 + p.z * 1.2 + noise.noise(p * 4) * .3))),
              seg=9, rings=6, bump=lambda d: .3 * noise.noise(d * 1.7 + Vector((5, 2, 1))))
    return [pc]


def katana():
    """A katana for Itachi's Tsukuyomi (the swords): a long curved blade,
    dark grip; 4.2 long, the point to the front, the grip centre at the origin."""
    blade = Piece("Blade", "Metal", flat=True)
    grip = Piece("Grip", "Fabric")
    fit = Piece("Fittings", "Metal")
    wrapped_grip(grip, -.95, .05, .07, rgb(20, 20, 24), rgb(70, 22, 26), sides=14, steps=30, pitch=.12, diamond=True)
    rings = []
    for y in (.06, .1):
        rings.append([Vector((math.cos(a) * .15, y, math.sin(a) * .13)) for a in [s / 24 * math.tau for s in range(24)]])
    loft(fit, rings, rgb(40, 40, 46))
    rs = []
    H, T, steps = .15, .045, 26
    for i in range(steps):
        u = i / (steps - 1)
        y = .1 + 3.1 * u
        curve = .18 * u * u
        top, bot = H / 2, -H / 2
        if u > .9:
            v = (u - .9) / .1
            bot = -H / 2 + H * v ** 1.4 * .95
        sh = bot + (top - bot) * .66
        tt = T * (1 - .3 * u)
        rs.append([Vector((0, y, bot + curve)), Vector((tt * .55, y, sh + curve)), Vector((tt * .5, y, top + curve)),
                   Vector((-tt * .5, y, top + curve)), Vector((-tt * .55, y, sh + curve))])
    def bcol(p, k):
        ring = rs[min(k, len(rs) - 1)]
        u = (p.z - ring[0].z) / max(1e-4, ring[2].z - ring[0].z)
        return rgb(220, 226, 236) if u < .3 else rgb(120, 126, 138)
    loft(blade, rs, bcol, tip1=rs[-1][2] + Vector((0, .05, -.01)))
    return [blade, grip, fit]


def tsukuyomi_cross():
    """The cross of the Tsukuyomi: two rough timbers lashed with rope; the
    post 9 high (base at 0), the bar 6 wide at 5.4."""
    wood = Piece("Timber", "Wood", flat=True)
    rope = Piece("Rope", "Fabric")
    def timber(a, b, w, d):
        pts = [a.lerp(b, i / 12) for i in range(13)]
        def col(p, k):
            g = noise.noise(Vector((p.x * 9, p.y * 9, p.z * .8)) if abs(b.z - a.z) > 1 else Vector((p.x * .8, p.y * 9, p.z * 9)))
            return lerp(rgb(34, 20, 18), rgb(70, 44, 36), max(0, min(1, .5 + g * .9)))
        tube(wood, pts, lambda k: 1, col, sides=4, shape=lambda t, k: ((w + .03 * noise.noise(Vector((k * 7, t, 0)))) * 1.41, (d + .03 * noise.noise(Vector((t, k * 7, 1)))) * 1.41), twist=0)
    timber(Vector((0, 0, -.2)), Vector((0, 0, 9)), .36, .26)
    timber(Vector((-3, -.05, 5.4)), Vector((3, -.05, 5.4)), .3, .22)
    for x in (-2.3, 2.3, 0):
        for j in range(4):
            z = 5.4 + (j - 1.5) * .09
            pts = [Vector((x + .2 * math.cos(a), -.05 + .2 * math.sin(a), z + .02 * math.sin(a * 3))) for a in [i / 12 * math.tau for i in range(13)]]
            tube(rope, pts, .035, rgb(150, 120, 80), sides=5)
    return [wood, rope]


def bandage_wrap():
    """Lee's bandage wound round the held body: a ribbon spiralling up a
    radius-1.05 column, 4.6 high, centred, frayed ends loose."""
    pc = Piece("Bandage", "Fabric")
    rows_in, rows_out = [], []
    N = 140
    for i in range(N + 1):
        u = i / N
        a = u * math.tau * 4.2
        z = -2.3 + 4.6 * u
        r = 1.05 + .04 * math.sin(a * 3)
        tilt = .28
        c, sn = math.cos(a), math.sin(a)
        rows_in.append(Vector((c * r, sn * r, z - tilt / 2)))
        rows_out.append(Vector((c * r, sn * r, z + tilt / 2)))
    for k, (a, b) in enumerate(((rows_in, rows_out),)):
        pass
    # a thin ribbon: two sheets a hair apart so it reads from inside and out
    def col(p, k):
        return lerp(rgb(214, 206, 188), rgb(246, 242, 232), max(0, min(1, .6 + noise.noise(p * 6) * .5)))
    strips = [[rows_in[i], rows_out[i], rows_out[i] * 1.03, rows_in[i] * 1.03] for i in range(N + 1)]
    loft(pc, strips, col, cap0=True, cap1=True)
    return [pc]


def trigrams():
    """Neji's Hakke field on the floor: the circle, the eight trigrams (three
    lines each, broken or whole), the yin-yang at the centre. 16 across, flat."""
    lines = Piece("Trigrams", "Neon")
    disc = Piece("Field", "Neon", alpha=.72)
    col = rgb(206, 214, 255)
    # rings
    for r, w in ((7.6, .12), (7.25, .05), (4.6, .06)):
        rows = []
        for i in range(97):
            a = i / 96 * math.tau
            rows.append([Vector((math.cos(a) * (r - w), math.sin(a) * (r - w), 0)), Vector((math.cos(a) * (r + w), math.sin(a) * (r + w), 0)),
                         Vector((math.cos(a) * (r + w), math.sin(a) * (r + w), .03)), Vector((math.cos(a) * (r - w), math.sin(a) * (r - w), .03))])
        loft(lines, rows, col, cap0=False, cap1=False)
    # the eight trigrams (King Wen order, outer line first)
    TRI = ["111", "000", "100", "010", "001", "011", "101", "110"]
    for k, code in enumerate(TRI):
        a = k * math.pi / 4
        d = Vector((math.cos(a), math.sin(a), 0))
        t = Vector((-math.sin(a), math.cos(a), 0))
        for j, bit in enumerate(code):
            r = 6.7 - j * .5
            segs = [(-.9, .9)] if bit == "1" else [(-.9, -.15), (.15, .9)]
            for s0, s1 in segs:
                c = d * r
                p = [c + t * s0 - d * .14, c + t * s1 - d * .14, c + t * s1 + d * .14, c + t * s0 + d * .14]
                loft(lines, [[q for q in p], [q + Vector((0, 0, .04)) for q in p]], col)
    # the yin-yang: a disc of two halves, the dots
    rows = []
    for i in range(65):
        a = i / 64 * math.tau
        rows.append(Vector((math.cos(a) * 1.6, math.sin(a) * 1.6, 0)))
    yin = Piece("Taiji", "Neon")
    from mathutils.geometry import tessellate_polygon
    def poly(pts, cc, z=.02):
        tris = tessellate_polygon([[Vector((p[0], p[1], 0)) for p in pts]])
        idx = [yin.add(Vector((p[0], p[1], z)), cc) for p in pts]
        for t in tris:
            yin.face(idx[t[0]], idx[t[1]], idx[t[2]])
    R = 1.6
    light = []
    for i in range(33):
        a = -math.pi / 2 + math.pi * i / 32
        light.append((math.cos(a) * R, math.sin(a) * R))
    for i in range(1, 17):
        a = math.pi / 2 + math.pi * i / 16
        light.append((math.cos(a) * R / 2, R / 2 + math.sin(a) * R / 2))
    for i in range(1, 16):
        a = math.pi / 2 - math.pi * i / 16
        light.append((math.cos(a) * R / 2, -R / 2 + math.sin(a) * R / 2))
    dark = [(-x, -y) for x, y in light]
    poly(light, col)
    poly(dark, rgb(60, 70, 130))
    for cy, cc in ((R / 2, rgb(60, 70, 130)), (-R / 2, col)):
        poly([(math.cos(a) * .22, cy + math.sin(a) * .22) for a in [i / 16 * math.tau for i in range(16)]], cc, z=.04)
    # the faint field
    fr = [[Vector((math.cos(a) * 7.6, math.sin(a) * 7.6, -.01)) for a in [i / 64 * math.tau for i in range(64)]]]
    loft(disc, fr + [[v * .001 for v in fr[0]]], rgb(150, 160, 255), cap0=False, cap1=False)
    return [disc, lines, yin]


# ---------------------------------------------------------------- creatures
# Kakashi's ninken (Client/HoundFX): Pakkun the small tan pug-nosed one, then
# the pack; the Konoha headband round the forehead. The body (head, ears,
# headband, tail) is one model, each leg another (on the dog's hip joints).
# Units: the dog at scale 1, its root at mid-body height, front +y here.
COATS = [(rgb(204, 168, 118), rgb(236, 214, 180)), (rgb(104, 104, 116), rgb(196, 196, 204)),
         (rgb(122, 90, 62), rgb(206, 184, 150)), (rgb(58, 56, 62), rgb(214, 210, 206))]


def ninken(i):
    coat, pale = COATS[i]
    fur = Piece("Fur", "Fabric")
    dark = Piece("Dark", "SmoothPlastic")
    band = Piece("Headband", "Fabric")
    plate = Piece("Plate", "Metal", flat=True)
    def furcol(p, k):
        belly = smooth((-p.z - .05) / .2) if p.y < .55 else 0
        muzzle = smooth((p.y - 1.15) / .1)
        n = noise.noise(p * 7) * .06
        return lerp(lerp(coat, pale, max(belly, muzzle)), rgb(0, 0, 0), max(0, n))
    # the body: rump to a deep chest
    prof = [(-.8, .3, .3, .06), (-.55, .42, .4, .04), (-.1, .36, .36, 0), (.3, .45, .48, -.02), (.62, .36, .42, .06), (.75, .18, .2, .14)]
    rings = []
    for j in range(17):
        y = -.8 + 1.55 * j / 16
        w, h, z0 = interp(prof, y)
        rings.append([Vector((math.cos(a) * w, y, z0 + math.sin(a) * h)) for a in [s_ / 18 * math.tau for s_ in range(18)]])
    loft(fur, rings, furcol)
    # neck and head
    tube(fur, [Vector((0, .5, .25)), Vector((0, .7, .45)), Vector((0, .85, .55))], lambda k: .26 - .04 * k, furcol, sides=12)
    ellipsoid(fur, (0, .95, .62), (.3, .3, .28), furcol, seg=14, rings=9)
    # the muzzle, a little open on the bite
    tube(fur, [Vector((0, 1.1, .56)), Vector((0, 1.26, .52)), Vector((0, 1.38, .5))], lambda k: .16 - .04 * k, furcol, sides=10, shape=lambda a, k: (1, .8))
    tube(fur, [Vector((0, 1.08, .42)), Vector((0, 1.24, .36)), Vector((0, 1.32, .34))], lambda k: .1 - .03 * k, pale, sides=8, shape=lambda a, k: (1, .5))
    ellipsoid(dark, (0, 1.42, .55), (.07, .05, .05), rgb(20, 18, 20), seg=8, rings=5)
    ellipsoid(dark, (0, 1.25, .45), (.1, .1, .03), rgb(120, 30, 40), seg=8, rings=4)
    for side in (-1, 1):
        ellipsoid(dark, (side * .15, 1.17, .7), (.045, .03, .05), rgb(16, 14, 16), seg=8, rings=5)
        # ears: soft triangles, up and back
        tube(fur, [Vector((side * .18, .9, .82)), Vector((side * .26, .82, 1.02)), Vector((side * .3, .74, 1.12))],
             lambda k: .12 * (1 - k) + .01, lambda p, k: lerp(coat, rgb(30, 26, 26), k * .5), sides=6, shape=lambda a, k: (1, .35))
    # the Konoha headband round the forehead, its plate on the front
    br = []
    for jj in range(2):
        z = .74 + jj * .1
        br.append([Vector((math.cos(a) * .3, .95 + math.sin(a) * .3, z)) for a in [s_ / 20 * math.tau for s_ in range(20)]])
    br = [[Vector((v.x, .95 + (v.y - .95), v.z)) for v in r] for r in br]
    loft(band, br, rgb(40, 52, 96), cap0=False, cap1=False)
    p0 = Vector((0, 1.24, .79))
    loft(plate, [[p0 + Vector((-.13, 0, -.05)), p0 + Vector((.13, 0, -.05)), p0 + Vector((.13, 0, .05)), p0 + Vector((-.13, 0, .05))],
                 [p0 + Vector((-.13, .03, -.05)), p0 + Vector((.13, .03, -.05)), p0 + Vector((.13, .03, .05)), p0 + Vector((-.13, .03, .05))]],
         rgb(190, 196, 206))
    # the tail, up and curled
    tube(fur, [Vector((0, -.75, .2)), Vector((0, -.95, .45)), Vector((0, -.9, .7)), Vector((0, -.78, .78))], lambda k: .09 * (1 - k * .6), furcol, sides=8)
    # the mantle: a short dark vest over the back
    vest = Piece("Vest", "Fabric")
    vr = []
    for j in range(9):
        y = -.45 + .95 * j / 8
        w, h, z0 = interp(prof, y)
        vr.append([Vector((math.cos(a) * w * 1.06, y, z0 + math.sin(a) * h * 1.06)) for a in [math.radians(-20 + 220 * q / 12) for q in range(13)]])
    loft(vest, vr, rgb(48, 54, 74), closed=False, cap0=False, cap1=False)
    return [fur, dark, band, plate, vest]


def ninken_leg(i):
    coat, pale = COATS[i]
    leg = Piece("Leg", "Fabric")
    tube(leg, [Vector((0, 0, .05)), Vector((0, .02, -.3)), Vector((0, -.04, -.55)), Vector((0, .02, -.68))], lambda k: .1 - .03 * k, lambda p, k: lerp(coat, pale, k * .6), sides=8)
    ellipsoid(leg, (0, .06, -.71), (.08, .11, .05), pale, seg=8, rings=5)
    return [leg]

# ---------------------------------------------------------------- dragons
# Kakashi's Suiryūdan and Doryūdan (user 13/11: « les dragons ça va pas trop,
# cherche des modèles de dragons en 3D »): the anime's eastern dragon, fierce,
# not cute: a long angular skull under a heavy brow, deep-set glaring eyes, a
# mouth open on rows of fangs, horns swept far back, a mane of blades, long
# whiskers; a serpent body of overlapping scaled segments with a dorsal crest.
# Head width ~1.6 at scale 1 (Client/DragonFX scales to the look).
DRAGON = {
    "Water": {"base": rgb(70, 150, 235), "dark": rgb(24, 70, 170), "belly": rgb(200, 232, 255), "crest": rgb(236, 248, 255),
              "horn": rgb(214, 238, 255), "eye": rgb(190, 250, 255), "mouth": rgb(20, 40, 110), "mat": "Glass", "flat": False, "rough": 0.0},
    "Earth": {"base": rgb(132, 104, 74), "dark": rgb(74, 58, 42), "belly": rgb(160, 138, 104), "crest": rgb(96, 80, 62),
              "horn": rgb(70, 58, 46), "eye": rgb(255, 150, 40), "mouth": rgb(50, 30, 20), "mat": "Slate", "flat": True, "rough": .07},
}


def interp(table, y):
    for i in range(len(table) - 1):
        a, b = table[i], table[i + 1]
        if a[0] <= y <= b[0]:
            t = smooth((y - a[0]) / (b[0] - a[0]))
            return tuple(a[k] + (b[k] - a[k]) * t for k in range(1, len(a)))
    return tuple(table[-1][1:]) if y > table[-1][0] else tuple(table[0][1:])


def rough(p, st, f=3.0):
    if not st["rough"]:
        return p
    n = noise.noise_vector(p * f)
    return p + n * st["rough"]


def dragon_head(st):
    skull = Piece("Skull", st["mat"], flat=st["flat"])
    jaw = Piece("Jaw", st["mat"], flat=st["flat"])
    teeth = Piece("Teeth", "SmoothPlastic", flat=True)
    horn = Piece("Horns", "SmoothPlastic" if st["mat"] == "Glass" else st["mat"], flat=st["flat"])
    eye = Piece("Eyes", "Neon")
    pupil = Piece("Pupils", "SmoothPlastic")
    # y, half width, top, bottom (upper jaw line)
    prof = [(-.75, .5, .45, -.3), (-.4, .74, .62, -.4), (0, .8, .66, -.4), (.35, .66, .56, -.32), (.7, .5, .4, -.24),
            (1.1, .44, .32, -.2), (1.45, .44, .33, -.18), (1.75, .36, .28, -.14), (1.95, .2, .18, -.08)]
    S, Y = 28, 30
    rings = []
    for i in range(Y + 1):
        y = -.75 + 2.7 * i / Y
        w, top, bot = interp(prof, y)
        ring = []
        for s in range(S):
            a = s / S * math.tau
            c, sn = math.cos(a), math.sin(a)
            x = w * (abs(c) ** .7) * (1 if c >= 0 else -1)
            z = (top if sn > 0 else -bot) * (abs(sn) ** .8) * (1 if sn >= 0 else -1)
            # heavy brow ridge overhanging the eyes, sockets under it, the
            # nostrils flared on the snout
            def g2(y0, sy, a0, sa):
                return math.exp(-((y - y0) / sy) ** 2) * (math.exp(-((a - math.radians(a0)) / sa) ** 2) + math.exp(-((a - math.radians(180 - a0)) / sa) ** 2))
            brow = g2(.42, .2, 42, .3)
            sock = g2(.36, .13, 16, .2)
            nost = g2(1.7, .1, 58, .28)
            cheek = g2(-.1, .3, -15, .4)
            ridge = math.exp(-((a - math.pi / 2) / .25) ** 2) * (.06 if y < 1.2 else .02)
            k = 1 + .55 * brow - .3 * sock + .28 * nost + .12 * cheek
            p = Vector((x * k, y, z * k + ridge))
            ring.append(rough(p, st))
        rings.append(ring)

    def scol(p, k):
        up = p.z
        if up < -.12:
            return st["mouth"] if p.y > -.2 else st["belly"]
        g = smooth((up + .1) / .7)
        c = lerp(st["base"], st["dark"], g * .7)
        if abs(p.x) < .12 and up > .25:
            c = lerp(c, st["crest"], .35)
        return c
    loft(skull, rings, scol, tip1=Vector((0, 2.0, .02)))
    # the lower jaw, open ~28 deg about its hinge under the ear
    hinge = Vector((0, -.25, -.32))
    R = Matrix.Rotation(math.radians(-28), 3, "X")
    jprof = [(-.35, .62, -.05, -.28), (.2, .55, -.02, -.3), (.8, .42, -.02, -.24), (1.3, .34, -.02, -.2), (1.65, .26, -.01, -.14), (1.8, .14, 0, -.06)]
    jr = []
    for i in range(21):
        y = -.35 + 2.15 * i / 20
        w, top, bot = interp(jprof, y)
        ring = []
        for s in range(20):
            a = s / 20 * math.tau
            c, sn = math.cos(a), math.sin(a)
            x = w * (abs(c) ** .7) * (1 if c >= 0 else -1)
            z = (top if sn > 0 else bot) * abs(sn) ** .8 if sn > 0 else bot * abs(sn) ** .8
            if sn > 0:
                z = top
            p = Vector((x, y, z - .32))
            ring.append(hinge + R @ (rough(p, st) - hinge))
        jr.append(ring)

    def jcol(p, k):
        return st["mouth"] if (R.inverted() @ (p - hinge)).z > -.06 else lerp(st["belly"], st["base"], .3)
    loft(jaw, jr, jcol, tip1=hinge + R @ (Vector((0, 1.86, -.36)) - hinge))
    # tongue: a forked ribbon in the jaw
    tongue = [hinge + R @ (Vector((0, -.1 + 1.5 * u, -.3 + .05 * math.sin(u * 5))) - hinge) for u in [i / 10 for i in range(11)]]
    tube(jaw, tongue, lambda k: .09 * (1 - k * .6), rgb(200, 40, 60), sides=8, shape=lambda a, k: (1, .35))
    # teeth: upper row down from the jaw line, lower row up; fangs at the front
    toothc = rgb(250, 248, 240) if st["mat"] == "Glass" else rgb(232, 222, 196)
    for side in (-1, 1):
        for i in range(9):
            y = .1 + i * .19
            w, top, bot = interp(prof, y)
            fang = 1.9 if i in (6, 7) else 1.0
            base = Vector((side * w * .82, y, bot + .02))
            tube(teeth, [base, base + Vector((side * .01, .02, -.11 * fang))], lambda k: .045 * fang * (1 - k) + .002, toothc, sides=5, cap1=False)
            w2, _, _ = interp(jprof, y)
            lb = hinge + R @ (Vector((side * w2 * .82, y, -.33)) - hinge)
            up = R @ Vector((0, .01, .1 * (1.6 if i in (5, 6) else 1)))
            tube(teeth, [lb, lb + up], lambda k: .04 * (1 - k) + .002, toothc, sides=5, cap1=False)
    # eyes: narrow, slanted, glowing, a thin slit; deep under the brow
    for side in (-1, 1):
        c = Vector((side * .6, .4, .24))
        rot = Matrix.Rotation(side * math.radians(-22), 3, "Y")
        e0 = len(eye.v)
        ellipsoid(eye, (0, 0, 0), (.05, .17, .055), st["eye"], seg=12, rings=8)
        eye.v[e0:] = [c + rot @ v for v in eye.v[e0:]]
        p0 = len(pupil.v)
        ellipsoid(pupil, (0, 0, 0), (.02, .022, .05), rgb(10, 10, 14), seg=8, rings=6)
        pupil.v[p0:] = [c + Vector((side * .035, .02, 0)) + rot @ v for v in pupil.v[p0:]]
    # horns: long, swept back and up then out, ringed; a tine forward
    for side in (-1, 1):
        pts = []
        for i in range(14):
            u = i / 13
            pts.append(Vector((side * (.32 + .35 * u + .25 * u * u), -.2 - 2.4 * u, .62 + 1.05 * u - .55 * u * u)))
        tube(horn, pts, lambda k: (.17 * (1 - k) ** .8 + .012) * (1 + .12 * (math.sin(k * 40) > .3)), lambda p, k: lerp(st["horn"], st["dark"], .35 * k), sides=8)
        b = pts[4]
        tube(horn, [b, b + Vector((side * .15, .35, .35))], lambda k: .07 * (1 - k) + .005, st["horn"], sides=6)
        # cheek fins / spikes back from the jaw corner
        for j in range(3):
            o = Vector((side * .78, -.2 - j * .15, -.05 - j * .12))
            tube(horn, [o, o + Vector((side * (.35 + .1 * j), -.6 - .1 * j, -.05))], lambda k: .07 * (1 - k) + .004, st["crest"], sides=5, shape=lambda a, k: (1, .35))
    mane = Piece("Mane", "SmoothPlastic" if st["mat"] == "Glass" else st["mat"], flat=True, alpha=.08 if st["mat"] == "Glass" else 0)
    # the mane: blades flowing back down the neck from behind the jaw and the
    # nape, under the horns (it waves in the anime, it is still here)
    for j in range(15):
        side = -1 if j % 2 else 1
        t = j / 14
        a = math.radians(10 + 150 * t) if side > 0 else math.radians(170 - 150 * t)
        root = Vector((math.cos(a) * .62, -.45 - .25 * t, math.sin(a) * .5 + .05))
        out = Vector((math.cos(a) * .55, -1.6 - .5 * math.sin(t * 3), math.sin(a) * .35 + .1))
        mid = root + out * .5 + Vector((math.cos(a) * .15, 0, .12))
        tube(mane, [root, mid, root + out + Vector((0, 0, .05 * math.sin(j)))], lambda k: .19 * (1 - k) ** .8 + .01,
             lambda p, k: lerp(st["crest"], st["base"], .35 * k), sides=4, shape=lambda aa, k: (1, .22))
    # whiskers: long, flowing back from the upper lip
    whisk = Piece("Whiskers", "SmoothPlastic")
    for side in (-1, 1):
        pts = [Vector((side * (.4 + .75 * u + .2 * math.sin(u * 4)), 1.6 - 2.6 * u, -.12 - .3 * u + .16 * math.sin(u * 4.5))) for u in [i / 16 for i in range(17)]]
        tube(whisk, pts, lambda k: .06 * (1 - k) + .01, st["crest"], sides=6)
    return [skull, jaw, teeth, horn, eye, pupil, mane, whisk]


def dragon_seg(st):
    """One body segment, 1.35 long round its centre (it overlaps its
    neighbours at 1.1 spacing), radius .58: scaled plates on the back, a
    ridged pale belly, a dorsal crest blade."""
    body = Piece("Body", st["mat"], flat=st["flat"])
    crest = Piece("Crest", "SmoothPlastic" if st["mat"] == "Glass" else st["mat"], flat=True, alpha=.08 if st["mat"] == "Glass" else 0)
    S, Y = 24, 14
    rings = []
    for i in range(Y + 1):
        u = i / Y
        y = -.68 + 1.36 * u
        r = .58 * (1 - .22 * (2 * u - 1) ** 4)
        ring = []
        for s in range(S):
            a = s / S * math.tau
            belly = math.sin(a) < -.55
            scale = .035 * (1 - abs(((s % 3) / 3 + u * 2) % 1 - .5) * 2) if not belly else .025 * (math.sin(u * math.tau * 3) > 0)
            rr = r * (1 + scale)
            ring.append(rough(Vector((math.cos(a) * rr, y, math.sin(a) * rr * .92)), st, 4))
        rings.append(ring)

    def col(p, k):
        a = math.atan2(p.z, p.x)
        if math.sin(a) < -.55:
            return lerp(st["belly"], st["base"], .15 * ((k % 2) == 0))
        g = smooth((math.sin(a) + .2) / 1.2)
        return lerp(lerp(st["base"], st["dark"], g * .6), st["crest"], .12 * ((k + (1 if p.x > 0 else 0)) % 2))
    loft(body, rings, col)
    pts = [Vector((0, -.55 + 1.1 * u, .5)) for u in [i / 6 for i in range(7)]]
    # the crest: a row of swept blades along the spine
    for j in range(2):
        b = Vector((0, -.35 + .6 * j, .48))
        tube(crest, [b, b + Vector((0, -.25, .3)), b + Vector((0, -.6, .5))], lambda k: .14 * (1 - k) + .01, st["crest"], sides=4, shape=lambda a, k: (.18, 1))
    return [body, crest]


MODELS = {
    **{"Ninken%d" % (i + 1): (lambda i=i: ninken(i)) for i in range(4)},
    **{"NinkenLeg%d" % (i + 1): (lambda i=i: ninken_leg(i)) for i in range(4)},
    "Rock": rock,
    "Katana": katana,
    "TsukuyomiCross": tsukuyomi_cross,
    "BandageWrap": bandage_wrap,
    "Trigrams": trigrams,
    "WaterDragonHead": lambda: dragon_head(DRAGON["Water"]),
    "WaterDragonSeg": lambda: dragon_seg(DRAGON["Water"]),
    "EarthDragonHead": lambda: dragon_head(DRAGON["Earth"]),
    "EarthDragonSeg": lambda: dragon_seg(DRAGON["Earth"]),
    "SandClump": sand_clump,
    "Kunai": lambda: kunai(False),
    "MarkedKunai": lambda: kunai(True),
    "Shuriken": shuriken,
    "Tanto": tanto,
    "SandCoffin": sand_coffin,
    "SandPillar": sand_pillar,
}


def luau(names=None):
    out = ["-- Generated by tools/blender/fx_models.py: the game's modelled props.",
           "-- Per model, its pieces (one material each): o = the piece's centre in the",
           "-- model's frame (Roblox: x right, y up, front -z; studs), v = vertices",
           "-- round that centre, t = triangles (1-based), c = vertex colours (sRGB).",
           "-- Built at run time by Client/MeshKit. Do not edit: re-run the script.",
           "return {"]
    for name, fn in MODELS.items():
        if names and name not in names:
            continue
        out.append(model_luau(name, fn()))
    out.append("}")
    return "\n".join(out) + "\n"


def render_dragon(out_dir, style):
    """The whole dragon as the game lays it: the head, then segments at 1.1
    spacing (x1.1 scale, tapering to .38) along a rearing S curve."""
    import bpy
    from nd_mesh import to_blender, render_set, clear
    clear()
    st = DRAGON[style]
    objs = [to_blender(p) for p in dragon_head(st)]
    seg = [to_blender(p, link=False) for p in dragon_seg(st)]
    n = 14
    prev = Vector((0, 0, 0))
    pts = []
    for i in range(1, n + 1):
        u = i / n
        pts.append(Vector((math.sin(u * 4.2) * 2.2, -1.1 * i * 1.1, -math.sin(u * 2.6) * 3.2 + u * 1.5)))
    for i, p in enumerate(pts):
        k = 1.1 * (1 - (i + 1) / n * .62)
        nxt = pts[i - 1] if i > 0 else Vector((0, .5, 0))
        q = (nxt - p).to_track_quat("Y", "Z")
        for o in seg:
            c = o.copy()
            bpy.context.collection.objects.link(c)
            c.location = p
            c.rotation_mode = "QUATERNION"
            c.rotation_quaternion = q
            c.scale = (k, k, k)
            objs.append(c)
    render_set(objs, os.path.join(out_dir, style + "DragonFull.png"), view=(1.4, .9, .55), size=(720, 540), fill=.7)
    print("rendered", style, "full", flush=True)


def render(out_dir, names=None):
    import bpy
    from nd_mesh import to_blender, render_set, clear
    os.makedirs(out_dir, exist_ok=True)
    for style in ("Water", "Earth"):
        if names and style + "DragonFull" in names:
            render_dragon(out_dir, style)
    if names and all(n.endswith("Full") for n in names):
        return
    if names and any("Dragon" in n for n in names):
        pass
    views = {"Ninken1": (1.2, .8, .4), "Ninken2": (1.2, .8, .4), "Trigrams": (.1, -.3, 1), "TsukuyomiCross": (.6, -1, .3), "BandageWrap": (1, -1, .4), "WaterDragonHead": (1.3, .7, .35), "EarthDragonHead": (1.3, .7, .35), "Shuriken": (0.25, -0.5, 1.0), "SandCoffin": (1, -1.6, .35), "SandPillar": (1, -1.6, .45)}
    for name, fn in MODELS.items():
        if names and name not in names:
            continue
        clear()
        pieces = fn()
        objs = [to_blender(p) for p in pieces]
        big = "Dragon" in name
        render_set(objs, os.path.join(out_dir, name + ".png"), view=views.get(name, (0.9, -0.25, 1.0)),
                   size=(720, 540) if big else (480, 360), fill=.75 if big else 1.15)
        v, t = stats(pieces)
        print("rendered", name, v, "verts", t, "tris", flush=True)


def write(src_dir, limit=110000):
    """Writes Client/MeshData.luau (the index) and MeshData1..n (chunks under
    `limit` bytes each, so no script gets too big for Studio)."""
    chunks, cur, size = [], [], 0
    for name, fn in MODELS.items():
        text = model_luau(name, fn())
        if cur and size + len(text) > limit:
            chunks.append(cur)
            cur, size = [], 0
        cur.append(text)
        size += len(text)
    if cur:
        chunks.append(cur)
    head = "-- Generated by tools/blender/fx_models.py. Do not edit: re-run the script.\n"
    old = [f for f in os.listdir(src_dir) if f.startswith("MeshData") and f.endswith(".luau")]
    for f in old:
        os.remove(os.path.join(src_dir, f))
    for i, c in enumerate(chunks, 1):
        with open(os.path.join(src_dir, "MeshData%d.luau" % i), "w") as fh:
            fh.write(head + "return {\n" + "\n".join(c) + "\n}\n")
    with open(os.path.join(src_dir, "MeshData.luau"), "w") as fh:
        fh.write(head + "-- The game's modelled props (Client/MeshKit builds them). Per model, its\n"
                 "-- pieces (one material each): o = the piece's centre in the model's frame\n"
                 "-- (Roblox: x right, y up, front -z; studs), h = its half extents, n vertices,\n"
                 "-- m triangles, d = the packed mesh (see tools/blender/nd_mesh.piece_luau).\n"
                 "local all={}\n"
                 "for _,name in {%s} do\n"
                 "\tfor k,v in require(script.Parent[name]) do all[k]=v end\n"
                 "end\nreturn all\n" % ",".join('"MeshData%d"' % i for i in range(1, len(chunks) + 1)))
    print("wrote", len(chunks), "chunks", [sum(len(t) for t in c) for c in chunks])


if __name__ == "__main__":
    if sys.argv[1] == "write":
        write(sys.argv[2])
    elif sys.argv[1] == "luau":
        sys.stdout.write(luau(sys.argv[2:] or None))
    else:
        render(sys.argv[2], sys.argv[3:] or None)
