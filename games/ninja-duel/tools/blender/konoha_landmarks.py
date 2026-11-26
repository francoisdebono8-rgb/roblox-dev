"""The landmarks of the new Konoha and the training props (21/11, étape 3 ANIMATEUR 1 and 4, DEC-047).

The plan (Shared/KonohaLayout.Buildings) names each landmark by a model; Server/Hub tags the
building with it (Dress) and Client/HubDress puts this mesh there. Same frame as the houses
(konoha_houses.py): Roblox's axes in HubMap's base studs, origin at the centre of the foot, the
door toward +Z, `w` along X, `d` along Z, the layout's footprint and height (REF below; the
builder may scale a second, differently sized lot of the same model with REF).

Naruto part I, looked up again before modelling (the anime's establishing shots):
  * the Hokage Residence: a big round tower, red-orange plaster, a ring of windows per floor,
    a wide low roof with a terrace, a round red plate on the front (no 火: no letters);
  * the great gate (A-un gate): two tall pillars, a tiled roof over the beam, two huge green
    doors standing open (their kanji left out), guard booths aside;
  * Ichiraku: a narrow stall with a counter and stools, short noren split curtains, lanterns;
  * the hospital and the academy: plain three-storey blocks, the academy red-orange with the
    swing tree in front of it;
  * the chūnin exam preliminaries' hall: the long back wall with tall windows and the side
    galleries with railings the genin watch from;
  * the Hyūga compound's halls: white walls on a stone base, dark timber, hip roofs, engawa;
  * the Uchiha police: a squat building with a curved roof (its crest left out);
  * the Naka shrine, its torii and the pier; a market hall; the water tower.
The training props of Training Ground Three: the wooden posts (the bell test's), here as a
training dummy (straw wrapped, arm pegs, a paper target) and a kunai target (painted rings on
a board, on a tripod, and one on a stump). No logos, no real words anywhere.

    blender -b --python-expr ... konoha_models.py render OUT_DIR <names>   (they join MODELS)
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Matrix, Vector
from nd_mesh import Piece, rgb, lerp, loft, tube

import konoha_houses as KH

T, Ry, Rx = KH.T, KH.Ry, KH.Rx

# model: (w, d, h) - the plan's footprint (KonohaLayout.Buildings, first lot of that model)
REF = {
    "hokage_residence": (44, 44, 40), "hospital": (36, 30, 24), "academy_annex": (36, 30, 24),
    "exam_hall": (90, 12, 26), "exam_hall_wing": (8, 42, 18), "ichiraku": (16, 12, 9),
    "great_gate": (48, 8, 50), "hyuga_hall": (60, 22, 14), "hyuga_gate": (8, 20, 10),
    "uchiha_police": (24, 18, 16), "naka_shrine": (26, 22, 16), "torii": (4, 18, 15),
    "pier": (18, 12, 2), "water_tower": (16, 16, 34), "market_hall": (26, 14, 12),
    "memorial_stone": (4, 2, 6), "academy_tree": (6, 6, 18), "final_arena": (64, 64, 3),
    "training_dummy": (3, 3, 7), "kunai_target": (4, 2, 6), "stump_target": (3, 3, 3), "kunai_board": (4, 1, 4), "market_stall": (8, 5, 6), "barrel": (3, 3, 3.6),
}


def K():
    return KH.K()


def P():
    return KH.pieces("lm")


def ring(m, y, r, n):
    return [m @ Vector((math.cos(a) * r, y, math.sin(a) * r)) for a in [i / n * math.tau for i in range(n)]]


def floors_of_windows(timber, glass, w, d, h, floors, per, z_front=True, sides=True, back=True, h0=1.5):
    fh = (h - h0) / floors
    for f in range(floors):
        y = h0 + fh * (f + .55)
        for i in range(per):
            x = -w / 2 + (i + .5) * w / per
            if z_front:
                KH.window(timber, glass, T(x, y, d / 2 + .05), 2.6, 2.4)
            if back:
                KH.window(timber, glass, T(x, y, -d / 2 - .05) @ Ry(math.pi), 2.6, 2.4)
        if sides:
            n = max(1, int(d / 6))
            for i in range(n):
                z = -d / 2 + (i + .5) * d / n
                KH.window(timber, glass, T(w / 2 + .05, y, z) @ Ry(math.pi / 2), 2.4, 2.2)
                KH.window(timber, glass, T(-w / 2 - .05, y, z) @ Ry(-math.pi / 2), 2.4, 2.2)


# ------------------------------------------------------------------ the landmarks
def hokage_residence():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["hokage_residence"]
    r = w / 2 - 2
    orange = rgb(204, 98, 56)
    # the round body: three bands of plaster, a darker band at each floor
    for k, (y0, y1) in enumerate(((0, 13), (13, 25), (25, h - 6))):
        loft(walls, [ring(T(0, 0, 0), y0, r, 28), ring(T(0, 0, 0), y1, r - .4 * k, 28)],
             lambda q, kk: km.grime(km.jitter(orange, q, .05, .4), q, 0, 3, .3))
        loft(timber, [ring(T(0, 0, 0), y1 - .5, r + .3, 28), ring(T(0, 0, 0), y1 + .3, r + .3, 28)], C["woodDark"])
    # a ring of windows on each floor
    for y in (8, 19.5, 29.5):
        for i in range(14):
            a = i / 14 * math.tau
            m = T(math.sin(a) * (r + .05), y, math.cos(a) * (r + .05)) @ Ry(a)
            KH.window(timber, glass, m, 2.2, 2.6, cross=True)
    # the low wide roof with its terrace and railing
    loft(tiles, [ring(T(0, 0, 0), h - 6, r + 3.5, 28), ring(T(0, 0, 0), h - 3.5, r - 3, 28)],
         lambda q, kk: km.jitter(C["roofDark"], q, .06, .6), cap0=True, cap1=False)
    loft(walls, [ring(T(0, 0, 0), h - 3.5, r - 3, 24), ring(T(0, 0, 0), h - 1.8, r - 3, 24)], orange, cap1=True)
    for i in range(24):
        a = i / 24 * math.tau
        km.box(timber, T(math.sin(a) * (r - 3.4), h - 1, math.cos(a) * (r - 3.4)), (.3, 1.6, .3), C["woodDark"])
    loft(timber, [ring(T(0, 0, 0), h - .3, r - 3.4, 24), ring(T(0, 0, 0), h, r - 3.4, 24)], C["woodDark"], cap0=False, cap1=False)
    # the front: an entrance block with a tiled porch roof and the round red plate (no letter)
    km.box(walls, T(0, 4, r - .5), (12, 8, 6), km.wall_col(orange), cell=2)
    KH.door(timber, T(0, 0, r + 2.55), 5, 6.4)
    km.box(tiles, T(0, 8.4, r + 2.6) @ Rx(math.radians(16)), (14, .5, 5), C["roofDark"])
    km.cyl(metal, T(0, 33, r + .6) @ Rx(math.pi / 2), 4.2, .5, rgb(176, 40, 32), sides=20)
    km.cyl(metal, T(0, 33, r + .9) @ Rx(math.pi / 2), 3.4, .3, rgb(236, 226, 206), sides=20)
    # the base: stone steps all round the foot
    loft(walls, [ring(T(0, 0, 0), 0, r + 1.5, 28), ring(T(0, 0, 0), .8, r + 1.5, 28)], C["stone"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def block_building(name, color, roof="flat", floors=3, sign_col=None, extra=None):
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF[name]
    KH.wall(walls, T(0, h / 2, 0), (w, h, d), color, cell=4)
    km.box(walls, T(0, .7, 0), (w + .6, 1.4, d + .6), lambda q, f: km.grime(C["stoneDark"], q, 0, 1.4, .3))
    for f in range(1, floors):
        km.box(timber, T(0, 1.5 + (h - 1.5) / floors * f, 0), (w + .5, .5, d + .5), C["woodDark"])
    floors_of_windows(timber, glass, w, d, h, floors, max(2, int(w / 6)))
    KH.door(timber, T(0, 0, d / 2 + .05), 4.4, 6)
    km.box(tiles, T(0, 7.2, d / 2 + 2) @ Rx(math.radians(14)), (9, .4, 4.4), C["roofDark"])
    for x in (-3.8, 3.8):
        km.box(timber, T(x, 3.5, d / 2 + 3.6), (.5, 7, .5), C["wood"])
    if roof == "hip":
        KH.hip(tiles, timber, T(0, h, 0), w, d, 22, 1.6, C["roofTerra"])
    else:
        km.box(walls, T(0, h + .5, 0), (w + 1, 1, d + 1), lerp(color, rgb(40, 40, 40), .3))
        KH.tank(timber, metal, T(w / 4, h + 1, -d / 5), 3, 4)
        KH.tank(timber, metal, T(-w / 3, h + 1, d / 6), 2.4, 3.4)
    if sign_col:
        KH.sign(timber, cloth, T(0, h * .72, d / 2 + .35), w * .45, 2.4, sign_col, 3, 4)
    if extra:
        extra(walls, timber, glass, tiles, cloth, metal)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def hospital():
    return block_building("hospital", rgb(214, 206, 186), "flat", 3, rgb(182, 54, 44))


def academy_annex():
    return block_building("academy_annex", rgb(206, 116, 72), "hip", 3, rgb(232, 214, 176))


def exam_hall():
    """The back of the preliminaries' hall: a long tall wall, tall windows, a gable roof."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["exam_hall"]
    KH.wall(walls, T(0, h / 2, 0), (w, h, d), rgb(196, 182, 160), cell=5)
    for i in range(9):
        x = -w / 2 + (i + .5) * w / 9
        km.box(timber, T(x, h / 2, d / 2 + .3), (1.2, h, .6), C["woodDark"])
        KH.window(timber, glass, T(x + 4.5, h * .58, d / 2 + .05), 3.2, 9, cross=True)
        KH.window(timber, glass, T(x + 4.5, h * .58, -d / 2 - .05) @ Ry(math.pi), 3.2, 9, cross=True)
    km.box(walls, T(0, 1, 0), (w + .6, 2, d + .6), C["stone"])
    KH.gable(tiles, timber, T(0, h, 0), w, d, 24, 1.6, C["roofDark"], courses=3, ribs=18)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def exam_hall_wing():
    """A side gallery of the hall: the balcony the genin watch from, its railing, posts."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["exam_hall_wing"]
    KH.wall(walls, T(-w / 4, h / 2, 0), (w / 2, h, d), rgb(196, 182, 160), cell=4)
    km.box(timber, T(w / 4, 10, 0), (w / 2, .6, d), lambda q, f: km.wood(q, f, C["woodLight"]), cell=1.5)
    for z in range(int(-d / 2) + 2, int(d / 2), 6):
        km.box(timber, T(w / 2 - .4, 5, z), (.7, 10, .7), C["woodDark"])
        km.box(timber, T(w / 2 - .4, 12.5, z), (.3, 4.4, .3), C["wood"])
    km.box(timber, T(w / 2 - .4, 11.4, 0), (.3, .3, d), C["wood"])
    km.box(timber, T(w / 2 - .4, 14.6, 0), (.4, .4, d), C["woodDark"])
    for z in range(int(-d / 2) + 3, int(d / 2), 6):
        KH.window(timber, glass, T(-.05, 14, z) @ Ry(math.pi / 2), 2.4, 3)
    km.box(tiles, T(0, h + .4, 0) @ Rx(0), (w + 2, .6, d + 2), C["roofDark"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def ichiraku():
    """The ramen stall: a kitchen at the back, the counter on the street with five stools, the
    short noren hanging from the awning, two red lanterns. (yaw 90 in the plan: the counter
    faces +Z of the model all the same.)"""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["ichiraku"]
    KH.wall(walls, T(0, h / 2, -d / 2 + 2.5), (w, h, 5), C["plasterWarm"])
    km.box(timber, T(0, 1.8, d / 2 - 2.2), (w - 1, 3.6, 2.2), lambda q, f: km.wood(q, f, C["woodLight"]), cell=1.2)
    km.box(timber, T(0, 3.75, d / 2 - 2.2), (w - .4, .35, 2.8), C["wood"])
    for i in range(5):
        x = -w / 2 + 2 + i * (w - 4) / 4
        km.cyl(metal, T(x, 0, d / 2 + .3), .18, 2.4, C["iron"], sides=6)
        km.cyl(cloth, T(x, 2.4, d / 2 + .3), .75, .35, rgb(190, 50, 40), sides=10)
    for x in (-w / 2 + .3, w / 2 - .3):
        km.box(timber, T(x, h / 2, d / 2 - .4), (.5, h, .5), C["woodDark"])
    km.box(tiles, T(0, h - .4, d / 2 - 1) @ Rx(math.radians(14)), (w + 1.5, .4, 5.4), C["roofTerra"])
    km.noren(cloth, T(0, h - 1.3, d / 2 + .2) @ Ry(-math.pi / 2), rgb(236, 230, 214), n=5, w=2.6, h=1.6)
    for x in (-w / 2 + .8, w / 2 - .8):
        KH.lantern(cloth, metal, T(x, h - 2.6, d / 2 + 1.0))
    # the kitchen: a pot and a hood behind the counter
    km.cyl(metal, T(-3, 3.9, d / 2 - 5.5), 1, 1.6, C["iron"], sides=12)
    km.box(metal, T(-3, 7, d / 2 - 5.5), (3, .8, 3), C["iron"])
    KH.sign(timber, cloth, T(0, h + 1, d / 2 - 1.5), 6, 1.4, rgb(232, 214, 176), 2, 7)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def great_gate():
    """The A-un gate: two pillars on stone feet, the beam, a tiled roof, two huge doors open
    against the pillars (green, banded), a plate on the beam without its letters."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["great_gate"]
    red = rgb(150, 70, 48)
    for x in (-w / 2 + 3, w / 2 - 3):
        km.box(timber, T(x, h * .44, 0), (5.5, h * .88, 6), lambda q, f: km.grime(km.jitter(red, q, .05, .6), q, 0, 4, .4), cell=3)
        km.box(walls, T(x, 1.5, 0), (7.2, 3, 7.4), C["stone"])
        for y in (14, 30):
            km.box(metal, T(x, y, 0), (5.8, .7, 6.3), C["iron"])
    km.box(timber, T(0, h * .8, 0), (w, 4, 6.4), red, cell=3)
    km.box(timber, T(0, h * .8 - 2.6, 0), (w - 6, 1.2, 5), C["woodDark"])
    km.box(metal, T(0, h * .8, 3.4), (12, 3.2, .4), rgb(60, 58, 54))
    km.box(cloth, T(0, h * .8, 3.65), (11, 2.6, .1), rgb(214, 200, 168))
    KH.gable(tiles, timber, T(0, h * .8 + 2, 0), w + 2, 7, 26, 2.2, C["roofDark"], courses=2, ribs=14)
    green = rgb(70, 120, 76)
    for s in (-1, 1):   # the doors swung open, flat against the inside of the pillars
        x = s * (w / 2 - 6.5)
        km.box(timber, T(x, h * .4, -6.5), (1, h * .8, 11), lambda q, f: km.jitter(green, q, .05, .5), cell=2)
        for y in (6, h * .4, h * .74):
            km.box(metal, T(x - s * .6, y, -6.5), (.3, .6, 11), C["iron"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def hyuga_hall():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["hyuga_hall"]
    km.box(walls, T(0, .9, 0), (w + 2, 1.8, d + 2), C["stone"])
    KH.wall(walls, T(0, 1.8 + (h - 1.8) / 2, 0), (w, h - 1.8, d), rgb(236, 232, 222), cell=3)
    for i in range(int(w / 4) + 1):
        x = -w / 2 + i * w / int(w / 4)
        km.box(timber, T(x, h / 2 + .9, d / 2 + .2), (.6, h - 1.8, .5), C["woodDark"])
        km.box(timber, T(x, h / 2 + .9, -d / 2 - .2), (.6, h - 1.8, .5), C["woodDark"])
    km.box(timber, T(0, 2.1, d / 2 + 1.6), (w, .4, 3), lambda q, f: km.wood(q, f, C["woodLight"]), cell=1.4)  # the engawa
    for i in range(int(w / 6)):
        x = -w / 2 + 3 + i * 6
        km.box(glass, T(x, 6, d / 2 + .1), (4.6, 6, .1), rgb(232, 224, 200))
        km.box(timber, T(x, 6, d / 2 + .16), (4.6, .12, .06), C["woodDark"])
        km.box(timber, T(x, 6, d / 2 + .16), (.12, 6, .06), C["woodDark"])
    KH.hip(tiles, timber, T(0, h, 0), w, d, 26, 2.4, C["roofDark"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def hyuga_gate():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["hyuga_gate"]
    for z in (-d / 2 + 2.5, d / 2 - 2.5):
        KH.wall(walls, T(0, h * .35, z), (w, h * .7, 5), rgb(236, 232, 222), cell=2)
    for z in (-3.5, 3.5):
        km.box(timber, T(0, h * .4, z), (1, h * .8, 1), C["woodDark"])
    km.box(timber, T(0, h * .78, 0), (w + 1, 1, d - 2), C["woodDark"])
    KH.gable(tiles, timber, T(0, h * .8, 0) @ Ry(math.pi / 2), d, w, 28, 1.6, C["roofDark"], courses=2, ribs=8)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def uchiha_police():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["uchiha_police"]
    KH.wall(walls, T(0, h * .4, 0), (w, h * .8, d), rgb(150, 92, 80), cell=3)
    floors_of_windows(timber, glass, w, d, h * .8, 2, 4)
    KH.door(timber, T(0, 0, d / 2 + .05), 5, 6.6)
    # the curved roof: a vault of tiles over the block
    pts = [(-w / 2 - 1.5, 0)] + [((w / 2 + 1.5) * math.cos(a), 4 * math.sin(a)) for a in [math.pi - i / 10 * math.pi for i in range(11)]]
    km.prism(tiles, [(-(w / 2 + 1.5), 0)] + [((w / 2 + 1.5) * -math.cos(i / 10 * math.pi), 4 * math.sin(i / 10 * math.pi)) for i in range(11)],
             T(0, h * .8, 0), d + 2, C["roofDark"])
    KH.sign(timber, cloth, T(0, h * .62, d / 2 + .35), 8, 1.8, rgb(232, 214, 176), 2, 3)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def naka_shrine():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["naka_shrine"]
    km.box(walls, T(0, 1, 0), (w, 2, d), C["stone"])
    for i in range(4):
        km.box(walls, T(0, .25 + i * .5, d / 2 + 2 - i * .6), (8, .5, 1.2), C["stoneDark"])
    KH.wall(walls, T(0, 2 + (h - 7) / 2, -1), (w - 6, h - 7, d - 8), rgb(118, 50, 40), cell=2)
    for sx in (-1, 1):
        for sz in (-1, 1):
            km.box(timber, T(sx * (w / 2 - 3.5), h / 2 - 1, sz * (d / 2 - 4) - 1), (1, h - 4, 1), rgb(160, 50, 38))
    KH.hip(tiles, timber, T(0, h - 5, -1), w - 6, d - 8, 30, 3.2, C["roofDark"])
    KH.lantern(cloth, metal, T(-3, 8, d / 2 - 3.5))
    KH.lantern(cloth, metal, T(3, 8, d / 2 - 3.5))
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def torii():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["torii"]
    red = rgb(196, 58, 40)
    for z in (-d / 2 + 2, d / 2 - 2):
        km.cyl(timber, T(0, 0, z), .9, h - 1.5, red, sides=10)
        km.box(timber, T(0, .5, z), (2.2, 1, 2.2), C["black"])
    km.box(timber, T(0, h - 4.5, 0), (1, 1, d - 2), red)
    km.box(timber, T(0, h - 1.2, 0), (1.6, 1.2, d + 2.4), red)
    km.box(timber, T(0, h - .3, 0), (1.8, .6, d + 3.2), C["black"])
    km.box(timber, T(0, h - 2.8, 0), (.4, 2.6, 1.2), C["black"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def pier():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["pier"]
    km.box(timber, T(0, h - .3, 0), (w, .6, d), lambda q, f: km.wood(q, f, C["woodGrey"]), cell=1.2)
    for x in range(int(-w / 2) + 1, int(w / 2), 4):
        for z in (-d / 2 + .6, d / 2 - .6):
            km.cyl(timber, T(x, -6, z), .35, 6 + h, C["woodDark"], sides=6)
    for z in (-d / 2 + .2, d / 2 - .2):
        km.box(timber, T(0, h + .9, z), (w, .2, .2), C["wood"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def water_tower():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["water_tower"]
    legs = h - 12
    for sx in (-1, 1):
        for sz in (-1, 1):
            km.box(timber, T(sx * (w / 2 - 1.5), legs / 2, sz * (d / 2 - 1.5)), (1, legs, 1), C["woodDark"])
    for y in (legs * .33, legs * .66):
        for s in (-1, 1):
            km.box(timber, T(0, y, s * (d / 2 - 1.5)), (w - 2, .5, .5), C["wood"])
            km.box(timber, T(s * (w / 2 - 1.5), y, 0), (.5, .5, d - 2), C["wood"])
    km.box(timber, T(0, legs, 0), (w, .8, d), C["woodDark"])
    KH.tank(timber, metal, T(0, legs, 0), w / 2 - 1, 9, 18)
    for i in range(int(legs / 2)):
        km.box(timber, T(w / 2 - .8, 1 + i * 2, d / 2 - .2), (1.4, .2, .2), C["woodLight"])
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def market_hall():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["market_hall"]
    KH.wall(walls, T(0, h / 2, -d / 2 + 2), (w, h, 4), C["plasterWarm"])
    for x in range(int(-w / 2) + 1, int(w / 2) + 1, 5):
        km.box(timber, T(x, h * .4, d / 2 - .5), (.6, h * .8, .6), C["woodDark"])
    for i, col in enumerate((rgb(190, 60, 44), rgb(236, 220, 180), rgb(70, 110, 160), rgb(200, 150, 60))):
        x = -w / 2 + 3.5 + i * (w - 7) / 3
        km.box(timber, T(x, 1.6, d / 2 - 3), (5, 3.2, 2.6), C["wood"])
        km.box(cloth, T(x, 3.35, d / 2 - 3), (4.6, .3, 2.2), col)       # the goods (cloth, crates of produce)
        km.box(cloth, T(x, h * .62, d / 2 - .3) @ Rx(math.radians(20)), (5, .2, 3), col)  # awning
    KH.gable(tiles, timber, T(0, h * .8, 0), w, d, 22, 1.5, C["roofTerra"], courses=2, ribs=10)
    KH.sign(timber, cloth, T(0, h * .8 + 2.5, d / 2 + 1), 9, 1.6, rgb(190, 60, 44), 3, 11)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def memorial_stone():
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["memorial_stone"]
    km.prism(walls, [(-w / 2, 0), (w / 2, 0), (w / 2 - .4, h * .8), (.3, h), (-w / 2 + .5, h * .85)], T(0, 0, 0), d,
             lambda q, f: km.jitter(rgb(70, 72, 78), q, .1, 1.5))
    km.box(walls, T(0, .3, 0), (w + 2, .6, d + 2), C["stone"])
    for i in range(6):
        km.box(glass, T(-w / 2 + .8 + i * .5, h * .5, d / 2 + .02), (.12, h * .6, .04), rgb(40, 40, 46))
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def academy_tree():
    """The academy's swing tree: a broad tree, a rope swing from its low branch."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    w, d, h = REF["academy_tree"]
    base = km.MODELS["TreeA"]()
    out = list(base)
    km.box(timber, T(3.5, 9.5, 0) @ Matrix.Rotation(math.radians(-20), 4, "Z"), (7, .9, .9), C["bark"])
    for z in (-.7, .7):
        km.box(cloth, T(5.5, 6.2, z), (.12, 6.4, .12), C["rope"])
    km.box(timber, T(5.5, 3, 0), (1, .25, 2), C["woodLight"])
    return out + KH.done(walls, timber, glass, tiles, cloth, metal)


# ------------------------------------------------------------------ the Ōtsutsuki's arena (passe 3)
def final_arena():
    """(26/11, passe 3, DEV: « son arène de finale au crépuscule ») Where the host of the
    tournament waits and the final is fought: a raised round stage of dressed stone (the duel's
    ring, 18 across its middle, inlaid darker), steps on its front (+Z), a ring of stone posts
    each with a lit brazier, and at its back a tall crimson torii framing the low sun. The dusk
    itself is the client's (Client/ArenaDuskFX): the braziers are the light that stays."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    fire = Piece("Fire", "Neon", flat=True)
    w, d, h = REF["final_arena"]
    R = w / 2 - 2
    stone = lambda q, f: km.grime(km.jitter(rgb(150, 144, 136), q, .1, .9), q, 0, 1.6, .35)
    km.cyl(walls, T(0, 0, 0), R + 1.5, .8, rgb(96, 92, 88), sides=24)
    km.cyl(walls, T(0, 0, 0), R, h, stone, sides=24)
    # the duel's ring and a band round it
    km.cyl(walls, T(0, h - .02, 0), 19, .08, rgb(104, 98, 94), sides=40)
    km.cyl(walls, T(0, h - .01, 0), 17.6, .1, rgb(132, 126, 120), sides=40)
    # the steps up, on the front
    for k in range(3):
        km.box(walls, T(0, h * (k + 1) / 4 - h / 8, R + 3.2 - k * 1.2), (14, h * (k + 1) / 4, 1.4), stone)
    # the posts and their braziers (none in front of the steps)
    for i in range(10):
        a = (i + .5) / 10 * math.tau
        x, z = math.sin(a) * (R - 1.6), math.cos(a) * (R - 1.6)
        if z > R * .8:
            continue
        km.box(walls, T(x, h + 4, z), (1.8, 8, 1.8), stone)
        km.box(walls, T(x, h + .3, z), (2.6, .6, 2.6), rgb(96, 92, 88))
        km.cyl(metal, T(x, h + 8, z), 1.1, .9, C["iron"], sides=10, r2=1.6)
        rings = [[Vector((x + math.cos(t) * r, h + 8.8 + y, z + math.sin(t) * r)) for t in [j / 8 * math.tau for j in range(8)]]
                 for y, r in ((0, 1.2), (.9, .8), (1.9, .25))]
        loft(fire, rings, lambda q, kk: (1.0, .55 + .25 * ((q.y - h - 8.8) / 1.9), .2), cap0=True, cap1=True)
    # the crimson torii at the back, over the stage's edge
    red, black = rgb(170, 40, 34), rgb(34, 30, 30)
    for sx in (-1, 1):
        km.cyl(timber, T(sx * 9, h, -R + 1.5), .9, 22, red, sides=12)
        km.cyl(timber, T(sx * 9, h, -R + 1.5), 1.2, 1.2, black, sides=12)
    km.box(timber, T(0, h + 17, -R + 1.5), (24, 1.2, 1.4), red)
    km.box(timber, T(0, h + 21.2, -R + 1.5), (30, 1.4, 2), black)
    km.box(timber, T(0, h + 20.4, -R + 1.5), (28, .9, 1.7), red)
    km.box(timber, T(0, h + 19, -R + 1.5), (1.4, 3, .9), red)
    # (François's reference, 26/11 23:38) behind the ring, stone towers hung with white banners,
    # three black tomoe on each, a brazier on each tower
    ink = Piece("Ink", "SmoothPlastic", flat=True)
    for x, z in ((-22, -20), (22, -20), (-30, 4), (30, 4)):
        m = T(x, 0, z) @ Ry(math.atan2(x, z))   # the banner (-Z) faces the ring
        km.box(walls, m @ T(0, 9, 0), (7, 18, 7), lambda q, f: km.grime(km.jitter(rgb(84, 80, 82), q, .1, .8), q, 0, 3, .4))
        km.box(walls, m @ T(0, 18.4, 0), (8, .8, 8), rgb(60, 56, 58))
        km.box(cloth, m @ T(0, 10.5, -3.62), (4.2, 9, .12), rgb(232, 228, 220))
        km.box(timber, m @ T(0, 15.1, -3.75), (5, .35, .35), rgb(40, 34, 30))
        for k, (bx, by) in enumerate(((-1, 12.4), (1, 12.4), (0, 9.4))):
            c = m @ Vector((bx * .95, by, -3.72))
            out = (m.to_3x3() @ Vector((0, 0, -1))).normalized()
            right = (m.to_3x3() @ Vector((1, 0, 0))).normalized()
            tube(ink, [c, c + out * .05], .5, rgb(24, 22, 26), sides=14)
            pts = [c + right * (.35 * math.cos(a)) + Vector((0, .35 * math.sin(a) - .2 * j, 0)) + out * .03
                   for j, a in enumerate([math.radians(-10 - 40 * j) for j in range(6)])]
            tube(ink, pts, lambda kk: .28 * (1 - kk) + .03, rgb(24, 22, 26), sides=8, tip1=True)
        km.cyl(metal, m @ T(0, 18.8, 0), 1.3, 1, C["iron"], sides=10, r2=1.8)
        top = m @ Vector((0, 19.8, 0))
        rings = [[Vector((top.x + math.cos(t) * r, top.y + y, top.z + math.sin(t) * r)) for t in [j / 8 * math.tau for j in range(8)]]
                 for y, r in ((0, 1.4), (1.1, .9), (2.3, .25))]
        loft(fire, rings, lambda q, kk: (1.0, .6, .2), cap0=True, cap1=True)
    return KH.done(walls, timber, glass, tiles, cloth, metal) + [p for p in (fire, ink) if p.v]


# ------------------------------------------------------------------ Training Ground Three
def training_dummy():
    """The training dummy: a post on a stone foot, a straw-wrapped body bound with rope, two
    arm pegs, a head block, a paper target on the chest (rings, no letter)."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    straw = rgb(196, 168, 106)
    km.cyl(walls, T(0, 0, 0), 1.4, .6, C["stone"], sides=10)
    km.cyl(timber, T(0, .6, 0), .45, 6.4, lambda q, k: km.wood(q, None, C["wood"]), sides=8)
    loft(cloth, [ring(T(0, 0, 0), 2.6, 1.05, 10), ring(T(0, 0, 0), 3.6, 1.15, 10), ring(T(0, 0, 0), 4.8, 1.05, 10),
                 ring(T(0, 0, 0), 5.3, .8, 10)], lambda q, k: km.jitter(straw, q, .12, 3.0))
    for y in (2.9, 3.9, 4.9):
        loft(cloth, [ring(T(0, 0, 0), y, 1.12, 10), ring(T(0, 0, 0), y + .18, 1.12, 10)], C["rope"], cap0=False, cap1=False)
    for s in (-1, 1):
        km.box(timber, T(s * 1.6, 4.4, 0) @ Matrix.Rotation(math.radians(s * -12), 4, "Z"), (2.2, .4, .4), C["woodDark"])
        loft(cloth, [ring(T(s * 2.5, 0, 0), 4.2, .32, 8), ring(T(s * 2.5, 0, 0), 4.8, .32, 8)], straw)
    km.box(timber, T(0, 6.6, 0), (1.1, 1.3, 1.0), C["woodLight"])
    km.box(cloth, T(0, 6.4, .22), (.6, .14, .7), C["rope"])
    for r_, col in ((.62, rgb(236, 226, 200)), (.45, rgb(176, 40, 32)), (.28, rgb(236, 226, 200)), (.12, rgb(176, 40, 32))):
        km.cyl(glass, T(0, 3.9, 1.12 + (.62 - r_) * .03) @ Rx(math.pi / 2), r_, .04, col, sides=16)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def kunai_target():
    """A round wooden target board on a tripod, painted rings; two kunai already in it."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    cx, cy = 0, 3.6
    km.cyl(timber, T(cx, cy, 0) @ Rx(math.pi / 2), 1.8, .5, lambda q, k: km.wood(q, None, C["woodLight"]), sides=20)
    for r_, col in ((1.55, rgb(236, 226, 200)), (1.2, rgb(176, 40, 32)), (.85, rgb(236, 226, 200)), (.5, rgb(176, 40, 32)),
                    (.2, rgb(36, 34, 38))):
        km.cyl(glass, T(cx, cy, .52 + (1.6 - r_) * .006) @ Rx(math.pi / 2), r_, .03, col, sides=20)  # on the front face (z .5)
    for a in (-30, 30, 180):
        rad = math.radians(a)
        km.box(timber, T(math.sin(rad) * 1.2, 1.7, -math.cos(rad) * .9 - .4) @ Matrix.Rotation(math.radians(-14 if a != 180 else 14), 4, "X"),
               (.3, 3.8, .3), C["woodDark"])
    for (x, y) in ((.4, 3.9), (-.7, 3.2)):
        km.box(metal, T(x, y, .85) @ Rx(math.radians(8)), (.12, .12, .8), C["iron"])
        km.cyl(metal, T(x, y, 1.25) @ Rx(math.pi / 2), .14, .1, C["iron"], sides=8)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def stump_target():
    """A tree stump with a painted target on its face (the low kunai target)."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    loft(timber, [ring(T(0, 0, 0), 0, 1.6, 12), ring(T(0, 0, 0), .6, 1.35, 12), ring(T(0, 0, 0), 2.6, 1.25, 12)],
         lambda q, k: km.jitter(C["bark"], q, .12, 2.0), cap1=True)
    km.cyl(timber, T(0, 2.6, 0), 1.15, .06, C["woodLight"], sides=12)
    for r_, col in ((1.0, rgb(176, 40, 32)), (.65, rgb(236, 226, 200)), (.3, rgb(176, 40, 32))):
        km.cyl(glass, T(0, 2.67 + (1 - r_) * .01, 0), r_, .02, col, sides=16)
    return KH.done(walls, timber, glass, tiles, cloth, metal)



def kunai_board():
    """The board alone, for the kunai targets of the market lane (Server/Hub's Target<i>: their
    own post stays): a round wooden board, its rings, a rim, two kunai in it. Centre at the
    origin, the face toward +z (the throw mark)."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    km.cyl(timber, T(0, 0, -.25) @ Rx(math.pi / 2), 1.8, .5, lambda q, k: km.wood(q, None, C["woodLight"]), sides=20)
    loft(timber, [ring(T(0, 0, 0) @ Rx(math.pi / 2), -.3, 1.86, 20), ring(T(0, 0, 0) @ Rx(math.pi / 2), .3, 1.86, 20)], C["woodDark"], cap0=False, cap1=False)
    for r_, col in ((1.55, rgb(236, 226, 200)), (1.2, rgb(176, 40, 32)), (.85, rgb(236, 226, 200)), (.5, rgb(176, 40, 32)),
                    (.2, rgb(36, 34, 38))):
        km.cyl(glass, T(0, 0, .27 + (1.6 - r_) * .006) @ Rx(math.pi / 2), r_, .03, col, sides=20)
    for (x, y) in ((.4, .3), (-.7, -.4)):
        km.box(metal, T(x, y, .6) @ Rx(math.radians(8)), (.12, .12, .8), C["iron"])
        km.cyl(metal, T(x, y, 1.0) @ Rx(math.pi / 2), .14, .1, C["iron"], sides=8)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


# ------------------------------------------------------------------ the market's props (22/11)
# Server/Hub draws a market stall and a barrel of the plan (Layout.Props "stall", "barrel") as a
# plain block (Prop_stall 8 x 6 x 5, Prop_barrel 3 x 3.6): in the street they read as brown
# crates the size of a car. Client/KonohaLifeFX puts these over them.
def market_stall():
    """A Part I street stall, 8 wide and 5 deep, open on both long sides: four posts, a striped
    cloth awning with a short valance, a counter of planks down the middle with goods on it
    (crates, round fruit, bowls, rolled cloth), two paper lanterns under the eave."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    from nd_mesh import ellipsoid
    for x in (-3.7, 3.7):
        for z in (-2.2, 2.2):
            km.box(timber, T(x, 2.75, z), (.32, 5.5, .32), C["woodDark"])
    # the counter: planks on trestles
    km.box(timber, T(0, 2.6, 0), (7.4, .25, 2.2), lambda q, k=None: km.jitter(C["woodLight"], q, .1, 2))
    for x in (-3, 0, 3):
        km.box(timber, T(x, 1.25, 0), (.25, 2.5, 1.8), C["wood"])
    km.box(timber, T(0, .9, 0), (7.2, .2, 1.6), C["wood"])
    # the awning: a low-pitched cloth roof in stripes, a valance on both long sides
    stripes = (rgb(196, 58, 42), rgb(236, 226, 200))
    for i in range(8):
        x0 = -4.2 + i * 1.05
        col = stripes[i % 2]
        for side in (-1, 1):
            a = Vector((x0, 5.4, 0)); b = Vector((x0 + 1.05, 5.4, 0))
            c = Vector((x0 + 1.05, 4.9, side * 2.9)); d = Vector((x0, 4.9, side * 2.9))
            v = [Vector((x0, 4.9, side * 2.9)), Vector((x0 + 1.05, 4.9, side * 2.9))]
            low = [q - Vector((0, .55, 0)) for q in v]
            # both faces (Roblox draws one side of a triangle): seen from the street and from under
            for rows in ([[a, b], [d, c]], [[d, c], [a, b]], [v, low], [low, v]):
                loft(cloth, rows, col, cap0=False, cap1=False, closed=False)
    km.box(timber, T(0, 5.45, 0), (8.6, .2, .2), C["woodDark"])          # the ridge pole
    # the goods
    rng = random.Random(22)
    for x in (-2.8, -1.4, 1.2, 2.7):
        km.box(timber, T(x, 3.05, rng.uniform(-.5, .5)), (1.1, .7, .9), C["woodLight"])
        for k in range(5):
            col = rng.choice((rgb(210, 70, 50), rgb(230, 170, 60), rgb(120, 160, 70), rgb(236, 200, 120)))
            ellipsoid(cloth, Vector((x + rng.uniform(-.35, .35), 3.55, rng.uniform(-.3, .3))), (.22, .2, .22), col, seg=8, rings=5)
    for x in (-.1, .35):
        km.cyl(glass, T(x, 2.75, .6), .35, .22, rgb(236, 232, 222), sides=10)
    km.cyl(cloth, T(.2, 2.95, -.6) @ Rx(math.pi / 2) @ Ry(0), .25, 1.4, rgb(70, 100, 160), sides=8)
    for x in (-3.4, 3.4):
        KH.lantern(cloth, timber, T(x, 4.1, 2.4), w=.9, h=1.2)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


def barrel():
    """A wooden barrel, 3 across and 3.6 tall, three iron hoops, its lid."""
    km = K(); C = km.C
    walls, timber, glass, tiles, cloth, metal = P()
    rows = []
    for k in range(7):
        y = k / 6 * 3.6
        r = 1.3 + .22 * math.sin(k / 6 * math.pi)
        rows.append(ring(T(0, 0, 0), y, r, 14))
    loft(timber, rows, lambda q, k: km.jitter(C["woodLight"], q, .14, 3.0))
    for y in (.45, 1.8, 3.1):
        r = 1.3 + .22 * math.sin(y / 3.6 * math.pi) + .05
        loft(metal, [ring(T(0, 0, 0), y, r, 14), ring(T(0, 0, 0), y + .18, r, 14)], C["iron"], cap0=False, cap1=False)
    km.cyl(timber, T(0, 3.6, 0), 1.25, .08, C["wood"], sides=14)
    return KH.done(walls, timber, glass, tiles, cloth, metal)


# (training_dummy and kunai_target go into konoha_models' TrainingProps)
# Placed by the client (Client/KonohaLifeFX), not tagged by Server/Hub: written apart
# (Client/PropMeshData) so HubMeshData keeps only what HubDress names.
PROPS_OUT = ["kunai_board", "market_stall", "barrel"]

MODELS = {
    "hokage_residence": hokage_residence, "hospital": hospital, "academy_annex": academy_annex,
    "exam_hall": exam_hall, "exam_hall_wing": exam_hall_wing, "ichiraku": ichiraku, "great_gate": great_gate,
    "hyuga_hall": hyuga_hall, "hyuga_gate": hyuga_gate, "uchiha_police": uchiha_police, "naka_shrine": naka_shrine,
    "torii": torii, "pier": pier, "water_tower": water_tower, "market_hall": market_hall,
    "memorial_stone": memorial_stone, "academy_tree": academy_tree, "final_arena": final_arena,
    "training_dummy": training_dummy, "kunai_target": kunai_target, "stump_target": stump_target, "kunai_board": kunai_board, "market_stall": market_stall, "barrel": barrel,
}
