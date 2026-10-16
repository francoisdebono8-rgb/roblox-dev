-- Explicit experimental sandbox: kinematic proxies, never the live projectiles.
-- Chakra lab (Codex 7091585, ported verbatim). Needs the chakra runtime
-- modules ChakraConfig/ChakraRules/ChakraInteractions/ChakraVectors, which are
-- NOT part of the dev-tools port: DevHooks loads this lab only when all four
-- exist (DevTools.ChakraRuntime). Debug/QA places only (DEBUG_SOURCES).
local S=require(script.Parent.ProfileSchema)
local V=require(script.Parent.ChakraVectors)
local Engine=require(script.Parent.ChakraInteractions)
local Lab={};Lab.__index=Lab
function Lab.new(cfg)
 local copy=S.copy(cfg);copy.Enabled=true
 return setmetatable({engine=assert(Engine.new(copy)),contacts={},steps=0,discardedSeconds=0},Lab)
end
local demos={
 kunai_wind={rules={"wind-kunai"}},kunai_seal={rules={"surface-embed","seal-anchor"}},
 redirection={rules={"wind-kunai","redirect-projectile","deflect-projectile"}},wire_property={rules={"wire-property","metal-conduction"}},
 projectile_surface={rules={"surface-embed"}},fire_surface={rules={"fire-surface"}},
}
function Lab:reset(clearRules)
 self.engine:reset();if clearRules then self.engine.switches={} end;self.contacts={};self.steps=0;self.discardedSeconds=0
end
function Lab:demo(name,mastery)
 local def=assert(demos[name],"Unknown chakra demo");self:reset(false)
 local e=self.engine;for _,id in def.rules do if e.switches[id]==nil then e:toggle(id,true) end end
 local kind=if name=="wire_property" then "Wire" else "Kunai"
 e:spawn("a",kind,{position=V.new(-10,3,0),mastery=mastery or "Basic"})
 if name=="kunai_wind" then assert(e:infuse("a","Wind").ok);e:launch("a",V.new(1,0,0))
 elseif name=="kunai_seal" then
  assert(e:property("a","Marked",true).ok);assert(e:property("a","Seal",true).ok)
  e:surface("wall","Wall",V.new(8,3,0));e:launch("a",V.new(1,0,0))
 elseif name=="redirection" then
  assert(e:infuse("a","Wind").ok);e:spawn("b","Shuriken",{position=V.new(10,3,0)});e:launch("a",V.new(1,0,0));e:launch("b",V.new(-1,0,0))
 elseif name=="wire_property" then assert(e:infuse("a","Lightning").ok)
 elseif name=="projectile_surface" then
  e:surface("floor","Floor",V.new(0,0,0));e.objects.a.position=V.new(0,9,0);e:launch("a",V.new(0,-1,0))
 elseif name=="fire_surface" then
  assert(e:infuse("a","Fire").ok);e:surface("wood","Wood",V.new(8,3,0));e:launch("a",V.new(1,0,0))
 end
 return e:inspect()
end
function Lab:forceClash(a,b,direction,normal)
 local e=self.engine;local source=assert(e.objects[a],"Unknown source")
 local tagList={};for _,nature in e.cfg.Natures do if source.tags[nature.tag] then table.insert(tagList,nature.tag) end end
 return e:trigger({trigger="ProjectileClash",source=a,target=b,direction=direction or V.new(0,1,0),normal=normal or V.new(1,0,0),tags=tagList})
end
function Lab:embed(id,surface)
 local s=assert(self.engine.surfaces[surface],"Unknown surface")
 return self.engine:trigger({trigger="SurfaceHit",source=id,surface=surface,position=s.position,normal=s.normal})
end
function Lab:step(dt)
 local e=self.engine;local before=S.copy(e.objects);local candidates={};local ids={}
 for id,o in before do if o.launched then table.insert(ids,id) end end;table.sort(ids)
 local overlapping={}
 for i,id in ids do
  local a=before[id];local da=V.mul(a.velocity,dt)
  for j=i+1,#ids do
   local b=before[ids[j]];local key=id..":"..b.id;local radius=a.radius+b.radius
   local touching=V.length(V.sub(a.position,b.position))<=radius+.01
   if touching then overlapping[key]=true end
   if not (touching and self.contacts[key]) then
    local t=V.sweep(a.position,da,b.position,V.mul(b.velocity,dt),radius)
    if t then table.insert(candidates,{t=t,source=id,target=b.id,key=key}) end
   end
  end
  for surfaceId,s in e.surfaces do
   local signed=V.dot(V.sub(a.position,s.position),s.normal)-a.radius;local travel=V.dot(da,s.normal)
   if signed>=0 and travel<0 and signed+travel<=0 then
    local t=-signed/travel;local center=V.add(a.position,V.mul(da,t));local hit=V.sub(center,V.mul(s.normal,a.radius))
    if V.length(V.sub(hit,s.position))<=s.radius then table.insert(candidates,{t=t,source=id,surface=surfaceId,hit=hit,key=id..":"..surfaceId}) end
   end
  end
 end
 table.sort(candidates,function(a,b) return if a.t==b.t then a.key<b.key else a.t<b.t end)
 e:advance(dt);self.steps+=1;local handled={}
 for _,hit in candidates do
  local a=e.objects[hit.source];local b=hit.target and e.objects[hit.target]
  if a and not handled[a.id] and (not hit.target or b and not handled[b.id]) then
   local oldA=S.copy(a.position);local oldB=b and S.copy(b.position)
   a.position=V.add(before[a.id].position,V.mul(before[a.id].velocity,dt*hit.t))
   local result
   if b then
    b.position=V.add(before[b.id].position,V.mul(before[b.id].velocity,dt*hit.t))
    local normal=V.sub(a.position,b.position);if V.length(normal)<1e-8 then normal=V.sub(a.velocity,b.velocity) end
    if V.length(normal)<1e-8 then normal=V.new(1,0,0) end
    result=self:forceClash(a.id,b.id,a.velocity,normal);overlapping[hit.key]=true
   else result=e:trigger({trigger="SurfaceHit",source=a.id,surface=hit.surface,position=hit.hit,normal=e.surfaces[hit.surface].normal}) end
   if result.ok then
    for _,id in {a.id,b and b.id} do
     local o=e.objects[id];handled[id]=true;if o.launched then o.position=V.add(o.position,V.mul(o.velocity,dt*(1-hit.t))) end
    end
   else a.position=oldA;if b then b.position=oldB end end
  end
 end
 self.contacts=overlapping
end
function Lab:run(seconds)
 assert(type(seconds)=="number" and seconds>0 and seconds<=30,"Run budget 0..30 seconds")
 local remaining=seconds;while remaining>1e-8 do local dt=math.min(1/60,remaining);self:step(dt);remaining-=dt end
 return self:report()
end
function Lab:report()
 local report=self.engine:inspect();report.lab={kinematicProxies=true,steps=self.steps,discardedSeconds=self.discardedSeconds};return report
end
-- Compare in independent sandboxes; never mutates the current run or config.
function Lab.compare(cfg,kind,infusions,masteries)
 assert(cfg.Objects[kind] and #infusions>0 and #infusions<=8 and #masteries>0 and #masteries<=8,"Comparison budget")
 local rows={}
 for _,mastery in masteries do for _,infusion in infusions do
  local lab=Lab.new(cfg);for _,rule in cfg.Rules do if rule.trigger=="Infuse" then lab.engine:toggle(rule.id,true) end end
  lab.engine:spawn("preview",kind,{mastery=mastery});local ok,result=pcall(lab.engine.infuse,lab.engine,"preview",infusion);if not ok then result={ok=false,error=tostring(result)} end
  table.insert(rows,{tool=kind,infusion=infusion,mastery=mastery,result=result})
 end end
 return rows
end
Lab.demos=demos
return Lab
