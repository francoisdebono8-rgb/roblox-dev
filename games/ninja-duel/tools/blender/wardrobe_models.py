"""The wardrobe, wave 2 (19/11, vague-2 § 2 ANIMATEUR 2): many more outfit pieces, in the same
frame and format as outfit_models.py (DEC-040), which merges these into its MODELS.

Masks, capes and back items are outfit pieces like the others (19/11, OUTILLEUR/DEV): worn
on the Head or the torso, so the icon tool renders them with the rest.

Part I references (looked at for the shapes, nothing copied): the genin's zipped track
jackets, high collars and mesh undershirts; the chunin's flak vest; the Hyuga's loose robes and
hakama-like trousers; the ANBU's animal masks (here a fox and a cat, painted with plain
stripes); the cloth face mask; the travelling cloak with its hood; the big scroll and the
folded fuma shuriken worn on the back; sandals, tabi, high boots, leg weights. The forehead
protector is a cloth band and a metal plate with plain engraved lines: never a village symbol.

Colour: the pieces show in SmoothPlastic (no texture), so every default colour below is a
clear, mid-value colour that reads at 20 studs; a slot's colour multiplies the vertex shading.

Shapes are made for the standard R15 parts (outfit_models.REF; "Head" 1.2 x 1.2 x 1.2 at the
head's centre, the brow 0.27 above it, the face at -Z) and scale with each part at run time.
"""
import math

from mathutils import Vector, noise

from nd_mesh import loft, tube


def O():
    import outfit_models  # lazy: outfit_models imports this module at its end
    return outfit_models


HEAD = (1.2, 1.2, 1.2)
BROW = .46  # (23/11, François: « les bandanas tombent sur les yeux ») on the forehead: the eyes are at y .07 to .25


def head_ring(pc, y, h, r=(.64, .66), bulge=.02, col=None, n=24, z_off=0.0):
    """A cloth band round the head at height y (its centre), h tall."""
    o = O()
    rows = []
    for dy, g in ((h / 2, 0.0), (h * .2, bulge), (-h * .2, bulge), (-h / 2, 0.0)):
        rows.append([Vector((math.cos(t) * (r[0] + g), y + dy, math.sin(t) * (r[1] + g) + z_off))
                     for t in [i / n * math.tau for i in range(n)]])
    loft(pc, rows, col or o.shade(.92, .05), cap0=False, cap1=False)


def ribbon(pc, pts, width, side=Vector((1, 0, 0)), col=None, thick=.03):
    """A flat strip along pts (a tail, a strap), `width` across `side`, two-sided."""
    o = O()
    a = [Vector(p) - side * width / 2 for p in pts]
    b = [Vector(p) + side * width / 2 for p in pts]
    rows = [[p, q] for p, q in zip(a, b)]
    loft(pc, rows, col or o.shade(.9, .06), cap0=False, cap1=False, closed=False)
    back = [[q + Vector((0, 0, thick)), p + Vector((0, 0, thick))] for p, q in zip(a, b)]
    loft(pc, back, col or o.shade(.8, .04), cap0=False, cap1=False, closed=False)


def dome(pc, y0, r=(.66, .68), top=.72, rings=6, n=24, front_open=0.0, col=None, z_off=0.0, fat=1.0):
    """A cap over the head from y0 up (a bandana, a hood): front_open (radians) leaves the face.
    fat < 1 keeps the sides full higher up (hair over the boxy R15 head: the skull never shows)."""
    o = O()
    rows = []
    for k in range(rings):
        u = k / (rings - 1)
        a = math.cos(u * math.pi / 2 * .92) ** fat
        y = y0 + (top - y0) * math.sin(u * math.pi / 2)
        ring = []
        for i in range(n):
            t = -math.pi / 2 + front_open / 2 + (2 * math.pi - front_open) * i / (n - 1) if front_open else i / n * math.tau
            ring.append(Vector((math.cos(t) * r[0] * a, y, math.sin(t) * r[1] * a + z_off)))
        rows.append(ring)
    loft(pc, rows, col or o.shade(.9, .06), cap0=False, cap1=True, closed=not front_open)


def plate_front(pc, y, w, h, z=-.67, curve=.12, col=None, n=10):
    """A curved metal plate on the brow (or a mask on the face), facing -Z."""
    o = O()
    rows = []
    for dz in (0.0, -.04):
        for yy in (y + h / 2, y - h / 2):
            rows.append([Vector((-w / 2 + w * i / (n - 1), yy, z + dz + curve * (2 * i / (n - 1) - 1) ** 2)) for i in range(n)])
    front = [rows[2], rows[3]]
    back = [rows[1], rows[0]]
    g = col or o.shade(.95, .03)
    loft(pc, [list(reversed(front[0])), list(reversed(front[1]))], g, cap0=False, cap1=False, closed=False)
    loft(pc, back, g, cap0=False, cap1=False, closed=False)
    loft(pc, [rows[0], rows[2]], g, cap0=False, cap1=False, closed=False)
    loft(pc, [rows[3], rows[1]], g, cap0=False, cap1=False, closed=False)


def engrave(pc, y, w, z=-.73, lines=2):
    """Plain engraved lines on a plate (no symbol)."""
    o = O()
    for k in range(lines):
        yy = y + (k - (lines - 1) / 2) * .07
        o.box(pc, (0, yy, z), (w * .24, .012, .01), lambda p, kk: (.55, .55, .58))


# ------------------------------------------------------------------ headbands (Head unless said)
def _protector(o, part="Head", y=BROW, tails=.55, plate=True, scratched=False, band_h=.17, plate_w=.66):
    band = o.add(part, "Band")
    head_ring(band, y, band_h)
    if plate:
        pl = o.add(part, "Plate", mat="Metal")
        plate_front(pl, y, plate_w, band_h * 1.25)
        mark = o.add(part, "Plate", mat="Metal", name="Engraving")
        engrave(mark, y, plate_w)
        # (20/11, references) the plate is held by a rivet at each corner
        for sx in (-1, 1):
            for sy in (-1, 1):
                xx = sx * plate_w * .43
                O().box(mark, (xx, y + sy * band_h * .42, -.715 + .12 * (xx / (plate_w / 2)) ** 2),
                        (.022, .022, .015), lambda p, k: (.62, .62, .66))
        if scratched:
            O().box(mark, (0, y, -.745), (plate_w * .42, .014, .01), lambda p, k: (.3, .3, .32))
    knot = o.add(part, "Band", name="Knot")
    O().box(knot, (0, y, .68), (.07, .07, .05), O().shade(.82, .04))
    if tails:
        for sx in (-1, 1):
            pts = [Vector((sx * (.04 + .1 * u), y - .02 - tails * u, .7 + .12 * u + .05 * math.sin(u * 3))) for u in [k / 6 for k in range(7)]]
            ribbon(band, pts, .11)
    return band


def item_headband_classic():
    o = O().Out()
    _protector(o)
    return o.items


def item_headband_long():
    o = O().Out()
    _protector(o, tails=1.5)
    return o.items


def item_headband_scratched():
    o = O().Out()
    _protector(o, scratched=True, tails=.7)
    return o.items


def item_headband_hachimaki():
    o = O().Out()
    band = o.add("Head", "Band")
    head_ring(band, BROW, .22, bulge=.03)
    for sx in (-1, 1):
        pts = [Vector((sx * (.05 + .2 * u), BROW - .05 - .55 * u, .72 + .1 * u)) for u in [k / 5 for k in range(6)]]
        ribbon(band, pts, .14)
    O().box(band, (0, BROW, .7), (.09, .09, .06), O().shade(.82, .04))
    return o.items


def item_headband_bandana():
    o = O().Out()
    cap = o.add("Head", "Band", name="Bandana")
    dome(cap, BROW - .05, top=.7, rings=5)
    pl = o.add("Head", "Plate", mat="Metal")
    plate_front(pl, BROW, .5, .2)
    engrave(o.add("Head", "Plate", mat="Metal", name="Engraving"), BROW, .5)
    knot = o.add("Head", "Band", name="Knot")
    O().box(knot, (0, BROW - .08, .7), (.09, .08, .06), O().shade(.82, .04))
    pts = [Vector((0, BROW - .1 - .5 * u, .72 + .08 * u)) for u in [k / 5 for k in range(6)]]
    ribbon(knot, pts, .22)
    return o.items


def item_headband_bow():
    o = O().Out()
    _protector(o, tails=0, band_h=.15, plate_w=.42)
    bow = o.add("Head", "Band", name="Bow")
    for sx in (-1, 1):  # two loops on top, toward the back
        loop = [Vector((sx * (.08 + .22 * math.sin(u * math.pi)), .62 + .14 * math.sin(u * math.pi * 2) * .5, .1 + .18 * math.sin(u * math.pi))) for u in [k / 8 for k in range(9)]]
        tube(bow, loop, .05, O().shade(.92, .04), sides=8)
    return o.items


def item_headband_neck():
    o = O().Out()
    S = O().size("UpperTorso")
    y = S.y / 2 + .1
    band = o.add("UpperTorso", "Band")
    head_ring(band, y, .2, r=(.6, .56), bulge=.03)
    pl = o.add("UpperTorso", "Plate", mat="Metal")
    plate_front(pl, y, .46, .22, z=-.6, curve=.1)
    engrave(o.add("UpperTorso", "Plate", mat="Metal", name="Engraving"), y, .46, z=-.66)
    return o.items


def item_headband_waist():
    o = O().Out()
    band = o.add("LowerTorso", "Band")
    O().ribbed(band, "LowerTorso", .05, .75, pad=.13, ribs=1, depth=.02, rings_per=4)
    pl = o.add("LowerTorso", "Plate", mat="Metal")
    plate_front(pl, -.02, .5, .22, z=-.6, curve=.08)
    engrave(o.add("LowerTorso", "Plate", mat="Metal", name="Engraving"), -.02, .5, z=-.66)
    for sx in (-1, 1):  # tails at the side
        pts = [Vector((.95 + .05 * u, -.1 - .7 * u, sx * .08 + .05 * u)) for u in [k / 5 for k in range(6)]]
        ribbon(band, pts, .12, side=Vector((0, 0, 1)))
    return o.items


# ------------------------------------------------------------------ masks (Head)
def _animal_mask(ears="fox"):
    o = O().Out()
    m = o.add("Head", "Mask", mat="SmoothPlastic")
    rows = []
    n = 14
    for k, (y, wid, dz) in enumerate(((.5, .44, .0), (.25, .56, -.02), (0.0, .58, -.04), (-.25, .5, -.08), (-.48, .3, -.16))):
        rows.append([Vector((wid * (2 * i / (n - 1) - 1), y, -.68 + dz + .25 * (2 * i / (n - 1) - 1) ** 2 - (.12 if k == 3 and abs(i - (n - 1) / 2) < 2 else 0))) for i in range(n)])
    loft(m, [list(reversed(r)) for r in rows], O().shade(.97, .02), cap0=False, cap1=False, closed=False)
    loft(m, [[p + Vector((0, 0, .04)) for p in r] for r in reversed(rows)], O().shade(.8, .02), cap0=False, cap1=False, closed=False)
    # the snout (fox: long; cat: short) and the ears
    snout = .2 if ears == "fox" else .08
    tube(m, [Vector((0, -.12, -.78)), Vector((0, -.2, -.78 - snout))], lambda k: .12 * (1 - .5 * k), O().shade(.95, .02), sides=8, tip1=True)
    for sx in (-1, 1):
        h = .34 if ears == "fox" else .22
        tube(m, [Vector((sx * .32, .42, -.62)), Vector((sx * (.38 if ears == "fox" else .34), .42 + h, -.6))], lambda k: .1 * (1 - k * .9), O().shade(.95, .02), sides=6, tip1=True)
    paint = o.add("Head", "Paint", mat="SmoothPlastic")
    for sx in (-1, 1):  # eye slits, cheek stripes, brow marks: plain strokes
        O().box(paint, (sx * .2, .14, -.76), (.1, .03, .02), lambda p, k: (.15, .15, .17))
        for j in range(2):
            O().box(paint, (sx * (.36 + .02 * j), -.06 - .1 * j, -.72), (.09, .018, .02), lambda p, k: (1, 1, 1))
        O().box(paint, (sx * .16, .36, -.74), (.07, .02, .02), lambda p, k: (1, 1, 1))
    strap = o.add("Head", "Strap")
    head_ring(strap, .12, .07, r=(.63, .65), bulge=.01)
    return o.items


def item_mask_fox():
    return _animal_mask("fox")


def item_mask_cat():
    return _animal_mask("cat")


def item_mask_cloth():
    o = O().Out()
    pc = o.add("Head", "Cloth")
    rows = []
    n = 24
    # (20/11, references) up to just under the eyes, down over the neck (Kakashi's)
    for y, rr, dz in ((.08, .63, 0.0), (-.1, .63, -.02), (-.36, .61, -.01), (-.62, .58, 0.0), (-.9, .58, .02)):
        rows.append([Vector((math.cos(t) * rr, y, math.sin(t) * rr * 1.02 + (dz if math.sin(t) < 0 else 0))) for t in [i / n * math.tau for i in range(n)]])
    # the nose's ridge pushes the front out
    for p in rows[0] + rows[1]:
        if p.z < -.5 and abs(p.x) < .2:
            p.z -= .06
    loft(pc, rows, O().shade(.9, .07, ao_y=(-.9, .2)), cap0=False, cap1=False)
    return o.items


def item_mask_respirator():
    o = O().Out()
    m = o.add("Head", "Metal", mat="Metal")
    plate_front(m, -.32, .5, .34, z=-.68, curve=.14)
    for sx in (-1, 1):
        tube(m, [Vector((sx * .18, -.36, -.76)), Vector((sx * .2, -.38, -.86))], .08, O().shade(.85, .04), sides=8)
    grill = o.add("Head", "Strap")
    for k in range(3):
        O().box(grill, (0, -.25 - k * .08, -.76), (.14, .012, .02), lambda p, kk: (.3, .3, .32))
    head_ring(grill, -.2, .07, r=(.62, .64), bulge=.01)
    return o.items


# ------------------------------------------------------------------ capes and cloaks (torso)
def _mantle(o, slot, pad=.22):
    pc = o.add("UpperTorso", slot, name="Mantle")
    O().shell(pc, "UpperTorso", -.04, .3, pad=pad, flare1=.22, folds=.03, rings=5)
    return pc


def item_cape_short():
    o = O().Out()
    _mantle(o, "Cape")
    pc = o.add("UpperTorso", "Cape", name="Back")
    O().flap(pc, "UpperTorso", -1.05, 1.05, .15, 1.9, 1, pad=.2, flare=.25, folds=.04, seed=2)
    trim = o.add("UpperTorso", "Trim", name="Clasp")
    O().box(trim, (0, .62, -.68), (.1, .1, .05), O().shade(.95, .03))
    return o.items


def item_cape_long():
    o = O().Out()
    _mantle(o, "Cape", pad=.24)
    pc = o.add("UpperTorso", "Cape", name="Back")
    # (20/11) shorter and hanging further back: the running legs swing behind the body
    O().flap(pc, "UpperTorso", -1.1, 1.1, .1, 2.7, 1, pad=.24, flare=.5, folds=.05, seed=5)
    trim = o.add("UpperTorso", "Trim", name="Hem")
    O().flap(trim, "UpperTorso", -1.1, 1.1, 1.74, .22, 1, pad=.25 + .5 * .5 * .92, flare=.04, folds=.05, seed=5)
    return o.items


def item_cloak_hooded():
    o = O().Out()
    _mantle(o, "Cape", pad=.26)
    pc = o.add("UpperTorso", "Cape", name="Back")
    O().flap(pc, "UpperTorso", -1.1, 1.1, .1, 2.6, 1, pad=.26, flare=.28, folds=.05, seed=7)
    for x0, x1, name in ((-1.1, -.5, "FrontL"), (.5, 1.1, "FrontR")):
        f = o.add("UpperTorso", "Cape", name=name)
        O().flap(f, "UpperTorso", x0, x1, .1, 2.4, -1, pad=.26, flare=.12, folds=.04, seed=x0)
    hood = o.add("Head", "Cape", name="Hood")
    # (20/11, OUTILLEUR: the headband's knot and the mask came through it) roomier, further back
    dome(hood, -.45, r=(.8, .84), top=.88, rings=7, front_open=2.2, z_off=.12)
    return o.items


def item_scarf():
    o = O().Out()
    S = O().size("UpperTorso")
    pc = o.add("UpperTorso", "Scarf")
    head_ring(pc, S.y / 2 + .08, .26, r=(.66, .62), bulge=.06)
    head_ring(pc, S.y / 2 - .1, .18, r=(.7, .66), bulge=.05)
    for sx, ln in ((1, 1.7), (-1, 1.2)):
        pts = [Vector((sx * (.28 + .06 * u), S.y / 2 - .15 - ln * u, .62 + .35 * u + .06 * math.sin(u * 5))) for u in [k / 8 for k in range(9)]]
        ribbon(pc, pts, .32)
    return o.items


# ------------------------------------------------------------------ worn on the back (torso)
def item_back_scroll():
    o = O().Out()
    pc = o.add("UpperTorso", "Paper", name="Scroll")
    tube(pc, [Vector((-1.15, -.55, .8)), Vector((1.15, -.55, .8))], .3, O().shade(.95, .03), sides=14)
    wood = o.add("UpperTorso", "Wood", name="Rods", mat="Wood")
    for sx in (-1, 1):
        tube(wood, [Vector((sx * 1.15, -.55, .8)), Vector((sx * 1.32, -.55, .8))], .2, O().shade(.85, .04), sides=10)
    band = o.add("UpperTorso", "Strap")
    tube(band, [Vector((-.2, -.55, .8)), Vector((.2, -.55, .8))], .31, O().shade(.9, .03), sides=14, cap0=False, cap1=False)
    S = O().size("UpperTorso")
    a, b = (S.x / 2 + .1) / O().K, (S.z / 2 + .1) / O().K
    rows = []
    for w in (-.08, .08):  # the strap across the chest, shoulder to hip
        rows.append([Vector((a * math.copysign(abs(math.cos(t)) ** .125, math.cos(t)), -a * math.copysign(abs(math.cos(t)) ** .125, math.cos(t)) * .55 + w,
                             b * math.copysign(abs(math.sin(t)) ** .125, math.sin(t)))) for t in [i / 28 * math.tau for i in range(28)]])
    loft(band, rows, O().shade(.9, .05), cap0=False, cap1=False)
    return o.items


def item_back_pouch():
    o = O().Out()
    S = O().size("LowerTorso")
    pc = o.add("LowerTorso", "Leather", name="Pouch")
    O().box(pc, (0, -.05, S.z / 2 + .26), (.42, .22, .16), O().shade(.9, .05))
    O().box(pc, (0, .1, S.z / 2 + .3), (.44, .1, .18), O().shade(.8, .04))
    for sx in (-1, 1):
        O().box(pc, (sx * .75, -.02, S.z / 2 + .14), (.14, .17, .1), O().shade(.88, .05))
    buckle = o.add("LowerTorso", "Metal", mat="Metal")
    O().box(buckle, (0, .02, S.z / 2 + .49), (.06, .05, .02), O().shade(.95, .02))
    belt = o.add("LowerTorso", "Strap")
    O().ribbed(belt, "LowerTorso", .2, .7, pad=.12, ribs=1, depth=.015, rings_per=3)
    return o.items


def item_back_sword():
    o = O().Out()
    a, b = Vector((-.85, -.75, .72)), Vector((.75, .95, .72))
    d = (b - a).normalized()
    sheath = o.add("UpperTorso", "Sheath", name="Sheath")
    tube(sheath, [a, a.lerp(b, .5), b], .1, O().shade(.9, .04), sides=8, shape=lambda t, k: (1.0, .45))
    guard = o.add("UpperTorso", "Metal", mat="Metal")
    g = b + d * .06
    tube(guard, [g - d * .03, g + d * .03], .2, O().shade(.95, .02), sides=10)
    hilt = o.add("UpperTorso", "Grip", name="Hilt")
    tube(hilt, [g + d * .04, g + d * .8], .075, lambda p, k: (.85 + .15 * (int(k * 10) % 2),) * 3, sides=8)
    strap = o.add("UpperTorso", "Strap")
    for t in (.3, .7):
        c = a.lerp(b, t)
        tube(strap, [c + Vector((-.15, .12, -.1)), c + Vector((.15, -.12, -.1))], .03, O().shade(.85, .03), sides=6)
    return o.items


def item_back_fuma():
    o = O().Out()
    pc = o.add("UpperTorso", "Metal", mat="Metal", name="Blades")
    c = Vector((0, -.05, .78))
    for k in range(4):
        a = k * math.pi / 2 + .3
        tip = c + Vector((math.cos(a) * 1.05, math.sin(a) * 1.05, 0))
        side = Vector((-math.sin(a), math.cos(a), 0)) * .22
        rows = [[c + side * .4, c - side * .4], [c.lerp(tip, .45) + side, c.lerp(tip, .45) - side * .2], [tip, tip]]
        loft(pc, rows, O().shade(.95, .03), cap0=False, cap1=False, closed=False)
        loft(pc, [[p + Vector((0, 0, .04)) for p in reversed(r)] for r in rows], O().shade(.8, .03), cap0=False, cap1=False, closed=False)
    hub = o.add("UpperTorso", "Grip", name="Hub")
    tube(hub, [c + Vector((0, 0, -.06)), c + Vector((0, 0, .1))], .2, O().shade(.85, .04), sides=12)
    strap = o.add("UpperTorso", "Strap")
    O().ribbed(strap, "UpperTorso", .45, .58, pad=.12, ribs=1, depth=.01, rings_per=3)
    return o.items


# ------------------------------------------------------------------ tops
def item_track_jacket():
    o = O().Out()
    up = o.add("UpperTorso", "Cloth")
    O().shell(up, "UpperTorso", 0, 1, pad=.09, flare1=.03, folds=.03, hem=False)
    O().zipper(o, "UpperTorso", "Trim", 0, 1, pad=.09)
    col = o.add("UpperTorso", "Trim", name="Collar")
    O().collar(col, "UpperTorso", h=.24, flare=.07, thick=.05, neck=(.63, .59))
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", -.15, .9, pad=.1, hem=True, folds=.02)
    o.both("UpperArm", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.1, folds=.03, hem=False))
    o.both("UpperArm", "Trim", lambda pc, part: O().ribbed(pc, part, .1, .2, pad=.12, ribs=1, depth=.01, rings_per=3))
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .9, pad=.1, flare1=.03, folds=.03))
    return o.items


def item_mesh_shirt():
    o = O().Out()
    up = o.add("UpperTorso", "Cloth")
    # a fishnet: the knit as light/dark diamonds in the shading
    def net(p, k):
        g = .72 + .28 * (abs(math.sin(p.x * 22 + p.y * 22)) * abs(math.sin(p.x * 22 - p.y * 22))) ** .5
        return (g, g, g)
    O().shell(up, "UpperTorso", 0, 1, pad=.03, folds=.004, hem=False, rings=14, col=net)
    o.both("UpperArm", "Cloth", lambda pc, part: O().shell(pc, part, -.04, .98, pad=.03, folds=.004, hem=False, rings=10, col=net))
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .6, pad=.03, folds=.004, hem=True, rings=8, col=net))
    col = o.add("UpperTorso", "Cloth", name="Neck")
    O().collar(col, "UpperTorso", h=.18, flare=.02, thick=.03, neck=(.62, .58))
    return o.items


def item_haori():
    o = O().Out()
    under = o.add("UpperTorso", "Under")
    O().shell(under, "UpperTorso", 0, 1, pad=.05, folds=.015, hem=False)
    S = O().size("UpperTorso")
    coat = o.add("UpperTorso", "Cloth", name="Coat")
    a, b = (S.x / 2 + .2) / O().K, (S.z / 2 + .22) / O().K
    rows = []
    for k in range(8):
        y = S.y / 2 - k / 7 * S.y * 1.02
        rows.append([Vector(((a) * math.copysign(abs(math.cos(t)) ** .125, math.cos(t)), y, (b) * math.copysign(abs(math.sin(t)) ** .125, math.sin(t))))
                     for t in [-math.pi / 2 + .45 + (2 * math.pi - .9) * i / (O().SEG - 7) for i in range(O().SEG - 6)]])
    loft(coat, rows, O().shade(.93, .06), cap0=False, cap1=False, closed=False)
    O().thigh_tails(o, "Cloth", .95, y_top=-.15, pad=.18, flare=.1)
    tie = o.add("UpperTorso", "Trim", name="Tie")
    for sx in (-1, 1):
        tube(tie, [Vector((sx * .32, .05, -.68)), Vector((sx * .05, -.05, -.7)), Vector((sx * .1, -.4, -.72))], .035, O().shade(.95, .03), sides=6)
    o.both("UpperArm", "Cloth", lambda pc, part: O().shell(pc, part, -.08, .9, pad=.2, flare1=.18, folds=.04))
    lo = o.add("LowerTorso", "Under")
    O().shell(lo, "LowerTorso", -.15, .9, pad=.07, hem=False)
    return o.items


def item_chunin_vest():
    o = O().Out()
    up = o.add("UpperTorso", "Cloth")
    O().shell(up, "UpperTorso", 0, 1, pad=.06, folds=.02, hem=False)
    O().flak_vest(o, "Vest")
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", -.15, .9, pad=.08, hem=False)
    o.both("UpperArm", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.07, folds=.025, hem=False))
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .9, pad=.07, folds=.025))
    return o.items


def item_gi():
    o = O().Out()
    O().tunic_body(o, "Cloth", lower_h=.9, sleeve=.9, seed=3)
    belt = o.add("LowerTorso", "Belt")
    O().ribbed(belt, "LowerTorso", .05, .65, pad=.14, ribs=1, depth=.02, rings_per=4)
    for sx in (-1, 1):
        ribbon(belt, [Vector((sx * .3 + .5, -.05 - .45 * u, -.7 - .04 * u)) for u in [k / 4 for k in range(5)]], .14)
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.04, .35, pad=.16, flare0=.12, flare1=.14, folds=.04))
    return o.items


def item_turtleneck():
    o = O().Out()
    up = o.add("UpperTorso", "Cloth")
    O().shell(up, "UpperTorso", 0, 1, pad=.05, folds=.015, hem=False)
    col = o.add("UpperTorso", "Cloth", name="Neck")
    O().collar(col, "UpperTorso", h=.3, flare=.03, thick=.07, neck=(.64, .6))
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", -.15, .8, pad=.07, hem=True)
    o.both("UpperArm", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.05, folds=.02, hem=False))
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .95, pad=.05, folds=.02))
    return o.items


def item_sash_top():
    o = O().Out()
    up = o.add("UpperTorso", "Cloth")
    O().shell(up, "UpperTorso", .02, 1, pad=.06, folds=.02, hem=False, scale_x=.99)
    S = O().size("UpperTorso")
    a, b = (S.x / 2 + .12) / O().K, (S.z / 2 + .12) / O().K
    sash = o.add("UpperTorso", "Sash")
    rows = []
    for w in (-.14, .14):
        rows.append([Vector((a * math.copysign(abs(math.cos(t)) ** .125, math.cos(t)), -a * math.copysign(abs(math.cos(t)) ** .125, math.cos(t)) * .6 + w,
                             b * math.copysign(abs(math.sin(t)) ** .125, math.sin(t)))) for t in [i / 28 * math.tau for i in range(28)]])
    loft(sash, rows, O().shade(.9, .06), cap0=False, cap1=False)
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", -.1, .5, pad=.07, hem=False)
    belt = o.add("LowerTorso", "Sash", name="Obi")
    O().ribbed(belt, "LowerTorso", .3, .8, pad=.11, ribs=1, depth=.02, rings_per=4)
    return o.items


# ------------------------------------------------------------------ bottoms
def item_hakama():
    o = O().Out()
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", -.1, 1.05, pad=.12, hem=False)
    o.both("UpperLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.22, flare1=.2, folds=.05, hem=False))
    o.both("LowerLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .78, pad=.3, flare0=.2, flare1=.36, folds=.06))
    belt = o.add("LowerTorso", "Belt")
    O().ribbed(belt, "LowerTorso", .0, .5, pad=.15, ribs=1, depth=.02, rings_per=4)
    return o.items


def item_cargo_pants():
    o = O().Out()
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", .2, 1.05, pad=.08, hem=False)
    o.both("UpperLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.1, flare1=.04, folds=.035, hem=False))
    o.both("LowerLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .6, pad=.11, flare1=.04, folds=.035, hem=False))
    o.both("LowerLeg", "Tie", lambda pc, part: O().ribbed(pc, part, .55, .9, pad=.05, ribs=4, depth=.02, spiral=1.0))
    def pocket(pc, part):
        S = O().size(part)
        O().box(pc, (S.x / 2 + .07, -.05, 0), (.06, .22, .2), O().shade(.85, .05))
        O().box(pc, (S.x / 2 + .1, .15, 0), (.07, .05, .21), O().shade(.95, .03))
    o.both("UpperLeg", "Pocket", pocket)
    return o.items


def item_leggings():
    o = O().Out()
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", .2, 1.05, pad=.04, hem=False, folds=.005)
    o.both("UpperLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.04, folds=.006, hem=False))
    o.both("LowerLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .9, pad=.04, folds=.006, hem=True))
    # the leg weights: padded blocks strapped round the shin
    def weights(pc, part):
        O().ribbed(pc, part, .55, .82, pad=.24, ribs=3, depth=.05, rings_per=3)
    o.both("LowerLeg", "Weights", weights)
    return o.items


def item_wrap_pants():
    o = O().Out()
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", .2, 1.05, pad=.09, hem=False)
    o.both("UpperLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.14, flare1=.1, folds=.045, hem=False))
    o.both("LowerLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .3, pad=.16, flare0=.1, flare1=.02, folds=.045))
    o.both("LowerLeg", "Wrap", lambda pc, part: O().ribbed(pc, part, .25, .92, pad=.03, ribs=9, depth=.015, spiral=1.0))
    return o.items


def item_wrap_skirt():
    o = O().Out()
    lo = o.add("LowerTorso", "Under")
    O().shell(lo, "LowerTorso", .2, 1.05, pad=.07, hem=False)
    o.both("UpperLeg", "Under", lambda pc, part: O().shell(pc, part, -.05, .45, pad=.08, folds=.02))
    O().thigh_tails(o, "Cloth", 1.05, y_top=-.05, pad=.13, flare=.18)
    belt = o.add("LowerTorso", "Belt")
    O().ribbed(belt, "LowerTorso", .0, .45, pad=.17, ribs=1, depth=.02, rings_per=4)
    return o.items


def item_long_shorts():
    o = O().Out()
    lo = o.add("LowerTorso", "Cloth")
    O().shell(lo, "LowerTorso", .2, 1.05, pad=.09, hem=False)
    o.both("UpperLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.05, 1.02, pad=.13, flare1=.08, folds=.04, hem=False))
    o.both("LowerLeg", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .2, pad=.16, flare0=.08, flare1=.12, folds=.045))
    belt = o.add("LowerTorso", "Belt")
    O().ribbed(belt, "LowerTorso", .1, .6, pad=.12, ribs=1, depth=.015, rings_per=3)
    return o.items


# ------------------------------------------------------------------ arms
def item_arm_warmers():
    o = O().Out()
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.06, .96, pad=.1, flare0=.03, flare1=.02, folds=.04, hem="both"))
    return o.items


def item_gauntlets():
    o = O().Out()
    o.both("LowerArm", "Leather", lambda pc, part: O().shell(pc, part, .45, .98, pad=.08, flare0=.08, folds=.01, hem=True))
    o.both("Hand", "Leather", lambda pc, part: O().shell(pc, part, -.05, .85, pad=.03, folds=.004, hem=False, rings=4))
    o.both("LowerArm", "Metal", lambda pc, part: O().plate(pc, part, .5, .9, .1, arc=(-.6, .6), thick=.04), mat="Metal")
    return o.items


def item_bracers():
    o = O().Out()
    o.both("LowerArm", "Leather", lambda pc, part: O().shell(pc, part, .2, .9, pad=.06, folds=.006, hem="both", rings=6))
    def studs(pc, part):
        S = O().size(part)
        for y in (.2, .0, -.2):
            for x in (-.18, .18):
                O().box(pc, (x, y, -(S.z / 2 + .06) / O().K - .02), (.04, .04, .03), O().shade(.95, .02))
    o.both("LowerArm", "Metal", studs, mat="Metal")
    return o.items


def item_fingerless():
    o = O().Out()
    o.both("Hand", "Leather", lambda pc, part: O().shell(pc, part, -.08, .55, pad=.02, folds=.002, hem=True, rings=4))
    o.both("LowerArm", "Leather", lambda pc, part: O().ribbed(pc, part, .82, 1.0, pad=.04, ribs=1, depth=.01, rings_per=3))
    def plate(pc, part):
        S = O().size(part)
        O().box(pc, (0, .02, -(S.z / 2 + .02) / O().K - .02), (.26, .07, .025), O().shade(.95, .02))
    o.both("Hand", "Metal", plate, mat="Metal")
    return o.items


def item_elbow_pads():
    o = O().Out()
    def pad(pc, part):
        S = O().size(part)
        O().ribbed(pc, part, .02, .26, pad=.1, ribs=2, depth=.03, rings_per=3)
    o.both("LowerArm", "Pad", pad)
    o.both("UpperArm", "Strap", lambda pc, part: O().ribbed(pc, part, .78, .88, pad=.05, ribs=1, depth=.01, rings_per=3))
    return o.items


def item_long_sleeves():
    o = O().Out()
    o.both("UpperArm", "Cloth", lambda pc, part: O().shell(pc, part, .1, 1.02, pad=.07, folds=.03, hem=False))
    o.both("LowerArm", "Cloth", lambda pc, part: O().shell(pc, part, -.02, .8, pad=.1, flare1=.16, folds=.04))
    o.both("UpperArm", "Trim", lambda pc, part: O().ribbed(pc, part, .08, .18, pad=.09, ribs=1, depth=.01, rings_per=3))
    return o.items


# ------------------------------------------------------------------ feet
def item_boots():
    o = O().Out()
    for side in ("Right", "Left"):
        pc = o.add(side + "Foot", "Leather")
        S = O().size("RightFoot")
        y = -S.y / 2
        rows = [O().section(S.x / 2 / O().K + .06, S.z / 2 / O().K + .14, y=y + dy) for dy in (-.07, -.02, .2, S.y / 2 + .05)]
        for r in rows:
            for p in r:
                p.z -= .06
        loft(pc, rows, O().shade(.85, .05), cap0=True, cap1=False)
    o.both("LowerLeg", "Leather", lambda pc, part: O().shell(pc, part, .35, 1.0, pad=.1, flare0=.06, folds=.015, hem="both"))
    o.both("LowerLeg", "Strap", lambda pc, part: (O().ribbed(pc, part, .5, .58, pad=.12, ribs=1, depth=.01, rings_per=3),
                                                 O().ribbed(pc, part, .75, .83, pad=.12, ribs=1, depth=.01, rings_per=3)))
    return o.items


def item_tabi():
    o = O().Out()
    for side in ("Right", "Left"):
        pc = o.add(side + "Foot", "Cloth")
        O().shell(pc, side + "Foot", -.1, 1.0, pad=.06, folds=.004, hem=False, rings=4)
        sole = o.add(side + "Foot", "Sole")
        S = O().size("RightFoot")
        rows = [O().section(S.x / 2 / O().K + .05, S.z / 2 / O().K + .08, y=-S.y / 2 + dy) for dy in (-.06, -.01)]
        loft(sole, rows, O().shade(.7, .04), cap0=True, cap1=True)
        split = o.add(side + "Foot", "Sole", name="Split")
        O().box(split, (.18 if side == "Right" else -.18, 0, -S.z / 2 - .06), (.015, S.y / 2 + .02, .1), lambda p, k: (.4, .4, .4))
    o.both("LowerLeg", "Cloth", lambda pc, part: O().shell(pc, part, .7, 1.0, pad=.06, folds=.01, hem=True, rings=4))
    return o.items


def item_geta():
    o = O().Out()
    for side in ("Right", "Left"):
        S = O().size("RightFoot")
        wood = o.add(side + "Foot", "Wood", mat="Wood")
        O().box(wood, (0, -S.y / 2 - .08, -.05), (S.x / 2 + .06, .05, S.z / 2 + .14), O().shade(.85, .05))
        for zz in (-.28, .25):
            O().box(wood, (0, -S.y / 2 - .25, zz), (S.x / 2 + .02, .12, .06), O().shade(.75, .04))
        thong = o.add(side + "Foot", "Strap")
        tube(thong, [Vector((-.38, -S.y / 2 - .02, -.05)), Vector((-.2, .12, -.32)), Vector((0, .08, -.45)), Vector((.2, .12, -.32)), Vector((.38, -S.y / 2 - .02, -.05))], .04, O().shade(.9, .04), sides=6)
    return o.items


def item_shin_guards():
    o = O().Out()
    for side in ("Right", "Left"):
        def pcs(slot, side=side):
            return o.add(side + "Foot", "Sandal")
        O().sandal(pcs, side + "Foot")
    o.both("LowerLeg", "Metal", lambda pc, part: O().plate(pc, part, .15, .8, .1, arc=(-.7, .7), thick=.05), mat="Metal")
    o.both("LowerLeg", "Strap", lambda pc, part: (O().ribbed(pc, part, .25, .32, pad=.06, ribs=1, depth=.01, rings_per=3),
                                                 O().ribbed(pc, part, .66, .73, pad=.06, ribs=1, depth=.01, rings_per=3)))
    return o.items


def item_wrapped_feet():
    o = O().Out()
    for side in ("Right", "Left"):
        pc = o.add(side + "Foot", "Wrap")
        O().ribbed(pc, side + "Foot", -.05, .9, pad=.04, ribs=3, depth=.015, spiral=1.0)
    o.both("LowerLeg", "Wrap", lambda pc, part: O().ribbed(pc, part, .55, 1.0, pad=.03, ribs=5, depth=.015, spiral=1.0))
    return o.items


def item_open_boots():
    o = O().Out()
    for side in ("Right", "Left"):
        def pcs(slot, side=side):
            return o.add(side + "Foot", "Leather")
        O().sandal(pcs, side + "Foot")
    o.both("LowerLeg", "Leather", lambda pc, part: O().shell(pc, part, .3, 1.0, pad=.08, flare0=.04, folds=.01, hem="both"))
    return o.items


# ------------------------------------------------------------------ the six invented outfits
# A set is a bundle of the pieces above, each in the set's own colours (no mesh of its own:
# the pieces are shared). id -> (name, [(model, {slot: colour})]).
SETS = {
    "SetEmberMonk": ("Ember Monk", [
        ("Gi", {"Cloth": (232, 120, 40), "Belt": (40, 36, 40)}), ("Hakama", {"Cloth": (120, 34, 36), "Belt": (40, 36, 40)}),
        ("Bracers", {"Leather": (96, 64, 44), "Metal": (200, 200, 206)}), ("Geta", {"Wood": (164, 120, 80), "Strap": (190, 40, 36)}),
        ("Hachimaki", {"Band": (236, 232, 220)})]),
    "SetMistHunter": ("Mist Hunter", [
        ("Turtleneck", {"Cloth": (58, 96, 128)}), ("CargoPants", {"Cloth": (58, 96, 128), "Tie": (210, 210, 214), "Pocket": (46, 80, 108)}),
        ("Gauntlets", {"Leather": (52, 56, 66), "Metal": (176, 182, 190)}), ("Boots", {"Leather": (52, 56, 66), "Strap": (40, 42, 50)}),
        ("MaskCat", {"Mask": (240, 240, 236), "Paint": (70, 120, 200), "Strap": (40, 42, 50)}), ("Scarf", {"Scarf": (170, 210, 226)})]),
    "SetStormCourier": ("Storm Courier", [
        ("TrackJacket", {"Cloth": (238, 200, 40), "Trim": (36, 40, 52)}), ("LongShorts", {"Cloth": (36, 40, 52), "Belt": (238, 200, 40)}),
        ("Fingerless", {"Leather": (36, 40, 52), "Metal": (200, 204, 210)}), ("Tabi", {"Cloth": (236, 232, 222), "Sole": (60, 60, 64)}),
        ("BackPouch", {"Leather": (150, 110, 70), "Metal": (200, 204, 210), "Strap": (60, 50, 44)}),
        ("HeadbandClassic", {"Band": (36, 40, 52), "Plate": (200, 204, 210)})]),
    "SetShadowScout": ("Shadow Scout", [
        ("MeshShirt", {"Cloth": (90, 90, 100)}), ("SashTop", {"Cloth": (46, 48, 60), "Sash": (150, 40, 60)}),
        ("WrapPants", {"Cloth": (46, 48, 60), "Wrap": (200, 196, 186)}), ("ArmWarmers", {"Cloth": (200, 196, 186)}),
        ("WrappedFeet", {"Wrap": (200, 196, 186)}), ("MaskCloth", {"Cloth": (46, 48, 60)}),
        ("BackSword", {"Sheath": (30, 30, 36), "Metal": (190, 190, 196), "Grip": (150, 40, 60), "Strap": (30, 30, 36)})]),
    "SetLeafMedic": ("Leaf Medic", [
        ("ChuninVest", {"Cloth": (64, 70, 92), "Vest": (110, 150, 92)}), ("Leggings", {"Cloth": (64, 70, 92), "Weights": (236, 232, 222)}),
        ("ElbowPads", {"Pad": (236, 232, 222), "Strap": (40, 42, 50)}), ("OpenBoots", {"Leather": (64, 70, 92)}),
        ("HeadbandNeck", {"Band": (64, 70, 92), "Plate": (200, 204, 210)})]),
    "SetSandNomad": ("Sand Nomad", [
        ("Haori", {"Cloth": (196, 150, 90), "Under": (110, 60, 46), "Trim": (230, 200, 120)}),
        ("WrapSkirt", {"Cloth": (196, 150, 90), "Under": (110, 60, 46), "Belt": (230, 200, 120)}),
        ("ShinGuards", {"Sandal": (90, 64, 44), "Metal": (176, 160, 130), "Strap": (90, 64, 44)}),
        ("CloakHooded", {"Cape": (214, 186, 140)}),
        ("BackScroll", {"Paper": (240, 230, 200), "Wood": (120, 80, 50), "Strap": (90, 64, 44)})]),
}


# ------------------------------------------------------------------ hair styles (22/11, redone, DEC-047)
# Worn on the Head (slot "hair"), over a bald head: Server/Style takes the avatar's own hair off
# when a style is worn and paints its slot "Hair" with the chosen hair colour.
# (22/11, François: « les 7 coiffures sont mauvaises ») The first set was needles on a cap: thin
# round spikes, no volume, nothing that reads as anime hair. Redone as Part I hair is drawn:
# broad FLAT locks (a lens section, wide across the scalp, thin through it), bigger than the
# skull, layered, each lock darker at the root and light at its tip, a fringe that frames the
# face. Silhouettes after the Part I cuts (none is a character's exact cut, no face, no logo):
#   HairSpiky     big spikes every way, a three-lock fringe          (Naruto)
#   HairSwept     spikes thrown back and up, long bangs to the jaw   (Sasuke)
#   HairBowl      a glossy round bowl, the fringe cut straight        (Lee)
#   HairLong      long and straight, parted, tied at the very end    (Neji)
#   HairHighTail  pulled back tight, a spiky tail high on the crown  (Shikamaru)
#   HairBuns      two round buns on top, a short fringe              (Tenten)
#   HairTilted    every lock swept up to one side                    (Kakashi)
HEAD_C = Vector((0, .1, 0))     # the skull's centre (Head part space; the face looks -Z)
EYE_X, EYE_TOP = .5, .43        # the eyes and the brows keep clear (with a margin for the avatars' own heads)


def scalp(az, el, r=.56):
    """A point on the skull: az in degrees round Y (0 = the back, +Z; 180 = the face, -Z;
    90 = his left, +X... the model's +X), el in degrees above the ears' plane."""
    a, e = math.radians(az), math.radians(el)
    return HEAD_C + Vector((math.sin(a) * math.cos(e) * r * 1.02, math.sin(e) * r, math.cos(a) * math.cos(e) * r))


def lock(pc, root, direction, length, width, thick=.09, bend=(0, 0, 0), sections=5, sides=8, dark=.72, curl=0.0, blunt=0.0):
    """One flat lock of hair: a lens section `width` across and `thick` through, tapering to a
    point `length` along `direction`, bending by `bend` (x length, quadratic). Darker at the root.
    The width lies across the scalp (perpendicular to both the lock and the skull's normal)."""
    d = Vector(direction).normalized()
    b = Vector(bend)
    root = Vector(root)
    n0 = (root - HEAD_C).normalized()
    az = Vector((0, 1, 0)).cross(n0)
    if az.length < .05:
        az = Vector((1, 0, 0))

    def build(length):
        pts = [root + d * length * s + b * length * s * s for s in [k / sections for k in range(sections + 1)]]
        rings = []
        for k in range(sections):
            t = (pts[k + 1] - pts[k]).normalized()
            # the width lies round the head (the horizontal tangent at the root), so a spike is a
            # broad blade seen from the front or the back, never a needle
            wa = az - t * az.dot(t)
            if wa.length < .05:
                wa = t.cross(n0)
            wa.normalize()
            ta = wa.cross(t).normalized()
            s = k / sections
            taper = (1 - s) ** .75 * (1 - blunt) + blunt      # blunt: straight hair keeps its width to the end
            w, th = width * taper * (1 + .25 * math.sin(s * math.pi)), thick * (1 - s * .6)
            ring = []
            for i in range(sides):
                a = i / sides * math.tau
                # a lens: wide across, thin through
                x, y = math.cos(a), math.sin(a)
                ring.append(pts[k] + wa * (x * w / 2) + ta * (y * th / 2) + wa * (curl * y * th))
            rings.append(ring)
        return pts, rings

    def over_eyes(pts, rings):
        return any(q.z < -.15 and abs(q.x) < EYE_X and q.y < EYE_TOP for q in [pts[-1]] + [q for r in rings for q in r])

    # (23/11, François: « des cheveux sur les yeux », « toujours des imprécisions au niveau des
    # yeux ») nothing in front of the eyes: every point of the lock (its whole width, not only its
    # middle line) that would be over the face between the temples below the brows cuts it short;
    # a lock that cannot clear them is not drawn
    pts, rings = build(length)
    for _ in range(16):
        if not over_eyes(pts, rings):
            break
        length *= .85
        pts, rings = build(length)
    if over_eyes(pts, rings):
        return

    def col(p, ri):
        g = dark + (1 - dark) * ri / sections
        g += .05 * noise.noise(Vector((p.x * 5, p.y * 5, p.z * 5)))
        g = max(.5, min(1, g))
        return (g, g, g)
    loft(pc, rings, col, cap0=True, cap1=False, tip1=pts[-1])


def skull(pc, front=1.9, r=(.67, .69), top=.78, y0=.02, z_off=.03, hairline=.42):
    """The hair's mass over the skull (under the locks): closed over the forehead and the crown
    from the hairline up, open on the face below it (the first set left the forehead bald)."""
    o = O()
    n = 28
    rows_band, rows_cap = [], []
    for k in range(4):                       # the sides and the back, open on the face
        y = y0 + (hairline - y0) * k / 3
        ring = []
        for i in range(n):
            t = -math.pi / 2 + front / 2 + (2 * math.pi - front) * i / (n - 1)
            ring.append(Vector((math.cos(t) * r[0], y, math.sin(t) * r[1] + z_off)))
        rows_band.append(ring)
    loft(pc, rows_band, o.shade(.76, .04), cap0=False, cap1=False, closed=False)
    for k in range(7):                       # the crown, closed
        u = k / 6
        a = math.cos(u * math.pi / 2 * .94) ** .3
        y = hairline + (top - hairline) * math.sin(u * math.pi / 2)
        rows_cap.append([Vector((math.cos(t) * r[0] * a, y, math.sin(t) * r[1] * a + z_off)) for t in [i / n * math.tau for i in range(n)]])
    loft(pc, rows_cap, o.shade(.8, .05), cap0=False, cap1=True)



def nape(pc, length=.38, width=.36, out=.35, spread=150, count=9, el=8, flow=(0, 0, 0)):
    """Locks hanging round the back and the sides under the crown: the cap's lower edge
    becomes a ragged line of tips, not a hat's brim."""
    for k in range(count):
        az = -spread + 2 * spread * k / (count - 1)
        root = scalp(az, el, r=.6)
        n = (root - HEAD_C)
        n.y = 0
        n.normalize()
        lock(pc, root, n * out + Vector((0, -1, 0)) + Vector(flow), length, width, thick=.09, bend=(0, 0, 0))


def fringe(pc, xs, y=.5, length=.42, width=.3, down=(0, -1, -.35), spread=.25):
    """Locks over the brow, from the hairline down toward the eyes (never over them)."""
    for x in xs:
        lock(pc, (x, y, -.56), (down[0] + x * spread, down[1], down[2]), length, width, thick=.08, bend=(0, 0, -.12))


def item_hair_spiky():
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h)
    import random
    rng = random.Random(3)
    # big spikes all round the crown and the back, out and up; the top ones longest
    for az, el, ln in ((0, 20, .75), (35, 15, .7), (-35, 15, .7), (70, 18, .62), (-70, 18, .62), (110, 25, .55), (-110, 25, .55),
                       (0, 50, .8), (50, 48, .78), (-50, 48, .78), (100, 50, .7), (-100, 50, .7), (150, 55, .62), (-150, 55, .62),
                       (20, 78, .7), (-20, 78, .7), (180, 70, .6), (90, 75, .62), (-90, 75, .62)):
        root = scalp(az, el)
        n = (root - HEAD_C).normalized()
        lock(h, root, n + Vector((0, .45, 0)), ln * rng.uniform(.92, 1.08), .5, thick=.12, bend=(0, .15, 0))
    # over the ears: short locks down and out
    for x in (-1, 1):
        lock(h, scalp(x * 100, -5), (x * .8, -.7, .1), .4, .3)
    nape(h, length=.42, out=.6)
    fringe(h, (-.36, -.12, .12, .36), y=.56, length=.34, width=.36)
    return o.items


def item_hair_swept():
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h)
    # the back thrown back and up: long locks in fans, rising toward the crown
    for az, el, ln in ((0, 10, .7), (30, 12, .66), (-30, 12, .66), (60, 18, .55), (-60, 18, .55),
                       (0, 40, .9), (25, 42, .85), (-25, 42, .85), (55, 45, .7), (-55, 45, .7),
                       (0, 68, .85), (35, 70, .75), (-35, 70, .75), (120, 72, .55), (-120, 72, .55)):
        root = scalp(az, el)
        lock(h, root, (math.sin(math.radians(az)) * .35, .55, 1), ln, .38, bend=(0, .25, 0))
    # long bangs either side of the face, down to the jaw; a short lock between the eyes
    for x in (-1, 1):
        lock(h, (x * .54, .5, -.44), (x * .12, -1, -.1), .85, .28, thick=.08, bend=(x * .05, 0, -.05))
    lock(h, (.05, .52, -.56), (.15, -1, -.35), .45, .26, thick=.08)
    nape(h, length=.36, out=.9, spread=120, count=7, flow=(0, .3, .4))
    return o.items


def item_hair_bowl():
    o = O().Out()
    h = o.add("Head", "Hair")
    # a round helmet of hair, bigger than the skull, its edge cut straight: over the brows in
    # front, the jaw at the sides, the nape behind; a thick rim so it reads as a mass
    n = 36
    rows = []
    for k in range(9):
        u = k / 8
        ring = []
        for i in range(n):
            t = i / n * math.tau                     # 0 = his left (+X), -pi/2 = the face (-Z)
            fz = -math.sin(t)                        # 1 = the face
            edge = .3 * max(0, fz) ** 2 + (-.25) * (1 - max(0, fz) ** 2)
            edge = .46 if fz > .55 else edge         # the fringe cut level, over the brows
            y = edge + (.86 - edge) * math.sin(u * math.pi / 2)
            a = math.cos(u * math.pi / 2 * .96) ** .45
            ring.append(Vector((math.cos(t) * .74 * a, y, math.sin(t) * .76 * a + .03)))
        rows.append(ring)
    def gloss(p, ri):
        g = .78 + .2 * ri / 8 + (.2 if abs(p.y - .62) < .08 and p.z < .2 else 0)   # the shine band
        return (min(1, g),) * 3
    loft(h, rows, gloss, cap0=False, cap1=True)
    inner = [[(p - HEAD_C) * .93 + HEAD_C for p in rows[0]], rows[0]]
    loft(h, inner, O().shade(.7, .02), cap0=False, cap1=False)   # the rim's thickness
    return o.items


def item_hair_long():
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, front=1.7)
    # parted in the middle: two curtains framing the face, down past the jaw
    for x in (-1, 1):
        lock(h, (x * .3, .62, -.5), (x * 1.3, -.35, -.05), .5, .34, thick=.09, bend=(0, -.4, 0))
        lock(h, (x * .58, .4, -.36), (x * .08, -1, .02), .95, .32, thick=.09)
        lock(h, (x * .55, .3, -.2), (x * .1, -1, .05), 1.0, .4, thick=.1)
    # the fall down the back: a broad flat sheet, tied near its end
    rows = []
    for (y, w, z) in ((.55, 1.2, .5), (.0, 1.1, .7), (-.7, .85, .78), (-1.4, .5, .8), (-1.75, .3, .8), (-2.2, .42, .8), (-2.45, .08, .78)):
        rows.append([Vector((math.cos(t) * w / 2, y, z + math.sin(t) * max(.08, w * .22))) for t in [i / 16 * math.tau for i in range(16)]])
    def col(p, ri):
        g = .74 + .26 * ri / 6
        return (g, g, g)
    loft(h, rows, col)
    tie = o.add("Head", "Tie")
    head_ring(tie, -1.75, .14, r=(.18, .07), z_off=.8)
    return o.items


def item_hair_high_tail():
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.65, .67), top=.72)   # pulled tight
    for az in (-150, -120, 120, 150):  # the hairline's swept-back strokes
        lock(h, scalp(az, 30), (0, .3, 1), .55, .3, thick=.06, bend=(0, .1, 0))
    tie = o.add("Head", "Tie")
    head_ring(tie, .7, .12, r=(.15, .15), z_off=.42)
    # the tail: a pineapple of spikes bursting up and back from the tie
    import random
    rng = random.Random(4)
    for k in range(9):
        a = k / 9 * math.tau
        root = Vector((math.cos(a) * .08, .78, .42 + math.sin(a) * .08))
        d = Vector((math.cos(a) * .55, 1.0, .55 + math.sin(a) * .55))
        lock(h, root, d, rng.uniform(.6, .8), .26, thick=.08, bend=(0, -.1, .15))
    return o.items


def item_hair_buns():
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h)
    from nd_mesh import ellipsoid
    for x in (-.4, .4):
        ellipsoid(h, Vector((x, .84, .12)), (.33, .31, .33), O().shade(.86, .1), seg=16, rings=10)
    tie = o.add("Head", "Tie")
    for x in (-.4, .4):             # a band round each bun's foot
        rows = [[Vector((x + math.cos(t) * r_, y, .12 + math.sin(t) * r_)) for t in [i / 16 * math.tau for i in range(16)]]
                for (y, r_) in ((.6, .29), (.66, .31), (.72, .29))]
        loft(tie, rows, O().shade(.9, .03), cap0=False, cap1=False)
    fringe(h, (-.3, -.08, .16, .36), length=.36, width=.26)
    for x in (-1, 1):
        lock(h, (x * .58, .4, -.34), (x * .05, -1, -.05), .6, .22, thick=.07)
    return o.items


def item_hair_tilted():
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h)
    import random
    rng = random.Random(9)
    side = Vector((-.85, 1.0, .15))       # everything leans up and to his right (-X)
    for az, el in ((0, 25), (40, 20), (-40, 22), (80, 30), (-80, 30), (130, 40), (-130, 40),
                   (0, 55), (45, 55), (-45, 55), (95, 60), (-95, 60), (160, 62), (-160, 62), (20, 82), (-60, 80)):
        lock(h, scalp(az, el), side + (scalp(az, el) - HEAD_C) * .6, rng.uniform(.7, .9), .5, thick=.12, bend=(-.15, .05, 0))
    nape(h, length=.36, out=.5, flow=(-.4, 0, 0))
    fringe(h, (-.3, 0, .3), y=.56, length=.32, width=.3, down=(-.5, -1, -.3), spread=.1)
    return o.items


# (23/11, François: « elles sont belles mais pas assez variées ») six more Part I silhouettes
def item_hair_bob():
    """Short and round to the jaw, the fringe swept to one side, the forehead free (Sakura's short cut)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, front=1.6, r=(.7, .72), top=.8)
    # the round fall all round the sides and the back, down to the jaw
    for az in (-125, -100, -75, -50, -25, 0, 25, 50, 75, 100, 125):
        root = scalp(az, 18, r=.64)
        out = Vector((math.sin(math.radians(az)) * .25, -1, math.cos(math.radians(az)) * .25))
        lock(h, root, out, .72, .46, thick=.12, bend=(-math.sin(math.radians(az)) * .1, 0, -math.cos(math.radians(az)) * .1))
    for x in (-1, 1):
        lock(h, (x * .62, .4, -.34), (x * .05, -1, -.02), .62, .34, thick=.1)    # beside the cheeks
    fringe(h, (-.3, -.08, .14), y=.62, length=.4, width=.34, down=(1, -.45, -.25), spread=0)   # swept aside, over the brow
    return o.items


def item_hair_hime():
    """Long and straight down the back, a level fringe over the brows, side locks to the jaw (a hime cut)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, front=1.7, r=(.69, .71), top=.79)
    fringe(h, (-.33, -.11, .11, .33), y=.58, length=.2, width=.26, down=(0, -1, -.25), spread=0)
    for x in (-1, 1):
        lock(h, (x * .6, .42, -.34), (0, -1, -.02), .75, .3, thick=.08, blunt=.6)          # the side locks, cut level at the jaw
    # the long fall: straight locks side by side down the back
    for az in (-110, -85, -60, -35, -12, 12, 35, 60, 85, 110):
        root = scalp(az, 25, r=.64)
        out = Vector((math.sin(math.radians(az)) * .12, -1, math.cos(math.radians(az)) * .18))
        lock(h, root, out, 1.95 - abs(az) / 250, .5, thick=.12, bend=(0, 0, .08), blunt=.65)
    return o.items


def item_hair_pony():
    """A long ponytail from the crown down the back, the bang swept to one side of the face (Ino)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.66, .68), top=.75)
    tie = o.add("Head", "Tie")
    head_ring(tie, .6, .1, r=(.15, .15), z_off=.55)
    rows = []
    for (y, w, z) in ((.62, .36, .62), (.4, .46, .82), (-.2, .42, .92), (-.9, .32, .92), (-1.5, .2, .88), (-1.85, .04, .85)):
        rows.append([Vector((math.cos(t) * w / 2, y, z + math.sin(t) * w * .3)) for t in [i / 12 * math.tau for i in range(12)]])
    loft(h, rows, lambda p, ri: (min(1, .76 + .24 * ri / 5),) * 3)
    lock(h, (-.15, .64, -.5), (-1, -.55, -.05), .7, .38, thick=.08, bend=(0, -.35, 0))    # the long bang, beside the eye
    lock(h, (-.6, .42, -.34), (-.05, -1, 0), .8, .26, thick=.08)
    return o.items


def item_hair_mane():
    """A wild long mane of spikes down the back (the hermit's)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.7, .72), top=.8)
    import random
    rng = random.Random(12)
    for k in range(16):
        az = -100 + 200 * k / 15
        el = rng.uniform(5, 55)
        root = scalp(az, el)
        out = Vector((math.sin(math.radians(az)) * .5, -.35 + el / 100, math.cos(math.radians(az)) * .9 + .3))
        lock(h, root, out, rng.uniform(.9, 1.4), .42, thick=.12, bend=(0, -.5, .2))
    for az in (60, 100, 140, -60, -100, -140):
        lock(h, scalp(az, 70), (math.sin(math.radians(az)) * .4, .7, .5), .55, .38, thick=.1)
    for x in (-1, 1):
        lock(h, (x * .6, .4, -.32), (x * .2, -1, 0), 1.0, .3, thick=.09)
    fringe(h, (-.25, .05, .3), y=.6, length=.24, width=.3, down=(.2, -1, -.3), spread=.1)
    return o.items


def item_hair_short():
    """Short and messy all over, the tips pointing every way (Kiba)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.67, .69), top=.77)
    import random
    rng = random.Random(21)
    for k in range(26):
        az, el = rng.uniform(-180, 180), rng.uniform(5, 85)
        root = scalp(az, el, r=.6)
        n = (root - HEAD_C).normalized()
        lock(h, root, n + Vector((rng.uniform(-.4, .4), rng.uniform(-.2, .3), rng.uniform(-.2, .4))), rng.uniform(.28, .42), .3, thick=.08)
    fringe(h, (-.3, -.1, .12, .32), y=.6, length=.24, width=.24, down=(0, -1, -.4), spread=.5)
    return o.items


def item_hair_blaze():
    """Short spikes all thrown up and back like a flame, the temples bare (Gaara)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.66, .68), top=.76, front=1.8)
    for az, el, ln in ((0, 30, .6), (30, 35, .55), (-30, 35, .55), (60, 45, .5), (-60, 45, .5), (0, 60, .65), (40, 65, .6),
                       (-40, 65, .6), (100, 55, .45), (-100, 55, .45), (150, 70, .55), (-150, 70, .55), (180, 50, .5)):
        root = scalp(az, el)
        lock(h, root, (math.sin(math.radians(az)) * .25, 1, .55), ln, .4, thick=.1, bend=(0, 0, .25))
    fringe(h, (-.2, .05, .28), y=.62, length=.22, width=.28, down=(0, -1, -.3), spread=.3)
    return o.items


# (23/11, François, « plus de coupes et plus de couleurs ») five more
def item_hair_twin_tails():
    """Two tails high on the sides of the head, a short fringe."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.67, .69), top=.77)
    tie = o.add("Head", "Tie")
    for x in (-1, 1):
        rows = [[Vector((x * .72 + math.cos(t) * .1, .52, .12 + math.sin(t) * .1)) for t in [i / 12 * math.tau for i in range(12)]],
                [Vector((x * .74 + math.cos(t) * .11, .45, .12 + math.sin(t) * .11)) for t in [i / 12 * math.tau for i in range(12)]]]
        loft(tie, rows, O().shade(.9, .03), cap0=True, cap1=True)
        lock(h, (x * .76, .5, .14), (x * .35, -1, .2), 1.5, .42, thick=.14, bend=(x * .2, .15, 0), blunt=.2)
        lock(h, (x * .76, .5, .1), (x * .55, -1, -.05), 1.2, .32, thick=.12, bend=(x * .15, .1, 0))
    fringe(h, (-.3, -.08, .14, .34), y=.6, length=.3, width=.28)
    return o.items


def item_hair_topknot():
    """Pulled up into a knot on the crown, the sides close (a samurai's knot)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.65, .67), top=.72, front=2.0)
    from nd_mesh import ellipsoid
    ellipsoid(h, Vector((0, .86, .12)), (.22, .2, .32), O().shade(.86, .06), seg=12, rings=8)
    lock(h, (0, .9, .32), (0, -.3, 1), .5, .26, thick=.12, bend=(0, -.3, 0), blunt=.5)    # the knot's tail
    tie = o.add("Head", "Tie")
    head_ring(tie, .78, .08, r=(.16, .16), z_off=.12)
    for az in (-150, -110, 110, 150, 180):
        lock(h, scalp(az, 30), (0, .5, 1), .45, .3, thick=.05, bend=(0, .2, 0))
    return o.items


def item_hair_braid():
    """Long hair gathered into one thick braid down the back, the forehead free."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.67, .69), top=.76, front=1.8)
    for x in (-1, 1):
        lock(h, (x * .25, .66, -.48), (x * 1.2, -.3, .1), .45, .34, thick=.08, bend=(0, -.3, .2))   # swept back off the brow
    # the braid: plaits alternating left and right down the back
    y, z = .2, .66
    for k in range(9):
        side = 1 if k % 2 else -1
        r = .17 - k * .009
        from nd_mesh import ellipsoid
        ellipsoid(h, Vector((side * .05, y, z)), (r * 1.15, r * 1.25, r), O().shade(.84, .08), seg=10, rings=6)
        y -= .2
        z += .02
    tie = o.add("Head", "Tie")
    head_ring(tie, y + .12, .08, r=(.09, .09), z_off=z)
    lock(h, (0, y + .05, z), (0, -1, .05), .3, .2, thick=.08)
    return o.items


def item_hair_undercut():
    """Shaved short at the sides and the back, a tall spiky crest on top."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.62, .64), top=.66, front=2.0)     # the shaved part: close to the skull
    for k in range(9):
        z = -.4 + k * .1
        ln = .55 + .15 * math.sin(k / 8 * math.pi)
        lock(h, (0, .64, z), (0, 1, .35 + k * .05), ln, .5, thick=.12, bend=(0, -.1, .2))
    return o.items


def item_hair_curtain():
    """Parted in the middle, falling to the shoulders all round (curtains)."""
    o = O().Out()
    h = o.add("Head", "Hair")
    skull(h, r=(.69, .71), top=.79)
    for x in (-1, 1):
        lock(h, (x * .1, .68, -.46), (x * 1.0, -.5, -.05), .55, .38, thick=.09, bend=(0, -.35, 0))   # the part, swept out
    for az in (-130, -105, -80, -55, -30, -10, 10, 30, 55, 80, 105, 130):
        root = scalp(az, 20, r=.64)
        out = Vector((math.sin(math.radians(az)) * .25, -1, math.cos(math.radians(az)) * .15))
        lock(h, root, out, .95, .44, thick=.11, blunt=.45)
    return o.items


HAIR = {"HairSpiky": item_hair_spiky, "HairSwept": item_hair_swept, "HairBowl": item_hair_bowl, "HairLong": item_hair_long,
        "HairHighTail": item_hair_high_tail, "HairBuns": item_hair_buns, "HairTilted": item_hair_tilted,
        "HairBob": item_hair_bob, "HairHime": item_hair_hime, "HairPony": item_hair_pony, "HairMane": item_hair_mane,
        "HairShort": item_hair_short, "HairBlaze": item_hair_blaze,
        "HairTwinTails": item_hair_twin_tails, "HairTopknot": item_hair_topknot, "HairBraid": item_hair_braid,
        "HairUndercut": item_hair_undercut, "HairCurtain": item_hair_curtain}


# model -> builder
MODELS = {
    # headbands
    "HeadbandClassic": item_headband_classic, "HeadbandLong": item_headband_long, "HeadbandScratched": item_headband_scratched,
    "Hachimaki": item_headband_hachimaki, "HeadbandBandana": item_headband_bandana, "HeadbandBow": item_headband_bow,
    "HeadbandNeck": item_headband_neck, "HeadbandWaist": item_headband_waist,
    # hair styles (étape 3)
    **HAIR,
    # masks
    "MaskFox": item_mask_fox, "MaskCat": item_mask_cat, "MaskCloth": item_mask_cloth, "MaskRespirator": item_mask_respirator,
    # capes
    "CapeShort": item_cape_short, "CapeLong": item_cape_long, "CloakHooded": item_cloak_hooded, "Scarf": item_scarf,
    # back
    "BackScroll": item_back_scroll, "BackPouch": item_back_pouch, "BackSword": item_back_sword, "BackFuma": item_back_fuma,
    # tops
    "TrackJacket": item_track_jacket, "MeshShirt": item_mesh_shirt, "Haori": item_haori, "ChuninVest": item_chunin_vest,
    "Gi": item_gi, "Turtleneck": item_turtleneck, "SashTop": item_sash_top,
    # bottoms
    "Hakama": item_hakama, "CargoPants": item_cargo_pants, "Leggings": item_leggings, "WrapPants": item_wrap_pants,
    "WrapSkirt": item_wrap_skirt, "LongShorts": item_long_shorts,
    # arms
    "ArmWarmers": item_arm_warmers, "Gauntlets": item_gauntlets, "Bracers": item_bracers, "Fingerless": item_fingerless,
    "ElbowPads": item_elbow_pads, "LongSleeves": item_long_sleeves,
    # feet
    "Boots": item_boots, "Tabi": item_tabi, "Geta": item_geta, "ShinGuards": item_shin_guards, "WrappedFeet": item_wrapped_feet,
    "OpenBoots": item_open_boots,
}

# The catalogue entries (Shared/Catalog, DEV 2): id -> (kind, model, name, colours by slot).
# kind: top, bottom, arms, feet, headband, mask, cape, back, set. Colours chosen to read in
# SmoothPlastic; several ids share a model (a colourway).
C = lambda *rgb: rgb
CATALOG = {
    # tops
    "TopTrackJacketOrange": ("top", "TrackJacket", "Track Jacket", {"Cloth": C(236, 120, 30), "Trim": C(34, 44, 92)}),
    "TopTrackJacketRed": ("top", "TrackJacket", "Track Jacket (Crimson)", {"Cloth": C(196, 44, 44), "Trim": C(36, 36, 40)}),
    "TopMeshShirt": ("top", "MeshShirt", "Mesh Shirt", {"Cloth": C(80, 80, 92)}),
    "TopHaori": ("top", "Haori", "Short Haori", {"Under": C(40, 44, 60), "Cloth": C(170, 210, 226), "Trim": C(236, 232, 222)}),
    "TopChuninVest": ("top", "ChuninVest", "Chunin Vest", {"Cloth": C(46, 54, 86), "Vest": C(110, 150, 92)}),
    "TopGiWhite": ("top", "Gi", "Training Gi", {"Cloth": C(236, 232, 222), "Belt": C(40, 36, 40)}),
    "TopGiBlue": ("top", "Gi", "Training Gi (Indigo)", {"Cloth": C(60, 80, 160), "Belt": C(236, 232, 222)}),
    "TopTurtleneckPlum": ("top", "Turtleneck", "Turtleneck", {"Cloth": C(120, 60, 120)}),
    "TopTurtleneckTeal": ("top", "Turtleneck", "Turtleneck (Teal)", {"Cloth": C(30, 130, 130)}),
    "TopSashTop": ("top", "SashTop", "Sash Top", {"Cloth": C(46, 48, 60), "Sash": C(196, 44, 44)}),
    # bottoms
    "BottomHakamaNavy": ("bottom", "Hakama", "Hakama", {"Cloth": C(46, 54, 96), "Belt": C(236, 232, 222)}),
    "BottomHakamaGrey": ("bottom", "Hakama", "Hakama (Ash)", {"Cloth": C(120, 124, 132), "Belt": C(40, 36, 40)}),
    "BottomCargo": ("bottom", "CargoPants", "Cargo Pants", {"Cloth": C(96, 110, 70), "Tie": C(226, 222, 212), "Pocket": C(80, 92, 58)}),
    "BottomLeggings": ("bottom", "Leggings", "Leggings & Weights", {"Cloth": C(46, 140, 60), "Weights": C(236, 120, 30)}),
    "BottomWrapPants": ("bottom", "WrapPants", "Wrapped Trousers", {"Cloth": C(140, 100, 70), "Wrap": C(226, 222, 212)}),
    "BottomWrapSkirt": ("bottom", "WrapSkirt", "Wrap Skirt", {"Under": C(40, 44, 60), "Cloth": C(196, 60, 90), "Belt": C(236, 200, 80)}),
    "BottomLongShorts": ("bottom", "LongShorts", "Long Shorts", {"Cloth": C(60, 100, 170), "Belt": C(36, 36, 40)}),
    # arms
    "ArmsWarmers": ("arms", "ArmWarmers", "Arm Warmers", {"Cloth": C(236, 232, 222)}),
    "ArmsGauntlets": ("arms", "Gauntlets", "Gauntlets", {"Leather": C(96, 64, 44), "Metal": C(190, 194, 200)}),
    "ArmsBracers": ("arms", "Bracers", "Studded Bracers", {"Leather": C(140, 70, 40), "Metal": C(210, 190, 120)}),
    "ArmsFingerless": ("arms", "Fingerless", "Fingerless Gloves", {"Leather": C(36, 36, 40), "Metal": C(190, 194, 200)}),
    "ArmsElbowPads": ("arms", "ElbowPads", "Elbow Pads", {"Pad": C(60, 100, 170), "Strap": C(36, 36, 40)}),
    "ArmsLongSleeves": ("arms", "LongSleeves", "Long Sleeves", {"Cloth": C(170, 60, 60), "Trim": C(236, 200, 80)}),
    # feet
    "FeetBoots": ("feet", "Boots", "High Boots", {"Leather": C(60, 50, 44), "Strap": C(150, 110, 70)}),
    "FeetTabi": ("feet", "Tabi", "Tabi", {"Cloth": C(236, 232, 222), "Sole": C(60, 60, 64)}),
    "FeetGeta": ("feet", "Geta", "Geta", {"Wood": C(164, 120, 80), "Strap": C(196, 44, 44)}),
    "FeetShinGuards": ("feet", "ShinGuards", "Shin Guards", {"Sandal": C(46, 54, 96), "Metal": C(190, 194, 200), "Strap": C(36, 36, 40)}),
    "FeetWrapped": ("feet", "WrappedFeet", "Wrapped Feet", {"Wrap": C(226, 222, 212)}),
    "FeetOpenBoots": ("feet", "OpenBoots", "Open-Toe Boots", {"Leather": C(40, 44, 70)}),
    # headbands (8)
    "HeadbandBlue": ("headband", "HeadbandClassic", "Forehead Protector", {"Band": C(46, 60, 130), "Plate": C(200, 204, 210)}),
    "HeadbandLongBlack": ("headband", "HeadbandLong", "Long-Tail Protector", {"Band": C(36, 36, 40), "Plate": C(200, 204, 210)}),
    "HeadbandScratched": ("headband", "HeadbandScratched", "Scratched Protector", {"Band": C(110, 40, 44), "Plate": C(170, 174, 180)}),
    "HeadbandHachimaki": ("headband", "Hachimaki", "Hachimaki", {"Band": C(236, 232, 222)}),
    "HeadbandBandana": ("headband", "HeadbandBandana", "Bandana Protector", {"Band": C(60, 100, 170), "Plate": C(200, 204, 210)}),
    "HeadbandBow": ("headband", "HeadbandBow", "Ribbon Protector", {"Band": C(220, 80, 120), "Plate": C(200, 204, 210)}),
    "HeadbandNeck": ("headband", "HeadbandNeck", "Neck Protector", {"Band": C(46, 60, 130), "Plate": C(200, 204, 210)}),
    "HeadbandWaist": ("headband", "HeadbandWaist", "Waist Protector", {"Band": C(130, 60, 140), "Plate": C(200, 204, 210)}),
    # masks
    "MaskFox": ("mask", "MaskFox", "Fox Mask", {"Mask": C(240, 240, 236), "Paint": C(200, 40, 40), "Strap": C(36, 36, 40)}),
    "MaskCat": ("mask", "MaskCat", "Cat Mask", {"Mask": C(240, 240, 236), "Paint": C(60, 100, 200), "Strap": C(36, 36, 40)}),
    "MaskCloth": ("mask", "MaskCloth", "Face Mask", {"Cloth": C(46, 54, 86)}),
    "MaskRespirator": ("mask", "MaskRespirator", "Respirator", {"Metal": C(150, 156, 166), "Strap": C(36, 36, 40)}),
    # hair styles (étape 3): slot "Hair" takes the chosen hair colour (Server/Style)
    "HairSpiky": ("hair", "HairSpiky", "Wild Spikes", {"Hair": C(236, 196, 70)}),
    "HairSwept": ("hair", "HairSwept", "Swept Spikes", {"Hair": C(30, 30, 44)}),
    "HairBowl": ("hair", "HairBowl", "Bowl Cut", {"Hair": C(24, 22, 28)}),
    "HairLong": ("hair", "HairLong", "Long Tied", {"Hair": C(60, 44, 40), "Tie": C(236, 232, 222)}),
    "HairHighTail": ("hair", "HairHighTail", "High Tail", {"Hair": C(36, 34, 40), "Tie": C(150, 40, 40)}),
    "HairBuns": ("hair", "HairBuns", "Twin Buns", {"Hair": C(80, 52, 36), "Tie": C(200, 60, 60)}),
    "HairTilted": ("hair", "HairTilted", "Tilted Spikes", {"Hair": C(200, 204, 210)}),
    "HairBob": ("hair", "HairBob", "Short Bob", {"Hair": C(236, 150, 170)}),
    "HairHime": ("hair", "HairHime", "Hime Cut", {"Hair": C(40, 40, 70)}),
    "HairPony": ("hair", "HairPony", "Long Ponytail", {"Hair": C(240, 214, 120), "Tie": C(110, 60, 140)}),
    "HairMane": ("hair", "HairMane", "Wild Mane", {"Hair": C(230, 230, 226)}),
    "HairShort": ("hair", "HairShort", "Messy Short", {"Hair": C(66, 46, 36)}),
    "HairBlaze": ("hair", "HairBlaze", "Flame Spikes", {"Hair": C(176, 52, 40)}),
    "HairTwinTails": ("hair", "HairTwinTails", "Twin Tails", {"Hair": C(120, 70, 140), "Tie": C(236, 226, 198)}),
    "HairTopknot": ("hair", "HairTopknot", "Topknot", {"Hair": C(36, 32, 36), "Tie": C(176, 40, 34)}),
    "HairBraid": ("hair", "HairBraid", "Long Braid", {"Hair": C(150, 96, 56), "Tie": C(60, 110, 80)}),
    "HairUndercut": ("hair", "HairUndercut", "Undercut Crest", {"Hair": C(52, 70, 110)}),
    "HairCurtain": ("hair", "HairCurtain", "Curtains", {"Hair": C(110, 80, 60)}),
    # capes
    "CapeShortRed": ("cape", "CapeShort", "Short Cape", {"Cape": C(196, 44, 44), "Trim": C(236, 200, 80)}),
    "CapeLongWhite": ("cape", "CapeLong", "Long Cape", {"Cape": C(236, 232, 222), "Trim": C(196, 60, 40)}),
    "CloakHooded": ("cape", "CloakHooded", "Hooded Cloak", {"Cape": C(110, 90, 70)}),
    "ScarfRed": ("cape", "Scarf", "Long Scarf", {"Scarf": C(196, 44, 44)}),
    # back
    "BackScroll": ("back", "BackScroll", "Great Scroll", {"Paper": C(240, 230, 200), "Wood": C(120, 80, 50), "Strap": C(196, 44, 44)}),
    "BackPouch": ("back", "BackPouch", "Tool Pouch", {"Leather": C(150, 110, 70), "Metal": C(200, 204, 210), "Strap": C(60, 50, 44)}),
    "BackSword": ("back", "BackSword", "Sheathed Blade", {"Sheath": C(30, 30, 36), "Metal": C(200, 190, 140), "Grip": C(196, 44, 44), "Strap": C(60, 50, 44)}),
    "BackFuma": ("back", "BackFuma", "Folded Fuma", {"Metal": C(176, 182, 190), "Grip": C(60, 50, 44), "Strap": C(60, 50, 44)}),
}
for _id, (_name, _parts) in SETS.items():
    for _m, _c in _parts:
        assert _m in MODELS, (_id, _m)
