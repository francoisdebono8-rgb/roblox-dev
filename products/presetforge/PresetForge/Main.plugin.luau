local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local Modules = script.Parent.Modules
local ApplyService = require(Modules.ApplyService)
local CaptureService = require(Modules.CaptureService)
local Constants = require(Modules.Constants)
local Controller = require(Modules.Controller)
local PresetStore = require(Modules.PresetStore)
local PreviewService = require(Modules.PreviewService)
local UIFactory = require(Modules.UIFactory)

local toolbar = plugin:CreateToolbar("PresetForge")
local toggleButton = toolbar:CreateButton(
	"PresetForgeToggle",
	"Open PresetForge",
	"",
	"PresetForge"
)
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	680,
	520,
	480,
	360
)
local widget = plugin:CreateDockWidgetPluginGuiAsync("PresetForgeV1", widgetInfo)
widget.Title = "PresetForge " .. Constants.VERSION

local ui = UIFactory.build(widget)
local store = PresetStore.new(plugin, Constants.STORE_KEY)
local loaded, loadError = store:load()
local controller = Controller.new(
	ui,
	store,
	CaptureService.new(CollectionService),
	PreviewService.new(CollectionService),
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
