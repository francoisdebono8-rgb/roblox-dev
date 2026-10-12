local PresetValidator = require(script.Parent.PresetValidator)

local RecipeRepository = {}
RecipeRepository.__index = RecipeRepository

local function withLibrary(recipes, library)
	for _, recipe in ipairs(recipes) do
		recipe.library = library
	end
	return recipes
end

function RecipeRepository.new(localStore, projectStore)
	return setmetatable({
		localStore = localStore,
		projectStore = projectStore,
		_revisions = {},
	}, RecipeRepository)
end

function RecipeRepository:load()
	local localOk, localError = self.localStore:load()
	local projectOk, projectError = self.projectStore:load()
	if not localOk then
		return false, localError
	elseif not projectOk then
		return false, projectError
	end
	local localNames = {}
	for _, recipe in ipairs(self.localStore:getPresets()) do
		localNames[PresetValidator.nameKey(recipe.name)] = recipe.name
	end
	for _, recipe in ipairs(self.projectStore:getPresets()) do
		local localName = localNames[PresetValidator.nameKey(recipe.name)]
		if localName then
			return false, string.format(
				"Recipe name conflict between Local and Project libraries: %s",
				localName
			)
		end
	end
	return true
end

function RecipeRepository:_store(library)
	if library == "Local" then
		return self.localStore
	elseif library == "Project" then
		return self.projectStore
	end
	return nil
end

function RecipeRepository:getRecipes(query)
	local recipes = withLibrary(self.localStore:getPresets(), "Local")
	for _, recipe in ipairs(withLibrary(self.projectStore:getPresets(), "Project")) do
		recipes[#recipes + 1] = recipe
	end
	table.sort(recipes, function(left, right)
		local leftName = string.lower(left.name)
		local rightName = string.lower(right.name)
		return leftName < rightName or (leftName == rightName and left.library < right.library)
	end)
	if type(query) == "string" and query ~= "" then
		local filtered = {}
		local needle = string.lower(query)
		for _, recipe in ipairs(recipes) do
			if string.find(string.lower(recipe.name), needle, 1, true) then
				filtered[#filtered + 1] = recipe
			end
		end
		return filtered
	end
	return recipes
end

function RecipeRepository:duplicate(library, name, newLibrary, newName)
	local original = self:find(library, name)
	if not original then
		return false, "Recipe not found"
	end
	return self:create(newLibrary, newName, original)
end

function RecipeRepository:find(library, name)
	local store = self:_store(library)
	if not store then
		return nil
	end
	-- Project recipes and settings can change outside this controller's mutation paths.
	if not store:load() then return nil end
	local recipe = store:find(name)
	if recipe then
		recipe.library = library
	end
	return recipe
end

function RecipeRepository:_findAny(name, excludedLibrary, excludedName)
	local key = PresetValidator.nameKey(name)
	for _, recipe in ipairs(self:getRecipes()) do
		local excluded = recipe.library == excludedLibrary
			and excludedName ~= nil
			and PresetValidator.nameKey(recipe.name) == PresetValidator.nameKey(excludedName)
		if not excluded and PresetValidator.nameKey(recipe.name) == key then
			return recipe
		end
	end
	return nil
end

function RecipeRepository:create(library, name, captured)
	if self:_findAny(name) then
		return false, "A Local or Project recipe with this name already exists"
	end
	local store = self:_store(library)
	if not store then
		return false, "Choose Local or Project"
	end
	local created, result = store:create(name, captured)
	if created then
		self:_changed(library, result.name)
		result.library = library
	end
	return created, result
end

function RecipeRepository:update(library, currentName, captured)
	local store = self:_store(library)
	if not store then
		return false, "Unknown recipe library"
	end
	local updated, result = store:update(currentName, captured)
	if updated then
		self:_changed(library, currentName)
		result.library = library
	end
	return updated, result
end

function RecipeRepository:rename(library, currentName, requestedName)
	if self:_findAny(requestedName, library, currentName) then
		return false, "A Local or Project recipe with this name already exists"
	end
	local store = self:_store(library)
	if not store then
		return false, "Unknown recipe library"
	end
	local renamed, result = store:rename(currentName, requestedName)
	if renamed then
		self:_changed(library, currentName)
		self:_changed(library, result.name)
		result.library = library
	end
	return renamed, result
end

function RecipeRepository:delete(library, name)
	local store = self:_store(library)
	if not store then
		return false, "Unknown recipe library"
	end
	local deleted, err = store:delete(name)
	if deleted then self:_changed(library, name) end
	return deleted, err
end

function RecipeRepository:revision(library, name)
	return self._revisions[library .. ":" .. PresetValidator.nameKey(name)] or 0
end

function RecipeRepository:_changed(library, name)
	local key = library .. ":" .. PresetValidator.nameKey(name)
	self._revisions[key] = (self._revisions[key] or 0) + 1
end

return RecipeRepository
