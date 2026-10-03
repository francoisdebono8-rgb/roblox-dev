"""Extract scoped 0.2.5 QA logs without copying account/device log metadata."""

import argparse
import hashlib
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
parser.add_argument("--product", required=True,
                    choices=("SchemaForge", "PresetForge", "CurveForge", "AccessForge", "JointForge"))
parser.add_argument("--artifact", required=True, type=Path)
parser.add_argument("--since", required=True, help="ISO UTC timestamp lower bound")
parser.add_argument("--output", required=True, type=Path)
args = parser.parse_args()
sha = hashlib.sha256(args.artifact.read_bytes()).hexdigest()
pattern = re.compile(r"^(\S+?),.*?\[FLog::Creator(?:Output|Error)\] (.*)$")
tag = re.compile(r"\[" + re.escape(args.product) + r"[^\]]*\]")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if not match or match[1] < args.since:
        continue
    start = tag.search(match[2])
    if not start:
        continue
    message = match[2][start.start():]
    message = re.sub(r"(?:/Users/|/private/|/var/folders/)[^\s\"']+", "<local-path>", message)
    lines.append(f"{match[1]} {message}")
assert lines, "No matching executed QA evidence"
assert any(sha in line for line in lines), "Log does not identify the exact candidate SHA"
assert not args.output.exists(), "Choose a new evidence filename; preserve previous runs"
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(
    f"{args.product} / Forge Studio 0.2.5\nArtifact SHA256: {sha}\n"
    "Native QA package importing the exact binary; not installed-GUI proof.\n"
    "Read individual results and final summary. Missing checks are not PASS.\n\n"
    + "\n".join(lines) + "\n")
print(f"Saved {len(lines)} scoped native lines to {args.output}")
