-- MY NINJA, the wardrobe (DESIGN 19/11, plan « vrai jeu » § 4 DESIGN 4: « tout
-- ce qu'on possède par emplacement, avec ton avatar qui tourne »). A page of
-- the manga (DA v3): on the left his own avatar turning in a case; in the
-- middle the slots, one band per slot (the slot open is the ink band); on the
-- right every piece of that slot as a card: the ones he can wear first (free
-- or owned), then the ones still to get, with where to get them (MARKET in
-- Ryō, SHOP in Robux). Wearing is the server's (EquipItem, as OutfitPanel);
-- nothing is bought here. The slots the catalogue does not have yet (mask,
-- cape, back, weapon, victory pose: DEV, Shared/Catalog) show greyed with
-- SOON, so the shape of the collection is visible from day one.
-- Presentation only. Opened by MY NINJA (the shop, OutfitPanel's ALL MY
-- THINGS); closed by X, B or Esc.
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Shop=require(Shared.Shop)

local W={}
W.__index=W
W.W,W.H=1180,660
-- The slots, in the order they are read (the future ones after).
W.SLOTS={"set","top","bottom","arms","feet","mask","cape","back","headband","kunai","shuriken","tanto","gourd"}
-- (19/11, DEV: the catalogue has mask, cape and back now; they leave W.FUTURE by themselves)
W.FUTURE={{id="mask",name="MASK"},{id="cape",name="CAPE"},{id="back",name="ON THE BACK"},{id="weapon",name="NINJA WEAPON"},{id="pose",name="VICTORY POSE"}}
W.CARD=152
W.COLS=4
-- The slot bands' column: its height (the avatar's case's), a band's pitch.
W.LIST_H=536
W.PITCH={max=50,min=42}
function W.pitch(n) return math.clamp(math.floor((W.LIST_H-8)/math.max(1,n)),W.PITCH.min,W.PITCH.max) end

-- Where an item is had: "worn", "owned" (free or bought), "market" (Ryō),
-- "shop" (Robux), or "earned" (a kit's tree, a master).
function W.state(style,item)
	local worn=style and style.equipped and style.equipped[item.slot]
	if worn==item.id then return "worn" end
	if item.base or (style and style.owned and style.owned[item.id]) then return "owned" end
	if item.ryo then return "market" end
	if item.robux then return "shop" end
	return "earned"
end

-- The items of a slot: what he can wear first, then the rest, catalogue order kept.
function W.items(style,slot)
	local mine,rest={},{}
	for _,item in Shop.inSlot(slot) do
		local s=W.state(style,item)
		table.insert(if s=="worn" or s=="owned" then mine else rest,item)
	end
	for _,item in rest do table.insert(mine,item) end
	return mine
end

-- How many of a slot he has (for the band: « TOP  3/5 »).
function W.count(style,slot)
	local have,all=0,0
	for _,item in Shop.inSlot(slot) do
		all+=1
		local s=W.state(style,item)
		if s=="worn" or s=="owned" then have+=1 end
	end
	return have,all
end

local function rgb(t) return Color3.fromRGB(t[1] or 0,t[2] or 0,t[3] or 0) end

function W.new(kit,gui,send,ui)
	local self=setmetatable({kit=kit,send=send,ui=ui,slot="top",tabs={},cards={}},W)
	local M=kit.MANGA
	self.M=M
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=74;self.root.Visible=false;self.root.Active=true
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(W.W,W.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=75
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.card=card
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		-- under Roblox's top bar; the whole card always in the window
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),W.W+24,W.H+24,1.15)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	self.scale=scale
	local function z(o,d) o.ZIndex=76+(d or 0);return o end
	z(kit.text(card,"MY NINJA",UDim2.fromOffset(28,14),UDim2.fromOffset(420,64),64,M.ink,kit.TITLE_FONT))
	z(kit.frame(card,UDim2.fromOffset(28,74),UDim2.fromOffset(220,6),M.red,0))
	self.sub=z(kit.text(card,"",UDim2.fromOffset(470,30),UDim2.fromOffset(560,40),18,M.mid or M.ink,kit.BODY_FONT,Enum.TextXAlignment.Right))
	-- close: big, in the corner (44 px and more on a phone after the scale)
	self.close=z(kit.button(card,"X",UDim2.fromOffset(W.W-92,14),UDim2.fromOffset(72,72),function() self:hide() end,M.ink),2)
	self.close.TextColor3=M.cream;self.close.TextSize=36
	-- the avatar's case, turning
	local case=z(kit.frame(card,UDim2.fromOffset(28,96),UDim2.fromOffset(330,536),M.cream,0))
	kit.create("UIStroke",case,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.case=case
	self.wornName=z(kit.text(case,"",UDim2.new(0,10,1,-58),UDim2.new(1,-20,0,48),20,M.ink,kit.STRONG_FONT,Enum.TextXAlignment.Center),3)
	self.wornName.TextWrapped=true
	local okP,Preview=pcall(function() return require(script.Parent.StylePreview) end)
	if okP and Preview then
		local made,preview=pcall(Preview.new,case,UDim2.fromOffset(0,0),UDim2.new(1,0,1,-60))
		if made then self.preview=preview end
	end
	-- the slot bands
	-- (26/11, passe 2, seen in the game: fifteen bands of 50 from the top ran
	-- 190 studs under the card, TANTO cut, GOURD and the slots to come off the
	-- window) As many as fit in the case's height, smaller down to a size a
	-- finger still takes, the rest by scrolling the column.
	local bands={}
	for _,slot in W.SLOTS do if Shop.Slots[slot] then table.insert(bands,{slot,Shop.Slots[slot].name}) end end
	for _,f in W.FUTURE do if not Shop.Slots[f.id] then table.insert(bands,{f.id,f.name,true}) end end
	local pitch=W.pitch(#bands)
	local column=kit.create("ScrollingFrame",card,{Position=UDim2.fromOffset(372,96),Size=UDim2.fromOffset(244,W.LIST_H),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=6,ScrollBarImageColor3=M.ink,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=76})
	self.column=column
	local y=4
	local function tab(id,name,future)
		local b=z(kit.button(column,"",UDim2.fromOffset(6,y),UDim2.fromOffset(220,pitch-4),function() if not future then self:open(id) end end,M.paper),1)
		b.AutoButtonColor=not future
		kit.create("UIStroke",b,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local label=z(kit.text(b,name,UDim2.fromOffset(12,0),UDim2.new(1,-80,1,0),18,M.ink,kit.STRONG_FONT),2)
		local count=z(kit.text(b,"",UDim2.new(1,-74,0,0),UDim2.new(0,64,1,0),16,M.mid or M.ink,kit.BODY_FONT,Enum.TextXAlignment.Right),2)
		if future then b.BackgroundColor3=M.back or M.paper;label.TextColor3=M.off or M.ink;count.Text="SOON" end
		self.tabs[id]={button=b,label=label,count=count,future=future}
		y+=pitch
	end
	for _,band in bands do tab(band[1],band[2],band[3]) end
	-- the pieces: a scrolling grid
	local grid=kit.create("ScrollingFrame",card,{Position=UDim2.fromOffset(618,96),Size=UDim2.fromOffset(W.W-646,536),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=8,ScrollBarImageColor3=M.ink,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=76})
	kit.create("UIGridLayout",grid,{CellSize=UDim2.fromOffset(W.CARD-24,W.CARD+18),CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder})
	kit.create("UIPadding",grid,{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4)})
	self.grid=grid
	-- (26/11, passe 2) the look pointed at is worn by the turning copy; out of
	-- the looks, he is shown as he is
	pcall(function()
		grid.MouseLeave:Connect(function()
			if self.root.Visible and self.preview then pcall(function() self.preview:show(nil,Players.LocalPlayer.Character) end) end
		end)
	end)
	pcall(function()
		UIS.InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	pcall(function()
		RunService.RenderStepped:Connect(function(dt) self:turn(dt) end)
	end)
	return self
end

function W:shown() return self.root.Visible end

function W:show(kits)
	if kits then self.kits=kits end
	if self.ui and self.ui.shopPanel and self.ui.shopPanel:shown() then self.ui.shopPanel:hide() end
	if self.ui and self.ui.outfitPanel and self.ui.outfitPanel.root and self.ui.outfitPanel.root.Visible then self.ui.outfitPanel:hide() end
	self.root.Visible=true
	if self.preview then pcall(function() self.preview:refresh(Players.LocalPlayer.Character) end) end
	self:draw()
	if UIS:GetLastInputType().Name:sub(1,7)=="Gamepad" then
		task.defer(function() pcall(function() GuiService.SelectedObject=self.tabs[self.slot].button end) end)
	end
end

function W:hide()
	if not self.root.Visible then return end
	self.root.Visible=false
	pcall(function()
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.card) then GuiService.SelectedObject=nil end
	end)
end

function W:refresh(kits)
	self.kits=kits
	if self.root.Visible then
		-- the server dressed him: the turning copy follows a moment later
		task.delay(.3,function() if self.preview and self.root.Visible then pcall(function() self.preview:refresh(Players.LocalPlayer.Character) end) end end)
		self:draw()
	end
end

function W:open(slot)
	self.slot=slot
	self:draw()
end

-- The avatar turns slowly, a full turn every 14 s.
function W:turn(dt)
	if not self.root.Visible or not self.preview or not self.preview.model then return end
	pcall(function()
		local model=self.preview.model
		model:PivotTo(model:GetPivot()*CFrame.Angles(0,dt*math.pi*2/14,0))
	end)
end

local SAY={worn="WORN",owned="WEAR IT",market="MARKET",shop="SHOP",earned="EARNED"}

function W:makeCard(item)
	local kit,M=self.kit,self.M
	local style=self.kits and self.kits.style
	local s=W.state(style,item)
	local mine=s=="worn" or s=="owned"
	local b=kit.button(self.grid,"",UDim2.new(),UDim2.new(),function()
		if s=="owned" then self.send("EquipItem",{item=item.id}) end
		if item.slot=="set" and self.preview then pcall(function() self.preview:show(item.id,Players.LocalPlayer.Character) end) end
	end,if s=="worn" then M.ink else M.paper)
	b.ZIndex=77;b.AutoButtonColor=mine
	-- (26/11, passe 2: the same as the shop) a look on the body pointed at (the
	-- mouse, a pad's selection) is worn by the turning copy over his outfit
	local info=Shop.Slots[item.slot]
	if self.preview and info and (info.outfit or item.slot=="headband") then
		pcall(function()
			local function point() pcall(function() self.preview:show(item.id,Players.LocalPlayer.Character) end) end
			b.MouseEnter:Connect(point)
			b.SelectionGained:Connect(point)
		end)
	end
	kit.create("UIStroke",b,{Color=if s=="worn" then M.red else M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	-- the swatch: its colours as two blocks (the item's icon once rendered)
	local sw=kit.frame(b,UDim2.fromOffset(10,10),UDim2.new(1,-20,0,74),M.cream,0)
	sw.ZIndex=78
	local colours={}
	for _,c in item.colors or {} do table.insert(colours,c) end
	if #colours==0 then sw.BackgroundColor3=M.back or M.cream end
	for i,c in colours do
		if i>3 then break end
		local part=kit.frame(sw,UDim2.fromScale((i-1)/math.min(#colours,3),0),UDim2.fromScale(1/math.min(#colours,3),1),rgb(c),0)
		part.ZIndex=79
	end
	if item.none then kit.text(sw,"NONE",UDim2.fromScale(0,0),UDim2.fromScale(1,1),20,M.off or M.ink,kit.STRONG_FONT,Enum.TextXAlignment.Center).ZIndex=80 end
	local name=kit.text(b,item.name or item.id,UDim2.fromOffset(8,88),UDim2.new(1,-16,0,40),16,if s=="worn" then M.cream else M.ink,kit.STRONG_FONT,Enum.TextXAlignment.Center)
	name.ZIndex=78;name.TextScaled=true;name.TextWrapped=true
	kit.create("UITextSizeConstraint",name,{MaxTextSize=17,MinTextSize=11})
	local tag=kit.text(b,SAY[s],UDim2.new(0,8,1,-34),UDim2.new(1,-16,0,26),15,M.cream,kit.STRONG_FONT,Enum.TextXAlignment.Center)
	tag.ZIndex=78;tag.BackgroundTransparency=0
	tag.BackgroundColor3=if s=="worn" then M.red elseif s=="owned" then M.ink else (M.off or M.ink)
	if s=="market" then tag.Text=string.format("MARKET  %s RYŌ",tostring(item.ryo)) end
	if not mine then b.BackgroundColor3=M.back or M.paper;name.TextColor3=M.mid or M.ink end
	return b,s
end

function W:draw()
	local style=self.kits and self.kits.style
	for id,t in self.tabs do
		if not t.future then
			local have,all=W.count(style,id)
			t.count.Text=string.format("%d/%d",have,all)
			local open=id==self.slot
			t.button.BackgroundColor3=if open then self.M.ink else self.M.paper
			t.label.TextColor3=if open then self.M.cream else self.M.ink
			t.count.TextColor3=if open then (self.M.redSoft or self.M.cream) else (self.M.mid or self.M.ink)
		end
	end
	for _,c in self.cards do c:Destroy() end
	table.clear(self.cards)
	local states={}
	for i,item in W.items(style,self.slot) do
		local b,s=self:makeCard(item)
		b.LayoutOrder=i
		table.insert(self.cards,b);states[item.id]=s
	end
	local worn=style and style.equipped and style.equipped[self.slot]
	local item=worn and Shop.item and Shop.item(worn)
	self.wornName.Text=if item then "WEARING  •  "..(item.name or worn) else "NOTHING IN THIS SLOT"
	local have,all=W.count(style,self.slot)
	self.sub.Text=string.format("%s  •  you have %d of %d",Shop.Slots[self.slot] and Shop.Slots[self.slot].name or self.slot,have,all)
	return states
end

return W
