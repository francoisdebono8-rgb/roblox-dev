local BuiltInRewards = {}

local function isFinitePositiveNumber(value)
	return type(value) == "number"
		and value > 0
		and value < math.huge
		and value == value
end

local handlers = {}

function handlers.LeaderstatIncrement(player, params)
	if type(params) ~= "table"
		or type(params.statName) ~= "string"
		or params.statName == ""
		or not isFinitePositiveNumber(params.amount)
	then
		return false, "Invalid LeaderstatIncrement params"
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(params.statName)
	if not stat or (not stat:IsA("IntValue") and not stat:IsA("NumberValue")) then
		return false, "Configured leaderstat was not found or is not numeric"
	end

	stat.Value += params.amount
	return true
end

function handlers.WalkSpeedMinimum(player, params)
	if type(params) ~= "table" or not isFinitePositiveNumber(params.minimum) then
		return false, "Invalid WalkSpeedMinimum params"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false, "Humanoid is not available"
	end

	humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, params.minimum)
	return true
end

function BuiltInRewards.resolve(name)
	return handlers[name]
end

function BuiltInRewards.exists(name)
	return handlers[name] ~= nil
end

return BuiltInRewards
