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
local function cleanError(err) return tostring(err):gsub("^.-:%d+: ", "") end
local function sameSelection(a,b)
	if #a~=#b then return false end
	for _,obj in ipairs(a) do if not table.find(b,obj) then return false end end
	return true
end
function View.mount(widget, selection, history)
	local state={schema=Schema.new(),tab="Rules",scope="Selection",fieldIndex=1,childIndex=1,childMode=false,page=1,
		message="",dirty=false,reason="All",field="",picked={},drafts={},scrolls={}}
	local disposed,rendering=false,false
	local renderGeneration=0
	local inputOwners=setmetatable({}, {__mode="k"})
	local render,refresh
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
		colors.bg=t:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		colors.field=t:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
		colors.text=t:GetColor(Enum.StudioStyleGuideColor.MainText)
		colors.muted=t:GetColor(Enum.StudioStyleGuideColor.SubText)
		colors.border=t:GetColor(Enum.StudioStyleGuideColor.Border)
		colors.accent=Color3.fromRGB(99,214,174); colors.onAccent=Color3.fromRGB(15,45,34)
		local light=colors.bg.R+colors.bg.G+colors.bg.B>1.5
		colors.note=light and Color3.fromRGB(18,105,77) or colors.accent
		colors.error=light and Color3.fromRGB(172,43,43) or Color3.fromRGB(255,153,142)
		for obj,roles in pairs(styles) do for property,role in pairs(roles) do obj[property]=colors[role] end end
	end
	theme()
	local root=make("Frame",widget,{Name="SchemaForgeUI",Size=UDim2.fromScale(1,1),BorderSizePixel=0,ClipsDescendants=true})
	paint(root,"BackgroundColor3","bg")
	local function label(parent,name,text,role,height)
		local obj=make("TextLabel",parent,{Name=name,Text=text,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 18),
			AutomaticSize=height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,Font=Enum.Font.BuilderSans,TextSize=14,
			TextWrapped=not height,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
			TextTruncate=height and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None})
		paint(obj,"TextColor3",role or "text"); return obj
	end
	local tooltip=label(root,"Tooltip","","text")
	tooltip.ZIndex=50; tooltip.Visible=false; tooltip.BackgroundTransparency=0; padding(tooltip,8); paint(tooltip,"BackgroundColor3","field")
	local function tip(obj,text)
		obj.MouseEnter:Connect(function()
			tooltip.Text=text or obj.Text; tooltip.Size=UDim2.new(1,-24,0,24)
			tooltip.Position=UDim2.fromOffset(12,math.clamp(obj.AbsolutePosition.Y-root.AbsolutePosition.Y+obj.AbsoluteSize.Y,8,math.max(8,root.AbsoluteSize.Y-100)))
			tooltip.Visible=true
		end)
		obj.MouseLeave:Connect(function() tooltip.Visible=false end)
	end
	local header=make("Frame",root,{Name="Header",Size=UDim2.new(1,0,0,128),BackgroundTransparency=1})
	local title=label(header,"ProductTitle","SchemaForge","text",24)
	title.Position=UDim2.fromOffset(12,8); title.Size=UDim2.new(1,-104,0,24); title.TextSize=18; title.Font=Enum.Font.BuilderSansBold
	local context=label(header,"ContractName","","text",20); context.Position=UDim2.fromOffset(12,34); context.Size=UDim2.new(1,-24,0,20)
	local tag=label(header,"ContractTag","","note",18); tag.Position=UDim2.fromOffset(12,55); tag.Size=UDim2.new(1,-24,0,18)
	local scopeText=label(header,"AuditScope","","muted",18); scopeText.Position=UDim2.fromOffset(12,74); scopeText.Size=UDim2.new(1,-24,0,18)
	for _,obj in ipairs({context,tag,scopeText}) do tip(obj) end
	local nav=make("Frame",header,{Name="Tabs",Position=UDim2.fromOffset(12,96),Size=UDim2.new(1,-24,0,28),BackgroundTransparency=1})
	make("UIGridLayout",nav,{CellSize=UDim2.new(1/3,-3,1,0),CellPadding=UDim2.fromOffset(4,0),SortOrder=Enum.SortOrder.LayoutOrder})
	local body=make("ScrollingFrame",root,{Name="Body",Position=UDim2.fromOffset(12,132),Size=UDim2.new(1,-24,1,-236),BackgroundTransparency=1,
		BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=4,ClipsDescendants=true})
	local footer=make("Frame",root,{Name="Footer",Position=UDim2.new(0,12,1,-100),Size=UDim2.new(1,-24,0,96),BackgroundTransparency=1})
	local actions=make("Frame",footer,{Name="Actions",Size=UDim2.new(1,0,0,32),BackgroundTransparency=1})
	local feedback=make("ScrollingFrame",footer,{Name="Feedback",Position=UDim2.fromOffset(0,36),Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,
		BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3})
	local message=label(feedback,"Status","","muted")
	local version=label(footer,"Version","1.1.0  |  Project contracts","muted",18); version.Position=UDim2.fromOffset(0,78); version.TextSize=12
	local function invalidate() state.audit=nil; state.plan=nil; state.stale=nil; state.page=1; state.picked={}; state.subsetActive=false end
	local function changed() state.dirty=true; invalidate(); if refresh then refresh() end end
	local function act(fn)
		return function()
			if disposed or rendering then return end
			state.message=""; state.failed=false
			local ok,err=pcall(fn)
			if not ok then state.message=cleanError(err); state.failed=true end
			render()
		end
	end
	local function button(parent,name,text,fn,active,enabled)
		local b=make("TextButton",parent,{Name=name,Text=text,Size=UDim2.new(1,-4,0,32),BorderSizePixel=0,Font=Enum.Font.BuilderSansMedium,
			TextSize=14,TextTruncate=Enum.TextTruncate.AtEnd,Active=enabled~=false,Selectable=enabled~=false,AutoButtonColor=enabled~=false,TextTransparency=enabled==false and 0.5 or 0})
		make("UICorner",b,{CornerRadius=UDim.new(0,4)})
		paint(b,"BackgroundColor3",active and "accent" or "field"); paint(b,"TextColor3",active and "onAccent" or "text")
		b.Activated:Connect(act(function() if b.Active then fn() end end)); tip(b,text); return b
	end
	local function row(parent,count)
		local r=make("Frame",parent,{Size=UDim2.new(1,-4,0,32),BackgroundTransparency=1})
		make("UIGridLayout",r,{CellSize=UDim2.new(1/count,-4,1,0),CellPadding=UDim2.fromOffset(4,0),SortOrder=Enum.SortOrder.LayoutOrder}); return r
	end
	local function toggle(parent,name,text,value,setter)
		local b=button(parent,name,"",function() setter(not value) end)
		local box=make("Frame",b,{Name="Checkbox",Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(16,16),BorderSizePixel=0})
		paint(box,"BackgroundColor3",value and "accent" or "bg"); local stroke=make("UIStroke",box,{}); paint(stroke,"Color","border")
		local mark=label(box,"Check",value and utf8.char(0x2713) or "","onAccent",16); mark.TextXAlignment=Enum.TextXAlignment.Center
		local caption=label(b,"Caption",text,"text",24); caption.Position=UDim2.fromOffset(32,5); caption.Size=UDim2.new(1,-40,0,24)
		tip(b,text); return b
	end
	local function errorFor(part,key)
		local s=Schema.new(); s.tag="Validation"; s.fields={}; s.children={}
		if part=="field" then s.fields={Schema.copy(state.schema.fields[state.fieldIndex])}
		elseif part=="child" then s.children={Schema.copy(state.schema.children[state.childIndex])}
		else s[key]=state.schema[key] end
		local ok,err=pcall(Schema.validate,s); return ok and "" or cleanError(err)
	end
	local function input(parent,name,titleText,value,setter,validator)
		label(parent,name.."Label",titleText,"muted")
		local owner=(name=="SchemaName" or name=="TargetTag") and "schema"
			or state.childMode and ("child:"..state.childIndex) or ("field:"..state.fieldIndex)
		local key=owner..":"..name
		local box=make("TextBox",parent,{Name=name,Text=state.drafts[key] or (value==nil and "" or tostring(value)),Size=UDim2.new(1,-4,0,32),
			ClearTextOnFocus=false,BorderSizePixel=0,Font=Enum.Font.BuilderSans,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
		inputOwners[box]=owner=="schema" and state.schema or state.childMode and state.schema.children[state.childIndex] or state.schema.fields[state.fieldIndex]
		paint(box,"BackgroundColor3","field"); paint(box,"TextColor3","text"); padding(box,6)
		local errorText=label(parent,name.."Error","","error")
		local function validate() local err=validator and validator() or ""; errorText.Text=err; errorText.Visible=err~="" end
		table.insert(validation,validate); validate()
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if rendering then return end
			state.drafts[key]=box.Text; setter(box.Text); changed()
			for _,check in ipairs(validation) do check() end
		end)
		return box
	end
	local function menu(parent,name,titleText,options,value,setter)
		button(parent,name,titleText..": "..tostring(value).." "..utf8.char(0x25BE),function() state.menu=state.menu==name and nil or name end)
		if state.menu==name then
			local list=make("ScrollingFrame",parent,{Name=name.."Options",Size=UDim2.new(1,-4,0,math.min(180,#options*36)),CanvasSize=UDim2.new(),
				AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4}); stack(list,4)
			for i,choice in ipairs(options) do button(list,name.."Option"..i,choice,function() state.menu=nil; setter(choice,i) end,choice==value) end
		end
	end
	local function loadDraft(s,token)
		state.schema=s; state.token=token; state.loadedName=token and s.name or nil; state.dirty=false
		state.fieldIndex=1; state.childIndex=1; state.drafts={}; state.scrolls={}; state.resetScroll=true; state.menu=nil; state.tab="Rules"; invalidate()
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
		if #state.schema.fields==0 and #state.schema.children==0 and not state.loadedName then
			label(body,"EmptyHint","Select one configured object to capture a contract.","muted")
			button(body,"Capture","Capture reference",capture,true)
		end
		input(body,"SchemaName","Schema name",state.schema.name,function(v) state.schema.name=v end,function() return errorFor("schema","name") end)
		input(body,"TargetTag","Target tag (exact)",state.schema.tag,function(v) state.schema.tag=v end,function() return errorFor("schema","tag") end)
		menu(body,"ExpectedClass","Expected class",Schema.classes,state.schema.className,function(v) state.schema.className=v; changed() end)
		local modes=row(body,2)
		button(modes,"AttributesMode","Attributes ("..#state.schema.fields..")",function() state.childMode=false; state.menu=nil end,not state.childMode)
		button(modes,"ChildrenMode","Children ("..#state.schema.children..")",function() state.childMode=true; state.menu=nil end,state.childMode)
		if state.childMode then
			local names={}; for i,c in ipairs(state.schema.children) do names[i]=i..". "..c.path end
			if #names>0 then menu(body,"ChildPicker","Child",names,names[state.childIndex],function(_,i) state.childIndex=i end) end
			button(body,"AddChild","+ Required child",function()
				assert(#state.schema.children<32,"Limit: 32 child rules")
				table.insert(state.schema.children,{path="Child"..(#state.schema.children+1),className="Instance",description=""}); state.childIndex=#state.schema.children; state.drafts={}; changed()
			end)
			local c=state.schema.children[state.childIndex]
			if c then
				input(body,"ChildPath","Child path / nested child",c.path,function(v) c.path=v end,function()
					local count=0; for _,other in ipairs(state.schema.children) do if other.path==c.path then count+=1 end end
					if count>1 then return "Duplicate child path: "..c.path end
					return errorFor("child")
				end)
				menu(body,"ChildClass","Class",Schema.classes,c.className,function(v) c.className=v; changed() end)
				input(body,"ChildDescription","Designer note",c.description,function(v) c.description=v end,function() return #c.description>240 and "At most 240 characters." or "" end)
				button(body,"RemoveChild","Remove child rule",function() table.remove(state.schema.children,state.childIndex); state.childIndex=math.max(1,state.childIndex-1); state.drafts={}; changed() end)
			end
		else
			local names={}; for i,f in ipairs(state.schema.fields) do names[i]=i..". "..f.name end
			if #names>0 then menu(body,"FieldPicker","Field",names,names[state.fieldIndex],function(_,i) state.fieldIndex=i end) end
			button(body,"AddField","+ Attribute rule",function()
				assert(#state.schema.fields<32,"Limit: 32 attribute rules")
				table.insert(state.schema.fields,{name="Attribute"..(#state.schema.fields+1),kind="number",required=true,hasDefault=false,default=0,integer=false,choices={},description=""})
				state.fieldIndex=#state.schema.fields; state.drafts={}; changed()
			end)
			local f=state.schema.fields[state.fieldIndex]
			if f then
				input(body,"FieldName","Attribute name",f.name,function(v) f.name=v end,function()
					local count=0; for _,other in ipairs(state.schema.fields) do if other.name==f.name then count+=1 end end
					if count>1 then return "Duplicate attribute: "..f.name end
					return errorFor("field")
				end)
				menu(body,"FieldType","Type",Schema.kinds,f.kind,function(v)
					f.kind=v; f.min=nil; f.max=nil; f.integer=false; f.choices={}; f.hasDefault=false
					f.default=v=="number" and 0 or v=="string" and "" or false; state.drafts={}; changed()
				end)
				input(body,"FieldDescription","Designer note",f.description,function(v) f.description=v end,function() return #f.description>240 and "At most 240 characters." or "" end)
				toggle(body,"Required","Required",f.required,function(v) f.required=v; changed() end)
				if f.kind=="number" then
					for _,key in ipairs({"min","max"}) do
						input(body,key,key=="min" and "Minimum (optional)" or "Maximum (optional)",f[key],function(v) f[key]=v~="" and (tonumber(v) or v) or nil end,function()
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
				end
				toggle(body,"UseDefault","Repair missing values",f.hasDefault,function(v) f.hasDefault=v; changed() end)
				if f.hasDefault then
					if f.kind=="boolean" then toggle(body,"DefaultBoolean","Default: true",f.default==true,function(v) f.default=v; changed() end)
					else input(body,"DefaultValue","Default value",f.default,function(v) f.default=f.kind=="number" and (tonumber(v) or v) or v end,function()
						local ok,err=pcall(Schema.valueError,f,f.default)
						return not ok and "Fix the rule bounds first." or err or ""
					end) end
				end
				button(body,"RemoveField","Remove attribute rule",function() table.remove(state.schema.fields,state.fieldIndex); state.fieldIndex=math.max(1,state.fieldIndex-1); state.drafts={}; changed() end)
			end
		end
	end
	local function pages(items,draw)
		local count=math.max(1,math.ceil(#items/6)); state.page=math.min(state.page,count)
		for i=(state.page-1)*6+1,math.min(state.page*6,#items) do draw(items[i],i) end
		if count>1 then
			local r=row(body,3)
			button(r,"Previous",utf8.char(0x2190),function() state.page=math.max(1,state.page-1) end)
			label(r,"Page",state.page.." / "..count,"muted",32)
			button(r,"Next",utf8.char(0x2192),function() state.page=math.min(count,state.page+1) end)
		end
	end
	local function findings()
		local scopes=row(body,2)
		for _,scope in ipairs({"Selection","Workspace"}) do button(scopes,"Scope"..scope,scope,function() state.scope=scope; invalidate() end,state.scope==scope) end
		if not state.audit then label(body,"AuditHint","Audit tagged objects against this contract.","muted"); return end
		local a=state.audit
		label(body,"AuditSummary",string.format("%d checked / %d match / %d findings",a.matched,a.valid,#a.issues))
		label(body,"AuditWarning","Contract findings, not a correctness guarantee.","muted")
		menu(body,"ReasonFilter","Reason",{"All","Missing","Wrong type","Invalid value","Required child","Class"},state.reason,function(v) state.reason=v; state.page=1; state.plan=nil end)
		local values={}; for _,i in ipairs(a.issues) do if not table.find(values,i.field) then table.insert(values,i.field) end end
		local fields={"All fields"}; for _,value in ipairs(values) do table.insert(fields,value) end
		menu(body,"FieldFilter","Field / rule",fields,state.field=="" and "All fields" or state.field,function(_,i) state.field=i==1 and "" or values[i-1]; state.page=1; state.plan=nil end)
		local visible=visibleIssues(); local chosen=subset()
		local objects={}; for _,i in ipairs(chosen) do objects[i.instance]=true end
		local objectCount=0; for _ in pairs(objects) do objectCount+=1 end
		label(body,"SubsetSummary",#visible.." shown / "..#chosen.." findings in subset","note")
		button(body,"SelectFindings","Select affected ("..objectCount.." objects)",function() selectIssues(chosen) end,false,#chosen>0)
		button(body,"ClearSubset","Use all shown findings",function() state.picked={}; state.subsetActive=false; state.plan=nil end)
		pages(visible,function(finding,i)
			local item=make("Frame",body,{Name="Finding"..i,Size=UDim2.new(1,-4,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1}); stack(item,4)
			toggle(item,"Pick"..i,"Include "..finding.field,not state.subsetActive or state.picked[finding]==true,function(v)
				if not state.subsetActive then for _,shown in ipairs(visible) do state.picked[shown]=true end end
				state.picked[finding]=v or nil; state.subsetActive=true; state.plan=nil
			end)
			label(item,"Identity",finding.identity or finding.instance.Name)
			label(item,"Path",finding.path,"muted").TextSize=12
			label(item,"Reason",finding.category.." / "..finding.reason,finding.fix and "note" or "error")
			label(item,"Expected","Expected: "..finding.expected)
			label(item,"Actual","Actual: "..finding.actual)
			if finding.description~="" then label(item,"Note","Note: "..finding.description,"muted") end
			button(item,"SelectFinding"..i,"Select object",function() assert(Engine.allowed(finding.instance),"Object was removed. Audit again"); selectIssues({finding}) end)
		end)
	end
	local function repairs()
		if not state.plan then label(body,"RepairHint",state.stale or "Run an audit, then preview missing defaults.","muted"); return end
		local plan=state.plan; local seen={}; for _,c in ipairs(plan.changes) do seen[c.instance]=true end
		local n=0; for _ in pairs(seen) do n+=1 end
		label(body,"RepairSummary",#plan.changes.." missing defaults / "..n.." objects","note")
		label(body,"Preservation","Existing values, tags and children stay unchanged.","muted")
		pages(plan.changes,function(c,i) label(body,"Repair"..i,c.identity.."\n"..c.path.."\n"..c.name..": (missing) "..utf8.char(0x2192).." "..tostring(c.value)) end)
	end
	local function library()
		button(body,"Capture","Capture reference",capture,true)
		button(body,"New","New blank schema",function() replaceDraft(function() loadDraft(Schema.new()) end) end)
		label(body,"LibraryTitle","Saved in this project","muted")
		local ok,names=pcall(Store.list)
		if not ok then label(body,"LibraryError",cleanError(names),"error")
		elseif #names==0 then label(body,"NoSchemas","No saved schemas.","muted")
		else for _,name in ipairs(names) do
			local b=button(body,"Load"..name,name,function() replaceDraft(function() local s,token=Store.load(name); loadDraft(s,token); state.message="Loaded project schema." end) end)
			b.AutomaticSize=Enum.AutomaticSize.Y; b.TextWrapped=true; b.TextTruncate=Enum.TextTruncate.None; padding(b,6)
		end end
		if state.loadedName then
			button(body,"Delete","Delete saved schema",function() state.confirm={title="Delete saved schema "..state.loadedName.."?",fn=function() Store.delete(state.loadedName,state.token,history); loadDraft(Schema.new()); state.message="Deleted. Native Undo available." end} end)
		end
	end
	local tabs={}
	for _,name in ipairs({"Rules","Audit","Repairs"}) do tabs[name]=button(nav,"Tab"..name,name,function() state.tab=name; state.menu=nil; state.page=1 end) end
	local lib=button(header,"Library","Library",function() state.tab=state.tab=="Library" and "Rules" or "Library"; state.menu=nil end)
	lib.Position=UDim2.new(1,-84,0,8); lib.Size=UDim2.fromOffset(72,28)
	refresh=function()
		context.Text=(state.loadedName and "" or "Draft: ")..state.schema.name..(state.dirty and " *" or "")
		tag.Text="Tag: "..(state.schema.tag~="" and state.schema.tag or "not set").." / "..state.schema.className
		local roots=state.audit and state.audit.roots or selection:Get()
		scopeText.Text=state.scope=="Workspace" and "Scope: Workspace" or "Scope: Selection + descendants ("..#roots..")"..(#roots>0 and " / "..roots[1]:GetFullName() or "")
		message.Text=state.stale or state.message; paint(message,"TextColor3",(state.stale or state.failed) and "error" or "note")
		local save=actions:FindFirstChild("Save",true)
		if save then local valid=pcall(Schema.validate,state.schema); save.Active=valid; save.Selectable=valid; save.TextTransparency=valid and 0 or 0.5; save.Text=state.dirty and "Save schema *" or "Save schema" end
		for _,name in ipairs({"Apply","PrepareFixes"}) do
			local b=actions:FindFirstChild(name,true)
			if b then b.Active=not state.stale and (name=="Apply" and state.plan~=nil and #state.plan.changes>0 or name=="PrepareFixes" and state.audit~=nil); b.TextTransparency=b.Active and 0 or 0.5 end
		end
	end
	local renderedTab,renderedConfirmation
	render=function()
		if disposed then return end
		renderGeneration+=1; local generation=renderGeneration
		-- DockWidget text focus is separate from the main viewport input service.
		local focus
		for _,obj in ipairs(body:GetDescendants()) do
			if obj:IsA("TextBox") and obj:IsFocused() then focus=obj; break end
		end
		local focusName,focusOwner,cursor,selectionStart
		if focus then focusName=focus.Name; focusOwner=inputOwners[focus]; cursor=focus.CursorPosition; selectionStart=focus.SelectionStart end
		if renderedTab and not renderedConfirmation and not state.resetScroll then state.scrolls[renderedTab]=body.CanvasPosition end
		state.resetScroll=nil
		rendering=true; tooltip.Visible=false; validation={}
		for _,obj in ipairs(body:GetChildren()) do obj:Destroy() end
		for _,obj in ipairs(actions:GetChildren()) do obj:Destroy() end
		stack(body,8)
		if state.confirm then
			label(body,"Confirmation",state.confirm.title,"error")
			button(body,"Confirm","Confirm",function() local fn=state.confirm.fn; state.confirm=nil; fn() end)
			button(body,"Cancel","Cancel",function() state.confirm=nil end)
		elseif state.tab=="Rules" then rules() elseif state.tab=="Audit" then findings() elseif state.tab=="Repairs" then repairs() else library() end
		for name,b in pairs(tabs) do paint(b,"BackgroundColor3",state.tab==name and "accent" or "field"); paint(b,"TextColor3",state.tab==name and "onAccent" or "text") end
		if not state.confirm then
			if state.tab=="Rules" then
				button(actions,"Save","Save schema",function()
					local token=state.loadedName==state.schema.name and state.token or nil
					state.token=Store.save(state.schema,token,history); state.loadedName=state.schema.name; state.dirty=false; state.message="Saved in this project."
				end,true)
			elseif state.tab=="Audit" then
				local r=row(actions,2); button(r,"Audit","Audit",runAudit)
				button(r,"PrepareFixes","Preview",function()
					assert(not state.stale,"Scope or values changed. Audit again.")
					state.plan=Engine.preview(state.audit,subset()); state.tab="Repairs"; state.page=1; state.planSelection=selection:Get()
				end,true,state.audit~=nil and not state.stale)
			elseif state.tab=="Repairs" then
				button(actions,"Apply","Apply "..(state.plan and #state.plan.changes or 0).." missing defaults",function()
					assert(not state.stale and sameSelection(state.planSelection,selection:Get()),"Selection changed. Preview again.")
					if state.loadedName then
						local _,token=Store.load(state.loadedName)
						assert(token==state.token,"Saved schema changed. Reload and audit again.")
					end
					local count=Engine.apply(state.plan,history); state.plan=nil; state.audit=nil; state.picked={}
					state.message=count.." defaults added. Native Undo available."
				end,true,state.plan~=nil and not state.stale and #state.plan.changes>0)
			else button(actions,"Return","Return to rules",function() state.tab="Rules" end) end
		end
		renderedTab=state.tab; renderedConfirmation=state.confirm~=nil; refresh(); rendering=false
		local wanted=state.confirm and Vector2.zero or state.scrolls[state.tab] or Vector2.zero; body.CanvasPosition=wanted
		task.defer(function()
			if disposed or generation~=renderGeneration then return end
			if focusName then
				local replacement=body:FindFirstChild(focusName,true)
				if replacement and replacement:IsA("TextBox") and inputOwners[replacement]==focusOwner then
					replacement:CaptureFocus(); replacement.CursorPosition=cursor; replacement.SelectionStart=selectionStart
				end
			end
			body.CanvasPosition=wanted
		end)
	end
	local selectionChanged=selection.SelectionChanged:Connect(function()
		if disposed then return end
		local selected=selection:Get(); local inspection=state.inspectionSelection and sameSelection(state.inspectionSelection,selected); state.inspectionSelection=nil
		if state.plan or (state.audit and state.scope=="Selection" and not inspection and not sameSelection(state.audit.roots,selected)) then state.stale="Selection changed. Audit and preview again." end
		refresh()
	end)
	local function historyChanged()
		invalidate(); state.message="History changed. Run a fresh audit."
		task.defer(function() if not disposed then render() end end)
	end
	local undo=history.OnUndo:Connect(historyChanged); local redo=history.OnRedo:Connect(historyChanged); local themed=studio.ThemeChanged:Connect(theme)
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
	return function() disposed=true; selectionChanged:Disconnect(); undo:Disconnect(); redo:Disconnect(); themed:Disconnect(); root:Destroy() end
end
return View
