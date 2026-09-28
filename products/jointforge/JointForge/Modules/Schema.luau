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

-- Exact equality is used for freshness. Only native numeric representation gets
-- tolerance at preflight/readback; explicit bounds prevent tiny clamps hiding in it.
function Schema.accepted(actual, wanted)
	if typeof(actual) ~= typeof(wanted) then return false end
	if actual == wanted then return true end
	if typeof(wanted) == "number" then
		return Schema.finite(actual) and Schema.finite(wanted)
			and math.abs(actual - wanted) <= math.max(1, math.abs(wanted)) * 1e-6
	elseif typeof(wanted) == "CFrame" then
		if not Schema.validValue(actual) or not Schema.validValue(wanted) then return false end
		local a, b = { actual:GetComponents() }, { wanted:GetComponents() }
		for i, value in ipairs(a) do if not Schema.accepted(value, b[i]) then return false end end
		return true
	end
	return false
end

local bounds = {
	LowerAngle = {-180, 180}, UpperAngle = {-180, 180}, TwistLowerAngle = {-180, 180}, TwistUpperAngle = {-180, 180},
	Restitution = {0, 1}, Thickness = {0}, AngularSpeed = {0}, MotorMaxTorque = {0}, ServoMaxTorque = {0},
	MaxFrictionTorque = {0}, Length = {0}, FreeLength = {0.1}, Stiffness = {0}, Damping = {0}, MaxForce = {0},
	MinLength = {0}, MaxLength = {0.1},
}

function Schema.read(joint)
	local values = {}
	for _, field in ipairs(Schema.fields[joint.ClassName]) do values[field] = joint[field] end
	return values
end

function Schema.validateChanges(joint, changes)
	assert(Schema.supported(joint), "This class is inspect-only.")
	assert(type(changes) == "table", "Supply explicit field changes.")
	local values = Schema.read(joint)
	for field, value in pairs(changes) do
		assert(table.find(Schema.fields[joint.ClassName], field), "Unsupported field: " .. tostring(field))
		assert(typeof(value) == typeof(joint[field]) and Schema.validValue(value), "Invalid " .. field)
		if typeof(value) == "EnumItem" then assert(value.EnumType == joint[field].EnumType, "Wrong enum for " .. field) end
		local range = bounds[field]
		if range then
			local minimum = if field == "Length" and joint:IsA("RodConstraint") then 0.2
				elseif field == "UpperAngle" and joint:IsA("BallSocketConstraint") then 0 else range[1]
			assert(value >= minimum and (not range[2] or value <= range[2]), field .. " is outside the accepted bounds.")
		end
		values[field] = value
	end
	if joint:IsA("HingeConstraint") then assert(values.LowerAngle <= values.UpperAngle, "LowerAngle must not exceed UpperAngle.") end
	if joint:IsA("BallSocketConstraint") then assert(values.TwistLowerAngle <= values.TwistUpperAngle, "TwistLowerAngle must not exceed TwistUpperAngle.") end
	if joint:IsA("SpringConstraint") then assert(values.MinLength <= values.MaxLength, "MinLength must not exceed MaxLength.") end
	local probe, accepted = Instance.new(joint.ClassName), {}
	local ok, err = pcall(function()
		for _, field in ipairs(Schema.fields[joint.ClassName]) do probe[field] = values[field] end
		for _, field in ipairs(Schema.fields[joint.ClassName]) do
			assert(Schema.accepted(probe[field], values[field]), field .. " was clamped/coerced by the engine.")
			accepted[field] = probe[field]
		end
	end)
	probe:Destroy()
	assert(ok, err)
	return accepted
end

function Schema.writeOrder(class, before, after)
	local order = table.clone(Schema.fields[class])
	for _, pair in ipairs({ {"LowerAngle", "UpperAngle"}, {"TwistLowerAngle", "TwistUpperAngle"}, {"MinLength", "MaxLength"} }) do
		local lower, upper = table.find(order, pair[1]), table.find(order, pair[2])
		if lower and upper and after[pair[1]] > before[pair[2]] then order[lower], order[upper] = order[upper], order[lower] end
	end
	return order
end

return Schema
