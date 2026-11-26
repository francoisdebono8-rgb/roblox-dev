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
--
-- (DESIGN 20/11, step 1) v2: the lens closes in on the head, and the duel
-- changes the face itself, live (François 20/11: « c'est des têtes… des images
-- en live », the face that changes, no picture laid on it). HIT, GUARD BREAK,
-- KO, VICTORY, FOCUS, RAGE each set a mood of Shared/Face (FaceCam.MOOD) on
-- the face-cam's own copy of the drawn eyes and mouth; the fighter's real face
-- in the arena is left to its own moods. When it ends, the copy follows the
-- real face again.
local okF,Face=pcall(function() return require((game:GetService("ReplicatedStorage")::any).NinjaDuel.Face) end)
if not okF then Face=nil end
local FaceCam={}
FaceCam.__index=FaceCam

FaceCam.FOV=30
-- The lens: in front of the chest, a little above the eyes.
-- (v2) closer: the head fills the case
-- (DESIGN 26/11, seen in the game: a skin-coloured square) head and neck,
-- the hair's outline readable
FaceCam.DISTANCE=3.7
FaceCam.LIFT=.14
-- How often the eyes and the mouth are copied from the real face.
FaceCam.MIRROR=1/24
-- Parts further than this from the head are not filmed (a long weapon, a
-- cape: they would fill the case).
FaceCam.REACH=3.2
FaceCam.PLATES={FaceEye=true,FaceMouth=true}

-- ------------------------------------------------------------------ pure
-- (v2) The expression a fighter's view calls for, or nil (his own face).
-- `outcome`: "won" / "lost" at the result. The strongest first.
FaceCam.EXPRESSIONS={"hit","guardbreak","ko","victory","focus","rage"}
FaceCam.MOOD={hit="hurt",guardbreak="stun",ko="ko",victory="win",focus="focus",rage="shout"}
function FaceCam.expression(actor,outcome)
	if type(actor)~="table" then return nil end
	if outcome=="won" then return "victory" end
	if (actor.health or 1)<=0 or actor.state=="Defeated" or actor.state=="Lost" or outcome=="lost" then return "ko" end
	if actor.state=="Stunned" or actor.guardBroken then return "guardbreak" end
	if actor.reaction=="HitStun" or actor.reaction=="Knockback" or actor.reaction=="Knockdown" or actor.reaction=="Juggled" or actor.reaction=="WallSplat" then return "hit" end
	if (actor.awaken or 0)>0 or ((actor.maxHealth or 0)>0 and (actor.health or 0)<=actor.maxHealth*.25) then return "rage" end
	if actor.techCharge or actor.sealing then return "focus" end
	return nil
end

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
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then link(d.Part0,d.Part1)
		-- (26/11, passe 2, seen in the game: the player's body has no Motor6D but
		-- AnimationConstraints, its hair a RigidConstraint) joined by attachments
		elseif (d:IsA("AnimationConstraint") or d:IsA("RigidConstraint")) and d.Attachment0 and d.Attachment1 then
			link(d.Attachment0.Parent,d.Attachment1.Parent)
		end
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
	view.Ambient=Color3.fromRGB(205,195,185);view.LightColor=Color3.fromRGB(255,244,228);view.LightDirection=Vector3.new(-.35,-1,-.55)
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

-- (DESIGN 26/11, seen in the game) A Roblox head whose face the ViewportFrame
-- does not draw (a dynamic head: its face is in its SurfaceAppearance, a
-- smooth skin in the case) gets a manga face in ink over it — eyes, brows,
-- mouth — that takes the six expressions. A classic face (a Decal) is drawn
-- by Roblox and left alone, and so are the prodigies' plates.
function FaceCam.needsCartoon(head)
	if not head then return false end
	for _,d in head:GetChildren() do
		if d:IsA("Decal") and d.Transparency<1 and d.Texture~="" then return false end
	end
	return head:IsA("MeshPart") or head:FindFirstChildOfClass("FaceControls")~=nil
end
-- The cartoon's shapes for an expression (pure): eye ("dot", "closed", "x",
-- "wide", "happy", "narrow"), brow tilt (degrees, + = angry), mouth ("line",
-- "smile", "open", "o", "wave", "grit").
FaceCam.CARTOON={
	none={eye="dot",brow=0,mouth="line"},
	hit={eye="closed",brow=-12,mouth="wave"},
	guardbreak={eye="wide",brow=-18,mouth="o"},
	ko={eye="x",brow=0,mouth="wave"},
	victory={eye="happy",brow=-6,mouth="smile"},
	focus={eye="narrow",brow=16,mouth="line"},
	rage={eye="narrow",brow=26,mouth="grit"},
}
local INK=Color3.fromRGB(20,16,17)
local function bar(parent,name,size,pos,rot,color)
	local f=Instance.new("Frame");f.Name=name;f.BorderSizePixel=0;f.BackgroundColor3=color or INK;f.AnchorPoint=Vector2.new(.5,.5)
	f.Size=size;f.Position=pos;f.Rotation=rot or 0;f.Parent=parent
	return f
end
local function round(f) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(.5,0);c.Parent=f;return f end
-- Draws the face (in a holder sized to the head's front) for a shape set.
function FaceCam.drawCartoon(holder,shape)
	holder:ClearAllChildren()
	for side=-1,1,2 do
		local cx=.5+side*.2
		local eye=shape.eye
		if eye=="dot" or eye=="wide" then
			local w=if eye=="wide" then .2 else .14
			local white=round(bar(holder,"Eye",UDim2.fromScale(w,w*1.5),UDim2.fromScale(cx,.46),0,Color3.new(1,1,1)))
			local st=Instance.new("UIStroke");st.Thickness=3;st.Color=INK;st.Parent=white
			round(bar(white,"Pupil",UDim2.fromScale(.5,.5),UDim2.fromScale(.5,.55)))
		elseif eye=="closed" then
			bar(holder,"Eye",UDim2.fromScale(.13,.035),UDim2.fromScale(cx,.47),side*-18)
			bar(holder,"Eye",UDim2.fromScale(.13,.035),UDim2.fromScale(cx,.51),side*18)
		elseif eye=="x" then
			bar(holder,"Eye",UDim2.fromScale(.14,.035),UDim2.fromScale(cx,.48),45)
			bar(holder,"Eye",UDim2.fromScale(.14,.035),UDim2.fromScale(cx,.48),-45)
		elseif eye=="happy" then
			bar(holder,"Eye",UDim2.fromScale(.08,.035),UDim2.fromScale(cx-.03,.48),-35)
			bar(holder,"Eye",UDim2.fromScale(.08,.035),UDim2.fromScale(cx+.03,.48),35)
		else -- narrow
			bar(holder,"Eye",UDim2.fromScale(.17,.07),UDim2.fromScale(cx,.49),0)
		end
		bar(holder,"Brow",UDim2.fromScale(.21,.065),UDim2.fromScale(cx,.33),side*shape.brow)
	end
	local m=shape.mouth
	if m=="line" then bar(holder,"Mouth",UDim2.fromScale(.24,.05),UDim2.fromScale(.5,.72))
	elseif m=="smile" then
		local o=round(bar(holder,"Mouth",UDim2.fromScale(.26,.12),UDim2.fromScale(.5,.72),0,Color3.fromRGB(120,20,24)))
		round(bar(o,"Tongue",UDim2.fromScale(.5,.4),UDim2.fromScale(.5,.75),0,Color3.fromRGB(230,90,90)))
	elseif m=="open" or m=="grit" then
		local o=bar(holder,"Mouth",UDim2.fromScale(.3,.14),UDim2.fromScale(.5,.72),0,if m=="grit" then Color3.new(1,1,1) else Color3.fromRGB(120,20,24))
		local st=Instance.new("UIStroke");st.Thickness=2;st.Color=INK;st.Parent=o
		if m=="grit" then bar(o,"Teeth",UDim2.new(1,0,0,2),UDim2.fromScale(.5,.5)) end
	elseif m=="o" then
		local o=round(bar(holder,"Mouth",UDim2.fromScale(.1,.12),UDim2.fromScale(.5,.73),0,Color3.fromRGB(120,20,24)))
		local st=Instance.new("UIStroke");st.Thickness=2;st.Color=INK;st.Parent=o
	else -- wave
		bar(holder,"Mouth",UDim2.fromScale(.09,.03),UDim2.fromScale(.45,.72),20)
		bar(holder,"Mouth",UDim2.fromScale(.09,.03),UDim2.fromScale(.55,.72),-20)
	end
end

function FaceCam:clear()
	for _,c in self.copies do if c.copy then c.copy:Destroy() end end
	for _,p in self.plates do if p.holder then p.holder:Destroy() end end
	if self.cartoon then self.cartoon:Destroy();self.cartoon=nil end
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
	-- (26/11) no plates and a face Roblox won't draw: the manga face
	local head=model:FindFirstChild("Head")
	if #self.plates==0 and FaceCam.needsCartoon(head) then
		local holder=Instance.new("Frame")
		holder.Name="Cartoon";holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(.5,.5)
		holder.ZIndex=self.overlay.ZIndex+1;holder.Parent=self.overlay
		self.cartoon=holder;self.cartoonShape=nil
	end
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

-- (v2) The face-cam's copy of the drawn face, as a Shared/Face face.
function FaceCam:copyFace()
	local face={eyes={},spec={}}
	local head=self.model and self.model:FindFirstChild("Head")
	for _,plate in self.plates do
		local gui=plate.holder
		if plate.part.Name=="FaceEye" then
			local white=gui:FindFirstChild("White")
			local iris=white and white:FindFirstChild("Iris")
			local e={part=plate.part,gui=gui,white=white,iris=iris,pupil=iris and iris:FindFirstChild("Pupil"),lid=white and white:FindFirstChild("Lid"),
				lash=gui:FindFirstChild("Lash"),flick=gui:FindFirstChild("Flick"),brow=gui:FindFirstChild("Brow"),ring=gui:FindFirstChild("Ring"),closed={},tomoe={}}
			for _,c in gui:GetChildren() do if c.Name=="Closed" then table.insert(e.closed,c) end end
			e.side=if head and head.CFrame:PointToObjectSpace(plate.part.Position).X>0 then 1 else -1
			table.insert(face.eyes,e)
		else
			local curveBox=gui:FindFirstChild("Curve")
			local open=gui:FindFirstChild("Open")
			face.mouth={part=plate.part,gui=gui,line=gui:FindFirstChild("Line"),curveBox=curveBox,curve=curveBox and curveBox:FindFirstChild("Arc"),
				open=open,tongue=open and open:FindFirstChild("Tongue"),upper=open and open:FindFirstChild("Teeth"),teeth=gui:FindFirstChild("Grit")}
		end
	end
	return face
end

-- (v2) The expression shown (nil: his own face). Held at least .45 s so a
-- quick flicker reads.
function FaceCam:express(name,now)
	now=now or os.clock()
	if name==nil and self.expression and now<(self.expressionUntil or 0) then return end
	if name==self.expression then return end
	self.expression=name
	self.expressionUntil=now+.45
	for _,plate in self.plates do self:draw(plate) end -- back to the real face's drawing
	if name and Face and #self.plates>0 then
		pcall(Face.set,self:copyFace(),FaceCam.MOOD[name])
	end
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
	-- the manga face on the head's front, turned with it
	if self.cartoon then
		local front=head.CFrame*CFrame.new(0,0,-head.Size.Z*.5)
		local x,y,perStud,seen=FaceCam.project(lens,FaceCam.FOV,size,front.Position)
		local toLens=(lens.Position-head.Position)
		seen=seen and head.CFrame.LookVector:Dot(toLens.Unit)>.15
		self.cartoon.Visible=seen
		if seen then
			self.cartoon.Position=UDim2.fromOffset(x,y)
			self.cartoon.Size=UDim2.fromOffset(head.Size.X*perStud,head.Size.Y*perStud)
			self.cartoon.Rotation=FaceCam.roll(head,lens)
			local shape=self.expression or "none"
			if shape~=self.cartoonShape then
				self.cartoonShape=shape
				FaceCam.drawCartoon(self.cartoon,FaceCam.CARTOON[shape] or FaceCam.CARTOON.none)
			end
		end
	end
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
			if mirror and not self.expression then
				local ok,same=pcall(FaceCam.mirror,plate.drawing,plate.holder)
				if ok and not same then self:draw(plate) end
			end
		end
	end
	return true
end

return FaceCam
