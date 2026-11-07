-- (06/11, « nous, pour le Byakugan, on voit des 1, 2, 3 pop sur le truc,
-- c'est super moche ; lui, on voit vraiment les vaisseaux du chakra ») The
-- Byakugan's sight, drawn for the eyes that have it (Shared/Sight decides
-- when: Neji's Perception, a Byakugan awakening).
--
-- The world loses half its colour; the opponent's chakra network appears over his
-- body: two veins along the spine, each arm and each leg, chakra pulsing
-- along them from the core outward. What it tells:
--   how much chakra he has   the veins burn bright and the pulses run fast
--                            when he is full; they dim and slow as he empties;
--   the points closed in it  Neji's eight points are nodes on the network: a
--                            closed one goes dark and so does the channel it
--                            feeds (the arm behind a shoulder, the leg behind
--                            a hip, the spine behind the heart);
--   a jutsu coming           while he moulds chakra (seals, a channel, a
--                            loaded strike) the network flares and the pulses
--                            rush into the hands;
--   where he is              his outline shows through walls and trees;
--   what is real             a clone or an image has no network: only the
--                            real body lights up.
-- Only the opponent's body is read (data.bot). In Studio, workspace attribute
-- NDSight = "byakugan" opens it for filming.
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Sight=require(game:GetService("ReplicatedStorage").NinjaDuel.Sight)

local ByakuganFX={}
local K,FX

local VEIN=Color3.fromRGB(40,110,255)
local VEIN_CORE=Color3.fromRGB(150,205,255)
local VEIN_BRIGHT=Color3.fromRGB(80,160,255)
local DOTS=10
local CLOSED=Color3.fromRGB(16,20,36)
local PULSES=16

-- The network: chains of nodes, each node a part of the rig and a point on
-- it (in fractions of the part's size; -Z is the front). Chakra runs from the
-- first node of a chain to its last.
local CHAINS={
	spine={{"LowerTorso",0,-.4,0},{"LowerTorso",0,.42,-.1},{"UpperTorso",0,-.42,-.15},{"UpperTorso",-.08,.1,-.3},{"UpperTorso",0,.46,-.1},{"Head",0,-.42,0},{"Head",0,.1,-.1}},
	armL={{"UpperTorso",-.42,.36,0},{"LeftUpperArm",0,.42,0},{"LeftUpperArm",0,-.42,0},{"LeftLowerArm",0,.42,0},{"LeftLowerArm",0,-.42,0},{"LeftHand",0,-.1,0}},
	armR={{"UpperTorso",.42,.36,0},{"RightUpperArm",0,.42,0},{"RightUpperArm",0,-.42,0},{"RightLowerArm",0,.42,0},{"RightLowerArm",0,-.42,0},{"RightHand",0,-.1,0}},
	legL={{"LowerTorso",-.26,-.36,0},{"LeftUpperLeg",0,.42,0},{"LeftUpperLeg",0,-.42,0},{"LeftLowerLeg",0,.42,0},{"LeftLowerLeg",0,-.42,0},{"LeftFoot",0,0,-.25}},
	legR={{"LowerTorso",.26,-.36,0},{"RightUpperLeg",0,.42,0},{"RightUpperLeg",0,-.42,0},{"RightLowerLeg",0,.42,0},{"RightLowerLeg",0,-.42,0},{"RightFoot",0,0,-.25}},
}
-- Which channel each of Neji's points (FX.TENKETSU) feeds.
local FEEDS={throat="spine",heart="spine",solar="spine",navel="spine",leftShoulder="armL",rightShoulder="armR",leftHip="legL",rightHip="legR"}

local S=nil

local function forced()
	if not RunService:IsStudio() then return nil end
	local value=workspace:GetAttribute("NDSight")
	return if type(value)=="string" and value~="" then value else nil
end

-- --------------------------------------------------------------- the world
local function grade(on)
	local ok,Lighting=pcall(function() return game:GetService("Lighting") end)
	if not ok or not Lighting then return end
	local cc=Lighting:FindFirstChild("ByakuganSight")
	if on and not cc then
		cc=Instance.new("ColorCorrectionEffect");cc.Name="ByakuganSight";cc.Parent=Lighting
	end
	if not cc then return end
	-- Half the colour out of the world (the grade tints the veins too: more
	-- would turn them grey), a cool cast, a touch darker.
	local goal=if on then {Saturation=-.25,Contrast=.1,Brightness=-.05,TintColor=Color3.fromRGB(226,232,255)} else {Saturation=0,Contrast=0,Brightness=0,TintColor=Color3.new(1,1,1)}
	TweenService:Create(cc,TweenInfo.new(if on then .25 else .35),goal):Play()
	if not on then task.delay(.4,function() if cc.Parent and cc.Saturation>-.05 then cc:Destroy() end end) end
end

-- ----------------------------------------------------------- the network
local function build(fx,model)
	local holder=Instance.new("Folder");holder.Name="ByakuganNetwork";holder.Parent=fx.folder
	local net={holder=holder,chains={},beams={},nodes={},pulses={},attachments={}}
	for name,chain in CHAINS do
		local list={}
		for i,spec in chain do
			local part=model:FindFirstChild(spec[1])
			if not part or not part:IsA("BasePart") then list=nil;break end
			local size=part.Size
			local main=Instance.new("Attachment");main.Name="ChakraNode";main.Position=Vector3.new(spec[2]*size.X,spec[3]*size.Y,spec[4]*size.Z);main.Parent=part
			-- A second vein beside the first (the network is a mesh, not a wire).
			local side=Instance.new("Attachment");side.Name="ChakraNode";side.Position=main.Position+Vector3.new(.14,0,.1);side.Parent=part
			table.insert(net.attachments,main);table.insert(net.attachments,side)
			list[i]={main=main,side=side}
		end
		if list then
			net.chains[name]=list
			local beams={}
			for i=1,#list-1 do
				for k,key in {"main","side"} do
					local beam=Instance.new("Beam")
					beam.Attachment0=list[i][key];beam.Attachment1=list[i+1][key]
					beam.FaceCamera=true;beam.Segments=8;beam.LightEmission=.5;beam.LightInfluence=0
					beam.Width0=if k==1 then .17 else .1;beam.Width1=beam.Width0
					beam.CurveSize0=(if k==1 then .18 else -.22)*(if i%2==0 then 1 else -1);beam.CurveSize1=-beam.CurveSize0*.6
					beam.Color=ColorSequence.new(VEIN);beam.Transparency=NumberSequence.new(.2)
					beam.Parent=holder
					table.insert(beams,{beam=beam,main=k==1})
				end
			end
			net.beams[name]=beams
		end
	end
	-- Neji's eight points, as nodes of the network.
	for id in FX.TENKETSU do
		local node=K.block(holder,Vector3.one*.24,CFrame.new(),VEIN_CORE,Enum.Material.Neon)
		node.Shape=Enum.PartType.Ball;node.Name="Tenketsu";node.Transparency=1
		net.nodes[id]=node
	end
	-- The dotted look of a network seen through the skin: small beads along
	-- every channel, fixed on the body.
	net.dots={}
	for name in net.chains do
		for k=1,DOTS do
			local d=K.block(holder,Vector3.one*.13,CFrame.new(),VEIN,Enum.Material.Neon)
			d.Shape=Enum.PartType.Ball;d.Name="ChakraDot";d.Transparency=1
			table.insert(net.dots,{part=d,chain=name,along=(k-.5)/DOTS})
		end
	end
	for i=1,PULSES do
		local p=K.block(holder,Vector3.one*.22,CFrame.new(),VEIN_CORE,Enum.Material.Neon)
		p.Shape=Enum.PartType.Ball;p.Name="ChakraPulse";p.Transparency=1
		local names={"spine","armL","armR","legL","legR"}
		net.pulses[i]={part=p,chain=names[(i-1)%#names+1],along=(i*.37)%1}
	end
	-- His outline through walls and trees.
	local outline=Instance.new("Highlight");outline.Name="ByakuganOutline";outline.Adornee=model
	outline.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;outline.FillColor=VEIN;outline.FillTransparency=1
	-- (An always-on-top fill would wash out the veins inside the body.)
	outline.OutlineColor=VEIN_CORE;outline.OutlineTransparency=.15;outline.Parent=holder
	net.outline=outline
	-- The body itself turns to glass: the network runs inside it, and an
	-- opaque body would hide it.
	net.glass={}
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" and d.Transparency<.9 then table.insert(net.glass,d) end
	end
	return net
end

-- A point along a chain (0 = its first node, 1 = its last), on the bodies'
-- current pose.
local function world(a) return a.Parent.CFrame*a.Position end
local function along(chain,t)
	local count=#chain
	local x=math.clamp(t,0,1)*(count-1)
	local i=math.min(count-1,math.floor(x)+1)
	local f=x-(i-1)
	return world(chain[i].main):Lerp(world(chain[i+1].main),f)
end
local function move(parts,cfs)
	if #parts==0 then return end
	if workspace.BulkMoveTo then workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
	else for i,p in parts do p.CFrame=cfs[i] end end
end

local function release()
	if not S then return end
	if S.net then
		S.net.holder:Destroy()
		for _,a in S.net.attachments do a:Destroy() end
	end
	for dot in S.dots or {} do if dot.Parent then dot.LocalTransparencyModifier=0 end end
	for _,part in (S.net and S.net.glass) or {} do if part.Parent then part.LocalTransparencyModifier=0 end end
	if S.graded then grade(false) end
	S=nil
end

local function draw(fx,actor,dt)
	local net=S.net
	local chakra=math.clamp((actor.chakra or 0)/math.max(1,actor.maxChakra or 100),0,1)
	local moulding=actor.state=="TechniqueChannel" or actor.sealing~=nil or actor.chakraLoad~=nil or actor.infused~=nil
	-- Closed points: which channels they cut.
	local closed,cut={},{}
	for _,id in actor.tenketsuPoints or {} do closed[id]=true;cut[FEEDS[id] or ""]=true end
	local severe=actor.tenketsuSevere==true
	local base=.05+(1-chakra)*.5
	local flare=if moulding then 1.6 else 1
	local t=os.clock()
	for name,beams in net.beams do
		local dead=cut[name] or severe
		for _,entry in beams do
			local beam=entry.beam
			local flicker=.06*math.sin(t*9+(beam.CurveSize0*20))
			beam.Transparency=NumberSequence.new(math.clamp((if dead then .8 else base)+flicker,0,.95))
			beam.Color=ColorSequence.new(if dead then CLOSED elseif moulding then VEIN_CORE elseif entry.main then VEIN_BRIGHT else VEIN)
			local w=(if entry.main then .17 else .1)*flare
			beam.Width0=w;beam.Width1=w
		end
	end
	-- The points: bright and open, or dark and shut.
	local parts,cfs={},{}
	for id,node in net.nodes do
		local at=FX.tenketsuWorld(S.model,id)
		if at then
			table.insert(parts,node);table.insert(cfs,CFrame.new(at))
			node.Color=if closed[id] then CLOSED else VEIN_CORE
			node.Size=Vector3.one*(if closed[id] then .36 else .28)
			node.Transparency=if closed[id] then .05 else .2+.15*math.sin(t*6)
		else
			node.Transparency=1
		end
	end
	-- The flow: faster and fuller with more chakra, a rush to the hands while
	-- he moulds a jutsu; none through a channel that is cut.
	local live=math.floor(PULSES*(.25+.75*chakra)+.5)
	local speed=(.35+.9*chakra)*(if moulding then 2.4 else 1)
	for i,pulse in net.pulses do
		local chain=net.chains[pulse.chain]
		local on=chain~=nil and i<=live and not cut[pulse.chain] and not severe
		if on then
			pulse.along=(pulse.along+dt*speed)%1
			table.insert(parts,pulse.part);table.insert(cfs,CFrame.new(along(chain,pulse.along)))
			pulse.part.Transparency=.1
		else
			pulse.part.Transparency=1
		end
	end
	for _,dot in net.dots do
		table.insert(parts,dot.part);table.insert(cfs,CFrame.new(along(net.chains[dot.chain],dot.along)))
		local dead=cut[dot.chain] or severe
		dot.part.Color=if dead then CLOSED else VEIN
		dot.part.Transparency=if dead then .35 else .15
	end
	move(parts,cfs)
	-- (A body the speed has turned to ink stays ink: the Byakugan sees chakra,
	-- it does not read speed; that is the Sharingan's.)
	for _,part in net.glass do if part.LocalTransparencyModifier<.99 then part.LocalTransparencyModifier=.72 end end
	-- Effects' own markers of the closed points would sit on top of ours.
	local aura=fx.auras and fx.auras[S.model]
	S.dots=S.dots or {}
	for _,entry in (aura and aura.points) or {} do
		if entry.dot and entry.dot.Parent then entry.dot.LocalTransparencyModifier=1;S.dots[entry.dot]=true end
	end
end

local function step(fx,data,dt,folder)
	local mode=forced()
	local duel=data and data.phase=="Duel" and mode~="off"
	local target=duel and data.bot or nil
	local viewer=duel and data.human or nil
	local model=target and folder and folder:FindFirstChild(target.id or "")
	local open=model~=nil and (mode=="byakugan" or (mode==nil and Sight.viewChakraSight(viewer)))
	if not open then release();return end
	if S and (S.model~=model or S.fx~=fx or not S.net or not S.net.holder.Parent) then release() end
	if not S then
		S={model=model,fx=fx,net=build(fx,model),graded=true}
		grade(true)
		local root=model:FindFirstChild("HumanoidRootPart")
		if root and K.SOUND then pcall(function() K.sound(K.anchorPart(fx.folder,root.Position),K.SOUND.whoosh,.3,.7) end) end
	end
	draw(fx,target,dt)
end

function ByakuganFX.install(Effects,kit)
	K=kit;FX=Effects
	table.insert(Effects.layers,{name="Byakugan",step=step})
end
ByakuganFX.release=release
return ByakuganFX
