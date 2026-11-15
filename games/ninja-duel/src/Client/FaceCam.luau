-- The face-cam of the duel's HUD (HUD v3, DESIGN validated 14/11: « chaque
-- combattant a une case en haut qui filme en direct la tête de son perso »;
-- François 15/11: « on peut pas avoir une image animée du visage ? »).
--
-- A ViewportFrame films a copy of the fighter's head (with its hair, its
-- accessories and the top of the torso), moved every frame to where the real
-- one is, from a lens set in front of his chest: a blow that snaps the head,
-- a guard broken, a K.O., all show. A ViewportFrame draws parts, meshes and
-- decals (a Roblox avatar's own face is a decal: it shows as is) but not the
-- SurfaceGuis that draw the prodigies' cartoon eyes and mouth (Shared/Face).
-- Those are drawn again over the picture: each eye and the mouth is copied
-- once into a 2D frame laid where its plate is seen through the lens, and its
-- drawing (the lids, the look, the mouth's shape: Face.set) is mirrored from
-- the real one several times a second. A plate turned away from the lens is
-- hidden. Presentation only, on this client.
local FaceCam={}
FaceCam.__index=FaceCam

FaceCam.FOV=30
-- The lens: in front of the chest, a little above the eyes.
FaceCam.DISTANCE=4
FaceCam.LIFT=.2
-- How often the eyes and the mouth are copied from the real face.
FaceCam.MIRROR=1/24
-- Parts further than this from the head are not filmed (a long weapon, a
-- cape: they would fill the case).
FaceCam.REACH=3.2
FaceCam.PLATES={FaceEye=true,FaceMouth=true}

-- ------------------------------------------------------------------ pure
-- The parts that make the head seen: the head, everything joined to it (hair,
-- accessories, the face's own pieces but its drawing plates), what is joined
-- to those (a hair band on a hair base), and the upper torso under it.
function FaceCam.collect(model)
	local head=model and model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return {} end
	local links={}
	local function link(a,b)
		if not (a and b) then return end
		links[a]=links[a] or {};table.insert(links[a],b)
		links[b]=links[b] or {};table.insert(links[b],a)
	end
	for _,d in model:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then link(d.Part0,d.Part1) end
	end
	local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	local seen={[head]=true}
	local list={head}
	local queue={head}
	while #queue>0 do
		local part=table.remove(queue,1)
		for _,other in links[part] or {} do
			if not seen[other] and other:IsA("BasePart") then
				seen[other]=true
				local near=(other.CFrame.Position-head.CFrame.Position).Magnitude<=FaceCam.REACH
				-- the torso shows, but what hangs from it (the arms) does not
				if other==torso then table.insert(list,other)
				elseif near and other.Name~="HumanoidRootPart" and not FaceCam.PLATES[other.Name] then
					table.insert(list,other);table.insert(queue,other)
				end
			end
		end
	end
	return list
end

-- The lens for a head: in front of the chest (the torso's front, the head's
-- when there is no torso), looking at the face.
function FaceCam.lens(head,torso)
	local front=(torso or head).CFrame.LookVector
	front=Vector3.new(front.X,0,front.Z)
	if front.Magnitude<1e-3 then front=Vector3.new(0,0,-1) end
	front=front.Unit
	local target=head.CFrame.Position
	local at=target+front*FaceCam.DISTANCE+Vector3.new(0,FaceCam.LIFT,0)
	return CFrame.lookAt(at,target-Vector3.new(0,.08,0))
end

-- Where a point of the world is seen in a picture of `size` (pixels) filmed
-- by `lens` with a vertical field of view `fov` (degrees): x, y in pixels from
-- the top left, the pixels per stud at its depth, and whether it is in front.
function FaceCam.project(lens,fov,size,point)
	local local_=lens:PointToObjectSpace(point)
	local depth=-local_.Z
	if depth<=1e-3 then return 0,0,0,false end
	local tanH=math.tan(math.rad(fov)/2)
	local aspect=size.X/math.max(size.Y,1)
	local x=(.5+.5*(local_.X/depth)/(tanH*aspect))*size.X
	local y=(.5-.5*(local_.Y/depth)/tanH)*size.Y
	local perStud=size.Y/(2*depth*tanH)
	return x,y,perStud,true
end

-- Whether a face plate looks toward the lens (its drawing is on its front).
function FaceCam.facing(plate,lens)
	local toLens=(lens.Position-plate.CFrame.Position)
	if toLens.Magnitude<1e-3 then return false end
	return plate.CFrame.LookVector:Dot(toLens.Unit)>.2
end

-- The head's roll as the lens sees it, in degrees for a GUI's Rotation. A
-- drawing on a plate's front reads left to right along the plate's -X seen
-- from in front of it.
function FaceCam.roll(plate,lens)
	local right=lens:VectorToObjectSpace(-plate.CFrame.RightVector)
	return -math.deg(math.atan2(right.Y,right.X))
end

-- What is copied from a drawing to its copy, by class.
local PROPS={
	Frame={"Visible","Size","Position","Rotation","AnchorPoint","BackgroundColor3","BackgroundTransparency"},
	CanvasGroup={"Visible","Size","Position","Rotation","AnchorPoint","BackgroundColor3","BackgroundTransparency","GroupTransparency","GroupColor3"},
	ImageLabel={"Visible","Size","Position","Rotation","AnchorPoint","BackgroundTransparency","ImageColor3","ImageTransparency"},
	TextLabel={"Visible","Size","Position","Rotation","Text","TextColor3","TextTransparency"},
	UIGradient={"Color","Rotation","Offset","Transparency","Enabled"},
	UIStroke={"Color","Transparency","Thickness","Enabled"},
	UICorner={"CornerRadius"},
}
FaceCam.PROPS=PROPS
-- Copies the drawing `source` onto `copy` (same shape: a copy of it). Returns
-- false when their shapes differ (a Sharingan drawn since: copy it again).
function FaceCam.mirror(source,copy)
	local a,b=source:GetDescendants(),copy:GetDescendants()
	if #a~=#b then return false end
	for i,from in a do
		local to=b[i]
		if from.ClassName~=to.ClassName then return false end
		for _,prop in PROPS[from.ClassName] or {} do
			local value=(from::any)[prop]
			if (to::any)[prop]~=value then (to::any)[prop]=value end
		end
	end
	return true
end

-- ------------------------------------------------------------------ the case
function FaceCam.new(parent)
	local self=setmetatable({},FaceCam)
	local view=Instance.new("ViewportFrame")
	view.Name="FaceCam";view.Size=UDim2.fromScale(1,1);view.BackgroundTransparency=1;view.BorderSizePixel=0
	view.Ambient=Color3.fromRGB(150,140,135);view.LightColor=Color3.fromRGB(255,244,228);view.LightDirection=Vector3.new(-.35,-1,-.55)
	view.ZIndex=(parent.ZIndex or 1)+1
	view.Parent=parent
	local lens=Instance.new("Camera");lens.FieldOfView=FaceCam.FOV;lens.Parent=view
	view.CurrentCamera=lens
	local overlay=Instance.new("Frame")
	overlay.Name="FaceDrawing";overlay.Size=UDim2.fromScale(1,1);overlay.BackgroundTransparency=1;overlay.ClipsDescendants=true
	overlay.ZIndex=view.ZIndex+1
	overlay.Parent=parent
	self.view,self.lens,self.overlay,self.parent=view,lens,overlay,parent
	self.copies={};self.plates={}
	self.mirrorAt=0
	return self
end

function FaceCam:clear()
	for _,c in self.copies do if c.copy then c.copy:Destroy() end end
	for _,p in self.plates do if p.holder then p.holder:Destroy() end end
	self.copies={};self.plates={};self.model=nil
end

-- A part's copy for the picture: no joints, no scripts, no drawings, anchored.
local function still(part)
	local copy=part:Clone()
	for _,d in copy:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("SurfaceGui") or d:IsA("BillboardGui")
			or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Attachment") then d:Destroy() end
	end
	copy.Anchored=true;copy.CanCollide=false;copy.CanQuery=false;copy.CanTouch=false
	return copy
end

-- The model filmed (nil: nothing). Rebuilt when it changes.
function FaceCam:watch(model)
	if model==self.model and model~=nil and model.Parent then return end
	self:clear()
	self.model=model
	if not model then return end
	for _,part in FaceCam.collect(model) do
		local ok,copy=pcall(still,part)
		if ok and copy then copy.Parent=self.view;table.insert(self.copies,{part=part,copy=copy}) end
	end
	for _,p in model:GetChildren() do
		if FaceCam.PLATES[p.Name] and p:IsA("BasePart") then
			local drawing=p:FindFirstChild("Drawing")
			if drawing then table.insert(self.plates,{part=p,drawing=drawing}) end
		end
	end
	for _,plate in self.plates do self:draw(plate) end
end

-- One plate's drawing, copied into a frame of the overlay.
function FaceCam:draw(plate)
	if plate.holder then plate.holder:Destroy() end
	local holder=Instance.new("Frame")
	holder.Name="Plate";holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(.5,.5)
	holder.ZIndex=self.overlay.ZIndex+1
	for _,child in plate.drawing:GetChildren() do
		local ok,copy=pcall(function() return child:Clone() end)
		if ok and copy then copy.Parent=holder end
	end
	holder.Parent=self.overlay
	plate.holder=holder
end

-- Every frame: the copies where the real parts are, the lens, the drawings.
function FaceCam:step(now)
	local model=self.model
	local head=model and model:FindFirstChild("Head")
	if not head then self.view.Visible=false;self.overlay.Visible=false;return false end
	self.view.Visible=true;self.overlay.Visible=true
	for _,c in self.copies do
		if c.part.Parent then c.copy.CFrame=c.part.CFrame;c.copy.Transparency=c.part.Transparency end
	end
	local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	local lens=FaceCam.lens(head,torso)
	self.lens.CFrame=lens
	local size=self.view.AbsoluteSize
	local mirror=now>=self.mirrorAt
	if mirror then self.mirrorAt=now+FaceCam.MIRROR end
	for _,plate in self.plates do
		local part=plate.part
		local x,y,perStud,front=FaceCam.project(lens,FaceCam.FOV,size,part.CFrame.Position)
		local shown=front and part.Parent~=nil and FaceCam.facing(part,lens)
		plate.holder.Visible=shown
		if shown then
			plate.holder.Position=UDim2.fromOffset(x,y)
			plate.holder.Size=UDim2.fromOffset(part.Size.X*perStud,part.Size.Y*perStud)
			plate.holder.Rotation=FaceCam.roll(part,lens)
			if mirror then
				local ok,same=pcall(FaceCam.mirror,plate.drawing,plate.holder)
				if ok and not same then self:draw(plate) end
			end
		end
	end
	return true
end

return FaceCam
