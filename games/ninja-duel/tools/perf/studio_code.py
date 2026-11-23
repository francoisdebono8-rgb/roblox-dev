#!/usr/bin/env python3
"""The Studio code of the fluidity measures (OUTILLEUR, 23/11; étape 5, DEC-049).

The probe (NDPerfProbe) is in the LAB copy already (tools/lab/lab_place.py). In a Play of
it, with the device simulator on BEFORE the Play (the game builds its touch controls when
the client starts: Client/TouchControls):

    python3 tools/perf/studio_code.py --measure LABEL [seconds]   Client: a camera turn, measured
    python3 tools/perf/studio_code.py --go X Z                    Client: the body to a place of Konoha (map coordinates)
    python3 tools/perf/studio_code.py --groups                    Client: what each group of the village costs (4 directions)
    python3 tools/perf/studio_code.py --cull [studs]              Client: the dressing, the life and the folk hidden past a distance
    python3 tools/perf/studio_code.py --read                      Client: the probe's records (JSON)
    python3 tools/perf/studio_code.py --report LOG.json           the table (text)

robloxstudio-mcp adds what Luau cannot read: capture_micro_profiler (the frame, the
render, whether Studio draws at a reduced rate), get_scene_analysis triangle_composition,
capture_device_matrix (the screens of the phones).
"""
import json
import sys

MEASURE = ('local P=require(game:GetService("ReplicatedStorage"):WaitForChild("NDPerfProbe")) '
           'P.lookAround({seconds}) '
           'return game:GetService("HttpService"):JSONEncode(P.measure({{seconds={seconds},label="{label}"}}))')
GO = ('local HM=require(game:GetService("ReplicatedStorage").NinjaDuel.HubMap) '
      'local p=game:GetService("Players").LocalPlayer local root=p.Character.HumanoidRootPart '
      'local w=HM.world(Vector3.new({x},0,{z})) local params=RaycastParams.new() params.FilterDescendantsInstances={{p.Character}} '
      'local hit=workspace:Raycast(w+Vector3.new(0,80,0),Vector3.new(0,-200,0),params) '
      'root.AssemblyLinearVelocity=Vector3.zero root.CFrame=CFrame.new(w.X,(hit and hit.Position.Y or 0)+4,w.Z) '
      'return tostring(root.Position)')
READ = 'return game:GetService("Players").LocalPlayer:GetAttribute("NDPerfLog")'
GROUPS_LIST = ["NinjaDuelHub", "NinjaDuelHubDress", "NinjaDuels", "NinjaDuelArenaDress", "KonohaLife", "KonohaFolk"]
CULLED = ["NinjaDuelHubDress", "KonohaLife", "KonohaFolk"]

# The camera fixed at the body, four directions; the renderer's triangles and draw calls
# (Stats) with everything shown, then with one group made invisible (LocalTransparencyModifier,
# the client only, put back at the end).
_FOUR = '''local Stats=game:GetService("Stats")
local p=game:GetService("Players").LocalPlayer
local cam=workspace.CurrentCamera
local root=p.Character.HumanoidRootPart
local function sample() local t,d=0,0 for i=1,3 do task.wait(.25) t+=Stats.SceneTriangleCount d+=Stats.SceneDrawcallCount end return {math.floor(t/3),math.floor(d/3)} end
local function collect(names,cond) local list={} for _,g in names do local f=workspace:FindFirstChild(g) if f then for _,d in f:GetDescendants() do if d:IsA("BasePart") and cond(d) then table.insert(list,d) end end end end return list end
local function hide(list,on) for _,d in list do d.LocalTransparencyModifier=on and 1 or 0 end end
%s
cam.CameraType=Enum.CameraType.Scriptable
local res={}
local ok,err=pcall(function()
for k=0,3 do
	local a=k*math.pi/2
	local at=root.Position+Vector3.new(0,6,0)
	cam.CFrame=CFrame.lookAt(at,at+Vector3.new(math.sin(a),-0.05,-math.cos(a)))
	task.wait(.6)
	local row={dir=k,all=sample()}
	%s
	table.insert(res,row)
end
end)
%s
cam.CameraType=Enum.CameraType.Custom
return game:GetService("HttpService"):JSONEncode({ok=ok,err=err,res=res%s})'''


def groups_code() -> str:
    names = "{" + ",".join(f'"{g}"' for g in GROUPS_LIST) + "}"
    setup = f"local names={names}\nlocal lists={{}} for _,g in names do lists[g]=collect({{g}},function() return true end) end"
    body = "for _,g in names do hide(lists[g],true) row[g]=sample() hide(lists[g],false) end"
    restore = "for _,g in names do hide(lists[g],false) end"
    return _FOUR % (setup, body, restore, "")


def cull_code(studs: int = 160) -> str:
    names = "{" + ",".join(f'"{g}"' for g in CULLED) + "}"
    setup = f"local far=collect({names},function(d) return (d.Position-root.Position).Magnitude>{studs} end)"
    body = f"hide(far,true) row.cull{studs}=sample() hide(far,false)"
    return _FOUR % (setup, body, "hide(far,false)", ",far=#far")


def report(log: list) -> str:
    lines = [f"{'mesure':44} {'triangles':>17} {'appels':>11} {'i/s':>5}  parts"]
    for r in log:
        tri = f"{r.get('triangles') or 0:>7} / {r.get('trianglesMax') or 0:>7}"
        dc = f"{r.get('drawcalls') or 0:>4} / {r.get('drawcallsMax') or 0:>4}"
        lines.append(f"{r.get('label', '?')[:44]:44} {tri:>17} {dc:>11} {r.get('fps') or 0:>5}  {r.get('scene', {}).get('parts')}")
    lines.append("(triangles et appels de dessin : moyenne / maximum pendant la mesure ; i/s : ceux du Mac, voir le README)")
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    cmd = args[0]
    if cmd == "--measure":
        label = args[1] if len(args) > 1 else "?"
        print(MEASURE.format(seconds=int(args[2]) if len(args) > 2 else 10, label=label.replace('"', "'")))
    elif cmd == "--go":
        print(GO.format(x=float(args[1]), z=float(args[2])))
    elif cmd == "--groups":
        print(groups_code())
    elif cmd == "--cull":
        print(cull_code(int(args[1]) if len(args) > 1 else 160))
    elif cmd == "--read":
        print(READ)
    elif cmd == "--report":
        with open(args[1], encoding="utf-8") as f:
            data = json.load(f)
        print(report(data if isinstance(data, list) else data.get("probe", [])))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
