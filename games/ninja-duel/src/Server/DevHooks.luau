-- Studio-only playtest hooks. A BindableFunction in ServerStorage lets a Studio
-- tool (or the command bar) start duels, drive either fighter through the real
-- combat requests, let the AI play both sides, and read a compact state dump.
-- Never active outside Studio; it only calls the same server APIs players use.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local DevHooks={}
function DevHooks.install(matches)
	if not RunService:IsStudio() then return end
	local AI=require(script.Parent.AI)
 local Shared=game:GetService("ReplicatedStorage").NinjaDuel
 local Rules=require(Shared.Rules)
 local Metrics=require(Shared.DevMetrics)
 local tools=require(script.Parent.DevTools).new(matches)
 local buckets={};local logs={}
 local control=Instance.new("RemoteFunction");control.Name="DevControl";control.Parent=Shared
 local function allowed(player,kind,rate,burst)
  buckets[player]=buckets[player] or {}
  local bucket=buckets[player][kind] or {tokens=burst,time=os.clock()};buckets[player][kind]=bucket
  return Rules.consumeToken(bucket,os.clock(),rate,burst)
 end
	local hook=Instance.new("BindableFunction");hook.Name="NinjaDuelDev";hook.Parent=game:GetService("ServerStorage")
	local autopilot=nil
	-- Client diagnostics (Studio only): the local client forwards its warnings,
	-- errors and camera framing so a playtest can be inspected from tooling.
	local logRemote=Instance.new("RemoteEvent");logRemote.Name="NinjaDuelDevLog";logRemote.Parent=game:GetService("ReplicatedStorage")
	local clientLog={}
	local clientInfo={}
 logRemote.OnServerEvent:Connect(function(player,kind,payload)
  if not allowed(player,"telemetry",5,10) then return end
  if kind=="log" and type(payload)=="string" then
   logs[player]=logs[player] or {};local entries=logs[player]
   table.insert(entries,payload:sub(1,400));if #entries>60 then table.remove(entries,1) end
  elseif (kind=="info" or kind=="report") and type(payload)=="table" and Metrics.validPayload(payload) and Metrics.estimate(payload)<60000 then
   if kind=="report" then tools.reports[player]=payload else clientInfo=payload end
  end
 end)
 local function run(player,op,arg)
  if not player then return {ok=false,error="No player"} end
  local result=tools:run(player,op,arg)
  if op=="profile" and result.ok then logRemote:FireClient(player,"profile",result.enabled) end
  if op=="report" and result.ok then
   tools.reports[player]=nil;logRemote:FireClient(player,"report");task.wait(.3)
   result=tools:run(player,op,arg)
   require(script.Parent.DevReport).print(result)
  end
  return result
 end
 control.OnServerInvoke=function(player,op,arg)
  if not allowed(player,"control",2,4) then return {ok=false,error="Dev command rate limit"} end
  return run(player,op,arg)
 end
 Players.PlayerRemoving:Connect(function(player) tools:remove(player);buckets[player]=nil;logs[player]=nil end)
	local function session()
		local player=Players:GetPlayers()[1]
		return player,player and matches.sessions[player]
	end
	local function summary(a,now)
		if not a then return nil end
		return {state=a.state,health=a.health,chakra=math.floor(a.chakra),position=a.root.Position,reaction=a.reaction,attackName=a.attackName,
			airborne=a.airborne,wall=a.wall~=nil,airHold=a.airHold,pending=a.pending and (a.pending.name or (a.pending.spec and a.pending.spec.Id)),
			throwing=a.throwing and a.throwing.kind,anchor=a.anchor and a.anchor.position,velocity=a.root.AssemblyLinearVelocity,
			untilIn=a.untilTime-now,groundPose=a.groundPose,flash=(a.flashUntil or 0)>now,comboHits=a.comboHits,subCharges=a.subCharges,seals=#(a.anchors or {}),attackVariant=a.attackVariant,
			chainOpen=a.chainOpen and now>=(a.chainAt or 0) and a.state=="Recovery",combo=a.combo,hitZone=a.hitZone,hitKind=a.hitKind}
	end
	hook.OnInvoke=function(op,arg1,arg2,arg3)
		local player,s=session()
  if op=="tool" then return run(player,arg1,arg2) end
  clientLog=player and logs[player] or {}
		if op=="start" then
			if not player then return "no player" end
			if s and s.phase~="Selection" then matches:selection(player) end
			return matches:start(player,arg1 or "Flashstep",arg2 or "Mirage",arg3==true)
		elseif op=="selection" then
			if player then matches:selection(player) end;return true
		end
		if not s or not s.combat then return "no duel" end
		local c=s.combat
		local actor=if arg1=="bot" then s.bot else s.human
		if op=="act" then
			-- arg1 = "human"/"bot", arg2 = action, arg3 = optional aim
			local ok,reason=c:request(actor,arg2,arg3)
			return {ok=ok,reason=reason}
		elseif op=="scripted" then
			-- Ignore the local client's (idle) move packets while a tool drives the human.
			s.scripted=arg1==true;return true
		elseif op=="move" then
			actor.move=arg2 or Vector3.zero;actor.lastMove=os.clock()+(arg3 or 0)
			if arg1~="bot" then actor.sprinting=false end
			return true
		elseif op=="health" then
			actor.health=math.max(1,arg2 or actor.health);actor.hum.Health=actor.health;return actor.health
		elseif op=="sprint" then
			actor.sprinting=arg2==true;return true
		elseif op=="refill" then
			for _,a in {s.human,s.bot} do a.chakra=a.def.Chakra;a.cooldowns={};a.health=a.def.Health;a.hum.Health=a.health;a.subCharges=2;a.subCooldown=0;a.subRegenAt=math.huge end
			return true
		elseif op=="place" then
			-- arg1 / arg2 = offsets from the arena origin for human / bot
			c:relocate(s.human,s.origin+(arg1 or Vector3.new(0,3,6)));c:relocate(s.bot,s.origin+(arg2 or Vector3.new(0,3,-6)))
			s.human.root.CFrame=CFrame.lookAt(s.human.root.Position,s.bot.root.Position*Vector3.new(1,0,1)+Vector3.new(0,s.human.root.Position.Y,0))
			s.bot.root.CFrame=CFrame.lookAt(s.bot.root.Position,s.human.root.Position*Vector3.new(1,0,1)+Vector3.new(0,s.bot.root.Position.Y,0))
			return true
		elseif op=="freezeBot" then
			s.botFrozen=arg1==true
			if s.botFrozen then s.bot.move=Vector3.zero end
			return true
		elseif op=="autopilot" then
			-- The AI drives the human fighter too: full AI-vs-AI fights to watch.
			if arg1 then autopilot=AI.new(c,s.human,99) else autopilot=nil end
			s.autopilot=arg1==true
			return true
		elseif op=="clientlog" then
			local out=table.concat(clientLog," || ");if arg1 then table.clear(clientLog) end;return out
		elseif op=="probe" then
			-- Smoothness probe from the client (Studio only); resets on read.
			logRemote:FireAllClients("probe");task.wait(.3);return clientInfo.probe
		elseif op=="clientinfo" then
			logRemote:FireAllClients("info");task.wait(.3);return clientInfo
		elseif op=="ko" then
			-- arg1 = "human"/"bot": that fighter is knocked out by the other.
			local victim=if arg1=="human" then s.human else s.bot
			local by=if arg1=="human" then s.bot else s.human
			victim.invulnerableUntil=0;victim.rotationUntil=0;victim.readUntil=0;victim.guardHeld=false;victim.comboHits=0
			c:damage(by,victim,victim.health+50,false,false)
			return if s.finishing then "KO" else s.phase
		elseif op=="rematch" then
			s.lastLifecycle=-10
			matches:request(player,{action="Rematch",epoch=s.epoch})
			return s.phase
		elseif op=="damagelog" then
			-- arg1=true clears it; the log starts when first requested.
			c.damageLog=c.damageLog or {}
			local out=c.damageLog
			if arg1 then c.damageLog={} end
			return out
		elseif op=="state" then
			local projectiles={}
			for _,p in c.projectiles do table.insert(projectiles,{kind=p.kind,position=p.position}) end
			return {phase=s.phase,now=c.now,human=summary(s.human,c.now),bot=summary(s.bot,c.now),projectiles=projectiles,hazards=#c.hazards,events=s.human.events,botEvents=s.bot.events}
		end
		return "unknown op"
	end
	RunService.Heartbeat:Connect(function()
  tools.profiler:watch()
		local _,s=session()
		if autopilot and s and s.phase=="Duel" and autopilot.actor==s.human then autopilot:update(s.combat.now)
		elseif autopilot and s and s.combat and autopilot.actor~=s.human then autopilot=AI.new(s.combat,s.human,99) end
	end)
end
return DevHooks
