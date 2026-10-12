local Constants = require(script.Parent.Constants)
local Schema = require(script.Parent.Schema)
local Guard = require(script.Parent.DataGuard)

local TargetResolver = {}
TargetResolver.__index = TargetResolver

local function trim(value)
	return value:match("^%s*(.-)%s*$")
end

function TargetResolver.new(collectionService)
	return setmetatable({
		_collectionService = collectionService,
	}, TargetResolver)
end

function TargetResolver:validateOptions(schemaId, options)
	if type(options) ~= "table" or (options.scope ~= "Selection" and options.scope ~= "Descendants") then
		return nil, "Choose Selection or Descendants scope"
	end
	if options.scope == "Selection" then
		return {
			scope = "Selection",
			className = Schema.defaultClassFilter(schemaId),
			nameContains = "",
			tag = "",
		}
	end

	local className = trim(type(options.className) == "string" and options.className or "")
	local nameContains = trim(type(options.nameContains) == "string" and options.nameContains or "")
	local tag = trim(type(options.tag) == "string" and options.tag or "")
	if not Schema.isClassFilterAllowed(schemaId, className) then
		return nil, "Choose a supported class filter for this recipe"
	elseif #nameContains > Constants.MAX_FILTER_BYTES or nameContains:find("%c") then
		return nil, "Name filter must be 80 bytes or fewer without control characters"
	elseif #tag > Constants.MAX_FILTER_BYTES or tag:find("%c") then
		return nil, "Tag filter must be 80 bytes or fewer without control characters"
	end
	return {
		scope = "Descendants",
		className = className,
		nameContains = nameContains,
		tag = tag,
	}
end

local function addUnique(items, seen, instance)
	if not seen[instance] then
		seen[instance] = true
		items[#items + 1] = instance
	end
end

function TargetResolver:resolve(schemaId, selection, options)
	if not Guard.array(selection, Constants.MAX_ROOTS) then return nil, "Root/selection limit exceeded or invalid list" end
	for _, root in ipairs(selection) do
		if typeof(root) ~= "Instance" then return nil, "Invalid selection root" end
	end
	local normalized, optionsError = self:validateOptions(schemaId, options)
	if not normalized then
		return nil, optionsError
	end

	local scanned = {}
	local seen = {}
	if normalized.scope == "Selection" then
		for _, instance in ipairs(selection) do
			addUnique(scanned, seen, instance)
		end
	else
		-- Traverse each subtree once, including when a selected root is nested in another.
		local expanded = {}
		local function expand(root)
			local stack = { root }
			while #stack > 0 do
				local container = table.remove(stack)
				if not expanded[container] then
					expanded[container] = true
					local children = container:GetChildren()
					for _, child in ipairs(children) do
						addUnique(scanned, seen, child)
						if #scanned > Constants.MAX_SCANNED then return false end
					end
					for index = #children, 1, -1 do
						if not expanded[children[index]] then stack[#stack + 1] = children[index] end
					end
				end
			end
			return true
		end
		for _, root in ipairs(selection) do
			if not expand(root) then return nil, "Scanned descendant limit exceeded" end
		end
	end

	local compatible = {}
	local ignored = {}
	local nameNeedle = string.lower(normalized.nameContains)
	for _, instance in ipairs(scanned) do
		local reason = nil
		if normalized.scope == "Descendants" and not Schema.matchesClassFilter(schemaId, instance, normalized.className) then
			reason = "class filter"
		elseif nameNeedle ~= "" and not string.find(string.lower(instance.Name), nameNeedle, 1, true) then
			reason = "name filter"
		elseif normalized.tag ~= "" and not self._collectionService:HasTag(instance, normalized.tag) then
			reason = "tag filter"
		elseif not Schema.isCompatible(schemaId, instance) then
			reason = "incompatible class"
		end

		if reason then
			ignored[#ignored + 1] = {
				instance = instance,
				path = instance:GetFullName(),
				reason = reason,
			}
		else
			compatible[#compatible + 1] = instance
			if #compatible > Constants.MAX_COMPATIBLE then return nil, "Compatible target limit exceeded" end
		end
	end

	return {
		options = normalized,
		selectionCount = #selection,
		scannedCount = #scanned,
		compatible = compatible,
		ignored = ignored,
	}
end

return TargetResolver
