-- Bodies that are not fighters (Server/Bodies: Naruto's shadow clones), drawn
-- from the snapshot's `bodies`. A clone is a copy of its owner's own model
-- (rig and costume, so it looks exactly like him), anchored at its root,
-- carried on a smoothed track of the server positions and posed by the motion
-- engine like a fighter (its run, its jab, its side of a carried route, the
-- Rasengan it shapes). Copies are pooled per owner model; the puffs of smoke
-- come from the contact feed (Client/NarutoFX). Presentation only.
local Motion=require(script.Parent.VelmoraMotionEngine)
-- (06/11) Kakashi's ninken are dogs, not copies of him (Client/HoundFX).
local HoundFX=require(script.Parent.HoundFX)
local BodyViews={};BodyViews.__index=BodyViews
BodyViews.clock=os.clock -- (headless tests drive time)
-- A body never lags its server position by more than this before it snaps.
local SNAP=12
-- (06/11) Copies kept per owner: Naruto's crowd is ten at once. A fighter
-- whose kit makes a crowd (Fighters[id].Bodies.clone.Crowd) has its copies
-- made ahead, one a frame, so the crowd does not stall the frame it appears.
BodyViews.POOL=12
local Fighters=nil
local function crowdSize(fighterId)
	if not Fighters then
		local ok,mod=pcall(function() return require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters) end)
		Fighters=if ok then mod else {}
	end
	local def=Fighters[fighterId or ""]
	local tune=def and def.Bodies and def.Bodies.clone
	return tune and tune.Crowd or 0
end
function BodyViews.new()
	local folder=Instance.new("Folder");folder.Name="NinjaDuelBodies";folder.Parent=workspace
	return setmetatable({folder=folder,views={},pools={},epoch=nil},BodyViews)
end
-- A copy of `source` that can be posed but never collides, never blocks the
-- camera, carries no Humanoid, script, sound, light or held weapon.
function BodyViews.copy(source)
	local archivable=source.Archivable
	source.Archivable=true
	local ok,copy=pcall(function() return source:Clone() end)
	source.Archivable=archivable
	if not ok or not copy then return nil end
	copy.Name="ShadowClone"
	for _,d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide=false;d.CanQuery=false;d.CanTouch=false;d.Massless=true;d.Anchored=false
			d.LocalTransparencyModifier=0
			-- The quiet tell (the deception is where blows come from, not which
			-- body is real): a chakra copy casts no shadow, the real one does.
			d.CastShadow=false
		elseif d:IsA("Humanoid") or d:IsA("Sound") or d:IsA("BaseScript") or d:IsA("Highlight") or d:IsA("ParticleEmitter")
			or d:IsA("Trail") or d:IsA("Light") or d:IsA("Beam") then
			d:Destroy()
		elseif d:IsA("Model") and d.Parent and d.Parent:IsA("BasePart") then
			-- A weapon held in a hand (Motion.weapon) stays with its owner.
			d:Destroy()
		end
	end
	local root=copy:FindFirstChild("HumanoidRootPart")
	if not root then copy:Destroy();return nil end
	root.Anchored=true;copy.PrimaryPart=root
	-- (Audit 04/11) a copy made in the Nine-Tails cloak kept its red slit eyes
	-- (and a blink) for the rest of the round: the copy's face starts calm.
	pcall(function()
		local Face=require(game:GetService("ReplicatedStorage").NinjaDuel.Face)
		local face=Face.find(copy)
		if face then Face.tint(face,nil);Face.set(face,"calm") end
		for _,d in copy:GetDescendants() do
			if d.Name=="Iris" and d:IsA("BasePart") then
				local color,material=d:GetAttribute("NDIrisColor"),d:GetAttribute("NDIrisMaterial")
				if typeof(color)=="Color3" then d.Color=color end
				if type(material)=="string" and Enum.Material[material] then d.Material=Enum.Material[material] end
			end
		end
	end)
	return copy
end
function BodyViews:take(owner)
	local pool=self.pools[owner]
	local model=pool and table.remove(pool)
	if not model then model=BodyViews.copy(owner) end
	if not model then return nil end
	Motion.reset(model)
	model.Parent=self.folder
	return model
end
function BodyViews:release(view)
	local model=view.model
	if view.hound then model:Destroy();return end
	model.Parent=nil
	if view.fadeSet and view.fadeSet~=0 then for _,part in view.parts or BodyViews.parts(model) do part.LocalTransparencyModifier=0 end end
	local pool=self.pools[view.owner] or {}
	self.pools[view.owner]=pool
	if #pool<BodyViews.POOL then table.insert(pool,model) else model:Destroy() end
end
function BodyViews:reset()
	for id,view in self.views do view.model:Destroy();self.views[id]=nil end
	for owner,pool in self.pools do for _,model in pool do model:Destroy() end;self.pools[owner]=nil end
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
-- One body this frame: the track, then the pose.
function BodyViews:step(view,entry,dt)
	local now=BodyViews.clock()
	if view.entry~=entry then
		view.entry=entry;view.seenAt=now
		-- A flicker across the stage (Bodies.warp) snaps instead of sliding.
		if entry.warp~=view.warp then view.warp=entry.warp;view.pos=entry.position end
	end
	local velocity=entry.velocity or Vector3.zero
	-- A short lead only: a clone dashing to its strike (90 studs/s) stops dead,
	-- and a long extrapolation would carry it past the spot between packets.
	local ahead=entry.position+velocity*math.min(.05,now-(view.seenAt or now))
	if (ahead-view.pos).Magnitude>SNAP then view.pos=ahead
	else view.pos=view.pos:Lerp(ahead,1-math.exp(-18*math.max(dt,1/240))) end
	local look=flat(entry.look or Vector3.new(0,0,-1))
	look=if look.Magnitude>.05 then look.Unit else Vector3.new(0,0,-1)
	local drawn=view.look or look
	drawn=drawn:Lerp(look,1-math.exp(-14*math.max(dt,1/240)))
	view.look=if drawn.Magnitude>.05 then drawn.Unit else look
	if view.hound then HoundFX.pose(view,entry,dt);return end
	view.model:PivotTo(CFrame.lookAt(view.pos,view.pos+view.look))
	-- Its own clock: an action animates from the frame it was first seen.
	local clock=view.clock
	local serial=entry.actionSerial or 0
	if serial~=clock.serial then clock.serial=serial;clock.at=now-math.clamp(entry.actionElapsed or 0,0,.12) end
	if entry.cast~=clock.cast then clock.cast=entry.cast;clock.castAt=now end
	local acting=entry.action~=nil and (entry.state=="Startup" or entry.state=="Active" or entry.state=="Recovery")
	local visual={fighterId=entry.fighterId,health=1,airborne=entry.airborne==true,velocity=velocity,speed=flat(velocity).Magnitude,
		state=if acting then entry.state elseif entry.cast then "TechniqueChannel" else "Neutral",
		attackName=if acting then entry.action else nil,attackVariant=if acting then entry.variant else nil,attackSerial=serial,
		castId=if acting then nil else entry.cast,castElapsed=now-(clock.castAt or now)}
	view.phase=Motion.present(view.model,visual,{attackElapsed=if acting then now-clock.at else 0,reactionElapsed=0},dt)
	self:fade(view,dt)
end
-- (06/11) A crowd round the opponent stands between the lens and the player's
-- own body: a clone in that line, or right against the lens, fades to a ghost
-- (as an obstacle near the camera would) so the player still sees himself
-- and the fight.
-- (14/11, CM QA A6: « le mur de clones cache tout ») In a fight seen from
-- outside (a film, a spectator), the crowd round the struck body hid it: no
-- one saw who hit whom. Every fighter the clone does not belong to is kept in
-- sight the same way: a clone in the line to him, or pressed against him,
-- fades to a ghost.
BodyViews.FADE=.7
BodyViews.CLOSE=3.2 -- studs: a clone this close to the body it strikes fades
function BodyViews:fade(view,dt)
	local camera=workspace.CurrentCamera
	local want=0
	if camera and camera.CFrame and (self.targets or self.focus) then
		local lens=camera.CFrame.Position
		local root=view.model.PrimaryPart
		local p=if root then root.Position else view.pos
		if (p-lens).Magnitude<4 then want=BodyViews.FADE end
		for _,target in self.targets or {self.focus} do
			if want>0 then break end
			local at=if typeof(target)=="Vector3" then target else target.pos
			local owner=if typeof(target)=="table" then target.model else nil
			local line=at-lens
			local length=line.Magnitude
			if length>.5 then
				local along=(p-lens):Dot(line/length)
				local off=((p-lens)-line/length*along).Magnitude
				if along>0 and along<length-1 and off<2.6 then want=BodyViews.FADE end
			end
			if owner and owner~=view.owner and Vector3.new(p.X-at.X,0,p.Z-at.Z).Magnitude<BodyViews.CLOSE then want=BodyViews.FADE end
		end
	end
	local now=view.fadeNow or 0
	now+=(want-now)*(1-math.exp(-14*math.max(dt,1/240)))
	if want==0 and now<.02 then now=0 end
	view.fadeNow=now
	local set=view.fadeSet or 0
	if math.abs(now-set)<.02 and not (now==0 and set~=0) then return end
	view.fadeSet=now
	view.parts=view.parts or BodyViews.parts(view.model)
	for _,part in view.parts do part.LocalTransparencyModifier=now end
end
function BodyViews.parts(model)
	local list={}
	for _,d in model:GetDescendants() do if d:IsA("BasePart") then table.insert(list,d) end end
	return list
end
-- A puppet (Sasori's marionette) is a copy of its owner turned to wood: the
-- body parts lacquered brown, the costume and hair hidden, a pale mask, and
-- glowing chakra threads from the owner's fingers to its wrists.
local BODY={Head=true,UpperTorso=true,LowerTorso=true,LeftUpperArm=true,RightUpperArm=true,LeftLowerArm=true,RightLowerArm=true,
	LeftHand=true,RightHand=true,LeftUpperLeg=true,RightUpperLeg=true,LeftLowerLeg=true,RightLowerLeg=true,LeftFoot=true,RightFoot=true}
function BodyViews.puppetize(model,owner)
	if model:GetAttribute("Puppet") then return end
	model:SetAttribute("Puppet",true)
	model.Name="Puppet"
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then
			if BODY[d.Name] then d.Color=Color3.fromRGB(150,110,74);d.Material=Enum.Material.Wood
			else d.Transparency=1 end
		elseif d:IsA("Decal") then d.Transparency=1 end
	end
	local head=model:FindFirstChild("Head")
	if head then
		local mask=Instance.new("Part");mask.Name="PuppetMask";mask.Size=Vector3.new(1.1,1.2,.1);mask.Color=Color3.fromRGB(236,226,206)
		mask.CanCollide=false;mask.CanQuery=false;mask.Massless=true;mask.CFrame=head.CFrame*CFrame.new(0,0,-.62);mask.Parent=model
		local weld=Instance.new("WeldConstraint");weld.Part0=head;weld.Part1=mask;weld.Parent=mask
	end
	-- Threads: owner's hands to the puppet's wrists.
	for _,side in {"Left","Right"} do
		local from=owner:FindFirstChild(side.."Hand");local to=model:FindFirstChild(side.."Hand")
		if from and to then
			local a0=Instance.new("Attachment");a0.Name="PuppetThread";a0.Parent=from
			local a1=Instance.new("Attachment");a1.Parent=to
			local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.06;beam.Width1=.06
			beam.Color=ColorSequence.new(Color3.fromRGB(140,200,255));beam.LightEmission=1;beam.Transparency=NumberSequence.new(.35);beam.FaceCamera=true
			beam.Parent=to
		end
	end
end
-- Every frame (Presentation:update): draw the live bodies, put away the rest.
function BodyViews:update(data,dt,folder)
	if not data or data.phase~="Duel" then
		for id,view in self.views do self:release(view);self.views[id]=nil end
		return
	end
	if data.epoch~=self.epoch then self:reset();self.epoch=data.epoch end
	-- The player's own body (what the lens must keep in sight).
	local mine=data.human and folder and folder:FindFirstChild(data.human.id or "")
	local mineRoot=mine and mine:FindFirstChild("HumanoidRootPart")
	self.focus=if mineRoot then mineRoot.Position else nil
	-- Every fighter's body (A6): the clones of one never hide the other.
	local targets={}
	for _,actor in {data.human,data.bot} do
		local model=actor and folder and folder:FindFirstChild(actor.id or "")
		local root=model and model:FindFirstChild("HumanoidRootPart")
		if root then table.insert(targets,{model=model,pos=root.Position}) end
	end
	self.targets=if #targets>0 then targets else nil
	-- Copies made ahead for a crowd (one a frame, out of the workspace).
	for _,actor in {data.human,data.bot} do
		local want=actor and crowdSize(actor.fighterId) or 0
		local owner=want>0 and folder and folder:FindFirstChild(actor.id or "")
		if owner then
			local pool=self.pools[owner] or {}
			self.pools[owner]=pool
			local live=0
			for _,view in self.views do if view.owner==owner then live+=1 end end
			if #pool+live<math.min(want,BodyViews.POOL) then
				local model=BodyViews.copy(owner)
				if model then model.Parent=nil;table.insert(pool,model) end
			end
		end
	end
	local live={}
	for _,entry in data.bodies or {} do
		live[entry.id]=true
		local view=self.views[entry.id]
		if not view and entry.kind=="hound" then
			local model,rig=HoundFX.build(entry.slot or entry.id)
			model.Parent=self.folder
			view={model=model,rig=rig,hound=true,pos=entry.position,look=nil,warp=entry.warp,clock={}}
			self.views[entry.id]=view
		end
		if not view then
			local owner=folder and folder:FindFirstChild(entry.owner or "")
			local model=owner and self:take(owner)
			if model and entry.kind=="puppet" then BodyViews.puppetize(model,owner) end
			if model then
				view={model=model,owner=owner,pos=entry.position,look=nil,warp=entry.warp,clock={}}
				self.views[entry.id]=view
			end
		end
		if view then self:step(view,entry,dt) end
	end
	for id,view in self.views do
		if not live[id] then self:release(view);self.views[id]=nil end
	end
end
return BodyViews
