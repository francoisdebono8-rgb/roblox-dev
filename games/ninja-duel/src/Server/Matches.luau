local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local BetaRoster=require(Shared.BetaRoster)
local Rules=require(Shared.Rules)
local World=require(script.Parent.World)
local Stage=require(script.Parent.Stage)
local ArenaMeshes=require(script.Parent.ArenaMeshes)
local AvatarBody=require(script.Parent.AvatarBody)
local Progression=require(script.Parent.Progression)
local Masters=require(Shared.Masters)
local Shop=require(Shared.Shop)
local HubMap=require(Shared.HubMap)
local Combat=require(script.Parent.Combat)
local AI=require(script.Parent.AI)
local Tutorial=require(script.Parent.Tutorial)
-- (21/11, DEC-047) the first combat's coach: prompts when their moment comes.
local Coach=require(script.Parent.Coach)
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
-- (DEC-038) Konoha between duels (Server/Hub), when the village is built.
local Hub=require(script.Parent.Hub)
function Matches.hubOn() return Config.Hub~=nil and Config.Hub.Enabled==true and Hub.built==true end
-- A refusal for the screen: the reason a command gave, without the module
-- and line an error carries, in capitals that keep their accents.
Matches.CODE_GAP=2
Matches.CODE_MISSES=8
Matches.CODE_LOCK=60
function Matches.refusal(why)
	local text=string.gsub(tostring(why),"^.-:%d+: ","")
	return require(Shared.Text).upper(text)
end
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
	-- (DEC-038) gated: a player's own kit, its objects earned on his tree only.
	if bracket~=nil then kit,reason=SkillBuilds.admit(bracket,fighterId,nodes,spec.unlocked,{gated=spec.gated==true})
	else kit,reason=SkillBuilds.build(fighterId,nodes,{unlocked=spec.unlocked,gated=spec.gated==true}) end
	if not kit then return false,reason end
	-- (21/11, DEC-045) the ninja's tree: his nature, infusions, mobility and
	-- tools ride on the kit's def (Shared/NinjaTree.def, read by the combat)
	if type(spec.ninja)=="table" then kit.def.Ninja=SkillBuilds.copy(spec.ninja) end
	return true,kit
end
function Matches.new(remote)
	local folder=Instance.new("Folder"); folder.Name="NinjaDuels"; folder.Parent=workspace
	local self=setmetatable({remote=remote,folder=folder,sessions={},nextLane=0,epoch=0},Matches)
	-- Online 1v1 (queue, private codes, two-player duels) on the same sessions.
	self.online=Online.new(self)
	-- (04/11) The Prodigy Tournament against the AI (Server/Tournament).
	self.tournament=require(script.Parent.Tournament).new(self)
	-- (21/11, étape 3 DEV 4, DEC-047) the things to do alone in Konoha
	self.solo=require(script.Parent.SoloPlay).new(self)
	return self
end
-- Each duel owns a stage far from every other one.
function Matches.laneOrigin(lane)
	return Vector3.new((lane-1)*520,0,0)
end
-- (14/11, François: « que notre perso puisse combattre » dans la ville) A duel
-- started at a master's home (his card, the training dummy: `key`) is fought
-- there, in the village, when he really stands there (his walker within reach
-- of the ground). nil: the stadium.
function Matches.villageSite(player,key)
	if not Matches.hubOn() or not (Config.Hub and Config.Hub.VillageDuels==true) or type(key)~="string" then return nil end
	local spot=if key=="Training" then HubMap.Training else HubMap.Masters[key]
	local duel=spot and spot.duel
	if not duel then return nil end
	local centre=HubMap.Origin+duel.at
	local body=Hub.bodies and Hub.bodies[player]
	local character=body and body.character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root or (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(centre.X,0,centre.Z)).Magnitude>duel.radius+50 then return nil end
	return {key=key,origin=centre,radius=duel.radius,place=spot.place,axis=duel.axis,start=duel.start}
end
-- (15/11) Where the two fighters start, from the centre: along the street a
-- place runs (its `axis`), `start` studs away (the stadium's distance, held
-- inside a small place's circle).
function Matches.startOffset(s)
	local site=s and s.site
	local axis=site and site.axis or Vector3.zAxis
	local half=Config.StartDistance
	if site and site.start then half=site.start elseif site and site.radius then half=math.min(half,site.radius*.7) end
	return axis*half
end
-- (15/11) A place of the village holds one fight at a time: a duel at a
-- master's home or a 1v1 in the street (Server/Online). `except`: the session
-- or online duel asking (its own rematch keeps the place).
function Matches:siteFree(key,except)
	if type(key)~="string" then return true end
	for _,s in self.sessions do
		if s~=except and s.site and s.site.key==key and (s.phase=="Duel" or s.phase=="Result") then return false end
	end
	for d in (self.online and self.online.duels) or {} do
		if d~=except and d.site and d.site.key==key and d.phase~="Pick" then return false end
	end
	return true
end
-- (21/11, étape 3 DEV 4, DEC-047: « un duel lancé de partout ») A duel asked
-- while he walks in Konoha (the board's DUELS, anywhere) is fought in the free
-- open place of the village nearest to him, within StreetReach; nil: the
-- stadium (he is not walking, or nothing is free near).
function Matches:nearSite(player,except)
	if not Matches.hubOn() or not (Config.Hub and Config.Hub.VillageDuels==true) then return nil end
	local body=Hub.bodies and Hub.bodies[player]
	local root=body and body.character and body.character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local here=Vector3.new(root.Position.X,0,root.Position.Z)
	local best,bestDistance=nil,Matches.StreetReach
	for _,street in HubMap.Streets or {} do
		local centre=HubMap.Origin+street.at
		local distance=(Vector3.new(centre.X,0,centre.Z)-here).Magnitude
		if distance<bestDistance and self:siteFree(street.key,except) then best,bestDistance=street,distance end
	end
	if not best then return nil end
	return {key=best.key,origin=HubMap.Origin+best.at,radius=best.radius,place=best.place,street=true,axis=best.axis,start=best.start}
end
-- (23/11, passe 1, Server/Thugs) A rogue ninja's racket answered FIGHT: a
-- street duel against the AI at his place (or the nearest free one), with
-- the walker's own kit (a practice with Lee's while he has none). The purse
-- is paid when it is decided. Returns whether it started.
function Matches:thugFight(player,kit,key,level)
	local s=self.sessions[player]
	if not s or s.phase~="Selection" or s.finishing then return false end
	local view=Progression.view(player)
	local own=view and view.selected and Progression.owns(player,view.selected) and view.selected or nil
	s.masterTrial=nil;s.firstStage=nil;s.challenge=nil
	s.thug={kit=kit,key=key}
	if type(level)=="string" and Matches.LEVELS[level] then s.aiLevel=level end
	s.nextSite=self:freeVillageSite(player,key,s) or self:nearSite(player,s)
	local ok=self:start(player,own or "Leaf",kit,own==nil)
	s.nextSite=nil
	if ok==false then s.thug=nil;return false end
	return true
end
function Matches:freeVillageSite(player,key,except)
	local site=Matches.villageSite(player,key)
	if site and not self:siteFree(site.key,except) then return nil end
	return site
end
-- (15/11, François: « des 1v1 vraiment comme ça sur la map », « j'ai bien
-- aimé cette idée de combat rapproché ») Two players walking in Konoha who
-- challenge each other fight where they are: the free open place of the
-- village (HubMap.Streets) nearest to the two of them, within `reach` studs.
-- nil: the stadium (one of them is not walking, or nothing is free near).
Matches.StreetReach=260*(HubMap.Scale or 1)
function Matches:streetSite(players)
	if not Matches.hubOn() or not (Config.Hub and Config.Hub.VillageDuels==true) then return nil end
	local sum,n=Vector3.zero,0
	for _,player in players do
		local body=Hub.bodies and Hub.bodies[player]
		local root=body and body.character and body.character:FindFirstChild("HumanoidRootPart")
		if not root then return nil end
		sum+=root.Position;n+=1
	end
	if n==0 then return nil end
	local middle=sum/n
	local best,bestDistance=nil,Matches.StreetReach
	for _,street in HubMap.Streets or {} do
		local centre=HubMap.Origin+street.at
		local distance=(Vector3.new(centre.X,0,centre.Z)-Vector3.new(middle.X,0,middle.Z)).Magnitude
		if distance<bestDistance and self:siteFree(street.key) then best,bestDistance=street,distance end
	end
	if not best then return nil end
	return {key=best.key,origin=HubMap.Origin+best.at,radius=best.radius,place=best.place,street=true,axis=best.axis,start=best.start}
end
-- (B1 lot 2, DEC-034) What a new player's first minutes look like, measured
-- on the server (Codex's audit §3: time to the first input, the first jutsu,
-- the first finished duel; abandons). One line each in the log
-- ([NinjaDuelFirst]) and, in the published game, Roblox's onboarding funnel
-- (AnalyticsService, in order and once each; skipped quietly where the
-- service is unavailable, as in the tests).
-- (19/11, vague 2 DEV 4) The funnel follows the loop as it is now (Konoha,
-- the inspirations, the outfit, the first duel at the gate, the market, the
-- tree): where new players stop is read from these steps (OUTILLEUR: the
-- Creator Dashboard's export). `input` and `jutsu` stay in the log only.
-- The format (for tools/analytics): step name -> its order, 1 to 9, sent to
-- AnalyticsService:LogOnboardingFunnelStepEvent(player, order, name) once per
-- player and only forward; every step is also one log line
-- `[NinjaDuelFirst] <UserId> <step> <seconds since joined>`. A duel against a
-- player counts like one against the AI (started, hit, duel, won).
Matches.FUNNEL={joined=1,inspiration=2,dressed=3,started=4,hit=5,duel=6,won=7,bought=8,node=9}
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
	-- (23/11, step 5) the test place's record of his visit (Server/TestLog)
	require(script.Parent.TestLog).open(s,os.time(),os.clock())
	-- (DEC-036, beta loop 13/11) The player fights in his own Roblox avatar,
	-- built once in the background; until it is ready, the prodigy's body.
	if Config.AvatarBody and Config.AvatarBody.Enabled==true and type(player)=="userdata" then
		s.avatarBody=true
		pcall(AvatarBody.prepare,player)
	end
	return s
end
-- The duel goes: its bodies, effects and marks. (QA 12/11) The lane's
-- stadium stays for the next duel (Server/Stage); Matches:dropStage takes it.
function Matches:destroy(s)
	-- (15/11) a duel fought in Konoha leaves its walls as they were
	if s.combat then pcall(function() require(script.Parent.WorldReaction).restore(s.combat) end) end
	if s.combat then s.combat:clear() end
	if s.human then AntiCheat.clear(s.human) end
	if s.folder then
		for _,child in s.folder:GetChildren() do
			if child~=s.stage then child:Destroy() end
		end
	end
	s.tutorial=nil; s.coach=nil; s.combat=nil; s.ai=nil; s.human=nil; s.bot=nil
end
-- The lane and its stadium (the player left).
function Matches:dropStage(s)
	if s.folder then s.folder:Destroy() end
	s.folder=nil; s.stage=nil; s.stageRecord=nil
end
function Matches:laneFolder(s)
	if not (s.folder and s.folder.Parent) then
		s.folder=Instance.new("Folder"); s.folder.Name="Duel_"..s.lane; s.folder.Parent=self.folder
		s.stage=nil; s.stageRecord=nil
	end
	return s.folder
end
-- (QA 12/11, gel au BEGIN) A lane with no stadium gets one while its player
-- is on the roster: built away from the world once the arena's meshes are in
-- (a stadium built before falls back to the old part-built decor), then
-- revealed a few pieces a frame (Stage.reveal). The first BEGIN finds it in
-- place; a duel that starts sooner takes the rest at once (Matches:stageFor).
Matches.STAGE_WAIT=20
function Matches:prepareStage(s)
	if s.stage and s.stage.Parent or s.stagePreparing then return end
	s.stagePreparing=true
	task.spawn(function()
		for _=1,Matches.STAGE_WAIT*4 do
			if ArenaMeshes.state~="loading" then break end
			task.wait(.25)
		end
		s.stagePreparing=nil
		if self.sessions[s.owner]~=s or (s.stage and s.stage.Parent) then return end
		local holder=Instance.new("Folder")
		local yard=World.arena(holder,Matches.laneOrigin(s.lane))
		if not yard then holder:Destroy(); return end
		local folder=self:laneFolder(s)
		s.stage=yard; s.stageRecord=nil; s.stageDressed=ArenaMeshes.ready()
		Stage.reveal(yard,folder,function()
			if s.stage==yard then s.stageRecord=Stage.remember(yard) end
		end)
		holder:Destroy()
	end)
end
-- The lane's stadium, whole for a new duel: the one built ahead or the last
-- duel's with its damage undone. Built here only when there is none, it lost
-- a piece, or it was built with the part decor before the meshes came in.
function Matches:stageFor(s)
	local folder=self:laneFolder(s)
	local yard=s.stage
	if yard and yard.Parent==folder and (s.stageDressed or not ArenaMeshes.ready()) then
		Stage.finish(yard)
		if s.stageRecord and Stage.restore(s.stageRecord) then return yard end
	end
	if yard then yard:Destroy() end
	s.stage=World.arena(folder,s.origin)
	s.stageRecord=if s.stage then Stage.remember(s.stage) else nil
	s.stageDressed=ArenaMeshes.ready()
	return s.stage
end
-- (DEC-037) A profile just loaded: the roster learns the player's kits.
function Matches:kitsLoaded(player)
	local s=self.sessions[player]
	if s and s.phase=="Selection" then self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player)}) end
end
function Matches:selection(player,notice)
	local s=self:session(player)
	-- (23/11, step 5) back to the roster in the middle of a duel: left (TestLog)
	if s.phase=="Duel" and not s.logDecided and not s.tutorial then require(script.Parent.TestLog).duel(s,"left",os.clock()) end
	if s.online and self.online then self.online:leave(player,s) end
	self:destroy(s)
	player.Character=nil; s.phase="Selection"; s.epoch+=1
	-- Back on the roster: a tournament in progress ends here.
	s.cup=nil;s.cupMatch=nil;s.spectate=nil;s.autopilot=nil;s.cupPilot=nil
	s.masterTrial=nil
	local view=Progression.view(player)
	self:send(player,{phase="Selection",epoch=s.epoch,notice=notice,kits=view})
	-- (DEC-038) Between duels the player walks Konoha as his own avatar:
	-- through the gate the first time, out of the exam hall after a duel.
	if Matches.hubOn() then
		Hub.badge(player,view)
		Hub.enter(player,s.returnTo or (if s.hubVisited then "hall" else "gate"),Progression.looks(player))
		s.returnTo=nil
		s.hubVisited=true
	end
	-- (Lobby, 04/11) in a duel server the roster is the lobby: back home.
	if self.lobby then self.lobby:onSelection(player) end
	self:prepareStage(s)
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
	-- (DEC-038) A learned kit fights with the player's own tree (his build,
	-- the objects he earned); a kit he only tries is the prodigy's whole kit.
	if options==nil and not s.spectate and not s.online then
		local spec=Progression.kitSpec(player,playerId)
		if spec then options={player=spec} end
	end
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
	s.dare=nil
	-- (DEC-038) The walk in Konoha ends: the duel's body takes over.
	if Matches.hubOn() then Hub.leave(player) end
	if self.solo then self.solo:leave(player) end
	s.playerId=playerId; s.botId=botId; s.winner=nil; s.phase="Duel"; s.origin=Matches.laneOrigin(s.lane)
	s.logDecided=nil
	s.options=options
	-- (19/11, funnel) his first duel begins (a watched match is not his)
	if not s.spectate then Matches.measure(player,s,"started") end
	-- (14/11) A duel at a master's home: in the village, no stadium.
	local site=s.nextSite;s.nextSite=nil
	s.site=site;s.radius=site and site.radius or nil
	if site then
		s.origin=site.origin
		local axis=site.axis or Vector3.zAxis
		s.returnTo={at=site.origin-HubMap.Origin+axis*site.radius*.5,face=-axis}
	else
		-- (QA 12/11) The lane's stadium is the one already in the world, its
		-- last duel's damage undone: only the two bodies are new at BEGIN.
		self:stageFor(s)
	end
	s.effects=Instance.new("Folder"); s.effects.Name="Effects"; s.effects.Parent=s.folder
	s.combat=Combat.new(s); s.combat.now=workspace:GetServerTimeNow()
	local function actor(id,def,position,look,kit)
		local cf=CFrame.lookAt(position,look)
		-- (DEC-036) The player's own Roblox avatar wearing the kit, when the
		-- session asks for it and the avatar is built (Server/AvatarBody);
		-- otherwise the prodigy's own body.
		local model,hum,root,joints
		-- (A tournament match he only watches is two prodigies.)
		if id=="PlayerFighter" and s.avatarBody and not s.spectate then model,hum,root,joints=AvatarBody.rig(player,s.folder,def,Fighters[def],cf,id,Progression.looks(player)) end
		if not model then model,hum,root,joints=World.rig(s.folder,Fighters[def],cf,id) end
		return s.combat:add(id,model,hum,root,joints,def,kit)
	end
	local off,up=Matches.startOffset(s),Vector3.new(0,3,0)
	s.human=actor("PlayerFighter",playerId,s.origin+up+off,s.origin+up-off,playerKit)
	s.bot=actor("AIFighter",botId,s.origin+up-off,s.origin+up+off,botKit)
	s.human.target=s.bot; s.bot.target=s.human; s.human.locked=true; s.bot.locked=true
	player.Character=s.human.model
	-- (13/11) The looks his own ninja wears (Shared/Shop): his weapons' skins.
	if not s.spectate then s.human.looks=Progression.looks(player) end
	-- (Beta loop) a learned kit he fights with is his roster's pick next time.
	if not s.spectate then Progression.remember(player,playerId) end
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+ s.epoch,Matches.aiLevel(s)):withStrategy()
	s.finishing=false
	-- Tournament rounds: first to two (one in training).
	s.round=1;s.wins={PlayerFighter=0,AIFighter=0};s.roundsToWin=if training or s.firstFight then 1 else Config.RoundsToWin
	s.finish=function(winner,_loser)
		self:roundOver(s,winner,function() self:snapshot(player,s) end,function() self:nextRound(player,s) end)
	end
	s.tutorial=nil; if training then Tutorial.new(s,if s.firstStage=="intro" then "first" else nil) end
	-- (21/11, DEC-047) the first combat: one real round against the novice,
	-- the coach's prompts when their moment comes (Server/Coach).
	s.coach=nil; if s.firstFight and not training then Coach.new(s,s.combat.now) end
	-- Tournament framing: both fighters are shown before the round begins.
	s.introUntil=if training then nil else s.combat.now+2.6
	local epoch=s.epoch
	s.human.hum.Died:Connect(function() if s.epoch==epoch and s.phase=="Duel" then s.human.health=0; s.human.state="Defeated"; s.finish(s.bot,s.human) end end)
	s.bot.hum.Died:Connect(function() if s.epoch==epoch and s.phase=="Duel" then s.bot.health=0; s.bot.state="Defeated"; s.finish(s.human,s.bot) end end)
	self:snapshot(player,s)
	return true
end
-- (24/11, the CM's series MY AVATAR VS THE 8, § 3.1) An inspiration's
-- challenge in the street becomes a moment: the duel's intro first gives his
-- dare (the DESIGN's manga bubble, `line` s), then the VS card with both heads
-- (`vs` s), then BEGIN (Config.IntroBegin). The snapshot's `dare` says it.
Matches.Dare={line=1.6,vs=1.5}
-- The challenge `c` accepted (Server/SoloPlay): his duel against the
-- inspiration, where the inspiration stood. `kit`: the learned kit he fights
-- with. `level`: the inspiration's AI (Solo.Challenge.level unless a film
-- asks). Returns whether it started.
function Matches:challengeStart(player,kit,c,now,level)
	local s=self:session(player)
	s.masterTrial=nil;s.firstStage=nil;s.firstFight=nil;s.coach=nil;s.challenge=c.kit
	s.aiLevel=if Matches.LEVELS[level or ""] then level else require(Shared.Solo).Challenge.level
	s.nextSite={key=c.site.key,origin=HubMap.Origin+c.site.at,radius=c.site.radius,place=c.site.place,street=true,axis=c.site.axis,start=c.site.start}
	local ok=self:start(player,kit,c.kit,false)
	s.nextSite=nil
	if not ok then s.challenge=nil;self.solo:challengeEnded(player,false,now);return false end
	local D=Matches.Dare
	s.dare={kit=c.kit,line=c.line,lineFor=D.line,vsFor=D.vs,at=s.combat.now}
	s.introUntil=s.combat.now+D.line+D.vs+(Config.IntroBegin or .75)
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
	-- (22/11, the CM's titles COMEBACK KID and UNTOUCHED) a round of note won
	-- in a real duel (not practice, not the first fight)
	if s.human and winner==s.human and s.owner and not s.tutorial and not s.firstFight and not s.online then
		local max=s.human.def.Health or 100
		if s.human.health<=max*.1 then pcall(Progression.solo,s.owner,"feat",{feat="comeback"})
		elseif s.human.health>=max-.01 then pcall(Progression.solo,s.owner,"feat",{feat="untouched"}) end
	end
	-- (21/11, DEC-047) the first combat is over: the next duel is an ordinary one.
	-- (22/11, the OUTILLEUR's robot) the novice and his coach are for the
	-- first fight only: its rematch, and any duel after it, is at easy
	if decided and s.firstFight then s.firstFight=nil;s.coach=nil;if s.aiLevel=="first" then s.aiLevel="easy" end end
	if decided and not s.tutorial and not s.online and s.owner then
		Matches.measure(s.owner,s,"duel")
		if s.human and winner==s.human then Matches.measure(s.owner,s,"won") end
		require(script.Parent.TestLog).duel(s,if s.human and winner==s.human then "won" else "lost")
	end
	if decided then s.logDecided=true end
	-- (DEC-037) The masters' path: mastery for the kit fought with; a master's
	-- duel won teaches his kit. Shown on the result screen (snapshot `progress`).
	if decided and not s.online and s.owner and s.human then
		local won=winner==s.human
		local gained=Progression.duelEnded(s.owner,s,won)
		s.progress={mastery=gained and gained.mastery,gained=gained~=nil and gained.amount~=nil,amount=gained and gained.amount,fighter=s.playerId,need=Masters.Need,
			points=gained and gained.points,ryo=gained and gained.ryo,firstWin=gained and gained.firstWin,
			-- (19/11, vague 2 DEV 5) the day's quests done, the days in a row
			daily=gained and gained.daily}
		if s.masterTrial and won then
			local ok=Progression.learnFromMaster(s.owner,s.masterTrial)
			if ok then s.progress.learned=s.masterTrial end
		end
		-- (23/11, passe 1) a rogue's racket fought: his purse, or some of ours
		if s.thug then
			local okT,purse=pcall(require(script.Parent.Thugs).ended,s.owner,won)
			s.progress.thug={kit=s.thug.kit,won=won,ryo=okT and purse or 0}
			s.thug=nil
		end
		-- (21/11, DEC-047) an inspiration's challenge in the street, decided
		if s.challenge and self.solo then
			local paid=self.solo:challengeEnded(s.owner,won,s.combat and s.combat.now or 0)
			s.progress.challenge={kit=s.challenge,won=won,amount=paid and paid.amount}
			s.challenge=nil
		end
		-- (19/11, DEV 6) what this duel brought closer: the next node, the
		-- next tier, the inspirations that will want to meet him
		s.progress.ahead=Progression.ahead(s.owner,s.playerId)
	end
	-- (DEC-040) Against another player: each present seat's kit earns its
	-- mastery (Progression.versusEnded), shown on his own result screen.
	if decided and s.online and s.seats and not s.forfeit then
		-- (20/11, DEC-043) the ranked ladder: every duel between two players
		-- counts, both ratings move
		local ranked={}
		local w,l=nil,nil
		for _,seat in s.seats do
			if seat.player then if winner==seat.actor then w=seat.player else l=seat.player end end
		end
		if w and l then ranked=Progression.rankedDuel(w,l) end
		for _,seat in s.seats do
			-- (19/11, OUTILLEUR's two-player test: « le duel en ligne ne compte
			-- pas dans l'entonnoir ») a duel against a player counts as one
			-- against the AI: decided, and won
			if seat.present and seat.player and seat.session then
				Matches.measure(seat.player,seat.session,"duel")
				if winner==seat.actor then Matches.measure(seat.player,seat.session,"won") end
				require(script.Parent.TestLog).duel(seat.session,if winner==seat.actor then "won" else "lost")
				seat.session.logDecided=true
			end
			if seat.present and seat.actor and seat.player then
				local used=0
				for _ in seat.actor.usedJutsu or {} do used+=1 end
				local won=winner==seat.actor
				local lost=0
				for id,n in s.wins do if id~=seat.actor.id then lost+=n end end
				local gained=Progression.versusEnded(seat.player,seat.fighter,won,used,lost)
				seat.progress={mastery=gained and gained.mastery,gained=gained~=nil and gained.amount~=nil,amount=gained and gained.amount,fighter=seat.fighter,need=Masters.Need,
					points=gained and gained.points,ryo=gained and gained.ryo,firstWin=gained and gained.firstWin,
					ahead=Progression.ahead(seat.player,seat.fighter),daily=gained and gained.daily,
					ranked=ranked[seat.player],merit=gained and gained.merit}
			end
		end
	end
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
Matches.LEVELS={easy=true,normal=true,hard=true,first=true}
function Matches.aiLevel(s)
	-- (DEC-037) A master's duel: the prodigy at his level.
	if s.masterTrial then return Masters.DuelLevel end
	if s.cup then
		if s.spectate then return "normal" end
		local m=s.cup.match or 1
		return if m<=4 then "easy" elseif m<=6 then "normal" else "hard"
	end
	return if Matches.LEVELS[s.aiLevel or ""] then s.aiLevel else "easy"
end
function Matches:nextRound(player,s)
	self:resetRound(s)
	s.ai=AI.new(s.combat,s.bot,player.UserId%100000+s.epoch,Matches.aiLevel(s)):withStrategy()
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
	local off=Matches.startOffset(s)
	c:relocate(first,s.origin+Vector3.new(0,3,0)+off);c:relocate(second,s.origin+Vector3.new(0,3,0)-off)
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
			ready[i]={id=spec.Id,name=spec.Name,card=spec.CardName,cost=spec.Cost,remaining=math.max(0,(a.cooldowns[spec.Id] or 0)-now),requires=spec.Requires,condition=not spec.Requires or (spec.Requires=="Anchor" and Techniques.sealOf(s.combat,a,now)~=nil) or (spec.Requires=="Target" and s.combat:targetValid(a,a.target,spec.Range,0.35))}
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
			-- (21/11, DEC-047) the AI's plan of the fight (Server/AI.Strategy): "pressure",
			-- "distance" or "trap", and how long ago it changed
			strategy=a.strategy,strategyAge=if a.strategyAt then s.combat.now-a.strategyAt else nil,
			cue=if a.cueUntil>s.combat.now then a.cue else "",quiet=if (a.quietUntil or 0)>s.combat.now and not (s.autopilot or s.spectate) then a.quiet else nil,dodge=math.max(0,a.dodgeUntil-s.combat.now),read=math.max(0,a.readUntil-s.combat.now),
			speed=a.locomotion.Magnitude,airborne=a.airborne,sprinting=a.model:GetAttribute("MovementSprinting")==true,
			landStrong=a.model:GetAttribute("MovementHardLanding")==true,pursuit=math.max(0,a.pursuitUntil-s.combat.now),combo=a.combo,
			subCharges=a.subCharges,chakraLoad=if a.chakraLoad and a.chakraLoad.untilTime>s.combat.now then a.chakraLoad.nature else nil,infused=(a.pending and a.pending.chakraFlow) or (if a.state=="Recovery" and a.flowShown and a.flowShown.serial==a.attackSerial then a.flowShown.nature else nil),wall=a.wall~=nil,wallMode=a.wall and a.wall.mode or nil,wallSide=a.wall and a.wall.side or nil,reaction=a.reaction,guardImpact=math.max(0,(a.guardImpact or 0)-s.combat.now),attackName=a.attackName,attackElapsed=s.combat.now-(a.attackStarted or 0),whiffed=if a.state=="Recovery" and a.attackWhiffed then true else nil,airHold=a.airHold,impactSerial=a.impactSerial or 0,impactHeavy=a.impactHeavy,impactStyle=a.impactStyle,
			hitFrom=a.hitFrom,hitAngle=a.hitAngle,hitStrength=a.hitStrength or 0,hitZone=a.hitZone,hitKind=a.hitKind,hitTwist=a.hitTwist,groundPose=a.groundPose,groundSide=a.groundSide,koStyle=a.koStyle,koAirborne=a.koAirborne,koFlying=a.koFlight~=nil,reactionElapsed=math.max(0,s.combat.now-(a.reactionStartedAt or s.combat.now)),
			-- (Audit 29/10) Only the counters the client reads: every event count
			-- (80+ names, never reset) went out 30 times a second.
			events=if a.events then {Parry=a.events.Parry,ReadSlip=a.events.ReadSlip,Draw=a.events.Draw,Awaken=a.events.Awaken,AirJump=a.events.AirJump} else nil,velocity=if a.state=="Dodging" then (a.dodgeDirection or Vector3.zero)*35 else a.root.AssemblyLinearVelocity,
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
			counter=math.max(0,(a.counterUntil or 0)-now),warpSerial=a.warpSerial or 0,travel=s.combat:travelView(a),
			shield=a.shieldCharges or 0,shieldMax=a.def.SandShield and a.def.SandShield.Charges or 0,bound=a.reaction=="Bound",boundKind=if a.reaction=="Bound" then a.boundKind else nil,
			awaken=math.max(0,(a.awakenUntil or 0)-now),gate=if (a.awakenUntil or 0)>now then a.gateOpen else nil,sight=if (a.sightUntil or 0)>now then true else nil,
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
			-- (13/11) the looks of the player's own ninja (Shared/Shop).
			looks=a.looks,
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
			copy=Copy.view(s.combat,a),
			-- (06/11) Soaked by the water (Interactions): lightning runs through him.
			wet=require(script.Parent.Interactions).wet(s.combat,a),
			-- (21/11, DEC-045) his ninja's tree in the duel (NinjaArts.view): nature,
			-- infused kunai and blade, the tag ready, the smoke, the second jump.
			ninja=require(script.Parent.NinjaArts).view(s.combat,a)}
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
			mark=p.mark,normal=p.normal,expires=p.expires,charged=p.charged,holds=p.holds and p.holds.id,anchored=p.anchored,hidden=p.hidden,
			-- (21/11, DEC-045) the ninja's nature it carries, the explosive tag on it (NinjaArts).
			ninja=p.ninja,tag=p.tag})
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
	return {phase=s.phase,epoch=s.epoch,first=s.firstStage,winner=s.winner and (if s.winner==mine.id then "PlayerFighter" else "AIFighter"),tutorial=Tutorial.snapshot(s) or Coach.snapshot(s),origin=s.origin,human=data(mine),bot=data(theirs),impacts=feed,impactSerial=s.combat.impactSerial or 0,
		-- Bodies that are not fighters (Naruto's shadow clones), drawn by Client/BodyViews.
		bodies=Bodies.view(s.combat),
		-- zones: wind lanes and updrafts (Zones.snapshot), drawn per kind by the client.
		projectiles=projectiles,hazards=hazards,zones=Zones.snapshot(s.combat,now),serverNow=now,intro=math.max(0,(s.introUntil or 0)-now),ko=s.finishing==true,
		round=s.round or 1,wins={human=wins[mine.id] or 0,bot=wins[theirs.id] or 0},roundsToWin=s.roundsToWin or 1,matchPoint=s.matchPoint,
		-- (Tournament) the bracket in play, and a match the player only watches.
		cup=if s.cup and self.tournament then self.tournament:view(s.cup) else nil,spectate=s.spectate==true,
		-- (DEC-037) the masters' path: mastery gained, a kit learned, the master being fought.
		progress=s.progress,master=s.masterTrial,
		-- (15/11) a duel in the village: where it is fought (the banner says it)
		site=if s.site then {key=s.site.key,place=s.site.place,radius=s.site.radius,street=s.site.street} else nil,
		-- (24/11) an inspiration's challenge: his dare, then the VS card, during
		-- the first round's intro (Matches.challengeStart); `at` server time
		dare=if s.dare and (s.round or 1)==1 and (s.introUntil or 0)>now then s.dare else nil}
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
	-- (23/11, passe 1) a rogue's racket answered: pay, run or fight (Server/Thugs)
	if action=="Racket" then
		if type(payload.id)=="string" and type(payload.choice)=="string" then pcall(require(script.Parent.Thugs).answer,player,payload.id,payload.choice) end
		return
	end
	-- (23/11, step 5) the screen the client is on (the test place's record)
	if action=="Screen" then require(script.Parent.TestLog).clientScreen(s,payload.name);return end
	-- (23/11, step 5, DEC-049) REPORT A PROBLEM (the test place), any phase
	if action=="Report" then
		local ok,why=pcall(function() require(script.Parent.Reports).record(player,payload.text,payload.where,s) end)
		if not ok then warn("[NinjaDuel] report: "..tostring(why)) end
		return
	end
	if payload.epoch~=s.epoch then return end
	if s.metrics and not s.metrics.inputAt and (action~="Move" or (typeof(payload.direction)=="Vector3" and payload.direction.Magnitude>.5)) then Matches.measure(player,s,"input") end
	-- The online flow owns every request of a player who is in it.
	if self.online and self.online:request(player,s,action,payload,clock) then return end
	-- (B1) held on the first minute: straight to its duel, not the roster.
	if action=="TutorialSkip" and s.tutorial and s.tutorial.first then s.tutorial.done=true;return end
	if action=="TutorialSkip" and s.coach then s.coach=nil;return end
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
		-- (21/11, DEC-047; François: « trop long et ne m'apprend pas à jouer »)
		-- No drills on a waiting partner first: straight into one real round
		-- against the novice, with the coach's prompts at the right moments.
		s.lastLifecycle=clock;s.aiLevel="first";s.firstStage="duel";s.firstFight=true
		s.nextSite=self:freeVillageSite(player,payload.here,s)
		if not self:start(player,payload.player,rival,false) then s.firstStage=nil;s.firstFight=nil end
		s.nextSite=nil
		return
	end
	-- (DEC-037) The masters' path from the roster: the starter, the kit for the
	-- next duels, a master's duel, a kit bought.
	-- (DEC-038) The tree of a learned kit: a node bought with its points, an
	-- unlocked node turned on or off. Between duels only.
	-- (21/11, DEC-045) The ninja's tree: a node learned with the ninja points,
	-- a learned node turned on or off (a nature: the other one goes off).
	if action=="NinjaLearn" or action=="NinjaSet" then
		if clock-s.lastLifecycle<0.25 or s.phase~="Selection" or not Progression.enabled() then return end
		if type(payload.node)~="string" or #payload.node>32 then return end
		s.lastLifecycle=clock
		local ok,why
		if action=="NinjaLearn" then ok,why=Progression.ninjaLearn(player,payload.node)
		else ok,why=Progression.ninjaSet(player,payload.node,payload.on==true) end
		self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player),notice=if ok then nil else Matches.refusal(why)})
		return
	end
	if action=="LearnNode" or action=="SetNode" then
		if clock-s.lastLifecycle<0.25 or s.phase~="Selection" or not Progression.enabled() then return end
		if type(payload.player)~="string" or type(payload.node)~="string" or #payload.node>32 then return end
		s.lastLifecycle=clock
		local ok,why
		if action=="LearnNode" then ok,why=Progression.learnNode(player,payload.player,payload.node)
			if ok then Matches.measure(player,s,"node") end
		else ok,why=Progression.setNode(player,payload.player,payload.node,payload.on==true) end
		self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player),notice=if ok then nil else Matches.refusal(why)})
		return
	end
	-- (13/11) The shop: a look for Ryō, a look worn, a Robux offer prompted
	-- (a look, a pack of Ryō, a pass). Between duels only.
	-- (19/11) A code typed in the shop (Shared/Codes): one try every 2 s, and
	-- after 8 wrong ones in a row a minute's wait (no guessing in bulk).
	if action=="RedeemCode" then
		if s.phase~="Selection" or not Progression.enabled() or type(payload.code)~="string" or #payload.code>40 then return end
		if clock-(s.lastCode or -10)<Matches.CODE_GAP or clock<(s.codeLock or 0) then return end
		s.lastCode=clock
		local ok,result=Progression.redeemCode(player,payload.code)
		local notice
		if ok then
			s.codeMisses=0
			notice=require(Shared.Codes).thanks(result,Shop)
		else
			s.codeMisses=(s.codeMisses or 0)+1
			if s.codeMisses>=Matches.CODE_MISSES then s.codeMisses=0;s.codeLock=clock+Matches.CODE_LOCK end
			notice=Matches.refusal(result)
		end
		self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player),notice=notice,codeOk=ok==true})
		return
	end
	if action=="BuyItem" or action=="EquipItem" or action=="BuyRobux" or action=="BuyPass" then
		if clock-s.lastLifecycle<0.25 or s.phase~="Selection" or not Progression.enabled() then return end
		s.lastLifecycle=clock
		local ok,why=true,nil
		if action=="BuyItem" and type(payload.item)=="string" then ok,why=Progression.buyItem(player,payload.item)
			if ok and Matches.hubOn() then Hub.restyle(player,Progression.looks(player)) end
			if ok then Matches.measure(player,s,"bought") end
		elseif action=="EquipItem" and type(payload.item)=="string" then ok,why=Progression.equipItem(player,payload.item)
			if ok and Matches.hubOn() then Hub.restyle(player,Progression.looks(player)) end
			-- (19/11, funnel) dressed: a top or an inspiration's outfit on
			local view=if ok then Progression.view(player) else nil
			if view and Shop.dressed(view.style) then Matches.measure(player,s,"dressed") end
		elseif action=="BuyRobux" and type(payload.product)=="number" and payload.product>0 then
			local known=Progression.productFor(payload.product)
			if known then pcall(function() game:GetService("MarketplaceService"):PromptProductPurchase(player,payload.product) end) end
			return
		elseif action=="BuyPass" and type(payload.pass)=="string" then
			local id=if payload.pass=="MasteryPass" then (Config.Progression and Config.Progression.MasteryPass) else ((Config.Shop and Config.Shop.Passes or {})[payload.pass])
			if type(id)=="number" and id>0 then pcall(function() game:GetService("MarketplaceService"):PromptGamePassPurchase(player,id) end) end
			return
		end
		self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player),notice=if ok then nil else Matches.refusal(why)})
		return
	end
	if action=="ChooseStarter" or action=="SelectKit" or action=="MasterTrial" or action=="BuyKit" then
		if clock-s.lastLifecycle<0.8 or s.phase~="Selection" or not Progression.enabled() then return end
		if type(payload.player)~="string" then return end
		s.lastLifecycle=clock
		if action=="ChooseStarter" or action=="SelectKit" then
			local ok,why
			if action=="ChooseStarter" then ok,why=Progression.chooseStarter(player,payload.player) else ok,why=Progression.select(player,payload.player) end
			if ok and action=="ChooseStarter" then Matches.measure(player,s,"inspiration") end
			local view=Progression.view(player)
			self:send(player,{phase="Selection",epoch=s.epoch,kits=view,notice=if ok then nil else Matches.refusal(why)})
			-- (14/11) the kit over his head in Konoha follows his choice
			if ok and Matches.hubOn() then Hub.badge(player,view) end
		elseif action=="MasterTrial" then
			local master=payload.master
			local h=Progression.handles[player]
			local can,why=Masters.canLearn(h and h.data.kits,master)
			if not can or not Progression.owns(player,payload.player) then
				self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player),notice=Matches.refusal(if can then "Kit not learned" else why)})
				return
			end
			s.masterTrial=master;s.firstStage=nil
			s.nextSite=self:freeVillageSite(player,payload.here,s)
			if not self:start(player,payload.player,master,false) then s.masterTrial=nil end
			s.nextSite=nil
		elseif action=="BuyKit" then
			local product=(Config.Progression and Config.Progression.Products or {})[payload.player]
			if product and not Progression.owns(player,payload.player) then
				pcall(function() game:GetService("MarketplaceService"):PromptProductPurchase(player,product) end)
			end
		end
		return
	end
	-- (21/11, étape 3 DEV 4, DEC-047) the things to do alone in Konoha
	-- (Server/SoloPlay): the rooftop race, the kunai targets (a throw
	-- `toward` a direction), given up; the inspiration's challenge accepted.
	if action=="SoloRace" or action=="SoloTargets" or action=="SoloQuit" or action=="SoloThrow" or action=="SoloChallenge" then
		if s.phase~="Selection" or not Matches.hubOn() or not self.solo then return end
		local now=workspace:GetServerTimeNow()
		if action=="SoloThrow" then self.solo:throw(player,payload.toward,now);return end
		if action=="SoloQuit" then self.solo:stop(player,"quit");return end
		if clock-s.lastLifecycle<0.8 then return end
		s.lastLifecycle=clock
		if action=="SoloRace" or action=="SoloTargets" then
			if self.solo.runs[player] then self.solo:stop(player,nil) end
			self.solo:start(player,if action=="SoloRace" then "race" else "targets",now)
			return
		end
		if type(payload.kit)~="string" then return end
		local h=Progression.handles[player]
		local kit=h and h.data.kits.selected
		if not (kit and Progression.owns(player,kit)) then return end
		local c=self.solo:accept(player,payload.kit,now)
		if not c then return end
		self:challengeStart(player,kit,c,now)
		return
	end
	if action=="Start" or action=="Tutorial" or action=="Rematch" or action=="Selection" then
		if clock-s.lastLifecycle<0.8 then return end
		if (action=="Start" or action=="Tutorial") and s.phase=="Selection" then
			if type(payload.player)~="string" or type(payload.bot)~="string" then return end
			-- (DEC-037) A duel that counts takes a learned kit; practice takes any.
			if action=="Start" and not Progression.owns(player,payload.player) then
				self:send(player,{phase="Selection",epoch=s.epoch,kits=Progression.view(player),notice="KIT NOT LEARNED YET — TRY IT IN PRACTICE"})
				return
			end
			s.masterTrial=nil
			s.lastLifecycle=clock;s.firstStage=nil
			if type(payload.level)=="string" and Matches.LEVELS[payload.level] then s.aiLevel=payload.level end
			s.nextSite=self:freeVillageSite(player,payload.here,s)
			-- (21/11, DEC-047) asked anywhere in Konoha: fought near him
			if not s.nextSite and payload.here==nil then s.nextSite=self:nearSite(player,s) end
			self:start(player,payload.player,payload.bot,action=="Tutorial")
			s.nextSite=nil
		elseif action=="Rematch" and (s.phase=="Result" or s.finishing) then
			s.lastLifecycle=clock;s.firstStage=nil
			-- (14/11) a rematch at a master's home stays there
			s.nextSite=s.site;s.returnTo=nil
			self:start(player,s.playerId,s.botId,s.tutorial~=nil,s.options)
			s.nextSite=nil
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
	-- (DEC-037) The jutsu this duel saw (mastery counts each different one once).
	if ok and type(action)=="string" and (string.sub(action,1,9)=="Technique" or string.sub(action,1,4)=="Seal") then
		actor.usedJutsu=actor.usedJutsu or {};actor.usedJutsu[action]=true
	end
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
				if s.tutorial then
					local passed=s.tutorial.passed or 0
					Tutorial.update(s,now,dt)
					-- (21/11, DEC-047) a step of his kit done with the dummy pays
					if s.tutorial and (s.tutorial.passed or 0)>passed and not s.tutorial.first and s.owner then Progression.solo(s.owner,"step") end
				elseif not s.botFrozen and not intro and not s.finishing then s.ai:update(now) end
				if s.coach and not intro and not s.finishing then Coach.update(s,now,dt) end
				-- (B1 lot 2) the first minute's last prompt done: its real duel.
				if s.tutorial and s.tutorial.done and s.firstStage=="intro" then
					s.firstStage="duel";s.aiLevel="easy";s.nextSite=s.site;self:start(player,s.playerId,s.botId,false);s.nextSite=nil
				end
				-- (19/11, funnel) his first blow that lands: the other body hurt
				if s.metrics and not s.metrics.hitAt and s.bot and s.bot.def and s.bot.health and s.bot.health<s.bot.def.Health then
					Matches.measure(player,s,"hit")
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
	if self.solo then self.solo:update(now) end
	-- (21/11, DEC-047) the open 1v1: a ring round every duel fought in the
	-- village; the passers-by watch from outside it (Hub.duelRings)
	if Matches.hubOn() and now>=(self.nextRings or 0) then
		self.nextRings=now+.25
		pcall(Hub.duelRings,self:activeSites())
	end
end
-- The places of the village a duel is fought in now: {{key, origin, radius}}.
function Matches:activeSites()
	local out={}
	for _,s in self.sessions do
		if s.site and (s.phase=="Duel" or s.phase=="Result") then table.insert(out,{key=s.site.key,origin=s.site.origin,radius=s.site.radius}) end
	end
	for d in (self.online and self.online.duels) or {} do
		if d.site and d.phase~="Pick" then table.insert(out,{key=d.site.key,origin=d.site.origin,radius=d.site.radius}) end
	end
	return out
end
function Matches:remove(player)
	local s=self.sessions[player]
	if s then
		-- A disconnect forfeits an online fight and frees queue entries and codes.
		if s.online and self.online then self.online:leave(player,s) end
		-- (B1 lot 2) left before finishing a first duel: an abandon, measured.
		if s.metrics and not s.metrics.duelAt then print(string.format("[NinjaDuelFirst] %s left %.1fs (stage %s)",tostring(player.UserId),os.clock()-(s.metrics.joined or os.clock()),tostring(s.firstStage or s.phase))) end
		-- (23/11, step 5) the test place's record, written as he leaves
		local TestLog=require(script.Parent.TestLog)
		if s.phase=="Duel" and not s.logDecided and not s.tutorial then TestLog.duel(s,"left",os.clock()) end
		pcall(TestLog.write,player,s)
		self:destroy(s); self:dropStage(s); self.sessions[player]=nil
		AvatarBody.forget(player)
		Hub.forget(player)
	end
	if self.solo then self.solo:leave(player);self.solo.runs[player]=nil end
end
return Matches
