#!/usr/bin/env python3
"""The lint gate of SyphoDev's roblox-code skill (Selene), kept to what is a bug in Ninja Duel.

Selene was run on src/ on 19/11 with the Roblox standard library (tools/syphodev/selene_roblox_std.py):
132 errors and 10 283 warnings. Nearly all of them are the project's style (several
statements on a line, shadowing) or false positives of the generated library (`assert`
with one argument, `Vector3.yAxis:Cross`). The ten `if_same_then_else` were read and are
deliberate. One finding was a real bug: a multiple assignment from a single if-expression,

    local targets,rate=if c then wallRunTargets(...) else wallTargets(...)

Luau keeps ONE value from an if-expression, so `rate` was always nil (VelmoraMotionEngine,
the wall pose). This gate looks for that pattern, and it needs no Selene and no network:

    python3 tools/syphodev/lint_src.py          (from games/ninja-duel; in tests/run.sh)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2] / "src"
# `local a,b = if ...` or `a,b = if ...` whose right side is a single if-expression (no
# second top-level value, which would itself start with `if` or follow a top-level comma).
MULTI = re.compile(r"^\s*(local\s+)?[A-Za-z_][\w.]*\s*(,\s*[A-Za-z_][\w.]*\s*)+=\s*if\b(?P<rhs>.*)$")


def top_level_comma(s):
    depth = 0
    quote = None
    for ch in s:
        if quote:
            if ch == quote:
                quote = None
            continue
        if ch in "\"'":
            quote = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            return True
    return False


def scan():
    found = []
    for path in sorted(ROOT.rglob("*.luau")):
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            code = line.split("--", 1)[0]
            m = MULTI.match(code)
            if m and not top_level_comma(m.group("rhs")):
                found.append(f"{path.relative_to(ROOT.parent)}:{n}: several names take ONE value "
                             f"from an if-expression: {code.strip()[:120]}")
    return found


if __name__ == "__main__":
    bad = scan()
    for b in bad:
        print(b)
    if bad:
        print(f"FAIL {len(bad)} multiple assignment(s) from a single if-expression "
              "(write an if statement that assigns every name)")
        sys.exit(1)
    print("PASS no multiple assignment from a single if-expression in src/ (Selene's unbalanced_assignments)")
