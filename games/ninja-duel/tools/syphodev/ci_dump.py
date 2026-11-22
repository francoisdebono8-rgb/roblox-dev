#!/usr/bin/env python3
"""The village as Hub.build makes it, dumped by lune on GitHub's runner, for a session
without lune (OUTILLEUR, 21/11). konoha_dump.luau needs lune; the suite's workflow has it.

On a scratch branch (never the common one), the end of tests/run.sh becomes:

    "$LUNE" run tools/syphodev/konoha_dump.luau /tmp/konoha.json || status=1
    python3 tools/syphodev/ci_dump.py --print /tmp/konoha.json
    exit $status

then `gh workflow run ninja-duel-suite.yml --ref <branch>` and, once it is done:

    python3 tools/syphodev/ci_dump.py --fetch <run id> work/map/konoha.json
    python3 tools/syphodev/konoha_spec.py work/map/konoha.json work/map/konoha_spec.json
    python3 tools/syphodev/konoha_prove.py work/map/konoha_spec.json work/map/konoha_report.json

The JSON goes through the log gzipped, in base64 lines of 3000 characters ("KJ ...").
"""
import base64
import gzip
import json
import re
import subprocess
import sys

REPO = "francoisdebono8-rgb/roblox-dev"
WIDTH = 3000


def encode(data: dict) -> list:
    raw = base64.b64encode(gzip.compress(json.dumps(data, separators=(",", ":")).encode())).decode()
    return ["KJ " + raw[i:i + WIDTH] for i in range(0, len(raw), WIDTH)]


def decode(log: str) -> dict:
    chunks = []
    for line in log.splitlines():
        m = re.search(r"(?:^|\s)KJ (\S+)$", line)
        if m:
            chunks.append(m.group(1))
    if not chunks:
        raise SystemExit("no KJ line in this log")
    return json.loads(gzip.decompress(base64.b64decode("".join(chunks))))


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if len(args) >= 2 and args[0] == "--print":
        with open(args[1], encoding="utf-8") as f:
            for line in encode(json.load(f)):
                print(line)
        return 0
    if len(args) >= 3 and args[0] == "--fetch":
        log = subprocess.run(["gh", "run", "view", args[1], "--repo", REPO, "--log"], capture_output=True, text=True).stdout
        data = decode(log)
        with open(args[2], "w", encoding="utf-8") as f:
            json.dump(data, f)
        print(f"{len(data.get('parts', []))} parts -> {args[2]}")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
