"""Build a disposable native UI harness around an exact commercial candidate."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from build_demo import scene

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--artifact", type=Path, default=HERE / "PresetForge-v2.2.0-ui24.rbxm")
parser.add_argument("--output", type=Path, default=Path("/tmp/PresetForge23UI"))
parser.add_argument("--width", type=int, default=560)
parser.add_argument("--height", type=int, default=640)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
digest = hashlib.sha256(args.artifact.read_bytes()).hexdigest()
with tempfile.TemporaryDirectory(prefix="presetforge-ui-") as temp:
    project = Path(temp) / "gate.project.json"
    xml = Path(temp) / "gate.rbxmx"
    project.write_text(json.dumps({"name": "PresetForgeUIGate", "tree": {
        "$className": "Model", "$attributes": {"SHA256": digest},
        "Candidate": {"$path": str(args.artifact.resolve())},
        "Runner": {"$path": str(HERE / "Harness.plugin.luau")}
    }}))
    def build(output):
        subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True)
    build(xml)
    doc = ET.parse(xml)
    candidate = next(n for n in doc.getroot().find("Item").findall("Item") if n.findtext("Properties/string[@name='Name']") == "Candidate")
    imported = {n.findtext("Properties/string[@name='Name']"): n.findtext("Properties/*[@name='Source']") or ""
                for n in candidate.iter("Item") if n.get("class") in {"Script", "ModuleScript"}}
    expected = {"Main": (HERE.parent / "PresetForge/Main.plugin.luau").read_text()}
    expected.update({p.stem: p.read_text() for p in (HERE.parent / "PresetForge/Modules").glob("*.luau")})
    assert imported == expected and len(imported) == len(expected)
    assert len(list(candidate.iter("Item"))) == len(expected) + 2
    assert all(n.get("class") in {"Model", "Folder", "Script", "ModuleScript"} for n in candidate.iter("Item"))
    scripts = [n for n in doc.iter("Item") if n.get("class") == "Script"]
    main = next(n for n in scripts if n.findtext("Properties/string[@name='Name']") == "Main")
    properties = main.find("Properties")
    disabled = properties.find("bool[@name='Disabled']")
    if disabled is None:
        disabled = ET.SubElement(properties, "bool", name="Disabled")
    disabled.text = "true"
    doc.write(xml, encoding="utf-8", xml_declaration=True)
    project.write_text(json.dumps({"name": "PresetForgeUIGate", "tree": {"$path": str(xml)}}))
    build(args.output / "PresetForgeUIGate.rbxm")
    project.write_text(json.dumps({"name": "PresetForgeUIGate", "tree": {"$path": str((args.output / "PresetForgeUIGate.rbxm").resolve())}}))
    verified = Path(temp) / "verified.rbxmx"
    build(verified)
    final = ET.parse(verified).getroot().find("Item")
    final_candidate = next(n for n in final.findall("Item") if n.findtext("Properties/string[@name='Name']") == "Candidate")
    final_sources = {n.findtext("Properties/string[@name='Name']"): n.findtext("Properties/*[@name='Source']") or ""
                     for n in final_candidate.iter("Item") if n.get("class") in {"Script", "ModuleScript"}}
    assert final_sources == imported
    assert hashlib.sha256(args.artifact.read_bytes()).hexdigest() == digest
    enabled = [n for n in final.iter("Item") if n.get("class") == "Script" and n.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
    project.write_text(json.dumps(scene(review=True, width=args.width, height=args.height)))
    build(args.output / "PresetForgeUIGate.rbxl")
print("Exact imported candidate SHA256:", digest)
