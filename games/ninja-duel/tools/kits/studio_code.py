#!/usr/bin/env python3
"""Prints the Luau to run in Studio (Edit) for the kit tools, with the module
inside: paste it in the command bar (or Roblox_Studio execute_luau, Edit) and
save the JSON it returns.

    python3 tools/kits/studio_code.py          the kits' fingerprint (KitPrint.luau)
    python3 tools/kits/studio_code.py nodes    what every tree node changes (NodeCheck.luau)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

NODES = '''local NodeCheck=(function()
\t--[[ NodeCheck.luau ]]
end)()
local RS=game:GetService("ReplicatedStorage").NinjaDuel
local server=game:GetService("ServerScriptService"):FindFirstChild("NinjaDuelServer")
local mods={SkillBuilds=require(server.SkillBuilds),SkillTrees=require(RS.SkillTrees),BetaRoster=require(RS.BetaRoster),
\tNinjaTree=RS:FindFirstChild("NinjaTree") and require(RS.NinjaTree)}
local result=NodeCheck.run(mods)
local light={failures=result.failures,lines=NodeCheck.lines(result),kits={},ninja={}}
for _,id in result.order do
\tlight.kits[id]={}
\tfor _,row in result.kits[id] do
\t\ttable.insert(light.kits[id],{id=row.id,major=row.major,kind=row.kind,tier=row.tier,unlock=row.unlock,item=row.item,
\t\t\twired=row.wired,changes=#row.changes,kinds=row.kinds,error=row.error})
\tend
end
for _,row in result.ninja or {} do table.insert(light.ninja,{id=row.id,changes=#row.changes}) end
return game:GetService("HttpService"):JSONEncode(light)
'''


def code(which: str = "kitprint") -> str:
    if which == "nodes":
        body = open(os.path.join(HERE, "NodeCheck.luau"), encoding="utf-8").read()
        return NODES.replace("\t--[[ NodeCheck.luau ]]\n", body)
    body = open(os.path.join(HERE, "KitPrint.luau"), encoding="utf-8").read()
    wrapper = open(os.path.join(HERE, "studio_kitprint.luau"), encoding="utf-8").read()
    return wrapper.replace("\t--[[ KitPrint.luau ]]\n", body)


if __name__ == "__main__":
    print(code(sys.argv[1] if len(sys.argv) > 1 else "kitprint"), end="")
