-- Server: AI-vs-AI soak over several matchups (autopilot on the human side),
-- healing both sides so the fight never ends; reports events and errors seen.
local PAIRS={{"Sand","Lion"},{"Mirage","GentleFist"},{"Flashstep","Sand"},{"Lion","Flashstep"}}
local SECONDS=35
local dev=game:GetService("ServerStorage"):WaitForChild("NinjaDuelDev",10)
local LogService=game:GetService("LogService")
local errors={}
local conn=LogService.MessageOut:Connect(function(message,kind)
	if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then
		if #errors<12 then table.insert(errors,string.sub(message,1,220)) end
	end
end)
local out={}
for _,pair in PAIRS do
	dev:Invoke("start",pair[1],pair[2])
	local t0=os.clock()
	repeat task.wait(.25) local r=dev:Invoke("act","human","GuardOff") until (type(r)=="table" and r.reason~="Intro") or os.clock()-t0>12
	dev:Invoke("place",Vector3.new(0,3,8),Vector3.new(0,3,-8));dev:Invoke("refill")
	dev:Invoke("freezeBot",false);dev:Invoke("scripted",false);dev:Invoke("autopilot",true)
	local t1=os.clock()
	while os.clock()-t1<SECONDS do
		task.wait(1)
		dev:Invoke("health","human",300);dev:Invoke("health","bot",300)
	end
	local s=dev:Invoke("state")
	local function count(ev)
		local n=0
		for k,v in ev or {} do if k=="Hit" or k=="Technique" or k=="Rush" or k=="Chase" or k=="ChakraClash" then n+=v end end
		return n
	end
	local function pick(ev,keys) local p={} for _,k in keys do table.insert(p,k.."="..tostring((ev or {})[k] or 0)) end return table.concat(p," ") end
	local keys={"Hit","Technique","Rush","Chase","Guard","Dodge","SandShield","ChakraClash"}
	table.insert(out,string.format("%s vs %s (%s): %s || %s",pair[1],pair[2],s.phase,pick(s.events,keys),pick(s.botEvents,keys)))
	dev:Invoke("autopilot",false)
end
conn:Disconnect()
table.insert(out,"errors/warnings: "..#errors)
for _,e in errors do table.insert(out,"  "..e) end
return table.concat(out,"\n")
