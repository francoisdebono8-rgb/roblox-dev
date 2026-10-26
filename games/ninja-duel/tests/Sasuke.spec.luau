-- Fourth playable prototype: Sasuke (12). Lion Kick into Shadow of the
-- Dancing Leaf and the Lion Combo, the vault kick, Wire Trap into Dragon
-- Flame, Chidori (and its punishable miss), the curse mark, hidden blades in
-- the Phoenix Flower, and AI duels against every prodigy.
local H=require("./Harness")
local V=H.V
local AI=H.load("Server/AI")
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
local function chain(c,a)
 until_(c,.8,function() return a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt end,"the chain never opened")
end
local function slot(a,id) for i,t in a.def.Techniques do if t.Id==id then return "Technique"..i end end end

test("Lion Kick: two hits + toward launches, he follows into the air, heavy is the Lion Combo",function()
 local c,a,b=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,"Attack"));chain(c,a)
 assert(c:request(a,"Attack"));chain(c,a)
 a.move=a.root.CFrame.LookVector
 assert(c:request(a,"Attack"))
 a.move=V.zero
 assert(a.attackName=="LionKick","forward picked "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Launched" end,"the rising kick did not launch")
 until_(c,.6,function() return (a.events or {}).ShadowLeaf end,"no Shadow of the Dancing Leaf")
 until_(c,1,function() return a.state~="Pursuit" end,"the chase never arrived")
 assert(a.airborne and (a.lionUntil or 0)>c.now,"Sasuke is not in the air with the body")
 local gap=(a.root.Position-b.root.Position).Magnitude
 assert(gap<6,"Shadow Leaf left him "..string.format("%.1f",gap).." studs away")
 local health=b.health
 assert(c:request(a,"Heavy"),"Lion Combo refused")
 assert(a.attackVariant=="LionBarrage","the air heavy was not the Lion Combo")
 until_(c,1.2,function() return b.health<health end,"the Lion Combo never landed")
 assert(health-b.health>=12,"the Lion Combo was light ("..string.format("%.1f",health-b.health)..")")
end)

test("vault kick: sideways inside a string crosses to the other side",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,2.6),V.new(0,3,-2.6))
 assert(c:request(a,"Attack"));chain(c,a)
 local before=a.root.Position-b.root.Position
 a.move=a.root.CFrame.RightVector
 assert(c:request(a,"Attack"))
 assert(a.attackName=="VaultKick","side picked "..tostring(a.attackName))
 a.move=V.zero
 H.step(c,.35)
 local after=a.root.Position-b.root.Position
 local turned=math.deg(math.acos(math.clamp(V.new(before.X,0,before.Z).Unit:Dot(V.new(after.X,0,after.Z).Unit),-1,1)))
 assert(turned>100,"the vault turned only "..string.format("%.0f",turned).." degrees around the opponent")
end)

test("Wire Trap binds; Great Fireball on the wired body is the Dragon Flame",function()
 local c,a,b=H.duel("Lion","GentleFist")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8))
 assert(c:request(a,slot(a,"WireTrap"),b.root.Position),"Wire Trap refused")
 local wire
 until_(c,.6,function() for _,p in c.projectiles do if p.kind=="wire" then wire=p end end return wire~=nil end,"no wire thrown")
 until_(c,.6,function() return b.reaction=="Bound" or wire.dead or not table.find(c.projectiles,wire) end,"the wire never arrived")
 if b.reaction~="Bound" then c:projectileHit(wire,b,b.root.Position,-wire.direction) end
 assert(b.reaction=="Bound" and a.wireVictim==b,"the wire did not bind")
 H.step(c,.35)
 local health=b.health
 assert(c:request(a,slot(a,"FireBloom"),b.root.Position),"Dragon Flame refused")
 until_(c,1,function() return b.health<health end,"the Dragon Flame never burned")
 for _,p in c.projectiles do assert(p.kind~="fireball","the wired fire still flew as a fireball") end
 assert(health-b.health>=10,"the Dragon Flame was light")
end)

test("Chidori: formed, held in the hand, released by the strike; it lands hard from range; a miss leaves him open",function()
 local c,a,b=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,7),V.new(0,3,-7))
 local health=b.health
 assert(c:request(a,slot(a,"Chidori"),b.root.Position),"Chidori refused")
 assert(a.state=="TechniqueChannel","no charge")
 -- (Embodiment) The charge forms it; it stays in the hand, nothing is thrown yet.
 until_(c,1.2,function() return a.bodyState~=nil end,"the Chidori was never held")
 H.step(c,.3)
 assert(a.attackName~="ChidoriThrust","the held Chidori threw itself")
 assert(c:request(a,"Attack"),"the strike does not release it")
 until_(c,1.2,function() return a.attackName=="ChidoriThrust" end,"the thrust never started")
 until_(c,.8,function() return b.health<health end,"the Chidori never landed")
 assert(health-b.health>=18,"the Chidori was light ("..string.format("%.1f",health-b.health)..")")
 assert(b.reaction=="Knockback","the Chidori did not throw the body")
 -- The miss: nobody in front.
 local c2,x,y=H.duel("Lion","Mirage")
 place(c2,x,y,V.new(0,3,7),V.new(0,3,-7))
 c2:relocate(y,V.new(40,3,-7))
 assert(c2:request(x,slot(x,"Chidori"),V.new(0,3,-7)))
 until_(c2,1.2,function() return x.bodyState~=nil end,"the Chidori was never held")
 assert(c2:request(x,"Attack"))
 until_(c2,1.2,function() return x.attackName=="ChidoriThrust" end,"the thrust never started")
 until_(c2,.8,function() return x.state=="Recovery" end,"no recovery after the miss")
 local open=0
 for _=1,100 do if x.state=="Recovery" then open+=.01 end H.step(c2,.01) end
 assert(open>=.45,"a missed Chidori recovered in "..string.format("%.2f",open).."s")
end)

test("curse mark: faster and harder, and it eats his health (never to a KO)",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
 a.health=a.def.Health*.3
 assert(c:request(a,"Awaken"),"curse mark refused")
 local before=a.health
 H.step(c,2)
 assert(a.health<before-1.5,"the curse mark did not drain ("..string.format("%.1f",before-a.health)..")")
 a.health=1.4
 H.step(c,2)
 assert(a.health>=1,"the curse mark killed him")
 assert(a.speedScale>1,"the curse mark did not speed him up")
end)

test("Phoenix Flower hides two shuriken in the flames",function()
 local c,a,b=H.duel("Lion","Flashstep")
 place(c,a,b,V.new(0,3,16),V.new(0,3,-16))
 assert(c:request(a,slot(a,"PhoenixFlower"),b.root.Position))
 local blades,flames=0,0
 local seen={}
 for _=1,120 do
  H.step(c,.01)
  for _,p in c.projectiles do
   if p.a==a and not seen[p] then seen[p]=true;if p.kind=="shuriken" then blades+=1 elseif p.kind=="phoenix" then flames+=1 end end
  end
 end
 assert(flames==5,"flames: "..flames)
 assert(blades==2,"hidden blades: "..blades)
end)

test("AI duels: Sasuke against every prodigy, both ways, without wedging",function()
 for _,pair in {{"Lion","Flashstep"},{"Flashstep","Lion"},{"Lion","Mirage"},{"Mirage","Lion"},{"Lion","GentleFist"},{"GentleFist","Lion"},{"Lion","Lion"}} do
  local c,a,b,match=H.duel(pair[1],pair[2])
  place(c,a,b,V.new(0,3,12),V.new(0,3,-12))
  local one,two=AI.new(c,a,7),AI.new(c,b,11)
  local stuck={}
  local dealt={[a]=0,[b]=0}
  for _=1,1500 do
   if match.phase~="Duel" then break end
   local ha,hb=a.health,b.health
   one:update(c.now);two:update(c.now)
   H.step(c,.01)
   dealt[a]+=math.max(0,hb-b.health);dealt[b]+=math.max(0,ha-a.health)
   for _,x in {a,b} do
    if x.state=="Neutral" then stuck[x]=0 else stuck[x]=(stuck[x] or 0)+.01 end
    assert(stuck[x]<4,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
   end
  end
  print(string.format("  %s vs %s: dealt %.0f / %.0f",pair[1],pair[2],dealt[a],dealt[b]))
 end
end)

print("NinjaDuel Sasuke prototype: "..passed.." PASS")
