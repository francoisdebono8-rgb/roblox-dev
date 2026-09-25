local UIFactory = {}

local COLORS = {
	background = Color3.fromRGB(29, 31, 34),
	panel = Color3.fromRGB(38, 41, 45),
	panelHover = Color3.fromRGB(48, 52, 57),
	border = Color3.fromRGB(68, 74, 80),
	text = Color3.fromRGB(239, 242, 244),
	muted = Color3.fromRGB(165, 174, 182),
	accent = Color3.fromRGB(43, 181, 164),
	accentDark = Color3.fromRGB(34, 89, 83),
	accentHover = Color3.fromRGB(57, 201, 183),
	danger = Color3.fromRGB(229, 96, 96),
	success = Color3.fromRGB(94, 204, 140),
	warning = Color3.fromRGB(237, 185, 81),
}

local function create(className, properties, parent)
	local instance = Instance.new(className)
	for propertyName, value in pairs(properties or {}) do
		instance[propertyName] = value
	end
	instance.Parent = parent
	return instance
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 4) }, parent)
end

local function stroke(parent, color)
	return create("UIStroke", {
		Color = color or COLORS.border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function padding(parent, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
	}, parent)
end

local function label(parent, text, size, color, bold)
	return create("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans,
		Size = UDim2.new(1, 0, 0, size + 6),
		Text = text,
		TextColor3 = color or COLORS.text,
		TextSize = size,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, parent)
end

local function button(parent, text, width, accent)
	local result = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = accent and COLORS.accent or COLORS.panel,
		Font = Enum.Font.BuilderSansBold,
		Size = UDim2.new(0, width, 0, 32),
		Text = text,
		TextColor3 = COLORS.text,
		TextSize = 13,
	}, parent)
	corner(result, 4)
	stroke(result, accent and COLORS.accent or COLORS.border)
	result.MouseEnter:Connect(function()
		if result.Active then
			result.BackgroundColor3 = accent and COLORS.accentHover or COLORS.panelHover
		end
	end)
	result.MouseLeave:Connect(function()
		if result:GetAttribute("Selected") then
			result.BackgroundColor3 = COLORS.accentDark
		else
			result.BackgroundColor3 = accent and COLORS.accent or COLORS.panel
		end
	end)
	return result
end

local function textBox(parent, placeholder)
	local result = create("TextBox", {
		BackgroundColor3 = COLORS.panel,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		PlaceholderColor3 = COLORS.muted,
		PlaceholderText = placeholder,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		TextColor3 = COLORS.text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	padding(result, 0, 8, 0, 8)
	corner(result, 4)
	stroke(result)
	return result
end

local function separator(parent)
	return create("Frame", {
		BackgroundColor3 = COLORS.border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
	}, parent)
end

local function sectionTitle(parent, text)
	local result = label(parent, string.upper(text), 11, COLORS.muted, true)
	result.Size = UDim2.new(1, 0, 0, 18)
	return result
end

function UIFactory.setButtonEnabled(target, enabled)
	target.Active = enabled
	target.Selectable = enabled
	target.TextTransparency = enabled and 0 or 0.5
	target.BackgroundTransparency = enabled and 0 or 0.35
	local border = target:FindFirstChildOfClass("UIStroke")
	if border then
		border.Transparency = enabled and 0 or 0.55
	end
end

function UIFactory.setSegment(target, selected)
	target:SetAttribute("Selected", selected)
	target.BackgroundColor3 = selected and COLORS.accentDark or COLORS.panel
	local border = target:FindFirstChildOfClass("UIStroke")
	if border then
		border.Color = selected and COLORS.accent or COLORS.border
	end
end

function UIFactory.createCheckbox(parent, text, checked)
	local result = button(parent, "", 160, false)
	result.AutomaticSize = Enum.AutomaticSize.Y
	result.Size = UDim2.new(1, -2, 0, 34)
	result.Font = Enum.Font.BuilderSans
	result.TextWrapped = true
	result.TextXAlignment = Enum.TextXAlignment.Left
	padding(result, 7, 8, 7, 8)
	result:SetAttribute("Label", text)

	local function render(value)
		result:SetAttribute("Checked", value)
		result.Text = (value and "[x]  " or "[ ]  ") .. result:GetAttribute("Label")
		result.BackgroundColor3 = value and COLORS.accentDark or COLORS.panel
	end
	result.Activated:Connect(function()
		render(not result:GetAttribute("Checked"))
	end)
	render(checked == true)
	return result
end

function UIFactory.setCheckbox(target, checked, text)
	if text then
		target:SetAttribute("Label", text)
	end
	target:SetAttribute("Checked", checked)
	target.Text = (checked and "[x]  " or "[ ]  ") .. target:GetAttribute("Label")
	target.BackgroundColor3 = checked and COLORS.accentDark or COLORS.panel
end

function UIFactory.createPresetButton(parent, recipe, selected)
	local marker = recipe.library == "Project" and "P" or "L"
	local result = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = selected and COLORS.accentDark or COLORS.panel,
		Font = selected and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans,
		LayoutOrder = 10,
		Size = UDim2.new(1, -2, 0, 44),
		Text = string.format("[%s]  %s\n     %s", marker, recipe.name, recipe.schemaId),
		TextColor3 = COLORS.text,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
	padding(result, 0, 8, 0, 8)
	corner(result, 4)
	stroke(result, selected and COLORS.accent or COLORS.border)
	return result
end

function UIFactory.createResultButton(parent, text, status)
	local tone = status == "affected" and COLORS.warning
		or status == "matching" and COLORS.success
		or COLORS.muted
	local result = create("TextButton", {
		AutomaticSize = Enum.AutomaticSize.Y,
		AutoButtonColor = false,
		BackgroundColor3 = COLORS.panel,
		Font = Enum.Font.BuilderSans,
		LayoutOrder = 10,
		Size = UDim2.new(1, -2, 0, 42),
		Text = text,
		TextColor3 = COLORS.text,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, parent)
	padding(result, 7, 8, 7, 8)
	corner(result, 4)
	stroke(result, tone)
	return result
end

function UIFactory.build(widget)
	local ui = { colors = COLORS }
	local root = create("Frame", {
		BackgroundColor3 = COLORS.background,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, widget)
	ui.root = root

	local header = create("Frame", {
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 56),
	}, root)
	padding(header, 8, 14, 8, 14)
	local title = label(header, "PresetForge", 18, COLORS.text, true)
	title.Size = UDim2.new(0.55, 0, 0, 22)
	local promise = label(header, "Safe Bulk Editor for Roblox Studio", 12, COLORS.muted, false)
	promise.Position = UDim2.new(0, 0, 0, 25)
	promise.Size = UDim2.new(0.8, 0, 0, 18)
	local version = label(header, "2.0", 11, COLORS.accent, true)
	version.AnchorPoint = Vector2.new(1, 0.5)
	version.Position = UDim2.new(1, 0, 0.5, 0)
	version.Size = UDim2.new(0, 50, 0, 20)
	version.TextXAlignment = Enum.TextXAlignment.Right

	local body = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 57),
		Size = UDim2.new(1, 0, 1, -57),
	}, root)
	local sidebar = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(34, 36, 40),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 210, 1, 0),
	}, body)
	padding(sidebar, 12, 12, 12, 12)
	local libraryTitle = sectionTitle(sidebar, "Recipe library")
	libraryTitle.LayoutOrder = 1
	local saveButton = button(sidebar, "+  Save Recipe", 186, true)
	saveButton.Position = UDim2.new(0, 0, 0, 24)
	ui.saveButton = saveButton
	local libraryHint = label(sidebar, "[L] Local   [P] Project", 11, COLORS.muted, false)
	libraryHint.Position = UDim2.new(0, 0, 0, 62)
	libraryHint.Size = UDim2.new(1, 0, 0, 18)
	local presetList = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 86),
		ScrollBarImageColor3 = COLORS.border,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 1, -86),
	}, sidebar)
	padding(presetList, 0, 2, 4, 0)
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, presetList)
	ui.presetList = presetList

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 210, 0, 0),
		Size = UDim2.new(1, -210, 1, 0),
	}, body)
	padding(content, 12, 14, 12, 14)
	local detailScroll = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = COLORS.border,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 1, -48),
	}, content)
	padding(detailScroll, 0, 8, 8, 0)
	create("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, detailScroll)
	ui.detailScroll = detailScroll

	local detailTop = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 70),
	}, detailScroll)
	local detailName = label(detailTop, "Choose a recipe", 19, COLORS.text, true)
	detailName.Size = UDim2.new(1, -90, 0, 28)
	ui.detailName = detailName
	local libraryBadge = label(detailTop, "", 11, COLORS.accent, true)
	libraryBadge.AnchorPoint = Vector2.new(1, 0)
	libraryBadge.Position = UDim2.new(1, 0, 0, 4)
	libraryBadge.Size = UDim2.new(0, 84, 0, 20)
	libraryBadge.TextXAlignment = Enum.TextXAlignment.Right
	ui.libraryBadge = libraryBadge

	local actionNames = { "Rename", "Edit", "Recapture", "Delete" }
	local actionKeys = { "renameButton", "editButton", "recaptureButton", "deleteButton" }
	for index, text in ipairs(actionNames) do
		local action = button(detailTop, text, index == 3 and 82 or 66, false)
		action.Position = UDim2.new(0, (index - 1) * 72, 0, 36)
		if index == 3 then
			action.Position = UDim2.new(0, 144, 0, 36)
		elseif index == 4 then
			action.Position = UDim2.new(0, 232, 0, 36)
		end
		action.Size = UDim2.new(0, index == 3 and 82 or 66, 0, 28)
		ui[actionKeys[index]] = action
	end

	local renamePanel = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 32),
		Visible = false,
	}, detailScroll)
	ui.renamePanel = renamePanel
	local renameInput = textBox(renamePanel, "Recipe name")
	renameInput.Size = UDim2.new(1, -142, 0, 32)
	ui.renameInput = renameInput
	local renameConfirm = button(renamePanel, "Save", 62, true)
	renameConfirm.AnchorPoint = Vector2.new(1, 0)
	renameConfirm.Position = UDim2.new(1, -68, 0, 0)
	ui.renameConfirm = renameConfirm
	local renameCancel = button(renamePanel, "Cancel", 62, false)
	renameCancel.AnchorPoint = Vector2.new(1, 0)
	renameCancel.Position = UDim2.new(1, 0, 0, 0)
	ui.renameCancel = renameCancel

	local detailCounts = label(detailScroll, "No recipe selected", 13, COLORS.muted, false)
	detailCounts.LayoutOrder = 3
	ui.detailCounts = detailCounts
	local dividerOne = separator(detailScroll)
	dividerOne.LayoutOrder = 4
	local fieldsTitle = sectionTitle(detailScroll, "Recipe fields")
	fieldsTitle.LayoutOrder = 5
	local capturedText = label(detailScroll, "Select a recipe to inspect its fields.", 13, COLORS.muted, false)
	capturedText.LayoutOrder = 6
	ui.capturedText = capturedText
	local dividerTwo = separator(detailScroll)
	dividerTwo.LayoutOrder = 7

	local scopeTitle = sectionTitle(detailScroll, "Scope")
	scopeTitle.LayoutOrder = 8
	local scopeRow = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 9,
		Size = UDim2.new(1, 0, 0, 32),
	}, detailScroll)
	local selectionButton = button(scopeRow, "Selection", 112, false)
	ui.scopeSelectionButton = selectionButton
	local descendantsButton = button(scopeRow, "Descendants", 112, false)
	descendantsButton.Position = UDim2.new(0, 120, 0, 0)
	ui.scopeDescendantsButton = descendantsButton
	UIFactory.setSegment(selectionButton, true)

	local filterPanel = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 10,
		Size = UDim2.new(1, 0, 0, 70),
		Visible = false,
	}, detailScroll)
	ui.filterPanel = filterPanel
	local classFilter = textBox(filterPanel, "Class/type")
	classFilter.Size = UDim2.new(0.32, -5, 0, 32)
	ui.classFilterInput = classFilter
	local nameFilter = textBox(filterPanel, "Name contains (optional)")
	nameFilter.Position = UDim2.new(0.32, 3, 0, 0)
	nameFilter.Size = UDim2.new(0.36, -5, 0, 32)
	ui.nameFilterInput = nameFilter
	local tagFilter = textBox(filterPanel, "Tag (optional)")
	tagFilter.Position = UDim2.new(0.68, 3, 0, 0)
	tagFilter.Size = UDim2.new(0.32, -3, 0, 32)
	ui.tagFilterInput = tagFilter
	local filterHint = label(filterPanel, "Class is required. Name and tag narrow the descendant scan.", 11, COLORS.muted, false)
	filterHint.Position = UDim2.new(0, 0, 0, 39)
	filterHint.Size = UDim2.new(1, 0, 0, 24)

	local selectionText = label(detailScroll, "0 selected", 13, COLORS.text, false)
	selectionText.LayoutOrder = 11
	ui.selectionText = selectionText
	local previewTitle = sectionTitle(detailScroll, "Preview")
	previewTitle.LayoutOrder = 12
	local previewSummary = label(detailScroll, "Run Preview to inspect every pending change.", 13, COLORS.muted, false)
	previewSummary.LayoutOrder = 13
	ui.previewSummary = previewSummary

	local selectRow = create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 14,
		Size = UDim2.new(1, 0, 0, 30),
	}, detailScroll)
	local selectAffected = button(selectRow, "Select affected", 116, false)
	selectAffected.Size = UDim2.new(0, 116, 0, 28)
	ui.selectAffectedButton = selectAffected
	local selectMatching = button(selectRow, "Select matching", 116, false)
	selectMatching.Position = UDim2.new(0, 122, 0, 0)
	selectMatching.Size = UDim2.new(0, 116, 0, 28)
	ui.selectMatchingButton = selectMatching
	local selectIgnored = button(selectRow, "Select ignored", 108, false)
	selectIgnored.Position = UDim2.new(0, 244, 0, 0)
	selectIgnored.Size = UDim2.new(0, 108, 0, 28)
	ui.selectIgnoredButton = selectIgnored

	local resultList = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		LayoutOrder = 15,
		ScrollBarImageColor3 = COLORS.border,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 0, 210),
	}, detailScroll)
	padding(resultList, 0, 4, 4, 0)
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, resultList)
	ui.resultList = resultList
	local feedback = label(detailScroll, "", 12, COLORS.muted, false)
	feedback.LayoutOrder = 16
	feedback.Visible = false
	ui.feedback = feedback

	local actionBar = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -38),
		Size = UDim2.new(1, 0, 0, 38),
	}, content)
	local previewButton = button(actionBar, "Preview", 104, false)
	previewButton.AnchorPoint = Vector2.new(1, 0)
	previewButton.Position = UDim2.new(1, -112, 0, 0)
	ui.previewButton = previewButton
	local applyButton = button(actionBar, "Apply", 104, true)
	applyButton.AnchorPoint = Vector2.new(1, 0)
	applyButton.Position = UDim2.new(1, 0, 0, 0)
	ui.applyButton = applyButton

	local overlay = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(12, 13, 15),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
	}, root)
	ui.editorOverlay = overlay
	local dialog = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = COLORS.background,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -32, 1, -32),
		ZIndex = 21,
	}, overlay)
	create("UISizeConstraint", { MaxSize = Vector2.new(580, 620), MinSize = Vector2.new(430, 430) }, dialog)
	corner(dialog, 6)
	stroke(dialog)
	padding(dialog, 16, 16, 16, 16)
	local editorTitle = label(dialog, "Save Recipe", 18, COLORS.text, true)
	editorTitle.ZIndex = 22
	ui.editorTitle = editorTitle
	local sourceText = label(dialog, "Source: none", 12, COLORS.muted, false)
	sourceText.Position = UDim2.new(0, 0, 0, 28)
	sourceText.Size = UDim2.new(1, 0, 0, 34)
	sourceText.ZIndex = 22
	ui.editorSourceText = sourceText
	local nameInput = textBox(dialog, "Recipe name")
	nameInput.Position = UDim2.new(0, 0, 0, 66)
	nameInput.ZIndex = 22
	ui.editorNameInput = nameInput

	local localButton = button(dialog, "Local", 100, false)
	localButton.Position = UDim2.new(0, 0, 0, 106)
	localButton.ZIndex = 22
	ui.localLibraryButton = localButton
	local projectButton = button(dialog, "Project", 100, false)
	projectButton.Position = UDim2.new(0, 108, 0, 106)
	projectButton.ZIndex = 22
	ui.projectLibraryButton = projectButton
	UIFactory.setSegment(localButton, true)
	local libraryHelp = label(dialog, "Project recipes are inserted only when explicitly selected.", 11, COLORS.muted, false)
	libraryHelp.Position = UDim2.new(0, 218, 0, 111)
	libraryHelp.Size = UDim2.new(1, -218, 0, 28)
	libraryHelp.ZIndex = 22

	local fieldLabel = label(dialog, "FIELDS - choose exactly what Apply may change", 11, COLORS.muted, true)
	fieldLabel.Position = UDim2.new(0, 0, 0, 148)
	fieldLabel.Size = UDim2.new(1, 0, 0, 18)
	fieldLabel.ZIndex = 22
	local fieldList = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 170),
		ScrollBarImageColor3 = COLORS.border,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 1, -300),
		ZIndex = 22,
	}, dialog)
	padding(fieldList, 0, 4, 4, 0)
	create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, fieldList)
	ui.fieldList = fieldList

	local extras = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -122),
		Size = UDim2.new(1, 0, 0, 34),
		ZIndex = 22,
	}, dialog)
	local tagsCheck = UIFactory.createCheckbox(extras, "Tags", false)
	tagsCheck.Size = UDim2.new(0.48, 0, 0, 34)
	tagsCheck.ZIndex = 22
	ui.tagsCheck = tagsCheck
	local attributesCheck = UIFactory.createCheckbox(extras, "Attributes", false)
	attributesCheck.Position = UDim2.new(0.52, 0, 0, 0)
	attributesCheck.Size = UDim2.new(0.48, 0, 0, 34)
	attributesCheck.ZIndex = 22
	ui.attributesCheck = attributesCheck

	local editorHint = label(dialog, "Save and Preview are read-only.", 12, COLORS.muted, false)
	editorHint.Position = UDim2.new(0, 0, 1, -82)
	editorHint.Size = UDim2.new(1, -210, 0, 42)
	editorHint.ZIndex = 22
	ui.editorHint = editorHint
	local editorConfirm = button(dialog, "Save", 96, true)
	editorConfirm.AnchorPoint = Vector2.new(1, 1)
	editorConfirm.Position = UDim2.new(1, 0, 1, 0)
	editorConfirm.ZIndex = 22
	ui.editorConfirm = editorConfirm
	local editorCancel = button(dialog, "Cancel", 96, false)
	editorCancel.AnchorPoint = Vector2.new(1, 1)
	editorCancel.Position = UDim2.new(1, -104, 1, 0)
	editorCancel.ZIndex = 22
	ui.editorCancel = editorCancel

	return ui
end

return UIFactory
