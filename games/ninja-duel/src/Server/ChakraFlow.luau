-- ChakraFlow: chakra into whatever the body does next (Freedom, user 28/10:
-- "la liberté, c'est les infusions de chakra").
--
-- Hold the chakra modifier alone (pad R1, keyboard Z) and the body LOADS its
-- chakra: it glows in its nature for Tune.Life seconds. The next action spends
-- the load and comes out infused, whatever it is and wherever the body is:
--   strike  (light, heavy, run, air, the drawn kunai): harder, longer, and its
--           nature on contact (lightning stuns longer, fire burns, wind throws
--           further, the gentle fist closes a point, raw strength crushes)
--   jump    a chakra leap: higher and further (Naruto's rooftop bounds)
--   dodge   a chakra dash at the opponent, on the ground (the re-engage
--           without sprint or lock) or IN THE AIR (the chase, out of any
--           window: air combat that goes to him)
--   tool    the fighter's own chakra throw (ChakraCombat), no chord needed
-- References: the Storm games' chakra charge / chakra dash, Shinobi
-- Striker's chakra-infused basic attacks; in the series Kakashi's and
-- Sasuke's chakra flow through a blade, Asuma's wind blade, Naruto's leaps,
-- Tsunade's and Sakura's chakra fists.
-- Server-authoritative: the client only says "load"; nature, cost and every
-- consequence are decided here.
local ChakraFlow={}
local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)

ChakraFlow.Tune={
	Life=2.4,          -- seconds a load lasts unused
	Strike=10,         -- chakra an infused strike costs
	Leap=6,            -- an infused jump
	Damage=1.3,        -- strike damage scale (Heavy-type enders: HeavyDamage)
	HeavyDamage=1.45,
	Reach=.8,          -- extra range / depth (studs)
	Impulse=1.2,       -- knockback scale
	LeapUp=1.2,        -- jump vertical scale (apex about x1.5: Studio 18 -> 27 studs)
	LeapCarry=1.35,    -- jump horizontal scale
}
local T=ChakraFlow.Tune
-- Each fighter's chakra nature and its signature moves live in
-- Shared/ChakraMoves (05/11: the HUD names them while the button is held).
local ChakraMoves=require(game:GetService("ReplicatedStorage").NinjaDuel.ChakraMoves)
ChakraFlow.Nature=ChakraMoves.Nature
ChakraFlow.Label=ChakraMoves.Label
-- What a nature does to the strike itself (on top of the common scaling).
local SHAPE={
	Wind={reach=1.6,impulse=1.45},      -- a blade of wind past the fist
	Strength={impulse=1.6},             -- the body thrown much further
	Lightning={reach=.4},
	-- (Stage 6) Gaara's hardened sand: longer lashes (and they slow, ChakraFlow.hit).
	Fire={},Sand={reach=2,impulse=1.15},GentleFist={},Chakra={},
}
ChakraFlow.Signature=ChakraMoves.Signature
ChakraFlow.SigLabel=ChakraMoves.SigLabel
-- What a signature adds to the strike's own reach and push.
local SIG_SHAPE={FireJet={reach=2.5},SandFist={reach=2.5},Vacuum={reach=4,impulse=1.5},Rasengan={impulse=1.3}}
function ChakraFlow.signature(a,slot)
	local sig=ChakraFlow.Signature[a.fighterId]
	return sig and sig[slot] or nil
end
local NOT_STRIKES={Grab=true,Throw=true,ThrowUp=true}
local HEAVY={Heavy=true,DashAttack=true,Slam=true,Launcher=true,Light3=true,AirFlip=true,FlyingKick=true,WallDive=true}

function ChakraFlow.nature(a)
	return ChakraFlow.Nature[a.fighterId] or "Chakra"
end
function ChakraFlow.active(c,a)
	local load=a.chakraLoad
	if not load then return nil end
	if c.now>load.untilTime then a.chakraLoad=nil;return nil end
	return load
end
-- The modifier held alone: load. A load already there is refreshed.
function ChakraFlow.load(c,a)
	if a.health<=0 or a.reaction then return false,"Reacting" end
	if a.chakra<math.min(T.Strike,T.Leap) then
		c:cue(a,"NOT ENOUGH CHAKRA",.5)
		return false,"Need chakra"
	end
	local fresh=ChakraFlow.active(c,a)==nil
	local nature=ChakraFlow.nature(a)
	a.chakraLoad={untilTime=c.now+T.Life,nature=nature,at=c.now}
	if fresh then
		c:pushImpact(a.root.Position,"chakraload",false,{owner=a.id,fighter=a.fighterId,nature=nature})
		-- (05/11: Minato's plain chakra read "CHAKRA • CHAKRA")
		c:cue(a,if nature=="Chakra" then "CHAKRA" else "CHAKRA • "..ChakraFlow.Label[nature],.6)
		require(script.Parent.Brawler).event(c,a,"ChakraLoad")
	end
	return true
end
-- Spends the load (and its cost) when the body can pay; nil otherwise.
local function spend(c,a,cost)
	local load=ChakraFlow.active(c,a)
	if not load or a.chakra<cost then return nil end
	a.chakraLoad=nil
	a.chakra-=cost
	return load.nature
end
ChakraFlow.spend=spend

-- (05/11: the screen read "CHAKRA • LIGHT1") A move's name for the player:
-- the strings' blows are a strike, the rest split into words.
function ChakraFlow.moveLabel(name)
	local base=string.gsub(tostring(name),"%d+$","")
	if base=="Light" then return "STRIKE" end
	if base=="Air" then return "AIR STRIKE" end
	return string.upper((string.gsub(base,"(%l)(%u)","%1 %2")))
end
-- Brawler.start: the strike about to come out takes the load.
function ChakraFlow.strike(c,a,name,spec)
	if NOT_STRIKES[name] then return nil end
	local nature=spend(c,a,T.Strike)
	if not nature then return nil end
	-- (Stage 6) Sasuke's two natures: fire on his kicks, lightning elsewhere.
	if a.fighterId=="Lion" and spec.kind=="kick" then nature="Fire" end
	local shape=SHAPE[nature] or {}
	-- (Gaara's heavy is his sand hand)
	local sig=ChakraFlow.signature(a,if HEAVY[name] or name=="SandHand" then "heavy" else "light")
	spec.chakraSig=sig
	local sigShape=sig and SIG_SHAPE[sig] or {}
	spec.damageScale=(spec.damageScale or 1)*(if HEAVY[name] then T.HeavyDamage else T.Damage)
	local reach=T.Reach+(shape.reach or 0)+(sigShape.reach or 0)
	-- (Stage 6) B + L2: a drawn blade carries the chakra further (Kakashi's
	-- white-chakra tanto grows).
	if a.armed and a.def.Weapon then reach+=1.5 end
	spec.range=(spec.range or 5)+reach
	spec.depth=(spec.depth or 2)+reach
	spec.impulse=spec.impulse*(T.Impulse*(shape.impulse or 1)*(sigShape.impulse or 1))
	c:pushImpact(a.root.Position,"chakrastrike",false,{owner=a.id,fighter=a.fighterId,nature=nature,move=name,sig=sig})
	c:cue(a,if sig then ChakraFlow.SigLabel[sig] else ChakraFlow.Label[nature].." • "..ChakraFlow.moveLabel(name),.5)
	return nature
end

local function brawler() return require(script.Parent.Brawler) end
local function line(a,b)
	local d=b.root.Position-a.root.Position
	d=Vector3.new(d.X,0,d.Z)
	return if d.Magnitude>.05 then d.Unit else Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z).Unit
end
local function live(c,a,b) return a.health>0 and b.health>0 and c.match.phase=="Duel" end
-- What each signature does on contact (after the nature's common effect).
ChakraFlow.OnHit={
	Nagashi=function(c,a,b,p,guarded)
		-- the current runs through the guard and holds the body a beat
		if guarded then b.hitstopUntil=math.max(b.hitstopUntil or 0,c.now+.18);c:chip(a,b,3);c:cue(b,"SHOCKED",.4)
		elseif b.reaction and b.reactionUntil then b.reactionUntil+=.25 end
	end,
	CloneStrike=function(c,a,b,p,guarded)
		-- a clone pops beside him and kicks him on (the clones' own barrage
		-- kick: Legion's controller lands it, juggling him for the follow-up)
		local Bodies=require(script.Parent.Bodies)
		local dir=line(a,b)
		local side=if math.floor(c.now*10)%2==0 then 1 else -1
		local body=Bodies.spawn(c,a,{kind="clone",position=b.root.Position+dir:Cross(Vector3.yAxis)*side*2.3-Vector3.new(0,1.1,0),
			ephemeral=true,life=.5,mode="barrage",state="Startup",action="BarrageKick"})
		if body then body.line=dir:Cross(Vector3.yAxis)*side;body.angle=0;body.syllable="" end
	end,
	Uzumaki=function(c,a,b,p,guarded)
		if guarded then return end
		local dir=line(a,b)
		brawler().react(c,b,"Launched",dir*5+Vector3.new(0,52,0),1.05,a)
		a.pursuitUntil=c.now+1.1
		local Bodies=require(script.Parent.Bodies)
		for k=-1,1,2 do
			local body=Bodies.spawn(c,a,{kind="clone",position=b.root.Position+dir:Cross(Vector3.yAxis)*k*1.6-Vector3.new(0,1.2,0),ephemeral=true,life=.42,mode="barrage",state="Active",action="BarrageKick"})
			if body then body.line=dir;body.angle=0;body.syllable="" end
		end
	end,
	SandGrip=function(c,a,b,p,guarded)
		if guarded then b.slowUntil=math.max(b.slowUntil or 0,c.now+1.2);b.slowScale=.6 return end
		-- the sand holds him where the hand would have thrown him down
		if b.reaction=="Knockdown" then b.invulnerableUntil=c.now;b.groundPose=nil;b.airborne=false end
		require(script.Parent.Families).bind(c,a,b,{Bind=.8,Kind="sand",Name="Sand Grip"})
	end,
	Flurry=function(c,a,b,p,guarded)
		-- three more fists in a blink; the last one pushes
		local dir=line(a,b)
		for k=1,3 do
			c:schedule(c.now+.065*k,function()
				if not live(c,a,b) then return end
				if (b.root.Position-a.root.Position).Magnitude>7 then return end
				c.damageTag="ChakraFlurry";c:chip(a,b,if guarded or b.state=="Guarding" then .8 else 2.2);c.damageTag=nil
				b.hitstopUntil=math.max(b.hitstopUntil or 0,c.now+.035)
				c:pushImpact(b.root.Position+Vector3.new(0,.4*k-.6,0),"chakrahit",k==3,{owner=a.id,victim=b.id,fighter=a.fighterId,nature="Strength",sig="Flurry",direction=dir})
				if k==3 and not guarded and b.state~="Guarding" then brawler().react(c,b,"Knockback",dir*30+Vector3.new(0,6,0),.35,a) end
			end)
		end
	end,
	GuardCrush=function(c,a,b,p,guarded)
		if not guarded then return end
		b.guardHeld=false
		brawler().react(c,b,"HitStun",Vector3.zero,.5,a)
		c:chip(a,b,3);c:cue(b,"GUARD BROKEN",.6);c:cue(a,"GUARD CRUSH",.5)
	end,
	Crows=function(c,a,b,p,guarded)
		if guarded then return end
		b.illusionUntil=math.max(b.illusionUntil or 0,c.now+1.1);b.illusionKind="crows"
		c:cue(b,"CROWS • GENJUTSU",.6)
	end,
	Rasengan=function(c,a,b,p,guarded)
		local dir=line(a,b)
		if guarded then b.guardSlide={dir=dir,remaining=4,speed=40};c:chip(a,b,3) return end
		c.damageTag="ChakraRasengan";c:chip(a,b,6);c.damageTag=nil
		brawler().react(c,b,"Knockback",dir*58+Vector3.new(0,14,0),.7,a)
	end,
	EarthSpike=function(c,a,b,p,guarded)
		if guarded then b.guardSlide={dir=line(a,b),remaining=1.5,speed=20} return end
		brawler().react(c,b,"Launched",Vector3.new(0,48,0),1.0,a)
		a.pursuitUntil=c.now+1.1
		c:pushImpact(b.root.Position-Vector3.new(0,2.6,0),"chakrahit",true,{owner=a.id,victim=b.id,fighter=a.fighterId,nature="Earth",sig="EarthSpike",direction=Vector3.yAxis})
	end,
}
-- Brawler.hit: the nature on contact (clean or guarded).
function ChakraFlow.hit(c,a,b,p,guarded)
	local nature=p.chakraFlow
	if not nature or b.health<=0 then return end
	local sig=p.spec and p.spec.chakraSig
	if sig and ChakraFlow.OnHit[sig] then
		local hook=ChakraFlow.OnHit[sig]
		c:schedule(c.now,function() if b.health>0 then hook(c,a,b,p,guarded) end end)
	end
	c:pushImpact(b.root.Position,"chakrahit",HEAVY[p.name]==true,{owner=a.id,victim=b.id,fighter=a.fighterId,nature=nature,guarded=guarded,direction=a.root.CFrame.LookVector})
	if guarded then
		-- Chakra through the guard: the guard pays in chakra; lightning and the
		-- gentle fist go through as a little damage.
		b.chakra=math.max(0,b.chakra-(if nature=="GentleFist" then 18 else 12))
		if nature=="Lightning" or nature=="GentleFist" then c:chip(a,b,2) end
		if nature=="Strength" or nature=="Wind" then
			local dir=Vector3.new(a.root.CFrame.LookVector.X,0,a.root.CFrame.LookVector.Z)
			if dir.Magnitude>.05 then b.guardSlide={dir=dir.Unit,remaining=2.6,speed=30} end
		end
		return
	end
	if nature=="Lightning" then
		-- The current holds the body a beat longer.
		if b.reaction and b.reactionUntil then b.reactionUntil+=.2 end
		b.hitstopUntil=math.max(b.hitstopUntil or 0,c.now+.08)
	elseif nature=="Fire" then
		-- It burns on: three chips over the next second (never a stun).
		for k=1,3 do
			c:schedule(c.now+.3*k,function()
				if b.health>0 and a.health>0 and c.match.phase=="Duel" then
					c.damageTag="ChakraBurn";c:chip(a,b,1.5);c.damageTag=nil
				end
			end)
		end
	elseif nature=="GentleFist" then
		require(script.Parent.Brawler).gentleFist(c,a,b,false)
	elseif nature=="Sand" then
		-- Sand clings: the body is slowed a moment.
		b.slowUntil=math.max(b.slowUntil or 0,c.now+1);b.slowScale=.75
	elseif nature=="Chakra" and a.fighterId=="Flashstep" then
		-- (Stage 6) Minato's infused blow seals the body (Flying Thunder God destination).
		local Techniques=require(script.Parent.Techniques)
		if Techniques.plant then Techniques.plant(c,a,b.root.Position,Vector3.yAxis,b) end
		c:cue(a,"SEALED",.5)
	end
end

-- The jump: a chakra leap when loaded (called after Motor.jump took off).
function ChakraFlow.leap(c,a)
	if not spend(c,a,T.Leap) then return false end
	-- (Lee: no ninjutsu, pure strength: the leap goes much higher)
	local up=if ChakraFlow.signature(a,"leap")=="Lotus" then T.LeapUp*1.3 else T.LeapUp
	local function boost()
		local v=a.root.AssemblyLinearVelocity
		a.root.AssemblyLinearVelocity=Vector3.new(v.X*T.LeapCarry,math.max(v.Y,0)*up+4,v.Z*T.LeapCarry)
	end
	boost()
	-- The humanoid may restate its own jump on the next step: once more.
	local at=c.now
	c:schedule(c.now+1/30,function()
		if a.airborne and a.root.AssemblyLinearVelocity.Y>0 and a.root.AssemblyLinearVelocity.Y<30 and c.now-at<.2 then boost() end
	end)
	c:pushImpact(a.root.Position-Vector3.new(0,2.6,0),"chakraleap",false,{owner=a.id,fighter=a.fighterId,nature=ChakraFlow.nature(a)})
	require(script.Parent.Brawler).event(c,a,"ChakraLeap")
	return true
end

-- The dodge: a chakra dash at the opponent. On the ground it is the re-engage
-- (no sprint, no lock needed); in the air it is the chase, out of any window.
-- Returns ok, why when it took over the press; nil to leave the dodge alone.
-- Signature dashes: out behind him (Lee's afterimage, Minato's flash,
-- Kakashi's Headhunter), a short Rotation (Neji), crows aside (Itachi).
local function behind(c,a,b,label,kind)
	local dir=line(a,b)
	local from=a.root.Position
	local to=b.root.Position+dir*2.6
	to=Vector3.new(to.X,from.Y,to.Z)
	c:relocate(a,to)
	a.root.CFrame=CFrame.lookAt(a.root.Position,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
	a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+.25)
	a.teleportAt=c.now
	c:pushImpact(to,"teleport",false,{owner=a.id,from=from,to=to,kind=kind})
	c:cue(a,label,.5)
	return true
end
ChakraFlow.OnDash={
	AfterImage=function(c,a,b,gap) if gap>14 or a.airborne then return nil end return behind(c,a,b,"AFTERIMAGE","afterimage") end,
	FlyingThunder=function(c,a,b,gap) if gap>16 or a.airborne then return nil end return behind(c,a,b,"FLYING THUNDER GOD","flash") end,
	Headhunter=function(c,a,b,gap) if gap>14 or a.airborne then return nil end return behind(c,a,b,"DOTON • HEADHUNTER","earth") end,
	Rotation=function(c,a,b,gap)
		a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+.4)
		c:pushImpact(a.root.Position,"chakrahit",true,{owner=a.id,victim=a.id,fighter=a.fighterId,nature="GentleFist",sig="Rotation",direction=Vector3.yAxis})
		c:cue(a,"ROTATION",.5)
		if gap<5.5 and not b.reaction then
			b.hitstopUntil=math.max(b.hitstopUntil or 0,c.now+.05)
			brawler().react(c,b,"Knockback",line(a,b)*34+Vector3.new(0,8,0),.4,a)
		end
		return true
	end,
	CrowScatter=function(c,a,b,gap)
		if a.airborne then return nil end
		local dir=line(a,b)
		local side=dir:Cross(Vector3.yAxis)*(if (a.dodgeSide or 1)>0 then 1 else -1)
		local from=a.root.Position
		local to=from+side*6
		c:relocate(a,to)
		a.invulnerableUntil=math.max(a.invulnerableUntil or 0,c.now+.3)
		a.teleportAt=c.now
		c:pushImpact(to,"teleport",false,{owner=a.id,from=from,to=to,kind="crows"})
		c:cue(a,"CROW SCATTER",.5)
		return true
	end,
}
function ChakraFlow.dash(c,a)
	if not ChakraFlow.active(c,a) then return nil end
	local b=a.target
	if not b or b.health<=0 then return nil end
	local sig=ChakraFlow.signature(a,"dash")
	local hook=sig and ChakraFlow.OnDash[sig]
	if hook and a.chakra>=T.Leap and (a.state=="Neutral" or a.state=="Guarding") and not a.reaction then
		local gap=(b.root.Position-a.root.Position).Magnitude
		if hook(c,a,b,gap) then
			a.chakraLoad=nil;a.chakra-=T.Leap
			require(script.Parent.Brawler).event(c,a,"ChakraDash")
			return true
		end
	end
	local gap=(b.root.Position-a.root.Position).Magnitude
	local ok,why
	if a.airborne then
		if gap>Config.PursuitRange then return nil end
		ok,why=c:chase(a)
	else
		if gap<(Config.Rush.MinRange or 7) then return nil end
		ok,why=c:rush(a)
	end
	if ok then
		a.chakraLoad=nil
		c:pushImpact(a.root.Position,"chakradash",false,{owner=a.id,fighter=a.fighterId,nature=ChakraFlow.nature(a),air=a.airborne})
		require(script.Parent.Brawler).event(c,a,"ChakraDash")
	end
	return ok,why
end
return ChakraFlow
