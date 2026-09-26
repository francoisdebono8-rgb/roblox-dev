local Schema = require(script.Parent.Schema)
local Graph = require(script.Parent.Graph)
local Planner = {}

local function clone(value)
	if type(value) ~= "table" then return value end
	local out = {}
	for k, v in pairs(value) do out[k] = clone(v) end
	return out
end

function Planner.preview(world, request)
	local plan = { request = clone(request), world = world, operations = {}, errors = {}, warnings = {}, extra = {}, used = false }
	local function add(list, message) table.insert(plan[list], message) end
	local function part(p)
		assert(typeof(p) == "Instance" and p:IsA("BasePart") and p:IsDescendantOf(world), "Choose a BasePart inside Workspace.")
		table.insert(plan.extra, p)
	end
	local joints = Graph.all(world)
	local function pair(class, a, b, attachment0, attachment1, batch)
		assert(Schema.fields[class], "Unsupported joint type.")
		part(a); part(b)
		assert(a ~= b, "Part0 and Part1 must be different.")
		local noCollision = class == "NoCollisionConstraint"
		for _, joint in ipairs(joints) do
			local x, y = Graph.endpoints(joint)
			local same = (x == a and y == b) or (x == b and y == a)
			local otherNoCollision = joint:IsA("NoCollisionConstraint")
			if (same and noCollision == otherNoCollision) or (batch and not otherNoCollision and (x == b or y == b)) then
				add("errors", b.Name .. ": existing connection " .. joint:GetFullName() .. " (preserved).")
			end
		end
		-- Also reject indirect connections; a duplicate assembly path can lock a moving part.
		if not noCollision then
			local seen, queue = { [a] = true }, { a }
			local index = 1
			while queue[index] do
				local current = queue[index]; index += 1
				for _, joint in ipairs(joints) do
					if not joint:IsA("NoCollisionConstraint") then
						local x, y = Graph.endpoints(joint)
						local nextPart = if x == current then y elseif y == current then x else nil
						if nextPart and not seen[nextPart] then seen[nextPart] = true; table.insert(queue, nextPart) end
					end
				end
			end
			if seen[b] then add("errors", b.Name .. ": already connected to the root through a joint path.") end
		end
		local op = { kind = "create", class = class, a = a, b = b, attachment0 = attachment0, attachment1 = attachment1 }
		if Schema.usesAttachments(class) then
			for i, attachment in pairs({ [0] = attachment0, [1] = attachment1 }) do
				local endpoint = if i == 0 then a else b
				assert(attachment:IsA("Attachment") and attachment.Parent == endpoint, "Existing attachments must be direct children of their endpoint parts.")
				table.insert(plan.extra, attachment)
			end
			local pivot = CFrame.new((a.Position + b.Position) / 2) * a.CFrame.Rotation
			if class == "HingeConstraint" or class == "BallSocketConstraint" then
				pivot = if attachment0 then attachment0.WorldCFrame elseif attachment1 then attachment1.WorldCFrame else pivot
				op.world0, op.world1 = pivot, pivot
			else op.world0, op.world1 = a.CFrame, b.CFrame end
			local cf0 = if attachment0 then attachment0.WorldCFrame else op.world0
			local cf1 = if attachment1 then attachment1.WorldCFrame else op.world1
			op.length = (cf0.Position - cf1.Position).Magnitude
			if class == "HingeConstraint" or class == "BallSocketConstraint" then
				if op.length > 0.001 then add("warnings", "Attachment pivots are separated; simulation may move the parts.") end
				if class == "HingeConstraint" and cf0.XVector:Dot(cf1.XVector) < 0.999 then add("warnings", "Hinge axes are not aligned; align the attachments before simulation.") end
			end
		end
		if a.Anchored and b.Anchored then add("warnings", b.Name .. ": both endpoints are anchored; no physical motion until you explicitly unanchor a part.") end
		table.insert(plan.operations, op)
	end
	local ok, err = pcall(function()
		if request.kind == "create" then
			pair(request.class, request.a, request.b, request.attachment0, request.attachment1, false)
		elseif request.kind == "batch" then
			part(request.root)
			local seen = {}
			assert(#request.entries > 0, "Add at least one Static or Moving part.")
			for _, entry in ipairs(request.entries) do
				assert(not seen[entry.part], "Duplicate batch part."); seen[entry.part] = true
				assert(entry.mode == "Static" or entry.mode == "Moving", "Classify each part as Static or Moving.")
				pair(if entry.mode == "Static" then "WeldConstraint" else "Motor6D", request.root, entry.part, nil, nil, true)
			end
		elseif request.kind == "edit" then
			local joint = request.joint
			assert(joint and joint:IsDescendantOf(world), "The joint is no longer in Workspace.")
			Schema.validateChanges(joint, request.changes)
			assert(next(request.changes), "Change at least one field.")
			table.insert(plan.operations, { kind = "edit", joint = joint, changes = clone(request.changes) })
			if request.changes.C0 or request.changes.C1 then add("warnings", "Changing C0/C1 can move the connected assembly. Reset means identity, not preserve pose.") end
		elseif request.kind == "remove" then
			assert(#request.joints > 0, "Choose joints to remove.")
			local seen = {}
			for _, joint in ipairs(request.joints) do
				assert(joint:IsDescendantOf(world) and Graph.isJoint(joint), "Select only existing joints/constraints.")
				assert(#joint:GetChildren() == 0, "Move children out of " .. joint.Name .. " before removing it.")
				assert(not seen[joint], "Duplicate removal."); seen[joint] = true
				table.insert(plan.operations, { kind = "remove", joint = joint })
			end
		else error("Unknown action.") end
	end)
	if not ok then add("errors", tostring(err)) end
	plan.snapshot = Graph.snapshot(world, plan.extra)
	return plan
end

function Planner.check(plan)
	assert(not plan.invalidated, "Inputs changed since Preview. Preview again.")
	assert(not plan.used, "Preview already applied. Preview again.")
	assert(#plan.errors == 0 and #plan.operations > 0, "Resolve Preview conflicts before Apply.")
	assert(Graph.equal(plan.snapshot, Graph.snapshot(plan.world, plan.extra)), "Workspace changed since Preview. Preview again.")
	local fresh = Planner.preview(plan.world, plan.request)
	assert(#fresh.errors == 0 and Graph.equal(plan.operations, fresh.operations), "Preview is stale. Preview again.")
end

return Planner
