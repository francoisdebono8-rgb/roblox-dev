local Root = script.Parent.Parent
local V = require(Root.Visuals)
local Engine = require(Root.ProductModules.Schema.Engine)
local SchemaModule = require(Root.ProductModules.Schema.Schema)
local Station = {}; Station.__index = Station
function Station.new(station)
	local self = setmetatable({ station = station }, Station); self:reset(); return self
end
function Station:leave() self.audit, self.selected = nil, nil end
function Station:reset()
	self:leave(); self.station.contents:ClearAllChildren()
	local s = self.station
	self.fixture = V.folder(s.contents, "DispatchCrates")
	self.schema = SchemaModule.new()
	self.schema.name, self.schema.tag, self.schema.className = "Dispatch crate", "PGAuditCrate", "Model"
	self.schema.fields = { { name = "Health", kind = "number", required = true, hasDefault = true, default = 50, min = 1, max = 100, integer = true, choices = {}, description = "Crate durability" } }
	self.schema.children = { { path = "Core", className = "BasePart", description = "Physical crate body", optional = false } }
	self.schema.requiredTags = { "PGReady" }
	for i = 1, 24 do
		local crate = V.folder(self.fixture, string.format("Crate%02d", i), "Model")
		crate:AddTag("PGAuditCrate")
		if i < 17 or i > 20 then crate:AddTag("PGReady") end
		if i >= 5 then crate:SetAttribute("Health", i <= 8 and "fragile" or (i <= 12 and -10 or 75)) end
		local x, z = ((i - 1) % 6 - 2.5) * 6, (math.floor((i - 1) / 6) - 1.5) * 7
		local part = V.part(s, crate, i >= 13 and i <= 16 and "Shell" or "Core", Vector3.new(3.5, 3.5, 3.5), Vector3.new(x, 2.1, z), Color3.fromRGB(119, 150, 151), Enum.Material.Metal)
		crate.PrimaryPart = part
		V.part(s, crate, "Band", Vector3.new(3.6, 0.4, 3.6), Vector3.new(x, 2.1, z), Color3.fromRGB(203, 206, 207))
	end
	self.summary, self.message = "24 tagged crates / dispatch audit", "Missing defaults and tags may be repaired; other errors remain diagnostic."
end
function Station:scan()
	self.audit = Engine.audit(self.schema, { self.fixture }); self.selected = #self.audit.issues > 0 and 1 or nil
	local repairable = {}
	for _, finding in ipairs(self.audit.issues) do if finding.fix then repairable[finding.instance] = true end end
	local count = 0; for _ in pairs(repairable) do count += 1 end
	self.summary = string.format("%d checked / %d valid / %d with issues\n%d safely repairable / %d findings", self.audit.matched, self.audit.valid, self.audit.matched - self.audit.valid, count, #self.audit.issues)
	self.message = "Engine.audit / select a finding"
end
function Station:handle(action, _, index)
	if action == "run" then self:scan()
	elseif action == "select" and self.audit and self.audit.issues[index] then self.selected = index
	elseif action == "apply" then
		local issue = self.audit and self.audit.issues[self.selected]
		assert(issue and issue.fix, "This finding is diagnostic-only.")
		local plan = Engine.preview(self.audit, { issue })
		assert(Engine.isFresh(plan), "Audit is stale. Audit again.")
		-- Only production-authorized additive repairs; never replace invalid existing data.
		for _, change in ipairs(plan.changes) do
			assert(change.instance:IsDescendantOf(self.fixture) and change.instance.Parent == change.parent, "Outside the fixture.")
			if change.action == "attribute" then
				assert(change.instance:GetAttribute(change.name) == nil, "Attribute already exists.")
				change.instance:SetAttribute(change.name, change.value)
			elseif change.action == "tag" then
				assert(not change.instance:HasTag(change.name), "Tag already exists.")
				change.instance:AddTag(change.name)
			else error("Unsupported additive repair.") end
		end
		self:scan(); self.message = "Safe additive repair applied / audit refreshed"
	end
end
function Station:state()
	local rows, highlights, seen = {}, {}, {}
	if self.audit then
		for _, issue in ipairs(self.audit.issues) do
			table.insert(rows, { title = issue.instance.Name .. " / " .. issue.category,
				detail = issue.field .. "\nExpected: " .. issue.expected .. "\nActual: " .. issue.actual .. "\n" .. issue.reason .. (issue.fix and "\nSafe additive repair" or "\nDiagnostic only"), instance = issue.instance })
			if not seen[issue.instance] then seen[issue.instance] = true; table.insert(highlights, issue.instance) end
		end
	end
	local issue = self.audit and self.audit.issues[self.selected]
	return { summary = self.summary, message = self.message, rows = rows, selected = self.selected,
		canApply = issue ~= nil and issue.fix ~= nil, highlights = highlights }
end
return Station
