"""The six houses of the new Konoha (19/11, DEC-042; plan: tools/blender/konoha_layout.py).

Each is ONE reusable model, 800 to 2 000 triangles (the budget is asserted, measured on the
built pieces), registered in konoha_models.MODELS under the layout's own model name, so the
builder (Server/Hub) puts a model where KonohaLayout.Buildings names it, and hub_fbx.py exports
it with the other village models.

Frame (konoha_models): Roblox's (x, y up, z), studs of HubMap's base frame (before HubMap.Scale).
Origin at the centre of the foot; the door looks at +Z (KonohaLayout: yaw 0 = the front faces
+Z); `width` along X, `depth` along Z, as REF below. The builder scales X and Z to the lot's
footprint (w, d in KonohaLayout) and keeps Y: the layout's height is this model's wall top.

Part I references: the colourful plaster blocks with a round wooden water tank on the roof,
the tiled two-storey machiya with a lattice front, the shop with its noren and awning, the
walkway apartment blocks, the clan halls on a stone base with an engawa. No logos: the sign
boards carry plain strokes, never a real word.

    blender -b --python konoha_houses.py -- render OUT_DIR [names]   preview + triangle counts
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Matrix, Vector
from nd_mesh import Piece, rgb, lerp

FLOOR = 7.0
# model: (width, depth, wall top, triangle budget) - KonohaLayout.Houses mirrors these
REF = {
    "small_house": (14, 14, 7, 900),
    "machiya": (17, 17, 14, 1400),
    "tank_house": (17, 16, 21, 1800),
    "shop_house": (20, 16, 14, 1500),
    "apartment": (24, 16, 21, 2000),
    "tower_house": (13, 13, 28, 2000),
    "clan_house": (22, 17, 9, 1600),
    # (23/11, passe commune 1: « un mix entre le vrai et le généré », Edo post towns and Kyoto)
    "edo_townhouse": (18, 16, 12, 2000),
    "edo_inn": (24, 18, 13, 2000),
    "kura": (12, 10, 10, 1400),
    "tea_shop": (16, 14, 7, 1600),
    "farmhouse": (20, 16, 5, 1800),
}
MIN_TRIS = 800


def K():
    import konoha_models as km  # lazy: konoha_models imports this module at its end
    return km


def T(x, y=0, z=0):
    return Matrix.Translation((x, y, z))


def Ry(a):
    return Matrix.Rotation(a, 4, "Y")


def Rx(a):
    return Matrix.Rotation(a, 4, "X")


FRONT = Ry(-math.pi / 2)  # konoha_models' details face +X; this turns them to +Z


def wall(pc, m, size, base, cell=3.5):
    km = K()
    km.box(pc, m, size, km.wall_col(base), cell=cell)


def window(frame, glass, m, w=2.8, h=2.4, shutter=None, cross=True):
    """A lean window facing +Z at m: a dark pane, a sill and a head, one lattice cross."""
    km = K()
    C = km.C
    km.box(glass, m @ T(0, 0, .02), (w, h, .12), rgb(46, 42, 40))
    km.box(frame, m @ T(0, -h / 2 - .14, .16), (w + .5, .26, .42), C["wood"])
    km.box(frame, m @ T(0, h / 2 + .12, .12), (w + .4, .24, .3), C["woodDark"])
    if cross:
        km.box(frame, m @ T(0, 0, .1), (.12, h, .1), C["woodLight"])
        km.box(frame, m @ T(0, 0, .1), (w, .12, .1), C["woodLight"])
    if shutter:
        km.box(frame, m @ T(-w / 2 - .7, 0, .1), (1.1, h + .2, .14), shutter)


def door(frame, m, w=3.4, h=5.6, col=None):
    km = K()
    C = km.C
    col = col or C["woodDark"]
    km.box(frame, m @ T(0, h / 2, .02), (w, h, .14), col)
    km.box(frame, m @ T(0, h / 2, .1), (.1, h, .08), C["woodLight"])
    km.box(frame, m @ T(0, h + .2, .12), (w + .8, .4, .34), C["wood"])
    for x in (-w / 2 - .2, w / 2 + .2):
        km.box(frame, m @ T(x, h / 2, .12), (.4, h + .4, .34), C["wood"])


def gable(tiles, wood, m, w, d, pitch=26, over=1.4, color=None, courses=3, ribs=7, thick=.7):
    """A gable roof over a w x d body whose wall top is at m's origin: the ridge along X, the
    two slopes down to +Z and -Z (the front and the back). Slabs, the tile courses as steps,
    ribs down the slope, the ridge cap, boarded gables, a fascia under each eave."""
    km = K()
    C = km.C
    color = color or C["roofTile"]
    p = math.radians(pitch)
    half = d / 2 + over
    rise = math.tan(p) * half
    slope = half / math.cos(p)
    L = w + over * 2
    dark = lerp(color, rgb(20, 22, 24), .35)
    for s in (1, -1):
        # the slab: centred on the slope's middle, turned about X
        mid = m @ T(0, rise / 2 + thick / 2, s * half / 2)
        rot = Rx(s * p)
        km.box(tiles, mid @ rot, (L, thick, slope), lambda q, f: km.jitter(color, q, .07, .6))
        for c in range(1, courses + 1):
            t = c / (courses + 1)
            pos = m @ T(0, rise * (1 - t) + thick + .05, s * half * t)
            km.box(tiles, pos @ rot, (L, .22, .5), dark)
        for r in range(ribs):
            x = -L / 2 + (r + .5) * L / ribs
            km.box(tiles, mid @ T(x, thick / 2 + .08, 0) @ rot, (.32, .16, slope), lerp(color, rgb(250, 250, 250), .08))
        km.box(wood, m @ T(0, -.1, s * (half - .1)), (L, .5, .3), C["woodDark"])  # fascia
    km.box(tiles, m @ T(0, rise + thick + .15, 0), (L + .4, .6, 1.0), dark)  # ridge cap
    for sx in (1, -1):
        km.prism(wood, [(-half + .2, 0), (half - .2, 0), (0, rise - .1)], m @ T(sx * w / 2, 0, 0) @ Ry(math.pi / 2), .3,
                 C["woodGrey"])
    return rise + thick


def hip(tiles, wood, m, w, d, pitch=28, over=1.8, color=None):
    """A hip roof (four slopes) over w x d: eaves at m's origin, the ridge along X."""
    km = K()
    C = km.C
    color = color or C["roofTile"]
    hw, hd = w / 2 + over, d / 2 + over
    rise = math.tan(math.radians(pitch)) * hd
    rl = max(.5, hw - hd)
    e = [m @ Vector(v) for v in ((-hw, 0, -hd), (hw, 0, -hd), (hw, 0, hd), (-hw, 0, hd))]
    r = [m @ Vector((-rl, rise, 0)), m @ Vector((rl, rise, 0))]
    col = lambda q: km.jitter(color, q, .07, .6)
    ix = [tiles.add(q, col(q)) for q in e + r]
    tiles.face(ix[3], ix[2], ix[5], ix[4])  # front
    tiles.face(ix[1], ix[0], ix[4], ix[5])  # back
    tiles.face(ix[2], ix[1], ix[5])
    tiles.face(ix[0], ix[3], ix[4])
    # the underside, a little lower (the slab's thickness, seen from below)
    u = [tiles.add(q - Vector((0, .6, 0)), C["woodDark"]) for q in e]
    tiles.face(u[0], u[1], u[2], u[3])
    for a, b in ((0, 1), (1, 2), (2, 3), (3, 0)):
        tiles.face(ix[a], ix[b], u[b], u[a])
    dark = lerp(color, rgb(20, 22, 24), .35)
    km.box(tiles, m @ T(0, rise + .2, 0), (rl * 2 + 1.2, .6, 1.0), dark)
    for sx in (-1, 1):  # the ridge's turned-up ends (onigawara)
        km.box(tiles, m @ T(sx * (rl + .5), rise + .7, 0), (.8, 1.2, 1.1), dark)
    # tile courses on the long slopes
    for s in (1, -1):
        for t in (.33, .66):
            y = rise * (1 - t)
            km.box(tiles, m @ T(0, y + .12, s * hd * t), (2 * (rl + (hw - rl) * t), .2, .45), dark)
    return rise


def lantern(cloth, cap, m, w=1.3, h=1.8, col=None):
    km = K()
    C = km.C
    col = col or C["lantern"]
    rings = []
    for j in range(5):
        v = j / 4
        rr = (w / 2) * (.65 + .35 * math.sin(v * math.pi))
        rings.append([m @ Vector((math.cos(a) * rr, -h / 2 + h * v, math.sin(a) * rr)) for a in
                      [i / 8 * math.tau for i in range(8)]])
    from nd_mesh import loft
    loft(cloth, rings, col)
    km.box(cap, m @ T(0, h / 2 + .06, 0), (w * .6, .16, w * .6), C["black"])


def sign(wood, paint, m, w, h, col, strokes=3, seed=0):
    """A sign board facing +Z: a frame, a coloured face, plain brush strokes (no real word)."""
    km = K()
    C = km.C
    rng = random.Random(seed)
    km.box(wood, m, (w + .3, h + .3, .2), C["woodDark"])
    km.box(paint, m @ T(0, 0, .12), (w, h, .06), col)
    for k in range(strokes):
        y = h / 2 - (k + .7) * h / (strokes + .5)
        km.box(paint, m @ T(rng.uniform(-.15, .15), y, .17), (w * rng.uniform(.35, .6), .22, .04), C["black"])


def tank(wood, iron, m, r=2.4, h=3.6, staves=10):
    """The round wooden water tank of Konoha's roofs: legs, staves, hoops, a conical lid."""
    km = K()
    C = km.C
    from nd_mesh import loft
    for x in (-1, 1):
        for z in (-1, 1):
            km.box(wood, m @ T(x * r * .6, .6, z * r * .6), (.45, 1.2, .45), C["woodDark"])
    ring = lambda y, rr, n: [m @ Vector((math.cos(a) * rr, y, math.sin(a) * rr)) for a in [i / n * math.tau for i in range(n)]]
    loft(wood, [ring(1.2, r, staves), ring(1.2 + h, r, staves)], lambda q, k: km.jitter(C["woodLight"], q, .12, 1.4))
    for y in (1.8, 1.2 + h - .5):
        loft(iron, [ring(y, r + .08, staves), ring(y + .22, r + .08, staves)], C["iron"], cap0=False, cap1=False)
    loft(wood, [ring(1.2 + h, r + .25, staves), ring(1.2 + h + .3, r + .25, staves)], C["woodDark"], cap0=True, cap1=False,
         tip1=m @ Vector((0, 1.2 + h + 1.2, 0)))


def pipe(iron, m, h):
    km = K()
    km.cyl(iron, m, .18, h, km.C["iron"], sides=6, cap=False)


# ------------------------------------------------------------------------------------------------
def pieces(name):
    walls = Piece("Walls", "Concrete", flat=True)
    timber = Piece("Timber", "Wood", flat=True)
    glass = Piece("Openings", "SmoothPlastic", flat=True)
    tiles = Piece("Tiles", "Slate", flat=True)
    cloth = Piece("Cloth", "Fabric", flat=True)
    metal = Piece("Metal", "Metal", flat=True)
    return walls, timber, glass, tiles, cloth, metal


def done(*ps):
    return [p for p in ps if p.v]


def small_house():
    km = K()
    C = km.C
    w, d, h, _ = REF["small_house"]
    walls, timber, glass, tiles, cloth, metal = pieces("small")
    wall(walls, T(0, h / 2, 0), (w, h, d), C["plasterWarm"])
    km.box(timber, T(0, .5, 0), (w + .3, 1, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for sx in (-1, 1):
        for sz in (-1, 1):
            km.box(timber, T(sx * w / 2, h / 2, sz * d / 2), (.8, h, .8), C["wood"])
    door(timber, T(-2.6, 0, d / 2 + .05))
    window(timber, glass, T(3.2, 4.2, d / 2 + .05), shutter=C["roofBlue"])
    for z in (-3, 3):
        window(timber, glass, T(w / 2 + .05, 4.2, z) @ Ry(math.pi / 2), 2.4, 2.2)
        window(timber, glass, T(-w / 2 - .05, 4.2, z) @ Ry(-math.pi / 2), 2.4, 2.2)
    window(timber, glass, T(0, 4.2, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.2)
    # the little porch roof over the door, on two brackets
    km.box(tiles, T(-2.6, 6.6, d / 2 + 1.0) @ Rx(math.radians(18)), (5.2, .3, 2.4), C["roofTerra"])
    for x in (-4.6, -.6):
        km.box(timber, T(x, 6.1, d / 2 + .6), (.3, .3, 1.4), C["woodDark"])
    gable(tiles, timber, T(0, h, 0), w, d, 26, 1.2, C["roofTerra"], courses=2, ribs=6)
    lantern(cloth, metal, T(-.2, 4.8, d / 2 + .6))
    km.box(timber, T(3.2, 2.6, d / 2 + .6), (3.4, .8, .8), C["woodDark"])  # flower box
    km.box(cloth, T(3.2, 3.1, d / 2 + .6), (3.0, .5, .6), C["leaf"])
    pipe(metal, T(w / 2 + .35, 0, -d / 2 + 1.2), h + 1)
    return done(walls, timber, glass, tiles, cloth, metal)


def machiya():
    km = K()
    C = km.C
    w, d, h, _ = REF["machiya"]
    walls, timber, glass, tiles, cloth, metal = pieces("machiya")
    wall(walls, T(0, h / 2, 0), (w, h, d), C["plaster"])
    km.box(timber, T(0, .45, 0), (w + .3, .9, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    # the timber frame: corner posts, the floor band, the ground floor's lattice front (koshi)
    for sx in (-1, 1):
        for sz in (-1, 1):
            km.box(timber, T(sx * w / 2, h / 2, sz * d / 2), (.9, h, .9), C["woodDark"])
    km.box(timber, T(0, FLOOR, 0), (w + .4, .6, d + .4), C["wood"])
    km.box(timber, T(0, h - .2, 0), (w + .3, .4, d + .3), C["woodDark"])
    km.box(glass, T(1.8, 3.2, d / 2 + .03), (9.6, 4.6, .1), rgb(40, 34, 30))
    for k in range(10):
        km.box(timber, T(-2.6 + k * 1.0, 3.2, d / 2 + .18), (.24, 4.6, .24), C["woodLight"])
    km.box(timber, T(1.8, 5.6, d / 2 + .2), (10, .3, .3), C["woodDark"])
    km.box(timber, T(1.8, .95, d / 2 + .2), (10, .3, .3), C["woodDark"])
    door(timber, T(-5.6, 0, d / 2 + .05), 3.2, 5.8)
    # the lean-to roof over the ground floor (hisashi), its rafters
    km.box(tiles, T(0, FLOOR - .2, d / 2 + 1.4) @ Rx(math.radians(22)), (w + 1.2, .4, 3.2), C["roofTile"])
    for k in range(6):
        km.box(timber, T(-w / 2 + 1 + k * (w - 2) / 5, FLOOR - .9, d / 2 + .9), (.25, .3, 1.8), C["woodDark"])
    # the upper floor: two lattice windows to the street (mushiko), one on each side, two back
    for x in (-4.2, 4.2):
        window(timber, glass, T(x, FLOOR + 3.4, d / 2 + .05), 3.6, 2.2)
        window(timber, glass, T(x, FLOOR + 3.4, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.2)
    for z in (-3.5, 3.5):
        window(timber, glass, T(w / 2 + .05, 3.6, z) @ Ry(math.pi / 2), 2.6, 2.2)
        window(timber, glass, T(-w / 2 - .05, FLOOR + 3.4, z) @ Ry(-math.pi / 2), 2.6, 2.2)
    # a small balcony rail under the upper windows
    km.box(timber, T(0, FLOOR + 1.6, d / 2 + .7), (w - 3, .25, .25), C["wood"])
    for k in range(5):
        km.box(timber, T(-w / 2 + 1.5 + k * (w - 3) / 4, FLOOR + 1.0, d / 2 + .7), (.2, 1.2, .2), C["wood"])
    gable(tiles, timber, T(0, h, 0), w, d, 26, 1.5, C["roofTile"], courses=3, ribs=8)
    lantern(cloth, metal, T(-3.4, 5.2, d / 2 + .7))
    km.box(cloth, T(-5.6, 6.6, d / 2 + .3), (3.6, 1.6, .08), C["roofBlue"])  # a short noren
    pipe(metal, T(-w / 2 - .3, 0, -d / 2 + 1), h + 2)
    return done(walls, timber, glass, tiles, cloth, metal)


def tank_house():
    km = K()
    C = km.C
    w, d, h, _ = REF["tank_house"]
    walls, timber, glass, tiles, cloth, metal = pieces("tank")
    body = rgb(206, 170, 120)  # warm ochre plaster, the anime's colourful blocks
    wall(walls, T(0, h / 2, 0), (w, h, d), body)
    km.box(timber, T(0, .5, 0), (w + .3, 1, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for f in (1, 2):
        km.box(walls, T(0, f * FLOOR, 0), (w + .5, .5, d + .5), lerp(body, rgb(255, 250, 240), .35))
    # parapet and the flat roof
    km.box(tiles, T(0, h + .25, 0), (w + .4, .5, d + .4), C["roofDark"])
    for sx, sz, lx, lz in ((0, 1, w + .8, .5), (0, -1, w + .8, .5), (1, 0, .5, d + .8), (-1, 0, .5, d + .8)):
        km.box(walls, T(sx * (w + .3) / 2, h + .9, sz * (d + .3) / 2), (lx, 1.3, lz), lerp(body, rgb(255, 250, 240), .35))
    door(timber, T(-4.6, 0, d / 2 + .05), 3.2, 5.4, C["roofBlue"])
    for f in range(3):
        y = f * FLOOR + 4.0
        xs = (1.0, 5.4) if f == 0 else (-4.6, 1.0, 5.4)
        for x in xs:
            window(timber, glass, T(x, y, d / 2 + .05), 2.6, 2.2)
        for z in (-3.6, 3.6):
            window(timber, glass, T(w / 2 + .05, y, z) @ Ry(math.pi / 2), 2.4, 2.2)
        window(timber, glass, T(0, y, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.2)
    # the canopy over the door, the vertical sign, pipes, an outdoor unit
    km.box(tiles, T(-4.6, 6.4, d / 2 + .9), (4.6, .25, 1.8), C["roofBlue"])
    sign(timber, cloth, T(w / 2 - 1.2, 11, d / 2 + .5) @ Ry(math.pi / 2), 1.4, 5.0, C["red"], 3, 7)
    pipe(metal, T(-w / 2 - .3, 0, d / 2 - 1), h + 1)
    pipe(metal, T(w / 2 + .3, 0, -d / 2 + 1), h + 1)
    km.box(metal, T(-w / 2 - .5, 9.2, -2), (1.0, 1.6, 2.4), C["stone"])
    # THE tank, and a hatch
    tank(timber, metal, T(3, h + .5, -1.5))
    km.box(timber, T(-4.5, h + .7, 2), (2.2, .5, 2.2), C["woodGrey"])
    return done(walls, timber, glass, tiles, cloth, metal)


def shop_house():
    km = K()
    C = km.C
    w, d, h, _ = REF["shop_house"]
    walls, timber, glass, tiles, cloth, metal = pieces("shop")
    body = C["plasterWarm"]
    wall(walls, T(0, h / 2, 0), (w, h, d), body)
    km.box(timber, T(0, .45, 0), (w + .3, .9, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for sx in (-1, 1):
        for sz in (-1, 1):
            km.box(timber, T(sx * w / 2, h / 2, sz * d / 2), (.9, h, .9), C["wood"])
    km.box(timber, T(0, FLOOR, 0), (w + .4, .6, d + .4), C["woodDark"])
    # the open shop front: a dark interior, the counter, shelves with goods, the noren
    km.box(glass, T(0, 3.1, d / 2 + .03), (w - 3, 4.6, .1), rgb(54, 40, 32))
    km.box(timber, T(0, 1.4, d / 2 + .9), (w - 4, 1.6, 1.6), C["wood"])
    km.box(timber, T(0, 2.3, d / 2 + .9), (w - 3.6, .2, 1.9), C["woodLight"])
    rng = random.Random(3)
    goods = (C["red"], C["green"], C["paper"], C["roofBlue"], C["lantern"])
    for k in range(8):
        km.box(cloth, T(-w / 2 + 3 + k * (w - 6) / 7, 2.75, d / 2 + .9), (1.1, .7, 1.0), goods[k % 5])
    km.box(timber, T(0, 4.2, d / 2 + .25), (w - 3, .2, .5), C["woodDark"])
    for k in range(5):
        km.box(cloth, T(-6 + k * 3, 5.0, d / 2 + .5), (2.8, 1.8, .06), lerp(C["roofBlue"], rgb(30, 30, 50), .15 * (k % 2)))
    # the awning, slanted, on posts
    km.box(tiles, T(0, 6.3, d / 2 + 2.0) @ Rx(math.radians(16)), (w + .6, .3, 4.0), C["red"])
    for x in (-w / 2 + .6, w / 2 - .6):
        km.box(timber, T(x, 3.0, d / 2 + 3.6), (.4, 6.0, .4), C["woodDark"])
    # upper floor
    for x in (-5, 0, 5):
        window(timber, glass, T(x, FLOOR + 3.4, d / 2 + .05), 2.8, 2.2, shutter=C["green"] if x == 0 else None)
    for z in (-3.5, 3.5):
        window(timber, glass, T(w / 2 + .05, FLOOR + 3.4, z) @ Ry(math.pi / 2), 2.6, 2.2)
        window(timber, glass, T(-w / 2 - .05, FLOOR + 3.4, z) @ Ry(-math.pi / 2), 2.6, 2.2)
    window(timber, glass, T(-4, FLOOR + 3.4, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.2)
    window(timber, glass, T(4, 3.6, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.2)
    sign(timber, cloth, T(0, h - 1.6, d / 2 + .5), 7.0, 1.6, C["paper"], 2, 11)
    gable(tiles, timber, T(0, h, 0), w, d, 24, 1.4, C["roofBlue"], courses=3, ribs=9)
    lantern(cloth, metal, T(-w / 2 + .3, 6.0, d / 2 + 3.6))
    lantern(cloth, metal, T(w / 2 - .3, 6.0, d / 2 + 3.6))
    return done(walls, timber, glass, tiles, cloth, metal)


def apartment():
    km = K()
    C = km.C
    w, d, h, _ = REF["apartment"]
    walls, timber, glass, tiles, cloth, metal = pieces("apartment")
    body = rgb(178, 190, 186)  # pale celadon plaster
    trim = lerp(body, rgb(255, 255, 250), .4)
    wall(walls, T(0, h / 2, -.8), (w, h, d - 1.6), body)
    km.box(timber, T(0, .5, 0), (w + .3, 1, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    # three floors of units opening on a walkway along the front: slab, rail, posts
    for f in range(3):
        y = f * FLOOR
        for u, x in enumerate((-8, 0, 8)):
            door(timber, T(x - 1.8, y + .3, d / 2 - 1.55), 2.6, 5.0, (C["roofBlue"], C["redDark"], C["wood"])[(u + f) % 3])
            window(timber, glass, T(x + 1.9, y + 4.0, d / 2 - 1.55), 2.6, 2.0, cross=False)
        if f > 0:
            km.box(walls, T(0, y, d / 2 - .8), (w + .6, .45, 1.8), trim)
            km.box(timber, T(0, y + 2.2, d / 2 + .05), (w + .4, .25, .25), C["iron"])
            for k in range(5):
                km.box(metal, T(-w / 2 + .5 + k * (w - 1) / 4, y + 1.1, d / 2 + .05), (.16, 2.2, .16), C["iron"])
        window(timber, glass, T(w / 2 + .05, y + 4.0, -2) @ Ry(math.pi / 2), 2.4, 2.0, cross=False)
        for x in (-6, 6):
            window(timber, glass, T(x, y + 4.0, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.0, cross=False)
    # the outside stair up the west side, the roof, two tanks, laundry poles
    for k in range(8):
        km.box(timber, T(-w / 2 - 1.4, .9 + k * 1.75, -d / 2 + 2 + k * 1.5), (2.4, .3, 1.5), C["iron"])
    km.box(metal, T(-w / 2 - 2.5, 7.5, 0), (.2, 1.0, d - 2), C["iron"])
    km.box(tiles, T(0, h + .25, 0), (w + .5, .5, d + .5), C["roofDark"])
    for sx, sz, lx, lz in ((0, 1, w + .8, .4), (0, -1, w + .8, .4), (1, 0, .4, d + .8), (-1, 0, .4, d + .8)):
        km.box(walls, T(sx * (w + .4) / 2, h + .85, sz * (d + .4) / 2), (lx, 1.2, lz), trim)
    tank(timber, metal, T(-6, h + .5, -2), 2.2, 3.2)
    tank(timber, metal, T(6, h + .5, -2), 2.0, 2.8)
    km.box(metal, T(0, h + 2.3, 3.5), (w - 6, .12, .12), C["iron"])
    for x in (-3, 0, 3):
        km.box(cloth, T(x, h + 1.6, 3.5), (2.0, 1.4, .05), (C["paper"], C["roofBlue"], C["cloth"])[x // 3 + 1])
    for x in (-w / 2 + 3, w / 2 - 3):
        km.box(metal, T(x, h + 1.4, 3.5), (.15, 2.0, .15), C["iron"])
    return done(walls, timber, glass, tiles, cloth, metal)


def clan_house():
    km = K()
    C = km.C
    w, d, h, _ = REF["clan_house"]
    walls, timber, glass, tiles, cloth, metal = pieces("clan")
    base = 1.5
    # the stone base, the hall's walls set back behind the engawa
    km.box(walls, T(0, base / 2, 0), (w + 1, base, d + 1), lambda q, f: km.jitter(C["stone"], q, .08, .8), cell=3.0)
    km.box(walls, T(0, base + (h - base) / 2, -1.2), (w - 2, h - base, d - 4.4), lambda q, f: km.jitter(C["cloth"], q, .03, .4))
    # the timber frame over the plaster: posts, a band under the eaves
    zf = d / 2 - 3.4 + .05
    for k in range(7):
        x = -(w - 2) / 2 + k * (w - 2) / 6
        km.box(timber, T(x, base + (h - base) / 2, zf), (.6, h - base, .6), C["woodDark"])
        km.box(timber, T(x, base + (h - base) / 2, -d / 2 + 1.0), (.5, h - base, .5), C["woodDark"])
    km.box(timber, T(0, h - .3, -1.2), (w - 1.6, .6, d - 4.0), C["woodDark"])
    # shoji panels between the front posts (paper and a light lattice)
    for k in range(6):
        x = -(w - 2) / 2 + (k + .5) * (w - 2) / 6
        km.box(glass, T(x, base + 2.8, zf + .02), ((w - 2) / 6 - .7, 5.0, .08), C["paper"])
        km.box(timber, T(x, base + 2.8, zf + .08), (.1, 5.0, .06), C["woodLight"])
        km.box(timber, T(x, base + 2.0, zf + .08), ((w - 2) / 6 - .7, .1, .06), C["woodLight"])
        km.box(timber, T(x, base + 3.8, zf + .08), ((w - 2) / 6 - .7, .1, .06), C["woodLight"])
    # the engawa: a deck along the front on short posts, a step
    km.box(timber, T(0, base + .2, d / 2 - 1.6), (w - 1, .35, 3.4), C["woodLight"])
    for x in (-w / 2 + 1, -w / 6, w / 6, w / 2 - 1):
        km.box(timber, T(x, base + (h - base) / 2, d / 2 - .2), (.5, h - base, .5), C["wood"])
    km.box(walls, T(0, .45, d / 2 + 1.0), (6, .9, 1.4), C["stoneDark"])
    # side windows (round-topped would cost more: square, barred)
    for sx in (-1, 1):
        window(timber, glass, T(sx * ((w - 2) / 2 + .05), base + 3.4, -1.2) @ Ry(sx * math.pi / 2), 3.2, 2.0)
    km.box(timber, T(0, h + .1, 0), (w + .6, .3, d + .6), C["woodDark"])
    hip(tiles, timber, T(0, h + .25, 0), w, d, 28, 1.6, C["roofDark"])
    for x in (-w / 2 + 1, w / 2 - 1):
        lantern(cloth, metal, T(x, h - 1.4, d / 2 + .2), 1.2, 1.6, C["paper"])
    return done(walls, timber, glass, tiles, cloth, metal)


def tower_house():
    """(22/11, François: « l'arrangement de l'espace et la différence entre les bâtiments n'est
    pas assez forte ») The tall narrow blocks that break Konoha's skyline in Part I's wide
    shots: four floors on a small lot, a floor band at each storey, a balcony on the third,
    a tall vertical sign, a stepped roof with its water tank high over the street."""
    km = K()
    C = km.C
    w, d, h, _ = REF["tower_house"]
    walls, timber, glass, tiles, cloth, metal = pieces("tower")
    body = rgb(214, 186, 170)  # a pale rose plaster (each house's own tint is added on the client)
    trim = lerp(body, rgb(255, 250, 244), .4)
    wall(walls, T(0, h / 2, 0), (w, h, d), body)
    km.box(timber, T(0, .5, 0), (w + .3, 1, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for f in (1, 2, 3):
        km.box(walls, T(0, f * FLOOR, 0), (w + .6, .5, d + .6), trim)
    door(timber, T(-2.6, 0, d / 2 + .05), 3.0, 5.2, C["redDark"])
    km.box(tiles, T(-2.6, 6.2, d / 2 + .9), (4.2, .25, 1.8), C["roofTerra"])
    for f in range(4):
        y = f * FLOOR + 4.0
        for x in ((2.6,) if f == 0 else (-2.8, 2.8)):
            window(timber, glass, T(x, y, d / 2 + .05), 2.4, 2.2, shutter=C["roofGreen"] if f % 2 else None)
        for sx in (-1, 1):
            window(timber, glass, T(sx * (w / 2 + .05), y, 0) @ Ry(sx * math.pi / 2), 2.4, 2.2)
        window(timber, glass, T(0, y, -d / 2 - .05) @ Ry(math.pi), 2.6, 2.2)
    # the third floor's balcony: a slab, a rail, a pot of plants, laundry on the rail
    y = 2 * FLOOR
    km.box(walls, T(0, y + .2, d / 2 + 1.0), (w - 2, .4, 2.0), trim)
    km.box(timber, T(0, y + 1.5, d / 2 + 1.95), (w - 2, .2, .2), C["iron"])
    for x in (-w / 2 + 1.2, 0, w / 2 - 1.2):
        km.box(metal, T(x, y + .85, d / 2 + 1.95), (.14, 1.3, .14), C["iron"])
    km.box(cloth, T(-2.0, y + 1.0, d / 2 + 2.0), (1.6, 1.1, .05), C["cloth"])
    km.box(cloth, T(.2, y + 1.05, d / 2 + 2.0), (1.2, 1.0, .05), C["roofBlue"])
    km.box(timber, T(3.4, y + .75, d / 2 + 1.2), (1.0, .7, 1.0), C["redDark"])
    km.box(cloth, T(3.4, y + 1.4, d / 2 + 1.2), (1.2, .8, 1.2), C["leaf"])
    # the tall sign down the corner, pipes
    sign(timber, cloth, T(w / 2 + .5, 15, d / 2 - 1.6) @ Ry(math.pi / 2), 1.5, 7.5, C["red"], 4, 11)
    pipe(metal, T(-w / 2 - .3, 0, d / 2 - 1), h + 1)
    # a stepped roof: the parapet, a smaller block (the stair's head), the tank on it
    km.box(tiles, T(0, h + .25, 0), (w + .4, .5, d + .4), C["roofDark"])
    for sx, sz, lx, lz in ((0, 1, w + .8, .4), (0, -1, w + .8, .4), (1, 0, .4, d + .8), (-1, 0, .4, d + .8)):
        km.box(walls, T(sx * (w + .3) / 2, h + .85, sz * (d + .3) / 2), (lx, 1.2, lz), trim)
    km.box(walls, T(-2.2, h + 1.8, -2.2), (5.5, 3.6, 5.5), trim)
    km.box(tiles, T(-2.2, h + 3.75, -2.2), (6.1, .3, 6.1), C["roofTerra"])
    tank(timber, metal, T(-2.2, h + 3.9, -2.2), 1.8, 2.6)
    return done(walls, timber, glass, tiles, cloth, metal)


# ================================================================================================
# (23/11, passe commune 1) The Edo houses of the new town: Tsumago-juku and Ouchi-juku's post-town
# fronts, Kyoto's machiya, the white storehouses, Shirakawa-go's steep thatch. Dark timber, white
# or earth plaster, deep tiled eaves on every floor, lattices, noren, engawa. No water tank.
WOOD_EDO = rgb(74, 52, 36)


def eave(tiles, timber, m, w, depth, pitch=20, color=None, brackets=4):
    """A lean-to eave (hisashi) along a front facing +Z: m at the wall, its top edge; slopes out
    and down `depth`, with brackets under it."""
    km = K()
    C = km.C
    color = color or C["roofTile"]
    p = math.radians(pitch)
    drop = math.tan(p) * depth
    km.box(tiles, m @ T(0, -drop / 2, depth / 2) @ Rx(p), (w, .35, depth / math.cos(p) + .2), lambda q, f: km.jitter(color, q, .07, .6))
    dark = lerp(color, rgb(20, 22, 24), .35)
    for k in range(1, 3):
        km.box(tiles, m @ T(0, -drop * k / 3 + .2, depth * k / 3) @ Rx(p), (w, .16, .35), dark)
    for k in range(brackets):
        x = -w / 2 + .6 + k * (w - 1.2) / max(1, brackets - 1)
        km.box(timber, m @ T(x, -drop - .2, depth * .5), (.25, .3, depth), C["woodDark"])
    return drop


def lattice(timber, glass, m, w, h, bars=None, col=None):
    """A koshi lattice front facing +Z at m (its centre): a dark back, close vertical bars."""
    km = K()
    km.box(glass, m, (w, h, .1), rgb(38, 30, 26))
    n = bars or int(w / .55)
    for k in range(n):
        km.box(timber, m @ T(-w / 2 + (k + .5) * w / n, 0, .14), (.16, h, .16), col or km.C["woodLight"])
    for y in (-h / 2, h / 2):
        km.box(timber, m @ T(0, y, .16), (w + .2, .22, .22), WOOD_EDO)


def noren_front(cloth, timber, m, w=3.6, h=2.0, col=None, n=3):
    """A split curtain over a door facing +Z: m at its top centre."""
    km = K()
    col = col or km.C["roofBlue"]
    km.box(timber, m @ T(0, .1, .1), (w + .4, .14, .14), km.C["woodDark"])
    for k in range(n):
        x = -w / 2 + (k + .5) * w / n
        km.box(cloth, m @ T(x, -h / 2, .14), (w / n - .1, h, .05), lerp(col, rgb(20, 20, 30), .12 * (k % 2)))


def edo_townhouse():
    """Two floors on a narrow deep lot: the ground floor's lattice front and noren, a deep eave,
    the low upper floor's white plaster with its slatted mushiko window, the main tiled gable."""
    km = K()
    C = km.C
    w, d, h, _ = REF["edo_townhouse"]
    walls, timber, glass, tiles, cloth, metal = pieces("edo_townhouse")
    upper = rgb(226, 220, 204)
    wall(walls, T(0, FLOOR / 2, 0), (w, FLOOR, d), rgb(150, 112, 80))
    wall(walls, T(0, FLOOR + (h - FLOOR) / 2, -.6), (w, h - FLOOR, d - 1.2), upper)
    km.box(timber, T(0, .4, 0), (w + .3, .8, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for sx in (-1, 1):
        for sz in (-1, 1):
            km.box(timber, T(sx * w / 2, FLOOR / 2, sz * d / 2), (.8, FLOOR, .8), WOOD_EDO)
    km.box(timber, T(0, FLOOR - .2, d / 2 + .1), (w + .3, .6, .6), WOOD_EDO)
    lattice(timber, glass, T(2.4, 3.1, d / 2 + .05), 10.5, 4.6)
    door(timber, T(-5.8, 0, d / 2 + .05), 3.2, 5.6, WOOD_EDO)
    noren_front(cloth, timber, T(-5.8, 5.4, d / 2 + .2), 3.4, 2.0, C["roofBlue"])
    eave(tiles, timber, T(0, FLOOR + .3, d / 2), w + 1.0, 2.6, 22, C["roofTile"], 5)
    # the upper floor: the slatted mushiko window, plaster, two small side windows
    km.box(glass, T(0, FLOOR + 2.6, d / 2 - 1.15), (9, 2.2, .1), rgb(40, 32, 26))
    for k in range(16):
        km.box(timber, T(-4.4 + k * .59, FLOOR + 2.6, d / 2 - 1.05), (.22, 2.2, .16), WOOD_EDO)
    for sz in (-3, 3):
        window(timber, glass, T(w / 2 + .05, FLOOR + 2.6, sz) @ Ry(math.pi / 2), 2.0, 1.6)
    gable(tiles, timber, T(0, h, 0), w, d, 24, 1.8, C["roofTile"], courses=3, ribs=9)
    lantern(cloth, metal, T(w / 2 - 1.2, 4.6, d / 2 + .9), 1.0, 1.5, C["paper"])
    sign(timber, cloth, T(-1, FLOOR + .9 + 2.6, d / 2 + 2.4), 4.0, 1.0, C["woodLight"], 2, 21)
    return done(walls, timber, glass, tiles, cloth, metal)


def edo_inn():
    """The post town's inn: a wide front, sliding doors at the street, an engawa at the side,
    the upper floor's open balcony with its railing all along, a hip roof with deep eaves."""
    km = K()
    C = km.C
    w, d, h, _ = REF["edo_inn"]
    walls, timber, glass, tiles, cloth, metal = pieces("edo_inn")
    plaster = rgb(214, 204, 184)
    wall(walls, T(0, FLOOR / 2, 0), (w, FLOOR, d), plaster)
    wall(walls, T(0, FLOOR + (h - FLOOR) / 2, -1.2), (w, h - FLOOR, d - 2.4), plaster)
    km.box(timber, T(0, .4, 0), (w + .3, .8, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for k in range(7):
        x = -w / 2 + k * w / 6
        km.box(timber, T(x, h / 2, d / 2), (.7, h, .7), WOOD_EDO)
    km.box(timber, T(0, FLOOR, 0), (w + .4, .6, d + .4), WOOD_EDO)
    # the ground floor: shoji doors between the posts, the noren at the middle
    for k in range(6):
        x = -w / 2 + (k + .5) * w / 6
        km.box(glass, T(x, 3.0, d / 2 + .03), (w / 6 - .9, 5.0, .08), C["paper"])
        km.box(timber, T(x, 3.0, d / 2 + .1), (.1, 5.0, .06), C["woodLight"])
        km.box(timber, T(x, 2.0, d / 2 + .1), (w / 6 - .9, .1, .06), C["woodLight"])
    noren_front(cloth, timber, T(0, 5.6, d / 2 + .2), 4.4, 1.8, C["red"], 4)
    eave(tiles, timber, T(0, FLOOR - .3, d / 2), w + 1.2, 2.4, 20, C["roofDark"], 6)
    # the balcony: a deck in front of the set-back upper floor, a railing, its shoji behind
    km.box(timber, T(0, FLOOR + .45, d / 2 - 1.2), (w + .2, .3, 2.4), C["woodLight"])
    km.box(timber, T(0, FLOOR + 1.7, d / 2 - .1), (w + .2, .22, .22), WOOD_EDO)
    km.box(timber, T(0, FLOOR + 1.0, d / 2 - .1), (w + .2, .12, .12), WOOD_EDO)
    for k in range(13):
        km.box(timber, T(-w / 2 + k * w / 12, FLOOR + 1.0, d / 2 - .1), (.16, 1.4, .16), WOOD_EDO)
    for k in range(6):
        x = -w / 2 + (k + .5) * w / 6
        km.box(glass, T(x, FLOOR + 2.8, d / 2 - 2.35), (w / 6 - .8, 3.8, .08), C["paper"])
    km.box(cloth, T(-4, FLOOR + 2.0, d / 2 - .05), (2.4, 1.2, .05), C["cloth"])  # a futon airing on the rail
    hip(tiles, timber, T(0, h + .2, -.4), w, d - .8, 26, 2.0, C["roofTile"])
    lantern(cloth, metal, T(-w / 2 + 1.5, 5.2, d / 2 + 1.0), 1.2, 1.7, C["paper"])
    lantern(cloth, metal, T(w / 2 - 1.5, 5.2, d / 2 + 1.0), 1.2, 1.7, C["paper"])
    sign(timber, cloth, T(0, h - 1.2, d / 2 - 2.2), 6.0, 1.2, C["woodLight"], 3, 31)
    return done(walls, timber, glass, tiles, cloth, metal)


def kura():
    """The white storehouse: thick plaster walls, the black and white tiled base (namako), one
    small iron-shuttered window high up, a heavy tiled gable with a deep ridge."""
    km = K()
    C = km.C
    w, d, h, _ = REF["kura"]
    walls, timber, glass, tiles, cloth, metal = pieces("kura")
    white = rgb(236, 232, 222)
    wall(walls, T(0, h / 2, 0), (w, h, d), white)
    # namako: dark tiles with a light diamond grid on the lower walls
    km.box(tiles, T(0, 1.6, 0), (w + .2, 3.2, d + .2), rgb(48, 50, 54))
    for sz, rot in ((d / 2 + .12, 0), (-d / 2 - .12, math.pi)):
        for k in range(-5, 6):
            km.box(walls, T(k * 1.1, 1.6, sz) @ Ry(rot) @ Rz_(math.radians(45)), (.12, 4.2, .05), rgb(214, 214, 208))
            km.box(walls, T(k * 1.1, 1.6, sz) @ Ry(rot) @ Rz_(math.radians(-45)), (.12, 4.2, .05), rgb(214, 214, 208))
    km.box(timber, T(0, h - .3, 0), (w + .4, .6, d + .4), white)
    km.box(metal, T(0, h - 2.6, d / 2 + .1), (2.0, 1.8, .2), C["iron"])
    km.box(timber, T(0, 2.9, d / 2 + .1), (3.0, 5.4, .25), WOOD_EDO)    # the heavy door
    km.box(metal, T(0, 2.9, d / 2 + .25), (.2, 5.4, .06), C["iron"])
    eave(tiles, timber, T(0, 6.2, d / 2), 4.4, 1.4, 22, C["roofTile"], 2)
    gable(tiles, timber, T(0, h, 0), w, d, 30, 1.2, rgb(52, 56, 60), courses=3, ribs=6, thick=.9)
    km.box(tiles, T(0, h + math.tan(math.radians(30)) * (d / 2 + 1.2) + 1.5, 0), (w + 3.0, .9, 1.4), rgb(36, 38, 42))
    return done(walls, timber, glass, tiles, cloth, metal)


def Rz_(a):
    return Matrix.Rotation(a, 4, "Z")


def tea_shop():
    """The tea stand on the street: one floor, the front open on a counter, a red bench and a
    parasol outside, a cloth awning on poles, noren and a lantern."""
    km = K()
    C = km.C
    w, d, h, _ = REF["tea_shop"]
    walls, timber, glass, tiles, cloth, metal = pieces("tea_shop")
    wall(walls, T(0, h / 2, -1.0), (w, h, d - 2.0), rgb(178, 140, 100))
    km.box(timber, T(0, .35, 0), (w + .3, .7, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for x in (-w / 2, -w / 6, w / 6, w / 2):
        km.box(timber, T(x, h / 2, d / 2 - 2.0), (.6, h, .6), WOOD_EDO)
    km.box(glass, T(0, 3.0, d / 2 - 1.95), (w - 1.2, 4.6, .08), rgb(48, 36, 28))
    km.box(timber, T(0, 1.3, d / 2 - 1.0), (w - 3, 1.4, 1.4), C["wood"])        # the counter
    km.box(timber, T(0, 2.05, d / 2 - 1.0), (w - 2.6, .18, 1.7), C["woodLight"])
    for k in range(6):
        km.box(cloth, T(-w / 2 + 2.6 + k * (w - 5.2) / 5, 2.45, d / 2 - 1.0), (.8, .6, .8), (C["paper"], C["green"], C["red"])[k % 3])
    noren_front(cloth, timber, T(0, 5.8, d / 2 - 1.8), w - 2, 1.4, rgb(70, 92, 64), 5)
    # the awning: cloth over the street on two poles
    km.box(cloth, T(0, 5.4, d / 2 + .6) @ Rx(math.radians(14)), (w + .6, .2, 4.4), C["red"])
    for x in (-w / 2 + .5, w / 2 - .5):
        km.box(timber, T(x, 2.7, d / 2 + 2.6), (.3, 5.4, .3), WOOD_EDO)
    # the bench with its red cloth, the parasol
    km.box(timber, T(-3.5, .9, d / 2 + 1.4), (5.0, .3, 1.6), C["wood"])
    km.box(cloth, T(-3.5, 1.1, d / 2 + 1.4), (4.6, .1, 1.4), C["lantern"])
    for x in (-5.7, -1.3):
        km.box(timber, T(x, .45, d / 2 + 1.4), (.3, .9, 1.2), WOOD_EDO)
    km.box(timber, T(3.6, 3.0, d / 2 + 1.6), (.16, 6.0, .16), C["woodDark"])
    from nd_mesh import loft
    ring = lambda y, r: [Vector((3.6 + math.cos(a) * r, y, d / 2 + 1.6 + math.sin(a) * r)) for a in [i / 12 * math.tau for i in range(12)]]
    loft(cloth, [ring(5.4, 3.2), ring(6.4, .2)], C["lantern"], cap0=True, cap1=True)
    gable(tiles, timber, T(0, h, -1.0), w, d - 2.0, 24, 1.4, C["roofTile"], courses=2, ribs=8)
    lantern(cloth, metal, T(w / 2 - 1.0, 4.4, d / 2 + .4), 1.1, 1.5, C["lantern"])
    return done(walls, timber, glass, tiles, cloth, metal)


def farmhouse():
    """Shirakawa-go's gasshō: low walls under a steep thatched gable that comes down almost to the
    ground, the gable end open with small windows in the attic floors."""
    km = K()
    C = km.C
    w, d, h, _ = REF["farmhouse"]
    walls, timber, glass, tiles, cloth, metal = pieces("farmhouse")
    thatch = rgb(150, 124, 82)
    wall(walls, T(0, h / 2, 0), (w, h, d), rgb(118, 92, 66))
    km.box(timber, T(0, .35, 0), (w + .3, .7, d + .3), lambda q, f: km.grime(C["stoneDark"], q, 0, 1, .3))
    for k in range(5):
        x = -w / 2 + k * w / 4
        km.box(timber, T(x, h / 2, d / 2 + .05), (.6, h, .6), WOOD_EDO)
    for k in range(4):
        x = -w / 2 + (k + .5) * w / 4
        km.box(glass, T(x, 2.4, d / 2 + .05), (w / 4 - 1.2, 3.6, .08), C["paper"])
    # the steep thatch: ridge along Z (the gable ends face the street, +Z and -Z)
    p = math.radians(58)
    half = w / 2 + 1.6
    rise = math.tan(p) * half
    slope = half / math.cos(p)
    L = d + 3.0
    for s in (1, -1):
        km.box(tiles, T(s * half / 2, h + rise / 2 + .6, 0) @ Rz_(-s * p), (slope + .2, 1.4, L), lambda q, f: km.jitter(thatch, q, .14, 1.2))
    km.box(tiles, T(0, h + rise + .9, 0), (1.6, 1.0, L + .4), rgb(96, 80, 58))
    for k in range(5):   # the ridge's crossed binding logs
        km.box(timber, T(0, h + rise + 1.4, -L / 2 + 1 + k * (L - 2) / 4) @ Rz_(math.radians(35)), (2.6, .3, .3), WOOD_EDO)
    # the gable ends: a timber triangle with two floors of small windows
    for sz in (d / 2 + .1, -d / 2 - .1):
        km.prism(timber, [(-half + 1.2, 0), (half - 1.2, 0), (0, rise - .6)], T(0, h, sz), .3, rgb(104, 80, 56))
        for y, xs in ((2.6, (-3.2, 0, 3.2)), (6.6, (-1.4, 1.4))):
            for x in xs:
                km.box(glass, T(x, h + y, sz + (.2 if sz > 0 else -.2)), (1.8, 1.4, .1), C["paper"])
    return done(walls, timber, glass, tiles, cloth, metal)


MODELS = {
    "tower_house": tower_house,
    "small_house": small_house,
    "machiya": machiya,
    "tank_house": tank_house,
    "shop_house": shop_house,
    "apartment": apartment,
    "clan_house": clan_house,
    "edo_townhouse": edo_townhouse,
    "edo_inn": edo_inn,
    "kura": kura,
    "tea_shop": tea_shop,
    "farmhouse": farmhouse,
}


# ================================================================================================
# (23/11, passe commune 1: « les murs sont intangibles, comme les toits ») What stops a body:
# each house as a few simple solids that follow what is drawn (the walls' block, each roof
# slope, the eaves, awnings, balconies and their rails, stairs, tanks), in the model's frame
# (x, y up, z; origin at the foot's centre, front at +Z). Server/Hub (the DEV) builds them as
# invisible parts in place of the lot's one box, scaled like the model (X and Z to the lot).
# ("B", cx, cy, cz, sx, sy, sz, yaw): a block. ("W", ...): a WedgePart whose slope RISES toward
# its local +Z (Roblox's wedge); yaw (degrees, about Y): 0 rises to +Z, 180 to -Z, 90 to +X,
# -90 to -X; the size is in the wedge's own frame (X across the slope, Y up, Z along it).
def _B(cx, cy, cz, sx, sy, sz):
    return ("B", cx, cy, cz, sx, sy, sz, 0)


def _gable_s(y0, w, d, pitch, over, thick=.7, z0=0.0):
    half = d / 2 + over
    rise = math.tan(math.radians(pitch)) * half
    L = w + over * 2
    hy = rise + thick
    return [("W", 0, y0 + hy / 2, z0 + half / 2, L, hy, half, 180),
            ("W", 0, y0 + hy / 2, z0 - half / 2, L, hy, half, 0)]


def _eave_s(y0, w, depth, pitch, z_wall):
    drop = math.tan(math.radians(pitch)) * depth
    return [("W", 0, y0 - drop / 2, z_wall + depth / 2, w, drop + .4, depth, 180)]


def _flat_s(h, w, d, parapet=1.2):
    out = [_B(0, h + .25, 0, w + .4, .5, d + .4)]
    for sx, sz, lx, lz in ((0, 1, w + .8, .4), (0, -1, w + .8, .4), (1, 0, .4, d + .8), (-1, 0, .4, d + .8)):
        out.append(_B(sx * (w + .3) / 2, h + .25 + parapet / 2 + .25, sz * (d + .3) / 2, lx, parapet, lz))
    return out


def _tank_s(x, y, z, r, h):
    top = 1.2 + h + 1.2
    return [_B(x, y + top / 2, z, r * 2, top, r * 2)]


def solids(name):
    w, d, h, _ = REF[name]
    F = FLOOR
    body = [_B(0, h / 2, 0, w + .3, h, d + .3)]
    if name == "small_house":
        return body + [_B(-2.6, 6.6, d / 2 + 1.0, 5.2, .6, 2.4)] + _gable_s(h, w, d, 26, 1.2)
    if name == "machiya":
        return body + [_B(0, F - .2, d / 2 + 1.4, w + 1.2, .9, 3.2)] + _gable_s(h, w, d, 26, 1.5)
    if name == "tank_house":
        return (body + _flat_s(h, w, d, 1.3) + [_B(-4.6, 6.4, d / 2 + .9, 4.6, .4, 1.8), _B(-4.5, h + .7, 2, 2.2, .5, 2.2),
                                               _B(-w / 2 - .5, 9.2, -2, 1.0, 1.6, 2.4)] + _tank_s(3, h + .5, -1.5, 2.4, 3.6))
    if name == "shop_house":
        return body + [_B(0, 6.3, d / 2 + 2.0, w + .6, .6, 4.2), _B(0, 1.4, d / 2 + .9, w - 4, 1.6, 1.6),
                       _B(-w / 2 + .6, 3.0, d / 2 + 3.6, .4, 6.0, .4), _B(w / 2 - .6, 3.0, d / 2 + 3.6, .4, 6.0, .4)] + _gable_s(h, w, d, 24, 1.4)
    if name == "apartment":
        out = [_B(0, h / 2, -.8, w, h, d - 1.6), _B(0, .5, 0, w + .3, 1, d + .3)]
        for f in (1, 2):
            y = f * F
            out += [_B(0, y, d / 2 - .8, w + .6, .45, 1.8), _B(0, y + 1.1, d / 2 + .05, w + .4, 2.2, .3)]
        for k in range(8):
            out.append(_B(-w / 2 - 1.4, .9 + k * 1.75, -d / 2 + 2 + k * 1.5, 2.4, .3, 1.5))
        return out + _flat_s(h, w, d, 1.2) + _tank_s(-6, h + .5, -2, 2.2, 3.2) + _tank_s(6, h + .5, -2, 2.0, 2.8)
    if name == "clan_house":
        base = 1.5
        out = [_B(0, base / 2, 0, w + 1, base, d + 1), _B(0, base + (h - base) / 2, -1.2, w - 2, h - base, d - 4.4),
               _B(0, base + .2, d / 2 - 1.6, w - 1, .35, 3.4), _B(0, .45, d / 2 + 1.0, 6, .9, 1.4)]
        for x in (-w / 2 + 1, -w / 6, w / 6, w / 2 - 1):
            out.append(_B(x, base + (h - base) / 2, d / 2 - .2, .5, h - base, .5))
        return out + [_B(0, h + .1, 0, w + .6, .3, d + .6)] + _gable_s(h + .25, w, d, 28, 1.6, .6)
    if name == "tower_house":
        y = 2 * F
        return (body + [_B(-2.6, 6.2, d / 2 + .9, 4.2, .4, 1.8), _B(0, y + .2, d / 2 + 1.0, w - 2, .4, 2.0),
                        _B(0, y + .85, d / 2 + 1.95, w - 2, 1.5, .25)] + _flat_s(h, w, d, 1.2)
                + [_B(-2.2, h + 1.8, -2.2, 5.5, 3.6, 5.5), _B(-2.2, h + 3.75, -2.2, 6.1, .3, 6.1)] + _tank_s(-2.2, h + 3.9, -2.2, 1.8, 2.6))
    if name == "edo_townhouse":
        return ([_B(0, F / 2, 0, w + .3, F, d + .3), _B(0, F + (h - F) / 2, -.6, w, h - F, d - 1.2)]
                + _eave_s(F + .3, w + 1.0, 2.6, 22, d / 2) + _gable_s(h, w, d, 24, 1.8))
    if name == "edo_inn":
        return ([_B(0, F / 2, 0, w + .3, F, d + .3), _B(0, F + (h - F) / 2, -1.2, w, h - F, d - 2.4),
                 _B(0, F + .45, d / 2 - 1.2, w + .2, .3, 2.4), _B(0, F + 1.1, d / 2 - .1, w + .2, 1.5, .25)]
                + _eave_s(F - .3, w + 1.2, 2.4, 20, d / 2) + _gable_s(h + .2, w, d - .8, 26, 2.0, .6, z0=-.4))
    if name == "kura":
        top = h + math.tan(math.radians(30)) * (d / 2 + 1.2) + 1.5
        return body + _eave_s(6.2, 4.4, 1.4, 22, d / 2) + _gable_s(h, w, d, 30, 1.2, .9) + [_B(0, top, 0, w + 3.0, .9, 1.4)]
    if name == "tea_shop":
        return ([_B(0, h / 2, -1.0, w, h, d - 2.0), _B(0, .35, 0, w + .3, .7, d + .3), _B(0, 1.3, d / 2 - 1.0, w - 3, 1.6, 1.4),
                 _B(0, 5.4, d / 2 + .6, w + .6, .5, 4.4), _B(-3.5, .6, d / 2 + 1.4, 5.0, 1.2, 1.6),
                 _B(-w / 2 + .5, 2.7, d / 2 + 2.6, .3, 5.4, .3), _B(w / 2 - .5, 2.7, d / 2 + 2.6, .3, 5.4, .3)]
                + _gable_s(h, w, d - 2.0, 24, 1.4, z0=-1.0))
    if name == "farmhouse":
        half = w / 2 + 1.6
        rise = math.tan(math.radians(58)) * half
        hy = rise + 1.3
        L = d + 3.0
        return body + [("W", half / 2, h + hy / 2, 0, L, hy, half, -90), ("W", -half / 2, h + hy / 2, 0, L, hy, half, 90)]
    raise KeyError(name)


def solid_objects(name):
    """Blender objects for a house's solids (Roblox frame -> konoha_models.blender's frame)."""
    import konoha_models as km
    from nd_mesh import to_blender
    out = []
    for k, cx, cy, cz, sx, sy, sz, yaw in solids(name):
        pc = Piece("Solid", "Neon", flat=True, alpha=.55)
        m = T(cx, cy, cz) @ Ry(math.radians(yaw))
        hx, hy, hz = sx / 2, sy / 2, sz / 2
        if k == "B":
            km.box(pc, m, (sx, sy, sz), rgb(230, 40, 40), bottom=True)
        else:   # the wedge: high edge at local +Z
            pts = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)]
            ix = [pc.add(m @ Vector(p), rgb(230, 40, 40)) for p in pts]
            for f in ((0, 1, 2, 3), (3, 2, 4, 5), (0, 3, 5), (1, 4, 2), (0, 5, 4, 1)):
                pc.face(*[ix[i] for i in f])
        out.append(to_blender(km.blender([pc])[0]))
    return out


def solids_luau():
    """Shared/HubSolids.luau: model name -> its solids (rounded to the hundredth)."""
    lines = []
    for name in MODELS:
        rows = []
        for k, cx, cy, cz, sx, sy, sz, yaw in solids(name):
            rows.append('{"%s",%s}' % (k, ",".join("%g" % round(v, 2) for v in (cx, cy, cz, sx, sy, sz, yaw))))
        lines.append("\t%s={%s}," % (name, ",".join(rows)))
    return ("--!strict\n-- GENERATED by tools/blender/konoha_houses.py (solids). Do not edit: re-run the script.\n"
            "-- (23/11, passe commune 1) What stops a body in each house, following what is drawn, in the\n"
            "-- model's frame (x, y up, z; origin at the foot's centre, the front at +Z; before the lot's\n"
            "-- scale). {kind, cx, cy, cz, sx, sy, sz, yaw}: kind \"B\" a block, \"W\" a WedgePart whose slope\n"
            "-- rises toward its local +Z; yaw in degrees about Y (0: rises to +Z, 180: to -Z, 90: to +X);\n"
            "-- the size is in the part's own frame. The builder scales X and Z like the model.\n"
            "return {\n" + "\n".join(lines) + "\n}\n")


def check(name, ps):
    from nd_mesh import stats
    import konoha_layout
    lay = konoha_layout.HOUSES[name]
    assert (lay[5][0], lay[5][1], lay[1], lay[0]) == REF[name], "%s: KonohaLayout.HOUSES disagrees with REF" % name
    _, t = stats(ps)
    assert MIN_TRIS <= t <= REF[name][3], "%s: %d triangles (budget %d to %d)" % (name, t, MIN_TRIS, REF[name][3])
    return t


def report():
    out = {}
    for name, fn in MODELS.items():
        from nd_mesh import stats
        out[name] = stats(fn())[1]
    return out


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if args and args[0] == "solids":
        open(os.path.join(args[1], "HubSolids.luau"), "w").write(solids_luau())
        print("wrote HubSolids.luau", len(MODELS), "houses")
    if args and args[0] == "render":
        import konoha_models as km
        from nd_mesh import to_blender, render_set, clear, stats
        out = args[1]
        os.makedirs(out, exist_ok=True)
        for name in ([a for a in args[2:] if not a.startswith("--")] or MODELS):
            clear()
            ps = km.blender(MODELS[name]())
            t = stats(ps)[1]
            objs = [to_blender(p) for p in ps]
            if "--solids" in sys.argv:   # the solids over the model, translucent red
                objs += solid_objects(name)
            render_set(objs, os.path.join(out, name + ".png"), size=(640, 480), view=(.9, -1.2, .6), fill=.9,
                       world=(.66, .7, .76))
            print("HOUSE", name, t, "tris", "budget", REF[name][3], flush=True)
    else:
        print(report())
