return function(modules, legacyModules)
	local Curve, Engine, Settings = require(modules.Curve), require(modules.Engine), require(modules.Settings)
	local history = game:GetService("ChangeHistoryService")
	local passed, failed, fixture, outputs = 0, 0, nil, {}
	local fixtures = {
		straight = { Vector3.zero, Vector3.new(20, 0, 0) },
		scurve = { Vector3.zero, Vector3.new(6, 0, 8), Vector3.new(12, 0, -8), Vector3.new(20, 0, 0) },
		vertical = { Vector3.zero, Vector3.new(0, 10, 0), Vector3.new(2, 20, 0), Vector3.new(14, 22, 0) },
		spatial = { Vector3.zero, Vector3.new(8, 10, 0), Vector3.new(2, 20, 8), Vector3.new(-8, 30, 2), Vector3.new(0, 40, -8), Vector3.new(8, 50, 0) },
		threshold = { Vector3.zero, Vector3.new(1, 10, 0), Vector3.new(4, 20, 0), Vector3.new(5, 30, 2) },
		gentle = { Vector3.zero, Vector3.new(1800, 20, 10), Vector3.new(3600, -20, -10), Vector3.new(5400, 0, 0) },
		tight = { Vector3.zero, Vector3.new(0.2, 0, 0.8), Vector3.new(0.4, 0, -0.8), Vector3.new(0.8, 0, 0) },
	}
	local function test(name, fn)
		fixture = Instance.new("Folder"); fixture.Name = "CurveForgeV11Fixture"; fixture.Parent = workspace
		local ok, err = xpcall(fn, debug.traceback)
		if ok then passed += 1; print("[CurveForgeV11][PASS] " .. name)
		else failed += 1; warn("[CurveForgeV11][FAIL] " .. name .. ": " .. tostring(err)) end
		for _, item in ipairs(outputs) do item:Destroy() end; outputs = {}; fixture:Destroy()
	end
	local function config(values)
		local s = table.clone(Settings.defaults); for k, v in pairs(values or {}) do s[k] = v end; return s
	end
	local function part(pos, parent, name)
		local p = Instance.new("Part"); p.Name = name or "Part"; p.Anchored = true; p.Position = pos; p.Parent = parent or fixture; return p
	end
	local function controls(points)
		local c = {}; for i, position in ipairs(points or fixtures.straight) do table.insert(c, part(position, fixture, "Control" .. i)) end; return c
	end
	local function source()
		local m = Instance.new("Model"); m.Name = "Source"; m.Parent = fixture
		local a = part(Vector3.new(60, 5, 10), m, "Primary"); a.Size = Vector3.new(1, 2, 3); a.CFrame *= CFrame.Angles(0.3, 0.5, 0.2)
		local b = part(Vector3.new(62, 7, 10), m, "Child"); b.Size = Vector3.new(2, 1, 1)
		m.PrimaryPart = a; return m
	end
	local function reject(fn) assert(not pcall(fn), "Expected rejection") end
	local function apply(plan, target)
		history:SetWaypoint("CurveForge V11 fixture baseline")
		local m = Engine.apply(plan, history, target); if not target then table.insert(outputs, m) end; return m
	end
	local function snapshot(model)
		local state = {}
		for _, item in ipairs(model:GetDescendants()) do
			if item:IsA("BasePart") then state[item:GetFullName()] = { item.CFrame, item.Size } end
		end
		return state
	end
	local function sameGeometry(a, b)
		for key, value in pairs(a) do assert(b[key] and value[1]:FuzzyEq(b[key][1], 1e-4) and value[2] == b[key][2], key) end
		for key in pairs(b) do assert(a[key], key) end
	end
	local function stable(path)
		local before = Curve.frame(path, 0)
		for i = 1, 800 do
			local cf = Curve.frame(path, path.length * i / 800)
			assert(cf.Position.X == cf.Position.X and math.abs(cf.UpVector:Dot(cf.LookVector)) < 1e-4)
			local _, angle = before.Rotation:ToObjectSpace(cf.Rotation):ToAxisAngle()
			assert(math.abs(angle) < 0.45, "Discontinuous consecutive frame: " .. angle)
			before = cf
		end
		assert((before.Position - path.positions[#path.positions]).Magnitude < 1e-4)
		assert(before:FuzzyEq(Curve.frame(path, path.length), 1e-6))
	end
	for _, key in ipairs({ "straight", "scurve", "vertical", "spatial", "threshold" }) do
		test("Stable continuous frames / " .. key, function() stable(Curve.sample(fixtures[key])) end)
	end
	test("Pure vertical endpoints and no world-up threshold roll flip", function()
		local path = Curve.sample({ Vector3.zero, Vector3.new(0, 20, 0) }); stable(path)
		assert(Curve.frame(path, 0).LookVector:Dot(Vector3.yAxis) > 0.999)
		local p = Curve.sample(fixtures.threshold); local last = Curve.frame(p, 0)
		for i = 1, 500 do local cf = Curve.frame(p, p.length * i / 500); assert(last.UpVector:Dot(cf.UpVector) > 0.98); last = cf end
	end)
	test("Roll off preserves planar V1 reference and ignores control rotation", function()
		local c = controls(fixtures.scurve); local p = Engine.plan(c, config({ SegmentLength = 5 }))
		local before = Curve.frame(p.path, p.path.length * 0.3)
		c[2].CFrame *= CFrame.Angles(0.3, 0.8, 0.4); Engine.check(p)
		local nextPlan = Engine.plan(c, config({ SegmentLength = 5 }))
		assert(before:FuzzyEq(Curve.frame(nextPlan.path, nextPlan.path.length * 0.3), 1e-5))
		assert(before.UpVector:Dot(Vector3.yAxis) > 0.999)
	end)
	test("Roll on interpolates guides smoothly without moving path", function()
		local c = controls(); c[1].CFrame = CFrame.new(c[1].Position); c[2].CFrame = CFrame.new(c[2].Position) * CFrame.Angles(math.pi / 2, 0, 0)
		local plain = Engine.plan(c, config()); local rolled = Engine.plan(c, config({ ControlRoll = true }))
		stable(rolled.path)
		for i = 0, 20 do assert(Curve.at(plain.path, i) == Curve.at(rolled.path, i)) end
		assert(Curve.frame(rolled.path, 0).UpVector:Dot(Vector3.yAxis) > 0.999)
		assert(Curve.frame(rolled.path, 20).UpVector:Dot(Vector3.zAxis) > 0.999)
		assert(Curve.frame(rolled.path, 10).UpVector:Dot((Vector3.yAxis + Vector3.zAxis).Unit) > 0.999)
	end)
	test("Parallel roll guide fallback is finite and deterministic", function()
		local p = Curve.sample(fixtures.straight, { Vector3.xAxis, Vector3.xAxis }); stable(p)
	end)
	test("Half-turn roll guides interpolate without a discontinuous flip", function()
		local p = Curve.sample(fixtures.straight, { Vector3.yAxis, -Vector3.yAxis }); stable(p)
		assert(Curve.frame(p, p.length).UpVector:Dot(-Vector3.yAxis) > 0.999)
	end)
	local function reference(points, steps)
		local p = { positions = { points[1] }, lengths = { 0 }, length = 0 }
		for i = 1, #points - 1 do
			local b, c = points[i], points[i + 1]; local a, d = points[i - 1] or (2 * b - c), points[i + 2] or (2 * c - b)
			for j = 1, steps do
				local t = j / steps
				local v = 0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t^2 + (-a + 3 * b - 3 * c + d) * t^3)
				local distance = (v - p.positions[#p.positions]).Magnitude
				if distance > 1e-8 then p.length += distance; table.insert(p.positions, v); table.insert(p.lengths, p.length) end
			end
		end
		return p
	end
	for _, key in ipairs({ "straight", "gentle", "tight", "spatial" }) do
		test("Adaptive accuracy / old fixed comparison / " .. key, function()
			local points = fixtures[key]; local p = Curve.sample(points); local again = Curve.sample(points)
			assert(p.length == again.length and #p.positions == #again.positions and #p.positions <= Curve.MAX_SAMPLES)
			assert(p.positions[1] == points[1] and p.positions[#p.positions] == points[#points])
			if key == "straight" then assert(#p.positions == 2 and p.length == 20) end
			local old, dense = reference(points, 64), reference(points, 4096)
			local error, oldError = 0, 0
			for i = 0, 500 do
				local fraction = i / 500; local wanted = Curve.at(dense, dense.length * fraction)
				error = math.max(error, (Curve.at(p, p.length * fraction) - wanted).Magnitude)
				oldError = math.max(oldError, (Curve.at(old, old.length * fraction) - wanted).Magnitude)
			end
			print(string.format("[CurveForgeV11][MEASURE] %s samples=%d oldSamples=%d length=%.9f referenceLength=%.9f maxPositionError=%.9f oldError=%.9f", key, #p.positions, #old.positions, p.length, dense.length, error, oldError))
			assert(error <= 0.02, "Arc-position error > 0.02 studs: " .. error)
			assert(math.abs(p.length - dense.length) <= math.max(0.001, dense.length * 0.0001), "Length error > 0.01%")
		end)
	end
	test("Eight controls and translated valid paths remain bounded", function()
		local points = {}
		for i = 1, 8 do points[i] = Vector3.new(i * 20, math.sin(i) * 10, math.cos(i) * 10) end
		local origin = Vector3.new(50000, 100, 50000)
		local shifted = {}; for i, point in ipairs(points) do shifted[i] = point + origin end
		local a, b = Curve.sample(points), Curve.sample(shifted)
		assert(#a.positions <= Curve.MAX_SAMPLES and #b.positions <= Curve.MAX_SAMPLES)
		assert(b.positions[1] == shifted[1] and b.positions[#b.positions] == shifted[8])
		assert(math.abs(a.length - b.length) < 0.1)
	end)
	local function cable(points, diameter, segmentLength)
		local p = Engine.plan(controls(points), config({ Diameter = diameter, SegmentLength = segmentLength, Material = "Metal", Anchored = false, CanCollide = true, CastShadow = false }))
		local before = #workspace:GetDescendants(); local out = Engine.output(p); table.insert(outputs, out)
		assert(out.Parent == nil and #workspace:GetDescendants() == before)
		assert(#out:GetDescendants() == p.estimates.outputInstanceCount)
		for i = 1, p.estimates.segmentCount do
			local segment = out:FindFirstChild(string.format("Segment%03d", i))
			local a, b = Curve.at(p.path, p.distances[i]), Curve.at(p.path, p.distances[i + 1])
			local tip1 = segment.CFrame:PointToWorldSpace(Vector3.new(segment.Size.X / 2, 0, 0))
			local tip2 = segment.CFrame:PointToWorldSpace(Vector3.new(-segment.Size.X / 2, 0, 0))
			assert(math.min((tip1 - a).Magnitude, (tip2 - a).Magnitude) < 0.001)
			assert(math.min((tip1 - b).Magnitude, (tip2 - b).Magnitude) < 0.001)
			assert(segment.Size.X >= 0.001 and math.abs(segment.Size.Y - diameter) < 1e-5)
			assert(math.abs(segment.CFrame.RightVector:Dot((b - a).Unit)) > 0.9999)
			assert(segment.Color == p.settings.Color and segment.Material == Enum.Material.Metal and not segment.Anchored and segment.CanCollide and not segment.CastShadow)
			if i < p.estimates.segmentCount then local joint = out:FindFirstChild(string.format("Joint%03d", i)); assert((joint.Position - b).Magnitude < 0.001 and joint.Shape == Enum.PartType.Ball and math.abs(joint.Size.X - diameter) < 1e-5) end
		end
	end
	for _, key in ipairs({ "straight", "scurve", "vertical", "spatial" }) do test("Cable closed shared endpoints / " .. key, function() cable(fixtures[key], 0.4, 0.5) end) end
	test("Cable diameter extremes and short segment", function() cable(fixtures.tight, 50, 0.1); cable(fixtures.scurve, 0.05, 0.3) end)
	test("Repeat Count, endpoints, Orient, local offset, source and scale", function()
		local c, src = controls(fixtures.spatial), source(); local initial = snapshot(src)
		for _, endpoints in ipairs({ true, false }) do
			for _, orient in ipairs({ true, false }) do
				for _, preserve in ipairs({ true, false }) do
					local p = Engine.plan(c, config({ Mode = "Repeat", Distribution = "Count", Count = 7, Endpoints = endpoints, Orient = orient, PreserveRotation = preserve }), src)
					local out = Engine.output(p); table.insert(outputs, out); assert(#out:GetChildren() == 7)
					assert(p.estimates.copyCount == 7 and p.estimates.sourceInstanceCount == 3 and p.estimates.outputInstanceCount == #out:GetDescendants())
					assert((endpoints and p.distances[1] == 0 and p.distances[7] == p.path.length) or (not endpoints and p.distances[1] > 0 and p.distances[7] < p.path.length))
					for i, distance in ipairs(p.distances) do
						local copy = out:FindFirstChild(string.format("Copy%03d", i)); local frame = Curve.frame(p.path, distance)
						local rotation = if not orient then src:GetPivot().Rotation elseif preserve then frame.Rotation * p.rotation else frame.Rotation
						assert(copy:GetPivot():FuzzyEq(CFrame.new(frame.Position) * rotation, 1e-4) and copy:GetScale() == src:GetScale())
						assert(copy.Primary.Size == src.Primary.Size and copy.Child.Size == src.Child.Size)
					end
				end
			end
		end
		sameGeometry(initial, snapshot(src))
	end)
	test("Repeat Spacing deterministic; explicit endpoint remainder", function()
		local c, src = controls(), source()
		for _, endpoints in ipairs({ true, false }) do
			local s = config({ Mode = "Repeat", Spacing = 6, Endpoints = endpoints }); local p = Engine.plan(c, s, src); local again = Engine.plan(c, s, src)
			assert(#p.distances == (endpoints and 5 or 3))
			for i, distance in ipairs(p.distances) do assert(distance == again.distances[i]); if i > 1 and i < #p.distances then assert(distance - p.distances[i - 1] == 6) end end
			if endpoints then assert(p.distances[5] - p.distances[4] == 2) end
		end
	end)
	test("Actual 3D repeated copies have uniform reference arc spacing", function()
		local c, src = controls(fixtures.spatial), source()
		local p = Engine.plan(c, config({ Mode = "Repeat", Spacing = 2.5, Endpoints = false }), src)
		local out = Engine.output(p); table.insert(outputs, out)
		local dense = reference(fixtures.spatial, 4096)
		local previous, error = nil, 0
		for i in ipairs(p.distances) do
			local position = out:FindFirstChild(string.format("Copy%03d", i)):GetPivot().Position
			local closest, arc = math.huge, 0
			for k = 2, #dense.positions do
				local a, delta = dense.positions[k - 1], dense.positions[k] - dense.positions[k - 1]
				local t = math.clamp((position - a):Dot(delta) / delta:Dot(delta), 0, 1)
				local separation = (position - a - delta * t).Magnitude
				if separation < closest then closest, arc = separation, dense.lengths[k - 1] + delta.Magnitude * t end
			end
			if previous then error = math.max(error, math.abs(arc - previous - 2.5)) end
			previous = arc
		end
		print(string.format("[CurveForgeV11][MEASURE] actualCopies=%d spacing=2.5 maxReferenceArcStepError=%.9f", #p.distances, error))
		assert(error <= 0.01, "Nonuniform actual copy arc spacing")
	end)
	test("Repeated Edit Existing / Regenerate has no cumulative drift", function()
		local c, src = controls(fixtures.spatial), source(); local initial = snapshot(src)
		local model = apply(Engine.plan(c, config({ Mode = "Repeat", Distribution = "Count", Count = 8, ControlRoll = true }), src))
		local expected = snapshot(model.Output); local rotation = model.CurveForgeData:GetAttribute("RotationOffset")
		for _ = 1, 6 do apply(Engine.load(model), model); sameGeometry(expected, snapshot(model.Output)); assert(model.CurveForgeData:GetAttribute("RotationOffset") == rotation) end
		sameGeometry(initial, snapshot(src))
	end)
	local changes = {
		{ "internal move with unchanged pivot", function(src) src.Child.Position += Vector3.xAxis end },
		{ "resize", function(src) src.Child.Size += Vector3.one end },
		{ "add descendant", function(src) Instance.new("Folder").Parent = src end },
		{ "remove descendant", function(src) src.Child:Destroy() end },
		{ "rename descendant", function(src) src.Child.Name = "ChangedName" end },
		{ "reparent descendant", function(src) src.Child.Parent = fixture end },
		{ "reparent root", function(src) local folder = Instance.new("Folder"); folder.Parent = fixture; src.Parent = folder end },
		{ "delete source", function(src) src:Destroy() end },
		{ "source pivot", function(src) src:PivotTo(src:GetPivot() * CFrame.new(1, 0, 0)) end },
		{ "source attributes", function(src) src.Child:SetAttribute("Changed", true) end },
	}
	for _, entry in ipairs(changes) do
		test("Stale source / " .. entry[1], function()
			local c, src = controls(), source(); local p = Engine.plan(c, config({ Mode = "Repeat", Count = 2, Distribution = "Count" }), src)
			local pivot = src:GetPivot(); entry[2](src)
			if entry[1] == "internal move with unchanged pivot" then assert(pivot == src:GetPivot()) end
			local before = #workspace:GetDescendants(); reject(function() Engine.apply(p, history) end); assert(#workspace:GetDescendants() == before)
		end)
	end
	test("Control order/count/deletion/rotation and settings stale rules", function()
		local c = controls(); local s = config(); local p = Engine.plan(c, s)
		c[1], c[2] = c[2], c[1]; reject(function() Engine.check(p) end); c[1], c[2] = c[2], c[1]
		p = Engine.plan(c, s); s.Diameter = 2; reject(function() Engine.check(p) end)
		p = Engine.plan(c, s); p.settings.SegmentLength = 9; reject(function() Engine.check(p) end)
		p = Engine.plan(c, s); c[1].CFrame *= CFrame.Angles(0.2, 0, 0); Engine.check(p)
		s.ControlRoll = true; p = Engine.plan(c, s); c[1].CFrame *= CFrame.Angles(0.2, 0, 0); reject(function() Engine.check(p) end)
		p = Engine.plan(c, s); table.remove(c); reject(function() Engine.check(p) end)
		c = controls(); p = Engine.plan(c, s); c[1]:Destroy(); reject(function() Engine.apply(p, history) end)
	end)
	test("Actual V1 binary metadata loads and regenerates to V2", function()
		local old = require(legacyModules.Engine); local oldSettings = table.clone(require(legacyModules.Settings).defaults)
		oldSettings.Mode, oldSettings.Distribution, oldSettings.Count = "Repeat", "Count", 3
		local c, src = controls(), source(); history:SetWaypoint("V1 fixture")
		local model = old.apply(old.plan(c, oldSettings, src), history); table.insert(outputs, model)
		assert(model.CurveForgeData:GetAttribute("Version") == 1)
		local p = Engine.load(model); assert(p.settings.ControlRoll == false)
		local oldOutput, oldData = model.Output, model.CurveForgeData
		apply(p, model); assert(model.CurveForgeData:GetAttribute("Version") == 2 and #model.Output:GetChildren() == 3)
		history:Undo(); task.wait(); assert(model.Output == oldOutput and model.CurveForgeData == oldData)
		history:Redo(); task.wait(); assert(model.CurveForgeData:GetAttribute("Version") == 2)
	end)
	test("Actual V1 curved Cable migrates with roll off and user additions intact", function()
		local old = require(legacyModules.Engine); local c = controls(fixtures.spatial)
		history:SetWaypoint("V1 Cable fixture")
		local model = old.apply(old.plan(c, table.clone(require(legacyModules.Settings).defaults)), history); table.insert(outputs, model)
		local addition = Instance.new("Folder"); addition.Name = "UserAddition"; addition.Parent = model
		local p = Engine.load(model); assert(p.settings.Mode == "Cable" and p.settings.ControlRoll == false)
		apply(p, model); assert(model.CurveForgeData:GetAttribute("Version") == 2 and addition.Parent == model)
		local again = Engine.load(model); assert(again.settings.ControlRoll == false and #again.controls == #c)
	end)
	test("Malformed metadata fails safely", function()
		local model = apply(Engine.plan(controls(), config())); local data = model.CurveForgeData
		data:SetAttribute("ControlRoll", nil); reject(function() Engine.load(model) end); data:SetAttribute("ControlRoll", false)
		data:SetAttribute("RotationOffset", CFrame.new(1, 0, 0)); reject(function() Engine.load(model) end); data:SetAttribute("RotationOffset", CFrame.identity)
		local duplicate = data["1"]:Clone(); duplicate.Parent = data; reject(function() Engine.load(model) end); duplicate:Destroy()
		data["2"].Name = "3"; reject(function() Engine.load(model) end)
	end)
	test("Hard limits before mutation and correct boundary estimates", function()
		local c = controls({ Vector3.zero, Vector3.new(512, 0, 0) }); local p = Engine.plan(c, config())
		assert(p.estimates.segmentCount == 512 and p.estimates.outputInstanceCount == 1023 and p.estimates.sampleCount == 2)
		c[2].Position = Vector3.new(513, 0, 0); reject(function() Engine.plan(c, config()) end)
		local src = source(); local before = #workspace:GetDescendants()
		reject(function() Engine.plan(c, config({ Mode = "Repeat", Count = 501, Distribution = "Count" }), src) end)
		reject(function() Engine.plan(c, config({ Mode = "Repeat", Spacing = 0.1 }), src) end)
		for i = 1, 7 do local v = Instance.new("Folder"); v.Parent = src end
		local allowed = Engine.plan(c, config({ Mode = "Repeat", Count = 500, Distribution = "Count" }), src)
		assert(allowed.estimates.outputInstanceCount == 5000)
		Instance.new("Folder").Parent = src; reject(function() Engine.plan(c, config({ Mode = "Repeat", Count = 500, Distribution = "Count" }), src) end)
		for _ = 1, 990 do Instance.new("Folder").Parent = src end
		reject(function() Engine.plan(c, config({ Mode = "Repeat", Count = 2, Distribution = "Count" }), src) end)
		assert(#workspace:GetDescendants() == before + 998)
	end)
	test("Build and Regenerate native history preserve exact output and user additions", function()
		local c = controls(fixtures.scurve); local before = #workspace:GetDescendants()
		local model = apply(Engine.plan(c, config())); local original = snapshot(model.Output)
		history:Undo(); task.wait(); assert(model.Parent == nil and #workspace:GetDescendants() == before)
		history:Redo(); task.wait(); sameGeometry(original, snapshot(model.Output))
		local addition = Instance.new("Folder"); addition.Name = "UserAddition"; addition.Parent = model
		local oldOutput, oldData = model.Output, model.CurveForgeData
		local p = Engine.load(model); local nextSettings = table.clone(p.settings); nextSettings.Diameter = 2
		apply(Engine.plan(p.controls, nextSettings), model); local replaced = model.Output
		assert(addition.Parent == model and oldOutput.Parent == nil)
		history:Undo(); task.wait(); assert(model.Output == oldOutput and model.CurveForgeData == oldData and addition.Parent == model)
		history:Redo(); task.wait(); assert(model.Output == replaced and addition.Parent == model)
	end)
	test("Recording refusal/throw, commit rollback and reentrant stale input", function()
		local c = controls(); local model = apply(Engine.plan(c, config())); local oldOutput, oldData = model.Output, model.CurveForgeData
		local sibling = Instance.new("Folder"); sibling.Name = "User"; sibling.Parent = model
		local before = #workspace:GetDescendants()
		local bad = { TryBeginRecording = function() return "Injected" end, FinishRecording = function(_, _, op) if op == Enum.FinishRecordingOperation.Commit then error("Injected commit failure") end end }
		reject(function() Engine.apply(Engine.plan(c, config()), bad, model) end)
		assert(model.Output == oldOutput and model.CurveForgeData == oldData and sibling.Parent == model and #workspace:GetDescendants() == before)
		reject(function() Engine.apply(Engine.plan(c, config()), bad) end); assert(#workspace:GetDescendants() == before)
		for _, begin in ipairs({ function() return nil end, function() error("Injected begin failure") end }) do reject(function() Engine.apply(Engine.plan(c, config()), { TryBeginRecording = begin }) end); assert(#workspace:GetDescendants() == before) end
		local committed = false
		local changed = { TryBeginRecording = function() c[1].Position += Vector3.yAxis; return "Changed" end, FinishRecording = function(_, _, op) committed = op == Enum.FinishRecordingOperation.Commit end }
		reject(function() Engine.apply(Engine.plan(c, config()), changed, model) end); assert(not committed and model.Output == oldOutput and #workspace:GetDescendants() == before)
	end)
	test("Controls or source inside replaced output are rejected", function()
		local c = controls(); local model = apply(Engine.plan(c, config())); c[1].Parent = model.Output
		reject(function() Engine.apply(Engine.plan(c, config()), history, model) end); c[1].Parent = fixture
		local src = model.Output:FindFirstChildWhichIsA("BasePart")
		reject(function() Engine.apply(Engine.plan(c, config({ Mode = "Repeat", Distribution = "Count", Count = 2 }), src), history, model) end)
	end)
	print(string.format("[CurveForgeV11][SUMMARY] %d PASS / %d FAIL", passed, failed))
	return failed == 0
end
