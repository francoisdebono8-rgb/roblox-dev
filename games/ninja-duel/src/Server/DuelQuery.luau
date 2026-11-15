-- (15/11, François: « des 1v1 vraiment comme ça sur la map », « dans la rue »)
-- A duel fought in Konoha's streets shares them with the players walking by.
-- The passers-by stay out of the fight: their avatars are in the NinjaWalkers
-- collision group, which the fighters never collide with, and every query of
-- the fight (the motor's rays, the hits, the props pushed, the projectiles)
-- runs in the NinjaDuelRays group, which never meets a passer-by. The
-- village itself (walls, houses, the ground) still stops and holds the fight.
local DuelQuery={GROUP="NinjaDuelRays",WALKERS="NinjaWalkers",FIGHTERS="NinjaFighters",ready=false}

function DuelQuery.setup()
	if DuelQuery.ready then return true end
	local ok=pcall(function()
		local physics=game:GetService("PhysicsService")
		for _,name in {DuelQuery.FIGHTERS,DuelQuery.WALKERS,DuelQuery.GROUP} do
			if not physics:IsCollisionGroupRegistered(name) then physics:RegisterCollisionGroup(name) end
		end
		physics:CollisionGroupSetCollidable(DuelQuery.FIGHTERS,DuelQuery.FIGHTERS,false)
		physics:CollisionGroupSetCollidable(DuelQuery.FIGHTERS,DuelQuery.WALKERS,false)
		physics:CollisionGroupSetCollidable(DuelQuery.GROUP,DuelQuery.WALKERS,false)
	end)
	DuelQuery.ready=ok
	return ok
end

-- A fight's RaycastParams or OverlapParams: blind to the passers-by.
function DuelQuery.apply(params)
	if DuelQuery.ready then pcall(function() params.CollisionGroup=DuelQuery.GROUP end) end
	return params
end

-- A walker's avatar (Server/Hub): every part, and every part added later
-- (the outfit, the headband), in the passers-by's group.
function DuelQuery.walker(character)
	if not DuelQuery.setup() then return end
	local function put(d) if d:IsA("BasePart") then d.CollisionGroup=DuelQuery.WALKERS end end
	for _,d in character:GetDescendants() do put(d) end
	character.DescendantAdded:Connect(put)
end

return DuelQuery
