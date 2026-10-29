# Ninja Duel — arena modelling helpers (Roblox space; see arena_assets.py).
import math, random
import nd_look
from nd_look import *
from mathutils import Vector
V = nd_look.R

def frame(a):
    """Tangent, up and inward normal at azimuth a (0 = +Z)."""
    return Vector((math.cos(a), 0, -math.sin(a))), Vector((0, 1, 0)), Vector((-math.sin(a), 0, -math.cos(a)))

def obox(center, size, t, u, n, name="obox"):
    """Box along the axes t (x), u (y), n (z) at center (Roblox space)."""
    c = Vector(center)
    sx, sy, sz = (s / 2 for s in size)
    verts = [tuple(c + t * (x * sx) + u * (y * sy) + n * (z * sz)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    ob = nd_look._object(name, verts, faces)
    nd_look._outward(ob)
    return ob

def arc_box(radius, a, y, size, name="arcbox"):
    """A box tangent to the circle of `radius` at azimuth a; size =
    (along the arc, height, radial depth), y = its centre height."""
    t, u, n = frame(a)
    c = Vector((math.sin(a) * radius, y, math.cos(a) * radius))
    return obox(c, size, t, u, n, name)

def arc_sweep(profile, a0, a1, steps, name="sweep"):
    """Sweep a closed (radius, y) polygon round the Y axis from a0 to a1."""
    m = len(profile)
    verts, faces = [], []
    for k in range(steps + 1):
        a = a0 + (a1 - a0) * k / steps
        for r, y in profile:
            verts.append((math.sin(a) * r, y, math.cos(a) * r))
    for k in range(steps):
        for i in range(m):
            j = (i + 1) % m
            faces.append((k * m + i, k * m + j, (k + 1) * m + j, (k + 1) * m + i))
    faces.append(tuple(range(m)))
    faces.append(tuple(steps * m + i for i in reversed(range(m))))
    ob = nd_look._object(name, verts, faces)
    nd_look._outward(ob)
    return ob

def rect(r0, r1, y0, y1):
    return [(r0, y0), (r1, y0), (r1, y1), (r0, y1)]

def put(objs, asset, piece, rgb, smooth=30, material="SmoothPlastic"):
    if not isinstance(objs, list):
        objs = [objs]
    objs = [o for o in objs if o]
    if not objs:
        return
    o = join(objs, asset + "__" + piece) if len(objs) > 1 else objs[0]
    finish(o, asset, piece, rgb, smooth=smooth, material=material)

def cylinder(center, radius, height, sides=12, name="cyl"):
    cx, cy, cz = center
    return loft([(0, radius, radius, 2), (height, radius, radius, 2)], sides=sides, center=(cx, cy, cz), name=name)

def lumpy(center, radii, seed, amount=.18, segments=10, rings=7, name="lump"):
    """A faceted, irregular ball (leaves, bushes)."""
    o = ellipsoid(center, radii, segments=segments, rings=rings, name=name)
    r = random.Random(seed)
    c = V(*center)
    for v in o.data.vertices:
        d = v.co - c
        v.co = c + d * (1 + r.uniform(-amount, amount))
    o.data.update()
    return o


# ---------------------------------------------------------------- roofs
def hip_roof(ax, az, h, y0, lift=1.2, thick=.5, name="roof"):
    """Japanese hip roof: concave slopes, corners turned up. ax, az are the
    eave half-sizes (ax >= az); the ridge runs along X."""
    K, S = 12, 64
    verts, faces = [], []
    for k in range(K + 1):
        s = k / K
        d = az * .94 * s
        hx, hz = max(.05, ax - d), max(.05, az - d)
        yy = y0 + h * s ** 1.7
        for i, (x, z) in enumerate(superellipse(hx, hz, 10, S)):
            xn, zn = abs(x) / ax, abs(z) / az
            corner = (min(xn, 1) * min(zn / max(hz / az, 1e-3), 1)) ** 3
            up = lift * (1 - s) ** 2.5 * corner * 1.0 + lift * .25 * (1 - s) ** 3
            verts.append((x, yy + up, z))
    for k in range(K):
        for i in range(S):
            j = (i + 1) % S
            faces.append((k * S + i, k * S + j, (k + 1) * S + j, (k + 1) * S + i))
    faces.append(tuple(K * S + i for i in range(S)))
    ob = nd_look._object(name, verts, faces)
    nd_look._outward(ob)
    solidify(ob, thick)
    return ob

def ridge(ax, az, h, y0, w=.7, name="ridge"):
    top = y0 + h + .2
    rl = ax - az * .94
    parts = [box((0, top, 0), (2 * rl + 1.2, w, w), bevel=.1, segments=1)]
    for s in (-1, 1):
        parts.append(box((s * (rl + .6), top + .7, 0), (.6, 1.6, .5), bevel=.12, segments=1))
    return join(parts, name)

