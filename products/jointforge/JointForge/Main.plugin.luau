local toolbar = plugin:CreateToolbar("JointForge")
local toggle = toolbar:CreateButton("JointForge", "Create, batch-assemble and inspect joints", "")
toggle.ClickableWhenViewportHidden = true
local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 560, 720, 320, 480)
local widget = plugin:CreateDockWidgetPluginGuiAsync("JointForge1", info)
widget.Title = "JointForge"
local dispose = require(script.Parent.Modules.View).mount(widget, game:GetService("Selection"), game:GetService("ChangeHistoryService"))
toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(widget.Enabled) end)
toggle:SetActive(widget.Enabled)
plugin.Unloading:Connect(function() dispose(); widget:Destroy(); toolbar:Destroy() end)
