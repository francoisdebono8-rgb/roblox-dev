local Schema = require(script.Parent.Schema)
local Graph = require(script.Parent.Graph)
local Planner = {}
local issued = setmetatable({}, { __mode = "k" })

local function copy(value, visiting, budget, depth)
	if type(value) ~= "table" then return value end
	assert(not getmetatable(value) and not visiting[value] and depth <= 16, "Invalid/cyclic request table.")
	visiting[value] = true
	local out = {}
	for key, child in pairs(value) do
		budget.n += 1; assert(budget.n <= Graph.limits.requestValues, "Request value cap exceeded.")
		assert(type(key) == "number" or type(key) == "string", "Invalid request key.")
		out[key] = copy(child, visiting, budget, depth + 1)
	end
	visiting[value] = nil
	return out
end

local function freeze(value)
	if type(value) ~= "table" or table.isfrozen(value) then return end
	for _, child in pairs(value) do freeze(child) end
	table.freeze(value)
end

local function array(values, limit, message)
	assert(type(values) == "table" and #values > 0 and #values <= limit, message)
	local count = 0
	for key in pairs(values) do
		assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #values, "Expected a dense ordered array.")
		count += 1
	end
	assert(count == #values, "Expected a dense ordered array.")
end

function Planner.preview(world, input)
	local plan = { world = world, operations = {}, errors = {}, warnings = {}, diagnostics = {}, metrics = {} }
	local state = { phase = "issued", seeds = {}, selected = {}, nameParents = {} }
	local function diagnostic(code, message, severity, joint)
		table.insert(plan.diagnostics, { code = code, message = message, severity = severity, joint = joint })
		if severity == "error" then table.insert(plan.errors, message)
		elseif severity == "warning" then table.insert(plan.warnings, message) end
	end
	local function need(condition, code, message)
		if not condition then diagnostic(code, message, "error"); error(message, 0) end
	end
	local function seed(item) if item then table.insert(state.seeds, item) end end
	local function part(item)
		need(typeof(item) == "Instance" and item:IsA("BasePart") and item:IsDescendantOf(world),
			"broken-endpoint", "Choose a BasePart inside Workspace.")
		seed(item)
	end
	local reserved, index, projected = {}, nil, 0
	local function name(parent, base)
		state.nameParents[parent] = true
		if not reserved[parent] then reserved[parent] = table.clone(index.childNames[parent] or {}) end
		local candidate, i = base, 1
		while reserved[parent][candidate] do i += 1; candidate = base .. "_" .. i end
		reserved[parent][candidate] = true
		return candidate
	end
	local function add(op)
		projected += 1
		for _, attachment in ipairs(op.attachments or {}) do if not attachment.existing then projected += 1 end end
		assert(projected <= Graph.limits.operations, "Planned operation cap exceeded.")
		table.insert(plan.operations, op)
	end
	local function validJoint(joint)
		assert(typeof(joint) == "Instance" and joint:IsDescendantOf(world) and Graph.isJoint(joint), "Choose an existing joint/constraint.")
		assert(Schema.supported(joint), "This class is inspect-only; mixed removals are refused wholly.")
		state.selected[joint] = true
		local a, b, ea, eb = Graph.endpoints(joint)
		seed(a); seed(b); seed(ea); seed(eb)
		for _, d in ipairs(Graph.diagnostics(joint, world)) do diagnostic(d.code, d.message, "info", joint) end
	end
	local function conflict(class, a, b, batch)
		part(a); part(b)
		need(a ~= b, "same-endpoint", "Part0 and Part1 must be different.")
		local category = class == "NoCollisionConstraint" and "collision" or "physical"
		local direct = index.direct[a][b]
		if direct and direct[category] then
			diagnostic("direct-duplicate", "An exact endpoint pair already has a " .. category .. " connection.", "error", direct[category])
		elseif category == "physical" and index.components[a] == index.components[b] then
			diagnostic("indirect-path", "Endpoints are already connected through a physical joint path.", "error")
		end
		if batch then
			for _, edge in ipairs(index.adjacency[b]) do
				if not edge.noCollision then diagnostic("batch-connected", "Batch child already has a physical connection.", "error", edge.joint); break end
			end
		end
		if a.Anchored and b.Anchored then diagnostic("anchored-both", "Both endpoints are anchored; no motion until explicitly unanchored.", "warning") end
	end
	local function attachment(existing, endpoint, worldFrame, suffix)
		if existing then
			need(typeof(existing) == "Instance" and existing:IsA("Attachment") and existing.Parent == endpoint,
				"attachment-ancestry", "Attachments must be direct children of their endpoint BaseParts.")
			seed(existing)
			return { existing = existing, part = endpoint, world = existing.WorldCFrame, localFrame = existing.CFrame }
		end
		assert(typeof(worldFrame) == "CFrame" and Schema.validValue(worldFrame), "A finite attachment world CFrame is required.")
		return { part = endpoint, world = worldFrame, localFrame = endpoint.CFrame:ToObjectSpace(worldFrame),
			name = name(endpoint, "JF_Attachment" .. suffix) }
	end
	local function attachmentWarnings(class, attachments)
		local cf0, cf1 = attachments[1].world, attachments[2].world
		local length = (cf0.Position - cf1.Position).Magnitude
		assert(Schema.finite(length), "Attachment distance must be finite.")
		if class == "HingeConstraint" or class == "BallSocketConstraint" then
			if length > 0.001 then diagnostic("separated-pivot", "Attachment pivots are separated; simulation may move parts.", "warning") end
			if class == "HingeConstraint" and cf0.XVector:Dot(cf1.XVector) < 0.999 then diagnostic("hinge-axis", "Hinge axes are not aligned.", "warning") end
		end
		return length
	end
	local function create(class, a, b, at0, at1, batch)
		assert(Schema.fields[class], "Unsupported joint type.")
		conflict(class, a, b, batch)
		local op = { kind = "create", class = class, a = a, b = b, name = name(a, "JF_" .. class .. "_" .. b.Name), parent = a, preservePose = true }
		local changes = {}
		if Schema.usesAttachments(class) then
			local pivot = CFrame.new((a.Position + b.Position) / 2) * a.CFrame.Rotation
			if at0 then attachment(at0, a, nil, "0"); pivot = at0.WorldCFrame
			elseif at1 then attachment(at1, b, nil, "1"); pivot = at1.WorldCFrame end
			local pivots = class == "HingeConstraint" or class == "BallSocketConstraint"
			op.attachments = { attachment(at0, a, pivots and pivot or a.CFrame, "0"), attachment(at1, b, pivots and pivot or b.CFrame, "1") }
			op.attachment0, op.attachment1 = at0, at1
			op.length = attachmentWarnings(class, op.attachments)
			if class == "RopeConstraint" or class == "RodConstraint" or class == "SpringConstraint" then
				assert(op.length >= (class == "RodConstraint" and 0.2 or class == "SpringConstraint" and 0.1 or 0.001), "Endpoint distance is too small for this constraint.")
				changes[class == "SpringConstraint" and "FreeLength" or "Length"] = op.length
			end
			changes.Visible = true
		elseif class == "Weld" or class == "Motor6D" then
			changes.C0, changes.C1 = a.CFrame:ToObjectSpace(b.CFrame), CFrame.identity
		end
		local probe = Instance.new(class)
		local ok, values = pcall(Schema.validateChanges, probe, changes); probe:Destroy(); assert(ok, values)
		op.values = values
		add(op)
	end
	local ok, err = pcall(function()
		assert(typeof(world) == "Instance" and (world == workspace or world:IsDescendantOf(workspace)), "Workspace edit scope required.")
		plan.request = copy(input, {}, { n = 0 }, 0)
		local request = plan.request
		assert(type(request) == "table", "Supply an explicit request.")
		state.excluded = if request.kind == "reassign" then request.joint else nil
		index = Graph.build(world, state.excluded); plan.metrics = table.clone(index.metrics)
		if request.kind == "create" then
			create(request.class, request.a, request.b, request.attachment0, request.attachment1, false)
		elseif request.kind == "batch" then
			part(request.root); array(request.entries, Graph.limits.batch, "Batch entry cap exceeded or empty batch.")
			local seen = {}
			for _, entry in ipairs(request.entries) do
				assert(type(entry) == "table" and entry.part ~= request.root, "Root cannot also be a batch child.")
				assert(entry.part and not seen[entry.part], "Duplicate batch part."); seen[entry.part] = true
				assert(entry.mode == "Static" or entry.mode == "Moving", "Classify each part as Static or Moving.")
				create(entry.mode == "Static" and "WeldConstraint" or "Motor6D", request.root, entry.part, nil, nil, true)
			end
		elseif request.kind == "edit" then
			validJoint(request.joint)
			local before = Schema.read(request.joint)
			local values = Schema.validateChanges(request.joint, request.changes)
			assert(next(request.changes), "Change at least one field.")
			add({ kind = "edit", class = request.joint.ClassName, joint = request.joint, before = before, values = values,
				changes = request.changes, order = Schema.writeOrder(request.joint.ClassName, before, values) })
			if request.changes.C0 or request.changes.C1 then diagnostic("raw-frame", "C0/C1 edits can move the assembly; identity reset does not preserve pose.", "warning") end
		elseif request.kind == "reassign" then
			local joint = request.joint; validJoint(joint)
			assert(request.endpoint0 ~= nil or request.endpoint1 ~= nil, "Explicit new endpoint input is required.")
			assert(request.poseMode == nil or request.poseMode == "preserve" or request.poseMode == "raw", "Unknown pose mode.")
			local a, b, old0, old1 = Graph.endpoints(joint)
			local op = { kind = "reassign", class = joint.ClassName, joint = joint, before = Schema.read(joint),
				old0 = old0, old1 = old1, preservePose = request.poseMode ~= "raw" }
			if Schema.usesAttachments(joint.ClassName) then
				local function resolve(spec, previous, suffix)
					if spec == nil then spec = previous end
					if typeof(spec) == "Instance" then
						need(spec:IsA("Attachment") and spec.Parent and spec.Parent:IsA("BasePart"), "attachment-ancestry", "Supply a direct-child Attachment.")
						part(spec.Parent); return attachment(spec, spec.Parent, nil, suffix)
					end
					assert(type(spec) == "table" and spec.create == true, "Explicit Attachment or {create=true, part, worldCFrame} required.")
					part(spec.part); return attachment(nil, spec.part, spec.worldCFrame, suffix)
				end
				op.attachments = { resolve(request.endpoint0, old0, "0"), resolve(request.endpoint1, old1, "1") }
				a, b = op.attachments[1].part, op.attachments[2].part
				attachmentWarnings(joint.ClassName, op.attachments)
			else
				a, b = request.endpoint0 or a, request.endpoint1 or b
			end
			conflict(joint.ClassName, a, b, false); op.a, op.b = a, b
			local changes = {}
			if joint:IsA("Weld") or joint:IsA("Motor6D") then
				if op.preservePose then
					-- Transform timing is deferred by Studio. Refuse nonidentity transforms
					-- until edit-mode preservation is established by the native release gate.
					assert(not joint:IsA("Motor6D") or Graph.equal(joint.Transform, CFrame.identity), "Preserve pose requires identity Motor6D.Transform; use explicit raw mode otherwise.")
					changes.C0 = a.CFrame:ToObjectSpace(b.CFrame * joint.C1)
				else diagnostic("raw-frame", "Raw endpoint reassignment retains C0/C1 and may move connected parts.", "warning") end
			end
			op.values = Schema.validateChanges(joint, changes)
			op.order = Schema.writeOrder(joint.ClassName, op.before, op.values)
			add(op)
		elseif request.kind == "remove" then
			array(request.joints, Graph.limits.remove, "Removal count cap exceeded or empty removal.")
			for _, joint in ipairs(request.joints) do
				assert(not state.selected[joint], "Duplicate removal.")
				validJoint(joint)
				assert(#joint:GetChildren() == 0, "Move children out of the joint before removal.")
				add({ kind = "remove", joint = joint, parent = joint.Parent })
			end
		else error("Unknown action.") end
		plan.fingerprint = Graph.fingerprint(index, state.seeds, state.selected, state.nameParents)
		plan.snapshot = plan.fingerprint.objects
		plan.metrics.projectedOperations = projected
	end)
	if not ok then
		if #plan.errors == 0 then diagnostic("invalid-request", tostring(err), "error") end
		plan.operations = {}
	end
	freeze(plan); issued[plan] = state
	return plan
end

function Planner.invalidate(plan)
	local state = issued[plan]; if state then state.invalidated = true end
end

function Planner.check(plan, applying)
	local state = issued[plan]
	assert(state, "Only an exact engine-issued plan can be applied.")
	assert(not state.invalidated, "Inputs changed since Preview.")
	assert(state.phase == (applying and "applying" or "issued"), "Preview already consumed; Preview again.")
	assert(#plan.errors == 0 and #plan.operations > 0, "Resolve Preview errors before Apply.")
	local index = Graph.build(plan.world, state.excluded)
	assert(Graph.equal(plan.fingerprint, Graph.fingerprint(index, state.seeds, state.selected, state.nameParents)), "Relevant graph changed since Preview.")
end

function Planner.consume(plan)
	local state = issued[plan]
	assert(state and state.phase == "issued" and not state.invalidated, "Preview is not available.")
	state.phase = "applying"
end

function Planner.finish(plan)
	local state = issued[plan]; if state then state.phase = "consumed" end
end

return Planner
