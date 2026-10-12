"""Build and verify isolated Forge Studio 0.2.5 artifacts; never installs or opens Studio."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--compiler", default="luau-compile")
parser.add_argument("--luau", default="luau")
args = parser.parse_args()
artifact = HERE / "SchemaForge-ForgeStudio-0.2.5.rbxm"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_protected():
    protected = json.loads((HERE / "baseline.json").read_text())["protectedFiles"]
    for path, expected in protected.items():
        assert digest(ROOT / path) == expected, f"Protected historical/engine file changed: {path}"


def build(project, output):
    subprocess.run([args.rojo, "build", str(project), "-o", str(output)], check=True, stdout=subprocess.DEVNULL)


def sources(model):
    result = {}
    for item in model.iter("Item"):
        if item.get("class") in {"Script", "ModuleScript"}:
            name = item.findtext("Properties/string[@name='Name']")
            assert name not in result
            result[name] = item.findtext("Properties/*[@name='Source']") or ""
    return result


def named(model, name):
    return next(item for item in model.findall("Item") if item.findtext("Properties/string[@name='Name']") == name)


check_protected()
files = {"Main": ROOT / "SchemaForge/Main.plugin.luau"}
files.update({p.stem: p for p in sorted((ROOT / "SchemaForge/Modules").glob("*.luau"))})
assert set(files) == {"Main", "Schema", "Engine", "Store", "View", "AuditSummary"}
expected = {name: path.read_text() for name, path in files.items()}
qa_sources = sorted(HERE.glob("*.luau")) + [ROOT / "tests/V12.spec.luau"]
compiled = subprocess.run([args.compiler, "--null", *map(str, [*files.values(), *qa_sources])], check=True, text=True, capture_output=True)
offline = subprocess.run([args.luau, str(HERE / "offline.luau")], check=True, text=True, capture_output=True)
assert "[SUMMARY] 6 PASS / 0 FAIL" in offline.stdout
build(ROOT / "release.project.json", artifact)
with tempfile.TemporaryDirectory(prefix="schemaforge025-") as tmp:
    temp = Path(tmp)
    project, xml = temp / "import.project.json", temp / "import.rbxmx"
    duplicate = temp / "duplicate.rbxm"
    build(ROOT / "release.project.json", duplicate)
    assert artifact.read_bytes() == duplicate.read_bytes(), "Non-reproducible candidate"
    project.write_text(json.dumps({"name": "Candidate", "tree": {"$path": str(artifact)}}))
    build(project, xml)
    model = ET.parse(xml).getroot().find("Item")
    assert model.get("class") == "Model" and len(list(model.iter("Item"))) == 8
    assert sources(model) == expected, "Embedded production source differs"
    assert named(model, "Main").findtext("Properties/bool[@name='Disabled']") != "true"
    for item in model.iter("Item"):
        assert item.get("class") in {"Model", "Folder", "Script", "ModuleScript"}
    for source in expected.values():
        for forbidden in ("GetAsync", "PostAsync", "RequestAsync", "loadstring", "/Users/", "SchemaForge025Mode", "AnalyticsService"):
            assert forbidden not in source, f"Unexpected production payload: {forbidden}"
    sha = digest(artifact)
    legacy = ROOT / "dist/SchemaForge-v1.1.0.rbxm"
    project.write_text(json.dumps({"name": "SchemaForge025QA", "tree": {
        "$className": "Model", "$attributes": {"CandidateSHA256": sha, "LegacySHA256": digest(legacy)},
        "Candidate": {"$path": str(artifact)}, "Legacy": {"$path": str(legacy)},
        "Runner": {"$path": str(HERE / "Runner.plugin.luau")},
        "Fixture": {"$path": str(HERE / "Fixture.luau")},
        "V12": {"$path": str(ROOT / "tests/V12.spec.luau")},
        "SummaryTests": {"$path": str(HERE / "AuditSummary.spec.luau")},
        "HeroTests": {"$path": str(HERE / "Hero.spec.luau")},
    }}))
    build(project, xml)
    doc = ET.parse(xml); model = doc.getroot().find("Item")
    originals = {}
    for key in ("Candidate", "Legacy"):
        imported = named(model, key); originals[key] = sources(imported)
        props = named(imported, "Main").find("Properties")
        disabled = props.find("bool[@name='Disabled']")
        if disabled is None:
            disabled = ET.SubElement(props, "bool", name="Disabled")
        disabled.text = "true"
    assert originals["Candidate"] == expected
    doc.write(xml, encoding="utf-8", xml_declaration=True)
    project.write_text(json.dumps({"name": "SchemaForge025QA", "tree": {"$path": str(xml)}}))
    qa = HERE / "SchemaForge025QA.rbxm"; build(project, qa)
    project.write_text(json.dumps({"name": "SchemaForge025QA", "tree": {"$path": str(qa)}}))
    build(project, xml)
    model = ET.parse(xml).getroot().find("Item")
    for key in originals:
        assert sources(named(model, key)) == originals[key]
    enabled = [item for item in model.iter("Item") if item.get("class") == "Script" and item.findtext("Properties/bool[@name='Disabled']") != "true"]
    assert len(enabled) == 1 and enabled[0].findtext("Properties/string[@name='Name']") == "Runner"
    for mode in ("technical", "fixture"):
        project.write_text(json.dumps({"name": "SchemaForge025" + mode.title(), "tree": {
            "$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": {"SchemaForge025Mode": mode}},
        }}))
        build(project, HERE / ("SchemaForge025" + mode.title() + ".rbxl"))
check_protected()
source_manifest = {name: {"path": str(path.relative_to(ROOT)), "sha256": digest(path)} for name, path in files.items()}
manifest = {
    "product": "SchemaForge", "productVersion": "1.2.0", "catalogueRelease": "Forge Studio 0.2.5",
    "artifact": artifact.name, "sha256": digest(artifact), "bytes": artifact.stat().st_size,
    "status": "READY FOR NATIVE; NOT FROZEN", "canonicalAssetId": "84085408748744",
    "sourceVerification": {"status": "PASS", "reproducibleBytes": True, "exactEmbeddedSources": True, "commercialMainEnabled": True, "sources": source_manifest},
    "gates": {"compilation": "PASS", "offlineSummaryCases": "6 PASS / 0 FAIL", "historicalAndEnginePreservation": "PASS",
              "qaImportExactSources": "PASS", "nativeFullRegression": "NON TESTED", "nativeSafeRepairStaleUndoRedo": "NON TESTED",
              "installedMainGui": "NON TESTED", "dark560": "NON TESTED", "dark320": "NON TESTED", "lightSanity": "NON TESTED",
              "width240400AndShort": "NON TESTED", "finalVisualReview": "NON TESTED"},
    "qa": {"artifact": qa.name, "sha256": digest(qa), "mode": "local Edit mode", "nativeCases": 63, "technicalMatrixRows": 41,
           "places": ["SchemaForge025Technical.rbxl", "SchemaForge025Fixture.rbxl"], "prefix": "[SchemaForge025]",
           "sources": {str(p.relative_to(ROOT)): digest(p) for p in qa_sources}},
    "publication": "NOT PERFORMED",
}
(HERE / "candidate.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
(HERE / "offline-verification.txt").write_text(compiled.stdout + compiled.stderr + offline.stdout +
    "PASS: exact-source candidate, deterministic bytes, isolated QA imports, protected historical files and engine hashes.\n" +
    "NON TESTED: Studio native execution and actual installed GUI.\n")
print(json.dumps({"artifact": artifact.name, "sha256": manifest["sha256"], "qa": qa.name, "status": manifest["status"]}, indent=2))
print(offline.stdout, end="")
