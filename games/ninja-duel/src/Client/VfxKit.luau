-- Presentation primitives on the project's own VFX textures
-- (tools/vfx_textures.py -> assets/vfx -> uploaded image ids below).
--
-- Cel-shaded fire and smoke flipbooks, ground cracks and scorch, an impact
-- star, a crescent slash, a shock ring, spark streaks and lightning. Every
-- helper degrades to a built-in Roblox texture (or to nothing) when an id is
-- not set, so the game never depends on an upload to run.
-- Presentation only: nothing here can change gameplay.
-- Uploaded ids feed real ParticleEmitters. Without them the packed textures
-- live in EditableImages, which a Decal or an ImageLabel can show but a
-- ParticleEmitter cannot (Studio, 2026-10-26: an emitter with EditableImage
-- content renders nothing): bursts and streams are then drawn by the small
-- sprite system below (billboards stepped on RenderStepped), with the same
-- property names as an emitter.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Kit={}

-- Uploaded image ids (rbxassetid://...). Empty: the built-in fallback is used.
Kit.IDS={
	fire="",      -- nd_fire_flip.png   4x4 flipbook, colours baked in
	smoke="",     -- nd_smoke_flip.png  4x4 flipbook, grey cel tones (tinted)
	crack="",     -- nd_crack.png       radial web of cracks (dark)
	scorch="",    -- nd_scorch.png      radial burn streaks (dark)
	star="",      -- nd_star.png        impact star (white)
	slash="",     -- nd_slash.png       crescent arc (white)
	ring="",      -- nd_ring.png        shock ring (white)
	streak="",    -- nd_streak.png      spark streak (white)
	lightning="", -- nd_lightning_flip.png 2x2 flipbook (white)
}
local BUILTIN={
	fire="rbxasset://textures/particles/fire_main.dds",
	smoke="rbxasset://textures/particles/smoke_main.dds",
	star="rbxasset://textures/particles/sparkles_main.dds",
	streak="rbxasset://textures/particles/sparkles_main.dds",
	ring="rbxasset://textures/particles/explosion01_shockwave_main.dds",
	lightning="rbxasset://textures/particles/sparkles_main.dds",
}
local FLIP={fire=Enum.ParticleFlipbookLayout.Grid4x4,smoke=Enum.ParticleFlipbookLayout.Grid4x4,lightning=Enum.ParticleFlipbookLayout.Grid2x2}
local GRID={fire=4,smoke=4,lightning=2}
local dims={}

-- Where a texture comes from, best first: an uploaded id, else the packed
-- copy decoded once into an EditableImage (Client/VfxAtlas), else nothing
-- (the built-in fallback). `has` says whether our own art is available.
local runtime={}
local tried={}
local B64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local DIGIT={}
for i=1,#B64 do DIGIT[string.byte(B64,i)]=i-1 end
-- Palette + run-length text (tools/vfx_textures.py --pack) -> RGBA8 buffer.
function Kit.decode(entry)
	local w,h=entry.w,entry.h
	local pal=entry.pal
	local colours={}
	for i=0,#pal/4-1 do
		local r,g,b,a=pal[i*4+1],pal[i*4+2],pal[i*4+3],pal[i*4+4]
		colours[i]=r+g*256+b*65536+a*16777216
	end
	local out=buffer.create(w*h*4)
	local data=entry.data
	local n=#data
	local i,at=1,0
	local total=w*h
	while i<=n and at<total do
		local c=DIGIT[string.byte(data,i)]
		i+=1
		if c then
			local run,shift=0,0
			while true do
				local v=DIGIT[string.byte(data,i)]
				i+=1
				if v then
					run+=bit32.lshift(bit32.band(v,31),shift);shift+=5
					if bit32.band(v,32)==0 then break end
				end
			end
			local colour=colours[c] or 0
			for k=at,math.min(total-1,at+run) do buffer.writeu32(out,k*4,colour) end
			at+=run+1
		end
	end
	return out,w,h
end
local function editable(name)
	if tried[name] then return runtime[name] end
	tried[name]=true
	local ok,result=pcall(function()
		local atlas=require(script.Parent.VfxAtlas)
		local entry=atlas[name]
		if not entry then return nil end
		local pixels,w,h=Kit.decode(entry)
		local image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(w,h)})
		if not image then return nil end
		image:WritePixelsBuffer(Vector2.zero,Vector2.new(w,h),pixels)
		dims[name]=Vector2.new(w,h)
		return Content.fromObject(image)
	end)
	runtime[name]=if ok then result else nil
	return runtime[name]
end
function Kit.has(name)
	if (Kit.IDS[name] or "")~="" then return true end
	return editable(name)~=nil
end
-- True when this texture can only be drawn as sprites (no uploaded id).
function Kit.spriteOnly(name)
	return (Kit.IDS[name] or "")=="" and editable(name)~=nil
end
-- The texture as Content (assign to TextureContent).
function Kit.content(name)
	if not Content then return nil end
	local id=Kit.IDS[name]
	if id and id~="" then return Content.fromUri(id) end
	local image=editable(name)
	if image then return image end
	return Content.fromUri(BUILTIN[name] or BUILTIN.star)
end
-- Build every texture now (a frame of work at load, none mid-fight).
function Kit.warm()
	for name in Kit.IDS do Kit.has(name) end
end

local function new(class,props,parent)
	local x=Instance.new(class)
	for k,v in props do x[k]=v end
	if parent then x.Parent=parent end
	return x
end
Kit.new=new
local function tween(object,time,goal,style,direction)
	local t=TweenService:Create(object,TweenInfo.new(time,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),goal)
	t:Play();return t
end
Kit.tween=tween
function Kit.seq(points)
	local keys={}
	for _,p in points do table.insert(keys,ColorSequenceKeypoint.new(p[1],p[2])) end
	return ColorSequence.new(keys)
end
function Kit.num(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local seq,num=Kit.seq,Kit.num

local function holder(parent,position,life)
	local p=new("Part",{Name="FXAnchor",Size=Vector3.new(.2,.2,.2),CFrame=CFrame.new(position),Transparency=1,
		Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false},parent)
	Debris:AddItem(p,life or 4)
	return p
end
Kit.holder=holder

-- ------------------------------------------------------------------ sprites
local function evalNum(v,u)
	if type(v)=="number" then return v end
	if typeof(v)~="NumberSequence" then return 0 end
	local k=v.Keypoints
	for i=1,#k-1 do
		local a,b=k[i],k[i+1]
		if u<=b.Time then
			local t=if b.Time>a.Time then (u-a.Time)/(b.Time-a.Time) else 1
			return a.Value+(b.Value-a.Value)*t
		end
	end
	return k[#k].Value
end
local function evalColor(v,u)
	if typeof(v)=="Color3" then return v end
	if typeof(v)~="ColorSequence" then return Color3.new(1,1,1) end
	local k=v.Keypoints
	for i=1,#k-1 do
		local a,b=k[i],k[i+1]
		if u<=b.Time then
			local t=if b.Time>a.Time then (u-a.Time)/(b.Time-a.Time) else 1
			return a.Value:Lerp(b.Value,t)
		end
	end
	return k[#k].Value
end
local function range(r,default)
	if typeof(r)=="NumberRange" then return r.Min+(r.Max-r.Min)*math.random() end
	return r or default
end
local live={}
local streams={}
local origin
local stepping=false
local function originPart()
	if origin and origin.Parent then return origin end
	origin=Instance.new("Part")
	origin.Name="FXSpriteOrigin";origin.Anchored=true;origin.CanCollide=false;origin.CanQuery=false;origin.CanTouch=false
	origin.Transparency=1;origin.Size=Vector3.new(.2,.2,.2);origin.CFrame=CFrame.new()
	origin.Parent=workspace
	return origin
end
-- A direction inside the emission cone (half-angle `spread` degrees round `axis`).
local function coneDirection(axis,spread)
	local tilt=math.rad(math.min(spread,180))*math.sqrt(math.random())
	local spin=math.random()*math.pi*2
	local up=if math.abs(axis.Y)>.95 then Vector3.xAxis else Vector3.yAxis
	local side=axis:Cross(up).Unit
	local other=side:Cross(axis).Unit
	return (axis*math.cos(tilt)+(side*math.cos(spin)+other*math.sin(spin))*math.sin(tilt)).Unit
end
local stepAll
local function ensureStep()
	if stepping then return end
	stepping=true
	game:GetService("RunService").RenderStepped:Connect(function(dt) stepAll(dt) end)
end
-- One sprite: a billboard on the shared origin, an image (a flipbook cell).
local function spawnSprite(name,position,direction,props)
	local content=Kit.content(name)
	if not content then return end
	local size=props.Size or NumberSequence.new(1)
	local gui=Instance.new("BillboardGui")
	gui.Name="FXSprite";gui.Adornee=originPart();gui.LightInfluence=0;gui.ResetOnSpawn=false
	gui.Size=UDim2.fromScale(1,1);gui.StudsOffsetWorldSpace=position
	gui.Brightness=1+(props.LightEmission or 0)*1.5
	local img=Instance.new("ImageLabel")
	img.BackgroundTransparency=1;img.Size=UDim2.fromScale(1,1);img.ImageContent=content
	img.AnchorPoint=Vector2.new(.5,.5);img.Position=UDim2.fromScale(.5,.5)
	local grid=GRID[name]
	local dim=dims[name] or Vector2.new(256,256)
	local frames,frame0=nil,0
	if grid then
		img.ImageRectSize=dim/grid
		frames=grid*grid
		if props.FlipbookMode==Enum.ParticleFlipbookMode.Random then frame0=math.random(0,frames-1) end
	end
	img.Parent=gui
	local spread=if typeof(props.SpreadAngle)=="Vector2" then math.max(props.SpreadAngle.X,props.SpreadAngle.Y) else 0
	local dir=if spread>0 then coneDirection(direction,spread) else direction
	local s={gui=gui,img=img,pos=position,vel=dir*range(props.Speed,0),age=0,life=math.max(.02,range(props.Lifetime,1)),
		size=size,trans=props.Transparency or 0,color=props.Color or Color3.new(1,1,1),drag=props.Drag or 0,
		accel=props.Acceleration or Vector3.zero,rot=range(props.Rotation,0),spin=range(props.RotSpeed,0),
		frames=frames,frame0=frame0,random=props.FlipbookMode==Enum.ParticleFlipbookMode.Random,grid=grid,cell=img.ImageRectSize,
		along=props.Orientation==Enum.ParticleOrientation.VelocityParallel,aspect=props.Aspect or 1}
	gui.Parent=Kit.spriteLayer()
	table.insert(live,s)
	ensureStep()
	return s
end
function Kit.spriteLayer()
	local player=game:GetService("Players").LocalPlayer
	local gui=player and player:FindFirstChildOfClass("PlayerGui")
	if not gui then return workspace end
	local layer=gui:FindFirstChild("NinjaDuelSprites")
	if not layer then layer=Instance.new("Folder");layer.Name="NinjaDuelSprites";layer.Parent=gui end
	return layer
end
stepAll=function(dt)
	local camera=workspace.CurrentCamera
	local n=#live
	local i=1
	while i<=n do
		local s=live[i]
		s.age+=dt
		local u=s.age/s.life
		if u>=1 or not s.gui.Parent then
			s.gui:Destroy()
			live[i]=live[n];live[n]=nil;n-=1
			continue
		end
		if s.drag>0 then s.vel*=math.exp(-s.drag*dt) end
		s.vel+=s.accel*dt
		s.pos+=s.vel*dt
		s.gui.StudsOffsetWorldSpace=s.pos
		local size=evalNum(s.size,u)
		if s.along then
			-- Stretched along its motion on screen (a streak).
			local a=camera:WorldToViewportPoint(s.pos)
			local b=camera:WorldToViewportPoint(s.pos+s.vel*.02)
			local d=Vector2.new(b.X-a.X,b.Y-a.Y)
			if d.Magnitude>.01 then s.img.Rotation=math.deg(math.atan2(d.X,-d.Y)) end
			s.gui.Size=UDim2.fromScale(size*s.aspect,size*s.aspect)
			s.img.Size=UDim2.fromScale(.22,1)
		else
			s.gui.Size=UDim2.fromScale(size*s.aspect,size)
			s.img.Rotation=s.rot+s.spin*s.age
		end
		s.img.ImageTransparency=evalNum(s.trans,u)
		s.img.ImageColor3=evalColor(s.color,u)
		if s.frames then
			local f=if s.random then (s.frame0+math.floor(s.age*24))%s.frames else math.min(s.frames-1,math.floor(u*s.frames))
			s.img.ImageRectOffset=Vector2.new(f%s.grid,math.floor(f/s.grid))*s.cell
		end
		i+=1
	end
	for handle in streams do
		local at=handle.attachment
		if not at.Parent or handle.dead then streams[handle]=nil;continue end
		if handle.Enabled and handle.Rate>0 then
			handle.acc+=handle.Rate*dt
			local cf=at.WorldCFrame
			local axis=if handle.props.front then cf.LookVector else cf.UpVector
			while handle.acc>=1 do
				handle.acc-=1
				spawnSprite(handle.name,cf.Position,axis,handle.props)
			end
		end
	end
end
-- A continuous emitter at an attachment: set handle.Rate / handle.Enabled /
-- handle.props.Size like an emitter's properties.
function Kit.stream(attachment,name,props)
	if not Kit.spriteOnly(name) then
		local e=Instance.new("ParticleEmitter")
		e.TextureContent=Kit.content(name);e.LightInfluence=0
		local flip=FLIP[name]
		if flip then e.FlipbookLayout=flip;e.FlipbookMode=props.FlipbookMode or Enum.ParticleFlipbookMode.OneShot end
		for k,v in props do if k~="front" and k~="Aspect" and k~="FlipbookMode" then e[k]=v end end
		if props.front then e.EmissionDirection=Enum.NormalId.Front end
		e.Parent=attachment
		return e
	end
	local handle={attachment=attachment,name=name,props=props,Rate=props.Rate or 0,Enabled=true,acc=0}
	streams[handle]=true
	ensureStep()
	return handle
end

-- Property writes that work on either kind of stream.
function Kit.setSize(stream,size)
	if not stream then return end
	if typeof(stream)=="Instance" then stream.Size=size else stream.props.Size=size end
end
function Kit.setRate(stream,rate)
	if stream then stream.Rate=rate end
end
function Kit.stop(stream)
	if not stream then return end
	if typeof(stream)=="Instance" then stream.Enabled=false else stream.dead=true end
end

-- A one-shot particle burst. `texture` is a Kit texture name; a flipbook
-- texture plays once over each particle's life.
function Kit.burst(parent,position,texture,count,props)
	if Kit.spriteOnly(texture) then
		local d=props.direction
		local axis=if d and d.Magnitude>.01 then d.Unit else Vector3.yAxis
		for _=1,count do spawnSprite(texture,position,axis,props) end
		return nil
	end
	local h=holder(parent,position,(props.hold or 4))
	local at=new("Attachment",{},h)
	local e=new("ParticleEmitter",{Enabled=false,LightInfluence=0,TextureContent=Kit.content(texture),ZOffset=props.zoffset or .5},at)
	local flip=FLIP[texture]
	if flip and Kit.has(texture) then
		e.FlipbookLayout=flip;e.FlipbookMode=Enum.ParticleFlipbookMode.OneShot
	end
	for k,v in props do
		if k~="hold" and k~="zoffset" and k~="direction" then e[k]=v end
	end
	local d=props.direction
	if d and d.Magnitude>.01 then
		d=d.Unit
		if d.Y>.99 then -- straight up: the attachment's own +Y
		elseif d.Y<-.99 then e.EmissionDirection=Enum.NormalId.Bottom
		else at.WorldCFrame=CFrame.lookAt(position,position+d)*CFrame.Angles(-math.pi/2,0,0) end
	end
	e:Emit(count)
	return e,h
end

-- A flat textured quad (both faces) at `cf`, growing and fading.
function Kit.plane(parent,cf,texture,size,growTo,time,color,transparency,light)
	if not Kit.has(texture) then return nil end
	local p=new("Part",{Name="FXPlane",Size=Vector3.new(size.X,size.Y,.05),CFrame=cf,Transparency=1,
		Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false},parent)
	for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
		local d=new("Decal",{TextureContent=Kit.content(texture),Face=face,Color3=color or Color3.new(1,1,1),Transparency=transparency or 0},p)
		tween(d,time,{Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
	end
	if light then
		-- Bright: a second, additive-looking copy.
		local glow=new("SurfaceLight",{Brightness=light,Range=6,Color=color or Color3.new(1,1,1),Face=Enum.NormalId.Front},p)
		tween(glow,time,{Brightness=0})
	end
	tween(p,time,{Size=Vector3.new(growTo.X,growTo.Y,.05)})
	Debris:AddItem(p,time+.05)
	return p
end

-- A decal laid on the floor (crack, scorch), held then faded.
function Kit.floorUnder(position,exclude,depth)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances=exclude or {}
	return workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-(depth or 14),0),params)
end
function Kit.ground(parent,position,normal,texture,size,hold,fade,color,transparency)
	if not Kit.has(texture) then return nil end
	normal=(normal or Vector3.yAxis).Unit
	-- A flat part whose top face lies on the surface, spun at random.
	local side=if math.abs(normal.Y)>.9 then Vector3.xAxis else Vector3.yAxis
	local right=side:Cross(normal).Unit
	local cf=CFrame.fromMatrix(position+normal*.04,right,normal)*CFrame.Angles(0,math.random()*math.pi*2,0)
	local p=new("Part",{Name="FXGround",Size=Vector3.new(size*.55,.05,size*.55),CFrame=cf,Transparency=1,
		Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false},parent)
	local d=new("Decal",{TextureContent=Kit.content(texture),Face=Enum.NormalId.Top,Color3=color or Color3.new(1,1,1),Transparency=1},p)
	-- In fast: the crack opens in a few frames.
	tween(d,.06,{Transparency=transparency or 0})
	tween(p,.1,{Size=Vector3.new(size,.05,size)},Enum.EasingStyle.Back)
	task.delay(hold,function() if d.Parent then tween(d,fade,{Transparency=1}) end end)
	Debris:AddItem(p,hold+fade+.1)
	return p
end

-- The struck body tints for a few frames (red on a hit, gold on a guard).
local tints=setmetatable({},{__mode="k"})
function Kit.tint(model,color,time,strength)
	if not model then return end
	local h=tints[model]
	if not h or not h.Parent then
		h=new("Highlight",{Name="HitTint",DepthMode=Enum.HighlightDepthMode.Occluded,FillTransparency=1,OutlineTransparency=1},model)
		tints[model]=h
	end
	h.FillColor=color;h.OutlineColor=color
	h.FillTransparency=1-(strength or .55);h.OutlineTransparency=.35
	tween(h,time,{FillTransparency=1,OutlineTransparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
end

-- Cel dust from the floor (landings, slams, skids).
function Kit.dust(parent,position,count,size,color,speed)
	return Kit.burst(parent,position,"smoke",count,{
		Lifetime=NumberRange.new(.45,.8),Speed=NumberRange.new(speed or 10,(speed or 10)*1.8),SpreadAngle=Vector2.new(80,8),
		Color=ColorSequence.new(color or Color3.fromRGB(214,200,172)),LightEmission=0,
		Size=num({{0,size*.5},{.3,size},{1,size*1.25}}),Transparency=num({{0,0},{.75,.1},{1,1}}),
		Drag=7,RotSpeed=NumberRange.new(-40,40),Rotation=NumberRange.new(0,360),Acceleration=Vector3.new(0,3,0),
		direction=Vector3.yAxis})
end

-- Streaks flying out of a contact, aligned to their own velocity.
function Kit.streaks(parent,position,direction,count,color,speed,spread)
	return Kit.burst(parent,position,"streak",count,{
		Lifetime=NumberRange.new(.08,.16),Speed=NumberRange.new(speed,speed*1.7),SpreadAngle=Vector2.new(spread or 50,spread or 50),
		Color=ColorSequence.new(color),LightEmission=1,Orientation=Enum.ParticleOrientation.VelocityParallel,
		Size=if Kit.spriteOnly("streak") then num({{0,2.6},{1,1.2}}) else num({{0,.35},{1,.08}}),
		Squash=num({{0,-1.2},{1,-1.6}}),Transparency=num({{0,0},{1,.6}}),Drag=8,
		direction=direction,zoffset=2})
end

-- The flash at the point of contact.
function Kit.star(parent,position,size,color,time)
	return Kit.burst(parent,position,"star",1,{
		Lifetime=NumberRange.new(time or .1),Speed=NumberRange.new(0),Color=ColorSequence.new(color),LightEmission=1,
		Size=num({{0,size*.5},{.25,size},{1,size*1.15}}),Transparency=num({{0,0},{.6,.2},{1,1}}),
		Rotation=NumberRange.new(0,360),zoffset=3})
end

return Kit
