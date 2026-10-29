# Ninja Duel — the Chunin Exam finals stadium in Blender, pass 2 (user 29/10
# 17:01-17:03, with reference pictures: "ça ressemble pas vraiment à ça", the
# ground, the shadows and the trees can be much better, the wooden posts and
# rocks in the middle "ça fait pas professionnel").
# From the references:
#   - inside, one tall smooth wall of pale grey-green concrete panels with
#     vertical seams, no stands round the field;
#   - outside, a brick-red domed bowl with ribs and two pale bands, small
#     openings at its foot;
#   - the spectators sit only in the buildings on the north rim: a central
#     hall with stacked golden roofs and wings with open galleries;
#   - a sandy field with uneven grass patches and tufts, bushes and trees in
#     a ring along the wall, the middle open.
# Visual pieces only: the field, the wall fighters run on, the balcony and
# the trees' trunks stay real parts in Server/World. Every asset is modelled
# around its own origin in ROBLOX space (studs, +Y up, buildings facing -Z,
# toward the field) and placed by World.arena through Server/ArenaMeshes:
#   WallSector, ShellSector : one 45-degree slice, centred on +Z (field centre);
#   Hall (at World's Kage point), Wing (on the rim), Gate;
#   Tree, Bush, Tufts, GrassA/B/C : the field and the forest.
import sys, os, math, random
sys.path.insert(0, os.environ.get("ND_LIB", os.path.dirname(__file__)))
import importlib, nd_look, arena_kit
importlib.reload(nd_look); importlib.reload(arena_kit)
from nd_look import *
from arena_kit import *
from mathutils import Vector

OUT = os.environ.get("ND_OUT", os.path.dirname(__file__))
reset()

RW = 145            # World.WALL_RADIUS: inner face of the wall
WALL_H = 40
TOP = WALL_H + 1.2  # the rim
HALF = math.radians(22.5)

PANEL = (186, 194, 180); PANEL_B = (178, 188, 174); SEAM = (132, 140, 128)
GRIME = (150, 156, 140); RIM = (204, 206, 196)
BRICK = (158, 76, 56); BRICK_RIB = (182, 100, 74); BAND = (230, 222, 202); VENT = (44, 34, 30)
WHITE = (240, 236, 226); WHITE_D = (214, 210, 198); WINDOW = (58, 62, 70); STONE = (176, 172, 160)
ROOF = (212, 156, 62); ROOF_D = (176, 120, 44); RIDGE = (150, 98, 36); WOOD = (110, 78, 54); WOOD_D = (80, 56, 40)
SEAT = (150, 150, 146)
LEAF = (86, 136, 62); LEAF_D = (62, 110, 54); LEAF_L = (118, 160, 74); BARK = (102, 76, 56)
GRASS = (118, 156, 74); GRASS_D = (96, 136, 64); TUFT = (102, 144, 66)

rng = random.Random(29)

# ---------------------------------------------------------------- inner wall
def wall_sector():
    A = "WallSector"
    a0, a1 = -HALF, HALF
    put(arc_sweep(rect(RW - .05, RW + .4, 0, WALL_H), a0, a1, 24), A, "Seams", SEAM, 60)
    panels = {0: [], 1: []}
    n = 4
    for k in range(n):
        p0 = a0 + (a1 - a0) * k / n + .35 / RW
        p1 = a0 + (a1 - a0) * (k + 1) / n - .35 / RW
        panels[k % 2].append(arc_sweep(rect(RW - .3, RW - .04, 0, WALL_H - .1), p0, p1, 8))
    put(panels[0], A, "Panel", PANEL, 60, "Concrete")
    put(panels[1], A, "PanelB", PANEL_B, 60, "Concrete")
    # Weathering at the foot, a slim joint two thirds up, the rim's lip.
    put(arc_sweep(rect(RW - .42, RW - .2, 0, 2.6), a0, a1, 24), A, "Grime", GRIME, 60, "Concrete")
    put(arc_sweep(rect(RW - .36, RW - .25, 26.6, 26.9), a0, a1, 24), A, "Joint", SEAM, 60)
    put(arc_sweep([(RW - .9, WALL_H - .3), (RW + 3.4, WALL_H - .3), (RW + 3.4, TOP), (RW - .9, TOP)], a0, a1, 24), A, "Rim", RIM, 50, "Concrete")

# ---------------------------------------------------------------- outer dome
def shell_r(y):
    """Outer radius of the bowl at height y: a dome swelling to the ground."""
    t = max(0.0, min(1.0, y / TOP))
    return RW + 3.4 + 24 * (1 - t ** 1.6) ** .6

def shell_sector():
    A = "ShellSector"
    a0, a1 = -HALF, HALF
    ys = [-1] + [TOP * k / 16 for k in range(17)]
    prof = [(RW + 3.2, -1)] + [(shell_r(max(0, y)), y) for y in ys] + [(RW + 3.2, TOP)]
    put(arc_sweep(prof, a0, a1, 32), A, "Brick", BRICK, 40, "Brick")
    ribs, bands, vents = [], [], []
    for k in range(4):
        a = a0 + (a1 - a0) * (k + .5) / 4
        w = 1.1 / RW
        rp = [(RW + 3.2, -1)] + [(shell_r(max(0, y)) + .7, y) for y in ys] + [(RW + 3.2, TOP)]
        ribs.append(arc_sweep(rp, a - w, a + w, 2))
    for yb in (11, 27):
        bp = [(shell_r(yb - .9) - .2, yb - .9), (shell_r(yb - .9) + .35, yb - .9), (shell_r(yb + .9) + .35, yb + .9), (shell_r(yb + .9) - .2, yb + .9)]
        bands.append(arc_sweep(bp, a0, a1, 32))
    for k in range(8):
        a = a0 + (a1 - a0) * (k + .5) / 8
        vents.append(arc_box(shell_r(2.5) - .2, a, 2.5, (4.5, 2.6, 1.4)))
    put(ribs, A, "Ribs", BRICK_RIB, 40, "Brick")
    put(bands, A, "Bands", BAND, 40)
    put(vents, A, "Vents", VENT, 40)

# ---------------------------------------------------------------- buildings
def window_strip(x0, x1, y, h, z, step=3.2, name="win"):
    """A dark band of windows with pale mullions across x0..x1 at face z."""
    dark = [box(((x0 + x1) / 2, y, z), (x1 - x0, h, .2), bevel=0)]
    mull = []
    k = 0
    x = x0
    while x <= x1 + .01:
        mull.append(box((x, y, z - .12), (.35, h, .2), bevel=0))
        x += step
    mull.append(box(((x0 + x1) / 2, y + h / 2, z - .14), (x1 - x0 + .4, .35, .25), bevel=0))
    mull.append(box(((x0 + x1) / 2, y - h / 2, z - .14), (x1 - x0 + .4, .35, .25), bevel=0))
    return dark, mull

def hall():
    """The central hall (World's Kage point is its balcony floor): a white
    base on the rim, an open gallery, two upper storeys, three golden roofs."""
    A = "Hall"
    whites, darks, mulls, wood = [], [], [], []
    whites.append(box((0, -8, 2.5), (40, 16, 27), bevel=0))
    d, m = window_strip(-18, 18, -7.5, 3.2, -11.1); darks += d; mulls += m
    whites.append(box((0, 4.5, 6), (34, 9, 14), bevel=0))
    whites.append(box((0, 12.5, 4), (26, 6.5, 13), bevel=0))
    d, m = window_strip(-11.5, 11.5, 12.6, 2.8, -2.6, 2.9); darks += d; mulls += m
    whites.append(box((0, 20.2, 3), (16, 4.4, 9), bevel=0))
    d, m = window_strip(-6.5, 6.5, 20.3, 2.2, -1.6, 2.6); darks += d; mulls += m
    put(whites, A, "White", WHITE, 40)
    put(darks, A, "Windows", WINDOW, 40)
    put(mulls, A, "Mullions", WHITE_D, 40)
    # Gallery: floor out over the wall, pillars, rail (the two Kage sit at
    # (+-4, 1, -11) on it).
    put([box((0, .4, -4.5), (38, .8, 16), bevel=.1, segments=1)], A, "Floor", STONE, 40)
    pillars = [cylinder((x, .8, -12.2), .7, 8.4, 12) for x in (-17.5, -10.5, -3.5, 3.5, 10.5, 17.5)]
    put(pillars, A, "Pillars", WHITE_D, 40)
    rail = [box((0, 2.0, -12.8), (37, .35, .35), bevel=0), box((0, 1.2, -12.8), (37, .25, .25), bevel=0)]
    rail += [box((x, 1.4, -12.8), (.3, 1.4, .3), bevel=0) for x in [-18 + 36 * k / 18 for k in range(19)]]
    put(rail, A, "Rail", WOOD, 30)
    put([box((0, 9.0, -4.5), (39, .8, 17.5), bevel=0)], A, "Beam", WOOD_D, 30)
    roofs = [hip_roof(23, 13, 4.6, 9.2, lift=1.8, thick=.6), hip_roof(16.5, 9.6, 4.0, 15.6, lift=1.5, thick=.5),
             hip_roof(11, 7, 3.6, 22.4, lift=1.3, thick=.45)]
    put(roofs, A, "Roof", ROOF, 35)
    put([ridge(23, 13, 4.6, 9.2, w=.8), ridge(16.5, 9.6, 4.0, 15.6, w=.7), ridge(11, 7, 3.6, 22.4, w=.7)], A, "Ridge", RIDGE, 30)
    put([box((0, 27.4, 0), (1.4, 1.8, 1.4), bevel=.3, segments=2)], A, "Finial", ROOF_D, 30)

WING_W, WING_TIERS = 50, 4
def wing_seats():
    """Seat positions in Wing space (World seats spectators there)."""
    out = []
    for i in range(WING_TIERS):
        y = 2 + (i + 1) * 1.25
        z = -8.4 + i * 2.9 + 1.0
        x = -WING_W / 2 + 2
        while x <= WING_W / 2 - 2:
            out.append((x, y, z))
            x += 2.3
    return out

def wing():
    """A spectators' wing on the rim: stepped benches in an open gallery under
    a golden hip roof, a white back block with a band of windows."""
    A = "Wing"
    W = WING_W
    put([box((0, 1, 0), (W + 2, 2, 24), bevel=.15, segments=1)], A, "Base", STONE, 40)
    steps, benches = [], []
    for i in range(WING_TIERS):
        y = 2 + (i + 1) * 1.25
        z0 = -9.8 + i * 2.9
        steps.append(box((0, (2 + y) / 2, z0 + (13 - i * 2.9) / 2), (W - 1, y - 2, 13 - i * 2.9), bevel=0))
        benches.append(box((0, y + .3, z0 + 1.6), (W - 2, .55, 1.0), bevel=.05, segments=1))
    put(steps, A, "Steps", WHITE_D, 40)
    put(benches, A, "Benches", SEAT, 40)
    whites, darks, mulls = [box((0, 9, 7.5), (W, 14, 8), bevel=0)], [], []
    for s in (-1, 1):
        whites.append(box((s * (W / 2 - .4), 7.5, -1), (.8, 11, 18), bevel=0))
    d, m = window_strip(-W / 2 + 2, W / 2 - 2, 12.6, 2.4, 3.4, 3.0); darks += d; mulls += m
    put(whites, A, "White", WHITE, 40)
    put(darks, A, "Windows", WINDOW, 40)
    put(mulls, A, "Mullions", WHITE_D, 40)
    pillars = [cylinder((x, 2, -10.6), .55, 11.4, 10) for x in [-W / 2 + 1 + (W - 2) * k / 7 for k in range(8)]]
    put(pillars, A, "Pillars", WHITE_D, 40)
    rail = [box((0, 3.2, -11.2), (W, .3, .3), bevel=0)] + [box((x, 2.6, -11.2), (.25, 1.2, .25), bevel=0) for x in [-W / 2 + W * k / 20 for k in range(21)]]
    put(rail, A, "Rail", WOOD, 30)
    put([box((0, 13.6, -1), (W + 1, .8, 21), bevel=0)], A, "Beam", WOOD_D, 30)
    put([hip_roof(W / 2 + 3.5, 13.5, 5.4, 13.8, lift=1.8, thick=.6)], A, "Roof", ROOF, 35)
    put([ridge(W / 2 + 3.5, 13.5, 5.4, 13.8, w=.8)], A, "Ridge", RIDGE, 30)

def gate():
    """A doorway in the wall: dark opening, concrete frame, plaque."""
    A = "Gate"
    put([box((0, 0, .1), (16, 15, .3), bevel=0)], A, "Dark", (30, 30, 30), 40)
    put([box((x, -.2, -.05), (7.6, 14.4, .4), bevel=.08, segments=1) for x in (-3.9, 3.9)], A, "Doors", (92, 70, 52), 30)
    fr = [box((0, 8.3, -.4), (19.5, 1.8, 1.0), bevel=.15, segments=1)]
    fr += [box((x, .2, -.4), (1.8, 16.4, 1.0), bevel=.15, segments=1) for x in (-8.9, 8.9)]
    put(fr, A, "Frame", SEAM, 30, "Concrete")
    put([box((0, 11.2, -.35), (6, 2.2, .3), bevel=.05, segments=1)], A, "Plaque", WHITE_D, 30)

# ---------------------------------------------------------------- vegetation
def tree():
    """A whole field tree, 26 tall at scale 1: flared trunk, three limbs,
    a crown of faceted clumps (trunk and crown in one, nothing floats)."""
    A = "Tree"
    trunk = [loft([(0, 1.9, 1.9, 2), (1.2, 1.35, 1.35, 2), (8, 1.05, 1.05, 2), (15, .85, .85, 2)], sides=9)]
    for k, (az, el, L) in enumerate(((.4, 50, 7.5), (2.5, 44, 7), (4.4, 56, 6.5))):
        a = az; e = math.radians(el)
        p0 = Vector((0, 11.5 + k * 1.2, 0))
        p1 = p0 + Vector((math.sin(a) * math.cos(e), math.sin(e), math.cos(a) * math.cos(e))) * L
        d = p1 - p0; t = d.normalized(); side = Vector((math.cos(a), 0, -math.sin(a)))
        trunk.append(obox((p0 + p1) / 2, (.9, .9, d.length), side, t.cross(side), t))
    put(trunk, A, "Trunk", BARK, 35, "Wood")
    lumps = {LEAF: [], LEAF_D: [], LEAF_L: []}
    spots = [((0, 20, 0), (8, 5.5, 8), LEAF), ((-5.5, 17.5, 2), (5.6, 4.2, 5.6), LEAF_D), ((5, 18, -2.5), (5.8, 4.4, 5.8), LEAF_D),
             ((1, 17, 5.5), (5.2, 4, 5.2), LEAF), ((-2, 18, -5.5), (5.4, 4.2, 5.4), LEAF), ((1.5, 24, 1), (5.2, 3.8, 5.2), LEAF_L),
             ((-3.5, 22.5, -2), (4.4, 3.4, 4.4), LEAF_L), ((5, 21.5, 3), (4.2, 3.2, 4.2), LEAF)]
    for k, (c, r, col) in enumerate(spots):
        lumps[col].append(lumpy(c, r, 100 + k, amount=.14, segments=12, rings=8))
    put(lumps[LEAF], A, "Leaves", LEAF, 25, "Grass")
    put(lumps[LEAF_D], A, "LeavesDark", LEAF_D, 25, "Grass")
    put(lumps[LEAF_L], A, "LeavesLight", LEAF_L, 25, "Grass")

def bush():
    """A low hedge clump for the foot of the wall (about 10 wide, 5 tall)."""
    A = "Bush"
    put([lumpy((0, 2.2, 0), (3.6, 2.6, 3.2), 300, .15, 10, 7), lumpy((3, 1.6, .8), (2.8, 2.0, 2.6), 301, .15, 10, 7),
         lumpy((-3.2, 1.5, -.4), (2.6, 1.9, 2.4), 303, .15, 10, 7)], A, "Leaves", LEAF, 25, "Grass")
    put([lumpy((-1.2, 1.4, 1.6), (2.4, 1.8, 2.2), 302, .15, 10, 7), lumpy((1.6, 3.4, -.6), (2.2, 1.6, 2.0), 304, .15, 10, 7)], A, "LeavesDark", LEAF_D, 25, "Grass")

def tufts():
    """A patch of grass tufts: small leaning blades (about 6 across)."""
    A = "Tufts"
    r = random.Random(400)
    blades = {TUFT: [], GRASS_D: []}
    for k in range(26):
        x, z = r.uniform(-3, 3), r.uniform(-3, 3)
        h = r.uniform(.6, 1.3)
        lean = Vector((r.uniform(-.3, .3), 1, r.uniform(-.3, .3))).normalized()
        blades[TUFT if k % 3 else GRASS_D].append(spike(Vector((x, 0, z)), lean, h, .32, .12, sides=3, rings=2))
    put(blades[TUFT], A, "Blades", TUFT, 10, "Grass")
    put(blades[GRASS_D], A, "BladesDark", GRASS_D, 10, "Grass")

def grass_patch(A, seed, rx, rz):
    """A flat, irregular patch of grass lying on the sand."""
    r = random.Random(seed)
    S = 28
    bumps = [(r.uniform(0, 6.28), r.uniform(.08, .22), r.randint(2, 5)) for _ in range(4)]
    verts, faces = [], []
    for i in range(S):
        a = 2 * math.pi * i / S
        k = 1 + sum(m * math.sin(f * a + p) for p, m, f in bumps)
        verts.append((math.cos(a) * rx * k, 0, math.sin(a) * rz * k))
    for i in range(S):
        verts.append((verts[i][0], .12, verts[i][2]))
    faces.append(tuple(range(S)))
    faces.append(tuple(S + i for i in reversed(range(S))))
    for i in range(S):
        j = (i + 1) % S
        faces.append((i, j, S + j, S + i))
    o = nd_look._object(A, verts, faces)
    nd_look._outward(o)
    put(o, A, "Grass", GRASS if seed % 2 else GRASS_D, 30, "Grass")

wall_sector()
shell_sector()
hall()
wing()
gate()
tree()
bush()
tufts()
grass_patch("GrassA", 11, 9, 6)
grass_patch("GrassB", 22, 6, 4.5)
grass_patch("GrassC", 33, 14, 8)
export("Arena_Assets", OUT)

# ------------------------------------------------ review render (not exported)
def placed(asset, pos, yaw, scale=1.0):
    for o in [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(asset + "__") and "#" not in o.name]:
        d = o.copy(); d.name = o.name + "#"; bpy.context.scene.collection.objects.link(d)
        d.location = V(*pos); d.rotation_euler = (0, 0, yaw); d.scale = (scale, scale, scale)

originals = [o for o in bpy.data.objects if o.type == "MESH"]
for k in range(8):
    placed("WallSector", (0, 0, 0), k * math.pi / 4)
    placed("ShellSector", (0, 0, 0), k * math.pi / 4)
placed("Hall", (0, WALL_H + 16, -(RW + 12)), math.pi)
for a, s in ((.34, 1), (.7, .8)):
    for sg in (-1, 1):
        az = math.pi + sg * a
        placed("Wing", (math.sin(az) * (RW + 9), TOP, math.cos(az) * (RW + 9)), az, s)
placed("Gate", (0, 8, RW - .4), 0)
for k in range(48):
    a = k / 48 * math.pi * 2 + rng.uniform(-.04, .04)
    placed("Bush", (math.sin(a) * (RW - 4.5), 0, math.cos(a) * (RW - 4.5)), a * 7, 1 + (k % 3) * .2)
for spot in ((.55, 112, .9), (1.6, 104, .8), (2.4, 110, .85), (3.3, 98, .75), (3.9, 116, .95), (5.3, 106, .85), (6.0, 92, .75)):
    placed("Tree", (math.sin(spot[0]) * spot[1], 0, math.cos(spot[0]) * spot[1]), spot[0] * 3, spot[2])
for k in range(70):
    a = k / 70 * math.pi * 2 + rng.uniform(-.03, .03)
    r = RW + 40 + rng.uniform(0, 60)
    placed("Tree", (math.sin(a) * r, 0, math.cos(a) * r), a * 5, rng.uniform(1.4, 2.1))
for k in range(40):
    a = rng.uniform(0, 6.28); r = rng.uniform(60, RW - 10)
    placed(("GrassA", "GrassB", "GrassC")[k % 3], (math.sin(a) * r, 0, math.cos(a) * r), a, rng.uniform(.8, 1.4))
for k in range(60):
    a = rng.uniform(0, 6.28); r = rng.uniform(50, RW - 8)
    placed("Tufts", (math.sin(a) * r, 0, math.cos(a) * r), a, rng.uniform(.8, 1.3))
for o in originals:
    o.hide_render = True
ground = box((0, -.5, 0), (1400, 1, 1400), bevel=0); ground.color = (.33, .5, .27, 1)
field = cylinder((0, -.45, 0), RW, .5, 64); field.color = (.8, .72, .52, 1)
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
sh = scene.display.shading
sh.light = "STUDIO"; sh.color_type = "OBJECT"; sh.show_cavity = True; sh.show_shadows = True
sh.show_object_outline = False
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
cd = bpy.data.cameras.new("cam"); cd.lens = 24; cd.clip_end = 4000
cam = bpy.data.objects.new("cam", cd); scene.collection.objects.link(cam); scene.camera = cam
for key, (eye, target) in {"overview": ((0, 200, 360), (0, 0, -40)), "field": ((10, 7, 70), (0, 40, -150)), "aerial": ((260, 160, 260), (0, 10, 0))}.items():
    cam.location = V(*eye)
    cam.rotation_euler = (V(*target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT, "Arena_%s.png" % key)
    bpy.ops.render.render(write_still=True)
print("done")
