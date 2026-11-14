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
local Scripts=require(game:GetService("ReplicatedStorage").NinjaDuel.UltimateScripts)
local Face=require(game:GetService("ReplicatedStorage").NinjaDuel.Face)
local MeshKit=require(script.Parent.MeshKit)
local HoundFX=require(script.Parent.HoundFX)
local VfxKit=require(script.Parent.VfxKit)
local K -- Effects' helpers, handed over by install()
local ShadowFX=require(script.Parent.ShadowFX)
UltimateFX.clock=os.clock -- (headless tests drive time)

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
-- Per sequence: the core colour, its edge, the world's grade while it plays.
UltimateFX.LOOK={
	clones={core=rgb(255,150,40),edge=rgb(255,226,170),grade={tint=rgb(255,236,214),saturation=.15,contrast=.12}},
	lion={core=rgb(150,200,255),edge=rgb(236,246,255),grade={tint=rgb(214,226,255),saturation=-.2,contrast=.25}},
	pyramid={core=rgb(214,176,112),edge=rgb(150,112,70),grade={tint=rgb(255,232,196),saturation=-.1,contrast=.15}},
	lotus={core=rgb(120,230,140),edge=rgb(226,255,226),grade={tint=rgb(226,255,226),saturation=.1,contrast=.15}},
	palms={core=rgb(190,200,255),edge=rgb(250,250,255),grade={tint=rgb(226,230,255),saturation=-.35,contrast=.2}},
	tsukuyomi={core=rgb(200,20,30),edge=rgb(20,10,12),grade={tint=rgb(255,70,70),saturation=-1,contrast=.7,brightness=-.12}},
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
		return K.new("ColorCorrectionEffect",{Name="NinjaUltimateGrade",TintColor=look.grade.tint,Saturation=look.grade.saturation,Contrast=look.grade.contrast,Brightness=look.grade.brightness or 0},Lighting)
	end)
	if not ok or not cc then return end
	fx.ultimateGrade=cc
	task.delay(time,function()
		if cc.Parent then K.tween(cc,.3,{TintColor=Color3.new(1,1,1),Saturation=0,Contrast=0});Debris:AddItem(cc,.35) end
	end)
end

-- (13/11) A modelled stone (MeshKit "Rock") or, until ready, a slate block.
local function stone(parent,size,cf)
	-- A rock keeps its shadow (#62 light pass: light effects cast none, rocks do).
	local r=MeshKit.part("Rock")
	if r then
		r.Size=Vector3.new(size,size*.8,size*.9)*1.25;r.CFrame=cf;r.Parent=parent
		return ShadowFX.keep(r)
	end
	return ShadowFX.keep(K.block(parent,Vector3.one*size,cf,rgb(120,112,100),Enum.Material.Slate))
end
UltimateFX.stone=stone
-- A modelled prop's root moved (its pieces are welded to it): tween the root.
local function prop(name,parent,cf)
	local m=MeshKit.model(name)
	if not m then return nil end
	m.PrimaryPart.CFrame=cf
	m.Parent=parent
	return m
end
local function fadeModel(m,time,to)
	for _,d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name~="Root" then
			local base=d:GetAttribute("BaseAlpha")
			if base==nil then base=d.Transparency;d:SetAttribute("BaseAlpha",base) end
			K.tween(d,time,{Transparency=if to==1 then 1 else base})
		end
	end
end
local function hideModel(m)
	for _,d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name~="Root" then d:SetAttribute("BaseAlpha",d.Transparency);d.Transparency=1 end
	end
end

local function modelFor(folder,id) return folder and folder:FindFirstChild(id or "") end
local function rootOf(model) return model and model:FindFirstChild("HumanoidRootPart") end
local function around(position,radius,rng)
	local a=rng:NextNumber()*math.pi*2
	return position+Vector3.new(math.cos(a)*radius,rng:NextNumber()*2-.5,math.sin(a)*radius)
end

-- (Redone 02/11) Each sequence draws its own moments, on its own timeline
-- (Shared/UltimateScripts cues), round the bodies where they are drawn: no
-- shared "beat" any more. A clone of the caster's drawn body (afterimages,
-- Lee's ghosts) is copied part by part.
local function copyBody(fx,model,cf,life)
	if not model then return nil end
	local root=model:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local holder=K.new("Model",{Name="UltimateClone"},fx.folder)
	local base=root.CFrame
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" and d.Transparency<.9 and d.Size.Magnitude<8 then
			local ok,g=pcall(function() local was=d.Archivable;d.Archivable=true;local x=d:Clone();d.Archivable=was;return x end)
			if ok and g then
				for _,ch in g:GetChildren() do
					if not (ch:IsA("SpecialMesh") or ch:IsA("Decal") or ch:IsA("SurfaceAppearance") or ch:IsA("SurfaceGui") or ch:IsA("Texture")) then ch:Destroy() end
				end
				g.Anchored=true;g.CanCollide=false;g.CanQuery=false;g.CanTouch=false;g.CastShadow=false
				g.CFrame=cf*base:ToObjectSpace(d.CFrame)
				g.Parent=holder
			end
		end
	end
	Debris:AddItem(holder,life)
	return holder
end
UltimateFX.copyBody=copyBody
-- An afterimage: the body as drawn now, in one flat colour, fading.
local function ghost(fx,model,color,life)
	local root=model and model:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local g=copyBody(fx,model,root.CFrame,life+.05)
	if not g then return end
	for _,part in g:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color=color;part.Material=Enum.Material.Neon;part.Transparency=.45
			for _,d in part:GetChildren() do if d:IsA("Decal") then d:Destroy() end end
			K.tween(part,life,{Transparency=1})
		end
	end
end
UltimateFX.ghost=ghost

local function screen(fx)
	local gui=playerGui()
	if not gui then return nil end
	local s=gui:FindFirstChild("NinjaUltimateFX")
	if not s then s=K.new("ScreenGui",{Name="NinjaUltimateFX",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=41},gui) end
	return s
end
-- A word on the screen (U! ZU! the palm count, the hours): it slams in big
-- and settles, then goes.
function UltimateFX.textPop(fx,text,color,size,hold)
	local s=screen(fx)
	if not s then return nil end
	local label=K.new("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,(size or 70)*1.4),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.38),
		Font=Enum.Font.GothamBlack,Text=text,TextColor3=color,TextSize=(size or 70)*1.7,TextStrokeTransparency=0,TextStrokeColor3=Color3.new(),TextTransparency=0},s)
	K.tween(label,.12,{TextSize=size or 70})
	task.delay(hold or .5,function() if label.Parent then K.tween(label,.2,{TextTransparency=1,TextStrokeTransparency=1}) end end)
	Debris:AddItem(label,(hold or .5)+.3)
	return label
end
-- The impact frame: two frames of the world in black and white, hard
-- contrast, a white flash on top (the anime's "frame" on a decisive blow).
function UltimateFX.impactFrame(fx)
	pcall(function()
		local Lighting=game:GetService("Lighting")
		local cc=K.new("ColorCorrectionEffect",{Name="NinjaImpactFrame",Saturation=-1,Contrast=2.4,Brightness=.08},Lighting)
		task.delay(.05,function() if cc.Parent then cc.Contrast=-1.6;cc.Brightness=.25 end end)
		task.delay(.1,function() if cc.Parent then cc:Destroy() end end)
	end)
	local s=screen(fx)
	if s then
		local white=K.new("Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.35,BorderSizePixel=0,Size=UDim2.fromScale(1,1)},s)
		K.tween(white,.14,{BackgroundTransparency=1})
		Debris:AddItem(white,.2)
	end
end
-- A crater where a body is driven into the floor: a ring of thrown rock, the
-- crack, the dust.
function UltimateFX.crater(fx,p,color,size)
	size=size or 1
	local floor=Vector3.new(p.X,p.Y-2.9,p.Z)
	K.shockRing(fx.folder,floor+Vector3.new(0,.15,0),color,2,18*size,.45)
	K.smokePuff(fx.folder,floor+Vector3.new(0,.5,0),rgb(196,184,160),14,2.4*size)
	local rng=Random.new(math.floor(p.X*7+p.Z*13))
	for k=1,10 do
		local a=k/10*math.pi*2+rng:NextNumber()*.4
		-- (14/11, CM QA A4) stones a third of the size, thrown low: never in front of a face
		local rock=stone(fx.folder,(.2+rng:NextNumber()*.3)*size,CFrame.new(floor+Vector3.new(math.cos(a)*1.6,.3,math.sin(a)*1.6))*CFrame.Angles(rng:NextNumber()*3,rng:NextNumber()*3,0))
		local out=floor+Vector3.new(math.cos(a)*(4+rng:NextNumber()*3)*size,.2,math.sin(a)*(4+rng:NextNumber()*3)*size)
		K.tween(rock,.3,{CFrame=CFrame.new(out+Vector3.new(0,.6,0))*CFrame.Angles(rng:NextNumber()*6,rng:NextNumber()*6,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		task.delay(.35,function() if rock.Parent then K.tween(rock,.3,{CFrame=CFrame.new(out),Transparency=.2},Enum.EasingStyle.Quad,Enum.EasingDirection.In) end end)
		task.delay(1.6,function() if rock.Parent then K.tween(rock,.4,{Transparency=1}) end end)
		Debris:AddItem(rock,2.1)
	end
	-- the crater itself, modelled (sunk bowl, plates pushed up, cracks), or
	-- the old dark star of grooves
	local modelled=VfxKit.mark(fx.folder,"GroundCrater",floor,Vector3.yAxis,5*size,2,.6)
	for k=1,if modelled then 0 else 7 do
		local a=k/7*math.pi*2
		local len=(3+k%3)*size
		local c=K.block(fx.folder,Vector3.new(.25,.06,len),CFrame.new(floor+Vector3.new(math.cos(a)*len/2,.06,math.sin(a)*len/2))*CFrame.Angles(0,-a+math.pi/2,0),rgb(40,34,30),Enum.Material.Slate)
		task.delay(2,function() if c.Parent then K.tween(c,.5,{Transparency=1}) end end)
		Debris:AddItem(c,2.6)
	end
	K.sound(K.anchorPart(fx.folder,p),K.SOUND.boom,.8,.8)
	K.sound(K.anchorPart(fx.folder,p),K.SOUND.debris,.6,1,1.2)
end

-- The sequence's context: the frame of the catch, the bodies as drawn.
local function context(fx,impact,folder,look)
	local victimModel=modelFor(folder,impact.victim)
	local casterModel=modelFor(folder,impact.owner)
	local ctx={fx=fx,impact=impact,look=look,kind=impact.kind,time=impact.time or 3.4,started=UltimateFX.clock(),
		victimModel=victimModel,casterModel=casterModel,victim=rootOf(victimModel),caster=rootOf(casterModel),token={}}
	ctx.frame=if impact.origin and impact.line then Scripts.frame(impact.origin,impact.line) else Scripts.frame(impact.position or Vector3.zero,Vector3.new(0,0,-1))
	function ctx.vpos() return (ctx.victim and ctx.victim.Parent and ctx.victim.Position) or impact.position or ctx.frame.origin end
	function ctx.cpos() return (ctx.caster and ctx.caster.Parent and ctx.caster.Position) or ctx.frame.origin-ctx.frame.f*4 end
	function ctx.t() return UltimateFX.clock()-ctx.started end
	function ctx.live() return fx.ultimateRun==ctx.token end
	function ctx.floor(p) p=p or ctx.vpos();return Vector3.new(p.X,ctx.frame.origin.Y-2.9,p.Z) end
	-- Run fn every frame until `untilT` (sequence time) or the end.
	function ctx.loop(untilT,fn)
		task.spawn(function()
			while ctx.live() and ctx.t()<untilT do
				local ok=pcall(fn,ctx.t())
				if not ok then break end
				task.wait()
			end
		end)
	end
	function ctx.hand(model,side)
		model=model or ctx.casterModel
		return model and (model:FindFirstChild((side or "Right").."Hand") or model:FindFirstChild("HumanoidRootPart"))
	end
	return ctx
end

-- ------------------------------------------------------------------- cues
local CUE={}
UltimateFX.CUE=CUE
CUE.impactFrame=function(ctx) UltimateFX.impactFrame(ctx.fx) end
CUE.crater=function(ctx) UltimateFX.crater(ctx.fx,ctx.vpos(),ctx.look.core,1.2) end

-- Naruto -----------------------------------------------------------------
CUE.punch=function(ctx)
	local p=ctx.vpos()
	K.flash(ctx.fx.folder,p+Vector3.new(0,.3,0),ctx.look.edge,.6,4,.12,.2)
	K.shockRing(ctx.fx.folder,p,ctx.look.core,1,6,.25,ctx.frame.f)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.punch,.7,.9)
end
CUE.sign=function(ctx)
	-- The chakra pours out of him: an orange flare, the floor dust thrown out.
	local p=ctx.cpos()
	K.flash(ctx.fx.folder,p,ctx.look.core,2,9,.3,.3)
	K.shockRing(ctx.fx.folder,ctx.floor(p)+Vector3.new(0,.2,0),ctx.look.core,2,22,.5)
	K.smokePuff(ctx.fx.folder,ctx.floor(ctx.vpos())+Vector3.new(0,1,0),rgb(240,236,226),16,3)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.whoosh,.7,.8)
end

-- Sasuke ---------------------------------------------------------------
-- A groove torn in the floor behind a hand dragged low (the Chidori run,
-- the Raikiri run), glowing then cooling.
local function scar(ctx,model,untilT,color)
	local last=nil
	ctx.loop(untilT,function()
		local hand=ctx.hand(model)
		if not hand then return end
		local at=ctx.floor(hand.Position)+Vector3.new(0,.08,0)
		if last and (at-last).Magnitude>.8 then
			local mid=(at+last)/2
			local g=K.block(ctx.fx.folder,Vector3.new(.45,.12,(at-last).Magnitude+.2),CFrame.lookAt(mid,at),color,Enum.Material.Neon)
			K.tween(g,1.4,{Color=rgb(40,40,50),Size=Vector3.new(.3,.06,(at-last).Magnitude+.2)})
			task.delay(2.4,function() if g.Parent then K.tween(g,.5,{Transparency=1}) end end)
			Debris:AddItem(g,3)
			if K.sparks and math.random()<.5 then K.sparks(ctx.fx.folder,at,color,3,16) end
			last=at
		elseif not last then last=at end
	end)
end
CUE.chidoriRun=function(ctx)
	UltimateFX.handCharge(ctx.fx,ctx.casterModel,ctx.look,.8,false)
	scar(ctx,ctx.casterModel,.4,ctx.look.core)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.cpos()),K.SOUND.electric,.8,1.1)
end
CUE.impale=function(ctx)
	-- Through the body: a burst out of the back, the current running for a while.
	local p=ctx.vpos()
	K.flash(ctx.fx.folder,p+ctx.frame.f*.8,ctx.look.edge,1.2,7,.18,.1)
	K.shockRing(ctx.fx.folder,p+ctx.frame.f*1.2,ctx.look.core,1,9,.3,ctx.frame.f)
	if K.sparks then K.sparks(ctx.fx.folder,p+ctx.frame.f*1.2,ctx.look.core,20,40) end
	local t0=ctx.t()
	ctx.loop(t0+.45,function()
		if K.sparks and math.random()<.35 then K.sparks(ctx.fx.folder,ctx.vpos()+Vector3.new(0,math.random()-.3,0),ctx.look.edge,4,22) end
	end)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.electric,.9,.85)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.heavy,.6,.8)
end
CUE.throwUp=function(ctx)
	local p=ctx.vpos()
	K.shockRing(ctx.fx.folder,ctx.floor(p)+Vector3.new(0,.2,0),ctx.look.edge,2,14,.35)
	K.smokePuff(ctx.fx.folder,ctx.floor(p)+Vector3.new(0,.6,0),rgb(200,190,170),8,1.8)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.whooshBy,.6,.9)
end
CUE.airHit=function(ctx)
	local p=ctx.vpos()
	local d=(p-ctx.cpos())
	d=if d.Magnitude>.1 then d.Unit else ctx.frame.f
	K.shockRing(ctx.fx.folder,p,ctx.look.edge,1.5,10,.25,d)
	K.flash(ctx.fx.folder,p,ctx.look.core,.6,4.5,.12,.2)
end

-- Gaara: one sand mass, start to end --------------------------------------
-- ~110 grains that are never replaced: they pour out of the floor under him,
-- run to the body, climb it, close round it into a cocoon (with its shell),
-- rise with it on a column, tighten, crush, and fly apart. Each grain keeps
-- an offset in the held body's space once it has reached it.
local SAND=rgb(214,176,112)
local SAND_DARK=rgb(170,132,82)
local function sandMass(ctx)
	local fx=ctx.fx
	local rng=Random.new(ctx.impact.serial or 7)
	local mass={grains={},phase="flood",scale=1,shellSize=0}
	ctx.sand=mass
	local from=ctx.floor(ctx.cpos())+ctx.frame.f*1.2
	local N=110
	for i=1,N do
		local s=.45+rng:NextNumber()*.85
		-- (13/11) modelled clods of sand (tools/blender/fx_models.py) once ready
		local g=MeshKit.part("SandClump")
		if g then
			g.Size=Vector3.new(s,s*.8,s)*1.15;g.CFrame=CFrame.new(from);g.Parent=fx.folder
		else
			g=K.block(fx.folder,Vector3.new(s,s*.8,s),CFrame.new(from),if i%3==0 then SAND_DARK else SAND,Enum.Material.Sand)
		end
		g.Name="SandGrain"
		-- Its place on the body: a shell round it, low first (the legs), up to the head.
		local h=(i/N)
		local a=rng:NextNumber()*math.pi*2
		local r=1.05+rng:NextNumber()*.45
		local body=Vector3.new(math.cos(a)*r,-2.6+h*5.0,math.sin(a)*r*.8)
		-- Where it waits on the floor first (a pool round the feet).
		local pool=Vector3.new(math.cos(a)*(1.4+rng:NextNumber()*2.4),-2.75,math.sin(a)*(1.4+rng:NextNumber()*2.4))
		mass.grains[i]={part=g,body=body,pool=pool,spin=CFrame.Angles(rng:NextNumber()*6,rng:NextNumber()*6,rng:NextNumber()*6),
			delay=rng:NextNumber()*.55,arrive=nil,from=from+Vector3.new(rng:NextNumber()-.5,0,rng:NextNumber()-.5)}
	end
	-- The floor stain spreading under the body, the cocoon's shell, the column.
	local stain=K.block(fx.folder,Vector3.new(.08,1,1),CFrame.new(ctx.floor(ctx.vpos())+Vector3.new(0,.05,0))*CFrame.Angles(0,0,math.rad(90)),SAND,Enum.Material.Sand)
	stain.Shape=Enum.PartType.Cylinder;stain.Name="SandStain"
	K.tween(stain,.8,{Size=Vector3.new(.08,9,9)})
	-- (13/11, user: « sur Gaara il y a une colonne un peu bizarre qui s'élève »)
	-- The cocoon was a smooth ball and the column a plain dark cylinder: they
	-- are now modelled (fx_models.py): the coffin wraps the body from the feet
	-- up in thick spiral bands of sand, and a twisting rope of sand, flared into
	-- the floor and cupped at the top, lifts it. Primitives stay as the fallback.
	local shell=MeshKit.part("SandCoffin")
	if shell then
		mass.coffin=shell.Size;shell.CFrame=CFrame.new(ctx.vpos());shell.Parent=fx.folder
	else
		shell=K.block(fx.folder,Vector3.new(.1,.1,.1),CFrame.new(ctx.vpos()),SAND,Enum.Material.Sand)
		shell.Shape=Enum.PartType.Ball
	end
	shell.Name="SandCocoon";shell.Transparency=1
	local column=MeshKit.part("SandPillar")
	if column then
		mass.pillar=column.Size;column.CFrame=CFrame.new(ctx.floor());column.Parent=fx.folder
	else
		column=K.block(fx.folder,Vector3.new(.1,2.2,2.2),CFrame.new(ctx.floor()),SAND_DARK,Enum.Material.Sand)
		column.Shape=Enum.PartType.Cylinder
	end
	column.Name="SandColumn";column.Transparency=1
	mass.stain,mass.shell,mass.column=stain,shell,column
	local t0=ctx.t()
	ctx.loop(ctx.time+.5,function(t)
		local v=ctx.victim
		local vcf=if v and v.Parent then v.CFrame else CFrame.new(ctx.vpos())
		local floorY=ctx.frame.origin.Y-2.9
		for i,g in mass.grains do
			local cf
			if mass.phase=="flood" or (mass.phase=="grip" and g.body.Y>-1.2) then
				-- run along the floor from his feet to the pool round the body
				local k=math.clamp((t-t0-g.delay)/.45,0,1)
				local to=Vector3.new(vcf.Position.X,0,vcf.Position.Z)+Vector3.new(g.pool.X,floorY+.3,g.pool.Z)
				local p=g.from:Lerp(to,k*k*(3-2*k))+Vector3.new(0,math.sin(k*math.pi)*.6,0)
				cf=CFrame.new(p)*g.spin
			elseif mass.phase=="burst" then
				cf=nil
			else
				-- on the body: from the pool up to its place on the shell
				g.arrive=g.arrive or t
				local k=math.clamp((t-g.arrive)/.35,0,1)
				local place=vcf*(g.body*mass.scale)
				local pool=Vector3.new(vcf.Position.X+g.pool.X,floorY+.3,vcf.Position.Z+g.pool.Z)
				local p=pool:Lerp(place,k*k*(3-2*k))
				if mass.phase=="tighten" then p+=Vector3.new(math.sin(t*60+i)*.06,0,math.cos(t*55+i)*.06) end
				cf=CFrame.new(p)*g.spin
			end
			if cf then g.part.CFrame=cf end
		end
		if mass.shellSize>0 then
			if mass.coffin then
				-- it climbs from the feet: full width soon, full height last
				local k=mass.shellSize
				local base=mass.coffin*.97*mass.scale
				shell.Size=Vector3.new(base.X*(.72+.28*k),base.Y*k,base.Z*(.72+.28*k))
				shell.CFrame=vcf*CFrame.new(0,-base.Y*(1-k)/2,0)
			else
				shell.CFrame=vcf
				shell.Size=Vector3.new(2.5,5.4,2.5)*mass.shellSize*mass.scale
			end
		end
		if mass.columnOn then
			local top=vcf.Position.Y-2.6*mass.scale
			local h=math.max(.2,top-floorY)
			if mass.pillar then
				-- rooted .4 under the floor, its cup under the coffin, turning
				local tall=h+.4
				local w=.8*mass.scale
				column.Size=Vector3.new(mass.pillar.X*w,tall,mass.pillar.Z*w)
				column.CFrame=CFrame.new(vcf.Position.X,floorY-.4+tall/2,vcf.Position.Z)*CFrame.Angles(0,t*1.4,0)
			else
				column.CFrame=CFrame.new(vcf.Position.X,floorY+h/2,vcf.Position.Z)*CFrame.Angles(0,0,math.rad(90))
				column.Size=Vector3.new(h,2.4*mass.scale,2.4*mass.scale)
			end
		end
	end)
	return mass
end
CUE.sandFlood=function(ctx)
	sandMass(ctx)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.cpos()),K.SOUND.whoosh,.6,.6)
	K.smokePuff(ctx.fx.folder,ctx.floor(ctx.cpos())+Vector3.new(0,.4,0),SAND,6,1.6)
end
CUE.sandGrip=function(ctx)
	local m=ctx.sand;if not m then return end
	m.phase="grip"
	K.smokePuff(ctx.fx.folder,ctx.floor()+Vector3.new(0,.5,0),SAND,8,1.6)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.vpos()),K.SOUND.debris,.5,1.3,.8)
end
CUE.sandCocoon=function(ctx)
	local m=ctx.sand;if not m then return end
	m.phase="cocoon"
	m.shell.Transparency=0
	-- the shell grows over the body once the grains are on it
	task.spawn(function()
		local s=UltimateFX.clock()
		while ctx.live() and UltimateFX.clock()-s<.45 do m.shellSize=math.clamp((UltimateFX.clock()-s)/.45,0,1);task.wait() end
		m.shellSize=1
	end)
end
CUE.sandLift=function(ctx)
	local m=ctx.sand;if not m then return end
	m.columnOn=true;m.column.Transparency=0
	K.shockRing(ctx.fx.folder,ctx.floor()+Vector3.new(0,.2,0),SAND,2,14,.4)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.vpos()),K.SOUND.debris,.6,.8,1)
end
CUE.sandTighten=function(ctx)
	local m=ctx.sand;if not m then return end
	m.phase="tighten"
	task.spawn(function()
		local s=UltimateFX.clock()
		while ctx.live() and UltimateFX.clock()-s<.3 do m.scale=1-.12*math.clamp((UltimateFX.clock()-s)/.3,0,1);task.wait() end
	end)
end
CUE.sandCrush=function(ctx)
	local m=ctx.sand;if not m then return end
	m.scale=.72
	K.flash(ctx.fx.folder,ctx.vpos(),SAND,2,8,.2,.2)
	K.shockRing(ctx.fx.folder,ctx.vpos(),SAND,2,12,.3)
	UltimateFX.textPop(ctx.fx,"SABAKU SOSO",rgb(255,214,150),64,.8)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.vpos()),K.SOUND.boom,.7,1.2)
end
CUE.sandBurst=function(ctx)
	local m=ctx.sand;if not m then return end
	m.phase="burst"
	local center=ctx.vpos()
	local rng=Random.new(11)
	for _,g in m.grains do
		local d=g.part.Position-center
		d=if d.Magnitude>.1 then d.Unit else Vector3.yAxis
		local out=g.part.Position+d*(6+rng:NextNumber()*8)+Vector3.new(0,rng:NextNumber()*3,0)
		K.tween(g.part,.5,{CFrame=CFrame.new(out)*g.spin,Transparency=1})
		Debris:AddItem(g.part,.6)
	end
	K.tween(m.shell,.25,{Size=m.shell.Size*1.6,Transparency=1});Debris:AddItem(m.shell,.3)
	K.tween(m.column,.5,{Transparency=1});Debris:AddItem(m.column,.55)
	K.tween(m.stain,1.2,{Transparency=1});Debris:AddItem(m.stain,1.3)
	K.smokePuff(ctx.fx.folder,center,SAND,22,3.4)
	K.shockRing(ctx.fx.folder,center,SAND,3,26,.5)
	K.sound(K.anchorPart(ctx.fx.folder,center),K.SOUND.boom,.9,.7)
end

-- Lee ----------------------------------------------------------------------
CUE.gates=function(ctx)
	local p=ctx.cpos()
	for k=0,2 do
		task.delay(k*.1,function()
			K.shockRing(ctx.fx.folder,ctx.floor(p)+Vector3.new(0,.2,0),ctx.look.core,2,10+k*6,.35)
			K.flash(ctx.fx.folder,p,ctx.look.edge,1.5,5+k*2,.15,.3)
		end)
	end
	-- the floor breaks under him and the stones rise round him
	local rng=Random.new(5)
	for k=1,8 do
		local a=k/8*math.pi*2
		local at=ctx.floor(p)+Vector3.new(math.cos(a)*2.2,.2,math.sin(a)*2.2)
		local rock=stone(ctx.fx.folder,.4+rng:NextNumber()*.5,CFrame.new(at))
		K.tween(rock,.6,{CFrame=CFrame.new(at+Vector3.new(0,2+rng:NextNumber()*2,0))*CFrame.Angles(rng:NextNumber()*4,rng:NextNumber()*4,0)},Enum.EasingStyle.Sine)
		task.delay(.7,function() if rock.Parent then K.tween(rock,.3,{CFrame=CFrame.new(at),Transparency=1},Enum.EasingStyle.Quad,Enum.EasingDirection.In) end end)
		Debris:AddItem(rock,1.1)
	end
	UltimateFX.textPop(ctx.fx,"GATE OF LIMIT: OPEN",rgb(150,255,160),44,.6)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.boom,.6,1.3)
end
CUE.airTrail=function(ctx)
	-- he is everywhere: green afterimages of his body at every place he was
	local last=0
	ctx.loop(2.3,function(t)
		if t-last>=.075 then last=t;ghost(ctx.fx,ctx.casterModel,ctx.look.core,.3) end
	end)
end
CUE.bandage=function(ctx)
	local fx=ctx.fx
	local strip=K.block(fx.folder,Vector3.new(.2,.06,1),CFrame.new(ctx.cpos()),rgb(240,236,226),Enum.Material.Fabric)
	strip.Name="Bandage"
	local wraps={}
	ctx.loop(3.12,function(t)
		local hand=ctx.hand()
		local from=if hand then hand.Position else ctx.cpos()
		local to=ctx.vpos()
		local d=to-from
		if d.Magnitude>.1 then strip.Size=Vector3.new(.22,.06,d.Magnitude);strip.CFrame=CFrame.lookAt(from:Lerp(to,.5),to) end
		-- (13/11) the bandage wound round him: a modelled spiral ribbon
		-- (MeshKit "BandageWrap") that turns, or the old rings
		if not wraps.model and wraps.tried==nil and t>2.36 then
			wraps.tried=true
			wraps.model=prop("BandageWrap",fx.folder,CFrame.new(to))
		end
		if wraps.model then
			local k=math.clamp((t-2.36)/.2,.2,1)
			wraps.model.PrimaryPart.CFrame=CFrame.new(to+Vector3.new(0,-.4*(1-k),0))*CFrame.Angles(0,t*9,0)
		else
			if #wraps<5 and t>2.36+#wraps*.05 then
				local w=K.block(fx.folder,Vector3.new(.25,2.3,2.3),CFrame.new(to),rgb(240,236,226),Enum.Material.Fabric)
				w.Shape=Enum.PartType.Cylinder;w.Transparency=.15
				table.insert(wraps,w)
			end
			for i,w in wraps do
				w.CFrame=CFrame.new(to+Vector3.new(0,-1.6+i*.65,0))*CFrame.Angles(0,t*9+i,math.rad(90))
				w.Size=Vector3.new(.25,1.9,1.9)
			end
		end
	end)
	task.delay(math.max(0,3.15-ctx.t()),function()
		strip:Destroy()
		for _,w in wraps do w:Destroy() end
		if wraps.model then wraps.model:Destroy() end
	end)
end
CUE.spin=function(ctx)
	-- the fall: rings of wind spiral round the pair all the way down
	ctx.loop(3.1,function(t)
		if math.random()<.5 then
			local p=ctx.vpos()
			K.shockRing(ctx.fx.folder,p+Vector3.new(0,1,0),ctx.look.edge,2,6,.2)
		end
	end)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.vpos()),K.SOUND.whooshBy,.8,.7)
end

-- Neji -----------------------------------------------------------------
CUE.trigrams=function(ctx)
	local mid=ctx.cpos():Lerp(ctx.vpos(),.5)
	UltimateFX.trigrams(ctx.fx,ctx.floor(mid)+Vector3.new(0,.06,0),ctx.look,ctx.time)
	K.shockRing(ctx.fx.folder,ctx.floor(mid)+Vector3.new(0,.1,0),ctx.look.edge,2,18,.5)
	K.sound(K.anchorPart(ctx.fx.folder,mid),K.SOUND.whoosh,.5,1.4)
end
CUE.palmRain=function(ctx)
	-- every palm a point of light closing on the body; the points stay lit
	local times=Scripts.palmTimes()
	local i=1
	local rng=Random.new(3)
	local points={}
	ctx.loop(3.0,function(t)
		while times[i] and t>=times[i] do
			local v=ctx.victim
			if v then
				local off=Vector3.new((rng:NextNumber()-.5)*1.4,(rng:NextNumber()-.3)*2.4,-.55)
				local dot=K.block(ctx.fx.folder,Vector3.one*.22,v.CFrame*CFrame.new(off),ctx.look.edge,Enum.Material.Neon)
				dot.Shape=Enum.PartType.Ball
				table.insert(points,{part=dot,off=off})
				K.flash(ctx.fx.folder,(v.CFrame*CFrame.new(off)).Position,ctx.look.edge,.3,1.8,.07,.2)
				if i%3==0 then K.sound(K.anchorPart(ctx.fx.folder,v.Position),K.SOUND.hit,.25,1.2+(i%5)*.05) end
			end
			i+=1
		end
		local v=ctx.victim
		if v then for _,pt in points do pt.part.CFrame=v.CFrame*CFrame.new(pt.off) end end
	end)
	task.delay(ctx.time,function() for _,pt in points do if pt.part.Parent then pt.part:Destroy() end end end)
end
CUE.silence=function(ctx)
	-- a breath: the colour drains, the sound stops
	pcall(function()
		local Lighting=game:GetService("Lighting")
		local cc=K.new("ColorCorrectionEffect",{Name="NinjaSilence",Saturation=-.9,Contrast=.3},Lighting)
		task.delay(.32,function() if cc.Parent then cc:Destroy() end end)
	end)
end
CUE.lastPalm=function(ctx)
	local p=ctx.vpos()
	K.shockRing(ctx.fx.folder,p,ctx.look.edge,2,16,.35,ctx.frame.f)
	K.shockRing(ctx.fx.folder,p+ctx.frame.f*2,ctx.look.core,1,10,.3,ctx.frame.f)
	K.flash(ctx.fx.folder,p,ctx.look.edge,1.4,7,.2,.1)
	UltimateFX.textPop(ctx.fx,"HAKKE ROKUJUYON SHO",rgb(220,226,255),46,.8)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.boom,.7,1.3)
end

-- Itachi -----------------------------------------------------------------
CUE.eye=function(ctx)
	-- (13/11, #73, François: only Itachi has it, at given moments) the
	-- Mangekyō turns in his own eyes for the rest of the Tsukuyomi
	Face.mangekyoFor(ctx.casterModel,math.max(.8,(ctx.time or 3.4)-ctx.t()))
	-- the Mangekyo fills the screen for a moment
	local s=screen(ctx.fx)
	if s then
		local eye=K.new("Frame",{BackgroundColor3=rgb(200,16,24),Size=UDim2.fromOffset(40,40),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BorderSizePixel=0},s)
		K.new("UICorner",{CornerRadius=UDim.new(1,0)},eye)
		K.new("UIAspectRatioConstraint",{},eye)
		local pupil=K.new("Frame",{BackgroundColor3=Color3.new(),Size=UDim2.fromScale(.24,.24),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BorderSizePixel=0},eye)
		K.new("UICorner",{CornerRadius=UDim.new(1,0)},pupil)
		for k=0,2 do
			local a=k*math.pi*2/3
			local blade=K.new("Frame",{BackgroundColor3=Color3.new(),Size=UDim2.fromScale(.12,.42),AnchorPoint=Vector2.new(.5,1),
				Position=UDim2.fromScale(.5,.5),Rotation=math.deg(a),BorderSizePixel=0},eye)
			K.new("UICorner",{CornerRadius=UDim.new(1,0)},blade)
		end
		K.tween(eye,.35,{Size=UDim2.fromScale(.9,.9),Rotation=120},Enum.EasingStyle.Quint)
		task.delay(.35,function() if eye.Parent then K.tween(eye,.15,{BackgroundTransparency=1});for _,d in eye:GetChildren() do if d:IsA("Frame") then K.tween(d,.15,{BackgroundTransparency=1}) end end end end)
		Debris:AddItem(eye,.6)
	end
	K.sound(K.anchorPart(ctx.fx.folder,ctx.cpos()),K.SOUND.whoosh,.5,.5)
end
CUE.redWorld=function(ctx)
	local p=ctx.vpos()
	UltimateFX.grade(ctx.fx,UltimateFX.LOOK.tsukuyomi,3.0-ctx.t())
	local moon=K.block(ctx.fx.folder,Vector3.new(34,34,34),CFrame.new(p+ctx.frame.f*90+Vector3.new(0,55,0)),rgb(190,10,20),Enum.Material.Neon)
	moon.Shape=Enum.PartType.Ball;moon.Name="RedMoon";moon.Transparency=1
	K.tween(moon,.4,{Transparency=0})
	task.delay(2.9,function() if moon.Parent then moon:Destroy() end end)
	-- the floor goes black under the body (a dark disc to the horizon)
	local floor=K.block(ctx.fx.folder,Vector3.new(.1,120,120),CFrame.new(ctx.floor(p)+Vector3.new(0,.04,0))*CFrame.Angles(0,0,math.rad(90)),rgb(18,6,8),Enum.Material.SmoothPlastic)
	floor.Shape=Enum.PartType.Cylinder;floor.Transparency=1;floor.Name="TsukuyomiFloor"
	K.tween(floor,.3,{Transparency=.05})
	task.delay(2.9,function() if floor.Parent then floor:Destroy() end end)
end
CUE.cross=function(ctx)
	local p=ctx.vpos()
	local back=ctx.frame.f*.75
	local cf=CFrame.lookAt(ctx.floor(p)+back,ctx.floor(p)+back-ctx.frame.f)
	-- (13/11) a modelled cross of rough timber lashed with rope
	local cross=prop("TsukuyomiCross",ctx.fx.folder,cf)
	if cross then
		cross.Name="TsukuyomiCross"
		hideModel(cross);fadeModel(cross,.25,0)
		task.delay(math.max(0,3.3-ctx.t()),function() cross:Destroy() end)
		return
	end
	local post=K.block(ctx.fx.folder,Vector3.new(.7,9,.5),cf*CFrame.new(0,4.5,0),rgb(30,18,18),Enum.Material.Wood)
	local bar=K.block(ctx.fx.folder,Vector3.new(6,.6,.5),cf*CFrame.new(0,5.4,0),rgb(30,18,18),Enum.Material.Wood)
	post.Name="TsukuyomiCross";bar.Name="TsukuyomiCross"
	for _,x in {post,bar} do x.Transparency=1;K.tween(x,.25,{Transparency=0}) end
	task.delay(math.max(0,3.3-ctx.t()),function() post:Destroy();bar:Destroy() end)
end
CUE.swords=function(ctx)
	-- the swords, again: from every side into the body, held, gone
	local p=ctx.vpos()
	local rng=Random.new(math.floor(ctx.t()*100))
	for k=1,6 do
		local a=rng:NextNumber()*math.pi*2
		local dir=Vector3.new(math.cos(a),(rng:NextNumber()-.3)*.6,math.sin(a)).Unit
		local tip=p+Vector3.new(0,rng:NextNumber()*1.6-.4,0)
		-- (13/11) modelled katanas (MeshKit "Katana": the point 3.2 ahead of the grip)
		local sword=prop("Katana",ctx.fx.folder,CFrame.lookAt(tip+dir*6.4,tip))
		if sword then
			K.tween(sword.PrimaryPart,.08,{CFrame=CFrame.lookAt(tip+dir*2.4,tip)},Enum.EasingStyle.Linear)
			task.delay(.35,function() if sword.Parent then fadeModel(sword,.1,1) end end)
			Debris:AddItem(sword,.5)
		else
			local blade=K.block(ctx.fx.folder,Vector3.new(.12,.3,3.6),CFrame.lookAt(tip+dir*5,tip),rgb(30,30,34),Enum.Material.Metal)
			K.tween(blade,.08,{CFrame=CFrame.lookAt(tip+dir*1.4,tip)},Enum.EasingStyle.Linear)
			task.delay(.35,function() if blade.Parent then K.tween(blade,.1,{Transparency=1}) end end)
			Debris:AddItem(blade,.5)
		end
	end
	K.flash(ctx.fx.folder,p,ctx.look.core,.8,4,.15,.3)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.swish,.6,.8)
end
CUE.worldBack=function(ctx)
	local g=ctx.fx.ultimateGrade
	if g and g.Parent then g:Destroy() end
	K.flash(ctx.fx.folder,ctx.vpos(),Color3.new(1,1,1),2,10,.15,.2)
	for _,d in ctx.fx.folder:GetChildren() do if d.Name=="RedMoon" or d.Name=="TsukuyomiFloor" or d.Name=="TsukuyomiCross" then d:Destroy() end end
end

-- Minato -----------------------------------------------------------------
UltimateFX.kunai=function(fx,from,to,look)
	-- (13/11) his three-pronged kunai, modelled (MeshKit "MarkedKunai")
	local stuck=CFrame.lookAt(to+Vector3.new(0,.4,0),to+Vector3.new(0,-1,0))
	local mk=prop("MarkedKunai",fx.folder,CFrame.lookAt(from,to))
	if mk then
		mk.Name="FlashKunai"
		K.tween(mk.PrimaryPart,.2,{CFrame=stuck},Enum.EasingStyle.Linear)
		task.delay(.22,function() if mk.Parent then K.shockRing(fx.folder,to+Vector3.new(0,.1,0),look.core,.5,3,.3) end end)
		Debris:AddItem(mk,3.6)
		return
	end
	local k=K.block(fx.folder,Vector3.new(.16,.16,1.1),CFrame.lookAt(from,to),rgb(60,60,66),Enum.Material.Metal)
	k.Name="FlashKunai"
	local mark=K.block(fx.folder,Vector3.new(.06,.06,.5),CFrame.lookAt(from,to)*CFrame.new(0,0,.55),look.core,Enum.Material.Neon)
	local stuck=CFrame.lookAt(to+Vector3.new(0,.4,0),to+Vector3.new(0,-1,0))
	K.tween(k,.2,{CFrame=stuck},Enum.EasingStyle.Linear)
	K.tween(mark,.2,{CFrame=stuck*CFrame.new(0,0,-.55)},Enum.EasingStyle.Linear)
	task.delay(.22,function() if k.Parent then K.shockRing(fx.folder,to+Vector3.new(0,.1,0),look.core,.5,3,.3) end end)
	Debris:AddItem(k,3.6);Debris:AddItem(mark,3.6)
end
CUE.kunaiFan=function(ctx)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.cpos()),K.SOUND.swish,.6,1.3)
end
CUE.timeStop=function(ctx)
	-- time stops: the world grey; every place he appears leaves its yellow
	-- streak hanging in the air until time starts again
	pcall(function()
		local Lighting=game:GetService("Lighting")
		local cc=K.new("ColorCorrectionEffect",{Name="NinjaTimeStop",Saturation=-1,Contrast=.35,TintColor=rgb(230,236,255)},Lighting)
		ctx.timeStop=cc
		task.delay(math.max(0,2.95-ctx.t()),function() if cc.Parent then cc:Destroy() end end)
	end)
	K.shockRing(ctx.fx.folder,ctx.vpos(),ctx.look.edge,1,30,.4)
	local streaks={}
	ctx.streaks=streaks
	local last=ctx.cpos()
	ctx.loop(2.9,function()
		local now=ctx.cpos()
		if (now-last).Magnitude>2 then
			local s=K.block(ctx.fx.folder,Vector3.new(.3,.3,(now-last).Magnitude),CFrame.lookAt(last:Lerp(now,.5),now),ctx.look.core,Enum.Material.Neon)
			s.Transparency=.1;table.insert(streaks,s)
			local cut=K.block(ctx.fx.folder,Vector3.new(.08,2.4,.08),CFrame.new(ctx.vpos())*CFrame.Angles(math.random()*3,math.random()*3,math.random()*3),Color3.new(1,1,1),Enum.Material.Neon)
			cut.Transparency=.2;table.insert(streaks,cut)
		end
		last=now
	end)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.vpos()),K.SOUND.whoosh,.7,.4)
end
CUE.timeStart=function(ctx)
	if ctx.timeStop and ctx.timeStop.Parent then ctx.timeStop:Destroy() end
	for _,s in ctx.streaks or {} do
		if s.Parent then K.tween(s,.25,{Transparency=1,Size=s.Size*Vector3.new(.2,.2,1)});Debris:AddItem(s,.3) end
	end
	for _,d in ctx.fx.folder:GetChildren() do
		if d.Name=="FlashKunai" then if d:IsA("Model") then fadeModel(d,.2,1) else K.tween(d,.2,{Transparency=1}) end end
	end
end
CUE.cutsLand=function(ctx)
	local p=ctx.vpos()
	for k=1,8 do
		local cut=K.block(ctx.fx.folder,Vector3.new(.1,4,.1),CFrame.new(p)*CFrame.Angles(k*.7,k*1.3,k*.4),ctx.look.edge,Enum.Material.Neon)
		K.tween(cut,.25,{Size=Vector3.new(.02,5,.02),Transparency=1})
		Debris:AddItem(cut,.3)
	end
	K.flash(ctx.fx.folder,p,ctx.look.core,1.5,8,.2,.1)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.swish,.9,1.1)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.heavy,.6,1)
end

-- Kakashi --------------------------------------------------------------
CUE.hounds=function(ctx)
	-- Kuchiyose: eight hounds burst out of the floor and pin the body
	local p=ctx.vpos()
	local rng=Random.new(9)
	local hounds={}
	for k=0,7 do
		local a=k/8*math.pi*2+.2
		local spot=ctx.floor(p)+Vector3.new(math.cos(a)*1.5,0,math.sin(a)*1.5)
		local look=CFrame.lookAt(spot,Vector3.new(p.X,spot.Y,p.Z))
		-- (13/11) the modelled ninken (Client/HoundFX) out of the floor, biting
		if MeshKit.has("Ninken1") then
			local ok,dog=pcall(function() return (HoundFX.build(k%4+1)) end)
			if ok and dog then
				dog.Name="Hound";dog.Parent=ctx.fx.folder
				local lift=dog:GetAttribute("Lift") or .8
				local aim=CFrame.lookAt(spot,Vector3.new(p.X,spot.Y,p.Z))
				local root=dog.PrimaryPart
				root.CFrame=aim*CFrame.new(0,-1.6,0)*CFrame.Angles(math.rad(35),0,0)
				K.tween(root,.15,{CFrame=aim*CFrame.new(0,lift+rng:NextNumber()*.3,.2)*CFrame.Angles(math.rad(-12),0,0)})
				K.smokePuff(ctx.fx.folder,spot+Vector3.new(0,.5,0),rgb(196,184,160),3,1)
				table.insert(hounds,dog)
				continue
			end
		end
		local dog=K.new("Model",{Name="Hound"},ctx.fx.folder)
		local tone=if k%3==0 then rgb(120,96,70) else rgb(70,70,80)
		local body=K.block(dog,Vector3.new(.9,.9,1.8),look*CFrame.new(0,-1.4,0),tone,Enum.Material.SmoothPlastic)
		local head=K.block(dog,Vector3.new(.7,.7,.8),look*CFrame.new(0,-1.1,-1.1),tone,Enum.Material.SmoothPlastic)
		local band=K.block(dog,Vector3.new(.72,.2,.82),look*CFrame.new(0,-.85,-1.1),rgb(40,50,90),Enum.Material.Fabric)
		local up=CFrame.new(0,1.4+rng:NextNumber()*.4,0)
		K.tween(body,.15,{CFrame=up*body.CFrame});K.tween(head,.15,{CFrame=up*head.CFrame});K.tween(band,.15,{CFrame=up*band.CFrame})
		K.smokePuff(ctx.fx.folder,spot+Vector3.new(0,.5,0),rgb(196,184,160),3,1)
		table.insert(hounds,dog)
	end
	task.delay(math.max(0,2.42-ctx.t()),function()
		for _,dog in hounds do
			local c=dog:GetPivot().Position
			K.smokePuff(ctx.fx.folder,c,rgb(236,236,240),3,1)
			dog:Destroy()
		end
	end)
	K.sound(K.anchorPart(ctx.fx.folder,p),K.SOUND.debris,.6,1.1,.8)
end
CUE.raikiriCharge=function(ctx)
	UltimateFX.handCharge(ctx.fx,ctx.casterModel,ctx.look,2.2,true)
	ctx.loop(2.45,function()
		if math.random()<.3 then
			local hand=ctx.hand()
			if hand and K.sparks then K.sparks(ctx.fx.folder,hand.Position,ctx.look.edge,4,26) end
			if hand and math.random()<.3 then K.shockRing(ctx.fx.folder,ctx.floor(hand.Position)+Vector3.new(0,.1,0),ctx.look.core,1,5,.2) end
		end
	end)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.cpos()),K.SOUND.electric,.9,.7)
end
CUE.raikiriRun=function(ctx)
	scar(ctx,ctx.casterModel,2.45,ctx.look.edge)
	K.sound(K.anchorPart(ctx.fx.folder,ctx.cpos()),K.SOUND.electric,.9,1.2)
end

local function sequence(fx,impact,folder)
	local look=lookOf(impact.kind)
	local ctx=context(fx,impact,folder,look)
	fx.ultimateRun=ctx.token
	UltimateFX.banner(fx,impact.name,look.core,ctx.time)
	-- the world's grade, unless the sequence changes the world itself
	if impact.kind~="tsukuyomi" and impact.kind~="flash" then UltimateFX.grade(fx,look,ctx.time) end
	local spec=Scripts.KINDS[impact.kind or ""]
	for _,cue in (spec and spec.cues) or {} do
		local t,name=cue[1],cue[2]
		local function run()
			if not ctx.live() then return end
			if string.sub(name,1,5)=="text:" then UltimateFX.textPop(fx,string.sub(name,6),look.edge,42,.9);return end
			local fn=CUE[name]
			if fn then pcall(fn,ctx) end
		end
		if t<=0 then run() else task.delay(t,run) end
	end
	fx.ultimateCtx=ctx
	K.sound(K.anchorPart(fx.folder,impact.position),K.SOUND.whoosh,.6,.7)
	return ctx
end
UltimateFX.sequence=sequence
UltimateFX.context=context

-- A ball of lightning held in the caster's right hand for `time` seconds
-- (white and long for the Raikiri).
function UltimateFX.handCharge(fx,model,look,time,big)
	local hand=model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm") or model:FindFirstChild("HumanoidRootPart")
	if not hand then return end
	local ball=K.block(fx.folder,Vector3.new(1,1,1)*(if big then 1.6 else 1.2),hand.CFrame,look.edge,Enum.Material.Neon)
	ball.Shape=Enum.PartType.Ball;ball.Name="HandCharge";ball.Transparency=.15
	local started=UltimateFX.clock()
	task.spawn(function()
		while ball.Parent and UltimateFX.clock()-started<time do
			if hand.Parent then ball.CFrame=hand.CFrame*CFrame.new(0,-.6,0) end
			if math.random()<.5 and K.sparks then K.sparks(fx.folder,ball.Position,look.core,3,18) end
			task.wait(.03)
		end
		if ball.Parent then ball:Destroy() end
	end)
	Debris:AddItem(ball,time+.2)
end
-- The eight trigrams: a ring on the floor with its eight marks.
function UltimateFX.trigrams(fx,center,look,time)
	-- (13/11) the Hakke field modelled: circles, the eight trigrams, the
	-- yin-yang (MeshKit "Trigrams", 16 across), turning slowly under them
	local field=prop("Trigrams",fx.folder,CFrame.new(center))
	if field then
		field.Name="Trigrams"
		hideModel(field);fadeModel(field,.25,0)
		local root=field.PrimaryPart
		K.tween(root,time,{CFrame=CFrame.new(center)*CFrame.Angles(0,math.rad(40),0)},Enum.EasingStyle.Linear)
		task.delay(math.max(0,time-.3),function() if field.Parent then fadeModel(field,.3,1) end end)
		Debris:AddItem(field,time)
		return
	end
	local disc=K.block(fx.folder,Vector3.new(.06,16,16),CFrame.new(center)*CFrame.Angles(0,0,math.rad(90)),look.core,Enum.Material.Neon,"Part")
	disc.Name="Trigrams";disc.Shape=Enum.PartType.Cylinder;disc.Transparency=.75
	for k=0,7 do
		local angle=k*math.pi/4
		local mark=K.block(fx.folder,Vector3.new(1.6,.08,.3),CFrame.new(center+Vector3.new(math.cos(angle)*6.2,.05,math.sin(angle)*6.2))*CFrame.Angles(0,-angle,0),look.edge,Enum.Material.Neon)
		mark.Name="Trigram"
		Debris:AddItem(mark,time)
	end
	Debris:AddItem(disc,time)
end
-- (07/11, Studio: the clash was a white ring on the floor, over at once)
-- Rasengan into Chidori, the grind: for `duration` seconds the spinning blue
-- sphere and the crackling lightning press into each other between the two
-- held bodies, sparks thrown off where they meet; the burst follows (the
-- server's second "jutsuclash" contact).
local RASEN=rgb(120,190,255)
local RASEN_CORE=rgb(226,244,255)
local VOLT=rgb(176,214,255)
local function grind(fx,impact,folder)
	local mid=impact.position
	local line=impact.direction or Vector3.zAxis
	line=Vector3.new(line.X,0,line.Z)
	line=if line.Magnitude>.05 then line.Unit else Vector3.zAxis
	local life=math.max(.15,impact.duration or .4)
	-- the Rasengan side: toward its holder (owner or victim of the contact)
	local towardRasen=if impact.rasengan==impact.victim then line else -line
	local holder=K.new("Model",{Name="JutsuGrind"},fx.folder)
	local sphere=K.block(holder,Vector3.one*1.9,CFrame.new(mid+towardRasen*1),RASEN,Enum.Material.Neon)
	sphere.Shape=Enum.PartType.Ball;sphere.Transparency=.35
	local core=K.block(holder,Vector3.one*1.1,CFrame.new(mid+towardRasen*1),RASEN_CORE,Enum.Material.Neon)
	core.Shape=Enum.PartType.Ball;core.Transparency=.1
	local rings={}
	for k=1,2 do
		local ring=K.block(holder,Vector3.new(.08,2.6,2.6),CFrame.new(mid+towardRasen*1),RASEN_CORE,Enum.Material.Neon)
		ring.Shape=Enum.PartType.Cylinder;ring.Transparency=.45;rings[k]=ring
	end
	local arcs=K.new("Model",{Name="Volt"},holder)
	local born=os.clock()
	local rng=Random.new()
	K.sound(K.anchorPart(fx.folder,mid),K.SOUND.electric,.55,1.1)
	K.sound(K.anchorPart(fx.folder,mid),K.SOUND.whoosh,.4,.6)
	task.spawn(function()
		local nextSpark=0
		while holder.Parent and os.clock()-born<life do
			local t=os.clock()-born
			local swell=1+t/life*.5
			local at=mid+towardRasen*1
			sphere.Size=Vector3.one*1.9*swell;core.Size=Vector3.one*1.1*swell
			sphere.CFrame=CFrame.new(at);core.CFrame=CFrame.new(at)
			for k,ring in rings do ring.CFrame=CFrame.new(at)*CFrame.Angles(t*24*(if k==1 then 1 else -1),t*9,math.rad(90)*(k-1)) end
			-- the lightning: jagged arcs out of the other side into the sphere
			arcs:ClearAllChildren()
			local from=mid-towardRasen*1.2
			for _=1,7 do
				local a=from+Vector3.new(rng:NextNumber(-1,1),rng:NextNumber(-1,1),rng:NextNumber(-1,1))*.9
				local b=mid+Vector3.new(rng:NextNumber(-.6,.6),rng:NextNumber(-.6,.6),rng:NextNumber(-.6,.6))
				local last=a
				for k=1,3 do
					local q=if k==3 then b else a:Lerp(b,k/3)+Vector3.new(rng:NextNumber(-.3,.3),rng:NextNumber(-.3,.3),rng:NextNumber(-.3,.3))
					local len=(q-last).Magnitude
					if len>.03 then K.block(arcs,Vector3.new(.08,.08,len),CFrame.lookAt(last:Lerp(q,.5),q),if rng:NextNumber()<.35 then RASEN_CORE else VOLT,Enum.Material.Neon) end
					last=q
				end
			end
			if t>=nextSpark then
				nextSpark=t+.08
				if K.sparks then K.sparks(fx.folder,mid,RASEN_CORE,6,24) end
			end
			task.wait(.03)
		end
		if holder.Parent then holder:Destroy() end
	end)
end
local function impact(fx,impact,folder)
	local style=impact.style
	local p=impact.position
	if style=="ultimateStart" then
		local look=lookOf(impact.kind)
		-- The Chidori and the Raikiri are formed at the press.
		if impact.kind=="lion" or impact.kind=="raikiri" then
			local caster=modelFor(folder,impact.owner)
			if caster then UltimateFX.handCharge(fx,caster,look,.5,impact.kind=="raikiri") end
		end
		K.flash(fx.folder,p,look.core,1,6,.18,.2)
		K.shockRing(fx.folder,p-Vector3.new(0,2.6,0),look.edge,2,12,.35)
		K.sound(K.anchorPart(fx.folder,p),K.SOUND.whoosh,.55,1.15)
		return true
	elseif style=="ultimate" then
		sequence(fx,impact,folder)
		return true
	elseif style=="ultimateTick" then
		-- A blow of the sequence: its own sound per fighter, the heavy ones
		-- louder, and the words that go with it (U! ZU! MA! KI!, the count).
		local look=lookOf(impact.kind)
		local quiet=impact.kind=="tsukuyomi" or impact.kind=="palms" or impact.kind=="pyramid"
		if not quiet then K.flash(fx.folder,p,look.edge,.4,if impact.heavy then 3.6 else 2.2,.08,.25) end
		local SND={clones=K.SOUND.punch,lion=K.SOUND.electric,pyramid=K.SOUND.debris,lotus=K.SOUND.punch,palms=K.SOUND.hit,tsukuyomi=K.SOUND.swish,flash=K.SOUND.swish,raikiri=K.SOUND.electric}
		K.sound(K.anchorPart(fx.folder,p),SND[impact.kind or ""] or K.SOUND.hit,if impact.heavy then .7 else .4,1+((impact.index or 0)%4)*.06,.6)
		if impact.heavy then K.sound(K.anchorPart(fx.folder,p),K.SOUND.heavy,.55,.9) end
		if impact.text and impact.kind~="pyramid" then
			local big=impact.kind=="clones" and #impact.text<=2
			UltimateFX.textPop(fx,impact.text..(if big then "!" else ""),if impact.kind=="tsukuyomi" then rgb(255,60,60) else look.edge,if big then 110 else 54,if big then .32 else .55)
		end
		return true
	elseif style=="ultimateKunai" then
		local caster=rootOf(modelFor(folder,impact.owner))
		local from=if caster then caster.Position else p
		for i,point in impact.points or {} do task.delay((i-1)*.02,function() UltimateFX.kunai(fx,from,point,UltimateFX.LOOK.flash) end) end
		return true
	elseif style=="ultimateEnd" then
		local look=lookOf(impact.kind)
		-- (the sequence's own cues keep running to its end: a burst, a crater)
		task.delay(.35,function() if fx.ultimateCtx and fx.ultimateCtx.kind==impact.kind then fx.ultimateRun=nil end end)
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
		-- (13/11, #73) the genjutsu is cast with the Mangekyō
		Face.mangekyoFor(modelFor(folder,impact.owner),impact.time or 1.5)
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
		-- (Jutsu pass 05/11, user: « la flaque d'eau de Kakashi ») The water
		-- used to be one flat blue disc, 18 studs wide, drawn at the impact:
		-- where the dragon broke on a body that is chest height, so it hung in
		-- the air. Now it lies ON the floor under the impact: a wet patch of
		-- overlapping ovals (dark, glossy, see-through), spreading in, a few
		-- ripples while it lasts, soaking away at the end. Same area as the
		-- server's (Interactions.PUDDLE): lightning into it still conducts.
		local radius=impact.radius or 9
		local life=impact.time or 6
		local hit=K.floorUnder and K.floorUnder(fx,p,2,16)
		local ground=if hit then hit.Position else p-Vector3.new(0,2.9,0)
		local rng=Random.new(impact.serial or math.floor(p.X*7+p.Z*13))
		local holder=K.new("Model",{Name="Puddle"},fx.folder)
		local patches={}
		-- (06/11, user: « la flaque est mieux mais pas très belle ») It read
		-- as a flat sheet of blue plastic laid on the sand. Water over sand is
		-- mostly the sand, darker and glossy: three layers now -
		--   soaked ground: the floor's own colour darkened, ragged, wider
		--     than the water (the sand drank the edge);
		--   the water: barely blue, see-through over the soaked ground, very
		--     reflective (it mirrors the sky);
		--   a few bright glints of sky on it.
		local floorColor=if hit and hit.Instance and hit.Instance:IsA("BasePart") then hit.Instance.Color else rgb(196,168,120)
		local SOAK=floorColor:Lerp(rgb(40,34,30),.45)
		local WATER=rgb(78,110,132)
		local function patch(at,w,d,color,transparency,material,reflect,yaw)
			local part=K.block(holder,Vector3.new(w,.06,d),CFrame.new(at)*CFrame.Angles(0,yaw or rng:NextNumber(0,math.pi*2),0),color,material,"Part")
			K.new("SpecialMesh",{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,.4,1)},part)
			part.Reflectance=reflect or 0;part.Transparency=1;part.CastShadow=false
			table.insert(patches,{part=part,size=part.Size,transparency=transparency})
			return part
		end
		-- soaked ground: one body, lobes round it (opaque, one colour: no seams)
		patch(ground+Vector3.new(0,.02,0),radius*1.75,radius*1.5,SOAK,0,Enum.Material.SmoothPlastic)
		for k=1,8 do
			local a=k/8*math.pi*2+rng:NextNumber(-.3,.3)
			local off=Vector3.new(math.cos(a),0,math.sin(a))*radius*rng:NextNumber(.55,.85)
			local sz=radius*rng:NextNumber(.45,.75)
			patch(ground+off+Vector3.new(0,.018-k*.001,0),sz,sz*rng:NextNumber(.6,.9),SOAK,0,Enum.Material.SmoothPlastic)
		end
		-- the water: smaller than the soaked ground, see-through, glossy
		patch(ground+Vector3.new(0,.05,0),radius*1.35,radius*1.1,WATER,.45,Enum.Material.Glass,.45)
		for k=1,4 do
			local a=k/4*math.pi*2+rng:NextNumber(-.4,.4)
			local off=Vector3.new(math.cos(a),0,math.sin(a))*radius*rng:NextNumber(.3,.5)
			local sz=radius*rng:NextNumber(.45,.65)
			patch(ground+off+Vector3.new(0,.048,0),sz,sz*rng:NextNumber(.6,.85),WATER,.45,Enum.Material.Glass,.45)
		end
		-- glints of sky
		for k=1,3 do
			local off=Vector3.new(rng:NextNumber(-1,1),0,rng:NextNumber(-1,1))*radius*.4
			patch(ground+off+Vector3.new(0,.07,0),radius*rng:NextNumber(.12,.22),radius*rng:NextNumber(.04,.07),rgb(230,244,255),.35,Enum.Material.SmoothPlastic,0)
		end
		for _,entry in patches do
			entry.part.Size=entry.size*Vector3.new(.35,1,.35)
			K.tween(entry.part,.28,{Size=entry.size,Transparency=entry.transparency},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		end
		-- the splash where it lands (VFX Studio's water burst and droplets),
		-- then rings spreading on the water now and then (its ripple flipbook,
		-- laid flat on the surface)
		K.shockRing(fx.folder,ground+Vector3.new(0,.12,0),rgb(200,230,255),1,radius*1.6,.4)
		if K.SOUND and K.SOUND.splash then K.sound(K.anchorPart(fx.folder,ground),K.SOUND.splash,.7,.9) end
		local TEX=K.TEX or {}
		local water=K.new("Part",{Name="PuddleWater",Size=Vector3.new(.2,.2,.2),CFrame=CFrame.new(ground+Vector3.new(0,.12,0)),Transparency=1,
			Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false},holder)
		local at=K.new("Attachment",{},water)
		if TEX.splash then
			local splash=K.new("ParticleEmitter",{Texture=TEX.splash,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid8x8,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
				Rate=0,Lifetime=NumberRange.new(.55,.65),Speed=NumberRange.new(0,0),Color=ColorSequence.new(rgb(190,225,255)),LightEmission=.25,
				Size=K.num({{0,radius*.6},{1,radius*.9}}),Transparency=K.num({{0,.05},{1,.4}}),Rotation=NumberRange.new(0,360)},at)
			splash:Emit(2)
		end
		if TEX.droplets then
			local drops=K.new("ParticleEmitter",{Texture=TEX.droplets,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
				Rate=0,Lifetime=NumberRange.new(.5,.8),Speed=NumberRange.new(8,16),SpreadAngle=Vector2.new(50,50),EmissionDirection=Enum.NormalId.Top,
				Acceleration=Vector3.new(0,-40,0),Color=ColorSequence.new(rgb(200,232,255)),LightEmission=.2,Size=K.num({{0,1.2},{1,.8}}),
				Transparency=K.num({{0,0},{1,.6}})},at)
			drops:Emit(10)
		end
		local ripples=TEX.ripple and K.new("ParticleEmitter",{Texture=TEX.ripple,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode=Enum.ParticleFlipbookMode.OneShot,Orientation=Enum.ParticleOrientation.VelocityPerpendicular,EmissionDirection=Enum.NormalId.Top,
			Rate=0,Lifetime=NumberRange.new(.9,1.1),Speed=NumberRange.new(.01,.01),Color=ColorSequence.new(rgb(205,232,255)),LightEmission=.15,
			Size=K.num({{0,1.5},{1,3.4}}),Transparency=K.num({{0,.25},{1,1}}),Rotation=NumberRange.new(0,360)},at)
		for k=1,math.floor((life-1)/.7) do
			task.delay(k*.7,function()
				if not holder.Parent then return end
				local a=rng:NextNumber(0,math.pi*2)
				local spot=Vector3.new(math.cos(a),0,math.sin(a))*radius*rng:NextNumber(0,.6)
				if ripples then
					at.Position=spot
					ripples:Emit(1)
				else
					K.shockRing(fx.folder,ground+spot+Vector3.new(0,.1,0),rgb(190,222,250),.4,2.6,.7)
				end
			end)
		end
		task.delay(math.max(0,life-.9),function()
			if not holder.Parent then return end
			for _,entry in patches do K.tween(entry.part,.9,{Transparency=1,Size=entry.size*Vector3.new(.8,1,.8)}) end
		end)
		Debris:AddItem(holder,life+.2)
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
	elseif style=="jutsuclash" and impact.phase=="grind" then
		grind(fx,impact,folder)
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
