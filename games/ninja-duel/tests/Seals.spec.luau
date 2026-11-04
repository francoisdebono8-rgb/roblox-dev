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
  place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
  b.ai=nil
  for k,spec in H.fighters[id].SealJutsu do
   a.chakra=a.def.Chakra or 100;a.cooldowns={}
   local ok,why=c:request(a,"Seal"..k,b.root.Position)
   assert(ok,id.." Seal"..k.." ("..spec.Id..") refused: "..tostring(why))
   assert((a.cooldowns[spec.Id] or 0)>c.now,id.." "..spec.Id.." not cast by Seal"..k)
   for _,t in a.def.Techniques do assert((a.cooldowns[t.Id] or 0)<=c.now,id.." the quick slot "..t.Id.." went instead") end
   for _=1,160 do H.step(c,.01) end
   c:relocate(a,V.new(0,3,9));c:relocate(b,V.new(0,3,-9));a.reaction=nil;b.reaction=nil
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
   assert(ok,id.." "..spec.Id.." refused: "..tostring(why))
   if spec.Family=="Counter" then
    H.step(c,spec.Channel+.06)
    c:request(b,"Attack")
   end
   for _=1,220 do H.step(c,.01) end
   local touched=b.health<health or b.reaction~=nil or (b.sealedUntil or 0)>c.now or (a.buffs and next(a.buffs)~=nil)
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
