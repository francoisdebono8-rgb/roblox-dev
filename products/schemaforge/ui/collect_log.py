"""Retain only product-prefixed QA output, never unrelated Studio/account logs."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
prefixes = ("[SchemaForgeUI]", "[SchemaForgeV12]", "[SchemaForgeTechnicalGate]")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    for prefix in prefixes:
        if prefix in line:
            lines.append(line[line.index(prefix):])
            break
assert lines, "No product evidence found"
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text("\n".join(lines) + "\n")
print(f"Retained {len(lines)} product lines in {args.output}")
