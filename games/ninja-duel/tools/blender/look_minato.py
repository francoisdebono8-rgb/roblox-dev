# Minato (13; user 29/10 reference): the white tracksuit with navy piping
# down the arms, legs and sides, a navy band at the hem and cuffs, the hood
# down round the collar, the zip, spiky blond hair with long bangs, no
# headband.
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
SKIN = (252, 224, 196); HAIR, HAIR_S = (255, 218, 80), (236, 182, 44)
WHITE, WHITE_S = (236, 238, 242), (206, 210, 220); NAVY = (36, 48, 96)
head(SKIN)
torso(WHITE)
collar(WHITE_S, y=.74, height=.3, hx=.8, hz=.7, thick=.12)
finish(ellipsoid((0, UT[1] + .6, .5), (.62, .3, .22)), "UpperTorso", "Hood", WHITE_S)
finish(box((0, UT[1] - .08, -.5), (.05, 1.25, .03), bevel=.01), "UpperTorso", "Zip", (170, 176, 190))
for s in (-1, 1):
    finish(box((s * .885, UT[1] - .05, 0), (.03, 1.3, .14), bevel=.01), "UpperTorso", "Piping", NAVY)
hips(WHITE)
finish(band(.42, .22, .87, .51, thick=.06, center=LT, n=3.4), "LowerTorso", "HemBand", NAVY)
arms(WHITE, WHITE, cuff=NAVY)
legs(WHITE, cuff=NAVY)
for side, s in (("Left", -1), ("Right", 1)):
    for body, r, h in (("UpperArm", .39, 1.2), ("LowerArm", .345, 1.05), ("UpperLeg", .445, 1.3), ("LowerLeg", .425, 1.1)):
        c = REST[side + body]
        finish(box((c[0] + s * r, c[1], c[2]), (.035, h, .12), bevel=.01), side + body, "Piping", NAVY)
hands(SKIN)
sandals(NAVY, SKIN)
hair_mass(HAIR, band=(.5, .5), back=-.45)
spikes([(0, 70, .95, .74, .55, .15), (32, 60, 1.0, .74, .45, .12), (-32, 60, 1.0, .74, .45, .12),
        (64, 50, 1.0, .72, .35, .1), (-64, 50, 1.0, .72, .35, .1), (96, 42, .95, .7, .3, .1), (-96, 42, .95, .7, .3, .1),
        (128, 38, 1.05, .74, .3, .1), (-128, 38, 1.05, .74, .3, .1), (158, 38, 1.1, .76, .25, .1), (-158, 38, 1.1, .76, .25, .1),
        (180, 20, 1.0, .74, .1, .05), (150, 12, .85, .66, 0, .05), (-150, 12, .85, .66, 0, .05), (112, 18, .8, .6, 0, .05), (-112, 18, .8, .6, 0, .05),
        (180, 62, 1.0, .74, .35, .1), (0, 86, .85, .7, .9, .1), (60, 76, .9, .7, .7, .1), (-60, 76, .9, .7, .7, .1), (140, 68, .95, .72, .5, .1), (-140, 68, .95, .72, .5, .1)], HAIR, HAIR_S)
fringe([(-.52, -.7, -.02), (-.28, -.4, .12), (-.04, -.1, .2), (.2, .26, .14), (.44, .58, .06), (.62, .78, -.06)], HAIR, band_top=None, width=.46, thick=.15, taper=1.1, top=.92)
side_locks(HAIR, x=.87, top=.55, length=1.25, z=-.4, width=.46, thick=.16)
export("Look_Minato", OUT)
preview("Look_Minato", OUT, stand_in=False)
print("done")
