"""Build and verify CurveForge 0.2.5 plus a separate, exact-artifact native QA kit."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
PRODUCT = HERE.parent.parent
REPO = PRODUCT.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--compiler", default="luau-compile")
args = parser.parse_args()
artifact = HERE / "CurveForge-ForgeStudio-0.2.5.rbxm"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def sources(item):
    result = {}
    for node in item.iter("Item"):
        if node.get("class") in {"Script", "ModuleScript"}:
            name = node.findtext("Properties/string[@name='Name']")
            assert name not in result
            result[name] = node.findtext("Properties/*[@name='Source']") or ""
    return result


def build(project, output):
    subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True, capture_output=True)


def tree_build(tree, name, project, output):
    project.write_text(json.dumps({"name": name, "tree": tree}))
    build(project, output)


expected = {"Main": PRODUCT / "CurveForge/Main.plugin.luau"}
expected.update({path.stem: path for path in (PRODUCT / "CurveForge/Modules").glob("*.luau")})
texts = {name: path.read_text() for name, path in expected.items()}
historical = [PRODUCT / "dist/CurveForge-v1.0.0.rbxm", PRODUCT / "dist/CurveForge-v1.1.0.rbxm", PRODUCT / "ui/CurveForge-v1.1.0-ui26.rbxm"]
historical_hashes = {}
# Git objects at the pinned checkpoint retain their original products/ paths.
for path in historical:
    original = subprocess.check_output(["git", "show", "bff0d9d:" + path.relative_to(REPO).as_posix().replace("plugins/", "products/", 1)], cwd=REPO)
    assert path.read_bytes() == original, "Historical binary changed: " + str(path)
    historical_hashes[str(path.relative_to(PRODUCT))] = sha(original)
for name in ("Engine", "Curve", "Settings", "ForgeMark"):
    original = subprocess.check_output(["git", "show", "bff0d9d:" + expected[name].relative_to(REPO).as_posix().replace("plugins/", "products/", 1)], cwd=REPO)
    assert expected[name].read_bytes() == original, "Protected source changed: " + name

compile_paths = [*expected.values(), *HERE.glob("*.luau"), PRODUCT / "tests/Suite.luau", PRODUCT / "tests/V11.spec.luau"]
subprocess.run([args.compiler, "--null", *map(str, compile_paths)], check=True)

with tempfile.TemporaryDirectory(prefix="curveforge025-") as temporary:
    temp = Path(temporary)
    project = temp / "build.project.json"
    build(PRODUCT / "release.project.json", artifact)
    build(PRODUCT / "release.project.json", temp / "repeat.rbxm")
    assert artifact.read_bytes() == (temp / "repeat.rbxm").read_bytes(), "Nondeterministic binary"
    tree_build({"$path": str(artifact)}, "CurveForge", project, temp / "candidate.rbxmx")
    candidate_doc = ET.parse(temp / "candidate.rbxmx")
    candidate = candidate_doc.getroot().find("Item")
    assert sources(candidate) == texts, "Embedded sources differ"
    assert len(list(candidate.iter("Item"))) == len(texts) + 2
    assert all(item.get("class") in {"Model", "Folder", "Script", "ModuleScript"} for item in candidate.iter("Item"))
    for source in texts.values():
        for forbidden in ("loadstring", "GetAsync", "PostAsync", "/Users/", "CurveForge025QA", "[CurveForge025]"):
            assert forbidden not in source, forbidden
    enabled = [item for item in candidate.iter("Item") if item.get("class") == "Script" and item.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Main"

    # Disable only imported duplicate Main scripts; retain all embedded source strings.
    import_trees = {}
    imported_sources = {}
    for name, path in (("Candidate", artifact), ("Legacy", historical[0])):
        xml = temp / (name + ".rbxmx")
        tree_build({"$path": str(path)}, name, project, xml)
        doc = ET.parse(xml); model = doc.getroot().find("Item")
        imported_sources[name] = sources(model)
        for item in model.iter("Item"):
            if item.get("class") == "Script":
                props = item.find("Properties")
                disabled = props.find("bool[@name='Disabled']")
                if disabled is None:
                    disabled = ET.SubElement(props, "bool", name="Disabled")
                disabled.text = "true"
        doc.write(xml, encoding="utf-8", xml_declaration=True)
        import_trees[name] = {"$path": str(xml)}

    tests = {"Suite": PRODUCT / "tests/Suite.luau", "V11": PRODUCT / "tests/V11.spec.luau",
             "Context": HERE / "Context.spec.luau", "View": HERE / "View.spec.luau", "Fixture": HERE / "Fixture.luau"}
    qa_tree = {"$className": "Model", "$attributes": {"CandidateSHA256": sha(artifact.read_bytes()), "CatalogueRelease": "Forge Studio 0.2.5"},
               **import_trees, "Tests": {"$className": "Folder", **{name: {"$path": str(path)} for name, path in tests.items()}}}
    qa_import = HERE / "CurveForge-0.2.5-QA-import.rbxm"
    tree_build(qa_tree, "CurveForge025QA", project, qa_import)
    tree_build({"$path": str(qa_import)}, "CurveForge025QA", project, temp / "check.rbxmx")
    verified = ET.parse(temp / "check.rbxmx").getroot().find("Item")
    for name, original_sources in imported_sources.items():
        imported = next(item for item in verified.findall("Item") if item.findtext("Properties/string[@name='Name']") == name)
        assert sources(imported) == original_sources
    assert all(item.findtext("Properties/bool[@name='Disabled']") == "true" for item in verified.iter("Item") if item.get("class") == "Script")
    runner = HERE / "CurveForge-0.2.5-QA-runner.rbxm"
    tree_build({"$className": "Model", "Runner": {"$path": str(HERE / "Runner.plugin.luau")}}, "CurveForge025Runner", project, runner)
    place = HERE / "CurveForge-0.2.5-QA.rbxl"
    tree_build({"$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": {"CurveForge025QA": True}},
                "ServerStorage": {"$className": "ServerStorage", "CurveForge025QA": {"$path": str(qa_import)}},
                "Lighting": {"$className": "Lighting", "$properties": {"Technology": "ShadowMap", "Brightness": 2, "ClockTime": 14}}},
               "CurveForge025QA", project, place)

manifest = {
    "product": "CurveForge", "productVersion": "1.1.0", "catalogueRelease": "Forge Studio 0.2.5",
    "canonicalAssetId": "90642263224333", "baselineCommit": "bff0d9d",
    "artifact": artifact.name, "sha256": sha(artifact.read_bytes()),
    "sourceVerification": {"status": "PASS", "deterministicRebuild": True, "embeddedSourceEquality": True,
                           "productionOnly": True, "protectedEngineAndBrandUnchanged": True,
                           "sources": {str(path.relative_to(PRODUCT)): sha(path.read_bytes()) for path in expected.values()}},
    "historicalArtifacts": historical_hashes,
    "qaArtifacts": {path.name: sha(path.read_bytes()) for path in (qa_import, runner, place)},
    "qaSourceSha256": {str(path.relative_to(PRODUCT)): sha(path.read_bytes()) for path in [*tests.values(), HERE / "Runner.plugin.luau"]},
    "gates": {"luauCompilation": "PASS", "exactArtifactPackaging": "PASS", "nativeRegression": "NOT RUN",
              "contextReadOnlyAndHistory": "NOT RUN", "installedMainAndGUI": "NOT RUN", "nativeScreenshots": "NOT CAPTURED",
              "lightDarkSanity": "NOT RUN", "visualAcceptance": "PENDING"},
    "nativeExpected": {"baseline": 9, "technical": 42, "context": 5, "viewCallbackSmoke": 7},
    "publication": "NOT PERFORMED",
}
(HERE / "candidate.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
print(json.dumps({"artifact": str(artifact), "sha256": manifest["sha256"], "offline": "PASS", "native": "NOT RUN"}, indent=2))
