local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)
local Techniques=require(script.Parent.Techniques)
local Brawler=require(script.Parent.Brawler)
local Chakra=require(script.Parent.ChakraCombat)
local Bodies=require(script.Parent.Bodies)
local Zones=require(script.Parent.Zones)
local Families=require(script.Parent.Families)
-- Family techniques (roster breadth pass): when one is worth using is read
-- from its family and its own spec.AI band, never from the fighter's name.
local function familyWants(self,c,a,target,spec,distance,danger)
	local rule=spec.AI or {}
	local family=spec.Family
	local range=spec.Range or 30
	local opening=target.state=="Recovery" or target.state=="TechniqueRecovery" or target.state=="Stunned" or target.reaction=="Bound"
	local lo,hi,chance
	if family=="Projectile" then lo,hi,chance=8,math.min(range*.85,40),.45
	elseif family=="Strike" then lo,hi,chance=3.5,math.min(range,16),if opening then .9 else .3
	elseif family=="Burst" then lo,hi,chance=0,(spec.Radius or 7)-.5,if danger or target.state=="Rush" then .8 else .25
	elseif family=="Zone" then
		if spec.At=="Self" then lo,hi,chance=0,(spec.Radius or 8)+4,.35 else lo,hi,chance=6,math.min(range,34),.35 end
	elseif family=="Buff" then lo,hi,chance=0,24,.5
	elseif family=="Teleport" then
		if spec.To=="Back" then lo,hi,chance=0,6,if danger then .6 else 0 else lo,hi,chance=8,math.min(range,34),if opening then .7 else .25 end
	elseif family=="Counter" then lo,hi,chance=0,8,if danger then .7 else 0
	elseif family=="Summon" then
		-- Out first; once out, a lunge now and then.
		if Bodies.count(c,a,spec.Body or "puppet")==0 then lo,hi,chance=0,40,.8 else lo,hi,chance=0,30,.25 end
	else return false end
	lo=rule.Min or lo;hi=rule.Max or hi;chance=rule.Chance or chance
	-- Synergies read from data, not names: a strike that is stronger inside
	-- his own zone is taken while the body stands in it; a burst that clears
	-- blades answers blades flying at him; a detonation answers his own
	-- objects lying near the body.
	if spec.InZone and Families.inOwnZone(c,a,target) then chance=math.max(chance,.85) end
	if family=="Burst" and spec.Clear then
		for _,p in c.projectiles do
			if p.a==target and (p.position-a.root.Position).Magnitude<(spec.Radius or 7)+10 then lo,hi,chance=0,math.huge,math.max(chance,.7);break end
		end
	end
	if rule.Punish and not opening then return false end
	if distance<lo or distance>hi then return false end
	if (family=="Projectile" or family=="Strike" or family=="Teleport") and not c:lineOfSight(a,target) then return false end
	return self.rng:NextNumber()<chance
end
local AI={}; AI.__index=AI
function AI.new(combat,actor,seed)
	return setmetatable({combat=combat,actor=actor,nextTick=0,observed=nil,observedAt=0,guardUntil=0,rng=Random.new(seed or 23)},AI)
end
local function slotOf(a,id)
	for slot,spec in a.def.Techniques do if spec.Id==id then return "Technique"..slot,spec end end
	return nil
end
-- A press with an explicit route intent. The stick memory (Brawler.observe)
-- keeps the latest strong push for a moment; the bot's approach must never
-- turn into a route it did not choose, so it declares the one it wants.
local function press(c,a,action,dir,sideSign,aim)
	a.intentOverride={dir or "neutral",sideSign or 0}
	local ok,reason=c:request(a,action,aim)
	a.intentOverride=nil
	return ok,reason
end
-- How keen each prodigy is to re-engage (chakra dash from mid range, chase in
-- a window): Sasuke presses after the body, Itachi waits for it.
local DASH={Flashstep=1.1,Mirage=.75,GentleFist=1,Lion=1.45}
local CHASE={Flashstep=.62,Mirage=.5,GentleFist=.58,Lion=.74}
-- Rock Lee (stress-test wave) is the keenest of all: he never lets the body go.
DASH.Leaf=1.6;CHASE.Leaf=.8
-- Naruto (roster wave): rushes in almost as eagerly, from any angle, and
-- chases every launch (his barrage needs it).
DASH.Legion=1.5;CHASE.Legion=.8
-- Temari (roster wave) re-enters at her range (the wind step) and rarely
-- chases: her conversions are at range (AI:zone).
DASH.Gale=.35;CHASE.Gale=.25
-- A wind lane (Zones) the body stands in that blows against its way to the
-- opponent: the side to step out of it, else nil.
local function laneAgainst(c,a,toward)
	for _,z in c.zones or {} do
		if z.owner~=a and z.tune.headwind and z.direction:Dot(toward)<-.4 and Zones.inside(z,a.root.Position) then
			local d=a.root.Position-z.origin
			local across=Vector3.new(d.X,0,d.Z)-z.direction*(d.X*z.direction.X+d.Z*z.direction.Z)
			return if across.Magnitude>.3 then across.Unit else z.direction:Cross(Vector3.yAxis).Unit
		end
	end
	return nil
end
-- A straight dash at the opponent would run up an enemy lane (it breaks there).
local function laneOnPath(c,a,target)
	if not c.zones or #c.zones==0 then return false end
	local from,to=a.root.Position,target.root.Position
	local way=Vector3.new(to.X-from.X,0,to.Z-from.Z)
	if way.Magnitude<1 then return false end
	for _,z in c.zones do
		if z.owner~=a and z.tune.headwind and z.direction:Dot(way.Unit)<-.35 then
			for k=1,6 do if Zones.inside(z,from:Lerp(to,k/7)) then return true end end
		end
	end
	return false
end
local function plantedSeals(a)
	local count=0
	for _,entry in a.anchors or {} do if not entry.actor then count+=1 end end
	return count
end
-- Defence first: wall tech on the impact, and a substitution decided once per
-- combo (like a player choosing when to spend it), not rolled every tick.
function AI:defend(now)
	local c,a=self.combat,self.actor
	if a.reaction=="WallSplat" then
		local elapsed=now-(a.splatAt or now)
		if self.techPlan==nil then self.techPlan=self.rng:NextNumber()<.5 end
		if self.techPlan and elapsed>=Config.Wall.TechFrom+.03 and elapsed<=Config.Wall.TechUntil then
			if c:request(a,"Dodge") then self.techPlan=nil;return true end
		end
	else self.techPlan=nil end
	-- Incoming blades or fire: guard or sidestep once, at reaction speed.
	if a.state=="Neutral" and not a.reaction and not a.wall and now>=(self.projectileReact or 0) then
		for _,p in c.projectiles do
			if p.a~=a then
				local offset=a.root.Position-p.position
				local gap=offset.Magnitude
				if gap<16 and gap>2 and p.direction:Dot(offset.Unit)>.92 then
					self.projectileReact=now+.6
					-- Neji answers blades and fire with Rotation when it is ready.
					local rotation=slotOf(a,"Rotation")
					if rotation and gap<11 and self.rng:NextNumber()<.55 and c:request(a,rotation) then return true end
					-- Rock Lee kicks a blade out of the air (his tool is the deflecting kick).
					if a.def.Tool=="Deflect" and Techniques.DEFLECTABLE[p.kind] and gap<12 and self.rng:NextNumber()<.6 and c:request(a,"Tool",p.position) then return true end
					local roll=self.rng:NextNumber()
					if roll<.35 then
						c:request(a,"Guard");self.guardUntil=now+.35;return true
					elseif roll<.6 and a.dodgeUntil<=now then
						a.move=Vector3.new(-p.direction.Z,0,p.direction.X)*(if self.rng:NextNumber()<.5 then 1 else -1)
						if c:request(a,"Dodge") then return true end
					end
					break
				end
			end
		end
	end
	-- Grabbed: try to break the throw on reaction.
	if a.reaction=="Grabbed" and a.grabbedAt and now-a.grabbedAt>.12 and self.rng:NextNumber()<.45 then
		if c:request(a,"Grab") then return true end
	end
	-- Low on health: awaken (once per match).
	if not a.awakened and a.def.Awakening and a.health<=a.def.Health*Config.Awaken.Threshold and not a.reaction and self.rng:NextNumber()<.4 then
		if c:request(a,"Awaken") then return true end
	end
	local hits=a.comboHits or 0
	if hits==0 then self.subPlan=nil end
	if hits>0 and self.subPlan==nil then
		self.subPlan=if self.rng:NextNumber()<.5 then 3+math.floor(self.rng:NextNumber()*3) else false
	end
	local hurt=a.state=="Stunned" or (a.reaction~=nil and a.reaction~="Wakeup")
	if hurt and self.subPlan and hits>=self.subPlan and a.subCharges>0 and a.chakra>=Config.Substitution.Cost then
		if c:request(a,"Substitute") then self.subPlan=false;return true end
	end
	-- Ninja Embodiment (EMB-003): the blow's own window to answer it, decided
	-- once per reaction: guard back up or step out (away or to a side) on the
	-- ground, right itself in the air, roll out of a knockdown.
	if a.reaction and self.recoverFor~=a.reactionStartedAt then
		local kind=Brawler.recoverable(c,a)
		if kind then
			self.recoverFor=a.reactionStartedAt
			if self.rng:NextNumber()<(Config.AI.Recover or .5) then
				local away=a.root.Position-a.target.root.Position;away=Vector3.new(away.X,0,away.Z)
				away=if away.Magnitude>.1 then away.Unit else -a.root.CFrame.LookVector
				local side=Vector3.new(-away.Z,0,away.X)*(if self.rng:NextNumber()<.5 then 1 else -1)
				if kind=="stand" and self.rng:NextNumber()<.55 then
					if c:request(a,"Guard") then self.guardUntil=now+.3;return true end
				else
					a.move=if self.rng:NextNumber()<.5 then away else (side+away*.4).Unit
					if c:request(a,"Dodge") then return true end
				end
			end
		end
	end
	return false
end
-- A zoner (def.Zoner: Temari). The distance is hers: too close, the fan pushes
-- the body out or she steps back on the wind (else the fan string makes the
-- distance); a body thrown or held up in the air is converted at range, never
-- chased; at range the scythe, a whirlwind where the body is going, the Great
-- Gust at an approach or at blades, and no walking into melee. Same costs and
-- windows as the player. True when it decided this tick.
function AI:zone(now,distance,toward,tangent,target)
	local c,a=self.combat,self.actor
	local tune=a.def.Zoner
	if a.state=="Rush" then return true end
	if a.reaction or a.airborne or a.state~="Neutral" then return false end
	local function cast(id,aim)
		local slot=slotOf(a,id)
		if slot and c:request(a,slot,aim or target.root.Position) then self.techReadyAt=now+.5+self.rng:NextNumber()*.9;return true end
		return false
	end
	local tool=now>=(a.neutralToolAt or 0) and a.chakra>=Config.ToolCost
	local closing=(target.locomotion or Vector3.zero):Dot(-toward)
	local threat=target.state=="Rush" or target.state=="Pursuit" or closing>6
	local hurt=target.reaction~=nil or target.state=="Stunned"
	-- Where the body will be when the wind gets there (a scythe at ~74 studs/s).
	local lead=target.root.Position+(target.locomotion or Vector3.zero)*math.min(.5,distance/74)*.8
	-- A dash or a chase at her: the gust stops it in the air (it is not
	-- armoured); already on her, the guard takes the arrival strike.
	if target.state=="Rush" or target.state=="Pursuit" then
		if distance<7 and self.rng:NextNumber()<.6 then c:request(a,"Guard");self.guardUntil=now+.4;return true end
		if distance<(a.def.Gust and a.def.Gust.Range or 18)+2 and tool and self.rng:NextNumber()<.75 then
			a.move=Vector3.zero
			if press(c,a,"Tool","neutral",0,target.root.Position) then return true end
		end
	end
	if distance<tune.Close then
		if hurt then return false end
		-- A strike already coming: the guard (her fan string or a gust answers after).
		if (target.state=="Startup" or target.state=="Active") and distance<8 and self.rng:NextNumber()<.55 then
			c:request(a,"Guard");self.guardUntil=now+.35;return true
		end
		-- Walking into the fan's length: the tip first (it out-reaches a fist),
		-- the string then throws the body back out.
		if distance>4.6 and distance<7.6 and target.state~="Startup" and target.state~="Active" and self.rng:NextNumber()<.45 then
			a.move=Vector3.zero
			if press(c,a,"Attack") then return true end
		end
		if distance<tune.Push and tool and self.rng:NextNumber()<.55 and press(c,a,"Tool","neutral",0,target.root.Position) then return true end
		if a.pursuitUntil<=now and self.rng:NextNumber()<.45 then
			a.move=-toward
			if press(c,a,"Pursuit","back",0) then return true end
		end
		return false
	end
	local floating=target.reaction=="Launched" or target.reaction=="Juggled" or (target.reaction=="Knockback" and target.airborne)
	local sight=c:lineOfSight(a,target)
	if floating and sight and distance<32 then
		if cast("Kamaitachi") then return true end
		if distance<17 and tool and press(c,a,"Tool","neutral",0,target.root.Position) then return true end
	end
	-- Blades coming at her: the gust sends them back.
	if tool and Techniques.bladeIncoming(c,a,{Radius=6,Reach=16}) and self.rng:NextNumber()<.55 then
		if press(c,a,"Tool","neutral",0,target.root.Position) then return true end
	end
	-- Coming in fast inside her band: out on the wind before the body arrives.
	if threat and distance<tune.Close+5 and a.pursuitUntil<=now and self.rng:NextNumber()<.35 then
		a.move=-toward
		if press(c,a,"Pursuit","back",0) then return true end
	end
	if now>=(self.techReadyAt or 0) and sight and target.state~="Defeated" then
		local roll=self.rng:NextNumber()
		if distance<24 and threat and roll<.3 and cast("GreatGust") then return true end
		if distance>12 and distance<34 and closing>3 and roll<.5 then
			-- (where the body will be when the column rises: the signs, then the beat)
			if cast("Cyclone",target.root.Position+(target.locomotion or Vector3.zero)*.69) then return true end
		end
		-- (against a body coming in fast, from far enough that a dash into the
		-- channel meets the scythe)
		if distance>(if threat then 15 else 10) and distance<42 and roll<.7 and cast("Kamaitachi",lead) then return true end
	end
	-- Hold the band: inside it she backs off at an angle (a straight backpedal
	-- is slower than any approach), never walks into melee.
	if distance<(tune.Keep or tune.Close+6) then
		a.move=(-toward*.75+tangent*(self.strafeSign or 1)*.66).Unit;a.sprinting=distance<tune.Close+3
	end
	return true
end
function AI:update(now)
	local c,a=self.combat,self.actor; local target=a.target; local tune=Config.AI
	if c.match.phase~="Duel" or a.health<=0 or target.health<=0 then a.move=Vector3.zero; return end
	if now<self.nextTick then return end
	self.nextTick=now+tune.Tick
	-- No exemption from a shroud: lost in it, the bot aims at where it last saw him.
	if Families.shrouded(c,a) then a.fogAim=self.lastSeen or target.root.Position
	else a.fogAim=nil;self.lastSeen=target.root.Position end
	if a.state~="Rush" then self.feinted=nil end
	if self:defend(now) then return end
	-- Genjutsu: sometimes the bot sees through the decoy, sometimes it does not.
	if a.illusionUntil>now then
		if self.illusionSeen==nil then self.illusionSeen=self.rng:NextNumber()<.35 end
	else self.illusionSeen=nil end
	local fooled=a.decoyPosition and a.illusionUntil>now and not self.illusionSeen
	local position=if fooled then a.decoyPosition else target.root.Position
	local delta=position-a.root.Position; delta=Vector3.new(delta.X,0,delta.Z)
	local distance=delta.Magnitude; local toward=if distance>0.1 then delta.Unit else Vector3.zAxis
	-- Facing is Combat:faceLocked's job (the bot is locked like the player): a
	-- lookAt snap on every 0.18 s decision made the body pivot in visible jerks.
	local tangent=Vector3.new(-toward.Z,0,toward.X);local minato=a.def.Name=="Minato"
	local desired=a.def.PreferredRange or 7
	-- Rhythm: press for a while, then probe at range (spacing, reading), and
	-- breathe after a combo lands instead of restarting at once.
	if now>=(self.modeUntil or 0) then
		local wasProbing=self.probing
		self.probing=not self.probing and self.rng:NextNumber()<.55
		self.modeUntil=now+(if self.probing then 1.6+self.rng:NextNumber()*2 else 2.2+self.rng:NextNumber()*2.6)
		self.probeRange=8+self.rng:NextNumber()*12
		-- A probe often resolves into an entry: the press opens with a dash.
		if wasProbing and not self.probing then self.entryUntil=now+1.2 end
	end
	-- Against a zoner (a far longer preferred range than ours: Temari) waiting
	-- at range is losing: no probing, weave on the way in, dash from further,
	-- step out of a wind lane that blows against the approach (below).
	local zoner=(target.def.PreferredRange or 7)>=14 and (a.def.PreferredRange or 7)<12 and not a.def.Zoner
	if zoner then self.probing=false end
	local downed=target.reaction=="Knockdown" or target.reaction=="Wakeup" or (target.reaction=="Knockback" and target.airborne==false)
	if downed and not self.wasDowned and a.pursuitUntil<=now then self.breathUntil=now+.35+self.rng:NextNumber()*.5 end
	self.wasDowned=downed
	-- Got hit and out of it: back off into neutral (reset, tools, reads)
	-- instead of mashing straight back in.
	local hurt=a.reaction~=nil or a.state=="Stunned"
	if self.wasHurt and not hurt and self.rng:NextNumber()<tune.Disengage then
		self.probing=true;self.modeUntil=now+1.2+self.rng:NextNumber()*1.4;self.probeRange=10+self.rng:NextNumber()*8
	end
	self.wasHurt=hurt
	local calm=self.probing or now<(self.breathUntil or 0)
	-- Probing happens at tool range: spacing, throws and reads before running in.
	if self.probing then desired+=self.probeRange or 14 elseif calm then desired+=4 end
	-- Genjutsu image (Itachi's Mirage): hold the line behind the image while it
	-- stands; the opponent has to come to it (blades still fly through it).
	local holding=target.illusionBy==a and (target.illusionUntil or 0)>now
	if holding then desired=distance end
	local radial=if distance>desired+2 then 1 elseif distance<desired-2 then -0.6 else 0
	-- Lateral movement is committed for a beat, then changes side: readable
	-- repositioning, not a sine-wave drift around the opponent.
	if now>=(self.strafeUntil or 0) then
		self.strafeSign=if self.rng:NextNumber()<.5 then 1 else -1
		self.strafeUntil=now+.6+self.rng:NextNumber()*(if minato then .7 else 1.1)
		self.strafeAmount=if self.rng:NextNumber()<.2 then 0 else (if minato then .95 else .6)
	end
	-- Pressing in from range: straight at them, angling only on the last
	-- steps. Two sprinting fighters offset the same way (velocity turns at a
	-- bounded rate) orbit each other forever instead of meeting.
	local lateral=self.strafeAmount or .5
	if radial>0 and not calm then lateral*=if zoner then .8 elseif distance>desired+8 then 0 else .35 end
	if holding then lateral=0 end
	a.move=(toward*radial+tangent*(self.strafeSign or 1)*lateral)
	-- Standing in a wind lane that blows against the way in: out of it sideways.
	local outOfLane=radial>0 and laneAgainst(c,a,toward)
	if outOfLane then a.move=outOfLane+toward*.25;Brawler.event(c,a,"LaneAvoid") end
	-- Space is a resource: backing off drifts toward the open middle, so the
	-- wall is a choice (wall run, splat) and not where every retreat ends.
	local centre=(a.root.Position-c.match.origin)*Vector3.new(1,0,1)
	local edge=math.clamp((centre.Magnitude-(Config.ArenaRadius-45))/30,0,1)
	if edge>0 and radial<.5 and centre.Magnitude>.1 then a.move-=centre.Unit*edge*.9 end
	a.sprinting=distance>desired+6 and not calm
	if calm then a.move*=.7 end
	-- Step-in feint at probing range: two quick steps in, then out of reach,
	-- often with a blade on the way out.
	if self.feintOut then
		if now<self.feintOut then
			a.move=-toward+tangent*(self.strafeSign or 1)*.4;a.sprinting=false
			if edge>0 and centre.Magnitude>.1 then a.move-=centre.Unit*edge end
			if self.feintThrow and now>=self.feintThrow then self.feintThrow=nil;c:request(a,"Tool",target.root.Position) end
		else self.feintOut=nil end
	elseif self.feintIn then
		if now<self.feintIn then a.move=toward;a.sprinting=true
		else self.feintIn=nil;self.feintOut=now+.35+self.rng:NextNumber()*.2
			self.feintThrow=if self.rng:NextNumber()<.45 then now+.12 else nil
			Brawler.event(c,a,"FeintStep")
		end
	elseif self.probing and a.state=="Neutral" and not a.airborne and distance>9 and distance<19 and self.rng:NextNumber()<tune.Feint then
		self.feintIn=now+.22+self.rng:NextNumber()*.12
	end
	if a.move.Magnitude>1 then a.move=a.move.Unit end
	if now>=self.guardUntil and a.state=="Guarding" then c:request(a,"GuardOff") end
	-- Wall run: rise along the wall, then dive at the opponent.
	local fromCenter=(a.root.Position-c.match.origin)*Vector3.new(1,0,1)
	local outward=if fromCenter.Magnitude>.1 then fromCenter.Unit else Vector3.xAxis
	if a.wall then
		self.wallSince=self.wallSince or now
		local along=Vector3.new(-a.wall.normal.Z,0,a.wall.normal.X)
		a.move=(-a.wall.normal*.7+along*(self.wallSide or 1)*.7).Unit
		if now-self.wallSince>.3 and (target.root.Position-a.root.Position).Magnitude<=Config.Wall.DiveRange and self.rng:NextNumber()<.55 then
			c:request(a,"Attack")
		end
		return
	end
	self.wallSince=nil
	if self.wallRun and now<self.wallRun and a.state=="Neutral" and not a.reaction then
		a.move=(outward+tangent*.25).Unit;a.sprinting=true
		return
	end
	if fromCenter.Magnitude>Config.ArenaRadius-22 and distance>11 and distance<44 and a.state=="Neutral" and not a.airborne and self.rng:NextNumber()<tune.WallRun then
		self.wallRun=now+1.1;self.wallSide=if self.rng:NextNumber()<.5 then 1 else -1
		return
	end
	if target.state~=self.observed then
  if target.state=="Startup" or target.state=="TechniqueChannel" then self.threatAt=now end
  self.observed=target.state;self.observedAt=now
 end
	-- Reads: an opponent stepping into melee range is answered before the
	-- strike lands. Not a reaction (no latency): a guess, taken once per entry
	-- - guard (a parry when the timing lands), sidestep or counter-poke.
	local closing=(target.locomotion or Vector3.zero):Dot(-toward)
	local entering=distance<8.5 and (self.lastDistance or 99)>=8.5 and closing>4
	self.lastDistance=distance
	local free=a.state=="Neutral" and not a.reaction and not a.airborne
	-- A zoner plays her own range game (AI:zone) before any melee logic.
	if a.def.Zoner and self:zone(now,distance,toward,tangent,target) then return end
	if entering and free then
		local roll=self.rng:NextNumber()
		if roll<tune.ReadGuard then
			c:request(a,"Guard");self.guardUntil=now+.42;return
		elseif roll<tune.ReadGuard+tune.ReadDodge and a.dodgeUntil<=now then
			a.move=tangent*(self.strafeSign or 1)
			if c:request(a,"Dodge") then return end
		elseif roll<tune.ReadGuard+tune.ReadDodge+tune.ReadPoke and distance<7.5 then
			if c:request(a,"Attack") then return end
		end
	end
	-- Toe to toe with a fighter who is not swinging yet: sometimes hold a
	-- guard in anticipation (a parry if the strike comes right then).
	if free and distance<7 and target.state=="Neutral" and not target.reaction and self.rng:NextNumber()<tune.GuardRead then
		c:request(a,"Guard");self.guardUntil=now+.28+self.rng:NextNumber()*.22;return
	end
	local reacted=now-self.observedAt>=tune.Reaction
	local danger=target.state=="Startup" or target.state=="TechniqueChannel"
	local reactedThreat=reacted and (target.state=="Startup" or target.state=="Active")
 -- Remember the wind-up through Active/Recovery: short attacks used to erase
 -- the observation before reaction latency elapsed, so defense never fired.
 local remembered=self.threatAt and now-self.threatAt>=tune.Reaction and now-self.threatAt<.9
 if remembered and distance<9 and a.state=="Neutral" and not a.reaction then
  self.threatAt=nil
  if target.state=="Recovery" then
   a.move=toward;a.sprinting=true
   if distance<6 then c:request(a,"Attack") else c:request(a,"Dodge") end
  elseif minato then
   a.move=tangent;c:request(a,"Dodge")
  else
   c:request(a,"Guard");self.guardUntil=now+.36
  end
  return
 end
	-- Neji: a strike about to land at close range is a Rotation read.
	if reactedThreat and a.state=="Neutral" and distance<6.5 and slotOf(a,"Rotation") and self.rng:NextNumber()<.3 then
		if c:request(a,(slotOf(a,"Rotation"))) then return end
	end
	if a.state=="Startup" and a.attackName=="Heavy" and now-a.attackStarted>.08 and self.rng:NextNumber()<(if minato then .18 else .3) then c:request(a,"Feint");return end
	-- A newly observed telegraph may alter movement, but cannot trigger an
	-- instant defensive action or coincidental interrupt before reaction latency.
	if danger and not reacted then return end
	if reacted and danger and distance<9 then
		if target.state=="TechniqueChannel" and distance<=6.8 and self.rng:NextNumber()<tune.Aggression then
			c:request(a,"Attack"); return
		end
		if self.rng:NextNumber()<tune.Defense then
			if self.rng:NextNumber()<0.45 then c:request(a,"Dodge")
			else c:request(a,"Guard"); self.guardUntil=now+0.5 end
			return
		end
	end
	if a.grabVictim then c:request(a,if self.rng:NextNumber()<.4 then "Heavy" else "Attack");return end
	-- Re-engage: Itachi sometimes turns his dash into a feint (a guard and a
	-- read) instead of arriving; on arrival the bot converts with the dash
	-- strike, the quick heavy or, close to a guard, a grab.
	if a.state=="Rush" then
		if a.fighterId=="Mirage" and not self.feinted and distance<10 then
			self.feinted=true
			if self.rng:NextNumber()<.3 and c:request(a,"Guard") then self.guardUntil=now+.3;return end
		end
		press(c,a,"Attack");return
	end
	if (a.rushArriveUntil or 0)>now and not a.airborne then
		local roll=self.rng:NextNumber()
		if target.state=="Guarding" and distance<4.5 and roll<.45 then press(c,a,"Grab")
		elseif roll<.2 then press(c,a,"Heavy")
		else press(c,a,"Attack") end
		return
	end
	-- Sasuke under the rising body: one strike, then the Lion Combo.
	if (a.lionUntil or 0)>now and a.airborne and a.state=="Neutral" then
		press(c,a,if (a.airCombo or 0)>=1 and self.rng:NextNumber()<.7 then "Heavy" else "Attack");return
	end
	-- Wired opponent: the current down the wire first when the reserve pays
	-- for both (it holds the body longer, ChakraCombat.conduct), then the
	-- Dragon Flame along it. The current is a tool action, not a jutsu.
	local wired=a.wireVictim
	if wired and wired.reaction=="Bound" and wired.boundBy==a and (a.state=="Neutral" or a.state=="TechniqueRecovery") then
		local fire,spec=slotOf(a,"FireBloom")
		local current=Chakra.plan(c,a,"Shuriken")
		if current and current.mode=="conduct" and (wired.wireConducts or 0)==0 and a.chakra>=Chakra.cost(current,false)+(spec and spec.Cost or 0)
			and c:request(a,"Tool",nil,nil,{chakra=true}) then return end
		if fire and c:request(a,fire,target.root.Position) then return end
	end
	-- His stretched wire with the opponent standing by it: lightning thrown
	-- at the wire charges it (and the trap is live), once per wire.
	if a.state=="Neutral" and not target.airborne then
		for _,w in c.projectiles do
			if w.a==a and w.planted=="wire" and not w.dead and not w.charged then
				self.armed=self.armed or {}
				local far=w.origin+w.direction*w.range
				local ab=far-w.origin
				local k=math.clamp((target.root.Position-w.origin):Dot(ab)/math.max(ab:Dot(ab),1e-6),0,1)
				local spot=w.origin+ab*k
				local gap=(target.root.Position-spot)*Vector3.new(1,0,1)
				if not self.armed[w.id] and gap.Magnitude<8 then
					self.armed[w.id]=true
					local plan=Chakra.plan(c,a,"Shuriken")
					if plan and plan.mode=="throw" and plan.tags.lightning and a.chakra>=Chakra.cost(plan,false)+10
						and c:request(a,"Tool",spot,nil,{chakra=true}) then return end
				end
			end
		end
	end
	-- A read that landed (Read or a caught genjutsu): cash it in.
	-- A counter with a reach (a caught genjutsu image, a repelled strike) glides to the body.
	local counterRange=8+(if a.counterReach and a.counterReach.expires>now then a.counterReach.max else 0)
	if (a.counterUntil or 0)>now and distance<counterRange then a.move=toward;c:request(a,"Attack");return end
	-- Flying Thunder God arrival: strike from the new angle, or Rasengan at once.
	if (a.flashUntil or 0)>now then
		local rasengan=slotOf(a,"BurstStrike")
		if rasengan and self.rng:NextNumber()<.35 and c:request(a,rasengan) then return end
		c:request(a,if self.rng:NextNumber()<.3 then "Heavy" else "Attack");return
	end
	-- The opponent is pinned against a wall: pursue, extend, bounce or pin it.
	if target.reaction=="WallSplat" then
		local gap=(target.root.Position-a.root.Position).Magnitude
		if gap<7 then a.move=toward;c:request(a,if self.rng:NextNumber()<.45 then "Heavy" else "Attack");return end
		if a.pursuitUntil>now and gap<Config.PursuitRange and c:request(a,"Pursuit") then return end
		if not minato and gap<32 and c:request(a,"Tool",target.root.Position) then return end
		a.move=toward;a.sprinting=true;return
	end
	-- A marked kunai that is about to pass the opponent is a teleport cue.
	if minato and a.state=="Neutral" then
		local seal=Techniques.sealOf(c,a,now)
		if seal and (seal-target.root.Position).Magnitude<7 and (c:markedInFlight(a) or self.rng:NextNumber()<.5) then
			local slot=slotOf(a,"Flashstep")
			if slot and c:request(a,slot) then return end
		end
	end
	-- A body launched straight up above him is out of reach too: the flat
	-- distance stays short while it rises (Naruto's barrage, a pillar).
	local above=target.airborne and target.root.Position.Y-a.root.Position.Y>4
	if a.pursuitUntil>now and (distance>8 or above) and distance<Config.PursuitRange and self.rng:NextNumber()<(CHASE[a.fighterId] or .58) then
		c:request(a,"Pursuit"); return
	end
	if a.state=="Recovery" and a.chainOpen then
		-- In the air Minato may finish with a plunging Rasengan instead of the slam.
		if a.airborne and minato and (a.airCombo or 0)>=1 and self.rng:NextNumber()<.25 then
			local rasengan=slotOf(a,"BurstStrike")
			if rasengan and c:request(a,rasengan) then return end
		end
		-- The directional grammar: the stick picks the route, so the bot sets it
		-- explicitly (an approach held by accident must not pick a launcher).
		local roll=self.rng:NextNumber()
		if a.airborne then
			-- A fighter with its own air finisher (Rock Lee's lotuses) cashes it in
			-- after one confirmed hit inside the Shadow of the Dancing Leaf window.
			if (a.lionUntil or 0)>now and (a.airCombo or 0)>=1 and (Brawler.graph(a) or {}).airFinisher and roll<.75 then a.move=Vector3.zero;press(c,a,"Heavy");return end
			if (a.airCombo or 0)>=2 and roll<.4 then a.move=Vector3.zero;press(c,a,"Heavy");return end
			if (a.airCombo or 0)>=1 then
				if roll<.22 then a.move=-toward;press(c,a,"Attack","back");return
				elseif roll<.42 then a.move=toward;press(c,a,"Attack","forward");return
				elseif roll<.54 then
					local sign=if self.rng:NextNumber()<.5 then 1 else -1
					a.move=tangent*sign;press(c,a,"Attack","side",sign);return
				end
			end
			a.move=Vector3.zero;press(c,a,"Attack");return
		end
		-- Neji: end a string with Vacuum Palm.
		if a.fighterId=="GentleFist" and a.combo>=2 and roll<.18 then
			local palm=slotOf(a,"VacuumPalm")
			if palm and c:request(a,palm,target.root.Position) then return end
		end
		local nearWall=fromCenter.Magnitude>Config.ArenaRadius-22
		if a.combo>=2 then
			if roll<.3 then a.move=toward;press(c,a,"Attack","forward");return end -- launcher
			if roll<.46 then a.move=-toward;press(c,a,"Attack","back");return end -- low route
			if roll<.56 then a.move=Vector3.zero;press(c,a,"Heavy");return end
		elseif a.combo==1 and roll<.2 then a.move=Vector3.zero;press(c,a,"Heavy");return end
		if roll<.7 and roll>=.56 then
			local sign=if self.rng:NextNumber()<.5 then 1 else -1
			a.move=tangent*sign;press(c,a,"Attack","side",sign);return
		end
		if roll>=.92 then
			-- Tool inside the string; away + tool hops out behind it.
			local away=not nearWall and self.rng:NextNumber()>=.5
			a.move=if away then -toward else Vector3.zero
			press(c,a,"Tool",if away then "back" else "neutral",0,target.root.Position);return
		end
		a.move=Vector3.zero;press(c,a,"Attack");return
	end
	if a.state~="Neutral" or a.reaction then return end
	-- Bodies (Naruto's clones): a clone winding up a jab close by is struck
	-- first (the stick aims the opener at it), one merely close now and then.
	local body=not a.airborne and Bodies.threat(c,a,6.5)
	if body and self.rng:NextNumber()<(if body.state=="Startup" then .8 else .3) then
		local to=Vector3.new(body.position.X-a.root.Position.X,0,body.position.Z-a.root.Position.Z)
		if to.Magnitude>.5 then a.move=to.Unit;if c:request(a,"Attack") then return end end
	end
	if a.chakra<18 then a.move=-toward+tangent*0.2; return end
	-- (Rock Lee has no blade to probe with: his tool is the deflecting kick.)
	if distance>7 and distance<46 and a.def.Tool~="Deflect" and self.rng:NextNumber()<(if a.def.Name=="Itachi" then 0.11 else 0.09)*(if self.probing then tune.ProbeTool else 1) and target.state~="Guarding" then
		-- A tool master sometimes throws the geometry instead (side + tool).
		if a.def.ToolMastery and a.def.ToolMastery.Geometry and self.rng:NextNumber()<.4 then
			a.move=tangent*(if self.rng:NextNumber()<.5 then 1 else -1)
		end
		-- Chakra tool (isolated, no extra roll): every third probing throw with a
		-- comfortable reserve is infused; a body-chakra fighter (Neji) keeps the blade.
		self.probeThrows=(self.probeThrows or 0)+1
		local infuse=self.probeThrows%3==0 and not a.def.GentleFist and a.chakra>=(a.def.Chakra or Config.Chakra)*.6
		if c:request(a,"Tool",target.root.Position,nil,if infuse then {chakra=true} else nil) then return end
	end
	-- Choose by capabilities/technique identifiers, never by a second bot combat engine.
	-- Jutsu are paced: after one, a few seconds of movement, tools and reads
	-- before the next. A close punish (stunned, bound, or recovering within
	-- reach) is not; a recovery seen from range is still neutral.
	local punish=target.state=="Stunned" or target.reaction=="Bound"
		or ((target.state=="Recovery" or target.state=="TechniqueRecovery") and distance<7)
	if self.rng:NextNumber()<tune.Technique and (now>=(self.techReadyAt or 0) or punish) then
		-- A kit made only of family techniques is scanned from a rotating slot
		-- (the whole kit gets used, not slot 1 first); a kit with bespoke
		-- techniques keeps its authored priority order.
		local count=#a.def.Techniques
		local rotate=true
		for _,spec in a.def.Techniques do if not spec.Family then rotate=false end end
		self.techStart=if rotate then ((self.techStart or 0)%math.max(count,1))+1 else 1
		for k=0,count-1 do
			local slot=((self.techStart+k-1)%count)+1
			local spec=a.def.Techniques[slot]
			local use=false; local aim=target.root.Position
			if spec.Id=="MarkedBlade" then use=plantedSeals(a)<2 and not c:markedInFlight(a) and distance>8; aim=position+target.hum.MoveDirection*3
			elseif spec.Id=="Flashstep" then local seal=Techniques.sealOf(c,a,now);use=seal~=nil and (distance>14 or (seal-target.root.Position).Magnitude<7)
			elseif spec.Id=="BurstStrike" then use=distance<7 and (target.state=="Recovery" or target.state=="Stunned" or target.state=="TechniqueRecovery")
			elseif spec.Id=="Read" then use=distance<8 and danger and reacted
			elseif spec.Id=="NeedleFan" then use=distance>8 and distance<36
			elseif spec.Id=="MirageCast" then use=distance>10 and distance<21 and (target.state=="Recovery" or target.state=="Guarding" or self.rng:NextNumber()<0.18) end
			if spec.Id=="FireBloom" then use=distance>6 and distance<46 and c:lineOfSight(a,target) and (target.state=="Recovery" or target.state=="TechniqueChannel" or self.rng:NextNumber()<0.32) end
			if spec.Id=="WireTrap" then use=distance>7 and distance<28 and c:lineOfSight(a,target) and self.rng:NextNumber()<.4 end
			if spec.Id=="Chidori" then use=distance>4 and distance<16 and (target.state=="Recovery" or target.state=="TechniqueRecovery" or target.state=="Stunned" or target.reaction=="Bound" or self.rng:NextNumber()<.06) end
			if spec.Id=="FireBloom" and a.wireVictim and a.wireVictim.reaction=="Bound" then use=true end
			if spec.Id=="SandCoffin" then use=distance>7 and distance<28 and c:lineOfSight(a,target) and self.rng:NextNumber()<.45 end
			if spec.Id=="SandShuriken" then use=distance>9 and distance<34 and self.rng:NextNumber()<.5 end
			if spec.Id=="DesertWave" then use=distance<8 and (target.state=="Startup" or target.state=="Rush" or target.state=="Active" or self.rng:NextNumber()<.25) end
			if spec.Id=="VacuumPalm" then use=distance>7 and distance<24 and c:lineOfSight(a,target) and self.rng:NextNumber()<.45 end
			if spec.Id=="SixtyFourPalms" then use=distance<4.6 and (target.state=="Recovery" or target.state=="Stunned" or target.state=="TechniqueRecovery" or target.state=="TechniqueChannel") end
			if spec.Id=="Rotation" then use=false end
			if spec.Id=="PhoenixFlower" then use=distance>9 and distance<34 and c:lineOfSight(a,target) and self.rng:NextNumber()<.5 end
			if spec.Id=="WindCut" then use=distance>8 and distance<28 end
			if spec.Id=="Quickstep" then use=distance>9 and distance<20 and self.rng:NextNumber()<0.25 end
			-- Rock Lee (stress-test wave): the spinning kick crosses a gap or
			-- punishes a recovery, in line of sight; nothing he has is thrown.
			if spec.Id=="LeafGreatWhirlwind" then use=distance>5 and distance<16 and c:lineOfSight(a,target)
				and (target.state=="Recovery" or target.state=="TechniqueChannel" or target.state=="TechniqueRecovery" or self.rng:NextNumber()<.4) end
			-- Naruto (roster wave): clones out in neutral (two at most), a pair
			-- charging from mid range, the Rasengan on an opening or with a clone
			-- out to shape it.
			-- (With none out, now and then he holds the single clone for the pair.)
			if spec.Id=="ShadowClone" then local out=Bodies.count(c,a,"clone");use=distance>4 and distance<26 and out<2 and a.chakra>=36 and (out>0 or self.rng:NextNumber()<.6) end
			if spec.Id=="MassShadowClone" then use=distance>7 and distance<22 and Bodies.count(c,a,"clone")==0 and a.chakra>=70 and self.rng:NextNumber()<.5 end
			if spec.Id=="CloneRasengan" then use=distance<9 and (target.state=="Recovery" or target.state=="Stunned" or target.state=="TechniqueRecovery"
				or (Bodies.count(c,a,"clone")>0 and self.rng:NextNumber()<.35)) end
			if spec.Family and not use then use=familyWants(self,c,a,target,spec,distance,danger) end
			if use and c:request(a,"Technique"..slot,aim) then
				self.techReadyAt=now+(tune.TechniqueGap or 0)+self.rng:NextNumber()*(tune.TechniqueJitter or 0);return
			end
		end
	end
	local whiff=target.state=="Recovery" and (target.attackName=="Heavy" or not target.hitConfirmed)
	if whiff and distance<10 then a.move=toward;a.sprinting=true;c:request(a,"Attack");return end
	-- Probing or breathing: no fresh melee initiation, only punishes and reads.
	if calm then return end
	local reach=(a.def.AttackProfile and a.def.AttackProfile.Light1 and a.def.AttackProfile.Light1.range or 6)+1.5
	-- A body on the floor with wake-up cover cannot be hit: no swings at it.
	local covered=target.groundPose~=nil and (target.invulnerableUntil or 0)>now
	if covered then return end
	-- Ninja Embodiment (EMB-002): an entry is a plan, not a walk into the
	-- string. Out of a run (the running strike), over the top (the drop
	-- strike on the way down), round a committed body to its side, or
	-- straight in. The strike then reads the situation the plan made.
	if not self.plan and free and distance>6.5 and distance<13 and self.rng:NextNumber()<(tune.Plan or 0) then
		local roll=self.rng:NextNumber()
		local committed=target.state=="Recovery" or target.state=="TechniqueChannel" or target.state=="TechniqueRecovery" or target.state=="Startup"
		self.plan=if committed and roll<.45 then "flank" elseif roll<.45 then "run" elseif roll<.75 then "jump" else "straight"
		self.planUntil=now+1.4;self.planSide=self.strafeSign or 1
		Brawler.event(c,a,"Plan:"..self.plan)
		if self.plan=="jump" then a.move=toward;c:request(a,"Jump") end
	end
	if self.plan and (now>(self.planUntil or 0) or a.reaction) then self.plan=nil end
	if self.plan=="run" then
		a.move=toward;a.sprinting=false
		if distance<9 and distance>3.5 and c:request(a,"Attack") then self.plan=nil end
		return
	elseif self.plan=="jump" then
		a.move=toward
		local vy=a.root.AssemblyLinearVelocity.Y
		local above=a.root.Position.Y-target.root.Position.Y
		if a.airborne and vy<-6 and distance<6.5 and above>1.5 and above<=6 then
			if c:request(a,"Attack") then self.plan=nil end
		elseif not a.airborne and now>(self.planUntil or 0)-1.1 then self.plan=nil end
		return
	elseif self.plan=="flank" then
		a.move=(tangent*(self.planSide or 1)+toward*.45).Unit
		if distance<5.5 and c:request(a,"Attack") then self.plan=nil end
		return
	elseif self.plan=="straight" then self.plan=nil end
	if distance<math.max(8,reach) and self.rng:NextNumber()<tune.Aggression then
		c:request(a,if a.grabVictim then "Attack" elseif distance<5 and self.rng:NextNumber()<.12 then "Grab" elseif self.rng:NextNumber()<.16 then "Heavy" else "Attack")
	end
	-- Out-ranged (sand lashes): close the gap instead of waiting at its edge.
	local theirs=(target.def.AttackProfile and target.def.AttackProfile.Light1 and target.def.AttackProfile.Light1.range or 6)
	if theirs>reach and distance>reach-1 and distance<theirs+3 and target.state~="Startup" then
		a.move=toward;a.sprinting=true
		if distance>Config.Rush.MinRange+.5 and self.rng:NextNumber()<.3 and not laneOnPath(c,a,target) and c:request(a,"Pursuit") then return end
		if self.rng:NextNumber()<.2 then c:request(a,"Dodge");return end
	end
	if distance>6 and distance<17 and self.rng:NextNumber()<0.1 then c:request(a,"Jump") end
	-- Chakra dash in from mid range when the opponent is not attacking (nor
	-- holding a guard the arrival would run into); Neji closes in from closer.
	local dashFrom=if a.fighterId=="GentleFist" then 7.5 else 11
	-- Keener at the start of a press and from far away (walking twenty studs
	-- into a zoner is the slow answer).
	local keen=.1*(DASH[a.fighterId] or 1)
	if (self.entryUntil or 0)>now then keen*=4 elseif distance>desired+10 then keen*=2 end
	if zoner then keen*=1.3 end
	if not calm and distance>dashFrom and distance<44 and target.state~="Startup" and target.state~="TechniqueChannel" and target.state~="Guarding"
		and self.rng:NextNumber()<keen and not laneOnPath(c,a,target) then
		if c:request(a,"Pursuit") then self.entryUntil=nil;return end
	end
	-- Sidestep cover when the direct route is obstructed.
	local block=workspace:Raycast(a.root.Position,toward*6,c:rayParams(true))
	if block then a.move=tangent; c:request(a,"Jump") end
end
return AI
