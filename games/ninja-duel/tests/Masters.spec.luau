-- The masters' path (DEC-037, user 12/11 17 h 02-17 h 21): one kit among
-- three to start, every other kit taught by its master once the player has
-- enough mastery in a kit linked to him, or bought at once (never a random
-- draw). Checked here on the real ProfileSchema, ProfileRepository (memory
-- store) and Matches: the profile's v2 record and its migration from v1, the
-- commands, the map, the mastery a duel earns, the server gates (a duel that
-- counts takes a learned kit, practice takes any), a master's duel won
-- teaching his kit, a purchase granted once and only once saved. Roblox's
-- DataStore and MarketplaceService themselves are not exercised (Studio /
-- live), nor the roster screen (next step).
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Masters=H.load("Shared/Masters")
local Config=H.load("Shared/Config")

test("the profile keeps the kits (v2, now v3 with the wallet); a v1 profile gains an empty kits record",function()
	local p=S.new("dev_kits")
	assert(p.schemaVersion==S.Version and p.kits and next(p.kits.owned)==nil,"a new profile has no kits record")
	assert(S.validate(p))
	local v1={schemaVersion=1,id="dev_old",fighters={},sequence=3}
	local m,why=S.migrate(v1)
	assert(m and m.schemaVersion==S.Version and m.kits and m.wallet and m.style and m.sequence==3,"v1 did not migrate: "..tostring(why))
	assert(S.migrate({schemaVersion=S.Version+1,id="dev_x",fighters={},sequence=0})==nil,"a future schema was accepted")
	local bad=S.copy(p);bad.kits.owned.Nobody=true
	assert(not S.validate(bad),"an unknown kit was accepted")
	local bad2=S.copy(p);bad2.kits.selected="Lion"
	assert(not S.validate(bad2),"a selected kit that is not owned was accepted")
end)

test("one starter among three, once; a kit is selected only once learned",function()
	local p=S.new("dev_start")
	local ok=pcall(S.apply,p,1,"chooseStarter",{fighter="Flashstep"})
	assert(not ok,"Minato was a starter")
	local q=S.apply(p,1,"chooseStarter",{fighter="Leaf"})
	assert(q.kits.owned.Leaf and q.kits.starter=="Leaf" and q.kits.selected=="Leaf")
	assert(not pcall(S.apply,q,2,"chooseStarter",{fighter="Lion"}),"a second starter was taken")
	assert(not pcall(S.apply,q,2,"selectKit",{fighter="Lion"}),"an unlearned kit was selected")
	for _,id in Masters.Starters do assert(Masters.isKit(id),id.." is not a kit") end
	for _,id in Masters.Kits do assert(Masters.Map[id],id.." has no master (the starters not chosen too)") end
	for id,rule in Masters.Map do
		assert(Masters.isKit(id),id)
		for _,from in rule.from do assert(Masters.isKit(from),from) end
	end
	-- Every kit is reachable from every starter through the map (no dead end).
	for _,start in Masters.Starters do
		local owned={[start]=true}
		local grew=true
		while grew do
			grew=false
			for id,rule in Masters.Map do
				if not owned[id] then for _,from in rule.from do if owned[from] then owned[id]=true;grew=true;break end end end
			end
		end
		local n=0;for _ in owned do n+=1 end
		assert(n==#Masters.Kits,"from "..start.." the map opens only "..n.." kits")
	end
end)

test("a master teaches once the player has the mastery in a kit linked to him",function()
	local p=S.apply(S.new("dev_master"),1,"chooseStarter",{fighter="Leaf"})
	assert(not pcall(S.apply,p,2,"learnKit",{fighter="GentleFist",via="master"}),"Neji taught without mastery")
	local can,why=Masters.canLearn(p.kits,"GentleFist")
	assert(not can and string.find(why,"Leaf"),tostring(why))
	local seq=1
	while (p.kits.mastery.Leaf or 0)<Masters.Need do
		seq+=1;p=S.apply(p,seq,"gainMastery",{fighter="Leaf",amount=Masters.Gain.Max})
	end
	assert(not pcall(S.apply,p,seq+1,"gainMastery",{fighter="Lion",amount=10}),"mastery for an unlearned kit")
	assert(not pcall(S.apply,p,seq+1,"gainMastery",{fighter="Leaf",amount=Masters.Gain.Max+1}),"more than one duel's mastery at once")
	seq+=1;p=S.apply(p,seq,"learnKit",{fighter="GentleFist",via="master"})
	assert(p.kits.owned.GentleFist,"Neji's kit was not learned")
	assert(not pcall(S.apply,p,seq+1,"learnKit",{fighter="Flashstep",via="master"}),"Minato taught before Kakashi")
end)

test("a duel's mastery: finishing, winning, each different jutsu once, less against easy AI",function()
	local G=Masters.Gain
	assert(Masters.duelGain({won=true,techniques=5,level="normal"})==G.Finished+G.Won+G.MaxTechniques*G.PerTechnique)
	assert(Masters.duelGain({won=false,techniques=0,level="normal"})==G.Finished)
	assert(Masters.duelGain({won=true,techniques=0,level="easy"})<G.Finished+G.Won)
	local wins=math.ceil(Masters.Need/Masters.duelGain({won=true,techniques=2,level="normal"}))
	assert(wins>=3 and wins<=6,"the first master needs "..wins.." good wins")
end)

test("a kit bought is granted once per receipt, whatever the replays",function()
	local p=S.apply(S.new("dev_buy"),1,"chooseStarter",{fighter="Lion"})
	p=S.apply(p,2,"learnKit",{fighter="Flashstep",via="purchase",receipt="r1"})
	assert(p.kits.owned.Flashstep and p.kits.receipts[1]=="r1")
	assert(not pcall(S.apply,p,3,"learnKit",{fighter="Flashstep",via="purchase",receipt="r1"}),"a receipt was granted twice")
	-- The same sequence replays the stored result (an ambiguous save).
	local again,_,replayed=S.apply(p,2,"learnKit",{fighter="Flashstep",via="purchase",receipt="r1"})
	assert(replayed and again.kits.owned.Flashstep)
	assert(not pcall(S.apply,p,3,"learnKit",{fighter="Flashstep",via="gift"}),"an unknown way to learn")
end)

-- The server: Progression on a memory store, through Matches.
local getService=H.envBase.game.GetService
local owners=0
H.envBase.game.GetService=function(g,name)
	if name=="HttpService" then return {GenerateGUID=function() owners+=1;return "server-"..owners end} end
	return getService(g,name)
end
local clock=7000
H.workspace.GetServerTimeNow=function() return clock end
H.envBase.task={delay=function() end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Progression=H.load("Server/Progression")
local Matches=H.load("Server/Matches")
local sent={}
local remote={FireClient=function(_,player,data) sent[player]=data end}

test("off: every kit is open, as in the beta today",function()
	Config.Progression.Enabled=false
	local player={UserId=501,Name="P501",DisplayName="P501",Parent=H.Players}
	assert(Progression.owns(player,"Flashstep") and Progression.view(player)==nil)
end)

test("on: a duel that counts takes a learned kit, practice takes any; a master's duel won teaches his kit",function()
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local m=Matches.new(remote)
	local player={UserId=502,Name="P502",DisplayName="P502",Parent=H.Players}
	m:selection(player)
	assert(not Progression.owns(player,"Leaf"),"a kit was open before the profile loaded")
	assert(Progression.load(player),"the profile did not load")
	local view=Progression.view(player)
	assert(view.needStarter and next(view.owned)==nil,"a new profile already has kits")
	local s=m.sessions[player]
	local function send(action,extra)
		s.lastLifecycle=-10
		local payload={action=action,epoch=s.epoch}
		for k,v in extra or {} do payload[k]=v end
		m:request(player,payload)
	end
	send("Start",{player="Leaf",bot="Lion"})
	assert(s.phase=="Selection" and string.find(sent[player].notice or "","NOT LEARNED"),"a duel started with an unlearned kit")
	send("Tutorial",{player="Flashstep",bot="Lion"})
	assert(s.phase=="Duel" and s.playerId=="Flashstep","practice refused a kit not learned yet")
	m:selection(player)
	send("ChooseStarter",{player="Leaf"})
	assert(Progression.owns(player,"Leaf") and sent[player].kits.selected=="Leaf","the starter was not taken")
	-- Duels with Lee: mastery, two different jutsu each time.
	local function duel(won,botId)
		send("Start",{player="Leaf",bot=botId or "Lion",level="normal"})
		assert(s.phase=="Duel","the duel did not start")
		s.human.usedJutsu={Technique1=true,Technique2=true}
		for _=1,2 do
			if s.phase~="Duel" then break end
			if won then s.finish(s.human,s.bot) else s.finish(s.bot,s.human) end
			s.finishing=false;s.phase="Duel"
		end
		m:selection(player)
	end
	local before=Progression.view(player).mastery.Leaf or 0
	duel(true)
	local after=Progression.view(player).mastery.Leaf or 0
	assert(after>before,"a won duel earned no mastery")
	assert(s.progress and s.progress.amount==after-before and s.progress.need==Masters.Need,"the result screen does not get what was earned")
	while (Progression.view(player).mastery.Leaf or 0)<Masters.Need do duel(true) end
	assert(Progression.view(player).masters.GentleFist.ready,"Neji does not teach after the mastery")
	-- (Beta loop) the roster fights his duel with the kit that earned it.
	assert(Progression.view(player).masters.GentleFist.via=="Leaf","Neji's duel is not fought with Lee")
	assert(Progression.view(player).selected=="Leaf","the kit fought with is not the roster's pick")
	-- Neji's duel: the master at his level; won, his kit is learned.
	send("MasterTrial",{player="Leaf",master="GentleFist"})
	assert(s.phase=="Duel" and s.botId=="GentleFist" and s.masterTrial=="GentleFist" and Matches.aiLevel(s)==Masters.DuelLevel,"the master's duel did not start")
	s.finish(s.human,s.bot);s.finishing=false;s.phase="Duel";s.finish(s.human,s.bot)
	assert(s.progress and s.progress.learned=="GentleFist","winning the master's duel taught nothing")
	assert(Progression.owns(player,"GentleFist"),"Neji's kit is not learned")
	-- Saved on leaving: a new server finds it.
	local store=Progression.repo.store
	Progression.release(player)
	Progression.repo=nil;Progression.init(store)
	assert(Progression.load(player) and Progression.owns(player,"GentleFist") and Progression.owns(player,"Leaf"),"the kits were not saved")
	Config.Progression.Enabled=false
end)

test("(DEC-038) a learned kit fights with its tree: objects earned, nodes on; a kit only tried is whole",function()
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local m=Matches.new(remote)
	local player={UserId=503,Name="P503",DisplayName="P503",Parent=H.Players}
	m:selection(player)
	assert(Progression.load(player),"the profile did not load")
	local s=m.sessions[player]
	local function send(action,extra)
		s.lastLifecycle=-10
		local payload={action=action,epoch=s.epoch}
		for k,v in extra or {} do payload[k]=v end
		m:request(player,payload)
	end
	local function weights()
		for _,spec in s.human.def.Techniques do if spec.Id=="RemoveWeights" then return spec end end
	end
	send("ChooseStarter",{player="Leaf"})
	local tree=sent[player].kits.trees.Leaf
	assert(tree and tree.points==0 and tree.free==0,"a new kit's tree has points")
	send("Start",{player="Leaf",bot="Lion"})
	assert(s.phase=="Duel" and weights().Locked==true,"his Lee took the weights off without Gai's permission")
	m:selection(player)
	send("LearnNode",{player="Leaf",node="Weights"})
	assert(string.find(sent[player].notice or "","POINTS"),"a node learned with no points: "..tostring(sent[player].notice))
	assert(Progression.run(player,"gainMastery",{fighter="Leaf",amount=120}))
	send("LearnNode",{player="Leaf",node="Weights"})
	tree=sent[player].kits.trees.Leaf
	assert(tree.points==12 and tree.free==2 and table.find(tree.active,"Weights"),"the node is not on: "..tostring(tree.free))
	send("Start",{player="Leaf",bot="Lion"})
	assert(s.phase=="Duel" and not weights().Locked,"the node did not reach the duel")
	m:selection(player)
	send("SetNode",{player="Leaf",node="Weights",on=false})
	send("Start",{player="Leaf",bot="Lion"})
	assert(weights().Locked==true,"turned off, the node still fought")
	m:selection(player)
	-- A kit he only tries is the prodigy's whole kit (the gourd's shield too).
	send("Tutorial",{player="Sand",bot="Lion"})
	assert(s.phase=="Duel" and s.human.def.SandShield~=nil,"a kit tried in practice lost its object")
	m:selection(player)
	-- The AI's prodigy is never gated.
	send("Start",{player="Leaf",bot="Sand"})
	assert(s.bot.def.SandShield~=nil,"the AI's Gaara lost his gourd")
	Config.Progression.Enabled=false
end)

test("a purchase is granted once, and only once the profile is saved",function()
	Config.Progression.Enabled=true;Config.Progression.Products={Flashstep=9001}
	Progression.repo=nil
	local store=Repo.memoryStore()
	Progression.init(store)
	local player={UserId=503,Name="P503",DisplayName="P503",Parent=H.Players}
	H.Players.GetPlayerByUserId=function(_,id) return if id==503 then player else nil end
	assert(Progression.load(player))
	Progression.chooseStarter(player,"Lion")
	local Decision=H.roblox.Enum.ProductPurchaseDecision
	H.envBase.Enum=H.roblox.Enum
	store.failBefore=3 -- the save cannot go through: Roblox must ask again
	assert(Progression.processReceipt({PlayerId=503,ProductId=9001,PurchaseId="buy-1"})==Decision.NotProcessedYet,"granted without a save")
	store.failBefore=0
	assert(Progression.processReceipt({PlayerId=503,ProductId=9001,PurchaseId="buy-1"})==Decision.PurchaseGranted,"not granted once saved")
	assert(Progression.owns(player,"Flashstep"))
	assert(Progression.processReceipt({PlayerId=503,ProductId=9001,PurchaseId="buy-1"})==Decision.PurchaseGranted,"the replayed receipt was refused")
	local receipts=Progression.handles[player].data.kits.receipts
	local n=0;for _,r in receipts do if r=="buy-1" then n+=1 end end
	assert(n==1,"the receipt was recorded "..n.." times")
	assert(Progression.processReceipt({PlayerId=503,ProductId=1234,PurchaseId="buy-2"})==Decision.NotProcessedYet,"an unknown product was granted")
	Config.Progression.Enabled=false;Config.Progression.Products={}
end)

print(string.format("NinjaDuel masters' path (DEC-037): %d PASS",passed))
