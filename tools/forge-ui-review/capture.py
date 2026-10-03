"""Capture native review windows after the harness announces each stable viewport.

Produces unmodified window screenshots in /tmp only. Review them before any crop.
"""
import argparse
from pathlib import Path
import re
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("log", type=Path)
parser.add_argument("--helper", type=Path, required=True)
parser.add_argument("--window-id")
parser.add_argument("--count", type=int, default=6)
args = parser.parse_args()
seen = set()
window_id = args.window_id
deadline = time.monotonic() + 180
while time.monotonic() < deadline:
    text = args.log.read_text(errors="replace") if args.log.exists() else ""
    if "[ForgeUIReview] FAIL" in text:
        raise SystemExit("Native harness failed; inspect its diagnostic log.")
    matches = re.findall(r"\[ForgeUIReview\] CAPTURE (\w+) (560|320) viewport=", text)
    if matches and matches[-1] not in seen:
        name, width = matches[-1]
        if not window_id:
            listing = subprocess.check_output(["python3", str(args.helper), "--list-windows", "--app", "Roblox Studio"], text=True)
            windows = [line.split("\t")[0] for line in listing.splitlines() if "562x666" in line]
            if not windows:
                time.sleep(1)
                continue
            window_id = windows[-1]
        path = Path("/tmp") / f"forge-review-{name}-{width}.png"
        subprocess.run(["python3", str(args.helper), "--window-id", window_id, "--path", str(path)], check=True)
        seen.add((name, width))
        print(f"Captured {name} {width}: {path}", flush=True)
    if len(seen) == args.count:
        break
    time.sleep(0.5)
if len(seen) != args.count:
    raise SystemExit(f"Only {len(seen)}/{args.count} windows captured; not a visual PASS.")
