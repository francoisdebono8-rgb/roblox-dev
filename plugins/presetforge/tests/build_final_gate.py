"""Package tests with the exact final binary; never rebuild or change the release."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
PRODUCT = HERE.parent
ARTIFACT = PRODUCT / "dist" / "PresetForge-v2.1.0.rbxm"
SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}


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
            result[path] = (item.get("class"), item.findtext("Properties/*[@name='Source']") or "")
        for node in item.findall("Item"):
            visit(node, path)

    visit(root, ())
    return result


def audit_commercial(root):
    require(root.get("class") == "Model" and name(root) == "PresetForge", "Unexpected release root")
    require(sorted(name(node) for node in root.findall("Item")) == ["Main", "Modules"], "QA or unexpected nodes in commercial root")
    main, modules = child(root, "Main"), child(root, "Modules")
    require(main.get("class") == "Script", "Main must be the commercial Script")
    require(modules.get("class") == "Folder", "Modules must be a Folder")
    require(main.findtext("Properties/bool[@name='Disabled']") != "true", "Commercial Main is disabled")
    expected = {("PresetForge", "Main"): ("Script", (PRODUCT / "PresetForge/Main.plugin.luau").read_text())}
    for source in sorted((PRODUCT / "PresetForge/Modules").glob("*.luau")):
        expected[("PresetForge", "Modules", source.stem)] = ("ModuleScript", source.read_text())
    actual = sources(root)
    changed = sorted("/".join(path) for path in actual.keys() | expected.keys() if actual.get(path) != expected.get(path))
    require(not changed, "Final binary sources differ; rebuild the release first: " + ", ".join(changed))
    require(len(list(root.iter("Item"))) == len(expected) + 2, "Unexpected non-code nodes in commercial artifact")
    for _, code in expected.values():
        require("PresetForgeReleaseGate" not in code and "GateTestSupport" not in code, "QA code leaked into production")
    return main


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default="rojo")
    parser.add_argument("--output", type=Path, default=Path(tempfile.gettempdir()) / "PresetForgeReleaseGate-v2.1.0.rbxm")
    args = parser.parse_args()
    output = args.output.resolve()
    require(ARTIFACT.is_file(), f"Missing final artifact: {ARTIFACT}. No source/older-binary fallback is allowed.")
    require(output.suffix == ".rbxm", "QA output must have .rbxm extension")
    require(not output.is_relative_to((PRODUCT / "dist").resolve()), "QA output must remain outside commercial dist/")
    require("Gate" in output.stem or "QA" in output.stem, "Use a QA/Gate output name to distinguish it from the commercial release")
    digest = hashlib.sha256(ARTIFACT.read_bytes()).hexdigest()

    def build(project, destination):
        subprocess.run([args.rojo, "build", str(project), "-o", str(destination)], check=True)

    def import_binary(binary, directory, stem, model_name):
        project = directory / f"{stem}.project.json"
        project.write_text(json.dumps({"name": model_name, "tree": {"$path": str(binary)}}))
        xml = directory / f"{stem}.rbxmx"
        build(project, xml)
        return ET.parse(xml)

    with tempfile.TemporaryDirectory(prefix="presetforge-final-gate-") as temporary:
        directory = Path(temporary)
        release_doc = import_binary(ARTIFACT, directory, "commercial", "PresetForge")
        release_root = release_doc.getroot().find("Item")
        require(release_root is not None, "Empty commercial binary")
        audit_commercial(release_root)
        original_sources = sources(release_root)

        qa_xml = directory / "gate.rbxmx"
        build(HERE / "final-gate.project.json", qa_xml)
        qa_doc = ET.parse(qa_xml)
        qa_root = qa_doc.getroot().find("Item")
        commercial_copy = child(qa_root, "PresetForge")
        commercial_main = audit_commercial(commercial_copy)
        require(sources(commercial_copy) == original_sources, "QA imported different commercial code")
        disabled = commercial_main.find("Properties/bool[@name='Disabled']")
        if disabled is None:
            disabled = ET.SubElement(commercial_main.find("Properties"), "bool", name="Disabled")
        disabled.text = "true"
        qa_doc.write(qa_xml, encoding="utf-8", xml_declaration=True)

        project = directory / "disabled-gate.project.json"
        project.write_text(json.dumps({"name": "PresetForgeReleaseGate", "tree": {
            "$path": str(qa_xml), "$attributes": {"CommercialSHA256": digest, "CommercialArtifact": ARTIFACT.name}
        }}))
        staged = directory / output.name
        build(project, staged)
        verified = import_binary(staged, directory, "verified", "PresetForgeReleaseGate").getroot().find("Item")
        copy = child(verified, "PresetForge")
        require(sources(copy) == original_sources, "Bundling changed commercial script/module Source")
        require(child(copy, "Main").findtext("Properties/bool[@name='Disabled']") == "true", "QA Main must stay disabled")
        enabled = [node for node in verified.iter("Item") if node.get("class") in {"Script", "LocalScript"}
                   and node.findtext("Properties/bool[@name='Disabled']") != "true"]
        require(len(enabled) == 1 and name(enabled[0]) == "Runner", "Only the opt-in QA Runner may execute")
        require(hashlib.sha256(ARTIFACT.read_bytes()).hexdigest() == digest, "Commercial artifact changed during QA build; retry")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(staged.read_bytes())

    print(f"QA bundle: {output}")
    print(f"Commercial artifact: {ARTIFACT.name}; SHA256 {digest}")
    print("PASS: commercial sources match, QA absent from release, embedded Main disabled with exact Source preserved.")
    print('Native opt-in: workspace:SetAttribute("PresetForgeReleaseGate", true) before loading the QA plugin.')


if __name__ == "__main__":
    main()
