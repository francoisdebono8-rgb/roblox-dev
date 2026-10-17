-- Naruto Uzumaki (roster wave: Part I, the Chunin Exam to the Valley of the
-- End, 13). The shadow clones on the shared Bodies component: how a clone
-- behaves (at his side, out on a flank, in the Uzumaki Barrage, shaping the
-- Rasengan), his jutsu (Shadow Clone, Rasengan, Multi Shadow Clone), the
-- transformed kunai, and the Nine-Tails chakra that takes the clones away
-- (Bodies.blocked: the cloak has claws instead). Installed into Techniques
-- by its last line, like a client identity layer into Effects.
-- Sheet: docs/characters/NARUTO.md; report: docs/reports/convergence3/NARUTO.md.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Attacks=require(Shared.Attacks)
local Bodies=require(script.Parent.Bodies)
local Legion={}
local CLONE="clone"
local JAB,KICK=Attacks.CloneJab,Attacks.BarrageKick
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function brawler() return require(script.Parent.Brawler) end
local function tune(a) return Bodies.tuning(a,CLONE) end
local function rightOf(a)
	local right=flat(a.root.CFrame.RightVector)
	return if right.Magnitude>.1 then right.Unit else Vector3.xAxis
end
-- Clones come out on alternate sides of him.
local function nextSide(a)
	a.cloneSide=-(a.cloneSide or -1)
	return a.cloneSide
end
local function aside(c,a,side,distance)
	local p=a.root.Position+rightOf(a)*side*(distance or 2.8)
	return Vector3.new(p.X,c.match.origin.Y+3,p.Z)
end
-- The opponent is open to a clone's jab: not swinging, not in a reaction, not
-- under wake-up cover.
local function open(c,b)
	if b.health<=0 or b.reaction or b.groundPose or (b.invulnerableUntil or 0)>c.now then return false end
	return b.state=="Neutral" or b.state=="Guarding" or b.state=="Recovery" or b.state=="TechniqueRecovery" or b.state=="Stunned"
end
-- Persistent clones ---------------------------------------------------------
-- "guard": at his side (a decoy for blades, a partner for the swap and the
-- Rasengan) until the opponent comes close; "flank": out to the opponent's
-- side, a jab (Attacks.CloneJab, judged from the clone) whenever the opponent
-- is open; when Naruto dashes in, a flanking clone rushes the other side.
local function jab(c,body,b)
	local t=c.now-body.actionAt
	if body.state=="Startup" and t>=JAB.startup then
		body.state="Active"
		local reach=tune(body.owner).Reach or 5.4
		if Bodies.hitFrom(c,body,b,{damage=tune(body.owner).Strike or 4,reach=reach+.8,arc=.2,reaction="HitStun",push=10,up=3,stun=JAB.stun,tag="Shadow Clone"}) then
			brawler().event(c,body.owner,"CloneJab")
		end
	elseif body.state=="Active" and t>=JAB.startup+JAB.active then body.state="Recovery"
	elseif body.state=="Recovery" and t>=JAB.startup+JAB.active+JAB.recovery then body.state="Neutral";body.action=nil end
end
local function persistent(c,body,dt)
	local a=body.owner
	local b=a.target
	if not b or b.health<=0 then return end
	local gap=flat(b.root.Position-body.position).Magnitude
	if body.state~="Neutral" then
		jab(c,body,b)
		if body.alive then Bodies.face(body,b.root.Position) end
		return
	end
	if body.mode=="guard" and gap<=12 then body.mode="flank" end
	local goal,speed
	if body.mode=="guard" then
		goal,speed=aside(c,a,body.side,2.8),28
	else
		-- Out on the opponent's flank, off the line between the two of them.
		local line=flat(a.root.Position-b.root.Position)
		line=if line.Magnitude>.1 then line.Unit else flat(-b.root.CFrame.LookVector).Unit
		local angle=body.side*100
		speed=if body.rush then 46 else 34
		if a.state=="Rush" and a.rush then
			-- The pincer: Naruto comes in on one angle, the clone on the other.
			if not body.pincer then body.pincer=true;body.nextStrike=c.now+.08 end
			angle=-(a.rush.side or body.side)*70;speed=80
		else body.pincer=nil end
		local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(angle)):VectorToWorldSpace(line)
		goal=b.root.Position+around*4.2
		goal=Vector3.new(goal.X,c.match.origin.Y+3,goal.Z)
	end
	Bodies.move(c,body,goal,speed,dt)
	Bodies.face(body,b.root.Position)
	local reach=tune(a).Reach or 5.4
	if body.mode=="flank" and c.now>=body.nextStrike and gap<=reach and open(c,b) then
		body.rush=nil
		body.state="Startup";body.action="CloneJab";body.variant=nil;body.actionAt=c.now;body.actionSerial+=1
		-- A clone's rhythm: not the same beat twice in a row.
		body.nextStrike=c.now+(tune(a).Every or 1.9)*(.85+((body.id*7+body.actionSerial*3)%5)*.1)
	end
end
-- Uzumaki Barrage clones: they burst out beside the launched body, kick it
-- higher ("U-ZU-MA-") and puff away; Naruto brings the last word down.
local function barrage(c,body,dt)
	local b=body.owner.target
	if not b or b.health<=0 then return end
	local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(body.angle or 0)):VectorToWorldSpace(body.line or Vector3.new(0,0,-1))
	local goal=b.root.Position+around*2.3-Vector3.new(0,1.1,0)
	body.position=c:clamp(body.position:Lerp(goal,math.min(1,dt*18)))
	Bodies.face(body,b.root.Position)
	if body.state=="Startup" and c.now>=body.actionAt+KICK.startup then
		body.state="Active"
		if Bodies.hitFrom(c,body,b,{damage=KICK.damage,reach=4.8,height=6,arc=-1,reaction="Juggled",push=2,up=22,stun=KICK.stun,tag="Uzumaki Barrage"}) then
			brawler().event(c,body.owner,"BarrageKick")
			c:pushImpact(b.root.Position,"uzumaki",false,{owner=body.owner.id,fighter=body.owner.fighterId,syllable=body.syllable})
		end
	elseif body.state=="Active" and c.now>=body.actionAt+KICK.startup+KICK.active then body.state="Recovery" end
end
-- The Rasengan's helper: beside his right hand, shaping the sphere in his
-- palm until the release (or until it is struck: the jutsu falls apart).
local function shape(c,body,dt)
	local a=body.owner
	local p=body.shaping
	if not p or a.pending~=p or a.health<=0 then
		body.shaping=nil;body.cast=nil;body.mode="spent";body.state="Recovery"
		body.expires=math.min(body.expires,c.now+.2)
		return
	end
	local fwd=flat(a.root.CFrame.LookVector)
	fwd=if fwd.Magnitude>.1 then fwd.Unit else Vector3.new(0,0,-1)
	local right=rightOf(a)
	local goal=a.root.Position+right*1.9+fwd*.7
	Bodies.move(c,body,Vector3.new(goal.X,c.match.origin.Y+3,goal.Z),60,dt)
	body.look=-right;body.cast="RasenganShape";body.state="Neutral"
end
-- A clone struck while it shapes the Rasengan: the technique falls apart
-- (the chakra is spent, the cooldown runs, a short recovery to punish).
local function lost(c,body,why,by)
	local a=body.owner
	local p=body.shaping
	if p and a.pending==p and a.state=="TechniqueChannel" and (why=="hit" or why=="blade" or why=="area") then
		a.pending=nil;c:setState(a,"Recovery",.4)
		c:pushImpact(a.root.Position,"rasengan",false,{phase="broken",owner=a.id,fighter=a.fighterId})
		c:cue(a,"RASENGAN • THE CLONE WAS BROKEN",.9)
		if by then c:cue(by,"CLONE BROKEN • NO RASENGAN",.8) end
		brawler().event(c,a,"RasenganBroken")
	end
end
-- The kunai transformed back into a clone near the target (the chakra chord
-- on his tool): it lands on the opponent's flank and strikes at once.
local function kunaiClone(c,p)
	local a=p.a
	local b=a.target
	local at=Vector3.new(p.position.X,c.match.origin.Y+3,p.position.Z)
	local line=flat(a.root.Position-b.root.Position)
	local side=if line.Magnitude>.1 and line.Unit:Cross(Vector3.yAxis):Dot(flat(at-b.root.Position))>=0 then 1 else -1
	local body=Bodies.spawn(c,a,{kind=CLONE,position=at,mode="flank",side=side,delay=0})
	if body then
		-- It pops where the kunai was and hops onto the flank before it strikes.
		body.rush=true;body.nextStrike=c.now+.16
		c:cue(a,"TRANSFORMATION • CLONE",.6)
		brawler().event(c,a,"CloneKunai")
	end
end
-- The Uzumaki Barrage (route payoff of the launcher route UzumakiKick): two
-- more clones keep the body up, and the heavy after the chase is his own
-- finisher (MoveGraphs.Legion.airFinisher: NARUTO UZUMAKI RENDAN).
local function uzumaki(c,a,b,p)
	a.lionUntil=c.now+2.1
	c:cue(a,"U-ZU-MA-KI • E, THEN HEAVY: NARUTO RENDAN",1)
	brawler().event(c,a,"UzumakiBarrage")
	c:pushImpact(b.root.Position,"uzumaki",false,{owner=a.id,fighter=a.fighterId,syllable="U"})
	local line=flat(a.root.Position-b.root.Position)
	line=if line.Magnitude>.1 then line.Unit else Vector3.new(0,0,-1)
	local syllables={"ZU","MA"}
	for k,angle in {125,-125} do
		c:schedule(c.now+.12+k*.18,function()
			if a.health<=0 or b.health<=0 or c.match.phase~="Duel" or not (b.reaction=="Launched" or b.reaction=="Juggled") then return end
			local around=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(angle)):VectorToWorldSpace(line)
			local body=Bodies.spawn(c,a,{kind=CLONE,position=b.root.Position+around*2.3-Vector3.new(0,1.1,0),ephemeral=true,life=.42,
				mode="barrage",airborne=true,state="Startup",action="BarrageKick"})
			if body then body.line=line;body.angle=angle;body.syllable=syllables[k] end
		end)
	end
end
function Legion.install(Techniques)
	Bodies.controllers.guard=persistent
	Bodies.controllers.flank=persistent
	Bodies.controllers.barrage=barrage
	Bodies.controllers.shape=shape
	Bodies.onDispel[CLONE]=lost
	Bodies.transforms[CLONE]=kunaiClone
	brawler().payoffs.uzumaki=uzumaki
	-- Kage Bunshin: one clone at his side (two at most). Near the opponent it
	-- goes straight out to a flank.
	local function canClone(c,a)
		if Bodies.blocked(c,a) then c:cue(a,"NINE-TAILS CHAKRA • NO CLONES",.6);return false end
		if Bodies.count(c,a,CLONE)>=(tune(a).Max or 2) then c:cue(a,"TWO CLONES AT MOST",.6);return false end
		return true
	end
	Techniques.ShadowClone={
		check=canClone,
		execute=function(c,a)
			local side=nextSide(a)
			local b=a.target
			local near=b~=nil and b.health>0 and (b.root.Position-a.root.Position).Magnitude<=16
			local body=Bodies.spawn(c,a,{kind=CLONE,position=aside(c,a,side),mode=if near then "flank" else "guard",side=side,delay=.3})
			if not body then return end
			c:cue(a,"SHADOW CLONE • "..Bodies.count(c,a,CLONE).." / "..(tune(a).Max or 2),.7)
			brawler().event(c,a,"ShadowClone")
		end,
	}
	-- Tajū Kage Bunshin: clones burst out on both sides at once and charge.
	Techniques.MassShadowClone={
		check=canClone,
		execute=function(c,a)
			local made=0
			for _,side in {1,-1} do
				local body=Bodies.spawn(c,a,{kind=CLONE,position=aside(c,a,side,3.2),mode="flank",side=side,delay=.2})
				if body then body.rush=true;made+=1 end
			end
			c:cue(a,"MULTI SHADOW CLONE",.8)
			if made>0 then brawler().event(c,a,"MassShadowClone") end
		end,
	}
	-- Rasengan, Part I: he cannot shape it alone. A free clone comes to his
	-- side and shapes it through the channel; with none he makes one for it
	-- (CloneCost more chakra, a longer channel). Striking that clone breaks
	-- the jutsu. In the Nine-Tails cloak: no clone, almost no wind-up.
	Techniques.CloneRasengan={
		check=function(c,a,spec)
			if Bodies.blocked(c,a) or Bodies.free(c,a,CLONE) then return true end
			return a.chakra>=spec.Cost+(spec.CloneCost or 12)
		end,
		start=function(c,a,pending)
			local spec=table.clone(pending.spec);pending.spec=spec
			-- (A channel lengthened elsewhere, the tutorial's interrupt step, stays long.)
			if Bodies.blocked(c,a) then
				spec.Channel=math.min(spec.Channel,spec.CloakChannel or .2);pending.cloak=true
				c:cue(a,"NINE-TAILS RASENGAN",.6)
			else
				local body=Bodies.free(c,a,CLONE)
				if body then
					c:cue(a,"RASENGAN • THE CLONE SHAPES IT",spec.Channel)
				else
					a.chakra=math.max(0,a.chakra-(spec.CloneCost or 12))
					spec.Channel=math.max(spec.Channel,spec.SoloChannel or .6)
					body=Bodies.spawn(c,a,{kind=CLONE,position=aside(c,a,1,1.9),ephemeral=true,life=spec.Channel+1})
					c:cue(a,"RASENGAN • A CLONE FOR IT",spec.Channel)
				end
				if body then body.mode="shape";body.shaping=pending;body.cast="RasenganShape";body.expires=math.max(body.expires,c.now+spec.Channel+1);pending.shaper=body end
			end
			a.untilTime=c.now+spec.Channel
		end,
		execute=function(c,a,pending)
			local shaper=pending.shaper
			if shaper and not shaper.alive then return end
			local Brawler=brawler()
			Brawler.start(c,a,"DashAttack")
			local p=a.pending
			if not p then return end
			p.spec=table.clone(p.spec)
			p.spec.damage=pending.spec.Damage;p.spec.travel=10;p.spec.recovery=.45
			p.spec.reaction="Knockback";p.spec.impulse=Vector3.new(0,22,74);p.spec.stun=.62
			p.rasengan=true;a.travelRemaining=10
			-- (One variant: the client draws it red in the cloak.)
			a.attackVariant="Rasengan"
			c:pushImpact(a.root.Position,"burst",false,{owner=a.id,fighter=a.fighterId,cloak=pending.cloak})
			Brawler.event(c,a,"Rasengan")
		end,
	}
end
return Legion
