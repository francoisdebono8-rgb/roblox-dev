"""Moveset pass v2 (06/11): Minato (Flashstep) - every strike, air attack,
jump and landing, re-checked and re-authored (work in progress: the clips
not yet re-authored are ported from their current modules so every clip name
exists).

  ND_ONLY=Flashstep python3 job_moves_v2.py
"""
import bpy, os, re, json, math
from mathutils import Matrix, Vector, Quaternion
from nd_shot import Shot, merge
import nd_rig, nd_ctrl, nd_anim
import clips_flash2, minato_p4, jutsu_minato, common_e9, clips_react2
from clips_flash2 import STANCE, s

N = "Flashstep."
HERE = os.path.dirname(os.path.abspath(__file__))
SRC_CLIENT = os.path.join(HERE, "..", "..", "src", "Client")
H = nd_rig.ROOT_HEIGHT
B = nd_rig.B
CENTRE = nd_ctrl.CENTRE
MOTORS = nd_ctrl.MOTORS
JOINTS = nd_rig.JOINTS


# ======================================================= Motor6D rows -> ctrl
# (worked around inside this module: nd_mocap.bake keys the FK deform rig of
# nd_rig, and job_moves_v2 exports from the control rig of nd_ctrl. This
# solves a pose track - Motor6D local rotations, the rows the game plays and
# nd_mocap.track's output - back onto the control bones: FK bones take the
# part frames, the feet's IK targets take the ankles, the knee poles point
# where the knees are.)
FK_PART = {"cog": "LowerTorso", "spine": "UpperTorso", "neck": "Head"}
for _s, _n in (("R", "Right"), ("L", "Left")):
    FK_PART["shoulder." + _s] = _n + "UpperArm"
    FK_PART["forearm." + _s] = _n + "LowerArm"
    FK_PART["hand." + _s] = _n + "Hand"


def _T(v):
    return Matrix.Translation(Vector(v))


def fk(qs, root_loc):
    """One frame of Motor6D rotations -> part frames (Roblox axes, HRP at H)."""
    P = {"HRP": _T((0, H, 0))}
    for joint in nd_rig.ORDER:
        p0, p1 = MOTORS[joint]
        pivot = Vector(JOINTS[joint][0])
        M = qs[joint].to_matrix().to_4x4()
        if joint == "Root":
            M.translation = Vector(root_loc)
        P[p1] = P[p0] @ _T(pivot - CENTRE[p0]) @ M @ _T(CENTRE[p1] - pivot)
    return P


def _to_bl(P):
    m = (B @ P.to_3x3()).to_4x4()
    m.translation = B @ P.translation
    return m


def ctrl_pose(arm, qs, root_loc):
    """{bone: (quat or None, loc or None)} for the control rig."""
    P = fk(qs, root_loc)
    rest = {b.name: b.matrix_local for b in arm.data.bones}
    A = {"root": rest["root"]}
    for bone, part in FK_PART.items():
        A[bone] = _to_bl(P[part]) @ nd_ctrl.part_rest(part).inverted() @ rest[bone]
    out = {"root": (Quaternion(), Vector())}
    for bone in FK_PART:
        par = arm.data.bones[bone].parent.name
        basis = rest[bone].inverted() @ rest[par] @ A[par].inverted() @ A[bone]
        out[bone] = (basis.to_quaternion().normalized(), basis.translation.copy() if bone == "cog" else None)
    for side, n in (("R", "Right"), ("L", "Left")):
        foot = _to_bl(P[n + "Foot"]) @ nd_ctrl.part_rest(n + "Foot").inverted() @ rest["foot." + side]
        basis = rest["foot_ik." + side].inverted() @ foot
        out["foot_ik." + side] = (basis.to_quaternion().normalized(), basis.translation.copy())
        hip = B @ (P[n + "UpperLeg"] @ (Vector(JOINTS[n + "Hip"][0]) - CENTRE[n + "UpperLeg"]))
        knee = B @ (P[n + "UpperLeg"] @ (Vector(JOINTS[n + "Knee"][0]) - CENTRE[n + "UpperLeg"]))
        ank = foot.translation
        mid = (hip + ank) * .5
        # the knee is a hinge: it bends toward the thigh's own front (-Z of
        # the UpperLeg part), taken square to the hip-ankle line (robust on
        # a straight leg, where knee - mid vanishes)
        axis = (ank - hip).normalized()
        fwd = B @ (P[n + "UpperLeg"].to_3x3() @ Vector((0, 0, -1)))
        d = fwd - axis * fwd.dot(axis)
        if d.length < 1e-3:
            d = knee - mid
        pole_world = mid + d.normalized() * 3.0
        pole = arm.data.bones["knee_pole." + side]
        out["knee_pole." + side] = (None, pole.matrix_local.to_3x3().transposed() @ (pole_world - pole.head_local))
    return out


def bake_ctrl(arm, tr, name, markers=None, meta=None, plant=None):
    """A pose track {"q": {joint: [Quaternion]}, "loc": [Vector], "fps"} keyed
    on the control rig as action `name` (markers in seconds). plant: optional
    {side: [(i0, i1)]} sample ranges where that foot's IK target is held at
    its position of i0 (a planted foot cannot slide)."""
    act = nd_anim.new_action(arm, name)
    step = nd_anim.FPS // tr.get("fps", 30)
    n = len(tr["loc"])
    last = {}
    poses = [ctrl_pose(arm, {j: tr["q"][j][i] for j in nd_rig.ORDER}, tr["loc"][i]) for i in range(n)]
    for side, ranges in (plant or {}).items():
        for i0, i1 in ranges:
            for i in range(max(0, i0), min(n - 1, i1) + 1):
                q, _ = poses[i]["foot_ik." + side]
                q0, l0 = poses[i0]["foot_ik." + side]
                poses[i]["foot_ik." + side] = (q0, l0)
    for i, pose in enumerate(poses):
        for bone, (q, loc) in pose.items():
            pb = arm.pose.bones[bone]
            if q is not None:
                prev = last.get(bone)
                if prev is not None and prev.dot(q) < 0:
                    q = -q
                last[bone] = q
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=i * step, group=bone)
            if loc is not None:
                pb.location = loc
                pb.keyframe_insert("location", frame=i * step, group=bone)
    for fc in nd_anim.fcurves(act):
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_markers"] = dict(markers or {})
    act["nd_loop"] = False
    act["nd_meta"] = dict(meta or {})
    act["nd_rig"] = "ctrl"
    act.frame_range = (0, (n - 1) * step)
    return act


_TIMINGS = None


def game_rows(name):
    """The clip the game plays now (src/Client/Authored*.luau) as a track."""
    global _TIMINGS
    if _TIMINGS is None:
        try:
            _TIMINGS = json.load(open(os.environ.get("ND_TIMINGS", "/tmp/claude-0/-home-claude/60386c0c-0f7e-5237-92aa-0aedd11b1cac/scratchpad/moves_clip_timings.json")))
        except Exception:
            _TIMINGS = {}
    files = sorted(f for f in os.listdir(SRC_CLIENT) if f.startswith("Authored") and f.endswith(".luau"))
    if name in _TIMINGS:
        files = [_TIMINGS[name]["file"]]
    found = None
    for f in files:
        text = open(os.path.join(SRC_CLIENT, f)).read()
        i = text.find('["%s"]={' % name)
        if i >= 0:
            found = (f, text, i)     # (the last file wins, like the engine's merge)
    if not found:
        return None
    f, text, i = found
    head_end = text.index("joints={", i)
    head = text[i:head_end]
    fps = int(re.search(r"fps=(\d+)", head).group(1))
    length = float(re.search(r"length=([\d.]+)", head).group(1))
    mk = dict((k, float(v)) for k, v in re.findall(r"(\w+)=([\d.]+)", re.search(r"markers=\{([^}]*)\}", head).group(1)))
    body = text[head_end:text.index("}},", head_end)]
    rows = dict((j, [float(x) for x in v.split(",")]) for j, v in re.findall(r"(\w+)=\{([^}]*)\}", body))
    tr = {"q": {}, "loc": [], "fps": fps}
    for j in nd_rig.ORDER:
        r = rows[j]
        w = 7 if j == "Root" else 4
        k = len(r) // w
        if j == "Root":
            tr["loc"] = [Vector(r[i * 7:i * 7 + 3]) for i in range(k)]
            tr["q"][j] = [Quaternion((r[i * 7 + 6], r[i * 7 + 3], r[i * 7 + 4], r[i * 7 + 5])) for i in range(k)]
        else:
            tr["q"][j] = [Quaternion((r[i * 4 + 3], r[i * 4], r[i * 4 + 1], r[i * 4 + 2])) for i in range(k)]
    return {"tr": tr, "markers": mk, "length": length, "file": f}


def author_game(arm):
    """The clips the game plays now, replayed on the control rig (triage)."""
    names = json.load(open(os.environ.get("ND_CLIPNAMES", "/tmp/claude-0/-home-claude/60386c0c-0f7e-5237-92aa-0aedd11b1cac/scratchpad/moves_clipnames.json")))["Flashstep"]
    only = [c for c in os.environ.get("ND_CLIPS", "").split(",") if c]
    acts = []
    for name in names:
        if only and name not in only:
            continue
        g = game_rows(name)
        if g is None:
            print("no game clip", name)
            continue
        acts.append(bake_ctrl(arm, g["tr"], name + ".old" if os.environ.get("ND_OLD_SUFFIX") else name, g["markers"], {"from": g["file"]}))
    return acts


def _guard_impact(arm):
    b = clips_react2.Body("Flashstep", STANCE, 18 / 22, 1.0)
    return [a for a in clips_react2.guards(b, arm) if a.name.endswith("Guard.Impact")][0]


def _flip(arm):
    """Ground flip (the engine turns the body over): a tuck - knees to the
    chest, arms hugging the shins - opened late for the landing."""
    sh = Shot(arm, N + "Flip")
    sh.key(0, s({"root": {"y": -.7, "pitch": 20}}), "ease")
    tuck = s({"root": {"y": -.2, "pitch": 30}, "torso": {"pitch": 30}, "head": {"pitch": 10},
              "ra": {"raise": 70, "out": -6, "elbow": 100}, "la": {"raise": 70, "out": -6, "elbow": 100},
              "rf": {"z": -.3, "y": 1.6, "x": .3}, "lf": {"z": -.3, "y": 1.6, "x": -.3}})
    sh.key(10, tuck, "ease")
    sh.key(34, tuck, "ease")
    sh.key(48, s(), "ease")
    return sh.build()


def author(arm):
    acts = []
    port = [
        lambda: clips_flash2.light1(arm), lambda: clips_flash2.light2(arm), lambda: clips_flash2.light3(arm),
        lambda: jutsu_minato.light4(arm), lambda: clips_flash2.heavy(arm), lambda: clips_flash2.launcher(arm),
        lambda: clips_flash2.air1(arm), lambda: clips_flash2.air2(arm),
        lambda: clips_flash2.jump_air(arm), lambda: clips_flash2.jump_leap(arm), lambda: clips_flash2.land(arm),
        lambda: minato_p4.sweep(arm), lambda: minato_p4.angle_step(arm), lambda: minato_p4.knee_strike(arm),
        lambda: minato_p4.air_drive(arm), lambda: minato_p4.air_spike(arm), lambda: minato_p4.air_switch(arm),
        lambda: minato_p4.rasengan_drop(arm), lambda: minato_p4.quickstep(arm),
        lambda: jutsu_minato.flash_strike(arm),
        lambda: common_e9.grab(arm, N, STANCE), lambda: common_e9.throw_up(arm, N, STANCE),
        lambda: common_e9.air_flip(arm, N, clips_flash2.AIR),
        lambda: _guard_impact(arm), lambda: _flip(arm),
    ]
    for fn in port:
        try:
            r = fn()
        except Exception as e:  # keep the rest of the set
            print("PORT FAIL", e)
            continue
        acts += r if isinstance(r, list) else [r]
    try:
        import gaps_e6
        acts.append(gaps_e6.slam(arm, "Flashstep", clips_flash2.AIR, s, "stab"))
    except Exception as e:
        print("PORT FAIL slam", e)
    return acts
