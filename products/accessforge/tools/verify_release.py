"""Verify the release's reproducible bytes, exact sources and closed instance tree."""
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
expected = {"Main": ROOT / "AccessForge/Main.plugin.luau"}
expected.update({p.stem: p for p in (ROOT / "AccessForge/Modules").glob("*.luau")})
release = ROOT / "dist/AccessForge-v1.0.0.rbxm"
with tempfile.TemporaryDirectory() as temp:
    binary, xml = Path(temp) / "release.rbxm", Path(temp) / "release.rbxmx"
    for target in (binary, xml):
        subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(target)], check=True)
    assert binary.read_bytes() == release.read_bytes(), "Artifact differs from final sources"
    found = {}
    tree = ET.parse(xml)
    root = tree.getroot().find("Item")
    assert root.get("class") == "Model"
    assert len(root.findall("Item")) == 2
    for item in tree.iter("Item"):
        assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
        if item.get("class") not in {"Script", "ModuleScript"}:
            continue
        props = item.find("Properties")
        name = props.find("string[@name='Name']").text
        source = props.find("*[@name='Source']").text or ""
        assert name in expected and name not in found
        assert source == expected[name].read_text(), name
        for forbidden in ("HttpService", "GetAsync", "PostAsync", "loadstring", "require(0", "/Users/", "AccessForgeTests", "AccessForgeDemo", "telemetry"):
            assert forbidden not in source, forbidden
        found[name] = hashlib.sha256(source.encode()).hexdigest()
    assert set(found) == set(expected)
manifest = {"version": "1.0.0", "artifact": release.name, "sha256": hashlib.sha256(release.read_bytes()).hexdigest(), "source_sha256": found}
(ROOT / "dist/manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(f"PASS: {len(found)} exact sources; reproducible binary; no tests, demo or network code")
