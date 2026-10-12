local AttributeCodec = require(script.Parent.AttributeCodec)
local PresetValidator = require(script.Parent.PresetValidator)
local Schema = require(script.Parent.Schema)
local ValueCodec = require(script.Parent.ValueCodec)
local Constants = require(script.Parent.Constants)
local ExecutionPlan = require(script.Parent.ExecutionPlan)

local PreviewService = {}
PreviewService.__index = PreviewService

local function increment(map, key)
	map[key] = (map[key] or 0) + 1
end

local function sortedKeys(values)
	local keys = {}
	for key in pairs(values) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

function PreviewService.new(collectionService, targetResolver)
	return setmetatable({
		_collectionService = collectionService,
		_targetResolver = targetResolver,
	}, PreviewService)
end

function PreviewService:build(recipe, selection, options, revision)
	local validRecipe, recipeError = PresetValidator.recipe(recipe)
	if not validRecipe then
		return nil, recipeError
	end
	local resolved, resolveError = self._targetResolver:resolve(recipe.schemaId, selection, options)
	if not resolved then
		return nil, resolveError
	end

	local preview = {
		options = resolved.options,
		selectionCount = resolved.selectionCount,
		scannedCount = resolved.scannedCount,
		compatibleCount = #resolved.compatible,
		affectedCount = 0,
		matchingCount = 0,
		ignoredCount = #resolved.ignored,
		targets = {},
		affected = {},
		matching = {},
		ignored = {},
		results = {},
		propertyChanges = {},
		tagChanges = {},
		attributeChanges = {},
		totalChanges = 0,
		warnings = {},
	}

	for _, ignored in ipairs(resolved.ignored) do
		local result = {
			instance = ignored.instance,
			path = ignored.path,
			status = "ignored",
			reason = ignored.reason,
			changes = {},
		}
		preview.ignored[#preview.ignored + 1] = ignored.instance
		preview.results[#preview.results + 1] = result
	end

	for _, instance in ipairs(resolved.compatible) do
		local changes = {}
		for _, propertyName in ipairs(sortedKeys(recipe.properties)) do
			local definition = Schema.property(recipe.schemaId, propertyName)
			local ok, currentValue = pcall(function()
				return instance[propertyName]
			end)
			if not ok then
				return nil, instance:GetFullName() .. ": could not read " .. propertyName
			end
			local desiredValue = recipe.properties[propertyName]
			if not ValueCodec.equal(definition, currentValue, desiredValue) then
				changes[#changes + 1] = {
					kind = "property",
					name = propertyName,
					before = currentValue,
					after = desiredValue,
				}
				increment(preview.propertyChanges, propertyName)
				preview.totalChanges += 1
			end
		end

		if recipe.capture.tags then
			for _, tag in ipairs(recipe.tags) do
				if not self._collectionService:HasTag(instance, tag) then
					changes[#changes + 1] = {
						kind = "tag",
						name = tag,
						before = false,
						after = true,
					}
					increment(preview.tagChanges, tag)
					preview.totalChanges += 1
				end
			end
		end

		if recipe.capture.attributes then
			local currentAttributes = instance:GetAttributes()
			for _, attributeName in ipairs(sortedKeys(recipe.attributes)) do
				local currentValue = currentAttributes[attributeName]
				local desiredValue = recipe.attributes[attributeName]
				if currentValue == nil or not AttributeCodec.equal(currentValue, desiredValue) then
					changes[#changes + 1] = {
						kind = "attribute",
						name = attributeName,
						beforeExists = currentValue ~= nil,
						before = currentValue,
						after = desiredValue,
					}
					local counts = preview.attributeChanges[attributeName] or { added = 0, updated = 0 }
					if currentValue == nil then
						counts.added += 1
					else
						counts.updated += 1
					end
					preview.attributeChanges[attributeName] = counts
					preview.totalChanges += 1
				end
			end
		end

		local status = #changes > 0 and "affected" or "matching"
		local result = {
			instance = instance,
			path = instance:GetFullName(),
			status = status,
			changes = changes,
		}
		preview.results[#preview.results + 1] = result
		if status == "affected" then
			preview.affectedCount += 1
			preview.affected[#preview.affected + 1] = instance
			preview.targets[#preview.targets + 1] = instance
		else
			preview.matchingCount += 1
			preview.matching[#preview.matching + 1] = instance
		end
		if preview.affectedCount > Constants.MAX_AFFECTED then return nil, "Affected target limit exceeded" end
		if preview.totalChanges > Constants.MAX_WRITES then return nil, "Planned write limit exceeded" end
	end

	-- Preserve resolver order within each group, including identical sibling names.
	local grouped = {}
	for _, status in ipairs({ "affected", "matching", "ignored" }) do
		for _, result in ipairs(preview.results) do
			if result.status == status then
				grouped[#grouped + 1] = result
			end
		end
	end
	preview.results = grouped
	if preview.compatibleCount == 0 then
		preview.warnings[#preview.warnings + 1] = "No compatible targets match this scope and filter"
	elseif preview.affectedCount == 0 then
		preview.warnings[#preview.warnings + 1] = "All compatible targets already match this recipe"
	end
	local issuedOk, plan, planError = pcall(ExecutionPlan.issue, preview, recipe, selection, resolved, self._targetResolver, self._collectionService, revision)
	if not issuedOk then return nil, "Planning failed: " .. tostring(plan) end
	if not plan then return nil, planError end
	preview.plan = plan
	preview.metrics = {
		scanned = preview.scannedCount, ignored = preview.ignoredCount, compatible = preview.compatibleCount,
		matching = preview.matchingCount, affected = preview.affectedCount,
		propertyWrites = plan.counts.properties, tagWrites = plan.counts.tags, attributeWrites = plan.counts.attributes,
	}
	return preview
end

local function sameOptions(left, right)
	return left.scope == right.scope
		and left.className == right.className
		and left.nameContains == right.nameContains
		and left.tag == right.tag
end

local function sameChange(left, right)
	return left.kind == right.kind
		and left.name == right.name
		and left.beforeExists == right.beforeExists
		and ValueCodec.equalAny(left.before, right.before)
		and ValueCodec.equalAny(left.after, right.after)
end

function PreviewService.same(left, right)
	if left == nil or right == nil
		or not sameOptions(left.options, right.options)
		or left.selectionCount ~= right.selectionCount
		or left.scannedCount ~= right.scannedCount
		or left.compatibleCount ~= right.compatibleCount
		or left.affectedCount ~= right.affectedCount
		or left.matchingCount ~= right.matchingCount
		or left.ignoredCount ~= right.ignoredCount
		or left.totalChanges ~= right.totalChanges
		or #left.results ~= #right.results then
		return false
	end

	for index, leftResult in ipairs(left.results) do
		local rightResult = right.results[index]
		if not rightResult
			or leftResult.instance ~= rightResult.instance
			or leftResult.path ~= rightResult.path
			or leftResult.status ~= rightResult.status
			or leftResult.reason ~= rightResult.reason
			or #leftResult.changes ~= #rightResult.changes then
			return false
		end
		for changeIndex, leftChange in ipairs(leftResult.changes) do
			if not sameChange(leftChange, rightResult.changes[changeIndex]) then
				return false
			end
		end
	end
	return true
end

return PreviewService
