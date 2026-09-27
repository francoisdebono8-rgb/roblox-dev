local Settings = require(script.Parent.Settings)
local Geometry = require(script.Parent.Geometry)
local Engine = {}
local GROUPS = { "Stairs", "Landings", "Rails", "Supports" }

local function child(parent, name, class)
	local found
	for _, item in ipairs(parent:GetChildren()) do
		if item.Name == name then assert(not found, "Duplicate " .. name .. " in assembly."); found = item end
	end
	assert(found and found.ClassName == class, "Missing or invalid " .. name .. ".")
	if class == "ObjectValue" then assert(#found:GetChildren() == 0, "Unexpected additions inside " .. name .. " metadata.") end
	return found
end
local function marker(value)
	assert(typeof(value) == "Instance" and value:IsA("BasePart") and value:IsDescendantOf(workspace), "Assign valid Start and End BaseParts in Workspace.")
end

function Engine.read(model)
	assert(typeof(model) == "Instance" and model:IsA("Model") and model:IsDescendantOf(workspace), "Select one AccessForge assembly in Workspace.")
	local data = child(model, "AccessForgeData", "Folder")
	assert(data:GetAttribute("Version") == 1, "Unsupported AccessForge metadata version.")
	local output = child(data, "Output", "ObjectValue").Value
	assert(output and output:IsA("Model") and output.Parent == model, "Generated geometry was removed or moved.")
	local groups = {}
	for _, name in ipairs(GROUPS) do groups[name] = child(output, name, "Folder") end
	local owned, seen = {}, {}
	local registry = child(data, "Owned", "Folder")
	assert(#registry:GetChildren() <= Settings.MAX_PARTS, "Ownership registry exceeds the output cap.")
	for _, ref in ipairs(registry:GetChildren()) do
		assert(ref:IsA("ObjectValue") and #ref:GetChildren() == 0, "Invalid ownership metadata.")
		local p = ref.Value
		if p then
			assert(p:IsA("Part") and not seen[p] and p:GetAttribute("AccessForgeGenerated") == true, "Invalid generated part reference.")
			assert(p.Parent and groups[p.Parent.Name] == p.Parent, "Generated parts were moved. Restore their group before regenerating.")
			assert(#p:GetChildren() == 0, "A generated part contains user additions. Move those additions outside that part before regenerating.")
			seen[p] = true; table.insert(owned, p)
		end
	end
	local start, finish = child(data, "Start", "ObjectValue").Value, child(data, "End", "ObjectValue").Value
	marker(start); marker(finish)
	assert(not seen[start] and not seen[finish], "Control markers cannot be generated geometry.")
	local settings = {}
	for key in pairs(Settings.defaults) do settings[key] = data:GetAttribute(key) end
	Settings.validate(settings)
	assert(#data:GetChildren() == 4, "Metadata contains unexpected objects. Preserve them outside AccessForgeData first.")
	return { data = data, output = output, groups = groups, owned = owned, start = start, finish = finish, settings = settings }
end

function Engine.plan(start, finish, settings, target)
	marker(start); marker(finish); assert(start ~= finish, "Start and End must be different markers.")
	local plan = Geometry.plan(start.Position, finish.Position, settings)
	plan.start, plan.finish = start, finish
	plan.a, plan.b = start.Position, finish.Position
	plan.target = target
	if target then
		local current = Engine.read(target)
		for _, p in ipairs(current.owned) do assert(p ~= start and p ~= finish, "Markers cannot be owned generated parts.") end
		plan.data = current.data
	end
	return plan
end

function Engine.load(model)
	local current = Engine.read(model)
	return Engine.plan(current.start, current.finish, current.settings, model)
end

function Engine.output(plan)
	local output = Instance.new("Model"); output.Name = "Generated"
	local groups, parts = {}, {}
	local ok, err = pcall(function()
		for _, name in ipairs(GROUPS) do local f = Instance.new("Folder"); f.Name = name; f.Parent = output; groups[name] = f end
		for _, spec in ipairs(plan.parts) do
			local p = Instance.new("Part")
			p.Name, p.Size, p.CFrame = spec.name, spec.size, spec.cf
			p.Shape = spec.round and Enum.PartType.Cylinder or Enum.PartType.Block
			p.Material, p.Color = Enum.Material[spec.material], spec.color
			p.Anchored, p.CanCollide = plan.settings.Anchored, plan.settings.CanCollide
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p:SetAttribute("AccessForgeGenerated", true)
			p.Parent = groups[spec.group]; table.insert(parts, p)
		end
	end)
	if not ok then output:Destroy(); error(err) end
	return output, parts, groups
end

local function metadata(plan, output, parts)
	local data = Instance.new("Folder"); data.Name = "AccessForgeData"
	data:SetAttribute("Version", 1)
	for key, value in pairs(plan.settings) do data:SetAttribute(key, value) end
	local function ref(parent, name, value)
		local r = Instance.new("ObjectValue"); r.Name = name; r.Value = value; r.Parent = parent
	end
	ref(data, "Start", plan.start); ref(data, "End", plan.finish); ref(data, "Output", output)
	local owned = Instance.new("Folder"); owned.Name = "Owned"; owned.Parent = data
	for i, p in ipairs(parts) do ref(owned, tostring(i), p) end
	return data
end

function Engine.apply(plan, history)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before building.")
	assert(not plan.used, "Preview again before building.")
	marker(plan.start); marker(plan.finish)
	assert(plan.start.Position == plan.a and plan.finish.Position == plan.b, "Markers moved. Preview again.")
	local previous
	if plan.target then
		previous = Engine.read(plan.target)
		assert(previous.data == plan.data, "Assembly changed. Load or preview it again.")
	end
	local output, parts = Engine.output(plan)
	local destination = previous and previous.output or output
	local data = metadata(plan, destination, parts)
	local model = plan.target or Instance.new("Model")
	local oldParents = {}
	local id = history:TryBeginRecording("AccessForge", previous and "Regenerate AccessForge" or "Build AccessForge")
	if not id then output:Destroy(); data:Destroy(); if not previous then model:Destroy() end; error("Undo recording unavailable. Finish the other operation and retry.") end
	local ok, err = pcall(function()
		if previous then
			for _, p in ipairs(previous.owned) do oldParents[p] = p.Parent; p.Parent = nil end
			previous.data.Parent = nil
			for _, p in ipairs(parts) do p.Parent = previous.groups[p.Parent.Name] end
		else
			model.Name = "AccessForge_" .. plan.settings.Mode
			output.Parent = model
		end
		data.Parent = model
		if not previous then model.Parent = workspace end
		history:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then
		for _, p in ipairs(parts) do p:Destroy() end
		data:Destroy()
		if previous then
			for p, parent in pairs(oldParents) do p.Parent = parent end
			previous.data.Parent = model
		else model:Destroy() end
		output:Destroy()
		pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end)
		error(err)
	end
	if previous then output:Destroy() end
	plan.used = true
	return model
end

function Engine.newMarkers(history, origin, mode)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before creating markers.")
	local id = history:TryBeginRecording("AccessForgeMarkers", "New AccessForge markers")
	assert(id, "Undo recording unavailable.")
	local folder = Instance.new("Folder"); folder.Name = "AccessForge_Markers"
	local points = {}
	local ok, err = pcall(function()
		local offset = if mode == "Switchback" then Vector3.new(9, 16, 0) elseif mode == "Catwalk" then Vector3.new(0, 0, -30) else Vector3.new(0, 8, -20)
		for i, position in ipairs({ origin, origin + offset }) do
			local p = Instance.new("Part"); p.Name = i == 1 and "Start" or "End"
			p.Shape, p.Size, p.Position = Enum.PartType.Ball, Vector3.one * 0.7, position
			p.Color, p.Transparency = Color3.fromRGB(250, 176, 50), 0.3
			p.Anchored, p.CanCollide, p.CanTouch, p.CastShadow = true, false, false, false
			p.Parent = folder; points[i] = p
		end
		folder.Parent = workspace
		history:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then folder:Destroy(); pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end); error(err) end
	return points[1], points[2]
end

return Engine
