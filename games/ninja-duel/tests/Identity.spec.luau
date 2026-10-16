-- CORE4 identity pass (CORE_COMBAT_CONVERGENCE_2, phases 4 and 8): Itachi's
-- genjutsu image, visible Read and Sharingan Focus; Minato's Wind Cut and
-- Yellow Flash; Neji's tracked chakra points, 64 Palms climax, Rotation
-- counter and Byakugan Full Field; Sasuke's Curse Mark; jutsu flow.
-- Headless: it proves rules, state and the snapshot/impact contract the client
-- draws from. Readability, poses and VFX need native Studio.
local H=require("./Harness")
local V=H.V
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
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do
  H.step(c,.01)
  if cond() then return end
 end
 error(message)
end
local function slot(a,id)
 for i,spec in a.def.Techniques do if spec.Id==id then return "Technique"..i end end
 error("no technique "..id)
end
local function impactsSince(c,serial,style)
 local list={}
 for _,impact in c.impacts do if impact.serial>serial and (style==nil or impact.style==style) then table.insert(list,impact) end end
 return list
end
local function flat(v) return V.new(v.X,0,v.Z) end
local function ev(x,name) return (x.events or {})[name] or 0 end
local function awaken(c,a) a.awakened=true;a.awakenUntil=c.now+12;a.awakenedAt=c.now;a.curseLanded=c.now end
-- Itachi casts Mirage on b standing 16 studs away; returns where he stood.
local function mirage(c,a,b)
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8))
 local stood=a.root.Position
 assert(c:request(a,slot(a,"MirageCast"),b.root.Position),"Mirage refused")
 until_(c,.8,function() return (b.illusionUntil or 0)>c.now end,"the genjutsu never took")
 return stood
end

-- Itachi ----------------------------------------------------------------------
test("Itachi · Mirage: the image stays where he stood and he withdraws behind it, on the opponent's line",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 local stood=mirage(c,a,b)
 assert(b.illusionKind=="image" and b.illusionBy==a,"not an image genjutsu")
 assert((b.decoyPosition-stood).Magnitude<.6,"the image is not where he stood")
 local line=(stood-b.root.Position).Unit
 local back=(a.root.Position-stood):Dot(line)
 assert(back>4,"he did not withdraw behind his image ("..string.format("%.2f",back)..")")
 local off=flat((a.root.Position-stood)-line*back).Magnitude
 assert(off<.5,"the image does not cover him on the line ("..string.format("%.2f",off)..")")
 assert(a.root.CFrame.LookVector:Dot((b.root.Position-a.root.Position).Unit)>.9,"he does not face the opponent")
 local spec=a.def.Techniques[tonumber(string.match(slot(a,"MirageCast"),"%d"))]
 assert(spec.Channel<=.45 and spec.Recovery<=.2,"the hand signs still freeze him")
end)

test("Itachi · Mirage: a swing that reaches the image is caught, exposed, and the counter palm steps through it",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 local stood=mirage(c,a,b)
 -- The victim walks up to "Itachi" (the image) and swings at it.
 c:relocate(b,stood-V.new(0,0,6));b.root.CFrame=H.C.lookAt(b.root.Position,stood)
 until_(c,.5,function() return a.state=="Neutral" end,"Itachi never recovered from the cast")
 assert(c:request(b,"Attack"))
 until_(c,.6,function() return ev(a,'MirageCatch')>0 end,"the swing at the image was not caught")
 assert(b.illusionUntil<=c.now and b.decoyPosition==nil,"the image survived the catch")
 assert(b.health==b.def.Health and a.health==a.def.Health,"the swing at the image hit somebody")
 until_(c,.1,function() return b.state=="Stunned" end,"the swing at the image was not exposed")
 assert((a.counterUntil or 0)>c.now and a.counterReach and a.counterReach.max>=6,"no counter with a reach")
 local gap=flat(a.root.Position-b.root.Position).Magnitude
 assert(gap>6,"setup: the real body must stand out of a plain palm's reach ("..string.format("%.1f",gap)..")")
 assert(c:request(a,"Attack"))
 assert(a.attackName=="CounterPalm" and a.attackVariant=="MirageCounter","the catch did not open the stepping counter palm")
 until_(c,.5,function() return b.health<b.def.Health end,"the counter palm never reached the exposed body")
 local catch=false
 for _,impact in c.impacts do if impact.style=="mirage" and impact.phase=="catch" then catch=true end end
 assert(catch,"the client was not told the image broke")
end)

test("Itachi · Mirage: a whiff that does not reach the image is not punished (rule and visual agree)",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 mirage(c,a,b)
 -- Far to the side, swinging away from the image.
 c:relocate(b,V.new(12,3,0));b.root.CFrame=H.C.lookAt(b.root.Position,b.root.Position+V.xAxis)
 assert(c:request(b,"Attack"))
 H.step(c,.5)
 assert(ev(a,'MirageCatch')==0,"a swing nowhere near the image was caught")
 assert(b.illusionUntil>c.now,"the genjutsu ended without a reason")
end)

test("Itachi · Mirage: walking into the image dissolves it; any blow breaks the genjutsu; the Byakugan is immune",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 local stood=mirage(c,a,b)
 local serial=c.impactSerial
 c:relocate(b,stood+V.new(1,0,0))
 H.step(c,.03)
 assert(b.illusionUntil<=c.now,"walking into the image did not dissolve it")
 local touch=false
 for _,impact in impactsSince(c,serial,"mirage") do if impact.phase=="touch" then touch=true end end
 assert(touch,"no touch cue")
 local c2,x,y=H.duel("Mirage","Flashstep")
 mirage(c2,x,y)
 H.step(c2,.05)
 assert(c2:damage(x,y,3,false,false))
 H.step(c2,.03)
 assert(y.illusionUntil<=c2.now,"a blow did not break the genjutsu")
 local c3,m,n=H.duel("Mirage","GentleFist")
 place(c3,m,n,V.new(0,3,8),V.new(0,3,-8))
 assert(c3:request(m,slot(m,"MirageCast"),n.root.Position))
 H.step(c3,.8)
 assert(n.illusionUntil<=c3.now,"the image fooled the Byakugan")
end)

test("Itachi · AI: while its image holds, the Itachi AI keeps the line behind it",function()
 local AI=H.load("Server/AI")
 local c,a,b=H.duel("Mirage","Flashstep")
 local stood=mirage(c,a,b)
 local start=a.root.Position
 local brain=AI.new(c,a,5)
 for _=1,100 do brain:update(c.now);H.step(c,.01) end
 assert(b.illusionUntil>c.now,"setup: the image should still hold")
 local line=(stood-b.root.Position).Unit
 local rel=a.root.Position-stood
 local off=flat(rel-line*rel:Dot(line)).Magnitude
 assert(off<1.5 and rel:Dot(line)>3,"the AI left the line behind its image ("..string.format("%.2f off, %.2f back",off,rel:Dot(line))..")")
 assert(flat(a.root.Position-start).Magnitude<2.5,"the AI walked away from behind its image")
end)

test("Itachi · Read: the blow bites his afterimage, he slips aside square to the attacker, the counter opens",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,slot(a,"Read"),b.root.Position))
 H.step(c,.15)
 assert(a.readUntil>c.now,"no Read stance")
 local stood=a.root.Position
 local serial=c.impactSerial
 assert(c:request(b,"Attack"))
 until_(c,.4,function() return (a.counterUntil or 0)>c.now end,"the strike was not read")
 assert(a.health==a.def.Health,"the read strike landed")
 assert(b.state=="Stunned","the attacker was not caught out")
 local moved=flat(a.root.Position-stood)
 assert(moved.Magnitude>1.5,"no slip ("..string.format("%.2f",moved.Magnitude)..")")
 assert(math.abs(moved.Unit:Dot(flat(stood-b.root.Position).Unit))<.5,"the slip is not to the side")
 assert(a.root.CFrame.LookVector:Dot(flat(b.root.Position-a.root.Position).Unit)>.9,"he does not face the attacker")
 local cue=impactsSince(c,serial,"read")
 assert(#cue==1 and (cue[1].position-stood).Magnitude<.5 and cue[1].victim==b.id,"no read cue at the afterimage")
 assert(a.state=="Neutral" and a.pending==nil,"he stayed in the stance")
 assert(flat(a.root.Position-b.root.Position).Magnitude<5.5,"the slip left the counter out of reach")
end)

test("Itachi · Read: a strike pressed during the stance is the counter palm the moment the read lands",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(a,slot(a,"Read"),b.root.Position))
 H.step(c,.15)
 local ok,reason=c:request(a,"Attack")
 assert(ok and reason=="Buffered","a press during the stance was refused ("..tostring(reason)..")")
 assert(c:request(b,"Attack"))
 until_(c,.4,function() return a.attackName=="CounterPalm" end,"the read did not fire the pressed counter")
 until_(c,.4,function() return b.health<b.def.Health end,"the instant counter did not land")
end)

test("Itachi · Sharingan Focus: the raised guard reads a late blow (slip, counter); without Focus it is a block",function()
 for _,focus in {true,false} do
  local c,a,b=H.duel("Flashstep","Mirage")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  if focus then awaken(c,b) end
  assert(c:request(b,"Guard"))
  H.step(c,.6) -- raised long before the blow: outside every parry window
  local serial=c.impactSerial
  assert(c:request(a,"Attack"))
  H.step(c,.3)
  if focus then
   assert(ev(b,'Parry')==1,"the focused guard did not read the blow")
   assert(#impactsSince(c,serial,"read")==1,"the focused read was not shown")
   assert((b.counterUntil or 0)>c.now and a.state=="Stunned","the read opened no counter")
   -- A blade into a long-held focused guard is blocked, not read.
   local c2,x,y=H.duel("Flashstep","Mirage")
   place(c2,x,y,V.new(0,3,8),V.new(0,3,-8))
   awaken(c2,y)
   assert(c2:request(y,"Guard"));H.step(c2,.6)
   local blade=c2:projectile(x,y.root.Position,90,30,3,"kunai")
   c2:projectileHit(blade,y,y.root.Position,V.zAxis)
   assert(y.impactStyle=="block" and ev(y,'Parry')==0,"a focused guard deflected a blade outside the eye's window")
  else
   assert(b.impactStyle=="block" and ev(b,'Parry')==0,"a late guard parried without Focus")
  end
 end
end)

test("Itachi · Sharingan Focus: a swing that misses close to him is read",function()
 for _,focus in {true,false} do
  local c,a,b=H.duel("Flashstep","Mirage")
  place(c,a,b,V.new(0,3,10),V.new(0,3,0))
  if focus then awaken(c,b) end
  assert(c:request(a,"Attack"))
  H.step(c,.45)
  assert(a.hitConfirmed==false and b.health==b.def.Health,"setup: the swing should miss")
  if focus then assert(ev(b,'WhiffRead')==1 and (b.counterUntil or 0)>c.now,"the focused eye did not read the whiff")
  else assert(ev(b,'WhiffRead')==0,"a whiff was read without Focus") end
 end
end)

-- Minato ----------------------------------------------------------------------
local function bodySeals(a,b)
 local list={}
 for _,entry in a.anchors or {} do if entry.actor==b then table.insert(list,entry) end end
 return list
end
test("Minato · Wind Cut: thrown on the run; a cut body is marked and Flying Thunder God lands beside it",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,12),V.new(0,3,-12))
 a.move=V.new(1,0,0)
 assert(c:request(a,slot(a,"WindCut"),b.root.Position),"Wind Cut refused")
 assert(a.state=="Neutral","Wind Cut stopped him ("..a.state..")")
 until_(c,.8,function() return b.health<b.def.Health end,"the gust never landed")
 local seals=bodySeals(a,b)
 assert(#seals==1 and seals[1].wind and seals[1].expires-c.now<=Techniques.WIND.Seal+.01,"the cut body carries no short wind seal")
 assert(b.reaction=="HitStun","the cut did not throw the body aside ("..tostring(b.reaction)..")")
 a.move=V.zero
 assert(c:request(a,slot(a,"Flashstep")),"no Flying Thunder God onto the wind seal")
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no arrival")
 assert(flat(a.root.Position-b.root.Position).Magnitude<5,"he did not land beside the cut body")
 -- A guard stops the gust and keeps no seal.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,12),V.new(0,3,-12))
 assert(c2:request(y,"Guard"));H.step(c2,.3)
 assert(c2:request(x,slot(x,"WindCut"),y.root.Position))
 until_(c2,.8,function() return y.impactStyle=="block" end,"the gust never reached the guard")
 assert(#bodySeals(x,y)==0 and y.reaction==nil,"a guarded gust marked the body")
end)

test("Minato · Wind Cut: a longer seal already on the body is kept, not shortened",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,12),V.new(0,3,-12))
 local marked=Techniques.plant(c,a,b.root.Position,V.yAxis,b)
 local expires=marked.expires
 assert(c:request(a,slot(a,"WindCut"),b.root.Position))
 until_(c,.8,function() return b.health<b.def.Health end,"the gust never landed")
 local seals=bodySeals(a,b)
 assert(#seals==1 and seals[1]==marked and seals[1].expires==expires,"the wind cut shortened the marked kunai's seal")
end)

test("Minato · Wind Cut: the gust cuts enemy blades out of its lane",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
 local blade=c:projectile(b,a.root.Position,40,40,2,"shuriken")
 assert(c:request(a,slot(a,"WindCut"),b.root.Position))
 for _=1,60 do H.step(c,.01);if not table.find(c.projectiles,blade) then break end end
 assert(not table.find(c.projectiles,blade),"the blade survived the gust")
 assert(a.health==a.def.Health and ev(a,'WindCutBlade')>=1,"the blade was not cut by the gust")
end)

test("Minato · Yellow Flash: each jump leaves its return seal, a launched body is a destination, the arrival lasts longer",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,0),V.new(0,3,-20))
 awaken(c,a)
 Techniques.plant(c,a,V.new(20,0,0),V.yAxis)
 local start=a.root.Position
 a.move=V.xAxis
 assert(c:request(a,"Technique2"),"teleport refused")
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no arrival")
 assert(a.flashUntil-c.now>.6,"the awakened arrival window is not longer")
 local planted={}
 for _,entry in a.anchors do if not entry.actor then table.insert(planted,entry) end end
 assert(#planted==1 and planted[1].wake and flat(planted[1].position-start).Magnitude<1,"no return seal where he left")
 -- A launched body (chase window open) is a destination without any seal on it.
 until_(c,.5,function() return a.state=="Neutral" end,"stuck after the arrival")
 a.cooldowns={};a.move=V.zero
 c:relocate(b,V.new(-6,12,-10));b.airborne=true
 Brawler.react(c,b,"Launched",V.new(0,20,0),1.2,a)
 a.pursuitUntil=c.now+1
 assert(c:request(a,"Technique2"),"no Flying Thunder God onto the launched body")
 until_(c,.3,function() return (a.root.Position-b.root.Position).Magnitude<5 end,"he did not arrive beside the launched body")
 assert(a.pursuitUntil<=c.now,"the chase window was not spent")
 -- Without the awakening nothing reaches the body.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,0),V.new(0,3,-20))
 Brawler.react(c2,y,"Launched",V.new(0,20,0),1.2,x);x.pursuitUntil=c2.now+1
 assert(not c2:request(x,"Technique2"),"a launched body was a destination without Yellow Flash")
end)

-- Neji ------------------------------------------------------------------------
local Matches=H.load("Server/Matches")
local function view(c,victim,other)
 local s={combat=c,epoch=1,phase="Duel",origin=V.zero,round=1,wins={},roundsToWin=1}
 return Matches.view(Matches,s,s,victim,other).human
end
test("Neji · tenketsu: each clean palm closes a real point on the body, listed in the snapshot and lit for the client",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 local serial=c.impactSerial
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return (b.tenketsu or 0)==1 end,"no point closed")
 local point=b.tenketsuPoints and b.tenketsuPoints[1]
 assert(point and table.find(Brawler.TENKETSU_ORDER.body,point),"the closed point has no place on the body")
 local cue=impactsSince(c,serial,"tenketsu")
 assert(#cue==1 and cue[1].point==point and cue[1].victim==b.id and cue[1].count==1 and not cue[1].severe,"no point cue for the client")
 assert(#impactsSince(c,serial,"palm")>=1 and #impactsSince(c,serial,"light")==0,"the palm still reads as a generic punch")
 local data=view(c,b,a)
 assert(#data.tenketsuPoints==1 and data.tenketsuPoints[1]==point and not data.tenketsuSevere,"the snapshot does not list the closed point")
 -- Four points: a severed network, clearly flagged; then they all reopen.
 for _=1,3 do Brawler.closePoint(c,a,b,"body") end
 local severe=view(c,b,a)
 assert(#severe.tenketsuPoints==4 and severe.tenketsuSevere,"four points are not a severed network")
 local seen={}
 for _,id in severe.tenketsuPoints do assert(not seen[id],"a point closed twice");seen[id]=true end
 H.step(c,a.def.GentleFist.Duration+.1)
 assert(#view(c,b,a).tenketsuPoints==0,"the points never reopened")
end)

test("Neji · closed points compromise the guard: no parry at four, blocks cost more stamina",function()
 local function guard(points)
  local c,a,b=H.duel("GentleFist","Flashstep")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  for _=1,points do Brawler.closePoint(c,a,b,"body") end
  local stamina=b.stamina
  assert(c:request(b,"Guard"))
  assert(c:request(a,"Attack"))
  H.step(c,.3)
  return ev(b,'Parry'),stamina-b.stamina,b
 end
 local parries=guard(0)
 assert(parries==1,"setup: a fresh guard should parry")
 local severed,_,b=guard(4)
 assert(severed==0 and b.impactStyle=="block","a severed network still parried")
 -- Same late guard, plain block: four points cost more stamina than none.
 local function block(points)
  local c,a,b=H.duel("GentleFist","Flashstep")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  for _=1,points do Brawler.closePoint(c,a,b,"body") end
  assert(c:request(b,"Guard"));H.step(c,.4)
  local stamina=b.stamina
  assert(c:request(a,"Attack"));H.step(c,.3)
  assert(b.impactStyle=="block","setup: not a block")
  return stamina-b.stamina
 end
 assert(block(4)>block(0)+5,"closed points did not make the guard cost more")
end)

test("Neji · 64 Palms is the climax: closed points add palms and seal time; at four the guard collapses",function()
 local function flurry(points,guarding)
  local c,a,b=H.duel("GentleFist","Flashstep")
  place(c,a,b,V.new(0,3,2),V.new(0,3,-2))
  for _=1,points do Brawler.closePoint(c,a,b,"body") end
  c.damageLog={}
  if guarding then assert(c:request(b,"Guard"));H.step(c,.3) end
  assert(c:request(a,slot(a,"SixtyFourPalms")),"64 Palms refused")
  local sealedFor=0
  for _=1,300 do
   H.step(c,.01)
   if (b.sealedUntil or 0)>c.now then sealedFor=b.sealedUntil-c.now;break end
  end
  local palms=0
  for _,entry in c.damageLog do if entry.tag=="64 Palms" then palms+=1 end end
  return palms,sealedFor,a,b
 end
 local basePalms,baseSeal=flurry(0,false)
 assert(basePalms==8 and math.abs(baseSeal-3.5)<.05,"base flurry changed ("..basePalms..", "..string.format("%.2f",baseSeal)..")")
 local palms,seal,a=flurry(4,true)
 assert(ev(a,'GuardCollapse')==1,"the guard did not collapse at four points")
 assert(palms==12 and math.abs(seal-5.1)<.05,"four points did not deepen the flurry ("..palms..", "..string.format("%.2f",seal)..")")
 local plan=Techniques.palmsPlan(4)
 assert(plan.interval<.15 and plan.final>2.5,"the climax is not faster and heavier")
 local guarded=flurry(2,true)
 assert(guarded==1,"below four points the guard should still hold the opening palm")
end)

test("Neji · Rotation flows into the twin palm: the strike staggers within reach, the dome winds down, a pressed palm glides out",function()
 local c,a,b=H.duel("Flashstep","GentleFist")
 place(c,a,b,V.new(0,3,3),V.new(0,3,-3))
 assert(c:request(a,"Attack"))
 assert(c:request(b,"Technique1"),"Rotation refused")
 local ok,reason=c:request(b,"Attack")
 assert(ok and reason=="Buffered","a palm pressed during the spin was refused ("..tostring(reason)..")")
 until_(c,.6,function() return ev(b,'Repel')>0 end,"the strike was not repelled")
 assert(a.reaction=="HitStun","the turned-aside strike was thrown across the stage ("..tostring(a.reaction)..")")
 until_(c,.15,function() return b.attackName=="PalmThrust" end,"the pressed palm did not glide out of the spin")
 assert(b.attackVariant=="TrigramCounter" and (b.rotationUntil or 0)<=c.now,"the dome did not hand over to the counter")
 local health=a.health
 until_(c,.5,function() return a.health<health end,"the counter palm never reached the staggered attacker")
 -- Without a pressed palm the dome still winds down at once and waits.
 local c2,x,y=H.duel("Flashstep","GentleFist")
 place(c2,x,y,V.new(0,3,3),V.new(0,3,-3))
 assert(c2:request(x,"Attack"));assert(c2:request(y,"Technique1"))
 until_(c2,.6,function() return ev(y,'Repel')>0 end,"no repel")
 local repelled=c2.now
 until_(c2,.3,function() return y.state=="Neutral" end,"the dome did not wind down after the repel")
 assert(c2.now-repelled<.2 and (y.counterUntil or 0)>c2.now,"the dome kept its full recovery")
 assert(c2:request(y,"Attack") and y.attackName=="PalmThrust","no counter palm out of the repel")
 -- Pressed while the dome is still winding down: straight out of the spin.
 local c3,m,n=H.duel("Flashstep","GentleFist")
 place(c3,m,n,V.new(0,3,3),V.new(0,3,-3))
 assert(c3:request(m,"Attack"));assert(c3:request(n,"Technique1"))
 until_(c3,.6,function() return (n.events.Repel or 0)>0 end,"no repel")
 assert(n.state=="TechniqueActive" or n.state=="TechniqueRecovery","setup: the dome should still be winding down")
 assert(c3:request(n,"Attack") and n.attackName=="PalmThrust","a press during the wind-down was eaten")
end)

test("Neji · Byakugan Full Field: a clean palm closes two points; a palm that breaks a jutsu seals the techniques",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 awaken(c,a)
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return (b.tenketsu or 0)>0 end,"no point closed")
 assert(b.tenketsu==2,"the full field palm closed "..b.tenketsu.." point(s)")
 local c2,x,y=H.duel("GentleFist","Mirage")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 awaken(c2,x)
 assert(c2:request(y,slot(y,"FireBloom"),x.root.Position),"fireball refused")
 assert(c2:request(x,"Attack"))
 until_(c2,.4,function() return ev(x,'Interrupt')>0 end,"the channel was not broken")
 assert((y.sealedUntil or 0)>c2.now and ev(x,'FlowCut')==1,"breaking the jutsu did not cut the flow")
 -- Not awakened: an interrupt stays an interrupt.
 local c3,m,n=H.duel("GentleFist","Mirage")
 place(c3,m,n,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c3:request(n,slot(n,"FireBloom"),m.root.Position));assert(c3:request(m,"Attack"))
 until_(c3,.4,function() return ev(m,'Interrupt')>0 end,"the channel was not broken")
 assert((n.sealedUntil or 0)<=c3.now and n.tenketsu==1,"the base palm changed")
end)

-- Sasuke ----------------------------------------------------------------------
local function chainOpen(c,a)
 for _=1,90 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen and c.now>=(a.chainAt or 0) then return true end end
 return false
end
test("Sasuke · Curse Mark: the third kick does not let go (a stagger, the string stays open into the cursed launcher)",function()
 for _,cursed in {true,false} do
  local c,a,b=H.duel("Lion","Mirage")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  if cursed then awaken(c,a) end
  for hit=1,2 do assert(c:request(a,"Attack"));assert(chainOpen(c,a),"string broke at hit "..hit) end
  assert(c:request(a,"Attack"))
  assert(a.attackName=="Light3","not the third kick")
  until_(c,.5,function() return a.state=="Recovery" end,"the third kick never recovered")
  if cursed then
   assert(b.reaction=="HitStun" and a.chainOpen,"the cursed kick let go ("..tostring(b.reaction)..")")
   assert(ev(a,'CurseExtension')==1,"no curse cue")
   assert(chainOpen(c,a),"no chain window after the cursed kick")
   assert(c:request(a,"Heavy") and a.attackName=="Launcher","the open string did not lead into the launcher ("..tostring(a.attackName)..")")
   until_(c,.5,function() return b.reaction=="Launched" end,"the launcher after the cursed kick did not launch")
   H.step(c,.2)
   assert(a.state=="Pursuit","the cursed launcher did not chase")
  else
   assert(b.reaction=="Knockback" and not a.chainOpen,"the base third kick changed")
  end
 end
end)

test("Sasuke · Curse Mark: every launcher becomes the Dancing Leaf",function()
 for _,cursed in {true,false} do
  local c,a,b=H.duel("Lion","Mirage")
  place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
  if cursed then awaken(c,a) end
  for hit=1,2 do assert(c:request(a,"Attack"));assert(chainOpen(c,a),"string broke at hit "..hit) end
  assert(c:request(a,"Heavy"))
  assert(a.attackName=="Launcher","heavy after two is "..tostring(a.attackName))
  until_(c,.5,function() return b.reaction=="Launched" end,"the launcher did not launch")
  H.step(c,.2)
  if cursed then assert(a.state=="Pursuit" and (a.shadowUntil or 0)>c.now and (a.lionUntil or 0)>c.now,"no cursed Dancing Leaf chase ("..a.state..")")
  else assert(a.state~="Pursuit","the base launcher chased by itself") end
 end
end)

test("Sasuke · Curse Mark: the drain doubles while he lands nothing, pauses after a blow, never kills; the cursed body takes more",function()
 local c,a,b=H.duel("Lion","Mirage")
 awaken(c,a);a.curseLanded=c.now-2
 local before=a.health
 H.step(c,1)
 local hungry=before-a.health
 assert(math.abs(hungry-a.def.Awakening.HealthDrain*a.def.Awakening.Hunger)<.15,"hungry drain "..string.format("%.2f",hungry))
 a.curseFedUntil=c.now+.6;a.curseLanded=c.now
 before=a.health;H.step(c,.5)
 assert(before-a.health<.01,"the drain did not pause after a blow")
 a.health=1.5;H.step(c,2)
 assert(a.health>=1,"the curse killed")
 local c2,x,y=H.duel("Lion","Mirage")
 local healthy=x.health;assert(c2:damage(y,x,10,false,false));local plain=healthy-x.health
 local c3,m,n=H.duel("Lion","Mirage")
 awaken(c3,m)
 local full=m.health;assert(c3:damage(n,m,10,false,false));local cursed=full-m.health
 assert(cursed>plain*1.1,"the cursed body did not take more ("..cursed.." vs "..plain..")")
end)

-- Jutsu flow --------------------------------------------------------------------
test("jutsu flow: a cast started off-line turns into its aim instead of snapping the facing",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 place(c,a,b,V.new(0,3,8),V.new(0,3,-8))
 a.root.CFrame=H.C.lookAt(a.root.Position,a.root.Position+V.xAxis)
 assert(c:request(a,slot(a,"NeedleFan"),b.root.Position))
 local toward=flat(b.root.Position-a.root.Position).Unit
 assert(a.root.CFrame.LookVector:Dot(toward)<.5,"the cast snapped the facing in one frame")
 H.step(c,.2)
 assert(a.root.CFrame.LookVector:Dot(toward)>.95,"the cast never turned into its aim")
end)

test("jutsu flow: utility jutsu yield the end of their recovery to a dodge; commitments do not",function()
 local function recover(fighter,id,setup)
  local c,a,b=H.duel(fighter,"Mirage")
  place(c,a,b,V.new(0,3,9),V.new(0,3,-9))
  if setup then setup(c,a,b) end
  assert(c:request(a,slot(a,id),b.root.Position),id.." refused")
  until_(c,1.2,function() return a.state=="TechniqueRecovery" end,id.." never recovered")
  local spec=a.def.Techniques[tonumber(string.match(slot(a,id),"%d"))]
  local early=c:request(a,"Dodge")
  until_(c,spec.Recovery,function() return c.now-(a.untilTime-spec.Recovery)>=spec.Recovery*.6 end,"recovery clock")
  return early,c:request(a,"Dodge"),a
 end
 local early,late,a=recover("GentleFist","VacuumPalm")
 assert(not early and late and a.state=="Dodging","Vacuum Palm did not flow into a dodge")
 local _,lateFlash=recover("Flashstep","Flashstep",function(c,x) Techniques.plant(c,x,V.new(12,0,0),V.yAxis) end)
 assert(lateFlash,"Flying Thunder God did not flow into a dodge")
 local _,lateFire=recover("Mirage","FireBloom")
 assert(not lateFire,"the Great Fireball commitment became cancellable")
end)

-- Client cues (presentation only) --------------------------------------------
-- Effects runs headless on stubs: it proves every new cue resolves its body
-- points and builds without error, NOT how it looks (native Studio).
for _,k in {"NumberRange","NumberSequence","NumberSequenceKeypoint","ColorSequence","ColorSequenceKeypoint"} do H.envBase[k]=H.roblox[k] end
local baseNew=H.envBase.Instance.new
local created=0
H.envBase.Instance={new=function(class)
 created+=1
 local x=baseNew(class)
 if class=="ParticleEmitter" then function x:Emit() end end
 if x.GetPivot==nil then function x:GetPivot() return self.CFrame end end
 if x.PivotTo==nil then function x:PivotTo(cf) self.CFrame=cf end end
 return x
end}
local Effects=H.load("Client/Effects")
local Presentation=H.load("Client/Presentation")
test("client · every chakra point the server can close has a place on the body",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 local seen={}
 for _,order in Brawler.TENKETSU_ORDER do for _,id in order do seen[id]=true end end
 for id in seen do
  local at,part=Effects.tenketsuWorld(b.model,id)
  assert(at and part,"no body location for point "..id)
  assert((at-b.root.Position).Magnitude<4,"point "..id.." floats off the body")
 end
end)
test("client · the new identity cues build on the contact feed without error",function()
 local c,a,b=H.duel("Mirage","GentleFist")
 local fx=Effects.new()
 local models={[a.id]=a.model,[b.id]=b.model}
 local folder={FindFirstChild=function(_,id) return models[id] end}
 local before=created
 for _,impact in {
  {style="read",position=a.root.Position,owner=a.id,victim=b.id,to=a.root.Position+V.xAxis*2,phase="read"},
  {style="read",position=a.root.Position,owner=a.id,victim=b.id,phase="whiff"},
  {style="mirage",position=a.root.Position,owner=a.id,victim=b.id,phase="cast"},
  {style="mirage",position=a.root.Position,owner=a.id,victim=b.id,phase="catch"},
  {style="mirage",position=a.root.Position,owner=a.id,victim=b.id,phase="touch"},
  {style="mirage",position=a.root.Position,owner=a.id,victim=b.id,phase="seen"},
  {style="mirage",position=a.root.Position,owner=a.id,to=b.root.Position},
  {style="tenketsu",position=b.root.Position,owner=b.id,victim=a.id,point="heart",count=1},
  {style="tenketsu",position=b.root.Position,owner=b.id,victim=a.id,point="navel",count=4,severe=true},
  {style="windseal",position=b.root.Position,owner=a.id,victim=b.id,direction=V.xAxis},
  {style="curse",position=b.root.Position,owner=a.id,victim=b.id},
  {style="teleport",position=b.root.Position,owner=a.id,from=a.root.Position,to=b.root.Position,awake=true},
 } do fx:impact(impact,folder) end
 assert(created>before+60,"the cues built nothing ("..(created-before)..")")
 -- Persistent cues: closed points stay lit, the full field, a hungry curse.
 local aura={marks={}}
 fx:identity(a.model,{fighterId="Mirage",health=10,tenketsuPoints={"heart","throat","navel","leftHip"},tenketsuSevere=true},aura)
 local lit=0;for _ in aura.points do lit+=1 end
 assert(lit==4 and aura.leak,"closed points are not drawn on the body")
 fx:identity(a.model,{fighterId="Mirage",health=10,tenketsuPoints={}},aura)
 lit=0;for _ in aura.points do lit+=1 end
 assert(lit==0 and aura.leak==nil,"reopened points stayed lit")
 local neji={}
 fx:identity(b.model,{fighterId="GentleFist",health=10,awaken=5,tenketsuPoints={}},neji)
 assert(neji.field,"no Byakugan field")
end)
test("client · the genjutsu image is drawn from the deceived side and from the caster's side",function()
 local deceived,at=Presentation.illusionView({phase="Duel",human={illusion=2,decoy=V.one},bot={illusion=0}})
 assert(deceived=="deceived" and at==V.one,"the deceived player does not see the image")
 assert(Presentation.illusionView({phase="Duel",human={illusion=0},bot={illusion=1,decoy=V.one}})=="caster","Itachi's player does not see his image")
 assert(Presentation.illusionView({phase="Duel",human={illusion=0},bot={illusion=0}})==nil,"an image without a genjutsu")
 assert(Presentation.illusionView({phase="Result",human={illusion=2,decoy=V.one}})==nil,"an image outside the duel")
end)

print("NinjaDuel identity pass: "..passed.." PASS")
