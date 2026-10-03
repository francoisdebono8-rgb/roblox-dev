"""Build current candidates and opt-in QA; never install, launch or publish."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
from fixture import build_fixture

HERE = Path(__file__).resolve().parent
PRODUCT = HERE.parents[1]
REPO = PRODUCT.parents[1]
BASELINE = "bff0d9d"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def named(item, name):
    return next(child for child in item.findall("Item") if child.findtext("Properties/string[@name='Name']") == name)


def sources(item):
    result = {}
    for node in item.iter("Item"):
        if node.get("class") in {"Script", "ModuleScript"}:
            name = node.findtext("Properties/string[@name='Name']")
            assert name not in result, name
            result[name] = node.findtext("Properties/*[@name='Source']") or ""
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="/private/tmp/jointforge-tools/rojo/rojo")
    parser.add_argument("--compiler", default="/private/tmp/jointforge-tools/luau/luau-compile")
    args = parser.parse_args()
    expected = {"Main": PRODUCT / "JointForge/Main.plugin.luau"}
    expected.update({p.stem: p for p in (PRODUCT / "JointForge/Modules").glob("*.luau")})
    assert len(expected) == 9
    historical = {str(p.relative_to(PRODUCT)): digest(p) for p in (PRODUCT / "dist").glob("*") if p.is_file()}
    preserved = {}
    for name in ("Graph", "Planner", "Schema", "Transaction", "ForgeMark", "StudioUI"):
        path = expected[name]
        baseline = subprocess.run(["git", "show", BASELINE + ":" + str(path.relative_to(REPO))], cwd=REPO, check=True, capture_output=True).stdout
        assert baseline == path.read_bytes(), "Engine/brand baseline changed: " + name
        preserved[name] = digest(path)
    compile_files = list(expected.values()) + [HERE / "Runner.plugin.luau", HERE / "Issues.spec.luau", PRODUCT / "tests/V11.spec.luau"]
    result = subprocess.run([args.compiler, "--null", *map(str, compile_files)], capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr

    def build(project, output):
        subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True, capture_output=True)

    artifact = HERE / "JointForge-ForgeStudio-0.2.5.rbxm"
    with tempfile.TemporaryDirectory(prefix="jointforge025-") as directory:
        temp = Path(directory)
        project = temp / "import.project.json"

        def import_xml(path, filename):
            project.write_text(json.dumps({"name": "JointForge", "tree": {"$path": str(path)}}))
            xml = temp / filename
            build(project, xml)
            return ET.parse(xml)

        build(PRODUCT / "release.project.json", artifact)
        second = temp / "second.rbxm"
        build(PRODUCT / "release.project.json", second)
        assert artifact.read_bytes() == second.read_bytes(), "Non-reproducible build"
        commercial = import_xml(artifact, "commercial.rbxmx").getroot().find("Item")
        assert sources(commercial) == {key: value.read_text() for key, value in expected.items()}
        assert len(list(commercial.iter("Item"))) == 11
        for item in commercial.iter("Item"):
            assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
        assert named(commercial, "Main").findtext("Properties/bool[@name='Disabled']") != "true"
        for source in sources(commercial).values():
            for token in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "JointForge025Gate", "JointForgeV11", "AnalyticsService", "/Users/"):
                assert token not in source, token

        fixture_path = HERE / "JointForge-Issues.rbxmx"
        build_fixture().write(fixture_path, encoding="utf-8", xml_declaration=True)
        imported_fixture = import_xml(fixture_path, "fixture.rbxmx").getroot().find("Item")
        fixture_joints = [item for item in imported_fixture.iter("Item") if item.get("class") in {
            "WeldConstraint", "Weld", "RopeConstraint", "HingeConstraint", "RigidConstraint"}]
        assert len(fixture_joints) == 12
        assert all(item.get("class") not in {"Script", "LocalScript", "ModuleScript"} for item in imported_fixture.iter("Item"))
        refs = {item.get("referent") for item in imported_fixture.iter("Item")}
        for item in fixture_joints:
            for ref in item.findall("Properties/Ref"):
                assert ref.text == "null" or ref.text in refs

        legacy = PRODUCT / "dist/JointForge-v1.0.0.rbxm"
        qa_project = temp / "qa.project.json"
        qa_project.write_text(json.dumps({"name": "JointForge025QA", "tree": {
            "$className": "Model", "$attributes": {"CandidateSHA256": digest(artifact), "LegacySHA256": digest(legacy)},
            "Candidate": {"$path": str(artifact)}, "Legacy": {"$path": str(legacy)},
            "Fixture": {"$path": str(fixture_path)}, "Runner": {"$path": str(HERE / "Runner.plugin.luau")},
            "Tests": {"$className": "Folder", "Issues": {"$path": str(HERE / "Issues.spec.luau")}, "V11": {"$path": str(PRODUCT / "tests/V11.spec.luau")}}
        }}))
        qa_xml = temp / "qa.rbxmx"
        build(qa_project, qa_xml)
        qa_doc = ET.parse(qa_xml)
        qa_root = qa_doc.getroot().find("Item")
        imported_sources = {}
        for key in ("Candidate", "Legacy"):
            imported = named(qa_root, key)
            imported_sources[key] = sources(imported)
            properties = named(imported, "Main").find("Properties")
            disabled = properties.find("bool[@name='Disabled']")
            if disabled is None:
                disabled = ET.SubElement(properties, "bool", name="Disabled")
            disabled.text = "true"
        qa_doc.write(qa_xml, encoding="utf-8", xml_declaration=True)
        qa_project.write_text(json.dumps({"name": "JointForge025QA", "tree": {"$path": str(qa_xml)}}))
        qa_artifact = HERE / "JointForge025QA.rbxm"
        build(qa_project, qa_artifact)
        verified_qa = import_xml(qa_artifact, "qa-verified.rbxmx").getroot().find("Item")
        assert sources(named(verified_qa, "Candidate")) == sources(commercial)
        for key in imported_sources:
            assert sources(named(verified_qa, key)) == imported_sources[key]
        enabled = [item for item in verified_qa.iter("Item") if item.get("class") == "Script" and item.findtext("Properties/bool[@name='Disabled']") != "true"]
        assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"

        for filename, world in (
            ("JointForge025QA.rbxl", {"$className": "Workspace", "$attributes": {"JointForge025Gate": True}}),
            ("JointForge025-Demo.rbxl", {"$className": "Workspace", "JointForgeIssueAssembly": {"$path": str(fixture_path)}}),
        ):
            project.write_text(json.dumps({"name": "JointForge025", "tree": {"$className": "DataModel", "Workspace": world}}))
            build(project, HERE / filename)

    assert historical == {str(p.relative_to(PRODUCT)): digest(p) for p in (PRODUCT / "dist").glob("*") if p.is_file()}, "Historical dist changed"
    manifest = {
        "product": "JointForge", "productVersion": "1.1.0", "catalogueRelease": "Forge Studio 0.2.5",
        "baselineCommit": BASELINE, "canonicalAssetId": "103958912217728", "artifact": artifact.name, "sha256": digest(artifact),
        "sourceVerification": {"status": "PASS", "sourceCount": len(expected), "reproducibleBuild": True, "importedSourcesEqual": True,
            "sourceSha256": {str(path.relative_to(PRODUCT)): digest(path) for path in expected.values()}, "preservedBaselineSources": preserved},
        "historicalArtifacts": historical,
        "qa": {"artifact": qa_artifact.name, "sha256": digest(qa_artifact), "place": "JointForge025QA.rbxl",
            "demo": "JointForge025-Demo.rbxl", "fixture": fixture_path.name, "fixtureSha256": digest(fixture_path),
            "mode": "Local Edit mode, guarded empty Workspace", "workspaceAttribute": "JointForge025Gate",
            "outputPrefix": "[JointForge025]", "technicalMatrixRows": 56, "additionalIssueScenarios": 10,
            "installedGuiProof": False},
        "gates": {"luauCompilation": "PASS", "exactSourceArtifact": "PASS", "historicalPreservation": "PASS", "fixturePackaging": "PASS",
            "nativeRegression": "NON TESTED", "nativeIssueWorkflow": "NON TESTED", "nativeResponsiveness": "NON TESTED",
            "actualInstalledGui": "NON TESTED", "nativeScreenshots": "NON TESTED", "lightDarkSanity": "NON TESTED"},
        "publication": "NOT PERFORMED",
    }
    (HERE / "candidate.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"artifact": str(artifact), "sha256": digest(artifact), "productionSources": len(expected), "compiledSources": len(compile_files),
        "qaArtifact": str(qa_artifact), "nativeStatus": "NON TESTED"}, indent=2))


if __name__ == "__main__":
    main()
