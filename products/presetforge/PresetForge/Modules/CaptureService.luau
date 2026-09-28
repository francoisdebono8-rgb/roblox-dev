local PresetValidator = require(script.Parent.PresetValidator)
local Schema = require(script.Parent.Schema)

local CaptureService = {}
CaptureService.__index = CaptureService

local function oneSource(selection)
	if type(selection) ~= "table" or #selection ~= 1 then
		return nil, nil, "Select exactly one supported source"
	end
	local source = selection[1]
	local schema = Schema.forInstance(source)
	if not schema then
		return nil, nil, "The source class is not supported"
	end
	return source, schema
end

function CaptureService.new(collectionService)
	return setmetatable({
		_collectionService = collectionService,
	}, CaptureService)
end

function CaptureService:capture(selection, options)
	local source, schema, sourceError = oneSource(selection)
	if not source then
		return nil, sourceError
	end

	local validOptions, optionsError = PresetValidator.captureOptions(schema.id, options)
	if not validOptions then
		return nil, optionsError
	end

	local recipe = {
		schemaId = schema.id,
		capture = {
			tags = options.tags == true,
			attributes = options.attributes == true,
		},
		properties = {},
		tags = {},
		attributes = {},
	}

	for _, propertyName in ipairs(options.properties) do
		local ok, value = pcall(function()
			return source[propertyName]
		end)
		if not ok then
			return nil, "Could not read source property: " .. propertyName
		end
		local valid, valueError = Schema.validateValue(schema.id, propertyName, value)
		if not valid then
			return nil, valueError
		end
		recipe.properties[propertyName] = value
	end

	if options.tags then
		local available = self._collectionService:GetTags(source)
		recipe.tags = if options.tagNames then table.clone(options.tagNames) else available
		for _, name in ipairs(recipe.tags) do
			if not table.find(available, name) then return nil, "Selected tag is absent: " .. name end
		end
		table.sort(recipe.tags)
	end
	if options.attributes then
		local available = source:GetAttributes()
		if options.attributeNames then
			for _, name in ipairs(options.attributeNames) do
				if available[name] == nil then return nil, "Selected attribute is absent: " .. name end
				recipe.attributes[name] = available[name]
			end
		else recipe.attributes = available end
	end
	local candidate = table.clone(recipe)
	candidate.name = "Captured recipe"
	local valid, validationError = PresetValidator.recipe(candidate)
	if not valid then return nil, validationError end
	return recipe, source
end

function CaptureService:recapture(recipe, selection)
	local validRecipe, recipeError = PresetValidator.recipe(recipe)
	if not validRecipe then
		return nil, recipeError
	end

	local source, schema, sourceError = oneSource(selection)
	if not source then
		return nil, sourceError
	end

	local fields = {}
	for propertyName in pairs(recipe.properties) do
		if not Schema.property(schema.id, propertyName) then
			return nil, string.format("%s is not valid for %s", propertyName, schema.label)
		end
		fields[#fields + 1] = propertyName
	end
	table.sort(fields)

	local captured, captureError = self:capture(selection, {
		properties = fields,
		tags = recipe.capture.tags,
		attributes = recipe.capture.attributes,
		tagNames = recipe.tags,
		attributeNames = (function()
			local names = {}
			for name in pairs(recipe.attributes) do names[#names + 1] = name end
			table.sort(names)
			return names
		end)(),
	})
	if not captured then
		return nil, captureError
	end
	captured.name = recipe.name
	return captured, source
end

return CaptureService
