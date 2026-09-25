local Constants = require(script.Parent.Constants)

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

function PresetValidator.captureOptions(options)
	if type(options) ~= "table" then
		return false, "Choose at least one capture category"
	end

	for _, key in ipairs({ "properties", "tags", "attributes" }) do
		if options[key] ~= nil and type(options[key]) ~= "boolean" then
			return false, "Capture options must be boolean"
		end
	end

	if not options.properties and not options.tags and not options.attributes then
		return false, "Choose at least one capture category"
	end

	return true
end

return PresetValidator
