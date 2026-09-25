local AttributeCodec = require(script.Parent.AttributeCodec)
local Constants = require(script.Parent.Constants)

local PreviewService = {}
PreviewService.__index = PreviewService

local function increment(map, key)
	map[key] = (map[key] or 0) + 1
end

function PreviewService.new(collectionService)
	return setmetatable({
		_collectionService = collectionService,
	}, PreviewService)
end

function PreviewService:build(preset, selection)
	local preview = {
		selectionCount = #selection,
		compatibleCount = 0,
		ignoredCount = 0,
		targets = {},
		targetStates = {},
		propertyChanges = {},
		tagChanges = {},
		attributeChanges = {},
		warnings = {},
		totalChanges = 0,
	}

	for _, instance in ipairs(selection) do
		if instance:IsA("BasePart") then
			preview.compatibleCount += 1
			preview.targets[#preview.targets + 1] = instance
			local targetState = {
				properties = {},
				tags = {},
				attributes = {},
			}
			preview.targetStates[#preview.targetStates + 1] = targetState

			if preset.capture.properties then
				for _, propertyName in ipairs(Constants.PROPERTIES) do
					local ok, currentValue = pcall(function()
						return instance[propertyName]
					end)
					if not ok then
						preview.warnings[#preview.warnings + 1] = instance:GetFullName() .. ": " .. propertyName .. " is unreadable"
					else
						targetState.properties[propertyName] = currentValue
						if currentValue ~= preset.properties[propertyName] then
							increment(preview.propertyChanges, propertyName)
							preview.totalChanges += 1
						end
					end
				end
			end

			if preset.capture.tags then
				for _, tag in ipairs(preset.tags) do
					local hasTag = self._collectionService:HasTag(instance, tag)
					targetState.tags[tag] = hasTag
					if not hasTag then
						increment(preview.tagChanges, tag)
						preview.totalChanges += 1
					end
				end
			end

			if preset.capture.attributes then
				local currentAttributes = instance:GetAttributes()
				for attributeName, desiredValue in pairs(preset.attributes) do
					local currentValue = currentAttributes[attributeName]
					targetState.attributes[attributeName] = {
						exists = currentValue ~= nil,
						value = currentValue,
					}
					if currentValue == nil then
						local changes = preview.attributeChanges[attributeName] or { added = 0, updated = 0 }
						changes.added += 1
						preview.attributeChanges[attributeName] = changes
						preview.totalChanges += 1
					elseif not AttributeCodec.equal(currentValue, desiredValue) then
						local changes = preview.attributeChanges[attributeName] or { added = 0, updated = 0 }
						changes.updated += 1
						preview.attributeChanges[attributeName] = changes
						preview.totalChanges += 1
					end
				end
			end
		else
			preview.ignoredCount += 1
		end
	end

	if preview.ignoredCount > 0 then
		preview.warnings[#preview.warnings + 1] = string.format(
			"%d non-BasePart selection%s will be ignored",
			preview.ignoredCount,
			preview.ignoredCount == 1 and "" or "s"
		)
	end
	if preview.compatibleCount == 0 then
		preview.warnings[#preview.warnings + 1] = "Select at least one BasePart target"
	elseif preview.totalChanges == 0 then
		preview.warnings[#preview.warnings + 1] = "Selected BaseParts already match this preset"
	end

	return preview
end

local function sameScalarMap(left, right)
	for key, value in pairs(left) do
		if right[key] ~= value then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function sameTargetStates(left, right)
	if #left ~= #right then
		return false
	end

	for index, leftState in ipairs(left) do
		local rightState = right[index]
		if not rightState
			or not sameScalarMap(leftState.properties, rightState.properties)
			or not sameScalarMap(leftState.tags, rightState.tags) then
			return false
		end

		for attributeName, leftAttribute in pairs(leftState.attributes) do
			local rightAttribute = rightState.attributes[attributeName]
			if not rightAttribute
				or leftAttribute.exists ~= rightAttribute.exists
				or (leftAttribute.exists and not AttributeCodec.equal(leftAttribute.value, rightAttribute.value)) then
				return false
			end
		end
		for attributeName in pairs(rightState.attributes) do
			if leftState.attributes[attributeName] == nil then
				return false
			end
		end
	end

	return true
end

local function sameMap(left, right)
	for key, value in pairs(left) do
		local other = right[key]
		if type(value) == "table" then
			if type(other) ~= "table" or value.added ~= other.added or value.updated ~= other.updated then
				return false
			end
		elseif value ~= other then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

function PreviewService.same(left, right)
	if left == nil or right == nil then
		return false
	elseif left.selectionCount ~= right.selectionCount
		or left.compatibleCount ~= right.compatibleCount
		or left.ignoredCount ~= right.ignoredCount
		or left.totalChanges ~= right.totalChanges
		or #left.targets ~= #right.targets then
		return false
	end

	for index, target in ipairs(left.targets) do
		if target ~= right.targets[index] then
			return false
		end
	end

	return sameMap(left.propertyChanges, right.propertyChanges)
		and sameMap(left.tagChanges, right.tagChanges)
		and sameMap(left.attributeChanges, right.attributeChanges)
		and sameTargetStates(left.targetStates, right.targetStates)
end

return PreviewService
