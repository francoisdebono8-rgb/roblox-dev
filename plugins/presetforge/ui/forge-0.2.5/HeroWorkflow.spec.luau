local modules = script.Parent.Parent.PresetForge.Modules
local Support = require(script.Parent.GateTestSupport)
local Collection = game:GetService("CollectionService")
local History = game:GetService("ChangeHistoryService")
local Apply = require(modules.ApplyService)
local Store = require(modules.PresetStore)
local Project = require(modules.ProjectStore)
local Repository = require(modules.RecipeRepository)
local UI = require(modules.UIFactory)

local function snapshot(root)
	local data = {}
	for _, item in ipairs(root:GetDescendants()) do
		local tags = item:GetTags(); table.sort(tags)
		local state = {name = item.Name, parent = item.Parent, tags = tags, attributes = item:GetAttributes()}
		if item:IsA("PointLight") then
			state.Brightness, state.Color, state.Range = item.Brightness, item.Color, item.Range
			state.Shadows, state.Enabled = item.Shadows, item.Enabled
		elseif item:IsA("BasePart") then
			state.CFrame, state.Size, state.Color = item.CFrame, item.Size, item.Color
			state.Material, state.Anchored, state.CanCollide = item.Material, item.Anchored, item.CanCollide
		end
		data[item] = state
	end
	return data
end

return function(test, assets)
	local function fixture(cleanup)
		local workshop, storage = assets.Workshop:Clone(), assets.Storage:Clone()
		workshop.Parent = workspace
		cleanup(function() workshop:Destroy(); storage:Destroy() end)
		local settingsData, settings = {}, {}
		function settings:GetSetting(key) return settingsData[key] end
		function settings:SetSetting(key, value) settingsData[key] = value end
		local repository = Repository.new(Store.new(settings, "PresetForge025HeroQA"), Project.new(storage))
		assert(repository:load())
		return workshop, storage, repository
	end
	local function recipeContext(workshop, repository, name)
		local recipe = assert(repository:find("Project", name or "Warm worklights"))
		return {recipe = recipe, selection = {workshop}, options = {scope = "Descendants", className = "PointLight"}}
	end
	local function build(context)
		return assert(Support.preview():build(context.recipe, context.selection, context.options))
	end
	test("H01 selective capture controls persist only selected metadata", function(cleanup)
		local _, storage, repository = fixture(cleanup)
		local source = storage.ReferenceFixture.Source
		local before = snapshot(storage.ReferenceFixture)
		local controller, ui = Support.controller(cleanup, repository, {source})
		controller:_openCreate(); ui.editorNameInput.Text = "Selected metadata"
		UI.setCheckbox(ui.tagsCheck, true); UI.setCheckbox(ui.attributesCheck, true)
		for name, check in pairs(controller._editorTags) do UI.setCheckbox(check, name == "FixtureReady") end
		for name, check in pairs(controller._editorAttributes) do UI.setCheckbox(check, name == "LightingProfile") end
		controller:_saveEditor()
		assert(not ui.editorOverlay.Visible, ui.editorHint.Text)
		local captured = assert(repository:find("Local", "Selected metadata"))
		Support.equal(captured.tags, {"FixtureReady"})
		Support.equal(captured.attributes, {LightingProfile = "Warm"})
		assert(next(captured.properties) == nil)
		Support.equal(before, snapshot(storage.ReferenceFixture), "capture must not alter source")
	end)
	test("H02 disabled metadata categories ignore over-limit source metadata", function(cleanup)
		local _, storage, repository = fixture(cleanup)
		local source = storage.ReferenceFixture.Source
		for index = 1, 65 do source:AddTag("Probe" .. index); source:SetAttribute("Probe" .. index, index) end
		local before = snapshot(storage.ReferenceFixture)
		local controller, ui = Support.controller(cleanup, repository, {source})
		controller:_openCreate(); ui.editorNameInput.Text = "Properties only"
		UI.setCheckbox(controller._editorFields.Brightness, true)
		controller:_saveEditor()
		assert(not ui.editorOverlay.Visible, ui.editorHint.Text)
		local captured = assert(repository:find("Local", "Properties only"))
		Support.equal(captured.properties, {Brightness = 5})
		assert(#captured.tags == 0 and next(captured.attributes) == nil)
		Support.equal(before, snapshot(storage.ReferenceFixture))
	end)
	test("H03 real workshop read-only Preview and all eight metrics", function(cleanup)
		local workshop, _, repository = fixture(cleanup)
		local before = snapshot(workshop)
		local controller, ui = Support.controller(cleanup, repository, {workshop})
		Support.selectRecipe(controller, "Project", "Warm worklights")
		controller:_setScope("Descendants"); controller:_runPreview()
		local preview = assert(controller._preview)
		Support.equal(preview.metrics, {scanned = 197, compatible = 40, affected = 30, matching = 10,
			ignored = 157, propertyWrites = 60, tagWrites = 0, attributeWrites = 0})
		assert(ui.applyButton.Active and ui.applyButton.Text == "Apply 30")
		assert(ui.previewMetrics.AffectedMetric.Text == "30 will change")
		assert(ui.currentView == "Changes" and not controller._showMatching and not controller._showIgnored)
		for _, result in ipairs(preview.results) do
			if result.status == "affected" then
				assert(#result.changes == 2)
				for _, change in ipairs(result.changes) do
					assert(change.kind == "property")
					if change.name == "Brightness" then assert(change.before == 2 and change.after == 5)
					else assert(change.name == "Color" and change.before == Color3.new(1, 1, 1) and change.after == Color3.fromRGB(255, 204, 140)) end
				end
			end
		end
		Support.equal(before, snapshot(workshop), "Preview changed the fixture")
	end)
	test("H04 Apply exact subset, native Undo, Preview again and Redo", function(cleanup)
		local workshop, _, repository = fixture(cleanup)
		cleanup(function() History:SetWaypoint("PresetForge025 hero cleanup") end)
		local context = recipeContext(workshop, repository)
		local preview, before, writes, touched = build(context), snapshot(workshop), 0, {}
		local applier = Apply.new(Collection, History, function(target, change, write)
			assert(before[target].Brightness == 2, "A matching/ignored object received a setter")
			assert(change.kind == "property" and (change.name == "Brightness" or change.name == "Color"))
			writes += 1; touched[target] = true; write()
		end)
		History:SetWaypoint("PresetForge025 workshop baseline")
		local ok, counts = applier:apply(preview.plan, context)
		assert(ok, tostring(counts))
		Support.equal(counts, {targets = 30, properties = 60, tags = 0, attributes = 0})
		local touchedCount = 0; for _ in pairs(touched) do touchedCount += 1 end
		assert(touchedCount == 30 and writes == 60)
		local expected = {}
		for item, state in pairs(before) do
			expected[item] = table.clone(state)
			if item:IsA("PointLight") then expected[item].Brightness = 5; expected[item].Color = Color3.fromRGB(255, 204, 140) end
		end
		Support.equal(expected, snapshot(workshop), "unselected data changed")
		assert(build(context).metrics.affected == 0)
		assert(History:GetCanUndo()); History:Undo(); task.wait()
		Support.equal(before, snapshot(workshop), "native Undo")
		local afterUndo = build(context)
		assert(afterUndo.metrics.affected == 30 and afterUndo.metrics.propertyWrites == 60)
		assert(History:GetCanRedo()); History:Redo(); task.wait()
		Support.equal(expected, snapshot(workshop), "native Redo")
	end)
	test("H05 stale target mutation blocks watched and synchronous Apply", function(cleanup)
		local workshop, _, repository = fixture(cleanup)
		local target = workshop.Lighting["Bay 01"]["Fixture 01"].Diffuser["Worklight 01"]
		local controller, ui, _, history = Support.controller(cleanup, repository, {workshop})
		Support.selectRecipe(controller, "Project", "Warm worklights")
		controller:_setScope("Descendants"); controller:_runPreview()
		target.Brightness = 3; task.wait()
		assert(controller._preview == nil and not ui.applyButton.Active)
		local mutated = snapshot(workshop)
		controller:_apply(); assert(history.begins == 0)
		Support.equal(mutated, snapshot(workshop))
		controller:_runPreview(); controller:_stopWatchingPreview()
		target.Brightness = 4; mutated = snapshot(workshop)
		controller:_apply()
		assert(history.begins == 0 and controller._preview == nil and not ui.applyButton.Active)
		Support.equal(mutated, snapshot(workshop), "stale synchronous Apply wrote")
	end)
	test("H06 selective metadata Apply preserves every other field/tag/attribute", function(cleanup)
		local workshop, _, repository = fixture(cleanup)
		cleanup(function() History:SetWaypoint("PresetForge025 metadata cleanup") end)
		local context = recipeContext(workshop, repository, "Service metadata")
		local before, preview = snapshot(workshop), build(context)
		assert(preview.metrics.propertyWrites == 0 and preview.metrics.tagWrites == 40 and preview.metrics.attributeWrites == 40)
		History:SetWaypoint("PresetForge025 metadata baseline")
		local ok, counts = Apply.new(Collection, History):apply(preview.plan, context)
		assert(ok, tostring(counts))
		Support.equal(counts, {targets = 40, properties = 0, tags = 40, attributes = 40})
		for item, state in pairs(before) do
			if item:IsA("PointLight") then
				state.tags[#state.tags + 1] = "FixtureReady"; table.sort(state.tags)
				state.attributes.LightingProfile = "Warm"
			end
		end
		Support.equal(before, snapshot(workshop), "metadata Apply broadened its write scope")
	end)
	test("H07 release metadata retains product semver and accepted branding", function(cleanup)
		local constants = require(modules.Constants)
		assert(constants.VERSION == "2.2.0" and constants.CATALOGUE_RELEASE == "Forge Studio 0.2.5")
		local _, ui = Support.controller(cleanup, (Support.repository(cleanup)))
		assert(ui.footer.Version.Text == constants.CATALOGUE_RELEASE)
		assert(ui.header.ProductTitle.Text == "PresetForge" and ui.header.ForgeMark)
		assert(ui.header.ProductTitle.Font == Enum.Font.BuilderSansBold)
	end)
	test("H08 real long paths and hero metrics at 240/320/400/560", function(cleanup)
		local workshop, _, repository = fixture(cleanup)
		workshop.Name = string.rep("LongWorkshop", 8) .. utf8.char(233, 28450)
		local host = Support.host(cleanup, 560, 640)
		local controller, ui = Support.controller(cleanup, repository, {workshop}, host)
		Support.selectRecipe(controller, "Project", "Warm worklights")
		controller:_setScope("Descendants")
		for _, width in ipairs({560, 320, 240, 400, 560}) do
			host.Size = UDim2.fromOffset(width, 640)
			controller:_runPreview()
			for _ = 1, 8 do task.wait() end
			local paths = 0
			for _, item in ipairs(ui.resultList:GetDescendants()) do
				if item.Name == "ObjectPath" then
					paths += 1
					assert(utf8.len(item.Text), "truncated path broke UTF-8")
					assert(item.TextBounds.X <= math.min(item.AbsoluteSize.X, width - (width >= 520 and 168 or 0) - 28) + 1,
						"Object path overflows workspace at " .. width)
				end
			end
			assert(paths == 30 and ui.applyButton.Text == "Apply 30" and ui.applyButton.Active)
			assert(ui.applyButton.AbsolutePosition.Y + ui.applyButton.AbsoluteSize.Y <= host.AbsolutePosition.Y + 640)
		end
	end)
end
