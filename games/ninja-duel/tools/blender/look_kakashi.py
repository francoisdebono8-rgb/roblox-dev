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
spikes([(0, 66, 1.15, .7, .8, .15, -.3), (-30, 60, 1.15, .7, .7, .12, -.35), (30, 64, 1.0, .66, .8, .1, -.2), (-65, 50, 1.05, .68, .5, .1, -.4),
        (65, 52, .9, .62, .6, .1, -.1), (-100, 40, .95, .64, .3, .1, -.4), (100, 44, .8, .58, .4, .05), (-140, 40, 1.0, .66, .35, .1, -.3),
        (140, 42, .9, .62, .35, .05), (180, 40, 1.0, .66, .35, .1, -.2), (180, 66, 1.0, .64, .7, .1, -.3), (0, 84, .9, .62, 1.0, .1, -.3),
        (-150, 68, .9, .62, .6, .1, -.3), (150, 68, .85, .6, .6, .1)] + band_crown(HAIR, count=14, length=.55, width=.5, up=1.2), HAIR, HAIR_S)
bangs([(-.4, -.58, .26), (-.12, -.24, .3), (.18, .08, .3)], HAIR, width=.4)
side_locks(HAIR, x=.88, top=.45, length=.75, z=-.3, width=.36)
export("Look_Kakashi", OUT)
preview("Look_Kakashi", OUT, stand_in=False)
print("done")
