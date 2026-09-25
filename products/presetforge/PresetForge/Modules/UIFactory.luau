local UIFactory = {}

local COLORS = {
	background = Color3.fromRGB(30, 32, 35),
	panel = Color3.fromRGB(38, 41, 45),
	panelHover = Color3.fromRGB(48, 52, 57),
	border = Color3.fromRGB(66, 71, 77),
	text = Color3.fromRGB(239, 242, 244),
	muted = Color3.fromRGB(165, 173, 181),
	accent = Color3.fromRGB(45, 184, 166),
	accentHover = Color3.fromRGB(58, 202, 183),
	danger = Color3.fromRGB(226, 91, 91),
	success = Color3.fromRGB(91, 202, 137),
	warning = Color3.fromRGB(236, 183, 79),
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
		TextSize = 14,
	}, parent)
	corner(result, 4)
	stroke(result, accent and COLORS.accent or COLORS.border)

	result.MouseEnter:Connect(function()
		if result.Active then
			result.BackgroundColor3 = accent and COLORS.accentHover or COLORS.panelHover
		end
	end)
	result.MouseLeave:Connect(function()
		result.BackgroundColor3 = accent and COLORS.accent or COLORS.panel
	end)
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

local function checkbox(parent, text)
	local result = button(parent, "[ ]  " .. text, 120, false)
	result.Font = Enum.Font.BuilderSans
	result.TextXAlignment = Enum.TextXAlignment.Left
	result:SetAttribute("Checked", false)
	result.Activated:Connect(function()
		local checked = not result:GetAttribute("Checked")
		result:SetAttribute("Checked", checked)
		result.Text = (checked and "[x]  " or "[ ]  ") .. text
		result.BackgroundColor3 = checked and Color3.fromRGB(35, 87, 82) or COLORS.panel
	end)
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

function UIFactory.createPresetButton(parent, preset, selected)
	local result = create("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = selected and Color3.fromRGB(35, 87, 82) or COLORS.panel,
		Font = selected and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans,
		LayoutOrder = 10,
		Size = UDim2.new(1, -2, 0, 38),
		Text = preset.name,
		TextColor3 = COLORS.text,
		TextSize = 14,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	padding(result, 0, 10, 0, 10)
	corner(result, 4)
	stroke(result, selected and COLORS.accent or COLORS.border)
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
		Size = UDim2.new(1, 0, 0, 52),
	}, root)
	padding(header, 8, 14, 8, 14)

	local title = label(header, "PresetForge", 18, COLORS.text, true)
	title.Size = UDim2.new(0.6, 0, 0, 22)
	local promise = label(header, "Save once. Apply safely.", 12, COLORS.muted, false)
	promise.Position = UDim2.new(0, 0, 0, 24)
	promise.Size = UDim2.new(0.6, 0, 0, 18)
	local localBadge = label(header, "LOCAL", 10, COLORS.accent, true)
	localBadge.AnchorPoint = Vector2.new(1, 0.5)
	localBadge.Position = UDim2.new(1, 0, 0.5, 0)
	localBadge.Size = UDim2.new(0, 52, 0, 20)
	localBadge.TextXAlignment = Enum.TextXAlignment.Right

	local body = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 53),
		Size = UDim2.new(1, 0, 1, -53),
	}, root)

	local sidebar = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(34, 36, 40),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 190, 1, 0),
	}, body)
	padding(sidebar, 12, 12, 12, 12)

	local libraryTitle = sectionTitle(sidebar, "Preset library")
	libraryTitle.LayoutOrder = 1
	local saveButton = button(sidebar, "+  Save Preset", 166, true)
	saveButton.LayoutOrder = 2
	saveButton.Position = UDim2.new(0, 0, 0, 24)
	ui.saveButton = saveButton

	local presetList = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.new(0, 0, 0, 68),
		ScrollBarImageColor3 = COLORS.border,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 1, -68),
	}, sidebar)
	padding(presetList, 0, 2, 4, 0)
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, presetList)
	ui.presetList = presetList

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 190, 0, 0),
		Size = UDim2.new(1, -190, 1, 0),
	}, body)
	padding(content, 12, 14, 12, 14)

	local detailScroll = create("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollBarImageColor3 = COLORS.border,
		ScrollBarThickness = 4,
		Size = UDim2.new(1, 0, 1, -50),
	}, content)
	padding(detailScroll, 0, 8, 8, 0)
	create("UIListLayout", {
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, detailScroll)
	ui.detailScroll = detailScroll

	local detailTop = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 30),
	}, detailScroll)
	local detailName = label(detailTop, "Choose a preset", 19, COLORS.text, true)
	detailName.Size = UDim2.new(1, -150, 0, 30)
	ui.detailName = detailName
	local renameButton = button(detailTop, "Rename", 68, false)
	renameButton.AnchorPoint = Vector2.new(1, 0)
	renameButton.Position = UDim2.new(1, -76, 0, 0)
	renameButton.Size = UDim2.new(0, 68, 0, 28)
	ui.renameButton = renameButton
	local deleteButton = button(detailTop, "Delete", 68, false)
	deleteButton.AnchorPoint = Vector2.new(1, 0)
	deleteButton.Position = UDim2.new(1, 0, 0, 0)
	deleteButton.Size = UDim2.new(0, 68, 0, 28)
	ui.deleteButton = deleteButton

	local renamePanel = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 32),
		Visible = false,
	}, detailScroll)
	ui.renamePanel = renamePanel
	local renameInput = create("TextBox", {
		BackgroundColor3 = COLORS.panel,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		PlaceholderColor3 = COLORS.muted,
		PlaceholderText = "Preset name",
		Size = UDim2.new(1, -142, 0, 32),
		Text = "",
		TextColor3 = COLORS.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, renamePanel)
	padding(renameInput, 0, 8, 0, 8)
	corner(renameInput, 4)
	stroke(renameInput)
	ui.renameInput = renameInput
	local renameConfirm = button(renamePanel, "Save", 62, true)
	renameConfirm.AnchorPoint = Vector2.new(1, 0)
	renameConfirm.Position = UDim2.new(1, -68, 0, 0)
	ui.renameConfirm = renameConfirm
	local renameCancel = button(renamePanel, "Cancel", 62, false)
	renameCancel.AnchorPoint = Vector2.new(1, 0)
	renameCancel.Position = UDim2.new(1, 0, 0, 0)
	ui.renameCancel = renameCancel

	local detailCounts = label(detailScroll, "No preset selected", 13, COLORS.muted, false)
	detailCounts.LayoutOrder = 3
	ui.detailCounts = detailCounts
	local dividerOne = separator(detailScroll)
	dividerOne.LayoutOrder = 4

	local capturedTitle = sectionTitle(detailScroll, "Captured setup")
	capturedTitle.LayoutOrder = 5
	local capturedText = label(detailScroll, "Select a preset to inspect its contents.", 13, COLORS.muted, false)
	capturedText.LayoutOrder = 6
	ui.capturedText = capturedText
	local semantics = label(detailScroll, "Preset tags are added. Other tags and attributes remain untouched.", 12, COLORS.muted, false)
	semantics.LayoutOrder = 7
	ui.semantics = semantics
	local dividerTwo = separator(detailScroll)
	dividerTwo.LayoutOrder = 8

	local selectionTitle = sectionTitle(detailScroll, "Current selection")
	selectionTitle.LayoutOrder = 9
	local selectionText = label(detailScroll, "0 selected", 13, COLORS.text, false)
	selectionText.LayoutOrder = 10
	ui.selectionText = selectionText

	local previewTitle = sectionTitle(detailScroll, "Preview")
	previewTitle.LayoutOrder = 11
	local previewText = label(detailScroll, "Run Preview to inspect every pending change.", 13, COLORS.muted, false)
	previewText.LayoutOrder = 12
	ui.previewText = previewText

	local feedback = label(detailScroll, "", 12, COLORS.muted, false)
	feedback.LayoutOrder = 13
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
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
	}, root)
	ui.saveOverlay = overlay
	local dialog = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = COLORS.panel,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 360, 0, 310),
		ZIndex = 21,
	}, overlay)
	corner(dialog, 6)
	stroke(dialog)
	padding(dialog, 16, 16, 16, 16)

	local saveTitle = label(dialog, "Save Preset", 18, COLORS.text, true)
	saveTitle.ZIndex = 22
	local sourceText = label(dialog, "Source: none", 12, COLORS.muted, false)
	sourceText.Position = UDim2.new(0, 0, 0, 30)
	sourceText.Size = UDim2.new(1, 0, 0, 36)
	sourceText.ZIndex = 22
	ui.saveSourceText = sourceText
	local nameInput = create("TextBox", {
		BackgroundColor3 = COLORS.background,
		ClearTextOnFocus = false,
		Font = Enum.Font.BuilderSans,
		PlaceholderColor3 = COLORS.muted,
		PlaceholderText = "Preset name",
		Position = UDim2.new(0, 0, 0, 72),
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		TextColor3 = COLORS.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	}, dialog)
	padding(nameInput, 0, 9, 0, 9)
	corner(nameInput, 4)
	stroke(nameInput)
	ui.saveNameInput = nameInput

	local captureLabel = label(dialog, "CAPTURE", 11, COLORS.muted, true)
	captureLabel.Position = UDim2.new(0, 0, 0, 120)
	captureLabel.ZIndex = 22
	local propertiesCheck = checkbox(dialog, "Properties")
	propertiesCheck.Position = UDim2.new(0, 0, 0, 145)
	propertiesCheck.ZIndex = 22
	ui.propertiesCheck = propertiesCheck
	local tagsCheck = checkbox(dialog, "Tags")
	tagsCheck.Position = UDim2.new(0, 126, 0, 145)
	tagsCheck.ZIndex = 22
	ui.tagsCheck = tagsCheck
	local attributesCheck = checkbox(dialog, "Attributes")
	attributesCheck.Position = UDim2.new(0, 0, 0, 183)
	attributesCheck.ZIndex = 22
	ui.attributesCheck = attributesCheck

	local saveHint = label(dialog, "Choose at least one category. Saving and previewing never change the project.", 12, COLORS.muted, false)
	saveHint.Position = UDim2.new(0, 0, 0, 224)
	saveHint.Size = UDim2.new(1, 0, 0, 36)
	saveHint.ZIndex = 22
	ui.saveHint = saveHint
	local saveConfirm = button(dialog, "Save", 92, true)
	saveConfirm.AnchorPoint = Vector2.new(1, 1)
	saveConfirm.Position = UDim2.new(1, 0, 1, 0)
	saveConfirm.ZIndex = 22
	ui.saveConfirm = saveConfirm
	local saveCancel = button(dialog, "Cancel", 92, false)
	saveCancel.AnchorPoint = Vector2.new(1, 1)
	saveCancel.Position = UDim2.new(1, -100, 1, 0)
	saveCancel.ZIndex = 22
	ui.saveCancel = saveCancel

	return ui
end

return UIFactory
