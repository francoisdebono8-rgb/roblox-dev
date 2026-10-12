if not workspace:GetAttribute("JointForgeTestPlace") then return end
task.defer(function()
	local ok, err = pcall(require(script.Parent.Suite), script.Parent.Modules)
	if not ok then warn("[JointForgeTests][FAIL] " .. tostring(err)) end
end)
