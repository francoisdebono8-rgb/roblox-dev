-- Optional server-owned domain. Pure data, bounded state, atomic rule resolution.
-- No active fighter/weapon, remote, timer, damage, animation or camera reference.
local S=require(script.Parent.ProfileSchema)
local V=require(script.Parent.ChakraVectors)
local Rules=require(script.Parent.ChakraRules)
local E={};E.__index=E
local function size(t) local n=0;for _ in t do n+=1 end;return n end
local function tagMap(list) local t={};for _,tag in list do t[tag]=true end;return t end
local function tags(cfg,o)
 local out=tagMap(cfg.Objects[o.kind].tags)
 for id in o.properties do out[cfg.Properties[id].tag]=true end
 if o.infusion then
  local infusion=cfg.Infusions[o.infusion];for _,tag in infusion.tags do out[tag]=true end
  if infusion.nature then out[cfg.Natures[infusion.nature].tag]=true end
 end
 for tag in o.infusionResults do out[tag]=true end
 for tag in o.interactionResults do out[tag]=true end
 return out
end
function E.new(cfg)
 Rules.validate(cfg);if cfg.Enabled~=true then return nil,"Chakra interactions disabled" end
 return setmetatable({cfg=S.copy(cfg),objects={},surfaces={},switches={},events={},serial=0,time=0,counters={triggers=0,rules=0,rejected=0,expired=0}},E)
end
function E:record(row)
 self.serial+=1;row.sequence=self.serial;row.time=self.time;table.insert(self.events,row)
 if #self.events>self.cfg.MaxEvents then table.remove(self.events,1) end
end
function E:spawn(id,kind,spec)
 spec=spec or {};assert(S.id(id) and not self.objects[id] and size(self.objects)<self.cfg.MaxObjects,"Object ID/budget")
 assert(S.serializable(spec),"Unsafe object data")
 local def=assert(self.cfg.Objects[kind],"Unknown tool")
 local mastery=spec.mastery or (spec.character and self.cfg.CharacterMastery[spec.character]) or "Basic"
 assert(self.cfg.Masteries[mastery] and (not spec.owner or S.id(spec.owner)) and (not spec.character or S.id(spec.character)),"Invalid server identity/mastery")
 local position=spec.position or V.new();assert(V.valid(position),"Invalid position")
 local chakra=spec.chakra or 100;assert(S.integer(chakra,self.cfg.MaxChakra),"Invalid development chakra")
 local o={id=id,kind=kind,toolType=def.toolType,owner=spec.owner,character=spec.character,mastery=mastery,position=S.copy(position),velocity=V.new(),chakra=chakra,
  properties={},infusionResults={},interactionResults={},stats=S.copy(def.stats),tags={},launched=false,embedded=false,age=0,radius=def.radius}
 o.tags=tags(self.cfg,o);self.objects[id]=o;return S.copy(o)
end
function E:surface(id,kind,position,normal)
 local def=assert(self.cfg.Surfaces[kind],"Unknown surface")
 assert(S.id(id) and not self.surfaces[id] and size(self.surfaces)<self.cfg.MaxSurfaces,"Surface ID/budget")
 normal=normal or def.normal;assert(V.valid(position) and V.valid(normal),"Invalid surface geometry")
 self.surfaces[id]={id=id,kind=kind,position=S.copy(position),normal=V.unit(normal),tags=tagMap(def.tags),radius=def.radius}
 return S.copy(self.surfaces[id])
end
function E:toggle(ruleId,enabled)
 assert(type(enabled)=="boolean","Boolean switch required")
 local found=false;for _,rule in self.cfg.Rules do found=found or rule.id==ruleId end;assert(found,"Unknown rule")
 self.switches[ruleId]=enabled
end
function E:_trigger(arg)
 assert(S.serializable(arg) and self.cfg.Triggers[arg.trigger],"Invalid trigger data")
 local source=S.copy(assert(self.objects[arg.source],"Unknown source"));local target=arg.target and S.copy(assert(self.objects[arg.target],"Unknown target"))
 assert(not target or target.id~=source.id,"Self collision refused")
 local surface=arg.surface and S.copy(assert(self.surfaces[arg.surface],"Unknown surface"))
 if arg.trigger=="ProjectileClash" then assert(target and source.tags.projectile and target.tags.projectile and source.launched and target.launched and not source.embedded and not target.embedded,"Two moving projectiles required") end
 if arg.trigger=="SurfaceHit" then assert(surface and V.valid(arg.position) and V.valid(arg.normal),"Surface contact geometry required") end
 for _,key in {"position","normal","direction"} do if arg[key] then assert(V.valid(arg[key]),"Invalid contact vector") end end
 local context={tags={}};for _,tag in arg.tags or {} do assert(self.cfg.Tags[tag],"Unknown context tag");context.tags[tag]=true end
 if arg.trigger=="Infuse" then source.stats=S.copy(self.cfg.Objects[source.kind].stats);source.infusionResults={} end
 source.tags=tags(self.cfg,source)
 local selected,trace=Rules.plan(self.cfg,{trigger=arg.trigger,source=source,target=target,surface=surface,context=context,mastery=self.cfg.Masteries[source.mastery]},self.switches)
 local cost=0;for _,rule in selected do cost+=rule.cost or 0 end;assert(source.chakra>=cost,"Insufficient chakra for rules")
 local applied={};local results={};local signals={}
 for _,rule in selected do
  table.insert(applied,rule.id)
  for _,effect in rule.effects do
   local result=S.copy(effect);result.rule=rule.id
   local receiver=if effect.target=="target" then target elseif effect.target=="surface" then surface else source
   assert(receiver,"Missing result receiver")
   if effect.kind=="scaleStat" then
    local value=assert(source.stats[effect.stat],"Stat not supported by tool")
    local mastery=self.cfg.Masteries[source.mastery];local factor=effect.factor+(effect.perLevel or 0)*(effect.mastery and mastery.levels[effect.mastery] or 0)
    factor=math.min(effect.maxFactor or 4,factor);local cap=self.cfg.Objects[source.kind].caps[effect.stat]
    source.stats[effect.stat]=math.min(cap,value*factor);result.value=source.stats[effect.stat]
   elseif effect.kind=="tag" then
    if receiver==surface then surface.tags[effect.tag]=true
    else local field=if arg.trigger=="Infuse" then "infusionResults" else "interactionResults";receiver[field][effect.tag]=true end
   elseif effect.kind=="signal" then table.insert(signals,{rule=rule.id,name=effect.name,source=source.id,target=target and target.id,surface=surface and surface.id})
   elseif effect.kind=="redirect" or effect.kind=="reflect" then
    assert(receiver.launched and not receiver.embedded,"Result requires moving projectile")
    local velocity=receiver.velocity
    if effect.kind=="reflect" then assert(arg.normal,"Reflection normal required");velocity=V.reflect(velocity,arg.normal)
    else assert(arg.direction,"Redirection direction required");velocity=V.mul(V.unit(arg.direction),V.length(velocity)) end
    local speed=math.min(self.cfg.MaxSpeed,V.length(velocity)*effect.speedScale);receiver.velocity=V.mul(V.unit(velocity),speed);result.velocity=S.copy(receiver.velocity)
   elseif effect.kind=="embed" then
    assert(surface and arg.position,"Embed contact required");receiver.position=S.copy(arg.position);receiver.velocity=V.new();receiver.embedded=true;receiver.launched=false;receiver.interactionResults.embedded=true
   elseif effect.kind=="anchor" then
    assert(surface and arg.position,"Anchor surface required");receiver.anchor={position=S.copy(arg.position),normal=V.unit(arg.normal),surface=surface.id,rule=rule.id};receiver.interactionResults.spatialAnchor=true
   end
   table.insert(results,result)
  end
 end
 source.chakra-=cost
 if arg.trigger=="Infuse" and source.launched and source.stats.speed then source.velocity=V.mul(V.unit(source.velocity),source.stats.speed) end
 source.tags=tags(self.cfg,source);if target then target.tags=tags(self.cfg,target) end
 assert(S.serializable(source) and (not target or S.serializable(target)) and (not surface or S.serializable(surface)),"Unsafe result")
 self.objects[source.id]=source;if target then self.objects[target.id]=target end;if surface then self.surfaces[surface.id]=surface end
 local row={trigger=arg.trigger,source=source.id,target=target and target.id,surface=surface and surface.id,applied=applied,trace=trace,cost=cost,signals=signals}
 self:record(row);self.counters.rules+=#applied
 return {ok=true,source=S.copy(source),target=S.copy(target),surface=S.copy(surface),effects=results,signals=signals,trace=trace}
end
function E:trigger(arg)
 local started=os.clock();self.counters.triggers+=1
 local ok,result=pcall(self._trigger,self,arg)
 if not ok then self.counters.rejected+=1;self:record({trigger=type(arg)=="table" and tostring(arg.trigger):sub(1,40) or "invalid",error=tostring(result):sub(1,200)});return {ok=false,error=tostring(result)} end
 result.resolveMilliseconds=(os.clock()-started)*1000;return result
end
local function change(self,id,fn)
 local previous=assert(self.objects[id],"Unknown object");local o=S.copy(previous);fn(o);self.objects[id]=o
 local result=self:trigger({trigger="Infuse",source=id})
 if not result.ok then self.objects[id]=previous end
 return result
end
function E:infuse(id,infusion)
 return change(self,id,function(o)
  if infusion=="None" then o.infusion=nil;return end
  local def=assert(self.cfg.Infusions[infusion],"Unknown infusion");assert(self.cfg.Objects[o.kind].infusions[infusion],"Tool incompatible with infusion")
  assert(o.chakra>=def.cost,"Insufficient infusion chakra");o.chakra-=def.cost;o.infusion=infusion
 end)
end
function E:property(id,property,enabled)
 assert(type(enabled)=="boolean","Property switch required")
 return change(self,id,function(o)
  local def=assert(self.cfg.Properties[property],"Unknown property");for _,tag in def.requires do assert(o.tags[tag],"Property incompatible with object") end
  o.properties[property]=if enabled then true else nil
 end)
end
function E:launch(id,direction,speed)
 local o=assert(self.objects[id],"Unknown object");assert(self.cfg.Objects[o.kind].canLaunch and not o.embedded,"Tool cannot launch")
 assert(V.valid(direction),"Invalid direction");direction=V.unit(direction);speed=speed or o.stats.speed
 assert(type(speed)=="number" and speed>0 and speed<=self.cfg.MaxSpeed,"Invalid launch speed")
 o.velocity=V.mul(direction,speed);o.launched=true;return S.copy(o)
end
function E:advance(dt)
 assert(type(dt)=="number" and dt>0 and dt<=.1,"Step must be 0..0.1 seconds")
 self.time+=dt;local expired={}
 for id,o in self.objects do
  o.age+=dt;if o.age>=self.cfg.MaxLife then table.insert(expired,id);self.objects[id]=nil;self.counters.expired+=1
  elseif o.launched then o.position=V.add(o.position,V.mul(o.velocity,dt)) end
 end
 return expired
end
function E:inspect(id) return S.copy(id and assert(self.objects[id],"Unknown object") or {objects=self.objects,surfaces=self.surfaces,switches=self.switches,events=self.events,counters=self.counters,time=self.time}) end
function E:reset()
 self.objects={};self.surfaces={};self.events={};self.serial=0;self.time=0;self.counters={triggers=0,rules=0,rejected=0,expired=0}
 -- Explicit switches survive reset so an A/B run retains the chosen configuration.
end
return E
