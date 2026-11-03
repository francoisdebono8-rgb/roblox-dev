-- Ninja Embodiment (DEC-027, EMB-002): the strike input means "attack from
-- the body's current situation", not "advance the universal combo counter".
--
-- One shared reading of the situation (pure: positions, velocities, facings,
-- states), one ordered list of situations, and per fighter a declaration of
-- what its body does in each (MoveGraphs[id].context, else a default slot of
-- its own graph). Deterministic: the same situation always gives the same
-- strike; nothing is random and nothing is keyed on a fighter id here.
--
-- Situations (first match wins):
--   drop    falling onto a grounded body below and close
--   wall    his back is to a surface on this body's line (a drive puts him
--           into it); also read inside a string, where it ends the string
--   back    the opponent's back is turned to this body, within reach
--   aside   (the player's stick) pressed while moving round him: the
--           fighter's own lateral strike, which carries the body round
--   away    (the player's stick) pressed while backing off: a strike that
--           takes the step back with it (space, not a string)
--   run     carrying real speed toward the opponent (not a full sprint)
--   flank   at the opponent's side, within reach
--   close   inside arm's length: knees, elbows, hilts, palms
--   reach   standing at the edge of reach: a lunge across it
-- None of them: the plain strike (the light string still exists, it is just
-- no longer the only meaning of the button).
local Context={}

local function flat(v) return Vector3.new(v.X,0,v.Z) end

-- Tunables (studs, studs/s). Kept here so tests and tuning read one table.
Context.Tune={
	DropFall=-6,        -- vertical speed below which the body is falling
	DropHeight=6,       -- at most this far above the target's root
	DropReach=6.5,      -- horizontal distance for a drop strike
	BackDot=-.35,       -- target facing . (target -> me) below this: his back
	FlankDot=.4,        -- |target facing . (target -> me)| below this: his side
	Reach=5.5,          -- back / flank / close situations need this distance or less
	Close=2.9,          -- inside this: close-range body strikes
	RunSpeed=13,        -- speed toward the opponent for a running strike
	RunMin=3.5,RunMax=10,
	ReachMin=6.8,ReachSpan=3,ReachStill=4,
	Stick=7,            -- the stick's lateral opener (aside) within this distance
	StickAway=9,        -- backing off: the step-back strike (a body already moving away)
	WallBehind=12,      -- a surface at most this far behind the target (a
	                    -- finisher throws a body about that far)
}

-- s: {pos, look, vel, airborne, grounded, target={pos, look, airborne, down, guarding}}
-- (Brawler adds the world facts it perceives: x.wallBehind, x.plainReach.)
-- Returns a table describing the situation (pure, no Roblox services).
function Context.read(s)
	local t=s.target
	local to=flat(t.pos-s.pos)
	local dist=to.Magnitude
	local line=if dist>.05 then to.Unit else flat(s.look).Unit
	local toward=flat(s.vel):Dot(line)
	-- Where this body stands relative to the opponent's facing.
	local fromTarget=-line
	local tlook=flat(t.look)
	local facingDot=if tlook.Magnitude>.05 then tlook.Unit:Dot(fromTarget) else 1
	return {
		dist=dist,dy=s.pos.Y-t.pos.Y,toward=toward,speed=flat(s.vel).Magnitude,vy=s.vel.Y,
		airborne=s.airborne==true,targetAirborne=t.airborne==true,targetDown=t.down==true,
		targetGuarding=t.guarding==true,facingDot=facingDot,
	}
end

local T=Context.Tune
-- Ordered situations. Each test reads only the context table.
Context.Situations={
	{tag="drop",test=function(x) return x.airborne and not x.targetAirborne and not x.targetDown and x.vy<T.DropFall and x.dy>1.5 and x.dy<=T.DropHeight and x.dist<=T.DropReach end},
	{tag="wall",test=function(x) return not x.airborne and not x.targetAirborne and not x.targetDown and x.dist<=T.Reach and x.wallBehind~=nil and x.wallBehind<=T.WallBehind end},
	{tag="back",test=function(x) return not x.airborne and not x.targetAirborne and not x.targetDown and x.dist<=T.Reach and x.facingDot<T.BackDot end},
	{tag="aside",test=function(x) return not x.airborne and not x.targetAirborne and not x.targetDown and x.stick=="side" and x.dist<=T.Stick end},
	{tag="away",test=function(x) return not x.airborne and not x.targetAirborne and not x.targetDown and x.stick=="back" and x.dist<=T.StickAway end},
	{tag="run",test=function(x) return not x.airborne and x.toward>=T.RunSpeed and x.dist>=T.RunMin and x.dist<=T.RunMax end},
	{tag="flank",test=function(x) return not x.airborne and not x.targetAirborne and not x.targetDown and x.dist<=T.Reach and math.abs(x.facingDot)<T.FlankDot end},
	{tag="close",test=function(x) return not x.airborne and not x.targetAirborne and x.dist<T.Close end},
	-- Beyond what the plain strike's own step reaches (x.plainReach, the
	-- fighter's: a fan or a cleaver reaches further than a fist).
	{tag="reach",test=function(x) local from=x.plainReach or T.ReachMin return not x.airborne and not x.targetAirborne and not x.targetDown and x.speed<T.ReachStill and x.dist>from and x.dist<=from+T.ReachSpan end},
}

-- What a fighter's body does in a situation when it declares nothing: a slot
-- of its own move graph (so the default already carries its identity), then a
-- shared strike.
Context.Defaults={
	drop=function(graph) return "DropStrike" end,
	-- The fighter's own string finisher (its Light3 throws the body away).
	wall=function(graph) return graph.wallStrike or "Light3" end,
	back=function(graph) return "BackStrike" end,
	aside=function(graph) return graph.routes and graph.routes.side or nil end,
	away=function(graph) return graph.stepBack or "StepBackStrike" end,
	-- (Studio 28/10) A light out of a run opens the string: a runStrike that
	-- throws the body away (Sasuke's and Lee's flying kick) stays on the
	-- sprint heavy, the run's light is the shared DashAttack.
	run=function(graph,attacks)
		local m=graph.runStrike
		if m and attacks and attacks[m] and attacks[m].reaction~="HitStun" then return "DashAttack" end
		return m or "DashAttack"
	end,
	flank=function(graph) return graph.routes and graph.routes.side or nil end,
	-- (Audit 29/10, user: "Gaara particulier") A light pressed at close range
	-- never launches by default: Gaara's heavyAfterOne is his Sand Pillar, so
	-- every light at arm's length was a launcher. A fighter may still declare
	-- a launching closeStrike on purpose.
	close=function(graph,attacks)
		if graph.closeStrike then return graph.closeStrike end
		local m=graph.heavyAfterOne
		if m and attacks and attacks[m] and attacks[m].reaction=="Launched" then return nil end
		return m
	end,
	reach=function(graph) return graph.reachStrike or "DashAttack" end,
}

-- A surface a body can be driven into (Server/Perception reads it; the
-- client's guess of its next strike too): the stadium wall, the field trees,
-- the boulders, anything declared NinjaWall or WorldBreakable. A broken one
-- (a stump, a mound) no longer is.
function Context.surface(part)
	if not part then return false end
	if part:GetAttribute("WorldState")=="Broken" then return false end
	return part:GetAttribute("NinjaWall")==true or part:GetAttribute("WorldBreakable")==true or part.Name=="Field tree" or part.Name=="Cover"
end
-- (É7) The stick against the line to the opponent: "forward", "back",
-- "side" (with the side's sign) or nil under the strong-push threshold.
-- Brawler.classify reads it on the server, the client's guess of its own
-- next strike reads the same. tune: Config.Combo.
function Context.stick(move,line,tune)
	local m=flat(move)
	if m.Magnitude<tune.IntentStrong then return nil,0 end
	local u=m.Unit
	local along=u:Dot(line)
	if along>=tune.Toward then return "forward",0 end
	if along<=-tune.Away then return "back",0 end
	return "side",if u:Dot(line:Cross(Vector3.yAxis))>=0 then 1 else -1
end
-- The air dive (Brawler.airDive): high above a grounded body and out of the
-- first air swing's reach, the air opener is the lunge down onto him.
-- (Audit 03/11, B02) Straight above his head (a jump in place next to him:
-- 15 studs up, 1-3 away) the air swing passed over him too: from Overhead
-- up, a body that close is dived on as well.
Context.AirDive={Above=3,AboveMax=26,Near=3.5,Far=18,Overhead=6}
function Context.airDive(myPos,targetPos)
	local d=targetPos-myPos
	local h=flat(d).Magnitude
	local above=-d.Y
	local T=Context.AirDive
	return above>=T.Above and above<=T.AboveMax and (h>=T.Near or above>=T.Overhead) and h<=T.Far
end

-- graph: the fighter's MoveGraphs entry (may be nil); attacks: the Attacks
-- table (a slot naming a strike that does not exist is skipped).
-- Returns move name and situation tag, or nil for the plain strike.
function Context.resolve(x,graph,attacks,only)
	graph=graph or {}
	local declared=graph.context or {}
	for _,situation in Context.Situations do
		if (not only or only[situation.tag]) and situation.test(x) then
			local move=declared[situation.tag]
			if move==false then continue end
			if move==nil then move=Context.Defaults[situation.tag](graph,attacks) end
			if move and attacks[move] then return move,situation.tag end
		end
	end
	return nil,nil
end

return Context
