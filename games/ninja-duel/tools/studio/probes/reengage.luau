-- Server: native re-engage check. For each fighter: chakra dash from 22 studs
-- (bot frozen), then Light1 + launcher + E (chase). Logs state changes, the
-- arrival distance and the time to arrive.
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local out={}
local function poll(seconds,label)
	local t0=os.clock();local last;local log={}
	local arrived
	while os.clock()-t0<seconds do
		local s=dev:Invoke("state")
		local d=(s.human.position and s.bot.position) and (s.human.position-s.bot.position).Magnitude or -1
		local key=s.human.state..(s.human.attackName and ("/"..s.human.attackName) or "")
		if key~=last then table.insert(log,string.format("%.2f %s d=%.1f",os.clock()-t0,key,d));last=key end
		if not arrived and s.human.state~="Rush" and s.human.state~="Pursuit" and os.clock()-t0>.05 then arrived=os.clock()-t0 end
		task.wait()
	end
	table.insert(out,label..": "..table.concat(log," | "))
end
for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
	dev:Invoke("start",id,"Mirage")
	local t0=os.clock()
	repeat task.wait(.2) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
	dev:Invoke("autopilot",false);dev:Invoke("freezeBot",true);dev:Invoke("scripted",true);dev:Invoke("refill")
	dev:Invoke("health","human",400);dev:Invoke("health","bot",400)
	dev:Invoke("move","human",Vector3.zero)
	dev:Invoke("place",Vector3.new(0,3,11),Vector3.new(0,3,-11));task.wait(.6)
	local r=dev:Invoke("act","human","Pursuit")
	poll(.8,id.." dash ("..tostring(r and r.ok)..")")
	dev:Invoke("refill")
	dev:Invoke("place",Vector3.new(0,3,2.5),Vector3.new(0,3,-2.5));task.wait(.5)
	dev:Invoke("act","human","Attack");task.wait(.3)
	dev:Invoke("act","human","Attack");task.wait(.3)
	dev:Invoke("move","human",Vector3.new(0,0,-1),.3);task.wait(.05)
	dev:Invoke("act","human","Attack");dev:Invoke("move","human",Vector3.zero)
	task.wait(.35)
	local c=dev:Invoke("act","human","Pursuit")
	poll(.9,id.." launch+chase ("..tostring(c and c.ok)..","..tostring(c and c.reason)..")")
end
return table.concat(out,"\n")
