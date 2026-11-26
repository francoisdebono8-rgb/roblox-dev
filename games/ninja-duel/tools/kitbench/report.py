#!/usr/bin/env python3
"""The kits' bench report (OUTILLEUR, passe commune 3, 26/11; DEC-055).

    python3 tools/kitbench/report.py CLIPS.json [--md RAPPORT.md]
    python3 tools/kitbench/report.py --sheet KIT [FROM]   Client : la planche (puis capture_screenshot)
    python3 tools/kitbench/report.py --clips             Client : quel clip chaque kit joue

CLIPS.json is _G.NDKitBench.clips() (tools/kitbench/kit_bench.luau, injected by
tools/robots/inject.py bench): for each kit and each street move, the clip the game plays
(Client/HubBody.clipName) and whether it is the kit's own or borrowed from Lion.
"""
import json
import sys

BENCH_LUA = '(_G.NDKitBench or error("NDKitBench absent : python3 tools/robots/inject.py bench (pendant le Play)"))'
KITS = ["Lion", "Legion", "Sand", "Leaf", "GentleFist", "Mirage", "Copycat", "Flashstep"]
NAMES = {"Lion": "Sasuke", "Legion": "Naruto", "Sand": "Gaara", "Leaf": "Lee", "GentleFist": "Neji",
         "Mirage": "Itachi", "Copycat": "Kakashi", "Flashstep": "Minato"}
MOVES = ["Light1", "Light2", "Light3", "Heavy", "Air", "Dodge", "Guard"]


def borrowed(clips: dict) -> list:
    """(kit, move, clip) for each move a kit plays with another kit's clip."""
    out = []
    for kit in KITS:
        for move in MOVES:
            c = (clips.get(kit) or {}).get(move) or {}
            if c and not c.get("own"):
                out.append((kit, move, c.get("clip")))
    return out


def report(clips: dict) -> str:
    lines = ["# Le banc des kits : quel clip chaque coup joue", "",
             "| kit | " + " | ".join(MOVES) + " |", "|---|" + "---|" * len(MOVES)]
    for kit in KITS:
        cells = []
        for move in MOVES:
            c = (clips.get(kit) or {}).get(move) or {}
            if not c:
                cells.append("—")
            elif c.get("own"):
                cells.append(f"{c.get('length')} s")
            else:
                cells.append(f"**{c.get('clip')}** ({c.get('length')} s)")
        lines.append(f"| {NAMES[kit]} ({kit}) | " + " | ".join(cells) + " |")
    b = borrowed(clips)
    lines.append("")
    lines.append("Chaque case : la longueur du clip du kit ; en gras, le clip d'un autre kit que le jeu prend faute du sien. "
                 + (f"{len(b)} coup(s) emprunté(s) : " + ", ".join(f"{NAMES[k]} {m} ({c})" for k, m, c in b) + "." if b else "Aucun coup emprunté."))
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--sheet":
        kit = args[1]
        start = int(args[2]) if len(args) > 2 else 1
        print(f'return {BENCH_LUA}.sheet("{kit}",{start},16,"side")')
        return 0
    if args[0] == "--clips":
        print(f"return {BENCH_LUA}.clips()")
        return 0
    with open(args[0], encoding="utf-8") as f:
        clips = json.load(f)
    text = report(clips)
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
