-- Ninja Embodiment (DEC-027, EMB-004): the arena answers what happens in it.
--
-- One shared rule for every contact with the world: a body thrown into a tree,
-- a spike into the floor, a fireball on a boulder, a blade into a trunk, a heavy
-- strike that met a wall instead of a body, a burning zone on the grass. Each is
-- an `impact` with a position, a surface, an energy and a contact kind (blunt,
-- slash, pierce, blast, energy) plus an optional element. The surface's
-- material class decides the answer (a crater in earth, a crack in stone, a cut
-- or a hole in wood, a scorch under fire), wears the part's integrity, and a
-- breakable part that runs out of it breaks (a tree falls, a boulder shatters).
--
-- Nothing here names a fighter or a technique: a new technique gets world
-- reactions by declaring its contact kind / element (spec.world, p.world), or
-- by default from its strike kind or projectile kind.
--
-- Authority and budget: the server owns every scar and break; scars are plain
-- anchored non-colliding parts in the match folder (they replicate on their
-- own and survive round resets: the arena keeps the fight's memory for the
-- whole match), bounded by Config.World.MaxScars (oldest first out), merged
-- into a nearby scar of the same kind instead of stacking, and the rubble of
-- breaks is bounded by Config.World.MaxRubble. A new match builds a new arena.
local Config=require(game:GetService("ReplicatedStorage").NinjaDuel.Config)

local WorldReaction={}

local TUNE=Config.World

-- Material classes (Enum.Material name -> class). A part may override with the
-- WorldMaterial attribute.
WorldReaction.Materials={
	Grass="earth",LeafyGrass="earth",Ground="earth",Mud="earth",Sand="earth",Snow="earth",
	Wood="wood",WoodPlanks="wood",
	Slate="stone",Rock="stone",Basalt="stone",Granite="stone",Concrete="stone",Brick="stone",Cobblestone="stone",
	Pavement="stone",Limestone="stone",Sandstone="stone",Marble="stone",CrackedLava="stone",
	Ice="brittle",Glass="brittle",Neon="brittle",
	Metal="metal",DiamondPlate="metal",CorrodedMetal="metal",
}
-- Per class: base integrity (a 2.6-stud-thick part; scaled by its thickness),
-- the scar colors, and how the class takes each contact kind:
--   wear: integrity lost per unit of energy; scar: the mark it leaves.
WorldReaction.Classes={
	earth={integrity=math.huge,dark=Color3.fromRGB(88,70,52),burn=Color3.fromRGB(34,30,26),
		blunt={wear=0,scar="crater"},slash={wear=0,scar="furrow"},pierce={wear=0,scar="puncture"},
		blast={wear=0,scar="crater"},energy={wear=0,scar="trench"}},
	wood={integrity=120,dark=Color3.fromRGB(62,44,30),burn=Color3.fromRGB(26,22,20),
		blunt={wear=.8,scar="crack"},slash={wear=1,scar="cut"},pierce={wear=.25,scar="puncture"},
		blast={wear=1.1,scar="splinter"},energy={wear=1.4,scar="hole"}},
	stone={integrity=200,dark=Color3.fromRGB(84,80,74),burn=Color3.fromRGB(40,38,36),
		blunt={wear=.7,scar="crack"},slash={wear=.35,scar="scratch"},pierce={wear=.08,scar="chip"},
		blast={wear=.8,scar="crater"},energy={wear=1,scar="gouge"}},
	brittle={integrity=30,dark=Color3.fromRGB(180,200,210),burn=Color3.fromRGB(60,60,60),
		blunt={wear=1.4,scar="crack"},slash={wear=1,scar="crack"},pierce={wear=1,scar="crack"},
		blast={wear=1.6,scar="crack"},energy={wear=1.6,scar="crack"}},
	metal={integrity=math.huge,dark=Color3.fromRGB(70,70,74),burn=Color3.fromRGB(30,30,32),
		blunt={wear=0,scar="dent"},slash={wear=0,scar="scratch"},pierce={wear=0,scar=nil},
		blast={wear=0,scar="dent"},energy={wear=0,scar="gouge"}},
}
-- Elements add their own mark and wear on top of the contact.
--   fire: scorches anything, burns wood faster; lightning: chars and drills;
--   wind: cuts; water: darkens (wet) and puts out nothing here (no fire state).
WorldReaction.Elements={
	fire={scar="scorch",wear={wood=1.6,earth=0,stone=.4,brittle=1,metal=0}},
	lightning={scar="char",wear={wood=1.3,earth=0,stone=1.1,brittle=1.5,metal=0}},
	wind={scar="cut",wear={wood=.8,earth=0,stone=.3,brittle=1,metal=0}},
	water={scar="wet",wear={wood=0,earth=0,stone=0,brittle=0,metal=0}},
}
-- Strike kinds (Attacks spec.kind) -> contact kind.
WorldReaction.StrikeKinds={slash="slash",tenketsu="pierce",palm="blunt",kick="blunt",strike="blunt",heavy="blunt",
	launch="blunt",sweep="blunt",spike="blunt"}
-- Projectile kinds -> contact kind and element (a family projectile declares
-- its own with spec.World / p.world).
WorldReaction.Projectiles={
	shuriken={contact="pierce"},kunai={contact="pierce"},marked={contact="pierce"},needle={contact="pierce"},
	senbon={contact="pierce"},tool={contact="pierce"},wire={contact="slash"},bone={contact="pierce"},
	fireball={contact="blast",element="fire"},phoenix={contact="blast",element="fire"},
	wind={contact="slash",element="wind"},gale={contact="slash",element="wind"},kamatari={contact="slash",element="wind"},
	palm={contact="blunt"},sand={contact="blunt"},
}

-- ------------------------------------------------------------------ records
local function state(c)
	local w=c.world
	if not w then
		w={parts=setmetatable({},{__mode="k"}),scars={},rubble={},embeds={},
			stats={impacts=0,scars=0,merged=0,breaks=0,smash=0,embeds=0}}
		c.world=w
	end
	return w
end
WorldReaction.state=state

function WorldReaction.classOf(part)
	local declared=part:GetAttribute("WorldMaterial")
	if declared and WorldReaction.Classes[declared] then return declared end
	local name=part.Material and part.Material.Name or "Plastic"
	return WorldReaction.Materials[name]
end
-- Thickness factor: a thin plank breaks sooner than a trunk, a big boulder later.
local function thickness(part)
	local s=part.Size
	local thin=math.min(s.X,s.Y,s.Z)
	return math.clamp(thin/2.6,.6,2.2)
end
function WorldReaction.record(c,part)
	local w=state(c)
	local rec=w.parts[part]
	if rec then return rec end
	local class=WorldReaction.classOf(part)
	if not class then return nil end
	local base=WorldReaction.Classes[class].integrity
	local max=if base==math.huge then math.huge else base*thickness(part)
	-- A prop may declare its own (a crate goes to one heavy blow).
	local declared=part:GetAttribute("WorldIntegrity")
	if type(declared)=="number" then max=declared end
	rec={class=class,max=max,integrity=max,state="Intact",breakable=part:GetAttribute("WorldBreakable")==true,color=part.Color}
	w.parts[part]=rec
	return rec
end

-- ------------------------------------------------------------------ scars
local function folderOf(c)
	local w=state(c)
	if w.folder and w.folder.Parent then return w.folder end
	local root=c.match and (c.match.folder or (c.match.effects and c.match.effects.Parent))
	if not root then return nil end
	local f=Instance.new("Folder");f.Name="WorldMemory";f.Parent=root
	w.folder=f
	return f
end
-- A deterministic "random" from a position (the same impact draws the same
-- crack on every server; nothing about the world uses math.random).
local function hash(v)
	local x=math.sin(v.X*12.9898+v.Y*78.233+v.Z*37.719)*43758.5453
	return x-math.floor(x)
end
-- An orthonormal frame on the surface: X along the normal.
local function surfaceFrame(position,normal,along)
	local n=if normal.Magnitude>.01 then normal.Unit else Vector3.yAxis
	local t=along and (along-n*along:Dot(n)) or nil
	if not t or t.Magnitude<.05 then
		t=n:Cross(if math.abs(n.Y)<.9 then Vector3.yAxis else Vector3.xAxis)
	end
	t=t.Unit
	return CFrame.fromMatrix(position,n,t)
end
-- Scar shapes: size grows with energy, capped per kind.
local SHAPES={
	crater={round=true,depth=.1,grow=1/22,min=.9,max=4.5},
	trench={round=false,depth=.1,grow=1/16,min=1.2,max=6,width=.9},
	furrow={round=false,depth=.08,grow=1/14,min=1.4,max=5,width=.35},
	puncture={round=true,depth=.08,grow=0,min=.35,max=.5},
	crack={round=false,depth=.06,grow=1/14,min=1,max=4.2,width=.18,cross=true},
	cut={round=false,depth=.06,grow=1/12,min=1.2,max=4.5,width=.14},
	scratch={round=false,depth=.05,grow=1/18,min=.8,max=3,width=.08},
	splinter={round=true,depth=.12,grow=1/26,min=.8,max=2.4},
	hole={round=true,depth=.14,grow=1/30,min=.7,max=2},
	chip={round=true,depth=.06,grow=0,min=.4,max=.6},
	gouge={round=true,depth=.12,grow=1/26,min=.7,max=2.4},
	dent={round=true,depth=.05,grow=1/30,min=.6,max=1.8},
	scorch={round=true,depth=.04,grow=1/14,min=1.4,max=7,burn=true,transparency=.12},
	char={round=true,depth=.04,grow=1/18,min=1,max=4,burn=true,transparency=.08},
	wet={round=true,depth=.03,grow=1/12,min=1.6,max=6,transparency=.45},
}
WorldReaction.Shapes=SHAPES
local function scarSize(kind,energy)
	local s=SHAPES[kind]
	return math.clamp(s.min+energy*s.grow,s.min,s.max)
end
local function evict(list,max)
	while #list>max do
		local old=table.remove(list,1)
		if old.part then old.part:Destroy() end
	end
end
local RELIEF={crater=true,gouge=true,trench=true,crack=true}
local function chunk(parent,cf,size,material,color)
	local c=Instance.new("Part")
	c.Name="Scar chunk";c.Anchored=true;c.CanCollide=false;c.CanQuery=false;c.CanTouch=false;c.CastShadow=true
	c.Size=size;c.CFrame=cf;c.Material=material;c.Color=color
	c.TopSurface=Enum.SurfaceType.Smooth;c.BottomSurface=Enum.SurfaceType.Smooth
	c.Parent=parent
	return c
end
-- The frame of a scar: X along the surface normal, Z along a strip's length.
local function relief(scar,palette)
	local p=scar.part
	for _,ch in p:GetChildren() do if ch.Name=="Scar chunk" then ch:Destroy() end end
	local surf=scar.surface
	local isPart=typeof(surf)=="Instance" and surf:IsA("BasePart")
	local material=if isPart then surf.Material else Enum.Material.Slate
	local color=if isPart then surf.Color:Lerp(palette.dark,.25) else palette.dark:Lerp(Color3.new(.55,.5,.45),.4)
	p.Material=material
	local size=scar.size
	local base=scar.frame*CFrame.new(-SHAPES[scar.kind].depth*.5,0,0)
	local seed=scar.position
	if SHAPES[scar.kind].round then
		-- The lip: chunks round the rim, tilted outward, half sunk in the floor.
		local n=math.clamp(math.floor(5+size*2.2),6,14)
		local r=size*.5
		for k=1,n do
			local h=hash(seed+Vector3.new(k,k*1.7,k*2.3))
			local a=(k/n)*math.pi*2+h*.4
			local s=size*(.16+h*.12)
			local at=base*CFrame.new(s*.25,math.cos(a)*r*(.9+h*.2),math.sin(a)*r*(.9+h*.2))
			-- tilt about the rim's tangent so the face lifts away from the centre
			local cf=at*CFrame.Angles(a,0,0)*CFrame.Angles(0,0,math.rad(20+h*30))
			chunk(p,cf,Vector3.new(s*.7,s*1.1,s*.9),material,color)
		end
	else
		-- A crack / trench: slabs on both sides of the line, pushed up and out.
		local n=math.clamp(math.floor(3+size*1.6),4,10)
		local width=(SHAPES[scar.kind].width or .3)
		for k=1,n do
			local h=hash(seed+Vector3.new(k*3,k,k*.5))
			local z=(k/(n+1)-.5)*size
			local sideSign=if k%2==0 then 1 else -1
			local s=math.max(.35,width*2.2+size*.06)*(.8+h*.5)
			local at=base*CFrame.new(s*.18,sideSign*(width*.9+s*.35),z)
			local cf=at*CFrame.Angles(0,0,0)*CFrame.Angles(sideSign*math.rad(14+h*22),0,0)
			chunk(p,cf,Vector3.new(s*.45,s*1.2,s*(.9+h*.6)),material,color)
		end
	end
end
local function draw(scar,class)
	local s=SHAPES[scar.kind]
	local p=scar.part
	local palette=WorldReaction.Classes[class] or WorldReaction.Classes.stone
	if s.round then
		p.Shape=Enum.PartType.Cylinder
		p.Size=Vector3.new(s.depth,scar.size,scar.size)
		p.CFrame=scar.frame
	else
		p.Shape=Enum.PartType.Block
		p.Size=Vector3.new(s.depth,s.width or .2,scar.size)
		p.CFrame=scar.frame
	end
	p.Color=if scar.kind=="wet" then Color3.fromRGB(40,52,64) elseif s.burn then palette.burn else palette.dark
	p.Transparency=s.transparency or 0
	-- (User 28/10: "it does not crack the ground, it prints something on it".)
	-- A crater, a gouge, a trench or a crack is drawn in RELIEF: the floor's own
	-- material is broken and lifted - a lip of tilted chunks round a crater, the
	-- slabs on both sides of a crack pushed up and apart - over the dark recess.
	if RELIEF[scar.kind] then relief(scar,palette) end
end
-- Leave (or deepen) a scar. Returns the scar entry.
function WorldReaction.scar(c,kind,surface,position,normal,energy,along,class)
	if not SHAPES[kind] then return nil end
	local w=state(c)
	-- The same mark close to an old one deepens it instead of stacking parts.
	for k=#w.scars,1,-1 do
		local old=w.scars[k]
		if old.kind==kind and old.surface==surface and (old.position-position).Magnitude<math.max(.8,old.size*.45) then
			old.size=math.min(SHAPES[kind].max,old.size+math.max(.15,scarSize(kind,energy)*.25))
			old.marks+=1
			if old.part then draw(old,old.class) end
			w.stats.merged+=1
			-- Most recent stays last: it is the freshest memory.
			table.remove(w.scars,k);table.insert(w.scars,old)
			return old
		end
	end
	local folder=folderOf(c)
	-- Clear of the surface: a flush mark z-fought into a dark ring outline.
	local lift=SHAPES[kind].depth*.5+.06
	local frame=surfaceFrame(position+normal*lift,normal,along)
	if not SHAPES[kind].round and not along then
		-- An unaimed crack runs in a direction drawn from where it is.
		frame=frame*CFrame.Angles(math.pi*2*hash(position),0,0)
	end
	local entry={kind=kind,surface=surface,position=position,normal=normal,size=scarSize(kind,energy),frame=frame,class=class,marks=1,at=c.now}
	if folder then
		local p=Instance.new("Part")
		p.Name="Scar "..kind;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
		p.Material=Enum.Material.SmoothPlastic
		p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
		entry.part=p
		draw(entry,class)
		p:SetAttribute("WorldScar",kind)
		p.Parent=folder
		if SHAPES[kind].cross then
			-- A crack branches once (a second thin line, same part budget: it
			-- is drawn as a child of the first and leaves with it).
			local branch=Instance.new("Part")
			branch.Name="Scar branch";branch.Anchored=true;branch.CanCollide=false;branch.CanQuery=false;branch.CanTouch=false;branch.CastShadow=false
			branch.Size=Vector3.new(p.Size.X,p.Size.Y,p.Size.Z*.55);branch.Color=p.Color;branch.Material=p.Material
			branch.CFrame=frame*CFrame.Angles(.5+hash(position+Vector3.one)*.6,0,0)*CFrame.new(0,0,p.Size.Z*.22)
			branch.Parent=p
		end
	end
	table.insert(w.scars,entry)
	w.stats.scars+=1
	evict(w.scars,TUNE.MaxScars)
	return entry
end

-- ------------------------------------------------------------------ breaks
local function rubble(c,at,size,color,material,direction)
	local w=state(c)
	local folder=folderOf(c)
	if not folder then return end
	for k=1,TUNE.RubblePerBreak do
		local h=hash(at+Vector3.new(k,k*2,k*3))
		local a=(k/TUNE.RubblePerBreak+h*.3)*math.pi*2
		local r=size*(.5+h*.7)
		local push=direction*size*.6
		local s=size*(.22+h*.18)
		local p=Instance.new("Part")
		p.Name="Rubble";p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
		p.Size=Vector3.new(s,s*.7,s*.9);p.Color=color;p.Material=material
		p.CFrame=CFrame.new(Vector3.new(at.X+math.cos(a)*r+push.X,at.Y+s*.3,at.Z+math.sin(a)*r+push.Z))*CFrame.Angles(h*3,a,h*2)
		p.Parent=folder
		table.insert(w.rubble,{part=p})
	end
	evict(w.rubble,TUNE.MaxRubble)
end
-- A tall part (a trunk) falls away from the blow; a squat one (a boulder)
-- shatters into a low mound. Either way what is left is low: it no longer
-- hides a body, stops a blade at head height or takes a wall splat.
function WorldReaction.breakPart(c,part,rec,at,direction)
	local w=state(c)
	rec.state="Broken";rec.integrity=0
	part:SetAttribute("WorldState","Broken");part:SetAttribute("WorldIntegrity",0)
	w.stats.breaks+=1
	-- The marks it carried belonged to the old shape: they go with it (the
	-- rubble and the stump are its memory now).
	for k=#w.scars,1,-1 do
		local scar=w.scars[k]
		if scar.surface==part then
			if scar.part then scar.part:Destroy() end
			table.remove(w.scars,k)
		end
	end
	local flat=Vector3.new(direction.X,0,direction.Z)
	flat=if flat.Magnitude>.05 then flat.Unit else Vector3.xAxis
	local size,cf=part.Size,part.CFrame
	local bottom=cf.Position.Y-size.Y/2
	if size.Y>math.max(size.X,size.Z)*2 then
		local cut=TUNE.StumpHeight
		local base=Vector3.new(cf.Position.X,bottom,cf.Position.Z)
		part.Size=Vector3.new(size.X,cut,size.Z)
		part.CFrame=CFrame.new(base+Vector3.new(0,cut/2,0))*cf.Rotation
		-- The rest of the trunk (and everything it carries) tips over the cut.
		local pivot=CFrame.new(base+Vector3.new(0,cut,0))
		local axis=Vector3.yAxis:Cross(flat).Unit
		local fall=pivot*CFrame.fromAxisAngle(axis,math.rad(84))*pivot:Inverse()
		local log=Instance.new("Part")
		log.Name="Fallen "..part.Name;log.Anchored=true;log.CanCollide=false;log.CanQuery=false;log.CanTouch=false
		log.Size=Vector3.new(size.X,size.Y-cut,size.Z);log.Color=part.Color;log.Material=part.Material
		log.CFrame=fall*CFrame.new(base+Vector3.new(0,cut+(size.Y-cut)/2,0))
		log.Parent=folderOf(c) or part
		for _,child in part:GetChildren() do
			if child:IsA("BasePart") then child.CFrame=fall*child.CFrame;child.CanCollide=false end
		end
		WorldReaction.scar(c,"crater",nil,base+flat*(size.Y*.55),Vector3.yAxis,40,flat,"earth")
	else
		local keep=TUNE.MoundShare
		part.Size=Vector3.new(size.X*.9,size.Y*keep,size.Z*.9)
		part.CFrame=CFrame.new(Vector3.new(cf.Position.X,bottom+size.Y*keep/2,cf.Position.Z))*cf.Rotation
		for _,child in part:GetChildren() do
			if child:IsA("BasePart") then
				child.Size*=.55;child.CanCollide=false
				child.CFrame=CFrame.new(Vector3.new(child.Position.X,bottom+child.Size.Y*.4,child.Position.Z)+flat*size.X*.4)*child.CFrame.Rotation
			end
		end
	end
	part.Color=WorldReaction.Classes[rec.class].dark:Lerp(rec.color,.5)
	rubble(c,Vector3.new(at.X,bottom,at.Z),math.max(1,math.min(size.X,size.Z)*.5),part.Color,part.Material,flat)
	c:pushImpact(at,"worldbreak",true,{normal=-flat,material=rec.class,direction=flat})
end

-- ------------------------------------------------------------------ impacts
-- hit: {part, position, normal, energy, contact, element, direction, source}
-- Returns {class, scar, wear, state, broken} or nil (no material: a body, a
-- prop without a class, or too little energy to mark anything).
function WorldReaction.impact(c,hit)
	local part=hit.part
	if not part or not part.Parent or part:GetAttribute("WorldScar") then return nil end
	local rec=WorldReaction.record(c,part)
	if not rec then return nil end
	local w=state(c)
	local energy=hit.energy or 0
	local contact=hit.contact or "blunt"
	local profile=WorldReaction.Classes[rec.class]
	local answer=profile[contact] or profile.blunt
	local element=hit.element and WorldReaction.Elements[hit.element]
	w.stats.impacts+=1
	if energy<TUNE.MinEnergy then return nil end
	local normal=hit.normal or Vector3.yAxis
	local position=hit.position
	local direction=hit.direction or -normal
	-- The mark of the contact, then the mark of the element.
	local scar=answer.scar
	local entry=nil
	if scar then entry=WorldReaction.scar(c,scar,part,position,normal,energy,if contact=="slash" or contact=="energy" then direction else nil,rec.class) end
	if element and element.scar then WorldReaction.scar(c,element.scar,part,position+normal*.02,normal,energy,nil,rec.class) end
	if contact=="pierce" and (rec.class=="wood" or rec.class=="earth") then
		-- A blade that stays: a world fact (an anchor a technique can read).
		table.insert(w.embeds,{position=position,normal=normal,part=part,owner=hit.source,at=c.now})
		w.stats.embeds+=1
		while #w.embeds>TUNE.MaxEmbeds do table.remove(w.embeds,1) end
	end
	-- Wear.
	local wear=energy*answer.wear
	if element then wear+=energy*(element.wear[rec.class] or 0)*.5 end
	local result={class=rec.class,scar=scar,element=hit.element,wear=wear,state=rec.state,broken=false}
	if rec.state=="Broken" or rec.max==math.huge or wear<=0 then return result end
	rec.integrity=math.max(0,rec.integrity-wear)
	local share=rec.integrity/rec.max
	part:SetAttribute("WorldIntegrity",math.floor(share*100+.5)/100)
	if rec.state=="Intact" and share<=TUNE.CrackedShare then
		rec.state="Cracked";part:SetAttribute("WorldState","Cracked")
		part.Color=rec.color:Lerp(profile.dark,.35)
	end
	if share<=0 then
		if rec.breakable then
			WorldReaction.breakPart(c,part,rec,position,direction)
			result.broken=true
		else
			-- A structural surface (the stadium wall, the floor) never goes:
			-- it keeps a sliver and carries its marks.
			rec.integrity=rec.max*.02
		end
	end
	result.state=rec.state
	return result
end

-- ------------------------------------------------------------------ hooks
-- A body carried into a surface (a wall splat, a knockback into a tree).
-- `velocity` (optional): the body's flight, the way a broken trunk falls.
-- Returns the impact result.
function WorldReaction.body(c,a,hit,speed,velocity)
	if speed<TUNE.BodySpeed then return nil end
	-- A body pressed against the same surface frame after frame hit it once.
	if a.worldHitPart==hit.Instance and c.now-(a.worldHitAt or -1)<TUNE.BodyRepeat then return nil end
	a.worldHitPart=hit.Instance;a.worldHitAt=c.now
	local energy=speed*TUNE.BodyEnergy
	local result=WorldReaction.impact(c,{part=hit.Instance,position=hit.Position,normal=hit.Normal,energy=energy,contact="blunt",
		direction=if velocity and velocity.Magnitude>.1 then velocity.Unit else -hit.Normal,source=a.reactionSource and a.reactionSource.id})
	if result and result.broken then state(c).stats.smash+=1 end
	return result
end
-- A body slammed onto the floor (spike, landed slam).
function WorldReaction.landing(c,a,hit,fall)
	if fall<TUNE.LandingSpeed then return nil end
	if a.worldHitPart==hit.Instance and c.now-(a.worldHitAt or -1)<TUNE.BodyRepeat then return nil end
	a.worldHitPart=hit.Instance;a.worldHitAt=c.now
	return WorldReaction.impact(c,{part=hit.Instance,position=Vector3.new(a.root.Position.X,hit.Position.Y,a.root.Position.Z),normal=hit.Normal,
		energy=fall*TUNE.BodyEnergy,contact="blunt",source=a.reactionSource and a.reactionSource.id})
end
-- A projectile reached a surface.
function WorldReaction.projectile(c,p,hit)
	local declared=p.world or (p.family and p.family.World) or WorldReaction.Projectiles[p.kind]
	local contact=declared and declared.contact or (if (p.radius or 0)>1.2 then "blunt" else "pierce")
	local element=(declared and declared.element) or (if p.infusion and WorldReaction.Elements[p.infusion] then p.infusion else nil)
	local energy=(p.damage or 2)*TUNE.ProjectileEnergy+(p.radius or 0)*6
	return WorldReaction.impact(c,{part=hit.Instance,position=hit.Position,normal=hit.Normal,energy=energy,contact=contact,element=element,
		direction=p.direction,source=p.a and p.a.id})
end
-- A strike whose swing met no body: if the world is in front of it, the world
-- takes it (a heavy blow into a trunk, a lightning thrust into stone).
function WorldReaction.strike(c,a,pending)
	local spec=pending.spec or {}
	local declared=spec.world
	if declared==false then return nil end
	local reach=(spec.contact or 3.6)+(spec.range or 4)*.4
	local look=a.root.CFrame.LookVector
	local from=a.root.Position+Vector3.new(0,.6,0)
	local hit=workspace:Raycast(from,look*reach,c:rayParams(true))
	if not hit or math.abs(hit.Normal.Y)>.6 then return nil end
	local contact=(declared and declared.contact) or WorldReaction.StrikeKinds[spec.kind or ""] or "blunt"
	local heavy=Config.World.HeavyKinds[spec.kind or ""] or spec.reaction=="Knockdown" or spec.reaction=="Launched"
	local energy=(spec.damage or 4)*TUNE.StrikeEnergy*(if heavy then 1.6 else 1)
	return WorldReaction.impact(c,{part=hit.Instance,position=hit.Position,normal=hit.Normal,energy=energy,contact=contact,
		element=(declared and declared.element) or spec.element,direction=look,source=a.id})
end
-- A burning (or otherwise elemental) zone marks the ground under it.
function WorldReaction.zone(c,position,radius,element)
	if not WorldReaction.Elements[element or ""] then return nil end
	local hit=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-8,0),c:rayParams(true))
	if not hit then return nil end
	return WorldReaction.impact(c,{part=hit.Instance,position=hit.Position,normal=hit.Normal,energy=radius*TUNE.ZoneEnergy,contact="blast",element=element})
end
-- What the world still remembers (inspect, audit, perception later).
function WorldReaction.summary(c)
	local w=state(c)
	local cracked,broken=0,0
	for _,rec in w.parts do
		if rec.state=="Cracked" then cracked+=1 elseif rec.state=="Broken" then broken+=1 end
	end
	return {scars=#w.scars,rubble=#w.rubble,embeds=#w.embeds,cracked=cracked,broken=broken,stats=table.clone(w.stats)}
end

return WorldReaction
