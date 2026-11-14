-- The shop (13/11, user: « on voit tout ce qui est boutique, UI, design, […]
-- les armes »; design board « Ninja Duel : boutique, arbres et armes »). Five
-- tabs down the left, the player's Ryō under them:
--   KITS     the eight kits: yours, a master who teaches you now, the way to a
--            closed one; try it, or learn it at once for Robux (when sold);
--   WEAPONS  the looks of the kunai, the shuriken, Kakashi's tanto, Gaara's
--            gourd (a look, never a number), and how weapons work in a duel;
--   STYLE    the headband over your own avatar;
--   PASSES   2x mastery, VIP, early access, more builds;
--   RYŌ      packs, and what playing pays.
-- Every decision is the server's (Matches: BuyItem, EquipItem, BuyRobux,
-- BuyPass, BuyKit, Tutorial); prices and states come from Shared/Shop over
-- the server's Progression view. Opened from Konoha's HUD and the roster.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Shop=require(Shared.Shop)
local MastersView=require(Shared.MastersView)
local Masters=require(Shared.Masters)
local Fighters=require(Shared.Fighters)
local Text=require(Shared.Text)
local Config=require(Shared.Config)
local FirstMinute=require(Shared.FirstMinute)
local Panel={}
Panel.__index=Panel

local W,H=1500,800
local SIDE=260
local TABS={"KITS","WEAPONS","STYLE","PASSES","RYŌ"}
Panel.CLOSE={X=W-170,Y=26,W=140,H=56}

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
local function upper(s) return Text.upper(s or "") end
local function nameOf(id) local def=Fighters[id] return upper(def and def.Name or id) end

function Panel.new(kit,gui,send,onTree)
	local self=setmetatable({kit=kit,send=send,onTree=onTree,tab="KITS",drawn={}},Panel)
	local P,create,frame,text,button,corner=kit.palette,kit.create,kit.frame,kit.text,kit.button,kit.corner
	self.P=P
	self.root=frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(6,5,8),.2)
	self.root.ZIndex=73;self.root.Visible=false;self.root.Active=true
	local card=kit.inkCard(frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(W,H),kit.CARD,0))
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=74
	self.card=card
	local scale=create("UIScale",card,{Scale=1})
	-- (14/11, a reader's report on PR #84) the card fits any window: no floor
	-- that pushes CLOSE off a narrow or portrait one (Panel.fit); small, a
	-- close mark anchored in the window's corner, and the pad's B closes.
	self.corner=kit.cornerClose(self.root,function() self:hide() end)
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=Panel.fit(v,kit)
		self.corner.Visible=scale.Scale<kit.SMALL
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.KeyCode==Enum.KeyCode.ButtonB and self.root.Visible then self:hide() end
		end)
	end)
	-- The side: the tabs and the Ryō.
	local side=frame(card,UDim2.fromOffset(0,5),UDim2.fromOffset(SIDE,H-5),P.ink,.35)
	kit.inkTitle(text(side,"SHOP",UDim2.fromOffset(24,24),UDim2.fromOffset(SIDE-48,56),54,P.paper,kit.TITLE_FONT))
	self.tabs={}
	for i,name in TABS do
		local b=button(side,name,UDim2.fromOffset(20,100+(i-1)*64),UDim2.fromOffset(SIDE-40,54),function() self.tab=name;self:draw() end)
		b.TextSize=26;b.TextXAlignment=Enum.TextXAlignment.Left
		create("UIPadding",b,{PaddingLeft=UDim.new(0,18)})
		self.tabs[name]=b
	end
	local wallet=frame(side,UDim2.new(0,20,1,-104),UDim2.new(1,-40,0,80),P.ink,0);corner(wallet,10)
	text(wallet,"YOUR RYŌ",UDim2.fromOffset(16,10),UDim2.fromOffset(180,16),11,P.muted,kit.BODY_FONT)
	self.ryo=text(wallet,"0",UDim2.fromOffset(16,28),UDim2.fromOffset(190,40),36,P.gold,kit.TITLE_FONT)
	-- The content.
	self.heading=kit.inkTitle(text(card,"",UDim2.fromOffset(SIDE+40,26),UDim2.fromOffset(800,50),46,P.paper,kit.TITLE_FONT))
	self.subheading=text(card,"",UDim2.fromOffset(SIDE+42,76),UDim2.fromOffset(900,22),15,P.gold,kit.BODY_FONT)
	button(card,"CLOSE",UDim2.fromOffset(Panel.CLOSE.X,Panel.CLOSE.Y),UDim2.fromOffset(Panel.CLOSE.W,Panel.CLOSE.H),function() self:hide() end,P.red)
	self.body=frame(card,UDim2.fromOffset(SIDE+40,112),UDim2.fromOffset(W-SIDE-70,H-160),P.ink,1)
	self.footer=text(card,"",UDim2.fromOffset(SIDE+40,H-40),UDim2.fromOffset(W-SIDE-70,20),12,P.muted,kit.BODY_FONT)
	return self
end

-- The card's scale in a window of `viewport` pixels (it always fits).
function Panel.fit(viewport,kit) return kit.fitScale(viewport,W+60,H+40,1.2) end
-- Where CLOSE sits in the window, for the suites: {x, y, w, h} in pixels.
function Panel.closeRect(viewport,kit)
	local s=Panel.fit(viewport,kit)
	local left,top=viewport.X/2-W*s/2,viewport.Y/2-H*s/2
	return {x=left+Panel.CLOSE.X*s,y=top+Panel.CLOSE.Y*s,w=Panel.CLOSE.W*s,h=Panel.CLOSE.H*s,scale=s}
end
function Panel:shown() return self.root.Visible end
function Panel:hide() self.root.Visible=false end
function Panel:show(kits,tab)
	self.kits=kits
	if tab then self.tab=tab end
	self:draw()
	self.root.Visible=true
end
function Panel:refresh(kits)
	self.kits=kits
	if self.root.Visible then self:draw() end
end

function Panel:add(item) table.insert(self.drawn,item);return item end
function Panel:draw()
	for _,item in self.drawn do item:Destroy() end
	self.drawn={}
	local P=self.P
	for name,b in self.tabs do
		local on=name==self.tab
		b.BackgroundColor3=if on then P.red else P.panel
		b.TextColor3=if on then P.paper else P.text
	end
	self.ryo.Text=tostring(self.kits and self.kits.ryo or 0)
	if self.tab=="KITS" then self:drawKits()
	elseif self.tab=="WEAPONS" then self:drawLooks({"kunai","shuriken","tanto","gourd"},"WEAPONS","A look, never a number. Each kit keeps its own; the kit's objects (gourd, weights, tanto) are earned on its tree.")
	elseif self.tab=="STYLE" then self:drawLooks({"headband"},"STYLE","Ninja pieces over your own Roblox avatar, in Konoha and in the duel. What you own on Roblox stays yours.")
	elseif self.tab=="PASSES" then self:drawPasses()
	else self:drawRyo() end
end

-- ------------------------------------------------------------------ kits
function Panel:drawKits()
	local K,P=self.kit,self.P
	self.heading.Text="THE KITS"
	self.subheading.Text="Every kit is taught for free by its master in Konoha. Here you save time."
	self.footer.Text="A kit bought comes with no tree points: its tree grows as you play it. Never a random draw."
	local kits=self.kits
	local products=Config.Progression and Config.Progression.Products or {}
	local cw,ch=(W-SIDE-70-3*16)/4,300
	for i,id in Masters.Kits do
		local col,row=(i-1)%4,math.floor((i-1)/4)
		local def=Fighters[id]
		local status=MastersView.status(kits,id)
		local act=MastersView.action(kits,id)
		local card=self:add(K.frame(self.body,UDim2.fromOffset(col*(cw+16),row*(ch+16)),UDim2.fromOffset(cw,ch),P.panel,0))
		K.corner(card,12)
		if status=="owned" or status=="master" then K.create("UIStroke",card,{Color=if status=="owned" then P.gold else P.red,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
		local banner=K.frame(card,UDim2.fromOffset(0,0),UDim2.new(1,0,0,120),rgb(def and def.Color or {120,120,120}),0);K.corner(banner,12)
		K.text(banner,nameOf(id),UDim2.fromOffset(14,70),UDim2.new(1,-28,0,44),40,P.ink,K.TITLE_FONT)
		local tag=if status=="owned" then (if kits and kits.starter==id then "YOUR FIRST KIT" else "YOURS")
			elseif status=="master" then "HE TEACHES YOU NOW" elseif status=="starter" then "A FIRST KIT" elseif status=="loading" then "…" elseif status=="open" then "OPEN" else "STILL CLOSED"
		K.text(card,tag,UDim2.fromOffset(14,130),UDim2.new(1,-28,0,18),12,if status=="owned" or status=="master" then P.gold else P.muted,K.BODY_FONT)
		local line=""
		if status=="owned" then
			local tree=kits.trees and kits.trees[id]
			line=string.format("Mastery %d  •  %d free points",kits.mastery and kits.mastery[id] or 0,tree and tree.free or 0)
		elseif status=="master" then line="Free: beat him in his duel, at his home in Konoha, with "..nameOf(act.via).."."
		elseif status=="locked" or status=="starterLocked" then
			local rule=Masters.Map[id]
			local from={}
			for _,other in rule and rule.from or {} do table.insert(from,nameOf(other)) end
			line=if status=="starterLocked" then "Take a first kit first." else "His master asks "..Masters.Need.." mastery with "..table.concat(from," or ").."."
		elseif status=="starter" then line="Free: one of the three first kits." end
		local body=K.text(card,line,UDim2.fromOffset(14,152),UDim2.new(1,-28,0,60),13,P.text,K.BODY_FONT)
		body.TextYAlignment=Enum.TextYAlignment.Top
		-- The buttons.
		local rival=FirstMinute.rival(id) or "Lion"
		if status=="owned" then
			K.button(card,"SKILL TREE",UDim2.new(0,14,1,-58),UDim2.new(1,-28,0,44),function() if self.onTree then self.onTree(id) end end)
		elseif status~="loading" and status~="open" then
			local product=products[id]
			local tryW=if product and product>0 and status~="starter" then .42 else 1
			K.button(card,"TRY",UDim2.new(0,14,1,-58),UDim2.new(tryW,-(if tryW<1 then 18 else 28),0,44),function()
				self.send("Tutorial",{player=id,bot=rival});self:hide()
			end)
			if tryW<1 then
				local buy=K.button(card,"LEARN NOW",UDim2.new(.42,4,1,-58),UDim2.new(.58,-18,0,44),function() self.send("BuyKit",{player=id}) end,P.gold)
				buy.TextColor3=P.ink
			end
		end
	end
end

-- ------------------------------------------------------------------ looks
function Panel:drawLooks(slots,title,sub)
	local K,P=self.kit,self.P
	self.heading.Text=title
	self.subheading.Text=sub
	self.footer.Text="Ryō is earned in duels (the day's first win counts double) or bought in packs. Robux looks show SOON until they are on sale."
	local kits=self.kits
	local style=kits and kits.style
	local products=Config.Shop and Config.Shop.Products or {}
	local y=0
	local cw=210
	for _,slot in slots do
		local info=Shop.Slots[slot]
		local label=info.name..(if info.kit then "  •  "..nameOf(info.kit) else "")
		self:add(K.text(self.body,label,UDim2.fromOffset(0,y),UDim2.fromOffset(600,26),22,P.gold,K.TITLE_FONT))
		y+=32
		for k,item in Shop.inSlot(slot) do
			local state=Shop.state(style,item,kits and kits.ryo or 0,products)
			local x=(k-1)*(cw+14)
			local cell=self:add(K.frame(self.body,UDim2.fromOffset(x,y),UDim2.fromOffset(cw,128),P.panel,0))
			K.corner(cell,10)
			if state.kind=="equipped" then K.create("UIStroke",cell,{Color=P.gold,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
			-- The swatch: the look's colours side by side.
			local swatch=K.frame(cell,UDim2.fromOffset(12,12),UDim2.new(1,-24,0,34),P.ink,0);K.corner(swatch,6)
			local colors={}
			for _,key in {"Blade","Body","Band","Grip","Ring","Plate"} do if item.colors and item.colors[key] then table.insert(colors,item.colors[key]) end end
			if #colors==0 then colors={{40,38,44}} end
			for c,color in colors do
				K.frame(swatch,UDim2.new((c-1)/#colors,2,0,2),UDim2.new(1/#colors,-4,1,-4),rgb(color),0)
			end
			K.text(cell,item.name,UDim2.fromOffset(12,52),UDim2.new(1,-24,0,18),13,P.text,K.BODY_FONT)
			local label=state.label
			if state.kind=="ryo" and not state.afford then label="NEED "..state.price.." RYŌ" end
			local color=if state.kind=="ryo" and state.afford then P.gold elseif state.kind=="robux" then P.red elseif state.kind=="owned" then P.panel else P.ink
			local b=K.button(cell,label,UDim2.fromOffset(12,80),UDim2.new(1,-24,0,36),function()
				if state.kind=="owned" then self.send("EquipItem",{item=item.id})
				elseif state.kind=="ryo" and state.afford then self.send("BuyItem",{item=item.id})
				elseif state.kind=="robux" then self.send("BuyRobux",{product=state.product}) end
			end,color)
			b.TextSize=18
			if state.kind=="ryo" and state.afford then b.TextColor3=P.ink end
			if state.kind=="equipped" or state.kind=="soon" or (state.kind=="ryo" and not state.afford) then b.AutoButtonColor=false;b.TextColor3=P.muted end
		end
		y+=148
	end
	if title=="WEAPONS" then
		local how=self:add(K.frame(self.body,UDim2.fromOffset(0,y),UDim2.new(1,0,0,96),P.panel,0))
		K.corner(how,10)
		local t=K.text(how,"IN A DUEL: every ninja carries a kunai (draw it, throw it; with chakra each kit makes something else of it). Sasuke and Itachi throw shuriken, Minato plants his marked kunai, Lee deflects blades. Gaara's gourd, Lee's weights and Kakashi's tanto are kit objects, earned on their tree.",
			UDim2.fromOffset(16,12),UDim2.new(1,-32,1,-24),14,P.text,K.BODY_FONT)
		t.TextYAlignment=Enum.TextYAlignment.Top
	end
end

-- ------------------------------------------------------------------ passes
function Panel:drawPasses()
	local K,P=self.kit,self.P
	self.heading.Text="PASSES"
	self.subheading.Text="Bought once, kept forever. Time and status, never a win."
	self.footer.Text="Ranked and tournament duels give everyone the prodigy's whole kit, on an equal budget."
	local ids=Config.Shop and Config.Shop.Passes or {}
	for i,pass in Shop.Passes do
		local id=if pass.id=="MasteryPass" then (Config.Progression and Config.Progression.MasteryPass or 0) else (ids[pass.id] or 0)
		local owned=pass.id=="MasteryPass" and self.kits and self.kits.boost
		local cell=self:add(K.frame(self.body,UDim2.fromOffset(0,(i-1)*112),UDim2.new(1,0,0,100),P.panel,0))
		K.corner(cell,10)
		if i==1 then K.create("UIStroke",cell,{Color=P.red,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
		K.text(cell,pass.name,UDim2.fromOffset(18,12),UDim2.fromOffset(500,34),30,P.paper,K.TITLE_FONT)
		local note=K.text(cell,pass.note,UDim2.fromOffset(18,50),UDim2.new(1,-260,0,40),14,P.text,K.BODY_FONT)
		note.TextYAlignment=Enum.TextYAlignment.Top
		local label=if owned then "YOURS" elseif id>0 then "BUY" else "SOON"
		local b=K.button(cell,label,UDim2.new(1,-220,.5,-26),UDim2.fromOffset(200,52),function()
			if not owned and id>0 then self.send("BuyPass",{pass=pass.id}) end
		end,if id>0 and not owned then P.gold else P.ink)
		if id>0 and not owned then b.TextColor3=P.ink else b.TextColor3=P.muted;b.AutoButtonColor=false end
	end
end

-- ------------------------------------------------------------------ Ryō
function Panel:drawRyo()
	local K,P=self.kit,self.P
	self.heading.Text="RYŌ"
	self.subheading.Text="For looks only: never a kit, never a tree point."
	self.footer.Text="Ryō packs show SOON until they are on sale."
	local packs=Config.Shop and Config.Shop.RyoPacks or {}
	for i,pack in packs do
		local cell=self:add(K.frame(self.body,UDim2.fromOffset(0,(i-1)*96),UDim2.fromOffset(560,84),P.panel,0))
		K.corner(cell,10)
		K.text(cell,pack.amount.." RYŌ",UDim2.fromOffset(18,20),UDim2.fromOffset(300,44),34,P.gold,K.TITLE_FONT)
		local on=(pack.product or 0)>0
		local b=K.button(cell,if on then "BUY" else "SOON",UDim2.new(1,-180,.5,-24),UDim2.fromOffset(160,48),function()
			if on then self.send("BuyRobux",{product=pack.product}) end
		end,if on then P.gold else P.ink)
		b.TextColor3=if on then P.ink else P.muted
	end
	local R=Shop.Ryo
	local earn=self:add(K.frame(self.body,UDim2.fromOffset(600,0),UDim2.fromOffset(560,300),P.panel,0))
	K.corner(earn,10)
	K.text(earn,"EARNED BY PLAYING",UDim2.fromOffset(18,14),UDim2.fromOffset(500,34),28,P.paper,K.TITLE_FONT)
	local lines={
		string.format("A duel finished: %d  •  won: +%d",R.Finished,R.Won),
		string.format("The day's first win: ×%d",R.FirstWinOfDay),
		string.format("A master's duel won: +%d",R.MasterWon),
		string.format("Tournament: %d to the champion, %d to the finalist (soon)",R.Champion,R.Finalist),
	}
	for k,line in lines do K.text(earn,line,UDim2.fromOffset(18,56+(k-1)*30),UDim2.new(1,-36,0,24),15,P.text,K.BODY_FONT) end
end

return Panel
