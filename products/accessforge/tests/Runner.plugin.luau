if workspace:GetAttribute("AccessForgeMediaBuild") then
	task.defer(function()
		local ok, err = pcall(require(game.ServerStorage.AccessForgeMediaSetup))
		if not ok then warn("[AccessForgeMedia][FAIL] " .. tostring(err)) end
	end)
	return
end
if not workspace:GetAttribute("AccessForgeQA") then return end
task.defer(function()
	local root = game:GetService("ServerStorage")
	local ok, err = pcall(function() assert(require(root.AccessForgeSuite)(root.AccessForgeCommercial.Modules), "Native test failures") end)
	if not ok then warn("[AccessForgeTests][RUNNER FAIL] " .. tostring(err)) end
end)
