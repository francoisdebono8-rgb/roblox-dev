-- (06/11) Kakashi's Sharingan copy (Server/Copy): a jutsu cast in front of him
-- takes his first slot for 15 s or one cast and he casts it as its owner does;
-- not from behind (unless uncovered), not a Hyuga's, not the Rasengan; a
-- copied crowd is ten Kakashis, and the key again takes one of their bodies.
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

print("NinjaDuel Kakashi copy: "..passed.." PASS")
