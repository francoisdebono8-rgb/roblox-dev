return function(Summary)
	local count = 0
	local function check(name, audit, expected)
		local result = Summary.fromAudit(audit)
		for key, value in pairs(expected) do assert(result[key] == value, name .. ": " .. key) end
		assert(result.checked == result.valid + result.objectsWithIssues, name .. ": object accounting")
		count += 1
		print("[SchemaForge025Summary][PASS] " .. name)
	end
	local function expected(checked, valid, affected, findings, safe)
		return {checked=checked, valid=valid, objectsWithIssues=affected, findings=findings, safelyRepairableFindings=safe}
	end
	check("No targets is zero checked, not a successful population", {matched=0, valid=0, issues={}}, expected(0,0,0,0,0))
	check("All targets valid", {matched=3, valid=3, issues={}}, expected(3,3,0,0,0))
	local a, b = {}, {}
	local issues = {
		{instance=a, category="Missing", fix={action="attribute", value=false}},
		{instance=a, category="Required tag", fix={action="tag"}},
		{instance=b, category="Wrong type"},
	}
	check("Multiple findings count an object once; false default repairs count", {matched=3,valid=1,issues=issues}, expected(3,1,2,3,2))
	check("Diagnostic-only objects are never repairable", {matched=2,valid=0,issues={
		{instance=a,category="Class"}, {instance=a,category="Invalid value"},
		{instance=b,category="Required child"}, {instance=b,category="Forbidden tag"},
	}}, expected(2,0,2,4,0))
	check("Missing without default remains diagnostic", {matched=1,valid=0,issues={{instance=a,category="Missing"}}}, expected(1,0,1,1,0))
	local audit = {matched=3, valid=1, issues=issues}
	local first = Summary.fromAudit(audit)
	first.findings = -1
	check("Summary is detached and leaves finding identity/fix intact", audit, expected(3,1,2,3,2))
	assert(audit.issues == issues and issues[1].fix.value == false and issues[1].instance == a)
	print("[SchemaForge025Summary][SUMMARY] " .. count .. " PASS / 0 FAIL")
	return count
end
