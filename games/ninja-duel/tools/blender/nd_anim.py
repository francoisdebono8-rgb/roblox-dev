"""Ninja Duel animation authoring in Blender.

A pose is written with anatomical controls (the same vocabulary as the
runtime engine, Client/VelmoraMotionEngine), in degrees and studs:

  root  {x, y, z, pitch, yaw, roll}  hips: y < 0 crouches; pitch + leans
                                     forward, yaw + turns right, roll + tilts
                                     the top to the right
  torso {pitch, yaw, roll}           chest on the hips
  head  {pitch, yaw, roll}
  ra/la {raise, out, twist, elbow, wrist, wroll}
                                     raise + lifts the arm forward, out +
                                     away from the body, twist + rolls it
                                     inward, elbow + flexes, wrist + bends
                                     the hand forward (palm side)
  rl/ll {lift, out, twist, knee, ankle}
                                     a free leg (kicks, air): lift + raises
                                     the thigh forward, knee + flexes
  rf/lf {x, y, z, yaw, toe}          a planted foot: ankle target offset from
                                     its rest position (studs, x right, y up,
                                     z back), two-bone IK solves the leg

build(spec) turns that into joint rotations (Roblox CFrame.Angles order) and
key() writes them as Blender keyframes on the rig from nd_rig. Everything is
authored at 60 fps; the exporter samples at 30.
"""
import bpy, math
from mathutils import Matrix, Quaternion, Vector
from nd_rig import JOINTS, ORDER

FPS = 60
L1, L2 = 1.05, 1.0  # thigh, shin (hip->knee, knee->ankle)
RAD = math.radians


def R(x=0, y=0, z=0):
    """Roblox CFrame.Angles(x, y, z) in degrees (Rx * Ry * Rz)."""
    return Matrix.Rotation(RAD(x), 3, "X") @ Matrix.Rotation(RAD(y), 3, "Y") @ Matrix.Rotation(RAD(z), 3, "Z")


def merge(base, over):
    out = {k: dict(v) if isinstance(v, dict) else v for k, v in base.items()}
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k].update(v)
        else:
            out[k] = dict(v) if isinstance(v, dict) else v
    return out


def ori(o):
    o = o or {}
    return R(-o.get("pitch", 0), -o.get("yaw", 0), -o.get("roll", 0))


# The three functions below are exact ports of the runtime engine's armCF,
# legFK and legIK (Client/VelmoraMotionEngine), so a pose spec means the same
# body in Blender and in the game.
def arm_rot(side, a):
    s = 1 if side == "R" else -1
    a = a or {}
    shoulder = R(a.get("raise", 0), 0, 0) @ R(0, 0, a.get("out", 0) * s) @ R(0, a.get("twist", 0) * s, 0)
    return shoulder, R(a.get("elbow", 0), 0, 0), R(a.get("wrist", 0), 0, a.get("wroll", 0) * s)


def leg_free(side, l):
    s = 1 if side == "R" else -1
    l = l or {}
    hip = R(l.get("lift", 0), 0, 0) @ R(0, 0, l.get("out", 0) * s) @ R(0, l.get("twist", 0) * s, 0)
    return hip, R(-l.get("knee", 0), 0, 0), R(l.get("ankle", 0), 0, 0)


def leg_ik(side, root_pos, root_rot, f):
    """Planted foot: ankle target (HumanoidRootPart space) -> hip, knee, ankle."""
    s = 1 if side == "R" else -1
    ankle = Vector((.5 * s + f.get("x", 0), -2.6 + f.get("y", 0), f.get("z", 0)))
    hip_w = Vector(root_pos) + root_rot @ Vector((.5 * s, -.55, 0))
    inv = root_rot.inverted()
    d = inv @ (ankle - hip_w)
    u = d.normalized() if d.length > 1e-4 else Vector((0, -1, 0))
    D = max(.45, min(d.length, L1 + L2 - 1e-3))
    bend = math.pi - math.acos(max(-1, min(1, (L1 * L1 + L2 * L2 - D * D) / (2 * L1 * L2))))
    a = math.acos(max(-1, min(1, (L1 * L1 + D * D - L2 * L2) / (2 * L1 * D))))
    hint = Vector((s * .18, 0, -1)).normalized()
    w = hint - u * hint.dot(u)
    if w.length < 1e-3:
        w = Vector((0, 0, -1))
    w = w.normalized()
    up = -(u * math.cos(a) + w * math.sin(a))
    x = w.cross(up)
    if x.length < 1e-3:
        x = Vector((1, 0, 0))
    x = x.normalized()
    z = x.cross(up).normalized()
    hip = Matrix((x, up, z)).transposed()  # columns x, up, z (CFrame.fromMatrix)
    knee = R(-math.degrees(bend), 0, 0)
    foot = (hip @ knee).inverted() @ inv @ R(0, -f.get("yaw", 0), 0) @ R(f.get("toe", 0), 0, 0)
    return hip, knee, foot


def build(spec):
    """spec -> {joint: (Quaternion, location or None)}"""
    out = {}
    r = spec.get("root", {})
    root_rot = ori(r)
    root_pos = (r.get("x", 0), r.get("y", 0), r.get("z", 0))
    out["Root"] = (root_rot.to_quaternion(), Vector(root_pos))
    out["Waist"] = (ori(spec.get("torso")).to_quaternion(), None)
    out["Neck"] = (ori(spec.get("head")).to_quaternion(), None)
    for side, key in (("R", "ra"), ("L", "la")):
        name = "Right" if side == "R" else "Left"
        sh, el, wr = arm_rot(side, spec.get(key))
        out[name] = (sh.to_quaternion(), None)
        out[name + "Elbow"] = (el.to_quaternion(), None)
        out[name + "Wrist"] = (wr.to_quaternion(), None)
    for side, free, plant in (("R", "rl", "rf"), ("L", "ll", "lf")):
        name = "Right" if side == "R" else "Left"
        if spec.get(free) is not None:
            hip, knee, ankle = leg_free(side, spec[free])
        else:
            hip, knee, ankle = leg_ik(side, root_pos, root_rot, spec.get(plant) or {})
        out[name + "Hip"] = (hip.to_quaternion(), None)
        out[name + "Knee"] = (knee.to_quaternion(), None)
        out[name + "Ankle"] = (ankle.to_quaternion(), None)
    return out


# ------------------------------------------------------------------ actions
def new_action(arm, name):
    act = bpy.data.actions.get(name)
    if act:
        bpy.data.actions.remove(act)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    if not arm.animation_data:
        arm.animation_data_create()
    arm.animation_data.action = act
    return act


def fcurves(act):
    """All F-curves of an action (Blender 4.4+ slotted actions or legacy)."""
    if hasattr(act, "layers") and len(act.layers):
        out = []
        for layer in act.layers:
            for strip in layer.strips:
                for bag in getattr(strip, "channelbags", []):
                    out.extend(bag.fcurves)
        if out:
            return out
    return list(getattr(act, "fcurves", []))


_last_quat = {}


def key(arm, frame, spec, interp="BEZIER", easing="AUTO"):
    pose = build(spec)
    for name in ORDER:
        pb = arm.pose.bones[name]
        q, loc = pose[name]
        # Keep quaternions on one hemisphere so interpolation takes the short way.
        prev = _last_quat.get((arm.name, name))
        if prev is not None and prev.dot(q) < 0:
            q = -q
        _last_quat[(arm.name, name)] = q
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame, group=name)
        if loc is not None:
            pb.location = loc
            pb.keyframe_insert("location", frame=frame, group=name)
    act = arm.animation_data.action
    for fc in fcurves(act):
        for kp in fc.keyframe_points:
            if abs(kp.co.x - frame) < .01:
                kp.interpolation = interp
                if easing != "AUTO":
                    kp.easing = easing
    return pose


def lag(arm, bones, frames):
    """Overlap: these joints follow the rest of the body `frames` later
    (their keys after the first shift right)."""
    act = arm.animation_data.action
    for fc in fcurves(act):
        path = fc.data_path
        if any('"%s"' % b in path for b in bones):
            pts = sorted(fc.keyframe_points, key=lambda k: k.co.x)
            for kp in pts[1:]:
                kp.co.x += frames
                kp.handle_left.x += frames
                kp.handle_right.x += frames
            fc.update()


def clip(arm, name, keys, markers=None, loop=False):
    """keys: list of (frame, spec[, interp[, easing]]). markers: {name: frame}."""
    _last_quat.clear()
    act = new_action(arm, name)
    for k in keys:
        key(arm, k[0], k[1], *(k[2:]))
    for fc in fcurves(act):
        for kp in fc.keyframe_points:
            if kp.interpolation == "BEZIER":
                kp.handle_left_type = "AUTO_CLAMPED"
                kp.handle_right_type = "AUTO_CLAMPED"
        fc.update()
    act["nd_markers"] = markers or {}
    act["nd_loop"] = bool(loop)
    act["nd_end"] = keys[-1][0]
    act.frame_range = (keys[0][0], keys[-1][0])
    return act


def use(arm, act):
    arm.animation_data.action = act
    ad = arm.animation_data
    if hasattr(ad, "action_slot") and hasattr(act, "slots") and len(act.slots):
        ad.action_slot = act.slots[0]
