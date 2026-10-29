# Sasuke (12), Blender pass: navy high-collared short-sleeved shirt with a
# red-and-white roundel on the back, white shorts, pale arm warmers, leg
# wraps, blue-black hair swept back in spikes, long bangs framing the face.
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
SKIN = (250, 226, 204); HAIR, HAIR_S = (30, 34, 56), (50, 58, 92)
NAVY, NAVY_D = (36, 46, 96), (26, 32, 70); WHITE = (238, 236, 230); WARM = (214, 214, 224)
head(SKIN)
torso(NAVY)
collar(NAVY, y=.8, height=.44, hx=.74, hz=.64, flare=.16, thick=.06)
o = ellipsoid((0, UT[1] + .12, .505), (.3, .3, .03), segments=40, rings=12); finish(o, "UpperTorso", "RoundelRed", (214, 40, 40))
o = ellipsoid((0, UT[1] + .12, .52), (.3, .3, .03), segments=40, rings=12); cut_below(o, (0, UT[1] + .12, 0), (0, -1, 0)); finish(o, "UpperTorso", "RoundelWhite", (246, 244, 240))
hips(WHITE)
legs(WHITE, lower=SKIN)
for side in ("Left", "Right"):
    leg_band(side, .18, .56, WHITE)
arms(NAVY, WARM, sleeve_end=-.05, skin=SKIN)
hands(SKIN)
sandals(NAVY_D, SKIN)
headband(NAVY_D)
hair_mass(HAIR)
spikes([(180, 40, 1.1, .72, .5, .1), (150, 45, 1.0, .66, .45, .1), (-150, 45, 1.0, .66, .45, .1), (120, 30, .9, .6, .3, .05), (-120, 30, .9, .6, .3, .05),
        (180, 15, .95, .66, .25, .05), (160, 62, .9, .62, .6, .1), (-160, 62, .9, .62, .6, .1), (180, 72, .9, .6, .8, .1), (0, 80, .6, .55, .6, .05),
        (40, 66, .62, .55, .4, .05), (-40, 66, .62, .55, .4, .05), (90, 45, .6, .5, .2, .05), (-90, 45, .6, .5, .2, .05)], HAIR, HAIR_S)
bangs([(-.34, -.42, .22), (-.1, -.12, .26), (.12, .14, .26), (.34, .42, .22)], HAIR, width=.42)
side_locks(HAIR, x=.86, top=.6, length=1.05, z=-.4, width=.42)
export("Look_Sasuke", OUT)
preview("Look_Sasuke", OUT, stand_in=False)
print("done")
