local modules = script.Parent.Parent.BrickKitMonetization.Modules
local BuiltInRewards = require(modules.BuiltInRewards)

local stat = {
	Value = 10,
	IsA = function(_, className)
		return className == "IntValue"
	end,
}
local leaderstats = {
	FindFirstChild = function(_, name)
		return name == "Coins" and stat or nil
	end,
}
local humanoid = { WalkSpeed = 16 }
local character = {
	FindFirstChildOfClass = function(_, className)
		return className == "Humanoid" and humanoid or nil
	end,
}
local player = {
	Character = character,
	FindFirstChild = function(_, name)
		return name == "leaderstats" and leaderstats or nil
	end,
}

local increment = BuiltInRewards.resolve("LeaderstatIncrement")
assert(increment(player, { statName = "Coins", amount = 5 }) == true)
assert(stat.Value == 15, "LeaderstatIncrement must use server params")

local speed = BuiltInRewards.resolve("WalkSpeedMinimum")
assert(speed(player, { minimum = 24 }) == true)
assert(speed(player, { minimum = 24 }) == true)
assert(humanoid.WalkSpeed == 24, "WalkSpeedMinimum must be idempotent")

return true
