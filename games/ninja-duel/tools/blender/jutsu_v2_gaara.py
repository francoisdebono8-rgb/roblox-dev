"""Gaara (Sand) jutsu pass v2 -- WORK IN PROGRESS.
"""
import json, math, os
from nd_shot import Shot, merge
from gaara_p7 import STANCE, FOLD_R, FOLD_L
import gaara_p7, jutsu_gaara, gaps_e6, common_e9
from jutsu_gaara import ZERO, SEAL

N = "Sand."
F = 60.0
MIXAMO = "/mnt/user-data/uploads/Documents/NinjaDuelBlender/mixamo"
CAPS = os.environ.get("ND_CAPS", "/tmp/claude-0/-home-claude/60386c0c-0f7e-5237-92aa-0aedd11b1cac/scratchpad/v2/Sand/caps")
BASE = merge(ZERO, STANCE)
Y0 = BASE["root"]["y"]
PARTS = ("root", "torso", "head", "ra", "la")


def s(over=None):
    return merge(BASE, over or {})


# ------------------------------------------------------------ captures
def _euler(q, order):
    e = q.to_matrix().to_euler(order)
    return math.degrees(e.x), math.degrees(e.y), math.degrees(e.z)


def _decompose(tr, i):
    """One capture frame (Motor6D rotations, Roblox axes) in the pose
    vocabulary of nd_anim (the inverse of ori() and arm_rot())."""
    out = {}
    for part, j in (("root", "Root"), ("torso", "Waist"), ("head", "Neck")):
        x, y, z = _euler(tr["q"][j][i], "ZYX")
        out[part] = {"pitch": -x, "yaw": -y, "roll": -z}
    out["root"]["y"] = tr["loc"][i].y
    for key, side, sg in (("ra", "Right", 1), ("la", "Left", -1)):
        x, y, z = _euler(tr["q"][side][i], "YZX")
        el = _euler(tr["q"][side + "Elbow"][i], "YZX")[0]
        wx, _, wz = _euler(tr["q"][side + "Wrist"][i], "ZYX")
        out[key] = {"raise": x, "out": z * sg, "twist": y * sg, "elbow": el, "wrist": wx, "wroll": wz * sg}
    return out


def capture(key):
    """A Mixamo capture as pose-vocabulary frames (30 fps), unwrapped; cached."""
    path = os.path.join(CAPS, key + ".json")
    if os.path.exists(path):
        with open(path) as fh:
            return json.load(fh)
    import bpy, nd_mocap
    fbx = os.path.join(MIXAMO, "mixamo_%s.fbx" % key)
    if not os.path.exists(fbx):
        print("WARN no capture", key)
        return None
    scene = bpy.context.scene
    fps, frame, active = scene.render.fps, scene.frame_current, bpy.context.view_layer.objects.active
    objs, arms, acts = set(bpy.data.objects), set(bpy.data.armatures), set(bpy.data.actions)
    src, s0, s1, _ = nd_mocap.import_fbx(fbx)
    tr = nd_mocap.track(src, s0, s1, "inplace")
    frames = [_decompose(tr, i) for i in range(len(tr["loc"]))]
    for o in set(bpy.data.objects) - objs:
        bpy.data.objects.remove(o, do_unlink=True)
    for a in set(bpy.data.armatures) - arms:
        bpy.data.armatures.remove(a)
    for a in set(bpy.data.actions) - acts:
        bpy.data.actions.remove(a)
    scene.render.fps = fps
    scene.frame_set(frame)
    bpy.context.view_layer.objects.active = active
    # unwrap the angles frame to frame (no 360 jumps)
    for i in range(1, len(frames)):
        for part, v in frames[i].items():
            for k, x in v.items():
                if k == "y":
                    continue
                p = frames[i - 1][part][k]
                while x - p > 180:
                    x -= 360
                while x - p < -180:
                    x += 360
                v[k] = x
    try:
        os.makedirs(CAPS, exist_ok=True)
        with open(path, "w") as fh:
            json.dump(frames, fh)
    except OSError:
        pass
    return frames


def _cap_at(frames, c):
    c = min(max(c, 0), len(frames) - 1)
    a = int(math.floor(c))
    b = min(len(frames) - 1, a + 1)
    u = c - a
    return {p: {k: frames[a][p][k] * (1 - u) + frames[b][p][k] * u for k in frames[a][p]} for p in frames[a]}


def _mirror_cap(spec):
    out = {}
    for p, v in spec.items():
        v = dict(v)
        if p in ("root", "torso", "head"):
            for k in ("yaw", "roll"):
                if k in v:
                    v[k] = -v[k]
        out[{"ra": "la", "la": "ra"}.get(p, p)] = v
    return out


def smooth(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


# ------------------------------------------------------------ the timeline
class Take:
    """One continuous act (channel -> release -> recover) evaluated frame by
    frame, so the cuts meet exactly and every frame is keyed (linear at
    60 fps: the game plays exactly this).

      key(f, spec, spacing)  full-body poses, merged onto the previous one;
          spacing as nd_shot: ease (slow in/out), pass (passes through,
          monotone), impact (arrives at speed), launch (leaves at speed), hold
      lag(channels, n)       overlap: "head", "ra.wrist", "la"... follow n
          frames late (the hand last), catching up by the end
      lead(channels, n)      the same, n frames EARLY (the hips lead)
      layer(capture, src, dst, gains)  a Mixamo capture's motion, time-warped
          (capture frames src -> clip frames dst, piecewise), added as deltas
          from its first mark, faded in and out; gains per part or part.attr
      arm_from(capture, side, src, dst, weight, offset)  the capture's ARM
          itself (absolute), blended in over the key-posed arm
    """

    def __init__(self, name):
        self.name = name
        self.keys, self.shifts, self.layers, self.arms = [], {}, [], []

    def key(self, f, spec, sp="ease"):
        self.keys.append((f, spec, sp))
        return self

    def lag(self, chans, n):
        for c in chans:
            self.shifts[c] = n
        return self

    def lead(self, chans, n):
        return self.lag(chans, -n)

    def layer(self, cap, src, dst, gains, mirror=False, fade=(4, 6)):
        frames = capture(cap)
        if frames:
            self.layers.append((frames, src, dst, gains, mirror, fade))
        return self

    def arm_from(self, cap, side, src, dst, weight=1.0, offset=None, mirror=False, fade=(4, 6), to=None):
        frames = capture(cap)
        if frames:
            self.arms.append((frames, side, src, dst, weight, offset or {}, mirror, fade, to or side))
        return self

    # -------------------------------------------------------- evaluation
    def _prepare(self):
        keys = sorted(self.keys, key=lambda k: k[0])
        full, poses = BASE, []
        for f, spec, sp in keys:
            full = merge(full, spec)
            poses.append((f, full, sp))
        self.poses = poses
        self.f0, self.f1 = poses[0][0], poses[-1][0]
        chans = {}
        for part in PARTS + ("rf", "lf", "travel"):
            for k in poses[0][1].get(part, {}):
                chans[(part, k)] = None
        self.curves = {}
        n = len(poses)
        for (part, k) in chans:
            fs = [p[0] for p in poses]
            vs = [p[1].get(part, {}).get(k, 0.0) for p in poses]
            mi, mo = [0.0] * n, [0.0] * n
            for i in range(n):
                sp = poses[i][2]
                sl_p = (vs[i] - vs[i - 1]) / (fs[i] - fs[i - 1]) if i > 0 else 0.0
                sl_n = (vs[i + 1] - vs[i]) / (fs[i + 1] - fs[i]) if i < n - 1 else 0.0
                if sp == "pass" and 0 < i < n - 1:
                    if sl_p * sl_n <= 0:
                        m = 0.0
                    else:
                        m = (vs[i + 1] - vs[i - 1]) / (fs[i + 1] - fs[i - 1])
                        lim = 3 * min(abs(sl_p), abs(sl_n))
                        m = max(-lim, min(lim, m))
                    mi[i] = mo[i] = m
                elif sp == "impact":
                    mi[i] = 1.6 * sl_p
                elif sp == "launch":
                    mo[i] = 1.6 * sl_n
            self.curves[(part, k)] = (fs, vs, mi, mo, [p[2] for p in poses])

    def _eval(self, chan, t):
        fs, vs, mi, mo, sps = self.curves[chan]
        if t <= fs[0]:
            return vs[0]
        if t >= fs[-1]:
            return vs[-1]
        i = max(j for j in range(len(fs)) if fs[j] <= t)
        if i >= len(fs) - 1:
            return vs[-1]
        if sps[i] == "hold":
            return vs[i]
        d = fs[i + 1] - fs[i]
        u = (t - fs[i]) / d
        h00 = 2 * u ** 3 - 3 * u ** 2 + 1
        h10 = u ** 3 - 2 * u ** 2 + u
        h01 = -2 * u ** 3 + 3 * u ** 2
        h11 = u ** 3 - u ** 2
        return h00 * vs[i] + h10 * d * mo[i] + h01 * vs[i + 1] + h11 * d * mi[i + 1]

    def _shift(self, part, k):
        return self.shifts.get(part + "." + k, self.shifts.get(part, 0))

    def pose(self, t):
        spec = {}
        for (part, k) in self.curves:
            n = self._shift(part, k)
            tt = t
            if n:
                # n frames late (or early), easing back to 0 near both ends
                w = min(1.0, (t - self.f0) / (2 * abs(n)), (self.f1 - t) / (2 * abs(n)))
                tt = t - n * max(0.0, w)
            spec.setdefault(part, {})[k] = self._eval((part, k), tt)
        for frames, src, dst, gains, mirror, fade in self.layers:
            if not dst[0] <= t <= dst[-1]:
                continue
            ref = _cap_at(frames, src[0])
            cur = _cap_at(frames, _warp(src, dst, t))
            if mirror:
                ref, cur = _mirror_cap(ref), _mirror_cap(cur)
            w = smooth((t - dst[0]) / max(fade[0], 1e-6)) * smooth((dst[-1] - t) / max(fade[1], 1e-6))
            for part in PARTS:
                for k in cur.get(part, {}):
                    g = gains.get(part + "." + k, gains.get(part, 0.0))
                    if g and k in spec.get(part, {}):
                        spec[part][k] += g * w * (cur[part][k] - ref[part][k])
        for frames, side, src, dst, weight, offset, mirror, fade, to in self.arms:
            if not dst[0] <= t <= dst[-1]:
                continue
            cur = _cap_at(frames, _warp(src, dst, t))
            if mirror:
                cur = _mirror_cap(cur)
            w = weight * smooth((t - dst[0]) / max(fade[0], 1e-6)) * smooth((dst[-1] - t) / max(fade[1], 1e-6))
            for k, v in cur[side].items():
                v = v + offset.get(k, 0.0)
                spec[to][k] = spec[to][k] * (1 - w) + v * w
        return spec

    def frames(self):
        self._prepare()
        return [self.pose(t) for t in range(self.f0, self.f1 + 1)]


def _warp(src, dst, t):
    for (a0, a1), (b0, b1) in zip(zip(src, src[1:]), zip(dst, dst[1:])):
        if b0 <= t <= b1:
            return a0 + (a1 - a0) * (t - b0) / max(b1 - b0, 1e-6)
    return src[-1] if t > dst[-1] else src[0]


def clip(arm, name, frames, a, b, markers=None):
    """Frames a..b of an evaluated timeline as one action (keyed every frame)."""
    sh = Shot(arm, name)
    for i, f in enumerate(range(a, b + 1)):
        sh.key(i, frames[f], "linear")
    return sh.build(markers=markers or {})


def cut(arm, prefix, take, ch, rel, act, rec, rel_marker=None):
    """Channel 0..ch, Release ch..ch+rel, Recover from the Active frame
    (ch+act) for rec frames: the three meet on the very same poses."""
    fr = take.frames()
    if len(fr) - 1 < ch + act + rec:
        raise ValueError("%s: timeline %d frames < %d" % (prefix, len(fr) - 1, ch + act + rec))
    re_m = {rel_marker[0]: rel_marker[1] / F} if rel_marker else {}
    return [clip(arm, prefix + ".Channel", fr, 0, ch, {"release": ch / F}),
            clip(arm, prefix + ".Release", fr, ch, ch + rel, re_m),
            clip(arm, prefix + ".Recover", fr, ch + act, ch + act + rec)]


def seal(n, i=1, over=None):
    """Seal n made i-th, at the chin: no sink, no turn (he does not gather
    himself, the sand does); the chin dips a hair, the eyes stay on him."""
    return s(merge(merge({"root": {"y": Y0 - .008 * i}, "torso": {"pitch": -1},
                          "head": {"pitch": BASE["head"]["pitch"] + 2 + i, "yaw": -3}}, SEAL[n]), over or {}))


def held(pose, over):
    """The same pose a little further on (a hold keeps moving)."""
    return merge(pose, over)


# ================================================================ ShukakuArm
def shukaku_arm(arm):
    """Ch .3 (18) | Act .12 (7) | Rec .34 (20); Release 12 frames."""
    t = Take(N + "ShukakuArm")
    t.key(0, s(), "ease")
    t.key(4, seal(1, 1), "impact")
    t.key(7, seal(1, 1, {"head": {"pitch": 8}}), "ease")
    t.key(10, seal(2, 2), "impact")
    # the right hand leaves the seal, elbow first, up and out to his right;
    # the left forearm settles back across him
    t.key(14, s({"root": {"yaw": 8}, "torso": {"yaw": 6, "roll": -2},
                 "head": {"yaw": -8, "pitch": 4},
                 "ra": {"raise": 112, "out": 66, "twist": -6, "elbow": 84, "wrist": 16},
                 "la": merge(FOLD_L, {"raise": 54, "elbow": 112})}), "pass")
    # the giant arm grows from that shoulder: his arm stands high out to the
    # right, clawed, the chest open to that side (the wind-up of the sweep)
    raised = s({"root": {"y": Y0 + .015, "yaw": 12}, "torso": {"pitch": -4, "yaw": 13, "roll": -6},
                "head": {"pitch": 4, "yaw": -17, "roll": 3},
                "ra": {"raise": 150, "out": 58, "twist": -30, "elbow": 26, "wrist": -40}})
    t.key(18, raised, "ease")
    C = 18
    # the release: the hips lead to the left, the arm comes down to shoulder
    # height on his right (the sand arm lands on the field) ...
    t.key(C + 4, s({"root": {"y": Y0 - .01, "yaw": 9}, "torso": {"pitch": 1, "yaw": 12, "roll": -3},
                    "head": {"pitch": 6, "yaw": -15},
                    "ra": {"raise": 100, "out": 78, "twist": -22, "elbow": 14, "wrist": -34}}), "pass")
    # ... and drives flat across the field, right to left, the chest turning
    # with it; heavy: the knees give, the hand trails (the sand's weight)
    t.key(C + 10, s({"root": {"y": Y0 - .03, "yaw": 2}, "torso": {"pitch": 4, "yaw": 0, "roll": 0},
                     "head": {"pitch": 7, "yaw": -5},
                     "ra": {"raise": 96, "out": 14, "twist": -12, "elbow": 8, "wrist": -24}}), "pass")
    t.key(C + 15, s({"root": {"y": Y0 - .03, "yaw": -4}, "torso": {"pitch": 3, "yaw": -12, "roll": 2},
                     "head": {"pitch": 7, "yaw": 3},
                     "ra": {"raise": 94, "out": -34, "twist": -2, "elbow": 10, "wrist": -12}}), "pass")
    # carried on across, slowing (overshoot) ...
    left = s({"root": {"y": Y0 - .025, "yaw": -6}, "torso": {"pitch": 2, "yaw": -18, "roll": 3},
              "head": {"pitch": 7, "yaw": 6},
              "ra": {"raise": 90, "out": -56, "twist": 6, "elbow": 18, "wrist": -2}})
    t.key(C + 19, left, "ease")
    # ... and the forearm wraps in: the sweep flows into the fold
    t.key(C + 23, s({"root": {"y": Y0 - .01, "yaw": 0}, "torso": {"yaw": -8, "roll": 1}, "head": {"yaw": 0},
                     "ra": {"raise": 72, "out": -46, "twist": 30, "elbow": 92, "wrist": 0}}), "pass")
    t.key(C + 7 + 20, s(), "ease")
    t.lead(["root.yaw"], 2)
    t.lag(["head"], 2)
    t.lag(["ra.wrist"], 3)
    t.lag(["la"], 2)
    return cut(arm, N + "ShukakuArm", t, 18, 12, 7, 20, ("release", 7))


# ================================================================ SandCoffin
def sand_coffin(arm):
    """Ch .35 (21) | Act .1 (6) | Rec .35 (20); Release 6 frames."""
    t = Take(N + "SandCoffin")
    t.key(0, s(), "ease")
    # the right elbow lifts out of the fold, the forearm unfolding, hand last
    t.key(6, s({"torso": {"yaw": 3}, "head": {"pitch": 5, "yaw": -5},
                "ra": {"raise": 86, "out": 18, "twist": 24, "elbow": 96, "wrist": 22}}), "pass")
    # the arm unrolls toward him, rising ...
    t.key(11, s({"root": {"z": -.01}, "torso": {"pitch": 1, "yaw": 6},
                 "head": {"pitch": 4, "yaw": -6},
                 "ra": {"raise": 106, "out": 14, "twist": -4, "elbow": 36, "wrist": 26}}), "pass")
    # ... and opens at him, the whole arm straight, the palm open, fingers
    # spread (the sand wave runs at him)
    reach = s({"root": {"y": Y0 - .01, "z": -.02}, "torso": {"pitch": 2, "yaw": 8},
               "head": {"pitch": 3, "yaw": -7},
               "ra": {"raise": 104, "out": 12, "twist": -24, "elbow": 2, "wrist": -34},
               "la": merge(FOLD_L, {"elbow": 112, "raise": 56})})
    t.key(15, reach, "ease")
    # the fingers spread wider while it wraps him (anticipation of the close)
    wide = held(reach, {"ra": {"raise": 102, "wrist": -46, "twist": -30}, "torso": {"yaw": 9}})
    t.key(21, wide, "ease")
    C = 21
    # the crush: the fist closes, turns over and is pulled down and in;
    # the shoulder hunches over it, the knees give
    fist = s({"root": {"y": Y0 - .03, "z": -.02}, "torso": {"pitch": 5, "yaw": 6, "roll": -1},
              "head": {"pitch": 6, "yaw": -6},
              "ra": {"raise": 92, "out": 10, "twist": -64, "elbow": 34, "wrist": 34},
              "la": merge(FOLD_L, {"elbow": 114, "raise": 56})})
    t.key(C + 4, fist, "impact")
    t.key(C + 6, held(fist, {"root": {"y": Y0 - .035}, "ra": {"raise": 90, "elbow": 38, "wrist": 36}}), "ease")
    # held: the fist squeezes, trembling a hair
    t.key(C + 11, held(fist, {"root": {"y": Y0 - .03}, "ra": {"raise": 93, "elbow": 33, "wrist": 32}}), "ease")
    t.key(C + 15, held(fist, {"root": {"y": Y0 - .025}, "ra": {"raise": 91, "elbow": 36, "wrist": 35}}), "ease")
    # lowered, the elbow first, and folded
    t.key(C + 20, s({"root": {"y": Y0 - .01}, "torso": {"pitch": 1, "yaw": 2},
                     "ra": {"raise": 70, "out": -16, "twist": 26, "elbow": 96, "wrist": 6}}), "pass")
    t.key(C + 6 + 20, s(), "ease")
    t.lag(["head"], 2)
    t.lag(["ra.wrist"], 2)
    t.lag(["la"], 2)
    t.layer("cast_forward", [24, 36, 44], [4, 15, 21], {"torso.pitch": .15, "root.y": .2, "root.pitch": .1})
    return cut(arm, N + "SandCoffin", t, 21, 6, 6, 20)


def author(arm):
    acts = []
    acts += sand_coffin(arm) + gaara_p7.sand_shuriken(arm) + gaara_p7.desert_wave(arm)
    acts += gaps_e6.sand_armor(arm)
    acts += shukaku_arm(arm) + jutsu_gaara.sand_spikes(arm) + jutsu_gaara.quicksand(arm)
    acts += jutsu_gaara.third_eye(arm) + jutsu_gaara.sand_clone(arm)
    acts.append(gaara_p7.awaken(arm))
    acts.append(gaara_p7.throw_sand(arm))
    acts.append(common_e9.throw(arm, "Sand.", gaara_p7.STANCE))
    return acts
