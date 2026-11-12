-- (Feel audit 07/11, need 4: « les jutsu de déplacement ») Minato's Lightning
-- Strike moves him 11-14 studs in ONE frame, Kakashi's Lightning Cut 18: on
-- the screen the body was here, then there, with a puff at each end and
-- nothing between (FamilyFX draws a family relocation as two puffs). The eye
-- has to be told where he went. This layer draws the path itself, before
-- FamilyFX sees the impact:
--   * the line he went along: a bright beam at chest height that is drawn
--     from the departure to the arrival (it is not there at once: it runs, in
--     .06 s, the speed of the jutsu made visible) and thins out behind him;
--     a scorch on the floor along the same line, slower to go;
--   * afterimages of his arrival pose strung back along the line (the body
--     seen at three or four instants of a move too fast to see), the nearest
--     to the arrival the brightest;
--   * Minato's: yellow, clean (one straight line, the Flying Thunder God);
--     Kakashi's: white-blue lightning, the line broken into a zigzag that
--     re-forks twice while it fades (it crackles), sparks where it lands -
--     drawn with LightningBoltFX (SamyBlue/Lightning-Beams, MIT, adapted).
-- The arrival pose is the clip's (Flashstep.LightningStrike.Arrive,
-- Copycat.LightningCut.Arrive, AuthoredClips50). No plain Neon parts (VFX
-- bible 06/11): beams on invisible anchors, ForceField afterimages.
-- Presentation only; every call is guarded (a failure costs this frame's
-- trail, never Effects).
local DashTrailFX={}
local K -- Effects' helpers (install)
DashTrailFX.KINDS={
	flash={core=Color3.fromRGB(255,250,214),edge=Color3.fromRGB(255,206,60),zig=0,ghosts=4,width=.55},
	lightning={core=Color3.fromRGB(240,248,255),edge=Color3.fromRGB(120,180,255),zig=.9,ghosts=3,width=.45},
}
DashTrailFX.RUN=.06   -- seconds for the line to reach the arrival
DashTrailFX.LIFE=.32  -- seconds the line lasts
DashTrailFX.MIN=3     -- studs: a shorter move has no trail
local Debris=game:GetService("Debris")
local Bolt=require(script.Parent.LightningBoltFX)
local function anchor(parent,position)
	local p=K.new("Part",{Name="TrailAnchor",Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,
		Transparency=1,Size=Vector3.new(.05,.05,.05),CFrame=CFrame.new(position)},parent)
	return p,K.new("Attachment",{},p)
end
local function seq(a,b) return NumberSequence.new({NumberSequenceKeypoint.new(0,a),NumberSequenceKeypoint.new(1,b)}) end
-- One beam from a to b (attachments), fading with the line.
local function beam(holder,a0,a1,color,width0,width1,transparency)
	return K.new("Beam",{Attachment0=a0,Attachment1=a1,Width0=width0,Width1=width1,FaceCamera=true,Segments=1,
		LightEmission=1,LightInfluence=0,Color=ColorSequence.new(color),Transparency=seq(transparency,transparency)},holder)
end
-- The points of the line: straight for Minato, a zigzag for Kakashi.
function DashTrailFX.points(from,to,zig,rng)
	local line=to-from
	local n=if zig>0 then math.max(4,math.floor(line.Magnitude/2.2)) else 1
	local side=line:Cross(Vector3.yAxis)
	side=if side.Magnitude>1e-3 then side.Unit else Vector3.xAxis
	local out={from}
	for i=1,n-1 do
		local u=i/n
		local j=zig*(rng:NextNumber()*2-1)
		table.insert(out,from+line*u+side*j+Vector3.new(0,zig*.6*(rng:NextNumber()*2-1),0))
	end
	table.insert(out,to)
	return out
end
local function draw(fx,impact,folder,look)
	local from,to=impact.from or impact.position,impact.to or impact.position
	local line=Vector3.new(to.X-from.X,0,to.Z-from.Z)
	if line.Magnitude<DashTrailFX.MIN then return false end
	local holder=K.new("Model",{Name="DashTrail"},fx.folder)
	Debris:AddItem(holder,DashTrailFX.LIFE+.5)
	local chest=Vector3.new(0,.4,0)
	local rng=Random.new()
	-- The line, drawn from the departure: each segment appears in turn.
	local function bolt(width,transparency,lifeK)
		local pts=DashTrailFX.points(from+chest,to+chest,look.zig,rng)
		local atts={}
		for i,p in pts do local _,a=anchor(holder,p);atts[i]=a end
		local beams={}
		for i=1,#atts-1 do
			local u=(i-1)/(#atts-1)
			task.delay(DashTrailFX.RUN*u,function()
				if not holder.Parent then return end
				-- the tail (departure) thinner than the head (arrival)
				local b=beam(holder,atts[i],atts[i+1],look.core,width*(.35+.65*u),width*(.35+.65*(i/(#atts-1))),transparency)
				local glow=beam(holder,atts[i],atts[i+1],look.edge,width*2.4*(.35+.65*u),width*2.4*(.35+.65*(i/(#atts-1))),math.min(.9,transparency+.35))
				table.insert(beams,b);table.insert(beams,glow)
			end)
		end
		task.delay(DashTrailFX.LIFE*lifeK,function()
			for _,b in beams do if b.Parent then b:Destroy() end end
		end)
	end
	if look.zig>0 then
		-- Kakashi: real lightning along the line (LightningBoltFX, the
		-- Lightning-Beams maths): it runs from the departure to the arrival in
		-- RUN seconds (the pulse), then two more forks of the same line crackle
		-- while the first fades.
		Bolt.folder=fx.folder
		local function fork(width,radius,delay)
			task.delay(delay,function()
				local a,b=from+chest,to+chest
				local axis=(b-a).Unit
				local bolt=Bolt.new(Bolt.point(a,axis),Bolt.point(b,axis),math.clamp(math.floor((b-a).Magnitude*1.6),10,30))
				bolt.Color=look.core;bolt.GlowColor=look.edge
				bolt.Thickness=width;bolt.MinRadius=.1;bolt.MaxRadius=radius
				bolt.Frequency=1.4;bolt.AnimationSpeed=9
				bolt.PulseSpeed=1/DashTrailFX.RUN;bolt.PulseLength=DashTrailFX.LIFE/DashTrailFX.RUN;bolt.FadeLength=.15
				task.delay(DashTrailFX.RUN+DashTrailFX.LIFE*.5,function() pcall(bolt.DestroyDissipate,bolt,.15,.6) end)
			end)
		end
		fork(look.width*.7,look.zig,0)
		fork(look.width*.45,look.zig*1.4,.08)
		fork(look.width*.3,look.zig*1.8,.16)
	else
		bolt(look.width,.05,1)
	end
	-- The scorch on the floor, under the line, slower to go.
	local floor=K.floorUnder and K.floorUnder(fx,from,1,6)
	local y=if floor then floor.Position.Y+.08 else from.Y-2.5
	local _,g0=anchor(holder,Vector3.new(from.X,y,from.Z))
	local _,g1=anchor(holder,Vector3.new(to.X,y,to.Z))
	local scorch=K.new("Beam",{Attachment0=g0,Attachment1=g1,Width0=.25,Width1=.9,FaceCamera=false,Segments=1,LightEmission=.6,LightInfluence=.4,
		Color=ColorSequence.new(look.edge),Transparency=seq(.6,.25)},holder)
	g0.Axis=Vector3.yAxis;g1.Axis=Vector3.yAxis
	local t0=os.clock()
	task.spawn(function()
		while scorch.Parent and os.clock()-t0<DashTrailFX.LIFE+.4 do
			local k=(os.clock()-t0)/(DashTrailFX.LIFE+.4)
			scorch.Transparency=seq(.6+.4*k,.25+.75*k)
			task.wait()
		end
	end)
	-- Afterimages of the arrival pose strung back along the line.
	local model=folder and folder:FindFirstChild(impact.owner or "")
	if model and fx.ghost then
		task.delay(.04,function()
			if not model.Parent then return end
			for k=1,look.ghosts do
				local u=k/(look.ghosts+1)
				local ghost=fx:ghost(model,look.edge,.12+(1-u)*.16,.42+u*.3)
				if ghost then
					local pivot=ghost:GetPivot()
					pcall(function() ghost:PivotTo(pivot-line*u) end)
				end
			end
		end)
	end
	-- The arrival: the light thrown out along the line; sparks for the blade.
	if K.flash then K.flash(fx.folder,to,look.core,1.2,6,.16,.1) end
	if K.shockRing then K.shockRing(fx.folder,Vector3.new(to.X,y+.1,to.Z),look.edge,1.5,9,.25) end
	if K.burst and look.zig>0 then
		K.burst(fx.folder,to,{Texture=K.TEX and K.TEX.spark,Lifetime=NumberRange.new(.1,.25),Speed=NumberRange.new(12,22),SpreadAngle=Vector2.new(70,70),
			Color=ColorSequence.new(look.core,look.edge),LightEmission=1,Size=NumberSequence.new(.35,0),Drag=6,
			EmissionDirection=Enum.NormalId.Front},16)
	end
	if K.sound and K.SOUND and K.anchorPart then
		K.sound(K.anchorPart(fx.folder,to),K.SOUND.whooshBy or K.SOUND.whoosh,.5,if look.zig>0 then 1.9 else 1.6)
	end
	return true
end
local function impact(fx,data,folder)
	if data.style~="teleport" then return false end
	local look=DashTrailFX.KINDS[data.kind or ""]
	if not look then return false end
	pcall(draw,fx,data,folder,look)
	-- false: the trail is drawn on top of the family's own puffs (FamilyFX),
	-- which still mark the departure and the arrival.
	return false
end
DashTrailFX.impact=impact
function DashTrailFX.install(FX,kit)
	K=kit
	table.insert(FX.layers,{name="DashTrail",impact=impact})
end
return DashTrailFX
