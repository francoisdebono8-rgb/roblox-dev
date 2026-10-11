-- Studio-only command dispatcher. Shared by the overlay and the command bar.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Commands=require(Shared.DevCommands)
local Scenarios=require(script.Parent.DevScenarios)
local Profiler=require(script.Parent.DevProfiler)
local Tools={};Tools.__index=Tools
function Tools.new(matches)
 return setmetatable({matches=matches,profiler=Profiler.new(matches),last={},reports={},dummy={}},Tools)
end
function Tools:run(player,op,arg)
 local valid,clean=Commands.validate(op,arg)
 if not valid then return {ok=false,error="Invalid command"} end
 local matches=self.matches;local s=matches.sessions[player];arg=clean
 self.profiler:command(op)
 if op=="reset" or op=="character" then
  local first=arg.first or (s and s.playerId);local second=arg.second or (s and s.botId)
  local ok,value=Scenarios.reset(matches,player,first,second,self.dummy[player]~=false)
  return {ok=ok,epoch=ok and value.epoch or nil,error=not ok and value or nil}
 elseif op=="scenario" or op=="repeat" then
  local name=if op=="repeat" then self.last[player] or "neutral" else arg.name
  local ok,value=Scenarios.setup(matches,player,name,arg.first,arg.second)
  if ok then self.last[player]=name;self.dummy[player]=true end
  return {ok=ok,scenario=ok and value or nil,error=not ok and value or nil}
 elseif op=="profile" then
  if arg.enabled then self.profiler:start() else self.profiler:stop() end
  return {ok=true,enabled=self.profiler.metrics.enabled}
 elseif op=="report" then
  return {ok=true,server=self.profiler:report(),client=self.reports[player]}
 end
 if not s or not s.combat or s.phase~="Duel" then return {ok=false,error="No active duel"} end
 local c=s.combat;local a=if arg.actor=="bot" then s.bot else s.human
 if op=="dummy" then self.dummy[player]=arg.enabled==true;s.botFrozen=self.dummy[player];if s.botFrozen then s.bot.move=Vector3.zero end
 elseif op=="refill" then Scenarios.refill(s)
 elseif op=="awaken" then
  Scenarios.refill(s,a);a.awakened=false;a.health=a.def.Health*.3;a.hum.Health=a.health
  local ok,reason=c:request(a,"Awaken");return {ok=ok,error=not ok and reason or nil}
 elseif op=="ko" then
  a.invulnerableUntil=0;a.rotationUntil=0;a.readUntil=0;a.guardHeld=false;a.shieldCharges=0;a.comboHits=0
  c:damage(a.target,a,a.health+200,false,false)
 else return {ok=false,error="Unknown command"} end
 matches:snapshot(player,s)
 return {ok=true,epoch=s.epoch,dummy=s.botFrozen}
end
function Tools:remove(player) self.last[player]=nil;self.reports[player]=nil;self.dummy[player]=nil;self.profiler.lastSend[player]=nil end
return Tools
