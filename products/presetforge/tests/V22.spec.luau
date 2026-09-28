return function(test, modules, legacy20, legacy21, pluginObject, artifactRoot)
	local Collection = game:GetService("CollectionService")
	local History = game:GetService("ChangeHistoryService")
	local Capture = require(modules.CaptureService)
	local Preview = require(modules.PreviewService)
	local Resolver = require(modules.TargetResolver)
	local Apply = require(modules.ApplyService)
	local Plan = require(modules.ExecutionPlan)
	local Serializer = require(modules.PresetSerializer)
	local Store = require(modules.PresetStore)
	local Project = require(modules.ProjectStore)
	local Constants = require(modules.Constants)
	local Guard = require(modules.DataGuard)
	local service = Preview.new(Collection, Resolver.new(Collection))
	local function recipe()
		return { name = "Technical recipe", schemaId = "BasePart", capture = { tags = true, attributes = true },
			properties = { Anchored = true, Transparency = 0.5 }, tags = { "Keep", "Chosen" },
			attributes = { False = true, Zero = 7, Empty = "changed", Added = Vector3.new(1, 2, 3) } }
	end
	local function history()
		local h = { begins = 0, commits = 0, cancels = 0 }
		function h:TryBeginRecording() self.begins += 1; return "record" end
		function h:FinishRecording(_, operation)
			if operation == Enum.FinishRecordingOperation.Commit then self.commits += 1 else self.cancels += 1 end
		end
		return h
	end
	local function fixture(cleanup)
		local root = Instance.new("Folder"); root.Name = "PresetForge19Fixture"; root.Parent = workspace
		cleanup(function() root:Destroy() end)
		local a = Instance.new("Part"); a.Name = "Target"; a.Anchored = false; a.CanCollide = false; a.Parent = root
		a:SetAttribute("False", false); a:SetAttribute("Zero", 0); a:SetAttribute("Empty", ""); a:SetAttribute("Unrelated", "keep")
		a:AddTag("Keep"); a:AddTag("Outside")
		local b = a:Clone(); b.Name = "Second"; b.Parent = root
		return root, a, b
	end
	local function context(r, targets, options)
		return { recipe = r, selection = targets, options = options or { scope = "Selection" } }
	end
	local function build(c)
		local preview, err = service:build(c.recipe, c.selection, c.options, c.revision)
		assert(preview, err)
		return preview
	end
	local function restored(a)
		assert(not a.Anchored and a.Transparency == 0)
		assert(a:GetAttribute("False") == false and a:GetAttribute("Zero") == 0 and a:GetAttribute("Empty") == "")
		assert(a:GetAttribute("Added") == nil and a:GetAttribute("Unrelated") == "keep")
		assert(a:HasTag("Keep") and a:HasTag("Outside") and not a:HasTag("Chosen"))
	end
	local function mockSettings()
		local p = { value = nil, writes = 0 }
		function p:GetSetting() return self.value end
		function p:SetSetting(_, value) self.writes += 1; self.value = value end
		return p
	end
	for index, legacy in ipairs({ legacy20, legacy21 }) do
		test(string.format("M%02d legacy %s exact-binary Local/Project load", index, if index == 1 then "2.0" else "2.1"), function(cleanup)
			local r = recipe()
			local oldSerializer = require(legacy.PresetSerializer)
			local p = mockSettings(); p.value = assert(oldSerializer.encodeAll({ r }))
			local before = Guard.copy(p.value)
			local store = Store.new(p, "isolated")
			assert(store:load() and p.writes == 0 and Guard.equal(before, p.value))
			assert(Serializer.equal({ r }, store:getPresets()))
			assert(store:update(r.name, store:find(r.name)))
			assert(p.value.version == Constants.STORE_VERSION and Serializer.equal({ r }, assert(oldSerializer.decodeAll(p.value))))
			local container = Instance.new("Folder"); cleanup(function() container:Destroy() end)
			assert(require(legacy.ProjectStore).new(container):create(r.name, r))
			local originalRoot = container:GetChildren()[1]
			local nodes = originalRoot:GetDescendants()
			local current = Project.new(container, history())
			assert(current:load() and Serializer.equal({ r }, current:getPresets()))
			assert(container:GetChildren()[1] == originalRoot and Guard.equal(nodes, originalRoot:GetDescendants()))
			assert(current:update(r.name, current:find(r.name)))
			local old = require(legacy.ProjectStore).new(container)
			assert(old:load() and Serializer.equal({ r }, old:getPresets()))
		end)
	end
	test("M03 current Local real plugin round trip", function(cleanup)
		local key = "PresetForge19QA_" .. game:GetService("HttpService"):GenerateGUID(false)
		assert(key ~= Constants.STORE_KEY)
		local previous = pluginObject:GetSetting(key)
		cleanup(function() pluginObject:SetSetting(key, previous); assert(Guard.equal(previous, pluginObject:GetSetting(key))) end)
		local store = Store.new(pluginObject, key); assert(store:load()); assert(store:create("Round trip", recipe()))
		local again = Store.new(pluginObject, key); assert(again:load())
		assert(Serializer.equal(store:getPresets(), again:getPresets()))
	end)
	test("M04 current Project round trip and transaction failures", function(cleanup)
		local root = fixture(cleanup)
		local h = history(); local store = Project.new(root, h)
		assert(store:create("Round trip", recipe()))
		local again = Project.new(root, h); assert(again:load())
		assert(Serializer.equal(store:getPresets(), again:getPresets()))
		local before = store:getPresets(); local oldRoot = root:FindFirstChild(Constants.PROJECT_ROOT_NAME)
		function h:FinishRecording(_, op) if op == Enum.FinishRecordingOperation.Commit then error("commit failure") end end
		assert(not store:rename("Round trip", "Failure")); assert(root:FindFirstChild(Constants.PROJECT_ROOT_NAME) == oldRoot)
		assert(Serializer.equal(before, store:getPresets()))
		function h:TryBeginRecording() return nil end
		assert(not store:delete("Round trip")); assert(root:FindFirstChild(Constants.PROJECT_ROOT_NAME) == oldRoot)
	end)
	for id, label in pairs({ [5] = "property", [6] = "tag", [7] = "attribute" }) do
		test(string.format("M%02d selective %s subset and recapture", id, label), function(cleanup)
			local _, source, target = fixture(cleanup)
			source.Anchored = true; source:AddTag("Chosen"); source:SetAttribute("Zero", 10)
			local r = assert(Capture.new(Collection):capture({ source }, {
				properties = { "Anchored" }, tags = true, attributes = true, tagNames = { "Chosen" }, attributeNames = { "Zero" },
			})); r.name = "Subset"
			assert(next(r.properties) == "Anchored" and #r.tags == 1 and r.tags[1] == "Chosen" and next(r.attributes) == "Zero")
			local c = context(r, { target }); assert(Apply.new(Collection, history()):apply(build(c).plan, c))
			assert(target.Anchored and target.Transparency == 0 and target:GetAttribute("Zero") == 10)
			source:AddTag("Later"); source:SetAttribute("Later", 99)
			local recaptured = assert(Capture.new(Collection):recapture(r, { source }))
			assert(Serializer.equal({ r }, { recaptured }))
		end)
	end
	for id, label in pairs({ [8] = "tag", [9] = "attribute" }) do
		test(string.format("M%02d unrelated %s preservation", id, label), function(cleanup)
			local _, a = fixture(cleanup); local c = context(recipe(), { a })
			assert(Apply.new(Collection, history()):apply(build(c).plan, c))
			assert(a:HasTag("Outside") and a:HasTag("Keep") and a:GetAttribute("Unrelated") == "keep")
		end)
	end
	test("M10 mixed Selection immutable exact plan", function(cleanup)
		local root, a, b = fixture(cleanup); local r = recipe(); local c = context(r, { a, root, b, a })
		local p = build(c); assert(p.affectedCount == 2 and p.ignoredCount == 1 and p.scannedCount == 3)
		restored(a); restored(b)
		assert(table.isfrozen(p.plan) and table.isfrozen(p.plan.entries[1].changes[1]))
		assert(not pcall(function() p.plan.recipe.properties.Anchored = false end))
		p.results[1].changes[1].after = false
		assert(Apply.new(Collection, history()):apply(p.plan, c)); assert(a.Anchored and b.Anchored)
	end)
	test("M11 overlapping Descendants roots dedupe", function(cleanup)
		local root, a, b = fixture(cleanup); local nested = Instance.new("Folder"); nested.Parent = root; b.Parent = nested
		local c = context(recipe(), { nested, root, nested }, { scope = "Descendants", className = "Part" })
		local p = build(c); assert(p.scannedCount == 3 and p.compatibleCount == 2 and p.affectedCount == 2)
		local seen = {}; for _, entry in ipairs(p.plan.entries) do assert(not seen[entry.instance]); seen[entry.instance] = true end
		assert(seen[a] and seen[b])
	end)
	test("M12 class/name/tag filters", function(cleanup)
		local root, a = fixture(cleanup); a:AddTag("Filter")
		local p = build(context(recipe(), { root }, { scope = "Descendants", className = "Part", nameContains = "target", tag = "Filter" }))
		assert(p.compatibleCount == 1 and p.plan.entries[1].instance == a)
	end)
	local changes = {
		[13] = { "added matching descendant", function(root) local p = Instance.new("Part"); p.Parent = root end },
		[14] = { "removed matching descendant", function(_, _, b) b:Destroy() end },
		[15] = { "target reparent (identical paths)", function(root, a) local f = Instance.new("Folder"); f.Name = root.Name; f.Parent = root; a.Parent = f end },
		[16] = { "planned property tiny delta", function(_, a) a.Transparency = 0.0000001 end },
		[17] = { "planned attribute tiny delta", function(_, a) a:SetAttribute("Zero", 0.0000000001) end },
		[18] = { "planned tag presence", function(_, a) a:RemoveTag("Keep") end },
		[20] = { "recipe content", function(_, _, _, c) c.recipe.attributes.Zero = 8 end },
	}
	for id, change in pairs(changes) do
		test(string.format("M%02d stale %s", id, change[1]), function(cleanup)
			local root, a, b = fixture(cleanup)
			local c = context(recipe(), { root }, { scope = "Descendants", className = "Part" }); local p = build(c)
			change[2](root, a, b, c)
			local h = history(); local ok, err = Apply.new(Collection, h):apply(p.plan, c)
			assert(not ok and err:find("Stale Preview") and h.begins == 0 and not a.Anchored, tostring(err))
		end)
	end
	test("M19 unrelated property and nonmatching addition remain fresh", function(cleanup)
		local root, a = fixture(cleanup)
		local c = context(recipe(), { root }, { scope = "Descendants", className = "Part" }); local p = build(c)
		a.Color = Color3.new(1, 0, 0); a.Name = "Unfiltered rename"
		local ignored = Instance.new("Folder"); ignored.Parent = root
		assert(Apply.new(Collection, history()):apply(p.plan, c))
	end)
	test("M21 no-change targets and no-change fields untouched", function(cleanup)
		local _, a, b = fixture(cleanup); local r = recipe(); local first = context(r, { b })
		assert(Apply.new(Collection, history()):apply(build(first).plan, first))
		local c = context(r, { a, b }); local p = build(c); assert(p.matchingCount == 1)
		local touched = 0
		assert(Apply.new(Collection, history(), function(target, change, write)
			assert(target == a and not (change.kind == "tag" and change.name == "Keep")); touched += 1; write()
		end):apply(p.plan, c))
		assert(touched == p.totalChanges)
	end)
	test("M22 exact metrics and write counts", function(cleanup)
		local _, a, b = fixture(cleanup); local c = context(recipe(), { a, b }); local p = build(c)
		assert(p.metrics.scanned == 2 and p.metrics.affected == 2 and p.metrics.ignored == 0 and p.metrics.matching == 0)
		local ok, counts = Apply.new(Collection, history()):apply(p.plan, c); assert(ok, counts)
		assert(Guard.equal(p.plan.counts, counts) and counts.properties == 4 and counts.tags == 2 and counts.attributes == 8)
	end)
	test("M23 coercion preflight and readback rollback", function(cleanup)
		local root, a, b = fixture(cleanup)
		local target = Instance.new("Frame"); target.Parent = root
		local probe = Instance.new("Frame"); probe.LayoutOrder = 4294967296
		assert(probe.LayoutOrder == 2147483647, "Native integer coercion fixture changed"); probe:Destroy()
		local bad = { name = "Clamped", schemaId = "GuiObject", capture = { tags = false, attributes = false }, properties = { LayoutOrder = 4294967296 }, tags = {}, attributes = {} }
		local rejected, reason = service:build(bad, { target }, { scope = "Selection" })
		assert(rejected == nil and reason:find("coercion/clamp") and target.LayoutOrder == 0, tostring(reason))
		local c = context(recipe(), { a, b }); local p = build(c)
		local ok, err = Apply.new(Collection, history(), function(target, change, write)
			write(); if target == b and change.name == "Transparency" then target.Transparency = 0.25 end
		end):apply(p.plan, c)
		assert(not ok and err:find("readback")); restored(a); restored(b)
	end)
	test("M24 recording unavailable and recording-start reentrancy", function(cleanup)
		local _, a = fixture(cleanup); local c = context(recipe(), { a }); local h = history()
		function h:TryBeginRecording() return nil end
		assert(not Apply.new(Collection, h):apply(build(c).plan, c)); restored(a)
		local p = build(c); local writes = 0
		function h:TryBeginRecording() a.Transparency = 0.25; return "record" end
		local ok = Apply.new(Collection, h, function(_, _, write) writes += 1; write() end):apply(p.plan, c)
		assert(not ok and h.cancels == 1 and writes == 0 and a.Transparency == 0.25 and not a.Anchored)
	end)
	for id, kind in pairs({ [25] = "property", [26] = "tag", [27] = "attribute", [28] = "commit" }) do
		test(string.format("M%02d %s failure full rollback", id, kind), function(cleanup)
			local _, a, b = fixture(cleanup); local c = context(recipe(), { a, b }); local p = build(c); local h = history()
			if kind == "commit" then
				function h:FinishRecording(_, operation)
					if operation == Enum.FinishRecordingOperation.Commit then error("Injected commit failure") end
					self.cancels += 1
				end
			end
			local ok, err = Apply.new(Collection, h, function(target, change, write)
				write(); if target == b and change.kind == kind then error("Injected setter failure after write") end
			end):apply(p.plan, c)
			assert(not ok and err:find("rolled back") and not err:find("Rollback/cancel errors"), tostring(err))
			restored(a); restored(b); assert(h.cancels == 1)
		end)
	end
	test("M29 native Undo exact before and identity", function(cleanup)
		local root, a, b = fixture(cleanup); local c = context(recipe(), { a, b })
		History:SetWaypoint("PresetForge19 before Apply")
		assert(Apply.new(Collection, History):apply(build(c).plan, c))
		History:Undo(); task.wait(); assert(a.Parent == root and b.Parent == root); restored(a); restored(b)
		History:Redo(); task.wait(); assert(a.Anchored and b.Anchored)
	end)
	test("M30 native Redo and Project create/update/rename/delete identity Undo", function(cleanup)
		local container = fixture(cleanup); local store = Project.new(container, History)
		History:SetWaypoint("PresetForge19 project baseline")
		for _, op in ipairs({ "create", "update", "rename", "delete" }) do
			local before = container:FindFirstChild(Constants.PROJECT_ROOT_NAME)
			local beforeRecipes = store:getPresets(); local beforeNodes = before and before:GetDescendants() or {}
			if op == "create" then assert(store:create("Native", recipe()))
			elseif op == "update" then local r = recipe(); r.attributes.Zero = 99; assert(store:update("Native", r))
			elseif op == "rename" then assert(store:rename("Native", "Renamed"))
			else assert(store:delete("Renamed")) end
			local after = container:FindFirstChild(Constants.PROJECT_ROOT_NAME); local afterRecipes = store:getPresets()
			History:Undo(); task.wait(); assert(container:FindFirstChild(Constants.PROJECT_ROOT_NAME) == before)
			assert(not before or Guard.equal(beforeNodes, before:GetDescendants()))
			assert(store:load() and Serializer.equal(beforeRecipes, store:getPresets()))
			History:Redo(); task.wait(); assert(container:FindFirstChild(Constants.PROJECT_ROOT_NAME) == after)
			assert(store:load() and Serializer.equal(afterRecipes, store:getPresets()))
		end
	end)
	test("M31 one use including failed/stale/forged plans", function(cleanup)
		local _, a = fixture(cleanup); local c = context(recipe(), { a }); local p = build(c); local h = history()
		assert(Apply.new(Collection, h):apply(p.plan, c)); assert(not Apply.new(Collection, h):apply(p.plan, c))
		assert(not Apply.new(Collection, h):apply(Guard.copy(p.plan), c)); assert(h.begins == 1)
		local nextPlan = build(c); c.recipe.name = "changed"
		assert(not Apply.new(Collection, h):apply(nextPlan.plan, c)); c.recipe.name = "Technical recipe"
		assert(not Apply.new(Collection, h):apply(nextPlan.plan, c))
	end)
	test("M32 root/scan/compatible/affected/write caps", function(cleanup)
		local root = fixture(cleanup); local r = recipe()
		assert(service:build(r, table.create(Constants.MAX_ROOTS + 1, root), { scope = "Selection" }) == nil)
		root:ClearAllChildren()
		for _ = 1, Constants.MAX_SCANNED + 1 do Instance.new("Folder").Parent = root end
		local options = { scope = "Descendants", className = "Part" }
		local p, err = service:build(r, { root }, options); assert(p == nil and err:find("Scanned"), err)
		root:ClearAllChildren()
		for _ = 1, Constants.MAX_COMPATIBLE + 1 do Instance.new("Part").Parent = root end
		p, err = service:build(r, { root }, options); assert(p == nil and err:find("Compatible"), err)
		root:ClearAllChildren()
		for _ = 1, Constants.MAX_AFFECTED + 1 do Instance.new("Part").Parent = root end
		p, err = service:build(r, { root }, options); assert(p == nil and err:find("Affected"), err)
		root:ClearAllChildren(); r.tags = {}; r.attributes = {}
		for i = 1, 64 do r.tags[i] = "Tag" .. i; r.attributes["A" .. i] = i end
		for _ = 1, 160 do Instance.new("Part").Parent = root end
		p, err = service:build(r, { root }, options); assert(p == nil and err:find("write limit"), err)
		for _, target in ipairs(root:GetChildren()) do assert(not target.Anchored and next(target:GetAttributes()) == nil) end
	end)
	test("M33 malformed persistence duplicates/cycles/oversize/nested content", function(cleanup)
		local encoded = assert(Serializer.encodeAll({ recipe() }))
		for _, corrupt in ipairs({
			function(x) x.count = 1000000 end,
			function(x) x.items[1] = x.items["1"] end,
			function(x) x.items["2"] = x.items["1"] end,
			function(x) x.items["1"].capture.tags = "true" end,
			function(x) x.items["1"].attributes.items["1"].value = { kind = "Vector3", x = 1 } end,
			function(x) x.loop = x end,
			function(x) x.items["1"].name = string.rep("ff", 20000) end,
			function(x) x.items["1"].properties.items["1"].value = { kind = "number", value = 0 / 0 } end,
		}) do
			local copy = Guard.copy(encoded); corrupt(copy)
			local ok, result = pcall(Serializer.decodeAll, copy); assert(ok and result == nil)
		end
		local container = fixture(cleanup); local s = Project.new(container, history()); assert(s:create("Stored", recipe()))
		local root = container:FindFirstChild(Constants.PROJECT_ROOT_NAME)
		local duplicate = root:Clone(); duplicate.Parent = container; assert(not s:load()); duplicate:Destroy()
		local node = root.Stored
		duplicate = node.Tags:Clone(); duplicate.Parent = node; assert(not s:load()); duplicate:Destroy()
		local nested = Instance.new("Folder"); nested.Parent = node.Tags.Tag_001; assert(not s:load()); nested:Destroy()
		duplicate = node.Tags.Tag_001:Clone(); duplicate.Parent = node.Tags; assert(not s:load()); duplicate:Destroy()
		assert(s:load())
	end)
	test("M34 no network telemetry/runtime addition", function()
		assert(artifactRoot:GetAttribute("StaticSafetyVerified") == true)
		assert(#artifactRoot.PresetForge:GetChildren() == 2 and artifactRoot.PresetForge.Main.Disabled)
		for _, instance in ipairs(artifactRoot.PresetForge:GetDescendants()) do
			assert(not instance:IsA("LocalScript"))
			assert(not instance:IsA("Script") or instance == artifactRoot.PresetForge.Main)
		end
	end)
	test("M35 exact candidate binary/source correspondence", function()
		assert(artifactRoot:GetAttribute("SourceMatchVerified") == true and #artifactRoot:GetAttribute("CandidateSHA256") == 64)
		assert(Constants.VERSION == "2.2.0" and require(legacy20.Constants).VERSION == "2.0.0" and require(legacy21.Constants).VERSION == "2.1.0")
	end)
	test("extra selection order/filter membership/revision freshness", function(cleanup)
		local root, a, b = fixture(cleanup)
		for _, change in ipairs({
			function(c) c.selection = { b, a } end,
			function(c) c.options = { scope = "Descendants", className = "Part" } end,
			function(c) c.revision += 1 end,
		}) do
			local c = context(recipe(), { a, b }); c.revision = 1; local p = build(c); change(c)
			assert(not Plan.validate(p.plan, c)); assert(not Apply.new(Collection, history()):apply(p.plan, c)); restored(a)
		end
		for _, change in ipairs({ function() a.Name = "Other" end, function() a:RemoveTag("Filter") end }) do
			a.Name = "Target"; a:AddTag("Filter")
			local c = context(recipe(), { root }, { scope = "Descendants", className = "Part", nameContains = "Target", tag = "Filter" })
			local p = build(c); change(); assert(not Plan.validate(p.plan, c))
		end
	end)
	test("extra full recipe preflight rejects before history", function(cleanup)
		local _, a = fixture(cleanup)
		for _, change in ipairs({
			function(r) r.properties.Name = "not whitelisted" end,
			function(r) r.properties.Transparency = 2 end,
			function(r) r.attributes.Invalid = Vector3.new(0 / 0, 0, 0) end,
			function(r) r.attributes["bad name"] = true end,
			function(r) r.attributes.RBXReserved = true end,
			function(r) r.tags = { "duplicate", "duplicate" } end,
			function(r) r.attributes.Large = string.rep("x", Constants.MAX_STRING_BYTES + 1) end,
		}) do
			local r = recipe(); change(r); assert(service:build(r, { a }, { scope = "Selection" }) == nil); restored(a)
		end
	end)
	test("extra recording-start recipe/selection mutations and one-use failure", function(cleanup)
		local _, a, b = fixture(cleanup)
		for _, change in ipairs({ function(c) c.recipe.properties.Anchored = false end, function(c) c.selection = { b } end }) do
			local c = context(recipe(), { a }); local p = build(c); local h = history(); local writes = 0
			function h:TryBeginRecording() change(c); return "record" end
			local applier = Apply.new(Collection, h, function(_, _, write) writes += 1; write() end)
			assert(not applier:apply(p.plan, function() return c end)); assert(writes == 0 and h.cancels == 1)
			assert(not applier:apply(p.plan, c)); restored(a); restored(b)
		end
	end)
	test("extra controller revision and relevant watcher integration", function(cleanup)
		local Support = require(script.Parent.GateTestSupport)
		local repository = Support.repository(cleanup)
		local root, a = fixture(cleanup); assert(repository:create("Local", "Controller", recipe()))
		local controller, _, selection, h = Support.controller(cleanup, repository, { a })
		controller:_runPreview(); assert(controller._preview)
		a.Name = "Unrelated rename"; a.Color = Color3.new(1, 0, 0); task.wait()
		assert(controller._preview, "unrelated property unnecessarily invalidated GUI Preview")
		assert(repository:update("Local", "Controller", recipe()))
		controller:_apply(); assert(h.begins == 0 and not a.Anchored and controller._preview == nil)
		selection:Set({ root }); task.wait(); controller:_setScope("Descendants"); controller:_runPreview()
		local ignored = Instance.new("Folder"); ignored.Parent = root; task.wait()
		assert(controller._preview, "nonmatching descendant unnecessarily invalidated GUI Preview")
		local matched = Instance.new("Part"); matched.Parent = root; task.wait()
		assert(controller._preview == nil, "new matching descendant must invalidate GUI Preview")
	end)
	test("extra project reentrant mutation and nonarchivable clone refuse", function(cleanup)
		local container = fixture(cleanup); local h = history(); local store = Project.new(container, h)
		assert(store:create("Original", recipe()))
		local root = container:FindFirstChild(Constants.PROJECT_ROOT_NAME)
		root.Original.Attributes.Archivable = false
		assert(not store:rename("Original", "Dropped")); assert(root.Parent == container)
		root.Original.Attributes.Archivable = true
		function h:TryBeginRecording() root.Original.Attributes:SetAttribute("Zero", 42); return "record" end
		assert(not store:delete("Original")); assert(root.Parent == container and root.Original.Attributes:GetAttribute("Zero") == 42)
	end)
	test("extra controller observes externally edited Project recipe", function(cleanup)
		local Support = require(script.Parent.GateTestSupport)
		local repository, _, storage = Support.repository(cleanup)
		local _, a = fixture(cleanup); assert(repository:create("Project", "External", recipe()))
		local controller, _, _, h = Support.controller(cleanup, repository, { a })
		controller:_runPreview(); assert(controller._preview)
		storage:FindFirstChild(Constants.PROJECT_ROOT_NAME).External.Attributes:SetAttribute("Zero", 999)
		controller:_apply(); assert(h.begins == 0 and controller._preview == nil); restored(a)
	end)
	test("extra live Repository context rechecks stored recipe at recording start", function(cleanup)
		local Support = require(script.Parent.GateTestSupport)
		local repository, _, storage = Support.repository(cleanup)
		local _, a = fixture(cleanup); assert(repository:create("Project", "Live", recipe()))
		local function live()
			return { recipe = repository:find("Project", "Live"), selection = { a }, options = { scope = "Selection" }, revision = repository:revision("Project", "Live") }
		end
		local p = build(live()); local h = history(); local writes = 0
		function h:TryBeginRecording()
			self.begins += 1
			storage:FindFirstChild(Constants.PROJECT_ROOT_NAME).Live.Attributes:SetAttribute("Zero", 123)
			return "record"
		end
		local ok, err = Apply.new(Collection, h, function(_, _, write) writes += 1; write() end):apply(p.plan, live)
		assert(not ok and err:find("Recipe changed") and writes == 0 and h.cancels == 1, tostring(err)); restored(a)
		local revision = repository:revision("Project", "Live")
		p = build(live()); local edited = recipe(); edited.attributes.Zero = 321
		assert(repository.projectStore:update("Live", edited))
		assert(repository:revision("Project", "Live") == revision, "Test must bypass repository mutation token")
		assert(not Apply.new(Collection, history()):apply(p.plan, live)); restored(a)
		p = build(live()); storage:FindFirstChild(Constants.PROJECT_ROOT_NAME).Live:SetAttribute("FormatVersion", 999)
		assert(live().recipe == nil and not Apply.new(Collection, history()):apply(p.plan, live)); restored(a)
	end)
	test("extra corrupt Local reload and failed write preserve storage", function()
		local p = mockSettings(); local store = Store.new(p, "isolated"); assert(store:load()); assert(store:create("Saved", recipe()))
		local before = Guard.copy(p.value)
		local first = true
		function p:SetSetting(_, value)
			self.value = value
			if first then first = false; error("Write mutated then failed") end
		end
		assert(not store:rename("Saved", "Failed")); assert(Guard.equal(before, p.value))
		assert(store:find("Saved") and not store:find("Failed"))
		p.value = { version = 2, count = 1, items = {} }
		assert(not store:load() and #store:getPresets() == 0)
		local corrupted = p.value; assert(not store:create("Overwrite", recipe())); assert(p.value == corrupted)
	end)
	test("extra typed metadata canonical round trips and nested corruption", function(cleanup)
		local root = fixture(cleanup)
		local values = {
			String = "", Boolean = false, Number = 1e-12, UDim = UDim.new(0.25, 3), UDim2 = UDim2.new(0.25, 3, 0.5, -4),
			BrickColor = BrickColor.new("Bright red"), Color = Color3.fromRGB(123, 45, 67),
			Vector2 = Vector2.new(1.25, -3.5), Vector3 = Vector3.new(1.25, 2.5, -3.75),
			Transform = CFrame.new(1.25, 2.5, 3.75) * CFrame.Angles(0.2, 0.3, 0.4),
			Range = NumberRange.new(1.25, 2.75), Rect = Rect.new(-1, 2, 3, 4),
			Numbers = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25, 0.1), NumberSequenceKeypoint.new(1, 0.5, 0.2) }),
			Colors = ColorSequence.new(Color3.fromRGB(12, 34, 56), Color3.fromRGB(210, 220, 230)),
			Font = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
		}
		local r = recipe(); r.attributes = values
		local old = require(legacy21.PresetSerializer)
		local encoded = assert(old.encodeAll({ r })); local decoded = assert(Serializer.decodeAll(encoded))
		assert(Serializer.equal({ r }, decoded)); assert(old.decodeAll(assert(Serializer.encodeAll(decoded))))
		local s = Project.new(root, history()); assert(s:create("Types", r)); assert(s:load())
		assert(Serializer.equal({ (function() local copy = Guard.copy(r); copy.name = "Types"; return copy end)() }, s:getPresets()))
		local codec = require(modules.AttributeCodec)
		local broken = assert(codec.encode(values.Numbers)); broken.items["1"].envelope = nil
		assert(codec.decode(broken) == nil)
		broken = { kind = "Vector3", x = 1e100, y = 0, z = 0 }; assert(codec.decode(broken) == nil)
	end)
	test("extra exact class compatibility excludes Texture from Decal", function(cleanup)
		local root = fixture(cleanup); local texture = Instance.new("Texture"); texture.Parent = root
		local decal = Instance.new("Decal"); decal.Parent = root
		local r = { name = "Decal only", schemaId = "Decal", capture = { tags = false, attributes = false }, properties = { Transparency = 0.5 }, tags = {}, attributes = {} }
		local p = build(context(r, { texture, decal })); assert(p.compatibleCount == 1 and p.plan.entries[1].instance == decal)
	end)
end
