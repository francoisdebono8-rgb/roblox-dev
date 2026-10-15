local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local s=dev:Invoke("state")
if type(s)~="table" or s.phase~="Duel" then dev:Invoke("start","Flashstep","Mirage") end
local t0=os.clock()
repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
dev:Invoke("move","human",Vector3.zero);dev:Invoke("sprint","human",false)
dev:Invoke("place",Vector3.new(0,3,6),Vector3.new(0,3,-6));dev:Invoke("refill")
dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
dev:Invoke("freezeBot",false);dev:Invoke("scripted",false);dev:Invoke("autopilot",true)
return "fight on: "..tostring(dev:Invoke("state").phase)
