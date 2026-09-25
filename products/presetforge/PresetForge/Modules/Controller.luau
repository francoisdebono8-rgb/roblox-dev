local Constants = require(script.Parent.Constants)
local Schema = require(script.Parent.Schema)
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

local function copyArray(values)
	local result = table.create(#values)
	for index, value in ipairs(values) do
		result[index] = value
	end
	return result
end

local function countLabel(count, singular, plural)
	return string.format("%d %s", count, count == 1 and singular or plural or singular .. "s")
end

local function cleanValue(value)
	if value == nil then
		return "<missing>"
	end
	local kind = typeof(value)
	local text
	if kind == "number" then
		text = string.format("%.6g", value)
	elseif kind == "EnumItem" then
		text = tostring(value)
	elseif kind == "string" then
		text = value
	else
		text = tostring(value)
	end
	text = text:gsub("[%c]", " ")
	if #text > 92 then
		return text:sub(1, 89) .. "..."
	end
	return text
end

local function recipeKey(library, name)
	return tostring(library) .. "\0" .. tostring(name)
end

function Controller.new(ui, repository, captureService, previewService, applyService, selectionService)
	local self = setmetatable({
		_ui = ui,
		_repository = repository,
		_captureService = captureService,
		_previewService = previewService,
		_applyService = applyService,
		_selectionService = selectionService,
		_selectedLibrary = nil,
		_selectedName = nil,
		_scope = "Selection",
		_preview = nil,
		_previewSelection = nil,
		_previewOptions = nil,
		_deleteArmedFor = nil,
		_editorMode = nil,
		_editorSource = nil,
		_editorLibrary = "Local",
		_editorFields = {},
		_internalSelection = false,
		_connections = {},
		_presetConnections = {},
		_resultConnections = {},
	}, Controller)
	self:_connect()
	self:_render()
	return self
end

function Controller:_listen(signal, callback)
	self._connections[#self._connections + 1] = signal:Connect(callback)
end

function Controller:_recipe()
	if not self._selectedLibrary or not self._selectedName then
		return nil
	end
	return self._repository:find(self._selectedLibrary, self._selectedName)
end

function Controller:_selection()
	return self._selectionService:Get()
end

function Controller:_setFeedback(message, tone)
	self._ui.feedback.Text = message or ""
	self._ui.feedback.Visible = message ~= nil and message ~= ""
	self._ui.feedback.TextColor3 = self._ui.colors[tone or "muted"] or self._ui.colors.muted
end

function Controller:showError(message)
	self:_setFeedback(message, "danger")
end

function Controller:_disarmDelete()
	self._deleteArmedFor = nil
	self._ui.deleteButton.Text = "Delete"
	self._ui.deleteButton.TextColor3 = self._ui.colors.text
end

function Controller:_clearPreview(message)
	self._preview = nil
	self._previewSelection = nil
	self._previewOptions = nil
	if message then
		self:_setFeedback(message, "warning")
	end
end

function Controller:_connect()
	self:_listen(self._ui.saveButton.Activated, function()
		self:_openCreate()
	end)
	self:_listen(self._ui.editorCancel.Activated, function()
		self._ui.editorOverlay.Visible = false
	end)
	self:_listen(self._ui.editorConfirm.Activated, function()
		self:_saveEditor()
	end)
	self:_listen(self._ui.localLibraryButton.Activated, function()
		if self._editorMode == "create" then
			self:_setEditorLibrary("Local")
		end
	end)
	self:_listen(self._ui.projectLibraryButton.Activated, function()
		if self._editorMode == "create" then
			self:_setEditorLibrary("Project")
		end
	end)

	self:_listen(self._ui.renameButton.Activated, function()
		local recipe = self:_recipe()
		if recipe then
			self:_disarmDelete()
			self._ui.renameInput.Text = recipe.name
			self._ui.renamePanel.Visible = true
			self._ui.renameInput:CaptureFocus()
		end
	end)
	self:_listen(self._ui.renameCancel.Activated, function()
		self._ui.renamePanel.Visible = false
	end)
	self:_listen(self._ui.renameConfirm.Activated, function()
		self:_renameRecipe()
	end)
	self:_listen(self._ui.renameInput.FocusLost, function(enterPressed)
		if enterPressed and self._ui.renamePanel.Visible then
			self:_renameRecipe()
		end
	end)
	self:_listen(self._ui.editButton.Activated, function()
		self:_openEdit()
	end)
	self:_listen(self._ui.recaptureButton.Activated, function()
		self:_recapture()
	end)
	self:_listen(self._ui.deleteButton.Activated, function()
		self:_deleteRecipe()
	end)

	self:_listen(self._ui.scopeSelectionButton.Activated, function()
		self:_setScope("Selection")
	end)
	self:_listen(self._ui.scopeDescendantsButton.Activated, function()
		self:_setScope("Descendants")
	end)
	for _, input in ipairs({ self._ui.classFilterInput, self._ui.nameFilterInput, self._ui.tagFilterInput }) do
		self:_listen(input:GetPropertyChangedSignal("Text"), function()
			if self._preview then
				self:_clearPreview("Scope or filter changed. Run Preview again.")
				self:_renderDetail()
			end
		end)
	end

	self:_listen(self._ui.previewButton.Activated, function()
		self:_runPreview()
	end)
	self:_listen(self._ui.applyButton.Activated, function()
		self:_apply()
	end)
	self:_listen(self._ui.selectAffectedButton.Activated, function()
		self:_selectResults("affected")
	end)
	self:_listen(self._ui.selectMatchingButton.Activated, function()
		self:_selectResults("matching")
	end)
	self:_listen(self._ui.selectIgnoredButton.Activated, function()
		self:_selectResults("ignored")
	end)

	self:_listen(self._selectionService.SelectionChanged, function()
		if self._internalSelection then
			return
		end
		self._ui.editorOverlay.Visible = false
		self:_clearPreview("Selection changed. Run Preview before applying.")
		self:_disarmDelete()
		self:_renderDetail()
	end)
end

function Controller:_source()
	local selection = self:_selection()
	if #selection ~= 1 then
		return nil, nil, "Select exactly one supported source"
	end
	local schema = Schema.forInstance(selection[1])
	if not schema then
		return nil, nil, "The selected source class is not supported"
	end
	return selection[1], schema
end

function Controller:_setEditorLibrary(library)
	self._editorLibrary = library
	UIFactory.setSegment(self._ui.localLibraryButton, library == "Local")
	UIFactory.setSegment(self._ui.projectLibraryButton, library == "Project")
end

function Controller:_clearDynamic(container, connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function Controller:_buildEditorFields(source, schema, selectedProperties)
	self:_clearDynamic(self._ui.fieldList, {})
	table.clear(self._editorFields)
	if #schema.properties == 0 then
		local empty = Instance.new("TextLabel")
		empty.AutomaticSize = Enum.AutomaticSize.Y
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.BuilderSans
		empty.Size = UDim2.new(1, -4, 0, 36)
		empty.Text = "This class supports tags and attributes only."
		empty.TextColor3 = self._ui.colors.muted
		empty.TextSize = 12
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.Parent = self._ui.fieldList
		return
	end
	for index, definition in ipairs(schema.properties) do
		local value = source[definition.name]
		local text = string.format("%s    %s", definition.name, cleanValue(value))
		local check = UIFactory.createCheckbox(self._ui.fieldList, text, selectedProperties[definition.name] ~= nil)
		check.LayoutOrder = index
		check.ZIndex = 22
		self._editorFields[definition.name] = check
	end
end

function Controller:_openEditor(mode, source, schema, recipe)
	self._editorMode = mode
	self._editorSource = source
	self._ui.editorTitle.Text = mode == "create" and "Save Recipe" or "Edit Recipe"
	self._ui.editorSourceText.Text = string.format("Source: %s (%s)", source:GetFullName(), schema.label)
	self._ui.editorNameInput.Text = recipe and recipe.name or ""
	self._ui.editorNameInput.TextEditable = mode == "create"
	self._ui.editorNameInput.TextTransparency = mode == "create" and 0 or 0.35
	self._ui.editorConfirm.Text = mode == "create" and "Save" or "Update"
	self._ui.editorHint.Text = "Save and Preview are read-only. Only checked fields can be applied."
	self._ui.editorHint.TextColor3 = self._ui.colors.muted

	if mode == "create" then
		self:_setEditorLibrary("Local")
		UIFactory.setButtonEnabled(self._ui.localLibraryButton, true)
		UIFactory.setButtonEnabled(self._ui.projectLibraryButton, true)
		UIFactory.setCheckbox(self._ui.tagsCheck, false)
		UIFactory.setCheckbox(self._ui.attributesCheck, false)
	else
		self:_setEditorLibrary(recipe.library)
		UIFactory.setButtonEnabled(self._ui.localLibraryButton, false)
		UIFactory.setButtonEnabled(self._ui.projectLibraryButton, false)
		UIFactory.setCheckbox(self._ui.tagsCheck, recipe.capture.tags)
		UIFactory.setCheckbox(self._ui.attributesCheck, recipe.capture.attributes)
	end
	self:_buildEditorFields(source, schema, recipe and recipe.properties or {})
	self._ui.editorOverlay.Visible = true
	if mode == "create" then
		self._ui.editorNameInput:CaptureFocus()
	end
end

function Controller:_openCreate()
	local source, schema, sourceError = self:_source()
	if not source then
		self:_setFeedback(sourceError, "danger")
		return
	end
	self:_disarmDelete()
	self:_openEditor("create", source, schema, nil)
end

function Controller:_openEdit()
	local recipe = self:_recipe()
	if not recipe then
		return
	end
	local source, schema, sourceError = self:_source()
	if not source then
		self:_setFeedback(sourceError, "danger")
		return
	elseif schema.id ~= recipe.schemaId then
		self:_setFeedback("Edit requires a source of the recipe's current class. Use Recapture for compatible class changes.", "danger")
		return
	end
	self:_disarmDelete()
	self:_openEditor("edit", source, schema, recipe)
end

function Controller:_selectedEditorFields()
	local fields = {}
	for propertyName, check in pairs(self._editorFields) do
		if check:GetAttribute("Checked") == true then
			fields[#fields + 1] = propertyName
		end
	end
	table.sort(fields)
	return fields
end

function Controller:_saveEditor()
	local selection = self:_selection()
	if #selection ~= 1 or selection[1] ~= self._editorSource then
		self._ui.editorHint.Text = "Source selection changed. Close and reopen the editor."
		self._ui.editorHint.TextColor3 = self._ui.colors.danger
		return
	end
	local captured, captureError = self._captureService:capture(selection, {
		properties = self:_selectedEditorFields(),
		tags = self._ui.tagsCheck:GetAttribute("Checked") == true,
		attributes = self._ui.attributesCheck:GetAttribute("Checked") == true,
	})
	if not captured then
		self._ui.editorHint.Text = captureError
		self._ui.editorHint.TextColor3 = self._ui.colors.danger
		return
	end

	local saved, result
	if self._editorMode == "create" then
		saved, result = self._repository:create(self._editorLibrary, self._ui.editorNameInput.Text, captured)
	else
		saved, result = self._repository:update(self._selectedLibrary, self._selectedName, captured)
	end
	if not saved then
		self._ui.editorHint.Text = result
		self._ui.editorHint.TextColor3 = self._ui.colors.danger
		return
	end

	self._selectedLibrary = result.library
	self._selectedName = result.name
	self._ui.editorOverlay.Visible = false
	self:_clearPreview()
	self:_setFeedback(self._editorMode == "create"
		and (result.library .. " recipe saved.")
		or "Recipe fields and values updated.", "success")
	self:_resetFilters(result)
	self:_render()
end

function Controller:_renameRecipe()
	local recipe = self:_recipe()
	if not recipe then
		return
	end
	local renamed, result = self._repository:rename(recipe.library, recipe.name, self._ui.renameInput.Text)
	if not renamed then
		self:_setFeedback(result, "danger")
		return
	end
	self._selectedName = result.name
	self._ui.renamePanel.Visible = false
	self:_clearPreview()
	self:_setFeedback("Recipe renamed.", "success")
	self:_render()
end

function Controller:_recapture()
	local recipe = self:_recipe()
	if not recipe then
		return
	end
	local captured, captureError = self._captureService:recapture(recipe, self:_selection())
	if not captured then
		self:_setFeedback("Recapture refused: " .. captureError, "danger")
		return
	end
	local updated, result = self._repository:update(recipe.library, recipe.name, captured)
	if not updated then
		self:_setFeedback(result, "danger")
		return
	end
	self:_clearPreview()
	self:_resetFilters(result)
	self:_setFeedback("Values recaptured; the chosen field set was preserved.", "success")
	self:_render()
end

function Controller:_deleteRecipe()
	local recipe = self:_recipe()
	if not recipe then
		return
	end
	local key = recipeKey(recipe.library, recipe.name)
	if self._deleteArmedFor ~= key then
		self._deleteArmedFor = key
		self._ui.deleteButton.Text = "Confirm"
		self._ui.deleteButton.TextColor3 = self._ui.colors.danger
		self:_setFeedback("Click Confirm to permanently delete this " .. recipe.library .. " recipe.", "warning")
		return
	end
	local deleted, deleteError = self._repository:delete(recipe.library, recipe.name)
	if not deleted then
		self:_setFeedback(deleteError, "danger")
		return
	end
	self._selectedLibrary = nil
	self._selectedName = nil
	self:_clearPreview()
	self:_disarmDelete()
	self:_setFeedback("Recipe deleted.", "success")
	self:_render()
end

function Controller:_setScope(scope)
	if self._scope == scope then
		return
	end
	self._scope = scope
	self:_clearPreview("Scope changed. Run Preview again.")
	self:_renderDetail()
end

function Controller:_resetFilters(recipe)
	self._ui.classFilterInput.Text = Schema.defaultClassFilter(recipe.schemaId) or ""
	self._ui.nameFilterInput.Text = ""
	self._ui.tagFilterInput.Text = ""
end

function Controller:_rawScopeOptions(recipe)
	if self._scope == "Selection" then
		return { scope = "Selection" }
	end
	return {
		scope = "Descendants",
		className = self._ui.classFilterInput.Text ~= "" and self._ui.classFilterInput.Text
			or Schema.defaultClassFilter(recipe.schemaId),
		nameContains = self._ui.nameFilterInput.Text,
		tag = self._ui.tagFilterInput.Text,
	}
end

function Controller:_runPreview()
	local recipe = self:_recipe()
	if not recipe then
		return
	end
	self:_disarmDelete()
	local selection = self:_selection()
	local preview, previewError = self._previewService:build(recipe, selection, self:_rawScopeOptions(recipe))
	if not preview then
		self:_setFeedback(previewError, "danger")
		return
	end
	self._preview = preview
	self._previewSelection = copyArray(selection)
	self._previewOptions = preview.options
	self:_setFeedback("Preview is read-only. Inspect the detailed changes before Apply.", "muted")
	self:_renderDetail()
end

function Controller:_apply()
	local recipe = self:_recipe()
	if not recipe or not self._preview or not self._previewSelection then
		return
	end
	local currentPreview, previewError = self._previewService:build(recipe, self._previewSelection, self._previewOptions)
	if not currentPreview then
		self:_setFeedback(previewError, "danger")
		return
	elseif not self._previewService.same(self._preview, currentPreview) then
		self._preview = currentPreview
		self:_setFeedback("Targets or values changed. Preview refreshed; review it before applying.", "warning")
		self:_renderDetail()
		return
	end

	local applied, result = self._applyService:apply(recipe, currentPreview.targets)
	if not applied then
		self:_setFeedback(result, "danger")
		return
	end
	self._preview = assert(self._previewService:build(recipe, self._previewSelection, self._previewOptions))
	self:_setFeedback(string.format(
		"Applied to %s: %s, %s, %s. One Undo restores the previous state.",
		countLabel(result.targets, "target"),
		countLabel(result.properties, "property", "properties"),
		countLabel(result.tags, "tag"),
		countLabel(result.attributes, "attribute")
	), "success")
	self:_renderDetail()
end

function Controller:_selectInstances(instances)
	local live = {}
	for _, instance in ipairs(instances) do
		if typeof(instance) == "Instance" and instance.Parent ~= nil then
			live[#live + 1] = instance
		end
	end
	self._internalSelection = true
	self._selectionService:Set(live)
	task.defer(function()
		self._internalSelection = false
	end)
end

function Controller:_selectResults(status)
	if not self._preview then
		return
	end
	self:_selectInstances(self._preview[status])
end

function Controller:_renderPresetList()
	self:_clearDynamic(self._ui.presetList, self._presetConnections)
	local recipes = self._repository:getRecipes()
	if self._selectedName and not self:_recipe() then
		self._selectedLibrary = nil
		self._selectedName = nil
	end
	if not self._selectedName and #recipes > 0 then
		self._selectedLibrary = recipes[1].library
		self._selectedName = recipes[1].name
		self:_resetFilters(recipes[1])
	end
	if #recipes == 0 then
		local empty = Instance.new("TextLabel")
		empty.AutomaticSize = Enum.AutomaticSize.Y
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.BuilderSans
		empty.LayoutOrder = 10
		empty.Size = UDim2.new(1, -4, 0, 64)
		empty.Text = "No recipes yet.\nSelect one supported source and save exact fields."
		empty.TextColor3 = self._ui.colors.muted
		empty.TextSize = 12
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.TextYAlignment = Enum.TextYAlignment.Top
		empty.Parent = self._ui.presetList
		return
	end
	for _, recipe in ipairs(recipes) do
		local selected = recipe.library == self._selectedLibrary and recipe.name == self._selectedName
		local recipeButton = UIFactory.createPresetButton(self._ui.presetList, recipe, selected)
		self._presetConnections[#self._presetConnections + 1] = recipeButton.Activated:Connect(function()
			self._selectedLibrary = recipe.library
			self._selectedName = recipe.name
			self._ui.renamePanel.Visible = false
			self:_clearPreview()
			self:_disarmDelete()
			self:_resetFilters(recipe)
			self:_setFeedback(nil)
			self:_render()
		end)
	end
end

function Controller:_capturedText(recipe)
	local lines = {}
	for _, propertyName in ipairs(sortedKeys(recipe.properties)) do
		lines[#lines + 1] = propertyName .. " = " .. cleanValue(recipe.properties[propertyName])
	end
	if recipe.capture.tags then
		lines[#lines + 1] = #recipe.tags == 0 and "Tags: none captured" or "Tags: + " .. table.concat(recipe.tags, ", + ")
	end
	if recipe.capture.attributes then
		local keys = sortedKeys(recipe.attributes)
		if #keys == 0 then
			lines[#lines + 1] = "Attributes: none captured"
		else
			for _, name in ipairs(keys) do
				lines[#lines + 1] = "Attribute " .. name .. " = " .. cleanValue(recipe.attributes[name])
			end
		end
	end
	return #lines > 0 and table.concat(lines, "\n") or "No fields captured"
end

function Controller:_resultText(result)
	local status = string.upper(result.status)
	if result.status == "ignored" then
		return string.format("%s  %s\n%s", status, result.path, result.reason)
	end
	local lines = { status .. "  " .. result.path }
	for _, change in ipairs(result.changes) do
		local before = change.beforeExists == false and "<missing>" or cleanValue(change.before)
		lines[#lines + 1] = string.format("%s %s: %s -> %s", change.kind, change.name, before, cleanValue(change.after))
	end
	if #result.changes == 0 then
		lines[#lines + 1] = "Already matches every selected field."
	end
	return table.concat(lines, "\n")
end

function Controller:_renderResults()
	self:_clearDynamic(self._ui.resultList, self._resultConnections)
	if not self._preview then
		return
	end
	local limit = math.min(#self._preview.results, Constants.MAX_RENDERED_RESULTS or 500)
	for index = 1, limit do
		local result = self._preview.results[index]
		local resultButton = UIFactory.createResultButton(self._ui.resultList, self:_resultText(result), result.status)
		self._resultConnections[#self._resultConnections + 1] = resultButton.Activated:Connect(function()
			self:_selectInstances({ result.instance })
		end)
	end
	if #self._preview.results > limit then
		local more = Instance.new("TextLabel")
		more.AutomaticSize = Enum.AutomaticSize.Y
		more.BackgroundTransparency = 1
		more.Font = Enum.Font.BuilderSans
		more.LayoutOrder = 20
		more.Size = UDim2.new(1, -4, 0, 36)
		more.Text = string.format("Showing %d of %d results. Narrow the filters to inspect each object.", limit, #self._preview.results)
		more.TextColor3 = self._ui.colors.warning
		more.TextSize = 12
		more.TextWrapped = true
		more.TextXAlignment = Enum.TextXAlignment.Left
		more.Parent = self._ui.resultList
	end
end

function Controller:_renderDetail()
	local recipe = self:_recipe()
	local selection = self:_selection()
	UIFactory.setSegment(self._ui.scopeSelectionButton, self._scope == "Selection")
	UIFactory.setSegment(self._ui.scopeDescendantsButton, self._scope == "Descendants")
	self._ui.filterPanel.Visible = self._scope == "Descendants"
	self._ui.selectionText.Text = string.format(
		"%d selected | %s scope",
		#selection,
		self._scope
	)

	if not recipe then
		self._ui.detailName.Text = "Choose a recipe"
		self._ui.libraryBadge.Text = ""
		self._ui.detailCounts.Text = "No recipe selected"
		self._ui.capturedText.Text = "Select a recipe to inspect its fields."
		self._ui.previewSummary.Text = "Run Preview to inspect every pending change."
		self._ui.renamePanel.Visible = false
		for _, button in ipairs({
			self._ui.renameButton,
			self._ui.editButton,
			self._ui.recaptureButton,
			self._ui.deleteButton,
			self._ui.previewButton,
			self._ui.applyButton,
			self._ui.selectAffectedButton,
			self._ui.selectMatchingButton,
			self._ui.selectIgnoredButton,
		}) do
			UIFactory.setButtonEnabled(button, false)
		end
		self:_renderResults()
		return
	end

	self._ui.detailName.Text = recipe.name
	self._ui.libraryBadge.Text = string.upper(recipe.library)
	self._ui.detailCounts.Text = string.format(
		"%s | %s | %s | %s",
		recipe.schemaId,
		countLabel(countMap(recipe.properties), "field"),
		countLabel(recipe.capture.tags and #recipe.tags or 0, "tag"),
		countLabel(recipe.capture.attributes and countMap(recipe.attributes) or 0, "attribute")
	)
	self._ui.capturedText.Text = self:_capturedText(recipe)
	if not self._preview then
		self._ui.previewSummary.Text = "Run Preview to inspect every pending change."
	else
		self._ui.previewSummary.Text = string.format(
			"%d scanned | %d compatible | %d affected | %d matching | %d ignored | %d writes",
			self._preview.scannedCount,
			self._preview.compatibleCount,
			self._preview.affectedCount,
			self._preview.matchingCount,
			self._preview.ignoredCount,
			self._preview.totalChanges
		)
	end

	for _, button in ipairs({ self._ui.renameButton, self._ui.editButton, self._ui.recaptureButton, self._ui.deleteButton }) do
		UIFactory.setButtonEnabled(button, true)
	end
	UIFactory.setButtonEnabled(self._ui.previewButton, true)
	UIFactory.setButtonEnabled(self._ui.applyButton, self._preview ~= nil and self._preview.affectedCount > 0)
	UIFactory.setButtonEnabled(self._ui.selectAffectedButton, self._preview ~= nil and #self._preview.affected > 0)
	UIFactory.setButtonEnabled(self._ui.selectMatchingButton, self._preview ~= nil and #self._preview.matching > 0)
	UIFactory.setButtonEnabled(self._ui.selectIgnoredButton, self._preview ~= nil and #self._preview.ignored > 0)
	self:_renderResults()
end

function Controller:_render()
	self:_renderPresetList()
	self:_renderDetail()
end

function Controller:destroy()
	for _, connections in ipairs({ self._connections, self._presetConnections, self._resultConnections }) do
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		table.clear(connections)
	end
end

return Controller
