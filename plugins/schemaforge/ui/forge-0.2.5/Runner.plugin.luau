local mode = workspace:GetAttribute("SchemaForge025Mode")
if mode ~= "technical" and mode ~= "fixture" then return end

task.defer(function()
	local root, errors = script.Parent, {}
	local success, err = xpcall(function()
		assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning() and game.PlaceId == 0,
			"Local disposable Edit-mode place required")
		assert(not workspace:GetAttribute("SchemaForge025Running"), "QA already running")
		for _, item in ipairs(workspace:GetChildren()) do assert(item:IsA("Terrain") or item:IsA("Camera"), "Workspace must be empty") end
		for _, name in ipairs({"ServerStorage", "ReplicatedStorage", "ServerScriptService"}) do
			assert(#game:GetService(name):GetChildren() == 0, "QA service must be empty: " .. name)
		end
		workspace:SetAttribute("SchemaForge025Running", true)
		assert(root.Candidate.Main.Disabled and root.Legacy.Main.Disabled, "Imported Main must be disabled only on QA copies")
		print("[SchemaForge025][ARTIFACT] " .. root:GetAttribute("CandidateSHA256") .. " mode=" .. mode)
		local modules = root.Candidate.Modules
		local Fixture = require(root.Fixture)
		if mode == "technical" then
			local connection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
				if source and source:IsDescendantOf(root) then table.insert(errors, message) end
			end)
			local ok, suiteError = xpcall(function()
				assert(require(root.V12)(modules, root.Legacy.Modules, plugin), "Full V12 regression failed")
				assert(require(root.SummaryTests)(require(modules.AuditSummary)) == 6)
				assert(require(root.HeroTests)(modules, Fixture), "Hero regression failed")
				task.wait(0.5)
			end, debug.traceback)
			connection:Disconnect()
			assert(ok, suiteError); assert(#errors == 0, table.concat(errors, "\n"))
		else
			local f = Fixture.create(require(modules.Schema))
			local Engine, Summary = require(modules.Engine), require(modules.AuditSummary)
			local Store = require(modules.Store)
			local selection, history = game:GetService("Selection"), game:GetService("ChangeHistoryService")
			Store.save(f.schema, nil, history); selection:Set(f.roots)
			local function snapshot()
				local summary = Summary.fromAudit(Engine.audit(f.schema, f.roots))
				print("[SchemaForge025][FIXTURE] " .. game:GetService("HttpService"):JSONEncode(summary))
				return summary
			end
			local summary = snapshot()
			assert(summary.checked == 8 and summary.valid == 3 and summary.objectsWithIssues == 5 and summary.findings == 7 and summary.safelyRepairableFindings == 3)
			local bridge = Instance.new("BindableFunction"); bridge.Name = "SchemaForge025QA"; bridge.Parent = game.ServerStorage
			bridge.OnInvoke = function(command)
				if command == "snapshot" then return snapshot()
				elseif command == "stale" then f.objects[4]:SetAttribute("Cost", 99)
				elseif command == "scope" then selection:Set(f.roots)
				elseif command == "reference" then selection:Set({f.reference})
				else error("Unknown QA command") end
			end
			print("[SchemaForge025][FIXTURE READY] Load Greenhouse Contract in the separately installed commercial plugin. No GUI acceptance claimed.")
		end
	end, debug.traceback)
	root:SetAttribute("Complete", true); root:SetAttribute("Success", success)
	if success then
		print("[SchemaForge025][SUMMARY] " .. (mode == "technical" and "PASS: 53 regression + 6 summary + 4 hero cases; 41 matrix rows" or "FIXTURE READY; installed GUI NON TESTED"))
	else warn("[SchemaForge025][SUMMARY] FAIL: " .. tostring(err)) end
end)
