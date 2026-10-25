-- Movement overhaul (docs/movement/MOVEMENT_OVERHAUL_AUDIT.md): the context
-- picks the acrobatics, each fighter's level decides who does them, the body
-- really turns over, a committed action cancels the rotation, and a dodge
-- hands its momentum back. Headless mechanics only: the look and the feel
-- are Studio checks.
local H=require("./Harness")
local V=H.V
local Vector3=H.roblox.Vector3
local passed=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if ok then passed+=1;print("PASS "..name)
 else print("FAIL "..name..": "..tostring(err));error(name..": "..tostring(err),0) end
end
local Motion=H.load("Client/VelmoraMotionEngine")
local AXIS_Y=H.roblox.CFrame.identity.UpVector
local function upY(transform) return transform:VectorToObjectSpace(AXIS_Y).Y end
local function frame(model,actor,dt)
 Motion.tick(dt or 1/60)
 return Motion.present(model,actor,{},dt or 1/60)
end
local function body(a,over)
 local out={fighterId=a.fighterId,state="Neutral",health=100,attackElapsed=0,reactionElapsed=0,airborne=false,
  velocity=Vector3.zero,speed=0,landing=false}
 for k,v in over or {} do out[k]=v end
 return out
end
-- One fighter standing still, then taking off with a velocity given in its own
-- frame (x right, z forward); returns the trick chosen on the takeoff frame.
local function takeoff(id,side,forward,up)
 local c,a=H.duel(id,if id=="Flashstep" then "Mirage" else "Flashstep")
 Motion.reset(a.model)
 local look=a.root.CFrame.LookVector
 local right=a.root.CFrame.RightVector
 local v=right*side+look*forward+V.new(0,up,0)
 for _=1,10 do frame(a.model,body(a)) end
 frame(a.model,body(a,{airborne=true,velocity=v,speed=v.Magnitude}))
 return Motion.trickOf(a.model),a,v
end

test("a backward jump with momentum is a back flip for an acrobat, a lean for Gaara",function()
 local trick=takeoff("Leaf",0,-24,40)
 assert(trick and trick.kind=="back","Lee's backward jump did not flip (got "..tostring(trick and trick.kind)..")")
 assert(takeoff("Sand",0,-24,40)==nil,"Gaara flips")
 assert(takeoff("Rinnegan",0,-24,40)==nil,"Nagato flips")
end)

test("a side jump with momentum is a side flip; a slow or plain hop never turns",function()
 local trick=takeoff("Lion",24,0,40)
 assert(trick and trick.kind=="side" and trick.sign==1,"Sasuke's side jump is not a side flip to his right")
 assert(takeoff("Leaf",0,8,40)==nil,"a walking hop flipped")
 assert(takeoff("Leaf",0,-24,4)==nil,"stepping off a ledge flipped")
 -- A plain sprint jump stays a leap (most long jumps in the references are leaps).
 assert(takeoff("Leaf",0,36,40)==nil,"every sprint jump flips")
end)

test("a chained launched jump front-flips, and never twice in a row",function()
 local c,a=H.duel("Leaf","Flashstep")
 Motion.reset(a.model)
 local look=a.root.CFrame.LookVector
 local leap=look*36+V.new(0,40,0)
 for _=1,10 do frame(a.model,body(a)) end
 local function hop()
  frame(a.model,body(a,{airborne=true,velocity=leap,speed=36}))
  local t=Motion.trickOf(a.model)
  for _=1,40 do frame(a.model,body(a,{airborne=true,velocity=leap*.5,speed=18})) end
  frame(a.model,body(a,{velocity=look*36,speed=36}))
  return t
 end
 local first,second,third=hop(),hop(),hop()
 assert(first==nil,"the first sprint jump flipped")
 assert(second and second.kind=="front","the chained launched jump did not front-flip")
 assert(third==nil,"two front flips in a row")
end)

test("the body really turns over at the top of a flip, then comes back upright",function()
 local trick,a,v=takeoff("Leaf",0,-24,40)
 assert(trick,"no flip to measure")
 local mid,low=1,1
 local frames=math.floor(trick.dur*60)
 for i=1,frames+20 do
  frame(a.model,body(a,{airborne=true,velocity=v,speed=v.Magnitude}))
  local y=upY(a.model.joints.Root.Transform)
  if i>frames*.3 and i<frames*.7 then low=math.min(low,y) end
  mid=y
 end
 assert(low<-.3,string.format("the body never went upside down (lowest up.y %.2f)",low))
 assert(mid>.8,string.format("the body stayed turned after the flip (up.y %.2f)",mid))
end)

test("a strike, a hit or a dodge cancels the flip at once",function()
 for _,over in {{attackName="Air1",state="Startup"},{reaction="Juggled"},{state="Dodging"}} do
  local trick,a,v=takeoff("Leaf",0,-24,40)
  assert(trick,"no flip to cancel")
  local o=table.clone(over);o.airborne=true;o.velocity=v;o.speed=v.Magnitude
  frame(a.model,body(a,o))
  assert(Motion.trickOf(a.model)==nil,"the flip kept going through "..tostring(over.attackName or over.reaction or over.state))
 end
end)

test("leaving a wall flips the acrobats off it",function()
 local c,a=H.duel("Flashstep","Mirage")
 Motion.reset(a.model)
 for _=1,10 do frame(a.model,body(a,{wall=true,airborne=true,velocity=V.new(0,12,0)})) end
 frame(a.model,body(a,{airborne=true,velocity=V.new(0,30,-20),speed=36}))
 local t=Motion.trickOf(a.model)
 assert(t and t.kind=="wall","Minato does not flip off the wall")
end)

test("a flip lands in the ninja crouch, arms out",function()
 local trick,a,v=takeoff("Leaf",0,-24,40)
 for _=1,math.floor(trick.dur*60)+2 do frame(a.model,body(a,{airborne=true,velocity=v,speed=v.Magnitude})) end
 local branch
 for _=1,10 do branch=frame(a.model,body(a,{landing=true,landingPhase=.2,velocity=V.zero})) end
 assert(branch=="landing","no landing after the flip")
 local root=a.model.joints.Root.Transform.Position.Y
 Motion.reset(a.model)
 for _=1,10 do frame(a.model,body(a,{landing=true,landingPhase=.2,velocity=V.zero})) end
 assert(root<a.model.joints.Root.Transform.Position.Y-.15,"the post-flip landing is not lower than a plain one")
end)

test("acrobatic side and back dodges turn the body; the others slide",function()
 local function lowest(id,dir)
  local c,a=H.duel(id,if id=="Flashstep" then "Mirage" else "Flashstep")
  Motion.reset(a.model)
  local v=(if dir=="side" then a.root.CFrame.RightVector else -a.root.CFrame.LookVector)*35
  local low=1
  for _=1,19 do
   frame(a.model,body(a,{state="Dodging",velocity=v,speed=35}))
   low=math.min(low,upY(a.model.joints.Root.Transform))
  end
  return low
 end
 assert(lowest("Leaf","side")<.2,"Lee's side dodge is no cartwheel")
 assert(lowest("Lion","back")<.2,"Sasuke's back dodge is no handspring")
 assert(lowest("Sand","side")>.6,"Gaara cartwheels")
 assert(lowest("Mirage","back")>.6,"Itachi handsprings")
end)

test("every dodge turns the body, not only the first (the dodge clock restarts)",function()
 local c,a=H.duel("Leaf","Mirage")
 Motion.reset(a.model)
 local v=a.root.CFrame.RightVector*35
 local function dodge()
  local low=1
  for _=1,19 do frame(a.model,body(a,{state="Dodging",velocity=v,speed=35}));low=math.min(low,upY(a.model.joints.Root.Transform)) end
  return low
 end
 local first=dodge()
 for _=1,30 do frame(a.model,body(a,{velocity=v,speed=20})) end
 local second=dodge()
 assert(first<.2,"the first dodge did not turn the body")
 assert(second<.2,string.format("the second dodge stood upright (up.y %.2f)",second))
end)

test("a dodge hands its momentum back: the run continues out of it",function()
 local c,a,b=H.duel("Flashstep","Mirage")
 c:relocate(a,V.new(0,3,20));c:relocate(b,V.new(30,3,-20))
 local dir=V.new(1,0,0)
 a.move=dir
 for _=1,60 do H.step(c,.01) end
 local ok,why=c:request(a,"Dodge")
 assert(ok,"dodge refused: "..tostring(why))
 local n=0
 repeat H.step(c,.01);n+=1 until a.state~="Dodging" or n>60
 assert(a.state~="Dodging","still dodging")
 H.step(c,.01)
 -- The server's own ground locomotion (the harness has no physics solver).
 local speed=(a.locomotion or V.zero).Magnitude
 assert(speed>=(a.def.Speed or 18)*.8,string.format("the dodge stopped the run (%.1f studs/s after it)",speed))
 -- Without input the carry fades (no free gliding).
 a.move=V.zero
 for _=1,80 do H.step(c,.01) end
 assert((a.locomotion or V.zero).Magnitude<1,"the body keeps gliding after a dodge with no input")
end)

test("a back dodge near them keeps the chest on them; running off, it is a dash along the run",function()
 local function dodgeAway(gap,walk)
  local c,a,b=H.duel("Leaf","Mirage")
  c:relocate(b,V.new(0,3,0));c:relocate(a,V.new(0,3,gap))
  a.root.CFrame=H.roblox.CFrame.lookAt(a.root.Position,V.new(0,3,0))
  a.move=V.new(0,0,1)
  for _=1,math.floor(walk/.01) do H.step(c,.01) end
  assert(c:request(a,"Dodge"),"dodge refused")
  local keep=a.evade and a.evade.keep
  local n=0
  repeat H.step(c,.01);n+=1 until a.state~="Dodging" or n>60
  local to=(b.root.Position-a.root.Position)*V.new(1,0,1)
  return keep,a.root.CFrame.LookVector:Dot(to.Unit)
 end
 local keep,face=dodgeAway(12,.12)
 assert(keep,"a back dodge close in did not keep the chest on them")
 assert(face>.7,string.format("the back dodge turned away from them (%.2f)",face))
 local keep2=dodgeAway(30,.6)
 assert(not keep2,"running off (committed facing), the dodge still turned back to them")
end)

test("a side dodge out of a sprint keeps the run's facing (no 90-degree root pivot)",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(-60,3,30));c:relocate(b,V.new(60,3,-30))
 a.move=V.new(1,0,0);a.sprinting=true
 local n=0
 repeat H.step(c,.01);n+=1 until (a.locomotion or V.zero).Magnitude>=30 or n>300
 local look0=a.root.CFrame.LookVector
 a.move=V.new(0,0,1)
 assert(c:request(a,"Dodge"),"dodge refused")
 local worst=1
 for _=1,30 do H.step(c,.01);worst=math.min(worst,a.root.CFrame.LookVector:Dot(look0)) end
 assert(worst>.94,string.format("the side dodge pivoted the root (cos %.2f)",worst))
end)

test("an opening light in a full sprint is the running strike, carried by the run; walking or mid-string it is not",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(-60,3,0));c:relocate(b,V.new(40,3,0))
 a.move=V.new(1,0,0);a.sprinting=true
 local n=0
 repeat H.step(c,.01);n+=1 until (a.locomotion or V.zero).Magnitude>=30 or n>300
 assert((a.locomotion or V.zero).Magnitude>=30,"never reached sprint speed")
 local from=a.root.Position
 assert(c:request(a,"Attack"))
 -- The fighter's own running entry (Lee: the flying kick), not the plain opener.
 assert(a.attackName and a.attackName~="Light1","a sprinting light was "..tostring(a.attackName))
 for _=1,25 do H.step(c,.01) end
 local moved=V.new(a.root.Position.X-from.X,0,a.root.Position.Z-from.Z).Magnitude
 assert(moved>=6,string.format("the running strike stopped the run (%.1f studs in the swing)",moved))
 -- After the recovery the run picks up from part of its speed, not from a stand.
 -- Through the recovery the body slides on (no dead stop).
 local n2=0
 repeat H.step(c,.01);n2+=1 until a.state=="Recovery" or n2>100
 local slideFrom=a.root.Position
 repeat H.step(c,.01);n2+=1 until a.state=="Neutral" or n2>200
 local slid=V.new(a.root.Position.X-slideFrom.X,0,a.root.Position.Z-slideFrom.Z).Magnitude
 assert(slid>=2,string.format("the body stood still through the recovery (%.1f studs)",slid))
 H.step(c,.01)
 assert((a.locomotion or V.zero).Magnitude>=18,string.format("the run restarted from a stand after the strike (%.1f)",(a.locomotion or V.zero).Magnitude))
 -- Walking: the plain opener.
 local c2,a2,b2=H.duel("Leaf","Mirage")
 c2:relocate(a2,V.new(-60,3,0));c2:relocate(b2,V.new(40,3,0))
 a2.move=V.new(1,0,0);a2.sprinting=false
 for _=1,60 do H.step(c2,.01) end
 assert(c2:request(a2,"Attack"));assert(a2.attackName=="Light1","a walking light was "..tostring(a2.attackName))
end)

test("a jump-in air strike with nobody in reach rides the leap: no hold",function()
 local c,a,b=H.duel("Leaf","Mirage")
 c:relocate(a,V.new(-60,3,0));c:relocate(b,V.new(60,3,0))
 a.move=V.new(1,0,0);a.sprinting=true
 local n=0
 repeat H.step(c,.01);n+=1 until (a.locomotion or V.zero).Magnitude>=30 or n>300
 assert(c:request(a,"Jump"),"jump refused")
 for _=1,10 do H.step(c,.01) end
 local before=(a.locomotion or V.zero).Magnitude
 assert(c:request(a,"Attack"))
 assert(a.attackName=="Air1" or (a.attackName or ""):find("Air"),"no air strike ("..tostring(a.attackName)..")")
 assert((a.airHold or 0)<=c.now,"the out-of-reach air strike froze the leap")
 -- (The brake itself is a physics effect: measured in Studio, see
 -- docs/movement/MOVEMENT_OVERHAUL_AUDIT.md; the harness has no air velocity.)
 local _=before
end)

test("walls: a shallow entry runs along the wall, a steep one climbs; the wall jump keeps the run along it",function()
 -- Real wall planes (Harness.addWall: x = X, facing -X), the server's own step.
 local function enter(dir,speed)
  H.clearWalls();local part=H.addWall(10)
  local c,a,b=H.duel("Leaf","Mirage")
  c:relocate(a,V.new(8,3,0));c:relocate(b,V.new(-40,3,60))
  a.move=V.zero;H.step(c,.01) -- the movement donors exist after a step
  a.locomotion=dir*speed;a.move=dir
  H.step(c,.01)
  return c,a,part
 end
 -- Shallow (45 degrees in): a run along the wall from the entry speed.
 local c,a=enter(V.new(1,0,-1).Unit,50)
 assert(a.wall and a.wall.mode=="run","a shallow entry did not run along the wall ("..tostring(a.wall and a.wall.mode)..")")
 local z0,y0=a.root.Position.Z,a.root.Position.Y
 -- Studio: the courtyard wall is a ring of segments; crossing a seam onto the
 -- next segment is the same wall, not a fall off it.
 H.clearWalls();H.addWall(10)
 for _=1,20 do H.step(c,.01) end
 assert(a.wall~=nil,"the run fell off at a wall seam")
 assert(a.root.Position.Z<z0-5,string.format("the run did not travel along the wall (%.1f studs)",z0-a.root.Position.Z))
 assert(a.root.Position.Y>y0+1,"the run stayed on the floor (no arc up the wall)")
 local early=a.wall.motion and V.new(a.wall.motion.X,0,a.wall.motion.Z).Magnitude or 0
 for _=1,40 do H.step(c,.01) end
 local late=a.wall and a.wall.motion and V.new(a.wall.motion.X,0,a.wall.motion.Z).Magnitude or 0
 assert(early>late,string.format("the wall run does not lose speed (%.1f -> %.1f)",early,late))
 -- The wall jump keeps most of the run along the wall.
 assert(a.wall,"the run ended before the jump")
 local runSpeed=late
 assert(c:request(a,"Jump") and a.wall==nil,"no wall jump")
 local v=a.root.AssemblyLinearVelocity
 assert(-v.Z>=runSpeed*.7,string.format("the wall jump dropped the run along the wall (%.1f of %.1f)",-v.Z,runSpeed))
 assert(v.Y>20 and v.X<-10,"the wall jump does not leave the wall upward and outward")
 -- Steep (straight in): a climb, as high as the entry speed carries.
 local function climb(speed)
  local c2,a2=enter(V.new(1,0,0),speed)
  assert(a2.wall and a2.wall.mode=="climb","a straight entry did not climb")
  local top=a2.root.Position.Y
  for _=1,300 do H.step(c2,.01);top=math.max(top,a2.root.Position.Y);if not a2.wall then break end end
  return top
 end
 local fast,slow=climb(54),climb(19)
 assert(fast>slow+3,string.format("the climb height does not follow the entry speed (%.1f vs %.1f)",fast,slow))
 H.clearWalls()
end)

test("the client draws a wall run as a run leaning into the wall, not the climb turned sideways",function()
 local c,a=H.duel("Leaf","Mirage")
 Motion.reset(a.model)
 for _=1,30 do frame(a.model,body(a,{wall=true,wallMode="run",wallSide=1,airborne=true,velocity=V.new(0,0,-30),speed=30})) end
 local run=a.model.joints.Root.Transform
 Motion.reset(a.model)
 for _=1,30 do frame(a.model,body(a,{wall=true,airborne=true,velocity=V.new(0,12,0),speed=12})) end
 local climb=a.model.joints.Root.Transform
 assert(upY(run)>.6,string.format("the wall run is not upright (up.y %.2f)",upY(run)))
 assert(upY(climb)<.5,string.format("the climb is not lying on the wall (up.y %.2f)",upY(climb)))
end)

test("the full sprint is each fighter's: Lee drives low, Itachi stays economical",function()
 local function sprintPitch(id)
  local c,a=H.duel(id,if id=="Flashstep" then "Mirage" else "Flashstep")
  Motion.reset(a.model)
  local v=a.root.CFrame.LookVector*44
  for _=1,40 do frame(a.model,body(a,{velocity=v,speed=44,sprinting=true})) end
  -- Forward pitch of the root joint (its up axis tipped toward the run).
  local up=a.model.joints.Root.Transform:VectorToObjectSpace(AXIS_Y)
  return up.Z
 end
 local lee,itachi=sprintPitch("Leaf"),sprintPitch("Mirage")
 assert(math.abs(lee)>math.abs(itachi)+.05,string.format("Lee's sprint is no lower than Itachi's (%.2f vs %.2f)",lee,itachi))
end)

print(string.format("NinjaDuel movement overhaul: %d PASS (headless; the look and feel are Studio checks)",passed))
