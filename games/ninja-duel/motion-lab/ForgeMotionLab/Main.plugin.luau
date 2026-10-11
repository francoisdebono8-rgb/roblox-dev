-- Local Studio plugin only; importing the model into a place cannot start it.
if not plugin then return end
local toolbar=plugin:CreateToolbar("Forge Motion Lab")
local button=toolbar:CreateButton("Motion Lab","Create, edit and mix R15 motion variants","","Motion Lab")
button.ClickableWhenViewportHidden=true
local widget=plugin:CreateDockWidgetPluginGuiAsync("ForgeMotionLab_v1",DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,false,false,1180,780,780,600))
widget.Title="Forge Motion Lab · UI+"
local dispose,controller=require(script.Parent.Modules.View).mount(widget,plugin)
button.Click:Connect(function()widget.Enabled=not widget.Enabled end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function()button:SetActive(widget.Enabled)end)
button:SetActive(widget.Enabled)
plugin.Unloading:Connect(function()dispose();widget:Destroy();toolbar:Destroy()end)
