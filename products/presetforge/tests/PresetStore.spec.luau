local modules = script.Parent.Parent.PresetForge.Modules
local AttributeCodec = require(modules.AttributeCodec)
local Constants = require(modules.Constants)
local PresetStore = require(modules.PresetStore)

local settings = {}
local fakePlugin = {}
function fakePlugin:GetSetting(key)
	return settings[key]
end
function fakePlugin:SetSetting(key, value)
	settings[key] = value
end

local attributes = {
	StringValue = "safe / persisted % value",
	BooleanValue = false,
	NumberValue = 12.5,
	UDimValue = UDim.new(0.5, 7),
	UDim2Value = UDim2.new(0.25, 2, 0.75, 4),
	BrickColorValue = BrickColor.new("Bright red"),
	Color3Value = Color3.fromRGB(12, 34, 56),
	Vector2Value = Vector2.new(3, 4),
	Vector3Value = Vector3.new(5, 6, 7),
	CFrameValue = CFrame.new(1, 2, 3) * CFrame.Angles(0.1, 0.2, 0.3),
	NumberRangeValue = NumberRange.new(2, 9),
	RectValue = Rect.new(1, 2, 8, 10),
	NumberSequenceValue = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1, 0.2),
		NumberSequenceKeypoint.new(1, 3, 0.4),
	}),
	ColorSequenceValue = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 20, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 50, 60)),
	}),
	FontValue = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.SemiBold,
		Enum.FontStyle.Italic
	),
}

local captured = {
	capture = { properties = true, tags = true, attributes = true },
	properties = {
		Anchored = true,
		CanCollide = false,
		CanTouch = true,
		CanQuery = false,
		Transparency = 0.35,
		CastShadow = false,
		Massless = true,
	},
	tags = { "Gameplay", "safe/tag" },
	attributes = attributes,
}

local store = PresetStore.new(fakePlugin, Constants.STORE_KEY)
assert(store:load() == true)
local created, createdPreset = store:create("Gameplay / Ghost", captured)
assert(created == true, tostring(createdPreset))

local reopenedStore = PresetStore.new(fakePlugin, Constants.STORE_KEY)
assert(reopenedStore:load() == true, "saved presets must load in a new store")
local loaded = reopenedStore:find("gameplay / ghost")
assert(loaded ~= nil and loaded.name == "Gameplay / Ghost")
assert(#loaded.tags == 2 and loaded.tags[2] == "safe/tag")
for name, value in pairs(attributes) do
	assert(AttributeCodec.equal(loaded.attributes[name], value), "attribute did not round-trip: " .. name)
end

assert(reopenedStore:create("Second", captured) == true)
local renamed, renameError = reopenedStore:rename("Gameplay / Ghost", "second")
assert(renamed == false and renameError:find("already exists") ~= nil, "duplicate rename must be refused")
assert(reopenedStore:rename("Gameplay / Ghost", "Ghost Parts") == true)
assert(reopenedStore:find("Ghost Parts") ~= nil)
assert(reopenedStore:find("Gameplay / Ghost") == nil)

assert(reopenedStore:delete("Ghost Parts") == true)
assert(reopenedStore:find("Ghost Parts") == nil)
local finalStore = PresetStore.new(fakePlugin, Constants.STORE_KEY)
assert(finalStore:load() == true)
assert(#finalStore:getPresets() == 1 and finalStore:getPresets()[1].name == "Second")

return true
