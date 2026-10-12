"""Package opt-in Edit-mode QA importing the exact candidate and historical binaries."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--output-dir", type=Path, default=Path(tempfile.gettempdir()) / "AccessForge21QA")
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)

def build(project, output):
    subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True)

def named(item, name):
    return next(child for child in item.findall("Item") if child.findtext("Properties/string[@name='Name']") == name)

def sources(root):
    result = {}
    for item in root.iter("Item"):
        if item.get("class") in {"Script", "ModuleScript"}:
            name = item.findtext("Properties/string[@name='Name']")
            assert name not in result
            result[name] = item.findtext("Properties/*[@name='Source']") or ""
    return result

with tempfile.TemporaryDirectory(prefix="accessforge-technical-") as temp:
    directory = Path(temp)
    artifacts = {"Candidate": ROOT / "dist/AccessForge-v1.1.0.rbxm", "Legacy": ROOT / "dist/AccessForge-v1.0.0.rbxm"}
    digests = {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in artifacts.items()}
    assert digests["Legacy"] == "53655a01ca0bb2e05886cdc401fa38003430f4f10f7317854a93c646d9dff44c", "Public V1 was changed"
    project = directory / "gate.project.json"
    project.write_text(json.dumps({"name": "AccessForgeTechnicalGate", "tree": {
        "$className": "Model", "$attributes": {key + "SHA256": value for key, value in digests.items()},
        "SourceMatchVerified": {"$className": "BoolValue", "$properties": {"Value": True}},
        **{key: {"$path": str(path)} for key, path in artifacts.items()},
        "Runner": {"$path": str(ROOT / "tests/TechnicalGate.plugin.luau")},
        "Tests": {"$className": "Folder", "V11": {"$path": str(ROOT / "tests/V11.spec.luau")}}
    }}))
    xml = directory / "gate.rbxmx"; build(project, xml)
    doc = ET.parse(xml); root = doc.getroot().find("Item")
    expected = {"Main": (ROOT / "AccessForge/Main.plugin.luau").read_text()}
    expected.update({p.stem: p.read_text() for p in (ROOT / "AccessForge/Modules").glob("*.luau")})
    assert sources(named(root, "Candidate")) == expected and len(expected) == 5
    original_sources = {}
    for key in artifacts:
        item = named(root, key); original_sources[key] = sources(item)
        assert len(original_sources[key]) == 5 and len(list(item.iter("Item"))) == 7
        props = named(item, "Main").find("Properties")
        disabled = props.find("bool[@name='Disabled']")
        if disabled is None:
            disabled = ET.SubElement(props, "bool", name="Disabled")
        disabled.text = "true"
    doc.write(xml, encoding="utf-8", xml_declaration=True)
    project.write_text(json.dumps({"name": "AccessForgeTechnicalGate", "tree": {"$path": str(xml)}}))
    output = args.output_dir / "AccessForgeTechnicalGate.rbxm"; build(project, output)
    project.write_text(json.dumps({"name": "AccessForgeTechnicalGate", "tree": {"$path": str(output.resolve())}}))
    check = directory / "verified.rbxmx"; build(project, check)
    verified = ET.parse(check).getroot().find("Item")
    for key in artifacts:
        assert sources(named(verified, key)) == original_sources[key]
        assert hashlib.sha256(artifacts[key].read_bytes()).hexdigest() == digests[key]
        assert named(named(verified, key), "Main").findtext("Properties/bool[@name='Disabled']") == "true"
    enabled = [item for item in verified.iter("Item") if item.get("class") == "Script" and item.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
    project.write_text(json.dumps({"name": "AccessForge21QA", "tree": {"$className": "DataModel",
        "Workspace": {"$className": "Workspace", "$attributes": {"AccessForgeTechnicalGate": True}},
        "Lighting": {"$className": "Lighting", "$properties": {"Technology": "ShadowMap"}}
    }}))
    build(project, args.output_dir / "AccessForge21QA.rbxl")
print(json.dumps({"sha256": digests, "qa_plugin": str(output), "qa_place": str(args.output_dir / "AccessForge21QA.rbxl"), "status": "PACKAGING ONLY; native tests not yet run"}, indent=2))
