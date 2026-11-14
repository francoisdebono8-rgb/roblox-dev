-- (13/11, user: « il va nous falloir des vrais modèles 3D, des vrais modèles de
-- technique ») The game's modelled props: weapons, the sand of Gaara's
-- ultimate, and what comes next. tools/blender/fx_models.py models them and
-- writes Client/MeshData (packed vertices, colours, triangles); this module
-- builds each piece once on the client with AssetService:CreateEditableMesh
-- (like VfxKit's textures: nothing to upload) and hands out clones.
--   MeshKit.prepare()          builds every template (yields; run it in the background)
--   MeshKit.has(name)          true once that model is ready
--   MeshKit.model(name)        a Model: a transparent "Root" (PrimaryPart) at the
--                              model's origin and its pieces welded to it; nil if
--                              not ready (the caller keeps its part-built version)
--   MeshKit.part(name,piece)   one piece's MeshPart clone (or nil)
-- Presentation only. Headless (no AssetService) nothing is built and every
-- caller keeps its primitives.
local MeshKit={ready={},state="idle",error=nil}
local okData,Data=pcall(require,script.Parent.MeshData)
MeshKit.Data=if okData then Data else {}

-- base64 -> buffer
local B64={}
do
	local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	for i=1,64 do B64[string.byte(alphabet,i)]=i-1 end
end
function MeshKit.decode(s)
	local n=#s
	local pad=0
	if string.sub(s,-2)=="==" then pad=2 elseif string.sub(s,-1)=="=" then pad=1 end
	local out=buffer.create(n//4*3-pad)
	local o=0
	local size=buffer.len(out)
	for i=1,n,4 do
		local a,b,c,d=string.byte(s,i,i+3)
		local x=bit32.bor(bit32.lshift(B64[a] or 0,18),bit32.lshift(B64[b] or 0,12),bit32.lshift(B64[c] or 0,6),B64[d] or 0)
		if o<size then buffer.writeu8(out,o,bit32.rshift(x,16)) end
		if o+1<size then buffer.writeu8(out,o+1,bit32.band(bit32.rshift(x,8),255)) end
		if o+2<size then buffer.writeu8(out,o+2,bit32.band(x,255)) end
		o+=3
	end
	return out
end

-- The piece's arrays: positions (round its centre), colours, triangles.
function MeshKit.unpack(spec)
	local raw=MeshKit.decode(spec.d)
	local n,m=spec.n,spec.m
	local h=spec.h
	local pos,col,tri=table.create(n),table.create(n),table.create(m*3)
	local at=0
	for i=1,n do
		local x=buffer.readu16(raw,at)/65535*2-1
		local y=buffer.readu16(raw,at+2)/65535*2-1
		local z=buffer.readu16(raw,at+4)/65535*2-1
		pos[i]=Vector3.new(x*h[1],y*h[2],z*h[3])
		at+=6
	end
	for i=1,n do
		col[i]=Color3.fromRGB(buffer.readu8(raw,at),buffer.readu8(raw,at+1),buffer.readu8(raw,at+2))
		at+=3
	end
	for k=1,m*3 do
		tri[k]=buffer.readu16(raw,at)+1
		at+=2
	end
	return pos,col,tri
end

local MATERIAL={}
for _,name in {"Metal","Fabric","Sand","Slate","Rock","Glass","Neon","Wood","SmoothPlastic","Plastic","Ice","Concrete","Granite","Grass","Marble","ForceField"} do
	local ok,m=pcall(function() return Enum.Material[name] end)
	if ok then MATERIAL[name]=m end
end

local function build(spec)
	local AssetService=game:GetService("AssetService")
	local em=AssetService:CreateEditableMesh({})
	local pos,col,tri=MeshKit.unpack(spec)
	local ids,cols=table.create(#pos),table.create(#pos)
	for i,p in pos do
		ids[i]=em:AddVertex(p)
		cols[i]=em:AddColor(col[i],1)
	end
	local acc
	if not spec.flat then
		acc=table.create(#pos,Vector3.zero)
		for k=1,#tri,3 do
			local a,b,c=tri[k],tri[k+1],tri[k+2]
			local nrm=(pos[b]-pos[a]):Cross(pos[c]-pos[a])
			acc[a]+=nrm;acc[b]+=nrm;acc[c]+=nrm
		end
	end
	local nid={}
	for k=1,#tri,3 do
		local a,b,c=tri[k],tri[k+1],tri[k+2]
		local f=em:AddTriangle(ids[a],ids[b],ids[c])
		em:SetFaceColors(f,{cols[a],cols[b],cols[c]})
		if spec.flat then
			local nrm=(pos[b]-pos[a]):Cross(pos[c]-pos[a])
			local id=em:AddNormal(if nrm.Magnitude>1e-9 then nrm.Unit else Vector3.yAxis)
			em:SetFaceNormals(f,{id,id,id})
		else
			local list={}
			for j,i in {a,b,c} do
				if not nid[i] then
					local nrm=acc[i]
					nid[i]=em:AddNormal(if nrm.Magnitude>1e-9 then nrm.Unit else Vector3.yAxis)
				end
				list[j]=nid[i]
			end
			em:SetFaceNormals(f,list)
		end
	end
	-- (14/11, CM QA: « Failed to create empty EditableMesh … memory budget » at
	-- every Play) A client holds only a handful of live EditableMeshes, and a
	-- MeshPart made straight from one keeps it alive: the budget ran out after
	-- a few pieces. Each piece is baked into static content
	-- (AssetService:CreateDataModelContentAsync) and its EditableMesh freed;
	-- only where baking is unavailable is the live mesh kept (as before).
	local part
	local okBake,result,content=pcall(function() return AssetService:CreateDataModelContentAsync(Content.fromObject(em)) end)
	if okBake and result==Enum.CreateContentResult.Success and content then
		part=AssetService:CreateMeshPartAsync(content)
		em:Destroy()
		MeshKit.baked=(MeshKit.baked or 0)+1
	else
		part=AssetService:CreateMeshPartAsync(Content.fromObject(em))
		MeshKit.live=(MeshKit.live or 0)+1
	end
	part.Name=spec.name
	part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.CastShadow=false
	part.Color=Color3.new(1,1,1)
	part.Material=MATERIAL[spec.mat] or Enum.Material.SmoothPlastic
	part.Transparency=spec.alpha or 0
	part.Reflectance=spec.reflect or 0
	-- the mesh's bounds are the packed half extents: keep the authored size
	part.Size=Vector3.new(spec.h[1]*2,spec.h[2]*2,spec.h[3]*2)
	return part
end

-- Builds every template (yields between models so a frame never stalls).
function MeshKit.prepare(names)
	if MeshKit.state=="loading" or MeshKit.state=="failed" then return end
	MeshKit.state="loading"
	local okService=pcall(function() return game:GetService("AssetService").CreateEditableMesh end)
	if not okService then MeshKit.state="failed";MeshKit.error="no AssetService";return end
	for name,pieces in MeshKit.Data do
		if MeshKit.ready[name] or (names and not table.find(names,name)) then continue end
		local made={}
		local ok,err=pcall(function()
			for _,spec in pieces do table.insert(made,{part=build(spec),o=Vector3.new(spec.o[1],spec.o[2],spec.o[3]),name=spec.name}) end
		end)
		if not ok then
			MeshKit.state="failed";MeshKit.error=tostring(err)
			warn("[NinjaDuel] MeshKit: modelled props unavailable, primitives kept: "..tostring(err))
			return
		end
		MeshKit.ready[name]=made
		task.wait()
	end
	MeshKit.state="ready"
end

function MeshKit.has(name) return MeshKit.ready[name]~=nil end

function MeshKit.model(name)
	local t=MeshKit.ready[name]
	if not t then return nil end
	local model=Instance.new("Model");model.Name=name
	local root=Instance.new("Part")
	root.Name="Root";root.Size=Vector3.one*.1;root.Transparency=1
	root.Anchored=true;root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;root.CastShadow=false
	root.CFrame=CFrame.new();root.Parent=model
	for _,entry in t do
		local p=entry.part:Clone()
		p.CFrame=CFrame.new(entry.o)
		p.Anchored=false;p.Massless=true
		p.Parent=model
		local w=Instance.new("WeldConstraint");w.Name="Hold";w.Part0=root;w.Part1=p;w.Parent=root
	end
	model.PrimaryPart=root
	return model
end

function MeshKit.part(name,piece)
	local t=MeshKit.ready[name]
	if not t then return nil end
	for _,entry in t do
		if piece==nil or entry.name==piece then
			local p=entry.part:Clone()
			return p,entry.o
		end
	end
	return nil
end
return MeshKit
