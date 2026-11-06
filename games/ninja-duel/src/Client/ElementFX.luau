-- (06/11, user: « c'est faux, la foudre ne va pas dans l'eau ») Water and
-- lightning on screen (Server/Interactions). A soaked body drips while it is
-- wet; the current shows where it runs: jagged arcs crawling over the whole
-- puddle (everyone in it is shocked), arcs over a soaked body that lightning
-- reached. One identity layer installed into Effects ahead of the others (it
-- takes the "conduct" contact). Presentation only.
local ElementFX={}
local K -- Effects' helpers, handed over by install()
ElementFX.clock=os.clock -- (headless tests drive time)
local ARC=Color3.fromRGB(170,214,255)
local CORE=Color3.fromRGB(244,250,255)
local DROP=Color3.fromRGB(150,190,220)
-- One jagged arc from a to b: a few segments, the middle points thrown aside.
local function arc(holder,a,b,rng,width,color)
	local points={a}
	local n=4
	for k=1,n-1 do
		local p=a:Lerp(b,k/n)
		table.insert(points,p+Vector3.new(rng:NextNumber(-.5,.5),rng:NextNumber(-.15,.35),rng:NextNumber(-.5,.5)))
	end
	table.insert(points,b)
	for k=1,#points-1 do
		local p,q=points[k],points[k+1]
		local length=(q-p).Magnitude
		if length>.05 then
			K.block(holder,Vector3.new(width,width,length),CFrame.lookAt((p+q)/2,q),color,Enum.Material.Neon)
		end
	end
end
-- The current: re-drawn every few hundredths of a second for `life` seconds.
local function current(fx,draw,life,anchor)
	local holder=K.new("Model",{Name="Current"},fx.folder)
	local rng=Random.new()
	local born=ElementFX.clock()
	local function redraw()
		holder:ClearAllChildren()
		draw(holder,rng)
	end
	redraw()
	task.spawn(function()
		while holder.Parent and ElementFX.clock()-born<life do
			task.wait(.05)
			if holder.Parent then redraw() end
		end
		if holder.Parent then holder:Destroy() end
	end)
	K.sound(K.anchorPart(fx.folder,anchor),K.SOUND.electric,.6,1)
end
local function conduct(fx,impact,folder)
	local at=impact.position
	if impact.body then
		-- Over the soaked body: arcs between its parts.
		local victim=folder and folder:FindFirstChild(impact.victim or "")
		current(fx,function(holder,rng)
			local parts={}
			if victim then for _,d in victim:GetChildren() do if d:IsA("BasePart") and d.Transparency<1 then table.insert(parts,d) end end end
			for _=1,7 do
				local a=if #parts>0 then parts[rng:NextInteger(1,#parts)].Position else at+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-2,2),rng:NextNumber(-1,1))
				local b=a+Vector3.new(rng:NextNumber(-1.6,1.6),rng:NextNumber(-1.6,1.6),rng:NextNumber(-1.6,1.6))
				arc(holder,a,b,rng,.07,if rng:NextNumber()<.3 then CORE else ARC)
			end
		end,.5,at)
		K.flash(fx.folder,at,ARC,.6,3.4,.14,.3)
		return true
	end
	-- Over the whole puddle, on the floor.
	local radius=impact.radius or 9
	local hit=K.floorUnder and K.floorUnder(fx,at,2,16)
	local floor=(if hit then hit.Position else at-Vector3.new(0,2.9,0))+Vector3.new(0,.18,0)
	current(fx,function(holder,rng)
		for _=1,16 do
			local angle=rng:NextNumber(0,math.pi*2)
			local r=radius*math.sqrt(rng:NextNumber())
			local a=floor+Vector3.new(math.cos(angle)*r,0,math.sin(angle)*r)
			local turn=angle+rng:NextNumber(-1.2,1.2)
			local length=rng:NextNumber(1.5,3.5)
			local b=a+Vector3.new(math.cos(turn)*length,0,math.sin(turn)*length)
			if (Vector3.new(b.X,0,b.Z)-Vector3.new(floor.X,0,floor.Z)).Magnitude>radius then b=a:Lerp(b,.3) end
			arc(holder,a,Vector3.new(b.X,floor.Y,b.Z),rng,.09,if rng:NextNumber()<.25 then CORE else ARC)
		end
	end,.6,floor)
	K.shockRing(fx.folder,floor,ARC,1,radius*2,.3)
	return true
end
-- A soaked body drips.
local drips=setmetatable({},{__mode="k"})
local function fighter(fx,model,actor,dt)
	local wet=actor.wet==true and (actor.health or 1)>0
	local st=drips[model]
	if wet and not st then
		local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
		if not torso then return end
		local at=Instance.new("Attachment");at.Name="Soaked";at.Parent=torso
		local e=Instance.new("ParticleEmitter")
		e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.Rate=26;e.Lifetime=NumberRange.new(.35,.6)
		e.Speed=NumberRange.new(0,1);e.Acceleration=Vector3.new(0,-40,0);e.SpreadAngle=Vector2.new(60,60)
		e.Shape=Enum.ParticleEmitterShape.Box;e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
		e.Color=ColorSequence.new(DROP);e.LightEmission=.3;e.LightInfluence=.6
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.16),NumberSequenceKeypoint.new(1,.08)})
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,.8)})
		e.Parent=at
		drips[model]={attachment=at,emitter=e}
	elseif not wet and st then
		st.emitter.Enabled=false
		game:GetService("Debris"):AddItem(st.attachment,1)
		drips[model]=nil
	end
end
-- (06/11, Studio) Sasuke's lightning down his wire read as a white-hot wire:
-- the current crawls the wire now, jagged arcs from his hand to the bound
-- body for half a second (the contact's own drawing still runs after).
local function alongWire(fx,impact)
	local from,to=impact.from,impact.to
	if not (from and to) or (to-from).Magnitude<1 then return end
	current(fx,function(holder,rng)
		local steps=math.clamp(math.floor((to-from).Magnitude/2.2),3,12)
		for k=0,steps-1 do
			if rng:NextNumber()<.75 then
				local a=from:Lerp(to,k/steps)
				local b=from:Lerp(to,(k+1)/steps)
				arc(holder,a,b,rng,.07,if rng:NextNumber()<.3 then CORE else ARC)
			end
		end
	end,.5,to)
end
local function impact(fx,data,folder)
	if data.style=="conduct" then return conduct(fx,data,folder) end
	if data.style=="chidori" and data.chakra=="conduct" then alongWire(fx,data) end
	return false
end
function ElementFX.install(Effects,kit)
	K=kit
	table.insert(Effects.layers,1,{name="Elements",impact=impact,fighter=fighter})
end
return ElementFX
