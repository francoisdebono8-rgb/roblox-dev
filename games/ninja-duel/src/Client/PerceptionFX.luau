-- (06/11, « leur Sharingan sert à quelque chose ; un truc qui va trop vite,
-- on le voit avec le Sharingan ») What the viewer's eyes make of a fighter
-- under a speed jutsu (Shared/Sight decides who is fast and who reads it).
--
--   Ordinary eyes: the fast body is not drawn at all while it moves or
--   strikes. In its place, a scrawl of black ink lines that boils twenty
--   times a second around where it is and where it just was. The wind-up of
--   a strike is invisible: that is the point, the guard has to be guessed.
--
--   Sharingan eyes: the body stays sharp; its last positions trail behind it
--   as translucent afterimages (crimson to violet), and the strike to come
--   shows as a red ghost where it will land, from its wind-up.
--
-- Only the opponent's body is read this way (data.bot); a viewer sees his own
-- body as usual. Cosmetic on this client only: the server rule is the AI's
-- (Server/AI reads Sight too). In Studio, workspace attribute NDSight forces
-- the eyes for filming: "normal", "sharingan" or "off".
local RunService=game:GetService("RunService")
local Sight=require(game:GetService("ReplicatedStorage").NinjaDuel.Sight)

local PerceptionFX={}
local K

local INK=Color3.fromRGB(0,0,0)
local NEAR=Color3.fromRGB(128,24,38)
local FAR=Color3.fromRGB(58,52,112)
local FORESIGHT=Color3.fromRGB(176,18,30)
local STROKES=56
local BOIL=1/20
local GHOSTS=4
local SPACING=.075
local HISTORY=.45
local MAX_GHOST_PARTS=26

-- The one body being read, and everything drawn for it.
local S=nil

local function forced()
	if not RunService:IsStudio() then return nil end
	local value=workspace:GetAttribute("NDSight")
	return if type(value)=="string" and value~="" then value else nil
end

-- Hide (1) or restore (0) one drawable piece of the body. The face and the
-- emblems are SurfaceGuis, which a part's transparency does not hide: they
-- are switched off and given back their own setting.
local guiWas=setmetatable({},{__mode="k"})
local function setLocal(object,value)
	if object:IsA("LayerCollector") then
		if value>0 then
			if guiWas[object]==nil then guiWas[object]=object.Enabled end
			object.Enabled=false
		elseif guiWas[object]~=nil then
			object.Enabled=guiWas[object];guiWas[object]=nil
		end
		return
	end
	pcall(function() object.LocalTransparencyModifier=value end)
end

-- The body's drawable pieces: parts (the root excluded) and what is drawn on
-- or from them (face decals, aura emitters, trails, beams).
local function collect(model)
	local parts,others={},{}
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name~="HumanoidRootPart" then table.insert(parts,d) end
		elseif d:IsA("Decal") or d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			table.insert(others,d)
		end
	end
	return parts,others
end
-- The pieces an afterimage copies: the solid ones that make the silhouette.
local function silhouette(parts)
	local list={}
	for _,p in parts do
		if p.Transparency<.85 and p.Size.Magnitude>.35 then table.insert(list,p) end
	end
	table.sort(list,function(a,b) return a.Size.Magnitude>b.Size.Magnitude end)
	while #list>MAX_GHOST_PARTS do table.remove(list) end
	return list
end

local function release()
	if not S then return end
	for object in S.hidden do if object.Parent then setLocal(object,0) end end
	if S.holder then S.holder:Destroy() end
	S=nil
end

local function holderOf(fx)
	if S.holder and S.holder.Parent then return S.holder end
	local holder=Instance.new("Folder");holder.Name="Sight";holder.Parent=fx.folder
	S.holder=holder;S.strokes=nil;S.ghosts=nil;S.foresight=nil
	return holder
end

-- ---------------------------------------------------------------- the body
local function hideBody()
	for _,list in {S.parts,S.others} do
		for _,object in list do
			if not S.hidden[object] and object.Parent then S.hidden[object]=true end
			setLocal(object,1)
		end
	end
end
local function showBody()
	for object in S.hidden do if object.Parent then setLocal(object,0) end end
	table.clear(S.hidden)
end

-- --------------------------------------------------------------- the ink
local function strokes(fx)
	local holder=holderOf(fx)
	if S.strokes then return S.strokes end
	local list={}
	for i=1,STROKES do
		-- Neon black: pure ink whatever the light (a lit plastic stick turns grey).
		local p=K.block(holder,Vector3.new(.08,.08,1),CFrame.new(),INK,Enum.Material.Neon)
		p.Name="Ink";p.Transparency=1
		list[i]=p
	end
	S.strokes=list
	return list
end
local function hideInk()
	for _,p in S.strokes or {} do p.Transparency=1 end
end
local function sample(age)
	local want=os.clock()-age
	local best=nil
	for i=#S.history,1,-1 do
		best=S.history[i]
		if best.t<=want then break end
	end
	return best
end
local function drawInk(fx,velocity,dt)
	local list=strokes(fx)
	S.boil=(S.boil or 0)-dt
	if S.boil>0 then return end
	S.boil=BOIL
	local rng=S.rng
	local flat=Vector3.new(velocity.X,0,velocity.Z)
	local moving=flat.Magnitude>6
	local along=if moving then flat.Unit else Vector3.xAxis
	local n=#S.ghostSrc
	if n==0 then hideInk();return end
	for i,p in list do
		-- Two in three on the body as it is, the rest on where it just was.
		local past=i>STROKES*.74
		local frame=if past then sample(.04+rng:NextNumber()*.18) else nil
		-- Bigger pieces of the body get more lines (the torso, not a lock of hair).
		local roll,index=rng:NextNumber()*S.weight[n],n
		for k=1,n do if roll<=S.weight[k] then index=k;break end end
		local src=S.ghostSrc[index]
		local cf=if frame and frame.cf[index] then frame.cf[index] else src.CFrame
		local size=src.Size
		local center=cf*Vector3.new((rng:NextNumber()-.5)*size.X,(rng:NextNumber()-.5)*size.Y,(rng:NextNumber()-.5)*size.Z)
		-- Mostly upright hatching (a pen scrawling the body over and over),
		-- some lines dragged along the motion.
		local dir
		if moving and rng:NextNumber()<.3 then
			dir=(along+Vector3.new(0,(rng:NextNumber()-.5)*.5,0)).Unit
		else
			dir=CFrame.Angles((rng:NextNumber()-.5)*.55,rng:NextNumber()*math.pi*2,(rng:NextNumber()-.5)*.55):VectorToWorldSpace(Vector3.yAxis)
		end
		local length=(if past then .5 else .7)+rng:NextNumber()*(if past then 1.2 else 1.7)
		local thick=(if past then .04 else .05)+rng:NextNumber()*.06
		p.Size=Vector3.new(thick,thick,length)
		p.CFrame=CFrame.lookAt(center,center+dir)
		p.Transparency=if past then .35+rng:NextNumber()*.35 else rng:NextNumber()*.15
	end
end

-- ------------------------------------------------------------ afterimages
local function ghost(fx,color)
	local holder=holderOf(fx)
	local copy={}
	for i,src in S.ghostSrc do
		local archivable=src.Archivable
		src.Archivable=true
		local ok,g=pcall(function() return src:Clone() end)
		src.Archivable=archivable
		if ok and g then
			for _,child in g:GetChildren() do
				if child:IsA("SpecialMesh") then child.TextureId=""
				elseif not child:IsA("DataModelMesh") then child:Destroy() end
			end
			g.Name="Afterimage";g.Anchored=true;g.CanCollide=false;g.CanQuery=false;g.CanTouch=false;g.CastShadow=false;g.Massless=true
			g.Material=Enum.Material.SmoothPlastic;g.Reflectance=0;g.Color=color;g.Transparency=1;g.LocalTransparencyModifier=0
			if g:IsA("MeshPart") then pcall(function() g.TextureID="" end) end
			g.Parent=holder
			copy[i]=g
		end
	end
	return copy
end
local function ghosts(fx)
	holderOf(fx)
	if S.ghosts then return S.ghosts end
	local list={}
	for k=1,GHOSTS do list[k]=ghost(fx,NEAR:Lerp(FAR,(k-1)/math.max(1,GHOSTS-1))) end
	S.ghosts=list
	S.foresight=ghost(fx,FORESIGHT)
	return list
end
local function place(copy,frame,offset,transparency)
	local parts,cfs={},{}
	for i,g in copy do
		local cf=frame and frame.cf[i] or S.ghostSrc[i].CFrame
		table.insert(parts,g);table.insert(cfs,if offset then offset*cf else cf)
		g.Transparency=transparency
	end
	if #parts==0 then return end
	if workspace.BulkMoveTo then workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
	else for i,p in parts do p.CFrame=cfs[i] end end
end
local function hideCopy(copy)
	for _,g in copy or {} do g.Transparency=1 end
end
local function hideGhosts()
	for _,copy in S.ghosts or {} do hideCopy(copy) end
	hideCopy(S.foresight)
end
local function drawGhosts(fx,actor,viewer)
	local list=ghosts(fx)
	local root=S.root
	local here=root and root.Position or Vector3.zero
	for k,copy in list do
		local frame=sample(k*SPACING)
		local there=frame and frame.root or here
		-- No afterimage stacked on a body that has not gone anywhere.
		if frame and (there-here).Magnitude>.8 then place(copy,frame,nil,.56+k*.09) else hideCopy(copy) end
	end
	-- The strike to come: from its wind-up, a red ghost where it will land.
	local striking=actor.state=="Startup" or actor.state=="TechniqueChannel"
	if striking and S.lastStrike~=actor.attackSerial then
		S.lastStrike=actor.attackSerial;S.foreAt=os.clock()
		local toward=Vector3.zero
		if viewer and viewer.position and root then
			local d=viewer.position-here;d=Vector3.new(d.X,0,d.Z)
			if d.Magnitude>.1 then toward=d.Unit*math.clamp(d.Magnitude-2.6,0,7) end
		end
		S.foreOffset=toward
	end
	local age=os.clock()-(S.foreAt or -9)
	if age<.45 and S.foreOffset then
		place(S.foresight,nil,CFrame.new(S.foreOffset),.35+math.max(0,age-.2)*2.4)
	else
		hideCopy(S.foresight)
	end
end

-- ------------------------------------------------------------------ frame
local function step(fx,data,dt,folder)
	local mode=forced()
	local duel=data and data.phase=="Duel" and mode~="off"
	local target=duel and data.bot or nil
	local model=target and folder and folder:FindFirstChild(target.id or "")
	if not model or not model.Parent then release();return end
	if not S or S.model~=model or S.fx~=fx then
		release()
		S={model=model,fx=fx,hidden={},history={},lastFast=-9,refresh=0,rng=Random.new(),episode=false}
	end
	local now=os.clock()
	-- The pieces of the body (an awakening adds a cloak, a tail, steam).
	S.refresh-=dt
	if S.refresh<=0 or not S.parts then
		S.refresh=.4
		S.parts,S.others=collect(model)
		local src=silhouette(S.parts)
		if not S.ghostSrc or #src~=#S.ghostSrc then
			S.ghostSrc=src
			local total=0;S.weight={}
			for k,part in src do total+=part.Size.Magnitude;S.weight[k]=total end
			-- The afterimages copy these: rebuilt with them.
			if S.ghosts then for _,copy in S.ghosts do for _,g in copy do g:Destroy() end end;S.ghosts=nil end
			if S.foresight then for _,g in S.foresight do g:Destroy() end;S.foresight=nil end
			table.clear(S.history)
		end
		S.root=model:FindFirstChild("HumanoidRootPart")
	end
	-- Where the body was, a few tenths of a second back.
	local cfs={}
	for i,src in S.ghostSrc do cfs[i]=src.CFrame end
	table.insert(S.history,{t=now,cf=cfs,root=S.root and S.root.Position})
	while #S.history>2 and now-S.history[1].t>HISTORY do table.remove(S.history,1) end

	if Sight.viewUnreadable(target) then S.lastFast=now end
	local active=Sight.viewFast(target) and now-S.lastFast<=Sight.LINGER
	if not active then
		if S.episode then showBody();hideInk();hideGhosts();S.episode=false end
		return
	end
	local viewer=data.human
	local reads=if mode=="sharingan" then true elseif mode=="normal" then false else Sight.viewReads(viewer)
	if not S.episode or S.reads~=reads then
		S.episode=true;S.reads=reads
		-- The moment the eyes meet the speed: a glint in the reader's eyes,
		-- a dry rush of air for the others.
		local viewerModel=viewer and folder:FindFirstChild(viewer.id or "")
		if reads and viewerModel and fx.eyeGlint then pcall(fx.eyeGlint,fx.folder,viewerModel)
		elseif not reads and S.root then pcall(K.sound,K.anchorPart(fx.folder,S.root.Position),K.SOUND.whoosh,.35,1.6) end
	end
	local velocity=target.velocity or Vector3.zero
	if reads then
		showBody();hideInk()
		drawGhosts(fx,target,viewer)
	else
		hideGhosts()
		hideBody()
		drawInk(fx,velocity,dt)
	end
end

function PerceptionFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="Perception",step=step})
end
PerceptionFX.release=release
return PerceptionFX
