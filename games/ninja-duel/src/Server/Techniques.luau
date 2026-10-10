-- Each entry supplies prerequisites and payoff. The combat pipeline owns cost,
-- channel, interruption, active window and recovery for every entry.
local Techniques = {}
local Elements=require(script.Parent.Elements)
Techniques.MarkedBlade = {
	check = function() return true end,
	execute = function(c, a, pending, now)
		c:projectile(a, pending.aim, 62, pending.spec.Range, pending.spec.Damage, "blade", function(position, normal)
			if a.health <= 0 or c.match.phase ~= "Duel" then return end
			if a.anchor then a.anchor.part:Destroy() end
			local offset=if normal.Y>0.5 then Vector3.new(0,3,0) else normal*3+Vector3.new(0,1,0)
			local at = c:clamp(position + offset)
			local p = c:effect("Anchor", position + normal*0.2, a.color, Vector3.new(1.3,0.2,1.3), 12)
			a.anchor = { position = at, expires = c.now + 12, part = p }
			c:cue(a,"ANCHOR PLACED")
		end)
	end,
}
Techniques.Flashstep = {
	check = function(c, a, _spec, now)
		return a.anchor ~= nil and a.anchor.expires > now and (a.anchor.position-a.root.Position).Magnitude <= 40
	end,
	execute = function(c,a,_pending,now)
		local anchor = a.anchor
		if not anchor or anchor.expires <= now then c:cue(a,"ANCHOR EXPIRED"); return end
		local target = anchor.position
		-- Never relocate into solid geometry, and never accept a client destination.
		local overlaps = workspace:GetPartBoundsInBox(CFrame.new(target),Vector3.new(3,5,3),c:overlapParams())
		for _, p in overlaps do
			if p.CanCollide and not p:IsDescendantOf(a.model) then c:cue(a,"ARRIVAL BLOCKED"); return end
		end
		c:effect("Departure",a.root.Position,a.color,Vector3.new(2,5,2),0.3)
		c:relocate(a,target)
		c:effect("Arrival",target,a.color,Vector3.new(3,5,3),0.45)
		anchor.part:Destroy(); a.anchor = nil
		c:cue(a,"FLASHSTEP • RECOVERING")
	end,
}
Techniques.BurstStrike = {
	check = function() return true end,
	execute = function(c,a,pending)
		-- Channel commits chakra; release becomes a travelling physical attack.
		require(script.Parent.Brawler).start(c,a,"DashAttack")
		a.pending.spec=table.clone(a.pending.spec)
		a.pending.spec.damage=pending.spec.Damage;a.pending.spec.travel=10;a.pending.spec.recovery=.48
		a.travelRemaining=10

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
		for _, angle in { -0.13,0,0.13 } do
			local d = CFrame.fromAxisAngle(Vector3.yAxis,angle):VectorToWorldSpace(direction.Unit)
			c:projectile(a,a.root.Position+d*pending.spec.Range,54,pending.spec.Range,pending.spec.Damage,"needle")
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
		c:cue(victim,"MIRAGE • TRUST THE BODY",3)
		c:cue(a,"ECHO ACTIVE",3)
	end,
}
Techniques.Quickstep={
	check=function() return true end,
	execute=function(c,a)
		local direction=if a.move.Magnitude>0.2 then a.move else a.root.CFrame.RightVector
		local moved=require(script.Parent.Motor).travel(a,c,direction,11)
		c:effect("Quickstep",a.root.Position,a.color,Vector3.new(2,3,2),0.22)
		c:cue(a,if moved>3 then "ANGLE CREATED" else "ANGLE BLOCKED")
	end,
}
Techniques.FireBloom={check=function() return true end,execute=Elements.fire}
Techniques.WindCut={check=function() return true end,execute=Elements.wind}
return Techniques
