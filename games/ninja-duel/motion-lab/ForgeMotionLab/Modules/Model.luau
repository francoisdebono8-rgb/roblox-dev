local Edit=require(script.Parent.MotionEdit)
local M={Version=1,Layers={"Root","Legs","Hips","Torso","LeftArm","RightArm","Head","Weapon"}}
M.DNA={
 {"cadence","Cadence",.5,2,1,"Rhythm"},{"amplitude","Amplitude",.2,1.8,1,"Rhythm"},{"apparentWeight","Apparent weight",0,1,.5,"Rhythm"},{"recoverySpeed","Recovery speed",.5,2,1,"Rhythm"},
 {"groundedness","Groundedness",0,1,.7,"Body"},{"centerHeight","Centre height",-.8,.35,0,"Body"},{"hipInvolvement","Hip involvement",0,1.5,1,"Body"},{"upperActivity","Upper activity",0,1.6,1,"Body"},{"lowerActivity","Lower activity",0,1.6,1,"Body"},{"asymmetry","Asymmetry",-1,1,0,"Body"},{"looseness","Looseness",0,1,.5,"Body"},
 {"forwardPressure","Forward pressure",0,1,.5,"Travel"},{"lateralBias","Lateral bias",-1,1,0,"Travel"},{"stepLength","Step length",.4,2,1,"Travel"},{"strideFrequency","Stride frequency",.5,2,1,"Travel"},{"rotationAmount","Rotation",0,1.6,1,"Travel"},{"rootIntensity","Root intensity",0,1.6,1,"Travel"},
 {"guardOpenness","Guard openness",0,1,.5,"Expression"},{"precision","Precision",0,1,.7,"Expression"},{"acrobatics","Acrobatics",0,1,.4,"Expression"},{"aggression","Aggression",0,1,.5,"Expression"},{"headTracking","Head / aim",0,1,.6,"Expression"},
}
function M.copy(v) if type(v)~="table" then return v end;local out={};for k,x in v do out[k]=M.copy(x) end;return out end
function M.id(s) return type(s)=="string" and #s>0 and #s<=100 and s:match("^[%w_.:%-]+$")~=nil end
function M.finite(n) return type(n)=="number" and n==n and math.abs(n)<1e8 end
function M.safe(value)
 local seen={};local nodes=0
 local function walk(v,d)
  nodes+=1;if nodes>400000 or d>22 then return false end
  if type(v)=="table" then
   if seen[v] then return false end;seen[v]=true
   for k,x in v do if (type(k)~="string" and type(k)~="number") or not walk(k,d+1) or not walk(x,d+1) then return false end end
   seen[v]=nil;return true
  end
  return v==nil or type(v)=="boolean" or M.finite(v) or (type(v)=="string" and #v<=2000000)
 end
 return walk(value,0)
end
function M.defaults() local d={};for _,row in M.DNA do d[row[1]]=row[5] end;return d end
function M.new(id,name)
 local p={schemaVersion=1,id=id,name=name,baseRig="R15",bodyLayers={},motionDNA=M.defaults(),locomotionSet={},sequences={},characterRules={},blendValues={},metadata={sourceType="generated",dnaReference=M.defaults()},stance={weapon={roll=0}},gait={stride=1,cadence=1,arm=35,bob=1,guard=.2},clips={}}
 for _,layer in M.Layers do p.bodyLayers[layer]={source="base",strength=1,enabled=true} end
 return p
end
function M.validate(p,known)
 if not M.safe(p) or type(p)~="table" or p.schemaVersion~=1 or not M.id(p.id) or type(p.name)~="string" or #p.name<1 or #p.name>80 or p.baseRig~="R15" then return false,"Invalid MotionPreset header" end
 if type(p.motionDNA)~="table" or type(p.bodyLayers)~="table" then return false,"Missing DNA/body layers" end
 for layer in p.bodyLayers do if not table.find(M.Layers,layer) then return false,"Unknown body layer" end end
 for _,row in M.DNA do local v=p.motionDNA and p.motionDNA[row[1]];if not M.finite(v) or v<row[3] or v>row[4] then return false,"Invalid DNA: "..row[1] end end
 for _,layer in M.Layers do
  local b=p.bodyLayers and p.bodyLayers[layer]
  if type(b)~="table" or not M.id(b.source) or b.source==p.id or not M.finite(b.strength) or b.strength<0 or b.strength>1 or type(b.enabled)~="boolean" then return false,"Invalid body layer" end
  if known and b.source~="base" and not known[b.source] then return false,"Missing source: "..b.source end
 end
 if type(p.sequences)~="table" or #p.sequences>16 then return false,"Sequence budget" end
 for _,sequence in p.sequences do
  if type(sequence)~="table" or not M.id(sequence.id) or type(sequence.name)~="string" or type(sequence.orderedClips)~="table" or #sequence.orderedClips>24 then return false,"Invalid sequence" end
  for _,clip in sequence.orderedClips do
   if type(clip)~="table" or not M.id(clip.asset) or not M.finite(clip.duration) or clip.duration<.12 or clip.duration>5 or not M.finite(clip.blend) or clip.blend<0 or clip.blend>.5 or (clip.transition~="blend" and clip.transition~="cut") then return false,"Invalid sequence clip" end
  end
 end
 for _,key in {"stance","gait","clips","characterRules","locomotionSet","metadata"} do if type(p[key])~="table" then return false,"Missing "..key end end
 if type(p.metadata.sourceType)~="string" or #p.metadata.sourceType>100 then return false,"Invalid source metadata" end
 if p.metadata.dnaReference then
  if type(p.metadata.dnaReference)~="table" then return false,"Invalid DNA reference" end
  for _,row in M.DNA do local v=p.metadata.dnaReference[row[1]];if not M.finite(v) or v<row[3] or v>row[4] then return false,"Invalid DNA reference" end end
 end
 local function anatomy(pose)
  if type(pose)~="table" then return false end
  for key,part in pose do
   if (key=="breath" or key=="tempo") and M.finite(part) then continue end
   if key=="keep" and type(part)=="boolean" then continue end
   if not table.find({"root","torso","head","ra","la","rl","ll","rf","lf","weapon"},key) or type(part)~="table" then return false end
   for field,value in part do if type(field)~="string" or not M.finite(value) or math.abs(value)>10000 then return false end end
  end
  return true
 end
 if not anatomy(p.stance) then return false,"Invalid anatomical stance" end
 for _,n in p.gait do if not M.finite(n) or math.abs(n)>100 then return false,"Invalid gait" end end
 for name,clip in p.clips do
  if not M.id(name) or type(clip)~="table" or not M.finite(clip.duration) or clip.duration<=0 or clip.duration>30 or type(clip.keys)~="table" or #clip.keys<1 or #clip.keys>128 then return false,"Invalid authored clip" end
  local previous=-1
  for _,key in clip.keys do
   if type(key)~="table" or not M.finite(key.at) or key.at<previous or key.at<0 or key.at>1 or not anatomy(key.pose) then return false,"Invalid motion key" end
   previous=key.at
  end
 end
 for key,value in p.locomotionSet do if not M.id(key) or not M.id(value) then return false,"Invalid locomotion reference" end end
 local overrides=p.characterRules.grammarOverrides
 if overrides then
  if type(overrides)~="table" then return false,"Invalid grammar overrides" end
  for grammar,values in overrides do
   if not M.id(grammar) or type(values)~="table" then return false,"Invalid grammar expression" end
   for key,value in values do if not table.find({"bodyScale","rootLift","rootTravel","lateralTravel"},key) or not M.finite(value) or math.abs(value)>5 then return false,"Invalid expression value" end end
  end
 end
 if p.motionVariants~=nil then
  if type(p.motionVariants)~="table" then return false,"Invalid variants" end
  local count=0;for id,v in p.motionVariants do count+=1;if count>64 or type(v)~="table" or id~=v.id then return false,"Variant budget/identity" end;local ok,why=Edit.validate(v);if not ok then return false,why end end
 end
 return true
end
function M.validateGraph(presets)
 if type(presets)~="table" then return false,"Invalid preset library" end
 local count=0
 for id,p in presets do
  count+=1;if count>128 or type(p)~="table" or id~=p.id then return false,"Preset budget/identity" end
  local ok,why=M.validate(p,presets);if not ok then return false,why end
 end
 local visiting={};local heights={}
 local function visit(id)
  if visiting[id] then return nil,"Body source cycle" end
  if heights[id] then return heights[id] end
  visiting[id]=true;local height=0
  for _,b in presets[id].bodyLayers do if b.source~="base" then
   local child,why=visit(b.source);if not child then return nil,why end;height=math.max(height,child+1)
  end end
  visiting[id]=nil;if height>8 then return nil,"Body source depth" end;heights[id]=height;return height
 end
 for id in presets do local height,why=visit(id);if not height then return false,why end end
 return true
end
function M.validateAssets(p,assets)
 for id,v in p.motionVariants or {} do if (assets[id] and(not assets[id].variantDefinition or assets[id].variantDefinition.sourceAsset~=v.sourceAsset)) or not assets[v.sourceAsset] or assets[v.sourceAsset].grammar~=v.sourceGrammar then return false,"Invalid variant source: "..v.sourceAsset end end
 for _,seq in p.sequences do for _,block in seq.orderedClips do if not assets[block.asset] and not (p.motionVariants and p.motionVariants[block.asset]) then return false,"Unknown motion block: "..block.asset end end end
 for _,id in p.locomotionSet do if not assets[id] and not (p.motionVariants and p.motionVariants[id]) then return false,"Unknown locomotion block: "..id end end
 return true
end
function M.duration(sequence) local n=0;for _,clip in sequence.orderedClips do n+=clip.duration end;return n end
function M.reorder(sequence,from,to)
 assert(from>=1 and from<=#sequence.orderedClips and to>=1 and to<=#sequence.orderedClips,"Invalid clip order")
 table.insert(sequence.orderedClips,to,table.remove(sequence.orderedClips,from))
end
return M
