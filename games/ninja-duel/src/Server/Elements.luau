-- Element families define different gameplay primitives. Fire and Wind are
-- equipped in this slice; the other families reserve explicit behavior seams.
local Chakra=require(script.Parent.ChakraCombat)
local Elements={
	Families={
		Fire={primitive="TravellingBlast",counter="Sidestep the fireball, then punish the recovery"},
		Lightning={primitive="PrecisionBurst",counter="Bait the committed line"},
		Wind={primitive="Displacement",counter="Sidestep the cutting lane"},
		Water={primitive="MovingControlVolume",counter="Cross behind the wave"},
		Earth={primitive="SolidGroundCover",counter="Reposition around cover"},
	},
}
-- Katon: Great Fireball. Released from the mouth after the hand signs, it is a
-- real travelling volume that grows as it flies, bursts on contact and leaves
-- burning ground behind.
function Elements.fire(c,a,pending,now)
	local spec=pending.spec
	local aim=pending.aim or (a.target and a.target.root.Position) or a.root.Position+a.root.CFrame.LookVector*spec.Range
	local origin=c.launchPoint(a,"Fireball")
	-- Fire travels flat and slightly down onto the opponent's body, never into
	-- the sky when the aim point is a little high.
	local delta=aim-origin
	local flat=Vector3.new(delta.X,0,delta.Z)
	if flat.Magnitude<1 then flat=a.root.CFrame.LookVector*Vector3.new(1,0,1) end
	local drop=math.clamp(delta.Y,-flat.Magnitude*.35,flat.Magnitude*.08)
	local target=origin+flat.Unit*spec.Range+Vector3.new(0,drop*spec.Range/math.max(flat.Magnitude,1),0)
	local ball=c:projectile(a,target,spec.Speed or 54,spec.Range,spec.Damage,"fireball",nil,{origin=origin,radius=2.4,growth=2.2,heavy=true})
	if spec.Lane then Elements.burnLane(c,a,ball) end
	c:cue(a,"KATON • GREAT FIREBALL")
end
-- Itachi's Katon is control, not only damage (spec.Lane): where the fireball
-- passes the opponent, the ground under its path catches, patch after patch at
-- an even spacing. The lane cuts the field beside the body that dodged it:
-- walk round it, jump it, or take the burn (Combat:chip, it never stuns).
local LANE={Reach=14,Spacing=5,Radius=2.4,Life=2.6,Damage=.3,Drop=24}
Elements.LANE=LANE
function Elements.burnLane(c,a,ball)
	c:schedule(c.now+.03,function()
		if c.match.phase~="Duel" or ball.dead or not table.find(c.projectiles,ball) then return end
		local b=a.target
		if b and b.health>0 then
			local near=Vector3.new(ball.position.X-b.root.Position.X,0,ball.position.Z-b.root.Position.Z).Magnitude<=LANE.Reach
			if near and not ball.laneNext then ball.laneNext=ball.position end
			-- Every patch point the flight has passed since the last poll.
			while near and ball.laneNext and (ball.position-ball.laneNext):Dot(ball.direction)>=0 do
				local floor=workspace:Raycast(ball.laneNext,Vector3.new(0,-LANE.Drop,0),c:rayParams(true))
				if floor then
					local patch=c:addHazard(a,floor.Position+Vector3.new(0,.5,0),LANE.Radius,LANE.Life,ball.damage*LANE.Damage,"Fire")
					patch.lane=ball.id
				end
				ball.laneNext+=ball.direction*LANE.Spacing
			end
			-- Past the opponent: the lane is laid.
			if not near and ball.laneNext then return end
		end
		Elements.burnLane(c,a,ball)
	end)
end
-- Katon: Phoenix Flower. Five small flames released one after another, each
-- re-aimed at the opponent with a lateral offset: a fan that follows the
-- target and pressures a sidestep, with small burning patches where they land.
function Elements.phoenix(c,a,pending,now)
	local spec=pending.spec
	local offsets={0,-5,5,-2.5,2.5}
	for k,offset in offsets do
		c:schedule(now+(k-1)*.06,function()
			if a.health<=0 or a.reaction or a.state=="Stunned" then return end
			local victim=a.target
			local goal=if victim and victim.health>0 then victim.root.Position+victim.root.AssemblyLinearVelocity*Vector3.new(1,0,1)*.15 else a.root.Position+a.root.CFrame.LookVector*spec.Range
			local origin=c.launchPoint(a,"Fireball")
			local flat=Vector3.new(goal.X-origin.X,0,goal.Z-origin.Z)
			if flat.Magnitude<1 then flat=a.root.CFrame.LookVector*Vector3.new(1,0,1) end
			local side=Vector3.new(-flat.Unit.Z,0,flat.Unit.X)
			local aim=goal+side*offset+Vector3.new(0,-.6,0)
			c:projectile(a,aim,spec.Speed or 68,spec.Range,spec.Damage,"phoenix",nil,{origin=origin,radius=.9,growth=.35})
		end)
	end
	-- Sasuke hides two shuriken inside the flames.
	if spec.HiddenBlades then
		for k=1,2 do
			c:schedule(now+.14+k*.07,function()
				if a.health<=0 or a.reaction or a.state=="Stunned" or not a.target or a.target.health<=0 then return end
				local side=a.root.CFrame.RightVector*(if k==1 then -1.5 else 1.5)
				-- Skill build (Wired Flames): the hidden blades trail wire and bind.
				if spec.WiredBlades then
					c:projectile(a,a.target.root.Position+side,90,spec.Range,2,"wire",nil,{riders={bind=spec.WiredBlades}})
				else
					-- Blades hidden in the flames come out burning: they ignite what they
					-- touch and leave a burning point where they land (ChakraCombat).
					c:projectile(a,a.target.root.Position+side,90,spec.Range,2,"shuriken",nil,{chakra=Chakra.innate(c,a,"Shuriken","Fire")})
				end
			end)
		end
	end
	c:cue(a,"KATON • PHOENIX FLOWER")
end
function Elements.wind(c,a,pending)
	local aim=pending.aim
	if (aim-a.root.Position).Magnitude<1 then aim=a.root.Position+a.root.CFrame.LookVector*pending.spec.Range end
	-- Skill build (Gale Chase): a gust that connects opens the chase window.
	c:projectile(a,aim,88,pending.spec.Range,pending.spec.Damage,"wind",nil,{radius=1.4,riders=if pending.spec.Chase then {chase=pending.spec.Chase} else nil})
	c:cue(a,"WIND • CUTTING LANE")
end
return Elements
