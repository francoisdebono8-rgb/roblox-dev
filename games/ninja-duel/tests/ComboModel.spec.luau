-- Combo state, input model, route reliability and re-engage
-- (CORE_COMBAT_CONVERGENCE_2 phases 1-3). Every case drives the real
-- Combat/Brawler/AI against two headless rigs; nothing is mocked.
--
-- Phase 1: a string counts CONFIRMED hits. A press, a startup, a buffered
-- input or a whiff never advances it, a buffered press waits for the outcome
-- of the swing before it, and the stick is read through a short directional
-- memory relative to the opponent instead of one instantaneous frame.
-- Phase 2: every CORE4 route of the shared grammar executes from a normal
-- confirmed string. Phase 3: one contextual re-engage (chase in a window,
-- chakra dash outside it), same cost, a punishable arrival and a different
-- re-entry for each prodigy.
-- Headless geometry and timing only: feel, camera and the pad itself need Studio.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local MoveGraphs=H.load("Shared/MoveGraphs")
local Brawler=H.load("Server/Brawler")
local Techniques=H.load("Server/Techniques")
local CORE4={"Flashstep","Mirage","GentleFist","Lion"}
local UP={Flashstep="Launcher",Mirage="Launcher",GentleFist="Launcher",Lion="LionKick"}
local SIDE={Flashstep="AngleStep",Mirage="FeintStep",GentleFist="CircleStep",Lion="VaultKick"}
local QUICK={Flashstep="KneeStrike",Mirage="CounterPalm",GentleFist="PalmThrust",Lion="KneeStrike"}
local CANCEL={Flashstep="BurstStrike",Mirage="NeedleFan",GentleFist="VacuumPalm",Lion="Chidori"}
local passed=0
local failures={}
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else table.insert(failures,name);print("FAIL "..name..": "..tostring(err)) end
end
local function place(c,a,b,gap)
 gap=gap or 4.5
 c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 for _,x in {a,b} do x.move=V.zero end
end
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return true end
 end
 error(message,0)
end
local function chainOpen(c,a) return a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0) end
local function chain(c,a,label)
 until_(c,.9,function() return chainOpen(c,a) end,(label or "")..": the chain never opened ("..tostring(a.state)..")")
end
local function flat(v) return V.new(v.X,0,v.Z) end
local function toward(a) return flat(a.target.root.Position-a.root.Position).Unit end
local function side(a,sign) local t=toward(a);return V.new(-t.Z,0,t.X)*(sign or 1) end
local function rotated(v,degrees)
 local r=math.rad(degrees)
 return V.new(v.X*math.cos(r)-v.Z*math.sin(r),0,v.X*math.sin(r)+v.Z*math.cos(r))
end
-- One press with the stick held at `stick`, released right after.
local function press(c,a,action,stick,aim)
 a.move=stick or V.zero
 local ok,reason=c:request(a,action,aim)
 a.move=V.zero
 return ok,reason
end
local function slot(a,id) for i,t in a.def.Techniques do if t.Id==id then return "Technique"..i end end end
-- A fresh duel with `hits` confirmed lights and the chain window open.
local function opened(id,hits,other)
 local c,a,b=H.duel(id,other or "Mirage")
 place(c,a,b)
 assert(press(c,a,"Attack"),id..": opening light refused")
 chain(c,a,id)
 if (hits or 1)>=2 then
  assert(press(c,a,"Attack"),id..": second light refused")
  until_(c,.8,function() return chainOpen(c,a) and a.attackName=="Light2" end,id..": the second chain never opened")
 end
 return c,a,b
end
-- Hold both bodies in the air for an air exchange (the victim juggled).
local function airborne(c,a,b,gap)
 place(c,a,b,gap or 3)
 for _,x in {a,b} do c:relocate(x,x.root.Position+V.new(0,7,0));x.airborne=true;x.airHold=c.now+2 end
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.reaction="Juggled";b.reactionUntil=c.now+2;b.reactionVelocity=V.zero
end
local function airStep(c,b,seconds,cond)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01);b.reactionVelocity=V.zero
  if cond and cond() then return true end
 end
 return false
end

-- Phase 1 -------------------------------------------------------------------
test("a whiff never advances the string: the first real hit is the opener (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage")
  place(c,a,b,30)
  assert(press(c,a,"Attack"),id..": opening press refused")
  assert(a.attackName=="Light1",id..": the opening press is "..tostring(a.attackName))
  until_(c,1.2,function() return a.state=="Neutral" end,id..": the whiff never recovered")
  assert((a.combo or 0)==0,id..": a whiff advanced the combo to "..tostring(a.combo))
  place(c,a,b)
  assert(press(c,a,"Attack"),id..": first real press refused")
  assert(a.attackName=="Light1",id..": the first real hit plays "..tostring(a.attackName).." (one step ahead)")
  until_(c,.5,function() return b.health<b.def.Health end,id..": the opener never landed")
  assert(a.combo==1,id..": one confirmed hit reads as combo "..tostring(a.combo))
 end
end)
test("one confirmed hit is one: toward + strike after a single hit is the second light, pressed directly or buffered",function()
 for _,id in CORE4 do
  for _,mode in {"direct","buffered"} do
   local c,a,b=H.duel(id,"Mirage")
   place(c,a,b)
   assert(press(c,a,"Attack"))
   if mode=="buffered" then
    until_(c,.3,function() return a.state=="Active" end,id..": no active window")
    local ok,reason=press(c,a,"Attack",toward(a))
    assert(ok and reason=="Buffered",id..": the early press was not buffered ("..tostring(reason)..")")
    until_(c,.6,function() return a.attackName~="Light1" and a.attackName~=nil end,id..": the buffered press never fired")
   else
    chain(c,a,id)
    assert(press(c,a,"Attack",toward(a)))
   end
   assert(a.attackName=="Light2",id.." ("..mode.."): toward after ONE hit gave "..tostring(a.attackName))
  end
 end
end)
test("L, L, then toward released 0.1 s before the press still launches (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=opened(id,2)
  a.move=toward(a);H.step(c,.04)
  a.move=V.zero;H.step(c,.1)
  assert(chainOpen(c,a),id..": fixture: the chain closed before the press")
  assert(press(c,a,"Attack"))
  assert(a.attackName==UP[id],id..": a toward push released 0.1 s before the press gave "..tostring(a.attackName))
  until_(c,.6,function() return b.reaction=="Launched" end,id..": the launcher did not launch")
 end
end)
test("a direction pushed while the press waits in the buffer picks the route (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=opened(id,1)
  assert(press(c,a,"Attack"),id..": second light refused")
  -- Neutral press during the second swing, then toward for a few frames.
  local ok,reason=press(c,a,"Attack")
  assert(ok and reason=="Buffered",id..": the third press was not buffered ("..tostring(reason)..")")
  a.move=toward(a);H.step(c,.05);a.move=V.zero
  until_(c,.8,function() return a.attackName~="Light2" and a.attackName~=nil end,id..": the buffered press never fired")
  assert(a.attackName==UP[id],id..": a push made during the buffer was ignored ("..tostring(a.attackName)..")")
 end
end)
test("a toward push 40 degrees off the opponent line still launches; 60 degrees off turns the angle",function()
 for _,id in CORE4 do
  local c,a=opened(id,2)
  assert(press(c,a,"Attack",rotated(toward(a),40)))
  assert(a.attackName==UP[id],id..": 40 degrees off the line gave "..tostring(a.attackName))
  local c2,x=opened(id,1)
  assert(press(c2,x,"Attack",rotated(toward(x),-62)))
  assert(x.attackName==SIDE[id],id..": 62 degrees off the line gave "..tostring(x.attackName))
 end
end)
test("one hit + side turns the angle and keeps the string; two hits + away takes the legs (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=opened(id,1)
  assert(press(c,a,"Attack",side(a,1)))
  assert(a.attackName==SIDE[id],id..": side after one hit gave "..tostring(a.attackName))
  until_(c,.6,function() return (a.events.Hit or 0)>=2 end,id..": the lateral route never connected")
  chain(c,a,id)
  assert(a.combo==2,id..": the lateral route did not count as the second confirmed hit ("..tostring(a.combo)..")")
  local c2,x,y=opened(id,2)
  assert(press(c2,x,"Attack",-toward(x)))
  assert(x.attackName=="Sweep",id..": away after two hits gave "..tostring(x.attackName))
  until_(c2,.6,function() return y.reaction=="Knockdown" end,id..": the sweep did not take the legs")
 end
end)
test("heavy: after one hit the fighter's quick heavy, after two the launcher, from neutral the heavy (CORE4)",function()
 for _,id in CORE4 do
  local c,a=opened(id,1)
  assert(press(c,a,"Heavy"));assert(a.attackName==QUICK[id],id..": heavy after one is "..tostring(a.attackName))
  local c2,x=opened(id,2)
  assert(press(c2,x,"Heavy"));assert(x.attackName=="Launcher",id..": heavy after two is "..tostring(x.attackName))
  local c3,m,n=H.duel(id,"Mirage");place(c3,m,n)
  assert(press(c3,m,"Heavy"));assert(m.attackName==(m.def.HeavyMove or "Heavy"),id..": neutral heavy is "..tostring(m.attackName))
 end
end)
test("a press buffered during a whiff waits for the full recovery and comes out as a fresh opener (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage")
  place(c,a,b,30)
  assert(press(c,a,"Attack"))
  local ok,reason=press(c,a,"Attack")
  assert(ok and reason=="Buffered",id..": the early press was not buffered ("..tostring(reason)..")")
  local recoveryEnd=nil
  for _=1,120 do
   H.step(c,.01)
   if a.state=="Recovery" and (a.attackSerial or 0)<2 then
    assert(not a.chainOpen,id..": a whiff opened the chain")
    recoveryEnd=a.untilTime
   end
   if (a.attackSerial or 0)>=2 then break end
  end
  assert((a.attackSerial or 0)>=2,id..": the buffered press was dropped after the whiff")
  assert(recoveryEnd and c.now>=recoveryEnd-.011,id..": the buffered press cut the whiff recovery short")
  assert(a.attackName=="Light1",id..": the buffered press after a whiff is "..tostring(a.attackName).." instead of a fresh opener")
  assert((a.combo or 0)==0,id..": the combo survived the whiff ("..tostring(a.combo)..")")
 end
end)
test("a blade landing during a whiffing swing does not open the string",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 -- Out of every opener's reach (the reach strike lands up to ~12.5 once the
 -- light's contact is an arm's length, 4.1).
 place(c,a,b,16)
 assert(press(c,a,"Attack"))
 until_(c,.3,function() return a.state=="Active" end,"no active window")
 local p=c:projectile(a,b.root.Position,96,30,3,"kunai")
 c:projectileHit(p,b,b.root.Position,V.zAxis);c:removeProjectile(p)
 assert(b.health<b.def.Health,"fixture: the kunai did not land")
 until_(c,.5,function() return a.state=="Recovery" end,"no recovery")
 assert(not a.chainOpen,"a kunai that landed during a whiff opened the string")
 assert((a.combo or 0)==0,"a kunai that landed during a whiff counted as a string hit")
end)
test("a press just after the chain window still continues; after a pause the string restarts (CORE4)",function()
 for _,id in CORE4 do
  local c,a=opened(id,1)
  until_(c,.6,function() return a.state=="Neutral" end,id..": the recovery never ended")
  H.step(c,.05)
  assert(press(c,a,"Attack"))
  assert(a.attackName=="Light2",id..": a press 0.05 s late restarted the string ("..tostring(a.attackName)..")")
  local c2,x,y=opened(id,1)
  until_(c2,.6,function() return x.state=="Neutral" end,id..": the recovery never ended")
  H.step(c2,.45);place(c2,x,y)
  assert(press(c2,x,"Attack"))
  assert(x.attackName=="Light1",id..": a press after a pause continued a dead string ("..tostring(x.attackName)..")")
 end
end)
test("the directional memory: a strong push is remembered briefly, a weak tilt never, the latest push wins",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,10)
 a.move=toward(a);H.step(c,.03);a.move=V.zero
 H.step(c,.1)
 assert(Brawler.intent(a)=="forward","a push released 0.1 s ago was forgotten")
 H.step(c,.25)
 assert(Brawler.intent(a)=="neutral","a push released 0.35 s ago still steers the route")
 a.move=toward(a)*.3;H.step(c,.05);a.move=V.zero
 assert(Brawler.intent(a)=="neutral","a weak tilt became a route")
 a.move=toward(a);H.step(c,.03);a.move=side(a,1);H.step(c,.03);a.move=V.zero
 local dir,sign=Brawler.intent(a)
 assert(dir=="side" and sign==1,"the latest push did not win ("..tostring(dir)..", "..tostring(sign)..")")
end)
test("air: a whiffed air strike resets the air string; after a confirmed air hit the stick picks drive / spike / switch (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage")
  airborne(c,a,b,30)
  assert(press(c,a,"Attack"));assert(a.attackName=="Air1",id..": first air press is "..tostring(a.attackName))
  airStep(c,b,.8,function() return a.state=="Neutral" end)
  assert(a.state=="Neutral",id..": the air whiff never recovered ("..a.state..")")
  airborne(c,a,b,3)
  assert(press(c,a,"Attack"))
  assert(a.attackName=="Air1",id..": after an air whiff the next air strike is "..tostring(a.attackName))
  local routes=MoveGraphs[id].routes
  for _,pair in {{"toward",routes.airUp},{"away",routes.airDown},{"side",routes.airSide}} do
   local c2,x,y=H.duel(id,"Mirage")
   airborne(c2,x,y,3)
   assert(press(c2,x,"Attack"))
   assert(airStep(c2,y,.6,function() return chainOpen(c2,x) end),id..": the air string never opened")
   assert(x.airCombo==1,id..": one air hit reads as "..tostring(x.airCombo))
   local stick=if pair[1]=="toward" then toward(x) elseif pair[1]=="away" then -toward(x) else side(x,1)
   assert(press(c2,x,"Attack",stick))
   assert(x.attackName==pair[2],id..": air "..pair[1].." gave "..tostring(x.attackName))
  end
 end
end)

test("air: toward pressed a moment late after an air hit still drives (no Air2 by accident) (CORE4)",function()
 -- Studio, real keys: W + click just after Air1's window gave Air2.
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage")
  airborne(c,a,b,3)
  assert(press(c,a,"Attack"))
  assert(airStep(c,b,.6,function() return chainOpen(c,a) end),id..": the air string never opened")
  assert(airStep(c,b,.6,function() return a.state=="Neutral" end),id..": the air hit never recovered")
  assert(a.airborne and (a.airCombo or 0)==1,id..": fixture: not airborne with one air hit")
  assert(press(c,a,"Attack",toward(a)))
  assert(a.attackName==MoveGraphs[id].routes.airUp,id..": the late toward air press gave "..tostring(a.attackName))
 end
end)

-- Phase 2: route table --------------------------------------------------------
test("route table, ground: base string, routes with their payoffs, running attacks, tool branch, disengage, jutsu conversion (CORE4)",function()
 for _,id in CORE4 do
  -- Base string: the third light knocks away and opens the chase.
  local c,a,b=opened(id,2)
  assert(press(c,a,"Attack"));assert(a.attackName==(if id=="GentleFist" and (b.tenketsu or 0)>=3 then "PalmThrust" else "Light3"),id..": the third light is "..tostring(a.attackName))
  until_(c,.6,function() return b.reaction=="Knockback" end,id..": the third light did not knock away")
  assert(a.pursuitUntil>c.now,id..": the knock-away opened no chase window")
  -- Forward route and its payoff.
  local c2,x,y=opened(id,2)
  assert(press(c2,x,"Attack",toward(x)));assert(x.attackName==UP[id])
  until_(c2,.6,function() return y.reaction=="Launched" end,id..": no launch")
  if id=="Flashstep" then
   local body=false;for _,e in x.anchors or {} do if e.actor==y then body=true end end
   assert(body,"Minato's rising kick left no seal on the body")
  elseif id=="Mirage" then
   assert(until_(c2,.6,function() for _,p in c2.projectiles do if p.a==x then return true end end return false end,"no cover"),"Itachi's launcher was not covered")
  elseif id=="Lion" then
   until_(c2,.6,function() return (x.events.ShadowLeaf or 0)>0 end,"Sasuke's rising kick was not followed (Shadow of the Dancing Leaf)")
  end
  -- Low route payoff: Minato's floor seal, Neji's second chakra point.
  local c3,m,n=opened(id,2)
  local points=n.tenketsu or 0
  assert(press(c3,m,"Attack",-toward(m)));assert(m.attackName=="Sweep")
  until_(c3,.6,function() return n.reaction=="Knockdown" end,id..": the sweep did not knock down")
  if id=="Flashstep" then
   local planted=false;for _,e in m.anchors or {} do if not e.actor then planted=true end end
   assert(planted,"Minato's sweep planted no seal")
  elseif id=="GentleFist" then
   assert((n.tenketsu or 0)>=points+2,"Neji's sweep did not close two points ("..tostring(n.tenketsu)..")")
  end
  -- Running attacks out of a sprint (user 28/10): the light is the string's
  -- first blow carried by the run; the heavy is the fighter's running strike
  -- (MoveGraphs runStrike, else its DashAttack).
  local runStrike=(H.load("Shared/MoveGraphs")[id] or {}).runStrike or "DashAttack"
  for _,pair in {{"Attack","Light1"},{"Heavy",runStrike}} do
   local c4,p,q=H.duel(id,"Mirage");place(c4,p,q,11)
   p.sprinting=true;p.locomotion=p.root.CFrame.LookVector*40
   assert(press(c4,p,pair[1]));assert(p.attackName==pair[2],id..": sprint "..pair[1].." is "..tostring(p.attackName))
   until_(c4,.7,function() return if pair[3] then q.reaction==pair[3] else q.reaction~=nil end,id..": "..pair[2].." did not land")
  end
  -- Tool branch: a blade inside a clean string keeps the pressure.
  local c5,t,u=opened(id,1)
  assert(press(c5,t,"Tool",nil,u.root.Position),id..": chain tool refused")
  assert((t.events.ChainTool or 0)>=1,id..": the tool did not cancel the string")
  assert(until_(c5,.4,function() return #c5.projectiles>0 end,id..": no blade"),"no blade")
  -- Disengage: away + tool hops out behind a throw.
  local c6,d,e=opened(id,1)
  local gap=(d.root.Position-e.root.Position).Magnitude
  assert(press(c6,d,"Tool",-toward(d),e.root.Position),id..": disengage refused")
  H.step(c6,.4)
  assert((d.events.Disengage or 0)>=1 and (d.root.Position-e.root.Position).Magnitude>gap+2,id..": the disengage made no space")
  -- Jutsu conversion: the confirmed string cancels into the fighter's technique.
  local c7,j,k=opened(id,1)
  j.chakra=j.def.Chakra
  assert(press(c7,j,slot(j,CANCEL[id]),nil,k.root.Position),id..": no string cancel into "..CANCEL[id])
  assert(j.state=="TechniqueChannel" and j.untilTime-c7.now<=.15,id..": the string cancel kept a full wind-up")
 end
end)
test("route table, air: string, drive, spike bounce, switch, slam and each prodigy's aerial conversion (CORE4)",function()
 for _,id in CORE4 do
  -- Two air hits.
  local c,a,b=H.duel(id,"Mirage");airborne(c,a,b,3)
  assert(press(c,a,"Attack"));assert(airStep(c,b,.6,function() return chainOpen(c,a) end),id..": no air chain")
  assert(press(c,a,"Attack"));assert(a.attackName=="Air2",id..": the second air strike is "..tostring(a.attackName))
  airStep(c,b,.4,function() return (a.events.AirHit or 0)>=2 end)
  assert((a.events.AirHit or 0)>=2,id..": the air string did not land twice")
  -- Slam ends the air phase.
  assert(airStep(c,b,.5,function() return chainOpen(c,a) end),id..": no second air chain")
  assert(press(c,a,"Heavy"));assert(a.attackName=="Slam",id..": air heavy is "..tostring(a.attackName))
  until_(c,1,function() return b.reaction=="Knockdown" end,id..": the slam did not knock down")
  -- Spike: the body bounces once off the floor.
  local c2,x,y=H.duel(id,"Mirage");airborne(c2,x,y,3)
  assert(press(c2,x,"Attack"));assert(airStep(c2,y,.6,function() return chainOpen(c2,x) end))
  local points=y.tenketsu or 0
  assert(press(c2,x,"Attack",-toward(x)));assert(x.attackName=="AirSpike")
  until_(c2,1.6,function() return (y.events or {}).GroundBounce~=nil end,id..": the spike never bounced")
  if id=="GentleFist" then assert((y.tenketsu or 0)>=points+2,"Neji's descending palm did not close two points ("..tostring(y.tenketsu)..")") end
  -- Drive sends the body away; switch keeps the air string.
  local c3,m,n=H.duel(id,"Mirage");airborne(c3,m,n,3)
  assert(press(c3,m,"Attack"));assert(airStep(c3,n,.6,function() return chainOpen(c3,m) end))
  assert(press(c3,m,"Attack",toward(m)));assert(m.attackName=="AirDrive")
  until_(c3,.6,function() return n.reaction=="Knockback" end,id..": the drive did not send the body away")
  local c4,p,q=H.duel(id,"Mirage");airborne(c4,p,q,3)
  assert(press(c4,p,"Attack"));assert(airStep(c4,q,.6,function() return chainOpen(c4,p) end))
  assert(press(c4,p,"Attack",side(p,1)));assert(p.attackName=="AirSwitch")
  assert(airStep(c4,q,.6,function() return chainOpen(c4,p) end),id..": the air switch did not keep the air string")
  assert(p.airCombo==2,id..": the switch did not count as the second air hit")
  -- The prodigy's own aerial conversion.
  if id=="Flashstep" then
   local c5,f,g=H.duel(id,"Mirage");airborne(c5,f,g,3);f.chakra=f.def.Chakra
   assert(press(c5,f,slot(f,"BurstStrike")),"airborne Rasengan refused")
   until_(c5,.5,function() return f.attackVariant=="RasenganDrop" end,"Minato's air Rasengan is not the plunge")
  elseif id=="Mirage" then
   local c5,f,g=H.duel(id,"Mirage");airborne(c5,f,g,12)
   assert(press(c5,f,"Tool",nil,g.root.Position),"air throw refused")
   local seen={};local count=0
   airStep(c5,g,.4,function() for _,p2 in c5.projectiles do if p2.a==f and not seen[p2] then seen[p2]=true;count+=1 end end return false end)
   assert(count>=3,"Itachi's air fan threw "..count.." blades")
  elseif id=="Lion" then
   local c5,f,g=opened(id,2)
   assert(press(c5,f,"Attack",toward(f)));assert(f.attackName=="LionKick")
   until_(c5,1.2,function() return f.state~="Pursuit" and (f.events.ShadowLeaf or 0)>0 end,"no Shadow of the Dancing Leaf")
   assert(press(c5,f,"Heavy"),"Lion Combo refused");assert(f.attackVariant=="LionBarrage","the air heavy was not the Lion Combo")
  end
 end
end)
test("route table, re-engage: chase after a launch, a knock-away and a wall splat, then a route on arrival (CORE4)",function()
 for _,id in CORE4 do
  -- Launch -> chase -> air string.
  local c,a,b=opened(id,2)
  assert(press(c,a,"Heavy"));assert(a.attackName=="Launcher")
  until_(c,.6,function() return b.reaction=="Launched" end,id..": no launch")
  if id~="Lion" then
   assert(press(c,a,"Pursuit"),id..": chase refused after the launch")
   assert(a.state=="Pursuit",id..": the launch chase is "..a.state)
   until_(c,.5,function() return a.state~="Pursuit" end,id..": the chase never arrived")
   assert(press(c,a,"Attack"),id..": no strike after the chase")
   until_(c,.5,function() return (a.events.AirHit or 0)>=1 end,id..": the strike after the chase never connected")
  end
  -- Knock-away -> chase -> strike on arrival.
  local c2,x,y=opened(id,2)
  assert(press(c2,x,"Attack"))
  until_(c2,.6,function() return y.reaction=="Knockback" end,id..": no knock-away")
  H.step(c2,.08)
  local health=y.health
  assert(press(c2,x,"Pursuit"),id..": chase refused after the knock-away")
  assert(x.state=="Pursuit",id..": the knock-away chase is "..x.state)
  until_(c2,.6,function() return x.state~="Pursuit" end,id..": the chase never arrived")
  assert(press(c2,x,"Attack"),id..": no strike on arrival")
  until_(c2,.5,function() return y.health<health end,id..": the strike after the chase never connected")
  -- Wall conversion: a body carried into a wall sticks; chase it, then the
  -- heavy bounces it back out for a fresh air phase.
  H.clearWalls();H.addWall(14)
  local c3,m,n=H.duel(id,"Mirage")
  c3:relocate(m,V.new(-2,3,0));c3:relocate(n,V.new(8,3,0))
  m.root.CFrame=H.C.lookAt(m.root.Position,n.root.Position);n.root.CFrame=H.C.lookAt(n.root.Position,m.root.Position)
  Brawler.react(c3,n,"Knockback",V.new(52,10,0),.5,m)
  until_(c3,.5,function() return n.reaction=="WallSplat" end,id..": the knock-away never splatted")
  n.reactionUntil=c3.now+1
  assert(m.pursuitUntil>c3.now,id..": no chase window after the splat")
  assert(press(c3,m,"Pursuit"),id..": no chase to the wall")
  until_(c3,.6,function() return m.state~="Pursuit" end,id..": the wall chase never arrived")
  assert(press(c3,m,"Heavy"),id..": no heavy on the pinned body")
  until_(c3,.8,function() return (m.events.WallBounce or 0)>=1 end,id..": the heavy did not bounce the body off the wall ("..tostring(m.attackName)..")")
  H.clearWalls()
 end
end)

-- Phase 3: re-engage --------------------------------------------------------
test("re-engage: E outside a window is the chakra dash, inside one it is the chase, both for the same chakra (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,20)
  local chakra=a.chakra
  assert(press(c,a,"Pursuit"),id..": dash refused")
  assert(a.state=="Rush",id..": E outside a window is "..a.state)
  local dash=chakra-a.chakra
  local c2,x,y=opened(id,2)
  assert(press(c2,x,"Heavy"))
  until_(c2,.6,function() return y.reaction=="Launched" end,id..": no launch")
  chakra=x.chakra
  if id~="Lion" then
   assert(press(c2,x,"Pursuit"),id..": chase refused")
   assert(x.state=="Pursuit",id..": E in a window is "..x.state)
   assert(math.abs(dash-(chakra-x.chakra))<.01,string.format("%s: the dash costs %.1f, the chase %.1f",id,dash,chakra-x.chakra))
  end
  assert(math.abs(dash-Config.PursuitCost)<.01,string.format("%s: the dash costs %.1f instead of %.1f",id,dash,Config.PursuitCost))
 end
end)
test("re-engage: the arrival converts at once into a strike but cannot guard at once; unanswered it is punishable (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,20)
  assert(press(c,a,"Pursuit"))
  until_(c,.9,function() return a.state~="Rush" end,id..": the dash never ended")
  assert(a.state=="Recovery",id..": the dash arrival has no recovery ("..a.state..")")
  assert(not c:request(a,"Guard"),id..": the dash arrival guarded at once")
  assert(press(c,a,"Attack"),id..": no strike on arrival")
  assert(a.attackName=="DashAttack",id..": the arrival strike is "..tostring(a.attackName))
  until_(c,.5,function() return b.health<b.def.Health end,id..": the arrival strike never landed")
  -- Heavy on arrival is the fighter's quick heavy.
  local c2,x,y=H.duel(id,"Mirage");place(c2,x,y,20)
  assert(press(c2,x,"Pursuit"))
  until_(c2,.9,function() return x.state~="Rush" end,id..": the dash never ended")
  assert(press(c2,x,"Heavy"),id..": no heavy on arrival")
  assert(x.attackName==QUICK[id],id..": the arrival heavy is "..tostring(x.attackName))
  -- Unanswered: the defender's strike lands before the dasher may guard.
  local c3,m,n=H.duel(id,"Mirage");place(c3,m,n,20)
  assert(press(c3,m,"Pursuit"))
  until_(c3,.9,function() return m.state~="Rush" end,id..": the dash never ended")
  n.root.CFrame=H.C.lookAt(n.root.Position,m.root.Position)
  assert(press(c3,n,"Attack"),"the punish was refused")
  H.step(c3,.02)
  assert(not c3:request(m,"Guard") or m.state~="Guarding" or m.health<m.def.Health,id..": the arrival guarded before the punish")
 end
end)
test("pad re-engage: sprint + dodge toward a locked opponent at mid range is the dash; otherwise it stays a dodge (CORE4)",function()
 for _,id in CORE4 do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,20);a.locked=true;a.sprinting=true
  assert(press(c,a,"Dodge",toward(a)),id..": sprint + dodge toward refused")
  assert(a.state=="Rush",id..": sprint + dodge toward is "..a.state)
  local c2,x,y=H.duel(id,"Mirage");place(c2,x,y,20);x.locked=true;x.sprinting=false
  assert(press(c2,x,"Dodge",toward(x)));assert(x.state=="Dodging",id..": a walking forward dodge became "..x.state)
  local c3,m,n=H.duel(id,"Mirage");place(c3,m,n,20);m.locked=true;m.sprinting=true
  assert(press(c3,m,"Dodge",side(m,1)));assert(m.state=="Dodging",id..": a sprinting side dodge became "..m.state)
  local c4,p,q=H.duel(id,"Mirage");place(c4,p,q,4);p.locked=true;p.sprinting=true
  assert(press(c4,p,"Dodge",toward(p)));assert(p.state=="Dodging",id..": a point-blank forward dodge became "..p.state)
 end
end)
local function dash(id,gap,setup,during)
 local c,a,b=H.duel(id,"Mirage");place(c,a,b,gap);a.locked=true
 if setup then setup(c,a,b) end
 local line=toward(a)
 local start=c.now
 assert(press(c,a,"Pursuit"),id..": dash refused")
 local t=0
 while a.state=="Rush" and t<1 do
  H.step(c,.01);t+=.01
  if during then during(c,a,b,t) end
 end
 assert(a.state~="Rush",id..": the dash never ended")
 local offset=flat(a.root.Position-b.root.Position)
 local angle=math.deg(math.acos(math.clamp((-line):Dot(offset.Unit),-1,1)))
 return {time=c.now-start,gap=offset.Magnitude,angle=angle,c=c,a=a,b=b,right=offset:Dot(V.new(-line.Z,0,line.X))}
end
test("re-engage identity: Minato fastest and on an angle (his seal's side), Itachi calm with an afterimage, Neji on the centre line",function()
 local m,i,n,s=dash("Flashstep",24),dash("Mirage",24),dash("GentleFist",24),dash("Lion",24)
 assert(m.time<i.time and m.time<n.time and m.time<s.time,string.format("Minato is not the fastest re-entry (%.2f / %.2f / %.2f / %.2f s)",m.time,i.time,n.time,s.time))
 assert(i.time>n.time and i.time>s.time,string.format("Itachi's approach is not the calmest (%.2f s)",i.time))
 assert(m.angle>20,string.format("Minato did not arrive on an angle (%.0f deg)",m.angle))
 assert(n.angle<8,string.format("Neji left the centre line (%.0f deg)",n.angle))
 assert(n.gap<i.gap,string.format("Neji does not close in tighter than Itachi (%.1f vs %.1f)",n.gap,i.gap))
 assert(i.angle>8 and i.angle<m.angle,string.format("Itachi does not arrive slightly aside (%.0f deg)",i.angle))
 -- Minato with a seal planted beside the target arrives on the seal's side.
 for _,sign in {1,-1} do
  local sealed=dash("Flashstep",24,function(c,a,b)
   local t=toward(a)
   Techniques.plant(c,a,V.new(b.root.Position.X,0,b.root.Position.Z)+V.new(-t.Z,0,t.X)*sign*6,V.yAxis)
  end)
  assert(sealed.right*sign>1.5,"Minato did not arrive on the side of his seal ("..string.format("%.1f",sealed.right)..")")
  assert(sealed.angle>40,string.format("the seal did not widen Minato's angle (%.0f deg)",sealed.angle))
 end
 -- Itachi leaves an afterimage where he left from.
 local c,a=i.c,i.a
 local ghost=false
 for _,impact in c.impacts do if impact.style=="afterimage" and impact.owner==a.id then ghost=true end end
 assert(ghost,"Itachi's re-engage left no afterimage")
 -- Each style is reported to the client.
 for _,r in {m,i,n,s} do
  local seen=false
  for _,impact in r.c.impacts do if impact.style=="chase" and impact.owner==r.a.id and impact.variant~=nil then seen=true end end
  assert(seen,r.a.fighterId..": the re-engage style was not reported")
 end
end)
test("re-engage identity: Itachi can feint out of his dash with a guard; Neji re-enters from closer; Sasuke commits past a side-stepping target",function()
 -- Itachi: guard during the dash stops it (an afterimage stays) and raises the guard.
 local c,a,b=H.duel("Mirage","Flashstep");place(c,a,b,24);a.locked=true
 assert(press(c,a,"Pursuit"));H.step(c,.08)
 assert(a.state=="Rush","fixture: Itachi is not dashing")
 assert(c:request(a,"Guard"),"Itachi could not feint his dash with a guard")
 assert(a.state=="Guarding","the feint did not end in a guard ("..a.state..")")
 assert((a.events.RushFeint or 0)>=1,"the feint was not reported")
 -- The others are committed to their dash.
 for _,id in {"Flashstep","GentleFist","Lion"} do
  local c2,x,y=H.duel(id,"Mirage");place(c2,x,y,24);x.locked=true
  assert(press(c2,x,"Pursuit"));H.step(c2,.05)
  assert(not c2:request(x,"Guard"),id..": guarded out of a committed dash")
 end
 -- Neji: from 6 studs the others are too close, he is not.
 for _,id in CORE4 do
  local c3,x,y=H.duel(id,"Mirage");place(c3,x,y,6);x.locked=true
  local ok=press(c3,x,"Pursuit")
  if id=="GentleFist" then assert(ok and x.state=="Rush","Neji could not close in from 6 studs")
  else assert(not ok,id.." dashed from 6 studs") end
 end
 -- A target that steps aside 0.08 s into the dash: Minato tracks it, Sasuke runs past.
 local function sidestep(c,a,b,t)
  if t>=.08 and t<.09 then local line=toward(a);c:relocate(b,b.root.Position+V.new(-line.Z,0,line.X)*7) end
 end
 local lion,flash=dash("Lion",30,nil,sidestep),dash("Flashstep",30,nil,sidestep)
 assert(flash.gap<4.5,string.format("Minato lost a side-stepping target (%.1f studs)",flash.gap))
 assert(lion.gap>flash.gap+1.5,string.format("Sasuke tracked like Minato instead of committing (%.1f vs %.1f studs)",lion.gap,flash.gap))
 -- His committed whiff costs more recovery than Minato's surgical one.
 assert(lion.a.untilTime-lion.c.now>flash.a.untilTime-flash.c.now,"Sasuke's committed dash recovers as fast as Minato's")
end)
test("re-engage: an unlocked dash is a straight reposition, not a homing one",function()
 local c,a,b=H.duel("Flashstep","Mirage");place(c,a,b,20);a.locked=false
 local line=side(a,1)
 local from=a.root.Position
 assert(press(c,a,"Pursuit",line),"unlocked dash refused")
 assert(a.state=="Rush","the unlocked dash is "..a.state)
 until_(c,.8,function() return a.state~="Rush" end,"the unlocked dash never ended")
 local moved=flat(a.root.Position-from)
 assert(moved.Magnitude>10,"the unlocked dash barely moved ("..string.format("%.1f",moved.Magnitude)..")")
 assert(moved.Unit:Dot(line)>.9,"the unlocked dash homed onto the opponent")
end)
test("the AI re-engages: every CORE4 bot dashes or chases within a minute, without wedging",function()
 local saved=H.envBase.Random
 H.envBase.Random={new=function(seed)
  local state=(seed or 1)*2654435761%4294967296
  local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
  return {NextNumber=function(_,x,y) local r=roll();if x and y then return x+(y-x)*r end return r end,
   NextInteger=function(_,x,y) return math.floor(x+(y-x+1)*roll()) end}
 end}
 local ok,err=pcall(function()
  local AI=H.load("Server/AI")
  for k,pair in {{"Flashstep","Lion"},{"Mirage","GentleFist"},{"GentleFist","Flashstep"},{"Lion","Mirage"}} do
   local c,a,b,match=H.duel(pair[1],pair[2])
   place(c,a,b,24)
   local one,two=AI.new(c,a,k*7),AI.new(c,b,k*7+3)
   local stuck={}
   local t=0
   while t<60 do
    match.phase="Duel"
    for _,f in {a,b} do if f.health<f.def.Health*.3 then f.health=f.def.Health;f.hum.Health=f.health end end
    one:update(c.now);two:update(c.now);H.step(c,.02);t+=.02
    for _,x in {a,b} do
     -- A wedge is one state (and one swing) that never ends; a long legal
     -- sequence (launcher, chase, air string, slam) is not.
     local key=x.state..":"..tostring(x.attackSerial or 0)..":"..tostring(x.castId)
     if x.state=="Neutral" or x.state=="Guarding" or key~=(stuck[x] and stuck[x].key) then stuck[x]={key=key,t=0} else stuck[x].t+=.02 end
     assert(stuck[x].t<2.5,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
    end
   end
   for _,x in {a,b} do
    local used=(x.events.Rush or 0)+(x.events.Chase or 0)
    print(string.format("   %s: %d dashes, %d chases, %d feints",x.fighterId,x.events.Rush or 0,x.events.Chase or 0,x.events.RushFeint or 0))
    assert(used>=1,x.fighterId.." never re-engaged in a minute")
   end
  end
 end)
 H.envBase.Random=saved
 assert(ok,err)
end)

test("toward held, a press a moment late after two hits still launches (no Light3 by accident)",function()
 -- Studio, real keyboard and mouse: W held, three clicks 0.24 s apart gave
 -- Light3 one time in three when the third click fell just after the window.
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,4)
 local t,second,third=0,false,false
 assert(c:request(a,"Attack"))
 while t<1.4 do
  a.move=V.new(0,0,-1)
  H.step(c,.01);t+=.01
  if not second and t>=.24 then second=true;c:request(a,"Attack") end
  if not third and t>=.74 then third=true;c:request(a,"Attack");assert(a.attackName=="Launcher","the late toward press played "..tostring(a.attackName)) end
 end
 assert(third,"fixture: the third press never happened")
end)
test("a deliberate double tap reaches the buffer (the flood guard sits under it)",function()
 -- The anti-cheat refused a second Attack packet within 0.16 s: a fast
 -- double tap meant to buffer the next light never reached the server.
 local Tune=H.load("Shared/VelmoraCombatConfig")
 assert(Tune.Rates.Attack<=.1,"two presses 0.1 s apart: the second is dropped (gap "..Tune.Rates.Attack..")")
end)

print(string.format("NinjaDuel combo model: %d PASS",passed))
if #failures>0 then error(#failures.." FAIL: "..table.concat(failures," | "),0) end
