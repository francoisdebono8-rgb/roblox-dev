local toolbar = plugin:CreateToolbar("AccessForge")
local toggle = toolbar:CreateButton("AccessForge", "Industrial stairs and catwalks", "")
toggle.ClickableWhenViewportHidden = true
local widget = plugin:CreateDockWidgetPluginGuiAsync("AccessForge1", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 440, 780, 360, 600))
widget.Title = "AccessForge"
local dispose = require(script.Parent.Modules.View).mount(widget, game:GetService("Selection"), game:GetService("ChangeHistoryService"))
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function() dispose(); widget:Destroy(); toolbar:Destroy() end)
