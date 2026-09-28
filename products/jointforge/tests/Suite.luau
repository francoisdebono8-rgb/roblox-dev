return function(modules)
	local Schema = require(modules.Schema)
	local Graph = require(modules.Graph)
	local Planner = require(modules.Planner)
	local Transaction = require(modules.Transaction)
	local history = game:GetService("ChangeHistoryService")
	assert(not game:GetService("RunService"):IsRunning(), "Run this harness in Studio edit mode.")
	local passed, failed = 0, 0
	local folder
	local function part(name, position)
		local p = Instance.new("Part")
		p.Name, p.CFrame, p.Anchored = name, CFrame.new(position) * CFrame.Angles(0.2, 0.4, -0.1), true
		p.Parent = folder
		return p
	end
	local function rejects(fn)
		assert(not pcall(fn), "Expected rejection")
	end
	local function test(name, fn)
		folder = Instance.new("Folder"); folder.Name = "JointForgeTestFixture"; folder.Parent = workspace
		local ok, err = pcall(fn)
		if ok then passed += 1; print("[JointForgeTests][PASS] " .. name)
		else failed += 1; warn("[JointForgeTests][FAIL] " .. name .. ": " .. tostring(err)) end
		folder:Destroy()
	end
	local function apply(request)
		history:SetWaypoint("JointForge QA fixture baseline")
		local plan = Planner.preview(workspace, request)
		assert(#plan.errors == 0, table.concat(plan.errors, "\n"))
		return Transaction.apply(plan, history, request.kind == "remove"), plan
	end
	local function undoCheck(before, after)
		assert(history:GetCanUndo(), "Undo unavailable")
		history:Undo()
		task.wait()
		assert(before(), "One Undo failed to restore prior state")
		history:Redo()
		task.wait()
		assert(after(), "One Redo failed to restore operation")
	end

	test("all nine classes / read-only preview / world poses / native Undo Redo", function()
		for _, class in ipairs(Schema.types) do
			local a, b = part("Root", Vector3.new(0, 10, 0)), part("Target", Vector3.new(4, 11, 0))
			local acf, bcf, count = a.CFrame, b.CFrame, #folder:GetDescendants()
			history:SetWaypoint("JointForge QA fixture baseline")
			local plan = Planner.preview(workspace, { kind = "create", class = class, a = a, b = b })
			assert(#folder:GetDescendants() == count and a.CFrame == acf and b.CFrame == bcf, "Preview mutated place")
			local joint = Transaction.apply(plan, history)[1]
			assert(joint.ClassName == class and a.CFrame == acf and b.CFrame == bcf)
			local x, y = Graph.endpoints(joint); assert(x == a and y == b)
			if class == "Weld" or class == "Motor6D" then assert((a.CFrame * joint.C0):FuzzyEq(b.CFrame * joint.C1, 1e-5)) end
			undoCheck(function() return #folder:GetDescendants() == count and a.Parent == folder and b.Parent == folder and a.CFrame == acf and b.CFrame == bcf end,
				function() return joint.Parent == a end)
			a:Destroy(); b:Destroy()
		end
	end)
	test("gun/tool batch static + moving with one Undo", function()
		local a, b, c = part("Handle", Vector3.new(0, 10, 0)), part("Body", Vector3.new(1, 10, 0)), part("Slide", Vector3.new(1, 11, 0))
		local before = { a.CFrame, b.CFrame, c.CFrame }
		b.Anchored, c.Anchored = false, false
		local result = apply({ kind = "batch", root = a, entries = { { part = b, mode = "Static" }, { part = c, mode = "Moving" } } })
		assert(result[1]:IsA("WeldConstraint") and result[2]:IsA("Motor6D"))
		local function samePoses()
			for i, p in ipairs({ a, b, c }) do
				if not p.CFrame:FuzzyEq(before[i], 1e-5) then return false end
			end
			return true
		end
		for i, p in ipairs({ a, b, c }) do
			print("[JointForgeTests] pose delta " .. p.Name .. " = " .. tostring((p.Position - before[i].Position).Magnitude))
		end
		assert(samePoses(), "Batch moved an endpoint beyond floating-point tolerance")
		undoCheck(function() return a.Parent == folder and b.Parent == folder and c.Parent == folder and #Graph.all(folder) == 0 and samePoses() end, function() return #Graph.all(folder) == 2 and samePoses() end)
	end)
	test("door hinge existing attachments preserved", function()
		local a, b = part("Frame", Vector3.new(0, 10, 0)), part("Door", Vector3.new(3, 10, 0))
		local at0, at1 = Instance.new("Attachment"), Instance.new("Attachment")
		at0.Parent, at1.Parent = a, b
		at0.WorldCFrame = CFrame.new(1.5, 10, 0) * CFrame.Angles(0, 0, math.pi / 2)
		at1.WorldCFrame = at0.WorldCFrame
		local c0, c1 = at0.CFrame, at1.CFrame
		local result = apply({ kind = "create", class = "HingeConstraint", a = a, b = b, attachment0 = at0, attachment1 = at1 })
		assert(result[1].Attachment0 == at0 and result[1].Attachment1 == at1 and at0.CFrame == c0 and at1.CFrame == c1)
		undoCheck(function() return at0.Parent == a and at1.Parent == b and #Graph.all(folder) == 0 end, function() return #Graph.all(folder) == 1 end)
	end)
	test("rope and spring lengths / edit properties", function()
		for _, class in ipairs({ "RopeConstraint", "SpringConstraint" }) do
			local a, b = part("Beam", Vector3.new(0, 10, 0)), part("Load", Vector3.new(0, 5, 0))
			local joint = apply({ kind = "create", class = class, a = a, b = b })[1]
			local field = if class == "RopeConstraint" then "Length" else "FreeLength"
			assert(math.abs(joint[field] - 5) < 1e-5)
			apply({ kind = "edit", joint = joint, changes = { [field] = 6 } })
			undoCheck(function() return joint[field] == 5 end, function() return joint[field] == 6 end)
			a:Destroy(); b:Destroy()
		end
	end)
	test("existing connections, reverse duplicates and indirect cycles blocked", function()
		local a, b, c = part("A", Vector3.new()), part("B", Vector3.new(2, 0, 0)), part("C", Vector3.new(4, 0, 0))
		local old = apply({ kind = "create", class = "WeldConstraint", a = a, b = b })[1]
		apply({ kind = "create", class = "Weld", a = b, b = c })
		for _, request in ipairs({
			{ kind = "create", class = "Motor6D", a = b, b = a },
			{ kind = "create", class = "Motor6D", a = a, b = c },
			{ kind = "batch", root = a, entries = { { part = b, mode = "Moving" } } },
		}) do
			local plan = Planner.preview(workspace, request)
			assert(#plan.errors > 0); rejects(function() Transaction.apply(plan, history) end)
		end
		assert(old.Parent == a and old.Part0 == a and old.Part1 == b)
		local plan = Planner.preview(workspace, { kind = "create", class = "NoCollisionConstraint", a = a, b = b })
		assert(#plan.errors == 0, "NoCollision can coexist with a physical joint")
	end)
	test("stale preview rejects movement, new joints and attachment edits", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		local req = { kind = "create", class = "Weld", a = a, b = b }
		local plan = Planner.preview(workspace, req)
		b.CFrame += Vector3.new(1, 0, 0)
		rejects(function() Transaction.apply(plan, history) end)
		plan = Planner.preview(workspace, req)
		apply({ kind = "create", class = "WeldConstraint", a = a, b = b })
		rejects(function() Transaction.apply(plan, history) end)
		local c = part("C", Vector3.new(10, 0, 0))
		local at = Instance.new("Attachment"); at.Parent = c
		plan = Planner.preview(workspace, { kind = "create", class = "RopeConstraint", a = a, b = c, attachment1 = at })
		at.Position = Vector3.new(1, 0, 0)
		rejects(function() Transaction.apply(plan, history) end)
	end)
	test("inspection finds externally parented and broken joints", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		local joint = Instance.new("Motor6D"); joint.Part0, joint.Part1, joint.Parent = a, b, folder
		assert(#Graph.inspect(workspace, { a }) == 1)
		joint.Part1 = nil
		local info = Graph.inspect(workspace, { a })[1]
		assert(info.broken and info.endpoint0 == a and info.endpoint1 == nil)
	end)
	test("C0 C1 edits / reset / native Undo", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		local joint = apply({ kind = "create", class = "Motor6D", a = a, b = b })[1]
		local old = joint.C0
		apply({ kind = "edit", joint = joint, changes = { C0 = CFrame.identity } })
		undoCheck(function() return joint.C0 == old end, function() return joint.C0 == CFrame.identity end)
		assert(Schema.parse("1 2 3 0 90 0", CFrame.identity):FuzzyEq(CFrame.new(1, 2, 3) * CFrame.fromOrientation(0, math.pi / 2, 0)))
		rejects(function() Schema.parse("nan 0 0 0 0 0", CFrame.identity) end)
	end)
	test("confirmed batch removal / preserve attachments / native Undo", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		local joint = apply({ kind = "create", class = "RopeConstraint", a = a, b = b })[1]
		local at = joint.Attachment0
		local plan = Planner.preview(workspace, { kind = "remove", joints = { joint } })
		rejects(function() Transaction.apply(plan, history, false) end)
		Transaction.apply(plan, history, true)
		assert(joint.Parent == nil and at.Parent == a)
		undoCheck(function() return joint.Parent == a and at.Parent == a end, function() return joint.Parent == nil and at.Parent == a end)
	end)
	test("invalid fields, endpoints and duplicates rejected", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		for _, req in ipairs({
			{ kind = "create", class = "Weld", a = a, b = a },
			{ kind = "create", class = "Script", a = a, b = b },
			{ kind = "batch", root = a, entries = { { part = b, mode = "Static" }, { part = b, mode = "Moving" } } },
		}) do assert(#Planner.preview(workspace, req).errors > 0) end
		local joint = apply({ kind = "create", class = "HingeConstraint", a = a, b = b })[1]
		for _, changes in ipairs({ { CurrentAngle = 1 }, { Name = "Other" }, { LowerAngle = 90, UpperAngle = -90 }, { MotorMaxTorque = 0 / 0 } }) do
			assert(#Planner.preview(workspace, { kind = "edit", joint = joint, changes = changes }).errors > 0)
		end
	end)
	test("recording unavailable and commit failure rollback", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		local plan = Planner.preview(workspace, { kind = "create", class = "SpringConstraint", a = a, b = b })
		local count = #folder:GetDescendants()
		rejects(function() Transaction.apply(plan, { TryBeginRecording = function() return nil end }) end)
		assert(#folder:GetDescendants() == count)
		local cancelled = false
		local mock = {
			TryBeginRecording = function() return "test" end,
			FinishRecording = function(_, _, op)
				if op == Enum.FinishRecordingOperation.Commit then error("Injected commit failure") end
				cancelled = true
			end,
		}
		plan = Planner.preview(workspace, { kind = "create", class = "SpringConstraint", a = a, b = b })
		rejects(function() Transaction.apply(plan, mock) end)
		assert(cancelled and #folder:GetDescendants() == count)
	end)
	test("UI invalidation / removal children / unary inspect / detached endpoints", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		local plan = Planner.preview(workspace, { kind = "create", class = "WeldConstraint", a = a, b = b })
		Planner.invalidate(plan)
		rejects(function() Transaction.apply(plan, history) end)
		local joint = apply({ kind = "create", class = "Weld", a = a, b = b })[1]
		Instance.new("Folder", joint)
		assert(#Planner.preview(workspace, { kind = "remove", joints = { joint } }).errors > 0)
		local force = Instance.new("VectorForce"); force.Attachment0 = Instance.new("Attachment", a); force.Parent = b
		for _, info in ipairs(Graph.inspect(workspace, { force })) do assert(not info.broken, "Unary force is not a broken two-endpoint joint") end
		plan = Planner.preview(workspace, { kind = "edit", joint = joint, changes = { Enabled = false } })
		b.Parent = nil
		rejects(function() Transaction.apply(plan, history) end)
		b:Destroy()
	end)
	test("every exposed property is writable in this Studio engine", function()
		for _, class in ipairs(Schema.types) do
			local joint = Instance.new(class)
			local changes = {}
			for _, field in ipairs(Schema.fields[class]) do
				local value = joint[field]
				if Schema.validValue(value) then changes[field] = value end
			end
			Schema.validateChanges(joint, changes)
			joint:Destroy()
		end
	end)
	test("edit and removal roll back after injected commit failure", function()
		local a, b = part("A", Vector3.new()), part("B", Vector3.new(4, 0, 0))
		b.Anchored = false
		local joint = apply({ kind = "create", class = "Motor6D", a = a, b = b })[1]
		local old, pose = joint.C0, b.CFrame
		local mock = {
			TryBeginRecording = function() return "test" end,
			FinishRecording = function(_, _, op) if op == Enum.FinishRecordingOperation.Commit then error("Injected commit failure") end end,
		}
		local plan = Planner.preview(workspace, { kind = "edit", joint = joint, changes = { C0 = CFrame.identity } })
		rejects(function() Transaction.apply(plan, mock) end)
		assert(joint.C0 == old and b.CFrame:FuzzyEq(pose, 1e-5))
		plan = Planner.preview(workspace, { kind = "remove", joints = { joint } })
		rejects(function() Transaction.apply(plan, mock, true) end)
		assert(joint.Parent == a and joint.Part1 == b)
	end)
	print(string.format("[JointForgeTests] %d passed / %d failed", passed, failed))
	assert(failed == 0, "JointForge tests failed")
end
