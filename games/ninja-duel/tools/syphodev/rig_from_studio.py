#!/usr/bin/env python3
"""rig.json from joints read out of Studio (studio_rig.luau), keeping the base rig's route keys
(root_joint, up_joints, torsos, feet, arms, clip_keys). The feet's depth is recomputed down the
chain, so the route's frame stays "feet at y = 0, root at rest".

    python3 rig_from_studio.py studio_out.json rig.json > rig_prodigy.json
"""
import json
import sys

st, base = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
out = dict(base)
out["joints"] = sorted(st["joints"], key=lambda j: [x["name"] for x in base["joints"]].index(j["name"]))
out["sizes"] = st["sizes"]
centre = {"HumanoidRootPart": [0.0, 0.0, 0.0]}
pending = list(out["joints"])
while pending:
    for j in list(pending):
        if j["part0"] in centre:
            c = centre[j["part0"]]
            centre[j["part1"]] = [c[i] + j["c0"]["pos"][i] - j["c1"]["pos"][i] for i in range(3)]
            pending.remove(j)
            break
low = min(centre[p][1] - out["sizes"][p][1] / 2 for p in out["feet"])
out["hrp"] = [0, round(-low, 4), 0]
out["source"] = "read out of Studio (studio_rig.luau): " + ", ".join(
    f"{j['name']} C0 {j['c0']['pos']}" for j in out["joints"]
    if j["c0"]["pos"] != next(b for b in base["joints"] if b["name"] == j["name"])["c0"]["pos"])
print(json.dumps(out, indent=1))
