-- The ground answering the fight, on the client (06/11, user: « applique-toi
-- plus sur les dégâts au sol… beaucoup d'attaques restent dans le ciel et pas
-- sur le sol… c'est pas encore des vrais blocs de pierre qui se cassent »).
--
-- Two things, presentation only:
--   * the floor breaks for real: when the server leaves a crater, a crack, a
--     trench, a gouge or a skid in the arena (Server/WorldReaction, the parts
--     named "Scar <kind>" in a WorldMemory folder), blocks of that ground are
--     torn out of it: they fly up and out, tumble, bounce once, settle round
--     the scar and crumble away; dust bursts out of the hole; stone cracks.
--   * the big blows reach the ground: a heavy contact, a launcher, a slam, a
--     wall or ground bounce, a Rasengan or a Chidori landing on a body push a
--     ring of dust along the floor under it and kick up grit, whatever the
--     height of the contact (they used to happen in the air only).
-- Installed into Effects as one layer (it never claims a contact: Effects
-- still draws its own).
local Debris=game:GetService("Debris")
local RunService=game:GetService("RunService")
local GroundFX={}
local K -- Effects' helpers, handed over by install()

-- Blocks thrown per scar kind: {count, size, speed}.
GroundFX.BREAK={crater={10,.9,26},gouge={7,.7,20},trench={8,.7,18},crack={6,.6,15},skid={3,.45,9}}
-- Contact styles whose blow reaches the ground (a dust ring under them).
GroundFX.HEAVY={heavy=.8,launcher=.9,slam=1.2,finisher=1,groundbounce=1.2,wall=.6,wallbounce=.8,worldbreak=1.3,
	chidori=1,rasengan=1.1,fire=1,palmburst=.8,clash=.7,awaken=1.1}
local MAX_LIVE=60 -- blocks in flight at once (the oldest settle early)

local live={}
local function floorBelow(position,depth,exclude)
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances=exclude or {}
	return workspace:Raycast(position+Vector3.new(0,1,0),Vector3.new(0,-(depth or 12),0),params)
end
-- What the torn ground is made of: the scar's own chunks say it (relief), else
-- the floor under it.
local function groundOf(scar)
	for _,c in scar:GetChildren() do
		if c:IsA("BasePart") and c.Name=="Scar chunk" and c.Material~=Enum.Material.SmoothPlastic then return c.Material,c.Color end
	end
	local hit=floorBelow(scar.Position,6,{scar})
	if hit and hit.Instance:IsA("BasePart") then
		-- the arena's flat earth breaks into blocks with the grain of earth
		local m=hit.Instance.Material
		if m==Enum.Material.SmoothPlastic or m==Enum.Material.Plastic then m=Enum.Material.Ground end
		return m,hit.Instance.Color
	end
	return Enum.Material.Ground,Color3.fromRGB(150,120,86)
end
local step
local function ensureStep()
	if step then return end
	step=RunService.RenderStepped:Connect(function(dt)
		dt=math.min(dt,1/20)
		local any=false
		for block,b in live do
			any=true
			if not block.Parent then live[block]=nil;continue end
			b.age+=dt
			if not b.rest then
				b.vel+=Vector3.new(0,-95*dt,0)
				local pos=block.Position+b.vel*dt
				if pos.Y-b.half<=b.floor then
					pos=Vector3.new(pos.X,b.floor+b.half,pos.Z)
					if b.bounced or math.abs(b.vel.Y)<8 then
						b.rest=true
					else
						b.bounced=true
						b.vel=Vector3.new(b.vel.X*.45,-b.vel.Y*.32,b.vel.Z*.45)
						b.spin*=.5
					end
				end
				b.rot=b.rot*CFrame.Angles(b.spin.X*dt,b.spin.Y*dt,b.spin.Z*dt)
				block.CFrame=CFrame.new(pos)*b.rot
			end
			if b.age>=b.life then
				live[block]=nil
				K.tween(block,.5,{Transparency=1,Size=block.Size*.6})
				Debris:AddItem(block,.55)
			end
		end
		if not any then step:Disconnect();step=nil end
	end)
end
local function count() local n=0;for _ in live do n+=1 end;return n end
-- Blocks of ground torn out at `at` (the floor point), thrown up and out.
function GroundFX.tear(fx,at,kind,material,color,along)
	local spec=GroundFX.BREAK[kind] or GroundFX.BREAK.crack
	local n,size,speed=spec[1],spec[2],spec[3]
	if count()+n>MAX_LIVE then
		-- the oldest blocks settle now
		for block,b in live do if b.age>.3 then b.age=b.life end end
	end
	local floorY=at.Y
	for k=1,n do
		local a=(k/n)*math.pi*2+math.random()*.6
		local out=Vector3.new(math.cos(a),0,math.sin(a))
		if along then
			-- a crack or a skid throws its blocks to both sides of its line
			local side=along:Cross(Vector3.yAxis)
			out=(side*(if k%2==0 then 1 else -1)+along*(math.random()-.5)*.6).Unit
		end
		local s=size*(.6+math.random()*.8)
		local block=K.block(fx.folder,Vector3.new(s*1.3,s*.7,s),CFrame.new(at+out*s*.8+Vector3.new(0,s*.3,0))*CFrame.Angles(math.random()*6,math.random()*6,math.random()*6),
			color:Lerp(Color3.new(0,0,0),math.random()*.18),material)
		block.Name="GroundBlock";block.CastShadow=true
		live[block]={vel=out*speed*(.45+math.random()*.6)+Vector3.new(0,speed*(.7+math.random()*.6),0),
			spin=Vector3.new(math.random()-.5,math.random()-.5,math.random()-.5)*14,rot=block.CFrame.Rotation,
			floor=floorY,half=s*.35,age=0,life=2.6+math.random()*1.4}
	end
	ensureStep()
	-- the dust of the broken ground
	K.burst(fx.folder,at+Vector3.new(0,.6,0),{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.5,1),Speed=NumberRange.new(6,14),SpreadAngle=Vector2.new(70,70),
		EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(color:Lerp(Color3.fromRGB(230,220,200),.35)),LightInfluence=1,
		Size=K.num({{0,1.4},{1,3.6}}),Transparency=K.num({{0,.25},{1,1}}),Drag=4,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40)},math.floor(n*1.6))
	local anchor=K.anchorPart(fx.folder,at)
	K.sound(anchor,K.SOUND.debris,.5+n*.03,.85+math.random()*.2,1.1)
	if kind=="crater" or kind=="gouge" then K.sound(anchor,K.SOUND.heavy,.45,.6) end
end
-- A blow that reaches the ground: a ring of dust along the floor, grit.
function GroundFX.reach(fx,position,strength)
	local hit=floorBelow(position,9,{fx.folder,fx.fighters})
	if not hit or hit.Normal.Y<.6 then return end
	local at=hit.Position
	local color=if hit.Instance:IsA("BasePart") then hit.Instance.Color else Color3.fromRGB(196,168,120)
	local dust=color:Lerp(Color3.fromRGB(236,226,206),.45)
	K.shockRing(fx.folder,at+Vector3.new(0,.15,0),dust,2,10+strength*8,.35+strength*.1)
	K.burst(fx.folder,at+Vector3.new(0,.3,0),{Texture=K.TEX.smoke,Lifetime=NumberRange.new(.35,.7),Speed=NumberRange.new(8,16*strength),SpreadAngle=Vector2.new(85,10),
		EmissionDirection=Enum.NormalId.Top,Color=ColorSequence.new(dust),LightInfluence=1,Size=K.num({{0,1},{1,2.6}}),
		Transparency=K.num({{0,.35},{1,1}}),Drag=5,Rotation=NumberRange.new(0,360)},math.floor(8+strength*8))
	K.burst(fx.folder,at+Vector3.new(0,.2,0),{Texture=K.TEX.spark,Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(6,12),SpreadAngle=Vector2.new(60,60),
		EmissionDirection=Enum.NormalId.Top,Acceleration=Vector3.new(0,-40,0),Color=ColorSequence.new(color:Lerp(Color3.new(0,0,0),.3)),
		LightEmission=0,LightInfluence=1,Size=K.num({{0,.22},{1,.16}}),Drag=1},math.floor(6+strength*6))
end
local function impact(fx,data,folder)
	local strength=GroundFX.HEAVY[data.style or ""]
	if strength and data.position then
		local ok=pcall(GroundFX.reach,fx,data.position,strength*(if data.heavy then 1.2 else 1))
		if not ok and GroundFX.strict then error("GroundFX.reach") end
	end
	return false
end
-- Watch the server's scars appear.
local watched=setmetatable({},{__mode="k"})
local function watch(fx,memory)
	if watched[memory] then return end
	watched[memory]=true
	memory.ChildAdded:Connect(function(scar)
		if not scar:IsA("BasePart") then return end
		local kind=scar:GetAttribute("WorldScar") or string.match(scar.Name,"^Scar (%a+)")
		if not kind or not GroundFX.BREAK[kind] then return end
		task.defer(function()
			if not scar.Parent then return end
			local material,color=groundOf(scar)
			-- the scar's frame: X is the surface normal, Z runs along a line mark
			local along=if kind=="crater" or kind=="gouge" then nil else scar.CFrame.LookVector*Vector3.new(1,0,1)
			if along and along.Magnitude<.1 then along=nil end
			pcall(GroundFX.tear,fx,scar.Position,kind,material,color,along and along.Unit)
		end)
	end)
end
function GroundFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Ground",impact=impact})
	local function scan(d)
		if d:IsA("Folder") and d.Name=="WorldMemory" then
			-- the effects layer needs an Effects instance: the first one made
			task.spawn(function()
				local fx
				for _=1,600 do fx=FX.current;if fx then break end;task.wait(.1) end
				if fx then watch(fx,d) end
			end)
		end
	end
	for _,d in workspace:GetDescendants() do scan(d) end
	workspace.DescendantAdded:Connect(scan)
end
return GroundFX
