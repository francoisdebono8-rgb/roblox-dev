local AttributeCodec = require(script.Parent.AttributeCodec)
local Constants = require(script.Parent.Constants)
local PresetValidator = require(script.Parent.PresetValidator)
local Schema = require(script.Parent.Schema)
local StringCodec = require(script.Parent.StringCodec)
local ValueCodec = require(script.Parent.ValueCodec)

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

local function encodeTags(tags)
	local encoded = {}
	for _, tag in ipairs(tags) do
		encoded[#encoded + 1] = StringCodec.encode(tag)
	end
	return indexed(encoded)
end

local function decodeTags(encoded)
	if not validCount(encoded) then
		return nil, "Invalid tags record"
	end
	local tags = {}
	local seen = {}
	for index = 1, encoded.count do
		local tag, tagError = StringCodec.decode(readIndexed(encoded, index))
		if not tag then
			return nil, tagError
		elseif seen[tag] then
			return nil, "Duplicate persisted tag: " .. tag
		end
		seen[tag] = true
		tags[index] = tag
	end
	return tags
end

local function encodeAttributes(attributes)
	local encoded = {}
	for _, attributeName in ipairs(sortedKeys(attributes)) do
		local value, valueError = AttributeCodec.encode(attributes[attributeName])
		if not value then
			return nil, string.format("Attribute %s: %s", attributeName, valueError)
		end
		encoded[#encoded + 1] = {
			name = StringCodec.encode(attributeName),
			value = value,
		}
	end
	return indexed(encoded)
end

local function decodeAttributes(encoded)
	if not validCount(encoded) then
		return nil, "Invalid attributes record"
	end
	local attributes = {}
	for index = 1, encoded.count do
		local record = readIndexed(encoded, index)
		if type(record) ~= "table" then
			return nil, "Invalid attribute record"
		end
		local name, nameError = StringCodec.decode(record.name)
		if not name then
			return nil, nameError
		elseif attributes[name] ~= nil then
			return nil, "Duplicate persisted attribute: " .. name
		end
		local value, valueError = AttributeCodec.decode(record.value)
		if value == nil then
			return nil, valueError
		end
		attributes[name] = value
	end
	return attributes
end

function PresetSerializer.encodePreset(preset)
	local valid, validationError = PresetValidator.recipe(preset)
	if not valid then
		return nil, validationError
	end

	local properties = {}
	for _, propertyName in ipairs(sortedKeys(preset.properties)) do
		local definition = Schema.property(preset.schemaId, propertyName)
		local encodedValue, valueError = ValueCodec.encode(definition, preset.properties[propertyName])
		if not encodedValue then
			return nil, string.format("Property %s: %s", propertyName, valueError)
		end
		properties[#properties + 1] = {
			name = propertyName,
			value = encodedValue,
		}
	end

	local attributes, attributeError = encodeAttributes(preset.attributes)
	if not attributes then
		return nil, attributeError
	end

	return {
		name = StringCodec.encode(preset.name),
		schemaId = preset.schemaId,
		capture = {
			tags = preset.capture.tags,
			attributes = preset.capture.attributes,
		},
		properties = indexed(properties),
		tags = encodeTags(preset.tags),
		attributes = attributes,
	}
end

function PresetSerializer.decodePreset(encoded)
	if type(encoded) ~= "table" or type(encoded.capture) ~= "table" or not validCount(encoded.properties) then
		return nil, "Invalid recipe record"
	end
	local name, nameError = StringCodec.decode(encoded.name)
	if not name then
		return nil, nameError
	end
	local normalizedName, normalizeError = PresetValidator.normalizeName(name)
	if not normalizedName then
		return nil, normalizeError
	elseif not Schema.get(encoded.schemaId) then
		return nil, "Unsupported persisted recipe class"
	end

	local recipe = {
		name = normalizedName,
		schemaId = encoded.schemaId,
		capture = {
			tags = encoded.capture.tags == true,
			attributes = encoded.capture.attributes == true,
		},
		properties = {},
		tags = {},
		attributes = {},
	}

	for index = 1, encoded.properties.count do
		local record = readIndexed(encoded.properties, index)
		if type(record) ~= "table" or type(record.name) ~= "string" then
			return nil, "Invalid persisted property record"
		elseif recipe.properties[record.name] ~= nil then
			return nil, "Duplicate persisted property: " .. record.name
		end
		local definition = Schema.property(recipe.schemaId, record.name)
		if not definition then
			return nil, "Unsupported persisted property: " .. record.name
		end
		local value, valueError = ValueCodec.decode(definition, record.value)
		if value == nil then
			return nil, string.format("Property %s: %s", record.name, valueError)
		end
		local validValue, validationError = Schema.validateValue(recipe.schemaId, record.name, value)
		if not validValue then
			return nil, validationError
		end
		recipe.properties[record.name] = value
	end

	local tags, tagError = decodeTags(encoded.tags)
	if not tags then
		return nil, tagError
	end
	recipe.tags = tags
	local attributes, attributeError = decodeAttributes(encoded.attributes)
	if not attributes then
		return nil, attributeError
	end
	recipe.attributes = attributes

	local valid, validationError = PresetValidator.recipe(recipe)
	if not valid then
		return nil, validationError
	end
	return recipe
end

local function decodeLegacyPreset(encoded)
	if type(encoded) ~= "table" or type(encoded.capture) ~= "table" then
		return nil, "Invalid V1 preset record"
	end
	local name, nameError = StringCodec.decode(encoded.name)
	if not name then
		return nil, nameError
	end
	local normalizedName, normalizeError = PresetValidator.normalizeName(name)
	if not normalizedName then
		return nil, normalizeError
	end

	local recipe = {
		name = normalizedName,
		schemaId = "BasePart",
		capture = {
			tags = encoded.capture.tags == true,
			attributes = encoded.capture.attributes == true,
		},
		properties = {},
		tags = {},
		attributes = {},
	}
	if encoded.capture.properties == true then
		if type(encoded.properties) ~= "table" then
			return nil, "Invalid V1 properties record"
		end
		for _, propertyName in ipairs(Constants.LEGACY_PROPERTIES) do
			local value = encoded.properties[propertyName]
			local valid, validationError = Schema.validateValue("BasePart", propertyName, value)
			if not valid then
				return nil, validationError
			end
			recipe.properties[propertyName] = value
		end
	end
	if recipe.capture.tags then
		local tags, tagError = decodeTags(encoded.tags)
		if not tags then
			return nil, tagError
		end
		recipe.tags = tags
	end
	if recipe.capture.attributes then
		local attributes, attributeError = decodeAttributes(encoded.attributes)
		if not attributes then
			return nil, attributeError
		end
		recipe.attributes = attributes
	end

	local valid, validationError = PresetValidator.recipe(recipe)
	if not valid then
		return nil, validationError
	end
	return recipe
end

function PresetSerializer.encodeAll(presets)
	local records = {}
	for index, preset in ipairs(presets) do
		local encoded, encodeError = PresetSerializer.encodePreset(preset)
		if not encoded then
			return nil, string.format("Recipe %d: %s", index, encodeError)
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
	elseif not validCount(encoded)
		or (encoded.version ~= Constants.STORE_VERSION and encoded.version ~= Constants.LEGACY_STORE_VERSION) then
		return nil, "Unsupported or invalid PresetForge storage"
	end

	local presets = {}
	local names = {}
	for index = 1, encoded.count do
		local record = readIndexed(encoded, index)
		local preset, decodeError
		if encoded.version == Constants.LEGACY_STORE_VERSION then
			preset, decodeError = decodeLegacyPreset(record)
		else
			preset, decodeError = PresetSerializer.decodePreset(record)
		end
		if not preset then
			return nil, string.format("Recipe %d: %s", index, decodeError)
		end
		local key = PresetValidator.nameKey(preset.name)
		if names[key] then
			return nil, "Duplicate persisted recipe name: " .. preset.name
		end
		names[key] = true
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
