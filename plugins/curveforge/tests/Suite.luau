return function(modules)
	local Engine, Curve, Settings = require(modules.Engine), require(modules.Curve), require(modules.Settings)
	local history = game:GetService("ChangeHistoryService")
	assert(not game:GetService("RunService"):IsRunning(), "Execute in edit mode.")
	local passed, failed, fixture, generated = 0, 0, nil, {}
	local function part(position, name)
		local p = Instance.new("Part"); p.Name = name or "Control"; p.Position = position; p.Anchored = true; p.Parent = fixture; return p
	end
	local function controls(positions)
		local result = {}; for _, p in ipairs(positions) do table.insert(result, part(p)) end; return result
	end
	local function settings(extra)
		local s = table.clone(Settings.defaults); for k, v in pairs(extra or {}) do s[k] = v end; return s
	end
	local function reject(fn) assert(not pcall(fn), "Expected safe rejection") end
	local function apply(plan, target)
		history:SetWaypoint("CurveForge fixture baseline")
		local model = Engine.apply(plan, history, target); if not target then table.insert(generated, model) end; return model
	end
	local function test(name, fn)
		fixture = Instance.new("Folder"); fixture.Name = "CurveForgeTestFixture"; fixture.Parent = workspace
		local ok, err = pcall(fn)
		if ok then passed += 1; print("[CurveForgeTests][PASS] " .. name) else failed += 1; warn("[CurveForgeTests][FAIL] " .. name .. ": " .. tostring(err)) end
		fixture:Destroy(); for _, m in ipairs(generated) do m:Destroy() end; generated = {}
	end
	test("2-point straight path / endpoints / read-only preview", function()
		local c = controls({ Vector3.zero, Vector3.new(20, 0, 0) }); local before = #workspace:GetDescendants()
		local plan = Engine.plan(c, settings()); assert(math.abs(plan.path.length - 20) < 0.001)
		assert(Curve.at(plan.path, 0) == c[1].Position and Curve.at(plan.path, 20) == c[2].Position)
		local output = Engine.output(plan); assert(output.Parent == nil and #workspace:GetDescendants() == before); output:Destroy()
	end)
	test("4-point curved path / controls interpolated", function()
		local c = controls({ Vector3.zero, Vector3.new(5, 8, 0), Vector3.new(12, 2, 4), Vector3.new(20, 4, 0) })
		local plan = Engine.plan(c, settings()); assert(plan.path.length > 20)
		for _, p in ipairs(c) do local found = false; for _, v in ipairs(plan.path.positions) do if (p.Position - v).Magnitude < 1e-4 then found = true end end; assert(found) end
	end)
	test("vertical and 3D orientation / cable gap continuity / collision flags", function()
		local c = controls({ Vector3.zero, Vector3.new(0, 10, 0), Vector3.new(8, 15, 7), Vector3.new(10, 20, 2) })
		for _, collide in ipairs({ true, false }) do
			local plan = Engine.plan(c, settings({ CanCollide = collide, CastShadow = false }))
			local output = Engine.output(plan)
			for i = 1, #plan.distances - 1 do
				local p = output:FindFirstChild(string.format("Segment%03d", i)); assert(p and p.CanCollide == collide and not p.CastShadow)
				local a, b = Curve.at(plan.path, plan.distances[i]), Curve.at(plan.path, plan.distances[i + 1])
				local tip1, tip2 = p.CFrame:PointToWorldSpace(Vector3.new(p.Size.X / 2, 0, 0)), p.CFrame:PointToWorldSpace(Vector3.new(-p.Size.X / 2, 0, 0))
				assert(math.min((tip1 - a).Magnitude, (tip2 - a).Magnitude) < 1e-4)
				assert(math.min((tip1 - b).Magnitude, (tip2 - b).Magnitude) < 1e-4)
				if i < #plan.distances - 1 then local joint = output:FindFirstChild(string.format("Joint%03d", i)); assert((joint.Position - b).Magnitude < 1e-4 and joint.Size.Y == p.Size.Y) end
			end
			output:Destroy()
		end
	end)
	test("repeat spacing / count / endpoints / scale / tangent rotation", function()
		local c = controls({ Vector3.zero, Vector3.new(20, 0, 0) })
		local source = part(Vector3.new(30, 2, 0), "Source"); source.Size = Vector3.new(1, 3, 2); source.CFrame *= CFrame.Angles(0, 0.3, 0)
		for _, config in ipairs({ { Mode = "Repeat", Spacing = 5 }, { Mode = "Repeat", Distribution = "Count", Count = 7, Endpoints = false }, { Mode = "Repeat", Distribution = "Count", Count = 3, Orient = false }, { Mode = "Repeat", Spacing = 5, PreserveRotation = false } }) do
			local plan = Engine.plan(c, settings(config), source); local output = Engine.output(plan)
			assert(#output:GetChildren() == (config.Count or 5))
			for i, d in ipairs(plan.distances) do
				local copy = output:FindFirstChild(string.format("Copy%03d", i)); assert(copy.Size == source.Size and (copy.Position - Curve.at(plan.path, d)).Magnitude < 1e-4)
				if not plan.settings.Orient or plan.settings.PreserveRotation then assert(copy.CFrame.Rotation:FuzzyEq(source.CFrame.Rotation, 1e-4)) else assert(copy.CFrame.LookVector:Dot(Vector3.xAxis) > 0.999) end
			end
			if not plan.settings.Endpoints then assert(plan.distances[1] > 0 and plan.distances[#plan.distances] < 20) end
			output:Destroy()
		end
	end)
	test("Build native one-step Undo / Redo / unrelated objects preserved", function()
		local c = controls({ Vector3.zero, Vector3.new(20, 0, 0) }); local other = part(Vector3.new(90, 5, 0)); local cf = other.CFrame
		local model = apply(Engine.plan(c, settings())); assert(model.Parent == workspace)
		history:Undo(); task.wait(); assert(model.Parent == nil and other.Parent == fixture and other.CFrame == cf and c[1].Parent == fixture)
		history:Redo(); task.wait(); assert(model.Parent == workspace and other.CFrame == cf)
	end)
	test("Repeat Model / reopen metadata / Regenerate / native Undo / source unchanged", function()
		local c = controls({ Vector3.zero, Vector3.new(20, 0, 0) })
		local source = Instance.new("Model"); source.Parent = fixture
		local p = part(Vector3.new(30, 5, 0)); p.Parent = source
		local q = part(Vector3.new(31, 6, 0)); q.Parent = source
		local pose, size = p.CFrame, p.Size
		local model = apply(Engine.plan(c, settings({ Mode = "Repeat", Distribution = "Count", Count = 3 }), source))
		local old = model.Output; local loaded = Engine.load(model)
		loaded.settings.Count = 5; c[2].Position += Vector3.new(0, 5, 0)
		local plan = Engine.plan(loaded.controls, loaded.settings, source, loaded.rotation)
		apply(plan, model); assert(#model.Output:GetChildren() == 5 and p.CFrame == pose and p.Size == size and #source:GetChildren() == 2)
		history:Undo(); task.wait(); assert(model.Output == old and #old:GetChildren() == 3 and p.CFrame == pose)
		history:Redo(); task.wait(); assert(#model.Output:GetChildren() == 5 and p.CFrame == pose)
	end)
	test("invalid / deleted / stale controls / settings / output limits", function()
		local c = controls({ Vector3.zero, Vector3.new(20, 0, 0) })
		reject(function() Engine.plan({ c[1], c[1] }, settings()) end)
		reject(function() Engine.plan(c, settings({ Diameter = 0 / 0 })) end)
		reject(function() Engine.plan(c, settings({ Material = "Fake" })) end)
		local plan = Engine.plan(c, settings()); c[1].Position += Vector3.one
		reject(function() Engine.apply(plan, history) end)
		plan = Engine.plan(c, settings()); c[2]:Destroy(); reject(function() Engine.apply(plan, history) end)
		local long = controls({ Vector3.zero, Vector3.new(1000, 0, 0) }); reject(function() Engine.plan(long, settings({ SegmentLength = 0.1 })) end)
	end)
	test("scripted sources rejected / external references / unavailable Undo / rollback", function()
		local c = controls({ Vector3.zero, Vector3.new(20, 0, 0) }); local source = part(Vector3.new(30, 0, 0))
		local scriptItem = Instance.new("Script"); scriptItem.Parent = source
		reject(function() Engine.plan(c, settings({ Mode = "Repeat" }), source) end); scriptItem:Destroy()
		local ref = Instance.new("ObjectValue"); ref.Value = c[1]; ref.Parent = source
		reject(function() Engine.plan(c, settings({ Mode = "Repeat" }), source) end); ref:Destroy()
		local before = #workspace:GetDescendants()
		reject(function() Engine.apply(Engine.plan(c, settings()), { TryBeginRecording = function() return nil end }) end)
		assert(#workspace:GetDescendants() == before)
		local badHistory = { TryBeginRecording = function() return "test" end, FinishRecording = function(_, _, operation) if operation == Enum.FinishRecordingOperation.Commit then error("Injected failure") end end }
		reject(function() Engine.apply(Engine.plan(c, settings()), badHistory) end); assert(#workspace:GetDescendants() == before)
		local model = apply(Engine.plan(c, settings())); local old = model.Output
		reject(function() Engine.apply(Engine.plan(c, settings({ Diameter = 1 })), badHistory, model) end); assert(model.Output == old)
	end)
	test("New Path markers / native Undo / widget mounts without project mutation", function()
		history:SetWaypoint("Marker baseline")
		local c = Engine.newPath(history, Vector3.new(0, 5, 0)); local folder = c[1].Parent
		history:Undo(); task.wait(); assert(folder.Parent == nil)
		history:Redo(); task.wait(); assert(folder.Parent == workspace and #c == 4); folder:Destroy()
		local gui = Instance.new("ScreenGui"); local before = #workspace:GetDescendants()
		local dispose = require(modules.View).mount(gui, game:GetService("Selection"), history)
		assert(gui:FindFirstChild("CurveForgeUI") and #workspace:GetDescendants() == before); dispose(); gui:Destroy()
	end)
	print(string.format("[CurveForgeTests] %d passed / %d failed", passed, failed))
	return failed == 0
end
