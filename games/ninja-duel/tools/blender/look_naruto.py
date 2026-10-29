# Naruto (12-13), Blender pass v6 (user 29/10: 14:37 "produis les designs sur
# Blender"; 14:52 head/body too round; 15:19 "les mains sont des moignons",
# "cheveux, bandeau, faut que tu t'y attardes"). Built on nd_kit: the head
# profile, the band worn over the hair (the bangs come out under it, the
# hair puffs over it), fists with fingers.
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
SKIN = (252, 220, 186)
ORANGE, ORANGE_DARK = (250, 128, 30), (214, 92, 18)
NAVY = (34, 48, 104); WHITE = (246, 244, 236)
HAIR, HAIR_S = (255, 210, 60), (232, 166, 30)
head(SKIN)
torso(NAVY, ORANGE)
collar(WHITE, y=.72, height=.24, hx=.78, hz=.66, thick=.14)
finish(box((0, UT[1] - .1, -.505), (.07, 1.1, .03), bevel=.01), "UpperTorso", "Zip", WHITE)
finish(box((0, UT[1] + .45, -.52), (.12, .16, .04), bevel=.02), "UpperTorso", "ZipPull", (200, 200, 208))
for r, z, c in ((.32, .5, (214, 40, 34)), (.2, .512, ORANGE), (.08, .524, (214, 40, 34))):
    finish(ellipsoid((.03 if r == .2 else 0, UT[1] - .05, z), (r, r, .02), segments=36, rings=8), "UpperTorso", "Swirl%d" % int(r * 100), c)
hips(ORANGE)
finish(box((0, .02, .54), (.6, .34, .2), bevel=.05), "LowerTorso", "Pouch", (84, 74, 66))
arms(ORANGE, ORANGE, shoulder=NAVY, cuff=ORANGE_DARK)
hands(SKIN)
legs(ORANGE, cuff=ORANGE_DARK)
leg_band("Right", -.02, .36, WHITE, body="UpperLeg")
holster(NAVY)
sandals(NAVY, SKIN)
headband((40, 70, 160))
hair_mass(HAIR)
spikes([(0, 70, .95, .74, .55, .15), (32, 60, 1.0, .74, .45, .12), (-32, 60, 1.0, .74, .45, .12),
        (64, 50, 1.0, .72, .35, .1), (-64, 50, 1.0, .72, .35, .1), (96, 42, .95, .7, .3, .1), (-96, 42, .95, .7, .3, .1),
        (128, 38, 1.05, .74, .3, .1), (-128, 38, 1.05, .74, .3, .1), (158, 38, 1.1, .76, .25, .1), (-158, 38, 1.1, .76, .25, .1),
        (180, 20, 1.0, .74, .1, .05), (150, 12, .85, .66, 0, .05), (-150, 12, .85, .66, 0, .05), (112, 18, .8, .6, 0, .05), (-112, 18, .8, .6, 0, .05),
        (180, 62, 1.0, .74, .35, .1), (0, 86, .85, .7, .9, .1), (60, 76, .9, .7, .7, .1), (-60, 76, .9, .7, .7, .1), (140, 68, .95, .72, .5, .1), (-140, 68, .95, .72, .5, .1)], HAIR, HAIR_S)
bangs([(-.56, -.72, .06), (-.32, -.38, .24), (-.1, -.12, .28), (.12, .14, .24), (.34, .4, .28), (.58, .74, .08)], HAIR, width=.42, thick=.12)
export("Look_Naruto", OUT)
preview("Look_Naruto", OUT, stand_in=False)
print("done")
