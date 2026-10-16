-- Stress-test fighter of the next wave (DEC-015): Rock Lee at the Chunin
-- Exam preliminaries. Pure taijutsu on the shared systems: his routes (Leaf
-- Rising Wind into the shared Shadow of the Dancing Leaf, Leaf Hurricane,
-- Leaf Whirlwind), his air finisher (Primary Lotus paid with his own health,
-- the Hidden Lotus in the Fifth Gate), the Leaf Great Whirlwind technique, the
-- deflecting kick that replaces a blade, the Rupture that replaces the
-- kawarimi, his re-engage, the AI using his kit, AI duels against every
-- prodigy, his motion family and his costume.
-- Headless: rules, state, timing and the pose math. Feel, readability, the
-- look of the kicks and the costume need native Studio.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local MoveGraphs=H.load("Shared/MoveGraphs")
local Techniques=H.load("Server/Techniques")
local Brawler=H.load("Server/Brawler")
local ChakraTuning=H.load("Server/ChakraTuning")
local passed=0
local function test(name,fn)
 H.clearWalls()
 local ok,err=pcall(fn)
 H.clearWalls()
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function place(c,a,b,gap)
 gap=gap or 4.5
 c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
 for _,x in {a,b} do x.move=V.zero end
end
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return true end
 end
 error(message,0)
end
local function chainOpen(c,a) return a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0) end
local function chain(c,a,label)
 until_(c,.9,function() return chainOpen(c,a) end,(label or "")..": the chain never opened ("..tostring(a.state)..")")
end
local function flat(v) return V.new(v.X,0,v.Z) end
local function toward(a) return flat(a.target.root.Position-a.root.Position).Unit end
local function side(a,sign) local t=toward(a);return V.new(-t.Z,0,t.X)*(sign or 1) end
local function ev(x,name) return (x.events or {})[name] or 0 end
local function press(c,a,action,stick,aim,opts)
 a.move=stick or V.zero
 local ok,reason=c:request(a,action,aim,nil,opts)
 a.move=V.zero
 return ok,reason
end
local function slot(a,id) for i,t in a.def.Techniques do if t.Id==id then return "Technique"..i end end error("no technique "..id) end
-- Lee against `other` with `hits` confirmed lights and the chain open.
local function opened(hits,other)
 local c,a,b=H.duel("Leaf",other or "Mirage")
 place(c,a,b)
 assert(press(c,a,"Attack"),"opening light refused")
 chain(c,a,"Light1")
 if (hits or 1)>=2 then
  assert(press(c,a,"Attack"),"second light refused")
  until_(c,.8,function() return chainOpen(c,a) and a.attackName=="Light2" end,"the second chain never opened")
 end
 return c,a,b
end
-- Two lights, the rising kick, and the shadow glued under the rising body.
local function shadow(setup)
 local c,a,b=H.duel("Leaf","Mirage")
 if setup then setup(c,a,b) end
 place(c,a,b)
 assert(press(c,a,"Attack"));chain(c,a,"Light1")
 assert(press(c,a,"Attack"));until_(c,.8,function() return chainOpen(c,a) and a.attackName=="Light2" end,"no second chain")
 assert(press(c,a,"Attack",toward(a)),"the rising kick was refused")
 assert(a.attackName=="LeafRising","toward after two kicks gave "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Launched" end,"the Leaf Rising Wind did not launch")
 until_(c,1.2,function() return ev(a,"ShadowLeaf")>0 and a.state~="Pursuit" end,"no Shadow of the Dancing Leaf")
 return c,a,b
end

-- Kit identity -----------------------------------------------------------------
test("pure taijutsu: no blade, no element, no projectile technique, no kawarimi, a body-only chakra profile",function()
 local def=H.fighters.Leaf
 assert(def and def.Name=="Rock Lee" and def.Age==13,"Rock Lee is not in Fighters")
 assert(def.Tool=="Deflect" and def.ToolMastery==nil,"Lee carries a blade")
 for _,spec in def.Techniques do
  assert(spec.Element==nil,spec.Id.." is a ninjutsu ("..tostring(spec.Element)..")")
  assert(spec.Throw==nil and not spec.Mobile,spec.Id.." throws something")
 end
 assert(def.Substitution and def.Substitution.Mode=="burst","Lee still swaps his body (kawarimi)")
 local graph=MoveGraphs.Leaf
 assert(graph.disengage==nil,"Lee's graph hops out behind a throw")
 assert(graph.routes.up=="LeafRising" and graph.routes.down=="LeafHurricane" and graph.routes.side=="LeafWhirlwind","Lee's routes are not his own")
 assert(graph.onRoute.LeafRising=="shadowLeaf","the rising kick is not followed into the air")
 assert(graph.airFinisher and graph.airFinisher.name=="PrimaryLotus","no Primary Lotus")
 assert(graph.reengage and graph.reengage.name=="leaf","no re-engage style of his own")
 assert(ChakraTuning.CharacterMastery.Leaf=="Taijutsu","no chakra profile of his own")
 assert(#ChakraTuning.Masteries.Taijutsu.tags==1 and ChakraTuning.Masteries.Taijutsu.tags[1]=="body","the Taijutsu profile is not body-only")
 assert(next(ChakraTuning.Preferred.Taijutsu)==nil and ChakraTuning.BodyTool.Taijutsu==nil,"the Taijutsu profile pours chakra into something")
 -- Young stage only (DEC-013): five gates at most.
 assert(def.Awakening.Name=="FIFTH GATE","the awakening is not the Fifth Gate")
end)

-- Routes ---------------------------------------------------------------------
test("two kicks and toward: the Leaf Rising Wind, followed into the air by the shared Shadow of the Dancing Leaf",function()
 local c,a,b=shadow()
 assert(a.airborne and (a.lionUntil or 0)>c.now,"Lee is not in the air with the body")
 local gap=(a.root.Position-b.root.Position).Magnitude
 assert(gap<6,"the shadow left him "..string.format("%.1f",gap).." studs away")
 local cued=false
 for _,entry in c.match.cues do if entry.actor==a.id and entry.message:find("PRIMARY LOTUS",1,true) then cued=true end end
 assert(cued,"the shadow cue does not announce his own finisher")
end)
test("Primary Lotus: the air heavy in the shadow window drives the body into the floor, paid with 10 of his own health",function()
 local c,a,b=shadow()
 local health,victim=a.health,b.health
 assert(press(c,a,"Heavy"),"the Primary Lotus was refused")
 assert(a.attackName=="Slam" and a.attackVariant=="PrimaryLotus","the air heavy was not the Primary Lotus ("..tostring(a.attackVariant)..")")
 assert(math.abs((health-a.health)-10)<.01,string.format("the lotus cost %.1f health instead of 10",health-a.health))
 assert(ev(a,"PrimaryLotus")==1,"the lotus was not reported")
 until_(c,1.2,function() return b.health<victim end,"the Primary Lotus never landed")
 assert(victim-b.health>=14,string.format("the Primary Lotus was light (%.1f)",victim-b.health))
 until_(c,.6,function() return b.reaction=="Knockdown" end,"the lotus did not knock the body down")
 -- Sasuke keeps his own finisher in the same window.
 local c2,x,y=H.duel("Lion","Mirage");place(c2,x,y)
 assert(press(c2,x,"Attack"));chain(c2,x);assert(press(c2,x,"Attack"))
 until_(c2,.8,function() return chainOpen(c2,x) and x.attackName=="Light2" end,"Sasuke: no second chain")
 assert(press(c2,x,"Attack",toward(x)));until_(c2,1.4,function() return ev(x,"ShadowLeaf")>0 and x.state~="Pursuit" end,"Sasuke: no shadow")
 assert(press(c2,x,"Heavy") and x.attackVariant=="LionBarrage","Sasuke lost his Lion Combo to the lotus")
end)
test("too hurt for the lotus (26 health or less): the air heavy is the Leaf Heel, free; the lotus never kills him",function()
 local c,a,b=shadow(function(c,a) a.health=24;a.hum.Health=24 end)
 local health=a.health
 assert(press(c,a,"Heavy"))
 assert(a.attackVariant=="LeafHeel","a hurt Lee still paid for the lotus ("..tostring(a.attackVariant)..")")
 assert(a.health==health,"the Leaf Heel cost health")
 until_(c,1.2,function() return b.health<b.def.Health end,"the Leaf Heel never landed")
 -- Just above the threshold the lotus is paid and leaves him standing.
 local c2,x=shadow(function(c,a) a.health=27;a.hum.Health=27 end)
 assert(press(c2,x,"Heavy") and x.attackVariant=="PrimaryLotus","27 health refused the lotus")
 assert(x.health>=1 and x.health<=17.01,"the lotus price was not paid ("..x.health..")")
end)
test("heavy after two kicks is the rising kick too (into the chase); heavy after one is the knee",function()
 local c,a,b=opened(2)
 assert(press(c,a,"Heavy"));assert(a.attackName=="LeafRising","heavy after two kicks is "..tostring(a.attackName))
 until_(c,1.2,function() return ev(a,"ShadowLeaf")>0 end,"the heavy rising kick was not followed")
 local c2,x=opened(1)
 assert(press(c2,x,"Heavy"));assert(x.attackName=="KneeStrike","heavy after one kick is "..tostring(x.attackName))
end)
test("the Leaf Hurricane keeps the string: two kicks, away, a low spin, then the third kick ends it",function()
 local c,a,b=opened(2)
 assert(press(c,a,"Attack",-toward(a)));assert(a.attackName=="LeafHurricane","away after two kicks gave "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Juggled" end,"the low spin did not take the legs")
 assert(b.reaction~="Knockdown","the low spin ended the string with a knockdown")
 chain(c,a,"LeafHurricane")
 assert(a.combo==3,"the low spin did not count as the third confirmed hit ("..tostring(a.combo)..")")
 assert(press(c,a,"Attack"));assert(a.attackName=="Light3","after the low spin the next press is "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Knockback" end,"the fourth strike did not knock away")
 -- From the low spin the rising kick is still there.
 local c2,x,y=opened(2)
 assert(press(c2,x,"Attack",-toward(x)));chain(c2,x,"LeafHurricane")
 assert(press(c2,x,"Attack",toward(x)));assert(x.attackName=="LeafRising","toward after the low spin is "..tostring(x.attackName))
end)
test("the Leaf Whirlwind: one kick and side, a wide spin that reaches a body that stepped aside, the string stays open",function()
 local c,a,b=opened(1)
 assert(press(c,a,"Attack",side(a,1)));assert(a.attackName=="LeafWhirlwind","side after one kick gave "..tostring(a.attackName))
 -- The opponent steps a body width aside during the startup: the arc still reaches.
 c:relocate(b,b.root.Position+side(a,1)*2.6)
 local before=flat(a.root.Position-b.root.Position)
 local health=b.health
 until_(c,.5,function() return b.health<health end,"the wide spin missed a body that stepped aside")
 chain(c,a,"LeafWhirlwind")
 local after=flat(a.root.Position-b.root.Position)
 local turned=math.deg(math.acos(math.clamp(before.Unit:Dot(after.Unit),-1,1)))
 assert(turned<25,string.format("the Leaf Whirlwind took an angle (%.0f deg): it is not an orbit route",turned))
 assert(a.combo==2,"the whirlwind did not keep the string ("..tostring(a.combo)..")")
end)

-- Technique --------------------------------------------------------------------
test("Leaf Great Whirlwind: a spinning kick across 12 studs knocks away and opens the chase; 10 chakra and a cooldown",function()
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,12)
 local chakra=a.chakra
 assert(press(c,a,slot(a,"LeafGreatWhirlwind"),nil,b.root.Position),"the technique was refused")
 assert(math.abs(chakra-a.chakra-10)<.01,string.format("the technique cost %.1f",chakra-a.chakra))
 assert((a.cooldowns.LeafGreatWhirlwind or 0)>c.now+2,"no cooldown")
 until_(c,.4,function() return a.attackName=="GreatWhirlwind" end,"the spinning kick never started")
 local health=b.health
 until_(c,.8,function() return b.reaction=="Knockback" end,"the spinning kick did not knock away from 12 studs")
 assert(health-b.health>=6,"the spinning kick was light")
 assert(a.pursuitUntil>c.now,"the knock-away opened no chase")
 -- A clean string cancels into it with a short wind-up.
 local c2,x,y=opened(1);x.chakra=x.def.Chakra
 assert(press(c2,x,slot(x,"LeafGreatWhirlwind"),nil,y.root.Position),"no string cancel into the whirlwind")
 assert(x.state=="TechniqueChannel" and x.untilTime-c2.now<=.15,"the string cancel kept a full wind-up")
end)

-- Tool: the deflecting kick ------------------------------------------------------
test("the deflecting kick: blades kicked out of the air, nothing taken, the next dash free; jutsu go through",function()
 for _,kind in {"kunai","shuriken"} do
  local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,16)
  local blade=c:projectile(b,a.root.Position,80,30,3,kind)
  H.step(c,.06)
  assert(press(c,a,"Tool"),kind..": the deflecting kick was refused with a blade coming")
  assert(a.attackName=="DeflectKick",kind..": the tool button is "..tostring(a.attackName))
  until_(c,.5,function() return not table.find(c.projectiles,blade) end,kind..": the blade was never stopped")
  assert(a.health==a.def.Health,kind..": the blade still hit him")
  assert(ev(a,"Deflect")>=1 and (a.freeRushUntil or 0)>c.now,kind..": the deflection gave no free dash")
  local deflected=false
  for _,impact in c.impacts do if impact.style=="deflect" and impact.projectile==blade.id then deflected=true end end
  assert(deflected,kind..": the client was not told the blade was kicked away")
 end
 -- A fireball is a jutsu volume: alone it is no reason to kick, and it lands.
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,16)
 local fire=c:projectile(b,a.root.Position,58,40,8,"fireball",nil,{radius=1.4})
 H.step(c,.06)
 local ok,why=press(c,a,"Tool")
 assert(not ok and why=="Nothing to deflect","a lone fireball made him kick ("..tostring(why)..")")
 until_(c,.8,function() return not table.find(c.projectiles,fire) end,"the fireball never arrived")
 assert(a.health<a.def.Health and ev(a,"Deflect")==0,"the fireball was kicked away")
 -- One sweep of the kick with a blade, a fireball, a palm and a sand wave all
 -- inside its arc: only the blade goes.
 local c2,x,y=H.duel("Leaf","Mirage");place(c2,x,y,16)
 local ahead=x.root.Position+x.root.CFrame.LookVector*3
 local list={}
 for _,kind in {"kunai","fireball","palm","sandwave","wind"} do
  list[kind]=c2:projectile(y,x.root.Position,40,30,3,kind,nil,{origin=ahead})
 end
 assert(Techniques.deflectSweep(c2,x,x.def.Deflect)==1,"the sweep did not kick exactly the blade")
 assert(not table.find(c2.projectiles,list.kunai),"the blade survived the sweep")
 for _,kind in {"fireball","palm","sandwave","wind"} do assert(table.find(c2.projectiles,list[kind]),"the kick swallowed a "..kind) end
end)
test("the tool button with nothing coming and nobody in reach does nothing; he never throws anything",function()
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,20)
 local chakra=a.chakra
 local ok,why=press(c,a,"Tool",nil,b.root.Position)
 assert(not ok and why=="Nothing to deflect","an empty tool press did "..tostring(why))
 assert(a.state=="Neutral" and a.chakra==chakra,"an empty tool press cost something")
 -- Close in, it is a real kick.
 place(c,a,b,4)
 H.step(c,.6)
 assert(press(c,a,"Tool"),"the close kick was refused")
 until_(c,.5,function() return b.health<b.def.Health end,"the deflecting kick did not hit a close body")
 for _,p in c.projectiles do assert(p.a~=a,"Lee threw a projectile") end
end)
test("chakra modifier on the tool: refused with the fizzle and nothing spent (Taijutsu profile)",function()
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,4)
 local chakra=a.chakra
 local serial=c.impactSerial or 0
 local ok,why=press(c,a,"Tool",nil,b.root.Position,{chakra=true})
 assert(not ok and why=="No chakra tool","the chakra chord gave "..tostring(why))
 assert(a.chakra==chakra and a.state=="Neutral","the refused chord cost something")
 assert(ev(a,"ChakraRefused")==1,"the refusal was not reported")
 local fizzle=false
 for _,impact in c.impacts do if impact.serial>serial and impact.chakra=="fizzle" and impact.owner==a.id then fizzle=true end end
 assert(fizzle,"the refusal showed no fizzle")
end)

-- Rupture -------------------------------------------------------------------------
test("the Rupture replaces the kawarimi: same charge and window, he stays where he is, a close attacker is thrown off",function()
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b)
 assert(press(c,b,"Attack"))
 until_(c,.5,function() return a.reaction~=nil end,"fixture: Itachi's jab never landed")
 local from=a.root.Position
 local charges,chakra=a.subCharges,a.chakra
 assert(c:request(a,"Substitute"),"the Rupture was refused while hit")
 assert((a.root.Position-from).Magnitude<.5,"the Rupture moved him ("..string.format("%.1f",(a.root.Position-from).Magnitude)..")")
 assert(a.subCharges==charges-1 and chakra-a.chakra>=Config.Substitution.Cost-.01,"the Rupture did not spend a charge and its chakra")
 assert(a.reaction==nil and a.invulnerableUntil>c.now,"the Rupture did not free him")
 assert(b.reaction=="Knockback","the attacker was not thrown off")
 assert(ev(a,"Rupture")==1 and ev(a,"Substitute")==1,"the Rupture was not reported")
 for _,impact in c.impacts do assert(impact.style~="substitute" or impact.owner~=a.id,"a log replaced Lee (kawarimi visual)") end
 -- Out of reach (the attacker already stepped back), it is a read: a longer recovery.
 local c2,x,y=H.duel("Leaf","Mirage");place(c2,x,y)
 assert(press(c2,y,"Attack"))
 until_(c2,.5,function() return x.reaction~=nil end,"fixture: no hit")
 c2:relocate(y,y.root.Position+toward(x)*8)
 assert(c2:request(x,"Substitute"))
 assert(x.state=="Recovery" and x.untilTime-c2.now>=.29,"a whiffed Rupture recovered like a clean one")
 assert(y.reaction==nil,"an attacker out of reach was thrown off")
end)

-- Fifth Gate -------------------------------------------------------------------
local function walk(c,a,seconds)
 a.move=V.new(1,0,0);a.state="Neutral";a.untilTime=c.now;a.reaction=nil
 local from=a.root.Position
 H.step(c,seconds)
 a.move=V.zero
 H.step(c,.5)
 return flat(a.root.Position-from).Magnitude
end
test("the Fifth Gate: only under 35%; faster legs (the real limit), harder, the body burns and never dies",function()
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,12)
 local base=walk(c,a,1)
 place(c,a,b,12)
 assert(not c:request(a,"Awaken"),"the gate opened at full health")
 a.health=a.def.Health*.3;a.hum.Health=a.health
 assert(c:request(a,"Awaken"),"the gate refused under 35%")
 H.step(c,.5)
 assert(math.abs(a.speedScale-1.28)<.001,"the gate did not speed him up ("..tostring(a.speedScale)..")")
 -- The speed is real: walking, the limit Motor.step allows is the gate's.
 local before=a.health
 H.step(c,2)
 assert(before-a.health>3.5,string.format("the gate did not burn (%.1f)",before-a.health))
 a.health=1.3;a.hum.Health=1.3
 H.step(c,2)
 assert(a.health>=1,"the gate killed him")
 local moved=walk(c,a,1)
 assert(moved>base*1.2,string.format("he walked %.1f studs in the gate against %.1f without: the gate's speed is capped",moved,base))
end)
test("the Fifth Gate turns the lotus into the Hidden Lotus: free, harder, and the body bounces back up",function()
 local c,a,b=shadow(function(c,a,b)
  a.health=a.def.Health*.3;a.hum.Health=a.health
  assert(c:request(a,"Awaken"),"the gate refused")
  H.step(c,1.2)
 end)
 local health,victim=a.health,b.health
 assert(press(c,a,"Heavy"))
 assert(a.attackVariant=="HiddenLotus","the gate's lotus is "..tostring(a.attackVariant))
 assert(health-a.health<.2,"the Hidden Lotus cost health")
 until_(c,1.2,function() return b.health<victim end,"the Hidden Lotus never landed")
 until_(c,1.5,function() return ev(b,"GroundBounce")>0 end,"the Hidden Lotus did not bounce the body")
 assert(ev(a,"HiddenLotus")==1,"the Hidden Lotus was not reported")
end)

-- Re-engage ------------------------------------------------------------------------
test("re-engage: his dash is the fastest of all, straight down the line, and arrives into his kicks",function()
 local function dash(id)
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,24);a.locked=true
  local start=c.now
  assert(press(c,a,"Pursuit"),id..": dash refused")
  until_(c,1,function() return a.state~="Rush" end,id..": the dash never ended")
  return c.now-start,c,a,b
 end
 local lee,c,a,b=dash("Leaf")
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  local other=dash(id)
  assert(lee<other,string.format("%s re-enters faster than Lee (%.2f vs %.2f s)",id,other,lee))
 end
 local seen=false
 for _,impact in c.impacts do if impact.style=="chase" and impact.owner==a.id and impact.variant=="leaf" then seen=true end end
 assert(seen,"his re-engage style was not reported to the client")
 assert(press(c,a,"Attack") and a.attackName=="DashAttack","no strike on his arrival")
end)

-- AI ----------------------------------------------------------------------------------
local function seeded(fn)
 local saved=H.envBase.Random
 H.envBase.Random={new=function(seed)
  local state=(seed or 1)*2654435761%4294967296
  local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
  return {NextNumber=function(_,x,y) local r=roll();if x and y then return x+(y-x)*r end return r end,
   NextInteger=function(_,x,y) return math.floor(x+(y-x+1)*roll()) end}
 end}
 local ok,err=pcall(fn)
 H.envBase.Random=saved
 assert(ok,err)
end
test("the AI uses his kit: the spinning kick across a gap, the deflecting kick against a blade, the lotus after the rising kick",function()
 local AI=H.load("Server/AI")
 local low={NextNumber=function(_,x,y) if x and y then return x end return .05 end}
 -- Neutral at 10 studs, a jutsu roll: the spinning kick.
 local c,a,b=H.duel("Leaf","Mirage");place(c,a,b,10)
 local bot=AI.new(c,a,3);bot.rng=low;bot.probing=false;bot.modeUntil=c.now+5;bot.observed=b.state;bot.observedAt=c.now-1
 for _=1,40 do bot:update(c.now);H.step(c,.02);if ev(a,"Technique")>0 then break end end
 assert(ev(a,"GreatWhirlwind")>0 or a.castId=="LeafGreatWhirlwind","the bot never used the Leaf Great Whirlwind")
 -- A kunai flying at him: the deflecting kick.
 local c2,x,y=H.duel("Leaf","Mirage");place(c2,x,y,10)
 local bot2=AI.new(c2,x,5);bot2.rng=low
 c2:projectile(y,x.root.Position,80,30,3,"kunai")
 for _=1,20 do bot2:update(c2.now);H.step(c2,.01);if ev(x,"DeflectKick")>0 then break end end
 assert(ev(x,"DeflectKick")>0,"the bot did not kick the blade away")
 -- Up in the shadow after the rising kick, one air hit: the lotus.
 local c3,m,n=shadow()
 local bot3=AI.new(c3,m,9);bot3.rng={NextNumber=function(_,x,y) if x and y then return x end return .5 end}
 for _=1,120 do
  bot3:update(c3.now);H.step(c3,.01)
  n.reactionVelocity=V.zero
  if ev(m,"PrimaryLotus")>0 then break end
 end
 assert(ev(m,"PrimaryLotus")>0,"the bot never cashed in the lotus (air hits "..ev(m,"AirHit")..")")
end)
test("AI duels: Rock Lee against every CORE4 prodigy, Gaara and himself, both ways, to the KO and without wedging",function()
 seeded(function()
  local AI=H.load("Server/AI")
  local opponents={"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf"}
  local lotus,routes=0,0
  for k,other in opponents do
   for _,pair in (if other=="Leaf" then {{"Leaf","Leaf"}} else {{"Leaf",other},{other,"Leaf"}}) do
    do
     local c,a,b,match=H.duel(pair[1],pair[2])
     place(c,a,b,14)
     local one,two=AI.new(c,a,k*5+1),AI.new(c,b,k*5+3)
     local stuck={}
     local t=0
     while match.phase=="Duel" and t<150 do
      one:update(c.now);two:update(c.now);H.step(c,.01);t+=.01
      for _,x in {a,b} do
       if x.state=="Neutral" or x.state=="Guarding" then stuck[x]=0 else stuck[x]=(stuck[x] or 0)+.01 end
       assert(stuck[x]<4,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
       assert(x.health==x.health and x.root.Position.Y==x.root.Position.Y,pair[1].." vs "..pair[2]..": non-finite state")
      end
      for _,p in c.projectiles do assert(p.a.fighterId~="Leaf",pair[1].." vs "..pair[2]..": Lee threw a "..tostring(p.kind)) end
     end
     assert(match.phase~="Duel",string.format("%s vs %s did not finish in 150 s (%.0f / %.0f health)",pair[1],pair[2],a.health,b.health))
     for _,x in {a,b} do
      if x.fighterId=="Leaf" then lotus+=ev(x,"PrimaryLotus")+ev(x,"HiddenLotus")+ev(x,"LeafHeel");routes+=ev(x,"Route") end
     end
     print(string.format("   %s vs %s: %.1f s, winner %s",pair[1],pair[2],t,tostring(match.winner)))
    end
   end
  end
  assert(routes>=6,"Lee's bot barely used his routes ("..routes..")")
  assert(lotus>=1,"Lee's bot never reached a lotus in twelve duels")
 end)
end)

print("NinjaDuel Rock Lee stress test: "..passed.." PASS")
