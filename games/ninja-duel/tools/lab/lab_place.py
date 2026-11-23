#!/usr/bin/env python3
"""A LAB copy of a place, with the OUTILLEUR's robots already in it (23/11, étape 5).

    python3 tools/lab/lab_place.py PLACES/ND-JEU.rbxlx LAB/robots/ND-JEU-robots-<commit>.rbxlx

It writes a copy of the place with four ModuleScripts in ReplicatedStorage, so that a
Play of the copy has them without pasting anything in Studio:

  NDDuelBot       the simulated player (tools/duelbot: PlayerSim + the client driver)
  NDVillageBot    the village robot (tools/villagebot)
  NDNewPlayerBot  the new player's ten minutes (tools/newplayer)
  NDPerfProbe     the fluidity probe (tools/perf)

and a StringValue NDLabTools with the commit of the tools. The game itself is not
touched: only the copy gets them, never a place of PLACES/ (the source refuses to be the
output), and never the published game (the build never contains them: the pre-vol,
tools/preflight, checks it).
"""
import hashlib
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(TOOLS, "duelbot"))
import studio_code as duel  # noqa: E402


def read(rel):
    with open(os.path.join(TOOLS, rel), encoding="utf-8") as f:
        return f.read()


def modules() -> dict:
    """The robots' sources, comments stripped (what Studio runs)."""
    return {
        "NDDuelBot": duel.module_source(),
        "NDVillageBot": duel.strip(read("villagebot/village_bot.luau")),
        "NDNewPlayerBot": duel.strip(read("newplayer/newplayer_bot.luau")),
        "NDPerfProbe": duel.strip(read("perf/perf_probe.luau")),
    }


def commit() -> str:
    try:
        return subprocess.run(["git", "rev-parse", "--short=8", "HEAD"], cwd=TOOLS, capture_output=True,
                              text=True, timeout=10).stdout.strip() or "?"
    except Exception:
        return "?"


def item(cls, name, prop, value, ref):
    assert "]]>" not in value
    kind = "ProtectedString" if prop == "Source" else "string"
    return (f'<Item class="{cls}" referent="{ref}"><Properties><string name="Name">{name}</string>'
            f'<{kind} name="{prop}"><![CDATA[{value}]]></{kind}></Properties></Item>')


def inject(text: str, mods: dict, stamp: str) -> str:
    """The place's XML with the modules under ReplicatedStorage (old copies replaced)."""
    for name in list(mods) + ["NDLabTools"]:
        # a copy made from a copy: its old robots go
        text = re.sub(r'<Item class="(?:ModuleScript|StringValue)" referent="RBXNDLAB\w+">.*?<string name="Name">'
                      + name + r'</string>.*?</Item>', "", text, flags=re.S)
    m = re.search(r'<Item class="ReplicatedStorage" referent="[^"]*">\s*<Properties>.*?</Properties>', text, flags=re.S)
    if not m:
        raise ValueError("no ReplicatedStorage in the place")
    parts = []
    for i, (name, src) in enumerate(sorted(mods.items())):
        ref = "RBXNDLAB" + hashlib.sha1(name.encode()).hexdigest()[:24].upper()
        parts.append(item("ModuleScript", name, "Source", src, ref))
    parts.append(item("StringValue", "NDLabTools", "Value", stamp, "RBXNDLAB" + "0" * 24))
    return text[:m.end()] + "".join(parts) + text[m.end():]


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 2:
        print(__doc__)
        return 2
    src, out = args
    if os.path.abspath(src) == os.path.abspath(out):
        print("the copy must be another file than the place")
        return 2
    if os.sep + "PLACES" + os.sep in os.path.abspath(out):
        print("the copy goes in LAB/, never in PLACES/")
        return 2
    with open(src, encoding="utf-8") as f:
        text = f.read()
    mods = modules()
    stamp = f"tools {commit()} : " + ", ".join(sorted(mods))
    with open(out, "w", encoding="utf-8") as f:
        f.write(inject(text, mods, stamp))
    print(f"{out}: {stamp} ({sum(len(s) for s in mods.values())} characters of robots)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
