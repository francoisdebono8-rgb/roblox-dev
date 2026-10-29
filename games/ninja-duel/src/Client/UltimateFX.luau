-- The ultimates on the client (stage 6, the approved move list, "Ultimes"):
-- Server/Ultimates pushes the contacts, this layer draws them. One identity
-- layer installed into Effects (like LeeFX): Effects offers the registry and
-- its helpers; the lens is Camera:cinema (the same "ultimate" contact).
--   ultimateStart  the press: a flash of the fighter's colour, his ultimate's name
--   ultimate       caught: letterbox, the name, the sequence drawn for its time
--   ultimateTick   each blow of the sequence
--   ultimateEnd    the last blow
--   ultimateMiss   the opener whiffed (the opening is the opponent's)
-- and three awakening moments: Itachi's Tsukuyomi (the world turns red and
-- black for the held body), a gate of Lee's opening, the Byakugan's reveal.
-- Presentation only: nothing here can change gameplay.
local Debris=game:GetService("Debris")

local UltimateFX={}
local K -- Effects' helpers, handed over by install()
UltimateFX.clock=os.clock -- (headless tests drive time)

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
-- Per sequence: the core colour, its edge, the world's grade while it plays.
UltimateFX.LOOK={
	clones={core=rgb(255,150,40),edge=rgb(255,226,170),grade={tint=rgb(255,236,214),saturation=.15,contrast=.12}},
	lion={core=rgb(150,200,255),edge=rgb(236,246,255),grade={tint=rgb(214,226,255),saturation=-.2,contrast=.25}},
	pyramid={core=rgb(214,176,112),edge=rgb(150,112,70),grade={tint=rgb(255,232,196),saturation=-.1,contrast=.15}},
	lotus={core=rgb(120,230,140),edge=rgb(226,255,226),grade={tint=rgb(226,255,226),saturation=.1,contrast=.15}},
	palms={core=rgb(190,200,255),edge=rgb(250,250,255),grade={tint=rgb(226,230,255),saturation=-.35,contrast=.2}},
	tsukuyomi={core=rgb(200,20,30),edge=rgb(20,10,12),grade={tint=rgb(255,90,90),saturation=-1,contrast=.45}},
	flash={core=rgb(255,220,80),edge=rgb(255,250,220),grade={tint=rgb(255,246,214),saturation=0,contrast=.2}},
	raikiri={core=rgb(220,236,255),edge=rgb(120,170,255),grade={tint=rgb(220,230,255),saturation=-.3,contrast=.3}},
}
local function lookOf(kind) return UltimateFX.LOOK[kind or ""] or UltimateFX.LOOK.clones end

-- The screen side (letterbox and title) lives in the local player's GUI; a
-- headless scene has none and simply skips it.
local function playerGui()
	local ok,gui=pcall(function()
		local player=game:GetService("Players").LocalPlayer
		return player and player:FindFirstChildOfClass("PlayerGui")
	end)
	return ok and gui or nil
end
function UltimateFX.banner(fx,name,color,time,subtitle)
	local gui=playerGui()
	if not gui then return nil end
	local old=gui:FindFirstChild("NinjaUltimate")
	if old then old:Destroy() end
	local screen=K.new("ScreenGui",{Name="NinjaUltimate",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=40},gui)
	local top=K.new("Frame",{BackgroundColor3=Color3.new(),BorderSizePixel=0,Size=UDim2.new(1,0,0,0),Position=UDim2.fromScale(0,0)},screen)
	local bottom=K.new("Frame",{BackgroundColor3=Color3.new(),BorderSizePixel=0,Size=UDim2.new(1,0,0,0),AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1)},screen)
	K.tween(top,.22,{Size=UDim2.new(1,0,.11,0)});K.tween(bottom,.22,{Size=UDim2.new(1,0,.11,0)})
	local title=K.new("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,64),AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-18),
		Font=Enum.Font.GothamBlack,Text=name or "",TextColor3=color,TextSize=46,TextTransparency=1,TextStrokeTransparency=.2,TextStrokeColor3=Color3.new()},screen)
	K.tween(title,.2,{TextTransparency=0})
	local sub=nil
	if subtitle then
		sub=K.new("TextLabel",{Name="Count",BackgroundTransparency=1,Size=UDim2.new(1,0,0,30),AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,22),
			Font=Enum.Font.GothamBold,Text=subtitle,TextColor3=Color3.new(1,1,1),TextSize=26,TextStrokeTransparency=.3},screen)
	end
	fx.ultimateScreen={screen=screen,top=top,bottom=bottom,title=title,sub=sub,ends=UltimateFX.clock()+(time or 3.4)}
	task.delay(time or 3.4,function() UltimateFX.closeBanner(fx,screen) end)
	return screen
end
function UltimateFX.closeBanner(fx,screen)
	local open=fx.ultimateScreen
	if not open or (screen and open.screen~=screen) then return end
	fx.ultimateScreen=nil
	if open.screen.Parent then
		K.tween(open.top,.2,{Size=UDim2.new(1,0,0,0)});K.tween(open.bottom,.2,{Size=UDim2.new(1,0,0,0)})
		K.tween(open.title,.2,{TextTransparency=1})
		Debris:AddItem(open.screen,.3)
	end
end
-- The world's grade for the sequence (one at a time).
function UltimateFX.grade(fx,look,time)
	if fx.ultimateGrade and fx.ultimateGrade.Parent then fx.ultimateGrade:Destroy() end
	local ok,cc=pcall(function()
		local Lighting=game:GetService("Lighting") -- (asked late: a headless scene has none)
		return K.new("ColorCorrectionEffect",{Name="NinjaUltimateGrade",TintColor=look.grade.tint,Saturation=look.grade.saturation,Contrast=look.grade.contrast,Brightness=0},Lighting)
	end)
	if not ok or not cc then return end
	fx.ultimateGrade=cc
	task.delay(time,function()
		if cc.Parent then K.tween(cc,.3,{TintColor=Color3.new(1,1,1),Saturation=0,Contrast=0});Debris:AddItem(cc,.35) end
	end)
end

local function modelFor(folder,id) return folder and folder:FindFirstChild(id or "") end
local function rootOf(model) return model and model:FindFirstChild("HumanoidRootPart") end
local function around(position,radius,rng)
	local a=rng:NextNumber()*math.pi*2
	return position+Vector3.new(math.cos(a)*radius,rng:NextNumber()*2-.5,math.sin(a)*radius)
end

-- What each sequence draws round the held body while it plays (a beat every
-- ~0.16 s): Naruto's clones pouring in, Sasuke's lightning, the sand closing
-- into the pyramid, Lee's spin, Neji's palms, the red world, Minato's flashes,
-- Kakashi's white chakra blade.
local BEAT={
	clones=function(fx,p,look,rng,k)
		K.smokePuff(fx.folder,around(p,3.2,rng),rgb(236,230,220),6,1.3)
		K.flash(fx.folder,around(p,1.4,rng),look.core,.4,2.4,.1,.35)
	end,
	lion=function(fx,p,look,rng,k)
		if K.sparks then K.sparks(fx.folder,p+Vector3.new(0,rng:NextNumber()*2,0),look.core,8,22) end
		K.flash(fx.folder,around(p,1.2,rng),look.edge,.3,2.2,.08,.3)
	end,
	pyramid=function(fx,p,look,rng,k)
		local y=p.Y-2.6
		local spot=around(Vector3.new(p.X,y,p.Z),2+rng:NextNumber()*3,rng)
		local grain=K.block(fx.folder,Vector3.new(.9,.9,.9),CFrame.new(spot.X,y,spot.Z),look.core,Enum.Material.Sand)
		grain.CanCollide=false;grain.Anchored=true
		K.tween(grain,.35,{CFrame=CFrame.new(p+Vector3.new(0,.5,0)),Size=Vector3.new(.3,.3,.3)})
		Debris:AddItem(grain,.4)
		if k%3==0 then K.shockRing(fx.folder,Vector3.new(p.X,y+.1,p.Z),look.edge,3,9,.4) end
	end,
	lotus=function(fx,p,look,rng,k)
		K.shockRing(fx.folder,p,look.core,1.5,6,.25)
		K.smokePuff(fx.folder,p-Vector3.new(0,1.5,0),rgb(206,194,168),3,1)
	end,
	palms=function(fx,p,look,rng,k)
		K.flash(fx.folder,around(p,.9,rng),look.edge,.25,1.6,.07,.25)
		local open=fx.ultimateScreen
		if open and open.sub then
			local counts={2,4,8,16,32,64,128}
			open.sub.Text=tostring(counts[math.min(#counts,1+math.floor(k/2))]).." PALMS"
		end
	end,
	tsukuyomi=function(fx,p,look,rng,k)
		if k%2==0 then K.shockRing(fx.folder,p,look.core,1,7,.5) end
	end,
	flash=function(fx,p,look,rng,k)
		local from=around(p,6,rng)
		K.flash(fx.folder,from,look.core,.5,3,.1,.25)
		K.flash(fx.folder,around(p,1.2,rng),look.edge,.3,2,.08,.3)
	end,
	raikiri=function(fx,p,look,rng,k)
		if K.sparks then K.sparks(fx.folder,p,look.edge,10,26) end
		if k%2==0 then K.flash(fx.folder,p,look.core,.6,3.4,.1,.25) end
	end,
}
UltimateFX.BEAT=BEAT

local function sequence(fx,impact,folder)
	local look=lookOf(impact.kind)
	local time=impact.time or 3.4
	local victim=rootOf(modelFor(folder,impact.victim))
	UltimateFX.banner(fx,impact.name,look.core,time,if impact.kind=="palms" then "2 PALMS" else nil)
	UltimateFX.grade(fx,look,time)
	local beat=BEAT[impact.kind] or BEAT.clones
	local rng=Random.new(impact.serial or 1)
	local token={}
	fx.ultimateRun=token
	task.spawn(function()
		local started=UltimateFX.clock()
		local k=0
		while UltimateFX.clock()-started<time and fx.ultimateRun==token do
			k+=1
			local p=(victim and victim.Parent and victim.Position) or impact.position
			pcall(beat,fx,p,look,rng,k)
			task.wait(.16)
		end
	end)
	-- The pyramid closes at the end: a dome of sand over the body.
	if impact.kind=="pyramid" then
		task.delay(math.max(0,time-.9),function()
			if fx.ultimateRun~=token then return end
			local p=(victim and victim.Parent and victim.Position) or impact.position
			local dome=K.block(fx.folder,Vector3.new(1,1,1),CFrame.new(p),look.core,Enum.Material.Sand,"Part")
			dome.Shape=Enum.PartType.Ball;dome.CanCollide=false;dome.Anchored=true
			K.tween(dome,.35,{Size=Vector3.new(11,11,11)})
			task.delay(.6,function() if dome.Parent then K.tween(dome,.25,{Transparency=1}) end end)
			Debris:AddItem(dome,.9)
		end)
	end
	K.sound(K.anchorPart(fx.folder,impact.position),K.SOUND.whoosh,.6,.7)
end

local function impact(fx,impact,folder)
	local style=impact.style
	local p=impact.position
	if style=="ultimateStart" then
		local look=lookOf(impact.kind)
		K.flash(fx.folder,p,look.core,1,6,.18,.2)
		K.shockRing(fx.folder,p-Vector3.new(0,2.6,0),look.edge,2,12,.35)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.whoosh,.55,1.15)
		return true
	elseif style=="ultimate" then
		sequence(fx,impact,folder)
		return true
	elseif style=="ultimateTick" then
		local look=lookOf(impact.kind)
		K.flash(fx.folder,p,look.edge,.4,if impact.heavy then 3.2 else 2,.08,.25)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.hit,.35,1+((impact.index or 0)%4)*.06)
		return true
	elseif style=="ultimateEnd" then
		local look=lookOf(impact.kind)
		fx.ultimateRun=nil
		K.flash(fx.folder,p,look.core,1.2,9,.25,.15)
		K.shockRing(fx.folder,p-Vector3.new(0,2.4,0),look.core,3,18,.5)
		K.smokePuff(fx.folder,p-Vector3.new(0,2.4,0),rgb(206,194,168),12,2)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.boom,.7,.9)
		UltimateFX.closeBanner(fx)
		return true
	elseif style=="ultimateMiss" then
		fx.ultimateRun=nil
		K.smokePuff(fx.folder,p-Vector3.new(0,2.4,0),rgb(200,190,170),6,1.4)
		UltimateFX.closeBanner(fx)
		return true
	elseif style=="tsukuyomi" then
		local look=UltimateFX.LOOK.tsukuyomi
		K.shockRing(fx.folder,p,look.core,1,10,.6)
		-- The held body's player sees the red world; the caster only the ring.
		local mine=false
		pcall(function()
			local character=game:GetService("Players").LocalPlayer.Character
			mine=character~=nil and character.Name==impact.victim
		end)
		if mine then UltimateFX.grade(fx,look,impact.time or 1.5) end
		return true
	elseif style=="gate" then
		local tone=rgb(120,230,140)
		K.flash(fx.folder,p,tone,.8,4+(impact.gate or 1),.18,.25)
		K.shockRing(fx.folder,p-Vector3.new(0,2.6,0),tone,2,8+(impact.gate or 1)*2,.4)
		return true
	elseif style=="reveal" then
		K.flash(fx.folder,p,rgb(236,232,255),.6,3.2,.15,.3)
		return true
	-- (Stage 6) the interactions of Server/Interactions.
	elseif style=="steam" then
		-- A white cloud that holds for its time, puff after puff.
		local radius=impact.radius or 10
		local rng=Random.new(impact.serial or 3)
		for k=0,math.floor((impact.time or 3)/.3) do
			task.delay(k*.3,function()
				for _=1,3 do K.smokePuff(fx.folder,around(p,radius*.55,rng),rgb(238,240,244),5,radius*.35) end
			end)
		end
		K.flash(fx.folder,p,rgb(255,255,255),1,radius*.6,.2,.3)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.whoosh,.5,.6)
		return true
	elseif style=="puddle" then
		local radius=impact.radius or 9
		local disc=K.block(fx.folder,Vector3.new(.08,radius*2,radius*2),CFrame.new(p+Vector3.new(0,.06,0))*CFrame.Angles(0,0,math.rad(90)),rgb(90,160,220),Enum.Material.Glass,"Part")
		disc.Name="Puddle";disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.55;disc.Reflectance=.25
		task.delay(math.max(0,(impact.time or 6)-.6),function() if disc.Parent then K.tween(disc,.6,{Transparency=1}) end end)
		Debris:AddItem(disc,(impact.time or 6)+.1)
		return true
	elseif style=="conduct" then
		local at=impact.position or p
		K.shockRing(fx.folder,at+Vector3.new(0,.2,0),rgb(170,210,255),1,(impact.radius or 9)*2,.35)
		if K.sparks then K.sparks(fx.folder,p,rgb(220,236,255),14,26) end
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.electric,.6,1)
		return true
	elseif style=="sandmelt" then
		K.flash(fx.folder,p,rgb(255,150,60),.5,3,.18,.3)
		K.smokePuff(fx.folder,p-Vector3.new(0,1.6,0),rgb(214,176,112),5,1.2)
		return true
	elseif style=="jutsuclash" then
		K.flash(fx.folder,p,rgb(236,246,255),1.5,12,.3,.1)
		K.shockRing(fx.folder,p,rgb(150,200,255),2,22,.5)
		K.shockRing(fx.folder,p-Vector3.new(0,2.4,0),rgb(255,255,255),2,16,.45)
		if K.sparks then K.sparks(fx.folder,p,rgb(200,226,255),24,34) end
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.boom,.8,1.1)
		return true
	end
	return false
end
UltimateFX.impact=impact

function UltimateFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Ultimate",impact=impact})
end
return UltimateFX
