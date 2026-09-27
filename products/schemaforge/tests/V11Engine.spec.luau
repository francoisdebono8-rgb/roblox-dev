-- Native Studio Edit-mode extension: require(thisModule)(commercial.Modules).
return function(modules)
	local Schema, Engine = require(modules.Schema), require(modules.Engine)
	local history = game:GetService("ChangeHistoryService")
	local pass, fail = 0, 0
	local function rejects(fn) assert(not pcall(fn), "Expected refusal") end
	local function fixture(root)
		local schema = Schema.new()
		schema.name = "V11 contract"; schema.tag = "SchemaForgeV11Test"; schema.className = "Model"
		schema.fields = {
			{ name = "Cost", kind = "number", required = true, hasDefault = true, default = 25, min = 0, max = 100, integer = true, choices = {}, description = "Purchase cost" },
			{ name = "Enabled", kind = "boolean", required = true, hasDefault = true, default = false, integer = false, choices = {}, description = "Enable flag" },
			{ name = "Tier", kind = "string", required = true, hasDefault = false, integer = false, choices = {"Basic", "Rare"}, description = "Crop tier" },
		}
		schema.children = {{ path = "Socket/Prompt", className = "ProximityPrompt", description = "Interaction point" }}
		local function object(name)
			local model = Instance.new("Model"); model.Name = name; model.Parent = root; model:AddTag(schema.tag)
			model:SetAttribute("Cost", 25); model:SetAttribute("Enabled", false); model:SetAttribute("Tier", "Basic")
			local socket = Instance.new("Folder"); socket.Name = "Socket"; socket.Parent = model
			local prompt = Instance.new("ProximityPrompt"); prompt.Name = "Prompt"; prompt.Parent = socket
			return model
		end
		local missing = object("ZMissing"); missing:SetAttribute("Cost", nil); missing:SetAttribute("Enabled", nil)
		local valid = object("Valid")
		local wrong = object("AWrong"); wrong:SetAttribute("Cost", -3.5); wrong:SetAttribute("Enabled", "false"); wrong:SetAttribute("Tier", "Typo")
		local noChild = object("NoChild"); noChild.Socket.Prompt:Destroy()
		local wrongClass = Instance.new("Folder"); wrongClass.Name = "WrongClass"; wrongClass.Parent = root; wrongClass:AddTag(schema.tag)
		return { schema = schema, roots = {root}, missing = missing, valid = valid, wrong = wrong, noChild = noChild, wrongClass = wrongClass, object = object }
	end
	local function test(name, fn)
		local root = Instance.new("Folder"); root.Name = "SchemaForgeV11Fixture"; root.Parent = workspace
		local ok, err = pcall(function() fn(fixture(root), root) end)
		root:Destroy()
		if ok then pass += 1; print("[SchemaForgeV11Engine][PASS] " .. name)
		else fail += 1; warn("[SchemaForgeV11Engine][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function audit(f) return Engine.audit(f.schema, f.roots) end
	local function finding(result, instance, field)
		for _, issue in ipairs(result.issues) do if issue.instance == instance and issue.field == field then return issue end end
		error("Finding not found: " .. field)
	end
	local function refusesStale(f, change)
		local result = audit(f)
		local plan = Engine.preview(result, {finding(result, f.missing, "Cost")})
		assert(Engine.isFresh(result) and Engine.isFresh(plan))
		change()
		assert(not Engine.isFresh(result) and not Engine.isFresh(plan), "Changed audit remained fresh")
		rejects(function() Engine.preview(result) end)
		local recordingStarted = false
		rejects(function() Engine.apply(plan, {TryBeginRecording = function() recordingStarted = true; error("Must not record") end}) end)
		assert(not recordingStarted and f.missing:GetAttribute("Cost") == nil)
	end

	test("Structured categories, expected/actual values and notes preserve V1 reasons", function(f)
		local result = audit(f)
		assert(result.matched == 5 and result.valid == 1 and #result.issues == 7)
		local missing = finding(result, f.missing, "Cost")
		assert(missing.category == "Missing" and missing.reason == "Missing number" and missing.actual == "Missing")
		assert(missing.expected:find("integer", 1, true) and missing.expected:find("min 0", 1, true) and missing.expected:find("max 100", 1, true))
		assert(missing.description == "Purchase cost" and missing.fix.value == 25)
		local wrongType = finding(result, f.wrong, "Enabled")
		assert(wrongType.category == "Wrong type" and wrongType.expected == "boolean" and wrongType.actual == '"false" (string)')
		assert(wrongType.reason == "Expected boolean; found string" and wrongType.description == "Enable flag" and not wrongType.fix)
		local invalid = finding(result, f.wrong, "Cost")
		assert(invalid.category == "Invalid value" and invalid.actual == "-3.5 (number)" and invalid.reason == "Below minimum 0" and not invalid.fix)
		local choice = finding(result, f.wrong, "Tier")
		assert(choice.expected:find('"Basic", "Rare"', 1, true) and choice.description == "Crop tier")
		local child = finding(result, f.noChild, "Socket/Prompt")
		assert(child.category == "Required child" and child.expected == "ProximityPrompt at Socket/Prompt" and child.actual == "Missing")
		assert(child.description == "Interaction point" and not child.fix)
		local class = finding(result, f.wrongClass, "Class")
		assert(class.category == "Class" and class.expected == "Model" and class.actual == "Folder" and class.description == "" and not class.fix)
	end)
	test("Repairable findings sort first with stable path/field ties and duplicate identities", function(f)
		local duplicate = f.missing:Clone(); duplicate.Parent = f.missing.Parent
		local a, b = audit(f), audit(f)
		local first = finding(a, f.missing, "Cost"); local second = finding(a, duplicate, "Cost")
		assert(first.path == second.path and first.identity ~= second.identity)
		local sawUnrepairable = false
		for index, issue in ipairs(a.issues) do
			if not issue.fix then sawUnrepairable = true else assert(not sawUnrepairable) end
			assert(issue.instance == b.issues[index].instance and issue.field == b.issues[index].field and issue.identity == b.issues[index].identity)
		end
		assert(a.issues[1].field == "Cost" and a.issues[2].field == "Cost")
	end)
	test("Category/field filters intersect with finding and object selections", function(f)
		local a = audit(f); local enabled = finding(a, f.missing, "Enabled")
		assert(#Engine.filteredIssues(a) == 7 and #Engine.filteredIssues(a, "All", "") == 7)
		assert(#Engine.filteredIssues(a, "Missing") == 2 and #Engine.filteredIssues(a, "Invalid value") == 2)
		assert(#Engine.filteredIssues(a, nil, "Cost") == 2)
		assert(Engine.filteredIssues(a, "Missing", "Enabled", {f.missing})[1] == enabled)
		assert(Engine.filteredIssues(a, nil, nil, {[enabled] = true})[1] == enabled)
		assert(#Engine.filteredIssues(a, nil, nil, {[f.wrong] = true, [f.missing] = false}) == 3)
		assert(#Engine.filteredIssues(a, nil, nil, {}) == 0)
		assert(#Engine.filteredIssues(a, "Missing", "Tier") == 0)
		local reversed = {a.issues[2], a.issues[1]}
		local filtered = Engine.filteredIssues(a, nil, nil, reversed)
		assert(filtered[1] == a.issues[1] and filtered[2] == a.issues[2])
	end)
	test("Literal All field is filterable and unknown filters match nothing", function(f)
		local rule = Schema.copy(f.schema.fields[1]); rule.name = "All"; table.insert(f.schema.fields, rule)
		local a = audit(f)
		local filtered = Engine.filteredIssues(a, nil, "All")
		assert(#filtered == 4)
		for _, issue in ipairs(filtered) do assert(issue.field == "All") end
		assert(#Engine.filteredIssues(a, "not a reason") == 0 and #Engine.filteredIssues(a, nil, "not a field") == 0)
	end)
	test("Preview and selection use exactly the validated subset without writes", function(f, root)
		local a = audit(f); local before = #root:GetDescendants()
		local enabled = finding(a, f.missing, "Enabled")
		local plan = Engine.preview(a, {enabled, finding(a, f.wrong, "Cost")})
		assert(#plan.changes == 1 and plan.changes[1].instance == f.missing and plan.changes[1].name == "Enabled" and plan.changes[1].value == false)
		assert(plan.changes[1].identity == enabled.identity)
		assert(#Engine.preview(a).changes == 2 and #Engine.preview(a, {}).changes == 0)
		local selected
		local selection = {Set = function(_, objects) selected = objects end}
		assert(Engine.selectIssues(a, selection, Engine.filteredIssues(a, "Missing")) == 1 and selected[1] == f.missing)
		assert(Engine.selectIssues(a, selection) == 4 and #selected == 4)
		assert(Engine.selectIssues(a, selection, {}) == 0 and #selected == 0)
		assert(f.missing:GetAttribute("Enabled") == nil and f.missing:GetAttribute("Cost") == nil and #root:GetDescendants() == before)
	end)
	test("Copied, cross-audit, duplicate, sparse and oversized subsets are refused", function(f)
		local a, b = audit(f), audit(f)
		local issue = a.issues[1]
		for _, bad in ipairs({{Schema.copy(issue)}, {b.issues[1]}, {issue, issue}, {[2] = issue}, table.create(2001, issue)}) do
			rejects(function() Engine.preview(a, bad) end)
			local selected = false
			rejects(function() Engine.selectIssues(a, {Set = function() selected = true end}, bad) end)
			assert(not selected)
		end
		for _, bad in ipairs({{Schema.copy(issue)}, {b.issues[1]}, {[issue] = "yes"}, table.create(5001, issue)}) do
			rejects(function() Engine.filteredIssues(a, nil, nil, bad) end)
		end
		rejects(function() Engine.preview(Schema.copy(a)) end)
		assert(not Engine.isFresh({}) and not Engine.isFresh(nil))
	end)
	test("Tampered finding and forged plan cannot introduce a repair", function(f)
		local a = audit(f); local issue = finding(a, f.wrong, "Cost")
		issue.fix = {value = 25, parent = f.wrong.Parent}
		rejects(function() Engine.preview(a, {issue}) end)
		assert(not Engine.isFresh(a))
		local p = Engine.preview(audit(f))
		assert(not Engine.isFresh(Schema.copy(p)))
		p.changes[1].value = 26
		assert(not Engine.isFresh(p)); rejects(function() Engine.apply(p, history) end)
		assert(f.missing:GetAttribute("Cost") == nil and f.wrong:GetAttribute("Cost") == -3.5)
	end)
	test("Exact finding limit is retained; excess findings refuse the entire audit", function(f)
		f.schema.children = {}; f.schema.fields = {}
		for index = 1, 32 do
			table.insert(f.schema.fields, {name = "Missing" .. index, kind = "boolean", required = true, hasDefault = true, default = false, integer = false, choices = {}, description = ""})
		end
		for index = 1, 58 do f.object("Extra" .. index) end
		-- 62 Models * 32 missing fields + one class finding = 1985.
		assert(#audit(f).issues == 1985)
		local last = f.object("AtLimit")
		for index = 1, 17 do last:SetAttribute("Missing" .. index, false) end
		assert(#audit(f).issues == 2000)
		last:SetAttribute("Missing1", nil)
		rejects(function() audit(f) end)
		assert(f.missing:GetAttribute("Missing1") == nil)
	end)

	local staleCases = {
		{"existing attribute on another matched object", function(f) f.valid:SetAttribute("Tier", "Rare") end},
		{"optional/unruled attribute on a tagged object", function(f) f.valid:SetAttribute("DesignerNote", "Changed") end},
		{"additional tag on another matched object", function(f) f.valid:AddTag("SchemaForgeV11Extra") end},
		{"target tag removed from another matched object", function(f) f.valid:RemoveTag(f.schema.tag) end},
		{"new tagged object enters the scope", function(f) f.object("NewTarget") end},
		{"previously untagged scope object gains the target tag", function(f, root) root:AddTag(f.schema.tag) end},
		{"same-name tagged replacement", function(f) local replacement = f.valid:Clone(); local parent = f.valid.Parent; f.valid:Destroy(); replacement.Parent = parent end},
		{"required leaf removed", function(f) f.valid.Socket.Prompt:Destroy() end},
		{"required leaf renamed", function(f) f.valid.Socket.Prompt.Name = "OtherPrompt" end},
		{"same-name required leaf replaced", function(f) local old = f.valid.Socket.Prompt; local replacement = old:Clone(); old:Destroy(); replacement.Parent = f.valid.Socket end},
		{"required intermediate becomes ambiguous", function(f) local duplicate = f.valid.Socket:Clone(); duplicate.Parent = f.valid end},
		{"missing required child becomes present", function(f) local prompt = Instance.new("ProximityPrompt"); prompt.Name = "Prompt"; prompt.Parent = f.noChild.Socket end},
		{"tagged object renamed", function(f) f.valid.Name = "Renamed" end},
		{"tagged object reparented inside scope", function(f) f.valid.Parent = f.noChild end},
		{"scope ancestor renamed", function(_, root) root.Name = "RenamedScope" end},
		{"scope moved between supported services", function(_, root) root.Parent = game:GetService("ServerStorage") end},
		{"scope detached", function(_, root) root.Parent = nil end},
		{"source schema edited", function(f) f.schema.fields[1].default = 30 end},
		{"source scope array edited", function(f) f.roots[1] = f.missing end},
	}
	for _, case in ipairs(staleCases) do
		test("Stale: " .. case[1], function(f, root) refusesStale(f, function() case[2](f, root) end) end)
	end
	test("Mutated audit schema/roots invalidate a preview already created", function(f)
		local a = audit(f); local p = Engine.preview(a)
		a.schema.fields[1].default = 30
		assert(not Engine.isFresh(p)); rejects(function() Engine.apply(p, history) end)
		a = audit(f); p = Engine.preview(a); a.roots[1] = f.missing
		assert(not Engine.isFresh(p)); rejects(function() Engine.apply(p, history) end)
	end)
	test("Unrelated properties and untagged content do not stale an audit", function(f, root)
		local a = audit(f); local p = Engine.preview(a)
		f.valid.Socket.Prompt.Enabled = false
		local unrelated = Instance.new("Folder"); unrelated.Name = "Unrelated"; unrelated.Parent = root
		unrelated:SetAttribute("Cost", 17); unrelated:AddTag("DifferentTag")
		local outside = Instance.new("Folder"); outside.Name = "OtherChild"; outside.Parent = f.valid
		assert(Engine.isFresh(a) and Engine.isFresh(p))
	end)
	test("Required-child ambiguity and wrong class stay diagnostic only", function(f)
		local duplicate = f.valid.Socket:Clone(); duplicate.Parent = f.valid
		local issue = finding(audit(f), f.valid, "Socket/Prompt")
		assert(issue.category == "Required child" and issue.actual:find("Ambiguous", 1, true) and not issue.fix)
		duplicate:Destroy(); f.valid.Socket.Prompt:Destroy()
		local wrong = Instance.new("Folder"); wrong.Name = "Prompt"; wrong.Parent = f.valid.Socket
		local a = audit(f); issue = finding(a, f.valid, "Socket/Prompt")
		assert(issue.actual == "Folder" and not issue.fix and #Engine.preview(a, {issue}).changes == 0)
	end)
	test("Scope overlaps, false defaults and optional missing preserve compatibility", function(f, root)
		assert(Engine.audit(f.schema, {root, f.valid}).matched == 5)
		f.schema.fields[1].required = false
		local a = audit(f)
		assert(#Engine.filteredIssues(a, "Missing") == 1 and Engine.preview(a).changes[1].value == false)
		assert(f.valid:GetAttribute("Enabled") == false)
	end)
	test("Missing without default stays nonrepairable and selection is bounded", function(f)
		f.missing:SetAttribute("Tier", nil)
		local a = audit(f); local tier = finding(a, f.missing, "Tier")
		assert(tier.category == "Missing" and not tier.fix and #Engine.preview(a, {tier}).changes == 0)
		assert(#Engine.filteredIssues(a, nil, nil, table.create(5000, tier)) == 1)
		rejects(function() Engine.filteredIssues(a, nil, nil, table.create(5001, tier)) end)
		assert(not a.issues[#a.issues].fix)
	end)
	test("Freshness is rechecked when the history recording opens", function(f)
		local p = Engine.preview(audit(f)); local cancelled = false
		local fake = {
			TryBeginRecording = function() f.valid:SetAttribute("Cost", 26); return "test" end,
			FinishRecording = function(_, _, operation) assert(operation == Enum.FinishRecordingOperation.Cancel); cancelled = true end,
		}
		rejects(function() Engine.apply(p, fake) end)
		assert(cancelled and f.missing:GetAttribute("Cost") == nil and f.missing:GetAttribute("Enabled") == nil)
	end)
	test("Recording refusal and commit failure leave missing attributes absent", function(f)
		local p = Engine.preview(audit(f))
		rejects(function() Engine.apply(p, {TryBeginRecording = function() return nil end}) end)
		local cancelled = false
		local fake = {TryBeginRecording = function() return "test" end, FinishRecording = function(_, _, operation)
			if operation == Enum.FinishRecordingOperation.Commit then error("Injected commit failure") end
			cancelled = operation == Enum.FinishRecordingOperation.Cancel
		end}
		rejects(function() Engine.apply(p, fake) end)
		assert(cancelled and f.missing:GetAttribute("Cost") == nil and f.missing:GetAttribute("Enabled") == nil and Engine.isFresh(p))
	end)
	test("Native subset Apply, Undo and Redo preserve invalid values and hierarchy", function(f, root)
		history:SetWaypoint("SchemaForge V11 fixture baseline")
		local a = audit(f); local before = #root:GetDescendants()
		local p = Engine.preview(a, {finding(a, f.missing, "Enabled")})
		assert(Engine.apply(p, history) == 1)
		assert(f.missing:GetAttribute("Enabled") == false and f.missing:GetAttribute("Cost") == nil)
		assert(f.wrong:GetAttribute("Cost") == -3.5 and f.wrong:GetAttribute("Enabled") == "false" and #root:GetDescendants() == before)
		assert(not Engine.isFresh(p)); rejects(function() Engine.apply(p, history) end)
		history:Undo(); task.wait()
		assert(f.missing:GetAttribute("Enabled") == nil and f.missing:GetAttribute("Cost") == nil and root.Parent == workspace)
		history:Redo(); task.wait()
		assert(f.missing:GetAttribute("Enabled") == false and f.missing:GetAttribute("Cost") == nil and #root:GetDescendants() == before)
	end)
	print(string.format("[SchemaForgeV11Engine][SUMMARY] %d PASS / %d FAIL", pass, fail))
	return fail == 0
end
