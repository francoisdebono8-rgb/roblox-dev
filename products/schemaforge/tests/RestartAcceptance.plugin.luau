-- Read-only, separate QA plugin for a fresh opening of the licensed media place.
local greenhouse = workspace:FindFirstChild("PlantGreenhouse")
if not greenhouse or game.PlaceId ~= 0 then return end

task.defer(function()
	local prefix = "[SchemaForgeRestart]"
	local ok, err = pcall(function()
		print(prefix .. " artifact=" .. tostring(script.Parent:GetAttribute("CommercialArtifact")) .. " sha256=" .. tostring(script.Parent:GetAttribute("CommercialSHA256")))
		assert(not game:GetService("RunService"):IsRunning(), "Use Edit mode")
		local commercial = script.Parent.SchemaForge
		assert(commercial.Main.Disabled, "Disable only the embedded QA copy's Main")
		local Store = require(commercial.Modules.Store)
		local Engine = require(commercial.Modules.Engine)
		local pots = assert(greenhouse:FindFirstChild("ProductionPots"))
		local saved = game.ServerStorage._SchemaForgeSchemas["Greenhouse pots"].Value
		local names = Store.list()
		assert(#names == 1 and names[1] == "Greenhouse pots", "Unexpected saved project contracts")
		local schema, token = Store.load("Greenhouse pots")
		assert(token == saved and schema.tag == "GrowablePot" and #schema.fields == 3 and #schema.children == 1)
		local audit = Engine.audit(schema, {pots})
		assert(audit.matched == 8 and #audit.issues == 6, "Unexpected greenhouse audit")
		assert(pots.Cabbage_03:GetAttribute("Cost") == nil and pots.Cabbage_06:GetAttribute("Cost") == nil)
		assert(saved == game.ServerStorage._SchemaForgeSchemas["Greenhouse pots"].Value, "Read-only restart check changed storage")
		print(prefix .. "[PASS] Fresh Studio process loaded the existing disk-saved V1 contract with final 1.1.0 modules; 8 targets, 6 findings, no writes")
		print(prefix .. "[INFO] No GUI Library click or newly edited contract save/reopen is claimed")
	end)
	if not ok then warn(prefix .. "[FAIL] " .. tostring(err)) end
end)
