#!/usr/bin/env python3
"""The new Konoha's plan at the prover, with every house's roof as a place to reach
(OUTILLEUR, 21/11; DEC-047, step 3, OUTILLEUR 1: « vérifier que les toits sont
atteignables »).

The plan's spec (tools/blender/konoha_layout.py) files the houses as decoration: the
prover never asks whether a player gets up there. This copy of the spec turns each house
of the plan into a high ground the village must reach, runs the prover unchanged
(tools/syphodev/konoha_prove.py), and lists the roofs:
  * reached walking (the jump and the second jump, as konoha_profile.json models them);
  * reached only with a run-up (the prover's "generous" envelope: a take-off at the run);
  * never reached;
and the houses that cut into a wall of the plan.

    python3 tools/blender/konoha_layout.py OUT
    python3 tools/syphodev/konoha_plan_roofs.py OUT/konoha_plan_spec.json OUT     (40 s at res 4)
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
HOUSES = ("tank_house", "small_house", "shop_house", "clan_house", "machiya", "apartment")


def roofs_spec(spec: dict) -> tuple[dict, list]:
    """The same spec, each house a high ground declared reachable."""
    out = json.loads(json.dumps(spec))
    houses = []
    for part in out["parts"]:
        if part.get("mesh") in HOUSES:
            part.pop("decor", None)
            part["roles"] = ["high_ground"]
            houses.append(part["id"])
    reach = list(out.get("intent", {}).get("reachable", []))
    out.setdefault("intent", {})["reachable"] = reach + [m + "_*" for m in HOUSES]
    out["name"] = spec.get("name", "Konoha") + "Roofs"
    return out, houses


def summary(text: str, houses: list) -> dict:
    """What the prover's text says of the roofs."""
    generous = sorted(set(re.findall(r"- (\S+): intended reachable, but only via the generous envelope", text)))
    never = sorted(set(re.findall(r"- (\S+): intended reachable, but NO route exists", text)))
    overlaps = re.findall(r"- (\S+) and (\S+) overlap by ([\d.]+) studs", text)
    walls = [(a, b, float(d)) for a, b, d in overlaps if any(b.startswith(h) or a.startswith(h) for h in HOUSES)]
    flagged = set(generous) | set(never)
    return {
        "houses": len(houses),
        "walking": len([h for h in houses if h not in flagged]),
        "runup": [h for h in generous if h in houses],
        "never": [h for h in never if h in houses],
        "walls": walls,
        "result": "PASS" if "RESULT: PASS" in text else "FAIL",
    }


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if len(args) < 2:
        print(__doc__)
        return 2
    spec_path, out_dir = args[0], args[1]
    with open(spec_path, encoding="utf-8") as f:
        spec = json.load(f)
    variant, houses = roofs_spec(spec)
    os.makedirs(out_dir, exist_ok=True)
    vpath = os.path.join(out_dir, "plan_roofs_spec.json")
    with open(vpath, "w", encoding="utf-8") as f:
        json.dump(variant, f)
    run = subprocess.run([sys.executable, os.path.join(HERE, "konoha_prove.py"), vpath, os.path.join(out_dir, "plan_roofs_report.json")],
                         capture_output=True, text=True)
    text = run.stdout + run.stderr
    with open(os.path.join(out_dir, "plan_roofs.txt"), "w", encoding="utf-8") as f:
        f.write(text)
    s = summary(text, houses)
    print(f"Toits du plan : {s['houses']} maisons")
    print(f"  atteints en marchant (saut + second saut) : {s['walking']}")
    print(f"  seulement avec de l'élan (en courant)     : {len(s['runup'])}  {' '.join(s['runup'])}")
    print(f"  jamais atteints                            : {len(s['never'])}  {' '.join(s['never'])}")
    print(f"  maisons qui entrent dans un mur du plan    : {len(s['walls'])}")
    for a, b, d in s["walls"]:
        print(f"    {a} / {b} : {d:.2f} studs")
    with open(os.path.join(out_dir, "plan_roofs_summary.json"), "w", encoding="utf-8") as f:
        json.dump(s, f, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
