local Root = game:GetService("ServerStorage").Playground
local Session, Protocol = require(Root.Session), require(Root.Protocol)
local Catalog = require(game:GetService("ReplicatedStorage").ForgePlayground.Catalog)
local Graph = require(Root.ProductModules.Joint.Graph)
local Planner = require(Root.ProductModules.Joint.Planner)
local Geometry = require(Root.ProductModules.Access.Geometry)
local CurveEngine = require(Root.ProductModules.Curve.Engine)
local CurveMath = require(Root.ProductModules.Curve.Curve)
local SchemaEngine = require(Root.ProductModules.Schema.Engine)
local PreviewService = require(Root.ProductModules.Preset.PreviewService)
local ExecutionPlan = require(Root.ProductModules.Preset.ExecutionPlan)
local ApplyAdapter = require(Root.Stations.PlaygroundApplyAdapter)
local parent = Instance.new("Folder"); parent.Name, parent.Parent = "PlaygroundParityQA", workspace
local a, b = Session.new(parent, 5), Session.new(parent, 6)
local passed, failed = 0, 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then passed += 1; print("[Playground29] PASS " .. name)
	else failed += 1; warn("[Playground29] FAIL " .. name .. ": " .. tostring(err)) end
end
local function normalized(root)
	local result = {}
	local function visit(item, path)
		local value = { class = item.ClassName, attributes = item:GetAttributes(), tags = item:GetTags() }
		table.sort(value.tags)
		if item:IsA("BasePart") then value.cf, value.size, value.color, value.material, value.anchored = item.CFrame, item.Size, item.Color, item.Material, item.Anchored end
		if item:IsA("Light") then value.color, value.brightness, value.range = item.Color, item.Brightness, item.Range end
		if item:IsA("Attachment") then value.cf = item.CFrame end
		if Graph.isJoint(item) then
			local _, _, e0, e1 = Graph.endpoints(item)
			value.e0, value.e1 = e0 and e0:GetFullName(), e1 and e1:GetFullName()
		end
		result[path] = value
		local names = {}
		for _, child in ipairs(item:GetChildren()) do
			names[child.Name] = (names[child.Name] or 0) + 1
			visit(child, path .. "/" .. child.Name .. "#" .. names[child.Name])
		end
	end
	visit(root, "root"); return result
end
local function codes(findings)
	local result = {}
	for _, f in ipairs(findings) do result[f.joint.Name .. "/" .. f.code] = true end
	return result
end
local function findings(result)
	local resultKeys = {}
	for _, f in ipairs(result.issues) do resultKeys[f.instance.Name .. "/" .. f.field] = { f.category, f.expected, f.actual, f.fix ~= nil } end
	return resultKeys
end
local baselines = {}
for _, id in ipairs(Catalog.order) do baselines[id] = normalized(a.world.stations[id].contents) end
local untouched = normalized(b.world.model)

test("protocol defaults and index boundaries", function()
	for _, id in ipairs(Catalog.order) do assert(Protocol.validate("run", id, Catalog.defaults(id))) end
	assert(not Protocol.validate("run", "curve", { mode = "Cable", point = "2", offset = 0 / 0, count = 12 }))
	assert(not Protocol.validate("configure", "curve", { mode = "Repeat", point = "2", offset = 0, count = 999 }))
	assert(not Protocol.validate("run", "schema", { arbitrary = workspace }))
	assert(not Protocol.validate("select", "schema", {}, 0))
	assert(not Protocol.validate("select", "schema", {}, math.huge))
	assert(not Protocol.validate("select", "schema", {}, {}))
	assert(not Protocol.validate("run", "unknown", {}))
	assert(not Protocol.validate("perturb", "joint", Catalog.defaults("joint")))
end)
test("server limiter refill", function()
	local bucket = { tokens = 4, time = 1 }
	for _ = 1, 4 do assert(Protocol.allow(bucket, 1)) end
	assert(not Protocol.allow(bucket, 1)); assert(Protocol.allow(bucket, 2))
end)
test("inactive station mutations rejected", function()
	assert(not pcall(function() a:handle("apply", "preset", Catalog.defaults("preset")) end))
end)
test("Access select START gate", function()
	local s = a.stations.access
	s:preview(Catalog.defaults("access")); assert(s.plan == nil)
	s:handle("pick", Catalog.defaults("access"), 1); assert(s.started)
end)
for _, mode in ipairs({ "Straight", "Switchback", "Catwalk" }) do
	for _, rails in ipairs({ true, false }) do
		test("Access production parity " .. mode .. "/rails=" .. tostring(rails), function()
			local s, options = a.stations.access, { endpoint = mode, rails = rails }
			s:preview(options); assert(s.plan, s.message)
			local start, finish, settings = s:inputs(options)
			local production = Geometry.plan(start, finish, settings)
			assert(Graph.equal(s.plan, production))
			s:handle("apply", options)
			local output = s.station.contents.Generated
			assert(#output:GetChildren() == production.count)
			for i, p in ipairs(output:GetChildren()) do
				local spec = production.parts[i]
				assert((p.Position - spec.cf.Position).Magnitude < 1e-4 and (p.Size - spec.size).Magnitude < 1e-4)
				assert(p.CanCollide and p.Anchored and p.Color == spec.color)
			end
		end)
	end
end
test("Access invalid endpoint keeps committed output and clears ghost", function()
	local s = a.stations.access
	local original = normalized(s.station.contents.Generated)
	s:preview({ endpoint = "Invalid", rails = true })
	assert(s.plan == nil and not s.station.model:FindFirstChild("Preview"))
	assert(s.message:find("separation", 1, true))
	assert(Graph.equal(original, normalized(s.station.contents.Generated)))
end)
for _, mode in ipairs({ "Cable", "Repeat" }) do
	test("Curve production path and output parity " .. mode, function()
		local s, options = a.stations.curve, { mode = mode, point = "2", offset = 3, count = 12 }
		s:handle("configure", options)
		local plan = CurveEngine.plan(s.controls, s:settings(options), s.source)
		assert(Graph.equal(plan.estimates, s.plan.estimates) and Graph.equal(plan.distances, s.plan.distances))
		for i, distance in ipairs(plan.distances) do
			assert((CurveMath.at(plan.path, distance) - CurveMath.at(s.plan.path, s.plan.distances[i])).Magnitude < 1e-5)
		end
		local output = CurveEngine.output(plan)
		s:handle("apply", options)
		assert(Graph.equal(normalized(output), normalized(s.station.contents.Generated)))
		output:Destroy()
		options.offset, options.count = -6, 24; s:handle("configure", options); s:handle("apply", options)
		local generated = 0
		for _, child in ipairs(s.station.contents:GetChildren()) do if child.Name == "Generated" then generated += 1 end end
		assert(generated == 1 and not s.station.model:FindFirstChild("Preview"))
	end)
end
test("Curve ghost collision and changed-control freshness", function()
	local s, options = a.stations.curve, Catalog.defaults("curve")
	s:preview(options)
	for _, p in ipairs(s.station.model.Preview:GetDescendants()) do if p:IsA("BasePart") then assert(not p.CanCollide and not p.CanQuery and not p.CanTouch) end end
	s.controls[1].Position += Vector3.new(0, 0, 1)
	assert(not pcall(function() s:handle("apply", options) end))
end)
test("Joint diagnostics production parity", function()
	local s, expected = a.stations.joint, {}
	for _, edge in ipairs(Graph.inspect(s.fixture, { s.fixture })) do
		for _, d in ipairs(edge.diagnostics) do expected[edge.joint.Name .. "/" .. d.code] = true end
		if edge.a and edge.b then
			local p = Planner.preview(s.fixture, { kind = "reassign", joint = edge.joint, endpoint0 = edge.endpoint0, endpoint1 = edge.endpoint1 })
			for _, d in ipairs(p.diagnostics) do if d.code == "direct-duplicate" or d.code == "indirect-path" then expected[edge.joint.Name .. "/" .. d.code] = true end end
		end
	end
	s:scan(Catalog.defaults("joint")); assert(Graph.equal(expected, codes(s.findings)))
	assert(expected["MissingHandleLink/broken-endpoint"] and expected["MisalignedHinge/hinge-axis"] and expected["MisalignedHinge/separated-pivot"] and expected["FrameLink1/direct-duplicate"])
end)
test("Joint endpoint decision rejects same-part repair", function()
	local s = a.stations.joint
	s:handle("configure", { endpoint = "Door" })
	assert(#s.plan.errors > 0); assert(not pcall(function() s:apply() end))
	s:handle("configure", { endpoint = "Handle" }); assert(#s.plan.errors == 0)
	s:handle("apply", { endpoint = "Handle" })
	assert(not codes(s.findings)["MissingHandleLink/broken-endpoint"])
	assert(s.door.MissingHandleLink.Part1 == s.handlePart)
end)
test("Joint explicit removal and pivot repair reduce actual findings", function()
	local s, options = a.stations.joint, Catalog.defaults("joint")
	local before = #s.findings
	for i, f in ipairs(s.findings) do if f.code == "direct-duplicate" then s:handle("select", options, i); s:handle("apply", options); break end end
	assert(#s.findings < before)
	before = #s.findings
	for i, f in ipairs(s.findings) do if f.code == "separated-pivot" then s:handle("select", options, i); s:handle("apply", options); break end end
	assert(#s.findings < before and not codes(s.findings)["MisalignedHinge/hinge-axis"])
	for _, f in ipairs(s.findings) do assert(f.code == "anchored-both") end
end)
test("Schema audit parity and real fixture errors", function()
	local s = a.stations.schema
	s:scan(); local direct = SchemaEngine.audit(s.schema, { s.fixture })
	assert(Graph.equal(findings(s.audit), findings(direct)))
	assert(s.audit.matched == 24 and s.audit.valid == 4 and #s.audit.issues == 20)
	local categories = {}; for _, f in ipairs(s.audit.issues) do categories[f.category] = (categories[f.category] or 0) + 1 end
	for _, category in ipairs({ "Missing", "Wrong type", "Invalid value", "Required child", "Required tag" }) do assert(categories[category] == 4) end
end)
test("Schema safe repairs do not rewrite invalid values or hierarchy", function()
	local s = a.stations.schema
	for _ = 1, 8 do
		local issue = s.audit.issues[s.selected]; assert(issue.fix)
		local production = SchemaEngine.preview(s.audit, { issue }); assert(#production.changes == 1)
		s:handle("apply", {})
	end
	assert(s.audit.valid == 12 and #s.audit.issues == 12)
	assert(not s:state().canApply and not pcall(function() s:handle("apply", {}) end))
	assert(s.fixture.Crate05:GetAttribute("Health") == "fragile")
	assert(s.fixture.Crate09:GetAttribute("Health") == -10)
	assert(not s.fixture.Crate13:FindFirstChild("Core"))
end)
test("Schema stale audit cannot repair", function()
	local s = a.stations.schema; s:reset(); s:scan()
	s.audit.issues[1].instance:SetAttribute("Health", 99)
	assert(not SchemaEngine.isFresh(s.audit) and not pcall(function() s:handle("apply", {}) end))
end)
test("Preset PreviewService exact sets counts changes parity", function()
	local s, options = a.stations.preset, Catalog.defaults("preset")
	local before = normalized(s.station.contents); s:scan(options)
	local c = s:context(options)
	local direct = s.previewService:build(c.recipe, c.selection, c.options)
	assert(PreviewService.same(s.preview, direct))
	assert(s.preview.scannedCount == 72 and s.preview.compatibleCount == 24 and s.preview.affectedCount == 18 and s.preview.matchingCount == 6 and s.preview.ignoredCount == 48 and s.preview.totalChanges == 18)
	assert(Graph.equal(before, normalized(s.station.contents)))
end)
test("Preset applies only generated field writes", function()
	local s, options = a.stations.preset, Catalog.defaults("preset")
	local ignored = s.lights.Fixture36.Maintenance_36.Color
	s:handle("apply", options)
	assert(s.preview.affectedCount == 0 and s.preview.matchingCount == 24)
	for i = 1, 36 do
		local case = s.lights[string.format("Fixture%02d", i)]
		assert(case:FindFirstChildWhichIsA("PointLight").Brightness == 0.5)
	end
	assert(s.lights.Fixture36.Maintenance_36.Color == ignored)
	options.recipe = "Warm / Color + Brightness"; s:scan(options); assert(s.preview.totalChanges == 48)
	s:handle("apply", options); assert(s.lights.Fixture01.Accent_01.Brightness == 2)
	assert(s.lights.Fixture36.Maintenance_36.Brightness == 0.5)
end)
test("Preset stale plan and out-of-fixture adapter guard", function()
	local s, options = a.stations.preset, Catalog.defaults("preset")
	s:reset(); s:scan(options)
	assert(not pcall(function() ApplyAdapter.apply(b.stations.preset.lights, s.preview.plan, s:context(options)) end))
	s:handle("perturb", options)
	local fresh, err = ExecutionPlan.validate(s.preview.plan, s:context(options))
	assert(not fresh and err:find("Stale Preview", 1, true))
	local before = normalized(s.station.contents)
	s:handle("apply", options)
	assert(s.preview == nil and Graph.equal(before, normalized(s.station.contents)))
end)
test("every station reset restores exact baseline and removes previews", function()
	for _, id in ipairs(Catalog.order) do
		a.stations[id]:reset()
		assert(Graph.equal(baselines[id], normalized(a.world.stations[id].contents)), "Reset mismatch: " .. id)
		assert(not a.world.stations[id].model:FindFirstChild("Preview"))
	end
end)
test("no mutation leaks to another session", function() assert(Graph.equal(untouched, normalized(b.world.model))) end)
test("navigation clears prior ghost and plan", function()
	a:handle("visit", "curve", Catalog.defaults("curve")); a:handle("run", "curve", Catalog.defaults("curve"))
	assert(a.stations.curve.plan)
	a:handle("visit", "preset", Catalog.defaults("preset"))
	assert(not a.stations.curve.plan and not a.world.stations.curve.model:FindFirstChild("Preview"))
end)
test("session cleanup", function() a:destroy(); b:destroy(); assert(#parent:GetChildren() == 0) end)
parent:Destroy()
workspace:SetAttribute("PlaygroundQAPassed", passed); workspace:SetAttribute("PlaygroundQAFailed", failed)
print(string.format("[Playground29] COMPLETE %d passed / %d failed", passed, failed))
