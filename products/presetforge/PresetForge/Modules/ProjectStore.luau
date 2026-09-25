local Constants = require(script.Parent.Constants)
local PresetValidator = require(script.Parent.PresetValidator)
local Schema = require(script.Parent.Schema)
local ValueCodec = require(script.Parent.ValueCodec)

local ProjectStore = {}
ProjectStore.__index = ProjectStore

local function clone(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = clone(child)
	end
	return copy
end

local function sortedCopy(recipes)
	local result = clone(recipes)
	table.sort(result, function(left, right)
		return string.lower(left.name) < string.lower(right.name)
	end)
	return result
end

local function findChild(parent, name, className)
	local child = parent:FindFirstChild(name)
	if not child or child.ClassName ~= className then
		return nil
	end
	return child
end

local function exactAttributeSet(instance, expected)
	local attributes = instance:GetAttributes()
	for name in pairs(attributes) do
		if not expected[name] then
			return false
		end
	end
	for name in pairs(expected) do
		if attributes[name] == nil then
			return false
		end
	end
	return true
end

local function encodeRecipe(recipe)
	local valid, validationError = PresetValidator.recipe(recipe)
	if not valid then
		return nil, validationError
	end

	local node = Instance.new("Configuration")
	node.Name = recipe.name
	node:SetAttribute("FormatVersion", Constants.PROJECT_FORMAT_VERSION)
	node:SetAttribute("RecipeName", recipe.name)
	node:SetAttribute("SchemaId", recipe.schemaId)
	node:SetAttribute("CaptureTags", recipe.capture.tags)
	node:SetAttribute("CaptureAttributes", recipe.capture.attributes)

	local properties = Instance.new("Configuration")
	properties.Name = "Properties"
	properties.Parent = node
	for propertyName, value in pairs(recipe.properties) do
		local definition = Schema.property(recipe.schemaId, propertyName)
		properties:SetAttribute(propertyName, ValueCodec.toProjectAttribute(definition, value))
	end

	local tags = Instance.new("Folder")
	tags.Name = "Tags"
	tags.Parent = node
	for index, tag in ipairs(recipe.tags) do
		local value = Instance.new("StringValue")
		value.Name = string.format("Tag_%03d", index)
		value.Value = tag
		value.Parent = tags
	end

	local attributes = Instance.new("Configuration")
	attributes.Name = "Attributes"
	attributes.Parent = node
	for attributeName, value in pairs(recipe.attributes) do
		attributes:SetAttribute(attributeName, value)
	end

	return node
end

local function decodeRecipe(node)
	if node.ClassName ~= "Configuration" then
		return nil, "Project library contains a non-Configuration recipe"
	elseif #node:GetChildren() ~= 3 then
		return nil, node.Name .. " must contain exactly Properties, Tags, and Attributes"
	elseif not exactAttributeSet(node, {
		FormatVersion = true,
		RecipeName = true,
		SchemaId = true,
		CaptureTags = true,
		CaptureAttributes = true,
	}) then
		return nil, node.Name .. " has invalid recipe metadata"
	end

	local formatVersion = node:GetAttribute("FormatVersion")
	local recipeName = node:GetAttribute("RecipeName")
	local schemaId = node:GetAttribute("SchemaId")
	if formatVersion ~= Constants.PROJECT_FORMAT_VERSION then
		return nil, node.Name .. " uses an unsupported project format"
	elseif type(recipeName) ~= "string" or recipeName ~= node.Name then
		return nil, node.Name .. " has mismatched display metadata"
	elseif not Schema.get(schemaId) then
		return nil, node.Name .. " uses an unsupported class"
	end

	local propertiesNode = findChild(node, "Properties", "Configuration")
	local tagsNode = findChild(node, "Tags", "Folder")
	local attributesNode = findChild(node, "Attributes", "Configuration")
	if not propertiesNode or not tagsNode or not attributesNode then
		return nil, node.Name .. " has an invalid project structure"
	elseif #propertiesNode:GetChildren() > 0 or #attributesNode:GetChildren() > 0 then
		return nil, node.Name .. " contains unexpected executable or nested content"
	end

	local recipe = {
		name = recipeName,
		schemaId = schemaId,
		capture = {
			tags = node:GetAttribute("CaptureTags"),
			attributes = node:GetAttribute("CaptureAttributes"),
		},
		properties = {},
		tags = {},
		attributes = attributesNode:GetAttributes(),
	}

	for propertyName, storedValue in pairs(propertiesNode:GetAttributes()) do
		local definition = Schema.property(schemaId, propertyName)
		if not definition then
			return nil, node.Name .. " contains unsupported property " .. propertyName
		end
		local value, valueError = ValueCodec.fromProjectAttribute(definition, storedValue)
		if value == nil then
			return nil, string.format("%s.%s: %s", node.Name, propertyName, valueError)
		end
		recipe.properties[propertyName] = value
	end

	local tagChildren = tagsNode:GetChildren()
	table.sort(tagChildren, function(left, right)
		return left.Name < right.Name
	end)
	for _, child in ipairs(tagChildren) do
		if child.ClassName ~= "StringValue" or not child.Name:match("^Tag_%d%d%d$") then
			return nil, node.Name .. " contains an invalid tag record"
		end
		recipe.tags[#recipe.tags + 1] = child.Value
	end

	local valid, validationError = PresetValidator.recipe(recipe)
	if not valid then
		return nil, node.Name .. ": " .. validationError
	end
	return recipe
end

function ProjectStore.new(container)
	assert(typeof(container) == "Instance", "ProjectStore requires an Instance container")
	return setmetatable({
		_container = container,
		_recipes = {},
	}, ProjectStore)
end

function ProjectStore:_root()
	return self._container:FindFirstChild(Constants.PROJECT_ROOT_NAME)
end

function ProjectStore:_ensureRoot()
	local root = self:_root()
	if root then
		if root.ClassName ~= "Folder" or root:GetAttribute("FormatVersion") ~= Constants.PROJECT_FORMAT_VERSION then
			return nil, Constants.PROJECT_ROOT_NAME .. " exists but is not a PresetForge 2.0 library"
		end
		return root
	end
	root = Instance.new("Folder")
	root.Name = Constants.PROJECT_ROOT_NAME
	root:SetAttribute("FormatVersion", Constants.PROJECT_FORMAT_VERSION)
	root.Parent = self._container
	return root
end

function ProjectStore:load()
	local root = self:_root()
	if not root then
		self._recipes = {}
		return true
	elseif root.ClassName ~= "Folder"
		or not exactAttributeSet(root, { FormatVersion = true })
		or root:GetAttribute("FormatVersion") ~= Constants.PROJECT_FORMAT_VERSION then
		self._recipes = {}
		return false, Constants.PROJECT_ROOT_NAME .. " is malformed or unsupported"
	end

	local recipes = {}
	local names = {}
	for _, child in ipairs(root:GetChildren()) do
		local recipe, decodeError = decodeRecipe(child)
		if not recipe then
			self._recipes = {}
			return false, "Project recipe rejected: " .. decodeError
		end
		local key = PresetValidator.nameKey(recipe.name)
		if names[key] then
			self._recipes = {}
			return false, "Duplicate project recipe name: " .. recipe.name
		end
		names[key] = true
		recipes[#recipes + 1] = recipe
	end
	self._recipes = recipes
	return true
end

function ProjectStore:getPresets()
	return sortedCopy(self._recipes)
end

function ProjectStore:_findIndex(name)
	local key = PresetValidator.nameKey(name)
	for index, recipe in ipairs(self._recipes) do
		if PresetValidator.nameKey(recipe.name) == key then
			return index
		end
	end
	return nil
end

function ProjectStore:find(name)
	local index = self:_findIndex(name)
	return index and clone(self._recipes[index]) or nil
end

function ProjectStore:create(name, captured)
	local normalizedName, nameError = PresetValidator.normalizeName(name)
	if not normalizedName then
		return false, nameError
	end
	local loaded, loadError = self:load()
	if not loaded then
		return false, loadError
	elseif self:_findIndex(normalizedName) then
		return false, "A project recipe with this name already exists"
	end

	local recipe = clone(captured)
	recipe.name = normalizedName
	local node, encodeError = encodeRecipe(recipe)
	if not node then
		return false, encodeError
	end
	local root, rootError = self:_ensureRoot()
	if not root then
		node:Destroy()
		return false, rootError
	end
	node.Parent = root
	local verified, verifyError = self:load()
	if not verified then
		node:Destroy()
		self:load()
		return false, "Project recipe save could not be verified: " .. tostring(verifyError)
	end
	return true, clone(recipe)
end

function ProjectStore:update(currentName, captured)
	local loaded, loadError = self:load()
	if not loaded then
		return false, loadError
	end
	local index = self:_findIndex(currentName)
	if not index then
		return false, "Project recipe not found"
	end
	local recipe = clone(captured)
	recipe.name = self._recipes[index].name
	local replacement, encodeError = encodeRecipe(recipe)
	if not replacement then
		return false, encodeError
	end

	local root = self:_root()
	local previous = root:FindFirstChild(self._recipes[index].name)
	if not previous then
		replacement:Destroy()
		return false, "Project recipe instance not found"
	end
	previous.Parent = nil
	replacement.Parent = root
	local verified, verifyError = self:load()
	if not verified then
		replacement:Destroy()
		previous.Parent = root
		self:load()
		return false, "Project recipe update could not be verified: " .. tostring(verifyError)
	end
	previous:Destroy()
	return true, clone(recipe)
end

function ProjectStore:rename(currentName, requestedName)
	local loaded, loadError = self:load()
	if not loaded then
		return false, loadError
	end
	local index = self:_findIndex(currentName)
	if not index then
		return false, "Project recipe not found"
	end
	local normalizedName, nameError = PresetValidator.normalizeName(requestedName)
	if not normalizedName then
		return false, nameError
	end
	local duplicate = self:_findIndex(normalizedName)
	if duplicate and duplicate ~= index then
		return false, "A project recipe with this name already exists"
	end
	local recipe = clone(self._recipes[index])
	recipe.name = normalizedName
	local replacement, encodeError = encodeRecipe(recipe)
	if not replacement then
		return false, encodeError
	end
	local root = self:_root()
	local previous = root:FindFirstChild(self._recipes[index].name)
	if not previous then
		replacement:Destroy()
		return false, "Project recipe instance not found"
	end
	previous.Parent = nil
	replacement.Parent = root
	local verified, verifyError = self:load()
	if not verified then
		replacement:Destroy()
		previous.Parent = root
		self:load()
		return false, "Project recipe rename could not be verified: " .. tostring(verifyError)
	end
	previous:Destroy()
	return true, clone(recipe)
end

function ProjectStore:delete(name)
	local loaded, loadError = self:load()
	if not loaded then
		return false, loadError
	end
	local index = self:_findIndex(name)
	if not index then
		return false, "Project recipe not found"
	end
	local root = self:_root()
	local node = root:FindFirstChild(self._recipes[index].name)
	if not node then
		return false, "Project recipe instance not found"
	end
	node.Parent = nil
	local verified, verifyError = self:load()
	if not verified then
		node.Parent = root
		self:load()
		return false, "Project recipe deletion could not be verified: " .. tostring(verifyError)
	end
	node:Destroy()
	return true
end

return ProjectStore
