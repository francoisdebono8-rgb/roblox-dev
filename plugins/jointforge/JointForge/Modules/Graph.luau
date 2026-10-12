local Schema = require(script.Parent.Schema)
local Graph = {}

Graph.limits = table.freeze({ scan = 20000, nodes = 8000, edges = 8000, component = 4000, depth = 128,
	batch = 256, operations = 128, remove = 256, requestValues = 8192 })
local identities, nextIdentity = setmetatable({}, { __mode = "k" }), 0
function Graph.id(item)
	if not identities[item] then nextIdentity += 1; identities[item] = nextIdentity end
	return identities[item]
end

function Graph.isJoint(item)
	return item:IsA("JointInstance") or item:IsA("Constraint") or item:IsA("WeldConstraint") or item:IsA("NoCollisionConstraint")
end

function Graph.endpoints(joint)
	if joint:IsA("JointInstance") or joint:IsA("WeldConstraint") or joint:IsA("NoCollisionConstraint") then
		return joint.Part0, joint.Part1, joint.Part0, joint.Part1
	end
	local a, b = joint.Attachment0, joint.Attachment1
	local function part(attachment)
		return attachment and attachment:FindFirstAncestorWhichIsA("BasePart")
	end
	return part(a), part(b), a, b
end

function Graph.equal(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if typeof(a) == "CFrame" then
		local x, y = { a:GetComponents() }, { b:GetComponents() }
		for i, value in ipairs(x) do if value ~= y[i] then return false end end
		return true
	end
	if type(a) ~= "table" then return a == b end
	for key, value in pairs(a) do if not Graph.equal(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end

function Graph.ancestry(item)
	local result = {}
	while item do
		assert(#result < Graph.limits.depth, "Hierarchy depth cap exceeded.")
		table.insert(result, item); item = item.Parent
	end
	return result
end

function Graph.diagnostics(joint, world)
	local result = {}
	local function add(code, message) table.insert(result, { code = code, message = message, joint = joint }) end
	if not Schema.supported(joint) then add("inspect-only", "Unsupported class: inspect only.") end
	local a, b, ea, eb = Graph.endpoints(joint)
	if Schema.supported(joint) or joint:IsA("JointInstance") then
		if not a or not b or not a:IsDescendantOf(world) or not b:IsDescendantOf(world) then add("broken-endpoint", "Missing or detached endpoint.") end
		if a and a == b then add("same-endpoint", "Both endpoints refer to the same part.") end
	end
	if Schema.usesAttachments(joint.ClassName) then
		if (ea and ea.Parent ~= a) or (eb and eb.Parent ~= b) then add("attachment-ancestry", "Attachments must be direct children of BaseParts.") end
		if ea and eb and a and b then
			if joint:IsA("HingeConstraint") or joint:IsA("BallSocketConstraint") then
				if (ea.WorldPosition - eb.WorldPosition).Magnitude > 0.001 then add("separated-pivot", "Attachment pivots are separated.") end
			end
			if joint:IsA("HingeConstraint") and ea.WorldCFrame.XVector:Dot(eb.WorldCFrame.XVector) < 0.999 then add("hinge-axis", "Hinge axes are not aligned.") end
		end
	end
	if a and b and a.Anchored and b.Anchored then add("anchored-both", "Both endpoints are anchored.") end
	return result
end

-- One bounded hierarchy walk; subsequent pair/component queries use this index.
function Graph.build(world, excluded)
	local index = { world = world, joints = {}, edges = {}, nodes = {}, adjacency = {}, direct = {}, components = {},
		childNames = {}, metrics = { scans = 1, visited = 0, nodes = 0, edges = 0, componentVisits = 0 } }
	local queue, cursor = { world }, 1
	while queue[cursor] do
		local parent = queue[cursor]; cursor += 1
		local children = parent:GetChildren()
		assert(index.metrics.visited + #children <= Graph.limits.scan, "Hierarchy scan cap exceeded; no partial graph.")
		index.metrics.visited += #children
		index.childNames[parent] = {}
		for _, item in ipairs(children) do
			Graph.id(item); index.childNames[parent][item.Name] = true
			table.insert(queue, item)
			if item:IsA("BasePart") then
				index.metrics.nodes += 1; assert(index.metrics.nodes <= Graph.limits.nodes, "Graph node cap exceeded.")
				index.nodes[item], index.adjacency[item], index.direct[item] = true, {}, {}
			end
			if Graph.isJoint(item) then
				assert(#index.joints < Graph.limits.edges, "Joint/constraint scan cap exceeded.")
				table.insert(index.joints, item)
			end
		end
	end
	table.sort(index.joints, function(a, b) return Graph.id(a) < Graph.id(b) end)
	for _, joint in ipairs(index.joints) do
		local a, b, ea, eb = Graph.endpoints(joint)
		local edge = { joint = joint, a = a, b = b, endpoint0 = ea, endpoint1 = eb, noCollision = joint:IsA("NoCollisionConstraint") }
		table.insert(index.edges, edge)
		if a and index.nodes[a] then table.insert(index.adjacency[a], edge) end
		if b and b ~= a and index.nodes[b] then table.insert(index.adjacency[b], edge) end
		if joint ~= excluded and index.nodes[a] and index.nodes[b] then
			local function direct(x, y)
				index.direct[x][y] = index.direct[x][y] or {}
				index.direct[x][y][edge.noCollision and "collision" or "physical"] = joint
			end
			direct(a, b); direct(b, a)
		end
	end
	index.metrics.edges = #index.edges
	for _, seed in ipairs(queue) do
		if index.nodes[seed] and not index.components[seed] then
			local pending, i = { seed }, 1
			index.components[seed] = seed
			while pending[i] do
				local current = pending[i]; i += 1; index.metrics.componentVisits += 1
				assert(#pending <= Graph.limits.component, "Connected-component traversal cap exceeded.")
				for _, edge in ipairs(index.adjacency[current]) do
					if edge.joint ~= excluded and not edge.noCollision then
						local other = if edge.a == current then edge.b else edge.a
						if other and index.nodes[other] and not index.components[other] then
							index.components[other] = seed; table.insert(pending, other)
						end
					end
				end
			end
		end
	end
	return index
end

function Graph.all(world) return Graph.build(world).joints end

function Graph.inspect(world, selection)
	assert(#selection <= Graph.limits.nodes, "Selection cap exceeded.")
	local index, result = Graph.build(world), {}
	local function included(item)
		if not item then return false end
		for _, selected in ipairs(selection) do if item == selected or item:IsDescendantOf(selected) then return true end end
		return false
	end
	for _, edge in ipairs(index.edges) do
		if included(edge.joint) or included(edge.a) or included(edge.b) or included(edge.endpoint0) or included(edge.endpoint1) then
			local diagnostics = Graph.diagnostics(edge.joint, world)
			local broken = false
			for _, d in ipairs(diagnostics) do if d.code == "broken-endpoint" or d.code == "same-endpoint" or d.code == "attachment-ancestry" then broken = true end end
			edge.broken, edge.diagnostics = broken, diagnostics
			table.insert(result, edge)
		end
	end
	return result
end

function Graph.capture(item)
	local state = { parent = item.Parent, ancestry = Graph.ancestry(item), name = item.Name }
	if item:IsA("BasePart") then state.cf, state.anchored = item.CFrame, item.Anchored end
	if item:IsA("Attachment") then state.cf, state.world = item.CFrame, item.WorldCFrame end
	if Graph.isJoint(item) then
		state.a, state.b, state.ea, state.eb = Graph.endpoints(item)
		for _, field in ipairs(Schema.fields[item.ClassName] or {}) do state[field] = item[field] end
		if item:IsA("Motor6D") then state.Transform = item.Transform end
	end
	return state
end

function Graph.fingerprint(index, seeds, selected, nameParents)
	local snapshot, components = {}, {}
	local function capture(item)
		if item and not snapshot[item] then snapshot[item] = Graph.capture(item) end
	end
	for _, item in ipairs(seeds) do
		capture(item)
		if index.components[item] then components[index.components[item]] = true end
	end
	local relevant = {}
	for node, component in pairs(index.components) do if components[component] then relevant[node] = true; capture(node) end end
	for _, edge in ipairs(index.edges) do
		if relevant[edge.a] or relevant[edge.b] or selected[edge.joint] then
			capture(edge.joint); capture(edge.a); capture(edge.b); capture(edge.endpoint0); capture(edge.endpoint1)
		end
	end
	for item in pairs(selected) do
		capture(item)
		local children = item:GetChildren()
		assert(#children <= Graph.limits.scan, "Selected child-content cap exceeded.")
		local identitiesSet = {}; for _, child in ipairs(children) do identitiesSet[child] = true end
		snapshot[item].children = identitiesSet
	end
	local names = {}
	for parent in pairs(nameParents) do names[parent] = index.childNames[parent] or {} end
	return { objects = snapshot, names = names }
end

return Graph
