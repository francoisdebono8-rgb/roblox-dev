# Neji (13), Blender pass: the pale high-collared long-sleeved shirt hanging
# over the hips, dark shorts, bandaged right thigh and shins, the headband,
# long straight dark-brown hair down the back, parted bangs.
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
SKIN = (252, 228, 206); HAIR, HAIR_S = (70, 46, 36), (96, 64, 48)
SHIRT, SHIRT_S = (236, 230, 216), (204, 196, 180); SHORTS = (64, 58, 62); WRAP = (246, 244, 238)
head(SKIN)
torso(SHIRT)
collar(SHIRT, y=.8, height=.42, hx=.74, hz=.64, flare=.06, thick=.06)
finish(box((-.16, UT[1] - .05, -.5), (.05, 1.1, .03), bevel=.01), "UpperTorso", "Fold", SHIRT_S)
hips(SHIRT, length=.75, flare=.05)
legs(SHORTS, lower=SKIN)
for side in ("Left", "Right"):
    leg_band(side, .1, .7, WRAP)
leg_band("Right", 0, .5, WRAP, body="UpperLeg")
holster((50, 46, 52))
arms(SHIRT, SHIRT, cuff=SHIRT_S, bulk=.03)
hands(SKIN)
sandals((50, 46, 58), SKIN)
headband((42, 42, 54))
hair_mass(HAIR, back=-.8, nape_puff=.14)
back_mass(HAIR, bottom=-.95, width=.92, depth=.42, z=.52, top=.55)
# The long hair: three locks from the back of the head down to the waist,
# gathered by a tie near the ends.
long = []
for dx, spread in ((-.22, -.08), (0, 0), (.22, .08)):
    pts = [tuple(Vector((dx + spread * k / 10, HY - .3 - 2.7 * k / 10, .8 + .06 * math.sin(k / 10 * math.pi) - .02 * k))) for k in range(11)]
    long.append(lock_path(pts, lambda p: (0, 0, 1), .38, .2, sides=8, taper=.35))
finish(join(long, "long"), "Head", "LongHair", HAIR, smooth=40)
finish(band(-2.55, .12, .28, .16, thick=.05, center=(0, HY, .63), n=2), "Head", "HairTie", (240, 236, 226))
side_locks(HAIR, x=.87, top=.6, length=1.5, z=-.44, width=.46, thick=.15)
bangs([(-.22, -.4, .26), (.22, .4, .26)], HAIR, width=.42)
export("Look_Neji", OUT)
preview("Look_Neji", OUT, stand_in=False)
print("done")
