-- The robot that walks Konoha (OUTILLEUR, 21/11; DEC-047, step 3, OUTILLEUR 1).
-- Runs as the player's client in a Play of a LAB copy of ND-JEU (Roblox_Studio
-- execute_luau, Client datamodel), never in another discussion's place. It
-- moves the avatar as the player does (Humanoid:Move each frame after the
-- default controls, the run's speed, the jump and the ninja's second jump of
-- Client/HubMove) and measures what the static prover cannot:
--   routes  the time from place to place at a run, the path's length, every
--           moment it stayed stuck (where, against what), a fall out of the map;
--   roofs   for a sample of roofs: can a player get up there (run at it, jump,
--           second jump at the top of the jump), and how long it took.
-- The places: HubMap (spawns, the proctor, the masters' homes, the welcome
-- trio, the training ground, the market) and, when the village is built from
-- it, KonohaLayout.Pois. Installed once as ReplicatedStorage.NDVillageBot
-- (tools/villagebot/studio_code.py --module), then started with a plan:
--   require(game.ReplicatedStorage.NDVillageBot).start({routes="tour",roofs=16})
-- Results: the local player's attribute NDVillageLog (JSON), NDVillageState.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local PathfindingService=game:GetService("PathfindingService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
local HubMap=require(Shared:WaitForChild("HubMap"))

local Bot={}
-- Client/HubMove's numbers (the walk, the run, the jump, the second jump).
Bot.WALK,Bot.RUN,Bot.JUMP,Bot.LEAP,Bot.LEAP_AFTER=16,36,56,54,.18
Bot.ARRIVE=4            -- studs from a place: arrived
Bot.STUCK_TIME=1.5      -- seconds without half a stud of progress: stuck
Bot.LEG_LIMIT=90        -- a leg that takes longer is given up
Bot.POI_NEAR=14         -- a point of interest of the plan (often a building): at its door

local results={routes={},roofs={},places={}}
local function note(state) pcall(function() player:SetAttribute("NDVillageState",state) end) end
local function save() pcall(function() player:SetAttribute("NDVillageLog",HttpService:JSONEncode(results)) end) end
local function r1(x) return math.floor(x*10+.5)/10 end
local function flat(v) return Vector3.new(v.X,0,v.Z) end

local function body()
	local character=player.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	return character,hum,root
end

-- The stick, the run and the jump, applied after the default controls each
-- frame (they set Move and Jump in RenderStepped; Stepped comes after).
local drive={dir=Vector3.zero,speed=Bot.RUN,jump=false,leapAt=nil,jumpedAt=0,leapUsed=false,conn=nil}
local function start()
	if drive.conn then return end
	drive.conn=RunService.Stepped:Connect(function()
		local _,hum,root=body()
		if not hum or not root then return end
		hum:Move(drive.dir,false)
		hum.WalkSpeed=drive.speed
		local state=hum:GetState()
		local grounded=state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.RunningNoPhysics
		if grounded then drive.leapUsed=false end
		if drive.jump then
			drive.jump=false
			if grounded then
				hum.Jump=true;drive.jumpedAt=os.clock()
			elseif not drive.leapUsed and os.clock()-drive.jumpedAt>Bot.LEAP_AFTER then
				-- the ninja's second jump (HubMove:jump)
				drive.leapUsed=true
				local v=root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity=Vector3.new(v.X,Bot.LEAP,v.Z)
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end)
end
local function stop()
	drive.dir=Vector3.zero
	if drive.conn then drive.conn:Disconnect();drive.conn=nil end
end

-- What the body is stuck against: the nearest solid part's name.
local function against(root)
	local params=OverlapParams.new()
	params.FilterDescendantsInstances={player.Character}
	params.FilterType=Enum.RaycastFilterType.Exclude
	local best,dist=nil,math.huge
	for _,part in workspace:GetPartBoundsInRadius(root.Position,5,params) do
		if part.CanCollide then
			local d=(part.Position-root.Position).Magnitude
			if d<dist then best,dist=part,d end
		end
	end
	return best and (best.Parent and best.Parent.Name.."/"..best.Name or best.Name) or "?"
end

-- The places to walk between (world positions, on the ground).
function Bot.places()
	local list={}
	local function add(name,rel) table.insert(list,{name=name,pos=HubMap.world(rel)}) end
	for key,spot in HubMap.Spawns or {} do add("spawn:"..key,spot.at) end
	if HubMap.Proctor then add("proctor",HubMap.Proctor.at) end
	for key,spot in HubMap.Masters or {} do add("master:"..key,spot.at) end
	if HubMap.Training then add("training",HubMap.Training.at) end
	if HubMap.Market then add("market",HubMap.Market.at) end
	-- the new village's points of interest, when it is built from its plan
	-- (Config.Hub.Layout "konoha2", 21/11: the village of the plan in every place)
	local ok,Layout=pcall(function() return require(Shared:FindFirstChild("KonohaLayout")) end)
	local built=Layout and Layout.Built
	pcall(function() built=built or require(Shared.Config).Hub.Layout=="konoha2" end)
	if ok and Layout and Layout.Pois and (Bot.pois or built) then
		for _,poi in Layout.Pois do
			if not poi.far then table.insert(list,{name="poi:"..poi.id,pos=HubMap.world(Vector3.new(poi.at.X,0,poi.at.Y)*(HubMap.Scale or 1)),near=Bot.POI_NEAR}) end
		end
	end
	return list
end

-- Walk (at a run) to a place, along a path the engine computes, the way a
-- player would steer: at the next point, a jump where the path says so or
-- where he stopped moving. Returns what the leg met.
function Bot.walkTo(goal,label,near)
	local _,hum,root=body()
	local leg={to=label,from=nil,arrived=false,t=0,length=0,stuck={},recompute=0,fell=false}
	if not root then leg.error="no body";return leg end
	leg.from=r1((root.Position-HubMap.Origin).X)..","..r1((root.Position-HubMap.Origin).Z)
	leg.straight=r1(flat(goal-root.Position).Magnitude)
	local t0=os.clock()
	local last=root.Position
	while os.clock()-t0<Bot.LEG_LIMIT and leg.recompute<4 do
		local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5.5,AgentCanJump=true,WaypointSpacing=6})
		local ok=pcall(function() path:ComputeAsync(root.Position,goal) end)
		if not ok or path.Status~=Enum.PathStatus.Success then
			leg.status=if ok then path.Status.Name else "error"
			-- no path: straight at it, as a player would try
			leg.straightOnly=true
		end
		local points=if leg.straightOnly then {{Position=goal,Action=Enum.PathWaypointAction.Walk}} else path:GetWaypoints()
		local blocked=false
		for i,wp in points do
			if i==1 and #points>1 then continue end
			local target=wp.Position
			if wp.Action==Enum.PathWaypointAction.Jump then drive.jump=true end
			local since,best=os.clock(),flat(target-root.Position).Magnitude
			local tries=0
			while flat(target-root.Position).Magnitude>(if i==#points then (near or Bot.ARRIVE) else 2.5) do
				if os.clock()-t0>Bot.LEG_LIMIT then break end
				local d=flat(target-root.Position)
				drive.dir=if d.Magnitude>.01 then d.Unit else Vector3.zero
				task.wait()
				local _,_,now=body()
				if not now then break end
				root=now
				if root.Position.Y<HubMap.Origin.Y-30 then leg.fell=true end
				leg.length+=flat(root.Position-last).Magnitude;last=root.Position
				local dist=flat(target-root.Position).Magnitude
				if dist<best-.5 then best=dist;since=os.clock()
				elseif os.clock()-since>Bot.STUCK_TIME then
					tries+=1;since=os.clock()
					drive.jump=true
					task.delay(.3,function() drive.jump=true end)
					if tries>=3 then
						local rel=root.Position-HubMap.Origin
						table.insert(leg.stuck,{at={r1(rel.X),r1(rel.Y),r1(rel.Z)},against=against(root),toward=label})
						blocked=true;break
					end
				end
			end
			if blocked or os.clock()-t0>Bot.LEG_LIMIT then break end
		end
		-- arrived: next to it, and at its height (a balcony, a shrine, the faces)
		local high=math.abs((root.Position.Y-3)-goal.Y)
		if flat(goal-root.Position).Magnitude<=(near or Bot.ARRIVE)+1 and high<=6 then leg.arrived=true;break end
		if flat(goal-root.Position).Magnitude<=(near or Bot.ARRIVE)+1 then leg.below=r1(goal.Y-(root.Position.Y-3)) end
		leg.recompute+=1
		if leg.straightOnly and not blocked then break end
	end
	drive.dir=Vector3.zero
	leg.t=r1(os.clock()-t0);leg.length=r1(leg.length)
	leg.walk=r1(leg.length/Bot.WALK)
	return leg
end

-- The roofs: a part named like a roof, wide enough to stand on, with its
-- eave (the lowest edge of its top face: what a jump must clear to land on
-- it, a sloped roof included) above 8 studs. `maxEave` keeps the roofs up to
-- that height. Returns the sample, the count of roofs and the count by band
-- of eave height.
Bot.BANDS={12,15,18,21,25}
local function faceHeights(part)
	local lo,hi=math.huge,-math.huge
	for _,sx in {-1,1} do
		for _,sz in {-1,1} do
			local y=(part.CFrame*CFrame.new(sx*part.Size.X/2,part.Size.Y/2,sz*part.Size.Z/2)).Y-HubMap.Origin.Y
			lo=math.min(lo,y);hi=math.max(hi,y)
		end
	end
	return lo,hi
end
function Bot.roofs(limit,maxEave)
	local village=workspace:FindFirstChild("NinjaDuelHub")
	local list={}
	local bands={}
	for i=1,#Bot.BANDS+1 do bands[i]=0 end
	if not village then return list,0,bands end
	local total=0
	for _,part in village:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide and string.find(string.lower(part.Name),"roof") then
			local eave,ridge=faceHeights(part)
			if eave>8 and part.Size.X>=6 and part.Size.Z>=6 then
				total+=1
				local band=#Bot.BANDS+1
				for i,cap in Bot.BANDS do if eave<=cap then band=i;break end end
				bands[band]+=1
				if not maxEave or eave<=maxEave then table.insert(list,{part=part,eave=eave,ridge=ridge}) end
			end
		end
	end
	-- an even sample, from low to high
	table.sort(list,function(a,b) return a.eave<b.eave end)
	local out={}
	local step=math.max(1,#list/(limit or 16))
	local i=1
	while i<=#list and #out<(limit or 16) do table.insert(out,list[math.floor(i)]);i+=step end
	return out,total,bands
end

-- How high the body goes, standing still: one jump, the second jump at the top
-- of the first, the second jump as early as it is allowed. The gain is the
-- root's rise, which is the feet's rise.
function Bot.jumpHeight()
	local _,hum,root=body()
	if not hum or not root then return {error="no body"} end
	local out={gravity=workspace.Gravity,jumpPower=hum.JumpPower}
	for _,mode in {"single","apex","early"} do
		drive.dir=Vector3.zero
		task.wait(.8)
		local rest=root.Position.Y
		local top=rest
		local t0=os.clock()
		drive.jump=true
		local leapt=false
		while os.clock()-t0<2.5 do
			task.wait()
			top=math.max(top,root.Position.Y)
			if mode~="single" and not leapt and os.clock()-t0>Bot.LEAP_AFTER+.02 and (mode=="early" or root.AssemblyLinearVelocity.Y<3) then
				drive.jump=true;leapt=true
			end
		end
		out[mode]=r1(top-rest)
	end
	return out
end

-- Get up on a roof as a player does. Two ways, the first the building allows:
--   wall  (the new Konoha: a building whose walls are NinjaWall) run at the
--         wall, jump into it: Client/HubMove runs him up it and hops him onto
--         the roof at its top;
--   eave  stand just outside its eave (under it, the head hits the roof), jump
--         straight up, the second jump at the top of the first, and step in
--         over the roof once the feet are above the eave.
-- Three tries from the side the path arrives at.
Bot.FEET=3.8
Bot.OUTSIDE=2.5
local rayParams
local function ray(from,along)
	if not rayParams then rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude end
	rayParams.FilterDescendantsInstances={player.Character}
	return workspace:Raycast(from,along,rayParams)
end
function Bot.climb(roof)
	local part=roof.part
	local res={name=(part.Parent and part.Parent.Name or "?").."/"..part.Name,eave=r1(roof.eave),ridge=r1(roof.ridge),reached=false,tries=0,t=0}
	local t0=os.clock()
	local centre=part.Position
	local ground=Vector3.new(centre.X,HubMap.Origin.Y,centre.Z)
	local edge=math.max(part.Size.X,part.Size.Z)/2+6
	local walls=part.Parent and part.Parent:FindFirstChild("Walls")
	res.way=if walls and walls:GetAttribute("NinjaWall") then "wall" else "eave"
	-- how far outside the roof's footprint a point is (0 or less: under it),
	-- taken at the eave's height so that a sloped roof is measured level
	local function outside(pos,level)
		local at=if level then Vector3.new(pos.X,HubMap.Origin.Y+roof.eave,pos.Z) else pos
		local l=part.CFrame:PointToObjectSpace(at)
		return math.max(math.abs(l.X)-part.Size.X/2,math.abs(l.Z)-part.Size.Z/2)
	end
	-- the closest side to where he stands
	local _,_,root=body()
	if not root then res.error="no body";return res end
	local away=flat(root.Position-ground)
	local side=if away.Magnitude>.1 then away.Unit else Vector3.new(0,0,1)
	local foot=ground+side*edge
	local leg=Bot.walkTo(foot,res.name)
	res.approach=leg.t;res.approachArrived=leg.arrived
	local top,landed=0,false
	-- the top of the feet, and whether he stood on the roof at any moment
	local function watch()
		local feet=root.Position.Y-HubMap.Origin.Y-Bot.FEET
		top=math.max(top,feet)
		local _,hum=body()
		if outside(root.Position)<=1 and feet>=roof.eave-1 and hum and hum.FloorMaterial~=Enum.Material.Air then landed=true end
	end
	for try=1,3 do
		res.tries=try
		local _,_,now=body()
		if not now then break end
		root=now
		top,landed=0,false
		if res.way=="wall" then
			-- straight at the wall; at it, the jump into it
			-- (23/11) the generated village has fences, crates and gardens before the
			-- walls: a runnable wall of any building, or no headway for half a
			-- second, and he jumps (once more if the first did not take him up)
			local t1=os.clock()
			local jumps=0
			local since,best=os.clock(),flat(centre-root.Position).Magnitude
			while os.clock()-t1<5 and not landed do
				local d=flat(centre-root.Position)
				drive.dir=if d.Magnitude>1 then d.Unit else Vector3.zero
				task.wait();watch()
				local dist=d.Magnitude
				if dist<best-.3 then best=dist;since=os.clock() end
				if jumps<2 and os.clock()-t1>(if jumps==0 then 0 else 1.2) then
					local hit=ray(root.Position,drive.dir*3.5)
					local wall=hit and (hit.Instance==walls or hit.Instance:GetAttribute("NinjaWall"))
					if wall or os.clock()-since>.5 then
						drive.jump=true;jumps+=1;since=os.clock()
						res.climbAt=res.climbAt or r1(os.clock()-t1)
						if not wall then res.blockedBy=hit and (hit.Instance.Parent.Name.."/"..hit.Instance.Name) or "nothing" end
					end
				end
			end
		else
			-- walk in to just outside the eave, or until something stops him
			local since,best=os.clock(),outside(root.Position,true)
			while os.clock()-since<.4 and outside(root.Position,true)>Bot.OUTSIDE do
				local d=flat(centre-root.Position)
				drive.dir=if d.Magnitude>1 then d.Unit else Vector3.zero
				task.wait();watch()
				local o=outside(root.Position,true)
				if o<best-.3 then best=o;since=os.clock() end
			end
			-- under the eave already: step back out from under it
			local back=os.clock()
			while os.clock()-back<1.5 and outside(root.Position,true)<Bot.OUTSIDE-.8 do
				local d=flat(root.Position-centre)
				drive.dir=if d.Magnitude>.1 then d.Unit else side
				task.wait();watch()
			end
			res.from=r1(outside(root.Position,true))
			-- straight up, the second jump at the top, in over the roof once above it
			drive.dir=Vector3.zero
			drive.jump=true
			local up=os.clock()
			local leapt=false
			while os.clock()-up<2.4 do
				task.wait();watch()
				local feet=root.Position.Y-HubMap.Origin.Y-Bot.FEET
				local d=flat(centre-root.Position)
				drive.dir=if feet>roof.eave+.3 and d.Magnitude>1.5 then d.Unit else Vector3.zero
				if not leapt and os.clock()-up>.25 and root.AssemblyLinearVelocity.Y<3 then drive.jump=true;leapt=true end
				if landed then break end
			end
		end
		drive.dir=Vector3.zero
		task.wait(.3);watch()
		res.highest=r1(math.max(res.highest or 0,top))
		if landed then res.reached=true;res.upIn=r1(os.clock()-t0-(res.approach or 0));break end
		if try<3 then Bot.walkTo(foot,res.name) end
	end
	res.t=r1(os.clock()-t0)
	return res
end

-- ------------------------------------------------------------------ the race
-- The rooftop race (Shared/Solo, Server/SoloPlay), run as a player who knows
-- the route: from the post, ring after ring, straight at each one. A wall in
-- the way with the ring above: run at it and jump into it (Client/HubMove runs
-- him up it); an edge with the ring not far below: jump, and the second jump
-- at the top of the jump; something over his head with the ring above: out
-- from under it first. The server says when a ring is passed
-- (NinjaSoloNext) and gives the time (NinjaSoloEnd, NinjaSoloTime).
Bot.RING_LIMIT=40
local function solo() return require(Shared:WaitForChild("Solo")) end
-- The server's epoch for this player (an action of another epoch is
-- dropped): "Ready" in the village makes it send it again.
local epoch,listening=nil,nil
local function learnEpoch()
	local remote=Shared:WaitForChild("Action")
	if not listening then
		listening=remote.OnClientEvent:Connect(function(d) if type(d)=="table" and type(d.epoch)=="number" then epoch=d.epoch end end)
	end
	if epoch==nil then
		remote:FireServer({action="Ready"})
		local t=os.clock()
		while epoch==nil and os.clock()-t<3 do task.wait() end
	end
	return epoch
end
local function action(name,payload)
	payload=payload or {}
	payload.action=name
	payload.epoch=learnEpoch()
	Shared:WaitForChild("Action"):FireServer(payload)
end
-- Steer at `goal` (a world position: the root over a roof) until `done()`.
-- Returns true, or false and why.
function Bot.toward(goal,limit,done)
	local t0=os.clock()
	local since,best=os.clock(),math.huge
	local stalls,jumpedAt,leapPending=0,0,false
	local wallDir,wallUntil=nil,0
	local outFrom=nil
	while os.clock()-t0<limit do
		if done() then return true end
		local _,hum,root=body()
		if not root then return false,"no body" end
		local feet=root.Position.Y-Bot.FEET
		local d=flat(goal-root.Position)
		local want=if d.Magnitude>.5 then d.Unit else Vector3.zero
		local grounded=hum.FloorMaterial~=Enum.Material.Air
		local above=goal.Y-Bot.FEET>feet+2   -- the ring's roof is above his feet
		if os.clock()<wallUntil and wallDir then
			drive.dir=wallDir                  -- straight into the wall he runs up
		elseif outFrom then
			-- out from under what covers him, then up
			drive.dir=outFrom
			if not ray(root.Position,Vector3.new(0,9,0)) then outFrom=nil;drive.dir=Vector3.zero;drive.jump=true;jumpedAt=os.clock();leapPending=true end
		else
			drive.dir=want
			if grounded and os.clock()-jumpedAt>.45 then
				local hit=ray(root.Position,want*3.2)
				local over=ray(root.Position,Vector3.new(0,9,0))
				if above and over and d.Magnitude<40 then
					outFrom=-want                  -- under a deck or a roof: out first
				elseif hit and above then
					wallDir=-Vector3.new(hit.Normal.X,0,hit.Normal.Z).Unit
					wallUntil=os.clock()+1.6
					drive.dir=wallDir;drive.jump=true;jumpedAt=os.clock()
				elseif above and ray(root.Position+want*3,Vector3.new(0,9,0)) then
					-- the edge of a deck just ahead, over his head: straight up, then in
					drive.dir=Vector3.zero;drive.jump=true;jumpedAt=os.clock();leapPending=true
				elseif d.Magnitude>6 and goal.Y-Bot.FEET>feet-8 and not ray(root.Position+want*3,Vector3.new(0,-(Bot.FEET+5),0)) then
					-- the edge of a roof, the ring not far below: across
					drive.jump=true;jumpedAt=os.clock();leapPending=true
				end
			end
		end
		if leapPending and not grounded and os.clock()-jumpedAt>.25 and root.AssemblyLinearVelocity.Y<3 then
			drive.jump=true;leapPending=false
		end
		-- in the air over the goal's height: in toward it
		if not grounded and feet>goal.Y-Bot.FEET+.3 and os.clock()>=wallUntil then drive.dir=want end
		task.wait()
		local dist=(goal-root.Position).Magnitude
		if dist<best-.5 then best=dist;since=os.clock()
		elseif os.clock()-since>1.4 then
			stalls+=1;since=os.clock();outFrom=nil
			drive.jump=true;jumpedAt=os.clock();leapPending=true
			if stalls>8 then return false,"stalled" end
		end
	end
	return false,"time"
end
function Bot.race()
	local S=solo()
	local out={rings={},started=false}
	local post=S.startPost()
	-- to the post, by the streets
	local leg=Bot.walkTo(post,"race post",S.Race.startReach*(HubMap.Scale or 1)*.6)
	out.toPost=leg.t
	player:SetAttribute("NinjaSoloEnd",nil)
	local serial=player:GetAttribute("NinjaSoloSerial") or 0
	action("SoloRace",{})
	local t=os.clock()
	while os.clock()-t<3 and player:GetAttribute("NinjaSolo")~="race" do task.wait() end
	if player:GetAttribute("NinjaSolo")~="race" then out.error="the race did not start";return out end
	out.started=true
	-- the countdown: he waits at the post
	local at=player:GetAttribute("NinjaSoloAt") or 0
	while workspace:GetServerTimeNow()<at do task.wait() end
	local go=os.clock()
	for i in S.Race.rings do
		local r=S.Race.rings[i]
		local goal=S.world(r[1],r[2],r[3])+Vector3.new(0,Bot.FEET,0)
		note(string.format("race ring %d",i))
		local t1=os.clock()
		local ok,why=Bot.toward(goal,Bot.RING_LIMIT,function()
			return (player:GetAttribute("NinjaSoloNext") or 1)>i or (player:GetAttribute("NinjaSoloSerial") or 0)>serial
		end)
		local _,_,root=body()
		local rel=root and root.Position-HubMap.Origin
		table.insert(out.rings,{ring=i,ok=ok,why=why,split=r1(os.clock()-t1),at=r1(os.clock()-go),
			where=rel and {r1(rel.X),r1(rel.Y),r1(rel.Z)} or nil,top=r1(r[2]*(HubMap.Scale or 1))})
		save()
		if not ok then action("SoloQuit");break end
	end
	drive.dir=Vector3.zero
	local t2=os.clock()
	while os.clock()-t2<3 and (player:GetAttribute("NinjaSoloSerial") or 0)<=serial do task.wait() end
	out.clock=r1(os.clock()-go)
	out.serverEnd=player:GetAttribute("NinjaSoloEnd")
	out.serverTime=player:GetAttribute("NinjaSoloTime")
	out.best=player:GetAttribute("NinjaSoloBest")
	return out
end

-- A tour: from where he stands, the nearest place not yet visited, then the
-- next, until all are; back to the gate at the end.
-- The places up high (a master on a balcony, a torii, a perch under the
-- faces): the engine's paths stop at the ground, so he goes there the ninja's
-- way (Bot.toward). Reached: within 6 studs across, standing at its height.
function Bot.high()
	local out={}
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	local npcs=workspace:FindFirstChild("NinjaDuelHub") and workspace.NinjaDuelHub:FindFirstChild("Masters")
	params.FilterDescendantsInstances={player.Character,npcs}
	for key,spot in HubMap.Masters or {} do
		if spot.at.Y>1 then
			local pos=HubMap.world(spot.at)
			local hit=workspace:Raycast(pos+Vector3.new(0,40,0),Vector3.new(0,-80,0),params)
			local floor=hit and hit.Position.Y or pos.Y
			local goal=Vector3.new(pos.X,floor+Bot.FEET,pos.Z)
			note("high "..key)
			local t0=os.clock()
			local ok,why=Bot.toward(goal,45,function()
				local _,hum,root=body()
				return root~=nil and flat(goal-root.Position).Magnitude<=6 and root.Position.Y-Bot.FEET>=floor-1
					and hum.FloorMaterial~=Enum.Material.Air
			end)
			local _,_,root=body()
			local rel=root and root.Position-HubMap.Origin
			table.insert(out,{master=key,place=spot.place,floor=r1(floor-HubMap.Origin.Y),on=hit and (hit.Instance.Parent.Name.."/"..hit.Instance.Name) or nil,
				ok=ok,why=why,t=r1(os.clock()-t0),where=rel and {r1(rel.X),r1(rel.Y),r1(rel.Z)} or nil})
			save()
			-- back down to the street for the next one
			Bot.walkTo(HubMap.world(Vector3.new(spot.at.X,0,spot.at.Z)+(spot.face or Vector3.new(0,0,1))*14),"down")
		end
	end
	return out
end

function Bot.tour(places)
	local left=table.clone(places)
	local _,_,root=body()
	local order={}
	local at=root and root.Position or HubMap.world(Vector3.zero)
	while #left>0 do
		local bi,bd=1,math.huge
		for i,p in left do local d=flat(p.pos-at).Magnitude if d<bd then bi,bd=i,d end end
		local p=table.remove(left,bi)
		table.insert(order,p);at=p.pos
	end
	for _,p in places do if p.name=="spawn:gate" then table.insert(order,p) end end
	return order
end

function Bot.start(plan)
	plan=plan or {}
	Bot.pois=plan.pois==true
	results={routes={},roofs={},places={},plan=plan}
	save()
	task.spawn(function()
		start()
		note("walking")
		local places=Bot.places()
		for _,p in places do local rel=p.pos-HubMap.Origin;table.insert(results.places,{name=p.name,at={r1(rel.X),r1(rel.Z)}}) end
		if plan.routes~=false then
			for i,p in Bot.tour(places) do
				note(string.format("route %d %s",i,p.name))
				table.insert(results.routes,Bot.walkTo(p.pos,p.name,p.near));save()
			end
		end
		if plan.high then
			results.high=Bot.high();save()
		end
		if plan.race then
			for n=1,plan.race do
				note("race "..n)
				results.races=results.races or {}
				table.insert(results.races,Bot.race());save()
			end
		end
		if plan.jump then
			note("jump")
			results.jump=Bot.jumpHeight();save()
		end
		if (plan.roofs or 0)>0 then
			local roofs,total,bands=Bot.roofs(plan.roofs,plan.maxEave)
			results.roofCount=total
			results.roofBands={bands=Bot.BANDS,count=bands}
			for i,roof in roofs do
				note(string.format("roof %d/%d",i,#roofs))
				table.insert(results.roofs,Bot.climb(roof));save()
			end
		end
		stop()
		note("done")
		save()
	end)
	return "started"
end
return Bot
