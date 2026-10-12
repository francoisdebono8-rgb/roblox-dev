-- Disposable first-review harness. Never shipped in the commercial artifact.
if workspace:GetAttribute("PresetForgeUIGate") ~= true then return end
assert(game.PlaceId == 0 and not game:GetService("RunService"):IsRunning())
local modules = script.Parent.Candidate.Modules
local collection = game:GetService("CollectionService")
local selection = game:GetService("Selection")
local history = game:GetService("ChangeHistoryService")
local storage = game:GetService("ServerStorage")
local settingsData = {}
local isolatedSettings = {}
function isolatedSettings:GetSetting(key) return settingsData[key] end
function isolatedSettings:SetSetting(key, value) settingsData[key] = value end
local repository = require(modules.RecipeRepository).new(
    require(modules.PresetStore).new(isolatedSettings, "PresetForgeUIReview"),
    require(modules.ProjectStore).new(storage, history))
assert(repository:load())
local capture = require(modules.CaptureService).new(collection)
local source = storage.ReferenceFixture.Source
local workshop = workspace.Workshop
local widget = plugin:CreateDockWidgetPluginGuiAsync("PresetForgeUIReview_" .. game:GetService("HttpService"):GenerateGUID(false),
    DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, true, 562, 666, 562, 666))
widget.Title = "PresetForge UI review"
local host = Instance.new("Frame"); host.Name = "ExactViewport"; host.BackgroundTransparency = 1
host.Size = UDim2.fromOffset(560, 640); host.Parent = widget
local ui = require(modules.UIFactory).build(host)
local controller = require(modules.Controller).new(ui, repository, capture,
    require(modules.PreviewService).new(collection, require(modules.TargetResolver).new(collection)),
    require(modules.ApplyService).new(collection, history), selection)
local factory = require(modules.UIFactory)
local prefix = "[PresetForgeEnablement] "

-- Focused checks for newly exposed selective capture, through the real controller.
selection:Set({source})
controller:_openCreate()
ui.editorNameInput.Text = "Selective metadata"
factory.setCheckbox(ui.tagsCheck, true); factory.setCheckbox(ui.attributesCheck, true)
for name, check in pairs(controller._editorTags) do factory.setCheckbox(check, name == "FixtureReady") end
for name, check in pairs(controller._editorAttributes) do factory.setCheckbox(check, name == "LightingProfile") end
controller:_saveEditor()
assert(not ui.editorOverlay.Visible, ui.editorHint.Text)
local selected = repository:find("Local", "Selective metadata")
assert(selected and #selected.tags == 1 and selected.tags[1] == "FixtureReady")
assert(selected.attributes.LightingProfile == "Warm" and selected.attributes.Keep == nil and selected.attributes.FixtureId == nil)
assert(next(selected.properties) == nil and source:GetAttribute("Keep") == false)
assert(repository:delete("Local", "Selective metadata"))
print(prefix .. "PASS selective tag/attribute controls: only checked names saved; source unchanged")

local crowded = source:Clone(); crowded.Name = "CaptureLimitProbe"; crowded.Parent = storage
for i = 1, 65 do crowded:AddTag("Probe" .. i); crowded:SetAttribute("Probe" .. i, i) end
selection:Set({crowded}); controller:_openCreate(); ui.editorNameInput.Text = "Disabled metadata probe"
factory.setCheckbox(controller._editorFields.Brightness, true)
controller:_saveEditor()
assert(not ui.editorOverlay.Visible, ui.editorHint.Text)
local propertyOnly = repository:find("Local", "Disabled metadata probe")
assert(propertyOnly and propertyOnly.properties.Brightness == 5 and #propertyOnly.tags == 0 and next(propertyOnly.attributes) == nil)
assert(repository:delete("Local", "Disabled metadata probe")); crowded:Destroy()
print(prefix .. "PASS disabled metadata does not validate unselected names over category limits")

assert(repository:create("Local", "Cool worklights", assert(capture:capture(
    {workshop.Lighting["Bay 01"]["Fixture 01"].Diffuser["Worklight 01"]},
    {properties={"Brightness", "Color"}, tags=false, attributes=false}))))

local snapshots = {}
for _, item in ipairs(workshop:GetDescendants()) do
    if item:IsA("PointLight") then
        snapshots[item] = {Brightness=item.Brightness, Color=item.Color, Range=item.Range,
            Shadows=item.Shadows, Enabled=item.Enabled, id=item:GetAttribute("FixtureId"), keep=item:GetAttribute("Keep")}
    end
end
local descendants = workshop:GetDescendants()
local function unchanged()
    assert(#workshop:GetDescendants() == #descendants)
    for item, value in pairs(snapshots) do
        assert(item.Brightness == value.Brightness and item.Color == value.Color and item.Range == value.Range)
        assert(item.Shadows == value.Shadows and item.Enabled == value.Enabled)
        assert(item:GetAttribute("FixtureId") == value.id and item:GetAttribute("Keep") == value.keep)
        assert(item:HasTag("KeepTag") and not item:HasTag("FixtureReady"))
    end
end
local function preview()
    ui.editorOverlay.Visible = false
    controller._selectedLibrary = "Project"; controller._selectedName = "Warm worklights"
    controller:_render(); controller:_resetFilters(controller:_recipe())
    selection:Set({workshop})
    task.wait(.2) -- Native SelectionChanged is deferred; mimic selecting before clicking Preview.
    controller:_setScope("Descendants"); controller:_runPreview()
    local result = assert(controller._preview)
    local m = result.metrics
    assert(m.scanned == #descendants and m.compatible == 40 and m.affected == 30 and m.matching == 10)
    assert(m.ignored == #descendants-40 and m.propertyWrites == 60 and m.tagWrites == 0 and m.attributeWrites == 0)
    assert(ui.applyButton.Text == "Apply 30" and ui.applyButton.Active)
    unchanged()
    print(prefix .. string.format("PASS real read-only Preview: scanned=%d compatible=%d affected=%d matching=%d ignored=%d propertyWrites=%d tagWrites=%d attributeWrites=%d",
        m.scanned,m.compatible,m.affected,m.matching,m.ignored,m.propertyWrites,m.tagWrites,m.attributeWrites))
end
preview()
local camera = workspace.CurrentCamera
camera.CFrame = CFrame.lookAt(Vector3.new(51,27,47), Vector3.new(0,3,0)); camera.FieldOfView = 50
local bridge = Instance.new("BindableFunction"); bridge.Name = "PresetForgeUIQA"; bridge.Parent = storage
bridge.OnInvoke = function(command, width)
    if command == "resize" then host.Size = UDim2.fromOffset(width,640)
    elseif command == "preview" then preview()
    elseif command == "scene" then widget.Enabled = false; selection:Set({})
    elseif command == "show" then widget.Enabled = true; preview()
    elseif command == "editor" then selection:Set({source}); controller:_openEdit()
    elseif command == "apply" then controller:_apply()
    elseif command == "stale" then
        workshop.Lighting["Bay 01"]["Fixture 01"].Diffuser["Worklight 01"].Brightness = 3
    end
    return true
end
task.spawn(function()
    task.wait(5)
    for _, width in ipairs({560,320}) do
        host.Size = UDim2.fromOffset(width,640)
        preview()
        widget.Enabled = false; task.wait(.1); widget.Enabled = true; task.wait(3)
        assert(ui.previewMetrics.Visible and ui.previewMetrics:FindFirstChild("AffectedMetric").Text == "30 will change")
        for _, item in ipairs(ui.previewMetrics:GetChildren()) do
            if item:IsA("TextLabel") then assert(item.TextFits, item.Name .. " text clipped") end
        end
        for _, item in ipairs(ui.resultList:GetDescendants()) do
            if item.Name == "ObjectPath" then
                local available = width - (width >= 520 and 168 or 0) - 28
                assert(item.TextBounds.X <= available + 1, "Object path overflows the workspace")
            end
        end
        assert(ui.applyButton.AbsolutePosition.Y+ui.applyButton.AbsoluteSize.Y <= host.AbsolutePosition.Y+host.AbsoluteSize.Y)
        print(prefix .. "CAPTURE dark-" .. width .. " viewport=" .. tostring(host.AbsoluteSize) .. " sha256=" .. script.Parent:GetAttribute("SHA256"))
        task.wait(45)
    end
    print(prefix .. "FIRST REVIEW COMPLETE; final regression, Apply/Undo/Redo, Light NOT RUN pending visual acceptance")
end)
plugin.Unloading:Connect(function() controller:destroy(); widget:Destroy() end)
