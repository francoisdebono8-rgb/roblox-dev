-- The village as the game builds it (Server/Hub.build, at its real scale), every
-- part written as JSON for tools/syphodev/konoha_spec.py, which turns it into a
-- roblox-map spec for SyphoDev's prover (reach, falls, overlaps, flicker...).
--   lune run tools/syphodev/konoha_dump.luau <out.json>      (from games/ninja-duel)
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local process=require("@lune/process")
local H=require("../../tests/Harness")
local roblox=require("@lune/roblox")
H.envBase.Instance=roblox.Instance
H.envBase.UDim2=roblox.UDim2;H.envBase.UDim=roblox.UDim;H.envBase.Vector2=roblox.Vector2
local HubMap=H.load("Shared/HubMap")
local Hub=H.load("Server/Hub")
local folder=Hub.build(roblox.Instance.new("Folder"))
local O=HubMap.Origin
local out={origin={O.X,O.Y,O.Z},scale=HubMap.Scale,parts={},lake=nil}
local function r(x) return math.round(x*1000)/1000 end
for _,d in folder:GetDescendants() do
	if d:IsA("BasePart") then
		local cf=d.CFrame
		local p=cf.Position-O
		local rx,ry,rz=cf:ToOrientation()
		local unit=d:FindFirstAncestorWhichIsA("Model")
		table.insert(out.parts,{
			name=d.Name,class=d.ClassName,unit=unit and unit.Name or "",
			shape=if d:IsA("Part") then d.Shape.Name else d.ClassName,
			size={r(d.Size.X),r(d.Size.Y),r(d.Size.Z)},pos={r(p.X),r(p.Y),r(p.Z)},
			rot={r(math.deg(rx)),r(math.deg(ry)),r(math.deg(rz))},
			look={r(cf.LookVector.X),r(cf.LookVector.Y),r(cf.LookVector.Z)},
			up={r(cf.UpVector.X),r(cf.UpVector.Y),r(cf.UpVector.Z)},
			collide=d.CanCollide,transparency=r(d.Transparency),material=d.Material.Name,
			color={math.round(d.Color.R*255),math.round(d.Color.G*255),math.round(d.Color.B*255)},
			wall=d:GetAttribute("NinjaWall")==true,breakable=d:GetAttribute("NinjaBreak")~=nil,
		})
	end
end
if Hub.lake then
	local p=Hub.lake.cf.Position-O
	out.lake={pos={r(p.X),r(p.Y),r(p.Z)},size={r(Hub.lake.size.X),r(Hub.lake.size.Y),r(Hub.lake.size.Z)}}
end
fs.writeFile(process.args[1] or "konoha.json",serde.encode("json",out))
print(("%d parts from Hub.build (scale %s)"):format(#out.parts,tostring(HubMap.Scale)))
