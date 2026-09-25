local AttributeCodec = require(script.Parent.AttributeCodec)
local Constants = require(script.Parent.Constants)

local ApplyService = {}
ApplyService.__index = ApplyService

function ApplyService.new(collectionService, changeHistoryService)
	return setmetatable({
		_collectionService = collectionService,
		_changeHistoryService = changeHistoryService,
	}, ApplyService)
end

function ApplyService:_backup(preset, targets)
	local backups = {}
	local ok, backupError = pcall(function()
		for _, target in ipairs(targets) do
			local backup = {
				target = target,
				properties = {},
				addedTags = {},
				attributes = {},
			}
			if preset.capture.properties then
				for _, propertyName in ipairs(Constants.PROPERTIES) do
					backup.properties[propertyName] = target[propertyName]
				end
			end
			if preset.capture.attributes then
				local attributes = target:GetAttributes()
				for attributeName in pairs(preset.attributes) do
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
				if previous.exists then
					backup.target:SetAttribute(attributeName, previous.value)
				else
					backup.target:SetAttribute(attributeName, nil)
				end
			end
		end)
		if not ok then
			errors[#errors + 1] = backup.target:GetFullName() .. ": " .. tostring(rollbackError)
		end
	end
	return errors
end

function ApplyService:apply(preset, targets)
	if #targets == 0 then
		return false, "No compatible BasePart targets"
	end

	local backups, backupError = self:_backup(preset, targets)
	if not backups then
		return false, backupError
	end

	local recordingOk, recording = pcall(
		self._changeHistoryService.TryBeginRecording,
		self._changeHistoryService,
		"PresetForgeApply",
		"Apply PresetForge preset"
	)
	if not recordingOk or recording == nil then
		return false, "Could not start an undo recording"
	end

	local counts = { properties = 0, tags = 0, attributes = 0 }
	local appliedOk, applyError = pcall(function()
		for targetIndex, target in ipairs(targets) do
			local backup = backups[targetIndex]
			if preset.capture.properties then
				for _, propertyName in ipairs(Constants.PROPERTIES) do
					local desiredValue = preset.properties[propertyName]
					if target[propertyName] ~= desiredValue then
						target[propertyName] = desiredValue
						counts.properties += 1
					end
				end
			end

			if preset.capture.tags then
				for _, tag in ipairs(preset.tags) do
					if not self._collectionService:HasTag(target, tag) then
						self._collectionService:AddTag(target, tag)
						backup.addedTags[#backup.addedTags + 1] = tag
						counts.tags += 1
					end
				end
			end

			if preset.capture.attributes then
				local currentAttributes = target:GetAttributes()
				for attributeName, desiredValue in pairs(preset.attributes) do
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
