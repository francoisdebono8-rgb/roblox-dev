"""Itachi (Mirage) jutsu pass v2 - WORK IN PROGRESS (first save: the current
clips ported so every clip name exists; each jutsu is then re-authored in
place)."""
import math, os
import bpy
from mathutils import Matrix, Vector
import nd_mocap, nd_anim
import itachi_p3, jutsu_itachi, common_e9
from itachi_p3 import STANCE
from jutsu_sasuke import ZERO, SEAL, seal, weave, stance_fn
from nd_shot import Shot, merge

N = "Mirage."
WANT = ("Mirage.Awaken", "Mirage.CrowGenjutsu.Channel", "Mirage.CrowGenjutsu.Recover", "Mirage.CrowGenjutsu.Release",
        "Mirage.ExplodingClone.Channel", "Mirage.ExplodingClone.Recover", "Mirage.ExplodingClone.Release",
        "Mirage.FireBloom.Channel", "Mirage.FireBloom.Hold", "Mirage.FireBloom.Recover", "Mirage.FireBloom.Release",
        "Mirage.MirageCast.Channel", "Mirage.MirageCast.Recover", "Mirage.MirageCast.Release",
        "Mirage.NeedleFan.Channel", "Mirage.NeedleFan.Recover", "Mirage.NeedleFan.Release",
        "Mirage.PhoenixSageFire.Channel", "Mirage.PhoenixSageFire.Recover", "Mirage.PhoenixSageFire.Release",
        "Mirage.Read.Channel", "Mirage.Read.Recover", "Mirage.Read.Release", "Mirage.Throw", "Mirage.Throw.Shuriken")
s, at = stance_fn(STANCE)
RF, LF = STANCE["rf"], STANCE["lf"]


# ================================================== captures -> control rig
# nd_mocap bakes a capture onto the DEFORM rig (joint quaternions); the jutsu
# are authored on the CONTROL rig (nd_ctrl: root/torso/head angles, arm
# raise/out/twist, world feet). cap() reads the same track and inverts the
# control rig's own formulas (nd_anim.ori = Rx Ry Rz of the negated angles,
# nd_anim.arm_rot = Rx(raise) Rz(out) Ry(twist)), so a capture frame becomes
# an ordinary pose spec: it can be keyed, merged with Itachi's carriage and
# blended with key poses like any other.
MIXAMO = os.environ.get("ND_MIXAMO", "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo")
_CAPS = {}
D = math.degrees


def _ori(m):
    e = m.to_euler("ZYX")          # m = Rx(x) Ry(y) Rz(z)
    return {"pitch": -D(e.x), "yaw": -D(e.y), "roll": -D(e.z)}


def _arm(side, qs, qe, qw):
    k = 1 if side == "R" else -1
    e = qs.to_matrix().to_euler("YZX")     # Rx(raise) Rz(out) Ry(twist)
    el = qe.to_matrix().to_euler("YZX")
    w = qw.to_matrix().to_euler("ZYX")
    return {"raise": D(e.x), "out": D(e.z) * k, "twist": D(e.y) * k, "elbow": D(el.x), "wrist": D(w.x), "wroll": D(w.z) * k}


def _foot(side, root, Rr, qh, qk, qa):
    k = 1 if side == "R" else -1
    Rh = Rr @ qh.to_matrix()
    Rk = Rh @ qk.to_matrix()
    Ra = Rk @ qa.to_matrix()
    hip = root + Rr @ Vector((.5 * k, -.55, 0))
    ank = hip + Rh @ Vector((0, -nd_anim.L1, 0)) + Rk @ Vector((0, -nd_anim.L2, 0))
    e = Ra.to_euler("XYZ")                 # Ry(-yaw) Rx(toe)
    return {"x": ank.x - .5 * k, "y": ank.y + 2.6, "z": ank.z, "yaw": -D(e.y), "toe": D(e.x)}


def cap(key, yaw=0.0):
    """The capture `key` as a list of control-rig specs (one per capture
    frame, 30 fps), turned `yaw` degrees about the vertical; the hips' x/z
    are relative to the first frame."""
    if (key, yaw) in _CAPS:
        return _CAPS[(key, yaw)]
    scene = bpy.context.scene
    fps, frame = scene.render.fps, scene.frame_current
    objs, acts = set(bpy.data.objects), set(bpy.data.actions)
    src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
    tr = nd_mocap.track(src, s0, s1, "full")
    for o in set(bpy.data.objects) - objs:
        bpy.data.objects.remove(o, do_unlink=True)
    for a in set(bpy.data.actions) - acts:
        bpy.data.actions.remove(a)
    scene.render.fps = fps
    scene.frame_set(frame)
    turn = nd_anim.R(0, -yaw, 0)
    q = tr["q"]
    x0, z0 = tr["loc"][0].x, tr["loc"][0].z
    out = []
    for i in range(len(tr["loc"])):
        loc = tr["loc"][i]
        p = turn @ Vector((loc.x - x0, loc.y, loc.z - z0))
        Rr = turn @ q["Root"][i].to_matrix()
        spec = {"root": dict(_ori(Rr), x=p.x, y=p.y, z=p.z),
                "torso": _ori(q["Waist"][i].to_matrix()), "head": _ori(q["Neck"][i].to_matrix()),
                "ra": _arm("R", q["Right"][i], q["RightElbow"][i], q["RightWrist"][i]),
                "la": _arm("L", q["Left"][i], q["LeftElbow"][i], q["LeftWrist"][i])}
        for side, f, n in (("R", "rf", "Right"), ("L", "lf", "Left")):
            spec[f] = _foot(side, p, Rr, q[n + "Hip"][i], q[n + "Knee"][i], q[n + "Ankle"][i])
        out.append(spec)
    _CAPS[(key, yaw)] = out
    return out


def mix(a, b, w):
    """a -> b by w (0..1), channel by channel (numbers only)."""
    out = {}
    for part in set(a) | set(b):
        pa, pb = a.get(part, {}), b.get(part, {})
        out[part] = {}
        for k in set(pa) | set(pb):
            va, vb = pa.get(k, pb.get(k, 0)), pb.get(k, pa.get(k, 0))
            out[part][k] = va + (vb - va) * w
    return out


def sample(c, x):
    """Capture spec at fractional capture frame x."""
    x = min(max(x, 0), len(c) - 1)
    i = int(math.floor(x))
    j = min(len(c) - 1, i + 1)
    return mix(c[i], c[j], x - i)


def warp_time(src, dst, t):
    """Piecewise-linear: output frame t -> capture frame (src/dst marks)."""
    for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
        if b0 <= t <= b1:
            return a0 + (a1 - a0) * (t - b0) / max(b1 - b0, 1e-6)
    return src[-1] if t > dst[-1] else src[0]


def author(arm):
    acts = []
    acts += itachi_p3.read(arm)
    acts += itachi_p3.needle_fan(arm)
    acts += itachi_p3.mirage_cast(arm)
    acts += itachi_p3.fire_bloom(arm)
    acts.append(itachi_p3.throw_shuriken(arm))
    acts.append(itachi_p3.awaken(arm))
    acts += jutsu_itachi.crows(arm)
    acts += jutsu_itachi.clone(arm)
    acts += jutsu_itachi.paralysis(arm)
    acts += jutsu_itachi.phoenix(arm)
    acts.append(common_e9.throw(arm, N, merge(ZERO, STANCE)))
    names = {a.name for a in acts}
    missing = [n for n in WANT if n not in names]
    if missing:
        print("MISSING", missing)
    return [a for a in acts if a.name in WANT]
