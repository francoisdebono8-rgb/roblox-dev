-- Element families define different gameplay primitives. Fire and Wind are
-- equipped in this slice; the other families reserve explicit behavior seams.
local Elements={
	Families={
		Fire={primitive="AreaPressure",counter="Leave the telegraphed fan"},
		Lightning={primitive="PrecisionBurst",counter="Bait the committed line"},
		Wind={primitive="Displacement",counter="Sidestep the cutting lane"},
		Water={primitive="MovingControlVolume",counter="Cross behind the wave"},
		Earth={primitive="SolidGroundCover",counter="Reposition around cover"},
	},
}
function Elements.fire(c,a,pending,now)
	local spec=pending.spec
	local center=a.root.Position+a.root.CFrame.LookVector*8
	local visual=c:effect("Fire Bloom",center,Color3.fromRGB(255,111,48),Vector3.new(9,1,9),0.82)
	visual.Shape=Enum.PartType.Cylinder;visual.Size=Vector3.new(.08,11.6,11.6)
 visual.CFrame=CFrame.new(center-Vector3.new(0,2.7,0))*CFrame.Angles(0,0,math.pi/2);visual.Transparency=.68
 for i=-2,2 do
  local p=c:effect("Flame",center+a.root.CFrame.RightVector*i*1.65+Vector3.new(0,-.5,0),Color3.fromRGB(255,155+i*12,55),Vector3.new(1.7,3+math.abs(i)*.4,1.7),.36)
  p.Shape=Enum.PartType.Ball;p.Transparency=.25
 end
	c:cue(a,"FIRE • FAN ACTIVE")
	local hazard=c:addHazard(a,center,5.8,0.82,spec.Damage,"Fire")
	-- Immediate pressure is still subject to real range, facing and sight.
	if c:targetValid(a,a.target,spec.Range,0.32) then
		local delta=a.target.root.Position-center
		if Vector3.new(delta.X,0,delta.Z).Magnitude<=6.5 then
			if c:damage(a,a.target,spec.Damage,false,false) then hazard.lastHit[a.target]=now end
		end
	end
end
function Elements.wind(c,a,pending)
	local aim=pending.aim
	if (aim-a.root.Position).Magnitude<1 then aim=a.root.Position+a.root.CFrame.LookVector*pending.spec.Range end
	c:projectile(a,aim,88,pending.spec.Range,pending.spec.Damage,"wind")
	c:cue(a,"WIND • CUTTING LANE")
end
return Elements
