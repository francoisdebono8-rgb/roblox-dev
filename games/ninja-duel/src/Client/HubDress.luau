-- Konoha dressed in its Blender models (14/11, user: « les models 3d peuvent
-- être faits par l'animateur »; docs/systems/HUB_DRESS.md). Server/Hub builds
-- the village from parts and tags each building or prop as a unit: a Model
-- with the name of its modelled mesh (Dress) and where it goes (DressAt, a
-- CFrame; DressScale; DressLength for a wall, repeated in segments of 10).
-- Once Client/MeshKit has built a mesh, this puts it in place on this client
-- and hides the unit's parts: they stay solid (the walk, the rooftops, the
-- stairs) and come back if the mesh is missing. A part tagged Keep (a sign
-- and its text, the hall's floor) stays visible; a unit inside a unit (a
-- house's lantern) is dressed on its own.
-- Presentation only, on each client: nothing here reaches the server.
local HubDress={}

-- Every name of the contract (docs/systems/HUB_DRESS.md): the ANIMATOR's
-- tools/blender/konoha_models.py exports these, Server/Hub tags with them.
HubDress.NAMES={
	-- unique, modelled where they stand (their origin is the village's)
	KonohaGate=true,GateBooth=true,Ichiraku=true,ExamHall=true,TrainingProps=true,MemorialStone=true,
	HyugaCompound=true,UchihaGate=true,UchihaPier=true,NakaShrine=true,Torii=true,HokageCliff=true,FacesTerrace=true,
	-- repeated, in their own frame
	HouseGable_24x20x2=true,HouseShop_24x20x2=true,HouseShop_24x20x1=true,HouseBack_22x20x2=true,HouseUchiha_26x20x2=true,
	HouseFlat_24x20x2=true,HouseFlat_22x18x3=true,WaterTank=true,TreeA=true,TreeB=true,TreeC=true,
	PaperLantern=true,LampPost=true,StoneLantern=true,Bench=true,Crate=true,Stump=true,FenceSegment=true,
	VillageWall=true,CompoundWall=true,Ladder=true,
}
-- A wall's segment is 10 studs long (along its z).
HubDress.SEGMENT=10

-- The units under `root` (a unit inside a unit too).
function HubDress.units(root)
	local list={}
	for _,d in root:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("Dress") then table.insert(list,d) end
	end
	return list
end

-- The unit's own parts: not a Keep one, not one inside another unit.
function HubDress.parts(unit)
	local list={}
	local function walk(node)
		for _,child in node:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("Dress") then continue end
			if child:IsA("BasePart") and not child:GetAttribute("Keep") then table.insert(list,child) end
			walk(child)
		end
	end
	walk(unit)
	return list
end

-- Where each copy of the mesh goes: a list of {at=CFrame, scale=Vector3}.
-- A wall is cut into whole segments of about 10 that fill its length.
function HubDress.spots(unit)
	local at=unit:GetAttribute("DressAt")
	local scale=unit:GetAttribute("DressScale") or Vector3.one
	local length=unit:GetAttribute("DressLength")
	if typeof(at)~="CFrame" then return {} end
	if not length then return {{at=at,scale=scale}} end
	local n=math.max(1,math.round(length/HubDress.SEGMENT))
	local each=length/n
	local list={}
	for i=1,n do
		local z=-length/2+each*(i-.5)
		table.insert(list,{at=at*CFrame.new(0,0,z),scale=Vector3.new(scale.X,scale.Y,scale.Z*each/HubDress.SEGMENT)})
	end
	return list
end

-- Puts the mesh `pieces` (MeshKit.pieces: {part, o}) at every spot of the
-- unit, in `holder`; hides the unit's parts. Returns the copies.
function HubDress.dress(unit,pieces,holder)
	local made={}
	for _,spot in HubDress.spots(unit) do
		for _,entry in pieces do
			local p=entry.part:Clone()
			local s=spot.scale
			p.Size=entry.part.Size*s
			p.CFrame=spot.at*CFrame.new(entry.o*s)
			p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
			p.CastShadow=true
			p.Parent=holder
			table.insert(made,p)
		end
	end
	if #made>0 then
		for _,part in HubDress.parts(unit) do part.Transparency=1 end
	end
	return made
end

-- Dresses every unit of the village whose mesh is ready. `kit`: MeshKit (or
-- a stand-in with has/pieces). Returns how many units were dressed now.
function HubDress.apply(root,kit,holder,done)
	done=done or {}
	local count=0
	for _,unit in HubDress.units(root) do
		if done[unit] then continue end
		local name=unit:GetAttribute("Dress")
		if kit.has(name) then
			local made=HubDress.dress(unit,kit.pieces(name),holder)
			done[unit]=made
			count+=1
		end
	end
	return count
end

-- In the game: waits for the village, then dresses it as the meshes come
-- (MeshKit builds them in the background after the weapons).
function HubDress.start()
	local MeshKit=require(script.Parent.MeshKit)
	local hasAny=false
	for name in HubDress.NAMES do if MeshKit.Data[name] then hasAny=true;break end end
	if not hasAny then return end
	task.spawn(function()
		local root=workspace:WaitForChild("NinjaDuelHub",120)
		if not root then return end
		local holder=Instance.new("Folder");holder.Name="NinjaDuelHubDress";holder.Parent=workspace
		local done=setmetatable({},{__mode="k"})
		while root.Parent do
			HubDress.apply(root,MeshKit,holder,done)
			if MeshKit.state=="ready" or MeshKit.state=="failed" then
				HubDress.apply(root,MeshKit,holder,done)
				break
			end
			task.wait(1)
		end
	end)
end

return HubDress
