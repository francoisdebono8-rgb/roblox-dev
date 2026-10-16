-- Explicit QA setups (Codex 33028b2, ported to the current Matches API). Each
-- one rebuilds the duel through Matches:start (fresh actors and epoch, no
-- intro, the bot held as a dummy), then puts it in a state through the live
-- engine only: Brawler reactions, Brawler.splat on a real NinjaWall panel,
-- Combat:request and Combat:damage. A setup reproduces a state; it does not
-- prove that a human executed the route. Online sessions are never touched.
-- Debug/QA places only (build.py DEBUG_SOURCES).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Fighters=require(Shared.Fighters)
local Brawler=require(script.Parent.Brawler)
local World=require(script.Parent.World)
local Scenarios={}
Scenarios.names={"neutral","launcher","air","wall","substitution","grab","whiff","projectile","ko"}
-- The selectable CORE4 roster. Other ids (Sand) stay reachable from the command bar.
Scenarios.core={"Flashstep","Mirage","GentleFist","Lion"}
function Scenarios.known(name) return table.find(Scenarios.names,name)~=nil end
-- A fresh duel at close range. `first`/`second` default to the current pair.
function Scenarios.reset(matches,player,first,second,dummy)
	local old=matches.sessions[player]
	if old and old.online then return false,"Online session: leave it first (back to Selection)" end
	first=first or (old and old.playerId) or "Flashstep"
	second=second or (old and old.botId) or "Mirage"
	if type(first)~="string" or type(second)~="string" or not Fighters[first] or not Fighters[second] then return false,"Unknown fighter" end
	-- The same pairing keeps its validated skill builds (startBuild); a new
	-- pairing starts on the canonical kits.
	local options=if old and old.playerId==first and old.botId==second then old.options else nil
	local ok,reason=matches:start(player,first,second,false,options)
	if not ok then return false,reason or "Start refused" end
	local s=matches.sessions[player]
	s.introUntil=nil;s.botFrozen=dummy~=false
	if s.botFrozen then s.bot.move=Vector3.zero end
	local c=s.combat
	c:relocate(s.human,s.origin+Vector3.new(0,3,3));c:relocate(s.bot,s.origin+Vector3.new(0,3,-3))
	s.human.root.CFrame=CFrame.lookAt(s.human.root.Position,s.bot.root.Position)
	s.bot.root.CFrame=CFrame.lookAt(s.bot.root.Position,s.human.root.Position)
	matches:snapshot(player,s)
	return true,s
end
-- Chakra, cooldowns and substitution charges back to full (health untouched).
function Scenarios.refill(s,actor)
	for _,a in (if actor then {actor} else {s.human,s.bot}) do
		a.chakra=a.def.Chakra or Config.Chakra;a.cooldowns={}
		a.subCharges=Config.Substitution.Charges;a.subCooldown=0;a.subRegenAt=math.huge
	end
end
function Scenarios.setup(matches,player,name,first,second)
	if not Scenarios.known(name) then return false,"Unknown scenario" end
	local ok,s=Scenarios.reset(matches,player,first,second,true)
	if not ok then return false,s end
	local c,a,b=s.combat,s.human,s.bot
	local accepted,reason=true,nil
	if name=="launcher" then
		Brawler.react(c,b,"Launched",Vector3.new(0,48,0),1.2,a);a.pursuitUntil=c.now+Config.PursuitWindow
	elseif name=="air" then
		for _,x in {a,b} do c:relocate(x,x.root.Position+Vector3.new(0,13,0));x.airborne=true end
		a.airHold=c.now+2;Brawler.react(c,b,"Juggled",Vector3.zero,2,a)
	elseif name=="wall" then
		-- A real NinjaWall panel probed at World.WALL_RADIUS on +X, never a stored coordinate.
		local hit=workspace:Raycast(s.origin+Vector3.new(World.WALL_RADIUS-12,12,0),Vector3.xAxis*24,c:rayParams(true))
		if not hit or not hit.Instance:GetAttribute("NinjaWall") then return false,"No wall surface on probe ray" end
		c:relocate(b,hit.Position+hit.Normal*2.1)
		local front=b.root.Position+hit.Normal*5
		c:relocate(a,Vector3.new(front.X,s.origin.Y+3,front.Z))
		a.root.CFrame=CFrame.lookAt(a.root.Position,Vector3.new(b.root.Position.X,a.root.Position.Y,b.root.Position.Z))
		-- The engine's own splat: pin window, wall impact, splat damage and the attacker's chase window.
		Brawler.react(c,b,"Knockback",Vector3.zero,.42,a)
		Brawler.splat(c,b,hit)
	elseif name=="substitution" then
		a.lastHurt=c.now;Brawler.react(c,a,"HitStun",Vector3.zero,.45,b)
		accepted,reason=c:request(a,"Substitute")
	elseif name=="grab" then
		c:relocate(b,a.root.Position+a.root.CFrame.LookVector*3.4)
		accepted,reason=c:request(a,"Grab")
	elseif name=="whiff" then
		c:relocate(b,s.origin+Vector3.new(0,3,-22))
		accepted,reason=c:request(a,"Heavy")
	elseif name=="projectile" then
		c:relocate(b,s.origin+Vector3.new(0,3,-24))
		accepted,reason=c:request(a,"Tool",b.root.Position)
	elseif name=="ko" then
		b.rotationUntil=0;b.shieldCharges=0;b.invulnerableUntil=0;b.readUntil=0;b.guardHeld=false
		c:damage(a,b,b.health+200,false,false)
		accepted,reason=b.health<=0,"damage refused"
	end
	if not accepted then return false,name..": "..tostring(reason) end
	matches:snapshot(player,s)
	return true,{scenario=name,epoch=s.epoch,first=s.playerId,second=s.botId}
end
return Scenarios
