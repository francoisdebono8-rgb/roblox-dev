-- The shop and the Ryō (13/11, user: « on voit tout ce qui est boutique, UI,
-- design, […] les armes »): the catalogue (Shared/Shop), the profile's wallet
-- and looks (ProfileSchema v3), the Ryō a duel pays (the day's first win
-- doubled, a master's duel won), a look bought, worn, granted once per Robux
-- receipt, carried into the duel's snapshot, and the headband on an avatar.
-- Headless; MarketplaceService and the look on screen are Studio checks.
local H=require("./Harness")
local roblox=require("@lune/roblox")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local Shop=H.load("Shared/Shop")
local harnessInstance=H.envBase.Instance -- (the headband suite swaps in real instances)
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Config=H.load("Shared/Config")
local MastersView=H.load("Shared/MastersView")

test("the catalogue: every look has a slot, a price or is a base one, and every slot a base look",function()
	local seen={}
	for _,item in Shop.Items do
		assert(not seen[item.id],"twice: "..item.id);seen[item.id]=true
		assert(Shop.Slots[item.slot],item.id.." has no slot")
		assert(item.base or (item.ryo and item.ryo>0) or item.robux or (item.earned and item.how),item.id.." is neither base, sold nor earned")
		assert(not (item.ryo and item.robux),item.id.." has two prices")
		if item.robux then assert((Config.Shop.Products or {})[item.robux]~=nil,item.id.."'s product is not in Config.Shop") end
		-- (21/11, DEC-047) a title, an aura, a pose or an emote is not painted
		local personal=Shop.Slots[item.slot].personal and item.slot~="hairColor" and item.slot~="chakra" and item.slot~="frame"
		assert(item.none or item.colors or personal,item.id.." has no colours")
		if item.earned then assert(not item.ryo and not item.robux,item.id.." is earned and sold") end
	end
	-- (14/11) the masters' outfits are sold for Robux, at the SHOP
	for _,item in Shop.inSlot("set") do
		if not item.none then assert(item.robux and Shop.counter(item)=="shop",item.id.." is not a Robux look") end
	end
	for _,slot in Shop.SlotOrder do
		if Shop.Slots[slot].outfit then
			-- (DEC-040) he arrives without clothes: no default piece, but free ones
			assert(Shop.default(slot)==nil,slot.." dresses him before he chooses")
			local free=0
			for _,item in Shop.inSlot(slot) do if item.base then free+=1 end end
			assert(free>=1,slot.." has no free piece")
		elseif Shop.Slots[slot].personal then
			-- (21/11, DEC-047) his own hair, no title: a base look that may be « nothing »
			local base=0
			for _,item in Shop.inSlot(slot) do if item.base then base+=1 end end
			assert(base>=1,slot.." has no base look")
		else assert(Shop.default(slot),slot.." has no base look") end
	end
	-- (DEC-040) every outfit piece covers real body parts; a master's
	-- outfit is his kit's and is sold
	local kinds={shell=true,band=true,collar=true,shoulders=true,vest=true,sash=true,tail=true,cape=true,scroll=true}
	local bodies={UpperTorso=true,LowerTorso=true,UpperArm=true,LowerArm=true,Hand=true,UpperLeg=true,LowerLeg=true,Foot=true,Head=true}
	for _,item in Shop.Items do
		if Shop.Slots[item.slot].outfit and not item.none then
			assert(item.pieces and #item.pieces>0,item.id.." has no piece")
			for _,p in item.pieces do
				assert(bodies[p.on] and kinds[p.kind or "shell"] and item.colors[p.c],item.id.." has a bad piece")
			end
		end
		if item.slot=="set" and not item.none then assert(item.kit and not item.base,item.id.." is free or nobody's") end
	end
	-- Never on sale: a kit by chance, a tree point (no such item can exist).
	for _,item in Shop.Items do assert(item.slot~="points" and item.slot~="kit") end
	assert(Shop.duelRyo({won=true,firstWinToday=true})==(Shop.Ryo.Finished+Shop.Ryo.Won)*Shop.Ryo.FirstWinOfDay,"the first win of the day")
	-- (23/11, the OUTILLEUR's new-player robot) the first look within a newcomer's
	-- first two duels: the first fight and its rematch won (the novice, then easy),
	-- with the day's easy quest
	local cheapest=math.huge
	for _,item in Shop.Items do if item.ryo and not item.base and item.ryo<cheapest then cheapest=item.ryo end end
	local easy=H.load("Shared/DailyQuests").Tiers[1].ryo
	assert(Shop.duelRyo({won=true,firstWinToday=true})+Shop.duelRyo({won=true})+easy>=cheapest,"two duels do not pay the cheapest look ("..cheapest..")")
	assert(Shop.duelRyo({won=false})==Shop.Ryo.Finished,"a lost duel")
	assert(Shop.duelRyo({won=true,master=true})==Shop.Ryo.Finished+Shop.Ryo.Won+Shop.Ryo.MasterWon,"a master's duel won")
end)

test("the shop's states: equipped, owned, Ryō (affordable or not), Robux on sale or soon",function()
	local style={owned={KunaiBlack=true},equipped={kunai="KunaiBlack"}}
	assert(Shop.state(style,Shop.item("KunaiBlack"),0,{}).kind=="equipped")
	assert(Shop.state(style,Shop.item("KunaiSteel"),0,{}).kind=="owned","a base look is owned")
	local v=Shop.state(style,Shop.item("KunaiVermilion"),500,{})
	assert(v.kind=="ryo" and not v.afford,"500 Ryō buys a 1200 look")
	assert(Shop.state(style,Shop.item("KunaiVermilion"),5000,{}).afford)
	assert(Shop.state(style,Shop.item("KunaiGold"),0,{}).kind=="soon","a Robux look with no product")
	assert(Shop.state(style,Shop.item("KunaiGold"),0,{KunaiGold=123}).product==123)
	assert(Shop.state(nil,Shop.item("HeadbandBlue"),0,{}).kind=="equipped","the base headband is worn from the start")
end)

test("the profile v3: Ryō earned, a look bought and worn, refused when poor or owned, Robux grants once",function()
	local p=S.new("dev_shop")
	assert(p.wallet.ryo==0 and S.validate(p))
	local seq=0
	local function run(kind,args) seq+=1;local out,result=S.apply(p,seq,kind,args);p=out;return result end
	local function fails(kind,args) return not pcall(S.apply,p,seq+1,kind,args) end
	assert(fails("buyItem",{item="KunaiBlack"}),"a look bought with no Ryō")
	run("earnRyo",{amount=1000,day="2026-11-13"})
	assert(p.wallet.ryo==1000 and p.wallet.winDay=="2026-11-13")
	assert(fails("buyItem",{item="KunaiBlack"}),"1500 Ryō paid with 1000")
	run("earnRyo",{amount=600})
	run("buyItem",{item="KunaiBlack"})
	assert(p.wallet.ryo==100 and p.style.owned.KunaiBlack and p.style.equipped.kunai=="KunaiBlack","bought and worn")
	assert(fails("buyItem",{item="KunaiBlack"}),"bought twice")
	assert(fails("buyItem",{item="KunaiGold"}),"a Robux look for Ryō")
	assert(fails("buyItem",{item="KunaiSteel"}),"a base look bought")
	assert(fails("equipItem",{item="KunaiVermilion"}),"a look not owned worn")
	run("equipItem",{item="KunaiSteel"})
	assert(p.style.equipped.kunai=="KunaiSteel","back to the base look")
	run("grantItem",{item="KunaiGold",receipt="r-gold"})
	assert(p.style.owned.KunaiGold and p.style.equipped.kunai=="KunaiGold")
	assert(fails("grantItem",{item="KunaiGold",receipt="r-gold"}),"a receipt granted twice")
	run("grantRyo",{amount=3000,receipt="r-pack"})
	assert(p.wallet.ryo==3100 and fails("grantRyo",{amount=3000,receipt="r-pack"}),"a pack granted twice")
	-- (23/11, step 5, DEC-049) the eight prodigies' outfits in one purchase:
	-- one receipt, eight looks, the first worn; once only
	local bundle=Config.Shop.Bundles[1]
	run("grantItems",{items=bundle.items,receipt="r-bundle"})
	for _,id in bundle.items do assert(p.style.owned[id],"the bundle lacks "..id) end
	assert(p.style.equipped.set=="SetNaruto","the bundle's first outfit is worn")
	assert(fails("grantItems",{items=bundle.items,receipt="r-bundle"}),"a bundle granted twice")
	assert(fails("grantItems",{items={"KunaiBlack"},receipt="r-bad"}),"a Ryō look in a Robux bundle")
	assert(S.validate(p))
	local bad=S.copy(p);bad.style.equipped.kunai="HeadbandRed"
	assert(not S.validate(bad),"a headband worn as a kunai")
	bad=S.copy(p);bad.style.equipped.kunai="KunaiVermilion"
	assert(not S.validate(bad),"a look worn but not owned")
	bad=S.copy(p);bad.wallet.ryo=-5
	assert(not S.validate(bad),"negative Ryō")
	-- A v2 profile gains an empty wallet and the base looks.
	local v2=S.copy(p);v2.schemaVersion=2;v2.wallet=nil;v2.style=nil
	local m=S.migrate(v2)
	assert(m and m.schemaVersion==3 and m.wallet.ryo==0 and next(m.style.owned)==nil,"v2 did not migrate")
end)

-- The server: Progression and Matches on a memory store.
local getService=H.envBase.game.GetService
local owners=0
H.envBase.game.GetService=function(g,name)
	if name=="HttpService" then return {GenerateGUID=function() owners+=1;return "server-"..owners end} end
	return getService(g,name)
end
local clock=9000
H.workspace.GetServerTimeNow=function() return clock end
H.envBase.task={delay=function() end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Progression=H.load("Server/Progression")
local Matches=H.load("Server/Matches")
local sent={}
local remote={FireClient=function(_,player,data) sent[player]=data end}

test("a duel pays Ryō (the day's first win twice), the shop sells and dresses, the duel wears the looks",function()
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local m=Matches.new(remote)
	local player={UserId=611,Name="P611",DisplayName="P611",Parent=H.Players}
	m:selection(player)
	assert(Progression.load(player),"the profile did not load")
	local s=m.sessions[player]
	local function send(action,extra)
		s.lastLifecycle=-10
		local payload={action=action,epoch=s.epoch}
		for k,v in extra or {} do payload[k]=v end
		m:request(player,payload)
	end
	send("ChooseStarter",{player="Leaf"})
	assert(sent[player].kits.ryo==0,"a new player has Ryō")
	local function duel(won)
		send("Start",{player="Leaf",bot="Lion",level="normal"})
		assert(s.phase=="Duel","the duel did not start")
		for _=1,2 do
			if s.phase~="Duel" then break end
			if won then s.finish(s.human,s.bot) else s.finish(s.bot,s.human) end
			s.finishing=false;s.phase="Duel"
		end
		local progress=s.progress
		m:selection(player)
		return progress
	end
	local first=duel(true)
	assert(first.ryo==(Shop.Ryo.Finished+Shop.Ryo.Won)*Shop.Ryo.FirstWinOfDay and first.firstWin,"the day's first win: "..tostring(first.ryo))
	assert(string.find(MastersView.result(first),"FIRST WIN"),"the result does not say it")
	local second=duel(true)
	assert(second.ryo==Shop.Ryo.Finished+Shop.Ryo.Won and not second.firstWin,"a second win: "..tostring(second.ryo))
	local lost=duel(false)
	assert(lost.ryo==Shop.Ryo.Finished,"a lost duel: "..tostring(lost.ryo))
	local ryo=sent[player].kits.ryo
	-- (19/11, DEV 5) the day's quests and the days in a row pay too
	local daily=0
	for _,p in {first,second,lost} do daily+=(p.daily and p.daily.ryo or 0) end
	assert(first.daily and first.daily.streak and first.daily.streak.days==1,"the first duel of the day did not count the day")
	assert(ryo==first.ryo+second.ryo+lost.ryo+daily,"the wallet: "..tostring(ryo))
	-- The shop: a headband for Ryō, worn at once (a few days of duels).
	send("BuyItem",{item="HeadbandRed"})
	assert(sent[player].notice=="NOT ENOUGH RYŌ","the refusal for the screen: "..tostring(sent[player].notice))
	assert(Progression.run(player,"earnRyo",{amount=900}))
	ryo+=900
	send("BuyItem",{item="HeadbandRed"})
	local kits=sent[player].kits
	assert(kits.style.owned.HeadbandRed and kits.style.equipped.headband=="HeadbandRed" and kits.ryo==ryo-800,"the headband was not sold: "..tostring(sent[player].notice).." ryo "..tostring(kits.ryo).." of "..tostring(ryo))
	-- (19/11, vague 2 DEV 4) the funnel saw the first look bought, not the refusal
	assert(s.metrics.boughtAt,"the funnel did not see the first look bought")
	send("BuyItem",{item="KunaiBlack"})
	assert(sent[player].notice=="NOT ENOUGH RYŌ","a look too dear did not say why: "..tostring(sent[player].notice))
	send("EquipItem",{item="HeadbandNone"})
	assert(sent[player].kits.style.equipped.headband=="HeadbandNone")
	send("EquipItem",{item="HeadbandRed"})
	-- (funnel) a headband is not an outfit: not dressed yet; a top is
	assert(not s.metrics.dressedAt,"a headband counted as dressed")
	send("EquipItem",{item="TopTunicNavy"})
	assert(s.metrics.dressedAt,"the funnel did not see him dressed")
	-- The duel wears them: the snapshot carries the player's looks.
	send("Start",{player="Leaf",bot="Lion",level="normal"})
	assert(s.human.looks and s.human.looks.headband=="HeadbandRed" and s.human.looks.kunai=="KunaiSteel","the duel's looks")
	assert(s.bot.looks==nil,"the AI wears the player's looks")
	local view=m:view(s,s,s.human,s.bot)
	assert(view.human.looks and view.human.looks.headband=="HeadbandRed","the snapshot has no looks")
	m:selection(player)
	Config.Progression.Enabled=false
end)

test("the screens build and draw: the shop's five tabs, the tree by tiers, the Konoha card",function()
	H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim;H.envBase.Vector2=H.roblox.Vector2
	H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	H.workspace.GetAttribute=function() return nil end
	local baseNew=H.envBase.Instance.new
	local saved=H.envBase.Instance
	local made={}
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		table.insert(made,x)
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local sent={}
		local ui=UI.new(baseNew("PlayerGui"),function(action,extra) table.insert(sent,{action=action,extra=extra}) end)
		assert(ui.shopPanel and ui.treePanel,"the shop or the tree panel was not built")
		local kits={state="ready",owned={Leaf=true},mastery={Leaf=320},starter="Leaf",selected="Leaf",masters={GentleFist={ready=true,via="Leaf"}},
			trees={Leaf={points=32,free=12,unlocked={"Weights"},active={"Weights"},mastery=320}},ryo=2450,
			style={owned={KunaiBlack=true},equipped={kunai="KunaiBlack"}}}
		for _,tab in ui.shopPanel.tabsFor("shop",kits.style) do
			ui.shopPanel:show(kits,tab)
			assert(ui.shopPanel:shown() and #ui.shopPanel.drawn>0,tab.." drew nothing")
		end
		-- (14/11, François: « tout ce qu'il y a dans la boutique, c'est des
		-- Robux ») the SHOP sells nothing for Ryō; Konoha's market sells the
		-- looks for Ryō, in two tabs
		local style=kits.style
		local function at(counter)
			local ids,n={},0
			for _,slot in {"kunai","shuriken","tanto","gourd"} do
				for _,item in Shop.atCounter(slot,counter,style) do ids[item.id]=true;n+=1 end
			end
			return ids,n
		end
		local shop,nShop=at("shop")
		assert(not shop.KunaiVermilion and shop.KunaiBlack and shop.KunaiGold and shop.KunaiSteel,"the SHOP: a Ryō look for sale, or his own Ryō look or a free one hidden")
		local market,nMarket=at("market")
		assert(market.KunaiVermilion and not market.KunaiGold and market.KunaiSteel,"the market sells for Robux, or not for Ryō")
		ui.shopPanel:show(kits,"WEAPONS")
		local drawnShop=#ui.shopPanel.drawn
		ui.shopPanel:show(kits,"KITS","market")
		local marketTab=ui.shopPanel.tab
		ui.shopPanel:show(kits,"WEAPONS","market")
		assert(marketTab==ui.shopPanel.tabsFor("market",kits.style)[1] and ui.shopPanel.tab=="WEAPONS" and not ui.shopPanel.tabs.KITS.Visible and not ui.shopPanel.tabs.PASSES.Visible and ui.shopPanel.title.Text=="MARKET","the market's tabs")
		assert(ui.shopPanel.currency.Text=="PAID WITH RYŌ","the market's money")
		assert(drawnShop-#ui.shopPanel.drawn==nShop-nMarket,"the panel does not draw each counter's looks")
		ui.shopPanel:show(kits,"WEAPONS")
		assert(ui.shopPanel.tabs.KITS.Visible and ui.shopPanel.title.Text=="SHOP","the SHOP after the market")
		-- (DESIGN 19/11) each counter says its money; the passes page is VIP & PASSES, VIP first
		assert(ui.shopPanel.currency.Text=="PAID WITH ROBUX" and ui.shopPanel.tabs.PASSES.Text=="VIP & PASSES","the SHOP's money and its passes tab")
		ui.shopPanel.tab="PASSES";ui.shopPanel:draw()
		assert(ui.shopPanel.heading.Text=="VIP & PASSES","the passes page")
		ui.treePanel:show("Leaf",kits)
		-- (fourth pass) one branch at a time: every node shows in its branch
		local seen={}
		local opened=ui.treePanel.branch
		for b=1,#H.load("Shared/TreeView").layout("Leaf",kits.trees.Leaf).branches do
			ui.treePanel.branch=b;ui.treePanel:draw()
			for id in ui.treePanel.tiles do seen[id]=true end
		end
		assert(ui.treePanel:shown() and seen.Weights and seen.HeavyDrop,"the tree's tiles")
		ui.treePanel.branch=opened;ui.treePanel:draw()
		local weightsBranch=nil
		for b=1,6 do ui.treePanel.branch=b;ui.treePanel:draw();if ui.treePanel.tiles.Weights then weightsBranch=b break end end
		-- (15/11, DA v3) a page of paper: learned and on in ink, to learn in red
		local M=ui.treePanel.M
		assert(ui.treePanel.card.BackgroundColor3==M.back,"the tree is not a paper page")
		assert(ui.treePanel.tiles.Weights.BackgroundColor3==M.ink,"a node on is not a band of ink")
		assert(ui.treePanel.selected,"no node picked on opening")
		-- Pressing the picked node's button asks the server.
		ui.treePanel.selected="WeightsTempo";ui.treePanel:detail();ui.treePanel:press()
		assert(sent[#sent].action=="LearnNode" and sent[#sent].extra.node=="WeightsTempo","the tree's button")
		-- (14/11, the new player's walk) the shop's first kits: taken in one
		-- press, the master's place named, TRY beside it
		local new={state="ready",owned={},mastery={},masters={},needStarter=true,trees={},ryo=0,style={owned={},equipped={}}}
		local from=#made
		ui.shopPanel:show(new,"KITS")
		local takes,places=0,0
		for k=from+1,#made do
			local d=made[k]
			if d.Name=="TakeStarter" then takes+=1;if takes==1 then d.click() end end
			if d.ClassName=="TextLabel" and type(d.Text)=="string" and string.find(d.Text,"Take it here, or meet him:",1,true) then places+=1 end
		end
		assert(takes==3 and places==3,string.format("the first kits in the shop: %d TAKE IT, %d places",takes,places))
		assert(sent[#sent].action=="ChooseStarter" and sent[#sent].extra.player=="Legion","TAKE IT asks the server for the first kit")
	end)
	H.envBase.Instance=saved
	assert(ok,err)
end)

-- (14/11, a reader's report on PR #84) « À 390 × 844, le minimum de 0,4 donne
-- une carte de 600 px de large. Le bouton CLOSE de la boutique commence à
-- x = 427, celui de l'arbre à x = 433. » Every overlay now fits the window.
test("every overlay fits a narrow or portrait window: its CLOSE on screen, a corner close when small",function()
	local V=H.roblox.Vector2
	H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim;H.envBase.Vector2=V
	H.workspace.GetAttribute=function() return nil end
	local baseNew=H.envBase.Instance.new
	local saved=H.envBase.Instance
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local Tree,ShopPanel,Lobby=H.load("Client/TreePanel"),H.load("Client/ShopPanel"),H.load("Client/LobbyPanel")
		local function inside(r,v,what)
			assert(r.x>=0 and r.y>=0 and r.x+r.w<=v.X and r.y+r.h<=v.Y,
				string.format("%s at %dx%d: CLOSE %.0f..%.0f x %.0f..%.0f is off screen",what,v.X,v.Y,r.x,r.x+r.w,r.y,r.y+r.h))
		end
		for _,size in {{390,844},{360,640},{844,390},{1024,600},{1280,720},{1600,900},{1920,1080},{2560,1440}} do
			local v=V.new(size[1],size[2])
			H.workspace.CurrentCamera={ViewportSize=v,GetPropertyChangedSignal=function() return {Connect=function() end} end}
			local UI=H.load("Client/UI")
			local ui=UI.new(baseNew("PlayerGui"),function() end)
			local kit=UI.kit
			for name,panel in {Tree=Tree,Shop=ShopPanel} do
				local r=panel.closeRect(v,kit)
				inside(r,v,name)
				assert(1500*r.scale<=v.X and 800*r.scale<=v.Y,name.." card wider than the window at "..size[1])
			end
			inside(Lobby.closeRect(v,kit),v,"Players online")
			local sheet=kit.fitScale(v,1220,720,1.2)
			assert(1120*sheet<=v.X and 640*sheet<=v.Y,"the controls sheet is wider than the window at "..size[1])
			-- small: the large corner close shows (and stays inside the window)
			local small=ShopPanel.fit(v,kit)<kit.SMALL
			assert(ui.shopPanel.corner.Visible==small and ui.treePanel.corner.Visible==small,
				"corner close at "..size[1].."x"..size[2]..": "..tostring(ui.shopPanel.corner.Visible))
			assert(v.X-84>=0 and 70+66<=v.Y,"the corner close is off screen")
			-- big screens keep their look (the old scale where it already fitted)
			if size[1]>=1600 then assert(math.abs(ShopPanel.fit(v,kit)-math.min(1.2,size[1]/1560,size[2]/840))<1e-6,"the big screen's scale changed") end
		end
		-- the corner close closes
		local v=V.new(390,844)
		H.workspace.CurrentCamera={ViewportSize=v,GetPropertyChangedSignal=function() return {Connect=function() end} end}
		local UI=H.load("Client/UI")
		local ui=UI.new(baseNew("PlayerGui"),function() end)
		local kits={state="ready",owned={Leaf=true},mastery={Leaf=0},starter="Leaf",selected="Leaf",masters={},trees={},ryo=0,style={owned={},equipped={}}}
		ui.shopPanel:show(kits,"KITS");assert(ui.shopPanel:shown(),"the shop did not open")
		ui.shopPanel.corner.click();assert(not ui.shopPanel:shown(),"the corner close did not close the shop")
	end)
	H.envBase.Instance=saved
	H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	assert(ok,err)
end)

test("the headband goes on an avatar's head, comes off for none, never for a weapon look",function()
	H.envBase.Instance=roblox.Instance
	local Headband=H.load("Server/Headband")
	local Instance=roblox.Instance
	local model=Instance.new("Model")
	local head=Instance.new("Part");head.Name="Head";head.Size=roblox.Vector3.new(1.2,1.2,1.2);head.Parent=model
	local band=Headband.wear(model,"HeadbandBlack")
	assert(band and band:GetAttribute("NinjaHeadband")=="HeadbandBlack","no headband")
	local parts,welds=0,0
	for _,d in band:GetDescendants() do
		if d:IsA("BasePart") then parts+=1;assert(not d.CanCollide and not d.CanQuery,"a headband piece is hit") end
		if d:IsA("WeldConstraint") then welds+=1 end
	end
	assert(parts>=5 and welds==parts,"pieces "..parts.." welds "..welds)
	assert(Headband.wear(model,"HeadbandNone")==nil and model:FindFirstChild("NinjaHeadband")==nil,"none left it on")
	assert(Headband.wear(model,"KunaiBlack")==nil,"a kunai worn on the head")
	Headband.wear(model,"HeadbandRed");Headband.wear(model,"HeadbandBlue")
	local count=0
	for _,c in model:GetChildren() do if c:GetAttribute("NinjaHeadband") then count+=1 end end
	assert(count==1,"two headbands at once")
end)

-- (15/11, François: « applique la DA ») the shop of the DA v3 (Mix-Shop):
-- one red for what can be bought, grey and the Ryō missing for what cannot,
-- WORN and OWNED said on the card, an outfit drawn in its own colours.
test("DA v3 shop: the buttons' states, the Ryō still missing, the outfit's figure",function()
	H.envBase.UDim2=H.roblox.UDim2;H.envBase.UDim=H.roblox.UDim;H.envBase.Vector2=H.roblox.Vector2
	H.workspace.CurrentCamera={ViewportSize=H.roblox.Vector2.new(1600,900),GetPropertyChangedSignal=function() return {Connect=function() end} end}
	local Panel=H.load("Client/ShopPanel")
	assert(Panel.amount(1250)=="1,250" and Panel.amount(0)=="0" and Panel.amount(999)=="999" and Panel.amount(1000000)=="1,000,000","the Ryō are not written 1,250")
	local function says(state,ryo) local t,k,short=Panel.lookButton(state,ryo) return t,k,short end
	local t,k=says({kind="ryo",price=3000,afford=true},3200);assert(t=="3,000 RYŌ" and k=="red","an affordable look is not red: "..t)
	local t2,k2,short=says({kind="ryo",price=3000,afford=false},1250);assert(k2=="off" and short==1750 and t2=="NEED 1,750 MORE","a look too dear: "..t2)
	assert(select(2,says({kind="equipped"}))=="off" and select(1,says({kind="equipped"}))=="WORN","the worn look")
	assert(select(2,says({kind="owned"}))=="paper","an owned look is not a plain button")
	assert(select(2,says({kind="robux",product=1}))=="red" and select(2,says({kind="soon"}))=="off","Robux / soon")
	-- the masters' outfits: a figure in the set's own colours
	local naruto=Shop.item("SetNaruto")
	local by=Panel.dressedOf(naruto)
	assert(by.UpperTorso and by.UpperTorso[1]==236 and by.Foot and by.Foot[3]==92,"Naruto's figure is not orange with blue feet")
	-- the market: the line of the Ryō missing, in red, under the looks
	H.workspace.GetAttribute=function() return nil end
	local baseNew=harnessInstance.new
	local saved=H.envBase.Instance
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local ui=UI.new(baseNew("PlayerGui"),function() end)
		local kits={state="ready",owned={Leaf=true},mastery={Leaf=0},starter="Leaf",selected="Leaf",masters={},trees={},ryo=10,style={owned={},equipped={}}}
		ui.shopPanel:show(kits,"WEAPONS","market")
		assert(string.find(ui.shopPanel.footer.Text,"more Ryō — win duels to earn them",1,true),"no line for the Ryō missing: "..ui.shopPanel.footer.Text)
		assert(ui.shopPanel.ryo.Text=="10","the wallet")
		kits.ryo=999999;ui.shopPanel:refresh(kits)
		assert(not string.find(ui.shopPanel.footer.Text,"more Ryō",1,true) and ui.shopPanel.ryo.Text=="999,999","rich, the line stays")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 19/11) MY NINJA, the wardrobe: every slot and every piece, what he
-- can wear first, where the rest is had; the slots to come shown as SOON.
test("MY NINJA: the wardrobe lists every slot's pieces, his first, and opens from the shop",function()
	local W=H.load("Client/Wardrobe")
	local style={owned={KunaiBlack=true},equipped={kunai="KunaiSteel",top="TopTunicNavy"}}
	assert(W.state(style,Shop.item("KunaiSteel"))=="worn" and W.state(style,Shop.item("KunaiBlack"))=="owned","worn and owned")
	assert(W.state(style,Shop.item("KunaiVermilion"))=="market" and W.state(style,Shop.item("KunaiGold"))=="shop","market in Ryō, shop in Robux")
	local list=W.items(style,"kunai")
	assert(list[1].id=="KunaiSteel" and list[2].id=="KunaiBlack","his pieces first")
	local have,all=W.count(style,"kunai");assert(have==2 and all==#Shop.inSlot("kunai"),"the count")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local sent={}
		local ui=UI.new(baseNew("PlayerGui"),function(a,p) table.insert(sent,{a,p}) end)
		assert(ui.wardrobe,"no wardrobe")
		local kits={state="ready",owned={Leaf=true},mastery={Leaf=0},starter="Leaf",selected="Leaf",masters={},trees={},ryo=10,style=style}
		ui.shopPanel.onOutfit()
		ui.wardrobe:show(kits)
		assert(ui.wardrobe:shown() and (not ui.outfitPanel or ui.outfitPanel:shown()),"open, and Konoha's walk sees it")
		ui.wardrobe:open("kunai")
		assert(#ui.wardrobe.cards==#Shop.inSlot("kunai"),"one card per kunai")
		-- (19/11, vague 2 DEV 2) mask, cape and back are in the catalogue now;
		-- the ninja's weapon and the victory pose are still to come
		assert(ui.wardrobe.tabs.mask and not ui.wardrobe.tabs.mask.future and ui.wardrobe.tabs.cape and ui.wardrobe.tabs.back,"the accessories' tabs")
		assert(ui.wardrobe.tabs.weapon and ui.wardrobe.tabs.weapon.future and ui.wardrobe.tabs.weapon.count.Text=="SOON","the slots to come")
		ui.wardrobe:open("cape")
		assert(#ui.wardrobe.cards==#Shop.inSlot("cape"),"one card per cape")
		-- (26/11, seen in the game: the bands ran under the card) every band in its
		-- column, the column in the card, a finger's size kept
		local column=ui.wardrobe.column
		assert(column and column.Position.Y.Offset+column.Size.Y.Offset<=W.H-20,"the bands' column leaves the card")
		for id,t in ui.wardrobe.tabs do
			assert(t.button.Parent==column and t.button.Size.Y.Offset>=W.PITCH.min-4,id..": a band out of its column or too small")
		end
		assert(W.pitch(8)==W.PITCH.max and W.pitch(15)==W.PITCH.min and W.pitch(12)*12<=W.LIST_H,"the bands' pitch")
		assert(ui.wardrobe.close.Size.X.Offset>=64,"a big close")
		ui.wardrobe:hide();assert(not ui.wardrobe:shown())
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 20/11, step 1) the ranks: emblems, the result's rank line, the leaderboards
test("ranks: the result's line, the emblems and the leaderboards",function()
	local A=H.load("Shared/UIAssets")
	assert(#A.Ranks==6 and A.rank("GENIN").id=="genin" and A.rank("kage").name=="KAGE","the six ranks")
	local L=H.load("Client/Leaderboard")
	local list={}
	for i=1,14 do table.insert(list,{rank=i,id=100+i,name="N"..i,value=2000-i*60}) end
	local rows=L.rows(list,113)
	assert(#rows==L.ROWS+1 and rows[#rows].you,"the top ten, then his own row")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local genin={before=1222,after=1240,delta=18,rank={id="Genin",name="GENIN",from=1100}}
		assert(UI.rankLine(genin)=="GENIN  1240  (+18)  •  10 to CHUNIN","the rank line: "..UI.rankLine(genin))
		assert(A.rank(genin.rank).id=="genin","the emblem of the server's rank")
		local ui=UI.new(baseNew("PlayerGui"),function() end)
		ui:resultRanked({after=1260,delta=22,rankUp=true,rank={id="Chunin",name="CHUNIN",from=1250}})
		assert(ui.resultRankRow.Visible and ui.resultRank.Text:find("NEW RANK: CHUNIN  1260  (+22)",1,true),"the rank on the result: "..ui.resultRank.Text)
		ui:resultRanked(nil);assert(not ui.resultRankRow.Visible,"no rank sent, no line")
		assert(ui.leaderboard,"no leaderboard")
		ui:showLeaderboard({Rating={id="Rating",title="RANKED",rows=list},
			Rooftops={id="Rooftops",title="ROOFTOP RACE",rows={{rank=1,id=7,name="A",value=42.3,text="0:42.30"}}},
			Kit_Lion={id="Kit_Lion",title="X • MASTERY",kit="Lion",rows={}},Kit_Legion={id="Kit_Legion",title="Y • MASTERY",kit="Legion",rows={}}})
		local tabs=L.kitTabs(ui.leaderboard.boards)
		assert(#tabs==2 and tabs[1].kit=="Lion","the kits' tabs in the roster's order: "..#tabs.." "..tostring(tabs[1] and tabs[1].kit))
		assert(ui.leaderboard.kitTabs.Kit_Lion,"a chip per kit")
		assert(ui.leaderboard:shown() and #ui.leaderboard.drawn==L.ROWS+1 and not ui.leaderboard.empty.Visible,"the week's board")
		ui.leaderboard.tab="Rooftops";local rr=ui.leaderboard:draw()
		assert(#rr==1 and L.value(rr[1])=="0:42.30","the race's clock")
		ui.leaderboard.tab="Exam";ui.leaderboard:draw()
		assert(ui.leaderboard.empty.Visible,"an empty board says so")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (21/11, step 2 DESIGN) the two trees: the KIT tab with the kit's card, the
-- NINJA tab with the five natures in their colours; its buttons send the
-- ninja's commands.
test("the two trees: the kit's card, the natures, the ninja's commands",function()
	local Tree=H.load("Client/TreePanel")
	local NT=H.load("Shared/NinjaTree")
	local card=Tree.kitCard("Legion")
	assert(card and #card.starts>0 and card.signature~="","the kit's card")
	local view=NT.view(NT.new(),10)
	local layout=Tree.ninjaLayout(view)
	assert(#layout.natures==5 and #layout.branches==3,"five natures, three branches")
	assert(layout.natures[1].status=="learn","a nature to learn at 10 points")
	local d=Tree.ninjaDetail(view,"NatureFire")
	assert(d.action and d.action.kind=="learn" and d.counter:find("guard",1,true),"the fire card's detail")
	local r=NT.new();NT.learn(r,"NatureFire",10)
	local chosen=Tree.ninjaDetail(NT.view(r,10),"NatureFire")
	assert(chosen.status=="active" and chosen.action==nil,"the chosen nature")
	local locked=Tree.ninjaDetail(NT.view(NT.new(),0),"InfusedBlade")
	assert(locked.note and locked.note~="","a locked node says what opens it")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local sent={}
		local ui=UI.new(baseNew("PlayerGui"),function(action,payload) table.insert(sent,{action,payload}) end)
		local kits={state="ready",owned={Legion=true},mastery={Legion=0},starter="Legion",selected="Legion",masters={},trees={},ryo=0,style={owned={},equipped={}},ninja=view}
		local panel=ui.treePanel
		panel:show("Legion",kits)
		assert(panel:shown() and panel.tab=="kit","the KIT tab first")
		panel.tabs.ninja.click()
		assert(panel.tab=="ninja" and panel.tiles.NatureFire and panel.tiles.NatureWater,"the NINJA tab and its natures")
		assert(panel.selected=="NatureFire","a nature picked first")
		panel:press()
		assert(sent[#sent][1]=="NinjaLearn" and sent[#sent][2].node=="NatureFire","LEARN sends NinjaLearn")
		panel.tabs.kit.click();assert(panel.tab=="kit","back to the kit")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 21/11, vague 2 3) today's quests and the days in a row
test("today's quests: three rows, DONE stamped, the days in a row",function()
	local Q=H.load("Client/QuestPanel")
	local D=H.load("Shared/DailyQuests")
	local r=D.new()
	local view=D.view(r,D.DAY*100+3600)
	local rows=Q.rows(view)
	assert(#rows==3 and rows[1].fill==0 and rows[1].count:find("0 /",1,true),"three quests, none begun")
	assert(Q.done(view)==0,"none done")
	assert(Q.streakLine(view):find("FINISH A DUEL",1,true),"the streak says how to keep it")
	assert(Q.clock(3*3600+5*60)=="3 H 05","the clock")
	view.quests[1].done=true;view.quests[1].progress=view.quests[1].goal
	assert(Q.done(view)==1 and Q.rows(view)[1].done and Q.rows(view)[1].fill==1,"one done")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local panel=Q.new(UI.kit,baseNew("ScreenGui"))
		panel:show(view)
		assert(panel:shown() and #panel.drawn==3 and not panel.empty.Visible,"the page")
		panel:show(nil);assert(panel.empty.Visible,"no profile: it says so")
		panel.close.click();assert(not panel:shown(),"X closes")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 21/11, step 3) the first combat's coach: one prompt, its key,
-- NICE! when done, the old panel hidden
test("the coach: one prompt near the fight, its key, NICE! when done",function()
	local UI=H.load("Client/UI")
	local tut={id="guard",title="He strikes: guard",key="Hold F",pad="Hold L2",touch="Hold GUARD",coach=true,first=true,index=1,total=7}
	assert(UI.coachKey(tut,true,false)=="Hold GUARD" and UI.coachKey(tut,false,true)=="Hold L2","touch and pad words")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	UI=H.load("Client/UI")
	local ui=UI.new(baseNew("PlayerGui"),function() end)
	H.envBase.Instance=saved
	ui:coachPrompt(tut,{touch=false,gamepad=false})
	assert(ui.coach.Visible and ui.coachTitle.Text=="HE STRIKES: GUARD" and ui.coachCap.Visible and not ui.coachDone.Visible,"the prompt")
	tut.done=true;ui:coachPrompt(tut,{touch=false,gamepad=false})
	assert(ui.coachDone.Visible,"NICE! when done")
	ui:coachPrompt(tut,{touch=true})
	assert(not ui.coachCap.Visible and ui.coachTitle.Text:find("Hold GUARD",1,true),"a phone: the sentence")
	ui:coachPrompt(nil,{});assert(not ui.coach.Visible,"gone")
end)

-- (DESIGN 21/11, step 3) Konoha's minimap and big map, from KonohaLayout
test("the minimap: the village under the arrow, the places, the things to do",function()
	local Map=H.load("Client/MiniMap")
	local Layout=H.load("Shared/KonohaLayout")
	Layout.Origin=H.load("Shared/HubMap").Origin
	local x,z=Map.toBase(Layout.Origin+H.roblox.Vector3.new(0,0,13*(Layout.Scale or 1)))
	assert(math.abs(x)<1e-6 and math.abs(z-13)<1e-3,"world to base")
	local w,h=Map.extent(1);assert(w==2*Layout.HalfX and h==Layout.MaxZ-Layout.MinZ,"extent")
	assert(Map.nearest(0,12,60).id=="Plaza","the plaza is near the plaza")
	local todo=Map.todoList();assert(#todo>=3,"things to do: "..#todo)
	for _,t in todo do local found=false;for _,p in Layout.Pois do if p.id==t.id then found=true end end;assert(found,t.id) end
	assert(Map.kind({id="Hyuga",master="GentleFist"})=="master" and Map.kind({id="Training"})=="todo","seals")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		Map=H.load("Client/MiniMap")
		local map=Map.new(UI.kit,baseNew("ScreenGui"))
		map:setVisible(true)
		map:update(Layout.Origin,H.roblox.Vector3.new(0,0,-1))
		assert(map.placeLabel.Text=="THE PLAZA","the place under him: "..map.placeLabel.Text)
		-- (23/11, the OUTILLEUR's phones) upright, or the window no longer clips the village
		assert((map.mini.Rotation or 0)==0 and map.window.ClipsDescendants==true,"the minimap must stay upright and clip")
		map.mini.click();assert(map:shown(),"tap opens the big map")
		map.closeBig.click();assert(not map:shown(),"X closes it")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 23/11, step 4) the tournament's entry: a build of 100 points
test("the tournament's entry: the budget, what a node needs, ENTER sends the nodes",function()
	local E=H.load("Client/CupEntry")
	local TV=H.load("Shared/TreeView")
	local kit="Legion"
	local tree=TV.tree(kit)
	local free,needy=nil,nil
	for _,n in tree do
		if not free and #(n.Requires or {})==0 then free=n end
		if not needy and #(n.Requires or {})>0 then needy=n end
	end
	local nodes={}
	assert(E.toggle(kit,nodes,free.Id) and E.spent(kit,nodes)==free.Cost,"a free node taken")
	if needy then
		local ok=E.toggle(kit,{},needy.Id)
		assert(not ok and E.why(kit,{},needy.Id):find("^NEEDS"),"a node that needs another says so")
	end
	local all={}
	for _,n in tree do E.toggle(kit,all,n.Id) end
	assert(E.spent(kit,all)<=E.BUDGET,"never over the budget")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		E=H.load("Client/CupEntry")
		local sent={}
		local page=E.new(UI.kit,baseNew("ScreenGui"),function(a,p) table.insert(sent,{a,p}) end)
		page:show(kit,{active={free.Id}})
		assert(page:shown() and #page.nodes==1 and page.chips[free.Id],"his own build first")
		page.go.click()
		assert(sent[1][1]=="CupStart" and sent[1][2].nodes[1]==free.Id and sent[1][2].player==kit,"ENTER sends the nodes")
		page:show(kit,nil);page.best.click()
		assert(sent[2][2].nodes==nil,"BEST BUILD lets the server choose")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 23/11, step 5) the open shop: tabs with something in them, Ryō
-- confirmed, VIP first with its perks, retired passes gone
test("the open shop: no empty tab, BUY confirmed, VIP first",function()
	local Panel=H.load("Client/ShopPanel")
	local tabs=Panel.tabsFor("shop",{owned={},equipped={}})
	assert(tabs[1]=="KITS" and tabs[#tabs]=="RYŌ","the SHOP's ends")
	for _,name in tabs do
		local cat=Panel.CATEGORY[name]
		if cat then
			local n=0
			for _,slot in cat.slots do n+=#Shop.atCounter(slot,"shop",{owned={},equipped={}}) end
			assert(n>0,name.." is empty")
		end
	end
	local title,line=Panel.confirmLines("Vermilion kunai",1200,2000)
	assert(title=="BUY VERMILION KUNAI?" and line:find("800",1,true),"the confirmation: "..line)
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local sent={}
		local ui=UI.new(baseNew("PlayerGui"),function(a,p) table.insert(sent,{a,p}) end)
		local kits={state="ready",owned={Leaf=true},mastery={Leaf=0},starter="Leaf",selected="Leaf",masters={},trees={},ryo=999999,style={owned={},equipped={}},vip=true}
		local shop=ui.shopPanel
		shop:show(kits,"PASSES")
		assert(shop.heading.Text=="VIP & PASSES","the passes")
		local bought=false
		shop:confirm("X",100,500,function() bought=true end)
		assert(shop.confirmRoot and not bought,"asked first")
		shop.confirmNo.click();assert(shop.confirmRoot==nil and not bought,"CANCEL")
		shop:confirm("X",100,500,function() bought=true end);shop.confirmYes.click()
		assert(bought and shop.confirmRoot==nil,"BUY")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 23/11, step 5) SETTINGS and REPORT A PROBLEM
test("settings: sound and camera steps, the report sent with its place",function()
	local S=H.load("Client/SettingsPanel")
	assert(S.step(1,"volume",1)==1 and S.step(1,"volume",-1)==.9 and S.step(0,"volume",-1)==0,"the sound's steps")
	assert(S.step(.4,"sensitivity",-1)==.4 and S.step(1,"sensitivity",1)==1.2,"the camera's steps")
	assert(S.report("   ","x")==nil,"an empty report is not sent")
	assert(#S.report(string.rep("a",900),"x").text==S.MAX_REPORT,"capped")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		S=H.load("Client/SettingsPanel")
		local sent={}
		local page=S.new(UI.kit,baseNew("ScreenGui"),function(a,p) table.insert(sent,{a,p}) end)
		page:show("KONOHA • THE PLAZA")
		assert(page:shown() and not page.reportButton.Visible,"no REPORT outside the test place")
		page.volumeMinus.click();assert(page.volumeText.Text=="90%","SOUND −")
		page.forceReport=true;page:draw();assert(page.reportButton.Visible,"REPORT on the test place")
		page.reportButton.click();page.field.Text="Stuck on a roof";page.sendButton.click()
		assert(sent[1][1]=="Report" and sent[1][2].text=="Stuck on a roof" and sent[1][2].where=="KONOHA • THE PLAZA","the report")
		page.close.click();assert(not page:shown(),"X")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 23/11, passe 1) the racket: PAY, RUN, FIGHT; the fuse ends in a fight
test("the racket: three choices, PAY only with the Ryō, the fuse swings",function()
	local R=H.load("Client/RacketPanel")
	local l=R.lines({ask=120,win=200,lose=60,ryo=50})
	assert(not l.pay.ok and l.pay.sub:find("DON'T",1,true) and l.fight.sub:find("+200",1,true),"the lines")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		R=H.load("Client/RacketPanel")
		local sent={}
		local p=R.new(UI.kit,baseNew("ScreenGui"),function(a,b) table.insert(sent,{a,b}) end)
		p:show({id=7,name="Ryoji",line="Your Ryō or we fight.",ask=120,win=200,lose=60,ryo=50},0)
		assert(p:shown() and p.name.Text=="RYOJI","shown")
		p.buttons.pay.click();assert(#sent==0 and p:shown(),"no PAY without the Ryō")
		p.buttons.run.click();assert(sent[1][2].choice=="run" and not p:shown(),"RUN")
		p:show({id=8,ask=10,ryo=50,seconds=5},0);p:tick(6)
		assert(sent[2][2].choice=="fight" and sent[2][2].id==8,"the fuse ends in a FIGHT")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 26/11, DEC-053) the dare: bubble, then VS; THE 8; a thug's result line
test("the dare's bubble then VS, THE 8 board, the thug's result line",function()
	local UI=H.load("Client/UI")
	local dare={kit="Leaf",line="Let's go!",lineFor=1.6,vsFor=1.5,at=100}
	assert(UI.darePhase(dare,100.5)=="line" and UI.darePhase(dare,102)=="vs" and UI.darePhase(dare,103.5)==nil and UI.darePhase(dare,99)==nil,"its phases")
	assert(UI.thugLine({won=true,ryo=40})=="YOU TOOK HIS PURSE: +40 RYŌ" and UI.thugLine({won=false,ryo=-25})=="HE TOOK 25 RYŌ OFF YOU","the thug's line")
	local B=H.load("Client/EightBoard")
	local cards=B.cards({beaten={Leaf=true},count=1,need=8,order={"Legion","Leaf"}})
	assert(#cards==2 and not cards[1].beaten and cards[2].beaten,"the board's cards")
	assert(#B.cards(nil)==8,"the 8 without a profile")
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		UI=H.load("Client/UI")
		B=H.load("Client/EightBoard")
		local b=B.new(UI.kit,baseNew("ScreenGui"))
		b:show({beaten={Leaf=true},count=1,need=8})
		assert(b:shown() and b.score.Text=="1 / 8 BEATEN" and #b.drawn==8,"the board")
		b.close.click();assert(not b:shown(),"X")
		local ui=UI.new(baseNew("PlayerGui"),function() end)
		ui:buildDare()
		assert(ui.dareBubble and ui.dareVS and #ui.dareHeads==2,"the dare's pieces")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 26/11, passe 2) the gate's creation
test("the gate's creation: starter pieces, his own hair, ENTER sends Create",function()
	local C=H.load("Client/CreatorPanel")
	local hair=C.options("hair")
	assert(hair[1].id=="" and #hair>1,"his own hair first, then the styles")
	for _,slot in {"top","bottom","feet","headband"} do
		for _,o in C.options(slot) do assert(Shop.item(o.id).base,"only starter pieces: "..o.id) end
		assert(#C.options(slot)>0,slot)
	end
	local picks=C.defaults()
	local ids=C.wearing(picks)
	assert(ids~="" and not ids:find(",,",1,true),"what the preview wears: "..ids)
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		C=H.load("Client/CreatorPanel")
		local sent={}
		local c=C.new(UI.kit,baseNew("ScreenGui"),function(a,p) table.insert(sent,{a,p}) end)
		c:show();assert(c:shown() and c.step==1,"OUTFIT first")
		c.next.click();assert(c.step==2,"NEXT: HAIR")
		c.randomButton.click();assert(c.quip.Text~="","RANDOM says something")
		c:pick("hair",C.options("hair")[2].id)
		assert(c.quip.Text=="","a pick clears the quip")
		c.enter.click()
		assert(sent[1][1]=="Create" and sent[1][2].hair==C.options("hair")[2].id and sent[1][2].top~=nil and not c:shown(),"ENTER KONOHA")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (DESIGN 26/11, passe 3) the story's scenes, the challenge's words
test("a scene in bubbles: one at a time, then StorySeen; the challenge's prompt",function()
	local Mark=H.load("Client/ChallengeMark")
	local h,l=Mark.words(true,"Bob",3.2)
	assert(h=="CHALLENGE!" and l:find("HIT BACK",1,true) and l:find("4",1,true),"the struck one's prompt: "..l)
	H.workspace.GetAttribute=function() return nil end
	local saved=H.envBase.Instance
	local baseNew=harnessInstance.new
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
		return x
	end}
	local ok,err=pcall(function()
		local UI=H.load("Client/UI")
		local S=H.load("Client/StoryScene")
		local sent={}
		local sc=S.new(UI.kit,baseNew("ScreenGui"),function(a,p) table.insert(sent,{a,p}) end)
		local lines=S.lines("seals")
		assert(#lines>0,"the seals' scene has lines")
		sc:play("seals","CHAPTER 2")
		assert(sc:shown() and sc.line.Text==lines[1].line,"the first bubble")
		for _=1,#lines do sc:advance() end
		assert(not sc:shown() and sent[1][1]=="StorySeen" and sent[1][2].scene=="seals","seen at the end")
		sc:play("seals");sc.skip.click()
		assert(sent[2][1]=="StorySeen" and not sc:shown(),"SKIP")
	end)
	H.envBase.Instance=saved
	assert(ok,tostring(err))
end)

-- (15/11, DA v3 Mix-Shop) the STYLE preview: a still copy of his own avatar,
-- its scripts and its own outfit taken off, the character left as it was.
test("the STYLE preview: a still copy of his avatar, without its scripts nor its outfit",function()
	local Preview=H.load("Client/StylePreview")
	local Instance=roblox.Instance
	local character=Instance.new("Model");character.Archivable=false
	local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Parent=character
	local head=Instance.new("Part");head.Name="Head";head.Parent=character
	Instance.new("LocalScript").Parent=character
	local outfit=Instance.new("Model");outfit.Name="NinjaOutfit";outfit.Parent=character
	local copy=Preview.copy(character)
	assert(copy and copy:FindFirstChild("Head") and copy:FindFirstChild("Head").Anchored,"no still copy")
	assert(not copy:FindFirstChildOfClass("LocalScript") and not copy:FindFirstChild("NinjaOutfit"),"the copy kept a script or his outfit")
	assert(character.Archivable==false and character:FindFirstChild("NinjaOutfit"),"his own character was changed")
	assert(Preview.copy(nil)==nil,"a copy of nobody")
end)

test("the personalization (DEC-047): eight tabs, nothing empty, looks to earn given by their rule",function()
	local CatalogStyle=H.load("Shared/CatalogStyle")
	for _,tab in Shop.Tabs do
		local n=0
		for _,slot in tab.slots do assert(Shop.Slots[slot],tab.id..": unknown slot "..slot);n+=#Shop.inSlot(slot) end
		assert(n>=1,tab.id.." is empty")
	end
	for _,slot in {"hairColor","chakra","title","frame","aura"} do assert(#Shop.inSlot(slot)>=4,slot.." has too few looks") end
	local p=S.new("dev_style")
	assert(#CatalogStyle.earned(p,Shop.Items)==0,"a new profile has earned something")
	assert(not pcall(S.apply,p,p.sequence+1,"earnItem",{item="TitleGraduate"}),"a title given before its rule")
	p.merit={points=30,wins=1,pvpWins=0}
	local due=CatalogStyle.earned(p,Shop.Items)
	assert(table.find(due,"TitleGraduate") and table.find(due,"AuraEmber") and not table.find(due,"AuraStorm"),"the rules: "..table.concat(due,","))
	local np=S.apply(p,p.sequence+1,"earnItem",{item="TitleGraduate"});p=np
	assert(p.style.owned.TitleGraduate and S.validate(p),"the earned title")
	assert(not pcall(S.apply,p,p.sequence+1,"buyItem",{item="TitleStreet"}),"a title bought")
	p=S.apply(p,p.sequence+1,"equipItem",{item="TitleGraduate"})
	assert(p.style.equipped.title=="TitleGraduate","the title worn")
	local state=Shop.state(p.style,Shop.item("TitleStreet"),0,{})
	assert(state.kind=="earn" and state.how,"a look to earn does not say how")
	assert(CatalogStyle.color(Shop.item("ChakraCrimson"),"Chakra"),"the chakra's colour")
	-- (21/11) every pose and emote sold plays a clip the ANIMATEUR made
	local fs=require("@lune/fs")
	local clips=""
	for _,name in fs.readDir("src/Client") do
		if string.match(name,"^Authored.*%.luau$") then clips..=fs.readFile("src/Client/"..name) end
	end
	local poses,emotes=0,0
	for _,item in Shop.Items do
		if item.clip then
			assert(string.find(clips,'["'..item.clip..'"]',1,true),item.id.." plays "..item.clip..", a clip nobody made")
			if item.slot=="victory" then poses+=1 elseif item.slot=="emote" then emotes+=1 end
		end
	end
	assert(poses>=8 and emotes>=6,"poses "..poses..", emotes "..emotes)
end)

-- (23/11, step 5, DEC-049) the bundle's product id and the VIP pass
test("the eight outfits' bundle sells by its id once created, VIP marks the player",function()
	local bundle=Config.Shop.Bundles[1]
	assert(Progression.productFor(0)==nil or select(1,Progression.productFor(0))~="bundle","a bundle sold with no id")
	local saved=bundle.product
	bundle.product=987654
	local what,items=Progression.productFor(987654)
	bundle.product=saved
	assert(what=="bundle" and #items==8,"the bundle by its id")
	local attrs={}
	local player={UserId=1,SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
	local passes=Config.Shop.Passes
	local was=passes.VIP
	passes.VIP=1234
	Progression.passBought(player,1234)
	passes.VIP=was
	assert(attrs.NinjaVIP==true,"VIP bought in the game")
	attrs={}
	Progression.passBought(player,0)
	assert(attrs.NinjaVIP==nil,"no pass, no VIP")
	-- (23/11, the ANIMATEUR's CapeVIP, earned="vip") the cape comes with the
	-- pass, never sold: the profile marked once, the look then earned
	local Style=H.load("Shared/CatalogStyle")
	local cape=Shop.item("CapeVIP")
	assert(cape and cape.earned=="vip" and not cape.robux and not cape.ryo,"the VIP cape is sold, or missing")
	local p=S.new("dev_vip")
	assert(not table.find(Style.earned(p,Shop.Items),"CapeVIP"),"the VIP cape without the pass")
	S.Commands.setVip(p,{})
	assert(not pcall(S.Commands.setVip,p,{}),"VIP marked twice")
	assert(table.find(Style.earned(p,Shop.Items),"CapeVIP"),"no VIP cape with the pass")
	S.Commands.earnItem(p,{item="CapeVIP"})
	assert(p.style.owned.CapeVIP and S.validate(p),"the VIP cape not his, or the profile broken")
end)

-- (23/11, passe commune 1; François: « des PNJ peuvent vouloir se battre pour
-- me racketter ») the rogue ninjas of Konoha: a toll, a fight's purse, a walker
-- left alone a while after, their places the street duels'
test("the rogue ninjas: the toll or all he has, the fight's purse, never below nothing",function()
	local Thugs=H.load("Server/Thugs")
	assert(Thugs.toll(500)==Thugs.TOLL and Thugs.toll(12)==12 and Thugs.toll(0)==0,"the toll")
	assert(Thugs.purse(true,0)==Thugs.REWARD and Thugs.purse(false,500)==-Thugs.LOSS and Thugs.purse(false,5)==-5 and Thugs.purse(false,0)==0,"the purse")
	assert(Thugs.ready(nil,0) and not Thugs.ready(10,10+Thugs.COOLDOWN-1) and Thugs.ready(10,10+Thugs.COOLDOWN),"the cooldown")
	local spots=Thugs.spots({{key="b"},{key="a"},{key="c"}},2,{a=true})
	assert(#spots==2 and spots[1].key=="b" and spots[2].key=="c","their places")
	local p=S.new("dev_thug")
	p.wallet.ryo=25
	local r=S.Commands.payRyo(p,{amount=30})
	assert(p.wallet.ryo==0 and r.paid==25 and S.validate(p),"paid more than he had")
	assert(not pcall(S.Commands.payRyo,p,{amount=0}),"a toll of nothing")
	-- (23/11, passe 1) the DESIGN's racket panel: close, he is stopped; run
	-- far enough, he is let go; no answer, the fuse; caught running, a fight
	local offer=Thugs.offer("market",12)
	assert(offer.id=="market" and offer.ask==Thugs.TOLL and offer.win==Thugs.REWARD and offer.lose==12 and offer.seconds==Thugs.FUSE,"the panel's offer")
	local V=H.roblox.Vector3
	local function walker(x) local root={Position=V.new(x,0,0)};return {Parent=true,Character={FindFirstChild=function(_,n) return if n=="HumanoidRootPart" then root else nil end},root=root} end
	local fights={}
	local saved=Thugs.matches
	Thugs.matches={thugFight=function(_,player) table.insert(fights,player);return true end}
	Thugs.live={}
	local function rogue(key) local e={root={Position=V.zero},street={key=key},kit="Leaf"};Thugs.live[key]=e;return e end
	local function walking() return true end
	local a,b,c=walker(10),walker(12),walker(13)
	rogue("market")
	Thugs.racked={}
	Thugs.tick(100,{a},walking)
	assert(Thugs.pending[a] and Thugs.pending[a].entry.street.key=="market","close by: not stopped")
	assert(Thugs.answer(a,"market","run",100) and Thugs.pending[a].run,"the run")
	a.root.Position=V.new(Thugs.ESCAPE+1,0,0)
	Thugs.tick(101,{a},walking)
	assert(Thugs.pending[a]==nil and Thugs.racked[a]==101 and #fights==0,"far away: still held")
	rogue("market");Thugs.tick(102,{b},walking)
	Thugs.tick(102+Thugs.FUSE,{b},walking)
	assert(fights[1]==b and Thugs.pending[b]==nil,"no answer: no fight at the fuse")
	rogue("market");Thugs.tick(200,{c},walking)
	Thugs.answer(c,"market","run",200);Thugs.tick(200+Thugs.RUN_TIME,{c},walking)
	assert(fights[2]==c,"caught running: no fight")
	assert(not Thugs.answer(c,"market","pay"),"an answer with nothing asked")
	Thugs.matches=saved;Thugs.live={}
end)

-- (26/11, François at the gate: « on ne voit pas l'avatar en entier ») the
-- preview's lens takes in the whole body, in a tall card and a wide one
test("the style preview shows the whole avatar, head to feet, in any frame",function()
	local Preview=H.load("Client/StylePreview")
	local V3=H.V
	local half=math.rad(Preview.FOV/2)
	for _,case in {{size=V3.new(2,5.2,1),aspect=.69},{size=V3.new(4,7.5,2),aspect=.69},{size=V3.new(2,6,1),aspect=1.6},{size=V3.new(6,6,2),aspect=.5}} do
		local center=V3.new(0,3,0)
		local eye=Preview.fit(center,case.size,case.aspect)
		for _,y in {case.size.Y/2,-case.size.Y/2} do
			for _,x in {case.size.X/2,-case.size.X/2} do
				local p=eye:PointToObjectSpace(center+V3.new(x,y,-case.size.Z/2))
				assert(p.Z<0,"a corner behind the lens")
				local depth=-p.Z
				assert(math.abs(p.Y)/depth<=math.tan(half)+1e-6,"the head or the feet cut: "..tostring(case.size))
				assert(math.abs(p.X)/depth<=math.tan(half)*case.aspect+1e-6,"a side cut: "..tostring(case.size))
			end
		end
	end
end)

-- (26/11, passe 2, seen in the shop: the big avatar in his skin, a stride
-- frozen) the copy wears his outfit with the look pointed at in its slot, and
-- stands at rest
test("the style preview: his own outfit on, the look pointed at in its slot, standing at rest",function()
	local Preview=H.load("Client/StylePreview")
	local worn={"TopTunicBlack","BottomPantsSand","FeetSandals","HairCurtain"}
	local function has(list,id) return table.find(list,id)~=nil end
	local ids=Preview.ids(worn,nil)
	assert(#ids==4 and has(ids,"TopTunicBlack"),"his own outfit is not on the copy")
	ids=Preview.ids(worn,"TopTunicNavy")
	assert(has(ids,"TopTunicNavy") and not has(ids,"TopTunicBlack") and has(ids,"BottomPantsSand") and has(ids,"HairCurtain"),"a top pointed at: "..table.concat(ids,","))
	ids=Preview.ids(worn,"SetNaruto")
	assert(ids[1]=="SetNaruto" and not has(ids,"TopTunicBlack") and not has(ids,"BottomPantsSand") and has(ids,"HairCurtain"),"a master's outfit over his pieces: "..table.concat(ids,","))
	-- a piece over a master's outfit: never bare legs (the base outfit where nothing is)
	ids=Preview.ids({"SetNaruto","HairCurtain"},"TopTunicBlack")
	assert(has(ids,"TopTunicBlack") and not has(ids,"SetNaruto") and has(ids,Shop.BASE.bottom) and has(ids,Shop.BASE.feet) and not has(ids,Shop.BASE.top),"a top over a set: "..table.concat(ids,","))
	ids=Preview.ids({"SetNaruto"},"SetNone")
	assert(not has(ids,"SetNaruto") and has(ids,Shop.BASE.top) and has(ids,Shop.BASE.bottom),"his own pieces instead of a set: "..table.concat(ids,","))
	ids=Preview.ids(worn,"FeetNone")
	assert(not has(ids,"FeetSandals") and has(ids,"TopTunicBlack"),"bare feet pointed at")
	local same,paint=Preview.ids(worn,"HairFlame")
	assert(#same==4 and typeof(paint)=="Color3","a hair colour paints, the outfit stays")
	local _,own=Preview.ids(worn,"HairNatural")
	assert(own==false,"his own colour takes the paint off")
	local kept=Preview.ids(worn,"ChakraBlue")
	assert(#kept==4,"a look that is not worn on the body changes nothing")
	assert(Shop.BASE.top and Shop.item(Shop.BASE.top) and Shop.item(Shop.BASE.bottom) and Shop.item(Shop.BASE.feet),"the base outfit's pieces exist")
	-- standing at rest: a limb turned by the animation is put back where its joint holds it
	local Instance,CF=roblox.Instance,roblox.CFrame
	local Vector3new=roblox.Vector3.new
	local model=Instance.new("Model")
	local root=Instance.new("Part");root.Name="HumanoidRootPart";root.CFrame=CF.new(10,3,0);root.Parent=model
	local torso=Instance.new("Part");torso.Name="LowerTorso";torso.Parent=model
	local leg=Instance.new("Part");leg.Name="RightUpperLeg";leg.Parent=model
	local hip=Instance.new("Motor6D");hip.Part0=torso;hip.Part1=leg;hip.C0=CF.new(.5,-.2,0);hip.C1=CF.new(0,.4,0);hip.Parent=leg
	local rootJoint=Instance.new("Motor6D");rootJoint.Part0=root;rootJoint.Part1=torso;rootJoint.C0=CF.new(0,-1,0);rootJoint.C1=CF.new(0,0,0);rootJoint.Parent=torso
	torso.CFrame=CF.new(10,2,0)*CF.Angles(.4,0,0)
	leg.CFrame=CF.new(12,1,1)*CF.Angles(1.1,0,0)
	assert(Preview.rest(model)==2,"the copy's limbs were not put back")
	local want=CF.new(10,2,0)*CF.new(.5,-.2,0)*CF.new(0,.4,0):Inverse()
	assert((leg.CFrame.Position-want.Position).Magnitude<1e-4 and (torso.CFrame.Position-CF.new(10,2,0).Position).Magnitude<1e-4,"the leg does not stand at rest")
	local look=leg.CFrame.LookVector
	assert(math.abs(look.Y)<1e-4,"the leg kept its turn")
	-- the avatars' new joints (seen in the game: AnimationConstraints, no Motor6D)
	local body=Instance.new("Model")
	local root2=Instance.new("Part");root2.Name="HumanoidRootPart";root2.CFrame=CF.new(0,3,0);root2.Parent=body
	local arm=Instance.new("Part");arm.Name="RightUpperArm";arm.Parent=body
	local a0=Instance.new("Attachment");a0.CFrame=CF.new(1.5,.5,0);a0.Parent=root2
	local a1=Instance.new("Attachment");a1.CFrame=CF.new(0,.4,0);a1.Parent=arm
	local shoulder=Instance.new("AnimationConstraint");shoulder.Attachment0=a0;shoulder.Attachment1=a1;shoulder.Parent=arm
	arm.CFrame=CF.new(3,5,2)*CF.Angles(0,0,1.2)
	assert(Preview.rest(body)==1,"an AnimationConstraint's limb was not put back")
	assert((arm.CFrame.Position-Vector3new(1.5,3.1,0)).Magnitude<1e-4 and math.abs(arm.CFrame.RightVector.Y)<1e-4,"the arm does not hang at rest: "..tostring(arm.CFrame.Position))
end)

-- (DESIGN 27/11, fourth pass, after AC Shadows, Ghost of Tsushima, Sekiro)
-- one branch at a time as a tree: every node of every branch of every kit
-- has a place, none on another, the tiers climb from the foot (I) to the
-- top (III), each seal's name has room beside it, nothing leaves the page.
test("a branch as a tree: every seal placed, none overlapping, tiers climbing, names inside",function()
	local Tree=H.load("Client/TreePanel")
	local TV=H.load("Shared/TreeView")
	local Trees=H.load("Shared/SkillTrees")
	local NT=H.load("Shared/NinjaTree")
	local T=Tree.TREE
	local width=Tree.TREE_W-12
	local kits=0
	local function check(name,layout)
		for b,branch in layout.branches do
			local L=Tree.branchLayout(layout,b,width,592)
			for _,node in branch.nodes do
				local p=L.at[node.id]
				assert(p,name.." "..node.id.." has no place in its branch")
				local r=T.BIG/2
				assert(p.x-r>=0 and p.x+r<=width and p.y-r>=0 and p.y+r<=L.height,name.." "..node.id.." leaves the page")
				if not p.crown then
					local LW=T.OFF-r-24
					assert(LW>=130,"no room for the names")
					assert((p.side<0 and p.x-r-12-LW>=0) or (p.side>0 and p.x+r+12+LW<=width),name.." "..node.id..": its name leaves the page")
				end
			end
			local list={}
			for _,p in L.at do table.insert(list,p) end
			for i=1,#list do for j=i+1,#list do
				local a,c=list[i],list[j]
				assert(math.sqrt((a.x-c.x)^2+(a.y-c.y)^2)>=T.BIG+8,name.." "..branch.name..": "..a.node.id.." and "..c.node.id.." overlap")
				if a.t<c.t and not a.crown and not c.crown then assert(a.y>c.y,name..": tier "..a.t.." is not under tier "..c.t) end
			end end
			if L.crown then for _,p in L.at do if p~=L.crown then assert(L.crown.y<p.y,name..": the crown is not on top") end end end
		end
	end
	for kit in Trees do
		local layout=TV.layout(kit,{unlocked={},active={},points=0,free=0,mastery=0})
		if layout then kits+=1;check(kit,layout) end
	end
	check("Ninja",Tree.ninjaLayout(NT.view(NT.new(),0)))
	assert(kits>=8,"the eight kits' trees")
	-- what a seal says beside its name
	assert(Tree.sealState({status="learn",cost=4})=="LEARN  •  4 PTS" and Tree.sealState({status="active"})=="ON","the seal's words")
	local mine,all,can=Tree.branchCount({nodes={{status="active"},{status="off"},{status="learn"},{status="tier"}}})
	assert(mine==2 and all==4 and can==1,"a branch's count")
end)

test("each node's move (passe commune 4): the technique it names, its clips in order, the still at the blow",function()
	local Preview=H.load("Client/MovePreview")
	local SkillTrees=H.load("Shared/SkillTrees")
	local Authored=H.load("Client/AuthoredMotion")
	assert(#Preview.techs({Item="WindCut"})==1 and Preview.techs({Effects={{"tech.MarkedBlade.Range","mul",1.2}}})[1]=="MarkedBlade","the node's technique")
	assert(Preview.techs({Effects={{"def.Bodies.clone","set",true}}})[1]=="ShadowClone","the clone body")
	local has=function(n) return n=="Leaf.RemoveWeights.Channel" or n=="Leaf.RemoveWeights.Release" or n=="Leaf.Heavy" end
	local c=Preview.clips("Leaf",{Item="RemoveWeights"},has)
	assert(#c==2 and c[1]=="Leaf.RemoveWeights.Channel" and c[2]=="Leaf.RemoveWeights.Release","the parts in order: "..table.concat(c,","))
	assert(Preview.clips("Leaf",{Kind="stat"},has)[1]=="Leaf.Heavy","a number's node shows the kit's blow")
	assert(#Preview.clips("Leaf",{Kind="stat"},function() return false end)==0,"nothing authored: the icon stays")
	local len=function() return 1 end
	local still,at=Preview.still(c,len)
	assert(still=="Leaf.RemoveWeights.Release" and at==.5,"the still: the release's middle")
	local clip,t=Preview.at(c,len,1.25)
	assert(clip=="Leaf.RemoveWeights.Release" and math.abs(t-.25)<1e-6,"the loop's second clip")
	assert(Preview.at(c,len,2.25)=="Leaf.RemoveWeights.Release","the breath holds the last frame")
	assert(Preview.at(c,len,2.6)=="Leaf.RemoveWeights.Channel","the loop starts again")
	-- the real trees: most nodes of every kit show a real move of that kit
	local total,shown=0,0
	for kitId,tree in SkillTrees do
		if type(tree)=="table" and type(tree.Nodes)=="table" then
			for _,node in tree.Nodes do
				total+=1
				if #Preview.clips(kitId,node,Authored.has)>0 then shown+=1 end
			end
		end
	end
	assert(total>0 and shown/total>=.9,string.format("only %d of %d nodes show a move",shown,total))
end)

print(string.format("NinjaDuel shop and Ryō (13/11): %d PASS",passed))
