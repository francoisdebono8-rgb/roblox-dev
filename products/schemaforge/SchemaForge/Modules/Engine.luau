local Schema = require(script.Parent.Schema)
local Engine = {}
local services = { "Workspace", "ServerStorage", "ReplicatedStorage", "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService" }
local audits = setmetatable({}, { __mode = "k" })
local plans = setmetatable({}, { __mode = "k" })
local identities = setmetatable({}, { __mode = "k" })
local nextIdentity = 0

local function equal(a, b)
	if a == b then return true end
	if type(a) == "number" and type(b) == "number" and a ~= a and b ~= b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

local function list(value, limit)
	assert(type(value) == "table" and #value <= limit, "Invalid or oversized findings list")
	local count = 0
	for k in pairs(value) do
		count += 1
		assert(count <= limit and type(k) == "number" and k % 1 == 0 and k >= 1 and k <= #value, "Invalid findings list")
	end
	assert(count == #value, "Invalid findings list")
end

local function lineage(instance)
	local chain = {}
	while instance do
		table.insert(chain, { instance = instance, name = instance.Name })
		instance = instance.Parent
	end
	return chain
end

local function identity(instance)
	if not identities[instance] then nextIdentity += 1; identities[instance] = nextIdentity end
	return instance.Name .. " [" .. instance.ClassName .. " #" .. identities[instance] .. "]"
end

local function clipped(value)
	return #value > 480 and value:sub(1, 477) .. "..." or value
end

local function actualValue(value)
	local valueText = typeof(value) == "string" and string.format("%q", clipped(value)) or tostring(value)
	return clipped(valueText) .. " (" .. typeof(value) .. ")"
end

local function expectedValue(rule)
	local constraints = {}
	if rule.integer then table.insert(constraints, "integer") end
	if rule.min ~= nil then table.insert(constraints, "min " .. tostring(rule.min)) end
	if rule.max ~= nil then table.insert(constraints, "max " .. tostring(rule.max)) end
	if #rule.choices > 0 then
		local choices = {}
		for _, choice in ipairs(rule.choices) do table.insert(choices, string.format("%q", choice)) end
		table.insert(constraints, "one of " .. table.concat(choices, ", "))
	end
	return clipped(rule.kind .. (#constraints > 0 and " (" .. table.concat(constraints, "; ") .. ")" or ""))
end
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
	local steps = {}
	for _, name in ipairs(string.split(rule.path, "/")) do
		local matches = {}
		for _, child in ipairs(current:GetChildren()) do
			if child.Name == name then table.insert(matches, child) end
		end
		table.insert(steps, matches)
		if #matches > 1 then return "Ambiguous child name: " .. name, "Ambiguous child name: " .. name, steps end
		if #matches == 0 then return "Missing child: " .. rule.path, "Missing", steps end
		current = matches[1]
	end
	if not current:IsA(rule.className) then return "Expected " .. rule.className .. "; found " .. current.ClassName, current.ClassName, steps end
	return nil, current.ClassName, steps
end

-- Snapshot only tagged objects and the child paths their contract actually reads.
-- The bounded scope walk also detects newly tagged, inserted or removed objects.
local function scan(schema, roots, visit)
	assert(#roots > 0, "Select a scope or choose Workspace")
	local snapshot = { roots = {}, objects = {} }
	for _, root in ipairs(roots) do
		assert(Engine.allowed(root), "Scope is outside supported project services")
		table.insert(snapshot.roots, lineage(root))
	end
	local seen, checked, matched = {}, 0, 0
	local stack = table.clone(roots)
	while #stack > 0 do
		local instance = table.remove(stack)
		if seen[instance] or not Engine.allowed(instance) then continue end
		seen[instance] = true; checked += 1
		assert(checked <= 100000, "Scope exceeds 100000 instances. Select a smaller folder")
		for _, child in ipairs(instance:GetChildren()) do table.insert(stack, child) end
		if not instance:HasTag(schema.tag) then continue end
		matched += 1
		assert(matched <= 5000, "More than 5000 tagged objects. Narrow the scope")
		local tags = instance:GetTags(); table.sort(tags)
		local children = {}
		if instance:IsA(schema.className) then
			for _, rule in ipairs(schema.children) do
				local _, _, steps = childError(instance, rule)
				table.insert(children, steps)
			end
		end
		snapshot.objects[instance] = { lineage = lineage(instance), attributes = instance:GetAttributes(), tags = tags, children = children }
		if visit then visit(instance) end
	end
	return snapshot
end

function Engine.audit(schema, roots)
	Schema.validate(schema)
	local s = Schema.copy(schema)
	local result = { schema = s, roots = table.clone(roots), issues = {}, matched = 0, valid = 0, objects = {} }
	local order = {}
	local function issue(instance, field, reason, category, expected, actual, description, fix)
		assert(#result.issues < 2000, "More than 2000 findings. Narrow the scope; no partial results applied")
		local finding = { instance = instance, path = instance:GetFullName(), identity = identity(instance), field = field,
			reason = reason, category = category, expected = expected, actual = actual, description = description, fix = fix }
		table.insert(result.issues, finding); order[finding] = #result.issues
	end
	local snapshot = scan(s, roots, function(instance)
		result.matched += 1
		table.insert(result.objects, instance)
		local before = #result.issues
		if not instance:IsA(s.className) then
			issue(instance, "Class", "Expected " .. s.className .. "; found " .. instance.ClassName, "Class", s.className, instance.ClassName, "", nil)
		else
			for _, f in ipairs(s.fields) do
				local value = instance:GetAttribute(f.name)
				if value == nil then
					if f.required then issue(instance, f.name, "Missing " .. f.kind, "Missing", expectedValue(f), "Missing", f.description, f.hasDefault and { value = f.default, parent = instance.Parent } or nil) end
				else
					local err = Schema.valueError(f, value)
					if err then issue(instance, f.name, err, typeof(value) ~= f.kind and "Wrong type" or "Invalid value", expectedValue(f), actualValue(value), f.description, nil) end
				end
			end
			for _, c in ipairs(s.children) do
				local err, actual = childError(instance, c)
				if err then issue(instance, c.path, err, "Required child", c.className .. " at " .. c.path, actual, c.description, nil) end
			end
		end
		if #result.issues == before then result.valid += 1 end
	end)
	table.sort(result.issues, function(a, b)
		if (a.fix ~= nil) ~= (b.fix ~= nil) then return a.fix ~= nil end
		if a.path ~= b.path then return a.path < b.path end
		if a.field ~= b.field then return a.field < b.field end
		return order[a] < order[b]
	end)
	local members = {}
	for _, finding in ipairs(result.issues) do members[finding] = Schema.copy(finding) end
	audits[result] = { schema = Schema.copy(s), roots = table.clone(roots), sourceSchema = schema, sourceRoots = roots,
		scope = snapshot, members = members, issues = table.clone(result.issues) }
	return result
end

local function auditState(result)
	local state = audits[result]
	assert(state, "Run an audit first")
	assert(equal(result.schema, state.schema) and equal(result.roots, state.roots), "Schema or scope changed. Run the audit again")
	assert(equal(state.sourceSchema, state.schema) and equal(state.sourceRoots, state.roots), "Schema or scope changed. Run the audit again")
	list(result.issues, 2000)
	assert(#result.issues == #state.issues, "Audit findings changed. Run the audit again")
	for index, finding in ipairs(result.issues) do
		assert(finding == state.issues[index] and equal(finding, state.members[finding]), "Audit findings changed. Run the audit again")
	end
	return state
end

local function subset(result, issues)
	local state = auditState(result)
	if issues == nil then return state.issues end
	list(issues, #state.issues)
	local selected, ordered = {}, {}
	for _, finding in ipairs(issues) do
		assert(state.members[finding] and not selected[finding], "Invalid or duplicate finding; use findings from this audit")
		selected[finding] = true
	end
	for _, finding in ipairs(state.issues) do if selected[finding] then table.insert(ordered, finding) end end
	return ordered
end

-- nil/"All" means any reason; nil/"" means any field ("All" is a valid field).
-- selected accepts an array or boolean-valued set
-- of original findings or matched Instances; an empty selection matches nothing.
function Engine.filteredIssues(result, reason, field, selected)
	local state = auditState(result)
	assert(reason == nil or type(reason) == "string", "Invalid reason filter")
	assert(field == nil or type(field) == "string", "Invalid field filter")
	local findings, objects = {}, {}
	if selected ~= nil then
		assert(type(selected) == "table", "Invalid findings selection")
		local count = 0
		for key, value in pairs(selected) do
			count += 1; assert(count <= 5000, "Selection exceeds 5000 entries")
			local target, enabled = key, value
			if type(key) == "number" then
				assert(key % 1 == 0 and key >= 1 and key <= 5000, "Invalid findings selection")
				target, enabled = value, true
			else assert(type(enabled) == "boolean", "Invalid findings selection") end
			if state.members[target] then findings[target] = enabled
			else
				assert(state.scope.objects[target], "Selection must belong to this audit")
				objects[target] = enabled
			end
		end
	end
	local filtered = {}
	for _, finding in ipairs(state.issues) do
		if (reason == nil or reason == "All" or finding.category == reason)
			and (field == nil or field == "" or finding.field == field)
			and (selected == nil or findings[finding] or objects[finding.instance]) then
			table.insert(filtered, finding)
		end
	end
	return filtered
end

function Engine.isFresh(resultOrPlan)
	local ok, fresh = pcall(function()
		local state = audits[resultOrPlan]
		if state then auditState(resultOrPlan)
		else
			local plan = plans[resultOrPlan]
			if not plan then return false end
			state = auditState(plan.result)
			if not equal(resultOrPlan.schema, state.schema) or not equal(resultOrPlan.roots, state.roots)
				or not equal(resultOrPlan.changes, plan.changes) then return false end
		end
		return equal(scan(state.schema, state.roots), state.scope)
	end)
	return ok and fresh == true
end

function Engine.preview(result, issues)
	local findings = subset(result, issues)
	assert(Engine.isFresh(result), "Project changed since audit. Run the audit again")
	local plan = { schema = Schema.copy(result.schema), roots = table.clone(result.roots), changes = {} }
	for _, i in ipairs(findings) do
		if i.fix then table.insert(plan.changes, { instance = i.instance, path = i.path, identity = i.identity, name = i.field, value = i.fix.value, parent = i.fix.parent }) end
	end
	plans[plan] = { result = result, changes = Schema.copy(plan.changes) }
	return plan
end
function Engine.apply(plan, history)
	assert(plan and #plan.changes > 0, "No missing defaults to apply")
	assert(Engine.isFresh(plan), "Plan or project changed since audit. Run the audit again")
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
		assert(Engine.isFresh(plan), "Project changed since preview. Run the audit again")
		for _, c in ipairs(plan.changes) do
			c.instance:SetAttribute(c.name, c.value); table.insert(changed, c)
		end
		return #changed
	end, function() for _, c in ipairs(changed) do c.instance:SetAttribute(c.name, nil) end end)
end
function Engine.selectIssues(result, selection, issues)
	local objects, seen = {}, {}
	for _, i in ipairs(subset(result, issues)) do
		if Engine.allowed(i.instance) and not seen[i.instance] then table.insert(objects, i.instance); seen[i.instance] = true end
	end
	selection:Set(objects); return #objects
end
return Engine
