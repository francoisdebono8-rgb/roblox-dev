# Naruto (12-13), Blender pass v5 (user 29/10 14:37 "produis les designs sur
# Blender"; 14:52 "la tête est trop ronde ... les parties du corps toutes
# rondes ... toujours un problème sur les cheveux et le bandeau").
# - One head shape (nd_look.HEAD_PROFILE, a rounded box with a narrower
#   chin): the skin, the hair cap and the headband are all that profile grown
#   out by a fixed amount, so the band hugs the forehead and wraps the hair
#   exactly, everywhere.
# - Limbs and torso are rounded boxes (squircle sections), not tubes.
# - Orange jumpsuit, navy yoke, big white collar, rolled cuffs, the right-thigh
#   bandage and holster, navy sandals, blue-cloth headband with its plate,
#   wild blond hair in flat sharp spikes.
import sys, os, math
sys.path.insert(0, os.environ.get("ND_LIB", os.path.dirname(__file__)))
import importlib, nd_look
importlib.reload(nd_look)
from nd_look import *
from nd_look import _object, _outward

OUT = os.environ.get("ND_OUT", "/tmp")
reset()

SKIN = (252, 220, 186)
ORANGE, ORANGE_DARK = (250, 128, 30), (214, 92, 18)
NAVY = (34, 48, 104)
WHITE = (246, 244, 236)
HAIR, HAIR_SHADE = (255, 210, 60), (232, 166, 30)
CLOTH = (40, 70, 160)
METAL = (190, 198, 210)
SQ = 3.4   # squareness of the body sections

def folds(amount=.006, waves=3, rate=6):
    return lambda a, y: amount * math.sin(waves * a + y * rate) + amount * .5 * math.sin(7 * a - y * 11)

# ---------------------------------------------------------------- head
H = REST["Head"]
hy = H[1]
o = head_loft(H, -.95, .95, grow=0, steps=24, sides=56)
finish(o, "Head", "Skin", SKIN, smooth=50)

# ---------------------------------------------------------------- jumpsuit
ut = REST["UpperTorso"]
o = loft([(-.66, .84, .47, SQ), (-.3, .85, .48, SQ), (.05, .87, .49, SQ), (.34, .88, .49, SQ)],
         sides=40, center=ut, cap_top=False, wobble=folds())
finish(o, "UpperTorso", "Jacket", ORANGE)
o = loft([(.34, .88, .49, SQ), (.52, .88, .49, SQ), (.68, .8, .46, 3), (.79, .56, .4, 2.6)],
         sides=40, center=ut, cap_bottom=False)
finish(o, "UpperTorso", "Yoke", NAVY)
o = band(.72, .24, .78, .66, thick=.14, center=ut, n=2.6)
finish(o, "UpperTorso", "Collar", WHITE, smooth=60)
o = box((0, ut[1] - .1, -.505), (.07, 1.1, .03), bevel=.01)
finish(o, "UpperTorso", "Zip", WHITE)
o = box((0, ut[1] + .45, -.52), (.12, .16, .04), bevel=.02)
finish(o, "UpperTorso", "ZipPull", (200, 200, 208))

lt = REST["LowerTorso"]
o = loft([(-.62, .86, .5, SQ), (-.2, .85, .49, SQ), (.3, .83, .47, SQ), (.62, .81, .45, SQ)], sides=40, center=lt, wobble=folds(.006, 4, 9))
finish(o, "LowerTorso", "JacketHem", ORANGE)
o = box((0, .02, .54), (.6, .34, .2), bevel=.05)
finish(o, "LowerTorso", "Pouch", (84, 74, 66))

for side, s in (("Left", -1), ("Right", 1)):
    ua = REST[side + "UpperArm"]
    o = loft([(-.66, .37, .35, 3), (-.2, .38, .36, 3), (.2, .39, .37, 3)], sides=28, center=ua, cap_top=False, wobble=folds(.005, 2, 8))
    finish(o, side + "UpperArm", "Sleeve", ORANGE)
    o = loft([(.2, .39, .37, 3), (.45, .4, .38, 3), (.62, .34, .32, 2.6), (.7, .2, .2, 2.2)], sides=28, center=ua, cap_bottom=False)
    finish(o, side + "UpperArm", "Shoulder", NAVY)
    la = REST[side + "LowerArm"]
    o = loft([(-.5, .34, .33, 3), (-.1, .345, .335, 3), (.3, .34, .33, 3), (.6, .33, .32, 3)], sides=28, center=la, wobble=folds(.004, 3, 10))
    finish(o, side + "LowerArm", "Sleeve", ORANGE)
    o = band(-.4, .2, .4, .39, thick=.08, center=la, n=3)
    finish(o, side + "LowerArm", "Cuff", ORANGE_DARK, smooth=60)
    hd = REST[side + "Hand"]
    o = loft([(-.36, .2, .19, 3), (-.22, .29, .26, 3.2), (.06, .31, .28, 3.2), (.3, .28, .26, 3)], sides=24, center=hd)
    finish(o, side + "Hand", "Mitt", SKIN, smooth=50)
    o = box((hd[0] - s * .27, hd[1] + .02, -.12), (.14, .3, .16), bevel=.05, segments=3)
    finish(o, side + "Hand", "Thumb", SKIN, smooth=50)
    ul = REST[side + "UpperLeg"]
    o = loft([(-.66, .41, .4, 3), (0, .43, .42, 3), (.5, .45, .43, 3), (.68, .44, .42, 3)], sides=28, center=ul, wobble=folds(.006, 3, 7))
    finish(o, side + "UpperLeg", "Pants", ORANGE)
    ll = REST[side + "LowerLeg"]
    o = loft([(-.56, .43, .42, 3), (-.2, .42, .41, 3), (.3, .4, .39, 3), (.62, .39, .38, 3)], sides=28, center=ll, wobble=folds(.006, 3, 9))
    finish(o, side + "LowerLeg", "Pants", ORANGE)
    o = band(-.42, .26, .47, .46, thick=.1, center=ll, n=3)
    finish(o, side + "LowerLeg", "PantCuff", ORANGE_DARK, smooth=60)
    f = REST[side + "Foot"]
    o = box((f[0], f[1] - .2, f[2] - .02), (.78, .1, 1.18), bevel=.05, segments=3)
    finish(o, side + "Foot", "Sole", (60, 48, 44))
    o = loft([(-.15, .37, .3, 3), (.1, .36, .29, 3), (.22, .3, .24, 2.6)], sides=24, center=(f[0], f[1], f[2] + .28))
    finish(o, side + "Foot", "Heel", NAVY)
    for z in (-.06, -.3):
        o = box((f[0], f[1] - .04, f[2] + z), (.8, .16, .14), bevel=.04)
        finish(o, side + "Foot", "Strap", NAVY)
    o = box((f[0], f[1] - .1, f[2] - .44), (.62, .2, .34), bevel=.08, segments=3)
    finish(o, side + "Foot", "Toes", SKIN, smooth=50)

ul = REST["RightUpperLeg"]
o = band(-.02, .36, .48, .47, thick=.06, center=ul, n=3)
finish(o, "RightUpperLeg", "ThighWrap", WHITE, smooth=60)
o = box((ul[0] + .5, ul[1] - .05, 0), (.18, .46, .42), bevel=.05)
finish(o, "RightUpperLeg", "Holster", NAVY)

# ---------------------------------------------------------------- hair + band
BAND_Y0, BAND_Y1 = .3, .56
# Cap: the head grown .05, from the nape up; cut on a plane that runs from
# the top of the band at the front down to the nape at the back.
cap = head_loft(H, -.5, .95, grow=.05, steps=20, sides=56)
cut_below(cap, (0, hy + BAND_Y1, -.9), (0, 1.8, 1.0))
solidify_in(cap, .03)
finish(cap, "Head", "HairCap", HAIR_SHADE, smooth=55)
# Band: the head grown .1 between its two edges, .07 thick (inner wall at
# .03: it covers the cap edge, never cuts the forehead).
o = head_loft(H, BAND_Y0, BAND_Y1, grow=.1, steps=4, sides=64, cap_top=False, cap_bottom=False)
solidify_in(o, .07)
finish(o, "Head", "Headband", CLOTH, smooth=60)
o = head_panel(H, -.34, .34, BAND_Y0 + .02, BAND_Y1 - .02, .1, .145, nx=16, ny=3)
finish(o, "Head", "HeadbandPlate", METAL, smooth=30, reflect=.12)
mark = []
for k in range(14):
    a = 2 * math.pi * k / 14
    p = head_point(H, math.cos(a) * .07, (BAND_Y0 + BAND_Y1) / 2 + math.sin(a) * .07, .145)
    mark.append(box(tuple(p), (.03, .03, .03), bevel=0))
p = head_point(H, .1, (BAND_Y0 + BAND_Y1) / 2 + .06, .145)
mark.append(box(tuple(p), (.09, .025, .03), bevel=0))
o = join(mark, "mark")
finish(o, "Head", "PlateMark", (110, 118, 132), smooth=20)
for s in (-1, 1):
    a, b, n = head_section(BAND_Y0)
    o = box((s * .16, hy + BAND_Y0 - .3, b + .12), (.2, .64, .05), bevel=.02)
    finish(o, "Head", "BandTail" + ("L" if s < 0 else "R"), CLOTH)

# Spikes: rooted inside the cap above the band, flat, sharp, bursting out
# and up all round; a little curl upward at the tips.
def root(az, el, inset=.2):
    a, e = math.radians(az), math.radians(el)
    y = .1 + .9 * math.sin(e)
    hx, hz, n = head_section(y)
    d = Vector((math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e)))
    p = Vector((H[0] + math.sin(a) * hx * 1.05, hy + y, H[2] - math.cos(a) * hz * 1.05))
    return p - d * inset, d

spec = [
    (0, 66, 1.0, .78, .55, .15), (32, 56, 1.05, .76, .45, .12), (-32, 56, 1.05, .76, .45, .12),
    (64, 48, 1.05, .74, .35, .1), (-64, 48, 1.05, .74, .35, .1), (96, 40, 1.0, .72, .3, .1), (-96, 40, 1.0, .72, .3, .1),
    (128, 36, 1.1, .76, .3, .1), (-128, 36, 1.1, .76, .3, .1), (158, 36, 1.15, .78, .25, .1), (-158, 36, 1.15, .78, .25, .1),
    (180, 30, 1.05, .76, .15, .05), (180, 62, 1.0, .74, .35, .1), (0, 84, .9, .7, .9, .1), (60, 74, .95, .7, .7, .1),
    (-60, 74, .95, .7, .7, .1), (140, 66, 1.0, .72, .5, .1), (-140, 66, 1.0, .72, .5, .1),
]
parts, shade = [], []
for i, (az, el, length, width, up, curl) in enumerate(spec):
    p, d = root(az, el)
    d = (d + Vector((0, up, 0))).normalized()
    o = spike(p, d, length, width, width * .42, bend=(0, curl, 0), sides=8, twist=.25, rings=6)
    (shade if i % 4 == 2 else parts).append(o)
o = join(parts, "hair"); finish(o, "Head", "Hair", HAIR, smooth=25)
o = join(shade, "hairShade"); finish(o, "Head", "HairShade", HAIR_SHADE, smooth=25)
# Fringe: flat locks that lie on top of the band (offset past it) and stop
# just above the brows.
fringe = []
for x0, x1, y1 in ((-.52, -.66, .3), (-.32, -.4, .52), (-.12, -.14, .62), (.12, .14, .62), (.32, .4, .52), (.52, .66, .3)):
    pts = []
    for k in range(9):
        t = k / 8
        y = .86 - (.86 - y1) * t
        x = x0 + (x1 - x0) * t
        out = .07 + .1 * min(1, max(0, (BAND_Y1 + .14 - y) / .14))
        pts.append(tuple(head_point(H, x, y, out)))
    fringe.append(lock_path(pts, lambda p: (p[0] * .3, .25, -1), .44, .13, sides=7))
for s in (-1, 1):
    pts = [tuple(Vector((s * .92, hy + .5 - .7 * k / 7, -.25 - .1 * k / 7))) for k in range(8)]
    fringe.append(lock_path(pts, lambda p, s=s: (s, 0, -.3), .4, .14, sides=7))
o = join(fringe, "fringe"); finish(o, "Head", "Fringe", HAIR, smooth=30)

export("Look_Naruto", OUT)
preview("Look_Naruto", OUT, stand_in=False)
print("done")
