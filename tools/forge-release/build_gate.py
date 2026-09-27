"""Build an isolated QA runner from the final commercial binary artifacts."""
from pathlib import Path
import argparse
import json
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
with tempfile.TemporaryDirectory() as directory:
    xml = Path(directory) / "gate.rbxmx"
    subprocess.run([args.rojo, "build", str(ROOT / "gate.project.json"), "-o", str(xml)], check=True)
    doc = ET.parse(xml)
    disabled = 0
    for item in doc.iter("Item"):
        if item.get("class") != "Script":
            continue
        props = item.find("Properties")
        if props.find("string[@name='Name']").text == "Runner":
            continue
        value = props.find("bool[@name='Disabled']")
        if value is None:
            value = ET.SubElement(props, "bool", name="Disabled")
        value.text = "true"
        disabled += 1
    assert disabled == 3, f"Expected three untouched commercial entry points, got {disabled}"
    doc.write(xml, encoding="utf-8", xml_declaration=True)
    project = Path(directory) / "gate.project.json"
    project.write_text(json.dumps({"name":"ForgeCatalogGate", "tree":{"$path":str(xml)}}))
    subprocess.run([args.rojo, "build", str(project), "-o", str(args.output)], check=True)
print("QA only: exact commercial code, entry scripts disabled to avoid duplicate toolbars")
