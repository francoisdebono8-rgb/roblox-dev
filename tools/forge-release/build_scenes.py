"""Extract licensed primitive-only demo environments; never ship them in plugins."""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import shutil
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--source", type=Path, required=True)
parser.add_argument("--rojo", default="rojo")
args = parser.parse_args()
COMMIT = "fd6505c3cb12c94272532e1a0b0a30bf8499fc52"
assert subprocess.check_output(["git", "-C", str(args.source), "rev-parse", "HEAD"], text=True).strip() == COMMIT
license_text = (args.source / "LICENSE").read_text()
assert "MIT License" in license_text and "Copyright (c) 2020 TheNexusAvenger" in license_text
allowed = {"Model", "Folder", "Part", "WedgePart", "CornerWedgePart", "TrussPart", "PointLight", "SpotLight", "SurfaceLight", "BlockMesh", "CylinderMesh"}
props = {"Name", "CFrame", "size", "Size", "Color", "Color3uint8", "BrickColor", "Material", "Shape", "shape", "Transparency", "Reflectance", "CastShadow", "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface", "Brightness", "Range", "Angle", "Face", "Enabled", "Shadows", "Scale", "Offset", "VertexColor"}

def prop(node, kind, name, value):
    existing = node.find("Properties")
    if existing is None:
        existing = ET.SubElement(node, "Properties")
    for p in list(existing):
        if p.get("name") == name:
            existing.remove(p)
    item = ET.SubElement(existing, kind, name=name)
    item.text = str(value)

def clean(node, counter):
    if node.get("class") not in allowed:
        counter["removed"] += sum(1 for _ in node.iter("Item"))
        return None
    result = ET.Element("Item", node.attrib)
    properties = ET.SubElement(result, "Properties")
    original = node.find("Properties")
    if original is not None:
        for p in original:
            if p.get("name") in props and p.tag not in {"Content", "Ref", "ProtectedString", "SharedString"}:
                properties.append(copy.deepcopy(p))
    if node.get("class") in {"Part", "WedgePart", "CornerWedgePart", "TrussPart"}:
        prop(result, "bool", "Anchored", "true")
        prop(result, "bool", "Locked", "false")
    for child in node.findall("Item"):
        safe = clean(child, counter)
        if safe is not None:
            result.append(safe)
    return result

for product, map_name in {"presetforge":"DodgeballArena", "jointforge":"TheDepths", "curveforge":"RavenRock"}.items():
    source = args.source / f"src/ServerStorage/Maps/{map_name}.rbxmx"
    dest = ROOT / f"products/{product}/release/scene"
    dest.mkdir(parents=True, exist_ok=True)
    document = ET.Element("roblox", version="4")
    counts = {"removed": 0}
    for node in ET.parse(source).getroot().findall("Item"):
        safe = clean(node, counts)
        if safe is not None:
            prop(safe, "string", "Name", f"Nexus_{map_name}")
            document.append(safe)
    ET.indent(document)
    scene = dest / f"{map_name}-geometry.rbxmx"
    ET.ElementTree(document).write(scene, encoding="utf-8", xml_declaration=True)
    shutil.copyfile(args.source / "LICENSE", dest / "LICENSE-Nexus-Battles.txt")
    title = product.replace("forge", "Forge").capitalize().replace("forge", "Forge")
    project = {"name":f"{title}-Media", "tree":{"$className":"DataModel", "Workspace":{"$className":"Workspace", "Environment":{"$path":scene.name}}, "Lighting":{"$className":"Lighting", "$properties":{"Technology":"ShadowMap", "ClockTime":14, "Brightness":2}}}}
    camera_part = next(n for n in document.iter("Item") if n.findtext("Properties/string[@name='Name']") == "LoadingCameraPosition")
    frame = camera_part.find("Properties/CoordinateFrame[@name='CFrame']")
    camera_frame = [float(frame.findtext(axis)) for axis in ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")]
    project["tree"]["Workspace"]["Camera"] = {"$className":"Camera", "$properties":{"CFrame":camera_frame, "FieldOfView":70}}
    project_path = dest / "scene.project.json"
    project_path.write_text(json.dumps(project, indent=2) + "\n")
    subprocess.run([args.rojo,"build",str(project_path),"-o",str(dest / f"{title}-Media.rbxl")], check=True)
    manifest = {"source":"TheNexusAvenger/Nexus-Battles", "commit":COMMIT, "map":map_name, "url":f"https://github.com/TheNexusAvenger/Nexus-Battles/blob/{COMMIT}/src/ServerStorage/Maps/{map_name}.rbxmx", "source_sha256":hashlib.sha256(source.read_bytes()).hexdigest(), "derived_sha256":hashlib.sha256(scene.read_bytes()).hexdigest(), "license":"MIT; original repository also explicitly allows republication with attribution", "removed_instances":counts["removed"], "retained_instances":sum(1 for _ in document.iter("Item"))}
    (dest / "source.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(product, manifest["retained_instances"], "safe local instances")
