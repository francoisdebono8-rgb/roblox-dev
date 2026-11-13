-- (13/11, user: « les dragons ça va pas trop, cherche des modèles de dragons
-- en 3D ») Kakashi's Water Dragon and Earth Dragon as real modelled meshes:
-- the eastern dragon of tools/blender/fx_dragon.py (long skull, open jaw,
-- fangs, horns, whiskers, mane, fierce eyes; a body of finned segments),
-- painted with vertex colours. The meshes are built on the client at run time
-- from Client/DragonMeshes (AssetService:CreateEditableMesh, like VfxKit's
-- textures): nothing is uploaded. They are made once, in the background, at
-- install; until they are ready (or if the engine refuses EditableMesh) the
-- builders return nil and FamilyFX keeps its primitive dragon.
local DragonFX={}
local Data=require(script.Parent.DragonMeshes)
DragonFX.ready={}      -- style -> {head=MeshPart, jaw=MeshPart, seg=MeshPart}
DragonFX.failed=nil
DragonFX.MODEL_WIDTH=1.64 -- the modelled head's width at scale 1
DragonFX.JAW_PIVOT=Vector3.new(0,-.3,.35)
DragonFX.JAW_OPEN=24       -- degrees, the roar

local function meshPart(spec)
	local AssetService=game:GetService("AssetService")
	local em=AssetService:CreateEditableMesh({})
	local v,t,c=spec.v,spec.t,spec.c
	local ids,cols,pos={},{},{}
	for i=1,#v/3 do
		local p=Vector3.new(v[i*3-2],v[i*3-1],v[i*3])
		pos[i]=p
		ids[i]=em:AddVertex(p)
		cols[i]=em:AddColor(Color3.fromRGB(c[i*3-2],c[i*3-1],c[i*3]),1)
	end
	-- normals: per face for the rock (faceted), averaged for the water
	local acc={}
	if not spec.flat then
		for k=1,#t/3 do
			local a,b,d=t[k*3-2],t[k*3-1],t[k*3]
			local n=(pos[b]-pos[a]):Cross(pos[d]-pos[a])
			for _,i in {a,b,d} do acc[i]=(acc[i] or Vector3.zero)+n end
		end
	end
	local nid={}
	for k=1,#t/3 do
		local a,b,d=t[k*3-2],t[k*3-1],t[k*3]
		local f=em:AddTriangle(ids[a],ids[b],ids[d])
		em:SetFaceColors(f,{cols[a],cols[b],cols[d]})
		if spec.flat then
			local n=(pos[b]-pos[a]):Cross(pos[d]-pos[a])
			local id=em:AddNormal(if n.Magnitude>1e-6 then n.Unit else Vector3.yAxis)
			em:SetFaceNormals(f,{id,id,id})
		else
			local list={}
			for j,i in {a,b,d} do
				if not nid[i] then
					local n=acc[i] or Vector3.yAxis
					nid[i]=em:AddNormal(if n.Magnitude>1e-6 then n.Unit else Vector3.yAxis)
				end
				list[j]=nid[i]
			end
			em:SetFaceNormals(f,list)
		end
	end
	local part=AssetService:CreateMeshPartAsync(Content.fromObject(em))
	part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
	part.Color=Color3.new(1,1,1);part.Material=Enum.Material.SmoothPlastic
	return part
end

-- Builds the templates (yields). Called once, in the background.
function DragonFX.prepare()
	if DragonFX.failed~=nil then return end
	local ok,err=pcall(function()
		for style,set in Data do
			local out={}
			for key,spec in set do out[key]=meshPart(spec) end
			DragonFX.ready[style]=out
		end
	end)
	DragonFX.failed=if ok then false else tostring(err)
	if not ok then warn("[NinjaDuel] DragonFX: modelled dragons unavailable, primitives kept: "..tostring(err)) end
end

-- The serpent model FamilyFX's path pose drives: head (PrimaryPart), the
-- jaw welded open, and `n` segments named Segment1..n, sized to the look.
function DragonFX.build(style,look,n)
	local t=DragonFX.ready[style]
	if not t then return nil end
	local w=look.size[1]
	local k=w/DragonFX.MODEL_WIDTH
	local m=Instance.new("Model");m.Name="FamilySerpent"
	if style=="earth" then pcall(m.SetAttribute,m,"KeepShadow",true) end
	local head=t.head:Clone()
	head.Size=head.Size*k;head.CFrame=CFrame.new();head.Parent=m
	local jaw=t.jaw:Clone()
	jaw.Size=jaw.Size*k
	local hinge=DragonFX.JAW_PIVOT*k
	-- the jaw mesh is centred on its own bounds: place it by its rest offset
	jaw.CFrame=CFrame.new(hinge)*CFrame.Angles(math.rad(-DragonFX.JAW_OPEN),0,0)*CFrame.new(-hinge)*CFrame.new(t.jawOffset or Vector3.zero)
	jaw.Anchored=false;jaw.Massless=true
	jaw.Parent=m
	local weld=Instance.new("WeldConstraint");weld.Part0=head;weld.Part1=jaw;weld.Parent=head
	for i=1,n do
		local seg=t.seg:Clone()
		local taper=1-(i/n)*.62
		seg.Size=seg.Size*k*1.1*taper
		seg.Name="Segment"..i
		seg.CFrame=CFrame.new(0,0,i*look.size[3]/(n+1))
		seg.Parent=m
	end
	if style=="water" then
		for _,p in m:GetChildren() do if p:IsA("BasePart") then p.Transparency=.12;p.Reflectance=.08 end end
	end
	m.PrimaryPart=head
	return m
end
return DragonFX
