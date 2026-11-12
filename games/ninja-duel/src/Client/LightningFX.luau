-- (12/11) The lightning of the Chidori (Sasuke) and the Raikiri / Lightning
-- Blade (Kakashi), drawn with real bolts (LightningBoltFX, adapted from
-- SamyBlue/Lightning-Beams, MIT) on top of the hand's sparks and glow
-- (Effects, the Chidori aura):
--   * held: the "birds" - three to five arcs thrown out of the palm to points
--     round the hand, each living a few hundredths of a second and replaced,
--     so the hand never shows the same shape twice; one longer arc licks the
--     floor now and then;
--   * at a run: an arc from the hand to the floor behind it, dragged along;
--   * the blow (impact "chidori"): the lightning goes THROUGH the body, in the
--     direction of the thrust (VFX bible: the impact crosses the target), four
--     bolts out of the back, run from the contact outward (pulse);
--   * Kakashi's Lightning Cut relocation is DashTrailFX's (it uses the same
--     bolts for its line).
-- Bible: a white-hot core stroke, the colour in the glow (blue-white; the
-- Raikiri whiter), few layers, never plain Neon. Presentation only.
local LightningFX={}
local Bolt=require(script.Parent.LightningBoltFX)
local K
LightningFX.clock=os.clock
LightningFX.LOOKS={
	Chidori={core=Color3.fromRGB(236,244,255),glow=Color3.fromRGB(96,150,255),birds=4,reach=2.6},
	Raikiri={core=Color3.fromRGB(250,252,255),glow=Color3.fromRGB(150,200,255),birds=5,reach=3.0},
}
-- Same reading as Effects' Chidori aura (the hand that holds it).
function LightningFX.holding(actor)
	if not actor or (actor.health or 1)<=0 then return nil end
	local st=actor.state
	local body=actor.bodyState and actor.bodyState.id
	if body=="LightningBlade" then return "Raikiri" end
	if body=="Chidori" then return if actor.fighterId=="Copycat" then "Raikiri" else "Chidori" end
	if actor.castId=="Chidori" and (st=="TechniqueChannel" or st=="TechniqueActive") then return if actor.fighterId=="Copycat" then "Raikiri" else "Chidori" end
	if actor.castId=="LightningBlade" and (st=="TechniqueChannel" or st=="TechniqueActive") then return "Raikiri" end
	if actor.attackName=="ChidoriThrust" and (st=="Startup" or st=="Active") then return "Chidori" end
	if (actor.attackVariant=="Chidori" or actor.attackVariant=="ChidoriDive") and (st=="Startup" or st=="Active") then return "Chidori" end
	return nil
end
local function arc(from,to,look,width,life,radius)
	local b=Bolt.new(Bolt.point(from,(to-from).Unit),Bolt.point(to,(to-from).Unit),math.clamp(math.floor((to-from).Magnitude*3),6,18))
	b.Color=look.core;b.GlowColor=look.glow
	b.Thickness=width;b.MinRadius=0;b.MaxRadius=radius or .35
	b.Frequency=2.2;b.AnimationSpeed=12
	b.PulseSpeed=1/life;b.PulseLength=.9;b.FadeLength=.25
	b.MinThicknessMultiplier,b.MaxThicknessMultiplier=.35,1
	return b
end
LightningFX.arc=arc
local held=setmetatable({},{__mode="k"}) -- model -> {next, floorAt}
local function random(rng) return Vector3.new(rng:NextNumber()-.5,rng:NextNumber()-.5,rng:NextNumber()-.5).Unit end
local rng=Random.new()
local function fighter(fx,model,actor,dt)
	local kind=LightningFX.holding(actor)
	if not model then return end
	if not kind then held[model]=nil return end
	local hand=model:FindFirstChild("RightHand")
	if not hand then return end
	Bolt.folder=fx.folder
	local look=LightningFX.LOOKS[kind]
	local st=held[model]
	if not st then st={next=0,floorAt=0};held[model]=st end
	local now=LightningFX.clock()
	local palm=hand.Position-hand.CFrame.UpVector*.35
	if now>=st.next then
		st.next=now+.06+rng:NextNumber()*.04
		local n=math.max(1,look.birds-2+rng:NextInteger(0,2))
		for _=1,n do
			local dir=random(rng)
			arc(palm,palm+dir*look.reach*(.5+rng:NextNumber()*.6),look,.09+rng:NextNumber()*.05,.08+rng:NextNumber()*.06,.4)
		end
	end
	local root=model:FindFirstChild("HumanoidRootPart")
	local v=root and root.AssemblyLinearVelocity or Vector3.zero
	local speed=Vector3.new(v.X,0,v.Z).Magnitude
	if now>=st.floorAt and (speed>10 or rng:NextNumber()<.25) then
		st.floorAt=now+(if speed>10 then .07 else .35)
		local floor=K.floorUnder and K.floorUnder(fx,palm,1,7)
		if floor then
			local back=if speed>1 then -Vector3.new(v.X,0,v.Z).Unit*1.4 else random(rng)*Vector3.new(1,0,1)
			arc(palm,floor.Position+back,look,.12,.12,.55)
		end
	end
end
local function impact(fx,data,folder)
	if data.style~="chidori" then return false end
	pcall(function()
		Bolt.folder=fx.folder
		local at=data.position
		local dir=data.direction
		if not dir or dir.Magnitude<.1 then
			local owner=folder and folder:FindFirstChild(data.owner or "")
			local root=owner and owner:FindFirstChild("HumanoidRootPart")
			dir=if root then root.CFrame.LookVector else Vector3.new(0,0,-1)
		end
		dir=dir.Unit
		local owner=folder and folder:FindFirstChild(data.owner or "")
		local fid=data.fighter or (owner and owner:GetAttribute("FighterId"))
		local look=LightningFX.LOOKS[if fid=="Copycat" then "Raikiri" else "Chidori"]
		for i=1,4 do
			local spread=(random(rng)*.45+dir).Unit
			arc(at-dir*.4,at+spread*(4+i),look,.22-i*.03,.16+i*.03,.6)
		end
	end)
	return false -- Effects' flash and sparks still mark the contact
end
function LightningFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Lightning",impact=impact,fighter=function(fx,model,actor,dt)
		local ok=pcall(fighter,fx,model,actor,dt)
		if not ok and model then held[model]=nil end
	end})
end
return LightningFX
