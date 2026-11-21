#!/usr/bin/env python3
"""Clips authored the SyphoDev way, without Blender (21/11, étape 2 ANIMATEUR 1).

A clip is a few KEY POSES (the five of a blow: rest, anticipation, contact, follow-through,
return), each written as the body would be directed: where the feet stand, where the fist or
the foot goes, how the hips, the chest and the head turn. This module turns them into the
game's rows (Motor6D.Transform per joint per sample, tools/blender/clips_to_luau.py) on the
player's own skeleton (tools/syphodev/rig.json = World.RIG):

  * the semantic angles are r6_joint's (roblox-animation skill): pitch/lean/turn for the up
    joints (Root, Waist, Neck), swing/spread/twist for the limbs, Roblox axes (-Z forward);
  * a limb given a TARGET is solved (2-bone IK, least squares, pulled toward its hints): a
    planted foot stays where it stands while the hips turn and drop, a fist goes where the
    blow lands - that is what kills the sliding feet and the fists inside the head;
  * every key is grounded (the lowest planted foot on the floor) unless it is airborne;
  * the keys are slerped at 30 fps with the skill's eases, so the timing is in the keys;
  * the timing of a blow is NOT ours (DEC-043): the length and the markers (contact,
    recover) are copied from the clip it replaces, and the keys are placed around them.

The checks are the audit's (tools/syphodev/audit_clips.py + tools/blender/clip_grades.py):
every clip is graded before it is written, and `sheet()` draws the key frames from the side
and the front so the poses are looked at, not only counted.

    python3 tools/blender/syph_author.py SPEC_MODULE OLD_CLIPS.json OUT_DIR
"""
import json
import math
import os
import sys

import numpy as np
from scipy.optimize import least_squares

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "syphodev"))
sys.path.insert(0, HERE)
import audit_clips as A  # noqa: E402

RIG_PATH = os.path.join(ROOT, "tools", "syphodev", "rig.json")
RIG = json.load(open(RIG_PATH))
UP = set(RIG["up_joints"])          # Root, Waist, Neck
KEYS = RIG["clip_keys"]             # motor -> clip key (shoulders are "Right"/"Left")
JOINTS = {j["name"]: j for j in RIG["joints"]}
FLOOR = -RIG["hrp"][1]              # -3.01: the soles of a standing body
FOOT_HALF = RIG["sizes"]["RightFoot"][1] / 2
ORDER = []
_have, _pending = {"HumanoidRootPart"}, list(RIG["joints"])
while _pending:
    for _j in list(_pending):
        if _j["part0"] in _have:
            ORDER.append(_j); _have.add(_j["part1"]); _pending.remove(_j)
            break
FPS = 60
SIDE = {"R": "Right", "L": "Left"}


# ------------------------------------------------------------------ maths
def rx(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def ry(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rz(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def sem_R(joint, sem):
    """r6_joint.world_rot with this rig's up joints (C0 rotations are identity here)."""
    d = math.radians
    if joint in UP:
        a, b, c = d(-sem.get("pitch", 0.0)), d(sem.get("lean", 0.0)), d(sem.get("turn", 0.0))
    else:
        side = 1.0 if JOINTS[joint]["c0"]["pos"][0] >= 0 else -1.0
        a, b, c = d(sem.get("swing", 0.0)), d(sem.get("spread", 0.0)) * side, d(sem.get("twist", 0.0))
    return ry(c) @ rz(b) @ rx(a)


def R_to_q(R):
    m = R
    tr = m[0, 0] + m[1, 1] + m[2, 2]
    if tr > 0:
        s = math.sqrt(tr + 1.0) * 2
        w, x, y, z = .25 * s, (m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        w, x, y, z = (m[2, 1] - m[1, 2]) / s, .25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        w, x, y, z = (m[0, 2] - m[2, 0]) / s, (m[0, 1] + m[1, 0]) / s, .25 * s, (m[1, 2] + m[2, 1]) / s
    else:
        s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
        w, x, y, z = (m[1, 0] - m[0, 1]) / s, (m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, .25 * s
    q = np.array([x, y, z, w])
    return q / np.linalg.norm(q)


def slerp(a, b, u):
    d = float(np.dot(a, b))
    if d < 0:
        b, d = -b, -d
    if d > .9995:
        q = a + (b - a) * u
        return q / np.linalg.norm(q)
    th = math.acos(min(1.0, d))
    return (math.sin((1 - u) * th) * a + math.sin(u * th) * b) / math.sin(th)


def ease(name, u):
    if name == "linear":
        return u
    if name == "in":
        return u ** 3
    if name == "out":
        return 1 - (1 - u) ** 3
    if name == "in2":       # a softer acceleration (quadratic)
        return u ** 2
    if name == "out2":
        return 1 - (1 - u) ** 2
    if name == "hold":
        return 0.0
    return 4 * u ** 3 if u < .5 else 1 - (-2 * u + 2) ** 3 / 2   # smooth


# ------------------------------------------------------------------ the body
def fk(T):
    """T: joint -> (pos(3), R(3x3)) Motor6D.Transform. Returns part -> (R, p) in root space."""
    W = {"HumanoidRootPart": (np.eye(3), np.zeros(3))}
    for j in ORDER:
        Tp, TR = T.get(j["name"], (np.zeros(3), np.eye(3)))
        R0, p0 = W[j["part0"]]
        c0, c1 = np.array(j["c0"]["pos"], float), np.array(j["c1"]["pos"], float)
        R1 = R0 @ TR
        W[j["part1"]] = (R1, p0 + R0 @ (c0 + Tp) - R1 @ c1)
    return W


LIMB = {  # (upper joint, middle joint, end joint, end part)
    "RA": ("RightShoulder", "RightElbow", "RightWrist", "RightHand"),
    "LA": ("LeftShoulder", "LeftElbow", "LeftWrist", "LeftHand"),
    "RL": ("RightHip", "RightKnee", "RightAnkle", "RightFoot"),
    "LL": ("LeftHip", "LeftKnee", "LeftAnkle", "LeftFoot"),
}


def _limb_T(name, x):
    up, mid, end, _ = LIMB[name]
    leg = name.endswith("L")
    T = {up: (np.zeros(3), sem_R(up, {"swing": x[0], "spread": x[1], "twist": x[2]})),
         mid: (np.zeros(3), sem_R(mid, {"swing": -x[3] if leg else x[3]}))}
    if leg:
        T[end] = (np.zeros(3), sem_R(end, {"swing": x[4], "spread": x[5]}))
    return T


def solve_limb(T, name, target, hint, yaw=None, toe=0.0, pole=None, orient=True):
    """IK for one limb, the rest of the pose fixed. target: the hand's or the foot's centre.
    hint: preferred [swing, spread, twist, bend(, ankle, roll)]; the solution stays near it.
    yaw (feet): the toe's heading in degrees (0 = -Z, + = turned left); toe: sole pitch.
    pole: where the elbow/knee should point (a root-space direction)."""
    leg = name.endswith("L")
    n = 6 if leg else 4
    x0 = np.array((list(hint) + [0, 0, 0, 0, 0, 0])[:n], float)
    up, mid, end, part = LIMB[name]
    target = np.array(target, float)

    def res(x):
        TT = dict(T)
        TT.update(_limb_T(name, x))
        W = fk(TT)
        R, p = W[part]
        r = list((p - target) * 4.0)
        if leg and orient:
            up_v = R[:, 1]
            pitch = math.radians(toe)        # + = toes up, - = heel up
            if yaw is not None:
                hh = math.radians(yaw)
                h = np.array([-math.sin(hh), 0.0, -math.cos(hh)])
            else:
                f_ = -R[:, 2]
                h = np.array([f_[0], 0.0, f_[2]])
                h = h / (np.linalg.norm(h) or 1.0)
            want = np.array([0.0, math.cos(pitch), 0.0]) - math.sin(pitch) * h
            r += list((up_v - want) * 4.0)
            fwd = -R[:, 2]
            if yaw is not None:
                h = math.radians(yaw)
                r += [(fwd[0] - (-math.sin(h))) * 1.2, (fwd[2] - (-math.cos(h))) * 1.2]
        if pole is not None:
            # the elbow / knee pushed toward a direction (a root-space vector)
            mid_part = up.replace("Shoulder", "LowerArm").replace("Hip", "LowerLeg")
            up_part = up.replace("Shoulder", "UpperArm").replace("Hip", "UpperLeg")
            bend_pt = (W[mid_part][1] + W[up_part][1]) / 2
            line = (W[up_part][1] + p) / 2
            r += list((bend_pt - line - np.array(pole, float) * .25) * .6)
        r += list((x - x0) * np.array([.006, .006, .004, .004, .004, .004][:n]))
        return np.array(r)

    lo = [-170, -60, -90, 0] + ([-60, -30] if leg else [])
    hi = [170, 120, 90, 150] + ([60, 30] if leg else [])
    x0 = np.clip(x0, np.array(lo) + 1e-3, np.array(hi) - 1e-3)
    sol = least_squares(res, x0, bounds=(lo, hi), x_scale=10.0, max_nfev=400)
    T.update(_limb_T(name, sol.x))
    W = fk(T)
    err = float(np.linalg.norm(W[part][1] - target))
    return sol.x, err


def build_key(k, stance=None):
    """One key spec -> T (joint -> (pos, R)) and its solve errors.
    k = {"t", "ease", "root": {pitch, lean, turn, y, x, z}, "air": bool,
         "Waist": {...}, "Neck": {...},
         "RA"/"LA": {"hand": [x,y,z]} or {"swing","spread","twist","bend"} (+ "hint"),
         "RL"/"LL": {"foot": [x,z] (+ "lift", "yaw", "toe")} or semantic, "wrist": {...}}"""
    T = {}
    r = k.get("root", {})
    rootR = sem_R("Root", r)
    T["Root"] = (np.array([r.get("x", 0.0), r.get("y", 0.0), r.get("z", 0.0)]), rootR)  # ("sink": resolve())
    for jn in ("Waist", "Neck"):
        T[jn] = (np.zeros(3), sem_R(jn, k.get(jn, {})))
    errs = {}
    X = {}
    # free (semantic) limbs first, so the IK limbs see the whole body
    for name in ("RA", "LA", "RL", "LL"):
        spec = k.get(name, {})
        if "hand" in spec or "foot" in spec or "chest" in spec:
            continue
        leg = name.endswith("L")
        x = [spec.get("swing", 0), spec.get("spread", 0), spec.get("twist", 0), spec.get("bend", 0)]
        if leg:
            x += [spec.get("ankle", 0), spec.get("roll", 0)]
        T.update(_limb_T(name, x))
        X[name] = np.array(x, float)
    for wj in ("RightWrist", "LeftWrist"):
        side = "RA" if wj.startswith("Right") else "LA"
        T[wj] = (np.zeros(3), sem_R(wj, k.get(side, {}).get("wrist", {})))
    for name in ("RL", "LL", "RA", "LA"):
        spec = k.get(name, {})
        if "foot" in spec:
            f = spec["foot"]
            y = sole_y(spec)
            tgt = [f[0], y, f[1]] if len(f) == 2 else f
            hint = spec.get("hint", [10, 4, 0, 20, 0, 0])
            orient = spec.get("orient", len(f) == 2)
            X[name], errs[name] = solve_limb(T, name, tgt, hint, yaw=spec.get("yaw", 0.0) if orient else None,
                                             toe=spec.get("toe", 0.0), pole=spec.get("pole"), orient=orient)
        elif "hand" in spec or "chest" in spec:
            hint = spec.get("hint", [60, 10, 0, 60])
            if "chest" in spec:
                # a hand held relative to the chest (a guard, a hand behind the back): it turns
                # and leans with the body instead of staying where it was in the room
                Rc, pc = fk(T)["UpperTorso"]
                tgt = pc + Rc @ np.array(spec["chest"], float)
            else:
                tgt = spec["hand"]
            X[name], errs[name] = solve_limb(T, name, tgt, hint, pole=spec.get("pole"))
    T["_x"] = X
    return T, errs


def ground(T, k):
    """Move the root up or down so the lowest planted foot's sole is on the floor."""
    if k.get("air"):
        return T
    W = fk(T)
    feet = [n for n in ("RightFoot", "LeftFoot")]
    rig = A.Rig(RIG)
    low = min(float((W[f][1] + (W[f][0] @ rig.corners[f].T).T)[:, 1].min()) for f in feet)
    p, R = T["Root"]
    T["Root"] = (p + np.array([0, FLOOR - low, 0]), R)
    return T


def resolve(keys):
    """Each key solved. A key whose planted feet cannot be reached at its root height (the
    legs are too short for that stance) is lowered until they are: the body sinks into its
    knees instead of the feet floating. A key without planted feet is grounded whole."""
    out = []
    for k in keys:
        planted = [n for n in ("RL", "LL") if len(k.get(n, {}).get("foot", [])) == 2]
        fixed_y = "y" in k.get("root", {})
        kk = json.loads(json.dumps(k))
        kk.setdefault("root", {})
        if not fixed_y:
            kk["root"]["y"] = 0.0
        best = None
        for _ in range(8):
            T, errs = build_key(kk)
            e = max([errs.get(n, 0.0) for n in planted] or [0.0])
            if best is None or e < best[0] - .004:
                best = (e, kk["root"]["y"], T, errs)
            else:
                break          # lowering no longer helps: the foot is out of reach another way
            if fixed_y or e < .015:
                break
            kk["root"]["y"] -= e * 1.05
        e, kk["root"]["y"], T, errs = best
        sink = k.get("root", {}).get("sink", 0.0)
        if sink and not fixed_y:
            kk["root"]["y"] -= sink
            T, errs = build_key(kk)
        if not planted and not k.get("air") and k.get("ground", True):
            T = ground(T, k)
        out.append((k, T, errs))
    return out


_RIG = None


def _rig():
    global _RIG
    if _RIG is None:
        _RIG = A.Rig(RIG)
    return _RIG


def sole_y(spec):
    """The foot's centre height when its lowest edge is on the floor: a heel raised (toe < 0)
    or a toe raised tips the sole, and the foot has to sit higher for its edge to touch."""
    p = math.radians(abs(spec.get("toe", 0.0)))
    half_len = RIG["sizes"]["RightFoot"][2] / 2
    return FLOOR + FOOT_HALF * math.cos(p) + half_len * math.sin(p) + spec.get("lift", 0.0)


def _plant(k, name):
    spec = k.get(name, {})
    f = spec.get("foot")
    if f is None or len(f) != 2:
        return None
    return np.array([f[0], sole_y(spec), f[1]]), spec.get("yaw", 0.0), spec.get("toe", 0.0)


def sample(resolved, length):
    """Every 30th of a second: the keys slerped with their ease, then every foot planted in
    both keys around that time solved again where it stands (its target lerped), so a foot
    on the floor stays on the floor while the hips turn and drop between the keys."""
    n = int(round(length * FPS)) + 1
    rows = {KEYS[j["name"]]: [] for j in ORDER}
    times = [k["t"] for k, _, _ in resolved]
    for i in range(n):
        t = min(length, i / FPS)
        a = max(0, max(idx for idx, tt in enumerate(times) if tt <= t + 1e-9))
        b = min(len(times) - 1, a + 1)
        u = 0.0 if b == a or times[b] <= times[a] else (t - times[a]) / (times[b] - times[a])
        u = ease(resolved[a][0].get("ease", "smooth"), max(0.0, min(1.0, u)))
        Ta, Tb = resolved[a][1], resolved[b][1]
        TF = {}
        for j in ORDER:
            name = j["name"]
            pa, Ra = Ta.get(name, (np.zeros(3), np.eye(3)))
            pb, Rb = Tb.get(name, (np.zeros(3), np.eye(3)))
            q = slerp(R_to_q(Ra), R_to_q(Rb), u)
            x, y, z, w = q
            R = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                          [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                          [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
            TF[name] = (pa + (pb - pa) * u, R)
        if 0 < u < 1:
            for leg in ("RL", "LL"):
                pa_, pb_ = _plant(resolved[a][0], leg), _plant(resolved[b][0], leg)
                xa, xb = Ta["_x"].get(leg), Tb["_x"].get(leg)
                if pa_ is None or pb_ is None or xa is None or xb is None:
                    continue
                tgt = pa_[0] + (pb_[0] - pa_[0]) * u
                yaw = pa_[1] + (pb_[1] - pa_[1]) * u
                # a planted foot that moves to a new spot (its ball moves, not just turns on
                # it) is a step: it rises off the floor on the way instead of sliding
                ball_a = pa_[0] + np.array([-math.sin(math.radians(pa_[1])), 0, -math.cos(math.radians(pa_[1]))]) * .38
                ball_b = pb_[0] + np.array([-math.sin(math.radians(pb_[1])), 0, -math.cos(math.radians(pb_[1]))]) * .38
                step = float(np.hypot(*(ball_b - ball_a)[[0, 2]]))
                if step > .12:
                    tgt = tgt + np.array([0.0, min(.45, .2 + step * .35) * math.sin(math.pi * u), 0.0])
                toe = pa_[2] + (pb_[2] - pa_[2]) * u
                solve_limb(TF, leg, tgt, xa + (xb - xa) * u, yaw=yaw, toe=toe)
        if 0 < u < 1 and not resolved[a][0].get("air") and not resolved[b][0].get("air"):
            # no foot through the floor between two keys: a free foot (a kick, a leg on its
            # way back down) whose sole dips under the floor is lifted back onto it
            W = fk(TF)
            rig = _rig()
            for leg, part in (("RL", "RightFoot"), ("LL", "LeftFoot")):
                if _plant(resolved[a][0], leg) is not None and _plant(resolved[b][0], leg) is not None:
                    continue
                Rf, pf = W[part]
                low = float((pf + (Rf @ rig.corners[part].T).T)[:, 1].min())
                if low < FLOOR - .02:
                    xa, xb = Ta["_x"].get(leg), Tb["_x"].get(leg)
                    if xa is None or xb is None:
                        continue
                    solve_limb(TF, leg, pf + np.array([0, FLOOR - low + .09, 0]), xa + (xb - xa) * u, orient=False)
        for j in ORDER:
            name = j["name"]
            p, R = TF[name]
            q = R_to_q(R)
            key = KEYS[name]
            if key == "Root":
                rows[key].append([round(float(v), 4) for v in list(p) + list(q)])
            else:
                rows[key].append([round(float(v), 4) for v in q])
    # keep each joint's quaternions on one hemisphere (no sign flips between samples)
    for key, lst in rows.items():
        off = 3 if key == "Root" else 0
        for i in range(1, len(lst)):
            if sum(lst[i][off + c] * lst[i - 1][off + c] for c in range(4)) < 0:
                lst[i][off:off + 4] = [-v for v in lst[i][off:off + 4]]
    return n, rows


def make_clip(spec, old):
    """spec: {"name", "keys": [...], "length"?, "markers"?, "loop"?}. old: the clip replaced
    (its length and markers are kept: the timings are the DEV's)."""
    length = spec.get("length") or old["length"]
    markers = dict(old.get("markers") or {}) if old else dict(spec.get("markers") or {})
    keys = spec["keys"]
    # keys may be placed relative to the markers: "t": "contact-0.05"
    for k in keys:
        if isinstance(k["t"], str):
            base, _, off = k["t"].replace("+", " +").replace("-", " -").partition(" ")
            k["t"] = round(markers[base] + float(off.replace(" ", "") or 0), 4) if base in markers else float(k["t"])
        k["t"] = max(0.0, min(length, float(k["t"])))
    keys.sort(key=lambda k: k["t"])
    if keys[-1]["t"] < length:
        keys.append(dict(keys[-1], t=length))
    resolved = resolve(keys)
    n, rows = sample(resolved, length)
    loop = bool(spec.get("loop", old.get("loop") if old else False))
    clip = {"fps": FPS, "frames": n, "length": round(length, 4), "loop": loop, "markers": markers,
            "meta": {"source": "syph_author", "e2": 1}, "joints": rows}
    errs = {i: e for i, (_, _, e) in enumerate(resolved) if e and max(e.values()) > .08}
    return clip, errs


# ------------------------------------------------------------------ looking at it
def sheet(clip, path, title="", times=None, dpi=90):
    """The body at the given times (default 8 even samples), three views per time: from its
    right side (forward to the right), from the front, and from three-quarter front-left
    (the duel camera's usual angle)."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    rig = A.Rig(RIG)
    flat = {"fps": clip["fps"], "frames": clip["frames"], "joints": {k: [v for row in rows for v in row] for k, rows in clip["joints"].items()}}
    W = rig.pose(flat)
    n = clip["frames"]
    times = times if times is not None else [clip["length"] * i / 7 for i in range(8)]
    idx = [min(n - 1, int(round(t * clip["fps"]))) for t in times]
    fig, axes = plt.subplots(3, len(idx), figsize=(2.3 * len(idx), 8.0), squeeze=False)
    faces = [(0, 1, 3, 2), (4, 5, 7, 6), (0, 1, 5, 4), (2, 3, 7, 6), (0, 2, 6, 4), (1, 3, 7, 5)]
    col = {"Head": "#f2d3a8", "UpperTorso": "#9a9a9a", "LowerTorso": "#555555"}
    views = [ry(math.radians(90)), np.eye(3), ry(math.radians(-35))]   # right side, front, 3/4
    # right limbs warm (red/orange), left limbs cool (blue): which side does what reads at once
    for c, i in enumerate(idx):
        for r, V in enumerate(views):
            ax = axes[r][c]
            def proj(P):
                Q = P @ V.T
                return -Q[:, 0] if r == 0 else -Q[:, 0], Q[:, 1], Q[:, 2]
            items = []
            for p in rig.sizes:
                C = rig.corners_at(W, p)[i] @ V.T
                depth = C[:, 2].mean()
                items.append((depth, p, C))
            for depth, p, C in sorted(items, key=lambda t: -t[0]):
                for f in faces:
                    xs = [-C[v][0] for v in f]
                    ys = [C[v][1] for v in f]
                    c_ = col.get(p, ("#e0502a" if "Hand" in p or "Foot" in p else "#f09a50") if "Right" in p
                                 else ("#2a60c0" if "Hand" in p or "Foot" in p else "#6fa0e0"))
                    ax.fill(xs, ys, color=c_, alpha=.85, lw=.4, ec="k")
            ax.axhline(FLOOR, color="#555", lw=.8)
            ax.set_xlim(-3.4, 3.4); ax.set_ylim(-3.3, 3.0); ax.set_aspect("equal"); ax.axis("off")
            if r == 0:
                ax.set_title("%.2fs" % (i / clip["fps"]), fontsize=8)
    fig.suptitle(title, fontsize=10)
    fig.tight_layout()
    fig.savefig(path, dpi=dpi)
    plt.close(fig)


def grade(name, clip):
    import clip_grades as G
    rig = A.Rig(RIG)
    flat = dict(clip)
    flat["joints"] = {k: [v for row in rows for v in row] for k, rows in clip["joints"].items()}
    return G.grade(rig, name, flat)


def to_luau(clips, header):
    import clips_to_luau as C
    out = ["-- GENERATED by tools/blender/syph_author.py (" + header + ").",
           "-- Do not edit by hand: re-author the spec and re-run. Rows: Root = x,y,z,qx,qy,qz,qw;",
           "-- other joints = qx,qy,qz,qw; Roblox axes (Motor6D.Transform).",
           "return {"]
    for name in sorted(clips):
        c = clips[name]
        mk = ",".join("%s=%s" % (k, C.fmt(v)) for k, v in sorted(c["markers"].items()))
        meta = ",".join("%s=%s" % (k, json.dumps(v) if isinstance(v, str) else C.fmt(v)) for k, v in sorted(c["meta"].items()))
        out.append('\t["%s"]={fps=%d,frames=%d,length=%s,loop=%s,markers={%s},meta={%s},joints={' % (
            name, c["fps"], c["frames"], C.fmt(c["length"]), "true" if c["loop"] else "false", mk, meta))
        for key in sorted(c["joints"]):
            flat = [C.fmt(v) for row in c["joints"][key] for v in row]
            out.append("\t\t%s={%s}," % (key, ",".join(flat)))
        out.append("\t}},")
    out.append("}")
    return "\n".join(out) + "\n"
