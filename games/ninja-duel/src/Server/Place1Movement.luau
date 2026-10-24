-- Adapted directly from Place1 FirstPersonMovementController (alexkkork, MIT).
-- Per-actor/server execution replaces LocalPlayer, UI, input listeners and FPS camera.
-- Ground sprint/stamina, takeoff momentum, bunny-hop and air steering are donor code.
local Movement={}
function Movement.new(a,c)
 local profile=require(game:GetService("ReplicatedStorage").NinjaDuel.Config).Movement
 local WALK_SPEED=a.def.Speed
 local SPRINT_SPEED=profile.SprintSpeed*(a.def.SprintScale or 1)
 local JUMP_VERTICAL_SPEED=profile.JumpVelocity*(a.def.JumpScale or 1)
 local WALK_BHOP_SPEED=36
 local SPRINT_BHOP_SPEED=62*(a.def.SprintScale or 1)
 local STAMINA_DRAIN_SECONDS=60
 local STAMINA_REGEN_SECONDS=18
 local STAMINA_REGEN_DELAY=.85
 local EXHAUSTED_RECOVERY=.12
 local AIR_CONTROL_ACCELERATION=profile.AirAcceleration*(a.def.AirControlScale or 1)
 local AIR_ACCELERATION_SPEED_CAP=72
 local MOMENTUM_CARRY_CAP=120
 local currentCharacter,currentHumanoid,currentRoot=a.model,a.hum,a.root
 local stamina,regenDelayRemaining,exhausted,sprinting=1,0,false,false
 local lastGroundHorizontalVelocity=Vector3.zero
 local groundLocomotion=Vector3.zero
 -- Movement rhythm state (sprint and standstill bursts).
 local wasSprinting,burstUntil,burstReadyAt=false,0,0
 local lastJumpRequestAt=-math.huge
 local sprintInputs,jumpInputs='Sprint','Jump'
 local function anyHeld(kind) return kind=='Sprint' and a.sprinting end
 local function movementIsBlocked(_character)
  return a.wall~=nil or a.reaction~=nil or a.state~='Neutral'
   or a.model:GetAttribute('MovementTraversalActive')==true
 end
 local function setCharacterAttribute(name,value) a.model:SetAttribute(name,value) end
local function horizontalOf(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function moveVectorToward(current, target, maximumDelta)
	local difference = target - current
	local distance = difference.Magnitude
	if distance == 0 or distance <= maximumDelta then
		return target
	end
	return current + difference / distance * maximumDelta
end

local function preserveTakeoffMomentum()
	local character = currentCharacter
	local root = currentRoot
	if not character or not root or not root.Parent or movementIsBlocked(character) then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local currentHorizontal = horizontalOf(velocity)
	local carry = lastGroundHorizontalVelocity
	local carrySpeed = carry.Magnitude
	if carrySpeed <= currentHorizontal.Magnitude + 0.1 then
		return
	end

	if carrySpeed > MOMENTUM_CARRY_CAP then
		carry = carry.Unit * MOMENTUM_CARRY_CAP
	end
	root.AssemblyLinearVelocity = Vector3.new(carry.X, velocity.Y, carry.Z)
end

local function applyAirControl(deltaTime, desiredSprint)
	local root = currentRoot
	local humanoid = currentHumanoid
	if not root or not humanoid then
		return
	end

	local moveDirection = horizontalOf(a.move)
	if moveDirection.Magnitude < 0.05 then
		return
	end
	moveDirection = moveDirection.Unit

	local velocity = root.AssemblyLinearVelocity
	local horizontal = horizontalOf(velocity)
	local currentSpeed = horizontal.Magnitude
	local requestedSpeed = desiredSprint and SPRINT_SPEED or WALK_SPEED
	local targetSpeed
	if currentSpeed > AIR_ACCELERATION_SPEED_CAP then
		targetSpeed = currentSpeed
	else
		targetSpeed = math.min(math.max(currentSpeed, requestedSpeed), AIR_ACCELERATION_SPEED_CAP)
	end

	local targetHorizontal = moveDirection * targetSpeed
	local steeredHorizontal = moveVectorToward(
		horizontal,
		targetHorizontal,
		AIR_CONTROL_ACCELERATION * deltaTime
	)
	local allowedSpeed = math.max(currentSpeed, AIR_ACCELERATION_SPEED_CAP)
	if steeredHorizontal.Magnitude > allowedSpeed then
		steeredHorizontal = steeredHorizontal.Unit * allowedSpeed
	end

	if (steeredHorizontal - horizontal).Magnitude > 0.001 then
		root.AssemblyLinearVelocity = Vector3.new(steeredHorizontal.X, velocity.Y, steeredHorizontal.Z)
	end
end

local function requestGroundJump()
	local character = currentCharacter
	local humanoid = currentHumanoid
	local root = currentRoot
	if not character or not humanoid or not root or movementIsBlocked(character)
		or humanoid.Health <= 0 or not a.grounded then
		return
	end
	local now = c.now
	if now - lastJumpRequestAt < 0.12 then
		return
	end
	lastJumpRequestAt = now

	local jumpDirection = horizontalOf(a.move)
	if jumpDirection.Magnitude > 0.05 then
		jumpDirection = jumpDirection.Unit
		local fastHop = sprinting or anyHeld(sprintInputs)
		local targetHopSpeed = fastHop and SPRINT_BHOP_SPEED or WALK_BHOP_SPEED
		local currentVelocity = root.AssemblyLinearVelocity
		local currentHorizontal = horizontalOf(currentVelocity)
		local boostedSpeed = math.max(currentHorizontal.Magnitude, targetHopSpeed)
		local boosted = jumpDirection * math.min(boostedSpeed, MOMENTUM_CARRY_CAP)
		root.AssemblyLinearVelocity = Vector3.new(boosted.X, currentVelocity.Y, boosted.Z)
		lastGroundHorizontalVelocity = boosted
	end
	-- The Humanoid applies its own JumpPower when it enters Jumping; keep it equal
	-- to the authored takeoff speed so the two never disagree.
	humanoid.JumpPower = JUMP_VERTICAL_SPEED
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	local takeoffVelocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(
		takeoffVelocity.X,
		math.max(takeoffVelocity.Y, JUMP_VERTICAL_SPEED),
		takeoffVelocity.Z
	)
	character:SetAttribute("MovementLastJumpAt", c.now)
	character:SetAttribute(
		"MovementLastJumpHorizontalSpeed",
		horizontalOf(root.AssemblyLinearVelocity).Magnitude
	)
	character:SetAttribute("MovementLastJumpVerticalSpeed", root.AssemblyLinearVelocity.Y)
end

local function updateMovement(deltaTime)
	local character = currentCharacter
	local humanoid = currentHumanoid
	local root = currentRoot
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local blocked = movementIsBlocked(character)
	local grounded = a.grounded
	local horizontalVelocity = horizontalOf(root.AssemblyLinearVelocity)
	local groundSpeed = horizontalVelocity.Magnitude
	local hasMoveInput = a.move.Magnitude > 0.05
	local wantsSprint = anyHeld(sprintInputs) and hasMoveInput

	if exhausted and stamina >= EXHAUSTED_RECOVERY then
		exhausted = false
	end

	sprinting = not blocked and wantsSprint and not exhausted and stamina > 0
	if sprinting then
		stamina = math.max(0, stamina - deltaTime / STAMINA_DRAIN_SECONDS)
		regenDelayRemaining = STAMINA_REGEN_DELAY
		if stamina <= 0 then
			stamina = 0
			exhausted = true
			sprinting = false
		end
	else
		regenDelayRemaining = math.max(0, regenDelayRemaining - deltaTime)
		if regenDelayRemaining == 0 then
			stamina = math.min(1, stamina + deltaTime / STAMINA_REGEN_SECONDS)
		end
	end

	local desiredWalkSpeed = (sprinting and SPRINT_SPEED or WALK_SPEED)*(a.speedScale or 1)
	-- A finished dodge hands its exit speed to the ground locomotion (the
	-- velocity it left the body with), so the next step continues it.
	if a.evadeCarry and not blocked then
		if grounded then groundLocomotion=horizontalOf(a.evadeCarry) end
		a.evadeCarry=nil
	end
	if grounded then
		local input=horizontalOf(a.move)
		local target=Vector3.zero
		if not blocked and input.Magnitude>.05 then
			-- A backpedal or side step is slower than running where the body faces.
			local face=horizontalOf(root.CFrame.LookVector)
			local along=if face.Magnitude>.01 then face.Unit:Dot(input.Unit) else 1
			local scale=if along<-.3 then .72 elseif along<.5 then .88 else 1
			target=input.Unit*desiredWalkSpeed*scale
		end
		local acceleration=profile.GroundAcceleration*(a.def.AccelerationScale or 1)
		-- Rhythm: ordinary steps carry weight; a sprint that starts, or a move
		-- committed from a near standstill, bursts. Fast moments read as fast
		-- because the rest is not.
		if sprinting and not wasSprinting then burstUntil=c.now+(profile.BurstWindow or .16) end
		if target.Magnitude>.05 and groundLocomotion.Magnitude<desiredWalkSpeed*.35 and c.now>=(burstReadyAt or 0) then
			burstUntil=c.now+(profile.BurstWindow or .16)*.6;burstReadyAt=c.now+.5
		end
		wasSprinting=sprinting
		if target.Magnitude<.05 then acceleration=profile.GroundDeceleration
		elseif c.now<(burstUntil or 0) then acceleration=profile.BurstAcceleration or acceleration
		elseif groundLocomotion.Magnitude>.05 and groundLocomotion.Unit:Dot(target.Unit)<.45 then acceleration=profile.TurnAcceleration end
		groundLocomotion=moveVectorToward(groundLocomotion,target,acceleration*deltaTime)
		if groundLocomotion.Magnitude<.03 then groundLocomotion=Vector3.zero end
		lastGroundHorizontalVelocity=groundLocomotion
		humanoid.WalkSpeed=groundLocomotion.Magnitude
		humanoid:Move(if groundLocomotion.Magnitude>.01 then groundLocomotion.Unit else Vector3.zero,false)
		a.locomotion=groundLocomotion
	else
		-- Preserve the last grounded vector at takeoff, then bend it gradually in air.
		groundLocomotion=horizontalVelocity
		a.locomotion=horizontalVelocity
	end

	if not blocked then

		if anyHeld(jumpInputs) and grounded then
			requestGroundJump()
		end

		if not grounded then
			applyAirControl(deltaTime, sprinting)
			a.locomotion=horizontalOf(root.AssemblyLinearVelocity)
		end
	end

	setCharacterAttribute("MovementSprinting", sprinting)
	setCharacterAttribute("MovementStamina", stamina)
	setCharacterAttribute("MovementGroundSpeed", groundSpeed)
end


 local api={}
 function api.step(dt,grounded)
  a.grounded=grounded
  updateMovement(math.min(dt,.1))
  return sprinting
 end
 function api.jump(grounded)
  a.grounded=grounded
  local previous=lastJumpRequestAt
  requestGroundJump()
  if lastJumpRequestAt~=previous then
   preserveTakeoffMomentum()
   a.airborne=true;a.airDodgeUsed=false;a.takeoffUntil=c.now+.18
   return true
  end
  return false
 end
 return api
end
return Movement
