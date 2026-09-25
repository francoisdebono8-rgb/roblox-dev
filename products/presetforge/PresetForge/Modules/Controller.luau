local Constants = require(script.Parent.Constants)
local UIFactory = require(script.Parent.UIFactory)

local Controller = {}
Controller.__index = Controller

local function countMap(values)
	local count = 0
	for _ in pairs(values) do
		count += 1
	end
	return count
end

local function sortedKeys(values)
	local keys = {}
	for key in pairs(values) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local function countLabel(count, singular, plural)
	return string.format("%d %s", count, count == 1 and singular or plural or singular .. "s")
end

local function cleanValue(value)
	local text = if type(value) == "number" then string.format("%.6g", value) else tostring(value)
	text = text:gsub("[%c]", " ")
	if #text > 72 then
		return text:sub(1, 69) .. "..."
	end
	return text
end

function Controller.new(ui, store, captureService, previewService, applyService, selectionService)
	local self = setmetatable({
		_ui = ui,
		_store = store,
		_captureService = captureService,
		_previewService = previewService,
		_applyService = applyService,
		_selectionService = selectionService,
		_selectedName = nil,
		_preview = nil,
		_deleteArmedFor = nil,
		_connections = {},
		_presetConnections = {},
	}, Controller)

	self:_connect()
	self:_render()
	return self
end

function Controller:_listen(signal, callback)
	self._connections[#self._connections + 1] = signal:Connect(callback)
end

function Controller:_preset()
	if not self._selectedName then
		return nil
	end
	return self._store:find(self._selectedName)
end

function Controller:_selection()
	return self._selectionService:Get()
end

function Controller:_setFeedback(message, tone)
	local feedback = self._ui.feedback
	feedback.Text = message or ""
	feedback.Visible = message ~= nil and message ~= ""
	feedback.TextColor3 = self._ui.colors[tone or "muted"] or self._ui.colors.muted
end

function Controller:showError(message)
	self:_setFeedback(message, "danger")
end

function Controller:_disarmDelete()
	self._deleteArmedFor = nil
	self._ui.deleteButton.Text = "Delete"
	self._ui.deleteButton.TextColor3 = self._ui.colors.text
end

function Controller:_connect()
	self:_listen(self._ui.saveButton.Activated, function()
		self:_openSave()
	end)
	self:_listen(self._ui.saveCancel.Activated, function()
		self._ui.saveOverlay.Visible = false
	end)
	self:_listen(self._ui.saveConfirm.Activated, function()
		self:_savePreset()
	end)

	self:_listen(self._ui.renameButton.Activated, function()
		local preset = self:_preset()
		if preset then
			self:_disarmDelete()
			self._ui.renameInput.Text = preset.name
			self._ui.renamePanel.Visible = true
			self._ui.renameInput:CaptureFocus()
		end
	end)
	self:_listen(self._ui.renameCancel.Activated, function()
		self._ui.renamePanel.Visible = false
	end)
	self:_listen(self._ui.renameConfirm.Activated, function()
		self:_renamePreset()
	end)
	self:_listen(self._ui.renameInput.FocusLost, function(enterPressed)
		if enterPressed and self._ui.renamePanel.Visible then
			self:_renamePreset()
		end
	end)

	self:_listen(self._ui.deleteButton.Activated, function()
		self:_deletePreset()
	end)
	self:_listen(self._ui.previewButton.Activated, function()
		self:_runPreview()
	end)
	self:_listen(self._ui.applyButton.Activated, function()
		self:_apply()
	end)

	self:_listen(self._selectionService.SelectionChanged, function()
		self._preview = nil
		self:_disarmDelete()
		self:_setFeedback("Selection changed. Run Preview before applying.", "warning")
		self:_renderDetail()
	end)
end

function Controller:_resetCaptureChecks()
	for _, item in ipairs({
		{ self._ui.propertiesCheck, "Properties" },
		{ self._ui.tagsCheck, "Tags" },
		{ self._ui.attributesCheck, "Attributes" },
	}) do
		item[1]:SetAttribute("Checked", false)
		item[1].Text = "[ ]  " .. item[2]
		item[1].BackgroundColor3 = self._ui.colors.panel
	end
end

function Controller:_openSave()
	self:_disarmDelete()
	self._ui.saveNameInput.Text = ""
	self:_resetCaptureChecks()
	self._ui.saveHint.Text = "Choose at least one category. Saving and previewing never change the project."
	self._ui.saveHint.TextColor3 = self._ui.colors.muted

	local selection = self:_selection()
	if #selection == 1 and selection[1]:IsA("BasePart") then
		self._ui.saveSourceText.Text = "Source: " .. selection[1]:GetFullName()
	else
		self._ui.saveSourceText.Text = "Source: select exactly one BasePart"
	end
	self._ui.saveOverlay.Visible = true
	self._ui.saveNameInput:CaptureFocus()
end

function Controller:_savePreset()
	local options = {
		properties = self._ui.propertiesCheck:GetAttribute("Checked") == true,
		tags = self._ui.tagsCheck:GetAttribute("Checked") == true,
		attributes = self._ui.attributesCheck:GetAttribute("Checked") == true,
	}
	local captured, captureError = self._captureService:capture(self:_selection(), options)
	if not captured then
		self._ui.saveHint.Text = captureError
		self._ui.saveHint.TextColor3 = self._ui.colors.danger
		return
	end

	local saved, result = self._store:create(self._ui.saveNameInput.Text, captured)
	if not saved then
		self._ui.saveHint.Text = result
		self._ui.saveHint.TextColor3 = self._ui.colors.danger
		return
	end

	self._selectedName = result.name
	self._preview = nil
	self._ui.saveOverlay.Visible = false
	self:_setFeedback("Preset saved locally.", "success")
	self:_render()
end

function Controller:_renamePreset()
	local preset = self:_preset()
	if not preset then
		return
	end
	local renamed, result = self._store:rename(preset.name, self._ui.renameInput.Text)
	if not renamed then
		self:_setFeedback(result, "danger")
		return
	end

	self._selectedName = result.name
	self._ui.renamePanel.Visible = false
	self:_setFeedback("Preset renamed.", "success")
	self:_render()
end

function Controller:_deletePreset()
	local preset = self:_preset()
	if not preset then
		return
	elseif self._deleteArmedFor ~= preset.name then
		self._deleteArmedFor = preset.name
		self._ui.deleteButton.Text = "Confirm"
		self._ui.deleteButton.TextColor3 = self._ui.colors.danger
		self:_setFeedback("Click Confirm to permanently delete this local preset.", "warning")
		return
	end

	local deleted, deleteError = self._store:delete(preset.name)
	if not deleted then
		self:_setFeedback(deleteError, "danger")
		return
	end

	self._selectedName = nil
	self._preview = nil
	self:_disarmDelete()
	self:_setFeedback("Preset deleted.", "success")
	self:_render()
end

function Controller:_runPreview()
	local preset = self:_preset()
	if not preset then
		return
	end
	self:_disarmDelete()
	self._preview = self._previewService:build(preset, self:_selection())
	self:_setFeedback("Preview is read-only. Review the changes before Apply.", "muted")
	self:_renderDetail()
end

function Controller:_apply()
	local preset = self:_preset()
	if not preset or not self._preview then
		return
	end

	local currentPreview = self._previewService:build(preset, self:_selection())
	if not self._previewService.same(self._preview, currentPreview) then
		self._preview = currentPreview
		self:_setFeedback("Targets or values changed. Preview refreshed; review it before applying.", "warning")
		self:_renderDetail()
		return
	end

	local applied, result = self._applyService:apply(preset, currentPreview.targets)
	if not applied then
		self:_setFeedback(result, "danger")
		return
	end

	self._preview = self._previewService:build(preset, self:_selection())
	self:_setFeedback(string.format(
		"Applied to %s: %s, %s, %s. One Undo restores the previous state.",
		countLabel(currentPreview.compatibleCount, "BasePart"),
		countLabel(result.properties, "property", "properties"),
		countLabel(result.tags, "tag"),
		countLabel(result.attributes, "attribute")
	), "success")
	self:_renderDetail()
end

function Controller:_renderPresetList()
	for _, connection in ipairs(self._presetConnections) do
		connection:Disconnect()
	end
	table.clear(self._presetConnections)

	for _, child in ipairs(self._ui.presetList:GetChildren()) do
		if child:IsA("GuiButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local presets = self._store:getPresets()
	if self._selectedName and not self._store:find(self._selectedName) then
		self._selectedName = nil
	end
	if not self._selectedName and #presets > 0 then
		self._selectedName = presets[1].name
	end

	if #presets == 0 then
		local empty = Instance.new("TextLabel")
		empty.AutomaticSize = Enum.AutomaticSize.Y
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.BuilderSans
		empty.LayoutOrder = 10
		empty.Size = UDim2.new(1, -4, 0, 60)
		empty.Text = "No presets yet.\nSelect one BasePart and save its setup."
		empty.TextColor3 = self._ui.colors.muted
		empty.TextSize = 12
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.TextYAlignment = Enum.TextYAlignment.Top
		empty.Parent = self._ui.presetList
		return
	end

	for _, preset in ipairs(presets) do
		local selected = preset.name == self._selectedName
		local presetButton = UIFactory.createPresetButton(self._ui.presetList, preset, selected)
		self._presetConnections[#self._presetConnections + 1] = presetButton.Activated:Connect(function()
			self._selectedName = preset.name
			self._preview = nil
			self._ui.renamePanel.Visible = false
			self:_disarmDelete()
			self:_setFeedback(nil)
			self:_render()
		end)
	end
end

function Controller:_capturedText(preset)
	local lines = {}
	if preset.capture.properties then
		lines[#lines + 1] = "Properties"
		for _, propertyName in ipairs(Constants.PROPERTIES) do
			lines[#lines + 1] = "  " .. propertyName .. " = " .. cleanValue(preset.properties[propertyName])
		end
	end
	if preset.capture.tags then
		lines[#lines + 1] = "Tags"
		if #preset.tags == 0 then
			lines[#lines + 1] = "  None captured"
		else
			for _, tag in ipairs(preset.tags) do
				lines[#lines + 1] = "  + " .. tag
			end
		end
	end
	if preset.capture.attributes then
		lines[#lines + 1] = "Attributes"
		local keys = sortedKeys(preset.attributes)
		if #keys == 0 then
			lines[#lines + 1] = "  None captured"
		else
			for _, attributeName in ipairs(keys) do
				lines[#lines + 1] = "  " .. attributeName .. " = " .. cleanValue(preset.attributes[attributeName])
			end
		end
	end
	return table.concat(lines, "\n")
end

function Controller:_previewText()
	local preview = self._preview
	local preset = self:_preset()
	if not preview then
		return "Run Preview to inspect every pending change."
	end

	local lines = {
		string.format(
			"%d selected | %d compatible | %d ignored | %d changes",
			preview.selectionCount,
			preview.compatibleCount,
			preview.ignoredCount,
			preview.totalChanges
		),
	}
	for _, propertyName in ipairs(Constants.PROPERTIES) do
		local count = preview.propertyChanges[propertyName]
		if count then
			lines[#lines + 1] = string.format(
				"Property %s -> %s: %d target%s",
				propertyName,
				cleanValue(preset.properties[propertyName]),
				count,
				count == 1 and "" or "s"
			)
		end
	end
	for _, tag in ipairs(sortedKeys(preview.tagChanges)) do
		local count = preview.tagChanges[tag]
		lines[#lines + 1] = string.format("Add tag %s: %d target%s", tag, count, count == 1 and "" or "s")
	end
	for _, attributeName in ipairs(sortedKeys(preview.attributeChanges)) do
		local changes = preview.attributeChanges[attributeName]
		lines[#lines + 1] = string.format(
			"Attribute %s = %s: %d to add, %d to update",
			attributeName,
			cleanValue(preset.attributes[attributeName]),
			changes.added,
			changes.updated
		)
	end
	for _, warning in ipairs(preview.warnings) do
		lines[#lines + 1] = "Warning: " .. warning
	end
	return table.concat(lines, "\n")
end

function Controller:_renderDetail()
	local preset = self:_preset()
	local selection = self:_selection()
	local compatible = 0
	for _, instance in ipairs(selection) do
		if instance:IsA("BasePart") then
			compatible += 1
		end
	end
	self._ui.selectionText.Text = string.format(
		"%d selected | %d BasePart%s | %d ignored",
		#selection,
		compatible,
		compatible == 1 and "" or "s",
		#selection - compatible
	)

	if not preset then
		self._ui.detailName.Text = "Choose a preset"
		self._ui.detailCounts.Text = "No preset selected"
		self._ui.capturedText.Text = "Select a preset to inspect its contents."
		self._ui.previewText.Text = "Run Preview to inspect every pending change."
		self._ui.renamePanel.Visible = false
		UIFactory.setButtonEnabled(self._ui.renameButton, false)
		UIFactory.setButtonEnabled(self._ui.deleteButton, false)
		UIFactory.setButtonEnabled(self._ui.previewButton, false)
		UIFactory.setButtonEnabled(self._ui.applyButton, false)
		return
	end

	self._ui.detailName.Text = preset.name
	self._ui.detailCounts.Text = string.format(
		"%s | %s | %s",
		countLabel(preset.capture.properties and #Constants.PROPERTIES or 0, "property", "properties"),
		countLabel(preset.capture.tags and #preset.tags or 0, "tag"),
		countLabel(preset.capture.attributes and countMap(preset.attributes) or 0, "attribute")
	)
	self._ui.capturedText.Text = self:_capturedText(preset)
	self._ui.previewText.Text = self:_previewText()
	UIFactory.setButtonEnabled(self._ui.renameButton, true)
	UIFactory.setButtonEnabled(self._ui.deleteButton, true)
	UIFactory.setButtonEnabled(self._ui.previewButton, true)
	UIFactory.setButtonEnabled(
		self._ui.applyButton,
		self._preview ~= nil and self._preview.compatibleCount > 0 and self._preview.totalChanges > 0
	)
end

function Controller:_render()
	self:_renderPresetList()
	self:_renderDetail()
end

function Controller:destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	for _, connection in ipairs(self._presetConnections) do
		connection:Disconnect()
	end
	table.clear(self._presetConnections)
end

return Controller
