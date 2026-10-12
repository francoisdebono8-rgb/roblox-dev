return function(modules, fixtureFactory)
	local Engine, Preview = require(modules.Engine), require(modules.ContextPreview)
	local history=game:GetService("ChangeHistoryService")
	local passed,failed=0,0
	local function test(name,fn)
		local fixture=fixtureFactory(modules)
		local ok,err=xpcall(function() fn(fixture) end,debug.traceback)
		fixture.root:Destroy()
		if ok then passed+=1; print("[CurveForge025][PASS] "..name)
		else failed+=1; warn("[CurveForge025][FAIL] "..name..": "..tostring(err)) end
	end
	local function snapshot(root)
		local values={}
		local items=root:GetDescendants(); table.insert(items,root)
		for _,item in ipairs(items) do
			values[item]={parent=item.Parent,name=item.Name,archivable=item.Archivable,attributes=item:GetAttributes(),tags=item:GetTags()}
			table.sort(values[item].tags)
			if item:IsA("BasePart") then
				values[item].pose,values[item].size,values[item].color,values[item].transparency=item.CFrame,item.Size,item.Color,item.Transparency
			elseif item:IsA("Model") then values[item].pivot,values[item].primary=item:GetPivot(),item.PrimaryPart
			elseif item:IsA("ObjectValue") then values[item].reference=item.Value
			end
		end
		return values
	end
	local function unchanged(before,root)
		local after=snapshot(root)
		for item,record in pairs(before) do
			assert(after[item],"Original removed")
			for key,value in pairs(record) do
				if type(value)=="table" then
					for k,v in pairs(value) do assert(after[item][key][k]==v,"Original metadata changed") end
					for k in pairs(after[item][key]) do assert(value[k]~=nil,"Original metadata added") end
				else assert(after[item][key]==value,"Original changed: "..key) end
			end
		end
		for item in pairs(after) do assert(before[item],"Unexpected instance") end
	end
	test("Cable + custom Repeat contextual preview: no Workspace events, no source writes",function(fixture)
		fixture.Repeat.source.Stem:AddTag("CurveForge025SourceTag")
		fixture.Repeat.source.Stem:SetAttribute("SourceOwner","Keep")
		local reference=Instance.new("ObjectValue"); reference.Name="InternalReference"; reference.Value=fixture.Repeat.source.Stem; reference.Parent=fixture.Repeat.source
		local before=snapshot(workspace)
		local additions,removals=0,0
		local added=workspace.DescendantAdded:Connect(function() additions+=1 end)
		local removed=workspace.DescendantRemoving:Connect(function() removals+=1 end)
		for _,mode in ipairs({"Cable","Repeat"}) do
			local scene=fixture[mode]
			local plan=Engine.load(scene.output)
			local preview=Preview.create(plan,scene.output)
			assert(preview.model.Parent==nil and preview.existingAvailable and preview.contextCount>=2)
			for _,item in ipairs(preview.model:GetDescendants()) do
				assert(#item:GetTags()==0 and not item:IsA("LuaSourceContainer") and not item:IsA("ObjectValue"),"Live metadata in preview")
			end
			local proposedFrame,proposedSize=preview.proposed:GetBoundingBox()
			local existingFrame,existingSize=scene.output.Output:GetBoundingBox()
			assert(proposedFrame:FuzzyEq(existingFrame,1e-4) and (proposedSize-existingSize).Magnitude<1e-4)
			for _,part in ipairs(preview.sources) do
				assert(part~=scene.source and (not scene.source or not part:IsDescendantOf(scene.source)))
				assert(not part:IsDescendantOf(scene.output))
			end
			for _,value in ipairs({"Existing","Proposed","Existing","Proposed"}) do Preview.show(preview,value) end
			for item,transparency in pairs(preview.appearance) do
				if item:IsDescendantOf(preview.proposed) then assert(item.Transparency==transparency) end
			end
			preview.model:Destroy(); Engine.check(plan)
		end
		task.wait(); added:Disconnect(); removed:Disconnect()
		assert(additions==0 and removals==0,"Preview touched Workspace")
		unchanged(before,workspace)
	end)
	test("Preview retains native history head and next Undo/Redo",function(fixture)
		local marker=fixture.Cable.controls[2]
		local original=marker.CFrame
		history:SetWaypoint("CurveForge preview sentinel baseline")
		local recording=assert(history:TryBeginRecording("CurveForge025Sentinel","CurveForge preview sentinel"))
		marker.CFrame+=Vector3.new(0,2,0)
		history:FinishRecording(recording,Enum.FinishRecordingOperation.Commit)
		local canUndo,undoName=history:GetCanUndo()
		local canRedo,redoName=history:GetCanRedo()
		for _=1,3 do
			local scene=Preview.create(Engine.load(fixture.Cable.output),fixture.Cable.output)
			Preview.show(scene,"Existing"); Preview.show(scene,"Proposed"); scene.model:Destroy()
		end
		local undoAfter,nameAfter=history:GetCanUndo(); local redoAfter,redoNameAfter=history:GetCanRedo()
		assert(canUndo==undoAfter and undoName==nameAfter and canRedo==redoAfter and redoName==redoNameAfter)
		history:Undo(); task.wait(); assert(marker.CFrame==original,"Preview polluted Undo")
		history:Redo(); task.wait(); assert(marker.CFrame==original+Vector3.new(0,2,0))
	end)
	test("Move point -> stale rejected -> regenerate both modes -> native Undo/Redo",function(fixture)
		for _,mode in ipairs({"Cable","Repeat"}) do
			local scene=fixture[mode]
			local sourceBefore=scene.source and snapshot(scene.source)
			local old=scene.output.Output
			local oldPlan=Engine.load(scene.output)
			scene.controls[2].Position+=Vector3.new(0,4,5)
			assert(not pcall(Preview.create,oldPlan,scene.output),"Stale contextual preview accepted")
			assert(not pcall(Engine.apply,oldPlan,history,scene.output),"Stale write accepted")
			local plan=Engine.load(scene.output)
			assert(math.abs(plan.path.length-oldPlan.path.length)>0.1)
			local preview=Preview.create(plan,scene.output)
			assert(preview.existingAvailable and preview.proposed:GetBoundingBox()~=preview.existing:GetBoundingBox())
			preview.model:Destroy()
			history:SetWaypoint("CurveForge moved point baseline")
			Engine.apply(plan,history,scene.output); local new=scene.output.Output
			assert(old~=new)
			history:Undo(); task.wait(); assert(scene.output.Output==old)
			history:Redo(); task.wait(); assert(scene.output.Output==new)
			if sourceBefore then unchanged(sourceBefore,scene.source) end
		end
	end)
	test("Context sanitization, non-Archivable fallback and bounded neighbor count",function(fixture)
		local scene=fixture.Cable
		local pole=scene.scene.Pole1
		local scriptItem=Instance.new("Script"); scriptItem.Disabled=true; scriptItem.Parent=pole
		local reference=Instance.new("ObjectValue"); reference.Value=scene.controls[1]; reference.Parent=pole
		local decoration=Instance.new("SpecialMesh"); decoration.MeshType=Enum.MeshType.Brick; decoration.Parent=pole
		local clean=Preview.create(Engine.load(scene.output),scene.output)
		local poleCopy=assert(clean.context:FindFirstChild(pole.Name),"Real contextual pole not copied")
		assert(poleCopy:FindFirstChildOfClass("SpecialMesh"),"Real appearance lost")
		assert(not poleCopy:FindFirstChildOfClass("Script") and not poleCopy:FindFirstChildOfClass("ObjectValue"))
		clean.model:Destroy()
		for i=1,80 do
			local part=Instance.new("Part"); part.Anchored=true; part.Size=Vector3.one
			part.Position=Vector3.new(i%10,10,math.floor(i/10)); part.Parent=scene.scene
		end
		local preview=Preview.create(Engine.load(scene.output),scene.output)
		assert(preview.contextCount<=Preview.limits.contextParts and preview.limited)
		for _,item in ipairs(preview.context:GetDescendants()) do
			assert(not item:IsA("LuaSourceContainer") and not item:IsA("ObjectValue") and not item:IsA("Constraint"))
		end
		preview.model:Destroy()
		local first=scene.output.Output:FindFirstChildWhichIsA("BasePart")
		first.Archivable=false
		preview=Preview.create(Engine.load(scene.output),scene.output)
		assert(not preview.existingAvailable and not first.Archivable)
		assert(not pcall(Preview.show,preview,"Existing")); Preview.show(preview,"Proposed"); preview.model:Destroy()
	end)
	test("Query failure retains actual output and ordered invisible control markers",function(fixture)
		local scene=fixture.Cable
		for _,part in ipairs(scene.controls) do part.Transparency=1 end
		local plan=Engine.load(scene.output)
		local preview=Preview.create(plan,scene.output,{GetPartBoundsInBox=function() error("Injected query failure") end})
		assert(not preview.queryAvailable and preview.contextCount==0 and preview.existingAvailable)
		assert(#preview.proposed:GetChildren()>0)
		local gui=Instance.new("ScreenGui")
		local root=Instance.new("Frame"); root.Size=UDim2.fromOffset(320,640); root.Parent=gui
		local ui=require(modules.StudioUI).new(root,Color3.fromRGB(77,125,210))
		local viewport=ui.viewport(root,preview.model,preview,plan.positions,2)
		for i=1,4 do assert(viewport:FindFirstChild("PointMarker"..i),"Invisible point lost its marker") end
		gui:Destroy()
	end)
	print(string.format("[CurveForge025][CONTEXT] %d passed / %d failed",passed,failed))
	return failed==0
end
