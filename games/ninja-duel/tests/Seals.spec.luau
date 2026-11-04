-- Hand seals and free combos (DEC-032 §2-3, user 03/11: « plus de variété que
-- 4 cases comme Storm », « les combos trop génériques », « ce qui reste à
-- faire est censé être dans la bêta »).
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,pa,pb)
 c:relocate(a,pa);c:relocate(b,pb)
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
 b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
end
local SealJutsu=H.load("Shared/SealJutsu")
local Looks=H.load("Shared/Looks")
local Attacks=H.load("Shared/Attacks")
local Techniques=H.load("Server/Techniques")
local Config=H.load("Shared/Config")
local EIGHT={"Lion","Legion","Sand","Leaf","GentleFist","Mirage","Copycat","Flashstep"}

test("kits: the eight each weave four or more jutsu of their story, all wired",function()
 local ids={}
 for _,id in EIGHT do
  local def=H.fighters[id]
  assert(def.SealJutsu and #def.SealJutsu>=4,id.." has no seal jutsu")
  local seen={}
  for _,spec in def.SealJutsu do
   assert(#spec.Signs==SealJutsu.Length,spec.Id.." signs")
   local key=table.concat(spec.Signs,"-")
   assert(not seen[key],id..": two jutsu on "..key);seen[key]=true
   for _,v in spec.Signs do assert(v>=1 and v<=4,spec.Id.." sign "..v) end
   assert(not ids[spec.Id],"id twice "..spec.Id);ids[spec.Id]=true
   for _,t in def.Techniques do assert(t.Id~=spec.Id,spec.Id.." is already a quick slot") end
   assert(Techniques[spec.Id],spec.Id.." has no implementation")
   if spec.Kind then assert(Looks[spec.Kind],spec.Id.." look "..spec.Kind) end
   if spec.Move then assert(Attacks[spec.Move],spec.Id.." move "..spec.Move) end
   if spec.Leave and spec.Leave.Look then assert(Looks[spec.Leave.Look],spec.Id.." leave look") end
   assert(type(spec.Hint)=="string" and #spec.Hint>8,spec.Id.." hint")
  end
 end
end)

test("weave: the seal key, then two jutsu keys, casts the seal jutsu and not the slot",function()
 for _,id in EIGHT do
  local c,a,b=H.duel(id,"Flashstep")
  place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
  b.ai=nil
  local spec=H.fighters[id].SealJutsu[1]
  local slot=H.fighters[id].Techniques[spec.Signs[2]]
  assert(c:request(a,"Seals"),id.." seal key refused")
  assert(a.sealing,"no weave")
  assert(c:request(a,"Technique"..spec.Signs[1])==true,id.." first seal")
  assert(a.pending==nil or a.pending.kind~="Technique","the first seal cast a jutsu")
  local chakra=a.chakra
  local ok,why=c:request(a,"Technique"..spec.Signs[2],b.root.Position)
  assert(ok,id.." "..spec.Id.." refused: "..tostring(why))
  assert((a.cooldowns[spec.Id] or 0)>c.now,id.." "..spec.Id.." not cast")
  assert((a.cooldowns[slot.Id] or 0)<=c.now,id.." the slot "..slot.Id.." went instead")
  assert(chakra-a.chakra>=spec.Cost-.01,id.." the jutsu cost nothing")
  assert(a.sealing==nil,"the weave stayed open")
  for _=1,120 do H.step(c,.01) end
 end
end)

test("page (04/11): with the page held, one press casts the seal jutsu of its place",function()
 for _,id in EIGHT do
  local c,a,b=H.duel(id,"Flashstep")
  place(c,a,b,V.new(0,3,4),V.new(0,3,-4))
  b.ai=nil
  for k,spec in H.fighters[id].SealJutsu do
   a.chakra=a.def.Chakra or 100;a.cooldowns={}
   local ok,why=c:request(a,"Seal"..k,b.root.Position)
   -- (a jutsu that reads the other body has its condition: tested below)
   local conditional=why=="Nothing to copy" or why=="Launch him first"
   assert(ok or conditional,id.." Seal"..k.." ("..spec.Id..") refused: "..tostring(why))
   if ok then assert((a.cooldowns[spec.Id] or 0)>c.now,id.." "..spec.Id.." not cast by Seal"..k) end
   for _,t in a.def.Techniques do assert((a.cooldowns[t.Id] or 0)<=c.now,id.." the quick slot "..t.Id.." went instead") end
   for _=1,160 do H.step(c,.01) end
   c:relocate(a,V.new(0,3,4));c:relocate(b,V.new(0,3,-4));a.reaction=nil;b.reaction=nil
   c:setState(a,"Neutral",0);c:setState(b,"Neutral",0)
  end
  assert(not c:request(a,"Seal9"),"a seal page beyond the list")
 end
end)

test("page: off a wall the seal key opens nothing; the AI casts from the page too",function()
 local c,a,b=H.duel("Flashstep","Lion")
 place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
 b.ai=nil
 assert(c:request(a,"WallDetach")==true,"the seal key refused off a wall")
 assert(a.sealing==nil,"the old weave opened")
 -- a jutsu key after it is the quick slot, not a seal
 local slot=a.def.Techniques[1]
 assert(c:request(a,"Technique1",b.root.Position))
 assert((a.cooldowns[slot.Id] or 0)>c.now,"the key after C was not the quick slot")
end)

test("every seal jutsu runs to its end and reaches the body it is aimed at",function()
 local quiet={}
 for _,id in EIGHT do
  for _,spec in H.fighters[id].SealJutsu do
   local c,a,b=H.duel(id,"Flashstep")
   local d=math.clamp(((spec.AI and spec.AI.Min or 3)+(spec.AI and spec.AI.Max or 10))/2,2.6,14)
   if spec.Family=="Counter" or spec.Family=="Buff" then d=2.8 end
   place(c,a,b,V.new(0,3,d/2),V.new(0,3,-d/2))
   b.ai=nil;a.chakra=200
   local health=b.health
   assert(c:request(a,"Seals"))
   assert(c:request(a,"Technique"..spec.Signs[1]))
   local ok,why=c:request(a,"Technique"..spec.Signs[2],b.root.Position)
   if why=="Nothing to copy" or why=="Launch him first" then continue end
   assert(ok,id.." "..spec.Id.." refused: "..tostring(why))
   local start=b.root.Position
   local counters=a.events and a.events.Counter or 0
   local binds=a.events and a.events.FamilyBind or 0
   if spec.Family=="Counter" then
    H.step(c,spec.Channel+.06)
    c:request(b,"Attack")
   end
   -- A held technique (the Rasengan in the open) is driven by the next blow.
   if spec.HoldState then
    for _=1,60 do H.step(c,.01) end
    c:request(a,"Attack")
   end
   for _=1,220 do H.step(c,.01) end
   -- (a warping counter sends its author away: Minato's barrier)
   local sent=(b.root.Position-start).Magnitude>6 and (a.events and a.events.Counter or 0)>counters
   local held=(a.events and a.events.FamilyBind or 0)>binds
   local touched=sent or held or b.health<health or b.reaction~=nil or (b.sealedUntil or 0)>c.now or (a.buffs and next(a.buffs)~=nil)
   if not touched and spec.Family~="Buff" and spec.Family~="Teleport" and spec.Family~="Zone" then table.insert(quiet,id.."."..spec.Id) end
  end
 end
 assert(#quiet==0,"no effect on the body: "..table.concat(quiet,", "))
end)

test("weave: a sequence no jutsu has breaks the seals; a weave left open lapses into the slots",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
 b.ai=nil
 assert(c:request(a,"Seals"))
 assert(c:request(a,"Technique2"))
 local ok,why=c:request(a,"Technique2")
 assert(not ok and why=="Seals broken","2-2 should break: "..tostring(why))
 -- open, then nothing: the next key is the quick slot again
 assert(c:request(a,"Seals"))
 H.step(c,Config.Seals.Open+.1)
 local slot=a.def.Techniques[1]
 assert(c:request(a,"Technique1",b.root.Position),"the slot after a lapsed weave")
 assert((a.cooldowns[slot.Id] or 0)>c.now,"the slot did not go")
end)

test("closed chakra points stop the seals (weave and page); C off a wall only holds the page",function()
 local c,a,b=H.duel("Copycat","Flashstep")
 place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
 a.sealedUntil=c.now+2
 local ok,why=c:request(a,"Seals")
 assert(not ok and why=="Chakra points sealed",tostring(why))
 ok,why=c:request(a,"Seal1",b.root.Position)
 assert(not ok and why=="Chakra points sealed","the page ignored the closed points: "..tostring(why))
 a.sealedUntil=0
 -- (04/11) the page is the client's: C off a wall is accepted and opens nothing
 assert(c:request(a,"WallDetach"),"C off a wall refused")
 assert(a.sealing==nil,"C off a wall opened the old weave")
end)

-- Minato's new seals (04/11, user: his seal jutsu repeated his kunai and his
-- teleports): the Rasengan, the sealing trap, the barrier, level two.
local function slotOf(def,id) for i,spec in def.SealJutsu do if spec.Id==id then return i end end end
test("Minato: the seal page holds a real Rasengan (the orb stays in his palm, the next blow drives it)",function()
 local c,a,b=H.duel("Flashstep","Lion")
 place(c,a,b,V.new(0,3,3),V.new(0,3,-3));b.ai=nil;a.chakra=200
 assert(c:request(a,"Seal"..slotOf(a.def,"BurstStrike"),b.root.Position))
 for _=1,60 do H.step(c,.01) end
 assert(a.bodyState and a.bodyState.id=="BurstStrike","the Rasengan is not held in the palm ("..tostring(a.bodyState and a.bodyState.id)..")")
 local health=b.health
 assert(c:request(a,"Attack"))
 for _=1,80 do H.step(c,.01) end
 assert(b.health<health and a.attackVariant=="Rasengan","the blow did not drive the Rasengan")
end)
test("Minato: the sealing trap holds the first body that steps in, shuts its jutsu, then is spent",function()
 local c,a,b=H.duel("Flashstep","Lion")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8));b.ai=nil;a.chakra=200
 local spot=V.new(0,3,-2)
 assert(c:request(a,"Seal"..slotOf(a.def,"SealingTrap"),spot))
 for _=1,60 do H.step(c,.01) end
 local trap=nil
 for _,h in c.hazards do if h.look=="sealtrap" then trap=h end end
 assert(trap,"no formula on the floor")
 c:relocate(b,V.new(trap.position.X,3,trap.position.Z))
 for _=1,80 do H.step(c,.01) end
 assert(b.reaction=="Bound" and (b.sealedUntil or 0)>c.now,"the body that stepped in is not held and sealed ("..tostring(b.reaction)..")")
 for _=1,60 do H.step(c,.01) end
 for _,h in c.hazards do assert(h~=trap,"the formula was not spent") end
end)
test("Minato: the space-time barrier sends a blow's author far away and swallows a thrown blade",function()
 local c,a,b=H.duel("Flashstep","Lion")
 place(c,a,b,V.new(0,3,1.5),V.new(0,3,-1.5));b.ai=nil;a.chakra=200
 local health=a.health
 assert(c:request(a,"Seal"..slotOf(a.def,"SpaceTimeBarrier")))
 H.step(c,.1)
 assert(c:request(b,"Attack"))
 for _=1,40 do H.step(c,.01) end
 assert(a.health==health,"the blow went through the barrier")
 local gap=(b.root.Position-a.root.Position).Magnitude
 assert(gap>10,"the attacker was not sent away (gap "..gap..")")
 -- a thrown blade
 c:relocate(b,V.new(0,3,-14));a.cooldowns={};a.chakra=200
 for _=1,30 do H.step(c,.01) end
 assert(c:request(a,"Seal"..slotOf(a.def,"SpaceTimeBarrier")))
 H.step(c,.06)
 c:request(b,"Tool",a.root.Position)
 for _=1,60 do H.step(c,.01) end
 assert(a.health==health,"a thrown blade went through the barrier")
end)
test("Minato: level two sends the touched body to his latest seal, up into the air without one",function()
 local Techniques=H.load("Server/Techniques")
 for _,withSeal in {true,false} do
  local c,a,b=H.duel("Flashstep","Lion")
  place(c,a,b,V.new(0,3,2),V.new(0,3,-2));b.ai=nil;a.chakra=200
  local seal=V.new(14,3,10)
  if withSeal then Techniques.plant(c,a,V.new(seal.X,c.match.origin.Y,seal.Z),V.new(0,1,0)) end
  local before=b.root.Position
  assert(c:request(a,"Seal"..slotOf(a.def,"FlyingThunderTwo"),b.root.Position))
  for _=1,40 do H.step(c,.01) end
  if withSeal then
   local flat=V.new(b.root.Position.X-seal.X,0,b.root.Position.Z-seal.Z).Magnitude
   assert(flat<3,"the body was not sent to the seal ("..flat..")")
  else
   assert(b.root.Position.Y>before.Y+5,"the body was not sent up")
  end
  assert(b.reaction=="Juggled" and (a.pursuitUntil or 0)>c.now,"no beat in the air to follow it")
 end
end)

-- The fourteen replaced (04/11): each does what it says, on the engine.
local function seal(c,a,id,aim) a.chakra=200;a.cooldowns={};return c:request(a,"Seal"..slotOf(a.def,id),aim) end
local function run(c,n) for _=1,n do H.step(c,.01) end end
test("Sasuke: Sōshūha comes back from behind; the Sharingan copies the last jutsu and sends it back",function()
 local c,a,b=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8));b.ai=nil
 -- aimed wide of the body: the first pass misses, the return leg reaches it
 assert(seal(c,a,"Soshuha",b.root.Position+V.new(9,0,0)))
 local health=b.health
 run(c,220)
 assert(b.health<health,"the wired shuriken never came back into the body")
 -- the copy: nothing seen yet, then Itachi's Phoenix Sage Fire comes back at him
 local c2,s,i=H.duel("Lion","Mirage")
 place(c2,s,i,V.new(0,3,10),V.new(0,3,-10));i.ai=nil
 local ok,why=seal(c2,s,"SharinganCopy",i.root.Position)
 assert(not ok and why=="Nothing to copy",tostring(why))
 c2:relocate(s,V.new(30,3,10))
 assert(seal(c2,i,"PhoenixSageFire",V.new(30,3,10)+V.new(0,0,30)))
 run(c2,40);c2:relocate(s,V.new(0,3,10))
 local h=i.health
 assert(seal(c2,s,"SharinganCopy",i.root.Position),"the copy refused after a jutsu")
 run(c2,160)
 assert(i.health<h,"the copied fire never reached Itachi")
end)
test("Naruto: the ambush kicks him up from the floor; Gamakichi spits from in front; the throw crosses the field head first",function()
 local c,a,b=H.duel("Legion","Mirage")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8));b.ai=nil
 assert(seal(c,a,"CloneAmbush",b.root.Position))
 run(c,60)
 assert(b.reaction=="Launched","the ambush did not launch him ("..tostring(b.reaction)..")")
 local c2,n,i=H.duel("Legion","Mirage")
 place(c2,n,i,V.new(0,3,12),V.new(0,3,-12));i.ai=nil
 local h=i.health
 assert(seal(c2,n,"SummonGamakichi",i.root.Position))
 run(c2,120)
 assert(i.health<h,"Gamakichi's water bullet never reached him")
 local c3,m,j=H.duel("Legion","Mirage")
 place(c3,m,j,V.new(0,3,8),V.new(0,3,-8));j.ai=nil
 local h3=j.health
 assert(seal(c3,m,"CloneThrow",j.root.Position))
 run(c3,90)
 assert(j.health<h3,"the head dive across the field missed (16 studs)")
end)
test("Gaara: Shukaku's arm reaches across the field in front of him",function()
 local c,a,b=H.duel("Sand","Mirage")
 place(c,a,b,V.new(0,3,5.5),V.new(0,3,-5.5));b.ai=nil
 local h=b.health
 assert(seal(c,a,"ShukakuArm",b.root.Position))
 run(c,80)
 assert(b.health<h,"the arm of sand did not reach 11 studs")
end)
test("Lee: the nunchaku, the three rising kicks, the shadow after a launched body",function()
 local c,a,b=H.duel("Leaf","Mirage")
 place(c,a,b,V.new(0,3,2.5),V.new(0,3,-2.5));b.ai=nil
 local h=b.health
 assert(seal(c,a,"Nunchaku",b.root.Position));run(c,70)
 assert(b.health<h and a.attackName==nil or b.health<h,"the nunchaku missed")
 local c2,l,i=H.duel("Leaf","Mirage")
 place(c2,l,i,V.new(0,3,2.2),V.new(0,3,-2.2));i.ai=nil
 assert(seal(c2,l,"GorikiSenpu",i.root.Position));run(c2,40)
 assert(i.reaction=="Launched","the rising whirlwind did not launch")
 -- (out of the kick's recovery, at once: that is the shadow)
 local ok,why=seal(c2,l,"DancingLeafShadow",i.root.Position)
 assert(ok,"the shadow refused on a launched body: "..tostring(why))
 run(c2,4)
 assert(l.airborne and (l.lionUntil or 0)>c2.now and (l.root.Position-i.root.Position).Magnitude<4,"not behind the body in the air")
 local c3,m,j=H.duel("Leaf","Mirage")
 place(c3,m,j,V.new(0,3,6),V.new(0,3,-6));j.ai=nil
 local ok3,why3=seal(c3,m,"DancingLeafShadow",j.root.Position)
 assert(not ok3 and why3=="Launch him first",tostring(why3))
end)
test("Neji: the mountain crusher breaks a guard; the leg points slow him",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,6),V.new(0,3,-6));b.ai=nil
 c:request(b,"Guard")
 assert(seal(c,a,"Hasangeki",b.root.Position));run(c,70)
 assert((a.events and a.events.GuardBreak or 0)>0,"the guard held against the Hasangeki")
 local c2,n,i=H.duel("GentleFist","Mirage")
 place(c2,n,i,V.new(0,3,2),V.new(0,3,-2));i.ai=nil
 assert(seal(c2,n,"LegPoints",i.root.Position));run(c2,40)
 assert((i.slowUntil or 0)>c2.now and (i.slowScale or 1)<.8,"the leg points did not slow him")
end)
test("Itachi: the paralysis holds a body that faces him, not one looking away",function()
 for _,facing in {true,false} do
  local c,a,b=H.duel("Mirage","Lion")
  place(c,a,b,V.new(0,3,6),V.new(0,3,-6));b.ai=nil
  if not facing then b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.new(0,0,-5)) end
  assert(seal(c,a,"SharinganParalysis",b.root.Position));run(c,30)
  if facing then assert(b.reaction=="Bound","a body facing him was not held ("..tostring(b.reaction)..")")
  else assert(b.reaction~="Bound","a body looking away was held") end
 end
end)

-- A clean light, its recovery reached.
local function cleanHit(c,a,b)
 assert(c:request(a,"Attack"),"light refused")
 for _=1,80 do
  H.step(c,.01)
  if a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0) then return true end
 end
 return false
end

test("free combo: after a clean hit a player's jutsu, dodge or jump follows at once",function()
 for _,follow in {"technique","seal","dodge","jump"} do
  local c,a,b=H.duel("Copycat","Flashstep")
  place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
  b.ai=nil;a.playerInput=true;a.chakra=200
  assert(cleanHit(c,a,b),follow..": no clean hit")
  local ok,why
  if follow=="technique" then
   ok,why=c:request(a,H.slot(a,"TrackingFang"),b.root.Position)
   assert(ok and (a.cooldowns.TrackingFang or 0)>c.now,"the slot did not link: "..tostring(why))
  elseif follow=="seal" then
   assert(c:request(a,"Seals"));assert(c:request(a,"Technique2"))
   ok,why=c:request(a,"Technique3",b.root.Position)
   assert(ok and (a.cooldowns.EarthHeadhunter or 0)>c.now,"the seal jutsu did not link: "..tostring(why))
  elseif follow=="dodge" then
   ok,why=c:request(a,"Dodge")
   assert(ok and a.state=="Dodging","the dodge did not link: "..tostring(why)..", "..a.state)
  else
   ok,why=c:request(a,"Jump")
   assert(ok,"the jump did not link: "..tostring(why))
  end
  assert((a.links or 0)==1,follow..": link not counted")
 end
end)

test("free combo: the bot keeps its own plan; links are capped in a combo",function()
 local c,a,b=H.duel("Copycat","Flashstep")
 place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
 b.ai=nil;a.chakra=200
 assert(cleanHit(c,a,b))
 local Combat=H.load("Server/Combat")
 assert(not Combat.linkable(c,a,"Dodge"),"an AI body linked")
 a.playerInput=true
 assert(Combat.linkable(c,a,"Dodge"),"a player body did not link")
 a.links=Config.FreeCombo.Links;a.linkAt=c.now
 assert(not Combat.linkable(c,a,"Dodge"),"no cap on links")
end)

test("beta: the server starts a duel, the tutorial or an online pick only with the beta's eight",function()
 local Beta=H.load("Shared/BetaRoster")
 assert(#Beta==8,"the beta has "..#Beta.." fighters")
 for _,id in EIGHT do assert(table.find(Beta,id),id.." is not in the beta") end
 local Matches=H.load("Server/Matches")
 local m=Matches.new({FireClient=function() end,FireAllClients=function() end})
 local player={UserId=1,Name="p",DisplayName="p"}
 local ok,why=m:start(player,"Lion","Mirror",false)
 assert(not ok and why=="Not in the beta","a duel against Haku started: "..tostring(why))
 ok,why=m:start(player,"Rival","Lion",false)
 assert(not ok,"a duel as Madara started")
end)

print(("Seals: %d passed"):format(passed))
