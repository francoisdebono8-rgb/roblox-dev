return function(modules, Fixture)
	local Schema, Engine = require(modules.Schema), require(modules.Engine)
	local Summary = require(modules.AuditSummary)
	local history = game:GetService("ChangeHistoryService")
	local passed, failed = 0, 0
	local function rejects(fn)
		local ok = pcall(fn); assert(not ok, "Expected conservative refusal")
	end
	local function test(name, fn)
		local fixture = Fixture.create(Schema)
		local ok, err = xpcall(function() fn(fixture) end, debug.traceback)
		fixture.root:Destroy()
		if ok then passed += 1; print("[SchemaForge025Hero][PASS] " .. name)
		else failed += 1; warn("[SchemaForge025Hero][FAIL] " .. name .. ": " .. tostring(err)) end
	end
	local function totals(f, checked, valid, affected, findings, safe)
		local audit = Engine.audit(f.schema, f.roots)
		local summary = Summary.fromAudit(audit)
		assert(summary.checked == checked and summary.valid == valid and summary.objectsWithIssues == affected)
		assert(summary.findings == findings and summary.safelyRepairableFindings == safe)
		return audit
	end
	test("Real fixture 8 checked / 3 valid / 5 objects with issues / 7 findings / 3 safe", function(f)
		local audit = totals(f,8,3,5,7,3)
		for _, issue in ipairs(audit.issues) do
			assert(issue.expected ~= "" and issue.actual ~= "")
			if issue.field == "Cost" then assert(issue.description == f.schema.fields[1].description) end
		end
		local filtered = Engine.filteredIssues(audit,"Wrong type","")
		assert(#filtered == 1 and filtered[1].instance == f.objects[6])
		assert(Summary.fromAudit(audit).findings == 7)
		assert(#Engine.preview(audit, filtered).changes == 0)
	end)
	test("Preview read-only; missing-only Apply; native Undo and Redo", function(f)
		history:SetWaypoint("SchemaForge025 hero fixture")
		local audit = totals(f,8,3,5,7,3)
		local plan = Engine.preview(audit)
		assert(#plan.changes == 3 and f.objects[4]:GetAttribute("Cost") == nil and not f.objects[5]:HasTag("Interactable"))
		assert(Engine.apply(plan, history) == 3)
		totals(f,8,5,3,4,0)
		assert(f.objects[6]:GetAttribute("Cost") == "unknown" and f.objects[7]:GetAttribute("GrowthRate") == -2)
		assert(f.objects[8]:HasTag("Retired") and not f.objects[8]:FindFirstChild("InteractionAnchor"))
		history:Undo(); task.wait(); totals(f,8,3,5,7,3)
		history:Redo(); task.wait(); totals(f,8,5,3,4,0)
	end)
	test("Stale project blocks repair before opening history", function(f)
		local audit = Engine.audit(f.schema, f.roots); local plan = Engine.preview(audit)
		f.objects[4]:SetAttribute("Cost", 99)
		assert(not Engine.isFresh(plan))
		local began = false
		rejects(function() Engine.apply(plan, {TryBeginRecording=function() began=true; return nil end}) end)
		assert(not began and f.objects[4]:GetAttribute("Cost") == 99 and f.objects[5]:GetAttribute("Cost") == nil)
		rejects(function() Engine.preview(audit) end)
	end)
	test("Exact subset preserves remaining missing fields and selections", function(f)
		local audit = Engine.audit(f.schema, f.roots)
		local issue
		for _, finding in ipairs(audit.issues) do if finding.instance == f.objects[4] then issue = finding end end
		assert(issue and issue.fix)
		local selected
		Engine.selectIssues(audit, {Set=function(_, objects) selected=objects end}, {issue})
		assert(#selected == 1 and selected[1] == f.objects[4])
		local plan = Engine.preview(audit, {issue}); assert(#plan.changes == 1)
		assert(Engine.apply(plan, history) == 1)
		totals(f,8,4,4,6,2)
		assert(f.objects[5]:GetAttribute("Cost") == nil and not f.objects[5]:HasTag("Interactable"))
	end)
	print(string.format("[SchemaForge025Hero][SUMMARY] %d PASS / %d FAIL", passed, failed))
	return failed == 0
end
