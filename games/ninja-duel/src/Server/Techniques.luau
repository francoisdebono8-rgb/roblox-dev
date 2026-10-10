-- Each entry supplies prerequisites and payoff. The combat pipeline owns cost,
-- channel, interruption, active window and recovery for every entry.
local Techniques = {}
local Elements=require(script.Parent.Elements)
-- Where Minato's seal currently is: a planted kunai, or the marked kunai that is
-- still flying. Relocating onto a kunai in flight is the signature move.
local function sealOf(c,a,now)
	local flying=c:markedInFlight(a)
	if flying then return flying.position,flying end
	if a.anchor and a.anchor.expires>now then return a.anchor.position,nil end
	return nil,nil
end
Techniques.sealOf=sealOf
Techniques.MarkedBlade = {
	check = function() return true end,
	execute = function(c, a, pending, now)
		local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*30
		c:projectile(a, aim, 82, pending.spec.Range, pending.spec.Damage, "marked", function(position, normal)
			if a.health <= 0 or c.match.phase ~= "Duel" then return end
			if a.anchor then a.anchor.part:Destroy() end
			local offset=if normal.Y>0.5 then Vector3.new(0,3,0) else normal*3+Vector3.new(0,1,0)
			local at = c:clamp(position + offset)
			local p = c:effect("Anchor", position + normal*0.2, a.color, Vector3.new(1.3,0.2,1.3), 12)
			a.anchor = { position = at, surface = position, normal = normal, expires = c.now + 12, part = p }
			c:cue(a,"SEAL PLANTED")
		end)
	end,
}
Techniques.Flashstep = {
	check = function(c, a, _spec, now)
		local seal=sealOf(c,a,now)
		return seal~=nil and (seal-a.root.Position).Magnitude <= 60
	end,
	execute = function(c,a,_pending,now)
		local seal,flying=sealOf(c,a,now)
		if not seal then c:cue(a,"SEAL LOST"); return end
		local target=c:clamp(seal)
		-- A seal sitting on (or right next to) the opponent puts Minato behind
		-- them, on the far side from where he left: the angle change is the attack.
		local victim=a.target
		if victim and victim.health>0 then
			local toward=victim.root.Position-seal
			local flatGap=Vector3.new(toward.X,0,toward.Z).Magnitude
			if flatGap<7 then
				local away=Vector3.new(victim.root.Position.X-a.root.Position.X,0,victim.root.Position.Z-a.root.Position.Z)
				if away.Magnitude<.1 then away=victim.root.CFrame.LookVector*-1 end
				target=c:clamp(Vector3.new(victim.root.Position.X,math.max(victim.root.Position.Y,c.match.origin.Y+3),victim.root.Position.Z)+away.Unit*3.4)
			end
		end
		if target.Y<c.match.origin.Y+3 then target=Vector3.new(target.X,c.match.origin.Y+3,target.Z) end
		-- Never relocate into solid geometry, and never accept a client destination.
		local overlaps = workspace:GetPartBoundsInBox(CFrame.new(target),Vector3.new(2.6,4.6,2.6),c:overlapParams())
		for _, p in overlaps do
			if p.CanCollide and not p:IsDescendantOf(a.model) then
				if seal~=target then target=c:clamp(seal);break end
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
		if flying then flying.dead=true;c:removeProjectile(flying)
		elseif a.anchor then a.anchor.part:Destroy(); a.anchor = nil end
		-- The arrival opens a short window in which any strike cancels the
		-- technique recovery: teleport -> immediate attack from the new angle.
		a.flashUntil=now+.55
		a.teleportSerial=(a.teleportSerial or 0)+1
		c:pushImpact(target,"teleport",false,{owner=a.id,fighter=a.fighterId,from=departure,to=target,projectile=flying and flying.id})
		c:cue(a,"FLYING THUNDER GOD",.6)
	end,
}
Techniques.BurstStrike = {
	check = function() return true end,
	execute = function(c,a,pending)
		-- Channel commits chakra; release becomes a travelling physical attack.
		require(script.Parent.Brawler).start(c,a,"DashAttack")
		a.pending.spec=table.clone(a.pending.spec)
		a.pending.spec.damage=pending.spec.Damage;a.pending.spec.travel=10;a.pending.spec.recovery=.48
		-- Rasengan drives the body away spinning instead of a jab's stagger.
		a.pending.spec.reaction="Knockback";a.pending.spec.impulse=Vector3.new(0,22,66);a.pending.spec.stun=.62
		a.pending.rasengan=true;a.attackVariant="Rasengan"
		a.travelRemaining=10
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
Techniques.WindCut={check=function() return true end,execute=Elements.wind}
return Techniques
