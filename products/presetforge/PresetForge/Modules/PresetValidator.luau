local Constants = require(script.Parent.Constants)
local AttributeCodec = require(script.Parent.AttributeCodec)
local Schema = require(script.Parent.Schema)
local Guard = require(script.Parent.DataGuard)
local ValueCodec = require(script.Parent.ValueCodec)

local PresetValidator = {}

function PresetValidator.normalizeName(value)
	if type(value) ~= "string" then
		return nil, "Enter a preset name"
	end

	local name = value:match("^%s*(.-)%s*$")
	if name == "" then
		return nil, "Enter a preset name"
	elseif #name > Constants.MAX_NAME_BYTES then
		return nil, "Preset names must be 40 bytes or fewer"
	elseif name:find("%c") then
		return nil, "Preset names cannot contain control characters"
	end

	return name
end

function PresetValidator.nameKey(value)
	return string.lower(value)
end

function PresetValidator.captureOptions(schemaId, options)
	local schema = Schema.get(schemaId)
	if not schema then
		return false, "Unsupported source class"
	end
	if type(options) ~= "table" then
		return false, "Choose at least one field, tags, or attributes"
	end

	for _, key in ipairs({ "tags", "attributes" }) do
		if options[key] ~= nil and type(options[key]) ~= "boolean" then
			return false, "Capture options must be boolean"
		end
	end

	if not Guard.array(options.properties, 64) then
		return false, "Property selection must be a list"
	end
	for key, limit in pairs({ tagNames = Constants.MAX_TAGS, attributeNames = Constants.MAX_ATTRIBUTES }) do
		if options[key] ~= nil then
			if not Guard.array(options[key], limit) then return false, "Invalid selected metadata list" end
			local selected = {}
			for _, name in ipairs(options[key]) do
				if type(name) ~= "string" or selected[name] then return false, "Invalid or duplicate selected metadata name" end
				selected[name] = true
			end
		end
	end
	local seen = {}
	for _, propertyName in ipairs(options.properties) do
		if type(propertyName) ~= "string" or not Schema.property(schemaId, propertyName) then
			return false, "Unsupported selected property: " .. tostring(propertyName)
		elseif seen[propertyName] then
			return false, "Duplicate selected property: " .. propertyName
		end
		seen[propertyName] = true
	end

	if #options.properties == 0 and not options.tags and not options.attributes then
		return false, "Choose at least one field, tags, or attributes"
	end

	return true
end

function PresetValidator.recipe(preset)
	if type(preset) ~= "table" then
		return false, "Invalid recipe"
	end
	local name, nameError = PresetValidator.normalizeName(preset.name)
	if not name then
		return false, nameError
	end
	if not Schema.get(preset.schemaId) then
		return false, "Unsupported recipe class"
	elseif type(preset.capture) ~= "table" then
		return false, "Invalid recipe capture options"
	elseif type(preset.capture.tags) ~= "boolean" or type(preset.capture.attributes) ~= "boolean" then
		return false, "Recipe capture options must be boolean"
	elseif type(preset.properties) ~= "table" or type(preset.tags) ~= "table" or type(preset.attributes) ~= "table" then
		return false, "Invalid recipe contents"
	end

	local propertyCount = 0
	for propertyName, value in pairs(preset.properties) do
		if type(propertyName) ~= "string" then
			return false, "Invalid recipe property name"
		end
		local valid, valueError = Schema.validateValue(preset.schemaId, propertyName, value)
		if not valid then
			return false, valueError
		end
		local encoded = ValueCodec.encode(Schema.property(preset.schemaId, propertyName), value)
		if not encoded or not Guard.data(encoded) then return false, "Invalid or oversized property value" end
		propertyCount += 1
	end

	if not preset.capture.tags and #preset.tags > 0 then
		return false, "Recipe contains tags while tag capture is disabled"
	end
	if not Guard.array(preset.tags, Constants.MAX_TAGS) then return false, "Invalid or oversized tag list" end
	local seenTags = {}
	for _, tag in ipairs(preset.tags) do
		if type(tag) ~= "string" or tag == "" or #tag > 100 or tag:find("%c") then
			return false, "Invalid captured tag"
		elseif seenTags[tag] then
			return false, "Duplicate captured tag: " .. tag
		end
		seenTags[tag] = true
	end

	if not preset.capture.attributes and next(preset.attributes) ~= nil then
		return false, "Recipe contains attributes while attribute capture is disabled"
	end
	local attributeCount = 0
	for attributeName, value in pairs(preset.attributes) do
		attributeCount += 1
		if attributeCount > Constants.MAX_ATTRIBUTES then return false, "Attribute count limit exceeded" end
		if type(attributeName) ~= "string" or attributeName == "" or #attributeName > 100
			or attributeName:find("[^%w_./%-]") or attributeName:sub(1, 3) == "RBX" then
			return false, "Invalid captured attribute name"
		end
		local encoded, encodeError = AttributeCodec.encode(value)
		if not encoded then
			return false, string.format("Attribute %s: %s", attributeName, encodeError)
		end
	end

	if propertyCount == 0 and not preset.capture.tags and not preset.capture.attributes then
		return false, "Recipe must contain at least one field, tags, or attributes"
	end
	return true
end

return PresetValidator
