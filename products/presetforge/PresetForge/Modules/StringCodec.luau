local StringCodec = {}

function StringCodec.encode(value)
	assert(type(value) == "string", "StringCodec.encode expects a string")

	local bytes = table.create(#value)
	for index = 1, #value do
		bytes[index] = string.format("%02x", string.byte(value, index))
	end
	return table.concat(bytes)
end

function StringCodec.decode(value)
	if type(value) ~= "string" or #value % 2 ~= 0 or value:find("[^0-9a-f]") then
		return nil, "Invalid encoded string"
	end

	local characters = table.create(#value / 2)
	for index = 1, #value, 2 do
		characters[#characters + 1] = string.char(tonumber(value:sub(index, index + 1), 16))
	end
	return table.concat(characters)
end

return StringCodec
