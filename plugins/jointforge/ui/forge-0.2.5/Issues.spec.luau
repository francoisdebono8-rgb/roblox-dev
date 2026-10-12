local Suite = {}

function Suite.run(modules, fixture)
	local Graph, Inspection = require(modules.Graph), require(modules.Inspection)
	local Planner, Transaction = require(modules.Planner), require(modules.Transaction)
	local history = game:GetService("ChangeHistoryService")
	local passed, failed = 0, 0
	local function test(name, fn)
		local model = fixture:Clone(); model.Parent = workspace
		local ok, err = xpcall(function() fn(model) end, debug.traceback)
		model:Destroy()
		if ok then passed += 1; print("[JointForge025][PASS] " .. name)
		else failed += 1; warn("[JointForge025][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function scan(model) return Inspection.scan(workspace,{model}) end
	local function plan(request)
		local result = Planner.preview(workspace,request)
		assert(#result.errors==0,table.concat(result.errors,"; "))
		return result
	end
	local function apply(request)
		history:SetWaypoint("JointForge025 fixture baseline")
		return Transaction.apply(plan(request),history)
	end
	test("12 real joints, 12 diagnostic occurrences, 11 affected connections",function(model)
		local result = scan(model)
		assert(result.jointCount==12 and result.issueCount==12 and result.affectedCount==11)
		local expected = {["broken-endpoint"]=1,["direct-duplicate"]=2,["indirect-path"]=3,["attachment-ancestry"]=1,
			["anchored-both"]=1,["hinge-axis"]=1,["separated-pivot"]=1,["inspect-only"]=1,["same-endpoint"]=1}
		assert(Graph.equal(result.groups,expected))
		assert(result.byJoint[model.CleanConnection].issueCount==0,"A joint's own edge must not be a duplicate")
		for joint, info in pairs(result.byJoint) do for _,diagnostic in ipairs(info.diagnostics) do assert(diagnostic.joint==joint) end end
	end)
	test("Scan and repair Preview preserve every fixture object",function(model)
		local snapshots, descendants = {}, model:GetDescendants()
		for _,item in ipairs(descendants) do snapshots[item]=Graph.capture(item) end
		scan(model)
		plan({kind="reassign",joint=model.BrokenConnection,endpoint1=model.BrokenC})
		assert(#model:GetDescendants()==#descendants)
		for item, snapshot in pairs(snapshots) do assert(Graph.equal(Graph.capture(item),snapshot),item.Name) end
	end)
	test("Explicit repair, rescan 12 to 11, native Undo and Redo",function(model)
		local joint, endpoint = model.BrokenConnection, model.BrokenC
		assert(joint.Part1==nil and scan(model).issueCount==12)
		apply({kind="reassign",joint=joint,endpoint1=endpoint})
		assert(joint.Part1==endpoint and scan(model).issueCount==11)
		history:Undo(); task.wait(); assert(joint.Part1==nil and scan(model).issueCount==12)
		history:Redo(); task.wait(); assert(joint.Part1==endpoint and scan(model).issueCount==11)
	end)
	test("Explicit duplicate reassignment clears both affected rows",function(model)
		apply({kind="reassign",joint=model.DuplicateOne,endpoint1=model.DuplicateC})
		local result=scan(model)
		assert(result.issueCount==10 and result.groups["direct-duplicate"]==nil)
		assert(result.byJoint[model.DuplicateTwo].issueCount==0)
	end)
	test("Stale explicit repair refuses before native recording",function(model)
		local preview=plan({kind="reassign",joint=model.BrokenConnection,endpoint1=model.BrokenC})
		model.BrokenC.Name="ChangedAfterPreview"
		local began=false
		local ok,err=pcall(Transaction.apply,preview,{TryBeginRecording=function() began=true; error("Must not begin") end})
		assert(not ok and tostring(err):find("Relevant graph",1,true) and not began and model.BrokenConnection.Part1==nil)
	end)
	test("NoCollision and physical edges keep separate duplicate policy",function(model)
		local collision=Instance.new("NoCollisionConstraint")
		collision.Part0,collision.Part1,collision.Parent=model.CleanA,model.CleanB,model
		assert(scan(model).issueCount==12)
		local second=collision:Clone(); second.Parent=model
		local result=scan(model)
		assert(result.issueCount==14 and result.byJoint[model.CleanConnection].issueCount==0)
		assert(result.byJoint[collision].issueCount==1 and result.byJoint[second].issueCount==1)
	end)
	test("Create and Batch exact operations, native Undo and Redo",function(model)
		local created=apply({kind="create",class="WeldConstraint",a=model.CreateA,b=model.CreateB})[1]
		assert(created.Part0==model.CreateA and created.Part1==model.CreateB)
		local request={kind="batch",root=model.BatchA,entries={{part=model.BatchB,mode="Static"},{part=model.BatchC,mode="Moving"}}}
		local preview=plan(request); assert(#preview.operations==2)
		history:SetWaypoint("JointForge025 batch baseline")
		local results=Transaction.apply(preview,history)
		assert(results[1]:IsA("WeldConstraint") and results[2]:IsA("Motor6D"))
		history:Undo(); task.wait(); assert(results[1].Parent==nil and results[2].Parent==nil and created.Parent)
		history:Redo(); task.wait(); assert(results[1].Parent==model.BatchA and results[2].Parent==model.BatchA)
	end)
	test("Scope, duplicate identities, inspect-only and invalid scope",function(model)
		local result=Inspection.scan(workspace,{model.BrokenConnection})
		assert(result.jointCount==1 and result.issueCount==1)
		local endpoints={}
		for _,item in ipairs(model:GetChildren()) do if item.Name=="Endpoint" then table.insert(endpoints,item) end end
		assert(#endpoints==2 and Graph.id(endpoints[1])~=Graph.id(endpoints[2]))
		result=Inspection.scan(workspace,{model.InspectOnlyRigid})
		assert(result.issueCount==1 and result.groups["inspect-only"]==1)
		assert(#Planner.preview(workspace,{kind="remove",joints={model.InspectOnlyRigid}}).errors>0)
		assert(not pcall(Inspection.scan,workspace,{}))
		local detached=Instance.new("Model")
		assert(not pcall(Inspection.scan,workspace,{detached})); detached:Destroy()
	end)
	test("Bounded overflow, yielded cancellation and changed-scan refusal",function(model)
		local scope=Instance.new("Folder"); scope.Parent=model
		for _=1,129 do local joint=Instance.new("WeldConstraint"); joint.Parent=scope end
		local ok,err=pcall(Inspection.scan,workspace,{scope})
		assert(not ok and tostring(err):find("128 connections",1,true)); scope:Destroy()
		local count,heartbeats=0,0
		local okCancel,cancelError=pcall(Inspection.scan,workspace,{model},function()
			count+=1
			task.defer(function() heartbeats+=1 end); task.wait()
			if count==3 then error("User cancelled") end
		end)
		assert(not okCancel and tostring(cancelError):find("User cancelled",1,true) and count==3 and heartbeats==3)
		local changed=false
		local okChanged,changedError=pcall(Inspection.scan,workspace,{model},function()
			if not changed then changed=true; model.CleanA.CFrame+=Vector3.new(0,1,0) end
		end)
		assert(not okChanged and tostring(changedError):find("changed during Scan",1,true))
	end)
	test("128 connection scan yields to heartbeat under unrelated scene load",function(model)
		local scope=Instance.new("Folder"); scope.Parent=model
		for i=1,128 do
			local a,b,joint=Instance.new("Part"),Instance.new("Part"),Instance.new("WeldConstraint")
			a.CFrame,b.CFrame=CFrame.new(i*5,100,0),CFrame.new(i*5,100,3)
			a.Parent,b.Parent=scope,scope
			joint.Part0,joint.Part1,joint.Parent=a,b,scope
		end
		for _=1,2000 do local unrelated=Instance.new("Folder"); unrelated.Parent=model end
		local heartbeats,start,previous,longest=0,os.clock(),os.clock(),0
		local result=Inspection.scan(workspace,{scope},function()
			longest=math.max(longest,os.clock()-previous)
			task.defer(function() heartbeats+=1 end); task.wait(); previous=os.clock()
		end)
		longest=math.max(longest,os.clock()-previous)
		assert(result.jointCount==128 and result.issueCount==0 and heartbeats==128)
		print(string.format("[JointForge025][RESPONSIVENESS] joints=128 unrelatedFolders=2000 heartbeats=%d elapsed_ms=%.3f longest_step_ms=%.3f",heartbeats,(os.clock()-start)*1000,longest*1000))
	end)
	print(string.format("[JointForge025][ISSUES] %d PASS / %d FAIL",passed,failed))
	return passed==10 and failed==0
end

function Suite.viewSmoke(modules, fixture, hostPlugin)
	local View, UI, Graph = require(modules.View), require(modules.StudioUI), require(modules.Graph)
	local Planner = require(modules.Planner)
	local history=game:GetService("ChangeHistoryService")
	local model=fixture:Clone(); model.Parent=workspace
	local widget=hostPlugin:CreateDockWidgetPluginGuiAsync("JointForge025CallbackSmoke",
		DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float,false,false,560,640,240,360))
	local event=Instance.new("BindableEvent")
	local selected, callbacks, captured = {}, {}, nil
	local selection={Get=function() return selected end,Set=function(_,items) selected=items; event:Fire() end,SelectionChanged=event.Event}
	local originalNew,originalPreview=UI.new,Planner.preview
	-- Capture callbacks from native controls without changing shipped Sources.
	UI.new=function(...)
		local ui=originalNew(...); local originalButton=ui.button
		ui.button=function(parent,name,text,callback,style)
			local control=originalButton(parent,name,text,callback,style)
			table.insert(callbacks,{control=control,callback=callback}); return control
		end
		return ui
	end
	Planner.preview=function(...) captured=originalPreview(...); return captured end
	local dispose
	local ok,err=xpcall(function()
		dispose=View.mount(widget,selection,history)
		local function click(name,ordinal)
			local count=0
			for _,entry in ipairs(callbacks) do
				if entry.control.Parent and (entry.control.Name==name or entry.control.Text==name) then
					count+=1
					if count==(ordinal or 1) then assert(entry.control.Interactable,"Disabled control "..name); entry.callback(); return end
				end
			end
			error("Missing native control "..name)
		end
		assert(widget:FindFirstChild("ScanAction",true),"Inspect must open by default")
		selected={model}; click("ScanAction")
		click("LocateJoint"..Graph.id(model.BrokenConnection)); assert(selected[1]==model.BrokenConnection)
		click("InspectJoint"..Graph.id(model.BrokenConnection))
		assert(widget:FindFirstChild("EndpointIdentity0",true) and widget:FindFirstChild("EndpointIdentity1",true))
		selected={model.BrokenC}; click("Assign selected part to 1"); click("PreviewRepair")
		assert(captured.request.kind=="reassign" and captured.request.endpoint1==model.BrokenC and #captured.errors==0)
		local exact=captured
		event:Fire(); task.wait()
		assert(not pcall(Planner.check,exact) and not widget:FindFirstChild("ApplyAction",true))
		click("PreviewRepair")
		history:SetWaypoint("JointForge025 View repair baseline"); click("ApplyAction")
		assert(model.BrokenConnection.Part1==model.BrokenC)
		local truthful=false
		for _,item in ipairs(widget:GetDescendants()) do
			if item:IsA("TextLabel") and item.Text:find("12 scanned / 11 issues / 10 affected",1,true) then truthful=true end
		end
		assert(truthful,"Post-Apply summary must rescan the original assembly")
		click("Create")
		selected={model.CreateA}; click("Assign",1)
		selected={model.CreateB}; click("Assign",2); click("Preview")
		assert(captured.request.kind=="create" and #captured.operations==1 and #captured.errors==0)
		click("Batch"); selected={model.BatchA}; click("Use selected part as root")
		selected={model.BatchB}; click("Assign selection: Static")
		selected={model.BatchC}; click("Assign selection: Moving"); click("Preview")
		assert(captured.request.kind=="batch" and #captured.operations==2 and #captured.errors==0)
		click("Inspect"); selected={model.InvalidAttachmentAncestry}; click("Scan selection")
		click("InspectJoint"..Graph.id(model.InvalidAttachmentAncestry))
		selected={model.AncestryC}; click("Create attachment 0 at selected part")
		click("PreviewRepair"); assert(#captured.errors==0 and captured.operations[1].attachments[1].part==model.AncestryC)
		local exactAttachment=false
		for _,item in ipairs(widget:GetDescendants()) do
			if item:IsA("TextLabel") and item.Text:find("NEW "..model.AncestryC:GetFullName(),1,true)
				and item.Text:find(model.AncestryB.DirectAttachment:GetFullName(),1,true) then exactAttachment=true end
		end
		assert(exactAttachment,"Preview must identify each new/existing attachment")
	end,debug.traceback)
	UI.new,Planner.preview=originalNew,originalPreview
	if dispose then dispose() end
	event:Destroy(); widget:Destroy(); model:Destroy()
	assert(ok,err)
	print("[JointForge025][VIEW] PASS callback-driven native controls; installed GUI still requires manual QA")
end

return Suite
