-- The three transformations at the top of the kit trees (21/11, étape 2 ANIMATEUR 4, DEC-045:
-- « en haut, un nœud de transformation par kit, qui change une technique à vue d'œil »):
--
--   SASUKE  Wall Chidori (SkillTrees WallChidori, Transform = true; Server/Combat: the Chidori
--           cast from a wall run charges 0.3 s on the wall, then dives). On the wall the
--           lightning bites the wall: a burnt line drawn under his hand while it charges,
--           sparks thrown off the surface, then the dive (Lion.ChidoriDive, as before).
--   NARUTO  the Rasengan thrown: a projectile of kind "rasengan" (a clone - or he - throws the
--           sphere instead of carrying it in). It flies spinning, wisps of wind wrapped round it,
--           a blue wake. The throw: clip Legion.RasenganThrow.
--   LEE     the Lotus into the Dynamic Entry: attackVariant "LotusEntry". From the Lotus
--           crater he springs back and comes in feet first: green afterimages along the leap,
--           a ring where he takes off. Clip Leaf.LotusEntry.
--
-- The Wall Chidori reads what the server already sends (castId "Chidori", the fighter's `wall`);
-- the other two wait for their nodes and mechanics (the DEV's): the names above are the contract.
-- Presentation only.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local AwakenFX=require(script.Parent.AwakenFX)
local emit=AwakenFX.emitter

local Transform={}
Transform.clock=os.clock
local C=Color3.fromRGB
local BOLT=C(170,205,255)
local BOLT_CORE=C(240,248,255)
local BURN=C(30,26,30)
local BLUE=C(70,140,255)
local DEEP=C(30,70,170)
local CORE=C(235,246,255)
local LEAF=C(120,220,110)

local function seq(points)
	local keys={}
	for _,p in points do table.insert(keys,NumberSequenceKeypoint.new(p[1],p[2],p[3] or 0)) end
	return NumberSequence.new(keys)
end
local function range(a,b) return NumberRange.new(a,b or a) end
local function cols(a,b) return ColorSequence.new(a,b or a) end
local function part(parent,size,cf,color,material,class)
	local p=Instance.new(class or "Part")
	p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Neon
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Parent=parent
	return p
end
local function fade(x,time,goal)
	pcall(function() TweenService:Create(x,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play() end)
	pcall(function() Debris:AddItem(x,time+.05) end)
end
local function weld(root,p)
	p.Anchored=false;p.Massless=true
	local w=Instance.new("WeldConstraint");w.Part0=root;w.Part1=p;w.Parent=p
end

-- ------------------------------------------------------------------ Sasuke: the Wall Chidori
-- The nearest wall beside a body (the four horizontal directions, 4 studs), or nil.
function Transform.wallNear(fx,root)
	local best
	pcall(function()
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={fx.folder,fx.fighters}
		for _,d in {root.CFrame.RightVector,-root.CFrame.RightVector,root.CFrame.LookVector,-root.CFrame.LookVector} do
			local hit=workspace:Raycast(root.Position,d*4,params)
			if hit and math.abs(hit.Normal.Y)<.5 and (not best or hit.Distance<best.Distance) then best=hit end
		end
	end)
	return best
end
-- One stroke of the burn under the hand: a dark scar on the wall, sparks off it.
function Transform.scorch(folder,position,normal,from)
	local along=if from and (position-from).Magnitude>.05 then (position-from) else Vector3.yAxis*.3
	local len=math.max(.3,along.Magnitude)
	local mid=if from then (position+from)/2 else position
	local up=normal:Cross(along.Unit)
	local cf=CFrame.fromMatrix(mid+normal*.03,along.Unit,up.Magnitude>.01 and up.Unit or Vector3.yAxis)
	local scar=part(folder,Vector3.new(len,.22,.04),cf,BURN,Enum.Material.Slate)
	scar.Name="WallChidoriBurn"
	local glow=part(folder,Vector3.new(len,.08,.05),cf*CFrame.new(0,0,.01),BOLT_CORE)
	glow.Name="WallChidoriBurn";glow.Transparency=.1
	fade(glow,.35,{Transparency=1})
	if task and task.delay then task.delay(1.6,function() if scar.Parent then fade(scar,.6,{Transparency=1}) end end) end
	local holder=part(folder,Vector3.new(.1,.1,.1),CFrame.new(position),BOLT);holder.Transparency=1;holder.Name="WallChidoriSparks"
	local at=Instance.new("Attachment");at.Parent=holder
	local e=emit(at,"spark",{Name="WallChidoriSparks",Lifetime=range(.08,.2),Speed=range(6,14),SpreadAngle=Vector2.new(60,60),
		Color=cols(BOLT_CORE,BOLT),LightEmission=1,Size=seq({{0,.35},{1,0}})})
	e.Enabled=false;pcall(function() e:Emit(5) end)
	pcall(function() Debris:AddItem(holder,.5) end)
	return scar
end
local function wallChidori(fx,model,actor,st)
	local on=actor.castId=="Chidori" and actor.wall and (actor.state=="TechniqueChannel" or actor.state=="TechniqueActive")
	if not on then st.wallBurn=nil;return end
	local now=Transform.clock()
	if st.wallBurn and now-st.wallBurn.at<1/30 then return end
	local root=model:FindFirstChild("HumanoidRootPart")
	local hand=model:FindFirstChild("RightHand")
	if not (root and hand) then return end
	local hit=Transform.wallNear(fx,root)
	if not hit then return end
	-- the hand's point on the wall
	local p=hand.Position
	local onWall=p-hit.Normal*((p-hit.Position):Dot(hit.Normal))
	Transform.scorch(fx.folder,onWall,hit.Normal,st.wallBurn and st.wallBurn.last)
	st.wallBurn={at=now,last=onWall}
end

-- ------------------------------------------------------------------ Naruto: the thrown Rasengan
function Transform.buildRasengan(scale)
	scale=scale or 1
	local m=Instance.new("Model");m.Name="ThrownRasengan"
	local root=part(m,Vector3.one*.4*scale,CFrame.new(),CORE);root.Shape=Enum.PartType.Ball;root.Name="Root"
	local shell=part(m,Vector3.one*1.3*scale,CFrame.new(),DEEP,Enum.Material.Glass);shell.Shape=Enum.PartType.Ball;shell.Transparency=.35;shell.Name="Shell"
	local churn=part(m,Vector3.one*1.75*scale,CFrame.new(),BLUE,Enum.Material.ForceField);churn.Shape=Enum.PartType.Ball;churn.Name="Churn"
	weld(root,shell)
	-- the churn turns on its own (placed each frame), the wind bands round it
	for k=0,1 do
		local band=part(m,Vector3.new(.08,2.1*scale,2.1*scale),CFrame.Angles(k*math.pi/2,0,math.pi/2),C(200,230,255));band.Shape=Enum.PartType.Cylinder
		band.Transparency=.55;band.Name="WindBand"
	end
	local a0=Instance.new("Attachment");a0.Name="WakeTop";a0.Position=Vector3.new(0,.55*scale,0);a0.Parent=root
	local a1=Instance.new("Attachment");a1.Name="WakeBottom";a1.Position=Vector3.new(0,-.55*scale,0);a1.Parent=root
	local wake=Instance.new("Trail");wake.Name="RasenganWake";wake.Attachment0=a0;wake.Attachment1=a1;wake.Lifetime=.25
	wake.Color=cols(C(190,225,255),BLUE);wake.LightEmission=.8;wake.LightInfluence=0;wake.FaceCamera=true
	wake.Transparency=seq({{0,.2},{1,1}});wake.WidthScale=seq({{0,1},{1,.3}});wake.Parent=root
	local light=Instance.new("PointLight");light.Color=BLUE;light.Brightness=2.5;light.Range=10;light.Shadows=false;light.Parent=root
	m.PrimaryPart=root
	local decor={model=m,t=0}
	function decor.step(dt)
		decor.t+=dt
		local cf=root.CFrame
		churn.CFrame=cf*CFrame.Angles(decor.t*7,decor.t*11,0)
		churn.Size=Vector3.one*1.75*scale*(1+math.sin(decor.t*40)*.05)
		local i=0
		for _,b in m:GetChildren() do
			if b.Name=="WindBand" then
				b.CFrame=cf*CFrame.Angles(decor.t*18+i*math.pi/2,decor.t*5,math.pi/2)
				i+=1
			end
		end
	end
	return m,decor
end

-- ------------------------------------------------------------------ Lee: the Lotus into the Entry
local function lotusEntry(fx,model,actor,st)
	local on=actor.attackVariant=="LotusEntry" and (actor.state=="Startup" or actor.state=="Active")
	local root=model:FindFirstChild("HumanoidRootPart")
	if not on or not root then st.entry=nil;return end
	local now=Transform.clock()
	if not st.entry then
		st.entry={at=now,ghost=0}
		-- the take-off: a green ring kicked off the floor
		local ring=part(fx.folder,Vector3.new(.1,2,2),CFrame.new(root.Position-Vector3.new(0,2.6,0))*CFrame.Angles(0,0,math.pi/2),LEAF)
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.3;ring.Name="LotusEntryRing"
		fade(ring,.35,{Size=Vector3.new(.04,11,11),Transparency=1})
	end
	if now-st.entry.ghost>.05 and fx.ghost then
		st.entry.ghost=now
		pcall(fx.ghost,fx,model,LEAF,.22,.6)
	end
end

-- ------------------------------------------------------------------ in the duel
function Transform.install(FX,kit)
	if kit and kit.BUILD and not kit.BUILD.rasengan then
		kit.BUILD.rasengan=function()
			local m,decor=Transform.buildRasengan(1)
			m:SetAttribute("TransformRasengan",true)
			Transform.decor=Transform.decor or setmetatable({},{__mode="k"})
			Transform.decor[m]=decor
			return m
		end
	end
	local layer={name="Transform"}
	layer.frame=function(self)
		for _,entry in self.projectiles or {} do
			local d=Transform.decor and entry.model and Transform.decor[entry.model]
			if d then pcall(d.step,1/60) end
		end
	end
	layer.fighter=function(self,model,actor)
		if not model then return end
		self.transformState=self.transformState or setmetatable({},{__mode="k"})
		local st=self.transformState[model]
		if not st then st={};self.transformState[model]=st end
		if actor.fighterId=="Lion" then wallChidori(self,model,actor,st) end
		if actor.fighterId=="Leaf" then lotusEntry(self,model,actor,st) end
	end
	table.insert(FX.layers,layer)
	return layer
end

return Transform
