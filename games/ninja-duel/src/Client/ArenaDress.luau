-- The stadium as this screen shows it (look pass 03/11, user: "the brightness,
-- the graphics, everything that shows on the screen"). The stadium the server
-- builds (Server/World, the user's 29/10 layout) stays exactly as it is; this
-- client adds, on its own copy only, what makes it read as a place where a
-- tournament is fought rather than an empty yard:
--   * the tournament's colours on the pale wall: tall cloth banners with a
--     brushed character hanging from the cornice, a vermilion band with an
--     ink line round the whole wall;
--   * weight where the wall meets the ground: soot at its foot and a soft
--     shadow on the earth, so the wall stands on the field instead of floating;
--   * the duel's circle: an ink brush ring (an enso) painted on the earth round
--     the middle, open at one end like a brush stroke;
--   * air: dust lit by the sun hanging over the field, leaves drifting down.
-- Nothing here collides, is hit by a ray or touches a duel: every part is
-- CanCollide/CanQuery/CanTouch false and lives in a folder the server never sees.
local RunService=game:GetService("RunService")
local ArenaDress={}

local WALL_RADIUS=145
local WALL_HEIGHT=40
local INK=Color3.fromRGB(26,20,26)
local VERMILION=Color3.fromRGB(176,42,34)
local PAPER=Color3.fromRGB(238,230,212)
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local function part(parent,props)
	local p=Instance.new("Part")
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Material=Enum.Material.SmoothPlastic;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	for k,v in props do (p::any)[k]=v end
	p.Parent=parent
	return p
end

-- A ring of flat or upright pieces round the arena: `make(cf,width)` for each.
local function around(radius,segments,make)
	local width=2*math.pi*radius/segments+.12
	for k=0,segments-1 do
		local a=k/segments*math.pi*2
		make(a,width)
	end
end

local function banners(folder,origin)
	local cloths={}
	local glyphs={"火","忍","試","闘","影","葉"}
	for k=0,17 do
		local a=k/18*math.pi*2+math.pi/18
		-- Clear of the two gates (south +Z, west -X) and the balcony (east +X).
		local s,c=math.sin(a),math.cos(a)
		local nearGate=(c>.97) or (s<-.97) or (s>.96)
		if not nearGate then
			local dir=Vector3.new(s,0,c)
			local top=origin+dir*(WALL_RADIUS-1.9)+Vector3.new(0,WALL_HEIGHT-1.2,0)
			local hang=CFrame.lookAt(top,Vector3.new(origin.X,top.Y,origin.Z))
			local red=k%2==0
			local swinging={}
			local function hung(p) table.insert(swinging,{p,hang:ToObjectSpace(p.CFrame)});return p end
			local cloth=part(folder,{Name="Banner",Size=Vector3.new(6,17,.14),CFrame=hang*CFrame.new(0,-8.5,0),
				Color=if red then VERMILION else PAPER,Material=Enum.Material.Fabric})
			hung(cloth)
			-- The cloth's tail, cut in a swallowtail.
			for _,x in {-1.5,1.5} do
				hung(part(folder,{Name="BannerTail",Size=Vector3.new(3,1.6,.14),CFrame=cloth.CFrame*CFrame.new(x,-9.3,0)*CFrame.Angles(0,0,math.rad(x>0 and 18 or -18)),
					Color=if red then VERMILION else PAPER,Material=Enum.Material.Fabric}))
			end
			-- Ink border down both edges.
			for _,x in {-2.82,2.82} do
				hung(part(folder,{Name="BannerEdge",Size=Vector3.new(.36,17,.16),CFrame=cloth.CFrame*CFrame.new(x,0,-.02),Color=INK}))
			end
			part(folder,{Name="BannerRod",Size=Vector3.new(7.2,.45,.45),CFrame=hang*CFrame.new(0,.1,0),Color=rgb(60,42,30),Material=Enum.Material.Wood})
			for _,x in {-3.7,3.7} do
				part(folder,{Name="BannerKnob",Size=Vector3.new(.7,.7,.7),Shape=Enum.PartType.Ball,CFrame=hang*CFrame.new(x,.1,0),Color=rgb(196,150,60),Material=Enum.Material.Metal})
			end
			local gui=Instance.new("SurfaceGui")
			gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(240,680)
			gui.LightInfluence=1;gui.Parent=cloth
			-- A disc of the other colour, the character brushed in it.
			local disc=Instance.new("Frame")
			disc.AnchorPoint=Vector2.new(.5,.5);disc.Position=UDim2.fromOffset(120,190);disc.Size=UDim2.fromOffset(180,180)
			disc.BackgroundColor3=if red then PAPER else VERMILION;disc.BorderSizePixel=0;disc.Parent=gui
			local round=Instance.new("UICorner");round.CornerRadius=UDim.new(.5,0);round.Parent=disc
			local glyph=Instance.new("TextLabel")
			glyph.BackgroundTransparency=1;glyph.Size=UDim2.fromScale(1,1);glyph.Text=glyphs[k%#glyphs+1]
			glyph.Font=Enum.Font.GothamBlack;glyph.TextScaled=true;glyph.TextColor3=INK;glyph.Parent=disc
			local pad=Instance.new("UIPadding");pad.PaddingTop=UDim.new(.16,0);pad.PaddingBottom=UDim.new(.16,0);pad.Parent=disc
			-- Under it, the tournament's name in a column of small characters.
			local col=Instance.new("TextLabel")
			col.BackgroundTransparency=1;col.Position=UDim2.fromOffset(90,320);col.Size=UDim2.fromOffset(60,320)
			col.Text="中\n忍\n選\n抜";col.Font=Enum.Font.GothamBold;col.TextScaled=true
			col.TextColor3=if red then PAPER else INK;col.TextTransparency=.15;col.Parent=gui
			table.insert(cloths,{hang=hang,phase=k*1.7,parts=swinging})
		end
	end
	return cloths
end

local function wallBands(folder,origin)
	-- Vermilion band with an ink line under it, round the inner face.
	around(WALL_RADIUS-.55,116,function(a,width)
		local dir=Vector3.new(math.sin(a),0,math.cos(a))
		local base=origin+dir*(WALL_RADIUS-.55)
		local function band(name,y,h,color,depth,transparency)
			local at=base+Vector3.new(0,y,0)-dir*depth
			part(folder,{Name=name,Size=Vector3.new(width,h,.12),CFrame=CFrame.lookAt(at,Vector3.new(origin.X,at.Y,origin.Z)),Color=color,Transparency=transparency or 0})
		end
		band("WallBand",7.4,1.5,VERMILION,0)
		band("WallLine",6.35,.3,INK,0)
		band("WallLineTop",8.3,.16,INK,0,.2)
		-- Soot at the wall's foot, fading up.
		band("WallSoot",.9,1.8,INK,.02,.55)
		band("WallSoot",2.4,1.4,INK,.03,.78)
		band("WallSoot",3.7,1.4,INK,.04,.9)
		-- A soft shadow on the earth along the foot.
		local ground=origin+dir*(WALL_RADIUS-3.2)+Vector3.new(0,.06,0)
		part(folder,{Name="WallShade",Size=Vector3.new(width,.05,6),CFrame=CFrame.lookAt(ground,Vector3.new(origin.X,ground.Y,origin.Z)),Color=INK,Transparency=.8})
		local far=origin+dir*(WALL_RADIUS-8.2)+Vector3.new(0,.055,0)
		part(folder,{Name="WallShade",Size=Vector3.new(width*.96,.05,4.4),CFrame=CFrame.lookAt(far,Vector3.new(origin.X,far.Y,origin.Z)),Color=INK,Transparency=.9})
	end)
end

-- The ink circle: one stroke round the middle, heavy where the brush lands,
-- thinning and breaking into dry streaks where it lifts.
local function enso(folder,origin)
	local radius=36
	local segments=120
	local start=math.rad(200)
	local sweep=math.rad(332)
	for k=0,segments-1 do
		local t=k/segments
		local a=start+t*sweep
		local width=(if t<.08 then .9+t/.08*1.6 else 2.5-1.9*t^1.6)
		local dry=t>.86
		local r=radius+math.sin(t*9)*.35
		local at=origin+Vector3.new(math.sin(a)*r,.07,math.cos(a)*r)
		local tangent=Vector3.new(math.cos(a),0,-math.sin(a))
		local len=2*math.pi*r/segments*(sweep/(2*math.pi))+.25
		if dry then
			-- The lifted brush: two or three thin streaks, gaps between.
			for _,off in {-width*.35,width*.3} do
				if (k+math.floor(off*10))%3~=0 then
					part(folder,{Name="Enso",Size=Vector3.new(len,.04,width*.18),CFrame=CFrame.lookAt(at,at+tangent)*CFrame.Angles(0,math.pi/2,0)*CFrame.new(0,0,off),Color=INK,Transparency=.38})
				end
			end
		else
			part(folder,{Name="Enso",Size=Vector3.new(len,.04,width),CFrame=CFrame.lookAt(at,at+tangent)*CFrame.Angles(0,math.pi/2,0),Color=INK,Transparency=.3})
		end
	end
	-- Ink drops thrown off where the stroke began.
	local rand=Random.new(7)
	for _=1,9 do
		local a=start-rand:NextNumber(.02,.16)
		local r=radius+rand:NextNumber(-3,3)
		local d=rand:NextNumber(.35,1.1)
		part(folder,{Name="EnsoDrop",Shape=Enum.PartType.Cylinder,Size=Vector3.new(.04,d,d),
			CFrame=CFrame.new(origin+Vector3.new(math.sin(a)*r,.075,math.cos(a)*r))*CFrame.Angles(0,0,math.pi/2),Color=INK,Transparency=.32})
	end
end

local function air(folder,origin)
	-- Dust hanging in the sun over the field.
	local volume=part(folder,{Name="SunDust",Size=Vector3.new(200,26,200),CFrame=CFrame.new(origin+Vector3.new(0,14,0)),Transparency=1})
	local dust=Instance.new("ParticleEmitter")
	dust.Name="Dust";dust.Texture="rbxasset://textures/particles/sparkles_main.dds"
	dust.Shape=Enum.ParticleEmitterShape.Box;dust.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
	dust.Rate=34;dust.Lifetime=NumberRange.new(7,12);dust.Speed=NumberRange.new(.2,.6)
	dust.SpreadAngle=Vector2.new(180,180);dust.Acceleration=Vector3.new(.25,.05,.1)
	dust.Color=ColorSequence.new(rgb(255,236,200));dust.LightEmission=.9;dust.LightInfluence=0
	dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.3,.16),NumberSequenceKeypoint.new(1,0)})
	dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.35),NumberSequenceKeypoint.new(1,1)})
	dust.Parent=volume
	-- Leaves from the forest round the stadium, a few at a time.
	local sky=part(folder,{Name="LeafSky",Size=Vector3.new(280,1,280),CFrame=CFrame.new(origin+Vector3.new(0,70,0)),Transparency=1})
	local leaves=Instance.new("ParticleEmitter")
	leaves.Name="Leaves";leaves.Texture="rbxasset://textures/particles/sparkles_main.dds"
	leaves.Rate=9;leaves.Lifetime=NumberRange.new(10,14);leaves.Speed=NumberRange.new(2,4)
	leaves.EmissionDirection=Enum.NormalId.Bottom;leaves.SpreadAngle=Vector2.new(35,35)
	leaves.Color=ColorSequence.new(rgb(118,152,70),rgb(196,150,70));leaves.LightEmission=0;leaves.LightInfluence=1
	leaves.Size=NumberSequence.new(.42);leaves.Squash=NumberSequence.new(-.5)
	leaves.Rotation=NumberRange.new(0,360);leaves.RotSpeed=NumberRange.new(-120,120);leaves.Acceleration=Vector3.new(1.4,-.7,.5)
	leaves.Parent=sky
end

function ArenaDress.dress(courtyard)
	if courtyard:GetAttribute("Dressed") then return end
	local floor=courtyard:FindFirstChild("Training floor")
	if not floor then return end
	courtyard:SetAttribute("Dressed",true)
	local origin=floor.Position+Vector3.new(0,1,0)
	local folder=Instance.new("Folder");folder.Name="NinjaDuelArenaDress";folder.Parent=workspace
	local ok,err=pcall(function()
		wallBands(folder,origin)
		enso(folder,origin)
		air(folder,origin)
		local cloths=banners(folder,origin)
		-- The banners breathe in the wind, out of step.
		local last=0
		local connection
		connection=RunService.Heartbeat:Connect(function()
			if not folder.Parent or not courtyard.Parent then connection:Disconnect();folder:Destroy();return end
			local t=os.clock()
			if t-last<1/30 then return end
			last=t
			for _,b in cloths do
				local swing=math.sin(t*.9+b.phase)*math.rad(2.2)+math.sin(t*2.3+b.phase*2)*math.rad(.6)
				local pivot=b.hang*CFrame.Angles(swing,0,0)
				for _,entry in b.parts do entry[1].CFrame=pivot*entry[2] end
			end
		end)
	end)
	if not ok then warn("[NinjaDuel] arena dress: "..tostring(err)) end
end

function ArenaDress.start()
	local function check(d)
		if d.Name=="Courtyard" and d:IsA("Folder") then
			task.delay(.5,function() if d.Parent then ArenaDress.dress(d) end end)
		end
	end
	for _,d in workspace:GetDescendants() do check(d) end
	workspace.DescendantAdded:Connect(check)
end
return ArenaDress
