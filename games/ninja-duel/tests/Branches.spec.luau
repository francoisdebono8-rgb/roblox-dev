-- Phase 3 move graphs and cancel rules: directional branches inside a clean
-- string, disengages, Itachi's Read counter, Rasengan as a string finisher,
-- Flying Thunder God onto a kunai in flight, and the travelling fireball.
local H=require("./Harness")
local V=H.V
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local function face(c,a,b,gap)
 gap=gap or 4.5
 c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
end
-- Land a first light and stop inside its open chain window.
local function confirm(c,a,b)
 face(c,a,b)
 assert(c:request(a,"Attack"),"first light refused")
 for _=1,80 do
  H.step(c,.01)
  if a.state=="Recovery" and a.chainOpen and c.now>=a.chainAt then return end
 end
 error("the chain never opened ("..tostring(a.state)..")")
end
local function angleAround(b,p)
 local d=p-b.root.Position
 return math.atan2(d.X,d.Z)
end

test("Minato: side input inside a clean string swings around the guard",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 confirm(c,a,b)
 local before=angleAround(b,a.root.Position)
 a.move=a.root.CFrame.RightVector
 assert(c:request(a,"Attack"),"branch press refused")
 assert(a.attackName=="AngleStep","side input did not pick AngleStep: "..tostring(a.attackName))
 H.step(c,.3)
 local after=angleAround(b,a.root.Position)
 local turned=math.deg(math.abs((after-before+math.pi)%(2*math.pi)-math.pi))
 assert(turned>12,"AngleStep did not change the angle ("..string.format("%.1f",turned).." deg)")
 a.move=V.zero
 H.step(c,.6)
 assert(a.pending==nil,"AngleStep left a committed swing")
end)
test("Minato: back input disengages behind a kunai and ends the string",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 confirm(c,a,b)
 local gap=(a.root.Position-b.root.Position).Magnitude
 a.move=-a.root.CFrame.LookVector
 assert(c:request(a,"Attack"),"disengage refused")
 assert(a.state=="Recovery" and not a.chainOpen,"disengage kept the string open")
 local thrown=0
 for _=1,40 do H.step(c,.01);thrown=math.max(thrown,#c.projectiles) end
 assert(thrown>=1,"no kunai covered the retreat")
 assert((a.root.Position-b.root.Position).Magnitude>gap+2.5,"disengage did not create space")
end)
test("Itachi: side input trades the string for a knockdown sweep",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 confirm(c,a,b)
 a.move=a.root.CFrame.RightVector
 assert(c:request(a,"Attack"),"sweep refused")
 assert(a.attackName=="Sweep","side input did not pick the sweep: "..tostring(a.attackName))
 local downed=false
 for _=1,60 do H.step(c,.01);if b.reaction=="Knockdown" then downed=true end end
 assert(downed,"the sweep did not knock the opponent down")
end)
test("Itachi: back input hops away behind two shuriken",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 confirm(c,a,b)
 a.move=-a.root.CFrame.LookVector
 assert(c:request(a,"Attack"),"disengage refused")
 local thrown=0
 for _=1,50 do H.step(c,.01);thrown=math.max(thrown,#c.projectiles) end
 assert(thrown>=2,"Itachi covered the retreat with fewer than two shuriken")
end)
test("blocked lights keep no string; Itachi alone may cancel into shuriken",function()
 for _,fighter in {"Flashstep","Mirage"} do
  local c,a,b=H.duel(fighter,if fighter=="Flashstep" then "Mirage" else "Flashstep")
  face(c,a,b)
  assert(c:request(b,"Guard"),"guard refused")
  H.step(c,.3) -- past the parry window: a plain block
  assert(c:request(a,"Attack"),"light refused")
  for _=1,60 do H.step(c,.01);if a.state=="Recovery" then break end end
  assert(a.hitBlocked,"the guarded light was not marked as blocked")
  assert(not a.chainOpen,"a blocked light opened a string")
  H.step(c,.02)
  local tool=c:request(a,"Tool",b.root.Position)
  if fighter=="Mirage" then assert(tool,"Itachi could not cancel a blocked light into shuriken")
  else assert(not tool,"Minato cancelled a blocked light into a kunai") end
 end
end)
test("Itachi: a successful Read opens the counter palm",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 face(c,a,b)
 local slot
 for i,spec in a.def.Techniques do if spec.Id=="Read" then slot=i end end
 assert(c:request(a,"Technique"..slot,b.root.Position),"Read refused")
 H.step(c,.2)
 assert(a.readUntil>c.now,"the Read window never opened")
 assert(not c:damage(b,a,8,false,true),"Read let a frontal strike through")
 assert((a.counterUntil or 0)>c.now,"Read success did not open the counter")
 H.step(c,.3)
 assert(c:request(a,"Attack"),"counter press refused")
 assert(a.attackName=="CounterPalm","Read did not lead into the counter palm: "..tostring(a.attackName))
end)
test("Minato: a clean string can be spent on Rasengan",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 confirm(c,a,b)
 local slot
 for i,spec in a.def.Techniques do if spec.Id=="BurstStrike" then slot=i end end
 assert(c:request(a,"Technique"..slot,b.root.Position),"Rasengan cancel refused")
 assert(a.state=="TechniqueChannel","Rasengan did not start channelling")
 assert(a.untilTime-c.now<=.15,"the string cancel did not shorten the wind-up")
end)
test("Flying Thunder God reaches a marked kunai in flight and strikes on arrival",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 face(c,a,b,30)
 local mark,flash
 for i,spec in a.def.Techniques do
  if spec.Id=="MarkedBlade" then mark=i elseif spec.Id=="Flashstep" then flash=i end
 end
 assert(c:request(a,"Technique"..mark,b.root.Position+V.new(12,0,0)),"marked kunai refused")
 for _=1,25 do H.step(c,.01) end
 assert(c:markedInFlight(a),"the marked kunai is not in flight")
 local start=a.root.Position
 assert(c:request(a,"Technique"..flash),"Flying Thunder God refused while the kunai flies")
 for _=1,12 do H.step(c,.01) end
 assert((a.root.Position-start).Magnitude>8,"Minato did not relocate onto the kunai")
 assert((a.flashUntil or 0)>c.now,"the arrival strike window is closed")
 assert(c:request(a,"Attack"),"no strike on arrival")
 assert(a.state=="Startup","the arrival strike did not start")
end)
test("Great Fireball travels across the stage and connects at range",function()
 local c,a,b=H.duel("Mirage","Flashstep")
 face(c,a,b,34)
 local slot
 for i,spec in a.def.Techniques do if spec.Id=="FireBloom" then slot=i end end
 local health=b.health
 assert(c:request(a,"Technique"..slot,b.root.Position),"fireball refused")
 local seen=false
 for _=1,200 do
  H.step(c,.01)
  for _,p in c.projectiles do if p.kind=="fireball" then seen=true end end
  if b.health<health then break end
 end
 assert(seen,"no travelling fireball was created")
 assert(b.health<health,"the fireball never reached the opponent 34 studs away")
end)
print(string.format("NinjaDuel move graphs: %d PASS",passed))
