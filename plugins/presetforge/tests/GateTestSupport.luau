local modules = script.Parent.Parent.PresetForge.Modules
local CollectionService = game:GetService("CollectionService")
local ApplyService = require(modules.ApplyService)
local CaptureService = require(modules.CaptureService)
local Controller = require(modules.Controller)
local PresetStore = require(modules.PresetStore)
local PreviewService = require(modules.PreviewService)
local ProjectStore = require(modules.ProjectStore)
local RecipeRepository = require(modules.RecipeRepository)
local TargetResolver = require(modules.TargetResolver)
local UIFactory = require(modules.UIFactory)

local Support = {}

function Support.equal(left, right, path)
	path = path or "value"
	assert(typeof(left) == typeof(right), path .. ": type changed")
	if type(left) ~= "table" then
		assert(left == right, path .. ": value changed")
		return
	end
	for key, value in pairs(left) do
		Support.equal(value, right[key], path .. "." .. tostring(key))
	end
	for key in pairs(right) do
		assert(left[key] ~= nil, path .. ": unexpected key " .. tostring(key))
	end
end

function Support.repository(cleanup)
	local settings = {}
	local fakePlugin = {}
	function fakePlugin:GetSetting(key)
		return settings[key]
	end
	function fakePlugin:SetSetting(key, value)
		settings[key] = value
	end
	local container = Instance.new("Folder")
	container.Name = "PresetForgeGateProject"
	cleanup(function() container:Destroy() end)
	local function reopen()
		local repository = RecipeRepository.new(
			PresetStore.new(fakePlugin, "PresetForgeReleaseGateFakeSettings"),
			ProjectStore.new(container)
		)
		assert(repository:load())
		return repository
	end
	return reopen(), reopen, container
end

function Support.recipe()
	return {
		name = "Gate recipe",
		schemaId = "BasePart",
		capture = { tags = true, attributes = true },
		properties = { Anchored = true },
		tags = { "PresetForgeReleaseGateApplied" },
		attributes = { Level = 7, Note = "exact original", Enabled = false },
	}
end

function Support.part(parent, name, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = anchored == true
	part.CanCollide = false
	part.Color = Color3.fromRGB(12, 34, 56)
	part:SetAttribute("Keep", "unchanged")
	CollectionService:AddTag(part, "PresetForgeReleaseGateKeep")
	part.Parent = parent
	return part
end

function Support.preview()
	return PreviewService.new(CollectionService, TargetResolver.new(CollectionService))
end

function Support.host(cleanup, width, height)
	local screen = Instance.new("ScreenGui")
	screen.Name = "PresetForgeReleaseGateUI"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	cleanup(function() screen:Destroy() end)
	local host = Instance.new("Frame")
	host.Name = "MeasuredViewport"
	host.BackgroundTransparency = 1
	host.Size = UDim2.fromOffset(width or 560, height or 640)
	host.Parent = screen
	screen.Parent = game:GetService("CoreGui")
	return host
end

function Support.controller(cleanup, repository, selection, host)
	local selectionEvent = Instance.new("BindableEvent")
	cleanup(function() selectionEvent:Destroy() end)
	local mockSelection = { items = table.clone(selection or {}), SelectionChanged = selectionEvent.Event }
	function mockSelection:Get()
		return table.clone(self.items)
	end
	function mockSelection:Set(items)
		self.items = table.clone(items)
		selectionEvent:Fire()
	end
	local history = { begins = 0, commits = 0 }
	function history:TryBeginRecording()
		self.begins += 1
		return "PresetForgeGateMockRecording"
	end
	function history:FinishRecording(_, operation)
		assert(operation == Enum.FinishRecordingOperation.Commit)
		self.commits += 1
	end
	local ui = UIFactory.build(host or Support.host(cleanup))
	local controller = Controller.new(ui, repository, CaptureService.new(CollectionService),
		Support.preview(), ApplyService.new(CollectionService, history), mockSelection)
	cleanup(function() controller:destroy() end)
	task.wait()
	return controller, ui, mockSelection, history
end

function Support.selectRecipe(controller, library, name)
	controller._selectedLibrary = library
	controller._selectedName = name
	controller:_resetFilters(assert(controller:_recipe()))
	controller:_render()
	task.wait()
end

function Support.textIn(root, needle)
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			if string.find(object.Text, needle, 1, true) then
				return true
			end
		end
	end
	return false
end

return Support
