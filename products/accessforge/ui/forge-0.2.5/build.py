"""Build exact-source AccessForge 0.2.5 candidate and a separate opt-in native gate."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
PRODUCT = HERE.parents[1]
REPO = PRODUCT.parents[1]
ARTIFACT = HERE / "AccessForge-ForgeStudio-0.2.5.rbxm"
HISTORICAL = {
    "dist/AccessForge-v1.0.0.rbxm": "53655a01ca0bb2e05886cdc401fa38003430f4f10f7317854a93c646d9dff44c",
    "dist/AccessForge-v1.1.0.rbxm": "484faabbfa9f8b02717a537aeee46c87e26861b83f8a66adadade112a5d89959",
    "ui/AccessForge-v1.1.0-ui27.rbxm": "8605ae5f948132bf9b309fe8b2b61b6a92023e0f0aca98eb2ba3f02185feedc1",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def named(item, name):
    return next(child for child in item.findall("Item") if child.findtext("Properties/string[@name='Name']") == name)


def sources(root):
    result = {}
    for item in root.iter("Item"):
        if item.get("class") in {"Script", "ModuleScript"}:
            name = item.findtext("Properties/string[@name='Name']")
            assert name not in result
            result[name] = item.findtext("Properties/*[@name='Source']") or ""
        else:
            assert item.get("class") in {"Model", "Folder"}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo")
    parser.add_argument("--luau-compile", default="luau-compile")
    args = parser.parse_args()

    def build(project, output):
        subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True, capture_output=True)

    expected_paths = {"Main": PRODUCT / "AccessForge/Main.plugin.luau"}
    expected_paths.update({p.stem: p for p in (PRODUCT / "AccessForge/Modules").glob("*.luau")})
    expected = {key: path.read_text() for key, path in expected_paths.items()}
    for path, sha in HISTORICAL.items():
        assert digest(PRODUCT / path) == sha, f"Historical artifact changed: {path}"
    for name in ("Engine", "Geometry", "Settings", "ForgeMark"):
        path = expected_paths[name].relative_to(REPO).as_posix()
        baseline = subprocess.run(["git", "show", f"bff0d9d:{path}"], cwd=REPO, check=True, capture_output=True).stdout
        assert baseline == expected_paths[name].read_bytes(), f"Engine/brand baseline changed: {name}"
    for source in expected.values():
        for forbidden in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "TechnicalGate", "AccessForgeV11", "AnalyticsService", "/Users/"):
            assert forbidden not in source, forbidden
    for path in [*expected_paths.values(), HERE / "NativeGate.plugin.luau", HERE / "Fixture.luau", HERE / "Preview.spec.luau", PRODUCT / "tests/V11.spec.luau"]:
        compiled = subprocess.run([args.luau_compile, str(path)], capture_output=True)
        assert compiled.returncode == 0, compiled.stderr.decode()

    with tempfile.TemporaryDirectory(prefix="accessforge-025-") as temp:
        directory = Path(temp)
        build(PRODUCT / "release.project.json", ARTIFACT)
        rebuilt = directory / "rebuilt.rbxm"
        build(PRODUCT / "release.project.json", rebuilt)
        assert rebuilt.read_bytes() == ARTIFACT.read_bytes(), "Non-reproducible candidate"
        project = directory / "import.project.json"
        xml = directory / "import.rbxmx"
        project.write_text(json.dumps({"name": "AccessForge", "tree": {"$path": str(ARTIFACT)}}))
        build(project, xml)
        production = ET.parse(xml).getroot().find("Item")
        assert sources(production) == expected
        assert len(list(production.iter("Item"))) == len(expected) + 2
        assert named(production, "Main").findtext("Properties/bool[@name='Disabled']") != "true"
        assert all(item.get("class") != "Script" or item == named(production, "Main") for item in production.iter("Item"))
        candidate_sha = digest(ARTIFACT)
        artifacts = {"Candidate": ARTIFACT, "Legacy": PRODUCT / "dist/AccessForge-v1.0.0.rbxm"}
        attrs = {key + "SHA256": digest(path) for key, path in artifacts.items()}
        attrs["ProductionSourceCount"] = len(expected)
        project.write_text(json.dumps({"name": "AccessForge025Gate", "tree": {
            "$className": "Model", "$attributes": attrs,
            "SourceMatchVerified": {"$className": "BoolValue", "$properties": {"Value": True}},
            **{key: {"$path": str(path)} for key, path in artifacts.items()},
            "Runner": {"$path": str(HERE / "NativeGate.plugin.luau")},
            "Tests": {"$className": "Folder",
                      "V11": {"$path": str(PRODUCT / "tests/V11.spec.luau")},
                      "Preview": {"$path": str(HERE / "Preview.spec.luau")},
                      "Fixture": {"$path": str(HERE / "Fixture.luau")}}
        }}))
        build(project, xml)
        doc = ET.parse(xml); root = doc.getroot().find("Item")
        original_sources = {}
        for key in artifacts:
            imported = named(root, key); original_sources[key] = sources(imported)
            if key == "Candidate":
                assert original_sources[key] == expected
            props = named(imported, "Main").find("Properties")
            disabled = props.find("bool[@name='Disabled']")
            if disabled is None:
                disabled = ET.SubElement(props, "bool", name="Disabled")
            disabled.text = "true"
        doc.write(xml, encoding="utf-8", xml_declaration=True)
        project.write_text(json.dumps({"name": "AccessForge025Gate", "tree": {"$path": str(xml)}}))
        runner = HERE / "AccessForge025Gate.rbxm"
        build(project, runner)
        project.write_text(json.dumps({"name": "AccessForge025Gate", "tree": {"$path": str(runner)}}))
        build(project, xml)
        checked = ET.parse(xml).getroot().find("Item")
        for key in artifacts:
            assert sources(named(checked, key)) == original_sources[key]
            assert named(named(checked, key), "Main").findtext("Properties/bool[@name='Disabled']") == "true"
        enabled = [item for item in checked.iter("Item") if item.get("class") == "Script" and item.findtext("Properties/bool[@name='Disabled']") != "true"]
        assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
        project.write_text(json.dumps({"name": "AccessForge025QA", "tree": {
            "$className": "DataModel",
            "Workspace": {"$className": "Workspace", "$attributes": {"AccessForge025Gate": True}},
            "Lighting": {"$className": "Lighting", "$properties": {"Technology": "ShadowMap"}}
        }}))
        place = HERE / "AccessForge025QA.rbxl"
        build(project, place)
    for path, sha in HISTORICAL.items():
        assert digest(PRODUCT / path) == sha
    manifest = {
        "product": "AccessForge", "productVersion": "1.1.0", "catalogueRelease": "Forge Studio 0.2.5",
        "artifact": ARTIFACT.name, "sha256": candidate_sha, "baselineCommit": "bff0d9d",
        "canonicalAssetId": "127360597946823", "publication": "NOT PERFORMED",
        "sourceVerification": {"status": "PASS", "method": "Two byte-identical Rojo builds; exact imported source equality; QA binary reimport equality", "sourceCount": len(expected)},
        "sources": {str(path.relative_to(REPO)): digest(path) for path in sorted(expected_paths.values())},
        "historicalArtifacts": HISTORICAL,
        "qa": {"runner": runner.name, "runnerSha256": digest(runner), "place": place.name, "placeSha256": digest(place),
               "prefix": "[AccessForge025Gate]", "mode": "Local Studio Edit, PlaceId 0", "existingCases": 55, "existingMatrixRows": 44, "contextCases": 10},
        "gates": {"compilation": "PASS", "reproducibleBuild": "PASS", "exactSourceImport": "PASS",
                  "engineAndBrandBaseline": "PASS", "historicalArtifactsPreserved": "PASS", "qaIsolation": "PASS",
                  "nativeFullRegression": "NOT RUN", "installedProductionGui": "NOT RUN", "nativeUndoRedo": "NOT RUN",
                  "dark320560": "NOT RUN", "lightSanity": "NOT RUN", "narrow240400": "NOT RUN", "visualAcceptance": "PENDING"}
    }
    (HERE / "candidate.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"artifact": str(ARTIFACT), "sha256": candidate_sha, "sources": len(expected), "qaRunner": str(runner), "native": "NOT RUN"}, indent=2))


if __name__ == "__main__":
    main()
