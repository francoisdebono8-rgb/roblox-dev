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
-- The Konoha Chunin Exam finals stadium, as close as the block toolkit allows:
-- a round field of packed earth and grass, bushes along the foot of a very tall
-- circular wall of pale panels (the wall fighters run up), a few big trees on
-- the field, spectator stands crowning the wall under white pavilions with
-- golden roofs, the larger Kage box, the participants' balcony and the gate.
-- Combat contract: flat floor at the origin plane; the wall segments are the
-- NinjaWall surfaces just outside the fighters' round limit.
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local PALETTE={
	grass=rgb(104,136,70),grassDark=rgb(84,116,58),earth=rgb(178,152,110),earthDark=rgb(150,126,92),
	wall=rgb(218,216,196),wallSeam=rgb(178,180,160),wallBand=rgb(196,198,178),
	brick=rgb(152,74,52),brickDark=rgb(118,56,40),plaster=rgb(238,236,226),
	roof=rgb(222,164,58),roofDark=rgb(176,120,38),trim=rgb(70,62,56),wood=rgb(120,84,54),woodDark=rgb(84,58,38),
	leaf=rgb(70,112,58),leafDark=rgb(52,90,48),bark=rgb(96,70,50),
}
-- The stadium is large next to a 12-year-old: crossing it is a sprint, the
-- wall is a destination, not the edge of every exchange.
World.WALL_RADIUS=103
local function deco(parent,name,size,cf,color,material,shape)
	local p=part(parent,name,size,cf,color,material)
	p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
	if shape then p.Shape=shape end
	return p
end
-- A flat disc lying on the floor (cylinder axis pointing up).
local function disc(parent,name,radius,y,center,color,material)
	return deco(parent,name,Vector3.new(.06,radius*2,radius*2),CFrame.new(center+Vector3.new(0,y,0))*CFrame.Angles(0,0,math.pi/2),color,material,Enum.PartType.Cylinder)
end
local function label(target,face,text,color,font)
	local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(400,400);gui.LightInfluence=1;gui.Parent=target
	local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=color
	t.Font=font or Enum.Font.GothamBlack;t.TextScaled=true;t.Parent=gui
	return gui
end
local function spectator(folder,at,facing,seed)
	local parent=Instance.new("Model");parent.Name="SpectatorFigure";parent.Parent=folder
	local tones={rgb(70,96,74),rgb(70,86,120),rgb(120,70,62),rgb(140,120,90),rgb(96,80,110),rgb(60,64,72),rgb(150,140,128),rgb(86,104,76)}
	local skin={rgb(232,198,166),rgb(204,166,136),rgb(176,134,104)}
	local body=deco(parent,"Spectator",Vector3.new(1.3,2.0,.9),CFrame.lookAt(at+Vector3.new(0,1.0,0),at+Vector3.new(0,1.0,0)+facing),tones[seed%#tones+1],Enum.Material.SmoothPlastic)
	body.CastShadow=false
	local head=deco(parent,"SpectatorHead",Vector3.new(.95,.95,.95),body.CFrame*CFrame.new(0,1.45,0),skin[seed%#skin+1],Enum.Material.SmoothPlastic,Enum.PartType.Ball)
	head.CastShadow=false
	deco(parent,"SpectatorHair",Vector3.new(1.0,.45,1.0),head.CFrame*CFrame.new(0,.28,.05),if seed%4==0 then rgb(220,190,120) else rgb(36,30,28),Enum.Material.SmoothPlastic).CastShadow=false
end
local function tree(parent,at,height,spread)
	-- Field trees: a real trunk (cover and line of sight) under a loose crown.
	local trunk=part(parent,"Field tree",Vector3.new(2.6,height,2.6),CFrame.new(at+Vector3.new(0,height/2,0)),PALETTE.bark,Enum.Material.Wood)
	trunk.Shape=Enum.PartType.Block
	local crown=deco(parent,"Crown",Vector3.new(spread*2,spread*1.4,spread*2),CFrame.new(at+Vector3.new(0,height+spread*.3,0)),PALETTE.leaf,Enum.Material.Grass,Enum.PartType.Ball)
	crown.Size=Vector3.one*spread*1.9
	for k=0,4 do
		local a=k/5*math.pi*2
		deco(parent,"Crown",Vector3.one*spread*(1.1+(k%2)*.25),CFrame.new(at+Vector3.new(math.sin(a)*spread*.75,height-spread*.1+(k%3)*.8,math.cos(a)*spread*.75)),
			if k%2==0 then PALETTE.leafDark else PALETTE.leaf,Enum.Material.Grass,Enum.PartType.Ball)
	end
	for k=0,2 do
		local a=k/3*math.pi*2+.4
		deco(parent,"Branch",Vector3.new(.9,spread*1.1,.9),CFrame.new(at+Vector3.new(0,height*.72,0))*CFrame.Angles(0,a,math.rad(48))*CFrame.new(0,spread*.5,0),PALETTE.bark,Enum.Material.Wood)
	end
	return trunk
end
-- A white pavilion with a golden curved roof sitting on the stands.
local function pavilion(parent,cf,width,depth,height,tiers)
	deco(parent,"Pavilion",Vector3.new(width,height,depth),cf*CFrame.new(0,height/2,0),PALETTE.plaster,Enum.Material.SmoothPlastic)
	for k=-math.floor(width/6),math.floor(width/6) do
		deco(parent,"Window",Vector3.new(2.6,height*.38,.2),cf*CFrame.new(k*5.2,height*.58,-depth/2-.05),PALETTE.trim,Enum.Material.SmoothPlastic)
	end
	deco(parent,"Base trim",Vector3.new(width+.4,.8,depth+.4),cf*CFrame.new(0,.4,0),PALETTE.trim,Enum.Material.Wood)
	local y=height
	for tier=1,tiers do
		local w=width+6-tier*3;local d=depth+6-tier*3
		local pitch=math.rad(24)
		for _,side in {-1,1} do
			deco(parent,"Roof",Vector3.new(w,.9,d/2+1),cf*CFrame.new(0,y+1.1,side*(d/4))*CFrame.Angles(side*-pitch,0,0),PALETTE.roof,Enum.Material.SmoothPlastic)
			-- Up-turned eaves at the four corners.
			for _,ex in {-1,1} do
				deco(parent,"Eave",Vector3.new(2.2,.7,2.2),cf*CFrame.new(ex*(w/2-.6),y+.4,side*(d/2+.4))*CFrame.Angles(side*math.rad(-20),0,ex*math.rad(18)),PALETTE.roofDark,Enum.Material.SmoothPlastic)
			end
		end
		deco(parent,"Ridge",Vector3.new(w+.6,.7,.9),cf*CFrame.new(0,y+1.1+math.tan(pitch)*(d/4)+.6,0),PALETTE.roofDark,Enum.Material.SmoothPlastic)
		if tier<tiers then
			deco(parent,"Upper storey",Vector3.new(w-6,4,d-6),cf*CFrame.new(0,y+3.6,0),PALETTE.plaster,Enum.Material.SmoothPlastic)
			y+=4.6
		end
	end
end
local function atmosphere()
	local Lighting=game:GetService("Lighting")
	if Lighting:FindFirstChild("NinjaDuelAtmosphere") then return end
	-- Bright exam-day afternoon, as in the anime: clear sky, warm sun, soft haze.
	Lighting.ClockTime=14.6;Lighting.GeographicLatitude=30
	Lighting.Brightness=3;Lighting.EnvironmentDiffuseScale=.7;Lighting.EnvironmentSpecularScale=.3
	Lighting.Ambient=rgb(104,104,104);Lighting.OutdoorAmbient=rgb(150,146,138)
	pcall(function() Lighting.Technology=Enum.Technology.ShadowMap end)
	local atmo=Instance.new("Atmosphere");atmo.Name="NinjaDuelAtmosphere";atmo.Density=.26;atmo.Offset=.1
	atmo.Color=rgb(214,222,226);atmo.Decay=rgb(140,150,160);atmo.Glare=.2;atmo.Haze=.9;atmo.Parent=Lighting
	local cc=Instance.new("ColorCorrectionEffect");cc.Name="NinjaDuelGrade";cc.Saturation=.14;cc.Contrast=.06;cc.Brightness=.02;cc.TintColor=rgb(255,250,242);cc.Parent=Lighting
	local bloom=Instance.new("BloomEffect");bloom.Name="NinjaDuelBloom";bloom.Intensity=.45;bloom.Size=24;bloom.Threshold=1.5;bloom.Parent=Lighting
	local rays=Instance.new("SunRaysEffect");rays.Name="NinjaDuelRays";rays.Intensity=.04;rays.Spread=.6;rays.Parent=Lighting
end
World.atmosphere=atmosphere
function World.arena(parent, origin)
	local folder = Instance.new("Folder"); folder.Name = "Courtyard"; folder.Parent = parent
	local decor=Instance.new("Folder");decor.Name="Decor";decor.Parent=folder
	local C=PALETTE
	local R=World.WALL_RADIUS
	local height=62
	-- Field: grass with a broad packed-earth centre and worn patches.
	part(folder,"Training floor",Vector3.new(460,2,460),CFrame.new(origin-Vector3.new(0,1,0)),C.grass,Enum.Material.Grass)
	disc(decor,"Earth",64,.03,origin,C.earth,Enum.Material.Ground)
	for k=0,13 do
		local a=k/14*math.pi*2+.3
		local r=48+((k*37)%5)*5
		disc(decor,"Earth patch",14+((k*53)%4)*4,.035,origin+Vector3.new(math.sin(a)*r,0,math.cos(a)*r),if k%3==0 then C.earthDark else C.earth,Enum.Material.Ground)
	end
	-- Worn grass islands: clusters of overlapping small patches, never one
	-- perfect circle, so the field reads as trampled ground.
	for k=0,11 do
		local a=k/12*math.pi*2+1.1
		local r=22+((k*29)%4)*8
		local center=origin+Vector3.new(math.sin(a)*r,0,math.cos(a)*r)
		for j=0,4 do
			local b=j*1.7+k
			local offset=Vector3.new(math.sin(b)*(2+j*1.3),0,math.cos(b)*(1.5+j))
			disc(decor,"Grass tuft",1.6+((j*13+k)%4)*.9,.045,center+offset,if j%2==0 then C.grassDark else C.grass,Enum.Material.Grass)
		end
	end
	-- The tall panelled wall. Each segment is a wall-run surface.
	local segments=84
	local width=2*math.pi*(R+1)/segments+.3
	for k=0,segments-1 do
		local a=k/segments*math.pi*2
		local dir=Vector3.new(math.sin(a),0,math.cos(a))
		local at=origin+dir*(R+1)+Vector3.new(0,height/2,0)
		local look=CFrame.lookAt(at,origin+Vector3.new(0,height/2,0))
		local w=part(folder,"Boundary",Vector3.new(width,height,2),look,C.wall,Enum.Material.Concrete)
		w:SetAttribute("NinjaWall",true)
		deco(decor,"Seam",Vector3.new(.25,height,.1),look*CFrame.new(width/2,0,-1.02),C.wallSeam,Enum.Material.Concrete)
		deco(decor,"Band",Vector3.new(width,1.2,.1),look*CFrame.new(0,height/2-6,-1.02),C.wallBand,Enum.Material.Concrete)
		deco(decor,"Footing",Vector3.new(width,2.2,.6),look*CFrame.new(0,-height/2+1.1,-1.2),C.wallSeam,Enum.Material.Concrete)
		-- Brick outer face and the parapet in front of the first row of seats.
		deco(decor,"Outer face",Vector3.new(width,height,.6),look*CFrame.new(0,0,1.3),C.brick,Enum.Material.Brick)
		deco(decor,"Parapet",Vector3.new(width,1.2,1),look*CFrame.new(0,height/2+.6,-.4),C.brickDark,Enum.Material.Brick)
	end
	-- Tournament banners hang down the wall between the stands and the field.
	for k=0,15 do
		local a=k/16*math.pi*2+math.pi/16
		local dir=Vector3.new(math.sin(a),0,math.cos(a))
		local at=origin+dir*(R-.15)+Vector3.new(0,height-13,0)
		local look=CFrame.lookAt(at,origin+Vector3.new(0,height-13,0))
		local cloth=deco(decor,"Wall banner",Vector3.new(6.5,18,.12),look,if k%2==0 then rgb(170,40,36) else rgb(232,226,210),Enum.Material.Fabric)
		deco(decor,"Banner rod",Vector3.new(7.4,.35,.35),look*CFrame.new(0,9.1,0),rgb(70,52,36),Enum.Material.Wood)
		local gui=label(cloth,Enum.NormalId.Front,if k%3==0 then "火" elseif k%3==1 then "忍" else "試",if k%2==0 then rgb(232,226,210) else rgb(170,40,36))
		-- Match the cloth's proportions so the character is not squashed.
		gui.CanvasSize=Vector2.new(220,600)
	end
	-- Bushes along the foot of the wall.
	for k=0,95 do
		local a=k/96*math.pi*2+((k*17)%5)*.01
		local r=R-1.6-((k*29)%3)*.6
		local size=3.4+((k*41)%4)*.7
		deco(decor,"Bush",Vector3.one*size,CFrame.new(origin+Vector3.new(math.sin(a)*r,size*.32,math.cos(a)*r)),if k%3==0 then C.leafDark else C.leaf,Enum.Material.Grass,Enum.PartType.Ball)
	end
	-- Stands crowning the wall: rising tiers full of spectators.
	local seed=0
	local top=height
	for tier=1,4 do
		local radius=R+3+tier*3.4
		local steps=math.floor(radius*2*math.pi/7.2)
		for k=0,steps-1 do
			local a=k/steps*math.pi*2
			local at=origin+Vector3.new(math.sin(a)*radius,top+tier*2.1-.6,math.cos(a)*radius)
			local look=CFrame.lookAt(at,Vector3.new(origin.X,at.Y,origin.Z))
			deco(decor,"Stand",Vector3.new(6.8,tier*2.1+1,3.6),look*CFrame.new(0,-(tier*2.1+1)/2+.8,0),if tier%2==0 then C.wood else C.woodDark,Enum.Material.Wood)
			seed+=1
			if seed%4~=0 then
				local seat=look*CFrame.new(((seed*37)%5-2)*.9,.8,.4)
				spectator(decor,seat.Position,(origin-seat.Position)*Vector3.new(1,0,1),seed)
			end
		end
	end
	-- Pavilions on the stands; the Kage box is the large two-storey one (north).
	for k=0,13 do
		local a=k/14*math.pi*2+math.pi/14
		local at=origin+Vector3.new(math.sin(a)*(R+20),top+5,math.cos(a)*(R+20))
		pavilion(decor,CFrame.lookAt(at,Vector3.new(origin.X,at.Y,origin.Z)),18,10,8,1)
	end
	local kage=origin+Vector3.new(0,top+6,-(R+16))
	local kageCF=CFrame.lookAt(kage,Vector3.new(origin.X,kage.Y,origin.Z))
	pavilion(decor,kageCF,34,16,11,2)
	local box=deco(decor,"Kage box",Vector3.new(14,6,4),kageCF*CFrame.new(0,4,-9.6),C.trim,Enum.Material.Wood)
	for _,x in {-4,4} do spectator(decor,(kageCF*CFrame.new(x,1.4,-8.6)).Position,(origin-kage)*Vector3.new(1,0,1),if x<0 then 5 else 2) end
	local plaque=deco(decor,"Kage plaque",Vector3.new(4,4,.3),kageCF*CFrame.new(0,8.5,-9.9),C.plaster,Enum.Material.SmoothPlastic)
	label(plaque,Enum.NormalId.Front,"火",rgb(190,40,36))
	box.Transparency=0
	-- Participants' balcony on the east wall, and the arena gate to the south.
	local east=CFrame.lookAt(origin+Vector3.new(R-1.2,32,0),origin+Vector3.new(0,32,0))
	deco(decor,"Participants balcony",Vector3.new(16,1,4),east,C.woodDark,Enum.Material.Wood)
	deco(decor,"Balcony rail",Vector3.new(16,1.6,.3),east*CFrame.new(0,1.3,-1.9),C.wood,Enum.Material.Wood)
	for k=-3,3 do spectator(decor,(east*CFrame.new(k*2,.5,.2)).Position,-east.LookVector*-1,k+20) end
	local south=CFrame.lookAt(origin+Vector3.new(0,8,R-.05),origin+Vector3.new(0,8,0))
	-- The competitors' gate: two heavy wooden doors in a dark frame.
	deco(decor,"Gate",Vector3.new(18,16,.2),south*CFrame.new(0,0,.15),rgb(30,28,26),Enum.Material.SmoothPlastic)
	for _,x in {-4.4,4.4} do
		local door=south*CFrame.new(x,-.2,-.1)
		deco(decor,"Gate door",Vector3.new(8.4,15.4,.5),door,rgb(104,72,46),Enum.Material.WoodPlanks)
		for _,y in {-5,0,5} do deco(decor,"Gate band",Vector3.new(8.4,.4,.08),door*CFrame.new(0,y,-.29),rgb(52,50,50),Enum.Material.Metal) end
		deco(decor,"Gate ring",Vector3.new(.7,.7,.1),door*CFrame.new(if x<0 then 3.4 else -3.4,0,-.33),rgb(150,120,60),Enum.Material.Metal,Enum.PartType.Cylinder)
	end
	deco(decor,"Gate lintel",Vector3.new(21,2,.8),south*CFrame.new(0,8.6,-.2),C.trim,Enum.Material.Wood)
	for _,x in {-10,10} do deco(decor,"Gate post",Vector3.new(1.6,16,.8),south*CFrame.new(x,0,-.2),C.trim,Enum.Material.Wood) end
	-- Field trees: line of sight and something to fight around, as in the finals.
	for _,spot in {{.55,80,30,8.5},{1.6,74,26,7.5},{2.4,78,28,8},{3.3,70,24,7},{3.9,82,32,9},{5.3,76,28,8},{6.0,64,22,6.5}} do
		tree(folder,origin+Vector3.new(math.sin(spot[1])*spot[2],0,math.cos(spot[1])*spot[2]),spot[3],spot[4])
	end
	-- Weathered boulders for low cover (they stop blades and fire), spread so
	-- every approach has something to run around.
	for _,spot in {{1.5,30,1},{4.6,26,1},{.2,52,1.4},{2.9,48,1.25},{3.6,40,.9},{5.7,46,1.3},{1.05,62,1.1}} do
		local at=origin+Vector3.new(math.sin(spot[1])*spot[2],2*spot[3],math.cos(spot[1])*spot[2])
		local k=spot[3]
		part(folder,"Cover",Vector3.new(7,4,4)*k,CFrame.new(at)*CFrame.Angles(0,spot[1],0),rgb(128,124,114),Enum.Material.Slate)
		deco(decor,"Rock cap",Vector3.new(5,2.6,3.4)*k,CFrame.new(at+Vector3.new(-.5,2.2,0)*k)*CFrame.Angles(0,spot[1]+.3,math.rad(8)),rgb(140,136,124),Enum.Material.Slate)
		deco(decor,"Rock chip",Vector3.new(2.2,1.4,1.8)*k,CFrame.new(at+Vector3.new(3.6,-1.3,1.6)*k)*CFrame.Angles(0,spot[1]*2,math.rad(14)),rgb(118,114,106),Enum.Material.Slate)
	end
	-- The forest of Konoha around the stadium, seen over the stands.
	for k=0,47 do
		local a=k/48*math.pi*2+.07
		local r=R+42+((k*53)%5)*6
		local at=origin+Vector3.new(math.sin(a)*r,0,math.cos(a)*r)
		local h=50+((k*31)%4)*7
		deco(decor,"Forest trunk",Vector3.new(3,h,3),CFrame.new(at+Vector3.new(0,h/2,0)),C.bark,Enum.Material.Wood)
		deco(decor,"Forest crown",Vector3.one*(26+((k*13)%4)*5),CFrame.new(at+Vector3.new(0,h,0)),if k%2==0 then C.leafDark else C.leaf,Enum.Material.Grass,Enum.PartType.Ball)
	end
	-- A few leaves drifting over the field.
	local sky=deco(decor,"Leaf source",Vector3.new(190,1,190),CFrame.new(origin+Vector3.new(0,64,0)),C.leaf,Enum.Material.SmoothPlastic)
	sky.Transparency=1
	local leaves=Instance.new("ParticleEmitter");leaves.Name="Leaves"
	leaves.Texture="rbxasset://textures/particles/sparkles_main.dds";leaves.Rate=7;leaves.Lifetime=NumberRange.new(9,13)
	leaves.Speed=NumberRange.new(2,4);leaves.EmissionDirection=Enum.NormalId.Bottom;leaves.SpreadAngle=Vector2.new(30,30)
	leaves.Color=ColorSequence.new(rgb(120,160,80));leaves.LightEmission=.1;leaves.Size=NumberSequence.new(.35)
	leaves.Rotation=NumberRange.new(0,360);leaves.RotSpeed=NumberRange.new(-90,90);leaves.Acceleration=Vector3.new(1.2,-.6,.4)
	leaves.Parent=sky
	atmosphere()
	return folder
end
local function fighterGroup()
	local physics=game:GetService("PhysicsService")
	pcall(function()
		if not physics:IsCollisionGroupRegistered("NinjaFighters") then physics:RegisterCollisionGroup("NinjaFighters") end
		physics:CollisionGroupSetCollidable("NinjaFighters","NinjaFighters",false)
	end)
end
function World.rig(parent, def, cf, name)
	fighterGroup()
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
	-- Fighters pass through each other physically; Combat keeps them apart.
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.CollisionGroup="NinjaFighters" end end
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
	-- Sharingan: a pupil and three tomoe on each red iris.
	for _,side in {-1,1} do
		wear(model,"Head","Pupil",Vector3.new(.045,.045,.02),CFrame.new(side*.3,.07,-.842),rgb(12,8,10))
		for k=0,2 do
			local a=math.rad(90+k*120)
			wear(model,"Head","Tomoe",Vector3.new(.032,.032,.02),CFrame.new(side*.3+math.cos(a)*.048,.07+math.sin(a)*.048,-.842),rgb(12,8,10))
		end
	end
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
-- Neji at the Chunin Exam (13): cream high-collared Hyuga top, dark shorts,
-- bandaged right arm and thigh, long hair tied at the end, Byakugan eyes.
local function dressNeji(model,def)
	local hair=rgb(52,36,30)
	local robe=rgb(232,226,212)
	local robeShade=rgb(204,196,182)
	local shorts=rgb(72,54,46)
	local bandage=rgb(240,238,230)
	local skin=Color3.fromRGB(table.unpack(def.Skin))
	local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
	face(model,rgb(198,192,232),hair)
	-- Byakugan: pale irises with no pupil; the veins show when it flares.
	for _,p in model:GetChildren() do
		if p.Name=="Eye" then p.Color=rgb(242,240,252) end
		if p.Name=="Iris" then p.Material=Enum.Material.Neon;p.Transparency=.2 end
	end
	for _,side in {-1,1} do
		for k=0,2 do
			local vein=wear(model,"Head","ByakuganVein",Vector3.new(.035,.2,.02),CFrame.new(side*(.52+k*.06),.08+(k-1)*.07,-.79)*A(0,0,R(side*(30-k*30))),rgb(150,138,196))
			if vein then vein.Transparency=1 end
		end
	end
	hairCap(model,hair)
	for _,side in {-1,1} do
		wear(model,"Head","Bang",Vector3.new(.22,1.32,.4),CFrame.new(side*.74,-.24,-.44)*A(R(2),0,R(side*2)),hair)
		wear(model,"Head","SideHair",Vector3.new(.18,1.25,.95),CFrame.new(side*.8,-.14,.22),hair)
	end
	-- Centre parting: two smooth panels over the forehead, no spikes.
	for _,x in {-.36,.36} do
		wear(model,"Head","Fringe",Vector3.new(.62,.3,.16),CFrame.new(x,.5,-.7)*A(R(8),0,R(if x>0 then -10 else 10)),hair)
	end
	wear(model,"Head","BackHair",Vector3.new(1.66,1.45,.3),CFrame.new(0,-.14,.72),hair)
	wear(model,"UpperTorso","LongHair",Vector3.new(.72,1.5,.22),CFrame.new(0,.32,.62),hair)
	wear(model,"UpperTorso","HairTie",Vector3.new(.5,.12,.26),CFrame.new(0,-.38,.63),rgb(240,236,226))
	wear(model,"UpperTorso","HairTip",Vector3.new(.4,.48,.2),CFrame.new(0,-.68,.62),hair)
	headband(model,false)
	for _,name in {"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm"} do
		local part=model:FindFirstChild(name);if part then part.Color=robe end
	end
	wear(model,"UpperTorso","HighCollar",Vector3.new(1.42,.5,1.1),CFrame.new(0,.86,.04),robe)
	wear(model,"UpperTorso","Overlap",Vector3.new(.08,1.3,.04),CFrame.new(-.32,-.05,-.53)*A(0,0,R(-10)),robeShade)
	wear(model,"LowerTorso","WaistTie",Vector3.new(2.06,.26,1.06),CFrame.new(0,.3,0),robeShade)
	for _,side in {"Left","Right"} do
		local legTop=model:FindFirstChild(side.."UpperLeg");if legTop then legTop.Color=shorts end
		local legLow=model:FindFirstChild(side.."LowerLeg");if legLow then legLow.Color=skin end
		wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.84,.5,.84),CFrame.new(0,-.2,0),rgb(48,52,70))
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=rgb(40,46,66) end
		wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),skin)
		wear(model,side.."UpperArm","Sleeve",Vector3.new(.88,.36,.88),CFrame.new(0,-.2,0),robe)
	end
	local leftArm=model:FindFirstChild("LeftLowerArm");if leftArm then leftArm.Color=skin end
	local rightArm=model:FindFirstChild("RightLowerArm");if rightArm then rightArm.Color=bandage end
	for k=0,2 do wear(model,"RightLowerArm","BandageLine",Vector3.new(.84,.04,.84),CFrame.new(0,.25-k*.25,0)*A(0,0,R(8)),rgb(212,208,198)) end
	wear(model,"RightUpperLeg","ThighBandage",Vector3.new(.88,.5,.88),CFrame.new(0,0,0),bandage)
	wear(model,"RightUpperLeg","Holster",Vector3.new(.24,.5,.5),CFrame.new(.5,-.05,0),rgb(48,52,70))
end
-- Sasuke at the Chunin Exam (12): dark blue high-collared shirt with the
-- Uchiha fan on the back, light shorts, white arm warmers, the Leaf headband,
-- black hair swept back into spikes, a two-tomoe Sharingan. The cursed seal
-- marks are there but hidden until he awakens it.
local function dressSasuke(model,def)
	local hair=rgb(24,26,40)
	local hairShade=rgb(36,40,62)
	local shirt=rgb(34,40,72)
	local shorts=rgb(222,216,204)
	local warmer=rgb(236,236,232)
	local skin=Color3.fromRGB(table.unpack(def.Skin))
	local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
	face(model,rgb(200,20,30),hair)
	for _,p in model:GetChildren() do if p.Name=="Iris" then p.Material=Enum.Material.Neon end end
	for _,side in {-1,1} do
		wear(model,"Head","Pupil",Vector3.new(.045,.045,.02),CFrame.new(side*.3,.07,-.842),rgb(12,8,10))
		for k=0,1 do
			local a=math.rad(90+k*180)
			wear(model,"Head","Tomoe",Vector3.new(.034,.034,.02),CFrame.new(side*.3+math.cos(a)*.05,.07+math.sin(a)*.05,-.842),rgb(12,8,10))
		end
	end
	hairCap(model,hair)
	-- Swept back: long spikes pointing back and up behind the crown, two long
	-- bangs framing the face, a short fringe over the headband.
	local back={
		{Vector3.new(0,.62,.5),Vector3.new(0,.55,1),1.05,.62,.4},
		{Vector3.new(-.45,.5,.5),Vector3.new(-.45,.5,1),.95,.52,.36},
		{Vector3.new(.45,.5,.5),Vector3.new(.45,.5,1),.95,.52,.36},
		{Vector3.new(0,.25,.66),Vector3.new(0,.25,1),.9,.6,.38},
		{Vector3.new(-.5,.12,.6),Vector3.new(-.55,.15,1),.8,.46,.32},
		{Vector3.new(.5,.12,.6),Vector3.new(.55,.15,1),.8,.46,.32},
		{Vector3.new(0,.8,.2),Vector3.new(0,.9,.7),.7,.5,.32},
		{Vector3.new(-.3,-.1,.68),Vector3.new(-.2,-.2,1),.7,.44,.3},
		{Vector3.new(.3,-.1,.68),Vector3.new(.2,-.2,1),.7,.44,.3},
	}
	for index,s in back do spike(model,s[1],s[2],s[3],s[4],s[5],if index%2==0 then hairShade else hair) end
	for _,x in {-.34,0,.34} do spike(model,Vector3.new(x,.66,-.55),Vector3.new(x*.3,-.8,-.5),.46,.4,.22,hair) end
	for _,side in {-1,1} do
		wear(model,"Head","Bang",Vector3.new(.2,1.2,.36),CFrame.new(side*.78,-.2,-.44)*A(R(2),0,R(side*6)),hair)
		wear(model,"Head","SideHair",Vector3.new(.16,.85,.85),CFrame.new(side*.8,.05,.28),hair)
	end
	headband(model,false)
	-- The cursed seal (hidden): three black flame marks on the left of the neck.
	for k=0,2 do
		local mark=wear(model,"Head","CurseMark",Vector3.new(.05,.22,.14),CFrame.new(-.78,-.42+k*.18,.08-k*.12)*A(R(20*k),0,R(10)),rgb(12,10,14))
		if mark then mark.Transparency=1 end
	end
	for _,name in {"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm"} do
		local part=model:FindFirstChild(name);if part then part.Color=shirt end
	end
	wear(model,"UpperTorso","HighCollar",Vector3.new(1.5,.62,1.16),CFrame.new(0,.86,.04),shirt)
	crest(model,"UpperTorso",CFrame.new(0,.1,.53)*A(0,R(180),0),1.25)
	wear(model,"LowerTorso","Belt",Vector3.new(2.06,.22,1.06),CFrame.new(0,.3,0),rgb(30,30,36))
	for _,side in {"Left","Right"} do
		local armLow=model:FindFirstChild(side.."LowerArm");if armLow then armLow.Color=warmer end
		wear(model,side.."UpperArm","Sleeve",Vector3.new(.86,.42,.86),CFrame.new(0,.3,0),shirt)
		local legTop=model:FindFirstChild(side.."UpperLeg");if legTop then legTop.Color=shorts end
		local legLow=model:FindFirstChild(side.."LowerLeg");if legLow then legLow.Color=skin end
		wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.84,.42,.84),CFrame.new(0,-.28,0),rgb(40,46,70))
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=rgb(36,40,62) end
		wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),skin)
	end
	wear(model,"RightUpperLeg","ThighWrap",Vector3.new(.9,.38,.9),CFrame.new(0,-.1,0),warmer)
	wear(model,"RightUpperLeg","Holster",Vector3.new(.24,.5,.5),CFrame.new(.5,-.1,0),rgb(40,46,70))
	wear(model,"LowerTorso","ToolPouch",Vector3.new(.66,.4,.3),CFrame.new(0,.1,.62),rgb(70,64,58))
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
	if def.Name=="Minato" then dressMinato(model,def) elseif def.Name=="Itachi" then dressItachi(model,def) elseif def.Name=="Neji" then dressNeji(model,def)
	elseif def.Name=="Sasuke" then dressSasuke(model,def) end
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
