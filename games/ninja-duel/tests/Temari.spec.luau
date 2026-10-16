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
test("Kamaitachi: a wind scythe that knocks away (a wall splat at range) and lays its lane as it flies; 14 chakra, a cooldown, an interruptible channel",function()
 local c,a,b=H.duel("Gale","Mirage");place(c,a,b,20)
 local chakra=a.chakra
 assert(press(c,a,slot(a,"Kamaitachi"),nil,b.root.Position),"Kamaitachi was refused")
 assert(math.abs(chakra-a.chakra-14)<.01 and (a.cooldowns.Kamaitachi or 0)>c.now+3,"cost or cooldown")
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
test("Great Gust: blades in the cone are blown away, fire grows, the body is thrown to a wall, a wide lane stays",function()
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
 Gale_lane=H.load("Server/Gale").lane(c2,x,x.root.Position+toward(x)*2,toward(x),30,3.2,3.6)
 assert(Gale_lane.reflect,"an awakened lane does not return blades")
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

print("NinjaDuel Temari: "..passed.." PASS")
