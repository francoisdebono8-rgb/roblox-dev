"""Build opt-in isolated native QA importing the exact three commercial binaries."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--compile", dest="compiler")
parser.add_argument("--output-dir", type=Path, default=Path(tempfile.gettempdir()) / "PresetForge19QA")
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)

def build(project, output):
    subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True)

def named(item, name):
    return next(node for node in item.findall("Item") if node.findtext("Properties/string[@name='Name']") == name)

def sources(item):
    result = {}
    for node in item.iter("Item"):
        if node.get("class") in {"Script", "ModuleScript"}:
            name = node.findtext("Properties/string[@name='Name']")
            assert name not in result
            result[name] = node.findtext("Properties/*[@name='Source']") or ""
    return result

expected = {"Main": (ROOT / "PresetForge/Main.plugin.luau").read_text()}
expected.update({path.stem: path.read_text() for path in (ROOT / "PresetForge/Modules").glob("*.luau")})
for source in expected.values():
    assert not re.search(r"(?:HttpGet|HttpPost|RequestAsync|GetAsync|PostAsync|loadstring|InsertService|MessagingService|DataStoreService|require\s*\(\s*\d)", source)
if args.compiler:
    paths = list((ROOT / "PresetForge").rglob("*.luau")) + list((ROOT / "tests").glob("*.luau"))
    for path in paths:
        subprocess.run([args.compiler, str(path)], check=True, stdout=subprocess.DEVNULL)
    print(f"Compiled {len(paths)} Luau files")

artifacts = {"PresetForge": ROOT / "dist/PresetForge-v2.2.0.rbxm", "Legacy20": ROOT / "dist/PresetForge-v2.0.0.rbxm", "Legacy21": ROOT / "dist/PresetForge-v2.1.0.rbxm"}
digests = {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in artifacts.items()}
attrs = {("Candidate" if key == "PresetForge" else key) + "SHA256": value for key, value in digests.items()}
attrs.update(SourceMatchVerified=True, StaticSafetyVerified=True)
test_names = ["Schema.spec", "CapturePreview.spec", "ScopePreview.spec", "ApplyService.spec", "PresetStore.spec", "ProjectStore.spec", "Workflow.spec", "NativeRelease.spec", "GateTestSupport"]
with tempfile.TemporaryDirectory(prefix="presetforge19-") as temp:
    directory = Path(temp)
    project = directory / "gate.project.json"
    tree = {"$className": "Model", "$attributes": attrs,
            **{name: {"$path": str(path)} for name, path in artifacts.items()},
            "Runner": {"$path": str(ROOT / "tests/TechnicalGate.plugin.luau")},
            "Tests": {"$className": "Folder", "V22": {"$path": str(ROOT / "tests/V22.spec.luau")},
                      **{name: {"$path": str(ROOT / "tests" / (name + ".luau"))} for name in test_names}}}
    project.write_text(json.dumps({"name": "PresetForgeTechnicalGate", "tree": tree}))
    xml = directory / "gate.rbxmx"; build(project, xml)
    doc = ET.parse(xml); root = doc.getroot().find("Item")
    assert sources(named(root, "PresetForge")) == expected
    originals = {}
    for name in artifacts:
        item = named(root, name); originals[name] = sources(item)
        assert len(item.findall("Item")) == 2
        assert all(node.get("class") in {"Model", "Folder", "Script", "ModuleScript"} for node in item.iter("Item"))
        assert len([node for node in item.iter("Item") if node.get("class") == "Script"]) == 1
        props = named(item, "Main").find("Properties")
        disabled = props.find("bool[@name='Disabled']")
        if disabled is None: disabled = ET.SubElement(props, "bool", name="Disabled")
        disabled.text = "true"
    doc.write(xml, encoding="utf-8", xml_declaration=True)
    project.write_text(json.dumps({"name": "PresetForgeTechnicalGate", "tree": {"$path": str(xml)}}))
    output = args.output_dir / "PresetForgeTechnicalGate.rbxm"; build(project, output)
    project.write_text(json.dumps({"name": "PresetForgeTechnicalGate", "tree": {"$path": str(output.resolve())}}))
    check = directory / "verified.rbxmx"; build(project, check)
    verified = ET.parse(check).getroot().find("Item")
    for name, path in artifacts.items():
        assert sources(named(verified, name)) == originals[name]
        assert hashlib.sha256(path.read_bytes()).hexdigest() == digests[name]
    enabled = [node for node in verified.iter("Item") if node.get("class") == "Script" and node.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
    project.write_text(json.dumps({"name": "PresetForge19QA", "tree": {"$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": {"PresetForgeTechnicalGate": True}}}}))
    build(project, args.output_dir / "PresetForge19QA.rbxl")
print(json.dumps({"sha256": digests, "qa_plugin": str(output), "source_modules": len(expected), "status": "PACKAGING ONLY; native tests not yet run"}, indent=2))
