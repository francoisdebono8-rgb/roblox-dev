"""Moveset pass v2: Itachi (Mirage) - strings, heavy blows, air attacks,
jumps and landings (06/11, user: « même les attaques que tu crois bonnes »).

Work in progress: every clip starts as the clip the game plays now (read
back from src/Client/AuthoredClips*.luau and replayed onto the control rig),
then each one is re-authored below.
"""
import bpy, os, re, math
from mathutils import Matrix, Vector, Quaternion
import nd_rig, nd_ctrl, nd_anim, nd_shot

HERE = os.path.dirname(os.path.abspath(__file__))
CLIENT = os.path.normpath(os.path.join(HERE, "..", "..", "src", "Client"))
N = "Mirage."
FPS = 60

# clip -> the generated Luau module that holds the version the game plays now
CURRENT = {
    "Air1": "AuthoredClips34", "Air2": "AuthoredClips34", "AirDrive": "AuthoredClips34", "AirFlip": "AuthoredClips34",
    "AirSpike": "AuthoredClips34", "AirSwitch": "AuthoredClips34", "CounterPalm": "AuthoredClips34",
    "DashAttack": "AuthoredClips34", "FeintStep": "AuthoredClips35", "Flip": "AuthoredClips35", "Grab": "AuthoredClips35",
    "Guard.Impact": "AuthoredClips35", "Heavy": "AuthoredClips36", "Jump.Air": "AuthoredClips37",
    "Jump.Leap": "AuthoredClips37", "Land": "AuthoredClips37", "Launcher": "AuthoredClips37", "Light1": "AuthoredClips37",
    "Light2": "AuthoredClips37", "Light3": "AuthoredClips37", "Light4": "AuthoredJutsu4",
    "PhoenixFlower.Channel": "AuthoredClips38", "PhoenixFlower.Recover": "AuthoredClips38",
    "PhoenixFlower.Release": "AuthoredClips38", "Slam": "AuthoredClips38", "Sweep": "AuthoredClips38",
    "ThrowUp": "AuthoredClips38",
}
ORDER = list(nd_ctrl.MOTORS.keys())


# ================================================================ Luau rows
_cache = {}


def _luau_text(module):
    if module not in _cache:
        with open(os.path.join(CLIENT, module + ".luau")) as fh:
            _cache[module] = fh.read()
    return _cache[module]


def load_current(slot):
    """The clip the game plays now: {fps, frames, length, loop, markers, joints}."""
    name = N + slot
    text = _luau_text(CURRENT[slot])
    i = text.index('["%s"]=' % name)
    j = text.index("}},", i)
    block = text[i:j + 2]
    head = re.match(r'\["[^"]+"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(\w+),markers=\{([^}]*)\}', block)
    fps, frames, length, loop, marks = head.groups()
    markers = {}
    for kv in marks.split(","):
        if "=" in kv:
            k, v = kv.split("=")
            markers[k.strip()] = float(v)
    joints = {}
    for m in re.finditer(r"(\w+)=\{([-\d.,e]+)\}", block[block.index("joints={"):]):
        vals = [float(x) for x in m.group(2).split(",") if x]
        w = 7 if m.group(1) == "Root" else 4
        joints[m.group(1)] = [vals[k:k + w] for k in range(0, len(vals), w)]
    return {"fps": int(fps), "frames": int(frames), "length": float(length), "loop": loop == "true",
            "markers": markers, "joints": joints}


def row_T(row):
    """A Motor6D row -> 4x4 transform (Roblox axes)."""
    if len(row) == 7:
        x, y, z, qx, qy, qz, qw = row
    else:
        x = y = z = 0.0
        qx, qy, qz, qw = row
    m = Quaternion((qw, qx, qy, qz)).normalized().to_matrix().to_4x4()
    m.translation = Vector((x, y, z))
    return m


# ===================================================== rows -> control rig
CARRIED = {"cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head"}
for _s, _n in (("R", "Right"), ("L", "Left")):
    CARRIED["shoulder." + _s] = _n + "UpperArm"
    CARRIED["forearm." + _s] = _n + "LowerArm"
    CARRIED["hand." + _s] = _n + "Hand"
    CARRIED["thigh." + _s] = _n + "UpperLeg"
    CARRIED["shin." + _s] = _n + "LowerLeg"
    CARRIED["foot." + _s] = _n + "Foot"
B4 = Matrix(nd_rig.B).to_4x4()
HRP0 = None


def _from_roblox(F):
    """Roblox CFrame (world) -> armature-space matrix (inverse of nd_ctrl._to_roblox)."""
    out = Matrix.Identity(4)
    out.translation = nd_rig.B @ F.translation
    rot = nd_rig.B @ F.to_3x3()
    for i in range(3):
        for j in range(3):
            out[i][j] = rot[i][j]
    return out


def part_world(T):
    """Motor6D transforms {joint: 4x4} -> part CFrames (Roblox world), the
    HumanoidRootPart where the control rig's root puts it."""
    global HRP0
    if HRP0 is None:
        HRP0 = nd_ctrl._to_roblox(nd_ctrl.part_rest("HRP"))
    F = {"HRP": HRP0}
    for joint in ORDER:
        p0, p1 = nd_ctrl.MOTORS[joint]
        pivot = Vector(nd_rig.JOINTS[joint][0])
        c0 = Matrix.Translation(pivot - nd_ctrl.CENTRE[p0])
        c1 = Matrix.Translation(pivot - nd_ctrl.CENTRE[p1])
        F[p1] = F[p0] @ c0 @ T[joint] @ c1.inverted()
    return F


def bone_targets(arm, F):
    """Armature-space matrices the control bones must take to carry the parts
    (plus "fwd.R"/"fwd.L": the knee's forward, armature space)."""
    out = {}
    for s, n in (("R", "Right"), ("L", "Left")):
        out["fwd." + s] = (nd_rig.B @ (F[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1)) + F[n + "LowerLeg"].to_3x3() @ Vector((0, 0, -1)))).normalized()
    for bone, part in CARRIED.items():
        out[bone] = _from_roblox(F[part]) @ nd_ctrl.part_rest(part).inverted() @ arm.data.bones[bone].matrix_local
    return out


def basis_from(arm, M):
    """Desired armature-space pose matrices -> {bone: (quat, loc)} bases."""
    bones = arm.data.bones
    out = {}
    out["root"] = (Quaternion(), Vector())
    Mroot = bones["root"].matrix_local.copy()
    M = dict(M)
    M["root"] = Mroot
    for b in ("cog", "spine", "neck", "shoulder.R", "forearm.R", "hand.R", "shoulder.L", "forearm.L", "hand.L"):
        par = bones[b].parent.name
        rel = bones[par].matrix_local.inverted() @ bones[b].matrix_local
        basis = (M[par] @ rel).inverted() @ M[b]
        out[b] = (basis.to_quaternion().normalized(), basis.translation.copy() if b == "cog" else None)
    for s in ("R", "L"):
        ik = bones["foot_ik." + s]
        basis = ik.matrix_local.inverted() @ M["foot." + s]
        out["foot_ik." + s] = (basis.to_quaternion().normalized(), basis.translation.copy())
        hip = M["thigh." + s].translation
        knee = M["shin." + s].translation
        ankle = M["foot." + s].translation
        # the knee's bend points along the thigh's and shin's forward (-Z of
        # their parts), from the knee: never on the leg's own line
        fwd = M["fwd." + s]
        d = fwd.copy()
        leg = (ankle - hip)
        if leg.length > 1e-4:
            u = leg.normalized()
            d = (d - u * d.dot(u))
            d = d.normalized() if d.length > 1e-4 else fwd
        pole_world = (hip + ankle) * .5 + d * 3.0
        pole = bones["knee_pole." + s]
        out["knee_pole." + s] = (None, pole.matrix_local.to_3x3().transposed() @ (pole_world - pole.head_local))
    return out


def key_pose(arm, frame, pose, last_q):
    for bone, (q, loc) in pose.items():
        pb = arm.pose.bones[bone]
        if q is not None:
            prev = last_q.get(bone)
            if prev is not None and prev.dot(q) < 0:
                q = -q
            last_q[bone] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=frame, group=bone)
        if loc is not None:
            pb.location = loc
            pb.keyframe_insert("location", frame=frame, group=bone)


def bake_frames(arm, name, frames_T, step, markers=None, meta=None, loop=False):
    """[{joint: 4x4}] per sample (every `step` frames at 60 fps) -> a control-rig action."""
    act = nd_anim.new_action(arm, name)
    last_q = {}
    for i, T in enumerate(frames_T):
        key_pose(arm, i * step, basis_from(arm, bone_targets(arm, part_world(T))), last_q)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = dict(markers or {})
    act["nd_loop"] = bool(loop)
    act["nd_meta"] = dict(meta or {})
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, (len(frames_T) - 1) * step)
    return act


def rows_frames(clip):
    n = clip["frames"]
    return [{j: row_T(clip["joints"][j][i]) for j in ORDER} for i in range(n)]


def port(arm, slot):
    """The clip the game plays now, unchanged, on the control rig."""
    clip = load_current(slot)
    step = FPS // clip["fps"]
    return bake_frames(arm, N + slot, rows_frames(clip), step, clip["markers"], {"source": "v1"}, clip["loop"])


SLOTS = ["Light1", "Light2", "Light3", "Light4", "Heavy", "Launcher", "Slam", "Sweep", "DashAttack",
         "Air1", "Air2", "AirDrive", "AirFlip", "AirSpike", "AirSwitch", "CounterPalm", "FeintStep",
         "Grab", "ThrowUp", "Guard.Impact", "Flip", "Jump.Leap", "Jump.Air", "Land",
         "PhoenixFlower.Channel", "PhoenixFlower.Release", "PhoenixFlower.Recover"]
AUTHORED = {}   # slot -> function(arm) -> action (the re-authored clips)


def author(arm, only=None):
    acts = []
    for slot in SLOTS:
        if only and slot not in only:
            continue
        fn = AUTHORED.get(slot)
        acts.append(fn(arm) if fn else port(arm, slot))
    return acts


def old(arm):
    """The current clips, as the game plays them (review: old vs new)."""
    return [port(arm, slot) for slot in SLOTS]
