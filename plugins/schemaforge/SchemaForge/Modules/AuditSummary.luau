local AuditSummary = {}

-- Counts describe the complete audit, independently of UI filters and subsets.
function AuditSummary.fromAudit(audit)
	local objects, affected, repairable = {}, 0, 0
	for _, finding in ipairs(audit.issues) do
		if not objects[finding.instance] then
			objects[finding.instance] = true
			affected += 1
		end
		if finding.fix ~= nil then repairable += 1 end
	end
	return {
		checked = audit.matched,
		valid = audit.valid,
		objectsWithIssues = affected,
		findings = #audit.issues,
		safelyRepairableFindings = repairable,
	}
end

return AuditSummary
