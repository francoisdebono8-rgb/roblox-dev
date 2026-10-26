"""Ninja Duel R15 rig for Blender, matching Server/World.rig exactly.

Roblox -> Blender axes: (x, y, z)_rbx -> (x, -z, y)_bl. One Blender unit is
one stud. Every bone's rest frame IS the Roblox joint frame (bone local X =
Roblox X, local Y = Roblox Y, local Z = Roblox Z), so a pose bone's
rotation_quaternion is exactly the Motor6D.Transform rotation, and the Root
bone's location is the Root joint's Transform translation (studs, Roblox
axes). Bones therefore all point "up"; the body meshes show the real shape.
"""
import bpy
from mathutils import Matrix, Vector

# Rest centres (root space, Roblox axes) as Motor6D assembly places them
# (Part1 = pivot - C1), and sizes (Server/World.rig).
PARTS = {
    "LowerTorso": ((0, 0, 0), (2, 1, 1), "Root", "outfit"),
    "UpperTorso": ((0, 1.15, 0), (2, 1.4, 1), "Waist", "outfit"),
    "Head": ((0, 2.6, 0), (1.5, 1.5, 1.5), "Neck", "skin"),
    "Hair": ((0, 3.42, 0), (1.65, .55, 1.65), "Neck", "hair"),
    "Eyes": ((0, 2.75, -.76), (.85, .1, .05), "Neck", "ink"),
    "Sash": ((0, -.4, 0), (2.1, .25, 1.1), "Root", "accent"),
}
for side, s in (("Right", 1), ("Left", -1)):
    PARTS[side + "UpperArm"] = ((s * 1.45, 1.1, 0), (.8, 1.1, .8), side, "outfit")
    PARTS[side + "LowerArm"] = ((s * 1.45, .1, 0), (.76, .95, .76), side + "Elbow", "outfit")
    PARTS[side + "Hand"] = ((s * 1.45, -.63, 0), (.72, .5, .72), side + "Wrist", "skin")
    PARTS[side + "UpperLeg"] = ((s * .5, -1.05, 0), (.85, 1.1, .85), side + "Hip", "pants")
    PARTS[side + "LowerLeg"] = ((s * .5, -2.1, 0), (.8, 1.05, .8), side + "Knee", "pants")
    PARTS[side + "Foot"] = ((s * .5, -2.8, -.15), (.8, .42, 1.15), side + "Ankle", "pants")

# Joint pivots (root space) and parents. Names are the engine's JOINTS keys
# (Client/VelmoraMotionEngine): Right/Left are the shoulders.
JOINTS = {
    "Root": ((0, 0, 0), None),
    "Waist": ((0, .65, 0), "Root"),
    "Neck": ((0, 2.05, 0), "Waist"),
}
for side, s in (("Right", 1), ("Left", -1)):
    JOINTS[side] = ((s * 1.05, 1.6, 0), "Waist")
    JOINTS[side + "Elbow"] = ((s * 1.45, .55, 0), side)
    JOINTS[side + "Wrist"] = ((s * 1.45, -.38, 0), side + "Elbow")
    JOINTS[side + "Hip"] = ((s * .5, -.55, 0), "Root")
    JOINTS[side + "Knee"] = ((s * .5, -1.6, 0), side + "Hip")
    JOINTS[side + "Ankle"] = ((s * .5, -2.6, 0), side + "Knee")
ORDER = ["Root", "Waist", "Neck", "Right", "Left", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist",
         "RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle"]
# The HumanoidRootPart sits HipHeight + half its height above the floor.
ROOT_HEIGHT = 3.0

# Roblox -> Blender basis (columns: images of Roblox X, Y, Z).
B = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))


def rb(v):
    """Roblox vector -> Blender vector."""
    return B @ Vector(v)


FIGHTERS = {
    "Lion": {"skin": (236, 210, 190), "hair": (24, 26, 40), "outfit": (34, 40, 72), "pants": (35, 43, 54), "accent": (92, 132, 255), "ink": (24, 31, 38)},
    "Flashstep": {"skin": (240, 214, 186), "hair": (250, 214, 92), "outfit": (34, 46, 92), "pants": (35, 43, 54), "accent": (255, 214, 92), "ink": (24, 31, 38)},
    "Dummy": {"skin": (190, 190, 196), "hair": (120, 120, 130), "outfit": (120, 124, 134), "pants": (96, 100, 110), "accent": (150, 150, 160), "ink": (40, 40, 44)},
}


def material(name, rgb):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    c = tuple(v / 255 for v in rgb) + (1,)
    m.diffuse_color = c
    m.use_nodes = False
    return m


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for d in list(coll):
            if d.users == 0:
                coll.remove(d)


def build_rig(name="Sasuke", fighter="Lion", offset=(0, 0, 0)):
    """Armature + body boxes. `offset` places the rig (Blender world)."""
    arm_data = bpy.data.armatures.new(name + "Rig")
    arm = bpy.data.objects.new(name, arm_data)
    bpy.context.scene.collection.objects.link(arm)
    arm.location = Vector(offset) + Vector((0, 0, ROOT_HEIGHT))
    bpy.context.view_layer.objects.active = arm
    for o in bpy.context.selected_objects:
        o.select_set(False)
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    rest = Matrix(B).to_4x4()
    for joint in ORDER:
        pivot, parent = JOINTS[joint]
        eb = arm_data.edit_bones.new(joint)
        m = rest.copy()
        m.translation = rb(pivot)
        eb.head = rb(pivot)
        eb.tail = rb(pivot) + Vector((0, 0, .35))
        eb.matrix = m
        eb.length = .35
        if parent:
            eb.parent = arm_data.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    colours = FIGHTERS.get(fighter, FIGHTERS["Lion"])
    for part, (centre, size, bone, tone) in PARTS.items():
        bpy.ops.mesh.primitive_cube_add(size=1)
        box = bpy.context.active_object
        box.name = name + "_" + part
        box.scale = (size[0], size[2], size[1])  # Roblox (x, y, z) size -> Blender (x, z-depth, y-height)
        box.data.materials.append(material(fighter + "_" + tone, colours[tone]))
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        world = arm.matrix_world @ Matrix.Translation(rb(centre))
        box.parent = arm
        box.parent_type = "BONE"
        box.parent_bone = bone
        box.matrix_world = world
    return arm


def check_frames(arm):
    """Bone local axes must equal the Roblox axes (see module doc)."""
    bad = []
    for b in arm.data.bones:
        m = b.matrix_local.to_3x3()
        diff = max(abs(m[i][j] - B[i][j]) for i in range(3) for j in range(3))
        if diff > 1e-4:
            bad.append((b.name, round(diff, 4)))
    return bad
