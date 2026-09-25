local StringCodec = require(script.Parent.StringCodec)

local AttributeCodec = {}

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function indexed(items)
	local encoded = { count = #items, items = {} }
	for index, value in ipairs(items) do
		encoded.items[tostring(index)] = value
	end
	return encoded
end

local function readIndexed(container, index)
	if type(container) ~= "table" or type(container.items) ~= "table" then
		return nil
	end
	return container.items[tostring(index)] or container.items[index]
end

local function encodeColor3(value)
	return { r = value.R, g = value.G, b = value.B }
end

local function decodeColor3(value)
	return Color3.new(value.r, value.g, value.b)
end

function AttributeCodec.encode(value)
	local kind = typeof(value)

	if kind == "string" then
		return { kind = kind, value = StringCodec.encode(value) }
	elseif kind == "boolean" then
		return { kind = kind, value = value }
	elseif kind == "number" then
		if not finite(value) then
			return nil, "Non-finite numbers cannot be persisted"
		end
		return { kind = kind, value = value }
	elseif kind == "UDim" then
		return { kind = kind, scale = value.Scale, offset = value.Offset }
	elseif kind == "UDim2" then
		return {
			kind = kind,
			xScale = value.X.Scale,
			xOffset = value.X.Offset,
			yScale = value.Y.Scale,
			yOffset = value.Y.Offset,
		}
	elseif kind == "BrickColor" then
		return { kind = kind, number = value.Number }
	elseif kind == "Color3" then
		local encoded = encodeColor3(value)
		encoded.kind = kind
		return encoded
	elseif kind == "Vector2" then
		return { kind = kind, x = value.X, y = value.Y }
	elseif kind == "Vector3" then
		return { kind = kind, x = value.X, y = value.Y, z = value.Z }
	elseif kind == "CFrame" then
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		return {
			kind = kind,
			x = x,
			y = y,
			z = z,
			r00 = r00,
			r01 = r01,
			r02 = r02,
			r10 = r10,
			r11 = r11,
			r12 = r12,
			r20 = r20,
			r21 = r21,
			r22 = r22,
		}
	elseif kind == "NumberRange" then
		return { kind = kind, min = value.Min, max = value.Max }
	elseif kind == "Rect" then
		return {
			kind = kind,
			minX = value.Min.X,
			minY = value.Min.Y,
			maxX = value.Max.X,
			maxY = value.Max.Y,
		}
	elseif kind == "NumberSequence" then
		local keypoints = {}
		for _, point in ipairs(value.Keypoints) do
			keypoints[#keypoints + 1] = {
				time = point.Time,
				value = point.Value,
				envelope = point.Envelope,
			}
		end
		local encoded = indexed(keypoints)
		encoded.kind = kind
		return encoded
	elseif kind == "ColorSequence" then
		local keypoints = {}
		for _, point in ipairs(value.Keypoints) do
			keypoints[#keypoints + 1] = {
				time = point.Time,
				value = encodeColor3(point.Value),
			}
		end
		local encoded = indexed(keypoints)
		encoded.kind = kind
		return encoded
	elseif kind == "Font" then
		return {
			kind = kind,
			family = StringCodec.encode(value.Family),
			weight = value.Weight.Name,
			style = value.Style.Name,
		}
	end

	return nil, "Unsupported attribute type: " .. tostring(kind)
end

function AttributeCodec.decode(encoded)
	if type(encoded) ~= "table" or type(encoded.kind) ~= "string" then
		return nil, "Invalid encoded attribute"
	end

	local kind = encoded.kind
	local ok, value = pcall(function()
		if kind == "string" then
			local decoded, decodeError = StringCodec.decode(encoded.value)
			if not decoded then
				error(decodeError)
			end
			return decoded
		elseif kind == "boolean" then
			assert(type(encoded.value) == "boolean")
			return encoded.value
		elseif kind == "number" then
			assert(finite(encoded.value))
			return encoded.value
		elseif kind == "UDim" then
			return UDim.new(encoded.scale, encoded.offset)
		elseif kind == "UDim2" then
			return UDim2.new(encoded.xScale, encoded.xOffset, encoded.yScale, encoded.yOffset)
		elseif kind == "BrickColor" then
			return BrickColor.new(encoded.number)
		elseif kind == "Color3" then
			return decodeColor3(encoded)
		elseif kind == "Vector2" then
			return Vector2.new(encoded.x, encoded.y)
		elseif kind == "Vector3" then
			return Vector3.new(encoded.x, encoded.y, encoded.z)
		elseif kind == "CFrame" then
			return CFrame.new(
				encoded.x,
				encoded.y,
				encoded.z,
				encoded.r00,
				encoded.r01,
				encoded.r02,
				encoded.r10,
				encoded.r11,
				encoded.r12,
				encoded.r20,
				encoded.r21,
				encoded.r22
			)
		elseif kind == "NumberRange" then
			return NumberRange.new(encoded.min, encoded.max)
		elseif kind == "Rect" then
			return Rect.new(encoded.minX, encoded.minY, encoded.maxX, encoded.maxY)
		elseif kind == "NumberSequence" then
			local points = table.create(encoded.count)
			for index = 1, encoded.count do
				local point = assert(readIndexed(encoded, index))
				points[index] = NumberSequenceKeypoint.new(point.time, point.value, point.envelope)
			end
			return NumberSequence.new(points)
		elseif kind == "ColorSequence" then
			local points = table.create(encoded.count)
			for index = 1, encoded.count do
				local point = assert(readIndexed(encoded, index))
				points[index] = ColorSequenceKeypoint.new(point.time, decodeColor3(point.value))
			end
			return ColorSequence.new(points)
		elseif kind == "Font" then
			local family = assert(StringCodec.decode(encoded.family))
			local weight = assert(Enum.FontWeight[encoded.weight])
			local style = assert(Enum.FontStyle[encoded.style])
			return Font.new(family, weight, style)
		end

		error("Unsupported encoded attribute type: " .. kind)
	end)

	if not ok then
		return nil, tostring(value)
	end
	return value
end

local function deepEqual(left, right)
	if type(left) ~= type(right) then
		return false
	elseif type(left) ~= "table" then
		return left == right
	end

	for key, value in pairs(left) do
		if not deepEqual(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

function AttributeCodec.equal(left, right)
	local leftEncoded = AttributeCodec.encode(left)
	local rightEncoded = AttributeCodec.encode(right)
	return leftEncoded ~= nil and rightEncoded ~= nil and deepEqual(leftEncoded, rightEncoded)
end

return AttributeCodec
