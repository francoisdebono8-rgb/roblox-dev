"""Locomotion authoring: gait cycles, arcs and one-shots, baked to Blender
actions on the rig (nd_rig), in the engine's pose vocabulary (nd_anim).

A gait is described the way an animator blocks a cycle: stride, how long a
foot holds the ground, how deep the body sits and bounces, how far the knee
drives and the heel flicks, the pelvis/shoulder counter-twist, the arm
swing. gait_spec(G, theta, phi) gives the body at cycle phase phi (0 = the
right foot strikes, .5 = the left) when travelling at angle theta (0
forward, 90 right, 180 back, -90 left, relative to where the body faces).
Planted feet slide back at exactly the stride speed, so in game the runtime
advances phi by distance / stride and the feet stay locked on the floor.

Every cycle is baked densely (one key every `step` frames, linear), so what
the game plays is exactly what Blender shows.
"""
import math
from nd_anim import new_action, key, merge

TAU = 2 * math.pi


def smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def rot(x, z, deg):
    """Yaw a (x, z) HumanoidRootPart-plane vector (yaw + turns right)."""
    a = math.radians(deg)
    return x * math.cos(a) - z * math.sin(a), x * math.sin(a) + z * math.cos(a)


def add(spec, delta, w=1.0):
    """spec + w * delta (numeric fields, nested one level)."""
    out = {k: dict(v) if isinstance(v, dict) else v for k, v in spec.items()}
    for part, fields in delta.items():
        cur = out.setdefault(part, {})
        for f, v in fields.items():
            cur[f] = cur.get(f, 0) + v * w
    return out


def lerp_spec(a, b, t):
    """Numeric blend of two specs (a part missing on one side counts as 0)."""
    out = {}
    for part in set(a) | set(b):
        pa, pb = a.get(part, {}), b.get(part, {})
        out[part] = {f: pa.get(f, 0) + (pb.get(f, 0) - pa.get(f, 0)) * t for f in set(pa) | set(pb)}
    return out


def catmull(p0, p1, p2, p3, u):
    """Catmull-Rom between p1 and p2 on specs."""
    out = {}
    parts = set(p0) | set(p1) | set(p2) | set(p3)
    for part in parts:
        q = [p.get(part, {}) for p in (p0, p1, p2, p3)]
        fields = set().union(*[set(x) for x in q])
        o = {}
        for f in fields:
            v0, v1, v2, v3 = (x.get(f, 0) for x in q)
            o[f] = .5 * ((2 * v1) + (-v0 + v2) * u + (2 * v0 - 5 * v1 + 4 * v2 - v3) * u * u + (-v0 + 3 * v1 - 3 * v2 + v3) * u * u * u)
        out[part] = o
    return out


def bump(phi, at, width):
    """A smooth bump centred on `at` (cyclic phase)."""
    d = (phi - at + .5) % 1 - .5
    return math.exp(-(d / width) ** 2)


# ------------------------------------------------------------------ gaits
def gait_spec(G, theta, phi):
    tx, tz = math.sin(math.radians(theta)), -math.cos(math.radians(theta))
    side = math.sin(math.radians(theta))
    back = max(0.0, -math.cos(math.radians(theta)))
    fwd = max(0.0, math.cos(math.radians(theta)))
    # The hips turn into a sideways run (chest stays on the opponent).
    face = G.get("face", 0) * side * (1 - back)
    duty = G["duty"]
    half = G["S"] * duty / 2
    feet, dips = {}, []
    for key_, s, off in (("rf", 1, 0.0), ("lf", -1, .5)):
        q = (phi + off) % 1
        bx, bz = rot(s * G.get("width", .55), G.get("stagger", 0) * s, face)
        if q < duty:
            u = q / duty
            along = half * (1 - 2 * u)
            y = 0.0
            toe = G.get("strike", 8) * (1 - smooth(u * 4)) - G.get("push", 26) * smooth((u - .55) / .45)
            dips.append(math.sin(math.pi * u))
        else:
            u = (q - duty) / (1 - duty)
            hb = G.get("heel", .35)
            e = .12 * smooth(u / hb) if u < hb else .12 + .88 * smooth((u - hb) / (1 - hb))
            along = -half + 2 * half * e
            y = G["lift"] * math.sin(math.pi * u ** .8)
            toe = -16 - G.get("point", 20) * math.sin(math.pi * min(1, u / .75))
            if u > .8:
                toe += (G.get("strike", 8) + 16) * smooth((u - .8) / .2)
        fx, fz = bx + tx * along, bz + tz * along
        feet[key_] = {"x": fx - .5 * s, "y": y, "z": fz, "toe": toe, "yaw": face * .9 + G.get("footYaw", 0) * s}
    c = math.cos(TAU * phi)
    dip = max(dips) if dips else 0.0
    if G.get("walk"):
        rise = dip - .7
    else:
        rise = .45 - dip
    spec = {
        "root": {"y": G["y0"] + G["bob"] * rise,
                 "pitch": G["lean"] * (1 - back) - back * G.get("backLean", 6) + G.get("pitchBob", 0) * dip,
                 "yaw": face - G.get("hipYaw", 8) * c,
                 "roll": -G.get("roll", 3) * c + side * G.get("strafeRoll", 6) * (1 - back)},
        "torso": {"pitch": G.get("chest", 6) * (1 - back) - back * 4,
                  "yaw": -face * G.get("counter", .85) + (G.get("hipYaw", 8) + G.get("twist", 8)) * c,
                  "roll": -side * 3},
        "head": {}, "rf": feet["rf"], "lf": feet["lf"],
    }
    chest_world = spec["root"]["yaw"] + spec["torso"]["yaw"]
    spec["head"] = {"pitch": -(spec["root"]["pitch"] + spec["torso"]["pitch"]) * G.get("headComp", .7) + G.get("headPitch", 0),
                    "yaw": -chest_world * .7}
    A, E = G.get("arm", 40), G.get("elbow", 80)
    arms = {
        "ra": {"raise": G.get("armBase", 10) - A * c, "out": G.get("armOut", 10), "twist": G.get("armTwist", 10),
               "elbow": E - G.get("elbowSwing", 14) * c, "wrist": G.get("wrist", 0)},
        "la": {"raise": G.get("armBase", 10) + A * c, "out": G.get("armOut", 10), "twist": G.get("armTwist", 10),
               "elbow": E + G.get("elbowSwing", 14) * c, "wrist": G.get("wrist", 0)},
    }
    # Sideways and backward: the hands come up into the guard.
    guard = G.get("guard")
    gw = max(abs(side) * (1 - back), back) * G.get("guardOn", .8)
    if guard and gw > 0:
        for k in ("ra", "la"):
            swing = {"raise": arms[k]["raise"] - G.get("armBase", 10), "elbow": arms[k]["elbow"] - E}
            g = dict(guard[k])
            g["raise"] = g.get("raise", 0) + swing["raise"] * .3
            g["elbow"] = g.get("elbow", 0) + swing["elbow"] * .3
            arms[k] = lerp_spec({"a": arms[k]}, {"a": g}, gw)["a"]
    spec.update(arms)
    for at, width, delta in G.get("accents", []):
        spec = add(spec, delta, bump(phi, at, width))
        spec = add(spec, mirror_delta(delta), bump(phi, (at + .5) % 1, width))
    return spec


def mirror_delta(d):
    """The same accent on the other side of the body."""
    swap = {"ra": "la", "la": "ra", "rf": "lf", "lf": "rf", "rl": "ll", "ll": "rl"}
    out = {}
    for part, fields in d.items():
        f = dict(fields)
        for k in ("yaw", "roll", "x"):
            if k in f and part in ("root", "torso", "head", "rf", "lf"):
                f[k] = -f[k]
        out[swap.get(part, part)] = f
    return out


# ------------------------------------------------------------------ baking
def bake(arm, name, fn, frames, step=2, loop=True, markers=None, meta=None):
    """fn(u) -> spec for u in [0, 1]; keyed every `step` frames (linear)."""
    act = new_action(arm, name)
    from nd_anim import _last_quat
    _last_quat.clear()
    f = 0
    while True:
        key(arm, f, fn(f / frames), "LINEAR")
        if f >= frames:
            break
        f = min(frames, f + step)
    act["nd_markers"] = markers or {}
    act["nd_loop"] = bool(loop)
    act["nd_end"] = frames
    act["nd_meta"] = meta or {}
    act.frame_range = (0, frames)
    return act


def cycle(arm, name, G, theta, frames=48, meta=None):
    m = {"stride": G["S"]}
    m.update(meta or {})
    return bake(arm, name, lambda u: gait_spec(G, theta, u % 1), frames, 2, True, None, m)


def keyed(keys, u, loop=False):
    """Catmull-Rom through (u, spec) keys (u ascending in [0, 1])."""
    us = [k[0] for k in keys]
    n = len(keys)
    i = 0
    while i < n - 2 and u > us[i + 1]:
        i += 1
    a, b = us[i], us[i + 1]
    t = 0 if b == a else max(0, min(1, (u - a) / (b - a)))
    ease = keys[i + 1][2] if len(keys[i + 1]) > 2 else None
    if ease == "out":
        t = 1 - (1 - t) ** 2
    elif ease == "in":
        t = t * t
    elif ease == "snap":
        t = 1 - (1 - t) ** 3
    p1, p2 = keys[i][1], keys[i + 1][1]
    p0 = keys[i - 1][1] if i > 0 else (keys[-2][1] if loop else p1)
    p3 = keys[i + 2][1] if i + 2 < n else (keys[1][1] if loop else p2)
    return catmull(p0, p1, p2, p3, t)


def arc(arm, name, keys, frames, loop=False, markers=None, meta=None, step=2):
    return bake(arm, name, lambda u: keyed(keys, u, loop), frames, step, loop, markers, meta)


def reach_report(G, theta):
    """Worst leg stretch over the cycle (1.0 = straight leg)."""
    from nd_anim import ori
    from mathutils import Vector
    worst = 0
    for i in range(48):
        sp = gait_spec(G, theta, i / 48)
        r = sp["root"]
        rr = ori(r)
        for k, s in (("rf", 1), ("lf", -1)):
            f = sp[k]
            ankle = Vector((.5 * s + f["x"], -2.6 + f["y"], f["z"]))
            hip = Vector((r.get("x", 0), r["y"], r.get("z", 0))) + rr @ Vector((.5 * s, -.55, 0))
            worst = max(worst, (ankle - hip).length / 2.05)
    return round(worst, 3)
