"""Moveset pass v2 (06/11): Naruto (Legion) - strings, heavies, air attacks,
jumps and landings, re-authored from Mixamo captures on the control rig.

(Clip docstrings: see each function. The pipeline is at the top.)
"""
import bpy, math, os, re
from mathutils import Matrix, Quaternion, Vector
import nd_rig, nd_ctrl, nd_anim, nd_mocap, nd_style
from nd_rig import JOINTS, B
import naruto_p5 as P5
from nd_shot import Shot, merge

HERE = os.path.dirname(os.path.abspath(__file__))
N = "Legion."
FPS = 60
H = nd_rig.ROOT_HEIGHT
MIXAMO = os.environ.get("ND_MIXAMO", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo")
GAME = os.path.join(HERE, "..", "..", "src", "Client")
NAMES = ["Air1", "Air2", "AirDrive", "AirFlip", "AirSpike", "AirSwitch", "CloneKick", "CloneKickStrike", "DashAttack", "Flip",
         "Grab", "Guard.Impact", "HeadDive", "Headbutt", "Heavy", "Jump.Air", "Jump.Leap", "Land", "Launcher", "Light1", "Light2",
         "Light3", "Light4", "Light5", "MirrorClone", "MirrorStrike", "Rasengan", "Slam", "Tackle", "ThrowUp", "UzumakiKick",
         "UzumakiRise"]

# ====================================================================== pipeline
# A "track" is what the game plays: per 60 fps frame, the Motor6D transform of
# every joint (Roblox axes; Root also carries the hips' offset from the
# HumanoidRootPart). Captures and the game's own clips are both tracks; a track
# is keyed onto the control rig through forward kinematics (the FK bones take
# the parts' rotations, the IK feet take the feet, the knee poles the knees),
# so the export (nd_shot) reads back the same body, and planted feet are locked
# in the world on foot_ik.
MOTORS = nd_ctrl.MOTORS
CENTRE = nd_ctrl.CENTRE
CHAIN = ["Root", "Waist", "Neck", "Right", "RightElbow", "RightWrist", "Left", "LeftElbow", "LeftWrist",
         "RightHip", "RightKnee", "RightAnkle", "LeftHip", "LeftKnee", "LeftAnkle"]
B4 = B.to_4x4()
PARENT_BONE = {"cog": "root", "spine": "cog", "neck": "spine"}
for _s in ("R", "L"):
    PARENT_BONE["shoulder." + _s] = "spine"
    PARENT_BONE["forearm." + _s] = "shoulder." + _s
    PARENT_BONE["hand." + _s] = "forearm." + _s
FK_BONES = {"cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head"}
for _s, _n in (("R", "Right"), ("L", "Left")):
    FK_BONES["shoulder." + _s] = _n + "UpperArm"
    FK_BONES["forearm." + _s] = _n + "LowerArm"
    FK_BONES["hand." + _s] = _n + "Hand"


def new_track(n):
    return {"q": {j: [Quaternion() for _ in range(n)] for j in CHAIN}, "loc": [Vector() for _ in range(n)], "fps": FPS}


def copy(tr):
    return {"q": {j: [q.copy() for q in v] for j, v in tr["q"].items()}, "loc": [v.copy() for v in tr["loc"]],
            "fps": tr.get("fps", FPS)}


def length(tr):
    return len(tr["loc"])


def fk(q, loc, hrp=None):
    """Part CFrames (Roblox world, floor at y 0) from one frame of joints."""
    P = {"HRP": hrp if hrp is not None else Matrix.Translation((0, H, 0))}
    for j in CHAIN:
        p0, p1 = MOTORS[j]
        pivot = Vector(JOINTS[j][0])
        T = q[j].to_matrix().to_4x4()
        if j == "Root":
            T.translation = loc
        P[p1] = P[p0] @ Matrix.Translation(pivot - CENTRE[p0]) @ T @ Matrix.Translation(CENTRE[p1] - pivot)
    return P


def frame(tr, i):
    return {j: tr["q"][j][i] for j in CHAIN}, tr["loc"][i]


def point(P, part, joint, off=(0, 0, 0)):
    """World position of a joint pivot (+ offset in the part's axes)."""
    return P[part] @ (Vector(JOINTS[joint][0]) - CENTRE[part] + Vector(off))


def resample(tr, n_out):
    """Same motion over n_out frames (slerp)."""
    n = length(tr)
    out = new_track(n_out)
    for k in range(n_out):
        x = k * (n - 1) / max(1, n_out - 1)
        a = int(math.floor(x)); b = min(n - 1, a + 1); u = x - a
        for j in CHAIN:
            qa, qb = tr["q"][j][a], tr["q"][j][b]
            if qa.dot(qb) < 0:
                qb = -qb
            out["q"][j][k] = qa.slerp(qb, u)
        out["loc"][k] = tr["loc"][a].lerp(tr["loc"][b], u)
    return out


def at_time(tr, x):
    n = length(tr)
    x = min(max(x, 0), n - 1)
    a = int(math.floor(x)); b = min(n - 1, a + 1); u = x - a
    q = {}
    for j in CHAIN:
        qa, qb = tr["q"][j][a], tr["q"][j][b]
        if qa.dot(qb) < 0:
            qb = -qb
        q[j] = qa.slerp(qb, u)
    return q, tr["loc"][a].lerp(tr["loc"][b], u)


def warp(tr, src, dst, n_out):
    """Piecewise time warp: capture frames src[i] land on output frames dst[i]
    (consecutive equal src values = a hold, the hit-stop)."""
    out = new_track(n_out)
    for k in range(n_out):
        x = src[-1]
        for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
            if b0 <= k <= b1:
                x = a0 + (a1 - a0) * (k - b0) / max(b1 - b0, 1e-6)
                break
        q, loc = at_time(tr, x)
        for j in CHAIN:
            out["q"][j][k] = q[j]
        out["loc"][k] = loc
    return out


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def blend_to(tr, pose, weights):
    """Every frame k turns toward `pose` ({joint: q}, loc) by weights[k]."""
    q0, l0 = pose
    for k, w in enumerate(weights):
        if w <= 0:
            continue
        for j in CHAIN:
            a, b = tr["q"][j][k], q0[j]
            if a.dot(b) < 0:
                b = -b
            tr["q"][j][k] = a.slerp(b, w)
        tr["loc"][k] = tr["loc"][k].lerp(l0, w)
    return tr


def melt(tr, first, last, head=.25, tail=.3, head_n=None, tail_n=None):
    """The first and last frames become the given poses (the clips around it
    chain with no snap); head/tail: the part of the clip that blends."""
    n = length(tr)
    hn = head_n if head_n is not None else max(1, int(round(head * (n - 1))))
    tn = tail_n if tail_n is not None else max(1, int(round(tail * (n - 1))))
    if first is not None:
        blend_to(tr, first, [smooth(1 - k / hn) if k < hn else 0 for k in range(n)])
    if last is not None:
        blend_to(tr, last, [smooth(1 - (n - 1 - k) / tn) if n - 1 - k < tn else 0 for k in range(n)])
    return tr


def limit(tr, max_deg=40.0):
    """No joint turns more than max_deg between two 60 fps frames."""
    cap = math.radians(max_deg)
    for j in CHAIN:
        qs = tr["q"][j]
        for k in range(1, len(qs)):
            prev, q = qs[k - 1], qs[k]
            if prev.dot(q) < 0:
                q = -q
            ang = prev.rotation_difference(q).angle
            ang = min(ang, 2 * math.pi - ang)
            if ang > cap:
                qs[k] = prev.slerp(q, cap / ang)
    return tr


def low_pass(tr, joints=None, passes=1):
    """A light 1-2-1 filter (capture jitter after a warp)."""
    for _ in range(passes):
        for j in (joints or CHAIN):
            qs = tr["q"][j]
            out = [qs[0]]
            for k in range(1, len(qs) - 1):
                a, b, c = qs[k - 1], qs[k], qs[k + 1]
                if a.dot(b) < 0:
                    a = -a
                if c.dot(b) < 0:
                    c = -c
                out.append(a.slerp(c, .5).slerp(b, .5))
            out.append(qs[-1])
            tr["q"][j] = out
    return tr


# ---------------------------------------------------------------- poses
_POSE_CACHE = {}


def spec_pose(arm, spec):
    """A control-rig pose spec (naruto_p5 vocabulary) -> ({joint: q}, root loc)."""
    key = repr(spec)
    if key in _POSE_CACHE:
        return _POSE_CACHE[key]
    if arm.animation_data:
        arm.animation_data.action = None
    pose = nd_ctrl.pose_bones(arm, merge(spec, {"travel": {"x": 0, "z": 0, "yaw": 0}}))
    for bname, (q, loc) in pose.items():
        pb = arm.pose.bones[bname]
        if q is not None:
            pb.rotation_quaternion = q
        if loc is not None:
            pb.location = loc
    bpy.context.view_layer.update()
    T = nd_ctrl.retarget(arm)
    q = {j: T[j].to_quaternion().normalized() for j in CHAIN}
    out = (q, T["Root"].translation.copy())
    _POSE_CACHE[key] = out
    return out


STANCE_SPEC = P5.STANCE


def stance(arm):
    return spec_pose(arm, P5.s())


def air_pose(arm, over=None):
    return spec_pose(arm, P5.air(over))


def offset_pose(tr, joint, q, weights=None):
    """A turn added on a joint (in its parent's frame), weighted per frame."""
    for k in range(length(tr)):
        w = 1.0 if weights is None else weights[k]
        if w <= 0:
            continue
        tr["q"][joint][k] = (Quaternion().slerp(q, w) @ tr["q"][joint][k]).normalized()
    return tr


def env(n, keys):
    """Piecewise-linear weight envelope from (frame, weight) pairs (smoothstep)."""
    out = []
    for k in range(n):
        w = keys[-1][1]
        if k <= keys[0][0]:
            w = keys[0][1]
        else:
            for (f0, w0), (f1, w1) in zip(keys, keys[1:]):
                if f0 <= k <= f1:
                    w = w0 + (w1 - w0) * smooth((k - f0) / max(f1 - f0, 1e-6))
                    break
        out.append(w)
    return out


def turn(pitch=0, yaw=0, roll=0):
    return nd_anim.ori({"pitch": pitch, "yaw": yaw, "roll": roll}).to_quaternion()


def arm_q(side, spec):
    sh, el, wr = nd_anim.arm_rot(side, spec)
    return sh.to_quaternion(), el.to_quaternion(), wr.to_quaternion()


# ------------------------------------------------------------ to the rig
def ground(tr, weights=None, floor=0.0):
    """The hips' height follows the lower foot (it touches the floor)."""
    for k in range(length(tr)):
        w = 1.0 if weights is None else weights[k]
        if w <= 0:
            continue
        P = fk(*frame(tr, k))
        sole = min(P[f].translation.y - .21 for f in ("RightFoot", "LeftFoot"))
        tr["loc"][k] = tr["loc"][k] + Vector((0, (floor - sole) * w, 0))
    return tr


def lift(tr, dys):
    for k, dy in enumerate(dys):
        tr["loc"][k] = tr["loc"][k] + Vector((0, dy, 0))
    return tr


def _foot_runs(Ps, foot, lo=.09):
    n = len(Ps)
    low = [Ps[k][foot].translation.y - .21 < lo for k in range(n)]
    runs, i = [], 0
    while i < n:
        if low[i]:
            j = i
            while j + 1 < n and low[j + 1]:
                j += 1
            runs.append((i, j))
            i = j + 1
        else:
            i += 1
    return runs


def flat(m, y=None):
    """A foot CFrame put flat on the floor (keeps its yaw)."""
    fwd = m.to_3x3() @ Vector((0, 0, -1))
    yaw = math.atan2(-fwd.x, -fwd.z)
    out = Matrix.Rotation(yaw, 4, "Y")
    t = m.translation.copy()
    t.y = .21 if y is None else y
    out.translation = t
    return out


def plant(Ps, travel, ramp=3, step_back=9, flat_feet=True):
    """Feet that touch the floor stay where they landed (world), each contact
    run locked at its first frame; a run that reaches the end of the clip
    steps back onto the final stance (a short lifted step) when it is not
    already there. Returns {foot: [CFrame or None]} for foot_ik."""
    n = len(Ps)
    out = {}
    for foot in ("RightFoot", "LeftFoot"):
        world = [travel[k] @ Ps[k][foot] for k in range(n)]
        tgt = list(world)
        for (i, j) in _foot_runs(Ps, foot):
            if j - i < 1:
                continue
            anchor = flat(world[i]) if flat_feet else world[i]
            if i == 0 and j == n - 1:
                # the whole clip on this foot: from the start's spot to the end's
                a, b = flat(world[0]), flat(world[-1])
                d = (a.translation - b.translation).length
                if d < .05:
                    for k in range(n):
                        tgt[k] = a
                    continue
                anchor = a
            end_spot = flat(world[n - 1]) if j == n - 1 else None
            if i == 0 and j < n - 1:
                anchor = flat(world[0])
            last = j
            if end_spot is not None and (end_spot.translation - anchor.translation).length > .05:
                last = max(i, n - 1 - step_back)
            for k in range(i, last + 1):
                tgt[k] = anchor
            if last < j:
                # the step back to the stance: lift, carry, put down
                for k in range(last + 1, n):
                    u = (k - last) / (n - 1 - last)
                    e = smooth(u)
                    m = anchor.lerp(end_spot, e) if hasattr(anchor, "lerp") else None
                    loc = anchor.translation.lerp(end_spot.translation, e)
                    rot = anchor.to_quaternion().slerp(end_spot.to_quaternion(), e)
                    m = rot.to_matrix().to_4x4()
                    m.translation = loc + Vector((0, .5 * math.sin(math.pi * u), 0))
                    tgt[k] = m
            # ramp in from the free foot into the lock
            if i > 0:
                for d in range(1, ramp + 1):
                    k = i - d
                    if k < 0:
                        break
                    w = 1 - d / (ramp + 1)
                    loc = world[k].translation.lerp(anchor.translation, w)
                    rot = world[k].to_quaternion().slerp(anchor.to_quaternion(), w)
                    m = rot.to_matrix().to_4x4()
                    m.translation = loc
                    tgt[k] = m
        out[foot] = tgt
    return out


def key_track(arm, tr, name, markers=None, travel=None, planted=True, meta=None, loop=False, feet=None):
    """Keys a track onto the control rig as action `name` (60 fps).
    travel: per frame (x, z, yaw deg) of the HumanoidRootPart, Roblox world.
    planted: feet on the floor are locked in the world (foot_ik)."""
    n = length(tr)
    act = nd_anim.new_action(arm, name)
    rest = {b.name: b.matrix_local.copy() for b in arm.data.bones}
    hrps = []
    for k in range(n):
        x, z, yaw = travel[k] if travel else (0.0, 0.0, 0.0)
        m = Matrix.Rotation(math.radians(-yaw), 4, "Y")
        m.translation = Vector((x, H, z))
        hrps.append(m)
    Ps = [fk(*frame(tr, k)) for k in range(n)]
    trav = [hrps[k] @ Matrix.Translation((0, -H, 0)) for k in range(n)]
    if feet is not None:
        foot_t = feet
    elif planted:
        foot_t = plant(Ps, trav)
    else:
        foot_t = {f: [trav[k] @ Ps[k][f] for k in range(n)] for f in ("RightFoot", "LeftFoot")}
    part_rest = {p: nd_ctrl.part_rest(p) for p in list(FK_BONES.values()) + ["HRP", "RightFoot", "LeftFoot"]}
    last_q = {}
    for k in range(n):
        P = {p: trav[k] @ m for p, m in Ps[k].items()}
        P["HRP"] = hrps[k]
        M = {"root": (B4 @ P["HRP"]) @ part_rest["HRP"].inverted() @ rest["root"]}
        for bone, part in FK_BONES.items():
            M[bone] = (B4 @ P[part]) @ part_rest[part].inverted() @ rest[bone]
        L = {"root": rest["root"].inverted() @ M["root"]}
        for bone in FK_BONES:
            p = PARENT_BONE[bone]
            L[bone] = (rest[p].inverted() @ rest[bone]).inverted() @ M[p].inverted() @ M[bone]
        for side, n_ in (("R", "Right"), ("L", "Left")):
            foot = foot_t[n_ + "Foot"][k]
            mf = (B4 @ foot) @ part_rest[n_ + "Foot"].inverted() @ rest["foot." + side]
            L["foot_ik." + side] = rest["foot_ik." + side].inverted() @ mf
            # knee pole: in the plane of the leg, toward the knee
            hip = point(P, "LowerTorso", n_ + "Hip")
            knee = point(P, n_ + "UpperLeg", n_ + "Knee")
            ankle = foot.translation + (P[n_ + "LowerLeg"].to_3x3() @ Vector((0, 0, 0)))
            ankle = foot @ (Vector(JOINTS[n_ + "Ankle"][0]) - CENTRE[n_ + "Foot"])
            axis = ankle - hip
            mid = (hip + ankle) * .5
            fwd = P[n_ + "UpperLeg"].to_3x3() @ Vector((0, 0, -1))
            d = knee - (hip + axis * (max(0.0, min(1.0, (knee - hip).dot(axis) / max(axis.length_squared, 1e-6)))))
            if d.length < .08:
                d = fwd - axis.normalized() * fwd.dot(axis.normalized()) if axis.length > 1e-4 else fwd
            pole_w = B @ (mid + d.normalized() * 3.0)
            pr = rest["knee_pole." + side]
            Lp = Matrix.Identity(4)
            Lp.translation = pr.to_3x3().transposed() @ (pole_w - pr.translation)
            L["knee_pole." + side] = Lp
        for bone, Lm in L.items():
            pb = arm.pose.bones[bone]
            q = Lm.to_quaternion().normalized()
            prev = last_q.get(bone)
            if prev is not None and prev.dot(q) < 0:
                q = -q
            last_q[bone] = q
            if not bone.startswith("knee_pole"):
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=k, group=bone)
            if bone in ("root", "cog") or bone.startswith("foot_ik") or bone.startswith("knee_pole"):
                pb.location = Lm.translation
                pb.keyframe_insert("location", frame=k, group=bone)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = dict(markers or {})
    act["nd_loop"] = bool(loop)
    act["nd_meta"] = dict(meta or {})
    return act


# ------------------------------------------------------------ game clips
def game_clip(name):
    """A clip as the game plays it now (src/Client/Authored*.luau) as a 60 fps track."""
    import glob
    for path in sorted(glob.glob(os.path.join(GAME, "Authored*.luau"))):
        txt = open(path).read()
        i = txt.find('["%s"]={' % name)
        if i < 0:
            continue
        head = re.match(r'\["[^"]+"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(\w+),markers=\{([^}]*)\}', txt[i:])
        fps, frames, ln = int(head.group(1)), int(head.group(2)), float(head.group(3))
        marks = {}
        for kv in head.group(5).split(","):
            if "=" in kv:
                a, b = kv.split("=")
                marks[a.strip()] = float(b)
        j0 = txt.find("joints={", i) + len("joints={")
        tr = {"q": {}, "loc": [], "fps": fps}
        pos = j0
        for _ in range(15):
            m = re.match(r'\s*(\w+)=\{([^}]*)\},?', txt[pos:])
            if not m:
                break
            vals = [float(v) for v in m.group(2).split(",")]
            jn = m.group(1)
            if jn == "Root":
                rows = [vals[k:k + 7] for k in range(0, len(vals), 7)]
                tr["loc"] = [Vector(r[:3]) for r in rows]
                tr["q"]["Root"] = [Quaternion((r[6], r[3], r[4], r[5])) for r in rows]
            else:
                rows = [vals[k:k + 4] for k in range(0, len(vals), 4)]
                tr["q"][jn] = [Quaternion((r[3], r[0], r[1], r[2])) for r in rows]
            pos += m.end()
        n60 = int(round(ln * FPS)) + 1
        if fps != FPS or length(tr) != n60:
            tr = resample(tr, n60)
        tr["fps"] = FPS
        return tr, marks, ln
    raise KeyError(name)


def game_clips(arm, names=None):
    """The game's current clips replayed on the rig (the triage / before)."""
    acts = []
    for nm in names or NAMES:
        tr, marks, ln = game_clip(N + nm)
        acts.append(key_track(arm, tr, N + nm, {k: v for k, v in marks.items()}, planted=False, meta={"source": "game"}))
    return acts


# ------------------------------------------------------------ captures
_CAPTURES = {}


def capture(key):
    """A Mixamo capture as a track (30 fps, hips travel kept: "full")."""
    if key in _CAPTURES:
        return copy(_CAPTURES[key])
    before = set(bpy.data.objects)
    fps = bpy.context.scene.render.fps
    src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
    tr = nd_mocap.track(src, s0, s1, "full")
    for o in set(bpy.data.objects) - before:
        data = o.data
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.context.scene.render.fps = fps
    t = {"q": {j: tr["q"][j] for j in CHAIN}, "loc": tr["loc"], "fps": 30}
    _CAPTURES[key] = t
    return copy(t)


TIPS = {"RightHand": ("RightWrist", (0, -.35, 0)), "LeftHand": ("LeftWrist", (0, -.35, 0)),
        "RightFoot": ("RightAnkle", (0, -.2, -.5)), "LeftFoot": ("LeftAnkle", (0, -.2, -.5)),
        "RightLowerLeg": ("RightKnee", (0, 0, 0)), "LeftLowerLeg": ("LeftKnee", (0, 0, 0)),
        "Head": ("Neck", (0, .9, -.3))}


def tip_path(tr, part):
    joint, off = TIPS[part]
    pts, hips = [], []
    for k in range(length(tr)):
        P = fk(*frame(tr, k))
        pts.append(point(P, part, joint, off))
        hips.append(P["LowerTorso"].translation.copy())
    return pts, hips


def phases(tr, part, lo=0, hi=None):
    """(start, impact, settle, end) capture frames: the blow lands where the
    tip is furthest from the hips (inside lo..hi)."""
    pts, hips = tip_path(tr, part)
    n = len(pts)
    hi = n - 1 if hi is None else hi
    fps = tr.get("fps", 30)
    sp = [0] + [(pts[i] - pts[i - 1]).length * fps for i in range(1, n)]
    reach = [(p - h).length for p, h in zip(pts, hips)]
    impact = max(range(lo, hi + 1), key=lambda i: reach[i])
    a = max(lo, impact - 12)
    peak = max(range(a, impact + 1), key=lambda i: sp[i])
    start = peak
    while start > lo and sp[start - 1] > .12 * sp[peak]:
        start -= 1
    start = max(lo, start - 4)
    settle = impact
    while settle < hi and sp[settle + 1] > .12 * sp[peak]:
        settle += 1
    end = min(hi, settle + 8)
    return start, impact, max(settle, impact + 1), max(end, settle + 1)


def in_place(tr, keep=.5, keep_end=0.0):
    """The hips' horizontal travel of the capture: `keep` of it stays (the
    weight shift reads) and it comes back to keep_end of the final offset
    by the end."""
    n = length(tr)
    first = Vector((tr["loc"][0].x, 0, tr["loc"][0].z))
    lastv = Vector((tr["loc"][-1].x, 0, tr["loc"][-1].z))
    for k in range(n):
        u = k / max(1, n - 1)
        ramp = first.lerp(lastv, u)
        cur = Vector((tr["loc"][k].x, 0, tr["loc"][k].z))
        rel = (cur - ramp) * keep + (ramp - first) * keep_end
        tr["loc"][k] = Vector((rel.x, tr["loc"][k].y, rel.z))
    return tr


def base_height(tr, frames=3):
    ys = [tr["loc"][k].y for k in range(min(frames, length(tr)))]
    return sum(ys) / len(ys)


def strike(arm, key, part, length_s, contact, recover, hold=0, start_pose=None, end_pose=None, keep=.5, window=None,
           head=None, tail=None, air=False, settle_hold=0.0, pre=None):
    """A capture timed onto the game: wind-up -> contact (s), contact (held
    `hold` frames: the hit-stop) -> recover, recover -> end; the first and
    last frames melt into start_pose/end_pose."""
    tr = capture(key)
    lo, hi = window if window else (0, length(tr) - 1)
    s0, imp, st, e = phases(tr, part, lo, hi)
    if pre is not None:
        s0 = max(lo, s0 - pre)
    n_out = int(round(length_s * FPS)) + 1
    c = int(round(contact * FPS))
    r = int(round(recover * FPS))
    if hold:
        src = [s0, imp, imp + settle_hold, st, e]
        dst = [0, c, c + hold, r, n_out - 1]
    else:
        src = [s0, imp, st, e]
        dst = [0, c, r, n_out - 1]
    if not air:
        in_place(tr, keep)
    out = warp(tr, src, dst, n_out)
    out["src"] = (s0, imp, st, e)
    return out, c, r, n_out


def finish(arm, tr, name, contact=None, recover=None, start=None, end=None, head=.3, tail=.35, grounded=True,
           planted=True, travel=None, meta=None, extra_markers=None, head_n=None, tail_n=None, maxdeg=40, feet=None):
    if start is not None or end is not None:
        melt(tr, start, end, head, tail, head_n, tail_n)
    if grounded:
        ground(tr)
    limit(tr, maxdeg)
    marks = {}
    if contact is not None:
        marks["contact"] = contact / FPS
    if recover is not None:
        marks["recover"] = recover / FPS
    marks.update(extra_markers or {})
    return key_track(arm, tr, name, marks, travel=travel, planted=planted, meta=meta, feet=feet)


# ====================================================================== v0 port
def _flip_v0(arm):
    s = P5.s
    sh = Shot(arm, N + "Flip")
    sh.key(0, s(), "ease")
    sh.key(8, s({"root": {"y": -.9, "pitch": 30}}), "ease")
    sh.key(14, P5.air({"root": {"pitch": -180}}), "launch")
    sh.key(22, P5.air({"root": {"pitch": -340}}), "pass")
    sh.key(30, s({"root": {"y": -.9, "pitch": -340}}), "impact")
    sh.key(48, s({"root": {"pitch": -360 + P5.STANCE["root"]["pitch"]}}), "ease")
    return sh.build()


def old_clips(arm, names=None):
    """The key-posed sources (naruto_p5, gaps_e6, common_e9, clips_react2,
    jutsu_naruto) of the clips this pass replaces."""
    import common_e9, gaps_e6, clips_react2, jutsu_naruto
    have = set(bpy.data.actions)
    out = {}
    for a in P5.locomotion(arm):
        out[a.name] = a
    for fn in (P5.light1, P5.light2, P5.light3, P5.clone_kick, P5.clone_kick_strike, P5.heavy, P5.headbutt, P5.tackle,
               P5.uzumaki_kick, P5.uzumaki_rise, P5.launcher, P5.mirror_clone, P5.mirror_strike, P5.dash_attack, P5.rasengan,
               P5.air1, P5.air2, P5.air_drive, P5.air_spike, P5.air_switch, jutsu_naruto.light4, jutsu_naruto.light5):
        a = fn(arm)
        out[a.name] = a
    for a in gaps_e6.naruto(arm):
        out[a.name] = a
    for a in common_e9.author(arm, "Legion", P5.STANCE, P5.AIR, flip=True):
        out[a.name] = a
    for a in clips_react2.author(arm, "Legion", P5.STANCE, 1.05, 1.2, None):
        out[a.name] = a
    out[N + "Flip"] = _flip_v0(arm)
    keep = [out[N + n] for n in (names or NAMES)]
    for a in list(bpy.data.actions):
        if a not in have and a not in keep:
            bpy.data.actions.remove(a)
    return keep


# ====================================================================== moves
NEW = {}


def move(name):
    def deco(fn):
        NEW[name] = fn
        return fn
    return deco


def scrappy(tr, k=1.25, chest=6, w=None):
    """Naruto's carriage over a capture: more of every swing (torso, hips,
    arms: he overcommits), the shoulders thrown forward and the head down."""
    for j, f in (("Waist", k), ("Root", 1 + (k - 1) * .6), ("Right", 1 + (k - 1) * .8), ("Left", 1 + (k - 1) * .8),
                 ("Neck", .8)):
        nd_style.amp(tr, j, f)
    n = length(tr)
    ww = w or [1.0] * n
    offset_pose(tr, "Waist", turn(pitch=chest), ww)
    offset_pose(tr, "Neck", turn(pitch=-chest * .7), ww)
    return tr


def sink(tr, dy, keys):
    """The hips lower by dy over an envelope (knees bend: the IK feet stay)."""
    e = env(length(tr), keys)
    return lift(tr, [-dy * w for w in e])


@move("Light1")
def light1(arm):
    """L1, the right hook: half a step in with the shoulder's weight, the hips
    open first, the right shoulder follows and the bent arm swings round flat
    through the jaw; the head goes with it, the left fist stays up. Capture:
    hook (Mixamo), timed 5 / 11 of 20 frames, two frames held on the
    contact."""
    tr, c, r, n = strike(arm, "hook", "RightHand", .3333, 5 / 60, 11 / 60, hold=2, keep=.6)
    scrappy(tr, 1.3)
    st = stance(arm)
    return finish(arm, tr, N + "Light1", c, r, start=st, end=st, head_n=3, tail_n=8,
                  meta={"capture": "hook", "src": str(tr["src"])})


def author(arm):
    acts = {}
    for nm in NAMES:
        fn = NEW.get(nm)
        if fn:
            acts[nm] = fn(arm)
    rest = [nm for nm in NAMES if nm not in acts]
    if rest:
        for a in old_clips(arm, rest):
            acts[a.name[len(N):]] = a
    return [acts[nm] for nm in NAMES]
