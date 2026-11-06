"""Sasuke's moveset, pass v2 (06/11, user: « vérifie les poses de saut, les
impacts des gros coups, même les attaques que tu crois bonnes »).

Work in progress: every clip is first ported as shipped (the Motor6D rows of
src/Client/Authored*.luau put back onto the control rig), then re-authored
one by one below.
"""
import os, re, math
import bpy
from mathutils import Matrix, Quaternion, Vector
import nd_anim, nd_ctrl
from nd_rig import JOINTS, B, ORDER

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(HERE, "..", "..", "src", "Client"))
F = 60.0
N = "Lion."

CLIPS = ["Light1", "Light2", "Light3", "Light4", "Heavy", "Launcher", "Slam", "Sweep", "KneeStrike", "DashAttack",
         "FlyingKick", "LionKick", "LionBarrage", "VaultKick", "ChidoriThrust", "ChidoriDive",
         "Air1", "Air2", "AirDrive", "AirFlip", "AirSpike", "AirSwitch", "Grab", "ThrowUp", "Guard.Impact",
         "Flip", "Jump.Leap", "Jump.Air", "Land"]


# ------------------------------------------------------------ shipped rows
_LUAU = None


def shipped():
    """{clip name: {fps, frames, length, loop, markers, joints{joint: flat list}}}
    parsed from the game's generated Authored*.luau (what the game plays now)."""
    global _LUAU
    if _LUAU is not None:
        return _LUAU
    out = {}
    files = sorted(f for f in os.listdir(SRC) if re.match(r"Authored(Clips|Jutsu)\d*\.luau$", f))
    head = re.compile(r'\["([^"]+)"\]=\{fps=(\d+),frames=(\d+),length=([\d.]+),loop=(true|false),markers=\{([^}]*)\},meta=\{[^}]*\},joints=\{')
    for fn in files:
        txt = open(os.path.join(SRC, fn)).read()
        for m in head.finditer(txt):
            name = m.group(1)
            if not name.startswith(N):
                continue
            marks = {}
            for kv in m.group(6).split(","):
                if "=" in kv:
                    k, v = kv.split("=")
                    marks[k.strip()] = float(v)
            body_end = txt.find("\n\t}}", m.end())
            body = txt[m.end():body_end if body_end > 0 else None]
            joints = {}
            for jm in re.finditer(r"(\w+)=\{([^}]*)\}", body):
                joints[jm.group(1)] = [float(x) for x in jm.group(2).split(",") if x.strip()]
            out[name] = {"fps": int(m.group(2)), "frames": int(m.group(3)), "length": float(m.group(4)),
                         "loop": m.group(5) == "true", "markers": marks, "joints": joints, "file": fn}
    _LUAU = out
    return out


def rows_track(clip):
    """Shipped rows -> a pose track {"q": {joint: [Quaternion]}, "loc": [Vector], "fps"}."""
    n = clip["frames"]
    tr = {"q": {j: [] for j in ORDER}, "loc": [], "fps": clip["fps"]}
    for i in range(n):
        for j in ORDER:
            row = clip["joints"][j]
            if j == "Root":
                x, y, z, qx, qy, qz, qw = row[i * 7:(i + 1) * 7]
                tr["loc"].append(Vector((x, y, z)))
            else:
                qx, qy, qz, qw = row[i * 4:(i + 1) * 4]
            tr["q"][j].append(Quaternion((qw, qx, qy, qz)).normalized())
    return tr


# ---------------------------------------------- Motor6D track -> control rig
FK = ["Root", "Waist", "Neck", "Right", "RightElbow", "RightWrist", "Left", "LeftElbow", "LeftWrist",
      "RightHip", "RightKnee", "RightAnkle", "LeftHip", "LeftKnee", "LeftAnkle"]
BONE_PART = {"cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head",
             "shoulder.R": "RightUpperArm", "forearm.R": "RightLowerArm", "hand.R": "RightHand",
             "shoulder.L": "LeftUpperArm", "forearm.L": "LeftLowerArm", "hand.L": "LeftHand",
             "thigh.R": "RightUpperLeg", "shin.R": "RightLowerLeg", "foot.R": "RightFoot",
             "thigh.L": "LeftUpperLeg", "shin.L": "LeftLowerLeg", "foot.L": "LeftFoot"}
FK_BONES = ["cog", "spine", "neck", "shoulder.R", "forearm.R", "hand.R", "shoulder.L", "forearm.L", "hand.L"]


def part_world(T, hrp=None):
    """Motor6D transforms (Roblox) -> part CFrames (Roblox world, floor y=0)."""
    frames = {"HRP": hrp if hrp is not None else Matrix.Translation((0, nd_ctrl.H, 0))}
    for joint in FK:
        p0, p1 = nd_ctrl.MOTORS[joint]
        pivot = Vector(JOINTS[joint][0])
        c0 = Matrix.Translation(pivot - nd_ctrl.CENTRE[p0])
        c1 = Matrix.Translation(pivot - nd_ctrl.CENTRE[p1])
        frames[p1] = frames[p0] @ c0 @ T[joint] @ c1.inverted()
    return frames


def to_arm(Fm):
    m = Matrix.Identity(4)
    r = B @ Fm.to_3x3()
    for a in range(3):
        for b in range(3):
            m[a][b] = r[a][b]
    m.translation = B @ Fm.translation
    return m


def bake_track(arm, tr, name, markers=None, meta=None, lock=None):
    """Keys a Motor6D pose track onto the control rig as action `name`.

    markers: seconds from the first frame. lock: {"R"/"L": [(i0, i1)]} frame
    ranges (track frames) where that foot is held at its world spot of i0
    (no skating by construction: the IK carries the leg)."""
    step = int(F // tr.get("fps", 60))
    n = len(tr["loc"])
    act = nd_anim.new_action(arm, name)
    rest = {b.name: b.matrix_local.copy() for b in arm.data.bones}
    parent = {b.name: (b.parent.name if b.parent else None) for b in arm.data.bones}
    prest = {p: nd_ctrl.part_rest(p) for p in nd_ctrl.CENTRE}
    last_q = {}
    feet = []
    for i in range(n):
        T = {}
        for j in ORDER:
            m = tr["q"][j][i].to_matrix().to_4x4()
            if j == "Root":
                m.translation = tr["loc"][i]
            T[j] = m
        hrp = None
        if "hrp" in tr:
            hrp = tr["hrp"][i]
        P = part_world(T, hrp)
        M = {"root": rest["root"] if hrp is None else to_arm(hrp) @ prest["HRP"].inverted() @ rest["root"]}
        for b, p in BONE_PART.items():
            M[b] = to_arm(P[p]) @ prest[p].inverted() @ rest[b]
        feet.append({s: M["foot." + s].copy() for s in ("R", "L")})
        frame = i * step

        def key(bone, basis, loc=True):
            loc_, q, _ = basis.decompose()
            pb = arm.pose.bones[bone]
            prev = last_q.get(bone)
            if prev is not None and prev.dot(q) < 0:
                q = -q
            last_q[bone] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=frame, group=bone)
            if loc:
                pb.location = loc_
                pb.keyframe_insert("location", frame=frame, group=bone)

        key("root", rest["root"].inverted() @ M["root"])
        for b in FK_BONES:
            pr = parent[b]
            basis = rest[b].inverted() @ rest[pr] @ M[pr].inverted() @ M[b]
            key(b, basis, loc=b == "cog")
        for s in ("R", "L"):
            fm = M["foot." + s]
            if lock:
                for (i0, i1) in lock.get(s, ()):
                    if i0 <= i <= i1:
                        fm = feet[i0][s] if i0 < len(feet) else fm
            key("foot_ik." + s, rest["foot_ik." + s].inverted() @ fm)
            hip = M["thigh." + s].translation
            knee = M["shin." + s].translation
            ankle = fm.translation
            mid = (hip + ankle) * .5
            leg = (ankle - hip)
            d = knee - (hip + leg * ((knee - hip).dot(leg) / max(leg.length_squared, 1e-6)))
            fwd = M["thigh." + s].to_3x3() @ Vector((0, 1, 0))  # bone +Y = down the leg; use part forward below
            pf = (B @ P[BONE_PART["thigh." + s]].to_3x3()) @ Vector((0, 0, -1))
            pf = (B @ (P[BONE_PART["thigh." + s]].to_3x3() @ Vector((0, 0, -1))))
            u = leg.normalized() if leg.length > 1e-4 else Vector((0, 0, -1))
            pf = pf - u * pf.dot(u)
            ahead = d if d.length > .12 else (d + pf.normalized() * .12 if pf.length > 1e-4 else d)
            ahead = ahead.normalized() if ahead.length > 1e-5 else pf.normalized()
            pole_world = mid + ahead * 3.0
            pole = arm.data.bones["knee_pole." + s]
            pb = arm.pose.bones["knee_pole." + s]
            pb.location = pole.matrix_local.to_3x3().transposed() @ (pole_world - pole.head_local)
            pb.keyframe_insert("location", frame=frame, group="knee_pole." + s)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
        fc.update()
    act["nd_markers"] = dict(markers or {})
    act["nd_loop"] = False
    act["nd_meta"] = dict(meta or {})
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, (n - 1) * step)
    return act


def port(arm, short):
    """The shipped clip, unchanged, on the control rig."""
    clip = shipped()[N + short]
    return bake_track(arm, rows_track(clip), N + short, clip["markers"], {"source": "shipped " + clip["file"]})


# ------------------------------------------------------------------ author
NEW = {}


def author(arm):
    acts = []
    for short in CLIPS:
        fn = NEW.get(short)
        acts.append(fn(arm) if fn else port(arm, short))
    return acts
