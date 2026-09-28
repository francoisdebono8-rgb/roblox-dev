"""Collect only the most recent exact-candidate native run, with all 56 matrix rows."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
parser.add_argument("--output", type=Path, default=ROOT / "tests/native-v11-technical.txt")
args = parser.parse_args()
digest = hashlib.sha256((ROOT / "dist/JointForge-v1.1.0.rbxm").read_bytes()).hexdigest()
pattern = re.compile(r"^(\d{4}-\d{2}-\d{2}T[^,]+),.*\[FLog::Creator(?:Output|Warning)\] (?:Warning: )?(\[JointForge(?:TechnicalGate|V11)\].*)$")
lines = []
for line in args.log.read_text(errors="replace").splitlines():
    match = pattern.match(line)
    if not match:
        continue
    if "[JointForgeTechnicalGate] artifact=" in match[2]:
        lines = []
    lines.append(f"{match[1]} {match[2]}")
text = "\n".join(lines)
assert f"artifact=JointForge-v1.1.0.rbxm sha256={digest}" in text, "Wrong or missing exact-binary run"
assert "legacy=JointForge-v1.0.0.rbxm sha256=24f43cf04c7d4e8cf92310b3c725f827e36b1ea22d9806e20325a4af4d2633bd" in text
assert "[JointForgeTechnicalGate][SUMMARY] PASS" in text
assert "[FAIL]" not in text and "[SUMMARY] FAIL" not in text and "NON TESTED" not in text
summary = re.search(r"\[JointForgeV11\]\[SUMMARY\] (\d+) PASS / 0 FAIL", text)
assert summary
assert len(re.findall(r"\[JointForgeV11\]\[PASS\]", text)) == int(summary[1])
matrix = {int(n): status for n, status in re.findall(r"\[JointForgeV11\]\[MATRIX\] (\d+) (PASS|FAIL|NON TESTED)", text)}
assert matrix == {n: "PASS" for n in range(1, 57)}, "Incomplete matrix"
caps = re.findall(r"\[JointForgeV11\]\[CAP\] ([a-z-]+) PASS", text)
assert set(caps) == {"scan", "nodes", "edges", "component", "batch", "operations", "remove", "request", "request-depth", "ancestry", "inspect-selection"}, "Missing individual limit evidence"
benchmark = re.search(r"\[JointForgeV11\]\[BENCHMARK\] (.+)", text)
assert benchmark
assert not any(marker in text for marker in ("/Users/", "token=", "cookie", "Authorization"))
version = args.log.name.split("_", 1)[0]
assert re.fullmatch(r"\d+(?:\.\d+)+", version), "Expected versioned Studio log filename"
args.output.write_text(f"Native Roblox Studio {version}, Edit mode; isolated exact-candidate QA.\n" + text + "\n")
result = {"candidate_sha256": digest, "studio_version": version, "native_pass": int(summary[1]), "native_fail": 0, "caps": caps,
          "matrix": matrix, "benchmark": dict(part.split("=", 1) for part in benchmark[1].split())}
(ROOT / "tests/technical-1.1.0-results.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
print(f"PASS: {summary[1]} native cases, 56/56 matrix rows, exact candidate {digest}")
