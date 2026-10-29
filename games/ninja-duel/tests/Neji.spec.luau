-- Third prototype: Neji Hyuga. Gentle Fist chakra damage, Byakugan sight,
-- Rotation, Vacuum Palm, Sixty-Four Palms, his combo branches and AI duels
-- against both other prodigies.
local H=require("./Harness")
local V=H.V
local AI=H.load("Server/AI")
local Brawler=H.load("Server/Brawler")
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
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return end
 end
 error(message)
end

test("Gentle Fist: palms drain chakra through a guard and close chakra points",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 local chakra=b.chakra
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return b.health<b.def.Health end,"the palm never landed")
 assert(b.chakra<chakra-4,"a clean palm did not drain chakra")
 assert(b.tenketsu==1 and b.tenketsuUntil>c.now,"no chakra point closed")
 -- Closed points slow the recovery.
 b.chakra=10;local before=b.chakra;H.step(c,1)
 local slowed=b.chakra-before
 assert(slowed<b.def.ChakraRegen*.9,"recovery not slowed ("..slowed..")")
 -- Through a guard: chakra still drains, no point closes.
 local c2,x,y=H.duel("GentleFist","Mirage")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c2:request(y,"Guard"));H.step(c2,.3)
 local guardChakra=y.chakra
 assert(c2:request(x,"Attack"))
 H.step(c2,.3)
 assert(y.impactStyle=="block","the palm was not guarded")
 assert(y.chakra<guardChakra,"a guarded palm did not drain chakra")
 assert((y.tenketsu or 0)==0,"a guarded palm closed a chakra point")
end)

test("Byakugan: the guard covers the sides, not the blind spot behind",function()
 local c,a,b=H.duel("Flashstep","GentleFist")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 -- Neji looks away to the side; his guard still meets a strike from his flank.
 b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.xAxis)
 assert(c:request(b,"Guard"));H.step(c,.3)
 assert(c:request(a,"Attack"))
 H.step(c,.3)
 assert(b.impactStyle=="block","a flank strike crossed the Byakugan guard")
 -- Straight behind is the blind spot.
 local c2,x,y=H.duel("Flashstep","GentleFist")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 y.root.CFrame=H.C.lookAt(y.root.Position,y.root.Position-V.zAxis)
 assert(c2:request(y,"Guard"));H.step(c2,.3)
 assert(c2:request(x,"Attack"))
 until_(c2,.4,function() return y.health<y.def.Health end,"the blind-spot strike never landed")
 assert(y.impactStyle~="block","the blind spot was guarded")
end)

test("Rotation repels a strike, deflects blades and opens the palm-thrust counter",function()
 local c,a,b=H.duel("Flashstep","GentleFist")
 place(c,a,b,V.new(0,3,3),V.new(0,3,-3))
 c:projectile(a,b.root.Position,40,30,3,"kunai")
 assert(c:request(a,"Attack"))
 assert(c:request(b,H.slot(b,"Rotation")),"Rotation refused")
 until_(c,.6,function() return (b.events.Repel or 0)>0 end,"the strike was not repelled")
 assert(b.health==b.def.Health,"Neji was hurt inside Rotation")
 -- A turned-aside strike staggers out of the dome, within the counter's reach
 -- (a body only standing in the dome is still thrown out: Identity.spec).
 assert(a.reaction=="HitStun","the attacker did not stagger out of the dome ("..tostring(a.reaction)..")")
 H.step(c,.3)
 assert((b.events.Deflect or 0)>=1 or #c.projectiles==0,"the kunai was not deflected")
 until_(c,1,function() return b.state=="Neutral" end,"Rotation never recovered")
 assert((b.counterUntil or 0)>c.now,"no counter window after the repel")
 place(c,b,a,b.root.Position,b.root.Position-V.zAxis*3)
 a.reaction=nil;a.state="Neutral";a.invulnerableUntil=0
 assert(c:request(b,"Attack"))
 assert(b.attackName=="PalmThrust","the counter is not the palm thrust ("..tostring(b.attackName)..")")
end)

test("Vacuum Palm carries the opponent into a wall",function()
 local c,a,b=H.duel("GentleFist","Flashstep")
 H.addWall(20)
 place(c,a,b,V.new(-6,3,0),V.new(6,3,0))
 assert(c:request(a,H.slot(a,"VacuumPalm"),b.root.Position))
 local carried=false
 for _=1,120 do
  H.step(c,.01)
  for _,p in c.projectiles do
   if p.kind=="palm" and (p.position-b.root.Position).Magnitude<2.5 then c:projectileHit(p,b,b.root.Position,-V.xAxis);p.dead=true end
  end
  if b.reaction=="WallSplat" then carried=true;break end
 end
 assert(carried,"the palm did not carry the body into the wall ("..tostring(b.reaction)..")")
end)

test("Sixty-Four Palms: the flurry seals techniques, a substitution escapes it",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,2),V.new(0,3,-2))
 assert(c:request(a,H.slot(a,"SixtyFourPalms")),"64 Palms refused")
 until_(c,2.2,function() return (b.sealedUntil or 0)>c.now end,"the flurry never finished")
 assert(b.tenketsu==a.def.GentleFist.MaxPoints,"the chakra points were not all closed")
 assert(b.reaction=="Knockback","the last palm did not throw the body")
 until_(c,1.5,function() return b.reaction==nil and b.state=="Neutral" end,"the sealed fighter never recovered")
 assert((b.sealedUntil or 0)>c.now,"the seal ended before the fighter could act")
 local ok,reason=c:request(b,H.slot(b,"NeedleFan"),a.root.Position)
 assert(not ok and reason=="Chakra points sealed","a sealed fighter cast a technique ("..tostring(reason)..")")
 -- Escape: substitution out of the flurry stops the remaining palms.
 local c2,x,y=H.duel("GentleFist","Flashstep")
 place(c2,x,y,V.new(0,3,2),V.new(0,3,-2))
 assert(c2:request(x,H.slot(x,"SixtyFourPalms")))
 until_(c2,.6,function() return y.reaction=="HitStun" and y.flurriedBy==x end,"the flurry never locked")
 assert(c2:request(y,"Substitute"),"no substitution out of the flurry")
 H.step(c2,1.5)
 assert((y.sealedUntil or 0)<=c2.now,"the flurry finished after the escape")
 -- Whiff: nothing in reach, a long recovery.
 local c3,m,n=H.duel("GentleFist","Mirage")
 place(c3,m,n,V.new(0,3,10),V.new(0,3,-10))
 assert(c3:request(m,H.slot(m,"SixtyFourPalms")))
 H.step(c3,.45)
 assert(m.state=="TechniqueRecovery" or m.state=="TechniqueActive","missed palms skipped their recovery ("..m.state..")")
end)

test("Heavy after one clean palm is the twin-palm thrust",function()
 local c,a,b=H.duel("GentleFist","Flashstep")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,"Attack"))
 for _=1,80 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt then break end end
 assert(a.chainOpen,"the first palm did not open the string")
 assert(c:request(a,"Heavy"))
 assert(a.attackName=="PalmThrust","heavy after one palm is "..tostring(a.attackName))
 until_(c,.5,function() return b.reaction=="Knockback" end,"the thrust did not knock back")
end)

test("the Byakugan sees through Itachi's genjutsu",function()
 local c,a,b=H.duel("Mirage","GentleFist")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8))
 assert(c:request(a,H.slot(a,"MirageCast")),"Mirage refused")
 H.step(c,1.2)
 assert(b.illusionUntil<=c.now and b.decoyPosition==nil,"the decoy fooled the Byakugan")
end)

test("AI duels: Neji against both prodigies, both ways, without wedging",function()
 for _,pair in {{"GentleFist","Flashstep"},{"Flashstep","GentleFist"},{"GentleFist","Mirage"},{"Mirage","GentleFist"},{"GentleFist","GentleFist"}} do
  local c,a,b,match=H.duel(pair[1],pair[2])
  place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
  local one,two=AI.new(c,a,7),AI.new(c,b,11)
  local stuck={}
  for _=1,1500 do
   if match.phase~="Duel" then break end
   one:update(c.now);two:update(c.now)
   H.step(c,.01)
   for _,x in {a,b} do
    if x.state=="Neutral" then stuck[x]=0 else stuck[x]=(stuck[x] or 0)+.01 end
    assert(stuck[x]<4,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
   end
  end
 end
end)

print("NinjaDuel Neji prototype: "..passed.." PASS")
