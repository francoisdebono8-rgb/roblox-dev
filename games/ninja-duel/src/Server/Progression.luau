-- The masters' path on the server (DEC-037, user 12/11 17 h 02-17 h 21):
-- each player's saved profile (Server/ProfileRepository: lease, fenced
-- writes; Server/ProfileSchema v2: the kits learned, the starter, the
-- selected kit, the mastery per kit, the purchase receipts), loaded when he
-- joins, saved every SaveInterval and when he leaves or the server closes.
--   * A new player picks one kit among the starters (Shared/Masters).
--   * A duel with an owned kit, decided, earns that kit mastery.
--   * A master teaches his kit once the player has enough mastery in a kit
--     linked to him: the player wins the master's duel (the prodigy, hard AI).
--   * A kit can be bought at once (a Developer Product per kit, configured in
--     Config.Progression.Products; granted once per receipt, saved before
--     Roblox is told it is granted). Never a random draw; ranked and
--     tournament budgets stay equal (DEC-024).
-- Practice (the tutorial and the training duel) takes any kit: a player
-- tries what he wants to learn.
-- Off while Config.Progression.Enabled is false: every kit is open, as in the
-- beta today. Persistence: Roblox's DataStore (the DEV store in Studio, the
-- live one only with Live=true); where the DataStore is not reachable (a
-- local place in Studio, the headless specs) an in-memory store for the
-- session, said once in the output.
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Config=require(Shared.Config)
local Masters=require(Shared.Masters)
local S=require(script.Parent.ProfileSchema)
local Repo=require(script.Parent.ProfileRepository)

local P={handles=setmetatable({},{__mode="k"}),states=setmetatable({},{__mode="k"}),boost=setmetatable({},{__mode="k"}),repo=nil}
P.LoadTries=5
P.LoadRetry=3

function P.config() return Config.Progression or {} end
-- On once Config says so AND the profiles' store is up (Server/Main starts it):
-- a server or a headless suite that never starts it keeps every kit open.
function P.enabled() return P.config().Enabled==true and P.repo~=nil end
function P.profileId(player) return "u_"..tostring(player.UserId) end

-- The store: the DataStore when Roblox gives it, else memory for this session.
function P.init(store)
	if P.repo then return P.repo end
	if not store then
		local ok,ds=pcall(Repo.dataStore,{enabled=true,live=P.config().Live==true})
		if ok and ds then
			local probe=pcall(function() return ds:read("p_dev_probe") end)
			if probe then store=ds end
		end
		if not store then
			print("[NinjaDuel] progression: no DataStore here, profiles kept in memory for this session")
			store=Repo.memoryStore()
		end
	end
	P.repo=Repo.new(store)
	return P.repo
end

-- Loads a player's profile (yields): a locked one (he just left another
-- server) is retried a few times.
function P.load(player)
	if P.states[player]=="ready" or P.states[player]=="loading" then return P.handles[player] end
	P.init()
	P.states[player]="loading"
	local h,why
	for attempt=1,P.LoadTries do
		h,why=P.repo:load(P.profileId(player))
		if h or why~="Session locked" or attempt==P.LoadTries then break end
		task.wait(P.LoadRetry)
	end
	if not h then
		P.states[player]="failed"
		warn("[NinjaDuel] progression: "..player.Name.."'s profile not loaded ("..tostring(why).."): every kit open for him this session")
		return nil
	end
	P.handles[player]=h;P.states[player]="ready"
	local pass=P.config().MasteryPass or 0
	if pass>0 then
		pcall(function() P.boost[player]=game:GetService("MarketplaceService"):UserOwnsGamePassAsync(player.UserId,pass) end)
	end
	return h
end
function P.ready(player) return P.states[player]=="ready" and P.handles[player]~=nil end

-- What the roster shows: learned kits, mastery, and for every master whether
-- he teaches now and what is missing.
function P.view(player)
	if not P.enabled() then return nil end
	local state=P.states[player] or "none"
	local out={state=state,owned={},mastery={},masters={}}
	local h=P.handles[player]
	if state~="ready" or not h then
		if state=="failed" then for _,id in Masters.Kits do out.owned[id]=true end end
		return out
	end
	local k=h.data.kits
	for id in k.owned do out.owned[id]=true end
	for id,m in k.mastery do out.mastery[id]=m end
	out.starter=k.starter;out.selected=k.selected;out.needStarter=k.starter==nil
	for id in Masters.Map do
		local ok,why,best=Masters.canLearn(k,id)
		-- `via`: the learned kit he fights the master's duel with.
		out.masters[id]={ready=ok,via=if ok then why else nil,missing=if ok then nil else why,best=best,product=(P.config().Products or {})[id]}
	end
	return out
end

-- Whether a player may fight a duel that counts with this kit.
function P.owns(player,id)
	if not P.enabled() then return true end
	local state=P.states[player]
	if state=="failed" then return true end
	local h=P.handles[player]
	if state~="ready" or not h then return false end
	return h.data.kits.owned[id]==true
end

-- One profile command, in memory until the next save (Repo:pulse).
function P.run(player,kind,args)
	local h=P.handles[player]
	if not h then return false,"Profile not loaded" end
	return P.repo:apply(h,h.data.sequence+1,kind,args)
end
function P.chooseStarter(player,id) return P.run(player,"chooseStarter",{fighter=id}) end
function P.select(player,id) return P.run(player,"selectKit",{fighter=id}) end
function P.learnFromMaster(player,id) return P.run(player,"learnKit",{fighter=id,via="master"}) end
-- The kit he fights with becomes the roster's pick next time (no command when
-- it already is, nor for a kit he does not own: practice).
function P.remember(player,id)
	if not P.enabled() or not P.ready(player) then return end
	local k=P.handles[player].data.kits
	if k.owned[id] and k.selected~=id then P.select(player,id) end
end

-- A decided duel: mastery for the kit fought with, when it is owned and the
-- duel counts (not practice, not a watched match, not an autopilot).
function P.duelEnded(player,s,won)
	if not P.enabled() or not P.ready(player) then return nil end
	if s.tutorial or s.spectate or s.autopilot or s.scripted or s.online or s.cupPilot then return nil end
	local id=s.playerId
	if not P.owns(player,id) then return nil end
	local used=0
	for _ in (s.human and s.human.usedJutsu) or {} do used+=1 end
	local amount=Masters.duelGain({won=won,techniques=used,level=s.aiLevel or "easy"})
	if P.boost[player] then amount=math.min(Masters.Gain.Max,amount*2) end
	if amount<=0 then return nil end
	local ok,result=P.run(player,"gainMastery",{fighter=id,amount=amount})
	if ok and type(result)=="table" then result.amount=amount end
	return if ok then result else nil
end

-- A kit bought (MarketplaceService.ProcessReceipt): granted once per receipt,
-- and Roblox is told it is granted only once the profile is saved.
function P.processReceipt(info)
	local products=P.config().Products or {}
	local kit=nil
	for id,product in products do if product==info.ProductId then kit=id end end
	local Decision=Enum.ProductPurchaseDecision
	if not kit then return Decision.NotProcessedYet end
	local player=Players:GetPlayerByUserId(info.PlayerId)
	local h=player and P.handles[player]
	if not h then return Decision.NotProcessedYet end
	local receipt=string.gsub(tostring(info.PurchaseId),"[^%w_.:%-]","")
	if table.find(h.data.kits.receipts,receipt) then
		-- Granted before (the save went through, Roblox did not hear back).
		local saved=P.repo:save(h)
		return if saved then Decision.PurchaseGranted else Decision.NotProcessedYet
	end
	local ok=P.run(player,"learnKit",{fighter=kit,via="purchase",receipt=receipt})
	if not ok then return Decision.NotProcessedYet end
	local saved=P.repo:save(h)
	-- (Beta loop) the roster shows the kit bought without a return trip.
	if saved and P.onLoaded then task.spawn(pcall,P.onLoaded,player) end
	return if saved then Decision.PurchaseGranted else Decision.NotProcessedYet
end

function P.release(player)
	local h=P.handles[player]
	P.handles[player]=nil;P.states[player]=nil;P.boost[player]=nil
	if h and P.repo then
		local ok,why=P.repo:save(h,true)
		if not ok then warn("[NinjaDuel] progression: "..player.Name.."'s profile not saved on leaving ("..tostring(why)..")") end
	end
end

-- The live hooks (Server/Main): load on join (then `onLoaded(player)`),
-- release on leave, save every 10 s check, everything on shutdown, receipts.
function P.start(onLoaded)
	if P.config().Enabled~=true or P.started then return end
	P.started=true
	P.onLoaded=onLoaded
	P.init()
	local function join(player)
		task.spawn(function()
			P.load(player)
			if onLoaded then pcall(onLoaded,player) end
		end)
	end
	Players.PlayerAdded:Connect(join)
	for _,player in Players:GetPlayers() do join(player) end
	Players.PlayerRemoving:Connect(P.release)
	task.spawn(function()
		while true do
			task.wait(10)
			local failures=P.repo:pulse()
			for id,why in failures do warn("[NinjaDuel] progression: save "..id..": "..tostring(why)) end
		end
	end)
	game:BindToClose(function() if P.repo then P.repo:closeAll() end end)
	if next(P.config().Products or {}) then
		game:GetService("MarketplaceService").ProcessReceipt=P.processReceipt
	end
end

return P
