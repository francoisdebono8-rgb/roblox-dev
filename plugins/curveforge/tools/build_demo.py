"""Build original editable demo fixtures. Run demo/Setup in Studio for generated outputs."""
from pathlib import Path
import json
import subprocess
import argparse

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--rojo", default="rojo")
args = parser.parse_args()

def part(position, size, color, **extra):
    return {"$className": "Part", "$properties": {"Anchored": True, "Position": position, "Size": size, "Color": [c / 255 for c in color], **extra}}

world = {"$className": "Workspace", "Ground": part([0, -.5, 0], [125, 1, 85], [101,119,127])}
scenarios = [
    ("01_UtilityCable", [[-42,17,-18],[-32,12,-18],[-20,12,-18],[-10,17,-18]]),
    ("02_IndustrialPipe", [[0,3,-18],[9,3,-18],[16,7,-12],[24,10,-8],[36,10,-8]]),
    ("03_RepeatedFence", [[-38,2,15],[-18,2,8],[4,2,16],[35,2,13]])]
for name, positions in scenarios:
    scenario = {"$className": "Folder", "ControlPoints": {"$className": "Folder"}}
    for i, position in enumerate(positions, 1):
        scenario["ControlPoints"][f"Point{i:02}"] = part(position, [.65,.65,.65], [255,211,85], Shape="Ball", CanCollide=False, Transparency=.4)
    world[name] = scenario
for i, x in enumerate((-42,-10), 1):
    world["01_UtilityCable"][f"Pole{i}"] = part([x,8,-18],[.8,16,.8],[188,194,198])
    world["01_UtilityCable"][f"Crossarm{i}"] = part([x,17,-18],[4,.5,.7],[77,99,110])
for i, p in enumerate(([0,2,-18],[36,9,-8]), 1):
    world["02_IndustrialPipe"][f"Machine{i}"] = part(p,[4,4,5],[59,87,102])
world["03_RepeatedFence"]["FencePostSource"] = {"$className":"Model", "Post":part([-48,2,23],[.55,4,.55],[64,163,150]), "Cap":part([-48,4.1,23],[.9,.3,.9],[227,231,235])}
project = {"name":"CurveForge-Demo", "tree":{"$className":"DataModel", "Workspace":world, "Lighting":{"$className":"Lighting", "$properties":{"Technology":"ShadowMap", "Brightness":2,"ClockTime":14}}}}
path = ROOT / "demo/fixtures.project.json"
path.write_text(json.dumps(project, indent=2) + "\n")
subprocess.run([args.rojo,"build",str(path),"-o",str(ROOT / "demo/CurveForge-Demo.rbxl")], check=True)
print("Original fixtures ready. Generated-output scenarios require the Studio Setup run.")
