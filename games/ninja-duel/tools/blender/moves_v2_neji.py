"""Moveset pass v2 (06/11): Neji (GentleFist) - every strike, air attack,
jump and landing. v0: the current clips ported (neji_p9, jutsu_neji.light4,
gaps_e6 slam, common_e9 grab/throw/flip) so every clip name exists; reworked
clip by clip below.
"""
import math, re, os
from mathutils import Matrix, Vector, Quaternion
import bpy
import nd_rig, nd_ctrl, nd_anim
from nd_shot import Shot, merge
import neji_p9, jutsu_neji, gaps_e6, common_e9

N = "GentleFist."
S = neji_p9.s
AIR = neji_p9.AIR
HERE = os.path.dirname(os.path.abspath(__file__))


# ======================================================== rows -> control rig
# A joint track (Motor6D rotations, Roblox axes: a capture from nd_mocap.track
# or a clip already in the game) put onto the control rig: the FK bones take
# the parts' rotations, the feet go to foot_ik (world), the knees to their
# poles, so the clip is posed exactly like an authored one (and the feet can
# then be planted on the floor).
H = nd_rig.ROOT_HEIGHT
CENTRE = nd_ctrl.CENTRE
CARRIED = {"cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head",
           "shoulder.R": "RightUpperArm", "forearm.R": "RightLowerArm", "hand.R": "RightHand",
           "shoulder.L": "LeftUpperArm", "forearm.L": "LeftLowerArm", "hand.L": "LeftHand",
           "foot_ik.R": "RightFoot", "foot_ik.L": "LeftFoot"}
FK_ORDER = ["cog", "spine", "neck", "shoulder.R", "forearm.R", "hand.R", "shoulder.L", "forearm.L", "hand.L"]


def body_frames(q, root_t):
    """Part CFrames (Roblox axes, floor y=0) of one frame of joint rotations."""
    parts = {"HRP": Matrix.Translation((0, H, 0))}
    for j in nd_rig.ORDER:
        p0, p1 = nd_ctrl.MOTORS[j]
        piv = Vector(nd_rig.JOINTS[j][0])
        T = q[j].to_matrix().to_4x4()
        if j == "Root":
            T.translation = Vector(root_t)
        parts[p1] = parts[p0] @ Matrix.Translation(piv - CENTRE[p0]) @ T @ Matrix.Translation(CENTRE[p1] - piv)
    return parts


def to_arm(m):
    out = (nd_rig.B @ m.to_3x3()).to_4x4()
    out.translation = nd_rig.B @ m.translation
    return out


def joint_world(parts, part, joint):
    return parts[part] @ (Vector(nd_rig.JOINTS[joint][0]) - CENTRE[part])


def ctrl_pose(arm, parts):
    """Control-bone (rotation, location) bases reproducing these parts."""
    bones = arm.data.bones
    D = {"root": bones["root"].matrix_local.copy()}
    for b, part in CARRIED.items():
        D[b] = to_arm(parts[part]) @ nd_ctrl.part_rest(part).inverted() @ bones[b].matrix_local
    out = {}
    for b in ["root"] + FK_ORDER + ["foot_ik.R", "foot_ik.L"]:
        rest = bones[b].matrix_local
        par = bones[b].parent
        if par is None:
            basis = rest.inverted() @ D[b]
        else:
            basis = rest.inverted() @ par.matrix_local @ D[par.name].inverted() @ D[b]
        loc, rot, _ = basis.decompose()
        out[b] = (rot, loc)
    for side, n in (("R", "Right"), ("L", "Left")):
        hip = joint_world(parts, n + "UpperLeg", n + "Hip")
        knee = joint_world(parts, n + "LowerLeg", n + "Knee")
        ank = joint_world(parts, n + "Foot", n + "Ankle")
        axis = (ank - hip)
        d = knee - (hip + axis * (max(0.0, (knee - hip).dot(axis)) / max(axis.length_squared, 1e-6)))
        if d.length < .04:
            d = parts[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1))
        pole = knee + d.normalized() * 3.0
        rest = bones["knee_pole." + side].matrix_local
        Dp = rest.copy()
        Dp.translation = nd_rig.B @ pole
        loc, rot, _ = (rest.inverted() @ Dp).decompose()
        out["knee_pole." + side] = (None, loc)
    return out


LOC_BONES = ("root", "cog", "foot_ik.R", "foot_ik.L", "knee_pole.R", "knee_pole.L")


def key_frames(arm, name, frames, step=1, markers=None, loop=False, meta=None, end=None):
    """frames: list of {bone: (quat or None, loc or None)} -> an action."""
    act = nd_anim.new_action(arm, name)
    last = {}
    end = (len(frames) - 1) * step if end is None else end
    for i, pose in enumerate(frames):
        f = min(i * step, end)
        for b, (q, loc) in pose.items():
            pb = arm.pose.bones[b]
            if q is not None:
                p = last.get(b)
                if p is not None and p.dot(q) < 0:
                    q = -q
                last[b] = q
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=f, group=b)
            if loc is not None and b in LOC_BONES:
                pb.location = loc
                pb.keyframe_insert("location", frame=f, group=b)
    act["nd_markers"] = markers or {}
    act["nd_loop"] = bool(loop)
    act["nd_meta"] = meta or {}
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, end)
    return act


def rows_to_frames(arm, q_rows, loc_rows):
    """Per-frame joint rotations {joint: [Quaternion]} + root translations."""
    n = len(loc_rows)
    return [ctrl_pose(arm, body_frames({j: q_rows[j][i] for j in nd_rig.ORDER}, loc_rows[i])) for i in range(n)]


def game_clip(name, path=None):
    """A clip as the game has it now (src/Client/Authored*.luau)."""
    import json
    folder = os.path.join(HERE, "..", "..", "src", "Client")
    files = [path] if path else sorted(os.listdir(folder))
    for fn in files:
        if not fn.startswith("Authored") or not fn.endswith(".luau"):
            continue
        s = open(os.path.join(folder, fn)).read()
        i = s.find('["%s"]=' % name)
        if i < 0:
            continue
        j = s.find('\n\t["', i + 5)
        blk = s[i:j if j > 0 else len(s)]
        head = re.search(r'fps=(\d+),frames=(\d+),length=([\d.]+)', blk)
        mk = re.search(r'markers=\{([^}]*)\}', blk).group(1)
        markers = {k: float(v) for k, v in re.findall(r'(\w+)=([-\d.]+)', mk)}
        q, loc = {}, []
        for jn in nd_rig.ORDER:
            vals = [float(x) for x in re.search(r'\b%s=\{([^}]*)\}' % jn, blk).group(1).split(',')]
            w = 7 if jn == "Root" else 4
            rows = [vals[k:k + w] for k in range(0, len(vals), w)]
            if jn == "Root":
                loc = [Vector(r[:3]) for r in rows]
                rows = [r[3:] for r in rows]
            q[jn] = [Quaternion((r[3], r[0], r[1], r[2])) for r in rows]
        return {"fps": int(head.group(1)), "length": float(head.group(3)), "markers": markers, "q": q, "loc": loc, "file": fn}
    return None


def game_action(arm, name, path=None):
    c = game_clip(name, path)
    if not c:
        return None
    n = len(c["loc"])
    frames = rows_to_frames(arm, c["q"], c["loc"])
    # (the last sample sits on the clip's end even when the step does not divide it)
    return key_frames(arm, name, frames, 60 // c["fps"], markers=c["markers"], end=int(round(c["length"] * 60)))


def guard_impact(arm):
    sh = Shot(arm, N + "Guard.Impact")
    g = S(neji_p9.GUARD)
    sh.key(0, g, "ease")
    hit = S(merge(neji_p9.GUARD, {"root": {"y": -.86, "z": .26, "pitch": 2}, "torso": {"pitch": -4}, "head": {"pitch": 2}}))
    sh.key(3, hit, "impact")
    sh.key(8, S(merge(neji_p9.GUARD, {"root": {"y": -.8, "z": .18}})), "ease")
    sh.key(19, g, "ease")
    return sh.build()


def jump_leap(arm):
    sh = Shot(arm, N + "Jump.Leap")
    sh.key(0, S(), "ease")
    sh.key(8, S({"root": {"y": -1.1, "pitch": 16}, "ra": {"raise": -20, "out": 20, "elbow": 20}, "la": {"raise": -20, "out": 20, "elbow": 20}}), "ease")
    sh.key(14, S({"root": {"y": -.1, "pitch": 4}, "ra": {"raise": 140, "out": 10, "elbow": 20}, "la": {"raise": 140, "out": 10, "elbow": 20},
                  "rf": {"toe": 30}, "lf": {"toe": 30}}), "launch")
    sh.key(26, AIR, "ease")
    return sh.build()


def jump_air(arm):
    sh = Shot(arm, N + "Jump.Air")
    sh.key(0, AIR, "ease")
    sh.key(16, merge(AIR, {"rf": {"y": 1.2, "z": -.3}, "lf": {"y": 1.0}}), "ease")
    return sh.build()


def land(arm):
    sh = Shot(arm, N + "Land")
    sh.key(0, merge(AIR, {"rf": {"y": .3}, "lf": {"y": .3}}), "ease")
    sh.key(5, S({"root": {"y": -1.15, "pitch": 18}, "ra": {"raise": 40, "out": 40}, "la": {"raise": 40, "out": 40}}), "impact")
    sh.key(28, S(), "ease")
    return sh.build()


def flip(arm):
    sh = Shot(arm, N + "Flip")
    from kunai_lion import tuck
    TUCK = (0, -.55, -.35)
    for f, p in ((0, 0), (12, 90), (24, 180), (36, 270), (48, 360)):
        spec = {"root": {"y": -.4, "z": 0, "pitch": p, "yaw": 0, "roll": 0, "tuck": 1}}
        spec.update(tuck(0, spec["root"], TUCK, TUCK))
        sh.key(f, merge(AIR, spec), "linear")
    return sh.build()


def author(arm):
    p = neji_p9
    acts = [p.light1(arm), p.light2(arm), p.light3(arm), jutsu_neji.light4(arm), p.heavy(arm), p.launcher(arm),
            p.sweep(arm), p.circle_step(arm), p.dash_attack(arm), p.air1(arm), p.air2(arm), p.air_drive(arm),
            p.air_spike(arm), p.air_switch(arm),
            gaps_e6.slam(arm, "GentleFist", AIR, S, "palms"),
            common_e9.grab(arm, N, p.STANCE), common_e9.throw_up(arm, N, p.STANCE), common_e9.air_flip(arm, N, AIR),
            guard_impact(arm), jump_leap(arm), jump_air(arm), land(arm), flip(arm)]
    return acts


# ================================================================ captures
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo"
_CAP = {}


def capture(key, place="inplace"):
    """Mixamo capture -> joint track (nd_mocap.track), cached; the FBX's
    objects leave the scene again."""
    import nd_mocap, nd_style
    k = (key, place)
    if k not in _CAP:
        before = set(bpy.data.objects)
        src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
        _CAP[k] = nd_mocap.track(src, s0, s1, place)
        for o in set(bpy.data.objects) - before:
            bpy.data.objects.remove(o, do_unlink=True)
    return nd_style.copy(_CAP[k])


def track_action(arm, name, tr, markers=None, end=None):
    step = 60 // tr.get("fps", 30)
    return key_frames(arm, name, rows_to_frames(arm, tr["q"], tr["loc"]), step, markers=markers, end=end)
