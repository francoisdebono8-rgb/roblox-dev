local Constants = {}

Constants.STORE_KEY = "PresetForgePresetsV1"
Constants.STORE_VERSION = 2
Constants.LEGACY_STORE_VERSION = 1
Constants.MAX_NAME_BYTES = 40
Constants.MAX_FILTER_BYTES = 80
Constants.MAX_RENDERED_RESULTS = 500
Constants.PROJECT_ROOT_NAME = "PresetForgeProjectRecipes"
Constants.PROJECT_FORMAT_VERSION = 2
Constants.VERSION = "2.2.0"
Constants.SCHEMA_VERSION = 1
Constants.MAX_ROOTS = 256
Constants.MAX_SCANNED = 20000
Constants.MAX_COMPATIBLE = 5000
Constants.MAX_AFFECTED = 2000
Constants.MAX_WRITES = 20000
Constants.MAX_RECIPES = 256
Constants.MAX_TAGS = 64
Constants.MAX_ATTRIBUTES = 64
Constants.MAX_STRING_BYTES = 16384
Constants.MAX_PERSISTED_BYTES = 4194304

Constants.LEGACY_PROPERTIES = {
	"Anchored",
	"CanCollide",
	"CanTouch",
	"CanQuery",
	"Transparency",
	"CastShadow",
	"Massless",
}

Constants.PROPERTIES = Constants.LEGACY_PROPERTIES

return Constants
