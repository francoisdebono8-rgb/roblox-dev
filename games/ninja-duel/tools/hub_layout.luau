-- Konoha's layout for an overview render without Studio (14/11, HUB_DRESS):
-- builds the village headless (Server/Hub, Lune's Roblox instances) and
-- writes, as JSON, every dressed copy (the mesh's name, its CFrame and scale,
-- as Client/HubDress places it) and every part that stays seen (the ground,
-- the streets, the signs, the crests). tools/blender/konoha_village.py reads
-- it with the ANIMATOR's konoha_models.py and renders the village.
--   lune run tools/hub_layout.luau OUT.json      (from games/ninja-duel)
local fs=require("@lune/fs")
local process=require("@lune/process")
local roblox=require("@lune/roblox")
local H=require("../tests/Harness")
H.envBase.Instance=roblox.Instance
H.envBase.UDim2=roblox.UDim2;H.envBase.UDim=roblox.UDim;H.envBase.Vector2=roblox.Vector2
local Hub=H.load("Server/Hub")
local HubDress=H.load("Client/HubDress")
local HubMap=H.load("Shared/HubMap")
local root=roblox.Instance.new("Folder")
local folder=Hub.build(root)

local function cf(c) return {c:GetComponents()} end
local function v(x) return {x.X,x.Y,x.Z} end
local out={origin=v(HubMap.Origin),copies={},parts={}}
local hidden={}
for _,unit in HubDress.units(folder) do
	local name=unit:GetAttribute("Dress")
	for _,spot in HubDress.spots(unit) do table.insert(out.copies,{name=name,cf=cf(spot.at),scale=v(spot.scale)}) end
	for _,p in HubDress.parts(unit) do hidden[p]=true end
end
for _,p in folder:GetDescendants() do
	if p:IsA("BasePart") and not hidden[p] and p.Transparency<1 then
		local c=p.Color
		table.insert(out.parts,{name=p.Name,cf=cf(p.CFrame),size=v(p.Size),color={c.R,c.G,c.B},
			shape=if p:IsA("Part") then p.Shape.Name else "Block",material=p.Material.Name})
	end
end
local path=process.args[1] or "hub_layout.json"
fs.writeFile(path,require("@lune/serde").encode("json",out,false))
print(string.format("%d copies, %d parts -> %s",#out.copies,#out.parts,path))
