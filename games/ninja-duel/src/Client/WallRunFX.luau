-- (27/11, passe commune 4, François: « la course au mur doit être stylée »)
-- What a body running on a wall leaves on it, in town (Client/HubBody) and in
-- a duel (Client/Effects, the snapshot's wall / wallMode): at each step the
-- foot that takes the wall lights a ring of blue chakra flat on the surface
-- (it holds him there) and kicks a puff of dust off it; standing on the wall,
-- both soles glow, a slow pulse. Presentation only, on each client.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Kit=require(script.Parent.VfxKit)

local WallRunFX={}
WallRunFX.CHAKRA=Color3.fromRGB(96,170,255)
WallRunFX.CORE=Color3.fromRGB(214,236,255)
WallRunFX.DUST=Color3.fromRGB(196,184,160)
-- seconds between two steps, by how he moves on the wall
WallRunFX.STEP={climb=.15,run=.15,side=.13}
WallRunFX.STAND=.55 -- the soles' pulse while he stands on it
WallRunFX.REACH=2.2 -- how far from a foot a wall is looked for

local state=setmetatable({},{__mode="k"})
local DIRS={Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis,Vector3.yAxis,-Vector3.yAxis}

local function folderFor(model)
	local fx=workspace:FindFirstChild("NinjaDuelFX")
	if not fx then
		fx=Instance.new("Folder");fx.Name="NinjaDuelFX";fx.Parent=workspace
	end
	return fx
end

-- The wall under a foot: the nearest surface in the six directions that is
-- not the floor (|normal.Y| < .7) unless he stands on the wall (any).
local function surface(model,foot,anyFace)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={model,workspace:FindFirstChild("NinjaDuelFX")}
	local best
	for _,d in DIRS do
		local hit=workspace:Raycast(foot,d*WallRunFX.REACH,params)
		-- (an invisible boundary is not the wall he runs on)
		if hit and hit.Instance.Transparency>=.95 then hit=nil end
		if hit and (anyFace or math.abs(hit.Normal.Y)<.7) and (not best or hit.Distance<best.Distance) then best=hit end
	end
	return best
end

-- One ring flat on the wall: a thin neon disc that opens and fades, its
-- bright core, a puff of dust thrown off the wall.
function WallRunFX.mark(parent,position,normal,size,dust)
	local cf=CFrame.lookAt(position+normal*.06,position+normal*1.06)*CFrame.Angles(0,math.pi/2,0)
	local ring=Instance.new("Part")
	ring.Name="WallChakra";ring.Shape=Enum.PartType.Cylinder;ring.Material=Enum.Material.Neon
	ring.Color=WallRunFX.CHAKRA;ring.Transparency=.3;ring.Size=Vector3.new(.04,size,size)
	ring.CFrame=cf;ring.Anchored=true;ring.CanCollide=false;ring.CanQuery=false;ring.CanTouch=false;ring.CastShadow=false
	ring.Parent=parent
	local core=ring:Clone();core.Name="WallChakraCore";core.Color=WallRunFX.CORE;core.Transparency=.05
	core.Size=Vector3.new(.05,size*.45,size*.45);core.CFrame=cf*CFrame.new(.01,0,0);core.Parent=parent
	TweenService:Create(ring,TweenInfo.new(.38,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.03,size*1.9,size*1.9),Transparency=1}):Play()
	TweenService:Create(core,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.03,size*.9,size*.9),Transparency=1}):Play()
	Debris:AddItem(ring,.45);Debris:AddItem(core,.3)
	if dust then
		pcall(Kit.burst,parent,position+normal*.2,"smoke",3,{
			Lifetime=NumberRange.new(.35,.6),Speed=NumberRange.new(5,9),SpreadAngle=Vector2.new(35,35),
			Color=ColorSequence.new(WallRunFX.DUST),LightEmission=0,
			Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(.3,.8),NumberSequenceKeypoint.new(1,1.1)}),
			Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.7,.4),NumberSequenceKeypoint.new(1,1)}),
			Drag=6,Acceleration=Vector3.new(0,-6,0),RotSpeed=NumberRange.new(-60,60),Rotation=NumberRange.new(0,360),
			direction=normal})
	end
end

-- Each frame for a body: `mode` "climb" | "run" | "side" | "stand" | nil.
function WallRunFX.step(model,mode,now)
	if not model then return end
	local st=state[model]
	if not mode then
		if st then st.next=nil end
		return
	end
	if not st then st={foot=0};state[model]=st end
	if st.next and now<st.next then return end
	local stand=mode=="stand"
	st.next=now+(if stand then WallRunFX.STAND else (WallRunFX.STEP[mode] or .15))
	local parent=folderFor(model)
	local feet={}
	for _,name in {"LeftFoot","RightFoot","Left Leg","Right Leg"} do
		local p=model:FindFirstChild(name)
		if p and p:IsA("BasePart") then table.insert(feet,p) end
	end
	if #feet==0 then return end
	if stand then
		-- both soles, a slow soft pulse
		for _,foot in feet do
			local hit=surface(model,foot.Position,true)
			if hit then WallRunFX.mark(parent,hit.Position,hit.Normal,1.1,false) end
		end
		return
	end
	-- one foot per step, the two in turn: the one that takes the wall
	st.foot=(st.foot%#feet)+1
	local foot=feet[st.foot]
	local hit=surface(model,foot.Position,false)
	if hit then WallRunFX.mark(parent,hit.Position,hit.Normal,1.2,true) end
end

return WallRunFX
