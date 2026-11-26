#!/usr/bin/env python3
"""How different the 8 kits look doing the same thing (26/11, François: « les différences de kit
ne se voient pas assez bien dans leurs attaques »).

For every clip name the kits share (Light1..4, Heavy, DashAttack, Air1, Air2, Slam, Launcher, the
guard, the run...), each pair of kits is compared over the clip's normalised time: the mean angle
(degrees) between their joint rotations, every joint weighted alike. Under ~15 degrees two kits
read as the same gesture from the game's camera (audit 07/11: 10 degrees is the same blow).

    python3 tools/blender/kit_distinct.py CLIPS.json [OUT.json]
      CLIPS.json: lune run tools/syphodev/clips_dump.luau CLIPS.json
"""
import json
import math
import sys
from itertools import combinations

KITS = ["Legion", "Lion", "Leaf", "GentleFist", "Sand", "Copycat", "Mirage", "Flashstep"]
NAMES = {"Legion": "Naruto", "Lion": "Sasuke", "Leaf": "Lee", "GentleFist": "Neji", "Sand": "Gaara",
         "Copycat": "Kakashi", "Mirage": "Itachi", "Flashstep": "Minato"}
FIGHT = ["Light1", "Light2", "Light3", "Light4", "Heavy", "DashAttack", "Air1", "Air2", "Slam", "Launcher",
         "Guard", "Idle", "Grab", "Sweep"]
MOVE = ["Walk.F", "Run.F", "Sprint", "Jump.Up", "Jump.Air", "Land", "Brake", "Start", "AirFlip", "WallRun", "DoubleJump"]
SAMPLES = 16


def quats(clip):
    n = clip["frames"]
    out = {}
    for j, flat in clip["joints"].items():
        q = [flat[i * 4:i * 4 + 4] for i in range(len(flat) // 4)]
        if len(q) == n:
            out[j] = q
    return out


def at(q, u):
    x = u * (len(q) - 1)
    i = min(len(q) - 1, int(x))
    return q[i]


def angle(a, b):
    d = abs(sum(x * y for x, y in zip(a, b)))
    na = math.sqrt(sum(x * x for x in a)) or 1
    nb = math.sqrt(sum(x * x for x in b)) or 1
    return math.degrees(2 * math.acos(min(1.0, d / (na * nb))))


def distance(c1, c2):
    q1, q2 = quats(c1), quats(c2)
    joints = sorted(set(q1) & set(q2))
    if not joints:
        return None
    tot = 0.0
    for s in range(SAMPLES):
        u = s / (SAMPLES - 1)
        tot += sum(angle(at(q1[j], u), at(q2[j], u)) for j in joints) / len(joints)
    return tot / SAMPLES


def report(clips, names):
    rows = []
    for nm in names:
        have = [k for k in KITS if "%s.%s" % (k, nm) in clips]
        if len(have) < 2:
            continue
        pairs = []
        for a, b in combinations(have, 2):
            d = distance(clips["%s.%s" % (a, nm)], clips["%s.%s" % (b, nm)])
            if d is not None:
                pairs.append((d, a, b))
        pairs.sort()
        near = {k: min(d for d, a, b in pairs if k in (a, b)) for k in have}
        rows.append({"clip": nm, "kits": len(have), "mean": sum(p[0] for p in pairs) / len(pairs),
                     "closest": [round(pairs[0][0], 1), NAMES[pairs[0][1]], NAMES[pairs[0][2]]],
                     "near": {NAMES[k]: round(v, 1) for k, v in near.items()}})
    return rows


def main(path, out=None):
    clips = json.load(open(path))
    res = {"fight": report(clips, FIGHT), "move": report(clips, MOVE)}
    per = {}
    for r in res["fight"]:
        for k, v in r["near"].items():
            per.setdefault(k, []).append(v)
    res["kit_fight_near"] = {k: round(sum(v) / len(v), 1) for k, v in per.items()}
    for part in ("fight", "move"):
        print("== %s" % part)
        for r in res[part]:
            print("%-11s %d kits  mean %5.1f  closest %5.1f %s/%s  same(<15): %s" % (
                r["clip"], r["kits"], r["mean"], r["closest"][0], r["closest"][1], r["closest"][2],
                ",".join(k for k, v in r["near"].items() if v < 15) or "-"))
    print("== per kit, its nearest other kit on the same blow (mean over blows)")
    for k, v in sorted(res["kit_fight_near"].items(), key=lambda x: x[1]):
        print("%-8s %5.1f" % (k, v))
    if out:
        json.dump(res, open(out, "w"), indent=1, ensure_ascii=False)


if __name__ == "__main__":
    main(*sys.argv[1:3])
