-- (24/11, the CM's series « MY AVATAR VS THE 8 », doc projet
-- claude/cm-serie-my-avatar-vs-the-8-2026-11-24 § 3) challengeFilm: an
-- inspiration's challenge in the street, filmed without touching anything.
-- Studio only (DevHooks, build.py DEBUG_SOURCES): the CM runs it in the game's
-- one place (DEC-052) through the NDDev attribute.
--
--   challengeFilm {kit, street?, rounds?, dare?, with?, avatar?, prodigy?, seed?}
--     kit      the inspiration who challenges (Legion, Lion, Leaf, GentleFist,
--              Sand, Copycat, Mirage, Flashstep)
--     street   a street place's key (HubMap.Streets; MarketLane by default)
--     rounds   rounds to win, 1 to 3 (2)
--     dare     seconds he blocks the street, his line over his head, before
--              the duel (3; 0: at once)
--     with     the avatar's kit (his selected kit by default; a kit he learned)
--     avatar   the AI that plays the avatar: easy, normal, hard (normal)
--     prodigy  the inspiration's AI (Solo.Challenge.level: normal)
--     seed     the avatar's AI seed (another each time by default)
--   challengeFilmResult: where it is, each round's end (who, when), the winner.
--
-- Exactly a player's path: the inspiration stands in the street with his
-- dare (Server/SoloPlay), the avatar walks up, the challenge is accepted
-- (SoloPlay:accept) and fought there (Matches:challengeStart: the dare and
-- the VS card in the intro, the avatar's own body, his learned kit), and the
-- duel decided pays like any challenge (beaten, STUDENT OF THE EIGHT). The
-- only difference: an AI holds the avatar's stick too, like the `autopilot`
-- op, but with a level and its plans (AI:withStrategy) as the inspiration's.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local HubMap=require(Shared.HubMap)
local Solo=require(Shared.Solo)
local BetaRoster=require(Shared.BetaRoster)

local Film={}
Film.__index=Film
Film.DEFAULT={street="MarketLane",rounds=2,dare=3,avatar="normal"}
Film.LEVELS={easy=true,normal=true,hard=true}
-- A duel that never ends is given up after this (s).
Film.MAX_DUEL=300
-- During his dare the avatar walks up this far (studs) from further down the street.
Film.WALK=12

local function streetKeys()
	local keys={}
	for _,s in HubMap.Streets do table.insert(keys,s.key) end
	table.sort(keys)
	return table.concat(keys,", ")
end
local function eight()
	local kits={}
	for kit in Solo.Challenge.lines do table.insert(kits,kit) end
	table.sort(kits)
	return table.concat(kits,", ")
end

-- The spec checked, or nil and what is wrong (in words the CM can act on).
-- `own`: the avatar's selected kit.
function Film.plan(spec,own)
	spec=if type(spec)=="table" then spec else {}
	local D=Film.DEFAULT
	local kit=spec.kit
	if type(kit)~="string" or not Solo.Challenge.lines[kit] then return nil,"kit: one of "..eight() end
	local key=spec.street or D.street
	local site=nil
	for _,s in HubMap.Streets do if s.key==key then site=s end end
	if not site then return nil,"street: one of "..streetKeys() end
	local with=spec.with or own
	if type(with)~="string" or not table.find(BetaRoster,with) then return nil,"the avatar has no kit: choose a starter in the game, or give `with`" end
	local rounds=spec.rounds or D.rounds
	if type(rounds)~="number" or rounds~=math.floor(rounds) or rounds<1 or rounds>3 then return nil,"rounds: 1, 2 or 3" end
	local dare=spec.dare or D.dare
	if type(dare)~="number" or dare<0 or dare>10 then return nil,"dare: 0 to 10 s" end
	local avatar=spec.avatar or D.avatar
	if not Film.LEVELS[avatar] then return nil,"avatar: easy, normal or hard" end
	local prodigy=spec.prodigy or Solo.Challenge.level
	if not Film.LEVELS[prodigy] then return nil,"prodigy: easy, normal or hard" end
	if spec.seed~=nil and type(spec.seed)~="number" then return nil,"seed: a number" end
	return {kit=kit,site=site,with=with,rounds=rounds,dare=dare,avatar=avatar,prodigy=prodigy,seed=spec.seed}
end

-- deps: matches, AI (Server/AI), selected(player) → his kit or nil,
-- learned(player, kit) → whether he may fight with it, seed() → a number.
function Film.new(deps)
	return setmetatable({deps=deps,state="idle",rounds={}},Film)
end

-- Where the avatar starts, before the inspiration: one start of the street
-- (as the duel puts him), facing its centre where the inspiration stands.
function Film.marks(site)
	local origin=HubMap.Origin+site.at
	local axis=site.axis or Vector3.new(0,0,1)
	local half=site.start or math.min(24,site.radius*.7)
	local stand=origin+axis*half+Vector3.new(0,3,0)
	return stand,origin+Vector3.new(0,3,0)
end

function Film:start(player,spec,now)
	local m=self.deps.matches
	if not player then return {ok=false,error="no player"} end
	if not (m and m.solo) then return {ok=false,error="the things to do alone are off (Hub)"} end
	local s=m:session(player)
	self:stop(player)
	if s.phase~="Selection" then m:selection(player) end
	local plan,err=Film.plan(spec,self.deps.selected(player))
	if not plan then return {ok=false,error=err} end
	if not self.deps.learned(player,plan.with) then return {ok=false,error="the avatar has not learned "..plan.with} end
	local root=m.solo:root(player)
	if not root then return {ok=false,error="he is not walking in Konoha (the duel's end brings him back: try again in a few seconds)"} end
	local stand,centre=Film.marks(plan.site)
	-- the avatar further down the street, the inspiration in its middle, face
	-- to face; during the dare he walks up to him, filmed from the front
	-- (26/11, the CM: « la caméra du défi montre l'avatar de dos »; the
	-- player attribute NinjaEncounter, Client/Encounter)
	local axis=(plan.site.axis or Vector3.new(0,0,1))
	local from=if plan.dare>0 then stand+axis*Film.WALK else stand
	local body=root.Parent
	if body and body.PivotTo then body:PivotTo(CFrame.lookAt(from,Vector3.new(centre.X,from.Y,centre.Z))) end
	if plan.dare>0 then pcall(function() player:SetAttribute("NinjaEncounter",centre) end) end
	local c=m.solo:summon(plan.kit,plan.site,stand,now)
	if not c then return {ok=false,error="the inspiration could not come"} end
	self.plan=plan;self.player=player;self.rounds={};self.winner=nil;self.error=nil
	self.state="dare";self.startedAt=now;self.dareUntil=now+plan.dare;self.duelAt=nil;self.endedAt=nil
	self:step(now)
	return {ok=true,kit=plan.kit,with=plan.with,street=plan.site.key,place=plan.site.place,rounds=plan.rounds,
		avatar=plan.avatar,prodigy=plan.prodigy,line=c.line,duelIn=plan.dare,startedAt=now}
end

-- The duel begins: the challenge accepted like a player's, his AI at the stick.
function Film:begin(now)
	local m,player,plan=self.deps.matches,self.player,self.plan
	pcall(function() player:SetAttribute("NinjaEncounter",nil) end)
	local c=m.solo:accept(player,plan.kit,now)
	if not c then self:fail("the challenge could not be accepted (the avatar left the street?)");return end
	if not m:challengeStart(player,plan.with,c,now,plan.prodigy) then self:fail("the duel did not start");return end
	local s=m.sessions[player]
	s.roundsToWin=plan.rounds
	s.autopilot=true;s.scripted=true
	self.session=s;self.combat=s.combat;self.duelAt=s.combat.now
	self.pilot=self.deps.AI.new(s.combat,s.human,plan.seed or self.deps.seed(),plan.avatar):withStrategy()
	-- each round's end, as the duel calls it
	local finish=s.finish
	s.finish=function(winner,loser)
		if s.phase=="Duel" and not s.finishing then
			local wins=(s.wins and s.wins[winner.id] or 0)+1
			table.insert(self.rounds,{round=s.round or 1,winner=if winner==s.human then "avatar" else "prodigy",
				at=s.combat.now,since=s.combat.now-self.duelAt,style=loser and loser.koStyle,decisive=wins>=(s.roundsToWin or 1)})
		end
		return finish(winner,loser)
	end
	self.state="duel"
end

function Film:fail(why)
	self.state="failed";self.error=why
	pcall(function() self.player:SetAttribute("NinjaEncounter",nil) end)
	self:stop(self.player)
end

-- His own stick back to him.
function Film:stop(player)
	local m=self.deps.matches
	local s=player and m and m.sessions[player]
	if s and self.session==s then s.autopilot=nil;s.scripted=nil end
	self.pilot=nil;self.session=nil;self.combat=nil
end

-- Each frame (DevHooks' Heartbeat): the dare's wait, then the avatar's AI.
function Film:step(now)
	if self.state=="dare" then
		if now>=self.dareUntil then self:begin(now) end
		return
	end
	if self.state~="duel" then return end
	local s=self.session
	-- (each round is a new epoch: the duel is its Combat, kept from round to round)
	if not s or s.combat~=self.combat or s.phase~="Duel" then
		-- decided: the result screen, or he left
		local last=self.rounds[#self.rounds]
		self.winner=if last and last.decisive then last.winner else nil
		self.state=if self.winner then "done" else "stopped"
		self.endedAt=now
		self:stop(self.player)
		return
	end
	local c=s.combat
	if c.now-self.duelAt>Film.MAX_DUEL then self:fail("the duel lasted over "..Film.MAX_DUEL.." s");self.deps.matches:selection(self.player);return end
	local intro=s.introUntil and c.now<s.introUntil
	if self.pilot and not intro and not s.finishing then self.pilot:update(c.now) end
end

function Film:result()
	local plan=self.plan
	local last=self.rounds[#self.rounds]
	return {state=self.state,error=self.error,kit=plan and plan.kit,with=plan and plan.with,street=plan and plan.site.key,
		startedAt=self.startedAt,duelAt=self.duelAt,endedAt=self.endedAt,rounds=self.rounds,winner=self.winner,
		-- the decisive blow: when (server time, and seconds into the duel)
		finalBlow=if last and last.decisive then {at=last.at,since=last.since,round=last.round,by=last.winner,style=last.style} else nil}
end

return Film
