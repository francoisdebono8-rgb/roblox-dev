-- Shared ninja tools: every fighter throws; mastery changes what a throw can
-- do (Itachi's pair, Shuriken Geometry into the flank, ricochets, air fans).
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
local function thrown(c,a)
 local n=0
 for _,p in c.projectiles do if p.a==a then n+=1 end end
 return n
end

test("shared tools: every fighter throws; the count and blade follow mastery",function()
 for id,expect in {Flashstep={1,"kunai"},Mirage={2,"shuriken"},GentleFist={1,"kunai"}} do
  local c,a,b=H.duel(id,"Flashstep")
  place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
  assert(c:request(a,"Tool",b.root.Position),id.." could not throw")
  local most,kind=0,nil
  for _=1,30 do H.step(c,.01);local n=thrown(c,a);if n>most then most=n end;for _,p in c.projectiles do if p.a==a then kind=p.kind end end end
  assert(most==expect[1],id.." threw "..most.." blades, expected "..expect[1])
  assert(kind==expect[2],id.." threw "..tostring(kind))
 end
end)

test("Shuriken Geometry: side + tool strikes a wide blade into the flank, past a frontal guard",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
 assert(c:request(b,"Guard"));H.step(c,.3)
 a.move=a.root.CFrame.RightVector
 assert(c:request(a,"Tool",b.root.Position),"geometry refused")
 a.move=V.zero
 local redirected
 for _=1,120 do
  H.step(c,.01)
  for _,p in c.projectiles do if p.a==a and p.bounced then redirected=p end end
  if redirected then break end
 end
 assert(redirected,"the blades never met and turned")
 assert((a.events or {}).GeometryHit,"no geometry collision event")
 -- The turned blade comes from the side: the frontal guard does not cover it.
 local health=b.health
 c:projectileHit(redirected,b,b.root.Position,-redirected.direction)
 assert(b.health<health,"the flank blade did no damage")
 assert(b.impactStyle~="block","a frontal guard stopped a blade from the flank")
 -- The same shuriken thrown straight in is blocked.
 local c2,x,y=H.duel("Mirage","Flashstep")
 place(c2,x,y,V.new(0,3,14),V.new(0,3,-14))
 assert(c2:request(y,"Guard"));H.step(c2,.3)
 local straight=c2:projectile(x,y.root.Position,84,40,2,"shuriken")
 straight.position=y.root.Position+(x.root.Position-y.root.Position).Unit*3
 c2:projectileHit(straight,y,y.root.Position,-straight.direction)
 assert(y.impactStyle=="block","a straight shuriken went through a frontal guard")
end)

test("ricochet: Itachi's shuriken bounces off a wall at the opponent; Minato's kunai does not",function()
 for id,expect in {Mirage=true,Flashstep=false} do
  local c,a,b=H.duel(id,"GentleFist")
  place(c,a,b,V.new(0,3,0),V.new(4,3,-10))
  H.addWall(9)
  assert(c:request(a,"Tool",V.new(14,4,0)),id.." could not throw")
  local bounced=false
  for _=1,80 do H.step(c,.01);for _,p in c.projectiles do if p.a==a and p.bounced then bounced=true end end end
  assert(bounced==expect,id..(if expect then " never ricocheted" else " ricocheted"))
  H.clearWalls()
 end
end)

test("air fan: Itachi throws three blades from the air",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,10),V.new(0,3,-10))
 c:relocate(a,a.root.Position+V.new(0,8,0));a.airborne=true;a.airHold=c.now+1
 assert(c:request(a,"Tool",b.root.Position),"air throw refused")
 local most=0
 for _=1,40 do H.step(c,.01);most=math.max(most,thrown(c,a)) end
 assert(most==3,"the air fan threw "..most)
end)

print("NinjaDuel shared tools: "..passed.." PASS")
