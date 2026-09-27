local Schema = require(script.Parent.Schema)
local Engine = {}
local services = { "Workspace", "ServerStorage", "ReplicatedStorage", "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService" }
function Engine.allowed(instance)
	if typeof(instance) ~= "Instance" then return false end
	for _, name in ipairs(services) do
		local root = game:GetService(name)
		if instance == root or instance:IsDescendantOf(root) then
			local storage = game.ServerStorage:FindFirstChild("_SchemaForgeSchemas")
			return not storage or (instance ~= storage and not instance:IsDescendantOf(storage))
		end
	end
	return false
end
function Engine.transaction(history, label, change, rollback)
	assert(not game:GetService("RunService"):IsRunning(), "SchemaForge is available in Edit mode only")
	local recording = history:TryBeginRecording("SchemaForge", label)
	assert(recording, "Studio could not start an Undo recording; finish the current operation and retry")
	local ok, result = pcall(function()
		local value = change()
		history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
		return value
	end)
	if not ok then
		local restored, restoreError = pcall(rollback)
		pcall(function() history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end)
		assert(restored, "Rollback failed: " .. tostring(restoreError))
		error(result, 0)
	end
	return result
end
local function inside(instance, roots)
	for _, root in ipairs(roots) do if Engine.allowed(root) and (instance == root or instance:IsDescendantOf(root)) then return true end end
	return false
end
local function childError(instance, rule)
	local current = instance
	for _, name in ipairs(string.split(rule.path, "/")) do
		local found
		for _, child in ipairs(current:GetChildren()) do
			if child.Name == name then
				if found then return "Ambiguous child name: " .. name end
				found = child
			end
		end
		if not found then return "Missing child: " .. rule.path end
		current = found
	end
	if not current:IsA(rule.className) then return "Expected " .. rule.className .. "; found " .. current.ClassName end
	return nil
end
function Engine.audit(schema, roots)
	Schema.validate(schema)
	assert(#roots > 0, "Select a scope or choose Workspace")
	for _, root in ipairs(roots) do assert(Engine.allowed(root), "Scope is outside supported project services") end
	local s = Schema.copy(schema)
	local result = { schema = s, roots = table.clone(roots), issues = {}, matched = 0, valid = 0, objects = {} }
	local seen, checked = {}, 0
	local function issue(instance, field, reason, description, fix)
		assert(#result.issues < 2000, "More than 2000 findings. Narrow the scope; no partial results applied")
		table.insert(result.issues, { instance = instance, path = instance:GetFullName(), field = field, reason = reason, description = description, fix = fix })
	end
	local stack = table.clone(roots)
	while #stack > 0 do
		local instance = table.remove(stack)
		if seen[instance] or not Engine.allowed(instance) then continue end
		seen[instance] = true; checked += 1
		assert(checked <= 100000, "Scope exceeds 100000 instances. Select a smaller folder")
		for _, child in ipairs(instance:GetChildren()) do table.insert(stack, child) end
		if not instance:HasTag(s.tag) then continue end
		result.matched += 1
		assert(result.matched <= 5000, "More than 5000 tagged objects. Narrow the scope")
		table.insert(result.objects, instance)
		local before = #result.issues
		if not instance:IsA(s.className) then
			issue(instance, "Class", "Expected " .. s.className .. "; found " .. instance.ClassName, "", nil)
		else
			for _, f in ipairs(s.fields) do
				local value = instance:GetAttribute(f.name)
				if value == nil then
					if f.required then issue(instance, f.name, "Missing " .. f.kind, f.description, f.hasDefault and { value = f.default, parent = instance.Parent } or nil) end
				else
					local err = Schema.valueError(f, value)
					if err then issue(instance, f.name, err, f.description, nil) end
				end
			end
			for _, c in ipairs(s.children) do
				local err = childError(instance, c)
				if err then issue(instance, c.path, err, c.description, nil) end
			end
		end
		if #result.issues == before then result.valid += 1 end
	end
	table.sort(result.issues, function(a, b) if a.path == b.path then return a.field < b.field end; return a.path < b.path end)
	return result
end
function Engine.preview(result)
	assert(result and result.schema, "Run an audit first")
	local plan = { schema = Schema.copy(result.schema), roots = table.clone(result.roots), changes = {} }
	for _, i in ipairs(result.issues) do
		if i.fix then table.insert(plan.changes, { instance = i.instance, path = i.path, name = i.field, value = i.fix.value, parent = i.fix.parent }) end
	end
	return plan
end
function Engine.apply(plan, history)
	assert(plan and #plan.changes > 0, "No missing defaults to apply")
	Schema.validate(plan.schema)
	local seen = {}
	for _, c in ipairs(plan.changes) do
		assert(Engine.allowed(c.instance) and inside(c.instance, plan.roots) and c.instance.Parent == c.parent and c.instance:HasTag(plan.schema.tag) and c.instance:IsA(plan.schema.className), "Object or scope changed. Run the audit again")
		assert(c.instance:GetAttribute(c.name) == nil, "Attribute changed since audit. Run the audit again")
		seen[c.instance] = seen[c.instance] or {}; assert(not seen[c.instance][c.name], "Duplicate repair"); seen[c.instance][c.name] = true
		local rule
		for _, f in ipairs(plan.schema.fields) do if f.name == c.name then rule = f; break end end
		assert(rule and rule.required and rule.hasDefault and rule.default == c.value and not Schema.valueError(rule, c.value), "Invalid repair plan")
	end
	local changed = {}
	return Engine.transaction(history, "SchemaForge: add missing defaults", function()
		for _, c in ipairs(plan.changes) do
			c.instance:SetAttribute(c.name, c.value); table.insert(changed, c)
		end
		return #changed
	end, function() for _, c in ipairs(changed) do c.instance:SetAttribute(c.name, nil) end end)
end
function Engine.selectIssues(result, selection)
	assert(result, "Run an audit first")
	local objects, seen = {}, {}
	for _, i in ipairs(result.issues) do
		if Engine.allowed(i.instance) and not seen[i.instance] then table.insert(objects, i.instance); seen[i.instance] = true end
	end
	selection:Set(objects); return #objects
end
return Engine
