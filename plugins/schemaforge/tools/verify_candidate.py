"""Rebuild and verify the unpublished 1.2.0 candidate without changing public artifacts."""
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
candidate = ROOT / "dist/SchemaForge-v1.2.0.rbxm"
if args.build:
    subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(candidate)], check=True)
expected = {"Main": ROOT / "SchemaForge/Main.plugin.luau"}
expected.update({p.stem: p for p in (ROOT / "SchemaForge/Modules").glob("*.luau")})
with tempfile.TemporaryDirectory(prefix="schemaforge-candidate-") as temp:
    binary, xml = Path(temp) / "rebuilt.rbxm", Path(temp) / "imported.rbxmx"
    subprocess.run([args.rojo, "build", str(ROOT / "release.project.json"), "-o", str(binary)], check=True)
    assert binary.read_bytes() == candidate.read_bytes(), "Candidate/source mismatch"
    project = Path(temp) / "import.project.json"
    project.write_text(json.dumps({"name": "SchemaForge", "tree": {"$path": str(candidate)}}))
    subprocess.run([args.rojo, "build", str(project), "-o", str(xml)], check=True)
    model = ET.parse(xml).getroot().find("Item")
    assert model.get("class") == "Model" and len(list(model.iter("Item"))) == 7
    hashes = {}
    for item in model.iter("Item"):
        assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
        if item.get("class") not in {"Script", "ModuleScript"}:
            continue
        name = item.findtext("Properties/string[@name='Name']")
        source = item.findtext("Properties/*[@name='Source']") or ""
        assert name in expected and name not in hashes and source == expected[name].read_text()
        for forbidden in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "require(0", "/Users/", "TechnicalGate", "SchemaForgeV12", "AnalyticsService"):
            assert forbidden not in source, forbidden
        hashes[name] = hashlib.sha256(source.encode()).hexdigest()
    assert len(hashes) == 5
manifest = {"version": "1.2.0", "status": "unpublished technical candidate", "artifact": candidate.name,
            "sha256": hashlib.sha256(candidate.read_bytes()).hexdigest(), "source_sha256": hashes}
(ROOT / "dist/candidate-1.2.0.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(json.dumps(manifest, indent=2))
print("PASS: five production sources, single-model candidate, reproducible bytes; no native execution claimed")
