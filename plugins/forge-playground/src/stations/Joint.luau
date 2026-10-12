local Root = script.Parent.Parent
local V = require(Root.Visuals)
local Graph = require(Root.ProductModules.Joint.Graph)
local Planner = require(Root.ProductModules.Joint.Planner)
local Joint = {}; Joint.__index = Joint
local rank = { ["broken-endpoint"] = 1, ["direct-duplicate"] = 2, ["separated-pivot"] = 3, ["hinge-axis"] = 4, ["anchored-both"] = 5 }
function Joint.new(station)
	local self = setmetatable({ station = station }, Joint); self:reset(); return self
end
function Joint:leave() self.findings, self.selected, self.plan = nil, nil, nil end
function Joint:reset()
	self:leave(); self.station.contents:ClearAllChildren()
	local s = self.station
	self.fixture = V.folder(s.contents, "ServiceDoor", "Model")
	self.frame = V.part(s, self.fixture, "Frame", Vector3.new(1, 11, 2), Vector3.new(-10, 5.7, 0), Color3.fromRGB(166, 177, 186), Enum.Material.Metal)
	self.door = V.part(s, self.fixture, "Door", Vector3.new(7, 9, 0.8), Vector3.new(-5.7, 5.7, 0), Color3.fromRGB(212, 156, 65), Enum.Material.Metal)
	self.handlePart = V.part(s, self.fixture, "Handle", Vector3.new(0.7, 2.5, 1.4), Vector3.new(-3, 5.7, 1.2), Color3.fromRGB(237, 218, 180), Enum.Material.Metal)
	V.part(s, self.fixture, "Lintel", Vector3.new(10, 1, 2), Vector3.new(-5.5, 11.2, 0), Color3.fromRGB(166, 177, 186), Enum.Material.Metal)
	for i = 1, 2 do
		local weld = Instance.new("WeldConstraint")
		weld.Name, weld.Part0, weld.Part1, weld.Parent = "FrameLink" .. i, self.frame, self.door, self.frame
	end
	local broken = Instance.new("WeldConstraint")
	broken.Name, broken.Part0, broken.Parent = "MissingHandleLink", self.door, self.door
	self.hingeBase = V.part(s, self.fixture, "HingeBase", Vector3.new(1, 7, 2), Vector3.new(7, 3.7, 0), Color3.fromRGB(150, 170, 186), Enum.Material.Metal)
	self.hatch = V.part(s, self.fixture, "Hatch", Vector3.new(6, 6, 0.6), Vector3.new(10.5, 4, 0), Color3.fromRGB(136, 185, 165), Enum.Material.Metal)
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Name, a.Parent, a.Position = "BasePivot", self.hingeBase, Vector3.new(0.5, 0, 0)
	b.Name, b.Parent, b.CFrame = "OffsetPivot", self.hatch, CFrame.new(-2, 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2)
	local hinge = Instance.new("HingeConstraint")
	hinge.Name, hinge.Attachment0, hinge.Attachment1, hinge.Parent = "MisalignedHinge", a, b, self.hingeBase
	hinge.Enabled = false
	self.summary, self.message = "Service door / real joints and attachments", "Scan, select an issue, then choose a repair."
end
function Joint:diagnostics()
	local findings, seen = {}, {}
	local function add(d, joint)
		seen[joint] = seen[joint] or {}
		if not seen[joint][d.code] then
			seen[joint][d.code] = true
			table.insert(findings, { joint = joint, code = d.code, message = d.message })
		end
	end
	for _, edge in ipairs(Graph.inspect(self.fixture, { self.fixture })) do
		for _, d in ipairs(edge.diagnostics) do add(d, edge.joint) end
		-- Graph inspection diagnoses local state; the real planner diagnoses connection conflicts.
		if edge.a and edge.b then
			local plan = Planner.preview(self.fixture, { kind = "reassign", joint = edge.joint, endpoint0 = edge.endpoint0, endpoint1 = edge.endpoint1 })
			for _, d in ipairs(plan.diagnostics) do
				if d.code == "direct-duplicate" or d.code == "indirect-path" then add(d, edge.joint) end
			end
		end
	end
	table.sort(findings, function(a, b)
		if (rank[a.code] or 99) ~= (rank[b.code] or 99) then return (rank[a.code] or 99) < (rank[b.code] or 99) end
		return a.joint.Name < b.joint.Name
	end)
	return findings
end
function Joint:prepare(options)
	self.plan = nil
	local finding = self.findings and self.findings[self.selected]
	if not finding then return end
	local input
	if finding.code == "broken-endpoint" then
		input = { kind = "reassign", joint = finding.joint, endpoint1 = options.endpoint == "Handle" and self.handlePart or self.door }
	elseif finding.code == "direct-duplicate" or finding.code == "indirect-path" then
		input = { kind = "remove", joints = { finding.joint } }
	elseif finding.code == "hinge-axis" or finding.code == "separated-pivot" then
		local joint = finding.joint
		local a, b = Graph.endpoints(joint)
		local frame = joint.Attachment0.WorldCFrame
		input = { kind = "reassign", joint = joint, endpoint0 = joint.Attachment0,
			endpoint1 = { create = true, part = b, worldCFrame = frame } }
	end
	if input then
		self.plan = Planner.preview(self.fixture, input)
		self.message = #self.plan.errors > 0 and table.concat(self.plan.errors, "\n") or (input.kind == "remove" and "Explicit repair: remove selected redundant joint" or "Explicit repair: reassign selected endpoints")
	else self.message = "Diagnostic only / anchors stay unchanged in this fixture" end
end
function Joint:scan(options)
	self.findings = self:diagnostics(); self.selected = #self.findings > 0 and 1 or nil
	self.summary = string.format("%d joints scanned / %d findings", #Graph.inspect(self.fixture, { self.fixture }), #self.findings)
	self:prepare(options)
end
function Joint:apply()
	local plan = assert(self.plan, "Select a repairable issue.")
	Planner.check(plan); assert(#plan.operations == 1, "Demo repairs one joint at a time.")
	local op = plan.operations[1]
	assert(op.joint:IsDescendantOf(self.fixture), "Outside the fixture.")
	Planner.consume(plan)
	if op.kind == "remove" then
		op.joint:Destroy()
	elseif op.kind == "reassign" then
		local joint, created = op.joint, {}
		local ok, err = pcall(function()
			if op.attachments then
				local endpoints = {}
				for i, spec in ipairs(op.attachments) do
					assert(spec.part:IsDescendantOf(self.fixture), "Outside the fixture.")
					local a = spec.existing
					if not a then
						a = Instance.new("Attachment"); table.insert(created, a)
						a.Name, a.CFrame, a.Parent = spec.name, spec.localFrame, spec.part
					end
					endpoints[i] = a
				end
				joint.Attachment0, joint.Attachment1 = endpoints[1], endpoints[2]
			else
				assert(op.a:IsDescendantOf(self.fixture) and op.b:IsDescendantOf(self.fixture), "Outside the fixture.")
				joint.Part0, joint.Part1 = op.a, op.b
			end
		end)
		if not ok then
			if op.attachments then joint.Attachment0, joint.Attachment1 = op.old0, op.old1 else joint.Part0, joint.Part1 = op.old0, op.old1 end
			for _, a in ipairs(created) do a:Destroy() end
			Planner.finish(plan); error(err)
		end
	else error("Unsupported Playground joint operation.") end
	Planner.finish(plan); self.plan = nil
end
function Joint:handle(action, options, index)
	if action == "run" then self:scan(options)
	elseif action == "select" and self.findings and self.findings[index] then self.selected = index; self:prepare(options)
	elseif action == "configure" then self:prepare(options)
	elseif action == "apply" then
		self:apply(); self:scan(options); self.message = "Repair applied / real diagnostics rescanned"
	end
end
function Joint:state()
	local rows, highlights = {}, {}
	for _, finding in ipairs(self.findings or {}) do
		local a, b = Graph.endpoints(finding.joint)
		table.insert(rows, { title = finding.joint.Name .. " / " .. finding.code, detail = finding.message .. "\nEndpoint 0: " .. (a and a.Name or "Missing") .. "\nEndpoint 1: " .. (b and b.Name or "Missing"), instance = b or a })
	end
	local finding = self.findings and self.findings[self.selected]
	if finding then
		local a, b = Graph.endpoints(finding.joint)
		if a then table.insert(highlights, a) end; if b then table.insert(highlights, b) end
	end
	return { summary = self.summary, message = self.message, rows = rows, selected = self.selected, highlights = highlights,
		canApply = self.plan ~= nil and #self.plan.errors == 0 and #self.plan.operations > 0 }
end
return Joint
