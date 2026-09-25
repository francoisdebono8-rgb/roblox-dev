local modules = script.Parent.Parent.PresetForge.Modules
local Constants = require(modules.Constants)
local PresetStore = require(modules.PresetStore)
local ProjectStore = require(modules.ProjectStore)
local RecipeRepository = require(modules.RecipeRepository)

local settings = {}
local fakePlugin = {}
function fakePlugin:GetSetting(key)
	return settings[key]
end
function fakePlugin:SetSetting(key, value)
	settings[key] = value
end

local container = Instance.new("Folder")
container.Name = "ProjectStoreContainer"
local localStore = PresetStore.new(fakePlugin, Constants.STORE_KEY)
local projectStore = ProjectStore.new(container)
local repository = RecipeRepository.new(localStore, projectStore)
assert(repository:load())
assert(container:FindFirstChild(Constants.PROJECT_ROOT_NAME) == nil, "loading must not silently insert a project library")

local localRecipe = {
	schemaId = "BasePart",
	capture = { tags = false, attributes = false },
	properties = { Anchored = true },
	tags = {},
	attributes = {},
}
assert(repository:create("Local", "Local One", localRecipe))
assert(container:FindFirstChild(Constants.PROJECT_ROOT_NAME) == nil, "local saves must not touch the project")

local projectRecipe = {
	schemaId = "SurfaceLight",
	capture = { tags = true, attributes = true },
	properties = { Enabled = true, Face = Enum.NormalId.Top },
	tags = { "Lighting" },
	attributes = { Purpose = "Key" },
}
local created, createdRecipe = repository:create("Project", "Project Light", projectRecipe)
assert(created, tostring(createdRecipe))
local root = assert(container:FindFirstChild(Constants.PROJECT_ROOT_NAME))
assert(root.ClassName == "Folder" and root:GetAttribute("FormatVersion") == 2)
local node = assert(root:FindFirstChild("Project Light"))
assert(node.ClassName == "Configuration" and #node:GetChildren() == 3)
assert(node:FindFirstChild("Properties").ClassName == "Configuration")
assert(node:FindFirstChild("Properties"):GetAttribute("Face") == "Enum.NormalId.Top")
assert(node:FindFirstChild("Tags").ClassName == "Folder")
assert(node:FindFirstChild("Attributes").ClassName == "Configuration")

local reloadedProjectStore = ProjectStore.new(container)
assert(reloadedProjectStore:load())
local reloaded = assert(reloadedProjectStore:find("project light"))
assert(reloaded.properties.Face == Enum.NormalId.Top and reloaded.attributes.Purpose == "Key")
assert(reloaded.tags[1] == "Lighting")

local duplicate, duplicateError = repository:create("Project", "local one", projectRecipe)
assert(duplicate == false and duplicateError:find("Local or Project") ~= nil)
assert(projectStore:create("LOCAL ONE", projectRecipe))
local conflictRepository = RecipeRepository.new(
	PresetStore.new(fakePlugin, Constants.STORE_KEY),
	ProjectStore.new(container)
)
local conflictLoaded, conflictError = conflictRepository:load()
assert(conflictLoaded == false and conflictError:find("conflict between Local and Project") ~= nil)
assert(projectStore:delete("LOCAL ONE"))
local properties = node:FindFirstChild("Properties")
properties:SetAttribute("UnsafeProperty", true)
local accepted, tamperError = reloadedProjectStore:load()
assert(accepted == false and tamperError:find("unsupported property") ~= nil)
properties:SetAttribute("UnsafeProperty", nil)
assert(reloadedProjectStore:load())
local executable = Instance.new("Script")
executable.Name = "Unsafe"
executable.Parent = node
accepted, tamperError = reloadedProjectStore:load()
assert(accepted == false and tamperError:find("exactly") ~= nil)
executable:Destroy()
assert(reloadedProjectStore:load())

local changed = {
	schemaId = "SurfaceLight",
	capture = { tags = false, attributes = false },
	properties = { Face = Enum.NormalId.Bottom },
	tags = {},
	attributes = {},
}
assert(reloadedProjectStore:update("Project Light", changed))
assert(reloadedProjectStore:find("Project Light").properties.Face == Enum.NormalId.Bottom)
assert(reloadedProjectStore:rename("Project Light", "Shared Light"))
assert(reloadedProjectStore:find("Project Light") == nil and reloadedProjectStore:find("Shared Light") ~= nil)
assert(reloadedProjectStore:delete("Shared Light"))
assert(#reloadedProjectStore:getPresets() == 0)

container:Destroy()
return true
