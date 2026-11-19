#!/usr/bin/env python3
"""Two mechanical fixes found by the SyphoDev audit (audit_clips.py) on the game's clips.

  close_loops  a looping clip whose last sample is not its first snaps on every wrap
               (AuthoredMotion plays f % (frames - 1): the last sample must BE the first;
               a held part loops from its "loop" marker). The gap is spread over the whole
               cycle: each sample turns by its share of the rotation that carries the last
               sample onto the loop's first (the Root's translation slides the same way).
  despike      a joint that jumps more than 25 degrees for ONE sample and comes back
               (there-and-back: the samples on each side are close) is a one-frame pop -
               the IK flip of the video reads as a part changing colour. That sample of the
               WHOLE body becomes the halfway pose of its neighbours.

Used two ways:
  * tools/blender/clips_to_luau.py calls apply() in its film pass, so every export keeps them;
  * `python3 clip_passes.py src/Client/AuthoredClips*.luau src/Client/AuthoredJutsu?.luau`
    applies them in place to the generated modules, rewriting only the joints it changes
    (same format, 4 decimals, same clip and joint order).
"""
import math
import re
import sys

import numpy as np

SPIKE_DEG = 25.0
LOOP_DEG = 0.5
LOOP_MAX_DEG = 45.0  # a bigger wrap is authored (a strike that snaps back): left to the ANIMATEUR


def _norm(q):
    return q / np.linalg.norm(q, axis=-1, keepdims=True)


def _mul(a, b):
    ax, ay, az, aw = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    bx, by, bz, bw = b[..., 0], b[..., 1], b[..., 2], b[..., 3]
    return np.stack([aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
                     aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz], -1)


def _inv(a):
    return a * np.array([-1, -1, -1, 1.0])


def _slerp(a, b, u):
    d = float(np.dot(a, b))
    if d < 0:
        b, d = -b, -d
    if d > 0.9995:
        return _norm(a + (b - a) * u)
    th = math.acos(min(1.0, d))
    return (math.sin((1 - u) * th) * a + math.sin(u * th) * b) / math.sin(th)


def _angle(a, b):
    return math.degrees(2 * math.acos(min(1.0, abs(float(np.dot(_norm(a), _norm(b)))))))


def close_loops(q, p=None, start=0):
    """q: n×4 quaternions of one joint (p: n×3 Root translation or None); the cycle runs from
    sample `start` (0, or a held part's "loop" marker) to the last. In place; True if changed."""
    n = len(q)
    if n - start < 4:
        return False
    gap = _angle(q[start], q[-1])
    pgap = float(np.linalg.norm(p[start] - p[-1])) if p is not None else 0.0
    if (gap <= LOOP_DEG and pgap <= 0.005) or gap > LOOP_MAX_DEG:
        return False
    e = _norm(_mul(q[start], _inv(q[-1])))  # carries the last sample onto the loop's first
    if e[3] < 0:
        e = -e
    ident = np.array([0, 0, 0, 1.0])
    # Spread over the WHOLE cycle (drift correction): each sample turns by its share of the
    # gap. Spread over the last quarter only, it bent the legs of the runs during their
    # contact (measured: planted feet sliding 2-3x faster); over the cycle the change per
    # sample is the gap / the cycle's samples (a 10 deg gap on 38 samples: 0.26 deg).
    dp = (p[start] - p[-1]).copy() if p is not None else None
    L = n - 1 - start
    for i in range(start + 1, n):
        w = (i - start) / L
        q[i] = _norm(_mul(_slerp(ident, e, w), q[i]))
        if p is not None:
            p[i] = p[i] + dp * w
    q[-1] = q[start]
    if p is not None:
        p[-1] = p[start]
    return True


def spike_frames(q):
    """Samples where this joint jumps for ONE sample and comes back."""
    out = set()
    for i in range(1, len(q) - 1):
        a, b = _angle(q[i - 1], q[i]), _angle(q[i], q[i + 1])
        if min(a, b) > SPIKE_DEG and _angle(q[i - 1], q[i + 1]) < 0.35 * (a + b):
            out.add(i)
    return out


def loop_start(clip):
    """None when the clip does not wrap; else the sample its cycle restarts at
    (AuthoredMotion.sample: a "loop" marker, or 0 for a looping clip)."""
    mark = (clip.get("markers") or {}).get("loop")
    if mark is not None:
        return int(round(mark * clip["fps"]))
    return 0 if clip.get("loop") else None


def apply(clip):
    """clip: the export dict (joints: name -> list of per-sample rows). Returns (loops closed, spikes).
    A spike is fixed on the WHOLE body at that sample (every joint takes the halfway pose of its
    neighbours): the legs of a clip often compensate the hips to keep a foot planted, and
    smoothing one joint alone broke that (measured: a planted foot sliding 4x faster)."""
    closed = 0
    start = loop_start(clip)
    tracks = {}
    for joint, rows in clip["joints"].items():
        a = np.array(rows, float)
        root = a.shape[1] == 7
        tracks[joint] = [a[:, 3:7].copy() if root else a.copy(), a[:, 0:3].copy() if root else None, False]
    fixed = 0
    for _ in range(4):  # smoothing one sample can leave its neighbour isolated: a few rounds
        bad = set()
        for q, p, _c in tracks.values():
            bad |= spike_frames(q)
        bad = {i for i in bad if i - 1 not in bad and i + 1 not in bad}  # isolated samples only
        if not bad:
            break
        fixed += len(bad)
        for t in tracks.values():
            q, p = t[0], t[1]
            for i in sorted(bad):
                q[i] = _norm(_slerp(q[i - 1], q[i + 1], 0.5))
                if p is not None:
                    p[i] = (p[i - 1] + p[i + 1]) / 2
                t[2] = True
    for t in tracks.values():
        q, p = t[0], t[1]
        if start is not None and close_loops(q, p, start):
            t[2] = True
            closed += 1
    for joint, (q, p, changed) in tracks.items():
        if changed:
            out = np.concatenate([p, q], 1) if p is not None else q
            clip["joints"][joint] = [[round(float(v), 6) for v in row] for row in out]
    return closed, fixed


# ---- in place on the generated Luau modules ----
CLIP = re.compile(r'^\t\["(?P<name>[^"]+)"\]=\{fps=(?P<fps>\d+),frames=(?P<frames>\d+),length=[^,]+,loop=(?P<loop>true|false),markers=\{(?P<markers>[^}]*)\}')
JOINT = re.compile(r"^\t\t(?P<joint>\w+)=\{(?P<vals>[^}]*)\},$")


def fmt(v):
    s = ("%.4f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def fix_module(path):
    lines = open(path).read().split("\n")
    closed = spikes = 0
    clip, at = None, {}

    def flush():
        nonlocal closed, spikes
        if not clip or not at:
            return
        before = {j: [list(r) for r in rows] for j, rows in clip["joints"].items()}
        a, s = apply(clip)
        closed += a
        spikes += s
        for j, i in at.items():
            if clip["joints"][j] != before[j]:
                flat = [v for row in clip["joints"][j] for v in row]
                lines[i] = "\t\t%s={%s}," % (j, ",".join(fmt(v) for v in flat))

    for i, line in enumerate(lines):
        m = CLIP.match(line)
        if m:
            flush()
            marks = dict((k, float(v)) for k, v in (x.split("=") for x in m.group("markers").split(",") if x))
            clip = {"loop": m.group("loop") == "true", "frames": int(m.group("frames")), "fps": int(m.group("fps")),
                    "markers": marks, "joints": {}}
            at = {}
            continue
        j = JOINT.match(line)
        if j and clip is not None:
            vals = [float(x) for x in j.group("vals").split(",")]
            width = 7 if j.group("joint") == "Root" else 4
            clip["joints"][j.group("joint")] = [vals[k:k + width] for k in range(0, len(vals), width)]
            at[j.group("joint")] = i
    flush()
    open(path, "w").write("\n".join(lines))
    return closed, spikes


if __name__ == "__main__":
    tc = ts = 0
    for path in sys.argv[1:]:
        if re.search(r"\d+\.luau$", path):
            c, s = fix_module(path)
            tc += c
            ts += s
    print(f"loops closed: {tc} joint tracks; spikes smoothed: {ts} samples")
