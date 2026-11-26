-- (26/11, passe 2, DEV) The kits' trainings played by Server/TutorialBot,
-- headless: one line per kit, its steps, the time, and the steps where it got
-- stuck (status, the refusals). Not part of the suite (a simulation, like the
-- other .sim files): lune run tests/TutorialRobot.sim.luau [kit]
local H=require("./Harness")
local V=H.V
local clock=5000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
H.envBase.Random={new=function(seed)
	local state=(seed or 1)*2654435761%4294967296
	local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
	return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
		NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
H.load("Shared/Config").DamageScale=H.GameDamageScale
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Matches=H.load("Server/Matches")
local SoloPlay=H.load("Server/SoloPlay")
local Progression=H.load("Server/Progression")
local AI=H.load("Server/AI")

local BetaRoster=H.load("Shared/BetaRoster")
local FirstMinute=H.load("Shared/FirstMinute")
local Bot=H.load("Server/TutorialBot")
H.envBase.os={clock=function() return clock end,time=os.time,date=os.date}
local m
local function sim(sec) for _=1,math.max(1,math.ceil((sec or .03)/.02)) do clock+=.02; m:update(.02,clock); runTimers() end end
H.envBase.task.wait=function(sec) sim(sec) return sec end
local inbox={}
local remote={FireClient=function(_,player,data) end}
local only=...
for i,kit in BetaRoster do
	if only and only~=kit then continue end
	m=Matches.new(remote)
	local attrs={}
	local player={UserId=500+i,Name="T"..i,DisplayName="T"..i,Parent=H.Players,SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
	m:selection(player)
	assert(m:start(player,kit,FirstMinute.rival(kit) or "Lion",true),"no training for "..kit)
	local s=m.sessions[player]
	local t0=clock
	local ok,report=pcall(Bot.play,s,10)
	if not ok then print(kit.." BOT ERROR "..tostring(report)) continue end
	local stuck={}
	for _,step in report.steps do
		if step.status~="PASS" then table.insert(stuck,step.id..":"..tostring(step.status)..(if step.line then " ("..tostring(step.line)..")" else "")..(if step.refused and next(step.refused) then " refused "..(function() local r={} for k,v in step.refused do table.insert(r,tostring(k).."x"..tostring(v)) end return table.concat(r,",") end)() else "")) end
	end
	print(string.format("%-10s %2d steps  %5.0fs  %s",kit,#report.steps,clock-t0,if #stuck==0 then "ALL PASS" else "STUCK: "..table.concat(stuck," | ")))
end
