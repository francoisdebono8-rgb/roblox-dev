local specs = {
	script.Parent["ConfigValidator.spec"],
	script.Parent["BuiltInRewards.spec"],
	script.Parent["ReceiptRouter.spec"],
	script.Parent["Services.spec"],
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

assert(passed == #specs, string.format("%d/%d BrickKit specs passed", passed, #specs))
print(string.format("%d/%d BrickKit specs passed", passed, #specs))
