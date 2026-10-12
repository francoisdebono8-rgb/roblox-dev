"""Package an opt-in QA plugin and empty place from the exact final release binary."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
PRODUCT = HERE.parent
ARTIFACT = PRODUCT / "dist" / "SchemaForge-v1.1.0.rbxm"
GATE = "SchemaForgeFinalGate"
SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
TESTS = {"Suite": "Suite.luau", "V11Engine.spec": "V11Engine.spec.luau", "Layout.spec": "Layout.spec.luau"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def name(item):
    return item.findtext("Properties/string[@name='Name']")


def child(item, target):
    found = [node for node in item.findall("Item") if name(node) == target]
    require(len(found) == 1, f"Expected exactly one {target}")
    return found[0]


def sources(root):
    result = {}

    def visit(item, path):
        path = (*path, name(item))
        if item.get("class") in SCRIPT_CLASSES:
            require(path not in result, f"Duplicate script path: {'/'.join(path)}")
            result[path] = (item.get("class"), item.findtext("Properties/*[@name='Source']") or "")
        for node in item.findall("Item"):
            visit(node, path)

    visit(root, ())
    return result


def production_sources():
    expected = {("SchemaForge", "Main"): ("Script", (PRODUCT / "SchemaForge/Main.plugin.luau").read_text(encoding="utf-8"))}
    for source in sorted((PRODUCT / "SchemaForge/Modules").glob("*.luau")):
        expected[("SchemaForge", "Modules", source.stem)] = ("ModuleScript", source.read_text(encoding="utf-8"))
    require(len(expected) == 5, "Expected the five canonical production sources")
    return expected


def audit_commercial(root, expected, disabled=False):
    require(root is not None and root.get("class") == "Model" and name(root) == "SchemaForge", "Unexpected release root")
    require(sorted(name(node) for node in root.findall("Item")) == ["Main", "Modules"], "Unexpected nodes in commercial root")
    main, modules = child(root, "Main"), child(root, "Modules")
    require(main.get("class") == "Script" and modules.get("class") == "Folder", "Unexpected commercial Script/Modules classes")
    require((main.findtext("Properties/bool[@name='Disabled']") == "true") == disabled,
            "Commercial Main must be enabled in dist and disabled only in the QA harness")
    actual = sources(root)
    changed = sorted("/".join(path) for path in actual.keys() | expected.keys() if actual.get(path) != expected.get(path))
    require(not changed, "Final artifact/source mismatch; rebuild the release first: " + ", ".join(changed))
    require(len(list(root.iter("Item"))) == len(expected) + 2, "Unexpected non-code nodes in commercial artifact")
    for _, source in actual.values():
        require(not any(marker in source for marker in (GATE, "SchemaForgeV11Engine", "SchemaForgeLayout", "SchemaForgeTests")),
                "QA code leaked into commercial Source")


def validate_output(path, extension):
    require(path.suffix == extension, f"QA output must have {extension} extension")
    require(not path.is_relative_to((PRODUCT / "dist").resolve()), "QA output must remain outside commercial dist/")
    require("Gate" in path.stem or "QA" in path.stem, "Use a QA/Gate output name")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo")
    parser.add_argument("--output", type=Path, default=Path(tempfile.gettempdir()) / f"{GATE}-v1.1.0.rbxm")
    parser.add_argument("--place-output", type=Path, default=Path(tempfile.gettempdir()) / f"{GATE}-Empty-v1.1.0.rbxl")
    parser.add_argument("--restart-check", action="store_true", help="Package the read-only saved-greenhouse restart check instead of the empty-place suites")
    args = parser.parse_args()
    output, place_output = args.output.resolve(), args.place_output.resolve()
    validate_output(output, ".rbxm")
    validate_output(place_output, ".rbxl")
    require(ARTIFACT.is_file(), f"Missing final artifact: {ARTIFACT}. No source/older-binary fallback is allowed.")
    digest = hashlib.sha256(ARTIFACT.read_bytes()).hexdigest()
    expected = production_sources()
    runner = "RestartAcceptance.plugin.luau" if args.restart_check else "FinalGate.plugin.luau"
    qa_sources = {(GATE, "Runner"): ("Script", (HERE / runner).read_text(encoding="utf-8"))}
    qa_sources.update({(GATE, "Tests", key): ("ModuleScript", (HERE / filename).read_text(encoding="utf-8")) for key, filename in TESTS.items()})

    def build(project, destination):
        subprocess.run([args.rojo, "build", str(project), "-o", str(destination)], check=True)

    def import_binary(binary, directory, stem, model_name):
        project = directory / f"{stem}.project.json"
        project.write_text(json.dumps({"name": model_name, "tree": {"$path": str(binary)}}), encoding="utf-8")
        xml = directory / f"{stem}.rbxmx"
        build(project, xml)
        items = ET.parse(xml).getroot().findall("Item")
        require(len(items) == 1, f"Expected one root in {binary.name}")
        return items[0]

    with tempfile.TemporaryDirectory(prefix="schemaforge-final-gate-") as temporary:
        directory = Path(temporary)
        release_root = import_binary(ARTIFACT, directory, "commercial", "SchemaForge")
        audit_commercial(release_root, expected)
        qa_xml = directory / "gate.rbxmx"
        build(HERE / "final-gate.project.json", qa_xml)
        qa_doc = ET.parse(qa_xml)
        qa_root = qa_doc.getroot().find("Item")
        child(qa_root, "Runner").find("Properties/*[@name='Source']").text = qa_sources[(GATE, "Runner")][1]
        commercial_copy = child(qa_root, "SchemaForge")
        audit_commercial(commercial_copy, expected)
        main_properties = child(commercial_copy, "Main").find("Properties")
        disabled = main_properties.find("bool[@name='Disabled']")
        if disabled is None:
            disabled = ET.SubElement(main_properties, "bool", name="Disabled")
        disabled.text = "true"
        qa_doc.write(qa_xml, encoding="utf-8", xml_declaration=True)

        project = directory / "verified-gate.project.json"
        project.write_text(json.dumps({"name": GATE, "tree": {
            "$path": str(qa_xml), "$attributes": {"CommercialSHA256": digest, "CommercialArtifact": ARTIFACT.name}
        }}), encoding="utf-8")
        staged = directory / output.name
        build(project, staged)
        verified = import_binary(staged, directory, "verified", GATE)
        audit_commercial(child(verified, "SchemaForge"), expected, disabled=True)
        require(sorted(name(node) for node in verified.findall("Item")) == ["Runner", "SchemaForge", "Tests"], "Unexpected QA root children")
        wanted = dict(qa_sources)
        wanted.update({(GATE, *path): value for path, value in expected.items()})
        require(sources(verified) == wanted, "Bundling changed production or QA Source")
        enabled = [node for node in verified.iter("Item") if node.get("class") in {"Script", "LocalScript"}
                   and node.findtext("Properties/bool[@name='Disabled']") != "true"]
        require(len(enabled) == 1 and name(enabled[0]) == "Runner", "Only the opt-in QA Runner may execute")

        place_project = directory / "empty-qa.project.json"
        place_project.write_text(json.dumps({"name": f"{GATE}-Empty", "tree": {
            "$className": "DataModel", "Workspace": {"$className": "Workspace", "$attributes": {GATE: True}}
        }}), encoding="utf-8")
        staged_place = directory / place_output.name
        if args.restart_check:
            staged_place.write_bytes((PRODUCT / "release/SchemaForge-Media.rbxl").read_bytes())
        else:
            build(place_project, staged_place)
        require(production_sources() == expected, "Production sources changed during QA build; retry after the final release rebuild")
        require(hashlib.sha256(ARTIFACT.read_bytes()).hexdigest() == digest, "Commercial artifact changed during QA build; retry")
        output.parent.mkdir(parents=True, exist_ok=True)
        place_output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(staged.read_bytes())
        place_output.write_bytes(staged_place.read_bytes())

    print(f"QA plugin: {output}")
    print(f"{'Licensed greenhouse restart copy' if args.restart_check else 'Empty opt-in QA place'}: {place_output}")
    print(f"Commercial artifact: {ARTIFACT.name}; SHA256 {digest}")
    print("PASS: exact commercial/QA Sources verified; only Runner enabled; commercial dist unchanged.")
    print("Install the QA plugin locally, then open the generated separate QA place in Studio Edit mode.")
    if args.restart_check:
        print("Read-only restart check: only an unpublished place with PlantGreenhouse is inspected; no save or repair is performed.")
    else:
        print(f'Other places are ignored unless workspace:GetAttribute("{GATE}") == true; nonempty/published places are refused.')
    print("Packaging only: native suites, layout, themes and Undo/Redo have NOT been executed by this builder.")


if __name__ == "__main__":
    main()
