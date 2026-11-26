-- The people of Konoha (22/11, étape 3 ANIMATEUR, DEC-047; François: « les rues ne sont pas
-- animées »). A Part I street is never empty: villagers walk its length and back, stop, look
-- about; a few stand at Ichiraku's counter and at the market's stalls. On this screen only:
-- each is the duel's own rig built here (Server/World.rig's parts and joints, so the
-- ANIMATEUR's clips play on it), dressed in the wardrobe's modelled pieces (Client/OutfitDress
-- templates: tunics, haori, gi, hakama, the hair styles) in plain village colours, walking
-- with the kits' authored walk (Client/AuthoredMotion "<kit>.Walk.F"), standing with their
-- idle. Never solid, never queried: a fight or a walker goes through them. Only the ones near
-- the camera move (the others wait where they are).
local RunService=game:GetService("RunService")

local Folk={}
Folk.WALKERS=26
Folk.NEAR=260           -- studs from the camera within which they move
Folk.SPEED=5.2          -- studs a second (base units x HubMap.Scale)
local C=Color3.fromRGB

-- Plain village colours (no prodigy's colour): cloth, then trim.
Folk.CLOTH={C(92,104,132),C(132,92,70),C(110,124,92),C(170,150,120),C(70,76,96),C(150,72,64),C(196,184,160),C(84,110,120),C(120,96,130)}
Folk.SKIN={C(240,204,170),C(226,184,146),C(204,156,118),C(176,128,96),C(246,214,186)}
Folk.HAIR={C(30,28,32),C(60,44,36),C(96,70,48),C(40,36,44),C(140,120,96),C(176,176,180)}
Folk.TOPS={"Tunic","Haori","Gi","Turtleneck","SashTop","Tunic","ChuninVest"}
Folk.BOTTOMS={"Pants","Hakama","WrapSkirt","Pants","LongShorts"}
Folk.HAIRS={"HairBowl","HairLong","HairBuns","HairHighTail","HairSwept","HairBob","HairHime","HairShort","HairPony",false}
Folk.KITS={"Leaf","Legion","Lion","Copycat","GentleFist","Sand"}

-- A tiny deterministic rng (the same village for everyone, every time).
function Folk.rng(seed)
	local s=seed%2147483647
	if s<=0 then s+=2147483646 end
	return function(a,b)
		s=s*16807%2147483647
		local u=(s-1)/2147483646
		if a==nil then return u end
		if b==nil then return 1+math.floor(u*a) end
		return a+math.floor(u*(b-a+1))
	end
end
local function pick(r,list) return list[r(#list)] end

-- ------------------------------------------------------------------ the rig (World.rig's)
local function part(model,name,size,cf,color)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
	p.Anchored=false;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;p.CastShadow=false
	p.Parent=model
	return p
end
function Folk.rig(skin,cloth,pants)
	local model=Instance.new("Model");model.Name="Villager"
	local cf=CFrame.new()
	local root=part(model,"HumanoidRootPart",Vector3.new(2,2,1),cf,cloth);root.Transparency=1;root.Anchored=true
	local function body(name,size,offset,tint) return part(model,name,size,cf*CFrame.new(offset),tint) end
	local lower=body("LowerTorso",Vector3.new(2,1,1),Vector3.new(0,0,0),cloth)
	local upper=body("UpperTorso",Vector3.new(2,1.4,1),Vector3.new(0,1.15,0),cloth)
	local head=body("Head",Vector3.new(1.5,1.5,1.5),Vector3.new(0,2.45,0),skin)
	local function joint(name,p0,p1,c0,c1)
		local m=Instance.new("Motor6D");m.Name=name;m.Part0=p0;m.Part1=p1;m.C0=CFrame.new(c0);m.C1=CFrame.new(c1);m.Parent=p0
		return m
	end
	joint("Root",root,lower,Vector3.zero,Vector3.zero)
	joint("Waist",lower,upper,Vector3.new(0,.65,0),Vector3.new(0,-.5,0))
	joint("Neck",upper,head,Vector3.new(0,.9,0),Vector3.new(0,-.55,0))
	for _,side in {-1,1} do
		local prefix=if side==-1 then "Left" else "Right"
		local armTop=body(prefix.."UpperArm",Vector3.new(.8,1.1,.8),Vector3.new(side*1.45,.72,0),cloth)
		local armLow=body(prefix.."LowerArm",Vector3.new(.76,.95,.76),Vector3.new(side*1.45,-.28,0),cloth)
		local hand=body(prefix.."Hand",Vector3.new(.72,.5,.72),Vector3.new(side*1.45,-1,0),skin)
		local legTop=body(prefix.."UpperLeg",Vector3.new(.85,1.1,.85),Vector3.new(side*.5,-.85,0),pants)
		local legLow=body(prefix.."LowerLeg",Vector3.new(.8,1.05,.8),Vector3.new(side*.5,-1.75,0),pants)
		local foot=body(prefix.."Foot",Vector3.new(.8,.42,1.15),Vector3.new(side*.5,-2.55,-.15),C(60,50,44))
		joint(prefix.."Shoulder",upper,armTop,Vector3.new(side*1.05,.45,0),Vector3.new(-side*.4,.5,0))
		joint(prefix.."Elbow",armTop,armLow,Vector3.new(0,-.55,0),Vector3.new(0,.45,0))
		joint(prefix.."Wrist",armLow,hand,Vector3.new(0,-.48,0),Vector3.new(0,.25,0))
		joint(prefix.."Hip",lower,legTop,Vector3.new(side*.5,-.55,0),Vector3.new(0,.5,0))
		joint(prefix.."Knee",legTop,legLow,Vector3.new(0,-.55,0),Vector3.new(0,.5,0))
		joint(prefix.."Ankle",legLow,foot,Vector3.new(0,-.5,0),Vector3.new(0,.2,.15))
	end
	local eyes=body("Eyes",Vector3.new(.85,.1,.05),Vector3.new(0,2.6,-.76),C(24,31,38))
	joint("EyeJoint",head,eyes,Vector3.new(0,.15,-.76),Vector3.zero)
	model.PrimaryPart=root
	return model
end

-- Dresses a rig in wardrobe models (OutfitDress templates), each slot in the given colour.
function Folk.dress(model,Dress,list,colors)
	local n=0
	for _,name in list do
		local t=name and Dress.template(name)
		if t then
			for _,entry in t do
				local on=model:FindFirstChild(entry.on)
				if on and on:IsA("BasePart") then
					local size,cf=Dress.place(on,entry.on,entry.part.Size,entry.o,model)
					if size then
						local p=entry.part:Clone()
						p.Size=size;p.CFrame=cf
						p.Anchored=false;p.Massless=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
						p.Color=colors[entry.slot] or colors.Cloth or p.Color
						p.Material=Dress.material(p.Material)
						local w=Instance.new("WeldConstraint");w.Part0=on;w.Part1=p;w.Parent=p
						p.Parent=model
						n+=1
					end
				end
			end
		end
	end
	return n
end

-- ------------------------------------------------------------------ where they go
-- Each walker: a street of the plan (Shared/KonohaLayout), a lane a quarter of its width
-- off its middle, from one end to the other and back. Pure: the headless test reads it.
function Folk.routes(Layout,origin,scale,count,seed)
	local r=Folk.rng(seed or 47)
	local streets={}
	for _,s in Layout.Streets do
		if (s.b-s.a).Magnitude>=40 then table.insert(streets,s) end
	end
	table.sort(streets,function(a,b) return a.id<b.id end)
	local out={}
	for k=1,count do
		local s=streets[(k-1)%#streets+1]
		local dir=(s.b-s.a).Unit
		local across=Vector2.new(-dir.Y,dir.X)*(s.width*.25)*(if r()<.5 then -1 else 1)
		local a,b=s.a+across+dir*4,s.b+across-dir*4
		local t0=r()
		table.insert(out,{
			a=origin+Vector3.new(a.X,0,a.Y)*scale,b=origin+Vector3.new(b.X,0,b.Y)*scale,
			start=t0,street=s.id,kit=Folk.KITS[(k-1)%#Folk.KITS+1],seed=k*7919,
		})
	end
	return out
end
-- (26/11, the CM: « des passants traversent le duel de rue ») A walker whose
-- way crosses a street duel's ring (Server/Hub.duelRings: its Centre, its
-- Radius) stops at its edge and watches the fight: the place on the edge, the
-- way to the centre. `rings` = {{centre, radius}}; nil when he is clear.
Folk.MARGIN=2.5
function Folk.watch(at,rings)
	for _,ring in rings do
		local off=Vector3.new(at.X-ring.centre.X,0,at.Z-ring.centre.Z)
		if off.Magnitude<ring.radius+Folk.MARGIN then
			local out=if off.Magnitude>.1 then off.Unit else Vector3.new(1,0,0)
			local edge=Vector3.new(ring.centre.X,at.Y,ring.centre.Z)+out*(ring.radius+Folk.MARGIN)
			return edge,-out
		end
	end
	return nil
end
-- Where a walker is at time t on his route: position, the way he faces, walking or not.
-- He walks a->b, waits 2.5 s, walks b->a, waits 3 s.
function Folk.at(route,t,speed)
	local len=(route.b-route.a).Magnitude
	local walk=len/speed
	local period=2*walk+5.5
	local u=(t+route.start*period)%period
	if u<walk then return route.a:Lerp(route.b,u/walk),(route.b-route.a).Unit,true end
	u-=walk
	if u<2.5 then return route.b,(route.a-route.b).Unit,false end
	u-=2.5
	if u<walk then return route.b:Lerp(route.a,u/walk),(route.a-route.b).Unit,true end
	return route.a,(route.b-route.a).Unit,false
end

-- ------------------------------------------------------------------ in the game
local MOTOR={Right="RightShoulder",Left="LeftShoulder"}
local function joints(model)
	local j={}
	for _,d in model:GetDescendants() do if d:IsA("Motor6D") then j[d.Name]=d end end
	return j
end
local function pose(j,p)
	if not p then return end
	for name,cf in p do
		local m=j[MOTOR[name] or name]
		if m then m.Transform=cf end
	end
end

function Folk.start()
	if Folk.started then return end
	Folk.started=true
	task.spawn(function()
		local RS=game:GetService("ReplicatedStorage")
		local shared=RS:WaitForChild("NinjaDuel",30)
		if not shared then return end
		local okL,Layout=pcall(require,shared:WaitForChild("KonohaLayout",10))
		local okH,HubMap=pcall(require,shared:WaitForChild("HubMap",10))
		local okC,Config=pcall(require,shared:WaitForChild("Config",10))
		if not (okL and okH and Layout and HubMap) then return end
		if okC and Config and Config.Hub and Config.Hub.Enabled~=true then return end
		local hub=workspace:WaitForChild("NinjaDuelHub",60)
		if not hub then return end
		local okD,Dress=pcall(require,script.Parent.OutfitDress)
		local okA,Authored=pcall(require,script.Parent.AuthoredMotion)
		if not (okD and okA) then return end
		local folder=Instance.new("Folder");folder.Name="KonohaFolk";folder.Parent=workspace
		local O,S=HubMap.Origin,HubMap.Scale or 1
		local routes=Folk.routes(Layout,O,S,Folk.WALKERS)
		local walkers={}
		for _,route in routes do
			local r=Folk.rng(route.seed)
			local cloth,pants=pick(r,Folk.CLOTH),pick(r,Folk.CLOTH)
			local model=Folk.rig(pick(r,Folk.SKIN),cloth,pants)
			model.Parent=folder
			local hair=pick(r,Folk.HAIRS)
			local list={pick(r,Folk.TOPS),pick(r,Folk.BOTTOMS),hair or nil}
			local colors={Cloth=cloth,Trim=pick(r,Folk.CLOTH),Under=pants,Belt=pick(r,Folk.CLOTH),Sash=pick(r,Folk.CLOTH),
				Vest=C(110,150,92),Hair=pick(r,Folk.HAIR),Tie=pick(r,Folk.CLOTH),Wrap=C(226,222,212)}
			task.spawn(function() pcall(Folk.dress,model,Dress,list,colors) end)
			local walk=route.kit..".Walk.F"
			local idle=route.kit..".Idle"
			-- the cycle advances by the ground covered over the planted foot's sweep (about
			-- 0.7 of the clip's stride, Client/VelmoraMotionEngine contactStrideOf): no glide
			local stride,len=7,1
			pcall(function()
				local c=Authored.clip(walk)
				stride=(c and c.meta and c.meta.stride or 7)*.7
				len=Authored.length(walk) or 1
			end)
			table.insert(walkers,{model=model,root=model.PrimaryPart,j=joints(model),route=route,clipT=r()*len,rate=len/math.max(stride,1),
				walk=if Authored.has(walk) then walk else nil,idle=if Authored.has(idle) then idle else nil,phase=r()*3})
		end
		local acc=0
		local rings,ringsAt={},0
		RunService.Heartbeat:Connect(function(dt)
			acc+=dt
			if acc<1/30 then return end
			local step=acc;acc=0
			local t=os.clock()
			local cam=workspace.CurrentCamera
			local eye=cam and cam.CFrame.Position or O
			if t-ringsAt>.5 then
				ringsAt=t;rings={}
				for _,child in hub:GetChildren() do
					local centre,radius=child:GetAttribute("Centre"),child:GetAttribute("Radius")
					if string.sub(child.Name,1,9)=="DuelRing_" and typeof(centre)=="Vector3" and type(radius)=="number" then table.insert(rings,{centre=centre,radius=radius}) end
				end
			end
			for _,w in walkers do
				local at,dir,moving=Folk.at(w.route,t,Folk.SPEED*S)
				if #rings>0 then
					local edge,face=Folk.watch(at,rings)
					if edge then at,dir,moving=edge,face,false end
				end
				if (at-eye).Magnitude<Folk.NEAR or not w.placed then
					w.placed=true
					w.root.CFrame=CFrame.lookAt(at+Vector3.new(0,3,0),at+Vector3.new(0,3,0)+Vector3.new(dir.X,0,dir.Z))
					if moving then w.clipT+=step*Folk.SPEED*S*w.rate end
					local clip=if moving then w.walk else w.idle
					local ct=if moving then w.clipT else t+w.phase
					if clip then pcall(function() pose(w.j,Authored.sample(clip,ct)) end) end
				end
			end
		end)
	end)
end

return Folk
