if workspace:GetAttribute("SchemaForgeFinalGate") ~= true then return end

task.defer(function()
	local root = script.Parent
	local prefix = "[SchemaForgeFinalGate]"
	local passed, total = 0, 0
	local cleanup, errors = {}, {}
	local function deferCleanup(fn) table.insert(cleanup, fn) end
	local function run()
		local runService = game:GetService("RunService")
		assert(runService:IsStudio() and not runService:IsRunning(), "Use the installed local QA plugin in Studio Edit mode")
		assert(game.PlaceId == 0, "Use the separate empty local QA place, never a published project")
		for _, instance in ipairs(workspace:GetChildren()) do
			assert(instance:IsA("Camera") or instance:IsA("Terrain"), "QA requires an empty Workspace; found " .. instance.Name)
		end
		for _, name in ipairs({"ServerStorage", "ServerScriptService", "ReplicatedStorage", "ReplicatedFirst", "StarterGui", "StarterPack", "Lighting", "SoundService"}) do
			assert(#game:GetService(name):GetChildren() == 0, "QA requires empty " .. name)
		end
		for _, instance in ipairs(game:GetService("StarterPlayer"):GetChildren()) do
			assert((instance:IsA("StarterPlayerScripts") or instance:IsA("StarterCharacterScripts")) and #instance:GetChildren() == 0,
				"QA requires empty StarterPlayer containers")
		end
		assert(not workspace:GetAttribute("SchemaForgeFinalGateRunning"), "Another SchemaForge gate is already running")
		assert(root.SchemaForge.Main.Disabled, "Commercial Main must be disabled in the harness only")
		local digest = root:GetAttribute("CommercialSHA256")
		assert(type(digest) == "string" and #digest == 64 and digest:match("^%x+$"), "Build with tests/build_final_gate.py")
		assert(root:GetAttribute("CommercialArtifact") == "SchemaForge-v1.1.0.rbxm", "Wrong commercial artifact")
		workspace:SetAttribute("SchemaForgeFinalGateRunning", true)
		deferCleanup(function() workspace:SetAttribute("SchemaForgeFinalGateRunning", nil) end)
		local selection = game:GetService("Selection")
		local originalSelection = selection:Get()
		deferCleanup(function() selection:Set(originalSelection) end)
		local originalChildren = {}
		for _, container in ipairs({workspace, game:GetService("ServerStorage")}) do
			local children = {}; for _, instance in ipairs(container:GetChildren()) do children[instance] = true end
			originalChildren[container] = children
		end
		local function clearFixtures()
			selection:Set({})
			for container, children in pairs(originalChildren) do
				for _, instance in ipairs(container:GetChildren()) do if not children[instance] then instance:Destroy() end end
			end
		end
		deferCleanup(clearFixtures)
		local connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
			if source and source:IsDescendantOf(root) then table.insert(errors, message) end
		end)
		deferCleanup(function() connection:Disconnect() end)
		print(prefix .. " artifact=" .. root:GetAttribute("CommercialArtifact") .. " sha256=" .. digest)
		print(prefix .. " Native module suites, ScreenGui geometry and disposable DockWidget focus checks; no simulated clicks or manual-flow claim.")
		for _, name in ipairs({"Suite", "V11Engine.spec", "Layout.spec"}) do
			total += 1
			local ok, result = xpcall(function()
				local suite = require(root.Tests[name])
				local layoutPlugin = name == "Layout.spec" and plugin or nil
				if type(suite) == "function" then return suite(root.SchemaForge.Modules, layoutPlugin) end
				assert(type(suite) == "table" and type(suite.run) == "function", "Suite must return a function or module.run")
				return suite.run(root.SchemaForge.Modules, layoutPlugin)
			end, debug.traceback)
			if ok and result == true then
				passed += 1; print(prefix .. "[SUITE PASS] " .. name)
			else warn(prefix .. "[SUITE FAIL] " .. name .. ": " .. tostring(result)) end
			clearFixtures()
			task.wait()
		end
		-- View's freshness task wakes once after disposal; include that in error capture.
		task.wait(1.1)
		assert(#errors == 0, "Asynchronous production/QA errors: " .. table.concat(errors, "\n"))
	end
	local ok, err = xpcall(run, debug.traceback)
	for index = #cleanup, 1, -1 do
		local cleaned, cleanupError = pcall(cleanup[index])
		if not cleaned then ok = false; warn(prefix .. "[CLEANUP FAIL] " .. tostring(cleanupError)) end
	end
	local success = ok and total == 3 and passed == total
	root:SetAttribute("PassedSuites", passed)
	root:SetAttribute("TotalSuites", total)
	root:SetAttribute("Complete", true)
	root:SetAttribute("Success", success)
	if not ok then warn(prefix .. "[FAIL] " .. tostring(err)) end
	local summary = string.format("%s[SUMMARY] %d/%d suites PASS; gate %s", prefix, passed, total, success and "PASS" or "FAIL")
	if success then print(summary) else warn(summary) end
	print(prefix .. " NOT TESTED: human mouse/keyboard workflows, capture/load/filter/apply GUI flows, screenshots, restart persistence or publication.")
end)
