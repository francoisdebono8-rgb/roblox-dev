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
	-- the cliff's four places: a funny head until the server carves the
	-- creator or a champion there (Server/ChampionCliff turns it DressOff)
	HeadSlot1=true,HeadSlot2=true,HeadSlot3=true,HeadSlot4=true,
	-- repeated, in their own frame
	HouseGable_24x20x2=true,HouseShop_24x20x2=true,HouseShop_24x20x1=true,HouseBack_22x20x2=true,HouseUchiha_26x20x2=true,
	HouseFlat_24x20x2=true,HouseFlat_22x18x3=true,WaterTank=true,TreeA=true,TreeB=true,TreeC=true,
	PaperLantern=true,LampPost=true,StoneLantern=true,Bench=true,Crate=true,Stump=true,FenceSegment=true,
	VillageWall=true,CompoundWall=true,Ladder=true,
}
-- (21/11, DEC-047) the new Konoha's plan (Shared/KonohaLayout): every
-- building and backdrop of the plan is dressed by the model of its name (the
-- ANIMATEUR's, tools/blender/konoha_houses.py and konoha_models.py).
do
	local Layout=require(game:GetService("ReplicatedStorage").NinjaDuel.KonohaLayout)
	for _,b in Layout.Buildings do HubDress.NAMES[b[1]]=true end
	for _,o in Layout.Outside do HubDress.NAMES[o[1]]=true end
end
-- A wall's segment is 10 studs long (along its z).
HubDress.SEGMENT=10
-- (15/11) a hidden part -> the mesh copies standing for it: the duel camera
-- fades what it really sees (Client/Camera.fadeHit).
HubDress.copiesOf=setmetatable({},{__mode="k"})

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
function HubDress.spots(unit,fallback)
	local at=unit:GetAttribute(if fallback then "DressFallbackAt" else "DressAt")
	local scale=unit:GetAttribute(if fallback then "DressFallbackScale" else "DressScale") or Vector3.one
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
function HubDress.dress(unit,pieces,holder,fallback)
	local made={}
	for _,spot in HubDress.spots(unit,fallback) do
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
		HubDress.solidify(unit,made)
		for _,part in HubDress.parts(unit) do
			part.Transparency=1;HubDress.copiesOf[part]=made
			-- (15/11) a prop broken in a street duel: its model goes, the
			-- broken piece the server left (a stump, a mound) shows; put back
			-- after the duel, the model returns
			if part:GetAttribute("WorldBreakable") then
				pcall(function()
					part:GetAttributeChangedSignal("WorldState"):Connect(function() HubDress.broken(part,made) end)
				end)
			end
		end
	end
	return made
end

-- (23/11, François: « les murs sont intangibles, comme les toits »; seen in
-- Studio: a shop's front 3 to 6 studs out of its box, roofs, tanks and eaves
-- drawn over it) A building is solid where it is drawn: its model's pieces
-- collide and are seen by the rays (the run up a wall finds the front he
-- stands against), and the plain box under them no longer stops him where
-- nothing is drawn. Only for a building or a wall (a unit with a part to run
-- on, NinjaWall): the props keep their pieces (they break in a duel).
-- On this client only: the server's boxes stay for the duels it runs.
HubDress.WALL_HEIGHT,HubDress.WALL_WIDTH=7,4
function HubDress.solid(unit)
	for _,part in HubDress.parts(unit) do
		if part:GetAttribute("NinjaWall") and not part:GetAttribute("WorldBreakable") then return part end
	end
	return nil
end
function HubDress.solidify(unit,made)
	-- (23/11) a house with its own solids from the server (Server/Hub, the
	-- ANIMATEUR's Shared/HubSolids): they stop the body; the copies stay light
	if unit:GetAttribute("Solids") then return false end
	local wall=HubDress.solid(unit)
	if not wall then return false end
	local noClimb=wall:GetAttribute("NinjaNoClimb")
	for _,p in made do
		p.CanCollide=true;p.CanQuery=true
		local size=p.Size
		if size.Y>=HubDress.WALL_HEIGHT and math.max(size.X,size.Z)>=HubDress.WALL_WIDTH then
			p:SetAttribute("NinjaWall",true)
			if noClimb then p:SetAttribute("NinjaNoClimb",true) end
		end
	end
	for _,part in HubDress.parts(unit) do part.CanCollide=false end
	return true
end

-- A dressed prop's piece broken (or put back): its model hides (or shows).
function HubDress.broken(part,made)
	local broken=part:GetAttribute("WorldState")=="Broken"
	part.Transparency=if broken then 0 else 1
	for _,copy in made do
		if copy.Parent then
			if broken then
				if copy:GetAttribute("DressTransparency")==nil then copy:SetAttribute("DressTransparency",copy.Transparency) end
				copy.Transparency=1
			else
				copy.Transparency=copy:GetAttribute("DressTransparency") or 0
			end
		end
	end
	return broken
end

-- A unit the server turned DressOff (a cliff place where a face is carved):
-- its mesh copies go, its parts are the server's (hidden there). Turned
-- back on, it is dressed again. Returns true when the unit is dressed now.
function HubDress.sync(unit,kit,holder,done)
	local off=unit:GetAttribute("DressOff")==true
	if off then
		if done[unit] then
			for _,p in done[unit] do p:Destroy() end
			done[unit]=nil
			for _,part in HubDress.parts(unit) do HubDress.copiesOf[part]=nil end
		end
		return false
	end
	if done[unit] then return true end
	local name=unit:GetAttribute("Dress")
	-- (21/11, DEC-047) a house of the new Konoha's plan whose model does not
	-- exist yet wears the old village's house of its kind (DressFallback)
	local fallback=false
	if not kit.has(name) then
		name=unit:GetAttribute("DressFallback")
		if not name or not kit.has(name) then return false end
		fallback=true
	end
	done[unit]=HubDress.dress(unit,kit.pieces(name),holder,fallback)
	return true
end

-- Dresses every unit of the village whose mesh is ready. `kit`: MeshKit (or
-- a stand-in with has/pieces). Returns how many units were dressed now.
-- `watch(unit)` (optional): called once per unit, to follow its DressOff.
function HubDress.apply(root,kit,holder,done,watch)
	done=done or {}
	local count=0
	for _,unit in HubDress.units(root) do
		if watch then watch(unit) end
		if done[unit] then continue end
		if HubDress.sync(unit,kit,holder,done) then count+=1 end
	end
	return count
end

-- In the game: waits for the village, then dresses it as the meshes come
-- (MeshKit builds them in the background after the weapons).
function HubDress.start()
	local MeshKit=require(script.Parent.MeshKit)
	local hasAny=false
	for name in HubDress.NAMES do if MeshKit.Data[name] then hasAny=true;break end end
	if not hasAny then HubDress.dressed=true return end
	task.spawn(function()
		local root=workspace:WaitForChild("NinjaDuelHub",120)
		if not root then HubDress.dressed=true return end
		local holder=Instance.new("Folder");holder.Name="NinjaDuelHubDress";holder.Parent=workspace
		local done=setmetatable({},{__mode="k"})
		local watched=setmetatable({},{__mode="k"})
		-- the cliff's places change while the game runs (a new champion)
		local function watch(unit)
			if watched[unit] or unit:GetAttribute("HeadSlot")==nil then return end
			watched[unit]=true
			unit:GetAttributeChangedSignal("DressOff"):Connect(function() HubDress.sync(unit,MeshKit,holder,done) end)
		end
		-- (14/11, François: « les textures n'apparaissent pas au même moment »)
		-- The village is dressed in one go once every model is built: it was
		-- dressed once a second as they came, in waves for 12 s.
		while root.Parent and MeshKit.state~="ready" and MeshKit.state~="failed" do task.wait(.1) end
		if root.Parent then HubDress.apply(root,MeshKit,holder,done,watch) end
		HubDress.dressed=true
	end)
end

return HubDress
