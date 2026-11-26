-- The way in (26/11, DEC-054; François: « intro du jeu à revoir : arrive avec
-- une tenue de base […] en dehors du village et faire un combat sans
-- compétence très court, contre un PNJ, on arrive par une forêt »; « je veux
-- plus qu'il apparaisse nu »).
--
-- A new player (Progression.needsIntro) appears at the far end of the forest
-- outside the great gate (HubMap.Forest, built by Server/Hub.forestOutside),
-- his own avatar in the base outfit, the village ahead of him. A bandit blocks
-- the path at the clearing: when he comes near (or after a few seconds) it is
-- a fight, there and then, one short round without any technique (Combat:
-- the session's `bare`), the coach's prompts at the right moments (Server/
-- Coach, without the jutsu and the tool). The bandit down, back on the path;
-- at the gate's foot his character's creation opens (the client: the player
-- attribute NinjaIntro = "create"); done, he enters Konoha through the gate,
-- for good (the profile's `intro`).
--
-- Stages (the player attribute NinjaIntro, read by the client):
--   forest   walking to the clearing (the bandit waits there)
--   fight    the duel with the bandit
--   path     the bandit down: the path to the gate
--   create   at the gate: his ninja (the creation card)
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local HubMap=require(Shared.HubMap)

local Forest={}
-- The bodies' moves: a kit's taijutsu only (its techniques, tools, awakening,
-- ultimate and substitution are refused: Combat's `bare`). Lee's: pure
-- strikes, no clone, no sand, no eye.
Forest.KIT="Leaf"
Forest.BANDIT_KIT="Leaf"
Forest.LEVEL="first"
-- He comes when the walker is this near (studs, at the village's scale), or
-- after this long in the forest.
Forest.TRIGGER=22
Forest.WAIT=7
-- « très court »: the bandit falls in a handful of blows (his blows are the
-- novice's, the player's health has the coach's floor).
Forest.PLAYER_DAMAGE=3.2
-- On the K.O., the duel's result shows this long, then back on the path.
Forest.RESULT=2.6
-- (the CM's words replace these: the passe 2 section CM 1)
Forest.NAME="FOREST BANDIT"
Forest.LINE="Nice clothes, kid. Hand them over!"
-- The base outfit (DEC-054: never naked), equipped on his profile on arrival.
Forest.BASE={top="TopTunicNavy",bottom="BottomPantsDark",feet="FeetSandals"}

Forest.state={}         -- player -> {stage, at, resultAt}
Forest.matches=nil
Forest.bandit=nil       -- the statue (the client draws him as a rogue: NinjaThug)

local function stage(player,name)
	local st=Forest.state[player]
	if st then st.stage=name;st.at=os.clock() end
	pcall(function() player:SetAttribute("NinjaIntro",name) end)
end
Forest.stage=stage
function Forest.of(player)
	local st=Forest.state[player]
	return st and st.stage or nil
end
function Forest.root(player)
	local Hub=require(script.Parent.Hub)
	local body=Hub.bodies and Hub.bodies[player]
	local character=body and body.character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Whether this player starts in the forest (a new profile, the hub on, the
-- plan's village, which has the forest).
function Forest.needs(player)
	local Hub=require(script.Parent.Hub)
	if not (Hub.folder and Hub.folder:FindFirstChild("Forest")) then return false end
	local ok,needs=pcall(function() return require(script.Parent.Progression).needsIntro(player) end)
	return ok and needs==true
end
-- His base outfit, if he wears nothing yet (his profile's own pieces after).
function Forest.dress(player)
	local Progression=require(script.Parent.Progression)
	local Shop=require(Shared.Shop)
	local h=Progression.handles and Progression.handles[player]
	if not h or Shop.dressed(h.data.style) then return end
	for _,id in {Forest.BASE.top,Forest.BASE.bottom,Forest.BASE.feet} do
		pcall(Progression.run,player,"equipItem",{item=id})
	end
end
-- Where he appears (Matches.selection): the forest's far end, its clearing
-- after the fight (the duel's returnTo does that), never the village.
function Forest.arrive(player)
	if not Forest.state[player] then
		Forest.state[player]={stage="forest",at=os.clock()}
		Forest.dress(player)
	end
	local st=Forest.state[player]
	if st.stage=="fight" then stage(player,"path") else stage(player,st.stage) end
	return "forest"
end

-- The fight: the bandit, here and now (Matches.forestFight).
function Forest.fight(player)
	local m=Forest.matches
	if not m then return false end
	local ok=m:forestFight(player)
	if ok then stage(player,"fight") end
	return ok
end

-- The gate's foot: his ninja.
function Forest.atGate(player)
	stage(player,"create")
end
-- His ninja made: into Konoha, for good.
function Forest.created(player)
	local st=Forest.state[player]
	if not st or st.stage~="create" then return false end
	Forest.state[player]=nil
	pcall(function() player:SetAttribute("NinjaIntro",nil) end)
	pcall(function() require(script.Parent.Progression).introDone(player) end)
	local m=Forest.matches
	local s=m and m.sessions[player]
	if s then s.returnTo=nil;s.hubVisited=false end
	if m then m:selection(player) end
	return true
end

-- Every quarter second.
function Forest.tick(now)
	local m=Forest.matches
	if not m then return end
	local F=HubMap.Forest
	local bandit=HubMap.Origin+F.bandit
	local gate=HubMap.Origin+F.gate
	for player,st in Forest.state do
		local s=m.sessions[player]
		if not player.Parent or not s then Forest.state[player]=nil;continue end
		local root=Forest.root(player)
		if st.stage=="forest" and s.phase=="Selection" and not s.finishing then
			local near=root and (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(bandit.X,0,bandit.Z)).Magnitude<Forest.TRIGGER
			if near or now-st.at>Forest.WAIT then Forest.fight(player) end
		elseif st.stage=="fight" then
			if s.phase=="Result" then
				st.resultAt=st.resultAt or now
				if now-st.resultAt>=Forest.RESULT then
					local won=s.forestWon==true
					st.resultAt=nil
					-- lost (the coach's floor makes it rare): he comes again
					stage(player,if won then "path" else "forest");st.at=now
					m:selection(player)
				end
			elseif s.phase=="Selection" and not s.finishing then
				-- the duel left before its end: the bandit is still there
				stage(player,"forest")
			end
		elseif st.stage=="path" and root then
			if (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(gate.X,0,gate.Z)).Magnitude<F.gateRadius then Forest.atGate(player) end
		end
	end
end

-- The bandit, standing on the path at the clearing, facing the far end: a
-- kit's portrait, darkened, drawn by each client as a rogue (KonohaRogueFX).
function Forest.spawnBandit(holder,portraits)
	local Thugs=require(script.Parent.Thugs)
	local F=HubMap.Forest
	local entry=Thugs.spawn(holder,{key="ForestBandit",at=F.bandit,radius=0.01},Forest.BANDIT_KIT,portraits)
	if not entry then return nil end
	-- he is not one of the village's rackets
	Thugs.live.ForestBandit=nil
	local root=entry.root
	local at=HubMap.Origin+F.bandit+Vector3.new(0,3,0)
	local toward=HubMap.Origin+HubMap.Spawns.forest.at+Vector3.new(0,3,0)
	local delta=CFrame.lookAt(at,Vector3.new(toward.X,at.Y,toward.Z))*root.CFrame:Inverse()
	for _,piece in entry.model:GetDescendants() do
		if piece:IsA("BasePart") then piece.CFrame=delta*piece.CFrame end
	end
	entry.model.Name="ForestBandit"
	entry.model:SetAttribute("NinjaForestBandit",true)
	Forest.bandit=entry
	return entry
end

function Forest.start(hubFolder,portraits,matches)
	Forest.matches=matches
	local forest=hubFolder and hubFolder:FindFirstChild("Forest")
	if not forest then return end
	pcall(Forest.spawnBandit,forest,portraits)
	Players.PlayerRemoving:Connect(function(player) Forest.state[player]=nil end)
	task.spawn(function()
		while forest.Parent do
			task.wait(.25)
			pcall(Forest.tick,os.clock())
		end
	end)
end

return Forest
