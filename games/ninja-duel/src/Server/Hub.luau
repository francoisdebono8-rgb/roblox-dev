-- Konoha, the hub (DEC-038, user 13/11: « travailler la boucle en mode le
-- décor, les scènes, où est-ce qu'on va choisir le maître, […] les premiers
-- déplacements »). Built once per server from parts (a Blender dressing comes
-- after, as for the stadium): the gate, the main street with Ichiraku and the
-- rooftops, the plaza, the exam hall (its floor, balconies and the hand-sign
-- statue), the training ground and the memorial stone, the Hyūga compound,
-- the Uchiha district with its lake, pier and shrine, the stairs up to the
-- Hokage faces. The masters wait at home (Shared/HubMap), the proctor on the
-- hall's floor opens the board of duels. Between duels the player walks here
-- as his own Roblox avatar (player:LoadCharacter, the default controls); a
-- duel takes that body away (Matches:start) and the result brings him back
-- out of the hall's door. Presentation and walking only: no gameplay rule
-- lives here (kits, masters and trees are Server/Progression's).
-- (14/11) The Blender dressing (docs/systems/HUB_DRESS.md): each building or
-- prop is a "unit", a Model tagged with the name of its modelled mesh
-- (attribute Dress) and where it goes (DressAt, DressScale, DressLength). The
-- parts stay: they are the collisions and what shows until the mesh is built;
-- Client/HubDress hides them and puts the mesh in their place. A part tagged
-- Keep (a sign with its text, the hall's floor) stays visible.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage.NinjaDuel
local HubMap=require(Shared.HubMap)
local Config=require(Shared.Config)
local Hub={built=false,bodies=setmetatable({},{__mode="k"})}

local O=HubMap.Origin
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local C={
	grass=rgb(102,134,70),grassDark=rgb(84,114,58),earth=rgb(172,146,106),gravel=rgb(196,190,176),
	cobble=rgb(150,142,128),stone=rgb(176,172,164),stoneDark=rgb(120,116,110),rock=rgb(150,134,114),rockDark=rgb(118,104,90),
	plaster=rgb(232,226,212),plasterWarm=rgb(236,218,190),plasterGreen=rgb(204,214,188),
	wood=rgb(118,82,52),woodDark=rgb(82,56,36),woodLight=rgb(160,120,80),
	red=rgb(172,58,42),redDark=rgb(132,40,30),green=rgb(108,140,92),
	roofBlue=rgb(74,96,138),roofGreen=rgb(78,112,90),roofTerra=rgb(170,90,58),roofDark=rgb(66,70,72),roofTile=rgb(62,76,72),
	cloth=rgb(240,236,226),lantern=rgb(214,64,48),leaf=rgb(70,112,58),leafDark=rgb(52,90,48),bark=rgb(96,70,50),
	water=rgb(70,110,128),black=rgb(40,42,46),
}
Hub.COLORS=C

-- ------------------------------------------------------------------ helpers
local function rel(x,y,z) return CFrame.new(O+Vector3.new(x,y,z)) end
local function part(parent,name,size,cf,color,material,collide)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
	p.Anchored=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	p.CanCollide=collide~=false;p.CanTouch=false
	if collide==false then p.CanQuery=false end
	p.Parent=parent
	return p
end
local function deco(parent,name,size,cf,color,material) return part(parent,name,size,cf,color,material,false) end
-- A unit of the dressing: a Model whose parts the client swaps for the mesh
-- `dress` placed at `at` (CFrame), scaled by `scale` (Vector3) and, for a
-- wall, repeated along `length` (docs/systems/HUB_DRESS.md).
local function unit(parent,name,dress,at,scale,length)
	local m=Instance.new("Model");m.Name=name
	m:SetAttribute("Dress",dress);m:SetAttribute("DressAt",at)
	if scale then m:SetAttribute("DressScale",scale) end
	if length then m:SetAttribute("DressLength",length) end
	m.Parent=parent
	return m
end
local function keep(p) p:SetAttribute("Keep",true) return p end
-- The plaque of an empty place on the cliff (Server/ChampionCliff writes the
-- carved one's name there instead).
Hub.SLOT_TEXT="THE NEXT FACE HERE COULD BE YOURS"
Hub.unit=unit
-- A slab on the ground between two points (x,z), `width` wide. (14/11, seen
-- in the assembled render) each slab sits a hair above the one before, so
-- two that cross never flicker into each other (the lanes, the street and
-- the plaza).
local paths=0
local function path(parent,ax,az,bx,bz,width,color,material)
	local a,b=Vector3.new(ax,0,az),Vector3.new(bx,0,bz)
	local d=b-a
	paths+=1
	local lift=.06+(paths%10)*.006
	local cf=CFrame.lookAt(O+(a+b)/2+Vector3.new(0,lift,0),O+b+Vector3.new(0,lift,0))
	return deco(parent,"Path",Vector3.new(width,.12,d.Magnitude+width*.5),cf,color,material or Enum.Material.Ground)
end
local function sign(target,face,text,color,background)
	local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(600,140);gui.LightInfluence=1;gui.Parent=target
	local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=if background then 0 else 1
	t.BackgroundColor3=background or Color3.new();t.Text=text;t.TextColor3=color;t.Font=Enum.Font.Bangers;t.TextScaled=true;t.Parent=gui
	return gui
end
local function tree(parent,x,z,height,spread)
	height=height or 14;spread=spread or 6
	local seed=(x*7+z*13)%5
	parent=unit(parent,"Tree",if seed<2 then "TreeA" elseif seed<4 then "TreeB" else "TreeC",rel(x,0,z),Vector3.new(spread/6,height/14,spread/6))
	part(parent,"Tree",Vector3.new(2.2,height,2.2),rel(x,height/2,z),C.bark,Enum.Material.Wood)
	local top=rel(x,height+spread*.2,z)
	local crown=deco(parent,"Crown",Vector3.one*spread*1.9,top,if seed<2 then C.leafDark else C.leaf,Enum.Material.Grass)
	crown.Shape=Enum.PartType.Ball
	for k=0,3 do
		local a=k/4*math.pi*2+seed
		local ball=deco(parent,"Crown",Vector3.one*spread*(1.1+(k%2)*.3),top*CFrame.new(math.sin(a)*spread*.75,-spread*.3+(k%3)*.6,math.cos(a)*spread*.75),
			if k%2==0 then C.leafDark else C.leaf,Enum.Material.Grass)
		ball.Shape=Enum.PartType.Ball
	end
end
local function lantern(parent,cf,light)
	parent=unit(parent,"PaperLantern","PaperLantern",cf)
	local l=deco(parent,"Lantern",Vector3.new(1.6,2.2,1.6),cf,C.lantern,Enum.Material.Fabric)
	l.Shape=Enum.PartType.Cylinder;l.Size=Vector3.new(2.2,1.6,1.6);l.CFrame=cf*CFrame.Angles(0,0,math.pi/2)
	deco(parent,"LanternCap",Vector3.new(1.2,.3,1.2),cf*CFrame.new(0,1.2,0),C.black)
	if light then
		local p=Instance.new("PointLight");p.Color=rgb(255,190,130);p.Range=16;p.Brightness=.8;p.Shadows=false;p.Parent=l
	end
	return l
end
-- A gable roof over a w (x) by d (z) body whose top is at height y; the
-- ridge runs along `along` ("x" or "z").
local function roof(parent,cf,w,d,color,along,pitch,over)
	pitch=math.rad(pitch or 24);over=over or 1.6
	local span=if along=="x" then d else w
	local length=(if along=="x" then w else d)+over*2
	local half=span/2+over
	local slope=half/math.cos(pitch)
	local rise=math.tan(pitch)*half
	for _,side in {-1,1} do
		-- Each half slopes down from the ridge to its eave.
		local offset=if along=="x" then CFrame.new(0,rise/2,side*half/2)*CFrame.Angles(side*pitch,0,0)
			else CFrame.new(side*half/2,rise/2,0)*CFrame.Angles(0,0,-side*pitch)
		local size=if along=="x" then Vector3.new(length,.9,slope) else Vector3.new(slope,.9,length)
		part(parent,"Roof",size,cf*offset,color,Enum.Material.SmoothPlastic)
	end
	local ridge=if along=="x" then Vector3.new(length+.4,.8,1.2) else Vector3.new(1.2,.8,length+.4)
	deco(parent,"Ridge",ridge,cf*CFrame.new(0,rise+.3,0),C.roofDark)
	-- The gable ends: wedges closing the triangle under the roof.
	for _,end_ in {-1,1} do
		for _,side in {-1,1} do
			local w2=Instance.new("WedgePart")
			w2.Anchored=true;w2.CanTouch=false;w2.Color=C.plaster;w2.Material=Enum.Material.SmoothPlastic
			if along=="x" then
				w2.Size=Vector3.new(.6,rise,span/2)
				w2.CFrame=cf*CFrame.new(end_*(w/2-.3),rise/2,side*span/4)*CFrame.Angles(0,if side>0 then math.pi else 0,0)
			else
				w2.Size=Vector3.new(.6,rise,span/2)
				w2.CFrame=cf*CFrame.new(side*span/4,rise/2,end_*(d/2-.3))*CFrame.Angles(0,if side>0 then -math.pi/2 else math.pi/2,0)
			end
			w2.Parent=parent
		end
	end
	return rise
end
-- A house: `cf` is the centre of its foot, `front` the local side facing the
-- street (-1/+1 on x). Flat roofs make the rooftop run.
local function house(parent,cf,w,d,floors,wall,roofColor,opts)
	opts=opts or {}
	local h=floors*8
	local model=Instance.new("Model");model.Name=opts.name or "House"
	if opts.dress then
		-- the mesh's street face is its +x: a house facing -x turns round
		model:SetAttribute("Dress",opts.dress);model:SetAttribute("DressAt",cf*CFrame.Angles(0,if (opts.front or 1)<0 then math.pi else 0,0))
	end
	model.Parent=parent
	part(model,"Walls",Vector3.new(w,h,d),cf*CFrame.new(0,h/2,0),wall,Enum.Material.Plaster)
	deco(model,"Base",Vector3.new(w+.3,1,d+.3),cf*CFrame.new(0,.5,0),C.woodDark,Enum.Material.Wood)
	for f=1,floors-1 do deco(model,"Band",Vector3.new(w+.3,.6,d+.3),cf*CFrame.new(0,f*8,0),C.wood,Enum.Material.Wood) end
	for _,sx in {-1,1} do for _,sz in {-1,1} do
		deco(model,"Post",Vector3.new(.9,h,.9),cf*CFrame.new(sx*(w/2),h/2,sz*(d/2)),C.wood,Enum.Material.Wood)
	end end
	local front=opts.front or 1
	-- Windows and door on the street face.
	local face=cf*CFrame.new(front*(w/2+.06),0,0)
	for f=0,floors-1 do
		for _,z in {-d/4,d/4} do
			if not (f==0 and math.abs(z)<1 and opts.door~=false) then
				deco(model,"Window",Vector3.new(.12,2.6,3.2),face*CFrame.new(0,f*8+4.4,z),C.woodDark)
				deco(model,"Lattice",Vector3.new(.16,.3,3.2),face*CFrame.new(front*.02,f*8+4.4,z),C.woodLight,Enum.Material.Wood)
			end
		end
	end
	if opts.door~=false then
		deco(model,"Door",Vector3.new(.14,6.4,3.6),face*CFrame.new(0,3.2,0),C.woodDark,Enum.Material.Wood)
		if opts.noren then
			for k=-1,1 do deco(model,"Noren",Vector3.new(.08,2.2,1.1),face*CFrame.new(front*.25,5.4,k*1.2),opts.noren,Enum.Material.Fabric) end
		end
		lantern(model,face*CFrame.new(front*.9,6,2.6))
	end
	if opts.flat then
		part(model,"Roof",Vector3.new(w+1.2,1,d+1.2),cf*CFrame.new(0,h+.5,0),C.roofDark,Enum.Material.Slate)
		deco(model,"RoofEdge",Vector3.new(w+1.6,.4,d+1.6),cf*CFrame.new(0,h+1.1,0),C.woodDark,Enum.Material.Wood)
	else
		roof(model,cf*CFrame.new(0,h,0),w,d,roofColor,opts.along or "z",opts.pitch or 24,1.6)
	end
	if opts.sign then
		local board=keep(deco(model,"Sign",Vector3.new(.3,2.4,7),face*CFrame.new(front*.4,h-2.2,0),C.woodDark,Enum.Material.Wood))
		sign(board,if front>0 then Enum.NormalId.Right else Enum.NormalId.Left,opts.sign,C.cloth)
	end
	return model
end
local function wall(parent,ax,az,bx,bz,height,color,cap)
	local a,b=Vector3.new(ax,0,az),Vector3.new(bx,0,bz)
	local d=b-a
	local foot=CFrame.lookAt(O+(a+b)/2,O+b)
	local high=height>=20
	parent=unit(parent,"Wall",if high then "VillageWall" else "CompoundWall",foot,Vector3.new(1,height/(if high then 26 else 10),1),d.Magnitude)
	local cf=CFrame.lookAt(O+(a+b)/2+Vector3.new(0,height/2,0),O+b+Vector3.new(0,height/2,0))
	local w=part(parent,"Wall",Vector3.new(2,height,d.Magnitude),cf,color,Enum.Material.Plaster)
	deco(parent,"WallCap",Vector3.new(3,.8,d.Magnitude+1),cf*CFrame.new(0,height/2+.4,0),cap or C.roofTile)
	return w
end
local function crest(parent,cf)
	-- The Uchiha fan: red above, white below, a short handle.
	local red=deco(parent,"Crest",Vector3.new(.2,4.4,4.4),cf,C.red,Enum.Material.SmoothPlastic)
	red.Shape=Enum.PartType.Cylinder;red.CFrame=cf*CFrame.Angles(0,0,0)
	deco(parent,"CrestWhite",Vector3.new(.24,2.2,4.4),cf*CFrame.new(0,-1.1,0),C.cloth)
	deco(parent,"CrestHandle",Vector3.new(.24,2,.7),cf*CFrame.new(0,-3.2,0),C.woodLight,Enum.Material.Wood)
end

-- ------------------------------------------------------------------ the village
local function ground(f)
	-- The ground, open where the Uchiha lake is (x 152..206, z -96..-38).
	local lx1,lx2,lz1,lz2=152,206,-96,-38
	local function slab(x1,x2,z1,z2)
		if x2<=x1 or z2<=z1 then return end
		part(f,"Ground",Vector3.new(x2-x1,4,z2-z1),rel((x1+x2)/2,-2,(z1+z2)/2),C.grass,Enum.Material.Grass)
	end
	slab(-310,lx1,-280,236);slab(lx2,310,-280,236);slab(lx1,lx2,-280,lz1);slab(lx1,lx2,lz2,236)
	part(f,"LakeBed",Vector3.new(lx2-lx1,1,lz2-lz1),rel((lx1+lx2)/2,-4.5,(lz1+lz2)/2),C.rockDark,Enum.Material.Mud)
	-- The water itself is Terrain: Hub.water, once the village has its scale.
	for k=0,13 do
		local a=k/14*math.pi*2
		-- (14/11, the assembled render: white bricks round the lake) wet rock
		local r=deco(f,"Shore",Vector3.new(4+k%3,1.6,3+k%2),rel(179+math.sin(a)*28,0,-67+math.cos(a)*30),if k%2==0 then C.rock else C.rockDark,Enum.Material.Rock)
		r.CFrame=r.CFrame*CFrame.Angles(0,a,0)
	end
	-- Streets and paths.
	deco(f,"Street",Vector3.new(26,.12,172),rel(0,.06,124),C.cobble,Enum.Material.Cobblestone)
	deco(f,"Plaza",Vector3.new(124,.12,64),rel(0,.03,10),C.cobble,Enum.Material.Cobblestone)
	path(f,-62,24,-96,30,10,C.earth)
	path(f,-62,-12,-108,-100,9,C.earth)
	path(f,62,-8,96,-45,9,C.earth)
	path(f,-60,-24,-60,-130,9,C.earth);path(f,60,-24,60,-130,9,C.earth)
	path(f,-60,-136,60,-136,9,C.earth)
	-- The invisible edge of the village.
	for _,b in {{0,-266,620,1},{0,220,620,1},{-294,-23,1,500},{294,-23,1,500}} do
		local edge=part(f,"Edge",Vector3.new(b[3],80,b[4]),rel(b[1],40,b[2]),C.stone);edge.Transparency=1;edge.CanQuery=false
	end
end
local function gate(f)
	local village=f
	f=unit(village,"KonohaGate","KonohaGate",CFrame.new(O))
	for _,x in {-21,21} do
		part(f,"GatePillar",Vector3.new(6,44,6),rel(x,22,206),C.red,Enum.Material.Wood)
		deco(f,"PillarFoot",Vector3.new(7.4,3,7.4),rel(x,1.5,206),C.stone,Enum.Material.Slate)
	end
	part(f,"GateBeam",Vector3.new(54,5,6),rel(0,42.5,206),C.red,Enum.Material.Wood)
	part(f,"GateRoof",Vector3.new(62,1.4,12),rel(0,46,206),C.roofTile,Enum.Material.Slate)
	local plate=keep(deco(f,"GatePlate",Vector3.new(14,4.2,.4),rel(0,38,202.7),C.woodDark,Enum.Material.Wood))
	sign(plate,Enum.NormalId.Front,"KONOHA",rgb(236,190,90))
	-- The two great doors, open against the walls.
	for _,side in {-1,1} do
		local hinge=rel(side*18,19,206)
		deco(f,"GateDoor",Vector3.new(1.4,36,18),hinge*CFrame.new(0,0,-9),C.green,Enum.Material.Wood)
		deco(f,"DoorBand",Vector3.new(1.6,1,18),hinge*CFrame.new(0,8,-9),C.woodDark,Enum.Material.Wood)
		deco(f,"DoorBand",Vector3.new(1.6,1,18),hinge*CFrame.new(0,-8,-9),C.woodDark,Enum.Material.Wood)
	end
	-- The village wall either side of the gate.
	f=village
	wall(f,-24,206,-292,206,26,C.plasterWarm)
	wall(f,24,206,292,206,26,C.plasterWarm)
	-- The gatekeepers' booth.
	local booth=unit(f,"GateBooth","GateBooth",CFrame.new(O))
	part(booth,"Booth",Vector3.new(10,3.4,4),rel(34,1.7,188),C.wood,Enum.Material.Wood)
	for _,x in {29.5,38.5} do deco(booth,"BoothPost",Vector3.new(.8,9,.8),rel(x,4.5,190),C.woodDark,Enum.Material.Wood) end
	part(booth,"BoothRoof",Vector3.new(12,.8,7),rel(34,9.2,189),C.roofTile,Enum.Material.Slate)
	local spawn=Instance.new("SpawnLocation")
	spawn.Name="HubSpawn";spawn.Anchored=true;spawn.CanCollide=false;spawn.CanQuery=false;spawn.Transparency=1
	spawn.Size=Vector3.new(6,1,6);spawn.CFrame=rel(0,.5,192);spawn.Neutral=true;spawn.Duration=0;spawn.Enabled=true
	local decal=spawn:FindFirstChildOfClass("Decal");if decal then decal:Destroy() end
	spawn.Parent=f
end
local function street(f)
	-- West side: houses, a shop and Ichiraku.
	local west={{182,2,C.plaster,C.roofBlue},{158,2,C.plasterWarm,C.roofTerra,"TOOLS"},{134,1,C.plasterGreen,C.roofGreen,"TEA"},{86,2,C.plaster,C.roofTerra},{62,2,C.plasterWarm,C.roofBlue}}
	for _,h in west do
		house(f,rel(-31,0,h[1]),24,20,h[2],h[3],h[4],{front=1,sign=h[5],noren=if h[5] then C.roofBlue else nil,
			dress=string.format("%s_24x20x%d",if h[5] then "HouseShop" else "HouseGable",h[2])})
		house(f,rel(-58,0,h[1]),22,20,2,C.plasterWarm,C.roofDark,{front=1,door=false,dress="HouseBack_22x20x2"})
	end
	-- Ichiraku: the ramen stand, its counter, stools and curtains.
	local ichi=unit(f,"Ichiraku","Ichiraku",CFrame.new(O))
	part(ichi,"Kitchen",Vector3.new(10,9,22),rel(-37,4.5,110),C.plasterWarm,Enum.Material.Plaster)
	part(ichi,"Counter",Vector3.new(2.6,3.4,20),rel(-24,1.7,110),C.woodLight,Enum.Material.Wood)
	deco(ichi,"CounterTop",Vector3.new(3.4,.4,20.6),rel(-24,3.6,110),C.wood,Enum.Material.Wood)
	for k=0,4 do
		local stool=part(ichi,"Stool",Vector3.new(2.2,1.6,1.6),rel(-21,1.1,102+k*4),C.red,Enum.Material.SmoothPlastic)
		stool.Shape=Enum.PartType.Cylinder;stool.CFrame=rel(-21,1.1,102+k*4)*CFrame.Angles(0,0,math.pi/2)
	end
	for _,z in {100,120} do deco(ichi,"StandPost",Vector3.new(.8,9,.8),rel(-19.5,4.5,z),C.woodDark,Enum.Material.Wood) end
	local over=part(ichi,"StandRoof",Vector3.new(24,.8,26),rel(-30,9.6,110)*CFrame.Angles(0,0,math.rad(-8)),C.roofTerra,Enum.Material.SmoothPlastic)
	over.Name="StandRoof"
	for k=-4,4 do deco(ichi,"Noren",Vector3.new(.08,2.4,2),rel(-19.3,7.6,110+k*2.2),if k%2==0 then C.cloth else rgb(226,220,206),Enum.Material.Fabric) end
	local board=keep(deco(ichi,"IchirakuSign",Vector3.new(.3,2.2,12),rel(-19.1,9.6,110),C.red,Enum.Material.Wood))
	sign(board,Enum.NormalId.Right,"ICHIRAKU RAMEN",C.cloth)
	lantern(ichi,rel(-18.6,7,99.4),true);lantern(ichi,rel(-18.6,7,120.6),true)
	-- East side: the rooftop run, flat roofs at 16 studs with short gaps, a
	-- truss and crates to get up; a higher row behind.
	for k,z in {182,158,134,110,86,62} do
		house(f,rel(30,0,z),24,20,2,if k%2==0 then C.plaster else C.plasterGreen,C.roofDark,{front=-1,flat=true,name="Rooftop",dress="HouseFlat_24x20x2"})
		if k%2==1 then
			house(f,rel(56,0,z-11),22,18,3,C.plasterWarm,C.roofDark,{front=-1,flat=true,door=false,name="HighRoof",dress="HouseFlat_22x18x3"})
			-- (14/11) a water tank on the high roof's back corner (solid)
			local tank=unit(f,"WaterTank","WaterTank",rel(61,25,z-15))
			local body=part(tank,"Tank",Vector3.new(7,6,6),rel(61,28.5,z-15)*CFrame.Angles(0,0,math.pi/2),C.woodLight,Enum.Material.Wood)
			body.Shape=Enum.PartType.Cylinder
		end
	end
	for _,z in {176,90} do
		local ladder=unit(f,"LadderUnit","Ladder",rel(17,8,z))
		local truss=Instance.new("TrussPart");truss.Name="Ladder";truss.Anchored=true;truss.Size=Vector3.new(2,16,2);truss.CFrame=rel(17,8,z)
		truss.Color=C.woodLight;truss.Material=Enum.Material.Wood;truss.Parent=ladder
	end
	-- Crates up to the first roof from the gate's side.
	for _,c in {{22,2,196,4},{26,4,198.5,4,8},{30,6,196,4,12}} do
		local size=Vector3.new(c[4],c[5] or c[4],c[4])
		local crate=unit(f,"Crate","Crate",rel(c[1],size.Y/2,c[3]),size/4)
		part(crate,"Crate",size,rel(c[1],size.Y/2,c[3]),C.woodLight,Enum.Material.WoodPlanks)
	end
	-- Lanterns along the street.
	for z=60,190,26 do
		for _,x in {-13.5,13.5} do
			part(unit(f,"LampPost","LampPost",rel(x,0,z)),"LampPost",Vector3.new(.6,7,.6),rel(x,3.5,z),C.woodDark,Enum.Material.Wood)
			lantern(f,rel(x,7.6,z),z%52==8)
		end
	end
end
local function plaza(f)
	tree(f,-44,30,16,7);tree(f,44,30,16,7)
	for _,x in {-24,24} do
		local bench=unit(f,"Bench","Bench",rel(x,0,32))
		part(bench,"Bench",Vector3.new(8,1,2.4),rel(x,1.6,32),C.wood,Enum.Material.Wood)
		for _,dx in {-3,3} do deco(bench,"BenchLeg",Vector3.new(.6,1.2,2),rel(x+dx,.6,32),C.woodDark,Enum.Material.Wood) end
	end
	-- The board of the exam, beside the hall's door.
	for _,x in {22,34} do part(f,"BoardPost",Vector3.new(.8,9,.8),rel(x,4.5,-16),C.woodDark,Enum.Material.Wood) end
	local board=part(f,"ExamBoard",Vector3.new(12.6,6,.6),rel(28,5.4,-16),C.woodLight,Enum.Material.Wood)
	sign(board,Enum.NormalId.Back,"CHŪNIN EXAM • PRELIMINARIES",C.woodDark)
	for _,x in {-12,12} do
		local stone=unit(f,"StoneLantern","StoneLantern",rel(x,0,-14))
		part(stone,"StoneLantern",Vector3.new(2.4,5,2.4),rel(x,2.5,-14),C.stone,Enum.Material.Slate)
		local cap=deco(stone,"LanternRoof",Vector3.new(3.6,.8,3.6),rel(x,5.4,-14),C.stoneDark,Enum.Material.Slate)
		local glow=Instance.new("PointLight");glow.Color=rgb(255,196,140);glow.Range=12;glow.Brightness=.7;glow.Parent=cap
	end
end
local function hall(f)
	local m=unit(f,"ExamHall","ExamHall",CFrame.new(O))
	local H,T=30,2
	-- Floor and walls; the door faces the plaza (z = -22).
	keep(part(m,"HallFloor",Vector3.new(110,.4,98),rel(0,.2,-72),C.stone,Enum.Material.Slate))
	part(m,"WallW",Vector3.new(T,H,100),rel(-56,H/2,-72),C.plaster,Enum.Material.Plaster)
	part(m,"WallE",Vector3.new(T,H,100),rel(56,H/2,-72),C.plaster,Enum.Material.Plaster)
	part(m,"WallN",Vector3.new(114,H,T),rel(0,H/2,-122),C.plaster,Enum.Material.Plaster)
	part(m,"WallS1",Vector3.new(47,H,T),rel(-32.5,H/2,-22),C.plaster,Enum.Material.Plaster)
	part(m,"WallS2",Vector3.new(47,H,T),rel(32.5,H/2,-22),C.plaster,Enum.Material.Plaster)
	part(m,"Lintel",Vector3.new(18,H-14,T),rel(0,14+(H-14)/2,-22),C.plaster,Enum.Material.Plaster)
	for _,x in {-10,10} do part(m,"DoorPost",Vector3.new(2,14,3),rel(x,7,-22),C.red,Enum.Material.Wood) end
	deco(m,"DoorBeam",Vector3.new(24,2,3.4),rel(0,15,-21.4),C.red,Enum.Material.Wood)
	local plate=keep(deco(m,"HallPlate",Vector3.new(16,3.6,.4),rel(0,19.5,-20.6),C.woodDark,Enum.Material.Wood))
	sign(plate,Enum.NormalId.Back,"EXAM HALL",rgb(236,190,90))
	-- Wooden columns on the outer faces.
	for z=-34,-112,-13 do for _,x in {-57.2,57.2} do deco(m,"Column",Vector3.new(1.4,H,1.4),rel(x,H/2,z),C.wood,Enum.Material.Wood) end end
	for x=-48,48,16 do if math.abs(x)>12 then deco(m,"Column",Vector3.new(1.4,H,1.4),rel(x,H/2,-20.8),C.wood,Enum.Material.Wood) end end
	roof(m,rel(0,H,-72),114,102,C.roofTile,"z",22,4)
	-- Inside: the balconies (west and east), their stairs, the railing.
	for _,side in {-1,1} do
		local bx=side*50
		part(m,"Balcony",Vector3.new(10,1,90),rel(bx,12,-69),C.wood,Enum.Material.WoodPlanks)
		-- (the stairs arrive at the front end: the railing stops before them)
		part(m,"Railing",Vector3.new(.6,3,80),rel(side*44.7,14,-74),C.woodDark,Enum.Material.Wood)
		for z=-112,-36,10 do deco(m,"RailPost",Vector3.new(.9,4,.9),rel(side*44.7,14,z),C.woodDark,Enum.Material.Wood) end
		for step=1,12 do
			local x=side*(30+(step-1)*1.25)
			part(m,"Stair",Vector3.new(1.3,step,6),rel(x,step/2,-27.5),C.wood,Enum.Material.WoodPlanks)
		end
		for z=-110,-34,19 do
			local banner=deco(m,"Banner",Vector3.new(.1,14,5),rel(side*54.8,18,z),if (z//19)%2==0 then C.red else rgb(46,64,96),Enum.Material.Fabric)
			banner.Name="Banner"
		end
	end
	-- (14/11) Pillars along the balconies' edge, up to the roof (the
	-- ANIMATOR's ExamHall models them; solid here).
	for _,side in {-1,1} do
		for _,z in {-40,-58,-76,-94,-112} do part(m,"HallPillar",Vector3.new(2.5,29.6,2.5),rel(side*43.6,.4+14.8,z),C.red,Enum.Material.Wood) end
	end
	-- The hand-sign statue at the back (14/11, after the anime's hall: two arms
	-- in sleeves along the back wall, the joined hands rising in the middle,
	-- enormous; the ANIMATOR's ExamHall models it). Solid: the sleeves, the
	-- hands, the step.
	for _,side in {-1,1} do
		local sleeve=part(m,"StatueSleeve",Vector3.new(44,9.6,9.6),rel(side*32,5.2,-113),C.stone,Enum.Material.Fabric)
		sleeve.Shape=Enum.PartType.Cylinder
	end
	part(m,"StatueStep",Vector3.new(14,1.8,12),rel(0,.9,-113),C.stoneDark,Enum.Material.Slate)
	part(m,"StatueHands",Vector3.new(9,15,10),rel(0,13.5,-113),C.stone,Enum.Material.Concrete)
	part(m,"StatueFingers",Vector3.new(4,12.5,5),rel(0,27,-113),C.stone,Enum.Material.Concrete)
	-- Warm light under the roof.
	for _,z in {-40,-70,-100} do
		local holder=keep(deco(m,"HallLight",Vector3.new(1,1,1),rel(0,24,z),C.woodDark));holder.Transparency=1
		local light=Instance.new("PointLight");light.Color=rgb(255,214,170);light.Range=48;light.Brightness=1.1;light.Parent=holder
	end
end
local function training(f)
	deco(f,"TrainingEarth",Vector3.new(.12,60,60),rel(-132,.07,36)*CFrame.Angles(0,0,math.pi/2),C.earth,Enum.Material.Ground).Shape=Enum.PartType.Cylinder
	for _,p in {{-124,46},{-132,49},{-140,46}} do
		local stump=part(unit(f,"Stump","Stump",rel(p[1],0,p[2])),"Stump",Vector3.new(5,3,3),rel(p[1],2.5,p[2])*CFrame.Angles(0,0,math.pi/2),C.woodLight,Enum.Material.Wood)
		stump.Shape=Enum.PartType.Cylinder
	end
	-- A dummy and a target with kunai in it.
	local village=f
	f=unit(village,"TrainingProps","TrainingProps",CFrame.new(O))
	part(f,"Dummy",Vector3.new(1.4,7,1.4),rel(-150,3.5,16),C.wood,Enum.Material.Wood)
	deco(f,"DummyArms",Vector3.new(6,1,1),rel(-150,5.4,16),C.wood,Enum.Material.Wood)
	part(f,"TargetPost",Vector3.new(.8,6,.8),rel(-162,3,30),C.woodDark,Enum.Material.Wood)
	local target=deco(f,"Target",Vector3.new(.4,5,5),rel(-161.6,5.6,30)*CFrame.Angles(0,math.pi/2,0),C.cloth,Enum.Material.Wood)
	target.Shape=Enum.PartType.Cylinder;target.CFrame=rel(-161.6,5.6,30)
	deco(f,"Bull",Vector3.new(.5,1.4,1.4),rel(-161.4,5.6,30),C.red).Shape=Enum.PartType.Cylinder
	-- The fence along the ground.
	f=village
	for x=-196,-82,8 do
		local fence=unit(f,"FenceSegment","FenceSegment",rel(x+4,0,-16))
		part(fence,"Fence",Vector3.new(8,.5,.4),rel(x+4,2.4,-16),C.wood,Enum.Material.Wood)
		deco(fence,"FencePost",Vector3.new(.6,3,.6),rel(x,1.5,-16),C.woodDark,Enum.Material.Wood)
	end
	-- The memorial stone.
	local memorial=unit(f,"MemorialStone","MemorialStone",CFrame.new(O))
	part(memorial,"MemorialBase",Vector3.new(8,1,6),rel(-172,.5,78),C.stoneDark,Enum.Material.Slate)
	part(memorial,"MemorialStone",Vector3.new(1.6,7,4.6),rel(-172,4.5,78)*CFrame.Angles(0,math.rad(-20),0),C.black,Enum.Material.Marble)
	for _,p in {{-178,60},{-186,88},{-160,94},{-196,40},{-110,84},{-96,68},{-186,10},{-100,0}} do tree(f,p[1],p[2],15,6.5) end
end
local function hyuga(f)
	local x1,x2,z1,z2=-212,-108,-162,-52
	wall(f,x1,z1,x2,z1,10,C.plaster);wall(f,x1,z2,x2,z2,10,C.plaster);wall(f,x1,z1,x1,z2,10,C.plaster)
	wall(f,x2,z1,x2,-112,10,C.plaster);wall(f,x2,-94,x2,z2,10,C.plaster)
	deco(f,"Gravel",Vector3.new(54,.12,104),rel(-136,.07,-107),C.gravel,Enum.Material.Pebble)
	local trees=f
	f=unit(trees,"HyugaCompound","HyugaCompound",CFrame.new(O))
	for _,z in {-112,-94} do part(f,"GatePost",Vector3.new(2,13,2),rel(x2,6.5,z),C.woodDark,Enum.Material.Wood) end
	part(f,"GateRoof",Vector3.new(6,1,22),rel(x2,13.4,-103),C.roofDark,Enum.Material.Slate)
	local main=house(f,rel(-186,0,-107),34,96,1,C.plaster,C.roofDark,{front=1,along="z",pitch=20,name="HyugaHouse",door=true})
	main.Name="HyugaHouse"
	part(f,"Engawa",Vector3.new(4,1,90),rel(-167,1,-107),C.woodLight,Enum.Material.WoodPlanks)
	part(f,"TrainingPost",Vector3.new(1.4,6.4,1.4),rel(-132,3.2,-104),C.wood,Enum.Material.Wood)
	for k=0,7 do deco(f,"PostMark",Vector3.new(1.5,.25,1.5),rel(-132,1.2+k*.6,-104),C.woodDark,Enum.Material.Wood) end
	tree(trees,-124,-140,13,5.5);tree(trees,-124,-68,12,5)
end
local function uchiha(f)
	local x1,x2,z1,z2=96,216,-166,-30
	wall(f,x1,z1,x2,z1,10,C.plaster);wall(f,x1,z2,x2,z2,10,C.plaster);wall(f,x2,z1,x2,z2,10,C.plaster)
	wall(f,x1,z1,x1,-52,10,C.plaster);wall(f,x1,-38,x1,z2,10,C.plaster)
	local gateUnit=unit(f,"UchihaGate","UchihaGate",CFrame.new(O))
	for _,z in {-52,-38} do part(gateUnit,"GatePost",Vector3.new(2.2,14,2.2),rel(x1,7,z),C.redDark,Enum.Material.Wood) end
	part(gateUnit,"GateBeam",Vector3.new(3,1.6,20),rel(x1,14,-45),C.redDark,Enum.Material.Wood)
	crest(f,rel(x1-1.3,9,-58))
	crest(f,rel(x1-1.3,9,-32))
	-- Houses of the clan, the fan on their walls.
	for _,z in {-150,-124,-98} do
		local h=house(f,rel(118,0,z),26,20,2,C.plaster,C.roofDark,{front=1,name="UchihaHouse",dress="HouseUchiha_26x20x2"})
		crest(f,rel(131.2,11,z))
		h.Name="UchihaHouse"
	end
	-- The pier into the lake.
	local pier=unit(f,"UchihaPier","UchihaPier",CFrame.new(O))
	part(pier,"Pier",Vector3.new(30,.8,5),rel(165,1.2,-60),C.woodLight,Enum.Material.WoodPlanks)
	for x=152,178,6 do for _,z in {-62.2,-57.8} do part(pier,"PierPost",Vector3.new(.8,4,.8),rel(x,-1,z),C.woodDark,Enum.Material.Wood) end end
	-- The Naka shrine and its torii.
	local shrineUnit=unit(f,"NakaShrineUnit","NakaShrine",CFrame.new(O))
	part(shrineUnit,"ShrineBase",Vector3.new(34,1.6,26),rel(182,.8,-138),C.stoneDark,Enum.Material.Slate)
	local shrine=house(shrineUnit,rel(182,1.6,-140),24,18,1,C.plaster,C.roofDark,{front=1,door=false,along="x",pitch=26,name="NakaShrine"})
	shrine.Name="NakaShrine"
	local torii=unit(f,"Torii","Torii",CFrame.new(O))
	for _,x in {171,185} do part(torii,"Torii",Vector3.new(1.6,14,1.6),rel(x,7,-108),C.red,Enum.Material.Wood) end
	part(torii,"ToriiBeam",Vector3.new(20,1.4,2),rel(178,14.2,-108),C.red,Enum.Material.Wood)
	part(torii,"ToriiTie",Vector3.new(16,1,1.4),rel(178,11.6,-108),C.red,Enum.Material.Wood)
	tree(f,108,-70,13,5.5);tree(f,206,-150,14,6);tree(f,140,-42,12,5)
end
-- `stairX`, `stairW`: where the stairs climb to the terrace (the plan's
-- village: beside the Hokage's residence, which stands in front of the cliff).
local function faces(f,stairX,stairW)
	stairX=stairX or 0;stairW=stairW or 20
	-- The cliff; the four places each a unit of their own (14/11): an empty
	-- place waiting for its champion (the ANIMATOR's HeadSlot1..4: the block
	-- roughed out, scaffolding, a blank plaque) until Server/ChampionCliff
	-- carves the creator or a champion there (it turns the unit DressOff). The
	-- plaque stays (Keep): « the next face here could be yours », then a name.
	local cliff=unit(f,"HokageCliff","HokageCliff",CFrame.new(O))
	part(cliff,"Cliff",Vector3.new(330,92,32),rel(0,46,-248),C.rock,Enum.Material.Rock)
	-- (15/11) built at the village's first scale, then scaled with it
	for k,at in HubMap.Base.Heads do
		local s=HubMap.Base.HeadScale
		local slot=unit(f,"CliffHead","HeadSlot"..k,CFrame.new(O+at),s)
		slot:SetAttribute("HeadSlot",k)
		part(slot,"Face",Vector3.new(26*s.X,30*s.Y,8*s.Z),CFrame.new(O+at),C.rock,Enum.Material.Rock)
		local plate=keep(deco(slot,"SlotPlate",Vector3.new(14*s.X,3.2*s.Y,.3),CFrame.new(O+at+Vector3.new(0,-12.4*s.Y,3.95*s.Z)),C.rockDark,Enum.Material.Slate))
		sign(plate,Enum.NormalId.Back,Hub.SLOT_TEXT,rgb(236,222,190))
	end
	local terrace=unit(f,"FacesTerrace","FacesTerrace",CFrame.new(O))
	part(terrace,"Terrace",Vector3.new(84,24,26),rel(0,12,-219),C.stone,Enum.Material.Slate)
	for _,x in {-41,41} do part(terrace,"TerraceRail",Vector3.new(1,3,26),rel(x,25.5,-219),C.woodDark,Enum.Material.Wood) end
	-- The front rail leaves the stairs' mouth open.
	local a,b=math.max(-41,stairX-stairW/2-1),math.min(41,stairX+stairW/2+1)
	if a>-41 then part(terrace,"TerraceRail",Vector3.new(a+41,3,1),rel((-41+a)/2,25.5,-206.5),C.woodDark,Enum.Material.Wood) end
	if b<41 then part(terrace,"TerraceRail",Vector3.new(41-b,3,1),rel((b+41)/2,25.5,-206.5),C.woodDark,Enum.Material.Wood) end
	for step=1,24 do
		part(terrace,"Step",Vector3.new(stairW,step,2.8),rel(stairX,step/2,-140-(step-1)*2.8),C.stone,Enum.Material.Slate)
	end
	for _,x in {stairX-stairW/2-1,stairX+stairW/2+1} do
		for step=4,24,4 do lantern(f,rel(x,step+3,-140-(step-1)*2.8),step%8==0) end
	end
end
Hub.FACES_STAIRS={x=38,w=8} -- the plan's: its lamps and lanterns line them (KonohaLayout)
local function forest(f)
	for z=-200,190,24 do
		for _,x in {-276,-256,256,276} do
			if not (x>0 and z<-30 and z>-170) then tree(f,x+(z%3)*2,z,14+(z%5),6+(z%3)) end
		end
	end
	for x=-240,240,30 do if math.abs(x)>70 then tree(f,x,196,13,5.5) end end
end

-- (14/11, seen assembled in the Blender render: « le village paraît vide »)
-- Two quarters of houses on the lawns that were empty: the market streets
-- east of the rooftops (two lanes, shops and houses facing them, a cross
-- lane), the west residences north of the training ground (one lane). Every
-- house is one of the modelled kinds (docs/systems/HUB_DRESS.md), turned to
-- face its lane.
local SIGNS={"DANGO","TEA","WEAPONS","FLOWERS","BOOKS","TOOLS","SCROLLS","SWEETS"}
local KINDS={
	{dress="HouseGable_24x20x2",w=24,floors=2,wall="plaster",roof="roofBlue"},
	{dress="HouseShop_24x20x2",w=24,floors=2,wall="plasterWarm",roof="roofTerra",shop=true},
	{dress="HouseFlat_24x20x2",w=24,floors=2,wall="plasterGreen",roof="roofDark",flat=true},
	{dress="HouseShop_24x20x1",w=24,floors=1,wall="plasterWarm",roof="roofGreen",shop=true},
	{dress="HouseBack_22x20x2",w=22,floors=2,wall="plaster",roof="roofDark",door=false},
	{dress="HouseGable_24x20x2",w=24,floors=2,wall="plasterGreen",roof="roofTerra"},
}
Hub.KINDS=KINDS
-- A row of houses along a lane that runs along x at `laneZ` (`half`: half its
-- width); `side` +1 north of it (facing -z), -1 south (facing +z).
local function row(f,laneZ,half,side,xs,start)
	local signs=0
	for k,x in xs do
		local kind=KINDS[(start+k-1)%#KINDS+1]
		local z=laneZ+side*(half+2+kind.w/2)
		-- the house's front (+x) turned to the lane: north faces -z, south +z
		local cf=rel(x,0,z)*CFrame.Angles(0,if side>0 then math.pi/2 else -math.pi/2,0)
		local sign=nil
		if kind.shop then signs+=1;sign=SIGNS[(start+signs)%#SIGNS+1] end
		house(f,cf,kind.w,20,kind.floors,C[kind.wall],C[kind.roof],{front=1,flat=kind.flat,door=kind.door,sign=sign,
			noren=if kind.shop then C.roofBlue else nil,dress=kind.dress,name="QuarterHouse"})
	end
end
local function lamps(f,ax,bx,z,step)
	for x=ax,bx,step do
		part(unit(f,"LampPost","LampPost",rel(x,0,z)),"LampPost",Vector3.new(.6,7,.6),rel(x,3.5,z),C.woodDark,Enum.Material.Wood)
		lantern(f,rel(x,7.6,z),false)
	end
end
local function quarters(f)
	-- The market streets: lanes at z 56 and 150 (12 wide), a cross lane at x 158.
	path(f,72,56,250,56,12,C.cobble,Enum.Material.Cobblestone)
	path(f,72,150,250,150,12,C.cobble,Enum.Material.Cobblestone)
	path(f,158,56,158,150,10,C.cobble,Enum.Material.Cobblestone)
	path(f,60,36,76,56,10,C.cobble,Enum.Material.Cobblestone)
	local xs={86,110,134,182,206,230}
	row(f,56,6,1,xs,0);row(f,56,6,-1,xs,2);row(f,150,6,1,xs,4);row(f,150,6,-1,xs,1)
	lamps(f,98,242,61,48);lamps(f,98,242,145,48)
	for x=96,240,36 do if math.abs(x-158)>14 then tree(f,x,103,13,5.5) end end
	-- The west residences: a lane at z 150, from the back of Ichiraku.
	path(f,-246,150,-86,150,12,C.cobble,Enum.Material.Cobblestone)
	path(f,-46,110,-90,150,9,C.earth)
	local west={-232,-208,-184,-136,-112}
	row(f,150,6,1,west,3);row(f,150,6,-1,west,5)
	lamps(f,-220,-100,155,60)
	Hub.alleys(f)
end
-- (15/11, François: « la carte est à refaire avec des vrais quartiers, plus de
-- place un peu pour se battre, mais quand même dans des espaces resserrés »)
-- The back alleys, between the Uchiha district's wall and the market: a
-- narrow lane (7 wide) between two rows of small two-storey houses, a
-- courtyard in its middle (about 58 x 37) with crates to break and walls to
-- run on, and a passage behind the market's backs. Its houses wear the
-- quarters' models narrowed to their size (DressScale).
Hub.ALLEY={z=-3,width=7,depth=14,front=16,north={109,127,203,221,239,257},south={109,127,203,221,239,257},yard={x=165,z=-3}}
function Hub.alleys(f)
	local A=Hub.ALLEY
	path(f,96,A.z,266,A.z,A.width,C.earth)
	path(f,96,20,266,20,6,C.earth)
	path(f,136,A.z,194,A.z,36,C.cobble,Enum.Material.Cobblestone)
	local kinds={KINDS[1],KINDS[2],KINDS[3],KINDS[6]}
	local n=0
	for _,spec in {{xs=A.north,side=-1},{xs=A.south,side=1}} do
		for _,x in spec.xs do
			n+=1
			local kind=kinds[(n-1)%#kinds+1]
			local z=A.z+spec.side*(A.width/2+1+A.depth/2)
			local cf=rel(x,0,z)*CFrame.Angles(0,if spec.side>0 then math.pi/2 else -math.pi/2,0)
			local h=house(f,cf,A.depth,A.front,2,C[kind.wall],C[kind.roof],{front=1,flat=kind.flat,dress=kind.dress,name="AlleyHouse",
				noren=if kind.shop then C.roofBlue else nil})
			h:SetAttribute("DressScale",Vector3.new(A.depth/kind.w,1,A.front/20))
		end
	end
	-- the courtyard: cover to break, light to fight by
	for _,c in {{150,-12,4,2},{154.2,-12,4,2},{152.1,-12,4,6},{182,8,4,2},{186.5,6,4,2}} do
		local size=Vector3.new(c[3],c[3],c[3])
		local y=c[4]
		local crate=unit(f,"Crate","Crate",rel(c[1],y,c[2]),size/4)
		part(crate,"Crate",size,rel(c[1],y,c[2]),C.woodLight,Enum.Material.WoodPlanks)
	end
	local bench=unit(f,"Bench","Bench",rel(165,0,12))
	part(bench,"Bench",Vector3.new(8,1,2.4),rel(165,1.6,12),C.wood,Enum.Material.Wood)
	lamps(f,140,190,A.z-14,50)
	return n
end

-- Builds the village once per server (Main). Headless: the parts are built in
-- the given parent.
-- (15/11, François: « les bâtiments n'ont pas de mur, pas de physique »,
-- « une vraie adaptation avec les dégâts dans les murs ») What a street duel
-- does with the village. Every solid upright piece big enough to stand on its
-- side (a house's walls, the village walls, the hall, the gate's pillars) is
-- a wall the fighters run on (NinjaWall, Server/Motor), and the props break
-- (WorldBreakable, Server/WorldReaction) with a toughness of their own; the
-- duel's end puts them back (WorldReaction.restore).
Hub.BREAKABLE={Crate=40,Bench=60,FenceSegment=50,LampPost=45,StoneLantern=140,Stump=90}
Hub.WALL_HEIGHT=7
Hub.WALL_WIDTH=2
function Hub.forFights(f)
	local walls,breakables=0,0
	for _,d in f:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide then
			local s=d.Size
			if s.Y>=Hub.WALL_HEIGHT and math.max(s.X,s.Z)>=Hub.WALL_WIDTH*2 and math.min(s.X,s.Z)>=Hub.WALL_WIDTH*.5 then
				d:SetAttribute("NinjaWall",true);walls+=1
			end
		end
		if d:IsA("Model") and Hub.BREAKABLE[d:GetAttribute("Dress") or ""] then
			for _,p in d:GetChildren() do
				if p:IsA("BasePart") and p.CanQuery then
					p:SetAttribute("WorldBreakable",true);p:SetAttribute("WorldToughness",Hub.BREAKABLE[d:GetAttribute("Dress")]);breakables+=1
				end
			end
		end
	end
	return walls,breakables
end
-- (15/11, François: « s'ils sont grands, fait tout un peu plus grand aussi »)
-- The village built at its first scale, made `s` times bigger around the
-- origin: every piece's size and place, the dressing's place and scale (a
-- wall's segments keep their length: DressLength grows instead), the lights'
-- reach, the signs' text at the same share of their board, the tiles of a
-- texture, a mesh's own scale. The bodies (walkers, inspirations) keep theirs.
function Hub.scaleVillage(f,s)
	if s==1 then return 0 end
	local function at(cf) return CFrame.new(O+(cf.Position-O)*s)*cf.Rotation end
	local n=0
	for _,d in f:GetDescendants() do
		if d:IsA("BasePart") then
			local size=d.Size*s
			if d:IsA("TrussPart") then size=Vector3.new(d.Size.X,d.Size.Y*s,d.Size.Z) end
			d.Size=size;d.CFrame=at(d.CFrame);n+=1
		elseif d:IsA("Model") and d:GetAttribute("Dress") then
			local dressAt=d:GetAttribute("DressAt")
			if typeof(dressAt)=="CFrame" then d:SetAttribute("DressAt",at(dressAt)) end
			-- (21/11, DEC-047) the stand-in of a house of the plan (Client/HubDress)
			local fallbackAt=d:GetAttribute("DressFallbackAt")
			if typeof(fallbackAt)=="CFrame" then d:SetAttribute("DressFallbackAt",at(fallbackAt)) end
			local fallbackScale=d:GetAttribute("DressFallbackScale")
			if typeof(fallbackScale)=="Vector3" then d:SetAttribute("DressFallbackScale",fallbackScale*s) end
			local scale=d:GetAttribute("DressScale")
			if typeof(scale)~="Vector3" then scale=Vector3.one end
			local length=d:GetAttribute("DressLength")
			if type(length)=="number" then
				d:SetAttribute("DressLength",length*s)
				d:SetAttribute("DressScale",Vector3.new(scale.X*s,scale.Y*s,scale.Z))
			else
				d:SetAttribute("DressScale",scale*s)
			end
		elseif d:IsA("Light") then
			pcall(function() (d::any).Range*=s end)
		elseif d:IsA("SurfaceGui") then
			if d.SizingMode==Enum.SurfaceGuiSizingMode.PixelsPerStud then d.PixelsPerStud/=s end
		elseif d:IsA("Texture") then
			d.StudsPerTileU*=s;d.StudsPerTileV*=s
		elseif d:IsA("SpecialMesh") and d.MeshType==Enum.MeshType.FileMesh then
			d.Scale*=s
		elseif d:IsA("Attachment") then
			d.Position*=s
		end
	end
	return n
end
-- (19/11, the SyphoDev map check; François 15/11: « chez Itachi il y a de l'eau,
-- tout à l'heure je pouvais nager, maintenant je peux plus ») The Uchiha lake's
-- water is Terrain, which Hub.scaleVillage does not move: since the village
-- grew (HubMap.Scale 1.3) the hole and its bed moved out and the water stayed
-- behind, under the grass. It is filled here, after the scale, exactly in the
-- hole: the lake bed's box (x, z) from just over the bed up to just under the
-- ground's top. Returns the block's CFrame and size (tests/Hub.spec).
function Hub.water(f)
	local bed=f:FindFirstChild("LakeBed")
	if not bed then return nil end
	local at=bed.CFrame.Position
	local top=at.Y+bed.Size.Y/2
	local surface=O.Y-.4*(HubMap.Scale or 1)
	local size=Vector3.new(bed.Size.X,surface-top,bed.Size.Z)
	local cf=CFrame.new(at.X,(top+surface)/2,at.Z)
	pcall(function() workspace.Terrain:FillBlock(cf,size,Enum.Material.Water) end)
	Hub.lake={cf=cf,size=size}
	return cf,size
end
-- ------------------------------------------------- the new Konoha (DEC-042)
-- (21/11, étape 3 DEV 3, DEC-047; François: « la map n'est pas finie, est
-- restreinte ») The village built from the validated plan, Shared/KonohaLayout
-- (tools/blender/konoha_layout.py): its districts, streets, every building of
-- the plan (154 houses of six models, the landmarks), the walls, the rooftop
-- decks and the props; the Hokage cliff and Training Ground Three's props are
-- the old builder's. Every building is a solid block whose walls are run on
-- (Hub.forFights) and whose roof is walked on, dressed by the client with the
-- ANIMATEUR's model of the plan's name (Dress = the layout's model) and, until
-- that model exists, with the old village's house of the nearest kind
-- (DressFallback: Client/HubDress) scaled to the lot.
local Layout=require(Shared.KonohaLayout)
-- The six houses' stand-ins: {old mesh, its depth (x, the street face is +x),
-- height, frontage (z)} (the old builder's house(): w along x, d along z).
Hub.LAYOUT_STANDIN={
	small_house={"HouseGable_24x20x2",24,16,20},machiya={"HouseBack_22x20x2",22,16,20},
	tank_house={"HouseFlat_22x18x3",22,24,18},shop_house={"HouseShop_24x20x2",24,16,20},
	apartment={"HouseFlat_24x20x2",24,16,20},clan_house={"HouseUchiha_26x20x2",26,16,20},
	-- (23/11, the ANIMATEUR's variety pass) the tower, until its own model is exported
	tower_house={"HouseFlat_22x18x3",22,24,18},
}
local function lighten(c,k) return c:Lerp(Color3.new(1,1,1),k) end
-- One building of the plan: {model, x, z, w, d, h, yaw, district, landmark}.
Hub.MODEL_REF=(function() local ok,ref=pcall(function() return require(Shared.KonohaModelRef) end);return if ok then ref else {} end)()
-- (22/11, the OUTILLEUR's prover: the residence (52 studs) and the gate (65)
-- were the two roofs nobody reached) A building taller than a run up its wall
-- (Client/HubMove: about 36 studs) has a ladder up its back.
Hub.LADDER_ABOVE=26
function Hub.layoutBuilding(parent,b)
	local model,x,z,w,d,h,yaw,district,landmark=b[1],b[2],b[3],b[4],b[5],b[6],b[7] or 0,b[8],b[9]
	local foot=rel(x,0,z)*CFrame.Angles(0,math.rad(yaw),0)
	local m=Instance.new("Model");m.Name=landmark or model
	m:SetAttribute("Dress",model);m:SetAttribute("DressAt",foot)
	m:SetAttribute("LayoutModel",model)
	-- (22/11) the ANIMATEUR's model fitted to its lot (Shared/KonohaModelRef:
	-- the size it is built at): what is seen is what is run on
	local ref=Hub.MODEL_REF[model]
	if ref then m:SetAttribute("DressScale",Vector3.new(w/ref.w,h/ref.h,d/ref.d)) end
	local standin=Hub.LAYOUT_STANDIN[model]
	if standin then
		-- the old mesh's street face (+x) turned to the plan's door (+z)
		m:SetAttribute("DressFallback",standin[1])
		m:SetAttribute("DressFallbackAt",foot*CFrame.Angles(0,-math.pi/2,0))
		m:SetAttribute("DressFallbackScale",Vector3.new(d/standin[2],h/standin[3],w/standin[4]))
	end
	m.Parent=parent
	local tint=Color3.fromRGB(224,214,196)
	for _,dd in Layout.Districts do if dd.id==district then tint=lighten(dd.color,.55) end end
	part(m,"Walls",Vector3.new(w,h,d),foot*CFrame.new(0,h/2,0),tint,Enum.Material.Plaster)
	-- a flat roof to walk on, flush with the walls (an eave would catch the
	-- head at the top of a run up the wall, Client/HubMove; the model draws it)
	part(m,"Roof",Vector3.new(w,1,d),foot*CFrame.new(0,h+.5,0),C.roofDark,Enum.Material.Slate)
	deco(m,"Base",Vector3.new(w+.3,1,d+.3),foot*CFrame.new(0,.5,0),C.woodDark,Enum.Material.Wood)
	if h>Hub.LADDER_ABOVE and d>4 then
		local ladder=Instance.new("TrussPart");ladder.Name="Ladder"
		ladder.Size=Vector3.new(2,h+1,2);ladder.CFrame=foot*CFrame.new(0,(h+1)/2,-d/2-1)
		ladder.Anchored=true;ladder.Color=C.woodDark;ladder.Material=Enum.Material.Wood;ladder.Parent=m
		keep(ladder)
	end
	return m
end
local PROP={
	lamp=function(f,x,z,yaw,height)
		local u=unit(f,"LampPost","LampPost",rel(x,0,z))
		part(u,"LampPost",Vector3.new(.6,height or 7,.6),rel(x,(height or 7)/2,z),C.woodDark,Enum.Material.Wood)
		lantern(f,rel(x,(height or 7)+.6,z),false)
	end,
	tree=function(f,x,z,yaw,height) tree(f,x,z,height or 14,(height or 14)*.42) end,
	crate=function(f,x,z,yaw,height)
		local size=Vector3.new(4,height or 4,4)
		local u=unit(f,"Crate","Crate",rel(x,size.Y/2,z)*CFrame.Angles(0,math.rad(yaw or 0),0),size/4)
		part(u,"Crate",size,rel(x,size.Y/2,z)*CFrame.Angles(0,math.rad(yaw or 0),0),C.woodLight,Enum.Material.WoodPlanks)
	end,
	stone_lantern=function(f,x,z)
		local u=unit(f,"StoneLantern","StoneLantern",rel(x,0,z))
		part(u,"StoneLantern",Vector3.new(2.4,5,2.4),rel(x,2.5,z),C.stone,Enum.Material.Slate)
	end,
	bench=function(f,x,z,yaw)
		local cf=rel(x,0,z)*CFrame.Angles(0,math.rad(yaw or 0),0)
		local u=unit(f,"Bench","Bench",cf)
		part(u,"Bench",Vector3.new(8,1,2.4),cf*CFrame.new(0,1.6,0),C.wood,Enum.Material.Wood)
	end,
	fence=function(f,x,z,yaw)
		local cf=rel(x,0,z)*CFrame.Angles(0,math.rad(yaw or 0),0)
		local u=unit(f,"FenceSegment","FenceSegment",cf)
		part(u,"Fence",Vector3.new(10,3,.6),cf*CFrame.new(0,1.5,0),C.wood,Enum.Material.Wood)
	end,
}
local function prop(f,p)
	local kind,x,z,yaw,height,y=p[1],p[2],p[3],p[4],p[5],p[6]
	local make=PROP[kind]
	if make then make(f,x,z,yaw,height);return end
	-- a barrel, a stall, a post: a plain piece of its size
	local size=if kind=="barrel" then Vector3.new(3,3.6,3) elseif kind=="stall" then Vector3.new(8,6,5) else Vector3.new(1,height or 4,1)
	local piece=part(f,"Prop_"..tostring(kind),size,rel(x,(y or 0)+size.Y/2,z)*CFrame.Angles(0,math.rad(yaw or 0),0),C.wood,Enum.Material.Wood)
	if kind=="barrel" then piece.Shape=Enum.PartType.Cylinder;piece.CFrame=piece.CFrame*CFrame.Angles(0,0,math.pi/2) end
end
local function layoutGround(f)
	local x0,x1,z0,z1=-Layout.HalfX-20,Layout.HalfX+20,Layout.MinZ-20,Layout.MaxZ+24
	-- the ground around the Naka river's bed (Layout.Open "the Naka river"):
	-- the water is filled into it like the old lake (Hub.water, swimming)
	local river
	for _,o in Layout.Open do if o.shape=="rect" and string.find(o.why,"river") then river=o end end
	local function ground(ax,az,bx,bz)
		if bx-ax>.1 and bz-az>.1 then part(f,"Ground",Vector3.new(bx-ax,8,bz-az),rel((ax+bx)/2,-4,(az+bz)/2),C.grass,Enum.Material.Grass) end
	end
	if river then
		ground(x0,z0,river.x0,z1);ground(river.x1,z0,x1,z1)
		ground(river.x0,z0,river.x1,river.z0);ground(river.x0,river.z1,river.x1,z1)
		part(f,"LakeBed",Vector3.new(river.x1-river.x0,3,river.z1-river.z0),rel((river.x0+river.x1)/2,-6.5,(river.z0+river.z1)/2),C.rockDark,Enum.Material.Mud)
	else
		ground(x0,z0,x1,z1)
	end
	for _,dd in Layout.Districts do
		deco(f,"District_"..dd.id,Vector3.new(dd.x1-dd.x0,.06,dd.z1-dd.z0),rel((dd.x0+dd.x1)/2,.02,(dd.z0+dd.z1)/2),lighten(dd.color,.25),Enum.Material.Ground)
	end
	for _,st in Layout.Streets do
		path(f,st.a.X,st.a.Y,st.b.X,st.b.Y,st.width,C.cobble,Enum.Material.Cobblestone)
	end
	-- the invisible edge of the village (the wall stands inside it)
	for _,b in {{0,Layout.MinZ-4,640,1},{0,Layout.MaxZ+6,640,1},{-Layout.HalfX-6,-23,1,520},{Layout.HalfX+6,-23,1,520}} do
		local edge=part(f,"Edge",Vector3.new(b[3],90,b[4]),rel(b[1],45,b[2]),C.stone);edge.Transparency=1;edge.CanQuery=false
	end
	local spawn=Instance.new("SpawnLocation")
	spawn.Name="HubSpawn";spawn.Anchored=true;spawn.CanCollide=false;spawn.CanQuery=false;spawn.Transparency=1
	spawn.Size=Vector3.new(6,1,6);spawn.CFrame=rel(0,.5,192);spawn.Neutral=true;spawn.Duration=0;spawn.Enabled=true
	local decal=spawn:FindFirstChildOfClass("Decal");if decal then decal:Destroy() end
	spawn.Parent=f
end
function Hub.buildLayout(f)
	layoutGround(f)
	local buildings=Instance.new("Folder");buildings.Name="Buildings";buildings.Parent=f
	for _,b in Layout.Buildings do Hub.layoutBuilding(buildings,b) end
	for _,w in Layout.Walls do
		local id,x,z,ww,dd,height=w[1],w[2],w[3],w[4],w[5],w[6]
		-- (a hair over the roofs it meets: two tops at one height flicker, the prover)
		height+=.2
		if ww>=dd then wall(f,x-ww/2,z,x+ww/2,z,height,C.plasterWarm) else wall(f,x,z-dd/2,x,z+dd/2,height,C.plasterWarm) end
	end
	for _,deck in Layout.RoofDecks do
		local x,z,w,d,top=deck[1],deck[2],deck[3],deck[4],deck[5]
		part(f,"RoofDeck",Vector3.new(w,1,d),rel(x,top-.5,z),C.woodLight,Enum.Material.WoodPlanks)
		for _,sx in {-1,1} do for _,sz in {-1,1} do part(f,"DeckPost",Vector3.new(.8,top,.8),rel(x+sx*(w/2-.5),top/2,z+sz*(d/2-.5)),C.woodDark,Enum.Material.Wood) end end
		local ladder=unit(f,"LadderUnit","Ladder",rel(x-w/2-1,top/2,z))
		local truss=Instance.new("TrussPart");truss.Name="Ladder";truss.Anchored=true;truss.Size=Vector3.new(2,top,2);truss.CFrame=rel(x-w/2-1,top/2,z)
		truss.Color=C.woodLight;truss.Material=Enum.Material.Wood;truss.Parent=ladder
	end
	-- (23/11, tools/village) the walkways over the lanes, roof to roof: a ninja
	-- crosses at a run, the street keeps its sky above the walkers (their rope
	-- rails are drawn, not stood on)
	for _,br in Layout.Bridges or {} do
		local x0,z0,t0,x1,z1,t1,width=br[1],br[2],br[3],br[4],br[5],br[6],br[7]
		local a,b=rel(x0,t0-.5,z0).Position,rel(x1,t1-.5,z1).Position
		local cf=CFrame.lookAt((a+b)/2,b)
		local span=(b-a).Magnitude
		-- (a plain model until the ANIMATEUR draws one: not in the dressing's contract)
		local u=Instance.new("Model");u.Name="Bridge";u.Parent=f
		part(u,"Bridge",Vector3.new(width,1,span),cf,C.woodLight,Enum.Material.WoodPlanks)
		for _,side in {-1,1} do
			deco(u,"BridgeRope",Vector3.new(.25,.25,span),cf*CFrame.new(side*(width/2-.1),2.2,0),C.woodDark,Enum.Material.Fabric)
		end
	end
	-- The props, out of the line where the two fighters of a street duel
	-- stand (HubMap.Streets: its centre and both starts, a body's width
	-- around): a stall left there would start a fighter inside it.
	local S=HubMap.Scale or 1
	local lanes={}
	for _,street in HubMap.Streets do
		local axis=street.axis or Vector3.zAxis
		local half=(street.start or math.min(24,street.radius*.7))/S
		table.insert(lanes,{c=street.at/S,axis=axis,half=half})
	end
	local function onLane(x,z,reach)
		for _,l in lanes do
			local d=Vector3.new(x-l.c.X,0,z-l.c.Z)
			local along=d:Dot(l.axis)
			local across=(d-l.axis*along).Magnitude
			if math.abs(along)<=l.half+reach and across<=reach then return true end
		end
		return false
	end
	local st=Hub.FACES_STAIRS
	local function onStairs(x,z) return math.abs(x-st.x)<=st.w/2+1 and z<=-138 and z>=-206 end
	for _,p in Layout.Props do
		if not onLane(p[2],p[3],7) and not onStairs(p[2],p[3]) then prop(f,p) end
	end
	-- kept from the old builder: the Hokage cliff and its faces (their stairs
	-- beside the residence), Training Ground Three's props
	faces(f,st.x,st.w);training(f)
	-- An inspiration who waits up high (Itachi on his perch, HubMap) has a
	-- deck under his feet in the plan's village too, unless he stands on
	-- something already (Flashstep on the faces' terrace: two tops flickered)
	local tops={}
	for _,d in f:GetDescendants() do if d:IsA("BasePart") and d.CanCollide then table.insert(tops,d) end end
	local function standsOn(at)
		for _,p in tops do
			local l=p.CFrame:PointToObjectSpace(at)
			local top=p.CFrame.Position.Y+p.Size.Y/2
			if math.abs(l.X)<=p.Size.X/2 and math.abs(l.Z)<=p.Size.Z/2 and top<=at.Y+.05 and at.Y-top<.6 then return true end
		end
		return false
	end
	local spots={HubMap.Proctor}
	for _,spot in HubMap.Masters do table.insert(spots,spot) end
	for _,spot in spots do
		local b=spot.at/S
		if b.Y>1 and not standsOn(O+b) then
			part(f,"PerchDeck",Vector3.new(10,1,10),rel(b.X,b.Y-.5,b.Z),C.woodLight,Enum.Material.WoodPlanks)
			for _,sx in {-1,1} do for _,sz in {-1,1} do part(f,"PerchPost",Vector3.new(.8,b.Y-1,.8),rel(b.X+sx*4.4,(b.Y-1)/2,b.Z+sz*4.4),C.woodDark,Enum.Material.Wood) end end
		end
	end
	for _,o in Layout.Outside do
		local model,x,z,w,d,h=o[1],o[2],o[3],o[4],o[5],o[6]
		local u=Instance.new("Model");u.Name=o[8] or model;u:SetAttribute("Dress",model);u:SetAttribute("DressAt",rel(x,0,z));u.Parent=f
		part(u,"Backdrop",Vector3.new(w,h,d),rel(x,h/2,z),if model=="forest_of_death" then C.grass else C.stone,Enum.Material.Grass)
	end
	return f
end
-- Which village: "konoha2" (the plan, DEC-042) or "classic" (the old one).
-- "auto": the plan in the work places (debug, qa, capture), the old one in
-- the release build (kept for a step back if ND-JEU needs it).
function Hub.layoutMode()
	local mode=(Config.Hub and Config.Hub.Layout) or "classic"
	if mode~="auto" then return mode end
	local value="release"
	pcall(function() local profile=Shared:FindFirstChild("BuildProfile");if profile then value=profile.Value end end)
	return if value=="release" then "classic" else "konoha2"
end
function Hub.build(parent)
	if Hub.folder and Hub.folder.Parent then return Hub.folder end
	local f=Instance.new("Folder");f.Name="NinjaDuelHub"
	if Hub.layoutMode()=="konoha2" then
		Hub.buildLayout(f)
		f:SetAttribute("Layout","konoha2")
		Hub.scaleVillage(f,HubMap.Scale or 1)
		Hub.water(f)
		Hub.forFights(f)
		f.Parent=parent or workspace
		Hub.folder=f;Hub.built=true
		return f
	end
	ground(f);gate(f);street(f);plaza(f);hall(f);training(f);hyuga(f);uchiha(f);faces(f);quarters(f);forest(f)
	Hub.scaleVillage(f,HubMap.Scale or 1)
	Hub.water(f)
	Hub.forFights(f)
	f.Parent=parent or workspace
	Hub.folder=f;Hub.built=true
	return f
end

-- ------------------------------------------------------------------ the open 1v1
-- (21/11, étape 3 DEV 5, DEC-047; « le 1v1 ouvert : personne d'autre n'entre,
-- les autres regardent depuis la rue ») While a duel is fought in a place of
-- the village, a ring stands round it: a line on the ground everybody sees,
-- and a wall only the passers-by meet (its collision group meets the walkers'
-- alone: never the fighters, nor the fight's queries, nor a lens). A walker
-- caught inside when it starts is set down outside, facing the fight.
Hub.RING_GROUP="NinjaDuelRing"
Hub.RING_WALLS=24
Hub.RING_HEIGHT=14
function Hub.ringSetup()
	if Hub.ringReady~=nil then return Hub.ringReady end
	local DuelQuery=require(script.Parent.DuelQuery)
	local ok=DuelQuery.setup() and pcall(function()
		local physics=game:GetService("PhysicsService")
		if not physics:IsCollisionGroupRegistered(Hub.RING_GROUP) then physics:RegisterCollisionGroup(Hub.RING_GROUP) end
		for _,group in physics:GetRegisteredCollisionGroups() do
			physics:CollisionGroupSetCollidable(Hub.RING_GROUP,group.name,group.name==DuelQuery.WALKERS)
		end
	end)
	Hub.ringReady=ok==true
	return Hub.ringReady
end
-- The rings of the duels fought now: `active` = {{key, origin, radius}}.
-- Raised for a new one, taken down for one over; the walkers inside set out.
function Hub.duelRings(active)
	local f=Hub.folder
	if not f then return end
	local want={}
	for _,site in active do want["DuelRing_"..site.key]=site end
	for _,child in f:GetChildren() do
		if string.sub(child.Name,1,9)=="DuelRing_" and not want[child.Name] then child:Destroy() end
	end
	for name,site in want do
		if not f:FindFirstChild(name) then
			local ring=Instance.new("Folder");ring.Name=name;ring.Parent=f
			local walls=Hub.ringSetup()
			local r=site.radius
			local centre=Vector3.new(site.origin.X,O.Y,site.origin.Z)
			local n=Hub.RING_WALLS
			local width=2*math.pi*r/n+.6
			for k=1,n do
				local a=(k-.5)/n*math.pi*2
				local at=centre+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
				local face=CFrame.lookAt(at,centre)
				-- the line on the ground, red ink
				local line=deco(ring,"Line",Vector3.new(width,.1,.7),face*CFrame.new(0,.06,0),C.red,Enum.Material.SmoothPlastic)
				line.Transparency=.15
				if walls then
					local wall=part(ring,"Wall",Vector3.new(width,Hub.RING_HEIGHT,1),face*CFrame.new(0,Hub.RING_HEIGHT/2,0),C.red,Enum.Material.ForceField)
					wall.Transparency=1;wall.CanQuery=false;wall.CanTouch=false;wall.CastShadow=false
					pcall(function() wall.CollisionGroup=Hub.RING_GROUP end)
				end
			end
		end
	end
	-- the passers-by inside: set down outside, facing the fight
	for _,body in Hub.bodies do
		local root=body.character and body.character:FindFirstChild("HumanoidRootPart")
		if root then
			for _,site in want do
				local d=Vector3.new(root.Position.X-site.origin.X,0,root.Position.Z-site.origin.Z)
				if d.Magnitude<site.radius+1 then
					local out=if d.Magnitude>.1 then d.Unit else Vector3.xAxis
					local at=Vector3.new(site.origin.X,root.Position.Y,site.origin.Z)+out*(site.radius+3)
					pcall(function() body.character:PivotTo(CFrame.lookAt(at,Vector3.new(site.origin.X,at.Y,site.origin.Z))) end)
					break
				end
			end
		end
	end
end

-- ------------------------------------------------------------------ the masters
local function promptOn(model,id,text,place,elevated)
	local root=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart",true)
	if not root then return nil end
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="Talk";prompt.ActionText=text;prompt.ObjectText=place
	prompt.HoldDuration=0;prompt.MaxActivationDistance=if elevated then 22 else 12;prompt.RequiresLineOfSight=false
	prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	prompt.Style=Enum.ProximityPromptStyle.Default
	prompt.Parent=root
	return prompt
end
local function stand(model,at,face)
	local cf=CFrame.lookAt(O+at,O+at+Vector3.new(face.X,0,face.Z))
	-- The duel's rig stands with its root 3 studs over the floor (Matches).
	local root=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	-- Every piece moves with the root (the same as PivotTo, part by part).
	local delta=cf*CFrame.new(0,3,0)*root.CFrame:Inverse()
	for _,piece in model:GetDescendants() do
		if piece:IsA("BasePart") then piece.CFrame=delta*piece.CFrame end
	end
end
-- Each master at home (a copy of his roster portrait: the duel's rig and
-- costume, in guard), with the prompt the client answers (Client/HubClient).
function Hub.placeMasters(source)
	local f=Hub.folder
	if not f or f:FindFirstChild("Masters") then return end
	local holder=Instance.new("Folder");holder.Name="Masters";holder.Parent=f
	for id,spot in HubMap.Masters do
		local portrait=source and source:FindFirstChild(id)
		if not portrait then
			for _,m in (source and source:GetChildren() or {}) do if m:GetAttribute("Fighter")==id then portrait=m end end
		end
		if portrait then
			local model=portrait:Clone()
			model.Name=id;model:SetAttribute("NinjaMaster",id)
			model.Parent=holder
			stand(model,spot.at,spot.face)
			local prompt=promptOn(model,id,"TALK",spot.place,spot.at.Y>4)
			if prompt then prompt:SetAttribute("NinjaMaster",id) end
		end
	end
	Hub.placeProctor(holder)
	Hub.placeTraining(holder)
	Hub.placeMarket(holder)
	Hub.placeSolo(holder)
end
-- (21/11, étape 3 DEV 4, DEC-047) The things to do alone in the plan's
-- village (Shared/Solo): the rooftop race's start post at THE ROOFTOPS, the
-- kunai targets down the market lane. Each its prompt (Client/SoloView
-- answers it: attribute NinjaSolo) and the pieces that say what it is, none in
-- the way of a walker (the ANIMATEUR's models may dress them: KunaiTarget).
function Hub.placeSolo(holder)
	if not Hub.folder or Hub.folder:GetAttribute("Layout")~="konoha2" or holder:FindFirstChild("RooftopRace") then return end
	local Solo=require(Shared.Solo)
	local function prompted(model,at,id,text,place)
		local anchor=Instance.new("Part");anchor.Name="Anchor"
		anchor.Size=Vector3.new(1,1,1);anchor.Transparency=1;anchor.Anchored=true
		anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
		anchor.CFrame=CFrame.new(at+Vector3.new(0,4,0));anchor.Parent=model
		model.PrimaryPart=anchor
		model.Parent=holder
		local prompt=promptOn(model,id,text,place,false)
		if prompt then prompt:SetAttribute("NinjaSolo",model:GetAttribute("NinjaSolo"));prompt.MaxActivationDistance=14 end
		return prompt
	end
	-- the race: a tall post with its red banner, the start line on the ground
	local post=Solo.startPost()
	local race=Instance.new("Model");race.Name="RooftopRace";race:SetAttribute("NinjaSolo","race")
	deco(race,"Post",Vector3.new(1.4,18,1.4),CFrame.new(post+Vector3.new(-3,9,0)),C.woodDark,Enum.Material.Wood)
	deco(race,"Banner",Vector3.new(.3,7,4),CFrame.new(post+Vector3.new(-3,13.5,2.4)),C.red,Enum.Material.Fabric)
	deco(race,"Line",Vector3.new(12,.12,1.2),CFrame.new(post+Vector3.new(4,.06,0))*CFrame.Angles(0,math.pi/2,0),C.cloth,Enum.Material.SmoothPlastic)
	prompted(race,post,"RooftopRace","ROOFTOP RACE","THE ROOFTOPS")
	-- the targets: the mark on the ground, each board on its post facing it
	local mark=Solo.targetsMark()
	local targets=Instance.new("Model");targets.Name="KunaiTargets";targets:SetAttribute("NinjaSolo","targets")
	local ring=deco(targets,"Mark",Vector3.new(.12,7,7),CFrame.new(mark+Vector3.new(0,.06,0))*CFrame.Angles(0,0,math.pi/2),C.red,Enum.Material.SmoothPlastic)
	ring.Shape=Enum.PartType.Cylinder
	for i in Solo.Targets.boards do
		local at=Solo.board(i)
		local foot=Vector3.new(at.X,O.Y,at.Z)
		local board=Instance.new("Model");board.Name="Target"..i;board:SetAttribute("NinjaTarget",i);board.Parent=targets
		deco(board,"Post",Vector3.new(.4,at.Y-O.Y,.4),CFrame.new((foot+at)/2+Vector3.new(.3,0,0)),C.woodDark,Enum.Material.Wood)
		for k,band in {{3.4,C.cloth},{2.4,C.red},{1.4,C.cloth},{.6,C.red}} do
			local disc=deco(board,"Disc",Vector3.new(.16+k*.02,band[1],band[1]),CFrame.new(at-Vector3.new(k*.02,0,0)),band[2],Enum.Material.SmoothPlastic)
			disc.Shape=Enum.PartType.Cylinder
		end
	end
	prompted(targets,mark,"KunaiTargets","KUNAI TARGETS","THE MARKET LANE")
end
-- (14/11, audit: the training ground had three stumps and a dummy, and
-- nothing to do there) The dummy of Training Ground Three: E trains with his
-- kit (Client/HubClient sends the board's TRAINING). An invisible anchor of its
-- own: the village's units may be swapped for meshes (MeshKit).
function Hub.placeTraining(holder)
	local spot=HubMap.Training
	if not spot or holder:FindFirstChild("Training") then return end
	local model=Instance.new("Model");model.Name="Training"
	model:SetAttribute("NinjaTrain",true)
	local anchor=Instance.new("Part");anchor.Name="Anchor"
	anchor.Size=Vector3.new(1,1,1);anchor.Transparency=1;anchor.Anchored=true
	anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
	anchor.CFrame=CFrame.new(O+spot.at+Vector3.new(0,5,0))
	anchor.Parent=model
	model.PrimaryPart=anchor
	model.Parent=holder
	local prompt=promptOn(model,"Training","TRAIN",spot.place,false)
	if prompt then prompt:SetAttribute("NinjaTrain",true) end
end
-- (14/11, François: « on va créer une boutique propre au jeu avec des Ryō »)
-- The market's counter, at the crossing of its lanes: E opens the looks sold
-- for Ryō (Client/ShopPanel, "market"). An invisible anchor of its own (the
-- village's units may be swapped for meshes); the stall's model is the
-- ANIMATEUR's.
function Hub.placeMarket(holder)
	local spot=HubMap.Market
	if not spot or holder:FindFirstChild("Market") then return end
	local model=Instance.new("Model");model.Name="Market"
	model:SetAttribute("NinjaMarket",true)
	local anchor=Instance.new("Part");anchor.Name="Anchor"
	anchor.Size=Vector3.new(1,1,1);anchor.Transparency=1;anchor.Anchored=true
	anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
	anchor.CFrame=CFrame.new(O+spot.at+Vector3.new(0,4,0))
	anchor.Parent=model
	model.PrimaryPart=anchor
	model.Parent=holder
	local prompt=promptOn(model,"Market","BUY WITH RYŌ",spot.place,false)
	if prompt then prompt:SetAttribute("NinjaMarket",true);prompt.MaxActivationDistance=14 end
end
-- The proctor on the hall's floor (the Professor's rig): the board of duels.
function Hub.placeProctor(holder)
	local ok,err=pcall(function()
		local World=require(script.Parent.World)
		local Portraits=require(script.Parent.Portraits)
		local Fighters=require(Shared.Fighters)
		local spot=HubMap.Proctor
		local def=Fighters[spot.kit]
		if not def then return end
		local model,_,root,joints=World.rig(holder,def,CFrame.new(O+spot.at+Vector3.new(0,3,0)),"Proctor")
		root.Anchored=true
		for name,angles in Portraits.STANCE or {} do
			local joint=joints[name] or model:FindFirstChild(name,true)
			if joint and joint:IsA("Motor6D") then joint.C0=joint.C0*angles end
		end
		Portraits.strip(model)
		model:SetAttribute("NinjaBoard",true)
		stand(model,spot.at,spot.face)
		local prompt=promptOn(model,"Proctor","DUELS",spot.place,false)
		if prompt then prompt:SetAttribute("NinjaBoard",true) end
	end)
	if not ok then warn("[NinjaDuel] hub proctor: "..tostring(err)) end
end

-- ------------------------------------------------------------------ the walkers
-- (DEC-040) His avatar's description without its clothes, at the standard
-- scales, fetched once per player (yields). nil: Roblox gave none (the
-- default character then).
Hub.descs=setmetatable({},{__mode="k"})
function Hub.description(player)
	if Hub.descs[player]~=nil then return Hub.descs[player] or nil end
	local desc=nil
	pcall(function()
		desc=require(script.Parent.AvatarBody).description(player.UserId)
		if desc then require(script.Parent.Outfit).strip(desc) end
	end)
	Hub.descs[player]=desc or false
	return desc
end
-- The player's own avatar in the village (the default character and controls).
-- `where`: "gate" (arrival) or "hall" (back from a duel). Asynchronous; a duel
-- that starts meanwhile wins (Hub.leave bumps the serial).
function Hub.enter(player,where,looks)
	if typeof(player)~="Instance" or not Hub.folder then return end
	local serial=(Hub.bodies[player] and Hub.bodies[player].serial or 0)+1
	Hub.bodies[player]={serial=serial}
	task.spawn(function()
		if not player.Parent then return end
		-- (DEC-040) his avatar without its clothes (body, face, hair) at the
		-- game's standard scales, then the outfit he chose (Server/Outfit)
		local desc=Hub.description(player)
		local ok=pcall(function()
			if desc then player:LoadCharacterWithHumanoidDescription(desc:Clone()) else player:LoadCharacter() end
		end)
		local entry=Hub.bodies[player]
		local character=player.Character
		if not ok or not entry or entry.serial~=serial or not character then
			if character and (not entry or entry.serial~=serial) and character:GetAttribute("NinjaHubBody") then character:Destroy() end
			return
		end
		character:SetAttribute("NinjaHubBody",true)
		entry.character=character
		-- (19/11) the prodigies' height, as in his duels (AvatarBody.grow),
		-- before the headband and the outfit are sized on his body
		pcall(function() require(script.Parent.AvatarBody).grow(character) end)
		-- (15/11) a passer-by never enters a street duel (Server/DuelQuery)
		pcall(function() require(script.Parent.DuelQuery).walker(character) end)
		-- (13/11, the shop) the headband he chose, on his own avatar.
		pcall(function() require(script.Parent.Headband).fromLooks(character,looks) end)
		pcall(function() require(script.Parent.Outfit).wear(character,looks) end)
		-- (14/11) back from a duel in the village: where it was fought
		local spot=if type(where)=="table" then where else HubMap.Spawns[where] or HubMap.Spawns.gate
		local at=O+spot.at+Vector3.new(0,3.5,0)
		pcall(function() character:PivotTo(CFrame.lookAt(at,at+spot.face)) end)
		local hum=character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				task.wait(2)
				local now=Hub.bodies[player]
				if now and now.serial==serial and player.Parent then Hub.enter(player,"gate",looks) end
			end)
		end
	end)
end
-- (14/11) What the others see over his head in the village (Client/HubPlayers):
-- the kit he fights with and its mastery, as player attributes (replicated).
-- `view`: Progression.view (nil when the progression is off: his name only).
function Hub.badge(player,view)
	if typeof(player)~="Instance" then return end
	local kit=view and view.selected
	if kit and not (view.owned and view.owned[kit]) then kit=nil end
	pcall(function()
		player:SetAttribute("NinjaKit",kit)
		player:SetAttribute("NinjaMastery",if kit and view.mastery then view.mastery[kit] or 0 else nil)
	end)
end
-- A look changed while he walks (the shop): his headband, at once.
function Hub.restyle(player,looks)
	local entry=Hub.bodies[player]
	local character=entry and entry.character
	if character and character.Parent and character:GetAttribute("NinjaHubBody") then
		pcall(function() require(script.Parent.Headband).fromLooks(character,looks) end)
		pcall(function() require(script.Parent.Outfit).wear(character,looks) end)
	end
end
function Hub.leave(player)
	local entry=Hub.bodies[player]
	Hub.bodies[player]={serial=(entry and entry.serial or 0)+1}
	local character=typeof(player)=="Instance" and player.Character or (entry and entry.character)
	if character and character:GetAttribute("NinjaHubBody") then character:Destroy() end
end
function Hub.forget(player)
	Hub.leave(player)
	Hub.bodies[player]=nil
end

-- Server start (Main): build, then the masters once the portraits exist.
-- (23/11, step 5, DEC-049) The walker's ninja body seen by everyone: each
-- screen poses every walker with his kit's clips (Client/HubBody), but what a
-- client writes on joints stays on that client. Speed and height travel with
-- the body's physics; the rest (up a wall, the bound, the kick off a wall,
-- the hop over an edge) is sent here by its owner and set on his character,
-- which every client reads: NinjaPose (the state) and NinjaPoseSeq (+1 at
-- each, so the same move twice is seen twice). Only those words, at most
-- POSE_RATE a second.
Hub.POSES={climb=true,leap=true,kick=true,vault=true,none=true}
Hub.POSE_RATE=12
function Hub.pose(player,state,now,buckets)
	if type(state)~="string" or not Hub.POSES[state] then return false end
	local b=buckets[player]
	if not b or now-b.at>=1 then b={at=now,n=0};buckets[player]=b end
	if b.n>=Hub.POSE_RATE then return false end
	b.n+=1
	local character=player.Character
	if not character then return false end
	character:SetAttribute("NinjaPose",state)
	character:SetAttribute("NinjaPoseSeq",(character:GetAttribute("NinjaPoseSeq") or 0)+1)
	return true
end
function Hub.startPoses()
	local Shared=ReplicatedStorage:FindFirstChild("NinjaDuel")
	if not Shared or Shared:FindFirstChild("HubPose") then return end
	local remote=Instance.new("RemoteEvent");remote.Name="HubPose";remote.Parent=Shared
	local buckets={}
	remote.OnServerEvent:Connect(function(player,state) Hub.pose(player,state,os.clock(),buckets) end)
	game:GetService("Players").PlayerRemoving:Connect(function(player) buckets[player]=nil end)
end

function Hub.start()
	Hub.build(workspace)
	Hub.startPoses()
	-- (14/11) the creator and the champions carved on the cliff. Its own
	-- thread: (14/11, seen in Studio) MessagingService:SubscribeAsync never
	-- returned in a local file and held the whole server start (no roster,
	-- no village, no progression).
	task.spawn(function() pcall(function() require(script.Parent.ChampionCliff).begin(Hub.folder) end) end)
	task.spawn(function()
		local source=ReplicatedStorage:WaitForChild("NinjaDuelPortraits",120)
		if source then
			-- The portraits arrive one per frame: wait for the eight.
			local t=os.clock()
			while #source:GetChildren()<8 and os.clock()-t<30 do task.wait(.5) end
			Hub.placeMasters(source)
		end
	end)
end

return Hub
