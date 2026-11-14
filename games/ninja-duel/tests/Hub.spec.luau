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
	folder=Hub.build(root)
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
test("the village is cut into units: every name in the contract, every contract name used, signs kept",function()
	local used={}
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
	assert((first.CFrame.Position-(at*CFrame.new(0,8,0)).Position).Magnitude<1e-3 and first.Anchored and not first.CanCollide,"misplaced")
	-- a house facing -x turns round (the rooftops) — undressed here, its parts still show
	for _,u in HubDress.units(folder) do
		if u:GetAttribute("Dress")=="HouseFlat_24x20x2" and u.Name=="Rooftop" then
			assert(not done[u] and u:FindFirstChild("Walls").Transparency==0,"an undressed house was hidden")
			local look=u:GetAttribute("DressAt").LookVector
			assert(math.abs(look.Z-1)<1e-4,"a house facing -x is not turned round")
		end
	end
	-- the village wall, 268 long: 27 segments of ~10, each stretched a little
	for _,u in HubDress.units(folder) do
		if u:GetAttribute("Dress")=="VillageWall" then
			local spots=HubDress.spots(u)
			assert(#spots==27 and math.abs(spots[1].scale.Z-268/27/10)<1e-6,"wall segments: "..#spots)
			assert(#done[u]==27*2,"wall copies")
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
	assert(t.line.Text==Text.upper(Fighters.Leaf.Name).."  •  MASTERY 120","the line: "..t.line.Text)
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
			local z=at.Position.Z-HubMap.Origin.Z
			local lane=if math.abs(z-56)<math.abs(z-150) then 56 else 150
			local toward=if lane>z then 1 else -1
			assert(math.abs(at.RightVector.Z-toward)<1e-3,string.format("a house at z %.0f turns its back to its lane",z))
		end
	end
	assert(n>=30,"quarter houses: "..n)
	assert(HubMap.placeAt(HubMap.Origin+Vector3.new(160,0,103)).id=="Market","the market is not named")
	assert(HubMap.placeAt(HubMap.Origin+Vector3.new(-170,0,150)).id=="Residences","the residences are not named")
end)

print(string.format("NinjaDuel hub Konoha (DEC-038): %d PASS",passed))
