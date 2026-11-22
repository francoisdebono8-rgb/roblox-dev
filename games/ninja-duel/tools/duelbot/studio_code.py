#!/usr/bin/env python3
"""The Studio code of the simulated player (OUTILLEUR, 21/11).

    python3 tools/duelbot/studio_code.py --module
        Edit datamodel: installs ReplicatedStorage.NDDuelBot (PlayerSim pasted into
        studio_bot.luau, comments stripped) in the LAB place.
    python3 tools/duelbot/studio_code.py --first debutant 1,2 Lion,Legion,Leaf
    python3 tools/duelbot/studio_code.py --duel joueur easy 1 Lion:Mirage,Lion:Sand
    python3 tools/duelbot/studio_code.py '[{"mode":"first","kit":"Lion","seed":1}]'
        Client datamodel, during a Play: starts that plan; then --read reads it.
    python3 tools/duelbot/studio_code.py --read
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def lua_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, list):
        return "{" + ",".join(lua_value(x) for x in v) + "}"
    if isinstance(v, dict):
        return "{" + ",".join(f"{k}={lua_value(x)}" for k, x in v.items()) + "}"
    raise TypeError(v)


def strip(src: str) -> str:
    out = []
    for line in src.split("\n"):
        if line.strip().startswith("--"):
            continue
        # a trailing comment outside a string (none of ours has "--" in a string)
        if "--" in line and '"' not in line.split("--", 1)[1]:
            code = line.split("--", 1)[0]
            if code.count('"') % 2 == 0:
                line = code
        if line.strip():
            out.append(line.rstrip())
    return "\n".join(out)


def module_source() -> str:
    with open(os.path.join(HERE, "PlayerSim.luau"), encoding="utf-8") as f:
        sim = f.read()
    with open(os.path.join(HERE, "studio_bot.luau"), encoding="utf-8") as f:
        bot = f.read()
    sim_body = strip(sim)
    assert sim_body.rstrip().endswith("return PlayerSim")
    bot = bot.replace("local PlayerSim=nil --@PLAYERSIM", "local PlayerSim=(function()\n" + sim_body + "\nend)()")
    assert "--@" not in bot
    return strip(bot)


def install() -> str:
    src = module_source()
    assert "]==]" not in src
    return ('local old=game:GetService("ReplicatedStorage"):FindFirstChild("NDDuelBot") if old then old:Destroy() end\n'
            'local m=Instance.new("ModuleScript") m.Name="NDDuelBot"\n'
            "m.Source=[==[\n" + src + "\n]==]\n"
            'm.Parent=game:GetService("ReplicatedStorage") return "NDDuelBot "..#m.Source')


def start(plan: list) -> str:
    return 'return require(game:GetService("ReplicatedStorage"):WaitForChild("NDDuelBot")).start(' + lua_value(plan) + ")"


READ = ('local p=game:GetService("Players").LocalPlayer '
        'return tostring(p:GetAttribute("NDBotState")).." | "..tostring(p:GetAttribute("NDBotLog"))')


def plan_from_args(args: list) -> list:
    if args[0] == "--first":
        profile, seeds, kits = args[1], args[2].split(","), args[3].split(",")
        return [{"mode": "first", "kit": k, "seed": int(s), "profile": profile} for s in seeds for k in kits]
    if args[0] == "--duel":
        profile, level, seeds, pairs = args[1], args[2], args[3].split(","), args[4].split(",")
        return [{"mode": "duel", "kit": p.split(":")[0], "rival": p.split(":")[1], "level": level, "seed": int(s),
                 "profile": profile} for s in seeds for p in pairs]
    return json.loads(args[0])


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--module":
        print(install())
    elif args[0] == "--read":
        print(READ)
    else:
        print(start(plan_from_args(args)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
