if workspace:GetAttribute("CurveForgeTechnicalGate") ~= true then return end
task.defer(function()
	local root, errors = script.Parent, {}
	local success, err = xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId == 0, "Local empty Edit-mode QA place required")
		for _, item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"), "Workspace must be empty") end
		for _, service in ipairs({ "ServerStorage", "ReplicatedStorage", "ServerScriptService" }) do assert(#game:GetService(service):GetChildren() == 0, "QA service must be empty") end
		assert(not workspace:GetAttribute("CurveForgeGateRunning"), "Gate already running")
		workspace:SetAttribute("CurveForgeGateRunning", true)
		assert(root.Candidate.Main.Disabled and root.Legacy.Main.Disabled, "Only QA runner may execute")
		print("[CurveForgeTechnicalGate] artifact=CurveForge-v1.1.0.rbxm sha256=" .. root:GetAttribute("CandidateSHA256"))
		print("[CurveForgeTechnicalGate] legacy=CurveForge-v1.0.0.rbxm sha256=" .. root:GetAttribute("LegacySHA256"))
		local connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
			if source and source:IsDescendantOf(root) then table.insert(errors, message) end
		end)
		local baseline = require(root.Tests.Suite)(root.Candidate.Modules)
		local technical = require(root.Tests.V11)(root.Candidate.Modules, root.Legacy.Modules)
		task.wait(0.5); connection:Disconnect()
		assert(baseline and technical and #errors == 0, "Native suite failure or asynchronous exception")
	end, debug.traceback)
	workspace:SetAttribute("CurveForgeGateRunning", nil)
	root:SetAttribute("Complete", true); root:SetAttribute("Success", success)
	if success then print("[CurveForgeTechnicalGate][SUMMARY] PASS: baseline + technical suites; no runtime exception")
	else warn("[CurveForgeTechnicalGate][SUMMARY] FAIL: " .. tostring(err)) end
	print("[CurveForgeTechnicalGate] No graphical acceptance, media, listing or publication performed by this runner.")
end)
