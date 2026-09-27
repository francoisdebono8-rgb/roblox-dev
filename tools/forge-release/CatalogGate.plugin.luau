if not workspace:GetAttribute("ForgeCatalogGate") then return end
task.defer(function()
	local root = script.Parent
	local function run(name, fn)
		local ok, err = pcall(fn)
		if ok then print("[ForgeCatalogGate][PASS] " .. name) else warn("[ForgeCatalogGate][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	for _, name in ipairs({ "Schema.spec", "CapturePreview.spec", "ScopePreview.spec", "ApplyService.spec", "PresetStore.spec", "ProjectStore.spec" }) do
		run("PresetForge " .. name, function() assert(require(root.Tests[name])) end)
	end
	run("PresetForge native workflows / Undo Redo / real plugin storage", function()
		local m = root.PresetForge.Modules
		local collection, history = game:GetService("CollectionService"), game:GetService("ChangeHistoryService")
		local capture = require(m.CaptureService).new(collection)
		local preview = require(m.PreviewService).new(collection, require(m.TargetResolver).new(collection))
		local apply = require(m.ApplyService).new(collection, history)
		local folder = Instance.new("Folder"); folder.Name = "PresetForgeCatalogFixture"; folder.Parent = workspace
		local source = Instance.new("Part"); source.Anchored = true; source.Transparency = 0.4; source.Parent = folder
		source:SetAttribute("GateLevel", 8); collection:AddTag(source, "ForgeGateStyle")
		local targets = {}
		for i = 1, 3 do
			local p = Instance.new("Part"); p.Name = "GateTarget" .. i; p.Transparency = 0; p.CanCollide = false; p.Parent = folder
			p:SetAttribute("Keep", true); collection:AddTag(p, "ForgeGateTarget"); table.insert(targets, p)
		end
		local unrelated = Instance.new("Part"); unrelated.Name = "Unrelated"; unrelated.Parent = folder
		local recipe = assert(capture:capture({ source }, { properties = { "Anchored", "Transparency" }, tags = true, attributes = true }))
		recipe.name = "Catalog gate recipe"
		local count = #workspace:GetDescendants()
		local planned = assert(preview:build(recipe, { folder }, { scope = "Descendants", className = "Part", nameContains = "GateTarget", tag = "ForgeGateTarget" }))
		assert(#planned.targets == 3 and #workspace:GetDescendants() == count)
		for _, p in ipairs(targets) do assert(not p.Anchored and p.Transparency == 0 and p:GetAttribute("GateLevel") == nil) end
		local selected = assert(preview:build(recipe, { targets[1] }, { scope = "Selection" })); assert(#selected.targets == 1)
		history:SetWaypoint("PresetForge catalog baseline")
		assert(apply:apply(recipe, planned.targets))
		for _, p in ipairs(targets) do assert(p.Anchored and math.abs(p.Transparency - 0.4) < 1e-5 and not p.CanCollide and p:GetAttribute("Keep") and p:GetAttribute("GateLevel") == 8 and collection:HasTag(p, "ForgeGateStyle")) end
		assert(not unrelated.Anchored and unrelated.Transparency == 0)
		history:Undo(); task.wait()
		for _, p in ipairs(targets) do assert(not p.Anchored and p.Transparency == 0 and p:GetAttribute("GateLevel") == nil and not collection:HasTag(p, "ForgeGateStyle")) end
		history:Redo(); task.wait()
		for _, p in ipairs(targets) do assert(p.Anchored and p:GetAttribute("GateLevel") == 8) end
		local Store = require(m.PresetStore)
		local key = "ForgeCatalogGateTemporary20260927"
		local previous = plugin:GetSetting(key)
		local ok, err = pcall(function()
			plugin:SetSetting(key, nil)
			local store = Store.new(plugin, key); assert(store:load()); assert(store:create(recipe.name, recipe))
			local reopened = Store.new(plugin, key); assert(reopened:load()); assert(reopened:find(recipe.name))
			assert(reopened:rename(recipe.name, "Renamed gate recipe"))
			source.Transparency = 0.7
			local recaptured = assert(capture:recapture(recipe, { source }))
			assert(reopened:update("Renamed gate recipe", recaptured)); assert(reopened:delete("Renamed gate recipe"))
		end)
		plugin:SetSetting(key, previous)
		assert(ok, err)
		local projectRoot = Instance.new("Folder"); projectRoot.Name = "CatalogProjectLibrary"; projectRoot.Parent = game.ServerStorage
		local Project = require(m.ProjectStore)
		local store = Project.new(projectRoot); assert(store:load()); assert(store:create(recipe.name, recipe))
		local reopened = Project.new(projectRoot); assert(reopened:load()); assert(reopened:find(recipe.name))
		assert(reopened:update(recipe.name, recipe)); assert(reopened:rename(recipe.name, "Project gate")); assert(reopened:delete("Project gate"))
		projectRoot:Destroy(); folder:Destroy()
	end)
	run("JointForge suite invocation", function() require(root.JointSuite)(root.JointForge.Modules) end)
	run("CurveForge suite invocation", function() assert(require(root.CurveSuite)(root.CurveForge.Modules)) end)
	print("[ForgeCatalogGate] Finished; inspect each suite's PASS/FAIL totals.")
end)
