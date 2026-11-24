-- Life in the streets of the new Konoha (21/11, étape 3 ANIMATEUR 1, DEC-047; François: « il n'y
-- a rien à faire dans le village quand on est seul », the village has to feel lived in).
-- What a Part I establishing shot of the village has, drawn round the plan (Shared/KonohaLayout,
-- the same frame as Server/Hub: HubMap.Origin + base studs x HubMap.Scale):
--   * steam over Ichiraku's pot and over the shops' kitchens, thin smoke from a few roofs;
--   * strings of paper bunting across the market streets, swaying;
--   * birds wheeling high over the plaza and the market;
--   * leaves drifting through the training ground and the residences.
-- Cheap on purpose (a few emitters, parts that only move by CFrame), client side only, and
-- nothing that a fight in the street can collide with (CanCollide/CanQuery off, high up).
local RunService=game:GetService("RunService")
local AwakenFX=require(script.Parent.AwakenFX)
local emit=AwakenFX.emitter

local Life={}
Life.clock=os.clock
local C=Color3.fromRGB
local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function range(a,b) return NumberRange.new(a,b or a) end
local function part(parent,size,cf,color,material,name)
	local p=Instance.new("Part")
	p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Name=name or "Life"
	p.Parent=parent
	return p
end

-- Base studs of the plan -> the world (as Server/Hub builds it).
function Life.world(origin,scale,x,y,z) return origin+Vector3.new(x,y,z)*scale end

-- What goes where, from the plan alone (pure: the headless test reads it).
-- Returns {steam={{pos,size}}, smoke={...}, bunting={{a,b}}, birds={{centre,radius,height}}, leaves={pos...}}
function Life.plan(Layout,origin,scale,zones)
	zones=zones or {}
	local out={steam={},smoke={},bunting={},birds={},leaves={},nobori={}}
	local n=0
	for _,b in Layout.Buildings do
		local model,x,z,h=b[1],b[2],b[3],b[6]
		n+=1
		if model=="ichiraku" then
			table.insert(out.steam,{pos=Life.world(origin,scale,x,h+1,z),size=1.4})
		elseif model=="shop_house" and n%2==0 then
			table.insert(out.steam,{pos=Life.world(origin,scale,x,h+.5,z),size=1})
		elseif (model=="tank_house" or model=="apartment") and n%4==1 then
			table.insert(out.smoke,{pos=Life.world(origin,scale,x+3,h+2,z-2),size=1.2})
		end
		-- (22/11) a nobori, the tall shop banner, at the front corner of the shops
		if (model=="shop_house" or model=="ichiraku") and b[8]~="Uchiha" then
			local w,d,yaw=b[4],b[5],math.rad(b[7] or 0)
			local side=if n%2==0 then 1 else -1
			local lx,lz=side*(w/2-1),d/2+1.4                 -- yaw 0: the door looks at +Z
			local wx,wz=lx*math.cos(yaw)+lz*math.sin(yaw),-lx*math.sin(yaw)+lz*math.cos(yaw)
			local fx,fz=math.sin(yaw),math.cos(yaw)
			local spot=Life.world(origin,scale,x+wx,0,z+wz)
			if not Life.inClear(zones,spot-origin) then table.insert(out.nobori,{pos=spot,face=Vector3.new(fx,0,fz),n=n}) end
		end
	end
	for _,s in Layout.Streets do
		if string.find(s.id,"^Market") or s.id=="MainStreet" then
			local a,b=s.a,s.b
			local len=(b-a).Magnitude
			local dir=(b-a).Unit
			local across=Vector2.new(-dir.Y,dir.X)*(s.width/2+2)
			local count=math.floor(len/48)
			for k=1,count do
				local c=a+dir*(k*len/(count+1))
				local p,q=c+across,c-across
				table.insert(out.bunting,{a=Life.world(origin,scale,p.X,16,p.Y),b=Life.world(origin,scale,q.X,16,q.Y)})
			end
		end
		-- (22/11) laundry on lines across the back alleys and the residences' lanes
		if s.id=="BackAlley" or s.id=="AlleyLink" or s.id=="Residences" or s.id=="ResNorth" or s.id=="ResWest" or s.id=="UchihaStreet" then
			local a,b=s.a,s.b
			local len=(b-a).Magnitude
			local dir=(b-a).Unit
			local across=Vector2.new(-dir.Y,dir.X)*(s.width/2+2)
			local count=math.floor(len/40)
			for k=1,count do
				local c=a+dir*(k*len/(count+1)+((k*37)%11-5))
				local p,q=c+across,c-across
				table.insert(out.bunting,{a=Life.world(origin,scale,p.X,11,p.Y),b=Life.world(origin,scale,q.X,11,q.Y),laundry=true})
			end
		end
	end
	for _,d in Layout.Districts do
		local cx,cz=(d.x0+d.x1)/2,(d.z0+d.z1)/2
		if d.id=="Centre" or d.id=="Market" or d.id=="Residences" then
			table.insert(out.birds,{centre=Life.world(origin,scale,cx,0,cz),radius=math.min(d.x1-d.x0,d.z1-d.z0)*.35*scale,height=(60+#out.birds*12)*scale})
		end
		if d.id=="Training" or d.id=="Residences" or d.id=="Centre" then
			for k=0,2 do
				table.insert(out.leaves,Life.world(origin,scale,d.x0+(d.x1-d.x0)*(.25+k*.25),22,cz))
			end
		end
	end
	return out
end

-- ------------------------------------------------------------------ drawing it
local PAPER={C(196,58,42),C(236,226,198),C(232,176,60),C(70,110,160),C(110,150,80)}
local CLOTHES={C(236,232,222),C(70,96,150),C(196,72,60),C(220,190,110),C(120,150,110),C(60,60,70),C(230,200,200)}
local BANNERS={C(176,40,34),C(40,52,110),C(236,226,198),C(224,164,52),C(60,110,80)}
function Life.build(folder,plan)
	local made={birds={},bunting={}}
	for _,s in plan.steam do
		local p=part(folder,Vector3.one*.4,CFrame.new(s.pos),C(0,0,0),nil,"LifeSteam");p.Transparency=1
		local a=Instance.new("Attachment");a.Parent=p
		emit(a,"smoke",{Name="LifeSteam",Rate=3*s.size,Lifetime=range(1.6,2.4),Speed=range(1,2),SpreadAngle=Vector2.new(15,15),
			Acceleration=Vector3.new(.6,1.2,0),Color=ColorSequence.new(C(244,242,238)),LightEmission=.1,
			Size=seq({{0,1.2*s.size},{1,3.6*s.size}}),Transparency=seq({{0,.7},{.5,.78},{1,1}}),Rotation=range(0,360),RotSpeed=range(-15,15)}).Enabled=true
	end
	for _,s in plan.smoke do
		local p=part(folder,Vector3.one*.4,CFrame.new(s.pos),C(0,0,0),nil,"LifeSmoke");p.Transparency=1
		local a=Instance.new("Attachment");a.Parent=p
		emit(a,"smoke",{Name="LifeSmoke",Rate=1.5,Lifetime=range(3,4.5),Speed=range(1.5,2.5),SpreadAngle=Vector2.new(8,8),
			Acceleration=Vector3.new(1.2,.8,0),Color=ColorSequence.new(C(150,146,140),C(200,198,194)),
			Size=seq({{0,1},{1,5}}),Transparency=seq({{0,.75},{1,1}}),Rotation=range(0,360),RotSpeed=range(-10,10)}).Enabled=true
	end
	for i,b in plan.bunting do
		local holder=Instance.new("Model");holder.Name="LifeBunting";holder.Parent=folder
		local mid=(b.a+b.b)/2-Vector3.new(0,2,0)
		local flags={}
		local pts={}
		for k=0,8 do
			local t=k/8
			local p=b.a:Lerp(b.b,t)-Vector3.new(0,2*math.sin(t*math.pi)*1.2,0)
			table.insert(pts,p)
		end
		for k=1,#pts-1 do
			local p,q=pts[k],pts[k+1]
			local rope=part(holder,Vector3.new(.08,.08,(q-p).Magnitude),CFrame.lookAt((p+q)/2,q),C(90,70,50),Enum.Material.Fabric,"LifeRope")
			if b.laundry then
				-- a shirt, a towel, a gap: hung by their top edge
				if (k+i)%3~=0 then
					local tall=if (k*7+i)%2==0 then 1.6 else 1.1
					local flag=part(holder,Vector3.new(.05,tall,1.3),CFrame.lookAt((p+q)/2,q)*CFrame.new(0,-tall/2-.05,0),CLOTHES[(k*3+i)%#CLOTHES+1],Enum.Material.Fabric,"LifeLaundry")
					table.insert(flags,{part=flag,base=flag.CFrame,phase=k*.9+i,pivot=tall/2,swing=.35})
				end
			else
				local flag=part(holder,Vector3.new(.04,1.1,.9),CFrame.lookAt((p+q)/2,q)*CFrame.new(0,-.6,0),PAPER[(k+i)%#PAPER+1],Enum.Material.Fabric,"LifeFlag")
				table.insert(flags,{part=flag,base=flag.CFrame,phase=k*.7+i,pivot=.55,swing=.25})
			end
		end
		table.insert(made.bunting,flags)
	end
	for _,nb in plan.nobori do
		local holder=Instance.new("Model");holder.Name="LifeNobori";holder.Parent=folder
		local base=CFrame.lookAt(nb.pos,nb.pos+nb.face)
		part(holder,Vector3.new(.3,10,.3),base*CFrame.new(0,5,0),C(70,50,36),Enum.Material.Wood,"Pole")
		part(holder,Vector3.new(1.8,.16,.16),base*CFrame.new(.9,9.8,0),C(70,50,36),Enum.Material.Wood,"Bar")
		local banner=part(holder,Vector3.new(1.5,5.6,.06),base*CFrame.new(.9,6.9,0),BANNERS[nb.n%#BANNERS+1],Enum.Material.Fabric,"Banner")
		-- its plain brush mark (no real word), swinging with it
		local mark=part(holder,Vector3.new(.35,3.6,.08),base*CFrame.new(.9,6.9,0),if nb.n%#BANNERS==2 then C(30,30,34) else C(240,236,226),Enum.Material.SmoothPlastic,"Mark")
		table.insert(made.bunting,{{part=banner,base=banner.CFrame,phase=nb.n*.37,pivot=2.8,swing=.12,axis="x"},
			{part=mark,base=mark.CFrame,phase=nb.n*.37,pivot=2.8,swing=.12,axis="x"}})
	end
	for f,fl in plan.birds do
		for k=1,6 do
			local bird=Instance.new("Model");bird.Name="LifeBird";bird.Parent=folder
			local body=part(bird,Vector3.new(.35,.3,1.1),CFrame.new(fl.centre),C(40,38,44),nil,"Body")
			local wl=part(bird,Vector3.new(1.4,.06,.5),CFrame.new(fl.centre),C(50,48,54),nil,"Wing")
			local wr=part(bird,Vector3.new(1.4,.06,.5),CFrame.new(fl.centre),C(50,48,54),nil,"Wing")
			table.insert(made.birds,{body=body,wl=wl,wr=wr,flock=fl,phase=k/6*math.pi*2+f,lag=k*.06,height=fl.height+(k%3)*1.5})
		end
	end
	for _,pos in plan.leaves do
		local p=part(folder,Vector3.new(30,2,30),CFrame.new(pos),C(0,0,0),nil,"LifeLeaves");p.Transparency=1
		local a=Instance.new("Attachment");a.Parent=p
		emit(a,"leaf",{Name="LifeLeaves",Rate=1.2,Lifetime=range(5,7),Speed=range(.5,1.5),SpreadAngle=Vector2.new(180,180),
			Acceleration=Vector3.new(1.5,-1.6,.6),Drag=.8,Rotation=range(0,360),RotSpeed=range(-90,90),
			Shape=Enum.ParticleEmitterShape.Box,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume,
			Color=ColorSequence.new(C(120,150,70),C(200,150,60)),Size=seq({{0,.45},{1,.4}}),Transparency=seq({{0,0},{.85,.1},{1,1}})}).Enabled=true
	end
	return made
end

-- One step: the birds wheel and flap, the bunting sways.
function Life.step(made,t,eye)
	for _,b in made.birds do
		local fl=b.flock
		local a=t*.18+b.phase
		local pos=fl.centre+Vector3.new(math.cos(a)*fl.radius,b.height+math.sin(t*.7+b.phase)*3,math.sin(a)*fl.radius)
		local ahead=fl.centre+Vector3.new(math.cos(a+.05)*fl.radius,b.height,math.sin(a+.05)*fl.radius)
		local cf=CFrame.lookAt(pos,ahead)
		local flap=math.sin(t*9+b.phase*3)*.6
		b.body.CFrame=cf
		b.wl.CFrame=cf*CFrame.new(-.7,0,0)*CFrame.Angles(0,0,flap)
		b.wr.CFrame=cf*CFrame.new(.7,0,0)*CFrame.Angles(0,0,-flap)
	end
	for _,flags in made.bunting do
		-- only the lines and banners near the camera move (the far ones are still)
		if eye and flags[1] and (flags[1].base.Position-eye).Magnitude>240 then continue end
		for _,f in flags do
			-- swung from its top edge (a flag, a shirt, a banner on its bar)
			local a=math.sin(t*1.6+f.phase)*(f.swing or .25)
			local up=CFrame.new(0,f.pivot or .55,0)
			f.part.CFrame=f.base*up*(if f.axis=="x" then CFrame.Angles(a,0,0) else CFrame.Angles(0,0,a))*up:Inverse()
		end
	end
end

-- ------------------------------------------------------------------ the kunai boards
-- The market lane's boards (Server/Hub: KunaiTargets/Target<i>, Shared/Solo) wear the modelled
-- board (Client/PropMeshData "kunai_board": wood, rings, a rim, two kunai stuck in it),
-- facing the throw mark; Hub's own post stays, its plain discs are hidden here. The mesh goes
-- INSIDE Target<i>, so SoloView hiding a hit board hides it too. Headless or without
-- AssetService nothing changes (the discs stay).
function Life.boardFrame(at,mark)
	local flat=Vector3.new(mark.X,at.Y,mark.Z)-at
	if flat.Magnitude<1e-3 then flat=Vector3.new(-1,0,0) end
	return CFrame.lookAt(at,at-flat.Unit)   -- -Z away from the mark: the face (+Z) toward it
end
function Life.dressBoards(targets,Solo,build,data)
	local specs=data and data.kunai_board
	if not (targets and Solo and build and specs) then return 0 end
	local mark=Solo.targetsMark()
	local n=0
	for i in Solo.Targets.boards do
		local board=targets:FindFirstChild("Target"..i)
		if board and not board:FindFirstChild("BoardMesh") then
			local cf=Life.boardFrame(Solo.board(i),mark)
			local holder=Instance.new("Model");holder.Name="BoardMesh"
			local ok=pcall(function()
				for _,spec in specs do
					local p=build(spec)
					p.CFrame=cf*CFrame.new(spec.o[1],spec.o[2],spec.o[3])
					p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
					p.Parent=holder
				end
			end)
			if ok then
				holder.Parent=board
				for _,x in board:GetChildren() do if x:IsA("BasePart") and x.Name=="Disc" then x.Transparency=1 end end
				n+=1
			else
				holder:Destroy()
			end
		end
	end
	return n
end

-- ------------------------------------------------------------------ the market's props
-- (22/11, seen in a render of the plan: Server/Hub's stalls and barrels are plain blocks, brown
-- crates the size of a car down the market lanes) Each Prop_stall / Prop_barrel wears its model
-- (PropMeshData "market_stall", "barrel"), standing on the block's foot; the block stays (it is
-- what one bumps into) and is hidden here.
Life.PROPS={Prop_stall="market_stall",Prop_barrel="barrel"}
function Life.propFoot(p)
	local pos=p.CFrame.Position
	local half=if p.Name=="Prop_barrel" then 1.8 else p.Size.Y/2
	local look=p.CFrame.LookVector
	if p.Name=="Prop_barrel" then look=Vector3.new(0,0,-1) end   -- (Hub turns the barrel's cylinder on its side)
	local flat=Vector3.new(look.X,0,look.Z)
	if flat.Magnitude<1e-3 then flat=Vector3.new(0,0,-1) end
	return CFrame.lookAt(pos-Vector3.new(0,half,0),pos-Vector3.new(0,half,0)+flat.Unit)
end
function Life.dressProps(root,build,data)
	local n=0
	for _,p in root:GetDescendants() do
		local model=p:IsA("BasePart") and Life.PROPS[p.Name]
		local specs=model and data[model]
		if specs and not p:GetAttribute("LifeDressed") and not p:GetAttribute("LifeCleared") then
			local foot=Life.propFoot(p)
			local holder=Instance.new("Model");holder.Name="LifeProp"
			local ok=pcall(function()
				for _,spec in specs do
					local m=build(spec)
					m.CFrame=foot*CFrame.new(spec.o[1],spec.o[2],spec.o[3])
					m.Anchored=true;m.CanCollide=false;m.CanQuery=false;m.CanTouch=false
					m.Parent=holder
				end
			end)
			if ok then
				holder.Parent=p.Parent
				p.Transparency=1
				p:SetAttribute("LifeDressed",true)
				n+=1
			else
				holder:Destroy()
			end
		end
	end
	return n
end

-- ------------------------------------------------------------------ the places kept clear
-- (24/11, passe commune 1: « le personnage apparaît debout sur un tonneau ») Nothing of the
-- village's clutter where one arrives, where a master stands and fights, at the street-duel
-- places: the arrival points, the masters and their duel rings, the welcome trio, Training
-- Ground Three's ring, the street-duel places (HubMap, already scaled, relative to its Origin).
-- Returns {{at=Vector3 (relative), r=studs}}.
function Life.zones(HubMap)
	local s=HubMap.Scale or 1
	local out={}
	local function add(at,r) if at then table.insert(out,{at=Vector3.new(at.X,0,at.Z),r=r}) end end
	for _,spot in HubMap.Spawns or {} do add(spot.at,18*s) end
	for _,m in HubMap.Masters or {} do
		add(m.at,12*s)
		if m.duel then add(m.duel.at,m.duel.radius) end
	end
	for _,w in HubMap.Welcome or {} do add(w.at,8*s) end
	if HubMap.Training and HubMap.Training.duel then add(HubMap.Training.duel.at,HubMap.Training.duel.radius) end
	for _,street in HubMap.Streets or {} do add(street.at,street.radius or 14*s) end
	return out
end
-- (pure) Whether a point (relative to HubMap.Origin) stands in a kept-clear place.
function Life.inClear(zones,rel)
	for _,z in zones do
		local d=Vector3.new(rel.X,0,rel.Z)-z.at
		if d.Magnitude<z.r then return true end
	end
	return false
end
-- The clutter the village's plan puts down (Server/Hub: Prop_barrel, Prop_stall, Prop_post, and
-- the Crate, Bench, FenceSegment and Stump units): in a kept-clear place, gone from this screen
-- (hidden, not solid, not queried, their dressed meshes too). Returns how many.
Life.CLUTTER={Prop_barrel=true,Prop_stall=true,Prop_post=true,Crate=true,Bench=true,FenceSegment=true,Stump=true}
function Life.clearProps(root,zones,origin,copiesOf)
	local n=0
	local function gone(p)
		p.LocalTransparencyModifier=1;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
		for _,c in (copiesOf and copiesOf[p]) or {} do if c:IsA("BasePart") then c.LocalTransparencyModifier=1 end end
	end
	for _,d in root:GetDescendants() do
		if Life.CLUTTER[d.Name] then
			local at=nil
			if d:IsA("BasePart") then at=d.CFrame.Position
			elseif d:IsA("Model") then
				local p=d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart",true)
				at=p and p.CFrame.Position
			end
			if at and Life.inClear(zones,at-origin) then
				-- again at every pass: the village's dresser may draw its meshes after us
				if not d:GetAttribute("LifeCleared") then n+=1 end
				d:SetAttribute("LifeCleared",true)
				if d:IsA("BasePart") then gone(d) end
				for _,q in d:GetDescendants() do if q:IsA("BasePart") then gone(q) end end
				-- a prop dressed here (Life.dressProps) is a "LifeProp" beside its block
				for _,q in (d.Parent and d.Parent:GetChildren() or {}) do
					local qp=q.Name=="LifeProp" and q:IsA("Model") and q:FindFirstChildWhichIsA("BasePart",true)
					if qp and (qp.CFrame.Position-at).Magnitude<8 then q:Destroy() end
				end
			end
		end
	end
	return n
end

-- ------------------------------------------------------------------ each house its colours
-- (22/11, François: « la différence entre les bâtiments n'est pas assez forte, le village est
-- trop lisse ») The six house models were the same everywhere. A Part I Konoha is a patchwork:
-- ochre, peach, pink, pale green and white plaster side by side, roofs that change by quarter.
-- The modelled pieces carry their shading in vertex colours under a white part colour, so a part
-- colour tints them (as the wardrobe paints its slots): every house gets its own plaster from
-- its quarter's palette and its quarter's roofs, each a little different. Landmarks keep theirs.
local T=Color3.new
Life.PALETTE={
	-- walls: plaster tints; roofs: tile tints; cloth: noren and awnings
	Market={walls={T(1,.86,.62),T(1,.8,.7),T(1,.78,.8),T(1,.97,.9),T(.92,1,.84),T(1,.9,.55)},roofs={T(.95,.5,.4),T(1,.62,.42),T(.9,.42,.36)},cloth={T(1,.35,.3),T(.3,.45,1),T(1,.8,.3),T(.4,.8,.5)}},
	Residences={walls={T(.86,.93,1),T(.92,1,.86),T(1,.92,.84),T(1,.84,.86),T(1,1,.94),T(.95,.88,1)},roofs={T(.55,.68,.95),T(.5,.8,.62),T(.62,.72,.9)},cloth={T(.4,.6,1),T(.9,.5,.6)}},
	Alleys={walls={T(.86,.82,.76),T(.95,.85,.66),T(.8,.84,.84),T(.9,.78,.7)},roofs={T(.72,.5,.42),T(.6,.62,.66),T(.55,.45,.4)},cloth={T(.7,.45,.35),T(.45,.55,.6)}},
	Centre={walls={T(1,.94,.84),T(1,.86,.72),T(1,.98,.94)},roofs={T(.92,.46,.34),T(.82,.38,.3)},cloth={T(1,.4,.3),T(1,.85,.4)}},
	TeaStreet={walls={T(1,.9,.78),T(1,.84,.84),T(1,.97,.9)},roofs={T(.6,.42,.36),T(.5,.5,.56)},cloth={T(.3,.4,.8),T(.85,.3,.3)}},
	Main={walls={T(1,.92,.8),T(1,.98,.94)},roofs={T(.92,.46,.34)},cloth={T(1,.45,.3)}},
	Civic={walls={T(1,.88,.74),T(1,.95,.86)},roofs={T(.95,.5,.36),T(.85,.4,.3)},cloth={T(1,.5,.3)}},
	Uchiha={walls={T(1,1,.97),T(.96,.94,.9)},roofs={T(.34,.34,.4),T(.28,.28,.32)},timber={T(.55,.42,.4)},cloth={T(.75,.2,.2)}},
	Hyuga={walls={T(1,1,1),T(.97,.97,.95)},roofs={T(.62,.66,.74)},cloth={T(.75,.75,.9)}},
	Training={walls={T(.95,.9,.8)},roofs={T(.6,.55,.5)},cloth={T(.6,.7,.5)}},
}
-- The quarter of a base-frame point (KonohaLayout.Districts; the last that holds it).
function Life.district(Layout,x,z)
	local found
	for _,d in Layout.Districts do
		if x>=d.x0 and x<=d.x1 and z>=d.z0 and z<=d.z1 then found=d.id end
	end
	return found
end
-- A house's colours: its quarter's palette, picked by its place (the same for every player).
function Life.colours(district,x,z)
	local pal=Life.PALETTE[district or ""] or Life.PALETTE.Centre
	local h=math.abs(math.floor(x*73.1+z*37.7))
	local function of(list,salt) return list and list[(h+salt)%#list+1] end
	local wobble=((h%7)-3)*.012
	local walls=of(pal.walls,0)
	walls=T(math.clamp(walls.R+wobble,0,1),math.clamp(walls.G+wobble,0,1),math.clamp(walls.B+wobble,0,1))
	return {Walls=walls,Tiles=of(pal.roofs,3),Cloth=of(pal.cloth,5),Timber=of(pal.timber,1)}
end
-- Tints the dressed copies of every house unit under `root` (HubDress.copiesOf: the mesh copies
-- standing for a unit's parts). Returns how many houses took their colours.
Life.HOUSES={small_house=true,machiya=true,tank_house=true,shop_house=true,apartment=true,clan_house=true}
Life.tinted=setmetatable({},{__mode="k"})   -- the copies lists already tinted (a re-dress makes a new list)
function Life.tintHouses(root,copiesOf,Layout,origin,scale)
	local n=0
	for _,unit in root:GetDescendants() do
		if unit:IsA("Model") and Life.HOUSES[unit:GetAttribute("LayoutModel") or ""] then
			local walls=unit:FindFirstChild("Walls")
			local copies=walls and copiesOf[walls]
			local at=unit:GetAttribute("DressAt")
			if copies and not Life.tinted[copies] and typeof(at)=="CFrame" then
				local base=(at.Position-origin)/scale
				local cols=Life.colours(Life.district(Layout,base.X,base.Z),base.X,base.Z)
				for _,p in copies do
					local c=cols[p.Name]
					if c and p:IsA("BasePart") then p.Color=c end
				end
				Life.tinted[copies]=true
				n+=1
			end
		end
	end
	return n
end

-- In the game: once the new village is built (Config.Hub.Layout "konoha2"), on this client.
function Life.start()
	if Life.started then return end
	Life.started=true
	task.spawn(function()
		local RS=game:GetService("ReplicatedStorage")
		local shared=RS:WaitForChild("NinjaDuel",30)
		if not shared then return end
		local ok,Layout=pcall(require,shared:WaitForChild("KonohaLayout",10))
		local ok2,HubMap=pcall(require,shared:WaitForChild("HubMap",10))
		if not (ok and ok2 and Layout and HubMap) then return end
		local okc,Config=pcall(require,shared:WaitForChild("Config",10))
		if okc and Config and Config.Hub and Config.Hub.Layout and Config.Hub.Layout~="konoha2" then return end
		if okc and Config and Config.Hub and Config.Hub.Enabled~=true then return end
		-- only where the village stands (the hub server builds NinjaDuelHub; not in a duel place)
		local hub=workspace:WaitForChild("NinjaDuelHub",60)
		if not hub then return end
		local zones=Life.zones(HubMap)
		local okHD,HD=pcall(require,script.Parent.HubDress)
		local copiesOf=okHD and HD and HD.copiesOf or nil
		task.spawn(function()
			local okS,Solo=pcall(require,shared:WaitForChild("Solo",10))
			local okM,MeshKit=pcall(require,script.Parent.MeshKit)
			local okD,data=pcall(require,script.Parent.PropMeshData)
			if not (okS and okM and okD) then return end
			-- each piece built once (an EditableMesh baked), then cloned for every copy
			local made={}
			local function build(spec)
				local t=made[spec]
				if not t then t=MeshKit.build(spec);made[spec]=t end
				return t:Clone()
			end
			local boards=false
			for _=1,30 do   -- the hub's units may stream in a little after
				local targets=hub:FindFirstChild("KunaiTargets",true)
				if not boards and targets and Life.dressBoards(targets,Solo,build,data)>0 then boards=true end
				pcall(Life.clearProps,hub,zones,HubMap.Origin,copiesOf)
				pcall(Life.dressProps,hub,build,data)
				task.wait(2)
			end
		end)
		task.spawn(function()
			local okH,HubDress=pcall(require,script.Parent.HubDress)
			if not okH then return end
			-- the houses are dressed as their meshes come (MeshKit builds the village late)
			for _=1,90 do
				pcall(Life.tintHouses,hub,HubDress.copiesOf,Layout,HubMap.Origin,HubMap.Scale or 1)
				task.wait(2)
			end
		end)
		local folder=Instance.new("Folder");folder.Name="KonohaLife";folder.Parent=workspace
		local made=Life.build(folder,Life.plan(Layout,HubMap.Origin,HubMap.Scale or 1,zones))
		local acc=0
		RunService.Heartbeat:Connect(function(dt)
			acc+=dt
			if acc<1/30 then return end   -- 30 steps a second is plenty for birds and flags
			acc=0
			local cam=workspace.CurrentCamera
			Life.step(made,Life.clock(),cam and cam.CFrame.Position)
		end)
	end)
end

return Life
