"""Jutsu pass v2, Minato (Flashstep). WORK IN PROGRESS: port of the current
clips first (every clip name exists), re-authored clip by clip below.
"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
from mathutils import Vector, Quaternion
from nd_shot import Shot, merge
from clips_flash2 import STANCE
from jutsu_sasuke import ZERO, SEAL, stance_fn, weave, act as split_act
import clips_flash2, minato_p4, jutsu_minato, common_e9

N = "Flashstep."
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo"
s, at = stance_fn(STANCE)
BASE = s()


# ------------------------------------------------------------ captures
# A Mixamo capture (nd_mocap.track: local joint rotations in Roblox frames)
# read back as control-rig specs (raise/out/twist/elbow/wrist, root/torso/
# head pitch-yaw-roll, world feet), so it can be warped onto the game's
# timing, restyled and blended with key poses inside a Shot like any key.
_CACHE = {}


def capture(key):
    """The capture `key` as a track (cached; the FBX objects are removed)."""
    if key in _CACHE:
        return _CACHE[key]
    import bpy, nd_mocap
    before = set(bpy.data.objects)
    src, s0, s1, _ = nd_mocap.import_fbx(os.path.join(MIXAMO, "mixamo_%s.fbx" % key))
    tr = nd_mocap.track(src, s0, s1, "full")
    for o in set(bpy.data.objects) - before:
        bpy.data.objects.remove(o, do_unlink=True)
    _CACHE[key] = tr
    return tr


def _deg(x):
    return math.degrees(x)


def _ori_inv(q):
    """nd_anim.ori inverse: Rx(-pitch) Ry(-yaw) Rz(-roll)."""
    e = q.to_matrix().to_euler("ZYX")
    return {"pitch": -_deg(e.x), "yaw": -_deg(e.y), "roll": -_deg(e.z)}


def _arm_inv(side, sh, el, wr):
    """nd_anim.arm_rot inverse: shoulder Rx(raise) Rz(out s) Ry(twist s),
    elbow Rx(elbow), wrist Rx(wrist) Rz(wroll s)."""
    sg = 1 if side == "R" else -1
    a = sh.to_matrix().to_euler("YZX")
    e = el.to_matrix().to_euler("YZX")
    w = wr.to_matrix().to_euler("YZX")
    return {"raise": _deg(a.x), "out": _deg(a.z) * sg, "twist": _deg(a.y) * sg,
            "elbow": max(0.0, _deg(e.x)), "wrist": _deg(w.x), "wroll": _deg(w.z) * sg}


def cap_spec(tr, i):
    """Frame i (may be fractional) of a capture track as a full body spec.
    Feet: the capture's ankles (forward kinematics), HRP-relative, z/x from
    the hips' own travel removed."""
    n = len(tr["loc"])
    i = min(max(i, 0), n - 1)
    a = int(math.floor(i)); b = min(n - 1, a + 1); u = i - a

    def q(j):
        qa, qb = tr["q"][j][a], tr["q"][j][b]
        if qa.dot(qb) < 0:
            qb = -qb
        return qa.slerp(qb, u)
    loc = tr["loc"][a].lerp(tr["loc"][b], u)
    spec = {"root": dict(_ori_inv(q("Root")), x=0.0, y=loc.y, z=0.0),
            "torso": _ori_inv(q("Waist")), "head": _ori_inv(q("Neck")),
            "ra": _arm_inv("R", q("Right"), q("RightElbow"), q("RightWrist")),
            "la": _arm_inv("L", q("Left"), q("LeftElbow"), q("LeftWrist"))}
    Mr = q("Root").to_matrix()
    p = Vector((0, loc.y, 0))
    for side, sg, name in (("rf", 1, "Right"), ("lf", -1, "Left")):
        Mt = Mr @ q(name + "Hip").to_matrix()
        Ms = Mt @ q(name + "Knee").to_matrix()
        Mf = Ms @ q(name + "Ankle").to_matrix()
        hip = p + Mr @ Vector((.5 * sg, -.55, 0))
        ankle = hip + Mt @ Vector((0, -1.05, 0)) + Ms @ Vector((0, -1.0, 0))
        fwd = Mf @ Vector((0, 0, -1))
        yaw = _deg(math.atan2(fwd.x, -fwd.z))
        spec[side] = {"x": ankle.x - .5 * sg, "y": ankle.y + 2.6, "z": ankle.z, "yaw": yaw,
                      "toe": _deg(math.asin(max(-1, min(1, fwd.y))))}
    # (the hips' travel in the capture: feet relative to the moving hips)
    spec["_hips"] = (loc.x, loc.z)
    return spec


def speeds(tr, joint_tip="RightWrist"):
    """Per-frame speed (studs/s) of a hand, from forward kinematics."""
    out = []
    prev = None
    for i in range(len(tr["loc"])):
        pos = hand_pos(tr, i, "R" if joint_tip.startswith("Right") else "L")
        out.append(0.0 if prev is None else (pos - prev).length * tr.get("fps", 30))
        prev = pos
    return out


def hand_pos(tr, i, side):
    sg = 1 if side == "R" else -1
    name = "Right" if side == "R" else "Left"
    Mr = tr["q"]["Root"][i].to_matrix()
    Mw = Mr @ tr["q"]["Waist"][i].to_matrix()
    Ms = Mw @ tr["q"][name][i].to_matrix()
    Me = Ms @ tr["q"][name + "Elbow"][i].to_matrix()
    loc = tr["loc"][i]
    waist = loc + Mr @ Vector((0, .65, 0))
    sh = waist + Mw @ Vector((sg * 1.05, .95, 0))
    el = sh + Ms @ Vector((sg * .4, -1.05, 0))
    wr = el + Me @ Vector((0, -.93, 0))
    return wr


def lerp_spec(a, b, w, parts=None):
    """a -> b by w, channel by channel (numbers only; a channel missing on
    one side keeps the other's value)."""
    out = {}
    for part in set(a) | set(b):
        if part.startswith("_"):
            continue
        if parts is not None and part not in parts:
            out[part] = dict(a.get(part, {}))
            continue
        pa, pb = a.get(part, {}), b.get(part, {})
        d = {}
        for k in set(pa) | set(pb):
            if k in pa and k in pb:
                d[k] = pa[k] + (pb[k] - pa[k]) * w
            else:
                d[k] = pa.get(k, pb.get(k))
        out[part] = d
    return out


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def warp_frames(src, dst, f):
    """Piecewise-linear time warp: output frame f -> capture frame."""
    for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
        if b0 <= f <= b1:
            return a0 + (a1 - a0) * (f - b0) / max(b1 - b0, 1e-6)
    return src[-1] if f > dst[-1] else src[0]


def cap_track(key, src, dst, step=2):
    """[(frame, capture spec)] over the output frames dst[0]..dst[-1]: the
    capture frames `src` land on the output frames `dst`."""
    tr = capture(key)
    out = []
    f = dst[0]
    while f <= dst[-1]:
        out.append((f, cap_spec(tr, warp_frames(src, dst, f))))
        f += step
    if out[-1][0] != dst[-1]:
        out.append((dst[-1], cap_spec(tr, warp_frames(src, dst, dst[-1]))))
    return out


def author(arm):
    acts = []
    acts += clips_flash2.throws(arm)               # Throw.Kunai, Throw.MarkedKunai
    acts.append(minato_p4.wind_cut(arm))           # Throw.WindCut
    acts.append(minato_p4.dash_attack(arm))        # DashAttack
    acts += clips_flash2.ftg(arm)                  # Flashstep.Channel/Release/Recover
    acts.append(clips_flash2.rasengan(arm)[1])     # Rasengan (its channel twin is replaced next)
    acts.append(jutsu_minato.rasengan_channel(arm))  # BurstStrike.Channel
    acts += jutsu_minato.sealing_trap(arm)
    acts += jutsu_minato.space_time_barrier(arm)
    acts.append(jutsu_minato.flash_touch(arm))
    acts.append(minato_p4.awaken(arm))
    acts.append(common_e9.throw(arm, N, STANCE))   # Throw (grab throw)
    return acts
