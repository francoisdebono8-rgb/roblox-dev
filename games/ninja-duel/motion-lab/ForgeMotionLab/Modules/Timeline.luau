-- Full-width channel timeline. Data gestures use one undo checkpoint per drag.
local UI=require(script.Parent.UI)
local E=require(script.Parent.MotionEdit)
local M=require(script.Parent.Model)
local S=require(script.Parent.Sampler)
local T={};T.__index=T
function T.new(widget,parent,c,changed)
 return setmetatable({widget=widget,parent=parent,c=c,changed=changed,zoom=1,multi=false,selection={},connections={}},T)
end
function T:dispose()if self.ui then self.ui:dispose()end end
function T:refresh()
 local c=self.c;local parent=self.parent;self:dispose();parent:ClearAllChildren();local u=UI.new(self.widget);self.ui=u
 local variant=c:variant();local seq=c:sequence();local sequenceMode=c.sequenceMode
 local function action(fn,msg)local ok,err=pcall(fn);self.changed(ok and msg or tostring(err),true)end
 u:label(parent,sequenceMode and "SEQUENCE" or "POSE CHANNELS",{Position=UDim2.fromOffset(12,4),Size=UDim2.fromOffset(145,28),TextSize=11,Font=Enum.Font.BuilderSansBold},"accent")
 u:button(parent,sequenceMode and "Edit motion" or "Sequence",{Position=UDim2.fromOffset(154,6),Size=UDim2.fromOffset(94,24)},function()c.sequenceMode=not c.sequenceMode;c.time=0;self.changed(nil,true)end)
 u:button(parent,"+ Block",{Position=UDim2.fromOffset(256,6),Size=UDim2.fromOffset(72,24)},function()action(function()c:addClip(c.clip)end,"Block added")end)
 u:button(parent,"+ Key",{Position=UDim2.fromOffset(336,6),Size=UDim2.fromOffset(62,24)},function()action(function()
  assert(variant,"Create a variant first");local id=c:newId();c:variantEdit(function(v)E.addKey(v,id,c.time/S.duration(c.preset,c:asset(),c.library))end);c:selectKey(id)
 end,"Pose key added")end)
 u:button(parent,self.multi and "Multi ✓" or "Multi",{Position=UDim2.fromOffset(406,6),Size=UDim2.fromOffset(68,24)},function()self.multi=not self.multi;self.selection={};self:refresh()end,self.multi)
 local zoom=u:button(parent,"−",{Position=UDim2.new(1,-122,0,6),Size=UDim2.fromOffset(26,24)},function()self.zoom=math.max(1,self.zoom/1.5);self:refresh()end)
 u:tip(zoom,"Zoom out. Horizontal scrollbar appears when zoomed.")
 u:button(parent,"+",{Position=UDim2.new(1,-90,0,6),Size=UDim2.fromOffset(26,24)},function()self.zoom=math.min(8,self.zoom*1.5);self:refresh()end)
 u:button(parent,"Fit",{Position=UDim2.new(1,-58,0,6),Size=UDim2.fromOffset(46,24)},function()self.zoom=1;self:refresh()end)
 local total=math.max(.1,if sequenceMode then M.duration(seq)/c.preset.motionDNA.recoverySpeed else S.duration(c.preset,c:asset(),c.library))
 local labelWidth=146;local width=math.max(360,parent.AbsoluteSize.X-labelWidth-38)*self.zoom;self.width=width;self.total=total
 local rows=if sequenceMode then 2 else #E.Parts
 local area=u:make("ScrollingFrame",parent,{Name="TimelineCanvas",Position=UDim2.fromOffset(10,38),Size=UDim2.new(1,-20,1,-76),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.fromOffset(labelWidth+width+18,38+rows*24),ScrollingDirection=Enum.ScrollingDirection.XY})
 self.area=area
 for i=0,10 do local x=labelWidth+width*i/10;u:frame(area,{Position=UDim2.fromOffset(x,24),Size=UDim2.fromOffset(1,rows*24+10)},"line");u:label(area,string.format("%.2f",total*i/10),{Position=UDim2.fromOffset(x-12,0),Size=UDim2.fromOffset(42,18),TextSize=10},"muted")end
 local scrub=u:make("TextButton",area,{Name="TimeRuler",Position=UDim2.fromOffset(labelWidth,0),Size=UDim2.fromOffset(width,22),Text="",BackgroundTransparency=1,ZIndex=3})
 local startTime=0
 u:dragInput(scrub,function()local mouse=self.widget:GetRelativeMousePosition();local x=mouse.X-(scrub.AbsolutePosition.X-self.widget.AbsolutePosition.X);startTime=math.clamp(x/width,0,1)*total;c.time=startTime;c.playing=false end,function(delta)c.time=math.clamp(startTime+delta.X/width*total,0,total)end,function()self.changed(nil,false)end)
 if sequenceMode then
  u:label(area,"Motion blocks",{Position=UDim2.fromOffset(2,31),Size=UDim2.fromOffset(136,25),TextSize=12},"muted")
  local cursor=0
  for i,block in seq.orderedClips do
   local asset=c:asset(block.asset);local bWidth=block.duration/c.preset.motionDNA.recoverySpeed/total*width;local start=cursor/total*width
   local b=u:button(area,asset.name,{Name="SequenceBlock_"..i,Position=UDim2.fromOffset(labelWidth+start,29),Size=UDim2.fromOffset(math.max(14,bWidth-3),42),TextSize=12},nil,i==c.selectedBlock)
   u:tip(b,"Drag to reorder; drag the right edge to change duration.")
   local original;local target=i
   u:dragInput(b,function()original=self.widget:GetRelativeMousePosition().X;c.selectedBlock=i;c:checkpoint()end,function(delta)
    b.Position=UDim2.fromOffset(labelWidth+math.clamp(start+delta.X,0,width-bWidth),29)
    local centre=(start+delta.X+bWidth*.5)/width*total;local sum=0;target=#seq.orderedClips
    for index,other in seq.orderedClips do sum+=other.duration/c.preset.motionDNA.recoverySpeed;if centre<=sum then target=index;break end end
   end,function()action(function()if target~=i then c:edit(function(p)M.reorder(p.sequences[1],i,target)end,false);c.selectedBlock=target end end,"Block selected")end)
   local edge=u:button(b,"",{Name="BlockResize_"..i,Position=UDim2.new(1,-7,0,0),Size=UDim2.new(0,7,1,0),ZIndex=5},nil,true)
   local length=block.duration
   u:dragInput(edge,function()length=block.duration;c:checkpoint()end,function(delta)c:edit(function(p)p.sequences[1].orderedClips[i].duration=math.clamp(length+delta.X/width*total*c.preset.motionDNA.recoverySpeed,.12,5)end,false)end,function()self.changed("Block retimed",true)end)
   cursor+=block.duration/c.preset.motionDNA.recoverySpeed
  end
  if #seq.orderedClips==0 then u:label(area,"Add motions from the browser to build a phrase.",{Position=UDim2.fromOffset(labelWidth+8,30),Size=UDim2.fromOffset(width-16,36),TextSize=12},"muted")end
 else
  local keys=if variant then variant.poseOverrides else {}
  if not variant then
   local authored=c.preset.clips[c:asset().grammar];local contact=.42;local recovery=.7;if authored and authored.timing then contact=authored.timing.startup/authored.duration;recovery=(authored.timing.startup+authored.timing.active)/authored.duration end
   keys=E.create("preview","Preview",c:asset(),total,contact,recovery).poseOverrides
  end
  for i,part in E.Parts do local y=28+(i-1)*24
   local channel=variant and variant.channels[part] or {};local label=u:button(area,part,{Position=UDim2.fromOffset(0,y),Size=UDim2.fromOffset(94,22),TextSize=11},function()if variant then c:selectKey(c.selectedKey or "Contact",part);self.changed(nil,true,"Pose")end end,part==c.selectedPart)
   u:tip(label,"Select this body channel. Corrections are additive to the source pose.")
   for j,flag in {"muted","locked"}do local b=u:button(area,flag=="muted" and "M" or "L",{Position=UDim2.fromOffset(96+(j-1)*22,y),Size=UDim2.fromOffset(20,22),TextSize=10},function()action(function()c:variantEdit(function(v)v.channels[part]=v.channels[part] or {muted=false,locked=false};v.channels[part][flag]=not v.channels[part][flag]end)end)end,channel[flag]);u:tip(b,flag=="muted" and "Mute pose corrections on this channel" or "Lock this channel against edits")end
   for _,key in keys do
    local selected=(c.selectedKey==key.id and c.selectedPart==part) or self.selection[key.id]
    local has=next(key.parts[part] or {})~=nil
    local diamond=u:button(area,"",{Name="PoseKey_"..part.."_"..key.id,Position=UDim2.fromOffset(labelWidth+key.time*width-5,y+7),Size=UDim2.fromOffset(10,10),Rotation=45,ZIndex=5,BackgroundTransparency=if has or selected then 0 else .6},nil,selected)
    u:tip(diamond,(key.semantic or "Extra pose").." · "..part..string.format(" · %.3fs",key.time*total))
    local origin=0;local previous=0;local ids={}
    u:dragInput(diamond,function()
     if not variant then self.changed("Create a variant to edit keys",false);return end
     c:selectKey(key.id,part);if self.multi then self.selection[key.id]=not self.selection[key.id]else self.selection={[key.id]=true}end
     ids=table.clone(self.selection);if not next(ids)then ids[key.id]=true end;origin=key.time;previous=0;c:checkpoint()
    end,function(delta)
     if not variant then return end
     local requested=delta.X/width;local moved=0;c:variantEdit(function(v)moved=E.moveKeys(v,ids,requested-previous)end,false);previous+=moved
     local now=E.key(c:variant(),key.id);diamond.Position=UDim2.fromOffset(labelWidth+now.time*width-5,y+7);c.time=now.time*total
    end,function()if variant then self.changed("Key selected / retimed",true,"Pose")end end)
   end
  end
  -- Names stay separate from the channel diamonds, and are draggable semantic markers.
  for _,key in keys do if key.semantic then
   local marker=u:button(area,key.semantic,{Name="Marker_"..key.id,Position=UDim2.fromOffset(labelWidth+key.time*width-32,17),Size=UDim2.fromOffset(64,12),TextSize=9,ZIndex=6},nil,key.id==c.selectedKey)
   local previous=0
   u:dragInput(marker,function()if variant then c:selectKey(key.id);c:checkpoint();previous=0 end end,function(delta)if variant then local moved=0;c:variantEdit(function(v)moved=E.moveKeys(v,{[key.id]=true},delta.X/width-previous)end,false);previous+=moved;local now=E.key(c:variant(),key.id);marker.Position=UDim2.fromOffset(labelWidth+now.time*width-32,17);c.time=now.time*total end end,function()if variant then self.changed("Semantic marker retimed",true,"Motion")end end)
  end end
 end
 self.playhead=u:frame(area,{Name="Playhead",Position=UDim2.fromOffset(labelWidth,0),Size=UDim2.fromOffset(2,rows*24+35),ZIndex=7,Active=false},"accent")
 local detail=u:label(parent,"",{Position=UDim2.new(0,12,1,-30),Size=UDim2.new(1,-270,0,24),TextSize=11},"muted");self.detail=detail
 if sequenceMode then
  local selected=seq.orderedClips[c.selectedBlock]
  self.detail.Size=UDim2.fromOffset(152,24)
  local name=u:input(parent,seq.name,{Name="SequenceName",Position=UDim2.new(0,172,1,-30),Size=UDim2.fromOffset(138,24)},function(text)action(function()assert(#text>0 and #text<=64,"Name: 1–64 characters");c:edit(function(p)p.sequences[1].name=text end)end)end)
  if selected then
   u:input(parent,string.format("%.3f",selected.duration),{Name="BlockDuration",Position=UDim2.new(0,318,1,-30),Size=UDim2.fromOffset(62,24)},function(text)action(function()local n=tonumber(text);assert(n and n>=.12 and n<=5,"Block duration: 0.12–5s");c:edit(function(p)p.sequences[1].orderedClips[c.selectedBlock].duration=n end)end)end)
   u:input(parent,string.format("%.3f",selected.blend),{Name="BlockBlend",Position=UDim2.new(0,388,1,-30),Size=UDim2.fromOffset(62,24)},function(text)action(function()local n=tonumber(text);assert(n and n>=0 and n<=.5,"Blend: 0–0.5s");c:edit(function(p)p.sequences[1].orderedClips[c.selectedBlock].blend=n end)end)end)
   u:button(parent,selected.transition=="blend" and "Blend" or "Cut",{Position=UDim2.new(0,458,1,-30),Size=UDim2.fromOffset(56,24)},function()action(function()c:edit(function(p)local b=p.sequences[1].orderedClips[c.selectedBlock];b.transition=if b.transition=="blend"then "cut"else "blend"end)end)end)
   u:button(parent,"Remove block",{Position=UDim2.new(0,522,1,-30),Size=UDim2.fromOffset(98,24)},function()action(function()c:edit(function(p)table.remove(p.sequences[1].orderedClips,c.selectedBlock)end);c.selectedBlock=math.max(1,c.selectedBlock-1)end)end)
   u:tip(name,"Sequence name; following fields are duration and transition blend in seconds.")
  end
 elseif variant then
  u:button(parent,"Delete key",{Position=UDim2.new(1,-104,1,-30),Size=UDim2.fromOffset(92,24)},function()action(function()c:variantEdit(function(v)local k,i=E.key(v,c.selectedKey);assert(k and not k.semantic,"Keep the five semantic keys");table.remove(v.poseOverrides,i)end);c:selectKey("Contact")end,"Extra key removed")end)
  local stretch=u:input(parent,"1.2",{Position=UDim2.new(1,-244,1,-30),Size=UDim2.fromOffset(45,24)})
  u:button(parent,"Stretch",{Position=UDim2.new(1,-193,1,-30),Size=UDim2.fromOffset(76,24)},function()action(function()local factor=tonumber(stretch.Text);assert(factor and factor>=.25 and factor<=3,"Stretch: 0.25–3");c:variantEdit(function(v)
   local anchor=1;for _,key in v.poseOverrides do if self.selection[key.id]then anchor=math.min(anchor,key.time)end end
   assert(anchor<1,"Use Multi to select keys first")
   local targets={};for _,key in v.poseOverrides do if self.selection[key.id] then assert(not key.semantic or (key.semantic~="Start" and key.semantic~="Recovery"),"Keep boundary keys fixed");targets[key.id]=anchor+(key.time-anchor)*factor end end
   local previous=-1;for _,key in v.poseOverrides do local t=targets[key.id] or key.time;assert(t-previous>=.002 and t<=1,"Stretch would cross another key");previous=t end
   for _,key in v.poseOverrides do key.time=targets[key.id] or key.time end
  end)end,"Selected key timing stretched")end)
 end
 self:update(c.time,total)
end
function T:update(time,total)
 if self.playhead then self.playhead.Position=UDim2.fromOffset(146+math.clamp(time/math.max(.1,total),0,1)*self.width,0)end
 if self.detail then local c=self.c;local v=c:variant();local key=v and E.key(v,c.selectedKey);self.detail.Text=string.format("%.3f / %.3fs",time,total)..(if key then "   · "..(key.semantic or "Extra pose").." / "..(c.selectedPart or "Root") else "   · Drag ruler to scrub / diamonds to retime")end
end
return T
