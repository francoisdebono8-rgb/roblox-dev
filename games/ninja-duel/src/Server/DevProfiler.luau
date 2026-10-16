-- Studio profiler (Codex 33028b2, ported): instance-level instrumentation,
-- installed only while measurements are ON and removed at OFF and when a
-- duel is destroyed. Never changes positions, states, packet content, tick
-- rate or network ownership. Local duels and online duels are both observed.
-- Debug/QA places only (build.py DEBUG_SOURCES).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Metrics=require(Shared.DevMetrics)
local Profiler={};Profiler.__index=Profiler
local TRANSIENT={Startup=true,Active=true,Recovery=true,TechniqueChannel=true,TechniqueActive=true,TechniqueRecovery=true,Pursuit=true,Rush=true,Dodging=true,Stunned=true}
local function weak() return setmetatable({},{__mode="k"}) end
function Profiler.new(matches)
	return setmetatable({matches=matches,metrics=Metrics.new(),attached=weak(),tracks=weak(),lastWatch=0,lastSend={},lastEvents=weak(),lastCommand=nil},Profiler)
end
-- Every live Combat: local sessions and online duels.
function Profiler:combats()
	local list={}
	for _,s in self.matches.sessions do if s.combat then table.insert(list,s.combat) end end
	local online=self.matches.online
	if online and online.duels then for d in online.duels do if d.combat then table.insert(list,d.combat) end end end
	return list
end
function Profiler:attach(c)
	if self.attached[c] then return end
	self.attached[c]=true
	local m=self.metrics
	for _,key in {"updateActor","updateProjectiles","updateHazards","runScheduled","separate"} do
		m:wrap(c,key,"server."..key)
	end
	m:wrap(c,"update","server.combat",function(_,dt)
		m:sample("server.dt.ms",dt*1000)
		m:sample("server.projectiles",#c.projectiles);m:sample("server.impacts.retained",#c.impacts)
		m:sample("server.scheduled",c.scheduled and #c.scheduled or 0)
	end)
	m:wrap(c,"pushImpact","server.pushImpact")
	m:wrap(c,"relocate","server.relocate",function(_,a)
		m:event("intentional-relocation",{actor=a.id,state=a.state,attack=a.attackName,command=self.lastCommand})
	end)
	local separate=c.separate
	-- Observe the actual separation correction around the existing implementation.
	c.separate=function(selfCombat,...)
		local a,b=selfCombat.actors[1],selfCombat.actors[2]
		local pa,pb=a and a.root.Position,b and b.root.Position
		local result=table.pack(separate(selfCombat,...))
		if m.enabled and a and b then
			local correction=(a.root.Position-pa).Magnitude+(b.root.Position-pb).Magnitude
			m:sample("server.separation.studs",correction)
			if correction>.001 then m:count("server.separation.corrections") end
		end
		return table.unpack(result,1,result.n)
	end
	local observer=c.separate
	m:addRestore(c,function() if c.separate==observer then c.separate=separate end end)
end
function Profiler:release(c)
	if c and self.attached[c] then self.metrics:restoreObject(c);self.attached[c]=nil end
end
function Profiler:start()
	self.metrics:stop();self.metrics:start()
	self.attached=weak();self.tracks=weak();self.lastSend={};self.lastEvents=weak()
	local m=self.metrics
	m:wrap(self.matches,"destroy","server.destroy",nil,function(_,s) self:release(s.combat) end)
	if self.matches.online then
		m:wrap(self.matches.online,"teardown","server.online.teardown",nil,function(_,d) self:release(d.combat) end)
	end
	m:wrap(self.matches,"update","server.matches",function(_,dt)
		m:sample("server.heartbeat.ms",dt*1000)
		if dt>.05 then m:event("heartbeat-spike",{ms=dt*1000}) end
	end)
	m:wrap(self.matches,"request","server.request",function(_,player,payload)
		if type(payload)=="table" and type(payload.action)=="string" and #payload.action<=24 then
			m:count("input."..payload.action)
			if payload.action~="Move" then
				local s=self.matches.sessions[player];local a=s and s.human
				local epoch=payload.epoch
				m:event("input-intent",{userId=player.UserId,action=payload.action,
					epoch=if type(epoch)=="number" and epoch==epoch and math.abs(epoch)<1e6 then epoch else nil,state=a and a.state,
					direction=if typeof(payload.direction)=="Vector3" then tostring(payload.direction) else nil,attack=a and a.attackName})
			end
		end
	end)
	m:wrap(self.matches,"send","server.snapshot",function(_,player,payload)
		local now=os.clock();local last=self.lastSend[player];self.lastSend[player]=now
		if last then m:sample("server.snapshot.gap.ms",(now-last)*1000) end
		m:sample("server.snapshot.estimatedBytes",Metrics.estimate(payload))
	end)
	for _,c in self:combats() do self:attach(c) end
end
-- Called every Heartbeat by DevHooks; samples at most every 0.1 s.
function Profiler:watch()
	local m=self.metrics;if not m.enabled then return end
	local now=os.clock();if now-self.lastWatch<.1 then return end;self.lastWatch=now
	for _,c in self:combats() do
		self:attach(c)
		for _,a in c.actors do
			local previous=self.tracks[a]
			local position=a.root.Position
			if previous then
				local elapsed=now-previous.at;local delta=(position-previous.position).Magnitude
				m:sample("server.root.sampleDelta.studs",delta)
				if delta>math.max(8,elapsed*160) then m:event("server-position-jump",{actor=a.id,state=a.state,attack=a.attackName,studs=delta,warp=a.warpSerial or 0,previousWarp=previous.warp,command=self.lastCommand}) end
				if previous.state~=a.state or previous.reaction~=a.reaction then m:event("state",{actor=a.id,from=previous.state,state=a.state,reaction=a.reaction,attack=a.attackName}) end
			end
			self.tracks[a]={at=now,position=position,state=a.state,reaction=a.reaction,warp=a.warpSerial or 0}
			if TRANSIENT[a.state] and c.now-(a.untilTime or c.now)>.6 then m:count("watchdog.overdueState");m:event("overdue-state",{actor=a.id,state=a.state,overdue=c.now-a.untilTime}) end
			if (a.airHold or 0)-c.now>3 then m:count("watchdog.longAirHold") end
			local events=a.events or {};local old=self.lastEvents[a] or {}
			for name,n in events do if n>(old[name] or 0) then m:count("event."..name,n-(old[name] or 0)) end end
			self.lastEvents[a]=table.clone(events)
		end
	end
end
function Profiler:command(op)
	self.lastCommand=op;self.metrics:event("qa-command",{op=op})
end
function Profiler:stop() self.metrics:stop() end
function Profiler:report()
	local report=self.metrics:report();report.build=Shared.BuildFingerprint.Value
	report.units="*.ms = milliseconds; *.studs = studs; estimatedBytes = estimate, not wire bytes"
	return report
end
return Profiler
