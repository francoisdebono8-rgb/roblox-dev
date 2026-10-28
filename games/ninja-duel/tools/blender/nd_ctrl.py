"""Control rig: the animator's rig for Ninja Duel (DEC-028, ANIM-001).

The deform rig of nd_rig is the game's skeleton (one bone per Motor6D, every
bone in Roblox axes). It is not something an animator can work with: feet
float unless every frame is solved, the hips cannot be placed in the world.
This module builds the rig an animator actually poses, in Blender:

  root            the character's place on the floor (travel, facing)
  cog             the hips: centre of gravity, offset from the HumanoidRootPart
  spine, neck     chest and head (FK)
  shoulder/forearm/hand .R/.L   arms (FK, arcs are drawn with them)
  thigh/shin/foot .R/.L         legs, driven by IK
  foot_ik.R/.L    WORLD-space feet: where a foot is planted it stays there,
                  keyed once for the whole contact (no sliding by design)
  knee_pole.R/.L  where each knee points (rides with its foot)

Body boxes are parented to the control bones, so what the viewport and the
preview films show is exactly the posed control rig. retarget() then reads
the evaluated bones and computes the Motor6D transforms of every joint in
Roblox axes (C0^-1 * Part0^-1 * Part1 * C1), the same rows as nd_io.export:
the game plays exactly the body drawn in Blender, IK included.

Authoring happens on the control bones with keyframes and F-curve shaping
(nd_shot), the .blend files are the source of truth; scripts only build,
check, export and film.
"""
import bpy, math
from mathutils import Matrix, Vector, Quaternion
from nd_rig import PARTS, JOINTS, B, rb, FIGHTERS, material, ROOT_HEIGHT
import nd_anim

H = ROOT_HEIGHT
BT = B.transposed()


def bl(p):
    """HumanoidRootPart-space point (Roblox axes, character at rest) -> armature space."""
    return rb(p) + Vector((0, 0, H))


# name: (head, tail, parent) in armature space at rest; the character faces +Y.
def _bones():
    d = {
        "root": (Vector((0, 0, 0)), Vector((0, 1.2, 0)), None),
        "cog": (bl((0, 0, 0)), bl((0, .6, 0)), "root"),
        "spine": (bl(JOINTS["Waist"][0]), bl(JOINTS["Neck"][0]), "cog"),
        "neck": (bl(JOINTS["Neck"][0]), bl((0, 2.9, 0)), "spine"),
    }
    for side, s in (("R", 1), ("L", -1)):
        n = "Right" if s > 0 else "Left"
        d["shoulder." + side] = (bl(JOINTS[n][0]), bl(JOINTS[n + "Elbow"][0]), "spine")
        d["forearm." + side] = (bl(JOINTS[n + "Elbow"][0]), bl(JOINTS[n + "Wrist"][0]), "shoulder." + side)
        d["hand." + side] = (bl(JOINTS[n + "Wrist"][0]), bl((s * 1.45, -.9, 0)), "forearm." + side)
        # (The knee sits 0.05 forward of the straight line: Blender's IK cannot
        # choose a bend for a perfectly straight chain and leaves it straight.)
        knee = bl(JOINTS[n + "Knee"][0]) + Vector((0, .05, 0))
        d["thigh." + side] = (bl(JOINTS[n + "Hip"][0]), knee, "cog")
        d["shin." + side] = (knee, bl(JOINTS[n + "Ankle"][0]), "thigh." + side)
        ankle = bl(JOINTS[n + "Ankle"][0])
        d["foot." + side] = (ankle, ankle + Vector((0, .6, 0)), "shin." + side)
        d["foot_ik." + side] = (ankle, ankle + Vector((0, .6, 0)), None)
        # (Not parented to the foot: a pole that tilts with the toes flips the
        # knee when the foot points down behind or up in front.)
        d["knee_pole." + side] = (ankle + Vector((0, 3.0, 1.0)), ankle + Vector((0, 3.0, 1.4)), None)
    return d


BONES = _bones()
# Roblox part -> control bone that carries it.
CARRY = {"LowerTorso": "cog", "Sash": "cog", "UpperTorso": "spine", "Head": "neck", "Hair": "neck", "Eyes": "neck", "HairBack": "neck"}
for _side, _n in (("R", "Right"), ("L", "Left")):
    CARRY[_n + "UpperArm"] = "shoulder." + _side
    CARRY[_n + "LowerArm"] = "forearm." + _side
    CARRY[_n + "Hand"] = "hand." + _side
    CARRY[_n + "UpperLeg"] = "thigh." + _side
    CARRY[_n + "LowerLeg"] = "shin." + _side
    CARRY[_n + "Foot"] = "foot." + _side
# Motor6D joint -> (Part0, Part1); pivots from nd_rig.JOINTS.
MOTORS = {"Root": ("HRP", "LowerTorso"), "Waist": ("LowerTorso", "UpperTorso"), "Neck": ("UpperTorso", "Head")}
for _n in ("Right", "Left"):
    MOTORS[_n] = ("UpperTorso", _n + "UpperArm")
    MOTORS[_n + "Elbow"] = (_n + "UpperArm", _n + "LowerArm")
    MOTORS[_n + "Wrist"] = (_n + "LowerArm", _n + "Hand")
    MOTORS[_n + "Hip"] = ("LowerTorso", _n + "UpperLeg")
    MOTORS[_n + "Knee"] = (_n + "UpperLeg", _n + "LowerLeg")
    MOTORS[_n + "Ankle"] = (_n + "LowerLeg", _n + "Foot")
# Control bone that a joint's rotation is posed on (same pivot as the joint).
JOINT_BONE = {"Waist": "spine", "Neck": "neck"}
for _side, _n in (("R", "Right"), ("L", "Left")):
    JOINT_BONE[_n] = "shoulder." + _side
    JOINT_BONE[_n + "Elbow"] = "forearm." + _side
    JOINT_BONE[_n + "Wrist"] = "hand." + _side
CENTRE = {p: Vector(v[0]) for p, v in PARTS.items()}
CENTRE["HRP"] = Vector((0, 0, 0))


def part_rest(part):
    """Rest matrix of a part in armature space (Roblox part axes, B)."""
    m = Matrix(B).to_4x4()
    m.translation = bl(CENTRE[part])
    return m


def build(name="Sasuke", fighter="Lion", offset=(0, 0, 0)):
    data = bpy.data.armatures.new(name + "Ctrl")
    arm = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(arm)
    arm.location = Vector(offset)
    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.selected_objects:
        o.select_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bname, (head, tail, parent) in BONES.items():
        eb = data.edit_bones.new(bname)
        eb.head, eb.tail = head, tail
        eb.roll = 0
    for bname, (head, tail, parent) in BONES.items():
        if parent:
            data.edit_bones[bname].parent = data.edit_bones[parent]
            data.edit_bones[bname].use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    for side in ("R", "L"):
        ik = arm.pose.bones["shin." + side].constraints.new("IK")
        ik.target, ik.subtarget = arm, "foot_ik." + side
        ik.pole_target, ik.pole_subtarget = arm, "knee_pole." + side
        ik.chain_count = 2
        ik.use_stretch = False
        ik.iterations = 800
        ik.pole_angle = math.radians(-90)
        cr = arm.pose.bones["foot." + side].constraints.new("COPY_ROTATION")
        cr.target, cr.subtarget = arm, "foot_ik." + side
    # Pick the pole angle that leaves the rest pose exactly at rest.
    best = None
    for a in (-90, 90, 0, 180):
        for side in ("R", "L"):
            arm.pose.bones["shin." + side].constraints["IK"].pole_angle = math.radians(a)
        bpy.context.view_layer.update()
        err = sum(max(abs(x) for row in (arm.pose.bones[b].matrix.to_3x3() - arm.data.bones[b].matrix_local.to_3x3()) for x in row)
                  for b in ("thigh.R", "thigh.L", "shin.R", "shin.L"))
        if best is None or err < best[1]:
            best = (a, err)
    for side in ("R", "L"):
        arm.pose.bones["shin." + side].constraints["IK"].pole_angle = math.radians(best[0])
    arm["nd_pole_angle"] = best[0]
    arm["nd_rest_error"] = best[1]
    colours = dict(FIGHTERS.get(fighter, FIGHTERS["Lion"]))
    colours["outfitR"] = tuple(min(255, int(c * 1.6 + 20)) for c in colours["outfit"])
    colours["pantsR"] = tuple(min(255, int(c * 1.6 + 20)) for c in colours["pants"])
    for part, (centre, size, _bone, tone) in PARTS.items():
        bpy.ops.mesh.primitive_cube_add(size=1)
        box = bpy.context.active_object
        box.name = name + "_" + part
        box.scale = (size[0], size[2], size[1])
        box.data.materials.append(material(fighter + "_" + tone, colours[tone]))
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        box.parent = arm
        box.parent_type = "BONE"
        box.parent_bone = CARRY[part]
        box.matrix_world = arm.matrix_world @ Matrix.Translation(bl(centre))
        box["nd_part"] = part
    arm["nd_fighter"] = fighter
    return arm


# ------------------------------------------------------------ posing helpers
def local_rot(arm, bone, R_rbx):
    """A rotation in Roblox joint axes -> the control bone's local quaternion."""
    rest = arm.data.bones[bone].matrix_local.to_3x3()
    return (rest.transposed() @ (B @ R_rbx @ BT) @ rest).to_quaternion()


def pose_bones(arm, spec):
    """spec (nd_anim vocabulary + world feet) -> {bone: (quat or None, loc or None)}.

      travel {x, z, yaw}      the HumanoidRootPart on the floor (Roblox world axes)
      root   {x,y,z,pitch,yaw,roll}  hips relative to the HumanoidRootPart
      torso, head, ra, la     as nd_anim
      rf/lf  {x, y, z, yaw, toe, knee}  WORLD ankle position (Roblox axes:
             x right, y up from the planted height, z back) and the knee's
             direction (degrees, + outward)
    """
    out = {}
    tr = spec.get("travel", {})
    out["root"] = (Quaternion((0, 0, 1), math.radians(-tr.get("yaw", 0))), rb((tr.get("x", 0), 0, tr.get("z", 0))))
    r = spec.get("root", {})
    out["cog"] = (local_rot(arm, "cog", nd_anim.ori(r)),
                  arm.data.bones["cog"].matrix_local.to_3x3().transposed() @ rb((r.get("x", 0), r.get("y", 0), r.get("z", 0))))
    out["spine"] = (local_rot(arm, "spine", nd_anim.ori(spec.get("torso"))), None)
    out["neck"] = (local_rot(arm, "neck", nd_anim.ori(spec.get("head"))), None)
    for side, key in (("R", "ra"), ("L", "la")):
        sh, el, wr = nd_anim.arm_rot(side, spec.get(key))
        out["shoulder." + side] = (local_rot(arm, "shoulder." + side, sh), None)
        out["forearm." + side] = (local_rot(arm, "forearm." + side, el), None)
        out["hand." + side] = (local_rot(arm, "hand." + side, wr), None)
    for side, key in (("R", "rf"), ("L", "lf")):
        s = 1 if side == "R" else -1
        f = spec.get(key, {})
        rest_head = arm.data.bones["foot_ik." + side].head_local
        world = Vector((.5 * s + f.get("x", 0), -2.6 + H + f.get("y", 0), f.get("z", 0)))  # Roblox world (floor y=0)
        target = rb(world)
        R = nd_anim.R(0, -f.get("yaw", 0), 0) @ nd_anim.R(f.get("toe", 0), 0, 0)
        ik_rest = arm.data.bones["foot_ik." + side].matrix_local.to_3x3()
        out["foot_ik." + side] = (local_rot(arm, "foot_ik." + side, R), ik_rest.transposed() @ (target - rest_head))
        # The knee points ahead of the PELVIS (its yaw, half-way to the foot's,
        # turned by `knee`), from the middle of the hip-ankle line: legs that
        # swing under the body or kick above the hips never cross the pole,
        # so the knee never flips.
        if r.get("tuck"):
            # Somersault (root "tuck": 1): the pelvis pitches through 360, so
            # the knee aims along the PELVIS's own forward (tipped up a little),
            # from the real (rotated) hip: a tucked leg folds toward the chest
            # whatever way up the body is.
            Rp = nd_anim.R(0, -tr.get("yaw", 0), 0) @ nd_anim.ori(r)
            hip = rb(Vector((tr.get("x", 0) + r.get("x", 0), H + r.get("y", 0), tr.get("z", 0) + r.get("z", 0))) + Rp @ Vector((.5 * s, -.55, 0)))
            ahead = rb(Rp @ Vector((0, .3, -1))).normalized()
            pole_world = (hip + target) * .5 + ahead * 3.0
            pole = arm.data.bones["knee_pole." + side]
            out["knee_pole." + side] = (None, pole.matrix_local.to_3x3().transposed() @ (pole_world - pole.head_local))
            continue
        hip_y = H + r.get("y", 0) - .55
        hip = rb((tr.get("x", 0) + r.get("x", 0) + .5 * s, hip_y, tr.get("z", 0) + r.get("z", 0)))
        a = math.radians(tr.get("yaw", 0) + r.get("yaw", 0) * .5 + f.get("yaw", 0) * .5 + f.get("knee", 0) * s)
        ahead = Vector((math.sin(a), math.cos(a), 0.0))
        # The knee aims ahead, tilted the way a real knee goes: down-forward
        # when the heel is folded up behind (sprint recovery), up-forward when
        # the foot is high in front (a kick). Without the tilt the pole lies on
        # the leg's own line in those poses and the knee flips.
        leg = target - hip
        dz = leg.dot(ahead)
        dy = leg.z
        tilt = max(-1.2, min(2.0, dy + 1.0)) * max(-1.0, min(1.0, dz / .6))
        ahead = (ahead + Vector((0, 0, tilt))).normalized()
        pole_world = (hip + target) * .5 + ahead * 3.0
        pole = arm.data.bones["knee_pole." + side]
        out["knee_pole." + side] = (None, pole.matrix_local.to_3x3().transposed() @ (pole_world - pole.head_local))
    return out


# ------------------------------------------------------------- retargeting
def _to_roblox(m):
    """Armature-space matrix of a part -> Roblox CFrame (4x4, Roblox world axes)."""
    out = Matrix.Identity(4)
    out.translation = BT @ m.translation
    rot = BT @ m.to_3x3()
    for i in range(3):
        for j in range(3):
            out[i][j] = rot[i][j]
    return out


def part_frames(arm):
    """Evaluated part CFrames (Roblox axes), including the HumanoidRootPart."""
    out = {}
    for part, bone in CARRY.items():
        pb = arm.pose.bones[bone]
        m = pb.matrix @ arm.data.bones[bone].matrix_local.inverted() @ part_rest(part)
        out[part] = _to_roblox(m)
    root = arm.pose.bones["root"]
    hrp = root.matrix @ arm.data.bones["root"].matrix_local.inverted() @ part_rest("HRP")
    out["HRP"] = _to_roblox(hrp)
    return out


def retarget(arm):
    """Motor6D transforms (Roblox axes) of the evaluated control rig."""
    frames = part_frames(arm)
    out = {}
    for joint, (p0, p1) in MOTORS.items():
        pivot = Vector(JOINTS[joint][0])
        c0 = Matrix.Translation(pivot - CENTRE[p0])
        c1 = Matrix.Translation(pivot - CENTRE[p1])
        out[joint] = c0.inverted() @ frames[p0].inverted() @ frames[p1] @ c1
    return out


def check_rest(arm):
    """At rest every joint transform must be the identity (exact retarget)."""
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    bpy.context.view_layer.update()
    worst = 0.0
    for joint, m in retarget(arm).items():
        worst = max(worst, max(abs((m - Matrix.Identity(4))[i][j]) for i in range(4) for j in range(4)))
    return worst
