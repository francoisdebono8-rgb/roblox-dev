if workspace:GetAttribute("CurveForge025QA")~=true then return end
task.defer(function()
	local qa=game:GetService("ServerStorage"):FindFirstChild("CurveForge025QA")
	if not qa or qa:GetAttribute("Running") or qa:GetAttribute("Complete") then return end
	qa:SetAttribute("Running",true)
	local errors,connection={},nil
	local ok,err=xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId==0,"Local Edit-mode QA place required")
		for _,item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"),"QA Workspace must be empty") end
		assert(qa.Candidate.Main.Disabled and qa.Legacy.Main.Disabled,"QA import Main must be disabled")
		print("[CurveForge025] Forge Studio 0.2.5 / product 1.1.0 / sha256="..qa:GetAttribute("CandidateSHA256"))
		connection=game:GetService("ScriptContext").Error:Connect(function(message,_,source)
			if source and (source:IsDescendantOf(qa) or source==script) then table.insert(errors,message) end
		end)
		local baseline=require(qa.Tests.Suite)(qa.Candidate.Modules)
		local technical=require(qa.Tests.V11)(qa.Candidate.Modules,qa.Legacy.Modules)
		local fixture=require(qa.Tests.Fixture)
		local context=require(qa.Tests.Context)(qa.Candidate.Modules,fixture)
		local view=require(qa.Tests.View)(qa.Candidate.Modules,fixture)
		task.wait(0.2)
		assert(baseline and technical and context and view and #errors==0,"Native regression failed")
		local demo=fixture(qa.Candidate.Modules)
		game:GetService("Selection"):Set({demo.Cable.output})
		if workspace.CurrentCamera then workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(42,32,58),Vector3.new(0,8,10)) end
		print("[CurveForge025] Fixture ready: CurveForge025Demo.Cable.UtilityCable / Repeat.CustomBeaconPath")
	end,debug.traceback)
	if connection then connection:Disconnect() end
	qa:SetAttribute("Running",false); qa:SetAttribute("Complete",true); qa:SetAttribute("Success",ok)
	if ok then print("[CurveForge025][SUMMARY] PASS: 9 baseline + 42 technical + 5 context + 7 view callback checks")
	else warn("[CurveForge025][SUMMARY] FAIL: "..tostring(err)) end
	print("[CurveForge025] Installed commercial Main/GUI, physical interaction, screenshots and Light/Dark acceptance remain separate gates.")
end)
