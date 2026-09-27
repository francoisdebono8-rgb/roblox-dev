if not game:GetService("ServerStorage"):FindFirstChild("CurveForgeQA") then return end
task.defer(function()
	local qa = game:GetService("ServerStorage").CurveForgeQA
	local ok, err = pcall(function()
		assert(require(qa.Suite)(qa.Modules), "Test failures")
		require(qa.Demo)(qa.Modules)
	end)
	if not ok then warn("[CurveForgeTests][RUNNER FAIL] " .. tostring(err)) end
end)
