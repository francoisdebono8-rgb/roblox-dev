-- (06/11, « les chiens ninja qui sortent du sol ») Kakashi's ninken: Summoning:
-- Tracking Fang as a pack of bodies on the shared Bodies component (kind
-- "hound", the hook Bodies was made with). The pack digs under the floor to
-- the opponent (a dust trail runs along the ground, they cannot be struck
-- there), bursts out round his legs and bites: the body is held (a family
-- bind, "houndpack": the hounds themselves are what holds it), then they go in
-- a puff. A body that dodged or jumped is chased by the pack for a moment; the
-- first hound in reach bites (a shorter hold). Out of the ground each hound is
-- a body: one blow sends it away. Installed into Techniques by its last line.
local Bodies=require(script.Parent.Bodies)
local Hounds={}
local HOUND="hound"
-- Where each hound takes the legs, in the opponent's frame (right, back).
local SLOTS={{-1,-1},{1,-1},{-1,1},{1,1},{0,-1.3},{0,1.3}}
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function brawler() return require(script.Parent.Brawler) end
local function families() return require(script.Parent.Families) end
local function tune(a) return Bodies.tuning(a,HOUND) end
local function ground(c,p) return Vector3.new(p.X,c.match.origin.Y+3,p.Z) end
local function slotAt(c,b,k,spread)
	local s=SLOTS[(k-1)%#SLOTS+1]
	return ground(c,b.root.CFrame*Vector3.new(s[1]*spread*.85,0,s[2]*spread*.75))
end
-- Can the pack get its teeth into him (on the floor, not under cover)?
local function open(c,b)
	return b.health>0 and not b.airborne and (b.invulnerableUntil or 0)<=c.now and b.reaction~="Bound"
end
local function finish(c,pack,why)
	if pack.over then return end
	pack.over=true
	for k,body in pack.bodies do
		if body.alive then
			-- Each in its own puff, one after the other.
			c:schedule(c.now+(k-1)*.05,function() if body.alive then Bodies.dispel(c,body,why or "spent") end end)
		end
	end
end
local function bite(c,pack,body,hold)
	if pack.bitten then return end
	local a,b=pack.owner,pack.target
	if not open(c,b) then return end
	pack.bitten=true
	c.hitOrigin=body.position;c.damageTag="Tracking Fang"
	c:damage(a,b,(pack.spec.Damage or 4)*(a.def.CombatDamage or 1),false,false)
	c.hitOrigin=nil;c.damageTag=nil
	if c.match.phase~="Duel" or b.health<=0 then return end
	families().bind(c,a,b,{Bind=hold,Kind="houndpack",Name=pack.spec.Name or "Tracking Fang"})
	pack.holding=b.reaction=="Bound" and b.boundBy==a
	c:pushImpact(b.root.Position,"houndbite",true,{owner=a.id,fighter=a.fighterId,victim=b.id})
	brawler().event(c,a,"HoundBite")
	for _,other in pack.bodies do
		if other.alive then
			-- (the ones still under the floor burst out at his legs)
			if other.buried then c:pushImpact(other.position,"houndburst",false,{owner=a.id,fighter=a.fighterId,body=other.id}) end
			other.mode="hold";other.state="Active";other.buried=nil;other.action="Bite";other.actionAt=c.now;other.actionSerial+=1
		end
	end
	if not pack.holding then finish(c,pack) end
end
local function surface(c,body)
	local pack=body.pack
	body.buried=nil;body.state="Neutral"
	c:pushImpact(body.position,"houndburst",false,{owner=pack.owner.id,fighter=pack.owner.fighterId,body=body.id})
	local b=pack.target
	if not pack.bitten and open(c,b) and flat(b.root.Position-body.position).Magnitude<=(tune(pack.owner).Reach or 2.4)+1 then
		bite(c,pack,body,(pack.spec.Bind or 1.1))
	elseif not pack.bitten then
		body.mode="chase";body.state="Run"
		pack.chaseUntil=pack.chaseUntil or (c.now+(tune(pack.owner).Chase or 2.2))
	end
end
-- The pack under the floor: straight to its slot round his legs.
local function dig(c,body,dt)
	local pack=body.pack
	local b=pack.target
	if not b or b.health<=0 or pack.over then return finish(c,pack) end
	if pack.bitten then return surface(c,body) end
	local goal=slotAt(c,b,body.slot,1.7)
	Bodies.move(c,body,goal,(tune(pack.owner).Dig or 46)*(body.pace or 1),dt)
	Bodies.face(body,b.root.Position)
	if (body.position-goal).Magnitude<.7 or c.now>=pack.digUntil then surface(c,body) end
end
-- Dodged: the pack runs him down for a moment.
local function chase(c,body,dt)
	local pack=body.pack
	local b=pack.target
	if not b or b.health<=0 or pack.over then return finish(c,pack) end
	if pack.bitten then body.mode="hold";body.state="Active";return end
	if c.now>=(pack.chaseUntil or 0) then return finish(c,pack,"expire") end
	local goal=slotAt(c,b,body.slot,1.9)
	Bodies.move(c,body,goal,(tune(pack.owner).Run or 30)*(body.pace or 1),dt)
	Bodies.face(body,b.root.Position)
	if flat(b.root.Position-body.position).Magnitude<=(tune(pack.owner).Reach or 2.4)+.4 then
		bite(c,pack,body,tune(pack.owner).ChaseBite or .7)
	end
end
-- Teeth in his legs while the hold lasts; then gone.
local function hold(c,body,dt)
	local pack=body.pack
	local a,b=pack.owner,pack.target
	if not b or b.health<=0 or pack.over or b.reaction~="Bound" or b.boundBy~=a then return finish(c,pack) end
	-- (Studio 06/11: closer in, they disappeared under his legs.)
	local goal=slotAt(c,b,body.slot,1.6)
	body.position=c:clamp(body.position:Lerp(goal,math.min(1,dt*20)))
	Bodies.face(body,b.root.Position)
	body.state="Active"
end
function Hounds.install(Techniques)
	Bodies.controllers.dig=dig
	Bodies.controllers.chase=chase
	Bodies.controllers.hold=hold
	-- Summoning: Tracking Fang. The pack dives into the floor at his feet.
	Techniques.TrackingFang={
		check=function(c,a,spec)
			local b=a.target
			if not b or b.health<=0 then return false,"No target" end
			if flat(b.root.Position-a.root.Position).Magnitude>(spec.Range or 30)+2 then return false,"Out of range" end
			return true
		end,
		execute=function(c,a,pending)
			local spec=pending.spec
			local b=a.target
			if not b or b.health<=0 then return end
			local tn=tune(a)
			local count=tn.Pack or 4
			local reach=flat(b.root.Position-a.root.Position).Magnitude
			local pack={owner=a,target=b,spec=spec,bodies={},digUntil=c.now+math.min(spec.Range or 30,reach+4)/(tn.Dig or 46)+.15}
			local fwd=flat(b.root.Position-a.root.Position)
			fwd=if fwd.Magnitude>.1 then fwd.Unit else flat(a.root.CFrame.LookVector).Unit
			local right=fwd:Cross(Vector3.yAxis)
			for k=1,count do
				local at=ground(c,a.root.Position+fwd*1.4+right*((k-(count+1)/2)*.9))
				local body=Bodies.spawn(c,a,{kind=HOUND,position=at,ephemeral=true,life=8,mode="dig",state="Dig"})
				if body then
					body.pack=pack;body.slot=k;body.buried=true;body.pace=.94+(k%3)*.05
					table.insert(pack.bodies,body)
				end
			end
			c:cue(a,"SUMMONING • TRACKING FANG",.7)
			brawler().event(c,a,"TrackingFang")
		end,
	}
end
return Hounds
