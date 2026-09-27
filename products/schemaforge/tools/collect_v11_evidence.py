"""Extract product-only native gate evidence for the current commercial artifact."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--restart-check", action="store_true")
args = parser.parse_args()
product = Path(__file__).resolve().parents[1]
manifest = json.loads((product / "dist/manifest.json").read_text())
pattern = re.compile(r"^(\S+?),.*?\[FLog::Creator(?:Output|Warning|Error)\] (?:Warning: |Error: )?(\[SchemaForge(?:Tests|V11Engine|Layout|FinalGate|Restart)\].*)$")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if match:
        lines.append(f"{match[1]} {match[2]}")
text = "\n".join(lines)
assert f"sha256={manifest['sha256']}" in text, "Evidence is not for the current artifact"
expected = "[SchemaForgeRestart][PASS] Fresh Studio process" if args.restart_check else "[SchemaForgeFinalGate][SUMMARY] 3/3 suites PASS; gate PASS"
assert expected in text, "Incomplete/failed native gate"
assert "[FAIL]" not in text and "[SUITE FAIL]" not in text, "Failures require review; never silently omit them"
assert "/Users/" not in text and "Token=" not in text, "Private log data must not enter evidence"
args.output.write_text("Native Studio 0.740.19.7400003, Edit mode.\n" + text + "\n")
print(f"Saved {len(lines)} product-only evidence lines to {args.output.name}")
