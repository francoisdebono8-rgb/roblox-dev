"""Rebuild and verify the unpublished 1.1.0 candidate without changing public artifacts."""
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
parser.add_argument("--build", action="store_true")
args = parser.parse_args()
candidate = ROOT / "dist/JointForge-v1.1.0.rbxm"
assert hashlib.sha256((ROOT / "dist/JointForge-v1.0.0.rbxm").read_bytes()).hexdigest() == "24f43cf04c7d4e8cf92310b3c725f827e36b1ea22d9806e20325a4af4d2633bd", "Public V1 changed"
if args.build:
    subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(candidate)], check=True)
expected = {"Main": ROOT / "JointForge/Main.plugin.luau"}
expected.update({p.stem: p for p in (ROOT / "JointForge/Modules").glob("*.luau")})
with tempfile.TemporaryDirectory(prefix="jointforge-candidate-") as temp:
    binary, xml = Path(temp) / "rebuilt.rbxm", Path(temp) / "imported.rbxmx"
    subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(binary)], check=True)
    assert binary.read_bytes() == candidate.read_bytes(), "Candidate/source mismatch"
    project = Path(temp) / "import.project.json"
    project.write_text(json.dumps({"name": "JointForge", "tree": {"$path": str(candidate)}}))
    subprocess.run([args.rojo, "build", str(project), "-o", str(xml)], check=True)
    model = ET.parse(xml).getroot().find("Item")
    assert model.get("class") == "Model" and len(list(model.iter("Item"))) == 8
    hashes = {}
    for item in model.iter("Item"):
        assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
        if item.get("class") not in {"Script", "ModuleScript"}:
            continue
        name = item.findtext("Properties/string[@name='Name']")
        source = item.findtext("Properties/*[@name='Source']") or ""
        assert name in expected and name not in hashes and source == expected[name].read_text()
        for forbidden in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "require(0", "/Users/", "TechnicalGate", "JointForgeV11", "AnalyticsService"):
            assert forbidden not in source, forbidden
        hashes[name] = hashlib.sha256(source.encode()).hexdigest()
    assert len(hashes) == 6
manifest = {"version": "1.1.0", "status": "unpublished technical candidate", "artifact": candidate.name,
            "sha256": hashlib.sha256(candidate.read_bytes()).hexdigest(), "source_sha256": hashes}
(ROOT / "dist/candidate-1.1.0.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(json.dumps(manifest, indent=2))
print("PASS: six production sources, single-model candidate, reproducible bytes; no native execution claimed")
