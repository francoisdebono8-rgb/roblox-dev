"""Verify Rojo's XML build against production sources and audit the allowlist."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--rojo", default="rojo")
args = parser.parse_args()
source = ROOT / "JointForge"
release = ROOT / "dist" / "JointForge-v1.0.0.rbxm"
expected = {"Main": source / "Main.plugin.luau"}
expected.update({p.stem: p for p in (source / "Modules").glob("*.luau")})
with tempfile.TemporaryDirectory() as tmp:
    binary = Path(tmp) / "release.rbxm"
    xml = Path(tmp) / "release.rbxmx"
    for target in (binary, xml):
        subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(target)], check=True)
    assert binary.read_bytes() == release.read_bytes(), "Binary does not match current sources"
    tree = ET.parse(xml)
    found = {}
    for node in tree.iter("Item"):
        cls = node.get("class")
        assert cls in {"Model", "Folder", "Script", "ModuleScript"}, cls
        if cls in {"Script", "ModuleScript"}:
            props = node.find("Properties")
            name = props.find("string[@name='Name']").text
            code = props.find("*[@name='Source']").text or ""
            assert name not in found and name in expected, name
            assert code == expected[name].read_text(), f"Source mismatch: {name}"
            for forbidden in ("HttpService", "GetAsync", "PostAsync", "require(0", "loadstring", "/Users/", "JointForgeTests", "Telemetry"):
                assert forbidden not in code, f"Unexpected release content: {forbidden}"
            found[name] = hashlib.sha256(code.encode()).hexdigest()
    assert set(found) == set(expected)
manifest = {"version": "1.0.0", "artifact": release.name, "sha256": hashlib.sha256(release.read_bytes()).hexdigest(), "source_sha256": found}
(ROOT / "dist" / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(f"PASS: {len(found)} exact production sources, reproducible binary, allowlisted hierarchy")
