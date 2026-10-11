local E=require(script.Parent.MotionEdit)
local S=require(script.Parent.Sampler)
local Panel={}
function Panel.mount(u,scroll,c,tab,action,state,menu)
 local v=c:variant();local asset=c:asset()
 local function heading(text,y)u:label(scroll,text,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-4,0,24),Font=Enum.Font.BuilderSansBold,TextSize=14})end
 if not v then
  heading("Create a motion variant",0)
  u:label(scroll,(if asset.authoredClip then asset.side.." · Attack: "..asset.attackingLimb.."\nBrace: "..asset.supportLimb.." · "..asset.stance.."\nCreate an editable copy; source stays intact."else "Keep the original intact. Add pose corrections, timing and travel to a named variant."),{Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,-4,0,66),TextWrapped=true,TextSize=12},"muted")
  u:button(scroll,"Create Variant",{Position=UDim2.fromOffset(0,108),Size=UDim2.new(1,-4,0,32)},function()action(function()c:createVariant()end,"Variant created · source pinned as A")end,true)
  return
 end
 u:input(scroll,v.name,{Name="VariantName",Size=UDim2.new(1,-4,0,28)},function(text)action(function()assert(#text>0 and #text<=80,"Name: 1–80 characters");c:variantEdit(function(x)x.name=text end)end,"Variant renamed")end)
 local source=u:label(scroll,(if asset.authoredClip then asset.attackingLimb.." · brace "..asset.supportLimb else "Source · "..c.library.assets[v.sourceAsset].name),{Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,-4,0,20),TextSize=11},"muted")
 u:tip(source,c.library.assets[v.sourceAsset].name.." · "..(asset.attackingLimb or "Mixed body").." / support "..(asset.supportLimb or "profile").." · "..(asset.stance or "profile"))
 if tab=="Pose" then
  local key=E.key(v,c.selectedKey or "Contact");if not key then c.selectedKey="Contact";key=E.key(v,"Contact")end
  local part=c.selectedPart or "RightArm";c.selectedPart=part
  local select=u:button(scroll,(key.semantic or "Extra pose").." ▾",{Position=UDim2.fromOffset(0,60),Size=UDim2.new(.55,-4,0,26)})
  u:connect(select.Activated,function()local items={};for _,k in v.poseOverrides do table.insert(items,{id=k.id,name=(k.semantic or "Extra pose")..string.format("  %.3fs",k.time*S.duration(c.preset,c:asset(),c.library))})end;menu(select,items,function(id)action(function()c:selectKey(id)end)end)end)
  local partButton=u:button(scroll,part.." ▾",{Position=UDim2.new(.55,2,0,60),Size=UDim2.new(.45,-6,0,26)})
  u:connect(partButton.Activated,function()local choices={};for _,name in E.Parts do table.insert(choices,{id=name,name=name})end;menu(partButton,choices,function(id)action(function()c:selectKey(key.id,id)end)end)end)
  heading("Pose deltas · "..part,98)
  u:label(scroll,"Degrees / studs relative to the mixed base.",{Position=UDim2.fromOffset(0,122),Size=UDim2.new(1,-4,0,20),TextSize=11},"muted")
  local controls=E.Controls[part];local y=148;local controlRows={}
  for _,row in controls do
   local value=(key.parts[part] or {})[row[1]] or 0
   controlRows[row[1]]=u:slider(scroll,row[2],row[3],row[4],value,y,function(n)local ok,err=pcall(function()c:setPose(row[1],n,false)end);state(ok and nil or tostring(err))end,function()c:checkpoint()end)
   y+=46
  end
  heading("Fine nudge",y+4)
  local selectedField=controls[1][1];local fieldButton=u:button(scroll,controls[1][2].." ▾",{Position=UDim2.fromOffset(0,y+34),Size=UDim2.new(1,-86,0,26)})
  u:connect(fieldButton.Activated,function()local choices={};for _,row in controls do table.insert(choices,{id=row[1],name=row[2]})end;menu(fieldButton,choices,function(id)selectedField=id;fieldButton.Text=id.." ▾"end)end)
  local function nudge(sign,quiet)
   local function apply()
    local current=E.key(c:variant(),c.selectedKey);local value=(current.parts[part] or {})[selectedField] or 0;local control
    for _,row in controls do if row[1]==selectedField then control=row end end
    c:setPose(selectedField,math.clamp(value+sign*(if table.find({"x","y","z"},selectedField)then .05 else 1),control[3],control[4]))
   end
   if quiet then local ok,err=pcall(apply);state(ok and nil or tostring(err));if ok then
    local current=E.key(c:variant(),c.selectedKey);local field=controlRows[selectedField]:FindFirstChildWhichIsA("TextBox");field.Text=string.format("%.2f",current.parts[part][selectedField])
   end else action(apply)end
  end
  u:button(scroll,"−",{Position=UDim2.new(1,-78,0,y+34),Size=UDim2.fromOffset(34,26)},function()nudge(-1)end)
  u:button(scroll,"+",{Position=UDim2.new(1,-38,0,y+34),Size=UDim2.fromOffset(34,26)},function()nudge(1)end)
  -- Keyboard nudges are scoped to this focused editor; they never bind gameplay keys.
  local keyboard=u:input(scroll,"",{Name="NudgeKeys",Position=UDim2.fromOffset(0,y+68),Size=UDim2.new(1,-4,0,26),PlaceholderText="Focus here: ↑ / ↓ to nudge"})
  u:connect(keyboard.InputBegan,function(input)if input.KeyCode==Enum.KeyCode.Up then nudge(1,true)elseif input.KeyCode==Enum.KeyCode.Down then nudge(-1,true)end end)
  u:button(scroll,"Reset this part",{Position=UDim2.fromOffset(0,y+104),Size=UDim2.new(1,-4,0,28)},function()action(function()c:variantEdit(function(x)local k=E.key(x,c.selectedKey);assert(not(x.channels[part] and x.channels[part].locked),"Channel locked");k.parts[part]=nil end)end,"Pose corrections reset")end)
  u:label(scroll,"Leg edits use FK; foot edits use planted-foot IK. Hips share the anatomical root rotation.",{Position=UDim2.fromOffset(0,y+140),Size=UDim2.new(1,-4,0,58),TextWrapped=true,TextSize=11},"muted")
 else
  u:button(scroll,v.enabled and "Edits enabled ✓" or "Edits bypassed",{Position=UDim2.fromOffset(0,60),Size=UDim2.new(.6,-4,0,26)},function()action(function()c:variantEdit(function(x)x.enabled=not x.enabled end)end)end,v.enabled)
  u:button(scroll,"Assign",{Position=UDim2.new(.6,4,0,60),Size=UDim2.new(.4,-8,0,26)},function()action(function()c:assignVariant()end,"Assigned to source slot in this profile")end)
  heading("Timing",98)
  local function number(label,value,y,fn)
   u:label(scroll,label,{Position=UDim2.fromOffset(0,y),Size=UDim2.new(1,-90,0,26),TextSize=12})
   u:input(scroll,string.format("%.3f",value),{Name="Timing_"..label,Position=UDim2.new(1,-86,0,y),Size=UDim2.fromOffset(82,26)},function(text)action(function()local n=tonumber(text);assert(n and n==n,"Enter a finite number");fn(n)end)end)
  end
  number("Duration (s)",v.timing.duration,126,function(n)assert(n>=.12 and n<=30,"Duration: 0.12–30s");c:variantEdit(function(x)x.timing.duration=n end)end)
  local markers=E.markers(v)
  for i,label in {"Anticipation","Contact","Recovery start"}do local marker=markers[i+1];number(label.." (s)",marker.time*v.timing.duration,160+(i-1)*32,function(n)c:variantEdit(function(x)local current=E.key(x,marker.id);E.moveKeys(x,{[marker.id]=true},n/x.timing.duration-current.time)end);c:selectKey(marker.id)end)end
  number("Contact hold (norm)",v.timing.hold,258,function(n)assert(n>=0 and n<=.3,"Hold: 0–0.3 normalized");c:variantEdit(function(x)x.timing.hold=n end)end)
  number("Playback speed",v.timing.playbackSpeed,290,function(n)assert(n>=.25 and n<=3,"Speed: 0.25–3");c:variantEdit(function(x)x.timing.playbackSpeed=n end)end)
  local ease=u:button(scroll,"Easing · "..v.timing.easing.." ▾",{Position=UDim2.fromOffset(0,324),Size=UDim2.new(1,-4,0,26)})
  u:connect(ease.Activated,function()local choices={};for _,name in E.Easing do table.insert(choices,{id=name,name=name})end;menu(ease,choices,function(id)action(function()c:variantEdit(function(x)x.timing.easing=id end)end)end)end)
  heading("Exaggerate · whole motion",366)
  local y=396
  for _,row in E.Modifiers do u:slider(scroll,row[2],0,3,v.motionModifiers[row[1]],y,function(n)c:variantEdit(function(x)x.motionModifiers[row[1]]=n end,false);state()end,function()c:checkpoint()end);y+=46 end
  heading("Root trajectory",y+8);y+=38
  for _,row in {{"forward","Forward travel",-10,10},{"lateral","Lateral travel",-10,10},{"lift","Vertical lift",-10,10},{"turn","Turn / yaw",-360,360},{"startX","Start X",-10,10},{"startY","Start Y",-10,10},{"startZ","Start Z",-10,10},{"endX","End X",-10,10},{"endY","End Y",-10,10},{"endZ","End Z",-10,10}}do
   u:slider(scroll,row[2],row[3],row[4],v.rootPath[row[1]],y,function(n)c:variantEdit(function(x)x.rootPath[row[1]]=n end,false);state()end,function()c:checkpoint()end);y+=46
  end
 end
end
return Panel
