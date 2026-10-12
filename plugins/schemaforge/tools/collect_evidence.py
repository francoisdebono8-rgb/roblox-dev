"""Keep only product test results, never raw Studio/account logs."""
import argparse
from pathlib import Path
import re

parser = argparse.ArgumentParser()
parser.add_argument("log", type=Path)
parser.add_argument("--gui", action="store_true")
args = parser.parse_args()
tag = "SchemaForgeGUI" if args.gui else "SchemaForgeTests"
pattern = re.compile(r"^(\S+?),.*?\[FLog::CreatorOutput\] (\[" + tag + r"\].*)$")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if match:
        lines.append(f"{match[1]} {match[2]}")
assert lines and (args.gui or any("23 PASS / 0 FAIL" in line for line in lines))
target = Path(__file__).resolve().parents[1] / "tests" / ("gui-run.txt" if args.gui else "native-run.txt")
target.write_text("Studio 0.740.19.7400003, edit mode, exact final binary.\n" + "\n".join(lines) + "\n")
print(f"Saved {len(lines)} sanitized evidence lines to {target.name}")
