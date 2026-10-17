-- Bodies that are not fighters (Server/Bodies: Naruto's shadow clones), drawn
-- from the snapshot's `bodies`. A clone is a copy of its owner's own model
-- (rig and costume, so it looks exactly like him), anchored at its root,
-- carried on a smoothed track of the server positions and posed by the motion
-- engine like a fighter (its run, its jab, its side of a carried route, the
-- Rasengan it shapes). Copies are pooled per owner model; the puffs of smoke
-- come from the contact feed (Client/NarutoFX). Presentation only.
local Motion=require(script.Parent.VelmoraMotionEngine)
local BodyViews={};BodyViews.__index=BodyViews
BodyViews.clock=os.clock -- (headless tests drive time)
-- A body never lags its server position by more than this before it snaps.
local SNAP=12
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
	model.Parent=nil
	local pool=self.pools[view.owner] or {}
	self.pools[view.owner]=pool
	if #pool<4 then table.insert(pool,model) else model:Destroy() end
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
	local ahead=entry.position+velocity*math.min(.12,now-(view.seenAt or now))
	if (ahead-view.pos).Magnitude>SNAP then view.pos=ahead
	else view.pos=view.pos:Lerp(ahead,1-math.exp(-18*math.max(dt,1/240))) end
	local look=flat(entry.look or Vector3.new(0,0,-1))
	look=if look.Magnitude>.05 then look.Unit else Vector3.new(0,0,-1)
	local drawn=view.look or look
	drawn=drawn:Lerp(look,1-math.exp(-14*math.max(dt,1/240)))
	view.look=if drawn.Magnitude>.05 then drawn.Unit else look
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
end
-- Every frame (Presentation:update): draw the live bodies, put away the rest.
function BodyViews:update(data,dt,folder)
	if not data or data.phase~="Duel" then
		for id,view in self.views do self:release(view);self.views[id]=nil end
		return
	end
	if data.epoch~=self.epoch then self:reset();self.epoch=data.epoch end
	local live={}
	for _,entry in data.bodies or {} do
		live[entry.id]=true
		local view=self.views[entry.id]
		if not view then
			local owner=folder and folder:FindFirstChild(entry.owner or "")
			local model=owner and self:take(owner)
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
