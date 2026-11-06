"""Kakashi (Copycat) jutsu pass v2 - WORK IN PROGRESS (the current clips are
ported so every clip name exists; each jutsu is then re-authored in place)."""
import bpy, math, os
from mathutils import Quaternion, Vector
import nd_anim, nd_ctrl, nd_mocap, nd_rig
import kakashi_p6, jutsu_kakashi, common_e9
from kakashi_p6 import STANCE
from jutsu_sasuke import ZERO, SEAL, stance_fn, weave, seal, act
from nd_shot import Shot, merge, POSE_BONES

N = "Copycat."
s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]


# ====================================================== capture -> control rig
# nd_mocap bakes a capture on the DEFORM rig; the jutsu are authored on the
# CONTROL rig (nd_ctrl: IK feet in the world). layer() lays a capture's upper
# body and hips over a key-posed timeline: the timeline keeps the feet
# (planted where the stance has them, the IK legs follow the captured hips),
# the travel and the overall shape; the capture brings the weight shift, the
# order hips -> shoulder -> hand and the real timing of the throw or push.
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo/mixamo_%s.fbx"
CTRL = {"Root": "cog", "Waist": "spine", "Neck": "neck",
        "Right": "shoulder.R", "RightElbow": "forearm.R", "RightWrist": "hand.R",
        "Left": "shoulder.L", "LeftElbow": "forearm.L", "LeftWrist": "hand.L"}
UPPER_R = ("Right", "RightElbow", "RightWrist")
UPPER_L = ("Left", "LeftElbow", "LeftWrist")
_CAPS = {}


def capture(name, mirror=False):
    """A Mixamo capture as a pose track (nd_mocap.track, place 'full'),
    mirrored left<->right when asked (a right-handed throw for the free left
    hand). Cached per process."""
    if name not in _CAPS:
        scene = bpy.context.scene
        fps, frame = scene.render.fps, scene.frame_current
        before = set(bpy.data.objects)
        src, a, b, _ = nd_mocap.import_fbx(MIXAMO % name)
        tr = nd_mocap.track(src, a, b, place="full")
        for o in set(bpy.data.objects) - before:
            data = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if data is not None and getattr(data, "users", 1) == 0 and isinstance(data, bpy.types.Armature):
                bpy.data.armatures.remove(data)
        scene.render.fps = fps
        scene.frame_set(frame)
        _CAPS[name] = tr
    tr = _CAPS[name]
    out = {"q": {j: [q.copy() for q in v] for j, v in tr["q"].items()}, "loc": [v.copy() for v in tr["loc"]], "fps": 30}
    if mirror:
        swap = {}
        for j in out["q"]:
            m = j.replace("Right", "#").replace("Left", "Right").replace("#", "Left")
            swap[m] = [Quaternion((q.w, q.x, -q.y, -q.z)) for q in out["q"][j]]
        out["q"] = swap
        out["loc"] = [Vector((-v.x, v.y, v.z)) for v in out["loc"]]
    return out


def sample_track(tr, x):
    """The track at (fractional) capture frame x: {joint: Quaternion}, loc."""
    n = len(tr["loc"])
    x = min(max(x, 0.0), n - 1.0)
    a = int(math.floor(x)); b = min(n - 1, a + 1); u = x - a
    q = {}
    for j, qs in tr["q"].items():
        qa, qb = qs[a], qs[b]
        if qa.dot(qb) < 0:
            qb = -qb
        q[j] = qa.slerp(qb, u).normalized()
    return q, tr["loc"][a].lerp(tr["loc"][b], u)


def warp_fn(src_marks, dst_marks):
    """Piecewise-linear map output frame -> capture frame (smoothstepped
    inside each piece so the capture's own speed changes are kept but no
    piece starts or stops with a kink)."""
    def f(t):
        for (a0, a1), (b0, b1) in zip(zip(src_marks, src_marks[1:]), zip(dst_marks, dst_marks[1:])):
            if b0 <= t <= b1:
                return a0 + (a1 - a0) * (t - b0) / max(b1 - b0, 1e-6)
        return src_marks[0] if t < dst_marks[0] else src_marks[-1]
    return f


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def envelope(start, end, fade_in, fade_out):
    """Weight 0 at start -> 1 after fade_in frames ... 1 -> 0 over the last fade_out."""
    def w(f):
        a = smooth((f - start) / fade_in) if fade_in > 0 else 1.0
        b = smooth((end - f) / fade_out) if fade_out > 0 else 1.0
        return min(a, b)
    return w


def layer(arm, base, tr, timemap, weights, hips=None, delta=("Root",), yaw=0.0, step=1):
    """Rewrites action `base` (built with Shot) frame by frame: every control
    bone keeps the timeline's value, the captured joints in `weights`
    ({joint: w(frame) -> 0..1}) turn toward the capture. `delta` joints take
    the capture's motion relative to its first mapped frame on top of the
    timeline's own rotation (the hips: our stance's facing, the capture's
    weight shift); the others take the capture's absolute rotation (the arm
    shapes of the throw). hips: (w(frame), gain_xyz) the hips' captured
    displacement (relative to the first mapped frame) added to the cog."""
    nd_anim.use(arm, base)
    scene = bpy.context.scene
    start, end = int(base.frame_range[0]), int(base.frame_range[1])
    frames = list(range(start, end + 1, step))
    if frames[-1] != end:
        frames.append(end)
    q0, loc0 = sample_track(tr, timemap(start))
    yawq = nd_anim.R(0, -yaw, 0).to_quaternion()
    rows = []
    for f in frames:
        scene.frame_set(f)
        row = {}
        for b in POSE_BONES:
            pb = arm.pose.bones[b]
            row[b] = (pb.rotation_quaternion.copy(), pb.location.copy())
        q, loc = sample_track(tr, timemap(f))
        for j, wfn in weights.items():
            w = wfn(f)
            if w <= 0:
                continue
            bone = CTRL[j]
            if j in delta:
                d = q[j] @ q0[j].inverted()
                tgt_rbx = (yawq @ d @ yawq.inverted())
                # the timeline's own joint rotation in Roblox axes
                rest = arm.data.bones[bone].matrix_local.to_3x3()
                cur_rbx = (nd_rig.B.transposed() @ (rest @ row[bone][0].to_matrix() @ rest.transposed()) @ nd_rig.B).to_quaternion()
                capq = nd_ctrl.local_rot(arm, bone, (tgt_rbx @ cur_rbx).to_matrix())
            else:
                capq = nd_ctrl.local_rot(arm, bone, (yawq @ q[j]).to_matrix() if j == "Root" else q[j].to_matrix())
            bq = row[bone][0]
            if bq.dot(capq) < 0:
                capq = -capq
            row[bone] = (bq.slerp(capq, w), row[bone][1])
        if hips:
            wfn, gain = hips
            w = wfn(f)
            if w > 0:
                dl = loc - loc0
                dl = yawq.to_matrix() @ Vector((dl.x * gain[0], dl.y * gain[1], dl.z * gain[2]))
                add = arm.data.bones["cog"].matrix_local.to_3x3().transposed() @ nd_rig.rb(dl)
                row["cog"] = (row["cog"][0], row["cog"][1] + add * w)
        rows.append((f, row))
    markers = dict(base.get("nd_markers", {}))
    loop, meta = base.get("nd_loop", False), dict(base.get("nd_meta", {}))
    name = base.name
    act_ = nd_anim.new_action(arm, name)
    last = {}
    for f, row in rows:
        for b in POSE_BONES:
            q, l = row[b]
            p = last.get(b)
            if p is not None and p.dot(q) < 0:
                q = -q
            last[b] = q
            pb = arm.pose.bones[b]
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f, group=b)
            pb.location = l
            pb.keyframe_insert("location", frame=f, group=b)
    for fc in nd_anim.fcurves(act_):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR" if step == 1 else "BEZIER"
            if step != 1:
                kp.handle_left_type = kp.handle_right_type = "AUTO_CLAMPED"
        fc.update()
    act_["nd_markers"] = markers
    act_["nd_loop"] = loop
    m = {"capture": tr.get("name", "")}
    m.update(meta)
    act_["nd_meta"] = m
    act_["nd_rig"] = "ctrl"
    act_.frame_range = (start, end)
    return act_


# ================================================================== author
def author(arm):
    acts = []
    acts += kakashi_p6.lightning_blade(arm)
    acts += kakashi_p6.tracking_fang(arm)
    acts += kakashi_p6.water_dragon(arm)
    acts.append(kakashi_p6.dash_attack(arm))
    acts.append(kakashi_p6.throw_kunai(arm))
    acts.append(kakashi_p6.awaken(arm))
    acts += jutsu_kakashi.earth_wall(arm)
    acts += jutsu_kakashi.headhunter(arm)
    acts += jutsu_kakashi.earth_dragon(arm)
    acts += jutsu_kakashi.sabre(arm)
    acts.append(common_e9.throw(arm, "Copycat.", merge(ZERO, STANCE)))
    return acts
