if workspace:GetAttribute("SchemaForgeQA") then
	task.defer(function()
		local ok, err = pcall(function() assert(require(game.ServerStorage.SchemaForgeSuite)(game.ServerStorage.SchemaForgeCommercial.Modules), "Native test failures") end)
		if not ok then warn("[SchemaForgeTests][RUNNER FAIL] " .. tostring(err)) end
	end)
elseif workspace:GetAttribute("SchemaForgeMediaBuild") then
	task.defer(function()
		local ok, err = pcall(require(game.ServerStorage.SchemaForgeMediaSetup))
		if not ok then warn("[SchemaForgeMedia][FAIL] " .. tostring(err)) end
	end)
end
