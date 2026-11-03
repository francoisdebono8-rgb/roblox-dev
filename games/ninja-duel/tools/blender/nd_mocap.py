"""Mixamo motion capture onto the Ninja Duel rig, as RAW MATERIAL (DEC-032).

User 03/11: "je veux que tu t'en serves pour en faire toi de meilleures
animations pour nos personnages, pas des trucs génériques que tout le monde
aura dans son jeu". A capture gives what our key-posed clips lack (the weight,
the balance and the timing of a real body); it is never shipped as is: the
style passes (nd_style) turn it into each fighter's own movement.

retarget(src, arm, ...) bakes a Mixamo armature (FBX, "without skin", X Bot
skeleton) onto our rig (nd_rig) as one action:
  - each of our body segments takes the WORLD rotation of its capture bone
    (the upper torso takes Spine2, the head takes Head, the shoulder takes the
    upper arm...), measured from the capture's rest pose (T-pose) after our
    rest (arms down) has been swung onto it, so twists and swings carry over
    whatever the two skeletons' bone rolls;
  - the hips' travel is scaled to our height (studs) and kept in Roblox axes;
    `place` decides what of it the clip keeps (the engine moves the body).
Mixamo X Bot faces -Y in Blender with its right side at -X; our rig faces +Y
(Roblox -Z) with its right at +X, so the capture is turned half a turn first.
"""
import bpy, math
from mathutils import Matrix, Quaternion, Vector
import nd_rig, nd_anim

# our joint -> capture bone whose world rotation it takes
SOURCE = {
    "Root": "Hips", "Waist": "Spine2", "Neck": "Head",
    "Right": "RightArm", "RightElbow": "RightForeArm", "RightWrist": "RightHand",
    "Left": "LeftArm", "LeftElbow": "LeftForeArm", "LeftWrist": "LeftHand",
    "RightHip": "RightUpLeg", "RightKnee": "RightLeg", "RightAnkle": "RightFoot",
    "LeftHip": "LeftUpLeg", "LeftKnee": "LeftLeg", "LeftAnkle": "LeftFoot",
}
# limbs: the rest directions that are swung onto each other
# (capture: bone head -> this child's head; ours: Roblox root-space vectors)
SOURCE_CHILD = {
    "RightArm": "RightForeArm", "RightForeArm": "RightHand", "RightHand": "RightHandMiddle1",
    "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "LeftHand": "LeftHandMiddle1",
    "RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase",
    "LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase",
}
OUR_DIR = {}
for _side, _s in (("Right", 1), ("Left", -1)):
    # (the upper arm box hangs straight down from the shoulder pivot at its
    # inner top corner: its long axis, not pivot->elbow, is what must match)
    OUR_DIR[_side] = (0, -1, 0)
    OUR_DIR[_side + "Elbow"] = (0, -.93, 0)
    OUR_DIR[_side + "Wrist"] = (0, -1, 0)
    OUR_DIR[_side + "Hip"] = (0, -1.05, 0)
    OUR_DIR[_side + "Knee"] = (0, -1, 0)
    OUR_DIR[_side + "Ankle"] = (0, -.3, -.7)
PARENT = {j: p for j, (_, p) in nd_rig.JOINTS.items()}
QB = nd_rig.B.to_quaternion()
QB_INV = QB.inverted()
B_INV = nd_rig.B.inverted()


def import_fbx(path):
    """Imports a Mixamo FBX; returns (armature, first frame, last frame, fps)."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, ignore_leaf_bones=True, automatic_bone_orientation=False)
    new = [o for o in bpy.data.objects if o not in before]
    src = next(o for o in new if o.type == "ARMATURE")
    for o in new:
        if o is not src and o.type == "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    act = src.animation_data.action
    start, end = (int(round(v)) for v in act.frame_range)
    return src, start, end, bpy.context.scene.render.fps


def _prefix(src):
    for b in src.data.bones:
        if b.name.endswith("Hips"):
            return b.name[:-4]
    raise ValueError("no Hips bone in " + src.name)


def _decompose(m):
    loc, rot, _ = m.decompose()
    return loc, rot


def sample(src, start, end):
    """World rotations (turned to face like our rig) and hips positions per frame."""
    pre = _prefix(src)
    scene = bpy.context.scene
    # half a turn when the capture's right side is at -X (Mixamo's facing)
    r = src.matrix_world @ src.data.bones[pre + "RightUpLeg"].head_local
    l = src.matrix_world @ src.data.bones[pre + "LeftUpLeg"].head_local
    G = Matrix.Rotation(math.pi, 4, "Z") if r.x < l.x else Matrix.Identity(4)
    qG = G.to_quaternion()
    rest = {}
    for name in set(SOURCE.values()) | set(SOURCE_CHILD.values()):
        b = src.data.bones.get(pre + name)
        if b:
            rest[name] = _decompose(G @ src.matrix_world @ b.matrix_local)
    frames = []
    for f in range(start, end + 1):
        scene.frame_set(f)
        row = {}
        for name in set(SOURCE.values()):
            pb = src.pose.bones[pre + name]
            row[name] = _decompose(G @ src.matrix_world @ pb.matrix)
        frames.append(row)
    return rest, frames


def _align(rest, joint):
    """Swing that takes our rest segment onto the capture's rest segment."""
    s = SOURCE[joint]
    child = SOURCE_CHILD.get(s)
    if not child or child not in rest or joint not in OUR_DIR:
        return Quaternion()
    d_src = (rest[child][0] - rest[s][0]).normalized()
    d_our = nd_rig.rb(OUR_DIR[joint]).normalized()
    return d_our.rotation_difference(d_src)


def track(src, start, end, place="inplace", scale=None):
    """The capture as a pose track on our rig: {"q": {joint: [local Quaternion
    per capture frame]}, "loc": [root Vector (Roblox axes, studs)], "fps": 30,
    "travel": (x, z) studs over the clip}. place: "inplace" keeps the hips'
    height only (the engine moves the body); "full" keeps the travel too;
    "still" keeps nothing."""
    rest, frames = sample(src, start, end)
    align = {j: _align(rest, j) for j in nd_rig.ORDER}
    rest_q = {n: rest[n][1] for n in SOURCE.values()}
    hips0 = rest["Hips"][0]
    k = scale or (nd_rig.ROOT_HEIGHT / max(hips0.z, 1e-3))
    out = {"q": {j: [] for j in nd_rig.ORDER}, "loc": [], "fps": 30}
    first = None
    for row in frames:
        world = {}
        for j in nd_rig.ORDER:
            s = SOURCE[j]
            delta = row[s][1] @ rest_q[s].inverted()
            world[j] = QB_INV @ (delta @ align[j]) @ QB     # chain product in Roblox frames
        for j in nd_rig.ORDER:
            p = PARENT[j]
            q = world[j] if p is None else world[p].inverted() @ world[j]
            out["q"][j].append(q.normalized())
        rbx = B_INV @ ((row["Hips"][0] - hips0) * k)          # Roblox axes (x right, y up, z back)
        if first is None:
            first = rbx.copy()
        if place == "inplace":
            out["loc"].append(Vector((0, rbx.y, 0)))
        elif place == "full":
            out["loc"].append(rbx)
        else:
            out["loc"].append(Vector((0, 0, 0)))
    last = B_INV @ ((frames[-1]["Hips"][0] - hips0) * k)
    out["travel"] = (last.x - first.x, last.z - first.z)
    return out


def bake(arm, tr, name, loop=False, meta=None, markers=None):
    """Keys a track on `arm` as action `name` (60 fps frames)."""
    act = nd_anim.new_action(arm, name)
    step = nd_anim.FPS // tr.get("fps", 30)
    n = len(tr["loc"])
    # one hemisphere per joint (q and -q are the same turn; keys that swap
    # sign between frames tumble the segment in between)
    for j in nd_rig.ORDER:
        qs = tr["q"][j]
        for i in range(1, len(qs)):
            if qs[i].dot(qs[i - 1]) < 0:
                qs[i] = -qs[i]
    for i in range(n):
        for j in nd_rig.ORDER:
            pb = arm.pose.bones[j]
            pb.rotation_quaternion = tr["q"][j][i]
            pb.keyframe_insert("rotation_quaternion", frame=i * step)
        root = arm.pose.bones["Root"]
        root.location = tr["loc"][i]
        root.keyframe_insert("location", frame=i * step)
    for fc in act.fcurves:
        for kp in fc.keyframe_points:
            kp.interpolation = "LINEAR"
    act["nd_loop"] = bool(loop)
    m = {"source": "mixamo"}
    m.update(meta or {})
    act["nd_meta"] = m
    if markers:
        act["nd_markers"] = {k: v * nd_anim.FPS for k, v in markers.items()}
    return act


def retarget(src, arm, start, end, name, place="inplace", loop=False, scale=None):
    """track() + bake(): the raw capture on our rig (nd_meta: its travel)."""
    tr = track(src, start, end, place, scale)
    return bake(arm, tr, name, loop, {"travel_x": round(tr["travel"][0], 3), "travel_z": round(tr["travel"][1], 3),
                                      "frames": len(tr["loc"])})
