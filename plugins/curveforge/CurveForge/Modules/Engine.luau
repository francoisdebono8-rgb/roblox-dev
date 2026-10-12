local Curve = require(script.Parent.Curve)
local Settings = require(script.Parent.Settings)
local Engine = {}
local fingerprints = setmetatable({}, { __mode = "k" })

local function sameValues(a, b)
	for key, value in pairs(a) do if b[key] ~= value then return false end end
	for key, value in pairs(b) do if a[key] ~= value then return false end end
	return true
end

local function finiteFrame(cf)
	assert(typeof(cf) == "CFrame", "Invalid rotation metadata.")
	for _, value in ipairs({ cf:GetComponents() }) do assert(value == value and math.abs(value) < math.huge, "Nonfinite rotation metadata.") end
	assert(cf.Position.Magnitude < 1e-6, "Rotation offset must not translate the source.")
	assert(math.abs(cf.RightVector.Magnitude - 1) < 1e-4 and math.abs(cf.UpVector.Magnitude - 1) < 1e-4
		and math.abs(cf.LookVector.Magnitude - 1) < 1e-4 and math.abs(cf.RightVector:Dot(cf.UpVector)) < 1e-4
		and cf.RightVector:Cross(cf.UpVector):Dot(-cf.LookVector) > 0.9999, "Invalid rotation basis.")
end

local function sourceSnapshot(source)
	local pivot, result = source:GetPivot(), {}
	local all = source:GetDescendants(); table.insert(all, source)
	for _, item in ipairs(all) do
		local values = { Parent = item.Parent, Name = item.Name, Archivable = item.Archivable }
		if item:IsA("BasePart") then
			values.Relative = pivot:ToObjectSpace(item.CFrame)
			for _, key in ipairs({ "Size", "PivotOffset", "Color", "Material", "Transparency", "Reflectance", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow" }) do values[key] = item[key] end
		elseif item:IsA("Model") then
			values.PrimaryPart, values.Pivot, values.Scale = item.PrimaryPart, item:GetPivot(), item:GetScale()
		elseif item:IsA("ObjectValue") then values.Value = item.Value end
		local tags = {}; for _, tag in ipairs(item:GetTags()) do tags[tag] = true end
		result[item] = { values = values, attributes = item:GetAttributes(), tags = tags }
	end
	return result
end

local function sameSource(a, b)
	for item, record in pairs(a) do
		local other = b[item]
		if not other or not sameValues(record.values, other.values) or not sameValues(record.attributes, other.attributes) or not sameValues(record.tags, other.tags) then return false end
	end
	for item in pairs(b) do if not a[item] then return false end end
	return true
end

local function sourceParts(source)
	assert(source and source:IsDescendantOf(workspace) and (source:IsA("BasePart") or source:IsA("Model")), "Choose one source Part or Model in Workspace.")
	local parts = 0
	local all = source:GetDescendants(); table.insert(all, source)
	for _, item in ipairs(all) do
		assert(item.Archivable, "Source and descendants must be Archivable.")
		assert(not item:IsA("LuaSourceContainer"), "Repeated sources must not contain scripts.")
		if item:IsA("BasePart") then parts += 1 end
		if item:IsA("JointInstance") or item:IsA("WeldConstraint") or item:IsA("NoCollisionConstraint") then
			for _, p in pairs({ item.Part0, item.Part1 }) do assert(p == source or p:IsDescendantOf(source), "Source has a joint to an external object.") end
		elseif item:IsA("Constraint") then
			for _, a in pairs({ item.Attachment0, item.Attachment1 }) do assert(a:IsDescendantOf(source), "Source has an external attachment.") end
		elseif item:IsA("ObjectValue") and item.Value then
			assert(item.Value == source or item.Value:IsDescendantOf(source), "Source has an external object reference.")
		end
	end
	assert(parts > 0 and #all <= 1000, "Source must contain parts and at most 1000 instances.")
	return parts, #all
end

function Engine.plan(controls, settings, source, rotation)
	local config, positions, seen, guides, controlState = Settings.validate(settings), {}, {}, {}, {}
	assert(#controls >= 2 and #controls <= 8, "Assign 2 to 8 ordered BaseParts.")
	for _, part in ipairs(controls) do
		assert(typeof(part) == "Instance" and part:IsA("BasePart") and part:IsDescendantOf(workspace), "A control point is invalid or was deleted.")
		assert(not seen[part], "Duplicate control point."); seen[part] = true
		table.insert(positions, part.Position)
		table.insert(guides, part.CFrame.UpVector)
		table.insert(controlState, { part = part, parent = part.Parent, cframe = part.CFrame })
	end
	local path = Curve.sample(positions, config.ControlRoll and guides or nil)
	local plan = { controls = table.clone(controls), positions = positions, settings = config, path = path, source = source, distances = {} }
	local instances = 0
	if config.Mode == "Cable" then
		local count = math.ceil(path.length / config.SegmentLength)
		assert(count <= 512, "More than 512 segments. Increase segment length.")
		for i = 0, count do table.insert(plan.distances, path.length * i / count) end
		-- Reject coincident chord endpoints during planning, before allocating output/history.
		for i = 2, #plan.distances do
			assert((Curve.at(path, plan.distances[i]) - Curve.at(path, plan.distances[i - 1])).Magnitude >= 0.001,
				"Degenerate segment. Adjust control points or density.")
		end
	else
		local _; _, instances = sourceParts(source)
		plan.sourcePivot = source:GetPivot()
		plan.rotation = rotation or (Curve.frame(path, 0).Rotation:Inverse() * plan.sourcePivot.Rotation)
		finiteFrame(plan.rotation)
		if config.Distribution == "Count" then
			for i = 1, config.Count do
				local t = if config.Endpoints then (i - 1) / (config.Count - 1) else i / (config.Count + 1)
				table.insert(plan.distances, path.length * t)
			end
		else
			local count = math.floor(path.length / config.Spacing)
			assert(count <= 500, "More than 500 copies. Increase spacing.")
			if config.Endpoints then table.insert(plan.distances, 0) end
			for i = 1, count do
				if i * config.Spacing < path.length - 1e-5 then table.insert(plan.distances, i * config.Spacing) end
			end
			if config.Endpoints then table.insert(plan.distances, path.length) end
		end
		assert(#plan.distances > 0 and #plan.distances <= 500, "Spacing produces no copies or exceeds 500 copies.")
		assert(instances * #plan.distances <= 5000, "Output exceeds 5000 instances. Reduce copies or source complexity.")
	end
	local count = #plan.distances - (config.Mode == "Cable" and 1 or 0)
	plan.estimates = { pathLength = path.length, sampleCount = #path.positions, sourceInstanceCount = instances,
		segmentCount = config.Mode == "Cable" and count or 0, copyCount = config.Mode == "Repeat" and count or 0,
		outputInstanceCount = config.Mode == "Cable" and (2 * count - 1) or instances * count }
	-- Exact typed snapshots avoid hash collisions and preserve instance identity even for duplicate names.
	fingerprints[plan] = { inputControls = controls, controls = controlState, inputSettings = settings,
		settings = table.clone(config), source = source, sourceState = config.Mode == "Repeat" and sourceSnapshot(source) or nil,
		pivot = plan.sourcePivot, rotation = plan.rotation, distances = table.clone(plan.distances), path = path }
	return plan
end

function Engine.check(plan)
	assert(not plan.used, "Preview again before building.")
	local saved = assert(fingerprints[plan], "Unknown preview. Preview again.")
	assert(sameValues(saved.settings, Settings.validate(saved.inputSettings)) and sameValues(saved.settings, plan.settings), "Settings changed. Preview again.")
	assert(#saved.controls == #plan.controls and #saved.controls == #saved.inputControls, "Control order changed. Preview again.")
	for i, record in ipairs(saved.controls) do
		local part = record.part
		assert(plan.controls[i] == part and saved.inputControls[i] == part and part:IsDescendantOf(workspace) and part.Parent == record.parent,
			"Control order or hierarchy changed. Preview again.")
		assert(if saved.settings.ControlRoll then part.CFrame == record.cframe else part.Position == record.cframe.Position,
			"Control points changed. Preview again.")
	end
	assert(plan.path == saved.path and sameValues(plan.distances, saved.distances) and plan.rotation == saved.rotation and plan.source == saved.source,
		"Preview plan changed. Preview again.")
	if plan.settings.Mode == "Repeat" then
		sourceParts(plan.source)
		assert(plan.source:GetPivot() == saved.pivot and plan.sourcePivot == saved.pivot and sameSource(saved.sourceState, sourceSnapshot(plan.source)),
			"Source changed. Preview again.")
	end
end

function Engine.output(plan)
	local output = Instance.new("Model"); output.Name = "Output"
	local ok, err = pcall(function()
		local s = plan.settings
		if s.Mode == "Cable" then
			local function part(name, shape, size, cf)
				local p = Instance.new("Part")
				p.Name, p.Shape, p.Size, p.CFrame = name, shape, size, cf
				p.Color, p.Material = s.Color, Enum.Material[s.Material]
				p.Anchored, p.CanCollide, p.CastShadow = s.Anchored, s.CanCollide, s.CastShadow
				p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
				p.Parent = output
			end
			for i = 2, #plan.distances do
				local a, b = Curve.at(plan.path, plan.distances[i - 1]), Curve.at(plan.path, plan.distances[i])
				assert((b - a).Magnitude >= 0.001, "Degenerate segment. Adjust control points or density.")
				local direction = (b - a).Unit
				local up = Curve.frame(plan.path, (plan.distances[i - 1] + plan.distances[i]) / 2).UpVector
				if math.abs(up:Dot(direction)) > 0.999 then up = Curve.frame(plan.path, plan.distances[i - 1]).RightVector end
				part(string.format("Segment%03d", i - 1), Enum.PartType.Cylinder, Vector3.new((b - a).Magnitude, s.Diameter, s.Diameter), CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0))
				if i < #plan.distances then part(string.format("Joint%03d", i - 1), Enum.PartType.Ball, Vector3.one * s.Diameter, CFrame.new(b)) end
			end
		else
			for i, distance in ipairs(plan.distances) do
				local clone = plan.source:Clone()
				clone.Name = string.format("Copy%03d", i); clone.Parent = output
				local cf = Curve.frame(plan.path, distance)
				if s.Orient then
					if s.PreserveRotation then cf *= plan.rotation end
				else cf = CFrame.new(cf.Position) * plan.sourcePivot.Rotation end
				clone:PivotTo(cf)
			end
		end
	end)
	if not ok then output:Destroy(); error(err) end
	return output
end

function Engine.metadata(plan)
	local data = Instance.new("Folder"); data.Name = "CurveForgeData"
	data:SetAttribute("Version", 2)
	for key, value in pairs(plan.settings) do data:SetAttribute(key, value) end
	data:SetAttribute("RotationOffset", plan.rotation or CFrame.identity)
	for i, control in ipairs(plan.controls) do
		local ref = Instance.new("ObjectValue"); ref.Name = tostring(i); ref.Value = control; ref.Parent = data
	end
	local source = Instance.new("ObjectValue"); source.Name = "Source"; source.Value = plan.source; source.Parent = data
	return data
end

function Engine.load(model)
	assert(model and model:IsA("Model") and model:IsDescendantOf(workspace), "Select one generated CurveForge Model.")
	local data, output = model:FindFirstChild("CurveForgeData"), model:FindFirstChild("Output")
	assert(data and data:IsA("Folder") and (data:GetAttribute("Version") == 1 or data:GetAttribute("Version") == 2) and output and output:IsA("Model"), "Not a supported CurveForge model.")
	local names = {}
	for _, item in ipairs(model:GetChildren()) do
		if item.Name == "CurveForgeData" or item.Name == "Output" then assert(not names[item.Name], "Ambiguous generated metadata/output."); names[item.Name] = true end
	end
	local controls, settings = {}, {}
	for key in pairs(Settings.defaults) do settings[key] = data:GetAttribute(key) end
	if data:GetAttribute("Version") == 1 then settings.ControlRoll = false
	else assert(typeof(settings.ControlRoll) == "boolean", "Missing V2 roll setting.") end
	local refs = {}
	for _, ref in ipairs(data:GetChildren()) do
		assert(not refs[ref.Name] and ref:IsA("ObjectValue"), "Invalid or duplicate metadata reference.")
		assert(ref.Name == "Source" or table.find({ "1", "2", "3", "4", "5", "6", "7", "8" }, ref.Name), "Unknown metadata reference.")
		refs[ref.Name] = ref
	end
	local gap = false
	for i = 1, 8 do
		local ref = refs[tostring(i)]
		if ref then assert(not gap and ref.Value, "A saved control point was deleted or order is malformed."); table.insert(controls, ref.Value)
		else gap = true end
	end
	local source = data:FindFirstChild("Source")
	assert(source and source:IsA("ObjectValue"), "Invalid source metadata.")
	local rotation = data:GetAttribute("RotationOffset")
	finiteFrame(rotation)
	local plan = Engine.plan(controls, settings, source.Value, rotation)
	return plan, data, output
end

function Engine.apply(plan, history, target)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before building.")
	Engine.check(plan)
	local oldData, oldOutput
	if target then
		local _; _, oldData, oldOutput = Engine.load(target)
		for _, p in ipairs(plan.controls) do assert(not p:IsDescendantOf(target), "Control points cannot be inside the output being replaced.") end
		assert(not plan.source or (plan.source ~= target and not plan.source:IsDescendantOf(target)), "Source cannot be inside the output being replaced.")
	end
	local output, data, id
	local prepared, preparationError = pcall(function()
		output = Engine.output(plan); data = Engine.metadata(plan)
		id = history:TryBeginRecording("CurveForge", if target then "Regenerate CurveForge" else "Build CurveForge")
		assert(id, "Undo recording unavailable. Finish the other operation and retry.")
		Engine.check(plan)
		if target then
			assert(target:IsDescendantOf(workspace) and oldOutput.Parent == target and oldData.Parent == target
				and target:FindFirstChild("Output") == oldOutput and target:FindFirstChild("CurveForgeData") == oldData, "Target changed. Preview again.")
		end
	end)
	if not prepared then
		if output then output:Destroy() end; if data then data:Destroy() end
		if id then pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end) end
		error(preparationError)
	end
	local model = target or Instance.new("Model")
	local ok, err = pcall(function()
		if not target then model.Name = "CurveForge_" .. plan.settings.Mode end
		if oldOutput then oldOutput.Parent = nil; oldData.Parent = nil end
		output.Parent, data.Parent = model, model
		if not target then model.Parent = workspace end
		history:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then
		output:Destroy(); data:Destroy()
		if target then oldOutput.Parent, oldData.Parent = target, target else model:Destroy() end
		pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end)
		error(err)
	end
	plan.used = true
	return model
end

function Engine.newPath(history, origin)
	assert(not game:GetService("RunService"):IsRunning(), "Stop simulation before editing.")
	local id = history:TryBeginRecording("CurveForgeMarkers", "New CurveForge path")
	assert(id, "Undo recording unavailable.")
	local folder, controls = Instance.new("Folder"), {}
	folder.Name = "CurveForge_Controls"
	local ok, err = pcall(function()
		for i, offset in ipairs({ Vector3.new(-12, 0, 0), Vector3.new(-4, 3, 0), Vector3.new(4, 3, 4), Vector3.new(12, 0, 4) }) do
			local p = Instance.new("Part"); p.Name = string.format("Point%02d", i); p.Shape = Enum.PartType.Ball
			p.Size, p.Position = Vector3.one * 0.8, origin + offset
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, true, false
			p.Color, p.Transparency = Color3.fromRGB(251, 199, 77), 0.4; p.Parent = folder
			table.insert(controls, p)
		end
		folder.Parent = workspace
		history:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
	end)
	if not ok then folder:Destroy(); pcall(function() history:FinishRecording(id, Enum.FinishRecordingOperation.Cancel) end); error(err) end
	return controls
end

return Engine
