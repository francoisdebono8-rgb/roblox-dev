local World = {}
local Animation=require(script.Parent.Animation)
local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
World.part = part
-- --------------------------------------------------------------- arena
-- The Prodigy Tournament ground: a ringed stone stage in a walled bowl, tiered
-- wooden stands full of spectators, a judges' pavilion, banners, a torii
-- entrance and a forest/mountain backdrop. Everything the fighters use keeps
-- the combat contract: flat floor at the origin plane, NinjaWall slabs at
-- x = ±28 for wall running, raised platforms for height, stone posts for cover
-- and line of sight. Decoration never collides or blocks queries.
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local PALETTE={
	grass=rgb(88,116,66),sand=rgb(176,154,118),stone=rgb(172,164,146),stoneDark=rgb(116,110,98),stoneDeep=rgb(78,74,68),
	wood=rgb(126,86,54),woodDark=rgb(82,56,36),red=rgb(178,40,36),cream=rgb(240,232,212),roof=rgb(58,64,74),
	leaf=rgb(66,98,60),leafDark=rgb(46,74,48),blossom=rgb(240,176,190),rock=rgb(120,116,108),
}
local function deco(parent,name,size,cf,color,material,shape)
	local p=part(parent,name,size,cf,color,material)
	p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
	if shape then p.Shape=shape end
	return p
end
-- A flat disc lying on the floor (cylinder axis pointing up).
local function disc(parent,name,radius,y,origin,color,material)
	return deco(parent,name,Vector3.new(.06,radius*2,radius*2),CFrame.new(origin+Vector3.new(0,y,0))*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder)
end
local function label(target,face,text,color,font)
	local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(400,400);gui.LightInfluence=1;gui.Parent=target
	local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=color
	t.Font=font or Enum.Font.GothamBlack;t.TextScaled=true;t.Parent=gui
	return gui
end
local function spectator(parent,at,facing,seed)
	local tones={rgb(70,86,120),rgb(120,70,62),rgb(86,104,76),rgb(140,120,90),rgb(96,80,110),rgb(60,64,72),rgb(150,140,128)}
	local skin={rgb(232,198,166),rgb(204,166,136),rgb(176,134,104)}
	local body=deco(parent,"Spectator",Vector3.new(1.3,2.0,.9),CFrame.lookAt(at+Vector3.new(0,1.0,0),at+Vector3.new(0,1.0,0)+facing),tones[seed%#tones+1],Enum.Material.SmoothPlastic)
	body.CastShadow=false
	local head=deco(parent,"SpectatorHead",Vector3.new(.95,.95,.95),body.CFrame*CFrame.new(0,1.45,0),skin[seed%#skin+1],Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	head.CastShadow=false
	deco(parent,"SpectatorHair",Vector3.new(1.0,.45,1.0),head.CFrame*CFrame.new(0,.28,.05),if seed%4==0 then rgb(220,190,120) else rgb(36,30,28),Enum.Material.SmoothPlastic).CastShadow=false
end
local function pine(parent,at,scale)
	deco(parent,"Trunk",Vector3.new(1.4*scale,10*scale,1.4*scale),CFrame.new(at+Vector3.new(0,5*scale,0)),PALETTE.woodDark,Enum.Material.Wood)
	for k=0,3 do
		local r=(6-k*1.3)*scale
		deco(parent,"Needles",Vector3.new(r*2,3*scale,r*2),CFrame.new(at+Vector3.new(0,(7+k*3)*scale,0)),if k%2==0 then PALETTE.leafDark else PALETTE.leaf,Enum.Material.Grass,Enum.PartType.Ball)
	end
end
local function blossom(parent,at,scale)
	deco(parent,"Trunk",Vector3.new(1.2*scale,7*scale,1.2*scale),CFrame.new(at+Vector3.new(0,3.5*scale,0))*CFrame.Angles(0,0,math.rad(6)),PALETTE.woodDark,Enum.Material.Wood)
	for k,offset in {Vector3.new(0,8,0),Vector3.new(2.5,7,1),Vector3.new(-2.2,7.4,-1.4),Vector3.new(.6,9.4,-1.8)} do
		deco(parent,"Blossom",Vector3.new(6,4.6,6)*scale*(if k==1 then 1.2 else .9),CFrame.new(at+offset*scale),PALETTE.blossom,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	end
end
local function atmosphere()
	local Lighting=game:GetService("Lighting")
	if Lighting:FindFirstChild("NinjaDuelAtmosphere") then return end
	-- Late-afternoon tournament light: warm sun, soft haze, gentle bloom.
	Lighting.ClockTime=16.4;Lighting.GeographicLatitude=32
	Lighting.Brightness=2.6;Lighting.EnvironmentDiffuseScale=.6;Lighting.EnvironmentSpecularScale=.4
	Lighting.Ambient=rgb(92,88,96);Lighting.OutdoorAmbient=rgb(142,134,128)
	pcall(function() Lighting.Technology=Enum.Technology.ShadowMap end)
	local atmo=Instance.new("Atmosphere");atmo.Name="NinjaDuelAtmosphere";atmo.Density=.32;atmo.Offset=.12
	atmo.Color=rgb(222,206,182);atmo.Decay=rgb(130,112,104);atmo.Glare=.4;atmo.Haze=1.4;atmo.Parent=Lighting
	local cc=Instance.new("ColorCorrectionEffect");cc.Name="NinjaDuelGrade";cc.Saturation=.12;cc.Contrast=.08;cc.Brightness=.01;cc.TintColor=rgb(255,246,236);cc.Parent=Lighting
	local bloom=Instance.new("BloomEffect");bloom.Name="NinjaDuelBloom";bloom.Intensity=.55;bloom.Size=26;bloom.Threshold=1.4;bloom.Parent=Lighting
	local rays=Instance.new("SunRaysEffect");rays.Name="NinjaDuelRays";rays.Intensity=.05;rays.Spread=.6;rays.Parent=Lighting
end
World.atmosphere=atmosphere
function World.arena(parent, origin)
	local folder = Instance.new("Folder"); folder.Name = "Courtyard"; folder.Parent = parent
	local decor=Instance.new("Folder");decor.Name="Decor";decor.Parent=folder
	local C=PALETTE
	-- Ground and the ringed stage. The walkable floor is one flat plane.
	part(folder,"Training floor",Vector3.new(460,2,460),CFrame.new(origin-Vector3.new(0,1,0)),C.grass,Enum.Material.Grass)
	disc(decor,"Sand ring",84,.03,origin,C.sand,Enum.Material.Sand)
	disc(decor,"Stage",66,.06,origin,C.stone,Enum.Material.Slate)
	disc(decor,"Stage edge",66.6,.05,origin,C.stoneDeep,Enum.Material.Slate)
	disc(decor,"Line",44.4,.07,origin,C.stoneDark,Enum.Material.Slate)
	disc(decor,"Inner",44,.08,origin,C.stone,Enum.Material.Slate)
	-- Tournament emblem at the centre: red ring, cream field, the 天才 seal.
	disc(decor,"Emblem ring",13,.09,origin,C.red,Enum.Material.SmoothPlastic)
	disc(decor,"Emblem field",11.6,.1,origin,C.cream,Enum.Material.SmoothPlastic)
	local seal=deco(decor,"Emblem seal",Vector3.new(16,.05,16),CFrame.new(origin+Vector3.new(0,.13,0)),C.cream,Enum.Material.SmoothPlastic)
	seal.Transparency=1
	label(seal,Enum.NormalId.Top,"天才",C.red,Enum.Font.GothamBlack)
	-- Curb stones around the stage edge.
	for k=0,47 do
		local a=k/48*math.pi*2
		local at=origin+Vector3.new(math.sin(a)*67,.25,math.cos(a)*67)
		deco(decor,"Curb",Vector3.new(7.6,.5,1.4),CFrame.lookAt(at,origin+Vector3.new(0,.25,0)),if k%2==0 then C.stoneDark else C.stone,Enum.Material.Slate)
	end
	-- Low boundary wall of the bowl (just outside the fighters' limit).
	local wallRadius=82
	for k=0,39 do
		local a=k/40*math.pi*2
		local at=origin+Vector3.new(math.sin(a)*wallRadius,3,math.cos(a)*wallRadius)
		local w=part(folder,"Boundary",Vector3.new(13.4,6,2.4),CFrame.lookAt(at,origin+Vector3.new(0,3,0)),C.stoneDark,Enum.Material.Slate)
		w.CanQuery=false
		deco(decor,"Coping",Vector3.new(13.6,.6,3),w.CFrame*CFrame.new(0,3.3,0),C.stone,Enum.Material.Slate)
	end
	-- Tiered stands with spectators, broken by the judges' pavilion (north)
	-- and the torii entrance (south).
	local seed=0
	for tier=1,4 do
		local radius=wallRadius+3+tier*4.2
		local height=tier*2.6
		local steps=math.floor(radius*2*math.pi/7)
		for k=0,steps-1 do
			local a=k/steps*math.pi*2
			local north=math.abs(((a+math.pi)%(2*math.pi))-math.pi)<.32
			local south=math.abs(a-math.pi)<.22
			if not south then
				local at=origin+Vector3.new(math.sin(a)*radius,height/2,math.cos(a)*radius)
				local look=CFrame.lookAt(at,origin+Vector3.new(0,height/2,0))
				deco(decor,"Stand",Vector3.new(7.4,height,4.4),look,if tier%2==0 then C.wood else C.woodDark,Enum.Material.Wood)
				if not north then
					seed+=1
					if seed%3~=0 then
						local seat=look*CFrame.new(((seed*37)%5-2)*.9,height/2,.6)
						spectator(decor,seat.Position,(origin-seat.Position)*Vector3.new(1,0,1),seed)
					end
				end
			end
		end
	end
	-- Judges' pavilion on the north side: raised floor, posts, roof, three judges.
	local judges=origin+Vector3.new(0,0,-(wallRadius+9))
	local face=CFrame.lookAt(judges,origin)
	deco(decor,"Pavilion floor",Vector3.new(26,9,12),face*CFrame.new(0,4.5,0),C.woodDark,Enum.Material.Wood)
	for _,x in {-12,-4,4,12} do deco(decor,"Pavilion post",Vector3.new(1.2,12,1.2),face*CFrame.new(x,15,4.6),C.red,Enum.Material.Wood) end
	for _,side in {-1,1} do
		local roof=deco(decor,"Pavilion roof",Vector3.new(30,2.6,8.5),face*CFrame.new(0,22.2,side*3.4)*CFrame.Angles(math.rad(side*-22),0,0),C.roof,Enum.Material.Slate,Enum.PartType.Block)
		roof.Name="Pavilion roof"
	end
	deco(decor,"Pavilion ridge",Vector3.new(31,1,1),face*CFrame.new(0,23.8,0),C.red,Enum.Material.Wood)
	for _,x in {-6,0,6} do
		local seat=face*CFrame.new(x,9,-1)
		spectator(decor,seat.Position,(origin-seat.Position)*Vector3.new(1,0,1),if x==0 then 5 else 2)
		deco(decor,"Judge desk",Vector3.new(4.5,1.6,1.4),face*CFrame.new(x,9.8,-3.4),C.red,Enum.Material.Wood)
	end
	local hanging=deco(decor,"Pavilion banner",Vector3.new(14,4.2,.2),face*CFrame.new(0,18.6,-4.7),C.cream,Enum.Material.SmoothPlastic)
	label(hanging,Enum.NormalId.Back,"天才忍者大会",C.red)
	-- Torii gate at the south entrance.
	local gate=CFrame.lookAt(origin+Vector3.new(0,0,wallRadius+2),origin)
	for _,x in {-7,7} do deco(decor,"Torii post",Vector3.new(18,1.8,1.8),gate*CFrame.new(x,9,0)*CFrame.Angles(0,0,math.pi/2),C.red,Enum.Material.Wood,Enum.PartType.Cylinder) end
	deco(decor,"Torii kasagi",Vector3.new(21,1.6,2.4),gate*CFrame.new(0,18.6,0),C.roof,Enum.Material.Wood)
	deco(decor,"Torii nuki",Vector3.new(17,1.1,1.4),gate*CFrame.new(0,15,0),C.red,Enum.Material.Wood)
	local plaque=deco(decor,"Torii plaque",Vector3.new(3.2,3,.3),gate*CFrame.new(0,16.8,0),C.roof,Enum.Material.Wood)
	label(plaque,Enum.NormalId.Front,"試",C.cream)
	-- Banners on tall poles around the bowl.
	for k=0,7 do
		local a=(k+.5)/8*math.pi*2
		local at=origin+Vector3.new(math.sin(a)*(wallRadius-1.5),0,math.cos(a)*(wallRadius-1.5))
		local look=CFrame.lookAt(at,Vector3.new(origin.X,at.Y,origin.Z))
		deco(decor,"Banner pole",Vector3.new(.5,22,.5),look*CFrame.new(0,11,0),C.woodDark,Enum.Material.Wood)
		deco(decor,"Banner bar",Vector3.new(5.4,.4,.4),look*CFrame.new(0,21.4,-.3),C.woodDark,Enum.Material.Wood)
		local cloth=deco(decor,"Banner",Vector3.new(5,12,.12),look*CFrame.new(0,15,-.4),if k%2==0 then C.red else C.cream,Enum.Material.SmoothPlastic)
		label(cloth,Enum.NormalId.Front,"天\n才",if k%2==0 then C.cream else C.red)
	end
	-- Stone lanterns around the stage with warm light.
	for k=0,7 do
		local a=k/8*math.pi*2
		local at=origin+Vector3.new(math.sin(a)*70.5,0,math.cos(a)*70.5)
		deco(decor,"Lantern base",Vector3.new(2.2,1,2.2),CFrame.new(at+Vector3.new(0,.5,0)),C.stoneDark,Enum.Material.Slate)
		deco(decor,"Lantern post",Vector3.new(1,3.4,1),CFrame.new(at+Vector3.new(0,2.7,0)),C.stone,Enum.Material.Slate)
		local box=deco(decor,"Lantern",Vector3.new(1.9,1.6,1.9),CFrame.new(at+Vector3.new(0,5.2,0)),rgb(255,214,150),Enum.Material.Neon)
		deco(decor,"Lantern cap",Vector3.new(3,.6,3),CFrame.new(at+Vector3.new(0,6.3,0)),C.stoneDark,Enum.Material.Slate)
		local light=Instance.new("PointLight");light.Color=rgb(255,190,120);light.Range=18;light.Brightness=1.4;light.Shadows=false;light.Parent=box
	end
	-- Fight-space features.
	for _,x in { -1, 1 } do
		-- Carved stone slabs: the wall-run surfaces (and the tutorial's wall).
		local wall=part(folder,"Ninja wall",Vector3.new(3,23,26),CFrame.new(origin+Vector3.new(x*28,11.5,0)),C.stoneDark,Enum.Material.Slate)
		wall:SetAttribute("NinjaWall",true)
		for _,y in {4,11.5,19} do
			deco(decor,"Carving",Vector3.new(3.1,.5,24),CFrame.new(origin+Vector3.new(x*28,y,0)),C.stoneDeep,Enum.Material.Slate)
		end
		local mark=deco(decor,"Slab mark",Vector3.new(3.12,8,8),CFrame.new(origin+Vector3.new(x*28,14,0)),C.stoneDark,Enum.Material.Slate)
		mark.Transparency=1
		label(mark,if x<0 then Enum.NormalId.Right else Enum.NormalId.Left,"忍",C.red)
		local ledge=part(folder,"Wall ledge",Vector3.new(10,1,29),CFrame.new(origin+Vector3.new(x*28,23,0)),C.wood,Enum.Material.Wood)
		ledge.CanQuery=true
		part(folder,"Training beam",Vector3.new(1.2,1.2,28),CFrame.new(origin+Vector3.new(x*28,20,0)),C.woodDark,Enum.Material.Wood)
	end
	for _, z in { -40, 40 } do
		-- Rock cover and raised wooden platforms for height and sight lines.
		local rock=part(folder,"Cover",Vector3.new(8,4,3),CFrame.new(origin+Vector3.new(18,2,z)),C.rock,Enum.Material.Slate)
		deco(decor,"Rock cap",Vector3.new(6,2.4,4),rock.CFrame*CFrame.new(-.6,2.2,0)*CFrame.Angles(0,math.rad(18),math.rad(8)),C.rock,Enum.Material.Slate)
		local platform=part(folder,"Step platform",Vector3.new(14,1.2,14),CFrame.new(origin+Vector3.new(-17,7,z)),C.wood,Enum.Material.WoodPlanks)
		for _,cx in {-6,6} do for _,cz in {-6,6} do
			part(folder,"Platform post",Vector3.new(1,6.4,1),platform.CFrame*CFrame.new(cx,-3.8,cz),C.woodDark,Enum.Material.Wood)
		end end
	end
	-- Three training posts: the classic test of a genin team.
	for k,x in {-6,0,6} do
		local post=part(folder,"Training post",Vector3.new(5,1.8,1.8),CFrame.new(origin+Vector3.new(x,2.5,54))*CFrame.Angles(0,0,math.pi/2),C.wood,Enum.Material.Wood)
		post.Shape=Enum.PartType.Cylinder
		deco(decor,"Rope",Vector3.new(.4,1.9,1.9),post.CFrame*CFrame.new(.6,0,0),C.cream,Enum.Material.Fabric,Enum.PartType.Cylinder)
	end
	-- Backdrop: pines and blossoms around the bowl, mountains beyond.
	for k=0,23 do
		local a=k/24*math.pi*2+.13
		local r=112+((k*53)%7)*4
		local at=origin+Vector3.new(math.sin(a)*r,0,math.cos(a)*r)
		if k%3==0 then blossom(decor,at,1.4) else pine(decor,at,1.5+((k*31)%3)*.25) end
	end
	-- Distant ridges: four-sided peaks hazed by the atmosphere.
	for k=0,11 do
		local a=k/12*math.pi*2+.2
		local r=250+((k*37)%3)*30
		local at=origin+Vector3.new(math.sin(a)*r,0,math.cos(a)*r)
		local h=90+((k*41)%5)*22
		local half=70+((k*29)%4)*12
		local tone=if k%2==0 then rgb(104,118,122) else rgb(90,104,110)
		for q=0,3 do
			local turn=CFrame.new(at)*CFrame.Angles(0,q*math.pi/2+a,0)
			deco(decor,"Mountain",Vector3.new(half,h,half),turn*CFrame.new(half/2,h/2-6,-half/2),tone,Enum.Material.Rock).Name="Mountain"
		end
	end
	-- Peaks are corner wedges so four of them meet at a summit.
	for _,m in decor:GetChildren() do
		if m.Name=="Mountain" and m:IsA("Part") then
			local w=Instance.new("CornerWedgePart");w.Name="Mountain";w.Size=m.Size;w.CFrame=m.CFrame;w.Color=m.Color;w.Material=m.Material
			w.Anchored=true;w.CanCollide=false;w.CanQuery=false;w.CanTouch=false;w.CastShadow=false;w.Parent=decor;m:Destroy()
		end
	end
	-- Drifting petals over the stage.
	local sky=deco(decor,"Petal source",Vector3.new(140,1,140),CFrame.new(origin+Vector3.new(0,44,0)),C.cream,Enum.Material.SmoothPlastic)
	sky.Transparency=1
	local petals=Instance.new("ParticleEmitter");petals.Name="Petals"
	petals.Texture="rbxasset://textures/particles/sparkles_main.dds";petals.Rate=6;petals.Lifetime=NumberRange.new(9,13)
	petals.Speed=NumberRange.new(2,4);petals.EmissionDirection=Enum.NormalId.Bottom;petals.SpreadAngle=Vector2.new(30,30)
	petals.Color=ColorSequence.new(C.blossom);petals.LightEmission=.2;petals.Size=NumberSequence.new(.35)
	petals.Rotation=NumberRange.new(0,360);petals.RotSpeed=NumberRange.new(-90,90);petals.Acceleration=Vector3.new(1.2,-.6,.4)
	petals.Parent=sky
	atmosphere()
	return folder
end
function World.rig(parent, def, cf, name)
	local model = Instance.new("Model"); model.Name=name; model.Parent=parent
	local skin=Color3.fromRGB(table.unpack(def.Skin))
	local outfit=Color3.fromRGB(table.unpack(def.Outfit))
	local pants=Color3.fromRGB(35,43,54)
	local color=Color3.fromRGB(table.unpack(def.Color))
	local root=part(model,"HumanoidRootPart",Vector3.new(2,2,1),cf,outfit)
	root.Transparency=1
	local function body(name,size,offset,tint)
		return part(model,name,size,cf*CFrame.new(offset),tint)
	end
	local lower=body("LowerTorso",Vector3.new(2,1,1),Vector3.new(0,0,0),outfit)
	local upper=body("UpperTorso",Vector3.new(2,1.4,1),Vector3.new(0,1.15,0),outfit)
	local head=body("Head",Vector3.new(1.5,1.5,1.5),Vector3.new(0,2.45,0),skin)
	local hum=Instance.new("Humanoid")
	hum.RigType=Enum.HumanoidRigType.R15; hum.RequiresNeck=true; hum.BreakJointsOnDeath=false
	hum.MaxHealth=def.Health; hum.Health=def.Health; hum.WalkSpeed=def.Speed
	hum.UseJumpPower=true; hum.JumpPower=68; hum.HipHeight=2
	hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; hum.Parent=model
	Instance.new("Animator",hum)
	local joints={}
	local function joint(name,p0,p1,c0,c1)
		local m=Instance.new("Motor6D");m.Name=name;m.Part0=p0;m.Part1=p1;m.C0=CFrame.new(c0);m.C1=CFrame.new(c1);m.Parent=p0
		joints[name]=m;return m
	end
	joint("Root",root,lower,Vector3.zero,Vector3.zero)
	joint("Waist",lower,upper,Vector3.new(0,0.65,0),Vector3.new(0,-0.5,0))
	joint("Neck",upper,head,Vector3.new(0,0.9,0),Vector3.new(0,-0.55,0))
	for _,side in {-1,1} do
		local prefix=if side==-1 then "Left" else "Right"
		local armTop=body(prefix.."UpperArm",Vector3.new(0.8,1.1,0.8),Vector3.new(side*1.45,0.72,0),outfit)
		local armLow=body(prefix.."LowerArm",Vector3.new(0.76,0.95,0.76),Vector3.new(side*1.45,-0.28,0),outfit)
		local hand=body(prefix.."Hand",Vector3.new(0.72,0.5,0.72),Vector3.new(side*1.45,-1.0,0),skin)
		local legTop=body(prefix.."UpperLeg",Vector3.new(0.85,1.1,0.85),Vector3.new(side*0.5,-0.85,0),pants)
		local legLow=body(prefix.."LowerLeg",Vector3.new(0.8,1.05,0.8),Vector3.new(side*0.5,-1.75,0),pants)
		local foot=body(prefix.."Foot",Vector3.new(0.8,0.42,1.15),Vector3.new(side*0.5,-2.55,-0.15),pants)
		joint(prefix.."Shoulder",upper,armTop,Vector3.new(side*1.05,0.45,0),Vector3.new(-side*0.4,0.5,0))
		joint(prefix.."Elbow",armTop,armLow,Vector3.new(0,-0.55,0),Vector3.new(0,0.45,0))
		joint(prefix.."Wrist",armLow,hand,Vector3.new(0,-0.48,0),Vector3.new(0,0.25,0))
		joint(prefix.."Hip",lower,legTop,Vector3.new(side*0.5,-0.55,0),Vector3.new(0,0.5,0))
		joint(prefix.."Knee",legTop,legLow,Vector3.new(0,-0.55,0),Vector3.new(0,0.5,0))
		joint(prefix.."Ankle",legLow,foot,Vector3.new(0,-0.5,0),Vector3.new(0,0.2,0.15))
	end
	local hair=body("Hair",Vector3.new(1.65,0.55,1.65),Vector3.new(0,3,0),Color3.fromRGB(table.unpack(def.Hair)))
	joint("HairJoint",head,hair,Vector3.new(0,0.57,0),Vector3.new(0,-0.25,0))
	local sash=body("Sash",Vector3.new(2.1,0.25,1.1),Vector3.new(0,-0.4,0),color)
	joint("SashJoint",lower,sash,Vector3.new(0,-0.4,0),Vector3.zero)
	local eyes=body("Eyes",Vector3.new(0.85,0.1,0.05),Vector3.new(0,2.6,-0.76),Color3.fromRGB(24,31,38))
	joint("EyeJoint",head,eyes,Vector3.new(0,0.15,-0.76),Vector3.zero)
	for _,piece in model:GetChildren() do
		if piece:IsA("BasePart") then
			piece.Anchored=false
			piece.CanCollide=piece==root
			piece.CanQuery=piece==root or piece==lower or piece==upper or piece==head
			piece.Massless=piece~=root
		end
	end
	World.dress(model,def)
	model.PrimaryPart=root; root:SetNetworkOwner(nil)
	return model,hum,root,joints
end
-- --------------------------------------------------------------- costumes
-- Cosmetic layers welded onto the R15 body parts: silhouettes that read as the
-- two shinobi at combat distance. Massless, never collide, never block queries.
local function wear(model,bodyName,name,size,offset,color,material,class)
	local body=model:FindFirstChild(bodyName)
	if not body then return nil end
	local p=Instance.new(class or "Part")
	p.Name=name;p.Size=size;p.CFrame=body.CFrame*offset;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
	p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=true
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=p;weld.Parent=p
	p.Parent=model
	return p
end
World.wear=wear
local function cyl(p)
	if p then p.Shape=Enum.PartType.Cylinder end
	return p
end
local A=CFrame.Angles
local R=math.rad
local function headband(model,slashed)
	wear(model,"Head","Headband",Vector3.new(1.66,.24,1.66),CFrame.new(0,.36,0),rgb(28,36,58),Enum.Material.SmoothPlastic)
	wear(model,"Head","HeadbandPlate",Vector3.new(.86,.3,.06),CFrame.new(0,.36,-.85),rgb(176,184,194),Enum.Material.Metal)
	-- The Leaf symbol, reduced to a readable spiral mark.
	wear(model,"Head","LeafMark",Vector3.new(.3,.14,.02),CFrame.new(0,.38,-.89),rgb(70,78,90),Enum.Material.Metal)
	if slashed then wear(model,"Head","Slash",Vector3.new(.92,.04,.03),CFrame.new(0,.36,-.86)*A(0,0,R(-8)),rgb(30,30,34),Enum.Material.Metal) end
	for _,side in {-1,1} do
		wear(model,"Head","HeadbandTail",Vector3.new(.16,.55,.08),CFrame.new(side*.25,.18,.84)*A(R(18),0,R(side*10)),rgb(28,36,58),Enum.Material.SmoothPlastic)
	end
end
local function face(model,eye,brow)
	local eyes=model:FindFirstChild("Eyes")
	if eyes then eyes.Transparency=1 end
	for _,side in {-1,1} do
		wear(model,"Head","Eye",Vector3.new(.3,.17,.04),CFrame.new(side*.3,.08,-.8),rgb(245,245,240))
		wear(model,"Head","Iris",Vector3.new(.15,.15,.03),CFrame.new(side*.3,.07,-.825),eye,Enum.Material.SmoothPlastic)
		wear(model,"Head","Brow",Vector3.new(.34,.06,.04),CFrame.new(side*.3,.27,-.8)*A(0,0,R(side*-8)),brow)
	end
	wear(model,"Head","Mouth",Vector3.new(.28,.04,.03),CFrame.new(0,-.36,-.78),rgb(120,70,64))
end
-- Smooth rounded hair cap over the crown.
local function hairCap(model,color)
	local cap=wear(model,"Head","HairCap",Vector3.new(1.98,1.3,2.02),CFrame.new(0,.5,.08),color)
	if cap then
		local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=cap
	end
	return cap
end
-- A tapered lock: a long thin wedge whose point sits `length` along `direction`
-- from `base` (head space).
local function spike(model,base,direction,length,width,height,color)
	local d=direction.Unit
	local center=base+d*length*.5
	local up=if math.abs(d.Y)>.9 then Vector3.zAxis else Vector3.yAxis
	local cf=CFrame.lookAt(center,center+d,up)
	return wear(model,"Head","HairSpike",Vector3.new(width,height,length),cf,color,Enum.Material.SmoothPlastic,"WedgePart")
end
-- Young prodigies (12-14), not adult final forms: practical genin/chunin gear,
-- bigger heads and lighter builds, with only hints of who they will become.
local function dressMinato(model,def)
	local hair=rgb(250,216,98)
	local hairShade=rgb(228,182,60)
	local navy=rgb(34,52,92)
	local navyDark=rgb(24,34,60)
	local light=rgb(226,230,232)
	local accent=rgb(236,110,44)
	local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
	face(model,rgb(70,140,220),hairShade)
	hairCap(model,hair)
	-- Spiky but younger mane: shorter locks, two framing bangs.
	local spikes={
		{Vector3.new(0,.78,.25),Vector3.new(0,.4,1),.9,.6,.38},
		{Vector3.new(-.45,.66,.28),Vector3.new(-.5,.35,1),.82,.5,.34},
		{Vector3.new(.45,.66,.28),Vector3.new(.5,.35,1),.82,.5,.34},
		{Vector3.new(0,.45,.62),Vector3.new(0,-.05,1),.78,.66,.38},
		{Vector3.new(-.5,.3,.58),Vector3.new(-.55,-.3,.9),.7,.48,.32},
		{Vector3.new(.5,.3,.58),Vector3.new(.55,-.3,.9),.7,.48,.32},
		{Vector3.new(0,-.12,.68),Vector3.new(0,-.7,.75),.6,.6,.3},
		{Vector3.new(-.72,.5,.05),Vector3.new(-1,.5,.35),.52,.4,.28},
		{Vector3.new(.72,.5,.05),Vector3.new(1,.5,.35),.52,.4,.28},
		{Vector3.new(-.25,.82,-.2),Vector3.new(-.35,1,-.25),.45,.38,.28},
		{Vector3.new(.25,.82,-.2),Vector3.new(.35,1,-.25),.45,.38,.28},
	}
	for index,s in spikes do spike(model,s[1],s[2],s[3],s[4],s[5],if index%2==0 then hairShade else hair) end
	for _,x in {-.38,0,.38} do spike(model,Vector3.new(x,.62,-.55),Vector3.new(x*.4,-.75,-.55),.5,.42,.24,hair) end
	for _,side in {-1,1} do
		wear(model,"Head","Bang",Vector3.new(.2,.95,.34),CFrame.new(side*.8,-.05,-.42)*A(R(4),0,R(side*4)),hair)
		wear(model,"Head","SideHair",Vector3.new(.16,.8,.8),CFrame.new(side*.8,.08,.3),hair)
	end
	wear(model,"Head","BackHair",Vector3.new(1.6,1.0,.26),CFrame.new(0,.05,.74),hair)
	headband(model,false)
	-- Navy zip-up with a high collar, a light open half-vest (the seed of the
	-- future cloak, no rank marks), kunai holster on the right thigh.
	for _,name in {"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"} do
		local part=model:FindFirstChild(name);if part then part.Color=navy end
	end
	wear(model,"UpperTorso","Collar",Vector3.new(1.25,.36,1.02),CFrame.new(0,.8,.02),navy)
	wear(model,"UpperTorso","Zip",Vector3.new(.06,1.3,.03),CFrame.new(0,0,-.52),light)
	wear(model,"UpperTorso","HalfVestBack",Vector3.new(2.12,1.36,.08),CFrame.new(0,-.02,.56),light)
	for _,side in {-1,1} do
		wear(model,"UpperTorso","HalfVestFront",Vector3.new(.62,1.3,.08),CFrame.new(side*.72,-.05,-.56),light)
		wear(model,"UpperTorso","HalfVestSide",Vector3.new(.08,1.32,1.12),CFrame.new(side*1.04,-.03,0),light)
		wear(model,"UpperTorso","VestTrim",Vector3.new(.64,.08,.1),CFrame.new(side*.72,-.66,-.56),accent)
	end
	wear(model,"UpperTorso","VestTrimBack",Vector3.new(2.14,.08,.1),CFrame.new(0,-.66,.56),accent)
	wear(model,"LowerTorso","Belt",Vector3.new(2.06,.24,1.06),CFrame.new(0,.28,0),navyDark)
	wear(model,"LowerTorso","ToolPouch",Vector3.new(.7,.42,.3),CFrame.new(0,.12,.62),rgb(70,80,92))
	wear(model,"RightUpperLeg","ThighWrap",Vector3.new(.9,.4,.9),CFrame.new(0,.05,0),light)
	wear(model,"RightUpperLeg","Holster",Vector3.new(.24,.5,.5),CFrame.new(.5,-.05,0),navyDark)
	cyl(wear(model,"RightUpperLeg","HolsterRing",Vector3.new(.06,.22,.22),CFrame.new(.55,.3,0),rgb(120,126,134),Enum.Material.Metal))
	for _,side in {"Left","Right"} do
		local legLow=model:FindFirstChild(side.."LowerLeg");if legLow then legLow.Color=navyDark end
		local legTop=model:FindFirstChild(side.."UpperLeg");if legTop then legTop.Color=navyDark end
		wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.84,.55,.84),CFrame.new(0,-.15,0),light)
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=rgb(28,36,56) end
		wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),Color3.fromRGB(table.unpack(def.Skin)))
		wear(model,side.."LowerArm","Cuff",Vector3.new(.8,.18,.8),CFrame.new(0,-.38,0),light)
	end
end
-- Uchiha fan crest: red upper disc, white lower disc in front, short handle.
local function crest(model,body,offset,scale)
	cyl(wear(model,body,"CrestRed",Vector3.new(.04,.66*scale,.66*scale),offset*CFrame.new(0,.12*scale,0)*A(0,R(90),0),rgb(200,30,36)))
	cyl(wear(model,body,"CrestWhite",Vector3.new(.04,.46*scale,.46*scale),offset*CFrame.new(0,-.06*scale,-.02)*A(0,R(90),0),rgb(238,238,236)))
	wear(model,body,"CrestHandle",Vector3.new(.09*scale,.34*scale,.03),offset*CFrame.new(0,-.4*scale,-.02),rgb(238,238,236))
end
local function dressItachi(model,def)
	local hair=rgb(22,22,28)
	local shirt=rgb(48,52,68)
	local dark=rgb(22,22,30)
	local gray=rgb(132,136,146)
	local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
	face(model,rgb(200,20,30),hair)
	for _,p in model:GetChildren() do if p.Name=="Iris" then p.Material=Enum.Material.Neon end end
	hairCap(model,hair)
	-- Long dark hair tied low, centre-parted bangs framing the face.
	for _,side in {-1,1} do
		wear(model,"Head","Bang",Vector3.new(.24,1.15,.42),CFrame.new(side*.76,-.12,-.42)*A(R(3),0,R(side*3)),hair)
		wear(model,"Head","SideHair",Vector3.new(.18,1.0,.9),CFrame.new(side*.8,-.02,.25),hair)
	end
	for _,x in {-.42,-.12,.18,.45} do
		wear(model,"Head","Fringe",Vector3.new(.32,.42,.26),CFrame.new(x,.52,-.68)*A(R(196),0,0),hair,Enum.Material.SmoothPlastic,"WedgePart")
	end
	wear(model,"Head","BackHair",Vector3.new(1.62,1.2,.3),CFrame.new(0,-.05,.72),hair)
	cyl(wear(model,"Head","Ponytail",Vector3.new(1.0,.24,.24),CFrame.new(0,-.85,.86)*A(0,0,R(80))*A(0,R(10),0),hair))
	headband(model,false)
	-- Village-era Uchiha: dark high-collared shirt with the clan crest on the
	-- back, grey arm guards, shuriken holster. No cloak, no rings.
	for _,name in {"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm"} do
		local part=model:FindFirstChild(name);if part then part.Color=shirt end
	end
	wear(model,"UpperTorso","HighCollar",Vector3.new(1.45,.55,1.12),CFrame.new(0,.86,.04),shirt)
	crest(model,"UpperTorso",CFrame.new(0,.1,.53)*A(0,R(180),0),1.2)
	for _,side in {"Left","Right"} do
		wear(model,side.."LowerArm","ArmGuard",Vector3.new(.84,.72,.84),CFrame.new(0,-.05,0),gray,Enum.Material.Metal)
		wear(model,side.."UpperArm","Sleeve",Vector3.new(.86,.5,.86),CFrame.new(0,.28,0),shirt)
		local legLow=model:FindFirstChild(side.."LowerLeg");if legLow then legLow.Color=dark end
		local legTop=model:FindFirstChild(side.."UpperLeg");if legTop then legTop.Color=dark end
		wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.84,.55,.84),CFrame.new(0,-.15,0),rgb(206,206,198))
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=rgb(28,28,36) end
		wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),Color3.fromRGB(table.unpack(def.Skin)))
	end
	wear(model,"LowerTorso","Belt",Vector3.new(2.06,.22,1.06),CFrame.new(0,.3,0),dark)
	wear(model,"RightUpperLeg","ThighWrap",Vector3.new(.9,.36,.9),CFrame.new(0,.05,0),rgb(206,206,198))
	wear(model,"RightUpperLeg","Holster",Vector3.new(.24,.5,.5),CFrame.new(.5,-.05,0),dark)
end
local function soften(model)
	local head=model:FindFirstChild("Head")
	if head and not head:FindFirstChildOfClass("SpecialMesh") then
		-- A slightly larger, rounded head reads as a 12-14 year old, not an adult.
		local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Head;mesh.Scale=Vector3.new(1.24,1.26,1.24);mesh.Parent=head
	end
end
function World.dress(model,def)
	soften(model)
	-- The rig's coloured test sash is replaced by each costume's own belt.
	local sash=model:FindFirstChild("Sash");if sash then sash.Transparency=1 end
	if def.Name=="Minato" then dressMinato(model,def) elseif def.Name=="Itachi" then dressItachi(model,def) end
	-- Hair and head gear never shadow the face; the body still casts.
	local head=model:FindFirstChild("Head")
	for _,p in model:GetChildren() do
		if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
			local weld=p:FindFirstChildOfClass("WeldConstraint")
			p.CastShadow=not (p==head or (weld and weld.Part0==head))
		end
	end
end
function World.pose(a,now,dt)
 Animation.step(a,now)
end
return World
