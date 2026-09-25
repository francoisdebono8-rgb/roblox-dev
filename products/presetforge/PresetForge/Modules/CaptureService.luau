local AttributeCodec = require(script.Parent.AttributeCodec)
local Constants = require(script.Parent.Constants)
local PresetValidator = require(script.Parent.PresetValidator)

local CaptureService = {}
CaptureService.__index = CaptureService

function CaptureService.new(collectionService)
	return setmetatable({
		_collectionService = collectionService,
	}, CaptureService)
end

function CaptureService:capture(selection, options)
	local validOptions, optionsError = PresetValidator.captureOptions(options)
	if not validOptions then
		return nil, optionsError
	elseif #selection ~= 1 then
		return nil, "Select exactly one BasePart to capture"
	end

	local source = selection[1]
	if not source:IsA("BasePart") then
		return nil, "The capture source must be a BasePart"
	end

	local preset = {
		capture = {
			properties = options.properties == true,
			tags = options.tags == true,
			attributes = options.attributes == true,
		},
		properties = {},
		tags = {},
		attributes = {},
	}

	if options.properties then
		for _, propertyName in ipairs(Constants.PROPERTIES) do
			preset.properties[propertyName] = source[propertyName]
		end
	end

	if options.tags then
		preset.tags = self._collectionService:GetTags(source)
		table.sort(preset.tags)
	end

	if options.attributes then
		preset.attributes = source:GetAttributes()
		for attributeName, attributeValue in pairs(preset.attributes) do
			local encoded, encodeError = AttributeCodec.encode(attributeValue)
			if not encoded then
				return nil, string.format("Attribute %s cannot be captured: %s", attributeName, encodeError)
			end
		end
	end

	return preset, source
end

return CaptureService
