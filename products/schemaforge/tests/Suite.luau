return function(modules)
	local Schema, Engine, Store = require(modules.Schema), require(modules.Engine), require(modules.Store)
	local history = game:GetService("ChangeHistoryService")
	local pass, fail = 0, 0
	local function test(name, fn)
		local ok, err = pcall(fn)
		if ok then pass += 1; print("[SchemaForgeTests][PASS] " .. name) else fail += 1; warn("[SchemaForgeTests][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function rejects(fn) assert(not pcall(fn), "Expected refusal") end
	local root = Instance.new("Folder"); root.Name = "SchemaForgeFixture"; root.Parent = workspace
	local reference = Instance.new("Model"); reference.Name = "Reference"; reference.Parent = root; reference:AddTag("Harvestable")
	reference:SetAttribute("Cost", 25); reference:SetAttribute("Enabled", false); reference:SetAttribute("Tier", "Basic"); reference:SetAttribute("Tint", Color3.new(1, 0, 0))
	local schema
	local function field(name) for _, f in ipairs(schema.fields) do if f.name == name then return f end end end
	test("Capture is read-only, typed and excludes unsupported types", function()
		local count = #root:GetDescendants(); local skipped
		schema, skipped = Schema.capture(reference)
		assert(skipped == 1 and #schema.fields == 3 and #root:GetDescendants() == count)
		assert(field("Enabled").default == false and not field("Cost").hasDefault)
	end)
	schema.name = "Harvest contract"; field("Cost").min = 0; field("Cost").max = 100; field("Cost").integer = true; field("Cost").hasDefault = true
	field("Tier").choices = {"Basic", "Rare"}; field("Tier").description = "Valid crop tier"
	field("Enabled").hasDefault = true
	schema.children = {{path = "Socket/Prompt", className = "ProximityPrompt", description = "Interaction point"}}
	local socket = Instance.new("Attachment"); socket.Name = "Socket"; socket.Parent = reference
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "Prompt"; prompt.Parent = socket
	local missing = reference:Clone(); missing.Name = "MissingDefaults"; missing:SetAttribute("Cost", nil); missing:SetAttribute("Enabled", nil); missing.Parent = root
	local wrong = reference:Clone(); wrong.Name = "WrongValues"; wrong:SetAttribute("Cost", -3.5); wrong:SetAttribute("Tier", "Typo"); wrong.Parent = root
	local badType = reference:Clone(); badType.Name = "WrongType"; badType:SetAttribute("Enabled", "false"); badType.Parent = root
	local noChild = reference:Clone(); noChild.Name = "MissingChild"; noChild.Socket:Destroy(); noChild.Parent = root
	local wrongClass = Instance.new("Part"); wrongClass.Name = "WrongClass"; wrongClass.Anchored = true; wrongClass:AddTag("Harvestable"); wrongClass.Parent = root
	local unrelated = Instance.new("Part"); unrelated.Name = "Untagged"; unrelated.Anchored = true; unrelated.Parent = root
	history:SetWaypoint("SchemaForge test fixture baseline")
	local a, plan
	test("Required types, range, choices, class and child paths", function()
		a = Engine.audit(schema, {root}); assert(a.matched == 6 and a.valid == 1 and #a.issues == 7, tostring(#a.issues))
	end)
	test("Audit and preview leave all instances unchanged", function()
		local n = #root:GetDescendants(); plan = Engine.preview(a)
		assert(#plan.changes == 2 and #root:GetDescendants() == n and missing:GetAttribute("Cost") == nil)
		assert(wrong:GetAttribute("Cost") == -3.5 and unrelated:GetAttribute("Cost") == nil)
	end)
	test("Selection roots include descendants and deduplicate overlaps", function()
		local a2 = Engine.audit(schema, {root, reference}); assert(a2.matched == 6)
		assert(Engine.audit(schema, {reference}).matched == 1)
	end)
	test("False is present; optional missing is not a finding", function()
		local s = Schema.copy(schema); for _, f in ipairs(s.fields) do f.required = false end
		assert(#Engine.audit(s, {missing}).issues == 0 and #Engine.audit(schema, {reference}).issues == 0)
	end)
	test("Missing-only apply preserves values, geometry, tags and children", function()
		local cf, attrs, n = unrelated.CFrame, reference:GetAttributes(), #root:GetDescendants()
		assert(Engine.apply(plan, history) == 2)
		assert(missing:GetAttribute("Cost") == 25 and missing:GetAttribute("Enabled") == false)
		assert(wrong:GetAttribute("Cost") == -3.5 and badType:GetAttribute("Enabled") == "false")
		assert(#root:GetDescendants() == n and unrelated.CFrame == cf and reference:GetAttribute("Cost") == attrs.Cost and missing:HasTag("Harvestable"))
	end)
	test("Actual native Undo and Redo restore exact attributes", function()
		history:Undo(); task.wait(); assert(missing:GetAttribute("Cost") == nil and missing:GetAttribute("Enabled") == nil and root.Parent == workspace)
		history:Redo(); task.wait(); assert(missing:GetAttribute("Cost") == 25 and missing:GetAttribute("Enabled") == false)
	end)
	test("Already applied and stale existing values are refused", function()
		rejects(function() Engine.apply(plan, history) end)
		missing:SetAttribute("Cost", nil); local p = Engine.preview(Engine.audit(schema, {missing})); missing:SetAttribute("Cost", 77)
		rejects(function() Engine.apply(p, history) end); assert(missing:GetAttribute("Cost") == 77)
	end)
	test("Stale tag, parent and removed scope are refused", function()
		missing:SetAttribute("Cost", nil); local p = Engine.preview(Engine.audit(schema, {root}))
		missing:RemoveTag("Harvestable"); rejects(function() Engine.apply(p, history) end); missing:AddTag("Harvestable")
		missing.Parent = workspace; rejects(function() Engine.apply(p, history) end); missing.Parent = root
		root.Parent = nil; rejects(function() Engine.apply(p, history) end); root.Parent = workspace
	end)
	test("Duplicate child names and wrong child classes are reported", function()
		local duplicate = socket:Clone(); duplicate.Parent = reference
		assert(Engine.audit(schema, {reference}).issues[1].reason:find("Ambiguous")); duplicate:Destroy()
		local s = Schema.copy(schema); s.children[1].className = "Part"
		assert(Engine.audit(s, {reference}).issues[1].reason:find("Expected Part"))
	end)
	test("Invalid schemas and unsafe defaults are refused", function()
		for _, mutate in ipairs({
			function(s) s.tag = "" end,
			function(s) s.fields[1].name = "RBXPrivate" end,
			function(s) s.fields[1].min = 200 end,
			function(s) s.fields[1].default = -10 end,
			function(s) s.fields[1].max = 0/0 end,
			function(s) s.fields[1].default = "25" end,
			function(s) table.insert(s.fields, Schema.copy(s.fields[1])) end,
			function(s) s.children[1].path = "/Prompt" end,
			function(s) s.className = "ImaginaryClass" end,
		}) do local s = Schema.copy(schema); mutate(s); rejects(function() Schema.validate(s) end) end
	end)
	test("Number integer and min/max bounds are inclusive", function()
		local f = field("Cost"); assert(not Schema.valueError(f, 0) and not Schema.valueError(f, 100))
		assert(Schema.valueError(f, 1.5) and Schema.valueError(f, math.huge))
	end)
	test("Recording refusal does not mutate", function()
		local p = Engine.preview(Engine.audit(schema, {missing}))
		rejects(function() Engine.apply(p, {TryBeginRecording = function() return nil end}) end)
		assert(missing:GetAttribute("Cost") == nil)
	end)
	test("Commit failure rolls back all attempted repairs", function()
		local p = Engine.preview(Engine.audit(schema, {missing}))
		local fake = {TryBeginRecording = function() return "test" end, FinishRecording = function(_, _, op) if op == Enum.FinishRecordingOperation.Commit then error("injected commit failure") end end}
		rejects(function() Engine.apply(p, fake) end); assert(missing:GetAttribute("Cost") == nil)
	end)
	test("Project save/load matches typed values and descriptions", function()
		local token = Store.save(schema, nil, history); local loaded, actual = Store.load(schema.name)
		assert(token == actual and loaded.fields[2].default == false and loaded.children[1].path == "Socket/Prompt")
		assert(#Store.list() == 1)
	end)
	test("Project editing and actual native save Undo/Redo", function()
		local loaded, token = Store.load(schema.name); loaded.fields[1].description = "Purchase cost"
		Store.save(loaded, token, history); history:Undo(); assert(Store.load(schema.name).fields[1].description == "")
		history:Redo(); assert(Store.load(schema.name).fields[1].description == "Purchase cost")
	end)
	test("No duplicate save or stale overwrite", function()
		rejects(function() Store.save(schema, nil, history) end)
		rejects(function() Store.save(schema, "stale", history) end)
		assert(#Store.list() == 1)
	end)
	test("Delete saved and actual native Undo/Redo", function()
		local _, token = Store.load(schema.name); Store.delete(schema.name, token, history)
		assert(#Store.list() == 0); history:Undo(); assert(#Store.list() == 1); history:Redo(); assert(#Store.list() == 0)
	end)
	test("Malformed data fails without deleting it", function()
		local entry = Instance.new("StringValue"); entry.Name = "Broken"; entry.Value = "not JSON"; entry.Parent = game.ServerStorage._SchemaForgeSchemas
		rejects(function() Store.load("Broken") end); assert(entry.Value == "not JSON"); entry:Destroy()
	end)
	test("Storage name collision is protected", function()
		local f = game.ServerStorage._SchemaForgeSchemas; f.Name = "SavedContracts"
		local blocker = Instance.new("Folder"); blocker.Name = "_SchemaForgeSchemas"; blocker.Parent = game.ServerStorage
		rejects(Store.list); rejects(function() Store.save(schema, nil, history) end)
		assert(#blocker:GetChildren() == 0); blocker:Destroy(); f.Name = "_SchemaForgeSchemas"
	end)
	test("Forbidden scopes and empty scope are refused", function()
		rejects(function() Engine.audit(schema, {}) end)
		rejects(function() Engine.audit(schema, {game:GetService("CoreGui")}) end)
		rejects(function() Engine.audit(schema, {game.ServerStorage._SchemaForgeSchemas}) end)
	end)
	test("Select findings deduplicates real instances", function()
		local service = game:GetService("Selection"); local count = Engine.selectIssues(Engine.audit(schema, {root}), service)
		assert(#service:Get() == count and count == 5); service:Set({})
	end)
	test("UI mounts and disposes at narrow dock size", function()
		local widget = Instance.new("Frame"); widget.Size = UDim2.fromOffset(250, 500)
		local dispose = require(modules.View).mount(widget, game:GetService("Selection"), history)
		assert(widget:FindFirstChild("Audit", true) == nil and widget:FindFirstChild("TabAudit", true))
		dispose(); assert(#widget:GetChildren() == 0); widget:Destroy()
	end)
	print(string.format("[SchemaForgeTests][SUMMARY] %d PASS / %d FAIL", pass, fail))
	return fail == 0
end
