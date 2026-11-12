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
--   (no mark in the middle of the field: user 03/11, the floor stays clear);
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
			local cloth=part(folder,{Name="Banner",Size=Vector3.new(8,24,.14),CFrame=hang*CFrame.new(0,-12,0),
				Color=if red then VERMILION else PAPER,Material=Enum.Material.Fabric})
			hung(cloth)
			-- The cloth's tail, cut in a swallowtail.
			for _,x in {-1.5,1.5} do
				hung(part(folder,{Name="BannerTail",Size=Vector3.new(4,2,.14),CFrame=cloth.CFrame*CFrame.new(x*1.33,-12.9,0)*CFrame.Angles(0,0,math.rad(x>0 and 18 or -18)),
					Color=if red then VERMILION else PAPER,Material=Enum.Material.Fabric}))
			end
			-- Ink border down both edges.
			for _,x in {-3.8,3.8} do
				hung(part(folder,{Name="BannerEdge",Size=Vector3.new(.4,24,.16),CFrame=cloth.CFrame*CFrame.new(x,0,-.02),Color=INK}))
			end
			part(folder,{Name="BannerRod",Size=Vector3.new(9.4,.5,.5),CFrame=hang*CFrame.new(0,.1,0),Color=rgb(60,42,30),Material=Enum.Material.Wood})
			for _,x in {-4.8,4.8} do
				part(folder,{Name="BannerKnob",Size=Vector3.new(.7,.7,.7),Shape=Enum.PartType.Ball,CFrame=hang*CFrame.new(x,.1,0),Color=rgb(196,150,60),Material=Enum.Material.Metal})
			end
			local gui=Instance.new("SurfaceGui")
			gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(240,720)
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
		band("WallBand",8.4,2.2,VERMILION,0)
		band("WallLine",7.05,.36,INK,0)
		band("WallLineTop",9.6,.2,INK,0,.2)
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

-- The field's grass patches (Server/ArenaMeshes) a shade softer and a little
-- thin, so the earth shows at their edges and they lie in it, not on it.
local function settle(courtyard)
	local decor=courtyard:FindFirstChild("Decor")
	if not decor then return end
	for _,d in decor:GetChildren() do
		if d:IsA("BasePart") and (d.Name=="GrassA_Grass" or d.Name=="GrassB_Grass" or d.Name=="GrassC_Grass") then
			d.Color=d.Color:Lerp(rgb(150,146,90),.2)
		end
	end
end

function ArenaDress.dress(courtyard)
	if courtyard:GetAttribute("Dressed") then return end
	local floor=courtyard:FindFirstChild("Training floor")
	if not floor then return end
	courtyard:SetAttribute("Dressed",true)
	local origin=floor.Position+Vector3.new(0,1,0)
	local folder=Instance.new("Folder");folder.Name="NinjaDuelArenaDress";folder.Parent=workspace
	local ok,err=pcall(function()
		settle(courtyard)
		wallBands(folder,origin)
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

-- (QA 12/11, gel au BEGIN) The stadium's content fetched while the player is
-- still on the roster (meshes, textures), not at the first BEGIN.
function ArenaDress.preload(courtyard)
	local ok,provider=pcall(function() return game:GetService("ContentProvider") end)
	if not ok or not provider then return end
	pcall(function() provider:PreloadAsync({courtyard}) end)
end

function ArenaDress.start()
	local function check(d)
		if d.Name=="Courtyard" and d:IsA("Folder") then
			task.spawn(function()
				-- (QA 12/11) A lane's stadium now comes a few pieces a frame
				-- (Server/Stage, Building until the last one): dressed and
				-- fetched once it is whole.
				while d.Parent and d:GetAttribute("Building") do task.wait(.25) end
				task.wait(.5)
				if d.Parent then ArenaDress.dress(d);ArenaDress.preload(d) end
			end)
		end
	end
	for _,d in workspace:GetDescendants() do check(d) end
	workspace.DescendantAdded:Connect(check)
end
return ArenaDress
