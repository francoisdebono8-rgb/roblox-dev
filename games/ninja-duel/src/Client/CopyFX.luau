-- (06/11, « le Sharingan qui copie ») Kakashi's copy on screen (Server/Copy).
-- The read: while the opponent weaves the jutsu in front of him, a thin red
-- line runs from Kakashi's left eye to the hands that make it, and three
-- tomoe turn round that eye; when it is his, a red glint. The copied cast:
-- the same glint and red sparks from his hand. His left eye stays lit while he
-- holds a copy (Effects, the Copycat face). One identity layer installed into
-- Effects. Presentation only.
local CopyFX={}
local K -- Effects' helpers, handed over by install()
local Face=require(game:GetService("ReplicatedStorage").NinjaDuel.Face)
-- (13/11, issue #73) The read must read in a vertical medium shot (8 studs):
-- the gaze is a thin red line with a soft glow round it, and the Sharingan
-- itself appears big at his eye for the read (a drawn eye of BIG studs, the
-- commas turning: Face.drawSharingan, the count of Face.SHARINGAN.Copycat),
-- the anime's close-up on the eye without cutting the shot.
CopyFX.BIG=1.15
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
	local line=K.new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.13,Width1=.035,FaceCamera=true,Segments=1,LightEmission=1,LightInfluence=0,
		Color=ColorSequence.new(CORE,RED),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.6,.55),NumberSequenceKeypoint.new(1,.9)})},holder)
	-- its glow: wider, fainter, the same fade
	K.new("Beam",{Attachment0=a0,Attachment1=a1,Width0=.5,Width1=.12,FaceCamera=true,Segments=1,LightEmission=1,LightInfluence=0,
		Color=ColorSequence.new(RED),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(.6,.82),NumberSequenceKeypoint.new(1,.97)})},holder)
	-- The eye, big: red iris, dark ring, the commas turning (a billboard at the eye).
	local tomoe=nil
	local board=K.new("BillboardGui",{Name="SharinganRead",Adornee=from,Size=UDim2.fromScale(.2,.2),LightInfluence=0,AlwaysOnTop=false,MaxDistance=160},holder)
	local disc=K.new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),BackgroundColor3=RED,BorderSizePixel=0},board)
	K.new("UICorner",{CornerRadius=UDim.new(.5,0)},disc)
	K.new("UIStroke",{Thickness=2,Color=DARK,Transparency=.1},disc)
	local pupil=K.new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.22,.22),BackgroundColor3=DARK,BorderSizePixel=0,ZIndex=3},disc)
	K.new("UICorner",{CornerRadius=UDim.new(.5,0)},pupil)
	local drawing=Face.drawSharingan(disc,Face.tomoeFor("Copycat",false))
	drawing.Visible=true
	local ring=board
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
			-- The big eye: it opens in .12 s, the commas turn, it fades with the read.
			local open=math.clamp(t/.12,0,1)
			local k=CopyFX.BIG*(.25+.75*(1-(1-open)^3))*(1-.4*fade)
			r.ring.Size=UDim2.fromScale(k,k)
			local disc=r.ring:FindFirstChildOfClass("Frame")
			if disc then
				disc.BackgroundTransparency=fade
				local drawing=disc:FindFirstChild("Sharingan")
				if drawing then drawing.Rotation=t*420 end
				for _,d in disc:GetDescendants() do
					if d:IsA("Frame") then
						if d:GetAttribute("Base")==nil then d:SetAttribute("Base",d.BackgroundTransparency) end
						d.BackgroundTransparency=math.max(d:GetAttribute("Base"),fade)
					end
					if d:IsA("UIStroke") then d.Transparency=math.max(.1,fade) end
				end
			end
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
