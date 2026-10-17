-- Roster wave fighter (DEC-015, NEXT_VALIDATION_ROSTER_SCALE §9): Temari, the
-- long-range zoner. Her fan string (reach and distance), routes (Updraft into
-- rising air, Fan Slam, Fan Pirouette, Fan Dive), the fan gust that replaces a
-- thrown tool (pushes, sends blades back, Wind chakra), the persistent wind
-- zones (Zones.luau: headwind/tailwind, carry, blades turned aside or sped up,
-- fire fed, re-announced flights), Kamaitachi, Great Gust, Rising Whirlwind,
-- the wind step, the glide, Kirikiri Mai, the zoner AI and the AIs that must
-- reach her, the client (fan, zones drawn as wind, re-based flights), her
-- motion family, costume and roster slot.
-- Headless: rules, state, timing, pose math. Feel, readability and the look of
-- the fan, the wind and the costume need native Studio.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local MoveGraphs=H.load("Shared/MoveGraphs")
local Zones=H.load("Server/Zones")
local ChakraTuning=H.load("Server/ChakraTuning")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
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
local function gapOf(a,b) return flat(a.root.Position-b.root.Position).Magnitude end
local function toward(a) return flat(a.target.root.Position-a.root.Position).Unit end
local function side(a,sign) local t=toward(a);return V.new(-t.Z,0,t.X)*(sign or 1) end
local function ev(x,name) return (x.events or {})[name] or 0 end
local function press(c,a,action,stick,aim,opts)
 a.move=stick or V.zero
 local ok,reason=c:request(a,action,aim,nil,opts)
 a.move=V.zero
 return ok,reason
end
local function slot(a,id) for i,t in a.def.Techniques do if t.Id==id then return "Technique"..i end end error("no technique "..id) end
local function zonesOf(c,kind)
 local out={}
 for _,z in c.zones or {} do if not kind or z.kind==kind then table.insert(out,z) end end
 return out
end
-- Temari against `other` with `hits` confirmed fan strikes and the chain open.
local function opened(hits,other,gap)
 local c,a,b=H.duel("Gale",other or "Mirage")
 place(c,a,b,gap or 5.5)
 assert(press(c,a,"Attack"),"opening strike refused")
 chain(c,a,"Light1")
 if (hits or 1)>=2 then
  assert(press(c,a,"Attack"),"second strike refused")
  until_(c,.9,function() return chainOpen(c,a) and a.attackName=="Light2" end,"the second chain never opened")
 end
 return c,a,b
end
-- The client sees a flight as origin + direction x speed x (t - born): that
-- formula must stay on the server's flight (re-based on every change).
local function onPath(c,p,dt)
 local age=math.max(0,c.now-p.born)
 local drawn=p.origin+p.direction*math.min(age*p.speed,p.range)
 return (drawn-p.position).Magnitude<=p.speed*(dt or .01)*1.5+.05,(drawn-p.position).Magnitude
end
-- A long test lane owned by `a`, laid along `direction` from `origin`.
local function testLane(c,a,origin,direction,extra)
 local spec={origin=V.new(origin.X,0,origin.Z),direction=direction,length=80,width=6,life=20}
 for k,v in extra or {} do spec[k]=v end
 return Zones.add(c,a,"Wind",spec)
end

-- Kit identity ---------------------------------------------------------------
test("her kit: a zoner with an iron fan, no blade to throw, three wind techniques, a Wind profile of her own",function()
 local def=H.fighters.Gale
 assert(def and def.Name=="Temari" and def.Age==15,"Temari is not in Fighters")
 assert(def.Tool=="Gust" and def.ToolMastery==nil,"Temari throws blades")
 assert(def.PreferredRange>=16 and def.Zoner,"she does not hold a range")
 local ids={}
 for _,spec in def.Techniques do ids[spec.Id]=spec;assert(spec.Element=="Wind",spec.Id.." is not wind") end
 assert(ids.Kamaitachi and ids.GreatGust and ids.Cyclone,"her techniques are missing")
 assert(def.Awakening.Name=="KIRIKIRI MAI" and def.Awakening.Summon and (def.Awakening.Damage or 1)==1,"the awakening is not Kirikiri Mai without a damage multiplier")
 local graph=MoveGraphs.Gale
 assert(graph.routes.up=="Updraft" and graph.routes.down=="FanSlam" and graph.routes.side=="FanPirouette","her routes are not her own")
 assert(graph.routes.airDown=="FanDive" and graph.routes.airSide==nil,"her air routes")
 assert(graph.reengage and graph.reengage.reposition and graph.reengage.keep>=14,"no re-engage at range")
 assert(ChakraTuning.CharacterMastery.Gale=="WindFan" and ChakraTuning.Preferred.WindFan.Fan=="Wind","no Wind chakra profile")
 assert(ChakraTuning.Masteries.WindFan.levels.Wind==3,"the Wind mastery is not hers")
end)

-- The string ------------------------------------------------------------------
test("the fan string: a longer reach, she stops further out, and the third strike makes distance",function()
 -- From 6.9 studs the closed fan lands with her still at its length; a fist
 -- (Sasuke) has to step in to a body's width first.
 local function contactGap(id)
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,6.9)
  local health=b.health
  assert(press(c,a,"Attack"))
  until_(c,.6,function() return b.health<health end,id..": the strike did not land from 6.9 studs")
  return gapOf(a,b)
 end
 local fan,fist=contactGap("Gale"),contactGap("Lion")
 assert(fan>=5.5,string.format("the fan landed only after she walked in to %.1f studs",fan))
 assert(fist<=fan-1.5,string.format("fixture: the fist landed from %.1f studs (fan %.1f)",fist,fan))
 -- From 9 studs she steps in, but stops at the fan's reach, not at a fist's.
 local c3,m,n=H.duel("Gale","Mirage");place(c3,m,n,9);m.locked=true
 assert(press(c3,m,"Attack"));H.step(c3,.5)
 assert(gapOf(m,n)>=4.6,string.format("she walked into fist range (%.1f studs)",gapOf(m,n)))
 -- Three strikes: the third opens the fan and throws the body away.
 local c4,p,q=opened(2)
 assert(press(c4,p,"Attack"));assert(p.attackName=="Light3","the third press is "..tostring(p.attackName))
 until_(c4,.6,function() return q.reaction=="Knockback" end,"the fan gust did not knock away")
 H.step(c4,.8)
 assert(gapOf(p,q)>=12,string.format("the string ended %.1f studs apart: it made no distance",gapOf(p,q)))
end)
test("routes: toward after two is the Updraft into rising air, away the Fan Slam, sideways the Fan Pirouette throws the body aside",function()
 local c,a,b=opened(2)
 assert(press(c,a,"Attack",toward(a)));assert(a.attackName=="Updraft","toward after two gave "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Launched" end,"the Updraft did not launch")
 assert(#zonesOf(c,"Updraft")==1 and ev(a,"UpdraftHold")==1,"no column of rising air under the body")
 -- Held up: it comes down slowly (a plain launcher's body is down much sooner).
 local t=0
 while b.airborne and t<4 do H.step(c,.01);t+=.01 end
 local c2,x,y=H.duel("Mirage","Flashstep");place(c2,x,y,4.5)
 assert(press(c2,x,"Attack"));chain(c2,x);assert(press(c2,x,"Attack"))
 until_(c2,.9,function() return chainOpen(c2,x) and x.attackName=="Light2" end,"fixture: no second chain")
 assert(press(c2,x,"Attack",toward(x)));until_(c2,.6,function() return y.reaction=="Launched" end,"fixture: no launch")
 local u=0
 while y.airborne and u<4 do H.step(c2,.01);u+=.01 end
 assert(t>u+.35,string.format("the updraft held the body %.2f s against %.2f s for a plain launcher",t,u))
 -- Heavy after two is the Updraft too.
 local c3,m=opened(2)
 assert(press(c3,m,"Heavy"));assert(m.attackName=="Updraft","heavy after two is "..tostring(m.attackName))
 -- Away: the Fan Slam knocks down.
 local c4,p,q=opened(2)
 assert(press(c4,p,"Attack",-toward(p)));assert(p.attackName=="FanSlam","away after two gave "..tostring(p.attackName))
 until_(c4,.6,function() return q.reaction=="Knockdown" end,"the Fan Slam did not knock down")
 -- Sideways after one: a full turn, the body is thrown to the side asked for.
 local c5,s,o=opened(1)
 local right=side(s,1)
 local before=o.root.Position
 assert(press(c5,s,"Attack",right));assert(s.attackName=="FanPirouette","side after one gave "..tostring(s.attackName))
 until_(c5,.6,function() return o.reaction=="Knockback" end,"the pirouette did not throw the body")
 H.step(c5,.6)
 local moved=o.root.Position-before
 assert(moved:Dot(right)>=4,string.format("the body went %.1f studs to the side",moved:Dot(right)))
 assert(math.abs(moved:Dot(toward(s)))<moved:Dot(right),"the body was thrown away, not aside")
 -- Heavy after one: the backhand pushes away.
 local c6,h,k=opened(1)
 assert(press(c6,h,"Heavy"));assert(h.attackName=="FanBackhand","heavy after one is "..tostring(h.attackName))
 until_(c6,.6,function() return k.reaction=="Knockback" end,"the backhand did not push away")
end)
test("the air route: after an air hit, away is the Fan Dive that drives the body into the floor; toward the drive",function()
 local function airborne(dir)
  local c,a,b=H.duel("Gale","Mirage")
  c:relocate(a,V.new(0,16,3));c:relocate(b,V.new(0,16,-2))
  a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
  for _,x in {a,b} do x.airborne=true end
  a.airHold=c.now+2;H.envBase=H.envBase
  local Brawler=H.load("Server/Brawler")
  Brawler.react(c,b,"Juggled",V.zero,2,a)
  assert(press(c,a,"Attack"),"air strike refused")
  until_(c,.6,function() return chainOpen(c,a) end,"the air strike never chained")
  b.reactionVelocity=V.zero;b.reactionUntil=c.now+2
  assert(press(c,a,"Attack",if dir=="back" then -toward(a) else toward(a)))
  return c,a,b
 end
 local c,a,b=airborne("back")
 assert(a.attackName=="FanDive","away after an air hit gave "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Spiked" end,"the Fan Dive did not spike")
 local c2,x=airborne("forward")
 assert(x.attackName=="AirDrive","toward after an air hit gave "..tostring(x.attackName))
end)

-- The fan gust (tool) -----------------------------------------------------------
test("the gust: the body in the cone is pushed out without damage, blades are sent back at their thrower, fire grows",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,9)
 local chakra=a.chakra
 assert(press(c,a,"Tool",nil,b.root.Position),"the gust was refused")
 assert(math.abs(chakra-a.chakra-Config.ToolCost)<.01,"the gust did not cost the tool price")
 until_(c,.4,function() return b.reaction=="Knockback" end,"the body in the cone was not pushed")
 H.step(c,.6)
 assert(b.health==b.def.Health,"the gust did damage")
 assert(gapOf(a,b)>=13,string.format("the gust pushed the body to %.1f studs",gapOf(a,b)))
 local ok,why=press(c,a,"Tool",nil,b.root.Position)
 assert(ok or why=="Tool recovering","second gust: "..tostring(why))
 -- A kunai flying at her: sent back, it hits its thrower.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,16)
 -- (a contact radius: the harness has no body geometry for a bare ray)
 local blade=c2:projectile(y,x.root.Position,80,30,3,"kunai",nil,{radius=.3})
 H.step(c2,.05)
 assert(press(c2,x,"Tool",nil,y.root.Position))
 until_(c2,.4,function() return not table.find(c2.projectiles,blade) end,"the blade was never stopped")
 local back
 for _,p in c2.projectiles do if p.a==x and p.kind=="kunai" then back=p end end
 assert(back and back.bounced,"the blade was not sent back")
 until_(c2,1,function() return y.health<y.def.Health end,"the blade sent back never reached its thrower")
 assert(x.health==x.def.Health,"the blade still hit her")
 assert(ev(x,"GustReturn")==1,"the return was not reported")
 -- A fireball in the cone is not stopped: it grows (fire feeds on wind).
 local c3,m,n=H.duel("Gale","Mirage");place(c3,m,n,16)
 local fire=c3:projectile(n,m.root.Position,40,40,8,"fireball",nil,{radius=1.4})
 H.step(c3,.12)
 local before=fire.radius+fire.growth*(c3.now-fire.born)
 assert(press(c3,m,"Tool",nil,n.root.Position))
 H.step(c3,.12)
 assert(table.find(c3.projectiles,fire) or fire.radius>before,"the gust swallowed the fire")
 assert(fire.radius>=before*1.4,string.format("the fire did not grow (%.2f -> %.2f)",before,fire.radius))
end)
test("the gust inside a clean string is free, and away + gust hops her out behind it",function()
 local c,a,b=opened(1)
 local chakra=a.chakra
 local from=a.root.Position
 assert(press(c,a,"Tool",-toward(a),b.root.Position),"the string gust was refused")
 assert(a.chakra>=chakra-.01,"the gust inside a string cost chakra")
 H.step(c,.4)
 assert(ev(a,"ChainTool")==1 and ev(a,"Disengage")==1,"no disengage gust")
 assert(flat(a.root.Position-from):Dot(-toward(a))>=4,"she did not hop back out of the string")
end)
test("chakra modifier on the gust: a Wind infusion of the fan (her profile) reaches further and leaves a lane; refused with a fizzle when short",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,22)
 local chakra=a.chakra
 assert(press(c,a,"Tool",nil,b.root.Position,{chakra=true}),"the wind gust was refused")
 local cost=chakra-a.chakra
 assert(cost>Config.ToolCost+4-.01,string.format("the infused gust cost %.1f",cost))
 H.step(c,.2)
 local lanes=zonesOf(c,"Wind")
 assert(#lanes==1,"the wind gust left no lane")
 assert(lanes[1].length>=a.def.Gust.Range*1.3,"the lane is not the longer gust")
 assert(b.reaction=="Knockback","the longer gust did not reach 22 studs")
 local log=false
 for _,row in c.chakraLog or {} do if row.object=="Fan" and row.infusion=="Wind" then log=true end end
 assert(log,"the infusion was not logged")
 -- Short of chakra: the fizzle, nothing spent, no lane.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,10)
 x.chakra=8
 local ok,why=press(c2,x,"Tool",nil,y.root.Position,{chakra=true})
 assert(not ok and why=="Need chakra" and x.chakra==8,"the refused wind gust: "..tostring(why))
 assert(ev(x,"ChakraRefused")==1 and #zonesOf(c2)==0,"no fizzle, or a lane anyway")
end)

-- Zones -----------------------------------------------------------------------------
local function walkSpeed(lane,dir)
 local c,a,b=H.duel("Gale","Mirage")
 place(c,a,b,40)
 c:relocate(a,V.new(0,3,0));b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.xAxis)
 if lane then testLane(c,b,V.new(-130,0,0),V.xAxis,{length=260,width=8}) end
 a.move=dir;H.step(c,.6)
 local from=a.root.Position
 a.move=dir;H.step(c,1)
 local moved=flat(a.root.Position-from):Dot(dir)
 a.move=V.zero
 return moved,c,a
end
test("wind lane: into the wind she walks x0.7, with it x1.15 (the same walk outside a lane is the reference)",function()
 local still=walkSpeed(false,V.xAxis)
 local tail=walkSpeed(true,V.xAxis)
 local head=walkSpeed(true,-V.xAxis)
 -- (the carry adds its own drift downwind on top of the walk)
 local carry=Zones.KINDS.Wind.carry
 assert(math.abs((tail-carry)/still-1.15)<.06,string.format("tailwind walk %.1f vs %.1f",tail-carry,still))
 assert(math.abs((head+carry)/still-.7)<.06,string.format("headwind walk %.1f vs %.1f",head+carry,still))
end)
test("wind lane: a free body is carried downwind, more in the air; a body above the lane is not",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,30)
 testLane(c,a,V.new(-40,0,b.root.Position.Z),V.xAxis)
 local from=b.root.Position
 H.step(c,1)
 local carried=flat(b.root.Position-from):Dot(V.xAxis)
 assert(carried>=Zones.KINDS.Wind.carry*.8,string.format("the body drifted %.1f studs",carried))
 -- Off the floor (a jump inside the lane) the wind takes it further.
 b.airborne=true;c:relocate(b,b.root.Position+V.new(0,3,0))
 local up=b.root.Position
 Zones.step(c,.1)
 local floating=flat(b.root.Position-up):Dot(V.xAxis)
 assert(floating>=Zones.KINDS.Wind.airCarry*.1*.9 and floating>Zones.KINDS.Wind.carry*.1,string.format("in the air it drifted %.2f in 0.1 s",floating))
 -- Twelve studs up (a jump over the lane) the wind does not reach it.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,30)
 testLane(c2,x,V.new(-40,0,y.root.Position.Z),V.xAxis)
 c2:relocate(y,y.root.Position+V.new(0,10,0))
 assert(not Zones.inside(c2.zones[1],y.root.Position),"the lane reaches over a jump")
end)
test("wind lane: a blade flying up it is turned aside (she gets chakra back), the re-based flight stays on the client's path",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,30)
 -- Her lane blows from her toward Itachi; his kunai flies up it at her.
 testLane(c,a,a.root.Position+toward(a)*2,toward(a))
 a.chakra=50
 local blade=c:projectile(b,a.root.Position,80,40,3,"kunai",nil,{radius=.3})
 local course=blade.direction
 local worst=0
 for _=1,80 do
  H.step(c,.01)
  if not table.find(c.projectiles,blade) then break end
  local ok,miss=onPath(c,blade)
  worst=math.max(worst,miss)
  assert(ok,string.format("the flight left its announced path by %.2f studs",miss))
 end
 assert(blade.leg and blade.leg>=1,"the blade was never turned aside")
 assert(blade.direction:Dot(course)<.75,"the blade still flies at her")
 H.step(c,.6)
 assert(a.health==a.def.Health,"the turned blade still hit her")
 assert(a.chakra>=51.9 and ev(a,"WindDeflect")==1,"no chakra back for the turned blade")
 local drawn=false
 for _,impact in c.impacts do if impact.style=="winddeflect" then drawn=true end end
 assert(drawn,"the client was not told the blade was turned")
end)
test("wind lane: a blade riding it flies x1.4 and hits harder; jutsu volumes go through unchanged",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,30)
 -- The lane blows from Itachi toward her: his kunai rides it.
 testLane(c,a,b.root.Position+toward(b)*1.5,toward(b))
 local blade=c:projectile(b,a.root.Position,80,40,3,"kunai",nil,{radius=.3})
 H.step(c,.05)
 assert(math.abs(blade.speed-80*1.4)<.01,"the riding blade flies at "..blade.speed)
 until_(c,1,function() return a.health<a.def.Health end,"the riding blade never landed")
 assert(math.abs(a.def.Health-a.health-(3+1))<.01,string.format("the riding blade did %.1f",a.def.Health-a.health))
 for _,kind in {"palm","sandwave","gale"} do
  local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,30)
  testLane(c2,x,x.root.Position+toward(x)*2,toward(x))
  local p=c2:projectile(y,x.root.Position,60,40,3,kind,nil,{radius=1})
  H.step(c2,.15)
  assert(not p.leg and p.speed==60,kind.." was changed by the wind")
 end
end)
test("wind lane: fire that crosses it grows and burns harder, even the opponent's fire against her",function()
 local function crossing(withLane)
  local c,a,b=H.duel("Gale","Mirage");place(c,a,b,30)
  if withLane then testLane(c,a,V.new(-20,0,0),V.xAxis) end
  local fire=c:projectile(b,a.root.Position,58,40,10,"fireball",nil,{radius=1.4,growth=.5})
  H.step(c,.4)
  return fire,c
 end
 local plain=crossing(false)
 local fed,c=crossing(true)
 local function size(p,now) return p.radius+p.growth*(now-p.born) end
 assert(size(fed,c.now)>=size(plain,c.now)*1.4,string.format("the fire did not grow (%.2f vs %.2f)",size(fed,c.now),size(plain,c.now)))
 assert(fed.damage>=12-.01,"the fed fire does "..fed.damage)
 assert(fed.leg==1,"the fire was fed more than once by one lane")
end)
test("wind lane: a chakra dash straight up it breaks in the lane and stumbles; round it, the dash arrives; her own lane never breaks her step",function()
 local function dash(withLane,offset)
  local c,a,b=H.duel("Lion","Gale");place(c,a,b,26);a.locked=true
  -- Her lane blows from her down the line at him.
  if withLane then testLane(c,b,b.root.Position+toward(b)*2+(offset or V.zero),toward(b),{width=4}) end
  assert(press(c,a,"Pursuit"),"the dash was refused")
  local recovery
  until_(c,1,function() if a.state=="Recovery" then recovery=a.untilTime-c.now end return a.state~="Rush" end,"the dash never ended")
  return gapOf(a,b),recovery,a,b
 end
 local free,freeRecovery=dash(false)
 local broken,brokenRecovery,a,b=dash(true)
 assert(free<5,"fixture: the dash did not arrive ("..free..")")
 assert(broken>free+6,string.format("up her lane the dash still arrived (%.1f studs)",broken))
 assert(brokenRecovery>freeRecovery+.15,"the broken dash did not stumble")
 assert(ev(b,"WindBreak")==1,"the break was not reported to her")
 -- A lane off to the side of the line: the dash is untouched.
 local aside=dash(true,V.new(12,0,0))
 assert(aside<5,"a lane beside the line broke the dash")
 -- Her own wind step out through her own lane is never broken.
 local c2,x,y=H.duel("Gale","Lion");place(c2,x,y,6);x.locked=true
 testLane(c2,x,x.root.Position,toward(x),{width=6,origin=x.root.Position-toward(x)*4})
 assert(press(c2,x,"Pursuit"),"her step was refused")
 until_(c2,1,function() return x.state~="Rush" end,"her step never ended")
 assert(gapOf(x,y)>=14 and ev(x,"WindBreak")==0,"her own lane broke her wind step")
end)
test("zones end: a lane's life, and every zone goes with a KO (Combat:clear); the snapshot lists them per kind",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,20)
 testLane(c,a,V.zero,V.xAxis,{life=.5})
 Zones.add(c,a,"Updraft",{origin=V.new(5,0,5),radius=3,life=5})
 local list=Zones.snapshot(c,c.now)
 assert(#list==2,"the snapshot does not list both zones")
 local seen={}
 for _,z in list do seen[z.kind]=z end
 assert(seen.Wind and seen.Wind.owner==a.id and seen.Wind.length==80 and seen.Wind.direction:Dot(V.xAxis)>.99,"the lane snapshot")
 assert(seen.Updraft and seen.Updraft.radius==3,"the column snapshot")
 H.step(c,.6)
 assert(#zonesOf(c,"Wind")==0 and #zonesOf(c,"Updraft")==1,"the lane outlived its life")
 c:damage(a,b,b.health+50,false,false)
 assert(c.match.phase~="Duel" and #zonesOf(c)==0,"a zone outlived the KO")
end)

-- Techniques -----------------------------------------------------------------------
test("Kamaitachi: a wind scythe that knocks away (a wall splat at range) and lays its lane as it flies; 12 chakra, a cooldown, an interruptible channel",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,20)
 local chakra=a.chakra
 assert(press(c,a,slot(a,"Kamaitachi"),nil,b.root.Position),"Kamaitachi was refused")
 assert(math.abs(chakra-a.chakra-12)<.01 and (a.cooldowns.Kamaitachi or 0)>c.now+2.5,"cost or cooldown")
 assert(a.state=="TechniqueChannel","no channel (the fan opening)")
 until_(c,.5,function() for _,p in c.projectiles do if p.kind=="gale" then return true end end return false end,"no wind scythe")
 local scythe
 for _,p in c.projectiles do if p.kind=="gale" then scythe=p end end
 local lane=zonesOf(c,"Wind")[1]
 assert(lane and lane.carrier==scythe,"the scythe lays no lane")
 H.step(c,.08)
 assert(lane.reach>1 and lane.reach<lane.length,"the lane does not grow with the scythe ("..lane.reach..")")
 until_(c,.6,function() return b.reaction~=nil end,"the scythe never reached the body")
 assert(b.reaction=="Knockback","the scythe hit gave "..tostring(b.reaction))
 H.step(c,.1)
 assert(lane.carrier==nil and lane.reach<lane.length,"the lane did not stop where the scythe ended")
 -- With a wall behind the body, the wind splats it there.
 local c2,x,y=H.duel("Gale","Mirage")
 c2:relocate(x,V.new(-10,3,0));c2:relocate(y,V.new(4,3,0))
 x.root.CFrame=H.C.lookAt(x.root.Position,y.root.Position);y.root.CFrame=H.C.lookAt(y.root.Position,x.root.Position)
 H.addWall(9)
 assert(press(c2,x,slot(x,"Kamaitachi"),nil,y.root.Position))
 until_(c2,1.5,function() return y.reaction=="WallSplat" end,"the scythe did not splat the body on the wall")
 -- A strike during the fan's opening interrupts it: no scythe.
 local c3,m,n=H.duel("Gale","Mirage");place(c3,m,n,4.5)
 assert(press(c3,m,slot(m,"Kamaitachi"),nil,n.root.Position))
 assert(press(c3,n,"Attack"))
 until_(c3,.5,function() return ev(n,"Interrupt")>0 end,"the channel was not interrupted")
 H.step(c3,.4)
 for _,p in c3.projectiles do assert(p.kind~="gale","an interrupted channel still threw the scythe") end
end)
test("Great Gust: blades in the cone are blown away, fire grows, the body is thrown to a wall, a wide lane stays; wind scatters a sand shield",function()
 local c,a,b=H.duel("Gale","Mirage")
 c:relocate(a,V.new(-12,3,0));c:relocate(b,V.new(6,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 H.addWall(14)
 -- (slow blades: still in front of her when the three moons are open)
 local k1=c:projectile(b,a.root.Position,12,40,3,"kunai",nil,{origin=V.new(4,4,0)})
 local k2=c:projectile(b,a.root.Position,12,40,3,"shuriken",nil,{origin=V.new(2,4,1)})
 assert(press(c,a,slot(a,"GreatGust"),nil,b.root.Position),"Great Gust was refused")
 until_(c,.8,function() return ev(a,"GreatGust")>0 end,"the gust never came out")
 assert(not table.find(c.projectiles,k1) and not table.find(c.projectiles,k2),"a blade survived the Great Gust")
 assert(b.health<b.def.Health,"the gust did no damage")
 until_(c,1,function() return b.reaction=="WallSplat" end,"the body was not thrown to the wall")
 local lane=zonesOf(c,"Wind")[1]
 assert(lane and lane.width>=5 and lane.length>=28,"no wide lane")
 -- A fireball in the cone is not blown away: it grows.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,20)
 local fire=c2:projectile(y,x.root.Position,8,40,10,"fireball",nil,{radius=1.4,origin=y.root.Position+toward(y)*3})
 assert(press(c2,x,slot(x,"GreatGust"),nil,y.root.Position))
 until_(c2,.8,function() return ev(x,"GreatGust")>0 end,"no gust")
 assert(table.find(c2.projectiles,fire) and (fire.fed or 0)>=1 and fire.damage>=12-.01,"the fire in the cone did not grow")
 -- Wind scatters sand: Gaara's shield breaks outright under the gust (and the scythe).
 local c3,m,n=H.duel("Gale","Sand");place(c3,m,n,16)
 assert(n.shieldCharges==3,"fixture: no sand shield")
 assert(press(c3,m,slot(m,"GreatGust"),nil,n.root.Position))
 until_(c3,.8,function() return ev(m,"GreatGust")>0 end,"no gust on Gaara")
 assert(n.shieldCharges==0,"the gust left "..n.shieldCharges.." shield charges")
 local c4,s2,g=H.duel("Gale","Sand");place(c4,s2,g,16)
 assert(press(c4,s2,slot(s2,"Kamaitachi"),nil,g.root.Position))
 until_(c4,1,function() return g.shieldCharges<3 end,"the scythe never reached the shield")
 assert(g.shieldCharges==0,"the scythe took only one charge of the shield")
end)
test("Rising Whirlwind: the spot is marked, a beat later the column rises; a body still there is thrown up and held, one that moved is not",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,20)
 assert(press(c,a,slot(a,"Cyclone"),nil,b.root.Position),"the whirlwind was refused")
 local marked=false
 until_(c,.5,function() for _,i in c.impacts do if i.style=="cyclone" and i.phase=="mark" then marked=true end end return marked end,"the spot was not marked")
 assert(#zonesOf(c,"Updraft")==0,"the column rose without its beat")
 until_(c,.8,function() return b.reaction=="Launched" end,"the body standing there was not thrown up")
 assert(#zonesOf(c,"Updraft")==1 and ev(a,"CycloneHit")==1,"no column")
 local t=0
 while b.airborne and t<4 do H.step(c,.01);t+=.01 end
 assert(t>=1.6,string.format("the body was held only %.2f s",t))
 -- Kept moving: untouched.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,20)
 assert(press(c2,x,slot(x,"Cyclone"),nil,y.root.Position))
 H.step(c2,.3)
 c2:relocate(y,y.root.Position+V.new(6,0,0))
 H.step(c2,.6)
 assert(y.health==y.def.Health and y.reaction==nil,"the whirlwind followed a body that moved")
end)

-- Re-engage, defence, air ----------------------------------------------------------
test("the wind step (E outside a chase window): out to her range at an angle when close, in to her range when far, aside at range",function()
 local function step(gap,setup)
  local c,a,b=H.duel("Gale","Mirage");place(c,a,b,gap);a.locked=true
  if setup then setup(c,a,b) end
  local chakra=a.chakra
  local from=a.root.Position
  local line=toward(a)
  assert(press(c,a,"Pursuit"),"the wind step was refused at "..gap)
  assert(a.state=="Rush" and math.abs(chakra-a.chakra-Config.PursuitCost)<.01,"not the shared dash's price")
  until_(c,1,function() return a.state~="Rush" end,"the wind step never ended")
  return c,a,b,from,line
 end
 local c,a,b,from,line=step(5)
 assert(gapOf(a,b)>=14,string.format("from 5 studs she stepped to %.1f",gapOf(a,b)))
 local moved=flat(a.root.Position-from)
 assert(math.abs(moved:Dot(V.new(-line.Z,0,line.X)))>=2,"straight back: no angle")
 local c2,x,y=step(40)
 assert(gapOf(x,y)>=14 and gapOf(x,y)<=22,string.format("from 40 studs she stopped at %.1f (never into melee)",gapOf(x,y)))
 local c3,m,n=step(17)
 assert(gapOf(m,n)>=13 and gapOf(m,n)<=22,string.format("at range the step changed the gap to %.1f",gapOf(m,n)))
 assert(ev(m,"WindStep")==1 and ev(m,"Reengage")==1,"not reported as her re-engage")
 local seen=false
 for _,impact in c3.impacts do if impact.style=="chase" and impact.variant=="gale" then seen=true end end
 assert(seen,"the client was not told it is her wind step")
 -- Inside a chase window E is still the shared chase, at the body.
 local c4,p,q=H.duel("Gale","Mirage");place(c4,p,q,12)
 p.pursuitUntil=c4.now+.8
 assert(press(c4,p,"Pursuit"))
 assert(p.state=="Pursuit","inside a chase window E is "..p.state)
end)
test("the wind's retreat: her substitution jumps 14 studs back instead of 8",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b)
 assert(press(c,b,"Attack"))
 until_(c,.5,function() return a.reaction~=nil end,"fixture: no hit")
 local before=gapOf(a,b)
 assert(c:request(a,"Substitute"),"the substitution was refused")
 assert(gapOf(a,b)-before>=12,string.format("she hopped %.1f studs",gapOf(a,b)-before))
end)
test("the glide: jump held in the air, the open fan caps her fall; released, she drops",function()
 local function fall(held)
  local c,a,b=H.duel("Gale","Mirage");place(c,a,b,20)
  c:relocate(a,V.new(0,15,10));a.airborne=true
  a.root.AssemblyLinearVelocity=V.zero
  if held then c:request(a,"Jump") end
  local t,fastest=0,0
  while a.airborne and t<4 do H.step(c,.01);t+=.01;fastest=math.max(fastest,-a.root.AssemblyLinearVelocity.Y) end
  return t,fastest,a
 end
 local glide,top,a=fall(true)
 local drop=fall(false)
 assert(glide>drop+.3,string.format("held %.2f s against %.2f s",glide,drop))
 assert(top<=16,string.format("the glide fell at %.1f studs/s",top))
 assert(ev(a,"Glide")==1,"the glide was not reported")
end)

-- Awakening ---------------------------------------------------------------------------
test("Kirikiri Mai: Kamatari cuts across with a long lane; awakened lanes send blades back and every gust lays one; no damage bonus; then the fan stays shut",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,24)
 assert(not c:request(a,"Awaken"),"awakened at full health")
 a.health=a.def.Health*.3;a.hum.Health=a.health
 assert(c:request(a,"Awaken"),"the awakening was refused")
 local kamatari
 for _,p in c.projectiles do if p.kind=="kamatari" then kamatari=p end end
 assert(kamatari and kamatari.radius>=2.5,"no Kamatari")
 local lane=zonesOf(c,"Wind")[1]
 assert(lane and lane.carrier==kamatari and lane.reflect,"Kamatari lays no returning lane")
 assert(lane.expires-c.now>=8.9 and lane.width>=5.8,"the awakened lane is not longer and wider")
 until_(c,1,function() return b.reaction=="Knockdown" end,"Kamatari did not knock the body down")
 -- An awakened lane sends a blade back at its thrower.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,30)
 x.health=x.def.Health*.3;x.hum.Health=x.health
 assert(c2:request(x,"Awaken"))
 for _,p in table.clone(c2.projectiles) do c2:removeProjectile(p) end
 table.clear(c2.zones)
 H.step(c2,.5)
 local awakenedLane=H.load("Server/Gale").lane(c2,x,x.root.Position+toward(x)*2,toward(x),30,3.2,3.6)
 assert(awakenedLane.reflect,"an awakened lane does not return blades")
 local health=y.health
 local blade=c2:projectile(y,x.root.Position,80,40,3,"kunai",nil,{radius=.3})
 until_(c2,.6,function() return not table.find(c2.projectiles,blade) end,"the blade went through")
 until_(c2,1,function() return y.health<health end,"the returned blade never reached its thrower")
 assert(x.health==x.def.Health*.3,"the blade still hit her")
 -- A plain gust lays a lane while awakened.
 table.clear(c2.zones)
 x.neutralToolAt=0
 assert(press(c2,x,"Tool",nil,y.root.Position))
 H.step(c2,.2)
 assert(#zonesOf(c2,"Wind")==1,"an awakened gust laid no lane")
 -- No damage multiplier.
 local before=y.health
 c2:damage(x,y,10,false,false)
 assert(math.abs(before-y.health-10)<.5 or y.impactStyle=="block","the awakening multiplied her damage")
 -- When it ends, the fan stays shut for a moment.
 x.awakenUntil=c2.now-.1;x.cooldowns={};x.chakra=100;x.state="Neutral";x.untilTime=c2.now
 local ok,why=c2:request(x,slot(x,"Kamaitachi"),y.root.Position)
 assert(not ok and why=="Fan closed","after the awakening: "..tostring(why))
 x.awakenUntil=c2.now-3.1
 assert(c2:request(x,slot(x,"Kamaitachi"),y.root.Position),"the fan never opened again")
end)

-- AI ---------------------------------------------------------------------------------
local function seeded(fn)
 local saved=H.envBase.Random
 H.envBase.Random={new=function(seed)
  local state=(seed or 1)*2654435761%4294967296
  local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
  return {NextNumber=function(_,x,y) local r=roll();if x and y then return x+(y-x)*r end return r end,
   NextInteger=function(_,x,y) return math.floor(x+(y-x+1)*roll()) end}
 end}
 local ok,err=pcall(fn)
 H.envBase.Random=saved
 assert(ok,err)
end
test("the AI zones: at range the scythe and the whirlwind, blades sent back, at the fan's length the tip, too close the gust or the wind step, a floating body converted at range",function()
 local AI=H.load("Server/AI")
 local function bot(c,a,seed,roll)
  local x=AI.new(c,a,seed)
  x.rng={NextNumber=function(_,p,q) if p and q then return p end return roll end}
  x.probing=false;x.modeUntil=c.now+30;x.observed=a.target.state;x.observedAt=c.now-1
  return x
 end
 -- At 26 studs: Kamaitachi.
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,26);a.locked=true
 local z=bot(c,a,3,.1)
 for _=1,30 do z:update(c.now);H.step(c,.02);if a.castId then break end end
 assert(a.castId=="Kamaitachi","at range the bot cast "..tostring(a.castId))
 -- Coming in fast at 20 studs: a whirlwind ahead of him, or the Great Gust.
 local c2,x,y=H.duel("Gale","Mirage");place(c2,x,y,20);x.locked=true
 local z2=bot(c2,x,5,.25)
 y.locomotion=toward(y)*20
 for _=1,30 do z2:update(c2.now);H.step(c2,.02);y.locomotion=toward(y)*20;if x.castId then break end end
 assert(x.castId=="Cyclone" or x.castId=="GreatGust","an approach was answered with "..tostring(x.castId))
 -- Walking into the fan's length (6 studs): the tip first.
 local c6,f,g=H.duel("Gale","Mirage");place(c6,f,g,6.5);f.locked=true
 local z6=bot(c6,f,4,.1)
 for _=1,10 do z6:update(c6.now);H.step(c6,.02);if f.attackName then break end end
 assert(f.attackName=="Light1","at the fan's length the bot answered with "..tostring(f.attackName))
 -- Inside it (3.5 studs): the gust pushes him out (or she steps away on the wind).
 local c3,m,n=H.duel("Gale","Mirage");place(c3,m,n,3.5);m.locked=true
 local z3=bot(c3,m,7,.1)
 for _=1,20 do z3:update(c3.now);H.step(c3,.02);if ev(m,"Gust")+ev(m,"WindStep")>0 then break end end
 assert(ev(m,"Gust")+ev(m,"WindStep")>0,"too close, the bot did nothing about it")
 -- A kunai coming at her: the gust sends it back.
 local c4,p,q=H.duel("Gale","Mirage");place(c4,p,q,20);p.locked=true
 local z4=bot(c4,p,9,.1)
 c4:projectile(q,p.root.Position,60,30,3,"kunai")
 H.step(c4,.05)
 for _=1,20 do z4:update(c4.now);H.step(c4,.02);if ev(p,"Gust")>0 then break end end
 assert(ev(p,"Gust")>0,"a blade coming at her was not answered by the gust")
 -- A body held up in the air at 14 studs: converted at range, not chased.
 local c5,s,o=H.duel("Gale","Mirage");place(c5,s,o,14);s.locked=true
 local Brawler=H.load("Server/Brawler")
 c5:relocate(o,o.root.Position+V.new(0,6,0));Brawler.react(c5,o,"Launched",V.zero,2,s)
 local z5=bot(c5,s,11,.1)
 for _=1,20 do z5:update(c5.now);H.step(c5,.02);o.reactionVelocity=V.zero;if s.castId or ev(s,"Gust")>0 then break end end
 assert(s.castId=="Kamaitachi" or ev(s,"Gust")>0,"the floating body was not converted at range")
 assert(ev(s,"Chase")==0,"she chased into melee")
end)
test("the AIs that fight her: no probing at her range, and a wind lane blowing against the approach is left sideways",function()
 local AI=H.load("Server/AI")
 local c,a,b=H.duel("Lion","Gale");place(c,a,b,24)
 -- Her lane blows from her straight down his way in.
 testLane(c,b,b.root.Position+toward(b)*2,toward(b),{width=5})
 local z=AI.new(c,a,13)
 z.rng={NextNumber=function(_,p,q) if p and q then return p end return .9 end}
 z.observed=b.state;z.observedAt=c.now-1
 for _=1,12 do z:update(c.now);H.step(c,.05) end
 assert(not z.probing,"he probes at a zoner's range")
 assert(ev(a,"LaneAvoid")>0,"he never stepped out of the lane")
 local lane=c.zones[1]
 assert(not Zones.inside(lane,a.root.Position),"after a second he still walks up her lane")
 -- Out of it, he goes in.
 local out=gapOf(a,b)
 for _=1,16 do z:update(c.now);H.step(c,.05) end
 assert(gapOf(a,b)<out-4,string.format("out of the lane he did not go in (%.1f -> %.1f)",out,gapOf(a,b)))
end)
test("the AIs that fight her never dash straight up her lane (it would break there); round it they still do",function()
 local AI=H.load("Server/AI")
 local function dashes(withLane)
  local c,a,b=H.duel("Lion","Gale");place(c,a,b,26);a.locked=true
  if withLane then testLane(c,b,b.root.Position+toward(b)*2,toward(b),{width=2.5}) end
  -- (outside the lane himself, on its line further back: only the dash would cross it)
  c:relocate(a,a.root.Position+toward(a)*-1)
  local z=AI.new(c,a,21)
  z.rng={NextNumber=function(_,p,q) if p and q then return p end return .001 end}
  z.observed=b.state;z.observedAt=c.now-1;z.probing=false;z.modeUntil=c.now+30
  -- (no blade or jutsu this second: only the way in is measured)
  z.techReadyAt=c.now+30;a.neutralToolAt=c.now+30
  for _=1,10 do z:update(c.now);H.step(c,.05);if ev(a,"Rush")>0 then break end end
  return ev(a,"Rush")
 end
 assert(dashes(false)>0,"fixture: the bot does not dash in")
 assert(dashes(true)==0,"the bot dashed straight up her lane")
end)
test("AI duels: Temari against every fighter, both ways and the mirror, to the KO without wedging; every flight stays on the path the client draws",function()
 seeded(function()
  local AI=H.load("Server/AI")
  local opponents={"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf","Gale"}
  local totals={scythes=0,lanes=0,turned=0,gusts=0,steps=0,taken=0,duels=0,far=0,ticks=0}
  for k,other in opponents do
   for _,pair in (if other=="Gale" then {{"Gale","Gale"}} else {{"Gale",other},{other,"Gale"}}) do
    local c,a,b,match=H.duel(pair[1],pair[2])
    place(c,a,b,22)
    a.locked=true;b.locked=true
    local one,two=AI.new(c,a,k*7+1),AI.new(c,b,k*7+4)
    local stuck={}
    local t=0
    local lanes=0
    -- (two ranged fighters, her and Gaara behind his shield, fight longer)
    while match.phase=="Duel" and t<180 do
     one:update(c.now);two:update(c.now);H.step(c,.01);t+=.01
     for _,x in {a,b} do
      local key=x.state..":"..tostring(x.attackSerial or 0)..":"..tostring(x.castId)
      if x.state=="Neutral" or x.state=="Guarding" or key~=(stuck[x] and stuck[x].key) then stuck[x]={key=key,t=0} else stuck[x].t+=.01 end
      assert(stuck[x].t<2.5,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
      assert(x.health==x.health and x.root.Position.Y==x.root.Position.Y,pair[1].." vs "..pair[2]..": non-finite state")
     end
     for _,p in c.projectiles do
      if not p.dead and not p.planted and (p.speed or 0)>0 then
       local ok,miss=onPath(c,p)
       assert(ok,string.format("%s vs %s: a %s left its announced path by %.2f studs",pair[1],pair[2],p.kind,miss))
      end
     end
     lanes=math.max(lanes,#zonesOf(c,"Wind"))
     if match.phase=="Duel" then
      totals.ticks+=1
      if gapOf(a,b)>=12 then totals.far+=1 end
      if gapOf(a,b)>=20 then totals.band=(totals.band or 0)+1 end
     end
    end
    assert(match.phase~="Duel",string.format("%s vs %s did not finish in 180 s (%.0f / %.0f health)",pair[1],pair[2],a.health,b.health))
    for _,x in {a,b} do
     if x.fighterId=="Gale" then
      totals.scythes+=ev(x,"Kamaitachi");totals.turned+=ev(x,"WindDeflect")+ev(x,"WindReturn")+ev(x,"GustReturn")
      totals.gusts+=ev(x,"Gust");totals.steps+=ev(x,"WindStep")
     end
    end
    -- The other side reached her (the AIs can approach a zoner).
    local temari=if a.fighterId=="Gale" then a else b
    local rival=if temari==a then b else a
    if rival.fighterId~="Gale" then
     local dealt=(match.winner==rival.id) or temari.health<temari.def.Health
     assert(dealt,pair[1].." vs "..pair[2]..": "..rival.fighterId.." never touched her")
    end
    totals.lanes+=lanes;totals.duels+=1
    print(string.format("   %s vs %s: %.1f s, winner %s",pair[1],pair[2],t,tostring(match.winner)))
   end
  end
  print(string.format("   her scythes %d, gusts %d, wind steps %d, blades turned/returned %d, %.0f%% of the time 12+ studs apart, %.0f%% 20+",
   totals.scythes,totals.gusts,totals.steps,totals.turned,100*totals.far/math.max(1,totals.ticks),100*(totals.band or 0)/math.max(1,totals.ticks)))
  assert(totals.scythes>=20,"her bot barely used the scythe ("..totals.scythes..")")
  assert(totals.gusts>=5 and totals.steps>=3,"her bot never pushed or stepped away")
  assert(totals.far/math.max(1,totals.ticks)>=.4,"she does not hold her range")
 end)
end)

-- Harness ----------------------------------------------------------------------------
test("headless walking moves at the fighter's own speed (the duels above measure range at true speed)",function()
 -- Movement asks the Humanoid twice a frame; the harness used to move the root
 -- for both requests, each by 1/60 s on 0.01 s steps: 3.3x too fast.
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,40)
 c:relocate(a,V.new(0,3,0));c:relocate(b,V.new(40,3,0))
 a.root.CFrame=H.C.lookAt(a.root.Position,a.root.Position-V.zAxis)
 a.move=-V.zAxis;H.step(c,.5)
 local from=a.root.Position
 a.move=-V.zAxis;H.step(c,1)
 local speed=flat(a.root.Position-from).Magnitude
 assert(math.abs(speed-a.def.Speed)<a.def.Speed*.12,string.format("she walked %.1f studs/s with a speed of %.1f",speed,a.def.Speed))
end)

-- Client -----------------------------------------------------------------------------
local Motion=H.load("Client/VelmoraMotionEngine")
local C=H.C
local function clientScene(fn)
 local instance,restore=H.stubScene()
 local saved=H.workspace.GetServerTimeNow
 local ok,err=pcall(fn,instance)
 H.workspace.GetServerTimeNow=saved
 restore()
 assert(ok,err)
end
local function rig(instance,folder,id,at)
 local m=instance("Model");m.Name=id;m.Parent=folder
 for _,n in {"HumanoidRootPart","Head","RightHand","LeftHand","UpperTorso"} do
  local p=instance("Part");p.Name=n;p.CFrame=C.lookAt(at,at-V.zAxis);p.Size=V.new(1,1,1);p.Transparency=0;p.Parent=m
 end
 return m
end
local function named(root,name)
 local count=0
 for _,d in root:GetDescendants() do if d.Name==name then count+=1 end end
 return count
end
test("client: a flight re-based in the air (turned by the wind) bends where it bent instead of vanishing and jumping ahead",function()
 clientScene(function(instance)
  local FX=H.load("Client/Effects")
  local fx=FX.new()
  local now=100.25
  H.workspace.GetServerTimeNow=function() return now end
  local leg1={id=1,kind="kunai",origin=V.new(0,4,0),direction=-V.zAxis,speed=80,born=100,range=60,owner="B",radius=0,growth=0}
  fx:sync({phase="Duel",epoch=1,projectiles={leg1}})
  fx:stepProjectiles(1/60)
  local before=fx.projectiles[1].root.CFrame.Position
  -- The server turned it at 100.25 where it was (z = -20); the packet lands a
  -- frame later, while the client still draws 0.06 s behind (before the turn).
  local leg2={id=1,kind="kunai",origin=V.new(0,4,-20),direction=V.xAxis,speed=60,born=100.25,range=12,owner="B",radius=0,growth=0}
  fx:sync({phase="Duel",epoch=1,projectiles={leg2}})
  now+=1/60
  fx:stepProjectiles(1/60)
  local entry=fx.projectiles[1]
  assert(not entry.hidden,"the turned blade vanished")
  local at=entry.root.CFrame.Position
  assert((at-before).Magnitude<=80/60*1.6,string.format("the blade jumped %.2f studs in a frame",(at-before).Magnitude))
  -- Past the turn it follows the new line.
  for _=1,6 do now+=1/60;fx:stepProjectiles(1/60) end
  local late=entry.root.CFrame.Position
  assert(late.X>.5 and math.abs(late.Z+20)<.3,string.format("after the turn the blade is at (%.1f, %.1f)",late.X,late.Z))
 end)
end)
test("client: the scythe and Kamatari fly as wind, as wide as the server's radius; zones are drawn as wind (lanes stream along their direction, columns rise), never as fire",function()
 clientScene(function(instance)
  local FX=H.load("Client/Effects")
  local fx=FX.new()
  H.workspace.GetServerTimeNow=function() return 100.36 end
  local folder=instance("Folder")
  rig(instance,folder,"A",V.new(0,3,0));rig(instance,folder,"B",V.new(0,3,-20))
  local data={phase="Duel",epoch=1,projectiles={
    {id=1,kind="gale",origin=V.new(0,4,-2),direction=-V.zAxis,speed=74,born=100,range=46,owner="A",radius=2.4,growth=3},
    {id=2,kind="kamatari",origin=V.new(0,4,-2),direction=-V.zAxis,speed=105,born=100,range=90,owner="A",radius=2.8,growth=0}},
   hazards={{position=V.new(10,0,10),radius=3,remaining=2,kind="Fire",owner="B"}},
   zones={{id=1,kind="Wind",owner="A",origin=V.new(0,0,-2),direction=-V.zAxis,length=12,width=3.2,radius=3,height=9,remaining=3,life=3.6,reflect=false},
    {id=2,kind="Updraft",owner="A",origin=V.new(6,0,-10),direction=V.zAxis,length=0,width=3,radius=3.4,height=18,remaining=2,life=2.2,reflect=false}},
   human={id="A",fighterId="Gale",seals={},state="Neutral",health=130,maxHealth=130},
   bot={id="B",fighterId="Mirage",seals={},state="Neutral",health=145,maxHealth=145}}
  fx:sync(data)
  assert(fx.projectiles[1].model.Name=="Kamaitachi","the scythe flies as "..fx.projectiles[1].model.Name)
  assert(fx.projectiles[2].model.Name=="Kamatari" and named(fx.projectiles[2].model,"KamatariBody")==1,"Kamatari flies as "..fx.projectiles[2].model.Name)
  fx:stepProjectiles(1/60)
  local entry=fx.projectiles[1]
  local age=100.36-FX.DELAY-100
  local reach=0
  for _,seg in entry.model:GetChildren() do if seg.Name=="ScytheArc" then reach=math.max(reach,(seg.CFrame.Position-entry.root.CFrame.Position).Magnitude) end end
  assert(math.abs(reach-(2.4+3*age)*.85)<.3,string.format("the crescent is %.2f wide for a radius of %.2f",reach,2.4+3*age))
  fx:update(data,1/60,folder)
  local lane,column=nil,nil
  for _,d in fx.folder:GetChildren() do if d.Name=="WindLane" then lane=d elseif d.Name=="Updraft" then column=d end end
  assert(lane and column,"the zones are not drawn")
  local streaks=0
  for _,s in lane:GetChildren() do
   if s.Name=="WindStreak" then
    streaks+=1
    assert(s.CFrame.LookVector:Dot(-V.zAxis)>.99,"a streak does not run along the wind")
   end
  end
  assert(streaks>=8 and named(column,"UpdraftRing")>=3,"the lane does not stream or the column does not rise")
  for _,holder in {lane,column} do
   -- Wind may drag dust along a lane (seen in Studio: the bare floor band read
   -- as a slab), never flames.
   for _,d in holder:GetDescendants() do assert(not (d.ClassName=="ParticleEmitter" and tostring(d.Texture):find("fire")),"a zone is drawn with flames") end
  end
  -- The fire hazard is still drawn as fire.
  local fire=false
  for _,d in fx.folder:GetDescendants() do if d.ClassName=="ParticleEmitter" and tostring(d.Texture):find("fire") then fire=true end end
  assert(fire,"the fire hazard lost its flames")
  -- The lane grows with its scythe: the band follows the reported length.
  local band=lane:FindFirstChild("WindBand")
  local short=band.Size.Z
  data.zones[1].length=30
  for _=1,30 do fx:update(data,1/60,folder) end
  assert(band.Size.Z>short+12,"the lane did not grow with the scythe")
  -- Gone from the snapshot: gone from the screen.
  data.zones={}
  fx:update(data,1/60,folder)
  assert(fx.galeZones and next(fx.galeZones.list)==nil,"a zone outlived the snapshot")
 end)
end)
test("client: her contacts are drawn as wind (scythe hits, gusts, Great Gust, whirlwind, fire fed, blades turned, her awakening, wind step and casts)",function()
 clientScene(function(instance)
  local FX=H.load("Client/Effects")
  local fx=FX.new()
  local folder=instance("Folder")
  rig(instance,folder,"A",V.new(0,3,0));rig(instance,folder,"B",V.new(0,3,-10))
  local serial=0
  local function drew(impact)
   serial+=1;impact.serial=serial;impact.position=impact.position or V.new(0,3,-5)
   local before=#fx.folder:GetDescendants()
   fx:impact(impact,folder)
   return #fx.folder:GetDescendants()>before
  end
  for _,style in {"jutsu","stick","fade","spent"} do
   assert(drew({style=style,kind="gale",owner="A",direction=-V.zAxis}),"a scythe ending as "..style.." drew nothing")
  end
  assert(drew({style="jutsu",kind="kamatari",owner="A",direction=-V.zAxis}),"Kamatari's hit drew nothing")
  assert(drew({style="gust",owner="A",fighter="Gale",direction=-V.zAxis,range=18}) and named(fx.folder,"FanGust")==1,"the gust is not drawn")
  assert(drew({style="greatgust",owner="A",fighter="Gale",direction=-V.zAxis,range=30}) and named(fx.folder,"GreatGust")==1,"the Great Gust is not drawn")
  for _,phase in {"mark","rise","updraft"} do
   assert(drew({style="cyclone",owner="A",fighter="Gale",phase=phase,radius=3.4,delay=.45}),"the whirlwind "..phase.." drew nothing")
  end
  assert(named(fx.folder,"CycloneMark")==1,"the whirlwind's spot is not marked")
  assert(drew({style="windfeed",owner="A",fighter="Gale",direction=V.xAxis}),"fire fed by the wind drew nothing")
  assert(drew({style="winddeflect",owner="A",fighter="Gale",kind="kunai",direction=V.xAxis}),"a blade turned by a lane drew nothing")
  for _,style in {"awaken","chase","cast"} do
   assert(drew({style=style,owner="A",fighter="Gale",to=V.new(10,3,0),technique="Kamaitachi",direction=-V.zAxis}),"her "..style.." drew nothing")
  end
  -- Another fighter's dash is not drawn as her wind step.
  local before=named(fx.folder,"WindStreak")
  fx:impact({style="chase",owner="B",fighter="Mirage",variant="mirage",position=V.new(0,3,-10),to=V.new(0,3,-4),serial=99},folder)
  assert(named(fx.folder,"WindStreak")==before,"Itachi's dash was drawn as her wind")
 end)
end)
test("client: the iron fan, on her back at rest, a closed club in the hand for a strike, opened moon by moon for the wind, planted at the intro",function()
 clientScene(function(instance)
  local FX=H.load("Client/Effects")
  local GaleFX=H.load("Client/GaleFX")
  local fx=FX.new()
  local folder=instance("Folder")
  local temari=rig(instance,folder,"A",V.new(0,3,0));rig(instance,folder,"B",V.new(0,3,-10))
  local data={phase="Duel",epoch=1,projectiles={},hazards={},zones={},
   human={id="A",fighterId="Gale",seals={},state="Neutral",health=130,maxHealth=130},
   bot={id="B",fighterId="Mirage",seals={},state="Neutral",health=145,maxHealth=145}}
  local function fan()
   fx:update(data,1/60,folder)
   local model=temari:FindFirstChild("TemariFan")
   assert(model,"no fan on her")
   local carry=model:FindFirstChild("Grip"):FindFirstChild("FanCarry")
   local shown=0
   for _,m in model:GetChildren() do if m.Name=="FanMoon" and m.Transparency<.5 then shown+=1 end end
   local bar=model:FindFirstChild("FanBar")
   return carry.Part0 and carry.Part0.Name,bar.Transparency<.5,shown
  end
  local where,closed,moons=fan()
  assert(where=="UpperTorso" and closed and moons==0,"at rest the fan is "..tostring(where))
  assert(named(folder:FindFirstChild("B"),"TemariFan")==0,"Itachi carries her fan")
  data.human.attackName="Light1";data.human.state="Active";data.human.attackSerial=1
  where,closed=fan()
  assert(where=="RightHand" and closed,"a fan strike holds the fan as "..tostring(where).."/"..tostring(closed))
  data.human.attackName="Light3"
  where,closed,moons=fan()
  assert(where=="RightHand" and not closed and moons==1,"the third strike does not open the fan")
  data.human.attackName=nil;data.human.state="TechniqueChannel";data.human.castId="GreatGust";data.human.castElapsed=.2
  where,closed,moons=fan()
  assert(not closed and moons==1,"the fan does not start opening ("..moons.." moons)")
  data.human.castElapsed=.5
  where,closed,moons=fan()
  assert(moons==3,"three moons for the Great Gust ("..moons..")")
  data.human.castId=nil;data.human.state="Neutral";data.intro=1.5
  where=fan()
  assert(where=="HumanoidRootPart","at the intro the fan is not planted beside her")
  data.intro=0
  -- Kirikiri Mai: her mantle takes the wind's colour; at rest the fan is back on her back.
  data.human.awaken=6
  where,closed,moons=fan()
  assert(where=="UpperTorso" and moons==0,"awakened at rest the fan left her back")
  local aura=fx.auras[temari]
  assert(aura and aura.mantle and aura.galeMantle==aura.mantle,"her mantle is not the wind's")
  assert(GaleFX.fanPose({fighterId="Gale",state="Neutral",health=1,throwKind="Gust",throwElapsed=.1})=="open","the gust does not open the fan")
 end)
end)
local function snapshotJoints(model)
 local out={}
 for key,joint in model.joints do out[key]=joint.Transform end
 return out
end
local function differ(x,y,eps)
 local n=0
 for key,tr in x do if not tr:FuzzyEq(y[key],eps or .03) then n+=1 end end
 return n
end
local function body(actor,overrides)
 local out={fighterId=actor.fighterId,state="Neutral",health=actor.health,attackElapsed=0,reactionElapsed=0,airborne=false,
  velocity=V.zero,speed=0,hitAngle=0,hitStrength=.5,landing=false}
 for k,v in overrides or {} do out[k]=v end
 return out
end
local function present(model,actor,frames)
 Motion.reset(model)
 local clock={attackElapsed=actor.attackElapsed or 0,reactionElapsed=0}
 for _=1,frames or 45 do Motion.tick(1/60);Motion.present(model,actor,clock,1/60) end
 return snapshotJoints(model)
end
test("motion family: her own stance and walk (the hand on the hip), her own clips for the string, routes and air, casts that are not hand seals, her intro, no hand weapon",function()
 local family=Motion.familyOf("Gale")
 assert(family.body=="Gale" and family.weapons=="none" and family.intro=="Gale" and family.springy==false,"her motion family is "..tostring(family.body))
 local c,a=H.duel("Gale","Mirage")
 local mine=present(a.model,body(a))
 for _,id in {"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf"} do
  local c2,x=H.duel(id,"Gale")
  local theirs=present(x.model,body(x))
  assert(differ(mine,theirs)>=4,"she stands like "..id.." ("..differ(mine,theirs).." joints differ)")
 end
 -- Walking, the right hand stays where it rests (her stance), not a generic swing.
 local still=present(a.model,body(a))
 local walking=present(a.model,body(a,{velocity=V.new(0,0,-10),speed=10}))
 assert(walking.RightShoulder:FuzzyEq(still.RightShoulder,.08),"walking swings the hand off her hip")
 -- Her strikes are her own clips (a fan, not a fist or a kick).
 local function key(x,fighter,name,at)
  Motion.reset(x.model)
  for _=1,40 do Motion.pose(x.model,name,at or .05,fighter,1/60) end
  return snapshotJoints(x.model)
 end
 local c3,itachi=H.duel("Mirage","Gale")
 local c4,sasuke=H.duel("Lion","Gale")
 for _,name in {"Light1","Light2","Light3","Heavy","DashAttack","Air1","Air2","AirDrive","Slam"} do
  assert(differ(key(a,"Gale",name),key(itachi,"Mirage",name))>=3,name.." is Itachi's")
  assert(differ(key(a,"Gale",name),key(sasuke,"Lion",name))>=3,name.." is Sasuke's")
 end
 for _,name in {"Updraft","FanSlam","FanPirouette","FanBackhand","FanDive"} do
  assert(differ(key(a,"Gale",name),key(a,"Gale","Light1"))>=3,name.." falls back to her first strike")
 end
 -- Casts: the fan drawn and opened, never the generic hand seals.
 for _,id in {"Kamaitachi","GreatGust","Cyclone"} do
  local cast=present(a.model,body(a,{state="TechniqueChannel",castId=id,castElapsed=.1}))
  local seals=present(a.model,body(a,{state="TechniqueChannel",castId="SomeUnknownJutsu",castElapsed=.1}))
  assert(differ(cast,seals)>=4,id.." is cast with hand seals")
 end
 -- The fan gust (her tool) has its own arm.
 local gust=present(a.model,body(a,{throwKind="Gust",throwElapsed=.12,throwRelease=.1}))
 assert(differ(gust,still)>=3,"the gust does not move her arm")
 -- Her intro is her own.
 local intro=present(a.model,body(a,{intro=1}))
 local c5,lee=H.duel("Leaf","Gale")
 assert(differ(intro,present(lee.model,body(lee,{intro=1})))>=4 and differ(intro,still)>=3,"her intro is not hers")
 for _,name in {"Light1","Light3","Updraft","Kamaitachi"} do
  Motion.weapon(a.model,body(a,{attackName=name,state="Active",attackElapsed=.1}))
  local w=Motion.weaponState(a.model)
  assert(not w.visible and w.count==0,"the engine gave her a hand weapon for "..name)
 end
end)
local AXIS_X=H.roblox.CFrame.identity.RightVector
local AXIS_Y=H.roblox.CFrame.identity.UpVector
local function axisAngles(cf)
 local x=cf:VectorToObjectSpace(AXIS_X)
 local y=cf:VectorToObjectSpace(AXIS_Y)
 return math.acos(math.clamp(x.X,-1,1)),math.acos(math.clamp(y.Y,-1,1))
end
local function maxDelta(p,q)
 local worst,where=0,""
 for key,tr in p do
  local x1,y1=axisAngles(tr)
  local x2,y2=axisAngles(q[key])
  local d=math.deg(math.max(math.abs(x1-x2),math.abs(y1-y2)))
  if d>worst then worst,where=d,key end
 end
 return worst,where
end
test("her whole kit presents without a snap: string, routes, air, the gust, the three techniques, the wind step, the glide, Kirikiri Mai",function()
 local c,a,b=H.duel("Gale","Mirage")
 local clock={attackAt=0,reactionAt=0,attackElapsed=0,reactionElapsed=0}
 local previous,worst,worstAt=nil,0,""
 local seen={}
 local function frame()
  local velocity=a.root.AssemblyLinearVelocity
  local visual=body(a,{velocity=velocity,speed=velocity.Magnitude,attackName=a.attackName,attackVariant=a.attackVariant,attackSerial=a.attackSerial,
   state=a.state,reaction=a.reaction,airborne=a.airborne,groundPose=a.groundPose,castId=a.castId,castElapsed=c.now-(a.castStarted or c.now),
   throwKind=a.throwKind,throwElapsed=c.now-(a.throwStarted or -10),throwRelease=a.throwRelease,
   awaken=math.max(0,(a.awakenUntil or 0)-c.now),hitAngle=a.hitAngle or 0,hitStrength=a.hitStrength or .4})
  Motion.tick(1/60)
  local phase=Motion.present(a.model,visual,clock,1/60)
  seen[phase]=(seen[phase] or 0)+1
  local current=snapshotJoints(a.model)
  if previous then
   local d,joint=maxDelta(previous,current)
   if d>worst then worst=d;worstAt=string.format("%s %s @%s/%s/%s",phase,joint,a.state,tostring(a.attackName),tostring(a.castId)) end
  end
  previous=current
 end
 local function advance(seconds,hold)
  for _=1,math.ceil(seconds/.01) do
   c:update(.01,c.now+.01)
   if hold then b.reactionVelocity=V.zero end
   local name=a.attackName and (a.attackName..":"..tostring(a.attackSerial or 0))
   if clock.attackName~=name then clock.attackName=name;clock.attackAt=c.now end
   clock.attackElapsed=if a.attackName then c.now-clock.attackAt else 0
   if clock.reaction~=a.reaction then clock.reaction=a.reaction;clock.reactionAt=c.now end
   clock.reactionElapsed=if a.reaction then c.now-clock.reactionAt else 0
   frame()
  end
 end
 local function reset(gap)
  place(c,a,b,gap or 5.5)
  for _,x in {a,b} do x.health=x.def.Health;x.hum.Health=x.health;x.reaction=nil;x.state="Neutral";x.untilTime=c.now;x.pending=nil;x.attackName=nil;x.airborne=false end
  b.cooldowns={};a.cooldowns={};a.chakra=a.def.Chakra;a.neutralToolAt=0;a.rushReadyAt=0
 end
 a.move=V.new(1,0,0);advance(.4);a.move=V.zero;advance(.3)
 reset()
 press(c,a,"Attack");advance(.36);press(c,a,"Attack");advance(.36);press(c,a,"Attack");advance(.7)
 reset()
 press(c,a,"Attack");advance(.36);press(c,a,"Attack");advance(.36);press(c,a,"Attack",toward(a));advance(.9)
 reset()
 press(c,a,"Attack");advance(.36);press(c,a,"Attack",side(a,1));advance(.7)
 reset()
 press(c,a,"Attack");advance(.36);press(c,a,"Attack");advance(.36);press(c,a,"Attack",-toward(a));advance(.7)
 reset(12)
 press(c,a,"Tool",nil,b.root.Position);advance(.6)
 for _,id in {"Kamaitachi","GreatGust","Cyclone"} do reset(16);press(c,a,slot(a,id),nil,b.root.Position);advance(1.1) end
 reset(6);a.locked=true;press(c,a,"Pursuit");advance(.7)
 reset(10)
 c:relocate(a,a.root.Position+V.new(0,8,0));a.airborne=true;c:request(a,"Jump");advance(.8)
 reset(14)
 a.health=a.def.Health*.3;c:request(a,"Awaken");advance(.8)
 for _,name in {"Light3","Updraft","FanPirouette","FanSlam","Gust","Kamaitachi","GreatGust","Cyclone","WindStep","Glide","Kamatari"} do
  assert(ev(a,name)>=1,"the sequence never played "..name)
 end
 assert(seen.attack and seen.technique and seen.chase,"the kit never presented an attack, a cast or a dash")
 print(string.format("   worst %.1f deg/frame (%s)",worst,worstAt))
 assert(worst<39,"a snap of "..string.format("%.1f",worst).." deg/frame at "..worstAt)
end)
test("her costume builds: four sandy tufts, the Sand headband, the lilac kimono with its crimson obi, fishnet at elbows and knees; no fan in the costume",function()
 local made={}
 local base=H.envBase.Instance
 H.envBase.Instance={new=function(class) local x=base.new(class);table.insert(made,x);return x end}
 local World=H.load("Server/World")
 local c,a=H.duel("Gale","Mirage")
 local ok,err=pcall(World.dress,a.model,H.fighters.Gale)
 H.envBase.Instance=base
 assert(ok,err)
 local names={}
 for _,x in made do local n=rawget(x,"Name") or x.Name;if n then names[n]=(names[n] or 0)+1 end end
 assert(names.TemariPonytail==4,"no four tufts ("..tostring(names.TemariPonytail)..")")
 assert(names.Headband==1 and names.SandMark==1,"no Sand headband")
 assert(names.KimonoSkirt==1 and names.Obi==1 and names.ObiKnot==1,"no kimono and obi")
 assert(names.Fishnet==4,"no fishnet at elbows and knees")
 assert(names.TemariFan==nil,"the fan is part of the costume (it must move: GaleFX)")
 for _,x in made do
  local material=rawget(x,"Material") or x.Material
  assert(material~=H.roblox.Enum.Material.Fabric,"a Fabric part (renders as wicker in Studio)")
 end
 assert(a.model.bones.UpperTorso.Color==H.roblox.Color3.fromRGB(186,170,204),"the kimono is not lilac")
end)
test("she is selectable: her roster slot and both buttons, and the duel starts with her",function()
 H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim
 H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
 H.workspace.GetAttribute=function() return nil end
 local baseNew=H.envBase.Instance.new
 local saved=H.envBase.Instance
 H.envBase.Instance={new=function(class)
  local x=baseNew(class)
  x.Activated={Connect=function(_,fn) x.click=fn end}
  return x
 end}
 local ok,err=pcall(function()
  local UI=H.load("Client/UI")
  local sent={}
  local ui=UI.new(baseNew("PlayerGui"),function(action,extra) table.insert(sent,{action=action,extra=extra}) end)
  assert(ui.selectionButtons.slotGale and ui.selectionButtons.playerGale and ui.selectionButtons.botGale,"Temari is not in the roster")
  ui.selectionButtons.playerGale.click()
  assert(ui.player=="Gale","picking Temari did not select her")
  assert(ui.routeNote.Text:find("TEMARI",1,true),"her strings are not shown")
  ui.selectionButtons.botGale.click()
  assert(ui.bot=="Gale","Temari cannot be the opponent")
  ui.startButton.click()
  local last=sent[#sent]
  assert(last.action=="Start" and last.extra.player=="Gale","the start request does not carry Temari")
 end)
 H.envBase.Instance=saved
 assert(ok,err)
end)
test("camera at her range: two bodies 20 to 90 studs apart (one of them up in the air) both stay in frame",function()
 -- Measured on the real rig (Client/Camera): the focus, the boom and the lens
 -- at a zoner's distances. Headless geometry only.
 local saved=H.workspace.CurrentCamera
 local Camera=H.load("Client/Camera")
 local lens={CFrame=C.new(),FieldOfView=70,CameraType=nil}
 H.workspace.CurrentCamera=lens
 local players=H.envBase.game:GetService("Players")
 local ok,err=pcall(function()
  for _,setup in {{20,0},{40,0},{60,0},{90,0},{30,12}} do
   local gap,up=setup[1],setup[2]
   local me=V.new(0,3,gap/2)
   local them=V.new(0,3+up,-gap/2)
   local character={}
   local root={Position=me,Parent=character}
   function character:FindFirstChild(n) if n=="HumanoidRootPart" then return root end return nil end
   character.Parent={FindFirstChild=function() return nil end}
   players.LocalPlayer.Character=character
   local cam=Camera.new()
   cam.presentation={visualRoot=function(_,key) return if key=="human" then me else them end,visualVelocity=function() return V.zero end}
   local data={phase="Duel",epoch=1,human={health=100,impactSerial=0,state="Neutral",airborne=false,speed=0},
    bot={health=100,state="Neutral",airborne=up>0,position=them,id="AIFighter"}}
   for _=1,180 do cam:update(data,1/60) end
   local cf=lens.CFrame
   local tanV=math.tan(math.rad(lens.FieldOfView/2))
   local tanH=tanV*16/9
   for label,point in {me=me,them=them} do
    local p=cf:PointToObjectSpace(point)
    assert(p.Z<0,string.format("%d studs: %s is behind the lens",gap,label))
    local x,y=math.abs(p.X/-p.Z),math.abs(p.Y/-p.Z)
    assert(x<tanH*.9 and y<tanV*.9,string.format("%d studs (%d up): %s leaves the frame (%.2f, %.2f of %.2f, %.2f)",gap,up,label,x,y,tanH,tanV))
   end
  end
 end)
 players.LocalPlayer.Character=nil
 H.workspace.CurrentCamera=saved
 assert(ok,err)
end)

print("NinjaDuel Temari: "..passed.." PASS")
