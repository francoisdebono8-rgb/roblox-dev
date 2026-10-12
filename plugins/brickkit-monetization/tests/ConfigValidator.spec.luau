local modules = script.Parent.Parent.BrickKitMonetization.Modules
local ConfigValidator = require(modules.ConfigValidator)

local function handlerExists(name)
	return name == "KnownHandler" or name == "LeaderstatIncrement"
end

local active = ConfigValidator.validate({
	{
		enabled = true,
		type = "DeveloperProduct",
		id = 123,
		fallbackLabel = "Valid",
		rewardHandler = "KnownHandler",
		params = {},
	},
}, handlerExists)
assert(#active == 1, "valid config should be active")

local invalidActive, invalidIssues = ConfigValidator.validate({
	{
		enabled = true,
		type = "DeveloperProduct",
		id = 0,
		fallbackLabel = "Invalid ID",
		rewardHandler = "KnownHandler",
		params = {},
	},
	{
		enabled = true,
		type = "GamePass",
		id = 456,
		fallbackLabel = "Unknown handler",
		rewardHandler = "MissingHandler",
		params = {},
	},
	{
		enabled = true,
		type = "GamePass",
		id = 789,
		fallbackLabel = "Unsafe built-in",
		rewardHandler = "LeaderstatIncrement",
		params = {},
	},
}, handlerExists)

assert(#invalidActive == 0, "invalid entries must be disabled")
assert(#invalidIssues >= 3, "invalid config, unknown handlers, and unsafe combinations must be reported")

return true
