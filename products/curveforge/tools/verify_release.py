"""Rebuild the artifact and verify every embedded source and instance class."""
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
parser.add_argument("--version", default="1.1.0")
args = parser.parse_args()
expected = {"Main": ROOT / "CurveForge/Main.plugin.luau"}
expected.update({p.stem: p for p in (ROOT / "CurveForge/Modules").glob("*.luau")})
release = ROOT / f"dist/CurveForge-v{args.version}.rbxm"
with tempfile.TemporaryDirectory() as temp:
    binary, xml = Path(temp) / "release.rbxm", Path(temp) / "release.rbxmx"
    for target in (binary, xml):
        subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(target)], check=True)
    assert binary.read_bytes() == release.read_bytes(), "Artifact differs from final sources"
    found = {}
    for item in ET.parse(xml).iter("Item"):
        assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
        if item.get("class") not in {"Script", "ModuleScript"}:
            continue
        props = item.find("Properties")
        name = props.find("string[@name='Name']").text
        source = props.find("*[@name='Source']").text or ""
        assert name in expected and name not in found
        assert source == expected[name].read_text(), name
        for forbidden in ("HttpService", "GetAsync", "PostAsync", "loadstring", "require(0", "/Users/", "CurveForgeTests", "CurveForgeDemo", "telemetry"):
            assert forbidden not in source, forbidden
        found[name] = hashlib.sha256(source.encode()).hexdigest()
    assert set(found) == set(expected)
manifest = {"version": args.version, "artifact": release.name, "sha256": hashlib.sha256(release.read_bytes()).hexdigest(), "source_sha256": found}
(ROOT / "dist/manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(f"PASS: {len(found)} exact sources; reproducible binary; no tests, demo or network code")
