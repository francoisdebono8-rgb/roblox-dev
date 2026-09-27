if workspace:GetAttribute("PresetForgeReleaseGate") ~= true then
	return
end

task.defer(function()
	local root = script.Parent
	local prefix = "[PresetForgeReleaseGate]"
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),
		prefix .. " Run as a local plugin in Studio Edit mode")
	assert(root.PresetForge.Main.Disabled, prefix .. " Commercial Main must be disabled inside QA")
	assert(type(root:GetAttribute("CommercialSHA256")) == "string", prefix .. " Build with tests/build_final_gate.py")
	assert(require(root.PresetForge.Modules.Constants).VERSION == "2.1.0", prefix .. " Expected final version 2.1.0")
	print(prefix .. " artifact=" .. root:GetAttribute("CommercialArtifact") .. " sha256=" .. root:GetAttribute("CommercialSHA256"))
	print(prefix .. " Controller handlers + mock Selection; layout geometry uses real UIFactory. No GUI interaction claim.")

	local passed, total = 0, 0
	local asyncErrors = {}
	local errorConnection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
		if source and source:IsDescendantOf(root) then
			asyncErrors[#asyncErrors + 1] = message
		end
	end)
	local function test(name, callback)
		total += 1
		local cleanups = {}
		local ok, message = xpcall(function()
			callback(function(fn) cleanups[#cleanups + 1] = fn end)
		end, debug.traceback)
		for index = #cleanups, 1, -1 do
			local cleaned, cleanupError = pcall(cleanups[index])
			if not cleaned then
				ok = false
				message = tostring(message or "") .. "\nCleanup failed: " .. tostring(cleanupError)
			end
		end
		if ok then
			passed += 1
			print(prefix .. "[PASS] " .. name)
		else
			warn(prefix .. "[FAIL] " .. name .. ": " .. tostring(message))
		end
	end

	for _, name in ipairs({ "Schema.spec", "CapturePreview.spec", "ScopePreview.spec", "ApplyService.spec", "PresetStore.spec", "ProjectStore.spec" }) do
		test(name, function() assert(require(root.Tests[name]) == true) end)
	end
	for _, name in ipairs({ "Workflow.spec", "Layout.spec", "NativeRelease.spec" }) do
		local before = total
		local ok, message = xpcall(function()
			require(root.Tests[name])(function(caseName, callback) test(name .. " / " .. caseName, callback) end, plugin)
		end, debug.traceback)
		if not ok then
			test(name .. " suite load", function() error(message) end)
		elseif total == before then
			test(name .. " nonempty suite", function() error("No cases registered") end)
		end
	end
	task.wait()
	errorConnection:Disconnect()
	test("no asynchronous production/QA runtime errors", function()
		assert(#asyncErrors == 0, table.concat(asyncErrors, "\n"))
	end)
	root:SetAttribute("Passed", passed)
	root:SetAttribute("Total", total)
	root:SetAttribute("Complete", true)
	local summary = string.format("%s %d/%d checks passed", prefix, passed, total)
	if passed ~= total then error(summary) end
	print(summary)
	print(prefix .. " NOT TESTED: actual DockWidget interaction, camera appearance, restart persistence, licensed-scene acceptance.")
end)
