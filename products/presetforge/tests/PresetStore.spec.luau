local CollectionService = game:GetService("CollectionService")

local modules = script.Parent.Parent.PresetForge.Modules
local AttributeCodec = require(modules.AttributeCodec)
local CaptureService = require(modules.CaptureService)
local Constants = require(modules.Constants)
local PresetStore = require(modules.PresetStore)
local StringCodec = require(modules.StringCodec)

local function indexed(items)
	local result = { count = #items, items = {} }
	for index, value in ipairs(items) do
		result.items[tostring(index)] = value
	end
	return result
end

local legacyProperties = {
	Anchored = true,
	CanCollide = false,
	CanTouch = true,
	CanQuery = false,
	Transparency = 0.35,
	CastShadow = false,
	Massless = true,
}
local legacyAttribute = assert(AttributeCodec.encode("legacy"))
local settings = {
	[Constants.STORE_KEY] = {
		version = 1,
		count = 1,
		items = {
			["1"] = {
				name = StringCodec.encode("Legacy V1"),
				capture = { properties = true, tags = true, attributes = true },
				properties = legacyProperties,
				tags = indexed({ StringCodec.encode("LegacyTag") }),
				attributes = indexed({ {
					name = StringCodec.encode("LegacyAttribute"),
					value = legacyAttribute,
				} }),
			},
		},
	},
}
local fakePlugin = {}
function fakePlugin:GetSetting(key)
	return settings[key]
end
function fakePlugin:SetSetting(key, value)
	settings[key] = value
end

local store = PresetStore.new(fakePlugin, Constants.STORE_KEY)
assert(store:load())
local migrated = assert(store:find("legacy v1"))
assert(migrated.schemaId == "BasePart")
for _, propertyName in ipairs(Constants.LEGACY_PROPERTIES) do
	assert(migrated.properties[propertyName] == legacyProperties[propertyName])
end
assert(migrated.tags[1] == "LegacyTag" and migrated.attributes.LegacyAttribute == "legacy")

local source = Instance.new("Part")
source.Anchored = false
source.Transparency = 0.6
local captureService = CaptureService.new(CollectionService)
local edited = assert(captureService:capture({ source }, {
	properties = { "Anchored", "Transparency" },
	tags = false,
	attributes = false,
}))
local updated, updatedRecipe = store:update("Legacy V1", edited)
assert(updated, tostring(updatedRecipe))
assert(settings[Constants.STORE_KEY].version == 2, "editing a V1 recipe must persist V2 storage")
local reopened = PresetStore.new(fakePlugin, Constants.STORE_KEY)
assert(reopened:load())
local loaded = assert(reopened:find("Legacy V1"))
assert(loaded.properties.Anchored == false and math.abs(loaded.properties.Transparency - 0.6) < 1e-6)
assert(loaded.properties.CanCollide == nil, "editing must preserve the chosen field set")

source.Anchored = true
source.Transparency = 0.2
local recaptured, recaptureSource = captureService:recapture(loaded, { source })
assert(recaptured and recaptureSource == source)
assert(recaptured.properties.Anchored == true and math.abs(recaptured.properties.Transparency - 0.2) < 1e-6)
assert(recaptured.properties.CanCollide == nil)
local sound = Instance.new("Sound")
local invalidRecapture, recaptureError = captureService:recapture(loaded, { sound })
assert(invalidRecapture == nil and recaptureError:find("not valid for Sound") ~= nil)

assert(reopened:create("Second", edited))
local duplicate, duplicateError = reopened:rename("Legacy V1", "second")
assert(duplicate == false and duplicateError:find("already exists") ~= nil)
assert(reopened:rename("Legacy V1", "Edited Recipe"))
assert(reopened:delete("Edited Recipe"))
local finalStore = PresetStore.new(fakePlugin, Constants.STORE_KEY)
assert(finalStore:load())
assert(#finalStore:getPresets() == 1 and finalStore:getPresets()[1].name == "Second")

source:Destroy()
sound:Destroy()
return true
