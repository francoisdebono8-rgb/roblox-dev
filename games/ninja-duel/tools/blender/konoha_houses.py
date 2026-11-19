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
    "clan_house": (22, 17, 9, 1600),
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


def window(frame, glass, m, w=2.8, h=2.4, shutter=None):
    """A lean window facing +Z at m: a dark pane, a sill and a head, one lattice cross."""
    km = K()
    C = km.C
    km.box(glass, m @ T(0, 0, .02), (w, h, .12), rgb(46, 42, 40))
    km.box(frame, m @ T(0, -h / 2 - .14, .16), (w + .5, .26, .42), C["wood"])
    km.box(frame, m @ T(0, h / 2 + .12, .12), (w + .4, .24, .3), C["woodDark"])
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
    for k in range(12):
        km.box(timber, T(-2.8 + k * .84, 3.2, d / 2 + .18), (.22, 4.6, .22), C["woodLight"])
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
    for k in range(7):
        km.box(timber, T(-w / 2 + 1.5 + k * (w - 3) / 6, FLOOR + 1.0, d / 2 + .7), (.2, 1.2, .2), C["wood"])
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
            window(timber, glass, T(x + 1.9, y + 4.0, d / 2 - 1.55), 2.6, 2.0)
        if f > 0:
            km.box(walls, T(0, y, d / 2 - .8), (w + .6, .45, 1.8), trim)
            km.box(timber, T(0, y + 2.2, d / 2 + .05), (w + .4, .25, .25), C["iron"])
            for k in range(9):
                km.box(metal, T(-w / 2 + .5 + k * (w - 1) / 8, y + 1.1, d / 2 + .05), (.16, 2.2, .16), C["iron"])
        for z in (-5, 1):
            window(timber, glass, T(w / 2 + .05, y + 4.0, z) @ Ry(math.pi / 2), 2.4, 2.0)
        for x in (-6, 6):
            window(timber, glass, T(x, y + 4.0, -d / 2 - .05) @ Ry(math.pi), 3.0, 2.0)
    # the outside stair up the west side, the roof, two tanks, laundry poles
    for k in range(10):
        km.box(timber, T(-w / 2 - 1.4, .7 + k * 1.4, -d / 2 + 2 + k * 1.2), (2.4, .3, 1.2), C["iron"])
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


MODELS = {
    "small_house": small_house,
    "machiya": machiya,
    "tank_house": tank_house,
    "shop_house": shop_house,
    "apartment": apartment,
    "clan_house": clan_house,
}


def check(name, ps):
    from nd_mesh import stats
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
    if args and args[0] == "render":
        import konoha_models as km
        from nd_mesh import to_blender, render_set, clear, stats
        out = args[1]
        os.makedirs(out, exist_ok=True)
        for name in (args[2:] or MODELS):
            clear()
            ps = km.blender(MODELS[name]())
            t = stats(ps)[1]
            objs = [to_blender(p) for p in ps]
            render_set(objs, os.path.join(out, name + ".png"), size=(640, 480), view=(.9, -1.2, .6), fill=.9,
                       world=(.66, .7, .76))
            print("HOUSE", name, t, "tris", "budget", REF[name][3], flush=True)
    else:
        print(report())
