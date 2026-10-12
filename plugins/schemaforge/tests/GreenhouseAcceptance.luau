-- Disposable licensed greenhouse helper. Product actions remain real Studio clicks.
local greenhouse=assert(workspace:FindFirstChild("PlantGreenhouse"),"Open the licensed greenhouse copy")
local pots=assert(greenhouse:FindFirstChild("ProductionPots"))
local selection=game:GetService("Selection")
local widget
for _,obj in ipairs(game:GetDescendants()) do
	if obj:IsA("DockWidgetPluginGui") and obj.Title=="SchemaForge 1.1.0" then widget=obj end
end
assert(widget,"Install the exact SchemaForge 1.1.0 binary")
local root=assert(widget:FindFirstChild("SchemaForgeUI"))
local q={root=root,widget=widget,pots=pots}
local function snapshot()
	local result={}
	for _,obj in ipairs(greenhouse:GetDescendants()) do
		local row={Parent=obj.Parent,Name=obj.Name,Attributes=obj:GetAttributes(),Tags=obj:GetTags()}; table.sort(row.Tags)
		if obj:IsA("BasePart") then
			for _,key in ipairs({"CFrame","Size","Color","Material","Anchored","CanCollide","Transparency"}) do row[key]=obj[key] end
		end
		result[obj]=row
	end
	return result
end
local function equal(a,b)
	if type(a)~="table" then return a==b end
	if type(b)~="table" then return false end
	for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
	for k in pairs(b) do if a[k]==nil then return false end end
	return true
end
function q.resume()
	assert(#pots:GetChildren()==8)
	assert(pots.Cabbage_03:GetAttribute("Cost")==nil and pots.Cabbage_06:GetAttribute("Cost")==nil)
	q.baseline=snapshot(); widget.Enabled=true
	q.saved=game.ServerStorage._SchemaForgeSchemas["Greenhouse pots"].Value
	print("[SF11Greenhouse] Baseline: 8 pots, two missing defaults, original saved V1 contract")
end
function q.inspect(name)
	local obj=assert(root:FindFirstChild(name,true),name)
	print("[SF11Greenhouse][UI]",name,obj.AbsolutePosition,obj.AbsoluteSize)
	if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then print("[SF11Greenhouse][TEXT]",obj.Text) end
end
function q.unchanged()
	assert(equal(q.baseline,snapshot()),"Read-only action changed the greenhouse")
	assert(q.saved==game.ServerStorage._SchemaForgeSchemas["Greenhouse pots"].Value,"Browsing changed saved contract")
	print("[SF11Greenhouse][PASS] Read-only: exact attributes, properties, tags, hierarchy and saved contract preserved")
end
function q.applied()
	local actual=snapshot()
	for _,obj in ipairs({pots.Cabbage_03,pots.Cabbage_06}) do
		assert(actual[obj].Attributes.Cost==25,"Expected missing Cost default 25")
		actual[obj].Attributes.Cost=nil
	end
	assert(equal(q.baseline,actual),"Unexpected change outside the two missing Cost attributes")
	assert(pots.Cabbage_04:GetAttribute("Cost")==-5 and pots.Cabbage_04:GetAttribute("Variety")=="Cabage")
	assert(pots.Cabbage_07:GetAttribute("Enabled")=="yes")
	print("[SF11Greenhouse][PASS] Exact two-default Apply; existing invalid values, properties, attributes, tags and children unchanged")
end
function q.watchHistory()
	local h=game:GetService("ChangeHistoryService")
	q.undo=h.OnUndo:Connect(function() task.defer(function() q.unchanged(); print("[SF11Greenhouse][PASS] Native menu Undo restored greenhouse") end) end)
	q.redo=h.OnRedo:Connect(function() task.defer(function() q.applied(); print("[SF11Greenhouse][PASS] Native menu Redo reapplied only two defaults") end) end)
end
function q.stopHistory() if q.undo then q.undo:Disconnect(); q.redo:Disconnect() end end
function q.selectRoot() selection:Set({pots}) end
function q.selectReference() selection:Set({pots.Cabbage_Reference}) end
function q.assertSelection(expectedNames)
	local actual=selection:Get(); assert(#actual==#expectedNames,"Unexpected selected count")
	for _,obj in ipairs(actual) do assert(obj.Parent==pots and table.find(expectedNames,obj.Name),"Unexpected selected object") end
	q.unchanged(); print("[SF11Greenhouse][PASS] Exact affected subset selected: "..#actual)
end
function q.context()
	assert(root.Header.ContractName.Text=="Greenhouse pots")
	assert(root.Header.ContractTag.Text:find("GrowablePot",1,true))
	assert(root.Header.AuditScope.Text:find("Scope:",1,true))
	print("[SF11Greenhouse][PASS] Existing contract loaded with name, tag and scope context")
end
function q.checkStale()
	pots.Cabbage_Reference:SetAttribute("Cost",26)
	task.delay(1.5,function()
		local apply=assert(root:FindFirstChild("Apply",true))
		assert(not apply.Active,"Stale preview did not disable Apply")
		print("[SF11Greenhouse][PASS] Relevant project change disables stale Apply")
		pots.Cabbage_Reference:SetAttribute("Cost",25)
	end)
end
function q.fixture()
	local json=game:GetService("HttpService")
	local s=json:JSONDecode(q.saved)
	s.name="QA long contract - thirty two explicit greenhouse configuration fields"
	s.tag="SchemaForgeQAOnly"; s.fields={}; s.children={}
	for i=1,32 do
		table.insert(s.fields,{name=string.format("Field%02d_",i)..string.rep("LongName",8),kind="number",required=true,
			hasDefault=true,default=25,min=0,max=100,integer=true,choices={},description="Field "..i.." designer note"})
		table.insert(s.children,{path="Socket"..i.."/Prompt",className="ProximityPrompt",description="Required interaction point"})
	end
	assert(not game.ServerStorage._SchemaForgeSchemas:FindFirstChild(s.name))
	local entry=Instance.new("StringValue"); entry.Name=s.name; entry.Value=json:JSONEncode(s)
	entry.Parent=game.ServerStorage._SchemaForgeSchemas; q.fixtureEntry=entry
	local folder=Instance.new("Folder"); folder.Name="SchemaForgeQADuplicates"; folder.Parent=workspace; q.fixtureRoot=folder
	for _=1,2 do local obj=Instance.new("Model"); obj.Name=string.rep("SameName",12); obj:AddTag(s.tag); obj.Parent=folder end
	selection:Set({folder}); print("[SF11Greenhouse] Disposable 32-field/32-child schema and duplicate-name fixtures ready")
end
function q.reach(name)
	local body=root.Body; local obj=assert(body:FindFirstChild(name,true),name)
	local y=body.CanvasPosition.Y+obj.AbsolutePosition.Y-body.AbsolutePosition.Y
	body.CanvasPosition=Vector2.new(0,math.clamp(y-30,0,math.max(0,body.AbsoluteCanvasSize.Y-body.AbsoluteWindowSize.Y)))
	task.defer(function() q.inspect(name) end)
end
function q.watchText(name)
	local body=root.Body; local box=assert(body:FindFirstChild(name,true)); local scroll=body.CanvasPosition
	local connection
	connection=box:GetPropertyChangedSignal("Text"):Connect(function()
		task.defer(function()
			assert(body:FindFirstChild(name,true)==box,"Text edit replaced the input")
			assert(box:IsFocused(),"Text edit lost focus")
			assert(body.CanvasPosition==scroll,"Text edit moved scroll")
			assert(box.CursorPosition>0,"Text edit lost caret")
			print("[SF11Greenhouse][PASS] Real text edit retained input, focus, caret and scroll: "..name)
		end)
	end)
	q.textWatch=connection
end
function q.stopTextWatch() if q.textWatch then q.textWatch:Disconnect(); q.textWatch=nil end end
function q.checkTheme()
	local theme=settings().Studio.Theme
	assert(root.BackgroundColor3==theme:GetColor(Enum.StudioStyleGuideColor.MainBackground))
	assert(root.Header.ProductTitle.TextColor3==theme:GetColor(Enum.StudioStyleGuideColor.MainText),"Persistent title retained the previous theme")
	assert(root.Footer.Version.TextColor3==theme:GetColor(Enum.StudioStyleGuideColor.SubText),"Persistent footer retained the previous theme")
	for _,obj in ipairs(root.Body:GetDescendants()) do
		if obj:IsA("TextLabel") and obj.Name:match("Label$") then
			assert(obj.TextColor3==theme:GetColor(Enum.StudioStyleGuideColor.SubText),obj.Name..": stale theme")
		end
	end
	print("[SF11Greenhouse][PASS] Native theme colors on persistent and current controls: "..theme.Name)
end
function q.cleanFixture()
	q.stopTextWatch()
	if q.fixtureEntry then q.fixtureEntry:Destroy() end
	if q.fixtureRoot then q.fixtureRoot:Destroy() end
	q.selectRoot(); q.unchanged()
end
_G.SchemaForgeGreenhouseQA=q
print("[SF11Greenhouse] Helper ready; resume() records the original scene")
