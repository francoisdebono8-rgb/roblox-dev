-- Cartoon faces drawn in 2D on the head (user 29/10 14:07: "il manque une
-- expression faciale énorme"). Each eye and the mouth is a SurfaceGui on its
-- own invisible plate laid tangent to the round head, so the drawing hugs the
-- curve. The server builds the face (Face.build); the client drives it
-- (Face.set with an expression name, Face.blink, Face.tint for the
-- Sharingan / fox eyes). Nothing here touches gameplay.
local Face={}

-- The head the looks are built on (Server/Looks.form): the classic rounded
-- Head mesh, upright and round in plan, 0.9 in radius, straight-sided from
-- STRAIGHT below to STRAIGHT above the centre, rounding off beyond.
Face.Head=Vector3.new(.9,.93,.9)
Face.Radius=Face.Head.X
local STRAIGHT=.5
local PPS=320

local function new(class,props,parent)
	local i=Instance.new(class)
	for k,v in props do (i::any)[k]=v end
	if parent then i.Parent=parent end
	return i
end
local function round(parent,radius)
	return new("UICorner",{CornerRadius=UDim.new(radius or .5,0)},parent)
end

-- A plate tangent to the head at `angle` (degrees, + toward the fighter's
-- right) and height `y` (head space), facing out.
-- The squarer head of the Blender looks (tools/blender/nd_look.HEAD_PROFILE,
-- same numbers): (y, half-width, half-depth, squareness).
Face.BoxProfile={{-.95,.55,.56,2.6},{-.82,.74,.74,2.8},{-.55,.86,.83,3.2},{-.2,.9,.86,3.4},
	{.25,.9,.86,3.4},{.6,.86,.83,3.2},{.84,.72,.72,2.8},{.95,.45,.46,2.4}}
local SHAPE="can"
function Face.useShape(shape) SHAPE=shape or "can" end
function Face.boxSection(y)
	local P=Face.BoxProfile
	if y<=P[1][1] then return P[1][2],P[1][3],P[1][4] end
	for i=1,#P-1 do
		local a,b=P[i],P[i+1]
		if y<=b[1] then
			local t=(y-a[1])/(b[1]-a[1])
			return a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t,a[4]+(b[4]-a[4])*t
		end
	end
	local l=P[#P];return l[2],l[3],l[4]
end
local function onBox(angle,y,out)
	local hx,hz,n=Face.boxSection(y)
	local x=math.sin(math.rad(angle))*hx
	local t=math.min(.999,math.abs(x)/hx)
	local z=-hz*(1-t^n)^(1/n)
	local gx=math.sign(x)*t^(n-1)/hx
	local gz=-((math.abs(z)/hz)^(n-1))/hz
	local _,hz2=Face.boxSection(y+.02)
	local _,hz1=Face.boxSection(y-.02)
	local dbdy=(hz2-hz1)/.04
	local nrm=Vector3.new(gx,-dbdy*math.abs(gz),gz).Unit
	local p=Vector3.new(x,y,z)+nrm*(out or .006)
	return CFrame.lookAt(p,p+nrm)
end
function Face.onHead(angle,y,out)
	if SHAPE=="box" then return onBox(angle,y,out) end
	local h=Face.Head
	local a=math.rad(angle)
	local over=math.max(0,math.abs(y)-STRAIGHT)/(h.Y-STRAIGHT)
	local k=math.sqrt(math.max(0,1-over*over))
	local p=Vector3.new(h.X*k*math.sin(a),y,-h.Z*k*math.cos(a))
	local tilt=math.sign(y)*over
	local n=(Vector3.new(math.sin(a)*k,0,-math.cos(a)*k)+Vector3.new(0,tilt,0)).Unit
	p+=n*(out or .006)
	return CFrame.lookAt(p,p+n)
end
-- The angle (degrees) at which the head's surface is `x` studs off centre at
-- height `y`.
function Face.angleAt(x,y)
	if SHAPE=="box" then
		local hx=Face.boxSection(y)
		return math.deg(math.asin(math.clamp(x/hx,-1,1)))
	end
	local h=Face.Head
	local over=math.max(0,math.abs(y)-STRAIGHT)/(h.Y-STRAIGHT)
	local k=math.sqrt(math.max(.05,1-over*over))
	return math.deg(math.asin(math.clamp(x/(h.X*k),-1,1)))
end

local function plate(model,name,size,cf)
	local head=model:FindFirstChild("Head")
	if not head then return nil,nil end
	local p=new("Part",{Name=name,Size=Vector3.new(size.X,size.Y,.02),Transparency=1,CanCollide=false,CanQuery=false,CanTouch=false,
		Massless=true,Anchored=false,CastShadow=false,CFrame=head.CFrame*cf})
	new("WeldConstraint",{Part0=head,Part1=p},p)
	p.Parent=model
	local gui=new("SurfaceGui",{Name="Drawing",Face=Enum.NormalId.Front,SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud,PixelsPerStud=PPS,
		LightInfluence=.55,Brightness=1.15,ZOffset=1,ClipsDescendants=false,ResetOnSpawn=false},p)
	return p,gui
end

-- Positions and sizes in studs on a plate of size `w` x `h`, origin at its
-- centre, y down.
local function at(w,h,x,y) return UDim2.fromScale(.5+x/w,.5+y/h) end
local function sz(w,h,x,y) return UDim2.fromScale(x/w,y/h) end

local EW,EH=.62,.82 -- eye plate
local MW,MH=.7,.42 -- mouth plate

-- spec fields (all optional): iris, irisDark, pupil (false = none), style
-- ("normal" | "round" | "pale" | "ringed"), sclera (Vector2 studs), eyeX,
-- eyeY, brow (Color3, false = none), browThick, lash, skin, mood (the idle
-- expression), mouth (false = hidden), cheeks ("whiskers"), lids (0-1 resting
-- droop).
function Face.build(model,spec)
	spec=spec or {}
	-- Headless tests have no UI classes: the face is cosmetic, skip it.
	if UDim==nil or UDim2==nil or ColorSequence==nil or Vector2==nil then model:SetAttribute("FaceMood",spec.mood or "calm");return nil end
	local eyes=model:FindFirstChild("Eyes");if eyes then eyes.Transparency=1 end
	local lash=spec.lash or Color3.fromRGB(28,24,30)
	local sclera=spec.sclera or Vector2.new(.34,.3)
	local face={spec=spec,eyes={},model=model}
	local ex=spec.eyeX or .32
	local ey=spec.eyeY or -.06
	local eyeAngle=Face.angleAt(ex,ey)
	for _,s in {-1,1} do
		local part,gui=plate(model,"FaceEye",Vector2.new(EW,EH),Face.onHead(s*eyeAngle,ey))
		if not gui then continue end
		local e={side=s,part=part,gui=gui}
		-- The white: clipped so the lids and the look can cut the iris.
		e.white=new("CanvasGroup",{Name="White",AnchorPoint=Vector2.new(.5,.5),Position=at(EW,EH,0,0),Size=sz(EW,EH,sclera.X,sclera.Y),
			BackgroundColor3=Color3.fromRGB(250,250,246),BorderSizePixel=0},gui)
		round(e.white,.5)
		local iw=sclera.X*(if spec.style=="round" then .5 else .56)
		local ih=sclera.Y*(if spec.style=="round" then .62 else .8)
		e.iris=new("Frame",{Name="Iris",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.56),Size=UDim2.fromScale(iw/sclera.X,ih/sclera.Y),
			BackgroundColor3=spec.iris or Color3.fromRGB(70,110,200),BorderSizePixel=0},e.white)
		round(e.iris,.5)
		e.gradient=new("UIGradient",{Rotation=90,Color=ColorSequence.new(spec.irisDark or (spec.iris or Color3.fromRGB(70,110,200)):Lerp(Color3.new(),.45),spec.iris or Color3.fromRGB(70,110,200))},e.iris)
		if spec.style=="ringed" then new("UIStroke",{Thickness=3,Color=(spec.iris or Color3.new()):Lerp(Color3.new(),.5)},e.iris) end
		if spec.pupil~=false then
			e.pupil=new("Frame",{Name="Pupil",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromScale(.42,.42),
				BackgroundColor3=Color3.fromRGB(16,14,20),BorderSizePixel=0},e.iris)
			round(e.pupil,.5)
		end
		-- Sharingan commas, shown by Face.tint(..., "sharingan").
		e.tomoe={}
		for k=0,2 do
			local a=math.rad(k*120-90)
			local t=new("Frame",{Name="Tomoe",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5+.3*math.cos(a),.52+.3*math.sin(a)),Size=UDim2.fromScale(.2,.2),
				BackgroundColor3=Color3.fromRGB(16,10,12),BorderSizePixel=0,Visible=spec.sharingan==true},e.iris)
			round(t,.5)
			table.insert(e.tomoe,t)
		end
		e.shine=new("Frame",{Name="Shine",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.34,.3),Size=UDim2.fromScale(.32,.26),
			BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},e.iris)
		round(e.shine,.5)
		e.shine2=new("Frame",{Name="Shine",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.66,.74),Size=UDim2.fromScale(.14,.12),
			BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,BackgroundTransparency=.2},e.iris)
		round(e.shine2,.5)
		if spec.style=="pale" then
			e.iris.BackgroundColor3=spec.iris or Color3.fromRGB(226,222,240)
			e.gradient.Color=ColorSequence.new(Color3.fromRGB(200,196,224),spec.iris or Color3.fromRGB(236,232,248))
			e.shine.Visible=false;e.shine2.Visible=false
		end
		-- The dark ring Gaara never sleeps off.
		if spec.ring then
			e.ring=new("Frame",{Name="Ring",AnchorPoint=Vector2.new(.5,.5),Position=at(EW,EH,0,0),Size=sz(EW,EH,sclera.X+.08,sclera.Y+.09),BackgroundTransparency=1,ZIndex=0},gui)
			round(e.ring,.5)
			new("UIStroke",{Thickness=12,Color=spec.ring,Transparency=.05},e.ring)
		end
		-- The upper lash line and its flick at the outer corner.
		e.lash=new("Frame",{Name="Lash",AnchorPoint=Vector2.new(.5,.5),Size=sz(EW,EH,sclera.X*1.06,spec.lashThick or .05),BackgroundColor3=lash,BorderSizePixel=0,ZIndex=3},gui)
		round(e.lash,.5)
		e.flick=new("Frame",{Name="Flick",AnchorPoint=Vector2.new(.5,.5),Size=sz(EW,EH,.09,.04),BackgroundColor3=lash,BorderSizePixel=0,ZIndex=3},gui)
		round(e.flick,.5)
		-- The upper lid: skin over the top of the white, lowered to narrow the
		-- eye. It lives inside the white so it is clipped to its round shape.
		e.lid=new("Frame",{Name="Lid",AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromScale(.5,0),Size=UDim2.fromScale(1.3,1),
			Visible=false,BackgroundColor3=spec.skin or Color3.fromRGB(246,214,186),BorderSizePixel=0,ZIndex=2},e.white)
		-- Closed-eye strokes: a curve (blink, KO), a ^ (happy), a > (hurt).
		e.closed={}
		for k=1,2 do
			local c=new("Frame",{Name="Closed",AnchorPoint=Vector2.new(.5,.5),Size=sz(EW,EH,sclera.X*.62,.05),BackgroundColor3=lash,BorderSizePixel=0,Visible=false,ZIndex=3},gui)
			round(c,.5)
			e.closed[k]=c
		end
		if spec.brow~=false then
			e.brow=new("Frame",{Name="Brow",AnchorPoint=Vector2.new(.5,.5),Size=sz(EW,EH,sclera.X*(spec.browWide or 1.05),spec.browThick or .055),
				BackgroundColor3=spec.brow or lash,BorderSizePixel=0,ZIndex=4},gui)
			round(e.brow,.5)
		end
		-- Whisker marks on the cheek, below and outside the eye.
		if spec.cheeks=="whiskers" then
			for k=0,2 do
				local w=new("Frame",{Name="Whisker",AnchorPoint=Vector2.new(.5,.5),Position=at(EW,EH,s*-.06,.24+k*.07),Size=sz(EW,EH,.26,.022),
					Rotation=s*-(8-k*8),BackgroundColor3=Color3.fromRGB(96,62,48),BorderSizePixel=0},gui)
				round(w,.5)
			end
		end
		table.insert(face.eyes,e)
	end
	if spec.mouth~=false then
		local part,gui=plate(model,"FaceMouth",Vector2.new(MW,MH),Face.onHead(0,spec.mouthY or -.42))
		if gui then
			local m={part=part,gui=gui}
			local lip=spec.lip or Color3.fromRGB(110,56,52)
			-- A short line (calm), its curved version (smile), an open mouth
			-- with a tongue (shout, hurt), teeth (grin, grit).
			m.line=new("Frame",{Name="Line",AnchorPoint=Vector2.new(.5,.5),Position=at(MW,MH,0,0),Size=sz(MW,MH,.16,.028),BackgroundColor3=lip,BorderSizePixel=0},gui)
			round(m.line,.5)
			m.curveBox=new("Frame",{Name="Curve",AnchorPoint=Vector2.new(.5,0),Position=at(MW,MH,0,-.01),Size=sz(MW,MH,.3,.12),BackgroundTransparency=1,ClipsDescendants=true},gui)
			m.curve=new("Frame",{Name="Arc",AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromScale(.5,1),Size=UDim2.fromScale(.8,1.9),BackgroundTransparency=1},m.curveBox)
			round(m.curve,.5)
			m.curveStroke=new("UIStroke",{Thickness=8,Color=lip},m.curve)
			m.open=new("CanvasGroup",{Name="Open",AnchorPoint=Vector2.new(.5,.5),Position=at(MW,MH,0,.03),Size=sz(MW,MH,.22,.16),BackgroundColor3=Color3.fromRGB(86,26,32),BorderSizePixel=0},gui)
			round(m.open,.5)
			m.tongue=new("Frame",{Name="Tongue",AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.6),Size=UDim2.fromScale(.7,.6),BackgroundColor3=Color3.fromRGB(226,104,110),BorderSizePixel=0},m.open)
			round(m.tongue,.5)
			m.upper=new("Frame",{Name="Teeth",AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,0),Size=UDim2.fromScale(1,.26),BackgroundColor3=Color3.fromRGB(250,248,242),BorderSizePixel=0},m.open)
			m.teeth=new("Frame",{Name="Grit",AnchorPoint=Vector2.new(.5,.5),Position=at(MW,MH,0,.02),Size=sz(MW,MH,.24,.085),BackgroundColor3=Color3.fromRGB(250,248,242),BorderSizePixel=0},gui)
			round(m.teeth,.35)
			new("UIStroke",{Thickness=5,Color=lip},m.teeth)
			new("Frame",{Name="Gap",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-4,0,3),BackgroundColor3=lip:Lerp(Color3.new(1,1,1),.35),BorderSizePixel=0},m.teeth)
			face.mouth=m
		end
	end
	model:SetAttribute("FaceMood",spec.mood or "calm")
	model:SetAttribute("FaceLids",spec.lids or 0)
	Face.set(face,spec.mood or "calm")
	return face
end

-- Expressions: eye shape, brow, mouth.
--   eye  open | narrow | wide | closed | happy | squeeze | ko
--   brow calm | angry | worry | up | flat
--   mouth line | smile | smirk | grin | open | shout | grit | o | frown
Face.Moods={
	calm={eye="open",brow="calm",mouth="line"},
	cool={eye="narrow",brow="flat",mouth="line"},
	lazy={eye="lazy",brow="flat",mouth="line"},
	cheer={eye="open",brow="up",mouth="grin"},
	gentle={eye="open",brow="calm",mouth="smile"},
	smirk={eye="narrow",brow="flat",mouth="smirk"},
	stare={eye="narrow",brow="flat",mouth="line"},
	fierce={eye="open",brow="angry",mouth="grit"},
	fight={eye="narrow",brow="angry",mouth="grit"},
	focus={eye="narrow",brow="angry",mouth="line"},
	shout={eye="narrow",brow="angry",mouth="shout"},
	hurt={eye="squeeze",brow="worry",mouth="open"},
	stun={eye="wide",brow="worry",mouth="o"},
	ko={eye="ko",brow="worry",mouth="o"},
	win={eye="happy",brow="up",mouth="grin"},
}
local function look(face) return face end

function Face.find(model)
	local face={model=model,eyes={},spec={}}
	for _,p in model:GetChildren() do
		if p.Name=="FaceEye" then
			local gui=p:FindFirstChild("Drawing")
			if gui then
				local white=gui:FindFirstChild("White")
				local iris=white and white:FindFirstChild("Iris")
				local e={part=p,gui=gui,white=white,iris=iris,pupil=iris and iris:FindFirstChild("Pupil"),lid=white and white:FindFirstChild("Lid"),
					lash=gui:FindFirstChild("Lash"),flick=gui:FindFirstChild("Flick"),brow=gui:FindFirstChild("Brow"),ring=gui:FindFirstChild("Ring"),
					gradient=iris and iris:FindFirstChildOfClass("UIGradient"),closed={},tomoe={}}
				for _,c in gui:GetChildren() do if c.Name=="Closed" then table.insert(e.closed,c) end end
				if iris then for _,t in iris:GetChildren() do if t.Name=="Tomoe" then table.insert(e.tomoe,t) end end end
				e.side=if (model:FindFirstChild("Head") and (model.Head.CFrame:PointToObjectSpace(p.Position).X>0)) then 1 else -1
				table.insert(face.eyes,e)
			end
		elseif p.Name=="FaceMouth" then
			local gui=p:FindFirstChild("Drawing")
			if gui then
				local curveBox=gui:FindFirstChild("Curve")
				local open=gui:FindFirstChild("Open")
				face.mouth={part=p,gui=gui,line=gui:FindFirstChild("Line"),curveBox=curveBox,curve=curveBox and curveBox:FindFirstChild("Arc"),
					open=open,tongue=open and open:FindFirstChild("Tongue"),upper=open and open:FindFirstChild("Teeth"),teeth=gui:FindFirstChild("Grit")}
			end
		end
	end
	if #face.eyes==0 then return nil end
	return face
end

-- A frame's resting box, kept as attributes so a client that finds the face
-- (Face.find) reads the built size, not the narrowed one the server set.
local function restOf(obj)
	local size,pos=obj:GetAttribute("RestSize"),obj:GetAttribute("RestPos")
	if not size then
		size,pos=obj.Size,obj.Position
		obj:SetAttribute("RestSize",size);obj:SetAttribute("RestPos",pos)
	end
	return {size=size,pos=pos}
end
local function coverOf(eye,droop)
	return if eye=="narrow" then .3 elseif eye=="lazy" then .5 elseif eye=="wide" then 0 else droop
end
local function eyeShape(e,eye,brow,droop,browEye)
	local s=e.side
	local white=e.white
	if not white then return end
	-- The white's resting box, read back from its build size.
	e.base=e.base or restOf(white)
	local bx,by=e.base.size.X.Scale,e.base.size.Y.Scale
	local px,py=e.base.pos.X.Scale,e.base.pos.Y.Scale
	local open=eye=="open" or eye=="narrow" or eye=="wide" or eye=="lazy"
	white.Visible=open
	if e.ring then e.ring.Visible=true end
	-- Lid: how much of the white it covers (0 open .. 1 shut), and its slant.
	local cover=coverOf(eye,droop)
	local tilt=if brow=="angry" then 14 elseif brow=="worry" then -10 elseif brow=="flat" then 7 else 0
	local height=if eye=="wide" then by*1.12 else by
	-- A narrowed eye is a shorter white whose top edge comes down to the lash
	-- line (user 29/10 15:58: the skin-coloured lid drawn over the white is
	-- not clipped on a 3D face and showed as a pale box above the eye).
	local shown=height*(1-cover)
	white.Size=UDim2.fromScale(bx*(if eye=="wide" then 1.06 else 1),shown)
	white.Position=UDim2.fromScale(px,py+height*cover/2)
	if e.lid then e.lid.Visible=false end
	if e.ring then
		e.ringBase=e.ringBase or restOf(e.ring).size
		e.ring.Size=UDim2.fromScale(e.ringBase.X.Scale,e.ringBase.Y.Scale-height+shown)
		e.ring.Position=white.Position
	end
	if e.iris then
		e.irisBase=e.irisBase or restOf(e.iris)
		local ib=e.irisBase
		-- The iris keeps its size and place on the face; the shortened white
		-- trims its top (it slides down to sit inside).
		local ih=ib.size.Y.Scale*height
		local cy=py-height/2+ib.pos.Y.Scale*height
		local top=py-height/2+height*cover
		local h=math.min(ih,shown*.96)
		cy=math.max(cy,top+h/2)
		e.iris.Size=UDim2.fromScale(ib.size.X.Scale,h/math.max(shown,1e-3))
		e.iris.Position=UDim2.fromScale(.5,(cy-top)/math.max(shown,1e-3))
		if e.pupil then e.pupil.Size=if eye=="wide" then UDim2.fromScale(.26,.26) else UDim2.fromScale(.42,math.min(.9,.42*ih/h)) end
	end
	-- Lash line rides the lid edge.
	local top=py-height/2+height*cover
	if e.lash then
		e.lash.Visible=open
		e.lash.Position=UDim2.fromScale(px,top+.008)
		e.lash.Rotation=s*tilt
		e.flick.Visible=open
		e.flick.Position=UDim2.fromScale(px-s*bx*.52,top+.02)
		e.flick.Rotation=s*-24
	end
	-- Closed strokes.
	local c1,c2=e.closed[1],e.closed[2]
	if c1 and c2 then
		c1.Visible=not open;c2.Visible=false
		local w=bx*.62
		if eye=="closed" or eye=="ko" then
			c1.Position=UDim2.fromScale(px,py+.03);c1.Rotation=0;c1.Size=UDim2.fromScale(w*1.2,c1.Size.Y.Scale)
		elseif eye=="happy" then
			-- ^ : two strokes meeting above the eye's centre.
			c2.Visible=true
			c1.Size=UDim2.fromScale(w*.62,c1.Size.Y.Scale);c2.Size=c1.Size
			c1.Position=UDim2.fromScale(px-bx*.17,py+.02);c1.Rotation=-34
			c2.Position=UDim2.fromScale(px+bx*.17,py+.02);c2.Rotation=34
		elseif eye=="squeeze" then
			-- > < : the point toward the nose.
			c2.Visible=true
			c1.Size=UDim2.fromScale(w*.66,c1.Size.Y.Scale);c2.Size=c1.Size
			c1.Position=UDim2.fromScale(px-s*bx*.02,py-.018);c1.Rotation=s*-26
			c2.Position=UDim2.fromScale(px-s*bx*.02,py+.05);c2.Rotation=s*26
		end
	end
	if e.brow then
		local up=if brow=="up" then -.045 elseif brow=="worry" then -.03 elseif brow=="angry" then .035 elseif brow=="flat" then .015 else .012
		local angle=if brow=="angry" then 20 elseif brow=="worry" then -16 elseif brow=="up" then -4 elseif brow=="flat" then 7 else -3
		-- The brow sits just above the lid edge (user 29/10: no gap between
		-- brows and narrowed eyes); a blink keeps it where the mood put it.
		local lidTop=py-height/2+height*coverOf(browEye or eye,droop)
		e.brow.Position=UDim2.fromScale(px+s*.012,lidTop-.1/EH+up)
		e.brow.Rotation=s*angle
	end
end

local function mouthShape(m,mouth)
	if not m or not m.line then return end
	m.line.Visible=mouth=="line" or mouth=="frown"
	m.line.Rotation=0
	m.curveBox.Visible=mouth=="smile" or mouth=="smirk"
	m.curve.Rotation=0
	if mouth=="smirk" then m.curveBox.Rotation=-10;m.curveBox.Size=sz(MW,MH,.22,.1) else m.curveBox.Rotation=0;m.curveBox.Size=sz(MW,MH,.3,.12) end
	local open=mouth=="open" or mouth=="shout" or mouth=="o" or mouth=="grin"
	m.open.Visible=open
	if mouth=="shout" then m.open.Size=sz(MW,MH,.26,.22)
	elseif mouth=="grin" then m.open.Size=sz(MW,MH,.34,.15)
	elseif mouth=="o" then m.open.Size=sz(MW,MH,.1,.11)
	else m.open.Size=sz(MW,MH,.24,.13) end
	if m.upper then m.upper.Visible=mouth=="grin" or mouth=="shout";m.upper.Size=UDim2.fromScale(1,if mouth=="grin" then .42 else .26) end
	if m.tongue then m.tongue.Visible=mouth~="o" end
	m.teeth.Visible=mouth=="grit"
end

-- Apply an expression by name (Face.Moods) to a face from Face.build or
-- Face.find. Returns the face.
function Face.set(face,name,blink)
	if not face then return end
	local mood=Face.Moods[name] or Face.Moods.calm
	local eye=mood.eye
	if blink and (eye=="open" or eye=="narrow" or eye=="lazy" or eye=="wide") then eye="closed" end
	local droop=(face.spec and face.spec.lids) or 0
	if face.model then droop=face.model:GetAttribute("FaceLids") or droop end
	for _,e in face.eyes do eyeShape(e,eye,mood.brow,droop,mood.eye) end
	mouthShape(face.mouth,mood.mouth)
	face.current=name;face.blinking=blink
	return face
end

-- Iris colour override (nil restores): "sharingan" shows the commas.
function Face.tint(face,color,kind)
	if not face then return end
	for _,e in face.eyes do
		if not e.iris then continue end
		e.restore=e.restore or {color=e.iris.BackgroundColor3,gradient=e.gradient and e.gradient.Color}
		if color then
			e.iris.BackgroundColor3=color
			if e.gradient then e.gradient.Color=ColorSequence.new(color:Lerp(Color3.new(),.35),color) end
		else
			e.iris.BackgroundColor3=e.restore.color
			if e.gradient and e.restore.gradient then e.gradient.Color=e.restore.gradient end
		end
		for _,t in e.tomoe do t.Visible=color~=nil and kind=="sharingan" end
		if e.pupil then e.pupil.Size=if kind=="fox" then UDim2.fromScale(.16,.62) else UDim2.fromScale(.42,.42) end
		e.gui.LightInfluence=if color then .1 else .55
	end
end
Face.look=look
return Face
