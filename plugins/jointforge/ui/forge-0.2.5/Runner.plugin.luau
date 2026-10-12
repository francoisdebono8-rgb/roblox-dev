if workspace:GetAttribute("JointForge025Gate") ~= true then return end
task.defer(function()
	local root, errors = script.Parent, {}
	local success, err = xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId == 0, "Local empty Edit-mode QA place required")
		for _, item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"), "Workspace must be empty") end
		for _, name in ipairs({"ServerStorage", "ReplicatedStorage", "ServerScriptService"}) do assert(#game:GetService(name):GetChildren() == 0, "QA services must be empty") end
		assert(not workspace:GetAttribute("JointForge025Running"), "Gate already running")
		workspace:SetAttribute("JointForge025Running", true)
		assert(root.Candidate.Main.Disabled and root.Legacy.Main.Disabled)
		print("[JointForge025] sha256=" .. root:GetAttribute("CandidateSHA256"))
		local connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
			if source and source:IsDescendantOf(root) then table.insert(errors, message) end
		end)
		local suite = require(root.Tests.Issues)
		local full = require(root.Tests.V11)(root.Candidate.Modules, root.Legacy.Modules, plugin, {
			sourceCount = 9,
			viewSmoke = function() suite.viewSmoke(root.Candidate.Modules, root.Fixture, plugin) end,
		})
		local issues = suite.run(root.Candidate.Modules, root.Fixture)
		task.wait(0.5); connection:Disconnect()
		assert(full and issues and #errors == 0, "Suite failure or asynchronous exception")
	end, debug.traceback)
	workspace:SetAttribute("JointForge025Running", nil)
	root:SetAttribute("Complete", true); root:SetAttribute("Success", success)
	if success then print("[JointForge025][SUMMARY] PASS: full 56-row matrix and 10 issue scenarios")
	else warn("[JointForge025][SUMMARY] FAIL: " .. tostring(err)) end
end)
