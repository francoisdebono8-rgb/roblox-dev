"""Read-only source/binary gate for the five Forge Studio 0.2.5 candidates.

This verifies packaging, not Studio behavior or visual acceptance.
Historical dist artifacts are never rewritten.
"""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
PRODUCTS = ("SchemaForge", "PresetForge", "CurveForge", "AccessForge", "JointForge")
FORBIDDEN = ("/Users/", "/private/", "GetAsync(", "PostAsync(", "RequestAsync(",
             "loadstring(", "HttpGet(", "telemetry", "analytics")


def build(rojo, project, output):
    subprocess.run([rojo, "build", str(project), "-o", str(output)],
                   check=True, stdout=subprocess.DEVNULL)


def inspect_model(model, expected):
    assert model.get("class") == "Model", "Root must be a Model"
    found = {}
    containers = set()

    def walk(item, parent):
        name = item.findtext("Properties/string[@name='Name']")
        assert name, "Unnamed instance"
        path = f"{parent}/{name}" if parent else name
        cls = item.get("class")
        if cls in {"Script", "ModuleScript"}:
            assert path in expected and path not in found, f"Unexpected script: {path}"
            expected_class, source = expected[path]
            assert cls == expected_class, f"Wrong script class: {path}"
            assert item.findtext("Properties/bool[@name='Disabled']") != "true", path
            code = item.findtext("Properties/*[@name='Source']") or ""
            assert code == source.read_text(), f"Source mismatch: {path}"
            for value in FORBIDDEN:
                assert value not in code, f"Review prohibited content in {path}: {value}"
            found[path] = hashlib.sha256(code.encode()).hexdigest()
        else:
            assert cls == "Folder" and path == "Modules", f"Unexpected container: {path}"
            assert path not in containers, f"Duplicate container: {path}"
            containers.add(path)
        for child in item.findall("Item"):
            walk(child, path)

    for item in model.findall("Item"):
        walk(item, "")
    assert set(found) == set(expected), "Missing production sources"
    assert containers == {"Modules"}, "Missing Modules container"
    return found


def verify(rojo, title):
    product = ROOT / "products" / title.lower()
    source = product / title
    artifact = product / "ui" / "forge-0.2.5" / f"{title}-ForgeStudio-0.2.5.rbxm"
    assert artifact.is_file(), f"Candidate missing: {artifact.relative_to(ROOT)}"
    expected = {"Main": ("Script", source / "Main.plugin.luau")}
    expected.update({f"Modules/{p.stem}": ("ModuleScript", p)
                     for p in (source / "Modules").glob("*.luau")})
    with tempfile.TemporaryDirectory(prefix="forge-freeze-check-") as tmp:
        folder = Path(tmp)
        binary = folder / "rebuilt.rbxm"
        build(rojo, product / "release.project.json", binary)
        assert binary.read_bytes() == artifact.read_bytes(), "Candidate differs from source rebuild"
        project = folder / "import.project.json"
        project.write_text(json.dumps({"name": title, "tree": {"$path": str(artifact)}}))
        xml = folder / "imported.rbxmx"
        build(rojo, project, xml)
        roots = ET.parse(xml).getroot().findall("Item")
        assert len(roots) == 1, "Multiple roots in commercial package"
        sources = inspect_model(roots[0], expected)
    return {"product": title, "packaging": "PASS", "catalogueRelease": "Forge Studio 0.2.5",
            "artifact": str(artifact.relative_to(ROOT)),
            "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
            "sourceCount": len(sources), "sources": sources,
            "nativeGate": "NOT ASSERTED BY THIS CHECK"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo")
    parser.add_argument("--only", choices=PRODUCTS)
    args = parser.parse_args()
    results = []
    failed = False
    for title in (args.only,) if args.only else PRODUCTS:
        try:
            results.append(verify(args.rojo, title))
        except (AssertionError, OSError, subprocess.CalledProcessError) as error:
            results.append({"product": title, "packaging": "FAIL", "reason": str(error)})
            failed = True
    print(json.dumps(results, indent=2))
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
