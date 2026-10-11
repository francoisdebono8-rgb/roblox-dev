-- One authoring workflow: browse -> variant -> pose/timing -> compare -> save/export.
local UI=require(script.Parent.UI)
local M=require(script.Parent.Model)
local E=require(script.Parent.MotionEdit)
local Library=require(script.Parent.Library)
local S=require(script.Parent.Sampler)
local Rig=require(script.Parent.Rig)
local Controller=require(script.Parent.Controller)
local Timeline=require(script.Parent.Timeline)
local EditInspector=require(script.Parent.EditInspector)
local View={}
function View.mount(widget,plugin)
 local c=Controller.create(plugin);local ui=UI.new(widget);local scopes={};local alive=true;local inspectorTab="Mix"
 local root=ui:frame(widget,{Name="MotionWorkspace",Size=UDim2.fromScale(1,1),ClipsDescendants=true})
 local header=ui:frame(root,{Size=UDim2.new(1,0,0,78)},"panel")
 ui:label(header,"FORGE  /  MOTION LAB",{Position=UDim2.fromOffset(12,8),Size=UDim2.fromOffset(182,24),TextSize=13,Font=Enum.Font.BuilderSansBold})
 local nameBox=ui:input(header,c.preset.name,{Position=UDim2.fromOffset(196,7),Size=UDim2.new(1,-478,0,28)},function(text)if #text>0 and #text<=80 then c:edit(function(p)p.name=text end)end end)
 local dirty=ui:label(header,"Unsaved",{Position=UDim2.fromOffset(12,46),Size=UDim2.fromOffset(100,20),TextSize=11},"muted")
 local status=ui:label(root,"Ready",{Position=UDim2.new(0,12,1,-24),Size=UDim2.new(1,-24,0,20),TextSize=11},"muted")
 local left=ui:frame(root,{Name="MotionBrowser"},"panel")
 local right=ui:frame(root,{Name="ContextInspector"},"panel")
 local center=ui:frame(root,{Name="MotionCanvas"},"canvas")
 local bottom=ui:frame(root,{Name="MotionTimeline"},"panel")
 local divider=ui:frame(root,{Size=UDim2.new(1,-16,0,4),Active=true},"line")
 local timelineHeight=236;local savedHeight=nil
 local function layout()
  local width=root.AbsoluteSize.X;local height=root.AbsoluteSize.Y;local lw=if width<1000 then 188 else 250;local rw=if width<1000 then 238 else 286
  local th=math.clamp(savedHeight or (if height<680 then 192 else timelineHeight),180,math.min(300,math.max(180,height-360)))
  left.Position=UDim2.fromOffset(8,86);left.Size=UDim2.new(0,lw,1,-th-122)
  right.Position=UDim2.new(1,-rw-8,0,86);right.Size=UDim2.new(0,rw,1,-th-122)
  center.Position=UDim2.fromOffset(lw+16,86);center.Size=UDim2.new(1,-lw-rw-32,1,-th-122)
  bottom.Position=UDim2.new(0,8,1,-th-28);bottom.Size=UDim2.new(1,-16,0,th)
  divider.Position=UDim2.new(0,8,1,-th-34)
 end
 local resizeStart=0;local timeline
 ui:dragInput(divider,function()resizeStart=bottom.AbsoluteSize.Y end,function(delta)savedHeight=math.clamp(resizeStart-delta.Y,180,300);layout()end,function()if timeline then timeline:refresh()end end)
 local title=ui:label(center,"Run",{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-104,0,24),TextSize=16,Font=Enum.Font.BuilderSansBold})
 local timeReadout=ui:label(center,"0.00s",{Position=UDim2.new(1,-98,0,10),Size=UDim2.fromOffset(86,18),TextSize=11,TextXAlignment=Enum.TextXAlignment.Right},"muted")
 local subtitle=ui:label(center,"Live R15 preview",{Position=UDim2.fromOffset(12,33),Size=UDim2.new(1,-24,0,18),TextSize=11},"muted")
 local viewport=ui:make("ViewportFrame",center,{Name="MainPreview",Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,1,-140),BackgroundTransparency=1,Ambient=Color3.fromRGB(165,174,192),LightColor=Color3.fromRGB(233,240,255),LightDirection=Vector3.new(-1,-1,-.5),BorderSizePixel=0})
 local world=Instance.new("WorldModel");world.Parent=viewport
 local camera=Instance.new("Camera");camera.FieldOfView=38;camera.Parent=viewport;viewport.CurrentCamera=camera
 local rig=Rig.new(world);local rigB=Rig.new(world,Color3.fromRGB(225,180,115));rigB.model.Parent=nil
 local ghostPrev=Rig.new(nil,Color3.fromRGB(99,164,217));local ghostNext=Rig.new(nil,Color3.fromRGB(174,195,129))
 for _,ghost in {ghostPrev,ghostNext}do for name,part in ghost.parts do part.Transparency=if name=="HumanoidRootPart"then 1 else .82 end end
 local grid=Instance.new("Folder");grid.Name="Grid";grid.Parent=world
 for i=-8,8 do for _,axis in {"x","z"}do local part=Instance.new("Part");part.Size=if axis=="x"then Vector3.new(16,.015,.025)else Vector3.new(.025,.015,16);part.CFrame=CFrame.new(if axis=="x"then Vector3.new(0,-.02,i)else Vector3.new(i,-.02,0));part.Anchored=true;part.CanCollide=false;part.Color=Color3.fromRGB(68,87,111);part.Transparency=if i==0 then .2 else .7;part.Parent=grid end end
 local path=Instance.new("Folder");path.Name="RootTrajectory";path.Parent=world
 local showGrid=true;local showRoot=true;local ghosts=false;local editPose=false;local mode="front";local yaw=math.pi;local pitch=.16;local distance=12;local orbit=false;local last=nil
 local function updateCamera()camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(yaw)*distance,2.2+math.sin(pitch)*distance,math.cos(yaw)*distance),Vector3.new(0,2.2,0))end;updateCamera()
 local refresh,refreshLibrary,refreshInspector;local thumbnailRigs={};local pathDirty=true
 local function state(message)
  if message then status.Text=message end
  nameBox.Text=c.preset.name;dirty.Text=if c.dirty then "● Unsaved" else "✓ Saved"
  local actual=S.resolveAsset(c.preset,c:asset(),c.library)
  title.Text=if c.sequenceMode then c:sequence().name else actual.name
  subtitle.Text=if c.compare then "A · original       B · current variant / mix" elseif c:variant() then "Editable variant · "..(c.selectedPart or "RightArm") elseif c.preset.clips[actual.grammar]then "Authored anatomy · "..c.preset.name else "Procedural starting block · "..c.preset.name
  pathDirty=true
 end
 local function action(fn,message)
  local ok,err=pcall(fn);state(if ok then message or "Updated" else tostring(err):gsub("^.-:%d+: ",""));if ok and refresh then refresh()end
 end
 local popup=nil;local popupUI=nil
 local function closeMenu()if popupUI then popupUI:dispose();popupUI=nil end;if popup then popup:Destroy();popup=nil end end
 local function menu(anchor,items,chosen)
  closeMenu();popupUI=UI.new(widget)
  local height=math.min(320,#items*28+8);local x=math.clamp(anchor.AbsolutePosition.X-widget.AbsolutePosition.X,8,math.max(8,root.AbsoluteSize.X-218));local y=math.clamp(anchor.AbsolutePosition.Y-widget.AbsolutePosition.Y+anchor.AbsoluteSize.Y+4,8,math.max(8,root.AbsoluteSize.Y-height-28))
  popup=popupUI:frame(root,{Size=UDim2.fromOffset(210,height),Position=UDim2.fromOffset(x,y),ZIndex=50},"hover")
  local scroll=popupUI:scroll(popup,{Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4),ZIndex=51})
  for i,item in items do popupUI:button(scroll,item.name,{Position=UDim2.fromOffset(0,(i-1)*28),Size=UDim2.new(1,-4,0,26),ZIndex=52},function()closeMenu();chosen(item.id)end)end
 end
 local function pick(anchor,items,fn)menu(anchor,items,function(id)action(function()fn(id)end)end)end
 ui:button(header,"Save",{Position=UDim2.new(1,-274,0,7),Size=UDim2.fromOffset(64,28)},function()action(function()c:save()end,"Profile + variants saved locally")end,true)
 ui:button(header,"Export",{Position=UDim2.new(1,-204,0,7),Size=UDim2.fromOffset(68,28)},function()action(function()assert(not game:GetService("RunService"):IsRunning(),"Export in Edit mode");local module=c:export(game:GetService("ServerStorage"));game:GetService("Selection"):Set({module})end,"Edited poses exported · inert data in ServerStorage")end)
 ui:button(header,"Attach R15",{Position=UDim2.new(1,-130,0,7),Size=UDim2.fromOffset(90,28)},function()action(function()assert(not game:GetService("RunService"):IsRunning(),"Attach in Edit mode");local selected=game:GetService("Selection"):Get()[1];assert(selected and selected:IsA("Model")and selected:FindFirstChild("Humanoid")and selected.Humanoid.RigType==Enum.HumanoidRigType.R15,"Select an R15 Model first");c:export(selected)end,"Data attached to R15")end)
 local more=ui:button(header,"⋯",{Position=UDim2.new(1,-34,0,7),Size=UDim2.fromOffset(26,28)})
 ui:connect(more.Activated,function()pick(more,{{id="duplicate",name="Duplicate profile"},{id="delete",name="Delete saved profile"},{id="import",name="Import selected export"}},function(id)
  if id=="duplicate"then c:duplicate()elseif id=="delete"then c.store:delete(c.preset.id);c:new(nil)else local selected=game:GetService("Selection"):Get()[1];assert(selected,"Select a Motion Lab export");c:import(selected)end
 end)end)
 local new=ui:button(header,"New profile",{Position=UDim2.fromOffset(112,44),Size=UDim2.fromOffset(84,24)})
 ui:connect(new.Activated,function()local items={{id="blank",name="Blank profile"}};for _,t in Library.Templates do table.insert(items,{id=t.id,name=t.name.." starting profile"})end;pick(new,items,function(id)c:new(if id=="blank"then nil else id)end)end)
 for i,spec in {{"↶",function()c:undo()end},{"↷",function()c:redo()end},{"Pin A",function()c:pinCompare()end},{"Clear A/B",function()c.compare=nil end},{"Mirror",function()c.mirror=not c.mirror end}}do local x=if i<3 then 202+(i-1)*28 else 266+(i-3)*72;local b=ui:button(header,spec[1],{Position=UDim2.fromOffset(x,44),Size=UDim2.fromOffset(if i<3 then 24 else 66,24)},function()action(spec[2])end);ui:tip(b,({"Undo profile / variant edit","Redo last edit","Freeze current motion as reference A","Return to one rig","Mirror preview; source data is unchanged"})[i])end
 local create=ui:button(header,"Create Variant",{Position=UDim2.new(1,-128,0,44),Size=UDim2.fromOffset(116,24)},function()action(function()c:createVariant();inspectorTab="Pose";editPose=true end,"Variant created · select a channel or key")end,true)
 ui:tip(create,"Add non-destructive pose/timing corrections to the selected motion.")
 local function scope(key,parent)
  if scopes[key]then scopes[key]:dispose()end;parent:ClearAllChildren();scopes[key]=UI.new(widget);return scopes[key]
 end
 local search="";local category="All";local page=1
 local categories={{"All","All"},{"Locomotion","Move"},{"Punches","Punch"},{"Kicks","Kick"},{"Knees","Knee"},{"Elbows","Elbow"},{"Palm","Palm"},{"Dodges","Dodge"},{"Aerial","Air"},{"Wall","Wall"},{"Reactions","React"},{"Other","Other"}}
 refreshLibrary=function()
  local u=scope("library",left);thumbnailRigs={}
  u:label(left,"MOTION BROWSER",{Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-20,0,22),TextSize=11,Font=Enum.Font.BuilderSansBold},"muted")
  local field=u:input(left,search,{Position=UDim2.fromOffset(8,32),Size=UDim2.new(1,-16,0,28),PlaceholderText="Search name / tags"})
  u:connect(field.FocusLost,function()search=field.Text:lower();page=1;refreshLibrary()end)
  for i,tab in {"Characters","Motions","Custom"}do u:button(left,tab,{Position=UDim2.new((i-1)/3,6,0,66),Size=UDim2.new(1/3,-8,0,25),TextSize=11},function()c.tab=tab;page=1;search="";refreshLibrary()end,c.tab==tab or (c.tab=="Library"and tab=="Motions"))end
  local isMotion=c.tab=="Motions"or c.tab=="Library";local y=100
  if isMotion then
   for i,cat in categories do u:button(left,cat[2],{Position=UDim2.new(((i-1)%4)/4,6,0,y+math.floor((i-1)/4)*24),Size=UDim2.new(1/4,-8,0,21),TextSize=10},function()category=cat[1];page=1;refreshLibrary()end,category==cat[1])end;y+=78
  end
  local rows={}
  if isMotion then
   local ids=table.clone(c.library.assetOrder);for id in c.preset.motionVariants or {}do table.insert(ids,id)end
   for _,id in ids do local a=c:asset(id);local other=not table.find({"Locomotion","Punches","Kicks","Knees","Elbows","Dodges","Aerial","Wall","Reactions"},a.category)
    local match=category=="All"or a.category==category or(category=="Palm"and a.grammar:find("Palm"))or(category=="Other"and other)
    local tags=table.concat(a.tags or {}," · ");if match and(search==""or(a.name.." "..tags):lower():find(search,1,true))then table.insert(rows,{id=id,name=a.name,desc=if a.variant then "Variant · "..c.preset.name else a.category.." · "..c.preset.name,asset=a})end
   end
  else
   for _,id in c.library.order do local p=c.library.presets[id];local custom=c.store.custom[id]~=nil;if (c.tab=="Custom")==custom and(search==""or p.name:lower():find(search,1,true))then table.insert(rows,{id=id,name=p.name,desc=if custom then "Saved profile + variants"elseif p.metadata.sourceType=="ninja-duel"then "Ninja Duel · authored"else "Starting expression",profile=p})end end
  end
  local pages=math.max(1,math.ceil(#rows/8));page=math.clamp(page,1,pages)
  local scroll=u:scroll(left,{Position=UDim2.fromOffset(6,y),Size=UDim2.new(1,-12,1,-y-66)})
  for index=(page-1)*8+1,math.min(page*8,#rows)do local row=rows[index];local i=index-(page-1)*8
   local card=u:button(scroll,"",{Position=UDim2.fromOffset(0,(i-1)*68),Size=UDim2.new(1,-4,0,62)},function()action(function()
    if isMotion then c.clip=row.id;c.sequenceMode=false;c.time=0;inspectorTab=if c:variant()then "Pose"else "Motion";c.selectedKey="Contact"else c:load(row.id);inspectorTab="Mix"end
   end)end,isMotion and c.clip==row.id)
   local thumb=u:make("ViewportFrame",card,{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(44,54),BackgroundTransparency=1,Ambient=Color3.fromRGB(170,182,201),LightColor=Color3.new(1,1,1),BorderSizePixel=0})
   local tw=Instance.new("WorldModel");tw.Parent=thumb;local tr=Rig.new(tw);local tc=Instance.new("Camera");tc.CFrame=CFrame.lookAt(Vector3.new(5,4,-8),Vector3.new(0,2.6,0));tc.FieldOfView=40;tc.Parent=thumb;thumb.CurrentCamera=tc
   local profile=row.profile or c.preset;local asset=row.asset or c.library.assets.jab;local ok,pose=pcall(S.sample,profile,asset,.42,c.library);if ok then Rig.apply(tr,pose,Vector3.new(0,3,0),false,false)end;table.insert(thumbnailRigs,tr)
   u:label(card,row.name,{Position=UDim2.fromOffset(54,5),Size=UDim2.new(1,-84,0,22),TextSize=12,Font=Enum.Font.BuilderSansBold})
   u:label(card,row.desc,{Position=UDim2.fromOffset(54,29),Size=UDim2.new(1,-62,0,18),TextSize=10},"muted")
   if isMotion then local add=u:button(card,"+",{Position=UDim2.new(1,-27,0,6),Size=UDim2.fromOffset(22,22)},function()action(function()c:addClip(row.id)end,"Added to sequence")end);u:tip(add,"Add "..row.name.." to the sequence")end
  end
  if #rows==0 then u:label(scroll,"No matching motions / saved profiles.",{Size=UDim2.new(1,-8,0,70),TextWrapped=true,TextSize=12},"muted")end
  u:button(left,"‹",{Position=UDim2.new(0,8,1,-60),Size=UDim2.fromOffset(28,22)},function()page=math.max(1,page-1);refreshLibrary()end)
  u:label(left,page.." / "..pages,{Position=UDim2.new(0,46,1,-60),Size=UDim2.new(1,-92,0,22),TextSize=11,TextXAlignment=Enum.TextXAlignment.Center},"muted")
  u:button(left,"›",{Position=UDim2.new(1,-36,1,-60),Size=UDim2.fromOffset(28,22)},function()page=math.min(pages,page+1);refreshLibrary()end)
  u:button(left,"Import selected export",{Position=UDim2.new(0,8,1,-30),Size=UDim2.new(1,-16,0,24),TextSize=11},function()action(function()local selected=game:GetService("Selection"):Get()[1];assert(selected,"Select an exported ModuleScript or JSON value");c:import(selected)end,"Imported from validated JSON")end)
 end
 refreshInspector=function()
  local u=scope("inspector",right)
  for i,tab in {"Mix","DNA","Pose","Motion","Advanced"}do local b=u:button(right,tab,{Position=UDim2.new((i-1)/5,4,0,6),Size=UDim2.new(1/5,-5,0,27),TextSize=10},function()inspectorTab=tab;refreshInspector()end,inspectorTab==tab);u:tip(b,tab.." · contextual motion controls")end
  local scroll=u:scroll(right,{Position=UDim2.fromOffset(10,42),Size=UDim2.new(1,-20,1,-52)})
  if inspectorTab=="Pose"or inspectorTab=="Motion"then
   EditInspector.mount(u,scroll,c,inspectorTab,action,state,menu)
  elseif inspectorTab=="Mix"then
   u:label(scroll,"Body Mixer",{Size=UDim2.new(1,0,0,24),TextSize=16,Font=Enum.Font.BuilderSansBold})
   u:label(scroll,"Layer sources → one expression",{Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,-4,0,20),TextSize=11},"muted")
   for i,layer in M.Layers do local y=52+(i-1)*94;local spec=c.preset.bodyLayers[layer]
    u:label(scroll,layer,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-44,0,20),Font=Enum.Font.BuilderSansMedium,TextSize=12})
    u:button(scroll,spec.enabled and "On"or "Off",{Position=UDim2.new(1,-38,0,y),Size=UDim2.fromOffset(34,20),TextSize=10},function()action(function()c:edit(function(p)p.bodyLayers[layer].enabled=not spec.enabled end)end)end,spec.enabled)
    local source=if spec.source=="base"then "Own profile"else c.library.presets[spec.source].name
    local select=u:button(scroll,source.." ▾",{Position=UDim2.fromOffset(0,y+23),Size=UDim2.new(1,-4,0,24),TextSize=11})
    u:connect(select.Activated,function()local choices={{id="base",name="Own profile"}};for _,id in c.library.order do if id~=c.preset.id then table.insert(choices,{id=id,name=c.library.presets[id].name})end end;pick(select,choices,function(id)c:edit(function(p)p.bodyLayers[layer].source=id end)end)end)
    u:slider(scroll,"Blend",0,1,spec.strength,y+49,function(n)c:edit(function(p)p.bodyLayers[layer].strength=n end,false);state()end,function()c:checkpoint()end)
   end
  elseif inspectorTab=="DNA"then
   u:button(scroll,"Generate movement set",{Size=UDim2.new(1,-4,0,32)},function()action(function()c:generate()end,"Suggested route generated; every block remains editable")end,true)
   local y=44;local group=nil
   for _,row in M.DNA do if group~=row[6] then group=row[6];u:label(scroll,group,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-6,0,24),Font=Enum.Font.BuilderSansBold});y+=30 end
    u:slider(scroll,row[2],row[3],row[4],c.preset.motionDNA[row[1]],y,function(value)c:edit(function(p)p.motionDNA[row[1]]=value end,false);state()end,function()c:checkpoint()end);y+=46 end

  else
   local text="Profile ID\n"..c.preset.id.."\n\nSource\n"..c.preset.metadata.sourceType.."\n\nRig\nR15 · anatomical joint controls\n\nExport\nNinjaDuel.MotionDefinitions.v1\nData only. No automatic apply.\n\nCharacter expression\n"..game:GetService("HttpService"):JSONEncode(c.preset.characterRules)
   u:label(scroll,text,{Size=UDim2.new(1,-8,0,260),TextSize=13,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
   u:label(scroll,"Character rules (JSON)",{Position=UDim2.fromOffset(0,266),Size=UDim2.new(1,-8,0,24),Font=Enum.Font.BuilderSansMedium})
   u:input(scroll,game:GetService("HttpService"):JSONEncode(c.preset.characterRules),{Position=UDim2.fromOffset(0,294),Size=UDim2.new(1,-8,0,74),MultiLine=true,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top},function(text)action(function()
    local rules=game:GetService("HttpService"):JSONDecode(text);local candidate=M.copy(c.preset);candidate.characterRules=rules;local valid,why=M.validate(candidate,c.library.presets);assert(valid,why);c:edit(function(p)p.characterRules=rules end)
   end,"Expression rules updated")end)
   for i,key in {"idle","walk","run","dash","jump","land","wall"} do
    local y=382+(i-1)*38;u:button(scroll,key,{Position=UDim2.fromOffset(0,y),Size=UDim2.fromOffset(60,28)},function()c.clip=if key=="wall" then "wallrun" else key;c.sequenceMode=false;c.time=0;state();timeline:refresh()end)
    local id=c.preset.locomotionSet[key] or key;local button=u:button(scroll,(c:asset(id) and c:asset(id).name or id).." ▾",{Position=UDim2.fromOffset(70,y),Size=UDim2.new(1,-78,0,28)})
    u:connect(button.Activated,function()local items={};for _,assetId in c.library.assetOrder do table.insert(items,{id=assetId,name=c.library.assets[assetId].name})end;for assetId,v in c.preset.motionVariants or {}do table.insert(items,{id=assetId,name=v.name})end;pick(button,items,function(chosen)c:edit(function(p)p.locomotionSet[key]=chosen end)end)end)
   end
  end
 end
 local function changed(message,rebuild,tab)if tab then inspectorTab=tab;editPose=tab=="Pose"end;state(message);if rebuild and refresh then refresh()end end
 timeline=Timeline.new(widget,bottom,c,changed)
 refresh=function()layout();state();refreshLibrary();refreshInspector();timeline:refresh()end
 ui:connect(root:GetPropertyChangedSignal("AbsoluteSize"),function()layout();timeline:refresh()end);ui:connect(bottom:GetPropertyChangedSignal("AbsoluteSize"),function()timeline:refresh()end);layout()
 local controls=ui:frame(center,{Position=UDim2.new(0,6,1,-78),Size=UDim2.new(1,-12,0,72),BackgroundTransparency=1})
 local play;play=ui:button(controls,"Pause",{Size=UDim2.new(1/4,-4,0,24)},function()c.playing=not c.playing;play.Text=if c.playing then "Pause"else "Play"end,true)
 local loop;loop=ui:button(controls,"Loop",{Position=UDim2.new(1/4,0,0,0),Size=UDim2.new(1/4,-4,0,24)},function()c.loop=not c.loop;loop.Text=if c.loop then "Loop"else "Once"end)
 local speed=ui:button(controls,"1×",{Position=UDim2.new(2/4,0,0,0),Size=UDim2.new(1/4,-4,0,24)})
 ui:connect(speed.Activated,function()pick(speed,{{id=".25",name="0.25×"},{id=".5",name="0.5×"},{id="1",name="1×"},{id="1.5",name="1.5×"},{id="2",name="2×"}},function(id)c.speed=tonumber(id);speed.Text=id.."×"end)end)
 local angle=ui:button(controls,"Front",{Position=UDim2.new(3/4,0,0,0),Size=UDim2.new(1/4,0,0,24)})
 ui:connect(angle.Activated,function()pick(angle,{{id="front",name="Front"},{id="side",name="Side"},{id="free",name="Free orbit"}},function(id)mode=id;angle.Text=if id=="free"then "Free"else id:gsub("^%l",string.upper);yaw=if id=="side"then math.pi/2 else math.pi;updateCamera()end)end)
 local gridButton;gridButton=ui:button(controls,"Grid ✓",{Position=UDim2.fromOffset(0,27),Size=UDim2.new(1/4,-4,0,22),TextSize=11},function()showGrid=not showGrid;grid.Parent=if showGrid then world else nil;gridButton.Text=showGrid and "Grid ✓"or "Grid"end)
 local rootButton;rootButton=ui:button(controls,"Root ✓",{Position=UDim2.new(1/4,0,0,27),Size=UDim2.new(1/4,-4,0,22),TextSize=11},function()showRoot=not showRoot;path.Parent=if showRoot then world else nil;rootButton.Text=showRoot and "Root ✓"or "Root"end)
 ui:tip(rootButton,"Show root movement + sampled trajectory. Motion tab edits travel and offsets.")
 local ghostButton;ghostButton=ui:button(controls,"Ghosts",{Position=UDim2.new(2/4,0,0,27),Size=UDim2.new(1/4,-4,0,22),TextSize=11},function()ghosts=not ghosts;ghostButton.Text=ghosts and "Ghosts ✓"or "Ghosts"end)
 local poseButton;poseButton=ui:button(controls,"Edit Pose",{Position=UDim2.new(3/4,0,0,27),Size=UDim2.new(1/4,0,0,22),TextSize=11},function()action(function()if not c:variant()then c:createVariant()end;editPose=not editPose;inspectorTab=if editPose then "Pose"else "Motion"end)end)
 ui:tip(poseButton,"Creates a variant if needed. Choose a body part, then use sliders or focused arrow nudges.")
 local partSelect=ui:button(controls,"Body part ▾",{Position=UDim2.fromOffset(0,52),Size=UDim2.new(.6,-4,0,20),TextSize=10})
 ui:connect(partSelect.Activated,function()local items={};for _,part in E.Parts do table.insert(items,{id=part,name=part})end;pick(partSelect,items,function(id)assert(c:variant(),"Create a variant first");c:selectKey(c.selectedKey or "Contact",id);inspectorTab="Pose";editPose=true end)end)
 ui:button(controls,"Reset time",{Position=UDim2.new(.6,0,0,52),Size=UDim2.new(.4,0,0,20),TextSize=10},function()c.time=0 end)
 ui:connect(viewport.InputBegan,function(input)if mode=="free"and(input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton1)then orbit=true;last=widget:GetRelativeMousePosition();local conn;conn=ui:connect(input.Changed,function()if input.UserInputState==Enum.UserInputState.End then orbit=false;conn:Disconnect()end end)end end)
 ui:connect(viewport.InputChanged,function(input)if input.UserInputType==Enum.UserInputType.MouseWheel then distance=math.clamp(distance-input.Position.Z,7,30);updateCamera()end end)
 local debt=0
 ui:connect(game:GetService("RunService").RenderStepped,function(dt)
  if not alive or not widget.Enabled then return end
  play.Text=if c.playing then "Pause"else "Play";poseButton.Text=editPose and "Pose ✓"or "Edit Pose"
  if orbit then local now=widget:GetRelativeMousePosition();local diff=now-last;last=now;yaw-=diff.X*.009;pitch=math.clamp(pitch+diff.Y*.006,-.15,.8);updateCamera()end
  debt+=dt;if debt<1/30 then return end;local tick=math.min(debt,.1);debt=0
  local total=math.max(.1,if c.sequenceMode then M.duration(c:sequence())/c.preset.motionDNA.recoverySpeed else S.duration(c.preset,c:asset(),c.library))
  if c.playing then c.time+=tick*c.speed;if c.time>=total then if c.loop then c.time%=total else c.time=total;c.playing=false end end end;c.time=math.clamp(c.time,0,total)
  timeReadout.Text=string.format("%.2f / %.2fs",c.time,total);partSelect.Text=(c.selectedPart or "Body part").." ▾";timeline:update(c.time,total)
  local function pose(p,reference,t)
   local lib=if reference then c.compareLibrary else c.library;local seqMode=if reference then c.compareSequenceMode else c.sequenceMode;local clip=if reference then c.compareClip else c.clip
   if seqMode then local seq=p.sequences[1]or {orderedClips={}};local duration=math.max(.1,M.duration(seq)/p.motionDNA.recoverySpeed);return S.sequence(p,seq,t*duration,lib,c.mirror)end
   return S.sample(p,E.asset(p,clip,lib),t,lib,c.mirror)
  end
  local ok,err=pcall(function()
   local t=c.time/total;local current=pose(c.preset,false,t)
   if c.loop and c.playing and c.time>total-.08 then current=S.blendPose(current,pose(c.preset,false,0),math.clamp((c.time-total+.08)/.08,0,1))end
   local origin=Vector3.new(if c.compare then 2.5 else 0,3,0)
   if c.compare then rigB.model.Parent=world;Rig.apply(rig,pose(c.compare,true,t),Vector3.new(-2.5,3,0),showRoot,c.compare.bodyLayers.Weapon.enabled);Rig.apply(rigB,current,origin,showRoot,c.preset.bodyLayers.Weapon.enabled)else rigB.model.Parent=nil;Rig.apply(rig,current,origin,showRoot,c.preset.bodyLayers.Weapon.enabled)end
   local v=c:variant();if ghosts and v and not c.sequenceMode then
    local keys=v.poseOverrides;local before,after=keys[1].time,keys[#keys].time;for _,key in keys do if key.time<t-.001 then before=key.time elseif key.time>t+.001 then after=key.time;break end end
    ghostPrev.model.Parent=world;ghostNext.model.Parent=world;Rig.apply(ghostPrev,pose(c.preset,false,before),origin,showRoot,false);Rig.apply(ghostNext,pose(c.preset,false,after),origin,showRoot,false)
   else ghostPrev.model.Parent=nil;ghostNext.model.Parent=nil end
   if pathDirty then
    path:ClearAllChildren();pathDirty=false
    if not c.sequenceMode then local previous=nil;for i=0,24 do local anatomy=S.mixedAnatomy(c.preset,c:asset(),i/24,c.library);if c.mirror then anatomy=S.mirror(anatomy)end;local r=anatomy.root or {};local point=origin+Vector3.new(r.x or 0,(r.y or 0)-2.65,r.z or 0)
     if previous and(point-previous).Magnitude>.001 then local segment=Instance.new("Part");segment.Name="RootPathSegment";segment.Anchored=true;segment.CanCollide=false;segment.CanQuery=false;segment.CanTouch=false;segment.Size=Vector3.new(.035,.035,(point-previous).Magnitude);segment.CFrame=CFrame.lookAt((point+previous)/2,point);segment.Color=Color3.fromRGB(104,181,230);segment.Parent=path end;previous=point
    end end
   end
  end)
  if not ok then c.playing=false;status.Text="Preview: "..tostring(err)end
 end)
 refresh();status.Text=c.store.notice or "Browse → Create Variant → select Contact → Pose / Motion → Save + Export"
 return function()alive=false;closeMenu();timeline:dispose();for _,s in scopes do s:dispose()end;ui:dispose();for _,r in {rig,rigB,ghostPrev,ghostNext}do r.model:Destroy()end;path:Destroy();grid:Destroy();world:Destroy();root:Destroy()end,c
end
return View
