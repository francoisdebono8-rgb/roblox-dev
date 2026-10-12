local Settings = require(script.Parent.Settings)
local Geometry = require(script.Parent.Geometry)
local Engine = {}
local GROUPS = { "Stairs", "Landings", "Rails", "Supports" }
local issued = setmetatable({}, { __mode = "k" })
local PART_PROPERTIES = { "CFrame", "Size", "Shape", "Color", "Material", "MaterialVariant", "Anchored", "CanCollide",
	"CanTouch", "CanQuery", "CastShadow", "Transparency", "Reflectance", "Locked", "Massless", "CollisionGroup",
	"CustomPhysicalProperties", "PivotOffset", "RootPriority", "AssemblyLinearVelocity", "AssemblyAngularVelocity",
	"TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface" }

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

-- Exact before-state checks are separate from tolerant native write verification.
local function exact(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if typeof(a) == "CFrame" then return exact({a:GetComponents()}, {b:GetComponents()}) end
	if typeof(a) == "Vector3" then return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
	if typeof(a) == "Color3" then return a.R == b.R and a.G == b.G and a.B == b.B end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not exact(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

function Engine.read(model)
	assert(typeof(model) == "Instance" and model:IsA("Model") and model:IsDescendantOf(workspace), "Select one AccessForge assembly in Workspace.")
	local data = child(model, "AccessForgeData", "Folder")
	local version = data:GetAttribute("Version")
	assert(version == 1 or version == 2, "Unsupported AccessForge metadata version.")
	local output = child(data, "Output", "ObjectValue").Value
	assert(output and output == child(model, "Generated", "Model"), "Generated geometry was removed or moved.")
	local groups = {}
	for _, name in ipairs(GROUPS) do groups[name] = child(output, name, "Folder") end
	local owned, seen, refs = {}, {}, {}
	local registry = child(data, "Owned", "Folder")
	local count = #registry:GetChildren()
	assert(count > 0 and count <= Settings.MAX_PARTS, "Invalid ownership registry count.")
	if version == 2 then assert(data:GetAttribute("OwnedCount") == count, "Ownership registry count changed.") end
	for _, ref in ipairs(registry:GetChildren()) do
		assert(ref:IsA("ObjectValue") and #ref:GetChildren() == 0, "Invalid ownership metadata.")
		local index = tonumber(ref.Name)
		assert(index and index % 1 == 0 and index >= 1 and index <= count and tostring(index) == ref.Name and not refs[index], "Ownership registry order is corrupt.")
		refs[index] = ref
	end
	for i = 1, count do
		local ref = refs[i]; assert(ref, "Missing ownership registry entry.")
		local p = ref.Value
		assert(p and p:IsA("Part") and not seen[p] and p:GetAttribute("AccessForgeGenerated") == true, "Missing or duplicate generated part reference.")
		assert(p.Parent and groups[p.Parent.Name] == p.Parent, "Generated parts were moved. Restore their group before regenerating.")
		assert(#p:GetChildren() == 0, "A generated part contains user additions. Move those additions outside that part before regenerating.")
		if version == 2 then
			assert(p:GetAttribute("AccessForgeIndex") == i and ref:GetAttribute("Group") == p.Parent.Name, "Generated ownership identity changed.")
		end
		seen[p] = true; owned[i] = p
	end
	for _, item in ipairs(output:GetDescendants()) do
		assert(item:GetAttribute("AccessForgeGenerated") ~= true or seen[item], "Unregistered generated object: ownership is ambiguous.")
	end
	local start, finish = child(data, "Start", "ObjectValue").Value, child(data, "End", "ObjectValue").Value
	marker(start); marker(finish)
	assert(start ~= finish and not seen[start] and not seen[finish], "Control markers cannot be identical or generated geometry.")
	local settings = {}
	for key in pairs(Settings.defaults) do settings[key] = data:GetAttribute(key) end
	Settings.validate(settings)
	assert(#data:GetChildren() == 4, "Metadata contains unexpected objects. Preserve them outside AccessForgeData first.")
	return { data = data, output = output, groups = groups, owned = owned, refs = refs, registry = registry,
		start = start, finish = finish, settings = settings, version = version }
end

local function capture(object, properties, children)
	local values = { Name = object.Name, Parent = object.Parent, Archivable = object.Archivable }
	for _, key in ipairs(properties or {}) do values[key] = object[key] end
	local tags = object:GetTags(); table.sort(tags)
	local state = { object = object, values = values, attributes = object:GetAttributes(), tags = tags, properties = properties }
	if children then state.children = {}; for _, c in ipairs(object:GetChildren()) do state.children[c] = true end end
	return state
end

local function snapshot(start, finish, target, current)
	local states, ancestors = {}, {}
	local function add(object, properties, children) table.insert(states, capture(object, properties, children)) end
	local function ancestry(object)
		while object ~= workspace do
			assert(object, "Object left Workspace.")
			if not ancestors[object] then add(object); ancestors[object] = true end
			object = object.Parent
		end
	end
	for _, p in ipairs({start, finish}) do ancestry(p); add(p, {"CFrame"}) end
	if current then
		ancestry(target); add(target, {"PrimaryPart"})
		add(current.output, {"PrimaryPart"}); add(current.data, nil, true); add(current.registry, nil, true)
		for _, c in ipairs(current.data:GetChildren()) do if c:IsA("ObjectValue") then add(c, {"Value"}, true) end end
		for _, name in ipairs(GROUPS) do add(current.groups[name]) end
		for i, p in ipairs(current.owned) do add(p, PART_PROPERTIES, true); add(current.refs[i], {"Value"}, true) end
	end
	return states
end

local function fresh(plan, record)
	marker(plan.start); marker(plan.finish)
	assert(exact(Settings.validate(record.input), plan.settings), "Settings changed. Preview again.")
	if plan.target then
		local current = Engine.read(plan.target)
		assert(current.data == plan.data and current.output == plan.outputIdentity and exact(current.owned, plan.owned), "Assembly identity changed. Preview again.")
	end
	for _, state in ipairs(record.states) do
		local object = state.object
		for key, value in pairs(state.values) do assert(exact(object[key], value), "Project changed. Preview again: " .. key) end
		-- Also check properties whose before value is nil (PrimaryPart/physical overrides).
		for _, key in ipairs(state.properties or {}) do assert(exact(object[key], state.values[key]), "Project property changed. Preview again: " .. key) end
		local tags = object:GetTags(); table.sort(tags)
		assert(exact(object:GetAttributes(), state.attributes) and exact(tags, state.tags), "Attributes or tags changed. Preview again.")
		if state.children then
			local children = {}; for _, c in ipairs(object:GetChildren()) do children[c] = true end
			assert(exact(children, state.children), "Owned children changed. Preview again.")
		end
	end
end

function Engine.plan(start, finish, settings, target)
	marker(start); marker(finish); assert(start ~= finish, "Start and End must be different markers.")
	local current = target and Engine.read(target)
	if current then for _, p in ipairs(current.owned) do assert(p ~= start and p ~= finish, "Markers cannot be owned generated parts.") end end
	local plan = table.clone(Geometry.plan(start.Position, finish.Position, settings))
	plan.start, plan.finish, plan.a, plan.b, plan.target = start, finish, start.Position, finish.Position, target
	if current then
		plan.data, plan.outputIdentity = current.data, current.output
		plan.owned, plan.groups = table.freeze(table.clone(current.owned)), table.freeze(table.clone(current.groups))
	end
	issued[plan] = { input = settings, states = snapshot(start, finish, target, current), previous = current, used = false }
	return table.freeze(plan)
end

function Engine.isFresh(plan)
	local record = issued[plan]
	if not record or record.used then return false end
	return (pcall(fresh, plan, record))
end

function Engine.load(model)
	local current = Engine.read(model)
	return Engine.plan(current.start, current.finish, current.settings, model)
end

local function verifyPart(p, spec, settings)
	assert((p.Size - spec.size).Magnitude <= 0.002, "Generated size did not persist.")
	local actual, wanted = {p.CFrame:GetComponents()}, {spec.cf:GetComponents()}
	for i, value in ipairs(wanted) do assert(math.abs(actual[i] - value) <= (i <= 3 and 0.003 or 0.00001), "Generated frame did not persist.") end
	assert(p.Material == Enum.Material[spec.material] and p.Shape == (spec.round and Enum.PartType.Cylinder or Enum.PartType.Block), "Generated material/profile did not persist.")
	assert(p.Anchored == settings.Anchored and p.CanCollide == settings.CanCollide, "Generated physics flags did not persist.")
	for _, component in ipairs({"R", "G", "B"}) do assert(math.abs(p.Color[component] - spec.color[component]) <= 1 / 255, "Generated color did not persist.") end
end

local function allocate(plan)
	local output = Instance.new("Model"); output.Name = "Generated"
	local groups, parts = {}, {}
	local ok, err = pcall(function()
		for _, name in ipairs(GROUPS) do local f = Instance.new("Folder"); f.Parent = output; f.Name = name; groups[name] = f end
		for i, spec in ipairs(plan.parts) do
			local p = Instance.new("Part"); table.insert(parts, p); p.Parent = groups[spec.group]
			p.Name, p.Size, p.CFrame = spec.name, spec.size, spec.cf
			p.Shape = spec.round and Enum.PartType.Cylinder or Enum.PartType.Block
			p.Material, p.Color = Enum.Material[spec.material], spec.color
			p.Anchored, p.CanCollide = plan.settings.Anchored, plan.settings.CanCollide
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p:SetAttribute("AccessForgeGenerated", true); p:SetAttribute("AccessForgeIndex", i)
			verifyPart(p, spec, plan.settings)
		end
	end)
	if not ok then for _, p in ipairs(parts) do p:Destroy() end; output:Destroy(); error(err, 0) end
	return output, parts, groups
end

function Engine.output(plan)
	assert(Engine.isFresh(plan), "Preview requires a fresh issued plan.")
	return allocate(plan)
end

local function metadata(plan, output, parts)
	local data = Instance.new("Folder"); data.Name = "AccessForgeData"
	local ok, err = pcall(function()
		data:SetAttribute("Version", 2); data:SetAttribute("OwnedCount", #parts)
		for key, value in pairs(plan.settings) do data:SetAttribute(key, value) end
		local function ref(parent, name, value)
			local r = Instance.new("ObjectValue"); r.Parent = parent; r.Name = name; r.Value = value; return r
		end
		ref(data, "Start", plan.start); ref(data, "End", plan.finish); ref(data, "Output", output)
		local owned = Instance.new("Folder"); owned.Parent = data; owned.Name = "Owned"
		for i, p in ipairs(parts) do ref(owned, tostring(i), p):SetAttribute("Group", plan.parts[i].group) end
	end)
	if not ok then data:Destroy(); error(err, 0) end
	return data
end

function Engine.apply(plan, history)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before building.")
	local record = issued[plan]
	assert(record and not record.used, "Build requires an unused issued plan. Preview again.")
	record.used = true
	fresh(plan, record)
	local previous = record.previous
	local output, parts = allocate(plan)
	local data, model, id
	local journal = {}
	local function move(object, parent)
		table.insert(journal, { object = object, parent = object.Parent })
		object.Parent = parent
		assert(object.Parent == parent, "Parent write did not persist.")
	end
	local ok, err = pcall(function()
		data = metadata(plan, previous and previous.output or output, parts)
		model = plan.target or Instance.new("Model")
		if not previous then model.Name = "AccessForge_" .. plan.settings.Mode; output.Parent = model; data.Parent = model end
		id = history:TryBeginRecording("AccessForge", previous and "Regenerate AccessForge" or "Build AccessForge")
		assert(id, "Undo recording unavailable. Preview again after the other operation finishes.")
		fresh(plan, record)
		if previous then
			for _, p in ipairs(previous.owned) do move(p, nil) end
			move(previous.data, nil)
			for i, p in ipairs(parts) do move(p, previous.groups[plan.parts[i].group]) end
			move(data, model)
		else move(model, workspace) end
		local current = Engine.read(model)
		assert(current.data == data and #current.owned == plan.count, "Committed ownership did not persist.")
		for i, p in ipairs(parts) do verifyPart(p, plan.parts[i], plan.settings) end
		history:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then
		local failures = {}
		for i = #journal, 1, -1 do
			local entry = journal[i]
			local restored, reason = pcall(function()
				entry.object.Parent = entry.parent
				assert(entry.object.Parent == entry.parent, "Rollback parent did not persist.")
			end)
			if not restored then table.insert(failures, tostring(reason)) end
		end
		if id then
			local cancelled, reason = pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end)
			if not cancelled then table.insert(failures, tostring(reason)) end
		end
		for _, p in ipairs(parts) do p:Destroy() end
		if data then data:Destroy() end
		output:Destroy(); if model and not previous then model:Destroy() end
		assert(#failures == 0, tostring(err) .. "; Rollback failed: " .. table.concat(failures, "; "))
		error(err, 0)
	end
	-- Old Parts and metadata remain detached and alive for native Undo identity.
	if previous then output:Destroy() end
	return model
end

function Engine.newMarkers(history, origin, mode)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before creating markers.")
	assert(mode == "Straight" or mode == "Switchback" or mode == "Catwalk", "Invalid marker mode.")
	assert(typeof(origin) == "Vector3" and Settings.number(origin.Magnitude) and origin.Magnitude < 20000, "Invalid marker origin.")
	local offset = if mode == "Switchback" then Vector3.new(9, 16, 0) elseif mode == "Catwalk" then Vector3.new(0, 0, -30) else Vector3.new(0, 8, -20)
	assert((origin + offset).Magnitude < 20000, "End marker would exceed the coordinate bound.")
	local folder = Instance.new("Folder"); folder.Name = "AccessForge_Markers"
	local points, id = {}, nil
	local ok, err = pcall(function()
		for i, position in ipairs({ origin, origin + offset }) do
			local p = Instance.new("Part"); p.Parent = folder; points[i] = p; p.Name = i == 1 and "Start" or "End"
			p.Shape, p.Size, p.Position = Enum.PartType.Ball, Vector3.one * 0.7, position
			p.Color, p.Transparency = Color3.fromRGB(250, 176, 50), 0.3
			p.Anchored, p.CanCollide, p.CanTouch, p.CastShadow = true, false, false, false
		end
		id = history:TryBeginRecording("AccessForgeMarkers", "New AccessForge markers")
		assert(id, "Undo recording unavailable.")
		folder.Parent = workspace
		assert(folder.Parent == workspace, "Marker parent write did not persist.")
		history:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then
		folder.Parent = nil
		local cancelled, reason = true, nil
		if id then cancelled, reason = pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end) end
		folder:Destroy()
		assert(cancelled, tostring(err) .. "; Recording cancel failed: " .. tostring(reason))
		error(err, 0)
	end
	return points[1], points[2]
end

return Engine
