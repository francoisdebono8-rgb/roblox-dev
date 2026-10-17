-- DEC-021, first convergence block: the transversal contracts every fighter
-- relies on, written to fail on the defects Codex reproduced at de33f3d
-- (docs/archive/audits/2026-10-17-roster20):
--   lifecycle   no temporary state of a round survives into the next one
--               (buff, counter stance, slow, poison, windows), on the real
--               Matches.resetRound and on Combat:clear (result, rematch, leave);
--   composition a technique's buff and the awakening's merge (Heavy/Armor kept,
--               multipliers capped), on-hit riders merge field by field;
--   reach       a targeted relocation respects its Range and the line of
--               sight, refused before any cost.
local H=require("./Harness")
local V=H.V
local F=H.load("Server/Families")
local M=H.load("Server/Matches")
local Fighters=H.fighters
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function step(c,t) for _=1,math.ceil(t/.01) do H.step(c,.01) end end
local function place(c,a,b,pa,pb)
 c:relocate(a,pa);c:relocate(b,pb)
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 a.move=V.zero;b.move=V.zero
end
local function specOf(id,tech)
 for i,spec in Fighters[id].Techniques do if spec.Id==tech then return "Technique"..i,spec end end
 error(id.." has no "..tech)
end
local function slot(id,tech) return (specOf(id,tech)) end

test("lifecycle: a buff, a stance, a slow and a dose of poison end with the round (real resetRound)",function()
 local c,a,b,s=H.duel("Bone","Leaf")
 a.chakra=999
 assert(c:request(a,slot("Bone","Camellia")));step(c,.4)
 assert(F.buff(a,c.now),"Camellia did not start")
 -- The opponent carries a slow, a poison already ticking and a counter stance.
 b.slowUntil=c.now+20;b.slowScale=.5
 F.poison(c,a,b,{Damage=2,Time=10,Every=.5})
 b.counterStance={untilT=c.now+20,spec={Id="X",Name="X"}}
 s.combat=c;s.epoch=1;s.round=1
 M.resetRound({},s)
 local hp=b.health
 step(c,1.6)
 assert(F.buff(a,c.now)==nil,"the buff survived into the next round")
 assert(math.abs(F.damageScale(a,b,c.now)-1)<1e-6,"damage scale still raised: "..F.damageScale(a,b,c.now))
 assert(b.counterStance==nil,"the counter stance survived")
 assert(F.speedScale(b,c.now)==1,"the slow survived")
 assert(b.health==hp,"the old poison kept ticking in the new round")
end)

test("lifecycle: Combat:clear (result screen, rematch, a player who leaves) ends every temporary state",function()
 local c,a,b=H.duel("Medic","Leaf")
 a.chakra=999
 assert(c:request(a,slot("Medic","ChakraScalpel")));step(c,.4)
 b.slowUntil=c.now+20;b.sealedUntil=c.now+20;b.poisonedUntil=c.now+20
 c:clear(true)
 assert(a.buff==nil and F.onHit(a,c.now)==nil,"the scalpel survived Combat:clear")
 for _,key in {"slowUntil","sealedUntil","poisonedUntil"} do assert((b[key] or 0)<=c.now,key.." survived Combat:clear") end
end)

test("composition: a buff inside the awakening keeps the awakening's Heavy and Armor (Kimimaro)",function()
 local c,a,b=H.duel("Bone","Leaf")
 a.chakra=999
 a.health=a.def.Health*.2
 assert(c:request(a,"Awaken"));step(c,.5)
 assert(c:request(a,slot("Bone","Camellia")));step(c,.5)
 local t=F.buff(a,c.now)
 assert(t and t.Heavy==true,"Camellia hid the awakening's super armour")
 assert(t.Armor and math.abs(t.Armor-.3)<1e-6,"armour is "..tostring(t.Armor).." (expected the larger layer, .3)")
 assert(t.Damage and t.Damage>1.2,"the Camellia's bite was lost")
 -- Bounded: buff × awakening never past the cap.
 local total=F.damageScale(a,b,c.now)*(a.def.Awakening.Damage or 1)
 assert(total<=F.CAP.Damage+1e-6,"outgoing scale "..total.." passed the cap")
end)

test("composition: on-hit riders merge field by field (Kabuto keeps the scalpel's drain in his awakening)",function()
 local c,a,b=H.duel("Medic","Leaf")
 a.chakra=999
 a.health=a.def.Health*.2
 assert(c:request(a,"Awaken"));step(c,.5)
 assert(c:request(a,slot("Medic","ChakraScalpel")));step(c,.5)
 local r=F.onHit(a,c.now)
 assert(r and r.Drain,"the scalpel's drain was erased by the awakening")
 assert(r.Slow and r.Slow.Scale<=.72,"the stronger slow did not win")
 place(c,a,b,V.new(0,3,1.7),V.new(0,3,-1.7));b.health=999;b.chakra=50
 assert(c:request(a,"Attack"));step(c,.3)
 assert(b.chakra<50 and (b.slowUntil or 0)>c.now,"a blow did not both drain and slow")
end)

test("reach: a targeted relocation respects Range and sight, refused before any cost",function()
 for _,pair in {{"Flicker","BodyFlicker"},{"Mirror","MirrorStep"},{"Mist","SilentKilling"}} do
  local id,tech=pair[1],pair[2]
  local s,spec=specOf(id,tech)
  -- Far out of range: refused, nothing spent, nothing moved.
  local c,a,b=H.duel(id,"Leaf");place(c,a,b,V.new(0,3,60),V.new(0,3,-60));a.chakra=100
  local from=a.root.Position
  local ok,why=c:request(a,s,b.root.Position)
  assert(not ok and why=="Out of range",id..": "..tech.." accepted at 120 studs ("..tostring(why)..")")
  assert(a.chakra==100 and (a.cooldowns[spec.Id] or 0)<=c.now,id..": a refused relocation still cost")
  step(c,.3);assert((a.root.Position-from).Magnitude<1,id..": moved anyway")
  -- At the edge: accepted.
  local c2,a2,b2=H.duel(id,"Leaf");local half=(spec.Range-.5)/2
  place(c2,a2,b2,V.new(0,3,half),V.new(0,3,-half));a2.chakra=100
  assert(c2:request(a2,s,b2.root.Position),id..": refused at its edge")
  -- Behind a wall: refused.
  local c3,a3,b3=H.duel(id,"Leaf");place(c3,a3,b3,V.new(-6,3,0),V.new(6,3,0));a3.chakra=100
  H.addWall(0)
  local ok3,why3=c3:request(a3,s,b3.root.Position)
  assert(not ok3 and why3=="No line of sight",id..": blinked through a wall ("..tostring(why3)..")")
  H.clearWalls()
 end
 -- A step back needs no target in range.
 local c,a,b=H.duel("Flicker","Leaf");place(c,a,b,V.new(0,3,60),V.new(0,3,-60));a.chakra=100
 assert(c:request(a,slot("Flicker","FlickerOut")),"the retreat was refused far away")
end)

print(string.format("NinjaDuel convergence (lifecycle, composition, reach): %d PASS (headless)",passed))
