-- Command Bar helper for the disposable licensed arena. Never shipped in the plugin.
-- All product actions (capture, Preview, Apply, duplicate, edit) are real GUI clicks.
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local environment = assert(workspace:FindFirstChild("Environment"), "Open the licensed arena copy")
local lights, mixed = {}, {}
for _, object in ipairs(environment:GetDescendants()) do
	if object:IsA("PointLight") then lights[#lights + 1] = object end
	if object:IsA("SpotLight") and not mixed[1] then mixed[1] = object end
	if object:IsA("BasePart") and not mixed[2] then mixed[2] = object end
end
assert(#lights == 21, "Expected 21 authored PointLights")
table.sort(lights, function(left, right)
	return (left:GetAttribute("Circuit") or 0) < (right:GetAttribute("Circuit") or 0)
end)
local widget
for _, object in ipairs(game:GetDescendants()) do
	if object:IsA("DockWidgetPluginGui") and object.Title == "PresetForge 2.1.0" then widget = object end
end
assert(widget, "Install/open the exact 2.1.0 commercial artifact")
local root = assert(widget:FindFirstChild("Root"))
local q = { lights = lights, root = root, widget = widget }

local function snapshot()
	local result = {}
	for _, object in ipairs(environment:GetDescendants()) do
		local row = { Parent = object.Parent, Name = object.Name, Attributes = object:GetAttributes(), Tags = CollectionService:GetTags(object) }
		table.sort(row.Tags)
		if object:IsA("BasePart") then
			for _, key in ipairs({ "CFrame", "Size", "Color", "Material", "Anchored", "CanCollide", "Transparency" }) do row[key] = object[key] end
		elseif object:IsA("Light") then
			for _, key in ipairs({ "Color", "Brightness", "Range", "Enabled", "Shadows" }) do row[key] = object[key] end
		end
		result[object] = row
	end
	return result
end

local function equal(left, right)
	if type(left) ~= "table" then return left == right end
	if type(right) ~= "table" then return false end
	for key, value in pairs(left) do if not equal(value, right[key]) then return false end end
	for key in pairs(right) do if left[key] == nil then return false end end
	return true
end

function q.prepare()
	for index, light in ipairs(lights) do
		light.Name = index == 1 and "ArenaLightSource" or "ArenaLight"
		light.Color = Color3.fromRGB(255, 255, 255)
		light.Brightness = 1
		CollectionService:AddTag(light, "ArenaLighting")
		CollectionService:AddTag(light, "KeepExistingTag")
		light:SetAttribute("Circuit", index)
		light:SetAttribute("Emergency", false)
	end
	lights[1].Color = Color3.fromRGB(110, 220, 255)
	lights[1].Brightness = 3
	game:GetService("Lighting").ClockTime = 18.3
	game:GetService("Lighting").Ambient = Color3.fromRGB(115, 115, 125)
	widget.Enabled = true
	Selection:Set({ lights[1] })
	q.baseline = snapshot()
	print("[PF21Arena][PASS] Prepared licensed arena: 21 PointLights, existing tags/attributes, real source selected")
end

function q.resume()
	widget.Enabled = true
	q.baseline = snapshot()
	print("[PF21Arena] Resumed saved scene; baseline is the saved state")
end

function q.assertUnchanged()
	assert(equal(q.baseline, snapshot()), "Arena changed during read-only operation")
	print("[PF21Arena][PASS] Arena unchanged: properties, transforms, tags, attributes and hierarchy")
end

function q.assertApplied()
	local expected = q.baseline
	local current = snapshot()
	for object, row in pairs(current) do
		if object:IsA("PointLight") then
			assert(row.Color == lights[1].Color and row.Brightness == 3, "Selected fields not applied")
			row.Color, row.Brightness = expected[object].Color, expected[object].Brightness
		end
	end
	assert(equal(expected, current), "Unselected field, attribute, tag or object changed")
	print("[PF21Arena][PASS] Exact Apply: 20 changed PointLights; all unselected fields/tags/attributes preserved")
end

function q.selectMixed()
	Selection:Set({ lights[1], lights[2], mixed[1], mixed[2] })
end

function q.selectRoot() Selection:Set({ environment }) end
function q.selectSource() Selection:Set({ lights[1] }) end

function q.assertAffectedSelection()
	local selected = Selection:Get()
	assert(#selected == 20, "Select affected must select exactly 20 targets")
	for _, object in ipairs(selected) do assert(object:IsA("PointLight") and object ~= lights[1]) end
	q.assertUnchanged()
	print("[PF21Arena][PASS] Select affected identifies 20 actual changing instances")
end

function q.checkStale()
	lights[2].Brightness = 0.75
	task.defer(function()
		assert(not root:FindFirstChild("ApplyButton", true).Active, "Stale Apply still enabled")
		print("[PF21Arena][PASS] Relevant change invalidated Preview and disabled Apply")
		lights[2].Brightness = q.baseline[lights[2]].Brightness
	end)
end

function q.inspect(name)
	local object = name and root:FindFirstChild(name, true) or root
	assert(object, "Unknown UI node")
	print("[PF21Arena][UI]", object.Name, "position", object.AbsolutePosition, "size", object.AbsoluteSize)
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then print("[PF21Arena][TEXT]", object.Text) end
end

function q.project()
	local store = assert(game:GetService("ServerStorage"):FindFirstChild("PresetForgeProjectRecipes"))
	local recipe = assert(store:FindFirstChild("Arena Lighting Project"))
	local properties = recipe.Properties:GetAttributes()
	assert(properties.Brightness == 3 and properties.Color == lights[1].Color)
	local count = 0
	for _ in pairs(properties) do count += 1 end
	assert(count == 2 and not recipe:GetAttribute("CaptureTags") and not recipe:GetAttribute("CaptureAttributes"))
	print("[PF21Arena][PASS] Real Project recipe stores exactly Color/Brightness, no tag or attribute capture")
end

_G.PresetForgeArenaQA = q
print("[PF21Arena] Helper ready; call prepare() once, or resume() after reopening the saved scene")
