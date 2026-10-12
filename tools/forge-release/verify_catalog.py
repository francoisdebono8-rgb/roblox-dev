"""Read-only reproducibility and production-source audit of the three packages."""
from pathlib import Path
import argparse
import hashlib
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--rojo", default="rojo")
args = parser.parse_args()
for title, version in (("PresetForge", "2.1.0"), ("JointForge", "1.0.0"), ("CurveForge", "1.0.0")):
    product = ROOT / "plugins" / title.lower()
    source = product / title
    expected = {"Main": source / "Main.plugin.luau"}
    expected.update({p.stem: p for p in (source / "Modules").glob("*.luau")})
    artifact = product / "dist" / f"{title}-v{version}.rbxm"
    with tempfile.TemporaryDirectory() as tmp:
        binary, xml = Path(tmp) / "release.rbxm", Path(tmp) / "release.rbxmx"
        for output in (binary, xml):
            subprocess.run([args.rojo, "build", str(product / "release.project.json"), "-o", str(output)], check=True, stdout=subprocess.DEVNULL)
        assert binary.read_bytes() == artifact.read_bytes(), f"{title}: stale artifact"
        found = set()
        scripts = 0
        for item in ET.parse(xml).iter("Item"):
            cls = item.get("class")
            assert cls in {"Model", "Folder", "Script", "ModuleScript"}, cls
            if cls not in {"Script", "ModuleScript"}:
                continue
            scripts += cls == "Script"
            properties = item.find("Properties")
            name = properties.findtext("string[@name='Name']")
            code = properties.findtext("*[@name='Source']") or ""
            assert name in expected and name not in found, name
            assert code == expected[name].read_text(), name
            for forbidden in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "require(0", "/Users/", "/private/", "Tests", "ForgeCatalogGate", "Demo", "telemetry", "analytics"):
                assert forbidden not in code, (title, name, forbidden)
            found.add(name)
        assert found == set(expected) and scripts == 1
    print(f"PASS {title} {version}: {len(found)} exact sources, clean hierarchy, reproducible binary, SHA256 {hashlib.sha256(artifact.read_bytes()).hexdigest()}")
