-- Stage 6 (the approved move list, "Ultimes"): one ultimate per main fighter,
-- R1 + L1 (Y). The bar fills by hitting and by being hit; full, the press
-- opens with one blow that either takes both bodies into the sequence or
-- misses and leaves an opening. Plus the awakening moments that came with it
-- (Itachi's Tsukuyomi, Lee's gates one by one, Kakashi's Sharingan only awake).
local H=require("./Harness")
local V=H.V
local Ultimates=H.load("Server/Ultimates")
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
local function until_(c,seconds,cond,message)
 for _=1,math.ceil(seconds/.01) do H.step(c,.01);if cond() then return end end
 error(message)
end
local MAIN={"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf","Legion","Copycat"}

test("every main fighter has one ultimate; the others have none",function()
 for _,id in MAIN do
  local u=Ultimates.DEFS[H.fighters[id].Name]
  assert(u and u.Name and u.Time>=3 and u.Time<=4,id..": no 3-4 s ultimate")
 end
 assert(Ultimates.DEFS[H.fighters.Gale.Name]==nil,"Temari got an ultimate")
end)

test("the bar fills by hitting and by being hit, capped; an empty bar refuses",function()
 local c,a,b=H.duel("Legion","Mirage");place(c,a,b,3)
 assert(not c:request(a,"Ultimate"),"an empty bar fired")
 c:damage(a,b,10,false,false)
 assert(math.abs((a.ultimate or 0)-11)<.01,"dealing did not fill the bar ("..tostring(a.ultimate)..")")
 assert(math.abs((b.ultimate or 0)-8)<.01,"taking did not fill the bar ("..tostring(b.ultimate)..")")
 a.ultimate=99;c:damage(a,b,10,false,false)
 assert(a.ultimate==100 and Ultimates.ready(a),"the bar is not capped at 100")
end)

test("B03 (audit 03/11): with a full bar the bot fires its ultimate; with an empty one it never tries",function()
 local AI=H.load("Server/AI")
 for _,id in MAIN do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,5)
  b.ai=nil;a.ai=nil
  local brain=AI.new(c,a,5)
  local fired=false
  local request=c.request
  c.request=function(self,actor,action,...) if actor==a and action=="Ultimate" then fired=true end;return request(self,actor,action,...) end
  for _=1,300 do brain:update(c.now);H.step(c,.01);if fired then break end;c:relocate(a,V.new(0,3,2.5));c:relocate(b,V.new(0,3,-2.5));a.health=a.def.Health;b.health=b.def.Health end
  assert(not fired,id..": the bot tried an ultimate with an empty bar")
  a.ultimate=100
  for _=1,600 do brain:update(c.now);H.step(c,.01);if fired then break end;c:relocate(a,V.new(0,3,2.5));c:relocate(b,V.new(0,3,-2.5));b.health=b.def.Health end
  assert(fired,id..": the bot sat on a full bar for 6 s at 5 studs")
 end
end)

test("caught: both bodies are held for the sequence, the ticks and the last blow land, the bar is spent",function()
 for _,id in MAIN do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,4)
  b.health=999;a.ultimate=100
  local ok,why=c:request(a,"Ultimate")
  assert(ok,id..": the ultimate was refused ("..tostring(why)..")")
  assert(a.ultimate==0,id..": the bar was not spent")
  local u=Ultimates.def(a)
  until_(c,u.Startup+.2,function() return b.ultimateHeld==true end,id..": the opener did not take the body")
  assert(a.ultimateRunning and b.ultimateHeld,id..": the bodies are not held")
  assert(not c:request(b,"Attack"),id..": the held body could act")
  local before=b.health
  until_(c,u.Time+.4,function() return not b.ultimateHeld end,id..": the sequence never ended")
  H.step(c,.1)
  assert(before-b.health>=u.Damage*.8,string.format("%s: the sequence dealt %.1f of %d",id,before-b.health,u.Damage))
 end
end)

test("each fighter plays his own script: his own clip and the held body's, his own paths, nobody wired, no two alike",function()
 local Scripts=Ultimates.Scripts
 local signatures={}
 for _,id in MAIN do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,4)
  b.health=999;a.ultimate=100
  assert(c:request(a,"Ultimate"))
  local u=Ultimates.def(a)
  assert(a.ultClip==a.fighterId..".Ultimate",id..": the caster's clip did not start at the press ("..tostring(a.ultClip)..")")
  local top,warps,start,moved,clones,bound=0,a.warpSerial or 0,nil,0,{},false
  local samples={}
  local steps=math.ceil((u.Startup+u.Time+.2)/.02)
  for n=1,steps do
   H.step(c,.02)
   if b.ultimateHeld then
    assert(b.ultClip=="Ult."..u.Kind..".Victim",id..": the held body plays "..tostring(b.ultClip))
    start=start or a.root.Position
    moved=math.max(moved,(a.root.Position-start).Magnitude)
   end
   if b.reaction=="Bound" then bound=true end
   top=math.max(top,b.root.Position.Y-3)
   for _,body in c.bodies or {} do if body.alive and body.mode=="ult" then clones[body.id]=true end end
   if n%10==0 and a.ultimateSeq then
    local f=a.ultimateSeq.frame
    local pa,pb=f.anchor(a.root.Position),f.anchor(b.root.Position)
    table.insert(samples,string.format("%.0f,%.0f,%.0f/%.0f",pa.X,pa.Y,pa.Z,pb.Y))
   end
  end
  local sig=table.concat(samples,";")
  signatures[id]=sig
  assert(not bound,id..": the body was wired/bound")
  if id=="Lion" or id=="Leaf" or id=="Legion" then assert(top>8,id..": the body never went up ("..string.format("%.1f",top)..")") end
  if id=="Flashstep" then assert((a.warpSerial or 0)-warps>=8,"Minato did not flash round the body") end
  if id=="Mirage" then assert(moved<.5,"Itachi moved in the Tsukuyomi ("..string.format("%.2f",moved)..")") end
  if id=="Sand" then assert(moved<.5,"Gaara moved in his funeral") end
  if id=="Legion" then
   local n=0;for _ in clones do n+=1 end
   assert(n>=10,"Naruto's clones were not real bodies ("..n..")")
  end
  -- After the sequence: the clips are given back.
  H.step(c,.6)
  assert(a.ultClip==nil and b.ultClip==nil,id..": a clip stayed on after the sequence")
  print("   "..id..": "..#samples.." samples, top "..string.format("%.1f",top))
 end
 for x,sx in signatures do for y,sy in signatures do assert(x==y or sx~=sy,x.." and "..y.." follow the same paths") end end
end)

test("the scripts: every path starts at the catch, every blow inside the sequence, every shot cut in time order",function()
 local Scripts=Ultimates.Scripts
 for name,u in Ultimates.DEFS do
  local s=Scripts.KINDS[u.Kind]
  assert(s,name..": no script")
  for _,path in {s.caster,s.victim} do
   assert(path[1][1]==0,name..": a path does not start at the catch")
   for i=2,#path do assert(path[i][1]>=path[i-1][1],name..": a path goes back in time at key "..i) end
  end
  for _,blow in s.blows do assert(blow[1]>0 and blow[1]<u.Time-.3,name..": a blow at "..blow[1].." is outside the sequence") end
  for i=2,#s.shots do assert(s.shots[i][1]>s.shots[i-1][1],name..": shots out of order") end
  assert(u.Blows==#s.blows)
 end
 -- The frame round trip.
 local f=Scripts.frame(V.new(10,3,5),V.new(1,0,0))
 local w=f.world(V.new(1,2,3))
 assert((f.anchor(w)-V.new(1,2,3)).Magnitude<1e-4,"anchor/world do not agree")
 assert(#Scripts.palmTimes()>=40,"Neji's palms are not a rain")
end)

test("the authored clips: one per caster from the press, one per held body from the catch, long enough",function()
 local ok,clips=pcall(function() return H.load("Client/AuthoredClips") end)
 assert(ok and clips,"no authored clips")
 for _,id in MAIN do
  local u=H.fighters[id] and Ultimates.DEFS[H.fighters[id].Name]
  local caster=clips[id..".Ultimate"]
  assert(caster,id..".Ultimate is missing")
  assert(caster.length>=u.Startup+u.Time-.01,id..".Ultimate is too short ("..caster.length..")")
  local victim=clips["Ult."..u.Kind..".Victim"]
  assert(victim and victim.length>=u.Time-.01,"Ult."..u.Kind..".Victim is missing or short")
 end
end)

test("missed: out of reach or dodged, the bar is gone and the caster is open",function()
 local c,a,b=H.duel("Lion","Mirage");place(c,a,b,4)
 a.ultimate=100
 assert(c:request(a,"Ultimate"))
 c:relocate(b,V.new(0,3,-40))
 H.step(c,Ultimates.def(a).Startup+.05)
 assert(not b.ultimateHeld and a.ultimate==0,"a body out of reach was caught")
 assert(a.state=="Recovery" and a.untilTime-c.now>.6,"the miss left no opening")
end)

test("Itachi's awakening: the Tsukuyomi holds a body in sight for 1.5 s, once",function()
 local c,a,b=H.duel("Mirage","Flashstep");place(c,a,b,8)
 a.health=a.def.Health*.3;a.hum.Health=a.health
 assert(c:request(a,"Awaken"),"the awakening was refused")
 H.step(c,.05)
 assert(b.reaction=="Bound","the Tsukuyomi did not hold the body ("..tostring(b.reaction)..")")
 H.step(c,1.6)
 assert(b.reaction~="Bound","the Tsukuyomi held longer than 1.5 s")
end)

test("Lee's gates open one by one inside the awakening; Kakashi's Sharingan only awake",function()
 local Combat=H.load("Server/Combat")
 local c,a=H.duel("Leaf","Mirage")
 a.health=a.def.Health*.3;a.hum.Health=a.health
 assert(c:request(a,"Awaken"))
 local gates={}
 for k=0,4 do gates[k+1]=Combat.gateOf(a,c.now+k*4+.01) end
 assert(table.concat(gates,",")=="1,2,3,4,5","the gates do not open one every 4 s ("..table.concat(gates,",")..")")
 assert(Combat.gateOf(a,c.now+30)==5,"a sixth gate opened")
 assert(H.fighters.Copycat.SharinganAwake==true,"Kakashi's Sharingan is not awake-only")
end)

test("client: every ultimate contact and every cue of every script draws without error",function()
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  local UltimateFX=H.load("Client/UltimateFX")
  local Scripts=Ultimates.Scripts
  local fx=FX.new()
  local folder=instance("Folder")
  for _,id in {"A","B"} do
   local m=instance("Model");m.Name=id;m.Parent=folder
   local p=instance("Part");p.Name="HumanoidRootPart";p.CFrame=H.C.new(0,3,if id=="A" then 2 else -2);p.Size=V.one;p.Parent=m
   local hand=instance("Part");hand.Name="RightHand";hand.CFrame=H.C.new(.8,2.5,if id=="A" then 1.5 else -1.5);hand.Size=V.one;hand.Parent=m
  end
  local serial=0
  local function draw(impact)
   serial+=1;impact.serial=serial;impact.position=impact.position or V.new(0,3,-2)
   local before=#fx.folder:GetDescendants()
   fx:impact(impact,folder)
   return #fx.folder:GetDescendants()>before
  end
  for kind,spec in Scripts.KINDS do
   assert(draw({style="ultimateStart",owner="A",kind=kind,name=kind}),kind..": the press drew nothing")
   draw({style="ultimate",owner="A",victim="B",kind=kind,name=kind,time=3.4,origin=V.new(0,3,-2),line=V.new(0,0,-1)})
   for i,blow in spec.blows do draw({style="ultimateTick",owner="A",victim="B",kind=kind,index=i,heavy=blow[2],text=blow[3]}) end
   -- Every cue of the script, on a live context (the delays are Studio's).
   local ctx=UltimateFX.context(fx,{kind=kind,owner="A",victim="B",time=3.4,origin=V.new(0,3,-2),line=V.new(0,0,-1),position=V.new(0,3,-2),serial=1},folder,UltimateFX.LOOK[kind])
   fx.ultimateRun=ctx.token
   for _,cue in spec.cues do
    local name=cue[2]
    if string.sub(name,1,5)~="text:" then
     local fn=UltimateFX.CUE[name]
     assert(fn,kind..": no drawing for the cue "..name)
     fn(ctx)
    end
   end
   assert(draw({style="ultimateEnd",owner="A",victim="B",kind=kind}),kind..": the last blow drew nothing")
  end
  assert(draw({style="ultimateKunai",owner="A",points={V.new(3,3,0),V.new(-3,3,0)}}),"Minato's kunai drew nothing")
  assert(draw({style="ultimateMiss",owner="A",kind="lion"}),"the miss drew nothing")
  assert(draw({style="tsukuyomi",owner="A",victim="B",time=1.5}),"the Tsukuyomi drew nothing")
  assert(draw({style="gate",owner="A",fighter="Leaf",gate=3}),"the gate drew nothing")
  assert(draw({style="reveal",owner="A",body="B"}),"the reveal drew nothing")
 end)
 restore()
 assert(ok,err)
end)

test("camera: every script's shot list resolves to a lens at every moment",function()
 local Scripts=Ultimates.Scripts
 for kind in Scripts.KINDS do
  for t=0,4,.1 do
   local eye,at,fov=Scripts.shot(kind,t,function(name) return if name=="caster" then V.new(0,0,-4) else V.new(0,2,0) end)
   assert(eye and at and fov and fov>20 and fov<80,kind..": no lens at "..t)
   assert((eye-at).Magnitude>.5,kind..": the eye sits on its target at "..t)
  end
 end
end)

print("NinjaDuel ultimates and awakenings: "..passed.." PASS (headless; the cinematics are a Studio check)")
