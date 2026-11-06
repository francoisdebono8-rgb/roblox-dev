local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local BetaRoster=require(Shared.BetaRoster)
local Rules=require(Shared.Rules)
local World=require(script.Parent.World)
local Combat=require(script.Parent.Combat)
local AI=require(script.Parent.AI)
local Tutorial=require(script.Parent.Tutorial)
local AntiCheat=require(script.Parent.VelmoraAntiCheat)
local Techniques=require(script.Parent.Techniques)
local Ultimates=require(script.Parent.Ultimates)
local Bodies=require(script.Parent.Bodies)
local Copy=require(script.Parent.Copy)
local Brawler=require(script.Parent.Brawler)
local Online=require(script.Parent.Online)
local SkillBuilds=require(script.Parent.SkillBuilds)
local BuildPresets=require(script.Parent.BuildPresets)
local Zones=require(script.Parent.Zones)
local FirstMinute=require(Shared.FirstMinute)
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
	-- (04/11) The Prodigy Tournament against the AI (Server/Tournament).
	self.tournament=require(script.Parent.Tournament).new(self)
	return self
end
-- Each duel owns a stage far from every other one.
function Matches.laneOrigin(lane)
	return Vector3.new((lane-1)*520,0,0)
end
-- (B1 lot 2, DEC-034) What a new player's first minutes look like, measured
-- on the server (Codex's audit §3: time to the first input, the first jutsu,
-- the first finished duel; abandons). One line each in the log
-- ([NinjaDuelFirst]) and, in the published game, Roblox's onboarding funnel
-- (AnalyticsService, in order and once each; skipped quietly where the
-- service is unavailable, as in the tests).
Matches.FUNNEL={joined=1,input=2,jutsu=3,duel=4}
function Matches.measure(player,s,step)
	local m=s.metrics
	if not m or m[step.."At"] then return end
	m[step.."At"]=os.clock()
	local since=m[step.."At"]-(m.joined or m[step.."At"])
	print(string.format("[NinjaDuelFirst] %s %s %.1fs",tostring(player.UserId),step,since))
	local order=Matches.FUNNEL[step]
	if order and (m.funnel or 0)<order then
		m.funnel=order
		pcall(function() game:GetService("AnalyticsService"):LogOnboardingFunnelStepEvent(player,order,step) end)
	end
end
-- (FEEL 05/11, AVANT defect 3) What became of the player's presses this
-- round: accepted late, dropped as too old (gate), refused by the fight
-- (per reason), or buffered then lost when the body never came free in time
-- (Combat). Counted on the actor, sent to Roblox analytics once per round
-- (Matches.logPresses), so the share of presses that do nothing is measured
-- in the live game, not only in Studio.
function Matches.countPress(actor,kind,reason)
	local stats=actor.pressStats or {late=0,gate=0,refused=0,lost=0,reasons={}}
	actor.pressStats=stats
	stats[kind]=(stats[kind] or 0)+1
	if kind=="refused" and reason then stats.reasons[reason]=(stats.reasons[reason] or 0)+1 end
end
function Matches.logPresses(player,actor)
	local stats=actor and actor.pressStats
	if not player or not stats then return end
	actor.pressStats=nil
	pcall(function()
		local service=game:GetService("AnalyticsService")
		local fields={[Enum.AnalyticsCustomFieldKeys.CustomField01.Name]=tostring(actor.fighterId)}
		for _,kind in {"late","gate","refused","lost"} do
			if (stats[kind] or 0)>0 then service:LogCustomEvent(player,"Press_"..kind,stats[kind],fields) end
		end
	end)
end
function Matches:send(player,data)
	if player.Parent==Players then self.remote:FireClient(player,data) end
end
function Matches:session(player)
	if self.sessions[player] then return self.sessions[player] end
	self.nextLane+=1
	local s={phase="Selection",lane=self.nextLane,bucket={tokens=Config.RequestBurst,time=os.clock()},lastLifecycle=-10,epoch=0,
		metrics={joined=os.clock()},owner=player}
	self.sessions[player]=s
	Matches.measure(player,s,"joined")
	return s
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
	-- Back on the roster: a tournament in progress ends here.
	s.cup=nil;s.cupMatch=nil;s.spectate=nil;s.autopilot=nil;s.cupPilot=nil
	self:send(player,{phase="Selection",epoch=s.epoch,notice=notice})
	-- (Lobby, 04/11) in a duel server the roster is the lobby: back home.
	if self.lobby then self.lobby:onSelection(player) end
end
-- `options` (optional): {player=spec, bot=spec, bracket=id} skill builds (see
-- Matches.resolveKit). An invalid or over-budget build refuses the start. No
-- options: both fighters are exactly today's kits.
function Matches:start(player,playerId,botId,training,options)
	local s=self:session(player)
	if not Fighters[playerId] or not Fighters[botId] then return false end
	-- (Beta 03/11) only the beta's fighters (Shared/BetaRoster), whatever a client asks for.
	if not table.find(BetaRoster,playerId) or not table.find(BetaRoster,botId) then return false,"Not in the beta" end
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
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+ s.epoch,Matches.aiLevel(s))
	s.finishing=false
	-- Tournament rounds: first to two (one in training).
	s.round=1;s.wins={PlayerFighter=0,AIFighter=0};s.roundsToWin=if training then 1 else Config.RoundsToWin
	s.finish=function(winner,_loser)
		self:roundOver(s,winner,function() self:snapshot(player,s) end,function() self:nextRound(player,s) end)
	end
	s.tutorial=nil; if training then Tutorial.new(s,if s.firstStage=="intro" then "first" else nil) end
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
	if decided and not s.tutorial and not s.online and s.owner then Matches.measure(s.owner,s,"duel") end
	if not s.online and s.owner and s.human then Matches.logPresses(s.owner,s.human) end
	local finishEpoch=s.epoch
	notify()
	-- (Final blow) the thrown body needs its flight and a beat on the floor.
	task.delay(if decided then 2.2 else 2.6,function()
		if s.epoch~=finishEpoch or not s.finishing or s.phase~="Duel" then return end
		s.finishing=false
		if not decided then advance();return end
		s.phase="Result"; s.combat:clear(true)
		for _,a in s.combat.actors do World.pose(a,s.combat.now,0.1) end
		for _,a in s.combat.actors do a.hum.WalkSpeed=0; a.root.Anchored=true end
		notify()
	end)
end
-- (B1) The bot's level: the roster's choice for a duel (easy by default:
-- the first duel of a new player), stronger each round of the cup.
Matches.LEVELS={easy=true,normal=true,hard=true}
function Matches.aiLevel(s)
	if s.cup then
		if s.spectate then return "normal" end
		local m=s.cup.match or 1
		return if m<=4 then "easy" elseif m<=6 then "normal" else "hard"
	end
	return if Matches.LEVELS[s.aiLevel or ""] then s.aiLevel else "easy"
end
function Matches:nextRound(player,s)
	self:resetRound(s)
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+s.epoch,Matches.aiLevel(s))
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
		a.state="Neutral";a.untilTime=0;a.koStyle=nil;a.koAirborne=nil;a.koFlight=nil;a.groundPose=nil;a.reaction=nil;a.reactionVelocity=nil
		a.armed=nil;a.armAt=0;a.chakraLoad=nil
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
		for i,own in a.def.Techniques do
			-- (06/11) Kakashi's copy slot shows the jutsu his Sharingan copied.
			local copied=Copy.slotSpec(s.combat,a,i)
			local spec=copied or own
			ready[i]={id=spec.Id,name=spec.Name,cost=spec.Cost,remaining=math.max(0,(a.cooldowns[spec.Id] or 0)-now),requires=spec.Requires,condition=not spec.Requires or (spec.Requires=="Anchor" and Techniques.sealOf(s.combat,a,now)~=nil) or (spec.Requires=="Target" and s.combat:targetValid(a,a.target,spec.Range,0.35))}
			-- (06/11) A key that does something else while the technique's work is
			-- out (Naruto's crowd: TAKE A BODY) shows that instead.
			local technique=Techniques[spec.Id]
			local live=technique and technique.view and technique.view(s.combat,a,spec,now)
			if live then for k,v in live do ready[i][k]=v end;ready[i].requires=nil;ready[i].alt=true end
			if copied then ready[i].copied=true;ready[i].from=copied.CopiedFrom end
		end
		-- (DEC-032) the hand-seal jutsu (cooldowns) and the weave in progress
		local sealReady=nil
		if a.def.SealJutsu then
			sealReady={}
			for i,spec in a.def.SealJutsu do sealReady[i]={id=spec.Id,remaining=math.max(0,(a.cooldowns[spec.Id] or 0)-now),cost=spec.Cost} end
		end
		local weave=a.sealing
		local sealing=if weave and weave.untilT>s.combat.now then {seq=table.clone(weave.seq),remaining=weave.untilT-s.combat.now} else nil
		return {id=a.id,fighterId=a.fighterId,fighter=a.def.Name,sealReady=sealReady,sealing=sealing,health=a.health,maxHealth=a.def.Health,chakra=a.chakra,maxChakra=a.def.Chakra or Config.Chakra,stamina=a.stamina or 100,state=a.state,
			techniques=ready,position=a.root.Position,channel=if a.state=="TechniqueChannel" then math.max(0,a.untilTime-s.combat.now) else 0,
			anchor=a.anchor and a.anchor.position,illusion=math.max(0,a.illusionUntil-s.combat.now),decoy=a.decoyPosition,
			cue=if a.cueUntil>s.combat.now then a.cue else "",quiet=if (a.quietUntil or 0)>s.combat.now then a.quiet else nil,dodge=math.max(0,a.dodgeUntil-s.combat.now),read=math.max(0,a.readUntil-s.combat.now),
			speed=a.locomotion.Magnitude,airborne=a.airborne,sprinting=a.model:GetAttribute("MovementSprinting")==true,
			landStrong=a.model:GetAttribute("MovementHardLanding")==true,pursuit=math.max(0,a.pursuitUntil-s.combat.now),combo=a.combo,
			subCharges=a.subCharges,chakraLoad=if a.chakraLoad and a.chakraLoad.untilTime>s.combat.now then a.chakraLoad.nature else nil,infused=a.pending and a.pending.chakraFlow or nil,wall=a.wall~=nil,wallMode=a.wall and a.wall.mode or nil,wallSide=a.wall and a.wall.side or nil,reaction=a.reaction,guardImpact=math.max(0,(a.guardImpact or 0)-s.combat.now),attackName=a.attackName,attackElapsed=s.combat.now-(a.attackStarted or 0),whiffed=if a.state=="Recovery" and a.attackWhiffed then true else nil,airHold=a.airHold,impactSerial=a.impactSerial or 0,impactHeavy=a.impactHeavy,impactStyle=a.impactStyle,
			hitFrom=a.hitFrom,hitAngle=a.hitAngle,hitStrength=a.hitStrength or 0,hitZone=a.hitZone,hitKind=a.hitKind,hitTwist=a.hitTwist,groundPose=a.groundPose,groundSide=a.groundSide,koStyle=a.koStyle,koAirborne=a.koAirborne,koFlying=a.koFlight~=nil,reactionElapsed=math.max(0,s.combat.now-(a.reactionStartedAt or s.combat.now)),
			-- (Audit 29/10) Only the counters the client reads: every event count
			-- (80+ names, never reset) went out 30 times a second.
			events=if a.events then {Parry=a.events.Parry,ReadSlip=a.events.ReadSlip,Draw=a.events.Draw,Awaken=a.events.Awaken} else nil,velocity=if a.state=="Dodging" then (a.dodgeDirection or Vector3.zero)*35 else a.root.AssemblyLinearVelocity,
			-- Presentation timing for throws, casts, teleports and variants:
			-- elapsed values are measured on the server clock the client shares.
			attackSerial=a.attackSerial or 0,attackVariant=a.attackVariant,armed=a.armed==true,ultimate=a.ultimate or 0,ultimateReady=Ultimates.ready(a),
			-- (Stage 6) a whole-sequence clip (an ultimate's caster or held body).
			ultClip=a.ultClip,ultSerial=a.ultSerial or 0,ultElapsed=if a.ultClip then now-(a.ultAt or now) else nil,
			-- (É7) What the client's guess of its own next press needs (Brawler's
			-- own rules, one table: Brawler.guessView).
			guess=Brawler.guessView(s.combat,a),
			throwSerial=a.throwSerial or 0,throwKind=a.throwKind,throwElapsed=now-(a.throwStarted or -10),throwRelease=a.throwRelease or .1,
			castId=a.castId,castElapsed=now-(a.castStarted or now),
			-- A held technique gathering (0..1), for the body and the fire at the mouth.
			techCharge=if a.state=="TechniqueChannel" then a.techCharge else nil,
			-- A state of the body held until a strike releases it (Server/BodyState).
			bodyState=require(script.Parent.BodyState).snapshot(a,now),
			anchorSurface=a.anchor and a.anchor.surface,anchorNormal=a.anchor and a.anchor.normal,anchorRemaining=a.anchor and math.max(0,a.anchor.expires-now) or 0,
			teleportSerial=a.teleportSerial or 0,flash=(a.flashUntil or 0)>now,lookVector=a.root.CFrame.LookVector,turn=a.turnRate or 0,
			-- Phase 4: combo scaling, recharging substitution, seals, wall state.
			comboHits=a.comboHits or 0,comboDamage=a.comboDamage or 0,
			subRegen=if (a.subRegenAt or math.huge)<math.huge then math.max(0,a.subRegenAt-now) else 0,
			seals=sealList(a),splatNormal=if a.reaction=="WallSplat" then a.splatNormal else nil,
			splatElapsed=if a.reaction=="WallSplat" then now-(a.splatAt or now) else nil,
			counter=math.max(0,(a.counterUntil or 0)-now),warpSerial=a.warpSerial or 0,
			shield=a.shieldCharges or 0,shieldMax=a.def.SandShield and a.def.SandShield.Charges or 0,bound=a.reaction=="Bound",boundKind=if a.reaction=="Bound" then a.boundKind else nil,
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
			family=require(script.Parent.Families).snapshot(a,now,s.combat),
			-- (06/11) The jutsu Kakashi's Sharingan holds (his eye stays lit).
			copy=Copy.view(s.combat,a)}
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
		table.insert(projectiles,{id=p.id,kind=p.kind,origin=p.origin,direction=p.direction,speed=p.speed,born=p.born,range=p.range,owner=p.a.id,caster=p.a.fighterId,radius=p.radius,growth=p.growth,infusion=p.infusion,planted=p.planted,
			mark=p.mark,normal=p.normal,expires=p.expires,charged=p.charged,holds=p.holds and p.holds.id,anchored=p.anchored,hidden=p.hidden})
	end
	local hazards={}
	for _,h in s.combat.hazards do
		-- A buried charge says whether it is armed yet (QA-004 M5: posed → armed).
		table.insert(hazards,{position=h.position,radius=h.radius,remaining=math.max(0,h.expires-now),kind=h.kind,owner=h.a.id,lane=h.lane,look=h.look,
			charge=if h.charge then (if now>=(h.armedAt or 0) then "armed" else "posed") else nil})
	end
	-- Only contacts the client has not been sent yet; remotes are ordered and
	-- reliable, and the client still filters by serial.
	local feed={}
	local sent=if cursor.impactEpoch==s.epoch then (cursor.sentImpact or 0) else 0
	for _,impact in s.combat.impacts do if impact.serial>sent then table.insert(feed,impact) end end
	cursor.sentImpact=s.combat.impactSerial or 0;cursor.impactEpoch=s.epoch
	local wins=s.wins or {}
	return {phase=s.phase,epoch=s.epoch,first=s.firstStage,winner=s.winner and (if s.winner==mine.id then "PlayerFighter" else "AIFighter"),tutorial=Tutorial.snapshot(s),origin=s.origin,human=data(mine),bot=data(theirs),impacts=feed,impactSerial=s.combat.impactSerial or 0,
		-- Bodies that are not fighters (Naruto's shadow clones), drawn by Client/BodyViews.
		bodies=Bodies.view(s.combat),
		-- zones: wind lanes and updrafts (Zones.snapshot), drawn per kind by the client.
		projectiles=projectiles,hazards=hazards,zones=Zones.snapshot(s.combat,now),serverNow=now,intro=math.max(0,(s.introUntil or 0)-now),ko=s.finishing==true,
		round=s.round or 1,wins={human=wins[mine.id] or 0,bot=wins[theirs.id] or 0},roundsToWin=s.roundsToWin or 1,matchPoint=s.matchPoint,
		-- (Tournament) the bracket in play, and a match the player only watches.
		cup=if s.cup and self.tournament then self.tournament:view(s.cup) else nil,spectate=s.spectate==true}
end
function Matches:request(player,payload)
	local s=self:session(player); local clock=os.clock()
	-- (Audit 29/10) The stick has its own budget: a pad in motion sends up to
	-- 30 Move packets a second and they used to drain the presses' budget.
	if type(payload)=="table" and payload.action=="Move" then
		s.moveBucket=s.moveBucket or {tokens=Config.RequestBurst,time=clock}
		if not Rules.consumeToken(s.moveBucket,clock,Config.RequestRate,Config.RequestBurst) then return end
	elseif not Rules.consumeToken(s.bucket,clock,Config.RequestRate,Config.RequestBurst) then return end
	if type(payload)~="table" or type(payload.action)~="string" or #payload.action>24 then return end
	local action=payload.action
	if action=="Ready" then
		if s.online and self.online then self.online:refresh(player,s)
		elseif s.phase=="Selection" then self:send(player,{phase="Selection",epoch=s.epoch})
		elseif (s.phase=="Bracket" or s.phase=="Champion") and s.cup then self.tournament:send(player,s,s.phase)
		elseif s.combat then self:snapshot(player,s) end
		return
	end
	if payload.epoch~=s.epoch then return end
	if s.metrics and not s.metrics.inputAt and (action~="Move" or (typeof(payload.direction)=="Vector3" and payload.direction.Magnitude>.5)) then Matches.measure(player,s,"input") end
	-- The online flow owns every request of a player who is in it.
	if self.online and self.online:request(player,s,action,payload,clock) then return end
	-- (B1) held on the first minute: straight to its duel, not the roster.
	if action=="TutorialSkip" and s.tutorial and s.tutorial.first then s.tutorial.done=true;return end
	if action=="TutorialSkip" and s.tutorial then self:selection(player);s.tutorial=nil;return end
	-- (Audit 04/11) one step skipped (the panel's "tap: skip the step").
	if action=="TutorialStep" and s.tutorial then
		if clock-(s.lastStepSkip or -10)>.3 then s.lastStepSkip=clock;Tutorial.skip(s,s.combat and s.combat.now or clock) end
		return
	end
	if self.tournament and self.tournament:request(player,s,action,payload) then return end
	-- (B1 lot 2) PLAY on a first roster: the first minute with his fighter,
	-- his story's rival as the partner and then the opponent (easy AI).
	if action=="First" then
		if clock-s.lastLifecycle<0.8 or s.phase~="Selection" or type(payload.player)~="string" then return end
		local rival=FirstMinute.rival(payload.player)
		if not rival then return end
		s.lastLifecycle=clock;s.aiLevel="easy";s.firstStage="intro"
		if not self:start(player,payload.player,rival,true) then s.firstStage=nil end
		return
	end
	if action=="Start" or action=="Tutorial" or action=="Rematch" or action=="Selection" then
		if clock-s.lastLifecycle<0.8 then return end
		if (action=="Start" or action=="Tutorial") and s.phase=="Selection" then
			if type(payload.player)~="string" or type(payload.bot)~="string" then return end
			s.lastLifecycle=clock;s.firstStage=nil
			if type(payload.level)=="string" and Matches.LEVELS[payload.level] then s.aiLevel=payload.level end
			self:start(player,payload.player,payload.bot,action=="Tutorial")
		elseif action=="Rematch" and (s.phase=="Result" or s.finishing) then
			s.lastLifecycle=clock;s.firstStage=nil; self:start(player,s.playerId,s.botId,s.tutorial~=nil,s.options)
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
	actor.playerInput=true
	-- (Audit 29/10) The pad's × is the chase inside its window, else the jump.
	-- The client decided from a state one round trip old: a window already
	-- closed here became a paid ground dash. The server decides now, and a
	-- chase it refuses still jumps.
	local padJump=action=="PadJump"
	if padJump then
		action=if (actor.pursuitUntil or 0)>s.combat.now and actor.target and actor.target.health>0 then "Pursuit" else "Jump"
	end
	local clientTime=payload.clientTime
	if action~="Move" then
		local passed,late=AntiCheat.check(actor,action,clientTime,workspace:GetServerTimeNow())
		if not passed then
			-- Diagnostics for latency tests: how many presses were refused, and how
			-- old the last refused one was (late packets vs rate limit).
			actor.refusedInputs=(actor.refusedInputs or 0)+1
			actor.refusedAge=if type(clientTime)=="number" then workspace:GetServerTimeNow()-clientTime else nil
			Matches.countPress(actor,"gate")
			return
		end
		-- (FEEL 05/11) a late press plays without its (stale) time.
		if late then clientTime=nil;Matches.countPress(actor,"late") end
	end
	local function vector(v)
		return typeof(v)=="Vector3" and Rules.finite(v.X) and Rules.finite(v.Y) and Rules.finite(v.Z)
	end
	if action=="Move" then
		if s.autopilot or s.scripted or s.finishing then return end
		if not vector(payload.direction) or payload.direction.Magnitude>1.01 or math.abs(payload.direction.Y)>0.01 then return end
		actor.move=payload.direction; actor.lastMove=clock
		if type(payload.sprint)=="boolean" then actor.sprinting=payload.sprint end
		-- (DEC-031) Free (not locked on), the body faces where the player looks.
		if payload.look==false then actor.look=nil end
		if payload.look~=nil and payload.look~=false then
			if vector(payload.look) and math.abs(payload.look.Y)<=.01 and payload.look.Magnitude>.9 and payload.look.Magnitude<1.01 then actor.look=payload.look end
		end
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
 -- (Reference quality) A technique key is held: its release lets a held
 -- technique go (Combat.charging). Players hold keys; the AI plans its own.
 local slot=string.match(action,"^Technique(%d)$") or (if string.match(action,"^Seal%d$") then "1" else nil)
 if slot then actor.techHold={slot=tonumber(slot),down=true} end
 if action=="SealRelease" then
  if actor.techHold then actor.techHold.down=false end
  return
 end
 local ok,reason=s.combat:request(actor,action,aim,clientTime,if payload.chakra==true then {chakra=true} else nil)
	if padJump and action=="Pursuit" and ok==false then action="Jump";ok,reason=s.combat:request(actor,"Jump",aim,clientTime,nil) end
	if ok==false and not actor.latePress then Matches.countPress(actor,"refused",reason) end
	-- (05/11) A press refused while the body takes a blow says how to get out
	-- when the dodge button would ("Q" reads ○ on a pad, A on AZERTY).
	if not ok and reason=="Reacting" and s.combat.escapeOpen(s.combat,actor) then s.combat:cue(actor,"HIT • Q TO ESCAPE")
	elseif not ok and reason~="Committed" and reason~="Intro" and reason~="Empty slot" then
		s.combat:cue(actor,string.upper(reason))
		-- (FEEL 05/11) the client only shows the loud cues: the reason also goes
		-- on the quiet line, so a refused button is never silent.
		s.combat:quiet(actor,string.upper(reason))
	elseif not ok and reason=="Committed" and not actor.latePress then s.combat:quiet(actor,"BUSY") end
end
function Matches:update(dt,now)
	for player,s in self.sessions do
		-- Online players' duels are stepped once each by Online:update below.
		if s.phase=="Duel" and not s.online then
			-- (an autopilot drives the first fighter itself: its stick is not stale)
			if not s.autopilot and os.clock()-s.human.lastMove>0.4 then s.human.move=Vector3.zero end
			s.combat:update(math.min(dt,0.1),now)
			if s.phase=="Duel" then
				local intro=s.introUntil and now<s.introUntil
				if s.tutorial then Tutorial.update(s,now,dt) elseif not s.botFrozen and not intro and not s.finishing then s.ai:update(now) end
				-- (B1 lot 2) the first minute's last prompt done: its real duel.
				if s.tutorial and s.tutorial.done and s.firstStage=="intro" then
					s.firstStage="duel";s.aiLevel="easy";self:start(player,s.playerId,s.botId,false)
				end
				if s.metrics and not s.metrics.jutsuAt and s.human and s.human.events then
					for name in s.human.events do if string.sub(name,1,5)=="Cast:" then Matches.measure(player,s,"jutsu");break end end
				end
			end
		end
		if s.cup and self.tournament then self.tournament:update(player,s,now) end
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
		-- (B1 lot 2) left before finishing a first duel: an abandon, measured.
		if s.metrics and not s.metrics.duelAt then print(string.format("[NinjaDuelFirst] %s left %.1fs (stage %s)",tostring(player.UserId),os.clock()-(s.metrics.joined or os.clock()),tostring(s.firstStage or s.phase))) end
		self:destroy(s); self.sessions[player]=nil
	end
end
return Matches
