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

print(string.format("NinjaDuel movement overhaul: %d PASS (headless; the look and feel are Studio checks)",passed))
