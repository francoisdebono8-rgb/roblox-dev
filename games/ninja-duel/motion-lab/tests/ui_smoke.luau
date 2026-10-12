-- Real Roblox instance/property schemas; simulated Studio events, no rendering gate.
local fs=require("@lune/fs");local serde=require("@lune/serde");local r=require("@lune/roblox")
local process=require("@lune/process")
local artifact=process.args[1] or "motion-lab/dist/ForgeMotionLab.rbxm"
local root=r.deserializeModel(fs.readFile(artifact))[1]
assert(root.Name=="ForgeMotionLab")
local moduleCount=0
for _,source in root.Modules:GetChildren()do
 moduleCount+=1;assert(source:IsA("ModuleScript"));assert(source.Source==fs.readFile("motion-lab/ForgeMotionLab/Modules/"..source.Name..".luau"),"Binary source mismatch")
end
assert(moduleCount==#fs.readDir("motion-lab/ForgeMotionLab/Modules"))
assert(root.Main.Source==fs.readFile("motion-lab/ForgeMotionLab/Main.plugin.luau"))
local signals={};local totalCallbacks=0
local function signal()
 local s={callbacks={}};table.insert(signals,s)
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;table.insert(self.callbacks,{fn=fn,c=c});totalCallbacks+=1;return c end
 function s:Fire(...)for _,pair in table.clone(self.callbacks)do if pair.c.Connected then pair.fn(...)end end end
 return s
end
for _,spec in {{"GuiObject","MouseEnter"},{"GuiObject","MouseLeave"},{"GuiObject","InputBegan"},{"GuiObject","InputChanged"},{"GuiButton","Activated"},{"TextBox","FocusLost"}}do
 local values={};r.implementProperty(spec[1],spec[2],function(i)if not values[i]then values[i]=signal()end;return values[i]end)
end
local propertySignals={}
r.implementMethod("Instance","GetPropertyChangedSignal",function(i,key)
 propertySignals[i]=propertySignals[i] or {};propertySignals[i][key]=propertySignals[i][key] or signal();return propertySignals[i][key]
end)
local mouse=r.Vector2.zero
r.implementMethod("DockWidgetPluginGui","GetRelativeMousePosition",function()return mouse end)
local absoluteSize=function(i)
 if i:IsA("DockWidgetPluginGui") then return r.Vector2.new(i:GetAttribute("TestWidth") or 1180,i:GetAttribute("TestHeight") or 780)end
 if not i.Parent or not i.Parent:IsA("GuiBase2d")then return r.Vector2.zero end
 local p=i.Parent.AbsoluteSize;return r.Vector2.new(p.X*i.Size.X.Scale+i.Size.X.Offset,p.Y*i.Size.Y.Scale+i.Size.Y.Offset)
end
local absolutePosition=function(i)
 if i:IsA("DockWidgetPluginGui") or not i.Parent or not i.Parent:IsA("GuiBase2d")then return r.Vector2.zero end
 local p=i.Parent.AbsoluteSize;local pos=i.Parent.AbsolutePosition;local size=i.AbsoluteSize
 return pos+r.Vector2.new(p.X*i.Position.X.Scale+i.Position.X.Offset-size.X*i.AnchorPoint.X,p.Y*i.Position.Y.Scale+i.Position.Y.Offset-size.Y*i.AnchorPoint.Y)
end
for _,class in {"GuiObject","DockWidgetPluginGui","Frame","TextLabel","TextButton","TextBox","ViewportFrame","ScrollingFrame"} do r.implementProperty(class,"AbsoluteSize",absoluteSize);r.implementProperty(class,"AbsolutePosition",absolutePosition)end
local instanceFactory={new=function(class)
 local i=r.Instance.new(class);if i:IsA("GuiBase2d") then i.AbsoluteSize=r.Vector2.new(1180,780);i.AbsolutePosition=r.Vector2.zero end;return i
end}
local render=signal();local guid=0;local dark=true;local selection={}
local http={JSONDecode=function(_,value)return serde.decode("json",value)end,JSONEncode=function(_,value)return serde.encode("json",value)end,GenerateGUID=function()guid+=1;return "native-ui-"..guid end}
local studio={ThemeChanged=signal(),Theme={GetColor=function()return if dark then r.Color3.new(.1,.1,.1) else r.Color3.new(.9,.9,.9)end}}
local serverStorage=r.Instance.new("Folder");serverStorage.Name="ServerStorage"
local services={HttpService=http,RunService={RenderStepped=render,IsRunning=function()return false end},ServerStorage=serverStorage,Selection={Get=function()return selection end,Set=function(_,v)selection=v end},ChangeHistoryService={TryBeginRecording=function()return "test-recording"end,FinishRecording=function()end}}
local cache={};local load
load=function(module)
 if cache[module]~=nil then return cache[module]end
 local fn=assert(loadstring(module.Source,module.Name));setfenv(fn,setmetatable({script=module,require=load,game={GetService=function(_,name)return assert(services[name],name)end},settings=function()return {Studio=studio}end,Instance=instanceFactory,Enum=r.Enum,CFrame=r.CFrame,Vector3=r.Vector3,Vector2=r.Vector2,Color3=r.Color3,UDim2=r.UDim2,UDim=r.UDim,task={defer=function(fn)fn()end}},{__index=getfenv()}))
 cache[module]=fn();return cache[module]
end
local stored={};local plugin={GetSetting=function(_,key)return stored[key]end,SetSetting=function(_,key,v)stored[key]=v end}
local widget=instanceFactory.new("DockWidgetPluginGui");widget.Enabled=true
local dispose,c=load(root.Modules.View).mount(widget,plugin)
local function button(text)
 for _,object in widget:GetDescendants()do if object:IsA("TextButton") and object.Text==text then return object end end
 error("Missing button: "..text)
end
local function click(text)button(text).Activated:Fire()end
local function tick(n)for _=1,n or 3 do render:Fire(1/30)end end
tick(20);assert(#widget:GetDescendants()>200)
local viewport
for _,o in widget:GetDescendants()do if o.ClassName=="ViewportFrame" and o.Name=="MainPreview"then viewport=o end end
assert(viewport and viewport:FindFirstChildWhichIsA("WorldModel"))
click("DNA");click("Generate movement set");assert(#c:sequence().orderedClips==3)
click("Pin A");local pinned=c.compare.id;click("Mirror");assert(c.mirror)
click("Pause");assert(not c.playing);click("Play");tick()
click("Save");assert(c.store.custom[c.preset.id])
click("Export");assert(selection[1]:IsA("ModuleScript"));local json=selection[1].MotionLabJSON.Value;assert(serde.decode("json",json).ninjaDuel.clips.Light1)
click("Import selected export");assert(c.dirty and c.compare.id==pinned);click("Save")
click("Advanced");click("idle");assert(c.clip=="idle");tick()
click("Motions");c.clip="idle";click("+ Block");assert(c.sequenceMode);tick()
-- New editor exercised from exact packaged source, with simulated mouse drags.
click("Create Variant");local variantId=c.clip;assert(c:variant() and c.compare and not c.sequenceMode)
local function object(name)
 for _,o in widget:GetDescendants()do if o.Name==name then return o end end;error("Missing UI object: "..name)
end
local function inputNamed(name,text)local field=object(name);field.Text=text;field.FocusLost:Fire()end
local function inputLabel(label,text)
 for _,o in widget:GetDescendants()do if o:IsA("TextLabel") and o.Text==label then
  local field=o.Parent:FindFirstChildWhichIsA("TextBox");assert(field,"Missing slider value");field.Text=text;field.FocusLost:Fire();return
 end end;error("Missing slider: "..label)
end
inputLabel("Shoulder raise","35");assert(c:variant().poseOverrides[3].parts.RightArm.raise==35)
tick();click("↶");assert(not c:variant().poseOverrides[3].parts.RightArm);click("↷");assert(c:variant().poseOverrides[3].parts.RightArm.raise==35)
click("Motion");inputNamed("VariantName","Idle_Wide");inputNamed("Timing_Duration (s)","1.2");inputLabel("Amplitude","1.4");inputLabel("Forward travel","1.5")
assert(c:variant().name=="Idle_Wide" and c:variant().timing.duration==1.2 and c:variant().motionModifiers.amplitude==1.4);tick()
click("Ghosts");tick();assert(viewport:FindFirstChildWhichIsA("WorldModel"):FindFirstChild("RootTrajectory"))
local function dragObject(name,dx)
 local target=object(name);local changed=signal();local input={UserInputType=r.Enum.UserInputType.MouseButton1,UserInputState=r.Enum.UserInputState.Begin,Changed=changed}
 mouse=r.Vector2.zero;target.InputBegan:Fire(input);mouse=r.Vector2.new(dx,0);tick(1);input.UserInputState=r.Enum.UserInputState.End;changed:Fire();mouse=r.Vector2.zero
end
local before=c:variant().poseOverrides[3].time;dragObject("Marker_Contact",20);assert(c:variant().poseOverrides[3].time>before)
click("Pose");click("RightArm ▾");click("RightLeg");inputLabel("Hip raise","25");assert(c:variant().poseOverrides[3].parts.RightLeg.lift==25);tick()
click("Save");click("Export");local data=serde.decode("json",selection[1].MotionLabJSON.Value);assert(data.ninjaDuel.clips[variantId] and data.preset.motionVariants[variantId].name=="Idle_Wide")
click("Import selected export");local imported=c.preset.motionVariants[variantId];assert(imported and imported.poseOverrides[3].parts.RightLeg.lift==25);click("Save")
-- Restore the saved variant from the custom library and then add it to a phrase.
c.clip=variantId;click("+ Block");assert(c.sequenceMode);dragObject("BlockResize_"..c.selectedBlock,30);tick();click("Edit motion");assert(not c.sequenceMode)
click("New profile");click("Gaara starting profile");assert(c.preset.name=="Gaara study" and c.preset.motionDNA.amplitude==.35);tick()
click("Clear A/B");assert(c.compare==nil);click("Ghosts ✓");tick()
-- Bilateral browser/independent sides and edited common export on exact binary.
click("New profile");click("Blank profile");click("Motions")
object("CollectionFilter").Activated:Fire();click("Common bilateral")
object("FamilyFilter").Activated:Fire();click("Roundhouse")
local function selectMotion(text)
 for _,o in widget:GetDescendants()do if o:IsA("TextLabel")and o.Text==text then o.Parent.Activated:Fire();return end end;error("Missing motion card: "..text)
end
selectMotion("Roundhouse · L · Rotational");assert(c.clip=="common_roundhouse_L_Rotational");tick()
object("CompareLegacy").Activated:Fire();assert(c.compareClip=="roundhouse");tick()
object("SwitchSide").Activated:Fire();assert(c.clip=="common_roundhouse_R_Rotational");tick()
object("SideFilter").Activated:Fire();click("Right");assert(object("SideFilter").Text=="Right ▾")
click("Create Variant");local bilateralId=c.clip;assert(c.selectedPart=="RightLeg" and c:variant());inputLabel("Hip raise","18");tick()
click("Motion");inputNamed("Timing_Contact (s)","0.55");inputLabel("Hip rotation","1.15");tick();click("Save");click("Export")
local bilateral=serde.decode("json",selection[1].MotionLabJSON.Value);assert(bilateral.preset.motionVariants[bilateralId].poseOverrides[3].parts.RightLeg.lift==18 and bilateral.ninjaDuel.clips[bilateralId] and bilateral.assets.common_roundhouse_R_Rotational)
click("Import selected export");assert(c.preset.motionVariants[bilateralId]);click("Clear A/B");tick()
-- Reference source templates are editable immediately, not demo-only cards.
click("New profile");click("Combat reference study (neutral DNA)")
assert(c.clip=="ref_jab_L_Base" and c.preset.motionDNA.amplitude==1 and c.tab=="Motions")
assert(object("CollectionFilter").Text=="Reference ▾" and object("Marker_Ready") and object("Marker_Acceleration"))
object("FamilyFilter").Activated:Fire();click("Roundhouse")
selectMotion("Roundhouse · L · Base");assert(c.clip=="ref_roundhouse_L_Base" and c.selectedPart=="LeftLeg")
inputLabel("Hip raise","6");local edit=load(root.Modules.MotionEdit)
assert(edit.phase(c:variant(),"Contact").parts.LeftLeg.lift==6)
click("Motion");inputNamed("Timing_Acceleration (s)","0.33")
assert(edit.phase(c:variant(),"Acceleration").time>.34)
local acceleration=edit.phase(c:variant(),"Acceleration").time;dragObject("Marker_Acceleration",-8)
assert(edit.phase(c:variant(),"Acceleration").time<acceleration)
object("CompareLegacy").Activated:Fire();assert(c.compareClip=="common_roundhouse_L_Standard")
click("Save");click("Export");local reference=serde.decode("json",selection[1].MotionLabJSON.Value)
assert(reference.preset.motionVariants.ref_roundhouse_L_Base.phaseSchema=="combat-six")
assert(reference.ninjaDuel.motionMetadata.ref_roundhouse_L_Base.phaseMarkers.Acceleration)
object("SwitchSide").Activated:Fire();assert(c.clip=="ref_roundhouse_R_Base")
click("Create Variant");assert(c:variant().sourceAsset=="ref_roundhouse_R_Base_source")
click("Save");click("Export");click("Import selected export")
assert(c.preset.motionVariants.ref_roundhouse_L_Base and c:asset("ref_roundhouse_L_Base").counterpart=="ref_roundhouse_R_Base")
click("Clear A/B");tick()
widget:SetAttribute("TestWidth",780);widget:SetAttribute("TestHeight",600)
local host=widget:GetChildren()[1];host:GetPropertyChangedSignal("AbsoluteSize"):Fire()
widget.AbsoluteSize=r.Vector2.new(780,600)
local function reflow(parent)
 for _,child in parent:GetChildren()do if child:IsA("GuiObject")then child.AbsoluteSize=absoluteSize(child);child.AbsolutePosition=absolutePosition(child);reflow(child)end end
end
host.AbsoluteSize=absoluteSize(host);host:GetPropertyChangedSignal("AbsoluteSize"):Fire();reflow(widget)
assert(object("MotionCards").AbsoluteSize.Y>=62,"Collapsed motion browser at minimum size")
local rootButton=button("Root ✓");assert(rootButton.AbsolutePosition.X+rootButton.AbsoluteSize.X<=widget.AbsoluteSize.X)
dark=false;studio.ThemeChanged:Fire();tick()
for _,o in widget:GetDescendants()do if o:IsA("TextLabel")then assert(not o.Text:match("^Preview:"),o.Text)end end
local motorCount=0
for _,o in viewport:GetDescendants()do if o:IsA("Motor6D")then motorCount+=1;assert(o.Part0 and o.Part1 and o.Part1.CFrame.Position.X==o.Part1.CFrame.Position.X)end end
assert(motorCount==15)
dispose()
for _,s in signals do for _,pair in s.callbacks do assert(not pair.c.Connected,"Leaked UI connection")end end
print("PASS exact binary UI: legacy workflows + variant pose/timing/amplitude, marker/block drags, ghosts, edited export/import, bilateral and reference filters / six-phase edits / L-R / legacy comparison / edited export, 780 layout and teardown (simulated Studio events)")
print("Registered and released UI connections: "..totalCallbacks)
