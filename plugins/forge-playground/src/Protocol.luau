local Catalog = require(game:GetService("ReplicatedStorage").ForgePlayground.Catalog)
local Protocol = {}
local actions = { visit = true, run = true, configure = true, apply = true, select = true, reset = true, pick = true, perturb = true }

function Protocol.validate(action, id, options, index)
	if type(action) ~= "string" or not actions[action] then return false end
	if type(id) ~= "string" or not Catalog.stations[id] then return false end
	if action == "select" or action == "pick" then
		if type(index) ~= "number" or index ~= index or index % 1 ~= 0 or index < 1 or index > 256 then return false end
	elseif index ~= nil then return false end
	if action == "perturb" and id ~= "preset" then return false end
	if type(options) ~= "table" then return false end
	local fields = Catalog.stations[id].controls
	local count = 0
	for key in pairs(options) do
		count += 1
		if type(key) ~= "string" or count > #fields then return false end
		local found = false
		for _, field in ipairs(fields) do if field.key == key then found = true; break end end
		if not found then return false end
	end
	for _, field in ipairs(fields) do
		local value = options[field.key]
		if field.kind == "toggle" then
			if type(value) ~= "boolean" then return false end
		elseif field.kind == "choice" then
			if type(value) ~= "string" or not table.find(field.values, value) then return false end
		else
			if type(value) ~= "number" or value ~= value or value < field.min or value > field.max then return false end
			if (value - field.min) % field.step ~= 0 then return false end
		end
	end
	return true
end

function Protocol.allow(bucket, now)
	local elapsed = math.max(0, now - bucket.time)
	bucket.tokens = math.min(4, bucket.tokens + elapsed * 3)
	bucket.time = now
	if bucket.tokens < 1 then return false end
	bucket.tokens -= 1
	return true
end

return Protocol
