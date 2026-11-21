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
function Life.plan(Layout,origin,scale)
	local out={steam={},smoke={},bunting={},birds={},leaves={}}
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
	end
	for _,s in Layout.Streets do
		if string.find(s.id,"^Market") or s.id=="MainStreet" then
			local a,b=s.a,s.b
			local len=(b-a).Magnitude
			local dir=(b-a).Unit
			local across=Vector2.new(-dir.Y,dir.X)*(s.width/2+2)
			local count=math.floor(len/34)
			for k=1,count do
				local c=a+dir*(k*len/(count+1))
				local p,q=c+across,c-across
				table.insert(out.bunting,{a=Life.world(origin,scale,p.X,16,p.Y),b=Life.world(origin,scale,q.X,16,q.Y)})
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
		for k=0,12 do
			local t=k/12
			local p=b.a:Lerp(b.b,t)-Vector3.new(0,2*math.sin(t*math.pi)*1.2,0)
			table.insert(pts,p)
		end
		for k=1,#pts-1 do
			local p,q=pts[k],pts[k+1]
			local rope=part(holder,Vector3.new(.08,.08,(q-p).Magnitude),CFrame.lookAt((p+q)/2,q),C(90,70,50),Enum.Material.Fabric,"LifeRope")
			local flag=part(holder,Vector3.new(.04,1.1,.9),CFrame.lookAt((p+q)/2,q)*CFrame.new(0,-.6,0),PAPER[(k+i)%#PAPER+1],Enum.Material.Fabric,"LifeFlag")
			table.insert(flags,{part=flag,base=flag.CFrame,phase=k*.7+i})
		end
		table.insert(made.bunting,flags)
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
function Life.step(made,t)
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
		for _,f in flags do
			f.part.CFrame=f.base*CFrame.Angles(math.sin(t*1.6+f.phase)*.25,0,0)
		end
	end
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
		if not workspace:WaitForChild("NinjaDuelHub",60) then return end
		local folder=Instance.new("Folder");folder.Name="KonohaLife";folder.Parent=workspace
		local made=Life.build(folder,Life.plan(Layout,HubMap.Origin,HubMap.Scale or 1))
		local acc=0
		RunService.Heartbeat:Connect(function(dt)
			acc+=dt
			if acc<1/30 then return end   -- 30 steps a second is plenty for birds and flags
			acc=0
			Life.step(made,Life.clock())
		end)
	end)
end

return Life
