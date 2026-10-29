# Rock Lee (13), Blender pass: the green jumpsuit, orange leg warmers rolled
# at the top, the headband worn as a red belt, bandaged hands and forearms,
# the glossy black bowl cut (straight fringe above the brows).
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
SKIN = (252, 222, 192); GREEN, GREEN_D = (56, 170, 74), (40, 132, 58)
WARMER, ROLL = (250, 134, 40), (230, 110, 30); HAIR = (16, 16, 22); WRAP = (244, 240, 228); BELT = (190, 40, 40)
head(SKIN)
torso(GREEN)
collar(GREEN_D, y=.74, height=.22, hx=.72, hz=.62, thick=.1)
finish(box((0, UT[1] - .05, -.5), (.06, 1.25, .03), bevel=.01), "UpperTorso", "Seam", GREEN_D)
hips(GREEN)
finish(band(.3, .26, .88, .52, thick=.06, center=LT, n=3.4), "LowerTorso", "Belt", BELT)
finish(box((0, .3, -.55), (.5, .3, .05), bevel=.02), "LowerTorso", "BeltPlate", (190, 198, 210), reflect=.12)
arms(GREEN, WRAP)
hands(SKIN, wrap=WRAP)
legs(GREEN, lower=WARMER, baggy=.03)
for side in ("Left", "Right"):
    leg_band(side, .44, .22, ROLL, grow=.09)
sandals((40, 46, 66), SKIN)
o = head_loft(H, .24, .95, grow=.08, steps=12, sides=56); finish(o, "Head", "Bowl", HAIR, smooth=55, reflect=.04)
o = head_loft(H, -.5, .3, grow=.07, steps=10, sides=56); cut_below(o, (0, HY, -.2), (0, 0, 1)); finish(o, "Head", "BackHair", HAIR, smooth=55, reflect=.04)
for s in (-1, 1):
    finish(box((s * .9, HY + .08, -.3), (.12, .36, .3), bevel=.04), "Head", "Sideburn", HAIR)
export("Look_Lee", OUT)
preview("Look_Lee", OUT, stand_in=False)
print("done")
