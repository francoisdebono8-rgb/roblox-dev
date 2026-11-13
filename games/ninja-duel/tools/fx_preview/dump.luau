-- (13/11) Offline look at the creatures and objects the effects build from
-- Roblox primitives (no Studio needed): runs the game's own builders headless
-- (Lune, real Instances) and writes every visible part (shape, mesh, size,
-- CFrame, colour, material, transparency) as JSON for render.py (Blender).
--   lune run tools/fx_preview/dump.luau OUT.json
local roblox=require("@lune/roblox")
local fs=require("@lune/fs")
local process=require("@lune/process")
local H=require("../../tests/Harness")
for _,k in {"Instance","UDim","UDim2","NumberSequence","NumberSequenceKeypoint","ColorSequence","NumberRange","Color3","Vector2"} do H.envBase[k]=roblox[k] end
local Instance=roblox.Instance
local function new(class,props,parent)
	local i=Instance.new(class)
	for k,v in props or {} do pcall(function() i[k]=v end) end
	if parent then i.Parent=parent end
	return i
end
local function block(parent,size,cf,color,material,class)
	return new(class or "Part",{Size=size,CFrame=cf,Color=color,Material=material or roblox.Enum.Material.SmoothPlastic,Anchored=true},parent)
end
local nop=function() return nil end
local kit={new=new,block=block,tween=nop,sound=nop,flash=nop,shockRing=nop,burst=nop,smokePuff=nop,sparks=nop,anchorPart=function(p,at) return block(p,roblox.Vector3.one,roblox.CFrame.new(at)) end,
	floorUnder=nop,num=function(t) return roblox.NumberSequence.new(t[1][2]) end,seq=function(a) return roblox.NumberSequence.new(a) end,
	TEX=setmetatable({},{__index=function() return "" end}),SOUND=setmetatable({},{__index=function() return "" end}),BUILD={},
	weldAll=nop}
local FX={layers={},poses={}}
local FamilyFX=H.load("Client/FamilyFX")
FamilyFX.install(FX,kit)
local Looks=H.load("Shared/Looks")
local out={}
local function dump(name,model)
	local parts={}
	local origin=nil
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency<.95 then
			local mesh=d:FindFirstChildOfClass("SpecialMesh")
			local cf=d.CFrame
			local rx,ry,rz=cf:ToEulerAnglesXYZ()
			local okS,sh=pcall(function() return tostring(d.Shape) end)
			table.insert(parts,{class=d.ClassName,shape=if okS then sh else "Wedge",mesh=mesh and tostring(mesh.MeshType) or nil,
				size={d.Size.X,d.Size.Y,d.Size.Z},pos={cf.Position.X,cf.Position.Y,cf.Position.Z},
				r={cf.RightVector.X,cf.RightVector.Y,cf.RightVector.Z},u={cf.UpVector.X,cf.UpVector.Y,cf.UpVector.Z},b={-cf.LookVector.X,-cf.LookVector.Y,-cf.LookVector.Z},
				color={math.floor(d.Color.R*255),math.floor(d.Color.G*255),math.floor(d.Color.B*255)},material=tostring(d.Material),transparency=d.Transparency,name=d.Name})
		end
	end
	out[name]=parts
end
local want=process.args[2]
for kind,look in Looks do
	if type(look)=="table" and look.shape and FamilyFX.SHAPES[look.shape] and (not want or want==kind) then
		local ok,m=pcall(FamilyFX.SHAPES[look.shape],look)
		if ok and m then dump(kind,m) else print("skip",kind,m) end
	end
end
local HoundFX=H.load("Client/HoundFX")
for i=1,4 do local ok,m=pcall(HoundFX.build,i);if ok and m then dump("ninken"..i,m) else print("skip ninken",m) end end
fs.writeFile(process.args[1],H and require("@lune/serde").encode("json",out) or "")
local n=0 for _ in out do n+=1 end
print("dumped",n)
