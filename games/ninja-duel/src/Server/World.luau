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
function World.arena(parent, origin)
	local folder = Instance.new("Folder"); folder.Name = "Courtyard"; folder.Parent = parent
	local stone, dark = Color3.fromRGB(151, 145, 122), Color3.fromRGB(56, 65, 57)
	part(folder, "Training floor", Vector3.new(160, 2, 160), CFrame.new(origin - Vector3.new(0, 1, 0)), stone, Enum.Material.Slate)
	for _, x in { -1, 1 } do
		part(folder, "Boundary", Vector3.new(2, 25, 162), CFrame.new(origin + Vector3.new(x*81, 11.5, 0)), dark, Enum.Material.Concrete)
		part(folder, "Boundary", Vector3.new(162, 25, 2), CFrame.new(origin + Vector3.new(0, 11.5, x*81)), dark, Enum.Material.Concrete)
		local wall=part(folder,"Ninja wall",Vector3.new(3,23,26),CFrame.new(origin+Vector3.new(x*28,11.5,0)),dark,Enum.Material.Slate)
		wall:SetAttribute("NinjaWall",true)
		local ledge=part(folder,"Wall ledge",Vector3.new(10,1,29),CFrame.new(origin+Vector3.new(x*28,23,0)),stone,Enum.Material.Concrete)
		ledge.CanQuery=true
		for _, z in { -1, 1 } do
			local at = origin + Vector3.new(x*58, 0, z*58)
			part(folder, "Pillar", Vector3.new(3, 14, 3), CFrame.new(at + Vector3.new(0, 7, 0)), dark)
			part(folder, "Lantern", Vector3.new(4, 1, 4), CFrame.new(at + Vector3.new(0, 12, 0)), Color3.fromRGB(233, 198, 130), Enum.Material.Neon)
		end
	end
	for _, z in { -40, 40 } do
		part(folder, "Cover", Vector3.new(8, 4, 3), CFrame.new(origin + Vector3.new(18, 2, z)), dark, Enum.Material.Slate)
		part(folder,"Step platform",Vector3.new(14,1.2,14),CFrame.new(origin+Vector3.new(-17,7,z)),stone,Enum.Material.Concrete)
	end
	for i = -3, 3 do
		local stripe = part(folder, "Inlay", Vector3.new(0.09, 0.02, 146), CFrame.new(origin + Vector3.new(i*12, 0.02, 0)), Color3.fromRGB(147, 161, 156))
		stripe.CanCollide = false; stripe.CanQuery = false
	end
	for _,side in {-1,1} do
		part(folder,"Training beam",Vector3.new(1.2,1.2,28),CFrame.new(origin+Vector3.new(side*28,20,0)),Color3.fromRGB(109,73,46),Enum.Material.Wood)
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
-- Imported combat clips and Roblox catalogue movement tracks play on the server.
function World.pose(a,now,dt)
 Animation.step(a,now)
end
return World
