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

test("caught: both bodies are held for the sequence, the ticks and the last blow land, the bar is spent",function()
 for _,id in MAIN do
  local c,a,b=H.duel(id,"Mirage");place(c,a,b,4)
  b.health=999;a.ultimate=100
  local ok,why=c:request(a,"Ultimate")
  assert(ok,id..": the ultimate was refused ("..tostring(why)..")")
  assert(a.ultimate==0,id..": the bar was not spent")
  local u=Ultimates.def(a)
  until_(c,u.Startup+.2,function() return b.ultimateHeld==true end,id..": the opener did not take the body")
  assert(a.ultimateRunning and b.reaction=="Bound",id..": the bodies are not held")
  assert(not c:request(b,"Attack"),id..": the held body could act")
  local before=b.health
  until_(c,u.Time+.4,function() return not b.ultimateHeld end,id..": the sequence never ended")
  H.step(c,.1)
  assert(before-b.health>=u.Damage*.8,string.format("%s: the sequence dealt %.1f of %d",id,before-b.health,u.Damage))
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

test("client: every ultimate contact, the Tsukuyomi, a gate and the reveal draw without error",function()
 local instance,restore=H.stubScene()
 local ok,err=pcall(function()
  local FX=H.load("Client/Effects")
  local UltimateFX=H.load("Client/UltimateFX")
  local fx=FX.new()
  local folder=instance("Folder")
  for _,id in {"A","B"} do
   local m=instance("Model");m.Name=id;m.Parent=folder
   local p=instance("Part");p.Name="HumanoidRootPart";p.CFrame=H.C.new(0,3,if id=="A" then 2 else -2);p.Size=V.one;p.Parent=m
  end
  local serial=0
  local function draw(impact)
   serial+=1;impact.serial=serial;impact.position=impact.position or V.new(0,3,-2)
   local before=#fx.folder:GetDescendants()
   fx:impact(impact,folder)
   return #fx.folder:GetDescendants()>before
  end
  for kind in UltimateFX.LOOK do
   assert(draw({style="ultimateStart",owner="A",kind=kind,name=kind}),kind..": the press drew nothing")
   draw({style="ultimate",owner="A",victim="B",kind=kind,name=kind,time=3.4})
   assert(draw({style="ultimateTick",owner="A",victim="B",kind=kind,index=3,heavy=true}),kind..": a blow drew nothing")
   assert(draw({style="ultimateEnd",owner="A",victim="B",kind=kind}),kind..": the last blow drew nothing")
   -- Each sequence's beat runs on its own (the loop is a task in Studio).
   UltimateFX.BEAT[kind](fx,V.new(0,3,-2),UltimateFX.LOOK[kind],{NextNumber=function() return .5 end},2)
  end
  assert(draw({style="ultimateMiss",owner="A",kind="lion"}),"the miss drew nothing")
  assert(draw({style="tsukuyomi",owner="A",victim="B",time=1.5}),"the Tsukuyomi drew nothing")
  assert(draw({style="gate",owner="A",fighter="Leaf",gate=3}),"the gate drew nothing")
  assert(draw({style="reveal",owner="A",body="B"}),"the reveal drew nothing")
 end)
 restore()
 assert(ok,err)
end)

print("NinjaDuel ultimates and awakenings: "..passed.." PASS (headless; the cinematics are a Studio check)")
