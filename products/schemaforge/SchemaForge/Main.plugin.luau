local toolbar = plugin:CreateToolbar("SchemaForge")
local toggle = toolbar:CreateButton("SchemaForge", "Tagged object configuration audit", "")
toggle.ClickableWhenViewportHidden = true
local widget = plugin:CreateDockWidgetPluginGuiAsync("SchemaForge1", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 420, 640, 240, 360))
widget.Title = "SchemaForge | Forge Studio 0.2.5"
local dispose = require(script.Parent.Modules.View).mount(widget, game:GetService("Selection"), game:GetService("ChangeHistoryService"))
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function() dispose(); widget:Destroy(); toolbar:Destroy() end)
