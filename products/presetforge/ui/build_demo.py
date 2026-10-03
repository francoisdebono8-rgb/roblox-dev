"""Build a script-free lighting workshop with real persisted Project recipes."""
import argparse
import json
import math
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
WARM = [1, 204 / 255, 140 / 255]
WHITE = [1, 1, 1]


def node(kind, properties=None, **children):
    return {"$className": kind, "$properties": properties or {}, **children}


def part(position, size, color, material="SmoothPlastic", **children):
    return node("Part", {"Anchored": True, "Size": size, "Color": color,
                        "Material": material, "CFrame": [*position, 1, 0, 0, 0, 1, 0, 0, 0, 1]}, **children)


def light(index, matching=False):
    return node("PointLight", {
        "Brightness": 5 if matching else 2, "Color": WARM if matching else WHITE,
        "Range": 12, "Shadows": False, "Enabled": True,
        "Tags": ["Worklight", "KeepTag"],
        "Attributes": {"FixtureId": {"String": f"WL-{index:02}"},
                       "LightingProfile": {"String": "Existing"}, "Keep": {"Bool": False}},
    })


def recipe(name, fields, tags=None, attributes=None):
    return node("Configuration", {"Attributes": {
        "FormatVersion": {"Float64": 2}, "RecipeName": {"String": name},
        "SchemaId": {"String": "PointLight"}, "CaptureTags": {"Bool": tags is not None},
        "CaptureAttributes": {"Bool": attributes is not None},
    }}, Properties=node("Configuration", {"Attributes": fields}),
        Tags=node("Folder", **{f"Tag_{i:03}": node("StringValue", {"Value": tag})
                               for i, tag in enumerate(tags or [], 1)}),
        Attributes=node("Configuration", {"Attributes": attributes or {}}))


def camera_frame(eye, target):
    def unit(v):
        length = math.sqrt(sum(x*x for x in v))
        return [x/length for x in v]
    def cross(a, b):
        return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
    back = unit([a-b for a, b in zip(eye, target)])
    right = unit(cross([0, 1, 0], back))
    up = cross(back, right)
    return [*eye, *[v[i] for i in range(3) for v in (right, up, back)]]


def scene(review=False, width=560, height=640):
    workshop = node("Model")
    lights = node("Folder")
    for row in range(5):
        bay = node("Model")
        z = -16 + row*8
        bay["Rail"] = part([0, 10, z], [68, .4, .5], [.24, .26, .27], "Metal")
        for col in range(8):
            index = row*8 + col + 1
            x = -28 + col*8
            bay[f"Fixture {index:02}"] = part([x, 8, z], [2.4, .4, 2.4], [.16, .18, .19], "Metal",
                Stem=part([x, 9, z], [.12, 1.8, .12], [.3, .32, .34], "Metal"),
                Diffuser=part([x, 7.75, z], [2, .08, 2], [.92, .92, .88], "Neon",
                              **{f"Worklight {index:02}": light(index, index > 30)}))
        lights[f"Bay {row+1:02}"] = bay
    workshop["Lighting"] = lights
    workshop["Floor"] = part([0, -.5, 0], [74, 1, 50], [.5, .52, .53], "Concrete")
    workshop["RearWall"] = part([0, 5, -24.5], [74, 10, 1], [.62, .64, .65], "Concrete")
    for i, x in enumerate([-35, 35]):
        for j, z in enumerate([-22, 22]):
            workshop[f"Column{i}{j}"] = part([x, 5, z], [.8, 10, .8], [.25, .27, .29], "Metal")
    for i, x in enumerate([-24, 0, 24]):
        workshop[f"Workbench{i+1}"] = part([x, 2, -21], [12, .5, 3], [.21, .31, .31], "Metal")
        for side in [-1, 1]:
            workshop[f"BenchLeg{i}{side}"] = part([x+side*5, 1, -21], [.4, 2, 2.5], [.27, .29, .3], "Metal")
    source = part([0, 0, 0], [2, .4, 2], [.2, .2, .2], Source=light(0, True))
    source["Source"]["$properties"]["Tags"] += ["FixtureReady"]
    source["Source"]["$properties"]["Attributes"]["LightingProfile"] = {"String": "Warm"}
    workspace = node("Workspace", Camera=node("Camera", {
        "CFrame": camera_frame([51, 27, 47], [0, 3, 0]), "FieldOfView": 50,
    }), Workshop=workshop)
    if review:
        workspace["$attributes"] = {"PresetForgeUIGate": True, "UIWidth": width, "UIHeight": height}
    return {"name": "PresetForge-LightingWorkshop", "tree": {
        "$className": "DataModel", "Workspace": workspace,
        "Lighting": node("Lighting", {"Technology": "ShadowMap", "Brightness": .4,
            "ClockTime": 19, "Ambient": [.08, .08, .08], "OutdoorAmbient": [.1, .1, .1]}),
        "ServerStorage": node("ServerStorage", ReferenceFixture=source,
            PresetForgeProjectRecipes=node("Folder", {"Attributes": {"FormatVersion": {"Float64": 2}}},
                **{"Warm worklights": recipe("Warm worklights", {"Brightness": {"Float64": 5}, "Color": {"Color3": WARM}}),
                   "Service metadata": recipe("Service metadata", {}, ["FixtureReady"], {"LightingProfile": {"String": "Warm"}})})),
    }}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo")
    parser.add_argument("--output", type=Path, default=HERE / "PresetForge-LightingWorkshop.rbxl")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="presetforge-demo-") as temp:
        project = Path(temp) / "scene.project.json"
        project.write_text(json.dumps(scene()))
        subprocess.run([args.rojo, "build", str(project), "-o", str(args.output)], check=True)
