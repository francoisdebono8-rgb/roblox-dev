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

local function streaks(at:Vector3,count:number,direction:Vector3)
	local f=folder()
	for _=1,count do
		local s=Instance.new("Part")
		s.Anchored=true;s.CanCollide=false;s.CanQuery=false;s.CanTouch=false;s.CastShadow=false
		s.Material=Enum.Material.SmoothPlastic;s.Color=GHOST
		local length=2+math.random()*2.2
		s.Size=Vector3.new(.05,length,.05)
		local side=direction:Cross(Vector3.yAxis)
		if side.Magnitude<1e-3 then side=Vector3.xAxis end
		side=side.Unit
		local offset=side*((math.random()-.5)*3.4)+Vector3.new(0,(math.random()-.3)*2.4,0)-direction*(math.random()*1.5)
		s.CFrame=CFrame.new(at+offset)
		s.Transparency=.35
		s.Parent=f
		TweenService:Create(s,TweenInfo.new(STREAK_LIFE,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Transparency=1,Size=Vector3.new(.03,length*1.4,.03)}):Play()
		Debris:AddItem(s,STREAK_LIFE+.05)
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
		local flat=Vector3.new(delta.X,0,delta.Z)
		if delta.Magnitude>JUMP and delta.Magnitude<80 then
			-- A teleport: copies across the gap, fading the farther back they are.
			-- (Partie 0: four dense copies read as a cloud of dark cubes; three
			-- light ones read as a body that crossed the gap.)
			for k=1,3 do
				local u=k/4
				ghost(model,pose,-delta*(1-u),.6+.15*(1-u),LIFE*1.3)
			end
			streaks(pos-delta*.5,6,if flat.Magnitude>.1 then flat.Unit else Vector3.zAxis)
			st.at=now
		elseif delta.Magnitude/math.max(dt,1e-3)>SPEED and now-(st.at or 0)>=CADENCE then
			ghost(model,st.pose::{[string]:CFrame},Vector3.zero,.68,LIFE)
			streaks(pos,2,if flat.Magnitude>.1 then flat.Unit else Vector3.zAxis)
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
