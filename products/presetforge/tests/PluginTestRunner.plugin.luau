print("[PresetForgeTests] starting deterministic Studio tests")

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
		print("[PresetForgeTests][PASS] " .. spec.Name)
	else
		warn("[PresetForgeTests][FAIL] " .. spec.Name .. ": " .. tostring(errorMessage))
	end
end

assert(passed == #specs, string.format("[PresetForgeTests] %d/%d specs passed", passed, #specs))
print(string.format("[PresetForgeTests] %d/%d specs passed", passed, #specs))
