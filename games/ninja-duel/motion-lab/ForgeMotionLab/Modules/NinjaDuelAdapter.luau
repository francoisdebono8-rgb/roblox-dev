-- Adapter-owned character IDs. Core mixer/generator does not know Naruto names.
local M=require(script.Parent.Model)
local Sampler=require(script.Parent.Sampler)
local Edit=require(script.Parent.MotionEdit)
local A={Format="NinjaDuel.MotionDefinitions.v1"}
function A.import(data,lib)
 local index=0
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  local def=data.fighters[id];if not def or not data.stances[id] then continue end
  local p=M.new(id,def.name);p.metadata={sourceType="ninja-duel",description="Authored Ninja Duel motion",characterSource=id};p.stance=M.copy(data.stances[id]);p.stance.weapon={roll=if id=="Flashstep" then -35 elseif id=="Mirage" then 15 else 0};p.gait=M.copy(data.gaits[id]);p.clips={}
  -- Preserve renderer inheritance explicitly; legacy imports without metadata
  -- retain their previous direct-clip behavior. Source keyframes stay single-copy.
  local effective={};local origins={}
  local function gather(sourceId,seen)
   assert(not seen[sourceId],"Cyclic clip inheritance");seen[sourceId]=true
   local parent=data.clipInheritance and data.clipInheritance[sourceId]
   if parent then gather(parent,seen) end
   for name,keys in data.clips[sourceId] or {} do effective[name]=keys;origins[name]=sourceId end
  end
  gather(id,{})
  p.metadata.motionClipSources=origins
  for name,keys in effective do
   local a=data.attacks[name] or data.attacks.DashAttack;local scale=def.attackProfile and def.attackProfile[name] or {}
   local startup=a.startup*(scale.startup or 1);local active=a.active*(scale.active or 1);local recovery=a.recovery*(scale.recovery or 1);local exact=data.timings and data.timings[id] and data.timings[id][name];if exact then startup,active,recovery=exact.startup,exact.active,exact.recovery end;local duration=startup+active+recovery
   local normalized={};for _,key in keys do
    local t=if key.at<=1 then key.at*startup elseif key.at<=2 then startup+(key.at-1)*active else startup+active+(key.at-2)*recovery
    table.insert(normalized,{at=math.clamp(t/duration,0,1),pose=M.copy(key.pose),ease=key.ease})
   end
   p.clips[name]={duration=duration,keys=normalized,timing={startup=startup,active=active,recovery=recovery},gameTimeline=M.copy(keys)}
  end
  lib.presets[id]=p;index+=1;table.insert(lib.order,index,id)
 end
 local mapped={};for _,asset in lib.assets do mapped[asset.grammar]=true end
 local names={};for _,profile in lib.presets do for name in profile.clips do if not mapped[name] then mapped[name]=true;table.insert(names,name)end end end;table.sort(names)
 for _,name in names do
  local category=if name:match("^Air") then "Aerial" elseif name:match("^Wall") then "Wall" elseif name:find("Sweep") or name:find("Kick") then "Kicks" elseif name:match("^Throw") then "Grabs" elseif name:find("Step") then "Transitions" elseif name=="Riposte" then "Counters" else "Punches"
  local id="ninja_"..name;local duration=.65;for _,p in lib.presets do if p.clips[name] then duration=p.clips[name].duration;break end end
  lib.assets[id]={id=id,name=name:gsub("(%l)(%u)","%1 %2"),category=category,grammar=name,tags={category,"NinjaDuel"},compatibleBodyLayers=M.copy(M.Layers),defaultSpeed=1,duration=duration,contactMarkers={},rootPolicy="presentation",styleTags={"authored"},sourceType="ninja-duel",proceduralDefinition={kind=name}}
  table.insert(lib.assetOrder,id)
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
-- Preserve legacy exports; materialize only selected/referenced common clips.
-- A growing catalogue must not overflow Studio's 2 MB JSON import budget.
function A.exportIds(preset,lib,selected)
 local ids={};for _,id in lib.assetOrder do if not lib.assets[id].authoredClip then ids[id]=true end end
 local function include(id)
  if not id or ids[id]then return end;local a=Edit.asset(preset,id,lib);if not a then return end;ids[id]=true
  local v=Edit.variant(preset,a);if v then include(v.sourceAsset)end
  if a.metadata then include(a.metadata.fromAsset);include(a.metadata.toAsset)end
 end
 include(selected);for _,id in preset.locomotionSet do include(id)end
 for _,seq in preset.sequences do for _,block in seq.orderedClips do include(block.asset)end end
 for id in preset.motionVariants or {}do include(id)end
 local result={};for id in ids do table.insert(result,id)end;table.sort(result);return result
end
function A.ninjaDefinitions(preset,lib,selected)
 -- Same anatomy and 0..3 phase convention as VelmoraMotionEngine CLIPS.
 -- Export is deliberately inert; Claude chooses whether/where to use these tables.
 local function layerGait(p,layer,depth)
  assert(depth<9,"Source depth");local result=M.copy(p.gait);local spec=p.bodyLayers[layer]
  if spec.enabled and spec.source~="base" then local other=layerGait(lib.presets[spec.source],layer,depth+1);for key,value in other do result[key]=(result[key] or value)+(value-(result[key] or value))*spec.strength end end
  return result
 end
 local lower=layerGait(preset,"Legs",0);local upperLeft=layerGait(preset,"LeftArm",0);local upperRight=layerGait(preset,"RightArm",0);local hips=layerGait(preset,"Hips",0)
 local gait=M.copy(preset.gait);gait.stride=(lower.stride or 1)*preset.motionDNA.stepLength*preset.motionDNA.lowerActivity;gait.cadence=(lower.cadence or 1)*preset.motionDNA.cadence*preset.motionDNA.strideFrequency;gait.arm=((upperLeft.arm or 35)+(upperRight.arm or 35))*.5*preset.motionDNA.upperActivity;gait.bob=hips.bob or 1
 local out={id=preset.id,stance=Sampler.mixedAnatomy(preset,lib.assets.idle,0,lib),gait=gait,clips={},timings={},motionMetadata={},generated=true,automaticApply=false}
 local exportIds=A.exportIds(preset,lib,selected)
 for _,assetId in exportIds do
  local asset=Edit.asset(preset,assetId,lib);local actual=Sampler.resolveAsset(preset,asset,lib);local authored=actual.authoredClip or preset.clips[actual.grammar]
  local timing=if authored and authored.timing then authored.timing else {startup=asset.duration*.32,active=asset.duration*.2,recovery=asset.duration*.48}
  if actual.authoredClip then local scale=Sampler.duration(preset,actual,lib)/actual.authoredClip.duration;timing={startup=timing.startup*scale,active=timing.active*scale,recovery=timing.recovery*scale}end
  local variant=Edit.variant(preset,actual)
  if variant then local contactKey=Edit.phase(variant,"Contact");local followKey=Edit.phase(variant,"FollowThrough");local length=Sampler.duration(preset,actual,lib);local contact=if variant.enabled then contactKey.time else contactKey.sourceTime;local recovery=if variant.enabled then followKey.time else followKey.sourceTime;timing={startup=contact*length,active=(recovery-contact)*length,recovery=(1-recovery)*length} end
  local duration=timing.startup+timing.active+timing.recovery;local keys={}
  local samples={}
  if actual.authoredClip and not variant then
   for _,key in actual.authoredClip.keys do samples[key.at]=true end
  else for i=0,24 do samples[i/24]=true end end
  if variant then for _,key in variant.poseOverrides do samples[key.time]=true end;local contact=Edit.phase(variant,"Contact").time;samples[contact+math.min(variant.timing.hold,Edit.phase(variant,"FollowThrough").time-contact-.002)]=true end
  local times={};for t in samples do table.insert(times,t)end;table.sort(times)
  for _,t in times do
   local elapsed=t*duration
   local phase=if elapsed<=timing.startup then elapsed/timing.startup elseif elapsed<=timing.startup+timing.active then 1+(elapsed-timing.startup)/timing.active else 2+(elapsed-timing.startup-timing.active)/timing.recovery
   local easing="linear"
   if actual.authoredClip and not variant then for _,key in actual.authoredClip.keys do if key.at==t then easing=key.ease or "smooth";break end end end
   table.insert(keys,{at=phase,ease=easing,pose=Sampler.mixedAnatomy(preset,asset,t,lib)})
  end
  local exportName=if asset.variant then asset.id else asset.grammar
  out.clips[exportName]=keys;out.timings[exportName]=M.copy(timing)
  if actual.referenceBacked then
   local metadata=M.copy(actual.metadata);metadata.phaseMarkers={}
   if variant then for _,key in variant.poseOverrides do if key.sourceTime~=nil then metadata.phaseMarkers[key.semantic or key.id]={normalized=key.time,seconds=key.time*duration,sourceTime=key.sourceTime}end end end
   out.motionMetadata[exportName]=metadata
  end
 end
 return out
end
function A.bundle(preset,lib,selected)
 local graph=M.copy(lib.presets);graph[preset.id]=preset;local ok,why=M.validateGraph(graph);assert(ok,why)
 local required={};local function gather(p,depth)
  assert(depth<9,"Source depth");for _,layer in p.bodyLayers do
   if layer.source~="base" and not required[layer.source] then local source=assert(lib.presets[layer.source],"Missing source");required[source.id]=M.copy(source);gather(source,depth+1) end
  end
 end;gather(preset,0)
 local assets={}
 local function collect(p,clip)for _,id in A.exportIds(p,lib,clip)do if lib.assets[id]then assets[id]=M.copy(lib.assets[id])end end end
 collect(preset,selected);for _,p in required do collect(p,nil)end
 return {format=A.Format,version=1,baseRig="R15",preset=M.copy(preset),sources=required,assets=assets,ninjaDuel=A.ninjaDefinitions(preset,lib,selected),automaticApply=false}
end
function A.export(preset,lib,parent,prepared)
 local bundle=prepared or A.bundle(preset,lib)
 local module=Instance.new("ModuleScript");module.Name=preset.name:gsub("[^%w_]","_").."_MotionProfile"
 local name=module.Name;local suffix=1;while parent:FindFirstChild(module.Name) do suffix+=1;module.Name=name.."_"..suffix end
 module.Source="-- Forge Motion Lab: data only; no automatic gameplay integration.\nreturn "..A.toLuau(bundle)
 module.Parent=parent;return module,bundle
end
function A.read(instance,lib)
 -- JSON only; never evaluates a selected ModuleScript or foreign Source.
 local json=instance:FindFirstChild("MotionLabJSON")
 local value=if instance:IsA("StringValue") then instance.Value elseif json and json:IsA("StringValue") then json.Value else instance:GetAttribute("ForgeMotionLabJSON")
 assert(type(value)=="string" and #value<=2000000,"Select a Motion Lab JSON export")
 local data=game:GetService("HttpService"):JSONDecode(value);assert(M.safe(data) and data.format==A.Format and data.version==1,"Invalid export format")
 local all=M.copy(lib.presets);for id,p in data.sources or {} do all[id]=p end;all[data.preset.id]=data.preset
 local ok,why=M.validateGraph(all);assert(ok,why)
 for _,p in all do local valid,reason=M.validateAssets(p,lib.assets);assert(valid,reason) end
 return M.copy(data.preset),M.copy(data.sources or {})
end
return A
