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

-- =============================================================================
-- Convergence 3 (NEXT_VALIDATION_ROSTER_SCALE §5): the identity is SEEN in play.
-- Server half: the facts a cue needs ride on the contact feed and the snapshot.
-- Client half: each cue builds in a stub scene (Harness.stubScene: parenting and
-- calls only, nothing rendered). How it looks is a Studio check.
-- =============================================================================
local function feedSince(c,serial,seen,list)
 for _,impact in c.impacts do
  if impact.serial>serial and not seen[impact.serial] then seen[impact.serial]=true;table.insert(list,impact) end
 end
end

-- Neji (server) ----------------------------------------------------------------
test("Neji · the palm strikes the chakra point it closes: one palm contact names the point, the move and the drain; no fist burst",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 local emits=H.effectEmits
 local serial=c.impactSerial
 assert(c:request(a,"Attack"))
 until_(c,.4,function() return (b.tenketsu or 0)==1 end,"no point closed")
 local palms=impactsSince(c,serial,"palm")
 assert(#palms==1,"one palm, "..#palms.." palm contacts")
 local palm=palms[1]
 assert(palm.point==b.tenketsuPoints[1] and palm.move=="Light1" and palm.owner==a.id and palm.victim==b.id and palm.fighter=="GentleFist",
  "the palm contact does not say where it struck ("..tostring(palm.point)..", "..tostring(palm.move)..")")
 assert(math.abs((palm.drain or 0)-a.def.GentleFist.Drain)<1e-6,"the palm does not carry the chakra it drained")
 assert(H.effectEmits==emits,"a palm still bursts the donor fist effect on the body")
 -- Contrast: Minato's cut keeps the donor burst; its contact names the strike, no point.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,2.25),V.new(0,3,-2.25))
 local before=H.effectEmits
 local s2=c2.impactSerial
 assert(c2:request(x,"Attack"))
 until_(c2,.4,function() return y.health<y.def.Health end,"the cut never landed")
 assert(H.effectEmits>before,"setup: a generic strike lost its burst")
 local hit=impactsSince(c2,s2,"light")[1]
 assert(hit and hit.move=="Light1" and hit.owner==x.id and hit.fighter=="Flashstep" and hit.victim==y.id and hit.point==nil,"a strike's contact does not say what landed")
end)

test("Neji · a blocked palm still shows the chakra it drained",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(c:request(b,"Guard"));H.step(c,.4) -- raised long before: a block, not a parry
 local serial=c.impactSerial
 assert(c:request(a,"Attack"));H.step(c,.3)
 local block=impactsSince(c,serial,"block")[1]
 assert(block,"setup: the palm was not blocked")
 assert(block.owner==a.id and block.fighter=="GentleFist" and math.abs((block.drain or 0)-a.def.GentleFist.GuardDrain)<1e-6,"a blocked palm does not show the chakra it drained")
 assert(#impactsSince(c,serial,"tenketsu")==0,"a blocked palm closed a point")
end)

test("Neji · closed points: the snapshot carries the chakra recovery they leave, the same the body regenerates with",function()
 local c,a,b=H.duel("GentleFist","Mirage")
 assert(view(c,b,a).chakraRegen==1,"a fresh body shows a cut recovery")
 for _=1,2 do Brawler.closePoint(c,a,b,"body") end
 local data=view(c,b,a)
 assert(math.abs((data.chakraRegen or 1)-.7)<1e-6,"two points should leave 70 % ("..tostring(data.chakraRegen)..")")
 b.chakra=10;local before=b.chakra;H.step(c,1)
 assert(math.abs((b.chakra-before)-b.def.ChakraRegen*.7)<.05,"the recovery does not match what the bar shows ("..string.format("%.2f",b.chakra-before)..")")
 for _=1,2 do Brawler.closePoint(c,a,b,"body") end
 assert(math.abs(view(c,b,a).chakraRegen-.4)<1e-6,"four points should leave 40 %")
end)

test("Neji · 64 Palms counts 2-4-8-16-32-64 for both players, one palm contact per palm, 64 on the last, which throws the body",function()
 local c,a,b,match=H.duel("GentleFist","Flashstep")
 place(c,a,b,V.new(0,3,2),V.new(0,3,-2))
 for _=1,2 do Brawler.closePoint(c,a,b,"body") end
 local plan=Techniques.palmsPlan(2)
 local serial=c.impactSerial
 local seen,feed={},{}
 assert(c:request(a,slot(a,"SixtyFourPalms")),"64 Palms refused")
 for _=1,300 do
  H.step(c,.01);feedSince(c,serial,seen,feed)
  if (b.sealedUntil or 0)>c.now then break end
 end
 local counted,calls,lights={},{},0
 for _,impact in feed do
  if impact.style=="palm" and impact.count then table.insert(counted,impact) end
  if impact.style=="light" then lights+=1 end
 end
 assert(lights==0,"the flurry still pushed "..lights.." generic punch contact(s)")
 assert(#counted==plan.strikes,"one counted palm contact per palm ("..#counted.." for "..plan.strikes..")")
 for k,impact in counted do
  assert(impact.strike==k and impact.strikes==plan.strikes and impact.victim==b.id and impact.owner==a.id and impact.move=="SixtyFourPalms","palm "..k.." does not say which palm it is")
  assert((impact.count==64)==(k==#counted) and (impact.final==true)==(k==#counted),"64 called on palm "..k.." of "..#counted)
  if calls[#calls]~=impact.count then table.insert(calls,impact.count) end
 end
 assert(table.concat(calls,",")=="2,4,8,16,32,64","the count did not climb 2-4-8-16-32-64 ("..table.concat(calls,",")..")")
 assert(counted[#counted].heavy and b.reaction=="Knockback","the last palm did not throw the body")
 local victimRead=false
 for _,cue in match.cues do if cue.actor==b.id and cue.message:find("PALMS",1,true) then victimRead=true end end
 assert(victimRead,"the victim is not told the count")
 for n=7,12 do
  local last=nil
  for k=1,n do local count=Techniques.palmCount(k,n);assert(count>=(last or 0),"the count went down");last=count end
  assert(last==64 and Techniques.palmCount(n-1,n)<64,"64 is not the last palm alone at "..n.." palms")
 end
end)

test("Neji · the twin palm out of Rotation lands as a palm that names the counter (the client releases the dome there)",function()
 local c,a,b=H.duel("Flashstep","GentleFist")
 place(c,a,b,V.new(0,3,3),V.new(0,3,-3))
 assert(c:request(a,"Attack"))
 assert(c:request(b,"Technique1"),"Rotation refused")
 assert(c:request(b,"Attack"))
 local serial=c.impactSerial
 local health=a.health
 until_(c,1,function() return ev(b,"Repel")>0 and a.health<health-6 end,"the counter palm never landed")
 local counter
 for _,impact in impactsSince(c,serial,"palm") do if impact.variant=="TrigramCounter" then counter=impact end end
 assert(counter and counter.move=="PalmThrust" and counter.owner==b.id and counter.point,"the counter out of Rotation does not land as a named palm on a point")
end)

test("Neji · a Vacuum Palm that drives a body into a wall says so on the wall contact",function()
 local c,a,b=H.duel("GentleFist","Flashstep")
 H.addWall(20)
 place(c,a,b,V.new(-6,3,0),V.new(6,3,0))
 local serial=c.impactSerial
 local seen,feed={},{}
 assert(c:request(a,slot(a,"VacuumPalm"),b.root.Position))
 for _=1,120 do
  H.step(c,.01);feedSince(c,serial,seen,feed)
  for _,p in c.projectiles do
   if p.kind=="palm" and (p.position-b.root.Position).Magnitude<2.5 then c:projectileHit(p,b,b.root.Position,-V.xAxis);p.dead=true end
  end
  feedSince(c,serial,seen,feed)
  if b.reaction=="WallSplat" then break end
 end
 assert(b.reaction=="WallSplat","setup: no wall splat ("..tostring(b.reaction)..")")
 local wall
 for _,impact in feed do if impact.style=="wall" then wall=impact end end
 assert(wall and wall.cause=="VacuumPalm" and wall.by=="GentleFist","the wall contact does not say a Vacuum Palm drove the body there")
end)

-- Neji (client) ----------------------------------------------------------------
H.envBase.UDim=H.roblox.UDim
-- A stub scene with two bodies (A at the origin facing -Z, B 3 studs in front
-- facing A); `run(fx,folder,bodies)` inside it.
local function inScene(run)
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  -- (pcall: on a tree without the identity layer the cues are simply missing.)
  local layered,IdentityFX=pcall(H.load,"Client/IdentityFX")
  local clock=50
  if layered then IdentityFX.clock=function() return clock end end
  local fx=FX.new()
  local folder=instance("Folder")
  local bodies={}
  local function body(id,at,look)
   local m=instance("Model");m.Name=id;m.Parent=folder
   for _,n in {"HumanoidRootPart","Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","RightHand","LeftHand"} do
    local p=instance("Part");p.Name=n;p.Size=V.new(1,1,1);p.Transparency=0;p.Parent=m
    local y=if n=="Head" then 1.6 elseif n=="UpperTorso" then .6 elseif n=="LowerTorso" then -.4 elseif n:find("Hand") then -.2 else 0
    local x=if n:find("Left") then -1 elseif n:find("Right") then 1 else 0
    p.CFrame=H.C.lookAt(at+V.new(x,y,0),at+V.new(x,y,0)+look)
   end
   bodies[id]=m
   return m
  end
  body("A",V.new(0,3,0),-V.zAxis);body("B",V.new(0,3,-3),V.zAxis)
  run(fx,folder,bodies,function(dt) clock+=dt end,FX,IdentityFX)
 end)
 restore()
 if not ok then error(tostring(err),0) end
end
local function named(fx,name)
 local list={}
 for _,d in fx.folder:GetDescendants() do if d.Name==name then table.insert(list,d) end end
 return list
end
local function actorData(id,fighterId,extra)
 local data={id=id,fighterId=fighterId,health=135,maxHealth=135,seals={},state="Neutral",tenketsuPoints={},awaken=0,counter=0}
 for k,v in extra or {} do data[k]=v end
 return data
end
test("client · Neji's palm strikes the chakra point: an open-palm print there, no fist burst at the body's centre",function()
 inScene(function(fx,folder,bodies,_,FX)
  local victim=bodies.B
  local heart=FX.tenketsuWorld(victim,"heart")
  local root=victim:FindFirstChild("HumanoidRootPart").Position
  fx:impact({style="palm",position=root,owner="A",victim="B",fighter="GentleFist",move="Light1",point="heart",serial=1},folder)
  local prints=named(fx,"PalmPrint")
  assert(#prints==1,"no palm print ("..#prints..")")
  local nearest=math.huge
  for _,p in prints[1]:GetChildren() do nearest=math.min(nearest,(p.Position-heart).Magnitude) end
  assert(nearest<.4,"the palm is not printed on the heart point ("..string.format("%.2f",nearest)..")")
  for _,d in fx.folder:GetDescendants() do
   if d.ClassName=="Part" and d.Shape==H.roblox.Enum.PartType.Ball and (d.Position-root).Magnitude<.2 then error("a generic burst still flashes at the body's centre") end
  end
  assert(#named(fx,"PalmThrough")==1,"the chakra does not go through the body")
  assert(#named(fx,"TrigramRelease")==0,"a plain palm released the dome")
  -- The twin palm out of Rotation releases the chakra the dome left in the palms.
  fx:impact({style="palm",position=root,owner="A",victim="B",fighter="GentleFist",move="PalmThrust",variant="TrigramCounter",point="solar",serial=2},folder)
  assert(#named(fx,"TrigramRelease")==1,"the counter out of Rotation releases nothing")
 end)
end)
test("client · a blocked palm draws the chakra it drained out of the guard",function()
 inScene(function(fx,folder,bodies)
  fx:impact({style="block",position=bodies.B:FindFirstChild("HumanoidRootPart").Position,owner="A",victim="B",fighter="GentleFist",move="Light1",drain=3,serial=1},folder)
  local drain=named(fx,"ChakraDrain")
  assert(#drain==1 and #drain[1]:GetChildren()>=2,"no chakra drawn out of the guard")
  -- Any other fighter's blocked strike draws nothing of the kind.
  fx:impact({style="block",position=V.new(0,3,-3),owner="A",victim="B",fighter="Flashstep",move="Light1",serial=2},folder)
  assert(#named(fx,"ChakraDrain")==1,"a non-palm block drained chakra")
 end)
end)
test("client · 64 Palms: the count stands over the victim for both players, climbs, and clears after the throw",function()
 inScene(function(fx,folder,bodies,advance)
  local function palm(k,count,final,victim,owner)
   fx:impact({style="palm",position=V.new(0,3,-3),owner=owner,victim=victim,fighter="GentleFist",move="SixtyFourPalms",point="heart",
    count=count,strike=k,strikes=7,final=final,heavy=final,direction=-V.zAxis,serial=k},folder)
  end
  for k,count in {2,2,4,8,16,32,64} do palm(k,count,k==7,"B","A") end
  local boards=named(fx,"PalmCount")
  assert(#boards==1,"the count is not one board over the victim ("..#boards..")")
  assert(boards[1].Adornee==bodies.B:FindFirstChild("Head") and boards[1].AlwaysOnTop,"the count does not stand over the victim's head")
  assert(boards[1]:FindFirstChild("Count").Text=="64","the count did not reach 64")
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=actorData("A","GentleFist"),bot=actorData("B","Flashstep")}
  fx:update(data,1/60,folder)
  assert(#named(fx,"PalmCount")==1,"the throw did not hold its count a beat")
  advance(1.5);fx:update(data,1/60,folder)
  assert(#named(fx,"PalmCount")==0,"the count outlived the flurry")
  -- The other side of the same duel (the local player is the victim): same board.
  for k,count in {2,4} do palm(k,count,false,"A","B") end
  boards=named(fx,"PalmCount")
  assert(#boards==1 and boards[1].Adornee==bodies.A:FindFirstChild("Head") and boards[1]:FindFirstChild("Count").Text=="4","the victim's own view has no count")
 end)
end)
test("client · closed points keep a marker readable from any distance; Rotation's counter keeps Neji's palms lit",function()
 inScene(function(fx,folder,bodies)
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=actorData("A","GentleFist",{counter=.8}),
   bot=actorData("B","Mirage",{tenketsuPoints={"heart","throat"},tenketsu=2})}
  fx:update(data,1/60,folder)
  local marks=named(fx,"TenketsuMark")
  assert(#marks==2,"closed points carry "..#marks.." markers")
  assert(marks[1].AlwaysOnTop and marks[1].Size[1]==12,"a marker is not a constant-size mark over the body")
  local glow=0
  for _,hand in {"RightHand","LeftHand"} do if bodies.A:FindFirstChild(hand):FindFirstChild("CounterPalmGlow") then glow+=1 end end
  assert(glow==2,"the counter does not light Neji's palms")
  data.bot.tenketsuPoints={"heart","throat","solar","navel"};data.bot.tenketsuSevere=true;data.human.counter=0
  fx:update(data,1/60,folder)
  marks=named(fx,"TenketsuMark")
  assert(#marks==4 and marks[1].Size[1]==16,"a sealed network does not grow its markers")
  assert(bodies.A:FindFirstChild("RightHand"):FindFirstChild("CounterPalmGlow")==nil,"the palms stay lit after the counter")
  data.bot.tenketsuPoints={};data.bot.tenketsuSevere=false
  fx:update(data,1/60,folder)
  assert(#named(fx,"TenketsuMark")==0,"reopened points kept their markers")
 end)
end)
test("client · a body a Vacuum Palm drove into a wall leaves the air's palm print on the stone (not on any wall hit)",function()
 inScene(function(fx,folder)
  fx:impact({style="wall",position=V.new(20,3,0),normal=-V.xAxis,owner="B",cause="VacuumPalm",by="GentleFist",heavy=true,serial=1},folder)
  local prints=named(fx,"PalmPrint")
  assert(#prints==1,"no air print on the wall")
  assert(prints[1]:GetChildren()[1].Size.X>2,"the air print is not wall-sized")
  fx:impact({style="wall",position=V.new(20,3,8),normal=-V.xAxis,owner="B",cause="Light3",by="Flashstep",heavy=true,serial=2},folder)
  assert(#named(fx,"PalmPrint")==1,"another fighter's wall hit printed a palm")
 end)
end)
test("HUD · closed points read on both plates, their cost dims the chakra bar, sealed jutsu grey out with the reason",function()
 H.envBase.UDim2=H.roblox.UDim2
 H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
 H.workspace.GetAttribute=function() return nil end
 local baseNew=H.envBase.Instance.new
 local saved=H.envBase.Instance
 H.envBase.Instance={new=function(class) local x=baseNew(class);x.Activated={Connect=function() end};return x end}
 local ok,err=pcall(function()
  local UI=H.load("Client/UI")
  local ui=UI.new(baseNew("PlayerGui"),function() end)
  local function tech(id,name,cost) return {id=id,name=name,cost=cost,remaining=0,condition=true} end
  local me={id="PlayerFighter",fighterId="Mirage",health=100,maxHealth=145,chakra=80,maxChakra=125,stamina=100,state="Neutral",subCharges=2,subRegen=0,cue="",dodge=0,pursuit=0,counter=0,
   seals={},techniques={tech("Read","Sharingan Read",14),tech("NeedleFan","Shadow Shuriken",18)},tenketsu=2,tenketsuPoints={"heart","solar"},chakraRegen=.7,sealed=2.4}
  local neji={id="AIFighter",fighterId="GentleFist",health=135,maxHealth=135,chakra=100,maxChakra=115,stamina=100,state="Neutral",subCharges=2,subRegen=0,cue="",dodge=0,pursuit=0,counter=0,
   seals={},techniques={},tenketsuPoints={},chakraRegen=1,sealed=0}
  ui:render({phase="Duel",epoch=1,intro=0,round=1,roundsToWin=2,wins={human=0,bot=0},human=me,bot=neji})
  local lit=0
  for k,pip in ui.hp.points do
   assert(pip.Visible,"my plate hides the points Neji can close")
   if pip.BackgroundColor3~=H.roblox.Color3.fromRGB(46,42,48) then lit+=1 end
  end
  assert(lit==2,"my plate lights "..lit.." points for two closed")
  for _,pip in ui.enemy.points do assert(not pip.Visible,"Neji's own plate shows points nobody can close") end
  assert(ui.hp.status.Text:find("JUTSU SEALED",1,true),"the sealed jutsu are not said ("..ui.hp.status.Text..")")
  assert(ui.hp.chakra.BackgroundColor3~=ui.enemy.chakra.BackgroundColor3,"the chakra bar does not show the cut recovery")
  assert(ui.techniqueButtons[1].status.Text:find("SEALED",1,true) and ui.techniqueButtons[1].title.TextColor3~=H.roblox.Color3.fromRGB(240,232,212),"a sealed jutsu still reads ready")
  me.sealed=0
  ui:render({phase="Duel",epoch=1,intro=0,round=1,roundsToWin=2,wins={human=0,bot=0},human=me,bot=neji})
  assert(ui.hp.status.Text:find("REGEN -30%",1,true),"the recovery the points cost is not spelled out ("..ui.hp.status.Text..")")
  assert(ui.techniqueButtons[1].status.Text=="14 CHAKRA","an unsealed jutsu still reads sealed")
 end)
 H.envBase.Instance=saved
 assert(ok,err)
end)

-- Minato (server) ----------------------------------------------------------------
local function launchAndFlash(c,a,b)
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 for hit=1,2 do assert(c:request(a,"Attack"));assert(chainOpen(c,a),"string broke at hit "..hit) end
 a.intentOverride={"forward",0}
 assert(c:request(a,"Attack"))
 a.intentOverride=nil
 assert(a.attackName=="Launcher","not the rising kick ("..tostring(a.attackName)..")")
 until_(c,.5,function() return b.reaction=="Launched" end,"the rising kick did not launch")
 assert(#bodySeals(a,b)==1,"the rising kick left no seal on the body")
 local flashed=false
 for _=1,80 do H.step(c,.01);if c:request(a,"Technique2") then flashed=true;break end end
 assert(flashed,"no Flying Thunder God onto the sealed body")
 until_(c,.3,function() return (a.flashUntil or 0)>c.now end,"no arrival")
end
test("Minato · combo -> relocation -> combo: the rising kick's seal takes him to the body and the arrival strike carries the chain on",function()
 local c,a,b,match=H.duel("Flashstep","Mirage")
 launchAndFlash(c,a,b)
 local hits=b.comboHits
 assert(hits>=3 and b.reaction=="Launched","setup: the body should still be in the combo ("..hits..")")
 local serial=c.impactSerial
 assert(c:request(a,"Attack"))
 assert(a.attackName=="Air1","the arrival strike in the air is "..tostring(a.attackName))
 until_(c,.4,function() return (b.comboHits or 0)>hits end,"the arrival strike did not land")
 local link
 for _,impact in impactsSince(c,serial) do if impact.arrival then link=impact end end
 assert(link and link.move=="Air1" and link.owner==a.id and link.victim==b.id,"the arrival strike's contact does not say the chain went on")
 assert(ev(a,"FlashChain")==1,"no chain event")
 local said=false
 for _,cue in match.cues do if cue.actor==a.id and cue.message:find("CHAIN GOES ON",1,true) then said=true end end
 assert(said,"the player is not told the chain went on")
 -- An arrival strike that opens a fresh exchange is no chain.
 local c2,x,y=H.duel("Flashstep","Mirage")
 place(c2,x,y,V.new(0,3,0),V.new(0,3,-14))
 Techniques.plant(c2,x,y.root.Position,V.yAxis,y)
 assert(c2:request(x,"Technique2"))
 until_(c2,.3,function() return (x.flashUntil or 0)>c2.now end,"no arrival")
 assert(c2:request(x,"Attack"))
 until_(c2,.4,function() return y.health<y.def.Health end,"the arrival strike did not land")
 assert(ev(x,"FlashChain")==0,"a fresh exchange was called a chain")
 -- The Rasengan out of the jump carries the chain too, and grinds where it lands.
 local c3,m,n=H.duel("Flashstep","Mirage")
 launchAndFlash(c3,m,n)
 local s3=c3.impactSerial
 assert(c3:request(m,slot(m,"BurstStrike"),n.root.Position),"no Rasengan out of the arrival")
 local before=n.health
 until_(c3,.6,function() return n.health<before end,"the arrival Rasengan did not land")
 local rasengan
 for _,impact in impactsSince(c3,s3) do if impact.variant=="Rasengan" and impact.arrival then rasengan=impact end end
 assert(rasengan and ev(m,"FlashChain")==1,"the Rasengan out of the jump does not carry the chain")
end)

test("Minato · the Rasengan contact names itself (the client grinds it into the body)",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 place(c,a,b,V.new(0,3,4),V.new(0,3,-4))
 local serial=c.impactSerial
 assert(c:request(a,slot(a,"BurstStrike"),b.root.Position),"Rasengan refused")
 until_(c,1,function() return b.health<b.def.Health end,"the Rasengan never landed")
 local grind
 for _,impact in impactsSince(c,serial) do if impact.variant=="Rasengan" and impact.victim==b.id then grind=impact end end
 assert(grind and grind.owner==a.id and grind.fighter=="Flashstep","the Rasengan contact does not say it was the Rasengan")
end)

-- Minato (client) ----------------------------------------------------------------
test("client · Minato's seals read apart: a beacon over a planted kunai, a formula on the floor (no kunai) where Yellow Flash left, a ring round a sealed body",function()
 inScene(function(fx,folder,bodies)
  local minato=actorData("A","Flashstep",{seals={
   {id=1,surface=V.new(10,0,0),normal=V.yAxis,remaining=8},
   {id=2,surface=V.new(-10,0,0),normal=V.yAxis,remaining=8,wake=true},
   {id=3,surface=V.new(0,3,-3),normal=V.yAxis,remaining=4,body="B"}}})
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=minato,bot=actorData("B","Mirage")}
  fx:update(data,1/60,folder)
  local marks=named(fx,"SealMark")
  assert(#marks==3,"three seals, "..#marks.." marks")
  assert(#named(fx,"SealBeacon")==1,"the planted kunai has no beacon")
  assert(fx.seals["A:1"].model~=nil,"the planted seal lost its kunai")
  assert(fx.seals["A:2"].model==nil,"a return seal is drawn as a thrown kunai")
  -- The body ring surrounds the torso: parts in front of it and behind it.
  local torso=bodies.B:FindFirstChild("UpperTorso").Position
  local front,behind=0,0
  for _,mark in marks do
   local parts=mark:GetChildren()
   if #parts==11 then
    for _,p in parts do
     local d=p.Position-torso
     assert(V.new(d.X,0,d.Z).Magnitude>1.1,"a ring part sits inside the body")
     if d.Z>.3 then front+=1 elseif d.Z<-.3 then behind+=1 end
    end
   end
  end
  assert(front>0 and behind>0,"the body mark cannot be seen from both sides ("..front.." front, "..behind.." behind)")
  -- Seals that end take their marks with them.
  minato.seals={}
  fx:update(data,1/60,folder)
  assert(#named(fx,"SealMark")==0,"a spent seal kept its mark")
 end)
end)
test("client · Minato: the arrival window rings under him and closes; Yellow Flash draws the thread back to his return seal",function()
 inScene(function(fx,folder,bodies,advance)
  local minato=actorData("A","Flashstep",{flash=true})
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=minato,bot=actorData("B","Mirage")}
  fx:update(data,1/60,folder)
  local ring=named(fx,"ArrivalWindow")[1]
  assert(ring,"no arrival window ring")
  local first=ring.Size.Y
  advance(.3);fx:update(data,1/60,folder)
  assert(ring.Size.Y<first-1,"the arrival ring does not close with the window")
  minato.flash=false;fx:update(data,1/60,folder)
  assert(#named(fx,"ArrivalWindow")==0,"the ring outlived the window")
  -- Awakened with a return seal: the thread; not awakened: none.
  minato.awaken=6;minato.seals={{id=4,surface=V.new(-12,0,0),normal=V.yAxis,remaining=11,wake=true}}
  fx:update(data,1/60,folder)
  assert(bodies.A:FindFirstChild("UpperTorso"):FindFirstChild("ReturnThread"),"no thread from Yellow Flash to its return seal")
  assert(#named(fx,"ReturnThread")==1,"the thread is not drawn")
  minato.awaken=0;fx:update(data,1/60,folder)
  assert(bodies.A:FindFirstChild("UpperTorso"):FindFirstChild("ReturnThread")==nil and #named(fx,"ReturnThread")==0,"the thread outlived the awakening")
 end)
end)
test("client · an arrival strike that carries the chain links in gold; a Rasengan grinds where it lands",function()
 inScene(function(fx,folder)
  fx:impact({style="light",position=V.new(0,3,-3),owner="A",victim="B",fighter="Flashstep",move="Air1",arrival=true,serial=1},folder)
  assert(#named(fx,"ChainLink")==1,"no gold link for the chain carried through the jump")
  fx:impact({style="light",position=V.new(0,3,-3),owner="A",victim="B",fighter="Flashstep",move="Light1",serial=2},folder)
  assert(#named(fx,"ChainLink")==1,"a plain strike drew a chain link")
  fx:impact({style="finisher",position=V.new(0,3,-3),owner="A",victim="B",fighter="Flashstep",move="DashAttack",variant="Rasengan",serial=3},folder)
  local grind=named(fx,"RasenganGrind")
  assert(#grind==1 and #grind[1]:GetChildren()==3,"the Rasengan does not grind where it lands")
 end)
end)
local function hudScene(run)
 H.envBase.UDim2=H.roblox.UDim2
 H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
 H.workspace.GetAttribute=function() return nil end
 local baseNew=H.envBase.Instance.new
 local saved=H.envBase.Instance
 H.envBase.Instance={new=function(class) local x=baseNew(class);x.Activated={Connect=function() end};return x end}
 local ok,err=pcall(function()
  local UI=H.load("Client/UI")
  run(UI.new(baseNew("PlayerGui"),function() end),UI)
 end)
 H.envBase.Instance=saved
 if not ok then error(tostring(err),0) end
end
local function plate(fighterId,extra)
 local def=H.fighters[fighterId]
 local techniques={}
 for _,spec in def.Techniques do table.insert(techniques,{id=spec.Id,name=spec.Name,cost=spec.Cost,remaining=0,condition=true}) end
 local data={id=fighterId,fighterId=fighterId,health=def.Health,maxHealth=def.Health,chakra=100,maxChakra=def.Chakra,stamina=100,state="Neutral",subCharges=2,subRegen=0,
  cue="",dodge=0,pursuit=0,counter=0,seals={},techniques=techniques,tenketsuPoints={},chakraRegen=1,sealed=0,awaken=0}
 for k,v in extra or {} do data[k]=v end
 return data
end
local function duelView(h,b) return {phase="Duel",epoch=1,intro=0,round=1,roundsToWin=2,wins={human=0,bot=0},human=h,bot=b} end
test("HUD · Minato: after a jump the arrival strike and the Rasengan are prompted; Yellow Flash says what it changes and how long it lasts",function()
 hudScene(function(ui)
  local me=plate("Flashstep",{flash=true})
  ui:render(duelView(me,plate("Mirage")))
  assert(ui.hint.Text:find("ARRIVAL STRIKE",1,true) and ui.hint.Text:find("RMB — LAUNCH",1,true) and ui.hint.Text:find("3 — RASENGAN",1,true),"the arrival is not prompted ("..ui.hint.Text..")")
  me.airborne=true;ui:render(duelView(me,plate("Mirage")))
  assert(ui.hint.Text:find("RMB — SLAM",1,true),"the air arrival prompts a launcher ("..ui.hint.Text..")")
  me.airborne=false
  me.flash=false;me.awaken=7.25
  ui:render(duelView(me,plate("Mirage")))
  assert(not ui.hint.Text:find("ARRIVAL",1,true),"the arrival prompt outlived the window")
  assert(ui.hp.awake.Text:find("YELLOW FLASH  7.2",1,true) and ui.hp.awake.Text:find("RETURN SEAL",1,true),"the awakening does not say what it changes ("..ui.hp.awake.Text..")")
  assert(ui.enemy.awake.Text=="","an unawakened opponent shows an awakening")
 end)
end)

-- Itachi (server) ----------------------------------------------------------------
local Elements=H.load("Server/Elements")
test("Itachi · the Great Fireball burns a lane where it passes the opponent: fire as control (a chip, never a stun); Sasuke's does not",function()
 local function cast(fighter)
  local c,a,b=H.duel(fighter,"Flashstep")
  place(c,a,b,V.new(0,3,20),V.new(0,3,-20))
  assert(c:request(a,slot(a,"FireBloom"),b.root.Position),"fireball refused")
  -- He side-steps the blast: it flies on six studs beside him.
  c:relocate(b,V.new(6,3,-20))
  H.step(c,2)
  local lane={}
  for _,h in c.hazards do if h.lane then table.insert(lane,h) end end
  return c,a,b,lane
 end
 local c,a,b,lane=cast("Mirage")
 assert(b.health==b.def.Health,"setup: the side-step should dodge the blast")
 assert(#lane>=4,"no lane where the fireball passed him ("..#lane.." patches)")
 local tune=Elements.LANE
 for k,patch in lane do
  local d=patch.position-b.root.Position
  assert(V.new(d.X,0,d.Z).Magnitude<=tune.Reach+tune.Radius,"a patch burns far from the opponent")
  assert(patch.kind=="Fire" and patch.radius==tune.Radius and patch.lane==lane[1].lane,"a patch is not part of one fire lane")
  if k>1 then
   local gap=V.new(patch.position.X-lane[k-1].position.X,0,patch.position.Z-lane[k-1].position.Z).Magnitude
   assert(math.abs(gap-tune.Spacing)<.6,"the lane is not one line ("..string.format("%.2f",gap)..")")
  end
 end
 local data=Matches.view(Matches,{combat=c,epoch=1,phase="Duel",origin=V.zero,round=1,wins={},roundsToWin=1},{},a,b)
 local shown=0
 for _,h in data.hazards do if h.lane==lane[1].lane then shown+=1 end end
 assert(shown==#lane,"the snapshot does not carry the lane")
 -- Standing in it burns (a chip), never stuns nor feeds a combo.
 c:relocate(b,lane[2].position+V.new(0,.6,0))
 local health,hits=b.health,b.comboHits
 H.step(c,1)
 assert(b.health<health and b.state~="Stunned" and b.comboHits==hits,"the lane does not burn like fire (chip only)")
 local _,_,_,none=cast("Lion")
 assert(#none==0,"Sasuke's fireball burned Itachi's lane")
end)

test("Itachi · a ricochet and Shuriken Geometry show the paths their blades take",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 H.addWall(20)
 place(c,a,b,V.new(0,3,0),V.new(10,3,8))
 local serial=c.impactSerial
 local seen,feed={},{}
 c:projectile(a,V.new(26,3,-6),84,62,2,"shuriken")
 for _=1,80 do H.step(c,.01);feedSince(c,serial,seen,feed) end
 local ricochet
 for _,impact in feed do if impact.style=="deflect" and impact.ricochet then ricochet=impact end end
 assert(ricochet,"the ricochet does not say it is one")
 assert(ricochet.to and (ricochet.to-b.root.Position).Magnitude<4 and ricochet.direction:Dot((ricochet.to-ricochet.position).Unit)>.95,"the ricochet's new path is not shown toward the body")
 H.clearWalls()
 local c2,x,y=H.duel("Mirage","Flashstep")
 place(c2,x,y,V.new(0,3,12),V.new(0,3,-12))
 x.intentOverride={"side",1}
 assert(c2:request(x,"Tool"),"geometry refused")
 x.intentOverride=nil
 local s2=c2.impactSerial
 local seen2,feed2={},{}
 for _=1,90 do H.step(c2,.01);feedSince(c2,s2,seen2,feed2) end
 local meet
 for _,impact in feed2 do if impact.style=="clash" and impact.geometry then meet=impact end end
 assert(meet and meet.to and (meet.to-y.root.Position).Magnitude<1.5,"the geometry meeting does not show where its blades go")
end)

-- Itachi (client) ----------------------------------------------------------------
test("client · Itachi's Read: tomoe turn at his feet in the stance; a read draws the line from his eyes to the swing and a counter window that closes",function()
 inScene(function(fx,folder,bodies)
  local itachi=actorData("A","Mirage",{read=.8})
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=itachi,bot=actorData("B","Flashstep")}
  fx:update(data,1/60,folder)
  assert(#named(fx,"ReadTomoe")==1,"the Read stance shows nothing at his feet")
  itachi.read=0;itachi.counter=.9
  fx:update(data,1/60,folder)
  assert(#named(fx,"ReadTomoe")==0,"the tomoe outlived the stance")
  local ring=named(fx,"CounterWindow")[1]
  assert(ring,"no counter window")
  local open=ring.Size.Y
  itachi.counter=.2;fx:update(data,1/60,folder)
  assert(ring.Size.Y<open-2,"the counter window does not close with its time")
  itachi.counter=0;fx:update(data,1/60,folder)
  assert(#named(fx,"CounterWindow")==0,"the window outlived the counter")
  fx:impact({style="read",position=V.new(.5,3,0),owner="A",fighter="Mirage",victim="B",to=V.new(2,3,0),phase="read",serial=1},folder)
  assert(#named(fx,"ReadLine")==1,"the read does not show what he saw coming")
 end)
end)
test("client · a caught image lights the real body behind it; ricochet and Geometry flash their paths",function()
 inScene(function(fx,folder)
  fx:impact({style="mirage",position=V.new(0,3,-6),owner="A",fighter="Mirage",victim="B",phase="catch",serial=1},folder)
  assert(#named(fx,"MirageReveal")==1,"the caught image does not reveal the body")
  fx:impact({style="deflect",position=V.new(20,3,-6),owner="A",fighter="Mirage",ricochet=true,to=V.new(10,3,8),direction=(V.new(10,3,8)-V.new(20,3,-6)).Unit,serial=2},folder)
  assert(#named(fx,"RicochetPath")==1,"the ricochet's path does not flash")
  fx:impact({style="deflect",position=V.new(0,3,-3),owner="B",serial=3},folder)
  assert(#named(fx,"RicochetPath")==1,"a plain deflection drew a ricochet path")
  fx:impact({style="clash",position=V.new(-6,3,-10),owner="A",fighter="Mirage",geometry=true,to=V.new(0,3,-12),direction=V.xAxis,serial=4},folder)
  assert(#named(fx,"GeometryPath")==2,"the geometry's two blades do not show their paths")
 end)
end)
test("client · Itachi's lane reads as one scorched strip across the field and clears with its fire",function()
 inScene(function(fx,folder)
  local hazards={}
  for k=0,4 do table.insert(hazards,{position=V.new(6,2.4,-7-k*5),radius=2.4,remaining=2,kind="Fire",owner="A",lane=9}) end
  table.insert(hazards,{position=V.new(-20,2.4,0),radius=7.5,remaining=2,kind="Fire",owner="A"})
  local data={phase="Duel",epoch=1,hazards=hazards,projectiles={},human=actorData("A","Mirage"),bot=actorData("B","Flashstep")}
  fx:update(data,1/60,folder)
  local strips=named(fx,"FireLane")
  assert(#strips==1,"the lane is not drawn as one strip ("..#strips..")")
  local scorch=strips[1]:GetChildren()[1]
  assert(scorch.Size.Z>=20,"the strip does not run the lane's length")
  data.hazards={}
  fx:update(data,1/60,folder)
  assert(#named(fx,"FireLane")==0,"the strip outlived its fire")
 end)
end)
test("HUD · a read's counter is named and timed",function()
 hudScene(function(ui)
  ui:render(duelView(plate("Mirage",{counter=.74}),plate("Flashstep")))
  assert(ui.hint.Text:find("COUNTER PALM  0.7",1,true),"the counter is not named and timed ("..ui.hint.Text..")")
  ui:render(duelView(plate("GentleFist",{counter=.5}),plate("Flashstep")))
  assert(ui.hint.Text:find("TWIN PALM",1,true),"Neji's counter is not named ("..ui.hint.Text..")")
 end)
end)

-- Sasuke (server) ----------------------------------------------------------------
test("Sasuke · a Chidori that finds nothing tells both he is open; one that lands names itself",function()
 local c,a,b,match=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,30),V.new(0,3,-30))
 local serial=c.impactSerial
 local seen,feed={},{}
 assert(c:request(a,slot(a,"Chidori"),b.root.Position),"Chidori refused")
 for _=1,150 do H.step(c,.01);feedSince(c,serial,seen,feed) end
 assert(b.health==b.def.Health,"setup: the thrust should miss")
 assert(ev(a,"ChidoriMissed")==1,"the miss is not marked")
 local toB,toA=false,false
 for _,cue in match.cues do
  if cue.actor==b.id and cue.message=="CHIDORI MISSED • PUNISH" then toB=true end
  if cue.actor==a.id and cue.message:find("MISSED",1,true) then toA=true end
 end
 assert(toB and toA,"the miss is not said to both players")
 local whiff
 for _,impact in feed do if impact.style=="whiff" and impact.move=="ChidoriThrust" then whiff=impact end end
 assert(whiff and whiff.owner==a.id,"the empty thrust does not say it was the Chidori")
 local c2,x,y=H.duel("Lion","Mirage")
 place(c2,x,y,V.new(0,3,4),V.new(0,3,-4))
 local s2=c2.impactSerial
 local seen2,feed2={},{}
 assert(c2:request(x,slot(x,"Chidori"),y.root.Position))
 for _=1,120 do H.step(c2,.01);feedSince(c2,s2,seen2,feed2);if y.health<y.def.Health then break end end
 assert(y.health<y.def.Health,"setup: the thrust should land")
 H.step(c2,.3)
 local landed
 for _,impact in feed2 do if impact.move=="ChidoriThrust" and impact.victim==y.id and impact.style~="whiff" then landed=impact end end
 assert(landed and landed.owner==x.id,"the Chidori contact does not name itself")
 assert(ev(x,"ChidoriMissed")==0,"a landed Chidori was called a miss")
end)

test("Sasuke · the Phoenix Flower's hidden blades are marked as hidden in the snapshot",function()
 local c,a,b=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,14),V.new(0,3,-14))
 assert(c:request(a,slot(a,"PhoenixFlower"),b.root.Position),"Phoenix Flower refused")
 H.step(c,.62)
 local data=Matches.view(Matches,{combat=c,epoch=1,phase="Duel",origin=V.zero,round=1,wins={},roundsToWin=1},{},a,b)
 local hidden,flames=0,0
 for _,p in data.projectiles do
  if p.hidden then hidden+=1;assert(p.kind=="shuriken","a hidden blade is not steel") end
  if p.kind=="phoenix" then flames+=1;assert(not p.hidden,"a flame is marked hidden") end
 end
 assert(hidden==2 and flames>=1,"the two blades in the flames are not marked ("..hidden.." hidden, "..flames.." flames)")
end)

test("Sasuke · Shadow of the Dancing Leaf: the snapshot carries the Lion Combo window",function()
 local c,a,b=H.duel("Lion","Mirage")
 place(c,a,b,V.new(0,3,2.25),V.new(0,3,-2.25))
 assert(view(c,a,b).lion==0,"a window before any leaf")
 for hit=1,2 do assert(c:request(a,"Attack"));assert(chainOpen(c,a),"string broke at hit "..hit) end
 a.intentOverride={"forward",0}
 assert(c:request(a,"Attack"))
 a.intentOverride=nil
 assert(a.attackName=="LionKick","not the rising kick ("..tostring(a.attackName)..")")
 until_(c,.6,function() return a.state=="Pursuit" end,"no Dancing Leaf")
 local data=view(c,a,b)
 assert(data.lion>0 and data.lion<=2.1,"the Lion Combo window is not in the snapshot ("..tostring(data.lion)..")")
end)

-- Sasuke (client) ----------------------------------------------------------------
test("client · the curse spreads from the neck as it takes Sasuke, across the face while it starves, and recedes with it",function()
 inScene(function(fx,folder,bodies,advance,_,IdentityFX)
  local sasuke=actorData("A","Lion",{awaken=11})
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=sasuke,bot=actorData("B","Mirage")}
  local function shown()
   local count=0
   for _,p in bodies.A:GetChildren() do if p.Name=="CurseSpread" and p.Transparency==0 then count+=1 end end
   return count
  end
  fx:update(data,1/60,folder)
  local start=shown()
  assert(start>=1 and start<=2,"the curse appeared all at once ("..start..")")
  advance(1.2);fx:update(data,1/60,folder)
  local spread=shown()
  local plain=0
  for _,spec in IdentityFX.CURSE_SPREAD do if not spec.hunger then plain+=1 end end
  assert(spread==plain,"the curse did not spread over the body ("..spread.." of "..plain..")")
  sasuke.curseHunger=true;fx:update(data,1/60,folder)
  assert(shown()==#IdentityFX.CURSE_SPREAD,"a starving curse does not reach across the face")
  local neon=0
  for _=1,8 do
   advance(.05);fx:update(data,1/60,folder)
   for _,p in bodies.A:GetChildren() do if p.Name=="CurseSpread" and p.Material==H.roblox.Enum.Material.Neon then neon+=1 end end
  end
  assert(neon>0,"the hungry curse does not flicker")
  sasuke.awaken=0;fx:update(data,1/60,folder)
  for _,p in bodies.A:GetChildren() do assert(p.Name~="CurseSpread","the curse outlived the awakening") end
 end)
end)
test("client · Sasuke's Dancing Leaf leaves a shadow under the rising body; the vault kick draws its arc",function()
 inScene(function(fx,folder,bodies,advance)
  local sasuke=actorData("A","Lion",{state="Pursuit",lion=1.6})
  local data={phase="Duel",epoch=1,hazards={},projectiles={},human=sasuke,bot=actorData("B","Mirage")}
  local before=#named(fx,"Afterimage")
  for _=1,4 do advance(.08);fx:update(data,1/60,folder) end
  assert(#named(fx,"Afterimage")>=before+3,"no shadow chain under the rising body")
  sasuke.state="Startup";sasuke.lion=0;sasuke.attackName="VaultKick"
  fx:update(data,1/60,folder)
  assert(fx.auras[bodies.A].trail.Enabled,"the vault kick draws no arc")
 end)
end)
test("client · a Chidori bursts along its line where it lands and fizzles when it finds nothing; the Phoenix Flower's steel glints out of the flames",function()
 inScene(function(fx,folder)
  fx:impact({style="finisher",position=V.new(0,3,-3),owner="A",victim="B",fighter="Lion",move="ChidoriThrust",direction=-V.zAxis,serial=1},folder)
  assert(#named(fx,"ChidoriLine")==1,"the Chidori does not burst along its line")
  assert(#named(fx,"ChidoriFizzle")==0,"a landed Chidori fizzled")
  fx:impact({style="whiff",position=V.new(0,3,-2.2),owner="A",fighter="Lion",move="ChidoriThrust",serial=2},folder)
  assert(#named(fx,"ChidoriFizzle")==1,"an empty Chidori does not fizzle")
  local data={phase="Duel",epoch=1,hazards={},human=actorData("A","Lion"),bot=actorData("B","Mirage"),projectiles={
   {id=7,kind="shuriken",origin=V.new(0,4,0),direction=-V.zAxis,speed=90,born=99.7,range=56,owner="A",radius=0,growth=0,infusion="Fire",hidden=true},
   {id=8,kind="shuriken",origin=V.new(2,4,0),direction=-V.zAxis,speed=90,born=99.7,range=56,owner="A",radius=0,growth=0,infusion="Fire"}}}
  fx:sync(data);fx:update(data,1/60,folder)
  assert(#named(fx,"HiddenGlint")==1,"the hidden steel does not glint (or a plain blade did)")
  fx:update(data,1/60,folder)
  assert(#named(fx,"HiddenGlint")==1,"the glint repeats")
  -- The next duel numbers its blades from one again: its hidden steel glints too.
  data.epoch=2
  fx:sync(data);fx:update(data,1/60,folder)
  assert(#named(fx,"HiddenGlint")==1,"a new duel's hidden blade does not glint")
 end)
end)
test("HUD · Sasuke's continuations and risks are said: the Dancing Leaf, the Lion Combo prompt, the hungry curse, the Chidori charge and miss",function()
 hudScene(function(ui)
  local me=plate("Lion",{lion=1.4,airborne=true,cue="SHADOW OF THE DANCING LEAF • HEAVY = LION COMBO"})
  ui:render(duelView(me,plate("Mirage")))
  assert(ui.cue.Text==me.cue,"the Dancing Leaf is not said ("..ui.cue.Text..")")
  assert(ui.hint.Text=="RMB — LION COMBO","the Lion Combo is not prompted ("..ui.hint.Text..")")
  me.lion=0;me.airborne=false;me.awaken=6.5;me.curseHunger=true;me.cue="CURSE MARK • IT DOES NOT LET GO"
  ui:render(duelView(me,plate("Mirage")))
  assert(ui.cue.Text==me.cue,"the curse's hold is not said")
  assert(ui.hp.awake.Text:find("CURSE MARK",1,true) and ui.hp.awake.Text:find("HUNGRY",1,true),"the hungry curse is not said ("..ui.hp.awake.Text..")")
  -- From the other side: the charge can be broken, the miss punished.
  local itachi=plate("Mirage",{cue="CHIDORI MISSED • PUNISH"})
  ui:render(duelView(itachi,plate("Lion",{castId="Chidori",state="TechniqueChannel"})))
  assert(ui.hint.Text:find("BREAK THE CHIDORI CHARGE",1,true),"the Chidori charge is not marked breakable ("..ui.hint.Text..")")
  assert(ui.cue.Text=="CHIDORI MISSED • PUNISH","the missed Chidori is not said")
 end)
end)

print("NinjaDuel identity pass: "..passed.." PASS")
