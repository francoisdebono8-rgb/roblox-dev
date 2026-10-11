-- Adapter-owned character IDs. Core mixer/generator does not know Naruto names.
local M=require(script.Parent.Model)
local A={Format="NinjaDuel.MotionDefinitions.v1"}
function A.import(data,lib)
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  local def=data.fighters[id];if not def or not data.stances[id] then continue end
  local p=M.new(id,def.name);p.metadata={sourceType="ninja-duel",description="Authored Ninja Duel motion",characterSource=id};p.stance=M.copy(data.stances[id]);p.gait=M.copy(data.gaits[id]);p.clips={}
  for name,keys in data.clips[id] do
   local a=data.attacks[name] or data.attacks.DashAttack;local scale=def.attackProfile and def.attackProfile[name] or {}
   local startup=a.startup*(scale.startup or 1);local active=a.active*(scale.active or 1);local recovery=a.recovery*(scale.recovery or 1);local duration=startup+active+recovery
   local normalized={};for _,key in keys do
    local t=if key.at<=1 then key.at*startup elseif key.at<=2 then startup+(key.at-1)*active else startup+active+(key.at-2)*recovery
    table.insert(normalized,{at=math.clamp(t/duration,0,1),pose=M.copy(key.pose),ease=key.ease})
   end
   p.clips[name]={duration=duration,keys=normalized,gameTimeline=M.copy(keys)}
  end
  lib.presets[id]=p;table.insert(lib.order,1,id)
 end
 return lib
end
function A.serialize(bundle)
 assert(M.safe(bundle),"Unsafe export data")
 return game:GetService("HttpService"):JSONEncode(bundle)
end
function A.toLuau(value,depth)
 depth=depth or 0;assert(depth<24,"Export depth")
 if type(value)=="string" then return string.format("%q",value) elseif type(value)=="number" then assert(M.finite(value),"Invalid export number");return tostring(value) elseif type(value)=="boolean" then return tostring(value) elseif value==nil then return "nil" end
 assert(type(value)=="table","Unsupported export")
 local keys={};for key in value do table.insert(keys,key) end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local rows={};for _,key in keys do table.insert(rows,"["..A.toLuau(key,depth+1).."]="..A.toLuau(value[key],depth+1)) end
 return "{"..table.concat(rows,",").."}"
end
function A.bundle(preset,lib)
 local ok,why=M.validate(preset,lib.presets);assert(ok,why)
 local required={};local function gather(p,depth)
  assert(depth<9,"Source depth");for _,layer in p.bodyLayers do
   if layer.source~="base" and not required[layer.source] then local source=assert(lib.presets[layer.source],"Missing source");required[source.id]=M.copy(source);gather(source,depth+1) end
  end
 end;gather(preset,0)
 return {format=A.Format,version=1,baseRig="R15",preset=M.copy(preset),sources=required,assets=M.copy(lib.assets),automaticApply=false}
end
function A.export(preset,lib,parent)
 local bundle=A.bundle(preset,lib)
 local module=Instance.new("ModuleScript");module.Name=preset.name:gsub("[^%w_]","_").."_MotionProfile"
 module.Source="-- Forge Motion Lab: data only; no automatic gameplay integration.\nreturn "..A.toLuau(bundle)
 module.Parent=parent;return module,bundle
end
function A.read(instance,lib)
 -- JSON only; never evaluates a selected ModuleScript or foreign Source.
 local value=if instance:IsA("StringValue") then instance.Value else instance:GetAttribute("ForgeMotionLabJSON")
 assert(type(value)=="string" and #value<=2000000,"Select a Motion Lab JSON export")
 local data=game:GetService("HttpService"):JSONDecode(value);assert(M.safe(data) and data.format==A.Format and data.version==1,"Invalid export format")
 local all=M.copy(lib.presets);for id,p in data.sources or {} do all[id]=p end;all[data.preset.id]=data.preset
 local ok,why=M.validateGraph(all);assert(ok,why)
 for _,clip in data.preset.sequences do for _,block in clip.orderedClips do assert(lib.assets[block.asset],"Unknown motion block") end end
 return M.copy(data.preset),M.copy(data.sources or {})
end
return A
