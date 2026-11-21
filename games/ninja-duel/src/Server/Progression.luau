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
local SkillBuilds=require(script.Parent.SkillBuilds)
local Shop=require(Shared.Shop)
local Daily=require(Shared.DailyQuests)
local Exam=require(Shared.Exam)
local Codes=require(Shared.Codes)
local Ranked=require(Shared.Ranked)
local Merit=require(Shared.Merit)
-- (21/11, DEC-047) the personalization looks: titles, auras, frames earned
local Style=require(Shared.CatalogStyle)
local NinjaTree=require(Shared.NinjaTree)
-- (20/11) the leaderboards, when the server runs them (Server/Leaderboards)
local function boards()
	local ok,L=pcall(function() return require(script.Parent.Leaderboards).current end)
	return if ok then L else nil
end

local P={handles=setmetatable({},{__mode="k"}),states=setmetatable({},{__mode="k"}),boost=setmetatable({},{__mode="k"}),repo=nil}
P.LoadTries=5
-- The server's clock (UTC seconds; the suites set their own).
P.now=function() return os.time() end
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
	P.earnLooks(player)
	P.badges(player)
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
	-- (DEC-038) Each learned kit's tree: its points, what is unlocked and
	-- what is active in its build (the nodes themselves are Shared/SkillTrees).
	out.trees={}
	for id in k.owned do
		if SkillBuilds.tree(id) then
			local r=h.data.fighters[id]
			local earned=math.max(r and r.earned or 0,Masters.points(k.mastery[id] or 0))
			local unlocked,active={},{}
			if r then
				for node in r.unlocked do table.insert(unlocked,node) end
				local nodes=S.selection(h.data,id)
				for _,node in nodes or {} do table.insert(active,node) end
			end
			out.trees[id]={points=earned,free=earned-(if r then S.spent(id,r) else 0),unlocked=unlocked,active=active,mastery=k.mastery[id] or 0}
		end
	end
	-- (13/11) The wallet and the looks, for the shop and the HUD.
	out.ryo=h.data.wallet and h.data.wallet.ryo or 0
	out.style={owned=S.copy(h.data.style and h.data.style.owned or {}),equipped=S.copy(h.data.style and h.data.style.equipped or {})}
	out.boost=P.boost[player]==true
	-- (19/11) a code's mastery ×2: the seconds it still runs (0: none)
	local codes=h.data.codes
	out.codeBoost=if codes then math.max(0,codes.boostUntil-P.now()) else 0
	-- (19/11, vague 2 DEV 5) the day's quests and the days in a row, the
	-- week's exam: what the DESIGN's panels in Konoha show
	out.daily=Daily.view(h.data.daily,P.now())
	out.exam=Exam.view(h.data.exam,P.now())
	-- (20/11, DEC-043) his rank and his merit (the DESIGN's emblems and auras)
	out.ranked=Ranked.view(h.data.ranked)
	out.merit=Merit.view(h.data.merit)
	-- (21/11, DEC-045) the ninja's tree, for the DESIGN's NINJA tab
	out.ninja=NinjaTree.view(h.data.ninja,NinjaTree.points(h.data.kits.mastery))
	local okTitle,title=pcall(function() return player:GetAttribute("NinjaTitle") end)
	out.title=if okTitle and type(title)=="string" then title else nil
	return out
end
-- (19/11, plan § 2 « la séance » and DEV 6; OUTILLEUR in Studio: the result
-- showed the mastery and the Ryō, not what comes next) What a duel brings
-- closer, for the result screen (Matches: progress.ahead):
--   node: the cheapest node of the kit's tree he can take next (its tier open,
--     its requirements unlocked): id, name, cost, the free points, and the
--     mastery still missing for it (0: he can learn it now, at the tree);
--   tier: the next tier, when it is not open yet: its name and the mastery
--     that opens it;
--   inspirations: the kits whose inspiration this kit leads to, not learned
--     yet, with the mastery still missing (Masters.Need).
-- Pure: `data` is the profile (kits, fighters). nil for a kit not learned.
local TreeTiers=require(Shared.TreeTiers)
function P.aheadOf(data,kit)
	local k=data and data.kits
	if not (k and k.owned and k.owned[kit]) then return nil end
	local mastery=k.mastery and k.mastery[kit] or 0
	local out={kit=kit,mastery=mastery,inspirations={}}
	local tree=SkillBuilds.tree(kit)
	if tree then
		local r=data.fighters and data.fighters[kit] or S.fighter()
		local unlocked=r.unlocked or {}
		local earned=math.max(r.earned or 0,Masters.points(mastery))
		local spent=S.spent(kit,r)
		local best
		for _,node in tree.Nodes or tree do
			if type(node)=="table" and node.Id and not unlocked[node.Id] and mastery>=TreeTiers.need(node) then
				local ok=true
				for _,id in node.Requires or {} do if not unlocked[id] then ok=false end end
				if node.RequiresAny and #node.RequiresAny>0 then
					local any=false
					for _,id in node.RequiresAny do if unlocked[id] then any=true end end
					ok=ok and any
				end
				if ok and (not best or node.Cost<best.Cost) then best=node end
			end
		end
		if best then
			out.node={id=best.Id,name=best.Name,cost=best.Cost,free=earned-spent,
				mastery=math.max(0,(spent+best.Cost)*Masters.PointEvery-mastery)}
		end
		local open=TreeTiers.open(mastery)
		if TreeTiers.Need[open+1] then
			out.tier={name=TreeTiers.Names[open+1],need=TreeTiers.Need[open+1],mastery=TreeTiers.Need[open+1]-mastery}
		end
	end
	for id,rule in Masters.Map do
		if not k.owned[id] and table.find(rule.from,kit) then
			table.insert(out.inspirations,{kit=id,mastery=math.max(0,Masters.Need-mastery)})
		end
	end
	table.sort(out.inspirations,function(a,b) return a.kit<b.kit end)
	return out
end
function P.ahead(player,kit)
	if not P.enabled() or not P.ready(player) then return nil end
	return P.aheadOf(P.handles[player].data,kit)
end
-- (DEC-038) The tree at the master's: buy a node with the kit's points (it
-- goes into the kit's build), or turn an unlocked node on or off.
function P.learnNode(player,kit,node)
	if not P.enabled() or not P.ready(player) then return false,"Profile not loaded" end
	local h=P.handles[player]
	-- Points owed by mastery earned before the trees existed.
	if h.data.kits.owned[kit] and SkillBuilds.tree(kit) then
		local r=h.data.fighters[kit]
		if not r or r.earned<Masters.points(h.data.kits.mastery[kit] or 0) then P.run(player,"syncPoints",{fighter=kit}) end
	end
	return P.run(player,"learnNode",{fighter=kit,node=node})
end
function P.setNode(player,kit,node,on) return P.run(player,"setNode",{fighter=kit,node=node,on=on==true}) end
-- The build a player's own kit fights with in a duel that counts or in
-- practice with a learned kit: his active nodes, the kit objects he has not
-- earned taken away (gated). nil: the prodigy's whole kit (the path is off,
-- the profile failed, the kit is not his, or it has no tree).
function P.kitSpec(player,kit)
	if not P.enabled() or not P.ready(player) or not SkillBuilds.tree(kit) then return nil end
	local h=P.handles[player]
	if not h.data.kits.owned[kit] then return nil end
	local nodes,unlocked=S.selection(h.data,kit)
	local set={}
	for _,id in nodes or {} do set[id]=true end
	return {nodes=nodes or {},unlocked=unlocked or set,gated=true,ninja=NinjaTree.def(h.data.ninja)}
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
	if P.boosted(player) then amount=math.min(Masters.Gain.Max,amount*2) end
	local out=nil
	if amount>0 then
		local ok,result=P.run(player,"gainMastery",{fighter=id,amount=amount})
		if ok and type(result)=="table" then out=result;out.amount=amount end
	end
	-- (13/11, the shop) Ryō for the duel: the day's first win counts double,
	-- a master's duel won pays its own (Shared/Shop.Ryo).
	local h=P.handles[player]
	local today=os.date("!%Y-%m-%d")
	local first=won and h.data.wallet and h.data.wallet.winDay~=today
	local ryo=Shop.duelRyo({won=won,firstWinToday=first,master=s.masterTrial~=nil})
	if ryo>0 then
		local ok,result=P.run(player,"earnRyo",{amount=ryo,day=if first then today else nil})
		if ok and type(result)=="table" then
			out=out or {}
			out.ryo=ryo;out.ryoTotal=result.ryo;out.firstWin=first
		end
	end
	-- (19/11, vague 2 DEV 5) the day's quests and the days in a row
	local lost=s.wins and s.bot and s.wins[s.bot.id] or 0
	return P.daily(player,out,{duel=1,win=if won then 1 else 0,jutsu=used,flawless=if won and lost==0 then 1 else 0,cup=if won and s.cup then 1 else 0})
end
-- (19/11, vague 2 DEV 5) A counted duel's events for the day's quests and
-- the days in a row (Shared/DailyQuests); what they paid joins the result
-- screen's table `out` as out.daily {ryo, completed, streak, total}.
function P.daily(player,out,events)
	if not P.enabled() or not P.ready(player) then return out end
	local clean={}
	for name,n in events do if Daily.Events[name] and type(n)=="number" and n>0 then clean[name]=math.min(100,math.floor(n)) end end
	local ok,result=P.run(player,"dailyRecord",{day=Daily.day(P.now()),events=clean})
	if ok and type(result)=="table" then
		out=out or {}
		out.daily=result
		if (result.ryo or 0)>0 then out.ryoTotal=result.total end
		local L=boards()
		if L and result.streak then L:submit("Streak",player,result.streak.days) end
	end
	-- (20/11, DEC-043) a duel won: merit (`pvp` against a player)
	if (events.win or 0)>0 then
		local merit=P.merit(player,events.pvp==true)
		if merit then out=out or {};out.merit=merit end
	end
	-- (21/11, DEC-047) a title, an aura or a frame earned on the way
	local earned=P.earnLooks(player)
	if #earned>0 then out=out or {};out.earned=earned end
	return out
end
-- (21/11, DEC-047) The earned looks he now qualifies for (Shared/CatalogStyle:
-- titles, merit auras and frames), given; their names for the result screen.
function P.earnLooks(player)
	local names={}
	if not P.enabled() or not P.ready(player) then return names end
	local h=P.handles[player]
	for _,id in Style.earned(h.data,Shop.Items) do
		local ok=P.run(player,"earnItem",{item=id})
		local item=Shop.item(id)
		if ok and item then table.insert(names,item.name) end
	end
	if #names>0 then P.badges(player) end
	return names
end
-- (20/11, DEC-043) What everybody sees of him: NinjaRank (ACADEMY…KAGE),
-- NinjaRating, NinjaAura (merit tier, 0 none), on his Player.
function P.badges(player)
	local h=P.handles[player]
	if not h then return end
	local ranked=Ranked.view(h.data.ranked)
	local tier=Merit.tier(h.data.merit and h.data.merit.points or 0)
	pcall(function()
		player:SetAttribute("NinjaRank",ranked.rank.name)
		player:SetAttribute("NinjaRating",ranked.rating)
		player:SetAttribute("NinjaAura",tier)
		-- (21/11, DEC-045) his chakra nature, for the infusions' effects
		-- (the ANIMATEUR's Infusion.<Nature>); nil: none chosen
		player:SetAttribute("NinjaNature",NinjaTree.nature(h.data.ninja or NinjaTree.new()))
		-- (21/11, DEC-047) his personalization, read by every client: the
		-- title under his name, his chakra's colour, his face-cam frame, the
		-- aura he chose (a merit one he earned, or a shop one), his victory
		-- pose and emote (the ANIMATEUR's clips).
		local eq=(h.data.style and h.data.style.equipped) or {}
		local function worn(slot) local id=eq[slot];return (id and Shop.item(id)) or Shop.default(slot) end
		local title=worn("title")
		player:SetAttribute("NinjaTitle",if title and not title.none then title.name else nil)
		player:SetAttribute("NinjaChakra",Style.color(worn("chakra"),"Chakra"))
		local frame=worn("frame")
		player:SetAttribute("NinjaFrame",frame and frame.id)
		local aura=eq.aura and Shop.item(eq.aura)
		if aura and aura.tier then player:SetAttribute("NinjaAura",math.min(aura.tier,tier));player:SetAttribute("NinjaShopAura",nil)
		elseif aura and aura.id=="AuraNone" then player:SetAttribute("NinjaAura",0);player:SetAttribute("NinjaShopAura",nil)
		elseif aura then player:SetAttribute("NinjaAura",0);player:SetAttribute("NinjaShopAura",aura.id)
		else player:SetAttribute("NinjaShopAura",nil) end
		local victory,emote=worn("victory"),worn("emote")
		player:SetAttribute("NinjaVictory",victory and victory.id)
		player:SetAttribute("NinjaEmote",emote and emote.id)
	end)
end
-- (21/11, DEC-045) The ninja's tree: a node learned with the ninja points (all
-- the mastery earned), a learned node turned on or off. Between duels.
function P.ninjaLearn(player,node)
	if not P.enabled() or not P.ready(player) then return false,"Profile not loaded" end
	local ok,result=P.run(player,"ninjaLearn",{node=node})
	if ok then P.badges(player) end
	return ok,result
end
function P.ninjaSet(player,node,on)
	if not P.enabled() or not P.ready(player) then return false,"Profile not loaded" end
	local ok,result=P.run(player,"ninjaSet",{node=node,on=on==true})
	if ok then P.badges(player) end
	return ok,result
end
function P.rating(player)
	local h=P.handles[player]
	return if h and h.data.ranked then h.data.ranked.rating else Ranked.START
end
-- (20/11, DEC-043) A duel between two players, decided: both ratings move
-- (each against the other's rating before the duel). A player whose profile
-- is not loaded (left, Studio's test players) is skipped. Returns
-- {[player]=result} (Shared/Ranked.record).
function P.rankedDuel(winner,loser)
	if not P.enabled() then return {} end
	local wr,lr=P.rating(winner),P.rating(loser)
	local out={}
	for _,side in {{winner,lr,true},{loser,wr,false}} do
		local player,theirs,won=side[1],side[2],side[3]
		if player and P.ready(player) then
			local ok,result=P.run(player,"rankedResult",{opponent=theirs,won=won})
			if ok and type(result)=="table" then
				out[player]=result
				P.badges(player)
				local L=boards()
				if L then
					L:submit("Rating",player,result.after)
					if won then L:add("WeekWins",player,1) end
				end
			end
		end
	end
	return out
end
-- (20/11, DEC-043) A won duel the profile counts: merit (Shared/Merit).
function P.merit(player,pvp)
	if not P.enabled() or not P.ready(player) then return nil end
	local ok,result=P.run(player,"meritAdd",{pvp=pvp==true})
	if not ok or type(result)~="table" then return nil end
	if result.tierUp then P.badges(player) end
	local L=boards()
	if L then L:submit("Merit",player,result.points) end
	return result
end
-- Mastery ×2: the pass (bought), or a code's while it runs.
function P.boosted(player)
	if P.boost[player] then return true end
	local h=P.handles[player]
	local codes=h and h.data.codes
	return codes~=nil and codes.boostUntil>P.now()
end
-- (19/11) A code typed in the shop. ok, what it gave (Shared/Codes.thanks
-- says it) or why not.
function P.redeemCode(player,text)
	if not P.enabled() or not P.ready(player) then return false,"Profile not loaded" end
	local code=Codes.normalize(text)
	if not code then return false,"Code not found" end
	return P.run(player,"redeemCode",{code=code,now=P.now()})
end
-- (19/11, vague 2 DEV 5) An attempt at the week's exam (Server/WeeklyExam):
-- its score kept if it is the week's best. {week, best, improved, passed}.
function P.examResult(player,week,score,passed)
	if not P.enabled() or not P.ready(player) then return nil end
	local ok,result=P.run(player,"examResult",{week=week,score=score,passed=passed==true})
	return if ok and type(result)=="table" then result else nil
end
function P.examRecord(player)
	local h=P.handles[player]
	return h and h.data.exam
end
-- (DEC-040) Mastery and Ryō for the kit `kit`: `amount` of mastery (the
-- boost doubles it) and `ryo`. The result screen's table, or nil.
local function reward(player,kit,amount,ryo,day)
	if P.boosted(player) then amount*=2 end
	local out=nil
	if amount>0 then
		local ok,result=P.run(player,"gainMastery",{fighter=kit,amount=amount})
		if ok and type(result)=="table" then out=result;out.amount=amount end
	end
	if ryo>0 then
		local ok,result=P.run(player,"earnRyo",{amount=ryo,day=day})
		if ok and type(result)=="table" then
			out=out or {}
			out.ryo=ryo;out.ryoTotal=result.ryo;out.firstWin=day~=nil
		end
	end
	return out
end
-- (DEC-040, user 14/11: « t'es censé la gagner en affrontant des gens ») A
-- duel against another player, decided: mastery for the kit he fought with
-- when he has learned it (twice a duel against the AI), and a duel's Ryō.
function P.versusEnded(player,kit,won,techniques,lost)
	if not P.enabled() or not P.ready(player) or not P.owns(player,kit) then return nil end
	local h=P.handles[player]
	local today=os.date("!%Y-%m-%d")
	local first=won and h.data.wallet and h.data.wallet.winDay~=today
	local amount=Masters.versusGain({won=won,techniques=techniques})
	local ryo=Shop.duelRyo({won=won,firstWinToday=first})
	local out=reward(player,kit,amount,ryo,if first then today else nil)
	return P.daily(player,out,{duel=1,win=if won then 1 else 0,jutsu=techniques or 0,flawless=if won and (lost or 0)==0 then 1 else 0,pvp=true})
end
-- (DEC-040) The tournament's end for him: the champion's kit gets its bonus
-- and the champion's Ryō; a lost final, the finalist's.
function P.cupEnded(player,kit,champion)
	if not P.enabled() or not P.ready(player) or not P.owns(player,kit) then return nil end
	local amount=if champion then Masters.Gain.Champion else Masters.Gain.Finalist
	local ryo=if champion then Shop.Ryo.Champion else Shop.Ryo.Finalist
	return reward(player,kit,amount,ryo,nil)
end
-- (13/11) The shop between duels: a look for Ryō, a look worn.
-- (21/11, DEC-047) what he wears beyond the outfit shows at once (badges)
function P.buyItem(player,item)
	local ok,result=P.run(player,"buyItem",{item=item})
	if ok then P.badges(player) end
	return ok,result
end
function P.equipItem(player,item)
	local ok,result=P.run(player,"equipItem",{item=item})
	if ok then P.badges(player) end
	return ok,result
end
-- The looks the player's own ninja wears in a duel (each slot: the one he
-- chose, else the base one). nil when the path is off.
function P.looks(player)
	if not P.enabled() or not P.ready(player) then return nil end
	local h=P.handles[player]
	local out={}
	for _,slot in Shop.SlotOrder do
		local id=h.data.style and h.data.style.equipped[slot]
		local item=id and Shop.item(id) or Shop.default(slot)
		if item and not item.none then out[slot]=item.id end
	end
	return out
end
-- The Roblox ids the shop sells with (Config.Shop), by what they grant.
function P.shopConfig() return Config.Shop or {} end
function P.productFor(productId)
	for kit,product in P.config().Products or {} do if product==productId then return "kit",kit end end
	for item,product in P.shopConfig().Products or {} do if product==productId then return "item",item end end
	for _,pack in P.shopConfig().RyoPacks or {} do if pack.product==productId then return "ryo",pack.amount end end
	return nil
end

-- A kit bought (MarketplaceService.ProcessReceipt): granted once per receipt,
-- and Roblox is told it is granted only once the profile is saved.
function P.processReceipt(info)
	local Decision=Enum.ProductPurchaseDecision
	local what,value=P.productFor(info.ProductId)
	if not what then return Decision.NotProcessedYet end
	-- (13/11) A look or a pack of Ryō: granted once per receipt, saved first.
	if what~="kit" then
		local player=Players:GetPlayerByUserId(info.PlayerId)
		local h=player and P.handles[player]
		if not h then return Decision.NotProcessedYet end
		local receipt=string.gsub(tostring(info.PurchaseId),"[^%w_.:%-]","")
		if not table.find(h.data.kits.receipts,receipt) then
			local ok=if what=="item" then P.run(player,"grantItem",{item=value,receipt=receipt}) else P.run(player,"grantRyo",{amount=value,receipt=receipt})
			if not ok then return Decision.NotProcessedYet end
		end
		local saved=P.repo:save(h)
		if saved and P.onLoaded then task.spawn(pcall,P.onLoaded,player) end
		return if saved then Decision.PurchaseGranted else Decision.NotProcessedYet
	end
	local kit=value
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
	-- (13/11) Kits, looks and Ryō packs: one receipt handler for them all.
	game:GetService("MarketplaceService").ProcessReceipt=P.processReceipt
end

return P
