local PresetSerializer = require(script.Parent.PresetSerializer)
local PresetValidator = require(script.Parent.PresetValidator)

local PresetStore = {}
PresetStore.__index = PresetStore

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

local function sortedCopy(presets)
	local result = clone(presets)
	table.sort(result, function(left, right)
		return string.lower(left.name) < string.lower(right.name)
	end)
	return result
end

function PresetStore.new(pluginObject, storageKey)
	assert(pluginObject ~= nil, "PresetStore requires a plugin object")
	return setmetatable({
		_plugin = pluginObject,
		_storageKey = storageKey,
		_presets = {},
	}, PresetStore)
end

function PresetStore:load()
	local ok, stored = pcall(self._plugin.GetSetting, self._plugin, self._storageKey)
	if not ok then
		self._presets = {}
		return false, "Could not read local presets: " .. tostring(stored)
	end

	local presets, decodeError = PresetSerializer.decodeAll(stored)
	if not presets then
		self._presets = {}
		return false, "Local preset data is invalid: " .. tostring(decodeError)
	end

	self._presets = presets
	return true
end

function PresetStore:getPresets()
	return sortedCopy(self._presets)
end

function PresetStore:find(name)
	local key = PresetValidator.nameKey(name)
	for _, preset in ipairs(self._presets) do
		if PresetValidator.nameKey(preset.name) == key then
			return clone(preset)
		end
	end
	return nil
end

function PresetStore:_findIndex(name)
	local key = PresetValidator.nameKey(name)
	for index, preset in ipairs(self._presets) do
		if PresetValidator.nameKey(preset.name) == key then
			return index
		end
	end
	return nil
end

function PresetStore:_persist(candidate)
	local readBeforeOk, storedBefore = pcall(self._plugin.GetSetting, self._plugin, self._storageKey)
	if not readBeforeOk then return false, "Could not verify current local library" end
	local before = PresetSerializer.decodeAll(storedBefore)
	if not before or not PresetSerializer.equal(before, self._presets) then
		return false, "Local library changed or is invalid; reload before saving"
	end
	local encoded, encodeError = PresetSerializer.encodeAll(candidate)
	if not encoded then
		return false, encodeError
	end

	local writeOk, writeError = pcall(self._plugin.SetSetting, self._plugin, self._storageKey, encoded)
	if not writeOk then
		pcall(self._plugin.SetSetting, self._plugin, self._storageKey, storedBefore)
		return false, "Could not save presets: " .. tostring(writeError)
	end

	local readOk, stored = pcall(self._plugin.GetSetting, self._plugin, self._storageKey)
	if not readOk then
		pcall(self._plugin.SetSetting, self._plugin, self._storageKey, storedBefore)
		return false, "Preset save could not be verified: " .. tostring(stored)
	end
	local verified, verifyError = PresetSerializer.decodeAll(stored)
	if not verified or not PresetSerializer.equal(candidate, verified) then
		pcall(self._plugin.SetSetting, self._plugin, self._storageKey, storedBefore)
		return false, "Preset save could not be verified: " .. tostring(verifyError or "data mismatch")
	end

	self._presets = clone(candidate)
	return true
end

function PresetStore:create(name, captured)
	local normalizedName, nameError = PresetValidator.normalizeName(name)
	if not normalizedName then
		return false, nameError
	elseif self:_findIndex(normalizedName) then
		return false, "A preset with this name already exists"
	end

	local candidate = clone(self._presets)
	local preset = clone(captured)
	preset.name = normalizedName
	local validPreset, validationError = PresetValidator.recipe(preset)
	if not validPreset then
		return false, validationError
	end
	candidate[#candidate + 1] = preset

	local saved, saveError = self:_persist(candidate)
	if not saved then
		return false, saveError
	end
	return true, clone(preset)
end

function PresetStore:update(currentName, captured)
	local index = self:_findIndex(currentName)
	if not index then
		return false, "Recipe not found"
	end

	local candidate = clone(self._presets)
	local recipe = clone(captured)
	recipe.name = candidate[index].name
	local validRecipe, validationError = PresetValidator.recipe(recipe)
	if not validRecipe then
		return false, validationError
	end
	candidate[index] = recipe

	local saved, saveError = self:_persist(candidate)
	if not saved then
		return false, saveError
	end
	return true, clone(recipe)
end

function PresetStore:rename(currentName, requestedName)
	local index = self:_findIndex(currentName)
	if not index then
		return false, "Preset not found"
	end
	local normalizedName, nameError = PresetValidator.normalizeName(requestedName)
	if not normalizedName then
		return false, nameError
	end
	local duplicateIndex = self:_findIndex(normalizedName)
	if duplicateIndex and duplicateIndex ~= index then
		return false, "A preset with this name already exists"
	end

	local candidate = clone(self._presets)
	candidate[index].name = normalizedName
	local saved, saveError = self:_persist(candidate)
	if not saved then
		return false, saveError
	end
	return true, clone(candidate[index])
end

function PresetStore:delete(name)
	local index = self:_findIndex(name)
	if not index then
		return false, "Preset not found"
	end

	local candidate = clone(self._presets)
	table.remove(candidate, index)
	return self:_persist(candidate)
end

return PresetStore
