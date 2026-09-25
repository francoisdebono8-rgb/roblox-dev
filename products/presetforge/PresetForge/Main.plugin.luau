local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local Modules = script.Parent.Modules
local ApplyService = require(Modules.ApplyService)
local CaptureService = require(Modules.CaptureService)
local Constants = require(Modules.Constants)
local Controller = require(Modules.Controller)
local ProjectStore = require(Modules.ProjectStore)
local PresetStore = require(Modules.PresetStore)
local PreviewService = require(Modules.PreviewService)
local RecipeRepository = require(Modules.RecipeRepository)
local TargetResolver = require(Modules.TargetResolver)
local UIFactory = require(Modules.UIFactory)

local toolbar = plugin:CreateToolbar("PresetForge")
local toggleButton = toolbar:CreateButton(
	"PresetForgeToggle",
	"Open PresetForge Safe Bulk Editor",
	"",
	"PresetForge"
)
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	780,
	650,
	620,
	520
)
local widget = plugin:CreateDockWidgetPluginGuiAsync("PresetForgeV2", widgetInfo)
widget.Title = "PresetForge " .. Constants.VERSION

local ui = UIFactory.build(widget)
local repository = RecipeRepository.new(
	PresetStore.new(plugin, Constants.STORE_KEY),
	ProjectStore.new(ServerStorage)
)
local loaded, loadError = repository:load()
local targetResolver = TargetResolver.new(CollectionService)
local controller = Controller.new(
	ui,
	repository,
	CaptureService.new(CollectionService),
	PreviewService.new(CollectionService, targetResolver),
	ApplyService.new(CollectionService, ChangeHistoryService),
	Selection
)
if not loaded then
	controller:showError(loadError)
end

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
end)

plugin.Unloading:Connect(function()
	controller:destroy()
end)

toggleButton:SetActive(widget.Enabled)
