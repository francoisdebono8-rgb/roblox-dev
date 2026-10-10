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
			untilIn=a.untilTime-now,groundPose=a.groundPose,flash=(a.flashUntil or 0)>now}
	end
	hook.OnInvoke=function(op,arg1,arg2,arg3)
		local player,s=session()
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
		elseif op=="refill" then
			for _,a in {s.human,s.bot} do a.chakra=a.def.Chakra;a.cooldowns={};a.health=a.def.Health;a.hum.Health=a.health;a.subCharges=2;a.subCooldown=0 end
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
		elseif op=="clientinfo" then
			logRemote:FireAllClients("info");task.wait(.3);return clientInfo
		elseif op=="state" then
			local projectiles={}
			for _,p in c.projectiles do table.insert(projectiles,{kind=p.kind,position=p.position}) end
			return {phase=s.phase,now=c.now,human=summary(s.human,c.now),bot=summary(s.bot,c.now),projectiles=projectiles,hazards=#c.hazards,events=s.human.events}
		end
		return "unknown op"
	end
	RunService.Heartbeat:Connect(function()
		local _,s=session()
		if autopilot and s and s.phase=="Duel" and autopilot.actor==s.human then autopilot:update(s.combat.now)
		elseif autopilot and s and s.combat and autopilot.actor~=s.human then autopilot=AI.new(s.combat,s.human,99) end
	end)
end
return DevHooks
