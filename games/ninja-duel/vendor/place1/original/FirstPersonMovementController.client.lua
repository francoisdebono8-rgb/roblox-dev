local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WALK_SPEED = 18
local SPRINT_SPEED = 44
local MOVEMENT_GRAVITY = 105
local JUMP_VERTICAL_SPEED = 60
local WALK_BHOP_SPEED = 36
local SPRINT_BHOP_SPEED = 62
local SLIDE_JUMP_CARRY_TIME = 0.85
local STAMINA_DRAIN_SECONDS = 60
local STAMINA_REGEN_SECONDS = 18
local STAMINA_REGEN_DELAY = 0.85
local EXHAUSTED_RECOVERY = 0.12

local AIR_CONTROL_ACCELERATION = 72
local AIR_ACCELERATION_SPEED_CAP = 72
local MOMENTUM_CARRY_CAP = 120

local CAMERA_FOV_GAIN = 10
local CAMERA_BOB_X = 0.035
local CAMERA_BOB_Y = 0.055
local CAMERA_ROLL_DEGREES = 1.5

local PACKAGE_ID = "Place1MovementSystem"
local UI_NAME = "Place1MovementStamina"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local originalCameraMode = player.CameraMode
local originalMinZoom = player.CameraMinZoomDistance
local originalMaxZoom = player.CameraMaxZoomDistance
local originalGravity = Workspace.Gravity

local currentCharacter = nil
local currentHumanoid = nil
local currentRoot = nil
local originalWalkSpeed = nil
local originalUseJumpPower = nil
local originalJumpPower = nil
local characterGeneration = 0
local characterConnections = {}
local globalConnections = {}

local stamina = 1
local regenDelayRemaining = 0
local exhausted = false
local sprinting = false
local lastGroundHorizontalVelocity = Vector3.zero
local lastJumpRequestAt = -math.huge

local sprintInputs = {
	[Enum.KeyCode.LeftShift] = false,
	[Enum.KeyCode.RightShift] = false,
	[Enum.KeyCode.ButtonL3] = false,
}

local jumpInputs = {
	[Enum.KeyCode.Space] = false,
	[Enum.KeyCode.ButtonA] = false,
}

local function anyHeld(inputTable)
	for _, held in pairs(inputTable) do
		if held then
			return true
		end
	end
	return false
end

local function clearHeldInputs()
	for keyCode in pairs(sprintInputs) do
		sprintInputs[keyCode] = false
	end
	for keyCode in pairs(jumpInputs) do
		jumpInputs[keyCode] = false
	end
end

local function movementIsBlocked(character)
	return character:GetAttribute("MovementSliding") == true
		or character:GetAttribute("MovementTraversalActive") == true
end

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

local function setCharacterAttribute(name, value)
	local character = currentCharacter
	if character and character.Parent then
		character:SetAttribute(name, value)
	end
end

local previousUi = playerGui:FindFirstChild(UI_NAME)
if previousUi and previousUi:GetAttribute("MovementPackageId") == PACKAGE_ID then
	previousUi:Destroy()
end

local staminaGui = Instance.new("ScreenGui")
staminaGui.Name = UI_NAME
staminaGui.IgnoreGuiInset = true
staminaGui.ResetOnSpawn = false
staminaGui.DisplayOrder = 20
staminaGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
staminaGui:SetAttribute("MovementPackageId", PACKAGE_ID)

local staminaTrack = Instance.new("Frame")
staminaTrack.Name = "Track"
staminaTrack.AnchorPoint = Vector2.new(0.5, 0.5)
staminaTrack.Position = UDim2.fromScale(0.5, 0.555)
staminaTrack.Size = UDim2.fromOffset(124, 2)
staminaTrack.BorderSizePixel = 0
staminaTrack.BackgroundColor3 = Color3.new(1, 1, 1)
staminaTrack.BackgroundTransparency = 0.86
staminaTrack.Parent = staminaGui

local staminaFill = Instance.new("Frame")
staminaFill.Name = "Fill"
staminaFill.Size = UDim2.fromScale(1, 1)
staminaFill.BorderSizePixel = 0
staminaFill.BackgroundColor3 = Color3.new(1, 1, 1)
staminaFill.BackgroundTransparency = 0.38
staminaFill.Parent = staminaTrack

staminaGui.Parent = playerGui

local function disconnectCharacter()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)

	if currentCharacter and currentCharacter.Parent then
		currentCharacter:SetAttribute("MovementSprinting", false)
		currentCharacter:SetAttribute("MovementGroundSpeed", 0)
	end

	if currentHumanoid and currentHumanoid.Parent and originalWalkSpeed then
		local ownsCurrentSpeed = math.abs(currentHumanoid.WalkSpeed - WALK_SPEED) < 0.05
			or math.abs(currentHumanoid.WalkSpeed - SPRINT_SPEED) < 0.05
		if ownsCurrentSpeed and currentCharacter and not movementIsBlocked(currentCharacter) then
			currentHumanoid.WalkSpeed = originalWalkSpeed
		end
		if originalUseJumpPower ~= nil and originalJumpPower ~= nil then
			currentHumanoid.UseJumpPower = originalUseJumpPower
			currentHumanoid.JumpPower = originalJumpPower
		end
	end

	currentCharacter = nil
	currentHumanoid = nil
	currentRoot = nil
	originalWalkSpeed = nil
	originalUseJumpPower = nil
	originalJumpPower = nil
	stamina = 1
	regenDelayRemaining = 0
	exhausted = false
	sprinting = false
	lastGroundHorizontalVelocity = Vector3.zero
	lastJumpRequestAt = -math.huge
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

local function attachCharacter(character)
	characterGeneration += 1
	local generation = characterGeneration
	disconnectCharacter()

	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if generation ~= characterGeneration or player.Character ~= character then
		return
	end
	if not humanoid or not humanoid:IsA("Humanoid") or not root or not root:IsA("BasePart") then
		return
	end

	currentCharacter = character
	currentHumanoid = humanoid
	currentRoot = root
	originalWalkSpeed = humanoid.WalkSpeed
	originalUseJumpPower = humanoid.UseJumpPower
	originalJumpPower = humanoid.JumpPower
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JUMP_VERTICAL_SPEED
	stamina = 1
	regenDelayRemaining = 0
	exhausted = false
	sprinting = false
	lastGroundHorizontalVelocity = horizontalOf(root.AssemblyLinearVelocity)
	lastJumpRequestAt = -math.huge

	character:SetAttribute("MovementSprinting", false)
	character:SetAttribute("MovementStamina", stamina)
	character:SetAttribute("MovementGroundSpeed", lastGroundHorizontalVelocity.Magnitude)
	character:SetAttribute("MovementLastJumpAt", 0)
	character:SetAttribute("MovementLastJumpHorizontalSpeed", 0)
	character:SetAttribute("MovementLastJumpVerticalSpeed", 0)
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	table.insert(characterConnections, humanoid.StateChanged:Connect(function(_, newState)
		if currentCharacter ~= character then
			return
		end
		if newState == Enum.HumanoidStateType.Jumping then
			preserveTakeoffMomentum()
			if currentRoot and not movementIsBlocked(character) then
				local velocity = currentRoot.AssemblyLinearVelocity
				if velocity.Y < JUMP_VERTICAL_SPEED then
					currentRoot.AssemblyLinearVelocity = Vector3.new(
						velocity.X,
						JUMP_VERTICAL_SPEED,
						velocity.Z
					)
				end
			end
			task.defer(function()
				if currentCharacter == character and currentRoot and currentRoot.Parent then
					local velocity = currentRoot.AssemblyLinearVelocity
					character:SetAttribute("MovementLastJumpAt", Workspace:GetServerTimeNow())
					character:SetAttribute(
						"MovementLastJumpHorizontalSpeed",
						horizontalOf(velocity).Magnitude
					)
					character:SetAttribute("MovementLastJumpVerticalSpeed", velocity.Y)
				end
			end)
		elseif newState == Enum.HumanoidStateType.Freefall then
			preserveTakeoffMomentum()
		end
	end))

	table.insert(characterConnections, humanoid.Died:Connect(function()
		if currentCharacter == character then
			sprinting = false
			character:SetAttribute("MovementSprinting", false)
		end
	end))
end

local function applyAirControl(deltaTime, desiredSprint)
	local root = currentRoot
	local humanoid = currentHumanoid
	if not root or not humanoid then
		return
	end

	local moveDirection = horizontalOf(humanoid.MoveDirection)
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

local function preserveSlideJumpMomentum()
	local character = currentCharacter
	local root = currentRoot
	if not character or not root then
		return
	end

	local jumpAt = character:GetAttribute("MovementSlideJumpAt")
	local reportedSpeed = character:GetAttribute("MovementSlideJumpSpeed")
	local reportedDirection = character:GetAttribute("MovementSlideJumpDirection")
	if typeof(jumpAt) ~= "number" or typeof(reportedSpeed) ~= "number"
		or typeof(reportedDirection) ~= "Vector3" or reportedSpeed <= 0 then
		return
	end

	local age = Workspace:GetServerTimeNow() - jumpAt
	if age < 0 or age > SLIDE_JUMP_CARRY_TIME then
		return
	end

	local progress = math.clamp(age / SLIDE_JUMP_CARRY_TIME, 0, 1)
	local targetSpeed = reportedSpeed * (1.05 + (1 - 1.05) * progress)
	local velocity = root.AssemblyLinearVelocity
	local currentHorizontal = horizontalOf(velocity)
	local currentSpeed = currentHorizontal.Magnitude
	if currentSpeed >= targetSpeed or currentSpeed <= targetSpeed * 0.28 then
		return
	end

	local direction = if currentSpeed > 0.1
		then currentHorizontal.Unit
		else horizontalOf(reportedDirection).Unit
	local carried = direction * targetSpeed
	root.AssemblyLinearVelocity = Vector3.new(carried.X, velocity.Y, carried.Z)
	character:SetAttribute("MovementSlideJumpCarrySpeed", targetSpeed)
end

local function requestGroundJump()
	local character = currentCharacter
	local humanoid = currentHumanoid
	local root = currentRoot
	if not character or not humanoid or not root or movementIsBlocked(character)
		or humanoid.Health <= 0 or humanoid.FloorMaterial == Enum.Material.Air then
		return
	end
	local now = os.clock()
	if now - lastJumpRequestAt < 0.12 then
		return
	end
	lastJumpRequestAt = now

	local jumpDirection = horizontalOf(humanoid.MoveDirection)
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
	humanoid.Jump = true
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	local takeoffVelocity = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(
		takeoffVelocity.X,
		math.max(takeoffVelocity.Y, JUMP_VERTICAL_SPEED),
		takeoffVelocity.Z
	)
	character:SetAttribute("MovementLastJumpAt", Workspace:GetServerTimeNow())
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
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local horizontalVelocity = horizontalOf(root.AssemblyLinearVelocity)
	local groundSpeed = horizontalVelocity.Magnitude
	local hasMoveInput = humanoid.MoveDirection.Magnitude > 0.05
	local wantsSprint = anyHeld(sprintInputs) and hasMoveInput

	if grounded then
		lastGroundHorizontalVelocity = horizontalVelocity
	end

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

	if not blocked then
		local desiredWalkSpeed = sprinting and SPRINT_SPEED or WALK_SPEED
		if math.abs(humanoid.WalkSpeed - desiredWalkSpeed) > 0.01 then
			humanoid.WalkSpeed = desiredWalkSpeed
		end

		if anyHeld(jumpInputs) and grounded then
			requestGroundJump()
		end

		if not grounded then
			applyAirControl(deltaTime, sprinting)
			preserveSlideJumpMomentum()
		end
	end

	setCharacterAttribute("MovementSprinting", sprinting)
	setCharacterAttribute("MovementStamina", stamina)
	setCharacterAttribute("MovementGroundSpeed", groundSpeed)
end

table.insert(globalConnections, UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard and UserInputService:GetFocusedTextBox() then
		return
	end
	if sprintInputs[input.KeyCode] ~= nil then
		sprintInputs[input.KeyCode] = true
	end
	if jumpInputs[input.KeyCode] ~= nil then
		jumpInputs[input.KeyCode] = true
		requestGroundJump()
	end
end))

table.insert(globalConnections, UserInputService.InputEnded:Connect(function(input)
	if sprintInputs[input.KeyCode] ~= nil then
		sprintInputs[input.KeyCode] = false
	end
	if jumpInputs[input.KeyCode] ~= nil then
		jumpInputs[input.KeyCode] = false
	end
end))

table.insert(globalConnections, UserInputService.WindowFocusReleased:Connect(clearHeldInputs))
table.insert(globalConnections, UserInputService.JumpRequest:Connect(requestGroundJump))

table.insert(globalConnections, player.CharacterAdded:Connect(function(character)
	task.spawn(attachCharacter, character)
end))

table.insert(globalConnections, player.CharacterRemoving:Connect(function(character)
	if character == currentCharacter then
		characterGeneration += 1
		disconnectCharacter()
	end
end))

table.insert(globalConnections, RunService.Stepped:Connect(function(_, deltaTime)
	updateMovement(math.min(deltaTime, 0.1))
end))

local renderBindingName = "Place1FirstPersonMovement_" .. tostring(player.UserId)
local lastCamera = nil
local baseFieldOfView = nil
local bobPhase = 0
local smoothedBob = Vector3.zero
local smoothedRoll = 0
local smoothedPitch = 0

RunService:BindToRenderStep(renderBindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	local frameTime = math.min(deltaTime, 0.1)
	local uiAlpha = 1 - math.exp(-12 * frameTime)
	staminaFill.Size = UDim2.new(math.clamp(stamina, 0, 1), 0, 1, 0)
	local targetTransparency = sprinting and 0.24 or 0.38
	staminaFill.BackgroundTransparency += (targetTransparency - staminaFill.BackgroundTransparency) * uiAlpha

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if camera ~= lastCamera then
		lastCamera = camera
		baseFieldOfView = camera.FieldOfView
	end

	local character = currentCharacter
	local humanoid = currentHumanoid
	local root = currentRoot
	if not character or not humanoid or not root or humanoid.Health <= 0 then
		if baseFieldOfView and camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.FieldOfView += (baseFieldOfView - camera.FieldOfView) * (1 - math.exp(-8 * frameTime))
		end
		return
	end

	if movementIsBlocked(character) or camera.CameraType == Enum.CameraType.Scriptable then
		smoothedBob = Vector3.zero
		smoothedRoll = 0
		smoothedPitch = 0
		return
	end

	local horizontalVelocity = horizontalOf(root.AssemblyLinearVelocity)
	local speed = horizontalVelocity.Magnitude
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	local moving = humanoid.MoveDirection.Magnitude > 0.05 and speed > 0.5
	local intensity = grounded and moving and math.clamp(speed / SPRINT_SPEED, 0, 1) or 0

	bobPhase += frameTime * (7 + math.min(speed, SPRINT_SPEED) * 0.24)
	local targetBob = Vector3.new(
		math.cos(bobPhase) * CAMERA_BOB_X * intensity,
		math.sin(bobPhase * 2) * CAMERA_BOB_Y * intensity,
		0
	)
	local localVelocity = camera.CFrame:VectorToObjectSpace(horizontalVelocity)
	local targetRoll = -math.clamp(localVelocity.X / SPRINT_SPEED, -1, 1)
		* math.rad(CAMERA_ROLL_DEGREES)
	local targetPitch = math.sin(bobPhase * 2) * math.rad(0.22) * intensity
	local cameraAlpha = 1 - math.exp(-14 * frameTime)
	smoothedBob = smoothedBob:Lerp(targetBob, cameraAlpha)
	smoothedRoll += (targetRoll - smoothedRoll) * cameraAlpha
	smoothedPitch += (targetPitch - smoothedPitch) * cameraAlpha

	camera.CFrame = camera.CFrame
		* CFrame.new(smoothedBob)
		* CFrame.Angles(smoothedPitch, 0, smoothedRoll)
	if baseFieldOfView then
		local targetFov = baseFieldOfView + math.clamp(speed / SPRINT_SPEED, 0, 1) * CAMERA_FOV_GAIN
		camera.FieldOfView += (targetFov - camera.FieldOfView) * (1 - math.exp(-7 * frameTime))
	end
end)

player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 0.5
Workspace.Gravity = MOVEMENT_GRAVITY

if player.Character then
	task.spawn(attachCharacter, player.Character)
end

table.insert(globalConnections, script.Destroying:Connect(function()
	characterGeneration += 1
	disconnectCharacter()
	clearHeldInputs()
	RunService:UnbindFromRenderStep(renderBindingName)

	for _, connection in ipairs(globalConnections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(globalConnections)

	if staminaGui.Parent and staminaGui:GetAttribute("MovementPackageId") == PACKAGE_ID then
		staminaGui:Destroy()
	end
	if lastCamera and baseFieldOfView and lastCamera.Parent then
		lastCamera.FieldOfView = baseFieldOfView
	end
	player.CameraMode = originalCameraMode
	player.CameraMinZoomDistance = originalMinZoom
	player.CameraMaxZoomDistance = originalMaxZoom
	if math.abs(Workspace.Gravity - MOVEMENT_GRAVITY) < 0.01 then
		Workspace.Gravity = originalGravity
	end
end))
