-- The walk in Konoha (DEV): the run, the ninja's second jump, the fall back to
-- the gate. Split from Client/HubClient on 19/11 (plan « vague 2 », DEV 1) so
-- that the DESIGN owns the village's screen (HubClient: the HUD, the cards,
-- the markers, the buttons) and the DEV the body's movement, each in its own
-- file. HubClient makes one HubMove, steps it every frame while the village is
-- walked, and asks it to toggle the run (the RUN button, L3) and to jump.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local HubMap=require(Shared.HubMap)

local Move={}
Move.__index=Move
-- (14/11) The run latched by L3 or the touch RUN button stops after this long
-- at rest (the duel's pad sprint does the same, DECISIONS socle 2).
Move.REST=.35
-- (15/11) the village is 1.3 times bigger (HubMap.Scale): the run a little faster
Move.WALK,Move.RUN,Move.JUMP,Move.LEAP=16,36,56,54
-- The second jump: not before this long after leaving the ground.
Move.LEAP_AFTER=.18
-- (23/11, step 4, DEC-048) the second jump is a bound: for this long after it
-- the run carries this much more speed through the air (a roof to the next)
Move.BOUND,Move.BOUND_TIME=1.15,.6

-- (21/11, étape 3 DEV 3, DEC-047; François: « murs et toits courables
-- partout ») The run up a wall. Moving into a wall to run on (Server/Hub tags
-- them NinjaWall: every house of the plan, the village walls) in the air, or
-- running into it, he runs up it; at its top a hop onto the roof; jump on the
-- wall: a kick off it, back and up, and his second jump given back (alley to
-- alley). Once per wall touch, given back on the ground and by a kick. The
-- ninja tree's Wall Runner (DEC-045) makes it longer here too (the player's
-- attribute NinjaWallRun, Server/Progression.badges).
Move.CLIMB=38              -- studs a second up the wall
Move.CLIMB_TIME=.95        -- about 36 studs: a three-storey house of the plan
Move.CLIMB_REACH=2.8       -- the wall ahead, from the body's centre
Move.CLIMB_INTO=.55        -- how straight into the wall he must be moving
Move.MANTLE=Vector2.new(18,42) -- the hop over the top: forward, up (feet over the edge)
Move.KICK=Vector2.new(34,50)   -- the kick off the wall: away, up
Move.REGRAB=.3             -- after a kick, the same wall again not before

-- (27/11, François: « course latérale sur les murs, une vraie adaptation au
-- mur, qu'on puisse combattre sur les murs à la perpendiculaire ») Two more
-- ways on a wall:
--   * the run ALONG it: in the air (or running) beside a wall, moving along
--     it, he runs on it sideways, leaning into it, a short arc up then down;
--     jump: the kick off it; it runs out: he falls, his second jump given back.
--   * standing ON it: a run up (or along) that runs out with the stick still
--     into the wall sticks there, the body at a right angle to it, its feet
--     on it. The stick walks on it (into the wall: up, away: down, sideways:
--     along); his kit's blows and guard are played there (HubFightClient:
--     the root itself is turned); jump: the kick; at the top: onto the roof;
--     at the foot: back on the ground. The duel does the same (Server/Motor).
Move.SIDE_SPEED=40         -- studs a second along the wall
Move.SIDE_TIME=.9          -- how long the run along a wall lasts
Move.SIDE_RISE=16          -- the arc: up at first, falling SIDE_FALL a second after
Move.SIDE_FALL=34
Move.SIDE_INTO=.62         -- moving less straight into the wall than this: along it
Move.SIDE_REACH=2.9        -- the wall beside him, from the body's centre
Move.SIDE_MIN=14           -- the speed it takes (horizontal)
Move.SIDE_GAP=1.6          -- the body's centre off the wall while running on it
Move.STAND_SPEED=16        -- studs a second walking on the wall
Move.STAND_TIME=6          -- how long he holds on a wall
Move.STAND_INTO=.3         -- how straight into the wall the stick must be to stick

function Move.new()
	return setmetatable({runLatch=false,runMoved=false,restFor=0,leapUsed=false,jumpedAt=nil,climb=nil,climbUsed=false,kickedAt=-1,kickedFrom=nil,leapAt=nil,mantleAt=nil,side=nil,stand=nil},Move)
end
-- (23/11, step 5, DEC-049) an emote in the street: the look of the emote slot
-- (Shared/Shop id), played by his body for all to see (Server/Hub.pose). G on
-- a keyboard; the DESIGN's emote wheel calls Move:emote(id) too.
Move.EMOTE_KEY=Enum.KeyCode.G
function Move:emote(id)
	if type(id)~="string" then return end
	local remote=self.poseRemote or game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuel") and game:GetService("ReplicatedStorage").NinjaDuel:FindFirstChild("HubPose")
	self.poseRemote=remote
	if remote then remote:FireServer("emote:"..id) end
end

-- (23/11, step 4, DEC-048) his body posed like a ninja by the kit's clips
-- (Client/HubBody), in the village only; nil where the clips cannot load.
function Move:body()
	if self.bodyTried then return self.poser end
	self.bodyTried=true
	pcall(function()
		local Authored=require(script.Parent.AuthoredMotion)
		self.poser=require(script.Parent.HubBody).new(Authored)
	end)
	return self.poser
end

-- The run up a wall, one frame (pure). `m` the walker's state, `now` the
-- clock, `see` what the rays found: {wall = {normal, part} or nil (the wall
-- ahead at the chest), into = how straight into it he moves (0..1), air =
-- off the ground, run = running, scale = the tree's share}. Returns the velocity to give the body
-- this frame (nil: leave it to the humanoid) and what happened ("start",
-- "climb", "top", "spent", nil).
function Move.climbStep(m,now,see)
	local c=m.climb
	if c then
		-- the chest over the top: a hop onto the roof
		if not see.wall then
			m.climb=nil
			return -c.normal*Move.MANTLE.X+Vector3.yAxis*Move.MANTLE.Y,"top"
		end
		-- round a corner, or spent: he falls, his second jump given back
		if see.wall.normal:Dot(c.normal)<.9 or now-c.at>=Move.CLIMB_TIME*(c.scale or 1) then
			m.climb=nil;m.leapUsed=false
			return nil,"spent"
		end
		c.part=see.wall.part -- the next segment of the same wall
		return -c.normal*6+Vector3.yAxis*Move.CLIMB,"climb"
	end
	if m.climbUsed or not see.wall or (see.into or 0)<Move.CLIMB_INTO then return nil,nil end
	if not (see.air or see.run) then return nil,nil end
	if m.kickedFrom==see.wall.part and now-m.kickedAt<Move.REGRAB then return nil,nil end
	m.climb={at=now,normal=see.wall.normal,part=see.wall.part,scale=see.scale or 1}
	m.climbUsed=true
	return -see.wall.normal*6+Vector3.yAxis*Move.CLIMB,"start"
end
-- The jump pressed on the wall: the kick (pure). Returns the velocity or nil.
function Move.kick(m,now)
	local c=m.climb
	if not c then return nil end
	m.climb=nil;m.climbUsed=false;m.leapUsed=false
	m.kickedAt=now;m.kickedFrom=c.part
	return c.normal*Move.KICK.X+Vector3.yAxis*Move.KICK.Y
end
-- On the ground: the wall run is his again.
function Move.landed(m)
	m.climb=nil;m.climbUsed=false;m.leapUsed=false;m.side=nil;m.sideUsed=false
end

-- ------------------------------------------------------------ along the wall
-- (pure) The run along a wall starting: `see` = {wall = {normal, part} (the
-- wall beside him), dir = his flat move (unit), speed (horizontal), air, run}.
-- Returns the velocity of its first frame, or nil.
function Move.sideStart(m,now,see)
	if m.side or m.climb or m.stand or m.sideUsed then return nil end
	local w=see.wall
	if not w or not see.dir or (see.speed or 0)<Move.SIDE_MIN or not (see.air or see.run) then return nil end
	local into=see.dir:Dot(-w.normal)
	if into>=Move.SIDE_INTO or into<-.2 then return nil end
	if m.kickedFrom==w.part and now-m.kickedAt<Move.REGRAB then return nil end
	local along=see.dir-w.normal*see.dir:Dot(w.normal)
	if along.Magnitude<.3 then return nil end
	along=along.Unit
	-- the wall on his right: +1
	local side=if along:Cross(Vector3.yAxis):Dot(-w.normal)>0 then 1 else -1
	m.side={at=now,normal=w.normal,part=w.part,along=along,side=side,speed=math.max(Move.SIDE_SPEED,see.speed),scale=see.scale or 1}
	m.sideUsed=true
	return along*m.side.speed+Vector3.yAxis*Move.SIDE_RISE
end
-- (pure) One frame of the run along: `see.wall` the wall still beside him
-- (nil: it ended, a corner, a door). Returns the velocity and what happened
-- ("run", "spent", "lost").
function Move.sideStep(m,now,see)
	local r=m.side
	if not r then return nil,nil end
	local t=now-r.at
	if not see.wall or see.wall.normal:Dot(r.normal)<.9 then m.side=nil;m.leapUsed=false;return nil,"lost" end
	if t>=Move.SIDE_TIME*(r.scale or 1) then m.side=nil;m.leapUsed=false;return nil,"spent" end
	r.part=see.wall.part
	local speed=r.speed*math.exp(-.6*t)
	return r.along*speed+Vector3.yAxis*(Move.SIDE_RISE-Move.SIDE_FALL*t),"run"
end
-- The jump on a wall run along it: the kick, away and up, the run kept (pure).
function Move.sideKick(m,now)
	local r=m.side
	if not r then return nil end
	m.side=nil;m.sideUsed=false;m.leapUsed=false
	m.kickedAt=now;m.kickedFrom=r.part
	return r.normal*Move.KICK.X*.8+r.along*Move.SIDE_SPEED*.6+Vector3.yAxis*Move.KICK.Y
end

-- -------------------------------------------------------------- on the wall
-- (pure) The wall's axes: up it (the world's up laid on it), along it.
function Move.wallAxes(normal)
	local up=Vector3.yAxis-normal*normal.Y
	if up.Magnitude<.05 then up=Vector3.zAxis end
	up=up.Unit
	return up,up:Cross(normal).Unit
end
-- (pure) The stick on a wall: into it climbs, away comes down, sideways along.
function Move.wallStick(move,normal)
	local m=Vector3.new(move.X,0,move.Z)
	if m.Magnitude<.2 then return Vector3.zero end
	local up,along=Move.wallAxes(normal)
	local v=up*m:Dot(-normal)+along*m:Dot(along)
	return if v.Magnitude>1 then v.Unit else v
end
function Move.standStart(m,now,wall,scale)
	m.climb=nil;m.side=nil
	m.stand={at=now,normal=wall.normal,part=wall.part,look=Move.wallAxes(wall.normal),scale=scale or 1}
	return m.stand
end
-- The jump on the wall standing: the kick off it (pure).
function Move.standKick(m,now)
	local st=m.stand
	if not st then return nil end
	m.stand=nil;m.climbUsed=false;m.sideUsed=false;m.leapUsed=false
	m.kickedAt=now;m.kickedFrom=st.part
	return st.normal*Move.KICK.X+Vector3.yAxis*Move.KICK.Y
end

-- (pure) A surface the walker runs up: a NinjaWall, upright, and not the
-- village's own wall (NinjaNoClimb, Server/Hub: the edge of the village).
function Move.climbable(part,normal)
	if not part or part:GetAttribute("NinjaWall")~=true or part:GetAttribute("NinjaNoClimb")==true then return false end
	return math.abs(normal.Y)<.3
end
-- The ray of a frame: the wall ahead at the chest (only parts tagged
-- NinjaWall, in the village).
local params
local function look(character,root,direction)
	if not params then params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude end
	params.FilterDescendantsInstances={character}
	local flat=Vector3.new(direction.X,0,direction.Z)
	if flat.Magnitude<.1 then return nil end
	flat=flat.Unit
	local hit=workspace:Raycast(root.Position,flat*Move.CLIMB_REACH,params)
	if not (hit and Move.climbable(hit.Instance,hit.Normal)) then return nil end
	return {normal=Vector3.new(hit.Normal.X,0,hit.Normal.Z).Unit,part=hit.Instance}
end

-- The wall beside him (left or right, at the chest), for the run along it.
local function beside(character,root,direction)
	if not params then params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude end
	params.FilterDescendantsInstances={character}
	local flat=Vector3.new(direction.X,0,direction.Z)
	if flat.Magnitude<.1 then return nil end
	flat=flat.Unit
	local right=flat:Cross(Vector3.yAxis)
	local best=nil
	for _,dir in {right,-right,(right+flat).Unit,(-right+flat).Unit} do
		local hit=workspace:Raycast(root.Position,dir*Move.SIDE_REACH,params)
		if hit and Move.climbable(hit.Instance,hit.Normal) and (not best or hit.Distance<best.distance) then
			best={normal=Vector3.new(hit.Normal.X,0,hit.Normal.Z).Unit,part=hit.Instance,distance=hit.Distance,position=hit.Position}
		end
	end
	return best
end
-- The wall under his feet while he stands on it (a ray from the root back to it).
local function under(character,root,normal,reach)
	if not params then params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude end
	params.FilterDescendantsInstances={character}
	local hit=workspace:Raycast(root.Position,-normal*reach,params)
	if not (hit and Move.climbable(hit.Instance,hit.Normal)) then return nil end
	return {normal=Vector3.new(hit.Normal.X,0,hit.Normal.Z).Unit,part=hit.Instance,position=hit.Position}
end

local function body()
	local character=Players.LocalPlayer.Character
	local hum=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	return character,hum,root
end

-- The run latch (the touch RUN button, L3). Returns the new state.
function Move:toggleRun()
	self.runLatch=not self.runLatch;self.runMoved=false;self.restFor=0
	return self.runLatch
end

-- The jump button pressed: in the air, once per jump, a ninja's second jump
-- (chakra under the feet); on the ground, remembers when he left it.
function Move:jump()
	local _,hum,root=body()
	if not hum or not root then return false end
	-- on a wall: the kick off it (standing on it, running along it, up it)
	local wasStanding=self.stand~=nil
	local kick=Move.standKick(self,os.clock()) or Move.sideKick(self,os.clock()) or Move.kick(self,os.clock())
	if wasStanding then self:leaveWall(hum,root) end
	if kick then
		root.AssemblyLinearVelocity=kick
		root.CFrame=CFrame.lookAt(root.Position,root.Position+Vector3.new(kick.X,0,kick.Z))
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	end
	local state=hum:GetState()
	if (state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping) and not self.leapUsed and os.clock()-(self.jumpedAt or 0)>Move.LEAP_AFTER then
		self.leapUsed=true
		self.leapAt=os.clock()
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(v.X,Move.LEAP,v.Z)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	elseif state~=Enum.HumanoidStateType.Freefall then
		self.jumpedAt=os.clock()
	end
	return false
end

-- Off the wall he stood on: upright again, his own physics back.
function Move:leaveWall(hum,root)
	self.stand=nil
	pcall(function() hum.PlatformStand=false end)
	local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
	if look.Magnitude<.2 then look=Vector3.new(root.CFrame.UpVector.X,0,root.CFrame.UpVector.Z) end
	if look.Magnitude<.1 then look=Vector3.new(0,0,-1) end
	root.CFrame=CFrame.lookAt(root.Position,root.Position+look.Unit)
end
-- One frame standing on the wall. Returns what happened ("stand", "top",
-- "foot", "lost", "spent") and the speed he walks it.
function Move:standFrame(character,hum,root,dt,busy)
	local st=self.stand
	local height=math.max(1.5,hum.HipHeight+root.Size.Y/2)
	local wall=under(character,root,st.normal,height+1.8)
	if not wall then self:leaveWall(hum,root);return "lost",0 end
	st.normal,st.part=wall.normal,wall.part
	local up=Move.wallAxes(wall.normal)
	local walk=if busy then Vector3.zero else Move.wallStick(hum.MoveDirection,wall.normal)
	local motion=walk*Move.STAND_SPEED
	local foot=wall.position+motion*dt
	if os.clock()-st.at>=Move.STAND_TIME*(st.scale or 1) then self:leaveWall(hum,root);return "spent",0 end
	-- down at the foot of the wall: back on the ground
	if walk:Dot(up)<-.3 then
		local floor=workspace:Raycast(foot+wall.normal*.6,Vector3.new(0,-2.4,0),params)
		if floor and floor.Normal.Y>.6 then
			self:leaveWall(hum,root)
			root.CFrame=CFrame.new(floor.Position+wall.normal*1.2+Vector3.yAxis*height)*root.CFrame.Rotation
			root.AssemblyLinearVelocity=Vector3.zero
			return "foot",0
		end
	end
	-- the top: over it onto the roof
	local top=wall.part.Position.Y+wall.part.Size.Y*.5
	if foot.Y>top-.4 then
		self:leaveWall(hum,root)
		root.AssemblyLinearVelocity=-wall.normal*Move.MANTLE.X+Vector3.yAxis*Move.MANTLE.Y
		return "top",0
	end
	-- where he looks: where he walks; still, his last look
	if motion.Magnitude>1 then st.look=motion.Unit end
	local look=st.look-wall.normal*st.look:Dot(wall.normal)
	look=if look.Magnitude>.1 then look.Unit else up
	local at=foot+wall.normal*height
	pcall(function() hum.PlatformStand=true end)
	root.CFrame=CFrame.fromMatrix(at,look:Cross(wall.normal),wall.normal,-look)
	root.AssemblyLinearVelocity=Vector3.zero
	root.AssemblyAngularVelocity=Vector3.zero
	return "stand",motion.Magnitude
end

-- One frame of the walk. Returns the character's root (nil without a body)
-- and whether the run latch just ended (the screen repaints its RUN button).
function Move:step(dt)
	local character,hum,root=body()
	if not hum or not root then return nil,false end
	-- Shift held, or the run latched (L3, the touch RUN button) until he stops.
	-- (Latched standing still, it waits for him to move: the rest that ends
	-- it is the one after a run.)
	local ended=false
	if self.runLatch then
		if hum.MoveDirection.Magnitude>=.1 then self.runMoved=true;self.restFor=0
		elseif self.runMoved then self.restFor=(self.restFor or 0)+dt end
		if self.restFor>Move.REST then self.runLatch=false;self.runMoved=false;self.restFor=0;ended=true end
	end
	local run=self.runLatch or UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
	hum.WalkSpeed=if run then Move.RUN else Move.WALK
	-- the bound of the second jump carries him further
	if self.leapAt and os.clock()-self.leapAt<Move.BOUND_TIME and hum.MoveDirection.Magnitude>.1 then hum.WalkSpeed=Move.RUN*Move.BOUND end
	hum.UseJumpPower=true;hum.JumpPower=Move.JUMP
	local state=hum:GetState()
	local grounded=state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.RunningNoPhysics
	if grounded and not self.climb and not self.stand then Move.landed(self) end
	local share=tonumber(Players.LocalPlayer:GetAttribute("NinjaWallRun")) or 1
	local now=os.clock()
	local what=nil
	local wallSpeed=nil
	local busy=self.fight and self.fight.busy and self.fight:busy()
	if self.stand then
		-- standing on the wall (27/11)
		local happened,speed=self:standFrame(character,hum,root,dt,busy)
		what=if happened=="top" then "top" else nil
		if happened=="top" then self.mantleAt=now end
		wallSpeed=speed
	elseif self.side then
		-- running along the wall (27/11)
		local wall=beside(character,root,self.side.along)
		local velocity,happened=Move.sideStep(self,now,{wall=wall})
		if velocity then
			root.AssemblyLinearVelocity=velocity
			-- kept off the wall at the same gap, facing the run
			local at=root.Position
			if wall then at=at+wall.normal*(Move.SIDE_GAP-wall.distance) end
			root.CFrame=CFrame.lookAt(at,at+self.side.along)
		elseif happened=="spent" and wall and hum.MoveDirection.Magnitude>.1 and hum.MoveDirection.Unit:Dot(-wall.normal)>=Move.STAND_INTO then
			Move.standStart(self,now,wall,share)
		end
	else
		-- the run up a wall
		local direction=if self.climb then -self.climb.normal else hum.MoveDirection
		local wall=look(character,root,direction)
		local into=0
		if wall and hum.MoveDirection.Magnitude>.1 then into=hum.MoveDirection.Unit:Dot(-wall.normal) end
		local stickInto=into
		if self.climb then into=1 end
		local climbWall=self.climb
		local velocity
		velocity,what=Move.climbStep(self,now,{wall=wall,into=into,air=not grounded,run=run,scale=share})
		if velocity then
			root.AssemblyLinearVelocity=velocity
			if what=="start" then
				root.CFrame=CFrame.lookAt(root.Position,root.Position-wall.normal)
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		elseif what=="spent" and wall and climbWall and stickInto>=Move.STAND_INTO then
			-- the climb spent, the stick still into the wall: he stands on it
			Move.standStart(self,now,wall,share)
		elseif not what and not self.climb then
			-- beside a wall, moving along it: he runs on it
			local flat=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z)
			local dir=if hum.MoveDirection.Magnitude>.1 then Vector3.new(hum.MoveDirection.X,0,hum.MoveDirection.Z).Unit else nil
			local side=dir and beside(character,root,dir)
			local first=side and Move.sideStart(self,now,{wall=side,dir=dir,speed=flat.Magnitude,air=not grounded,run=run,scale=share})
			if first then
				root.AssemblyLinearVelocity=first
				root.CFrame=CFrame.lookAt(root.Position,root.Position+self.side.along)
				hum:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end
		if what=="top" then self.mantleAt=now end
	end
	-- (23/11, step 5) the emote key, and the emote the server granted (his own
	-- character's NinjaPose / NinjaEmote, as everyone sees it)
	if not self.emoteBound then
		self.emoteBound=true
		UIS.InputBegan:Connect(function(input,processed)
			-- (only while he walks the village: the walk was stepped just now)
			if not processed and input.KeyCode==Move.EMOTE_KEY and os.clock()-(self.steppedAt or -10)<.5 then self:emote("equipped") end
		end)
	end
	self.steppedAt=os.clock()
	local seq=character:GetAttribute("NinjaPoseSeq")
	if seq~=self.seenSeq then
		self.seenSeq=seq
		if character:GetAttribute("NinjaPose")=="emote" then self.emoteClip,self.emoteAt=character:GetAttribute("NinjaEmote"),os.clock() end
	end
	self.climbing=self.climb~=nil
	-- (23/11, step 5) what the others need to pose him: his move, sent on change
	local pose=if self.climb then "climb" elseif self.stand then "wallstand"
		elseif self.side then (if self.side.side>0 then "siderunR" else "siderunL") else "none"
	if self.leapAt and self.leapAt>(self.sentLeap or 0) then pose="leap";self.sentLeap=self.leapAt
	elseif self.kickedAt and self.kickedAt>0 and self.kickedAt>(self.sentKick or 0) then pose="kick";self.sentKick=self.kickedAt
	elseif what=="top" then pose="vault" end
	if pose~=self.sentPose or pose=="leap" or pose=="kick" or pose=="vault" then
		self.sentPose=pose
		local remote=self.poseRemote or game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuel") and game:GetService("ReplicatedStorage").NinjaDuel:FindFirstChild("HubPose")
		self.poseRemote=remote
		if remote then remote:FireServer(pose) end
	end
	-- (26/11, passe 3, DEC-055) his kit in the street: the keys, the slow of a
	-- blow, the dash (Client/HubFightClient)
	if not self.fight then
		local ok,Fight=pcall(require,script.Parent.HubFightClient)
		if ok then self.fight=Fight.new(self);self.fight:bind() end
	end
	local act,actAt=nil,nil
	if self.fight then
		local ok,a,at=pcall(self.fight.step,self.fight,dt,hum,root)
		if ok then act,actAt=a,at end
	end
	-- the body, posed by the kit's clips (Client/HubBody); the other walkers too
	local poser=self:body()
	if poser then
		pcall(require(script.Parent.HubBody).poseOthers,poser.Authored,dt,root.Position)
		local v=root.AssemblyLinearVelocity
		pcall(poser.step,poser,character,hum,{now=os.clock(),dt=dt,speed=wallSpeed or Vector3.new(v.X,0,v.Z).Magnitude,vy=if self.stand then 0 else v.Y,
			grounded=(grounded and not self.climb and not self.side) or self.stand~=nil,climbing=self.climb~=nil,climbSpeed=Move.CLIMB,
			sideRun=self.side and self.side.side,sideSpeed=self.side and self.side.speed,onWall=self.stand~=nil,
			leapAt=self.leapAt,kickAt=if self.kickedAt and self.kickedAt>0 then self.kickedAt else nil,mantleAt=self.mantleAt,
			emote=self.emoteClip,emoteAt=self.emoteAt,act=act,actAt=actAt})
	end
	-- Fell out of the village (into the lake's floor, off the cliff): the gate.
	if root.Position.Y<HubMap.Origin.Y-40 then
		-- (26/11, DEC-054) out of the forest's ground: its far end, not the village
		local rel=root.Position-HubMap.Origin
		local spot=if HubMap.inForest and HubMap.inForest(rel) then HubMap.Spawns.forest else HubMap.Spawns.gate
		local at=HubMap.Origin+spot.at+Vector3.new(0,4,0)
		character:PivotTo(CFrame.lookAt(at,at+spot.face))
	end
	return root,ended
end

return Move
