-- (27/11, the CM's series « YOUR AVATAR × NARUTO SCENES », doc projet
-- claude/cm-concept-scenes-naruto-2026-11-27, INBOX-CM-SCENES-20261127)
-- sceneFilm: a WRITTEN scene in a street of Konoha. The avatar (the player's
-- own Roblox body, wearing a prodigy's kit, all its techniques his for the
-- shoot) against the prodigy of the scene; the order of the blows is the
-- script's, but every blow goes through the duel's real code (the same
-- presses as a player's keys), so what comes out of it (the sand that
-- blocks by itself, the weights that crater the floor, the Lotus) is the
-- game's own. Studio only (DevHooks, build.py DEBUG_SOURCES): the CM runs it
-- in the game's one place (DEC-052) through the NDDev attribute.
--
--   sceneFilm {preset?, street?, avatar={kit, nodes?}, foe={kit},
--              beats={{t, who, act, toward?, hold?, chakra?}, ...},
--              gap?, intro?, koAtEnd?, koAt?, flash?, take?, tail?}
--     preset   a scene written here (Scene.PRESETS: LeeWeights), its fields
--              taken unless the spec gives them
--     street   a street place's key (HubMap.Streets; Plaza by default)
--     avatar   kit: the prodigy's kit he wears; nodes: tree nodes added to
--              the whole kit (e.g. HeavyDrop, the weights' crater)
--     foe      kit: the prodigy of the scene, his whole kit; his automatic
--              defences (Gaara's sand) stay his
--     beats    t: seconds from the scene's start; who: avatar or foe; act:
--              light, heavy, leap, dash, tool, guard, unguard, grab,
--              substitute, ultimate, awaken, a chakra move (chakra=true, or
--              its name: AfterImage, Lotus, Rotation...), a technique by its
--              Id (RemoveWeights, PrimaryLotus...), a seal jutsu by its Id
--              (CloneAmbush...), walk / run (hold s), stop, refill (chakra,
--              cooldowns and sand, not health); toward: foe (default), away,
--              left, right, none, or a direction; hold: s the key or the
--              stick stays held
--     gap      studs between them at the start, along the street (8)
--     intro    the duel's VS intro first (false: the scene starts at once)
--     koAtEnd  the foe falls to the last beat's blow (true): until then
--              neither can fall (a body under half its health is made whole
--              again); from the last beat the foe has 1 health, and if he
--              still stands koWithin s later, he is knocked out
--     koAt     when the foe's next blow knocks him out (s), instead of the
--              last beat
--     flash    the sync flash at t = 0 (true): the screen goes white 0.15 s
--     take     the take's number, for the cameras (NDTake)
--   sceneFilmResult: where it is, when each beat was pressed (and whether
--   the duel took it), each blow that landed and each the sand stopped, and
--   the K.O. Times are the duel's clock (server time) and seconds from t = 0;
--   `stalls`: the server froze then (a capture, a hitch), the scene waited.
--
-- The duel is a real one (Matches:start, one round, the street's ring), but
-- scripted: the client's stick is ignored and the foe's AI is off. It never
-- counts for his profile (Progression.duelEnded: s.scripted).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local HubMap=require(Shared.HubMap)
local Fighters=require(Shared.Fighters)
local SealJutsu=require(Shared.SealJutsu)
local ChakraMoves=require(Shared.ChakraMoves)
local BetaRoster=require(Shared.BetaRoster)

local Scene={}
Scene.__index=Scene
Scene.DEFAULT={street="Plaza",gap=8,seals=.3,tail=3,koWithin=2.5,lead=.6}
-- A scene's last beat at most this far in (s).
Scene.MAX_T=60
Scene.WHO={avatar="avatar",foe="foe"}
-- The duel's keys, as a player presses them.
Scene.PLAIN={light="Attack",heavy="Heavy",leap="Jump",jump="Jump",dash="Dodge",tool="Tool",guard="Guard",unguard="GuardOff",
	grab="Grab",substitute="Substitute",ultimate="Ultimate",awaken="Awaken"}
-- The presses the chakra button infuses (Shared/ChakraMoves.Slots).
Scene.SLOT={light="Attack",heavy="Heavy",leap="Jump",dash="Dodge",tool="Tool"}
Scene.MOVES={walk=true,run=true}
Scene.TOWARD={foe=true,away=true,left=true,right=true,none=true}
-- A key or a stick held at most this long (s).
Scene.MAX_HOLD=5
-- (27/11, Studio: a capture froze the server 2 s and three beats went off
-- together) The scene's clock moves at most this much a frame: a stall of the
-- server delays what follows instead of piling it up. Each stall is told in
-- the result (`stalls`): a take with one is to be shot again. (A slow Studio's
-- frames, 0.1 to 0.25 s with four places open, are no stall.)
Scene.MAX_DT=.5

-- The scenes written here (the CM's storyboards). Episode 1, « Lee's
-- weights » (doc projet § Épisode 1): his blows stopped by the sand, he
-- takes the weights off, they crater the floor, the AfterImage gets round
-- the sand, the Lotus drives Gaara into the floor.
Scene.PRESETS={
	-- (the K.O. armed after the Lotus seizes him, 12.46 s in the harness: its
	-- slam into the floor, 13.2 s, knocks him out)
	LeeWeights={street="Plaza",avatar={kit="Leaf",nodes={"Weights","HeavyDrop","LearnPrimaryLotus"}},foe={kit="Sand"},gap=7,koAt=12.8,
		beats={
			-- 0–2 s: in, a blow that the sand stops
			{t=0.2,who="avatar",act="walk",hold=.5},
			{t=0.9,who="avatar",act="light"},
			-- 2–5 s: round him, from every side, the sand blocks everything
			-- (one blow at a time: each costs the sand a charge, none breaks it)
			{t=1.3,who="avatar",act="walk",toward="left",hold=.4},
			{t=1.9,who="avatar",act="light",toward="foe"},
			{t=2.3,who="avatar",act="walk",toward="right",hold=.4},
			{t=2.9,who="avatar",act="light",toward="foe"},
			{t=3.2,who="foe",act="refill"},
			{t=3.4,who="avatar",act="walk",hold=.2},
			{t=3.9,who="avatar",act="light"},
			{t=4.5,who="avatar",act="light"},
			-- 5–8 s: back off, the weights off and down
			{t=5.0,who="avatar",act="dash",toward="away",hold=.3},
			{t=6.0,who="avatar",act="RemoveWeights"},
			{t=7.6,who="foe",act="refill"},
			-- 8–12 s: gone; his speed's string cracks the sand, the blows land
			{t=8.2,who="avatar",act="AfterImage"},
			{t=8.6,who="avatar",act="light"},
			{t=8.9,who="avatar",act="light"},
			{t=9.2,who="avatar",act="light"},
			{t=9.6,who="avatar",act="light"},
			{t=10.3,who="avatar",act="AfterImage",toward="left"},
			{t=10.8,who="avatar",act="heavy"},
			-- 12–16 s: the Lotus
			{t=12.0,who="avatar",act="PrimaryLotus"},
		}},
}

local function list(t)
	local keys={}
	for k in t do table.insert(keys,k) end
	table.sort(keys)
	return table.concat(keys,", ")
end
local function streetKeys()
	local keys={}
	for _,s in HubMap.Streets do table.insert(keys,s.key) end
	table.sort(keys)
	return table.concat(keys,", ")
end
local function isVector(v) return typeof(v)=="Vector3" end

-- What `act` is for a kit: {kind, action, opts, seals, name} or nil and the
-- kit's moves, in words.
function Scene.resolve(kit,act)
	if type(act)~="string" or act=="" then return nil,"an act is a word" end
	local low=string.lower(act)
	if Scene.PLAIN[low] then return {kind="press",action=Scene.PLAIN[low],name=low} end
	if Scene.MOVES[low] then return {kind="move",run=low=="run",name=low} end
	if low=="stop" then return {kind="stop",name=low} end
	if low=="refill" then return {kind="refill",name=low} end
	local slot=string.match(low,"^chakra[:%s]+(%a+)$")
	if slot and Scene.SLOT[slot] then return {kind="press",action=Scene.SLOT[slot],opts={chakra=true},name=low} end
	for s,sig in ChakraMoves.Signature[kit] or {} do
		if string.lower(sig)==low then return {kind="press",action=Scene.SLOT[s],opts={chakra=true},name=sig} end
	end
	local def=Fighters[kit]
	for i,tech in (def and def.Techniques) or {} do
		if tech.Id and string.lower(tech.Id)==low then return {kind="press",action="Technique"..i,name=tech.Id} end
	end
	for _,spec in SealJutsu[kit] or {} do
		if type(spec)=="table" and spec.Id and string.lower(spec.Id)==low and spec.Signs then
			return {kind="seals",seals={spec.Signs[1],spec.Signs[2]},name=spec.Id}
		end
	end
	return nil,"act \""..act.."\": not a move of "..tostring(kit).." (its moves: "..Scene.moves(kit)..")"
end
-- A kit's moves, in the words `act` takes.
function Scene.moves(kit)
	local words={}
	for w in Scene.PLAIN do table.insert(words,w) end
	for w in Scene.MOVES do table.insert(words,w) end
	table.insert(words,"stop");table.insert(words,"refill")
	for _,sig in ChakraMoves.Signature[kit] or {} do table.insert(words,sig) end
	local def=Fighters[kit]
	for _,tech in (def and def.Techniques) or {} do if tech.Id then table.insert(words,tech.Id) end end
	for _,spec in SealJutsu[kit] or {} do if type(spec)=="table" and spec.Id and spec.Signs then table.insert(words,spec.Id) end end
	table.sort(words)
	return table.concat(words,", ")
end

-- A beat given as {t, who, act, toward?} or with its keys.
local function beatOf(b)
	if type(b)~="table" then return nil end
	return {t=b.t or b[1],who=b.who or b[2],act=b.act or b[3],toward=b.toward or b[4],hold=b.hold,chakra=b.chakra}
end

-- The spec checked and the presses it makes, in time order; or nil and what
-- is wrong (in words the CM can act on).
function Scene.plan(spec)
	spec=if type(spec)=="table" then spec else {}
	local D=Scene.DEFAULT
	if spec.preset~=nil then
		local base=Scene.PRESETS[spec.preset]
		if not base then return nil,"preset: one of "..list(Scene.PRESETS) end
		local merged=table.clone(base)
		for k,v in spec do if k~="preset" then merged[k]=v end end
		spec=merged
	end
	local key=spec.street or D.street
	local site=nil
	for _,s in HubMap.Streets do if s.key==key then site=s end end
	if not site then return nil,"street: one of "..streetKeys() end
	local avatar=if type(spec.avatar)=="table" then spec.avatar else {kit=spec.avatar}
	local foe=if type(spec.foe)=="table" then spec.foe else {kit=spec.foe}
	for _,side in {{"avatar",avatar},{"foe",foe}} do
		local kit=side[2].kit
		if type(kit)~="string" or not table.find(BetaRoster,kit) or not Fighters[kit] then return nil,side[1]..".kit: one of "..table.concat(BetaRoster,", ") end
	end
	local nodes=avatar.nodes or {}
	if type(nodes)~="table" then return nil,"avatar.nodes: a list of his tree's nodes" end
	for _,n in nodes do if type(n)~="string" then return nil,"avatar.nodes: a list of his tree's nodes" end end
	local gap=spec.gap or D.gap
	if type(gap)~="number" or gap<3 or gap>site.radius*1.6 then return nil,string.format("gap: 3 to %d studs in %s",math.floor(site.radius*1.6),key) end
	if type(spec.beats)~="table" or #spec.beats==0 then return nil,"beats: at least one {t, who, act}" end
	local kits={avatar=avatar.kit,foe=foe.kit}
	local presses,last={},0
	for n,raw in spec.beats do
		local b=beatOf(raw)
		local where="beat "..n
		if not b then return nil,where..": {t, who, act}" end
		if type(b.t)~="number" or b.t<0 or b.t>Scene.MAX_T then return nil,where..": t from 0 to "..Scene.MAX_T.." s" end
		local who=Scene.WHO[b.who or "avatar"]
		if not who then return nil,where..": who is avatar or foe" end
		local r,why=Scene.resolve(kits[who],b.act)
		if not r then return nil,where..": "..why end
		local toward=b.toward
		if toward~=nil and not isVector(toward) and not Scene.TOWARD[toward] then return nil,where..": toward is foe, away, left, right, none or a direction" end
		if b.hold~=nil and (type(b.hold)~="number" or b.hold<0 or b.hold>Scene.MAX_HOLD) then return nil,where..": hold from 0 to "..Scene.MAX_HOLD.." s" end
		local opts=r.opts
		if b.chakra==true then opts={chakra=true} end
		if r.kind=="press" and r.action:match("^Technique") and b.hold then opts=table.clone(opts or {});opts.hold=b.hold end
		local base={beat=n,who=who,name=r.name,toward=toward,hold=b.hold}
		if r.kind=="seals" then
			-- the weave: open, then the two seals (the jutsu goes on the second)
			local g=spec.seals or D.seals
			table.insert(presses,table.clone(base));presses[#presses].t=b.t;presses[#presses].kind="press";presses[#presses].action="Seals"
			for i,sign in r.seals do
				local p=table.clone(base);p.t=b.t+g*i;p.kind="press";p.action="Technique"..sign;p.part=true
				table.insert(presses,p)
			end
		else
			local p=table.clone(base);p.t=b.t;p.kind=r.kind;p.action=r.action;p.opts=opts;p.run=r.run
			table.insert(presses,p)
		end
		last=math.max(last,b.t)
	end
	-- in time order, the script's order kept for the same instant
	for i,p in presses do p.order=i end
	table.sort(presses,function(a,b) if a.t~=b.t then return a.t<b.t end return a.order<b.order end)
	local koAtEnd=spec.koAtEnd~=false
	local koAt=spec.koAt or last
	if type(koAt)~="number" or koAt<0 or koAt>Scene.MAX_T then return nil,"koAt: from 0 to "..Scene.MAX_T.." s" end
	return {site=site,avatar=avatar.kit,foe=foe.kit,nodes=table.clone(nodes),gap=gap,presses=presses,last=last,
		intro=spec.intro==true,koAtEnd=koAtEnd,koAt=koAt,koWithin=spec.koWithin or D.koWithin,flash=spec.flash~=false,
		take=spec.take or 1,tail=spec.tail or D.tail,lead=spec.lead or D.lead,preset=spec.preset}
end

-- deps: matches, press(c, actor, action, aim, opts) (DevHooks.press),
-- avatarState(player) → "ready" when his body is built, flash() → the
-- flash's time (or nil), attribute(name, value) (workspace's, for the
-- cameras), clock() (os.clock: the stick's age, as Matches reads it).
function Scene.new(deps)
	return setmetatable({deps=deps,state="idle",log={},events={}},Scene)
end

-- A flat direction for `toward`, from `a` (the foe: b).
function Scene.direction(a,b,toward)
	local flat=Vector3.new(1,0,1)
	local d=(b.root.Position-a.root.Position)*flat
	local at=if d.Magnitude>.01 then d.Unit else a.root.CFrame.LookVector*flat
	if toward==nil or toward=="foe" then return at end
	if toward=="away" then return -at end
	if toward=="left" then return Vector3.new(0,1,0):Cross(at).Unit end
	if toward=="right" then return at:Cross(Vector3.new(0,1,0)).Unit end
	if toward=="none" then return Vector3.zero end
	local v=toward*flat
	return if v.Magnitude>.01 then v.Unit else Vector3.zero
end

function Scene:start(player,spec,now)
	local m=self.deps.matches
	if not player then return {ok=false,error="no player"} end
	local plan,err=Scene.plan(spec)
	if not plan then return {ok=false,error=err} end
	local s=m:session(player)
	self:stop()
	if not m:siteFree(plan.site.key,s) then return {ok=false,error=plan.site.key.." holds a fight: try another street, or again when it ends"} end
	-- his own body: built once in the background (Server/AvatarBody)
	s.avatarBody=true
	local state=self.deps.avatarState and self.deps.avatarState(player) or "ready"
	if state~="ready" then return {ok=false,error="his avatar's body is not built yet ("..tostring(state).."): try again in a few seconds"} end
	if s.phase~="Selection" then m:selection(player) end
	s.masterTrial=nil;s.firstStage=nil;s.firstFight=nil;s.coach=nil;s.challenge=nil;s.cup=nil
	local site=plan.site
	s.nextSite={key=site.key,origin=HubMap.Origin+site.at,radius=site.radius,place=site.place,street=true,axis=site.axis,start=site.start}
	-- the prodigy's whole kit his for the shoot (nothing locked), with the
	-- nodes the scene asks for; the foe's whole kit
	local ok,why=m:start(player,plan.avatar,plan.foe,false,{player={nodes=plan.nodes}})
	s.nextSite=nil
	if not ok then return {ok=false,error="the duel did not start: "..tostring(why)} end
	s.roundsToWin=1;s.scripted=true;s.botFrozen=true;s.bot.move=Vector3.zero
	local c=s.combat
	if not plan.intro then s.introUntil=nil end
	-- face to face along the street, `gap` apart
	local axis=site.axis or Vector3.zAxis
	local up=Vector3.new(0,3,0)
	c:relocate(s.human,s.origin+up+axis*plan.gap/2);c:relocate(s.bot,s.origin+up-axis*plan.gap/2)
	s.human.root.CFrame=CFrame.lookAt(s.human.root.Position,Vector3.new(s.bot.root.Position.X,s.human.root.Position.Y,s.bot.root.Position.Z))
	s.bot.root.CFrame=CFrame.lookAt(s.bot.root.Position,Vector3.new(s.human.root.Position.X,s.bot.root.Position.Y,s.human.root.Position.Z))
	pcall(m.snapshot,m,player,s)
	-- what happens, as the duel calls it
	c.damageLog={}
	self.events={}
	s.onCombatEvent=function(a,event)
		table.insert(self.events,{at=c.now,who=if a==s.human then "avatar" else "foe",event=event})
	end
	self.plan=plan;self.player=player;self.session=s;self.combat=c
	self.log={};self.next=1;self.stops={};self.ko=nil;self.koArmed=false;self.forcing=nil;self.error=nil;self.endedAt=nil;self.lastDamage=nil
	self.stalls={};self.lastNow=c.now
	self.startedAt=now
	local attribute=self.deps.attribute or function() end
	attribute("NDTake",plan.take)
	attribute("NDBeat","ready#0")
	-- t = 0: after the intro if it plays, a breath after the flash
	local introLeft=if plan.intro and s.introUntil then math.max(0,s.introUntil-c.now) else 0
	self.t0=c.now+introLeft+plan.lead
	-- the scene's clock: seconds from t = 0, stalls taken out
	self.el=c.now-self.t0
	self.flashAt=nil
	if plan.flash and self.deps.flash then
		local due=introLeft
		self.flashDue=c.now+due
	end
	self.state="playing"
	return {ok=true,street=site.key,place=site.place,avatar=plan.avatar,foe=plan.foe,nodes=plan.nodes,presses=#plan.presses,
		lastBeat=plan.last,koAtEnd=plan.koAtEnd,startsIn=self.t0-c.now,startedAt=now,preset=plan.preset}
end

-- His stick back to him, the foe's AI back.
function Scene:stop()
	local s=self.session
	if s then
		s.scripted=nil;s.botFrozen=nil;s.onCombatEvent=nil
		for _,a in {s.human,s.bot} do if a then a.move=Vector3.zero;a.sprinting=false end end
	end
	self.session=nil;self.combat=nil
end

function Scene:fail(why)
	self.state="failed";self.error=why
	self:stop()
end

function Scene:press(p,el)
	local s,c=self.session,self.combat
	local a=if p.who=="avatar" then s.human else s.bot
	local b=if p.who=="avatar" then s.bot else s.human
	local clock=self.deps.clock or os.clock
	local res,why=true,nil
	if p.kind=="refill" then
		a.chakra=a.def.Chakra;a.cooldowns={}
		if a.def.SandShield then a.shieldCharges=a.def.SandShield.Charges end
	elseif p.kind=="stop" then
		a.move=Vector3.zero;a.sprinting=false
	elseif p.kind=="move" then
		local hold=p.hold or .3
		a.move=Scene.direction(a,b,p.toward);a.lastMove=clock()+hold;a.sprinting=p.run==true
		table.insert(self.stops,{at=el+hold,a=a})
	else
		-- the stick, for the presses a direction steers (a dash, a turn)
		if p.toward~=nil or p.action=="Dodge" then
			local hold=p.hold or .25
			a.move=Scene.direction(a,b,p.toward);a.lastMove=clock()+hold
			table.insert(self.stops,{at=el+hold,a=a})
		end
		if p.action=="Ultimate" then a.ultimate=100 end
		if p.who=="avatar" then a.playerInput=true end
		local aim=b.root.Position
		if p.toward~=nil and p.toward~="foe" then aim=a.root.Position+Scene.direction(a,b,p.toward)*12 end
		local ok,reason=self.deps.press(c,a,p.action,aim,p.opts)
		res,why=ok,reason
	end
	if not p.part then (self.deps.attribute or function() end)("NDBeat",p.name.."#"..p.beat) end
	table.insert(self.log,{beat=p.beat,t=p.t,at=c.now,since=el,who=p.who,act=p.name,action=p.action,ok=res~=false,why=why})
end

-- Each frame (DevHooks' Heartbeat).
function Scene:step(now)
	if self.state~="playing" then return end
	local s,plan=self.session,self.plan
	if not s or s.combat~=self.combat or s.phase~="Duel" then
		-- the duel is over: the K.O.'s result screen, or he left
		self.state=if self.ko then "done" else "stopped"
		self.endedAt=now
		self:stop()
		return
	end
	local c=s.combat
	if self.flashDue and c.now>=self.flashDue then
		self.flashDue=nil
		self.flashAt=c.now
		pcall(self.deps.flash)
	end
	local raw=math.max(0,c.now-self.lastNow)
	local dt=math.min(raw,Scene.MAX_DT)
	if raw>dt then table.insert(self.stalls,{at=c.now,since=self.el+dt,lost=raw-dt}) end
	self.lastNow=c.now
	self.el+=dt
	local el=self.el
	if el>plan.last+plan.koWithin+plan.tail+10 then self:fail("the scene ran past its end");self.deps.matches:selection(self.player);return end
	-- neither falls before the end: a body under half its health is whole again
	for _,a in {s.human,s.bot} do
		local armed=self.koArmed and a==s.bot
		if not armed and a.health>0 and a.health<a.def.Health*.5 then a.health=a.def.Health;pcall(function() a.hum.Health=a.health end) end
	end
	-- the K.O.: the foe's next blow, then by force
	if plan.koAtEnd and not self.koArmed and el>=plan.koAt then
		self.koArmed=true
		s.bot.health=math.min(s.bot.health,1);pcall(function() s.bot.hum.Health=s.bot.health end)
	end
	if s.finishing and not self.ko then
		self.ko={at=c.now,since=el,by=if s.winner==s.human.id then "avatar" else "foe",forced=self.forcing==true}
	end
	if plan.koAtEnd and self.koArmed and not s.finishing and el>=plan.koAt+plan.koWithin then
		-- he still stands: knocked out (as the `ko` op)
		local v=s.bot
		self.forcing=true
		v.invulnerableUntil=0;v.rotationUntil=0;v.readUntil=0;v.guardHeld=false;v.comboHits=0;v.shieldCharges=0
		v.health=1;pcall(function() v.hum.Health=1 end)
		c:damage(s.human,v,50,false,false)
		if s.finishing and not self.ko then self.ko={at=c.now,since=el,by="avatar",forced=true} end
	end
	if not plan.koAtEnd and el>=plan.last+plan.tail then
		self.state="done";self.endedAt=now
		self:stop()
		self.deps.matches:selection(self.player)
		return
	end
	-- the sticks let go
	for i=#self.stops,1,-1 do
		local stop=self.stops[i]
		if el>=stop.at then stop.a.move=Vector3.zero;stop.a.sprinting=false;table.remove(self.stops,i) end
	end
	-- the presses due
	while self.next<=#plan.presses and plan.presses[self.next].t<=el do
		local p=plan.presses[self.next]
		self.next+=1
		local ok,e=pcall(self.press,self,p,el)
		if not ok then table.insert(self.log,{beat=p.beat,t=p.t,at=c.now,since=el,who=p.who,act=p.name,action=p.action,ok=false,why=tostring(e)}) end
	end
end

function Scene:result()
	local plan=self.plan
	local hits={}
	local c=self.combat
	local damage=(c and c.damageLog) or self.lastDamage or {}
	if c then self.lastDamage=c.damageLog end
	-- a moment of the duel's clock in the scene's (the stalls before it taken out)
	local t0=self.t0 or 0
	local stalls=self.stalls or {}
	local function since(at)
		local lost=0
		for _,st in stalls do if st.at<=at then lost+=st.lost end end
		return at-t0-lost
	end
	local who=function(by)
		if not plan then return by end
		if plan.avatar==plan.foe then return "either" end
		return if by==plan.avatar then "avatar" elseif by==plan.foe then "foe" else tostring(by)
	end
	for _,d in damage do table.insert(hits,{at=d.t,since=since(d.t),by=who(d.by),amount=d.amount,tag=d.tag,hits=d.hits}) end
	local events={}
	for _,e in self.events do table.insert(events,{at=e.at,since=since(e.at),who=e.who,event=e.event}) end
	return {state=self.state,error=self.error,preset=plan and plan.preset,street=plan and plan.site.key,avatar=plan and plan.avatar,foe=plan and plan.foe,
		take=plan and plan.take,startedAt=self.startedAt,t0=self.t0,flashAt=self.flashAt,endedAt=self.endedAt,
		beats=self.log,hits=hits,events=events,ko=self.ko,stalls=stalls}
end

return Scene
