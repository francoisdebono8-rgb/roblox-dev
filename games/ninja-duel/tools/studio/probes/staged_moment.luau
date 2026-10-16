-- Server: staged duel moments for visual checks. MODE="setup" starts the duel
-- (A vs B, bot frozen, tool-driven); otherwise WHO performs MODE at GAP studs.
local MODE="setup"
local A,B="Sand","Flashstep"
local WHO="human"
local GAP=7
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local function place() dev:Invoke("move","human",Vector3.zero);dev:Invoke("place",Vector3.new(0,3,GAP/2),Vector3.new(0,3,-GAP/2)) end
if MODE=="setup" then
	dev:Invoke("start",A,B)
	local t0=os.clock()
	repeat task.wait(.2) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
	dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
	dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
	place();task.wait(.6)
	return "ready "..A.." vs "..B
end
dev:Invoke("refill");dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
place();task.wait(.5)
local s=dev:Invoke("state")
local other=if WHO=="human" then s.bot else s.human
local r=dev:Invoke("act",WHO,MODE,other and other.position)
task.wait(.05)
local after=dev:Invoke("state")
local me=if WHO=="human" then after.human else after.bot
return string.format("%s %s: ok=%s reason=%s state=%s attack=%s cast=%s",WHO,MODE,tostring(r and r.ok),tostring(r and r.reason),tostring(me.state),tostring(me.attackName),tostring(me.castId))
