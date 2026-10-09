local World = {}
local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
World.part = part
function World.arena(parent, origin)
	local folder = Instance.new("Folder"); folder.Name = "Courtyard"; folder.Parent = parent
	local stone, dark = Color3.fromRGB(116, 132, 135), Color3.fromRGB(42, 57, 63)
	part(folder, "Training floor", Vector3.new(96, 2, 96), CFrame.new(origin - Vector3.new(0, 1, 0)), stone, Enum.Material.Slate)
	for _, x in { -1, 1 } do
		part(folder, "Boundary", Vector3.new(2, 12, 98), CFrame.new(origin + Vector3.new(x*49, 5, 0)), dark, Enum.Material.Concrete)
		part(folder, "Boundary", Vector3.new(98, 12, 2), CFrame.new(origin + Vector3.new(0, 5, x*49)), dark, Enum.Material.Concrete)
		for _, z in { -1, 1 } do
			local at = origin + Vector3.new(x*37, 0, z*37)
			part(folder, "Pillar", Vector3.new(3, 14, 3), CFrame.new(at + Vector3.new(0, 7, 0)), dark)
			part(folder, "Lantern", Vector3.new(4, 1, 4), CFrame.new(at + Vector3.new(0, 12, 0)), Color3.fromRGB(233, 198, 130), Enum.Material.Neon)
		end
	end
	for _, z in { -22, 22 } do
		part(folder, "Cover", Vector3.new(8, 4, 3), CFrame.new(origin + Vector3.new(18, 2, z)), dark, Enum.Material.Slate)
	end
	for i = -3, 3 do
		local stripe = part(folder, "Inlay", Vector3.new(0.09, 0.02, 82), CFrame.new(origin + Vector3.new(i*12, 0.02, 0)), Color3.fromRGB(147, 161, 156))
		stripe.CanCollide = false; stripe.CanQuery = false
	end
	local ring = part(folder, "Duel circle", Vector3.new(0.03, 24, 24), CFrame.new(origin + Vector3.new(0, 0.04, 0))*CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(157,175,165))
	ring.Shape = Enum.PartType.Cylinder; ring.CanCollide = false; ring.CanQuery = false
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
	model.PrimaryPart=root; root:SetNetworkOwner(nil)
	return model,hum,root,joints
end
local function set(joints,name,base,angles,alpha)
	local joint=joints[name]
	if joint then joint.C0=joint.C0:Lerp(CFrame.new(base)*CFrame.Angles(angles.X,angles.Y,angles.Z),alpha) end
end
function World.pose(a,now,dt)
	local j=a.joints
	local speed=a.locomotion.Magnitude
	local moving=speed>2
	local phase=now*(if a.sprinting then 17 else 12)
	local swing=if moving then math.sin(phase)*math.min(0.95,speed/40) else math.sin(now*2)*0.03
	local flank=if a.locked then a.move:Dot(a.root.CFrame.RightVector) else 0
	local retreat=if a.locked then -a.move:Dot(a.root.CFrame.LookVector) else 0
	local lean=if moving then math.clamp(speed/90,0,0.37) else 0
	local leftArm,rightArm=swing,-swing
	local leftLeg,rightLeg=-swing,swing
	local waistTwist=math.sin(phase)*0.06
	if a.state=="Guarding" then leftArm,rightArm=-1.35,-1.35; lean=0.08 end
	if a.state=="Dodging" or a.state=="Pursuit" then leftArm,rightArm=-0.7,0.55; leftLeg,rightLeg=0.5,-0.5; lean=0.55 end
	if a.state=="Stunned" then leftArm,rightArm=0.7,0.7; lean=-0.25 end
	if a.state=="TechniqueChannel" then leftArm,rightArm=-1.55,-1.55; lean=0 end
	if a.state=="TechniqueActive" then leftArm,rightArm=-0.8,-1.9; lean=0.18 end
	if a.state=="Startup" or a.state=="Active" then
		local beat=a.combo or 1
		local attackPose={-1.5,-0.5,-1.1,-2.1}
		rightArm=attackPose[beat] or -1.5
		leftArm=if beat==2 then -1.5 elseif beat==4 then 0.85 else 0.15
		waistTwist=if beat%2==0 then -0.27 else 0.22
		lean=0.3
		if beat==2 then rightLeg=-0.8 end
		if beat==4 then leftLeg=-1.2 end
	end
	if a.airborne and a.state~="Startup" and a.state~="Active" and a.state~="Dodging" then
		if now<(a.takeoffUntil or 0) then leftArm,rightArm=-0.55,-0.55; leftLeg,rightLeg=0.4,0.4
		else leftArm,rightArm=-0.55,-0.8; leftLeg,rightLeg=0.5,-0.5 end
		lean=0.12
	end
	if not a.airborne and now<(a.landUntil or 0) then
		leftLeg,rightLeg=-0.35,-0.35; lean=0.32
	end
	if a.state=="Defeated" then leftArm,rightArm=1.4,1.4; leftLeg,rightLeg=0.8,0.8; lean=0.65 end
	local alpha=1-math.exp(-math.min(dt,0.1)*18)
	set(j,"Waist",Vector3.new(0,0.65,0),Vector3.new(lean,waistTwist+flank*0.12,0),alpha)
	set(j,"Neck",Vector3.new(0,0.9,0),Vector3.new(-lean*0.45,-waistTwist*0.4,0),alpha)
	for _,side in {-1,1} do
		local prefix=if side==-1 then "Left" else "Right"
		local arm=if side==-1 then leftArm else rightArm
		local leg=if side==-1 then leftLeg else rightLeg
		set(j,prefix.."Shoulder",Vector3.new(side*1.05,0.45,0),Vector3.new(arm,0,side*0.12),alpha)
		set(j,prefix.."Elbow",Vector3.new(0,-0.55,0),Vector3.new(if a.state=="Guarding" then -0.55 else -0.16,0,0),alpha)
		set(j,prefix.."Hip",Vector3.new(side*0.5,-0.55,0),Vector3.new(leg+retreat*0.1,0,0),alpha)
		set(j,prefix.."Knee",Vector3.new(0,-0.55,0),Vector3.new(math.max(0,-leg)*0.35,0,0),alpha)
	end
end
return World
