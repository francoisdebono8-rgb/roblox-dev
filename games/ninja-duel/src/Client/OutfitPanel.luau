-- His ninja (DEC-040, user 14/11: « il arrive genre nu et on ait un petit truc
-- de customisation de personnage. Genre au début on propose des trucs simples
-- mais qui font un peu de tenue ninja »). His own avatar arrives in Konoha
-- without its clothes (Server/Outfit); this card, on the left, lets him pick
-- what he wears, piece by piece (top, bottom, arms, feet, headband; a master's
-- outfit once he owns one), the camera on his face so he sees it change on
-- him. Every change is the server's (EquipItem: a free piece or one he owns).
-- It opens by itself on his first walk in the village, until he has a top;
-- the shop's STYLE tab opens it again.
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Shop=require(Shared.Shop)
local Panel={}
Panel.__index=Panel
Panel.W,Panel.H=440,600
-- The rows, top to bottom (`set` only once he owns a master's outfit).
Panel.ROWS={"set","top","bottom","arms","feet","headband"}

-- What he can wear in a slot: the free pieces and the ones he owns, in the
-- catalogue's order (`set`: his own pieces first).
function Panel.options(style,slot)
	local out={}
	for _,item in Shop.inSlot(slot) do
		if item.base or (style and style.owned and style.owned[item.id]) then table.insert(out,item) end
	end
	return out
end
-- The piece after (step 1) or before (-1) the one worn in `slot`.
function Panel.cycle(style,slot,step)
	local options=Panel.options(style,slot)
	if #options==0 then return nil end
	local worn=style and style.equipped and style.equipped[slot]
	local at=0
	for i,item in options do if item.id==worn then at=i end end
	if at==0 then return if step>0 then options[1] else options[#options] end
	return options[(at-1+step)%#options+1]
end

function Panel.new(kit,gui,send,ui)
	local self=setmetatable({kit=kit,send=send,ui=ui,rows={}},Panel)
	local P=kit.palette
	self.P=P
	self.root=kit.frame(gui,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),P.ink,1)
	self.root.ZIndex=72;self.root.Visible=false
	-- (DA v3, DESIGN, validée le 14/11 22 h 35) une case de planche manga :
	-- papier, encre noire, un seul rouge ; la ligne choisie en bande d'encre
	local M=kit.MANGA or {paper=Color3.fromRGB(255,253,248),ink=Color3.fromRGB(20,16,17),red=Color3.fromRGB(195,18,29),cream=Color3.fromRGB(246,238,222),redSoft=Color3.fromRGB(240,120,110)}
	self.M=M
	local card=kit.frame(self.root,UDim2.new(0,24,.5,0),UDim2.fromOffset(Panel.W,Panel.H),M.paper,0)
	card.AnchorPoint=Vector2.new(0,.5);card.ZIndex=73
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.card=card
	local scale=kit.create("UIScale",card,{Scale=1})
	self.scale=scale
	self.title=kit.text(card,"YOUR NINJA",UDim2.fromOffset(24,14),UDim2.fromOffset(392,52),52,M.ink,kit.TITLE_FONT)
	self.rule=kit.frame(card,UDim2.fromOffset(24,62),UDim2.fromOffset(170,5),M.red,0)
	self.sub=kit.text(card,"",UDim2.fromOffset(26,72),UDim2.fromOffset(392,36),14,M.ink,kit.BODY_FONT)
	self.sub.TextWrapped=true;self.sub.TextYAlignment=Enum.TextYAlignment.Top
	local y=112
	for _,slot in Panel.ROWS do
		local row=kit.frame(card,UDim2.fromOffset(20,y),UDim2.fromOffset(400,62),M.paper,0)
		kit.create("UIStroke",row,{Color=M.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local label=kit.text(row,Shop.Slots[slot].name,UDim2.fromOffset(62,4),UDim2.fromOffset(276,16),12,M.ink,kit.BODY_FONT,Enum.TextXAlignment.Center)
		local name=kit.text(row,"",UDim2.fromOffset(62,20),UDim2.fromOffset(276,36),22,M.ink,kit.STRONG_FONT or kit.BODY_FONT,Enum.TextXAlignment.Center)
		name.TextScaled=true
		kit.create("UITextSizeConstraint",name,{MaxTextSize=22,MinTextSize=12})
		local prev=kit.button(row,"‹",UDim2.fromOffset(4,4),UDim2.fromOffset(54,54),function() self:step(slot,-1) end,M.ink)
		local nxt=kit.button(row,"›",UDim2.fromOffset(342,4),UDim2.fromOffset(54,54),function() self:step(slot,1) end,M.ink)
		for _,b in {prev,nxt} do b.TextSize=34;b.TextColor3=M.cream;b.Font=kit.STRONG_FONT or kit.BODY_FONT end
		row.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then self:select(slot) end end)
		self.rows[slot]={frame=row,name=name,label=label,prev=prev,next=nxt}
		y+=70
	end
	self.done=kit.button(card,"",UDim2.fromOffset(20,Panel.H-74),UDim2.fromOffset(400,56),function() self:finish() end,M.red)
	self.done.TextSize=30;self.done.TextColor3=M.cream
	-- DONE: a red « APPROVED » stamp prints (0.25 s), then the card goes
	self.stamp=kit.text(card,"APPROVED",UDim2.new(.5,-150,.5,-50),UDim2.fromOffset(300,100),64,M.red,kit.TITLE_FONT,Enum.TextXAlignment.Center)
	self.stamp.Rotation=-12;self.stamp.Visible=false;self.stamp.ZIndex=90
	kit.create("UIStroke",self.stamp,{Color=M.red,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.foot=kit.text(card,"More at the market.",UDim2.fromOffset(20,Panel.H-16),UDim2.fromOffset(400,14),12,M.ink,kit.BODY_FONT,Enum.TextXAlignment.Center)
	self.sel="top"
	-- (DESIGN 19/11, OUTILLEUR's measure on an iPhone 13: arrows 31 px, DONE
	-- 32, the card over half of the inspiration's) A short window (a phone in
	-- landscape) gets the compact card: a strip along the bottom, the rows in
	-- three columns, so the scale stays high and every button is 44 px or
	-- more; his face stays in view above it.
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		self:layout(v.Y<Panel.COMPACT_BELOW)
		if self.compact then
			scale.Scale=math.clamp(math.min((v.X-100)/Panel.CW,(v.Y*.62)/Panel.CH),.45,1.1)
		else
			scale.Scale=math.clamp(math.min((v.Y-40)/Panel.H,(v.X*.55)/Panel.W),.45,1.1)
		end
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	pcall(function()
		UIS.InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			local key=input.KeyCode
			if key==Enum.KeyCode.ButtonB then self:finish()
			elseif processed then return
			-- (DA v3) the keyboard: ↑↓ a row, ←→ a piece, Enter DONE
			elseif key==Enum.KeyCode.Up or key==Enum.KeyCode.Down then self:move(if key==Enum.KeyCode.Up then -1 else 1)
			elseif key==Enum.KeyCode.Left or key==Enum.KeyCode.Right then self:step(self.sel,if key==Enum.KeyCode.Left then -1 else 1)
			elseif key==Enum.KeyCode.Return or key==Enum.KeyCode.KeypadEnter then self:finish() end
		end)
	end)
	-- The camera on his face while the card is open; it opens by itself on
	-- his first walk (twice a second: no cost).
	self.clock=0
	RunService.RenderStepped:Connect(function(dt) self:frame(dt) end)
	return self
end

Panel.COMPACT_BELOW=500
Panel.CW,Panel.CH=1000,236
-- The card's two shapes: the column on the left (PC), the strip along the
-- bottom (a phone in landscape). Same rows and buttons, placed again.
function Panel:layout(compact)
	if compact==self.compact then return end
	self.compact=compact
	local card=self.card
	if compact then
		card.AnchorPoint=Vector2.new(.5,1);card.Position=UDim2.new(.5,0,1,-6);card.Size=UDim2.fromOffset(Panel.CW,Panel.CH)
		self.title.TextSize=44;self.title.Position=UDim2.fromOffset(20,6);self.rule.Position=UDim2.fromOffset(20,52)
		self.sub.Visible=false;self.foot.Visible=false
		local i=0
		for _,slot in Panel.ROWS do
			local r=self.rows[slot]
			local col,line=i%3,i//3
			r.frame.Position=UDim2.fromOffset(20+col*324,74+line*78);r.frame.Size=UDim2.fromOffset(312,72)
			r.prev.Position=UDim2.fromOffset(4,4);r.prev.Size=UDim2.fromOffset(64,64)
			r.next.Position=UDim2.fromOffset(244,4);r.next.Size=UDim2.fromOffset(64,64)
			r.label.Position=UDim2.fromOffset(72,4);r.label.Size=UDim2.fromOffset(168,18)
			r.name.Position=UDim2.fromOffset(72,22);r.name.Size=UDim2.fromOffset(168,44)
			i+=1
		end
		self.done.Position=UDim2.fromOffset(Panel.CW-280,4);self.done.Size=UDim2.fromOffset(260,64)
	else
		card.AnchorPoint=Vector2.new(0,.5);card.Position=UDim2.new(0,24,.5,0);card.Size=UDim2.fromOffset(Panel.W,Panel.H)
		self.title.TextSize=52;self.title.Position=UDim2.fromOffset(24,14);self.rule.Position=UDim2.fromOffset(24,62)
		self.sub.Visible=true;self.foot.Visible=true
		local y=112
		for _,slot in Panel.ROWS do
			local r=self.rows[slot]
			r.frame.Position=UDim2.fromOffset(20,y);r.frame.Size=UDim2.fromOffset(400,62)
			r.prev.Position=UDim2.fromOffset(4,4);r.prev.Size=UDim2.fromOffset(54,54)
			r.next.Position=UDim2.fromOffset(342,4);r.next.Size=UDim2.fromOffset(54,54)
			r.label.Position=UDim2.fromOffset(62,4);r.label.Size=UDim2.fromOffset(276,16)
			r.name.Position=UDim2.fromOffset(62,20);r.name.Size=UDim2.fromOffset(276,36)
			y+=70
		end
		self.done.Position=UDim2.fromOffset(20,Panel.H-74);self.done.Size=UDim2.fromOffset(400,56)
	end
end

-- (DESIGN 19/11) the wardrobe counts as this panel for Konoha (the walk
-- stops while either is open: HubClient asks this panel)
function Panel:shown() return self.root.Visible or (self.ui and self.ui.wardrobe and self.ui.wardrobe:shown()) or false end
function Panel:dressed() return Shop.dressed(self.kits and self.kits.style) end
function Panel:show(kits)
	if kits then self.kits=kits end
	self:draw()
	if not self.root.Visible then
		self.root.Visible=true
		local camera=workspace.CurrentCamera
		self.cameraWas=camera.CameraType
		if self.ui and self.ui.shopPanel and self.ui.shopPanel:shown() then self.ui.shopPanel:hide() end
		if UIS:GetLastInputType().Name:sub(1,7)=="Gamepad" then
			task.defer(function() pcall(function() GuiService.SelectedObject=self.rows.top.next end) end)
		end
	end
end
function Panel:hide()
	if not self.root.Visible then return end
	self.root.Visible=false
	pcall(function()
		local selected=GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.card) then GuiService.SelectedObject=nil end
	end)
	local camera=workspace.CurrentCamera
	camera.CameraType=Enum.CameraType.Custom
end
-- DONE: only once he wears a top (or a master's outfit).
function Panel:finish()
	if not self:dressed() or self.stamping then return end
	self.seen=true
	self.stamping=true
	self.stamp.Visible=true;self.stamp.TextTransparency=1
	pcall(function()
		local TweenService=game:GetService("TweenService")
		TweenService:Create(self.stamp,TweenInfo.new(.12),{TextTransparency=0}):Play()
	end)
	task.delay(.25,function()
		self.stamp.Visible=false;self.stamping=false
		self:hide()
	end)
end
-- The rows a player can be on (the master's outfit only once he owns one).
function Panel:selectable()
	local out={}
	local style=self.kits and self.kits.style
	for _,slot in Panel.ROWS do
		if slot~="set" or #Panel.options(style,"set")>1 then table.insert(out,slot) end
	end
	return out
end
function Panel:select(slot) self.sel=slot;self:draw() end
function Panel:move(step)
	local rows=self:selectable()
	local at=table.find(rows,self.sel) or 1
	self.sel=rows[(at-1+step)%#rows+1]
	self:draw()
end
function Panel:refresh(kits)
	self.kits=kits
	if self.root.Visible then self:draw() end
end
function Panel:step(slot,step)
	local style=self.kits and self.kits.style
	local item=Panel.cycle(style,slot,step)
	if item then self.send("EquipItem",{item=item.id}) end
end
function Panel:draw()
	local style=self.kits and self.kits.style
	local P=self.P
	local ownsSet=#Panel.options(style,"set")>1
	local worn=style and style.equipped or {}
	local set=worn.set and Shop.item(worn.set)
	for _,slot in Panel.ROWS do
		local row=self.rows[slot]
		local id=worn[slot]
		local item=id and Shop.item(id)
		local M=self.M
		local covered=set and not set.none and slot~="set" and slot~="headband"
		local on=self.sel==slot
		-- (DA v3) always shown; disabled until he owns one
		local locked=slot=="set" and not ownsSet
		row.prev.Visible=not locked;row.next.Visible=not locked
		row.name.Text=if locked then "GET ONE IN THE SHOP › STYLE" elseif covered then "("..set.name..")" elseif item then item.name elseif slot=="headband" then (Shop.default("headband") or {name=""}).name else "NOTHING"
		-- the chosen row: a band of ink, cream text, its count in soft red
		row.frame.BackgroundColor3=if on then M.ink else M.paper
		row.name.TextColor3=if on then M.cream elseif locked or covered then Color3.fromRGB(120,112,108) else M.ink
		local options=Panel.options(style,slot)
		local index=0
		for i,o in options do if o.id==id then index=i end end
		row.label.Text=Shop.Slots[slot].name..(if #options>0 and not locked then string.format("  %d/%d",math.max(index,0),#options) else "")
		row.label.TextColor3=if on then M.redSoft else M.ink
	end
	local dressed=self:dressed()
	self.sub.Text=if dressed then "Looking sharp." else "Start with a top."
	self.done.Text=if dressed then "DONE" else "PICK A TOP"
	self.done.AutoButtonColor=dressed
	self.done.BackgroundColor3=if dressed then self.M.red else Color3.fromRGB(120,112,108)
end
-- Every frame while open: the camera in front of him, his body on the right
-- of the card. Twice a second: opens by itself on his first walk.
function Panel:frame(dt)
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if self.root.Visible and root then
		local camera=workspace.CurrentCamera
		if camera.CameraType~=Enum.CameraType.Scriptable then camera.CameraType=Enum.CameraType.Scriptable end
		local cf=root.CFrame
		-- (compact: the strip hides his legs; his face and chest centred above it)
		local aim=if self.compact then cf.Position+Vector3.new(0,-1.6,0) else cf.Position+Vector3.new(0,.4,0)+cf.RightVector*2.4
		camera.CFrame=CFrame.lookAt(aim+cf.LookVector*10+Vector3.new(0,1.2,0),aim)
	end
	self.clock+=dt
	if self.clock<.5 then return end
	self.clock=0
	local kits=self.kits
	local ui=self.ui
	local busy=ui and ((ui.shopPanel and ui.shopPanel:shown()) or (ui.treePanel and ui.treePanel:shown()))
	-- (26/11, DEC-054) in the forest the creation waits for the gate (Client/ForestIntro)
	local intro=Players.LocalPlayer:GetAttribute("NinjaIntro")
	if not self.root.Visible and not self.seen and intro==nil and ui and ui.hubWalk and root and kits and kits.state=="ready" and kits.style and not self:dressed() and not busy then
		self:show()
	end
	-- (a duel, the board: the card goes)
	if self.root.Visible and ui and not ui.hubWalk then self:hide() end
end

return Panel
