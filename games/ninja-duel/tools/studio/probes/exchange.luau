-- Server: one clean scripted exchange, started after DELAY so a client recording
-- can start first. SCEN = "string" | "launch" | "heavy" | "guarded".
local SCEN="string"
local DELAY=2.5
local A,B="Flashstep","Mirage"
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
workspace:SetAttribute("NdCapGen",(workspace:GetAttribute("NdCapGen") or 0)+1)
local s=dev:Invoke("state")
if type(s)~="table" or s.phase~="Duel" then
 dev:Invoke("start",A,B)
 local t0=os.clock()
 repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
end
dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
dev:Invoke("move","human",Vector3.zero);dev:Invoke("move","bot",Vector3.zero)
dev:Invoke("act","human","GuardOff");dev:Invoke("act","bot","GuardOff")
dev:Invoke("place",Vector3.new(0,3,4),Vector3.new(0,3,-1.5))
task.spawn(function()
 task.wait(DELAY)
 local function press(action,times,gap,move)
  for _=1,times do
   if move then dev:Invoke("move","human",move,.3) end
   dev:Invoke("act","human",action)
   task.wait(gap)
  end
 end
 if SCEN=="string" then
  press("Attack",9,.14)
 elseif SCEN=="launch" then
  press("Attack",4,.14)
  press("Attack",3,.14,Vector3.new(0,0,-1)) -- toward: launcher route
  dev:Invoke("move","human",Vector3.zero)
  press("Pursuit",2,.12)
  press("Attack",6,.14)
  press("Heavy",2,.14)
 elseif SCEN=="heavy" then
  press("Heavy",1,1)
 elseif SCEN=="guarded" then
  dev:Invoke("act","bot","Guard")
  press("Attack",6,.16)
  dev:Invoke("act","bot","GuardOff")
 end
 dev:Invoke("move","human",Vector3.zero)
end)
return "scenario "..SCEN.." in "..DELAY.." s"
