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

print(string.format("NinjaDuel hub Konoha (DEC-038): %d PASS",passed))
