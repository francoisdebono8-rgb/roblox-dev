-- The merit aura on a player's duel body (20/11, the ANIMATEUR's step 1: « si
-- le corps du duel n'est pas le Character du joueur, appelle
-- MeritAuraFX.wear(corps, tier, true) »). The duel body is a rig built by the
-- server (Server/AvatarBody.rig), tagged Avatar = his UserId; it wears his
-- tier, quietly (a third of the particles): the duel stays readable.
local Players=game:GetService("Players")
local DuelAuras={started=false}

-- His tier (Player attribute NinjaAura, Server/Progression), 0 for none.
function DuelAuras.tierOf(userId)
	local player=Players:GetPlayerByUserId(userId)
	return if player then (player:GetAttribute("NinjaAura") or 0) else 0
end
-- Puts his aura on `model` (a duel body). `wear`: MeritAuraFX.wear by default.
function DuelAuras.dress(model,wear)
	local id=model and model:GetAttribute("Avatar")
	if type(id)~="number" or not model.Parent then return false end
	local tier=DuelAuras.tierOf(id)
	if tier<=0 then return false end
	wear=wear or function(m,t,quiet) return require(script.Parent.MeritAuraFX).wear(m,t,quiet) end
	local ok=pcall(wear,model,tier,true)
	return ok
end

function DuelAuras.start()
	if DuelAuras.started then return end
	DuelAuras.started=true
	local function seen(inst)
		if inst:IsA("Model") and inst:GetAttribute("Avatar")~=nil then task.defer(DuelAuras.dress,inst) end
	end
	workspace.DescendantAdded:Connect(seen)
	for _,inst in workspace:GetDescendants() do seen(inst) end
end

return DuelAuras
