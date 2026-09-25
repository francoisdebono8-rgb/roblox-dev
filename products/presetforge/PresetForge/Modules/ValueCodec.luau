local AttributeCodec = require(script.Parent.AttributeCodec)

local ValueCodec = {}

local function deepEqual(left, right)
	if type(left) ~= type(right) then
		return false
	elseif type(left) == "number" then
		return math.abs(left - right) <= 1e-6
	elseif type(left) ~= "table" then
		return left == right
	end
	for key, value in pairs(left) do
		if not deepEqual(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

function ValueCodec.encode(definition, value)
	if definition.kind == "EnumItem" then
		return {
			kind = "EnumItem",
			enumType = definition.enumType,
			item = value.Name,
		}
	end
	return AttributeCodec.encode(value)
end

function ValueCodec.decode(definition, encoded)
	if definition.kind == "EnumItem" then
		if type(encoded) ~= "table"
			or encoded.kind ~= "EnumItem"
			or encoded.enumType ~= definition.enumType
			or type(encoded.item) ~= "string" then
			return nil, "Invalid encoded enum"
		end
		local enumType = Enum[definition.enumType]
		local value = enumType and enumType[encoded.item] or nil
		if not value then
			return nil, "Unknown enum item"
		end
		return value
	end
	return AttributeCodec.decode(encoded)
end

function ValueCodec.equal(definition, left, right)
	local leftEncoded = ValueCodec.encode(definition, left)
	local rightEncoded = ValueCodec.encode(definition, right)
	return leftEncoded ~= nil and rightEncoded ~= nil and deepEqual(leftEncoded, rightEncoded)
end

function ValueCodec.equalAny(left, right)
	if left == nil or right == nil then
		return left == right
	end
	if typeof(left) == "EnumItem" or typeof(right) == "EnumItem" then
		return left == right
	end
	return AttributeCodec.equal(left, right)
end

function ValueCodec.toProjectAttribute(definition, value)
	if definition.kind == "EnumItem" then
		return string.format("Enum.%s.%s", definition.enumType, value.Name)
	end
	return value
end

function ValueCodec.fromProjectAttribute(definition, value)
	if definition.kind ~= "EnumItem" then
		return value
	end
	if type(value) ~= "string" then
		return nil, "Enum project value must be a string"
	end
	local enumTypeName, itemName = value:match("^Enum%.([%w_]+)%.([%w_]+)$")
	if enumTypeName ~= definition.enumType then
		return nil, "Enum project value has the wrong type"
	end
	local enumType = Enum[definition.enumType]
	local item = enumType and enumType[itemName] or nil
	if not item then
		return nil, "Enum project value has an unknown item"
	end
	return item
end

return ValueCodec
