-- Adapted directly from Place1 ParkourTraversalController (alexkkork, MIT).
-- Per-actor server authority; semantic Jump API instead of donor UIS listeners.
-- Mantle detection/clearance/Bezier arc and multi-direction wall hops are retained.
local Parkour={}
function Parkour.new(a,c)
local MANTLE_REACH = 3.6
local MIN_LEDGE_HEIGHT = 0.7
local MAX_LEDGE_HEIGHT = 5.7
local MANTLE_CHECK_INTERVAL = 0.055
local MANTLE_COOLDOWN = 0.34
local WALL_HOP_REACH = 3.25
local WALL_HOP_AWAY_SPEED = 58
local WALL_HOP_UP_SPEED = 64
local WALL_HOP_COOLDOWN = 0.15
local MAX_WALL_HOPS = 2

 local character,humanoid,rootPart=a.model,a.hum,a.root
 local rayParams=c:rayParams(true);rayParams.RespectCanCollide=true
 local overlapParams=c:overlapParams();overlapParams.RespectCanCollide=true;overlapParams.MaxParts=32
local traversing = false
local mantleStartCFrame = CFrame.identity
local mantleTargetCFrame = CFrame.identity
local mantleStartedAt = 0
local mantleDuration = 0.42
local mantleHeight = 0
local savedWalkSpeed: number? = nil
local savedAutoRotate: boolean? = nil
local lastMantleAt = -math.huge
local lastMantleCheckAt = -math.huge

local jumpKeyHeld = false
local jumpPulseExpiresAt = 0
local wallHopCount = 0
local lastWallHopAt = -math.huge
local lastGroundedAt = c.now

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function safeUnit(vector: Vector3, fallback: Vector3): Vector3
	if vector.Magnitude > 1e-4 then
		return vector.Unit
	end
	return fallback
end

local function standingRootOffset(currentHumanoid: Humanoid, currentRoot: BasePart): number
	if currentHumanoid.RigType == Enum.HumanoidRigType.R6 then
		local currentCharacter = character
		local torso = currentCharacter and currentCharacter:FindFirstChild("Torso")
		local leg = currentCharacter and (
			currentCharacter:FindFirstChild("Left Leg")
			or currentCharacter:FindFirstChild("Right Leg")
		)
		if torso and torso:IsA("BasePart") and leg and leg:IsA("BasePart") then
			return torso.Size.Y * 0.5 + leg.Size.Y
		end
		return 3
	end
	return math.max(2.2, currentHumanoid.HipHeight + currentRoot.Size.Y * 0.5)
end

local function setCharacterAttribute(name: string, value: any)
	local currentCharacter = character
	if currentCharacter and currentCharacter.Parent then
		currentCharacter:SetAttribute(name, value)
	end
end

local function hasAnyBooleanAttribute(instance: Instance, names: {string}): boolean
	local cursor: Instance? = instance
	while cursor do
		for _, name in names do
			if cursor:GetAttribute(name) == true then
				return true
			end
		end
		cursor = cursor.Parent
	end
	return false
end

local function mantleBlocked(instance: Instance): boolean
	return hasAnyBooleanAttribute(instance, {"NoParkour", "NoClimb", "NoMantle"})
end

local function wallHopBlocked(instance: Instance): boolean
	return hasAnyBooleanAttribute(instance, {"NoParkour", "NoClimb", "NoWallHop"})
end

local function isJumpHeld(): boolean
	return jumpKeyHeld or c.now < jumpPulseExpiresAt
end

local function canUseMovement(): boolean
	local currentCharacter = character
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	return (a.state=="Neutral" or a.state=="Recovery") and not a.reaction and not a.wall
		and currentCharacter ~= nil
		and currentCharacter.Parent ~= nil
		and currentHumanoid ~= nil
		and currentHumanoid.Parent ~= nil
		and currentHumanoid.Health > 0
		and not currentHumanoid.Sit
		and currentRoot ~= nil
		and currentRoot.Parent ~= nil
end

local function clearanceIsOpen(
	targetPosition: Vector3,
	characterHeight: number,
	wallPart: BasePart,
	topPart: BasePart
): boolean
	local params = overlapParams
	if not params then
		return false
	end

	local clearanceSize = Vector3.new(2.35, characterHeight, 1.85)
	local clearanceCenter = targetPosition + Vector3.new(0, characterHeight * 0.5 + 0.14, 0)
	local parts = workspace:GetPartBoundsInBox(CFrame.new(clearanceCenter), clearanceSize, params)
	for _, part in parts do
		if part.CanCollide and part ~= wallPart and part ~= topPart then
			return false
		end
	end
	return true
end

local function findMantleCandidate(): (CFrame?, number?, BasePart?)
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	local params = rayParams
	if not currentHumanoid or not currentRoot or not params then
		return nil, nil, nil
	end

	local moveDirection = horizontal(a.move)
	if moveDirection.Magnitude < 0.12 then
		return nil, nil, nil
	end
	moveDirection = moveDirection.Unit

	local rootOffset = standingRootOffset(currentHumanoid, currentRoot)
	local feetY = currentRoot.Position.Y - rootOffset
	local groundHit = workspace:Raycast(
		currentRoot.Position + Vector3.new(0, 0.1, 0),
		Vector3.new(0, -(rootOffset + 1.25), 0),
		params
	)
	if groundHit and groundHit.Normal.Y > 0.55 then
		feetY = groundHit.Position.Y
	end
	local wallOrigin = Vector3.new(currentRoot.Position.X, feetY + 0.58, currentRoot.Position.Z)
	local wallHit = workspace:Raycast(wallOrigin, moveDirection * MANTLE_REACH, params)
	if not wallHit or not wallHit.Instance:IsA("BasePart") then
		return nil, nil, nil
	end

	local wallPart = wallHit.Instance
	if not wallPart.Anchored or not wallPart.CanCollide or math.abs(wallHit.Normal.Y) > 0.4 then
		return nil, nil, nil
	end
	if mantleBlocked(wallPart) then
		return nil, nil, nil
	end

	local outwardNormal = safeUnit(horizontal(wallHit.Normal), -moveDirection)
	if moveDirection:Dot(-outwardNormal) < 0.45 then
		return nil, nil, nil
	end

	local insidePoint = wallHit.Position - outwardNormal * 1.2
	local topOrigin = Vector3.new(insidePoint.X, feetY + MAX_LEDGE_HEIGHT + 1.4, insidePoint.Z)
	local topHit = workspace:Raycast(topOrigin, Vector3.new(0, -(MAX_LEDGE_HEIGHT + 2.2), 0), params)
	if not topHit or not topHit.Instance:IsA("BasePart") then
		return nil, nil, nil
	end

	local topPart = topHit.Instance
	if not topPart.Anchored or not topPart.CanCollide or topHit.Normal.Y < 0.72 then
		return nil, nil, nil
	end
	if mantleBlocked(topPart) then
		return nil, nil, nil
	end

	local ledgeHeight = topHit.Position.Y - feetY
	if ledgeHeight < MIN_LEDGE_HEIGHT or ledgeHeight > MAX_LEDGE_HEIGHT then
		return nil, nil, nil
	end

	local characterHeight = math.clamp(rootOffset + 2.3, 4.4, 6.7)
	local landingSurfacePosition = topHit.Position - outwardNormal * 0.32
	if not clearanceIsOpen(landingSurfacePosition, characterHeight, wallPart, topPart) then
		return nil, nil, nil
	end

	local targetRootY = topHit.Position.Y + rootOffset + 0.12
	local targetPosition = Vector3.new(landingSurfacePosition.X, targetRootY, landingSurfacePosition.Z)
	local facing = -outwardNormal
	local targetCFrame = CFrame.lookAt(targetPosition, targetPosition + facing)
	return targetCFrame, ledgeHeight, topPart
end

local function restoreMantleOwnership()
	local currentHumanoid = humanoid
	if currentHumanoid and currentHumanoid.Parent then
		if savedWalkSpeed ~= nil then
			currentHumanoid.WalkSpeed = savedWalkSpeed
		end
		if savedAutoRotate ~= nil then
			currentHumanoid.AutoRotate = savedAutoRotate
		end
	end
	savedWalkSpeed = nil
	savedAutoRotate = nil
end

local function finishMantle(reason: string, cancelled: boolean)
	if not traversing then
		return
	end

	local currentHumanoid = humanoid
	local currentRoot = rootPart
	traversing = false
	lastMantleAt = c.now
	setCharacterAttribute("MovementTraversalActive", false)
	setCharacterAttribute("MovementTraversalType", "")
	setCharacterAttribute("MovementTraversalState", if cancelled then "Cancelled" else "Completed")
	setCharacterAttribute("MovementTraversalEndReason", reason)
	restoreMantleOwnership()
 if cancelled and currentHumanoid and currentRoot and currentHumanoid.Health>0 then
  currentHumanoid:ChangeState(if a.grounded then Enum.HumanoidStateType.Running else Enum.HumanoidStateType.Freefall)
 end

	if not cancelled and currentHumanoid and currentRoot and currentHumanoid.Health > 0 then
		currentRoot.CFrame = mantleTargetCFrame
		currentRoot.AssemblyLinearVelocity = horizontal(mantleTargetCFrame.LookVector) * 8 + Vector3.new(0, -1.5, 0)
		currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end

local function startMantle(targetCFrame: CFrame, ledgeHeight: number, topPart: BasePart)
	local currentCharacter = character
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	if traversing or not currentCharacter or not currentHumanoid or not currentRoot then
		return
	end
	if currentCharacter:GetAttribute("MovementSliding") == true then
		return
	end

	traversing = true
	mantleStartCFrame = currentRoot.CFrame
	mantleTargetCFrame = targetCFrame
	mantleStartedAt = c.now
	mantleHeight = ledgeHeight
	mantleDuration = math.clamp(0.22 + ledgeHeight * 0.022, 0.24, 0.36)
	savedWalkSpeed = currentHumanoid.WalkSpeed
	savedAutoRotate = currentHumanoid.AutoRotate
	currentHumanoid.WalkSpeed = 0
	currentHumanoid.AutoRotate = false
	currentHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
	currentRoot.AssemblyLinearVelocity = Vector3.zero

	setCharacterAttribute("MovementTraversalActive", true)
	setCharacterAttribute("MovementTraversalType", "Mantle")
	setCharacterAttribute("MovementTraversalState", "Active")
	setCharacterAttribute("MovementTraversalEndReason", "")
	setCharacterAttribute("MovementMantleHeight", ledgeHeight)
	setCharacterAttribute("MovementMantleDuration", mantleDuration)
	setCharacterAttribute("MovementMantleStartedAt", c.now)
	setCharacterAttribute("MovementMantleSurface", topPart:GetFullName())
end

local function attemptMantle()
	if traversing or not canUseMovement() then
		return
	end
	local currentCharacter = character
	local currentHumanoid = humanoid
	if not currentCharacter or not currentHumanoid then
		return
	end
	if currentCharacter:GetAttribute("MovementSliding") == true
		or currentCharacter:GetAttribute("MovementTraversalActive") == true then
		return
	end
	local slideJumpAt = currentCharacter:GetAttribute("MovementSlideJumpAt")
	if typeof(slideJumpAt) == "number" and c.now - slideJumpAt < 0.32 then
		return
	end
	local state = currentHumanoid:GetState()
	if state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Dead then
		return
	end
	if c.now - lastMantleAt < MANTLE_COOLDOWN then
		return
	end

	local targetCFrame, ledgeHeight, topPart = findMantleCandidate()
	if targetCFrame and ledgeHeight and topPart then
		startMantle(targetCFrame, ledgeHeight, topPart)
	end
end

local function updateMantle(now: number)
	if not traversing then
		return
	end
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	if not canUseMovement() or not currentHumanoid or not currentRoot or currentHumanoid.Health <= 0 then
		finishMantle("CharacterUnavailable", true)
		return
	end

	local normalizedTime = math.clamp((now - mantleStartedAt) / mantleDuration, 0, 1)
	local smoothTime = normalizedTime * normalizedTime * (3 - 2 * normalizedTime)
	local startPosition = mantleStartCFrame.Position
	local targetPosition = mantleTargetCFrame.Position
	local controlPosition = startPosition:Lerp(targetPosition, 0.48)
		+ Vector3.new(0, math.max(0.8, mantleHeight * 0.24), 0)
	local inverse = 1 - smoothTime
	local position = startPosition * (inverse * inverse)
		+ controlPosition * (2 * inverse * smoothTime)
		+ targetPosition * (smoothTime * smoothTime)

	local startFacing = safeUnit(horizontal(mantleStartCFrame.LookVector), horizontal(mantleTargetCFrame.LookVector))
	local targetFacing = safeUnit(horizontal(mantleTargetCFrame.LookVector), startFacing)
	local facing = safeUnit(startFacing:Lerp(targetFacing, smoothTime), targetFacing)
	currentHumanoid.WalkSpeed = 0
	currentHumanoid.AutoRotate = false
	currentRoot.AssemblyLinearVelocity = Vector3.zero
	position=c:clamp(position)
	currentRoot.CFrame = CFrame.lookAt(position, position + facing)

	if normalizedTime >= 1 then
		finishMantle("Completed", false)
	end
end

local function appendUniqueDirection(directions: {Vector3}, candidate: Vector3)
	candidate = horizontal(candidate)
	if candidate.Magnitude < 0.1 then
		return
	end
	candidate = candidate.Unit
	for _, direction in directions do
		if direction:Dot(candidate) > 0.96 then
			return
		end
	end
	table.insert(directions, candidate)
end

local function findWallHopSurface(): RaycastResult?
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	local params = rayParams
	if not currentHumanoid or not currentRoot or not params then
		return nil
	end

	local directions: {Vector3} = {}
	local look = horizontal(currentRoot.CFrame.LookVector)
	local right = horizontal(currentRoot.CFrame.RightVector)
	local velocity = horizontal(currentRoot.AssemblyLinearVelocity)
	appendUniqueDirection(directions, currentHumanoid.MoveDirection)
	appendUniqueDirection(directions, velocity)
	appendUniqueDirection(directions, look)
	appendUniqueDirection(directions, -look)
	appendUniqueDirection(directions, right)
	appendUniqueDirection(directions, -right)
	appendUniqueDirection(directions, -velocity)

	local bestHit: RaycastResult? = nil
	local bestDistance = math.huge
	local origin = currentRoot.Position + Vector3.new(0, 0.25, 0)
	for _, direction in directions do
		local hit = workspace:Raycast(origin, direction * WALL_HOP_REACH, params)
		if hit and hit.Instance:IsA("BasePart") then
			local part = hit.Instance
			local distance = (hit.Position - origin).Magnitude
			if part.Anchored and part.CanCollide and math.abs(hit.Normal.Y) < 0.35
				and not wallHopBlocked(part) and distance < bestDistance then
				bestHit = hit
				bestDistance = distance
			end
		end
	end
	return bestHit
end

local function attemptWallHop(forcedNormal: Vector3?)
	if traversing or wallHopCount >= MAX_WALL_HOPS or not canUseMovement() then
		return
	end
	local currentCharacter = character
	local currentHumanoid = humanoid
	local currentRoot = rootPart
	if not currentCharacter or not currentHumanoid or not currentRoot then
		return
	end
	if currentCharacter:GetAttribute("MovementSliding") == true
		or currentCharacter:GetAttribute("MovementTraversalActive") == true then
		return
	end
	local now = c.now
	if (not forcedNormal and (currentHumanoid.FloorMaterial ~= Enum.Material.Air or now - lastGroundedAt < 0.13))
		or now - lastWallHopAt < WALL_HOP_COOLDOWN then
		return
	end

	local hit = findWallHopSurface()
	if not forcedNormal and (not hit or not hit.Instance:IsA("BasePart")) then
		return
	end

	local away = safeUnit(horizontal(forcedNormal or hit.Normal), -horizontal(currentRoot.CFrame.LookVector))
	local currentHorizontal = horizontal(currentRoot.AssemblyLinearVelocity)
	local tangentCarry = currentHorizontal - away * currentHorizontal:Dot(away)
	if tangentCarry.Magnitude > 28 then
		tangentCarry = tangentCarry.Unit * 28
	end

	wallHopCount += 1
	lastWallHopAt = now
	currentHumanoid.JumpPower = WALL_HOP_UP_SPEED
	currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	currentRoot.AssemblyLinearVelocity = away * WALL_HOP_AWAY_SPEED
		+ tangentCarry * 0.55
		+ Vector3.new(0, WALL_HOP_UP_SPEED, 0)
	setCharacterAttribute("MovementWallHopCount", wallHopCount)
	setCharacterAttribute("MovementLastWallHopAt", c.now)
	setCharacterAttribute("MovementLastWallHopSurface", if hit then hit.Instance:GetFullName() else "NinjaWall")
	a.airborne=true;a.airDodgeUsed=false;a.takeoffUntil=c.now+.18
	return true
end


 local api={}
 function api.jump()
  jumpPulseExpiresAt=c.now+.34
  attemptMantle()
  if traversing then return true end
  return attemptWallHop()==true
 end
 function api.rebound(normal) return attemptWallHop(normal)==true end
 function api.wallSurface() return findWallHopSurface() end
 function api.step()
  if a.grounded then lastGroundedAt=c.now;wallHopCount=0 end
  updateMantle(c.now)
  if not traversing and isJumpHeld() and c.now-lastMantleCheckAt>=MANTLE_CHECK_INTERVAL then
   lastMantleCheckAt=c.now;attemptMantle()
  end
  if traversing then a.airborne=true;a.hum:Move(Vector3.zero);a.locomotion=Vector3.zero end
  return traversing
 end
 function api.reset() finishMantle('SessionReset',true);wallHopCount=0;jumpPulseExpiresAt=0 end
 return api
end
return Parkour
