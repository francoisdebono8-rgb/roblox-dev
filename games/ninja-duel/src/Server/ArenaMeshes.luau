-- The stadium's scenery made in Blender (stage 5, user 29/10: the arena,
-- "stade Chûnin, original"). tools/blender/arena_assets.py models each asset
-- around its own origin; Studio's importer uploads them;
-- tools/blender/arena_to_luau.py writes Server/ArenaMeshData (per asset: the
-- pieces' mesh, offset from the asset's origin, size, colour, material).
-- Each mesh is made once at server start; World.arena places assets with
-- ArenaMeshes.place. Until they are ready (or headless) World keeps its
-- part-built decor. Gameplay never depends on these: they are visual only
-- (no collision, no queries); walls, balcony, cover and breakables stay parts.
local ArenaMeshes={templates={},state="idle"}
local ok,Data=pcall(require,script.Parent.ArenaMeshData)
if not ok then Data={} end
ArenaMeshes.Data=Data

local OPTIONS=nil
pcall(function() OPTIONS={RenderFidelity=Enum.RenderFidelity.Precise,CollisionFidelity=Enum.CollisionFidelity.Box} end)

function ArenaMeshes.preload()
	if ArenaMeshes.state~="idle" then return end
	local okService,AssetService=pcall(function() return game:GetService("AssetService") end)
	if not okService or not AssetService or not AssetService.CreateMeshPartAsync then return end
	local list={}
	for _,pieces in Data do for _,piece in pieces do table.insert(list,piece) end end
	if #list==0 then return end
	ArenaMeshes.state="loading"
	local left,failed=#list,false
	for _,piece in list do
		task.spawn(function()
			local good,part=pcall(function() return AssetService:CreateMeshPartAsync(piece.mesh,OPTIONS) end)
			if good and part then
				ArenaMeshes.templates[piece.mesh]=part
			else
				failed=true
				warn("[ArenaMeshes] "..piece.name..": "..tostring(part))
			end
			left-=1
			if left==0 then ArenaMeshes.state=if failed then "failed" else "ready" end
		end)
	end
end

function ArenaMeshes.ready()
	return ArenaMeshes.state=="ready"
end

-- Place one asset at cf (its origin), uniformly scaled. Returns the parts.
function ArenaMeshes.place(parent,asset,cf,scale)
	local pieces=Data[asset]
	if not pieces then return {} end
	scale=scale or 1
	local made={}
	for _,piece in pieces do
		local template=ArenaMeshes.templates[piece.mesh]
		if template then
			local p=template:Clone()
			p.Name=asset.."_"..piece.name
			p.Size=piece.size*scale
			p.CFrame=cf*CFrame.new(piece.offset*scale)
			p.Color=piece.color
			p.Material=Enum.Material[piece.material or "SmoothPlastic"] or Enum.Material.SmoothPlastic
			p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
			p.Parent=parent
			table.insert(made,p)
		end
	end
	return made
end

return ArenaMeshes
