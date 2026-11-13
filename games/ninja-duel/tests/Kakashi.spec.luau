-- (06/11) Kakashi's Sharingan copy (Server/Copy): a jutsu cast in front of him
-- takes his first slot for 15 s or one cast and he casts it as its owner does;
-- not from behind (unless uncovered), not a Hyuga's, not the Rasengan; a
-- copied crowd is ten Kakashis, and the key again takes one of their bodies.
-- His ninken (Server/Hounds): a pack that digs to the legs and holds.
-- Headless: rules and state. The red read on screen needs native Studio.
local H=require("./Harness")
local V=H.V
local Bodies=H.load("Server/Bodies")
local Copy=H.load("Server/Copy")
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
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
 b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
 a.move=V.zero;b.move=V.zero
end
local function slot(x,id) for i,t in x.def.Techniques do if t.Id==id then return "Technique"..i end end error("no technique "..id) end
local function settle(c,x) for _=1,300 do if x.state=="Neutral" and not x.reaction then return end H.step(c,.01) end error("never back to neutral ("..tostring(x.state)..")") end

test("a jutsu cast in front of Kakashi is his next: cast once as its owner does, then the slot is his own again",function()
 local c,k,b=H.duel("Copycat","Mirage");place(c,k,b,14)
 assert(c:request(b,slot(b,"FireBloom"),k.root.Position),"Itachi's fireball refused")
 assert(k.copy and k.copy.spec.Id=="FireBloom","Kakashi did not copy the fireball")
 assert(Copy.slotSpec(c,k,1).Id=="FireBloom","the copy is not in his first slot")
 local copyImpacts=0
 for _,impact in c.impacts do if impact.style=="copy" then copyImpacts+=1 end end
 assert(copyImpacts==1,"the read was not in the feed")
 H.step(c,1.2);settle(c,k)
 assert(c:request(k,"Technique1",b.root.Position),"Kakashi's copied fireball refused")
 assert((k.cooldowns.FireBloom or 0)>c.now,"the copied cast did not run as the fireball")
 assert(k.copy.uses==0,"the copy was not spent")
 assert(Copy.slotSpec(c,k,1)==nil,"the slot did not come back to the Water Dragon")
 assert(k.def.Techniques[1].Id=="WaterDragon","his own kit changed")
end)

test("a held Great Fireball is copied as big as he saw it: his tap throws it back that size, his hold gathers more (13/11, #72)",function()
 local DevHooks=H.load("Server/DevHooks")
 local function ball(c,x)
  for _=1,200 do
   H.step(c,.01)
   for _,p in c.projectiles do if p.a==x and p.kind=="fireball" then return p end end
  end
  error("no fireball from "..x.def.Name)
 end
 -- The first ball lands (or flies off) before the other one answers.
 local function gone(c,p)
  for _=1,400 do if not table.find(c.projectiles,p) then return end H.step(c,.01) end
  error("the fireball never ended")
 end
 -- Sasuke holds it full (the film seat's press: the key down 1.25 s).
 local c,k,s=H.duel("Copycat","Lion");place(c,k,s,16)
 assert(DevHooks.press(c,s,slot(s,"FireBloom"),k.root.Position,{hold=1.25}),"Sasuke's held fireball refused")
 local his=ball(c,s)
 assert(his.charge>=.99,"Sasuke's fireball was not held full ("..string.format("%.2f",his.charge)..")")
 assert(k.copy and k.copy.spec.Id=="FireBloom" and k.copy.spec.SeenCharge>=.99,"the eye did not keep what it saw gathered")
 gone(c,his);settle(c,k)
 -- Kakashi's tap: the same ball back.
 assert(DevHooks.press(c,k,"Technique1",s.root.Position),"Kakashi's copy refused")
 assert(not k.techHold.down,"a tap left the key held")
 local back=ball(c,k)
 assert(math.abs(back.charge-his.charge)<.01 and math.abs(back.radius-his.radius)<.01,
  string.format("the copy went %.2f / radius %.2f, Sasuke's was %.2f / %.2f",back.charge,back.radius,his.charge,his.radius))
 -- Seen half-gathered, Kakashi holds his key and gathers the rest himself.
 local c2,k2,s2=H.duel("Copycat","Lion");place(c2,k2,s2,16)
 assert(DevHooks.press(c2,s2,slot(s2,"FireBloom"),k2.root.Position,{hold=.6}))
 local half=ball(c2,s2)
 local seen=half.charge
 assert(seen>.1 and seen<.6 and math.abs(k2.copy.spec.SeenCharge-seen)<.01,"the half-gathered ball was not what the eye kept")
 gone(c2,half);settle(c2,k2)
 local chakra=k2.chakra
 assert(DevHooks.press(c2,k2,"Technique1",s2.root.Position,{hold=1.3}),"Kakashi's held copy refused")
 assert(ball(c2,k2).charge>=.99,"Kakashi could not hold the copy")
 assert(k2.chakra<chakra-k2.copy.spec.Cost,"holding the copy was free")
end)

test("not from behind (unless uncovered), not a Hyuga's, not the Rasengan",function()
 local c,k,b=H.duel("Copycat","Mirage");place(c,k,b,14)
 k.root.CFrame=H.C.lookAt(k.root.Position,k.root.Position+(k.root.Position-b.root.Position))
 assert(c:request(b,slot(b,"FireBloom"),k.root.Position),"fireball refused")
 assert(k.copy==nil,"a jutsu behind his back was copied")
 -- Uncovered, the eye reads it from any angle.
 local c2,k2,b2=H.duel("Copycat","Mirage");place(c2,k2,b2,14)
 k2.root.CFrame=H.C.lookAt(k2.root.Position,k2.root.Position+(k2.root.Position-b2.root.Position))
 k2.awakenUntil=c2.now+10
 assert(c2:request(b2,slot(b2,"FireBloom"),k2.root.Position),"fireball refused")
 assert(k2.copy and k2.copy.spec.Id=="FireBloom","uncovered, the eye did not read it from behind")
 -- A Hyuga's palm: kekkei genkai.
 local c3,k3,n=H.duel("Copycat","GentleFist");place(c3,k3,n,14)
 assert(c3:request(n,slot(n,"VacuumPalm"),k3.root.Position),"Vacuum Palm refused")
 assert(k3.copy==nil,"a Hyuga's jutsu was copied")
 -- The Rasengan: no seals to read.
 assert(not Copy.copyable({def={}},{Id="CloneRasengan"}),"the Rasengan is copyable")
end)

test("a copied Multi Shadow Clone is ten Kakashis, and the key again takes one of their bodies",function()
 local c,k,b=H.duel("Copycat","Legion");place(c,k,b,14)
 assert(c:request(b,slot(b,"MassShadowClone"),k.root.Position),"Naruto's crowd refused")
 assert(k.copy and k.copy.spec.Id=="MassShadowClone","the crowd was not copied")
 H.step(c,1.5);settle(c,k)
 k.chakra=k.def.Chakra
 assert(c:request(k,"Technique1",b.root.Position),"Kakashi's copied crowd refused")
 for _=1,100 do H.step(c,.01) end
 local mine=Bodies.crowd(c,k,"clone")
 assert(#mine==10,"Kakashi's crowd is not ten ("..#mine..")")
 settle(c,k)
 local before=k.root.Position
 assert(Copy.slotSpec(c,k,1).Id=="MassShadowClone","the slot let go of the crowd while it is out")
 assert(c:request(k,"Technique1",b.root.Position),"the body switch was refused")
 assert((k.root.Position-before).Magnitude>2,"Kakashi did not take a clone's body")
end)

test("Tracking Fang: four hounds dig to his legs (no blow reaches them there), burst out and hold him, then go",function()
 local c,k,b=H.duel("Copycat","Mirage");place(c,k,b,14)
 assert(c:request(k,slot(k,"TrackingFang"),b.root.Position),"Tracking Fang refused")
 local pack={}
 for _=1,40 do
  H.step(c,.01)
  pack={}
  for _,body in c.bodies or {} do if body.alive and body.kind=="hound" then table.insert(pack,body) end end
  if #pack>0 then break end
 end
 assert(#pack==4,"the pack is not four hounds ("..#pack..")")
 assert(pack[1].buried,"a hound digging is not under the floor")
 assert(Bodies.threat(c,b,40)==nil,"a buried hound can be struck")
 local held=false
 for _=1,150 do
  H.step(c,.01)
  if b.reaction=="Bound" and b.boundBy==k and b.boundKind=="houndpack" then held=true;break end
 end
 assert(held,"the hounds never held him")
 H.step(c,2.5)
 local left=0
 for _,body in c.bodies or {} do if body.alive and body.kind=="hound" then left+=1 end end
 assert(left==0,"hounds stayed after the hold ("..left..")")
end)

print("NinjaDuel Kakashi copy: "..passed.." PASS")
