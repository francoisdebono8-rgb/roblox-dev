-- The walk's lens in Konoha (26/11, passe 3, DEC-055 « la caméra dans les
-- rues » ; seen in the game in passe 2: the lens inside a green wooden prop,
-- the screen full of its inside). The walk uses Roblox's own camera, which
-- stops only at solid, opaque parts: a dressed prop of the village (its
-- invisible box does not collide, its mesh does not query), a tree's crown, a
-- stall's roof let the lens through. What stands between his head and the
-- lens, or holds the lens itself, fades while it is there (the duel's own
-- rule, Client/Camera.fadeHit: an invisible box fades the mesh it carries),
-- and comes back when it is not.
-- Presentation only.

local Sight={}
Sight.__index=Sight
-- How much a prop in the way fades (LocalTransparencyModifier), how many
-- things a ray may cross, how often it is looked at (s).
Sight.FADE=.72
Sight.LAYERS=5
Sight.EVERY=1/30
-- The lens is "inside" what is this near its point (studs).
Sight.INSIDE=.8

function Sight.new()
	return setmetatable({faded={},at=0},Sight)
end

-- (pure) Whether `part` may fade for the walk's lens: not his own body, not
-- the ground, not the village's walls and buildings the lens should stop at.
function Sight.fades(part,character)
	if not part or not part:IsA("BasePart") then return false end
	if character and part:IsDescendantOf(character) then return false end
	if part.Name=="Ground" or part.Name=="Edge" then return false end
	-- (another walker or a body: never faded, they are what he looks at)
	local model=part:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then return false end
	return true
end

function Sight:step(dt,character,head)
	self.at+=dt
	if self.at<Sight.EVERY then return end
	self.at=0
	local camera=workspace.CurrentCamera
	if not (camera and head and head.Parent) then return self:clear() end
	local Camera=require(script.Parent.Camera)
	local lens=camera.CFrame.Position
	local from=head.Position
	local faded={}
	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	local exclude={character}
	params.FilterDescendantsInstances=exclude
	local dir=lens-from
	if dir.Magnitude>.2 then
		for _=1,Sight.LAYERS do
			local hit=workspace:Raycast(from,dir,params)
			if not hit then break end
			if Sight.fades(hit.Instance,character) then Camera.fadeHit(hit.Instance,faded) end
			table.insert(exclude,hit.Instance)
			params.FilterDescendantsInstances=exclude
		end
	end
	-- (27/11) a tree drawn wider than its box (Client/Camera.fadeWide)
	Camera.fadeWide(from,lens,faded)
	-- the lens inside a prop
	local overlap=OverlapParams.new()
	overlap.FilterType=Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances={character}
	for _,part in workspace:GetPartBoundsInRadius(lens,Sight.INSIDE,overlap) do
		if Sight.fades(part,character) then Camera.fadeHit(part,faded) end
	end
	faded=Camera.keepHidden(faded,self.faded)
	for part in self.faded do if not faded[part] and part.Parent then part.LocalTransparencyModifier=0 end end
	for part in faded do if part.Transparency<.95 then part.LocalTransparencyModifier=Sight.FADE end end
	self.faded=faded
end

-- Everything back (a duel begins, the walk ends).
function Sight:clear()
	for part in self.faded do if part.Parent then part.LocalTransparencyModifier=0 end end
	self.faded={}
end

return Sight
