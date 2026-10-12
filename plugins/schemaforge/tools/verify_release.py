"""Rebuild and verify the exact production-only plugin."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--rojo", default="rojo")
args = parser.parse_args()
expected = {"Main": root / "SchemaForge/Main.plugin.luau"}
expected.update({p.stem: p for p in (root / "SchemaForge/Modules").glob("*.luau")})
release = root / "dist/SchemaForge-v1.1.0.rbxm"
with tempfile.TemporaryDirectory() as temp:
    binary, xml = Path(temp) / "release.rbxm", Path(temp) / "release.rbxmx"
    for target in (binary, xml):
        subprocess.run([args.rojo, "build", str(root / "release.project.json"), "-o", str(target)], check=True)
    assert binary.read_bytes() == release.read_bytes(), "Artifact/source mismatch"
    found = {}
    tree = ET.parse(xml)
    model = tree.getroot().find("Item")
    assert model.get("class") == "Model" and len(model.findall("Item")) == 2
    for item in tree.iter("Item"):
        assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
        if item.get("class") not in {"Script", "ModuleScript"}:
            continue
        props = item.find("Properties")
        name = props.find("string[@name='Name']").text
        source = props.find("*[@name='Source']").text or ""
        assert name in expected and name not in found
        assert source == expected[name].read_text(), name
        for forbidden in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "require(0", "/Users/", "SchemaForgeTests", "SchemaForgeMedia", "telemetry", "AnalyticsService"):
            assert forbidden not in source, forbidden
        found[name] = hashlib.sha256(source.encode()).hexdigest()
    assert set(found) == set(expected)
manifest = {"version": "1.1.0", "artifact": release.name, "sha256": hashlib.sha256(release.read_bytes()).hexdigest(), "source_sha256": found}
(root / "dist/manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(f"PASS: {len(found)} exact sources, reproducible binary, no test/demo/network requests")
