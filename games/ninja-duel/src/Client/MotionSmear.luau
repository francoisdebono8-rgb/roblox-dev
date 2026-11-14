-- Speed smear (fluidity pass, user reference 28/10). What the eye cannot
-- follow is drawn as motion: a body moving faster than a sprint leaves dark
-- translucent copies of its pose along its path and thin speed streaks around
-- it; a body that jumps several studs in one frame (a teleport, a substitution,
-- a flash step) leaves copies interpolated along the line it crossed, so the
-- jump reads as a very fast move, not a cut. Presentation only.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")

local Smear={}

local LIMBS={"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand",
	"LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot","HairCap"}
local GHOST=Color3.fromRGB(26,26,36)
local SPEED=55 -- studs/s: above a sprint (45); dodge 61, pursuit 74, rush 90
local JUMP=6 -- studs in one frame: a teleport
local CADENCE=1/20
local LIFE=.12
local STREAK_LIFE=.12

type State={pos:Vector3?,at:number?,pose:{[string]:CFrame}?}

local function folder():Instance
	local f=workspace:FindFirstChild("NinjaDuelFX")
	if not f then
		f=Instance.new("Folder");f.Name="NinjaDuelFX";f.Parent=workspace
	end
	return f
end

local function snapshot(model:Model):{[string]:CFrame}
	local out={}
	for _,name in LIMBS do
		local p=model:FindFirstChild(name)
		if p and p:IsA("BasePart") and p.Transparency<.9 then out[name]=p.CFrame end
	end
	return out
end

local function ghost(model:Model,pose:{[string]:CFrame},shift:Vector3,transparency:number,life:number)
	local holder=Instance.new("Model");holder.Name="Smear"
	for name,cf in pose do
		local src=model:FindFirstChild(name)
		if src and src:IsA("BasePart") then
			local g=Instance.new("Part")
			g.Anchored=true;g.CanCollide=false;g.CanQuery=false;g.CanTouch=false;g.CastShadow=false
			g.Material=Enum.Material.SmoothPlastic;g.Color=GHOST
			g.Size=src.Size;g.CFrame=cf+shift
			g.Transparency=transparency
			g.Parent=holder
			TweenService:Create(g,TweenInfo.new(life,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1}):Play()
		end
	end
	holder.Parent=folder()
	Debris:AddItem(holder,life+.05)
end

-- (14/11, CM QA A2: « traits de vitesse = poteaux noirs verticaux ») The
-- streaks were drawn upright whatever the motion, in the ghosts' near-black:
-- a body thrown up left a column of black poles from the sky to the floor.
-- They lie along the motion now (3D: up, down, slanted), pale, and are gone
-- with their tween.
local STREAK=Color3.fromRGB(236,240,248)
local function streaks(at:Vector3,count:number,direction:Vector3)
	local f=folder()
	local dir=if direction.Magnitude>1e-3 then direction.Unit else Vector3.zAxis
	local side=dir:Cross(if math.abs(dir.Y)>.9 then Vector3.xAxis else Vector3.yAxis).Unit
	local lift=side:Cross(dir).Unit
	for _=1,count do
		local s=Instance.new("Part")
		s.Anchored=true;s.CanCollide=false;s.CanQuery=false;s.CanTouch=false;s.CastShadow=false
		s.Material=Enum.Material.SmoothPlastic;s.Color=STREAK
		local length=1.6+math.random()*1.6
		s.Size=Vector3.new(.05,.05,length)
		local offset=side*((math.random()-.5)*3)+lift*((math.random()-.5)*2.4)-dir*(math.random()*1.5)
		local p=at+offset
		s.CFrame=CFrame.lookAt(p,p+dir)
		s.Transparency=.5
		s.Parent=f
		TweenService:Create(s,TweenInfo.new(STREAK_LIFE,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Size=Vector3.new(.03,.03,length*1.4)}):Play()
		task.delay(STREAK_LIFE+.02,function() s:Destroy() end)
	end
end

-- One rendered frame of one body. `st` is the caller's per-body table.
function Smear.step(st:State,model:Model?,dt:number)
	if not model then return end
	local root=model:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then return end
	local now=os.clock()
	local pos=root.Position
	local pose=snapshot(model)
	if st.pos and st.pose then
		local delta=pos-(st.pos::Vector3)
		if delta.Magnitude>JUMP and delta.Magnitude<80 then
			-- A teleport: copies across the gap, fading the farther back they are.
			-- (Partie 0: four dense copies read as a cloud of dark cubes; three
			-- light ones read as a body that crossed the gap.)
			for k=1,3 do
				local u=k/4
				ghost(model,pose,-delta*(1-u),.6+.15*(1-u),LIFE*1.3)
			end
			streaks(pos-delta*.5,6,delta)
			st.at=now
		elseif delta.Magnitude/math.max(dt,1e-3)>SPEED and now-(st.at or 0)>=CADENCE then
			ghost(model,st.pose::{[string]:CFrame},Vector3.zero,.68,LIFE)
			streaks(pos,2,delta)
			st.at=now
		end
	end
	st.pos=pos;st.pose=pose
end

-- Thin arcs behind the hands and feet while a strike is out (the reference's
-- fine swing lines): built once per body, lit only during the swing; they
-- only show where a limb moves fast, so a still hand leaves nothing.
local ENDS={RightHand=Vector3.new(0,-.35,0),LeftHand=Vector3.new(0,-.35,0),RightFoot=Vector3.new(0,-.1,-.35),LeftFoot=Vector3.new(0,-.1,-.35)}
function Smear.limbs(st:any,model:Model?,active:boolean)
	if not model then return end
	if st.trailModel~=model then
		st.trailModel=model;st.trails={}
		for name,tip in ENDS do
			local part=model:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				local a0=Instance.new("Attachment");a0.Name="SmearA";a0.Position=tip*.3;a0.Parent=part
				local a1=Instance.new("Attachment");a1.Name="SmearB";a1.Position=tip;a1.Parent=part
				local t=Instance.new("Trail")
				t.Name="SwingArc";t.Attachment0=a0;t.Attachment1=a1
				t.Color=ColorSequence.new(Color3.fromRGB(235,238,245))
				t.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.45),NumberSequenceKeypoint.new(1,1)})
				t.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,.1)})
				t.Lifetime=.11;t.MinLength=.15;t.FaceCamera=true;t.LightEmission=.2
				t.Enabled=false;t.Parent=part
				table.insert(st.trails,t)
			end
		end
	end
	for _,t in st.trails do
		if t.Parent and t.Enabled~=active then t.Enabled=active end
	end
end

return Smear
