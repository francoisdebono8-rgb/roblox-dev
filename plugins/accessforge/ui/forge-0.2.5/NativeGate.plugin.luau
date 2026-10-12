if workspace:GetAttribute("AccessForge025Gate") ~= true then return end
task.defer(function()
	local root, errors = script.Parent, {}
	local connection
	local ok, err = xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId==0,"Local Edit-mode QA place required")
		for _,item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"),"Empty QA Workspace required") end
		for _,name in ipairs({"ServerStorage","ReplicatedStorage","ServerScriptService"}) do assert(#game:GetService(name):GetChildren()==0,"Empty QA services required") end
		assert(not workspace:GetAttribute("AccessForge025Running"),"Gate already running")
		workspace:SetAttribute("AccessForge025Running",true)
		assert(root.Candidate.Main.Disabled and root.Legacy.Main.Disabled and root.SourceMatchVerified.Value)
		print("[AccessForge025Gate] candidate="..root:GetAttribute("CandidateSHA256"))
		print("[AccessForge025Gate] legacy="..root:GetAttribute("LegacySHA256"))
		connection=game:GetService("ScriptContext").Error:Connect(function(message,_,source)
			if source and source:IsDescendantOf(root) then table.insert(errors,message) end
		end)
		assert(require(root.Tests.V11)(root.Candidate.Modules,root.Legacy.Modules),"Full V11 regression failed")
		local Fixture=require(root.Tests.Fixture)
		assert(require(root.Tests.Preview)(root.Candidate.Modules,Fixture),"Contextual regression failed")
		task.wait(0.5); assert(#errors==0,"Asynchronous QA exception")
		local _,cases=Fixture.create()
		game:GetService("Selection"):Set({cases.Straight.start})
		if workspace.CurrentCamera then
			workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(42,42,40),Vector3.new(0,15,-15))
			workspace.CurrentCamera.Focus=CFrame.new(0,15,-15)
		end
		print("[AccessForge025Gate] Fixture ready. Installed production GUI and theme/width captures remain pending.")
	end,debug.traceback)
	if connection then connection:Disconnect() end
	workspace:SetAttribute("AccessForge025Running",nil)
	root:SetAttribute("Complete",true); root:SetAttribute("Success",ok)
	if ok then print("[AccessForge025Gate][SUMMARY] PASS")
	else warn("[AccessForge025Gate][SUMMARY] FAIL: "..tostring(err)) end
end)
