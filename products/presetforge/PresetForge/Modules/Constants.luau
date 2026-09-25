local Constants = {}

Constants.STORE_KEY = "PresetForgePresetsV1"
Constants.STORE_VERSION = 2
Constants.LEGACY_STORE_VERSION = 1
Constants.MAX_NAME_BYTES = 40
Constants.MAX_FILTER_BYTES = 80
Constants.MAX_RENDERED_RESULTS = 500
Constants.PROJECT_ROOT_NAME = "PresetForgeProjectRecipes"
Constants.PROJECT_FORMAT_VERSION = 2
Constants.VERSION = "2.0.0"

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
