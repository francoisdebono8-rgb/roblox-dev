local modules = script.Parent.Parent.PresetForge.Modules
local CollectionService = game:GetService("CollectionService")
local PreviewService = require(modules.PreviewService)
local SelectionNavigator = require(modules.SelectionNavigator)
local UIFactory = require(modules.UIFactory)
local Support = require(script.Parent.GateTestSupport)

return function(test)
	for _, libraries in ipairs({ { "Local", "Local" }, { "Local", "Project" }, { "Project", "Local" }, { "Project", "Project" } }) do
		test("duplicate/edit " .. libraries[1] .. " -> " .. libraries[2], function(cleanup)
			local repository, reopen = Support.repository(cleanup)
			local recipe = Support.recipe()
			recipe.attributes.Offset = Vector3.new(1.25, 2.5, -3.75)
			recipe.attributes.Tint = Color3.fromRGB(12, 34, 56)
			assert(repository:create(libraries[1], "Original", recipe))
			local original = assert(repository:find(libraries[1], "Original"))
			local copied, variant = repository:duplicate(libraries[1], "Original", libraries[2], "Variant")
			assert(copied, tostring(variant))
			assert(variant.name == "Variant" and variant.library == libraries[2])
			for _, key in ipairs({ "capture", "properties", "tags", "attributes" }) do
				Support.equal(original[key], variant[key], key)
			end
			variant.properties.Anchored = false
			variant.properties.Massless = true
			variant.tags[1] = "PresetForgeVariant"
			variant.attributes.Level = 99
			variant.attributes.Offset = Vector3.new(8, 9, 10)
			variant.capture.tags = false
			Support.equal(original, repository:find(libraries[1], "Original"), "original after returned-copy mutation")
			assert(repository:find(libraries[2], "Variant").properties.Anchored == true,
				"mutating the returned copy must not silently write the stored variant")
			variant.capture.tags = true
			assert(repository:update(libraries[2], "Variant", variant))
			local reloaded = reopen()
			Support.equal(original, reloaded:find(libraries[1], "Original"), "persisted original")
			Support.equal(variant, reloaded:find(libraries[2], "Variant"), "persisted variant")
		end)
	end

	test("duplicate failures preserve both libraries", function(cleanup)
		local repository, reopen = Support.repository(cleanup)
		assert(repository:create("Local", "Original", Support.recipe()))
		assert(repository:create("Project", "Occupied", Support.recipe()))
		local before = repository:getRecipes()
		for _, args in ipairs({
			{ "Local", "Original", "Project", "ORIGINAL" },
			{ "Local", "Original", "Local", "occupied" },
			{ "Local", "Missing", "Project", "Variant" },
			{ "Local", "Original", "Unknown", "Variant" },
			{ "Local", "Original", "Project", "" },
		}) do
			local ok, message = repository:duplicate(table.unpack(args))
			assert(ok == false and type(message) == "string" and #message > 0)
			Support.equal(before, repository:getRecipes())
			Support.equal(before, reopen():getRecipes())
		end
	end)

	test("case-insensitive literal name search", function(cleanup)
		local repository = Support.repository(cleanup)
		local names = { "zeta", "Alpha [Boss].*+?%()^$-", "ALPine", "plain" }
		for index, name in ipairs(names) do
			assert(repository:create(index % 2 == 0 and "Project" or "Local", name, Support.recipe()))
		end
		local all = repository:getRecipes()
		Support.equal({ all[1].name, all[2].name, all[3].name, all[4].name },
			{ names[2], names[3], names[4], names[1] })
		Support.equal(all, repository:getRecipes(""))
		for _, query in ipairs({ "aLp", "[bOsS]", ".*", "+", "?", "%", "(", ")", "^", "$", "-", "[", "]", "missing", "BasePart", "Project" }) do
			local expected = {}
			for _, recipe in ipairs(all) do
				if string.find(string.lower(recipe.name), string.lower(query), 1, true) then
					expected[#expected + 1] = recipe
				end
			end
			Support.equal(expected, repository:getRecipes(query), "search " .. query)
		end
		Support.equal(all, repository:getRecipes(), "search is read-only")
	end)

	test("changes-first stable resolver order, including duplicate paths", function(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local a = Support.part(folder, "Duplicate", false)
		local b = Support.part(folder, "Duplicate", false)
		local m1 = Support.part(folder, "Matching", true)
		local m2 = Support.part(folder, "Matching", true)
		local i1 = Instance.new("Folder")
		i1.Name, i1.Parent = "Ignored", folder
		local i2 = Instance.new("Folder")
		i2.Name, i2.Parent = "Ignored", folder
		local recipe = Support.recipe()
		recipe.capture, recipe.tags, recipe.attributes = { tags = false, attributes = false }, {}, {}
		local selection = { i2, m2, b, i1, a, m1, b }
		local service = Support.preview()
		local preview = assert(service:build(recipe, selection, { scope = "Selection" }))
		assert(preview.scannedCount == 6 and preview.affectedCount == 2 and preview.matchingCount == 2 and preview.ignoredCount == 2)
		local expected = { b, a, m2, m1, i2, i1 }
		local statuses = { "affected", "affected", "matching", "matching", "ignored", "ignored" }
		for index, result in ipairs(preview.results) do
			assert(result.instance == expected[index] and result.status == statuses[index], "unstable result " .. index)
		end
		assert(#preview.results == #expected)
		Support.equal({ b, a }, preview.targets)
		assert(not a.Anchored and not b.Anchored, "Preview mutated a target")
		assert(PreviewService.same(preview, assert(service:build(recipe, selection, { scope = "Selection" }))))
	end)

	test("stale preview detects exact values, tags, membership and paths", function(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local target = Support.part(folder, "Target", false)
		local recipe = Support.recipe()
		local service = Support.preview()
		local function build(selection, options)
			return assert(service:build(recipe, selection or { target }, options or { scope = "Selection" }))
		end
		local original = build()
		target.Color = Color3.fromRGB(99, 88, 77)
		assert(PreviewService.same(original, build()), "unselected property invalidated preview")
		for _, change in ipairs({
			function() target:SetAttribute("Level", 3) end,
			function() CollectionService:AddTag(target, recipe.tags[1]) end,
			function() target.Anchored = true end,
			function() target.Name = "Renamed" end,
		}) do
			local before = build()
			change()
			assert(not PreviewService.same(before, build()), "relevant change did not stale preview")
		end
		assert(not PreviewService.same(build(), build({})), "removed target did not stale preview")
		assert(not PreviewService.same(build(), build({ folder }, {
			scope = "Descendants", className = "Part", nameContains = "Renamed", tag = "",
		})), "changed scope did not stale preview")
	end)

	test("controller exact before/after and captured values", function(cleanup)
		local repository = Support.repository(cleanup)
		local controller = Support.controller(cleanup, repository)
		local before = string.rep("before [literal].% ", 12) .. "BEFORE-END"
		local after = string.rep("after [literal].% ", 12) .. "AFTER-END"
		local precise = 123.123456789
		local recipe = Support.recipe()
		recipe.attributes.Note, recipe.attributes.Level = after, precise
		local captured = controller:_capturedText(recipe)
		assert(string.find(captured, after, 1, true), "captured string was truncated")
		assert(string.find(captured, string.format("%.17g", precise), 1, true), "captured number lost precision")
		local instance = Instance.new("Part")
		cleanup(function() instance:Destroy() end)
		local result = controller:_resultText({
			instance = instance, status = "affected", path = "Workspace." .. string.rep("LongPath.", 16) .. "End",
			changes = { { kind = "attribute", name = "Note", before = before, after = after } },
		}, 1)
		assert(string.find(result, before, 1, true) and string.find(result, after, 1, true), "before/after string was truncated")
	end)

	test("controller Apply rechecks stale data even without watchers", function(cleanup)
		local repository = Support.repository(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local target = Support.part(folder, "Target", false)
		assert(repository:create("Local", "Recipe", Support.recipe()))
		local controller, ui, _, history = Support.controller(cleanup, repository, { target })
		controller:_runPreview()
		assert(controller._preview and ui.applyButton.Active)
		controller:_stopWatchingPreview()
		target:SetAttribute("Level", 3)
		controller:_apply()
		assert(history.begins == 0 and not target.Anchored and target:GetAttribute("Level") == 3,
			"stale Apply wrote to the target")
		assert(controller._preview == nil, "stale plan must be discarded")
		controller:_runPreview()
		controller:_apply()
		assert(history.begins == 1 and history.commits == 1 and target.Anchored and target:GetAttribute("Level") == 7)
		assert(target.CanCollide == false and target:GetAttribute("Keep") == "unchanged")
		assert(CollectionService:HasTag(target, "PresetForgeReleaseGateKeep"))
	end)

	test("controller watched property clears Preview and disables Apply", function(cleanup)
		local repository = Support.repository(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local target = Support.part(folder, "Target", false)
		assert(repository:create("Local", "Recipe", Support.recipe()))
		local controller, ui, _, history = Support.controller(cleanup, repository, { target })
		controller:_runPreview()
		target:SetAttribute("Level", 3)
		task.wait()
		assert(controller._preview == nil and not ui.applyButton.Active)
		controller:_apply()
		assert(history.begins == 0 and not target.Anchored and target:GetAttribute("Level") == 3)
		controller:_runPreview()
		target.Anchored = true
		task.wait()
		assert(controller._preview == nil and not ui.applyButton.Active)
		controller:_apply()
		assert(history.begins == 0 and target:GetAttribute("Level") == 3)
		controller:_runPreview()
		controller:_apply()
		assert(history.begins == 1 and target.Anchored and target:GetAttribute("Level") == 7)
	end)

	test("controller selection, scope and filter invalidate Preview", function(cleanup)
		local repository = Support.repository(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local target = Support.part(folder, "Target", false)
		assert(repository:create("Local", "Recipe", Support.recipe()))
		local controller, ui, selection, history = Support.controller(cleanup, repository, { target })
		controller:_runPreview()
		selection:Set({ folder })
		task.wait()
		assert(controller._preview == nil and not ui.applyButton.Active)
		controller:_runPreview()
		controller:_setScope("Descendants")
		assert(controller._preview == nil)
		for _, input in ipairs({ ui.nameFilterInput, ui.tagFilterInput, ui.classFilterInput }) do
			controller:_resetFilters(controller:_recipe())
			task.wait()
			controller:_runPreview()
			assert(controller._preview)
			input.Text ..= "Changed"
			task.wait()
			assert(controller._preview == nil and not ui.applyButton.Active)
			controller:_apply()
		end
		assert(history.begins == 0 and not target.Anchored)
	end)

	test("controller Select groups is read-only and requires fresh Preview", function(cleanup)
		local repository = Support.repository(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local affected = Support.part(folder, "Affected", false)
		local matching = Support.part(folder, "Matching", true)
		local ignored = Instance.new("Folder")
		ignored.Parent = folder
		local recipe = Support.recipe()
		recipe.capture, recipe.tags, recipe.attributes = { tags = false, attributes = false }, {}, {}
		assert(repository:create("Local", "Recipe", recipe))
		local controller, _, selection, history = Support.controller(cleanup, repository, { ignored, matching, affected })
		controller:_runPreview()
		local preview = controller._preview
		for _, status in ipairs({ "affected", "matching", "ignored" }) do
			selection:Set({ ignored, matching, affected })
			task.wait()
			controller:_runPreview()
			controller:_selectResults(status)
			task.wait()
			Support.equal(preview[status], selection:Get(), status)
			assert(controller._preview == nil, "changed Selection must invalidate exact plan")
		end
		assert(not affected.Anchored and matching.Anchored and history.begins == 0)
	end)

	test("controller search filters the rendered library without editing recipes", function(cleanup)
		local repository = Support.repository(cleanup)
		assert(repository:create("Local", "Alpha [Boss]", Support.recipe()))
		assert(repository:create("Project", "Other", Support.recipe()))
		local before = repository:getRecipes()
		local controller, ui = Support.controller(cleanup, repository)
		assert(ui.searchInput and ui.duplicateButton and ui.frameAffectedButton and ui.showMatchingButton and ui.showIgnoredButton,
			"missing #16 UI controls")
		local selected = controller:_recipe()
		ui.searchInput.Text = "[bOsS]"
		task.wait()
		assert(Support.textIn(ui.presetList, "Alpha [Boss]") and not Support.textIn(ui.presetList, "Other"))
		ui.searchInput.Text = "no such recipe"
		task.wait()
		assert(not Support.textIn(ui.presetList, "Alpha [Boss]") and not Support.textIn(ui.presetList, "Other"))
		assert(controller:_recipe().name == selected.name, "search discarded the selected recipe")
		ui.searchInput.Text = ""
		task.wait()
		assert(Support.textIn(ui.presetList, "Alpha [Boss]") and Support.textIn(ui.presetList, "Other"))
		Support.equal(before, repository:getRecipes())
	end)

	test("controller Edit variant preserves original nested fields", function(cleanup)
		local repository, reopen = Support.repository(cleanup)
		assert(repository:create("Local", "Original", Support.recipe()))
		assert(repository:duplicate("Local", "Original", "Project", "Variant"))
		local original = repository:find("Local", "Original")
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local source = Support.part(folder, "VariantSource", false)
		source.Massless = true
		source:SetAttribute("Level", 99)
		CollectionService:AddTag(source, "PresetForgeVariant")
		local controller, ui = Support.controller(cleanup, repository, { source })
		Support.selectRecipe(controller, "Project", "Variant")
		controller:_openEdit()
		assert(ui.editorOverlay.Visible and controller._editorFields.Anchored and controller._editorFields.Massless)
		UIFactory.setCheckbox(controller._editorFields.Anchored, true)
		UIFactory.setCheckbox(controller._editorFields.Massless, true)
		UIFactory.setCheckbox(ui.tagsCheck, true)
		UIFactory.setCheckbox(ui.attributesCheck, true)
		for name, check in pairs(controller._editorTags) do UIFactory.setCheckbox(check, name == "PresetForgeVariant") end
		for name, check in pairs(controller._editorAttributes) do UIFactory.setCheckbox(check, name == "Level") end
		controller:_saveEditor()
		assert(not ui.editorOverlay.Visible)
		local variant = assert(reopen():find("Project", "Variant"))
		assert(variant.properties.Anchored == false and variant.properties.Massless == true and variant.properties.CanCollide == nil)
		assert(variant.attributes.Level == 99 and table.find(variant.tags, "PresetForgeVariant"))
		Support.equal(original, reopen():find("Local", "Original"))
	end)

	test("controller duplicate confirmation creates and selects a separate variant", function(cleanup)
		local repository = Support.repository(cleanup)
		assert(repository:create("Project", "Original", Support.recipe()))
		local original = repository:find("Project", "Original")
		local controller, ui = Support.controller(cleanup, repository)
		controller._renameMode = "duplicate"
		ui.renameInput.Text = "Variant"
		ui.renamePanel.Visible = true
		controller:_renameRecipe()
		assert(controller:_recipe().name == "Variant" and controller:_recipe().library == "Project")
		assert(not ui.renamePanel.Visible and ui.searchInput.Text == "")
		Support.equal(original, repository:find("Project", "Original"))
		assert(#repository:getRecipes() == 2)
	end)

	test("controller changes-only default and optional matching/ignored rows", function(cleanup)
		local repository = Support.repository(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local affected = Support.part(folder, "ChangedObject", false)
		local matching = Support.part(folder, "MatchingObject", true)
		local ignored = Instance.new("Folder")
		ignored.Name, ignored.Parent = "IgnoredObject", folder
		local recipe = Support.recipe()
		recipe.capture, recipe.tags, recipe.attributes = { tags = false, attributes = false }, {}, {}
		assert(repository:create("Local", "Recipe", recipe))
		local controller, ui = Support.controller(cleanup, repository, { ignored, matching, affected })
		controller:_runPreview()
		assert(Support.textIn(ui.resultList, "ChangedObject"))
		assert(not Support.textIn(ui.resultList, "MatchingObject") and not Support.textIn(ui.resultList, "IgnoredObject"))
		controller._showMatching = true
		controller:_renderResults()
		assert(Support.textIn(ui.resultList, "MatchingObject") and not Support.textIn(ui.resultList, "IgnoredObject"))
		controller._showIgnored = true
		controller:_renderResults()
		assert(Support.textIn(ui.resultList, "IgnoredObject"))
		local rows = {}
		for _, row in ipairs(ui.resultList:GetChildren()) do
			if row.Name == "ObjectChanges" then rows[#rows + 1] = row end
		end
		table.sort(rows, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		assert(#rows == 3 and rows[1]:GetAttribute("Status") == "affected" and rows[2]:GetAttribute("Status") == "matching")
		assert(Support.textIn(rows[1], "ChangedObject") and Support.textIn(rows[2], "MatchingObject"))
		controller:_runPreview()
		assert(not controller._showMatching and not controller._showIgnored)
		assert(not affected.Anchored and matching.Anchored)
	end)

	test("controller retains capture draft but refuses a changed source", function(cleanup)
		local repository = Support.repository(cleanup)
		local folder = Instance.new("Folder")
		cleanup(function() folder:Destroy() end)
		local source = Support.part(folder, "Source", true)
		local other = Support.part(folder, "Other", false)
		local controller, ui, selection = Support.controller(cleanup, repository, { source })
		controller:_openCreate()
		ui.editorNameInput.Text = "Unsaved draft"
		UIFactory.setCheckbox(controller._editorFields.Anchored, true)
		UIFactory.setCheckbox(ui.tagsCheck, true)
		UIFactory.setCheckbox(ui.attributesCheck, true)
		selection:Set({ other })
		task.wait()
		assert(ui.editorOverlay.Visible and ui.editorNameInput.Text == "Unsaved draft")
		assert(controller._editorSource == source and controller._editorFields.Anchored:GetAttribute("Checked"))
		assert(ui.tagsCheck:GetAttribute("Checked") and ui.attributesCheck:GetAttribute("Checked"))
		controller:_saveEditor()
		assert(#repository:getRecipes() == 0 and ui.editorOverlay.Visible, "source mismatch saved the wrong object")
		assert(source.Anchored and not other.Anchored)
	end)

	test("Frame uses rotated spatial bounds without changing instances", function(cleanup)
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = "PresetForgeReleaseGateFrameFixture", workspace
		cleanup(function() folder:Destroy() end)
		local part = Support.part(folder, "Rotated", true)
		part.Size = Vector3.new(2, 4, 6)
		part.CFrame = CFrame.new(10, 5, -3) * CFrame.Angles(0, 0, math.pi / 2)
		local light = Instance.new("PointLight")
		light.Parent = part
		local camera = { calls = 0 }
		function camera:ZoomToExtents(frame, size)
			self.calls += 1
			assert((frame.Position - Vector3.new(10, 5, -3)).Magnitude < 1e-5)
			assert((size - Vector3.new(4, 2, 6)).Magnitude < 1e-5)
		end
		local before = { frame = part.CFrame, size = part.Size, attrs = part:GetAttributes(), tags = CollectionService:GetTags(part) }
		local childCount = #folder:GetDescendants()
		assert(SelectionNavigator.frame({ light, part, light }, camera))
		assert(camera.calls == 1 and #folder:GetDescendants() == childCount)
		Support.equal(before.frame, part.CFrame)
		Support.equal(before.size, part.Size)
		Support.equal(before.attrs, part:GetAttributes())
		local tags = CollectionService:GetTags(part)
		table.sort(tags)
		table.sort(before.tags)
		Support.equal(before.tags, tags)
	end)

	test("Frame refuses missing camera and nonspatial selection", function(cleanup)
		local frame = Instance.new("Frame")
		cleanup(function() frame:Destroy() end)
		local calls = 0
		local camera = { ZoomToExtents = function() calls += 1 end }
		local ok, message = SelectionNavigator.frame({}, nil)
		assert(ok == false and type(message) == "string")
		ok, message = SelectionNavigator.frame({ frame }, camera)
		assert(ok == false and type(message) == "string" and calls == 0)
	end)
end
