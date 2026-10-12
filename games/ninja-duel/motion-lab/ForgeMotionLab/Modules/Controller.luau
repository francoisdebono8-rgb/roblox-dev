local M=require(script.Parent.Model)
local Library=require(script.Parent.Library)
local Adapter=require(script.Parent.NinjaDuelAdapter)
local Store=require(script.Parent.Store)
local Edit=require(script.Parent.MotionEdit)
local Sampler=require(script.Parent.Sampler)
local C={};C.__index=C
function C.create(plugin)
 local lib=Library.new();Adapter.import(require(script.Parent.NinjaSources),lib)
 local self=setmetatable({library=lib,store=Store.new(plugin,lib),history={},future={},counter=0,dirty=false,clip="run",tab="Characters",playing=true,loop=true,speed=1,time=0,sequenceMode=false,mirror=false,compare=nil,selectedBlock=1},C)
 self.preset=M.copy(lib.presets.Flashstep);self.preset.id=self:newId();self.preset.name="Minato × Itachi"
 for _,layer in {"Torso","LeftArm","RightArm"} do self.preset.bodyLayers[layer].source="Mirage" end;self.preset.bodyLayers.Head.source="GentleFist"
 self.preset.sequences={{id="sequence1",name="Opening phrase",orderedClips={}}};self.dirty=true
 return self
end
function C:newId() self.counter+=1;return "custom_"..game:GetService("HttpService"):GenerateGUID(false):gsub("%-","") end
function C:checkpoint() table.insert(self.history,M.copy(self.preset));if #self.history>40 then table.remove(self.history,1) end;self.future={} end
function C:edit(fn,record) if record~=false then self:checkpoint() end;fn(self.preset);self.dirty=true;self.time=0 end
function C:repairSelection() if not self:asset() then self.clip="run";self.selectedKey=nil end end
function C:undo()
 if #self.history==0 then return end;table.insert(self.future,M.copy(self.preset));self.preset=table.remove(self.history);self.dirty=true;self.time=0;self:repairSelection()
end
function C:redo()
 if #self.future==0 then return end;table.insert(self.history,M.copy(self.preset));self.preset=table.remove(self.future);self.dirty=true;self.time=0;self:repairSelection()
end
function C:load(id)
 self:checkpoint();self.preset=M.copy(assert(self.library.presets[id],"Missing profile"));self.clip="run";self.sequenceMode=false;self.selectedKey=nil;if not self.store.custom[id] then self.preset.id=self:newId();self.preset.name=self.preset.name.." study" end
 if #self.preset.sequences==0 then self.preset.sequences={{id="sequence1",name="Opening phrase",orderedClips={}}} end;self.dirty=self.store.custom[id]==nil;self.time=0
end
function C:new(template)
 self.clip="run";self.sequenceMode=false;self.selectedKey=nil
 self:checkpoint();self.preset=if template then M.copy(self.library.presets[template]) else M.new("new","Untitled motion")
 self.preset.id=self:newId();self.preset.name=if template then self.preset.name.." study" else "Untitled motion";self.preset=Library.propose(self.preset);self.dirty=true;self.time=0
end
function C:duplicate() self:checkpoint();self.preset.id=self:newId();self.preset.name=self.preset.name.." copy";self.dirty=true end
function C:generate() self:edit(function(p) local generated=Library.propose(p);p.locomotionSet=generated.locomotionSet;p.sequences=generated.sequences;p.metadata.generated=true end) end
function C:sequence() return self.preset.sequences[1] end
function C:addClip(id)
 local asset=assert(Edit.asset(self.preset,id,self.library),"Unknown block");assert(#self:sequence().orderedClips<24,"Maximum 24 blocks")
 self:edit(function(p)table.insert(p.sequences[1].orderedClips,{asset=id,duration=math.clamp(asset.duration,.12,5),blend=.1,transition="blend"})end);self.selectedBlock=#self:sequence().orderedClips;self.sequenceMode=true
end
function C:asset(id) return Edit.asset(self.preset,id or self.clip,self.library) end
function C:variant() return Edit.variant(self.preset,self:asset()) end
function C:createVariant()
 local source=self:asset();assert(not source.variant or source.referenceBacked,"Select a source motion to create a variant")
 self.sequenceMode=false;self:pinCompare();local id=self:newId();local clip=source.authoredClip or self.preset.clips[source.grammar];local duration=Sampler.duration(self.preset,source,self.library)
 local contact,recovery=.42,.7;if clip and clip.timing then contact=clip.timing.startup/clip.duration;recovery=(clip.timing.startup+clip.timing.active)/clip.duration end
 self:edit(function(p)
  p.motionVariants=p.motionVariants or {};local v=if source.referenceBacked then M.copy(assert(self:variant()))else Edit.create(id,source.name.."_A",source,duration,contact,recovery);v.id=id;v.name=source.name.."_A"
  if source.authoredClip and not source.referenceBacked then
   for _,key in source.authoredClip.keys do if key.phase=="Anticipation"then v.poseOverrides[2].time=key.at;v.poseOverrides[2].sourceTime=key.at end end
  end
  p.motionVariants[id]=v
 end)
 self.clip=id;self.sequenceMode=false;self.selectedKey="Contact";self.selectedPart=if source.attackingLimb=="LeftArm"then "LeftArm"elseif source.attackingLimb=="LeftLeg"then "LeftLeg"elseif source.attackingLimb=="RightLeg"then "RightLeg"else "RightArm";self.playing=false;self.time=Edit.phase(self:variant(),"Contact").time*duration
 return id
end
function C:switchSide()
 local source=self:asset();assert(source.counterpart and self.library.assets[source.counterpart],"No opposite-side asset")
 self.clip=source.counterpart;self.sequenceMode=false;self.time=0;self.mirror=false;self.selectedKey=nil
end
function C:compareLegacy()
 local source=self:asset();assert(source.legacyAsset and self.library.assets[source.legacyAsset],"No legacy comparison")
 local selected=self.clip;self.clip=source.legacyAsset;self:pinCompare();self.clip=selected;self.sequenceMode=false;self.time=0;self.mirror=false
end
function C:variantEdit(fn,record)
 assert(self:variant(),"Create a variant before editing")
 local template=M.copy(self:variant());local at=self.time
 self:edit(function(p)p.motionVariants=p.motionVariants or {};p.motionVariants[self.clip]=p.motionVariants[self.clip]or template;fn(p.motionVariants[self.clip])end,record);self.time=at
end
function C:selectKey(id,part)
 local v=assert(self:variant(),"Select a variant");local key=assert(Edit.key(v,id),"Missing key")
 self.selectedKey=id;self.selectedPart=part or self.selectedPart or "Root";self.playing=false;self.sequenceMode=false;self.time=key.time*Sampler.duration(self.preset,self:asset(),self.library)
end
function C:setPose(field,value,record)
 local part=self.selectedPart or "Root";local control=nil;for _,row in Edit.Controls[part] or {} do if row[1]==field then control=row end end;assert(control and M.finite(value) and value>=control[3] and value<=control[4],"Invalid pose value");local v=assert(self:variant());assert(not(v.channels[part] and v.channels[part].locked),"Channel is locked")
 self:variantEdit(function(variant)local key=assert(Edit.key(variant,self.selectedKey));key.parts[part]=key.parts[part] or {};key.parts[part][field]=value end,record)
end
function C:assignVariant(slot)
 local variant=assert(self:variant(),"Select a variant");self:edit(function(p)p.locomotionSet[slot or variant.sourceAsset]=self.clip end)
end
function C:save()
 if self:asset().variantDefinition and not(self.preset.motionVariants and self.preset.motionVariants[self.clip])then self:variantEdit(function()end)end
 self.store:save(self.preset);self.dirty=false
end
function C:pinCompare() self.compare=M.copy(self.preset);self.compareLibrary={presets=M.copy(self.library.presets),assets=self.library.assets};self.compareSequenceMode=self.sequenceMode;self.compareClip=self.clip end
function C:export(parent)
 local bundle=Adapter.bundle(self.preset,self.library,self.clip);local payload=Adapter.serialize(bundle);assert(#payload<=2000000,"Export too large")
 local history=game:GetService("ChangeHistoryService");local recording=history:TryBeginRecording("ForgeMotionLabExport","Export Motion Lab profile")
 assert(recording,"Finish the current Studio operation first")
 local module
 local ok,result=pcall(function()
  local folder=parent:FindFirstChild("ForgeMotionLabExports");if not folder then folder=Instance.new("Folder");folder.Name="ForgeMotionLabExports";folder.Parent=parent end
  assert(folder:IsA("Folder"),"ForgeMotionLabExports name occupied by another instance")
  module=Adapter.export(self.preset,self.library,folder,bundle)
  local json=Instance.new("StringValue");json.Name="MotionLabJSON";json.Value=payload;json.Parent=module
  module:SetAttribute("ForgeMotionLabFormat",Adapter.Format);return module
 end)
 history:FinishRecording(recording,if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel)
 assert(ok,result);return result
end
function C:import(instance)
 local p,sources=Adapter.read(instance,self.library)
 -- Always remap imported snapshots: no bundled/live source is overwritten.
 local ids={};for id in sources do ids[id]=self:newId() end
 local function remap(profile)
  for _,layer in profile.bodyLayers do if ids[layer.source] then layer.source=ids[layer.source] end end
 end
 remap(p)
 for oldId,source in sources do source.id=ids[oldId];remap(source);source.metadata.imported=true;self.library.presets[source.id]=source;table.insert(self.library.order,source.id) end
 self:checkpoint();p.id=self:newId();self.preset=p;self.clip="run";self.selectedKey=nil;self.sequenceMode=false;self.dirty=true;self.time=0
end
return C
