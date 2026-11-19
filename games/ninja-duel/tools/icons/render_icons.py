"""The catalogue's icons (OUTILLEUR, 19/11, plan-vrai-jeu-taches-2026-11-19
§ 4 OUTILLEUR 2): every look of Shared/Shop rendered from the ANIMATEUR's
Blender models, same angle, same light, transparent PNG, for the DESIGN.

  blender --background --python render_icons.py -- OUT_DIR [ids... | --manquantes]

Models (read from tools/blender, never changed here):
  top, bottom, arms, feet, set   outfit_models.py (the pieces the game welds),
                                 on the R15 mannequin, cropped to the slot
  kunai, shuriken, tanto         fx_models.py (the props the game builds)
  gourd                          look_gaara.py (the gourd of Gaara's look)
  headband                       no Blender model: the game's own geometry
                                 (Server/Headband) on the mannequin's head
Colours: the item's `colors` (Shared/Shop) multiply the model's vertex colours,
as the game paints a MeshPart (Client/Effects.paint, Server/Outfit). A "none"
look (no headband, bare arms...) has no icon: the screen draws an empty slot.
Writes OUT_DIR/<id>.png (512x512) and OUT_DIR/icons.json (what each icon is).
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(os.path.dirname(HERE))
BLENDER_TOOLS = os.path.join(GAME, "tools", "blender")
sys.path.insert(0, BLENDER_TOOLS)
import bpy  # noqa: E402
from mathutils import Vector, Matrix  # noqa: E402
from nd_mesh import Piece, to_blender, clear  # noqa: E402

SIZE = 512
VIEW = (0.42, 1.0, 0.30)   # the same three-quarter front for every icon (Blender frame: front = +y)
SKIN = (0.93, 0.78, 0.62)
SAMPLES = 16


# ----------------------------------------------------------------- the catalogue
# The same reader as the coverage check (tools/icons/catalogue.py): Shop.Items
# and, once it exists, Shared/Catalog.luau.
sys.path.insert(0, HERE)
from catalogue import catalogue  # noqa: E402


# ----------------------------------------------------------------- rendering
def tint(pc, rgb):
    t = [x / 255 for x in rgb]
    pc.c = [tuple(a * b for a, b in zip(cc, t)) for cc in pc.c]


def box(pc, c, half, col):
    from outfit_models import box as ob
    ob(pc, c, half, lambda p, k: col)


def place(objs, rot):
    m = rot
    for o in objs:
        o.matrix_world = m @ o.matrix_world


def render(objs, path, view=VIEW, fill=1.08):
    S = bpy.context.scene
    S.render.engine = "CYCLES"
    S.cycles.device = "CPU"
    S.cycles.samples = SAMPLES
    S.cycles.use_denoising = False
    S.render.resolution_x = S.render.resolution_y = SIZE
    S.render.film_transparent = True
    S.render.image_settings.file_format = "PNG"
    S.render.image_settings.color_mode = "RGBA"
    w = S.world or bpy.data.worlds.new("W")
    S.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.66, 0.72, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    for o in list(S.objects):
        if o.type in ("LIGHT", "CAMERA"):
            bpy.data.objects.remove(o)
    # one key light from the upper left front, the same for every icon
    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy = 3.4
    sun.rotation_euler = (0.85, 0.0, 3.6)
    S.collection.objects.link(sun)
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr = (lo + hi) / 2
    rad = (hi - lo).length / 2
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = 70
    S.collection.objects.link(cam)
    S.camera = cam
    d = Vector(view).normalized()
    fov = 2 * math.atan(36 / 2 / cam.data.lens)
    dist = rad * fill / math.sin(fov / 2)
    cam.location = ctr + d * dist
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.clip_end = dist * 4
    S.render.filepath = path
    bpy.ops.render.render(write_still=True)


# ----------------------------------------------------------------- the models
SLOT_PARTS = {
    # what of the mannequin each outfit slot shows (the rest would make the piece small)
    "top": ["UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperArm", "RightLowerArm", "LeftLowerArm"],
    "bottom": ["LowerTorso", "RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg"],
    "arms": ["RightUpperArm", "RightLowerArm", "RightHand"],
    "feet": ["RightLowerLeg", "LeftLowerLeg", "RightFoot", "LeftFoot"],
}


# the share of a body part's height kept at its bottom (the sandals would be
# small under two whole shins)
CROP = {"feet": {"RightLowerLeg": .35, "LeftLowerLeg": .35}}
# (vague 2, DEV 2) the new slots, once the ANIMATEUR models them in
# outfit_models.ITEMS: a mask on the head, a cape and what is carried on the
# back seen from behind (three-quarter back, the same light).
SLOT_PARTS.update({
    "mask": ["Head"],
    "cape": ["UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg"],
    "back": ["UpperTorso", "LowerTorso"],
})
VIEW_BACK = (-0.42, -1.0, 0.30)
VIEWS = {"cape": VIEW_BACK, "back": VIEW_BACK}


def mannequin(parts, crop=None):
    import outfit_models as OM
    objs = []
    for part in parts:
        c = OM.REST[part]
        S = OM.REF.get(part, (1.2, 1.2, 1.2))
        keep = (crop or {}).get(part, 1.0)
        cy = c[1] - S[1] / 2 + S[1] * keep / 2
        pc = Piece(part, "SmoothPlastic")
        box(pc, (c[0], cy, c[2]), (S[0] / 2 * .98, S[1] * keep / 2 * .98, S[2] / 2 * .98), SKIN)
        objs.append(to_blender(OM.to_blender_frame(pc)))
    return objs


def outfit(item):
    import outfit_models as OM
    model = OM.ITEMS.get(item["id"])
    if not model:
        return None, "pas de modèle dans outfit_models.ITEMS"
    parts = SLOT_PARTS.get(item["slot"]) or list(OM.REST.keys())
    objs = mannequin(parts, CROP.get(item["slot"]))
    for part, slot, pc in OM.built(model):
        if part not in parts:
            continue
        c = OM.REST[part]
        col = item["colors"].get(slot) or OM.NEW_SLOTS.get(model, {}).get(slot) or (150, 150, 150)
        tint(pc, col)
        pc.v = [v + Vector((c[0], -c[2], c[1])) for v in pc.v]
        objs.append(to_blender(pc))
    return objs, "outfit_models.py · " + model


def paint_key(pc):
    """Client/Effects.paint: which colour of the look paints this piece."""
    n = pc.name
    if pc.mat == "Neon" or n == "SealTag":
        return None
    if "Blade" in n or n in ("Tip", "Body"):
        return "Blade"
    if "Grip" in n or "Wrap" in n:
        return "Grip"
    if "Fitting" in n or "Ring" in n or "Guard" in n:
        return "Ring"
    if pc.mat == "Metal":
        return "Blade"
    if pc.mat == "Fabric":
        return "Grip"
    return None


def weapon(item):
    import fx_models as FXM
    slot = item["slot"]
    pieces = {"kunai": lambda: FXM.kunai(False), "shuriken": FXM.shuriken, "tanto": FXM.tanto}[slot]()
    objs = []
    for pc in pieces:
        key = paint_key(pc)
        col = key and (item["colors"].get(key) or item["colors"].get("Blade"))
        if col:
            tint(pc, col)
        objs.append(to_blender(pc))
    if slot == "shuriken":
        # flat in its plane: stood up, facing the lens
        place(objs, Matrix.Rotation(math.radians(72), 4, "X"))
    else:
        # the point up, leaning to the right
        place(objs, Matrix.Rotation(math.radians(-38), 4, "Y") @ Matrix.Rotation(math.radians(90), 4, "X"))
    return objs, "fx_models.py · " + slot


def node_material(name, rgb, rough=0.6):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = tuple((x / 255) ** 2.2 for x in rgb) + (1,)
    bsdf.inputs["Roughness"].default_value = rough
    return m


def gourd(item):
    """The gourd of Gaara's look. look_gaara.py builds the whole look, then
    exports and previews it: it is run here WITHOUT its export and preview
    lines (nothing written), and only its Gourd pieces are kept. The Body
    colour of the item paints the gourd itself."""
    clear()
    src = open(os.path.join(BLENDER_TOOLS, "look_gaara.py"), encoding="utf-8").read()
    lines = [ln for ln in src.splitlines() if not ln.lstrip().startswith(("export(", "preview("))]
    cwd = os.getcwd()
    os.chdir(BLENDER_TOOLS)
    try:
        exec(compile("\n".join(lines), "look_gaara.py", "exec"), {"__name__": "__icons__", "__file__": os.path.join(BLENDER_TOOLS, "look_gaara.py")})
    finally:
        os.chdir(cwd)
    keep = [o for o in bpy.data.objects if o.type == "MESH" and "__Gourd" in o.name]
    if not keep:
        return None, "look_gaara.py n'a pas d'objet Gourd"
    for o in list(bpy.data.objects):
        if o not in keep:
            bpy.data.objects.remove(o)
    for o in keep:
        rgb = tuple(int(x * 255) for x in o.color[:3])
        if o.name.endswith("__Gourd") and item["colors"].get("Body"):
            rgb = item["colors"]["Body"]
        o.data.materials.clear()
        o.data.materials.append(node_material(o.name + "_icon", rgb))
    return keep, "look_gaara.py · Gourd (sans son export)"


def headband(item):
    """Server/Headband on the R15 head (1.2 studs): four strips at the brow,
    two tails behind, the plate in front. No Blender model exists."""
    import outfit_models as OM
    hx = hy = hz = 1.2
    c = OM.REST["Head"]
    objs = []
    head = Piece("Head", "SmoothPlastic")
    box(head, c, (hx / 2 * .98, hy / 2 * .98, hz / 2 * .98), SKIN)
    objs.append(to_blender(OM.to_blender_frame(head)))
    band = tuple(x / 255 for x in item["colors"].get("Band", (46, 64, 120)))
    plate = tuple(x / 255 for x in item["colors"].get("Plate", (200, 204, 210)))
    y = c[1] + hy * .16
    w, d = hx * 1.06, hz * 1.06
    strips = [((0, y, -d / 2), (w, hy * .2, .06)), ((0, y, d / 2), (w, hy * .2, .06)),
              ((-w / 2, y, 0), (.06, hy * .2, d)), ((w / 2, y, 0), (.06, hy * .2, d))]
    for at, size in strips:
        pc = Piece("Band", "Fabric")
        box(pc, at, (size[0] / 2, size[1] / 2, size[2] / 2), band)
        objs.append(to_blender(OM.to_blender_frame(pc)))
    for side in (-1, 1):
        pc = Piece("Tail", "Fabric")
        box(pc, (side * .12, y - hy * .26, d / 2 + .05), (.07, hy * .25, .02), band)
        objs.append(to_blender(OM.to_blender_frame(pc)))
    pc = Piece("Plate", "Metal")
    box(pc, (0, y, -d / 2 - .05), (w * .31, hy * .085, .025), plate)
    objs.append(to_blender(OM.to_blender_frame(pc)))
    return objs, "Server/Headband (géométrie du jeu, pas de modèle Blender)"


BUILD = {"top": outfit, "bottom": outfit, "arms": outfit, "feet": outfit, "set": outfit,
         "mask": outfit, "cape": outfit, "back": outfit,
         "kunai": weapon, "shuriken": weapon, "tanto": weapon, "gourd": gourd, "headband": headband}


def builder(item):
    """The slot's builder; a slot it does not know yet is drawn as an outfit
    piece when the ANIMATEUR has modelled the look in outfit_models.ITEMS."""
    if item["slot"] in BUILD:
        return BUILD[item["slot"]]
    import outfit_models as OM
    if item["id"] in OM.ITEMS:
        return outfit
    return lambda _item: (None, "emplacement « %s » inconnu de render_icons.py (ajouter une ligne à BUILD)" % item["slot"])


def main(out, only=None):
    """Renders the looks (all, or the ids in `only`; "--manquantes": those
    without a PNG in `out` yet) and keeps icons.json whole: the entries of the
    looks not rendered this time stay as they were."""
    os.makedirs(out, exist_ok=True)
    looks = catalogue()
    if only and "--manquantes" in only:
        only = [it["id"] for it in looks if not it["none"] and not os.path.isfile(os.path.join(out, it["id"] + ".png"))]
        print("missing:", " ".join(only) or "none", flush=True)
    path_json = os.path.join(out, "icons.json")
    before = {}
    if os.path.isfile(path_json):
        with open(path_json, encoding="utf-8") as f:
            before = {e["id"]: e for e in json.load(f).get("icons", [])}
    manifest = []
    for item in looks:
        if only is not None and item["id"] not in only:
            if item["id"] in before:
                manifest.append(before[item["id"]])
            continue
        entry = {k: item[k] for k in ("id", "slot", "name", "counter") if k in item}
        if "ryo" in item:
            entry["ryo"] = item["ryo"]
        if item["none"]:
            entry["icon"] = None
            entry["note"] = "aucun objet (case vide à l'écran)"
            manifest.append(entry)
            continue
        clear()
        try:
            objs, source = builder(item)(item)
        except Exception as e:  # a model that does not build is listed, not hidden
            objs, source = None, "échec : %s" % e
        entry["model"] = source
        if not objs:
            entry["icon"] = None
            manifest.append(entry)
            print("NO ICON", item["id"], source, flush=True)
            continue
        path = os.path.join(out, item["id"] + ".png")
        render(objs, path, VIEWS.get(item["slot"], VIEW))
        entry["icon"] = item["id"] + ".png"
        if item["slot"] in VIEWS:
            entry["view"] = VIEWS[item["slot"]]
        manifest.append(entry)
        print("icon", item["id"], flush=True)
    with open(path_json, "w", encoding="utf-8") as f:
        json.dump({"size": SIZE, "view": VIEW, "icons": manifest}, f, ensure_ascii=False, indent=1)
    return manifest


if __name__ in ("__main__", "<run_path>"):
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if argv:
        main(argv[0], argv[1:] or None)
