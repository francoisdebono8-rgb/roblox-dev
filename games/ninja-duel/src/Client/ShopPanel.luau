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
local HubMap=require(Shared.HubMap)
local Panel={}
Panel.__index=Panel

local W,H=1500,800
local SIDE=260
local TABS={"KITS","WEAPONS","STYLE","PASSES","RYŌ"}
Panel.CLOSE={X=W-170,Y=26,W=140,H=56}

local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
local function upper(s) return Text.upper(s or "") end
local function nameOf(id) local def=Fighters[id] return upper(def and def.Name or id) end
-- 1250 -> "1,250"
local function amount(n)
	local s=tostring(math.floor(n or 0))
	local out=s:reverse():gsub("(%d%d%d)","%1,"):reverse()
	return (out:gsub("^,",""))
end
Panel.amount=amount
local OFF=Color3.fromRGB(138,124,112)
local function mangaOf(kit) return kit.MANGA or {paper=Color3.fromRGB(255,253,248),back=Color3.fromRGB(242,235,221),ink=Color3.fromRGB(20,16,17),red=Color3.fromRGB(195,18,29),cream=Color3.fromRGB(246,238,222),redSoft=Color3.fromRGB(255,156,138),brown=Color3.fromRGB(94,79,67),mid=Color3.fromRGB(58,47,40),off=OFF} end
-- (DA v3, DESIGN, validated 14/11: Mix-Shop) one ink ring around a paper case
local function ring(kit,gui,thick) return kit.create("UIStroke",gui,{Color=mangaOf(kit).ink,Thickness=thick or 3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
-- A button of the page: "red" (the action), "ink", "paper" (ringed in ink) or
-- "off" (what cannot be pressed yet: grey, never red).
local function press(kit,parent,label,position,size,callback,kind)
	local M=mangaOf(kit)
	local back=if kind=="red" then M.red elseif kind=="ink" then M.ink elseif kind=="off" then (M.off or OFF) else M.paper
	local b=kit.button(parent,label,position,size,callback,back)
	b.Font=kit.STRONG_FONT or kit.BODY_FONT;b.TextSize=20
	b.TextColor3=if kind=="paper" then M.ink else M.cream
	if kind=="paper" then ring(kit,b,3) end
	if kind=="off" then b.AutoButtonColor=false end
	return b
end
Panel.press=press
-- A tag on a card's corner: WORN (red), OWNED (ink).
local function tagOn(kit,parent,label,color)
	local M=mangaOf(kit)
	local t=kit.text(parent,label,UDim2.new(1,-96,0,-10),UDim2.fromOffset(88,24),14,M.cream,kit.STRONG_FONT or kit.BODY_FONT,Enum.TextXAlignment.Center)
	t.BackgroundTransparency=0;t.BackgroundColor3=color;t.Rotation=3;t.ZIndex=(parent.ZIndex or 1)+3
	return t
end
-- (DA v3, Mix-Shop) a master's outfit drawn as a little figure in its colours:
-- the cloth where the set dresses a part, ink where it leaves the body bare.
local FIGURE={
	Head={.5,.02,.26,.16},UpperTorso={.5,.2,.4,.2},LowerTorso={.5,.4,.36,.1},
	LeftUpperArm={.22,.2,.12,.16},RightUpperArm={.78,.2,.12,.16},LeftLowerArm={.22,.36,.12,.14},RightLowerArm={.78,.36,.12,.14},
	LeftUpperLeg={.4,.5,.15,.2},RightUpperLeg={.6,.5,.15,.2},LeftLowerLeg={.4,.7,.15,.2},RightLowerLeg={.6,.7,.15,.2},
	LeftFoot={.38,.9,.19,.07},RightFoot={.62,.9,.19,.07},
}
local function dressedOf(item)
	local by={}
	for _,piece in item and item.pieces or {} do
		local color=item.colors and item.colors[piece.c]
		if color and not by[piece.on] and (piece.kind==nil or piece.kind=="vest" or piece.kind=="tail") then by[piece.on]=color end
	end
	return by
end
Panel.dressedOf=dressedOf
local function figure(kit,parent,item,position,size)
	local M=mangaOf(kit)
	local box=kit.frame(parent,position,size,M.paper,1)
	local by=dressedOf(item)
	for part,r in FIGURE do
		local key=part:gsub("^Left",""):gsub("^Right","")
		local color=by[key]
		local f=kit.frame(box,UDim2.fromScale(r[1],r[2]),UDim2.fromScale(r[3],r[4]),if color then Color3.fromRGB(color[1],color[2],color[3]) else M.ink,0)
		f.AnchorPoint=Vector2.new(.5,0)
		if part=="Head" then kit.corner(f,40) else kit.corner(f,3) end
	end
	return box
end

function Panel.new(kit,gui,send,onTree)
	local self=setmetatable({kit=kit,send=send,onTree=onTree,tab="KITS",drawn={}},Panel)
	local P,create,frame,text,button,corner=kit.palette,kit.create,kit.frame,kit.text,kit.button,kit.corner
	self.P=P
	local M=mangaOf(kit)
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	self.root=frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=73;self.root.Visible=false;self.root.Active=true
	-- (DA v3, DESIGN, validated 14/11: Mix-Shop) a page of the manga, not a
	-- dark frame: paper, an ink edge, one red for what you can do.
	local card=frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(W,H),M.back,0)
	corner(card,6);ring(kit,card,4)
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
	local side=frame(card,UDim2.fromOffset(0,0),UDim2.fromOffset(SIDE,H),M.paper,0)
	corner(side,6)
	self.side=side
	local seam=frame(card,UDim2.fromOffset(SIDE-2,0),UDim2.fromOffset(4,H),M.ink,0)
	seam.ZIndex=75
	self.title=text(side,"SHOP",UDim2.fromOffset(22,10),UDim2.fromOffset(SIDE-40,92),88,M.ink,kit.TITLE_FONT)
	local brush=frame(side,UDim2.fromOffset(26,94),UDim2.fromOffset(150,8),M.red,0);corner(brush,4);brush.Rotation=-2
	self.tabs={}
	self.tabMarks={}
	for i,name in TABS do
		local b=button(side,name,UDim2.fromOffset(16,120+(i-1)*62),UDim2.fromOffset(SIDE-32,52),function() self.tab=name;self:draw() end,M.paper)
		b.TextSize=24;b.Font=STRONG;b.TextColor3=M.ink;b.TextXAlignment=Enum.TextXAlignment.Left
		create("UIPadding",b,{PaddingLeft=UDim.new(0,20)})
		-- the open tab: a band of ink, its name in cream, a red mark at its edge
		local mark=frame(b,UDim2.fromOffset(0,6),UDim2.new(0,6,1,-12),M.red,0)
		mark.Visible=false
		self.tabs[name]=b
		self.tabMarks[name]=mark
	end
	local wallet=frame(side,UDim2.new(0,20,1,-110),UDim2.new(1,-40,0,84),M.paper,0)
	wallet.Rotation=2;ring(kit,wallet,3)
	text(wallet,"YOUR RYŌ",UDim2.fromOffset(16,10),UDim2.fromOffset(180,18),14,M.brown or M.ink,STRONG)
	self.ryo=text(wallet,"0",UDim2.fromOffset(16,30),UDim2.new(1,-32,0,44),40,M.ink,STRONG)
	-- The content.
	self.heading=text(card,"",UDim2.fromOffset(SIDE+40,18),UDim2.fromOffset(800,62),60,M.ink,kit.TITLE_FONT)
	self.headLine=frame(card,UDim2.fromOffset(SIDE+42,78),UDim2.fromOffset(180,7),M.red,0);corner(self.headLine,4);self.headLine.Rotation=-1
	self.subheading=text(card,"",UDim2.fromOffset(SIDE+42,88),UDim2.fromOffset(900,22),17,M.brown or M.ink,STRONG)
	press(kit,card,"CLOSE",UDim2.fromOffset(Panel.CLOSE.X,Panel.CLOSE.Y),UDim2.fromOffset(Panel.CLOSE.W,Panel.CLOSE.H),function() self:hide() end,"paper").TextSize=24
	self.body=frame(card,UDim2.fromOffset(SIDE+40,122),UDim2.fromOffset(W-SIDE-70,H-170),M.paper,1)
	self.footer=text(card,"",UDim2.fromOffset(SIDE+40,H-42),UDim2.fromOffset(W-SIDE-70,24),16,M.mid or M.ink,kit.BODY_FONT)
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
-- (14/11) A pad gets the focus on the open tab (no button of the shop could
-- be reached with a pad before) and gives it back when the shop closes.
function Panel.padFocus(target)
	pcall(function()
		if game:GetService("UserInputService"):GetLastInputType().Name:sub(1,7)~="Gamepad" then return end
		task.defer(function() pcall(function() game:GetService("GuiService").SelectedObject=target end) end)
	end)
end
function Panel.dropFocus(root)
	pcall(function()
		local GuiService=game:GetService("GuiService")
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(root) then GuiService.SelectedObject=nil end
	end)
end
function Panel:hide() self.root.Visible=false;Panel.dropFocus(self.root) end
-- (14/11, François: « tout ce qu'il y a dans la boutique, c'est des Robux. Et
-- on va créer une boutique propre au jeu avec des Ryō ») `counter`: "shop"
-- (the SHOP: kits, looks, passes and Ryō for Robux) or "market" (Konoha's
-- market: looks for Ryō, Server/Hub.placeMarket).
Panel.TABS={shop=TABS,market={"WEAPONS","STYLE"}}
function Panel:show(kits,tab,counter)
	self.kits=kits
	self.counter=counter or "shop"
	if tab then self.tab=tab end
	if not table.find(Panel.TABS[self.counter],self.tab) then self.tab=Panel.TABS[self.counter][1] end
	self:draw()
	self.root.Visible=true
	Panel.padFocus(self.tabs[self.tab])
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
	local counter=self.counter or "shop"
	self.title.Text=if counter=="market" then "MARKET" else "SHOP"
	local slot=0
	for _,name in TABS do
		local b=self.tabs[name]
		local on=name==self.tab
		b.Visible=table.find(Panel.TABS[counter],name)~=nil
		if b.Visible then b.Position=UDim2.fromOffset(20,100+slot*64);slot+=1 end
		b.BackgroundColor3=if on then self.M.ink else self.M.paper
		b.TextColor3=if on then self.M.cream else self.M.ink
		self.tabMarks[name].Visible=on
	end
	self.ryo.Text=amount(self.kits and self.kits.ryo or 0)
	self.footer.TextColor3=self.M.mid or self.M.ink
	if self.tab=="KITS" then self:drawKits()
	elseif self.tab=="WEAPONS" then self:drawLooks({"kunai","shuriken","tanto","gourd"},"WEAPONS","A look, never a number. Each kit keeps its own; the kit's objects (gourd, weights, tanto) are earned on its tree.")
	elseif self.tab=="STYLE" then
		-- (DEC-040) the masters' outfits on his own avatar, then the pieces;
		-- MY NINJA opens the outfit card (Client/OutfitPanel)
		self:drawLooks({"set","headband"},"STYLE","Your inspirations' outfits and ninja pieces over your own avatar, in Konoha and in every duel.")
		-- (Mix-Shop) his avatar in the side, wearing the outfit pointed at
		self:preview(nil)
		if self.onOutfit then
			local b=self:add(press(self.kit,self.card,"MY NINJA",UDim2.fromOffset(Panel.CLOSE.X-230,Panel.CLOSE.Y),UDim2.fromOffset(210,Panel.CLOSE.H),function() self:hide();self.onOutfit() end,"ink"))
			b.TextSize=24
		end
	elseif self.tab=="PASSES" then self:drawPasses()
	else self:drawRyo() end
	if self.stylePreview and self.tab~="STYLE" then self.stylePreview.view.Visible=false end
end

-- ------------------------------------------------------------------ kits
function Panel:drawKits()
	local K,M=self.kit,self.M
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	self.heading.Text="THE KITS"
	self.subheading.Text="Every kit is free in Konoha, from the ninja who inspires it. Here you save time."
	self.footer.Text="A kit bought comes with no tree points: its tree grows as you play it. Never a random draw."
	local kits=self.kits
	local products=Config.Progression and Config.Progression.Products or {}
	local cw,ch=(W-SIDE-70-3*16)/4,296
	for i,id in Masters.Kits do
		local col,row=(i-1)%4,math.floor((i-1)/4)
		local def=Fighters[id]
		local status=MastersView.status(kits,id)
		local act=MastersView.action(kits,id)
		local mine=status=="owned"
		local card=self:add(K.frame(self.body,UDim2.fromOffset(col*(cw+16),row*(ch+16)),UDim2.fromOffset(cw,ch),M.paper,0))
		K.corner(card,4)
		local edge=ring(K,card,if status=="master" then 4 else 3)
		if status=="master" then edge.Color=M.red end
		-- the kit in its own colour, the one colour a case keeps (like the avatar)
		local banner=K.frame(card,UDim2.fromOffset(6,6),UDim2.new(1,-12,0,108),rgb(def and def.Color or {120,120,120}),0);K.corner(banner,3)
		K.text(banner,nameOf(id),UDim2.fromOffset(12,62),UDim2.new(1,-24,0,44),42,M.ink,K.TITLE_FONT)
		if mine then tagOn(K,card,"YOURS",M.ink) elseif status=="master" then tagOn(K,card,"READY",M.red) end
		local tag=if status=="owned" then (if kits and kits.starter==id then "YOUR FIRST KIT" else "YOURS")
			elseif status=="master" then "READY FOR YOU" elseif status=="starter" then "A FIRST KIT" elseif status=="loading" then "…" elseif status=="open" then "OPEN" else "STILL CLOSED"
		K.text(card,tag,UDim2.fromOffset(14,124),UDim2.new(1,-28,0,20),15,if mine or status=="master" then M.red else (M.brown or M.ink),STRONG)
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
		elseif status=="starter" then
			-- (14/11) a new player looking here learns he can take it now, or
			-- meet its master in Konoha
			local spot=HubMap.Masters[id]
			line="Free: one of the three first kits. Take it here, or meet him: "..(if spot then Text.upper(spot.place) else "IN KONOHA").."."
		end
		local body=K.text(card,line,UDim2.fromOffset(14,148),UDim2.new(1,-28,0,80),16,M.mid or M.ink,K.BODY_FONT)
		body.TextYAlignment=Enum.TextYAlignment.Top
		-- The buttons.
		local rival=FirstMinute.rival(id) or "Lion"
		if status=="owned" then
			press(K,card,"SKILL TREE",UDim2.new(0,14,1,-58),UDim2.new(1,-28,0,44),function() if self.onTree then self.onTree(id) end end,"ink")
		elseif status=="starter" then
			-- (14/11) the first kit, taken in one press (DECISIONS: the first
			-- minute, the ninja chosen in one gesture); TRY beside it
			local take=press(K,card,"TAKE IT",UDim2.new(0,14,1,-58),UDim2.new(.58,-18,0,44),function() self.send("ChooseStarter",{player=id}) end,"red")
			take.Name="TakeStarter"
			press(K,card,"TRY",UDim2.new(.58,4,1,-58),UDim2.new(.42,-18,0,44),function()
				self.send("Tutorial",{player=id,bot=rival});self:hide()
			end,"paper")
		elseif status~="loading" and status~="open" then
			local product=products[id]
			local tryW=if product and product>0 then .42 else 1
			press(K,card,"TRY",UDim2.new(0,14,1,-58),UDim2.new(tryW,-(if tryW<1 then 18 else 28),0,44),function()
				self.send("Tutorial",{player=id,bot=rival});self:hide()
			end,"paper")
			if tryW<1 then
				press(K,card,"LEARN NOW",UDim2.new(.42,4,1,-58),UDim2.new(.58,-18,0,44),function() self.send("BuyKit",{player=id}) end,"red")
			end
		end
	end
end

-- ------------------------------------------------------------------ looks
-- (DA v3, Mix-Shop) what a look's button says and how it looks; `short`: the
-- Ryō it still lacks.
function Panel.lookButton(state,ryo)
	if state.kind=="equipped" then return "WORN","off" end
	if state.kind=="owned" then return "WEAR IT","paper" end
	if state.kind=="ryo" then
		if state.afford then return amount(state.price).." RYŌ","red" end
		return "NEED "..amount(state.price-(ryo or 0)).." MORE","off",state.price-(ryo or 0)
	end
	if state.kind=="robux" then return "BUY · ROBUX","red" end
	return "SOON","off"
end
function Panel:drawLooks(slots,title,sub)
	local K,M=self.kit,self.M
	local STRONG=K.STRONG_FONT or K.BODY_FONT
	self.heading.Text=title
	self.subheading.Text=sub
	self.footer.Text=if self.counter=="market" then "Ryō is earned in duels, against other players and in tournaments (the day's first win counts double)."
		else "Looks for Ryō are sold at Konoha's market. Robux looks show SOON until they are on sale."
	local kits=self.kits
	local ryo=kits and kits.ryo or 0
	local style=kits and kits.style
	local products=Config.Shop and Config.Shop.Products or {}
	local y=0
	local cw=210
	local shortest
	for _,slot in slots do
		local info=Shop.Slots[slot]
		local label=info.name..(if info.kit then "  •  "..nameOf(info.kit) else "")
		self:add(K.text(self.body,label,UDim2.fromOffset(0,y),UDim2.fromOffset(600,28),24,M.ink,K.TITLE_FONT))
		y+=34
		-- (DEC-040) a slot of many looks (the masters' outfits) wraps; an outfit
		-- shows its figure in the set's colours (Mix-Shop)
		local tall=info.outfit==true
		local ch=if tall then 190 else 128
		local perRow=math.max(1,math.floor((W-SIDE-70+14)/(cw+14)))
		for k,item in Shop.atCounter(slot,self.counter or "shop",style) do
			local state=Shop.state(style,item,ryo,products)
			local x=((k-1)%perRow)*(cw+14)
			if (k-1)%perRow==0 and k>1 then y+=ch+14 end
			local cell=self:add(K.frame(self.body,UDim2.fromOffset(x,y),UDim2.fromOffset(cw,ch),if state.kind=="equipped" then M.ink else M.paper,0))
			K.corner(cell,4)
			local edge=ring(K,cell,3)
			if state.kind=="equipped" then edge.Color=M.red;tagOn(K,cell,"WORN",M.red)
			elseif state.kind=="owned" then tagOn(K,cell,"OWNED",M.ink) end
			local ink=if state.kind=="equipped" then M.cream else M.ink
			local top=10
			if tall and item.pieces then
				figure(K,cell,item,UDim2.fromOffset(cw/2-34,8),UDim2.fromOffset(68,84))
				top=96
			else
				-- the swatch: the look's colours side by side
				local swatch=K.frame(cell,UDim2.fromOffset(12,12),UDim2.new(1,-24,0,34),M.ink,0);K.corner(swatch,3)
				local colors={}
				for _,key in {"Blade","Body","Band","Grip","Ring","Plate"} do if item.colors and item.colors[key] then table.insert(colors,item.colors[key]) end end
				if #colors==0 and item.colors then
					-- (an outfit piece: its cloth colours, in a stable order)
					local keys={}
					for key in item.colors do table.insert(keys,key) end
					table.sort(keys)
					for _,key in keys do table.insert(colors,item.colors[key]) end
				end
				if #colors==0 then colors={{40,38,44}} end
				for c,color in colors do
					K.frame(swatch,UDim2.new((c-1)/#colors,2,0,2),UDim2.new(1/#colors,-4,1,-4),rgb(color),0)
				end
				top=50
			end
			if item.kit then
				K.text(cell,nameOf(item.kit).." · INSPIRATION",UDim2.fromOffset(12,top),UDim2.new(1,-24,0,16),13,if state.kind=="equipped" then (M.redSoft or M.cream) else (M.brown or M.ink),STRONG)
				top+=16
			end
			local name=K.text(cell,item.name,UDim2.fromOffset(12,top),UDim2.new(1,-24,0,24),17,ink,STRONG)
			name.TextScaled=true
			K.create("UITextSizeConstraint",name,{MaxTextSize=17,MinTextSize=11})
			local text,kind,short=Panel.lookButton(state,ryo)
			if short and (shortest==nil or short<shortest) then shortest=short end
			local b=press(K,cell,text,UDim2.new(0,12,1,-46),UDim2.new(1,-24,0,36),function()
				if state.kind=="owned" then self.send("EquipItem",{item=item.id})
				elseif state.kind=="ryo" and state.afford then self.send("BuyItem",{item=item.id})
				elseif state.kind=="robux" then self.send("BuyRobux",{product=state.product}) end
			end,kind)
			b.TextSize=17
			-- (Mix-Shop) an outfit pointed at (the mouse, a pad's selection) is
			-- worn by the avatar in the side
			if info.outfit then
				pcall(function()
					cell.MouseEnter:Connect(function() self:preview(item.id) end)
					b.SelectionGained:Connect(function() self:preview(item.id) end)
				end)
			end
		end
		y+=ch+20
	end
	-- (Mix-Shop) what is missing, said once, with how to get it
	if shortest then
		self.footer.Text="You need "..amount(shortest).." more Ryō — win duels to earn them."
		self.footer.TextColor3=M.red
	end
	if title=="WEAPONS" then
		local how=self:add(K.frame(self.body,UDim2.fromOffset(0,y),UDim2.new(1,0,0,100),M.paper,0))
		K.corner(how,4);ring(K,how,3)
		local t=K.text(how,"IN A DUEL: every ninja carries a kunai (draw it, throw it; with chakra each kit makes something else of it). Sasuke and Itachi throw shuriken, Minato plants his marked kunai, Lee deflects blades. Gaara's gourd, Lee's weights and Kakashi's tanto are kit objects, earned on their tree.",
			UDim2.fromOffset(16,12),UDim2.new(1,-32,1,-24),16,M.mid or M.ink,K.BODY_FONT)
		t.TextYAlignment=Enum.TextYAlignment.Top
	end
end

-- (DA v3, Mix-Shop) the avatar in the side column of STYLE: `itemId` worn
-- (nil: his own outfit). Built the first time; no character, nothing shown.
function Panel:preview(itemId)
	local ok,err=pcall(function()
		local player=game:GetService("Players").LocalPlayer
		local character=player and player.Character
		if not self.stylePreview then
			local Preview=require(script.Parent.StylePreview)
			self.stylePreview=Preview.new(self.side,UDim2.fromOffset(16,440),UDim2.fromOffset(SIDE-32,230))
		end
		self.stylePreview.view.Visible=character~=nil
		if character then self.stylePreview:show(itemId,character) end
	end)
	return ok,err
end

-- ------------------------------------------------------------------ passes
function Panel:drawPasses()
	local K,M=self.kit,self.M
	self.heading.Text="PASSES"
	self.subheading.Text="Bought once, kept forever. Time and status, never a win."
	self.footer.Text="Ranked and tournament duels give everyone the prodigy's whole kit, on an equal budget."
	local ids=Config.Shop and Config.Shop.Passes or {}
	for i,pass in Shop.Passes do
		local id=if pass.id=="MasteryPass" then (Config.Progression and Config.Progression.MasteryPass or 0) else (ids[pass.id] or 0)
		local owned=pass.id=="MasteryPass" and self.kits and self.kits.boost
		local cell=self:add(K.frame(self.body,UDim2.fromOffset(0,(i-1)*114),UDim2.new(1,-8,0,100),M.paper,0))
		K.corner(cell,4)
		local edge=ring(K,cell,if i==1 then 4 else 3)
		if i==1 then edge.Color=M.red end
		K.text(cell,pass.name,UDim2.fromOffset(18,10),UDim2.fromOffset(600,38),34,M.ink,K.TITLE_FONT)
		local note=K.text(cell,pass.note,UDim2.fromOffset(18,50),UDim2.new(1,-260,0,42),16,M.mid or M.ink,K.BODY_FONT)
		note.TextYAlignment=Enum.TextYAlignment.Top
		if owned then tagOn(K,cell,"OWNED",M.ink) end
		local label=if owned then "YOURS" elseif id>0 then "BUY" else "SOON"
		press(K,cell,label,UDim2.new(1,-220,.5,-26),UDim2.fromOffset(200,52),function()
			if not owned and id>0 then self.send("BuyPass",{pass=pass.id}) end
		end,if id>0 and not owned then "red" else "off").TextSize=22
	end
end

-- ------------------------------------------------------------------ Ryō
function Panel:drawRyo()
	local K,M=self.kit,self.M
	self.heading.Text="RYŌ"
	self.subheading.Text="For looks only: never a kit, never a tree point."
	self.footer.Text="Ryō packs show SOON until they are on sale."
	local packs=Config.Shop and Config.Shop.RyoPacks or {}
	for i,pack in packs do
		local cell=self:add(K.frame(self.body,UDim2.fromOffset(0,(i-1)*98),UDim2.fromOffset(560,84),M.paper,0))
		K.corner(cell,4);ring(K,cell,3)
		K.text(cell,amount(pack.amount).." RYŌ",UDim2.fromOffset(18,20),UDim2.fromOffset(300,44),38,M.ink,K.TITLE_FONT)
		local on=(pack.product or 0)>0
		press(K,cell,if on then "BUY" else "SOON",UDim2.new(1,-180,.5,-24),UDim2.fromOffset(160,48),function()
			if on then self.send("BuyRobux",{product=pack.product}) end
		end,if on then "red" else "off").TextSize=22
	end
	local R=Shop.Ryo
	local earn=self:add(K.frame(self.body,UDim2.fromOffset(600,0),UDim2.fromOffset(560,300),M.ink,0))
	K.corner(earn,4);earn.Rotation=-1
	K.text(earn,"EARNED BY PLAYING",UDim2.fromOffset(18,14),UDim2.fromOffset(500,38),32,M.cream,K.TITLE_FONT)
	local lines={
		string.format("A duel finished: %d  •  won: +%d",R.Finished,R.Won),
		string.format("The day's first win: ×%d",R.FirstWinOfDay),
		string.format("His duel won (a new inspiration): +%d",R.MasterWon),
		string.format("Tournament: %d to the champion, %d to the finalist",R.Champion,R.Finalist),
	}
	for k,line in lines do K.text(earn,line,UDim2.fromOffset(18,60+(k-1)*32),UDim2.new(1,-36,0,26),17,M.cream,K.STRONG_FONT or K.BODY_FONT) end
end

return Panel
