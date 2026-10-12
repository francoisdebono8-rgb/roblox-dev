-- Opt-in Edit-mode gate; modules are imported from the exact commercial binaries.
return function(modules, legacyModules, hostPlugin, options)
	local Schema, Graph = require(modules.Schema), require(modules.Graph)
	local Planner, Transaction = require(modules.Planner), require(modules.Transaction)
	local OldPlanner = require(legacyModules.Planner)
	local history = game:GetService("ChangeHistoryService")
	local pass, fail, matrix = 0, 0, {}
	local folder
	local function rejects(fn, fragment)
		local ok, err = pcall(fn); assert(not ok, "Expected refusal")
		if fragment then assert(tostring(err):find(fragment, 1, true), tostring(err)) end
	end
	local function test(ids, name, fn)
		folder = Instance.new("Folder"); folder.Name = "JointForgeV11Fixture"; folder.Parent = workspace
		local ok, err = xpcall(fn, debug.traceback)
		folder:Destroy()
		for _, id in ipairs(ids) do if not ok then matrix[id] = false elseif matrix[id] == nil then matrix[id] = true end end
		if ok then pass += 1; print("[JointForgeV11][PASS] " .. name)
		else fail += 1; warn("[JointForgeV11][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function part(name, x)
		local p = Instance.new("Part")
		p.Name, p.CFrame, p.Anchored = name or "Part", CFrame.new(x or 0, 20, 0) * CFrame.Angles(0.2, 0.4, -0.1), true
		p.Parent = folder; return p
	end
	local function pair() return part("A", 0), part("B", 4) end
	local function preview(request)
		local p = Planner.preview(workspace, request)
		assert(#p.errors == 0, table.concat(p.errors, "; "))
		assert(table.isfrozen(p) and table.isfrozen(p.operations))
		return p
	end
	local function apply(request)
		history:SetWaypoint("JointForge technical fixture baseline")
		return Transaction.apply(preview(request), history, request.kind == "remove")
	end
	local function create(class, a, b)
		return apply({kind = "create", class = class, a = a, b = b})[1]
	end
	local function undoRedo(before, after)
		assert(history:GetCanUndo(), "Native Undo unavailable")
		history:Undo(); task.wait(); assert(before(), "Native Undo mismatch")
		history:Redo(); task.wait(); assert(after(), "Native Redo mismatch")
	end
	local function diagnostic(plan, code)
		for _, d in ipairs(plan.diagnostics) do if d.code == code then return true end end
		return false
	end
	local function rawJoint(class, a, b)
		local j = Instance.new(class); j.Part0, j.Part1, j.Parent = a, b, folder; return j
	end
	local function fake(onBegin, onCommit)
		return { TryBeginRecording = function() if onBegin then onBegin() end; return "qa" end,
			FinishRecording = function(_, _, op) if op == Enum.FinishRecordingOperation.Commit and onCommit then onCommit() end end }
	end
	local function stale(request, change)
		local p = preview(request); change()
		local began = false
		rejects(function() Transaction.apply(p, fake(function() began = true end), true) end, "Relevant graph")
		assert(not began)
	end
	local function attachment(p, cf)
		local a = Instance.new("Attachment"); a.Parent = p; a.WorldCFrame = cf or p.CFrame
		return a
	end
	local function sameFields(joint, values, except)
		for field, value in pairs(values) do
			if not except or not except[field] then assert(Graph.equal(joint[field], value), "Unrelated field changed: " .. field) end
		end
	end

	for id, class in ipairs(Schema.types) do
		test({id, 49, 54}, class .. " exact endpoints, read-only Preview and native Undo/Redo", function()
			local a, b = pair()
			local acf, bcf, count = a.CFrame, b.CFrame, #folder:GetDescendants()
			local p = preview({kind = "create", class = class, a = a, b = b})
			assert(#folder:GetDescendants() == count and a.CFrame == acf and b.CFrame == bcf)
			history:SetWaypoint("JointForge technical fixture baseline")
			local joint = Transaction.apply(p, history)[1]
			local x, y = Graph.endpoints(joint); assert(x == a and y == b)
			assert(a.CFrame:FuzzyEq(acf, 1e-5) and b.CFrame:FuzzyEq(bcf, 1e-5))
			if class == "Weld" or class == "Motor6D" then assert((a.CFrame * joint.C0):FuzzyEq(b.CFrame * joint.C1, 1e-5)) end
			undoRedo(function() return joint.Parent == nil and #folder:GetDescendants() == count end,
				function() return joint.Parent == a and select(2, Graph.endpoints(joint)) == b end)
		end)
	end

	test({10, 11, 12, 13, 16}, "Pair diagnostics and separate NoCollision semantics", function()
		local a, b = pair(); local c = part("C", 8)
		local same = Planner.preview(workspace, {kind = "create", class = "Weld", a = a, b = a})
		assert(#same.errors > 0 and diagnostic(same, "same-endpoint"))
		rawJoint("WeldConstraint", a, b); rawJoint("WeldConstraint", b, c)
		local duplicate = Planner.preview(workspace, {kind = "create", class = "Motor6D", a = b, b = a})
		assert(#duplicate.errors > 0 and diagnostic(duplicate, "direct-duplicate"))
		local indirect = Planner.preview(workspace, {kind = "create", class = "Weld", a = a, b = c})
		assert(#indirect.errors > 0 and diagnostic(indirect, "indirect-path"))
		local p = preview({kind = "create", class = "NoCollisionConstraint", a = a, b = b})
		assert(diagnostic(p, "anchored-both"))
		Transaction.apply(p, fake())
		assert(#Planner.preview(workspace, {kind = "create", class = "NoCollisionConstraint", a = b, b = a}).errors > 0)
		local d, e = part("D", 12), part("E", 16)
		rawJoint("NoCollisionConstraint", d, e)
		preview({kind = "create", class = "Weld", a = d, b = e})
	end)

	test({19, 20}, "Immutable request/operations, engine identity and one-use state", function()
		local a, b = pair()
		local request = {kind = "create", class = "Weld", a = a, b = b}
		local p = preview(request); request.b = a
		rejects(function() p.request.b = a end); rejects(function() p.operations[1].a = b end)
		rejects(function() Transaction.apply(table.clone(p), fake()) end, "engine-issued")
		rejects(function() Transaction.apply({request = request}, fake()) end, "engine-issued")
		Transaction.apply(p, fake()); rejects(function() Transaction.apply(p, fake()) end, "consumed")
		local c = part("C", 8); p = preview({kind = "create", class = "Weld", a = a, b = c})
		Planner.invalidate(p); rejects(function() Transaction.apply(p, fake()) end, "Inputs changed")
	end)

	test({21, 22, 23}, "Relevant new edge stales; distant changes stay fresh; full ancestry stales", function()
		local a, b = pair()
		local request = {kind = "create", class = "Weld", a = a, b = b}
		local c, d = part("C", 12), part("D", 16)
		local distant = rawJoint("WeldConstraint", c, d)
		local p = preview(request); distant.Enabled = false; distant.Name = "Unrelated"; d.CFrame += Vector3.new(1, 0, 0)
		Planner.check(p); distant:Destroy(); Planner.check(p)
		distant = rawJoint("Weld", c, d); Planner.check(p)
		stale(request, function() rawJoint("WeldConstraint", a, c) end)
		local container = Instance.new("Folder"); container.Parent = folder; b.Parent = container
		stale(request, function() container.Parent = a end)
		stale(request, function() b.Parent = nil end); b:Destroy()
	end)

	test({14, 15, 17, 18}, "Broken/unsupported inspection, direct attachment ancestry and pivot diagnostics", function()
		local a, b = pair()
		local broken = rawJoint("Motor6D", a, nil)
		local records = Graph.inspect(workspace, {broken})
		assert(#records == 1 and records[1].broken and records[1].diagnostics[1].code == "broken-endpoint")
		local unary = Instance.new("VectorForce"); unary.Attachment0 = attachment(a); unary.Parent = b
		records = Graph.inspect(workspace, {unary})
		assert(#records == 1 and not records[1].broken and records[1].diagnostics[1].code == "inspect-only")
		broken:Destroy(); unary:Destroy()
		local x, y = attachment(a), attachment(b, b.CFrame * CFrame.Angles(0, 0, math.pi / 2))
		local request = {kind = "create", class = "HingeConstraint", a = a, b = b, attachment0 = x, attachment1 = y}
		local p = preview(request); assert(diagnostic(p, "hinge-axis") and diagnostic(p, "separated-pivot"))
		local nested = Instance.new("Folder"); nested.Parent = a; x.Parent = nested
		p = Planner.preview(workspace, request)
		assert(#p.errors > 0 and diagnostic(p, "attachment-ancestry"))
		local constraint = Instance.new("HingeConstraint"); constraint.Attachment0, constraint.Attachment1, constraint.Parent = x, y, a
		assert(Graph.inspect(workspace, {constraint})[1].broken)
	end)

	test({24, 25}, "Attachment local/world frame, reparent/delete and edited field stale exactly", function()
		for _, change in ipairs({
			function(a) a.CFrame *= CFrame.new(0.0000001, 0, 0) end,
			function(a, _, b) a.Parent = b end,
			function(a) a:Destroy() end,
		}) do
			local a, b = pair(); local at = attachment(a)
			stale({kind = "create", class = "RopeConstraint", a = a, b = b, attachment0 = at}, function() change(at, a, b) end)
			a:Destroy(); b:Destroy()
		end
		local a, b = pair(); local joint = rawJoint("Weld", a, b)
		stale({kind = "edit", joint = joint, changes = {Enabled = false}}, function() joint.C0 *= CFrame.new(0.0000001, 0, 0) end)
	end)

	test({26, 27, 28}, "Every exposed field uses native preflight/readback; bounds, enums, finite frames", function()
		local numeric = {LowerAngle = -30, UpperAngle = 50, TwistLowerAngle = -20, TwistUpperAngle = 30,
			MinLength = 1, MaxLength = 10, FreeLength = 6, Length = 6, Restitution = 0.25,
			Thickness = 0.3, AngularVelocity = -2, AngularSpeed = 5, TargetAngle = 20,
			MotorMaxTorque = 7, ServoMaxTorque = 8, MaxFrictionTorque = 9, Stiffness = 10, Damping = 2, MaxForce = 12}
		for _, class in ipairs(Schema.types) do
			local joint = Instance.new(class); joint.Parent = folder
			local changes = {}
			for _, field in ipairs(Schema.fields[class]) do
				local old = joint[field]
				local value = if typeof(old) == "boolean" then not old elseif typeof(old) == "EnumItem" then Enum.ActuatorType.Motor
					elseif typeof(old) == "CFrame" then CFrame.new(1, 2, 3) * CFrame.Angles(0.2, 0.1, 0.3) else numeric[field]
				assert(value ~= nil, "Missing editable-field fixture " .. field)
				Schema.validateChanges(joint, {[field] = value})
				changes[field] = value
			end
			local p = preview({kind = "edit", joint = joint, changes = changes})
			Transaction.apply(p, fake())
			for field, wanted in pairs(changes) do assert(Schema.accepted(joint[field], wanted), field) end
			joint:Destroy()
		end
		for _, item in ipairs({
			{"HingeConstraint", {LowerAngle = 90, UpperAngle = -90}},
			{"BallSocketConstraint", {TwistLowerAngle = 90, TwistUpperAngle = -90}},
			{"SpringConstraint", {MinLength = 10, MaxLength = 2}},
			{"HingeConstraint", {ActuatorType = Enum.Material.Plastic}},
			{"HingeConstraint", {MotorMaxTorque = -0.00000001}},
			{"HingeConstraint", {ServoMaxTorque = 1e100}},
			{"BallSocketConstraint", {UpperAngle = 180.0000001}},
			{"RopeConstraint", {Restitution = 1.00000001}},
			{"RopeConstraint", {Length = 1e100}},
			{"RodConstraint", {Length = 0.2 - 1e-8}},
			{"SpringConstraint", {FreeLength = 0.1 - 1e-8}},
			{"SpringConstraint", {MaxLength = 0.1 - 1e-8}},
			{"SpringConstraint", {Stiffness = 0 / 0}},
			{"Weld", {C0 = CFrame.new(0 / 0, 0, 0)}},
			{"Motor6D", {C1 = CFrame.new(math.huge, 0, 0)}},
			{"Weld", {Name = "Unsupported"}},
		}) do
			local joint = Instance.new(item[1]); joint.Parent = folder
			assert(#Planner.preview(workspace, {kind = "edit", joint = joint, changes = item[2]}).errors > 0, item[1])
			joint:Destroy()
		end
		local spring = Instance.new("SpringConstraint"); spring.MaxForce = math.huge; spring.Parent = folder
		Transaction.apply(preview({kind = "edit", joint = spring, changes = {Visible = not spring.Visible}}), fake())
		assert(spring.MaxForce == math.huge, "Unchanged native infinity must survive")
	end)

	for _, class in ipairs({"WeldConstraint", "Weld", "Motor6D", "NoCollisionConstraint"}) do
		test({29, 32, 50}, class .. " explicit endpoints preserve unanchored poses, fields and native history", function()
			local a, b = pair(); local c, d = part("C", 10), part("D", 14)
			b.Anchored, d.Anchored = false, false
			local neighbor = part("Neighbor", 18); neighbor.Anchored = false
			local joint = create(class, a, b)
			local edge = rawJoint("WeldConstraint", b, neighbor)
			local values, parent = Schema.read(joint), joint.Parent
			local poses = {[a] = a.CFrame, [b] = b.CFrame, [c] = c.CFrame, [d] = d.CFrame, [neighbor] = neighbor.CFrame}
			local p = preview({kind = "reassign", joint = joint, endpoint0 = c, endpoint1 = d})
			assert(p.operations[1].old0 == a and p.operations[1].old1 == b and p.operations[1].a == c and p.operations[1].b == d)
			history:SetWaypoint("JointForge technical fixture baseline"); Transaction.apply(p, history)
			assert(joint.Part0 == c and joint.Part1 == d and joint.Parent == parent and edge.Part0 == b)
			sameFields(joint, values, {C0 = true})
			for p0, cf in pairs(poses) do assert(p0.CFrame:FuzzyEq(cf, 1e-5), "Endpoint or old neighbor moved") end
			if class == "Weld" or class == "Motor6D" then assert((c.CFrame * joint.C0):FuzzyEq(d.CFrame * joint.C1, 1e-5)) end
			local finalC0 = values.C0 and joint.C0
			undoRedo(function() return joint.Part0 == a and joint.Part1 == b and (not values.C0 or Graph.equal(joint.C0, values.C0)) end,
				function() return joint.Part0 == c and joint.Part1 == d and (not finalC0 or Graph.equal(joint.C0, finalC0)) end)
		end)
	end

	for _, class in ipairs({"HingeConstraint", "BallSocketConstraint", "RopeConstraint", "RodConstraint", "SpringConstraint"}) do
		test({30, 50}, class .. " explicit existing/new attachments retain fields, old attachments and native history", function()
			local a, b = pair(); local c, d = part("C", 10), part("D", 14)
			local joint = create(class, a, b)
			local old0, old1, values = joint.Attachment0, joint.Attachment1, Schema.read(joint)
			local replacement = attachment(c)
			local p = preview({kind = "reassign", joint = joint, endpoint0 = replacement,
				endpoint1 = {create = true, part = d, worldCFrame = d.CFrame * CFrame.new(0, 1, 0)}})
			history:SetWaypoint("JointForge technical fixture baseline"); Transaction.apply(p, history)
			local new1 = joint.Attachment1
			assert(joint.Attachment0 == replacement and new1.Parent == d and old0.Parent == a and old1.Parent == b)
			assert(Schema.accepted(new1.WorldCFrame, p.operations[1].attachments[2].world))
			sameFields(joint, values)
			undoRedo(function() return joint.Attachment0 == old0 and joint.Attachment1 == old1 and new1.Parent == nil end,
				function() return joint.Attachment0 == replacement and joint.Attachment1 == new1 and new1.Parent == d end)
		end)
	end

	test({29, 30, 31, 32}, "Explicit broken repair; conflict/no-input/unsafe-transform refusals; opt-in raw frames", function()
		local a, b = pair(); local c = part("C", 8)
		local joint = rawJoint("Weld", a, nil)
		assert(#Planner.preview(workspace, {kind = "reassign", joint = joint}).errors > 0)
		Transaction.apply(preview({kind = "reassign", joint = joint, endpoint1 = b}), fake())
		assert(joint.Part0 == a and joint.Part1 == b)
		local other = rawJoint("WeldConstraint", a, c)
		assert(#Planner.preview(workspace, {kind = "reassign", joint = joint, endpoint1 = c}).errors > 0)
		joint:Destroy(); other:Destroy()
		local rope = Instance.new("RopeConstraint"); rope.Attachment0 = attachment(a); rope.Parent = a
		Transaction.apply(preview({kind = "reassign", joint = rope, endpoint1 = attachment(b)}), fake())
		assert(select(2, Graph.endpoints(rope)) == b); rope:Destroy()
		joint = create("Motor6D", a, b); joint.Transform = CFrame.new(0, 1, 0)
		assert(#Planner.preview(workspace, {kind = "reassign", joint = joint, endpoint1 = c}).errors > 0)
		local oldC0, oldC1, transform = joint.C0, joint.C1, joint.Transform
		local p = preview({kind = "reassign", joint = joint, endpoint1 = c, poseMode = "raw"})
		assert(diagnostic(p, "raw-frame")); Transaction.apply(p, fake())
		assert(joint.C0 == oldC0 and joint.C1 == oldC1 and joint.Transform == transform)
	end)

	test({33, 34, 35, 36, 37, 53}, "Bounded mixed batch, duplicate-name identities, exact poses and whole-batch refusal", function()
		local root, entries, poses = part("Handle", 0), {}, {}
		for i = 1, Graph.limits.operations do
			local child = part("Duplicate", i * 2); child.Anchored = false
			entries[i] = {part = child, mode = i % 2 == 0 and "Static" or "Moving"}; poses[child] = child.CFrame
		end
		local collision = Instance.new("Folder"); collision.Name = "JF_Motor6D_Duplicate"; collision.Parent = root
		local request = {kind = "batch", root = root, entries = entries}
		local p, second = preview(request), preview(request)
		assert(Graph.equal(p.operations, second.operations) and p.metrics.scans == 1 and #p.operations == 128)
		assert(p.operations[1].name == "JF_Motor6D_Duplicate_2")
		local names = {}
		for i, op in ipairs(p.operations) do assert(op.b == entries[i].part and not names[op.name]); names[op.name] = true end
		history:SetWaypoint("JointForge technical fixture baseline")
		local result = Transaction.apply(p, history); assert(#result == #entries)
		for i, joint in ipairs(result) do
			assert(joint.Part0 == root and joint.Part1 == entries[i].part)
			assert(joint.ClassName == (entries[i].mode == "Static" and "WeldConstraint" or "Motor6D"))
			assert(joint.Part1.CFrame:FuzzyEq(poses[joint.Part1], 1e-5))
		end
		undoRedo(function() return result[1].Parent == nil and result[#result].Parent == nil end,
			function() return result[1].Parent == root and result[#result].Parent == root end)
		for _, list in ipairs({
			{{part = root, mode = "Static"}},
			{{part = entries[1].part, mode = "Static"}, {part = entries[1].part, mode = "Moving"}},
			{{part = part("Valid", 800), mode = "Static"}, {part = part("Invalid", 804), mode = "Unknown"}},
		}) do
			local before = #folder:GetDescendants()
			local blocked = Planner.preview(workspace, {kind = "batch", root = root, entries = list})
			assert(#blocked.errors > 0 and #blocked.operations == 0 and #folder:GetDescendants() == before)
		end
	end)

	test({38, 39, 40}, "Planned attachment world frames and lengths; near-zero refuses wholly", function()
		for _, class in ipairs({"RopeConstraint", "RodConstraint", "SpringConstraint"}) do
			local a, b = pair()
			local existing = attachment(a, a.CFrame * CFrame.new(1, 2, 0))
			local old = existing.CFrame
			local p = preview({kind = "create", class = class, a = a, b = b, attachment0 = existing})
			local length = p.operations[1].length
			local result = Transaction.apply(p, fake())[1]
			assert(result.Attachment0 == existing and existing.CFrame == old)
			assert(Schema.accepted(result.Attachment1.WorldCFrame, p.operations[1].attachments[2].world))
			assert(Schema.accepted(result[class == "SpringConstraint" and "FreeLength" or "Length"], length))
			a:Destroy(); b:Destroy()
			a, b = pair(); b.CFrame = a.CFrame
			assert(#Planner.preview(workspace, {kind = "create", class = class, a = a, b = b}).errors > 0)
			a:Destroy(); b:Destroy()
		end
	end)

	test({41, 42, 51}, "Confirmed removal retains exact instances and attachments; child/mixed/duplicate refusals", function()
		local a, b = pair(); local joint = create("RopeConstraint", a, b)
		local at0, at1 = joint.Attachment0, joint.Attachment1
		local request = {kind = "remove", joints = {joint}}
		local p = preview(request); local began = false
		rejects(function() Transaction.apply(p, fake(function() began = true end), false) end, "confirmation")
		assert(not began and joint.Parent == a)
		history:SetWaypoint("JointForge technical fixture baseline"); Transaction.apply(p, history, true)
		assert(joint.Parent == nil and at0.Parent == a and at1.Parent == b)
		undoRedo(function() return joint.Parent == a and joint.Attachment0 == at0 and joint.Attachment1 == at1 end,
			function() return joint.Parent == nil and at0.Parent == a and at1.Parent == b end)
		joint.Parent = a
		assert(#Planner.preview(workspace, {kind = "remove", joints = {joint, joint}}).errors > 0)
		local child = Instance.new("Folder"); child.Parent = joint
		assert(#Planner.preview(workspace, request).errors > 0); child:Destroy()
		local unsupported = Instance.new("VectorForce"); unsupported.Parent = a
		local mixed = Planner.preview(workspace, {kind = "remove", joints = {joint, unsupported}})
		assert(#mixed.errors > 0 and #mixed.operations == 0)
		stale(request, function() local content = Instance.new("Folder"); content.Parent = joint end)
		joint:ClearAllChildren()
		stale(request, function() joint.Parent = b end)
		joint.Parent = a
		local parent = Instance.new("Folder"); parent.Parent = folder; joint.Parent = parent
		stale(request, function() parent.Parent = b end)
	end)

	test({43, 44}, "Recording refusal consumes plan; mutation during recording opens refuses before writes", function()
		local a, b = pair()
		local request = {kind = "create", class = "Weld", a = a, b = b}
		local p = preview(request); local count = #folder:GetDescendants()
		rejects(function() Transaction.apply(p, {TryBeginRecording = function() return nil end}) end, "cannot start")
		assert(#folder:GetDescendants() == count)
		rejects(function() Transaction.apply(p, fake()) end, "consumed")
		p = preview(request); local changed = b.CFrame * CFrame.new(1, 0, 0); local cancelled = false
		rejects(function() Transaction.apply(p, {
			TryBeginRecording = function() b.CFrame = changed; return "qa" end,
			FinishRecording = function(_, _, operation) assert(operation == Enum.FinishRecordingOperation.Cancel); cancelled = true end,
		}) end, "Relevant graph")
		assert(cancelled and b.CFrame == changed and #folder:GetDescendants() == count, "External recording-open mutation must not be overwritten")
		local c = part("C", 8)
		p = preview(request)
		rejects(function() Transaction.apply(p, fake(function() rawJoint("WeldConstraint", a, c) end)) end, "Relevant graph")
	end)

	local function injected(plan, when, check)
		local env = getfenv(Transaction.apply); local faulted, cancelled = false, false
		-- QA-only environment injection: unchanged candidate Source and real native
		-- setters. Fault occurs immediately after the selected native write/readback.
		setfenv(Transaction.apply, setmetatable({assert = function(condition, message)
			env.assert(condition, message)
			if not faulted and when(message) then
				faulted = true; if check then check() end
				error("Injected native post-write failure")
			end
		end}, {__index = env}))
		local ok, err = pcall(Transaction.apply, plan, {
			TryBeginRecording = function() return "qa" end,
			FinishRecording = function(_, _, op) assert(op == Enum.FinishRecordingOperation.Cancel); cancelled = true end,
		}, true)
		setfenv(Transaction.apply, env)
		assert(not ok and faulted and cancelled and tostring(err):find("Injected native post-write failure", 1, true), tostring(err))
	end

	test({38, 45}, "Injected mid-create failure cleans only owned attachments and leaves no batch prefix", function()
		local a, b = pair(); local external = attachment(a)
		local before = #folder:GetDescendants()
		local p = preview({kind = "create", class = "RopeConstraint", a = a, b = b, attachment0 = external})
		injected(p, function(message) return message == "Native write readback mismatch: Attachment1" end,
			function() assert(#folder:GetDescendants() == before + 1) end)
		assert(#folder:GetDescendants() == before and external.Parent == a)
		local c = part("C", 8)
		p = preview({kind = "batch", root = a, entries = {{part = b, mode = "Static"}, {part = c, mode = "Moving"}}})
		local writes = 0
		injected(p, function(message)
			if message == "Native write readback mismatch: Parent" then writes += 1 end
			return writes == 1
		end, function() assert(#Graph.all(folder) == 1) end)
		assert(#Graph.all(folder) == 0 and #a:GetChildren() == 1)
	end)

	test({46}, "Injected mid-edit readback failure restores changed fields and connected poses", function()
		local a, b = pair(); b.Anchored = false
		local joint = create("Motor6D", a, b)
		local fields, acf, bcf = Schema.read(joint), a.CFrame, b.CFrame
		local p = preview({kind = "edit", joint = joint, changes = {C0 = CFrame.new(0, 2, 0), Enabled = false}})
		injected(p, function(message) return message == "Native write readback mismatch: C0" end)
		sameFields(joint, fields); assert(a.CFrame:FuzzyEq(acf, 1e-5) and b.CFrame:FuzzyEq(bcf, 1e-5))
	end)

	test({42, 47}, "Injected mid-remove rollback restores exact first and unvisited second identities", function()
		local a, b = pair(); local c = part("C", 8)
		local one, two = rawJoint("WeldConstraint", a, b), rawJoint("WeldConstraint", b, c)
		local parent0, parent1 = one.Parent, two.Parent
		injected(preview({kind = "remove", joints = {one, two}}), function(message) return message == "Native write readback mismatch: Parent" end,
			function() assert(one.Parent == nil and two.Parent == parent1) end)
		assert(one.Parent == parent0 and two.Parent == parent1 and one.Part1 == b and two.Part1 == c)
	end)

	test({38, 42, 48}, "Injected commit failure rolls back create/edit/reassign/remove and keeps native identity", function()
		for _, kind in ipairs({"create", "edit", "reassign", "remove"}) do
			local a, b = pair(); local c = part("C", 8); b.Anchored = false
			local joint = kind ~= "create" and create("Motor6D", a, b) or nil
			local count, fields, acf, bcf = #folder:GetDescendants(), joint and Schema.read(joint), a.CFrame, b.CFrame
			local request = if kind == "create" then {kind = kind, class = "SpringConstraint", a = a, b = b}
				elseif kind == "edit" then {kind = kind, joint = joint, changes = {C0 = CFrame.identity}}
				elseif kind == "reassign" then {kind = kind, joint = joint, endpoint1 = c}
				else {kind = kind, joints = {joint}}
			rejects(function() Transaction.apply(preview(request), fake(nil, function() error("Injected commit failure") end), true) end, "Injected commit")
			assert(#folder:GetDescendants() == count and a.CFrame:FuzzyEq(acf, 1e-5) and b.CFrame:FuzzyEq(bcf, 1e-5))
			if joint then assert(joint.Parent == a and joint.Part0 == a and joint.Part1 == b); sameFields(joint, fields) end
			a:Destroy(); b:Destroy(); c:Destroy()
		end
	end)

	test({50}, "Raw C0/C1 and numeric edit native Undo/Redo", function()
		local a, b = pair(); local joint = create("Weld", a, b)
		local old0, old1 = joint.C0, joint.C1
		apply({kind = "edit", joint = joint, changes = {C0 = CFrame.new(0, 1, 0), C1 = CFrame.new(0, -1, 0)}})
		undoRedo(function() return Graph.equal(joint.C0, old0) and Graph.equal(joint.C1, old1) end,
			function() return joint.C0 == CFrame.new(0, 1, 0) and joint.C1 == CFrame.new(0, -1, 0) end)
		joint:Destroy(); joint = create("RopeConstraint", a, b)
		local length = joint.Length; apply({kind = "edit", joint = joint, changes = {Length = 9}})
		undoRedo(function() return joint.Length == length end, function() return joint.Length == 9 end)
	end)

	test({52}, "Each hierarchy/node/edge/component/entry/operation/remove/request/depth cap refuses wholly", function()
		local function cap(name, fill, request, fragment)
			local scope = Instance.new("Folder"); scope.Parent = folder
			local a, b = part("A", 0), part("B", 4); a.Parent, b.Parent = scope, scope
			local req = request or {kind = "create", class = "Weld", a = a, b = b}
			fill(scope, a, b, req)
			local p = Planner.preview(workspace, req)
			assert(#p.errors > 0 and #p.operations == 0 and table.concat(p.errors):find(fragment, 1, true), name .. ": " .. table.concat(p.errors))
			print("[JointForgeV11][CAP] " .. name .. " PASS")
			scope:Destroy()
		end
		cap("scan", function(scope)
			for _ = 1, Graph.limits.scan do local item = Instance.new("Folder"); item.Parent = scope end
		end, nil, "scan cap")
		cap("nodes", function(scope)
			for _ = 1, Graph.limits.nodes do local item = Instance.new("Part"); item.Parent = scope end
		end, nil, "node cap")
		cap("edges", function(scope)
			for _ = 1, Graph.limits.edges + 1 do local item = Instance.new("WeldConstraint"); item.Parent = scope end
		end, nil, "constraint scan cap")
		cap("component", function(scope, a)
			for _ = 1, Graph.limits.component do
				local item = Instance.new("Part"); item.Anchored = true; item.Parent = scope
				local joint = Instance.new("WeldConstraint"); joint.Part0, joint.Part1, joint.Parent = a, item, scope
			end
		end, nil, "traversal cap")
		cap("batch", function(_, a, b, req)
			req.kind, req.root, req.entries = "batch", a, {}
			for _ = 1, Graph.limits.batch + 1 do table.insert(req.entries, {part = b, mode = "Static"}) end
		end, nil, "Batch entry cap")
		cap("operations", function(scope, a, _, req)
			req.kind, req.root, req.entries = "batch", a, {}
			for _ = 1, Graph.limits.operations + 1 do
				local item = Instance.new("Part"); item.Anchored = true; item.Parent = scope
				table.insert(req.entries, {part = item, mode = "Static"})
			end
		end, nil, "operation cap")
		cap("remove", function(scope, _, _, req)
			req.kind, req.joints = "remove", {}
			for _ = 1, Graph.limits.remove + 1 do
				local joint = Instance.new("Weld"); joint.Parent = scope; table.insert(req.joints, joint)
			end
		end, nil, "Removal count cap")
		cap("request", function(_, _, _, req)
			req.extra = {}; for i = 1, Graph.limits.requestValues + 1 do req.extra[i] = i end
		end, nil, "Request value cap")
		cap("request-depth", function(_, _, _, req)
			local current = req
			for _ = 1, 18 do current.extra = {}; current = current.extra end
		end, nil, "request table")
		cap("ancestry", function(scope, a)
			local parent = scope
			for _ = 1, Graph.limits.depth do local item = Instance.new("Folder"); item.Parent = parent; parent = item end
			a.Parent = parent
		end, nil, "depth cap")
		local selections, target = {}, part("Selection", 0)
		for i = 1, Graph.limits.nodes + 1 do selections[i] = target end
		rejects(function() Graph.inspect(workspace, selections) end, "Selection cap")
		print("[JointForgeV11][CAP] inspect-selection PASS")
	end)

	test({37}, "Measured sparse assembly comparison against embedded public V1", function()
		local root, entries = part("Handle", 0), {}
		for i = 1, 32 do entries[i] = {part = part("Entry", i * 2), mode = i % 2 == 0 and "Static" or "Moving"} end
		for i = 1, 1000 do
			local a, b = part("Sparse", 200 + i * 4), part("Sparse", 202 + i * 4)
			rawJoint("WeldConstraint", a, b)
		end
		for _ = 1, 2800 do local item = Instance.new("Folder"); item.Parent = folder end
		local request = {kind = "batch", root = root, entries = entries}
		local function old() return OldPlanner.preview(workspace, request) end
		local function new() return Planner.preview(workspace, request) end
		for _ = 1, 2 do assert(#old().errors == 0 and #new().errors == 0) end
		local before, after = {}, {}
		for i = 1, 5 do
			local start = os.clock(); local x = old(); before[i] = (os.clock() - start) * 1000
			start = os.clock(); local y = new(); after[i] = (os.clock() - start) * 1000
			assert(#x.operations == #y.operations and y.metrics.scans == 1)
		end
		table.sort(before); table.sort(after)
		print(string.format("[JointForgeV11][BENCHMARK] descendants=%d entries=32 edges=1000 warmup=2 repetitions=5 v1_preview_median_ms=%.6f candidate_preview_median_ms=%.6f candidate_graph_scans=1",
			#folder:GetDescendants(), before[3], after[3]))
	end)

	test({19, 54}, "Native View mount with QA-captured button callbacks and immutable-plan invalidation", function()
		if options and options.viewSmoke then options.viewSmoke(); return end
		local View = require(modules.View)
		local widget = hostPlugin:CreateDockWidgetPluginGuiAsync("JointForgeV11ControlSmoke",
			DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 440, 680, 340, 400))
		local event = Instance.new("BindableEvent")
		local selected, callbacks, captured = {}, {}, nil
		local selection = {Get = function() return selected end, Set = function(_, items) selected = items end, SelectionChanged = event.Event}
		local env, originalPreview = getfenv(View.mount), Planner.preview
		local nativeInstance, savedInstance = Instance, rawget(env, "Instance")
		-- QA-only event capture over real native controls; no source rewriting or
		-- synthetic visual acceptance. Other Instance classes remain native.
		env.Instance = {new = function(class)
			local item = nativeInstance.new(class)
			if class ~= "TextButton" then return item end
			return setmetatable({}, {
				__index = function(_, key)
					if key == "Activated" then return {Connect = function(_, fn)
						table.insert(callbacks, {button = item, fn = fn}); return item.Activated:Connect(fn)
					end} end
					return item[key]
				end,
				__newindex = function(_, key, value) item[key] = value end,
			})
		end}
		Planner.preview = function(...) captured = originalPreview(...); return captured end
		local dispose
		local ok, err = pcall(function()
			dispose = View.mount(widget, selection, history)
			assert(widget:FindFirstChild("JointForgeUI"))
			local function click(text, ordinal)
				local n = 0
				for _, callback in ipairs(callbacks) do
					if callback.button.Parent and callback.button.Text == text then
						n += 1; if n == (ordinal or 1) then callback.fn(); return end
					end
				end
				error("Missing native button " .. text)
			end
			local a, b = pair()
			selected = {a}; click("Use selected part", 1)
			selected = {b}; click("Use selected part", 2)
			click("Preview joint"); assert(captured and #captured.errors == 0 and table.isfrozen(captured))
			event:Fire(); task.wait()
			rejects(function() Planner.check(captured) end, "Inputs changed")
			local joint = rawJoint("Weld", a, b); local c = part("C", 8)
			click("Inspect"); selected = {joint}; click("Inspect current selection"); click("Inspect / edit")
			selected = {c}; click("Assign selected part to 1"); click("Preview explicit endpoint reassignment")
			assert(captured.request.kind == "reassign" and captured.request.endpoint1 == c and #captured.errors == 0)
			local rope = nativeInstance.new("RopeConstraint")
			rope.Attachment0, rope.Attachment1, rope.Parent = attachment(a), attachment(b), a
			local d = part("D", 12)
			local replacement = attachment(c); replacement.Name = "ExplicitReplacement"
			selected = {rope}; click("Inspect current selection"); click("Inspect / edit")
			selected = {replacement}; click("Assign selected attachment to 1")
			selected = {d}; click("Create attachment 0 at selected part")
			click("Preview explicit endpoint reassignment")
			assert(#captured.errors == 0, table.concat(captured.errors))
			local exact = false
			local spec = captured.operations[1].attachments[1]
			for _, item in ipairs(widget:GetDescendants()) do
				if item:IsA("TextLabel") and item.Text:find("NEW " .. d:GetFullName() .. "." .. spec.name, 1, true)
					and item.Text:find(replacement:GetFullName(), 1, true) then exact = true end
			end
			assert(exact, "Attachment reassignment Preview must identify both replacement attachments")
		end)
		Planner.preview = originalPreview; env.Instance = savedInstance
		if dispose then dispose() end; event:Destroy(); widget:Destroy()
		assert(ok, err)
	end)

	test({55, 56}, "Exact imported production payload and no network/runtime/QA code", function()
		local sourceCount = options and options.sourceCount or 6
		assert(#modules.Parent:GetDescendants() == sourceCount + 1 and modules.Parent.Main.Disabled)
		assert(#modules.Parent.Parent:GetAttribute("CandidateSHA256") == 64)
		local count = 0
		for _, item in ipairs(modules.Parent:GetDescendants()) do
			if item:IsA("LuaSourceContainer") then
				count += 1
				for _, token in ipairs({"GetAsync", "PostAsync", "RequestAsync", "loadstring", "TechnicalGate", "JointForgeV11", "AnalyticsService"}) do assert(not item.Source:find(token, 1, true)) end
			end
		end
		assert(count == sourceCount)
	end)

	for id = 1, 56 do
		local status = matrix[id] == true and "PASS" or matrix[id] == false and "FAIL" or "NON TESTED"
		print(string.format("[JointForgeV11][MATRIX] %02d %s", id, status))
		if matrix[id] ~= true then fail += 1 end
	end
	print(string.format("[JointForgeV11][SUMMARY] %d PASS / %d FAIL", pass, fail))
	return fail == 0
end
