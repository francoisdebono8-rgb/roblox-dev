"""Build isolated native QA from exact candidate and historical V1 binaries, never sources."""
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
parser.add_argument("--output-dir", type=Path, default=Path(tempfile.gettempdir()) / "CurveForge18QA")
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)

def build(project, output):
    subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True)

def named(item, name):
    return next(node for node in item.findall("Item") if node.findtext("Properties/string[@name='Name']") == name)

def sources(root):
    result = {}
    for item in root.iter("Item"):
        if item.get("class") in {"Script", "ModuleScript"}:
            name = item.findtext("Properties/string[@name='Name']")
            assert name not in result
            result[name] = item.findtext("Properties/*[@name='Source']") or ""
    return result

with tempfile.TemporaryDirectory(prefix="curveforge-technical-") as temp:
    directory = Path(temp)
    artifacts = {"Candidate": ROOT / "dist/CurveForge-v1.1.0.rbxm", "Legacy": ROOT / "dist/CurveForge-v1.0.0.rbxm"}
    digests = {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in artifacts.items()}
    project = directory / "gate.project.json"
    project.write_text(json.dumps({"name": "CurveForgeTechnicalGate", "tree": {
        "$className": "Model", "$attributes": {key + "SHA256": value for key, value in digests.items()},
        **{key: {"$path": str(path)} for key, path in artifacts.items()},
        "Runner": {"$path": str(ROOT / "tests/TechnicalGate.plugin.luau")},
        "Tests": {"$className": "Folder", "Suite": {"$path": str(ROOT / "tests/Suite.luau")}, "V11": {"$path": str(ROOT / "tests/V11.spec.luau")}}
    }}))
    xml = directory / "gate.rbxmx"
    build(project, xml)
    doc = ET.parse(xml); root = doc.getroot().find("Item")
    expected = {"Main": (ROOT / "CurveForge/Main.plugin.luau").read_text()}
    expected.update({path.stem: path.read_text() for path in (ROOT / "CurveForge/Modules").glob("*.luau")})
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
    project.write_text(json.dumps({"name": "CurveForgeTechnicalGate", "tree": {"$path": str(xml)}}))
    output = args.output_dir / "CurveForgeTechnicalGate.rbxm"
    build(project, output)
    project.write_text(json.dumps({"name": "CurveForgeTechnicalGate", "tree": {"$path": str(output.resolve())}}))
    check = directory / "verified.rbxmx"; build(project, check)
    verified = ET.parse(check).getroot().find("Item")
    for key in artifacts:
        assert sources(named(verified, key)) == original_sources[key]
        assert hashlib.sha256(artifacts[key].read_bytes()).hexdigest() == digests[key]
    enabled = [item for item in verified.iter("Item") if item.get("class") == "Script" and item.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
    project.write_text(json.dumps({"name": "CurveForge18QA", "tree": {"$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": {"CurveForgeTechnicalGate": True}}, "Lighting": {"$className": "Lighting", "$properties": {"Technology": "ShadowMap"}}}}))
    build(project, args.output_dir / "CurveForge18QA.rbxl")
print(json.dumps({"sha256": digests, "qa_plugin": str(output), "status": "PACKAGING ONLY; native tests not yet run"}, indent=2))
