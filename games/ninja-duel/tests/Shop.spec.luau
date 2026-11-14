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
local S=H.load("Server/ProfileSchema")
local Repo=H.load("Server/ProfileRepository")
local Config=H.load("Shared/Config")
local MastersView=H.load("Shared/MastersView")

test("the catalogue: every look has a slot, a price or is a base one, and every slot a base look",function()
	local seen={}
	for _,item in Shop.Items do
		assert(not seen[item.id],"twice: "..item.id);seen[item.id]=true
		assert(Shop.Slots[item.slot],item.id.." has no slot")
		assert(item.base or (item.ryo and item.ryo>0) or item.robux,item.id.." is neither base nor sold")
		assert(not (item.ryo and item.robux),item.id.." has two prices")
		if item.robux then assert((Config.Shop.Products or {})[item.robux]~=nil,item.id.."'s product is not in Config.Shop") end
		assert(item.none or item.colors,item.id.." has no colours")
	end
	for _,slot in Shop.SlotOrder do assert(Shop.default(slot),slot.." has no base look") end
	-- Never on sale: a kit by chance, a tree point (no such item can exist).
	for _,item in Shop.Items do assert(item.slot~="points" and item.slot~="kit") end
	assert(Shop.duelRyo({won=true,firstWinToday=true})==(Shop.Ryo.Finished+Shop.Ryo.Won)*2,"the first win of the day")
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
	assert(first.ryo==(Shop.Ryo.Finished+Shop.Ryo.Won)*2 and first.firstWin,"the day's first win: "..tostring(first.ryo))
	assert(string.find(MastersView.result(first),"FIRST WIN"),"the result does not say it")
	local second=duel(true)
	assert(second.ryo==Shop.Ryo.Finished+Shop.Ryo.Won and not second.firstWin,"a second win: "..tostring(second.ryo))
	local lost=duel(false)
	assert(lost.ryo==Shop.Ryo.Finished,"a lost duel: "..tostring(lost.ryo))
	local ryo=sent[player].kits.ryo
	assert(ryo==first.ryo+second.ryo+lost.ryo,"the wallet: "..tostring(ryo))
	-- The shop: a headband for Ryō, worn at once (a few days of duels).
	send("BuyItem",{item="HeadbandRed"})
	assert(sent[player].notice=="NOT ENOUGH RYŌ","the refusal for the screen: "..tostring(sent[player].notice))
	assert(Progression.run(player,"earnRyo",{amount=900}))
	ryo+=900
	send("BuyItem",{item="HeadbandRed"})
	local kits=sent[player].kits
	assert(kits.style.owned.HeadbandRed and kits.style.equipped.headband=="HeadbandRed" and kits.ryo==ryo-800,"the headband was not sold: "..tostring(sent[player].notice).." ryo "..tostring(kits.ryo).." of "..tostring(ryo))
	send("BuyItem",{item="KunaiBlack"})
	assert(sent[player].notice=="NOT ENOUGH RYŌ","a look too dear did not say why: "..tostring(sent[player].notice))
	send("EquipItem",{item="HeadbandNone"})
	assert(sent[player].kits.style.equipped.headband=="HeadbandNone")
	send("EquipItem",{item="HeadbandRed"})
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
	H.envBase.Instance={new=function(class)
		local x=baseNew(class)
		x.Activated={Connect=function(_,fn) x.click=fn end}
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
		for _,tab in {"KITS","WEAPONS","STYLE","PASSES","RYŌ"} do
			ui.shopPanel:show(kits,tab)
			assert(ui.shopPanel:shown() and #ui.shopPanel.drawn>0,tab.." drew nothing")
		end
		ui.treePanel:show("Leaf",kits)
		assert(ui.treePanel:shown() and ui.treePanel.tiles.Weights and ui.treePanel.tiles.HeavyDrop,"the tree's tiles")
		assert(ui.treePanel.selected,"no node picked on opening")
		-- Pressing the picked node's button asks the server.
		ui.treePanel.selected="WeightsTempo";ui.treePanel:detail();ui.treePanel:press()
		assert(sent[#sent].action=="LearnNode" and sent[#sent].extra.node=="WeightsTempo","the tree's button")
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

print(string.format("NinjaDuel shop and Ryō (13/11): %d PASS",passed))
