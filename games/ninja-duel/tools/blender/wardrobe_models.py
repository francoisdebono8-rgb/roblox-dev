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

from mathutils import Vector

from nd_mesh import loft, tube


def O():
    import outfit_models  # lazy: outfit_models imports this module at its end
    return outfit_models


HEAD = (1.2, 1.2, 1.2)
BROW = .27


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


def dome(pc, y0, r=(.66, .68), top=.72, rings=6, n=24, front_open=0.0, col=None, z_off=0.0):
    """A cap over the head from y0 up (a bandana, a hood): front_open (radians) leaves the face."""
    o = O()
    rows = []
    for k in range(rings):
        u = k / (rings - 1)
        a = math.cos(u * math.pi / 2 * .92)
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
    for y, rr, dz in ((.08, .66, 0.0), (-.1, .66, -.02), (-.36, .64, -.01), (-.62, .62, 0.0), (-.9, .62, .02)):
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
    O().flap(pc, "UpperTorso", -1.1, 1.1, .1, 3.3, 1, pad=.24, flare=.3, folds=.05, seed=5)
    trim = o.add("UpperTorso", "Trim", name="Hem")
    O().flap(trim, "UpperTorso", -1.1, 1.1, 2.12, .22, 1, pad=.25, flare=.02, folds=.05, seed=5)
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
    dome(hood, -.45, r=(.74, .78), top=.82, rings=7, front_open=2.0, z_off=.06)
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
    O().collar(col, "UpperTorso", h=.34, flare=.12, thick=.05, neck=(.66, .62))
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
    for zs, x0, x1, name in ((-1, -1.05, -.35, "FrontL"), (-1, .35, 1.05, "FrontR"), (1, -1.05, 1.05, "Back")):
        pc = o.add("LowerTorso", "Cloth", name=name)
        O().flap(pc, "LowerTorso", x0, x1, -.4, .95, zs, pad=.26, flare=.1, folds=.03, seed=zs + x0)
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
    for zs, x0, x1, name in ((-1, -1.05, .2, "Front"), (1, -1.05, 1.05, "Back"), (-1, .25, 1.05, "Side")):
        pc = o.add("LowerTorso", "Cloth", name=name)
        O().flap(pc, "LowerTorso", x0, x1, .2, 1.05, zs, pad=.15, flare=.2, folds=.03, seed=x0 + zs)
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


# model -> builder
MODELS = {
    # headbands
    "HeadbandClassic": item_headband_classic, "HeadbandLong": item_headband_long, "HeadbandScratched": item_headband_scratched,
    "Hachimaki": item_headband_hachimaki, "HeadbandBandana": item_headband_bandana, "HeadbandBow": item_headband_bow,
    "HeadbandNeck": item_headband_neck, "HeadbandWaist": item_headband_waist,
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
