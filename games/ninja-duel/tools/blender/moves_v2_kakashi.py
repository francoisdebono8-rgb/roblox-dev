"""Kakashi (Copycat) moveset pass v2 (06/11) - v0 safety net: every clip name
exists, taken from the current key-posed authoring (kakashi_p6, gaps_e6,
common_e9, clips_react2, jutsu_kakashi) while the clips are re-authored one
by one below.
"""
import bpy, math, os, re, glob
from mathutils import Matrix, Vector, Quaternion
from nd_shot import Shot, merge
import nd_rig, nd_ctrl, nd_anim
import kakashi_p6 as K

N = "Copycat."
s, air = K.s, K.air
FPS = 60


# ===================================================== joints -> control rig
# A clip given as Motor6D transforms per frame (a capture track, or rows of
# an exported clip) is put on the control rig: every FK bone takes its
# segment's pose, each foot_ik the foot's (or a planted spot), each knee pole
# the knee's direction. The IK legs then reproduce the legs, and a planted
# foot cannot slide (the hips swing over it).
H = nd_rig.ROOT_HEIGHT
B3 = nd_rig.B
CENTRE = nd_ctrl.CENTRE
JOINTS = nd_rig.JOINTS
ORDER = nd_rig.ORDER
FK_BONES = (("cog", "LowerTorso"), ("spine", "UpperTorso"), ("neck", "Head"),
            ("shoulder.R", "RightUpperArm"), ("forearm.R", "RightLowerArm"), ("hand.R", "RightHand"),
            ("shoulder.L", "LeftUpperArm"), ("forearm.L", "LeftLowerArm"), ("hand.L", "LeftHand"))


def T_of(q, loc=None):
    m = q.to_matrix().to_4x4()
    if loc is not None:
        m.translation = Vector(loc)
    return m


def fk(T, travel=(0.0, 0.0)):
    """{joint: 4x4 Motor6D transform} -> {part: Roblox CFrame} (HRP on the floor)."""
    P = {"HRP": Matrix.Translation((travel[0], H, travel[1]))}
    for j in ORDER:
        p0, p1 = nd_ctrl.MOTORS[j]
        pv = Vector(JOINTS[j][0])
        P[p1] = P[p0] @ Matrix.Translation(pv - CENTRE[p0]) @ T[j] @ Matrix.Translation(CENTRE[p1] - pv)
    return P


def pivot(P, joint):
    """World (Roblox) position of a joint's pivot."""
    p1 = nd_ctrl.MOTORS[joint][1]
    return P[p1] @ (Vector(JOINTS[joint][0]) - CENTRE[p1])


def to_arm(M):
    out = Matrix.Identity(4)
    R = B3 @ M.to_3x3()
    for i in range(3):
        for k in range(3):
            out[i][k] = R[i][k]
    out.translation = B3 @ M.translation
    return out


def _basis(arm, bone, desired, poses):
    b = arm.data.bones[bone]
    if b.parent:
        par = poses[b.parent.name]
        return (par @ b.parent.matrix_local.inverted() @ b.matrix_local).inverted() @ desired
    return b.matrix_local.inverted() @ desired


def key_joints(arm, frame, T, travel=(0.0, 0.0), plant=None, last=None):
    """Keys the control rig at `frame` so that it shows the transforms T.
    plant: {"R"/"L": Roblox world (x, y, z) ankle spot} holds a foot there."""
    P = fk(T, travel)
    poses = {}
    rest_root = arm.data.bones["root"].matrix_local
    root = Matrix.Translation(B3 @ Vector((travel[0], 0, travel[1])))
    poses["root"] = rest_root @ root
    pb = arm.pose.bones["root"]
    pb.rotation_quaternion = Quaternion()
    pb.location = root.translation
    pb.keyframe_insert("rotation_quaternion", frame=frame, group="root")
    pb.keyframe_insert("location", frame=frame, group="root")
    for bone, part in FK_BONES:
        desired = to_arm(P[part]) @ nd_ctrl.part_rest(part).inverted() @ arm.data.bones[bone].matrix_local
        poses[bone] = desired
        bas = _basis(arm, bone, desired, poses)
        loc, q, _ = bas.decompose()
        pb = arm.pose.bones[bone]
        if last is not None:
            prev = last.get(bone)
            if prev is not None and prev.dot(q) < 0:
                q = -q
            last[bone] = q
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=bone)
        if bone == "cog":
            pb.location = loc
            pb.keyframe_insert("location", frame=frame, group=bone)
    for side, n in (("R", "Right"), ("L", "Left")):
        foot = to_arm(P[n + "Foot"]) @ nd_ctrl.part_rest(n + "Foot").inverted() @ arm.data.bones["foot." + side].matrix_local
        hip, knee, ankle = pivot(P, n + "Hip"), pivot(P, n + "Knee"), pivot(P, n + "Ankle")
        if plant and plant.get(side) is not None:
            ankle = Vector(plant[side])
            foot.translation = B3 @ ankle
        ik = "foot_ik." + side
        bas = _basis(arm, ik, foot, poses)
        loc, q, _ = bas.decompose()
        pb = arm.pose.bones[ik]
        if last is not None:
            prev = last.get(ik)
            if prev is not None and prev.dot(q) < 0:
                q = -q
            last[ik] = q
        pb.rotation_quaternion = q
        pb.location = loc
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=ik)
        pb.keyframe_insert("location", frame=frame, group=ik)
        # the knee's side of the hip-ankle line (or the thigh's front when straight)
        mid = (hip + ankle) * .5
        line = (ankle - hip)
        d = line.normalized() if line.length > 1e-4 else Vector((0, -1, 0))
        k = knee - mid
        perp = k - d * k.dot(d)
        if perp.length < .12:
            fwd = P[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1))
            perp = fwd - d * fwd.dot(d)
        pole_w = B3 @ (mid + perp.normalized() * 3.0)
        pole = arm.data.bones["knee_pole." + side]
        pb = arm.pose.bones["knee_pole." + side]
        pb.location = pole.matrix_local.to_3x3().transposed() @ (pole_w - pole.head_local)
        pb.keyframe_insert("location", frame=frame, group="knee_pole." + side)
    return P


def bake_rows(arm, name, frames_T, step=1, markers=None, travels=None, plants=None, meta=None):
    """A list of per-sample transforms -> a control-rig action (60 fps frames)."""
    act = nd_anim.new_action(arm, name)
    last = {}
    for i, T in enumerate(frames_T):
        key_joints(arm, i * step, T, travels[i] if travels else (0.0, 0.0), plants[i] if plants else None, last)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = markers or {}
    act["nd_loop"] = False
    act["nd_meta"] = meta or {}
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, (len(frames_T) - 1) * step)
    return act


def rows_T(joints, i):
    """Exported/luau rows (x,y,z,qx,qy,qz,qw for Root) -> transforms of sample i."""
    T = {}
    for j in ORDER:
        r = joints[j][i]
        if j == "Root":
            T[j] = T_of(Quaternion((r[6], r[3], r[4], r[5])), (r[0], r[1], r[2]))
        else:
            T[j] = T_of(Quaternion((r[3], r[0], r[1], r[2])))
    return T


GAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "src", "Client")


def game_clips(prefix="Copycat."):
    """The clips the game plays now (src/Client/Authored*.luau; later files win)."""
    files = sorted(glob.glob(os.path.join(GAME, "AuthoredClips*.luau"))) + sorted(glob.glob(os.path.join(GAME, "AuthoredJutsu*.luau")))
    out = {}
    head = re.compile(r'\["(%s[^"]+)"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(\w+),markers=\{([^}]*)\},meta=\{([^}]*)\},joints=\{' % re.escape(prefix))
    for path in files:
        txt = open(path).read()
        for m in head.finditer(txt):
            name = m.group(1)
            body = txt[m.end():txt.find("\n\t}", m.end())]
            joints = {}
            for jm in re.finditer(r"(\w+)=\{([^}]*)\}", body):
                vals = [float(v) for v in jm.group(2).split(",") if v.strip()]
                w = 7 if jm.group(1) == "Root" else 4
                joints[jm.group(1)] = [vals[k:k + w] for k in range(0, len(vals), w)]
            marks = {}
            for kv in m.group(6).split(","):
                if "=" in kv:
                    k, v = kv.split("=")
                    marks[k.strip()] = float(v)
            out[name] = {"fps": int(m.group(2)), "frames": int(m.group(3)), "length": float(m.group(4)), "markers": marks,
                         "joints": joints}
    return out


def replay(arm, name, clip):
    """An exported clip put back on the control rig (as the game plays it)."""
    step = FPS // clip["fps"]
    frames = [rows_T(clip["joints"], i) for i in range(clip["frames"])]
    return bake_rows(arm, name, frames, step, dict(clip["markers"]), meta={"source": "game"})


# ================================================================ captures
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo"
CACHE = os.environ.get("ND_CAPCACHE", "/tmp/claude-0/-home-claude/60386c0c-0f7e-5237-92aa-0aedd11b1cac/scratchpad/moves/Copycat/cache")
_caps = {}


def capture(key):
    """A Mixamo capture as a track on our skeleton: [{joint: 4x4}] at 30 fps
    (hips: height and travel kept, Roblox axes)."""
    if key in _caps:
        return _caps[key]
    import json
    path = os.path.join(CACHE, key + ".json")
    if os.path.exists(path):
        raw = json.load(open(path))
    else:
        import nd_mocap
        S = bpy.context.scene
        keep_fps = S.render.fps
        active = bpy.context.view_layer.objects.active
        before = set(bpy.data.objects)
        src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
        tr = nd_mocap.track(src, s0, s1, "full")
        for o in set(bpy.data.objects) - before:
            bpy.data.objects.remove(o, do_unlink=True)
        S.render.fps = keep_fps
        if active:
            bpy.context.view_layer.objects.active = active
        raw = {"q": {j: [list(q) for q in v] for j, v in tr["q"].items()}, "loc": [list(v) for v in tr["loc"]]}
        try:
            os.makedirs(CACHE, exist_ok=True)
            json.dump(raw, open(path, "w"))
        except OSError:
            pass
    n = len(raw["loc"])
    track = []
    for i in range(n):
        T = {}
        for j in ORDER:
            T[j] = T_of(Quaternion(raw["q"][j][i]), raw["loc"][i] if j == "Root" else None)
        track.append(T)
    _caps[key] = track
    return track


def _q(m):
    return m.to_quaternion().normalized()


def lerp_T(a, b, u):
    out = {}
    for j in ORDER:
        qa, qb = _q(a[j]), _q(b[j])
        if qa.dot(qb) < 0:
            qb = -qb
        out[j] = T_of(qa.slerp(qb, u), a[j].translation.lerp(b[j].translation, u) if j == "Root" else None)
    return out


def sample(track, x):
    x = min(max(x, 0.0), len(track) - 1.0)
    a = int(math.floor(x))
    b = min(len(track) - 1, a + 1)
    return lerp_T(track[a], track[b], x - a)


def warp(track, src, dst):
    """Piecewise-linear retiming: capture frames src[i] land on output frames
    dst[i] (60 fps). Two dst marks on one src frame hold it (hit-stop)."""
    out = []
    for f in range(int(dst[-1]) + 1):
        x = src[-1]
        for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
            if b0 <= f <= b1:
                x = a0 + (a1 - a0) * (f - b0) / max(b1 - b0, 1e-6)
                break
        out.append(sample(track, x))
    return out


TIPS = {"RightWrist": (0, -.6, 0), "LeftWrist": (0, -.6, 0), "RightAnkle": (0, -.3, -.6), "LeftAnkle": (0, -.3, -.6),
        "RightKnee": (0, -.5, 0), "LeftKnee": (0, -.5, 0)}


def tip(P, joint):
    p1 = nd_ctrl.MOTORS[joint][1]
    return P[p1] @ (Vector(JOINTS[joint][0]) - CENTRE[p1] + Vector(TIPS.get(joint, (0, 0, 0))))


def phases(track, limb):
    """(start, impact, settle, end) capture frames of the blow (job_mocap_strikes)."""
    pts, hips = [], []
    for T in track:
        T0 = dict(T)
        T0["Root"] = T_of(_q(T["Root"]), (0, T["Root"].translation.y, 0))
        P = fk(T0)
        pts.append(tip(P, limb))
        hips.append(P["LowerTorso"].translation)
    sp = [0] + [(pts[i] - pts[i - 1]).length * 30 for i in range(1, len(pts))]
    reach = [(p - h).length for p, h in zip(pts, hips)]
    impact = max(range(len(reach)), key=lambda i: reach[i])
    lo = max(0, impact - 12)
    peak = max(range(lo, impact + 1), key=lambda i: sp[i])
    start = peak
    while start > 0 and sp[start - 1] > .12 * sp[peak]:
        start -= 1
    start = max(0, start - 4)
    settle = impact
    while settle < len(sp) - 1 and sp[settle + 1] > .12 * sp[peak]:
        settle += 1
    end = min(len(sp) - 1, settle + 8)
    return start, impact, max(settle, impact + 1), max(end, settle + 1)


def spec_T(arm, spec):
    """A pose spec (nd_ctrl vocabulary) -> Motor6D transforms, through the rig."""
    ad = arm.animation_data
    keep = ad.action if ad else None
    if ad:
        ad.action = None
    pose = nd_ctrl.pose_bones(arm, spec)
    for bone, (q, loc) in pose.items():
        pb = arm.pose.bones[bone]
        pb.rotation_quaternion = q if q is not None else Quaternion()
        pb.location = loc if loc is not None else Vector()
    bpy.context.view_layer.update()
    T = nd_ctrl.retarget(arm)
    feet = {}
    P = nd_ctrl.part_frames(arm)
    for side, n in (("R", "Right"), ("L", "Left")):
        feet[side] = P[n + "Foot"] @ (Vector(JOINTS[n + "Ankle"][0]) - CENTRE[n + "Foot"])
    if ad:
        ad.action = keep
    return T, feet


def smooth(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


def melt(frames, first, last, head=.22, tail=.25):
    """The first and last frames turn into the given poses (smoothstep)."""
    n = len(frames)
    out = []
    for k, T in enumerate(frames):
        u = k / max(1, n - 1)
        w0 = smooth(1 - u / head) if u < head else 0.0
        w1 = smooth(1 - (1 - u) / tail) if u > 1 - tail else 0.0
        if w0 > 0:
            T = lerp_T(T, first, w0)
        if w1 > 0:
            T = lerp_T(T, last, w1)
        out.append(T)
    return out


def layer(frames, joints, keys):
    """A key-posed layer over a capture: joints {joint: Quaternion} (a pose to
    turn toward) with weight keys [(frame, w)] (smoothstep between)."""
    keys = sorted(keys)
    for f, T in enumerate(frames):
        w = keys[0][1] if f <= keys[0][0] else keys[-1][1]
        for (f0, w0), (f1, w1) in zip(keys, keys[1:]):
            if f0 <= f <= f1:
                w = w0 + (w1 - w0) * smooth((f - f0) / max(f1 - f0, 1e-6))
                break
        if w <= 0:
            continue
        for j, q in joints.items():
            a = _q(T[j])
            b = q if a.dot(q) >= 0 else -q
            T[j] = T_of(a.slerp(b, w), T[j].translation if j == "Root" else None)
    return frames


def offset(frames, joint, q, keys):
    """An added turn on one joint (in its parent's frame), weighted by keys."""
    keys = sorted(keys)
    for f, T in enumerate(frames):
        w = keys[0][1] if f <= keys[0][0] else keys[-1][1]
        for (f0, w0), (f1, w1) in zip(keys, keys[1:]):
            if f0 <= f <= f1:
                w = w0 + (w1 - w0) * smooth((f - f0) / max(f1 - f0, 1e-6))
                break
        if w == 0:
            continue
        qq = Quaternion().slerp(q, w) if w <= 1 else q.to_matrix().to_quaternion()
        T[joint] = T_of((qq @ _q(T[joint])).normalized(), T[joint].translation if joint == "Root" else None)
    return frames


def arm_q(side, spec):
    sh, el, wr = nd_anim.arm_rot(side, spec)
    n = "Right" if side == "R" else "Left"
    return {n: sh.to_quaternion(), n + "Elbow": el.to_quaternion(), n + "Wrist": wr.to_quaternion()}


def ori_q(**o):
    return nd_anim.ori(o).to_quaternion()


def ankles(T, travel=(0.0, 0.0)):
    P = fk(T, travel)
    return {"R": pivot(P, "RightAnkle"), "L": pivot(P, "LeftAnkle")}, P


def footwork(frames, plan, travels=None):
    """Feet on the floor from a plan, per foot a list of segments:
      ("plant", f0, f1, spot)  held at spot (Roblox world x, z) - None: where
                               the capture puts it at f0 (or f1 with "end")
      ("fk", f0, f1)           the capture's own leg (a kick, a free leg)
    Between two segments the foot steps (arc, lifted .25). Returns per-frame
    {side: world ankle or None}; the hips come down where a planted foot
    would be out of reach."""
    n = len(frames)
    travels = travels or [(0.0, 0.0)] * n
    fkpos = [ankles(T, tv)[0] for T, tv in zip(frames, travels)]
    floor = H - 2.6
    out = [dict() for _ in range(n)]
    for side, segs in plan.items():
        segs = sorted(segs, key=lambda s_: s_[1])
        spots = []
        for sg in segs:
            if sg[0] == "plant":
                spot = sg[3] if len(sg) > 3 else None
                if spot is None or spot == "start":
                    p = fkpos[sg[1]][side]
                    spot = (p.x, p.z)
                elif spot == "end":
                    p = fkpos[min(sg[2], n - 1)][side]
                    spot = (p.x, p.z)
                spots.append(Vector((spot[0], floor, spot[1])))
            else:
                spots.append(None)
        for i, sg in enumerate(segs):
            f0, f1 = sg[1], min(sg[2], n - 1)
            for f in range(f0, f1 + 1):
                out[f][side] = spots[i]
        # the gaps between segments: a step from one spot to the next
        for i in range(len(segs) - 1):
            a, b = segs[i], segs[i + 1]
            g0, g1 = a[2], b[1]
            if g1 - g0 < 1:
                continue
            for f in range(g0 + 1, g1):
                u = (f - g0) / (g1 - g0)
                pa = spots[i] if spots[i] is not None else fkpos[g0][side]
                pb = spots[i + 1] if spots[i + 1] is not None else fkpos[g1][side]
                p = pa.lerp(pb, smooth(u))
                if spots[i] is not None and spots[i + 1] is not None:
                    p = p + Vector((0, .25 * math.sin(math.pi * u), 0))
                out[f][side] = p
    # out of reach: the hips come down over the planted feet
    for f in range(n):
        T = frames[f]
        P = fk(T, travels[f])
        drop = 0.0
        for side, n_ in (("R", "Right"), ("L", "Left")):
            p = out[f].get(side)
            if p is None:
                continue
            hip = pivot(P, n_ + "Hip")
            reach = (nd_anim.L1 + nd_anim.L2) * .97
            d = p - hip
            horiz = math.hypot(d.x, d.z)
            if d.length > reach and horiz < reach:
                need = p.y + math.sqrt(reach * reach - horiz * horiz)
                drop = min(drop, need - hip.y)
        if drop < 0:
            r = T["Root"]
            frames[f] = dict(T)
            frames[f]["Root"] = T_of(_q(r), r.translation + Vector((0, drop, 0)))
    return out


def ground(frames, travels=None, keep_air=False):
    """The lower ankle on the floor: the hips' height follows the legs."""
    floor = H - 2.6
    for f, T in enumerate(frames):
        a, _ = ankles(T, travels[f] if travels else (0.0, 0.0))
        z = min(a["R"].y, a["L"].y)
        if keep_air and z > floor:
            continue
        r = T["Root"]
        T["Root"] = T_of(_q(r), r.translation + Vector((0, floor - z, 0)))
    return frames


def strip_travel(frames):
    """The capture's hips travel leaves the Root joint (returned as travel)."""
    travels = []
    x0, z0 = frames[0]["Root"].translation.x, frames[0]["Root"].translation.z
    for T in frames:
        t = T["Root"].translation
        travels.append((t.x - x0, t.z - z0))
        T["Root"] = T_of(_q(T["Root"]), (0, t.y, 0))
    return travels

NAMES = ["Air1", "Air2", "AirDrive", "AirFlip", "AirSpike", "AirSwitch", "Blade.AirSpike", "Blade.DashAttack",
         "Blade.FeintStep", "Blade.Heavy", "Blade.Launcher", "Blade.Slam", "Blade.Sweep", "FeintStep", "Flip", "Grab",
         "Guard.Impact", "Heavy", "Jump.Air", "Jump.Leap", "KneeStrike", "Land", "Launcher", "Light1", "Light2",
         "Light3", "Light4", "Slam", "Sweep", "ThrowUp"]


def jump_air(arm):
    sh = Shot(arm, N + "Jump.Air")
    take = air({"root": {"y": 0, "pitch": 2}, "ra": {"raise": 120, "out": 20, "elbow": 30}, "la": {"raise": 130, "out": 14, "elbow": 26},
                "rf": {"y": .1, "z": .2, "toe": -40}, "lf": {"y": .5, "z": -.4, "toe": -20}})
    sh.key(0, take, "ease")
    sh.key(8, air({"root": {"y": -.5}, "rf": {"y": 1.2, "z": -.3}, "lf": {"y": 1.1, "z": -.2}}), "ease")
    sh.key(16, air({"root": {"y": -.2}, "rf": {"y": .4, "z": -.1}, "lf": {"y": .5, "z": .1},
                    "ra": {"raise": 50, "out": 60, "elbow": 20}, "la": {"raise": 50, "out": 60, "elbow": 20}}), "ease")
    return sh.build()


def jump_leap(arm):
    sh = Shot(arm, N + "Jump.Leap")
    take = air({"root": {"y": -.1, "pitch": 20}, "torso": {"pitch": 14}, "ra": {"raise": -50, "out": 14, "elbow": 18},
                "la": {"raise": -50, "out": 14, "elbow": 18}, "rf": {"y": .9, "z": -.6, "toe": -20}, "lf": {"y": .3, "z": .9, "toe": -50}})
    sh.key(0, take, "ease")
    sh.key(14, air({"root": {"y": -.4, "pitch": 12}, "rf": {"y": 1.1, "z": -.5}, "lf": {"y": 1.0, "z": .1}}), "ease")
    sh.key(26, air({"root": {"y": -.2}, "rf": {"y": .4, "z": -.4}, "lf": {"y": .5, "z": .2},
                    "ra": {"raise": 30, "out": 50, "elbow": 20}, "la": {"raise": 30, "out": 50, "elbow": 20}}), "ease")
    return sh.build()


def land(arm):
    sh = Shot(arm, N + "Land")
    sh.key(0, s({"root": {"y": -.2}}), "ease")
    sh.key(4, s({"root": {"y": -1.2, "pitch": 24}, "torso": {"pitch": 18}, "ra": {"raise": 30, "out": 58}, "la": {"raise": 34, "out": 54}}), "impact")
    sh.key(12, s({"root": {"y": -.8, "pitch": 12}}), "ease")
    sh.key(28, s(), "ease")
    return sh.build()


def flip(arm):
    sh = Shot(arm, N + "Flip")
    sh.key(0, air(), "ease")
    tuck = air({"root": {"y": -.6}, "torso": {"pitch": 30}, "head": {"pitch": 24}, "rf": {"y": 1.7, "z": -.6}, "lf": {"y": 1.6, "z": -.5},
                "ra": {"raise": 78, "out": 10, "elbow": 112}, "la": {"raise": 76, "out": 10, "elbow": 116}})
    sh.key(12, tuck, "ease")
    sh.key(34, tuck, "ease")
    sh.key(48, air({"root": {"y": -.2}, "rf": {"y": .5}, "lf": {"y": .5}}), "ease")
    return sh.build()


def author(arm):
    import gaps_e6, common_e9, clips_react2, jutsu_kakashi
    acts = [K.light1(arm), K.light2(arm), K.light3(arm), K.heavy(arm), K.knee_strike(arm), K.launcher(arm), K.sweep(arm),
            K.feint_step(arm), K.air1(arm), K.air2(arm), K.air_drive(arm), K.air_spike(arm), K.air_switch(arm)]
    acts += gaps_e6.kakashi(arm)
    acts += [common_e9.grab(arm, N, K.STANCE), common_e9.throw_up(arm, N, K.STANCE), common_e9.air_flip(arm, N, K.AIR)]
    acts += [a for a in clips_react2.author(arm, "Copycat", K.STANCE, .9, 1.1) if a.name == N + "Guard.Impact"]
    acts.append(jutsu_kakashi.light4(arm))
    acts += [jump_air(arm), jump_leap(arm), land(arm), flip(arm)]
    want = {N + n for n in NAMES}
    out, seen = [], set()
    for a in acts:
        if a.name in want and a.name not in seen:
            out.append(a)
            seen.add(a.name)
    missing = want - seen
    if missing:
        print("MISSING", sorted(missing))
    return out


# ============================================================ clip builder
def stance_T(arm, spec=None):
    return spec_T(arm, spec or s())


def strike(arm, name, key, limb, length, contact, recover, hold=3, plan=None, travel=1.0, start=None, end=None,
           head=.22, tail=.3, src=None, air=False, shape=None, meta=None):
    """A captured blow timed on the game: the wind-up lands on `contact`, the
    impact pose is held `hold` frames (hit-stop), the follow-through ends on
    `recover`, then the recovery melts into the stance. shape(frames,
    travels) adds the fighter's own layers; plan is the footwork."""
    track = capture(key)
    st, im, se, en = src or phases(track, limb)
    n = int(round(length * FPS))
    if hold:
        frames = warp(track, [st, im, im, se, en], [0, contact, contact + hold, recover, n])
    else:
        frames = warp(track, [st, im, se, en], [0, contact, recover, n])
    travels = strip_travel(frames)
    travels = [(x * travel, z * travel) for x, z in travels]
    if air:
        for T in frames:
            T["Root"] = T_of(_q(T["Root"]), (0, 0, 0))
        travels = [(0.0, 0.0)] * len(frames)
    else:
        ground(frames, travels)
    T0, _ = stance_T(arm, start)
    T1, _ = stance_T(arm, end if end is not None else start)
    frames = melt(frames, T0, T1, head, tail)
    if shape:
        shape(frames, travels)
    plants = footwork(frames, plan(frames, travels), travels) if plan else None
    m = {"contact": contact / FPS, "recover": recover / FPS}
    act = bake_rows(arm, name, frames, 1, m, travels, plants, dict(meta or {}, capture=key, src=str((st, im, se, en))))
    return act


def feet_of(arm, spec=None):
    """Stance ankle spots (Roblox world x, z) of a spec."""
    _, f = stance_T(arm, spec)
    return {k: (v.x, v.z) for k, v in f.items()}


def planted(arm, n, steps=None, spec=None):
    """Footwork: both feet on their stance spots; steps {side: (f0, f1, dx, dz)}
    lift the foot at f0 and put it down at f1, moved by (dx, dz) and kept there
    (dx, dz relative to its stance spot)."""
    home = feet_of(arm, spec)

    def plan(frames, travels):
        out = {}
        for side in ("R", "L"):
            hx, hz = home[side]
            st = (steps or {}).get(side)
            if not st:
                out[side] = [("plant", 0, n, (hx, hz))]
                continue
            segs, at, cur = [], 0, (hx, hz)
            for f0, f1, dx, dz in (st if isinstance(st, list) else [st]):
                segs.append(("plant", at, f0, cur))
                cur = (hx + dx, hz + dz)
                at = f1
            segs.append(("plant", at, n, cur))
            out[side] = segs
        return out
    return plan
