local SelectionNavigator = {}

function SelectionNavigator.frame(instances, camera)
	if not camera then
		return false, "No scene camera is available"
	end
	local minimum, maximum
	local seen = {}
	for _, instance in ipairs(instances) do
		local spatial = instance
		while spatial and not spatial:IsA("BasePart") and not spatial:IsA("Model") do
			spatial = spatial.Parent
		end
		if spatial and spatial:IsDescendantOf(workspace) and not seen[spatial] then
			seen[spatial] = true
			local frame, size
			if spatial:IsA("BasePart") then
				frame, size = spatial.CFrame, spatial.Size
			elseif spatial:FindFirstChildWhichIsA("BasePart", true) then
				frame, size = spatial:GetBoundingBox()
			end
			if frame then
				for x = -1, 1, 2 do
					for y = -1, 1, 2 do
						for z = -1, 1, 2 do
							local point = frame:PointToWorldSpace(size * Vector3.new(x, y, z) / 2)
							minimum = minimum and minimum:Min(point) or point
							maximum = maximum and maximum:Max(point) or point
						end
					end
				end
			end
		end
	end
	if not minimum then
		return false, "No 3D bounds to frame. Use Select to locate these objects in Explorer."
	end
	local ok = pcall(function()
		camera:ZoomToExtents(CFrame.new((minimum + maximum) / 2), (maximum - minimum):Max(Vector3.new(1, 1, 1)))
	end)
	if not ok then return false, "Could not frame these objects in the scene camera" end
	return true
end

return SelectionNavigator
