-- (06/11, « les chiens ninja qui sortent du sol ») Kakashi's ninken on screen
-- (Server/Hounds). The dogs: a small rig built here (a body, a chest, a head
-- with its snout and ears, the Konoha headband, four legs on joints, a tail),
-- four of them, Pakkun the small tan one first; posed by Client/BodyViews
-- every frame: under the floor while they dig (only a dust trail runs along
-- the ground), out with a jump, running (legs and bob), biting (braced, the
-- head shaking at his legs). The contacts: diving in at Kakashi's feet, the
-- burst out of the floor, the bite, the puff when one is sent away. One
-- identity layer installed into Effects. Presentation only.
local HoundFX={}
local K -- Effects' helpers, handed over by install()
HoundFX.clock=os.clock -- (headless tests drive time)
local SMOKE=Color3.fromRGB(236,236,240)
local DUST=Color3.fromRGB(196,176,140)
local BAND=Color3.fromRGB(40,52,96)
local PLATE=Color3.fromRGB(190,196,206)
local DARK=Color3.fromRGB(26,22,24)
-- {coat, pale, scale}: Pakkun, then the pack.
HoundFX.COATS={
	-- (Studio 06/11: at knee height they vanished under his legs.)
	{Color3.fromRGB(204,168,118),Color3.fromRGB(236,214,180),.85},
	{Color3.fromRGB(104,104,116),Color3.fromRGB(196,196,204),1.35},
	{Color3.fromRGB(122,90,62),Color3.fromRGB(206,184,150),1.45},
	{Color3.fromRGB(58,56,62),Color3.fromRGB(214,210,206),1.6},
}
local function part(model,name,size,color,shape)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.Color=color;p.Material=Enum.Material.SmoothPlastic
	p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=true
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	if shape then p.Shape=shape end
	p.Parent=model
	return p
end
local function weld(root,p,offset)
	p.CFrame=root.CFrame*offset
	local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=p;w.Parent=p
end
-- One dog (index picks the coat). Its pivot is its root, at mid-body height
-- `model:GetAttribute("Lift")` above the floor.
function HoundFX.build(index)
	local coat=HoundFX.COATS[(index-1)%#HoundFX.COATS+1]
	local color,pale,s=coat[1],coat[2],coat[3]
	local m=Instance.new("Model");m.Name="Ninken"
	local root=part(m,"HoundRoot",Vector3.one*.2,color);root.Transparency=1;root.Anchored=true
	m.PrimaryPart=root
	local function v(x,y,z) return Vector3.new(x,y,z)*s end
	local function at(x,y,z) return CFrame.new(x*s,y*s,z*s) end
	weld(root,part(m,"Body",v(1,.85,1.6),color,Enum.PartType.Ball),at(0,0,.1))
	weld(root,part(m,"Belly",v(.78,.5,1.2),pale,Enum.PartType.Ball),at(0,-.18,.1))
	weld(root,part(m,"Chest",v(.92,.9,.85),color,Enum.PartType.Ball),at(0,.12,-.5))
	weld(root,part(m,"Head",v(.74,.68,.76),color,Enum.PartType.Ball),at(0,.5,-.95))
	weld(root,part(m,"Snout",v(.4,.32,.46),pale,Enum.PartType.Ball),at(0,.38,-1.32))
	weld(root,part(m,"Nose",v(.16,.13,.13),DARK,Enum.PartType.Ball),at(0,.46,-1.55))
	for _,side in {-1,1} do
		weld(root,part(m,"Eye",v(.1,.1,.08),DARK,Enum.PartType.Ball),at(side*.18,.62,-1.27))
		local ear=Instance.new("WedgePart");ear.Name="Ear";ear.Size=v(.12,.32,.2);ear.Color=color;ear.Material=Enum.Material.SmoothPlastic
		ear.CanCollide=false;ear.CanQuery=false;ear.CanTouch=false;ear.Massless=true;ear.Parent=m
		weld(root,ear,at(side*.22,.9,-.9))
	end
	-- The Konoha headband round the forehead (Studio 06/11: on top it read as a hat).
	-- (and at eye level it read as a blindfold: above the eyes, round the head)
	weld(root,part(m,"Headband",v(.7,.11,.68),BAND),at(0,.7,-.95))
	weld(root,part(m,"Plate",v(.3,.1,.05),PLATE),at(0,.7,-1.3))
	local tail=part(m,"Tail",v(.13,.13,.6),color)
	weld(root,tail,at(0,.35,.95)*CFrame.Angles(math.rad(35),0,0))
	-- Legs on joints (Motor6D) so the stride can swing them.
	local legs={}
	for _,side in {-1,1} do
		for _,z in {-.5,.55} do
			local leg=part(m,"Leg",v(.2,.7,.2),color)
			local j=Instance.new("Motor6D");j.Name="Hip";j.Part0=root;j.Part1=leg
			j.C0=at(side*.3,-.15,z);j.C1=CFrame.new(0,.33*s,0)
			j.Parent=root
			table.insert(legs,{joint=j,phase=(if z<0 then 0 else math.pi)+(if side<0 then 0 else math.pi)})
		end
	end
	-- The dust it raises under the floor (a separate anchor at floor level).
	local dust=part(m,"Dust",Vector3.one*.2,DUST);dust.Transparency=1;dust.Anchored=true
	local e=Instance.new("ParticleEmitter")
	e.Texture="rbxasset://textures/particles/smoke_main.dds";e.Rate=0;e.Lifetime=NumberRange.new(.45,.8)
	e.Speed=NumberRange.new(2,5);e.SpreadAngle=Vector2.new(40,40);e.EmissionDirection=Enum.NormalId.Top
	e.Color=ColorSequence.new(DUST);e.LightInfluence=1
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.6),NumberSequenceKeypoint.new(1,1.8)})
	e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1)})
	e.Parent=dust
	m:SetAttribute("Lift",.8*s)
	return m,{legs=legs,dust=dust,emitter=e,scale=s,rise=-2.4}
end
-- Every frame (BodyViews): the dog where the server has it, posed by state.
function HoundFX.pose(view,entry,dt)
	local rig=view.rig
	local now=HoundFX.clock()
	local s=rig.scale
	local floor=view.pos.Y-3
	local buried=entry.buried==true
	-- Under the floor, out with a jump, then on its legs.
	local want=if buried then -2.4*s else 0
	rig.rise=if want<rig.rise then want else rig.rise+(want-rig.rise)*math.min(1,dt*16)
	local speed=Vector3.new(entry.velocity and entry.velocity.X or 0,0,entry.velocity and entry.velocity.Z or 0).Magnitude
	local biting=entry.state=="Active"
	local bob=if biting then 0 else math.abs(math.sin(now*16))*.22*math.min(1,speed/8)
	local look=view.look or Vector3.new(0,0,-1)
	local at=Vector3.new(view.pos.X,floor+view.model:GetAttribute("Lift")+rig.rise+bob,view.pos.Z)
	local frame=CFrame.lookAt(at,at+look)
	if biting then
		-- Braced, the head down at his legs, a shake.
		frame*=CFrame.Angles(math.rad(-14),math.rad(math.sin(now*38)*7),0)
	elseif rig.rise<-.05 then
		frame*=CFrame.Angles(math.rad(30),0,0) -- the jump out
	end
	view.model:PivotTo(frame)
	for _,leg in rig.legs do
		local swing=if biting then math.rad(18)*(if leg.phase<1 then -1 else 1) else math.sin(now*16+leg.phase)*math.rad(40)*math.min(1,speed/8)
		leg.joint.Transform=CFrame.Angles(swing,0,0)
	end
	-- The dust trail along the floor while it digs.
	rig.dust.CFrame=CFrame.new(view.pos.X,floor+.15,view.pos.Z)
	rig.emitter.Rate=if buried and speed>2 then 70 else 0
end

-- ------------------------------------------------------------------ contacts
local function puff(fx,at,count,size,color) K.smokePuff(fx.folder,at,color or SMOKE,count,size) end
local function body(fx,impact)
	if impact.kind~="hound" then return false end
	local at=impact.position
	local floor=at-Vector3.new(0,2.6,0)
	if impact.phase=="appear" then
		-- Diving into the floor at his feet.
		puff(fx,floor,6,1.2,DUST)
	elseif impact.phase=="hit" or impact.phase=="blade" or impact.phase=="area" then
		puff(fx,floor+Vector3.new(0,.8,0),16,2)
		K.sound(K.anchorPart(fx.folder,at),K.SOUND.hit,.3,1.7)
	else
		-- The summoning ends: each in its puff of smoke.
		puff(fx,floor+Vector3.new(0,.8,0),10,1.6)
	end
	return true
end
local function burst(fx,impact)
	local floor=impact.position-Vector3.new(0,2.8,0)
	puff(fx,floor,10,1.6,DUST)
	K.burst(fx.folder,floor,{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.3,.6),Speed=NumberRange.new(8,14),SpreadAngle=Vector2.new(35,35),
		EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(DUST),LightInfluence=1,Size=K.num({{0,.5},{1,1.1}}),Acceleration=Vector3.new(0,-30,0)},8)
	if (impact.body or 0)%2==0 then K.sound(K.anchorPart(fx.folder,floor),K.SOUND.debris,.35,1.4,.4) end
	return true
end
local function bite(fx,impact)
	local at=impact.position-Vector3.new(0,1.6,0)
	K.flash(fx.folder,at,SMOKE,.3,2.2,.12,.4)
	K.sound(K.anchorPart(fx.folder,at),K.SOUND.punch,.45,1.25)
	return true
end
local function impact(fx,data)
	if data.style=="body" then return body(fx,data) end
	if data.style=="houndburst" then return burst(fx,data) end
	if data.style=="houndbite" then return bite(fx,data) end
	return false
end
function HoundFX.install(Effects,kit)
	K=kit
	-- Before Naruto's layer: his answers "body" contacts of his clones only.
	table.insert(Effects.layers,1,{name="Hounds",impact=impact})
end
return HoundFX
