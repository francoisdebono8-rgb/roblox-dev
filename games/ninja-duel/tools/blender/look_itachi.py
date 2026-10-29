# Itachi (13, the ANBU years; user 29/10 reference): dark short-sleeved
# high-collared shirt, pale ANBU chest armour on shoulder straps with its
# padded waist band, long arm guards with a pale plate, dark trousers, the
# headband, long bangs and a low ponytail, a sword longer than Kakashi's
# across his back. The tear lines and the Sharingan are drawn.
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
SKIN = (248, 224, 204); HAIR = (24, 24, 32); SHIRT = (32, 32, 44)
ARMOR, ARMOR_S = (186, 184, 204), (150, 148, 170); PANTS = (48, 48, 62)
head(SKIN)
torso(SHIRT)
collar(SHIRT, y=.8, height=.44, hx=.74, hz=.64, flare=.1, thick=.06)
o = loft([(-.62, .8, .53, 3.6), (-.2, .83, .54, 3.6), (.3, .85, .54, 3.6), (.56, .8, .51, 3.4)], sides=40, center=UT); finish(o, "UpperTorso", "ChestArmor", ARMOR)
for s in (-1, 1):
    finish(box((s * .42, UT[1] + .6, 0), (.3, .1, 1.08), bevel=.03), "UpperTorso", "ArmorStrap", ARMOR)
    o = box((s * .5, UT[1] - .44, -.55), (.22, .16, .05), bevel=.02); rotated(o, (s * .5, UT[1] - .44, -.55), -s * 30); finish(o, "UpperTorso", "Buckle", ARMOR_S)
finish(band(.25, .4, .93, .57, thick=.1, center=LT, n=3.4), "LowerTorso", "ArmorBand", ARMOR)
hips(SHIRT)
arms(SHIRT, SKIN, sleeve_end=-.15, skin=SKIN)
arm_guard((30, 30, 42), plate=ARMOR, top=.4, bottom=-.5)
hands(SKIN)
legs(PANTS, baggy=.03)
for side in ("Left", "Right"):
    leg_band(side, -.3, .3, (226, 224, 232))
sandals((34, 34, 46), SKIN)
sword_on_back(2.6, (.08, UT[1], .62), -28, hilt_len=.78)
headband((36, 42, 62))
hair_mass(HAIR, back=-.8, nape_puff=.16)
back_mass(HAIR, bottom=-1.0, width=.92, depth=.4, z=.5, top=.4)
side_locks(HAIR, x=.87, top=.6, length=1.55, z=-.44, width=.48, thick=.16)
bangs([(-.3, -.38, .22), (-.06, -.08, .26), (.18, .22, .24)], HAIR, width=.42)
pts = [tuple(Vector((0, HY - .7 - 1.9 * k / 10, .86 + .16 * k / 10))) for k in range(11)]
finish(lock_path(pts, lambda p: (0, 0, 1), .4, .26, sides=8, taper=.55), "Head", "Ponytail", HAIR, smooth=40)
finish(band(-.7, .1, .23, .2, thick=.04, center=(0, HY, .85), n=2), "Head", "HairTie", (70, 30, 40))
export("Look_Itachi", OUT)
preview("Look_Itachi", OUT, stand_in=False)
print("done")
