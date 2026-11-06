-- (06/11, « leur Sharingan sert à quelque chose ») What a pair of eyes can
-- read of a fighter, the one rule the server and the client share.
--
-- An amplified speed jutsu (Lee's weights off, the Eight Gates, Minato's
-- Yellow Flash: a technique or an awakening flagged `Unreadable`) makes the
-- body too fast for ordinary eyes while it moves or strikes: on their screen
-- it is a scrawl of ink lines, the wind-up of a strike cannot be seen, and the
-- AI cannot read it either. The Sharingan (`def.Sharingan`, Kakashi only
-- uncovered) reads it: the body stays visible, its path trails behind it and
-- the strike to come shows a beat early.
--
-- Pure data and arithmetic: no instance, no service, safe in headless specs.
local Fighters=require(script.Parent.Fighters)

local Sight={}

-- A fast body is unreadable while it does something worth reading: a strike
-- (wind-up, active frames), a dodge, a rush, a chase, a technique's release,
-- or simply running hard. Standing still, it is a body like any other.
Sight.FAST_STATES={Startup=true,Active=true,Dodging=true,Rush=true,Pursuit=true,TechniqueActive=true}
Sight.FAST_SPEED=11
-- The client keeps the blur this long after the last fast frame, so a body
-- that pauses between two kicks does not flicker in and out of ink.
Sight.LINGER=.3

local function techSpec(def,id)
	if not def or not id then return nil end
	for _,spec in def.Techniques or {} do if spec.Id==id then return spec end end
	return nil
end
Sight.techSpec=techSpec

-- Is this fighter's speed jutsu running? `buffId`: the family buff it holds
-- (nil if none), `awake`: its awakening is on.
function Sight.speedJutsu(fighterId,buffId,awake)
	local def=Fighters[fighterId or ""]
	if not def then return false end
	local spec=techSpec(def,buffId)
	if spec and spec.Unreadable then return true end
	return awake==true and def.Awakening~=nil and def.Awakening.Unreadable==true
end
-- Is the body doing something too fast to follow right now?
function Sight.moving(state,speed)
	return Sight.FAST_STATES[state or ""]==true or (speed or 0)>=Sight.FAST_SPEED
end
-- Do these eyes read a speed jutsu? The Sharingan does; Kakashi's only once
-- it is uncovered (his awakening).
function Sight.eyes(fighterId,awake)
	local def=Fighters[fighterId or ""]
	if not def or not def.Sharingan then return false end
	return not def.SharinganAwake or awake==true
end

-- Server side (an actor of Server/Combat).
function Sight.unreadable(a,now)
	if not a or (a.health or 0)<=0 then return false end
	local b=a.buff
	local buffId=if b and now<(b.untilT or 0) then b.id else nil
	if not Sight.speedJutsu(a.fighterId,buffId,(a.awakenUntil or 0)>now) then return false end
	return Sight.moving(a.state,a.locomotion and a.locomotion.Magnitude or 0)
end
function Sight.reads(a,now)
	return a~=nil and Sight.eyes(a.fighterId,(a.awakenUntil or 0)>now)
end

-- Client side (an actor of the duel snapshot, Server/Matches:view).
function Sight.viewFast(actor)
	if not actor or (actor.health or 1)<=0 then return false end
	local family=actor.family
	return Sight.speedJutsu(actor.fighterId,family and family.buff,(actor.awaken or 0)>0)
end
function Sight.viewUnreadable(actor)
	return Sight.viewFast(actor) and Sight.moving(actor.state,actor.speed)
end
function Sight.viewReads(actor)
	return actor~=nil and Sight.eyes(actor.fighterId,(actor.awaken or 0)>0)
end

return Sight
