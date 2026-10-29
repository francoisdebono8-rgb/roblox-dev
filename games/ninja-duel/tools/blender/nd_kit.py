# Ninja Duel — costume kit on top of nd_look: the parts every fighter shares
# (head skin, mitts, sandals, sleeves, trousers, headband, hair cap, spikes,
# fringe, long locks), so each look_<name>.py only says what is his.
# Roblox rest-pose space throughout (see nd_look).
import math
from mathutils import Vector
from nd_look import (REST, loft, band, box, ellipsoid, spike, lock_path, head_loft, head_point, head_section,
                     head_panel, cut_below, solidify_in, finish, join)

SQ = 3.4
H = REST["Head"]
HY = H[1]
BAND = (.42, .66)

def folds(amount=.006, waves=3, rate=6):
    return lambda a, y: amount * math.sin(waves * a + y * rate) + amount * .5 * math.sin(7 * a - y * 11)

def head(skin):
    finish(head_loft(H, -.95, .95, steps=24, sides=56), "Head", "Skin", skin, smooth=50)

def torso(top, bottom=None, split=.34, top_cut=None):
    """Upper torso shell; `bottom` below `split` when the chest is two colours."""
    ut = REST["UpperTorso"]
    rows = [(-.66, .84, .47, SQ), (-.3, .85, .48, SQ), (.05, .87, .49, SQ), (split, .88, .49, SQ), (.52, .88, .49, SQ), (.68, .8, .46, 3), (.79, .56, .4, 2.6)]
    if bottom:
        low = [r for r in rows if r[0] <= split]
        high = [r for r in rows if r[0] >= split]
        finish(loft(low, sides=40, center=ut, cap_top=False, wobble=folds()), "UpperTorso", "Chest", bottom)
        finish(loft(high, sides=40, center=ut, cap_bottom=False), "UpperTorso", "Yoke", top)
    else:
        finish(loft(rows, sides=40, center=ut, wobble=folds()), "UpperTorso", "Chest", top)

def hips(color, length=.62, flare=0.0, name="Hips"):
    lt = REST["LowerTorso"]
    rows = [(-length, .86 + flare, .5 + flare * .6, SQ), (-.2, .85, .49, SQ), (.3, .83, .47, SQ), (.62, .81, .45, SQ)]
    finish(loft(rows, sides=40, center=lt, wobble=folds(.006, 4, 9)), "LowerTorso", name, color)

def collar(color, y=.72, height=.3, hx=.74, hz=.64, thick=.14, n=2.6, flare=0.0):
    ut = REST["UpperTorso"]
    if flare:
        rows = [(y - height / 2, hx, hz, n), (y + height / 2, hx + flare, hz + flare, n)]
        o = loft(rows, sides=40, center=ut, cap_top=False, cap_bottom=False)
        solidify_in(o, thick)
    else:
        o = band(y, height, hx, hz, thick=thick, center=ut, n=n)
    finish(o, "UpperTorso", "Collar", color, smooth=60)

def arms(upper, lower, shoulder=None, cuff=None, sleeve_end=None, skin=None, bulk=0.0, cuff_color=None):
    """Upper sleeve (`shoulder` colours its cap; `sleeve_end` stops it at that
    height and shows `skin` below), forearm in `lower`, optional rolled cuff."""
    for side, s in (("Left", -1), ("Right", 1)):
        ua = REST[side + "UpperArm"]
        b = bulk
        start = sleeve_end if sleeve_end is not None else -.66
        if sleeve_end is not None:
            finish(loft([(-.66, .355, .335, 3), (sleeve_end + .06, .36, .34, 3)], sides=28, center=ua), side + "UpperArm", "Arm", skin)
        top_split = .2 if shoulder else .45
        rows = [(start, .39 + b, .37 + b, 3), (max(start + .05, -.2), .385 + b, .365 + b, 3), (top_split, .39 + b, .37 + b, 3)]
        cap_rows = [(top_split, .39 + b, .37 + b, 3), (.45, .4 + b, .38 + b, 3), (.62, .34 + b, .32 + b, 2.6), (.7, .2, .2, 2.2)]
        if shoulder:
            finish(loft(rows, sides=28, center=ua, cap_top=False, wobble=folds(.005, 2, 8)), side + "UpperArm", "Sleeve", upper)
            finish(loft(cap_rows, sides=28, center=ua, cap_bottom=False), side + "UpperArm", "Shoulder", shoulder)
        else:
            finish(loft(rows + cap_rows[1:], sides=28, center=ua, wobble=folds(.005, 2, 8)), side + "UpperArm", "Sleeve", upper)
        la = REST[side + "LowerArm"]
        finish(loft([(-.5, .34, .33, 3), (-.1, .345, .335, 3), (.3, .34, .33, 3), (.6, .33, .32, 3)], sides=28, center=la, wobble=folds(.004, 3, 10)), side + "LowerArm", "Forearm", lower)
        if cuff:
            finish(band(-.4, .2, .4, .39, thick=.08, center=la, n=3), side + "LowerArm", "Cuff", cuff, smooth=60)

def arm_guard(color, plate=None, top=.35, bottom=-.45, grow=.05):
    for side, s in (("Left", -1), ("Right", 1)):
        la = REST[side + "LowerArm"]
        finish(band((top + bottom) / 2, top - bottom, .345 + grow, .335 + grow, thick=.06, center=la, n=3), side + "LowerArm", "Guard", color, smooth=60)
        if plate:
            finish(box((la[0] + s * (.4 + grow), la[1] + (top + bottom) / 2, 0), (.08, (top - bottom) * .9, .46), bevel=.03), side + "LowerArm", "GuardPlate", plate, reflect=.08)

def hands(skin, wrap=None):
    """A closed fist: the back of the hand, four curled fingers with their
    knuckles, the thumb across the front (user 29/10 15:19: "les mains sont
    des moignons")."""
    for side, s in (("Left", -1), ("Right", 1)):
        hd = REST[side + "Hand"]
        c = wrap or skin
        x, y, z = hd
        # back of the hand (outside), palm side toward the body
        parts = [box((x + s * .04, y + .08, z), (.42, .42, .46), bevel=.1, segments=3)]
        for i in range(4):
            fz = z - .18 + i * .12
            parts.append(box((x, y - .17, fz), (.46, .2, .105), bevel=.05, segments=2))        # knuckle row
            parts.append(box((x - s * .17, y - .22, fz), (.18, .22, .1), bevel=.05, segments=2))   # curled tip
        parts.append(box((x - s * .18, y - .05, z - .26), (.16, .26, .14), bevel=.06, segments=2))  # thumb
        parts.append(box((x - s * .05, y - .17, z - .29), (.26, .12, .12), bevel=.05, segments=2))
        finish(join(parts, "fist"), side + "Hand", "Fist", c, smooth=40)

def legs(upper, lower=None, cuff=None, baggy=0.0):
    for side, s in (("Left", -1), ("Right", 1)):
        ul = REST[side + "UpperLeg"]
        b = baggy
        finish(loft([(-.66, .41 + b, .4 + b, 3), (0, .43 + b, .42 + b, 3), (.5, .45, .43, 3), (.68, .44, .42, 3)], sides=28, center=ul, wobble=folds(.006, 3, 7)), side + "UpperLeg", "Thigh", upper)
        ll = REST[side + "LowerLeg"]
        finish(loft([(-.56, .43 + b, .42 + b, 3), (-.2, .42 + b, .41 + b, 3), (.3, .4, .39, 3), (.62, .39, .38, 3)], sides=28, center=ll, wobble=folds(.006, 3, 9)), side + "LowerLeg", "Shin", lower or upper)
        if cuff:
            finish(band(-.42, .26, .47 + b, .46 + b, thick=.1, center=ll, n=3), side + "LowerLeg", "Cuff", cuff, smooth=60)

def leg_band(side, y, height, color, body="LowerLeg", grow=.05):
    c = REST[side + body]
    r = .43 if body == "UpperLeg" else .41
    finish(band(y, height, r + grow, r - .01 + grow, thick=.06, center=c, n=3), side + body, "Wrap", color, smooth=60)

def sandals(color, skin, sole=(60, 48, 44)):
    for side, s in (("Left", -1), ("Right", 1)):
        f = REST[side + "Foot"]
        finish(box((f[0], f[1] - .2, f[2] - .02), (.78, .1, 1.18), bevel=.05, segments=3), side + "Foot", "Sole", sole)
        finish(loft([(-.15, .37, .3, 3), (.1, .36, .29, 3), (.22, .3, .24, 2.6)], sides=24, center=(f[0], f[1], f[2] + .28)), side + "Foot", "Heel", color)
        for z in (-.06, -.3):
            finish(box((f[0], f[1] - .04, f[2] + z), (.8, .16, .14), bevel=.04), side + "Foot", "Strap", color)
        finish(box((f[0], f[1] - .1, f[2] - .44), (.62, .2, .34), bevel=.08, segments=3), side + "Foot", "Toes", skin, smooth=50)
        ll = REST[side + "LowerLeg"]
        finish(band(-.42, .16, .44, .43, thick=.06, center=ll, n=3), side + "LowerLeg", "AnkleStrap", color, smooth=60)

def holster(color, side="Right"):
    ul = REST[side + "UpperLeg"]
    s = 1 if side == "Right" else -1
    finish(box((ul[0] + s * .5, ul[1] - .05, 0), (.18, .46, .42), bevel=.05), side + "UpperLeg", "Holster", color)

def headband(cloth, metal=(190, 198, 210), y0=BAND[0], y1=BAND[1], slashed=False, tails=True):
    o = head_loft(H, y0, y1, grow=.1, steps=4, sides=64, cap_top=False, cap_bottom=False)
    solidify_in(o, .07)
    finish(o, "Head", "Headband", cloth, smooth=60)
    finish(head_panel(H, -.34, .34, y0 + .02, y1 - .02, .1, .145, nx=16, ny=3), "Head", "HeadbandPlate", metal, smooth=30, reflect=.12)
    mid = (y0 + y1) / 2
    mark = []
    for k in range(14):
        a = 2 * math.pi * k / 14
        mark.append(box(tuple(head_point(H, math.cos(a) * .07, mid + math.sin(a) * .07, .145)), (.03, .03, .03), bevel=0))
    mark.append(box(tuple(head_point(H, .1, mid + .06, .145)), (.09, .025, .03), bevel=0))
    if slashed:
        for k in range(9):
            x = -.3 + .6 * k / 8
            mark.append(box(tuple(head_point(H, x, mid - .02 + x * .1, .15)), (.08, .02, .03), bevel=0))
    finish(join(mark, "mark"), "Head", "PlateMark", (110, 118, 132), smooth=20)
    if tails:
        a, b, n = head_section(y0)
        for s in (-1, 1):
            finish(box((s * .16, HY + y0 - .3, b + .12), (.2, .64, .05), bevel=.02), "Head", "BandTail", cloth)

def hair_cap(color, front=BAND[1], back=-.44, grow=.05):
    cap = head_loft(H, -.6, .95, grow=grow, steps=20, sides=56)
    # A plane from the front hairline (z -.9) down to the nape (z +.9).
    cut_below(cap, (0, HY + front, -.9), (0, 1.8, front - back))
    solidify_in(cap, .03)
    finish(cap, "Head", "HairCap", color, smooth=55)

def root(az, el, inset=.2):
    a, e = math.radians(az), math.radians(el)
    y = .1 + .9 * math.sin(e)
    hx, hz, n = head_section(y)
    d = Vector((math.sin(a) * math.cos(e), math.sin(e), -math.cos(a) * math.cos(e)))
    p = Vector((H[0] + math.sin(a) * hx * 1.05, HY + y, H[2] - math.cos(a) * hz * 1.05))
    return p - d * inset, d

def spikes(spec, color, shade=None, flat=.42, sides=8, name="Hair"):
    """spec: (azimuth, elevation, length, width, up-bias, curl[, side-bias])."""
    main, dark = [], []
    for i, row in enumerate(spec):
        az, el, length, width, up, curl = row[:6]
        sideways = row[6] if len(row) > 6 else 0
        p, d = root(az, el)
        d = (d + Vector((sideways, up, 0))).normalized()
        o = spike(p, d, length, width, width * flat, bend=(0, curl, 0), sides=sides, twist=.25, rings=6)
        (dark if shade and i % 4 == 2 else main).append(o)
    finish(join(main, "h"), "Head", name, color, smooth=25)
    if dark:
        finish(join(dark, "hs"), "Head", name + "Shade", shade, smooth=25)

def fringe(locks, color, band_top=BAND[1], name="Fringe", width=.44, thick=.13):
    """locks: (x at the root, x at the tip, tip height): flat locks that lie
    over the band (offset past it) down to the tip."""
    out = []
    for x0, x1, y1 in locks:
        pts = []
        for k in range(9):
            t = k / 8
            y = .86 - (.86 - y1) * t
            x = x0 + (x1 - x0) * t
            off = .07 + (.1 * min(1, max(0, (band_top + .14 - y) / .14)) if band_top is not None else 0)
            pts.append(tuple(head_point(H, x, y, off)))
        out.append(lock_path(pts, lambda p: (p[0] * .3, .25, -1), width, thick, sides=7))
    finish(join(out, "f"), "Head", name, color, smooth=30)

def side_locks(color, x=.92, top=.5, length=.7, z=-.25, width=.4, thick=.14, name="SideLocks", lean=0.0):
    out = []
    for s in (-1, 1):
        pts = [tuple(Vector((s * (x + lean * k / 7), HY + top - length * k / 7, z - .1 * k / 7))) for k in range(8)]
        out.append(lock_path(pts, lambda p, s=s: (s, 0, -.3), width, thick, sides=7))
    finish(join(out, "s"), "Head", name, color, smooth=30)

def back_mass(color, bottom=-.9, width=.95, depth=.5, z=.55, top=.4, body="Head", name="BackHair"):
    """A straight curtain of hair down the back of the head."""
    rows = []
    for k in range(7):
        t = k / 6
        y = top - (top - bottom) * t
        rows.append((y, width * (1 - .25 * t * t), depth * (1 - .5 * t), 2.6, z))
    rows.reverse()
    finish(loft(rows, sides=32, center=(0, HY, 0)), body, name, color, smooth=40)

def rotated(ob, pivot, deg):
    """Turn a piece about the Roblox Z axis (front-back) through `pivot`
    (Roblox rotation about +Z = Blender rotation about +Y, same angle)."""
    from mathutils import Matrix
    from nd_look import R
    P = R(*pivot)
    ob.data.transform(Matrix.Translation(P) @ Matrix.Rotation(math.radians(deg), 4, "Y") @ Matrix.Translation(-P))
    ob.data.update()
    return ob

def sword_on_back(length, pivot, angle, sheath=(22, 22, 28), hilt=(232, 228, 214), wrap=(28, 28, 36), metal=(160, 164, 172), hilt_len=.62):
    """A sheathed blade across the back, hilt over the right shoulder; the
    hilt pieces are Sheathed* (hidden by the client while it is drawn)."""
    px, py, pz = pivot
    parts = {}
    o = box((px, py - .2, pz), (.22, length, .18), bevel=.07, segments=2); rotated(o, pivot, angle)
    finish(o, "UpperTorso", "Sheath", sheath)
    o = box((px, py - .2 - length / 2 + .06, pz), (.25, .14, .21), bevel=.04); rotated(o, pivot, angle)
    finish(o, "UpperTorso", "SheathTip", metal, reflect=.1)
    top = py - .2 + length / 2
    o = box((px, top + .03, pz), (.4, .06, .34), bevel=.02); rotated(o, pivot, angle)
    finish(o, "UpperTorso", "SheathedGuard", (44, 44, 52))
    o = box((px, top + .06 + hilt_len / 2, pz), (.15, hilt_len, .15), bevel=.04); rotated(o, pivot, angle)
    finish(o, "UpperTorso", "SheathedHilt", hilt)
    wraps = []
    for k in range(4):
        y = top + .14 + k * (hilt_len - .1) / 4
        w = box((px, y, pz), (.17, .06, .17), bevel=0); rotated(w, (px, y, pz), 30); rotated(w, pivot, angle)
        wraps.append(w)
    finish(join(wraps, "w"), "UpperTorso", "SheathedWrap", wrap)


def hair_mass(color, puff=.03, band=BAND, back=-.5, front=None, nape_puff=.1):
    """The hair volume: hugging the head inside the band (the band squeezes
    it), puffing out above it, a little fuller at the back down to the nape.
    The band is worn OVER the hair (user 29/10 15:19)."""
    y0, y1 = band
    def g(y):
        if y < y0:            # below the band: back/sides only (cut below)
            t = min(1, (y0 - y) / .3)
            return .05 + nape_puff * (1 - t) * .6 + .02
        if y <= y1:           # under the band: tight
            return .04
        t = (y - y1) / (.95 - y1)
        return .04 + puff * math.sin(min(1, t * 1.6) * math.pi / 2) - .05 * t * t
    cap = head_loft(H, back - .1, .95, steps=28, sides=64, grow_fn=g)
    fy = front if front is not None else y0
    cut_below(cap, (0, HY + fy, -.9), (0, 1.8, fy - back))
    solidify_in(cap, .03)
    finish(cap, "Head", "HairMass", color, smooth=45)

def bangs(locks, color, band=BAND, width=.36, thick=.1, name="Bangs"):
    """Locks that come out from under the band onto the forehead.
    locks: (x at the root, x at the tip, tip height)."""
    out = []
    y_root = band[0] + .1
    for x0, x1, y1 in locks:
        pts = []
        for k in range(8):
            t = k / 7
            y = y_root - (y_root - y1) * t
            x = x0 + (x1 - x0) * t
            off = .045 + .03 * (1 - t)
            pts.append(tuple(head_point(H, x, y, off)))
        out.append(lock_path(pts, lambda p: (p[0] * .25, .1, -1), width, thick, sides=7, taper=.9))
    finish(join(out, "b"), "Head", name, color, smooth=30)


def band_crown(color, count=14, band=BAND, length=.55, width=.5, up=.9, skip_front=0):
    """Short spikes rising from just above the band all round: the hair
    spills over the band instead of a smooth edge."""
    spec = []
    for i in range(count):
        az = -180 + 360 * (i + .5) / count
        if skip_front and abs(az) < skip_front:
            continue
        el = math.degrees(math.asin(min(.99, (band[1] + .06 - .1) / .9)))
        spec.append((az, el, length, width, up, .05))
    return spec
