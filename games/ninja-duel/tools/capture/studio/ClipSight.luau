--!nocheck
-- ClipSight (FILM place): lines of sight that also see what a raycast cannot.
--  * the decor the game builds unqueryable (bushes and tree tops of
--    Client/ArenaDress, Server/World props: CanQuery=false), collected every
--    few seconds as boxes;
--  * any list of parts given by the caller (the replay's ghost bodies are
--    anchored copies with CanQuery=false, so a raycast passes through them).
-- Used by ClipAssist (F4) for "hidden by", and by NDDirector to pick a clear angle.
local Sight={}
local SKIP={NinjaDuels=true,NinjaDuelBodies=true,NinjaDuelFX=true,Effects=true,NinjaUltimateFX=true,VfxMesh=true,WorldMemory=true,NDReplay=true}
local boxes={}
local builtAt=-math.huge
Sight.refreshEvery=5

function Sight.refresh(force)
	if not force and os.clock()-builtAt<Sight.refreshEvery then return end
	builtAt=os.clock()
	table.clear(boxes)
	for _,root in workspace:GetChildren() do
		if not SKIP[root.Name] and not root:IsA("Camera") and not root:IsA("Terrain") then
			local list=root:IsA("BasePart") and {root} or root:GetDescendants()
			for _,p in list do
				if p:IsA("BasePart") and not p.CanQuery and p.Transparency<0.5 then
					local m=p.Size.Magnitude
					if m>1.2 and m<120 then table.insert(boxes,{part=p,cf=p.CFrame,h=p.Size/2,c=p.Position,r=m/2}) end
				end
			end
		end
	end
end

-- Segment a -> a+d against one box (slab test in the box's space): entry fraction or nil.
local function enter(cf,h,a,d)
	local o=cf:PointToObjectSpace(a)
	local v=cf:VectorToObjectSpace(d)
	local t0,t1=0,1
	for _,ax in {"X","Y","Z"} do
		local oo,vv,hh=o[ax],v[ax],h[ax]
		if math.abs(vv)<1e-9 then
			if oo<-hh or oo>hh then return nil end
		else
			local ta,tb=(-hh-oo)/vv,(hh-oo)/vv
			if ta>tb then ta,tb=tb,ta end
			if ta>t0 then t0=ta end
			if tb<t1 then t1=tb end
			if t0>t1 then return nil end
		end
	end
	return t0
end
Sight.enter=enter

-- The decor boxes within r of a point (a smaller list for many rays around one place).
function Sight.subset(center,r)
	Sight.refresh()
	local list={}
	for _,x in boxes do
		if (x.c-center).Magnitude<=x.r+r then table.insert(list,x) end
	end
	return list
end

-- The first unqueryable decor box between a and b (fraction along the segment).
-- list: a Sight.subset (all the boxes by default).
function Sight.decor(a,b,margin,list)
	if not list then Sight.refresh() end
	local d=b-a
	local L2=d:Dot(d)
	if L2<1e-6 then return nil end
	local best,bt=nil,1-(margin or 0.02)
	for _,x in list or boxes do
		local t=math.clamp((x.c-a):Dot(d)/L2,0,1)
		if (a+d*t-x.c).Magnitude<=x.r then
			local th=enter(x.cf,x.h,a,d)
			if th and th<bt then best,bt=x.part,th end
		end
	end
	return best,best and bt or nil
end

-- The first of `parts` (live CFrames) between a and b.
function Sight.parts(a,b,parts,margin)
	local d=b-a
	local L2=d:Dot(d)
	if L2<1e-6 then return nil end
	local best,bt=nil,1-(margin or 0.02)
	for _,p in parts do
		if p.Parent and p.Transparency<0.6 then
			local c=p.Position
			local t=math.clamp((c-a):Dot(d)/L2,0,1)
			if (a+d*t-c).Magnitude<=p.Size.Magnitude/2 then
				local th=enter(p.CFrame,p.Size/2,a,d)
				if th and th<bt then best,bt=p,th end
			end
		end
	end
	return best,best and bt or nil
end

-- An unqueryable decor box within r of a point (a lens placed in a bush).
function Sight.near(pos,r)
	Sight.refresh()
	for _,x in boxes do
		if (x.c-pos).Magnitude<=x.r+r then
			local o=x.cf:PointToObjectSpace(pos)
			local q=Vector3.new(math.clamp(o.X,-x.h.X,x.h.X),math.clamp(o.Y,-x.h.Y,x.h.Y),math.clamp(o.Z,-x.h.Z,x.h.Z))
			if (o-q).Magnitude<=r then return x.part end
		end
	end
	return nil
end

-- A raycast plus the unqueryable decor: true when nothing is in the way.
function Sight.clear(a,b,params)
	local hit=workspace:Raycast(a,b-a,params)
	if hit then return false,hit.Instance end
	local p=Sight.decor(a,b,0.02)
	return p==nil,p
end

return Sight
