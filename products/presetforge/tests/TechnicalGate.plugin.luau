if workspace:GetAttribute("PresetForgeTechnicalGate") ~= true then return end
task.defer(function()
	local root, prefix = script.Parent, "[PresetForgeTechnicalGate]"
	local success, err = xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId == 0, "Local empty Edit-mode place required")
		for _, item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"), "Workspace must be empty") end
		for _, service in ipairs({ "ServerStorage", "ReplicatedStorage", "ServerScriptService" }) do assert(#game:GetService(service):GetChildren() == 0, "QA service must be empty") end
		assert(not workspace:GetAttribute("PresetForgeGateRunning"), "Gate already running")
		workspace:SetAttribute("PresetForgeGateRunning", true)
		assert(root.PresetForge.Main.Disabled and root.Legacy20.Main.Disabled and root.Legacy21.Main.Disabled)
		print(prefix .. " artifact=PresetForge-v2.2.0.rbxm sha256=" .. root:GetAttribute("CandidateSHA256"))
		for _, name in ipairs({ "Legacy20", "Legacy21" }) do print(prefix .. " " .. name .. "=" .. root:GetAttribute(name .. "SHA256")) end
		local passed, total, asyncErrors = 0, 0, {}
		local connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
			if source and source:IsDescendantOf(root) then asyncErrors[#asyncErrors + 1] = message end
		end)
		local function test(name, callback)
			total += 1
			local cleanup = {}
			local ok, message = xpcall(function() callback(function(fn) cleanup[#cleanup + 1] = fn end) end, debug.traceback)
			for index = #cleanup, 1, -1 do
				local cleaned, cleanupError = pcall(cleanup[index])
				if not cleaned then ok = false; message = tostring(message) .. " cleanup: " .. tostring(cleanupError) end
			end
			if ok then passed += 1; print(prefix .. "[PASS] " .. name)
			else warn(prefix .. "[FAIL] " .. name .. ": " .. tostring(message)) end
		end
		for _, name in ipairs({ "Schema.spec", "CapturePreview.spec", "ScopePreview.spec", "ApplyService.spec", "PresetStore.spec", "ProjectStore.spec" }) do
			test("baseline " .. name, function() assert(require(root.Tests[name])) end)
		end
		for _, name in ipairs({ "Workflow.spec", "NativeRelease.spec" }) do
			require(root.Tests[name])(function(label, callback) test("baseline " .. name .. " / " .. label, callback) end, plugin)
		end
		require(root.Tests.V22)(test, root.PresetForge.Modules, root.Legacy20.Modules, root.Legacy21.Modules, plugin, root)
		task.wait(); connection:Disconnect()
		test("no asynchronous errors", function() assert(#asyncErrors == 0, table.concat(asyncErrors, "; ")) end)
		print(string.format("%s checks=%d passed=%d failed=%d", prefix, total, passed, total - passed))
		assert(total == passed, "Technical or baseline regression failure")
	end, debug.traceback)
	workspace:SetAttribute("PresetForgeGateRunning", nil)
	root:SetAttribute("Complete", true); root:SetAttribute("Success", success)
	if success then print(prefix .. "[SUMMARY] PASS") else warn(prefix .. "[SUMMARY] FAIL: " .. tostring(err)) end
end)
