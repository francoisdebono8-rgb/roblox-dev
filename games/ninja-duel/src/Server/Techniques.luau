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
Techniques.RANGE=60
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
		entry={actor=victim,position=victim.root.Position,expires=c.now+BODY_SEAL,id=a.sealSerial,
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
		entry={position=at,surface=surface,normal=normal,expires=c.now+12,id=a.sealSerial,
			part=c:effect("Anchor",surface+normal*0.2,a.color,Vector3.new(1.3,0.2,1.3),12)}
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
		-- The arrival opens a short window in which a strike (or Rasengan, with
		-- almost no wind-up) cancels the technique recovery.
		a.flashUntil=now+.55;a.teleportAt=now
		a.teleportSerial=(a.teleportSerial or 0)+1
		c:pushImpact(target,"teleport",false,{owner=a.id,fighter=a.fighterId,from=departure,to=target,projectile=seal.flying and seal.flying.id})
		local left=#seals(c,a,now)
		c:cue(a,if left>0 then "FLYING THUNDER GOD • "..left.." SEAL"..(if left>1 then "S" else "").." LEFT" else "FLYING THUNDER GOD",.7)
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
			spec.damage=pending.spec.Damage*.9;spec.reaction="Knockdown";spec.impulse=Vector3.new(0,-70,16);spec.stun=.92
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
				c:projectile(a,victim.root.Position+lead+a.root.CFrame.RightVector*(if k==1 then -.6 else .6),86,pending.spec.Range,pending.spec.Damage+1,"shuriken")
			end)
		end
		c:cue(a,"SHADOW SHURIKEN",.6)
	end,
}
Techniques.MirageCast = {
	check = function(c,a,spec)
		return c:targetValid(a,a.target,spec.Range,0.35)
	end,
	execute = function(c,a,pending,now)
		if not c:targetValid(a,a.target,pending.spec.Range,0.35) then c:cue(a,"CAST LOST SIGHT"); return end
		local victim = a.target
		victim.illusionUntil = now+3
		victim.decoyPosition = c:clamp(a.root.Position + a.root.CFrame.RightVector*7)
		c:effect("Echo",victim.decoyPosition,a.color,Vector3.new(2,5,1),3)
		c:pushImpact(a.root.Position,"mirage",false,{owner=a.id,fighter=a.fighterId,to=victim.decoyPosition})
		c:cue(victim,"MIRAGE • TRUST THE BODY",3)
		c:cue(a,"ECHO ACTIVE",3)
	end,
}
Techniques.Quickstep={
	check=function() return true end,
	execute=function(c,a)
		local direction=if a.move.Magnitude>0.2 then a.move else a.root.CFrame.RightVector
		local departure=a.root.Position
		local moved=require(script.Parent.Motor).travel(a,c,direction,11)
		c:effect("Quickstep",a.root.Position,a.color,Vector3.new(2,3,2),0.22)
		c:pushImpact(departure,"quickstep",false,{owner=a.id,fighter=a.fighterId,to=a.root.Position})
		c:cue(a,if moved>3 then "ANGLE CREATED" else "ANGLE BLOCKED")
	end,
}
Techniques.FireBloom={check=function() return true end,execute=Elements.fire}
Techniques.PhoenixFlower={check=function() return true end,execute=Elements.phoenix}
Techniques.WindCut={check=function() return true end,execute=Elements.wind}
return Techniques
