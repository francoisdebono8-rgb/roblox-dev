"""Interactive posing in the Blender UI (the animator's loop): pose the
control rig on the current frame, look at it in the viewport, adjust, then
key it. show() never keys; key() keys the shown pose on a frame; the action
is shaped afterwards (spacing) and refined in the Graph Editor."""
import bpy
import nd_ctrl, nd_shot
from nd_shot import merge

POSE_BONES = nd_shot.POSE_BONES
SHOT = {}


def apply(arm, spec):
    pose = nd_ctrl.pose_bones(arm, spec)
    for bone in POSE_BONES:
        q, loc = pose[bone]
        pb = arm.pose.bones[bone]
        if q is not None:
            pb.rotation_quaternion = q
        if loc is not None:
            pb.location = loc
    bpy.context.view_layer.update()


def show(arm, base, over=None):
    spec = merge(base, over or {})
    apply(arm, spec)
    return spec


def new_action(arm, name):
    act = bpy.data.actions.get(name)
    if act:
        bpy.data.actions.remove(act)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    arm.animation_data_create()
    arm.animation_data.action = act
    if hasattr(act, "slots") and hasattr(arm.animation_data, "action_slot"):
        try:
            slot = act.slots.new(id_type='OBJECT', name=arm.name)
            arm.animation_data.action_slot = slot
        except Exception:
            pass
    SHOT.clear()
    return act


def key(frame, spec, spacing="ease"):
    SHOT[frame] = (spec, spacing)


def build(arm, name, markers=None, loop=False, drags=()):
    sh = nd_shot.Shot(arm, name)
    for f in sorted(SHOT):
        spec, sp = SHOT[f]
        sh.key(f, spec, sp)
    for bones, n in drags:
        sh.drag(bones, n)
    act = sh.build(markers=markers, loop=loop)
    arm.animation_data.action = act
    s = bpy.context.scene
    s.frame_start, s.frame_end = int(act.frame_range[0]), int(act.frame_range[1])
    return act
