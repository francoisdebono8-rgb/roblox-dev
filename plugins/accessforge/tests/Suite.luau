return function(modules)
	assert(not game:GetService("RunService"):IsRunning(), "Run the suite in Studio edit mode.")
	local Engine, Geometry, Settings = require(modules.Engine), require(modules.Geometry), require(modules.Settings)
	local history = game:GetService("ChangeHistoryService")
	local fixture, generated, passed, failed
	passed, failed = 0, 0
	local function settings(extra)
		local s = table.clone(Settings.defaults); for k, v in pairs(extra or {}) do s[k] = v end; return s
	end
	local function part(pos, name)
		local p = Instance.new("Part"); p.Name = name or "Marker"; p.Anchored = true; p.Position = pos; p.Parent = fixture; return p
	end
	local function setup(extra, a, b)
		return Engine.plan(part(a or Vector3.new(0, 10, 0), "Start"), part(b or Vector3.new(0, 18, -20), "End"), settings(extra))
	end
	local function reject(fn)
		local ok = pcall(fn); assert(not ok, "Expected rejection")
	end
	local function near(a, b) assert(math.abs(a - b) < 1e-4, tostring(a) .. " ~= " .. tostring(b)) end
	local function matching(plan, pattern)
		local result = {}; for _, spec in ipairs(plan.parts) do if spec.name:find(pattern) then table.insert(result, spec) end end; return result
	end
	local function apply(plan)
		history:SetWaypoint("AccessForge test baseline")
		local model = Engine.apply(plan, history)
		if not plan.target then table.insert(generated, model) end
		return model
	end
	local function test(name, fn)
		fixture = Instance.new("Folder"); fixture.Name = "AccessForgeTestFixture"; fixture.Parent = workspace
		generated = {}
		local ok, err = pcall(fn)
		if ok then passed += 1; print("[AccessForgeTests][PASS] " .. name) else failed += 1; warn("[AccessForgeTests][FAIL] " .. name .. ": " .. tostring(err)) end
		fixture:Destroy(); for _, model in ipairs(generated) do model:Destroy() end
	end
	for _, spec in ipairs({
		{ "01 straight 10 steps", {}, Vector3.new(0,18,-20), 10 },
		{ "02 larger automatic stair", {}, Vector3.new(0,34,-60), 30 },
		{ "03 noninteger rise", {}, Vector3.new(0,18.37,-20), 11 },
	}) do
		test(spec[1], function()
			local plan = setup(spec[2], nil, spec[3]); assert(plan.steps == spec[4])
			local treads = matching(plan, "Tread"); assert(#treads == plan.steps)
			for i, p in ipairs(treads) do near(p.cf.Position.Y + p.size.Y / 2, plan.a.Y + i * plan.actualRise); near(p.size.Z, plan.depths[1]) end
			near(treads[#treads].cf.Position.Y + plan.settings.Thickness / 2, plan.b.Y)
		end)
	end
	test("04 narrow / wide", function()
		for _, width in ipairs({ 2, 18 }) do local plan = setup({ Width = width }); for _, p in ipairs(matching(plan, "Tread")) do near(p.size.X, width) end end
	end)
	test("05 material color anchored collision / square round", function()
		for _, round in ipairs({ "Square", "Round" }) do
			local plan = setup({ Material = "Concrete", Color = Color3.new(0.2,0.3,0.4), RailProfile = round, Anchored = false, CanCollide = false })
			local out = Engine.output(plan)
			for _, p in ipairs(out:GetDescendants()) do
				if p:IsA("Part") then
					assert(not p.Anchored and not p.CanCollide and #p:GetChildren() == 0)
					if p.Parent.Name == "Rails" then assert(p.Shape == (round == "Round" and Enum.PartType.Cylinder or Enum.PartType.Block))
					else assert(p.Material == Enum.Material.Concrete); near(p.Color.R, 0.2) end
				end
			end
			out:Destroy()
		end
	end)
	test("06 read-only plan and viewport output", function()
		local a, b = part(Vector3.new(0,10,0)), part(Vector3.new(0,18,-20))
		local seen = {}; for _, item in ipairs(workspace:GetDescendants()) do seen[item] = item.Parent end
		local count = #workspace:GetDescendants()
		local added, removed = 0, 0
		local ca = workspace.DescendantAdded:Connect(function() added += 1 end)
		local cr = workspace.DescendantRemoving:Connect(function() removed += 1 end)
		local plan = Engine.plan(a, b, settings()); local out = Engine.output(plan); assert(out.Parent == nil)
		local viewport = Instance.new("ViewportFrame"); out.Parent = viewport
		task.wait(); ca:Disconnect(); cr:Disconnect()
		assert(added == 0 and removed == 0 and #workspace:GetDescendants() == count)
		for item, parent in pairs(seen) do assert(item.Parent == parent) end
		viewport:Destroy()
	end)
	test("07 intended content only / 26 markers / 27 unrelated", function()
		local plan = setup(); local other = part(Vector3.new(66,77,88)); local cf, size = other.CFrame, other.Size
		local a, b = plan.start.CFrame, plan.finish.CFrame
		local model = apply(plan); assert(model.Parent == workspace)
		assert(other.CFrame == cf and other.Size == size and other.Parent == fixture)
		assert(plan.start.CFrame == a and plan.finish.CFrame == b and plan.start.Parent == fixture)
		local count = 0
		for _, item in ipairs(model:GetDescendants()) do assert(not item:IsA("LuaSourceContainer")); if item:IsA("BasePart") then count += 1 end end
		assert(count == plan.count)
	end)
	test("08 Build native one-step Undo and Redo", function()
		local plan = setup(); local model = apply(plan)
		history:Undo(); task.wait(); assert(model.Parent == nil and plan.start.Parent == fixture)
		history:Redo(); task.wait(); assert(model.Parent == workspace and #Engine.read(model).owned == plan.count)
	end)
	for _, side in ipairs({ "Left", "Right" }) do
		test("09 switchback / 10-11 " .. side .. " return / 17 landing rails", function()
			local plan = setup({ Mode = "Switchback", ReturnSide = side }, Vector3.new(0,0,0), Vector3.new(9,16,0))
			assert(plan.steps == 20 and #matching(plan, "Tread") == 20)
			local lower, upper = matching(plan, "LowerTread"), matching(plan, "UpperTread")
			near(lower[#lower].cf.Position.Y + plan.settings.Thickness/2, 8)
			near(upper[#upper].cf.Position.Y + plan.settings.Thickness/2, 16)
			assert(#matching(plan, "LandingBackTop") == 1 and #matching(plan, "LandingGapTop") == 1)
			local land = matching(plan, "ReturnLanding")[1]; assert(land.cf.Position.Z * (side == "Right" and -1 or 1) > 20)
			near(land.size.X, 15); near(land.cf.Position.Y + land.size.Y/2, 8)
			near(lower[#lower].cf.Position.X, 0); near(upper[#upper].cf.Position.X, 9)
		end)
	end
	test("12 landing depth", function()
		for _, depth in ipairs({ 4, 12 }) do
			local p = setup({ Mode = "Switchback", LandingDepth = depth }, Vector3.zero, Vector3.new(9,16,0))
			near(matching(p, "ReturnLanding")[1].size.Z, depth)
			local straight = setup({ Landing = true, LandingDepth = depth }); near(matching(straight, "TopLanding")[1].size.Z, depth)
		end
	end)
	for i, pair in ipairs({ {true,false}, {false,true}, {true,true} }) do
		test(tostring(12 + i) .. " rail toggles", function()
			local p = setup({ RailLeft = pair[1], RailRight = pair[2] })
			assert((#matching(p,"StraightLeftTop") > 0) == pair[1]); assert((#matching(p,"StraightRightTop") > 0) == pair[2])
		end)
	end
	test("16 stair rails slope and endpoint continuity", function()
		local p = setup({ Landing = true })
		local rail = matching(p,"StraightLeftTop")[1]
		assert(math.abs(rail.cf.LookVector:Dot((p.b-p.a).Unit)) > 0.999)
		local tip1 = rail.cf.Position + rail.cf.LookVector * rail.size.Z/2
		local tip2 = rail.cf.Position - rail.cf.LookVector * rail.size.Z/2
		near(math.min(tip1.Y,tip2.Y), p.a.Y+p.settings.RailHeight)
		near(math.max(tip1.Y,tip2.Y), p.b.Y+p.settings.RailHeight)
		local landing = matching(p,"LandingLeftTop")[1]
		near(landing.cf.Position.Y, math.max(tip1.Y,tip2.Y))
	end)
	test("18 catwalk / 19 rails / 20 supports / 21 spacing", function()
		local previous = 0
		for _, spacing in ipairs({ 12, 4 }) do
			local p = setup({ Mode = "Catwalk", Supports = true, SupportSpacing = spacing }, Vector3.new(0,16,0), Vector3.new(0,16,-30))
			assert(p.steps == 0 and #matching(p,"CatwalkLeftTop") == 1 and #matching(p,"CatwalkRightTop") == 1)
			local supports = matching(p,"Support"); assert(#supports > previous); previous = #supports
			for _, post in ipairs(supports) do near(post.cf.Position.Y-post.size.Y/2,0); near(post.cf.Position.Y+post.size.Y/2,15.7) end
		end
	end)
	test("22 exact metadata / 23 dimensions / 24 moved marker / 25 regenerate Undo Redo", function()
		local p = setup(); local model = apply(p); local current = Engine.read(model); local old = current.owned[1]
		local loaded = Engine.load(model); for k, v in pairs(p.settings) do assert(loaded.settings[k] == v, k) end
		local addition = part(Vector3.new(40,40,40),"UserDecoration"); addition.Parent = current.groups.Stairs; local cf = addition.CFrame
		loaded.settings.Width = 9; loaded.finish.Position += Vector3.new(0,2,-4)
		local changed = Engine.plan(loaded.start, loaded.finish, loaded.settings, model)
		apply(changed); local fresh = Engine.read(model).owned[1]; assert(old.Parent == nil and fresh.Parent ~= nil)
		assert(addition.Parent == current.groups.Stairs and addition.CFrame == cf)
		history:Undo(); task.wait(); assert(old.Parent == current.groups.Stairs and fresh.Parent == nil); near(Engine.load(model).settings.Width,6)
		history:Redo(); task.wait(); assert(old.Parent == nil and fresh.Parent == current.groups.Stairs); near(Engine.load(model).settings.Width,9)
		assert(addition.Parent == current.groups.Stairs and addition.CFrame == cf)
	end)
	test("28 invalid dimensions and enums", function()
		for key in pairs(Settings.limits) do
			for _, bad in ipairs({ "abc", 0/0, math.huge, -math.huge, -10001 }) do reject(function() setup({ [key] = bad }) end) end
			if key ~= "FloorHeight" then for _, bad in ipairs({ 0, -1 }) do reject(function() setup({ [key] = bad }) end) end end
		end
		reject(function() setup({ Material = "Fake" }) end); reject(function() setup({ Mode = "Ladder" }) end)
		reject(function() setup({ RailHeight = 1 }) end); reject(function() setup({ Thickness = 3 }) end)
	end)
	test("29 degenerate / invalid / deleted / stale input / metadata", function()
		reject(function() setup(nil, Vector3.zero, Vector3.zero) end)
		reject(function() setup(nil, Vector3.zero, Vector3.new(0,-2,-20)) end)
		reject(function() setup({ Mode = "Catwalk" }) end)
		reject(function() setup({ Mode = "Switchback" }, Vector3.zero, Vector3.new(2,8,0)) end)
		local p = setup(); p.finish.Position += Vector3.one; reject(function() Engine.apply(p,history) end)
		p = setup(); p.finish:Destroy(); reject(function() Engine.apply(p,history) end)
		local model = apply(setup()); local loaded = Engine.load(model)
		local child = Instance.new("Folder"); child.Parent = Engine.read(model).owned[1]
		reject(function() Engine.apply(loaded,history) end); assert(child.Parent ~= nil)
	end)
	test("30 conservative part and step caps", function()
		reject(function() setup({ Mode = "Catwalk", PostSpacing = 0.5 }, Vector3.new(0,10,0), Vector3.new(0,10,-500)) end)
		reject(function() setup({ RiserHeight = 0.1 }, Vector3.zero, Vector3.new(0,100,-200)) end)
	end)
	test("unavailable recording / rollback / no unrelated loss", function()
		local p = setup(); local count = #workspace:GetDescendants()
		reject(function() Engine.apply(p,{ TryBeginRecording = function() return nil end }) end); assert(#workspace:GetDescendants()==count)
		local bad = { TryBeginRecording = function() return "injected" end, FinishRecording = function(_,_,op) if op==Enum.FinishRecordingOperation.Commit then error("Injected failure") end end }
		reject(function() Engine.apply(p,bad) end); assert(#workspace:GetDescendants()==count)
		local model = apply(p); local loaded = Engine.load(model); local before = Engine.read(model)
		reject(function() Engine.apply(loaded,bad) end); assert(Engine.read(model).data==before.data and before.owned[1].Parent==before.groups.Stairs)
	end)
	test("widget mount / marker creation native Undo Redo", function()
		local gui = Instance.new("ScreenGui"); local count = #workspace:GetDescendants()
		local dispose = require(modules.View).mount(gui,game:GetService("Selection"),history)
		local ui = gui.AccessForgeScroll.AccessForgeUI
		assert(ui.Size.X.Offset >= 350 and ui.Size.Y.Offset >= 620 and #workspace:GetDescendants()==count)
		assert(ui.Settings.Size.Y.Offset + ui.Size.Y.Offset > 0)
		dispose(); gui:Destroy()
		history:SetWaypoint("Markers baseline")
		local a,b = Engine.newMarkers(history,Vector3.zero,"Straight"); local f=a.Parent
		history:Undo(); task.wait(); assert(f.Parent==nil)
		history:Redo(); task.wait(); assert(f.Parent==workspace and b.Parent==f); f:Destroy()
	end)
	print(string.format("[AccessForgeTests] %d passed / %d failed",passed,failed))
	return failed == 0
end
