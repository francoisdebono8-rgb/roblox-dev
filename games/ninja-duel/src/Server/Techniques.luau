-- Each entry supplies prerequisites and payoff. The combat pipeline owns cost,
-- channel, interruption, active window and recovery for every entry.
local Techniques = {}
local Elements=require(script.Parent.Elements)
-- Flying Thunder God seals. Minato can hold up to two planted kunai, one seal
-- placed on the opponent's body (a marked kunai that connects), and the marked
-- kunai still in flight. The stick chooses between them; with no input the
-- seal closest to the opponent wins, and a kunai in flight always does.
local MAX_PLANTED=2
local BODY_SEAL=5
Techniques.RANGE=90
local function syncAnchor(a)
	-- a.anchor mirrors the newest planted seal for HUD, AI and tooling.
	a.anchor=nil
	for _,entry in a.anchors or {} do if not entry.actor then a.anchor=entry end end
end
local function seals(c,a,now)
	local list={}
	local flying=c:markedInFlight(a)
	if flying then table.insert(list,{position=flying.position,flying=flying}) end
	local known={}
	for _,entry in a.anchors or {} do
		known[entry]=true
		if entry.expires>now and (not entry.actor or entry.actor.health>0) then
			table.insert(list,{position=if entry.actor then entry.actor.root.Position else entry.position,anchor=entry,body=entry.actor~=nil})
		end
	end
	-- A seal written directly into the single legacy slot still counts.
	if a.anchor and not known[a.anchor] and a.anchor.expires>now then table.insert(list,{position=a.anchor.position,anchor=a.anchor}) end
	-- Yellow Flash: a body he has just launched, knocked away or splatted (his
	-- chase window is open) is a destination by itself. No seal is spent on it;
	-- the chase window is.
	local tune=a.def.Awakening
	local b=a.target
	if tune and tune.FlashPursuit and (a.awakenUntil or 0)>now and b and b.health>0 and (a.pursuitUntil or 0)>now then
		local onBody=false
		for _,seal in list do if seal.body then onBody=true end end
		if not onBody then table.insert(list,{position=b.root.Position,body=true,virtual=true}) end
	end
	return list
end
Techniques.seals=seals
local function pick(c,a,now,range)
	local best,bestScore
	local stick=Vector3.new(a.move.X,0,a.move.Z)
	for _,seal in seals(c,a,now) do
		local gap=(seal.position-a.root.Position).Magnitude
		if gap<=range then
			local score
			if seal.flying then score=1000
			else
				local toward=Vector3.new(seal.position.X-a.root.Position.X,0,seal.position.Z-a.root.Position.Z)
				if stick.Magnitude>.4 and toward.Magnitude>2 then
					local dot=stick.Unit:Dot(toward.Unit)
					if dot>.3 then score=500+dot*100-gap*.2 end
				end
				if not score then score=100-(if a.target then (seal.position-a.target.root.Position).Magnitude else gap) end
			end
			if not bestScore or score>bestScore then best,bestScore=seal,score end
		end
	end
	return best
end
Techniques.pickSeal=pick
local function sealOf(c,a,now)
	local seal=pick(c,a,now,math.huge)
	if seal then return seal.position,seal.flying end
	return nil,nil
end
Techniques.sealOf=sealOf
function Techniques.consumeSeal(c,a,seal)
	if seal.virtual then a.pursuitUntil=0;return end
	if seal.flying then seal.flying.dead=true;c:removeProjectile(seal.flying);return end
	local entry=seal.anchor
	if not entry then return end
	if entry.part then entry.part:Destroy() end
	local index=a.anchors and table.find(a.anchors,entry)
	if index then table.remove(a.anchors,index) end
	if a.anchor==entry then a.anchor=nil end
	syncAnchor(a)
end
function Techniques.expireSeals(c,a,now)
	if a.anchor and a.anchor.expires<=now and not (a.anchors and table.find(a.anchors,a.anchor)) then
		if a.anchor.part then a.anchor.part:Destroy() end
		a.anchor=nil
	end
	if not a.anchors then return end
	local changed=false
	for i=#a.anchors,1,-1 do
		local entry=a.anchors[i]
		if entry.expires<=now or (entry.actor and entry.actor.health<=0) then
			if entry.part then entry.part:Destroy() end
			table.remove(a.anchors,i);changed=true
		end
	end
	if changed then syncAnchor(a) end
	-- Skill build (Kunai Recall): running over a planted kunai picks it up.
	local recall=a.def.SealRecall
	if recall and a.health>0 and not a.reaction then Techniques.recall(c,a,now,recall) end
end
-- Kunai Recall (SkillTrees Flashstep.KunaiRecall): standing on one of his own
-- planted kunai removes it and refunds a little chakra. A seal planted under
-- 0.6 s ago is never swallowed by the throw that just planted it.
function Techniques.recall(c,a,now,recall)
	for i=#a.anchors,1,-1 do
		local entry=a.anchors[i]
		if not entry.actor and now-(entry.plantedAt or now)>=.6 then
			local d=entry.position-a.root.Position
			if Vector3.new(d.X,0,d.Z).Magnitude<=recall.Radius and math.abs(d.Y)<4 then
				if entry.part then entry.part:Destroy() end
				table.remove(a.anchors,i);syncAnchor(a)
				a.chakra=math.min(a.def.Chakra or 100,a.chakra+recall.Refund)
				c:cue(a,"KUNAI RECOVERED • +"..recall.Refund.." CHAKRA",.7)
				require(script.Parent.Brawler).event(c,a,"KunaiRecall")
				return entry
			end
		end
	end
	return nil
end
-- Plant a seal on a surface, or on the opponent's body when the kunai connects.
function Techniques.plant(c,a,surface,normal,victim)
	a.anchors=a.anchors or {}
	a.sealSerial=(a.sealSerial or 0)+1
	local entry
	if victim then
		for i=#a.anchors,1,-1 do
			if a.anchors[i].actor then
				if a.anchors[i].part then a.anchors[i].part:Destroy() end
				table.remove(a.anchors,i)
			end
		end
		entry={actor=victim,position=victim.root.Position,expires=c.now+BODY_SEAL,id=a.sealSerial,plantedAt=c.now,
			part=c:effect("Body seal",victim.root.Position,a.color,Vector3.new(.6,.6,.6),BODY_SEAL)}
		c:cue(a,"SEAL ON TARGET • 2 TO FOLLOW",.9)
	else
		local planted={}
		for i,existing in a.anchors do if not existing.actor then table.insert(planted,i) end end
		if #planted>=MAX_PLANTED then
			local oldest=a.anchors[planted[1]]
			if oldest.part then oldest.part:Destroy() end
			table.remove(a.anchors,planted[1])
		end
		local offset=if normal.Y>0.5 then Vector3.new(0,3,0) else normal*3+Vector3.new(0,1,0)
		local at=c:clamp(surface+offset)
		-- Skill build (Seal Ink) may lengthen how long a planted seal holds.
		local life=(a.def.Seals and a.def.Seals.PlantedLife) or 12
		entry={position=at,surface=surface,normal=normal,expires=c.now+life,id=a.sealSerial,plantedAt=c.now,
			part=c:effect("Anchor",surface+normal*0.2,a.color,Vector3.new(1.3,0.2,1.3),life)}
		local count=0
		for _,existing in a.anchors do if not existing.actor then count+=1 end end
		c:cue(a,if count>=1 then "SECOND SEAL PLANTED" else "SEAL PLANTED")
	end
	table.insert(a.anchors,entry)
	syncAnchor(a)
	return entry
end
-- Minato's substitution can reach a planted seal: the farthest one from the
-- attacker that is still in range. Spending a seal to escape is the cost.
function Techniques.escapeSeal(c,a,now)
	local attacker=a.target
	local best,bestGap
	for _,seal in seals(c,a,now) do
		if not seal.flying and not seal.body then
			local gap=(seal.position-a.root.Position).Magnitude
			local fromAttacker=if attacker then (seal.position-attacker.root.Position).Magnitude else gap
			if gap<=70 and fromAttacker>9 and (not bestGap or fromAttacker>bestGap) then best,bestGap=seal,fromAttacker end
		end
	end
	return best
end
Techniques.MarkedBlade = {
	check = function() return true end,
	execute = function(c, a, pending, now)
		local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*30
		c:projectile(a, aim, 82, pending.spec.Range, pending.spec.Damage, "marked", function(position, normal, victim)
			if a.health <= 0 or c.match.phase ~= "Duel" then return end
			Techniques.plant(c,a,position,normal,victim)
		end)
	end,
}
Techniques.Flashstep = {
	check = function(c, a, _spec, now)
		return pick(c,a,now,Techniques.RANGE)~=nil
	end,
	execute = function(c,a,_pending,now)
		local seal=pick(c,a,now,Techniques.RANGE)
		if not seal then c:cue(a,"SEAL LOST"); return end
		local target=c:clamp(seal.position)
		-- A seal on (or right next to) the opponent puts Minato beside them. The
		-- stick picks the side; with no input he lands on the far side from where
		-- he left. Choosing the side is the mixup.
		local victim=a.target
		local beside=false
		if victim and victim.health>0 then
			local toward=victim.root.Position-seal.position
			local flatGap=Vector3.new(toward.X,0,toward.Z).Magnitude
			if flatGap<7 or seal.body then
				local stick=Vector3.new(a.move.X,0,a.move.Z)
				local side
				if stick.Magnitude>.4 then side=stick.Unit
				else
					side=Vector3.new(victim.root.Position.X-a.root.Position.X,0,victim.root.Position.Z-a.root.Position.Z)
					side=if side.Magnitude<.1 then -victim.root.CFrame.LookVector else side.Unit
				end
				target=c:clamp(Vector3.new(victim.root.Position.X,math.max(victim.root.Position.Y,c.match.origin.Y+3),victim.root.Position.Z)+side*3.4)
				beside=true
			end
		end
		if target.Y<c.match.origin.Y+3 then target=Vector3.new(target.X,c.match.origin.Y+3,target.Z) end
		-- Never relocate into solid geometry, and never accept a client destination.
		local overlaps = workspace:GetPartBoundsInBox(CFrame.new(target),Vector3.new(2.6,4.6,2.6),c:overlapParams())
		for _, p in overlaps do
			if p.CanCollide and not p:IsDescendantOf(a.model) then
				if beside then target=c:clamp(seal.position);beside=false;break end
				c:cue(a,"ARRIVAL BLOCKED"); return
			end
		end
		local departure=a.root.Position
		c:effect("Departure",departure,a.color,Vector3.new(2,5,2),0.3)
		c:relocate(a,target)
		-- Arrive already facing the opponent so the follow-up starts on frame one.
		if victim and victim.health>0 then
			local face=victim.root.Position-a.root.Position;face=Vector3.new(face.X,0,face.Z)
			if face.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
		end
		a.airborne=a.root.Position.Y>c.match.origin.Y+4.2
		c:effect("Arrival",target,a.color,Vector3.new(3,5,3),0.45)
		Techniques.consumeSeal(c,a,seal)
		-- Yellow Flash: every jump leaves its own return point (a floor seal
		-- where he stood) and the arrival stays open longer, so relocations
		-- chain A -> B -> A instead of ending on the first arrival.
		local tune=a.def.Awakening
		local awake=tune~=nil and (a.awakenUntil or 0)>now
		if awake and tune.FlashWake then
			local wake=Techniques.plant(c,a,Vector3.new(departure.X,c.match.origin.Y,departure.Z),Vector3.yAxis)
			wake.wake=true
			require(script.Parent.Brawler).event(c,a,"FlashWake")
		end
		-- The arrival opens a short window in which a strike (or Rasengan, with
		-- almost no wind-up) cancels the technique recovery.
		a.flashUntil=now+(if awake and tune.Arrival then tune.Arrival else .55);a.teleportAt=now
		a.teleportSerial=(a.teleportSerial or 0)+1
		c:pushImpact(target,"teleport",false,{owner=a.id,fighter=a.fighterId,from=departure,to=target,projectile=seal.flying and seal.flying.id,awake=awake,body=seal.virtual==true})
		local left=#seals(c,a,now)
		if seal.virtual then c:cue(a,"YELLOW FLASH • FLYING THUNDER GOD TO THE BODY",.7)
		else c:cue(a,if left>0 then "FLYING THUNDER GOD • "..left.." SEAL"..(if left>1 then "S" else "").." LEFT" else "FLYING THUNDER GOD",.7) end
	end,
}
Techniques.BurstStrike = {
	check = function() return true end,
	execute = function(c,a,pending)
		local Brawler=require(script.Parent.Brawler)
		if pending.variant=="RasenganDrop" then
			-- Airborne (chase, jump, wall): the Rasengan is driven straight down
			-- into the opponent and the floor, ending the air phase.
			Brawler.start(c,a,"Slam")
			local spec=table.clone(a.pending.spec)
			-- Skill build (Rasengan Drive): DropReaction "Spiked" makes the body
			-- bounce once off the floor for a pick-up instead of a flat knockdown.
			spec.damage=pending.spec.Damage*.9;spec.reaction=pending.spec.DropReaction or "Knockdown";spec.impulse=Vector3.new(0,-70,16);spec.stun=.92
			spec.width=6.5;spec.height=8
			a.pending.spec=spec;a.pending.rasengan=true;a.attackVariant="RasenganDrop"
			c:pushImpact(a.root.Position,"burst",false,{owner=a.id,fighter=a.fighterId})
			return
		end
		-- Channel commits chakra; release becomes a travelling physical attack.
		Brawler.start(c,a,"DashAttack")
		a.pending.spec=table.clone(a.pending.spec)
		a.pending.spec.damage=pending.spec.Damage;a.pending.spec.travel=10;a.pending.spec.recovery=.48
		-- Rasengan drives the body away spinning instead of a jab's stagger.
		a.pending.spec.reaction="Knockback";a.pending.spec.impulse=Vector3.new(0,22,70);a.pending.spec.stun=.62
		a.pending.rasengan=true;a.attackVariant="Rasengan"
		a.travelRemaining=10
		if pending.variant=="FlashRasengan" then
			-- Out of a teleport he is already beside the target: a short, fast thrust.
			a.pending.spec.travel=5;a.travelRemaining=5;a.pending.spec.recovery=.4
		end
		c:pushImpact(a.root.Position,"burst",false,{owner=a.id,fighter=a.fighterId})
	end,
}
Techniques.Read = {
	check = function() return true end,
	execute = function(c,a,pending,now)
		a.readUntil = now + pending.spec.Active
		c:effect("Read",a.root.Position,a.color,Vector3.new(4,0.2,4),pending.spec.Active)
		c:cue(a,"READ WINDOW")
	end,
}
Techniques.NeedleFan = {
	check = function() return true end,
	execute = function(c,a,pending)
		local direction = pending.aim-a.root.Position
		if direction.Magnitude < 0.1 then direction = a.root.CFrame.LookVector end
		-- Five real shuriken in a fan: the centre blade tracks, the outer ones
		-- close the sideways escape.
		local origin=c.launchPoint(a,"Shuriken")
		for _, angle in { -0.2,-0.1,0,0.1,0.2 } do
			local d = CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(direction.Unit)
			c:projectile(a,origin+d*pending.spec.Range,74,pending.spec.Range,pending.spec.Damage,"shuriken",nil,{origin=origin})
		end
		-- Shadow Shuriken: two more blades hidden behind the fan, released a beat
		-- later at wherever the opponent went to dodge it.
		for k=1,2 do
			c:schedule(c.now+.26+k*.06,function()
				if a.health<=0 or a.reaction or a.state=="Stunned" or not a.target or a.target.health<=0 then return end
				local victim=a.target
				local lead=victim.root.AssemblyLinearVelocity*Vector3.new(1,0,1)*.18
				if pending.spec.FlankBlades then
					-- Skill build (Flank Blades): each hidden blade is redirected
					-- beside the opponent and comes in from a flank, past a frontal guard.
					local toward=Vector3.new(victim.root.Position.X-a.root.Position.X,0,victim.root.Position.Z-a.root.Position.Z)
					toward=if toward.Magnitude>.1 then toward.Unit else a.root.CFrame.LookVector
					local side=Vector3.new(-toward.Z,0,toward.X)*(if k==1 then -1 else 1)
					-- Beside and a little past the body, like Geometry's meeting point.
					local from=victim.root.Position+side*6+toward*1.5
					c:pushImpact(from,"clash",false,{owner=a.id,direction=-side})
					c:projectile(a,victim.root.Position+lead,86,12,pending.spec.Damage,"shuriken",nil,{origin=from})
					return
				end
				c:projectile(a,victim.root.Position+lead+a.root.CFrame.RightVector*(if k==1 then -.6 else .6),86,pending.spec.Range,pending.spec.Damage,"shuriken")
			end)
		end
		c:cue(a,"SHADOW SHURIKEN",.6)
	end,
}
-- Genjutsu: Mirage. Itachi leaves his image standing where he was and
-- withdraws a few steps straight back behind it, on the very line the
-- opponent is watching: the image covers him. A swing that reaches the image
-- (and not the body) gives the read away: the image breaks, the swing is
-- exposed and Itachi steps through his image with the counter palm. Trusting
-- the body works: walking into the image dissolves it, a blade thrown at him
-- passes through it, and any blow (his or yours) breaks the genjutsu.
local MIRAGE={Withdraw=5.5,Life=2.6,Touch=1.6,Reach=2,Exposed=.55,Counter=1.1,CounterReach=9}
Techniques.MIRAGE=MIRAGE
Techniques.MirageCast = {
	check = function(c,a,spec)
		return c:targetValid(a,a.target,spec.Range,0.35)
	end,
	execute = function(c,a,pending,now)
		if not c:targetValid(a,a.target,pending.spec.Range,0.35) then c:cue(a,"CAST LOST SIGHT"); return end
		local victim = a.target
		-- The Byakugan sees chakra, not light: the image has none.
		if victim.def.Byakugan then
			c:cue(victim,"BYAKUGAN • SEES THROUGH",1);c:cue(a,"GENJUTSU • SEEN THROUGH",1)
			c:pushImpact(a.root.Position,"mirage",false,{owner=a.id,fighter=a.fighterId,phase="seen",victim=victim.id})
			return
		end
		local Motor=require(script.Parent.Motor)
		local image=a.root.Position
		local away=image-victim.root.Position;away=Vector3.new(away.X,0,away.Z)
		away=if away.Magnitude>.1 then away.Unit else -a.root.CFrame.LookVector
		if Motor.travel(a,c,away,MIRAGE.Withdraw)<2.5 then
			-- A wall behind him: the withdrawal becomes a slip to the side (the
			-- stick's side when it points there); the image still stands in front.
			local side=Vector3.new(-away.Z,0,away.X)
			local stick=Vector3.new(a.move.X,0,a.move.Z)
			if stick.Magnitude>.4 and stick:Dot(side)<0 then side=-side end
			if Motor.travel(a,c,side,MIRAGE.Withdraw)<2.5 then Motor.travel(a,c,-side,MIRAGE.Withdraw) end
		end
		local face=victim.root.Position-a.root.Position;face=Vector3.new(face.X,0,face.Z)
		if face.Magnitude>.1 then a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+face) end
		victim.illusionUntil=now+MIRAGE.Life;victim.illusionAt=now;victim.illusionBy=a;victim.illusionKind="image"
		victim.decoyPosition=c:clamp(image)
		c:effect("Echo",victim.decoyPosition,a.color,Vector3.new(2,5,1),MIRAGE.Life)
		c:pushImpact(victim.decoyPosition,"mirage",false,{owner=a.id,fighter=a.fighterId,phase="cast",from=a.root.Position,to=victim.decoyPosition,victim=victim.id})
		c:cue(victim,"GENJUTSU • TRUST THE BODY",MIRAGE.Life)
		c:cue(a,"GENJUTSU • THE IMAGE HOLDS",1)
		require(script.Parent.Brawler).event(c,a,"Mirage")
	end,
}
-- Ends a genjutsu on `a` (the deceived fighter). why: "catch" | "touch" |
-- "break" | "expire"; the client finishes the image accordingly.
function Techniques.breakIllusion(c,a,why)
	local at=a.decoyPosition
	local caster=a.illusionBy
	a.illusionUntil=0;a.decoyPosition=nil;a.illusionBy=nil;a.illusionKind=nil;a.illusionAt=nil
	if at and why~="expire" then
		c:pushImpact(at,"mirage",false,{owner=caster and caster.id,fighter=caster and caster.fighterId,phase=why,victim=a.id})
	end
	if why=="touch" then
		c:cue(a,"GENJUTSU • DISPELLED",.7)
		if caster then c:cue(caster,"GENJUTSU • SEEN THROUGH",.7) end
	end
end
-- Every frame, for every fighter: a genjutsu image ends with its time, with
-- its caster, on any blow after it began (pain breaks it), or when the body
-- walks into the image. A skill-build echo (no kind) only keeps its timer.
function Techniques.stepIllusion(c,a,now)
	if (a.illusionUntil or 0)<=now then
		if a.decoyPosition or a.illusionKind then a.decoyPosition=nil;a.illusionBy=nil;a.illusionKind=nil;a.illusionAt=nil end
		return
	end
	if a.illusionKind~="image" then return end
	local caster=a.illusionBy
	local since=a.illusionAt or now
	if not caster or caster.health<=0 or (a.lastHurt or -10)>since or (caster.lastHurt or -10)>since then
		Techniques.breakIllusion(c,a,"break");return
	end
	local d=a.decoyPosition and a.decoyPosition-a.root.Position
	if d and a.state~="Startup" and a.state~="Active" and Vector3.new(d.X,0,d.Z).Magnitude<=MIRAGE.Touch and math.abs(d.Y)<4 then
		Techniques.breakIllusion(c,a,"touch")
	end
end
-- The swing bit the image: it breaks, the swing is exposed, the counter palm
-- opens with the reach to step through the image to the body.
function Techniques.mirageCatch(c,a,caster,pending,now)
	local legacy=a.illusionKind==nil
	Techniques.breakIllusion(c,a,"catch")
	caster.counterUntil=now+MIRAGE.Counter;caster.bonusUntil=now+MIRAGE.Counter
	caster.counterReach={expires=now+MIRAGE.Counter,max=MIRAGE.CounterReach,variant="MirageCounter"}
	require(script.Parent.Brawler).event(c,caster,"MirageCatch")
	c:cue(caster,"GENJUTSU • CAUGHT • PUNISH",1);c:cue(a,"GENJUTSU • EXPOSED",1)
	pending.spec=table.clone(pending.spec);pending.spec.recovery+=.32
	if not legacy then
		-- Exposed for a moment (a stun the counter reaches), not merely a longer
		-- recovery a dodge could cancel.
		c:schedule(now,function()
			if a.health>0 and a.state=="Recovery" and not a.reaction then c:setState(a,"Stunned",MIRAGE.Exposed) end
		end)
	end
end
-- A committed swing that touched nothing (Combat, end of the active window).
-- Under a genjutsu image, a swing that reached the image is caught; under
-- Sharingan Focus any swing that misses close to Itachi is read. A skill-build
-- echo keeps its own rule: any swing at all while it holds.
function Techniques.whiffRead(c,a,pending,now)
	local caster=a.illusionBy or a.target
	if (a.illusionUntil or 0)>now and caster and caster.health>0 then
		local struck=false
		if a.illusionKind=="image" and a.decoyPosition then
			local d=a.decoyPosition-a.root.Position
			local flat=Vector3.new(d.X,0,d.Z)
			local reach=(pending.spec.range or 6)+MIRAGE.Reach
			struck=flat.Magnitude<=reach and math.abs(d.Y)<6 and (flat.Magnitude<1 or a.root.CFrame.LookVector:Dot(flat.Unit)>.3)
		elseif a.illusionKind==nil then
			struck=caster.fighterId=="Mirage"
		end
		if struck then Techniques.mirageCatch(c,a,caster,pending,now);return end
	end
	local eye=a.target
	local tune=eye and eye.def.Awakening
	if eye and eye.health>0 and tune and tune.WhiffRead and (eye.awakenUntil or 0)>now and not eye.reaction then
		local d=eye.root.Position-a.root.Position
		local flat=Vector3.new(d.X,0,d.Z)
		if flat.Magnitude<=tune.WhiffRead and math.abs(d.Y)<6 and (flat.Magnitude<1 or a.root.CFrame.LookVector:Dot(flat.Unit)>.2) then
			eye.counterUntil=math.max(eye.counterUntil or 0,now+.9);eye.bonusUntil=now+.9
			eye.counterReach={expires=now+.9,max=5,variant="ReadCounter"}
			pending.spec=table.clone(pending.spec);pending.spec.recovery+=.22
			c:pushImpact(eye.root.Position,"read",false,{owner=eye.id,fighter=eye.fighterId,victim=a.id,phase="whiff"})
			c:cue(eye,"SHARINGAN • WHIFF READ • PUNISH",.8);c:cue(a,"READ • EXPOSED",.6)
			require(script.Parent.Brawler).event(c,eye,"WhiffRead")
		end
	end
end
Techniques.Quickstep={
	check=function() return true end,
	execute=function(c,a,pending,now)
		local direction=if a.move.Magnitude>0.2 then a.move else a.root.CFrame.RightVector
		local departure=a.root.Position
		local moved=require(script.Parent.Motor).travel(a,c,direction,11)
		c:effect("Quickstep",a.root.Position,a.color,Vector3.new(2,3,2),0.22)
		c:pushImpact(departure,"quickstep",false,{owner=a.id,fighter=a.fighterId,to=a.root.Position})
		-- Skill build (Quickstep Cut): the step opens the same arrival window as a
		-- teleport, so the new angle converts (strike, launcher or Rasengan).
		local arrival=pending and pending.spec.Arrival
		if arrival and moved>3 then
			a.flashUntil=now+arrival
			c:cue(a,"ANGLE CREATED • STRIKE",arrival)
			return
		end
		c:cue(a,if moved>3 then "ANGLE CREATED" else "ANGLE BLOCKED")
	end,
}
-- Great Fireball; on an opponent held by Sasuke's wire it becomes the Dragon
-- Flame: the fire runs along the wire and cannot miss.
Techniques.FireBloom={check=function() return true end,execute=function(c,a,pending,now)
	local b=a.wireVictim
	if b and b.reaction=="Bound" and b.boundBy==a and b.health>0 then
		a.wireVictim=nil;b.boundBy=nil
		c.damageTag="Dragon Flame"
		local hit=c:damage(a,b,pending.spec.Damage,true,false)
		c.damageTag=nil
		if c.match.phase~="Duel" then return end
		c:pushImpact(b.root.Position,"fire",true,{owner=a.id,normal=Vector3.yAxis,from=a.root.Position})
		if hit then
			local away=b.root.Position-a.root.Position;away=Vector3.new(away.X,0,away.Z)
			away=if away.Magnitude>.1 then away.Unit else a.root.CFrame.LookVector
			local Brawler=require(script.Parent.Brawler)
			Brawler.react(c,b,"Knockdown",away*30+Vector3.new(0,22,0),.8,a)
		end
		c:cue(a,"KATON • DRAGON FLAME",1)
		return
	end
	Elements.fire(c,a,pending,now)
end}
-- Wire Trap: a shuriken trailing ninja wire; a body it reaches is bound.
Techniques.WireTrap={
	check=function() return true end,
	execute=function(c,a,pending)
		local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*20
		c:projectile(a,aim,86,pending.spec.Range,pending.spec.Damage,"wire",nil,{radius=.7,riders=if pending.spec.WallPin then {wallPin=pending.spec.WallPin} else nil})
		c:cue(a,"WIRE TRAP",.5)
	end,
}
-- `riders` (skill builds): bind = a shorter bind for wired hidden blades;
-- wallPin = {Range, Bind}: a wall close behind the body along the wire ties it
-- against the surface for longer (Wire Pin).
function Techniques.wireBind(c,owner,victim,riders,direction)
	if victim.health<=0 then return end
	local Brawler=require(script.Parent.Brawler)
	local duration=(riders and riders.bind) or 1.0
	local pinned=false
	local pin=riders and riders.wallPin
	local along=direction and Vector3.new(direction.X,0,direction.Z)
	if pin and along and along.Magnitude>.05 then
		local hit=workspace:Raycast(victim.root.Position,along.Unit*pin.Range,c:rayParams(true))
		if hit and math.abs(hit.Normal.Y)<.3 and Brawler.splatSurface(hit.Instance) then
			c:relocate(victim,Vector3.new(hit.Position.X,victim.root.Position.Y,hit.Position.Z)+hit.Normal*1.7)
			duration=pin.Bind;pinned=true
			c:pushImpact(victim.root.Position,"pin",false,{owner=owner.id,normal=hit.Normal})
		end
	end
	Brawler.react(c,victim,"Bound",Vector3.zero,duration,owner)
	victim.boundBy=owner;owner.wireVictim=victim
	-- The wire is a conductor while it holds: Sasuke's lightning may run down it
	-- (ChakraCombat.conduct), bounded from the moment the bind started.
	victim.boundAt=c.now;victim.wireConducts=0
	c:cue(owner,if pinned then "WIRED TO THE WALL • 1 = DRAGON FLAME" else "WIRED • 1 = DRAGON FLAME",.9);c:cue(victim,"WIRED • X TO ESCAPE",.9)
	Brawler.event(c,owner,if pinned then "WirePin" else "WireBind")
end
-- Chidori: the charge is the channel (slowed, interruptible); the release is
-- a straight lightning thrust that ends the fight's momentum either way.
Techniques.Chidori={
	check=function() return true end,
	execute=function(c,a,pending)
		local Brawler=require(script.Parent.Brawler)
		a.stringCancel=nil
		Brawler.start(c,a,"ChidoriThrust")
		if a.pending then a.pending.spec.damage=pending.spec.Damage end
		c:pushImpact(a.root.Position,"chidori",true,{owner=a.id})
		c:cue(a,"CHIDORI",.8)
	end,
}
-- Gaara ----------------------------------------------------------------
-- Sand Coffin: a wave of sand runs along the ground; a body it reaches is bound
-- (held where it stands) and buried a beat later unless it substitutes out.
function Techniques.bindInSand(c,owner,victim)
	if victim.health<=0 or victim.invulnerableUntil>c.now then return end
	local Brawler=require(script.Parent.Brawler)
	Brawler.react(c,victim,"Bound",Vector3.zero,1.25,owner)
	victim.boundBy=owner
	c:cue(owner,"SAND COFFIN • BOUND",.8);c:cue(victim,"BOUND • X TO ESCAPE",.9)
	local spec
	for _,t in owner.def.Techniques do if t.Id=="SandCoffin" then spec=t end end
	c:schedule(c.now+1.05,function()
		if victim.reaction~="Bound" or victim.boundBy~=owner or owner.health<=0 or victim.health<=0 then return end
		victim.boundBy=nil
		c.damageTag="Sand Burial"
		c:damage(owner,victim,(spec and spec.Damage) or 18,false,false)
		c.damageTag=nil
		if c.match.phase~="Duel" or victim.health<=0 then return end
		Brawler.react(c,victim,"Knockdown",Vector3.new(0,16,0),.7,owner)
		c:pushImpact(victim.root.Position,"sandburial",true,{owner=owner.id})
		c:cue(owner,"SAND BURIAL",.8)
	end)
end
Techniques.SandCoffin={
	check=function() return true end,
	execute=function(c,a,pending)
		local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*20
		local origin=c.launchPoint(a,"Ground")
		local flat=Vector3.new(aim.X-origin.X,0,aim.Z-origin.Z)
		if flat.Magnitude<1 then flat=a.root.CFrame.LookVector*Vector3.new(1,0,1) end
		c:projectile(a,origin+flat.Unit*pending.spec.Range+Vector3.new(0,2,0),pending.spec.Speed or 46,pending.spec.Range,4,"sandwave",nil,{origin=origin+Vector3.new(0,1,0),radius=1.8,growth=.6})
		c:cue(a,"SAND COFFIN",.6)
	end,
}
Techniques.SandShuriken={
	check=function() return true end,
	execute=function(c,a,pending)
		local direction=pending.aim-a.root.Position
		if direction.Magnitude<.1 then direction=a.root.CFrame.LookVector end
		local origin=c.launchPoint(a,"Palm")
		for _,angle in {-.25,-.15,-.05,.05,.15,.25} do
			local d=CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(direction.Unit)
			c:projectile(a,origin+d*pending.spec.Range,80,pending.spec.Range,pending.spec.Damage,"sand",nil,{origin=origin,radius=.5})
		end
	end,
}
-- Desert Wave: a wall of sand rises in front of him and throws close
-- attackers away; blades and fire in it are swallowed.
Techniques.DesertWave={
	check=function() return true end,
	execute=function(c,a,pending)
		local Brawler=require(script.Parent.Brawler)
		local reach=pending.spec.Range
		local look=a.root.CFrame.LookVector
		for i=#c.projectiles,1,-1 do
			local p=c.projectiles[i]
			local d=p.position-a.root.Position
			if p.a~=a and d.Magnitude<=reach and look:Dot(d.Unit)>.2 then
				table.remove(c.projectiles,i)
				c:pushImpact(p.position,"deflect",false,{projectile=p.id,kind=p.kind,owner=p.a.id})
			end
		end
		local b=a.target
		if b and b.health>0 then
			local d=b.root.Position-a.root.Position
			local flat=Vector3.new(d.X,0,d.Z)
			if flat.Magnitude<=reach and (flat.Magnitude<2 or look:Dot(flat.Unit)>.25) then
				c.damageTag="Desert Wave"
				local hit=c:damage(a,b,pending.spec.Damage,false,false)
				c.damageTag=nil
				if c.match.phase~="Duel" then return end
				if hit then Brawler.react(c,b,"Knockback",(if flat.Magnitude>.1 then flat.Unit else look)*48+Vector3.new(0,16,0),.55,a) end
			end
		end
		c:pushImpact(a.root.Position+look*4,"sandwall",true,{owner=a.id,direction=look})
		c:cue(a,"DESERT WAVE",.6)
	end,
}
-- Rock Lee (stress-test wave, DEC-015) -----------------------------------
-- Pure taijutsu: nothing here is moulded into a jutsu. His technique is a
-- strike started by the jutsu pipeline (like the Chidori thrust), his tool
-- button a kick (Combat: def.Tool "Deflect") and his escape a kick too
-- (Combat:substitute, Mode "burst"). The lotuses are Brawler.airFinisher.
local LeeRules=require(game:GetService("ReplicatedStorage").NinjaDuel.Rules)
-- Konoha Daisenpū: a spinning kick that crosses the gap and knocks away.
Techniques.LeafGreatWhirlwind={
	check=function() return true end,
	execute=function(c,a,pending)
		local Brawler=require(script.Parent.Brawler)
		a.stringCancel=nil
		Brawler.start(c,a,"GreatWhirlwind")
		if a.pending then a.pending.spec.damage=pending.spec.Damage end
		c:pushImpact(a.root.Position,"afterimage",false,{owner=a.id,fighter=a.fighterId})
		c:cue(a,"LEAF GREAT WHIRLWIND",.7)
	end,
}
-- Blades a kick can send away; fire, wind, palms and sand waves are jutsu
-- volumes and go through.
local DEFLECTABLE={kunai=true,marked=true,shuriken=true,wire=true,sand=true}
Techniques.DEFLECTABLE=DEFLECTABLE
-- An enemy blade near him, or one flying at him from within `Reach`.
function Techniques.bladeIncoming(c,a,tune)
	for _,p in c.projectiles do
		if p.a~=a and DEFLECTABLE[p.kind] and not p.dead and not p.planted then
			local offset=a.root.Position-p.position
			local gap=offset.Magnitude
			if gap<=tune.Radius or (gap<=(tune.Reach or 24) and gap>.1 and p.direction:Dot(offset.Unit)>.6) then return true end
		end
	end
	return false
end
-- One sweep of the kick: every blade inside the frontal arc (Arc: cosine of
-- the half angle) and Radius is kicked out of the air.
function Techniques.deflectSweep(c,a,tune)
	local look=a.root.CFrame.LookVector*Vector3.new(1,0,1)
	look=if look.Magnitude>.05 then look.Unit else Vector3.new(0,0,-1)
	local kicked=0
	for i=#c.projectiles,1,-1 do
		local p=c.projectiles[i]
		if p.a~=a and DEFLECTABLE[p.kind] and not p.planted then
			local d=p.position-a.root.Position
			local flat=Vector3.new(d.X,0,d.Z)
			if d.Magnitude<=tune.Radius and math.abs(d.Y)<5 and (flat.Magnitude<1.2 or look:Dot(flat.Unit)>=tune.Arc) then
				table.remove(c.projectiles,i);p.dead=true
				c:pushImpact(p.position,"deflect",false,{projectile=p.id,kind=p.kind,owner=p.a.id,direction=-p.direction})
				kicked+=1
			end
		end
	end
	if kicked>0 then
		-- The Counter-Rush rule: the next chakra dash is free for a moment.
		a.freeRushUntil=c.now+(tune.FreeRush or .6)
		a.deflected=(a.deflected or 0)+kicked
		require(script.Parent.Brawler).event(c,a,"Deflect")
		c:cue(a,"DEFLECTED • E: FREE RUSH",.7)
	end
	return kicked
end
-- The tool button (Fighters.Leaf.Deflect): a crescent kick whose sweep runs
-- from the press to the end of its active window. It is a real strike on a
-- body in reach; with no blade coming and nobody in reach it does nothing.
function Techniques.deflectKick(c,a)
	local tune=a.def.Deflect
	if not tune then return false,"No tool" end
	if a.reaction or a.wall or a.throwing or not LeeRules.canAct(a,c.now) then return false,"Committed" end
	if (a.deflectReadyAt or 0)>c.now then return false,"Tool recovering" end
	local b=a.target
	local close=b~=nil and b.health>0 and (b.root.Position-a.root.Position).Magnitude<=tune.Radius+2
	if not close and not Techniques.bladeIncoming(c,a,tune) then return false,"Nothing to deflect" end
	local Brawler=require(script.Parent.Brawler)
	a.deflectReadyAt=c.now+tune.Cooldown
	if not Brawler.start(c,a,"DeflectKick") then return false end
	local spec=a.pending.spec
	local serial=a.attackSerial
	local span=spec.startup+spec.active
	Techniques.deflectSweep(c,a,tune)
	for k=1,4 do
		c:schedule(c.now+span*k/4,function()
			if a.health<=0 or a.reaction or a.attackSerial~=serial then return end
			Techniques.deflectSweep(c,a,tune)
		end)
	end
	Brawler.event(c,a,"DeflectKick")
	return true
end
-- The Rupture (Fighters.Leaf.Substitution, Mode "burst"): Combat:substitute
-- has spent the charge and the chakra, given the i-frames and kept him where he
-- is; this is the kick. A close attacker is thrown off. One that was out of
-- reach, guarded or evaded it leaves him a longer recovery to punish.
function Techniques.rupture(c,a,attacker,twist)
	local Brawler=require(script.Parent.Brawler)
	c:pushImpact(a.root.Position,"repel",true,{owner=a.id,fighter=a.fighterId,direction=a.root.CFrame.LookVector})
	Brawler.event(c,a,"Rupture")
	local landed=false
	if attacker and attacker.health>0 then
		local away=attacker.root.Position-a.root.Position
		local flat=Vector3.new(away.X,0,away.Z)
		if flat.Magnitude<=(twist.Radius or 5.5) then
			c.damageTag="Rupture"
			local hit=c:damage(a,attacker,twist.Damage or 4,false,false)
			c.damageTag=nil
			if c.match.phase~="Duel" then return true end
			landed=hit and attacker.impactStyle~="block"
			if landed then
				local push=if flat.Magnitude>.1 then flat.Unit else a.root.CFrame.LookVector
				Brawler.react(c,attacker,"Knockback",push*(twist.Knockback or 40)+Vector3.new(0,12,0),.45,a)
			end
		end
	end
	if not landed then c:setState(a,"Recovery",twist.Whiff or .3) end
	c:cue(a,if landed then "RUPTURE" else "RUPTURE • READ",.7)
	if attacker then c:cue(attacker,if landed then "RUPTURE • THROWN OFF" else "RUPTURE • PUNISH HIS RECOVERY",.7) end
	return true
end
-- Neji -----------------------------------------------------------------
Techniques.ROTATION_REACH=7
Techniques.Rotation={
	check=function() return true end,
	execute=function(c,a,pending,now)
		local active=pending.spec.Active
		a.rotationUntil=now+active;a.rotationHit={};a.rotationDamage=pending.spec.Damage
		-- Skill builds: a wider dome (Reach) and blades sent back (Reflect).
		a.rotationReach=pending.spec.Reach;a.rotationReflect=pending.spec.Reflect
		a.invulnerableUntil=math.max(a.invulnerableUntil,now+active);a.rotationGuardUntil=a.invulnerableUntil
		c:pushImpact(a.root.Position,"rotation",true,{owner=a.id,fighter=a.fighterId,duration=active})
		c:cue(a,"EIGHT TRIGRAMS • ROTATION",.7)
	end,
}
Techniques.VacuumPalm={
	check=function() return true end,
	execute=function(c,a,pending)
		local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*20
		local origin=c.launchPoint(a,"Palm")
		local flat=Vector3.new(aim.X-origin.X,0,aim.Z-origin.Z)
		if flat.Magnitude<1 then flat=a.root.CFrame.LookVector*Vector3.new(1,0,1) end
		local goal=origin+flat.Unit*pending.spec.Range+Vector3.new(0,math.clamp(aim.Y-origin.Y,-4,2),0)
		-- Skill build (Sealing Palm): a clean hit closes a chakra point at range.
		c:projectile(a,goal,pending.spec.Speed or 96,pending.spec.Range,pending.spec.Damage,"palm",nil,{origin=origin,radius=1.5,growth=2.5,riders=if pending.spec.Tenketsu then {tenketsu=true} else nil})
		c:cue(a,"EIGHT TRIGRAMS • VACUUM PALM",.6)
	end,
}
-- Eight Trigrams Sixty-Four Palms. The opening palm must land (and can be
-- guarded); once it does, the flurry locks the opponent in place, drains its
-- chakra point by point and ends by sealing its techniques. It is the climax of
-- the network: every chakra point already closed adds palms, quickens them and
-- lengthens the seal, and with all of them closed the guard has nothing left
-- to hold the opening palm with. The victim keeps one answer: a substitution.
local COUNTS={"2 PALMS","4 PALMS","8 PALMS","16 PALMS","32 PALMS","64 PALMS"}
function Techniques.palmsPlan(points,seal)
	points=math.clamp(points or 0,0,8)
	return {strikes=7+points,interval=math.max(.1,.15-.012*points),final=2.5+.25*points,seal=(seal or 3.5)+.4*points}
end
Techniques.SixtyFourPalms={
	check=function() return true end,
	execute=function(c,a,pending,now)
		local Brawler=require(script.Parent.Brawler)
		local victim=a.target
		local g=a.def.GentleFist
		pending.spec=table.clone(pending.spec)
		local points=if victim and (victim.tenketsuUntil or 0)>now then victim.tenketsu or 0 else 0
		c:pushImpact(a.root.Position,"trigram",false,{owner=a.id,fighter=a.fighterId,points=points})
		local reach=victim and victim.health>0 and c:targetValid(a,victim,pending.spec.Range,.4)
		if not reach or victim.invulnerableUntil>now or (victim.rotationUntil or 0)>now then
			pending.spec.Recovery=.85
			c:cue(a,"64 PALMS • MISSED",.7)
			return
		end
		if g and points>=g.MaxPoints and victim.guardHeld then
			-- Every point closed: the guard collapses under the opening palm.
			victim.guardHeld=false
			if victim.state=="Guarding" then c:setState(victim,"Neutral",0) end
			c:cue(victim,"GUARD BREAK • THE NETWORK IS CLOSED",.9)
			Brawler.event(c,a,"GuardCollapse")
		end
		c.damageTag="64 Palms"
		local opened=c:damage(a,victim,pending.spec.Damage,false,true)
		c.damageTag=nil
		if c.match.phase~="Duel" then return end
		if not opened or victim.impactStyle=="block" then
			pending.spec.Recovery=.7
			c:cue(a,"64 PALMS • GUARDED",.7)
			return
		end
		Brawler.gentleFist(c,a,victim,false,"body")
		-- Lock: Neji holds the technique, the victim is held in place.
		local plan=Techniques.palmsPlan(points,pending.spec.Seal)
		local strikes,interval=plan.strikes,plan.interval
		c:setState(a,"TechniqueActive",strikes*interval+.25)
		a.flurryUntil=now+strikes*interval+.2
		Brawler.react(c,victim,"HitStun",Vector3.zero,strikes*interval+.3,a)
		victim.flurriedBy=a
		c:cue(a,if points>0 then "EIGHT TRIGRAMS • 64 PALMS • "..points.." POINTS OPEN THE WAY" else "EIGHT TRIGRAMS • 64 PALMS",1)
		for k=1,strikes do
			c:schedule(now+k*interval,function()
				if a.health<=0 or a.state~="TechniqueActive" or victim.health<=0 or victim.reaction~="HitStun" or victim.flurriedBy~=a then return end
				local last=k==strikes
				c.damageTag="64 Palms"
				c:damage(a,victim,if last then pending.spec.Damage*plan.final else pending.spec.Damage,false,false)
				c.damageTag=nil
				if c.match.phase~="Duel" or victim.health<=0 then return end
				Brawler.gentleFist(c,a,victim,false,"body")
				c:pushImpact(victim.root.Position,"palm",last,{owner=a.id,direction=a.root.CFrame.LookVector})
				c:cue(a,COUNTS[math.min(#COUNTS,k)] or "64 PALMS",.4)
				if last then
					victim.flurriedBy=nil
					victim.sealedUntil=c.now+plan.seal
					Brawler.sealPoints(c,a,victim)
					local away=victim.root.Position-a.root.Position;away=Vector3.new(away.X,0,away.Z)
					away=if away.Magnitude>.1 then away.Unit else a.root.CFrame.LookVector
					Brawler.react(c,victim,"Knockback",away*46+Vector3.new(0,16,0),.6,a)
					c:cue(victim,"CHAKRA POINTS SEALED",1.2)
				else
					victim.reactionUntil=math.max(victim.reactionUntil,c.now+interval+.15)
				end
			end)
		end
	end,
}
-- Rotation that repelled a strike flows straight into its answer: the dome
-- winds down at once (no full recovery), and a strike pressed during the spin
-- is the twin palm gliding out of it.
function Techniques.rotationCounter(c,a)
	local now=c.now
	local queued=a.counterQueued~=nil and now-a.counterQueued<=.9
	local stop=if queued then now else now+.08
	a.rotationUntil=math.min(a.rotationUntil or 0,stop)
	-- A strike pressed while the dome winds down cancels straight into the counter.
	a.rotationCounterUntil=a.counterUntil
	if a.rotationGuardUntil and math.abs((a.invulnerableUntil or 0)-a.rotationGuardUntil)<1e-6 then a.invulnerableUntil=stop end
	local p=a.pending
	if p and p.kind=="Technique" and p.spec.Id=="Rotation" and a.state=="TechniqueActive" then
		p.spec=table.clone(p.spec);p.spec.Recovery=.04
		a.untilTime=math.min(a.untilTime,stop)
	end
	if queued then
		c:schedule(now,function()
			if a.health<=0 or (a.counterUntil or 0)<=c.now or a.reaction then return end
			if a.state=="TechniqueActive" or a.state=="TechniqueRecovery" then a.pending=nil;a.rotationUntil=0;c:setState(a,"Neutral",0) end
			require(script.Parent.Brawler).counterStart(c,a)
		end)
	end
end
Techniques.PhoenixFlower={check=function() return true end,execute=Elements.phoenix}
-- Minato's Wind Cut: a crescent of wind thrown off the kunai's edge on the run
-- (the legs never stop). It cuts enemy blades out of its lane, and a body it
-- cuts is thrown a step sideways with a short wind seal on it: the very next
-- Flying Thunder God lands beside that body, on the side the stick picks.
-- A guard stops the gust and keeps no seal.
local BLADES={kunai=true,shuriken=true,marked=true,wire=true}
local WIND={Seal=1.6,Cut=22,Lane=1.4,Radius=1.6}
Techniques.WIND=WIND
local function cutLane(c,a,gust)
	c:schedule(c.now+.015,function()
		if not table.find(c.projectiles,gust) or c.match.phase~="Duel" then return end
		local radius=gust.radius+(gust.growth or 0)*(c.now-gust.born)+WIND.Lane
		for i=#c.projectiles,1,-1 do
			local q=c.projectiles[i]
			if q~=gust and q.a~=a and BLADES[q.kind] and (q.position-gust.position).Magnitude<=radius then
				table.remove(c.projectiles,i)
				c:pushImpact(q.position,"deflect",false,{projectile=q.id,kind=q.kind,owner=q.a.id,direction=-q.direction})
				require(script.Parent.Brawler).event(c,a,"WindCutBlade")
			end
		end
		cutLane(c,a,gust)
	end)
end
function Techniques.windSeal(c,a,b,direction,stick)
	local Brawler=require(script.Parent.Brawler)
	local across=Vector3.new(-direction.Z,0,direction.X)
	across=if across.Magnitude>.05 then across.Unit else a.root.CFrame.RightVector
	if stick and stick.Magnitude>.4 and stick:Dot(across)<0 then across=-across end
	Brawler.react(c,b,if b.airborne then "Juggled" else "HitStun",across*WIND.Cut+(if b.airborne then Vector3.new(0,10,0) else Vector3.zero),.45,a)
	-- A longer seal already on that body (a marked kunai) is kept, not shortened.
	local kept=false
	for _,entry in a.anchors or {} do if entry.actor==b and entry.expires>c.now+WIND.Seal then kept=true end end
	if not kept then
		local entry=Techniques.plant(c,a,b.root.Position,Vector3.yAxis,b)
		entry.expires=c.now+WIND.Seal;entry.wind=true
	end
	c:pushImpact(b.root.Position,"windseal",false,{owner=a.id,fighter=a.fighterId,victim=b.id,direction=across})
	c:cue(a,"WIND CUT • SEALED • FLASH BESIDE IT",.9)
	Brawler.event(c,a,"WindSeal")
end
Techniques.WindCut={
	check=function() return true end,
	execute=function(c,a,pending)
		local spec=pending.spec
		local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*spec.Range
		local origin=c.launchPoint(a,"Wind")
		local flat=Vector3.new(aim.X-origin.X,0,aim.Z-origin.Z)
		if flat.Magnitude<1 then flat=a.root.CFrame.LookVector*Vector3.new(1,0,1) end
		local goal=origin+flat.Unit*spec.Range+Vector3.new(0,math.clamp(aim.Y-origin.Y,-3,2),0)
		local stick=Vector3.new(a.move.X,0,a.move.Z)
		local gust
		-- Skill build (Gale Chase): a gust that connects also opens the chase.
		gust=c:projectile(a,goal,spec.Speed or 104,spec.Range,spec.Damage,"wind",function(_,_,victim)
			if not victim or victim.health<=0 or a.health<=0 or c.match.phase~="Duel" then return end
			Techniques.windSeal(c,a,victim,gust.direction,stick)
		end,{origin=origin,radius=WIND.Radius,riders=if spec.Chase then {chase=spec.Chase} else nil})
		cutLane(c,a,gust)
		c:cue(a,"WIND CUT",.5)
	end,
}
-- Awakening rules that live on a landed strike (Brawler.hit). Before the
-- reaction: Minato's skill-build Flow chain; the Curse Mark feeding on the
-- fight. After it (awakenedReact): the Curse Mark's extensions.
function Techniques.awakenedHit(c,a,b,p)
	local tune=a.def.Awakening
	if not tune or (a.awakenUntil or 0)<=c.now or b.health<=0 then return end
	-- Skill build (Flow, Minato's awakening): a clean hit right after a teleport
	-- arrival seals the body again, so the relocation chain continues.
	local chain=tune.FlashChain
	if chain and a.teleportAt and c.now-a.teleportAt<.7 then
		local entry=Techniques.plant(c,a,b.root.Position,Vector3.yAxis,b)
		entry.expires=c.now+chain
		c:cue(a,"FLOW • SEALED AGAIN",.7);require(script.Parent.Brawler).event(c,a,"FlowSeal")
	end
	-- Curse Mark: a landed blow quiets the seal for a moment (it feeds on the fight).
	if tune.HealthDrain then a.curseFedUntil=c.now+(tune.Feed or 0);a.curseLanded=c.now end
end
function Techniques.awakenedReact(c,a,b,p)
	local tune=a.def.Awakening
	if not tune or (a.awakenUntil or 0)<=c.now or b.health<=0 then return end
	local Brawler=require(script.Parent.Brawler)
	if tune.Extension and (p.name=="Light3" or p.name=="AirDrive") and b.reaction=="Knockback" and (a.curseHoldReadyAt or 0)<=c.now then
		-- The cursed kick does not let go: a short stagger instead of the
		-- knock-away, and the string stays open for the next route (heavy =
		-- the launcher, which the curse turns into the Dancing Leaf). Once per
		-- exchange: the next ender within 2.5 s knocks away as usual.
		a.curseHoldReadyAt=c.now+2.5
		local v=b.reactionVelocity or Vector3.zero
		local flat=Vector3.new(v.X,0,v.Z)
		flat=if flat.Magnitude>.1 then flat.Unit else a.root.CFrame.LookVector*Vector3.new(1,0,1)
		-- (The knockback just marked the body airborne: judge by its height.)
		if b.root.Position.Y>c.match.origin.Y+4.2 then Brawler.react(c,b,"Juggled",flat*12+Vector3.new(0,14,0),.55,a)
		else b.airborne=false;Brawler.react(c,b,"HitStun",flat*14,.5,a) end
		p.spec.chain=true
		-- A string ender closes its string when it starts (combo model): the
		-- held kick keeps the three confirmed hits, so heavy is the launcher.
		a.combo=math.max(a.combo or 0,3);a.stringAt=c.now
		c:pushImpact(b.root.Position,"curse",false,{owner=a.id,fighter=a.fighterId,victim=b.id})
		c:cue(a,"CURSE MARK • IT DOES NOT LET GO",.6)
		Brawler.event(c,a,"CurseExtension")
	end
	if tune.CursedLeaf and b.reaction=="Launched" and p.name~="LionKick" then Techniques.cursedLeaf(c,a,b) end
end
-- Curse Mark: every launcher becomes the Dancing Leaf (a free chase glued
-- under the body; heavy up there is the Lion Combo).
function Techniques.cursedLeaf(c,a,b)
	local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)
	local Brawler=require(script.Parent.Brawler)
	a.lionUntil=c.now+2.1
	c:schedule(c.now+.12,function()
		if a.health<=0 or b.health<=0 or c.match.phase~="Duel" or not (b.reaction=="Launched" or b.reaction=="Juggled") then return end
		a.chakra+=Config.PursuitCost
		local from=a.root.Position
		if c:request(a,"Pursuit") then
			a.untilTime=c.now+.5;a.shadowUntil=a.untilTime;a.airHold=c.now+1.1
			c:pushImpact(from,"afterimage",false,{owner=a.id,fighter=a.fighterId})
			c:cue(a,"CURSED LEAF • HEAVY = LION COMBO",1)
			Brawler.event(c,a,"CursedLeaf")
		else a.chakra-=Config.PursuitCost end
	end)
end
-- Curse Mark drain: it burns faster while he is not landing blows (hunger),
-- pauses for a moment after each one, and never kills.
function Techniques.curseDrain(c,a,dt,now)
	local tune=a.def.Awakening
	if not (tune and tune.HealthDrain) or (a.awakenUntil or 0)<=now or a.health<=1 then a.curseHunger=false;return end
	local rate=tune.HealthDrain
	if (a.curseFedUntil or 0)>now then rate=0
	elseif tune.Hunger and now-(a.curseLanded or a.awakenedAt or now)>1.5 then rate*=tune.Hunger end
	a.curseHunger=rate>tune.HealthDrain
	if rate>0 then a.health=math.max(1,a.health-rate*dt);a.hum.Health=math.max(1,a.health) end
end
-- Naruto (roster wave): his jutsu and his clones' behaviour (Server/Legion).
require(script.Parent.Legion).install(Techniques)
return Techniques
