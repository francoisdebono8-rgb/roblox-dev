-- A house wall broken through in a street duel (27/11, François: « je veux
-- des dégâts de combat, les maisons se cassent lors des combats en ville »).
-- The server drew the hole (Server/WorldReaction.breach) and sends the
-- contact "housebreak" {position, normal, size, tint, direction}; this is
-- what flies out of it: plaster chunks in the wall's colour, broken boards
-- and laths, a few roof tiles from high on the wall, a burst of dust, the
-- crack of the wall. The pieces are this client's own: they fly out of the
-- wall, fall, bounce once or twice on the ground and lie there, then fade.
-- They never collide with a body (their own small simulation: a ray a frame,
-- no physics part to push a walker), and there are never more than LIMIT.
local RunService=game:GetService("RunService")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")

local House={}
House.LIMIT=60           -- pieces alive at once on this client
House.LIFE=5             -- seconds a piece lies before it fades
House.GRAVITY=110
House.SOUND={crack="rbxassetid://9117969717",boom="rbxasset://sounds/impact_explosion_03.mp3"}
local WOOD=Color3.fromRGB(110,78,52)
local TILE=Color3.fromRGB(64,62,70)
local DARK=Color3.fromRGB(46,36,30)

local live={}
local stepper=nil
-- (pure) The pieces of a breach: their kind, size and launch velocity. The
-- count and the speed grow with the hole; `rng` a Random.
function House.pieces(size,normal,direction,rng,high)
	local list={}
	local count=math.clamp(math.floor(8+size*2.2),10,24)
	local out=Vector3.new(normal.X,0,normal.Z)
	out=if out.Magnitude>.05 then out.Unit else Vector3.zAxis
	local push=Vector3.new(direction.X,0,direction.Z)
	-- the blow's way through: out of the wall's far side reads the same (out)
	push=if push.Magnitude>.05 and push.Unit:Dot(out)>0 then push.Unit else out
	local along=out:Cross(Vector3.yAxis)
	for k=1,count do
		local kind=if k%4==0 then "board" elseif high and k%5==1 then "tile" else "plaster"
		local s=size*(.08+rng:NextNumber()*.1)
		local dims=if kind=="board" then Vector3.new(.22,.14,size*(.22+rng:NextNumber()*.25))
			elseif kind=="tile" then Vector3.new(1.1,.16,.8)
			else Vector3.new(s*1.2,s,s*.9)
		local speed=16+rng:NextNumber()*22+size*2
		local v=(push*(.75+rng:NextNumber()*.5)+along*(rng:NextNumber()-.5)*1.4+Vector3.yAxis*(.25+rng:NextNumber()*.8)).Unit*speed
		table.insert(list,{kind=kind,size=dims,velocity=v,spin=Vector3.new(rng:NextNumber()-.5,rng:NextNumber()-.5,rng:NextNumber()-.5)*14,
			offset=along*(rng:NextNumber()-.5)*size*.6+Vector3.yAxis*(rng:NextNumber()-.5)*size*.5})
	end
	return list
end

local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
local function filter(folder)
	local list={folder}
	local players=game:GetService("Players")
	for _,p in players:GetPlayers() do if p.Character then table.insert(list,p.Character) end end
	local duels=workspace:FindFirstChild("NinjaDuels")
	if duels then
		for _,d in duels:GetDescendants() do if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then table.insert(list,d) end end
	end
	params.FilterDescendantsInstances=list
end

local function step(dt)
	dt=math.min(dt,1/20)
	local now=os.clock()
	for i=#live,1,-1 do
		local p=live[i]
		if not p.part.Parent then table.remove(live,i);continue end
		if p.resting then
			if now>=p.fadeAt then
				TweenService:Create(p.part,TweenInfo.new(.6),{Transparency=1}):Play()
				Debris:AddItem(p.part,.7)
				table.remove(live,i)
			end
			continue
		end
		p.velocity-=Vector3.new(0,House.GRAVITY*dt,0)
		local from=p.part.Position
		local move=p.velocity*dt
		local hit=workspace:Raycast(from,move+move.Unit*.15,params)
		if hit then
			if hit.Normal.Y>.55 then
				p.bounces+=1
				if p.bounces>=2 or p.velocity.Magnitude<10 then
					-- lying on the ground: flat on it, at an odd angle
					local yaw=math.atan2(p.velocity.X,p.velocity.Z)
					p.part.CFrame=CFrame.new(hit.Position+Vector3.new(0,p.part.Size.Y*.5,0))*CFrame.Angles(0,yaw,0)*CFrame.Angles(0,0,(p.tilt or 0))
					p.resting=true;p.fadeAt=now+House.LIFE
					continue
				end
				p.velocity=Vector3.new(p.velocity.X*.45,-p.velocity.Y*.32,p.velocity.Z*.45)
			else
				-- a wall: it falls down along it
				p.velocity=p.velocity-hit.Normal*p.velocity:Dot(hit.Normal)*1.3
				p.velocity*=.5
			end
			p.part.CFrame=CFrame.new(hit.Position+hit.Normal*.15)*p.part.CFrame.Rotation
		else
			p.part.CFrame=CFrame.new(from+move)*p.part.CFrame.Rotation*CFrame.Angles(p.spin.X*dt,p.spin.Y*dt,p.spin.Z*dt)
		end
		if now-p.born>8 then p.part:Destroy();table.remove(live,i) end
	end
	if #live==0 and stepper then stepper:Disconnect();stepper=nil end
end

local function dust(folder,at,normal,size,color)
	local a=Instance.new("Attachment")
	local anchor=Instance.new("Part");anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
	anchor.Transparency=1;anchor.Size=Vector3.new(.2,.2,.2);anchor.CFrame=CFrame.lookAt(at,at+normal);anchor.Parent=folder
	a.Parent=anchor
	local e=Instance.new("ParticleEmitter")
	e.Texture="rbxasset://textures/particles/smoke_main.dds"
	e.Color=ColorSequence.new(color:Lerp(Color3.new(1,1,1),.35),color:Lerp(Color3.fromRGB(120,110,100),.5))
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.5),NumberSequenceKeypoint.new(1,size*1.6)})
	e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)})
	e.Lifetime=NumberRange.new(1.1,2)
	e.Speed=NumberRange.new(6,16)
	e.SpreadAngle=Vector2.new(55,55)
	e.Acceleration=Vector3.new(0,-3,0)
	e.Drag=3
	e.Rate=0
	e.EmissionDirection=Enum.NormalId.Front
	e.Parent=a
	e:Emit(math.clamp(math.floor(10+size*3),12,30))
	Debris:AddItem(anchor,2.5)
end

local function sound(folder,at,id,volume,speed)
	local anchor=Instance.new("Part");anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
	anchor.Transparency=1;anchor.Size=Vector3.new(.2,.2,.2);anchor.Position=at;anchor.Parent=folder
	local s=Instance.new("Sound");s.SoundId=id;s.Volume=volume;s.PlaybackSpeed=speed
	s.RollOffMinDistance=30;s.RollOffMaxDistance=260
	pcall(function() local g=game:GetService("SoundService"):FindFirstChild("NinjaHits");if g then s.SoundGroup=g end end)
	s.Parent=anchor
	pcall(function() s:Play() end)
	Debris:AddItem(anchor,3)
end

-- The burst of one breach (or of a hole made bigger: fewer pieces).
function House.burst(folder,impact)
	local at=impact.position
	if not at or not folder then return 0 end
	local normal=impact.normal or Vector3.zAxis
	local size=impact.size or 4
	local tint=if typeof(impact.tint)=="Color3" then impact.tint else Color3.fromRGB(222,210,190)
	local rng=Random.new(math.floor((at.X*7+at.Y*13+at.Z*17)*10)%2147483647)
	local list=House.pieces(if impact.again then size*.6 else size,normal,impact.direction or -normal,rng,at.Y>8)
	filter(folder)
	for _,spec in list do
		if #live>=House.LIMIT then
			local old=table.remove(live,1)
			if old.part.Parent then old.part:Destroy() end
		end
		local part=Instance.new("Part")
		part.Name="HouseDebris";part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
		part.Size=spec.size
		part.Material=if spec.kind=="board" then Enum.Material.WoodPlanks elseif spec.kind=="tile" then Enum.Material.Slate else Enum.Material.Plaster
		part.Color=if spec.kind=="board" then WOOD elseif spec.kind=="tile" then TILE else tint:Lerp(DARK,rng:NextNumber()*.25)
		part.CFrame=CFrame.new(at+normal*.4+spec.offset)*CFrame.Angles(rng:NextNumber()*6,rng:NextNumber()*6,rng:NextNumber()*6)
		part.Parent=folder
		table.insert(live,{part=part,velocity=spec.velocity,spin=spec.spin,born=os.clock(),bounces=0,tilt=(rng:NextNumber()-.5)*.5})
	end
	if not stepper then stepper=RunService.Heartbeat:Connect(step) end
	dust(folder,at,normal,size,tint)
	sound(folder,at,House.SOUND.crack,1.1,.62+rng:NextNumber()*.1)
	if not impact.again then sound(folder,at,House.SOUND.boom,.55,.9) end
	return #list
end

return House
