-- Declarative matching only. No callbacks/code strings supplied by configuration.
local S=require(script.Parent.ProfileSchema)
local V=require(script.Parent.ChakraVectors)
local R={}
local kinds={scaleStat=true,tag=true,signal=true,redirect=true,reflect=true,embed=true,anchor=true}
local scopes={source=true,target=true,surface=true,context=true,mastery=true}
local function number(n,max) return type(n)=="number" and n==n and n>=0 and n<=(max or 1000) end
local function tags(cfg,list)
 assert(type(list)=="table" and #list<=64,"Tag list required")
 for _,tag in list do assert(cfg.Tags[tag]==true,"Unknown tag: "..tostring(tag)) end
end
function R.validate(cfg)
 assert(S.serializable(cfg) and type(cfg.Enabled)=="boolean","Unsafe interaction config")
 for _,key in {"MaxObjects","MaxSurfaces","MaxEvents","MaxLife","MaxSpeed","MaxChakra"} do assert(S.integer(cfg[key],1000) and cfg[key]>0,"Invalid limit") end
 assert(cfg.MaxObjects<=64 and cfg.MaxSurfaces<=32 and cfg.MaxEvents<=256 and cfg.MaxSpeed<=1000,"Lab budget exceeded")
 for id,value in cfg.Tags do assert(S.id(id) and value==true,"Invalid tag") end
 for id,nature in cfg.Natures do assert(S.id(id) and cfg.Tags[nature.tag],"Invalid nature") end
 for id,property in cfg.Properties do assert(S.id(id) and cfg.Tags[property.tag],"Invalid property");tags(cfg,property.requires) end
 for id,enabled in cfg.MasterySkills do assert(S.id(id) and enabled==true,"Invalid mastery skill") end
 for id,mastery in cfg.Masteries do
  assert(S.id(id),"Invalid mastery");tags(cfg,mastery.tags)
  for name,level in mastery.levels do assert(cfg.MasterySkills[name] and S.integer(level,100),"Invalid mastery level") end
 end
 assert(cfg.Masteries.Basic,"Basic mastery required")
 for character,mastery in cfg.CharacterMastery do assert(S.id(character) and cfg.Masteries[mastery],"Invalid character mastery mapping") end
 for id,def in cfg.Objects do
  assert(S.id(id) and S.id(def.toolType) and type(def.canLaunch)=="boolean" and number(def.radius,3) and def.radius>0,"Invalid tool");tags(cfg,def.tags)
  assert(({kunai=true,shuriken=true,wire=true,target=true})[def.visual],"Unknown lab visual")
  for infusion,enabled in def.infusions do assert(cfg.Infusions[infusion] and enabled==true,"Invalid tool infusion") end
  for stat,n in def.stats do assert(S.id(stat) and number(n,cfg.MaxSpeed) and number(def.caps[stat],cfg.MaxSpeed) and def.caps[stat]>=n,"Invalid stat cap") end
 end
 for id,def in cfg.Surfaces do assert(S.id(id) and V.valid(def.normal) and V.length(def.normal)>0 and number(def.radius,30) and def.radius>0,"Invalid surface");tags(cfg,def.tags) end
 for id,def in cfg.Infusions do assert(S.id(id) and number(def.cost,cfg.MaxChakra) and (not def.nature or cfg.Natures[def.nature]),"Invalid infusion");tags(cfg,def.tags) end
 local ids={}
 for _,rule in cfg.Rules do
  assert(S.id(rule.id) and not ids[rule.id] and cfg.Triggers[rule.trigger] and type(rule.enabled)=="boolean" and S.integer(rule.priority,1000),"Invalid interaction rule");ids[rule.id]=true
  assert(not rule.group or S.id(rule.group),"Invalid exclusive group")
  assert(not rule.cost or number(rule.cost,cfg.MaxChakra),"Invalid rule cost")
  for scope,filter in rule.when do
   if scope=="toolType" then assert(S.id(filter),"Invalid tool type")
   elseif scope=="minMastery" then for name,level in filter do assert(cfg.MasterySkills[name] and S.integer(level,100),"Invalid mastery threshold") end
   else assert(scopes[scope],"Unknown condition scope");for op,list in filter do assert(op=="all" or op=="any" or op=="none","Unknown tag filter");tags(cfg,list) end end
  end
  assert(#rule.effects>0 and #rule.effects<=16,"Invalid result count")
  for _,effect in rule.effects do
   assert(kinds[effect.kind],"Unknown result kind")
   if effect.kind=="scaleStat" then
    assert(S.id(effect.stat) and number(effect.factor,4) and effect.factor>0,"Invalid stat result")
    assert(not effect.mastery or cfg.MasterySkills[effect.mastery],"Invalid scaling mastery")
    assert(not effect.perLevel or number(effect.perLevel,1),"Invalid mastery factor")
    assert(not effect.maxFactor or number(effect.maxFactor,4) and effect.maxFactor>0,"Invalid max factor")
   elseif effect.kind=="signal" then assert(S.id(effect.name),"Invalid signal")
   else
    assert(effect.target=="source" or effect.target=="target" or (effect.kind=="tag" and effect.target=="surface"),"Invalid result target")
    if effect.kind=="tag" then assert(cfg.Tags[effect.tag],"Invalid result tag") end
    if effect.kind=="reflect" or effect.kind=="redirect" then assert(number(effect.speedScale,2) and effect.speedScale>0,"Invalid velocity scale") end
   end
  end
 end
 return true
end
local function filter(tagsValue,spec)
 tagsValue=tagsValue or {}
 for _,tag in spec.all or {} do if not tagsValue[tag] then return false,"missing "..tag end end
 if spec.any and #spec.any>0 then local found=false;for _,tag in spec.any do found=found or tagsValue[tag]==true end;if not found then return false,"missing any tag" end end
 for _,tag in spec.none or {} do if tagsValue[tag] then return false,"excluded "..tag end end
 return true
end
function R.match(rule,event)
 for _,scope in {"source","target","surface","context","mastery"} do
  local spec=rule.when[scope]
  if spec then local ok,why=filter(event[scope] and event[scope].tags,spec);if not ok then return false,scope..": "..why end end
 end
 if rule.when.toolType and event.source.toolType~=rule.when.toolType then return false,"toolType" end
 for name,min in rule.when.minMastery or {} do if (event.mastery.levels[name] or 0)<min then return false,"mastery "..name end end
 return true
end
function R.plan(cfg,event,switches)
 assert(cfg.Triggers[event.trigger],"Unknown trigger")
 local ordered={};for _,rule in cfg.Rules do if rule.trigger==event.trigger then table.insert(ordered,rule) end end
 table.sort(ordered,function(a,b) return if a.priority==b.priority then a.id<b.id else a.priority>b.priority end)
 local selected={};local trace={};local used={}
 for _,rule in ordered do
  local enabled=rule.enabled;if switches[rule.id]~=nil then enabled=switches[rule.id] end
  local matched,why=R.match(rule,event);local status
  if not enabled then status="disabled" elseif not matched then status=why elseif rule.group and used[rule.group] then status="exclusive-group" else status="selected";table.insert(selected,rule);if rule.group then used[rule.group]=true end end
  table.insert(trace,{rule=rule.id,status=status})
 end
 return selected,trace
end
return R
