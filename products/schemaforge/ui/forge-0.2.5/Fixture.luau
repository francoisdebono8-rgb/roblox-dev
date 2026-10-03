local Fixture = {}

function Fixture.create(Schema)
	assert(not workspace:FindFirstChild("SchemaForge025Greenhouse"), "Existing fixture must not be overwritten")
	local folder = Instance.new("Folder")
	folder.Name = "SchemaForge025Greenhouse"
	folder.Parent = workspace
	local objects = {}
	for index = 0, 7 do
		local pot = Instance.new("Part")
		pot.Name = index == 0 and "ReferencePot" or string.format("PlantPot%02d", index)
		pot.Anchored = true
		pot.Size = Vector3.new(3, 2, 3)
		pot.Position = Vector3.new((index % 4) * 6, 1, math.floor(index / 4) * 6)
		pot.Color = Color3.fromRGB(92, 145, 115)
		pot:SetAttribute("Cost", 25); pot:SetAttribute("GrowthRate", 1); pot:SetAttribute("Enabled", true)
		pot:AddTag("PlantPot"); pot:AddTag("Interactable")
		local attachment = Instance.new("Attachment"); attachment.Name = "InteractionAnchor"; attachment.Parent = pot
		pot.Parent = folder; objects[index+1] = pot
	end
	objects[4]:SetAttribute("Cost", nil)
	objects[5]:SetAttribute("Cost", nil); objects[5]:RemoveTag("Interactable")
	objects[6]:SetAttribute("Cost", "unknown")
	objects[7]:SetAttribute("GrowthRate", -2)
	objects[8].InteractionAnchor:Destroy(); objects[8]:AddTag("Retired")
	local schema = Schema.capture(objects[1])
	schema.name = "Greenhouse Contract"; schema.tag = "PlantPot"
	schema.requiredTags = {"Interactable"}; schema.forbiddenTags = {"Retired"}
	for _, rule in ipairs(schema.fields) do
		rule.hasDefault = true
		rule.description = rule.name == "Cost" and "Purchase cost in coins. Missing costs use the starter-pot price." or "Shared greenhouse configuration."
		if rule.kind == "number" then rule.min = 0 end
	end
	schema.children = {{path="InteractionAnchor", className="Attachment", optional=false, description="Anchor used by interaction prompts."}}
	Schema.validate(schema)
	return {root=folder, reference=objects[1], objects=objects, schema=schema, roots={folder}}
end

return Fixture
