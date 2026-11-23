"""(23/11, étape 5, DEC-049) The shop's offers rendered for the DESIGN, and every sellable look
checked on the avatar from the front and from the back.

    blender -b --python-expr "import sys; sys.argv=['offer_renders.py','offers',DST]+IDS; exec(open('offer_renders.py').read())"
    ... 'review', DST [ids]
    python3 offer_bundle.py DST     (the 8 prodigies' bundle, from their offers)

offers  one 512 x 512 PNG per Catalog id, transparent background, three-quarter front:
        outfits, sets, capes and back pieces on the whole avatar; hair, headbands and masks
        as a bust; weapons alone (in their Catalog colours); auras on the avatar, the
        effect drawn as Client/ShopAuraFX describes it (a still stand-in for particles).
review  the same look on the avatar seen from the front and from the back, side by side
        (1024 x 512), for the check « tout ce qui se vend, de face et de dos ».

Every id that is sold (robux, ryo > 0) or given (the VIP cape) is rendered; base items are
not offers. Colours are the Catalog row's own (colour variants differ), not the model's first.
"""
import math
import os
import random
import re
import sys

HERE = os.path.dirname(os.path.abspath(globals().get("__file__") or os.path.join(os.getcwd(), "offer_renders.py")))
sys.path.insert(0, HERE)
import bpy  # noqa: E402
from mathutils import Vector, Matrix  # noqa: E402
import nd_mesh  # noqa: E402
from nd_mesh import Piece, loft, to_blender, clear, rgb, tube, ellipsoid  # noqa: E402

_argv = sys.argv
sys.argv = ["outfit_models.py", "--lib"]
import outfit_models as OM  # noqa: E402
import fx_models as FX  # noqa: E402
sys.argv = _argv

CATALOG = os.path.join(HERE, "..", "..", "src", "Shared", "Catalog.luau")
SKIN = (0.93, 0.78, 0.62)
BUST = {"hair", "headband", "mask"}
WEAR = {"set", "top", "bottom", "arms", "feet", "cape", "back", "hair", "headband", "mask"}
WEAPON = {"kunai", "shuriken", "tanto"}


def catalog(every=False):
    """[(id, slot, row text)] for every sold or given look (every=True: all rows), in Catalog order."""
    out = []
    for m in re.finditer(r'\{id="(\w+)",slot="(\w+)"([^\n]*)', open(CATALOG).read()):
        i, s, rest = m.groups()
        if every or "robux=" in rest or re.search(r"ryo=[1-9]", rest) or 'earned="vip"' in rest:
            out.append((i, s, rest))
    return out


# What the avatar wears under a single piece, so a cape or a haircut is not shown on bare skin:
# the starting outfit (base items), the offered piece taking its slot.
UNDER = {"top": "TopTunicBlack", "bottom": "BottomPantsDark", "feet": "FeetBlack"}


def dressed(item_id, slot):
    if slot == "set":
        return [(item_id, colors(ROWS[item_id]))]
    looks = [(i, colors(ROWS[i])) for s, i in UNDER.items() if s != slot and i in ROWS]
    if item_id:
        looks.append((item_id, colors(ROWS[item_id])))
    return looks


def colors(rest):
    m = re.search(r"colors=\{(.*?)\}\}", rest)
    if not m:
        return {}
    return {k: tuple(int(x) for x in v.split(",")) for k, v in re.findall(r"(\w+)=\{(\d+,\d+,\d+)\}", m.group(1) + "}")}


def body_pieces():
    """The classic avatar (the parts OutfitDress fits to), skin, with eyes and a brow line."""
    out = []
    for part in OM.REST:
        S = OM.REF.get(part, (1.2, 1.2, 1.2))
        pc = Piece(part, "SmoothPlastic")
        if part == "Head":
            rings = [[Vector((math.cos(t) * r, y, math.sin(t) * r)) for t in [i / 24 * math.tau for i in range(24)]]
                     for y, r in ((-.6, .5), (-.5, .6), (.5, .6), (.6, .5))]
            loft(pc, rings, lambda p, kk: SKIN)
            out.append((part, pc))
            eyes = Piece("Eyes", "SmoothPlastic")
            for x in (-.2, .2):
                OM.box(eyes, (x, .08, -.6), (.06, .1, .02), lambda p, kk: (.1, .1, .12))
            out.append((part, eyes))
        else:
            OM.box(pc, (0, 0, 0), (S[0] / 2 * .98, S[1] / 2 * .98, S[2] / 2 * .98), lambda p, kk: SKIN)
            out.append((part, pc))
    return out


BODY = [(1.0, 1.0, 1.0)]   # the body's scale (width, height, depth), as OutfitDress scales by body.Size/REF


def place(v, part, yaw):
    """A vertex of `part` (Blender frame) moved to the part's rest place, the body turned `yaw`."""
    c = OM.REST[part]
    f = BODY[0]
    p = Vector(((v.x + c[0]) * f[0], (v.y - c[2]) * f[2], (v.z + c[1]) * f[1]))
    return Matrix.Rotation(yaw, 3, "Z") @ p


def look_pieces(item_id, cols):
    """The look's pieces [(part, slot, piece in Blender frame)] and the colour of each slot."""
    model = OM.ITEMS.get(item_id) or OM.WARDROBE_ITEMS.get(item_id)
    m = re.search(r'model="(\w+)"', ROWS.get(item_id, ""))
    if m:
        model = m.group(1)
    if not model and re.search(r'slot="headband"', ROWS.get(item_id, "")) or (not model and item_id.startswith("Headband")):
        model = "HeadbandClassic"   # the classic forehead protector's colour variants
    if not model or model not in OM.MODELS:
        return None, None
    pieces = OM.built(model)
    tints = dict(OM.NEW_SLOTS.get(model, {}))
    if item_id in OM.wardrobe_models.SETS:
        for m, cmap in OM.wardrobe_models.SETS[item_id][1]:
            for k, v in cmap.items():
                tints[m + k] = v
    tints.update(cols)
    return pieces, tints


def tinted(pc, rgb255):
    t = [x / 255 for x in rgb255]
    return [tuple(g * k for g, k in zip(cc, t)) for cc in pc.c]


def avatar(looks, yaw, bust=False, extra=()):
    """Blender objects: the avatar wearing the looks [(id, colours)], turned `yaw` (0: facing +y)."""
    objs = []
    keep = ("Head", "UpperTorso") if bust else None
    for part, pc in body_pieces():
        if keep and part not in keep:
            continue
        b = OM.to_blender_frame(pc)
        b.v = [place(v, part, yaw) for v in b.v]
        objs.append(to_blender(b))
    for item_id, cols in looks:
        pieces, tints = look_pieces(item_id, cols)
        for part, slot, pc in pieces or []:
            if keep and part not in keep:
                continue
            q = Piece(pc.name, pc.mat, pc.flat)
            q.v = [place(v, part, yaw) for v in pc.v]
            q.f = list(pc.f)
            q.c = tinted(pc, tints.get(slot, (150, 150, 150)))
            objs.append(to_blender(q))
    for pc in extra:
        q = Piece(pc.name, pc.mat, pc.flat, pc.alpha)
        q.v = [Matrix.Rotation(yaw, 3, "Z") @ v for v in pc.v]
        q.f, q.c = list(pc.f), list(pc.c)
        objs.append(to_blender(q))
    return objs


def weapon(item_id, slot, cols, yaw=0.0, at=(0, 0, 0)):
    if slot == "kunai":
        pieces = FX.kunai(marked=(item_id == "KunaiGold"))
        key = {"Blade": "Blade", "Grip": "Grip", "Fittings": "Ring"}
    elif slot == "shuriken":
        pieces = FX.shuriken()
        pieces = pieces if isinstance(pieces, list) else [pieces]
        key = {"Shuriken": "Blade"}
    else:
        pieces = FX.tanto()
        key = {"Blade": "Blade", "Grip": "Grip"}
    objs = []
    R = Matrix.Rotation(yaw, 3, "Z") @ Matrix.Rotation(math.radians(-35 if slot != "shuriken" else 65), 3, "Y")
    for pc in pieces:
        q = Piece(pc.name, pc.mat, pc.flat, pc.alpha)
        q.v = [R @ Vector((v.x, -v.z, v.y)) + Vector(at) for v in pc.v]
        q.f = list(pc.f)
        k = key.get(pc.name)
        if k and k in cols:   # the Catalog colour, the model's shading kept (light / mean light)
            lum = [sum(c) / 3 for c in pc.c]
            mean = sum(lum) / len(lum) or 1
            t = [x / 255 for x in cols[k]]
            q.c = [tuple(min(1, x * (l / mean)) for x in t) for l in lum]
        else:
            q.c = list(pc.c)
        objs.append(to_blender(q))
    return objs


# ---- the auras: still stand-ins for Client/ShopAuraFX's particles --------------------------
def aura_pieces(key, col):
    rnd = random.Random(7)
    c = tuple(x / 255 for x in col)
    out = []
    if key == "Sakura":        # petals drifting down round him
        pc = Piece("Petals", "SmoothPlastic", flat=True)
        for _ in range(46):
            a, r, z = rnd.uniform(0, math.tau), rnd.uniform(1.4, 2.1), rnd.uniform(-2.8, 3.6)
            ellipsoid(pc, (math.cos(a) * r, math.sin(a) * r, z), (.2, .11, .03), c, seg=8, rings=3)
        out.append(pc)
    elif key == "Ink":         # black wisps rising off the shoulders
        for side in (-1, 1):
            for k in range(3):
                pts = [(side * (1.0 + .25 * k) + .35 * math.sin(u * 5 + k), .1 * k, 2.0 + u * 3.2) for u in [i / 14 for i in range(15)]]
                pc = Piece("Ink%d%d" % (side, k), "SmoothPlastic", alpha=.25)
                tube(pc, pts, lambda kk: .16 * (1 - kk) + .02, lambda p, kk: c, sides=8)
                out.append(pc)
    elif key == "Fireflies":   # soft lights circling at his waist
        pc = Piece("Flies", "Neon")
        for i in range(11):
            a = i / 11 * math.tau + rnd.uniform(-.2, .2)
            ellipsoid(pc, (math.cos(a) * 2.0, math.sin(a) * 2.0, rnd.uniform(-.4, 1.6)), (.09, .09, .09), c, seg=8, rings=4)
        out.append(pc)
    elif key == "Frost":       # a cold breath at his feet, glints of ice
        mist = Piece("Mist", "SmoothPlastic", alpha=.55)
        rings = [[Vector((math.cos(t) * r, math.sin(t) * r, z)) for t in [i / 32 * math.tau for i in range(32)]]
                 for r, z in ((.2, -2.9), (2.4, -2.85), (2.2, -2.3), (.2, -2.25))]
        loft(mist, rings, lambda p, kk: c)
        out.append(mist)
        ice = Piece("Ice", "Neon", flat=True)
        for _ in range(14):
            a, r = rnd.uniform(0, math.tau), rnd.uniform(.8, 2.3)
            ellipsoid(ice, (math.cos(a) * r, math.sin(a) * r, rnd.uniform(-2.8, -1.4)), (.05, .05, .12), (.85, .95, 1), seg=6, rings=3)
        out.append(ice)
    elif key == "Thunder":     # a crackle across the shoulders
        for k in range(4):
            pts, x = [], -1.9
            while x < 1.9:
                pts.append((x, rnd.uniform(-.35, .35), 2.0 + rnd.uniform(-.3, .55)))
                x += rnd.uniform(.25, .5)
            pc = Piece("Bolt%d" % k, "Neon")
            tube(pc, pts, lambda kk: .045, lambda p, kk: c, sides=5)
            out.append(pc)
    elif key == "Shadow":      # a low violet smoke clinging to his legs
        for k in range(26):   # low wisps round the shins, thinning as they rise
            a = rnd.uniform(0, math.tau)
            z = -2.9 + rnd.uniform(0, 1.8) ** 1.5
            r = rnd.uniform(.9, 1.5)
            pc = Piece("Smoke%d" % k, "SmoothPlastic", alpha=.62)
            s = .5 * (1 - (z + 2.9) / 3)
            ellipsoid(pc, (math.cos(a) * r, math.sin(a) * r * .8, z), (s * 1.3, s, s * .55), c, seg=12, rings=6)
            out.append(pc)
    return out


# ---- rendering -----------------------------------------------------------------------------
def shoot(objs, path, size=(512, 512), view=(.55, 1.0, .16), fill=.92, lens=60, frame=None):
    S = bpy.context.scene
    S.render.engine = "CYCLES"
    S.cycles.device = "CPU"
    S.cycles.samples = 40
    S.cycles.use_denoising = False
    S.render.resolution_x, S.render.resolution_y = size
    S.render.film_transparent = True
    S.render.image_settings.file_format = "PNG"
    S.render.image_settings.color_mode = "RGBA"
    w = S.world or bpy.data.worlds.new("W")
    S.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (.78, .76, .74, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = .8
    for o in list(S.objects):
        if o.type in ("LIGHT", "CAMERA"):
            bpy.data.objects.remove(o)
    for name, energy, rot in (("Key", 3.4, (.8, .1, 2.5)), ("Rim", 2.2, (1.2, 0, -.6))):
        sun = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
        sun.data.energy = energy
        sun.rotation_euler = rot
        S.collection.objects.link(sun)
    bpy.context.view_layer.update()   # objects moved by .location: refresh matrix_world first
    pts = [o.matrix_world @ Vector(c) for o in (frame or objs) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (lo + hi) / 2
    rad = (hi - lo).length / 2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = lens
    S.collection.objects.link(cam)
    S.camera = cam
    d = Vector(view).normalized()
    fov = 2 * math.atan(36 / 2 / lens) * min(1, size[1] / size[0])
    dist = rad * fill / math.sin(fov / 2)
    cam.location = ctr + d * dist
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.clip_end = dist * 4
    S.render.filepath = path
    bpy.ops.render.render(write_still=True)


def head_frame(objs):
    """The objects a bust is framed on: whatever sits above the shoulders (head, hair, mask)."""
    bpy.context.view_layer.update()
    out = [o for o in objs if min((o.matrix_world @ Vector(c)).z for c in o.bound_box) > 1.6]
    return out or objs


def build(item_id, slot, rest, yaw):
    cols = colors(rest)
    if slot in WEAPON:
        return weapon(item_id, slot, cols, yaw * .3), "weapon"
    if slot == "aura":
        key = re.search(r'fx="Aura\.(\w+)"', rest).group(1)
        return avatar(dressed(None, slot), yaw, extra=aura_pieces(key, cols.get("Aura", (200, 200, 200)))), "aura"
    if slot in WEAR:
        bust = slot in BUST and item_id != "HeadbandWaist"
        objs = avatar(dressed(item_id, slot), yaw, bust=bust)
        return objs, ("bust" if bust else "body")
    return None, None


ROWS = {}


def run(mode, dst, ids=None):
    os.makedirs(dst, exist_ok=True)
    ROWS.update({i: rest for i, _, rest in catalog(every=True)})
    done, skipped = [], []
    for item_id, slot, rest in catalog():
        if ids and item_id not in ids:
            continue
        if mode == "offers":
            clear()
            # a cape or a back piece is shown from behind, three-quarter; the rest from the front
            objs, kind = build(item_id, slot, rest, math.pi if slot in ("cape", "back") else 0.0)
            if not objs:
                skipped.append((item_id, slot))
                continue
            fill = {"weapon": .78, "bust": 1.0, "body": .9, "aura": .95}[kind]
            shoot(objs, os.path.join(dst, "%s.png" % item_id), fill=fill, view=(.55, 1.0, .3 if kind == "bust" else .16),
                  frame=head_frame(objs) if kind == "bust" else None)
        else:   # review: front and back side by side
            if slot in WEAPON or slot not in WEAR | {"aura"}:
                skipped.append((item_id, slot))
                continue
            clear()
            front, kind = build(item_id, slot, rest, 0.0)
            if not front:
                skipped.append((item_id, slot))
                continue
            back, _ = build(item_id, slot, rest, math.pi)
            # the camera looks down -y, so +x is on the left of the picture: front left, back right
            for o in front:
                o.location.x += 2.4 if kind != "bust" else 1.6
            for o in back:
                o.location.x -= 2.4 if kind != "bust" else 1.6
            shoot(front + back, os.path.join(dst, "%s.png" % item_id), size=(1024, 512), view=(.0, 1.0, .1),
                  fill={"bust": 1.0}.get(kind, .92), frame=head_frame(front + back) if kind == "bust" else None)
        done.append(item_id)
        print("OFFER" if mode == "offers" else "REVIEW", item_id, flush=True)
    print("DONE %d SKIPPED %s" % (len(done), skipped), flush=True)


# (the bundle of the 8 prodigies' outfits is composed from their offers: offer_bundle.py)


# (23/11, passe commune 1) The starting outfits a new player composes (base pieces only), each
# on the three bodies OutfitDress fits (thin, wide, tall), front row then back row.
STARTERS = {
    "Navy": ["TopTunicNavy", "BottomPantsDark", "ArmsWraps", "FeetSandals", "HeadbandBlue"],
    "Black": ["TopTunicBlack", "BottomPantsSand", "ArmsGuards", "FeetBlack", "HeadbandBlue"],
    "Forest": ["TopTunicGreen", "BottomShorts", "ArmsWraps", "FeetSandals", "HeadbandBlue"],
    "Collar": ["TopHighCollar", "BottomPantsDark", "ArmsGuards", "FeetBlack", "HeadbandBlue"],
    "Sleeveless": ["TopSleeveless", "BottomShorts", "ArmsWraps", "FeetSandals", "HeadbandBlue"],
}


def starters(dst, names=None):
    os.makedirs(dst, exist_ok=True)
    ROWS.update({i: rest for i, _, rest in catalog(every=True)})
    for name, ids in STARTERS.items():
        if names and name not in names:
            continue
        clear()
        objs = []
        looks = [(i, colors(ROWS[i])) for i in ids]
        for row, yaw in enumerate((0.0, math.pi)):
            for k, (tag, f) in enumerate(OM.BODIES):
                BODY[0] = f
                part = avatar(looks, yaw)
                for o in part:
                    o.location.x += (1 - k) * 5.6   # +x is on the left of the picture
                    o.location.z += (1 - row) * 7.6
                objs += part
        BODY[0] = (1.0, 1.0, 1.0)
        shoot(objs, os.path.join(dst, "starter_%s.png" % name), size=(1024, 1024), view=(0, 1.0, .08), fill=.98)
        print("STARTER", name, flush=True)


if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[1] == "starters":
    starters(sys.argv[2], set(sys.argv[3:]) or None)
if __name__ == "__main__" and len(sys.argv) > 2 and sys.argv[1] in ("offers", "review"):
    run(sys.argv[1], sys.argv[2], set(sys.argv[3:]) or None)
