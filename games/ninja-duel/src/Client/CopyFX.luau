-- (06/11, « le Sharingan qui copie ») Kakashi's copy on screen (Server/Copy).
-- The read: while the opponent weaves the jutsu in front of him, a thin red
-- line runs from Kakashi's left eye to the hands that make it, and three
-- tomoe turn round that eye; when it is his, a red glint. The copied cast:
-- the same glint and red sparks from his hand. His left eye stays lit while he
-- holds a copy (Effects, the Copycat face). One identity layer installed into
-- Effects. Presentation only.
local CopyFX={}
local K -- Effects' helpers, handed over by install()
CopyFX.clock=os.clock -- (headless tests drive time)
local RED=Color3.fromRGB(235,30,40)
local CORE=Color3.fromRGB(255,170,160)
local DARK=Color3.fromRGB(40,6,10)
-- The left eye of a head (its front is -Z, the body's left is -X).
local function eyeOf(model)
	local head=model and model:FindFirstChild("Head")
	if not head then return nil end
	local s=head.Size
	return head.CFrame*CFrame.new(-s.X*.2,s.Y*.08,-s.Z*.5)
end
local function handOf(model)
	local hand=model and (model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm"))
	return if hand then hand.Position else (model and model:GetPivot().Position)
end
-- The reads in progress: {holder, line, from, to, tomoe, ring, kakashi, caster, untilT, born}.
local reads={}
local function read(fx,impact,folder)
	local kakashi=folder and folder:FindFirstChild(impact.owner or "")
	local caster=folder and folder:FindFirstChild(impact.from or "")
	local eye=eyeOf(kakashi)
	if not eye then return true end
	local now=CopyFX.clock()
	local holder=K.new("Model",{Name="SharinganCopy"},fx.folder)
	-- The gaze: a thin beam, bright at the eye, fading toward the hands.
	local from=K.block(holder,Vector3.one*.05,eye,RED,Enum.Material.Neon);from.Transparency=1
	local to=K.block(holder,Vector3.one*.05,eye,RED,Enum.Material.Neon);to.Transparency=1
	local a0=K.new("Attachment",{},from);local a1=K.new("Attachment",{},to)
	local line=K.new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.09,Width1=.025,FaceCamera=true,Segments=1,LightEmission=1,LightInfluence=0,
		Color=ColorSequence.new(RED),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.6,.65),NumberSequenceKeypoint.new(1,.92)})},holder)
	local tomoe={}
	for k=1,3 do
		local ball=K.block(holder,Vector3.one*.11,eye,DARK,Enum.Material.Neon)
		ball.Shape=Enum.PartType.Ball
		tomoe[k]=ball
	end
	local ring=K.block(holder,Vector3.new(.03,.4,.4),eye,RED,Enum.Material.Neon,"Part")
	ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.5
	-- (Studio only, for filming: workspace.NDCopyHold = seconds holds the read.)
	local ok,hold=pcall(function() return workspace:GetAttribute("NDCopyHold") end)
	local last=if ok and type(hold)=="number" then hold else math.clamp(impact.channel or .3,.35,.7)
	table.insert(reads,{holder=holder,line=line,from=from,to=to,tomoe=tomoe,ring=ring,kakashi=kakashi,caster=caster,born=now,untilT=now+last})
	-- The moment it is his: a red glint at the eye.
	K.flash(holder,eye.Position,RED,.3,1.6,.18,.4)
	K.sound(K.anchorPart(fx.folder,eye.Position),K.SOUND.whoosh,.25,2.2)
	return true
end
local function frame(fx,data,dt,folder)
	if #reads==0 then return end
	local now=CopyFX.clock()
	for i=#reads,1,-1 do
		local r=reads[i]
		local eye=eyeOf(r.kakashi)
		local gone=not eye or not r.holder.Parent
		local t=now-r.born
		local fade=math.clamp((now-r.untilT)/.2,0,1)
		if gone or fade>=1 then
			if r.holder.Parent then r.holder:Destroy() end
			table.remove(reads,i)
		else
			r.from.CFrame=eye;r.to.CFrame=CFrame.new(handOf(r.caster) or eye.Position)
			r.line.Enabled=fade<.95
			-- Three tomoe turning round the eye, in the plane of the face.
			for k,ball in r.tomoe do
				local a=t*14+k*2*math.pi/3
				ball.CFrame=eye*CFrame.new(math.cos(a)*.24,math.sin(a)*.24,-.04)
				ball.Transparency=fade
			end
			r.ring.CFrame=eye*CFrame.Angles(0,math.rad(90),0)*CFrame.new(.03,0,0)
			r.ring.Transparency=.5+.5*fade
		end
	end
end
-- He casts the jutsu he copied: the glint again, red sparks from his hand.
local function cast(fx,impact,folder)
	local kakashi=folder and folder:FindFirstChild(impact.owner or "")
	local eye=eyeOf(kakashi)
	local hand=handOf(kakashi)
	if eye then K.flash(fx.folder,eye.Position,RED,.3,1.4,.16,.4) end
	if hand then
		K.burst(fx.folder,hand,{Texture=K.TEX.spark,Lifetime=NumberRange.new(.15,.35),Speed=NumberRange.new(8,16),SpreadAngle=Vector2.new(180,180),
			Color=ColorSequence.new(RED,CORE),LightEmission=1,Size=K.num({{0,.4},{1,0}}),Drag=5},14)
	end
	return true
end
local function impact(fx,data,folder)
	if data.style=="copy" then return read(fx,data,folder) end
	if data.style=="copycast" then return cast(fx,data,folder) end
	return false
end
function CopyFX.install(Effects,kit)
	K=kit
	table.insert(Effects.layers,{name="Copy",impact=impact,frame=frame})
end
return CopyFX
