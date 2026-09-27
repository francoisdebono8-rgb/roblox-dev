"""Retain only product-prefixed native results; never commit whole Studio logs."""
import argparse
import hashlib
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
digest = hashlib.sha256((ROOT / "dist/CurveForge-v1.1.0.rbxm").read_bytes()).hexdigest()
pattern = re.compile(r"^(\d{4}-\d{2}-\d{2}T[^,]+),.*\[FLog::Creator(?:Output|Warning)\] (?:Warning: )?(\[CurveForge(?:TechnicalGate|V11|Tests)\].*)$")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if match:
        lines.append(f"{match[1]} {match[2]}")
text = "\n".join(lines)
assert f"artifact=CurveForge-v1.1.0.rbxm sha256={digest}" in text, "Wrong or missing exact-binary native run"
assert "[CurveForgeTechnicalGate][SUMMARY] PASS" in text and "9 passed / 0 failed" in text
assert "[FAIL]" not in text and "[SUMMARY] FAIL" not in text
assert not any(marker in text for marker in ("/Users/", "token=", "cookie", "Authorization"))
version = args.log.name.split("_", 1)[0]
assert re.fullmatch(r"\d+(?:\.\d+)+", version), "Expected versioned native Studio log filename"
args.output.write_text(f"Native Roblox Studio {version}, Edit mode; isolated exact-artifact QA.\n" + text + "\n")
print(f"PASS: {len(lines)} sanitized result lines; candidate {digest}")
