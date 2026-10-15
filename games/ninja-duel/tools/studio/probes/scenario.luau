-- Server: clean scenario (single placement before the probe window). SCEN = "rush" | "atk"
local SCEN="dodge"
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local s=dev:Invoke("state")
if type(s)~="table" or s.phase~="Duel" then dev:Invoke("start","Flashstep","Mirage") end
local t0=os.clock()
repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
dev:Invoke("place",Vector3.new(0,3,if SCEN=="rush" then 30 else 12),Vector3.new(0,3,-10))
task.spawn(function()
 task.wait(2)
 for i=1,5 do
  dev:Invoke("refill")
  if SCEN=="jump" then dev:Invoke("act","human","Jump");task.wait(1.4);continue end
  if SCEN=="dodge" then for _,d in {Vector3.new(1,0,0),Vector3.new(-1,0,0)} do dev:Invoke("move","human",d,.4);dev:Invoke("act","human","Dodge");task.wait(.95);dev:Invoke("move","human",Vector3.zero) end continue end
  dev:Invoke("act","human",if SCEN=="rush" then "Pursuit" else "Attack")
  task.wait(1)
  dev:Invoke("move","human",Vector3.new(0,0,1),1);task.wait(if SCEN=="rush" then 1.1 else .5)
  dev:Invoke("move","human",Vector3.zero);task.wait(.3)
 end
end)
return "scenario "..SCEN
