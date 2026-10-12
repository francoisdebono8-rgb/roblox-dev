"""Build the playable place; --qa emits a separate, never-publish native harness."""
import argparse
import hashlib
import json
import pathlib
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = ROOT.parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--rojo", default="rojo")
parser.add_argument("--compiler", help="Optional luau-compile executable")
parser.add_argument("--qa", action="store_true")
args = parser.parse_args()

project = json.loads((ROOT / "default.project.json").read_text())
sources = []


def resolve(node):
    if "$path" in node:
        path = (ROOT / node["$path"]).resolve()
        sources.append(path)
        node["$path"] = str(path)
    for value in node.values():
        if isinstance(value, dict):
            resolve(value)


resolve(project["tree"])
if args.qa:
    suite = ROOT / "tests/Runtime.server.luau"
    project["tree"]["ServerScriptService"]["RuntimeQA"] = {"$path": str(suite)}
    sources.append(suite)
if args.compiler:
    for source in sources:
        subprocess.run([args.compiler, str(source)], check=True, stdout=subprocess.DEVNULL)

output_dir = pathlib.Path(tempfile.gettempdir()) / "ForgePlaygroundQA" if args.qa else ROOT / "dist"
output_dir.mkdir(parents=True, exist_ok=True)
output = output_dir / ("Forge-Playground-QA.rbxl" if args.qa else "Forge-Playground-v0.1.0.rbxl")
with tempfile.TemporaryDirectory(prefix="forge-playground-build-") as directory:
    resolved = pathlib.Path(directory) / "build.project.json"
    resolved.write_text(json.dumps(project))
    subprocess.run([args.rojo, "build", str(resolved), "-o", str(output)], check=True)
    xml = pathlib.Path(directory) / "inspection.rbxlx"
    subprocess.run([args.rojo, "build", str(resolved), "-o", str(xml)], check=True, stdout=subprocess.DEVNULL)
    tree = ET.parse(xml)
    embedded = []
    script_names = []
    for item in tree.iter("Item"):
        if item.get("class") in {"Script", "LocalScript", "ModuleScript"}:
            properties = item.find("Properties")
            source = properties.find("*[@name='Source']")
            name = properties.find("string[@name='Name']")
            embedded.append(source.text or "")
            script_names.append(name.text)
    assert sorted(embedded) == sorted(p.read_text() for p in sources), "Embedded script/source mismatch"
    assert ("RuntimeQA" in script_names) == args.qa, "QA contamination or missing runner"
    assert "Main" not in script_names, "A plugin entry point was accidentally embedded"
    if args.qa:
        bundle = json.loads(json.dumps(project))
        bundle["tree"]["$className"] = "Model"
        for name, service in bundle["tree"].items():
            if isinstance(service, dict):
                service["$className"] = "Folder"
                service.pop("$properties", None)
        bundle["tree"]["StarterPlayer"]["StarterPlayerScripts"]["$className"] = "Folder"
        resolved.write_text(json.dumps(bundle))
        subprocess.run([args.rojo, "build", str(resolved), "-o", str(output_dir / "PlaygroundQAImport.rbxm")], check=True)

manifest = {
    "version": "0.1.0",
    "artifact": output.name,
    "qa_only": args.qa,
    "rojo": subprocess.check_output([args.rojo, "--version"], text=True).strip(),
    "project_sha256": hashlib.sha256((ROOT / "default.project.json").read_bytes()).hexdigest(),
    "embedded_source_check": "PASS",
    "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
    "sources": {str(p.relative_to(REPO)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(sources)},
}
(output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(output)
