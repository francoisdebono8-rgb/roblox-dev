-- Runs only in the isolated, opt-in, exact-binary technical gate.
return function(modules, legacyModules, hostPlugin)
	local Schema, Engine, Store = require(modules.Schema), require(modules.Engine), require(modules.Store)
	local OldSchema, OldEngine = require(legacyModules.Schema), require(legacyModules.Engine)
	local history, json = game:GetService("ChangeHistoryService"), game:GetService("HttpService")
	local pass, fail, matrix = 0, 0, {}
	local function rejects(fn, message)
		local ok, err = pcall(fn); assert(not ok, "Expected refusal")
		if message then assert(tostring(err):find(message, 1, true), tostring(err)) end
	end
	local function rule(name, value)
		return {name = name, kind = typeof(value), required = true, hasDefault = true, default = value, integer = false, choices = {}, description = "Saved contract"}
	end
	local function fixture(root)
		local s = Schema.new(); s.name = "Technical contract"; s.tag = "SchemaForgeV12Test"
		s.fields = {rule("Cost", 25), rule("Enabled", false), rule("Tier", "Basic")}
		s.fields[1].min = 0; s.fields[1].max = 100; s.fields[1].integer = true
		s.fields[3].choices = {"Basic", "Rare"}
		local function object(name, class)
			local obj = Instance.new(class or "Model"); obj.Name = name or "Target"; obj.Parent = root; obj:AddTag(s.tag)
			return obj
		end
		return {schema = s, roots = {root}, object = object, target = object()}
	end
	local function test(ids, name, fn)
		local root = Instance.new("Folder"); root.Name = "SchemaForgeV12Fixture"; root.Parent = workspace
		local ok, err = xpcall(function() fn(fixture(root), root) end, debug.traceback)
		root:Destroy()
		for _, child in ipairs(game.ServerStorage:GetChildren()) do child:Destroy() end
		for _, id in ipairs(ids) do if not ok then matrix[id] = false elseif matrix[id] == nil then matrix[id] = true end end
		if ok then pass += 1; print("[SchemaForgeV12][PASS] " .. name)
		else fail += 1; warn("[SchemaForgeV12][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function audit(f) return Engine.audit(f.schema, f.roots) end
	local function find(result, field, category)
		for _, finding in ipairs(result.issues) do if finding.field == field and (not category or finding.category == category) then return finding end end
		error("Missing finding " .. field)
	end
	local function storedEntry(name)
		return game.ServerStorage._SchemaForgeSchemas:FindFirstChild(name)
	end
	local function fakeFailure(check)
		return {TryBeginRecording = function() return "test" end, FinishRecording = function(_, _, operation)
			if operation == Enum.FinishRecordingOperation.Commit then if check then check() end; error("Injected commit failure") end
		end}
	end
	local function stale(f, mutate)
		local a = audit(f); local p = Engine.preview(a)
		assert(Engine.isFresh(a) and Engine.isFresh(p)); mutate()
		assert(not Engine.isFresh(a) and not Engine.isFresh(p), "Changed project remained fresh")
		rejects(function() Engine.preview(a) end)
		local began = false
		rejects(function() Engine.apply(p, {TryBeginRecording = function() began = true; return nil end}) end)
		assert(not began and f.target:GetAttribute("Cost") == nil)
	end

	test({1, 2, 4, 5, 6, 12}, "V1 load is read-only; migration, reload and old engine parity", function(f)
		local s = OldSchema.new(); s.name = f.schema.name; s.tag = f.schema.tag; s.fields = Schema.copy(f.schema.fields)
		local raw = json:JSONEncode(s)
		local storage = Instance.new("Folder"); storage.Name = "_SchemaForgeSchemas"; storage:SetAttribute("SchemaForgeVersion", 1); storage.Parent = game.ServerStorage
		local entry = Instance.new("StringValue"); entry.Name = s.name; entry.Value = raw; entry.Parent = storage
		local loaded, token = Store.load(s.name)
		assert(loaded.version == 1 and token == raw and entry.Value == raw and loaded.fields[2].default == false)
		local old, new = OldEngine.audit(s, f.roots), Engine.audit(loaded, f.roots)
		assert(old.matched == new.matched and old.valid == new.valid and #old.issues == #new.issues)
		for i, issue in ipairs(old.issues) do
			assert(issue.field == new.issues[i].field and issue.reason == new.issues[i].reason and issue.expected == new.issues[i].expected)
		end
		history:SetWaypoint("V1 schema baseline")
		local encoded = Store.save(loaded, token, history); local again, actual = Store.load(s.name)
		assert(loaded.version == 1 and again.version == 2 and encoded == actual and entry == storedEntry(s.name))
		for i, field in ipairs(s.fields) do
			for key, value in pairs(field) do if type(value) ~= "table" then assert(value == again.fields[i][key]) end end
		end
		history:Undo(); task.wait(); assert(entry.Value == raw and Store.load(s.name).version == 1)
		history:Redo(); task.wait(); assert(entry.Value == encoded and Store.load(s.name).version == 2)
	end)
	test({3}, "Malformed, cyclic, future, unknown-key and V1 extension payloads refuse safely", function(f)
		for _, mutate in ipairs({
			function(s) s.version = 3 end, function(s) s.version = "2" end,
			function(s) s.fields = {[2] = s.fields[1]} end, function(s) s.fields[1].extra = {} end,
			function(s) s.extra = {} end, function(s) s.fields[1].default = math.huge end,
			function(s) s.fields[1].choices = {[0] = "bad"} end, function(s) s.children = {{path = "A//B"}} end,
			function(s) s.version = 1; s.requiredTags = {"HiddenExtension"} end,
			function(s) s.extra = s end,
			function(s) local cursor = s; for _ = 1, 20 do cursor.extra = {}; cursor = cursor.extra end end,
		}) do local s = Schema.copy(f.schema); mutate(s); rejects(function() Schema.validate(s) end); rejects(function() Schema.encode(s) end) end
		for _, payload in ipairs({"not JSON", "[]", '{"version":900}', string.rep(" ", 64001)}) do rejects(function() Schema.decode(payload) end) end
		local s = Schema.copy(f.schema); s.fields = {rule("Vector", Vector3.new(1, 2, 3))}
		local wire = json:JSONDecode(Schema.encode(s))
		for _, mutate in ipairs({
			function(v) v.fields[1].default.components[1] = "nan" end,
			function(v) v.fields[1].default.components[1] = "0.1" end,
			function(v) v.fields[1].default.components[4] = "0" end,
			function(v) v.fields[1].default.kind = "CFrame" end,
			function(v) v.fields[1].default.extra = true end,
			function(v) v.fields[1].default.components[1] = 1 end,
		}) do local v = Schema.copy(wire); mutate(v); rejects(function() Schema.decode(json:JSONEncode(v)) end) end
	end)
	test({4, 5, 6, 18, 19, 23}, "Scalar semantics and non-destructive invalid-value diagnostics", function(f, root)
		f.target:SetAttribute("Cost", -3.5); f.target:SetAttribute("Enabled", "false"); f.target:SetAttribute("Tier", "Typo")
		local a = audit(f)
		assert(#a.issues == 3 and #Engine.preview(a).changes == 0)
		assert(find(a, "Cost").category == "Invalid value" and find(a, "Tier").category == "Invalid value" and find(a, "Enabled").category == "Wrong type")
		for _, value in ipairs({0, 100, 25}) do assert(not Schema.valueError(f.schema.fields[1], value)) end
		for _, value in ipairs({-1, 101, 1.5, math.huge, 0/0}) do assert(Schema.valueError(f.schema.fields[1], value)) end
		assert(not Schema.valueError(f.schema.fields[2], false) and not Schema.valueError(f.schema.fields[3], "Rare"))
		assert(f.target:GetAttribute("Cost") == -3.5 and f.target:GetAttribute("Enabled") == "false" and #root:GetDescendants() == 1)
	end)
	local values = {
		{"Vector2", Vector2.new(0.1, -16777216)}, {"Vector3", Vector3.new(1/3, -77.25, 0.00001)},
		{"Color3", Color3.new(0.1, 0.37, 0.9)}, {"CFrame", CFrame.new(1.1, -2.75, 1000.1) * CFrame.Angles(0.37, -0.71, 1.13)},
		{"UDim", UDim.new(0.1, -2147483648)}, {"UDim2", UDim2.new(0.1, 2147483647, -1/3, -73)},
		{"BrickColor", BrickColor.new("Bright red")}, {"NumberRange", NumberRange.new(-1/3, 17.7)},
	}
	for _, pair in ipairs(values) do
		test({2, 7, 8, 9, 10, 38}, pair[1] .. ": capture, exact codec/store roundtrip, default Apply and native Undo/Redo", function(f)
			local kind, value = pair[1], pair[2]
			f.target:SetAttribute("Typed", value)
			assert(Schema.equalValue(f.target:GetAttribute("Typed"), value))
			local captured, skipped = Schema.capture(f.target)
			assert(skipped == 0 and #captured.fields == 1 and captured.fields[1].kind == kind and not captured.fields[1].hasDefault)
			assert(Schema.equalValue(captured.fields[1].default, value))
			captured.name = "Typed " .. kind; captured.fields[1].hasDefault = true; captured.fields[1].exact = value
			local wire = Schema.encode(captured); local reloaded = Schema.decode(wire)
			assert(Schema.equalValue(reloaded.fields[1].default, value) and Schema.equalValue(reloaded.fields[1].exact, value))
			local encoded = Store.save(reloaded, nil, history); local stored, token = Store.load(captured.name)
			assert(token == encoded and Schema.equalValue(stored.fields[1].default, value) and Schema.equalValue(stored.fields[1].exact, value))
			assert(not Schema.valueError(stored.fields[1], value) and Schema.valueError(stored.fields[1], false))
			local different = Schema.initialValue(kind)
			assert(not Schema.equalValue(value, different) and Schema.valueError(stored.fields[1], different))
			f.target:SetAttribute("Typed", nil); history:SetWaypoint("Typed missing baseline " .. kind)
			local a = Engine.audit(stored, f.roots); local plan = Engine.preview(a)
			assert(#plan.changes == 1 and plan.changes[1].action == "attribute" and Schema.equalValue(plan.changes[1].value, value))
			assert(a.issues[1].expected:find(kind, 1, true) and f.target:GetAttribute("Typed") == nil)
			assert(Engine.apply(plan, history) == 1 and Schema.equalValue(f.target:GetAttribute("Typed"), value))
			history:Undo(); task.wait(); assert(f.target:GetAttribute("Typed") == nil)
			history:Redo(); task.wait(); assert(Schema.equalValue(f.target:GetAttribute("Typed"), value))
			assert(#Engine.audit(stored, f.roots).issues == 0)
			f.target:SetAttribute("Typed", different)
			local invalid = Engine.audit(stored, f.roots)
			assert(#Engine.preview(invalid).changes == 0 and invalid.issues[1].actual:find(kind, 1, true))
		end)
	end
	test({11}, "Vector per-axis and magnitude bounds are inclusive, finite and dimensional", function(f)
		for _, kind in ipairs({"Vector2", "Vector3"}) do
			local value = kind == "Vector2" and Vector2.new(3, 4) or Vector3.new(3, 4, 0)
			local r = rule("Direction", value); r.axisMin = {X = 3, Y = 4}; r.axisMax = {X = 3, Y = 4}; r.magnitudeMin = 5; r.magnitudeMax = 5
			f.schema.fields = {r}; assert(Schema.validate(f.schema) and not Schema.valueError(r, value))
			r.axisMax.X = 4; r.axisMin.X = 0
			assert(Schema.valueError(r, kind == "Vector2" and Vector2.new(0, 4) or Vector3.new(0, 4, 0)))
			r.magnitudeMin = 0; assert(not Schema.valueError(r, value))
			for _, mutate in ipairs({function(c) c.axisMin.W = 1 end, function(c) c.axisMax.X = -1 end, function(c) c.magnitudeMin = -1 end, function(c) c.magnitudeMax = 0/0 end}) do
				local s = Schema.copy(f.schema); mutate(s.fields[1]); rejects(function() Schema.validate(s) end)
			end
		end
		local s = Schema.copy(f.schema); s.fields[1] = rule("V2", Vector2.zero); s.fields[1].axisMin = {Z = 0}; rejects(function() Schema.validate(s) end)
		for _, value in ipairs({Vector2.new(math.huge, 0), Vector3.new(0/0, 0, 0), Color3.new(math.huge, 0, 0)}) do
			s.fields = {rule("Bad", value)}; rejects(function() Schema.validate(s) end)
		end
	end)
	test({12, 13, 14, 15, 16, 17, 18, 19, 23, 39}, "Tag contracts only add missing required tags; native Undo/Redo and wrong-class policy", function(f, root)
		f.schema.requiredTags = {"RequiredA", "RequiredB"}; f.schema.forbiddenTags = {"ForbiddenA"}
		f.target:AddTag("ForbiddenA"); f.target:AddTag("Unrelated"); f.target:SetAttribute("Cost", -1)
		f.target:SetAttribute("Enabled", "false"); f.target:SetAttribute("Tier", "Basic")
		local wrong = f.object("WrongClass", "Folder"); local untagged = Instance.new("Model"); untagged.Parent = root
		history:SetWaypoint("Tag fixture baseline")
		local a = audit(f); local p = Engine.preview(a)
		assert(a.matched == 2 and #Engine.filteredIssues(a, "Required tag") == 4 and #Engine.filteredIssues(a, "Forbidden tag") == 1)
		assert(#p.changes == 4 and not find(a, "ForbiddenA").fix)
		local before = #root:GetDescendants(); assert(Engine.apply(p, history) == 4)
		assert(f.target:HasTag("RequiredA") and wrong:HasTag("RequiredB") and not untagged:HasTag("RequiredA"))
		assert(f.target:HasTag("Unrelated") and f.target:HasTag("ForbiddenA") and f.target:GetAttribute("Cost") == -1 and f.target:GetAttribute("Enabled") == "false")
		assert(#root:GetDescendants() == before)
		history:Undo(); task.wait(); assert(not f.target:HasTag("RequiredA") and not wrong:HasTag("RequiredB") and f.target:HasTag("ForbiddenA"))
		history:Redo(); task.wait(); assert(f.target:HasTag("RequiredA") and wrong:HasTag("RequiredB") and f.target:HasTag("Unrelated"))
	end)
	test({13, 15}, "Tag duplicates, contradictions, invalid names and count bounds refuse", function(f)
		for _, mutate in ipairs({
			function(s) s.requiredTags = {"A", "A"} end, function(s) s.requiredTags = {"A"}; s.forbiddenTags = {"A"} end,
			function(s) s.requiredTags = {s.tag} end, function(s) s.forbiddenTags = {s.tag} end,
			function(s) s.requiredTags = {""} end, function(s) s.requiredTags = {"   "} end,
			function(s) s.forbiddenTags = {"bad\nname"} end, function(s) s.requiredTags = {[2] = "A"} end,
			function(s) s.requiredTags = {}; for i = 1, 17 do table.insert(s.requiredTags, "T" .. i) end end,
		}) do local s = Schema.copy(f.schema); mutate(s); rejects(function() Schema.validate(s) end) end
	end)
	test({20, 21, 22, 23, 28}, "Child rules distinguish every-segment ambiguity, missing and wrong class without writes", function(f, root)
		f.schema.children = {{path = "Socket/Prompt", className = "ProximityPrompt", description = "Interaction"}}
		assert(find(audit(f), "Socket/Prompt").actual == "Missing")
		local socket = Instance.new("Folder"); socket.Name = "Socket"; socket.Parent = f.target
		local wrong = Instance.new("Folder"); wrong.Name = "Prompt"; wrong.Parent = socket
		local a = audit(f); assert(find(a, "Socket/Prompt").actual == "Folder" and not find(a, "Socket/Prompt").fix)
		local duplicate = wrong:Clone(); duplicate.Parent = socket
		assert(find(audit(f), "Socket/Prompt").actual:find("Ambiguous", 1, true)); duplicate:Destroy()
		duplicate = socket:Clone(); duplicate.Parent = f.target
		assert(find(audit(f), "Socket/Prompt").actual == "Ambiguous child name: Socket"); duplicate:Destroy()
		local before = #root:GetDescendants(); local p = Engine.preview(audit(f)); Engine.apply(p, history)
		assert(#root:GetDescendants() == before and wrong.Parent == socket and wrong.ClassName == "Folder")
	end)
	test({20, 21, 22, 23}, "Optional child is absent-or-valid, with the same ambiguity and class diagnostics", function(f)
		f.schema.fields = {}; f.schema.children = {{path = "A/B", className = "Part", description = "", optional = true}}
		assert(#audit(f).issues == 0)
		local a = Instance.new("Folder"); a.Name = "A"; a.Parent = f.target
		local b = Instance.new("Folder"); b.Name = "B"; b.Parent = a
		assert(find(audit(f), "A/B").actual == "Folder")
		local duplicate = b:Clone(); duplicate.Parent = a
		assert(find(audit(f), "A/B").actual:find("Ambiguous", 1, true))
		assert(#Engine.preview(audit(f)).changes == 0)
	end)
	test({21, 28}, "Child cache shares scans and enforces depth/rule limits", function(f)
		local socket = Instance.new("Folder"); socket.Name = "Socket"; socket.Parent = f.target
		for i = 1, 100 do local c = Instance.new("Folder"); c.Name = "Leaf" .. i; c.Parent = socket end
		f.schema.fields = {}; f.schema.children = {}
		for i = 1, 32 do table.insert(f.schema.children, {path = "Socket/Leaf" .. i, className = "Folder", description = ""}) end
		local a = audit(f); assert(a.metrics.childVisits == 101 and #a.issues == 0)
		local s = Schema.copy(f.schema); s.children[1].path = "A/B/C/D/E/F/G/H/I"; rejects(function() Schema.validate(s) end)
		s = Schema.copy(f.schema); table.insert(s.children, {path = "Extra", className = "Folder", description = ""}); rejects(function() Schema.validate(s) end)
	end)
	test({24}, "Exact subset and audit/plan forgery checks include mutation of the source subset", function(f)
		f.schema.requiredTags = {"MustExist"}
		local a = audit(f); local selected = {find(a, "Enabled"), find(a, "MustExist")}; local p = Engine.preview(a, selected)
		assert(#p.changes == 2 and #Engine.preview(a, {}).changes == 0)
		assert(Engine.apply(p, history) == 2 and f.target:GetAttribute("Enabled") == false and f.target:HasTag("MustExist") and f.target:GetAttribute("Cost") == nil)
		a = audit(f); selected = {find(a, "Cost")}; p = Engine.preview(a, selected)
		selected[1] = find(a, "Tier"); assert(not Engine.isFresh(p)); rejects(function() Engine.apply(p, history) end)
		for _, bad in ipairs({{Schema.copy(a.issues[1])}, {a.issues[1], a.issues[1]}, {[2] = a.issues[1]}, {audit(f).issues[1]}}) do rejects(function() Engine.preview(a, bad) end) end
		p = Engine.preview(a); p.changes[1].value = 99; assert(not Engine.isFresh(p))
		selected = {a.issues[1]}; p = Engine.preview(a, selected); selected[1] = Schema.copy(selected[1]); assert(not Engine.isFresh(p))
		a = audit(f); a.issues[1].fix.value = 99; assert(not Engine.isFresh(a))
		assert(not Engine.isFresh({}) and not Engine.isFresh(nil))
	end)
	local staleCases = {
		{25, "attribute presence", function(f) f.target:SetAttribute("Enabled", false) end},
		{25, "attribute value", function(f) f.target:SetAttribute("Tier", "Rare") end},
		{26, "required tag", function(f) f.target:AddTag("RequiredA") end},
		{26, "forbidden tag", function(f) f.target:AddTag("ForbiddenA") end},
		{27, "target membership removed", function(f) f.target:RemoveTag(f.schema.tag) end},
		{27, "new matching object", function(f) f.object("New") end},
		{27, "new tag on scope", function(f, root) root:AddTag(f.schema.tag) end},
		{27, "target reparented", function(f, root) local folder = Instance.new("Folder"); folder.Parent = root; f.target.Parent = folder end},
		{27, "same-name target replaced", function(f) local c = f.target:Clone(); c.Parent = f.target.Parent; f.target:Destroy() end},
		{28, "required child removed", function(f) f.target.Socket.Prompt:Destroy() end},
		{28, "required child renamed", function(f) f.target.Socket.Prompt.Name = "Other" end},
		{28, "required child replaced with wrong class", function(f) f.target.Socket.Prompt:Destroy(); local c = Instance.new("Folder"); c.Name = "Prompt"; c.Parent = f.target.Socket end},
		{28, "required intermediate duplicated", function(f) local c = f.target.Socket:Clone(); c.Parent = f.target end},
		{28, "required child reparented", function(f) f.target.Socket.Prompt.Parent = f.target end},
	}
	for _, case in ipairs(staleCases) do
		test({case[1]}, "Stale: " .. case[2], function(f, root)
			f.schema.requiredTags = {"RequiredA"}; f.schema.forbiddenTags = {"ForbiddenA"}
			f.schema.children = {{path = "Socket/Prompt", className = "ProximityPrompt", description = ""}}
			local socket = Instance.new("Folder"); socket.Name = "Socket"; socket.Parent = f.target
			local prompt = Instance.new("ProximityPrompt"); prompt.Name = "Prompt"; prompt.Parent = socket
			stale(f, function() case[3](f, root) end)
		end)
	end
	test({25, 27}, "Schema version/content, roots and root ancestry are freshness dependencies", function(f, root)
		for _, change in ipairs({
			function() f.schema.fields[1].default = 30 end,
			function() f.schema.version = 99 end,
			function() f.roots[1] = f.target end,
			function() root.Parent = game.ServerStorage end,
		}) do
			local copy = Schema.copy(f.schema); local roots = table.clone(f.roots)
			stale(f, change); f.schema = copy; f.roots = roots; root.Parent = workspace
		end
	end)
	test({29}, "Unrelated attributes/tags/properties/names/children do not stale", function(f, root)
		local p = Engine.preview(audit(f))
		f.target:SetAttribute("DesignerNote", "unread"); f.target:AddTag("UnrelatedTag"); f.target.Name = "RenamedTarget"; root.Name = "RenamedRoot"
		f.target.Archivable = false
		local child = Instance.new("Folder"); child.Name = "UnrelatedChild"; child.Parent = f.target
		local outside = Instance.new("Folder"); outside.Parent = root
		assert(Engine.isFresh(p)); assert(Engine.apply(p, history) == 3)
	end)
	test({24, 27}, "Overlapping roots and duplicate names preserve stable object/finding identities", function(f, root)
		local duplicate = f.target:Clone(); duplicate.Parent = root
		f.roots = {root, f.target}; local a, b = audit(f), audit(f)
		assert(a.matched == 2 and a.issues[1].identity ~= a.issues[2].identity)
		for i, issue in ipairs(a.issues) do assert(issue.instance == b.issues[i].instance and issue.identity == b.issues[i].identity) end
		local selected
		assert(Engine.selectIssues(a, {Set = function(_, objects) selected = objects end}) == 2 and #selected == 2)
	end)
	test({31}, "Exactly 5000 tagged objects accepted; 5001 refuses without writes", function(f)
		f.schema.fields = {}
		for i = 2, 5000 do f.object("Target" .. i) end
		assert(audit(f).matched == 5000)
		f.object("OverLimit"); rejects(function() audit(f) end, "5000")
		assert(f.target:GetAttribute("Cost") == nil)
	end)
	test({32}, "Exactly 2000 findings accepted; 2001 refuses the whole audit", function(f)
		f.schema.fields = {}; for i = 1, 32 do table.insert(f.schema.fields, rule("Field" .. i, false)) end
		for i = 2, 62 do f.object("Object" .. i) end
		local last = f.object("Last"); for i = 1, 16 do last:SetAttribute("Field" .. i, false) end
		assert(#audit(f).issues == 2000)
		last:SetAttribute("Field1", nil); rejects(function() audit(f) end, "2000")
		assert(f.target:GetAttribute("Field1") == nil)
	end)
	test({28, 31}, "Child traversal budget refuses oversized work and preserves hierarchy", function(f)
		f.schema.fields = {}; f.schema.children = {{path = "Wanted", className = "Folder", description = ""}}
		for _ = 1, 100001 do local c = Instance.new("Folder"); c.Name = "Other"; c.Parent = f.target end
		rejects(function() audit(f) end, "100000")
		assert(#f.target:GetChildren() == 100001)
	end)
	test({33}, "Storage collisions, duplicate entries and compare-and-save concurrency refuse", function(f)
		local token = Store.save(f.schema, nil, history); local storage = game.ServerStorage._SchemaForgeSchemas
		local duplicate = storage:Clone(); duplicate.Parent = game.ServerStorage
		rejects(Store.list); rejects(function() Store.load(f.schema.name) end); rejects(function() Store.save(f.schema, token, history) end); duplicate:Destroy()
		local blocker = Instance.new("Folder"); blocker.Name = f.schema.name; blocker.Parent = storage
		rejects(Store.list); rejects(function() Store.load(f.schema.name) end); rejects(function() Store.save(f.schema, token, history) end); blocker:Destroy()
		local entry = storedEntry(f.schema.name); duplicate = entry:Clone(); duplicate.Parent = storage
		rejects(Store.list); rejects(function() Store.delete(f.schema.name, token, history) end); duplicate:Destroy()
		rejects(function() Store.save(f.schema, "stale", history) end); rejects(function() Store.save(f.schema, nil, history) end)
		assert(entry.Value == token)
	end)
	test({33, 34, 35}, "Recording-opening races preserve the external writer and refuse save/delete", function(f)
		local token = Store.save(f.schema, nil, history); local entry = storedEntry(f.schema.name)
		for _, operation in ipairs({"save", "delete"}) do
			entry.Value = token; local cancelled = false
			local fake = {TryBeginRecording = function() entry.Value = "External edit"; return "test" end,
				FinishRecording = function(_, _, op) assert(op == Enum.FinishRecordingOperation.Cancel); cancelled = true end}
			if operation == "save" then
				f.schema.fields[1].description = "Edited"; rejects(function() Store.save(f.schema, token, fake) end)
			else rejects(function() Store.delete(f.schema.name, token, fake) end) end
			assert(cancelled and entry.Value == "External edit" and entry.Parent == game.ServerStorage._SchemaForgeSchemas)
		end
	end)
	test({25, 33}, "Plans from loaded contracts stale on independent saved edits, replacement or duplicate storage", function(f)
		local token = Store.save(f.schema, nil, history)
		for _, mutate in ipairs({
			function(entry) entry.Value = token .. " " end,
			function(entry) local replacement = entry:Clone(); replacement.Parent = entry.Parent; entry.Parent = nil; return entry end,
			function(entry) local duplicate = entry.Parent:Clone(); duplicate.Parent = game.ServerStorage; return duplicate end,
		}) do
			local s = Store.load(f.schema.name); local a = Engine.audit(s, f.roots); local p = Engine.preview(a)
			local entry = storedEntry(f.schema.name); local folder = entry.Parent; local cleanup = mutate(entry)
			assert(not Engine.isFresh(a) and not Engine.isFresh(p))
			local began = false; rejects(function() Engine.apply(p, {TryBeginRecording = function() began = true end}) end)
			assert(not began and f.target:GetAttribute("Cost") == nil)
			if cleanup == entry then folder:FindFirstChild(entry.Name):Destroy(); entry.Parent = folder
			elseif cleanup then cleanup:Destroy() end
			entry.Value = token
		end
	end)
	test({25, 33, 36, 37}, "Saved contract edit inside TryBeginRecording blocks a direct Engine Apply", function(f)
		Store.save(f.schema, nil, history)
		local s, token = Store.load(f.schema.name); local p = Engine.preview(Engine.audit(s, f.roots)); local entry = storedEntry(s.name)
		local cancelled = false
		rejects(function() Engine.apply(p, {TryBeginRecording = function() entry.Value = token .. " "; return "test" end,
			FinishRecording = function(_, _, op) assert(op == Enum.FinishRecordingOperation.Cancel); cancelled = true end}) end)
		assert(cancelled and entry.Value == token .. " " and f.target:GetAttribute("Cost") == nil and f.target:GetAttribute("Enabled") == nil)
	end)
	test({34}, "Save recording refusal and create/update commit failure restore exact prior storage", function(f)
		rejects(function() Store.save(f.schema, nil, {TryBeginRecording = function() return nil end}) end)
		assert(not game.ServerStorage:FindFirstChild("_SchemaForgeSchemas"))
		rejects(function() Store.save(f.schema, nil, fakeFailure()) end)
		assert(not game.ServerStorage:FindFirstChild("_SchemaForgeSchemas"))
		local token = Store.save(f.schema, nil, history); local storage, entry = game.ServerStorage._SchemaForgeSchemas, storedEntry(f.schema.name)
		entry:SetAttribute("Unrelated", "Preserved"); f.schema.fields[1].description = "New description"
		rejects(function() Store.save(f.schema, token, fakeFailure(function() assert(entry.Value ~= token) end)) end)
		assert(entry.Value == token and entry.Parent == storage and entry:GetAttribute("Unrelated") == "Preserved")
		f.schema.name = "New entry"; rejects(function() Store.save(f.schema, nil, fakeFailure()) end)
		assert(#storage:GetChildren() == 1 and storage:GetChildren()[1] == entry)
	end)
	test({35}, "Delete recording refusal, rollback and native Undo/Redo restore the same entry", function(f)
		local token = Store.save(f.schema, nil, history); local entry = storedEntry(f.schema.name); local parent = entry.Parent
		rejects(function() Store.delete(f.schema.name, token, {TryBeginRecording = function() return nil end}) end)
		rejects(function() Store.delete(f.schema.name, token, fakeFailure(function() assert(entry.Parent == nil) end)) end)
		assert(entry.Parent == parent and entry.Value == token)
		history:SetWaypoint("Delete baseline"); Store.delete(f.schema.name, token, history); assert(entry.Parent == nil)
		history:Undo(); task.wait(); assert(entry.Parent == parent and entry.Value == token)
		history:Redo(); task.wait(); assert(entry.Parent == nil)
	end)
	test({36, 37}, "Mixed repair commit failure rolls back every attribute and tag", function(f)
		f.schema.requiredTags = {"RequiredA", "RequiredB"}; f.target:AddTag("KeepMe")
		local p = Engine.preview(audit(f))
		rejects(function() Engine.apply(p, {TryBeginRecording = function() return nil end}) end)
		assert(f.target:GetAttribute("Cost") == nil and not f.target:HasTag("RequiredA"))
		rejects(function() Engine.apply(p, fakeFailure(function()
			assert(f.target:GetAttribute("Cost") == 25 and f.target:GetAttribute("Enabled") == false and f.target:HasTag("RequiredA") and f.target:HasTag("RequiredB"))
		end)) end)
		assert(f.target:GetAttribute("Cost") == nil and f.target:GetAttribute("Enabled") == nil and f.target:GetAttribute("Tier") == nil)
		assert(not f.target:HasTag("RequiredA") and not f.target:HasTag("RequiredB") and f.target:HasTag("KeepMe") and Engine.isFresh(p))
	end)
	test({25, 36, 37}, "Project change while opening recording blocks every repair", function(f)
		f.schema.requiredTags = {"RequiredA"}; local p = Engine.preview(audit(f)); local cancelled = false
		local fake = {TryBeginRecording = function() f.target:SetAttribute("Tier", "Rare"); return "test" end,
			FinishRecording = function(_, _, op) assert(op == Enum.FinishRecordingOperation.Cancel); cancelled = true end}
		rejects(function() Engine.apply(p, fake) end)
		assert(cancelled and f.target:GetAttribute("Cost") == nil and not f.target:HasTag("RequiredA") and f.target:GetAttribute("Tier") == "Rare")
	end)
	for _, firstAction in ipairs({"attribute", "tag"}) do
		test({firstAction == "attribute" and 36 or 37}, "Injected mid-transaction readback failure after first " .. firstAction .. " restores native state", function(f)
			f.schema.fields = {rule(firstAction == "attribute" and "AAAttribute" or "ZZAttribute", 25)}
			f.schema.requiredTags = {firstAction == "attribute" and "ZZTag" or "AATag"}
			local p = Engine.preview(audit(f)); assert(#p.changes == 2 and p.changes[1].action == firstAction)
			local env = getfenv(Engine.apply); local faulted, cancelled = false, false
			-- QA-only environment injection: unchanged candidate code, real Instances,
			-- and real native setters. Fail immediately after the first native write.
			setfenv(Engine.apply, setmetatable({assert = function(condition, message)
				env.assert(condition, message)
				if message == "Repair value did not persist exactly" then
					faulted = true
					local first, second = p.changes[1], p.changes[2]
					env.assert(first.action == "tag" and first.instance:HasTag(first.name) or first.action == "attribute" and first.instance:GetAttribute(first.name) == 25)
					env.assert(second.action == "tag" and not second.instance:HasTag(second.name) or second.action == "attribute" and second.instance:GetAttribute(second.name) == nil)
					error("Injected mid-write readback failure")
				end
			end}, {__index = env}))
			local ok, err = pcall(Engine.apply, p, {TryBeginRecording = function() return "test" end,
				FinishRecording = function(_, _, operation) assert(operation == Enum.FinishRecordingOperation.Cancel); cancelled = true end})
			setfenv(Engine.apply, env)
			assert(not ok and tostring(err):find("Injected mid-write", 1, true) and faulted and cancelled)
			assert(f.target:GetAttribute(f.schema.fields[1].name) == nil and not f.target:HasTag(f.schema.requiredTags[1]) and Engine.isFresh(p))
		end)
	end
	test({36, 37}, "Rollback attempts earlier native entries after an injected restoration-check error", function(f)
		f.schema.requiredTags = {"ZZTag"}; local p = Engine.preview(audit(f))
		local env = getfenv(Engine.apply); local rollbackChecks = 0
		setfenv(Engine.apply, setmetatable({assert = function(condition, message)
			env.assert(condition, message)
			if message == "Rollback value persisted" then
				rollbackChecks += 1
				if rollbackChecks == 1 then error("Injected rollback-check failure") end
			end
		end}, {__index = env}))
		local ok, err = pcall(Engine.apply, p, fakeFailure())
		setfenv(Engine.apply, env)
		assert(not ok and tostring(err):find("Rollback failed", 1, true) and rollbackChecks == #p.changes)
		assert(f.target:GetAttribute("Cost") == nil and f.target:GetAttribute("Enabled") == nil and f.target:GetAttribute("Tier") == nil and not f.target:HasTag("ZZTag"))
	end)
	test({7, 11, 13}, "Native DockWidget control mount and typed text edits, without graphical acceptance", function(f)
		local View = require(modules.View)
		for index, pair in ipairs(values) do
			local s = Schema.copy(f.schema); s.fields = {rule("Typed", pair[2])}; s.fields[1].exact = pair[2]
			s.requiredTags = {"RequiredA"}; s.forbiddenTags = {"ForbiddenA"}
			local widget = hostPlugin:CreateDockWidgetPluginGuiAsync("SchemaForgeV12Smoke" .. index,
				DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 420, 640, 240, 360))
			local originalNew = Schema.new
			Schema.new = function() return Schema.copy(s) end
			local ok, dispose = pcall(View.mount, widget, game:GetService("Selection"), history)
			Schema.new = originalNew
			if not ok then widget:Destroy(); error(dispose) end
			local checked, err = pcall(function()
				local body = widget.SchemaForgeUI.Body.Detail
				for _, name in ipairs({"DefaultValue", "ExactValue"}) do assert(body:FindFirstChild(name), name) end
				assert(widget.SchemaForgeUI.Body.Collection:FindFirstChild("ContractSettings"), "Separate contract/tag editor remains reachable")
				assert(Schema.equalValue(Schema.parseValue(pair[1], body.DefaultValue.Text), pair[2]))
				body.DefaultValue.Text = "invalid"; task.wait()
				assert(body.DefaultValueError.Visible)
				body.DefaultValue.Text = Schema.editValue(pair[2]); task.wait()
				assert(not body.DefaultValueError.Visible)
				if pair[1] == "Vector2" or pair[1] == "Vector3" then
					assert(body:FindFirstChild("axisMinX") and body:FindFirstChild("axisMaxY") and body:FindFirstChild("magnitudeMax"))
					assert((body:FindFirstChild("axisMinZ") ~= nil) == (pair[1] == "Vector3"))
				end
			end)
			dispose(); widget:Destroy(); assert(checked, err)
		end
	end)
	test({7, 11, 13}, "Separate contract editor preserves native required/forbidden tag validation", function(f)
		local s = Schema.copy(f.schema); s.fields = {}; s.children = {}
		local widget = hostPlugin:CreateDockWidgetPluginGuiAsync("SchemaForgeContractSmoke",
			DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 420, 640, 240, 360))
		local originalNew = Schema.new
		Schema.new = function() return Schema.copy(s) end
		local ok, dispose = pcall(require(modules.View).mount, widget, game:GetService("Selection"), history)
		Schema.new = originalNew
		if not ok then widget:Destroy(); error(dispose) end
		local checked, err = pcall(function()
			local body = widget.SchemaForgeUI.Body.Detail
			assert(body:FindFirstChild("requiredTags") and body:FindFirstChild("forbiddenTags"))
			body.requiredTags.Text = "RequiredA,RequiredB"; task.wait(); assert(not body.requiredTagsError.Visible)
			body.forbiddenTags.Text = "RequiredA"; task.wait(); assert(body.forbiddenTagsError.Visible)
			assert(not widget.SchemaForgeUI.Footer.Actions.Save.Active)
			body.forbiddenTags.Text = "ForbiddenA"; task.wait(); assert(not body.forbiddenTagsError.Visible)
			assert(widget.SchemaForgeUI.Footer.Actions.Save.Active)
		end)
		dispose(); widget:Destroy(); assert(checked, err)
	end)
	test({30}, "Sparse benchmark: fixed 20000 descendants / 20 targets, warmup and seven medians", function(f, root)
		f.target:Destroy(); f.schema.fields = {}; f.schema.children = {}
		local folders = {}
		for i = 1, 100 do local folder = Instance.new("Folder"); folder.Name = string.format("Group%03d", i); folder.Parent = root; table.insert(folders, folder) end
		for i = 1, 19900 do
			local c = Instance.new("Folder"); c.Name = string.format("Object%05d", i); c.Parent = folders[(i - 1) % #folders + 1]
			if i <= 20 then c:AddTag(f.schema.tag) end
		end
		f.schema.className = "Folder"
		local oldSchema = Schema.copy(f.schema); oldSchema.version = 1; oldSchema.requiredTags = nil; oldSchema.forbiddenTags = nil
		local old = function() return OldEngine.audit(oldSchema, f.roots) end
		local new = function() return Engine.audit(f.schema, f.roots) end
		assert(#root:GetDescendants() == 20000 and old().matched == 20 and new().matched == 20)
		for _ = 1, 2 do old(); new() end
		local before, after = {}, {}
		for i = 1, 7 do
			local start = os.clock(); local a = old(); before[i] = (os.clock() - start) * 1000
			start = os.clock(); local b = new(); after[i] = (os.clock() - start) * 1000
			assert(a.matched == b.matched and a.valid == b.valid and b.metrics.candidateVisits == 20 and b.metrics.childVisits == 0 and b.metrics.mode == "GetTagged")
		end
		table.sort(before); table.sort(after)
		print(string.format("[SchemaForgeV12][BENCHMARK] descendants=20000 targets=20 warmup=2 repetitions=7 old_full_audit_median_ms=%.6f candidate_full_audit_median_ms=%.6f old_scope_visits=20001 candidate_visits=20 child_visits=0", before[4], after[4]))
	end)
	test({40, 41}, "Production package has only five scripts, no QA/runtime/network payload", function()
		local production = modules.Parent; assert(#production:GetDescendants() == 6)
		local count = 0
		for _, child in ipairs(production:GetDescendants()) do
			if child:IsA("LuaSourceContainer") then
				count += 1
				for _, pattern in ipairs({"GetAsync", "PostAsync", "RequestAsync", "loadstring", "TechnicalGate", "SchemaForgeV12", "AnalyticsService"}) do assert(not child.Source:find(pattern, 1, true)) end
			end
		end
		assert(count == 5 and production.Main.Disabled)
		assert(#production.Parent:GetAttribute("CandidateSHA256") == 64)
	end)
	for id = 1, 41 do
		local state = matrix[id] == true and "PASS" or matrix[id] == false and "FAIL" or "NON TESTED"
		print(string.format("[SchemaForgeV12][MATRIX] %02d %s", id, state))
		if matrix[id] ~= true then fail += 1 end
	end
	print(string.format("[SchemaForgeV12][SUMMARY] %d PASS / %d FAIL", pass, fail))
	return fail == 0
end
