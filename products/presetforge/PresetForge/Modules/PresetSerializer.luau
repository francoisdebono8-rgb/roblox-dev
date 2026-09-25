local AttributeCodec = require(script.Parent.AttributeCodec)
local Constants = require(script.Parent.Constants)
local PresetValidator = require(script.Parent.PresetValidator)
local StringCodec = require(script.Parent.StringCodec)

local PresetSerializer = {}

local function indexed(items)
	local container = { count = #items, items = {} }
	for index, value in ipairs(items) do
		container.items[tostring(index)] = value
	end
	return container
end

local function readIndexed(container, index)
	if type(container) ~= "table" or type(container.items) ~= "table" then
		return nil
	end
	return container.items[tostring(index)] or container.items[index]
end

local function validCount(container)
	return type(container) == "table"
		and type(container.count) == "number"
		and container.count >= 0
		and container.count % 1 == 0
		and container.count <= 10000
end

local function sortedKeys(values)
	local keys = {}
	for key in pairs(values) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local function validProperty(propertyName, value)
	if propertyName == "Transparency" then
		return type(value) == "number" and value >= 0 and value <= 1
	end
	return type(value) == "boolean"
end

local function deepEqual(left, right)
	if type(left) ~= type(right) then
		return false
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

function PresetSerializer.encodePreset(preset)
	local name, nameError = PresetValidator.normalizeName(preset.name)
	if not name then
		return nil, nameError
	end

	local validOptions, optionsError = PresetValidator.captureOptions(preset.capture)
	if not validOptions then
		return nil, optionsError
	end

	local properties = {}
	if preset.capture.properties then
		if type(preset.properties) ~= "table" then
			return nil, "Missing captured properties"
		end
		for _, propertyName in ipairs(Constants.PROPERTIES) do
			local value = preset.properties[propertyName]
			if not validProperty(propertyName, value) then
				return nil, "Invalid captured property: " .. propertyName
			end
			properties[propertyName] = value
		end
	end

	local tags = {}
	if preset.capture.tags then
		if type(preset.tags) ~= "table" then
			return nil, "Missing captured tags"
		end
		for _, tag in ipairs(preset.tags) do
			if type(tag) ~= "string" then
				return nil, "Invalid captured tag"
			end
			tags[#tags + 1] = StringCodec.encode(tag)
		end
	end

	local attributes = {}
	if preset.capture.attributes then
		if type(preset.attributes) ~= "table" then
			return nil, "Missing captured attributes"
		end
		for _, attributeName in ipairs(sortedKeys(preset.attributes)) do
			if type(attributeName) ~= "string" then
				return nil, "Invalid captured attribute name"
			end
			local encodedValue, encodeError = AttributeCodec.encode(preset.attributes[attributeName])
			if not encodedValue then
				return nil, string.format("Attribute %s: %s", attributeName, encodeError)
			end
			attributes[#attributes + 1] = {
				name = StringCodec.encode(attributeName),
				value = encodedValue,
			}
		end
	end

	return {
		name = StringCodec.encode(name),
		capture = {
			properties = preset.capture.properties == true,
			tags = preset.capture.tags == true,
			attributes = preset.capture.attributes == true,
		},
		properties = properties,
		tags = indexed(tags),
		attributes = indexed(attributes),
	}
end

function PresetSerializer.decodePreset(encoded)
	if type(encoded) ~= "table" or type(encoded.capture) ~= "table" then
		return nil, "Invalid preset record"
	end

	local name, nameError = StringCodec.decode(encoded.name)
	if not name then
		return nil, nameError
	end
	local normalizedName, normalizeError = PresetValidator.normalizeName(name)
	if not normalizedName then
		return nil, normalizeError
	end

	local capture = {
		properties = encoded.capture.properties == true,
		tags = encoded.capture.tags == true,
		attributes = encoded.capture.attributes == true,
	}
	local validOptions, optionsError = PresetValidator.captureOptions(capture)
	if not validOptions then
		return nil, optionsError
	end

	local preset = {
		name = normalizedName,
		capture = capture,
		properties = {},
		tags = {},
		attributes = {},
	}

	if capture.properties then
		if type(encoded.properties) ~= "table" then
			return nil, "Invalid properties record"
		end
		for _, propertyName in ipairs(Constants.PROPERTIES) do
			local value = encoded.properties[propertyName]
			if not validProperty(propertyName, value) then
				return nil, "Invalid persisted property: " .. propertyName
			end
			preset.properties[propertyName] = value
		end
	end

	if capture.tags then
		if not validCount(encoded.tags) then
			return nil, "Invalid tags record"
		end
		for index = 1, encoded.tags.count do
			local tag, tagError = StringCodec.decode(readIndexed(encoded.tags, index))
			if not tag then
				return nil, tagError
			end
			preset.tags[index] = tag
		end
	end

	if capture.attributes then
		if not validCount(encoded.attributes) then
			return nil, "Invalid attributes record"
		end
		for index = 1, encoded.attributes.count do
			local record = readIndexed(encoded.attributes, index)
			if type(record) ~= "table" then
				return nil, "Invalid attribute record"
			end
			local attributeName, attributeNameError = StringCodec.decode(record.name)
			if not attributeName then
				return nil, attributeNameError
			elseif preset.attributes[attributeName] ~= nil then
				return nil, "Duplicate persisted attribute: " .. attributeName
			end
			local attributeValue, attributeValueError = AttributeCodec.decode(record.value)
			if attributeValue == nil then
				return nil, attributeValueError
			end
			preset.attributes[attributeName] = attributeValue
		end
	end

	return preset
end

function PresetSerializer.encodeAll(presets)
	local records = {}
	for index, preset in ipairs(presets) do
		local encoded, encodeError = PresetSerializer.encodePreset(preset)
		if not encoded then
			return nil, string.format("Preset %d: %s", index, encodeError)
		end
		records[index] = encoded
	end

	local container = indexed(records)
	container.version = Constants.STORE_VERSION
	return container
end

function PresetSerializer.decodeAll(encoded)
	if encoded == nil then
		return {}
	elseif not validCount(encoded) or encoded.version ~= Constants.STORE_VERSION then
		return nil, "Unsupported or invalid PresetForge storage"
	end

	local presets = {}
	local names = {}
	for index = 1, encoded.count do
		local preset, decodeError = PresetSerializer.decodePreset(readIndexed(encoded, index))
		if not preset then
			return nil, string.format("Preset %d: %s", index, decodeError)
		end
		local nameKey = PresetValidator.nameKey(preset.name)
		if names[nameKey] then
			return nil, "Duplicate persisted preset name: " .. preset.name
		end
		names[nameKey] = true
		presets[index] = preset
	end
	return presets
end

function PresetSerializer.equal(left, right)
	local leftEncoded = PresetSerializer.encodeAll(left)
	local rightEncoded = PresetSerializer.encodeAll(right)
	return leftEncoded ~= nil and rightEncoded ~= nil and deepEqual(leftEncoded, rightEncoded)
end

return PresetSerializer
