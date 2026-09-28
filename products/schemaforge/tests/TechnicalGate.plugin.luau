if workspace:GetAttribute("SchemaForgeTechnicalGate") ~= true then return end
task.defer(function()
	local root, errors = script.Parent, {}
	local success, err = xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId == 0, "Local empty Edit-mode QA place required")
		for _, item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"), "Workspace must be empty") end
		for _, name in ipairs({"ServerStorage", "ReplicatedStorage", "ServerScriptService"}) do assert(#game:GetService(name):GetChildren() == 0, "QA service must be empty") end
		assert(not workspace:GetAttribute("SchemaForgeGateRunning"), "Gate already running")
		workspace:SetAttribute("SchemaForgeGateRunning", true)
		assert(root.Candidate.Main.Disabled and root.Legacy.Main.Disabled, "Only QA runner may execute")
		print("[SchemaForgeTechnicalGate] artifact=SchemaForge-v1.2.0.rbxm sha256=" .. root:GetAttribute("CandidateSHA256"))
		print("[SchemaForgeTechnicalGate] legacy=SchemaForge-v1.1.0.rbxm sha256=" .. root:GetAttribute("LegacySHA256"))
		local connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
			if source and source:IsDescendantOf(root) then table.insert(errors, message) end
		end)
		local ok = require(root.Tests.V12)(root.Candidate.Modules, root.Legacy.Modules, plugin)
		task.wait(0.5); connection:Disconnect()
		assert(ok and #errors == 0, "Native suite failure or asynchronous exception")
	end, debug.traceback)
	workspace:SetAttribute("SchemaForgeGateRunning", nil)
	root:SetAttribute("Complete", true); root:SetAttribute("Success", success)
	if success then print("[SchemaForgeTechnicalGate][SUMMARY] PASS")
	else warn("[SchemaForgeTechnicalGate][SUMMARY] FAIL: " .. tostring(err)) end
end)
