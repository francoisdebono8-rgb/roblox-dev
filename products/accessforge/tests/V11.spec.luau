-- This suite loads the exact candidate and public V1 binaries, in Edit mode only.
return function(modules, legacyModules)
	local Engine, Geometry, Settings = require(modules.Engine), require(modules.Geometry), require(modules.Settings)
	local Legacy, LegacySettings = require(legacyModules.Engine), require(legacyModules.Settings)
	local history = game:GetService("ChangeHistoryService")
	local passed, failed, matrix = 0, 0, {}
	local fixture, cleanup
	local function near(a, b, epsilon) assert(math.abs(a - b) <= (epsilon or 0.0001), tostring(a) .. " ~= " .. tostring(b)) end
	local function rejects(fn, message)
		local ok, err = pcall(fn); assert(not ok, "Expected refusal")
		if message then assert(tostring(err):find(message, 1, true), tostring(err)) end
	end
	local function settings(extra)
		local s = table.clone(Settings.defaults); for k, v in pairs(extra or {}) do s[k] = v end; return s
	end
	local function object(class, parent, name)
		local p = Instance.new(class); p.Name = name or class; p.Parent = parent; return p
	end
	local function marker(pos, name)
		local p = object("Part", fixture, name); p.Anchored = true; p.Position = pos; return p
	end
	local function plan(extra, a, b)
		local input = settings(extra)
		return Engine.plan(marker(a or Vector3.new(0, 10, 0), "Start"), marker(b or Vector3.new(0, 18, -20), "End"), input), input
	end
	local function apply(p)
		history:SetWaypoint("AccessForge fixture baseline")
		local model = Engine.apply(p, history); cleanup[model] = true; return model
	end
	local function specs(p, pattern)
		local result = {}; for _, spec in ipairs(p.parts) do if spec.name:find(pattern) then table.insert(result, spec) end end; return result
	end
	local function snapshot(model)
		local states = {}
		local items = model:GetDescendants(); table.insert(items, model)
		for _, item in ipairs(items) do
			local s = { parent = item.Parent, name = item.Name, attributes = item:GetAttributes(), tags = item:GetTags(), children = {} }
			for _, c in ipairs(item:GetChildren()) do s.children[c] = true end
			if item:IsA("Part") then s.cf = item.CFrame; s.size = item.Size; s.color = item.Color; s.material = item.Material end
			if item:IsA("ObjectValue") then s.value = item.Value end
			states[item] = s
		end
		return function()
			assert(#model:GetDescendants() + 1 == #items, "Unexpected objects after rollback")
			for item, s in pairs(states) do
				assert(item.Parent == s.parent and item.Name == s.name, "Identity/parent/name changed")
				local attrs = item:GetAttributes()
				for k, v in pairs(s.attributes) do assert(attrs[k] == v, k) end
				for k in pairs(attrs) do assert(s.attributes[k] ~= nil, k) end
				for _, c in ipairs(item:GetChildren()) do assert(s.children[c], "Child identity changed") end
				assert(#item:GetTags() == #s.tags)
				for _, tag in ipairs(s.tags) do assert(item:HasTag(tag)) end
				if s.cf then assert(item.CFrame == s.cf and item.Size == s.size and item.Color == s.color and item.Material == s.material) end
				if item:IsA("ObjectValue") then assert(item.Value == s.value) end
			end
		end
	end
	local function test(ids, name, fn)
		fixture = object("Folder", workspace, "AccessForgeV11Fixture"); cleanup = {[fixture] = true}
		local ok, err = xpcall(fn, debug.traceback)
		for instance in pairs(cleanup) do instance:Destroy() end
		for _, id in ipairs(ids) do if not ok then matrix[id] = false elseif matrix[id] == nil then matrix[id] = true end end
		if ok then passed += 1; print("[AccessForgeV11][PASS] " .. name)
		else failed += 1; warn("[AccessForgeV11][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function fakeFailure(check)
		return {TryBeginRecording = function() return "test" end, FinishRecording = function(_, _, op)
			if op == Enum.FinishRecordingOperation.Commit then if check then check() end; error("Injected commit failure") end
		end}
	end
	local function stale(mutate, target)
		local p, input = plan()
		local model = target and apply(p)
		if model then p = Engine.plan(p.start, p.finish, input, model) end
		mutate(p, input, model and Engine.read(model))
		assert(not Engine.isFresh(p), "Changed input remained fresh")
		local began = false
		rejects(function() Engine.apply(p, {TryBeginRecording = function() began = true end}) end)
		assert(not began, "Stale plan opened history")
	end

	for index, mode in ipairs({"Straight", "Switchback", "Catwalk"}) do
		test({index, 4, 39}, "Public V1 " .. mode .. " load, migrate, native Undo/Redo exact identities", function()
			local a = marker(Vector3.new(0, 10, 0)); local b = marker(if mode == "Switchback" then Vector3.new(9, 26, 0) elseif mode == "Catwalk" then Vector3.new(0, 10, -30) else Vector3.new(0, 18, -20))
			local s = table.clone(LegacySettings.defaults); s.Mode = mode
			history:SetWaypoint("AccessForge V1 fixture baseline")
			local model = Legacy.apply(Legacy.plan(a, b, s), history); cleanup[model] = true
			local before = snapshot(model); local old = Engine.read(model)
			local loaded = Engine.load(model); before(); assert(old.version == 1 and Engine.isFresh(loaded))
			local siblings = {object("Folder", model, "UserNote"), object("Part", old.output, "UserOutput"), object("Part", old.groups.Stairs, "UserPart")}
			before = snapshot(model)
			apply(loaded); local current = Engine.read(model); assert(current.version == 2 and #current.owned == loaded.count)
			for i, p in ipairs(current.owned) do assert(p:GetAttribute("AccessForgeIndex") == i) end
			for _, sibling in ipairs(siblings) do assert(sibling:IsDescendantOf(model)) end
			local after = snapshot(model)
			history:Undo(); task.wait(); before(); assert(Engine.read(model).data == old.data)
			history:Redo(); task.wait(); after(); assert(Engine.read(model).data == current.data)
		end)
	end
	test({5, 15, 16}, "Straight endpoint heights, top landing and no landing", function()
		for _, landing in ipairs({false, true}) do
			local p = plan({Landing = landing}, nil, Vector3.new(0, 18.37, -20))
			local treads = specs(p, "Tread"); assert(#treads == p.steps)
			for i, spec in ipairs(treads) do near(spec.cf.Position.Y + spec.size.Y / 2, p.a.Y + i * p.actualRise) end
			near(treads[#treads].cf.Position.Y + p.settings.Thickness / 2, p.b.Y)
			assert(p.metrics.landingCount == (landing and 1 or 0))
			if landing then local spec = specs(p, "TopLanding")[1]; near(spec.cf.Position.Y + spec.size.Y / 2, p.b.Y) end
			apply(p)
		end
	end)
	test({6, 7}, "Shallow solver avoids tiny risers; long run chooses nearest feasible tread", function()
		local shallow = plan({Thickness = 0.05}, Vector3.zero, Vector3.new(0, 0.5, -20))
		assert(shallow.steps == 5); near(shallow.actualRise, 0.1); near(shallow.depths[1], 4); apply(shallow)
		local long = plan({RailLeft = false, RailRight = false}, Vector3.zero, Vector3.new(0, 128, -1000))
		assert(long.steps == 256 and long.depths[1] == 1000 / 256); apply(long)
	end)
	for _, count in ipairs({19, 20, 21}) do
		test({count % 2 == 0 and 9 or 8}, "Switchback minimum-feasible solver " .. count .. " steps", function()
			local p = plan({Mode = "Switchback", RiserHeight = 0.5}, Vector3.new(0, 10, 0), Vector3.new(9, 10 + count * 0.5, 0))
			assert(p.steps == count); near(p.depths[2], 2)
			near(p.depths[1], math.ceil(count / 2) * 2 / math.floor(count / 2))
			local land = specs(p, "ReturnLanding")[1]; near(land.cf.Position.Y + land.size.Y / 2, 10 + math.floor(count / 2) * 0.5)
			local upper = specs(p, "UpperTread"); near(upper[#upper].cf.Position.Y + p.settings.Thickness / 2, p.b.Y); apply(p)
		end)
	end
	for _, side in ipairs({"Left", "Right"}) do
		test({side == "Left" and 10 or 11}, "Switchback " .. side .. " across quadrants", function()
			for _, delta in ipairs({Vector3.new(9,16,0), Vector3.new(-9,16,0), Vector3.new(0,16,9), Vector3.new(0,16,-9), Vector3.new(6.4,16,6.4)}) do
				local p = plan({Mode = "Switchback", ReturnSide = side}, Vector3.zero, delta)
				local across = Vector3.new(delta.X, 0, delta.Z).Unit
				local direction = Vector3.yAxis:Cross(across) * (side == "Right" and 1 or -1)
				assert(specs(p, "ReturnLanding")[1].cf.Position:Dot(direction) > 0)
				apply(p)
			end
		end)
	end
	test({12, 13, 14}, "Catwalk exact and tolerance boundary, above boundary refusal", function()
		for _, y in ipairs({0, 0.01, -0.01}) do
			local p = plan({Mode = "Catwalk"}, Vector3.zero, Vector3.new(0,y,-30))
			near(specs(p,"Catwalk$")[1].cf.Position.Y + p.settings.Thickness / 2, 0); apply(p)
		end
		rejects(function() plan({Mode="Catwalk"}, Vector3.zero, Vector3.new(0,0.0101,-30)) end)
	end)
	test({17, 18, 19}, "Rail sides, midrail and round/square native profiles", function()
		for _, side in ipairs({{true,false}, {false,true}, {true,true}, {false,false}}) do
			for _, mid in ipairs({false,true}) do for _, profile in ipairs({"Square","Round"}) do
				local p = plan({RailLeft=side[1], RailRight=side[2], MidRail=mid, RailProfile=profile})
				assert((#specs(p,"StraightLeftTop") == 1) == side[1] and (#specs(p,"StraightRightTop") == 1) == side[2])
				assert(p.metrics.railSegmentCount == ((side[1] and 1 or 0) + (side[2] and 1 or 0)) * (mid and 2 or 1))
				local model = apply(p)
				for _, part in ipairs(Engine.read(model).groups.Rails:GetChildren()) do assert(part.Shape == (profile == "Round" and Enum.PartType.Cylinder or Enum.PartType.Block)) end
			end end
		end
	end)
	test({20, 21}, "Supports off/on and floor ordering", function()
		for _, enabled in ipairs({false,true}) do
			local p = plan({Mode="Catwalk", Supports=enabled}, Vector3.new(0,16,0), Vector3.new(0,16,-30))
			assert((p.metrics.supportCount > 0) == enabled)
			for _, spec in ipairs(specs(p,"Support")) do near(spec.cf.Position.Y-spec.size.Y/2, 0); near(spec.cf.Position.Y+spec.size.Y/2, 15.7) end
			apply(p)
		end
		rejects(function() plan({Landing=true, Supports=true, FloorHeight=18}) end)
		rejects(function() plan({FloorHeight=10001}) end)
	end)
	test({22}, "MAX_STEPS accepts 256 Straight/Switchback, rejects mandatory 257", function()
		for _, mode in ipairs({"Straight", "Switchback"}) do
			local extra = {Mode=mode, RiserHeight=0.5, Thickness=0.05, RailLeft=false, RailRight=false}
			local endpoint = mode == "Straight" and Vector3.new(0,128,-128) or Vector3.new(9,128,0)
			local p = plan(extra, Vector3.zero, endpoint); assert(p.steps == 256); apply(p)
			rejects(function() plan(extra, Vector3.zero, endpoint + Vector3.new(0,0.5,0)) end, "256")
		end
	end)
	test({23}, "MAX_PARTS exactly 1000 passes; 1001 refuses", function()
		local s = {Mode="Catwalk", RailRight=false, MidRail=false, PostSpacing=0.5}
		local p = plan(s, Vector3.zero, Vector3.new(0,0,-498.5)); assert(p.count == 1000); apply(p)
		rejects(function() plan(s, Vector3.zero, Vector3.new(0,0,-499)) end, "1000")
	end)
	test({24}, "Invalid geometry refuses before any allocation or project mutation", function()
		local count = #workspace:GetDescendants()
		for _, pair in ipairs({{Vector3.zero,Vector3.zero}, {Vector3.zero,Vector3.new(0,5,0)}, {Vector3.zero,Vector3.new(0,-1,-10)}, {Vector3.new(math.huge,0,0),Vector3.zero}}) do
			rejects(function() Geometry.plan(pair[1],pair[2],settings()) end)
		end
		for _, extra in ipairs({{Thickness=4}, {Mode="Switchback",Width=100}, {Mode="Switchback",LandingDepth=1}, {RailHeight=1,Thickness=0.8}}) do
			rejects(function() Geometry.plan(Vector3.zero,Vector3.new(9,16,0),settings(extra)) end)
		end
		assert(#workspace:GetDescendants() == count)
	end)
	test({25}, "Immutable deterministic metrics; issued plan only; one-use; preview writes nothing", function()
		local p = plan(); local count = #workspace:GetDescendants()
		local again = Engine.plan(p.start,p.finish,table.clone(p.settings))
		for k,v in pairs(p.metrics) do if type(v)~="table" then assert(again.metrics[k]==v,k) end end
		for i,spec in ipairs(p.parts) do for k,v in pairs(spec) do assert(again.parts[i][k]==v,k) end end
		rejects(function() p.settings.Width=9 end); rejects(function() p.parts[1].name="Tampered" end)
		rejects(function() p.metrics.totalGeneratedParts=0 end); rejects(function() p.start=p.finish end)
		rejects(function() Engine.apply(table.clone(p),history) end)
		rejects(function() Engine.apply(Geometry.plan(p.a,p.b,p.settings),history) end)
		local output=Engine.output(p); assert(output.Parent==nil and #workspace:GetDescendants()==count); output:Destroy()
		assert(Engine.isFresh(p)); apply(p); assert(not Engine.isFresh(p)); rejects(function() Engine.apply(p,history) end)
	end)
	for _, entry in ipairs({
		{26,"marker translation",function(p) p.start.Position+=Vector3.new(0.00001,0,0) end},
		{26,"marker rotation",function(p) p.finish.CFrame*=CFrame.Angles(0,0.00001,0) end},
		{27,"marker reparent",function(p) p.start.Parent=object("Folder",fixture) end},
		{27,"marker deletion",function(p) p.finish:Destroy() end},
		{27,"ancestor reparent",function() local parent=object("Folder",workspace); cleanup[parent]=true; fixture.Parent=parent end},
		{28,"settings width",function(_,s) s.Width=9 end},
		{28,"settings mode",function(_,s) s.Mode="Catwalk" end},
	}) do test({entry[1]},entry[2].." stales before recording",function() stale(entry[3]) end) end
	for _, entry in ipairs({
		{29,"owned tiny translation",function(_,_,c) c.owned[1].Position+=Vector3.new(0.00001,0,0) end},
		{29,"owned size",function(_,_,c) c.owned[1].Size+=Vector3.new(0.01,0,0) end},
		{29,"owned rename",function(_,_,c) c.owned[1].Name="Edited" end},
		{29,"owned material",function(_,_,c) c.owned[1].Material=Enum.Material.Glass end},
		{29,"owned physics",function(_,_,c) c.owned[1].CanTouch=false end},
		{29,"owned reparent",function(_,_,c) c.owned[1].Parent=fixture end},
		{30,"metadata attribute",function(_,_,c) c.data:SetAttribute("Width",9) end},
		{30,"metadata duplicate",function(p,_,c) c.data:Clone().Parent=p.target end},
		{30,"output duplicate",function(p,_,c) c.output:Clone().Parent=p.target end},
		{30,"group duplicate",function(_,_,c) c.groups.Stairs:Clone().Parent=c.output end},
		{30,"registry missing reference",function(_,_,c) c.refs[1].Value=nil end},
		{30,"registry duplicate identity",function(_,_,c) c.refs[2].Value=c.refs[1].Value end},
		{30,"registry order",function(_,_,c) c.refs[1].Name="01" end},
		{30,"registry removed",function(_,_,c) c.refs[#c.refs]:Destroy() end},
		{30,"generated metadata",function(_,_,c) c.owned[1]:SetAttribute("AccessForgeIndex",99) end},
		{33,"owned child",function(_,_,c) object("Folder",c.owned[1],"UserChild") end},
	}) do test({entry[1]},entry[2].." refuses safely",function() stale(entry[3],true) end) end
	test({31,32}, "Unrelated Workspace edits and user siblings at every level survive", function()
		local p=plan(); local model=apply(p); local c=Engine.read(model); local loaded=Engine.load(model)
		local additions={}
		for _,parent in ipairs({fixture,model,c.output,c.groups.Stairs,c.groups.Landings,c.groups.Rails,c.groups.Supports}) do
			local item=object("Part",parent,"UserGeometry"); item.CFrame=CFrame.new(80,90,100); table.insert(additions,{item,parent})
		end
		assert(Engine.isFresh(loaded)); apply(loaded)
		for _,pair in ipairs(additions) do assert(pair[1].Parent==pair[2] and pair[1].Position==Vector3.new(80,90,100)) end
	end)
	test({34}, "Recording nil/throw leaves scene intact and consumes the plan", function()
		for _,historyStub in ipairs({{TryBeginRecording=function() return nil end},{TryBeginRecording=function() error("recording error") end}}) do
			local p=plan(); local before=snapshot(fixture); local count=#workspace:GetDescendants()
			rejects(function() Engine.apply(p,historyStub) end); before(); assert(#workspace:GetDescendants()==count and not Engine.isFresh(p))
		end
	end)
	test({35}, "Recording-open mutation caught before replacement; external edit preserved", function()
		local model=apply(plan()); local p=Engine.load(model); local old=Engine.read(model); local cancelled=false
		rejects(function() Engine.apply(p,{TryBeginRecording=function() old.owned[1].Name="Concurrent"; return "test" end,
			FinishRecording=function(_,_,op) assert(op==Enum.FinishRecordingOperation.Cancel); cancelled=true end}) end)
		assert(cancelled and old.owned[1].Name=="Concurrent" and Engine.read(model).data==old.data)
	end)
	for _,stage in ipairs({"first-detach","last-detach","data-detach","first-insert","last-insert","data-insert"}) do
		test({36}, "QA-only failure after "..stage.." restores exact old identities", function()
			local model=apply(plan()); local p=Engine.load(model); local before=snapshot(model); local env=getfenv(Engine.apply)
			local count=#p.owned
			local targets={ ["first-detach"]=1, ["last-detach"]=count, ["data-detach"]=count+1,
				["first-insert"]=count+2, ["last-insert"]=count+1+p.count, ["data-insert"]=count+2+p.count }
			local faulted,cancelled,writes=false,false,0
			setfenv(Engine.apply,setmetatable({assert=function(condition,message)
				env.assert(condition,message)
				if message=="Parent write did not persist." then
					writes+=1
					if writes==targets[stage] then faulted=true; error("Injected after setter") end
				end
			end},{__index=env}))
			local ok,err=pcall(Engine.apply,p,{TryBeginRecording=function() return "test" end,FinishRecording=function(_,_,op) assert(op==Enum.FinishRecordingOperation.Cancel); cancelled=true end})
			setfenv(Engine.apply,env)
			assert(not ok and tostring(err):find("Injected after setter",1,true) and faulted and cancelled); before()
		end)
	end
	test({37}, "Build/regenerate commit failure cleanup and exact rollback", function()
		local p=plan(); local count=#workspace:GetDescendants(); rejects(function() Engine.apply(p,fakeFailure()) end); assert(#workspace:GetDescendants()==count)
		local model=apply(plan()); local before=snapshot(model); p=Engine.load(model); local old=Engine.read(model)
		rejects(function() Engine.apply(p,fakeFailure(function() assert(old.data.Parent==nil and old.owned[1].Parent==nil) end)) end)
		before(); assert(Engine.read(model).data==old.data)
	end)
	test({38}, "Build native single Undo/Redo restores exact model and parts", function()
		local p=plan(); local model=apply(p); local after=snapshot(model)
		history:Undo(); task.wait(); assert(model.Parent==nil and p.start.Parent==fixture)
		history:Redo(); task.wait(); after(); assert(#Engine.read(model).owned==p.count)
	end)
	test({40}, "New Markers native Undo/Redo, recording refusal and commit cleanup", function()
		for _,mode in ipairs({"Straight","Switchback","Catwalk"}) do
			history:SetWaypoint("AccessForge marker fixture baseline")
			local a,b=Engine.newMarkers(history,Vector3.zero,mode); local folder=a.Parent; cleanup[folder]=true; local after=snapshot(folder)
			history:Undo(); task.wait(); assert(folder.Parent==nil)
			history:Redo(); task.wait(); after(); assert(a.Parent==folder and b.Parent==folder)
		end
		for _,stub in ipairs({{TryBeginRecording=function() return nil end},{TryBeginRecording=function() error("refused") end},fakeFailure()}) do
			local count=#workspace:GetDescendants(); rejects(function() Engine.newMarkers(stub,Vector3.zero,"Straight") end); assert(#workspace:GetDescendants()==count)
		end
		rejects(function() Engine.newMarkers(history,Vector3.new(math.huge,0,0),"Straight") end)
	end)
	test({41}, "Large coordinates, near axes, minimum width and maximum landing", function()
		for _,delta in ipairs({Vector3.new(0.01,8,-20),Vector3.new(-20,8,0.01)}) do
			local a=Vector3.new(19900,10,0); local p=plan({Width=2},a,a+delta); apply(p)
			for _,spec in ipairs(p.parts) do assert(spec.cf.RightVector.Magnitude>0.999 and spec.cf.UpVector.Magnitude>0.999) end
		end
		apply(plan({Width=100,Landing=true,LandingDepth=100}))
	end)
	test({42}, "Existing View mounts and loaded immutable settings can be edited by copy", function()
		local gui=Instance.new("ScreenGui"); cleanup[gui]=true
		local dispose=require(modules.View).mount(gui,game:GetService("Selection"),history); dispose()
		local p=Engine.load(apply(plan())); local editable=table.clone(p.settings); editable.Width=9
		apply(Engine.plan(p.start,p.finish,editable,p.target))
	end)
	test({43,44}, "Exact candidate source correspondence and closed production payload", function()
		local root=modules.Parent.Parent; assert(root.SourceMatchVerified.Value and #root:GetAttribute("CandidateSHA256")==64)
		local count=0
		for _,item in ipairs(modules.Parent:GetDescendants()) do
			if item:IsA("LuaSourceContainer") then
				count+=1
				for _,pattern in ipairs({"GetAsync","PostAsync","RequestAsync","loadstring","TechnicalGate","AccessForgeV11","AnalyticsService"}) do assert(not item.Source:find(pattern,1,true)) end
			else assert(item:IsA("Folder")) end
		end
		assert(count==5)
	end)
	for id=1,44 do print("[AccessForgeV11][MATRIX] "..id.." "..(matrix[id]==true and "PASS" or matrix[id]==false and "FAIL" or "NON TESTED")) end
	print(string.format("[AccessForgeV11][SUMMARY] %d PASS / %d FAIL",passed,failed))
	return failed==0
end
