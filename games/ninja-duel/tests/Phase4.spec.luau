-- Phase 4 combat depth: combo scaling and the combo limit, the recharging
-- substitution (seal escape, crow clone, tracking window), the wall loop
-- (splat, pin, bounce, tech, dive), clashes, context Rasengan, multi-seal
-- Flying Thunder God and the genjutsu read.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local Techniques=H.load("Server/Techniques")
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
-- Run until a condition holds (or fail with a message).
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return end
 end
 error(message)
end

test("combo scaling: later hits are worth less and the scale resets after the combo",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local dealt={}
 for i=1,5 do
  local before=b.health
  assert(c:damage(a,b,10,false,false),"hit "..i.." refused")
  dealt[i]=before-b.health
  H.step(c,.05)
 end
 assert(dealt[1]==10 and dealt[2]==10,"opening hits were scaled")
 assert(dealt[3]<dealt[2] and dealt[4]<dealt[3] and dealt[5]<dealt[4],"later hits were not scaled")
 assert(math.abs(dealt[3]-8.8)<.01,"third hit scale "..dealt[3])
 assert(b.comboHits==5)
 -- Free to act for a moment: the next hit starts a new, unscaled combo.
 H.step(c,.9)
 assert(b.comboHits==0,"combo counter never reset")
 local before=b.health
 c:damage(a,b,10,false,false)
 assert(before-b.health==10,"a fresh combo started scaled")
end)

test("a combo that runs too long drops the victim into a knockdown",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 b.comboHits=Config.ComboScaling.MaxHits-1
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return b.reaction~=nil end,"the light never connected")
 assert(b.reaction=="Knockdown","the combo limit did not end the combo ("..tostring(b.reaction)..")")
 assert((a.events.ComboLimit or 0)==1)
end)

test("substitution charges recharge one at a time and track the escape",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local tune=Config.Substitution
 assert(c:damage(a,b,5,false,false))
 local chakra=b.chakra
 assert(c:request(b,"Substitute"),"first substitution refused")
 assert(b.subCharges==1 and math.abs(chakra-b.chakra-tune.Cost)<.5,"charge or chakra not spent")
 assert(a.pursuitUntil>c.now,"the attacker got no tracking window")
 H.step(c,tune.Cooldown+.05)
 assert(c:damage(a,b,5,false,false))
 assert(c:request(b,"Substitute"),"second substitution refused")
 assert(b.subCharges==0)
 H.step(c,.3);assert(c:damage(a,b,5,false,false))
 assert(not c:request(b,"Substitute"),"substituted with no charge left")
 H.step(c,tune.Recharge-1.2)
 assert(b.subCharges==1,"the first charge did not come back ("..b.subCharges..")")
 H.step(c,tune.Recharge)
 assert(b.subCharges==2,"the second charge did not come back")
 -- Never a neutral dodge.
 H.step(c,1)
 assert(not c:request(b,"Substitute"),"substitution used outside a hit")
end)

test("Minato substitutes onto a planted seal and spends it",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 Techniques.plant(c,a,V.new(24,0,18),V.yAxis)
 assert(#a.anchors==1 and a.anchor~=nil)
 assert(c:damage(b,a,6,false,false))
 assert(c:request(a,"Substitute"),"substitution refused")
 assert((a.root.Position-V.new(24,3,18)).Magnitude<1.5,"Minato did not reach the seal: "..tostring(a.root.Position))
 assert(#a.anchors==0 and a.anchor==nil,"the seal was not spent")
end)

test("Itachi's substitution reappears behind the attacker as a crow clone",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,6),V.new(0,3,2))
 assert(c:damage(a,b,6,false,false))
 assert(c:request(b,"Substitute"))
 local back=(b.root.Position-a.root.Position):Dot(a.root.CFrame.LookVector)
 assert(back<-3,"Itachi did not reappear behind the attacker ("..string.format("%.1f",back)..")")
 assert(b.root.CFrame.LookVector:Dot((a.root.Position-b.root.Position).Unit)>.7,"Itachi does not face the attacker")
end)

test("wall carry: knockback splats into the wall, light hits pin, a heavy bounces out",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 H.addWall(14)
 place(c,a,b,V.new(4,3,0),V.new(8,3,0))
 Brawler.react(c,b,"Knockback",V.new(52,10,0),.5,a)
 until_(c,.5,function() return b.reaction=="WallSplat" end,"the knockback never splatted")
 assert(b.splatNormal and b.splatNormal.X<-.9,"splat normal does not face the field")
 assert(b.root.CFrame.LookVector.X<-.9,"the splatted body does not face the field")
 assert(a.pursuitUntil>c.now,"no pursuit window after the splat")
 local splattedHealth=b.health
 assert(splattedHealth<b.def.Health,"the wall impact did no damage")
 -- Walk in and pin it with a light.
 place(c,a,b,V.new(b.root.Position.X-3.5,3,0),b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position-V.xAxis)
 H.step(c,.1)
 assert(c:request(a,"Attack"),"light refused")
 until_(c,.35,function() return b.health<splattedHealth end,"the light never reached the pinned body")
 assert(b.reaction=="WallSplat" and b.splatPins==1,"the light did not pin ("..tostring(b.reaction)..")")
 until_(c,.6,function() return a.state=="Neutral" or (a.state=="Recovery" and c.now>=(a.recoveryCancelAt or 0)) end,"attacker stuck")
 if a.state=="Recovery" then a.state="Neutral";a.untilTime=c.now end
 b.reactionUntil=c.now+.6
 local health=b.health
 assert(c:request(a,"Heavy"),"heavy refused")
 until_(c,.6,function() return b.health<health end,"the heavy never reached the pinned body")
 assert(b.reaction=="Launched","the heavy did not bounce the body ("..tostring(b.reaction)..")")
 assert(b.reactionVelocity.X<-10 and b.reactionVelocity.Y>20,"the bounce does not send the body back out")
 assert((a.events.WallBounce or 0)==1)
end)

test("wall tech: the impact window kicks off the wall; mashing or a late press fails",function()
 for _,timing in {"early","good","late"} do
  local c,a,b=H.duel("Flashstep","Mirage")
  H.clearWalls();H.addWall(14)
  place(c,a,b,V.new(4,3,0),V.new(8,3,0))
  Brawler.react(c,b,"Knockback",V.new(52,10,0),.5,a)
  until_(c,.5,function() return b.reaction=="WallSplat" end,"no splat")
  local chakra=b.chakra
  if timing=="early" then
   assert(not c:request(b,"Dodge"),"tech accepted during the impact freeze")
   H.step(c,.1)
   assert(not c:request(b,"Dodge"),"mashing was not locked out")
   assert(b.reaction=="WallSplat" and b.subCharges==2,"a failed tech spent a substitution")
  elseif timing=="good" then
   H.step(c,.12)
   assert(c:request(b,"Dodge"),"tech refused inside the window")
   assert(b.reaction==nil and b.invulnerableUntil>c.now and b.chakra<chakra,"tech did not free the body")
   assert(b.root.AssemblyLinearVelocity.X<-10 and b.root.AssemblyLinearVelocity.Y>20,"tech did not kick off the wall")
   assert((b.events.WallTech or 0)==1)
  else
   H.step(c,Config.Wall.TechUntil+.08)
   assert(not c:request(b,"Dodge"),"late tech accepted")
  end
 end
end)

test("wall dive: a strike from a wall run dives at the opponent",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 local wall=H.addWall(14)
 place(c,a,b,V.new(12,16,0),V.new(-8,3,0))
 a.wall={part=wall,normal=-V.xAxis,untilTime=c.now+1};a.airborne=true
 assert(c:request(a,"Attack"),"dive refused")
 assert(a.attackName=="WallDive" and a.wall==nil,"strike from the wall is not a dive")
 local start=a.root.Position
 until_(c,.8,function() return b.health<b.def.Health end,"the dive never reached the opponent")
 assert((a.root.Position-start).Magnitude>12,"the dive did not travel")
 assert(b.reaction=="Knockdown","the dive did not knock down ("..tostring(b.reaction)..")")
end)

test("clash: two strikes active together cancel out into a reset",function()
 local c,a,b=H.duel("Flashstep","Flashstep")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,"Attack") and c:request(b,"Attack"))
 until_(c,.3,function() return (a.events.Clash or 0)>0 end,"no clash")
 assert(a.health==a.def.Health and b.health==b.def.Health,"a clash dealt damage")
 assert(a.pending==nil and b.pending==nil,"swings survived the clash")
 H.step(c,.3)
 assert((a.root.Position-b.root.Position).Magnitude>6,"the clash did not push the fighters apart")
end)

test("the Lightning Strike cashes in a teleport arrival at once",function()
 -- (Stage 6) at 13 Minato has no Rasengan: the arrival is spent on the
 -- shunshin cut, out of the teleport recovery.
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-3))
 Techniques.plant(c,a,V.new(0,0,-6),V.yAxis)
 assert(c:request(a,H.slot(a,"Flashstep")),"teleport refused")
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no arrival window")
 assert(c:request(a,H.slot(a,"LightningStrike"),b.root.Position),"the Lightning Strike was refused out of the teleport")
end)

test("Flying Thunder God (prototype): to the last planted seal only, a hit seals the body",function()
 -- (Stage 6) at 13 the technique is a prototype: the stick does not choose,
 -- he goes to the newest seal, and the jutsu recharges for 6 s.
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,0),V.new(0,3,-30))
 Techniques.plant(c,a,V.new(30,0,0),V.yAxis)
 Techniques.plant(c,a,V.new(-30,0,0),V.yAxis)
 assert(#a.anchors==2,"two seals were not both kept")
 a.move=V.xAxis
 assert(c:request(a,H.slot(a,"Flashstep")))
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no teleport")
 assert(a.root.Position.X<-25,"the prototype did not go to the last seal ("..tostring(a.root.Position)..")")
 assert(#a.anchors==1)
 assert((a.cooldowns.Flashstep or 0)-c.now>5,"the prototype does not recharge for 6 s")
 -- A third plant replaces the oldest planted seal, never exceeding two.
 Techniques.plant(c,a,V.new(0,0,40),V.yAxis);Techniques.plant(c,a,V.new(5,0,40),V.yAxis)
 local planted=0;for _,e in a.anchors do if not e.actor then planted+=1 end end
 assert(planted==2,"more than two planted seals")
 -- A seal on the body: the teleport lands beside the opponent wherever it went.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,0),V.new(0,3,-20))
 Techniques.plant(c2,x,y.root.Position,V.yAxis,y)
 c2:relocate(y,V.new(-18,3,-26))
 x.move=V.zero
 assert(c2:request(x,H.slot(x,"Flashstep")))
 until_(c2,.3,function() return (x.flashUntil or 0)>c2.now end,"no teleport to the body seal")
 assert((x.root.Position-y.root.Position).Magnitude<5,"did not arrive beside the sealed body")
 assert(#x.anchors==0,"the body seal was not spent")
end)

test("a marked kunai that connects puts the seal on the body",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,10),V.new(0,3,-10))
 assert(c:request(a,H.slot(a,"MarkedBlade"),b.root.Position))
 until_(c,.3,function() return c:markedInFlight(a)~=nil end,"no marked kunai thrown")
 -- The harness has no body raycasts: resolve the contact the server would see.
 local blade=c:markedInFlight(a)
 c:projectileHit(blade,b,b.root.Position,V.zAxis)
 assert(#a.anchors==1 and a.anchors[1].actor==b,"the seal is not on the body")
 -- A guarded kunai drops its seal at the guard's feet instead.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,10),V.new(0,3,-10))
 assert(c2:request(x,H.slot(x,"MarkedBlade"),y.root.Position))
 until_(c2,.3,function() return c2:markedInFlight(x)~=nil end,"no marked kunai thrown")
 assert(c2:request(y,"Guard"))
 H.step(c2,.3)
 c2:projectileHit(c2:markedInFlight(x),y,y.root.Position,V.zAxis)
 assert(#x.anchors==1 and x.anchors[1].actor==nil,"a guarded kunai sealed the body")
end)

test("genjutsu: swinging at the afterimage exposes the victim",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,-14),V.new(0,3,0))
 b.illusionUntil=c.now+3;b.decoyPosition=V.new(0,3,3)
 b.root.CFrame=H.C.lookAt(b.root.Position,b.decoyPosition)
 assert(c:request(b,"Attack"))
 until_(c,.6,function() return (a.counterUntil or 0)>c.now end,"the whiff on the decoy was not punished")
 assert(b.illusionUntil==0,"the illusion survived the read")
 assert((a.events.MirageCatch or 0)==1)
end)

test("Itachi's Sharingan: a late guard still parries and opens a counter",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,"Attack"))
 -- The guard went up ~0.27s before contact: outside a normal parry window
 -- (0.2s), inside the Sharingan's (0.3s).
 b.guardHeld=true;b.state="Guarding";b.guardPressedAt=c.now-.2
 H.step(c,.3)
 assert((b.events.Parry or 0)==1,"the Sharingan did not parry")
 assert((b.counterUntil or 0)>c.now-.1,"no counter window after the parry")
 -- Minato has no such eye: the same timing is a plain block for him.
 local c2,x,y=H.duel("Mirage","Flashstep")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c2:request(x,"Attack"))
 x.guardPressedAt=-10
 y.guardHeld=true;y.state="Guarding";y.guardPressedAt=c2.now-.26
 H.step(c2,.3)
 assert((y.events.Parry or 0)==0,"a late guard parried without the Sharingan")
end)

test("Itachi's Sharingan tracks a teleport behind a raised guard",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-3))
 Techniques.plant(c,a,b.root.Position,V.yAxis,b)
 assert(c:request(b,"Guard"))
 H.step(c,.3)
 assert(c:request(a,H.slot(a,"Flashstep")))
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no teleport")
 local health=b.health
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return b.health<health end,"the arrival strike never landed")
 assert(health-b.health<4,"the teleport crossed up the Sharingan guard ("..(health-b.health)..")")
end)

test("Shadow Shuriken and Phoenix Flower release their full volleys",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
 local thrown=0
 local seen={}
 assert(c:request(a,H.slot(a,"NeedleFan"),b.root.Position))
 for _=1,90 do H.step(c,.01);for _,p in c.projectiles do if not seen[p] then seen[p]=true;thrown+=1 end end end
 assert(thrown==7,"Shadow Shuriken released "..thrown.." blades")
 -- (Stage 6) the Phoenix Flower is Sasuke's mark now.
 local c2,x,y=H.duel("Lion","Flashstep")
 place(c2,x,y,V.new(0,3,14),V.new(0,3,-14))
 local flames=0;local seen2={}
 assert(c2:request(x,H.slot(x,"PhoenixFlower"),y.root.Position))
 for _=1,90 do H.step(c2,.01);for _,p in c2.projectiles do if not seen2[p] and p.kind=="phoenix" then seen2[p]=true;flames+=1 end end end
 assert(flames==5,"Phoenix Flower released "..flames.." flames")
end)

test("taijutsu routes: heavy after one clean strike differs per prodigy",function()
 for fighter,expect in {Flashstep={"KneeStrike","Juggled"},Mirage={"CounterPalm","Knockback"}} do
  local c,a,b=H.duel(fighter,"GentleFist")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  assert(c:request(a,"Attack"))
  for _=1,80 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt then break end end
  assert(a.chainOpen,fighter..": the first strike did not open the string")
  assert(c:request(a,"Heavy"))
  assert(a.attackName==expect[1],fighter..": heavy after one is "..tostring(a.attackName))
  until_(c,.5,function() return b.reaction==expect[2] end,fighter..": "..expect[1].." did not cause "..expect[2])
 end
end)

test("running taijutsu (user 28/10): out of a sprint, the light opens the string, the heavy is the running entry (Lee: flying kick)",function()
 for _,pair in {{"Attack","Light1","HitStun","Mirage"},{"Heavy","DashAttack","HitStun","Mirage"},{"Heavy","FlyingKick","Knockback","Leaf"}} do
  local c,a,b=H.duel(pair[4],"Flashstep")
  place(c,a,b,V.new(0,3,9),V.new(0,3,-2))
  a.sprinting=true;a.locomotion=a.root.CFrame.LookVector*40
  assert(c:request(a,pair[1]))
  assert(a.attackName==pair[2],"sprint "..pair[1].." is "..tostring(a.attackName))
  until_(c,.6,function() return b.reaction==pair[3] end,pair[2].." did not land ("..tostring(b.reaction)..")")
 end
end)

test("a press made before contact is not eaten: it chains once the swing lands",function()
 for _,fighter in {"Flashstep","Mirage","GentleFist"} do
  local c,a,b=H.duel(fighter,"Mirage")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  assert(c:request(a,"Attack"))
  assert(a.state=="Startup","first light did not start")
  local ok,reason=c:request(a,"Attack")
  assert(ok and reason=="Buffered",fighter..": an early press was refused ("..tostring(reason)..")")
  until_(c,.8,function() return a.attackName=="Light2" end,fighter..": the early press never chained")
 end
end)

print("NinjaDuel phase 4 depth: "..passed.." PASS")
