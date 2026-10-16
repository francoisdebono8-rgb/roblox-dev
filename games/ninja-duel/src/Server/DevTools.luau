-- Studio dev-tool dispatcher (Codex 33028b2, ported): shared by the F6 panel
-- (NinjaDuelDevControl remote) and the command bar (NinjaDuelDev "tool" op).
-- Every op acts on the calling player's own local session, through the
-- allowlist in DevCommands; online sessions are refused, never rebuilt.
-- Debug/QA places only (build.py DEBUG_SOURCES).
local Commands=require(script.Parent.DevCommands)
local Scenarios=require(script.Parent.DevScenarios)
local Profiler=require(script.Parent.DevProfiler)
local Tools={};Tools.__index=Tools
-- The chakra lab (ChakraDev/ChakraLab) runs on the chakra runtime modules,
-- which arrive with the chakra-interactions work, not with these tools.
Tools.ChakraRuntime={"ChakraConfig","ChakraRules","ChakraInteractions","ChakraVectors"}
-- First module of `names` absent from `parent` (nil when all are present).
function Tools.missing(parent,names)
	for _,name in names do
		if not parent:FindFirstChild(name) then return name end
	end
	return nil
end
function Tools.new(matches)
	return setmetatable({matches=matches,profiler=Profiler.new(matches),last={},reports={},dummy={}},Tools)
end
function Tools:run(player,op,arg)
	local valid,clean=Commands.validate(op,arg)
	if not valid then return {ok=false,error="Invalid command"} end
	local matches=self.matches;local s=matches.sessions[player];arg=clean
	self.profiler:command(op)
	if op=="list" then
		return {ok=true,scenarios=table.clone(Scenarios.names),fighters=table.clone(Scenarios.core),last=self.last[player],
			profiling=self.profiler.metrics.enabled,dummy=s~=nil and s.botFrozen==true}
	elseif op=="profile" then
		if arg.enabled then self.profiler:start() else self.profiler:stop() end
		return {ok=true,enabled=self.profiler.metrics.enabled}
	elseif op=="report" then
		return {ok=true,server=self.profiler:report(),client=self.reports[player]}
	elseif op=="panel" or op=="selftest" then
		-- Carried out by DevHooks (client toggle / DevQA task).
		return {ok=true}
	end
	if s and s.online then return {ok=false,error="Online session: leave it first (back to Selection)"} end
	if op=="reset" or op=="character" then
		local ok,value=Scenarios.reset(matches,player,arg.first,arg.second,self.dummy[player]~=false)
		return {ok=ok,epoch=if ok then value.epoch else nil,error=if ok then nil else value}
	elseif op=="scenario" or op=="repeat" then
		local name=if op=="repeat" then self.last[player] or "neutral" else arg.name
		local ok,value=Scenarios.setup(matches,player,name,arg.first,arg.second)
		if ok then self.last[player]=name;self.dummy[player]=true end
		return {ok=ok,scenario=if ok then value else nil,error=if ok then nil else value}
	end
	if not s or not s.combat or s.phase~="Duel" then return {ok=false,error="No active duel"} end
	local c=s.combat;local a=if arg.actor=="bot" then s.bot else s.human
	if op=="dummy" then
		self.dummy[player]=arg.enabled==true;s.botFrozen=self.dummy[player]
		if s.botFrozen then s.bot.move=Vector3.zero end
	elseif op=="refill" then
		Scenarios.refill(s)
	elseif op=="awaken" then
		-- QA override of once-per-match: health under the threshold, then the real Awaken request.
		Scenarios.refill(s,a);a.awakened=false;a.health=a.def.Health*.3;a.hum.Health=a.health
		local ok,reason=c:request(a,"Awaken")
		matches:snapshot(player,s)
		return {ok=ok,error=if ok then nil else reason}
	elseif op=="ko" then
		a.invulnerableUntil=0;a.rotationUntil=0;a.readUntil=0;a.guardHeld=false;a.shieldCharges=0;a.comboHits=0
		c:damage(a.target,a,a.health+200,false,false)
	else
		return {ok=false,error="Unknown command"}
	end
	matches:snapshot(player,s)
	return {ok=true,epoch=s.epoch,dummy=s.botFrozen==true}
end
function Tools:remove(player)
	self.last[player]=nil;self.reports[player]=nil;self.dummy[player]=nil;self.profiler.lastSend[player]=nil
end
return Tools
