-- Native movement measurement (Server datamodel, debug build with DevHooks).
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local RS=game:GetService("RunService")
local Http=game:GetService("HttpService")
assert(dev,"no DevHooks")
local function S() return dev:Invoke("state") end
local report={}
local st=S()
if type(st)~="table" or st.phase~="Duel" then dev:Invoke("start","Flashstep","Mirage") end
-- wait for the intro to end (requests answer "Intro" until then)
local t0=os.clock()
repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
local function reset()
 dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false)
 dev:Invoke("place",Vector3.new(0,3,40),Vector3.new(0,3,-70))
 task.wait(.6)
end
local function sample(dur,onFrame)
 local out={};local start=os.clock()
 while os.clock()-start<dur do
  local h=S().human
  local v=h.velocity
  table.insert(out,{t=os.clock()-start,y=h.position.Y,x=h.position.X,z=h.position.Z,vy=v.Y,hs=Vector3.new(v.X,0,v.Z).Magnitude,air=h.airborne,state=h.state})
  if onFrame then onFrame(os.clock()-start) end
  RS.Heartbeat:Wait()
 end
 return out
end
local function jumpStats(samples,y0)
 local apex,take,land=-math.huge,nil,nil
 for i,s in samples do
  if s.y>apex then apex=s.y end
  if not take and s.y>y0+0.3 then take=s.t end
  if take and not land and s.y<=y0+0.3 and s.t>take+.05 then land=s.t end
 end
 local before,after=0,math.huge
 for _,s in samples do
  if take and s.t<take and s.t>take-.15 then before=math.max(before,s.hs) end
  if land and s.t>land and s.t<land+.25 then after=math.min(after,s.hs) end
 end
 return {apex=math.floor((apex-y0)*10)/10,air=take and land and math.floor((land-take)*100)/100 or -1,
  hsBefore=math.floor(before),hsMinAfterLanding=after<math.huge and math.floor(after) or -1}
end
local fwd=Vector3.new(0,0,-1)
-- 1. standing jump
reset()
local y0=S().human.position.Y
dev:Invoke("act","human","Jump")
report.standingJump=jumpStats(sample(1.8),y0)
-- 2. running jump
reset();y0=S().human.position.Y
dev:Invoke("move","human",fwd,5)
task.wait(.8)
dev:Invoke("act","human","Jump")
report.runningJump=jumpStats(sample(1.8),y0)
-- 3. sprint jump
reset();y0=S().human.position.Y
dev:Invoke("move","human",fwd,5);dev:Invoke("sprint","human",true)
task.wait(1.0)
dev:Invoke("act","human","Jump")
report.sprintJump=jumpStats(sample(1.8),y0)
-- 4. run vs sprint steady speed
reset()
dev:Invoke("move","human",fwd,5)
local run=sample(1.2)
reset()
dev:Invoke("move","human",fwd,5);dev:Invoke("sprint","human",true)
local spr=sample(1.2)
local function steady(s) local m=0 for i=math.floor(#s*.6),#s do m=math.max(m,s[i].hs) end return math.floor(m) end
local function accel(s,frac) local top=steady(s) for _,x in s do if x.hs>=top*frac then return math.floor(x.t*100)/100 end end return -1 end
report.run={top=steady(run),t90=accel(run,.9)}
report.sprint={top=steady(spr),t90=accel(spr,.9)}
dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false)
return Http:JSONEncode(report)
