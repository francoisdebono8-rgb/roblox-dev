"""Extract only QA result lines, without Studio paths, account IDs or telemetry."""
from pathlib import Path
import argparse
import re

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("log", type=Path)
parser.add_argument("--since", required=True, help="ISO UTC timestamp prefix for the intended run")
parser.add_argument("--gui", action="store_true", help="Collect real GUI workflow assertions separately")
args = parser.parse_args()
tags = "ForgeGUI" if args.gui else "ForgeCatalogGate|JointForgeTests|CurveForgeTests"
pattern = re.compile(r"^(\S+?),.*?\[FLog::CreatorOutput\] (\[(?:" + tags + r")\].*)$")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if match and match[1] >= args.since:
        lines.append(f"{match[1]} {match[2]}")
assert lines and (args.gui or any("[ForgeCatalogGate] Finished" in line for line in lines)), "Incomplete run"
target = ROOT / ("docs/forge-catalog-gui-run.txt" if args.gui else "docs/forge-catalog-native-run.txt")
context = "actual GUI actions with Command Bar assertions; partial coverage, see release status" if args.gui else "final binary modules via isolated QA plugin"
target.write_text(f"Studio 0.740.19.7400931, edit mode; {context}.\n" + "\n".join(lines) + "\n")
print(f"Saved {len(lines)} actual result lines to {target.name}")
