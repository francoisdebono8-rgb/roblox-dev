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

function Move.new()
	return setmetatable({runLatch=false,runMoved=false,restFor=0,leapUsed=false,jumpedAt=nil,climb=nil,climbUsed=false,kickedAt=-1,kickedFrom=nil},Move)
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
	m.climb=nil;m.climbUsed=false;m.leapUsed=false
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
	if not (hit and hit.Instance:GetAttribute("NinjaWall") and math.abs(hit.Normal.Y)<.3) then return nil end
	return {normal=Vector3.new(hit.Normal.X,0,hit.Normal.Z).Unit,part=hit.Instance}
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
	-- on a wall: the kick off it
	local kick=Move.kick(self,os.clock())
	if kick then
		root.AssemblyLinearVelocity=kick
		root.CFrame=CFrame.lookAt(root.Position,root.Position+Vector3.new(kick.X,0,kick.Z))
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	end
	local state=hum:GetState()
	if (state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping) and not self.leapUsed and os.clock()-(self.jumpedAt or 0)>Move.LEAP_AFTER then
		self.leapUsed=true
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(v.X,Move.LEAP,v.Z)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	elseif state~=Enum.HumanoidStateType.Freefall then
		self.jumpedAt=os.clock()
	end
	return false
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
	hum.UseJumpPower=true;hum.JumpPower=Move.JUMP
	local state=hum:GetState()
	local grounded=state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.RunningNoPhysics
	if grounded and not self.climb then Move.landed(self) end
	-- the run up a wall
	local direction=if self.climb then -self.climb.normal else hum.MoveDirection
	local wall=look(character,root,direction)
	local into=0
	if wall and hum.MoveDirection.Magnitude>.1 then into=hum.MoveDirection.Unit:Dot(-wall.normal) end
	if self.climb then into=1 end
	local share=tonumber(Players.LocalPlayer:GetAttribute("NinjaWallRun")) or 1
	local velocity,what=Move.climbStep(self,os.clock(),{wall=wall,into=into,air=not grounded,run=run,scale=share})
	if velocity then
		root.AssemblyLinearVelocity=velocity
		if what=="start" then
			root.CFrame=CFrame.lookAt(root.Position,root.Position-wall.normal)
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
	self.climbing=self.climb~=nil
	-- Fell out of the village (into the lake's floor, off the cliff): the gate.
	if root.Position.Y<HubMap.Origin.Y-40 then
		local spot=HubMap.Spawns.gate
		local at=HubMap.Origin+spot.at+Vector3.new(0,4,0)
		character:PivotTo(CFrame.lookAt(at,at+spot.face))
	end
	return root,ended
end

return Move
