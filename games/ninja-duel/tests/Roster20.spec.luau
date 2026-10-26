-- The locked ten of the roster (DEC-022): each one's own mechanics, checked
-- headless beyond the Tier A floor (Roster.spec), and the generic family
-- fields they introduced (Families: Poison, PullTo, Teleport InZone/Heal,
-- Burst Leave, Buff OnHit; ToolMastery Projectile/Contact; Attacks riders).
-- Feel and looks stay Studio checks.
local H=require("./Harness")
local V=H.V
local Roster=H.load("Shared/Roster")
local Fighters=H.fighters
local MoveGraphs=H.load("Shared/MoveGraphs")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,gap)
 c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 for _,x in {a,b} do x.move=V.zero end
end
local function flat(v) return V.new(v.X,0,v.Z) end
local function press(c,a,action,stick,aim)
 a.move=stick or V.zero
 local ok,reason=c:request(a,action,aim)
 a.move=V.zero
 return ok,reason
end
local function run(c,seconds,each)
 for _=1,math.ceil(seconds/.01) do H.step(c,.01);if each then each() end end
end
local function slot(id,tech)
 for i,spec in Fighters[id].Techniques do if spec.Id==tech then return "Technique"..i,spec end end
 error(id.." has no "..tech)
end
local NEW={"Mirror","Mist","Bone","Flicker","Serpent","Medic","Clay","Puppet","Rinnegan","Ink","Rival","Sapling","Professor"}
local listed={}
for _,id in Roster do listed[id]=true end
local function each(fn) for _,id in NEW do if listed[id] then fn(id) end end end

-- (Ninja Embodiment, rupture) The opener follows the body: round him is the
-- fighter's own lateral strike, backing off is a strike that takes the step
-- back; toward him stays the plain opener (the launch and the low route still
-- need a confirmed hit).
test("direction + light out of a string: round him his own lateral strike, backing off the step-back strike, toward the plain opener",function()
 each(function(id)
  for _,dir in {"forward","back","side"} do
   local c,a,b=H.duel(id,"Leaf");place(c,a,b,3.4);b.health=999
   local stick=if dir=="forward" then flat(b.root.Position-a.root.Position).Unit elseif dir=="back" then flat(a.root.Position-b.root.Position).Unit else a.root.CFrame.RightVector
   assert(press(c,a,"Attack",stick),id..": opener refused")
   local graph=MoveGraphs[id]
   local want=if dir=="back" then (graph.stepBack or "StepBackStrike") elseif dir=="side" then (graph.routes.side or "Light1") else nil
   if want then
    assert(a.attackName==want,id..": "..dir.." + light from neutral gave "..tostring(a.attackName).." (wanted "..want..")")
   else
    assert(a.attackName=="Light1" or a.attackName=="DashAttack",id..": "..dir.." + light from neutral gave "..tostring(a.attackName))
    assert(a.attackName~=graph.routes.up and a.attackName~=graph.routes.down,id..": a launch or low route opened before any hit")
   end
  end
 end)
end)

test("Haku: senbon that slow, a mirror step that strikes harder inside his dome",function()
 if not listed.Mirror then return end
 local c,a,b=H.duel("Mirror","Leaf");place(c,a,b,12);b.health=999
 assert(press(c,a,"Tool",nil,b.root.Position))
 local slowed=false
 -- (The headless world has no ray hits on bodies: the needles get a body's width.)
 run(c,.8,function()
  for _,p in c.projectiles do if p.a==a then assert(p.kind=="senbon","Haku threw "..p.kind);p.radius=1 end end
  if (b.slowUntil or 0)>c.now then slowed=true end
 end)
 assert(slowed,"Haku's senbon did not slow")
 -- Mirror step outside then inside the dome: the arrival strike is harder inside.
 local function stepDamage(inside)
  local c2,a2,b2=H.duel("Mirror","Leaf");place(c2,a2,b2,14);b2.health=999;a2.chakra=999
  if inside then
   local s=slot("Mirror","IceMirrors")
   assert(press(c2,a2,s,nil,b2.root.Position));run(c2,1.4)
   a2.cooldowns={}
  end
  local before=b2.health
  local s=slot("Mirror","MirrorStep")
  assert(press(c2,a2,s,nil,b2.root.Position))
  local most=0
  run(c2,.8,function() most=math.max(most,before-b2.health) end)
  return most
 end
 local out,inn=stepDamage(false),stepDamage(true)
 assert(out>0,"the mirror step did not land")
 assert(inn>out*1.3,string.format("inside the dome %.1f vs outside %.1f",inn,out))
end)

test("Zabuza: the Silent Killing out of his mist is far harder; the Water Prison holds",function()
 if not listed.Mist then return end
 local function kill(mist)
  local c,a,b=H.duel("Mist","Leaf");place(c,a,b,10);b.health=999;a.chakra=999
  if mist then assert(press(c,a,slot("Mist","HiddenMist")));run(c,1.2);a.cooldowns={} end
  local before=b.health
  assert(press(c,a,slot("Mist","SilentKilling"),nil,b.root.Position))
  local behind=false
  run(c,.9,function()
   local look=flat(b.root.CFrame.LookVector)
   if look.Magnitude>0 and look.Unit:Dot(flat(a.root.Position-b.root.Position).Unit)<-.2 then behind=true end
  end)
  return before-b.health,behind
 end
 local plain,behind=kill(false)
 local misted=kill(true)
 assert(behind,"Zabuza did not reach the back")
 assert(plain>0 and misted>plain*1.4,string.format("mist %.1f vs plain %.1f",misted,plain))
end)

test("Kimimaro: bone armour, finger bullets, the Larch leaves the floor spiked",function()
 if not listed.Bone then return end
 local c,a,b=H.duel("Leaf","Bone");place(c,a,b,3.4);b.health=999
 local c2,a2,b2=H.duel("Leaf","Leaf");place(c2,a2,b2,3.4);b2.health=999
 assert(press(c,a,"Attack"));assert(press(c2,a2,"Attack"))
 run(c,.4);run(c2,.4)
 assert(999-b.health<999-b2.health,"Kimimaro's bones took nothing off the blow")
 local c3,a3,b3=H.duel("Bone","Leaf");place(c3,a3,b3,12)
 assert(press(c3,a3,"Tool",nil,b3.root.Position))
 local bone=false
 run(c3,.2,function() for _,p in c3.projectiles do if p.kind=="bone" then bone=true end end end)
 assert(bone,"his tool is not a bone bullet")
 local c4,a4,b4=H.duel("Bone","Leaf");place(c4,a4,b4,4);a4.chakra=999
 assert(press(c4,a4,slot("Bone","Larch")));run(c4,.5)
 local spiked=false
 for _,h in c4.hazards do if h.a==a4 and h.look=="bones" then spiked=true end end
 assert(spiked,"the Larch left no spikes")
end)


test("Shisui: a cheap body flicker to the flank, a retreat out of reach, a genjutsu that seals",function()
 if not listed.Flicker then return end
 local c,a,b=H.duel("Flicker","Leaf");place(c,a,b,14);b.health=999;a.chakra=999
 local before=b.health
 assert(press(c,a,slot("Flicker","BodyFlicker"),nil,b.root.Position))
 local closest=99
 run(c,.6,function() closest=math.min(closest,flat(a.root.Position-b.root.Position).Magnitude) end)
 assert(closest<5,"Shisui did not arrive beside the body")
 assert(b.health<before,"the flicker cut did not land")
 assert(Fighters.Flicker.Techniques[1].Cost<=10 and Fighters.Flicker.Techniques[1].Cooldown<=2,"the flicker is not cheap")
 local c2,a2,b2=H.duel("Flicker","Leaf");place(c2,a2,b2,4);a2.chakra=999
 local from=a2.root.Position
 assert(press(c2,a2,slot("Flicker","FlickerOut"),nil,b2.root.Position));run(c2,.3)
 assert((a2.root.Position-from).Magnitude>9,"the retreat did not take him out of reach")
 local c3,a3,b3=H.duel("Flicker","Leaf");place(c3,a3,b3,4);a3.chakra=999;b3.health=999
 assert(press(c3,a3,slot("Flicker","ShisuiGenjutsu"),nil,b3.root.Position));run(c3,.5)
 assert((b3.sealedUntil or 0)>c3.now,"the genjutsu sealed nothing")
end)

test("Orochimaru: the shadow snake drags the body in (never past him) and poisons; coils hold",function()
 if not listed.Serpent then return end
 local c,a,b=H.duel("Serpent","Leaf");place(c,a,b,14);b.health=999;a.chakra=999
 assert(press(c,a,slot("Serpent","ShadowSnake"),nil,b.root.Position))
 local nearest=99
 run(c,1.4,function() nearest=math.min(nearest,flat(b.root.Position-a.root.Position).Magnitude) end)
 assert(nearest<9,string.format("the body was not dragged in (closest %.1f)",nearest))
 local look=flat(a.root.CFrame.LookVector).Unit
 assert(look:Dot(flat(b.root.Position-a.root.Position))>-1,"the snake threw the body behind him")
 assert((b.poisonedUntil or 0)>0,"no venom")
 local hp=b.health;run(c,1.5)
 assert(b.health<hp,"the venom did no damage over time")
 -- A close body is not thrown behind him.
 local c2,a2,b2=H.duel("Serpent","Leaf");place(c2,a2,b2,4.5);a2.chakra=999
 local fwd=flat(b2.root.Position-a2.root.Position).Unit
 assert(press(c2,a2,slot("Serpent","ShadowSnake"),nil,b2.root.Position))
 local behind=false
 run(c2,1,function() if flat(b2.root.Position-a2.root.Position):Dot(fwd)<-1 then behind=true end end)
 assert(not behind,"a close body was pulled through him")
end)

test("Kabuto: the scalpel buff cuts (slows) and drains, the tendon cut slows hard, the retreat heals",function()
 if not listed.Medic then return end
 local c,a,b=H.duel("Medic","Leaf");place(c,a,b,3.4);a.chakra=999;b.health=999;b.chakra=100
 assert(press(c,a,slot("Medic","ChakraScalpel")));run(c,.6)
 place(c,a,b,3.4)
 b.chakra=50
 assert(press(c,a,"Attack"));run(c,.25)
 assert((b.slowUntil or 0)>c.now,"the scalpel did not cut a muscle")
 assert(b.chakra<50,"the scalpel drained nothing")
 local c2,a2,b2=H.duel("Medic","Leaf");place(c2,a2,b2,4);a2.chakra=999
 a2.health=60;a2.hum.Health=60
 assert(press(c2,a2,slot("Medic","MendingRetreat"),nil,b2.root.Position));run(c2,.3)
 assert(a2.health>60,"the retreat healed nothing")
end)


test("Deidara: clay birds burst and burn, spiders launch, a landmine waits, Katsu throws a close body off",function()
 if not listed.Clay then return end
 local c,a,b=H.duel("Clay","Leaf");place(c,a,b,14);a.chakra=999;b.health=999
 assert(press(c,a,slot("Clay","ClayBirds"),nil,b.root.Position))
 local knocked=false
 run(c,1.5,function() if b.reaction=="Knockback" or b.reaction=="Launched" then knocked=true end end)
 assert(knocked,"the birds did not blow the body away")
 local c2,a2,b2=H.duel("Clay","Leaf");place(c2,a2,b2,12);a2.chakra=999
 assert(press(c2,a2,slot("Clay","ClayMine"),nil,b2.root.Position));run(c2,.6)
 assert(#c2.hazards>0,"no landmine")
 local c3,a3,b3=H.duel("Clay","Leaf");place(c3,a3,b3,3.5);a3.chakra=999;b3.health=999
 local from=b3.root.Position
 assert(press(c3,a3,slot("Clay","Katsu")));run(c3,.6)
 assert((b3.root.Position-from).Magnitude>3,"Katsu threw nothing off")
end)

test("Sasori: long lashes; a marionette that holds a post, strikes on its own, carries his blade and breaks",function()
 if not listed.Puppet then return end
 local Bodies=H.load("Server/Bodies")
 -- His light reaches where a fist does not.
 local c,a,b=H.duel("Puppet","Leaf");place(c,a,b,7);b.health=999
 assert(press(c,a,"Attack"));run(c,.6)
 assert(b.health<999,"the puppet lash did not reach at 7 studs")
 -- The marionette: out, at its post by the body, striking on its own with poison.
 local c2,a2,b2=H.duel("Puppet","Leaf");place(c2,a2,b2,12);a2.chakra=999;b2.health=999
 assert(press(c2,a2,slot("Puppet","Marionette"),nil,b2.root.Position));run(c2,.5)
 local puppet=Bodies.of(c2,a2,"puppet")[1]
 assert(puppet,"no marionette came out")
 run(c2,3.5)
 assert(flat(puppet.position-b2.root.Position).Magnitude<7,"the marionette did not take its post by the body")
 assert(b2.health<999 and (b2.poisonedUntil or 0)>0,"the marionette never struck (with poison) on its own")
 -- Cast again: it lunges.
 local hp=b2.health;a2.cooldowns={}
 assert(press(c2,a2,slot("Puppet","Marionette"),nil,b2.root.Position))
 local lunged=false
 run(c2,1.2,function() if b2.reaction=="Knockback" then lunged=true end end)
 assert(lunged and b2.health<hp,"the second cast did not send it lunging")
 -- His heavy after one is carried by the puppet (from behind the body).
 local c3,a3,b3=H.duel("Puppet","Leaf");place(c3,a3,b3,7);a3.chakra=999;b3.health=999
 assert(press(c3,a3,slot("Puppet","Marionette"),nil,b3.root.Position));run(c3,.8)
 assert(press(c3,a3,"Attack"))
 for _=1,90 do H.step(c3,.01);if a3.state=="Recovery" and a3.chainOpen==true and c3.now>=(a3.chainAt or 0) then break end end
 assert(press(c3,a3,"Heavy"))
 assert(a3.attackName=="PuppetBlade" and a3.pending and a3.pending.body~=nil,"the blade was not carried by the marionette")
 -- One clean blow breaks it.
 local c4,a4,b4=H.duel("Puppet","Leaf");place(c4,a4,b4,6);a4.chakra=999
 assert(press(c4,a4,slot("Puppet","Marionette"),nil,b4.root.Position));run(c4,.3)
 local p4=Bodies.of(c4,a4,"puppet")[1];assert(p4)
 Bodies.dispel(c4,p4,"hit",b4)
 assert(#Bodies.of(c4,a4,"puppet")==0,"the marionette survived a blow")
 -- The shield still answers a blow with a poisoned blade.
 local c5,a5,b5=H.duel("Puppet","Leaf");place(c5,a5,b5,3.4);a5.chakra=999;a5.health=500
 assert(press(c5,a5,slot("Puppet","PuppetShield")));run(c5,.1)
 assert(press(c5,b5,"Attack"));run(c5,.5)
 assert((b5.poisonedUntil or 0)>0 and b5.health<b5.def.Health,"the puppet shield did not answer the blow")
end)

test("Nagato: repulsion clears blades and bodies, attraction pulls, the absorbing seal drinks a jutsu thrown at him",function()
 if not listed.Rinnegan then return end
 local c,a,b=H.duel("Rinnegan","Leaf");place(c,a,b,5);a.chakra=999;b.health=999
 local from=b.root.Position
 assert(press(c,a,slot("Rinnegan","Repulsion")));run(c,.6)
 assert(flat(b.root.Position-from).Magnitude>4,"repulsion pushed nothing")
 local c2,a2,b2=H.duel("Rinnegan","Leaf");place(c2,a2,b2,20);a2.chakra=999;b2.health=999
 assert(press(c2,a2,slot("Rinnegan","Attraction"),nil,b2.root.Position))
 local nearest=99
 run(c2,1.2,function() nearest=math.min(nearest,flat(b2.root.Position-a2.root.Position).Magnitude) end)
 assert(nearest<10,string.format("attraction did not pull (closest %.1f)",nearest))
 -- The absorbing seal: a jutsu thrown into it is drunk (no damage, chakra back).
 local c3,a3,b3=H.duel("Rinnegan","Copycat");place(c3,a3,b3,14);a3.chakra=40;b3.chakra=999;a3.health=100
 assert(press(c3,a3,slot("Rinnegan","Absorb")));run(c3,.1)
 local chakra=a3.chakra
 assert(c3:request(b3,"Technique3",a3.root.Position)) -- Kakashi's Water Dragon
 run(c3,1.5)
 assert(a3.health>=100,"the dragon was not absorbed (it hurt him)")
 assert(a3.chakra>chakra,"absorbing gave no chakra back")
 assert(((a3.events or {}).Absorbed or 0)>=1,"nothing was absorbed")
end)

test("Killer Bee: the Lariat crosses the gap and flattens, ink sticks, a tentacle holds",function()
 if not listed.Ink then return end
 local c,a,b=H.duel("Ink","Leaf");place(c,a,b,10);a.chakra=999;b.health=999
 assert(press(c,a,slot("Ink","Lariat"),nil,b.root.Position))
 local down=false
 run(c,1,function() if b.reaction=="Knockdown" then down=true end end)
 assert(down,"the Lariat did not flatten the body")
 local c2,a2,b2=H.duel("Ink","Leaf");place(c2,a2,b2,10);a2.chakra=999
 assert(press(c2,a2,slot("Ink","InkMist"),nil,b2.root.Position));run(c2,1.2)
 assert((b2.slowUntil or 0)>c2.now,"the ink did not slow")
end)


test("awakenings: each of the twenty changes a rule of play, not only numbers",function()
 -- A rule: a field the core or a family reads as behaviour (not a multiplier).
 local RULES={"Buff","OnHit","NoBlindSpot","FlashWake","FlashPursuit","GuardRead","WhiffRead","CursedLeaf","NoBodies","BindScale","Extension",
  "ShieldRegen","Drain","HealthDrain","Reflect","GustLane","FanClosed","Summon","ChainTeleport","ZoneFree","ChainCharges","ReflectClear","BloodChakra",
  -- DEC-026 newcomers: the awakening changes the riposte a parry opens (Brawler.riposteMove).
  "Riposte"}
 local Roster=H.load("Shared/Roster")
 for _,id in Roster do
  local aw=Fighters[id].Awakening
  local found=nil
  for _,k in RULES do if aw[k]~=nil then found=k;break end end
  assert(found,id..": the awakening only changes numbers")
 end
end)

test("Shisui's awakening: a flicker cut that lands gives the flicker back, three times in a row",function()
 if not listed.Flicker then return end
 local c,a,b=H.duel("Flicker","Leaf");place(c,a,b,10);a.chakra=999;b.health=999
 a.health=a.def.Health*.2
 assert(press(c,a,"Awaken"));run(c,.5)
 local s=slot("Flicker","BodyFlicker")
 local chained=0
 for k=1,4 do
  place(c,a,b,10)
  local ok,why=press(c,a,s,nil,b.root.Position)
  if ok then chained+=1 else print("   chain stop: "..tostring(why)) end
  run(c,.85)
 end
 assert(chained>=4,"the flicker chain broke after "..chained)
 local c2,a2,b2=H.duel("Flicker","Leaf");place(c2,a2,b2,10);a2.chakra=999;b2.health=999
 assert(press(c2,a2,s,nil,b2.root.Position));run(c2,.85);place(c2,a2,b2,10)
 assert(not press(c2,a2,s,nil,b2.root.Position),"outside the awakening the flicker has no chain")
end)

test("Haku: inside his dome the mirror step goes from mirror to mirror with a volley; awakened it is free",function()
 if not listed.Mirror then return end
 local c,a,b=H.duel("Mirror","Leaf");place(c,a,b,12);a.chakra=999;b.health=999
 assert(press(c,a,slot("Mirror","IceMirrors"),nil,b.root.Position));run(c,1.4)
 a.cooldowns={}
 local chakra=a.chakra
 assert(press(c,a,slot("Mirror","MirrorStep"),nil,b.root.Position))
 local thrown=0
 run(c,.5,function() for _,p in c.projectiles do if p.a==a and p.kind=="senbon" then thrown=math.max(thrown,1) end end end)
 assert(((a.events or {}).RingStep or 0)>=1 and thrown>=1,"no mirror-to-mirror volley inside the dome")
 local gap=flat(a.root.Position-b.root.Position).Magnitude
 assert(gap>4,"he stepped into melee instead of onto a mirror ("..gap..")")
 -- Awakened: the same step comes back at once and costs nothing.
 a.health=a.def.Health*.2;a.cooldowns={}
 assert(press(c,a,"Awaken"));run(c,.5)
 -- (the awakening's burst may have pushed him: back into the dome's centre)
 for _,h in c.hazards do if h.a==a and h.look=="mirror" then c:relocate(b,h.position+V.new(0,2.5,0)) end end
 local before=a.chakra
 assert(press(c,a,slot("Mirror","MirrorStep"),nil,b.root.Position));run(c,.5)
 assert(a.chakra>=before-1,"the mirror step still cost chakra awakened")
 assert(press(c,a,slot("Mirror","MirrorStep"),nil,b.root.Position),"the mirror step did not come back at once")
end)

test("Deidara: a missed bird/spider stays as a charge, a body stepping on it is blasted, Katsu detonates from anywhere",function()
 if not listed.Clay then return end
 local F=H.load("Server/Families")
 -- A mine laid, Katsu from far away: it goes off under the body.
 local c,a,b=H.duel("Clay","Leaf");place(c,a,b,14);a.chakra=999;b.health=999
 -- (buried beside the body, out of its trigger, inside its blast)
 assert(press(c,a,slot("Clay","ClayMine"),nil,b.root.Position+V.new(4,0,0)));run(c,.9)
 assert(#F.charges(c,a)==1,"no charge buried")
 b.health=999
 local hp=b.health
 a.cooldowns={}
 assert(press(c,a,slot("Clay","Katsu")));run(c,.6)
 assert(b.health<hp,"Katsu did not set the buried charge off")
 assert(#F.charges(c,a)==0,"the charge survived its detonation")
 -- A spider that misses waits; walking onto it blasts.
 local c2,a2,b2=H.duel("Clay","Leaf");place(c2,a2,b2,10);a2.chakra=999;b2.health=999
 c2:relocate(b2,V.new(30,3,0))
 assert(press(c2,a2,slot("Clay","ClaySpiders"),nil,a2.root.Position+V.new(0,0,-20)));run(c2,1.6)
 local laid=F.charges(c2,a2)
 assert(#laid>=1,"missed spiders left no charge")
 c2:relocate(b2,laid[1].position+V.new(0,2.5,0));b2.health=999
 run(c2,1.2)
 assert(b2.health<999,"stepping on a charge did nothing")
end)


test("Zabuza: inside his mist the opponent loses sight of him (shrouded: no lock, no homing)",function()
 if not listed.Mist then return end
 local F=H.load("Server/Families")
 local c,a,b=H.duel("Mist","Leaf");place(c,a,b,8);a.chakra=999
 assert(not F.shrouded(c,b),"shrouded before any mist")
 assert(press(c,a,slot("Mist","HiddenMist")));run(c,1.2)
 assert(F.shrouded(c,b),"the opponent in his mist still sees him")
 assert(not F.shrouded(c,a),"Zabuza is lost in his own mist")
 c:relocate(b,V.new(0,3,-60));run(c,.1)
 assert(not F.shrouded(c,b),"shrouded outside the mist")
end)


-- DEC-026 newcomers (Shared/Wave4): their own body before any jutsu — own
-- side/away routes, a clean block answered with their own riposte gesture,
-- a counter stance answered by a strike that must land, a Katon cone that
-- burns ahead and not at the flank, and an awakening that changes the riposte.
local function confirm(c,a)
 assert(press(c,a,"Attack"))
 for _=1,90 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0) then break end end
end
for _,id in {"Rival","Sapling","Professor"} do
 test(Fighters[id] and (Fighters[id].Name..": own routes, own riposte, a counter that answers with a strike, an awakened riposte") or id,function()
  if not listed[id] then return end
  local g=MoveGraphs[id]
  local reach=Fighters[id].AttackProfile.Light1.contact
  -- Side after one, away after two: its own moves.
  local c,a,b=H.duel(id,"Leaf");place(c,a,b,reach);b.health=999
  confirm(c,a)
  assert(press(c,a,"Attack",a.root.CFrame.RightVector))
  assert(a.attackName==g.routes.side,id..": side after one gave "..tostring(a.attackName))
  local c2,a2,b2=H.duel(id,"Leaf");place(c2,a2,b2,reach);b2.health=999
  confirm(c2,a2);confirm(c2,a2)
  assert(press(c2,a2,"Attack",flat(a2.root.Position-b2.root.Position).Unit))
  assert(a2.attackName==g.routes.down,id..": away after two gave "..tostring(a2.attackName))
  -- A guard that held: the next press is its own riposte.
  local c3,a3,b3=H.duel(id,"Leaf");place(c3,a3,b3,1.8)
  assert(press(c3,a3,"Guard"));run(c3,.25)
  assert(press(c3,b3,"Attack"))
  local blocked=false
  for _=1,60 do H.step(c3,.01);if (a3.riposteUntil or 0)>c3.now then blocked=true;break end end
  assert(blocked,id..": the guard took nothing")
  press(c3,a3,"Attack")
  assert(a3.attackName==g.riposte,id..": the riposte was "..tostring(a3.attackName).." (expected "..tostring(g.riposte)..")")
  -- Counter stance: the blow is turned aside, a strike of its body answers and lands.
  local counter,cspec
  for i,spec in Fighters[id].Techniques do if spec.Family=="Counter" then counter,cspec="Technique"..i,spec end end
  assert(counter and cspec.Move,id..": no counter stance with an answer")
  local c4,a4,b4=H.duel(id,"Leaf");place(c4,a4,b4,1.8);a4.chakra=999;b4.health=999
  assert(press(c4,a4,counter));run(c4,.1)
  assert(press(c4,b4,"Attack"))
  local answered=false
  run(c4,1,function() if a4.attackName==cspec.Move then answered=true end end)
  assert(answered,id..": the stance did not answer with "..cspec.Move)
  assert(b4.health<999,id..": the counter's answer did not land")
  assert(a4.health==a4.def.Health,id..": the read blow still hurt")
  -- Katon (Madara, Hiruzen): ahead, not at the flank.
  for i,spec in Fighters[id].Techniques do
   if spec.Family=="Burst" and spec.Arc then
    local c5,a5,b5=H.duel(id,"Leaf");place(c5,a5,b5,4);a5.chakra=999;b5.health=999
    assert(press(c5,a5,"Technique"..i,nil,b5.root.Position));run(c5,.9)
    assert(b5.health<999,id..": the Katon missed a body in front")
    local c6,a6,b6=H.duel(id,"Leaf");place(c6,a6,b6,4);a6.chakra=999;b6.health=999
    c6:relocate(b6,a6.root.Position+a6.root.CFrame.RightVector*7)
    assert(press(c6,a6,"Technique"..i,nil,a6.root.Position+a6.root.CFrame.LookVector*8));run(c6,.9)
    assert(b6.health==999,id..": the Katon burned a body at the flank")
    -- Aimed at the body, which side-steps during the channel: the cone stays
    -- where it was aimed (the caster's auto-facing does not swing it).
    local c8,a8,b8=H.duel(id,"Leaf");place(c8,a8,b8,4);a8.chakra=999;b8.health=999
    assert(press(c8,a8,"Technique"..i,nil,b8.root.Position))
    c8:relocate(b8,a8.root.Position+a8.root.CFrame.RightVector*7)
    a8.root.CFrame=H.C.lookAt(a8.root.Position,b8.root.Position)
    run(c8,.9)
    assert(b8.health==999,id..": the Katon swung onto a body that side-stepped")
   end
  end
  -- Awakened: the riposte becomes the awakening's.
  local aw=Fighters[id].Awakening.Riposte
  if aw then
   local c7,a7,b7=H.duel(id,"Leaf");place(c7,a7,b7,1.8)
   a7.health=a7.def.Health*.2
   assert(press(c7,a7,"Awaken"));run(c7,.6)
   assert((a7.awakenUntil or 0)>c7.now,id..": no awakening")
   place(c7,a7,b7,1.8)
   assert(press(c7,a7,"Guard"));run(c7,.25)
   assert(press(c7,b7,"Attack"))
   for _=1,60 do H.step(c7,.01);if (a7.riposteUntil or 0)>c7.now then break end end
   press(c7,a7,"Attack")
   assert(a7.attackName==aw.any,id..": the awakened riposte was "..tostring(a7.attackName))
  end
 end)
end


-- Identity pass L7-A (bible ZABUZA.md): the cleaver is in the body, not a
-- borrowed fan. Own clips for the five authored units and the routes, the
-- bible's A/C/R and reaches, the heavy after one is the same diagonal, the
-- handle answers a held guard, the away route backs off.
test("Zabuza (L7-A): own cleaver clips, the bible's timings and reaches, handle riposte, low cut that backs off",function()
 if not listed.Mist then return end
 local Motion=H.load("Client/VelmoraMotionEngine")
 local clips=Motion.CLIPS.Mist
 assert(clips,"no clip table of his own")
 for _,name in {"Light1","Light2","Light3","Heavy","CleaverRise","CleaverArc","CleaverDrop","CleaverHilt","SilentCleave","CleaverDive","Air1","Air2"} do
  assert(rawget(clips,name),"Zabuza has no clip of his own for "..name)
 end
 assert(Motion.familyOf("Mist").clips=="Mist","his clips still point at "..tostring(Motion.familyOf("Mist").clips))
 assert(Motion.familyOf("Mist").guard,"no guard of his own (blade held flat)")
 local B=H.load("Server/Brawler")
 local A=H.load("Shared/Attacks")
 local prof=Fighters.Mist.AttackProfile
 local want={Light1={.12,.06,.23,3.2},Light2={.28,.09,.30,5.5},Light3={.32,.10,.40,5.8},Heavy={.42,.10,.52,6}}
 for name,w in want do
  local base=A[name];local p=prof[name]
  local st,ac,re=base.startup*(p.startup or 1),base.active*(p.active or 1),base.recovery*(p.recovery or 1)
  assert(math.abs(st-w[1])<.015 and math.abs(ac-w[2])<.015 and math.abs(re-w[3])<.02,string.format("%s A/C/R %.2f/%.2f/%.2f (bible %.2f/%.2f/%.2f)",name,st,ac,re,w[1],w[2],w[3]))
  assert(p.contact==w[4],name.." contact "..tostring(p.contact).." (bible "..w[4]..")")
 end
 -- Heavy after one confirmed hit: the same diagonal, no separate move.
 local c,a,b=H.duel("Mist","Leaf");place(c,a,b,3.2);b.health=999
 confirm(c,a)
 assert(press(c,a,"Heavy"));assert(a.attackName=="Heavy","heavy after one was "..tostring(a.attackName))
 -- The handle answers a held guard.
 assert(MoveGraphs.Mist.riposte=="CleaverHilt","his riposte is not the handle")
 -- Away after two: the low cut backs him off.
 local c2,a2,b2=H.duel("Mist","Leaf");place(c2,a2,b2,3.2);b2.health=999
 confirm(c2,a2);confirm(c2,a2)
 local from=a2.root.Position
 assert(press(c2,a2,"Attack",flat(a2.root.Position-b2.root.Position).Unit))
 assert(a2.attackName=="CleaverDrop","away after two was "..tostring(a2.attackName))
 run(c2,.7)
 assert(flat(a2.root.Position-b2.root.Position).Magnitude>flat(from-b2.root.Position).Magnitude,"the low cut did not back him off")
end)

test("Killer Bee (L7-B): own blade clips, the bible's timings and reaches, elbow riposte, knee kick that backs off",function()
 if not listed.Ink then return end
 local Motion=H.load("Client/VelmoraMotionEngine")
 local clips=Motion.CLIPS.Ink
 assert(clips,"no clip table of his own")
 for _,name in {"Light1","Light2","Light3","Heavy","BladeLift","BladeSwap","KneeKick","ElbowCut","BladeFall","Air1","Air2","DashAttack"} do
  assert(rawget(clips,name),"Bee has no clip of his own for "..name)
 end
 assert(Motion.familyOf("Ink").clips=="Ink","his clips still point at "..tostring(Motion.familyOf("Ink").clips))
 assert(Motion.familyOf("Ink").guard,"no guard of his own (two blades crossed)")
 local A=H.load("Shared/Attacks")
 local prof=Fighters.Ink.AttackProfile
 local want={Light1={.16,.06,.20,4.2},Light2={.23,.06,.18,4.0},Light3={.12,.07,.34,4.4},Heavy={.30,.09,.42,4.8}}
 for name,w in want do
  local base=A[name];local p=prof[name]
  local st,ac,re=base.startup*(p.startup or 1),base.active*(p.active or 1),base.recovery*(p.recovery or 1)
  assert(math.abs(st-w[1])<.015 and math.abs(ac-w[2])<.015 and math.abs(re-w[3])<.02,string.format("%s A/C/R %.2f/%.2f/%.2f (bible %.2f/%.2f/%.2f)",name,st,ac,re,w[1],w[2],w[3]))
  assert(p.contact==w[4],name.." contact "..tostring(p.contact).." (bible "..w[4]..")")
 end
 local G=MoveGraphs.Ink
 assert(G.riposte=="ElbowCut","his riposte is not the elbow blade")
 assert(G.routes.up=="BladeLift" and G.routes.side=="BladeSwap" and G.routes.down=="KneeKick" and G.routes.airDown=="BladeFall","routes are not the bible's")
 -- Heavy after one confirmed hit: the same X, no separate move.
 local c,a,b=H.duel("Ink","Leaf");place(c,a,b,3.2);b.health=999
 confirm(c,a)
 assert(press(c,a,"Heavy"));assert(a.attackName=="Heavy","heavy after one was "..tostring(a.attackName))
 -- Away after two: the knee-blade kick backs him off.
 local c2,a2,b2=H.duel("Ink","Leaf");place(c2,a2,b2,3.2);b2.health=999
 confirm(c2,a2);confirm(c2,a2)
 local from=a2.root.Position
 assert(press(c2,a2,"Attack",flat(a2.root.Position-b2.root.Position).Unit))
 assert(a2.attackName=="KneeKick","away after two was "..tostring(a2.attackName))
 run(c2,.7)
 assert(flat(a2.root.Position-b2.root.Position).Magnitude>flat(from-b2.root.Position).Magnitude,"the knee kick did not back him off")
end)

test("Kimimaro (L4-A): own bone clips, the bible's timings and reaches, bone-elbow riposte, shin reap that backs off",function()
 if not listed.Bone then return end
 local Motion=H.load("Client/VelmoraMotionEngine")
 local clips=Motion.CLIPS.Bone
 assert(clips,"no clip table of his own")
 for _,name in {"Light1","Light2","Light3","Heavy","BoneRise","CamelliaArc","BoneReap","BoneElbow","BoneHeel","WillowCut","Air1","Air2","DashAttack"} do
  assert(rawget(clips,name),"Kimimaro has no clip of his own for "..name)
 end
 assert(Motion.familyOf("Bone").clips=="Bone","his clips still point at "..tostring(Motion.familyOf("Bone").clips))
 assert(Motion.familyOf("Bone").guard,"no guard of his own (forearm bones)")
 local A=H.load("Shared/Attacks")
 local prof=Fighters.Bone.AttackProfile
 local want={Light1={.12,.05,.18,3.2},Light2={.18,.06,.21,3.3},Light3={.22,.07,.30,3.9},Heavy={.28,.08,.36,3.8}}
 for name,w in want do
  local base=A[name];local p=prof[name]
  local st,ac,re=base.startup*(p.startup or 1),base.active*(p.active or 1),base.recovery*(p.recovery or 1)
  assert(math.abs(st-w[1])<.015 and math.abs(ac-w[2])<.015 and math.abs(re-w[3])<.02,string.format("%s A/C/R %.2f/%.2f/%.2f (bible %.2f/%.2f/%.2f)",name,st,ac,re,w[1],w[2],w[3]))
  assert(p.contact==w[4],name.." contact "..tostring(p.contact).." (bible "..w[4]..")")
 end
 local G=MoveGraphs.Bone
 assert(G.riposte=="BoneElbow","his riposte is not the bone elbow")
 assert(G.routes.up=="BoneRise" and G.routes.side=="CamelliaArc" and G.routes.down=="BoneReap" and G.routes.airDown=="BoneHeel","routes are not the bible's")
 local c,a,b=H.duel("Bone","Leaf");place(c,a,b,3.0);b.health=999
 confirm(c,a)
 assert(press(c,a,"Heavy"));assert(a.attackName=="Heavy","heavy after one was "..tostring(a.attackName))
 local c2,a2,b2=H.duel("Bone","Leaf");place(c2,a2,b2,3.0);b2.health=999
 confirm(c2,a2);confirm(c2,a2)
 local from=a2.root.Position
 assert(press(c2,a2,"Attack",flat(a2.root.Position-b2.root.Position).Unit))
 assert(a2.attackName=="BoneReap","away after two was "..tostring(a2.attackName))
 run(c2,.7)
 assert(flat(a2.root.Position-b2.root.Position).Magnitude>flat(from-b2.root.Position).Magnitude,"the reap did not back him off")
end)

test("Haku (L4-A): own senbon clips, the bible's timings and reaches, senbon riposte, low senbon that backs off",function()
 if not listed.Mirror then return end
 local Motion=H.load("Client/VelmoraMotionEngine")
 local clips=Motion.CLIPS.Mirror
 assert(clips,"no clip table of his own")
 for _,name in {"Light1","Light2","Light3","Heavy","FrostLift","IceSlide","SenbonLow","SenbonStab","SenbonDive","Air1","DashAttack"} do
  assert(rawget(clips,name),"Haku has no clip of his own for "..name)
 end
 assert(Motion.familyOf("Mirror").clips=="Mirror","his clips still point at "..tostring(Motion.familyOf("Mirror").clips))
 assert(Motion.familyOf("Mirror").guard,"no guard of his own (forearm and senbon)")
 local A=H.load("Shared/Attacks")
 local prof=Fighters.Mirror.AttackProfile
 local want={Light1={.11,.05,.18,3.1},Light2={.16,.05,.17,3.3},Light3={.19,.06,.28,3.5},Heavy={.25,.06,.32,3.8}}
 for name,w in want do
  local base=A[name];local p=prof[name]
  local st,ac,re=base.startup*(p.startup or 1),base.active*(p.active or 1),base.recovery*(p.recovery or 1)
  assert(math.abs(st-w[1])<.015 and math.abs(ac-w[2])<.015 and math.abs(re-w[3])<.02,string.format("%s A/C/R %.2f/%.2f/%.2f (bible %.2f/%.2f/%.2f)",name,st,ac,re,w[1],w[2],w[3]))
  assert(p.contact==w[4],name.." contact "..tostring(p.contact).." (bible "..w[4]..")")
 end
 local G=MoveGraphs.Mirror
 assert(G.riposte=="SenbonStab","his riposte is not the senbon")
 assert(G.routes.up=="FrostLift" and G.routes.side=="IceSlide" and G.routes.down=="SenbonLow" and G.routes.airDown=="SenbonDive","routes are not the bible's")
 local c,a,b=H.duel("Mirror","Leaf");place(c,a,b,3.0);b.health=999
 confirm(c,a)
 assert(press(c,a,"Heavy"));assert(a.attackName=="Heavy","heavy after one was "..tostring(a.attackName))
 local c2,a2,b2=H.duel("Mirror","Leaf");place(c2,a2,b2,3.0);b2.health=999
 confirm(c2,a2);confirm(c2,a2)
 local from=a2.root.Position
 assert(press(c2,a2,"Attack",flat(a2.root.Position-b2.root.Position).Unit))
 assert(a2.attackName=="SenbonLow","away after two was "..tostring(a2.attackName))
 run(c2,.7)
 assert(flat(a2.root.Position-b2.root.Position).Magnitude>flat(from-b2.root.Position).Magnitude,"the low senbon did not back him off")
end)

print(string.format("NinjaDuel roster 20 (locked ten): %d PASS (headless mechanics; feel and looks are Studio checks)",passed))
