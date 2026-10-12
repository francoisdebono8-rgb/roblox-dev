return function(modules, Fixture)
	local Engine, Settings, Preview = require(modules.Engine), require(modules.Settings), require(modules.Preview)
	local history = game:GetService("ChangeHistoryService")
	local passed, failed = 0, 0
	local function test(name, fn)
		local root, cases = Fixture.create()
		local cleanup = {root}
		local ok, err = xpcall(function() fn(cases, cleanup) end, debug.traceback)
		for _, item in ipairs(cleanup) do item:Destroy() end
		if ok then passed += 1; print("[AccessForge025][PASS] "..name)
		else failed += 1; warn("[AccessForge025][FAIL] "..name..": "..tostring(err)) end
	end
	local function plan(c, target, extra)
		local s = table.clone(Settings.defaults)
		for k,v in pairs(c.settings) do s[k]=v end
		for k,v in pairs(extra or {}) do s[k]=v end
		return Engine.plan(c.start,c.finish,s,target)
	end
	local function assertReadOnly(fn)
		local items, states = workspace:GetDescendants(), {}
		for _,item in ipairs(items) do
			states[item]={parent=item.Parent,name=item.Name,archivable=item.Archivable,cf=item:IsA("BasePart") and item.CFrame,size=item:IsA("BasePart") and item.Size}
		end
		fn()
		assert(#workspace:GetDescendants()==#items,"Preview changed Workspace descendants")
		for item,s in pairs(states) do
			assert(item.Parent==s.parent and item.Name==s.name and item.Archivable==s.archivable)
			if s.cf then assert(item.CFrame==s.cf and item.Size==s.size) end
		end
	end
	for _, mode in ipairs({"Straight","Switchback","Catwalk"}) do
		test(mode.." contextual fit and real metrics, Build/Undo/Redo",function(cases,cleanup)
			local c=cases[mode]; local p=plan(c)
			assert(p.metrics.totalGeneratedParts==#p.parts and p.metrics.stepCount==p.steps)
			assertReadOnly(function()
				local preview=Preview.capture(p); table.insert(cleanup,preview.model)
				assert(preview.model.Parent==nil and preview.contextCount>=4 and preview.contextCount<=Preview.MAX_CONTEXT)
				assert(preview.model.Endpoints.Start.Position==p.a and preview.model.Endpoints.End.Position==p.b)
				assert(preview.model.Context:FindFirstChild("LowerPlatform") and preview.model.Context:FindFirstChild("UpperPlatform"))
				assert(Preview.isCurrent(preview) and Engine.isFresh(p))
			end)
			history:SetWaypoint("AccessForge025 build baseline")
			local model=Engine.apply(p,history); table.insert(cleanup,model)
			assert(#Engine.read(model).owned==p.count)
			history:Undo(); task.wait(); assert(model.Parent==nil)
			history:Redo(); task.wait(); assert(model.Parent==workspace and #Engine.read(model).owned==p.count)
		end)
	end
	test("Invalid descending geometry refuses without Workspace/history writes",function(cases)
		local began=false
		assertReadOnly(function()
			local ok=pcall(function() Engine.apply(plan(cases.Invalid),{TryBeginRecording=function() began=true end}) end)
			assert(not ok and not began)
		end)
	end)
	test("Edit Existing, moved End, comparison, Regenerate, user additions, Undo/Redo",function(cases,cleanup)
		local c=cases.Straight
		history:SetWaypoint("AccessForge025 existing baseline")
		local model=Engine.apply(plan(c),history); table.insert(cleanup,model)
		local old=Engine.read(model)
		local note=Instance.new("Folder"); note.Name="UserAddedKeep"; note.Parent=old.groups.Stairs
		local user=Instance.new("Part"); user.Name="UserPartKeep"; user.Anchored=true; user.Parent=old.output
		local loaded=Engine.load(model)
		c.finish.Position+=Vector3.new(0,2,-4)
		assert(not Engine.isFresh(loaded))
		local p=plan(c,model,{Width=8})
		local preview=Preview.capture(p); table.insert(cleanup,preview.model)
		assert(preview.existingCount==#old.owned and #preview.model.Existing:GetChildren()==#old.owned)
		for i,part in ipairs(old.owned) do assert(preview.model.Existing:GetChildren()[i].CFrame==part.CFrame) end
		assert(not preview.model.Existing:FindFirstChild("UserPartKeep"))
		for _,mode in ipairs({"Existing","Proposed"}) do
			local display=Preview.display(preview,mode); table.insert(cleanup,display)
			assert(display[mode] and not display:FindFirstChild(mode=="Existing" and "Proposed" or "Existing"))
		end
		history:SetWaypoint("AccessForge025 regeneration baseline")
		assert(Engine.apply(p,history)==model)
		local new=Engine.read(model)
		assert(note.Parent==old.groups.Stairs and user.Parent==old.output and new.owned[1]~=old.owned[1])
		history:Undo(); task.wait(); assert(Engine.read(model).owned[1]==old.owned[1] and note.Parent==old.groups.Stairs and user.Parent==old.output)
		history:Redo(); task.wait(); assert(Engine.read(model).owned[1]==new.owned[1] and note.Parent==old.groups.Stairs and user.Parent==old.output)
		local child=Instance.new("Folder"); child.Parent=new.owned[1]
		assert(not pcall(Engine.load,model),"Owned-part additions must still refuse regeneration")
	end)
	test("Bounded child-free context; oversized omission; snapshot invalidation",function(cases,cleanup)
		local c=cases.Straight
		local scriptChild=Instance.new("Script"); scriptChild.Disabled=true; scriptChild.Parent=c.lower
		for i=1,80 do
			local part=Instance.new("Part"); part.Name="Context"..i; part.Size=Vector3.one; part.Anchored=true
			part.Position=c.start.Position+Vector3.new(i%8,0,math.floor(i/8)); part.Parent=c.folder
		end
		local huge=Instance.new("Part"); huge.Name="Oversized"; huge.Size=Vector3.new(1000,1,1000); huge.Position=c.start.Position; huge.Anchored=true; huge.Parent=c.folder
		local p=plan(c); local preview
		assertReadOnly(function() preview=Preview.capture(p); table.insert(cleanup,preview.model) end)
		assert(preview.limited and preview.contextCount<=Preview.MAX_CONTEXT and not preview.model.Context:FindFirstChild("Oversized"))
		assert(preview.queryLimited and preview.omitted.capacity>0)
		for _,part in ipairs(preview.model.Context:GetChildren()) do
			assert(part:IsA("BasePart") and #part:GetChildren()==0 and not part:IsDescendantOf(workspace))
		end
		local source=preview.sources[1].object; source.Size+=Vector3.one
		assert(not Preview.isCurrent(preview))
	end)
	test("Unsupported meshes, unions, trusses and child meshes are omitted, never boxes",function(cases,cleanup)
		local c=cases.Straight; local position=c.start.Position
		for _,class in ipairs({"MeshPart","UnionOperation","TrussPart","Part"}) do
			local source=Instance.new(class); source.Name="Unsupported"..class
			source.Position=position; source.Size=Vector3.new(4,2,3); source.Anchored=true
			source.CanCollide=false; source.CanQuery=false; source.Parent=c.folder
			if class=="Part" then local mesh=Instance.new("SpecialMesh"); mesh.Parent=source end
			c.start=source
			assertReadOnly(function()
				local preview=Preview.capture(plan(c)); table.insert(cleanup,preview.model)
				assert(preview.omitted.unsupported==1 and preview.omittedCount==1)
				assert(not preview.model.Context:FindFirstChild(source.Name),"Unsupported context became a false solid")
				assert(preview.model.Endpoints.Start.Position==position,"Endpoint position must remain visible")
			end)
			source:Destroy()
		end
	end)
	test("Non-Archivable, oversized and invisible context have explicit omission counts",function(cases,cleanup)
		local c=cases.Straight
		c.start.Archivable=false
		c.finish.Size=Vector3.new(Preview.MAX_CONTEXT_SIZE+1,1,1)
		local invisible=Instance.new("Part"); invisible.Name="InvisibleContext"; invisible.Anchored=true
		invisible.Size=Vector3.one; invisible.Position=c.lower.Position; invisible.Transparency=1; invisible.Parent=c.folder
		local archivableChanges=0
		local connection=c.start:GetPropertyChangedSignal("Archivable"):Connect(function() archivableChanges+=1 end)
		local ok,err=pcall(function()
			assertReadOnly(function()
				local p=plan(c); local preview=Preview.capture(p); table.insert(cleanup,preview.model)
				assert(preview.omitted.nonArchivable==1 and preview.omitted.oversized==1 and preview.omitted.invisible==1)
				assert(preview.omittedCount==3 and preview.contextCount==2 and not preview.queryLimited)
				assert(not preview.model.Context:FindFirstChild("Start") and not preview.model.Context:FindFirstChild("End"))
				local display=Preview.display(preview,"Proposed"); table.insert(cleanup,display)
				assert(Engine.isFresh(p) and not c.start.Archivable)
			end)
			task.wait(); assert(archivableChanges==0,"Preview mutated original Archivable")
		end)
		connection:Disconnect(); assert(ok,err)
	end)
	test("Supported primitive classes and shapes stay exact; visual mesh additions stale",function(cases,cleanup)
		local c=cases.Straight; local originals={}
		for index,spec in ipairs({{"Part",Enum.PartType.Block},{"Part",Enum.PartType.Ball},{"Part",Enum.PartType.Cylinder},{"WedgePart"},{"CornerWedgePart"}}) do
			local source=Instance.new(spec[1]); source.Name="Primitive"..index
			source.Size=Vector3.new(2,3,4); source.CFrame=CFrame.new(c.start.Position+Vector3.new(index,3,4))*CFrame.Angles(0,0.4,0)
			source.Anchored=true; if spec[2] then source.Shape=spec[2] end
			source.Parent=c.folder; table.insert(originals,source)
		end
		local preview=Preview.capture(plan(c)); table.insert(cleanup,preview.model)
		assert(preview.omittedCount==0 and not preview.queryLimited)
		for _,source in ipairs(originals) do
			local copy=preview.model.Context:FindFirstChild(source.Name)
			assert(copy and copy.ClassName==source.ClassName and copy.Size==source.Size and copy.CFrame==source.CFrame)
			if source:IsA("Part") then assert(copy.Shape==source.Shape) end
			assert(#copy:GetChildren()==0)
		end
		local mesh=Instance.new("BlockMesh"); mesh.Parent=originals[1]
		assert(not Preview.isCurrent(preview),"New child mesh must invalidate primitive context")
		mesh:Destroy(); assert(Preview.isCurrent(preview))
		originals[1].Archivable=false; assert(not Preview.isCurrent(preview))
	end)
	test("Context snapshot opens no history recording",function(cases,cleanup)
		local c=cases.Straight; local before=c.lower.Color
		history:SetWaypoint("AccessForge025 context baseline")
		local id=history:TryBeginRecording("AccessForge025 context fixture"); assert(id)
		c.lower.Color=Color3.fromRGB(20,60,90)
		history:FinishRecording(id,Enum.FinishRecordingOperation.Commit)
		local preview=Preview.capture(plan(c)); table.insert(cleanup,preview.model)
		history:Undo(); task.wait(); assert(c.lower.Color==before and not Preview.isCurrent(preview))
		history:Redo(); task.wait(); assert(Preview.isCurrent(preview))
	end)
	print(string.format("[AccessForge025][SUMMARY] %d PASS / %d FAIL",passed,failed))
	return failed==0
end
