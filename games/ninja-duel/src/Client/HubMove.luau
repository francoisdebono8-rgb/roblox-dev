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

function Move.new()
	return setmetatable({runLatch=false,runMoved=false,restFor=0,leapUsed=false,jumpedAt=nil},Move)
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
	if state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.RunningNoPhysics then self.leapUsed=false end
	-- Fell out of the village (into the lake's floor, off the cliff): the gate.
	if root.Position.Y<HubMap.Origin.Y-40 then
		local spot=HubMap.Spawns.gate
		local at=HubMap.Origin+spot.at+Vector3.new(0,4,0)
		character:PivotTo(CFrame.lookAt(at,at+spot.face))
	end
	return root,ended
end

return Move
