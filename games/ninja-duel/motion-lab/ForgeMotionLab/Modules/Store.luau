local M=require(script.Parent.Model)
local Store={};Store.__index=Store
local KEY="ForgeMotionLab.presets.v1"
function Store.new(plugin,library)
 local self=setmetatable({plugin=plugin,library=library,builtins=M.copy(library.presets),custom={},writable=true,notice=nil},Store)
 local ok,raw=pcall(function()return plugin:GetSetting(KEY)end)
 if not ok then self.writable=false;self.notice="Preset settings unavailable; export before closing.";return self end
 if raw~=nil then
  if type(raw)~="string" or #raw>2000000 then self.writable=false;self.notice="Preset settings invalid/too large; preserved.";return self end
  local decoded,data=pcall(function()return game:GetService("HttpService"):JSONDecode(raw)end)
  if not decoded or type(data)~="table" or data.version~=1 or not M.safe(data.presets) then self.writable=false;self.notice="Saved data could not be read. It has been preserved.";return self end
  local graph=M.copy(library.presets);for id,p in data.presets do if self.builtins[id] then self.writable=false;self.notice="Saved library collides with bundled sources; data preserved.";return self end;graph[id]=p end
  local valid,why=M.validateGraph(graph)
  if not valid then self.writable=false;self.notice=why..". Existing settings preserved.";return self end
  for _,p in data.presets do local good,reason=M.validateAssets(p,library.assets);if not good then self.writable=false;self.notice=reason..". Saved data preserved.";return self end end
  self.custom=M.copy(data.presets);for id,p in self.custom do library.presets[id]=M.copy(p);table.insert(library.order,id) end
 end
 return self
end
function Store:save(preset)
 assert(self.writable,self.notice)
 local valid,reason=M.validateAssets(preset,self.library.assets);assert(valid,reason)
 local all=M.copy(self.library.presets);all[preset.id]=preset;local ok,why=M.validateGraph(all);assert(ok,why)
 assert(not self.builtins[preset.id],"Duplicate a bundled profile before saving")
 local nextCustom=M.copy(self.custom);nextCustom[preset.id]=M.copy(preset)
 local function gather(p,seen)
  seen[p.id]=true
  for _,layer in p.bodyLayers do
   if layer.source~="base" and not self.builtins[layer.source] and not seen[layer.source] then
    local source=assert(self.library.presets[layer.source],"Missing saved source");nextCustom[source.id]=M.copy(source);gather(source,seen)
   end
  end
 end;gather(preset,{})
 local payload=game:GetService("HttpService"):JSONEncode({version=1,presets=nextCustom});assert(#payload<=2000000,"Preset storage full; export a library first")
 self.plugin:SetSetting(KEY,payload);self.custom=nextCustom;self.library.presets[preset.id]=M.copy(preset)
 if not table.find(self.library.order,preset.id) then table.insert(self.library.order,preset.id) end
 return true
end
function Store:delete(id)
 assert(self.writable and self.custom[id],"Only custom presets can be deleted")
 for other,p in self.library.presets do if other~=id then for _,layer in p.bodyLayers do assert(layer.source~=id,"This profile is used by "..p.name) end end end
 local nextCustom=M.copy(self.custom);nextCustom[id]=nil
 self.plugin:SetSetting(KEY,game:GetService("HttpService"):JSONEncode({version=1,presets=nextCustom}));self.custom=nextCustom;self.library.presets[id]=nil
 local at=table.find(self.library.order,id);if at then table.remove(self.library.order,at) end
end
return Store
