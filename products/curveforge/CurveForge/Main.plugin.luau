local toolbar = plugin:CreateToolbar("CurveForge")
local toggle = toolbar:CreateButton("CurveForge", "Curves, cables and repeated models", "")
toggle.ClickableWhenViewportHidden = true
local widget = plugin:CreateDockWidgetPluginGuiAsync("CurveForge1", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 440, 800, 360, 480))
widget.Title = "CurveForge"
local dispose = require(script.Parent.Modules.View).mount(widget, game:GetService("Selection"), game:GetService("ChangeHistoryService"))
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function() dispose(); widget:Destroy(); toolbar:Destroy() end)
