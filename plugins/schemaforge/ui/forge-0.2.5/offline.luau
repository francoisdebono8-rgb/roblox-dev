local Summary = require("../../SchemaForge/Modules/AuditSummary")
local run = require("./AuditSummary.spec")
assert(run(Summary) == 6)
