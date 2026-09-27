local AttributeCodec = require(script.Parent.AttributeCodec)
local PresetValidator = require(script.Parent.PresetValidator)
local Schema = require(script.Parent.Schema)
local ValueCodec = require(script.Parent.ValueCodec)

local ApplyService = {}
ApplyService.__index = ApplyService

local function sortedKeys(values)
	local keys = {}
	for key in pairs(values) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

function ApplyService.new(collectionService, changeHistoryService)
	return setmetatable({
		_collectionService = collectionService,
		_changeHistoryService = changeHistoryService,
	}, ApplyService)
end

function ApplyService:_backup(recipe, targets)
	local backups = {}
	local ok, backupError = pcall(function()
		for _, target in ipairs(targets) do
			assert(Schema.isCompatible(recipe.schemaId, target), "incompatible target")
			local backup = {
				target = target,
				properties = {},
				addedTags = {},
				attributes = {},
			}
			for propertyName in pairs(recipe.properties) do
				backup.properties[propertyName] = target[propertyName]
			end
			if recipe.capture.attributes then
				local attributes = target:GetAttributes()
				for attributeName in pairs(recipe.attributes) do
					backup.attributes[attributeName] = {
						exists = attributes[attributeName] ~= nil,
						value = attributes[attributeName],
					}
				end
			end
			backups[#backups + 1] = backup
		end
	end)
	if not ok then
		return nil, "Could not prepare a safe apply: " .. tostring(backupError)
	end
	return backups
end

function ApplyService:_rollback(backups)
	local errors = {}
	for index = #backups, 1, -1 do
		local backup = backups[index]
		local ok, rollbackError = pcall(function()
			for propertyName, value in pairs(backup.properties) do
				backup.target[propertyName] = value
			end
			for _, tag in ipairs(backup.addedTags) do
				self._collectionService:RemoveTag(backup.target, tag)
			end
			for attributeName, previous in pairs(backup.attributes) do
				backup.target:SetAttribute(attributeName, if previous.exists then previous.value else nil)
			end
		end)
		if not ok then
			errors[#errors + 1] = backup.target:GetFullName() .. ": " .. tostring(rollbackError)
		end
	end
	return errors
end

function ApplyService:apply(recipe, targets)
	local validRecipe, recipeError = PresetValidator.recipe(recipe)
	if not validRecipe then
		return false, "Recipe rejected: " .. recipeError
	elseif #targets == 0 then
		return false, "No affected compatible targets"
	end

	local backups, backupError = self:_backup(recipe, targets)
	if not backups then
		return false, backupError
	end

	local recordingOk, recording = pcall(
		self._changeHistoryService.TryBeginRecording,
		self._changeHistoryService,
		"PresetForgeApply",
		"Apply PresetForge recipe"
	)
	if not recordingOk or recording == nil then
		return false, "Could not start an undo recording"
	end

	local counts = { targets = #targets, properties = 0, tags = 0, attributes = 0 }
	local propertyNames = sortedKeys(recipe.properties)
	local appliedOk, applyError = pcall(function()
		for targetIndex, target in ipairs(targets) do
			local backup = backups[targetIndex]
			for _, propertyName in ipairs(propertyNames) do
				local definition = Schema.property(recipe.schemaId, propertyName)
				local desiredValue = recipe.properties[propertyName]
				if not ValueCodec.equal(definition, target[propertyName], desiredValue) then
					target[propertyName] = desiredValue
					counts.properties += 1
				end
			end

			if recipe.capture.tags then
				for _, tag in ipairs(recipe.tags) do
					if not self._collectionService:HasTag(target, tag) then
						self._collectionService:AddTag(target, tag)
						backup.addedTags[#backup.addedTags + 1] = tag
						counts.tags += 1
					end
				end
			end

			if recipe.capture.attributes then
				local currentAttributes = target:GetAttributes()
				for attributeName, desiredValue in pairs(recipe.attributes) do
					local currentValue = currentAttributes[attributeName]
					if currentValue == nil or not AttributeCodec.equal(currentValue, desiredValue) then
						target:SetAttribute(attributeName, desiredValue)
						counts.attributes += 1
					end
				end
			end
		end
	end)

	if not appliedOk then
		local rollbackErrors = self:_rollback(backups)
		pcall(
			self._changeHistoryService.FinishRecording,
			self._changeHistoryService,
			recording,
			Enum.FinishRecordingOperation.Cancel
		)
		local message = "Apply failed and changes were rolled back: " .. tostring(applyError)
		if #rollbackErrors > 0 then
			message ..= " Rollback errors: " .. table.concat(rollbackErrors, "; ")
		end
		return false, message
	end

	local finishOk, finishError = pcall(
		self._changeHistoryService.FinishRecording,
		self._changeHistoryService,
		recording,
		Enum.FinishRecordingOperation.Commit
	)
	if not finishOk then
		local rollbackErrors = self:_rollback(backups)
		pcall(
			self._changeHistoryService.FinishRecording,
			self._changeHistoryService,
			recording,
			Enum.FinishRecordingOperation.Cancel
		)
		local message = "Could not commit the undo recording; changes were rolled back: " .. tostring(finishError)
		if #rollbackErrors > 0 then
			message ..= " Rollback errors: " .. table.concat(rollbackErrors, "; ")
		end
		return false, message
	end
	return true, counts
end

return ApplyService
