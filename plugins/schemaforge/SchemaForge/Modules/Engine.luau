local Schema = require(script.Parent.Schema)
local Engine = {}
local services = { "Workspace", "ServerStorage", "ReplicatedStorage", "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService" }
local audits = setmetatable({}, { __mode = "k" })
local plans = setmetatable({}, { __mode = "k" })
local storedSchemas = setmetatable({}, { __mode = "k" })
local identities = setmetatable({}, { __mode = "k" })
local nextIdentity = 0
local collection = game:GetService("CollectionService")

function Engine.registerStoredSchema(schema, entry)
	storedSchemas[schema] = {entry = entry, folder = entry.Parent, token = entry.Value}
end

local function storedSchemaFresh(binding, name)
	if not binding then return true end
	local entry, folder = binding.entry, binding.folder
	if entry.Parent ~= folder or entry.Name ~= name or entry.Value ~= binding.token
		or folder.Parent ~= game.ServerStorage or folder.Name ~= "_SchemaForgeSchemas" or folder:GetAttribute("SchemaForgeVersion") ~= 1 then return false end
	local folders, entries = 0, 0
	for _, child in ipairs(game.ServerStorage:GetChildren()) do if child.Name == folder.Name then folders += 1 end end
	for _, child in ipairs(folder:GetChildren()) do if child.Name == name then entries += 1 end end
	return folders == 1 and entries == 1
end

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
		table.insert(chain, instance)
		instance = instance.Parent
	end
	return chain
end

local function identityNumber(instance)
	if not identities[instance] then nextIdentity += 1; identities[instance] = nextIdentity end
	return identities[instance]
end
local function identity(instance)
	return instance.Name .. " [" .. instance.ClassName .. " #" .. identityNumber(instance) .. "]"
end

local function clipped(value)
	return #value > 480 and value:sub(1, 477) .. "..." or value
end

local function actualValue(value)
	local valueText = Schema.formatValue(typeof(value) == "string" and clipped(value) or value)
	return clipped(valueText) .. " (" .. typeof(value) .. ")"
end

local function expectedValue(rule)
	local constraints = {}
	if rule.integer then table.insert(constraints, "integer") end
	if rule.min ~= nil then table.insert(constraints, "min " .. tostring(rule.min)) end
	if rule.max ~= nil then table.insert(constraints, "max " .. tostring(rule.max)) end
	if rule.exact ~= nil then table.insert(constraints, "exact " .. Schema.formatValue(rule.exact)) end
	for _, key in ipairs({"axisMin", "axisMax"}) do
		for _, axis in ipairs({"X", "Y", "Z"}) do
			if rule[key] and rule[key][axis] then table.insert(constraints, axis .. " " .. key .. " " .. rule[key][axis]) end
		end
	end
	for _, key in ipairs({"magnitudeMin", "magnitudeMax"}) do if rule[key] then table.insert(constraints, key .. " " .. rule[key]) end end
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
			local ancestor = instance
			while ancestor and ancestor ~= root do
				if ancestor.Parent == game.ServerStorage and ancestor.Name == "_SchemaForgeSchemas" then return false end
				ancestor = ancestor.Parent
			end
			return true
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
local function childError(instance, rule, cache, metrics)
	local current = instance
	local steps = {}
	for _, name in ipairs(string.split(rule.path, "/")) do
		if not cache[current] then
			local children = current:GetChildren()
			metrics.childVisits += #children
			assert(metrics.childVisits <= 100000, "Child traversal exceeds 100000 instances. Narrow the scope")
			local byName = {}
			for _, child in ipairs(children) do
				byName[child.Name] = byName[child.Name] or {}; table.insert(byName[child.Name], child)
				identityNumber(child)
			end
			for _, matches in pairs(byName) do table.sort(matches, function(a, b) return identityNumber(a) < identityNumber(b) end) end
			cache[current] = byName
		end
		local matches = cache[current][name] or {}
		table.insert(steps, matches)
		if #matches > 1 then return "Ambiguous child name: " .. name, "Ambiguous child name: " .. name, steps end
		if #matches == 0 then return not rule.optional and ("Missing child: " .. rule.path) or nil, "Missing", steps end
		current = matches[1]
	end
	if not current:IsA(rule.className) then return "Expected " .. rule.className .. "; found " .. current.ClassName, current.ClassName, steps end
	return nil, current.ClassName, steps
end

-- GetTagged is authoritative in Edit mode for descendants of DataModel. Keep a
-- bounded full-walk fallback only when that API fails, never for an empty result.
local function candidates(schema, roots, metrics)
	local ok, tagged = pcall(function() return collection:GetTagged(schema.tag) end)
	local result, seen = {}, {}
	if ok then
		metrics.mode = "GetTagged"; metrics.candidateVisits = #tagged
		assert(#tagged <= 100000, "Tag candidate search exceeds 100000 instances")
		for _, instance in ipairs(tagged) do
			if not seen[instance] and Engine.allowed(instance) and inside(instance, roots) then seen[instance] = true; table.insert(result, instance) end
		end
	else
		metrics.mode = "Scope fallback"
		local stack = table.clone(roots)
		while #stack > 0 do
			local instance = table.remove(stack)
			if seen[instance] or not Engine.allowed(instance) then continue end
			seen[instance] = true; metrics.candidateVisits += 1
			assert(metrics.candidateVisits <= 100000, "Scope exceeds 100000 instances. Select a smaller folder")
			if instance:HasTag(schema.tag) then table.insert(result, instance) end
			for _, child in ipairs(instance:GetChildren()) do table.insert(stack, child) end
		end
	end
	assert(#result <= 5000, "More than 5000 tagged objects. Narrow the scope")
	for _, instance in ipairs(result) do identityNumber(instance) end
	table.sort(result, function(a, b)
		local ap, bp = a:GetFullName(), b:GetFullName()
		if ap ~= bp then return ap < bp end
		return identityNumber(a) < identityNumber(b)
	end)
	return result
end
local function scan(schema, roots, visit, metrics)
	list(roots, 5000)
	assert(#roots > 0, "Select a scope or choose Workspace")
	metrics = metrics or { candidateVisits = 0, childVisits = 0 }
	local snapshot = { roots = {}, objects = {} }
	for _, root in ipairs(roots) do
		assert(Engine.allowed(root), "Scope is outside supported project services")
		table.insert(snapshot.roots, lineage(root))
	end
	local cache = {}
	for _, instance in ipairs(candidates(schema, roots, metrics)) do
		local tags, attributes, children, diagnostics = {}, {}, {}, {}
		for _, key in ipairs({"requiredTags", "forbiddenTags"}) do
			for _, tag in ipairs(schema[key] or {}) do tags[tag] = instance:HasTag(tag) end
		end
		if instance:IsA(schema.className) then
			for _, rule in ipairs(schema.fields) do attributes[rule.name] = instance:GetAttribute(rule.name) end
			for _, rule in ipairs(schema.children) do
				local err, actual, steps = childError(instance, rule, cache, metrics)
				table.insert(children, steps)
				table.insert(diagnostics, {error = err, actual = actual})
			end
		end
		snapshot.objects[instance] = { lineage = lineage(instance), attributes = attributes, tags = tags, children = children }
		if visit then visit(instance, diagnostics) end
	end
	return snapshot
end

function Engine.audit(schema, roots)
	Schema.validate(schema)
	local s = Schema.copy(schema)
	local result = { schema = s, roots = table.clone(roots), issues = {}, matched = 0, valid = 0, objects = {}, metrics = {candidateVisits = 0, childVisits = 0} }
	local order = {}
	local function issue(instance, field, reason, category, expected, actual, description, fix)
		assert(#result.issues < 2000, "More than 2000 findings. Narrow the scope; no partial results applied")
		local finding = { instance = instance, path = instance:GetFullName(), identity = identity(instance), field = field,
			reason = reason, category = category, expected = expected, actual = actual, description = description, fix = fix }
		table.insert(result.issues, finding); order[finding] = #result.issues
	end
	local snapshot = scan(s, roots, function(instance, diagnostics)
		result.matched += 1
		table.insert(result.objects, instance)
		local before = #result.issues
		if not instance:IsA(s.className) then
			issue(instance, "Class", "Expected " .. s.className .. "; found " .. instance.ClassName, "Class", s.className, instance.ClassName, "", nil)
		else
			for _, f in ipairs(s.fields) do
				local value = instance:GetAttribute(f.name)
				if value == nil then
					if f.required then issue(instance, f.name, "Missing " .. f.kind, "Missing", expectedValue(f), "Missing", f.description, f.hasDefault and { action = "attribute", value = f.default, parent = instance.Parent } or nil) end
				else
					local err = Schema.valueError(f, value)
					if err then issue(instance, f.name, err, typeof(value) ~= f.kind and "Wrong type" or "Invalid value", expectedValue(f), actualValue(value), f.description, nil) end
				end
			end
			for index, c in ipairs(s.children) do
				local err, actual = diagnostics[index].error, diagnostics[index].actual
				if err then issue(instance, c.path, err, "Required child", c.className .. " at " .. c.path, actual, c.description, nil) end
			end
		end
		for _, tag in ipairs(s.requiredTags or {}) do
			if not instance:HasTag(tag) then issue(instance, tag, "Missing required tag: " .. tag, "Required tag", "Tag present", "Missing", "", {action = "tag", parent = instance.Parent}) end
		end
		for _, tag in ipairs(s.forbiddenTags or {}) do
			if instance:HasTag(tag) then issue(instance, tag, "Forbidden tag: " .. tag, "Forbidden tag", "Tag absent", "Present", "", nil) end
		end
		if #result.issues == before then result.valid += 1 end
	end, result.metrics)
	table.sort(result.issues, function(a, b)
		if (a.fix ~= nil) ~= (b.fix ~= nil) then return a.fix ~= nil end
		if a.path ~= b.path then return a.path < b.path end
		if a.field ~= b.field then return a.field < b.field end
		return order[a] < order[b]
	end)
	local members = {}
	for _, finding in ipairs(result.issues) do members[finding] = Schema.copy(finding) end
	audits[result] = { schema = Schema.copy(s), roots = table.clone(roots), sourceSchema = schema, sourceRoots = roots,
		scope = snapshot, members = members, issues = table.clone(result.issues), storedSchema = storedSchemas[schema] }
	return result
end

local function auditState(result)
	local state = audits[result]
	assert(state, "Run an audit first")
	assert(storedSchemaFresh(state.storedSchema, state.schema.name), "Saved schema changed. Reload and run the audit again")
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
			if plan.subset then
				list(plan.subset, #plan.originalSubset)
				if #plan.subset ~= #plan.originalSubset then return false end
				for index, finding in ipairs(plan.subset) do if finding ~= plan.originalSubset[index] then return false end end
			end
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
		if i.fix then table.insert(plan.changes, { action = i.fix.action, instance = i.instance, path = i.path, identity = i.identity, name = i.field, value = i.fix.value, parent = i.fix.parent }) end
	end
	plans[plan] = { result = result, changes = Schema.copy(plan.changes), subset = issues, originalSubset = issues and table.clone(issues) }
	return plan
end
function Engine.apply(plan, history)
	assert(plan and #plan.changes > 0, "No additive repairs to apply")
	assert(Engine.isFresh(plan), "Plan or project changed since audit. Run the audit again")
	Schema.validate(plan.schema)
	local seen = {}
	for _, c in ipairs(plan.changes) do
		assert(Engine.allowed(c.instance) and inside(c.instance, plan.roots) and c.instance.Parent == c.parent and c.instance:HasTag(plan.schema.tag), "Object or scope changed. Run the audit again")
		local key = c.action .. ":" .. c.name
		seen[c.instance] = seen[c.instance] or {}; assert(not seen[c.instance][key], "Duplicate repair"); seen[c.instance][key] = true
		if c.action == "tag" then
			assert(not c.instance:HasTag(c.name) and table.find(plan.schema.requiredTags or {}, c.name), "Invalid required-tag repair")
		else
			assert(c.action == "attribute" and c.instance:IsA(plan.schema.className) and c.instance:GetAttribute(c.name) == nil, "Attribute changed since audit. Run the audit again")
			local rule
			for _, f in ipairs(plan.schema.fields) do if f.name == c.name then rule = f; break end end
			assert(rule and rule.required and rule.hasDefault and Schema.equalValue(rule.default, c.value) and not Schema.valueError(rule, c.value), "Invalid repair plan")
		end
	end
	local changed = {}
	return Engine.transaction(history, "SchemaForge: additive repairs", function()
		assert(Engine.isFresh(plan), "Project changed since preview. Run the audit again")
		for _, c in ipairs(plan.changes) do
			assert(c.action == "tag" and not c.instance:HasTag(c.name) or c.action == "attribute" and c.instance:GetAttribute(c.name) == nil, "Repair target changed during transaction")
			table.insert(changed, c)
			if c.action == "tag" then c.instance:AddTag(c.name) else c.instance:SetAttribute(c.name, c.value) end
			assert(c.action == "tag" and c.instance:HasTag(c.name) or c.action == "attribute" and Schema.equalValue(c.instance:GetAttribute(c.name), c.value), "Repair value did not persist exactly")
		end
		for _, c in ipairs(changed) do
			assert(c.action == "tag" and c.instance:HasTag(c.name) or c.action == "attribute" and Schema.equalValue(c.instance:GetAttribute(c.name), c.value), "Repair changed before commit")
		end
		return #changed
	end, function()
		local failures = {}
		for index = #changed, 1, -1 do
			local c = changed[index]
			local ok, err = pcall(function()
				if c.action == "tag" then c.instance:RemoveTag(c.name) else c.instance:SetAttribute(c.name, nil) end
				assert(c.action == "tag" and not c.instance:HasTag(c.name) or c.action == "attribute" and c.instance:GetAttribute(c.name) == nil, "Rollback value persisted")
			end)
			if not ok then table.insert(failures, tostring(err)) end
		end
		assert(#failures == 0, table.concat(failures, "; "))
	end)
end
function Engine.selectIssues(result, selection, issues)
	local objects, seen = {}, {}
	for _, i in ipairs(subset(result, issues)) do
		if Engine.allowed(i.instance) and not seen[i.instance] then table.insert(objects, i.instance); seen[i.instance] = true end
	end
	selection:Set(objects); return #objects
end
return Engine
