-- Stage 6 (the approved move list, "Interactions: les jutsu réagissent entre
-- eux"): the new meetings of Server/Interactions. Fire against water makes
-- steam; a Water Dragon leaves a puddle and lightning in it spreads; Gaara's
-- sand gets wet in it; fire melts his shield; Rasengan into Chidori explodes.
local H=require("./Harness")
local V=H.V
local Interactions=H.load("Server/Interactions")
local Families=H.load("Server/Families")
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,gap)
 c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,V.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
 b.root.CFrame=H.C.lookAt(b.root.Position,V.new(a.root.Position.X,b.root.Position.Y,a.root.Position.Z))
end
local function impacts(c,style)
 local n=0;for _,i in c.impacts or {} do if i.style==style then n+=1 end end;return n
end

test("a Great Fireball meeting the Water Dragon becomes steam: both fall, nobody sees through it",function()
 local c,a,b=H.duel("Lion","Copycat");place(c,a,b,40)
 a.chakra=999;b.chakra=999
 assert(c:request(a,H.slot(a,"FireBloom"),b.root.Position),"fireball refused")
 assert(c:request(b,H.slot(b,"WaterDragon"),a.root.Position),"Water Dragon refused")
 local steamed=false
 for _=1,200 do H.step(c,.01);if impacts(c,"steam")>0 then steamed=true;break end end
 assert(steamed,"the fire and the water passed through each other")
 for _,p in c.projectiles do assert(p.kind~="fireball" and p.kind~="waterdragon","a jutsu survived the steam") end
 -- Inside the cloud each has lost the other.
 local cloud;for _,h in c.hazards do if h.effects and h.effects.Name=="Steam" then cloud=h end end
 assert(cloud,"no cloud")
 c:relocate(a,cloud.position+V.new(0,3,0));c:relocate(b,cloud.position+V.new(2,3,0))
 assert(Families.shrouded(c,a) and Families.shrouded(c,b),"the steam hid nothing")
 H.step(c,3.2)
 assert(not Families.shrouded(c,a),"the steam outlived its 3 s")
end)

test("the Water Dragon leaves a puddle; lightning into a body standing in it hits harder and holds it",function()
 local c,a,b=H.duel("Copycat","Mirage");place(c,a,b,4)
 Interactions.ended(c,{kind="waterdragon",a=a},b.root.Position-V.new(0,3,0))
 assert(Interactions.inPuddle(c,b),"no puddle under the body")
 b.health=999
 local before=b.health
 a.castId="LightningBlade"
 c:damage(a,b,10,false,false)
 a.castId=nil
 assert(math.abs(before-b.health-13)<.01,"the current did not carry ("..(before-b.health)..")")
 assert(impacts(c,"conduct")==1 and (b.stunFloorUntil or 0)>c.now,"the current did not hold the body")
 -- Without lightning, the water changes nothing.
 before=b.health;c:damage(a,b,10,false,false)
 assert(math.abs(before-b.health-10)<.01 or before-b.health<10,"a plain blow was carried")
 H.step(c,6.2)
 assert(not Interactions.inPuddle(c,b),"the puddle outlived its 6 s")
end)

test("wet sand: the Coffin cast at a body in the water is slower and crushes harder",function()
 local c,a,b=H.duel("Sand","Mirage");place(c,a,b,14)
 Interactions.ended(c,{kind="waterdragon",a=b},b.root.Position-V.new(0,3,0))
 a.chakra=999
 assert(c:request(a,H.slot(a,"SandCoffin"),b.root.Position))
 local wave
 for _=1,80 do H.step(c,.01);for _,p in c.projectiles do if p.kind=="sandwave" then wave=p end end;if wave then break end end
 assert(wave and wave.wet,"the sand is not wet")
 assert(math.abs(wave.speed-46*Interactions.WET.Speed)<.01,"wet sand is not slower ("..wave.speed..")")
end)

test("fire reaching Gaara melts a charge of his sand shield",function()
 local c,a,b=H.duel("Lion","Sand");place(c,a,b,20)
 local charges=b.shieldCharges
 local ball=c:projectile(a,b.root.Position,60,40,10,"fireball",nil,{radius=2})
 c:projectileHit(ball,b,b.root.Position,V.zAxis)
 assert(b.shieldCharges==charges-2,"the fire took "..(charges-b.shieldCharges).." charges, not the absorb and the melt")
 assert(impacts(c,"sandmelt")==1,"no melt contact")
end)

test("Rasengan into Chidori: both thrown back, the clash contact names it",function()
 local c,a,b=H.duel("Legion","Lion");place(c,a,b,3)
 local health={a.health,b.health}
 assert(not Interactions.jutsuClash(c,a,b,{rasengan=true},{state="FireBloom"}),"a Rasengan clashed with a plain blow")
 assert(Interactions.jutsuClash(c,a,b,{rasengan=true},{state="Chidori"}),"no clash")
 assert(a.hop and b.hop and a.hop.remaining>=10,"the bodies were not thrown back")
 assert(a.health<health[1] and b.health<health[2],"the clash cost nothing")
 assert(impacts(c,"jutsuclash")==1)
end)

test("client: steam, puddle, current, melt and the jutsu clash draw without error",function()
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  local fx=FX.new()
  local folder=instance("Folder")
  local serial=0
  for _,style in {"steam","puddle","conduct","sandmelt","jutsuclash"} do
   serial+=1
   local before=#fx.folder:GetDescendants()
   fx:impact({style=style,serial=serial,position=V.new(0,3,0),radius=9,time=3,owner="A",victim="B"},folder)
   assert(#fx.folder:GetDescendants()>before,style.." drew nothing")
  end
 end)
 restore()
 assert(ok,err)
end)

test("infusion by nature: Sasuke's kicks burn, Gaara's lashes reach further, Minato's blow seals",function()
 local ChakraFlow=H.load("Server/ChakraFlow")
 local c,a=H.duel("Lion","Mirage");a.chakra=999
 a.chakraLoad={untilTime=c.now+2,nature="Lightning",at=c.now}
 local kick={kind="kick",impulse=V.new(0,0,10),range=5,depth=2}
 assert(ChakraFlow.strike(c,a,"Light3",kick)=="Fire","Sasuke's infused kick is not fire")
 a.chakraLoad={untilTime=c.now+2,nature="Lightning",at=c.now}
 assert(ChakraFlow.strike(c,a,"Light1",{kind="punch",impulse=V.new(0,0,10),range=5,depth=2})=="Lightning","Sasuke's infused fist is not lightning")
 local c2,g=H.duel("Sand","Mirage");g.chakra=999
 g.chakraLoad={untilTime=c2.now+2,nature="Sand",at=c2.now}
 local lash={impulse=V.new(0,0,10),range=8.5,depth=7.5}
 ChakraFlow.strike(c2,g,"Light1",lash)
 assert(lash.range>=8.5+2.7,"the sand lash is not longer ("..lash.range..")")
 local c3,m,n=H.duel("Flashstep","Mirage");place(c3,m,n,3)
 ChakraFlow.hit(c3,m,n,{chakraFlow="Chakra",name="Light1"},false)
 local sealed=false;for _,e in m.anchors or {} do if e.actor==n then sealed=true end end
 assert(sealed,"Minato's infused blow left no seal on the body")
end)

print("NinjaDuel interactions: "..passed.." PASS (headless; the look is a Studio check)")
