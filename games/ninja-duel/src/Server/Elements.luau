-- Element families define different gameplay primitives. Fire and Wind are
-- equipped in this slice; the other families reserve explicit behavior seams.
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
	c:projectile(a,target,spec.Speed or 54,spec.Range,spec.Damage,"fireball",nil,{origin=origin,radius=2.4,growth=2.2,heavy=true})
	c:cue(a,"KATON • GREAT FIREBALL")
end
function Elements.wind(c,a,pending)
	local aim=pending.aim
	if (aim-a.root.Position).Magnitude<1 then aim=a.root.Position+a.root.CFrame.LookVector*pending.spec.Range end
	c:projectile(a,aim,88,pending.spec.Range,pending.spec.Damage,"wind",nil,{radius=1.4})
	c:cue(a,"WIND • CUTTING LANE")
end
return Elements
