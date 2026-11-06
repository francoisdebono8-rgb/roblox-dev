"""Rock Lee (Leaf), jutsu pass v2 (05/11) - WORK IN PROGRESS: v0 ports the
current clips so every name exists; each jutsu is then re-authored below.
"""
import math, os, json
import bpy
from mathutils import Vector, Quaternion, Matrix
import nd_anim, nd_ctrl, nd_rig
from nd_shot import Shot, merge, POSE_BONES
import jutsu_lee, lee_p8, gaps_e6

N = "Leaf."
F60 = 60.0

# ===================================================================== captures
# A Mixamo capture (nd_mocap.track, place "full") turned into CONTROL-rig
# frames (nd_ctrl), so it can be blended, bone by bone and frame by frame,
# with key poses authored in the pose vocabulary (nd_shot.Shot): the capture
# gives the weight and the timing of a real body, the key poses give Lee's
# silhouette and the game's timing. The FK of the capture is computed on OUR
# segments (nd_rig.JOINTS), the legs go back through the control rig's IK
# (a world ankle, the kneecap's direction), so a foot the capture plants can
# be locked to the floor exactly (no skate by construction).
CACHE = os.environ.get("ND_LEE_CAPS", "/tmp/claude-0/-home-claude/60386c0c-0f7e-5237-92aa-0aedd11b1cac/scratchpad/v2/Leaf/lib")
MIXAMO = os.environ.get("ND_MIXAMO", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo")
H = nd_rig.ROOT_HEIGHT
CENTRE = nd_ctrl.CENTRE
_caps = {}


def capture(key):
    """The capture as {"q": {joint: [Quaternion]}, "loc": [Vector]} at 30 fps
    (Roblox axes, HumanoidRootPart space, hips travel kept)."""
    if key in _caps:
        return _caps[key]
    path = os.path.join(CACHE, key + ".json")
    if os.path.exists(path):
        d = json.load(open(path))
        tr = {"q": {j: [Quaternion(q) for q in v] for j, v in d["q"].items()}, "loc": [Vector(v) for v in d["loc"]]}
    else:
        import nd_mocap
        before = set(bpy.data.objects)
        acts = set(bpy.data.actions)
        src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
        t = nd_mocap.track(src, s0, s1, "full")
        for o in set(bpy.data.objects) - before:
            bpy.data.objects.remove(o, do_unlink=True)
        for a in set(bpy.data.actions) - acts:
            bpy.data.actions.remove(a)
        tr = {"q": t["q"], "loc": t["loc"]}
        try:
            os.makedirs(CACHE, exist_ok=True)
            json.dump({"fps": 30, "q": {j: [list(q) for q in v] for j, v in tr["q"].items()},
                       "loc": [list(v) for v in tr["loc"]]}, open(path, "w"))
        except OSError:
            pass
    _caps[key] = tr
    return tr


def sub(tr, a, b, speed=1.0, n=None):
    """Capture frames a..b (30 fps, fractional) resampled to 60 fps frames
    (`speed` > 1 plays it faster; `n` forces the frame count)."""
    if n is None:
        n = int(round((b - a) * 2 / speed)) + 1
    out = {"q": {j: [] for j in tr["q"]}, "loc": []}
    last = len(tr["loc"]) - 1
    for k in range(n):
        x = min(last, max(0.0, a + (b - a) * k / max(1, n - 1)))
        i = int(math.floor(x)); i2 = min(last, i + 1); u = x - i
        for j, qs in tr["q"].items():
            qa, qb = qs[i], qs[i2]
            if qa.dot(qb) < 0:
                qb = -qb
            out["q"][j].append(qa.slerp(qb, u))
        out["loc"].append(tr["loc"][i].lerp(tr["loc"][i2], u))
    return out


def warp(tr, src, dst):
    """Piecewise-linear time warp: capture frames src[i] (30 fps) land on
    output frames dst[i] (60 fps)."""
    n = dst[-1] + 1
    xs = []
    for t in range(n):
        for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
            if b0 <= t <= b1:
                xs.append(a0 + (a1 - a0) * (t - b0) / max(b1 - b0, 1e-6))
                break
    out = {"q": {j: [] for j in tr["q"]}, "loc": []}
    last = len(tr["loc"]) - 1
    for x in xs:
        x = min(last, max(0.0, x))
        i = int(math.floor(x)); i2 = min(last, i + 1); u = x - i
        for j, qs in tr["q"].items():
            qa, qb = qs[i], qs[i2]
            if qa.dot(qb) < 0:
                qb = -qb
            out["q"][j].append(qa.slerp(qb, u))
        out["loc"].append(tr["loc"][i].lerp(tr["loc"][i2], u))
    return out


def fk(q, loc):
    """Part frames (4x4, Roblox axes, HumanoidRootPart space) of one frame."""
    F = {"HRP": Matrix.Identity(4)}
    for j in nd_rig.ORDER:
        p0, p1 = nd_ctrl.MOTORS[j]
        piv = Vector(nd_rig.JOINTS[j][0])
        T = q[j].to_matrix().to_4x4()
        if j == "Root":
            T = Matrix.Translation(loc) @ T
        F[p1] = F[p0] @ Matrix.Translation(piv - CENTRE[p0]) @ T @ Matrix.Translation(CENTRE[p1] - piv)
    return F


def joint_at(F, joint):
    p0, p1 = nd_ctrl.MOTORS[joint]
    return F[p1] @ (Vector(nd_rig.JOINTS[joint][0]) - CENTRE[p1])


def frame_q(tr, k):
    return {j: tr["q"][j][k] for j in tr["q"]}


def digest(tr, step=1):
    """Per frame: hips height, hips x/z, hips yaw, ankle heights (world, floor
    = the lowest standing ankle) - to choose windows without rendering."""
    rows = []
    for k in range(0, len(tr["loc"]), step):
        F = fk(frame_q(tr, k), tr["loc"][k])
        fwd = F["LowerTorso"].to_3x3() @ Vector((0, 0, -1))
        aR, aL = joint_at(F, "RightAnkle"), joint_at(F, "LeftAnkle")
        rows.append((k, round(tr["loc"][k].y, 2), round(tr["loc"][k].x, 2), round(tr["loc"][k].z, 2),
                     round(math.degrees(math.atan2(fwd.x, -fwd.z))), round(aR.y + H, 2), round(aL.y + H, 2),
                     tuple(round(c, 1) for c in aR), tuple(round(c, 1) for c in aL)))
    return rows


def ctrl_frame(arm, q, loc, travel=(0.0, 0.0)):
    """One capture frame -> control bone values {bone: (quat or None, loc or None)}
    (travel: the root bone's world x/z; loc is the hips relative to it)."""
    out = {}
    tx, tz = travel
    out["root"] = (Quaternion(), nd_rig.rb((tx, 0, tz)))
    rest = arm.data.bones["cog"].matrix_local.to_3x3()
    out["cog"] = (nd_ctrl.local_rot(arm, "cog", q["Root"].to_matrix()), rest.transposed() @ nd_rig.rb(loc))
    for j, bone in nd_ctrl.JOINT_BONE.items():
        out[bone] = (nd_ctrl.local_rot(arm, bone, q[j].to_matrix()), None)
    F = fk(q, loc)
    off = Vector((tx, H, tz))
    for side, n in (("R", "Right"), ("L", "Left")):
        ankle = joint_at(F, n + "Ankle") + off
        hip = joint_at(F, n + "Hip") + off
        Rf = F[n + "Foot"].to_3x3()
        b = arm.data.bones["foot_ik." + side]
        out["foot_ik." + side] = (nd_ctrl.local_rot(arm, "foot_ik." + side, Rf),
                                  b.matrix_local.to_3x3().transposed() @ (nd_rig.rb(ankle) - b.head_local))
        out["knee_pole." + side] = (None, pole_loc(arm, side, hip, ankle, F[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1))))
    return out


def pole_loc(arm, side, hip, ankle, kneecap):
    """knee_pole location for a leg hip->ankle whose kneecap faces `kneecap`
    (Roblox world)."""
    d = (ankle - hip)
    d = d.normalized() if d.length > 1e-4 else Vector((0, -1, 0))
    perp = kneecap - d * kneecap.dot(d)
    if perp.length < 1e-3:
        perp = Vector((0, 0, -1)) - d * (-d.z)
    p = (hip + ankle) * .5 + perp.normalized() * 3.0
    b = arm.data.bones["knee_pole." + side]
    return b.matrix_local.to_3x3().transposed() @ (nd_rig.rb(p) - b.head_local)


def ctrl_frames(arm, tr, travel=None):
    """Every frame of a (resampled) track -> control bone values. travel:
    a function k -> (x, z) for the root bone (default: none; the hips keep the
    capture's travel)."""
    out = []
    for k in range(len(tr["loc"])):
        t = travel(k) if travel else (0.0, 0.0)
        loc = tr["loc"][k] - Vector((t[0], 0, t[1]))
        out.append(ctrl_frame(arm, frame_q(tr, k), loc, t))
    return out


def sample_action(arm, act, frame):
    """The control bone values an action gives at `frame` (F-curves evaluated)."""
    vals = {}
    for fc in nd_anim.fcurves(act):
        p = fc.data_path
        if not p.startswith('pose.bones["'):
            continue
        bone = p.split('"')[1]
        vals.setdefault(bone, {}).setdefault(p.rsplit(".", 1)[1], {})[fc.array_index] = fc.evaluate(frame)
    out = {}
    for bone in POSE_BONES:
        v = vals.get(bone, {})
        q = v.get("rotation_quaternion")
        l = v.get("location")
        out[bone] = (Quaternion([q.get(i, 1.0 if i == 0 else 0.0) for i in range(4)]).normalized() if q else None,
                     Vector([l.get(i, 0.0) for i in range(3)]) if l else None)
    return out


def blend(a, b, w):
    """Bone values a -> b by w (a float, or {bone: float})."""
    out = {}
    for bone in POSE_BONES:
        qa, la = a.get(bone, (None, None))
        qb, lb = b.get(bone, (None, None))
        u = w.get(bone, 0.0) if isinstance(w, dict) else w
        if qa is not None and qb is not None:
            if qa.dot(qb) < 0:
                qb = -qb
            q = qa.slerp(qb, u)
        else:
            q = qa if qa is not None else qb
        if la is not None and lb is not None:
            l = la.lerp(lb, u)
        else:
            l = la if la is not None else lb
        out[bone] = (q, l)
    return out


def bake(arm, name, frames, markers=None):
    """Keys every frame's control bone values (60 fps) as action `name`."""
    act = nd_anim.new_action(arm, name)
    last = {}
    for f, vals in enumerate(frames):
        for bone in POSE_BONES:
            q, l = vals[bone]
            pb = arm.pose.bones[bone]
            if q is not None:
                p = last.get(bone)
                if p is not None and p.dot(q) < 0:
                    q = -q
                last[bone] = q
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=f, group=bone)
            if l is not None:
                pb.location = l
                pb.keyframe_insert("location", frame=f, group=bone)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = markers or {}
    act["nd_loop"] = False
    act["nd_meta"] = {}
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, len(frames) - 1)
    return act


def keyed(arm, shot):
    """A Shot built, sampled per frame and thrown away: key-posed bone values."""
    act = shot.build()
    a, b = int(act.frame_range[0]), int(act.frame_range[1])
    out = [sample_action(arm, act, f) for f in range(a, b + 1)]
    bpy.data.actions.remove(act)
    return out


GROUPS = {"body": ("root", "cog"), "spine": ("spine", "neck"), "ra": ("shoulder.R", "forearm.R", "hand.R"),
          "la": ("shoulder.L", "forearm.L", "hand.L"), "rf": ("foot_ik.R", "knee_pole.R"), "lf": ("foot_ik.L", "knee_pole.L")}


def smooth(u):
    u = max(0.0, min(1.0, u))
    return u * u * (3 - 2 * u)


def ramp(f, pts):
    """Piecewise smoothstep weight through [(frame, w), ...]."""
    if f <= pts[0][0]:
        return pts[0][1]
    for (f0, w0), (f1, w1) in zip(pts, pts[1:]):
        if f0 <= f <= f1:
            return w0 + (w1 - w0) * smooth((f - f0) / max(f1 - f0, 1e-6))
    return pts[-1][1]


def world_feet(tr, travel=None):
    """Per frame world ankle (Roblox, floor y = 0) and foot rotation, both sides."""
    out = []
    for k in range(len(tr["loc"])):
        t = travel(k) if travel else (0.0, 0.0)
        F = fk(frame_q(tr, k), tr["loc"][k] - Vector((t[0], 0, t[1])))
        off = Vector((t[0], H, t[1]))
        row = {}
        for side, n in (("R", "Right"), ("L", "Left")):
            row[side] = (joint_at(F, n + "Ankle") + off, F[n + "Foot"].to_3x3(), joint_at(F, n + "Hip") + off,
                         F[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1)))
        out.append(row)
    return out


def lock_feet(arm, vals, feet, floor=.62, still=.09, runs=None):
    """A foot the capture puts on the floor stays exactly where it landed:
    contact runs (ankle low and slow) are held at their first frame's spot,
    on the floor, with a short ramp in and out. runs: {side: [(f0, f1)]} to
    force them instead."""
    n = len(feet)
    for side in ("R", "L"):
        if runs is not None:
            spans = runs.get(side, [])
        else:
            low = [feet[k][side][0].y < floor and (k == 0 or (feet[k][side][0] - feet[k - 1][side][0]).length < still) for k in range(n)]
            spans, k = [], 0
            while k < n:
                if low[k]:
                    j = k
                    while j + 1 < n and low[j + 1]:
                        j += 1
                    if j - k >= 2:
                        spans.append((k, j))
                    k = j + 1
                else:
                    k += 1
        for f0, f1 in spans:
            pos, R, _, _ = feet[f0][side]
            spot = Vector((pos.x, .4, pos.z))
            # (the foot lies flat on the floor where it is held: yaw kept)
            fw = R @ Vector((0, 0, -1))
            yaw = math.degrees(math.atan2(fw.x, -fw.z))
            Rflat = nd_anim.R(0, -yaw, 0)
            for k in range(f0, f1 + 1):
                w = min(1.0, (k - f0 + 1) / 3.0, (f1 - k + 1) / 3.0) if (f0 > 0 and f1 < n - 1) else 1.0
                if f0 == 0:
                    w = min(1.0, (f1 - k + 1) / 3.0) if f1 < n - 1 else 1.0
                p0, R0, hip, cap = feet[k][side]
                p = p0.lerp(spot, w)
                b = arm.data.bones["foot_ik." + side]
                q0 = nd_ctrl.local_rot(arm, "foot_ik." + side, R0)
                q1 = nd_ctrl.local_rot(arm, "foot_ik." + side, Rflat)
                if q0.dot(q1) < 0:
                    q1 = -q1
                vals[k]["foot_ik." + side] = (q0.slerp(q1, w), b.matrix_local.to_3x3().transposed() @ (nd_rig.rb(p) - b.head_local))
                vals[k]["knee_pole." + side] = (None, pole_loc(arm, side, hip, p, cap))
    return vals


def layer(arm, cap, key, weights):
    """Per frame: capture values `cap` toward key-posed values `key` by
    weights(f) -> {group: w} (w = 1: all key pose)."""
    out = []
    for f in range(len(cap)):
        wg = weights(f)
        w = {b: wg.get(g, 0.0) for g, bones in GROUPS.items() for b in bones}
        out.append(blend(cap[f], key[min(f, len(key) - 1)], w))
    return out


# ===================================================================== helpers
STANCE = lee_p8.STANCE
BACK = lee_p8.BACK


def stance_at(tx, tz, rf=None, lf=None, over=None):
    """Lee's stance with the HumanoidRootPart at (tx, tz); feet at world
    spots (ankle x/z) when given, else the stance's own."""
    p = merge(STANCE, {"travel": {"x": tx, "z": tz, "yaw": 0}})
    p["rf"] = merge(p["rf"], {"x": (rf[0] - .5) if rf else STANCE["rf"]["x"] + tx, "z": rf[1] if rf else STANCE["rf"]["z"] + tz, "y": 0, "toe": 0, "knee": 0})
    p["lf"] = merge(p["lf"], {"x": (lf[0] + .5) if lf else STANCE["lf"]["x"] + tx, "z": lf[1] if lf else STANCE["lf"]["z"] + tz, "y": 0, "toe": 0, "knee": 0})
    return merge(p, over or {})


def hips_travel(tr, smooth_n=2):
    """travel(k): the capture hips' x/z, lightly smoothed."""
    xs = [v.x for v in tr["loc"]]
    zs = [v.z for v in tr["loc"]]
    n = len(xs)

    def avg(a, k):
        lo, hi = max(0, k - smooth_n), min(n - 1, k + smooth_n)
        return sum(a[lo:hi + 1]) / (hi - lo + 1)
    sx = [avg(xs, k) for k in range(n)]
    sz = [avg(zs, k) for k in range(n)]
    return lambda k: (sx[min(k, n - 1)], sz[min(k, n - 1)])


# ================================================================ flying kick
def flying_kick(arm):
    """FlyingKick (Dynamic Entry and his run strike, Attacks .10/.16/.32:
    contact 6, recover 14, end 28)."""
    tr = warp(capture("flying_kick"), [5, 12, 17, 21, 31], [0, 6, 14, 19, 28])
    tv = hips_travel(tr)
    feet = world_feet(tr, tv)
    cap = lock_feet(arm, ctrl_frames(arm, tr, tv), feet)
    R_end, L_end = feet[-1]["R"][0], feet[-1]["L"][0]
    cx, cz = (R_end.x + L_end.x) / 2, (R_end.z + L_end.z) / 2
    sh = Shot(arm, "tmp")
    sh.key(0, stance_at(0, 0), "ease")
    sh.key(28, stance_at(cx, cz, (R_end.x, R_end.z), (L_end.x, L_end.z)), "ease")
    key = keyed(arm, sh)
    w = lambda f: {g: ramp(f, [(21, 0), (28, 1)]) for g in ("body", "spine", "ra", "la")}
    return bake(arm, N + "FlyingKick", layer(arm, cap, key, w), {"contact": 6 / 60, "recover": 14 / 60})


# ===================================================================== author
def author(arm):
    acts = []
    ch, drawn = jutsu_lee.nunchaku_channel(arm)
    acts += [ch, jutsu_lee.nunchaku(arm, drawn), jutsu_lee.goriki_channel(arm), jutsu_lee.goriki_senpu(arm)]
    acts += jutsu_lee.dancing_leaf(arm)
    acts += jutsu_lee.drunken_fist(arm)
    acts += lee_p8.great_whirlwind(arm)
    acts += [lee_p8.lotus("PrimaryLotus", True)(arm), flying_kick(arm), lee_p8.awaken(arm)]
    acts += gaps_e6.remove_weights(arm)
    return acts
