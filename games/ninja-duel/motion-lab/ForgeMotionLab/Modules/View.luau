local UI=require(script.Parent.UI)
local M=require(script.Parent.Model)
local Library=require(script.Parent.Library)
local Sampler=require(script.Parent.Sampler)
local Rig=require(script.Parent.Rig)
local Controller=require(script.Parent.Controller)
local View={}
function View.mount(widget,plugin)
 local c=Controller.create(plugin);local ui=UI.new(widget);local scopes={};local alive=true
 local root=ui:frame(widget,{Size=UDim2.fromScale(1,1),ClipsDescendants=true})
 local header=ui:frame(root,{Size=UDim2.new(1,0,0,104)})
 ui:label(header,"Forge Motion Lab",{Position=UDim2.fromOffset(18,8),Size=UDim2.fromOffset(220,32),TextSize=20,Font=Enum.Font.BuilderSansBold})
 ui:label(header,"Motion creation · R15",{Position=UDim2.fromOffset(18,40),Size=UDim2.fromOffset(200,18),TextSize=12},"muted")
 local nameBox=ui:input(header,c.preset.name,{Position=UDim2.fromOffset(246,14),Size=UDim2.new(1,-538,0,30)},function(text)if #text>0 and #text<=80 then c:edit(function(p)p.name=text end)end end)
 local status=ui:label(root,"Ready",{Position=UDim2.new(0,16,1,-27),Size=UDim2.new(1,-32,0,22),TextSize=12},"muted")
 local dirty=ui:label(header,"Unsaved mix",{Position=UDim2.fromOffset(246,47),Size=UDim2.new(1,-540,0,18),TextSize=12},"muted")
 local left=ui:frame(root,{Position=UDim2.fromOffset(12,108),Size=UDim2.new(0,210,1,-312)})
 local right=ui:frame(root,{Position=UDim2.new(1,-292,0,108),Size=UDim2.new(0,280,1,-312)})
 local center=ui:frame(root,{Position=UDim2.fromOffset(234,108),Size=UDim2.new(1,-538,1,-312)},"canvas")
 local bottom=ui:frame(root,{Position=UDim2.new(0,12,1,-192),Size=UDim2.new(1,-24,0,158)})
 local timeReadout=ui:label(center,"0.00s",{Position=UDim2.new(1,-100,0,44),Size=UDim2.fromOffset(86,18),TextXAlignment=Enum.TextXAlignment.Right,TextSize=11},"muted")
 local title=ui:label(center,"Run",{Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-110,0,24),TextSize=17,Font=Enum.Font.BuilderSansBold})
 local subtitle=ui:label(center,"Live R15 preview",{Position=UDim2.fromOffset(14,38),Size=UDim2.new(1,-28,0,18),TextSize=12},"muted")
 local viewport=ui:make("ViewportFrame",center,{Position=UDim2.fromOffset(0,65),Size=UDim2.new(1,0,1,-110),BackgroundTransparency=1,Ambient=Color3.fromRGB(165,174,192),LightColor=Color3.fromRGB(233,240,255),LightDirection=Vector3.new(-1,-1,-.5),BorderSizePixel=0})
 local world=Instance.new("WorldModel");world.Parent=viewport
 local camera=Instance.new("Camera");camera.FieldOfView=38;camera.Parent=viewport;viewport.CurrentCamera=camera
 local rig=Rig.new(world);local rigB=Rig.new(world,Color3.fromRGB(225,180,115));rigB.model.Parent=nil
 local grid=Instance.new("Folder");grid.Name="Grid";grid.Parent=world
 for i=-8,8 do for _,axis in {"x","z"} do local p=Instance.new("Part");p.Size=if axis=="x" then Vector3.new(16,.015,.025) else Vector3.new(.025,.015,16);p.CFrame=CFrame.new(if axis=="x" then Vector3.new(0,-.02,i) else Vector3.new(i,-.02,0));p.Anchored=true;p.CanCollide=false;p.Color=Color3.fromRGB(68,87,111);p.Transparency=if i==0 then .2 else .65;p.Parent=grid end end
 local showGrid=true;local showRoot=true;local mode="front";local yaw=math.pi;local pitch=.16;local distance=12;local drag=nil;local last=nil
 local function updateCamera()camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(yaw)*distance,2.2+math.sin(pitch)*distance,math.cos(yaw)*distance),Vector3.new(0,2.2,0))end;updateCamera()
 local refresh,refreshLibrary,refreshInspector,refreshTimeline
 local function state()nameBox.Text=c.preset.name;dirty.Text=if c.dirty then "Unsaved changes" else "Saved preset";title.Text=if c.sequenceMode then c:sequence().name else Sampler.resolveAsset(c.preset,c.library.assets[c.clip],c.library).name;subtitle.Text=if c.compare then "A: pinned reference    B: current edit" else "Live R15 · "..(if c.preset.metadata.sourceType=="ninja-duel" then "authored source" else "procedural profile")end
 local function action(fn,message)
  local ok,err=pcall(fn);status.Text=if ok then message or "Updated" else tostring(err):gsub("^.-:%d+: ","");state();if ok and refresh then refresh() end
 end
 local popup=nil;local popupUI=nil
 local function closeMenu()if popupUI then popupUI:dispose();popupUI=nil end;if popup then popup:Destroy();popup=nil end end
 local function menu(anchor,items,chosen)
  closeMenu();popupUI=UI.new(widget)
  popup=ui:frame(root,{Size=UDim2.fromOffset(math.max(180,anchor.AbsoluteSize.X),math.min(320,#items*30+8)),Position=UDim2.fromOffset(math.clamp(anchor.AbsolutePosition.X-root.AbsolutePosition.X,8,root.AbsoluteSize.X-210),math.min(root.AbsoluteSize.Y-330,anchor.AbsolutePosition.Y-root.AbsolutePosition.Y+anchor.AbsoluteSize.Y+4)),ZIndex=50},"hover")
  local scroll=ui:scroll(popup,{Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4),ZIndex=51})
  for i,item in items do popupUI:button(scroll,item.name,{Position=UDim2.fromOffset(0,(i-1)*30),Size=UDim2.new(1,-4,0,28),ZIndex=52},function()closeMenu();chosen(item.id)end)end
 end
 local function pick(anchor,items,fn)menu(anchor,items,function(id)action(function()fn(id)end)end)end
 local save=ui:button(header,"Save",{Position=UDim2.new(1,-282,0,14),Size=UDim2.fromOffset(72,30)},function()action(function()c:save()end,"Preset saved locally")end,true)
 ui:button(header,"Export",{Position=UDim2.new(1,-200,0,14),Size=UDim2.fromOffset(82,30)},function()action(function()assert(not game:GetService("RunService"):IsRunning(),"Export in Edit mode");local module=c:export(game:GetService("ServerStorage"));game:GetService("Selection"):Set({module})end,"Config exported to ServerStorage · no gameplay changes")end)
 ui:button(header,"Attach R15",{Position=UDim2.new(1,-108,0,14),Size=UDim2.fromOffset(94,30)},function()action(function()assert(not game:GetService("RunService"):IsRunning(),"Apply in Edit mode");local selected=game:GetService("Selection"):Get()[1];assert(selected and selected:IsA("Model") and selected:FindFirstChild("Humanoid") and selected.Humanoid.RigType==Enum.HumanoidRigType.R15,"Select an R15 Model first");c:export(selected)end,"Profile attached to R15 · animations untouched")end)
 local new=ui:button(header,"New profile",{Position=UDim2.fromOffset(18,72),Size=UDim2.fromOffset(94,28)})
 ui:connect(new.Activated,function()local items={{id="blank",name="Blank profile"}};for _,t in Library.Templates do table.insert(items,{id=t.id,name=t.name.." starting profile"})end;pick(new,items,function(id)c:new(if id=="blank" then nil else id)end)end)
 ui:button(header,"Duplicate",{Position=UDim2.fromOffset(120,72),Size=UDim2.fromOffset(80,28)},function()action(function()c:duplicate()end)end)
 local deleting=false
 ui:button(header,"Delete",{Position=UDim2.fromOffset(208,72),Size=UDim2.fromOffset(64,28)},function()if not deleting then deleting=true;status.Text="Click Delete again to remove this custom preset";return end;deleting=false;action(function()c.store:delete(c.preset.id);c:new(nil)end,"Preset removed")end)
 ui:button(header,"↶",{Position=UDim2.fromOffset(286,72),Size=UDim2.fromOffset(30,28)},function()action(function()c:undo()end)end)
 ui:button(header,"↷",{Position=UDim2.fromOffset(320,72),Size=UDim2.fromOffset(30,28)},function()action(function()c:redo()end)end)
 ui:button(header,"Pin A",{Position=UDim2.fromOffset(366,72),Size=UDim2.fromOffset(66,28)},function()action(function()c:pinCompare();rigB.model.Parent=world end,"A pinned; edit B to compare")end)
 ui:button(header,"Clear A/B",{Position=UDim2.fromOffset(440,72),Size=UDim2.fromOffset(78,28)},function()action(function()c.compare=nil;rigB.model.Parent=nil end)end)
 ui:button(header,"Mirror",{Position=UDim2.fromOffset(534,72),Size=UDim2.fromOffset(70,28)},function()action(function()c.mirror=not c.mirror end,c.mirror and "Mirror off" or "Mirror on")end)
 local function scope(key,parent)
  if scopes[key] then scopes[key]:dispose() end;parent:ClearAllChildren();scopes[key]=UI.new(widget);return scopes[key]
 end
 local search="";local category="All"
 refreshLibrary=function()
  local u=scope("library",left);u:label(left,"Sources",{Position=UDim2.fromOffset(12,10),Size=UDim2.new(1,-24,0,24),TextSize=16,Font=Enum.Font.BuilderSansBold})
  for i,tab in {"Characters","Library","Custom"} do u:button(left,tab,{Position=UDim2.new((i-1)/3,8,0,42),Size=UDim2.new(1/3,-10,0,27)},function()c.tab=tab;search="";refreshLibrary()end,c.tab==tab)end
  local field=u:input(left,search,{Position=UDim2.fromOffset(10,78),Size=UDim2.new(1,-20,0,30),PlaceholderText="Search sources"})
  u:connect(field.FocusLost,function()search=field.Text:lower();refreshLibrary()end)
  local y=116
  if c.tab=="Library" then local filter=u:button(left,category.." ▾",{Position=UDim2.fromOffset(10,y),Size=UDim2.new(1,-20,0,28)})
   u:connect(filter.Activated,function()local items={{id="All",name="All families"}};for _,family in Library.Families do table.insert(items,{id=family,name=family})end;pick(filter,items,function(id)category=id end)end);y+=36 end
  local scroll=u:scroll(left,{Position=UDim2.fromOffset(8,y),Size=UDim2.new(1,-16,1,-y-42)})
  local rows={}
  if c.tab=="Library" then for _,id in c.library.assetOrder do local a=c.library.assets[id];if (category=="All" or a.category==category) and (search=="" or a.name:lower():find(search,1,true)) then table.insert(rows,{id=id,name=a.name,desc=a.category})end end
  else for _,id in c.library.order do local p=c.library.presets[id];local custom=c.store.custom[id]~=nil;if (c.tab=="Custom")==custom and (search=="" or p.name:lower():find(search,1,true)) then table.insert(rows,{id=id,name=p.name,desc=if p.metadata.sourceType=="ninja-duel" then "Authored · Ninja Duel" elseif custom then "Saved motion profile" else "Generated starting profile"})end end end
  for i,row in rows do
   local b=u:button(scroll,"",{Position=UDim2.fromOffset(0,(i-1)*62),Size=UDim2.new(1,-6,0,56)},function()action(function()if c.tab=="Library" then c.clip=row.id;c.sequenceMode=false;c.time=0 else c:load(row.id)end end)end)
   u:label(b,row.name,{Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-20,0,24),Font=Enum.Font.BuilderSansMedium})
   u:label(b,row.desc,{Position=UDim2.fromOffset(10,30),Size=UDim2.new(1,-20,0,18),TextSize=11},"muted")
   if c.tab=="Library" and c.clip==row.id then u:frame(b,{Size=UDim2.new(0,3,1,-10),Position=UDim2.fromOffset(0,5)},"accent")end
  end
  if #rows==0 then u:label(scroll,if c.tab=="Custom" then "No saved profiles yet.\nSave a mix to keep it here." else "No matching sources.",{Size=UDim2.new(1,-10,0,80),TextWrapped=true,TextSize=13},"muted")end
  u:button(left,"Import selected export",{Position=UDim2.new(0,10,1,-34),Size=UDim2.new(1,-20,0,26)},function()action(function()local item=game:GetService("Selection"):Get()[1];assert(item,"Select an exported ModuleScript or JSON value");c:import(item)end,"Imported safely from JSON")end)
 end
 local inspectorTab="Mixer"
 refreshInspector=function()
  local u=scope("inspector",right)
  for i,tab in {"Mixer","DNA","Advanced"} do u:button(right,tab,{Position=UDim2.new((i-1)/3,8,0,10),Size=UDim2.new(1/3,-12,0,30)},function()inspectorTab=tab;refreshInspector()end,inspectorTab==tab)end
  local scroll=u:scroll(right,{Position=UDim2.fromOffset(12,52),Size=UDim2.new(1,-24,1,-64)})
  if inspectorTab=="Mixer" then
   u:label(scroll,"Body Mixer",{Size=UDim2.new(1,0,0,28),TextSize=17,Font=Enum.Font.BuilderSansBold})
   u:label(scroll,"Choose an expression for each layer.",{Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,0,22),TextSize=12},"muted")
   for i,layer in M.Layers do local y=60+(i-1)*124;local spec=c.preset.bodyLayers[layer]
    local label=layer:gsub("Arm"," arm");u:label(scroll,label,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-56,0,22),Font=Enum.Font.BuilderSansMedium})
    u:button(scroll,spec.enabled and "On" or "Off",{Position=UDim2.new(1,-48,0,y),Size=UDim2.fromOffset(42,22)},function()action(function()c:edit(function(p)p.bodyLayers[layer].enabled=not spec.enabled end)end)end,spec.enabled)
    local source=if spec.source=="base" then "Own profile" else c.library.presets[spec.source].name
    local pickButton=u:button(scroll,source.." ▾",{Position=UDim2.fromOffset(0,y+27),Size=UDim2.new(1,-6,0,28)})
    u:connect(pickButton.Activated,function()local choices={{id="base",name="Own profile"}};for _,id in c.library.order do if id~=c.preset.id then table.insert(choices,{id=id,name=c.library.presets[id].name})end end;pick(pickButton,choices,function(id)c:edit(function(p)p.bodyLayers[layer].source=id end)end)end)
    u:slider(scroll,"Blend",0,1,spec.strength,y+58,function(value)c:edit(function(p)p.bodyLayers[layer].strength=value end,false);state()end,function()c:checkpoint()end)
   end
  elseif inspectorTab=="DNA" then
   u:button(scroll,"Generate movement set",{Size=UDim2.new(1,-4,0,32)},function()action(function()c:generate()end,"Suggested route generated; every block remains editable")end,true)
   local y=44;local group=nil
   for _,row in M.DNA do if group~=row[6] then group=row[6];u:label(scroll,group,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-6,0,24),Font=Enum.Font.BuilderSansBold});y+=30 end
    u:slider(scroll,row[2],row[3],row[4],c.preset.motionDNA[row[1]],y,function(value)c:edit(function(p)p.motionDNA[row[1]]=value end,false);state()end,function()c:checkpoint()end);y+=62 end
  else
   local text="Profile ID\n"..c.preset.id.."\n\nSource\n"..c.preset.metadata.sourceType.."\n\nRig\nR15 · anatomical joint controls\n\nExport\nNinjaDuel.MotionDefinitions.v1\nData only. No automatic apply.\n\nCharacter expression\n"..game:GetService("HttpService"):JSONEncode(c.preset.characterRules)
   u:label(scroll,text,{Size=UDim2.new(1,-8,0,260),TextSize=13,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
   u:label(scroll,"Character rules (JSON)",{Position=UDim2.fromOffset(0,266),Size=UDim2.new(1,-8,0,24),Font=Enum.Font.BuilderSansMedium})
   u:input(scroll,game:GetService("HttpService"):JSONEncode(c.preset.characterRules),{Position=UDim2.fromOffset(0,294),Size=UDim2.new(1,-8,0,74),MultiLine=true,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top},function(text)action(function()
    local rules=game:GetService("HttpService"):JSONDecode(text);local candidate=M.copy(c.preset);candidate.characterRules=rules;local valid,why=M.validate(candidate,c.library.presets);assert(valid,why);c:edit(function(p)p.characterRules=rules end)
   end,"Expression rules updated")end)
   for i,key in {"idle","walk","run","dash","jump","land","wall"} do
    local y=382+(i-1)*38;u:button(scroll,key,{Position=UDim2.fromOffset(0,y),Size=UDim2.fromOffset(60,28)},function()c.clip=if key=="wall" then "wallrun" else key;c.sequenceMode=false;c.time=0;state();refreshTimeline()end)
    local id=c.preset.locomotionSet[key] or key;local button=u:button(scroll,(c.library.assets[id] and c.library.assets[id].name or id).." ▾",{Position=UDim2.fromOffset(70,y),Size=UDim2.new(1,-78,0,28)})
    u:connect(button.Activated,function()local items={};for _,assetId in c.library.assetOrder do table.insert(items,{id=assetId,name=c.library.assets[assetId].name})end;pick(button,items,function(chosen)c:edit(function(p)p.locomotionSet[key]=chosen end)end)end)
   end
  end
 end
 refreshTimeline=function()
  local u=scope("timeline",bottom);local seq=c:sequence()
  u:label(bottom,"Sequence",{Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(90,24),Font=Enum.Font.BuilderSansBold,TextSize=15})
  u:input(bottom,seq.name,{Position=UDim2.fromOffset(106,8),Size=UDim2.fromOffset(180,26)},function(text)if #text>0 and #text<=64 then c:edit(function(p)p.sequences[1].name=text end);state()end end)
  u:button(bottom,"+ "..c.library.assets[c.clip].name,{Position=UDim2.fromOffset(300,8),Size=UDim2.fromOffset(120,26)},function()action(function()c:addClip(c.clip)end)end)
  u:button(bottom,"Preview phrase",{Position=UDim2.fromOffset(432,8),Size=UDim2.fromOffset(116,26)},function()c.sequenceMode=true;c.time=0;state()end)
  local line=u:make("ScrollingFrame",bottom,{Position=UDim2.fromOffset(12,44),Size=UDim2.new(1,-24,0,62),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.fromOffset(#seq.orderedClips*112,0),ScrollingDirection=Enum.ScrollingDirection.X})
  for i,block in seq.orderedClips do
   local asset=c.library.assets[block.asset];local b=u:button(line,asset.name.."\n"..string.format("%.2fs",block.duration),{Position=UDim2.fromOffset((i-1)*112,0),Size=UDim2.fromOffset(106,54),TextWrapped=true},function()c.selectedBlock=i;task.defer(function()if alive then refreshTimeline()end end)end,c.selectedBlock==i)
   local start=nil
   u:connect(b.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then start=widget:GetRelativeMousePosition().X;u:connect(input.Changed,function()if input.UserInputState==Enum.UserInputState.End and start then local dx=widget:GetRelativeMousePosition().X-start;start=nil;local target=math.clamp(i+math.floor(dx/112+.5),1,#seq.orderedClips);if target~=i then action(function()c:edit(function(p)M.reorder(p.sequences[1],i,target)end);c.selectedBlock=target end,"Blocks reordered")end end end)end end)
  end
  if #seq.orderedClips==0 then u:label(line,"Choose a library block, then add it here.",{Size=UDim2.new(1,-12,0,44),TextSize=13},"muted")end
  local scrub=u:make("TextButton",bottom,{Position=UDim2.fromOffset(12,105),Size=UDim2.new(1,-24,0,8),Text="",BackgroundTransparency=.65,AutoButtonColor=false,BorderSizePixel=0})
  u:paint(scrub,"BackgroundColor3","line")
  u:connect(scrub.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then
   local mouse=widget:GetRelativeMousePosition();local relative=mouse.X-(scrub.AbsolutePosition.X-widget.AbsolutePosition.X)
   c.sequenceMode=true;c.playing=false;c.time=math.clamp(relative/math.max(1,scrub.AbsoluteSize.X),0,1)*M.duration(seq)/c.preset.motionDNA.recoverySpeed;state()
  end end)
  local selected=seq.orderedClips[c.selectedBlock]
  if selected then
   u:label(bottom,"Duration",{Position=UDim2.fromOffset(12,115),Size=UDim2.fromOffset(56,26),TextSize=12},"muted")
   u:input(bottom,tostring(selected.duration),{Position=UDim2.fromOffset(72,115),Size=UDim2.fromOffset(60,26)},function(text)local n=tonumber(text);if n and n>=.12 and n<=5 then action(function()c:edit(function(p)p.sequences[1].orderedClips[c.selectedBlock].duration=n end)end)else status.Text="Duration: 0.12–5 seconds"end end)
   u:label(bottom,"Blend",{Position=UDim2.fromOffset(144,115),Size=UDim2.fromOffset(42,26),TextSize=12},"muted")
   u:input(bottom,tostring(selected.blend),{Position=UDim2.fromOffset(190,115),Size=UDim2.fromOffset(60,26)},function(text)local n=tonumber(text);if n and n>=0 and n<=.5 then action(function()c:edit(function(p)p.sequences[1].orderedClips[c.selectedBlock].blend=n end)end)end end)
   u:button(bottom,selected.transition=="cut" and "Cut" or "Blend",{Position=UDim2.fromOffset(266,115),Size=UDim2.fromOffset(62,26)},function()action(function()c:edit(function(p)local b=p.sequences[1].orderedClips[c.selectedBlock];b.transition=if b.transition=="cut" then "blend" else "cut" end)end)end)
   u:button(bottom,"Remove block",{Position=UDim2.fromOffset(340,115),Size=UDim2.fromOffset(108,26)},function()action(function()c:edit(function(p)table.remove(p.sequences[1].orderedClips,c.selectedBlock)end);c.selectedBlock=math.max(1,c.selectedBlock-1)end)end)
  end
 end
 refresh=function()refreshLibrary();refreshInspector();refreshTimeline();state()end
 local controls=ui:frame(center,{Position=UDim2.new(0,0,1,-39),Size=UDim2.new(1,0,0,39)})
 local function layout()
  local narrow=root.AbsoluteSize.X<1000;local lw=if narrow then 180 else 210;local rw=if narrow then 240 else 280
  left.Size=UDim2.new(0,lw,1,-312);right.Position=UDim2.new(1,-rw-12,0,108);right.Size=UDim2.new(0,rw,1,-312)
  center.Position=UDim2.fromOffset(lw+24,108);center.Size=UDim2.new(1,-lw-rw-48,1,-312)
 end
 ui:connect(root:GetPropertyChangedSignal("AbsoluteSize"),layout);layout()
 local play;play=ui:button(controls,"Pause",{Position=UDim2.new(0,5,0,6),Size=UDim2.new(1/6,-7,0,28)},function()c.playing=not c.playing;play.Text=if c.playing then "Pause" else "Play" end)
 local loop;loop=ui:button(controls,"Loop ✓",{Position=UDim2.new(1/6,5,0,6),Size=UDim2.new(1/6,-7,0,28)},function()c.loop=not c.loop;loop.Text=if c.loop then "Loop ✓" else "Once" end)
 local speed=ui:button(controls,"1×",{Position=UDim2.new(2/6,5,0,6),Size=UDim2.new(1/6,-7,0,28)})
 ui:connect(speed.Activated,function()pick(speed,{{id="0.5",name="0.5×"},{id="1",name="1×"},{id="1.5",name="1.5×"},{id="2",name="2×"}},function(id)c.speed=tonumber(id);speed.Text=id.."×"end)end)
 local cameraButton=ui:button(center,"Front ▾",{Position=UDim2.new(1,-94,0,14),Size=UDim2.fromOffset(80,28)})
 ui:connect(cameraButton.Activated,function()pick(cameraButton,{{id="front",name="Front"},{id="side",name="Side"},{id="free",name="Free orbit"}},function(id)mode=id;cameraButton.Text=id.." ▾";if id=="front" then yaw=math.pi;pitch=.16 elseif id=="side" then yaw=math.pi/2;pitch=.16 end;updateCamera()end)end)
 local gridButton;gridButton=ui:button(controls,"Grid ✓",{Position=UDim2.new(3/6,5,0,6),Size=UDim2.new(1/6,-7,0,28)},function()showGrid=not showGrid;grid.Parent=if showGrid then world else nil;gridButton.Text=if showGrid then "Grid ✓" else "Grid" end)
 local rootButton;rootButton=ui:button(controls,"Root ✓",{Position=UDim2.new(4/6,5,0,6),Size=UDim2.new(1/6,-7,0,28)},function()showRoot=not showRoot;rootButton.Text=if showRoot then "Root ✓" else "Root" end)
 ui:button(controls,"Reset",{Position=UDim2.new(5/6,5,0,6),Size=UDim2.new(1/6,-7,0,28)},function()c.time=0 end)
 ui:connect(viewport.InputBegan,function(input)if mode=="free" and (input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton1) then drag=true;last=widget:GetRelativeMousePosition();ui:connect(input.Changed,function()if input.UserInputState==Enum.UserInputState.End then drag=nil end end)end end)
 ui:connect(viewport.InputChanged,function(input)if input.UserInputType==Enum.UserInputType.MouseWheel then distance=math.clamp(distance-input.Position.Z,7,22);updateCamera()end end)
 local debt=0
 ui:connect(game:GetService("RunService").RenderStepped,function(dt)
  if not alive or not widget.Enabled then return end
  if drag then local now=widget:GetRelativeMousePosition();local diff=now-last;last=now;yaw-=diff.X*.009;pitch=math.clamp(pitch+diff.Y*.006,-.15,.8);updateCamera()end
  debt+=dt;if debt<1/30 then return end;local tick=math.min(debt,.1);debt=0
  local total=if c.sequenceMode then M.duration(c:sequence())/c.preset.motionDNA.recoverySpeed else Sampler.duration(c.preset,c.library.assets[c.clip],c.library)
  total=math.max(total,.1)
  if c.playing then c.time+=tick*c.speed;if c.time>=total then if c.loop then c.time%=total else c.time=total;c.playing=false;play.Text="Play" end end end
  timeReadout.Text=string.format("%.2f / %.2fs",c.time,total)
  local function pose(p,reference)
   local lib=if reference then c.compareLibrary else c.library
   local sequenceMode=if reference then c.compareSequenceMode else c.sequenceMode
   local clip=if reference then c.compareClip else c.clip
   if sequenceMode then
    local seq=p.sequences[1] or {orderedClips={}};local duration=math.max(.1,M.duration(seq)/p.motionDNA.recoverySpeed)
    return Sampler.sequence(p,seq,(c.time/total)*duration,lib,c.mirror)
   end
   return Sampler.sample(p,lib.assets[clip],math.clamp(c.time/total,0,1),lib,c.mirror)
  end
  local ok,err=pcall(function()
   local current=pose(c.preset)
   if c.compare then Rig.apply(rig,pose(c.compare,true),Vector3.new(-2.5,3,0),showRoot,c.compare.bodyLayers.Weapon.enabled);Rig.apply(rigB,current,Vector3.new(2.5,3,0),showRoot,c.preset.bodyLayers.Weapon.enabled)
   else Rig.apply(rig,current,Vector3.new(0,3,0),showRoot,c.preset.bodyLayers.Weapon.enabled)end
  end)
  if not ok then c.playing=false;status.Text="Preview: "..tostring(err) end
 end)
 refresh();status.Text=c.store.notice or "Minato lower body + Itachi upper body · save to keep this mix"
 return function()alive=false;closeMenu();for _,scope in scopes do scope:dispose()end;ui:dispose();rig.model:Destroy();rigB.model:Destroy();world:Destroy();grid:Destroy();root:Destroy()end,c
end
return View
