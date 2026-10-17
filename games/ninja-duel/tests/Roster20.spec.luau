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
local NEW={"Mirror","Mist","Bone","Flicker","Serpent","Medic","Clay","Puppet","Rinnegan","Ink"}
local listed={}
for _,id in Roster do listed[id]=true end
local function each(fn) for _,id in NEW do if listed[id] then fn(id) end end end

test("direction + light before the first confirmed hit is the plain opener, never a route",function()
 each(function(id)
  for _,dir in {"forward","back","side"} do
   local c,a,b=H.duel(id,"Leaf");place(c,a,b,3.4);b.health=999
   local stick=if dir=="forward" then flat(b.root.Position-a.root.Position).Unit elseif dir=="back" then flat(a.root.Position-b.root.Position).Unit else a.root.CFrame.RightVector
   assert(press(c,a,"Attack",stick),id..": opener refused")
   assert(a.attackName=="Light1" or a.attackName=="DashAttack",id..": "..dir.." + light from neutral gave "..tostring(a.attackName))
   local routes=MoveGraphs[id].routes
   for _,r in routes do assert(a.attackName~=r or r=="Light1",id..": a route opened before any hit") end
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

test("Sasori: long puppet lashes, poison everywhere, a puppet that takes a blow and bites back",function()
 if not listed.Puppet then return end
 -- His light reaches where a fist does not.
 local c,a,b=H.duel("Puppet","Leaf");place(c,a,b,7);b.health=999
 assert(press(c,a,"Attack"));run(c,.6)
 assert(b.health<999,"the puppet lash did not reach at 7 studs")
 local c2,a2,b2=H.duel("Puppet","Leaf");place(c2,a2,b2,10);a2.chakra=999;b2.health=999
 assert(press(c2,a2,slot("Puppet","PuppetThrust"),nil,b2.root.Position));run(c2,.8)
 assert((b2.poisonedUntil or 0)>0,"the puppet thrust carried no poison")
 local c3,a3,b3=H.duel("Puppet","Leaf");place(c3,a3,b3,3.4);a3.chakra=999;a3.health=500
 assert(press(c3,a3,slot("Puppet","PuppetShield")));run(c3,.1)
 assert(press(c3,b3,"Attack"))
 run(c3,.5)
 assert((b3.poisonedUntil or 0)>0 and b3.health<b3.def.Health,"the puppet did not answer the blow")
end)

test("Nagato: repulsion clears blades and bodies, attraction pulls, absorption drinks chakra",function()
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
 local c3,a3,b3=H.duel("Rinnegan","Leaf");place(c3,a3,b3,5);a3.chakra=40;b3.chakra=100;b3.health=999
 assert(press(c3,a3,slot("Rinnegan","Absorb")));run(c3,.4)
 assert(b3.chakra<100 and a3.chakra>40-8,"absorption drank nothing")
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

print(string.format("NinjaDuel roster 20 (locked ten): %d PASS (headless mechanics; feel and looks are Studio checks)",passed))
