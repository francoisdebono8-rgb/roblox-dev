local Schema = require(script.Parent.Schema)
local Engine = require(script.Parent.Engine)
local Store = require(script.Parent.Store)
local View = {}
local function make(class, parent, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end
local function stack(parent, gap)
	make("UIListLayout", parent, { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder })
end
local function padding(parent, n)
	make("UIPadding", parent, {PaddingLeft=UDim.new(0,n), PaddingRight=UDim.new(0,n), PaddingTop=UDim.new(0,n), PaddingBottom=UDim.new(0,n)})
end
local function cleanError(err)
	local text = tostring(err):match("^[^\n]+") or "Operation failed. Please retry."
	return text:gsub("^.-:%d+: ", "")
end
local function sameSelection(a,b)
	if #a~=#b then return false end
	for _,obj in ipairs(a) do if not table.find(b,obj) then return false end end
	return true
end
function View.mount(widget, selection, history)
	local state={schema=Schema.new(),tab="Rules",scope="Selection",fieldIndex=1,childIndex=1,childMode=false,page=1,
		message="",dirty=false,reason="All",field="",picked={},drafts={},scrolls={},detail=false,contract=false}
	state.contract=#state.schema.fields==0
	local disposed,rendering=false,false
	local renderGeneration=0
	local inputOwners=setmetatable({}, {__mode="k"})
	local render,refresh,collection,rail,body
	local wide=false
	local validation={}
	local colors,styles={},{}
	local studio=settings().Studio
	local function paint(obj,property,role)
		if not styles[obj] then
			styles[obj]={}
			-- Keep native Instance wrappers alive until their controls are destroyed.
			obj.Destroying:Connect(function() styles[obj]=nil end)
		end
		styles[obj][property]=role; obj[property]=colors[role]
	end
	local function theme()
		local t=studio.Theme
		local background=t:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		colors.accent=Color3.fromRGB(99,214,174); colors.onAccent=Color3.fromRGB(15,45,34)
		local light=background.R+background.G+background.B>1.5
		colors.bg=light and Color3.fromRGB(234,238,237) or Color3.fromRGB(21,25,28)
		colors.text=light and Color3.fromRGB(31,42,38) or Color3.fromRGB(240,243,241)
		colors.muted=light and Color3.fromRGB(92,106,100) or Color3.fromRGB(154,166,161)
		colors.border=light and Color3.fromRGB(206,216,211) or Color3.fromRGB(52,60,66)
		colors.note=light and Color3.fromRGB(18,105,77) or colors.accent
		colors.error=light and Color3.fromRGB(175,53,46) or Color3.fromRGB(239,106,98)
		colors.warning=light and Color3.fromRGB(143,96,25) or Color3.fromRGB(229,168,77)
		colors.surface=light and Color3.fromRGB(247,249,248) or Color3.fromRGB(26,31,35)
		colors.raised=light and Color3.fromRGB(255,255,255) or Color3.fromRGB(32,38,43)
		colors.field=light and Color3.fromRGB(240,244,242) or Color3.fromRGB(37,44,49)
		colors.selected=light and Color3.fromRGB(229,241,235) or Color3.fromRGB(32,43,39)
		colors.selectedBorder=light and Color3.fromRGB(131,175,154) or Color3.fromRGB(60,102,86)
		colors.repair=light and Color3.fromRGB(237,247,241) or Color3.fromRGB(23,43,36)
		colors.hover=light and Color3.fromRGB(231,237,234) or Color3.fromRGB(42,50,53)
		colors.pressed=light and Color3.fromRGB(215,229,221) or Color3.fromRGB(48,65,58)
		for obj,roles in pairs(styles) do for property,role in pairs(roles) do obj[property]=colors[role] end end
	end
	theme()
	local root=make("Frame",widget,{Name="SchemaForgeUI",Size=UDim2.fromScale(1,1),BorderSizePixel=0,ClipsDescendants=true})
	paint(root,"BackgroundColor3","bg")
	local function label(parent,name,text,role,height)
		local obj=make("TextLabel",parent,{Name=name,Text=text,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 18),
			AutomaticSize=height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,Font=Enum.Font.BuilderSans,TextSize=13,
			TextWrapped=not height,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
			TextTruncate=height and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None})
		paint(obj,"TextColor3",role or "text"); return obj
	end
	local tooltip=label(root,"Tooltip","","text")
	tooltip.ZIndex=50; tooltip.Visible=false; tooltip.BackgroundTransparency=0; padding(tooltip,8); paint(tooltip,"BackgroundColor3","field")
	local function tip(obj,text)
		local hovering=false
		obj.MouseEnter:Connect(function()
			hovering=true
			task.delay(0.65,function()
				if not hovering or not obj.Parent or disposed then return end
				tooltip.Text=text or obj.Text; tooltip.Size=UDim2.new(1,-24,0,0)
				tooltip.Position=UDim2.fromOffset(12,math.clamp(obj.AbsolutePosition.Y-root.AbsolutePosition.Y+obj.AbsoluteSize.Y,8,math.max(8,root.AbsoluteSize.Y-100)))
				tooltip.Visible=true
			end)
		end)
		obj.MouseLeave:Connect(function() hovering=false; tooltip.Visible=false end)
	end
	local header=make("Frame",root,{Name="Header",Size=UDim2.new(1,0,0,118),BackgroundTransparency=1})
	local title=label(header,"ProductTitle","SchemaForge","text",24)
	title.Position=UDim2.fromOffset(12,6); title.Size=UDim2.new(1,-104,0,18); title.TextSize=13; title.Font=Enum.Font.BuilderSansBold; paint(title,"TextColor3","muted")
	local status=label(header,"DocumentState","Draft","muted",22); status.Position=UDim2.new(1,-84,0,8); status.Size=UDim2.fromOffset(72,22); status.TextXAlignment=Enum.TextXAlignment.Center; status.TextYAlignment=Enum.TextYAlignment.Center; status.TextSize=12
	status.BackgroundTransparency=0; paint(status,"BackgroundColor3","selected"); make("UICorner",status,{CornerRadius=UDim.new(0,5)})
	local context=label(header,"ContractName","","text",22); context.Position=UDim2.fromOffset(12,24); context.Size=UDim2.new(1,-24,0,22); context.Font=Enum.Font.BuilderSansBold; context.TextSize=18
	local tag=label(header,"ContractTag","","muted",18); tag.Position=UDim2.fromOffset(12,47); tag.Size=UDim2.new(1,-24,0,18); tag.TextSize=12
	local scopeText=label(header,"AuditScope","","muted",18); scopeText.Visible=false
	for _,obj in ipairs({context,tag,scopeText}) do tip(obj) end
	local nav=make("Frame",header,{Name="Tabs",Position=UDim2.fromOffset(12,70),Size=UDim2.new(1,-24,0,30),BackgroundTransparency=1})
	make("UIGridLayout",nav,{CellSize=UDim2.new(0.25,-3,1,0),CellPadding=UDim2.fromOffset(4,0),SortOrder=Enum.SortOrder.LayoutOrder})
	local workspaceUI=make("Frame",root,{Name="Body",BackgroundTransparency=1,ClipsDescendants=true})
	local function pane(name)
		local p=make("ScrollingFrame",workspaceUI,{Name=name,BorderSizePixel=0,CanvasSize=UDim2.new(),
			AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ClipsDescendants=true})
		paint(p,"BackgroundColor3",name=="Detail" and "raised" or "surface")
		return p
	end
	rail=pane("Navigation"); collection=pane("Collection"); body=pane("Detail")
	local footer=make("Frame",root,{Name="Footer",Position=UDim2.new(0,12,1,-62),Size=UDim2.new(1,-24,0,62),BackgroundTransparency=1})
	local message=label(footer,"Status","","muted",18); message.TextSize=12
	tip(message)
	local actions=make("Frame",footer,{Name="Actions",Position=UDim2.fromOffset(0,14),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1})
	local line=make("Frame",footer,{Size=UDim2.new(1,0,0,1),BorderSizePixel=0}); paint(line,"BackgroundColor3","border")
	local function invalidate() state.audit=nil; state.plan=nil; state.stale=nil; state.finding=nil; state.page=1; state.picked={}; state.subsetActive=false end
	local function changed()
		local previousPlan=state.plan
		state.schema.version=Schema.version; state.dirty=true; state.message=""; state.failed=false; state.success=nil; invalidate()
		if previousPlan then state.plan=previousPlan; state.stale="Contract changed. Audit and preview again." end
		if refresh then refresh() end
	end
	local function subsetChanged()
		if state.plan then state.stale="Subset changed. Audit and preview again." end
	end
	local function act(fn,inspection)
		return function()
			if disposed or rendering then return end
			if not inspection then state.message=""; state.failed=false; state.success=nil end
			local ok,err=pcall(fn)
			if not ok then state.message=cleanError(err); state.failed=true end
			render()
		end
	end
	local function button(parent,name,text,fn,active,enabled,inspection)
		local b=make("TextButton",parent,{Name=name,Text=text,Size=UDim2.new(1,-4,0,32),BorderSizePixel=0,Font=Enum.Font.BuilderSansMedium,
			TextSize=13,TextTruncate=Enum.TextTruncate.AtEnd,Active=enabled~=false,Selectable=enabled~=false,AutoButtonColor=false,TextTransparency=enabled==false and 0.5 or 0})
		make("UICorner",b,{CornerRadius=UDim.new(0,6)})
		local border=make("UIStroke",b,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Thickness=1,Transparency=active and 1 or 0})
		paint(border,"Color","border")
		local role=active and "accent" or "field"
		paint(b,"BackgroundColor3",role); paint(b,"TextColor3",active and "onAccent" or "text")
		local function resting() paint(b,"BackgroundColor3",b:GetAttribute("SurfaceRole") or role); b.BackgroundTransparency=b:GetAttribute("RestTransparency") or 0 end
		b.MouseEnter:Connect(function() if b.Active then b.BackgroundTransparency=0; paint(b,"BackgroundColor3",active and "accent" or "hover") end end)
		b.MouseLeave:Connect(resting)
		b.MouseButton1Down:Connect(function() if b.Active then paint(b,"BackgroundColor3",active and "selected" or "pressed") end end)
		b.MouseButton1Up:Connect(resting)
		b.Activated:Connect(act(function() if b.Active then fn() end end,inspection))
		if text~="" then tip(b,text) end
		return b
	end
	local function row(parent,count)
		local r=make("Frame",parent,{Size=UDim2.new(1,-4,0,32),BackgroundTransparency=1})
		make("UIGridLayout",r,{CellSize=UDim2.new(1/count,-4,1,0),CellPadding=UDim2.fromOffset(4,0),SortOrder=Enum.SortOrder.LayoutOrder}); return r
	end
	local function toggle(parent,name,text,value,setter)
		local b=button(parent,name,"",function() setter(not value) end); b.BackgroundTransparency=1; b:SetAttribute("RestTransparency",1); b.UIStroke.Transparency=1
		local box=make("Frame",b,{Name="Checkbox",Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(16,16),BorderSizePixel=0})
		paint(box,"BackgroundColor3",value and "accent" or "bg"); local stroke=make("UIStroke",box,{}); paint(stroke,"Color","border")
		local mark=label(box,"Check",value and utf8.char(0x2713) or "","onAccent",16); mark.TextXAlignment=Enum.TextXAlignment.Center
		local caption=label(b,"Caption",text,"text",24); caption.Position=UDim2.fromOffset(32,5); caption.Size=UDim2.new(1,-40,0,24)
		tip(b,text); return b
	end
	local function heading(parent,name,text)
		local l=label(parent,name,text,"text",24); l.TextSize=16; l.Font=Enum.Font.BuilderSansBold; return l
	end
	local function section(parent,text)
		local l=label(parent,"Section",text,"muted",24); l.TextSize=12; l.TextYAlignment=Enum.TextYAlignment.Bottom; l.Font=Enum.Font.BuilderSansMedium; return l
	end
	local function separator(parent)
		local f=make("Frame",parent,{Size=UDim2.new(1,-4,0,1),BorderSizePixel=0}); paint(f,"BackgroundColor3","border")
	end
	local function entry(parent,name,titleText,meta,selected,fn,marker)
		local b=button(parent,name,"",fn,false,true,true); b.Size=UDim2.new(1,-4,0,54); b.BackgroundTransparency=selected and 0 or 1
		b:SetAttribute("SurfaceRole",selected and "selected" or "surface"); b:SetAttribute("RestTransparency",selected and 0 or 1)
		paint(b,"BackgroundColor3",selected and "selected" or "surface")
		b.UIStroke.Transparency=selected and 0 or 1; paint(b.UIStroke,"Color","selectedBorder")
		local stripe=make("Frame",b,{Size=UDim2.fromOffset(3,34),Position=UDim2.fromOffset(0,10),BorderSizePixel=0,Visible=selected or marker~=nil}); paint(stripe,"BackgroundColor3",marker==false and "warning" or "note")
		local t=label(b,"Identity",titleText,"text",20); t.Position=UDim2.fromOffset(10,7); t.Size=UDim2.new(1,-20,0,20); t.Font=Enum.Font.BuilderSansBold
		local m=label(b,"Metadata",meta,"muted",18); m.Position=UDim2.fromOffset(10,30); m.Size=UDim2.new(1,-20,0,18); m.TextSize=12
		tip(b,titleText.."\n"..meta)
		return b
	end
	local function errorFor(part,key)
		local s=Schema.new(); s.tag="Validation"; s.fields={}; s.children={}
		if part=="field" then s.fields={Schema.copy(state.schema.fields[state.fieldIndex])}
		elseif part=="child" then s.children={Schema.copy(state.schema.children[state.childIndex])}
		else s[key]=state.schema[key] end
		local ok,err=pcall(Schema.validate,s); return ok and "" or cleanError(err)
	end
	local function input(parent,name,titleText,value,setter,validator)
		local group=make("Frame",parent,{Name=name.."Group",Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1}); stack(group,4)
		parent=group
		label(parent,name.."Label",titleText,"muted")
		local owner=(name=="SchemaName" or name=="TargetTag" or name=="requiredTags" or name=="forbiddenTags") and "schema"
			or state.childMode and ("child:"..state.childIndex) or ("field:"..state.fieldIndex)
		local key=owner..":"..name
		local box=make("TextBox",parent,{Name=name,Text=state.drafts[key] or (value==nil and "" or tostring(value)),Size=UDim2.new(1,-4,0,32),
			ClearTextOnFocus=false,BorderSizePixel=0,Font=Enum.Font.BuilderSans,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
		inputOwners[box]=owner=="schema" and state.schema or state.childMode and state.schema.children[state.childIndex] or state.schema.fields[state.fieldIndex]
		paint(box,"BackgroundColor3","field"); paint(box,"TextColor3","text"); padding(box,6)
		make("UICorner",box,{CornerRadius=UDim.new(0,6)})
		local stroke=make("UIStroke",box,{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Thickness=1}); paint(stroke,"Color","border")
		box.Focused:Connect(function() paint(stroke,"Color","note") end)
		box.FocusLost:Connect(function() paint(stroke,"Color","border") end)
		local errorText=label(parent,name.."Error","","error")
		local function validate()
			local ok,err=pcall(function() return validator and validator() or "" end)
			err=ok and err or cleanError(err); errorText.Text=err; errorText.Visible=err~=""
		end
		table.insert(validation,validate); validate()
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if rendering then return end
			state.drafts[key]=box.Text; setter(box.Text); changed()
			for _,check in ipairs(validation) do check() end
		end)
		return box
	end
	local function menu(parent,name,titleText,options,value,setter)
		local b=button(parent,name,titleText..": "..tostring(value),function() state.menu=state.menu==name and nil or name end)
		b.TextXAlignment=Enum.TextXAlignment.Left; padding(b,8)
		local arrow=make("ImageLabel",b,{Name="MenuArrow",BackgroundTransparency=1,Image="rbxasset://textures/DevConsole/ArrowDown.png",
			Position=UDim2.new(1,-12,0.5,-4),Size=UDim2.fromOffset(8,8)})
		paint(arrow,"ImageColor3","text")
		if state.menu==name then
			local popup=make("ScrollingFrame",root,{Name="MenuPopup",Size=UDim2.fromOffset(180,math.min(192,#options*36+8)),ZIndex=30,
				BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3})
			paint(popup,"BackgroundColor3","raised"); padding(popup,4); stack(popup,4)
			local stroke=make("UIStroke",popup,{}); paint(stroke,"Color","border")
			for i,choice in ipairs(options) do
				local option=button(popup,name.."Option"..i,choice,function() state.menu=nil; setter(choice,i) end)
				option.ZIndex=31; option.UIStroke.Transparency=1; paint(option,"BackgroundColor3",choice==value and "selected" or "raised")
			end
			task.defer(function()
				if not b.Parent or not popup.Parent then return end
				local width=math.min(root.AbsoluteSize.X-24,math.max(180,b.AbsoluteSize.X))
				local x=math.clamp(b.AbsolutePosition.X-root.AbsolutePosition.X,12,root.AbsoluteSize.X-width-12)
				local y=math.clamp(b.AbsolutePosition.Y-root.AbsolutePosition.Y+b.AbsoluteSize.Y+4,8,root.AbsoluteSize.Y-popup.AbsoluteSize.Y-8)
				popup.Size=UDim2.fromOffset(width,popup.AbsoluteSize.Y); popup.Position=UDim2.fromOffset(x,y)
			end)
		end
	end
	local function pairedInputs(parent)
		local pair=make("Frame",parent,{Name="PairedInputs",Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
		make("UIListLayout",pair,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Top})
		local columns={}
		for i=1,2 do
			columns[i]=make("Frame",pair,{Size=UDim2.new(0.5,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1}); stack(columns[i],4)
		end
		return columns
	end
	local function loadDraft(s,token)
		state.schema=s; state.token=token; state.loadedName=token and s.name or nil; state.dirty=false
		state.fieldIndex=1; state.childIndex=1; state.childMode=false; state.contract=#s.fields==0; state.detail=false
		state.drafts={}; state.scrolls={}; state.resetScroll=true; state.menu=nil; state.tab="Rules"; invalidate()
	end
	local function replaceDraft(fn)
		if state.dirty then state.confirm={title="Discard unsaved schema edits?",fn=fn} else fn() end
	end
	local function capture()
		replaceDraft(function()
			local selected=selection:Get(); assert(#selected==1 and Engine.allowed(selected[1]),"Select exactly one project reference")
			local s,skipped=Schema.capture(selected[1]); loadDraft(s); state.dirty=true
			state.message="Reference captured. "..skipped.." unsupported attributes skipped."
		end)
	end
	local function runAudit()
		local roots=state.scope=="Workspace" and {workspace} or selection:Get()
		state.audit=Engine.audit(state.schema,roots); state.plan=nil; state.stale=nil; state.page=1; state.picked={}
		state.reason="All"; state.field=""; state.subsetActive=false; state.message="Audit complete. Project unchanged."
		state.finding=nil; state.detail=false
	end
	local function visibleIssues()
		return state.audit and Engine.filteredIssues(state.audit,state.reason,state.field) or {}
	end
	local function subset()
		local visible=visibleIssues(); local picked={}
		for _,issue in ipairs(visible) do if state.picked[issue] then table.insert(picked,issue) end end
		return state.subsetActive and picked or visible
	end
	local function selectIssues(issues)
		local objects,seen={},{}
		for _,i in ipairs(issues) do if Engine.allowed(i.instance) and not seen[i.instance] then seen[i.instance]=true; table.insert(objects,i.instance) end end
		state.inspectionSelection=objects; selection:Set(objects); state.message=#objects.." affected objects selected."
	end
	local function rules()
		if state.contract then
		heading(body,"EditorTitle","Contract settings")
		input(body,"SchemaName","Schema name",state.schema.name,function(v) state.schema.name=v end,function() return errorFor("schema","name") end)
		input(body,"TargetTag","Target tag (exact)",state.schema.tag,function(v) state.schema.tag=v end,function() return errorFor("schema","tag") end)
		for _,key in ipairs({"requiredTags","forbiddenTags"}) do
			input(body,key,key=="requiredTags" and "Required tags (comma-separated)" or "Forbidden tags (comma-separated)",table.concat(state.schema[key] or {},","),function(v)
				state.schema[key]={}; if v~="" then for _,part in ipairs(string.split(v,",")) do table.insert(state.schema[key],part:match("^%s*(.-)%s*$")) end end
			end,function()
				local s=Schema.new(); s.tag=state.schema.tag; s.requiredTags=state.schema.requiredTags; s.forbiddenTags=state.schema.forbiddenTags
				local ok,err=pcall(Schema.validate,s); return ok and "" or cleanError(err)
			end)
		end
		menu(body,"ExpectedClass","Expected class",Schema.classes,state.schema.className,function(v) state.schema.className=v; changed() end)
		return
		end
		if state.childMode then
			local c=state.schema.children[state.childIndex]
			if c then
				label(body,"EditorKind","CHILD RULE","muted",18); heading(body,"EditorTitle",c.path)
				input(body,"ChildPath","Child path / nested child",c.path,function(v) c.path=v end,function()
					local count=0; for _,other in ipairs(state.schema.children) do if other.path==c.path then count+=1 end end
					if count>1 then return "Duplicate child path: "..c.path end
					return errorFor("child")
				end)
				menu(body,"ChildClass","Class",Schema.classes,c.className,function(v) c.className=v; changed() end)
				toggle(body,"OptionalChild","Optional if absent",c.optional==true,function(v) c.optional=v; changed() end)
				input(body,"ChildDescription","Designer note",c.description,function(v) c.description=v end,function() return #c.description>240 and "At most 240 characters." or "" end)
				separator(body)
				local remove=button(body,"RemoveChild","Remove child rule",function() state.confirm={title="Remove this child rule?",fn=function() table.remove(state.schema.children,state.childIndex); state.childIndex=math.max(1,state.childIndex-1); state.drafts={}; state.detail=false; changed() end} end)
				paint(remove,"TextColor3","error")
			end
		else
			local f=state.schema.fields[state.fieldIndex]
			if f then
				label(body,"EditorKind","ATTRIBUTE RULE","muted",18); heading(body,"EditorTitle",f.name)
				section(body,"IDENTITY")
				input(body,"FieldName","Attribute name",f.name,function(v) f.name=v end,function()
					local count=0; for _,other in ipairs(state.schema.fields) do if other.name==f.name then count+=1 end end
					if count>1 then return "Duplicate attribute: "..f.name end
					return errorFor("field")
				end)
				menu(body,"FieldType","Type",Schema.kinds,f.kind,function(v)
					f.kind=v; f.min=nil; f.max=nil; f.integer=false; f.choices={}; f.hasDefault=false
					f.exact=nil; f.axisMin=nil; f.axisMax=nil; f.magnitudeMin=nil; f.magnitudeMax=nil
					f.default=Schema.initialValue(v); state.drafts={}; changed()
				end)
				toggle(body,"Required","Required",f.required,function(v) f.required=v; changed() end)
				section(body,"CONSTRAINTS")
				if f.kind=="number" then
					local pair=pairedInputs(body)
					for i,key in ipairs({"min","max"}) do
						input(pair[i],key,key=="min" and "Min" or "Max",f[key],function(v) f[key]=v~="" and (tonumber(v) or v) or nil end,function()
							if f[key]~=nil and (type(f[key])~="number" or f[key]~=f[key] or math.abs(f[key])==math.huge) then return "Enter a finite number or leave blank." end
							if type(f.min)=="number" and type(f.max)=="number" and f.min>f.max then return "Minimum exceeds maximum." end
							return ""
						end)
					end
					toggle(body,"Integer","Integer only",f.integer,function(v) f.integer=v; changed() end)
				elseif f.kind=="string" then
					input(body,"Choices","Allowed choices (comma-separated)",table.concat(f.choices,","),function(v)
						f.choices={}; if v~="" then for _,part in ipairs(string.split(v,",")) do table.insert(f.choices,part:match("^%s*(.-)%s*$")) end end
					end,function() return errorFor("field") end)
				elseif f.kind=="Vector2" or f.kind=="Vector3" then
					for _,axis in ipairs(f.kind=="Vector2" and {"X","Y"} or {"X","Y","Z"}) do
						local pair=pairedInputs(body)
						for i,bound in ipairs({"axisMin","axisMax"}) do
							input(pair[i],bound..axis,axis..(bound=="axisMin" and " min" or " max"),f[bound] and f[bound][axis],function(v)
								f[bound]=f[bound] or {}; f[bound][axis]=v~="" and (tonumber(v) or v) or nil
							end,function() return errorFor("field") end)
						end
					end
					label(body,"MagnitudeCaption","Magnitude","muted",18)
					local pair=pairedInputs(body)
					for i,key in ipairs({"magnitudeMin","magnitudeMax"}) do
						input(pair[i],key,key=="magnitudeMin" and "Min" or "Max",f[key],function(v) f[key]=v~="" and (tonumber(v) or v) or nil end,function() return errorFor("field") end)
					end
				end
				if f.kind~="number" and f.kind~="string" and f.kind~="boolean" then
					toggle(body,"UseExact","Require exact value",f.exact~=nil,function(v) f.exact=v and (typeof(f.default)==f.kind and f.default or Schema.initialValue(f.kind)) or nil; changed() end)
					if f.exact~=nil then
						input(body,"ExactValue","Exact components (comma-separated)",Schema.editValue(f.exact),function(v)
							local ok,value=pcall(Schema.parseValue,f.kind,v); f.exact=ok and value or v
						end,function() return errorFor("field") end)
					end
				end
				section(body,"SAFE REPAIR")
				toggle(body,"UseDefault","Repair missing",f.hasDefault,function(v) f.hasDefault=v; changed() end)
				if f.hasDefault then
					if f.kind=="boolean" then toggle(body,"DefaultBoolean","Default: true",f.default==true,function(v) f.default=v; changed() end)
					else input(body,"DefaultValue",Schema.components(f.default) and "Default components (comma-separated)" or "Default value",Schema.editValue(f.default),function(v)
						local ok,value=pcall(Schema.parseValue,f.kind,v); f.default=ok and value or v
					end,function()
						local ok,err=pcall(Schema.valueError,f,f.default)
						return not ok and "Fix the rule bounds first." or err or ""
					end) end
				end
				section(body,"DESIGNER NOTE")
				input(body,"FieldDescription","Note",f.description,function(v) f.description=v end,function() return #f.description>240 and "At most 240 characters." or "" end)
				separator(body)
				local remove=button(body,"RemoveField","Remove attribute rule",function() state.confirm={title="Remove this attribute rule?",fn=function() table.remove(state.schema.fields,state.fieldIndex); state.fieldIndex=math.max(1,state.fieldIndex-1); state.drafts={}; state.detail=false; changed() end} end)
				paint(remove,"TextColor3","error")
			end
		end
	end
	local function ruleCollection()
		heading(collection,"RulesTitle","Rules")
		entry(collection,"ContractSettings","Contract settings","Tag, class & tag rules",state.contract,function() state.contract=true; state.detail=true; state.menu=nil end)
		if #state.schema.fields==0 and #state.schema.children==0 then
			label(collection,"EmptyHint","Capture one configured reference to start.","muted")
			button(collection,"Capture","Capture reference",capture)
		end
		section(collection,"ATTRIBUTES  /  "..#state.schema.fields)
		for i,f in ipairs(state.schema.fields) do
			entry(collection,"RuleField"..i,f.name,f.kind..(f.required and " / required" or " / optional"),not state.contract and not state.childMode and state.fieldIndex==i,function()
				state.contract=false; state.childMode=false; state.fieldIndex=i; state.detail=true; state.menu=nil
			end)
		end
		button(collection,"AddField","+ Attribute",function()
			assert(#state.schema.fields<32,"Limit: 32 attribute rules")
			table.insert(state.schema.fields,{name="Attribute"..(#state.schema.fields+1),kind="number",required=true,hasDefault=false,default=0,integer=false,choices={},description=""})
			state.fieldIndex=#state.schema.fields; state.contract=false; state.childMode=false; state.detail=true; state.drafts={}; changed()
		end,false,#state.schema.fields<32)
		section(collection,"CHILDREN  /  "..#state.schema.children)
		for i,c in ipairs(state.schema.children) do
			entry(collection,"RuleChild"..i,c.path,c.className..(c.optional and " / optional" or " / required"),not state.contract and state.childMode and state.childIndex==i,function()
				state.contract=false; state.childMode=true; state.childIndex=i; state.detail=true; state.menu=nil
			end)
		end
		button(collection,"AddChild","+ Child",function()
			assert(#state.schema.children<32,"Limit: 32 child rules")
			table.insert(state.schema.children,{path="Child"..(#state.schema.children+1),className="Instance",description=""})
			state.childIndex=#state.schema.children; state.contract=false; state.childMode=true; state.detail=true; state.drafts={}; changed()
		end,false,#state.schema.children<32)
	end
	local function pages(parent,items,draw)
		local count=math.max(1,math.ceil(#items/30)); state.page=math.min(state.page,count)
		for i=(state.page-1)*30+1,math.min(state.page*30,#items) do draw(items[i],i) end
		if count>1 then
			local r=row(parent,3)
			button(r,"Previous",utf8.char(0x2190),function() state.page=math.max(1,state.page-1) end)
			label(r,"Page",state.page.." / "..count,"muted",32)
			button(r,"Next",utf8.char(0x2192),function() state.page=math.min(count,state.page+1) end)
		end
	end
	local function diff(parent,expected,actual)
		local frame=make("Frame",parent,{Name="ExpectedActual",Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0})
		frame.BackgroundTransparency=1
		make("UIListLayout",frame,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
		for i,item in ipairs({{"Expected",expected,"text"},{"Actual",actual,"error"}}) do
			local cell=make("Frame",frame,{Name=item[1].."Cell",LayoutOrder=i,Size=UDim2.new(0.5,-4,0,96),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0})
			paint(cell,"BackgroundColor3","surface"); make("UICorner",cell,{CornerRadius=UDim.new(0,6)})
			local stroke=make("UIStroke",cell,{}); paint(stroke,"Color","border"); padding(cell,8); stack(cell,8)
			local caption=label(cell,item[1].."Label",string.upper(item[1]),"muted",18); caption.TextSize=11
			local value=label(cell,item[1],item[2],item[3]); value.TextSize=15; value.Font=Enum.Font.BuilderSansBold
		end
	end
	local function findingDetail()
		local finding=state.finding
		if not finding then heading(body,"DetailTitle","Finding detail"); label(body,"DetailEmpty","No finding selected.","muted"); return end
		local category=label(body,"FindingCategory",string.upper(finding.category)..(finding.fix and " / FIXABLE" or " / DIAGNOSTIC"),finding.fix and "note" or "warning"); category.TextSize=11
		local name=heading(body,"DetailTitle",finding.field); name.TextSize=18
		label(body,"FindingIdentity",finding.identity,"muted")
		local path=label(body,"FindingPath",finding.path,"muted",18); path.TextSize=12; tip(path)
		diff(body,finding.expected,finding.actual)
		if finding.description~="" then
			separator(body); label(body,"NoteCaption","Designer note","muted",18)
			local note=label(body,"DesignerNote",finding.description,"muted",56); note.TextWrapped=true; tip(note)
		end
		if finding.fix and not state.stale then
			-- Inspection presents the recorded finding; only explicit Preview creates a plan.
			local fix=finding.fix
			local repair=make("Frame",body,{Name="SafeRepair",Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0})
			paint(repair,"BackgroundColor3","repair"); make("UICorner",repair,{CornerRadius=UDim.new(0,6)}); padding(repair,10); stack(repair,6)
			local stroke=make("UIStroke",repair,{}); paint(stroke,"Color","selectedBorder")
			local caption=label(repair,"RepairCaption","SUGGESTED REPAIR","note",18); caption.TextSize=11
			local operation=label(repair,"SuggestedRepair",finding.field.."\nMissing "..utf8.char(0x2192).." "..(fix.action=="tag" and "Add tag" or Schema.formatValue(fix.value)),"text")
			operation.Font=Enum.Font.BuilderSansBold; operation.TextSize=14
			label(repair,"RepairSafety","Safe / additive only","muted",18).TextSize=12
		elseif not finding.fix then label(body,"DiagnosticOnly","No automatic repair.","muted") end
		button(body,"SelectFinding","Select in Studio",function() assert(Engine.allowed(finding.instance),"Object was removed. Audit again."); selectIssues({finding}) end)
	end
	local function findings()
		heading(collection,"AuditTitle","Findings")
		if state.audit then label(collection,"AuditSummary",string.format("%d checked / %d findings",state.audit.matched,#state.audit.issues),"muted",18).TextSize=12 end
		local scopes=row(collection,2)
		for _,scope in ipairs({"Selection","Workspace"}) do
			local b=button(scopes,"Scope"..scope,scope,function()
				local previousPlan=state.plan; state.scope=scope; invalidate()
				if previousPlan then state.plan=previousPlan; state.stale="Scope changed. Audit and preview again." end
			end)
			b.TextSize=12; b:SetAttribute("SurfaceRole",state.scope==scope and "selected" or "surface")
			paint(b,"BackgroundColor3",state.scope==scope and "selected" or "surface"); paint(b,"TextColor3",state.scope==scope and "note" or "muted")
		end
		if not state.audit then label(collection,"AuditHint","No audit for this scope.","muted"); findingDetail(); return end
		local a=state.audit
		if root.AbsoluteSize.X<280 then button(collection,"Filters",(state.filters and "Hide filters" or "Filters")..((state.reason~="All" or state.field~="") and " / active" or ""),function() state.filters=not state.filters; state.menu=nil end) end
		local values={}; for _,i in ipairs(a.issues) do if not table.find(values,i.field) then table.insert(values,i.field) end end
		local fields={"All fields"}; for _,value in ipairs(values) do table.insert(fields,value) end
		if root.AbsoluteSize.X>=280 or state.filters then
			menu(collection,"ReasonFilter","Reason",{"All","Missing","Wrong type","Invalid value","Required child","Required tag","Forbidden tag","Class"},state.reason,function(v) state.reason=v; state.page=1; subsetChanged(); state.finding=nil end)
			menu(collection,"FieldFilter","Field",fields,state.field=="" and "All fields" or state.field,function(_,i) state.field=i==1 and "" or values[i-1]; state.page=1; subsetChanged(); state.finding=nil end)
		end
		local visible=visibleIssues(); local chosen=subset()
		local ordered={}; for _,i in ipairs(visible) do if i.fix then table.insert(ordered,i) end end
		for _,i in ipairs(visible) do if not i.fix then table.insert(ordered,i) end end
		if not table.find(visible,state.finding) then state.finding=ordered[1] end
		local objects={}; for _,i in ipairs(chosen) do objects[i.instance]=true end
		local objectCount=0; for _ in pairs(objects) do objectCount+=1 end
		label(collection,"SubsetSummary",#chosen.." / "..#visible.." included","muted",18)
		pages(collection,ordered,function(finding,i)
			local item=make("Frame",collection,{Name="Finding"..i,Size=UDim2.new(1,-4,0,54),BackgroundTransparency=1})
			local included=not state.subsetActive or state.picked[finding]==true
			local pick=button(item,"Pick"..i,included and utf8.char(0x2713) or "",function()
				if not state.subsetActive then for _,shown in ipairs(visible) do state.picked[shown]=true end end
				state.picked[finding]=not included or nil; state.subsetActive=true; subsetChanged()
			end)
			pick.Position=UDim2.new(1,-28,0,0); pick.Size=UDim2.fromOffset(28,28); pick.BackgroundTransparency=1; pick:SetAttribute("RestTransparency",1); pick.UIStroke.Transparency=1
			paint(pick,"TextColor3",included and "note" or "muted"); tip(pick,"Include "..finding.field.." / "..finding.identity)
			local b=entry(item,"OpenFinding"..i,finding.field,finding.identity.." / "..finding.category,state.finding==finding,function() state.finding=finding; state.detail=true end,finding.fix~=nil)
			b.Position=UDim2.fromOffset(0,0); b.Size=UDim2.fromScale(1,1); b.Identity.Size=UDim2.new(1,-40,0,20)
			pick.ZIndex=3
		end)
		if #visible==0 then label(collection,"NoFindings",#a.issues==0 and "No contract findings." or "No findings match these filters.","muted") end
		separator(collection)
		button(collection,"SelectFindings","Select affected ("..objectCount..")",function() selectIssues(chosen) end,false,#chosen>0)
		button(collection,"ClearSubset","Include all shown",function() state.picked={}; state.subsetActive=false; subsetChanged() end,false,state.subsetActive==true)
		findingDetail()
	end
	local function repairs()
		heading(collection,"RepairTitle","Repair preview")
		if not state.plan then label(collection,"RepairHint",state.stale or "No current repair plan.","muted"); return end
		local plan=state.plan; local seen={}; for _,c in ipairs(plan.changes) do seen[c.instance]=true end
		local n=0; for _ in pairs(seen) do n+=1 end
		label(collection,"RepairSummary",#plan.changes.." additions / "..n.." objects","note")
		label(collection,"PlanScope",(state.planScope or state.scope).." / #"..plan.schema.tag,"muted")
		pages(collection,plan.changes,function(c,i)
			entry(collection,"Repair"..i,c.name,c.identity,state.repairIndex==i,function() state.repairIndex=i; state.detail=true end,true)
		end)
		local c=plan.changes[state.repairIndex or 1]
		if not c then label(body,"NoAdditions","This subset has no safe additions.","muted"); return end
		heading(body,"ChangeTitle",c.name)
		label(body,"ChangeIdentity",c.identity)
		local p=label(body,"ChangePath",c.path,"muted"); p.TextSize=12
		section(body,"EXACT PLANNED ADDITION")
		diff(body,c.action=="tag" and "Tag present" or Schema.formatValue(c.value),"Missing")
		label(body,"Preservation","Existing values and children stay unchanged. Tags are only added.","muted")
	end
	local function libraryList(parent,compact)
		local ok,names=pcall(Store.list)
		if not ok then label(parent,"LibraryError",cleanError(names),"error")
		elseif #names==0 then label(parent,"NoSchemas","No saved contracts.","muted")
		else for _,name in ipairs(names) do
			local fn=function() state.libraryName=name; state.tab="Library"; state.detail=true; state.menu=nil end
			if compact then
				local b=button(parent,"LibraryEntry"..name,name,fn,false,true,true); b.TextXAlignment=Enum.TextXAlignment.Left; b.TextSize=12; padding(b,4)
				local selected=state.libraryName==name or state.loadedName==name
				b.UIStroke.Transparency=1; b.BackgroundTransparency=selected and 0 or 1; b:SetAttribute("RestTransparency",selected and 0 or 1)
				b:SetAttribute("SurfaceRole",selected and "selected" or "surface")
				paint(b,"BackgroundColor3",selected and "selected" or "surface"); paint(b,"TextColor3",selected and "note" or "muted")
			else entry(parent,"LibraryEntry"..name,name,state.loadedName==name and "Loaded contract" or "Project contract",state.libraryName==name,fn) end
		end end
	end
	local function library()
		heading(collection,"LibraryTitle","Project library"); libraryList(collection,false)
		if not state.libraryName then state.libraryName=state.loadedName end
		if not state.libraryName then heading(body,"LibraryDetail","Contract library"); label(body,"LibraryHint","Choose a saved contract or capture a reference.","muted"); return end
		local ok,s=pcall(Store.load,state.libraryName)
		if not ok then label(body,"LibraryError",cleanError(s),"error"); return end
		heading(body,"LibraryDetail",s.name)
		label(body,"LibraryTag","#"..s.tag.." / "..s.className,"note")
		label(body,"LibraryCounts",#s.fields.." attributes / "..#s.children.." children","muted")
		label(body,"LibraryTags",#(s.requiredTags or {}).." required tags / "..#(s.forbiddenTags or {}).." forbidden tags","muted")
		button(body,"Load","Load contract",function() replaceDraft(function() local loaded,token=Store.load(state.libraryName); loadDraft(loaded,token); state.message="Loaded project contract." end) end)
		if state.loadedName==s.name then
			separator(body)
			local b=button(body,"Delete","Delete saved contract",function() state.confirm={title="Delete saved contract "..state.loadedName.."?",fn=function() Store.delete(state.loadedName,state.token,history); state.libraryName=nil; loadDraft(Schema.new()); state.message="Deleted. Native Undo available." end} end)
			paint(b,"TextColor3","error")
		end
	end
	local tabs={}
	local function navigate(name) state.tab=name; state.menu=nil; state.page=1; state.detail=false end
	for _,name in ipairs({"Rules","Audit","Repairs","Library"}) do
		tabs[name]=button(nav,"Tab"..name,name,function() navigate(name) end); tabs[name].TextSize=12
	end
	local function enabled(b,value)
		b.Active=value; b.Selectable=value; b.TextTransparency=value and 0 or 0.5
	end
	refresh=function()
		context.Text=state.schema.name~="" and state.schema.name or "Untitled contract"
		local roots=state.audit and state.audit.roots or selection:Get()
		scopeText.Text=state.scope=="Workspace" and "Workspace" or "Selection ("..#roots..")"
		tag.Text="#"..(state.schema.tag~="" and state.schema.tag or "No target tag").." / "..state.schema.className.." / "..scopeText.Text
		status.Text=state.stale and "Stale" or state.failed and "Blocked" or state.dirty and "Unsaved" or state.plan and "Ready" or state.success or state.loadedName and "Saved" or "Draft"
		paint(status,"TextColor3",(state.stale or state.failed) and "error" or state.plan and "note" or "muted")
		local safe=0; for _,finding in ipairs(subset()) do if finding.fix then safe+=1 end end
		message.Text=state.stale or (state.failed and state.message) or (state.tab=="Audit" and state.audit and (safe.." safe additions selected")) or (state.message~="" and state.message) or "Project contract / 1.2.0"
		paint(message,"TextColor3",(state.stale or state.failed) and "error" or "muted")
		local repair=body:FindFirstChild("SafeRepair"); if repair then repair.Visible=not state.stale end
		local save=actions:FindFirstChild("Save",true)
		if save then local valid=pcall(Schema.validate,state.schema); enabled(save,valid and not state.stale); save.Text=state.dirty and "Save edits" or "Save contract" end
		for _,name in ipairs({"Apply","PrepareFixes"}) do
			local b=actions:FindFirstChild(name,true)
			if b then enabled(b,not state.stale and (name=="Apply" and state.plan~=nil and #state.plan.changes>0 or name=="PrepareFixes" and state.audit~=nil and safe>0)) end
			if b and name=="PrepareFixes" then b.Text=root.AbsoluteSize.X<280 and "Preview "..safe or "Preview changes" end
		end
		for i,f in ipairs(state.schema.fields) do local r=collection:FindFirstChild("RuleField"..i); if r then r.Identity.Text=f.name end end
		for i,c in ipairs(state.schema.children) do local r=collection:FindFirstChild("RuleChild"..i); if r then r.Identity.Text=c.path end end
		for name,b in pairs(tabs) do
			paint(b,"BackgroundColor3",state.tab==name and "selected" or "surface"); paint(b,"TextColor3",state.tab==name and "note" or "text"); enabled(b,not state.confirm)
		end
	end
	local function layout()
		wide=root.AbsoluteSize.X>=560; nav.Visible=not wide
		local top=wide and 68 or 104
		header.Size=UDim2.new(1,0,0,top)
		workspaceUI.Position=UDim2.fromOffset(12,top+10); workspaceUI.Size=UDim2.new(1,-24,1,-top-82)
		rail.Visible=wide and not state.confirm; rail.Position=UDim2.new(); rail.Size=UDim2.new(0,124,1,0)
		collection.Visible=not state.confirm and (wide or not state.detail)
		body.Visible=state.confirm~=nil or wide or state.detail
		if wide and not state.confirm then
			local listWidth=186+math.floor(math.max(0,root.AbsoluteSize.X-560)*0.35)
			collection.Position=UDim2.fromOffset(132,0); collection.Size=UDim2.new(0,listWidth,1,0)
			body.Position=UDim2.fromOffset(140+listWidth,0); body.Size=UDim2.new(1,-140-listWidth,1,0)
		else
			collection.Position=UDim2.new(); collection.Size=UDim2.fromScale(1,1)
			body.Position=UDim2.new(); body.Size=UDim2.fromScale(1,1)
		end
		message.Position=wide and UDim2.fromOffset(132,12) or UDim2.fromOffset(0,3)
		message.Size=wide and UDim2.new(1,-284,0,38) or UDim2.new(1,0,0,18); message.TextWrapped=wide
		actions.Position=UDim2.fromOffset(0,wide and 14 or 24)
	end
	local function footerButton(name,text,fn,primary,available)
		local b=button(actions,name,text,fn,primary,available)
		local width=root.AbsoluteSize.X<280 and 112 or 144
		b.Position=primary and UDim2.new(1,-width,0,0) or UDim2.new()
		b.Size=primary and UDim2.new(0,width,1,0) or UDim2.new(0,wide and 124 or 84,1,0)
		return b
	end
	local function preview()
		assert(not state.stale,"Scope or values changed. Audit again.")
		state.plan=Engine.preview(state.audit,subset()); state.planScope=state.scope; state.tab="Repairs"; state.page=1; state.repairIndex=1; state.detail=false; state.planSelection=selection:Get()
		state.message=#state.plan.changes.." safe additions. Preview is read-only."
	end
	local function apply()
		assert(not state.stale and sameSelection(state.planSelection,selection:Get()),"Selection changed. Preview again.")
		if state.loadedName then
			local _,token=Store.load(state.loadedName)
			assert(token==state.token,"Saved schema changed. Reload and audit again.")
		end
		local count=Engine.apply(state.plan,history); invalidate(); state.detail=false
		state.message=count.." additions applied. Native Undo available."; state.success="Applied"
	end
	local function scrollKey()
		return state.tab..":"..(state.tab=="Rules" and (state.contract and "contract" or state.childMode and "child"..state.childIndex or "field"..state.fieldIndex)
			or state.tab=="Audit" and tostring(state.finding) or state.tab=="Repairs" and tostring(state.repairIndex) or tostring(state.libraryName))
	end
	local renderedTab,renderedKey,renderedConfirmation
	render=function()
		if disposed then return end
		if rendering then task.defer(render); return end
		renderGeneration+=1; local generation=renderGeneration
		-- DockWidget text focus is separate from the main viewport input service.
		local focus
		for _,obj in ipairs(body:GetDescendants()) do
			if obj:IsA("TextBox") and obj:IsFocused() then focus=obj; break end
		end
		local focusName,focusOwner,cursor,selectionStart
		if focus then focusName=focus.Name; focusOwner=inputOwners[focus]; cursor=focus.CursorPosition; selectionStart=focus.SelectionStart end
		if renderedTab and not renderedConfirmation and not state.resetScroll then
			state.scrolls[renderedTab..":list"]=collection.CanvasPosition; state.scrolls[renderedKey]=body.CanvasPosition
		end
		state.resetScroll=nil
		rendering=true; tooltip.Visible=false; validation={}
		local popup=root:FindFirstChild("MenuPopup"); if popup then popup:Destroy() end
		for _,p in ipairs({body,collection,rail}) do
			for _,obj in ipairs(p:GetChildren()) do obj:Destroy() end
			padding(p,8); stack(p,p==rail and 4 or 8)
			local border=make("UIStroke",p,{Thickness=1}); paint(border,"Color","border")
		end
		for _,obj in ipairs(actions:GetChildren()) do obj:Destroy() end
		layout()
		if wide then
			section(rail,"CONTRACT")
			for _,name in ipairs({"Rules","Audit","Repairs","Library"}) do
				local b=button(rail,"Nav"..name,name,function() navigate(name) end,false,not state.confirm)
				b.TextXAlignment=Enum.TextXAlignment.Left; padding(b,8); b:SetAttribute("SurfaceRole",state.tab==name and "selected" or "surface")
				b:SetAttribute("RestTransparency",state.tab==name and 0 or 1); b.BackgroundTransparency=state.tab==name and 0 or 1
				b.UIStroke.Transparency=1
				paint(b,"BackgroundColor3",state.tab==name and "selected" or "surface"); paint(b,"TextColor3",state.tab==name and "note" or "text")
				if state.tab==name then local marker=make("Frame",b,{Position=UDim2.fromOffset(0,7),Size=UDim2.fromOffset(3,18),BorderSizePixel=0}); paint(marker,"BackgroundColor3","note") end
				local count=name=="Rules" and (#state.schema.fields+#state.schema.children) or name=="Audit" and state.audit and #state.audit.issues or name=="Repairs" and state.plan and #state.plan.changes
				if count then local l=label(b,"Count",tostring(count),"muted",18); l.Position=UDim2.new(1,-20,0,7); l.Size=UDim2.fromOffset(16,18); l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Right end
			end
			separator(rail); section(rail,"LIBRARY"); libraryList(rail,true)
		end
		if state.confirm then
			heading(body,"ConfirmationTitle","Confirm change")
			label(body,"Confirmation",state.confirm.title,"error")
			footerButton("Cancel","Cancel",function() state.confirm=nil end,false)
			local confirm=footerButton("Confirm","Confirm",function() local fn=state.confirm.fn; state.confirm=nil; fn() end,true)
			paint(confirm,"BackgroundColor3","error"); paint(confirm,"TextColor3","bg")
		else
			if not wide and state.detail then button(body,"BackToList",utf8.char(0x2190).." "..(state.tab=="Audit" and "Findings" or state.tab),function() state.detail=false; state.menu=nil end) end
			if state.tab=="Rules" then ruleCollection(); rules() elseif state.tab=="Audit" then findings() elseif state.tab=="Repairs" then repairs() else library() end
		end
		if not state.confirm then
			if state.tab=="Rules" then
				footerButton("ToAudit","Audit",function() navigate("Audit") end,false)
				footerButton("Save","Save contract",function()
					local token=state.loadedName==state.schema.name and state.token or nil
					Store.save(state.schema,token,history)
					-- Rebind to the newly saved token before the next engine audit.
					state.schema,state.token=Store.load(state.schema.name); state.loadedName=state.schema.name; state.drafts={}; state.dirty=false; state.message="Saved in this project."
				end,true)
			elseif state.tab=="Audit" then
				if state.audit then footerButton("Audit",wide and "Re-run audit" or "Audit",runAudit,false); footerButton("PrepareFixes","Preview",preview,true)
				else footerButton("ToRules","Rules",function() navigate("Rules") end,false); footerButton("Audit","Run audit",runAudit,true) end
			elseif state.tab=="Repairs" then
				footerButton("ToAudit","Audit",function() navigate("Audit") end,false)
				footerButton("Apply","Apply "..(state.plan and #state.plan.changes or 0),apply,true)
			else
				footerButton("New","New",function() replaceDraft(function() loadDraft(Schema.new()) end) end,false)
				footerButton("Capture","Capture",capture,true)
			end
		end
		renderedTab=state.tab; renderedKey=scrollKey(); renderedConfirmation=state.confirm~=nil; refresh(); rendering=false
		local wanted=state.confirm and Vector2.zero or state.scrolls[renderedKey] or Vector2.zero
		local listWanted=state.scrolls[state.tab..":list"] or Vector2.zero; body.CanvasPosition=wanted; collection.CanvasPosition=listWanted
		task.defer(function()
			game:GetService("RunService").Heartbeat:Wait()
			if disposed or generation~=renderGeneration then return end
			if focusName then
				local replacement=body:FindFirstChild(focusName,true)
				if replacement and replacement:IsA("TextBox") and inputOwners[replacement]==focusOwner then
					replacement:CaptureFocus(); replacement.CursorPosition=cursor; replacement.SelectionStart=selectionStart
				end
			end
			body.CanvasPosition=wanted; collection.CanvasPosition=listWanted
		end)
	end
	local selectionChanged=selection.SelectionChanged:Connect(function()
		if disposed then return end
		local selected=selection:Get(); local inspection=state.inspectionSelection and sameSelection(state.inspectionSelection,selected); state.inspectionSelection=nil
		if state.plan or (state.audit and state.scope=="Selection" and not inspection and not sameSelection(state.audit.roots,selected)) then state.stale="Selection changed. Audit and preview again." end
		refresh()
	end)
	local function historyChanged()
		invalidate(); state.success=nil; state.message="History changed. Run a fresh audit."
		task.defer(function() if not disposed then render() end end)
	end
	local undo=history.OnUndo:Connect(historyChanged); local redo=history.OnRedo:Connect(historyChanged); local themed=studio.ThemeChanged:Connect(theme)
	local resized=root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if (root.AbsoluteSize.X>=560)~=wide then render() else
			layout()
			for _,b in ipairs(actions:GetChildren()) do
				if b:IsA("TextButton") and b.Position.X.Scale==1 then local width=root.AbsoluteSize.X<280 and 112 or 144; b.Size=UDim2.fromOffset(width,34); b.Position=UDim2.new(1,-width,0,0) end
			end
			refresh()
		end
	end)
	render()
	task.spawn(function()
		while not disposed do
			task.wait(1)
			if not disposed and state.audit and not state.stale then
				local ok,fresh=pcall(Engine.isFresh,state.plan or state.audit)
				if state.loadedName then
					local loaded,_,token=pcall(Store.load,state.loadedName)
					fresh=fresh and loaded and token==state.token
				end
				if not ok or not fresh then state.stale="Project changed. Audit and preview again."; refresh() end
			end
		end
	end)
	return function() disposed=true; selectionChanged:Disconnect(); undo:Disconnect(); redo:Disconnect(); themed:Disconnect(); resized:Disconnect(); root:Destroy() end
end
return View
