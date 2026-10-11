local M=require(script.Parent.Model)
local Library=require(script.Parent.Library)
local Adapter=require(script.Parent.NinjaDuelAdapter)
local Store=require(script.Parent.Store)
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
function C:undo()
 if #self.history==0 then return end;table.insert(self.future,M.copy(self.preset));self.preset=table.remove(self.history);self.dirty=true;self.time=0
end
function C:redo()
 if #self.future==0 then return end;table.insert(self.history,M.copy(self.preset));self.preset=table.remove(self.future);self.dirty=true;self.time=0
end
function C:load(id)
 self:checkpoint();self.preset=M.copy(assert(self.library.presets[id],"Missing profile"));if not self.store.custom[id] then self.preset.id=self:newId();self.preset.name=self.preset.name.." study" end
 if #self.preset.sequences==0 then self.preset.sequences={{id="sequence1",name="Opening phrase",orderedClips={}}} end;self.dirty=self.store.custom[id]==nil;self.time=0
end
function C:new(template)
 self:checkpoint();self.preset=if template then M.copy(self.library.presets[template]) else M.new("new","Untitled motion")
 self.preset.id=self:newId();self.preset.name=if template then self.preset.name.." study" else "Untitled motion";self.preset=Library.propose(self.preset);self.dirty=true;self.time=0
end
function C:duplicate() self:checkpoint();self.preset.id=self:newId();self.preset.name=self.preset.name.." copy";self.dirty=true end
function C:generate() self:edit(function(p) local generated=Library.propose(p);p.locomotionSet=generated.locomotionSet;p.sequences=generated.sequences;p.metadata.generated=true end) end
function C:sequence() return self.preset.sequences[1] end
function C:addClip(id)
 local asset=assert(self.library.assets[id],"Unknown block");assert(#self:sequence().orderedClips<24,"Maximum 24 blocks")
 self:edit(function(p)table.insert(p.sequences[1].orderedClips,{asset=id,duration=math.clamp(asset.duration,.12,5),blend=.1,transition="blend"})end);self.selectedBlock=#self:sequence().orderedClips;self.sequenceMode=true
end
function C:save() self.store:save(self.preset);self.dirty=false end
function C:pinCompare() self.compare=M.copy(self.preset);self.compareLibrary={presets=M.copy(self.library.presets),assets=self.library.assets};self.compareSequenceMode=self.sequenceMode;self.compareClip=self.clip end
function C:export(parent)
 local bundle=Adapter.bundle(self.preset,self.library);local payload=Adapter.serialize(bundle);assert(#payload<=2000000,"Export too large")
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
 self:checkpoint();p.id=self:newId();self.preset=p;self.dirty=true;self.time=0
end
return C
