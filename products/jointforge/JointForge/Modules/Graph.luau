local Schema = require(script.Parent.Schema)
local Graph = {}

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

function Graph.all(world)
	local result = {}
	for _, item in ipairs(world:GetDescendants()) do
		if Graph.isJoint(item) then table.insert(result, item) end
	end
	return result
end

function Graph.inspect(world, selection)
	local result = {}
	local function included(item)
		if not item then return false end
		for _, selected in ipairs(selection) do
			if selected == item or item:IsDescendantOf(selected) then return true end
		end
		return false
	end
	for _, joint in ipairs(Graph.all(world)) do
		local a, b, ea, eb = Graph.endpoints(joint)
		if included(joint) or included(a) or included(b) or included(ea) or included(eb) then
			local expectsPair = Schema.supported(joint) or joint:IsA("JointInstance")
			local broken = expectsPair and (not a or not b or not a:IsDescendantOf(world) or not b:IsDescendantOf(world) or a == b)
			table.insert(result, { joint = joint, a = a, b = b, endpoint0 = ea, endpoint1 = eb, broken = broken })
		end
	end
	table.sort(result, function(a, b) return a.joint:GetFullName() < b.joint:GetFullName() end)
	return result
end

function Graph.equal(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in pairs(a) do if not Graph.equal(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end

function Graph.snapshot(world, extra)
	local result = {}
	local function capture(item)
		if not item or result[item] then return end
		local state = { parent = item.Parent, name = item.Name }
		result[item] = state
		if item:IsA("BasePart") then state.cf = item.CFrame; state.anchored = item.Anchored end
		if item:IsA("Attachment") then state.cf = item.WorldCFrame end
	end
	for _, joint in ipairs(Graph.all(world)) do
		capture(joint)
		local a, b, ea, eb = Graph.endpoints(joint)
		local state = result[joint]
		state.a, state.b, state.ea, state.eb = a, b, ea, eb
		capture(a); capture(b); capture(ea); capture(eb)
		for _, field in ipairs(Schema.fields[joint.ClassName] or { "Enabled" }) do
			local ok, value = pcall(function() return joint[field] end)
			if ok then state[field] = value end
		end
	end
	for _, item in ipairs(extra or {}) do capture(item) end
	return result
end

return Graph
