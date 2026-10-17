local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local Rules=require(Shared.Rules)
local World=require(script.Parent.World)
local Combat=require(script.Parent.Combat)
local AI=require(script.Parent.AI)
local Tutorial=require(script.Parent.Tutorial)
local AntiCheat=require(script.Parent.VelmoraAntiCheat)
local Techniques=require(script.Parent.Techniques)
local Bodies=require(script.Parent.Bodies)
local Online=require(script.Parent.Online)
local SkillBuilds=require(script.Parent.SkillBuilds)
local BuildPresets=require(script.Parent.BuildPresets)
local Zones=require(script.Parent.Zones)
local Matches={}; Matches.__index=Matches
-- Skill builds (PROG-001..003) are resolved and validated here, on the server:
-- a spec is {nodes={...}, unlocked={[id]=true}} (unlocked = the profile's set)
-- or, for the AI, {preset="Hard"}; with a ranked bracket the build must also
-- fit its budget. Returns true + kit (nil = no build) or false + reason.
function Matches.resolveKit(fighterId,spec,bracket)
	if spec==nil then return true,nil end
	if type(spec)~="table" then return false,"Invalid build" end
	local nodes=spec.nodes
	if spec.preset~=nil then
		nodes=BuildPresets.ai(fighterId,spec.preset)
		if not nodes then return false,"Unknown AI preset" end
	end
	local kit,reason
	if bracket~=nil then kit,reason=SkillBuilds.admit(bracket,fighterId,nodes,spec.unlocked)
	else kit,reason=SkillBuilds.build(fighterId,nodes,{unlocked=spec.unlocked}) end
	if not kit then return false,reason end
	return true,kit
end
function Matches.new(remote)
	local folder=Instance.new("Folder"); folder.Name="NinjaDuels"; folder.Parent=workspace
	local self=setmetatable({remote=remote,folder=folder,sessions={},nextLane=0,epoch=0},Matches)
	-- Online 1v1 (queue, private codes, two-player duels) on the same sessions.
	self.online=Online.new(self)
	return self
end
-- Each duel owns a stage far from every other one.
function Matches.laneOrigin(lane)
	return Vector3.new((lane-1)*520,0,0)
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
	if s.human then AntiCheat.clear(s.human) end
	if s.folder then s.folder:Destroy() end
	s.tutorial=nil; s.folder=nil; s.combat=nil; s.ai=nil; s.human=nil; s.bot=nil
end
function Matches:selection(player,notice)
	local s=self:session(player)
	if s.online and self.online then self.online:leave(player,s) end
	self:destroy(s)
	player.Character=nil; s.phase="Selection"; s.epoch+=1
	self:send(player,{phase="Selection",epoch=s.epoch,notice=notice})
end
-- `options` (optional): {player=spec, bot=spec, bracket=id} skill builds (see
-- Matches.resolveKit). An invalid or over-budget build refuses the start. No
-- options: both fighters are exactly today's kits.
function Matches:start(player,playerId,botId,training,options)
	local s=self:session(player)
	if not Fighters[playerId] or not Fighters[botId] then return false end
	local playerKit,botKit
	if options~=nil then
		if type(options)~="table" then return false,"Invalid options" end
		local ok,result=Matches.resolveKit(playerId,options.player,options.bracket)
		if not ok then return false,result end
		playerKit=result
		ok,result=Matches.resolveKit(botId,options.bot,options.bracket)
		if not ok then return false,result end
		botKit=result
	end
	self:destroy(s); s.epoch+=1
	s.playerId=playerId; s.botId=botId; s.winner=nil; s.phase="Duel"; s.origin=Matches.laneOrigin(s.lane)
	s.options=options
	s.folder=Instance.new("Folder"); s.folder.Name="Duel_"..s.lane; s.folder.Parent=self.folder
	s.effects=Instance.new("Folder"); s.effects.Name="Effects"; s.effects.Parent=s.folder
	World.arena(s.folder,s.origin)
	s.combat=Combat.new(s); s.combat.now=workspace:GetServerTimeNow()
	local function actor(id,def,position,look,kit)
		local model,hum,root,joints=World.rig(s.folder,Fighters[def],CFrame.lookAt(position,look),id)
		return s.combat:add(id,model,hum,root,joints,def,kit)
	end
	s.human=actor("PlayerFighter",playerId,s.origin+Vector3.new(0,3,Config.StartDistance),s.origin+Vector3.new(0,3,-Config.StartDistance),playerKit)
	s.bot=actor("AIFighter",botId,s.origin+Vector3.new(0,3,-Config.StartDistance),s.origin+Vector3.new(0,3,Config.StartDistance),botKit)
	s.human.target=s.bot; s.bot.target=s.human; s.human.locked=true; s.bot.locked=true
	player.Character=s.human.model
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+ s.epoch)
	s.finishing=false
	-- Tournament rounds: first to two (one in training).
	s.round=1;s.wins={PlayerFighter=0,AIFighter=0};s.roundsToWin=if training then 1 else Config.RoundsToWin
	s.finish=function(winner,_loser)
		self:roundOver(s,winner,function() self:snapshot(player,s) end,function() self:nextRound(player,s) end)
	end
	s.tutorial=nil; if training then Tutorial.new(s) end
	-- Tournament framing: both fighters are shown before the round begins.
	s.introUntil=if training then nil else s.combat.now+2.6
	local epoch=s.epoch
	s.human.hum.Died:Connect(function() if s.epoch==epoch and s.phase=="Duel" then s.human.health=0; s.human.state="Defeated"; s.finish(s.bot,s.human) end end)
	s.bot.hum.Died:Connect(function() if s.epoch==epoch and s.phase=="Duel" then s.bot.health=0; s.bot.state="Defeated"; s.finish(s.human,s.bot) end end)
	self:snapshot(player,s)
	return true
end
-- A round is won. Shared by the local duel and the online duel: `notify` sends
-- the snapshots, `advance` starts the next round.
function Matches:roundOver(s,winner,notify,advance)
	if s.phase~="Duel" or s.finishing then return end
	-- The finishing blow gets a beat: the world holds, the camera eases out
	-- and K.O. is called before the next round or the result screen.
	s.finishing=true; s.winner=winner.id
	s.wins[winner.id]=(s.wins[winner.id] or 0)+1
	local decided=s.wins[winner.id]>=s.roundsToWin
	s.matchPoint=decided
	local finishEpoch=s.epoch
	notify()
	task.delay(if decided then 1.5 else 1.9,function()
		if s.epoch~=finishEpoch or not s.finishing or s.phase~="Duel" then return end
		s.finishing=false
		if not decided then advance();return end
		s.phase="Result"; s.combat:clear(true)
		for _,a in s.combat.actors do World.pose(a,s.combat.now,0.1) end
		for _,a in s.combat.actors do a.hum.WalkSpeed=0; a.root.Anchored=true end
		notify()
	end)
end
function Matches:nextRound(player,s)
	self:resetRound(s)
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+s.epoch)
	self:snapshot(player,s)
end
-- Next round: same stage and bodies, fresh fighters, a short intro. A new
-- epoch tells the client to reset its presentation like a fresh duel. The
-- first actor (the player, or online seat 1) restarts on +Z, the second on -Z.
function Matches:resetRound(s)
	local c=s.combat
	local first,second=c.actors[1],c.actors[2]
	s.epoch+=1;s.round+=1;s.winner=nil;s.matchPoint=false
	c:clear(true)
	for _,a in c.actors do
		a.health=a.def.Health;a.hum.Health=a.health;a.chakra=a.def.Chakra or Config.Chakra;a.cooldowns={}
		a.subCharges=Config.Substitution.Charges;a.subCooldown=0;a.subRegenAt=math.huge
		a.state="Neutral";a.untilTime=0;a.koStyle=nil;a.koAirborne=nil;a.groundPose=nil;a.reaction=nil;a.reactionVelocity=nil
		a.stamina=100;a.hitstopUntil=0;a.root.Anchored=false;a.hum.WalkSpeed=a.def.Speed
		a.shieldCharges=a.def.SandShield and a.def.SandShield.Charges or 0
	end
	c:relocate(first,s.origin+Vector3.new(0,3,Config.StartDistance));c:relocate(second,s.origin+Vector3.new(0,3,-Config.StartDistance))
	first.root.CFrame=CFrame.lookAt(first.root.Position,second.root.Position)
	second.root.CFrame=CFrame.lookAt(second.root.Position,first.root.Position)
	s.introUntil=c.now+1.8
end
function Matches:snapshot(player,s)
	self:send(player,self:view(s,s,s.human,s.bot))
end
-- The duel seen from one side: `human` is the viewer's own actor and `bot` the
-- opponent (its model is named bot.id); `winner` reads "PlayerFighter" when
-- the viewer won. `cursor` holds this viewer's impact feed position: the local
-- session itself, or an online seat.
function Matches:view(s,cursor,mine,theirs)
	local now=s.combat.now
	-- Every Flying Thunder God seal the client should draw: planted kunai
	-- (surface + normal) and the seal riding on the opponent's body.
	local function sealList(a)
		local list={}
		for _,seal in Techniques.seals(s.combat,a,now) do
			local entry=seal.anchor
			if entry then
				table.insert(list,{id=entry.id or 0,surface=entry.surface or seal.position,normal=entry.normal or Vector3.yAxis,
					remaining=math.max(0,entry.expires-now),body=entry.actor and entry.actor.id,wind=entry.wind==true,wake=entry.wake==true})
			end
		end
		return list
	end
	local function data(a)
		local ready={}
		for i,spec in a.def.Techniques do
			ready[i]={id=spec.Id,name=spec.Name,cost=spec.Cost,remaining=math.max(0,(a.cooldowns[spec.Id] or 0)-now),condition=not spec.Requires or (spec.Requires=="Anchor" and Techniques.sealOf(s.combat,a,now)~=nil) or (spec.Requires=="Target" and s.combat:targetValid(a,a.target,spec.Range,0.35))}
		end
		return {id=a.id,fighterId=a.fighterId,fighter=a.def.Name,health=a.health,maxHealth=a.def.Health,chakra=a.chakra,maxChakra=a.def.Chakra or Config.Chakra,stamina=a.stamina or 100,state=a.state,
			techniques=ready,position=a.root.Position,channel=if a.state=="TechniqueChannel" then math.max(0,a.untilTime-s.combat.now) else 0,
			anchor=a.anchor and a.anchor.position,illusion=math.max(0,a.illusionUntil-s.combat.now),decoy=a.decoyPosition,
			cue=if a.cueUntil>s.combat.now then a.cue else "",dodge=math.max(0,a.dodgeUntil-s.combat.now),read=math.max(0,a.readUntil-s.combat.now),
			speed=a.locomotion.Magnitude,airborne=a.airborne,sprinting=a.model:GetAttribute("MovementSprinting")==true,
			landStrong=a.model:GetAttribute("MovementHardLanding")==true,pursuit=math.max(0,a.pursuitUntil-s.combat.now),combo=a.combo,
			subCharges=a.subCharges,wall=a.wall~=nil,reaction=a.reaction,guardImpact=math.max(0,(a.guardImpact or 0)-s.combat.now),attackName=a.attackName,attackElapsed=s.combat.now-(a.attackStarted or 0),airHold=a.airHold,impactSerial=a.impactSerial or 0,impactHeavy=a.impactHeavy,impactStyle=a.impactStyle,
			hitFrom=a.hitFrom,hitAngle=a.hitAngle,hitStrength=a.hitStrength or 0,hitZone=a.hitZone,hitKind=a.hitKind,hitTwist=a.hitTwist,groundPose=a.groundPose,groundSide=a.groundSide,koStyle=a.koStyle,koAirborne=a.koAirborne,reactionElapsed=math.max(0,s.combat.now-(a.reactionStartedAt or s.combat.now)),events=a.events,velocity=if a.state=="Dodging" then (a.dodgeDirection or Vector3.zero)*35 else a.root.AssemblyLinearVelocity,
			-- Presentation timing for throws, casts, teleports and variants:
			-- elapsed values are measured on the server clock the client shares.
			attackSerial=a.attackSerial or 0,attackVariant=a.attackVariant,
			throwSerial=a.throwSerial or 0,throwKind=a.throwKind,throwElapsed=now-(a.throwStarted or -10),throwRelease=a.throwRelease or .1,
			castId=a.castId,castElapsed=now-(a.castStarted or now),
			anchorSurface=a.anchor and a.anchor.surface,anchorNormal=a.anchor and a.anchor.normal,anchorRemaining=a.anchor and math.max(0,a.anchor.expires-now) or 0,
			teleportSerial=a.teleportSerial or 0,flash=(a.flashUntil or 0)>now,lookVector=a.root.CFrame.LookVector,
			-- Phase 4: combo scaling, recharging substitution, seals, wall state.
			comboHits=a.comboHits or 0,comboDamage=a.comboDamage or 0,
			subRegen=if (a.subRegenAt or math.huge)<math.huge then math.max(0,a.subRegenAt-now) else 0,
			seals=sealList(a),splatNormal=if a.reaction=="WallSplat" then a.splatNormal else nil,
			splatElapsed=if a.reaction=="WallSplat" then now-(a.splatAt or now) else nil,
			counter=math.max(0,(a.counterUntil or 0)-now),warpSerial=a.warpSerial or 0,
			shield=a.shieldCharges or 0,shieldMax=a.def.SandShield and a.def.SandShield.Charges or 0,bound=a.reaction=="Bound",
			awaken=math.max(0,(a.awakenUntil or 0)-now),
			awakenReady=a.def.Awakening~=nil and not a.awakened and a.health>0 and a.health<=a.def.Health*Config.Awaken.Threshold,
			-- Neji: Rotation dome, closed chakra points and sealed techniques.
			rotation=(a.rotationUntil or 0)>now,tenketsu=if (a.tenketsuUntil or 0)>now then a.tenketsu or 0 else 0,
			sealed=math.max(0,(a.sealedUntil or 0)-now),
			-- Identity cues: which chakra points are closed on this body (body
			-- locations the client lights), a severed network, the kind of
			-- genjutsu it is under, a hungry Curse Mark.
			tenketsuPoints=if (a.tenketsuUntil or 0)>now then table.clone(a.tenketsuPoints or {}) else {},
			tenketsuSevere=(a.tenketsuUntil or 0)>now and (a.tenketsu or 0)>=4,
			illusionKind=if (a.illusionUntil or 0)>now then a.illusionKind else nil,
			curseHunger=a.curseHunger==true,
			-- Chakra on the body: the lightning stun it is locked in, the
			-- ground fire it stands in (ChakraCombat, Combat:updateHazards).
			shocked=if (a.shockUntil or 0)>now and (a.state=="Stunned" or a.reaction=="Bound") then a.shockUntil-now else 0,
			burning=math.max(0,(a.burnUntil or 0)-now),
			-- The share of chakra recovery the closed points leave (1: all), for
			-- the chakra bar; the air finisher window after the Dancing Leaf
			-- (Lion Combo, a lotus), for its prompt.
			chakraRegen=require(script.Parent.Brawler).tenketsuRegen(a,now),lion=math.max(0,(a.lionUntil or 0)-now),
			-- Temari: the open fan holding her up in the air.
			glide=a.gliding==true,
			-- Family buffs, counter stances and slows (Server/Families), for auras and the plate.
			family=require(script.Parent.Families).snapshot(a,now)}
	end
	-- Live projectiles: straight constant-speed flights the client reproduces
	-- exactly on the shared server clock, so blades and fire never stutter.
	local projectiles={}
	for _,p in s.combat.projectiles do
		-- infusion: the chakra nature it carries (nil: a plain object); planted:
		-- the tool a resting point or stretched wire is drawn as, "held" for a
		-- wire holding a body (ChakraCombat). Resting objects also carry what
		-- they mean (mark), their surface normal, their expiry and live charge
		-- (server clock), and a held wire the body it holds and its stake.
		table.insert(projectiles,{id=p.id,kind=p.kind,origin=p.origin,direction=p.direction,speed=p.speed,born=p.born,range=p.range,owner=p.a.id,radius=p.radius,growth=p.growth,infusion=p.infusion,planted=p.planted,
			mark=p.mark,normal=p.normal,expires=p.expires,charged=p.charged,holds=p.holds and p.holds.id,anchored=p.anchored,hidden=p.hidden})
	end
	local hazards={}
	for _,h in s.combat.hazards do
		table.insert(hazards,{position=h.position,radius=h.radius,remaining=math.max(0,h.expires-now),kind=h.kind,owner=h.a.id,lane=h.lane,look=h.look})
	end
	-- Only contacts the client has not been sent yet; remotes are ordered and
	-- reliable, and the client still filters by serial.
	local feed={}
	local sent=if cursor.impactEpoch==s.epoch then (cursor.sentImpact or 0) else 0
	for _,impact in s.combat.impacts do if impact.serial>sent then table.insert(feed,impact) end end
	cursor.sentImpact=s.combat.impactSerial or 0;cursor.impactEpoch=s.epoch
	local wins=s.wins or {}
	return {phase=s.phase,epoch=s.epoch,winner=s.winner and (if s.winner==mine.id then "PlayerFighter" else "AIFighter"),tutorial=Tutorial.snapshot(s),origin=s.origin,human=data(mine),bot=data(theirs),impacts=feed,impactSerial=s.combat.impactSerial or 0,
		-- Bodies that are not fighters (Naruto's shadow clones), drawn by Client/BodyViews.
		bodies=Bodies.view(s.combat),
		-- zones: wind lanes and updrafts (Zones.snapshot), drawn per kind by the client.
		projectiles=projectiles,hazards=hazards,zones=Zones.snapshot(s.combat,now),serverNow=now,intro=math.max(0,(s.introUntil or 0)-now),ko=s.finishing==true,
		round=s.round or 1,wins={human=wins[mine.id] or 0,bot=wins[theirs.id] or 0},roundsToWin=s.roundsToWin or 1,matchPoint=s.matchPoint}
end
function Matches:request(player,payload)
	local s=self:session(player); local clock=os.clock()
	if not Rules.consumeToken(s.bucket,clock,Config.RequestRate,Config.RequestBurst) then return end
	if type(payload)~="table" or type(payload.action)~="string" or #payload.action>24 then return end
	local action=payload.action
	if action=="Ready" then
		if s.online and self.online then self.online:refresh(player,s)
		elseif s.phase=="Selection" then self:send(player,{phase="Selection",epoch=s.epoch}) else self:snapshot(player,s) end
		return
	end
	if payload.epoch~=s.epoch then return end
	-- The online flow owns every request of a player who is in it.
	if self.online and self.online:request(player,s,action,payload,clock) then return end
	if action=="TutorialSkip" and s.tutorial then self:selection(player);s.tutorial=nil;return end
	if action=="Start" or action=="Tutorial" or action=="Rematch" or action=="Selection" then
		if clock-s.lastLifecycle<0.8 then return end
		if (action=="Start" or action=="Tutorial") and s.phase=="Selection" then
			if type(payload.player)~="string" or type(payload.bot)~="string" then return end
			s.lastLifecycle=clock; self:start(player,payload.player,payload.bot,action=="Tutorial")
		elseif action=="Rematch" and (s.phase=="Result" or s.finishing) then
			s.lastLifecycle=clock; self:start(player,s.playerId,s.botId,s.tutorial~=nil,s.options)
		elseif action=="Selection" and (s.phase=="Result" or s.finishing or s.tutorial) then s.lastLifecycle=clock; self:selection(player) end
		return
	end
	if s.phase~="Duel" or not s.human then return end
	self:act(s,s.human,payload,clock)
end
-- One player's input to their own actor: validated intent only, never state.
-- Shared by the local duel (s.human) and the online duel (each seat's actor);
-- the anti-cheat timing and rate state is kept per actor, so per player.
function Matches:act(s,actor,payload,clock)
	local action=payload.action
	if action~="Move" and not AntiCheat.check(actor,action,payload.clientTime,workspace:GetServerTimeNow()) then
		-- Diagnostics for latency tests: how many presses were refused, and how
		-- old the last refused one was (late packets vs rate limit).
		actor.refusedInputs=(actor.refusedInputs or 0)+1
		actor.refusedAge=if type(payload.clientTime)=="number" then workspace:GetServerTimeNow()-payload.clientTime else nil
		return
	end
	local function vector(v)
		return typeof(v)=="Vector3" and Rules.finite(v.X) and Rules.finite(v.Y) and Rules.finite(v.Z)
	end
	if action=="Move" then
		if s.autopilot or s.scripted or s.finishing then return end
		if not vector(payload.direction) or payload.direction.Magnitude>1.01 or math.abs(payload.direction.Y)>0.01 then return end
		actor.move=payload.direction; actor.lastMove=clock
		if type(payload.sprint)=="boolean" then actor.sprinting=payload.sprint end
		if type(payload.locked)=="boolean" then
			if actor.locked~=payload.locked then require(script.Parent.Brawler).event(s.combat,actor,if payload.locked then "Lock" else "Unlock") end
			actor.locked=payload.locked
		end
		-- Directional memory for routes: a strong push is kept for a moment even
		-- when it falls between two server frames (Brawler.observe).
		require(script.Parent.Brawler).observe(s.combat,actor)
		return
	end
	-- An action carries the same validated movement intent as Move. This keeps
 -- directional routes/dodges atomic with the button press, without granting
 -- the client authority over a route, state, cooldown or hit.
 if payload.direction~=nil and (not vector(payload.direction) or payload.direction.Magnitude>1.01 or math.abs(payload.direction.Y)>.01) then return end
 -- The chakra modifier is one boolean held with the action; what it does is
 -- decided by the server (the fighter's mastery), never by the client.
 if payload.chakra~=nil and type(payload.chakra)~="boolean" then return end
 local aim=nil
	if payload.aim~=nil then
		if not vector(payload.aim) or (payload.aim-actor.root.Position).Magnitude>150 then return end
		aim=payload.aim
	end
	if payload.direction~=nil and not (s.autopilot or s.scripted or s.finishing) then
  actor.move=payload.direction;actor.lastMove=clock
  if type(payload.sprint)=="boolean" then actor.sprinting=payload.sprint end
 end
 -- The held guard key is an intent that outlives a refused press (Combat
 -- re-raises it once free). Only players send it; the AI guards per tick.
 if action=="Guard" then actor.guardWanted=true elseif action=="GuardOff" then actor.guardWanted=false end
 local ok,reason=s.combat:request(actor,action,aim,payload.clientTime,if payload.chakra==true then {chakra=true} else nil)
	if not ok and reason~="Committed" and reason~="Intro" then s.combat:cue(actor,string.upper(reason)) end
end
function Matches:update(dt,now)
	for player,s in self.sessions do
		-- Online players' duels are stepped once each by Online:update below.
		if s.phase=="Duel" and not s.online then
			if os.clock()-s.human.lastMove>0.4 then s.human.move=Vector3.zero end
			s.combat:update(math.min(dt,0.1),now)
			if s.phase=="Duel" then
				local intro=s.introUntil and now<s.introUntil
				if s.tutorial then Tutorial.update(s,now,dt) elseif not s.botFrozen and not intro and not s.finishing then s.ai:update(now) end
			end
		end
		-- Regular cadence, plus an immediate packet when a contact, throw or
		-- teleport happened so presentation never waits a full interval.
		local urgent=s.combat and s.combat.urgent and now>=(s.lastUrgent or 0)+.03
		if s.combat and (now>=(s.nextSnapshot or 0) or urgent) then
			s.nextSnapshot=now+Config.SnapshotInterval; s.combat.urgent=false; s.lastUrgent=now; self:snapshot(player,s)
		end
	end
	if self.online then self.online:update(dt,now) end
end
function Matches:remove(player)
	local s=self.sessions[player]
	if s then
		-- A disconnect forfeits an online fight and frees queue entries and codes.
		if s.online and self.online then self.online:leave(player,s) end
		self:destroy(s); self.sessions[player]=nil
	end
end
return Matches
