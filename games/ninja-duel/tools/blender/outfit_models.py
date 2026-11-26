"""(14/11, DEV -> ANIMATEUR, DEC-040) The ninja outfit over the player's own
avatar: modelled pieces fitted on the standard R15 body (Server/AvatarBody.SCALES:
height/width/depth/head 1, body type 0, proportion 0), one mesh per body part
and per colour slot (Cloth, Collar, Belt, Wrap...: Shared/Shop's `colors`
keys, the game paints each slot).

References (Part I, the age the game draws: 12-14), checked 14/11:
  Naruto: orange track suit, the shoulders and upper back blue, a big white
    stand-up collar zipped high, the trousers taped at the shin, blue sandals.
  Sasuke: dark navy short-sleeved shirt with a very high open collar, white
    arm warmers elbow-to-wrist, white shorts, wrapped shins.
    (no clan crest: no logos in the game)
  Lee: green one-piece suit, orange leg warmers rolled over the shins, a red
    belt, bandaged forearms and hands.
  Neji: loose off-white robe shirt with long sleeves and tails to the thigh,
    dark shorts, a wrapped thigh.
  Gaara: dark red long coat to mid-thigh, the beige strap across the chest
    (the gourd's), dark trousers.
  Kakashi: navy long-sleeved shirt and trousers, the green flak vest with its
    scroll pockets and high collar, wrapped shins. (no spiral emblem)
  Itachi (ANBU): black sleeveless top, grey breastplate, metal forearm guards,
    black trousers. (no mask, no tattoo)
  Minato: navy shirt, green flak vest, the short white coat with the flames
    along its hem.
Free pieces: the genin tunic, the high collar, the sleeveless top, the tied
trousers, the wrapped shorts, arm wraps, arm guards, sandals.

Frame: each piece is modelled round ITS body part's centre, in the Roblox
frame (x right, y up, z back: the front is -z), on the reference part size
REF[part]; at run time it is scaled by body.Size/REF (any avatar at the
standard scales) and welded at body.CFrame*CFrame.new(o*scale).
Vertex colours are light shading only (folds, seams, hems: 0.6-1); the
MeshPart's Color is the slot's colour (they multiply).

Run:
  python3 outfit_models.py write ../../src/Shared   (OutfitMeshes + OutfitMeshData*)
  python3 outfit_models.py render <dir> [items]      (a mannequin per outfit)
"""
import math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import bpy  # noqa: F401 (brings mathutils)
from mathutils import Vector, noise
from nd_mesh import Piece, loft, smooth, outward


def lerp(a, b, t):
    return a + (b - a) * t

# The standard R15 body parts (Roblox's default body at scale 1): size and the
# rest-pose centre relative to LowerTorso.
REF = {
    "UpperTorso": (2, 1.6, 1), "LowerTorso": (2, .4, 1),
    "RightUpperArm": (1, 1.169, 1), "LeftUpperArm": (1, 1.169, 1),
    "RightLowerArm": (1, 1.052, 1), "LeftLowerArm": (1, 1.052, 1),
    "RightHand": (1, .3, 1), "LeftHand": (1, .3, 1),
    "RightUpperLeg": (1, 1.217, 1), "LeftUpperLeg": (1, 1.217, 1),
    "RightLowerLeg": (1, 1.193, 1), "LeftLowerLeg": (1, 1.193, 1),
    "RightFoot": (1, .3, 1), "LeftFoot": (1, .3, 1),
    "Head": (1.2, 1.2, 1.2),   # (19/11) masks, headbands, hoods: the classic head's box
}
REST = {
    "LowerTorso": (0, 0, 0), "UpperTorso": (0, 1.0, 0), "Head": (0, 2.4, 0),
    "RightUpperArm": (1.5, 1.2155, 0), "LeftUpperArm": (-1.5, 1.2155, 0),
    "RightLowerArm": (1.5, .105, 0), "LeftLowerArm": (-1.5, .105, 0),
    "RightHand": (1.5, -.571, 0), "LeftHand": (-1.5, -.571, 0),
    "RightUpperLeg": (.5, -.8085, 0), "LeftUpperLeg": (-.5, -.8085, 0),
    "RightLowerLeg": (.5, -2.0135, 0), "LeftLowerLeg": (-.5, -2.0135, 0),
    "RightFoot": (.5, -2.76, 0), "LeftFoot": (-.5, -2.76, 0),
}
K = .985   # (20/11: .957 before) the section's half axis over the part's: the cloth hugs the faces
# (20/11, François: « trop larges, elles flottent ») FIT .5 -> .3: every pad and flare a third
# tighter; FOLD: the cloth's folds 40 % shallower (they read as lumps on a blocky body)
FIT = .3
FOLD = .6
SEG = 28


def size(part):
    return Vector(REF[part])


def section(a, b, n=SEG, fold=None, y=0.0, front_cut=None):
    """A rounded-box ring (superellipse p=8) of half axes a (x), b (z) at height y.
    fold(theta, y) adds an outward offset (cloth folds)."""
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, s = math.cos(t), math.sin(t)
        x = a * math.copysign(abs(c) ** .125, c)
        z = b * math.copysign(abs(s) ** .125, s)
        if fold:
            d = fold(t, y)
            r = math.hypot(x, z) or 1
            x += x / r * d
            z += z / r * d
        out.append(Vector((x, y, z)))
    return out


def cloth_fold(amp=.025, freq=5.0, seed=0.0):
    def f(t, y):
        return amp * (.5 + .5 * noise.noise(Vector((math.cos(t) * freq * .3 + seed, y * freq, math.sin(t) * freq * .3))))
    return f


def shade(base=.92, var=.08, seed=0.0, ao_y=None):
    """Light shading (multiplies the slot colour): folds lighter/darker, and
    darker toward an edge y if ao_y=(y, width)."""
    def c(p, k):
        g = base + var * noise.noise(Vector((p.x * 3 + seed, p.y * 4, p.z * 3)))
        if ao_y:
            g -= .12 * max(0, 1 - abs(p.y - ao_y[0]) / ao_y[1])
        g = max(.55, min(1, g))
        return (g, g, g)
    return c


def shell(pc, part, y0, y1, pad=.07, flare0=0.0, flare1=0.0, folds=.02, rings=9, hem=True, seed=0.0, col=None, scale_x=1.0, scale_z=1.0):
    """Cloth round a body part from y0 (fraction from its top) to y1, with a
    rolled hem at the bottom (and top when hem='both')."""
    S = size(part)
    pad *= FIT
    flare0 *= FIT
    flare1 *= FIT
    a0 = (S.x / 2 + pad) / K * scale_x
    b0 = (S.z / 2 + pad) / K * scale_z
    fold = cloth_fold(folds * FOLD, 5, seed)
    rows = []
    for k in range(rings):
        u = k / (rings - 1)
        f = lerp(y0, y1, u)
        y = S.y / 2 - f * S.y
        fl = lerp(flare0, flare1, u)
        rows.append(section(a0 + fl, b0 + fl, fold=fold, y=y))
    if hem:
        last = rows[-1]
        y = last[0].y
        roll = [Vector((p.x * 1.02, y - .02, p.z * 1.02)) for p in last]
        under = [Vector((p.x * 1.0, y - .045, p.z * 1.0)) for p in last]
        rows += [roll, under]
        if hem == "both":
            first = rows[0]
            yt = first[0].y
            rows = [[Vector((p.x, yt + .045, p.z)) for p in first], [Vector((p.x * 1.02, yt + .02, p.z * 1.02)) for p in first]] + rows
    c = col or shade(seed=seed, ao_y=(rows[-1][0].y, .12))
    if "Leg" in part:
        # the inner side darker: two legs side by side on a blocky body read as two
        base = c
        def c(p, k, base=base):
            g = base(p, k)
            d = .3 * max(0.0, min(1.0, (-p.x - S.x * .25) / (S.x * .3)))
            return tuple(max(.45, x - d) for x in g)
    loft(pc, rows, c, cap0=False, cap1=False)
    return rows


def ribbed(pc, part, y0, y1, pad=.09, ribs=6, depth=.05, rings_per=3, col=None, spiral=0.0, seed=0.0):
    """Wraps, leg warmers, rolled bands: bulging rings (spiral>0: a bandage
    wound round, its turns shifting with the angle).
    (26/11, passe 2: « les bandages rendent mal » — in the game, on François's avatar, the
    wraps read as a stack of white plates and the hand as a mitten) A bandage (spiral>0) is now
    a smooth sleeve close to the skin: fine rows, a bulge of a few thousandths, the strips told
    by a soft shading and a thin seam where each turn overlaps the last, the ends drawn in so
    no rim stands proud."""
    S = size(part)
    pad *= FIT
    a0 = (S.x / 2 + pad) / K
    b0 = (S.z / 2 + pad) / K
    bandage = spiral > 0
    if bandage:   # (26/11, seen in the game: still a stack of plates) fewer, steeper strips
        depth = 0.0
        ribs = max(3, int(round(ribs * .55)))
        spiral = 2.2
        rings_per = max(rings_per, 8)
    n = ribs * rings_per + 1
    rows = []
    for k in range(n):
        u = k / (n - 1)
        y = S.y / 2 - lerp(y0, y1, u) * S.y
        end = min(u, 1 - u) * (n - 1) / max(1, rings_per)   # in turns from the nearer end
        draw = (.35 + .65 * min(1.0, end)) if bandage else 1.0
        ring = []
        for i in range(SEG):
            t = 2 * math.pi * i / SEG
            ph = u * ribs + spiral * t / (2 * math.pi)
            if bandage:   # flat strips, a slight lip where a turn lies over the one before
                f = ph % 1.0
                bulge = .004 * (f ** 2) * draw + .002 * noise.noise(Vector((t, y * 3, seed)))
                bulge -= pad * (1 - draw) * .9 / K
            else:
                bulge = depth * (.5 - .5 * math.cos(2 * math.pi * ph)) + .008 * noise.noise(Vector((t, y * 3, seed)))
            c, s = math.cos(t), math.sin(t)
            x = (a0 + bulge) * math.copysign(abs(c) ** .125, c)
            z = (b0 + bulge) * math.copysign(abs(s) ** .125, s)
            ring.append(Vector((x, y, z)))
        rows.append(ring)

    def c(p, ri):
        u = ri / (n - 1)
        t = math.atan2(p.z, p.x)
        ph = (u * ribs + spiral * t / (2 * math.pi)) % 1.0
        if bandage:   # the strip pale and even, a thin shadow at the seam
            g = .96 - .05 * ph - (.09 if ph < .05 else 0.0)
            return (g, g, g)
        g = .74 + .26 * math.sin(math.pi * ph)
        return (g, g, g)
    loft(pc, rows, col or c, cap0=False, cap1=False)


def collar(pc, part, h=.32, open_front=0.0, flare=.1, thick=.05, col=None, neck=(.64, .6), lean=0.0):
    """A stand-up collar on the torso's top: a ring round the neck, rising h
    and flaring; open_front (radians) leaves a V at the front."""
    S = size(part)
    top = S.y / 2
    rows = []
    n = SEG
    for k, (dy, fl) in enumerate(((-.05, -.02), (0, 0), (h * .5, flare * .4), (h, flare), (h + .02, flare + thick * .6))):
        ring = []
        for i in range(n):
            t = -math.pi / 2 + open_front / 2 + (2 * math.pi - open_front) * i / (n - 1)
            c, s = math.cos(t), math.sin(t)
            a, b = neck[0] + fl, neck[1] + fl   # absolute half axes: round the head's base (1.2 wide)
            x = a * math.copysign(abs(c) ** .5, c)
            z = b * math.copysign(abs(s) ** .5, s) + lean * dy
            ring.append(Vector((x, top + dy, z)))
        rows.append(ring)
    # the inner face (thickness), back down
    inner = [[Vector((p.x * (1 - thick / max(.1, abs(p.x) + abs(p.z))), p.y, p.z * (1 - thick / max(.1, abs(p.x) + abs(p.z))))) for p in r] for r in reversed(rows[1:4])]
    loft(pc, rows + inner, col or shade(.95, .05), cap0=False, cap1=False, closed=open_front == 0)


def flap(pc, part, x0, x1, y_top, length, z_side, pad=.08, flare=.25, folds=.03, rows=8, seed=0.0, col=None, hem_cut=None):
    """A hanging panel (coat tails, a robe's skirt) from the bottom of a part:
    front (z_side=-1) or back (+1), between x0 and x1 (fractions -1..1 of the
    half width), falling `length` below y_top (fraction from the top)."""
    S = size(part)
    y0 = S.y / 2 - y_top * S.y
    a = (S.x / 2 + pad)
    zb = z_side * (S.z / 2 + pad)
    cols = 14
    grid = []
    for k in range(rows):
        u = k / (rows - 1)
        y = y0 - u * length
        row = []
        for i in range(cols):
            v = i / (cols - 1)
            x = lerp(x0, x1, v) * a * (1 + flare * u)
            z = zb + z_side * (flare * .5 * u) + z_side * folds * noise.noise(Vector((x * 2 + seed, y * 2, 0))) * (1 + 3 * u)
            if hem_cut:
                y_eff = y - hem_cut(v) * u
            else:
                y_eff = y
            row.append(Vector((x, y_eff, z)))
        grid.append(row)
    # a little thickness: the same grid pushed in
    loft(pc, grid, col or shade(.9, .1, seed, ao_y=(y0, .15)), cap0=False, cap1=False, closed=False)
    back = [[Vector((p.x, p.y, p.z - z_side * .07)) for p in reversed(r)] for r in grid]
    loft(pc, back, col or shade(.8, .05, seed), cap0=False, cap1=False, closed=False)


def box(pc, c, half, col):
    """A small box (pockets, plates, buckles)."""
    cx, cy, cz = c
    hx, hy, hz = half
    rings = []
    for y in (cy + hy, cy - hy):
        rings.append([Vector((cx + sx * hx, y, cz + sz * hz)) for sx, sz in ((1, 1), (1, -1), (-1, -1), (-1, 1))])
    loft(pc, rings, col, cap0=True, cap1=True)


def plate(pc, part, y0, y1, pad, arc=(-.65, .65), thick=.06, col=None, front=True):
    """A rigid curved plate over the front of a part (guards, breastplates)."""
    S = size(part)
    a = (S.x / 2 + pad) / K
    b = (S.z / 2 + pad) / K
    rows = []
    n = 16
    for y in (S.y / 2 - y0 * S.y, S.y / 2 - y1 * S.y):
        for r in (1.0, 1.0 + thick / max(a, b)):
            ring = []
            for i in range(n):
                t = (-math.pi / 2 if front else math.pi / 2) + lerp(arc[0], arc[1], i / (n - 1)) * math.pi / 2
                c, s = math.cos(t), math.sin(t)
                ring.append(Vector((a * r * math.copysign(abs(c) ** .125, c), y, b * r * math.copysign(abs(s) ** .125, s))))
            rows.append(ring)
    outer = [rows[1], rows[3]]
    inner = [rows[0], rows[2]]
    g = col or (lambda p, k: (.95, .95, .95))
    loft(pc, outer, g, cap0=False, cap1=False, closed=False)
    loft(pc, [list(reversed(inner[1])), list(reversed(inner[0]))], g, cap0=False, cap1=False, closed=False)
    for edge in (0, n - 1):
        loft(pc, [[rows[0][edge], rows[1][edge]], [rows[2][edge], rows[3][edge]]], g, cap0=False, cap1=False, closed=False)
    loft(pc, [[rows[0][i], rows[1][i]] for i in range(n)], g, cap0=False, cap1=False, closed=False)
    loft(pc, [[rows[3][i], rows[2][i]] for i in range(n)], g, cap0=False, cap1=False, closed=False)


def sandal(pcs, part):
    """The ninja sandal: a sole under the foot, a strap over the toes' root
    and one round the heel and up to the ankle (the toes stay bare)."""
    S = size(part)
    sole = pcs("Sandal")
    y = -S.y / 2
    rows = []
    for dy, grow in ((-.13, 0.0), (-.05, .03), (0.0, .0)):
        rows.append(section(S.x / 2 / K + .04 + grow, S.z / 2 / K + .12 + grow, n=SEG, y=y + dy))
    for r in rows:
        for p in r:
            p.z -= .06          # the toe end a little longer
    loft(sole, rows, shade(.7, .06), cap0=True, cap1=True)
    strap = pcs("Sandal")
    shell(strap, part, .1, .55, pad=.035, folds=.004, rings=3, hem=False, col=shade(.9, .04), scale_z=1.0)


def mirror(pc):
    out = Piece(pc.name, pc.mat, pc.flat, pc.alpha, pc.reflect)
    out.v = [Vector((-v.x, v.y, v.z)) for v in pc.v]
    out.c = list(pc.c)
    out.f = [tuple(reversed(f)) for f in pc.f]
    return out


# ---------------------------------------------------------------- outfits
# Each builder returns [(part, slot, Piece)] in the Roblox frame of the part.
# `both(fn, side_part)` builds a right-side piece and mirrors it to the left.

class Out:
    def __init__(self):
        self.items = []

    def add(self, part, slot, mat="Fabric", name=None):
        pc = Piece(name or slot, mat)
        self.items.append((part, slot, pc))
        return pc

    def both(self, part, slot, build, mat="Fabric"):
        """build(pc, 'Right'+part) for the right; the left is its mirror."""
        pc = self.add("Right" + part, slot, mat)
        build(pc, "Right" + part)
        left = mirror(pc)
        self.items.append(("Left" + part, slot, left))
        return pc


# ---- (23/11, passe commune 1: « les habits du début sont moches et ne rendent pas bien sur le
# perso ») The starting pieces rebuilt with a shape: a wrapped jacket crossed by a dark lapel,
# a wide obi knotted at the side, kimono sleeves with a cuff, short skirts that swing with the
# thighs; baggy trousers bloused into wrapped shins; sandals with a thick sole.
def lapel(o, slot, width=.34, raise_=.035):
    """The crossed front of a wrapped jacket: a band from the right of the neck down to the
    left of the waist (left over right), and its continuation round the back of the neck."""
    S = size("UpperTorso")
    zf = -(S.z / 2 + .07) / K - raise_
    pts = [Vector((lerp(-.32, .62, k / 11), S.y / 2 + .02 - k / 11 * S.y * .9, zf)) for k in range(12)]
    pc = o.add("UpperTorso", slot, name="Lapel")
    rows = [[p + Vector((-width / 2, 0, .02)) for p in pts], [p + Vector((-width / 2 + .02, 0, -.015)) for p in pts],
            [p + Vector((width / 2 - .02, 0, -.015)) for p in pts], [p + Vector((width / 2, 0, .02)) for p in pts]]
    loft(pc, rows, shade(.95, .04), cap0=True, cap1=True, closed=False)
    neck = o.add("UpperTorso", slot, name="NeckBand")
    collar(neck, "UpperTorso", h=.1, open_front=1.5, flare=.03, thick=.04, neck=(.66, .6))
    return pc


def obi(o, slot, knot_side=1):
    """A wide sash: a band over the waist (the torso's bottom and the hips' top), a flat knot
    on one side and its two short tails."""
    up = o.add("UpperTorso", slot, name="Obi")
    ribbed(up, "UpperTorso", .8, 1.03, pad=.13, ribs=1, depth=.012, rings_per=4)
    lo = o.add("LowerTorso", slot, name="ObiLow")
    ribbed(lo, "LowerTorso", -.1, .5, pad=.15, ribs=1, depth=.012, rings_per=4)
    S = size("LowerTorso")
    knot = o.add("LowerTorso", slot, name="Knot")
    box(knot, (knot_side * .62, .12, -(S.z / 2 + .2)), (.16, .13, .05), shade(.9, .04))
    for dx, ln in ((-.06, .55), (.08, .42)):
        tail = o.add("LowerTorso", slot, name="ObiTail")
        box(tail, (knot_side * .62 + dx, .1 - ln / 2, -(S.z / 2 + .19)), (.07, ln / 2, .02), shade(.85, .05))


def kimono_sleeve(o, slot, trim, length=.62):
    o.both("UpperArm", slot, lambda pc, part: shell(pc, part, -.05, length, pad=.11, flare1=.1, folds=.03, seed=2))
    if trim:
        o.both("UpperArm", trim, lambda pc, part: ribbed(pc, part, length - .1, length + .02, pad=.22, ribs=1, depth=.012, rings_per=3))


def tunic_body(o, slot="Cloth", lower_h=.6, collar_v=True, sleeve=.55, seed=0.0, trim="Trim", belt="Belt", skirt=True):
    pc = o.add("UpperTorso", slot)
    shell(pc, "UpperTorso", .0, 1.0, pad=.07, flare1=.03, folds=.025, seed=seed, hem=False)
    if collar_v and trim:
        lapel(o, trim)
    lo = o.add("LowerTorso", slot)
    shell(lo, "LowerTorso", -.1, max(lower_h, 1.0) if skirt else lower_h + .05, pad=.09, flare1=.06, folds=.02, seed=seed + 1,
          hem=not skirt)
    if skirt:   # the jacket's skirt: a short panel before and behind each thigh, swinging with it
        thigh_tails(o, slot, .62, y_top=-.06, pad=.12, flare=.22, folds=.025, seed=seed + 3)
    if belt:
        obi(o, belt)
    if sleeve:
        kimono_sleeve(o, slot, trim, length=sleeve + .07)
    return pc


def item_tunic():
    o = Out()
    tunic_body(o)
    return o.items


def item_high_collar():
    o = Out()
    pc = o.add("UpperTorso", "Cloth")
    shell(pc, "UpperTorso", 0, 1, pad=.07, folds=.02, hem=False)
    lo = o.add("LowerTorso", "Cloth")
    shell(lo, "LowerTorso", -.1, 1.0, pad=.09, flare1=.05, hem=False)
    thigh_tails(o, "Cloth", .5, y_top=-.06, pad=.12, flare=.2, folds=.02, seed=5)
    o.both("UpperArm", "Cloth", lambda pc, part: shell(pc, part, -.04, .5, pad=.09, flare1=.05))
    col = o.add("UpperTorso", "Collar")
    collar(col, "UpperTorso", h=.34, flare=.08)
    obi(o, "Belt", knot_side=-1)
    return o.items


def item_sleeveless():
    o = Out()
    pc = o.add("UpperTorso", "Cloth")
    shell(pc, "UpperTorso", .02, 1, pad=.06, folds=.02, hem=False, scale_x=.99)
    lapel(o, "Cloth", width=.24)
    lo = o.add("LowerTorso", "Cloth")
    shell(lo, "LowerTorso", -.1, .9, pad=.08, hem=False)
    obi(o, "Belt")
    return o.items


def item_pants():
    o = Out()
    lo = o.add("LowerTorso", "Cloth")
    shell(lo, "LowerTorso", .2, 1.05, pad=.08, hem=False)
    # baggy thighs, bloused over the knee, then the shin wrapped tight down to the ankle
    o.both("UpperLeg", "Cloth", lambda pc, part: shell(pc, part, -.05, 1.04, pad=.13, flare1=.06, folds=.04, hem=False))
    o.both("LowerLeg", "Cloth", lambda pc, part: shell(pc, part, -.04, .52, pad=.2, flare0=.0, flare1=-.08, folds=.05, hem=False))
    o.both("LowerLeg", "Tie", lambda pc, part: ribbed(pc, part, .48, .93, pad=.05, ribs=6, depth=.022, spiral=1.0))
    return o.items


def item_shorts():
    o = Out()
    lo = o.add("LowerTorso", "Cloth")
    shell(lo, "LowerTorso", .2, 1.05, pad=.08, hem=False)
    o.both("UpperLeg", "Cloth", lambda pc, part: shell(pc, part, -.05, .7, pad=.13, flare1=.08, folds=.035))
    o.both("LowerLeg", "Wrap", lambda pc, part: ribbed(pc, part, .08, .93, pad=.04, ribs=10, depth=.022, spiral=1.0))
    return o.items


def item_arm_wraps():
    o = Out()
    # (19/11, vague 2: « trop épaisses ») close to the skin: a third of the old pad and depth
    o.both("LowerArm", "Wrap", lambda pc, part: ribbed(pc, part, .12, .98, pad=.01, ribs=10, depth=.01, spiral=1.0))
    # (26/11) round the palm only, the fingers free (a long hand made it a mitten)
    o.both("Hand", "Wrap", lambda pc, part: ribbed(pc, part, -.04, .42, pad=.008, ribs=2, depth=.006, spiral=1.0))
    return o.items


def item_arm_guards():
    # (26/11, François in the game: « les protège-bras flottent aux poignets ») the plate on the
    # skin (it stood .09 off it, with straps sticking out behind), wrapping further round, its
    # straps under its edges
    o = Out()
    o.both("LowerArm", "Guard", lambda pc, part: plate(pc, part, .2, .86, .03, arc=(-.85, .85), thick=.035), mat="Metal")
    o.both("LowerArm", "Strap", lambda pc, part: (ribbed(pc, part, .28, .37, pad=.018, ribs=1, depth=.004, rings_per=3),
                                                  ribbed(pc, part, .7, .79, pad=.018, ribs=1, depth=.004, rings_per=3)))
    return o.items


def item_sandals():
    o = Out()
    for side in ("Right", "Left"):
        def pcs(slot, side=side):
            return o.add(side + "Foot", slot)
        sandal(pcs, side + "Foot")
    o.both("LowerLeg", "Sandal", lambda pc, part: ribbed(pc, part, .86, 1.0, pad=.06, ribs=1, depth=.015, rings_per=4))
    return o.items


# ---- the masters

def zipper(o, part, slot, y0=0.0, y1=1.0, pad=.07):
    pc = o.add(part, slot, name="Zip")
    S = size(part)
    z = -(S.z / 2 + pad) / K - .015
    rows = []
    for dz in (0, -.025, 0):
        pass
    left, mid, right = [], [], []
    for k in range(12):
        y = S.y / 2 - lerp(y0, y1, k / 11) * S.y
        left.append(Vector((-.05, y, z + .005)))
        mid.append(Vector((0, y, z - .02)))
        right.append(Vector((.05, y, z + .005)))
    loft(pc, [left, mid, right], shade(.88, .05), cap0=False, cap1=False, closed=False)
    return pc


def item_naruto():
    o = Out()
    up = o.add("UpperTorso", "Orange")
    shell(up, "UpperTorso", .0, 1.0, pad=.09, flare1=.03, folds=.03, hem=False)
    yoke = o.add("UpperTorso", "Blue", name="Yoke")
    shell(yoke, "UpperTorso", -.02, .34, pad=.17, folds=0.0, hem=False)
    zipper(o, "UpperTorso", "White", .0, 1.0, pad=.09)
    col = o.add("UpperTorso", "White", name="Collar")
    # (20/11, OUTILLEUR on 7 bodies: « le col monte jusqu'à la bouche ») lower, closer to the neck
    collar(col, "UpperTorso", h=.24, flare=.08, thick=.05, neck=(.62, .58))
    lo = o.add("LowerTorso", "Orange")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.1, hem=False, folds=.03)
    o.both("UpperArm", "Orange", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.1, folds=.03, hem=False))
    o.both("UpperArm", "Blue", lambda pc, part: shell(pc, part, -.06, .26, pad=.12, folds=.01, hem=False))
    o.both("LowerArm", "Orange", lambda pc, part: shell(pc, part, -.02, .88, pad=.11, flare1=.05, folds=.035))
    o.both("UpperLeg", "Orange", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.12, folds=.04, hem=False))
    o.both("LowerLeg", "Orange", lambda pc, part: shell(pc, part, -.02, .68, pad=.13, flare1=.08, folds=.045))
    o.both("LowerLeg", "White", lambda pc, part: ribbed(pc, part, .6, .78, pad=.06, ribs=3, depth=.025, spiral=1.0))
    _feet(o, "Blue")
    holster(o, "White", "Blue")
    pouch = o.add("LowerTorso", "Blue", name="Pouch")   # (Part I) the tool pouch at the back of the belt
    box(pouch, (.35, -.02, (size("LowerTorso").z / 2 + .1) / K + .08), (.22, .16, .09), shade(.9, .05))
    return o.items


def thigh_tails(o, slot, length, y_top=-.08, pad=.1, flare=.16, folds=.03, seed=0, hem_cut=None, col=None, front=True, back=True):
    """(20/11, François: « elles ne suivent pas les mouvements ») A coat's tails, a robe's skirt:
    a panel in front and one behind EACH thigh, hanging `length` from its top, so they swing
    with the legs (one long panel from the hips stood still while the legs went through it)."""
    for zs in ((-1,) if front else ()) + ((1,) if back else ()):
        o.both("UpperLeg", slot, lambda pc, part, zs=zs: flap(pc, part, -1, 1, y_top, length, zs, pad=pad, flare=flare, folds=folds,
                                                             seed=seed + zs, hem_cut=hem_cut, col=col))


def holster(o, tape="Tape", pouch="Holster", side="Right"):
    """(20/11, references) The kunai holster on the thigh (Part I: Naruto, Sasuke, Neji wear it
    on the right): a white bandage round the thigh and the pouch strapped over it, on the
    outside. One side only: the slots Tape/Holster are the asymmetric ones (OutfitMeshes.spec)."""
    part = side + "UpperLeg"
    t = o.add(part, tape, name="HolsterTape")
    ribbed(t, part, .3, .52, pad=.14, ribs=3, depth=.015, spiral=1.0)
    h = o.add(part, pouch, name="Holster")
    S = size(part)
    sx = 1 if side == "Right" else -1
    x = sx * ((S.x / 2 + .07) / K + .06)
    box(h, (x, -.05, -.02), (.07, .24, .2), shade(.88, .05))
    box(h, (x + sx * .015, .14, -.02), (.075, .06, .21), shade(.96, .03))   # the flap
    box(h, (x + sx * .03, -.3, -.02), (.05, .06, .12), shade(.8, .04))     # the kunai's ring under it


def _feet(o, slot):
    for side in ("Right", "Left"):
        def pcs(s, side=side):
            return o.add(side + "Foot", slot)
        sandal(pcs, side + "Foot")
    o.both("LowerLeg", slot, lambda pc, part: ribbed(pc, part, .84, 1.0, pad=.04, ribs=1, depth=.015, rings_per=4))


def item_sasuke():
    o = Out()
    up = o.add("UpperTorso", "Navy")
    shell(up, "UpperTorso", .0, 1.0, pad=.07, folds=.02, hem=False)
    col = o.add("UpperTorso", "Navy", name="Collar")
    collar(col, "UpperTorso", h=.34, open_front=.9, flare=.09, thick=.05, neck=(.63, .59))
    lo = o.add("LowerTorso", "White")
    shell(lo, "LowerTorso", -.1, 1.05, pad=.08, hem=False)
    o.both("UpperArm", "Navy", lambda pc, part: shell(pc, part, -.05, .42, pad=.09, flare1=.05))
    # the arm warmers: elbow to wrist, loose, a ridge at each end
    o.both("LowerArm", "Wrap", lambda pc, part: shell(pc, part, -.06, .96, pad=.1, flare0=.03, flare1=.02, folds=.04, hem="both"))
    # (20/11, references) the arm warmers' blue rims at both ends
    o.both("LowerArm", "Navy", lambda pc, part: (ribbed(pc, part, -.04, .06, pad=.13, ribs=1, depth=.01, rings_per=3),
                                                ribbed(pc, part, .86, .96, pad=.13, ribs=1, depth=.01, rings_per=3)))
    o.both("UpperLeg", "White", lambda pc, part: shell(pc, part, -.05, .78, pad=.11, flare1=.07, folds=.035))
    # (20/11, references) Part I: bare shins (the wrapped shins were not his); the holster on the right thigh
    holster(o, "Wrap", "Navy")
    _feet(o, "Navy")
    return o.items


def item_lee():
    o = Out()
    up = o.add("UpperTorso", "Green")
    shell(up, "UpperTorso", -.04, 1.0, pad=.04, folds=.01, hem=False)
    lo = o.add("LowerTorso", "Green")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.05, hem=False, folds=.01)
    belt = o.add("LowerTorso", "Red")
    ribbed(belt, "LowerTorso", .0, .5, pad=.09, ribs=1, depth=.025, rings_per=6)
    # (20/11, references) the red belt IS his forehead protector: its metal plate in front
    plt = o.add("LowerTorso", "Plate", mat="Metal", name="Plate")
    box(plt, (0, .0, -(size("LowerTorso").z / 2 + .09) / K - .05), (.27, .1, .03), shade(.95, .03))
    for x in (-.22, .22):
        box(plt, (x, .0, -(size("LowerTorso").z / 2 + .09) / K - .085), (.025, .025, .01), shade(.7, .03))
    o.both("UpperArm", "Green", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.05, folds=.01, hem=False))
    o.both("LowerArm", "Green", lambda pc, part: shell(pc, part, -.02, .55, pad=.05, folds=.01, hem=False))
    o.both("LowerArm", "Wrap", lambda pc, part: ribbed(pc, part, .5, .99, pad=.01, ribs=6, depth=.01, spiral=1.0))
    o.both("UpperLeg", "Green", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.05, folds=.01, hem=False))
    o.both("LowerLeg", "Green", lambda pc, part: shell(pc, part, -.02, .2, pad=.05, folds=.01, hem=False))
    # the leg warmers: thick, rolled, slumping on the ankle
    o.both("LowerLeg", "Orange", lambda pc, part: ribbed(pc, part, .08, .95, pad=.2, ribs=6, depth=.045))
    _feet(o, "Green")
    return o.items


def item_neji():
    o = Out()
    up = o.add("UpperTorso", "Robe")
    shell(up, "UpperTorso", .0, 1.0, pad=.1, flare1=.06, folds=.04, hem=False)
    trim = o.add("UpperTorso", "Robe", name="Overlap")
    S = size("UpperTorso")
    pts = [Vector((lerp(-.25, .5, k / 9), S.y / 2 - k / 9 * S.y * .9, -(S.z / 2 + .1) / K - .015)) for k in range(10)]
    loft(trim, [pts, [p + Vector((.05, 0, -.03)) for p in pts], [p + Vector((.12, 0, 0)) for p in pts]], shade(.8, .04), cap0=False, cap1=False, closed=False)
    lo = o.add("LowerTorso", "Robe")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.12, flare1=.06, hem=False, folds=.03)
    thigh_tails(o, "Robe", 1.3, pad=.1, flare=.16)
    # long loose sleeves to the wrist
    o.both("UpperArm", "Robe", lambda pc, part: shell(pc, part, -.06, 1.02, pad=.12, flare1=.06, folds=.045, hem=False))
    o.both("LowerArm", "Robe", lambda pc, part: shell(pc, part, -.02, .62, pad=.18, flare0=.06, flare1=.16, folds=.05))
    o.both("UpperLeg", "Dark", lambda pc, part: shell(pc, part, -.05, .75, pad=.1, flare1=.06, folds=.03))
    o.both("LowerLeg", "Wrap", lambda pc, part: ribbed(pc, part, .05, .6, pad=.035, ribs=6, depth=.022, spiral=1.0))
    holster(o, "Wrap", "Dark")   # (20/11, references) the bandaged right thigh and its holster
    _feet(o, "Dark")
    return o.items


def item_gaara():
    o = Out()
    up = o.add("UpperTorso", "Coat")
    shell(up, "UpperTorso", .0, 1.0, pad=.1, flare1=.04, folds=.035, hem=False)
    col = o.add("UpperTorso", "Coat", name="Collar")
    collar(col, "UpperTorso", h=.16, flare=.05, neck=(.64, .6))
    # the strap across the chest, right shoulder to left hip, front and back
    sash = o.add("UpperTorso", "Sash")
    S = size("UpperTorso")
    a = (S.x / 2 + .14) / K
    b = (S.z / 2 + .14) / K
    rows = []
    for w in (-.16, .16):
        ring = []
        for i in range(SEG):
            t = 2 * math.pi * i / SEG
            c, s = math.cos(t), math.sin(t)
            x = a * math.copysign(abs(c) ** .125, c)
            z = b * math.copysign(abs(s) ** .125, s)
            y = x * .62 + w + .05 * math.sin(t * 3)
            ring.append(Vector((x, y, z)))
        rows.append(ring)
    loft(sash, rows, shade(.9, .06), cap0=False, cap1=False)
    # (20/11, references) Part I: his forehead protector rides on the gourd's strap, over the chest
    plt = o.add("UpperTorso", "Plate", mat="Metal", name="Plate")
    box(plt, (-.36, -.2, -b - .05), (.21, .09, .03), shade(.95, .03))
    lo = o.add("LowerTorso", "Coat")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.12, flare1=.08, hem=False, folds=.03)
    thigh_tails(o, "Coat", 1.6, pad=.11, flare=.18, seed=2)
    o.both("UpperArm", "Coat", lambda pc, part: shell(pc, part, -.06, 1.02, pad=.1, folds=.035, hem=False))
    o.both("LowerArm", "Coat", lambda pc, part: shell(pc, part, -.02, .84, pad=.11, flare1=.05, folds=.04))
    o.both("UpperLeg", "Dark", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.1, folds=.03, hem=False))
    o.both("LowerLeg", "Dark", lambda pc, part: shell(pc, part, -.02, .78, pad=.11, flare1=.04, folds=.035))
    _feet(o, "Dark")
    return o.items


def flak_vest(o, slot, collar_slot=None):
    vest = o.add("UpperTorso", slot, name="Vest")
    shell(vest, "UpperTorso", .02, 1.0, pad=.16, flare1=.02, folds=.012, hem=True, col=shade(.9, .05))
    S = size("UpperTorso")
    z = -(S.z / 2 + .16) / K - .03
    pockets = o.add("UpperTorso", slot, name="Pockets")
    for x in (-.62, -.22, .22, .62):
        box(pockets, (x, -.22, z - .05), (.16, .22, .06), shade(.84, .04))
        box(pockets, (x, .02, z - .07), (.17, .05, .07), shade(.95, .03))
    col = o.add("UpperTorso", collar_slot or slot, name="Collar")
    collar(col, "UpperTorso", h=.22, flare=.08, thick=.06, neck=(.66, .61))
    return vest


def item_kakashi():
    o = Out()
    up = o.add("UpperTorso", "Navy")
    shell(up, "UpperTorso", .0, 1.0, pad=.06, folds=.02, hem=False)
    flak_vest(o, "Vest")
    lo = o.add("LowerTorso", "Navy")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.08, hem=False)
    o.both("UpperArm", "Navy", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.07, folds=.025, hem=False))
    o.both("LowerArm", "Navy", lambda pc, part: shell(pc, part, -.02, .96, pad=.07, folds=.025))
    o.both("UpperLeg", "Navy", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.08, folds=.03, hem=False))
    o.both("LowerLeg", "Navy", lambda pc, part: shell(pc, part, -.02, .5, pad=.09, folds=.03, hem=False))
    o.both("LowerLeg", "Wrap", lambda pc, part: ribbed(pc, part, .45, .85, pad=.07, ribs=4, depth=.022, spiral=1.0))
    _feet(o, "Navy")
    # (20/11, references) his fingerless gloves with a metal plate on the back of the hand,
    # and the mask over the lower face
    o.both("Hand", "Navy", lambda pc, part: shell(pc, part, -.08, .6, pad=.02, folds=.002, hem=True, rings=4))
    o.both("Hand", "Guard", lambda pc, part: box(pc, (0, .02, -(size(part).z / 2 + .02) / K - .02), (.26, .07, .025), shade(.95, .02)), mat="Metal")
    import wardrobe_models as W
    for part, slot, pc in W.item_mask_cloth():
        o.items.append((part, "Navy", pc))
    return o.items


def item_itachi():
    o = Out()
    up = o.add("UpperTorso", "Black")
    shell(up, "UpperTorso", .02, 1.0, pad=.05, folds=.012, hem=False)
    bp = o.add("UpperTorso", "Grey", name="Breastplate")
    plate(bp, "UpperTorso", .04, .72, .12, arc=(-.95, .95), thick=.07)
    back = o.add("UpperTorso", "Grey", name="Backplate")
    plate(back, "UpperTorso", .04, .72, .12, arc=(-.95, .95), thick=.07, front=False)
    straps = o.add("UpperTorso", "Black", name="Straps")
    ribbed(straps, "UpperTorso", .74, .84, pad=.14, ribs=1, depth=.01, rings_per=3)
    lo = o.add("LowerTorso", "Black")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.07, hem=False)
    o.both("LowerArm", "Guard", lambda pc, part: plate(pc, part, .15, .85, .09, arc=(-.8, .8), thick=.05), mat="Metal")
    o.both("LowerArm", "Black", lambda pc, part: shell(pc, part, .1, .92, pad=.05, folds=.01, hem=False))
    o.both("UpperLeg", "Black", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.08, folds=.03, hem=False))
    o.both("LowerLeg", "Black", lambda pc, part: shell(pc, part, -.02, .85, pad=.09, folds=.03))
    _feet(o, "Black")
    return o.items


FLAME = lambda v: .55 * (.5 + .5 * math.sin(v * math.pi * 14)) ** 2


def item_minato():
    o = Out()
    up = o.add("UpperTorso", "Navy")
    shell(up, "UpperTorso", .0, 1.0, pad=.06, folds=.02, hem=False)
    flak_vest(o, "Vest")
    # the short white coat over it: open in front, short wide sleeves, hem of flames
    coat = o.add("UpperTorso", "Coat", name="Coat")
    S = size("UpperTorso")
    a = (S.x / 2 + .24) / K
    b = (S.z / 2 + .26) / K
    rows = []
    for k in range(8):
        y = S.y / 2 - k / 7 * S.y * 1.02
        ring = []
        for i in range(SEG - 6):
            t = -math.pi / 2 + .5 + (2 * math.pi - 1.0) * i / (SEG - 7)
            c, s = math.cos(t), math.sin(t)
            d = .03 * noise.noise(Vector((t * 2, y * 3, 0)))
            ring.append(Vector(((a + d) * math.copysign(abs(c) ** .125, c), y, (b + d) * math.copysign(abs(s) ** .125, s))))
        rows.append(ring)
    loft(coat, rows, shade(.95, .05), cap0=False, cap1=False, closed=False)
    lo = o.add("LowerTorso", "Navy")
    shell(lo, "LowerTorso", -.15, 1.05, pad=.08, hem=False)
    # the coat hangs open in front: two front panels at the sides, one at the back
    # (20/11) the coat's skirt hangs from each thigh (it follows the legs), its flames at the hem
    thigh_tails(o, "Coat", 1.0, y_top=-.15, pad=.2, flare=.12, seed=3, hem_cut=FLAME)
    thigh_tails(o, "Flame", .32, y_top=.672, pad=.21, flare=.03, seed=3, hem_cut=lambda v: -FLAME(v) * 1.2, col=shade(.95, .03))
    o.both("UpperArm", "Coat", lambda pc, part: shell(pc, part, -.08, .55, pad=.16, flare1=.1, folds=.03))
    o.both("UpperArm", "Navy", lambda pc, part: shell(pc, part, .4, 1.02, pad=.06, folds=.02, hem=False))
    o.both("LowerArm", "Navy", lambda pc, part: shell(pc, part, -.02, .96, pad=.07, folds=.025))
    o.both("UpperLeg", "Navy", lambda pc, part: shell(pc, part, -.05, 1.02, pad=.08, folds=.03, hem=False))
    o.both("LowerLeg", "Navy", lambda pc, part: shell(pc, part, -.02, .6, pad=.09, folds=.03, hem=False))
    o.both("LowerLeg", "Wrap", lambda pc, part: ribbed(pc, part, .55, .85, pad=.07, ribs=3, depth=.022, spiral=1.0))
    _feet(o, "Navy")
    return o.items


# model name -> builder; Shop item id -> model name (colour variants share one)
MODELS = {
    "Tunic": item_tunic, "HighCollar": item_high_collar, "Sleeveless": item_sleeveless,
    "Pants": item_pants, "Shorts": item_shorts, "ArmWraps": item_arm_wraps, "ArmGuards": item_arm_guards,
    "Sandals": item_sandals,
    "Naruto": item_naruto, "Sasuke": item_sasuke, "Lee": item_lee, "Neji": item_neji, "Gaara": item_gaara,
    "Kakashi": item_kakashi, "Itachi": item_itachi, "Minato": item_minato,
}
ITEMS = {
    "TopTunicNavy": "Tunic", "TopTunicBlack": "Tunic", "TopTunicGreen": "Tunic",
    "TopHighCollar": "HighCollar", "TopSleeveless": "Sleeveless",
    "BottomPantsDark": "Pants", "BottomPantsSand": "Pants", "BottomShorts": "Shorts",
    "ArmsWraps": "ArmWraps", "ArmsGuards": "ArmGuards",
    "FeetSandals": "Sandals", "FeetBlack": "Sandals",
    "SetNaruto": "Naruto", "SetSasuke": "Sasuke", "SetLee": "Lee", "SetNeji": "Neji", "SetGaara": "Gaara",
    "SetKakashi": "Kakashi", "SetItachi": "Itachi", "SetMinato": "Minato",
}
# Slots a model uses that Shared/Shop does not colour yet (DEV: add them).
NEW_SLOTS = {"Minato": {"Coat": (238, 236, 230), "Flame": (196, 48, 34), "Vest": (86, 98, 70)},
             "Lee": {"Wrap": (226, 222, 212)}}

# (19/11, vague 2) the wardrobe: many more pieces (tools/blender/wardrobe_models.py). Their
# items are catalogue entries (CATALOG: Shared/Catalog, DEV 2), not Shop items yet; each model's
# first colourway is its default (NewSlots), so a piece is never left without a colour.
import wardrobe_models  # noqa: E402
MODELS.update(wardrobe_models.MODELS)
CATALOG = wardrobe_models.CATALOG
for _id, (_kind, _model, _name, _cols) in CATALOG.items():
    NEW_SLOTS.setdefault(_model, dict(_cols))


# (20/11) the wardrobe's catalogue ids -> models; ids the catalogue already had keep their id
# (their cloth stand-in is replaced by the model: CapeTravel, BackScroll, MaskCloth)
WARDROBE_ITEMS = {k: v[1] for k, v in CATALOG.items()}
WARDROBE_ITEMS["CapeTravel"] = "CapeShort"
# (24/11) the village people's looks are models only, never Shop items (NPC_SETS below)
WARDROBE_ITEMS.update({k: k for k in wardrobe_models.SETS if k not in ("SetRogue",)})
# (the icon tool, tools/icons, reads ITEMS: every look with a model is there)
ITEMS.update(WARDROBE_ITEMS)


def _set_builder(set_id):
    """A set's pieces for the previews and the icons (never written: OutfitMeshes.Sets builds
    it at load), their colour slots prefixed by their model, as the catalogue colours them."""
    def build():
        out = []
        for m, _ in wardrobe_models.SETS[set_id][1]:
            out += [(part, m + slot, pc) for part, slot, pc in MODELS[m]()]
        return out
    return build


for _sid in wardrobe_models.SETS:
    MODELS[_sid] = _set_builder(_sid)
PRICE = {"top": 600, "bottom": 500, "arms": 350, "feet": 350, "headband": 800, "mask": 600, "cape": 900, "back": 700, "hair": 700}
# A set belongs to a kit (Shop.spec): the inspiration whose spirit it carries (my proposal, the DEV's call)
SET_KIT = {"SetEmberMonk": "Leaf", "SetMistHunter": "Mirage", "SetStormCourier": "Legion", "SetShadowScout": "Copycat",
           "SetLeafMedic": "GentleFist", "SetSandNomad": "Sand", "SetRogue": "Lion"}
# (24/11) the looks of the village's people, never in the shop (Shop.spec: every set is sold in
# Robux): modelled and exported (OutfitMeshes), left out of the Catalog
NPC_SETS = {"SetRogue"}
# Server/Outfit's cloth stand-ins (Shared/Catalog `pieces`), until the client has drawn the model
FALLBACK = {
    "top": lambda c: ['{on="UpperTorso",c="%s"}' % c, '{on="LowerTorso",c="%s",h=.6}' % c, '{on="UpperArm",c="%s",h=.55}' % c],
    "bottom": lambda c: ['{on="LowerTorso",c="%s",y0=.4,h=.6}' % c, '{on="UpperLeg",c="%s"}' % c, '{on="LowerLeg",c="%s"}' % c],
    "arms": lambda c: ['{on="LowerArm",kind="band",c="%s",y0=.15,h=.8}' % c],
    "feet": lambda c: ['{on="Foot",c="%s",pad=.05}' % c, '{on="LowerLeg",kind="band",c="%s",y0=.82,h=.18}' % c],
    "mask": lambda c: ['{on="Head",kind="shell",c="%s",y0=.5,h=.5,pad=.04}' % c],
    "hair": lambda c: ['{on="Head",kind="shell",c="%s",y0=.62,h=.4,pad=.06}' % c],
    "cape": lambda c: ['{on="UpperTorso",kind="cape",c="%s"}' % c],
    "back": lambda c: ['{on="UpperTorso",kind="scroll",c="%s"}' % c],
}
BEGIN, END = "\t-- BEGIN wardrobe (generated by tools/blender/outfit_models.py write: edit the generator)", "\t-- END wardrobe"


def write_catalog(path):
    """(20/11) The wardrobe's looks in Shared/Catalog: one generated block (between BEGIN and
    END), the ids the catalogue already had are left where they are. Ryō prices are proposals
    (the economy is the DEV's); a set is sold in Robux (SOON until its product exists)."""
    import re
    src = open(path).read()
    have = set(re.findall(r'\{id="(\w+)"', src.split(BEGIN)[0] + (src.split(END)[1] if END in src else "")))
    rows = []
    c = lambda cols: ",".join("%s={%d,%d,%d}" % (k, *v) for k, v in cols.items())
    for k, (kind, m, nm, cols) in CATALOG.items():
        if k in have:
            continue
        extra = ',model="%s"' % m if kind == "headband" else ""
        if kind == "headband" and "Plate" not in cols:
            cols = dict(cols, Plate=(200, 204, 210))  # (Server/Headband paints a plate on every band)
        first = next(iter(cols))
        pc = "" if kind == "headband" else ",\n\t\tpieces={%s}" % ",".join(FALLBACK[kind](first))
        rows.append('\t{id="%s",slot="%s",name="%s",ryo=%d,colors={%s}%s%s},' % (k, kind, nm.upper(), PRICE[kind], c(cols), extra, pc))
    for k, (nm, parts) in wardrobe_models.SETS.items():
        cols = {}
        for m, cm in parts:
            for sl, v in cm.items():
                cols[m + sl] = v
        top, low = parts[0][0] + next(iter(parts[0][1])), parts[1][0] + next(iter(parts[1][1]))
        pcs = FALLBACK["top"](top) + FALLBACK["bottom"](low)[1:]
        if k in NPC_SETS:
            continue
        sale = 'robux="%s"' % k
        rows.append('\t{id="%s",slot="set",kit="%s",name="%s",%s,colors={%s},\n\t\tpieces={%s}},' % (k, SET_KIT[k], nm.upper(), sale, c(cols), ",".join(pcs)))
    block = BEGIN + "\n" + "\n".join(rows) + "\n" + END
    if BEGIN in src:
        src = src.split(BEGIN)[0] + block + src.split(END)[1]
    else:
        i = src.rindex("}\n\nreturn Catalog")
        src = src[:i] + block + "\n" + src[i:]
    open(path, "w").write(src)
    print("catalogue:", len(rows), "wardrobe looks")


def to_blender_frame(pc):
    """Roblox frame (x, y up, z back) -> nd_mesh's Blender frame (x, -z, y)."""
    out = Piece(pc.name, pc.mat, pc.flat, pc.alpha, pc.reflect)
    out.v = [Vector((v.x, -v.z, v.y)) for v in pc.v]
    out.c, out.f = list(pc.c), list(pc.f)
    return out


def built(name):
    out = []
    for part, slot, pc in MODELS[name]():
        b = to_blender_frame(pc)
        outward(b)
        out.append((part, slot, b))
    return out


def write(dst, limit=110000):
    from nd_mesh import piece_luau, q
    chunks, cur, sizeb = [], [], 0
    report = []
    slots_of = {}
    for name in MODELS:
        if name in wardrobe_models.SETS:
            continue
        pieces = built(name)
        slots_of[name] = {sl for _, sl, _ in pieces}
        tris = sum(len(p.tris()) for _, _, p in pieces)
        report.append((name, len(pieces), tris))
        for k, (part, slot, pc) in enumerate(pieces):
            # (a holster is worn on one side: its name says so, OutfitMeshes.spec lets it be)
            pc.name = "%s_%s_%d%s" % (part, slot, k, "_Holster" if pc.name.startswith("Holster") else "")
            text = "\t{%s,%s,%s,%s}," % (q(name), q(part), q(slot), piece_luau(pc))
            if cur and sizeb + len(text) > limit:
                chunks.append(cur); cur, sizeb = [], 0
            cur.append(text); sizeb += len(text)
    if cur:
        chunks.append(cur)
    # every colour slot a catalogue entry or a set wears has its colour
    for k, (kind, m, nm, cols) in CATALOG.items():
        assert slots_of[m] <= set(cols), (k, sorted(slots_of[m] - set(cols)))
    for k, (nm, parts) in wardrobe_models.SETS.items():
        for m, cols in parts:
            assert slots_of[m] <= set(cols), (k, m, sorted(slots_of[m] - set(cols)))
    head = "-- Generated by tools/blender/outfit_models.py. Do not edit: re-run the script.\n"
    for f in os.listdir(dst):
        if f.startswith("OutfitMeshData") and f.endswith(".luau"):
            os.remove(os.path.join(dst, f))
    for i, c in enumerate(chunks, 1):
        with open(os.path.join(dst, "OutfitMeshData%d.luau" % i), "w") as fh:
            fh.write(head + "-- {model, body part, colour slot, piece}, in order.\nreturn {\n" + "\n".join(c) + "\n}\n")
    ref = ",".join("%s=Vector3.new(%g,%g,%g)" % (k, *v) for k, v in REF.items())
    items_all = dict(ITEMS)   # (a set is its own model, built at load: OutfitMeshes.Sets)
    items = ",".join("%s=%s" % (k, q(v)) for k, v in items_all.items())
    sets_lua = ",".join("%s={%s}" % (k, ",".join(q(m) for m, _ in parts)) for k, (nm, parts) in wardrobe_models.SETS.items())
    sets = ",\n\t".join("%s={kind=\"set\",name=%s,parts={%s}}" % (k, q(nm), ",".join("{model=%s,colors={%s}}" % (q(m), ",".join("%s={%d,%d,%d}" % (sl, *c) for sl, c in cols.items())) for m, cols in parts))
                          for k, (nm, parts) in wardrobe_models.SETS.items())
    catalog = ",\n\t".join("%s={kind=%s,model=%s,name=%s,colors={%s}}" % (k, q(kind), q(m), q(nm), ",".join("%s={%d,%d,%d}" % (s, *c) for s, c in cols.items()))
                             for k, (kind, m, nm, cols) in CATALOG.items())
    new_slots = ",".join("%s={%s}" % (m, ",".join("%s={%d,%d,%d}" % (s, *c) for s, c in v.items())) for m, v in NEW_SLOTS.items())
    with open(os.path.join(dst, "OutfitMeshes.luau"), "w") as fh:
        fh.write(head + """-- (DEC-040) The ninja outfit's modelled pieces (Server/Outfit): each Shop item
-- (Items: id -> model) is a list of pieces, one per body part and colour slot.
-- A piece is in MeshKit's packed format, modelled round its body part's
-- centre on the standard R15 part size Ref[part]: scale it by body.Size/Ref,
-- weld it at body.CFrame*CFrame.new(o*scale); its Color is the item's
-- colors[slot] (the vertex colours are shading: they multiply).
--   OutfitMeshes.Models[model] = {{on=<body part>, slot=<colour slot>, <piece>}, ...}
local OutfitMeshes={}
OutfitMeshes.Ref={%s}
OutfitMeshes.Items={%s}
-- Slots these models use that Shared/Shop has no colour for yet (a default)
OutfitMeshes.NewSlots={%s}
-- (19/11, vague 2) the wardrobe's new pieces, for Shared/Catalog (DEV 2): id -> its kind (top,
-- bottom, arms, feet, headband, mask, cape, back, set), its model, its name, its colours by slot.
-- Masks, headbands and hoods sit on the Head (Ref.Head), capes and back items on the torso.
OutfitMeshes.Catalog={
	%s,
	-- the six invented outfits: bundles of the pieces above, each in the set's colours
	%s,
}
OutfitMeshes.Models={}
for i=1,%d do
	for _,row in require(script.Parent["OutfitMeshData"..i]) do
		local list=OutfitMeshes.Models[row[1]]
		if not list then list={};OutfitMeshes.Models[row[1]]=list end
		local piece=row[4]
		piece.on=row[2];piece.slot=row[3]
		table.insert(list,piece)
	end
end
-- (20/11) The invented outfits: bundles of the pieces above, no mesh of their own. Each
-- piece is shared (a shallow copy), its colour slot prefixed by its model (Catalog colours
-- them: GiCloth, HakamaCloth...).
OutfitMeshes.Sets={%s}
for set,models in OutfitMeshes.Sets do
	local list={}
	for _,model in models do
		for _,piece in OutfitMeshes.Models[model] or {} do
			local copy=table.clone(piece)
			copy.slot=model..piece.slot
			table.insert(list,copy)
		end
	end
	OutfitMeshes.Models[set]=list
end
function OutfitMeshes.forItem(id)
	local model=OutfitMeshes.Items[id]
	return model and OutfitMeshes.Models[model] or nil
end
return OutfitMeshes
""" % (ref, items, new_slots, catalog, sets, len(chunks), sets_lua))
    write_catalog(os.path.join(dst, "Catalog.luau"))
    for name, n, t in report:
        print("%-12s %3d pieces %6d tris" % (name, n, t))
    print("chunks", len(chunks), "sizes", [sum(len(x) for x in c) for c in chunks])


def render(dst, names=None):
    import bpy
    from nd_mesh import to_blender, render_set, clear
    os.makedirs(dst, exist_ok=True)
    SKIN = (0.93, 0.78, 0.62)
    COLORS = {"Orange": (236, 120, 30), "Blue": (34, 44, 92), "White": (232, 230, 224), "Navy": (30, 40, 86),
              "Wrap": (226, 222, 212), "Green": (46, 140, 60), "Red": (190, 40, 36), "Robe": (226, 222, 208),
              "Dark": (60, 56, 64), "Coat": (110, 34, 36), "Sash": (206, 196, 170), "Vest": (86, 98, 70),
              "Black": (26, 26, 32), "Grey": (150, 152, 158), "Guard": (176, 180, 186), "Cloth": (40, 48, 78),
              "Collar": (34, 44, 92), "Belt": (150, 40, 36), "Tie": (210, 206, 196), "Strap": (36, 36, 44),
              "Sandal": (40, 48, 78), "Flame": (196, 48, 34)}
    for name in MODELS:
        if names and name not in names:
            continue
        clear()
        objs = []
        # the mannequin: the R15 parts as boxes
        for part, c in REST.items():
            S = REF.get(part, (1.2, 1.2, 1.2))
            pc = Piece(part, "SmoothPlastic")
            hx, hy, hz = S[0] / 2, S[1] / 2, S[2] / 2
            box(pc, (c[0], c[1], c[2]), (hx * .98, hy * .98, hz * .98), lambda p, k: SKIN)
            objs.append(to_blender(to_blender_frame(pc)))
        for part, slot, pc in built(name):
            c = REST[part]
            col = COLORS.get(slot, NEW_SLOTS.get(name, {}).get(slot, (150, 150, 150)))
            if name == "Minato" and slot == "Coat":
                col = (238, 236, 230)
            tint = [x / 255 for x in col]
            pc.c = [tuple(g * t for g, t in zip(cc, tint)) for cc in pc.c]
            pc.v = [v + Vector((c[0], -c[2], c[1])) for v in pc.v]
            objs.append(to_blender(pc))
        for view, tag in (((.25, 1.0, .12), "front"), ((-.35, -1.0, .15), "back")):
            render_set(objs, os.path.join(dst, "%s_%s.png" % (name, tag)), size=(360, 560), view=view, fill=1.05)
        print("rendered", name, flush=True)


def catalog_colors(model):
    """The colours Shared/Catalog gives the first look that wears `model` (the masters' sets)."""
    import re
    path = os.path.join(HERE, "..", "..", "src", "Shared", "Catalog.luau")
    src = open(path).read()
    ids = [k for k, v in ITEMS.items() if v == model] + [k for k, v in WARDROBE_ITEMS.items() if v == model]
    for k in ids:
        m = re.search(r'\{id="%s".*?colors=\{(.*?)\}\}' % k, src)
        if m:
            return {sl: tuple(int(x) for x in rgb.split(",")) for sl, rgb in re.findall(r"(\w+)=\{(\d+,\d+,\d+)\}", m.group(1) + "}")}
    return {}


BODIES = (("thin", (.82, 1.0, .85)), ("wide", (1.3, 1.0, 1.25)), ("tall", (1.0, 1.25, 1.0)))


def render_bodies(dst, names=None):
    """(19/11, vague 2) Each model tried on three avatar bodies (thin, wide, tall: every part's
    size times these, as Client/OutfitDress scales a piece by body.Size/Ref), seen from the
    front (the three on the right) and from the back (the three on the left), in its first
    catalogue colourway."""
    from nd_mesh import to_blender, render_set, clear
    os.makedirs(dst, exist_ok=True)
    SKIN = (0.93, 0.78, 0.62)
    for name in MODELS:
        if names and name not in names:
            continue
        clear()
        objs = []
        if name in wardrobe_models.SETS:  # a bundle: each piece in the set's colours
            pieces, tints = [], []
            for m, cmap in wardrobe_models.SETS[name][1]:
                for entry in built(m):
                    pieces.append(entry)
                    tints.append(cmap)
        if name not in wardrobe_models.SETS:
            pieces = built(name)
            cols = dict(NEW_SLOTS.get(name, {}))
            cols.update(catalog_colors(name))
            tints = [cols] * len(pieces)
        for k, (back, (tag, f)) in enumerate([(b, bd) for b in (False, True) for bd in BODIES]):
            dx = (k - 2.5) * 3.6
            turn = -1 if back else 1

            def place(v, part):
                c = REST[part]
                x, y, z = v.x * f[0] + c[0] * f[0], v.y * f[2] - c[2] * f[2], v.z * f[1] + c[1] * f[1]
                return Vector((x * turn + dx, y * turn, z))
            for part, c in REST.items():
                S = REF.get(part, (1.2, 1.2, 1.2))
                pc = Piece(part, "SmoothPlastic")
                if part == "Head":  # the classic head: a rounded cylinder, not a box
                    rings = [[Vector((math.cos(t) * r, y, math.sin(t) * r)) for t in [i / 16 * math.tau for i in range(16)]]
                             for y, r in ((-.6, .5), (-.5, .6), (.5, .6), (.6, .5))]
                    loft(pc, rings, lambda p, kk: SKIN)
                else:
                    box(pc, (0, 0, 0), (S[0] / 2 * .98, S[1] / 2 * .98, S[2] / 2 * .98), lambda p, kk: SKIN)
                b = to_blender_frame(pc)
                b.v = [place(v, part) for v in b.v]
                if back:
                    b.f = [tuple(fc) for fc in b.f]
                objs.append(to_blender(b))
            for (part, slot, pc), cols in zip(pieces, tints):
                q = Piece(pc.name, pc.mat, pc.flat)
                q.v = [place(v, part) for v in pc.v]
                q.f = list(pc.f)
                tint = [x / 255 for x in cols.get(slot, (150, 150, 150))]
                q.c = [tuple(g * t for g, t in zip(cc, tint)) for cc in pc.c]
                objs.append(to_blender(q))
        render_set(objs, os.path.join(dst, "%s.png" % name), size=(1500, 520), view=(.1, 1.0, .12), fill=.56, world=(.7, .72, .76))
        print("BODIES", name, sum(len(p.tris()) for _, _, p in pieces), flush=True)


def render_heads(dst, names=None):
    """(22/11) A head style seen close: front, three-quarter, side and back, on the classic
    head, in its first catalogue colourway."""
    from nd_mesh import to_blender, render_set, clear
    from mathutils import Matrix
    os.makedirs(dst, exist_ok=True)
    SKIN = (0.93, 0.78, 0.62)
    for name in MODELS:
        if names and name not in names:
            continue
        clear()
        objs = []
        pieces = built(name)
        cols = dict(NEW_SLOTS.get(name, {}))
        cols.update(catalog_colors(name))
        for k, turn in enumerate((180, 220, 270, 0)):   # front, three-quarter, side, back
            R = Matrix.Rotation(math.radians(turn), 3, "Z")
            off = Vector(((k - 1.5) * 2.6, 0, 0))
            head = Piece("Head", "SmoothPlastic")
            rings = [[Vector((math.cos(t) * r, y, math.sin(t) * r)) for t in [i / 20 * math.tau for i in range(20)]]
                     for y, r in ((-.6, .5), (-.5, .6), (.5, .6), (.6, .5))]
            loft(head, rings, lambda p, kk: SKIN)
            eyes = Piece("Eyes", "SmoothPlastic")
            for x in (-.2, .2):
                box(eyes, (x, .08, -.6), (.06, .1, .02), lambda p, kk: (.1, .1, .12))
            torso = Piece("Neck", "SmoothPlastic")
            box(torso, (0, -.95, 0), (.9, .35, .45), lambda p, kk: (.3, .32, .4))
            for pc0 in (head, eyes, torso):
                b = to_blender_frame(pc0)
                b.v = [R @ v + off for v in b.v]
                objs.append(to_blender(b))
            for (part, slot, pc) in pieces:      # (built() is already in Blender's frame)
                if part != "Head":
                    continue
                q = Piece(pc.name, pc.mat, pc.flat)
                q.v = [R @ v + off for v in pc.v]
                q.f = list(pc.f)
                tint = [x / 255 for x in cols.get(slot, (150, 150, 150))]
                q.c = [tuple(g * t for g, t in zip(cc, tint)) for cc in pc.c]
                objs.append(to_blender(q))
        render_set(objs, os.path.join(dst, "%s.png" % name), size=(1600, 460), view=(.05, 1.0, .18), fill=.34, world=(.7, .72, .76))
        print("HEADS", name, flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "heads":
        render_heads(sys.argv[2], sys.argv[3:] or None)
    elif sys.argv[1] == "bodies":
        render_bodies(sys.argv[2], sys.argv[3:] or None)
    elif sys.argv[1] == "write":
        write(sys.argv[2])
    else:
        render(sys.argv[2], sys.argv[3:] or None)
