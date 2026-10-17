-- Roster wave (several bodies, hook H12): Naruto Uzumaki in Part I. His
-- shadow clones are bodies that are not actors (Server/Bodies): capped, paid,
-- timed, dispelled by one blow (strike, blade, dome), carrying his routes
-- (the third hit from behind, the flank strike, the Uzumaki Barrage), shaping
-- his Rasengan, transformed from his kunai, swapped in a substitution; the
-- Nine-Tails cloak takes them away. The lock, the AI's target and the camera
-- stay on the real Naruto. AI duels against every fighter, his motion family,
-- his costume, his roster slot and the client drawing of the clones.
-- Headless: rules, state, timing and pose math. The look of the clones, the
-- poofs and the feel of a multi-body fight need native Studio.
local H=require("./Harness")
local V=H.V
local Config=H.load("Shared/Config")
local MoveGraphs=H.load("Shared/MoveGraphs")
local Bodies=H.load("Server/Bodies")
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
local function clones(c,a,all) return Bodies.of(c,a,"clone",all) end
local function impacts(c,style,phase)
 local out={}
 for _,impact in c.impacts do if impact.style==style and (phase==nil or impact.phase==phase) then table.insert(out,impact) end end
 return out
end
-- A clone of Naruto's standing still where the test puts it (no controller).
local function still(c,a,at)
 return Bodies.spawn(c,a,{kind="clone",position=at,mode="test"})
end
-- Naruto against `other` with `hits` confirmed lights and the chain open.
local function opened(hits,other,setup)
 local c,a,b=H.duel("Legion",other or "Mirage")
 place(c,a,b)
 if setup then setup(c,a,b) end
 assert(press(c,a,"Attack"),"opening light refused")
 chain(c,a,"Light1")
 if (hits or 1)>=2 then
  assert(press(c,a,"Attack"),"second light refused")
  until_(c,.8,function() return chainOpen(c,a) and a.attackName=="Light2" end,"the second chain never opened")
 end
 return c,a,b
end

-- Kit ---------------------------------------------------------------------------
test("kit: Part I Naruto, the largest reserve, capped clones, routes carried by clones, a chakra profile of his own",function()
 local def=H.fighters.Legion
 assert(def and def.Name=="Naruto" and def.Age==13,"Naruto is not in Fighters")
 assert(def.Chakra>=150 and def.Chakra>H.fighters.Mirage.Chakra,"not the largest reserve")
 local clone=def.Bodies and def.Bodies.clone
 assert(clone and clone.Max==2 and clone.Cost==12 and clone.Life==6,"the clones are not capped, paid and timed")
 assert(def.Substitution and def.Substitution.Mode=="clone","no swap with a clone")
 assert(def.ToolMastery and def.ToolMastery.Kind=="kunai" and def.ToolMastery.Transform=="clone","his kunai does not turn into a clone")
 assert(def.Awakening and def.Awakening.Name=="NINE-TAILS CHAKRA" and def.Awakening.NoBodies,"the awakening keeps the clones")
 local ids={}
 for _,spec in def.Techniques do ids[spec.Id]=spec end
 assert(ids.ShadowClone and ids.CloneRasengan and ids.MassShadowClone,"his jutsu are missing")
 local graph=MoveGraphs.Legion
 assert(graph.routes.up=="UzumakiKick" and graph.routes.down=="Tackle" and graph.routes.side=="MirrorClone","his routes are not his own")
 assert(graph.proxy.Light3.move=="CloneKick" and graph.proxy.UzumakiKick.summon and graph.proxy.MirrorClone.summon,"the clones do not carry his routes")
 assert(graph.airFinisher and graph.airFinisher.name=="NarutoRendan","no Naruto Rendan")
 assert(graph.reengage and graph.reengage.name=="legion" and graph.reengage.shuffle,"no unpredictable re-engage")
 assert(ChakraTuning.CharacterMastery.Legion=="ShadowClone" and ChakraTuning.Masteries.ShadowClone,"no chakra profile of his own")
 -- Young stage only (DEC-013): no Sage Mode, no Rasenshuriken, no four tails.
 for _,spec in def.Techniques do assert(not spec.Name:find("Shuriken",1,true) and not spec.Name:find("Sage",1,true),spec.Name.." is Part II") end
end)

-- Clones: lifecycle and limits ------------------------------------------------------
test("Shadow Clone: 12 chakra, a body beside him (not an actor), two at most, six seconds, then a puff",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,24)
 local chakra=a.chakra
 assert(press(c,a,slot(a,"ShadowClone")),"Shadow Clone refused")
 assert(math.abs(chakra-a.chakra-12)<.01,string.format("Shadow Clone cost %.1f",chakra-a.chakra))
 until_(c,.5,function() return #clones(c,a)==1 end,"no clone appeared")
 local clone=clones(c,a)[1]
 assert(#c.actors==2,"the clone became an actor")
 assert(b.target==a and a.target==b,"the targets moved off the real fighters")
 assert((clone.position-a.root.Position).Magnitude<4.5,"the clone did not appear beside him")
 assert(#impacts(c,"body","appear")==1,"the client was not told a clone appeared")
 local view=Bodies.view(c)
 assert(#view==1 and view[1].owner==a.id and view[1].fighterId=="Legion" and view[1].kind=="clone","the snapshot does not list the clone")
 H.step(c,1.3)
 assert(press(c,a,slot(a,"ShadowClone")),"the second clone was refused")
 until_(c,.5,function() return #clones(c,a)==2 end,"no second clone")
 local sides=clones(c,a)
 assert(sides[1].side~=sides[2].side,"both clones came out on the same side")
 H.step(c,1.3)
 local before=a.chakra
 local ok=press(c,a,slot(a,"ShadowClone"))
 assert(not ok and #clones(c,a)==2 and a.chakra>=before,"a third clone was made (or paid for)")
 -- Six seconds after the first, it puffs away on its own.
 until_(c,4.5,function() return not clone.alive end,"the clone outlived its six seconds")
 assert(c.now-clone.born>=5.9 and c.now-clone.born<=6.2,string.format("the clone lived %.2f s",c.now-clone.born))
 local expired=false
 for _,impact in impacts(c,"body","expire") do if impact.body==clone.id then expired=true end end
 assert(expired,"the clone left without a puff")
end)
test("one blow dispels a clone: the opponent's light reaches it first, the real Naruto is untouched, the swing is spent",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,9)
 local clone=still(c,a,b.root.Position+toward(b)*2.6)
 b.locked=true
 assert(press(c,b,"Attack"),"the opponent's light was refused")
 until_(c,.5,function() return not clone.alive end,"the light went through the clone")
 assert(a.health==a.def.Health,"the real Naruto was hit through his clone")
 local hit=impacts(c,"body","hit")
 assert(#hit==1 and hit[1].by==b.id,"the dispel was not reported with its author")
 until_(c,.5,function() return b.state=="Recovery" end,"the swing never recovered")
 assert(not b.chainOpen and (b.combo or 0)==0,"striking a clone counted as a confirmed hit")
 assert(ev(b,"BodyDispelled")==1 and ev(a,"BodyLost")==1,"the dispel was not counted")
 -- A wide swing (Itachi's low sweep) clears the clone beside Naruto and still takes his legs.
 local c2,x,y=H.duel("Mirage","Legion");place(c2,x,y)
 assert(press(c2,x,"Attack"));chain(c2,x,"Itachi Light1")
 assert(press(c2,x,"Attack"));until_(c2,.8,function() return chainOpen(c2,x) and x.attackName=="Light2" end,"Itachi: no second chain")
 local beside=still(c2,y,y.root.Position+side(y,1)*2)
 assert(press(c2,x,"Attack",-toward(x)));assert(x.attackName=="Sweep","fixture: Itachi's low route is "..tostring(x.attackName))
 until_(c2,.6,function() return not beside.alive end,"the sweep went under the clone")
 until_(c2,.6,function() return y.reaction=="Knockdown" end,"the sweep that cleared the clone missed Naruto")
end)
test("blades stop in a clone, jutsu go through it: a kunai is spent on the clone, a fireball puffs it and carries on",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,16)
 local clone=still(c,a,a.root.Position-toward(a)*-4)
 local blade=c:projectile(b,a.root.Position,80,30,3,"kunai")
 until_(c,.5,function() return not clone.alive end,"the kunai flew through the clone")
 assert(not table.find(c.projectiles,blade),"the kunai went on after the clone")
 local finished=false
 for _,impact in impacts(c,"body","blade") do if impact.projectile==blade.id then finished=true end end
 assert(finished,"the client was not told the blade ended in the clone")
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,16)
 local clone2=still(c2,x,x.root.Position+toward(x)*4)
 local fire=c2:projectile(y,x.root.Position,58,40,8,"fireball",nil,{radius=1.4})
 until_(c2,.5,function() return not clone2.alive end,"the fireball left the clone standing")
 assert(table.find(c2.projectiles,fire),"the fireball stopped in the clone")
 until_(c2,.6,function() return x.health<x.def.Health end,"the fireball never reached Naruto behind his clone")
 -- His own blades never touch his own clones.
 local c3,m,n=H.duel("Legion","Mirage");place(c3,m,n,16)
 local own=still(c3,m,m.root.Position+toward(m)*4)
 c3:projectile(m,n.root.Position,80,30,3,"kunai")
 H.step(c3,.3)
 assert(own.alive,"Naruto's own kunai dispelled his clone")
 -- A clone right behind Naruto is no shield: on a step that reaches both, he is nearer.
 local c4,u,w=H.duel("Legion","Mirage");place(c4,u,w,16)
 local behind=still(c4,u,u.root.Position+V.new(0,0,1.6))
 local blade={a=w,position=u.root.Position-V.new(0,0,.5),radius=0,growth=0,born=c4.now,kind="kunai",direction=V.zAxis,id=99}
 assert(Bodies.projectile(c4,blade,V.new(0,0,2.6))==false and behind.alive,"a clone behind Naruto took the blade that reached him first")
end)
test("the lock stays on Naruto, the stick picks the clone: an opener pushed at a clone on the flank swings at it",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,9)
 b.locked=true
 local clone=still(c,a,b.root.Position+side(b,1)*4)
 assert(press(c,b,"Attack",side(b,1)),"the opener at the clone was refused")
 assert(b.pending and b.pending.aim==clone,"the opener was not aimed at the clone")
 assert(b.target==a,"the lock moved to the clone")
 until_(c,.5,function() return not clone.alive end,"the swing at the clone missed it")
 assert(a.health==a.def.Health,"the swing at the clone hit Naruto")
 -- Pushed at Naruto instead, the same opener goes to him.
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,5)
 y.locked=true
 local clone2=still(c2,x,y.root.Position+side(y,1)*4)
 assert(press(c2,y,"Attack",toward(y)))
 assert(y.pending.aim==nil,"an opener pushed at Naruto was aimed at the clone")
 until_(c2,.5,function() return x.health<x.def.Health end,"the opener at Naruto missed")
 assert(clone2.alive,"the opener at Naruto dispelled the clone on the flank")
 -- Inside a string the stick picks routes, never a clone.
 local c3,m,n=opened(1,"Mirage")
 local clone3=still(c3,m,n.root.Position+side(n,1)*4)
 n.locked=true
 assert(press(c3,m,"Attack",side(m,1)))
 assert(m.pending.aim==nil,"a route was aimed at a clone")
 assert(clone3.alive)
end)
-- Routes carried by clones ---------------------------------------------------------
test("the third hit comes from a clone out, from behind: judged from the clone it goes through a frontal guard; the clone is spent",function()
 local c,a,b=opened(2,"Mirage",function(c,a,b) still(c,a,a.root.Position+side(a,1)*3) end)
 assert(#clones(c,a)==1,"fixture: no clone out")
 local clone=clones(c,a)[1]
 assert(press(c,a,"Attack"),"the third press was refused")
 assert(a.attackName=="CloneKick","the third hit with a clone out is "..tostring(a.attackName))
 -- The opponent raises a frontal guard against Naruto right away.
 b.reaction=nil;b.reactionUntil=0;b.state="Guarding";b.guardHeld=true;b.guardPressedAt=-10;b.untilTime=c.now
 local health=b.health
 until_(c,.6,function() return b.health<health end,"the clone's kick never landed")
 assert(b.impactStyle~="block","a frontal guard stopped a kick from behind")
 assert(math.abs(b.hitAngle or 0)>110,string.format("the kick was not judged from behind (hit angle %.0f)",b.hitAngle or 0))
 local line=flat(b.root.Position-a.root.Position).Unit
 assert(flat(clone.position-b.root.Position):Dot(line)>1.5,"the clone did not strike from behind the opponent")
 until_(c,.8,function() return not clone.alive end,"the clone outlived its kick")
 assert(#clones(c,a,true)==0,"a clone stayed after the route")
 -- No clone out: the third hit is his own push kick, and the same guard holds.
 local c2,x,y=opened(2,"Mirage")
 assert(press(c2,x,"Attack"))
 assert(x.attackName=="Light3","with no clone the third hit is "..tostring(x.attackName))
 y.reaction=nil;y.reactionUntil=0;y.state="Guarding";y.guardHeld=true;y.guardPressedAt=-10;y.untilTime=c2.now
 until_(c2,.6,function() return y.impactStyle=="block" end,"his own kick was not guarded")
 assert(#clones(c2,x,true)==0,"a plain third hit made a clone")
 -- A punch thrown at Naruto in the same instant does not "clash" with the
 -- clone's kick from behind: the two blows are far apart.
 local c3,m,n=opened(2,"Mirage",function(c,a) still(c,a,a.root.Position+side(a,1)*3) end)
 assert(press(c3,m,"Attack") and m.attackName=="CloneKick")
 H.step(c3,.06)
 n.reaction=nil;n.reactionUntil=0;n.state="Neutral";n.untilTime=c3.now;n.comboHits=0
 assert(press(c3,n,"Attack"),"fixture: the opponent's punch was refused")
 local health=n.health
 until_(c3,.6,function() return n.health<health end,"the clone's kick never landed")
 assert(ev(m,"Clash")==0 and ev(n,"Clash")==0,"the clone's kick clashed with a punch thrown at Naruto")
end)
test("side after one hit: a clone strikes from that flank and the string goes on; with none out he pays 12 for one",function()
 local c,a,b=opened(1)
 local chakra=a.chakra
 assert(press(c,a,"Attack",side(a,1)),"the side route was refused")
 assert(a.attackName=="MirrorClone","side after one hit gave "..tostring(a.attackName))
 assert(chakra-a.chakra>=11.9,string.format("the summoned clone cost %.1f",chakra-a.chakra))
 local clone=clones(c,a,true)[1]
 assert(clone and clone.ephemeral,"no clone came for the route")
 local health=b.health
 until_(c,.5,function() return b.health<health end,"the flank strike never landed")
 assert(math.abs(math.abs(b.hitAngle or 0)-90)<45,string.format("the strike was not judged from the flank (hit angle %.0f)",b.hitAngle or 0))
 chain(c,a,"MirrorClone")
 assert(a.combo==2,"the flank strike did not keep the string ("..tostring(a.combo)..")")
 until_(c,.8,function() return not clone.alive end,"the route's clone stayed")
 -- With a clone out the route spends it and costs nothing.
 local c2,x,y=opened(1,"Mirage",function(c,a) still(c,a,a.root.Position+side(a,-1)*3) end)
 local live=clones(c2,x)[1]
 local before=x.chakra
 assert(press(c2,x,"Attack",side(x,1)))
 assert(x.attackName=="MirrorClone" and live.carry~=nil,"the live clone did not take the route")
 assert(before-x.chakra<.5,"a route with a clone out was paid for")
 until_(c2,.8,function() return not live.alive end,"the clone survived its route")
 -- No clone, no chakra: the string simply goes on with his own hit.
 local c3,m=opened(1)
 m.chakra=5
 assert(press(c3,m,"Attack",side(m,1)))
 assert(m.attackName=="Light2","with nothing to pay for a clone the side route is "..tostring(m.attackName))
end)
test("toward after two hits: the Uzumaki Barrage — a clone kicks the body up, two more keep it there, E then heavy is NARUTO RENDAN",function()
 local c,a,b=opened(2)
 assert(press(c,a,"Attack",toward(a)),"the launcher route was refused")
 assert(a.attackName=="UzumakiKick","toward after two hits gave "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Launched" end,"the clone did not launch the body")
 assert(ev(a,"UzumakiBarrage")==1 and (a.lionUntil or 0)>c.now,"the barrage window did not open")
 assert(a.pursuitUntil>c.now,"no chase after the launch")
 local health=b.health
 until_(c,.7,function() return ev(a,"BarrageKick")>=2 end,"the barrage clones did not kick the body up")
 assert(b.health<health,"the barrage kicks did no damage")
 assert(b.airborne and (b.reaction=="Juggled" or b.reaction=="Launched"),"the barrage let the body fall")
 assert(press(c,a,"Pursuit"),"no chase after the barrage")
 until_(c,1,function() return a.state~="Pursuit" end,"the chase never arrived")
 assert(a.airborne,"the chase did not take him up to the body")
 assert(press(c,a,"Heavy"),"the air heavy was refused")
 assert(a.attackName=="Slam" and a.attackVariant=="NarutoRendan","the air heavy after the barrage was "..tostring(a.attackVariant))
 local before=b.health
 until_(c,1.2,function() return b.health<before end,"Naruto Rendan never landed")
 -- (Five hits in, combo scaling leaves about half of its 18: still the route's biggest blow.)
 assert(before-b.health>=8,string.format("Naruto Rendan was light (%.1f)",before-b.health))
 until_(c,.8,function() return b.reaction=="Knockdown" end,"Naruto Rendan did not drive the body down")
 assert(#clones(c,a,true)==0,"barrage clones outlived the barrage")
 -- Heavy after two hits is the same barrage.
 local c2,x=opened(2)
 assert(press(c2,x,"Heavy"));assert(x.attackName=="UzumakiKick","heavy after two hits is "..tostring(x.attackName))
 -- No clone and no chakra for one: the plain rising kick.
 local c3,m=opened(2);m.chakra=4
 assert(press(c3,m,"Attack",toward(m)));assert(m.attackName=="Launcher","with nothing to pay the launcher route is "..tostring(m.attackName))
end)
test("away after two hits: his own tackle into the legs, no clone",function()
 local c,a,b=opened(2)
 assert(press(c,a,"Attack",-toward(a)))
 assert(a.attackName=="Tackle","away after two hits gave "..tostring(a.attackName))
 until_(c,.6,function() return b.reaction=="Knockdown" end,"the tackle did not take the legs")
 assert(#clones(c,a,true)==0,"the tackle made a clone")
 local c2,x=opened(1)
 assert(press(c2,x,"Heavy"));assert(x.attackName=="Headbutt","heavy after one hit is "..tostring(x.attackName))
end)
-- Rasengan: a two-body technique ----------------------------------------------------
test("Rasengan with a clone out: the clone comes to his side and shapes it through the channel, then the thrust lands",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,8)
 local clone=still(c,a,a.root.Position+side(a,-1)*5)
 local chakra=a.chakra
 assert(press(c,a,slot(a,"CloneRasengan"),nil,b.root.Position),"the Rasengan was refused")
 assert(math.abs(chakra-a.chakra-22)<.01,string.format("the Rasengan with a clone out cost %.1f",chakra-a.chakra))
 assert(a.state=="TechniqueChannel" and math.abs((a.untilTime-c.now)-.45)<.02,"the channel is not the clone's")
 assert(clone.mode=="shape" and clone.cast=="RasenganShape","the clone out did not come to shape it")
 H.step(c,.2)
 local right=flat(a.root.CFrame.RightVector).Unit
 assert((clone.position-(a.root.Position+right*1.9)).Magnitude<1.6,"the shaping clone is not at his hand")
 local health=b.health
 until_(c,.8,function() return b.health<health end,"the Rasengan never landed")
 assert(health-b.health>=18,string.format("the Rasengan was light (%.1f)",health-b.health))
 until_(c,.4,function() return b.reaction=="Knockback" end,"the Rasengan did not drive the body away")
 assert(a.attackVariant=="Rasengan" and ev(a,"Rasengan")==1,"the thrust was not reported as the Rasengan")
 until_(c,.6,function() return not clone.alive end,"the shaping clone stayed after the release")
end)
test("strike the shaping clone and the Rasengan falls apart; with no clone he makes one (34 chakra, a longer channel)",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,9)
 local chakra=a.chakra
 assert(press(c,a,slot(a,"CloneRasengan"),nil,b.root.Position),"the solo Rasengan was refused")
 assert(math.abs(chakra-a.chakra-34)<.01,string.format("the Rasengan with no clone cost %.1f",chakra-a.chakra))
 assert(math.abs((a.untilTime-c.now)-.6)<.02,"no longer channel without a clone")
 local shaper=clones(c,a,true)[1]
 assert(shaper and shaper.ephemeral and shaper.mode=="shape","no clone was made to shape it")
 H.step(c,.15)
 -- A kunai into the shaping clone before the release.
 c:projectile(b,shaper.position,90,30,3,"kunai",nil,{origin=b.root.Position+V.new(0,0,0)})
 until_(c,.4,function() return not shaper.alive end,"the kunai missed the shaping clone")
 assert(a.state~="TechniqueChannel" and a.pending==nil,"the Rasengan kept channelling without its clone")
 assert(ev(a,"RasenganBroken")==1 and #impacts(c,"rasengan","broken")==1,"the broken Rasengan was not reported")
 local health=b.health
 H.step(c,.8)
 assert(b.health==health and ev(a,"Rasengan")==0,"a Rasengan came out without its clone")
 assert((a.cooldowns.CloneRasengan or 0)>c.now,"a broken Rasengan kept its cooldown free")
 -- Not enough chakra to make a clone for it, and none out: refused.
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,8);x.chakra=30
 local ok=press(c2,x,slot(x,"CloneRasengan"),nil,y.root.Position)
 assert(not ok and x.chakra==30,"a Rasengan with no clone and 30 chakra was allowed")
end)
-- Tool: the transformed kunai -------------------------------------------------------
test("the chakra chord on his kunai: near the target it turns back into a clone that strikes from there (12 + 4 chakra)",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,18)
 local chakra=a.chakra
 assert(press(c,a,"Tool",nil,b.root.Position+side(a,1)*3,{chakra=true}),"the clone kunai was refused")
 assert(math.abs(chakra-a.chakra-16)<.01,string.format("the clone kunai cost %.1f",chakra-a.chakra))
 until_(c,.3,function() return #c.projectiles==1 end,"no kunai left his hand")
 assert(c.projectiles[1].transform=="clone","the kunai does not carry the transformation")
 local health=b.health
 until_(c,1,function() return #clones(c,a)==1 end,"the kunai never turned into a clone")
 assert(#c.projectiles==0,"the kunai flew on after turning into a clone")
 assert(#impacts(c,"body","transform")==1,"the client was not told the kunai became a clone")
 until_(c,.6,function() return b.health<health end,"the clone from the kunai never struck")
 assert(math.abs(b.hitAngle or 0)>40,string.format("the clone's blow was judged from Naruto (hit angle %.0f)",b.hitAngle or 0))
 -- Two clones already out: the chord only reinforces the kunai (no third clone).
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,18)
 still(c2,x,x.root.Position+side(x,1)*3);still(c2,x,x.root.Position+side(x,-1)*3)
 assert(press(c2,x,"Tool",nil,y.root.Position,{chakra=true}))
 until_(c2,.3,function() return #c2.projectiles==1 end,"no kunai with two clones out")
 local p=c2.projectiles[1]
 assert(p.transform==nil and p.infusion=="Reinforce","with two clones out the chord gave "..tostring(p.infusion))
 -- The plain tool is a plain kunai.
 local c3,m,n=H.duel("Legion","Mirage");place(c3,m,n,18)
 assert(press(c3,m,"Tool",nil,n.root.Position))
 until_(c3,.3,function() return #c3.projectiles==1 end,"no plain kunai")
 assert(c3.projectiles[1].transform==nil and c3.projectiles[1].kind=="kunai","the plain tool is not a kunai")
end)
-- Defence: the swap -----------------------------------------------------------------
test("substitution with a clone out: \"it was a clone!\" — he swaps places with it, the clone puffs where he was hit",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b)
 local clone=still(c,a,a.root.Position+side(a,1)*10)
 local spot=clone.position
 assert(press(c,b,"Attack"))
 until_(c,.5,function() return a.reaction~=nil end,"fixture: Itachi's jab never landed")
 local from=a.root.Position
 assert(c:request(a,"Substitute"),"the substitution was refused")
 assert((flat(a.root.Position-spot)).Magnitude<1,"he did not take the clone's place")
 assert(not clone.alive,"the clone survived the swap")
 local swapped=false
 for _,impact in impacts(c,"body","swap") do if (impact.position-from).Magnitude<1 then swapped=true end end
 assert(swapped,"the clone did not puff where he was hit")
 local mode=nil
 for _,impact in impacts(c,"substitute") do if impact.owner==a.id then mode=impact.mode end end
 assert(mode=="clone","the substitution was drawn as "..tostring(mode))
 -- No clone out: the common hop (and its log).
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y)
 assert(press(c2,y,"Attack"))
 until_(c2,.5,function() return x.reaction~=nil end,"fixture: no hit")
 assert(c2:request(x,"Substitute"))
 local hop=nil
 for _,impact in impacts(c2,"substitute") do if impact.owner==x.id then hop=impact.mode end end
 assert(hop=="hop","with no clone the substitution was "..tostring(hop))
end)
-- The clones' own behaviour ---------------------------------------------------------------
test("a clone out goes to the opponent's flank and jabs when he is open, judged from its side; never while he swings",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,10)
 assert(press(c,a,slot(a,"ShadowClone")))
 until_(c,.5,function() return #clones(c,a)==1 end,"no clone")
 local clone=clones(c,a)[1]
 assert(clone.mode=="flank","a clone made 10 studs from the opponent stayed at his side ("..clone.mode..")")
 local health=b.health
 until_(c,2.5,function() return b.health<health end,"the flanking clone never jabbed")
 local line=flat(a.root.Position-b.root.Position).Unit
 local at=flat(clone.position-b.root.Position)
 assert(at.Magnitude<6.5 and math.abs(at.Unit:Dot(line))<.6,"the clone did not strike from a flank")
 assert(ev(a,"CloneJab")>=1,"the jab was not counted")
 -- Never into a swing: an opponent in his own startup is left alone.
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,10)
 local flanker=Bodies.spawn(c2,x,{kind="clone",position=y.root.Position+side(y,1)*3,mode="flank",side=1,delay=0})
 y.state="Startup";y.untilTime=c2.now+9;y.pending={kind="Brawl",name="Light1",spec=H.Attacks.Light1}
 H.step(c2,.6)
 assert(flanker.state=="Neutral" and y.health==y.def.Health,"a clone jabbed into the opponent's swing")
 -- Far from the opponent it stays at Naruto's side (a decoy, a partner).
 local c3,m,n=H.duel("Legion","Mirage");place(c3,m,n,30)
 assert(press(c3,m,slot(m,"ShadowClone")))
 until_(c3,.5,function() return #clones(c3,m)==1 end,"no clone")
 H.step(c3,.6)
 local guard=clones(c3,m)[1]
 assert(guard.mode=="guard" and (guard.position-m.root.Position).Magnitude<4.5,"a clone made far away left his side")
end)
test("Multi Shadow Clone: two clones burst out on both sides and charge; refused in the cap",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,14)
 assert(press(c,a,slot(a,"MassShadowClone")),"Multi Shadow Clone refused")
 until_(c,.6,function() return #clones(c,a)==2 end,"the two clones did not come out")
 local pair=clones(c,a)
 assert(pair[1].mode=="flank" and pair[2].mode=="flank" and pair[1].side~=pair[2].side,"the clones did not charge both flanks")
 local health=b.health
 until_(c,2,function() return b.health<health end,"the charging clones never struck")
 H.step(c,10)
 still(c,a,a.root.Position+side(a,1)*3);still(c,a,a.root.Position+side(a,-1)*3)
 local ok=press(c,a,slot(a,"MassShadowClone"))
 assert(not ok,"Multi Shadow Clone made clones past the cap")
end)
-- Awakening: the Nine-Tails chakra ------------------------------------------------
test("the Nine-Tails chakra: only under 35%; the clones burst, no clone comes back, the clone routes become claws",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,10)
 still(c,a,a.root.Position+side(a,1)*3);still(c,a,a.root.Position+side(a,-1)*3)
 assert(not c:request(a,"Awaken"),"the cloak came at full health")
 a.health=a.def.Health*.3;a.hum.Health=a.health
 assert(c:request(a,"Awaken"),"the cloak was refused under 35%")
 H.step(c,.05)
 assert(#clones(c,a,true)==0,"the clones survived the Nine-Tails chakra")
 assert(#impacts(c,"body","cloak")==2,"the clones did not burst in the cloak")
 H.step(c,.5)
 local ok=press(c,a,slot(a,"ShadowClone"))
 assert(not ok and #clones(c,a,true)==0,"a clone was made in the cloak")
 -- Clone routes become his own claws: no clone, no chakra for one.
 place(c,a,b,4.5);b.health=b.def.Health
 assert(press(c,a,"Attack"));chain(c,a,"cloak Light1")
 local chakra=a.chakra
 assert(press(c,a,"Attack",side(a,1)))
 assert(a.attackName=="ClawSwipe","the cloak's side route is "..tostring(a.attackName))
 assert(#clones(c,a,true)==0 and a.chakra>=chakra-.01,"the claw made (or paid) a clone")
 local spec=a.pending.spec
 assert(spec.range>=9.5,"the chakra claw does not reach further")
end)
test("in the cloak the Rasengan needs no clone and almost no wind-up; his recoveries are quicker",function()
 local function awake(c,a) a.health=a.def.Health*.3;a.hum.Health=a.health;assert(c:request(a,"Awaken"));H.step(c,.5);a.chakra=a.def.Chakra end
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,8)
 -- (The awakening's shockwave throws the opponent away: back in reach.)
 awake(c,a);place(c,a,b,8);b.reaction=nil;b.state="Neutral"
 local chakra=a.chakra
 assert(press(c,a,slot(a,"CloneRasengan"),nil,b.root.Position),"the cloak's Rasengan was refused")
 assert(a.untilTime-c.now<=.21,"the cloak's Rasengan kept a long channel")
 assert(chakra-a.chakra<=22.01 and #clones(c,a,true)==0,"the cloak's Rasengan paid for a clone")
 local health=b.health
 until_(c,.8,function() return b.health<health end,"the cloak's Rasengan never landed")
 -- Recovery: the same light recovers quicker in the cloak.
 local function recovery(cloak)
  local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,20)
  if cloak then awake(c2,x);place(c2,x,y,20) end
  assert(press(c2,x,"Attack"))
  until_(c2,.6,function() return x.state=="Recovery" end,"no recovery")
  return x.untilTime-c2.now
 end
 local plain,quick=recovery(false),recovery(true)
 assert(quick<plain*.85,string.format("the cloak did not quicken the recovery (%.2f vs %.2f)",quick,plain))
end)
-- Re-engage --------------------------------------------------------------------------
test("re-engage: his own entry on an angle whose side does not simply alternate; a clone out rushes the other side",function()
 local sides={}
 local c,a,b=H.duel("Legion","Mirage")
 for k=1,6 do
  place(c,a,b,24);a.locked=true;a.chakra=a.def.Chakra;a.rushReadyAt=0;a.state="Neutral";a.untilTime=c.now
  assert(press(c,a,"Pursuit"),"dash "..k.." refused")
  table.insert(sides,a.rush.side)
  until_(c,1,function() return a.state~="Rush" end,"dash "..k.." never ended")
  H.step(c,.4)
 end
 local alternating=true
 for k=2,#sides do if sides[k]==sides[k-1] then alternating=false end end
 assert(not alternating,"the entry side simply alternates: "..table.concat(sides,","))
 local seen=false
 for _,impact in c.impacts do if impact.style=="chase" and impact.owner==a.id and impact.variant=="legion" then seen=true end end
 assert(seen,"his re-engage style was not reported to the client")
 -- The pincer: a flanking clone rushes the other side while he dashes in.
 local c2,x,y=H.duel("Legion","Mirage");place(c2,x,y,24);x.locked=true
 local flanker=Bodies.spawn(c2,x,{kind="clone",position=y.root.Position+side(y,1)*5,mode="flank",side=1,delay=9})
 assert(press(c2,x,"Pursuit"))
 H.step(c2,.08)
 assert(flanker.pincer,"the clone did not join the dash")
 local health=y.health
 until_(c2,1,function() return y.health<health end,"the pincer clone never struck")
end)
-- Other fighters against the clones ------------------------------------------------
test("other fighters: Neji's Rotation sweeps clones away, each clone blow costs Gaara one shield charge",function()
 local c,a,b=H.duel("Legion","GentleFist");place(c,a,b,10)
 local near=still(c,a,b.root.Position+side(b,1)*4)
 local far=still(c,a,b.root.Position+side(b,1)*12)
 local rotation
 for i,t in b.def.Techniques do if t.Id=="Rotation" then rotation="Technique"..i end end
 assert(c:request(b,rotation))
 until_(c,.4,function() return not near.alive end,"Rotation left a clone standing inside the dome")
 assert(far.alive,"Rotation reached a clone far outside the dome")
 -- Gaara: a clone's jab spends one charge, it does not break the shield.
 local c2,x,y=H.duel("Legion","Sand");place(c2,x,y,10)
 local flanker=Bodies.spawn(c2,x,{kind="clone",position=y.root.Position+side(y,1)*3.5,mode="flank",side=1,delay=0})
 local charges=y.shieldCharges
 until_(c2,1,function() return y.shieldCharges<charges end,"the clone's jab never met the sand")
 assert(y.shieldCharges==charges-1 and y.health==y.def.Health,"a clone's jab broke the shield or got through it")
 assert(flanker.alive,"the shield dispelled the clone")
 -- Any awakening's shockwave blows away the clones close to the one awakening.
 local c3,m,n=H.duel("Legion","Lion");place(c3,m,n,12)
 local close=still(c3,m,n.root.Position+side(n,1)*5)
 local away=still(c3,m,n.root.Position+side(n,1)*14)
 n.health=n.def.Health*.3;n.hum.Health=n.health
 assert(c3:request(n,"Awaken"),"Sasuke's awakening was refused")
 assert(not close.alive and away.alive,"the awakening's shockwave did not clear only the close clone")
end)
test("the snapshot lists his live clones for the clients: owner, fighter, place, facing, action; the fighters stay two",function()
 local Matches=H.load("Server/Matches")
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,10)
 local clone=still(c,a,a.root.Position+side(a,1)*3)
 local gone=still(c,a,a.root.Position+side(a,-1)*3)
 Bodies.dispel(c,gone,"hit",b)
 local s={combat=c,epoch=1,phase="Duel",origin=V.zero,round=1,wins={},roundsToWin=1}
 local view=Matches.view(Matches,s,s,a,b)
 assert(view.human.id==a.id and view.bot.id==b.id,"the snapshot's fighters are not the two actors")
 assert(type(view.bodies)=="table" and #view.bodies==1,"the snapshot does not list exactly the live clone")
 local entry=view.bodies[1]
 assert(entry.id==clone.id and entry.owner==a.id and entry.fighterId=="Legion" and entry.kind=="clone","the clone's entry is wrong")
 assert((entry.position-clone.position).Magnitude<.01 and entry.look and entry.state=="Neutral" and entry.ephemeral==false,"the clone's place or state is missing")
 -- Seen from the other side (online) the same list: the clone is still his.
 local other=Matches.view(Matches,s,{},b,a)
 assert(#other.bodies==1 and other.bodies[1].owner==a.id,"the other side sees a different list")
end)
test("clean-up: the round's end and a KO take every clone away; a clone never outlives its owner",function()
 local c,a,b,match=H.duel("Legion","Mirage");place(c,a,b,12)
 still(c,a,a.root.Position+side(a,1)*3)
 c:clear(true)
 assert(#(c.bodies or {})==0 and #Bodies.view(c)==0,"a clone survived the round's end")
 -- A KO of Naruto ends the duel: the harness clears it all.
 local c2,x,y,m2=H.duel("Legion","Mirage");place(c2,x,y,5)
 still(c2,x,x.root.Position+side(x,1)*3)
 x.health=2;x.hum.Health=2
 assert(press(c2,y,"Attack"))
 until_(c2,.6,function() return m2.phase~="Duel" end,"the KO did not end the duel")
 assert(#(c2.bodies or {})==0,"a clone survived its owner's KO")
 -- Owner down while the duel goes on (the KO beat): his clones go.
 local c3,m,n=H.duel("Legion","Mirage");place(c3,m,n,12)
 local orphan=still(c3,m,m.root.Position+side(m,1)*3)
 m.health=0
 Bodies.step(c3,.01)
 assert(not orphan.alive,"a clone outlived its owner")
end)
-- AI ---------------------------------------------------------------------------------
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
local low={NextNumber=function(_,x,y) if x and y then return x end return .05 end}
local function bot(AI,c,a,seed,rng)
 local b=a.target
 local x=AI.new(c,a,seed);x.rng=rng or low;x.probing=false;x.modeUntil=c.now+30;x.observed=b.state;x.observedAt=c.now-1
 return x
end
test("the AI uses his kit: clones in neutral, the Rasengan with a clone out, the barrage into Naruto Rendan, the transformed kunai",function()
 local AI=H.load("Server/AI")
 -- (A mid roll: a jutsu roll, no toe-to-toe guard, no probing throw.)
 local mid={NextNumber=function(_,x,y) if x and y then return x end return .2 end}
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,12)
 local x=bot(AI,c,a,3,mid)
 for _=1,60 do x:update(c.now);H.step(c,.02);if ev(a,"ShadowClone")+ev(a,"MassShadowClone")>0 then break end end
 assert(ev(a,"ShadowClone")+ev(a,"MassShadowClone")>0,"the bot never made a clone")
 -- Two clones out at Rasengan range: it calls one to shape the Rasengan.
 local c2,m,n=H.duel("Legion","Mirage");place(c2,m,n,6)
 still(c2,m,m.root.Position+side(m,1)*3);still(c2,m,m.root.Position+side(m,-1)*3)
 local y=bot(AI,c2,m,5,mid)
 for _=1,60 do y:update(c2.now);H.step(c2,.02);if m.castId=="CloneRasengan" then break end end
 assert(m.castId=="CloneRasengan","the bot never used the Rasengan with its clones out")
 -- Two hits in, the barrage, the chase and Naruto Rendan.
 local c3,p,q=opened(2)
 assert(press(c3,p,"Attack",toward(p)))
 local z=bot(AI,c3,p,9,{NextNumber=function(_,x,y) if x and y then return x end return .5 end})
 for _=1,150 do
  z:update(c3.now);H.step(c3,.01)
  if ev(p,"NarutoRendan")>0 then break end
 end
 assert(ev(p,"NarutoRendan")>0,"the bot never brought Naruto Rendan down after the barrage (air hits "..ev(p,"AirHit")..")")
 -- Probing at range (beyond the step-in feints): the third throw is the
 -- transformed kunai.
 local c4,r,s=H.duel("Legion","Mirage");place(c4,r,s,22)
 local w=bot(AI,c4,r,11);w.techReadyAt=c4.now+60;w.probing=true;w.probeRange=16
 for _=1,200 do w:update(c4.now);H.step(c4,.02);if ev(r,"CloneKunai")>0 then break end end
 assert(ev(r,"CloneKunai")>0,"the bot never threw the transformed kunai")
end)
test("every fighter's AI answers a clone: one winding up at its side is struck first, the target stays the real Naruto",function()
 local AI=H.load("Server/AI")
 for _,id in {"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf"} do
  local c,a,b=H.duel("Legion",id);place(c,a,b,10)
  local flanker=Bodies.spawn(c,a,{kind="clone",position=b.root.Position+side(b,1)*3.4,mode="flank",side=1,delay=0})
  local x=bot(AI,c,b,7)
  for _=1,80 do x:update(c.now);H.step(c,.02);if not flanker.alive then break end end
  assert(not flanker.alive,id..": the AI never struck the clone at its side")
  assert(b.target==a,id..": the AI's target moved off the real Naruto")
 end
end)
test("AI duels: Naruto against every fighter, both ways, to the KO and without wedging; clones made and dispelled",function()
 seeded(function()
  local AI=H.load("Server/AI")
  local opponents={"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf"}
  local made,lost,dispelled,routes,rendan=0,0,0,0,0
  for k,other in opponents do
   for _,pair in {{"Legion",other},{other,"Legion"}} do
    local c,a,b,match=H.duel(pair[1],pair[2])
    place(c,a,b,14)
    local one,two=AI.new(c,a,k*5+1),AI.new(c,b,k*5+3)
    local stuck={}
    local t=0
    local most=0
    while match.phase=="Duel" and t<150 do
     one:update(c.now);two:update(c.now);H.step(c,.01);t+=.01
     for _,x in {a,b} do
      -- A wedge is one state (and one swing) that never ends; a long legal
      -- sequence (a barrage into Naruto Rendan) is not.
      local key=x.state..":"..tostring(x.attackSerial or 0)..":"..tostring(x.castId)
      if x.state=="Neutral" or x.state=="Guarding" or key~=(stuck[x] and stuck[x].key) then stuck[x]={key=key,t=0} else stuck[x].t+=.01 end
      assert(stuck[x].t<2.5,pair[1].." vs "..pair[2]..": "..x.fighterId.." wedged in "..x.state)
      assert(x.health==x.health and x.root.Position.Y==x.root.Position.Y,pair[1].." vs "..pair[2]..": non-finite state")
     end
     local naruto=if a.fighterId=="Legion" then a else b
     most=math.max(most,#Bodies.of(c,naruto,"clone"))
     for _,body in c.bodies or {} do
      assert(body.owner==naruto,"a body belongs to "..body.owner.fighterId)
      assert(body.position==body.position,"a clone's position went non-finite")
     end
    end
    assert(match.phase~="Duel",string.format("%s vs %s did not finish in 150 s (%.0f / %.0f health)",pair[1],pair[2],a.health,b.health))
    assert(most<=2,pair[1].." vs "..pair[2]..": "..most.." clones out at once")
    for _,x in {a,b} do
     if x.fighterId=="Legion" then
      made+=ev(x,"BodySpawned");lost+=ev(x,"BodyLost");routes+=ev(x,"Route");rendan+=ev(x,"NarutoRendan")
     else dispelled+=ev(x,"BodyDispelled") end
    end
    print(string.format("   %s vs %s: %.1f s, winner %s",pair[1],pair[2],t,tostring(match.winner)))
   end
  end
  assert(made>=12,"Naruto's bot barely made clones ("..made..")")
  assert(dispelled>=3,"his opponents barely dispelled clones ("..dispelled..")")
  assert(routes>=6,"Naruto's bot barely used his routes ("..routes..")")
  print(string.format("   clones made %d, lost %d, dispelled by opponents %d, routes %d, Naruto Rendan %d",made,lost,dispelled,routes,rendan))
 end)
end)
test("tutorial: the interrupt step gives Naruto readable hand signs (his Rasengan keeps the long channel)",function()
 local Tutorial=H.load("Server/Tutorial")
 local c,a,b=H.duel("Mirage","Legion")
 b.trainingChannelScale=3
 assert(c:request(b,Tutorial.interruptSlot(b),a.root.Position),"the tutorial jutsu was refused")
 assert(b.state=="TechniqueChannel" and b.untilTime-c.now>=.74,string.format("Naruto's signs last %.2f s",b.untilTime-c.now))
end)

-- Client -------------------------------------------------------------------------------
local Motion=H.load("Client/VelmoraMotionEngine")
local C=H.C
local function snapshot(model)
 local out={}
 for key,joint in model.joints do out[key]=joint.Transform end
 return out
end
local function differ(x,y,eps)
 local n=0
 for key,t in x do if not t:FuzzyEq(y[key],eps or .03) then n+=1 end end
 return n
end
local function body(actor,overrides)
 local out={fighterId=actor.fighterId,state="Neutral",health=actor.health,attackElapsed=0,reactionElapsed=0,airborne=false,
  velocity=V.zero,speed=0,hitAngle=0,hitStrength=.5,landing=false}
 for k,v in overrides or {} do out[k]=v end
 return out
end
local function present(model,actor,frames)
 Motion.reset(model)
 local clock={attackElapsed=actor.attackElapsed or 0,reactionElapsed=0}
 for _=1,frames or 45 do Motion.tick(1/60);Motion.present(model,actor,clock,1/60) end
 return snapshot(model)
end
test("motion family: his own stance, gait, intro and string — he stands, walks and punches like neither Minato nor Sasuke",function()
 local family=Motion.familyOf("Legion")
 assert(family.body=="Legion" and family.intro=="Legion" and family.weapons=="palms","Naruto's motion family is "..tostring(family.body))
 local c,a=H.duel("Legion","Mirage")
 local cm,m=H.duel("Flashstep","Mirage")
 local cs,s=H.duel("Lion","Mirage")
 local naruto,minato,sasuke=present(a.model,body(a)),present(m.model,body(m)),present(s.model,body(s))
 assert(differ(naruto,minato)>=4,"Naruto stands like Minato ("..differ(naruto,minato).." joints differ)")
 assert(differ(naruto,sasuke)>=4,"Naruto stands like Sasuke ("..differ(naruto,sasuke).." joints differ)")
 local walk={velocity=V.new(0,0,-12),speed=12}
 assert(differ(present(a.model,body(a,walk)),present(m.model,body(m,walk)))>=4,"Naruto walks like Minato")
 assert(differ(present(a.model,body(a,walk)),present(s.model,body(s,walk)))>=4,"Naruto walks like Sasuke")
 assert(differ(present(a.model,body(a,{intro=1})),present(m.model,body(m,{intro=1})))>=4,"Naruto's intro is Minato's kunai twirl")
 local function key1(x,fighter,name)
  Motion.reset(x.model)
  for _=1,40 do Motion.pose(x.model,name,.12,fighter,1/60) end
  return snapshot(x.model)
 end
 for _,name in {"Light1","Light2","Light3","Heavy"} do
  assert(differ(key1(a,"Legion",name),key1(m,"Flashstep",name))>=3,name.." is Minato's")
  assert(differ(key1(a,"Legion",name),key1(s,"Lion",name))>=3,name.." is Sasuke's")
 end
 -- No blade in his hands for his string (the kunai only shows to be thrown:
 -- the "palms" weapon family, Neji's rule; its model needs Studio).
 for _,name in {"Light1","Light2","Light3","Headbutt"} do
  Motion.weapon(a.model,body(a,{attackName=name,state="Active",attackElapsed=.1}))
  assert(not Motion.weaponState(a.model).visible,"a blade showed for "..name)
 end
end)
test("his clips: the clones' side of each route is a strike, his side is not; the seal, the shaping clone, the cloak's claws",function()
 local c,a=H.duel("Legion","Mirage")
 local function key1(name)
  Motion.reset(a.model)
  for _=1,40 do Motion.pose(a.model,name,.12,"Legion",1/60) end
  return snapshot(a.model)
 end
 for _,pair in {{"CloneKickStrike","CloneKick"},{"UzumakiRise","UzumakiKick"}} do
  assert(Motion.VARIANT_OF[pair[1]]==pair[2],pair[1].." does not ride on "..pair[2])
  assert(differ(key1(pair[1]),key1(pair[2]))>=4,"the clone's "..pair[1].." looks like Naruto's own side of it")
 end
 assert(Motion.VARIANT_OF.NarutoRendan=="Slam","Naruto Rendan does not ride on the slam")
 assert(differ(key1("NarutoRendan"),key1("Slam"))>=4,"Naruto Rendan looks like the plain slam")
 assert(differ(key1("ClawSwipe"),key1("Light1"))>=3 and differ(key1("ClawRise"),key1("Launcher"))>=3,"the cloak's claws are plain strikes")
 local seal=present(a.model,body(a,{state="TechniqueChannel",castId="ShadowClone",castElapsed=.05}))
 local generic=present(a.model,body(a,{state="TechniqueChannel",castId="SomeUnknownJutsu",castElapsed=.05}))
 assert(differ(seal,generic)>=3,"the Shadow Clone seal is the generic hand-sign cycle")
 local hold=present(a.model,body(a,{state="TechniqueChannel",castId="CloneRasengan",castElapsed=.1}))
 local shape=present(a.model,body(a,{state="TechniqueChannel",castId="RasenganShape",castElapsed=.1}))
 assert(differ(hold,shape)>=3,"the clone shaping the Rasengan stands like Naruto holding it")
end)
-- Largest single-frame joint change between two snapshots, in degrees.
local AXIS_X=H.roblox.CFrame.identity.RightVector
local AXIS_Y=H.roblox.CFrame.identity.UpVector
local function axisAngles(cf)
 local x=cf:VectorToObjectSpace(AXIS_X)
 local y=cf:VectorToObjectSpace(AXIS_Y)
 return math.acos(math.clamp(x.X,-1,1)),math.acos(math.clamp(y.Y,-1,1))
end
local function maxDelta(x,y)
 local worst,where=0,""
 for key,t in x do
  local x1,y1=axisAngles(t)
  local x2,y2=axisAngles(y[key])
  local d=math.deg(math.max(math.abs(x1-x2),math.abs(y1-y2)))
  if d>worst then worst,where=d,key end
 end
 return worst,where
end
local function tiltOf(joint)
 local _,angle=joint.Transform:ToAxisAngle()
 return math.abs(angle)
end
test("every one of his strikes and his clones' stays finite and inside the joint limits through its timeline",function()
 local c,a=H.duel("Legion","Mirage")
 local names={"NarutoRendan","CloneKickStrike","UzumakiRise","MirrorStrike","Rasengan"}
 for _,name in {"Light1","Light2","Light3","Heavy","Headbutt","Tackle","CloneKick","UzumakiKick","MirrorClone","ClawRise","ClawSwipe","CloneJab","BarrageKick","DashAttack","Air1","Air2","Slam","Launcher"} do table.insert(names,name) end
 for _,name in names do
  Motion.reset(a.model)
  for step=0,40 do
   Motion.pose(a.model,name,step*.03,"Legion",1/60)
   for key,joint in a.model.joints do
    local x,y,z=joint.Transform:ToOrientation()
    assert(x==x and y==y and z==z,name.." non-finite at "..step)
   end
  end
  for key,joint in a.model.joints do
   assert(tiltOf(joint)<math.pi*1.4,name.." left "..key.." at "..string.format("%.0f",math.deg(tiltOf(joint))).." deg")
  end
 end
end)
test("his whole kit presents without a snap: string, clone routes, barrage, Rendan, seal, Rasengan, swap, cloak",function()
 local c,a,b=H.duel("Legion","Mirage")
 local clock={attackAt=0,reactionAt=0,attackElapsed=0,reactionElapsed=0}
 local previous,worst,worstAt=nil,0,""
 local seen={}
 local function frame()
  local velocity=a.root.AssemblyLinearVelocity
  local visual=body(a,{velocity=velocity,speed=velocity.Magnitude,attackName=a.attackName,attackVariant=a.attackVariant,attackSerial=a.attackSerial,
   state=a.state,reaction=a.reaction,airborne=a.airborne,groundPose=a.groundPose,castId=a.castId,castElapsed=c.now-(a.castStarted or c.now),
   awaken=math.max(0,(a.awakenUntil or 0)-c.now),hitAngle=a.hitAngle or 0,hitStrength=a.hitStrength or .4})
  Motion.tick(1/60)
  local phase=Motion.present(a.model,visual,clock,1/60)
  seen[phase]=(seen[phase] or 0)+1
  local current=snapshot(a.model)
  if previous then
   local d,joint=maxDelta(previous,current)
   if d>worst then worst=d;worstAt=string.format("%s %s @%s/%s/%s",phase,joint,a.state,tostring(a.attackName),tostring(a.attackVariant)) end
  end
  previous=current
 end
 local function advance(seconds)
  for _=1,math.ceil(seconds/.01) do
   c:update(.01,c.now+.01)
   local name=a.attackName and (a.attackName..":"..tostring(a.attackSerial or 0))
   if clock.attackName~=name then clock.attackName=name;clock.attackAt=c.now end
   clock.attackElapsed=if a.attackName then c.now-clock.attackAt else 0
   if clock.reaction~=a.reaction then clock.reaction=a.reaction;clock.reactionAt=c.now end
   clock.reactionElapsed=if a.reaction then c.now-clock.reactionAt else 0
   frame()
  end
 end
 local function reset(gap)
  place(c,a,b,gap or 4.5)
  for _,x in {a,b} do
   x.health=x.def.Health;x.hum.Health=x.health;x.reaction=nil;x.state="Neutral";x.untilTime=c.now;x.pending=nil;x.attackName=nil;x.airborne=false
   -- (No wake-up cover left over from the tackle's knockdown.)
   x.groundPose=nil;x.invulnerableUntil=0;x.comboHits=0
  end
  b.cooldowns={};a.cooldowns={};a.chakra=a.def.Chakra
 end
 a.move=V.new(1,0,0);advance(.4);a.move=V.zero;advance(.3)
 reset()
 still(c,a,a.root.Position+side(a,1)*3)
 press(c,a,"Attack");advance(.32);press(c,a,"Attack");advance(.32);press(c,a,"Attack");advance(.7)
 reset()
 press(c,a,"Attack");advance(.32);press(c,a,"Attack",side(a,1));advance(.5);press(c,a,"Attack",-toward(a));advance(.8)
 reset()
 press(c,a,"Attack");advance(.32);press(c,a,"Attack");advance(.32);press(c,a,"Attack",toward(a));advance(.5)
 press(c,a,"Pursuit");advance(.5);press(c,a,"Heavy");advance(1.4)
 reset(14)
 press(c,a,"Technique1",nil,b.root.Position);advance(.6)
 reset(8)
 press(c,a,"Technique2",nil,b.root.Position);advance(1.2)
 reset()
 still(c,a,a.root.Position+side(a,1)*6)
 press(c,b,"Attack");advance(.12);c:request(a,"Substitute");advance(.6)
 reset(10)
 a.health=a.def.Health*.3;c:request(a,"Awaken");advance(.8)
 a.move=V.new(0,0,-1);a.sprinting=true;advance(.5);a.move=V.zero;a.sprinting=false;advance(.4)
 assert(seen.attack and seen.locomotion and seen.technique,"the fight never presented an attack, a run or a jutsu")
 for _,name in {"BodyStrike","UzumakiBarrage","NarutoRendan","ShadowClone","Rasengan","Substitute","Awaken"} do
  assert(ev(a,name)>=1,"the sequence never played "..name)
 end
 print(string.format("   worst %.1f deg/frame (%s)",worst,worstAt))
 assert(worst<39,"a snap of "..string.format("%.1f",worst).." deg/frame at "..worstAt)
end)
test("his costume builds: orange jumpsuit, blue shoulders, the spiral on the back, whiskers, spiky blond hair",function()
 local made={}
 local base=H.envBase.Instance
 H.envBase.Instance={new=function(class) local x=base.new(class);table.insert(made,x);return x end}
 local World=H.load("Server/World")
 local c,a=H.duel("Legion","Mirage")
 local ok,err=pcall(World.dress,a.model,H.fighters.Legion)
 H.envBase.Instance=base
 assert(ok,err)
 local names={}
 for _,x in made do local n=rawget(x,"Name") or x.Name;if n then names[n]=(names[n] or 0)+1 end end
 assert(names.Whisker==6,"no whiskers ("..tostring(names.Whisker)..")")
 assert(names.Spiral==1 and names.ShoulderPanel==1 and names.Collar==1,"no Part I jacket")
 assert((names.HairSpike or 0)>=12,"his hair is not spiky")
 assert(names.Headband==1,"no headband")
 assert(a.model.bones.UpperTorso.Color==H.roblox.Color3.fromRGB(244,130,36),"the jumpsuit is not his orange")
 for _,x in made do
  local material=rawget(x,"Material") or x.Material
  assert(material~=H.roblox.Enum.Material.Fabric,"a Fabric part (renders as wicker in Studio)")
 end
end)
test("he is selectable: his roster slot and both buttons, and the duel starts with him",function()
 H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim
 H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
 H.workspace.GetAttribute=function() return nil end
 local baseNew=H.envBase.Instance.new
 local saved=H.envBase.Instance
 H.envBase.Instance={new=function(class)
  local x=baseNew(class)
  x.Activated={Connect=function(_,fn) x.click=fn end}
  return x
 end}
 local ok,err=pcall(function()
  local UI=H.load("Client/UI")
  local sent={}
  local ui=UI.new(baseNew("PlayerGui"),function(action,extra) table.insert(sent,{action=action,extra=extra}) end)
  assert(ui.selectionButtons.slotLegion and ui.selectionButtons.playerLegion and ui.selectionButtons.botLegion,"Naruto is not in the roster")
  ui.selectionButtons.playerLegion.click()
  assert(ui.player=="Legion","picking Naruto did not select him")
  assert(ui.routeNote.Text:find("NARUTO",1,true),"his strings are not shown")
  ui.startButton.click()
  local last=sent[#sent]
  assert(last.action=="Start" and last.extra.player=="Legion","the start request does not carry Naruto")
 end)
 H.envBase.Instance=saved
 assert(ok,err)
end)
-- A stub rig that can be cloned (BodyViews draws a copy of the owner's model).
local function stubRig(instance,folder,id,at)
 local m=instance("Model");m.Name=id;m.Parent=folder
 local parts={}
 for _,n in {"HumanoidRootPart","LowerTorso","UpperTorso","Head","RightHand","LeftHand","RightUpperArm","LeftUpperArm","RightUpperLeg","LeftUpperLeg","RightLowerArm","LeftLowerArm","RightLowerLeg","LeftLowerLeg"} do
  local p=instance("Part");p.Name=n;p.CFrame=C.lookAt(at,at-V.zAxis);p.Size=V.new(1,1,1);p.Transparency=if n=="HumanoidRootPart" then 1 else 0;p.Parent=m
  parts[n]=p
 end
 m.PrimaryPart=parts.HumanoidRootPart
 for _,pair in {{"HumanoidRootPart","Root"},{"LowerTorso","Waist"},{"UpperTorso","Neck"},{"UpperTorso","RightShoulder"},{"UpperTorso","LeftShoulder"},
   {"RightUpperArm","RightElbow"},{"LeftUpperArm","LeftElbow"},{"RightLowerArm","RightWrist"},{"LeftLowerArm","LeftWrist"},
   {"LowerTorso","RightHip"},{"LowerTorso","LeftHip"},{"RightUpperLeg","RightKnee"},{"LeftUpperLeg","LeftKnee"},{"RightLowerLeg","RightAnkle"},{"LeftLowerLeg","LeftAnkle"}} do
  local j=instance("Motor6D");j.Name=pair[2];j.Transform=C.identity;j.Parent=parts[pair[1]]
 end
 local spiral=instance("Part");spiral.Name="Spiral";spiral.Parent=m;spiral.Transparency=0;spiral.CFrame=C.new(at);spiral.Size=V.one
 local hum=instance("Humanoid");hum.Parent=m
 local blade=instance("Model");blade.Name="Kunai";blade.Parent=parts.RightHand
 local function copy(x)
  local y=instance(x.ClassName)
  for k,v in rawget(x,"props") do y[k]=v end
  y.Name=x.Name
  for _,child in x.children do local z=copy(child);z.Parent=y end
  return y
 end
 m.Clone=function(self)
  local y=copy(self)
  y.PrimaryPart=y:FindFirstChild("HumanoidRootPart")
  y.Clone=self.Clone
  return y
 end
 return m
end
test("client: each clone is drawn as a posed copy of his own model, follows its body, and goes back to the pool",function()
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local BodyViews=H.load("Client/BodyViews")
  local clock=50;BodyViews.clock=function() return clock end
  local folder=instance("Folder")
  local naruto=stubRig(instance,folder,"A",V.new(0,3,0));stubRig(instance,folder,"B",V.new(0,3,-8))
  local views=BodyViews.new()
  local entry={id=1,owner="A",fighterId="Legion",kind="clone",position=V.new(4,3,0),look=-V.zAxis,state="Neutral",actionSerial=0,actionElapsed=0,velocity=V.zero,remaining=5,mode="flank",warp=0}
  views:update({phase="Duel",epoch=1,bodies={entry}},1/60,folder)
  local view=views.views[1]
  assert(view and view.model and view.model~=naruto,"no copy was drawn for the clone")
  assert(view.model.Name=="ShadowClone" and view.model.Parent==views.folder,"the copy is not in the bodies' folder")
  assert(view.model:FindFirstChild("Spiral"),"the copy does not wear his costume")
  assert(view.model:FindFirstChildOfClass("Humanoid")==nil,"the copy kept a Humanoid")
  assert(view.model:FindFirstChild("RightHand"):FindFirstChild("Kunai")==nil,"the copy kept a weapon from his hand")
  for _,d in view.model:GetDescendants() do
   if d:IsA("BasePart") then assert(d.CanCollide==false and d.CanQuery==false,"a copied part can collide or block the camera") end
  end
  assert(view.model.PrimaryPart.Anchored,"the copy's root is not anchored")
  assert((view.model.PrimaryPart.Position-entry.position).Magnitude<.6,"the copy does not stand where the clone is")
  -- The body runs: the copy follows on a smooth track (no jump to the new spot).
  local moved={id=1,owner="A",fighterId="Legion",kind="clone",position=V.new(8,3,0),look=-V.zAxis,state="Neutral",actionSerial=0,actionElapsed=0,velocity=V.new(30,0,0),remaining=5,mode="flank",warp=0}
  clock+=1/60
  views:update({phase="Duel",epoch=1,bodies={moved}},1/60,folder)
  local x1=view.model.PrimaryPart.Position.X
  assert(x1>4.2 and x1<7.9,string.format("the copy jumped to %.2f instead of following",x1))
  for _=1,30 do clock+=1/60;views:update({phase="Duel",epoch=1,bodies={moved}},1/60,folder) end
  assert(view.model.PrimaryPart.Position.X>7.5,"the copy never caught up with its body")
  -- Its jab poses the copy (its own clip, on its own clock).
  local rest={}
  for _,d in view.model:GetDescendants() do if d.ClassName=="Motor6D" then rest[d.Name]=d.Transform end end
  local jab={id=1,owner="A",fighterId="Legion",kind="clone",position=V.new(8,3,0),look=-V.zAxis,state="Startup",action="CloneJab",actionSerial=1,actionElapsed=0,velocity=V.zero,remaining=5,mode="flank",warp=0}
  for _=1,12 do clock+=1/60;views:update({phase="Duel",epoch=1,bodies={jab}},1/60,folder) end
  assert(view.phase=="attack","the jab was presented as "..tostring(view.phase))
  local moving=0
  for _,d in view.model:GetDescendants() do if d.ClassName=="Motor6D" and not d.Transform:FuzzyEq(rest[d.Name],.02) then moving+=1 end end
  assert(moving>=4,"the jab barely moved the copy ("..moving.." joints)")
  -- Gone: back to the pool, reused for the next clone.
  local model=view.model
  views:update({phase="Duel",epoch=1,bodies={}},1/60,folder)
  assert(views.views[1]==nil and model.Parent==nil,"the copy outlived its clone")
  views:update({phase="Duel",epoch=1,bodies={entry}},1/60,folder)
  assert(views.views[1].model==model,"the pooled copy was not reused")
  -- Back to the roster: nothing drawn.
  views:update({phase="Selection",epoch=1},1/60,folder)
  assert(next(views.views)==nil,"a clone was drawn on the roster screen")
 end)
 restore()
 assert(ok,err)
end)
test("client: a puff for every way a clone comes and goes, no log in his swap, the two-body Rasengan, the barrage call, the cloak",function()
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  local NarutoFX=H.load("Client/NarutoFX")
  local clock=70;NarutoFX.clock=function() return clock end
  local fx=FX.new()
  local folder=instance("Folder")
  local naruto=stubRig(instance,folder,"A",V.new(0,3,0));stubRig(instance,folder,"B",V.new(0,3,-8))
  for _,name in {"Iris","Iris"} do
   local p=instance("Part");p.Name=name;p.Parent=naruto;p.CFrame=C.new(0,5,0);p.Size=V.new(.1,.1,.1);p.Transparency=0;p.Color=H.roblox.Color3.fromRGB(60,130,230)
  end
  local function named(name)
   local count=0
   for _,d in fx.folder:GetDescendants() do if d.Name==name then count+=1 end end
   return count
  end
  local serial=0
  local function hit(style,extra)
   serial+=1
   local entry={style=style,position=V.new(2,3,0),owner="A",fighter="Legion",serial=serial}
   for k,v in extra or {} do entry[k]=v end
   local before=#fx.folder:GetDescendants()
   fx:impact(entry,folder)
   return #fx.folder:GetDescendants()-before
  end
  for _,phase in {"appear","hit","blade","area","expire","spent","swap","vanish","cloak","owner","transform"} do
   assert(hit("body",{kind="clone",phase=phase})>0,"a clone's "..phase.." drew no puff")
  end
  -- Another fighter's body is not his to draw.
  assert(hit("body",{kind="puppet",phase="appear",fighter="Puppeteer"})==0,"a puppet was drawn as a shadow clone")
  -- "It was a clone!": smoke, no wooden log.
  local function wood()
   local n=0
   for _,d in fx.folder:GetDescendants() do if d.Material==H.roblox.Enum.Material.Wood then n+=1 end end
   return n
  end
  local logs=wood()
  assert(hit("substitute",{mode="clone",to=V.new(10,3,0)})>0,"the swap drew nothing")
  assert(wood()==logs,"a log replaced Naruto in his clone swap")
  assert(hit("substitute",{mode="hop",to=V.new(10,3,0)})>0 and wood()>logs,"fixture: the common substitution has no log")
  assert(hit("cast",{technique="ShadowClone"})>0,"the Shadow Clone seal drew nothing")
  assert(hit("rasengan",{phase="broken"})>0 and named("RasenganBroken")==1,"a broken Rasengan drew nothing")
  assert(hit("uzumaki",{syllable="ZU"})>0 and named("UzumakiCall")>=1,"the barrage was not called out")
  -- The Rasengan forming between his palm and the clone at his side.
  local data={phase="Duel",epoch=1,hazards={},projectiles={},bodies={},
   human={id="A",fighterId="Legion",seals={},state="TechniqueChannel",castId="CloneRasengan",health=140,maxHealth=140},
   bot={id="B",fighterId="Mirage",seals={},state="Neutral",health=145,maxHealth=145}}
  fx:update(data,1/60,folder)
  assert(named("RasenganForming")==1,"no Rasengan forming in his palm")
  for _=1,6 do clock+=.04;fx:update(data,1/60,folder) end
  assert(named("RasenganWisp")>=1,"no chakra drawn in from the shaping clone")
  data.human.state="Neutral";data.human.castId=nil
  fx:update(data,1/60,folder)
  assert(named("RasenganForming")==0,"the forming Rasengan outlived the channel")
  -- Naruto Rendan: the last syllable.
  local calls=named("UzumakiCall")
  data.human.attackName="Slam";data.human.attackVariant="NarutoRendan";data.human.state="Startup";data.human.attackSerial=4
  fx:update(data,1/60,folder);fx:update(data,1/60,folder)
  assert(named("UzumakiCall")==calls+1,"Naruto Rendan was not called (KI)")
  -- The Nine-Tails cloak: a tail of red chakra, red eyes; gone with it.
  data.human.attackName=nil;data.human.attackVariant=nil;data.human.state="Neutral";data.human.awaken=6
  fx:update(data,1/60,folder)
  assert(named("FoxTail")==1,"no chakra tail in the cloak")
  local red=0
  for _,p in naruto:GetChildren() do if p.Name=="Iris" and p.Color==H.roblox.Color3.fromRGB(232,64,30) then red+=1 end end
  assert(red==2,"his eyes did not turn red in the cloak")
  data.human.awaken=0
  fx:update(data,1/60,folder)
  assert(named("FoxTail")==0,"the tail outlived the cloak")
  for _,p in naruto:GetChildren() do if p.Name=="Iris" then assert(p.Color==H.roblox.Color3.fromRGB(60,130,230),"his eyes stayed red") end end
 end)
 restore()
 assert(ok,err)
end)
print("NinjaDuel Naruto (several bodies): "..passed.." PASS")
