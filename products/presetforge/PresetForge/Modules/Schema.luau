local Schema = {}

local function property(name, kind, options)
	local definition = options or {}
	definition.name = name
	definition.kind = kind
	return definition
end

local families = {
	BasePart = {
		id = "BasePart",
		label = "BasePart",
		className = "BasePart",
		filterClasses = {
			"BasePart",
			"Part",
			"MeshPart",
			"WedgePart",
			"CornerWedgePart",
			"UnionOperation",
			"TrussPart",
			"Seat",
			"VehicleSeat",
			"SpawnLocation",
		},
		properties = {
			property("Anchored", "boolean"),
			property("CanCollide", "boolean"),
			property("CanTouch", "boolean"),
			property("CanQuery", "boolean"),
			property("Transparency", "number", { min = 0, max = 1 }),
			property("CastShadow", "boolean"),
			property("Massless", "boolean"),
		},
	},
	PointLight = {
		id = "PointLight",
		label = "PointLight",
		className = "PointLight",
		filterClasses = { "PointLight" },
		properties = {
			property("Enabled", "boolean"),
			property("Brightness", "number", { min = 0 }),
			property("Color", "Color3"),
			property("Shadows", "boolean"),
			property("Range", "number", { min = 0, max = 120 }),
		},
	},
	SpotLight = {
		id = "SpotLight",
		label = "SpotLight",
		className = "SpotLight",
		filterClasses = { "SpotLight" },
		properties = {
			property("Enabled", "boolean"),
			property("Brightness", "number", { min = 0 }),
			property("Color", "Color3"),
			property("Shadows", "boolean"),
			property("Range", "number", { min = 0, max = 120 }),
			property("Angle", "number", { min = 0, max = 180 }),
			property("Face", "EnumItem", { enumType = "NormalId" }),
		},
	},
	SurfaceLight = {
		id = "SurfaceLight",
		label = "SurfaceLight",
		className = "SurfaceLight",
		filterClasses = { "SurfaceLight" },
		properties = {
			property("Enabled", "boolean"),
			property("Brightness", "number", { min = 0 }),
			property("Color", "Color3"),
			property("Shadows", "boolean"),
			property("Range", "number", { min = 0, max = 120 }),
			property("Angle", "number", { min = 0, max = 180 }),
			property("Face", "EnumItem", { enumType = "NormalId" }),
		},
	},
	Sound = {
		id = "Sound",
		label = "Sound",
		className = "Sound",
		filterClasses = { "Sound" },
		properties = {
			property("SoundId", "string"),
			property("Volume", "number", { min = 0, max = 10 }),
			property("PlaybackSpeed", "number", { min = 0, max = 20 }),
			property("Looped", "boolean"),
			property("RollOffMinDistance", "number", { min = 0 }),
			property("RollOffMaxDistance", "number", { min = 0 }),
			property("RollOffMode", "EnumItem", { enumType = "RollOffMode" }),
		},
	},
	ParticleEmitter = {
		id = "ParticleEmitter",
		label = "ParticleEmitter",
		className = "ParticleEmitter",
		filterClasses = { "ParticleEmitter" },
		properties = {
			property("Enabled", "boolean"),
			property("Texture", "string"),
			property("Rate", "number"),
			property("Lifetime", "NumberRange"),
			property("Speed", "NumberRange"),
			property("Color", "ColorSequence"),
			property("Transparency", "NumberSequence"),
			property("Size", "NumberSequence"),
			property("LightEmission", "number", { min = 0, max = 1 }),
			property("LightInfluence", "number", { min = 0, max = 1 }),
			property("ZOffset", "number"),
			property("Rotation", "NumberRange"),
			property("RotSpeed", "NumberRange"),
			property("Orientation", "EnumItem", { enumType = "ParticleOrientation" }),
		},
	},
	Decal = {
		id = "Decal",
		label = "Decal",
		className = "Decal",
		exactClass = true,
		filterClasses = { "Decal" },
		properties = {
			property("ColorMap", "string"),
			property("Color3", "Color3"),
			property("Transparency", "number", { min = 0, max = 1 }),
			property("Face", "EnumItem", { enumType = "NormalId" }),
		},
	},
	Texture = {
		id = "Texture",
		label = "Texture",
		className = "Texture",
		filterClasses = { "Texture" },
		properties = {
			property("ColorMap", "string"),
			property("Color3", "Color3"),
			property("Transparency", "number", { min = 0, max = 1 }),
			property("Face", "EnumItem", { enumType = "NormalId" }),
			property("StudsPerTileU", "number", { exclusiveMin = 0 }),
			property("StudsPerTileV", "number", { exclusiveMin = 0 }),
			property("OffsetStudsU", "number"),
			property("OffsetStudsV", "number"),
		},
	},
	GuiObject = {
		id = "GuiObject",
		label = "GuiObject",
		className = "GuiObject",
		filterClasses = {
			"GuiObject",
			"Frame",
			"ScrollingFrame",
			"TextLabel",
			"TextButton",
			"TextBox",
			"ImageLabel",
			"ImageButton",
			"ViewportFrame",
		},
		properties = {
			property("Visible", "boolean"),
			property("Active", "boolean"),
			property("BackgroundColor3", "Color3"),
			property("BackgroundTransparency", "number", { min = 0, max = 1 }),
			property("BorderColor3", "Color3"),
			property("BorderSizePixel", "number", { min = 0, max = 100, integer = true }),
			property("Position", "UDim2"),
			property("Size", "UDim2"),
			property("AnchorPoint", "Vector2"),
			property("Rotation", "number"),
			property("ZIndex", "number", { integer = true }),
			property("LayoutOrder", "number", { integer = true }),
			property("AutomaticSize", "EnumItem", { enumType = "AutomaticSize" }),
		},
	},
	ProximityPrompt = {
		id = "ProximityPrompt",
		label = "ProximityPrompt",
		className = "ProximityPrompt",
		filterClasses = { "ProximityPrompt" },
		properties = {
			property("Enabled", "boolean"),
			property("ActionText", "string"),
			property("ObjectText", "string"),
			property("HoldDuration", "number"),
			property("MaxActivationDistance", "number"),
			property("RequiresLineOfSight", "boolean"),
			property("ClickablePrompt", "boolean"),
			property("KeyboardKeyCode", "EnumItem", { enumType = "KeyCode" }),
			property("GamepadKeyCode", "EnumItem", { enumType = "KeyCode" }),
			property("Exclusivity", "EnumItem", { enumType = "ProximityPromptExclusivity" }),
		},
	},
	Configuration = {
		id = "Configuration",
		label = "Configuration",
		className = "Configuration",
		filterClasses = { "Configuration" },
		properties = {},
	},
}

local familyOrder = {
	"BasePart",
	"PointLight",
	"SpotLight",
	"SurfaceLight",
	"Sound",
	"ParticleEmitter",
	"Texture",
	"Decal",
	"GuiObject",
	"ProximityPrompt",
	"Configuration",
}

for _, family in pairs(families) do
	family.propertyByName = {}
	for _, definition in ipairs(family.properties) do
		family.propertyByName[definition.name] = definition
	end
end

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Schema.get(schemaId)
	return families[schemaId]
end

function Schema.forInstance(instance)
	if typeof(instance) ~= "Instance" then
		return nil
	end
	for _, schemaId in ipairs(familyOrder) do
		local family = families[schemaId]
		if instance:IsA(family.className) then
			return family
		end
	end
	return nil
end

function Schema.property(schemaId, propertyName)
	local family = families[schemaId]
	return family and family.propertyByName[propertyName] or nil
end

function Schema.isCompatible(schemaId, instance)
	local family = families[schemaId]
	return family ~= nil
		and typeof(instance) == "Instance"
		and (if family.exactClass then instance.ClassName == family.className else instance:IsA(family.className))
end

function Schema.isClassFilterAllowed(schemaId, className)
	local family = families[schemaId]
	if not family or type(className) ~= "string" then
		return false
	end
	return table.find(family.filterClasses, className) ~= nil
end

function Schema.matchesClassFilter(schemaId, instance, className)
	return Schema.isClassFilterAllowed(schemaId, className)
		and typeof(instance) == "Instance"
		and instance:IsA(className)
end

function Schema.defaultClassFilter(schemaId)
	local family = families[schemaId]
	return family and family.className or nil
end

function Schema.validateValue(schemaId, propertyName, value)
	local definition = Schema.property(schemaId, propertyName)
	if not definition then
		return false, "Unsupported property for " .. tostring(schemaId) .. ": " .. tostring(propertyName)
	end

	local kind = typeof(value)
	if definition.kind == "number" then
		if not finite(value) then
			return false, propertyName .. " must be a finite number"
		elseif definition.integer and value % 1 ~= 0 then
			return false, propertyName .. " must be an integer"
		elseif definition.min ~= nil and value < definition.min then
			return false, propertyName .. " is below its safe minimum"
		elseif definition.exclusiveMin ~= nil and value <= definition.exclusiveMin then
			return false, propertyName .. " must be greater than its safe minimum"
		elseif definition.max ~= nil and value > definition.max then
			return false, propertyName .. " is above its safe maximum"
		end
	elseif definition.kind == "string" then
		if type(value) ~= "string" then
			return false, propertyName .. " must be a string"
		end
	elseif definition.kind == "boolean" then
		if type(value) ~= "boolean" then
			return false, propertyName .. " must be boolean"
		end
	elseif definition.kind == "EnumItem" then
		local enumType = Enum[definition.enumType]
		if kind ~= "EnumItem" or not enumType or value.EnumType ~= enumType then
			return false, propertyName .. " must be an Enum." .. tostring(definition.enumType) .. " item"
		end
	elseif kind ~= definition.kind then
		return false, string.format("%s must be %s", propertyName, definition.kind)
	end

	return true
end

return Schema
