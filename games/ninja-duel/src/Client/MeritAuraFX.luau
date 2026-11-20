-- The merit auras (20/11, étape 1 ANIMATEUR 3; DEC-043 § 1: « des auras et des titres gagnés
-- au mérite, jamais achetés »). Three tiers a player earns by winning (the thresholds, the
-- saving and who sees what are the DEV's: Server progression, « le mérite »); this module only
-- draws them on a body, in Konoha and in the duel.
--
-- In the direction of the VFX bible (06/11): anime, a little colour, few layers, no plain Neon,
-- the game's own drawn textures (AwakenFX.ID). An aura must never be mistaken for an awakening
-- (a combat state: AwakenFX), so it stays at the feet and on the outline, thin, and it is
-- quieter in a duel (quiet = a third of the particles).
--
-- The tiers are Shared/Merit's (ids, names, points: the DEV's), drawn here:
--   1 EMBER    warm embers lick round the feet, a faint ring breathes on the floor
--   2 STORM    + blue-violet chakra climbs the body's outline (shoulders, arms)
--   3 LEGEND   + white-gold: the mantle turns gold, leaves rise round the body, a soft light
--
-- API (client):
--   MeritAuraFX.wear(model, tier [, quiet])  -> the instances it made (or nil: no body, tier 0)
--   MeritAuraFX.remove(model)
--   MeritAuraFX.setQuiet(model, quiet)       a duel starts / ends
--   MeritAuraFX.start()                      dresses every player from his NinjaAura attribute
--                                            (Server/Progression), now and at each respawn
--   MeritAuraFX.TIERS[t] = {id, color}       (ids = Shared/Merit.Tiers)
-- Presentation only: nothing here can change gameplay.
local AwakenFX=require(script.Parent.AwakenFX)
local emitter=AwakenFX.emitter

local MeritAuraFX={}
MeritAuraFX.QUIET=.35

MeritAuraFX.TIERS={
	{id="Ember",color=Color3.fromRGB(255,150,70)},
	{id="Storm",color=Color3.fromRGB(130,150,255)},
	{id="Legend",color=Color3.fromRGB(255,220,130)},
}

local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function range(a,b) return NumberRange.new(a,b or a) end
local function colors(a,b) return ColorSequence.new(a,b or a) end

local function part(model,name)
	local p=model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end
-- each emitter remembers its full rate (quiet mode scales it)
local function keep(e,list)
	e:SetAttribute("MeritRate",e.Rate)
	table.insert(list,e)
	return e
end

-- The feet: a short chakra flame licking up from each foot.
local function feet(model,color,list,scale)
	for _,name in {"RightFoot","LeftFoot"} do
		local p=part(model,name)
		if p then
			local a=Instance.new("Attachment");a.Name="MeritFoot";a.Position=Vector3.new(0,-p.Size.Y/2,0);a.Parent=p
			table.insert(list,a)
			keep(emitter(a,"flame",{Rate=10*scale,Lifetime=range(.35,.55),Speed=range(.6,1.4),SpreadAngle=Vector2.new(25,25),
				Acceleration=Vector3.new(0,4,0),Color=colors(color),LightEmission=.55,
				Size=seq({{0,.55*scale},{.5,.45*scale},{1,.1}}),Transparency=seq({{0,.45},{.5,.55},{1,1}}),ZOffset=.3}),list)
		end
	end
end

-- The floor: a faint ring that breathes under the body.
local function ring(model,color,list)
	local root=part(model,"HumanoidRootPart")
	if not root then return end
	local a=Instance.new("Attachment");a.Name="MeritRing";a.Position=Vector3.new(0,-2.95,0);a.Parent=root
	table.insert(list,a)
	keep(emitter(a,"ring",{Rate=1.2,Lifetime=range(1.4),Speed=range(.01),Orientation=Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection=Enum.NormalId.Top,Rotation=range(0,360),RotSpeed=range(-20,20),Color=colors(color),LightEmission=.5,
		Size=seq({{0,2.2},{1,3.4}}),Transparency=seq({{0,1},{.25,.72},{1,1}}),ZOffset=.1}),list)
end

-- The outline: chakra that climbs off the shoulders and arms (surface emitters, thin).
local OUTLINE={"UpperTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"}
local function outline(model,color,list,rate)
	for _,name in OUTLINE do
		local p=part(model,name)
		if p then
			local e=emitter(p,"flame",{Rate=rate*(if name=="UpperTorso" then 2 else 1),Lifetime=range(.3,.5),Speed=range(.4,1),
				Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,
				Acceleration=Vector3.new(0,5,0),Color=colors(color),LightEmission=.5,
				Size=seq({{0,.38},{.6,.3},{1,0}}),Transparency=seq({{0,.55},{.6,.65},{1,1}}),ZOffset=.2})
			keep(e,list)
		end
	end
end

-- The storm: leaves rising round the body, slowly turning.
local function leaves(model,list)
	local p=part(model,"LowerTorso")
	if not p then return end
	keep(emitter(p,"leaf",{Rate=5,Lifetime=range(1.6,2.4),Speed=range(.8,1.6),
		Shape=Enum.ParticleEmitterShape.Cylinder,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,
		Acceleration=Vector3.new(0,2.2,0),Drag=1.2,Rotation=range(0,360),RotSpeed=range(-160,160),
		Color=colors(Color3.fromRGB(150,200,90),Color3.fromRGB(240,210,120)),LightEmission=.15,
		Size=seq({{0,.35},{.8,.32},{1,0}}),Transparency=seq({{0,.1},{.8,.2},{1,1}}),ZOffset=.1}),list)
end

local BUILD={
	function(model,list) -- 1 EMBER
		local c=MeritAuraFX.TIERS[1].color
		feet(model,c,list,1);ring(model,c,list)
	end,
	function(model,list) -- 2 STORM
		local c=MeritAuraFX.TIERS[2].color
		feet(model,c,list,1.15);ring(model,c,list);outline(model,c,list,4)
	end,
	function(model,list) -- 3 LEGEND
		local c=MeritAuraFX.TIERS[3].color
		feet(model,c,list,1.3);ring(model,c,list);outline(model,c,list,6);leaves(model,list)
		local torso=part(model,"UpperTorso")
		if torso then
			local light=Instance.new("PointLight")
			light.Name="MeritLight";light.Color=c;light.Brightness=.8;light.Range=8;light.Shadows=false;light.Parent=torso
			table.insert(list,light)
		end
	end,
}

MeritAuraFX.worn=setmetatable({},{__mode="k"})

function MeritAuraFX.remove(model)
	local st=model and MeritAuraFX.worn[model]
	if not st then return end
	for _,item in st.items do
		if item.Parent then
			if item:IsA("ParticleEmitter") then item.Enabled=false end
			item:Destroy()
		end
	end
	MeritAuraFX.worn[model]=nil
	model:SetAttribute("MeritAura",nil)
end

function MeritAuraFX.setQuiet(model,quiet)
	local st=model and MeritAuraFX.worn[model]
	if not st then return end
	st.quiet=quiet and true or false
	for _,item in st.items do
		if item:IsA("ParticleEmitter") then
			item.Rate=(item:GetAttribute("MeritRate") or item.Rate)*(if st.quiet then MeritAuraFX.QUIET else 1)
		elseif item:IsA("PointLight") then
			item.Enabled=not st.quiet
		end
	end
end

function MeritAuraFX.wear(model,tier,quiet)
	if not model then return nil end
	MeritAuraFX.remove(model)
	tier=math.clamp(math.floor(tonumber(tier) or 0),0,#BUILD)
	if tier==0 then return nil end
	local list={}
	local ok,err=pcall(BUILD[tier],model,list)
	if not ok then
		for _,item in list do if item.Parent then item:Destroy() end end
		warn("[MeritAuraFX] "..tostring(err))
		return nil
	end
	MeritAuraFX.worn[model]={tier=tier,items=list,quiet=false}
	model:SetAttribute("MeritAura",MeritAuraFX.TIERS[tier].id)
	if quiet then MeritAuraFX.setQuiet(model,true) end
	return list
end

-- Every player wears his tier: the attribute NinjaAura (Server/Progression) on his Player,
-- put on his character now and at each respawn, changed when the attribute changes.
function MeritAuraFX.start()
	if MeritAuraFX.started then return end
	MeritAuraFX.started=true
	local Players=game:GetService("Players")
	local function dress(player)
		local character=player.Character
		if character then
			local tier=player:GetAttribute("NinjaAura") or 0
			local st=MeritAuraFX.worn[character]
			if not st or st.tier~=tier then MeritAuraFX.wear(character,tier,st and st.quiet) end
		end
	end
	local function track(player)
		player:GetAttributeChangedSignal("NinjaAura"):Connect(function() dress(player) end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart",10)
			dress(player)
		end)
		dress(player)
	end
	for _,player in Players:GetPlayers() do task.spawn(track,player) end
	Players.PlayerAdded:Connect(track)
end

-- the images the auras use (fetched with AwakenFX.preload)
function MeritAuraFX.textures()
	return {AwakenFX.ID.flame,AwakenFX.ID.ring,AwakenFX.ID.leaf}
end

return MeritAuraFX
