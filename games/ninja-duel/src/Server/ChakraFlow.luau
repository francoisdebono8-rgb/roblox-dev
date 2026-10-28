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
	LeapUp=1.32,       -- jump vertical scale
	LeapCarry=1.35,    -- jump horizontal scale
}
local T=ChakraFlow.Tune
-- Each fighter's chakra nature (what the load is). Unlisted: plain chakra.
ChakraFlow.Nature={
	Lion="Lightning",Copycat="Lightning",Mirage="Fire",Legion="Wind",Gale="Wind",
	Sand="Sand",GentleFist="GentleFist",Leaf="Strength",Flashstep="Chakra",
}
ChakraFlow.Label={Lightning="RAITON",Fire="KATON",Wind="FUTON",Sand="SAND",GentleFist="GENTLE FIST",Strength="STRENGTH",Chakra="CHAKRA"}
-- What a nature does to the strike itself (on top of the common scaling).
local SHAPE={
	Wind={reach=1.6,impulse=1.45},      -- a blade of wind past the fist
	Strength={impulse=1.6},             -- the body thrown much further
	Lightning={reach=.4},
	Fire={},Sand={impulse=1.15},GentleFist={},Chakra={},
}
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
		c:cue(a,"CHAKRA • "..ChakraFlow.Label[nature],.6)
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

-- Brawler.start: the strike about to come out takes the load.
function ChakraFlow.strike(c,a,name,spec)
	if NOT_STRIKES[name] then return nil end
	local nature=spend(c,a,T.Strike)
	if not nature then return nil end
	local shape=SHAPE[nature] or {}
	spec.damageScale=(spec.damageScale or 1)*(if HEAVY[name] then T.HeavyDamage else T.Damage)
	local reach=T.Reach+(shape.reach or 0)
	spec.range=(spec.range or 5)+reach
	spec.depth=(spec.depth or 2)+reach
	spec.impulse=spec.impulse*(T.Impulse*(shape.impulse or 1))
	c:pushImpact(a.root.Position,"chakrastrike",false,{owner=a.id,fighter=a.fighterId,nature=nature,move=name})
	c:cue(a,ChakraFlow.Label[nature].." • "..string.upper(name),.5)
	return nature
end

-- Brawler.hit: the nature on contact (clean or guarded).
function ChakraFlow.hit(c,a,b,p,guarded)
	local nature=p.chakraFlow
	if not nature or b.health<=0 then return end
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
	end
end

-- The jump: a chakra leap when loaded (called after Motor.jump took off).
function ChakraFlow.leap(c,a)
	if not spend(c,a,T.Leap) then return false end
	local function boost()
		local v=a.root.AssemblyLinearVelocity
		a.root.AssemblyLinearVelocity=Vector3.new(v.X*T.LeapCarry,math.max(v.Y,0)*T.LeapUp+4,v.Z*T.LeapCarry)
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
function ChakraFlow.dash(c,a)
	if not ChakraFlow.active(c,a) then return nil end
	local b=a.target
	if not b or b.health<=0 then return nil end
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
