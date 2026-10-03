local toolbar = plugin:CreateToolbar("JointForge")
local toggle = toolbar:CreateButton("JointForge", "Scan assemblies, inspect issues and preview explicit repairs", "")
toggle.ClickableWhenViewportHidden = true
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 560, 720, 240, 360)
local widget = plugin:CreateDockWidgetPluginGuiAsync("JointForge1", info)
widget.Title = "JointForge | Forge Studio 0.2.5"
local dispose = require(script.Parent.Modules.View).mount(widget, game:GetService("Selection"), game:GetService("ChangeHistoryService"))
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function() dispose(); widget:Destroy(); toolbar:Destroy() end)
