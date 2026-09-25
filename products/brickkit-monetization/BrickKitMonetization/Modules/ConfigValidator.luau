local ConfigValidator = {}

local ALLOWED_FIELDS = {
	enabled = true,
	type = true,
	id = true,
	fallbackLabel = true,
	rewardHandler = true,
	params = true,
}

local ALLOWED_TYPES = {
	DeveloperProduct = true,
	GamePass = true,
}

local function isPositiveInteger(value)
	return type(value) == "number"
		and value > 0
		and value % 1 == 0
		and value < math.huge
end

local function addIssue(issues, index, message)
	table.insert(issues, {
		index = index,
		message = message,
	})
end

function ConfigValidator.validate(entries, handlerExists)
	local activeEntries = {}
	local issues = {}
	local seenIds = {}

	if type(entries) ~= "table" then
		addIssue(issues, 0, "Config must return an array of entries")
		return activeEntries, issues
	end

	for index, entry in ipairs(entries) do
		local valid = true

		if type(entry) ~= "table" then
			addIssue(issues, index, "Entry must be a table")
			continue
		end

		for field in pairs(entry) do
			if not ALLOWED_FIELDS[field] then
				valid = false
				addIssue(issues, index, "Unknown field: " .. tostring(field))
			end
		end

		if type(entry.enabled) ~= "boolean" then
			valid = false
			addIssue(issues, index, "enabled must be a boolean")
		end

		if not ALLOWED_TYPES[entry.type] then
			valid = false
			addIssue(issues, index, "type must be DeveloperProduct or GamePass")
		end

		if not isPositiveInteger(entry.id) then
			valid = false
			addIssue(issues, index, "id must be a positive integer")
		end

		if type(entry.fallbackLabel) ~= "string" or entry.fallbackLabel == "" then
			valid = false
			addIssue(issues, index, "fallbackLabel must be a non-empty string")
		end

		if type(entry.rewardHandler) ~= "string" or entry.rewardHandler == "" then
			valid = false
			addIssue(issues, index, "rewardHandler must be a non-empty string")
		elseif type(handlerExists) ~= "function" or not handlerExists(entry.rewardHandler) then
			valid = false
			addIssue(issues, index, "Unknown reward handler: " .. entry.rewardHandler)
		elseif entry.type == "GamePass" and entry.rewardHandler == "LeaderstatIncrement" then
			valid = false
			addIssue(issues, index, "LeaderstatIncrement is not idempotent and cannot be used for a Game Pass")
		elseif entry.type == "DeveloperProduct" and entry.rewardHandler == "WalkSpeedMinimum" then
			valid = false
			addIssue(issues, index, "WalkSpeedMinimum is reserved for Game Pass entries")
		end

		if type(entry.params) ~= "table" then
			valid = false
			addIssue(issues, index, "params must be a table")
		end

		if ALLOWED_TYPES[entry.type] and isPositiveInteger(entry.id) then
			local key = entry.type .. ":" .. tostring(entry.id)
			if seenIds[key] then
				valid = false
				addIssue(issues, index, "Duplicate type and id")
			else
				seenIds[key] = true
			end
		end

		if valid and entry.enabled then
			table.insert(activeEntries, entry)
		end
	end

	return activeEntries, issues
end

return ConfigValidator
