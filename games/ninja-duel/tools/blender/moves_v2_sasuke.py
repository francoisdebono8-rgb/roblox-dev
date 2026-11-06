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


# ============================================================ key posing
from nd_shot import Shot, merge
from clips_lion2 import STANCE

ZERO = {"travel": {"x": 0, "z": 0, "yaw": 0},
        "root": {"x": 0, "y": 0, "z": 0, "pitch": 0, "yaw": 0, "roll": 0},
        "torso": {"pitch": 0, "yaw": 0, "roll": 0}, "head": {"pitch": 0, "yaw": 0, "roll": 0},
        "ra": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "la": {"raise": 0, "out": 0, "twist": 0, "elbow": 0, "wrist": 0, "wroll": 0},
        "rf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0},
        "lf": {"x": 0, "y": 0, "z": 0, "yaw": 0, "toe": 0, "knee": 0}}
BASE = merge(ZERO, STANCE)
RF, LF = BASE["rf"], BASE["lf"]


def s(over=None):
    """The stance with `over` on top (every key is a whole body)."""
    return merge(BASE, over or {})


def at(T, over=None, x=0.0):
    """The stance carried T studs along z (and x): the feet with it."""
    return merge(s({"travel": {"z": T, "x": x}, "rf": {"z": RF["z"] + T, "x": RF["x"] + x},
                    "lf": {"z": LF["z"] + T, "x": LF["x"] + x}}), over or {})


def secs(f):
    return round(f / F, 4)


# ================================================================ strings
def light1(arm):
    """L1, the chasing palm (bible: « main chasse puis paume vers sternum »,
    step 0.4, shoulder engaged). The lead hand first clears down and inward
    (it brushes his guard aside) while the hips sit back on the rear leg;
    then the front foot steps in, the hips drive forward and turn the left
    shoulder in, and the heel of the palm lands on the sternum with the
    wrist bent back - held two frames - while the rear fist stays on the
    jaw. The rear foot drags the step closed in the recovery."""
    sh = Shot(arm, N + "Light1")
    sh.key(0, s(), "ease")
    clear = s({"root": {"y": -.56, "z": .06, "pitch": 8, "yaw": 34}, "torso": {"pitch": 4, "yaw": -20},
               "head": {"pitch": -8, "yaw": -14},
               "la": {"raise": 52, "out": -18, "twist": 40, "elbow": 74, "wrist": -20},
               "ra": {"raise": 50, "out": -14, "twist": 24, "elbow": 124}})
    sh.key(4, clear, "ease")
    T = -.4
    hit = s({"travel": {"z": -.28}, "root": {"y": -.66, "z": -.34, "pitch": 16, "yaw": 40}, "torso": {"pitch": 10, "yaw": 8},
             "head": {"pitch": -10, "yaw": -34},
             "la": {"raise": 88, "out": -12, "twist": 4, "elbow": 6, "wrist": -62},
             "ra": {"raise": 44, "out": -18, "twist": 26, "elbow": 128},
             "lf": {"z": LF["z"] + T, "yaw": -10}})
    sh.key(6, merge(clear, {"lf": {"z": LF["z"] + T * .6, "y": .22, "toe": 8}, "root": {"z": -.12}}), "pass")
    sh.key(8, hit, "impact")
    sh.key(11, merge(hit, {"root": {"z": -.38, "y": -.68}, "la": {"raise": 90, "elbow": 2}}), "ease")
    sh.key(14, merge(hit, {"root": {"z": -.3, "y": -.62, "yaw": 36}, "torso": {"yaw": 0},
                           "la": {"raise": 80, "out": -2, "elbow": 30, "wrist": -30}}), "pass")
    sh.key(19, merge(at(T * .5, {"rf": {"z": RF["z"] + T * .4, "y": .18, "toe": -10}, "lf": {"z": LF["z"] + T}}),
                     {"root": {"y": -.54}}), "pass")
    sh.key(22, at(T, {"root": {"y": -.56}}), "ease")
    sh.key(29, at(T), "ease")
    sh.drag(["neck"], 1).drag(["shoulder.R", "forearm.R"], 1)
    return sh.build(markers={"contact": .1333, "recover": .2333})


def light2(arm):
    """L2, the rib kick (bible: the right leg, hip to ribs from the outside,
    pivot on the planted left foot; « hanche chargée -> fouet »). The weight
    rocks onto the front foot and the hips load back; the right knee comes up
    and out to the side (chamber) as the support heel turns out; the hips roll
    over and the shin whips in at rib height, the body leaning away, the right
    arm thrown down-back against it, the left guard high. A short overshoot
    across, the knee folds back and the foot returns to its spot."""
    sh = Shot(arm, N + "Light2")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.6, "x": -.12, "z": -.18, "pitch": 12, "yaw": 40}, "torso": {"pitch": 8, "yaw": -22},
              "head": {"pitch": -8, "yaw": -24},
              "ra": {"raise": 30, "out": 8, "twist": 10, "elbow": 100},
              "la": {"raise": 74, "out": 0, "twist": 14, "elbow": 80}, "lf": {"yaw": -16}})
    sh.key(5, load, "ease")
    chamber = s({"root": {"y": -.5, "x": -.22, "z": -.12, "pitch": 2, "yaw": 2, "roll": -10}, "torso": {"pitch": 6, "yaw": 4, "roll": 4},
                 "head": {"pitch": -6, "yaw": 0},
                 "ra": {"raise": -6, "out": 30, "twist": 0, "elbow": 60},
                 "la": {"raise": 90, "out": -8, "twist": 20, "elbow": 96},
                 "rf": {"x": .5, "z": .0, "y": 1.75, "toe": -40, "yaw": 60, "knee": 70},
                 "lf": {"yaw": -60}})
    sh.key(8, chamber, "launch")
    hit = s({"root": {"y": -.42, "x": -.3, "z": -.06, "pitch": -12, "yaw": -46, "roll": -22}, "torso": {"pitch": 8, "yaw": 30, "roll": 10},
             "head": {"pitch": -6, "yaw": 34, "roll": 8},
             "ra": {"raise": -40, "out": 36, "twist": 0, "elbow": 20},
             "la": {"raise": 96, "out": -14, "twist": 20, "elbow": 104},
             "rf": {"x": -.25, "z": -2.1, "y": 2.55, "toe": -46, "yaw": 90, "knee": 80},
             "lf": {"yaw": -100}})
    sh.key(11, hit, "impact")
    sh.key(14, merge(hit, {"root": {"yaw": -54, "roll": -24}, "rf": {"x": -.75, "z": -1.9, "y": 2.45}}), "ease")
    sh.key(17, merge(chamber, {"root": {"yaw": -10}, "lf": {"yaw": -80}, "rf": {"x": .2, "z": -.4, "y": 1.6}}), "pass")
    sh.key(23, s({"root": {"y": -.62, "z": -.1, "yaw": 26}, "torso": {"yaw": -10},
                  "rf": {"z": RF["z"] - .1, "y": .2, "toe": -16, "yaw": 30}, "lf": {"yaw": -20}}), "pass")
    sh.key(26, s({"root": {"y": -.58}}), "ease")
    sh.key(33, s(), "ease")
    sh.drag(["neck"], 1).drag(["shoulder.R", "forearm.R", "hand.R"], 2)
    return sh.build(markers={"contact": .1833, "recover": .2667})


def light4(arm):
    """L3 of his string (the third of four: L1, L2, L4, L3): the lead hook to
    the body. A level change - the knees drop, the head slips outside the
    line - the left elbow comes out level and the hips turn it in under the
    ribs, the rear heel lifting with the turn; the turn winds the hips the
    other way for the spinning heel that ends the string."""
    sh = Shot(arm, N + "Light4")
    sh.key(0, s(), "ease")
    load = s({"root": {"y": -.86, "z": -.1, "pitch": 16, "yaw": 46, "roll": -8}, "torso": {"pitch": 14, "yaw": -30, "roll": -6},
              "head": {"pitch": -14, "yaw": -4, "roll": -4},
              "la": {"raise": 40, "out": 58, "twist": 30, "elbow": 104},
              "ra": {"raise": 62, "out": -20, "twist": 26, "elbow": 124},
              "lf": {"yaw": -14}})
    sh.key(3, load, "ease")
    T = -.3
    hit = s({"travel": {"z": T}, "root": {"y": -1.0, "z": -.34, "pitch": 20, "yaw": -10, "roll": -6},
             "torso": {"pitch": 14, "yaw": 16, "roll": -4},
             "head": {"pitch": -8, "yaw": 4},
             "la": {"raise": 64, "out": 30, "twist": 80, "elbow": 96, "wrist": 0},
             "ra": {"raise": 64, "out": -24, "twist": 30, "elbow": 128},
             "lf": {"z": LF["z"] + T, "yaw": 26}, "rf": {"y": .14, "toe": -34, "yaw": 70}})
    sh.key(5, hit, "impact")
    sh.key(8, merge(hit, {"root": {"yaw": -16, "y": -1.04}, "torso": {"yaw": 20}, "la": {"out": 22}}), "ease")
    sh.key(13, merge(hit, {"root": {"y": -.78, "z": -.22, "yaw": 20, "roll": 0}, "torso": {"yaw": -6, "roll": 0},
                           "la": {"raise": 62, "out": 10, "twist": 20, "elbow": 74},
                           "rf": {"z": RF["z"] + T + .1, "y": .12, "toe": -12, "yaw": 44}}), "pass")
    sh.key(18, at(T, {"root": {"y": -.58}}), "ease")
    sh.key(28, at(T), "ease")
    sh.drag(["neck"], 1).drag(["shoulder.R", "forearm.R"], 1)
    return sh.build(markers={"contact": .0833, "recover": .2167})


def light3(arm):
    """L4 of the string, its end (bible: the left leg, a short spinning heel
    back across to the shoulder, half a turn at most, down on the foot it
    left from; heavier, it throws him). The weight goes back over the right
    foot and the hips counter-wind a hair; then they turn away (the back
    shows), the head whips round first to keep him in sight and the left
    knee folds up across; the leg opens and the heel sweeps flat across at
    shoulder height, the body leaning away from it; it carries through, the
    hips unwind and the left foot comes down where it started."""
    sh = Shot(arm, N + "Light3")
    sh.key(0, s(), "ease")
    wind = s({"root": {"y": -.6, "x": .14, "z": .16, "pitch": 6, "yaw": 22}, "torso": {"pitch": 4, "yaw": -22},
              "head": {"pitch": -6, "yaw": -12},
              "la": {"raise": 60, "out": 14, "twist": 10, "elbow": 80}, "ra": {"raise": 50, "out": -10, "twist": 24, "elbow": 120},
              "rf": {"yaw": 30}})
    sh.key(5, wind, "ease")
    turn = s({"root": {"y": -.5, "x": .3, "z": .1, "pitch": 4, "yaw": 120, "roll": 6}, "torso": {"pitch": 6, "yaw": -30},
              "head": {"pitch": -6, "yaw": -70},
              "la": {"raise": 40, "out": 40, "twist": 0, "elbow": 90}, "ra": {"raise": 56, "out": 10, "twist": 10, "elbow": 110},
              "rf": {"yaw": 120}, "lf": {"x": .35, "z": -.2, "y": 1.35, "toe": -10, "yaw": 90, "knee": -20}})
    sh.key(11, turn, "launch")
    hit = s({"root": {"y": -.36, "x": .34, "z": .12, "pitch": -6, "yaw": 156, "roll": 18},
             "torso": {"pitch": 4, "yaw": -44, "roll": -6},
             "head": {"pitch": -4, "yaw": -76, "roll": -8},
             "la": {"raise": 20, "out": 70, "twist": 0, "elbow": 40}, "ra": {"raise": 70, "out": 40, "twist": 10, "elbow": 100},
             "rf": {"yaw": 150}, "lf": {"x": -.7, "z": -1.95, "y": 2.75, "toe": 10, "yaw": 150, "knee": -30}})
    sh.key(16, hit, "impact")
    sh.key(19, merge(hit, {"root": {"yaw": 170, "roll": 20}, "lf": {"x": -1.55, "z": -1.4, "y": 2.55}}), "ease")
    sh.key(24, merge(turn, {"root": {"yaw": 150, "y": -.5}, "torso": {"yaw": -36}, "head": {"yaw": -60},
                            "lf": {"x": -.4, "z": -.9, "y": .9, "toe": 0, "yaw": 80}, "rf": {"yaw": 150}}), "pass")
    land = s({"root": {"y": -.78, "z": -.1, "pitch": 14, "yaw": 54, "roll": 0}, "torso": {"pitch": 10, "yaw": -20},
              "head": {"pitch": -10, "yaw": -24},
              "la": {"raise": 60, "out": 24, "elbow": 70}, "ra": {"raise": 46, "out": -6, "elbow": 112},
              "rf": {"yaw": 70}, "lf": {"z": LF["z"], "x": LF["x"], "yaw": -4}})
    sh.key(29, land, "impact")
    sh.key(34, merge(land, {"root": {"y": -.66, "yaw": 38}, "rf": {"yaw": 46}}), "ease")
    sh.key(41, s(), "ease")
    sh.drag(["neck"], -1).drag(["shoulder.R", "forearm.R", "shoulder.L", "forearm.L"], 1)
    return sh.build(markers={"contact": .2667, "recover": .35})


# ========================================================= heavy blows
def heavy(arm):
    """Heavy (bible: « genou arrière chargé vers abdomen puis coude de
    verrouillage »; advance 0.7, a readable charge). The weight rocks back,
    the rear knee comes up to the belly and the right elbow cocks high
    behind the head (the charge, held a beat: slow in). Then everything
    falls forward together: the knee stamps down a long step ahead, the
    hips drop and turn, and the elbow drives through flat at chest height
    with the whole body behind it - the left fist yanked back to the hip.
    Held on the contact (the hit-stop), then the weight settles heavily,
    the body rises late and the right foot walks back into the stance."""
    sh = Shot(arm, N + "Heavy")
    sh.key(0, s(), "ease")
    sit = s({"root": {"y": -.66, "z": .14, "pitch": 4, "yaw": 34}, "torso": {"pitch": 0, "yaw": -18},
             "head": {"pitch": -6, "yaw": -18},
             "ra": {"raise": 70, "out": 30, "twist": 10, "elbow": 130},
             "la": {"raise": 72, "out": 0, "twist": 14, "elbow": 60}})
    sh.key(5, sit, "ease")
    charge = s({"root": {"y": -.3, "x": -.1, "z": .06, "pitch": -4, "yaw": 46, "roll": -6}, "torso": {"pitch": 14, "yaw": 12, "roll": 0},
                "head": {"pitch": -10, "yaw": -40},
                "ra": {"raise": 150, "out": 60, "twist": -30, "elbow": 150, "wrist": 0},
                "la": {"raise": 84, "out": -10, "twist": 10, "elbow": 24},
                "rf": {"x": .1, "z": -.35, "y": 1.75, "toe": -30, "yaw": 20, "knee": 10},
                "lf": {"yaw": -16}})
    sh.key(11, charge, "ease")
    sh.key(14, merge(charge, {"root": {"y": -.26, "pitch": -6}, "ra": {"raise": 156}, "rf": {"y": 1.85}}), "ease")
    T = -.7
    hit = s({"travel": {"z": T}, "root": {"y": -1.12, "x": -.05, "z": -.3, "pitch": 26, "yaw": -6, "roll": 0},
             "torso": {"pitch": 16, "yaw": -34, "roll": -4},
             "head": {"pitch": -14, "yaw": 16},
             "ra": {"raise": 92, "out": -36, "twist": 50, "elbow": 150, "wrist": 0},
             "la": {"raise": -24, "out": 22, "twist": 0, "elbow": 100},
             "rf": {"x": -.2, "z": -1.55, "y": 0, "toe": 0, "yaw": 0, "knee": 0},
             "lf": {"z": LF["z"], "y": 0, "toe": 0, "yaw": 20}})
    sh.key(16, merge(charge, {"travel": {"z": T * .6}, "root": {"y": -.7, "z": -.2, "pitch": 14, "yaw": 20},
                              "torso": {"yaw": -10}, "ra": {"raise": 130, "out": 20, "twist": 10},
                              "rf": {"z": -1.3, "y": .45, "toe": -6}}), "pass")
    sh.key(18, hit, "impact")
    sh.key(22, merge(hit, {"root": {"y": -1.18, "z": -.34, "pitch": 28}, "torso": {"yaw": -38}, "ra": {"out": -40}}), "ease")
    sh.key(25, merge(hit, {"root": {"y": -1.14, "pitch": 24}, "torso": {"yaw": -30}}), "ease")
    sh.key(33, merge(hit, {"root": {"y": -.84, "z": -.2, "pitch": 16, "yaw": 10}, "torso": {"pitch": 10, "yaw": -24},
                           "head": {"pitch": -10, "yaw": 0},
                           "ra": {"raise": 60, "out": -10, "twist": 30, "elbow": 110},
                           "la": {"raise": 30, "out": 20, "elbow": 90},
                           "lf": {"yaw": 0}}), "pass")
    # the right foot walks back behind, then the left re-sets the lead
    sh.key(37, merge(at(T, {"root": {"y": -.7, "yaw": 26, "pitch": 14}}),
                     {"lf": {"z": LF["z"], "yaw": 0}, "rf": {"x": RF["x"] - .1, "z": -.65, "y": .34, "toe": -14, "yaw": 20}}), "pass")
    sh.key(40, merge(at(T, {"root": {"y": -.66, "yaw": 32}}), {"lf": {"z": LF["z"]}}), "pass")
    sh.key(42, at(T, {"root": {"y": -.6}, "lf": {"z": LF["z"] + T * .5, "y": .16, "toe": 6}}), "pass")
    sh.key(45, at(T), "ease")
    sh.drag(["neck"], 2).drag(["shoulder.L", "forearm.L"], 1).drag(["spine"], 1)
    return sh.build(markers={"contact": .3, "recover": .4167})


def knee_strike(arm):
    """KneeStrike (his heavy after one hit): the clinch knee. Both hands shoot
    up and catch the back of his head, the hips push in; the hands haul the
    head down as the rear knee drives up through it - the body arches back
    over the support foot, up on its toes - held; the knee drops and the
    foot sets back down behind, the guard returns."""
    sh = Shot(arm, N + "KneeStrike")
    sh.key(0, s(), "ease")
    catch = s({"root": {"y": -.44, "z": -.2, "pitch": 6, "yaw": 20}, "torso": {"pitch": 10, "yaw": -8},
               "head": {"pitch": -8, "yaw": -12},
               "la": {"raise": 118, "out": -14, "twist": 30, "elbow": 54, "wrist": 30},
               "ra": {"raise": 112, "out": -22, "twist": 30, "elbow": 64, "wrist": 30}})
    sh.key(3, catch, "ease")
    hit = s({"travel": {"z": -.3}, "root": {"y": -.1, "z": -.42, "pitch": -18, "yaw": 10}, "torso": {"pitch": 30, "yaw": -6},
             "head": {"pitch": -2, "yaw": -6},
             "la": {"raise": 70, "out": -16, "twist": 30, "elbow": 104, "wrist": 40},
             "ra": {"raise": 66, "out": -22, "twist": 30, "elbow": 110, "wrist": 40},
             "rf": {"x": -.1, "z": -1.5, "y": 2.05, "toe": -50, "yaw": 10, "knee": 0},
             "lf": {"y": .1, "toe": 18, "yaw": -2}})
    sh.key(6, hit, "impact")
    sh.key(10, merge(hit, {"root": {"y": -.08, "pitch": -20}, "rf": {"y": 2.12, "z": -1.55}, "la": {"elbow": 108}, "ra": {"elbow": 114}}), "ease")
    sh.key(13, merge(hit, {"root": {"y": -.3, "pitch": -4, "z": -.34}, "torso": {"pitch": 14},
                           "rf": {"z": -.6, "y": 1.3, "toe": -30}, "lf": {"y": 0, "toe": 0},
                           "la": {"raise": 80, "out": 0, "elbow": 80}, "ra": {"raise": 60, "out": -10, "elbow": 110}}), "pass")
    sh.key(18, at(-.3, {"root": {"y": -.62}, "rf": {"z": RF["z"] - .3 + .05, "y": .16, "toe": -10}}), "pass")
    sh.key(23, at(-.3), "ease")
    sh.drag(["neck"], 1)
    return sh.build(markers={"contact": .1, "recover": .2})


# ------------------------------------------------------------------ author
NEW = {"Light1": light1, "Light2": light2, "Light4": light4, "Light3": light3, "Heavy": heavy, "KneeStrike": knee_strike}


def author(arm):
    acts = []
    for short in CLIPS:
        fn = NEW.get(short)
        acts.append(fn(arm) if fn else port(arm, short))
    return acts
