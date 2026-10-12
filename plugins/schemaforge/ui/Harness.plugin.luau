if workspace:GetAttribute("SchemaForgeUIGate") ~= true then return end
assert(game.PlaceId == 0 and not game:GetService("RunService"):IsRunning())
local modules = script.Parent.Candidate.Modules
local Geometry = require(script.Parent.Geometry)
local Schema, Store = require(modules.Schema), require(modules.Store)
local history, selection = game:GetService("ChangeHistoryService"), game:GetService("Selection")
local Engine=require(modules.Engine)
local calls={audit=0,preview=0,selection=0}
for _,name in ipairs({"audit","preview"}) do
    local original=Engine[name]
    Engine[name]=function(...)
        calls[name]+=1
        print("[SchemaForgeUI][ENGINE] "..name.."="..calls[name])
        return original(...)
    end
end
selection.SelectionChanged:Connect(function() calls.selection+=1 end)
local folder = Instance.new("Folder"); folder.Name = "Greenhouse"; folder.Parent = workspace
local reference = Instance.new("Part"); reference.Name = "ReferencePot"; reference.Anchored = true
reference:SetAttribute("Cost", 25); reference:SetAttribute("GrowthRate", 1); reference:SetAttribute("Enabled", true)
reference:AddTag("PlantPot"); reference:AddTag("Interactable"); reference.Parent = folder
local schema = Schema.capture(reference); schema.name = "Greenhouse Contract"; schema.tag = "PlantPot"
schema.requiredTags = {"Interactable"}; schema.forbiddenTags = {"Retired"}
for _, f in ipairs(schema.fields) do
    f.required = true; f.hasDefault = true
    f.description = f.name == "Cost" and "Purchase cost in coins. Missing costs use the starter-pot price." or "Shared greenhouse configuration."
    if f.kind == "number" then f.min = 0 end
end
schema.children = {{path = "Attachment", className = "Attachment", description = "Interaction anchor", optional = true}}
for i = 1, 6 do
    local p = reference:Clone(); p.Name = i <= 2 and "PlantPot" or "PlantPot" .. i; p.Position = Vector3.new(i * 5, 0, 0); p.Parent = folder
    if i <= 3 then p:SetAttribute("Cost", nil) elseif i == 4 then p:SetAttribute("Cost", "unknown") else p:SetAttribute("GrowthRate", -2) end
    if i == 2 then p:RemoveTag("Interactable") end
    if i == 5 then p:AddTag("Retired") end
end
history:SetWaypoint("SchemaForge UI fixture")
Store.save(schema, nil, history)
selection:Set({folder})
local widget, dispose, host
local function snapshot()
    local root=host.SchemaForgeUI
    print("[SchemaForgeUI][STATE] "..root.Header.DocumentState.Text.." / "..root.Header.ContractName.Text.." / "..root.Footer.Status.Text)
    local ok,result=pcall(Geometry.check,root)
    print("[SchemaForgeUI][GEOMETRY "..(ok and "PASS" or "FAIL").."] "..tostring(root.AbsoluteSize).." "..tostring(result))
    local costs,tags=0,0
    assert(folder.Parent == workspace, "QA fixture was removed from Workspace")
    for _,p in ipairs(folder:GetChildren()) do
        if p:GetAttribute("Cost")==nil then costs+=1 end
        if not p:HasTag("Interactable") then tags+=1 end
    end
    print("[SchemaForgeUI][FIXTURE] missingCosts="..costs.." missingTags="..tags.." invalidCost="..tostring(folder.PlantPot4:GetAttribute("Cost")).." invalidGrowth="..tostring(folder.PlantPot5:GetAttribute("GrowthRate")))
    for _,v in ipairs(root.Footer.Actions:GetChildren()) do
        if v:IsA("TextButton") then print("[SchemaForgeUI][ACTION] "..v.Name.." active="..tostring(v.Active).." text="..v.Text) end
    end
end
local function mount()
    if dispose then dispose(); widget:Destroy() end
    local width, height = workspace:GetAttribute("UIWidth") or 560, workspace:GetAttribute("UIHeight") or 640
    widget = plugin:CreateDockWidgetPluginGuiAsync("SchemaForgeUI23_" .. game:GetService("HttpService"):GenerateGUID(false),
        DockWidgetPluginGuiInfo.new(workspace:GetAttribute("UIDocked") and Enum.InitialDockState.Right or Enum.InitialDockState.Float, true, true, width, height, width, 360))
    widget.Title = "SchemaForge UI review"
    host = Instance.new("Frame"); host.Name = "ExactViewport"; host.Size = UDim2.fromOffset(width, height); host.BackgroundTransparency = 1; host.Parent = widget
    host.DescendantAdded:Connect(function(v)
        if v:IsA("TextButton") then
            v.Activated:Connect(function()
                print("[SchemaForgeUI][CLICK] "..v.Name)
                if v.Name:match("^OpenFinding") or v.Name:match("^RuleField") or v.Name:match("^RuleChild") or v.Name:match("^LibraryEntry") then
                    local before=table.clone(calls)
                    task.delay(0.2,function()
                        local unchanged=calls.audit==before.audit and calls.preview==before.preview and calls.selection==before.selection
                        print("[SchemaForgeUI][INSPECTION "..(unchanged and "PASS" or "FAIL").."] "..v.Name.." audit="..calls.audit.." preview="..calls.preview.." selection="..calls.selection)
                    end)
                end
                task.delay(0.3,snapshot)
            end)
        elseif v:IsA("TextBox") then
            v:GetPropertyChangedSignal("Text"):Connect(function()
                local owner=v:FindFirstAncestorWhichIsA("ScrollingFrame"); local scroll=owner and owner.CanvasPosition or Vector2.zero
                task.defer(function()
                    if v.Parent then
                        print("[SchemaForgeUI][TEXT] "..v.Name.." focus="..tostring(v:IsFocused()).." caret="..v.CursorPosition.." sameControl=true scrollStable="..tostring(not owner or owner.CanvasPosition==scroll))
                    end
                end)
            end)
        end
    end)
    local original = Schema.new
    Schema.new = function() return Schema.copy(schema) end
    local ok, result = pcall(require(modules.View).mount, host, selection, history)
    Schema.new = original
    assert(ok, result); dispose = result
    task.delay(1,function()
        print("[SchemaForgeUI] mounted " .. width .. "x" .. height .. " theme=" .. settings().Studio.Theme.Name .. " sha256=" .. script.Parent:GetAttribute("SHA256"))
        print("[SchemaForgeUI] viewport="..tostring(host.AbsolutePosition).." size="..tostring(host.AbsoluteSize))
    end)
end
workspace:GetAttributeChangedSignal("UIResize"):Connect(function()
    host.Size=UDim2.fromOffset(workspace:GetAttribute("UIWidth") or 560,workspace:GetAttribute("UIHeight") or 640)
    task.delay(0.3,snapshot)
end)
workspace:GetAttributeChangedSignal("UICommand"):Connect(function()
    local command=workspace:GetAttribute("UICommand")
    workspace:SetAttribute("UICommand",nil)
    if not command then return end
    local ok,err=pcall(function()
        if command=="matrix" then Geometry.matrix(host)
        elseif command=="root" then selection:Set({folder})
        elseif command=="reference" then selection:Set({reference})
        elseif command=="stale" then folder.PlantPot3:SetAttribute("GrowthRate",2)
        elseif command=="undo" then history:Undo()
        elseif command=="redo" then history:Redo()
        elseif command=="snapshot" then snapshot()
        end
    end)
    if not ok then warn("[SchemaForgeUI][FAIL] "..tostring(err)) end
end)
workspace:GetAttributeChangedSignal("UIProbe"):Connect(function()
    local root = widget.ExactViewport.SchemaForgeUI
    for _, v in ipairs(root:GetDescendants()) do
        if v:IsA("TextButton") or v:IsA("TextBox") then
            local visible, parent = v.Visible, v.Parent
            while parent and parent ~= root do if parent:IsA("GuiObject") then visible = visible and parent.Visible end; parent = parent.Parent end
            if visible then print("[SchemaForgeUI][CONTROL]", v.Name, v.Text, tostring(v.AbsolutePosition), tostring(v.AbsoluteSize)) end
        end
    end
end)
mount()

-- Invoking this QA-only bridge does not write an attribute into native history.
local bridge=Instance.new("BindableFunction"); bridge.Name="SchemaForgeUIQA"; bridge.Parent=game.ServerStorage
bridge.OnInvoke=function(command,width,height)
    if command=="resize" then
        host.Size=UDim2.fromOffset(width,height); task.wait(0.3); snapshot()
    elseif command=="matrix" then snapshot(); Geometry.matrix(host)
    elseif command=="snapshot" then snapshot()
    elseif command=="undo" then history:Undo(); task.wait(0.3); snapshot()
    elseif command=="redo" then history:Redo(); task.wait(0.3); snapshot()
    elseif command=="reference" then selection:Set({reference})
    elseif command=="root" then selection:Set({folder})
    elseif command=="long" then
        local s=Schema.copy(schema)
        s.name="Greenhouse Seasonal Prop Configuration and Interaction Contract"
        s.fields={}
        for i=1,32 do
            local f=Schema.copy(schema.fields[1])
            f.name=string.format("SeasonalGreenhousePropagationConfiguration_InteractionCostRule_%02d",i)
            f.required=i==1; f.hasDefault=false; s.fields[i]=f
        end
        Store.save(s,nil,history)
        folder.PlantPot3.Name="Greenhouse_Production_Seasonal_Propagation_Pot_With_A_Long_Identity"
        print("[SchemaForgeUI][FIXTURE] long contract saved with 32 real attribute rules")
    elseif command=="selection" then
        local list=selection:Get(); print("[SchemaForgeUI][SELECTION] count="..#list)
        for _,v in ipairs(list) do print("[SchemaForgeUI][SELECTED] "..v:GetFullName()) end
    else error("Unknown QA command") end
    return true
end
local toolbar=plugin:CreateToolbar("SchemaForge QA")
for _,command in ipairs({"matrix","root","reference","long","snapshot"}) do
    local b=toolbar:CreateButton("SchemaForgeQA_"..command,command,"",command)
    b.Click:Connect(function() bridge:Invoke(command) end)
end
local sizes={Vector2.new(240,360),Vector2.new(320,640),Vector2.new(400,640),Vector2.new(560,640)}
local sizeIndex=4
local resize=toolbar:CreateButton("SchemaForgeQA_resize","Cycle exact QA viewport","","resize")
resize.Click:Connect(function()
    sizeIndex=sizeIndex%#sizes+1
    bridge:Invoke("resize",sizes[sizeIndex].X,sizes[sizeIndex].Y)
end)
history.OnUndo:Connect(function() task.delay(0.3,function() print("[SchemaForgeUI][NATIVE UNDO]"); snapshot() end) end)
history.OnRedo:Connect(function() task.delay(0.3,function() print("[SchemaForgeUI][NATIVE REDO]"); snapshot() end) end)
local last=""
task.spawn(function()
    while host.Parent do
        task.wait(0.5)
        local root=host.SchemaForgeUI
        local signature=root.Header.DocumentState.Text..root.Header.ContractName.Text..root.Footer.Status.Text
        if signature~=last then last=signature; snapshot() end
    end
end)
history:SetWaypoint("SchemaForge UI fixture ready")
