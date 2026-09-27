local Curve = require(script.Parent.Curve)
local Settings = require(script.Parent.Settings)
local Engine = {}

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
	local config, positions, seen = Settings.validate(settings), {}, {}
	assert(#controls >= 2 and #controls <= 8, "Assign 2 to 8 ordered BaseParts.")
	for _, part in ipairs(controls) do
		assert(typeof(part) == "Instance" and part:IsA("BasePart") and part:IsDescendantOf(workspace), "A control point is invalid or was deleted.")
		assert(not seen[part], "Duplicate control point."); seen[part] = true
		table.insert(positions, part.Position)
	end
	local path = Curve.sample(positions)
	local plan = { controls = table.clone(controls), positions = positions, settings = config, path = path, source = source, distances = {} }
	if config.Mode == "Cable" then
		local count = math.ceil(path.length / config.SegmentLength)
		assert(count <= 512, "More than 512 segments. Increase segment length.")
		for i = 0, count do table.insert(plan.distances, path.length * i / count) end
	else
		local _, instances = sourceParts(source)
		plan.sourcePivot = source:GetPivot()
		plan.rotation = rotation or (Curve.frame(path, 0).Rotation:Inverse() * plan.sourcePivot.Rotation)
		assert(typeof(plan.rotation) == "CFrame", "Invalid rotation metadata.")
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
	return plan
end

function Engine.check(plan)
	assert(not plan.used, "Preview again before building.")
	for i, part in ipairs(plan.controls) do
		assert(part:IsDescendantOf(workspace) and part.Position == plan.positions[i], "Control points changed. Preview again.")
	end
	if plan.settings.Mode == "Repeat" then sourceParts(plan.source); assert(plan.source:GetPivot() == plan.sourcePivot, "Source moved. Preview again.") end
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
				local up = if math.abs(direction:Dot(Vector3.yAxis)) > 0.98 then Vector3.zAxis else Vector3.yAxis
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
	data:SetAttribute("Version", 1)
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
	assert(data and data:IsA("Folder") and data:GetAttribute("Version") == 1 and output and output:IsA("Model"), "Not a supported CurveForge model.")
	local controls, settings = {}, {}
	for key in pairs(Settings.defaults) do settings[key] = data:GetAttribute(key) end
	for i = 1, 8 do
		local ref = data:FindFirstChild(tostring(i))
		if ref then assert(ref:IsA("ObjectValue") and ref.Value, "A saved control point was deleted."); table.insert(controls, ref.Value) end
	end
	local source = data:FindFirstChild("Source")
	assert(source and source:IsA("ObjectValue"), "Invalid source metadata.")
	local rotation = data:GetAttribute("RotationOffset")
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
		assert(not plan.source or not plan.source:IsDescendantOf(target), "Source cannot be inside the output being replaced.")
	end
	local output, data = Engine.output(plan), Engine.metadata(plan)
	local id = history:TryBeginRecording("CurveForge", if target then "Regenerate CurveForge" else "Build CurveForge")
	if not id then output:Destroy(); data:Destroy(); error("Undo recording unavailable. Finish the other operation and retry.") end
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
