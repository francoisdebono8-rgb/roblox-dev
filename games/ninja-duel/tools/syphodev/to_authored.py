#!/usr/bin/env python3
"""SyphoDev joint-space clips (resolved.json) -> the game's clip JSON (AuthoredClips rows).

r6_clip.py writes resolved.json: per key, every joint's Motor6D.Transform as it rendered
and checked it. A Ninja Duel clip row IS Motor6D.Transform per joint per frame
(tools/blender/clips_to_luau.py header), so this only samples the keys at 30 fps with
the same ease and slerp r6_clip.py rendered with (Roblox slerps the CFrame), renames
the shoulders to the clip keys the engine reads ("Right"/"Left") and writes the JSON
that tools/blender/clips_to_luau.py turns into AuthoredClips*.luau.

    python3 to_authored.py rig.json out/clips.json out/punch/resolved.json [...]

The AuthoredClips modules belong to the ANIMATEUR (RUNBOOK 3 quater): this writes the
JSON; the ANIMATEUR merges it with his exports and runs clips_to_luau.py.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "../../../../.claude/skills/roblox-animation/scripts"))
import r6_joint as RJ  # noqa: E402  the same ease curves r6_clip.py samples with

FPS = 30


def quat(rows):
    m = rows
    tr = m[0][0] + m[1][1] + m[2][2]
    if tr > 0:
        s = math.sqrt(tr + 1.0) * 2
        w, x, y, z = 0.25 * s, (m[2][1] - m[1][2]) / s, (m[0][2] - m[2][0]) / s, (m[1][0] - m[0][1]) / s
    elif m[0][0] > m[1][1] and m[0][0] > m[2][2]:
        s = math.sqrt(1.0 + m[0][0] - m[1][1] - m[2][2]) * 2
        w, x, y, z = (m[2][1] - m[1][2]) / s, 0.25 * s, (m[0][1] + m[1][0]) / s, (m[0][2] + m[2][0]) / s
    elif m[1][1] > m[2][2]:
        s = math.sqrt(1.0 + m[1][1] - m[0][0] - m[2][2]) * 2
        w, x, y, z = (m[0][2] - m[2][0]) / s, (m[0][1] + m[1][0]) / s, 0.25 * s, (m[1][2] + m[2][1]) / s
    else:
        s = math.sqrt(1.0 + m[2][2] - m[0][0] - m[1][1]) * 2
        w, x, y, z = (m[1][0] - m[0][1]) / s, (m[0][2] + m[2][0]) / s, (m[1][2] + m[2][1]) / s, 0.25 * s
    n = math.sqrt(x * x + y * y + z * z + w * w)
    return [x / n, y / n, z / n, w / n]


def slerp(a, b, u):
    d = sum(p * q for p, q in zip(a, b))
    if d < 0:
        b, d = [-v for v in b], -d
    if d > 0.9995:
        r = [p + (q - p) * u for p, q in zip(a, b)]
    else:
        th = math.acos(d)
        s = math.sin(th)
        r = [(math.sin((1 - u) * th) * p + math.sin(u * th) * q) / s for p, q in zip(a, b)]
    n = math.sqrt(sum(v * v for v in r))
    return [v / n for v in r]


def r4(v):
    return round(v, 4) + 0.0


def convert(res, keys_of):
    keys = res["keys"]
    dur, loop = res["duration"], res["loop"]
    n = int(round(dur * FPS)) + (0 if loop else 1)
    Q = [{j: quat(k["poses"][j]["rows"]) for j in res["keyed"]} for k in keys]
    P = [{j: k["poses"][j]["pos"] for j in res["keyed"]} for k in keys]
    rows = {keys_of.get(j, j): [] for j in res["keyed"]}
    for i in range(n):
        t = min(i / FPS, dur)
        a = 0
        while a < len(keys) - 2 and t > keys[a + 1]["t"]:
            a += 1
        t0, t1 = keys[a]["t"], keys[a + 1]["t"]
        u = RJ.ease(keys[a].get("ease", "smooth"), (t - t0) / (t1 - t0) if t1 > t0 else 1.0)
        for j in res["keyed"]:
            q = slerp(Q[a][j], Q[a + 1][j], u)
            row = [r4(v) for v in q]
            if keys_of.get(j, j) == "Root":
                p = [r4(p0 + (p1 - p0) * u) for p0, p1 in zip(P[a][j], P[a + 1][j])]
                row = [round(v, 3) for v in p] + row
            rows[keys_of.get(j, j)].append(row)
    markers = {name: round(t, 4) for name, t in res.get("markers", [])}
    return {"fps": FPS, "frames": n, "length": round(dur, 4), "loop": loop, "markers": markers,
            "meta": {"source": "syphodev-joint-space"}, "joints": rows}


def main(rig_path, out_path, resolved):
    rig = json.load(open(rig_path))
    keys_of = rig.get("clip_keys", {})
    data = {}
    for p in resolved:
        res = json.load(open(p))
        data[res["name"]] = convert(res, keys_of)
        print(f"{res['name']}: {data[res['name']]['frames']} frames, {len(data[res['name']]['joints'])} joints")
    with open(out_path, "w") as fh:
        json.dump(data, fh, separators=(",", ":"))
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
