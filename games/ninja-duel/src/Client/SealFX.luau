-- (13/11, issue #73: « les signes de Kakashi ne sont que des poings devant la
-- poitrine ») The hand seals read as seals: while Kakashi weaves one (a seal
-- jutsu's channel), chakra gathers between his hands - a soft glow and a
-- light that tint the hands and the face from below - and every time the
-- hands snap together on a seal it pulses (a small burst of light and a puff
-- of chakra), so a chain of five seals reads as five beats. The colour says
-- the nature: earth amber, water blue, lightning white-blue; plain chakra
-- blue otherwise. The poses themselves are the clips' (jutsu_v2_kakashi).
-- Presentation only; never stops the feed.
local SealFX={}
local K
SealFX.clock=os.clock
SealFX.JUTSU={
	EarthWall="earth",EarthHeadhunter="earth",EarthDragon="earth",
	WaterDragon="water",WhiteChakraSabre="lightning",LightningBlade="lightning",TrackingFang="chakra",
}
SealFX.COLORS={
	earth={core=Color3.fromRGB(255,214,150),glow=Color3.fromRGB(230,150,60)},
	water={core=Color3.fromRGB(214,240,255),glow=Color3.fromRGB(70,150,255)},
	lightning={core=Color3.fromRGB(240,248,255),glow=Color3.fromRGB(140,190,255)},
	chakra={core=Color3.fromRGB(220,236,255),glow=Color3.fromRGB(110,170,255)},
}
SealFX.MEET=1.1 -- studs between the hands: a seal is made
SealFX.FIGHTERS={Copycat=true}
-- Which nature is being woven, or nil.
function SealFX.weaving(actor)
	if not actor or not SealFX.FIGHTERS[actor.fighterId or ""] then return nil end
	if actor.state~="TechniqueChannel" or (actor.health or 1)<=0 then return nil end
	return SealFX.JUTSU[actor.castId or ""]
end
local states=setmetatable({},{__mode="k"})
local function stop(st)
	if st.emitter then st.emitter.Enabled=false end
	if st.light then K.tween(st.light,.15,{Brightness=0}) end
	if st.attachment then game:GetService("Debris"):AddItem(st.attachment,.4) end
end
local function fighter(fx,model,actor,dt)
	if not model then return end
	local nature=SealFX.weaving(actor)
	local st=states[model]
	if not nature then
		if st then stop(st);states[model]=nil end
		return
	end
	local lh,rh=model:FindFirstChild("LeftHand"),model:FindFirstChild("RightHand")
	if not lh or not rh then return end
	local look=SealFX.COLORS[nature]
	if not st or st.nature~=nature or not st.attachment or not st.attachment.Parent then
		if st then stop(st) end
		local at=K.new("Attachment",{Name="SealGlow"},rh)
		local emitter=K.new("ParticleEmitter",{Texture=K.TEX.glow,Rate=26,Lifetime=NumberRange.new(.12,.2),Speed=NumberRange.new(0,.5),
			Color=ColorSequence.new(look.core,look.glow),LightEmission=1,LightInfluence=0,LockedToPart=true,
			Size=K.num({{0,.9},{1,1.4}}),Transparency=K.num({{0,.35},{1,1}})},at)
		local light=K.new("PointLight",{Color=look.glow,Brightness=0,Range=7,Shadows=false},at)
		K.tween(light,.12,{Brightness=1.6})
		st={nature=nature,attachment=at,emitter=emitter,light=light,together=false}
		states[model]=st
	end
	-- the glow sits between the palms
	local mid=(lh.Position+rh.Position)/2
	pcall(function() st.attachment.WorldPosition=mid end)
	local together=(lh.Position-rh.Position).Magnitude<SealFX.MEET
	if together and not st.together then
		-- a seal is made: the beat
		K.flash(fx.folder,mid,look.core,.25,1.6,.12,.2)
		K.burst(fx.folder,mid,{Texture=K.TEX.glow,Lifetime=NumberRange.new(.12,.22),Speed=NumberRange.new(2,5),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(look.glow),LightEmission=1,Size=K.num({{0,.5},{1,0}}),Drag=6},8)
		st.light.Brightness=3.2
		K.tween(st.light,.18,{Brightness=1.6})
	end
	st.together=together
end
function SealFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Seal",fighter=function(fx,model,actor,dt)
		local ok=pcall(fighter,fx,model,actor,dt)
		if not ok and model then states[model]=nil end
	end})
end
return SealFX
