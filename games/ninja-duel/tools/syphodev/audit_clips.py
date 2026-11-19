#!/usr/bin/env python3
"""SyphoDev's numeric checks run over EVERY authored clip of the game, on the real bodies.

"Numbers are cheap: it doesn't have to read an image." Each clip is posed frame by frame down
the Motor6D chain of a rig.json (the body the clip is played on), with the real part boxes,
and measured:
  ground   lowest point of the body vs the floor (HipHeight 2: the floor is 3 studs under
           the root): through the floor, or a grounded clip that never touches it;
  slip     a planted foot's contact point that slides along the floor (r6_clip's stance
           slip: the lowest corner followed to the next frame). Locomotion clips are measured
           against their own ground speed (meta.stride / length, direction from .F/.B/.L/.R);
  inside   a hand or forearm inside the torso, the hips or the other hand (oriented boxes,
           shrunk 10 % so touching is not counted), deeper than 0.08 stud;
  pop      a joint turning more than 40 degrees between two samples (the IK flip of the
           video reads as a part changing colour);
  loop     a looping clip whose last sample is not its first (it snaps on every wrap);
  timing   strikes outside Roblox's 0.3-0.7 s (reported, the server owns timing).

    python3 audit_clips.py rig.json all_clips.json out.json [--only Lion.]
"""
import json
import math
import re
import sys

import numpy as np

AIR = re.compile(r"(Air|Jump|Flip|Launched|Knockback|Handspring|Cartwheel|Leap|ThrowUp|Dive|Fly|Spike|"
                 r"Slam|Ultimate|Ult\.|Awaken|Chidori|Throw|Grabbed|Knockdown|Down|Getup|Dash|Chase|Hit\.Legs)")
STRIKE = re.compile(r"\.(Light\d|Heavy|Air\d|KneeStrike|DashAttack)$")
LOCO = re.compile(r"\.(Walk|Run|Sprint|Guard\.Step)(\.([FBLR]))?$")


def quats_to_R(q):
    q = q / np.linalg.norm(q, axis=1, keepdims=True)
    x, y, z, w = q[:, 0], q[:, 1], q[:, 2], q[:, 3]
    R = np.empty((len(q), 3, 3))
    R[:, 0, 0] = 1 - 2 * (y * y + z * z); R[:, 0, 1] = 2 * (x * y - z * w); R[:, 0, 2] = 2 * (x * z + y * w)
    R[:, 1, 0] = 2 * (x * y + z * w); R[:, 1, 1] = 1 - 2 * (x * x + z * z); R[:, 1, 2] = 2 * (y * z - x * w)
    R[:, 2, 0] = 2 * (x * z - y * w); R[:, 2, 1] = 2 * (y * z + x * w); R[:, 2, 2] = 1 - 2 * (x * x + y * y)
    return R


class Rig:
    def __init__(self, rig):
        self.joints = rig["joints"]
        self.sizes = {p: np.array(s, float) for p, s in rig["sizes"].items()}
        self.keys = rig["clip_keys"]  # motor -> clip key
        self.floor = -rig["hrp"][1] + 0.01  # the root stands HipHeight + 1 = 3 studs up
        order, have, pending = [], {"HumanoidRootPart"}, list(rig["joints"])
        while pending:
            for j in list(pending):
                if j["part0"] in have:
                    order.append(j); have.add(j["part1"]); pending.remove(j)
                    break
        self.order = order
        for j in self.joints:
            for k in ("c0", "c1"):
                assert np.allclose(np.array(j[k]["rows"]), np.eye(3)), "C0/C1 rotations other than identity are not handled"
        signs = np.array([[sx, sy, sz] for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)], float)
        self.corners = {p: signs * (s / 2) for p, s in self.sizes.items()}

    def pose(self, clip):
        """part -> (R n×3×3, p n×3), root space, every sample."""
        n, J = clip["frames"], clip["joints"]
        W = {"HumanoidRootPart": (np.repeat(np.eye(3)[None], n, 0), np.zeros((n, 3)))}
        for j in self.order:
            key = self.keys[j["name"]]
            rows = J.get(key)
            if rows is None:
                TR, Tp = np.repeat(np.eye(3)[None], n, 0), np.zeros((n, 3))
            elif key == "Root":
                a = np.array(rows, float).reshape(n, 7)
                TR, Tp = quats_to_R(a[:, 3:7]), a[:, 0:3]
            else:
                TR, Tp = quats_to_R(np.array(rows, float).reshape(n, 4)), np.zeros((n, 3))
            R0, p0 = W[j["part0"]]
            c0, c1 = np.array(j["c0"]["pos"]), np.array(j["c1"]["pos"])
            R1 = R0 @ TR
            p1 = p0 + np.einsum("nij,nj->ni", R0, c0 + Tp) - np.einsum("nij,j->ni", R1, c1)
            W[j["part1"]] = (R1, p1)
        return W

    def corners_at(self, W, part):
        R, p = W[part]
        return p[:, None, :] + np.einsum("nij,kj->nki", R, self.corners[part])


def obb_depth(Ra, pa, ha, Rb, pb, hb):
    """Penetration depth of two oriented boxes per frame (0 if apart). Ra: n×3×3, ha: half sizes."""
    n = len(pa)
    axes = [Ra[:, :, i] for i in range(3)] + [Rb[:, :, i] for i in range(3)]
    for i in range(3):
        for k in range(3):
            c = np.cross(Ra[:, :, i], Rb[:, :, k])
            norm = np.linalg.norm(c, axis=1, keepdims=True)
            axes.append(np.where(norm > 1e-6, c / np.maximum(norm, 1e-9), np.nan))
    d = pb - pa
    depth = np.full(n, np.inf)
    for L in axes:
        ra = sum(ha[i] * np.abs(np.einsum("ni,ni->n", Ra[:, :, i], L)) for i in range(3))
        rb = sum(hb[i] * np.abs(np.einsum("ni,ni->n", Rb[:, :, i], L)) for i in range(3))
        dist = np.abs(np.einsum("ni,ni->n", d, L))
        ov = ra + rb - dist
        ov = np.where(np.isnan(ov), np.inf, ov)
        depth = np.minimum(depth, ov)
    return np.maximum(depth, 0)


def angle_between(qa, qb):
    d = np.abs(np.sum(qa * qb, axis=1)) / (np.linalg.norm(qa, axis=1) * np.linalg.norm(qb, axis=1))
    return np.degrees(2 * np.arccos(np.clip(d, -1, 1)))


def audit(rig, name, clip):
    n, fps = clip["frames"], clip["fps"]
    W = rig.pose(clip)
    out = {"name": name, "length": clip["length"], "loop": bool(clip.get("loop")), "fps": fps, "frames": n}
    grounded = not AIR.search(name)
    out["grounded"] = grounded
    # ground
    low = np.min(np.stack([rig.corners_at(W, p)[:, :, 1].min(1) for p in rig.sizes]), 0) - rig.floor
    out["lowest_min"], out["lowest_max"] = round(float(low.min()), 3), round(float(low.max()), 3)
    # What the engine cannot fix (VelmoraMotionEngine authoredFeet, ANIM-002, locks a foot that is
    # low and slower than 3.5 st/s at the rest ankle height): a body part other than a foot under
    # the floor, or a foot under the floor while it moves faster than that.
    body_low = np.min(np.stack([rig.corners_at(W, p)[:, :, 1].min(1) for p in rig.sizes if not p.endswith("Foot")]), 0) - rig.floor
    out["body_under_floor"] = round(float(max(0.0, -body_low.min())), 3)
    moving_under = 0.0
    for foot in ("RightFoot", "LeftFoot"):
        C = rig.corners_at(W, foot)
        lowf = C[:, :, 1].min(1) - rig.floor
        ctr = W[foot][1]
        v = np.linalg.norm(np.diff(ctr, axis=0), axis=1) * fps
        fast = np.concatenate([v, v[-1:]]) > 3.5
        if (fast & (lowf < -0.1)).any():
            moving_under = max(moving_under, float(-lowf[fast].min()))
    out["moving_foot_under_floor"] = round(moving_under, 3)
    # slip of the planted feet
    m = LOCO.search(name)
    speed = 0.0
    direction = np.array([0, 0, 1.0])
    if m:
        stride = (clip.get("meta") or {}).get("stride")
        if stride and clip["length"] > 0:
            speed = stride / clip["length"]
        d = m.group(3) or "F"
        direction = {"F": np.array([0, 0, 1.0]), "B": np.array([0, 0, -1.0]),
                     "L": np.array([1.0, 0, 0]), "R": np.array([-1.0, 0, 0])}[d]
    worst_slip, slip_run = 0.0, 0.0
    for foot in ("RightFoot", "LeftFoot"):
        C = rig.corners_at(W, foot)
        run = np.zeros(3)
        last = n - (0 if out["loop"] else 1)
        for i in range(last):
            k = int(np.argmin(C[i, :, 1]))
            a, b = C[i, k], C[(i + 1) % n, k]
            if a[1] - rig.floor < 0.06 and b[1] - rig.floor < 0.06:
                mv = (b - a) - direction * speed / fps
                mv[1] = 0
                run += mv
                worst_slip = max(worst_slip, float(np.linalg.norm(mv) * fps))
                slip_run = max(slip_run, float(np.linalg.norm(run)))
            else:
                run = np.zeros(3)
    out["slip_speed_max"] = round(worst_slip, 2)
    out["slip_run_max"] = round(slip_run, 3)
    # inside the body
    shrink = 0.9
    pairs = [(a, b) for a in ("RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm")
             for b in ("UpperTorso", "LowerTorso", "Head")] + [("RightHand", "LeftHand")]
    inside = {}
    for a, b in pairs:
        Ra, pa = W[a]; Rb, pb = W[b]
        dep = obb_depth(Ra, pa, rig.sizes[a] / 2 * shrink, Rb, pb, rig.sizes[b] / 2 * shrink)
        bad = dep > 0.08
        if bad.any():
            inside[f"{a}~{b}"] = {"frames": int(bad.sum()), "depth": round(float(dep.max()), 3)}
    out["inside"] = inside
    # pops and loop closure
    pops, loopgap = {}, {}
    for key, rows in clip["joints"].items():
        a = np.array(rows, float).reshape(n, 7 if key == "Root" else 4)
        q = a[:, 3:7] if key == "Root" else a
        ang = angle_between(q[:-1], q[1:])
        # a flip (over 120 degrees in one sample) or a there-and-back spike: two big steps whose
        # ends are close (the joint jumps for one sample and comes back)
        spike = 0.0
        if n >= 3:
            skip = angle_between(q[:-2], q[2:])
            both = np.minimum(ang[:-1], ang[1:])
            sp = np.where((both > 25) & (skip < 0.35 * (ang[:-1] + ang[1:])), both, 0)
            spike = float(sp.max())
        if ang.max() > 120 or spike > 0:
            pops[key] = {"deg": round(float(max(ang.max(), spike)), 1), "frame": int(ang.argmax()),
                         "kind": "flip" if ang.max() > 120 else "spike"}
        mark = (clip.get("markers") or {}).get("loop")
        start = int(round(mark * fps)) if mark is not None else (0 if out["loop"] else None)
        if start is not None:
            g = float(angle_between(q[start:start + 1], q[-1:])[0])
            if g > 3:
                loopgap[key] = round(g, 1)
    out["pops"], out["loop_gap"] = pops, loopgap
    if STRIKE.search(name):
        out["strike_length_ok"] = 0.3 <= clip["length"] <= 0.7
    return out


def main(rig_path, clips_path, out_path, only=None):
    rig = Rig(json.load(open(rig_path)))
    clips = json.load(open(clips_path))
    res = [audit(rig, k, c) for k, c in sorted(clips.items()) if not only or k.startswith(only)]
    json.dump(res, open(out_path, "w"), indent=0)
    g = [r for r in res if r["grounded"]]
    print(f"{len(res)} clips ({len(g)} grounded) on {rig_path}")
    print(f"  body (not a foot) under the floor > 0.1 stud: {sum(1 for r in res if r['body_under_floor'] > 0.1)}")
    print(f"  moving foot under the floor > 0.1 stud: {sum(1 for r in res if r['moving_foot_under_floor'] > 0.1)}")
    print(f"  grounded but never touching (> 0.25): {sum(1 for r in g if r['lowest_min'] > 0.25)}")
    print(f"  planted foot sliding faster than the engine locks (> 6 st/s): {sum(1 for r in g if r['slip_speed_max'] > 6)}")
    print(f"  hand/forearm inside the body: {sum(1 for r in res if r['inside'])} "
          f"(head {sum(1 for r in res if any('Head' in k for k in r['inside']))}, "
          f"torso {sum(1 for r in res if any('Torso' in k for k in r['inside']))}, "
          f"hands {sum(1 for r in res if 'RightHand~LeftHand' in r['inside'])})")
    print(f"  joint flips/spikes: {sum(1 for r in res if r['pops'])}")
    print(f"  loops that do not close (> 3 deg): {sum(1 for r in res if r['loop_gap'])}")
    print(f"  strikes outside 0.3-0.7 s: {sum(1 for r in res if r.get('strike_length_ok') is False)}")


# Authored on purpose (a strike that snaps back on every wrap): the ANIMATEUR's call.
GATE_ALLOW_LOOP = {"GentleFist.SixtyFourPalms.Release"}


def gate(clips_path):
    """tests/run.sh: what tools/syphodev/clip_passes.py fixes must stay fixed."""
    import os
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import clip_passes as P
    clips = json.load(open(clips_path))
    bad = []
    for name, c in sorted(clips.items()):
        n = c["frames"]
        tracks = {}
        for key, rows in c["joints"].items():
            a = np.array(rows, float).reshape(n, 7 if key == "Root" else 4)
            tracks[key] = a[:, 3:7] if key == "Root" else a
        frames = set()
        for q in tracks.values():
            frames |= P.spike_frames(q)
        iso = sorted(i for i in frames if i - 1 not in frames and i + 1 not in frames)
        if iso:
            bad.append(f"{name}: one-sample pop at sample {iso[0]}")
        start = P.loop_start(c)
        if start is not None and name not in GATE_ALLOW_LOOP:
            gaps = {k: P._angle(q[start], q[-1]) for k, q in tracks.items()}
            k, g = max(gaps.items(), key=lambda kv: kv[1])
            if g > 3:
                bad.append(f"{name}: loop does not close ({k} {g:.1f} deg)")
    for b in bad[:10]:
        print("FAIL " + b)
    if bad:
        print(f"FAIL {len(bad)} clips: run python3 tools/syphodev/clip_passes.py src/Client/AuthoredClips*.luau src/Client/AuthoredJutsu?.luau")
        return 1
    print(f"PASS {len(clips)} clips: every loop closes, no one-sample pop (SyphoDev audit)")
    return 0


if __name__ == "__main__":
    a = sys.argv[1:]
    if a and a[0] == "--gate":
        if len(a) > 1:
            sys.exit(gate(a[1]))
        # tests/run.sh: dump the clips with Lune ($LUNE) into a temporary folder, then gate
        import os
        import subprocess
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "clips.json")
            subprocess.run([os.environ.get("LUNE", "lune"), "run", "tools/syphodev/clips_dump.luau", out],
                           check=True, capture_output=True)
            sys.exit(gate(out))
    only = a[a.index("--only") + 1] if "--only" in a else None
    main(a[0], a[1], a[2], only)
