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
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function cyl(p)
	if p then p.Shape=Enum.PartType.Cylinder end
	return p
end
local A=CFrame.Angles
local R=math.rad
local function headband(model,slashed)
	wear(model,"Head","Headband",Vector3.new(1.6,.24,1.6),CFrame.new(0,.36,0),rgb(28,36,58),Enum.Material.SmoothPlastic)
	wear(model,"Head","HeadbandPlate",Vector3.new(.86,.3,.06),CFrame.new(0,.36,-.81),rgb(176,184,194),Enum.Material.Metal)
	-- The Leaf symbol, reduced to a readable spiral mark.
	wear(model,"Head","LeafMark",Vector3.new(.3,.14,.02),CFrame.new(0,.38,-.85),rgb(70,78,90),Enum.Material.Metal)
	if slashed then wear(model,"Head","Slash",Vector3.new(.92,.04,.03),CFrame.new(0,.36,-.86)*A(0,0,R(-8)),rgb(30,30,34),Enum.Material.Metal) end
	for _,side in {-1,1} do
		wear(model,"Head","HeadbandTail",Vector3.new(.16,.55,.08),CFrame.new(side*.25,.18,.84)*A(R(18),0,R(side*10)),rgb(28,36,58),Enum.Material.SmoothPlastic)
	end
end
local function face(model,eye,brow)
	local eyes=model:FindFirstChild("Eyes")
	if eyes then eyes.Transparency=1 end
	for _,side in {-1,1} do
		wear(model,"Head","Eye",Vector3.new(.3,.17,.04),CFrame.new(side*.3,.08,-.76),rgb(245,245,240))
		wear(model,"Head","Iris",Vector3.new(.15,.15,.03),CFrame.new(side*.3,.07,-.785),eye,Enum.Material.SmoothPlastic)
		wear(model,"Head","Brow",Vector3.new(.34,.06,.04),CFrame.new(side*.3,.27,-.765)*A(0,0,R(side*-8)),brow)
	end
	wear(model,"Head","Mouth",Vector3.new(.28,.04,.03),CFrame.new(0,-.36,-.765),rgb(120,70,64))
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
local function dressMinato(model,def)
	local hair=rgb(248,214,96)
	local hairShade=rgb(226,180,58)
	local navy=rgb(30,44,78)
	local vest=rgb(86,104,62)
	local white=rgb(240,240,236)
	local flame=rgb(226,82,36)
	local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
	face(model,rgb(60,120,200),hairShade)
	hairCap(model,hair)
	-- Spiky mane swept back from the crown, side flicks, and two long bangs.
	local spikes={
		{Vector3.new(0,.78,.25),Vector3.new(0,.35,1),1.05,.62,.4},
		{Vector3.new(-.45,.66,.28),Vector3.new(-.45,.3,1),.95,.5,.36},
		{Vector3.new(.45,.66,.28),Vector3.new(.45,.3,1),.95,.5,.36},
		{Vector3.new(0,.45,.62),Vector3.new(0,-.1,1),.9,.7,.4},
		{Vector3.new(-.5,.3,.58),Vector3.new(-.5,-.35,.9),.8,.5,.34},
		{Vector3.new(.5,.3,.58),Vector3.new(.5,-.35,.9),.8,.5,.34},
		{Vector3.new(0,-.15,.68),Vector3.new(0,-.7,.75),.7,.62,.32},
		{Vector3.new(-.72,.5,.05),Vector3.new(-1,.45,.35),.6,.42,.3},
		{Vector3.new(.72,.5,.05),Vector3.new(1,.45,.35),.6,.42,.3},
		{Vector3.new(-.25,.82,-.2),Vector3.new(-.3,1,-.2),.5,.4,.3},
		{Vector3.new(.25,.82,-.2),Vector3.new(.3,1,-.2),.5,.4,.3},
	}
	for index,s in spikes do spike(model,s[1],s[2],s[3],s[4],s[5],if index%2==0 then hairShade else hair) end
	for _,x in {-.38,0,.38} do spike(model,Vector3.new(x,.62,-.55),Vector3.new(x*.4,-.75,-.55),.55,.42,.24,hair) end
	for _,side in {-1,1} do
		wear(model,"Head","Bang",Vector3.new(.2,1.15,.34),CFrame.new(side*.78,-.12,-.42)*A(R(4),0,R(side*4)),hair,Enum.Material.SmoothPlastic)
		wear(model,"Head","SideHair",Vector3.new(.16,.85,.8),CFrame.new(side*.79,.05,.3),hair)
	end
	wear(model,"Head","BackHair",Vector3.new(1.6,1.05,.26),CFrame.new(0,.05,.74),hair)
	headband(model,false)
	-- Jonin flak vest over the navy uniform, scroll pouches, high collar.
	local upper=model:FindFirstChild("UpperTorso");if upper then upper.Color=navy end
	local lower=model:FindFirstChild("LowerTorso");if lower then lower.Color=navy end
	wear(model,"UpperTorso","FlakVest",Vector3.new(2.1,1.32,1.12),CFrame.new(0,-.02,0),vest,Enum.Material.SmoothPlastic)
	wear(model,"UpperTorso","VestCollar",Vector3.new(1.3,.32,1.05),CFrame.new(0,.78,.02),vest,Enum.Material.SmoothPlastic)
	for _,x in {-.62,-.2,.2,.62} do
		wear(model,"UpperTorso","ScrollPouch",Vector3.new(.34,.5,.16),CFrame.new(x,-.12,-.62),rgb(74,90,52),Enum.Material.SmoothPlastic)
	end
	wear(model,"UpperTorso","Spiral",Vector3.new(.3,.3,.05),CFrame.new(0,.1,.6),rgb(170,40,30),Enum.Material.SmoothPlastic)
	-- White haori: shoulders and sleeves on the torso and arms, skirts on the
	-- hips so they follow the legs, flame hem.
	-- The haori is open at the front: shoulders, back and side panels only.
	wear(model,"UpperTorso","HaoriShoulders",Vector3.new(2.26,.3,1.2),CFrame.new(0,.62,.03),white)
	for _,side in {-1,1} do wear(model,"UpperTorso","HaoriSide",Vector3.new(.1,1.38,1.2),CFrame.new(side*1.1,.02,.03),white) end
	local back=wear(model,"UpperTorso","HaoriBack",Vector3.new(2.26,1.4,.08),CFrame.new(0,0,.62),white,Enum.Material.SmoothPlastic)
	if back then
		local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(220,140);gui.LightInfluence=1;gui.Parent=back
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text="四代目\n火影"
		label.TextColor3=rgb(200,40,30);label.Font=Enum.Font.GothamBlack;label.TextScaled=true;label.Parent=gui
	end
	-- Front opening: the haori hangs as two panels either side of the vest.
	for _,side in {-1,1} do
		wear(model,"UpperTorso","HaoriFront",Vector3.new(.5,1.4,.08),CFrame.new(side*.86,0,-.62),white,Enum.Material.SmoothPlastic)
		wear(model,"LeftUpperArm","Sleeve",Vector3.new(.98,.9,.98),CFrame.new(0,.14,0),white,Enum.Material.SmoothPlastic)
		wear(model,"RightUpperArm","Sleeve",Vector3.new(.98,.9,.98),CFrame.new(0,.14,0),white,Enum.Material.SmoothPlastic)
	end
	local skirts={
		{"HaoriSkirtBack",Vector3.new(2.3,1.9,.08),CFrame.new(0,-.85,.58)*A(R(-6),0,0)},
		{"HaoriSkirtLeft",Vector3.new(.08,1.9,1.1),CFrame.new(-1.08,-.85,0)*A(0,0,R(-6))},
		{"HaoriSkirtRight",Vector3.new(.08,1.9,1.1),CFrame.new(1.08,-.85,0)*A(0,0,R(6))},
		{"HaoriSkirtFrontL",Vector3.new(.55,1.9,.08),CFrame.new(-.84,-.85,-.58)*A(R(6),0,0)},
		{"HaoriSkirtFrontR",Vector3.new(.55,1.9,.08),CFrame.new(.84,-.85,-.58)*A(R(6),0,0)},
	}
	for _,s in skirts do
		local panel=wear(model,"LowerTorso",s[1],s[2],s[3],white,Enum.Material.SmoothPlastic)
		if panel then
			-- Flame hem: a band along the bottom edge crowned by a row of
			-- diamond tongues, so the hem reads as fire from any side.
			local spansX=s[2].X>s[2].Z
			local width=if spansX then s[2].X else s[2].Z
			local count=math.max(1,math.floor(width/.38))
			local bottom=-s[2].Y/2
			for k=1,count do
				local along=-width/2+(k-.5)*width/count
				local lift=bottom+.4+((k*37)%3)*.07
				local offset=if spansX then CFrame.new(along,lift,0)*A(0,0,R(45)) else CFrame.new(0,lift,along)*A(R(45),0,0)
				wear(model,"LowerTorso","Flame",if spansX then Vector3.new(.3,.3,s[2].Z+.02) else Vector3.new(s[2].X+.02,.3,.3),s[3]*offset,flame)
			end
			wear(model,"LowerTorso","FlameBand",Vector3.new(s[2].X+.02,.3,s[2].Z+.02),s[3]*CFrame.new(0,bottom+.15,0),flame)
		end
	end
	-- Navy pants with white shin wraps; shinobi sandals.
	for _,side in {"Left","Right"} do
		local legLow=model:FindFirstChild(side.."LowerLeg");if legLow then legLow.Color=navy end
		local legTop=model:FindFirstChild(side.."UpperLeg");if legTop then legTop.Color=navy end
		wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.84,.62,.84),CFrame.new(0,-.12,0),rgb(214,214,206),Enum.Material.SmoothPlastic)
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=rgb(26,32,52) end
		wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),Color3.fromRGB(table.unpack(def.Skin)))
		local armLow=model:FindFirstChild(side.."LowerArm");if armLow then armLow.Color=navy end
	end
end
local function cloud(model,body,offset,scale)
	-- Akatsuki cloud: white outline behind three red lobes.
	for index,lobe in {{-.32,0,.38},{0,.08,.46},{.3,-.02,.36}} do
		wear(model,body,"CloudEdge",Vector3.new(.03,lobe[3]*2*scale+.08,lobe[3]*2*scale+.08),offset*CFrame.new(lobe[1]*scale,lobe[2]*scale,0)*A(0,R(90),0),rgb(236,236,236))
		wear(model,body,"Cloud",Vector3.new(.04,lobe[3]*2*scale,lobe[3]*2*scale),offset*CFrame.new(lobe[1]*scale,lobe[2]*scale,-.035)*A(0,R(90),0),rgb(196,26,36))
	end
	for _,p in model:GetChildren() do
		if (p.Name=="Cloud" or p.Name=="CloudEdge") and p:IsA("Part") and p.Shape~=Enum.PartType.Cylinder then p.Shape=Enum.PartType.Cylinder end
	end
end
local function dressItachi(model,def)
	local hair=rgb(22,22,28)
	local cloak=rgb(20,20,26)
	local cap=model:FindFirstChild("Hair");if cap then cap.Color=hair;cap.Transparency=1 end
	face(model,rgb(200,20,30),hair)
	hairCap(model,hair)
	for _,p in model:GetChildren() do if p.Name=="Iris" then p.Material=Enum.Material.Neon end end
	-- Long dark bangs framing the face, a crown, and the low tie at the nape.
	for _,side in {-1,1} do
		wear(model,"Head","Bang",Vector3.new(.24,1.35,.42),CFrame.new(side*.74,-.2,-.42)*A(R(3),0,R(side*3)),hair)
		wear(model,"Head","SideHair",Vector3.new(.18,1.1,.9),CFrame.new(side*.8,-.05,.25),hair)
	end
	for _,x in {-.42,-.12,.18,.45} do
		wear(model,"Head","Fringe",Vector3.new(.32,.46,.26),CFrame.new(x,.5,-.68)*A(R(196),0,0),hair,Enum.Material.SmoothPlastic,"WedgePart")
	end
	wear(model,"Head","BackHair",Vector3.new(1.62,1.25,.3),CFrame.new(0,-.05,.72),hair)
	local tail=wear(model,"Head","Ponytail",Vector3.new(1.1,.24,.24),CFrame.new(0,-.85,.86)*A(0,0,R(80))*A(0,R(10),0),hair)
	cyl(tail)
	headband(model,true)
	-- Akatsuki cloak: black shell, high collar, long skirt to the knees, wide
	-- sleeves, red clouds outlined in white.
	local upper=model:FindFirstChild("UpperTorso");if upper then upper.Color=cloak end
	local lower=model:FindFirstChild("LowerTorso");if lower then lower.Color=cloak end
	wear(model,"UpperTorso","Cloak",Vector3.new(2.22,1.44,1.18),CFrame.new(0,.02,0),cloak,Enum.Material.SmoothPlastic)
	wear(model,"UpperTorso","CollarBack",Vector3.new(1.6,.8,.14),CFrame.new(0,.98,.48),cloak,Enum.Material.SmoothPlastic)
	for _,side in {-1,1} do
		wear(model,"UpperTorso","Collar",Vector3.new(.14,.8,1.0),CFrame.new(side*.74,.98,.0)*A(0,R(side*-12),0),cloak,Enum.Material.SmoothPlastic)
		wear(model,"UpperTorso","CollarLining",Vector3.new(.06,.7,.86),CFrame.new(side*.66,.98,-.02)*A(0,R(side*-12),0),rgb(150,20,30),Enum.Material.SmoothPlastic)
	end
	local skirts={
		{"CloakBack",Vector3.new(2.34,2.5,.1),CFrame.new(0,-1.15,.6)*A(R(-5),0,0)},
		{"CloakLeft",Vector3.new(.1,2.5,1.16),CFrame.new(-1.1,-1.15,0)*A(0,0,R(-5))},
		{"CloakRight",Vector3.new(.1,2.5,1.16),CFrame.new(1.1,-1.15,0)*A(0,0,R(5))},
		{"CloakFrontL",Vector3.new(1.1,2.5,.1),CFrame.new(-.58,-1.15,-.6)*A(R(5),0,0)},
		{"CloakFrontR",Vector3.new(1.1,2.5,.1),CFrame.new(.58,-1.15,-.6)*A(R(5),0,0)},
	}
	for _,s in skirts do wear(model,"LowerTorso",s[1],s[2],s[3],cloak,Enum.Material.SmoothPlastic) end
	for _,side in {"Left","Right"} do
		wear(model,side.."UpperArm","Sleeve",Vector3.new(1.0,1.15,1.0),CFrame.new(0,0,0),cloak,Enum.Material.SmoothPlastic)
		wear(model,side.."LowerArm","Sleeve",Vector3.new(1.04,.95,1.04),CFrame.new(0,.05,0),cloak,Enum.Material.SmoothPlastic)
		local legLow=model:FindFirstChild(side.."LowerLeg");if legLow then legLow.Color=rgb(34,36,50) end
		local legTop=model:FindFirstChild(side.."UpperLeg");if legTop then legTop.Color=rgb(34,36,50) end
		wear(model,side.."LowerLeg","ShinWrap",Vector3.new(.84,.6,.84),CFrame.new(0,-.12,0),rgb(206,206,198),Enum.Material.SmoothPlastic)
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=rgb(28,28,36) end
		wear(model,side.."Foot","Toes",Vector3.new(.7,.16,.34),CFrame.new(0,.1,-.42),Color3.fromRGB(table.unpack(def.Skin)))
	end
	cloud(model,"UpperTorso",CFrame.new(-.55,.2,.6+.08)*A(0,R(180),0),.55)
	cloud(model,"LowerTorso",CFrame.new(.45,-.9,.66)*A(0,R(180),0),.65)
	cloud(model,"LowerTorso",CFrame.new(-.6,-1.55,-.66),.6)
	cloud(model,"UpperTorso",CFrame.new(.55,-.1,-.62),.5)
	cloud(model,"LeftUpperArm",CFrame.new(-.52,0,0)*A(0,R(90),0),.4)
end
local function soften(model)
	local head=model:FindFirstChild("Head")
	if head and not head:FindFirstChildOfClass("SpecialMesh") then
		local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Head;mesh.Scale=Vector3.new(1.18,1.2,1.18);mesh.Parent=head
	end
end
function World.dress(model,def)
	soften(model)
	if def.Name=="Minato" then dressMinato(model,def) elseif def.Name=="Itachi" then dressItachi(model,def) end
	for _,p in model:GetChildren() do
		if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CastShadow=true end
	end
end
-- Imported combat clips and Roblox catalogue movement tracks play on the server.
function World.pose(a,now,dt)
 Animation.step(a,now)
end
return World
