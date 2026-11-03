"""Stick-figure contact sheets of a rig action (headless check: no GPU needed).
Front and side views per sampled frame, Roblox axes (y up), one PNG per clip."""
import bpy
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mathutils import Vector
import nd_rig, nd_anim

BONES = [("Root", "Waist"), ("Waist", "Neck"), ("Waist", "Right"), ("Waist", "Left"),
         ("Right", "RightElbow"), ("RightElbow", "RightWrist"), ("Left", "LeftElbow"), ("LeftElbow", "LeftWrist"),
         ("Root", "RightHip"), ("Root", "LeftHip"), ("RightHip", "RightKnee"), ("RightKnee", "RightAnkle"),
         ("LeftHip", "LeftKnee"), ("LeftKnee", "LeftAnkle")]
TIPS = {"Neck": (0, 1.3, 0), "RightWrist": (0, -.55, 0), "LeftWrist": (0, -.55, 0),
        "RightAnkle": (0, -.35, -.6), "LeftAnkle": (0, -.35, -.6)}
B_INV = nd_rig.B.inverted()


def points(arm):
    """Each body box's long axis (two ends, Roblox axes, studs, floor y = 0)
    for the current frame: what the player sees of the pose."""
    out = {}
    base = arm.matrix_world.translation.copy()
    base.z -= nd_rig.ROOT_HEIGHT
    for part, (centre, size, bone, _) in nd_rig.PARTS.items():
        if part in ("Eyes", "Sash", "HairBack"):
            continue
        pivot = Vector(nd_rig.JOINTS[bone][0])
        c = Vector(centre) - pivot
        half = Vector((0, 0, size[2] / 2)) if part.endswith("Foot") else Vector((0, size[1] / 2, 0))
        m = arm.matrix_world @ arm.pose.bones[bone].matrix
        out[part] = (B_INV @ ((m @ (c + half)) - base), B_INV @ ((m @ (c - half)) - base))
    return out


def sheet(arm, act, path, count=10, title=None):
    nd_anim.use(arm, act)
    start, end = int(act.frame_range[0]), int(act.frame_range[1])
    frames = [round(start + (end - start) * i / max(1, count - 1)) for i in range(count)]
    fig, axes = plt.subplots(2, count, figsize=(count * 1.6, 4.6))
    for c, f in enumerate(frames):
        bpy.context.scene.frame_set(f)
        p = points(arm)
        for r, (ax_i, label) in enumerate(((0, "front"), (2, "side"))):
            ax = axes[r][c]
            sign = 1 if ax_i == 0 else -1
            for part, (a, b) in p.items():
                colour = "#d33" if part.startswith("Right") else "#36c" if part.startswith("Left") else "#222"
                width = 5 if "Torso" in part or part == "Head" else 3
                ax.plot([a[ax_i] * sign, b[ax_i] * sign], [a.y, b.y], color=colour, lw=width, solid_capstyle="round")
            ax.axhline(0, color="#999", lw=.8)
            ax.set_xlim(-4, 4); ax.set_ylim(-.5, 7.5); ax.set_aspect("equal"); ax.axis("off")
            if r == 0:
                ax.set_title("f%d" % f, fontsize=7)
    fig.suptitle(title or act.name, fontsize=9)
    fig.tight_layout()
    fig.savefig(path, dpi=70)
    plt.close(fig)
