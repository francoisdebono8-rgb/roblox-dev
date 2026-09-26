local Schema = {}

Schema.types = { "WeldConstraint", "Weld", "Motor6D", "HingeConstraint", "BallSocketConstraint", "RopeConstraint", "RodConstraint", "SpringConstraint", "NoCollisionConstraint" }
Schema.fields = {
	WeldConstraint = { "Enabled" },
	Weld = { "Enabled", "C0", "C1" },
	Motor6D = { "Enabled", "C0", "C1" },
	NoCollisionConstraint = { "Enabled" },
	HingeConstraint = { "Enabled", "Visible", "LimitsEnabled", "LowerAngle", "UpperAngle", "ActuatorType", "AngularVelocity", "MotorMaxTorque", "AngularSpeed", "TargetAngle", "ServoMaxTorque" },
	BallSocketConstraint = { "Enabled", "Visible", "LimitsEnabled", "UpperAngle", "TwistLimitsEnabled", "TwistLowerAngle", "TwistUpperAngle", "MaxFrictionTorque" },
	RopeConstraint = { "Enabled", "Visible", "Length", "Restitution", "Thickness" },
	RodConstraint = { "Enabled", "Visible", "Length", "Thickness" },
	SpringConstraint = { "Enabled", "Visible", "FreeLength", "Stiffness", "Damping", "MaxForce", "LimitsEnabled", "MinLength", "MaxLength" },
}

function Schema.supported(instance)
	return Schema.fields[instance.ClassName] ~= nil
end

function Schema.usesAttachments(class)
	return class == "HingeConstraint" or class == "BallSocketConstraint" or class == "RopeConstraint" or class == "RodConstraint" or class == "SpringConstraint"
end

function Schema.finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end

function Schema.validValue(value)
	if typeof(value) == "CFrame" then
		for _, n in ipairs({ value:GetComponents() }) do
			if not Schema.finite(n) then return false end
		end
		return true
	end
	return typeof(value) ~= "number" or Schema.finite(value)
end

function Schema.parse(text, sample)
	if typeof(sample) == "number" then
		local n = tonumber(text)
		assert(Schema.finite(n), "Enter a finite number.")
		return n
	elseif typeof(sample) == "CFrame" then
		local values = {}
		for word in string.gmatch(text, "[^,%s]+") do
			local n = tonumber(word)
			assert(Schema.finite(n), "CFrame requires six finite numbers: X Y Z RX RY RZ.")
			table.insert(values, n)
		end
		assert(#values == 6, "Use X Y Z RX RY RZ (rotation in degrees).")
		return CFrame.new(values[1], values[2], values[3]) * CFrame.fromOrientation(math.rad(values[4]), math.rad(values[5]), math.rad(values[6]))
	end
	error("Unsupported field type")
end

function Schema.format(value)
	if typeof(value) == "CFrame" then
		local rx, ry, rz = value:ToOrientation()
		return string.format("%.6g %.6g %.6g  %.6g %.6g %.6g", value.X, value.Y, value.Z, math.deg(rx), math.deg(ry), math.deg(rz))
	elseif typeof(value) == "EnumItem" then
		return value.Name
	end
	return tostring(value)
end

-- Validate using a detached instance so engine clamping never silently changes a request.
function Schema.validateChanges(joint, changes)
	assert(Schema.supported(joint), "This class is inspect-only.")
	local probe = Instance.new(joint.ClassName)
	local ok, err = pcall(function()
		for _, field in ipairs(Schema.fields[joint.ClassName]) do probe[field] = joint[field] end
		for field, value in pairs(changes) do
			assert(table.find(Schema.fields[joint.ClassName], field), "Unsupported field: " .. field)
			assert(typeof(value) == typeof(joint[field]) and Schema.validValue(value), "Invalid " .. field)
			probe[field] = value
		end
		for field, value in pairs(changes) do
			if typeof(value) == "number" then
				assert(math.abs(probe[field] - value) <= math.max(1, math.abs(value)) * 1e-6, field .. " is outside the engine's accepted range.")
			end
		end
		if joint:IsA("HingeConstraint") then assert(probe.LowerAngle <= probe.UpperAngle, "LowerAngle must not exceed UpperAngle.") end
		if joint:IsA("BallSocketConstraint") then assert(probe.TwistLowerAngle <= probe.TwistUpperAngle, "TwistLowerAngle must not exceed TwistUpperAngle.") end
		if joint:IsA("SpringConstraint") then assert(probe.MinLength <= probe.MaxLength, "MinLength must not exceed MaxLength.") end
	end)
	probe:Destroy()
	assert(ok, err)
end

return Schema
