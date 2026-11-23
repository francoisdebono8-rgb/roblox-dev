-- Konoha, the hub (13/11, DEC-038): the map's places and the masters at home,
-- the village built from parts (the gate, the street, the hall, the districts),
-- every master standing on solid ground and out of the walls, the prompts the
-- client answers. Headless (Lune's Roblox instances); the look and the walk
-- are Studio checks.
local H=require("./Harness")
local roblox=require("@lune/roblox")
H.envBase.Instance=roblox.Instance
-- (the village's signs are SurfaceGuis: real UI datatypes)
H.envBase.UDim2=roblox.UDim2;H.envBase.UDim=roblox.UDim;H.envBase.Vector2=roblox.Vector2
local Instance=roblox.Instance
local Vector3=roblox.Vector3
local CFrame=roblox.CFrame
local HubMap=H.load("Shared/HubMap")
local BetaRoster=H.load("Shared/BetaRoster")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn)
	if ok then passed+=1;print("PASS "..name) else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end

test("the map: every kit of the beta has its master at home, inside the village; the spawns and places too",function()
	for _,id in BetaRoster do
		local spot=HubMap.Masters[id]
		assert(spot and spot.place and #spot.line>20,id.." has no home")
		assert(HubMap.inside(spot.at),id.." stands outside the village")
		assert(spot.face.Magnitude>.5,id.." faces nowhere")
	end
	for name,spot in HubMap.Spawns do assert(HubMap.inside(spot.at),"spawn "..name) end
	assert(HubMap.inside(HubMap.Proctor.at),"the proctor")
	local gate=HubMap.placeAt(HubMap.Origin+HubMap.Spawns.gate.at)
	assert(gate and gate.id=="Gate","the gate is not where the player arrives: "..tostring(gate and gate.id))
	assert(HubMap.placeAt(HubMap.Origin+HubMap.Masters.Legion.at).id=="Ichiraku","Naruto is not at Ichiraku")
	-- Far from every duel lane (Matches.laneOrigin: x = (lane-1)*520, z = 0).
	assert(math.abs(HubMap.Origin.Z)>=1500,"the village sits on the duel lanes")
end)

local Hub=H.load("Server/Hub")
local folder
test("the village is built: gate, street and Ichiraku, the rooftops, the hall, the districts, the faces",function()
	local root=Instance.new("Folder")
	-- the old village (Config.Hub.Layout "classic", the step back): its own
	-- tests below; the plan's village has its own (DEC-042)
	local HubConfig=H.load("Shared/Config").Hub
	local mode=HubConfig.Layout
	HubConfig.Layout="classic"
	folder=Hub.build(root)
	HubConfig.Layout=mode
	assert(folder and folder.Parent==root and Hub.built,"not built")
	local count,collide=0,0
	for _,d in folder:GetDescendants() do
		if d:IsA("BasePart") then count+=1;if d.CanCollide then collide+=1 end end
	end
	print(string.format("  %d parts (%d solid)",count,collide))
	assert(count>400 and count<5000,"parts: "..count)
	for _,name in {"HubSpawn","Ichiraku","ExamHall","HyugaHouse","NakaShrine","Rooftop","Ladder"} do
		assert(folder:FindFirstChild(name,true),name.." missing")
	end
	local spawn=folder:FindFirstChild("HubSpawn")
	assert(spawn:IsA("SpawnLocation") and spawn.Neutral and spawn.Transparency==1,"the spawn at the gate")
end)

-- Axis-aligned parts only (the floors, walls, posts): a rotated roof is skipped.
local function aligned(p)
	local cf=p.CFrame
	return (cf.LookVector-Vector3.new(0,0,-1)).Magnitude<1e-4 and (cf.UpVector-Vector3.new(0,1,0)).Magnitude<1e-4
end
local function boxContains(p,point,grow)
	local d=point-p.CFrame.Position
	local s=p.Size/2+Vector3.new(grow,grow,grow)
	return math.abs(d.X)<=s.X and math.abs(d.Y)<=s.Y and math.abs(d.Z)<=s.Z
end
test("the Uchiha lake has its water in its hole, at the village's scale (19/11: swimming came back)",function()
	-- (SyphoDev map check: the water body is where the map says it is.) Terrain is
	-- not a part: scaling the village left the water behind, under the grass.
	local bed=folder:FindFirstChild("LakeBed")
	assert(bed and Hub.lake,"no lake: "..tostring(bed).." "..tostring(Hub.lake))
	local w,s=Hub.lake.cf.Position,Hub.lake.size
	local function near(a,b) return math.abs(a-b)<1e-3 end
	local b=bed.CFrame.Position
	assert(near(w.X,b.X) and near(w.Z,b.Z),"the water is not over its bed: "..tostring(w).." vs "..tostring(b))
	assert(near(s.X,bed.Size.X) and near(s.Z,bed.Size.Z),"the water does not fill the hole: "..tostring(s).." vs "..tostring(bed.Size))
	assert(w.Y-s.Y/2>=b.Y+bed.Size.Y/2-1e-3,"the water goes through the lake bed")
	assert(s.Y>=3.5,"too shallow to swim: "..s.Y)
	-- No grass over the water: every Ground slab stays out of the lake's box.
	for _,g in folder:GetChildren() do
		if g.Name=="Ground" then
			local p,gs=g.CFrame.Position,g.Size
			local apartX=math.abs(p.X-w.X)>=(gs.X+s.X)/2-1e-3
			local apartZ=math.abs(p.Z-w.Z)>=(gs.Z+s.Z)/2-1e-3
			assert(apartX or apartZ,"a ground slab covers the lake")
		end
	end
	assert(w.Y+s.Y/2<=HubMap.Origin.Y,"the water rises over the ground")
end)

test("each master and the proctor stand on solid ground, out of every wall",function()
	local spots={Proctor=HubMap.Proctor}
	for id,spot in HubMap.Masters do spots[id]=spot end
	for id,spot in spots do
		local at=HubMap.Origin+spot.at
		local floor=false
		for _,p in folder:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide and p.Transparency<1 and aligned(p) then
				local top=p.CFrame.Position.Y+p.Size.Y/2
				local d=at-p.CFrame.Position
				if math.abs(d.X)<=p.Size.X/2 and math.abs(d.Z)<=p.Size.Z/2 and math.abs(top-at.Y)<=.35 then floor=true end
				-- His body (2.5 studs up from his feet) is in no solid part.
				assert(not boxContains(p,at+Vector3.new(0,2.5,0),-.2),id.." stands inside "..p.Name)
			end
		end
		assert(floor,id.." stands on nothing at "..tostring(spot.at))
	end
end)

test("the masters take their portraits, each with the prompt the client answers",function()
	local source=Instance.new("Folder")
	for _,id in BetaRoster do
		local model=Instance.new("Model");model.Name=id;model:SetAttribute("Fighter",id)
		local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1);root.Anchored=true;root.Parent=model
		local head=Instance.new("Part");head.Name="Head";head.Size=Vector3.new(1,1,1);head.CFrame=roblox.CFrame.new(0,1.5,0);head.Parent=model
		model.PrimaryPart=root
		model.Parent=source
	end
	Hub.placeMasters(source)
	local holder=folder:FindFirstChild("Masters")
	assert(holder,"no masters")
	for _,id in BetaRoster do
		local model=holder:FindFirstChild(id)
		assert(model and model:GetAttribute("NinjaMaster")==id,id.." is not home")
		local prompt=model:FindFirstChild("Talk",true)
		assert(prompt and prompt:IsA("ProximityPrompt") and prompt:GetAttribute("NinjaMaster")==id,id.."'s prompt")
		local spot=HubMap.Masters[id]
		local feet=model.PrimaryPart.CFrame.Position-Vector3.new(0,3,0)
		assert((feet-(HubMap.Origin+spot.at)).Magnitude<.05,id.." is not on his spot: "..tostring(feet))
		if spot.at.Y>4 then assert(prompt.MaxActivationDistance>=20,id.." is out of reach up there") end
	end
	-- (14/11) the dummy of Training Ground Three: E trains (Client/HubClient)
	local training=holder:FindFirstChild("Training")
	assert(training and training:GetAttribute("NinjaTrain")==true,"no training spot")
	local prompt=training:FindFirstChild("Talk",true)
	assert(prompt and prompt:GetAttribute("NinjaTrain")==true and prompt.ActionText=="TRAIN","the training prompt")
	assert(HubMap.placeAt(training.PrimaryPart.CFrame.Position).id=="Training","the dummy is not on the training ground")
	-- (14/11) the market's counter: the looks for Ryō
	local market=holder:FindFirstChild("Market")
	assert(market and market:GetAttribute("NinjaMarket")==true,"no market counter")
	local mp=market:FindFirstChild("Talk",true)
	assert(mp and mp:GetAttribute("NinjaMarket")==true,"the market's prompt")
	assert(HubMap.placeAt(market.PrimaryPart.CFrame.Position).id=="Market","the counter is not in the market")
end)

-- (14/11, audit in Studio: Roblox's paths from the gate end where a player
-- walks up to each master; Naruto, Gaara and Kakashi showed him their side or
-- their back) Each master faces the way he is walked up to.
test("the masters face the player who walks up to them",function()
	local arrive={Legion=Vector3.new(-7,0,126),Sand=Vector3.new(-47,0,-59),Copycat=Vector3.new(-149,0,83),Leaf=Vector3.new(-102,0,38)}
	for id,from in arrive do
		-- (15/11) measured at the village's first scale
		from*=(HubMap.Scale or 1)
		local spot=HubMap.Masters[id]
		local toward=Vector3.new(from.X-spot.at.X,0,from.Z-spot.at.Z).Unit
		local face=Vector3.new(spot.face.X,0,spot.face.Z).Unit
		local off=math.deg(math.acos(math.clamp(toward:Dot(face),-1,1)))
		assert(off<15,id.." looks "..math.floor(off).." degrees away from the player walking up")
	end
end)

test("a duel takes the walker away; a table player (the suites) is never spawned",function()
	local fake={UserId=7,Name="P7"}
	Hub.enter(fake,"gate")
	Hub.leave(fake)
	Hub.forget(fake)
	local Matches=H.load("Server/Matches")
	local Config=H.load("Shared/Config")
	local was=Config.Hub.Enabled
	Config.Hub.Enabled=true
	assert(Matches.hubOn(),"the village is built and on, yet off")
	Config.Hub.Enabled=false
	assert(not Matches.hubOn())
	Config.Hub.Enabled=was
end)

-- (14/11) The Blender dressing (docs/systems/HUB_DRESS.md): the ANIMATOR models,
-- Client/HubDress swaps each unit's parts for its mesh on the client.
local HubDress=H.load("Client/HubDress")
-- (21/11, étape 3 DEV 3, DEC-047) the new Konoha, built from the plan
local Layout=H.load("Shared/KonohaLayout")
local Vector2=roblox.Vector2
local Config=H.load("Shared/Config")
local layoutFolder
test("the new Konoha (DEC-042): every building of the plan, out of the open places, walls to run on, the masters on solid ground",function()
	local classic,builtWas=Hub.folder,Hub.built
	Hub.folder=nil;Hub.built=false
	local mode=Config.Hub.Layout
	Config.Hub.Layout="konoha2"
	local root=Instance.new("Folder")
	layoutFolder=Hub.build(root)
	Config.Hub.Layout=mode
	Hub.folder,Hub.built=classic,builtWas
	-- the Naka river: its bed under the ground, the water filled into it
	local bed=layoutFolder:FindFirstChild("LakeBed")
	assert(bed and bed.CFrame.Position.Y+bed.Size.Y/2<HubMap.Origin.Y-4,"no river bed under the ground")
	assert(layoutFolder:GetAttribute("Layout")=="konoha2","not the plan's village")
	local buildings=layoutFolder:FindFirstChild("Buildings")
	assert(buildings and #buildings:GetChildren()==#Layout.Buildings,"buildings: "..(buildings and #buildings:GetChildren() or 0).." of "..#Layout.Buildings)
	-- nothing of the plan stands in a place kept open (duels, squares)
	for _,b in Layout.Buildings do
		-- (the hall's own walls frame its open floor)
		if string.sub(b[1],1,9)=="exam_hall" then continue end
		for _,o in Layout.Open do
			local inside=if o.shape=="circle" then (Vector2.new(b[2],b[3])-o.at).Magnitude<o.radius else (b[2]>o.x0 and b[2]<o.x1 and b[3]>o.z0 and b[3]<o.z1)
			assert(not inside,tostring(b[9] or b[1]).." at "..b[2]..","..b[3].." stands in "..o.why)
		end
	end
	-- the houses' stand-ins: the old house of their kind, at the lot, scaled with the village
	local houses,walls=0,0
	for _,m in buildings:GetChildren() do
		if Hub.LAYOUT_STANDIN[m:GetAttribute("LayoutModel")] then
			houses+=1
			assert(typeof(m:GetAttribute("DressFallbackAt"))=="CFrame" and typeof(m:GetAttribute("DressFallbackScale"))=="Vector3","a house without its stand-in")
		end
	end
	for _,d in layoutFolder:GetDescendants() do if d:IsA("BasePart") and d:GetAttribute("NinjaWall") then walls+=1 end end
	print(string.format("  %d buildings, %d houses, %d walls to run on",#buildings:GetChildren(),houses,walls))
	assert(houses>=150 and walls>=houses,"houses "..houses..", walls "..walls)
	assert(layoutFolder:FindFirstChild("HubSpawn",true),"no spawn at the gate")
	-- every master and the proctor stand on solid ground, out of every wall
	local spots={Proctor=HubMap.Proctor}
	for id,spot in HubMap.Masters do spots[id]=spot end
	for id,spot in spots do
		local at=HubMap.Origin+spot.at
		local floor=false
		for _,p in layoutFolder:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide and p.Transparency<1 and aligned(p) then
				local top=p.CFrame.Position.Y+p.Size.Y/2
				local d=at-p.CFrame.Position
				if math.abs(d.X)<=p.Size.X/2 and math.abs(d.Z)<=p.Size.Z/2 and math.abs(top-at.Y)<=.35 then floor=true end
				assert(not boxContains(p,at+Vector3.new(0,2.5,0),-.2),id.." stands inside "..p:GetFullName())
			end
		end
		assert(floor,id.." stands on nothing at "..tostring(spot.at))
	end
	-- every place of a 1v1 in the street (a master's, the street's own): its
	-- centre and both starts are open ground in the plan's village too
	local solids={}
	for _,d in layoutFolder:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide and d.Size.Y>=2 and d.Transparency<1 then table.insert(solids,d) end
	end
	for _,street in HubMap.Streets do
		local centre=HubMap.Origin+street.at+Vector3.new(0,3,0)
		local axis=street.axis or Vector3.new(0,0,1)
		local half=street.start or math.min(24,street.radius*.7)
		for _,point in {centre,centre+axis*half,centre-axis*half} do
			for _,p in solids do
				local l=p.CFrame:PointToObjectSpace(point)
				assert(not (math.abs(l.X)<=p.Size.X/2+1.5 and math.abs(l.Y)<=p.Size.Y/2 and math.abs(l.Z)<=p.Size.Z/2+1.5),
					string.format("%s: a fighter starts inside %s",street.key,p:GetFullName()))
			end
		end
	end
end)

test("the village is cut into units: every name in the contract, every contract name used, signs kept",function()
	local used={}
	for _,u in HubDress.units(layoutFolder) do
		local name=u:GetAttribute("Dress")
		assert(HubDress.NAMES[name],u:GetFullName().." is dressed as "..tostring(name).." (not in the contract)")
		used[name]=(used[name] or 0)+1
	end
	for _,u in HubDress.units(folder) do
		local name=u:GetAttribute("Dress")
		assert(HubDress.NAMES[name],u:GetFullName().." is dressed as "..tostring(name).." (not in the contract)")
		assert(typeof(u:GetAttribute("DressAt"))=="CFrame",u.Name.." has no place")
		used[name]=(used[name] or 0)+1
	end
	for name in HubDress.NAMES do assert(used[name],name.." is in the contract but tags nothing") end
	assert(used.PaperLantern>=20 and used.TreeA+used.TreeB+used.TreeC>=60 and used.HouseFlat_24x20x2>=6,"counts")
	-- the contract's doc names them all
	local doc=require("@lune/fs").readFile("docs/systems/HUB_DRESS.md")
	for name in HubDress.NAMES do assert(string.find(doc,name,1,true),name.." missing from HUB_DRESS.md") end
	-- what must stay seen: the signs' text and the hall's floor
	for _,name in {"GatePlate","HallPlate","IchirakuSign","HallFloor"} do
		local p=folder:FindFirstChild(name,true)
		assert(p and p:GetAttribute("Keep"),name.." would be hidden")
	end
	-- the walk's solids are all inside a unit or ground (nothing solid is
	-- left out of the dressing but the ground, paths and edges)
	local loose={}
	for _,p in folder:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency<1 then
			local inUnit=false
			local node=p.Parent
			while node and node~=folder do
				-- (the masters and the proctor are bodies, not the village)
				if node:GetAttribute("Dress") or node:FindFirstChildOfClass("Humanoid") or node:FindFirstChild("HumanoidRootPart") then inUnit=true;break end
				node=node.Parent
			end
			if not inUnit then loose[p.Name]=(loose[p.Name] or 0)+1 end
		end
	end
	local allowed={Ground=true,LakeBed=true,Shore=true,Street=true,Plaza=true,Path=true,Gravel=true,TrainingEarth=true,
		BoardPost=true,ExamBoard=true,Crest=true,CrestWhite=true,CrestHandle=true}
	for name,n in loose do assert(allowed[name],n.." "..name.." left out of the dressing") end
	-- every mesh the ANIMATOR exports has a place
	local data=H.load("Client/HubMeshData")
	for name in data do assert(HubDress.NAMES[name],"HubMeshData exports "..name..", which nothing tags") end
end)

test("the dresser: a unit's parts hidden (not the kept ones, not a nested unit), its mesh placed, a wall in segments",function()
	local function piece(size) local p=Instance.new("Part");p.Size=size;return p end
	local made={}
	local kit={
		has=function(name) return name=="HouseShop_24x20x2" or name=="PaperLantern" or name=="VillageWall" or name=="TreeA" end,
		pieces=function(name)
			made[name]=true
			return {{part=piece(Vector3.new(24,16,20)),o=Vector3.new(0,8,0),name="Walls"},{part=piece(Vector3.new(2,1,2)),o=Vector3.new(1,2,3),name="Trim"}}
		end,
	}
	local holder=Instance.new("Folder")
	local done={}
	local n=HubDress.apply(folder,kit,holder,done)
	assert(n>0 and #holder:GetChildren()>0,"nothing dressed")
	-- a shop on the street: its walls hidden, its sign kept, its lantern dressed on its own
	local shop
	for _,u in HubDress.units(folder) do if u:GetAttribute("Dress")=="HouseShop_24x20x2" then shop=u;break end end
	assert(shop and done[shop],"the shop was not dressed")
	assert(shop:FindFirstChild("Walls").Transparency==1,"the shop's walls still show")
	assert(shop:FindFirstChild("Walls").CanCollide,"the shop's walls lost their collision")
	assert(shop:FindFirstChild("Sign").Transparency==0,"the shop's sign was hidden")
	local lanternUnit=shop:FindFirstChild("PaperLantern")
	assert(lanternUnit and done[lanternUnit],"the shop's lantern was not dressed on its own")
	-- the copy sits at DressAt * o
	local at=shop:GetAttribute("DressAt")
	local first=done[shop][1]
	-- (15/11) at the village's scale (DressScale)
	local scale=shop:GetAttribute("DressScale") or Vector3.one
	assert((first.CFrame.Position-(at*CFrame.new(Vector3.new(0,8,0)*scale)).Position).Magnitude<1e-3 and first.Anchored and not first.CanCollide,"misplaced")
	-- a house facing -x turns round (the rooftops) — undressed here, its parts still show
	for _,u in HubDress.units(folder) do
		if u:GetAttribute("Dress")=="HouseFlat_24x20x2" and u.Name=="Rooftop" then
			assert(not done[u] and u:FindFirstChild("Walls").Transparency==0,"an undressed house was hidden")
			local look=u:GetAttribute("DressAt").LookVector
			assert(math.abs(look.Z-1)<1e-4,"a house facing -x is not turned round")
		end
	end
	-- the village wall, 268 long at the first scale: whole segments of ~10,
	-- each stretched a little (more of them at a bigger scale)
	for _,u in HubDress.units(folder) do
		if u:GetAttribute("Dress")=="VillageWall" then
			local length=u:GetAttribute("DressLength")
			assert(math.abs(length-268*(HubMap.Scale or 1))<1e-3,"the wall's length: "..length)
			local n=math.round(length/10)
			local spots=HubDress.spots(u)
			assert(#spots==n and math.abs(spots[1].scale.Z-length/n/10)<1e-4,"wall segments: "..#spots)
			assert(#done[u]==n*2,"wall copies")
			break
		end
	end
	-- a tree: scaled by its height (14) and spread (6)
	for _,u in HubDress.units(folder) do
		if u:GetAttribute("Dress")=="TreeA" then
			local s=u:GetAttribute("DressScale")
			local copy=done[u][1]
			assert((copy.Size-Vector3.new(24,16,20)*s).Magnitude<1e-3,"the tree was not scaled")
			break
		end
	end
	-- a second pass does nothing more
	assert(HubDress.apply(folder,kit,holder,done)==0,"dressed twice")
end)

-- (15/11, François: « les bâtiments n'ont pas de mur, pas de physique »,
-- « une vraie adaptation avec les dégâts dans les murs ») The village's walls
-- carry a wall run, its props break, and the duel's end puts them back.
test("a street duel and the village: walls to run on, props that break, all put back after the duel",function()
	local walls,props=0,{}
	local house
	for _,d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("NinjaWall") then walls+=1 end
		if d:IsA("BasePart") and d:GetAttribute("WorldBreakable") then table.insert(props,d) end
		if d:IsA("Model") and d:GetAttribute("Dress")=="HouseShop_24x20x2" and not house then house=d end
	end
	assert(house and house:FindFirstChild("Walls"):GetAttribute("NinjaWall"),"a house's walls are not a wall to run on")
	assert(walls>=60,"few walls to run on: "..walls)
	assert(#props>=10,"few props break: "..#props)
	for _,d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("NinjaWall") then assert(d.Size.Y>=7,"a low piece is a wall: "..d.Name) end
	end
	-- a crate broken by a duel fought next to it, then put back
	local crate
	for _,p in props do if p.Name=="Crate" then crate=p;break end end
	assert(crate,"no crate breaks")
	local WorldReaction=H.load("Server/WorldReaction")
	local stage=Instance.new("Folder")
	local pushed=0
	local c={match={folder=stage},now=0,pushImpact=function() pushed+=1 end}
	local size,cf=crate.Size,crate.CFrame
	local broken=false
	for _=1,6 do
		local r=WorldReaction.impact(c,{part=crate,position=crate.CFrame.Position,normal=Vector3.new(1,0,0),energy=40,contact="blunt",direction=Vector3.new(-1,0,0)})
		if r and r.broken then broken=true;break end
	end
	assert(broken and crate:GetAttribute("WorldState")=="Broken" and crate.Size~=size,"the crate did not break")
	assert(WorldReaction.restore(c)>=1,"nothing put back")
	assert(crate.Size==size and crate.CFrame==cf and crate:GetAttribute("WorldState")==nil,"the crate stayed broken after the duel")
	-- the stage's own pieces are the Stage's to put back, not this
	local own=Instance.new("Part");own.Material=roblox.Enum.Material.Wood;own.Size=Vector3.new(4,4,4);own.Parent=stage
	local c2={match={folder=stage},now=0,pushImpact=function() end}
	WorldReaction.impact(c2,{part=own,position=Vector3.zero,normal=Vector3.new(1,0,0),energy=40,contact="blunt"})
	assert(WorldReaction.state(c2).parts[own] and WorldReaction.state(c2).parts[own].original==nil,"the stage's pieces are kept twice")
	-- on the client: its model hides while broken, comes back after
	local copy=Instance.new("Part");copy.Transparency=.2;copy.Parent=Instance.new("Folder")
	crate:SetAttribute("WorldState","Broken")
	assert(HubDress.broken(crate,{copy}) and copy.Transparency==1 and crate.Transparency==0,"a broken crate's model still shows")
	crate:SetAttribute("WorldState",nil)
	assert(not HubDress.broken(crate,{copy}) and math.abs(copy.Transparency-.2)<1e-6 and crate.Transparency==1,"the crate's model did not come back")
end)

-- (15/11, François: « il faudrait que la caméra s'adapte avec tous les
-- bâtiments ») A duel's lens in Konoha: a house's walls stop it (it comes in
-- front and swings along), a crate fades, and with it the mesh that dresses it.
test("a duel's lens in Konoha: the houses stop it, a prop fades with its mesh, the streets' places are open",function()
	local Camera=H.load("Client/Camera")
	local was=H.workspace.FindFirstChild
	H.workspace.FindFirstChild=function(_,name) if name=="NinjaDuelHub" then return folder end return nil end
	local ok,err=pcall(function()
		local shop,crate
		for _,u in HubDress.units(folder) do
			if u:GetAttribute("Dress")=="HouseShop_24x20x2" and not shop then shop=u end
			if u:GetAttribute("Dress")=="Crate" and not crate then crate=u end
		end
		local walls=shop:FindFirstChild("Walls")
		assert(Camera.solid(walls),"a house's walls do not stop the lens")
		local box=crate:FindFirstChildWhichIsA("BasePart")
		assert(box and not Camera.solid(box),"a crate stops the lens")
		local loose=Instance.new("Part");loose.Size=Vector3.new(6,10,6)
		assert(not Camera.solid(loose),"a prop outside the village stops the lens")
		-- the crate dressed: its mesh fades with its box
		local kit={has=function(name) return name=="Crate" end,pieces=function() local p=Instance.new("Part");p.Size=Vector3.new(4,4,4);return {{part=p,o=Vector3.zero}} end}
		local holder=Instance.new("Folder")
		local done={}
		assert(HubDress.sync(crate,kit,holder,done),"the crate was not dressed")
		local faded={}
		Camera.fadeHit(box,faded)
		assert(faded[box] and faded[done[crate][1]],"the crate's mesh stays in front of the lens")
		-- turned off, the mesh is forgotten
		crate:SetAttribute("DressOff",true)
		HubDress.sync(crate,kit,holder,done)
		assert(HubDress.copiesOf[box]==nil,"a removed mesh is still faded")
		crate:SetAttribute("DressOff",nil)
	end)
	H.workspace.FindFirstChild=was
	assert(ok,err)
	-- the open places for a 1v1 in the street: each once, inside the village
	local keys={}
	for _,street in HubMap.Streets do
		assert(not keys[street.key],"twice: "..street.key);keys[street.key]=true
		assert(HubMap.inside(street.at) and street.radius>=20 and street.place,"a street place: "..street.key)
	end
	assert(#HubMap.Streets>=8 and keys.Leaf and keys.Legion and keys.GentleFist and not keys.Training,"the streets' places: "..#HubMap.Streets)
	assert(keys.Plaza and keys.MarketLane and keys.Courtyard and keys.BackAlley and keys.Residences,"the streets' own places")
	-- the back alleys: two rows of narrow houses facing their lane, a named place
	local alley=0
	for _,m in folder:GetDescendants() do
		if m:IsA("Model") and m.Name=="AlleyHouse" then
			alley+=1
			local scale=m:GetAttribute("DressScale")
			assert(scale and scale.X<(HubMap.Scale or 1) and scale.Z<(HubMap.Scale or 1),"an alley house wears a full-size model")
			local walls=m:FindFirstChild("Walls")
			assert(walls and walls:GetAttribute("NinjaWall"),"an alley house is not a wall to run on")
		end
	end
	assert(alley==12,"alley houses: "..alley)
	for _,street in HubMap.Streets do
		if street.key=="Courtyard" or street.key=="BackAlley" then
			assert(HubMap.placeAt(HubMap.Origin+street.at).id=="Alleys","the back alleys are not named")
		end
	end
	-- (15/11) each place's centre and both starts are open ground: no wall,
	-- house or prop where a fighter stands
	local solids={}
	for _,d in folder:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide and d.Size.Y>=2 then table.insert(solids,d) end
	end
	local function blocked(point)
		for _,p in solids do
			local l=p.CFrame:PointToObjectSpace(point)
			if math.abs(l.X)<=p.Size.X/2+1.5 and math.abs(l.Y)<=p.Size.Y/2 and math.abs(l.Z)<=p.Size.Z/2+1.5 then return p end
		end
		return nil
	end
	for _,street in HubMap.Streets do
		local centre=HubMap.Origin+street.at+Vector3.new(0,3,0)
		local axis=street.axis or Vector3.new(0,0,1)
		local half=street.start or math.min(24,street.radius*.7)
		for _,point in {centre,centre+axis*half,centre-axis*half} do
			local wall=blocked(point)
			assert(not wall,string.format("%s: a fighter starts inside %s",street.key,wall and wall:GetFullName() or "?"))
		end
	end
end)

-- (14/11) The players met in the village: a name tag with the kit, CHALLENGE.
test("players met in Konoha: a tag with the kit and mastery, CHALLENGE sends the lobby's challenge, none when busy",function()
	local HubPlayers=H.load("Client/HubPlayers")
	local Fighters=H.load("Shared/Fighters")
	local Text=H.load("Shared/Text")
	local Color3=roblox.Color3
	local kit={palette={paper=Color3.new(1,1,1),gold=Color3.new(1,.8,.3),muted=Color3.new(.5,.5,.5),ink=Color3.new()},
		create=function(class,parent,props) local x=Instance.new(class);for k,v in props or {} do x[k]=v end;x.Parent=parent;return x end,
		text=function(parent,str) local l=Instance.new("TextLabel");l.Text=str;l.Parent=parent;return l end,
		TITLE_FONT=roblox.Enum.Font.Bangers,BODY_FONT=roblox.Enum.Font.Gotham}
	local world=Instance.new("Folder")
	local function avatar(name)
		local m=Instance.new("Model");m.Name=name
		local head=Instance.new("Part");head.Name="Head";head.Parent=m
		local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Parent=m
		m:SetAttribute("NinjaHubBody",true);m.Parent=world
		return m
	end
	local function player(id,name)
		local attrs={}
		return {UserId=id,Name=name,DisplayName=name,Character=avatar(name),attrs=attrs,
			GetAttribute=function(_,k) return attrs[k] end}
	end
	local me,bob=player(1,"Me"),player(7,"Bob")
	me.attrs.NinjaKit="Sand"
	bob.attrs.NinjaKit="Leaf";bob.attrs.NinjaMastery=120
	local players={LocalPlayer=me,GetPlayers=function() return {me,bob} end}
	local sent={}
	local active=true
	local holder=Instance.new("Folder")
	local hp=HubPlayers.new(kit,function(payload) table.insert(sent,payload) end,function() return active end,players,holder)
	hp:refresh()
	local t=hp.tags[bob]
	assert(t and t.gui.Parent==holder and t.gui.Adornee==bob.Character.Head,"no tag over Bob")
	assert(not hp.tags[me],"a tag over himself")
	-- (DEC-043) his kit by the CM's title
	assert(t.line.Text==H.load("Shared/KitTexts").name("Leaf").."  •  MASTERY 120" and t.line.Text=="THE HARD WORKER  •  MASTERY 120","the line: "..t.line.Text)
	assert(t.prompt.Parent==bob.Character.HumanoidRootPart and t.prompt.Enabled and t.prompt.ActionText=="CHALLENGE","the prompt")
	-- E held: the lobby's challenge with his own kit, once (a second press soon after is ignored)
	assert(hp:triggered(t.prompt) and sent[1].op=="challenge" and sent[1].to==7 and sent[1].fighter=="Sand","the challenge sent")
	assert(not hp:triggered(t.prompt) and #sent==1,"challenged twice in a row")
	-- do not disturb: shown, no prompt
	bob.attrs.NinjaDnd=true;hp:refresh()
	assert(t.line.Text=="DO NOT DISTURB" and not t.prompt.Enabled,"do not disturb")
	bob.attrs.NinjaDnd=nil
	-- in a duel himself: no prompt
	active=false;hp:refresh();assert(not t.prompt.Enabled,"a prompt while in a duel")
	active=true;hp:refresh();assert(t.prompt.Enabled,"the prompt did not come back")
	-- Bob leaves the village (his duel): the tag goes
	bob.Character:SetAttribute("NinjaHubBody",nil);hp:refresh()
	assert(not hp.tags[bob] and t.gui.Parent==nil and t.prompt.Parent==nil,"the tag stayed after he left")
	-- a new avatar: a new tag
	bob.Character=avatar("Bob");hp:refresh()
	assert(hp.tags[bob] and hp.tags[bob].character==bob.Character,"no tag on his new avatar")
end)

test("the badge: his chosen kit and its mastery over his head, nothing for a kit he has not learned",function()
	local p=Instance.new("Folder") -- (an Instance with attributes, standing in for the Player)
	Hub.badge(p,{selected="Leaf",owned={Leaf=true},mastery={Leaf=320}})
	assert(p:GetAttribute("NinjaKit")=="Leaf" and p:GetAttribute("NinjaMastery")==320,"badge")
	Hub.badge(p,{selected="Sand",owned={Leaf=true},mastery={}})
	assert(p:GetAttribute("NinjaKit")==nil and p:GetAttribute("NinjaMastery")==nil,"an unlearned kit shown")
	Hub.badge(p,nil)
	assert(p:GetAttribute("NinjaKit")==nil,"the progression off")
end)

-- (14/11) the village was empty in the assembled render: two quarters of houses.
test("the quarters: houses face their lane, no two houses overlap, the market and residences are named places",function()
	local boxes={}
	for _,w in folder:GetDescendants() do
		if w:IsA("BasePart") and w.Name=="Walls" then
			local cf,size=w.CFrame,w.Size
			-- the footprint on the ground (x, z), whatever the yaw
			local hx=math.abs(cf.RightVector.X)*size.X/2+math.abs(cf.LookVector.X)*size.Z/2
			local hz=math.abs(cf.RightVector.Z)*size.X/2+math.abs(cf.LookVector.Z)*size.Z/2
			table.insert(boxes,{x=cf.Position.X,z=cf.Position.Z,hx=hx,hz=hz,name=w.Parent.Name})
		end
	end
	assert(#boxes>=55,"houses: "..#boxes)
	for i=1,#boxes do for j=i+1,#boxes do
		local a,b=boxes[i],boxes[j]
		local overlap=math.abs(a.x-b.x)<a.hx+b.hx-.5 and math.abs(a.z-b.z)<a.hz+b.hz-.5
		assert(not overlap,string.format("%s at (%.0f, %.0f) overlaps %s at (%.0f, %.0f)",a.name,a.x-HubMap.Origin.X,a.z-HubMap.Origin.Z,b.name,b.x-HubMap.Origin.X,b.z-HubMap.Origin.Z))
	end end
	-- every quarter house turns its front (its mesh's +x) to its lane
	local n=0
	for _,m in folder:GetDescendants() do
		if m:IsA("Model") and m.Name=="QuarterHouse" then
			n+=1
			local at=m:GetAttribute("DressAt")
			-- (15/11) the lanes at the village's scale
			local k=HubMap.Scale or 1
			local z=at.Position.Z-HubMap.Origin.Z
			local lane=if math.abs(z-56*k)<math.abs(z-150*k) then 56*k else 150*k
			local toward=if lane>z then 1 else -1
			assert(math.abs(at.RightVector.Z-toward)<1e-3,string.format("a house at z %.0f turns its back to its lane",z))
		end
	end
	assert(n>=30,"quarter houses: "..n)
	local k=HubMap.Scale or 1
	assert(HubMap.placeAt(HubMap.Origin+Vector3.new(160,0,103)*k).id=="Market","the market is not named")
	assert(HubMap.placeAt(HubMap.Origin+Vector3.new(-170,0,150)*k).id=="Residences","the residences are not named")
end)

-- (14/11, user: « à terme ça sera les champions, on peut mettre le dev aussi et
-- des trucs drôles pour l'instant ») the cliff's four places.
test("the cliff: the creator carved first, the last three champions next, a funny head while a place is empty",function()
	local Cliff=H.load("Server/ChampionCliff")
	-- pure rules
	local list=Cliff.push({},{id=7,name="A",at=1})
	list=Cliff.push(list,{id=8,name="B",at=2});list=Cliff.push(list,{id=9,name="C",at=3})
	list=Cliff.push(list,{id=8,name="B",at=4})
	assert(#list==3 and list[1].id==8 and list[2].id==9 and list[3].id==7,"one place each, newest first")
	list=Cliff.push(list,{id=10,name="D",at=5})
	assert(#list==3 and list[1].id==10 and list[3].id==9,"the oldest goes")
	assert(#Cliff.clean({{id="x"},{id=-1},"junk",{id=3.5},{id=4,name=string.rep("n",40)}})==1,"the store's junk kept")
	local plan=Cliff.plan(42,{{id=10},{id=8}})
	assert(plan[1]==42 and plan[2]==10 and plan[3]==8 and plan[4]==nil,"the plan")
	-- on fakes: the store, the messages, the stone heads
	local stored=nil
	local published={}
	local heads={}
	local fail={}
	local function fakeHead(id)
		if fail[id] then return nil end
		local m={attrs={},Parent=nil}
		function m:SetAttribute(k,v) self.attrs[k]=v end
		function m:PivotTo(cf) self.at=cf end
		function m:Destroy() self.destroyed=true;self.Parent=nil end
		table.insert(heads,m)
		return m
	end
	local svc={
		store={GetAsync=function() return stored end,UpdateAsync=function(_,_,fn) stored=fn(stored) end},
		messaging={PublishAsync=function(_,topic,data) table.insert(published,{topic=topic,data=data}) end,SubscribeAsync=function() end},
		devId=function() return 42 end,head=fakeHead,spawn=function(fn,...) fn(...) end,now=function() return 100 end,
	}
	local cliff=Cliff.new(folder,svc):run()
	local function slot(k) return cliff:slotUnit(k) end
	local function face(k) return slot(k):FindFirstChild("Face") end
	assert(cliff.carved[1] and cliff.carved[1].model and cliff.carved[1].model.attrs.UserId==42,"the creator is not carved")
	assert(cliff.carved[1].model.Parent==cliff.holder,"his head is not on the cliff")
	local at=cliff.carved[1].model.at
	assert((at.Position-(HubMap.Origin+HubMap.Heads[1]-Vector3.new(0,0,Cliff.SINK))).Magnitude<1e-3 and at.LookVector.Z>.99,"his head is misplaced or faces the cliff")
	assert(slot(1):GetAttribute("DressOff")==true and face(1).Transparency==1 and face(1).CanCollide,"place 1 still shows its funny head")
	for k=2,4 do assert(not slot(k):GetAttribute("DressOff") and face(k).Transparency==0,"place "..k.." lost its funny head") end
	-- a champion: his face at once, the store and the other servers told
	cliff:crown({UserId=7,Name="Seven"})
	assert(cliff.carved[2].model.attrs.UserId==7 and slot(2):GetAttribute("DressOff"),"the champion is not carved")
	assert(stored and stored[1].id==7 and published[1].topic==Cliff.TOPIC and published[1].data.id==7,"store / message")
	-- three more: the newest first, the oldest goes, his stone head with him
	local seven=cliff.carved[2].model
	cliff:crown({UserId=8,Name="Eight"});cliff:crown({UserId=9,Name="Nine"});cliff:crown({UserId=10,Name="Ten"})
	assert(cliff.carved[2].id==10 and cliff.carved[3].id==9 and cliff.carved[4].id==8,"order")
	assert(seven.destroyed,"the oldest champion's head stayed")
	-- another server reads the same store
	local other=Cliff.new(Instance.new("Folder"),svc)
	other.folder=folder
	other:refresh()
	assert(#other.list==3 and other.list[1].id==10,"another server does not see the champions")
	-- an avatar that cannot load (a local file in Studio): the funny head stays
	fail[11]=true
	cliff:crown({UserId=11,Name="Eleven"})
	assert(not slot(2):GetAttribute("DressOff") and face(2).Transparency==0,"a failed avatar hid the funny head")
	-- no creator known (a local file): place 1 is a funny head
	local bare=Cliff.new(folder,{devId=function() return nil end,head=fakeHead,spawn=function(fn,...) fn(...) end,now=function() return 0 end}):run()
	assert(not bare.carved[1],"place 1 carved without a creator")
end)

test("the dresser follows a carved place: its funny head goes, and comes back",function()
	local function piece(size) local p=Instance.new("Part");p.Size=size;return p end
	local kit={has=function(name) return string.sub(name,1,8)=="HeadSlot" end,
		pieces=function() return {{part=piece(Vector3.new(26,30,8)),o=Vector3.zero,name="Head"}} end}
	local holder=Instance.new("Folder")
	local done={}
	local u
	for _,x in HubDress.units(folder) do if x:GetAttribute("HeadSlot")==3 then u=x end end
	u:SetAttribute("DressOff",nil)
	assert(HubDress.sync(u,kit,holder,done) and #done[u]==1,"the funny head is not dressed")
	u:SetAttribute("DressOff",true)
	assert(not HubDress.sync(u,kit,holder,done) and done[u]==nil and #holder:GetChildren()==0,"the funny head stayed over a carved face")
	u:SetAttribute("DressOff",nil)
	assert(HubDress.sync(u,kit,holder,done) and #holder:GetChildren()==1,"the funny head did not come back")
end)

-- (22/11) What the OUTILLEUR's prover and robot found on the plan's village,
-- and the ANIMATEUR's models on their lots.
test("the plan's village after the robots: the faces' stairs clear, a ladder up every roof too high to run to, no two tops at one height, the models fitted to their lots",function()
	local S=HubMap.Scale or 1
	local O=HubMap.Origin
	local steps,walls,ladders={}, {}, {}
	for _,d in layoutFolder:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name=="Step" then table.insert(steps,d) elseif d.Name=="Walls" then table.insert(walls,d) elseif d.Name=="Ladder" then table.insert(ladders,d) end
		end
	end
	assert(#steps==24,"the faces' stairs: "..#steps)
	-- no step inside a building
	for _,step in steps do
		for _,w in walls do
			local l=w.CFrame:PointToObjectSpace(step.CFrame.Position)
			assert(not (math.abs(l.X)<w.Size.X/2-.5 and math.abs(l.Z)<w.Size.Z/2-.5 and math.abs(l.Y)<w.Size.Y/2),"a step of the faces inside "..w.Parent.Name)
		end
	end
	-- every building taller than a run up its wall has its ladder
	local climb=36
	for _,unit in layoutFolder.Buildings:GetChildren() do
		local w=unit:FindFirstChild("Walls")
		if w and w.Size.Y>climb then assert(unit:FindFirstChild("Ladder"),unit.Name.." is too high to run up and has no ladder") end
	end
	-- no perch deck on a top that is already there
	for _,d in layoutFolder:GetDescendants() do
		if d:IsA("BasePart") and d.Name=="PerchDeck" then
			local top=d.CFrame.Position.Y+d.Size.Y/2
			for _,other in layoutFolder:GetDescendants() do
				if other~=d and other:IsA("BasePart") and other.CanCollide and other.Name~="PerchPost" then
					local l=other.CFrame:PointToObjectSpace(d.CFrame.Position)
					local otherTop=other.CFrame.Position.Y+other.Size.Y/2
					assert(not (math.abs(l.X)<other.Size.X/2 and math.abs(l.Z)<other.Size.Z/2 and math.abs(otherTop-top)<.05),"a perch deck flickers with "..other.Name)
				end
			end
		end
	end
	-- the ANIMATEUR's models on their lots: the mesh's size is the lot's
	local Ref=H.load("Shared/KonohaModelRef")
	local fitted=0
	for _,unit in layoutFolder.Buildings:GetChildren() do
		local model=unit:GetAttribute("LayoutModel")
		local ref=model and Ref[model]
		local w=unit:FindFirstChild("Walls")
		if ref and w then
			local scale=unit:GetAttribute("DressScale")
			assert(typeof(scale)=="Vector3","no fit for "..unit.Name)
			assert(math.abs(ref.w*scale.X-w.Size.X)<.05 and math.abs(ref.h*scale.Y-w.Size.Y)<.05 and math.abs(ref.d*scale.Z-w.Size.Z)<.05,unit.Name.." and its model differ")
			fitted+=1
		end
	end
	assert(fitted>=170,"models fitted: "..fitted)
	print(string.format("  %d models fitted to their lots, %d ladders",fitted,#ladders))
end)

-- (21/11, étape 3 DEV 3, DEC-047; François: « murs et toits courables
-- partout ») The village walker runs up the walls (Client/HubMove).
test("the run up a wall in the village: up it, over onto the roof, a kick off it, the tree's share",function()
	local Move=H.load("Client/HubMove")
	local m=Move.new()
	local wall={normal=Vector3.new(-1,0,0),part={}}
	assert(Move.climbStep(m,0,{wall=wall,into=1,air=false,run=false})==nil,"walking into a wall climbs it")
	assert(Move.climbStep(m,0,{wall=wall,into=.2,air=true})==nil,"along a wall climbs it")
	local v,what=Move.climbStep(m,0,{wall=wall,into=1,air=true})
	assert(what=="start" and v.Y==Move.CLIMB and v.X>0,"in the air into a wall: not up it")
	v,what=Move.climbStep(m,.5,{wall=wall,into=1,air=true})
	assert(what=="climb","the run up stopped")
	v,what=Move.climbStep(m,.6,{wall=nil,into=1,air=true})
	assert(what=="top" and v.Y==Move.MANTLE.Y and v.X>0,"no hop onto the roof at the top")
	assert(Move.climbStep(m,.7,{wall=wall,into=1,air=true})==nil,"twice up before the ground")
	-- spent: he falls, his second jump given back
	Move.landed(m);m.leapUsed=true
	assert(select(2,Move.climbStep(m,1,{wall=wall,into=1,run=true}))=="start","running into a wall: not up it")
	v,what=Move.climbStep(m,1+Move.CLIMB_TIME+.01,{wall=wall,into=1,air=true})
	assert(what=="spent" and v==nil and m.leapUsed==false,"spent: no fall, or no second jump")
	-- the tree's Wall Runner: longer
	Move.landed(m)
	Move.climbStep(m,2,{wall=wall,into=1,run=true,scale=1.4})
	assert(select(2,Move.climbStep(m,2+Move.CLIMB_TIME+.01,{wall=wall,into=1,air=true}))=="climb","the tree's share does not lengthen it")
	-- the kick: away and up; the other wall of the alley at once, the same not
	local k=Move.kick(m,3)
	assert(k and k.X<0 and k.Y==Move.KICK.Y and m.climb==nil and not m.climbUsed and not m.leapUsed,"the kick")
	assert(Move.climbStep(m,3.1,{wall=wall,into=1,air=true})==nil,"the same wall again at once")
	assert(select(2,Move.climbStep(m,3.1,{wall={normal=Vector3.new(1,0,0),part={}},into=1,air=true}))=="start","the alley's other wall")
	-- high enough for a three-storey house of the plan; the hop clears the feet
	assert(Move.CLIMB*Move.CLIMB_TIME>=21*(HubMap.Scale or 1)+2,"the run up is short of the tallest houses")
	assert(Move.MANTLE.Y^2/(2*196.2)>=3.5,"the hop at the top does not clear the feet")
end)

-- (23/11, step 4, DEC-048; François: « pas du tout ninja feel ») the walker's
-- body posed by the kit's own clips (Client/HubBody): the gait by the ground
-- covered, the wall run leaning off the wall, the bound, the roll.
test("the ninja walker: the kit's gait by the ground covered, up the wall off it, the bound, the roll",function()
	local Authored=H.load("Client/AuthoredMotion")
	local Body=H.load("Client/HubBody")
	local b=Body.new(Authored);b.kit="Sand"
	local function frame(f)
		f.now=f.now or 1;f.dt=f.dt or 1/60;f.kit="Sand";f.vy=f.vy or 0
		if f.grounded==nil then f.grounded=true end
		return Body.choose(b,f)
	end
	assert(frame({speed=0}).move=="Idle","standing")
	assert(frame({speed=12}).move=="Walk.F" and frame({speed=24}).move=="Run.F" and frame({speed=36}).move=="Sprint","the gaits")
	-- the cycle advances by the ground covered: twice the speed, twice the phase
	b.phase=0;frame({speed=66,dt=.1});local one=b.phase
	b.phase=0;frame({speed=33,dt=.1});assert(math.abs(one-2*b.phase)<1e-6 and one>0,"the gait is not tied to the ground")
	-- up the wall: the sprint, tilted
	local up=frame({speed=0,climbing=true,grounded=false,climbSpeed=38})
	assert(up.move=="Sprint" and up.tilt==1,"the run up the wall")
	-- the second jump, then the arc
	local leap=frame({speed=36,grounded=false,vy=40,leapAt=1,now=1.05})
	assert(leap.move=="AirJump","the bound: "..leap.move)
	local arc=frame({speed=36,grounded=false,vy=-30,now=2})
	assert(arc.move=="Jump.Air","the arc")
	-- a fall from high: the roll while running, the hard landing still
	frame({speed=36,grounded=false,vy=-80,now=3})
	assert(frame({speed=30,vy=0,now=3.02}).move=="Parkour.LandRoll","no roll")
	frame({speed=0,grounded=false,vy=-80,now=5})
	assert(frame({speed=0,vy=0,now=5.02}).move=="Parkour.LandHard","no hard landing")
	-- every clip it plays exists for every kit of the eight (the kit's own, or Sasuke's)
	for _,kit in H.load("Shared/BetaRoster") do
		for _,move in {"Idle","Walk.F","Run.F","Sprint","Jump.Air","AirJump","Land","Parkour.Leap","Parkour.Vault","Parkour.LandRoll","Parkour.LandHard"} do
			assert(Body.clipName(Authored,kit,move),kit.." has no "..move)
		end
	end
	-- the pose: every joint, the root tilted off the wall once eased in
	b.blendAt=-10;b.current=Body.clipName(Authored,"Sand","Sprint");b.tilt=1
	local pose=b:pose({move="Sprint",t=.1,tilt=1},10)
	local flat=Authored.sample(Body.clipName(Authored,"Sand","Sprint"),.1)
	assert(pose and pose.Root and pose.RightHip and pose.LeftKnee,"a pose")
	local lean=math.deg(math.acos(math.clamp(pose.Root.UpVector:Dot(flat.Root.UpVector),-1,1)))
	assert(lean>55,"the body is not off the wall: "..lean)
end)

-- (23/11, step 5, DEC-049) what a client writes on joints stays on it: each
-- screen poses every walker, his moves sent by their owner through the server.
test("the others see your ninja: the moves travel by the server, each screen poses every walker",function()
	local Hub=H.load("Server/Hub")
	local attrs={}
	local character={SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
	local player={Character=character}
	local buckets={}
	assert(Hub.pose(player,"climb",0,buckets) and attrs.NinjaPose=="climb" and attrs.NinjaPoseSeq==1,"up the wall")
	assert(Hub.pose(player,"leap",.1,buckets) and attrs.NinjaPose=="leap" and attrs.NinjaPoseSeq==2,"the bound")
	assert(not Hub.pose(player,"fly",.2,buckets) and not Hub.pose(player,42,.2,buckets),"only the walker's moves")
	assert(attrs.NinjaPose=="leap","a refused word changes nothing")
	local n=0
	for i=1,30 do if Hub.pose(player,"none",.3+i*.001,buckets) then n+=1 end end
	assert(n==Hub.POSE_RATE-2,"at most "..Hub.POSE_RATE.." a second: "..n)
	assert(Hub.pose(player,"none",1.5,buckets),"the next second")
	-- the screen that sees him: the move from the sequence, once
	local Body=H.load("Client/HubBody")
	local w={}
	local f=Body.crowdFacts(w,10,1/60,Vector3.new(30,0,0),true,"climb",5,"Sand")
	assert(f.climbing and not f.grounded and f.speed==30 and f.kit=="Sand","up the wall, seen")
	f=Body.crowdFacts(w,11,1/60,Vector3.new(30,40,0),false,"leap",6,"Sand")
	assert(f.leapAt==11 and not f.climbing,"the bound, seen")
	f=Body.crowdFacts(w,11.2,1/60,Vector3.new(30,20,0),false,"leap",6,"Sand")
	assert(f.leapAt==11,"the same bound is seen once")
	-- an emote: the look he owns only, its clip on the character, played standing
	local owned={EmoteWave="Emote.Wave",EmotePushUps="Emote.PushUps"}
	local function grant(_,id) return owned[id] end
	assert(Hub.pose(player,"emote:EmotePushUps",5,buckets,grant) and attrs.NinjaPose=="emote" and attrs.NinjaEmote=="Emote.PushUps","his emote")
	assert(not Hub.pose(player,"emote:EmoteMeditate",5.1,buckets,grant),"an emote he does not own")
	assert(Hub.emoteClip(player,"EmoteWave")=="Emote.Wave" and Hub.emoteClip(player,"KunaiGold")==nil,"the base wave; a kunai is no emote")
	local Authored=H.load("Client/AuthoredMotion")
	local b=Body.new(Authored);b.kit="Sand"
	local e=Body.choose(b,{now=20,dt=1/60,speed=0,vy=0,grounded=true,kit="Sand",emote="Emote.PushUps",emoteAt=19.5})
	assert(e.move=="Emote.PushUps" and math.abs(e.t-.5)<1e-6,"the emote played")
	e=Body.choose(b,{now=20,dt=1/60,speed=20,vy=0,grounded=true,kit="Sand",emote="Emote.PushUps",emoteAt=19.5})
	assert(e.move~="Emote.PushUps","he walks: the emote stops")
	local Shop=H.load("Shared/Shop")
	for _,id in {"EmoteWave","EmoteMeditate","EmotePushUps","EmoteLaugh","EmoteStretch","EmoteHandSeals"} do
		local item=Shop.item(id)
		assert(item and item.slot=="emote" and Body.clipName(Authored,"Sand",item.clip),id.." has no clip")
	end
end)

print(string.format("NinjaDuel hub Konoha (DEC-038): %d PASS",passed))
