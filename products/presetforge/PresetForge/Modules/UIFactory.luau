local Constants = require(script.Parent.Constants)
local TextService = game:GetService("TextService")

local UIFactory = {}
local contexts = setmetatable({}, { __mode = "k" })

local function studioSettings()
	local ok, studio = pcall(function()
		return settings().Studio
	end)
	return ok and studio or nil
end

local function palette(studio)
	local colors = {
		background = Color3.fromRGB(29, 31, 34),
		panel = Color3.fromRGB(38, 41, 45),
		panelHover = Color3.fromRGB(48, 52, 57),
		border = Color3.fromRGB(86, 92, 99),
		text = Color3.fromRGB(239, 242, 244),
		muted = Color3.fromRGB(174, 182, 190),
		accent = Color3.fromRGB(34, 184, 207),
		accentHover = Color3.fromRGB(67, 204, 224),
		onAccent = Color3.fromRGB(12, 34, 39),
		danger = Color3.fromRGB(255, 139, 139),
		success = Color3.fromRGB(116, 214, 158),
		warning = Color3.fromRGB(245, 198, 106),
	}
	if studio then
		local theme = studio.Theme
		colors.background = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		colors.panel = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		colors.panelHover = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		colors.border = theme:GetColor(Enum.StudioStyleGuideColor.Border)
		colors.text = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		colors.muted = theme:GetColor(Enum.StudioStyleGuideColor.SubText)
	end
	local light = colors.background.R + colors.background.G + colors.background.B > 1.5
	colors.accentDark = colors.background:Lerp(colors.accent, light and 0.18 or 0.22)
	colors.accentText = light and Color3.fromRGB(0, 102, 120) or colors.accent
	if light then
		colors.danger = Color3.fromRGB(174, 37, 43)
		colors.success = Color3.fromRGB(30, 112, 66)
		colors.warning = Color3.fromRGB(135, 84, 0)
	end
	return colors
end

local fallbackColors = palette(nil)

local function contextFor(instance)
	while instance do
		if contexts[instance] then
			return contexts[instance]
		end
		instance = instance.Parent
	end
	return nil
end

local function paint(instance, property, role)
	local context = contextFor(instance)
	instance[property] = (context and context.colors or fallbackColors)[role]
	if context then
		local roles = context.styles[instance] or {}
		roles[property] = role
		context.styles[instance] = roles
	end
end

local function listen(owner, signal, callback)
	local connection = signal:Connect(callback)
	local context = contextFor(owner)
	if context then
		local connections = context.connections[owner]
		if not connections then
			connections = {}
			context.connections[owner] = connections
			if not contexts[owner] then
				connections[1] = owner.Destroying:Connect(function()
					for _, owned in ipairs(connections) do
						owned:Disconnect()
					end
					context.connections[owner] = nil
					context.styles[owner] = nil
				end)
			end
		end
		connections[#connections + 1] = connection
	end
	return connection
end

local function create(className, properties, parent)
	local instance = Instance.new(className)
	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
		instance.LayoutOrder = parent and #parent:GetChildren() + 1 or 0
		if parent and parent:IsA("GuiObject") then
			instance.ZIndex = parent.ZIndex
		end
	end
	for property, value in pairs(properties) do
		instance[property] = value
	end
	instance.Parent = parent
	return instance
end

local function padding(parent, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	}, parent)
end

local function border(parent, role)
	create("UICorner", { CornerRadius = UDim.new(0, 4) }, parent)
	local result = create("UIStroke", {
		Name = "Border",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
	}, parent)
	paint(result, "Color", role or "border")
	return result
end

local function stack(parent, name)
	local result = create("Frame", {
		Name = name,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
	}, parent)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, result)
	return result
end

local function fitWrappedText(target)
	local minimum = target.Size.Y.Offset
	local function resizeText()
		if target.AutomaticSize ~= Enum.AutomaticSize.Y or target.AbsoluteSize.X <= 0 then
			return
		end
		local inset = target:FindFirstChildOfClass("UIPadding")
		local horizontal = inset and (inset.PaddingLeft.Offset + inset.PaddingRight.Offset) or 0
		local vertical = inset and (inset.PaddingTop.Offset + inset.PaddingBottom.Offset) or 0
		-- Measure beyond the scroll viewport: automatic Y can otherwise use clipped text bounds.
		local bounds = TextService:GetTextSize(target.Text, target.TextSize, target.Font,
			Vector2.new(math.max(1, target.AbsoluteSize.X - horizontal), 1000000))
		local height = math.max(minimum, math.ceil(bounds.Y) + vertical + 2)
		if target.Size.Y.Offset ~= height then
			target.Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset, 0, height)
		end
	end
	for _, property in ipairs({ "AbsoluteSize", "Text", "TextSize", "Font", "AutomaticSize" }) do
		listen(target, target:GetPropertyChangedSignal(property), resizeText)
	end
	resizeText()
end

local function label(parent, text, size, role, bold)
	local result = create("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans,
		Size = UDim2.new(1, 0, 0, size + 6),
		Text = text,
		TextSize = size,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, parent)
	paint(result, "TextColor3", role or "text")
	fitWrappedText(result)
	return result
end

local function renderButton(target)
	local selected = target:GetAttribute("Selected") or target:GetAttribute("Checked")
	local primary = target:GetAttribute("Primary")
	local hover = target:GetAttribute("Hovered") and target.Active
	paint(target, "BackgroundColor3", selected and "accentDark"
		or primary and (hover and "accentHover" or "accent")
		or hover and "panelHover" or "panel")
	local outline = target:FindFirstChildOfClass("UIStroke")
	if outline then
		paint(outline, "Color", (selected or primary) and "accent" or "border")
	end
end

local function button(parent, text, primary)
	local result = create("TextButton", {
		AutoButtonColor = false,
		Font = Enum.Font.BuilderSansBold,
		Size = UDim2.new(1, 0, 0, 32),
		Text = text,
		TextSize = 13,
		TextWrapped = true,
	}, parent)
	result:SetAttribute("Primary", primary == true)
	paint(result, "TextColor3", primary and "onAccent" or "text")
	border(result)
	listen(result, result.MouseEnter, function()
		result:SetAttribute("Hovered", true)
		renderButton(result)
	end)
	listen(result, result.MouseLeave, function()
		result:SetAttribute("Hovered", false)
		renderButton(result)
	end)
	renderButton(result)
	return result
end

local function textBox(parent, placeholder)
	local result = create("TextBox", {
		AutomaticSize = Enum.AutomaticSize.Y,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		MultiLine = false,
		PlaceholderText = placeholder,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	paint(result, "BackgroundColor3", "panel")
	paint(result, "TextColor3", "text")
	paint(result, "PlaceholderColor3", "muted")
	padding(result, 7, 8, 7, 8)
	border(result)
	fitWrappedText(result)
	return result
end

local function pair(parent, name)
	return create("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
	}, parent)
end

local function inPair(target, index)
	target.Size = UDim2.new(0.5, -4, 1, 0)
	target.Position = UDim2.new((index - 1) * 0.5, (index - 1) * 4, 0, 0)
	return target
end

local function scroll(parent, name)
	local result = create("ScrollingFrame", {
		Name = name,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, parent)
	paint(result, "ScrollBarImageColor3", "border")
	padding(result, 12, 16, 12, 12)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, result)
	return result
end

function UIFactory.setButtonEnabled(target, enabled)
	target.Active = enabled
	target.Selectable = enabled
	target.TextTransparency = enabled and 0 or 0.5
	target.BackgroundTransparency = enabled and 0 or 0.35
	local outline = target:FindFirstChildOfClass("UIStroke")
	if outline then
		outline.Transparency = enabled and 0 or 0.55
	end
	renderButton(target)
end

function UIFactory.setSegment(target, selected)
	target:SetAttribute("Selected", selected)
	renderButton(target)
end

function UIFactory.createCheckbox(parent, text, checked)
	local result = button(parent, text, false)
	result.Name = "FieldCheckbox"
	result.AutomaticSize = Enum.AutomaticSize.Y
	result.Font = Enum.Font.BuilderSans
	result.Size = UDim2.new(1, 0, 0, 34)
	result.TextXAlignment = Enum.TextXAlignment.Left
	result.TextYAlignment = Enum.TextYAlignment.Top
	padding(result, 8, 8, 8, 36)
	fitWrappedText(result)
	result:SetAttribute("Label", text)
	local box = create("Frame", {
		Name = "Checkbox",
		Position = UDim2.fromOffset(-28, 0),
		Size = UDim2.fromOffset(16, 16),
	}, result)
	border(box)
	local mark = label(box, utf8.char(0x2713), 14, "onAccent", true)
	mark.Name = "Checkmark"
	mark.AutomaticSize = Enum.AutomaticSize.None
	mark.Size = UDim2.fromScale(1, 1)
	mark.TextXAlignment = Enum.TextXAlignment.Center
	mark.TextYAlignment = Enum.TextYAlignment.Center
	local function layer()
		box.ZIndex = result.ZIndex + 1
		mark.ZIndex = result.ZIndex + 2
	end
	listen(result, result:GetPropertyChangedSignal("ZIndex"), layer)
	layer()
	local function render()
		local value = result:GetAttribute("Checked") == true
		mark.Visible = value
		paint(box, "BackgroundColor3", value and "accent" or "panel")
		renderButton(result)
	end
	listen(result, result:GetAttributeChangedSignal("Checked"), render)
	listen(result, result.Activated, function()
		if result.Active then
			UIFactory.setCheckbox(result, not result:GetAttribute("Checked"))
		end
	end)
	UIFactory.setCheckbox(result, checked == true)
	render()
	return result
end

function UIFactory.setCheckbox(target, checked, text)
	if text then
		target:SetAttribute("Label", text)
	end
	target.Text = target:GetAttribute("Label") or target.Text
	target:SetAttribute("Checked", checked == true)
	renderButton(target)
end

function UIFactory.createPresetButton(parent, recipe, selected)
	local result = button(parent, string.format("%s\n%s | %s", recipe.name, recipe.library, recipe.schemaId), false)
	result.Name = "PresetButton"
	result.AutomaticSize = Enum.AutomaticSize.Y
	result.Size = UDim2.new(1, 0, 0, 48)
	result.Font = selected and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans
	result.TextSize = 14
	result.TextXAlignment = Enum.TextXAlignment.Left
	result.TextYAlignment = Enum.TextYAlignment.Top
	result:SetAttribute("RecipeName", recipe.name)
	result:SetAttribute("Library", recipe.library)
	padding(result, 8, 8, 8, 8)
	fitWrappedText(result)
	UIFactory.setSegment(result, selected)
	return result
end

function UIFactory.createResultButton(parent, text, status)
	local result = button(parent, text, false)
	result.Name = "ResultButton"
	result.AutomaticSize = Enum.AutomaticSize.Y
	result.Size = UDim2.new(1, 0, 0, 42)
	result.Font = Enum.Font.BuilderSans
	result.TextSize = 13
	result.TextXAlignment = Enum.TextXAlignment.Left
	result.TextYAlignment = Enum.TextYAlignment.Top
	result:SetAttribute("Status", status)
	padding(result, 8, 8, 8, 12)
	fitWrappedText(result)
	local tone = status == "affected" and "warning" or status == "matching" and "success"
		or status == "invalid" and "danger" or "muted"
	local marker = create("Frame", {
		Name = "StatusMarker",
		Position = UDim2.fromOffset(-8, 0),
		Size = UDim2.new(0, 2, 0, 20),
	}, result)
	paint(marker, "BackgroundColor3", tone)
	return result
end

local function refreshTheme(root, context, studio)
	local nextColors = palette(studio)
	local descendants = root:GetDescendants()
	descendants[#descendants + 1] = root
	for _, instance in ipairs(descendants) do
		local properties = {}
		if instance:IsA("GuiObject") then
			properties[#properties + 1] = "BackgroundColor3"
		end
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			properties[#properties + 1] = "TextColor3"
		end
		if instance:IsA("TextBox") then
			properties[#properties + 1] = "PlaceholderColor3"
		elseif instance:IsA("ScrollingFrame") then
			properties[#properties + 1] = "ScrollBarImageColor3"
		elseif instance:IsA("UIStroke") then
			properties[#properties + 1] = "Color"
		end
		local roles = context.styles[instance] or {}
		for _, property in ipairs(properties) do
			local role = roles[property]
			-- Controller writes tones directly; preserve its current semantic color.
			if not role or instance[property] ~= context.colors[role] then
				role = nil
				for candidate, oldColor in pairs(context.colors) do
					if instance[property] == oldColor then
						role = candidate
						break
					end
				end
			end
			if role then
				instance[property] = nextColors[role]
				roles[property] = role
			end
		end
		context.styles[instance] = roles
	end
	-- Controller and dynamic row factories retain this palette table.
	for role, color in pairs(nextColors) do
		context.colors[role] = color
	end
end

function UIFactory.build(widget)
	local studio = studioSettings()
	local context = {
		colors = palette(studio),
		styles = setmetatable({}, { __mode = "k" }),
		connections = {},
		destroyed = false,
	}
	local ui = { colors = context.colors, views = {}, viewButtons = {} }
	local function expose(key, instance)
		instance.Name = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
		ui[key] = instance
		return instance
	end
	local root = expose("root", create("Frame", {
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, widget))
	contexts[root] = context
	paint(root, "BackgroundColor3", "background")
	local header = expose("header", create("Frame", { Size = UDim2.new(1, 0, 0, 80) }, root))
	paint(header, "BackgroundColor3", "background")
	local title = label(header, "PresetForge", 18, "text", true)
	title.Name = "ProductTitle"
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -24, 0, 24)
	local navigation = create("Frame", {
		Name = "Navigation",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -24, 0, 32),
	}, header)
	local tabLayout = create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(4, 4),
		CellSize = UDim2.new(0.25, -3, 0, 32),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, navigation)
	local body = expose("body", create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, root))
	for index, name in ipairs({ "Library", "Recipe", "Targets", "Changes" }) do
		local view
		if name == "Library" then
			view = create("Frame", {
				Name = "LibraryView",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ClipsDescendants = true,
			}, body)
		else
			view = scroll(body, name .. "View")
		end
		view.Visible = name == "Library"
		ui.views[name] = view
		local tab = button(navigation, name, false)
		tab.Name = name .. "Tab"
		tab.LayoutOrder = index
		ui.viewButtons[name] = tab
		listen(tab, tab.Activated, function()
			ui.showView(name)
		end)
	end
	ui.detailScroll = ui.views.Recipe
	local library = ui.views.Library
	local libraryControls = stack(library, "LibraryControls")
	libraryControls.Position = UDim2.fromOffset(12, 12)
	libraryControls.Size = UDim2.new(1, -24, 0, 0)
	expose("searchInput", textBox(libraryControls, "Search recipes"))
	-- A search query stays on one line so a pasted query cannot hide the library.
	ui.searchInput.AutomaticSize = Enum.AutomaticSize.None
	ui.searchInput.TextWrapped = false
	expose("saveButton", button(libraryControls, "Save Recipe", true))
	expose("presetList", scroll(library, "PresetList"))
	ui.presetList.Position = UDim2.fromOffset(0, 84)
	ui.presetList.Size = UDim2.new(1, 0, 1, -84)

	local recipe = ui.views.Recipe
	expose("detailName", label(recipe, "Choose a recipe", 18, "text", true))
	expose("libraryBadge", label(recipe, "", 12, "accentText", true))
	expose("detailCounts", label(recipe, "No recipe selected", 13, "muted", false))
	local editRow = pair(recipe, "EditActions")
	expose("editButton", inPair(button(editRow, "Edit", false), 1))
	expose("duplicateButton", inPair(button(editRow, "Duplicate", false), 2))
	local nameRow = pair(recipe, "RecipeActions")
	expose("renameButton", inPair(button(nameRow, "Rename", false), 1))
	expose("recaptureButton", inPair(button(nameRow, "Recapture", false), 2))
	local renamePanel = expose("renamePanel", stack(recipe, "RenamePanel"))
	renamePanel.Visible = false
	expose("renameInput", textBox(renamePanel, "Recipe name"))
	local renameActions = pair(renamePanel, "RenameActions")
	expose("renameCancel", inPair(button(renameActions, "Cancel", false), 1))
	expose("renameConfirm", inPair(button(renameActions, "Save", true), 2))
	label(recipe, "Captured fields", 14, "text", true).Name = "FieldsTitle"
	expose("capturedText", label(recipe, "Select a recipe to inspect its fields.", 14, "text", false))
	expose("deleteButton", button(recipe, "Delete", false))

	local targets = ui.views.Targets
	label(targets, "Target scope", 14, "text", true).Name = "ScopeTitle"
	expose("scopeSelectionButton", button(targets, "Selection", false))
	expose("scopeDescendantsButton", button(targets, "Descendants", false))
	UIFactory.setSegment(ui.scopeSelectionButton, true)
	expose("selectionText", label(targets, "0 selected", 14, "text", false))
	local filters = expose("filterPanel", stack(targets, "FilterPanel"))
	filters.Visible = false
	label(filters, "Class / type", 13, "muted", false).Name = "ClassFilterLabel"
	expose("classFilterInput", textBox(filters, "Required class"))
	label(filters, "Name contains", 13, "muted", false).Name = "NameFilterLabel"
	expose("nameFilterInput", textBox(filters, "Optional name"))
	label(filters, "Tag", 13, "muted", false).Name = "TagFilterLabel"
	expose("tagFilterInput", textBox(filters, "Optional tag"))

	local changes = ui.views.Changes
	label(changes, "Changes", 14, "text", true).Name = "ChangesTitle"
	expose("previewSummary", label(changes, "Run Preview to inspect pending changes.", 14, "muted", false))
	expose("selectAffectedButton", button(changes, "Select affected", false))
	expose("frameAffectedButton", button(changes, "Frame affected", false))
	expose("resultList", stack(changes, "ResultList"))
	expose("showMatchingButton", button(changes, "Show matching", false))
	expose("selectMatchingButton", button(changes, "Select matching", false))
	expose("showIgnoredButton", button(changes, "Show ignored", false))
	expose("selectIgnoredButton", button(changes, "Select ignored", false))

	local footer = expose("footer", create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 76),
	}, root))
	paint(footer, "BackgroundColor3", "background")
	padding(footer, 8, 12, 8, 12)
	local actions = pair(footer, "PreviewActions")
	expose("previewButton", inPair(button(actions, "Preview", false), 1))
	expose("applyButton", inPair(button(actions, "Apply", true), 2))
	local version = label(footer, "v" .. Constants.VERSION, 12, "muted", false)
	version.Name = "Version"
	version.AutomaticSize = Enum.AutomaticSize.None
	version.Position = UDim2.fromOffset(0, 40)
	version.Size = UDim2.new(1, -64, 0, 20)
	local helpButton = expose("helpButton", button(footer, "Help", false))
	helpButton.Position = UDim2.new(1, -56, 0, 36)
	helpButton.Size = UDim2.fromOffset(56, 28)

	-- Feedback is shared by every view and scrolls independently of the fixed actions.
	local feedbackScroll = scroll(root, "FeedbackScroll")
	local feedbackPadding = feedbackScroll:FindFirstChildOfClass("UIPadding")
	feedbackPadding.PaddingTop = UDim.new(0, 4)
	feedbackPadding.PaddingBottom = UDim.new(0, 4)
	expose("feedback", label(feedbackScroll, "", 13, "muted", false))
	ui.feedback.Visible = false

	local overlay = expose("editorOverlay", create("Frame", {
		Active = true,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
		ClipsDescendants = true,
	}, root))
	paint(overlay, "BackgroundColor3", "background")
	local editorHeader = expose("editorHeader", create("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
	}, overlay))
	paint(editorHeader, "BackgroundColor3", "background")
	local editorTitle = expose("editorTitle", label(editorHeader, "Capture recipe", 18, "text", true))
	editorTitle.Position = UDim2.fromOffset(12, 12)
	editorTitle.Size = UDim2.new(1, -24, 0, 24)
	local editorScroll = expose("editorScroll", scroll(overlay, "EditorScroll"))
	editorScroll.Position = UDim2.fromOffset(0, 48)
	editorScroll.Size = UDim2.new(1, 0, 1, -104)
	expose("editorHint", label(editorScroll, "Choose the fields to capture.", 13, "muted", false))
	expose("editorSourceText", label(editorScroll, "Source: none", 13, "muted", false))
	label(editorScroll, "Recipe name", 14, "text", true).Name = "RecipeNameLabel"
	expose("editorNameInput", textBox(editorScroll, "Recipe name"))
	label(editorScroll, "Save to", 14, "text", true).Name = "StorageLabel"
	local storageRow = pair(editorScroll, "LibraryOptions")
	expose("localLibraryButton", inPair(button(storageRow, "Local", false), 1))
	expose("projectLibraryButton", inPair(button(storageRow, "Project", false), 2))
	UIFactory.setSegment(ui.localLibraryButton, true)
	expose("editorLibraryHelp", label(editorScroll, "Local recipes are saved in your Studio settings.", 13, "muted", false))
	label(editorScroll, "Fields", 14, "text", true).Name = "EditorFieldsTitle"
	expose("fieldList", stack(editorScroll, "FieldList"))
	expose("tagsCheck", UIFactory.createCheckbox(editorScroll, "Tags", false))
	expose("attributesCheck", UIFactory.createCheckbox(editorScroll, "Attributes", false))
	local editorFooter = expose("editorFooter", create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 56),
	}, overlay))
	paint(editorFooter, "BackgroundColor3", "background")
	padding(editorFooter, 12, 12, 12, 12)
	local editorActions = pair(editorFooter, "EditorActions")
	expose("editorCancel", inPair(button(editorActions, "Cancel", false), 1))
	expose("editorConfirm", inPair(button(editorActions, "Save", true), 2))

	local help = create("Frame", {
		Name = "HelpOverlay",
		Active = true,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 30,
	}, root)
	paint(help, "BackgroundColor3", "background")
	local helpBody = scroll(help, "HelpBody")
	helpBody.Size = UDim2.new(1, 0, 1, -56)
	label(helpBody, "PresetForge help", 18, "text", true)
	label(helpBody, "Capture one selected source, choose fields, then save the recipe.", 14, "text", false)
	label(helpBody, "Local recipes stay in Studio settings. Saving a Project recipe writes recipe storage into this place.", 14, "text", false)
	label(helpBody, "Choose target scope and filters, then Preview. Changes shows pending writes and exact before/after values.", 14, "text", false)
	label(helpBody, "Frame affected locates changed objects. Apply writes checked fields; use Studio Undo to revert an apply.", 14, "text", false)
	local closeHelp = button(help, "Close help", false)
	closeHelp.Name = "CloseHelp"
	closeHelp.Position = UDim2.new(0, 12, 1, -44)
	closeHelp.Size = UDim2.new(1, -24, 0, 32)
	listen(helpButton, helpButton.Activated, function()
		help.Visible = true
	end)
	listen(closeHelp, closeHelp.Activated, function()
		help.Visible = false
	end)

	function ui.showView(name)
		if context.destroyed or not ui.views[name] then
			return false
		end
		ui.currentView = name
		for viewName, view in pairs(ui.views) do
			view.Visible = viewName == name
			UIFactory.setSegment(ui.viewButtons[viewName], viewName == name)
		end
		return true
	end

	local function resize()
		local narrowTabs = root.AbsoluteSize.X < 320
		local navigationHeight = narrowTabs and 68 or 32
		local headerHeight = 48 + navigationHeight
		local feedbackLimit = root.AbsoluteSize.Y < 480 and 48 or 72
		local feedbackHeight = ui.feedback.Visible and math.min(feedbackLimit, ui.feedback.AbsoluteSize.Y + 8) or 0
		tabLayout.CellSize = UDim2.new(narrowTabs and 0.5 or 0.25, narrowTabs and -2 or -3, 0, 32)
		navigation.Size = UDim2.new(1, -24, 0, navigationHeight)
		header.Size = UDim2.new(1, 0, 0, headerHeight)
		body.Position = UDim2.fromOffset(0, headerHeight)
		body.Size = UDim2.new(1, 0, 1, -(headerHeight + 76 + feedbackHeight))
		feedbackScroll.Visible = ui.feedback.Visible
		feedbackScroll.Position = UDim2.new(0, 0, 1, -(76 + feedbackHeight))
		feedbackScroll.Size = UDim2.new(1, 0, 0, feedbackHeight)
	end
	listen(root, root:GetPropertyChangedSignal("AbsoluteSize"), resize)
	listen(ui.feedback, ui.feedback:GetPropertyChangedSignal("Visible"), resize)
	listen(ui.feedback, ui.feedback:GetPropertyChangedSignal("AbsoluteSize"), resize)
	listen(ui.feedback, ui.feedback:GetPropertyChangedSignal("Text"), function()
		feedbackScroll.CanvasPosition = Vector2.zero
	end)
	if studio then
		listen(root, studio.ThemeChanged, function()
			refreshTheme(root, context, studio)
		end)
	end
	listen(ui.editorHint, ui.editorHint:GetPropertyChangedSignal("Text"), function()
		if overlay.Visible then
			editorScroll.CanvasPosition = Vector2.zero
		end
	end)

	local function disconnect()
		if context.destroyed then
			return
		end
		context.destroyed = true
		for _, connections in pairs(context.connections) do
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
		end
		table.clear(context.connections)
		table.clear(context.styles)
		contexts[root] = nil
	end
	function ui.destroy()
		if context.destroyed then
			return
		end
		disconnect()
		root:Destroy()
	end
	listen(root, root.Destroying, disconnect)
	for _, key in ipairs({
		"renameButton", "editButton", "duplicateButton", "recaptureButton", "deleteButton",
		"previewButton", "applyButton", "selectAffectedButton", "frameAffectedButton",
		"selectMatchingButton", "selectIgnoredButton", "showMatchingButton", "showIgnoredButton",
	}) do
		UIFactory.setButtonEnabled(ui[key], false)
	end
	ui.showView("Library")
	resize()
	return ui
end

return UIFactory
