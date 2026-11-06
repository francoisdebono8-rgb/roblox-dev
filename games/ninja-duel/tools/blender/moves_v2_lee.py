"""Rock Lee (Leaf) moveset pass v2 -- WORK IN PROGRESS (first save: the
current game clips ported exactly onto the control rig, then re-authored one
by one).

Every clip is first read back from the game (src/Client/Authored*.luau, the
Motor6D rows the engine plays) and rebuilt on the control rig (nd_ctrl), so
every name exists with its current length and markers.
"""
import bpy, os, re, glob, math, json
from mathutils import Matrix, Vector, Quaternion
import nd_rig, nd_ctrl, nd_anim
from nd_rig import JOINTS, B

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", "..", "src", "Client"))
N = "Leaf."
CLIPS = ["Leaf.Air1", "Leaf.Air2", "Leaf.AirDrive", "Leaf.AirFlip", "Leaf.AirSpike", "Leaf.AirSwitch", "Leaf.DashAttack",
         "Leaf.Flip", "Leaf.Grab", "Leaf.Guard.Impact", "Leaf.Heavy", "Leaf.HiddenLotus", "Leaf.Jump.Air", "Leaf.Jump.Leap",
         "Leaf.KneeStrike", "Leaf.Land", "Leaf.LeafHeel", "Leaf.LeafHurricane", "Leaf.LeafRising", "Leaf.LeafWhirlwind",
         "Leaf.Light1", "Leaf.Light2", "Leaf.Light3", "Leaf.Light4", "Leaf.Light5", "Leaf.Slam", "Leaf.Throw", "Leaf.ThrowUp"]
H = nd_rig.ROOT_HEIGHT
BT = B.transposed()


# ------------------------------------------------------------ game clips
_GAME = {}


def game_clips():
    """The Leaf clips the game plays now: {name: {fps, length, markers, rows}}."""
    if _GAME:
        return _GAME
    for path in sorted(glob.glob(os.path.join(GAME, "Authored*.luau"))):
        text = open(path).read()
        for m in re.finditer(r'\["(Leaf\.[A-Za-z0-9.]+)"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(\w+),markers=\{([^}]*)\}', text):
            name = m.group(1)
            if name not in CLIPS or name in _GAME:
                continue
            fps, frames, length = int(m.group(2)), int(m.group(3)), float(m.group(4))
            markers = {}
            for kv in m.group(6).split(","):
                if "=" in kv:
                    k, v = kv.split("=")
                    markers[k.strip()] = float(v)
            j0 = text.index("joints={", m.end()) + len("joints={")
            rows = {}
            pos = j0
            for _ in range(len(nd_rig.ORDER)):
                jm = re.compile(r'\s*(\w+)=\{([^}]*)\},?').match(text, pos)
                vals = [float(x) for x in jm.group(2).split(",")]
                w = 7 if jm.group(1) == "Root" else 4
                rows[jm.group(1)] = [vals[i:i + w] for i in range(0, len(vals), w)]
                pos = jm.end()
            _GAME[name] = {"fps": fps, "frames": frames, "length": length, "markers": markers, "rows": rows}
    return _GAME


def rows_track(clip):
    """Game rows -> a pose track (nd_mocap.track's format: local Quaternions
    per joint in Roblox frames, Root translation) at the clip's fps."""
    tr = {"q": {j: [] for j in nd_rig.ORDER}, "loc": [], "fps": clip["fps"]}
    for j in nd_rig.ORDER:
        for r in clip["rows"][j]:
            q = r[3:] if j == "Root" else r
            tr["q"][j].append(Quaternion((q[3], q[0], q[1], q[2])).normalized())
    for r in clip["rows"]["Root"]:
        tr["loc"].append(Vector(r[:3]))
    return tr


# ------------------------------------------------- track -> control rig
MOTOR_ORDER = nd_rig.ORDER
CENTRE = nd_ctrl.CENTRE
PART_OF = {"root": "HRP", "cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head",
           "shoulder.R": "RightUpperArm", "forearm.R": "RightLowerArm", "hand.R": "RightHand",
           "shoulder.L": "LeftUpperArm", "forearm.L": "LeftLowerArm", "hand.L": "LeftHand"}
FK = ["cog", "spine", "neck", "shoulder.R", "forearm.R", "hand.R", "shoulder.L", "forearm.L", "hand.L"]


def fk(q, loc):
    """Part CFrames (Roblox axes, floor y=0, HumanoidRootPart at (0, H, 0))
    of one frame of a track."""
    F = {"HRP": Matrix.Translation((0, H, 0))}
    for j in MOTOR_ORDER:
        p0, p1 = nd_ctrl.MOTORS[j]
        pivot = Vector(JOINTS[j][0])
        T = q[j].to_matrix().to_4x4()
        if j == "Root":
            T.translation = loc
        F[p1] = F[p0] @ Matrix.Translation(pivot - CENTRE[p0]) @ T @ Matrix.Translation(-(pivot - CENTRE[p1]))
    return F


def joint_pos(F, joint):
    """World (Roblox) position of a joint pivot."""
    p0, p1 = nd_ctrl.MOTORS[joint]
    return F[p1] @ (Vector(JOINTS[joint][0]) - CENTRE[p1])


def _arm_space(Frbx):
    m = Matrix.Identity(4)
    rot = B @ Frbx.to_3x3()
    for i in range(3):
        for k in range(3):
            m[i][k] = rot[i][k]
    m.translation = B @ Frbx.translation
    return m


def frame_world(tr):
    """Per frame: the part CFrames (the HumanoidRootPart carried by the
    track's travel, if any)."""
    out = []
    trav = tr.get("travel")
    for i in range(len(tr["loc"])):
        q = {j: tr["q"][j][i] for j in MOTOR_ORDER}
        F = fk(q, tr["loc"][i])
        if trav:
            T = Matrix.Translation((trav[i].x, 0, trav[i].z))
            F = {k: T @ v for k, v in F.items()}
        out.append(F)
    return out


def smooth(vals, r=2):
    out = []
    for i in range(len(vals)):
        w = vals[max(0, i - r):i + r + 1]
        out.append(sum(w, type(vals[0])() if not isinstance(vals[0], (int, float)) else 0.0) / len(w))
    return out


def to_action(arm, tr, name, markers=None, plant=True, ground=False, meta=None, speed=.075, low=.3, length=None):
    """Bakes a track on the control rig as action `name` (every track frame
    keyed; 60 fps frames). The legs go through the rig's IK: each foot's
    world pose is keyed on foot_ik and the knee aims at a pole in the leg's
    own bend plane. plant: a foot resting on the floor (its sole under `low`
    and moving less than `speed` studs a frame, 3 frames or more) is held at
    one spot for the whole contact, eased in and out of it (no skate by
    construction). ground: while a foot is down, the hips' height follows
    the lower foot so it touches the floor (smoothed)."""
    step = 60 // tr.get("fps", 30)
    n = len(tr["loc"])
    end = int(round(length * 60)) if length else (n - 1) * step
    Fs = frame_world(tr)
    if ground:
        corr = []
        for F in Fs:
            low_y = min((F[s + "Foot"] @ Vector((0, -.21, 0))).y for s in ("Right", "Left"))
            w = 1.0 if low_y < .45 else max(0.0, 1 - (low_y - .45) / .35)
            corr.append(-low_y * w)
        corr = smooth(corr, 2)
        for i in range(n):
            tr["loc"][i] = tr["loc"][i] + Vector((0, corr[i], 0))
        Fs = frame_world(tr)
    # feet: world matrices, then the planted runs locked
    feet = {}
    for side in ("Right", "Left"):
        mats = [F[side + "Foot"].copy() for F in Fs]
        if plant:
            soles = [(m @ Vector((0, -.21, 0))).y for m in mats]
            still = [i > 0 and (mats[i].translation - mats[i - 1].translation).xz.length < speed for i in range(n)]
            on = [soles[i] < low and (still[i] or (i + 1 < n and still[i + 1])) for i in range(n)]
            i = 0
            runs = []
            while i < n:
                if not on[i]:
                    i += 1
                    continue
                j = i
                while j + 1 < n and on[j + 1]:
                    j += 1
                if j - i >= 2:
                    runs.append((i, j))
                i = j + 1
            orig = [m.copy() for m in mats]
            for i, j in runs:
                # the spot: the clip's own first/last frame when the run
                # reaches it (strings chain exactly), else where the foot
                # is most firmly down
                k0 = 0 if i == 0 else (n - 1 if j == n - 1 else min(range(i, j + 1), key=lambda k: soles[k]))
                spot = orig[k0]
                for k in range(i, j + 1):
                    m = orig[k]
                    t = spot.translation.copy()
                    lift = soles[k] - soles[k0]
                    if lift > 0:
                        t.y += lift
                    mm = (spot.to_3x3() if abs(lift) < .05 else m.to_3x3()).to_4x4()
                    mm.translation = t
                    mats[k] = mm
                # eased out of / into the lock (the foot leaves the spot)
                for d in range(1, 5):
                    u = d / 5.0
                    for k, ref in ((j + d, j), (i - d, i)):
                        if 0 <= k < n and not any(a <= k <= b for a, b in runs):
                            t = mats[ref].translation.lerp(orig[k].translation, u)
                            mm = orig[k].to_3x3().to_4x4()
                            mm.translation = t
                            mats[k] = mm
        feet[side] = mats
    act = nd_anim.new_action(arm, name)
    pbs = arm.pose.bones
    bones = arm.data.bones
    last = {}
    for i in range(n):
        F = Fs[i]
        M = {"root": _arm_space(F["HRP"]) @ nd_ctrl.part_rest("HRP").inverted() @ bones["root"].matrix_local}
        for b in FK:
            M[b] = _arm_space(F[PART_OF[b]]) @ nd_ctrl.part_rest(PART_OF[b]).inverted() @ bones[b].matrix_local
        frame = min(i * step, end)
        for b in ["root"] + FK:
            bone = bones[b]
            if bone.parent:
                P = bone.parent
                basis = bone.matrix_local.inverted() @ P.matrix_local @ M[P.name].inverted() @ M[b]
            else:
                basis = bone.matrix_local.inverted() @ M[b]
            loc, rot, _ = basis.decompose()
            prev = last.get(b)
            if prev is not None and prev.dot(rot) < 0:
                rot = -rot
            last[b] = rot
            pb = pbs[b]
            pb.rotation_quaternion = rot
            pb.keyframe_insert("rotation_quaternion", frame=frame, group=b)
            if b in ("root", "cog"):
                pb.location = loc
                pb.keyframe_insert("location", frame=frame, group=b)
        for side, s in (("Right", "R"), ("Left", "L")):
            fm = _arm_space(feet[side][i]) @ nd_ctrl.part_rest(side + "Foot").inverted() @ bones["foot." + s].matrix_local
            ik = bones["foot_ik." + s]
            basis = ik.matrix_local.inverted() @ fm
            loc, rot, _ = basis.decompose()
            key = "foot_ik." + s
            prev = last.get(key)
            if prev is not None and prev.dot(rot) < 0:
                rot = -rot
            last[key] = rot
            pbs[key].rotation_quaternion = rot
            pbs[key].location = loc
            pbs[key].keyframe_insert("rotation_quaternion", frame=frame, group=key)
            pbs[key].keyframe_insert("location", frame=frame, group=key)
            # knee pole: in the bend plane (hip, knee, ankle) on the knee's
            # side; a straight leg aims along the thigh's own forward
            hip = joint_pos(F, side + "Hip")
            knee = joint_pos(F, side + "Knee")
            ankle = feet[side][i] @ (Vector(JOINTS[side + "Ankle"][0]) - CENTRE[side + "Foot"])
            axis = (ankle - hip)
            d = knee - (hip + ankle) * .5
            if axis.length > 1e-4:
                a = axis.normalized()
                d = d - a * d.dot(a)
            fwd = F[side + "UpperLeg"].to_3x3() @ Vector((0, 0, -1))
            if axis.length > 1e-4:
                fwd = fwd - axis.normalized() * fwd.dot(axis.normalized())
            bend = d.length
            w = min(1.0, bend / .25)
            dirv = (d.normalized() * w + fwd.normalized() * (1 - w)) if bend > 1e-5 else fwd.normalized()
            pole_rbx = (hip + ankle) * .5 + dirv.normalized() * 3.0
            pole = bones["knee_pole." + s]
            pbs["knee_pole." + s].location = pole.matrix_local.to_3x3().transposed() @ (B @ pole_rbx - pole.head_local)
            pbs["knee_pole." + s].keyframe_insert("location", frame=frame, group="knee_pole." + s)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = dict(markers or {})
    act["nd_loop"] = False
    act["nd_meta"] = dict(meta or {})
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, end)
    return act


def port(arm, name):
    """The clip as the game plays it now."""
    c = game_clips()[name]
    return to_action(arm, rows_track(c), name, c["markers"], plant=False, meta={"source": "game"}, length=c["length"])


# ------------------------------------------------------------- captures
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo"
CACHE = "/tmp/claude-0/-home-claude/60386c0c-0f7e-5237-92aa-0aedd11b1cac/scratchpad/moves/Leaf/cache"
_CAP = {}


def copy(tr):
    out = {"q": {j: [q.copy() for q in v] for j, v in tr["q"].items()}, "loc": [v.copy() for v in tr["loc"]],
           "fps": tr.get("fps", 30)}
    if "travel" in tr:
        out["travel"] = [v.copy() for v in tr["travel"]]
    return out


def capture(key):
    """A Mixamo capture on our joints (nd_mocap.track, place "full": the
    hips' travel kept, Roblox axes, 30 fps), cached as JSON."""
    if key in _CAP:
        return copy(_CAP[key])
    path = os.path.join(CACHE, key + ".json")
    if os.path.exists(path):
        d = json.load(open(path))
        tr = {"q": {j: [Quaternion(q) for q in v] for j, v in d["q"].items()}, "loc": [Vector(v) for v in d["loc"]], "fps": d["fps"]}
    else:
        import nd_mocap
        scene = bpy.context.scene
        keep = (scene.render.fps, scene.render.fps_base, scene.frame_start, scene.frame_end, scene.frame_current)
        before, acts, arms = set(bpy.data.objects), set(bpy.data.actions), set(bpy.data.armatures)
        active = bpy.context.view_layer.objects.active
        src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
        tr = nd_mocap.track(src, s0, s1, "full")
        for o in set(bpy.data.objects) - before:
            bpy.data.objects.remove(o, do_unlink=True)
        for a in set(bpy.data.actions) - acts:
            bpy.data.actions.remove(a)
        for a in set(bpy.data.armatures) - arms:
            if a.users == 0:
                bpy.data.armatures.remove(a)
        scene.render.fps, scene.render.fps_base, scene.frame_start, scene.frame_end = keep[:4]
        scene.frame_set(keep[4])
        bpy.context.view_layer.objects.active = active
        os.makedirs(CACHE, exist_ok=True)
        json.dump({"fps": tr.get("fps", 30), "q": {j: [list(q) for q in v] for j, v in tr["q"].items()},
                   "loc": [list(v) for v in tr["loc"]]}, open(path, "w"))
        tr = {"q": tr["q"], "loc": tr["loc"], "fps": tr.get("fps", 30)}
    _CAP[key] = tr
    return copy(tr)


TIP = {"RightHand": (0, -.25, 0), "LeftHand": (0, -.25, 0), "RightFoot": (0, -.1, -.45), "LeftFoot": (0, -.1, -.45),
       "RightLowerLeg": (0, .45, 0), "LeftLowerLeg": (0, .45, 0), "Head": (0, 0, 0), "LowerTorso": (0, 0, 0)}


def points(tr, part):
    """World positions (Roblox axes, the track's own travel) of a part's tip."""
    out = []
    for i in range(len(tr["loc"])):
        F = fk({j: tr["q"][j][i] for j in MOTOR_ORDER}, tr["loc"][i])
        out.append(F[part] @ Vector(TIP.get(part, (0, 0, 0))))
    return out


def sole(tr):
    """Per frame: height of the lower foot's sole above the floor."""
    out = []
    for i in range(len(tr["loc"])):
        F = fk({j: tr["q"][j][i] for j in MOTOR_ORDER}, tr["loc"][i])
        out.append(min((F[s + "Foot"] @ Vector((0, -.21, 0))).y for s in ("Right", "Left")))
    return out


# ===================================================================== author
# --------------------------------------------------------- the strike tools
def pose_at(name, frame=0):
    """One frame of a game clip as a pose {"q": {joint: Quaternion}, "loc"}."""
    tr = rows_track(game_clips()[name])
    k = frame if frame >= 0 else len(tr["loc"]) + frame
    return {"q": {j: tr["q"][j][k].copy() for j in MOTOR_ORDER}, "loc": tr["loc"][k].copy()}


def warp(tr, src, dst, n_out, ease=None):
    """Piecewise time warp: capture frames src[i] -> output frames dst[i]
    (60 fps). A repeated src frame holds that pose (the impact held: the
    hit-stop). ease: per segment, None (linear) or an exponent (>1: slow
    start, fast finish -- a wind-up that snaps; <1: fast start, slow
    finish -- a follow-through that settles)."""
    n = len(tr["loc"])
    out_q = {j: [] for j in tr["q"]}
    out_l = []
    for k in range(n_out):
        x = src[-1]
        for i in range(len(src) - 1):
            b0, b1 = dst[i], dst[i + 1]
            if b0 <= k <= b1:
                u = (k - b0) / max(b1 - b0, 1e-6)
                e = ease[i] if ease and i < len(ease) else None
                if e:
                    u = u ** e
                x = src[i] + (src[i + 1] - src[i]) * u
                break
        x = min(max(x, 0), n - 1)
        a = int(math.floor(x)); b = min(n - 1, a + 1); u = x - a
        for j, qs in tr["q"].items():
            qa, qb = qs[a], qs[b]
            if qa.dot(qb) < 0:
                qb = -qb
            out_q[j].append(qa.slerp(qb, u))
        out_l.append(tr["loc"][a].lerp(tr["loc"][b], u))
    tr["q"], tr["loc"] = out_q, out_l
    tr["fps"] = 60
    return tr


def split_travel(tr, k=1.0, r=4):
    """The hips' horizontal travel goes to the HumanoidRootPart (smoothed,
    from 0): planted feet stay planted in the world, and the game carries the
    body (the export is in place). k scales it (the feet are re-planted)."""
    base = Vector((tr["loc"][0].x, 0, tr["loc"][0].z))
    flat = [Vector((v.x, 0, v.z)) - base for v in tr["loc"]]
    sm = smooth(flat, r)
    sm = [v - sm[0] for v in sm]
    tr["travel"] = [v * k for v in sm]
    tr["loc"] = [Vector((v.x - base.x - t.x, v.y, v.z - base.z - t.z)) for v, t in zip(tr["loc"], sm)]
    return tr


def _sstep(x):
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def melt(tr, first, last, head, tail):
    """The first `head` and last `tail` frames turn into the poses `first`
    and `last` (the stance the string chains through)."""
    n = len(tr["loc"])
    for k in range(n):
        w0 = _sstep(1 - k / head) if first and head > 0 else 0.0
        w1 = _sstep(1 - (n - 1 - k) / tail) if last and tail > 0 else 0.0
        for j in MOTOR_ORDER:
            q = tr["q"][j][k]
            if w0 > 0:
                f = first["q"][j]
                q = q.slerp(f if q.dot(f) >= 0 else -f, w0)
            if w1 > 0:
                f = last["q"][j]
                q = q.slerp(f if q.dot(f) >= 0 else -f, w1)
            tr["q"][j][k] = q
        v = tr["loc"][k]
        if w0 > 0:
            v = v.lerp(first["loc"], w0)
        if w1 > 0:
            v = v.lerp(last["loc"], w1)
        tr["loc"][k] = v
    return tr


def env(n, pts):
    """A weight per frame from (frame, weight) points (linear, held at ends)."""
    pts = sorted(pts)
    out = []
    for k in range(n):
        if k <= pts[0][0]:
            out.append(pts[0][1]); continue
        if k >= pts[-1][0]:
            out.append(pts[-1][1]); continue
        for (a, wa), (b, wb) in zip(pts, pts[1:]):
            if a <= k <= b:
                out.append(wa + (wb - wa) * _sstep((k - a) / max(b - a, 1e-6)))
                break
    return out


def hold_pose(tr, joints, weights):
    """Each frame turns toward a held pose {joint: Quaternion} by weights[k]."""
    for j, q in joints.items():
        for k, w in enumerate(weights):
            a = tr["q"][j][k]
            if w > 0:
                tr["q"][j][k] = a.slerp(q if a.dot(q) >= 0 else -q, min(1.0, w))
    return tr


def add(tr, joint, q, weights):
    """An extra turn on a segment (in its parent's frame), by weights[k]."""
    for k, w in enumerate(weights):
        if w:
            d = Quaternion().slerp(q, w) if w <= 1 else _qpow(q, w)
            tr["q"][joint][k] = (d @ tr["q"][joint][k]).normalized()
    return tr


def _qpow(q, w):
    axis, ang = q.to_axis_angle()
    return Quaternion(axis, ang * w)


def local_add(tr, joint, q, weights):
    """An extra turn in the segment's own frame (after its rotation)."""
    for k, w in enumerate(weights):
        if w:
            d = Quaternion().slerp(q, w) if w <= 1 else _qpow(q, w)
            tr["q"][joint][k] = (tr["q"][joint][k] @ d).normalized()
    return tr


def amp(tr, joint, k, ref, weights=None):
    """More (k > 1) or less of a segment's motion away from a reference
    pose `ref` (a Quaternion), by weights[k] (1 by default)."""
    out = []
    for i, a in enumerate(tr["q"][joint]):
        w = 1.0 if weights is None else weights[i]
        d = ref.rotation_difference(a)
        axis, ang = d.to_axis_angle()
        if ang > math.pi:
            ang -= 2 * math.pi
        out.append((ref @ Quaternion(axis, ang * (1 + (k - 1) * w))).normalized())
    tr["q"][joint] = out
    return tr


def lift(tr, dy):
    """Hips height offsets per frame (a list)."""
    tr["loc"] = [v + Vector((0, d, 0)) for v, d in zip(tr["loc"], dy)]
    return tr


def R(x=0, y=0, z=0):
    return nd_anim.R(x, y, z).to_quaternion()


# Lee's carriage: the rear (right) hand folded behind the small of the back
# (the stance's own joints), the lead (left) palm out at the opponent.
REAR = {"Right": Quaternion((0.6215, -0.2483, 0.669, -0.3234)), "RightElbow": Quaternion((0.829, 0.5592, 0, 0)),
        "RightWrist": Quaternion()}


def phases(tr, part, near=None):
    """(start, impact, settle, end) capture frames of a blow: the impact is
    where `part` reaches furthest from the hips (near a given frame if
    `near`), the start and the settle where its speed falls under 15 % of
    the peak around it."""
    P = points(tr, part)
    hips = points(tr, "LowerTorso")
    n = len(P)
    sp = [0] + [(P[i] - P[i - 1]).length for i in range(1, n)]
    reach = [(p - h).length for p, h in zip(P, hips)]
    rng = range(n) if near is None else range(max(0, near - 4), min(n, near + 5))
    impact = max(rng, key=lambda i: reach[i])
    lo = max(0, impact - 12)
    peak = max(range(lo, impact + 1), key=lambda i: sp[i])
    start = peak
    while start > 0 and sp[start - 1] > .15 * sp[peak]:
        start -= 1
    settle = impact
    while settle < n - 1 and sp[settle + 1] > .15 * sp[peak]:
        settle += 1
    return max(0, start - 3), impact, max(settle, impact + 1), min(n - 1, max(settle, impact + 1) + 6)


def strike(arm, name, key, src=None, part=None, near=None, hold=0, ease=(1.6, .8, .7), travel=1.0, ground=True,
           first=None, last=None, head=None, tail=None, edit=None, air=False, meta=None):
    """A blow from a capture, timed on the game: the capture's wind-up ->
    contact -> recover -> end warped onto the clip's own length and markers
    (the impact held `hold` frames: the hit-stop), melted into the stance at
    both ends, then `edit(tr, c, r, n)` (Lee's own carriage and accents),
    then baked on the control rig with the feet planted."""
    g = game_clips()[name]
    length, mk = g["length"], dict(g["markers"])
    n = int(round(length * 60)) + 1
    tr = capture(key)
    if src is None:
        src = phases(tr, part, near)
    s0, imp, settle, e = src
    c = int(round(mk["contact"] * 60))
    r = int(round(mk["recover"] * 60))
    if hold:
        warp(tr, [s0, imp, imp, settle, e], [0, c, c + hold, r, n - 1], n, ease=(ease[0], None, ease[1], ease[2]))
    else:
        warp(tr, [s0, imp, settle, e], [0, c, r, n - 1], n, ease=ease)
    if air:
        tr["loc"] = [Vector((0, 0, 0)) for _ in tr["loc"]]
    else:
        split_travel(tr, travel)
    stance = pose_at("Leaf.Light1", 0) if not air else pose_at("Leaf.Air1", 0)
    first = stance if first is None else first
    last = stance if last is None else last
    melt(tr, first, last, head if head is not None else max(2, min(c * .8, n * .25)), tail if tail is not None else n * .3)
    if edit:
        edit(tr, c, r, n)
    m = {"capture": key, "src": list(src)}
    m.update(meta or {})
    return to_action(arm, tr, name, mk, plant=not air, ground=ground and not air, meta=m, length=length)


# ====================================================================== clips
def _stance_q(j):
    return pose_at("Leaf.Light1", 0)["q"][j]


def explode(tr, c, n, k=1.25, joints=("Root", "Waist")):
    """Lee's accent: more of the hips' and chest's own turn around the blow."""
    w = env(n, [(0, 0), (max(1, c - 3), 1), (c + 4, 1), (n - 1, 0)])
    for j in joints:
        amp(tr, j, k, _stance_q(j), w)


def rear_hand(tr, n, w=.85, pts=None):
    hold_pose(tr, REAR, env(n, pts or [(0, w), (n - 1, w)]))


def light1(arm):
    """Light1, the placement: the lead (left) hand shoots out open at the
    shoulder, the hips turning in behind it, the rear hand staying folded
    behind the back; it snaps back to the guard (jab)."""
    def edit(tr, c, r, n):
        rear_hand(tr, n, .9)
        explode(tr, c, n, 1.3)
        local_add(tr, "LeftWrist", R(-35, 0, 0), env(n, [(0, 0), (c - 1, 1), (r, 1), (n - 1, 0)]))
    return strike(arm, N + "Light1", "jab", part="LeftHand", hold=1, edit=edit)


def light2(arm):
    """Light2, the whip: the rear leg snaps round at the ribs off a pivot of
    the front foot, the hips turning over; the lead arm swings across to
    balance it, the rear hand stays behind the back."""
    def edit(tr, c, r, n):
        rear_hand(tr, n, .75)
        explode(tr, c, n, 1.2)
    return strike(arm, N + "Light2", "kick_roundhouse", part="RightFoot", hold=1, edit=edit)


def light3(arm):
    """Light3, the heel: the lead knee chambers high and the heel drives out
    at the chest, the hips turned side-on behind it, the body leaning away
    over the support leg."""
    def edit(tr, c, r, n):
        rear_hand(tr, n, .8)
        explode(tr, c, n, 1.15)
    return strike(arm, N + "Light3", "kick_side", part="LeftFoot", hold=2, edit=edit)


def light4(arm):
    """Light4, the flurry: three punches in a blink at the body, lead, rear,
    lead, the shoulders rolling behind each (Lee's hands are as fast as his
    feet)."""
    def edit(tr, c, r, n):
        explode(tr, c, n, 1.15)
    return strike(arm, N + "Light4", "quad_punch", src=(9, 15, 28, 36), ease=(1.5, 1.0, .7), edit=edit)


def light5(arm):
    """Light5, the straight: the rear hand comes out from behind the back
    for once, the hips square and drive it at the face; held on the contact,
    then it folds back behind him."""
    def edit(tr, c, r, n):
        explode(tr, c, n, 1.25)
    return strike(arm, N + "Light5", "cross", part="RightHand", hold=2, edit=edit)


def heavy(arm):
    """Heavy, the spinning back kick: he coils, turns his back, and the heel
    of the rear leg comes round last at head height, the whole body behind
    it; held on the contact, then a heavy landing of the kicking foot and
    the turn back into the stance."""
    def edit(tr, c, r, n):
        rear_hand(tr, n, .5, [(0, .9), (c - 4, .3), (c + 6, .3), (n - 1, .9)])
        explode(tr, c, n, 1.1)
    return strike(arm, N + "Heavy", "kick_spin_back", part="RightFoot", hold=3, travel=.5, edit=edit)


NEW = {"Light1": light1, "Light2": light2, "Light3": light3, "Light4": light4, "Light5": light5, "Heavy": heavy}
OLD = os.environ.get("LEE_OLD") == "1"     # review: the clips as the game plays them now


def author(arm):
    acts = []
    for name in CLIPS:
        fn = None if OLD else NEW.get(name[len(N):])
        act = None
        if fn:
            try:
                act = fn(arm)
            except Exception as e:
                import traceback
                traceback.print_exc()
                print("FALLBACK", name, e)
        acts.append(act or port(arm, name))
    return acts
