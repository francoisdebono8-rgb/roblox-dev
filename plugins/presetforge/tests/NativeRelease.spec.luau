local modules = script.Parent.Parent.PresetForge.Modules
local CollectionService = game:GetService("CollectionService")
local History = game:GetService("ChangeHistoryService")
local ApplyService = require(modules.ApplyService)
local CaptureService = require(modules.CaptureService)
local Constants = require(modules.Constants)
local PresetStore = require(modules.PresetStore)
local Support = require(script.Parent.GateTestSupport)

return function(test, pluginObject)
	test("actual ApplyService with one native Undo and Redo", function(cleanup)
		local folder = Instance.new("Folder")
		folder.Name = "PresetForgeReleaseGateHistoryFixture"
		folder.Parent = workspace
		cleanup(function()
			folder:Destroy()
			History:SetWaypoint("PresetForge QA cleanup")
		end)
		local targets = {
			Support.part(folder, "DuplicateName", false),
			Support.part(folder, "DuplicateName", false),
		}
		targets[1]:SetAttribute("Level", 2)
		targets[1]:SetAttribute("Enabled", true)
		targets[2]:SetAttribute("Enabled", false)
		local unrelated = Support.part(folder, "Unrelated", false)
		local recipe = Support.recipe()
		local preview = assert(Support.preview():build(recipe, targets, { scope = "Selection" }))
		assert(#preview.targets == 2 and not targets[1].Anchored and targets[1]:GetAttribute("Level") == 2)
		local function unchanged()
			for _, target in ipairs(targets) do
				assert(not target.CanCollide and target.Color == Color3.fromRGB(12, 34, 56))
				assert(target:GetAttribute("Keep") == "unchanged")
				assert(CollectionService:HasTag(target, "PresetForgeReleaseGateKeep"))
			end
			assert(not unrelated.Anchored and unrelated:GetAttribute("Level") == nil)
			assert(not CollectionService:HasTag(unrelated, recipe.tags[1]))
		end
		local function applied()
			for _, target in ipairs(targets) do
				assert(target.Anchored and target:GetAttribute("Level") == 7 and target:GetAttribute("Enabled") == false)
				assert(target:GetAttribute("Note") == "exact original" and CollectionService:HasTag(target, recipe.tags[1]))
			end
			unchanged()
		end
		History:SetWaypoint("PresetForge QA fixture baseline")
		local ok, counts = ApplyService.new(CollectionService, History):apply(preview.plan, { recipe = recipe, selection = targets, options = { scope = "Selection" } })
		assert(ok, tostring(counts))
		assert(counts.targets == 2 and counts.properties == 2 and counts.tags == 2 and counts.attributes == 5)
		applied()
		assert(History:GetCanUndo(), "Native undo unavailable after Apply")
		History:Undo()
		task.wait()
		for _, target in ipairs(targets) do
			assert(not target.Anchored and target:GetAttribute("Note") == nil and not CollectionService:HasTag(target, recipe.tags[1]))
		end
		assert(targets[1]:GetAttribute("Level") == 2 and targets[2]:GetAttribute("Level") == nil)
		assert(targets[1]:GetAttribute("Enabled") == true and targets[2]:GetAttribute("Enabled") == false)
		unchanged()
		assert(History:GetCanRedo(), "Native redo unavailable after Undo")
		History:Redo()
		task.wait()
		applied()
	end)

	test("real plugin settings reopen/recapture/rename/delete with restoration", function(cleanup)
		local key = "PresetForgeTechnicalGate_v2_2_0_IsolatedSettings"
		assert(key ~= Constants.STORE_KEY)
		local previous = pluginObject:GetSetting(key)
		cleanup(function()
			pluginObject:SetSetting(key, previous)
			Support.equal(previous, pluginObject:GetSetting(key), "restored QA settings")
		end)
		pluginObject:SetSetting(key, nil)
		local store = PresetStore.new(pluginObject, key)
		assert(store:load())
		assert(store:create("QA local original", Support.recipe()))
		local reopened = PresetStore.new(pluginObject, key)
		assert(reopened:load())
		local original = assert(reopened:find("QA local original"))
		local source = Instance.new("Part")
		cleanup(function() source:Destroy() end)
		source.Anchored = false
		source:SetAttribute("Level", 42)
		source:SetAttribute("Enabled", true)
		source:SetAttribute("Note", "recaptured")
		CollectionService:AddTag(source, "PresetForgeReleaseGateApplied")
		CollectionService:AddTag(source, "NotSelected")
		local captured = assert(CaptureService.new(CollectionService):recapture(original, { source }))
		assert(reopened:update(original.name, captured))
		assert(reopened:rename(original.name, "QA renamed"))
		local verified = PresetStore.new(pluginObject, key)
		assert(verified:load())
		local saved = assert(verified:find("QA renamed"))
		assert(not saved.properties.Anchored and saved.properties.CanCollide == nil and saved.attributes.Level == 42)
		assert(#saved.tags == 1 and saved.tags[1] == "PresetForgeReleaseGateApplied" and verified:find(original.name) == nil)
		assert(verified:delete(saved.name))
		assert(store:load() and #store:getPresets() == 0)
	end)
end
