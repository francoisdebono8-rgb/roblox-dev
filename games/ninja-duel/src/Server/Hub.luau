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
	pcall(function()
		workspace.Terrain:FillBlock(rel((lx1+lx2)/2,-2.2,(lz1+lz2)/2),Vector3.new(lx2-lx1,3.6,lz2-lz1),Enum.Material.Water)
	end)
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
	-- The hand-sign statue at the back.
	part(m,"Pedestal",Vector3.new(22,4,10),rel(0,2,-114),C.stoneDark,Enum.Material.Slate)
	for _,side in {-1,1} do
		local arm=part(m,"StatueArm",Vector3.new(5,22,5),rel(side*3.6,14,-114)*CFrame.Angles(0,0,side*math.rad(9)),C.stone,Enum.Material.Concrete)
		deco(m,"StatueHand",Vector3.new(5.6,6,4.4),arm.CFrame*CFrame.new(0,13,0),C.stone,Enum.Material.Concrete)
		deco(m,"StatueFinger",Vector3.new(1.4,6,1.4),arm.CFrame*CFrame.new(side*-1.2,18.5,0),C.stone,Enum.Material.Concrete)
		deco(m,"StatueFinger",Vector3.new(1.4,5.2,1.4),arm.CFrame*CFrame.new(side*.4,18.1,0),C.stone,Enum.Material.Concrete)
	end
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
local function faces(f)
	-- The cliff; the four places each a unit of their own (14/11): an empty
	-- place waiting for its champion (the ANIMATOR's HeadSlot1..4: the block
	-- roughed out, scaffolding, a blank plaque) until Server/ChampionCliff
	-- carves the creator or a champion there (it turns the unit DressOff). The
	-- plaque stays (Keep): « the next face here could be yours », then a name.
	local cliff=unit(f,"HokageCliff","HokageCliff",CFrame.new(O))
	part(cliff,"Cliff",Vector3.new(330,92,32),rel(0,46,-248),C.rock,Enum.Material.Rock)
	for k,at in HubMap.Heads do
		local s=HubMap.HeadScale
		local slot=unit(f,"CliffHead","HeadSlot"..k,CFrame.new(O+at),s)
		slot:SetAttribute("HeadSlot",k)
		part(slot,"Face",Vector3.new(26*s.X,30*s.Y,8*s.Z),CFrame.new(O+at),C.rock,Enum.Material.Rock)
		local plate=keep(deco(slot,"SlotPlate",Vector3.new(14*s.X,3.2*s.Y,.3),CFrame.new(O+at+Vector3.new(0,-12.4*s.Y,3.95*s.Z)),C.rockDark,Enum.Material.Slate))
		sign(plate,Enum.NormalId.Back,Hub.SLOT_TEXT,rgb(236,222,190))
	end
	local terrace=unit(f,"FacesTerrace","FacesTerrace",CFrame.new(O))
	part(terrace,"Terrace",Vector3.new(84,24,26),rel(0,12,-219),C.stone,Enum.Material.Slate)
	for _,x in {-41,41} do part(terrace,"TerraceRail",Vector3.new(1,3,26),rel(x,25.5,-219),C.woodDark,Enum.Material.Wood) end
	-- The front rail leaves the stairs' mouth open in the middle.
	for _,x in {-26,26} do part(terrace,"TerraceRail",Vector3.new(30,3,1),rel(x,25.5,-206.5),C.woodDark,Enum.Material.Wood) end
	for step=1,24 do
		part(terrace,"Step",Vector3.new(20,step,2.8),rel(0,step/2,-140-(step-1)*2.8),C.stone,Enum.Material.Slate)
	end
	for _,x in {-11,11} do
		for step=4,24,4 do lantern(f,rel(x,step+3,-140-(step-1)*2.8),step%8==0) end
	end
end
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
end

-- Builds the village once per server (Main). Headless: the parts are built in
-- the given parent.
function Hub.build(parent)
	if Hub.folder and Hub.folder.Parent then return Hub.folder end
	local f=Instance.new("Folder");f.Name="NinjaDuelHub"
	ground(f);gate(f);street(f);plaza(f);hall(f);training(f);hyuga(f);uchiha(f);faces(f);quarters(f);forest(f)
	f.Parent=parent or workspace
	Hub.folder=f;Hub.built=true
	return f
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
-- The player's own avatar in the village (the default character and controls).
-- `where`: "gate" (arrival) or "hall" (back from a duel). Asynchronous; a duel
-- that starts meanwhile wins (Hub.leave bumps the serial).
function Hub.enter(player,where,looks)
	if typeof(player)~="Instance" or not Hub.folder then return end
	local serial=(Hub.bodies[player] and Hub.bodies[player].serial or 0)+1
	Hub.bodies[player]={serial=serial}
	task.spawn(function()
		if not player.Parent then return end
		local ok=pcall(function() player:LoadCharacter() end)
		local entry=Hub.bodies[player]
		local character=player.Character
		if not ok or not entry or entry.serial~=serial or not character then
			if character and (not entry or entry.serial~=serial) and character:GetAttribute("NinjaHubBody") then character:Destroy() end
			return
		end
		character:SetAttribute("NinjaHubBody",true)
		entry.character=character
		-- (13/11, the shop) the headband he chose, on his own avatar.
		pcall(function() require(script.Parent.Headband).fromLooks(character,looks) end)
		local spot=HubMap.Spawns[where] or HubMap.Spawns.gate
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
function Hub.start()
	Hub.build(workspace)
	-- (14/11) the creator and the champions carved on the cliff
	pcall(function() require(script.Parent.ChampionCliff).begin(Hub.folder) end)
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
