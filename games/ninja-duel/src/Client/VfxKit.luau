-- Presentation primitives on the project's own VFX textures
-- (tools/vfx_textures.py -> assets/vfx -> uploaded image ids below).
--
-- Cel-shaded fire and smoke flipbooks, ground cracks and scorch, an impact
-- star, a crescent slash, a shock ring, spark streaks and lightning. Every
-- helper degrades to a built-in Roblox texture (or to nothing) when an id is
-- not set, so the game never depends on an upload to run.
-- Presentation only: nothing here can change gameplay.
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
		return Content.fromObject(image)
	end)
	runtime[name]=if ok then result else nil
	return runtime[name]
end
function Kit.has(name)
	if (Kit.IDS[name] or "")~="" then return true end
	return editable(name)~=nil
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

-- A one-shot particle burst. `texture` is a Kit texture name; a flipbook
-- texture plays once over each particle's life.
function Kit.burst(parent,position,texture,count,props)
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
		Size=num({{0,.35},{1,.08}}),Squash=num({{0,-1.2},{1,-1.6}}),Transparency=num({{0,0},{1,.6}}),Drag=8,
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
