-- Tutorial v2 (user 02/11: "un vrai tutoriel ... adapté pour chaque perso",
-- "dedans tu pourras t'apercevoir de tous les bugs").
--
-- One curriculum, adapted to the fighter played: the string has his own
-- length, the routes are his (named by their move), the tool is his, every
-- jutsu of his kit is a step of its own, his awakening and ultimate when he
-- has them. Key names come from Shared/Controls (never written by hand).
--
-- Objectives observe the real engine (combat events, accepted presses);
-- setups reset the practice pair, they never fake success.
--
-- Every step is also a probe. While it runs it records what went wrong:
-- presses the fight refused (and why), moments the stick was held while the
-- body was free and did not move (a freeze), the watchdogs that had to let a
-- body go, and a step nobody could finish in time (STUCK: it moves on). Each
-- finished step prints one line ([NinjaDuelTutorial]) and the whole report is
-- Tutorial.report(s) (dev hook op "tutorial"). Server/TutorialBot plays it on
-- its own, for any fighter, in the debug places.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Controls=require(Shared.Controls)
local FirstMinute=require(Shared.FirstMinute)
local Brawler=require(script.Parent.Brawler)
local Tutorial={}

local K,P=Controls.KeyLabel,Controls.PadLabel
local function flat(v) return Vector3.new(v.X,0,v.Z) end

-- What a fighter's tool is called on screen.
local TOOL_NAME={Kunai="kunai",Shuriken="shuriken",Sand="sand bullet",Deflect="deflecting kick",Gust="fan gust"}
local function toolName(a)
	local mastery=a.def.ToolMastery
	if mastery and mastery.Projectile then return tostring(mastery.Projectile) end
	return TOOL_NAME[a.def.Tool or ""] or string.lower(tostring(a.def.Tool or "tool"))
end
local function moveLabel(name)
	-- "LionKick" -> "Lion Kick"
	return (string.gsub(tostring(name),"(%l)(%u)","%1 %2"))
end
local TECH_KEY={"1","2","3","4","5"}

-- ------------------------------------------------------------------ steps
-- A step: id, title, key, pad (strings or functions of the actor), place
-- ("near" | "far" | "wall" | "air"), bot ("idle" | "heavy" | "channel" |
-- "grab" | "fight"), setup(s,t,now), check(s,t,now) -> done, timeout (s).
local function step(spec) spec.timeout=spec.timeout or 40;spec.place=spec.place or "far";spec.bot=spec.bot or "idle";return spec end

-- The adapted curriculum for this actor (its own copy of every spec).
function Tutorial.plan(a)
	local def=a.def
	local graph=Brawler.graph(a) or {}
	local routes=graph.routes or {}
	local steps={}
	local function add(spec) table.insert(steps,step(spec)) end
	add({id="move",title="Move",key="WASD",pad="L stick",
		check=function(s,t) return t.travel>12 end})
	add({id="sprint",title="Sprint",key="Hold "..K.Sprint.." + move",pad=P.Sprint..", then move",
		check=function(s,t) return s.human.sprinting and s.human.locomotion.Magnitude>28 end})
	add({id="jump",title="Jump and land",key=K.Jump,pad=P.Jump,
		check=function(s,t) local a=s.human;t.seenAir=t.seenAir or a.airborne;return t.seenAir and not a.airborne end})
	add({id="lock",title="Unlock, then lock the target",key=K.Lock.." twice",pad=P.Lock.." twice",
		check=function(s,t) local a=s.human;t.unlocked=t.unlocked or not a.locked;return (t.unlocked or t.ev("Unlock")) and a.locked and t.ev("Lock") end})
	add({id="dodge",title=if def.SandFlicker then "Sand body-flicker" else "Directional dash",key="Direction + "..K.Dodge,pad="L stick + "..P.Dodge,
		check=function(s,t) return t.ev("Dodge") end})
	add({id="wall",title="Run up the wall, then rebound",key="Move into the wall, then "..K.Jump,pad="Push into the wall, then "..P.Jump,place="wall",
		check=function(s,t,now) local a=s.human;t.seenWall=t.seenWall or a.wall~=nil;return t.seenWall and (a.wallJumpUntil or 0)>now end})
	local length=def.StringLength or 4
	add({id="string",title="Land your "..length.."-hit string",key=K.Light.." x"..length,pad=P.Light.." x"..length,place="near",
		check=function(s,t) return t.count("Hit")>=length end})
	add({id="heavy",title="Heavy strike",key=K.Heavy,pad=P.Heavy,place="near",
		check=function(s,t) return t.ok("Heavy") and t.count("Hit")>=1 end})
	if routes.side then
		add({id="routeSide",title="Turn the angle: "..moveLabel(routes.side),key="2 hits, then "..K.Dodge,pad="2 hits, then "..P.Dodge,place="near",
			check=function(s,t) return t.ev("RouteSide") end})
	end
	if routes.down then
		add({id="routeDown",title="Go low: "..moveLabel(routes.down),key="3 hits, then "..K.Heavy,pad="3 hits, then "..P.Heavy,place="near",
			check=function(s,t) return t.ev("RouteDown") end})
	end
	if routes.up then
		add({id="launch",title="Launch: "..moveLabel(def.LauncherMove or "Launcher"),key="2 hits, then "..K.Heavy,pad="2 hits, then "..P.Heavy,place="near",
			check=function(s,t) return t.ev("LaunchHit") end})
	end
	add({id="chase",title="Chase the launched body",key=K.Pursuit.." after the launch",pad=P.Pursuit.." after the launch",place="near",
		setup=function(s,t,now) local c,a,b=s.combat,s.human,s.bot;Brawler.react(c,b,"Launched",Vector3.new(0,48,0),1.2);a.pursuitUntil=now+1.2 end,
		retry=3,
		check=function(s,t) local a,b=s.human,s.bot;return t.ev("Chase") and a.state=="Neutral" and a.airborne and (a.root.Position-b.root.Position).Magnitude<7 end})
	add({id="air",title="Land two aerial strikes",key=K.Light.." twice in the air",pad=P.Light.." twice in the air",place="air",retry=3,
		check=function(s,t) return t.count("AirHit")>=2 end})
	-- (Audit 04/11) the finisher is a table: its name (it printed "table: 0x…").
	local finisher=graph.airFinisher
	add({id="airFinish",title=if finisher then "Finish in the air: "..moveLabel(if type(finisher)=="table" then finisher.name else finisher) else "Finish downward",key=K.Heavy.." in the air",pad=P.Heavy.." in the air",place="air",retry=3,
		check=function(s,t) return t.ev("SlamHit") or t.ev("LionCombo") or (t.ok("Heavy") and t.count("Hit")>=1) end})
	add({id="runStrike",title=if graph.runStrike then "Strike on the run: "..moveLabel(graph.runStrike) else "Strike on the run",key="Sprint at him, then "..K.Light.." or "..K.Heavy,pad="Sprint at him, then "..P.Light.." or "..P.Heavy,
		check=function(s,t) return t.ev("RunningStrike") end})
	add({id="grab",title="Grab, then throw",key=K.Grab..", then "..K.Light.." ("..K.Heavy.." throws upward)",pad=P.Grab..", then "..P.Light,place="near",
		check=function(s,t) return t.ev("ThrowHit") end})
	-- A deflecting tool (Guy's kick) needs something thrown at it: the partner throws.
	add({id="tool",title="Your tool: "..toolName(a),key=if a.def.Tool=="Deflect" then K.Tool.." as his kunai flies" else K.Tool,pad=if a.def.Tool=="Deflect" then P.Tool.." as his kunai flies" else P.Tool,
		bot=if a.def.Tool=="Deflect" then "throw" else "idle",
		check=function(s,t) return t.ok("Tool") end})
	for i,spec in def.Techniques or {} do
		if i>5 then break end
		add({id="jutsu"..i,title="Jutsu "..i..": "..tostring(spec.Name),key=TECH_KEY[i],pad=Controls.TechniquePad[i] or ("Jutsu "..i),
			place=if (spec.Range or 20)<10 then "near" else "far",technique=spec,
			setup=function(s)
				local a=s.human;a.chakra=a.def.Chakra or 100;a.cooldowns={}
				-- (Studio 03/11, Minato: "Condition missing" on every press) A
				-- jutsu that goes to a seal gets one planted behind the partner.
				if spec.Requires=="Anchor" and s.bot and s.combat then
					local b=s.bot
					local away=b.root.Position-a.root.Position;away=Vector3.new(away.X,0,away.Z)
					away=if away.Magnitude>.1 then away.Unit else Vector3.zAxis
					local spot=b.root.Position+away*6
					require(script.Parent.Techniques).plant(s.combat,a,Vector3.new(spot.X,s.origin.Y,spot.Z),Vector3.yAxis)
				end
			end,
			check=function(s,t) return t.ev("Cast:"..tostring(spec.Id)) end})
	end
	-- (04/11) The second page: the first seal jutsu, one press with the page held.
	local seal=def.SealJutsu and def.SealJutsu[1]
	if seal then
		add({id="sealPage",title="Hand seals: "..tostring(seal.Name),key="Hold "..K.WallDetach.." + 1",pad="Hold R1 + L1 + □",
			place=if (seal.Range or 20)<10 then "near" else "far",technique=seal,
			setup=function(s) local a=s.human;a.chakra=a.def.Chakra or 100;a.cooldowns={} end,
			check=function(s,t) return t.ev("Cast:"..tostring(seal.Id)) end})
	end
	add({id="guard",title="Guard the incoming strike",key="Hold "..K.Guard,pad="Hold "..P.Guard,place="near",bot="heavy",
		check=function(s,t) return t.ev("GuardHit") end})
	add({id="evade",title="Dodge the incoming strike",key=K.Dodge.." during his wind-up",pad=P.Dodge.." during his wind-up",place="near",bot="heavy",
		check=function(s,t,now) local a,b=s.human,s.bot;return t.ev("Dodge") and (t.ev("Evaded") or (b.attackName~=nil and now-(b.attackStarted or now)>.46 and a.health==t.health)) end})
	-- (Studio 03/11, against Gaara: his heavy knocks down, and a body on the
	-- floor cannot substitute) The partner hits with his light here.
	add({id="substitute",title="Escape after being hit",key=K.Substitute.." just after contact",pad=P.Substitute.." just after contact",place="near",bot="heavy",strike="Attack",
		check=function(s,t) return t.ev("Substitute") end})
	-- (Roster run 02/11: STUCK for every fighter from 28 studs: the signs end
	-- before anyone gets there.) In dash reach, as in a duel.
	add({id="interrupt",title="Interrupt his hand signs",key=K.Light.." during the signs",pad=P.Light.." during the signs",place="mid",bot="channel",
		check=function(s,t) return t.ev("Interrupt") end})
	add({id="throwBreak",title="Break his grab",key=K.Grab.." as he seizes you",pad=P.Grab.." as he seizes you",place="near",bot="grab",
		check=function(s,t) return t.ev("ThrowBreak") end})
	if def.Awakening then
		add({id="awaken",title="Awaken: "..tostring(def.Awakening.Name or "awakening"),key=K.Awaken.." (low health)",pad="D-pad ↓ (low health)",
			setup=function(s) local a=s.human;a.awakened=false;a.health=a.def.Health*.3;a.hum.Health=a.health end,
			check=function(s,t) return t.ev("Awaken") end})
	end
	local Ultimates=require(script.Parent.Ultimates)
	local ult=Ultimates.def(a)
	if ult then
		add({id="ultimate",title="Ultimate: "..tostring(ult.Name),key=K.Ultimate.." (bar full)",pad=P.Ultimate.." (bar full)",place="near",
			setup=function(s) s.human.ultimate=Ultimates.MAX end,
			check=function(s,t) return t.ev("UltimateStart") end})
	end
	add({id="win",title="Win the practice duel",key="Use your complete kit",pad="Use your complete kit",place="far",bot="fight",timeout=math.huge,
		check=function() return false end})
	return steps
end

-- (B1 lot 2, DEC-034) The first minute: four prompts, a partner who waits,
-- then a real duel (Server/Matches). Each step moves on by itself after 25 s
-- (a player who does not find the key is not held there), and the panel says
-- what to press on a keyboard, a pad or a phone (Shared/FirstMinute.Touch).
function Tutorial.firstPlan(a)
	local def=a.def
	local steps={}
	local function add(spec) spec.timeout=spec.timeout or 25;spec.touch=FirstMinute.Touch[spec.id];table.insert(steps,step(spec)) end
	add({id="move",title="Move",key="WASD",pad="L stick",check=function(s,t) return t.travel>12 end})
	add({id="string",title="Strike: three hits",key=K.Light.." x3",pad=P.Light.." x3",place="near",
		check=function(s,t) return t.count("Hit")>=3 end})
	add({id="dodge",title="Dodge",key="Direction + "..K.Dodge,pad="L stick + "..P.Dodge,
		check=function(s,t) return t.ev("Dodge") end})
	local spec=FirstMinute.signature(def)
	if spec then
		local slot=FirstMinute.SignatureSlot
		add({id="signature",title="Your signature: "..tostring(spec.Name),key=TECH_KEY[slot],pad=Controls.TechniquePad[slot] or ("Jutsu "..slot),
			place=if (spec.Range or 20)<10 then "near" else "far",technique=spec,
			setup=function(s) local p=s.human;p.chakra=p.def.Chakra or 100;p.cooldowns={} end,
			-- (Studio 04/11, v37: the duel's intro cut the Chidori at its cast)
			-- the act plays out and lands before the duel begins.
			hold=2.4,
			check=function(s,t) return t.ev("Cast:"..tostring(spec.Id)) end})
	end
	return steps
end
-- ----------------------------------------------------------------- driver
function Tutorial.new(s,kind)
	local t={index=1,entered=0,baseline={},travel=0,attackAt=0,report={},timeoutScale=1,first=kind=="first"}
	t.steps=if t.first then Tutorial.firstPlan(s.human) else Tutorial.plan(s.human)
	s.tutorial=t
	return t
end
-- The next step; past the first minute's last one, it is done (the duel).
local function nextStep(s,t,now)
	t.index+=1
	if not t.steps[t.index] then t.index=#t.steps;t.done=true;return end
	Tutorial.enter(s,now)
end
-- Kept for the specs and tools that name the generic order.
Tutorial.Steps=Tutorial.plan({def={Techniques={}},fighterId=""})
function Tutorial.indexOf(s,id)
	for i,spec in s.tutorial.steps do if spec.id==id then return i end end
	return nil
end
local function counter(t,a,name) return (a.events and a.events[name] or 0)-(t.baseline[name] or 0) end
function Tutorial.enter(s,now)
	local t,a,b=s.tutorial,s.human,s.bot
	local spec=t.steps[t.index]
	local c=s.combat;c:clear(true)
	t.entered=now;t.completedAt=nil;t.baseline=table.clone(a.events or {});t.travel=0;t.seenAir=false;t.seenWall=false;t.unlocked=false
	t.lastPosition=a.root.Position;t.pressFrom=#(a.pressLog or {});t.stillFor=0;t.freezeOpen=false
	-- A step set up again (a missed launch) keeps its record and its clock.
	local same=t.rec and t.recIndex==t.index and not t.rec.status
	if same then t.rec.attempts+=1
	else t.rec={id=spec.id,title=spec.title,started=now,refused={},freezes=0,watchdogs=0,attempts=1};t.recIndex=t.index;t.stepFrom=now;t.stepPress=#(a.pressLog or {}) end
	for _,actor in {a,b} do
		actor.health=actor.def.Health;actor.hum.Health=actor.health;actor.state="Neutral";actor.untilTime=now;actor.chakra=actor.def.Chakra or 100
		actor.subCharges=2;actor.subCooldown=0;actor.subRegenAt=math.huge;actor.comboHits=0;actor.cooldowns={};actor.invulnerableUntil=0
		actor.reaction=nil;actor.reactionVelocity=nil;actor.groundPose=nil;actor.airHold=0
	end
	t.health=a.health
	b.trainingChannelScale=if spec.bot=="channel" then 3 else 1
	-- (Studio 03/11, Minato against Gaara: the run strike, the grab, the dodge
	-- and the escape never completed) A training partner's sand shield ate
	-- every blow the step asks for. It is down in the drills, up in the fight.
	if b.def.SandShield then
		if spec.bot=="fight" then b.shieldCharges=b.def.SandShield.Charges;b.shieldRegenAt=0
		else b.shieldCharges=0;b.shieldRegenAt=math.huge end
	end
	local place=spec.place
	local near=place=="near" or place=="air"
	local gapA,gapB=if near then 3 elseif place=="mid" then 5 else 14,if near then -2 elseif place=="mid" then -5 else -14
	c:relocate(a,s.origin+Vector3.new(0,3,gapA));c:relocate(b,s.origin+Vector3.new(0,3,gapB))
	if place=="wall" then
		local R=require(script.Parent.World).WALL_RADIUS
		c:relocate(a,s.origin+Vector3.new(R-7,3,0));c:relocate(b,s.origin+Vector3.new(R-17,3,0))
	end
	a.root.CFrame=CFrame.lookAt(a.root.Position,b.root.Position);b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position)
	if place=="air" then
		c:relocate(a,s.origin+Vector3.new(0,16,3));c:relocate(b,s.origin+Vector3.new(0,16,-2));a.airborne=true;a.airHold=now+1.8
		Brawler.react(c,b,"Juggled",Vector3.zero,1.8)
	end
	-- A jutsu that needs its target in reach starts within it.
	-- (Roster run 02/11: "Out of range" x5 for Guy, Kakashi, Shino...: a
	-- Sequence, a Zone at the target, a Teleport check their Range without
	-- Requires.) Any jutsu with a reach shorter than the gap starts within it.
	local tech=spec.technique
	if tech and (tech.Requires=="Target" or (tech.Range and tech.Range<(b.root.Position-a.root.Position).Magnitude+2)) then
		local gap=math.clamp((tech.Range or 10)*.5,3,12)
		c:relocate(b,a.root.Position+flat(b.root.Position-a.root.Position).Unit*gap)
		b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position)
	end
	if spec.setup then spec.setup(s,t,now) end
	t.attackAt=now+1
end
-- The bot's longest interruptible channel: the one the player learns to break.
function Tutorial.interruptSlot(b)
	local best,bestChannel="Technique1",-1
	for slot,spec in b.def.Techniques do
		-- (Studio 03/11, Kakashi against Naruto: STUCK) not a jutsu that runs
		-- at you once formed (the Rasengan, range 10): hand signs held in place.
		if spec.Interruptible and spec.Channel>bestChannel and not spec.Requires and not spec.Mobile and (spec.Range or 99)>12 then best,bestChannel="Technique"..slot,spec.Channel end
	end
	return best
end

-- -------------------------------------------------------------- the probe
-- Presses the fight refused since the step began, by reason.
local function collectRefusals(t,a)
	local log=a.pressLog or {}
	-- The log keeps its last 40 entries: count from where the step began.
	local from=math.max(1,math.min(t.stepPress or 0,#log)+1)
	if #log>=40 then from=1 end
	local out={}
	for i=from,#log do
		local entry=log[i]
		if entry.t>=(t.stepFrom or t.entered) and not entry.ok and entry.reason then out[entry.reason]=(out[entry.reason] or 0)+1 end
	end
	return out
end
-- A freeze: the stick held, the body alive and free (no reaction, no hold, not
-- committed), and it does not move for 0.4 s. What held it is kept.
local function probeFreeze(s,t,dt,now)
	local a=s.human
	local wants=a.move and flat(a.move).Magnitude>.5
	local step=(a.root.Position-(t.freezeLast or a.root.Position)).Magnitude;t.freezeLast=a.root.Position
	local free=a.health>0 and a.state=="Neutral" and not a.reaction and not a.wall and now>=(a.airHold or 0) and now>=(a.hitstopUntil or 0)
	if wants and free and step<.01 then
		t.stillFor+=dt
		if t.stillFor>=.4 and not t.freezeOpen then
			t.freezeOpen=true;t.rec.freezes+=1
			if not t.rec.freeze then
				local hum=a.hum
				t.rec.freeze={state=a.state,airborne=a.airborne,humState=hum and hum:GetState().Name,walkSpeed=hum and math.floor(hum.WalkSpeed*10)/10,
					anchored=a.root.Anchored,traversal=a.model:GetAttribute("MovementTraversalActive"),locomotion=math.floor(a.locomotion.Magnitude*10)/10,
					held=a.ultimateHeld==true,grounded=a.grounded}
			end
		end
	else t.stillFor=0;t.freezeOpen=false end
end
local function summary(rec)
	local parts={}
	for reason,n in rec.refused do table.insert(parts,reason.."x"..n) end
	table.sort(parts)
	local line=string.format("%s %.1fs",rec.status,rec.ended-rec.started)
	if #parts>0 then line..="  refused: "..table.concat(parts,", ") end
	if rec.freezes>0 then
		local f=rec.freeze or {}
		line..=string.format("  FREEZES %d (state=%s air=%s hum=%s walk=%s anchored=%s traversal=%s held=%s)",rec.freezes,tostring(f.state),tostring(f.airborne),tostring(f.humState),tostring(f.walkSpeed),tostring(f.anchored),tostring(f.traversal),tostring(f.held))
	end
	if rec.watchdogs>0 then line..="  watchdogs: "..rec.watchdogs end
	if rec.attempts>1 then line..="  setups: "..rec.attempts end
	return line
end
local function close(s,t,now,status)
	local a=s.human
	local rec=t.rec
	rec.status=status;rec.ended=now
	rec.refused=collectRefusals(t,a)
	rec.watchdogs=counter(t,a,"WatchdogWakeup")+counter(t,a,"WatchdogReaction")+counter(t,a,"WatchdogGrab")
	rec.line=summary(rec)
	table.insert(t.report,rec)
	print(string.format("[NinjaDuelTutorial] %s %d/%d %s: %s",tostring(a.fighterId),t.index,#t.steps,rec.id,rec.line))
end
function Tutorial.report(s)
	local t=s.tutorial
	if not t then return nil end
	local out={fighter=s.human and s.human.fighterId,steps={},current=t.steps[t.index] and t.steps[t.index].id}
	for _,rec in t.report do table.insert(out.steps,{id=rec.id,title=rec.title,status=rec.status,line=rec.line,refused=rec.refused,freezes=rec.freezes,freeze=rec.freeze,watchdogs=rec.watchdogs}) end
	return out
end

-- ------------------------------------------------------------------- tick
function Tutorial.update(s,now,dt)
	local t,a,b=s.tutorial,s.human,s.bot;local c=s.combat
	if t.done then return end
	if t.entered==0 then Tutorial.enter(s,now) end
	local spec=t.steps[t.index]
	if spec.bot=="fight" then s.ai:update(now);return end
	b.move=Vector3.zero;b.sprinting=false
	local displacement=(a.root.Position-(t.lastPosition or a.root.Position)).Magnitude;t.travel+=math.min(displacement,4);t.lastPosition=a.root.Position
	t.ev=function(name) return counter(t,a,name)>0 end
	t.count=function(name) return counter(t,a,name) end
	t.ok=function(action)
		for i=#(a.pressLog or {}),1,-1 do
			local entry=a.pressLog[i]
			if entry.t<t.entered then break end
			if entry.action==action and entry.ok then return true end
		end
		return false
	end
	probeFreeze(s,t,dt,now)
	if not t.completedAt and spec.check(s,t,now) then t.completedAt=now end
	if t.completedAt and now-t.completedAt>=(spec.hold or .22) then
		close(s,t,now,"PASS");nextStep(s,t,now);return
	end
	-- Nobody finished it in time: a probe that found a wall, not a lesson to
	-- retry forever. It is reported STUCK and the next step begins.
	if now-t.rec.started>=spec.timeout*(t.timeoutScale or 1) then
		close(s,t,now,"STUCK");nextStep(s,t,now);return
	end
	-- The practice partner.
	if spec.bot=="heavy" and now>=t.attackAt then
		if (b.root.Position-a.root.Position).Magnitude>7 then c:relocate(b,a.root.Position+a.root.CFrame.LookVector*5) end
		b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position);c:request(b,spec.strike or "Heavy");t.attackAt=now+1.7
	elseif spec.bot=="channel" and now>=t.attackAt then
		b.cooldowns={};b.chakra=b.def.Chakra or 100;c:request(b,Tutorial.interruptSlot(b),a.root.Position);t.attackAt=now+1.4
	elseif spec.bot=="throw" and now>=t.attackAt then
		b.cooldowns={};b.toolCooldown=0;c:request(b,"Tool",a.root.Position);t.attackAt=now+1.6
	elseif spec.bot=="grab" and now>=t.attackAt then
		if (b.root.Position-a.root.Position).Magnitude>4 then c:relocate(b,a.root.Position+a.root.CFrame.LookVector*3.2) end
		b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position);b.grabCooldown=0;c:request(b,"Grab");t.attackAt=now+1.8
	end
	-- A failed launch / juggle exercise sets itself up again (same step).
	if spec.retry and now-t.entered>spec.retry then Tutorial.enter(s,now) end
	if a.health<a.def.Health*.3 and spec.id~="awaken" then a.health=a.def.Health;a.hum.Health=a.health end
	if b.health<b.def.Health*.25 then b.health=b.def.Health;b.hum.Health=b.health end
end
function Tutorial.skip(s,now)
	local t=s.tutorial
	if not t or t.done or (not t.first and not t.steps[t.index+1]) then return false end
	close(s,t,now,"SKIP");nextStep(s,t,now)
	return true
end
function Tutorial.snapshot(s)
	local t=s.tutorial;if not t then return nil end
	local step=t.steps[t.index]
	return {index=t.index,total=#t.steps,title=step.title,pad=step.pad,key=step.key,touch=step.touch,id=step.id,first=t.first or nil}
end
return Tutorial
