local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local M={}
function M.setup(A,B,gap)
	dev:Invoke("autopilot",false)
	dev:Invoke("start",A,B)
	local t0=os.clock()
	repeat task.wait(.2) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
	dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true)
	M.reset(gap)
	return "ready "..A.." vs "..B
end
function M.reset(gap)
	dev:Invoke("refill");dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
	dev:Invoke("move","human",Vector3.zero)
	dev:Invoke("place",Vector3.new(0,3,(gap or 8)/2),Vector3.new(0,3,-(gap or 8)/2))
	task.wait(.5)
end
function M.act(who,action,aim)
	local s=dev:Invoke("state")
	local other=if who=="human" then s.bot else s.human
	return dev:Invoke("act",who,action,aim or (other and other.position))
end
M.dev=dev
return M
