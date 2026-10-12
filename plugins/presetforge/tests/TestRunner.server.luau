local specs = {
	script.Parent["Schema.spec"],
	script.Parent["CapturePreview.spec"],
	script.Parent["ScopePreview.spec"],
	script.Parent["ApplyService.spec"],
	script.Parent["PresetStore.spec"],
	script.Parent["ProjectStore.spec"],
}

local passed = 0
for _, spec in ipairs(specs) do
	local ok, errorMessage = pcall(require, spec)
	if ok then
		passed += 1
		print("[PASS] " .. spec.Name)
	else
		warn("[FAIL] " .. spec.Name .. ": " .. tostring(errorMessage))
	end
end

assert(passed == #specs, string.format("%d/%d PresetForge specs passed", passed, #specs))
print(string.format("%d/%d PresetForge specs passed", passed, #specs))
