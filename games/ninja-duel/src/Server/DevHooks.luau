-- Studio-only playtest hooks. A BindableFunction in ServerStorage lets a Studio
-- tool (or the command bar) start duels, drive either fighter through the real
-- combat requests, let the AI play both sides, and read a compact state dump.
-- Never active outside Studio; it only calls the same server APIs players use.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local DevHooks={}
-- Studio latency simulation for the client-to-server half (Studio's Incoming
-- Replication Lag covers server-to-client). Each player's requests reach the
-- server `latency` ms (± `jitter` ms) late and in order, like a slow reliable
-- remote. Wraps this matches instance only; returns the per-frame flush.
-- Debug/QA places only: this module never ships in the normal build.
function DevHooks.delayRequests(matches,settings,clock,random)
	local inbound=matches.request
	local queues={}
	matches.request=function(self,player,payload)
		local latency,jitter=settings()
		if latency<=0 and jitter<=0 and not queues[player] then return inbound(self,player,payload) end
		local queue=queues[player] or {}
		queues[player]=queue
		local due=clock()+math.max(0,latency+(random()*2-1)*jitter)/1000
		-- Reliable remotes never reorder: a request is never due before the previous one.
		if queue[#queue] and queue[#queue].due>due then due=queue[#queue].due end
		table.insert(queue,{due=due,payload=payload})
	end
	return function()
		local now=clock()
		for player,queue in queues do
			while queue[1] and queue[1].due<=now and player.Parent~=nil do inbound(matches,player,table.remove(queue,1).payload) end
			if #queue==0 or player.Parent==nil then queues[player]=nil end
		end
	end
end
function DevHooks.install(matches)
	if not RunService:IsStudio() or workspace:GetAttribute("NinjaDuelDebug")~=true then return end
	-- Set from the server command bar or the Workspace properties while testing:
	-- workspace:SetAttribute("NinjaDuelSimLatency",60) and ("NinjaDuelSimJitter",15).
	local flushRequests=DevHooks.delayRequests(matches,function()
		return tonumber(workspace:GetAttribute("NinjaDuelSimLatency")) or 0,tonumber(workspace:GetAttribute("NinjaDuelSimJitter")) or 0
	end,os.clock,math.random)
	local Inspector=require(script.Parent.CombatInspector)
	local debugRemote=Instance.new("RemoteEvent");debugRemote.Name="NinjaDuelCombatDebug";debugRemote.Parent=game:GetService("ReplicatedStorage")
	local traces=setmetatable({},{__mode="k"})
	local nextDebug=0
	local AI=require(script.Parent.AI)
	local hook=Instance.new("BindableFunction");hook.Name="NinjaDuelDev";hook.Parent=game:GetService("ServerStorage")
	local autopilot=nil
	-- Client diagnostics (Studio only): the local client forwards its warnings,
	-- errors and camera framing so a playtest can be inspected from tooling.
	local logRemote=Instance.new("RemoteEvent");logRemote.Name="NinjaDuelDevLog";logRemote.Parent=game:GetService("ReplicatedStorage")
	local clientLog={}
	local clientInfo={}
	logRemote.OnServerEvent:Connect(function(_,kind,payload)
		if kind=="log" and type(payload)=="string" then
			table.insert(clientLog,payload);while #clientLog>60 do table.remove(clientLog,1) end
		elseif kind=="info" and type(payload)=="table" then clientInfo=payload end
	end)
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
			chainOpen=a.chainOpen and now>=(a.chainAt or 0) and a.state=="Recovery",combo=a.combo,hitZone=a.hitZone,hitKind=a.hitKind,
			build=a.build and {spent=a.build.spent,bracket=a.build.bracket,nodes=table.clone(a.build.nodes)}}
	end
	hook.OnInvoke=function(op,arg1,arg2,arg3)
		local player,s=session()
		if op=="contracts" then
			return table.clone(Inspector.ToolHooks)
		elseif op=="start" then
			if not player then return "no player" end
			if s and s.phase~="Selection" then matches:selection(player) end
			return matches:start(player,arg1 or "Flashstep",arg2 or "Mirage",arg3==true)
		elseif op=="startBuild" then
			-- Skill builds (PROG-001..003), validated exactly like a real start.
			-- arg1 = {player=id, bot=id, training=bool, bracket=id,
			--   playerNodes={...} or playerRanked=bracket id (example build),
			--   botPreset=AI tier or botNodes={...}}
			if not player then return "no player" end
			local BuildPresets=require(script.Parent.BuildPresets)
			local spec=if type(arg1)=="table" then arg1 else {}
			local playerId,botId=spec.player or "Flashstep",spec.bot or "Mirage"
			local playerNodes=spec.playerNodes or (spec.playerRanked and BuildPresets.ranked(playerId,spec.playerRanked))
			local options={bracket=spec.bracket,player=if playerNodes then {nodes=playerNodes} else nil,
				bot=if spec.botPreset then {preset=spec.botPreset} elseif spec.botNodes then {nodes=spec.botNodes} else nil}
			if s and s.phase~="Selection" then matches:selection(player) end
			local ok,reason=matches:start(player,playerId,botId,spec.training==true,options)
			return {ok=ok,reason=reason}
		elseif op=="skills" then
			-- Trees, brackets and presets, for tooling and Studio checks.
			local SkillBuilds=require(script.Parent.SkillBuilds)
			local BuildPresets=require(script.Parent.BuildPresets)
			local out={brackets=SkillBuilds.Brackets,aiTiers=BuildPresets.AITiers,fighters={}}
			for id,tree in SkillBuilds.Trees do
				local nodes={}
				for _,node in tree.Nodes do
					table.insert(nodes,{id=node.Id,kind=node.Kind,cost=node.Cost,major=node.Major==true,branch=node.Branch,
						requires=node.Requires,requiresAny=node.RequiresAny,exclusive=node.Exclusive,wired=SkillBuilds.wired(id,node.Id),shows=node.Shows})
				end
				out.fighters[id]={nodes=nodes,designMax=SkillBuilds.maxCost(id,false),playableMax=SkillBuilds.maxCost(id,true),unwired=SkillBuilds.unwired(id)}
			end
			return out
		elseif op=="selection" then
			if player then matches:selection(player) end;return true
		elseif op=="lag" then
			-- arg1 = one-way request delay (ms), arg2 = jitter (± ms); 0, 0 turns it off.
			workspace:SetAttribute("NinjaDuelSimLatency",tonumber(arg1) or 0);workspace:SetAttribute("NinjaDuelSimJitter",tonumber(arg2) or 0)
			return {latency=workspace:GetAttribute("NinjaDuelSimLatency"),jitter=workspace:GetAttribute("NinjaDuelSimJitter")}
		elseif op=="online" then
			return matches.online and matches.online:summary()
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
		elseif op=="inspect" then
			return Inspector.snapshot(s)
		elseif op=="trace" then
			local trace=traces[s];local entries={}
			if trace then for _,entry in trace.entries do table.insert(entries,table.clone(entry)) end end
			return entries
		elseif op=="state" then
			local projectiles={}
			for _,p in c.projectiles do table.insert(projectiles,{kind=p.kind,position=p.position}) end
			return {phase=s.phase,now=c.now,human=summary(s.human,c.now),bot=summary(s.bot,c.now),projectiles=projectiles,hazards=#c.hazards,events=s.human.events,botEvents=s.bot.events}
		end
		return "unknown op"
	end
	RunService.Heartbeat:Connect(function()
		flushRequests()
		if workspace:GetAttribute("NinjaDuelDebugEnabled")~=false then
			for viewer,session in matches.sessions do
				if session.combat then
					local snapshot=Inspector.snapshot(session);local trace=traces[session] or {};traces[session]=trace
					Inspector.record(trace,snapshot,80)
					if os.clock()>=nextDebug then debugRemote:FireClient(viewer,snapshot) end
				end
			end
			if os.clock()>=nextDebug then nextDebug=os.clock()+.1 end
		end
		local _,s=session()
		if autopilot and s and s.phase=="Duel" and autopilot.actor==s.human then autopilot:update(s.combat.now)
		elseif autopilot and s and s.combat and autopilot.actor~=s.human then autopilot=AI.new(s.combat,s.human,99) end
	end)
end
return DevHooks
