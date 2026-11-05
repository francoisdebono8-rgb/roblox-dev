-- (05/11, lot 4 review) Reused fading parts for the afterimages, streaks and
-- arcs drawn many times a second (MotionSmear's ghosts and streaks, LeeFX's
-- lotus spiral, ChakraFX's arcs, IdentityFX's shadow chain). Each one used
-- to be a new Part, a new Tween and a Debris entry: a body moving faster than
-- a sprint alone made ~300 of each a second. Here a part comes from a pool
-- (one per parent and kind), one Heartbeat fades it along the curve its tween
-- had (TweenService's Quad, In or Out) and hides it (Transparency 1) for the
-- next use. Effects:reset clears the FX folder each duel: a destroyed part is
-- simply dropped. Presentation only.
local RunService=game:GetService("RunService")

local FadePool={}
FadePool.clock=os.clock

type Fade={part:BasePart,pool:{BasePart},parent:Instance,born:number,life:number,from:number,inward:boolean,size0:Vector3?,size1:Vector3?}

local pools=setmetatable({},{__mode="k"}) -- parent -> kind -> idle parts
local live:{Fade}={}
local spare:{Fade}={} -- finished records, reused
local connected=false

local function poolOf(parent:Instance,kind:string):{BasePart}
	local byKind=pools[parent]
	if not byKind then byKind={};pools[parent]=byKind end
	local list=byKind[kind]
	if not list then list={};byKind[kind]=list end
	return list
end

-- One frame: every live part takes its place on its curve; the finished ones
-- go back to their pool hidden.
function FadePool.step()
	local count=#live
	if count==0 then return end
	local now=FadePool.clock()
	for i=count,1,-1 do
		local f=live[i]
		local part=f.part
		local u=(now-f.born)/f.life
		if u>=1 or part.Parent~=f.parent then
			if part.Parent==f.parent then
				part.Transparency=1
				table.insert(f.pool,part)
			end
			live[i]=live[#live];live[#live]=nil
			f.part=nil::any;f.parent=nil::any;f.size0=nil;f.size1=nil
			table.insert(spare,f)
		else
			local e=if f.inward then u*u else 1-(1-u)*(1-u)
			part.Transparency=f.from+(1-f.from)*e
			if f.size0 then part.Size=(f.size0::Vector3):Lerp(f.size1::Vector3,e) end
		end
	end
end

-- A part of this kind under `parent`: an idle one, or a new one set up as
-- Effects' block() (anchored, no collision, query, touch or shadow, smooth
-- surfaces). The second value is true for a new part: the caller sets what
-- never changes for its kind (material, colour) only then.
function FadePool.take(parent:Instance,kind:string,class:string?):(BasePart,boolean)
	local list=poolOf(parent,kind)
	while #list>0 do
		local part=table.remove(list)::BasePart
		if part.Parent==parent then return part,false end
	end
	local part=Instance.new(class or "Part")::BasePart
	part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.CastShadow=false
	part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth
	part.Transparency=1
	part.Parent=parent
	return part,true
end

-- Fades `part` (taken under `parent` as `kind`) from `from` to fully
-- transparent over `life` seconds; "In" or "Out" is the tween's Quad easing
-- direction. With `size1` it also grows from its size now to `size1`.
function FadePool.fade(part:BasePart,parent:Instance,kind:string,life:number,from:number,direction:string,size1:Vector3?)
	part.Transparency=from
	local f=table.remove(spare) or ({}::any)
	f.part=part;f.pool=poolOf(parent,kind);f.parent=parent
	f.born=FadePool.clock();f.life=math.max(life,1e-3);f.from=from;f.inward=direction=="In"
	f.size0=if size1 then part.Size else nil;f.size1=size1
	table.insert(live,f)
	if not connected and RunService.Heartbeat then
		connected=true
		RunService.Heartbeat:Connect(FadePool.step)
	end
end

-- Parts fading now (the tests read it).
function FadePool.live():number return #live end

return FadePool
