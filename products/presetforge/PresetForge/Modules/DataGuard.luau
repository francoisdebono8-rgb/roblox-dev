local Constants = require(script.Parent.Constants)
local Guard = {}

function Guard.array(value, limit)
	if type(value) ~= "table" or #value > limit then return false end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #value then return false end
		count += 1
	end
	return count == #value
end

function Guard.data(value)
	local seen, nodes, bytes = {}, 0, 0
	local function walk(item, depth)
		nodes += 1
		if depth > 16 or nodes > 200000 then return false end
		if type(item) == "string" then
			bytes += #item
			return #item <= Constants.MAX_STRING_BYTES * 2 and bytes <= Constants.MAX_PERSISTED_BYTES
		elseif type(item) == "number" then
			return item == item and math.abs(item) < math.huge
		elseif type(item) == "boolean" then return true
		elseif type(item) ~= "table" or seen[item] or getmetatable(item) ~= nil then return false end
		seen[item] = true
		for key, child in pairs(item) do
			if (type(key) ~= "string" and type(key) ~= "number") or not walk(key, depth + 1) or not walk(child, depth + 1) then return false end
		end
		return true
	end
	return walk(value, 0)
end

function Guard.indexed(value, limit)
	if type(value) ~= "table" or type(value.count) ~= "number" or value.count % 1 ~= 0
		or value.count < 0 or value.count > limit or type(value.items) ~= "table" then return false end
	local count, seen = 0, {}
	for key in pairs(value.items) do
		local index = tonumber(key)
		if not index or index % 1 ~= 0 or index < 1 or index > value.count
			or (type(key) == "string" and tostring(index) ~= key) or seen[index] then return false end
		seen[index] = true; count += 1
	end
	return count == value.count
end

function Guard.copy(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in pairs(value) do copy[key] = Guard.copy(child) end
	return copy
end

function Guard.freeze(value)
	if type(value) ~= "table" or table.isfrozen(value) then return value end
	for _, child in pairs(value) do Guard.freeze(child) end
	return table.freeze(value)
end

function Guard.equal(left, right)
	if type(left) ~= type(right) then return false end
	if type(left) ~= "table" then return left == right end
	for key, value in pairs(left) do if not Guard.equal(value, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end
	return true
end

return Guard
