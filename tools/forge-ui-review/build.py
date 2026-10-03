"""Package exact UI candidates and a separate disposable native review harness."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
PRODUCTS = {"CurveForge": 26, "AccessForge": 27, "JointForge": 28}
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--output", type=Path, default=Path("/tmp/ForgeUIReview"))
parser.add_argument("--only", choices=list(PRODUCTS))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)


def build(tree, name, project, output):
    project.write_text(json.dumps({"name": name, "tree": tree}))
    subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True)


def sources(item):
    return {n.findtext("Properties/string[@name='Name']"): n.findtext("Properties/*[@name='Source']") or ""
            for n in item.iter("Item") if n.get("class") in {"Script", "ModuleScript"}}


with tempfile.TemporaryDirectory(prefix="forge-ui-review-") as tmp:
    temp = Path(tmp)
    project = temp / "build.project.json"
    tree = {"$className": "Model", "Runner": {"$path": str(HERE / "Harness.plugin.luau")}}
    digests = {}
    for name, issue in PRODUCTS.items():
        product = ROOT / "products" / name.lower()
        output = product / "ui" / f"{name}-v1.1.0-ui{issue}.rbxm"
        output.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([args.rojo, "build", str(product / "release.project.json"), "-o", str(output)], check=True)
        duplicate = temp / f"{name}-rebuild.rbxm"
        subprocess.run([args.rojo, "build", str(product / "release.project.json"), "-o", str(duplicate)], check=True)
        assert output.read_bytes() == duplicate.read_bytes(), "Nondeterministic package"
        xml = temp / f"{name}.rbxmx"
        build({"$path": str(output)}, name, project, xml)
        doc = ET.parse(xml)
        model = doc.getroot().find("Item")
        expected = {"Main": (product / name / "Main.plugin.luau").read_text()}
        expected.update({p.stem: p.read_text() for p in (product / name / "Modules").glob("*.luau")})
        assert sources(model) == expected
        assert len(list(model.iter("Item"))) == len(expected) + 2
        assert all(n.get("class") in {"Model", "Folder", "Script", "ModuleScript"} for n in model.iter("Item"))
        assert sum(n.get("class") == "Script" for n in model.iter("Item")) == 1
        main = next(n for n in model.iter("Item") if n.get("class") == "Script")
        props = main.find("Properties")
        assert props.findtext("bool[@name='Disabled']") != "true"
        disabled = props.find("bool[@name='Disabled']")
        if disabled is None:
            disabled = ET.SubElement(props, "bool", name="Disabled")
        disabled.text = "true"  # QA copy only; commercial artifact stays untouched.
        doc.write(xml, encoding="utf-8", xml_declaration=True)
        tree[name] = {"$path": str(xml)}
        digests[name] = hashlib.sha256(output.read_bytes()).hexdigest()
    tree["$attributes"] = {name + "SHA256": digest for name, digest in digests.items()}
    build(tree, "ForgeUIReview", project, args.output / "ForgeUIReview.rbxm")
    check = temp / "verified.rbxmx"
    build({"$path": str(args.output / "ForgeUIReview.rbxm")}, "ForgeUIReview", project, check)
    final = ET.parse(check).getroot().find("Item")
    for name in PRODUCTS:
        embedded = next(n for n in final.findall("Item") if n.findtext("Properties/string[@name='Name']") == name)
        assert sources(embedded) == sources(ET.parse(temp / f"{name}.rbxmx").getroot().find("Item"))
    enabled = [n for n in final.iter("Item") if n.get("class") == "Script" and n.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
    attributes = {"ForgeUIReview": True}
    if args.only:
        attributes["ReviewProduct"] = args.only
    build({"$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": attributes},
           "Lighting": {"$className": "Lighting", "$properties": {"Technology": "ShadowMap"}}},
          "ForgeUIReview", project, args.output / "ForgeUIReview.rbxl")
    (args.output / "hashes.json").write_text(json.dumps(digests, indent=2) + "\n")
print(json.dumps({"source_equality": "PASS", "deterministic_rebuild": "PASS", "sha256": digests}, indent=2))
