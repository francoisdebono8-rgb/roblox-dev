# Gaara (12), Blender pass: deep red-brown coat to mid-thigh over grey
# trousers, the pale strap across the chest, the big gourd on his back,
# short spiky brick-red hair (no headband). The forehead mark and the dark
# eye rings are drawn (Server/Looks, Shared/Face).
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
SKIN = (250, 228, 212); HAIR, HAIR_S = (190, 52, 40), (150, 36, 30)
COAT, COAT_D = (122, 46, 44), (92, 32, 34); GREY = (110, 104, 104); STRAP = (214, 200, 170)
GOURD, GOURD_D = (214, 170, 110), (170, 126, 78)
head(SKIN)
torso(COAT)
collar(COAT_D, y=.76, height=.3, hx=.76, hz=.66)
hips(COAT)
o = loft([(-1.3, .98, .62, 3), (-1.0, .93, .58, 3.2), (-.55, .88, .53, 3.4)], sides=40, center=LT, cap_top=False, wobble=folds(.01, 5, 6))
solidify_in(o, .05); finish(o, "LowerTorso", "CoatSkirt", COAT)
o = band(-1.26, .1, 1.0, .64, thick=.06, center=LT, n=3); finish(o, "LowerTorso", "CoatHem", COAT_D)
finish(band(.3, .24, .87, .51, thick=.06, center=LT, n=3.4), "LowerTorso", "Sash", COAT_D)
legs(GREY)
for side in ("Left", "Right"):
    leg_band(side, -.3, .3, (226, 220, 206))
arms(COAT, COAT, cuff=COAT_D)
hands(SKIN)
sandals((52, 44, 44), SKIN)
for z, ang in ((-.5, -36), (.5, 36)):
    o = box((0, UT[1], z), (.22, 2.1, .06), bevel=.02); rotated(o, (0, UT[1], z), ang); finish(o, "UpperTorso", "Strap", STRAP)
o = box((.25, UT[1] + .3, -.54), (.28, .28, .06), bevel=.03); finish(o, "UpperTorso", "Clasp", (180, 186, 196), reflect=.1)
prof = [(-1.25, .2), (-1.1, .6), (-.85, .84), (-.45, .92), (-.05, .84), (.18, .55), (.3, .42), (.42, .5), (.66, .6), (.9, .55), (1.1, .36), (1.24, .2), (1.48, .17)]
o = loft([(y, r, r * .82, 2) for y, r in prof], sides=40, center=(.05, UT[1] - .1, 1.2)); finish(o, "UpperTorso", "Gourd", GOURD, smooth=50)
finish(band(.3, .16, .46, .39, thick=.04, center=(.05, UT[1] - .1, 1.2), n=2), "UpperTorso", "GourdRope", GOURD_D)
finish(ellipsoid((.05, UT[1] + 1.46, 1.2), (.16, .12, .14)), "UpperTorso", "GourdCork", (120, 86, 56))
hair_mass(HAIR, band=(.5, .5), back=-.4)
spikes([(0, 70, .62, .52, .5, .1), (35, 60, .6, .5, .4, .1), (-35, 60, .6, .5, .4, .1), (70, 45, .55, .48, .2, .05), (-70, 45, .55, .48, .2, .05),
        (110, 35, .55, .48, .1, .05), (-110, 35, .55, .48, .1, .05), (145, 35, .6, .5, .15, .05), (-145, 35, .6, .5, .15, .05), (180, 30, .6, .52, .1, .05),
        (180, 62, .55, .5, .5, .05), (130, 66, .55, .48, .5, .05), (-130, 66, .55, .48, .5, .05), (0, 86, .5, .46, .8, .05)], HAIR, HAIR_S, flat=.5)
fringe([(-.55, -.66, .38), (-.3, -.36, .44), (-.05, -.04, .42), (.2, .24, .44), (.45, .56, .38)], HAIR, band_top=None, width=.38)
export("Look_Gaara", OUT)
preview("Look_Gaara", OUT, stand_in=False)
print("done")
