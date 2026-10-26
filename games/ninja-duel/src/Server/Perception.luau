-- Ninja Embodiment (DEC-027): what a body perceives of the space around a
-- fight. One shared read, used by the strike resolver (a body with its back
-- to a wall is a different situation), by the AI (bring the fight to a wall,
-- a tree, a boulder) and later by chakra actions that read the world.
--
-- Server-side and cheap: a handful of rays per read, cached per actor for
-- Config.Perception.Cache seconds. Nothing here names a fighter.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)

local Perception={}
local TUNE=Config.Perception

-- A surface a body can be driven into: the stadium wall, the field trees,
-- the boulders, anything declared NinjaWall or WorldBreakable. A broken one
-- (a stump, a mound) no longer is.
function Perception.surface(part)
	if not part then return false end
	if part:GetAttribute("WorldState")=="Broken" then return false end
	return part:GetAttribute("NinjaWall")==true or part:GetAttribute("WorldBreakable")==true or part.Name=="Field tree" or part.Name=="Cover"
end
local function kindOf(part)
	if part:GetAttribute("NinjaWall") then return "wall" end
	local m=part.Material and part.Material.Name or ""
	if m=="Wood" or m=="WoodPlanks" then return "tree" end
	return "rock"
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function surfaceHit(c,from,dir,length)
	local hit=workspace:Raycast(from,dir*length,c:rayParams(true))
	if hit and math.abs(hit.Normal.Y)<.5 and Perception.surface(hit.Instance) then
		return {distance=hit.Distance,part=hit.Instance,normal=hit.Normal,position=hit.Position,kind=kindOf(hit.Instance),
			state=hit.Instance:GetAttribute("WorldState") or "Intact"}
	end
	return nil
end
Perception.surfaceHit=surfaceHit

-- The arena's surfaces (built from the match folder, refreshed now and then;
-- a broken one is filtered out on every read).
local function candidates(c)
	local list=c.perceptionSurfaces
	if list and c.now>=list.at and c.now-list.at<TUNE.Refresh then return list end
	list={at=c.now}
	local folder=c.match and c.match.folder
	if folder and folder.GetDescendants then
		for _,part in folder:GetDescendants() do
			if part:IsA("BasePart") and part.CanCollide and Perception.surface(part) then table.insert(list,part) end
		end
	end
	c.perceptionSurfaces=list
	return list
end
-- The closest point of a part's box to a position, on the ground plane.
local function closest(part,position)
	local cf,size=part.CFrame,part.Size
	local p=cf:PointToObjectSpace(position)
	local q=Vector3.new(math.clamp(p.X,-size.X/2,size.X/2),math.clamp(p.Y,-size.Y/2,size.Y/2),math.clamp(p.Z,-size.Z/2,size.Z/2))
	return cf:PointToWorldSpace(q)
end
-- The nearest surface around a position within `range` (geometry, no rays).
function Perception.nearest(c,position,range)
	local best=nil
	for _,part in ipairs(candidates(c)) do
		if Perception.surface(part) then
			local point=closest(part,position)
			local d=flat(point-position)
			local distance=d.Magnitude
			if distance>.05 and distance<=range and (not best or distance<best.distance) then
				best={distance=distance,part=part,direction=d.Unit,position=point,kind=kindOf(part),state=part:GetAttribute("WorldState") or "Intact"}
			end
		end
	end
	return best
end

-- The read for actor `a` facing its target. Returns nil without a target.
--   behindTarget: the surface beyond the target on this body's line (a drive
--                 sends him into it)
--   behindSelf:   the surface at this body's own back (it is the one pinned)
--   nearest:      the closest surface around the target (within Scan), and
--                 the direction from him to it
--   blocked:      the world stands between the two bodies (cover)
function Perception.read(c,a)
	local b=a.target
	if not b or not b.root or b.health<=0 then return nil end
	local here,there=a.root.Position,b.root.Position
	-- Reused for a moment while neither body has really moved.
	local cache=a.perception
	if cache and cache.target==b and c.now>=cache.at and c.now-cache.at<TUNE.Cache
		and (cache.here-here).Magnitude<1 and (cache.there-there).Magnitude<1 then return cache end
	local line=flat(there-here)
	local distance=line.Magnitude
	line=if distance>.05 then line.Unit else flat(a.root.CFrame.LookVector).Unit
	local r={at=c.now,target=b,here=here,there=there,distance=distance,line=line}
	r.behindTarget=surfaceHit(c,there,line,TUNE.Behind)
	r.behindSelf=surfaceHit(c,here,-line,TUNE.Behind)
	r.nearest=Perception.nearest(c,there,TUNE.Scan)
	local chest=Vector3.new(0,.8,0)
	local block=workspace:Raycast(here+chest,(there-here),c:rayParams(true))
	r.blocked=block~=nil and not block.Instance:IsDescendantOf(b.model)
	a.perception=r
	return r
end

return Perception
