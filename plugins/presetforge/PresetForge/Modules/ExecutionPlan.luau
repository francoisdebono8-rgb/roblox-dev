local Constants = require(script.Parent.Constants)
local Guard = require(script.Parent.DataGuard)
local Serializer = require(script.Parent.PresetSerializer)
local Schema = require(script.Parent.Schema)
local ValueCodec = require(script.Parent.ValueCodec)
local AttributeCodec = require(script.Parent.AttributeCodec)

local ExecutionPlan = {}
local issued = setmetatable({}, { __mode = "k" })

local function ancestry(instance)
	local chain, current = {}, instance
	while current do
		assert(#chain < 512, "Target ancestry limit exceeded")
		chain[#chain + 1] = current
		current = current.Parent
	end
	return chain
end

local function snapshot(recipe, resolved, collection)
	local states = {}
	for _, instance in ipairs(resolved.compatible) do
		local state = { instance = instance, className = instance.ClassName, ancestry = ancestry(instance), properties = {}, attributes = {}, tags = {} }
		for name in pairs(recipe.properties) do state.properties[name] = instance[name] end
		for name in pairs(recipe.attributes) do
			local value = instance:GetAttribute(name)
			state.attributes[name] = { exists = value ~= nil, value = value }
		end
		for _, name in ipairs(recipe.tags) do state.tags[name] = collection:HasTag(instance, name) end
		states[#states + 1] = state
	end
	return states
end

local function sameStates(left, right)
	if #left ~= #right then return false end
	for index, a in ipairs(left) do
		local b = right[index]
		if a.instance ~= b.instance or a.className ~= b.className or not Guard.equal(a.ancestry, b.ancestry)
			or not Guard.equal(a.tags, b.tags) then return false end
		for name, value in pairs(a.properties) do if not ValueCodec.equalAny(value, b.properties[name]) then return false end end
		for name, value in pairs(a.attributes) do
			if value.exists ~= b.attributes[name].exists or not ValueCodec.equalAny(value.value, b.attributes[name].value) then return false end
		end
	end
	return true
end

function ExecutionPlan.preflight(plan)
	local valid, validationError = require(script.Parent.PresetValidator).recipe(plan.recipe)
	if not valid then return false, validationError end
	for _, entry in ipairs(plan.entries) do
		if not Schema.isCompatible(plan.schemaId, entry.instance) then return false, "Incompatible target" end
		local probe
		local ok, err = pcall(function()
			probe = Instance.new(entry.instance.ClassName)
			-- Reproduce controlled class state to catch interacting setters without project writes.
			for _, definition in ipairs(Schema.get(plan.schemaId).properties) do probe[definition.name] = entry.instance[definition.name] end
			for _, change in ipairs(entry.changes) do
				if change.kind == "property" then
					assert(Schema.validateValue(plan.schemaId, change.name, change.after))
					probe[change.name] = change.after
				elseif change.kind == "attribute" then
					probe:SetAttribute(change.name, change.after)
					assert(AttributeCodec.equal(probe:GetAttribute(change.name), change.after), "Attribute readback mismatch")
				elseif change.kind == "tag" then
					probe:AddTag(change.name)
					assert(probe:HasTag(change.name), "Tag readback mismatch")
				else error("Unsupported planned write") end
			end
			for name, value in pairs(plan.recipe.properties) do
				assert(ValueCodec.equal(Schema.property(plan.schemaId, name), probe[name], value), "Property coercion/clamp mismatch: " .. name)
			end
		end)
		if probe then probe:Destroy() end
		if not ok then return false, "Preflight rejected: " .. tostring(err) end
	end
	return true
end

function ExecutionPlan.issue(preview, recipe, roots, resolved, resolver, collection, revision)
	local encoded, err = Serializer.encodePreset(recipe)
	if not encoded then return nil, err end
	local normalized = assert(Serializer.decodePreset(encoded))
	local entries, counts = {}, { targets = preview.affectedCount, properties = 0, tags = 0, attributes = 0 }
	for _, result in ipairs(preview.results) do
		if result.status == "affected" then
			entries[#entries + 1] = { instance = result.instance, changes = Guard.copy(result.changes) }
			for _, change in ipairs(result.changes) do
				local key = ({ property = "properties", tag = "tags", attribute = "attributes" })[change.kind]
				counts[key] += 1
			end
		end
	end
	local plan = {
		recipe = normalized, schemaId = recipe.schemaId, schemaVersion = Constants.SCHEMA_VERSION,
		options = Guard.copy(resolved.options), roots = table.clone(roots), revision = revision or recipe.revision,
		library = recipe.library, entries = entries, counts = counts,
		states = snapshot(normalized, resolved, collection), rootAncestry = {},
	}
	for _, root in ipairs(roots) do plan.rootAncestry[#plan.rootAncestry + 1] = ancestry(root) end
	local valid, preflightError = ExecutionPlan.preflight(plan)
	if not valid then return nil, preflightError end
	Guard.freeze(plan)
	issued[plan] = { resolver = resolver, collection = collection, encoded = encoded }
	return plan
end

local function validate(plan, context, record)
	local ok, err = pcall(function()
		assert(type(context) == "table" and type(context.recipe) == "table", "Current recipe, selection and scope are required")
		assert(plan.schemaVersion == Constants.SCHEMA_VERSION, "Schema changed")
		assert(plan.revision == (context.revision or context.recipe.revision) and plan.library == context.recipe.library, "Recipe revision changed")
		local encoded = Serializer.encodePreset(context.recipe)
		assert(encoded and Guard.equal(encoded, record.encoded), "Recipe changed")
		assert(Guard.equal(plan.roots, context.selection), "Selection membership/order changed")
		for index, root in ipairs(plan.roots) do assert(Guard.equal(plan.rootAncestry[index], ancestry(root)), "Root ancestry changed") end
		local resolved, resolveError = record.resolver:resolve(plan.schemaId, context.selection, context.options)
		assert(resolved, resolveError)
		assert(Guard.equal(plan.options, resolved.options), "Scope/filter changed")
		assert(sameStates(plan.states, snapshot(plan.recipe, resolved, record.collection)), "Target set, ancestry or planned values changed")
	end)
	if not ok then return false, "Stale Preview: " .. tostring(err) end
	return true
end

function ExecutionPlan.validate(plan, context)
	local record = type(plan) == "table" and issued[plan]
	if not record then return false, "A fresh, unused Preview plan is required" end
	return validate(plan, context, record)
end

function ExecutionPlan.consume(plan, context)
	local record = type(plan) == "table" and issued[plan]
	if not record then return false, "A fresh, unused Preview plan is required" end
	issued[plan] = nil
	local function current()
		local ok, value = pcall(function() return if type(context) == "function" then context() else context end)
		if not ok then return false, "Current context unavailable: " .. tostring(value) end
		return validate(plan, value, record)
	end
	local valid, err = current()
	if not valid then return false, err end
	local ready, preflightError = ExecutionPlan.preflight(plan)
	if not ready then return false, preflightError end
	return true, current
end

return ExecutionPlan
