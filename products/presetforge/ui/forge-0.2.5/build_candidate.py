"""Build PresetForge 0.2.5 and a separate exact-binary native QA package. No Studio I/O."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
PRODUCT = HERE.parent.parent
REPO = PRODUCT.parent.parent
sys.path.insert(0, str(HERE.parent))
from build_demo import node, part, scene

BASELINE = "92e4463"
CATALOGUE = "Forge Studio 0.2.5"
VERSION = "2.2.0"
ARTIFACT = "PresetForge-ForgeStudio-0.2.5.rbxm"
SPECS = ["Schema.spec", "CapturePreview.spec", "ScopePreview.spec", "ApplyService.spec",
         "PresetStore.spec", "ProjectStore.spec", "Workflow.spec", "NativeRelease.spec",
         "Layout.spec", "GateTestSupport"]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(REPO).as_posix()


def named(item, name):
    return next(node for node in item.findall("Item")
                if node.findtext("Properties/string[@name='Name']") == name)


def sources(item):
    found = {}
    for node in item.iter("Item"):
        if node.get("class") in {"Script", "ModuleScript", "LocalScript"}:
            name = node.findtext("Properties/string[@name='Name']")
            assert name not in found, f"Duplicate source: {name}"
            found[name] = node.findtext("Properties/*[@name='Source']") or ""
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="/private/tmp/jointforge-tools/rojo/rojo")
    parser.add_argument("--compile", dest="compiler", default="/private/tmp/jointforge-tools/luau/luau-compile")
    args = parser.parse_args()
    qa = HERE / "qa"
    qa.mkdir(exist_ok=True)
    source_paths = sorted((PRODUCT / "PresetForge").rglob("*.luau"))
    qa_paths = sorted((PRODUCT / "tests").glob("*.luau")) + sorted(HERE.glob("*.luau"))
    protected_paths = sorted((PRODUCT / "dist").glob("*")) + [
        HERE.parent / "PresetForge-v2.2.0-ui24.rbxm", PRODUCT / "demo/PresetForge-Demo.rbxl"]
    protected = {relative(p): digest(p) for p in protected_paths if p.is_file()}
    input_paths = source_paths + qa_paths + [Path(__file__).resolve(), HERE.parent / "build_demo.py", PRODUCT / "release.project.json"]
    input_hashes = {relative(p): digest(p) for p in input_paths}
    expected = {"Main" if p.name == "Main.plugin.luau" else p.stem: p.read_text() for p in source_paths}
    production_hashes = {relative(p): digest(p) for p in source_paths}
    unchanged = []
    for path in source_paths:
        if path.name not in {"Constants.luau", "UIFactory.luau"}:
            baseline = subprocess.check_output(["git", "show", f"{BASELINE}:{relative(path)}"], cwd=REPO)
            assert baseline == path.read_bytes(), f"Engine/Main changed since accepted checkpoint: {path}"
            unchanged.append(relative(path))
    for source in expected.values():
        assert not re.search(r"(?:HttpGet|HttpPost|RequestAsync|GetAsync|PostAsync|loadstring|InsertService|MessagingService|DataStoreService|require\s*\(\s*\d)", source)
    for path in source_paths + qa_paths:
        subprocess.run([args.compiler, str(path)], check=True, stdout=subprocess.DEVNULL)

    with tempfile.TemporaryDirectory(prefix="presetforge025-") as temp:
        temp = Path(temp)
        project = temp / "build.project.json"

        def build(tree, output, name="PresetForge025QA"):
            project.write_text(json.dumps({"name": name, "tree": tree}))
            subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True,
                           stdout=subprocess.DEVNULL)

        artifact = HERE / ARTIFACT
        subprocess.run([args.rojo, "build", str(PRODUCT / "release.project.json"), "-o", str(artifact)], check=True)
        rebuilt = temp / "rebuilt.rbxm"
        subprocess.run([args.rojo, "build", str(PRODUCT / "release.project.json"), "-o", str(rebuilt)], check=True,
                       stdout=subprocess.DEVNULL)
        assert artifact.read_bytes() == rebuilt.read_bytes(), "Independent candidate rebuild differs"
        commercial_sha = digest(artifact)
        artifacts = {"PresetForge": artifact, "Legacy20": PRODUCT / "dist/PresetForge-v2.0.0.rbxm",
                     "Legacy21": PRODUCT / "dist/PresetForge-v2.1.0.rbxm"}
        hashes = {name: digest(path) for name, path in artifacts.items()}
        attrs = {("Candidate" if name == "PresetForge" else name) + "SHA256": sha for name, sha in hashes.items()}
        attrs.update(SourceMatchVerified=True, StaticSafetyVerified=True, Artifact=ARTIFACT)
        fixture = scene()
        fixture_tree = fixture["tree"]
        supports = node("Folder")
        for row in range(5):
            for side, x in enumerate((-33, 33)):
                supports[f"Rail support {row + 1:02}-{side + 1}"] = part(
                    [x, 5, -16 + row * 8], [.3, 10, .3], [.25, .27, .29], "Metal")
        fixture_tree["Workspace"]["Workshop"]["RailSupports"] = supports
        fixture_place = HERE / "PresetForge-LightingWorkshop.rbxl"
        build(fixture_tree, fixture_place, fixture["name"])
        fixture_xml = temp / "fixture.rbxmx"
        fixture_assets = {"$className": "Model", "Workshop": fixture_tree["Workspace"]["Workshop"],
                         "Storage": {"$className": "Folder",
                                     "ReferenceFixture": fixture_tree["ServerStorage"]["ReferenceFixture"],
                                     "PresetForgeProjectRecipes": fixture_tree["ServerStorage"]["PresetForgeProjectRecipes"]}}
        build(fixture_assets, fixture_xml)
        fixture_root = ET.parse(fixture_xml).getroot().find("Item")
        assert not sources(fixture_root), "Fixture must be script-free"
        descendants = list(named(fixture_root, "Workshop").iter("Item"))[1:]
        assert len(descendants) == 197
        lights = [n for n in descendants if n.get("class") == "PointLight"]
        assert len(lights) == 40
        assert sum(float(n.findtext("Properties/float[@name='Brightness']")) == 2 for n in lights) == 30
        assert sum(float(n.findtext("Properties/float[@name='Brightness']")) == 5 for n in lights) == 10

        tests = {"$className": "Folder", **{n: {"$path": str(PRODUCT / "tests" / (n + ".luau"))} for n in SPECS},
                 "V22": {"$path": str(PRODUCT / "tests/V22.spec.luau")},
                 "HeroWorkflow": {"$path": str(HERE / "HeroWorkflow.spec.luau")}}
        tree = {"$className": "Model", "$attributes": attrs,
                **{n: {"$path": str(p)} for n, p in artifacts.items()},
                "Runner": {"$path": str(HERE / "NativeGate.plugin.luau")},
                "Tests": tests, "FixtureAssets": {"$path": str(fixture_xml)}}
        imported = temp / "imported.rbxmx"
        build(tree, imported)
        doc = ET.parse(imported)
        root = doc.getroot().find("Item")
        candidate = named(root, "PresetForge")
        assert sources(candidate) == expected, "Candidate Sources differ from working tree"
        assert len(list(candidate.iter("Item"))) == len(expected) + 2
        assert len(candidate.findall("Item")) == 2
        original_sources = {}
        for name in artifacts:
            item = named(root, name)
            original_sources[name] = sources(item)
            assert all(n.get("class") in {"Model", "Folder", "Script", "ModuleScript"} for n in item.iter("Item"))
            scripts = [n for n in item.iter("Item") if n.get("class") == "Script"]
            assert len(scripts) == 1 and scripts[0] == named(item, "Main")
            props = scripts[0].find("Properties")
            disabled = props.find("bool[@name='Disabled']")
            if name == "PresetForge":
                assert disabled is None or disabled.text != "true", "Commercial Main must be enabled"
            if disabled is None:
                disabled = ET.SubElement(props, "bool", name="Disabled")
            disabled.text = "true"
        doc.write(imported, encoding="utf-8", xml_declaration=True)
        qa_plugin = qa / "PresetForge025Gate.rbxm"
        build({"$path": str(imported)}, qa_plugin)
        verified = temp / "verified.rbxmx"
        build({"$path": str(qa_plugin)}, verified)
        final = ET.parse(verified).getroot().find("Item")
        for name, path in artifacts.items():
            assert sources(named(final, name)) == original_sources[name]
            assert digest(path) == hashes[name]
        enabled = [n for n in final.iter("Item") if n.get("class") == "Script"
                   and n.findtext("Properties/bool[@name='Disabled']") != "true"]
        assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
        qa_place = qa / "PresetForge025Gate.rbxl"
        build({"$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": {"PresetForge025Gate": True}}}, qa_place)

    assert protected == {p: digest(REPO / p) for p in protected}, "Historical/user files changed during build"
    assert input_hashes == {p: digest(REPO / p) for p in input_hashes}, "Source changed during packaging"
    manifest = {
        "product": "PresetForge", "productVersion": VERSION, "catalogueRelease": CATALOGUE,
        "artifact": ARTIFACT, "artifactPathBase": "candidate.json directory", "sha256": commercial_sha,
        "baselineCommit": BASELINE, "canonicalAssetId": "73596873703054", "published": False,
        "sourceVerification": {"status": "PASS", "sourceCount": len(expected), "sources": production_hashes,
            "allEmbeddedSourcesEqual": True, "independentBuildByteEqual": True, "commercialMainEnabled": True,
            "commercialContainsOnlyMainAndModules": True, "qaReimportSourcesEqual": True,
            "engineAndMainUnchangedSinceBaseline": unchanged, "compiledLuauFiles": len(source_paths + qa_paths)},
        "protectedFiles": protected,
        "fixture": {"path": fixture_place.name, "sha256": digest(fixture_place), "scriptFree": True,
            "expectedMetrics": {"scanned": 197, "compatible": 40, "affected": 30, "matching": 10,
                                "ignored": 157, "propertyWrites": 60, "tagWrites": 0, "attributeWrites": 0}},
        "qa": {"plugin": "qa/" + qa_plugin.name, "sha256": digest(qa_plugin), "place": "qa/" + qa_place.name,
            "placeSha256": digest(qa_place), "prefix": "[PresetForge025Gate]", "expectedChecks": 94,
            "mode": "local Studio Edit, empty place, Workspace.PresetForge025Gate=true",
            "inputs": {p: sha for p, sha in input_hashes.items() if p not in production_hashes},
            "nativeStatus": "NON TESTED", "installedGuiProof": False},
        "gates": {"offlineCompilation": "PASS", "sourceArtifactEquality": "PASS", "historicalArtifactsPreserved": "PASS",
            "fixtureStructure": "PASS", "nativeRegression94": "NON TESTED", "installedMainWorkflow": "NON TESTED",
            "dark240320400560": "NON TESTED", "lightSanity": "NON TESTED", "longPathNative": "NON TESTED",
            "visualReview": "NON TESTED", "freezeReady": False},
    }
    (HERE / "candidate.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"artifact": str(artifact), "sha256": commercial_sha, "qa": str(qa_plugin),
                      "compiled": len(source_paths + qa_paths), "sources": len(expected),
                      "offline": "PASS", "native": "NON TESTED", "expectedChecks": 94}, indent=2))


if __name__ == "__main__":
    main()
