-- Looks of the 8 main fighters, final-beta pass (user 29/10 14:00-14:07:
-- "inspire-toi des tenues des versions jeunes", "les cheveux sont jamais très
-- bons", "bugs avec les bandeaux", "le masque de Kakashi ne va pas", "points
-- transparents au poignet", "Gaara est vraiment moche", "cartoon mais joli",
-- "il manque une expression faciale").
--
-- One body form for all of them (Looks.form): round limbs that overlap at the
-- joints (no see-through wrists or elbows), mitten hands that sink into the
-- forearm, a narrower kid's torso with the arms brought in, rounded shoes.
-- Head gear is built against the measured head (a rounded cylinder 0.915
-- studs in radius): bands and masks are rings just outside it, never boxes
-- whose corners cut through. Hair is a rounded base plus cone locks. The face
-- is drawn (Shared/Face) and carries expressions.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Face=require(Shared.Face)

local Looks={}
local A,R=CFrame.Angles,math.rad
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
-- A smooth cone, apex up, 1 x 1.3 x 1 studs at scale 1.
Looks.Cone="rbxassetid://1778999"
local CONE_W,CONE_H=1,1.3
local HEAD_R=Face.Radius

local ARMS={"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"}
local LEGS={"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}

local function mesh(p,kind,scale,offset)
	local m=Instance.new("SpecialMesh")
	m.MeshType=kind
	if scale then m.Scale=scale end
	if offset then m.Offset=offset end
	m.Parent=p
	return m
end
-- A costume piece welded onto a body part. opts: mesh ("Head" round tube,
-- "Sphere", "Brick"), scale, material, class ("Part" / "WedgePart"), shape.
local function piece(model,bodyName,name,size,offset,color,opts)
	local body=model:FindFirstChild(bodyName)
	if not body then return nil end
	opts=opts or {}
	local p=Instance.new(opts.class or "Part")
	p.Name=name;p.Size=size;p.CFrame=body.CFrame*offset;p.Color=color
	p.Material=opts.material or Enum.Material.SmoothPlastic
	p.Reflectance=opts.reflectance or 0
	p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=opts.shadow~=false
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	if opts.shape then p.Shape=opts.shape end
	if opts.mesh=="Head" then mesh(p,Enum.MeshType.Head,opts.scale)
	elseif opts.mesh=="Sphere" then mesh(p,Enum.MeshType.Sphere,opts.scale)
	elseif opts.mesh=="Brick" then mesh(p,Enum.MeshType.Brick,opts.scale) end
	if opts.transparency then p.Transparency=opts.transparency end
	p:SetAttribute("LookPiece",true)
	local weld=Instance.new("WeldConstraint");weld.Part0=body;weld.Part1=p;weld.Parent=p
	p.Parent=model
	return p
end
Looks.piece=piece
local function paint(model,names,color)
	for _,name in names do local part=model:FindFirstChild(name);if part then part.Color=color end end
end
-- A ring round a limb or the head: an exact cylinder of `dia` at height `y`.
-- (A Head mesh keeps a minimum thickness, about a quarter of its width: a
-- flat band drawn with one comes out twice too tall.)
local UPRIGHT=A(0,0,math.pi/2)
local function ring(model,body,name,y,height,dia,color,opts)
	opts=opts or {};opts.shape=Enum.PartType.Cylinder
	return piece(model,body,name,Vector3.new(height,dia,dia),CFrame.new(0,y,0)*UPRIGHT,color,opts)
end
-- A cone lock on the head: from `base` (head space) along `dir`, `len` long,
-- `w` x `d` thick at the root.
local function lock(model,name,base,dir,len,w,d,color,bodyName)
	local unit=dir.Unit
	local center=base+unit*len*.5
	local up=if math.abs(unit.Y)>.95 then Vector3.zAxis else Vector3.yAxis
	local cf=CFrame.lookAt(center,center+unit,up)*A(-math.pi/2,0,0)
	local p=piece(model,bodyName or "Head",name,Vector3.new(.2,.2,.2),cf,color)
	if p then
		local m=Instance.new("SpecialMesh");m.MeshType=Enum.MeshType.FileMesh;m.MeshId=Looks.Cone
		m.Scale=Vector3.new(w/CONE_W,len/CONE_H,(d or w)/CONE_W);m.Parent=p
	end
	return p
end
Looks.lock=lock
-- A soft rounded mass (ellipsoid) on any body part.
local function blob(model,body,name,size,cf,color,opts)
	opts=opts or {};opts.mesh="Sphere"
	return piece(model,body,name,size,cf,color,opts)
end

-- Body form: shared by the eight. Moves the arms in, rounds every limb.
function Looks.form(model,skin)
	local upper=model:FindFirstChild("UpperTorso")
	local lower=model:FindFirstChild("LowerTorso")
	if upper then mesh(upper,Enum.MeshType.Brick,Vector3.new(.84,1,.9)) end
	if lower then mesh(lower,Enum.MeshType.Brick,Vector3.new(.82,1,.88)) end
	for _,side in {"Left","Right"} do
		local s=if side=="Left" then -1 else 1
		local shoulder=upper and upper:FindFirstChild(side.."Shoulder")
		local arm=model:FindFirstChild(side.."UpperArm")
		if shoulder and arm and upper then
			-- The arm moves in with the narrower torso: shift the whole chain.
			local c0=shoulder.C0
			local target=CFrame.new(s*.84,c0.Position.Y,c0.Position.Z)
			local delta=upper.CFrame*target*shoulder.C1:Inverse()*arm.CFrame:Inverse()
			shoulder.C0=target
			for _,name in {side.."UpperArm",side.."LowerArm",side.."Hand"} do
				local p=model:FindFirstChild(name);if p then p.CFrame=delta*p.CFrame end
			end
		end
		local ua=model:FindFirstChild(side.."UpperArm");if ua then mesh(ua,Enum.MeshType.Head,Vector3.new(.9,1.16,.9)) end
		local la=model:FindFirstChild(side.."LowerArm");if la then mesh(la,Enum.MeshType.Head,Vector3.new(.88,1.22,.88)) end
		local hand=model:FindFirstChild(side.."Hand")
		if hand then
			-- A mitten: an ellipsoid that sinks into the forearm, and a thumb.
			mesh(hand,Enum.MeshType.Sphere,Vector3.new(.88,1.6,.82),Vector3.new(0,.06,0))
			if skin then hand.Color=skin end
			blob(model,side.."Hand","Thumb",Vector3.new(.22,.36,.22),CFrame.new(-s*.28,.02,-.14)*A(0,0,R(-s*22)),skin or hand.Color)
		end
		local ul=model:FindFirstChild(side.."UpperLeg");if ul then mesh(ul,Enum.MeshType.Head,Vector3.new(.94,1.2,.94)) end
		local ll=model:FindFirstChild(side.."LowerLeg");if ll then mesh(ll,Enum.MeshType.Head,Vector3.new(.9,1.2,.9)) end
		local foot=model:FindFirstChild(side.."Foot")
		if foot then mesh(foot,Enum.MeshType.Sphere,Vector3.new(.92,1.05,1),Vector3.new(0,.02,-.04)) end
		-- A ball at the shoulder closes the joint whatever the arm does.
		if ua then blob(model,side.."UpperArm","ShoulderBall",Vector3.new(.76,.76,.76),CFrame.new(0,.36,0),ua.Color) end
	end
	-- The head (user 29/10 14:33: the ball was "beaucoup trop rond"): the
	-- classic rounded Head mesh, 1.8 across and 1.86 tall (Shared/Face.Head);
	-- a neck under it.
	local head=model:FindFirstChild("Head")
	local neck=upper and upper:FindFirstChild("Neck")
	if head and neck and neck:IsA("Motor6D") then
		-- The head sits a little higher, on a visible neck, so the round chin
		-- clears the shoulders and the collars.
		local target=CFrame.new(0,1.05,0)
		head.CFrame=upper.CFrame*target*neck.C1:Inverse()
		neck.C0=target
	end
	if head then
		local m=head:FindFirstChildOfClass("SpecialMesh") or mesh(head,Enum.MeshType.Head)
		m.MeshType=Enum.MeshType.Head
		m.Scale=Vector3.new(1.2,1.24,1.2)
		if skin then head.Color=skin end
		piece(model,"UpperTorso","NeckSkin",Vector3.new(.62,.6,.62),CFrame.new(0,.88,.02),skin or head.Color,{mesh="Head"})
	end
end
-- After the costume painted the limbs: the joint balls take their limb's colour.
local function settle(model)
	for _,p in model:GetChildren() do
		if p.Name=="ShoulderBall" then
			local weld=p:FindFirstChildOfClass("WeldConstraint")
			if weld and weld.Part0 then p.Color=weld.Part0.Color end
		end
	end
end

-- Sandals: dark shoe over the foot, the toes bare.
local function sandals(model,color,skin)
	for _,side in {"Left","Right"} do
		local foot=model:FindFirstChild(side.."Foot");if foot then foot.Color=color end
		blob(model,side.."Foot","Toes",Vector3.new(.62,.26,.36),CFrame.new(0,.06,-.42),skin)
		piece(model,side.."Foot","Sole",Vector3.new(.74,.08,1.1),CFrame.new(0,-.19,-.04),rgb(46,40,40),{mesh="Sphere"})
		ring(model,side.."LowerLeg","Strap",-.5,.14,.76,color)
	end
end

-- The forehead protector: a cloth ring just outside the head (and the hair
-- base), a curved metal plate in three facets, an emblem, two tails.
local function headband(model,cloth,opts)
	opts=opts or {}
	local y=opts.y or .42
	-- An elliptical band (a Cylinder mesh scales on both axes): it hugs the
	-- forehead and still wraps the hair at the back.
	local r=opts.radius or 1.08
	local z=opts.z or .15
	local band=piece(model,"Head","Headband",Vector3.new(.26,2.0,r*2),CFrame.new(0,y,z)*UPRIGHT,cloth)
	if band then mesh(band,Enum.MeshType.Cylinder) end
	local metal=rgb(188,196,208)
	local front=-(r-z)
	for k=-1,1 do
		local a=k*17
		local px=math.sin(R(a))*(r+.012)
		local pz=z-math.cos(R(a))*(r+.012)
		local plate=piece(model,"Head","HeadbandPlate",Vector3.new(if k==0 then .34 else .26,.3,.04),
			CFrame.new(px,y,pz)*A(0,R(-a),0),metal,{reflectance=.12})
		if k==0 and plate and UDim2~=nil and UDim~=nil then
			-- An original emblem: a ring with a tail, engraved.
			local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=300
			gui.LightInfluence=.8;gui.Parent=plate
			local ringFrame=Instance.new("Frame");ringFrame.AnchorPoint=Vector2.new(.5,.5);ringFrame.Position=UDim2.fromScale(.46,.5);ringFrame.Size=UDim2.fromOffset(46,46)
			ringFrame.BackgroundTransparency=1;ringFrame.Parent=gui
			Instance.new("UICorner",ringFrame).CornerRadius=UDim.new(.5,0)
			local stroke=Instance.new("UIStroke");stroke.Thickness=7;stroke.Color=rgb(92,98,112);stroke.Parent=ringFrame
			local tail=Instance.new("Frame");tail.AnchorPoint=Vector2.new(0,.5);tail.Position=UDim2.fromScale(.56,.36);tail.Size=UDim2.fromOffset(30,7)
			tail.Rotation=-35;tail.BackgroundColor3=rgb(92,98,112);tail.BorderSizePixel=0;tail.Parent=gui
			if opts.slashed then
				local cut=Instance.new("Frame");cut.AnchorPoint=Vector2.new(.5,.5);cut.Position=UDim2.fromScale(.5,.5);cut.Size=UDim2.new(1.2,0,0,6)
				cut.Rotation=-12;cut.BackgroundColor3=rgb(40,40,46);cut.BorderSizePixel=0;cut.Parent=gui
			end
		end
	end
	if opts.tails~=false then
		for _,s in {-1,1} do
			piece(model,"Head","HeadbandTail",Vector3.new(.2,.72,.06),CFrame.new(s*.16,y-.3,z+r-.02)*A(R(14),0,R(s*12)),cloth)
		end
	end
	return front
end
Looks.headband=headband

-- The rounded hair base over the crown and the back of the head.
-- The rounded hair base: an ellipsoid set up and back on the head, so it
-- covers the crown, the back and the temples and leaves the face clear (the
-- hairline crosses the forehead about 0.65 up). The headband wraps it.
local function hairBase(model,color,opts)
	opts=opts or {}
	return piece(model,"Head","HairBase",Vector3.new(1.96,1.9,2.0),CFrame.new(0,.14+(opts.lift or 0),.24),color,{mesh="Sphere",shadow=false})
end

local function hideOld(model)
	local hair=model:FindFirstChild("Hair");if hair then hair.Transparency=1 end
	local sash=model:FindFirstChild("Sash");if sash then sash.Transparency=1 end
	local eyes=model:FindFirstChild("Eyes");if eyes then eyes.Transparency=1 end
end

-- A drawn emblem on the back (or anywhere): a thin plate with a SurfaceGui.
local function badge(model,body,name,size,cf,draw)
	local p=piece(model,body,name,Vector3.new(size.X,size.Y,.02),cf,Color3.new(1,1,1),{transparency=1,shadow=false})
	if not p then return end
	if UDim2==nil or UDim==nil then return p end -- headless tests: no UI classes
	local gui=Instance.new("SurfaceGui");gui.Name="Drawing";gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=200
	gui.LightInfluence=.7;gui.Parent=p
	draw(gui)
	return p
end
local function disc(parent,pos,size,color,stroke,strokeColor)
	local f=Instance.new("Frame");f.AnchorPoint=Vector2.new(.5,.5);f.Position=pos;f.Size=size;f.BackgroundColor3=color;f.BorderSizePixel=0
	if color==nil then f.BackgroundTransparency=1 end
	Instance.new("UICorner",f).CornerRadius=UDim.new(.5,0)
	if stroke then local s=Instance.new("UIStroke");s.Thickness=stroke;s.Color=strokeColor or Color3.new();s.Parent=f end
	f.Parent=parent
	return f
end
-- Back is +Z: a badge there faces out of the back.
local BACK=A(0,math.pi,0)

Looks.dressers={}
local D=Looks.dressers

-- Naruto (12-13): the orange jumpsuit with the navy shoulders, the big white
-- collar, a red swirl on the back, the blue-cloth headband, wild blond spikes,
-- whisker marks, a grin never far away.
D.Naruto=function(model,def)
	local skin=rgb(252,220,186)
	local hair,hairShade=rgb(255,212,64),rgb(236,170,34)
	local orange,orangeDark=rgb(250,128,30),rgb(220,96,20)
	local navy=rgb(34,48,104)
	local white=rgb(246,244,236)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LowerTorso"},orange);paint(model,ARMS,orange);paint(model,LEGS,orange)
	-- Navy yoke over the shoulders, front and back.
	piece(model,"UpperTorso","Yoke",Vector3.new(1.72,.44,.94),CFrame.new(0,.5,0),navy,{mesh="Brick"})
	for _,side in {"Left","Right"} do ring(model,side.."UpperArm","Sleeve",.3,.5,.8,navy) end
	-- The big white collar round the base of the head; the zip.
	ring(model,"UpperTorso","Collar",.72,.22,1.62,white)
	piece(model,"UpperTorso","Zip",Vector3.new(.07,.98,.03),CFrame.new(0,-.12,-.47),white)
	piece(model,"UpperTorso","ZipPull",Vector3.new(.12,.16,.05),CFrame.new(0,.36,-.48),rgb(200,200,206),{mesh="Sphere"})
	badge(model,"UpperTorso","Swirl",Vector2.new(.8,.8),CFrame.new(0,-.08,.465)*BACK,function(gui)
		disc(gui,UDim2.fromScale(.5,.5),UDim2.fromScale(.84,.84),rgb(214,40,34))
		disc(gui,UDim2.fromScale(.56,.46),UDim2.fromScale(.5,.5),orange)
		disc(gui,UDim2.fromScale(.5,.5),UDim2.fromScale(.2,.2),rgb(214,40,34))
	end)
	-- Cuffs rolled at the wrists and ankles, white bandage and holster on the right thigh.
	for _,side in {"Left","Right"} do
		ring(model,side.."LowerArm","Cuff",-.4,.2,.72,orangeDark)
		ring(model,side.."LowerLeg","PantCuff",-.36,.22,.8,orangeDark)
	end
	ring(model,"RightUpperLeg","ThighWrap",-.05,.34,.86,white)
	piece(model,"RightUpperLeg","Holster",Vector3.new(.2,.46,.42),CFrame.new(.42,-.05,0),navy,{mesh="Brick"})
	piece(model,"LowerTorso","Pouch",Vector3.new(.6,.34,.24),CFrame.new(0,.06,.5),rgb(84,74,66),{mesh="Brick"})
	sandals(model,navy,skin)
	-- Hair: a round base, spikes all round, the fringe over the band.
	hairBase(model,hair)
	headband(model,rgb(40,70,160))
	local spikes={
		{0,.9,.1, 0,1,.2, 1.0,.5},{-.45,.82,.2, -.55,.8,.3, .95,.46},{.45,.82,.2, .55,.8,.3, .95,.46},
		{-.2,.78,.55, -.2,.55,1, .9,.5},{.25,.78,.55, .25,.55,1, .9,.5},{0,.4,.85, 0,.1,1, .85,.52},
		{-.55,.36,.7, -.6,0,.9, .8,.46},{.55,.36,.7, .6,0,.9, .8,.46},{-.85,.6,.1, -1,.45,.15, .7,.42},
		{.85,.6,.1, 1,.45,.15, .7,.42},{-.8,.3,.45, -.9,-.1,.5, .66,.4},{.8,.3,.45, .9,-.1,.5, .66,.4},
		{0,-.1,.9, 0,-.6,.8, .6,.44},{-.4,.95,-.3, -.4,1,-.3, .6,.38},{.4,.95,-.3, .4,1,-.3, .6,.38},
	}
	for i,s in spikes do lock(model,"HairSpike",Vector3.new(s[1],s[2],s[3]),Vector3.new(s[4],s[5],s[6]),s[7],s[8],s[8]*.8,if i%3==0 then hairShade else hair) end
	-- Fringe: short spikes falling over the band.
	for _,x in {-.52,-.26,0,.26,.52} do
		lock(model,"Fringe",Vector3.new(x,.74,-.52),Vector3.new(x*.35,-1,-.8),.62,.34,.22,if x==0 then hairShade else hair)
	end
	for _,s in {-1,1} do lock(model,"SideLock",Vector3.new(s*.9,.4,-.32),Vector3.new(s*.25,-1,-.2),.6,.28,.2,hair) end
	Face.build(model,{iris=rgb(60,140,240),skin=skin,brow=rgb(214,150,40),lash=rgb(40,30,30),cheeks="whiskers",mood="fierce"})
	settle(model)
end

-- Sasuke (12): navy high-collared short-sleeve shirt, a red-and-white roundel
-- on the back, white shorts, pale arm warmers, leg wraps, blue-black hair
-- with the spikes swept back and long bangs framing the face.
D.Sasuke=function(model,def)
	local skin=rgb(250,226,204)
	local hair,hairShade=rgb(30,34,56),rgb(46,54,88)
	local navy,navyDark=rgb(36,46,96),rgb(26,32,70)
	local white=rgb(238,236,230)
	local warm=rgb(222,222,230)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LeftUpperArm","RightUpperArm"},navy)
	paint(model,{"LeftLowerArm","RightLowerArm"},warm)
	paint(model,{"LowerTorso","LeftUpperLeg","RightUpperLeg"},white)
	paint(model,{"LeftLowerLeg","RightLowerLeg"},skin)
	-- The high collar, open at the front.
	ring(model,"UpperTorso","HighCollar",.78,.42,1.7,navy)
	for _,side in {"Left","Right"} do
		ring(model,side.."UpperArm","SleeveHem",-.22,.12,.76,navyDark)
		ring(model,side.."LowerArm","WarmerTop",.42,.14,.72,rgb(200,200,210))
		ring(model,side.."LowerLeg","LegWrap",.26,.46,.8,white)
		ring(model,side.."UpperLeg","ShortsHem",-.28,.12,.86,rgb(214,212,206))
	end
	piece(model,"LowerTorso","Belt",Vector3.new(1.7,.16,.92),CFrame.new(0,.3,0),rgb(110,90,150),{mesh="Brick"})
	badge(model,"UpperTorso","Roundel",Vector2.new(.62,.62),CFrame.new(0,.08,.465)*BACK,function(gui)
		local top=Instance.new("Frame");top.Size=UDim2.fromScale(1,.5);top.BackgroundTransparency=1;top.ClipsDescendants=true;top.Parent=gui
		disc(top,UDim2.fromScale(.5,1),UDim2.fromScale(.92,1.84),rgb(214,40,40))
		local bottom=Instance.new("Frame");bottom.Position=UDim2.fromScale(0,.5);bottom.Size=UDim2.fromScale(1,.5);bottom.BackgroundTransparency=1;bottom.ClipsDescendants=true;bottom.Parent=gui
		disc(bottom,UDim2.fromScale(.5,0),UDim2.fromScale(.92,1.84),rgb(246,244,240))
	end)
	sandals(model,navyDark,skin)
	hairBase(model,hair)
	headband(model,navyDark)
	-- Spikes swept back and up from the crown.
	for i,s in {{0,.7,.6, 0,.6,1, 1.0,.56},{-.38,.62,.6, -.45,.5,1, .92,.5},{.38,.62,.6, .45,.5,1, .92,.5},
		{-.2,.3,.85, -.25,.35,1, .9,.5},{.2,.3,.85, .25,.35,1, .9,.5},{0,.9,.25, 0,.9,.6, .8,.5},{-.7,.5,.4, -.8,.3,.8, .7,.44},{.7,.5,.4, .8,.3,.8, .7,.44}} do
		lock(model,"HairSpike",Vector3.new(s[1],s[2],s[3]),Vector3.new(s[4],s[5],s[6]),s[7],s[8],s[8]*.7,if i%2==0 then hairShade else hair)
	end
	-- Long bangs down both sides of the face, a short fringe in the middle.
	for _,s in {-1,1} do
		lock(model,"Bang",Vector3.new(s*.8,.34,-.44),Vector3.new(s*.06,-1,-.12),1.15,.44,.26,hair)
		lock(model,"SideHair",Vector3.new(s*.95,.5,0),Vector3.new(s*.2,-1,.1),.95,.36,.5,hair)
	end
	for _,x in {-.34,0,.34} do lock(model,"Fringe",Vector3.new(x,.74,-.52),Vector3.new(x*.3,-1,-.8),.78,.38,.24,hair) end
	-- The cursed seal (hidden until the awakening): three marks on the neck.
	for k=0,2 do
		local mark=piece(model,"Head","CurseMark",Vector3.new(.12,.2,.03),Face.onHead(-58-k*7,-.42+k*.16,.01)*A(0,0,R(20-k*15)),rgb(14,10,16),{mesh="Sphere",shadow=false})
		if mark then mark.Transparency=1 end
	end
	Face.build(model,{iris=rgb(46,46,70),irisDark=rgb(16,16,26),skin=skin,brow=rgb(30,34,56),lash=rgb(20,20,30),mood="cool"})
	settle(model)
end

-- Gaara (12): the deep red-brown coat to the knees over grey trousers, the
-- strap across the chest holding a big gourd on his back, short spiky
-- brick-red hair, no brows, the dark rings round pale teal eyes, the red mark
-- on his forehead.
D.Gaara=function(model,def)
	local skin=rgb(250,228,212)
	local hair,hairShade=rgb(190,52,40),rgb(150,36,30)
	local coat,coatDark=rgb(122,46,44),rgb(92,32,34)
	local grey=rgb(110,104,104)
	local strap=rgb(214,200,170)
	local gourd,gourdDark=rgb(214,170,110),rgb(170,126,78)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LowerTorso"},coat);paint(model,ARMS,coat)
	paint(model,{"LeftUpperLeg","RightUpperLeg"},coat);paint(model,{"LeftLowerLeg","RightLowerLeg"},grey)
	-- The coat's skirt over the thighs, split at the front.
	for _,s in {-1,1} do
		piece(model,"LowerTorso","CoatSkirt",Vector3.new(.84,1.3,.98),CFrame.new(s*.42,-.68,.02)*A(0,0,R(s*-4)),coat,{mesh="Brick"})
	end
	piece(model,"LowerTorso","CoatHem",Vector3.new(1.74,.12,1.0),CFrame.new(0,-1.3,.02),coatDark,{mesh="Brick"})
	piece(model,"LowerTorso","Sash",Vector3.new(1.72,.22,.94),CFrame.new(0,.3,0),coatDark,{mesh="Brick"})
	ring(model,"UpperTorso","Collar",.74,.26,1.66,coatDark)
	for _,side in {"Left","Right"} do
		ring(model,side.."LowerArm","Cuff",-.38,.2,.74,coatDark)
		ring(model,side.."LowerLeg","Wrap",-.32,.24,.78,rgb(226,220,206))
	end
	-- The gourd strap: right shoulder to left hip, front and back.
	piece(model,"UpperTorso","GourdStrap",Vector3.new(.2,2.0,.05),CFrame.new(0,-.02,-.475)*A(0,0,R(-36)),strap)
	piece(model,"UpperTorso","GourdStrap",Vector3.new(.2,2.0,.05),CFrame.new(0,-.02,.475)*A(0,0,R(36)),strap)
	piece(model,"UpperTorso","StrapClasp",Vector3.new(.3,.3,.06),CFrame.new(.24,.3,-.5)*A(0,0,R(-36)),rgb(180,186,196),{reflectance=.1})
	-- The gourd: a big round belly, a smaller top, the neck and its cork.
	blob(model,"UpperTorso","Gourd",Vector3.new(1.8,1.8,1.5),CFrame.new(.05,-.35,1.18),gourd)
	blob(model,"UpperTorso","GourdTop",Vector3.new(1.18,1.18,1.0),CFrame.new(.22,.72,1.12),gourd)
	piece(model,"UpperTorso","GourdWaist",Vector3.new(.26,.9,.9),CFrame.new(.14,.26,1.15)*UPRIGHT,gourdDark,{shape=Enum.PartType.Cylinder})
	piece(model,"UpperTorso","GourdNeck",Vector3.new(.36,.4,.36),CFrame.new(.3,1.38,1.1)*A(0,0,R(-12)),gourdDark,{mesh="Head"})
	blob(model,"UpperTorso","GourdCork",Vector3.new(.3,.22,.3),CFrame.new(.33,1.6,1.1),rgb(120,86,56))
	-- Hair: short, messy, lifted at the front.
	hairBase(model,hair)
	for i,s in {{0,.92,.05, 0,1,.1, .62,.46},{-.42,.85,.1, -.6,.9,.1, .6,.42},{.42,.85,.1, .6,.9,.1, .6,.42},
		{-.25,.78,.5, -.3,.6,1, .62,.44},{.25,.78,.5, .3,.6,1, .62,.44},{0,.45,.85, 0,.2,1, .6,.46},
		{-.8,.55,.2, -1,.3,.3, .52,.4},{.8,.55,.2, 1,.3,.3, .52,.4},{-.6,.25,.65, -.7,-.1,.8, .52,.4},{.6,.25,.65, .7,-.1,.8, .52,.4},
		{-.3,.92,-.4, -.35,.85,-.6, .5,.36},{.3,.92,-.4, .35,.85,-.6, .5,.36}} do
		lock(model,"HairSpike",Vector3.new(s[1],s[2],s[3]),Vector3.new(s[4],s[5],s[6]),s[7],s[8],s[8]*.8,if i%3==0 then hairShade else hair)
	end
	for _,x in {-.55,-.28,.02,.3,.56} do lock(model,"Fringe",Vector3.new(x,.74,-.52),Vector3.new(x*.5,-.9,-.8),.5,.32,.2,hair) end
	-- The mark above his left eye.
	badge(model,"Head","LoveMark",Vector2.new(.34,.34),Face.onHead(-20,.46,.01),function(gui)
		local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text="愛";t.TextScaled=true
		t.Font=Enum.Font.GothamBold;t.TextColor3=rgb(200,36,40);t.Parent=gui
	end)
	Face.build(model,{iris=rgb(120,200,190),irisDark=rgb(60,140,130),style="ringed",skin=skin,brow=false,lash=rgb(30,20,24),
		ring=rgb(44,30,36),sclera=Vector2.new(.33,.26),mood="stare",lids=.12})
	settle(model)
end

-- Rock Lee (13): the green jumpsuit, orange leg warmers, the headband worn as
-- a belt, bandaged hands, a glossy black bowl cut, round eyes, huge brows.
D["Rock Lee"]=function(model,def)
	local skin=rgb(252,222,192)
	local green,greenDark=rgb(56,170,74),rgb(40,132,58)
	local warmer=rgb(250,134,40)
	local hair=rgb(16,16,22)
	local wrap=rgb(244,240,228)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LowerTorso"},green);paint(model,ARMS,green);paint(model,LEGS,green)
	-- Vest-cut seams of the jumpsuit, the zip.
	piece(model,"UpperTorso","Seam",Vector3.new(.06,1.3,.03),CFrame.new(0,-.04,-.465),greenDark)
	ring(model,"UpperTorso","Collar",.72,.2,1.6,greenDark)
	-- The headband as a belt, the plate at the front.
	local belt=rgb(190,40,40)
	piece(model,"LowerTorso","Belt",Vector3.new(1.72,.26,.94),CFrame.new(0,.28,0),belt,{mesh="Brick"})
	piece(model,"LowerTorso","BeltPlate",Vector3.new(.5,.3,.05),CFrame.new(0,.28,-.48),rgb(188,196,208),{reflectance=.12})
	-- Orange leg warmers, rolled at the top; bandages on the hands and forearms.
	for _,side in {"Left","Right"} do
		ring(model,side.."LowerLeg","LegWarmer",-.05,.86,.86,warmer)
		ring(model,side.."LowerLeg","WarmerRoll",.4,.2,.9,rgb(230,110,30))
		ring(model,side.."LowerArm","Wrap",-.12,.6,.72,wrap)
		local hand=model:FindFirstChild(side.."Hand");if hand then hand.Color=wrap end
	end
	for _,p in model:GetChildren() do if p.Name=="Thumb" then p.Color=wrap end end
	sandals(model,rgb(40,46,66),skin)
	-- The bowl cut: a glossy round helmet, a blunt fringe, short at the nape.
	-- (a Head mesh: its flat bottom is the straight-cut fringe), the back
	-- of the head, short sideburns.
	piece(model,"Head","HairBase",Vector3.new(2.04,.98,2.06),CFrame.new(0,.63,.06),hair,{mesh="Head",reflectance=.03,shadow=false})
	blob(model,"Head","BackHair",Vector3.new(1.92,1.6,1.3),CFrame.new(0,.12,.36),hair,{reflectance=.03,shadow=false})
	for _,s in {-1,1} do blob(model,"Head","SideHair",Vector3.new(.26,.7,.5),CFrame.new(s*.86,0,-.12),hair) end
	Face.build(model,{style="round",iris=rgb(20,20,24),irisDark=rgb(10,10,12),pupil=false,skin=skin,brow=hair,browThick=.12,browWide=1.25,
		lash=rgb(16,16,20),lashThick=.06,sclera=Vector2.new(.36,.36),mood="fierce"})
	settle(model)
end

-- Neji (13): the pale high-collared shirt with wide sleeves, dark shorts, the
-- bandaged right thigh and arm, long dark-brown hair tied low, the headband,
-- pale eyes without pupils.
D.Neji=function(model,def)
	local skin=rgb(252,228,206)
	local hair,hairShade=rgb(70,46,36),rgb(96,64,48)
	local shirt,shirtShade=rgb(236,230,216),rgb(204,196,180)
	local shorts=rgb(64,58,62)
	local wrap=rgb(246,244,238)
	Looks.form(model,skin)
	paint(model,{"UpperTorso"},shirt);paint(model,ARMS,shirt)
	paint(model,{"LowerTorso","LeftUpperLeg","RightUpperLeg"},shorts);paint(model,{"LeftLowerLeg","RightLowerLeg"},skin)
	-- The shirt hangs over the hips, wide sleeves, a high collar.
	piece(model,"LowerTorso","ShirtHem",Vector3.new(1.74,.8,.96),CFrame.new(0,.12,0),shirt,{mesh="Brick"})
	piece(model,"UpperTorso","Fold",Vector3.new(.06,1.1,.03),CFrame.new(-.14,-.05,-.465)*A(0,0,R(8)),shirtShade)
	ring(model,"UpperTorso","HighCollar",.76,.38,1.66,shirt)
	for _,side in {"Left","Right"} do
		ring(model,side.."LowerArm","WideSleeve",-.05,.8,.86,shirt)
		ring(model,side.."LowerLeg","LegWrap",.12,.6,.8,wrap)
	end
	ring(model,"RightUpperLeg","ThighWrap",0,.5,.88,wrap)
	piece(model,"RightUpperLeg","Holster",Vector3.new(.2,.42,.4),CFrame.new(.43,-.05,0),rgb(50,46,52),{mesh="Brick"})
	sandals(model,rgb(50,46,58),skin)
	-- Long straight hair: a base, bangs parted and framing, the long tail.
	hairBase(model,hair)
	headband(model,rgb(42,42,54))
	for _,s in {-1,1} do
		lock(model,"Bang",Vector3.new(s*.8,.34,-.44),Vector3.new(s*.03,-1,-.1),1.25,.44,.26,hair)
		blob(model,"Head","SideHair",Vector3.new(.34,1.5,.9),CFrame.new(s*.9,-.2,.22),hair)
	end
	blob(model,"Head","BackHair",Vector3.new(1.8,1.6,.6),CFrame.new(0,-.25,.84),hair)
	ring(model,"Head","HairTie",-.95,.14,.46,rgb(240,236,226))
	-- The tail falls down the back, from the head down to the waist.
	blob(model,"UpperTorso","HairTail",Vector3.new(.5,1.7,.34),CFrame.new(0,-.1,.62),hair)
	lock(model,"HairTip",Vector3.new(0,-.9,.62),Vector3.new(0,-1,.05),.6,.48,.32,hairShade,"UpperTorso")
	-- Byakugan veins at the temples (shown while focused).
	for _,s in {-1,1} do
		for k=0,2 do
			local vein=piece(model,"Head","ByakuganVein",Vector3.new(.03,.2,.02),Face.onHead(s*(44+k*4),.0+(k-1)*.08,.012)*A(0,0,R(s*(30-k*30))),rgb(150,138,196),{shadow=false})
			if vein then vein.Transparency=1 end
		end
	end
	Face.build(model,{style="pale",pupil=false,iris=rgb(236,232,250),skin=skin,brow=hair,lash=rgb(40,30,30),mood="cool",lids=.08})
	settle(model)
end

-- Itachi (13, the ANBU years; user 29/10 14:33 with a reference): the dark
-- short-sleeved shirt with its high collar, the pale ANBU chest armour on
-- shoulder straps with its padded waist band, long arm guards, dark
-- trousers, the headband, long bangs and a low ponytail, the lines under his
-- eyes, the Sharingan, and a sword on his back, longer than Kakashi's tanto
-- (hilt over the right shoulder; hilt parts are Sheathed*).
D.Itachi=function(model,def)
	local skin=rgb(248,224,204)
	local hair,hairShade=rgb(24,24,32),rgb(44,44,58)
	local shirt=rgb(32,32,44)
	local armor,armorShade=rgb(186,184,204),rgb(150,148,170)
	local pants=rgb(48,48,62)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm"},shirt)
	paint(model,{"LeftLowerArm","RightLowerArm"},skin)
	paint(model,LEGS,pants)
	ring(model,"UpperTorso","HighCollar",.8,.44,1.7,shirt)
	-- The armour: front and back plates, straps over the shoulders, a seam,
	-- two buckles, the padded band round the waist.
	piece(model,"UpperTorso","ChestArmor",Vector3.new(1.56,1.12,1.0),CFrame.new(0,-.1,0),armor,{mesh="Brick"})
	for _,s in {-1,1} do
		piece(model,"UpperTorso","ArmorStrap",Vector3.new(.3,.12,1.02),CFrame.new(s*.42,.56,0),armor,{mesh="Brick"})
		piece(model,"UpperTorso","ArmorBuckle",Vector3.new(.22,.16,.05),CFrame.new(s*.5,-.44,-.52)*A(0,0,R(s*-30)),armorShade)
	end
	piece(model,"UpperTorso","ArmorSeam",Vector3.new(.04,1.0,.03),CFrame.new(.06,-.1,-.51),armorShade)
	piece(model,"LowerTorso","ArmorBand",Vector3.new(1.86,.34,1.1),CFrame.new(0,.32,0),armor,{mesh="Brick"})
	piece(model,"LowerTorso","ArmorBandEdge",Vector3.new(1.88,.06,1.12),CFrame.new(0,.15,0),armorShade,{mesh="Brick"})
	-- Short sleeves; long arm guards with a pale plate on the outside.
	for _,side in {"Left","Right"} do
		local s=if side=="Left" then -1 else 1
		ring(model,side.."UpperArm","SleeveHem",-.06,.12,.78,rgb(24,24,34))
		ring(model,side.."LowerArm","ArmGuard",-.1,.72,.76,rgb(30,30,42))
		piece(model,side.."LowerArm","GuardPlate",Vector3.new(.1,.84,.5),CFrame.new(s*.39,-.08,0),armor)
		ring(model,side.."LowerArm","GuardStrap",.12,.07,.8,armorShade)
		ring(model,side.."LowerArm","GuardStrap",-.36,.07,.8,armorShade)
		ring(model,side.."LowerLeg","LegWrap",-.32,.3,.78,rgb(226,224,232))
	end
	sandals(model,rgb(34,34,46),skin)
	-- The sword across the back: long sheath, round guard, a hilt wrapped in
	-- a diamond pattern, over the right shoulder.
	local axis=CFrame.new(.08,0,.62)*A(0,0,R(-28))
	piece(model,"UpperTorso","Sheath",Vector3.new(.22,2.6,.2),axis*CFrame.new(0,-.3,0),rgb(22,22,28),{mesh="Head"})
	piece(model,"UpperTorso","SheathTip",Vector3.new(.1,.24,.24),axis*CFrame.new(0,-1.62,0)*UPRIGHT,rgb(150,150,160),{shape=Enum.PartType.Cylinder})
	piece(model,"UpperTorso","SheathedGuard",Vector3.new(.06,.4,.4),axis*CFrame.new(0,1.02,0)*UPRIGHT,rgb(40,40,48),{shape=Enum.PartType.Cylinder})
	piece(model,"UpperTorso","SheathedHilt",Vector3.new(.16,.78,.16),axis*CFrame.new(0,1.44,0),rgb(232,228,214),{mesh="Head"})
	for k=0,3 do
		piece(model,"UpperTorso","SheathedWrap",Vector3.new(.17,.08,.17),axis*CFrame.new(0,1.16+k*.18,0)*A(0,R(45),R(30)),rgb(26,26,34),{mesh="Brick"})
	end
	piece(model,"UpperTorso","SheathedPommel",Vector3.new(.05,.18,.18),axis*CFrame.new(0,1.84,0)*UPRIGHT,rgb(40,40,48),{shape=Enum.PartType.Cylinder})
	hairBase(model,hair)
	headband(model,rgb(36,42,62))
	for _,s in {-1,1} do
		lock(model,"Bang",Vector3.new(s*.8,.34,-.44),Vector3.new(s*.03,-1,-.1),1.3,.44,.26,hair)
		blob(model,"Head","SideHair",Vector3.new(.3,1.1,.8),CFrame.new(s*.9,-.05,.2),hair)
	end
	for _,x in {-.3,0,.28} do lock(model,"Fringe",Vector3.new(x,.74,-.52),Vector3.new(x*.3,-1,-.8),.7,.34,.22,if x==0 then hairShade else hair) end
	-- The low ponytail.
	ring(model,"Head","HairTie",-.78,.12,.4,rgb(70,30,40))
	blob(model,"UpperTorso","Ponytail",Vector3.new(.38,1.0,.3),CFrame.new(-.12,.3,.6)*A(R(-8),0,R(8)),hair)
	lock(model,"HairTip",Vector3.new(-.16,-.2,.64),Vector3.new(-.1,-1,.08),.5,.36,.24,hair,"UpperTorso")
	for _,s in {-1,1} do
		piece(model,"Head","TearLine",Vector3.new(.025,.2,.02),Face.onHead(s*30,-.28,.012)*A(0,0,R(s*-12)),rgb(150,110,104),{shadow=false})
	end
	Face.build(model,{iris=rgb(214,30,36),irisDark=rgb(140,10,20),skin=skin,brow=hair,lash=rgb(20,18,24),mood="cool",lids=.1,sharingan=true})
	settle(model)
end

-- Minato (13; user 29/10 14:35 with a reference): the white tracksuit with
-- navy piping down the arms and legs, a navy band at the hem and cuffs, the
-- hood down round the collar, a fishnet undershirt at the neck, the zip,
-- spiky blond hair with short bangs, calm blue eyes, a quiet smile.
D.Minato=function(model,def)
	local skin=rgb(252,224,196)
	local hair,hairShade=rgb(255,218,80),rgb(236,182,44)
	local white,whiteShade=rgb(236,238,242),rgb(206,210,220)
	local navy=rgb(36,48,96)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LowerTorso"},white);paint(model,ARMS,white);paint(model,LEGS,white)
	-- The hood down round the collar, the fishnet at the throat, the zip.
	ring(model,"UpperTorso","Hood",.74,.3,1.76,whiteShade)
	blob(model,"UpperTorso","HoodBack",Vector3.new(1.3,.6,.4),CFrame.new(0,.62,.46),whiteShade)
	piece(model,"UpperTorso","Fishnet",Vector3.new(.5,.24,.04),CFrame.new(0,.64,-.47),rgb(70,70,80))
	piece(model,"UpperTorso","Zip",Vector3.new(.05,1.2,.03),CFrame.new(0,-.06,-.465),rgb(170,176,190))
	-- Navy piping: down the outside of the arms and legs, the hem band.
	for _,side in {"Left","Right"} do
		local s=if side=="Left" then -1 else 1
		for _,limb in {"UpperArm","LowerArm"} do
			piece(model,side..limb,"Piping",Vector3.new(.06,1.12,.12),CFrame.new(s*.33,0,0),navy)
		end
		for _,limb in {"UpperLeg","LowerLeg"} do
			piece(model,side..limb,"Piping",Vector3.new(.06,1.16,.12),CFrame.new(s*.38,0,0),navy)
		end
		ring(model,side.."LowerArm","Cuff",-.42,.14,.72,navy)
		ring(model,side.."LowerLeg","PantCuff",-.4,.12,.78,navy)
	end
	piece(model,"UpperTorso","SidePiping",Vector3.new(1.7,1.38,.06),CFrame.new(0,0,0),navy,{mesh="Brick",scale=Vector3.new(1,1,1)})
	piece(model,"LowerTorso","HemBand",Vector3.new(1.72,.24,.94),CFrame.new(0,.36,0),navy,{mesh="Brick"})
	sandals(model,navy,skin)
	-- Hair: spiky all round, short bangs, no headband.
	hairBase(model,hair)
	for i,s in {{0,.95,.15, 0,1,.3, .95,.5},{-.42,.86,.25, -.6,.75,.45, .9,.46},{.42,.86,.25, .6,.75,.45, .9,.46},
		{-.2,.7,.65, -.25,.4,1, .9,.5},{.2,.7,.65, .25,.4,1, .9,.5},{0,.25,.92, 0,-.2,1, .75,.5},
		{-.6,.35,.7, -.65,-.1,.9, .75,.44},{.6,.35,.7, .65,-.1,.9, .75,.44},{-.88,.6,.2, -1,.35,.3, .7,.42},{.88,.6,.2, 1,.35,.3, .7,.42},
		{-.4,.95,-.25, -.5,1,-.3, .65,.4},{.4,.95,-.25, .5,1,-.3, .65,.4}} do
		lock(model,"HairSpike",Vector3.new(s[1],s[2],s[3]),Vector3.new(s[4],s[5],s[6]),s[7],s[8],s[8]*.8,if i%3==0 then hairShade else hair)
	end
	for _,s in {-1,1} do lock(model,"Bang",Vector3.new(s*.8,.4,-.42),Vector3.new(s*.1,-1,-.12),.95,.4,.24,hair) end
	for _,x in {-.44,-.15,.15,.44} do lock(model,"Fringe",Vector3.new(x,.74,-.52),Vector3.new(x*.4,-1,-.8),.72,.36,.22,hair) end
	Face.build(model,{iris=rgb(70,150,230),skin=skin,brow=rgb(220,170,60),lash=rgb(40,30,30),mood="gentle"})
	settle(model)
end

-- Kakashi (13; user 29/10 13:19 "version Storm, un petit sabre dans le
-- dos", 14:33 with a reference): the black suit and mask up over the nose,
-- the brown straps crossed on the chest with a metal clasp, grey shoulder
-- guards, black arm guards with metal plates, a pale belt, silver hair
-- swept up and to his left, the headband straight across the forehead, the
-- tanto sheathed across his back (hilt over the right shoulder). Hilt parts
-- are named Sheathed*: the client hides them while the blade is drawn.
D.Kakashi=function(model,def)
	local skin=rgb(250,226,204)
	local hair,hairShade=rgb(214,220,230),rgb(170,178,194)
	local suit,suitDark=rgb(30,32,42),rgb(20,22,30)
	local leather,leatherDark=rgb(124,82,56),rgb(96,62,42)
	local metal=rgb(176,182,196)
	Looks.form(model,skin)
	paint(model,{"UpperTorso","LowerTorso"},suit);paint(model,ARMS,suit);paint(model,LEGS,suit)
	ring(model,"Head","Mask",-.56,.8,1.86,suit,{shadow=false})
	ring(model,"UpperTorso","HighCollar",.76,.36,1.7,suit)
	-- The crossed straps, front and back, and the clasp where they meet.
	for _,z in {-.475,.475} do
		for _,s in {-1,1} do
			piece(model,"UpperTorso","Strap",Vector3.new(.22,2.0,.05),CFrame.new(0,-.04,z)*A(0,0,R(s*34)),leather)
		end
	end
	piece(model,"UpperTorso","StrapClasp",Vector3.new(.3,.3,.07),CFrame.new(0,-.04,-.5)*A(0,0,R(45)),metal,{reflectance=.08})
	-- Grey shoulder guards; black arm guards with a metal plate outside.
	for _,side in {"Left","Right"} do
		local s=if side=="Left" then -1 else 1
		blob(model,side.."UpperArm","ShoulderGuard",Vector3.new(.88,.56,.88),CFrame.new(0,.42,0),metal)
		ring(model,side.."LowerArm","ArmGuard",-.12,.76,.8,suitDark)
		piece(model,side.."LowerArm","GuardPlate",Vector3.new(.1,.7,.44),CFrame.new(s*.41,-.1,0),metal,{reflectance=.06})
		ring(model,side.."LowerArm","GuardBand",.24,.06,.82,metal)
		ring(model,side.."LowerLeg","ShinWrap",-.32,.3,.8,rgb(206,196,170))
	end
	-- The pale belt and its metal buckle; pouch and holster.
	piece(model,"LowerTorso","Belt",Vector3.new(1.72,.2,.94),CFrame.new(0,.32,0),rgb(206,190,150),{mesh="Brick"})
	piece(model,"LowerTorso","Buckle",Vector3.new(.32,.24,.06),CFrame.new(0,.32,-.48),metal,{reflectance=.08})
	piece(model,"LowerTorso","BackPouch",Vector3.new(.6,.32,.22),CFrame.new(0,.1,.5),leatherDark,{mesh="Brick"})
	piece(model,"RightUpperLeg","Holster",Vector3.new(.2,.46,.42),CFrame.new(.43,-.05,0),suitDark,{mesh="Brick"})
	-- The sheath across the back, its mouth over the right shoulder.
	local axis=CFrame.new(.1,.12,.62)*A(0,0,R(-36))
	piece(model,"UpperTorso","Sheath",Vector3.new(.22,1.7,.2),axis,rgb(22,22,28),{mesh="Head"})
	piece(model,"UpperTorso","SheathTip",Vector3.new(.12,.24,.24),axis*CFrame.new(0,-.88,0)*UPRIGHT,rgb(160,164,172),{shape=Enum.PartType.Cylinder,reflectance=.1})
	piece(model,"UpperTorso","SheathedGuard",Vector3.new(.06,.36,.36),axis*CFrame.new(0,.88,0)*UPRIGHT,rgb(50,50,58),{shape=Enum.PartType.Cylinder})
	piece(model,"UpperTorso","SheathedHilt",Vector3.new(.15,.6,.15),axis*CFrame.new(0,1.2,0),rgb(236,234,226),{mesh="Head"})
	for k=0,2 do piece(model,"UpperTorso","SheathedWrap",Vector3.new(.04,.17,.17),axis*CFrame.new(0,1.0+k*.17,0)*UPRIGHT,suitDark,{shape=Enum.PartType.Cylinder}) end
	sandals(model,suitDark,skin)
	-- Silver hair: swept up and leaning to his left.
	hairBase(model,hair)
	headband(model,rgb(30,36,56))
	for i,s in {{0,.9,.1, -.35,1,.15, 1.25,.58},{-.38,.85,.15, -.7,.9,.2, 1.15,.52},{.36,.86,.1, .05,1,.1, 1.05,.52},
		{-.7,.66,.1, -1,.6,.15, .95,.48},{.7,.7,.15, .5,.9,.2, .85,.46},{-.15,.75,.55, -.5,.8,.8, 1.0,.5},
		{.3,.7,.55, .05,.75,.9, .9,.48},{-.55,.5,.55, -.9,.4,.7, .8,.44},{0,.5,.8, -.2,.4,1, .8,.46},{-.2,.88,-.35, -.5,1,-.35, .75,.42},
		{.25,.88,-.35, -.05,1,-.4, .7,.4},{-.85,.3,.3, -1,.1,.4, .7,.4},{.85,.35,.3, 1,.25,.35, .6,.38}} do
		lock(model,"HairSpike",Vector3.new(s[1],s[2],s[3]),Vector3.new(s[4],s[5],s[6]),s[7],s[8],s[8]*.75,if i%2==0 then hairShade else hair)
	end
	for _,x in {-.4,-.1,.22} do lock(model,"Fringe",Vector3.new(x,.74,-.52),Vector3.new(x*.3-.15,-1,-.8),.6,.32,.2,hair) end
	for _,s in {-1,1} do lock(model,"SideLock",Vector3.new(s*.86,.3,-.3),Vector3.new(s*.15,-1,-.1),.7,.3,.2,hair) end
	Face.build(model,{iris=rgb(60,60,70),irisDark=rgb(24,24,30),skin=skin,brow=rgb(150,156,170),lash=rgb(30,30,38),mood="lazy",mouth=false,lids=.42})
	settle(model)
end

return Looks
