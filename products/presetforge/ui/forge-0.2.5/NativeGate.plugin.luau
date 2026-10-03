-- QA only. This imports the commercial modules; it never replaces the installed GUI.
if workspace:GetAttribute("PresetForge025Gate") ~= true then return end
task.defer(function()
	local root, prefix = script.Parent, "[PresetForge025Gate]"
	local passed, total, asyncErrors = 0, 0, {}
	local connection
	local running = false
	local success, err = xpcall(function()
		local runService = game:GetService("RunService")
		assert(runService:IsStudio() and not runService:IsRunning() and game.PlaceId == 0, "Local empty Edit-mode place required")
		for _, item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"), "Workspace must be empty") end
		for _, service in ipairs({"ServerStorage", "ReplicatedStorage", "ServerScriptService"}) do
			assert(#game:GetService(service):GetChildren() == 0, "QA service must be empty")
		end
		assert(not workspace:GetAttribute("PresetForgeGateRunning"), "Another PresetForge gate is running")
		workspace:SetAttribute("PresetForgeGateRunning", true)
		running = true
		assert(root.PresetForge.Main.Disabled and root.Legacy20.Main.Disabled and root.Legacy21.Main.Disabled)
		print(prefix .. " artifact=" .. root:GetAttribute("Artifact") .. " sha256=" .. root:GetAttribute("CandidateSHA256"))
		print(prefix .. " catalogue=Forge Studio 0.2.5 product=2.2.0 mode=local-edit")
		for _, name in ipairs({"Legacy20", "Legacy21"}) do print(prefix .. " " .. name .. "=" .. root:GetAttribute(name .. "SHA256")) end
		connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
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
		for _, name in ipairs({"Schema.spec", "CapturePreview.spec", "ScopePreview.spec", "ApplyService.spec", "PresetStore.spec", "ProjectStore.spec"}) do
			test("baseline " .. name, function() assert(require(root.Tests[name])) end)
		end
		for _, name in ipairs({"Workflow.spec", "NativeRelease.spec", "Layout.spec"}) do
			require(root.Tests[name])(function(label, callback) test(name .. " / " .. label, callback) end, plugin)
		end
		require(root.Tests.V22)(test, root.PresetForge.Modules, root.Legacy20.Modules, root.Legacy21.Modules, plugin, root)
		require(root.Tests.HeroWorkflow)(test, root.FixtureAssets)
		task.wait()
		test("no asynchronous errors", function() assert(#asyncErrors == 0, table.concat(asyncErrors, "; ")) end)
		print(string.format("%s checks=%d passed=%d failed=%d", prefix, total, passed, total - passed))
		assert(total == 94, "Expected all 74 technical checks, 12 layout checks and 8 hero checks")
		assert(total == passed, "Native regression failure")
	end, debug.traceback)
	if connection then connection:Disconnect() end
	if running then workspace:SetAttribute("PresetForgeGateRunning", nil) end
	root:SetAttribute("Passed", passed); root:SetAttribute("Total", total)
	root:SetAttribute("Complete", true); root:SetAttribute("Success", success)
	if success then print(prefix .. "[SUMMARY] PASS") else warn(prefix .. "[SUMMARY] FAIL: " .. tostring(err)) end
end)
