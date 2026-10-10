local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local Rules=require(Shared.Rules)
local World=require(script.Parent.World)
local Combat=require(script.Parent.Combat)
local AI=require(script.Parent.AI)
local Tutorial=require(script.Parent.Tutorial)
local Matches={}; Matches.__index=Matches
function Matches.new(remote)
	local folder=Instance.new("Folder"); folder.Name="NinjaDuels"; folder.Parent=workspace
	return setmetatable({remote=remote,folder=folder,sessions={},nextLane=0,epoch=0},Matches)
end
function Matches:send(player,data)
	if player.Parent==Players then self.remote:FireClient(player,data) end
end
function Matches:session(player)
	if self.sessions[player] then return self.sessions[player] end
	self.nextLane+=1
	local s={phase="Selection",lane=self.nextLane,bucket={tokens=Config.RequestBurst,time=os.clock()},lastLifecycle=-10,epoch=0}
	self.sessions[player]=s; return s
end
function Matches:destroy(s)
	if s.combat then s.combat:clear() end
	if s.folder then s.folder:Destroy() end
	s.tutorial=nil; s.folder=nil; s.combat=nil; s.ai=nil; s.human=nil; s.bot=nil
end
function Matches:selection(player)
	local s=self:session(player); self:destroy(s)
	player.Character=nil; s.phase="Selection"; s.epoch+=1
	self:send(player,{phase="Selection",epoch=s.epoch})
end
function Matches:start(player,playerId,botId,training)
	local s=self:session(player)
	if not Fighters[playerId] or not Fighters[botId] then return false end
	self:destroy(s); s.epoch+=1
	s.playerId=playerId; s.botId=botId; s.winner=nil; s.phase="Duel"; s.origin=Vector3.new((s.lane-1)*240,0,0)
	s.folder=Instance.new("Folder"); s.folder.Name="Duel_"..s.lane; s.folder.Parent=self.folder
	s.effects=Instance.new("Folder"); s.effects.Name="Effects"; s.effects.Parent=s.folder
	World.arena(s.folder,s.origin)
	s.combat=Combat.new(s); s.combat.now=workspace:GetServerTimeNow()
	local function actor(id,def,position,look)
		local model,hum,root,joints=World.rig(s.folder,Fighters[def],CFrame.lookAt(position,look),id)
		return s.combat:add(id,model,hum,root,joints,def)
	end
	s.human=actor("PlayerFighter",playerId,s.origin+Vector3.new(0,3,14),s.origin+Vector3.new(0,3,-14))
	s.bot=actor("AIFighter",botId,s.origin+Vector3.new(0,3,-14),s.origin+Vector3.new(0,3,14))
	s.human.target=s.bot; s.bot.target=s.human; s.human.locked=true
	player.Character=s.human.model
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+ s.epoch)
	s.finish=function(winner,_loser)
		if s.phase~="Duel" then return end
		s.phase="Result"; s.winner=winner.id; s.combat:clear(true)
		for _,a in s.combat.actors do World.pose(a,s.combat.now,0.1) end
		for _,a in s.combat.actors do a.hum.WalkSpeed=0; a.root.Anchored=true end
		self:snapshot(player,s)
	end
	s.tutorial=nil; if training then Tutorial.new(s) end
	local epoch=s.epoch
	s.human.hum.Died:Connect(function() if s.epoch==epoch and s.phase=="Duel" then s.human.health=0; s.human.state="Defeated"; s.finish(s.bot,s.human) end end)
	s.bot.hum.Died:Connect(function() if s.epoch==epoch and s.phase=="Duel" then s.bot.health=0; s.bot.state="Defeated"; s.finish(s.human,s.bot) end end)
	self:snapshot(player,s)
	return true
end
function Matches:snapshot(player,s)
	local function data(a)
		local ready={}
		for i,spec in a.def.Techniques do
			ready[i]={id=spec.Id,name=spec.Name,cost=spec.Cost,remaining=math.max(0,(a.cooldowns[spec.Id] or 0)-s.combat.now),condition=not spec.Requires or (spec.Requires=="Anchor" and a.anchor~=nil) or (spec.Requires=="Target" and s.combat:targetValid(a,a.target,spec.Range,0.35))}
		end
		return {id=a.id,fighterId=a.fighterId,fighter=a.def.Name,health=a.health,maxHealth=a.def.Health,chakra=a.chakra,maxChakra=a.def.Chakra or Config.Chakra,state=a.state,
			techniques=ready,position=a.root.Position,channel=if a.state=="TechniqueChannel" then math.max(0,a.untilTime-s.combat.now) else 0,
			anchor=a.anchor and a.anchor.position,illusion=math.max(0,a.illusionUntil-s.combat.now),decoy=a.decoyPosition,
			cue=if a.cueUntil>s.combat.now then a.cue else "",dodge=math.max(0,a.dodgeUntil-s.combat.now),read=math.max(0,a.readUntil-s.combat.now),
			speed=a.locomotion.Magnitude,airborne=a.airborne,pursuit=math.max(0,a.pursuitUntil-s.combat.now),combo=a.combo,
			subCharges=a.subCharges,wall=a.wall~=nil,reaction=a.reaction,attackName=a.attackName,attackElapsed=s.combat.now-(a.attackStarted or 0),airHold=a.airHold,impactSerial=a.impactSerial or 0,impactHeavy=a.impactHeavy,events=a.events,velocity=a.root.AssemblyLinearVelocity}
	end
	self:send(player,{phase=s.phase,epoch=s.epoch,winner=s.winner,tutorial=Tutorial.snapshot(s),origin=s.origin,human=data(s.human),bot=data(s.bot)})
end
function Matches:request(player,payload)
	local s=self:session(player); local clock=os.clock()
	if not Rules.consumeToken(s.bucket,clock,Config.RequestRate,Config.RequestBurst) then return end
	if type(payload)~="table" or type(payload.action)~="string" or #payload.action>24 then return end
	local action=payload.action
	if action=="Ready" then
		if s.phase=="Selection" then self:send(player,{phase="Selection",epoch=s.epoch}) else self:snapshot(player,s) end
		return
	end
	if payload.epoch~=s.epoch then return end
	if action=="TutorialSkip" and s.tutorial then self:selection(player);s.tutorial=nil;return end
	if action=="Start" or action=="Tutorial" or action=="Rematch" or action=="Selection" then
		if clock-s.lastLifecycle<0.8 then return end
		if (action=="Start" or action=="Tutorial") and s.phase=="Selection" then
			if type(payload.player)~="string" or type(payload.bot)~="string" then return end
			s.lastLifecycle=clock; self:start(player,payload.player,payload.bot,action=="Tutorial")
		elseif action=="Rematch" and s.phase=="Result" then
			s.lastLifecycle=clock; self:start(player,s.playerId,s.botId,s.tutorial~=nil)
		elseif action=="Selection" and (s.phase=="Result" or s.tutorial) then s.lastLifecycle=clock; self:selection(player) end
		return
	end
	if s.phase~="Duel" or not s.human then return end
	local function vector(v)
		return typeof(v)=="Vector3" and Rules.finite(v.X) and Rules.finite(v.Y) and Rules.finite(v.Z)
	end
	if action=="Move" then
		if not vector(payload.direction) or payload.direction.Magnitude>1.01 or math.abs(payload.direction.Y)>0.01 then return end
		s.human.move=payload.direction; s.human.lastMove=clock
		if type(payload.sprint)=="boolean" then s.human.sprinting=payload.sprint end
		if type(payload.locked)=="boolean" then
			if s.human.locked~=payload.locked then require(script.Parent.Brawler).event(s.combat,s.human,if payload.locked then "Lock" else "Unlock") end
			s.human.locked=payload.locked
		end
		return
	end
	local aim=nil
	if payload.aim~=nil then
		if not vector(payload.aim) or (payload.aim-s.human.root.Position).Magnitude>150 then return end
		aim=payload.aim
	end
	local ok,reason=s.combat:request(s.human,action,aim)
	if not ok and reason~="Committed" then s.combat:cue(s.human,string.upper(reason)) end
end
function Matches:update(dt,now)
	for player,s in self.sessions do
		if s.phase=="Duel" then
			if os.clock()-s.human.lastMove>0.4 then s.human.move=Vector3.zero end
			s.combat:update(math.min(dt,0.1),now)
			if s.phase=="Duel" then
				if s.tutorial then Tutorial.update(s,now,dt) else s.ai:update(now) end
			end
		end
		if s.combat and now>=(s.nextSnapshot or 0) then
			s.nextSnapshot=now+Config.SnapshotInterval; self:snapshot(player,s)
		end
	end
end
function Matches:remove(player)
	local s=self.sessions[player]
	if s then self:destroy(s); self.sessions[player]=nil end
end
return Matches
