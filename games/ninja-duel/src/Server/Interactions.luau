-- Interactions between jutsu (stage 6, the approved move list, "Interactions:
-- les jutsu réagissent entre eux"): when two things meet, what the anime
-- would have happen happens, each with its own contact for the client.
-- The older ones live where they always did (the wire catching fire, the
-- current running down the wire, the fire eating the wind, Rotation sending
-- blades back, the Byakugan's reveal, infused planted kunai); this module
-- holds the new ones:
--   fire + Water Dragon          a cloud of steam, nobody sees through it (3 s)
--   Water Dragon on the ground   a puddle (6 s); lightning in it spreads (stun)
--   Gaara's sand + water         wet sand: the Coffin slower but harder
--   fire on Gaara's sand         the shield loses a charge more (it melts)
--   Rasengan against Chidori     the two explode: both thrown back, big flash
-- Server rules only; the look is the client's (UltimateFX draws none of this:
-- Effects and its layers draw the contacts named here).
local Interactions={}

Interactions.STEAM={Radius=10,Time=3}
Interactions.PUDDLE={Radius=9,Time=6}
Interactions.CONDUCT={Damage=1.3,Stun=.6}
Interactions.WET={Speed=.7,Damage=1.3}
Interactions.CLASH={Push=14,Chip=5}

local FIRE_KINDS={fireball=true,phoenix=true,firebreath=true}
local function isFire(p)
	return p~=nil and (FIRE_KINDS[p.kind or ""]==true or p.infusion=="Fire" or (p.chakra and p.chakra.nature=="Fire") or false)
end
local function isWater(p)
	return p~=nil and (p.kind=="waterdragon" or p.kind=="water" or p.kind=="shark")
end
Interactions.isFire=isFire
Interactions.isWater=isWater
local function flat(v) return Vector3.new(v.X,0,v.Z) end

-- Two flying objects meet (ChakraCombat, before its own rules): true when an
-- interaction here took the meeting.
function Interactions.meet(c,p,q,at)
	if (isFire(p) and isWater(q)) or (isFire(q) and isWater(p)) then
		p.dead=true;q.dead=true
		Interactions.steam(c,at or p.position,p.a,q.a)
		return true
	end
	return false
end
-- A cloud of steam: inside it, each fighter has lost the other (the shroud
-- contract, Families.shrouded: one zone per owner, so both are blinded).
function Interactions.steam(c,position,a,b)
	local tune=Interactions.STEAM
	local spec={Shroud=true,Kind="mist",Name="Steam"}
	for _,owner in {a,b} do
		if owner and owner.health>0 then
			local h=c:addHazard(owner,position,tune.Radius,tune.Time,0,"Steam")
			h.effects=spec;h.look="mist"
		end
	end
	c:pushImpact(position,"steam",true,{radius=tune.Radius,time=tune.Time,owner=a and a.id})
	for _,x in {a,b} do if x then c:cue(x,"STEAM • NO SIGHT",.8) end end
end

-- Where a Water Dragon ends (on a body, a wall or the floor) the ground stays wet.
function Interactions.ended(c,p,position)
	if not isWater(p) or not position then return end
	c.puddles=c.puddles or {}
	local tune=Interactions.PUDDLE
	table.insert(c.puddles,{position=position,radius=tune.Radius,expires=c.now+tune.Time,owner=p.a})
	c:pushImpact(position,"puddle",false,{radius=tune.Radius,time=tune.Time,owner=p.a and p.a.id})
end
function Interactions.inPuddle(c,a)
	if not c.puddles or not a or not a.root then return nil end
	for i=#c.puddles,1,-1 do
		local w=c.puddles[i]
		if c.now>=w.expires then table.remove(c.puddles,i)
		elseif flat(a.root.Position-w.position).Magnitude<=w.radius and math.abs(a.root.Position.Y-w.position.Y)<6 then return w end
	end
	return nil
end
function Interactions.clear(c) c.puddles=nil end

-- Is this blow lightning? A lightning jutsu being cast, a held Chidori or
-- Lightning Blade released, a lightning-infused strike.
local LIGHTNING_STATES={Chidori=true,LightningBlade=true}
function Interactions.lightning(c,a)
	local p=a.pending
	if p and p.spec and (p.spec.Element=="Lightning" or p.spec.element=="Lightning") then return true end
	if p and LIGHTNING_STATES[p.state or ""] then return true end
	if a.castId=="LightningCut" or a.castId=="LightningBlade" or a.castId=="Chidori" then return true end
	if a.chakraLoad and a.chakraLoad.nature=="Lightning" then return true end
	return false
end
-- Combat:damage, before the amount lands: lightning into a body standing in
-- the water hits harder and the current holds it (Combat applies the stun).
function Interactions.damage(c,attacker,victim,amount)
	if not Interactions.lightning(c,attacker) then return amount,false end
	local w=Interactions.inPuddle(c,victim)
	if not w then return amount,false end
	c:pushImpact(victim.root.Position,"conduct",true,{owner=attacker.id,victim=victim.id,position=w.position,radius=w.radius})
	c:cue(attacker,"LIGHTNING • THE WATER CARRIES IT",.8)
	return amount*Interactions.CONDUCT.Damage,true
end

-- Sand Coffin cast at a body in the water: wet sand, slower but harder.
function Interactions.wetSand(c,a,target)
	if not Interactions.inPuddle(c,target) then return nil end
	c:cue(a,"WET SAND • SLOWER, HARDER",.8)
	return Interactions.WET
end

-- Fire reaching Gaara: his sand shield melts a charge more.
function Interactions.fireOnSand(c,p,victim)
	if not isFire(p) or not victim.def.SandShield or (victim.shieldCharges or 0)<=0 then return end
	victim.shieldCharges-=1
	victim.shieldRegenAt=c.now+victim.def.SandShield.Regen
	c:pushImpact(victim.root.Position,"sandmelt",false,{owner=victim.id})
	c:cue(victim,"FIRE • THE SAND MELTS",.6)
end

-- Two held jutsu released into each other (Brawler.clash): Rasengan against
-- Chidori (or Kakashi's Lightning Blade). Both are thrown far back, both
-- take a little, both jutsu are spent.
local function rasengan(p) return p.rasengan==true end
local function chidori(p) return LIGHTNING_STATES[p.state or ""]==true end
function Interactions.jutsuClash(c,a,b,p,q)
	if not ((rasengan(p) and chidori(q)) or (chidori(p) and rasengan(q))) then return false end
	local line=flat(b.root.Position-a.root.Position)
	line=if line.Magnitude>.1 then line.Unit else a.root.CFrame.LookVector
	local tune=Interactions.CLASH
	c:pushImpact(a.root.Position:Lerp(b.root.Position,.5),"jutsuclash",true,{direction=line,owner=a.id,victim=b.id})
	for _,x in {a,b} do
		c:chip(x.target or x,x,tune.Chip)
		c:cue(x,"RASENGAN • CHIDORI • CLASH",1)
	end
	a.hop={direction=-line,remaining=tune.Push,speed=44}
	b.hop={direction=line,remaining=tune.Push,speed=44}
	return true
end

return Interactions
