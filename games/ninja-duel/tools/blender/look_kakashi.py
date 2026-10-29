# Kakashi (13; user 29/10 "version Storm, un petit sabre dans le dos" and
# reference): black suit, the mask up over the nose, brown straps crossed on
# the chest with a metal clasp, grey shoulder guards, black arm guards with
# metal plates, a pale belt, the tanto across the back (hilt over the right
# shoulder), the headband, silver hair swept up and to his left.
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
SKIN = (250, 226, 204); HAIR, HAIR_S = (214, 220, 230), (170, 178, 194)
SUIT, SUIT_D = (30, 32, 42), (20, 22, 30); LEATHER = (124, 82, 56); METAL = (176, 182, 196); BELT = (206, 190, 150)
head(SKIN)
o = head_loft(H, -.97, -.24, grow=.03, steps=10, sides=56, cap_top=False); finish(o, "Head", "Mask", SUIT, smooth=50)
torso(SUIT)
collar(SUIT, y=.78, height=.36, hx=.74, hz=.64, thick=.08)
for z in (-.5, .5):
    for ang in (34, -34):
        o = box((0, UT[1] - .04, z), (.22, 2.05, .05), bevel=.02); rotated(o, (0, UT[1] - .04, z), ang); finish(o, "UpperTorso", "Strap", LEATHER)
o = box((0, UT[1] - .04, -.54), (.3, .3, .06), bevel=.02); rotated(o, (0, UT[1] - .04, -.54), 45); finish(o, "UpperTorso", "Clasp", METAL, reflect=.08)
hips(SUIT)
finish(band(.32, .22, .88, .52, thick=.06, center=LT, n=3.4), "LowerTorso", "Belt", BELT)
finish(box((0, .32, -.55), (.32, .24, .06), bevel=.02), "LowerTorso", "Buckle", METAL, reflect=.08)
finish(box((0, .1, .55), (.6, .32, .22), bevel=.05), "LowerTorso", "Pouch", (96, 62, 42))
arms(SUIT, SUIT, shoulder=METAL)
arm_guard(SUIT_D, plate=METAL, top=.3, bottom=-.46)
hands(SKIN)
legs(SUIT)
for side in ("Left", "Right"):
    leg_band(side, -.32, .3, (206, 196, 170))
holster(SUIT_D)
sandals(SUIT_D, SKIN)
sword_on_back(1.7, (.1, UT[1] + .12, .62), -36, hilt_len=.6)
headband((30, 36, 56))
hair_mass(HAIR)
spikes([(0, 62, 1.3, .78, .9, .15, -.6), (-25, 58, 1.35, .8, .8, .15, -.75), (-55, 50, 1.3, .78, .6, .12, -.9), (-85, 40, 1.15, .74, .4, .1, -.95),
        (25, 64, 1.1, .72, .9, .12, -.5), (55, 56, .95, .66, .8, .1, -.4), (85, 46, .8, .6, .6, .05, -.3), (-120, 40, 1.15, .74, .4, .1, -.7),
        (120, 44, .75, .56, .5, .05, -.2), (-150, 44, 1.1, .72, .45, .1, -.6), (150, 46, .8, .58, .5, .05, -.3), (180, 44, 1.0, .7, .5, .1, -.5),
        (180, 70, 1.05, .7, .9, .1, -.6), (0, 84, 1.0, .68, 1.2, .1, -.6), (-160, 70, 1.0, .68, .7, .1, -.6), (-60, 74, 1.05, .7, 1.0, .1, -.7)]
       + band_crown(HAIR, count=12, length=.5, width=.5, up=1.0, skip_front=35), HAIR, HAIR_S)
bangs([(-.44, -.7, .1), (-.2, -.36, .22), (.06, -.06, .3)], HAIR, width=.42)
side_locks(HAIR, x=.88, top=.45, length=.55, z=-.3, width=.34)
export("Look_Kakashi", OUT)
preview("Look_Kakashi", OUT, stand_in=False)
print("done")
