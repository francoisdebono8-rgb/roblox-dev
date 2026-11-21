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
	local ok,Layout=pcall(function() return require(Shared:FindFirstChild("KonohaLayout")) end)
	if ok and Layout and Layout.Pois and (Bot.pois or Layout.Built) then
		for _,poi in Layout.Pois do
			if not poi.far then add("poi:"..poi.id,Vector3.new(poi.at.X,0,poi.at.Y)*(HubMap.Scale or 1)) end
		end
	end
	return list
end

-- Walk (at a run) to a place, along a path the engine computes, the way a
-- player would steer: at the next point, a jump where the path says so or
-- where he stopped moving. Returns what the leg met.
function Bot.walkTo(goal,label)
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
			while flat(target-root.Position).Magnitude>(if i==#points then Bot.ARRIVE else 2.5) do
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
		if flat(goal-root.Position).Magnitude<=Bot.ARRIVE+1 and high<=6 then leg.arrived=true;break end
		if flat(goal-root.Position).Magnitude<=Bot.ARRIVE+1 then leg.below=r1(goal.Y-(root.Position.Y-3)) end
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

-- Get up on a roof as a player does: stand just outside its eave (under it,
-- the head hits the roof), jump straight up, the second jump at the top of
-- the first, and step in over the roof once the feet are above the eave.
-- Three tries from the side the path arrives at.
Bot.FEET=3.8
Bot.OUTSIDE=2.5
function Bot.climb(roof)
	local part=roof.part
	local res={name=(part.Parent and part.Parent.Name or "?").."/"..part.Name,eave=r1(roof.eave),ridge=r1(roof.ridge),reached=false,tries=0,t=0}
	local t0=os.clock()
	local centre=part.Position
	local ground=Vector3.new(centre.X,HubMap.Origin.Y,centre.Z)
	local edge=math.max(part.Size.X,part.Size.Z)/2+6
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
	for try=1,3 do
		res.tries=try
		local _,_,now=body()
		if not now then break end
		root=now
		local top=0
		local landed=false
		-- the top of the feet, and whether he stood on the roof at any moment
		local function watch()
			local feet=root.Position.Y-HubMap.Origin.Y-Bot.FEET
			top=math.max(top,feet)
			local _,hum=body()
			if outside(root.Position)<=1 and feet>=roof.eave-1 and hum and hum.FloorMaterial~=Enum.Material.Air then landed=true end
		end
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
		drive.dir=Vector3.zero
		task.wait(.3);watch()
		res.highest=r1(math.max(res.highest or 0,top))
		if landed then res.reached=true;break end
		if try<3 then Bot.walkTo(foot,res.name) end
	end
	res.t=r1(os.clock()-t0)
	return res
end

-- A tour: from where he stands, the nearest place not yet visited, then the
-- next, until all are; back to the gate at the end.
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
				table.insert(results.routes,Bot.walkTo(p.pos,p.name));save()
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
