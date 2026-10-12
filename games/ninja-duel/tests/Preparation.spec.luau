-- Contracts Claude can rely on while changing presentation and authored clips.
local H=require("./Harness")
local Inspector=H.load("Server/CombatInspector")
local Brawler=H.load("Server/Brawler")
local V=H.V
local ids={"Flashstep","Mirage","GentleFist","Lion"}
local passed=0
local function test(name,fn)
 H.clearWalls();local ok,err=pcall(fn);H.clearWalls();assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local function session(c) return {phase="Duel",epoch=1,combat=c} end
local function separate(c,a,b)
 c:relocate(a,V.new(0,3,30));c:relocate(b,V.new(0,3,-30))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
end

test("all 16 core-roster matchups load through the shared Combat actor contract",function()
 for _,first in ids do for _,second in ids do
  local c,a,b=H.duel(first,second);local state=Inspector.snapshot(session(c))
  assert(#state.actors==2 and state.actors[1].fighterId==first and state.actors[2].fighterId==second)
  assert(a.def.AttackProfile and a.def.ToolMastery and a.def.Techniques and a.def.Awakening)
  assert(state.actors[1].state=="Neutral" and state.actors[1].terrain=="ground")
 end end
end)

test("observer and bounded trace never mutate actors, pending specs or event counters",function()
 local c,a,b=H.duel("Flashstep","Mirage");assert(c:request(a,"Attack"))
 local pending=a.pending;local startup=pending.spec.startup;local health=a.health;local events=a.events;local now=c.now
 local trace={}
 for _=1,20 do local s=Inspector.snapshot(session(c));Inspector.record(trace,s,3);s.actors[1].events.Clash=999 end
 assert(a.pending==pending and pending.spec.startup==startup and a.health==health and a.events==events and c.now==now)
 assert(not a.events or a.events.Clash~=999)
 a.state="Active";Inspector.record(trace,Inspector.snapshot(session(c)),3)
 a.state="Recovery";Inspector.record(trace,Inspector.snapshot(session(c)),3)
 a.state="Neutral";Inspector.record(trace,Inspector.snapshot(session(c)),3)
 assert(#trace.entries==3 and trace.entries[3].state=="Neutral")
end)

test("every core fighter traverses real startup active recovery and returns to neutral",function()
 for _,id in ids do
  local c,a,b=H.duel(id,"Mirage");separate(c,a,b)
  assert(c:request(a,"Attack"));local seen={}
  for _=1,100 do local view=Inspector.actor(c,a);seen[view.phase]=true;H.step(c,.01) end
  assert(seen.startup and seen.active and seen.recovery,id)
  assert(a.state=="Neutral" and a.pending==nil,id.." never returned to neutral")
 end
end)

test("mobile tool hold release and range expiry are observable for all four fighters",function()
 for _,id in ids do
  local c,a,b=H.duel(id,"Flashstep");separate(c,a,b)
  assert(c:request(a,"Tool",V.new(0,3,-150)));assert(Inspector.actor(c,a).throw,"no hold/release projection")
  local sawFlight=false
  for _=1,250 do H.step(c,.01);if #Inspector.actor(c,a).projectiles>0 then sawFlight=true end end
  assert(sawFlight,id.." never released");assert(#c.projectiles==0 and not a.throwing,id.." leaked a throw")
 end
end)

test("projectile cleanup clears flight and throw projection without inventing embedded entities",function()
 local c,a,b=H.duel("Flashstep","Mirage");separate(c,a,b)
 local p=c:projectile(a,b.root.Position,30,60,2,"kunai");assert(#Inspector.actor(c,a).projectiles==1)
 c:removeProjectile(p);assert(#Inspector.actor(c,a).projectiles==0)
 assert(c:request(a,"Tool",b.root.Position));c:clear()
 local view=Inspector.actor(c,a);assert(view.throw==nil and #view.projectiles==0 and #view.anchors==0)
end)

test("reaction ground air wall and wakeup are separate from the actor action state",function()
 local c,a,b=H.duel("GentleFist","Lion")
 Brawler.react(c,a,"Launched",V.new(0,35,0),.3,b)
 local view=Inspector.actor(c,a);assert(view.reaction=="Launched" and view.state=="Neutral")
 a.airborne=true;a.root.AssemblyLinearVelocity=V.new(0,-4,0);assert(Inspector.actor(c,a).terrain=="falling")
 a.wall={normal=V.xAxis};assert(Inspector.actor(c,a).terrain=="wall");a.wall=nil
 Brawler.react(c,a,"Knockdown",V.zero,.1,b);H.step(c,.15)
 assert(a.reaction=="Wakeup" or a.reaction=="Knockdown")
 H.step(c,1);assert(a.reaction==nil)
end)

test("dodge parry punish and simultaneous strike clash retain existing semantics",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 assert(c:request(b,"Guard"));assert(Inspector.actor(c,b).guard)
 local health=b.health;c:damage(a,b,4,false,true);assert(b.health==health and a.state=="Stunned")
 assert(Inspector.actor(c,a).state=="Stunned")
 local c2,x,y=H.duel("Flashstep","Mirage");assert(c2:request(y,"Dodge"))
 assert(Inspector.actor(c2,y).invulnerability>0)
 c2:damage(x,y,4,false,true);assert(Inspector.actor(c2,y).counter>0 or Inspector.actor(c2,y).riposte>0)
 local c3,u,v=H.duel("Flashstep","Flashstep")
 assert(c3:request(u,"Attack") and c3:request(v,"Attack"));H.step(c3,.12)
 assert(Inspector.actor(c3,u).clashes==1 and u.state=="Recovery" and v.state=="Recovery")
end)

print("NinjaDuel technical preparation: "..passed.." PASS")
