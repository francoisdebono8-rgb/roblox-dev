# The Ōtsutsuki, host of the tournament (26/11-27/11, passe 3; François's four reference
# images, 23:38 and 23:50: « fais entièrement Otsutsuki comme un vrai perso »). Built like
# the eight (look_*.py on nd_look / nd_kit, the duel rig's rest pose): a whole character,
# not a costume over a stand-in.
#   the head: pale skin; a big mass of white hair in broad faceted locks, spilling from the
#     crown every way, long locks down both sides to the chest, a fringe parted round the
#     third eye; two thick cream horns curving out of the top, a dark purple ring at the
#     foot of each; a small blue diamond on the crown; the red third eye in a black rim;
#     the black mask from under the eyes to the neck, its top edge rising to a point over
#     the nose, edged in gold. The eyes (both Rinnegan) are drawn (Client/BossFX).
#   the body: a black robe; a high collar with gold and violet stripes either side of the
#     front; a white breastplate cut in a V at the neck with four black tomoe across it;
#     huge bevelled black shoulder guards, a gold band along their foot, a red magatama on
#     the outer face; black sleeves with gold cuffs; white hands; the robe's long skirts,
#     white panels with two tomoe each, edged in gold; black trousers and boots.
import sys, os, math
sys.path.insert(0, os.environ.get("ND_LIB", os.path.dirname(__file__)))
import importlib, nd_look, nd_kit
importlib.reload(nd_look); importlib.reload(nd_kit)
from nd_look import *
from nd_kit import *
from mathutils import Vector
OUT = os.environ.get("ND_OUT", "/tmp")
reset()
UT = REST["UpperTorso"]; LT = REST["LowerTorso"]
SKIN = skin_tone((246, 238, 238)); HAIR, HAIR_S = (226, 224, 232), (186, 184, 198)
ROBE, ROBE_D = (26, 24, 32), (16, 15, 20); GOLD = (214, 170, 62); VIOLET = (92, 72, 124)
WHITE = off_white((236, 234, 238)); INK = (24, 22, 28); RED = (206, 30, 38)
HORN = (234, 224, 204); RING = (54, 38, 64); GEM = (78, 132, 206)


def magatama(body, centre, right, up, out, r, colour, name):
    """A flat comma: a round head, its tail curling down and round under it."""
    c = Vector(centre)
    right, up, out = Vector(right), Vector(up), Vector(out)
    pieces = [ellipsoid(tuple(c), (r, r, r * .14), segments=16, rings=8, name="mh")]
    pts = []
    for k in range(8):
        a = math.radians(-15 - 26 * k)
        rr = r * (1.05 + .1 * k)
        pts.append(tuple(c + right * (rr * math.cos(a) * .9) + up * (rr * math.sin(a) - r * .15 * k) + out * .01))
    pieces.append(lock_path(pts, lambda p: tuple(out), r * .9, r * .2, sides=6, taper=.95))
    finish(join(pieces, "m"), body, name, colour, smooth=50)


# ------------------------------------------------------------------ head
head(SKIN)
# the mask: from under the eyes down over the neck, a point rising over the nose
o = head_loft(H, -.97, -.3, grow=.035, steps=10, sides=56, cap_top=False); finish(o, "Head", "Mask", ROBE_D, smooth=50)
pts = []
for k in range(15):
    x = -.62 + 1.24 * k / 14
    y = -.3 + .2 * max(0.0, 1 - abs(x) / .26)
    pts.append(tuple(head_point(H, x, y, .05)))
o = lock_path(pts, lambda p: (0, 0, -1), .07, .05, sides=6, taper=0.0); finish(o, "Head", "MaskTrim", GOLD, smooth=40, reflect=.1)
# the point over the nose: a wedge of the mask rising to the trim's peak
wedge = [tuple(head_point(H, 0, -.34 + .23 * k / 6, .035)) for k in range(7)]
o = lock_path(wedge, lambda p: (0, 0, -1), .56, .04, sides=6, taper=1.0); finish(o, "Head", "MaskPeak", ROBE_D, smooth=50)
# the third eye
finish(ellipsoid((0, HY + .42, -.86), (.13, .19, .05), name="rim"), "Head", "ThirdEyeRim", INK, smooth=60)
finish(ellipsoid((0, HY + .42, -.89), (.085, .14, .04), name="eye"), "Head", "ThirdEye", RED, smooth=60, material="Neon")
# the hair
hair_mass(HAIR, puff=.1, back=-.85, nape_puff=.2, band=(.3, .5))
crown = []
for i in range(16):
    az = -180 + 360 * (i + .5) / 16
    if abs(az) < 40:
        continue                                  # the front: the fringe does it
    crown.append((az, 62, 1.15, .82, -.35, -.25, 0))
for i in range(12):
    az = -180 + 360 * (i + .5) / 12
    if abs(az) < 50:
        continue
    crown.append((az, 36, 1.3, .8, -.55, -.3, 0))
crown += [(70, 22, 1.2, .9, -.6, -.2, .35), (-70, 22, 1.2, .9, -.6, -.2, -.35), (110, 20, 1.25, .95, -.7, -.2, .3),
          (-110, 20, 1.25, .95, -.7, -.2, -.3), (150, 18, 1.2, .74, -.75, -.2, 0), (-150, 18, 1.2, .74, -.75, -.2, 0),
          (180, 30, 1.3, .8, -.7, -.2, 0), (0, 86, .95, .9, .3, -.3, 0)]
spikes(crown, HAIR, HAIR_S, flat=.4)
# the fringe: broad locks parted round the third eye, down beside the eyes
fringe([(-.62, -.86, -.25), (-.4, -.6, -.05), (-.2, -.34, .12), (.2, .34, .12), (.4, .6, -.05), (.62, .86, -.25)],
       HAIR, band_top=None, width=.36, thick=.12, taper=.85, top=.88)
# long locks down the sides, to the chest
side_locks(HAIR, x=.86, top=.55, length=2.2, z=-.42, width=.5, thick=.15, lean=.08)
side_locks(HAIR, x=.92, top=.5, length=1.9, z=-.05, width=.5, thick=.15, lean=.12, name="SideLocksBack")
back_mass(HAIR, bottom=-1.9, width=1.0, depth=.55, z=.6, top=.45)
# the horns, their rings, the gem
for s in (-1, 1):
    base = Vector((s * .5, HY + .88, .05))
    pts = [tuple(base + Vector((s * (.75 * t - .45 * t * t), 1.45 * t + .1 * t * t, -.05 * t))) for t in [k / 10 for k in range(11)]]
    o = lock_path(pts, lambda p: (0, 0, -1), .52, .52, sides=12, taper=.98)
    finish(o, "Head", "Horn" + ("L" if s < 0 else "R"), HORN, smooth=50)
    o = band(HY + .86 - H[1], .2, .3, .3, thick=.16, center=(s * .5, H[1], .05), n=2, sides=24)
    finish(o, "Head", "HornRing" + ("L" if s < 0 else "R"), RING, smooth=50)
o = box((0, HY + 1.0, -.42), (.24, .08, .24), bevel=.0); rotated(o, (0, HY + 1.0, -.42), 0)
turned(o, (0, HY + 1.0, -.42), 45, "X")
finish(o, "Head", "Gem", GEM, material="Glass", reflect=.2)

# ------------------------------------------------------------------ body
torso(ROBE)
collar(ROBE, y=.78, height=.58, hx=.76, hz=.66, thick=.09, flare=.02)
for s in (-1, 1):
    for x, col, nm in ((.14, GOLD, "CollarGold"), (.26, VIOLET, "CollarViolet"), (.38, GOLD, "CollarGold2")):
        o = box((s * x, UT[1] + 1.1, -.69), (.05, .5, .04), bevel=.01); finish(o, "UpperTorso", nm + ("L" if s < 0 else "R"), col, reflect=.05)
# the breastplate: white over the chest, its top cut in a V (the black robe shows in it)
o = box((0, UT[1] + .02, -.56), (1.62, 1.18, .08), bevel=.03); finish(o, "UpperTorso", "Breastplate", WHITE)
vee = [tuple(Vector((0, UT[1] + .62 - .5 * k / 6, -.62))) for k in range(7)]
o = lock_path(vee, lambda p: (0, 0, -1), .95, .04, sides=6, taper=1.0); finish(o, "UpperTorso", "PlateVee", ROBE)
for s in (-1, 1):
    o = box((s * .25, UT[1] + .37, -.63), (.62, .07, .05), bevel=.015); rotated(o, (s * .25, UT[1] + .37, -.63), s * 40)
    finish(o, "UpperTorso", "PlateEdge" + ("L" if s < 0 else "R"), WHITE)
for i, x in enumerate((-.54, -.18, .18, .54)):
    magatama("UpperTorso", (x, UT[1] - .2, -.62), (1, 0, 0), (0, 1, 0), (0, 0, -1), .12, INK, "Tomoe%d" % i)
hips(ROBE, length=.7)
# the skirts: front and back panels to the knees, white panels with two tomoe, gold hems
for s in (-1, 1):
    side = "Left" if s < 0 else "Right"
    leg = REST[side + "UpperLeg"]
    o = box((leg[0], leg[1] - .15, -.56), (.9, 1.6, .06), bevel=.02); finish(o, side + "UpperLeg", "Skirt", ROBE)
    o = box((leg[0], leg[1] - .15, -.6), (.66, 1.3, .03), bevel=.01); finish(o, side + "UpperLeg", "SkirtPanel", WHITE)
    o = box((leg[0], leg[1] - .95, -.6), (.92, .07, .07), bevel=.01); finish(o, side + "UpperLeg", "SkirtHem", GOLD, reflect=.05)
    for k, y in enumerate((.2, -.35)):
        magatama(side + "UpperLeg", (leg[0], leg[1] + y, -.63), (1, 0, 0), (0, 1, 0), (0, 0, -1), .14, INK, "SkirtTomoe%d" % k)
    o = box((leg[0], leg[1] - .15, .56), (.9, 1.6, .06), bevel=.02); finish(o, side + "UpperLeg", "SkirtBack", ROBE)
# arms: black sleeves, gold cuffs, the shoulder guards
arms(ROBE, ROBE, cuff=GOLD)
hands(WHITE)
for s in (-1, 1):
    side = "Left" if s < 0 else "Right"
    sh = REST[side + "UpperArm"]
    c = (sh[0] + s * .12, sh[1] + .32, 0)
    o = box(c, (1.25, 1.0, 1.35), bevel=.16, segments=3); finish(o, side + "UpperArm", "Guard", ROBE)
    o = box((c[0], c[1] - .42, c[2]), (1.29, .1, 1.39), bevel=.03); finish(o, side + "UpperArm", "GuardGold", GOLD, reflect=.08)
    magatama(side + "UpperArm", (c[0] + s * .64, c[1] + .06, 0), (0, 0, -s), (0, 1, 0), (s, 0, 0), .22, RED, "GuardMark")
    magatama(side + "UpperArm", (c[0], c[1] + .51, -.1), (s, 0, 0), (0, 0, -1), (0, 1, 0), .16, RED, "GuardMarkTop")
legs(ROBE)
sandals(ROBE_D, SKIN)
for side in ("Left", "Right"):
    leg_band(side, -.3, .3, ROBE_D)
export("Look_Otsutsuki", OUT)
preview("Look_Otsutsuki", OUT, stand_in=False)
print("done")
