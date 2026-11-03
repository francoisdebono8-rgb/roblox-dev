"""Strikes of the 8 prodigies from Mixamo captures, timed to the game (DEC-032).

A capture brings the real mechanics of a blow (the hips lead, the shoulder
follows, the fist snaps); the game decides WHEN it lands. Each slot keeps the
timing of the key-posed clip it replaces (its length and its contact and
recover markers, read from the earlier exports), and the capture is warped
onto it piecewise: wind-up -> contact, contact -> recover, recover -> end
(the anime timing: a slow, readable wind-up, a blow that snaps). The first and
last frames melt into the key-posed clip's own, so a string chains with no
snap. Then each fighter's carriage (nd_style) applies.
  python job_mocap_strikes.py -- <mixamo folder> <out folder>"""
import bpy, sys, os, json, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nd_rig, nd_anim, nd_mocap, nd_style, nd_io
from mathutils import Quaternion, Vector

SRC, OUT = sys.argv[-2], sys.argv[-1]
ONLY = [f for f in os.environ.get("ND_ONLY", "").split(",") if f]
# slot -> (capture, striking limb): every fighter's base, then his own blows
BASE = {"Light1": ("jab", "LeftWrist"), "Light2": ("cross", "RightWrist"), "Light3": ("kick_roundhouse", "RightAnkle"),
        "Heavy": ("kick_side", "RightAnkle"), "Launcher": ("uppercut", "LeftWrist"), "KneeStrike": ("knee_muaythai", "RightKnee"),
        "Sweep": ("capoeira_ground_spin", "RightAnkle"), "DashAttack": ("flying_kick", "RightAnkle"),
        "FlyingKick": ("flying_kick", "RightAnkle"),
        # in the air: captured air kicks (the hips' height leaves the clip)
        "Air1": ("bicycle_kick", "RightAnkle"), "Air2": ("crescent_kick", "RightAnkle"),
        "AirDrive": ("flying_kick", "RightAnkle"), "AirFlip": ("spin_flip_kick", "RightAnkle"),
        "AirSwitch": ("butterfly_kick", "RightAnkle")}
OWN = {
    "Leaf": {"Light3": ("punch_combo4", "RightWrist"), "Heavy": ("hurricane_kick", "RightAnkle"),
             "LeafWhirlwind": ("butterfly_kick", "RightAnkle"), "LeafHurricane": ("hurricane_kick", "RightAnkle"),
             "LeafRising": ("backflip_uppercut", "RightWrist"), "LeafHeel": ("kick_high", "RightAnkle")},
    "Legion": {"Light1": ("hook", "RightWrist"), "Light2": ("uppercut", "LeftWrist"), "Light3": ("quad_punch", "RightWrist"),
               "Heavy": ("drop_kick", "RightAnkle"), "UzumakiKick": ("kick_high", "RightAnkle")},
    "Lion": {"Heavy": ("kick_high", "RightAnkle"), "LionKick": ("kick_spin_back", "RightAnkle"),
             "VaultKick": ("flip_kick", "RightAnkle"), "LionBarrage": ("punch_combo4", "RightWrist")},
    "GentleFist": {"Light3": ("cross", "RightWrist"), "PalmThrust": ("hadouken", "RightWrist"), "Sweep": ("kick_low", "RightAnkle")},
    "Mirage": {"Light2": ("kick_low", "RightAnkle"), "Light3": ("hook", "RightWrist"), "CounterPalm": ("hadouken", "RightWrist")},
    "Copycat": {"Light2": ("kick_low", "RightAnkle"), "Light3": ("cross", "RightWrist"), "Heavy": ("kick_roundhouse", "RightAnkle"),
                "Sweep": ("kick_low", "RightAnkle")},
    "Flashstep": {"Light2": ("kick_side", "RightAnkle"), "Heavy": ("spin_flip_kick", "RightAnkle"),
                  "Rasengan": ("hadouken", "RightWrist")},
    "Sand": {"Light1": ("flick_throw", "RightWrist"), "Light2": ("cast_forward", "RightWrist"), "Light3": ("hadouken", "RightWrist")},
}
AIR = {"Air1", "Air2", "AirDrive", "AirFlip", "AirSwitch"}
NO_BASE = {"Sand": {"Heavy", "Launcher", "KneeStrike", "FlyingKick", "Air1", "Air2", "AirDrive", "AirFlip", "AirSwitch"}}
PLAN = {}
for F in ("Leaf", "Legion", "Lion", "GentleFist", "Mirage", "Copycat", "Flashstep", "Sand"):
    PLAN[F] = {k: v for k, v in BASE.items() if k not in NO_BASE.get(F, ())}
    PLAN[F].update(OWN.get(F, {}))
TIPS = {"RightWrist": (0, -.6, 0), "LeftWrist": (0, -.6, 0), "RightAnkle": (0, -.3, -.6), "LeftAnkle": (0, -.3, -.6),
        "RightKnee": (0, -.5, 0), "LeftKnee": (0, -.5, 0)}

# the key-posed clips (earlier exports): timing and the poses to melt into
OLD = {}
for path in sorted(glob.glob(os.path.join(os.environ.get("ND_OLD", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/out"), "clips_*.json"))):
    if "_mocap" in path:
        continue
    try:
        OLD.update(json.load(open(path)))
    except Exception:
        pass


def row_q(row, root=False):
    r = row[3:] if root else row
    return Quaternion((r[3], r[0], r[1], r[2]))


def effector_track(arm, tr, limb):
    """World positions (studs) of the striking tip per capture frame."""
    act = nd_mocap.bake(arm, nd_style.copy(tr), "probe")
    nd_anim.use(arm, act)
    out, hips = [], []
    for i in range(len(tr["loc"])):
        bpy.context.scene.frame_set(i * 2)
        m = arm.matrix_world @ arm.pose.bones[limb].matrix
        out.append((m @ Vector(TIPS[limb])).copy())
        hips.append((arm.matrix_world @ arm.pose.bones["Root"].matrix).translation.copy())
    bpy.data.actions.remove(act)
    return out, hips


def phases(points, hips, fps=30):
    """(start, impact, settle, end) capture frames: the blow lands where the
    tip reaches furthest from the hips (a run-up's fast feet do not count)."""
    sp = [0] + [(points[i] - points[i - 1]).length * fps for i in range(1, len(points))]
    reach = [(p - h).length for p, h in zip(points, hips)]
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


def warp(tr, src_marks, dst_marks, frames_out):
    """Piecewise-linear time warp: capture frames src_marks -> output frames."""
    n = len(tr["loc"])
    out_q = {j: [] for j in tr["q"]}
    out_l = []
    for k in range(frames_out):
        t = k
        for (a0, a1), (b0, b1) in zip(zip(src_marks, src_marks[1:]), zip(dst_marks, dst_marks[1:])):
            if b0 <= t <= b1:
                x = a0 + (a1 - a0) * (t - b0) / max(b1 - b0, 1e-6)
                break
        else:
            x = src_marks[-1]
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


def melt(tr, old, head=.22, tail=.22):
    """The first and last frames turn into the key-posed clip's own."""
    n = len(tr["loc"])
    first = {j: (row_q(old["joints"][j][0], j == "Root")) for j in nd_rig.ORDER}
    last = {j: (row_q(old["joints"][j][-1], j == "Root")) for j in nd_rig.ORDER}
    y0, y1 = old["joints"]["Root"][0][1], old["joints"]["Root"][-1][1]
    for k in range(n):
        u = k / max(1, n - 1)
        w0 = max(0.0, 1 - u / head)
        w1 = max(0.0, 1 - (1 - u) / tail)
        for j in nd_rig.ORDER:
            q = tr["q"][j][k]
            if w0 > 0:
                q = q.slerp(first[j], w0 * w0 * (3 - 2 * w0))
            if w1 > 0:
                q = q.slerp(last[j], w1 * w1 * (3 - 2 * w1))
            tr["q"][j][k] = q
        y = tr["loc"][k].y
        y = y + (y0 - y) * max(w0, 0) + (y1 - y) * max(w1, 0)
        tr["loc"][k] = Vector((0, y, 0))
    return tr


def limit(tr, max_deg=58.0):
    """No segment turns more than max_deg between two exported frames (the
    engine draws twice per frame: under 30 deg a frame on screen). A spin
    the warp compressed catches up a frame later instead of snapping."""
    cap = math.radians(max_deg)
    for j, qs in tr["q"].items():
        out = [qs[0]]
        for q in qs[1:]:
            prev = out[-1]
            d = prev.rotation_difference(q)
            angle = d.angle if d.angle <= math.pi else 2 * math.pi - d.angle
            out.append(q if angle <= cap else prev.slerp(q if prev.dot(q) >= 0 else -q, cap / angle))
        tr["q"][j] = out
    return tr


def ground(arm, tr):
    """The lower ankle stays on the floor: the hips' height follows the legs
    (the engine plants a foot that touches the floor while the server carries
    the body)."""
    act = nd_mocap.bake(arm, nd_style.copy(tr), "probe_ground")
    nd_anim.use(arm, act)
    floor = (arm.matrix_world @ arm.data.bones["RightAnkle"].matrix_local).translation.z
    step = nd_anim.FPS // tr.get("fps", 30)
    for i in range(len(tr["loc"])):
        bpy.context.scene.frame_set(i * step)
        z = min((arm.matrix_world @ arm.pose.bones[a].matrix).translation.z for a in ("RightAnkle", "LeftAnkle"))
        tr["loc"][i] = tr["loc"][i] + Vector((0, floor - z, 0))
    bpy.data.actions.remove(act)
    return tr


def plant(arm, tr, ramp=3):
    """A foot on the floor stays where it landed (HumanoidRootPart space,
    two-bone IK), like the key-posed strikes: the capture's hips travel over
    it, ours stay in place, so without this the support foot slides."""
    act = nd_mocap.bake(arm, nd_style.copy(tr), "probe_plant")
    nd_anim.use(arm, act)
    step = nd_anim.FPS // tr.get("fps", 30)
    n = len(tr["loc"])
    B_INV = nd_rig.B.inverted()
    base = arm.matrix_world.translation.copy()
    feet = {"R": [], "L": []}
    for i in range(n):
        bpy.context.scene.frame_set(i * step)
        for side, bone in (("R", "RightAnkle"), ("L", "LeftAnkle")):
            m = arm.matrix_world @ arm.pose.bones[bone].matrix
            pos = B_INV @ (m.translation - base)
            fwd = B_INV @ (m.to_3x3() @ Vector((0, 0, -1)))
            feet[side].append((pos, math.degrees(math.atan2(fwd.x, -fwd.z))))
    bpy.data.actions.remove(act)
    for side, name in (("R", "Right"), ("L", "Left")):
        s = 1 if side == "R" else -1
        low = [p.y < -2.6 + .3 for p, _ in feet[side]]
        # contact runs, each locked at its first frame
        target = [None] * n
        i = 0
        while i < n:
            if low[i]:
                j = i
                while j + 1 < n and low[j + 1]:
                    j += 1
                if j - i >= 2:
                    for k in range(i, j + 1):
                        target[k] = feet[side][i]
                i = j + 1
            else:
                i += 1
        for k in range(n):
            if target[k] is None:
                continue
            # ramp in and out of the lock
            w = 1.0
            for d in range(1, ramp + 1):
                if k - d < 0 or target[k - d] is None or k + d >= n or target[k + d] is None:
                    w = min(w, d / (ramp + 1))
            (pos, yaw) = target[k]
            root_rot = tr["q"]["Root"][k].to_matrix()
            # the hips come down when the locked foot would be out of reach
            # (the capture's hips swing away over a pivoting support foot)
            hip = tr["loc"][k] + root_rot @ Vector((.5 * s, -.55, 0))
            horiz = Vector((pos.x - hip.x, 0, pos.z - hip.z)).length
            reach = (nd_anim.L1 + nd_anim.L2) * .96
            if (pos - hip).length > reach and horiz < reach:
                need = pos.y + math.sqrt(reach * reach - horiz * horiz)
                tr["loc"][k] = Vector((tr["loc"][k].x, tr["loc"][k].y + (need - hip.y) * w, tr["loc"][k].z))
            hip, knee, foot = nd_anim.leg_ik(side, tr["loc"][k], root_rot,
                                             {"x": pos.x - .5 * s, "y": pos.y + 2.6, "z": pos.z, "yaw": yaw})
            for joint, mat in ((name + "Hip", hip), (name + "Knee", knee), (name + "Ankle", foot)):
                q = mat.to_quaternion()
                cur = tr["q"][joint][k]
                if cur.dot(q) < 0:
                    q = -q
                tr["q"][joint][k] = cur.slerp(q, w)
    return tr


bpy.ops.wm.read_factory_settings(use_empty=True)
cache = {}
for fighter, slots in PLAN.items():
    if ONLY and fighter not in ONLY:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = nd_anim.FPS
    arm = nd_rig.build_rig(fighter, "Lion")
    acts = []
    for slot, (key, limb) in slots.items():
        name = "%s.%s" % (fighter, slot)
        old = OLD.get(name)
        path = os.path.join(SRC, "mixamo_%s.fbx" % key)
        if not old or not os.path.exists(path):
            print("skip", name, "no key-posed clip" if not old else "no capture")
            continue
        if key not in cache:
            before = set(bpy.data.objects)
            src, s0, s1, _ = nd_mocap.import_fbx(path)
            cache[key] = nd_mocap.track(src, s0, s1, "inplace")
            for o in set(bpy.data.objects) - before:
                bpy.data.objects.remove(o, do_unlink=True)
        tr = nd_style.copy(cache[key])
        start, impact, settle, end = phases(*effector_track(arm, tr, limb))
        fps_old = old.get("fps", 60)
        n_out = int(round(old["length"] * 60)) + 1
        c = old["markers"].get("contact", old["length"] * .4) * 60
        r = old["markers"].get("recover", old["length"] * .6) * 60
        warp(tr, [start, impact, settle, end], [0, c, r, n_out - 1], n_out)
        melt(tr, old)
        if slot in AIR:
            nd_style.still_root(tr, keep_rotation=True)
        else:
            ground(arm, tr)
            plant(arm, tr)
        limit(tr)
        kind = "Strike"
        nd_style.style(fighter, kind, tr)
        act = nd_mocap.bake(arm, tr, name, False, {"capture": key}, old["markers"])
        acts.append(act)
        print("clip", name, key, "src", (start, impact, settle, end), "->", n_out, "frames")
    if acts:
        nd_io.export(arm, acts, os.path.join(OUT, "clips_%s_strikes.json" % fighter))
        print("OK", fighter, len(acts))
