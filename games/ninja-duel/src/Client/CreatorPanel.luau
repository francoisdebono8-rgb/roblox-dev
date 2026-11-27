-- The gate's creation (DESIGN, passe 2, 26/11, DEC-054): at Konoha's great
-- gate he makes his ninja — outfit, hair, its colour, headband — on his own
-- Roblox avatar, big in the middle, turning. A manga spread: the four steps
-- as tabs on the left (one done → the next), the choices as cards on the
-- right, ENTER KONOHA at the bottom. Nothing is bought here: the starter
-- pieces (Catalog `base`) and one hair style and one colour, given at the gate.
--
-- Contract with the DEV: the client calls CreatorPanel:show() at the gate;
-- ENTER KONOHA sends "Create" {top, bottom, feet, headband, hair, hairColor}
-- (item ids; hair "" = his own Roblox hair). The server equips them, gives
-- the chosen hair and colour, then opens the gate.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Shop=require(Shared.Shop)
local Text=require(Shared.Text)
-- (CM 26/11) the words: Shared/Banter.Creation
local okB,Banter=pcall(function() return require(Shared.Banter) end)
local W=(okB and Banter.Creation) or {title="WHO ARE YOU?",sub="",random="RANDOM",confirm="THAT'S ME",quips={}}

local C={}
C.__index=C
C.W,C.H=1240,700
C.STEPS={
	{id="outfit",name="OUTFIT",slots={"top","bottom","feet"}},
	{id="hair",name="HAIR",slots={"hair"}},
	{id="color",name="COLOUR",slots={"hairColor"}},
	{id="headband",name="HEADBAND",slots={"headband"}},
}

-- ------------------------------------------------------------------ pure
-- The choices of a slot at the gate: the starter pieces; every hair style and
-- colour (one given here); hair also offers his own.
function C.options(slot)
	local out={}
	if slot=="hair" then table.insert(out,{id="",name="MY OWN HAIR"}) end
	for _,item in Shop.Items do
		if item.slot==slot and (item.base or slot=="hair" or slot=="hairColor") and not item.hidden then
			table.insert(out,{id=item.id,name=Text.upper(item.name),color=item.colors and (item.colors.Hair or item.colors.Cloth or item.colors.Band)})
		end
	end
	return out
end
-- The first choice of each slot (his default).
function C.defaults()
	local out={}
	for _,step in C.STEPS do
		for _,slot in step.slots do
			local o=C.options(slot)
			out[slot]=o[1] and o[1].id or ""
		end
	end
	return out
end
-- RANDOM: one of each (pure; rng a Random).
function C.random(rng)
	local out={}
	for _,step in C.STEPS do
		for _,slot in step.slots do
			local o=C.options(slot)
			local n=if #o>0 then (if rng and rng.NextInteger then rng:NextInteger(1,#o) else math.random(1,#o)) else 0
			out[slot]=if n>0 then o[n].id else ""
		end
	end
	return out
end
-- What the preview wears (comma list) and the hair's paint.
function C.wearing(picks)
	local ids={}
	for _,slot in {"top","bottom","feet","headband","hair"} do
		local id=picks[slot]
		if id and id~="" then table.insert(ids,id) end
	end
	local paint=nil
	local c=picks.hairColor and Shop.item(picks.hairColor)
	if c and c.colors and c.colors.Hair then
		local h=c.colors.Hair
		paint=if typeof(h)=="Color3" then h else Color3.fromRGB(h[1],h[2],h[3])
	end
	return table.concat(ids,","),paint
end

-- ------------------------------------------------------------------ page
function C.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send,drawn={},picks=C.defaults(),step=1},C)
	local M=kit.MANGA
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.2)
	self.root.ZIndex=78;self.root.Visible=false;self.root.Active=true;self.root.Name="Creator"
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(C.W,C.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=79
	kit.create("UIStroke",card,{Color=M.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),C.W+24,C.H+24,1.1)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	self.card=card
	local function z(o,d) o.ZIndex=80+(d or 0);return o end
	z(kit.text(card,W.title,UDim2.fromOffset(28,8),UDim2.fromOffset(560,72),68,M.ink,kit.TITLE_FONT))
	z(kit.frame(card,UDim2.fromOffset(28,76),UDim2.fromOffset(220,7),M.red,0))
	z(kit.text(card,W.sub or "",UDim2.fromOffset(600,34),UDim2.fromOffset(C.W-640,30),20,M.mid or M.ink,kit.VOICE_FONT or kit.BODY_FONT))
	-- the steps
	self.tabs={}
	for i,step in C.STEPS do
		local b=z(kit.button(card,i.."  "..step.name,UDim2.fromOffset(28,112+(i-1)*70),UDim2.fromOffset(250,58),function() self.step=i;self:draw() end,M.paper),1)
		b.Font=kit.TITLE_FONT;b.TextSize=30;b.TextXAlignment=Enum.TextXAlignment.Left
		kit.create("UIPadding",b,{PaddingLeft=UDim.new(0,16)})
		kit.create("UIStroke",b,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		self.tabs[i]=b
	end
	-- the avatar, big, turning, on a paper stage
	local stage=z(kit.frame(card,UDim2.fromOffset(300,96),UDim2.fromOffset(400,580),M.back or M.paper,0))
	kit.create("UIStroke",stage,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.stage=stage
	pcall(function()
		local Preview=require(script.Parent.StylePreview)
		self.preview=Preview.new(stage,UDim2.fromOffset(0,0),UDim2.fromScale(1,1))
		self.preview:turn(true)
	end)
	-- the choices
	-- (OUTILLEUR 27/11: the 5th row under NEXT, HAIR and COLOUR off the screen)
	-- the choices scroll, in four columns that fit, above the buttons
	self.body=kit.create("ScrollingFrame",card,{Position=UDim2.fromOffset(724,96),Size=UDim2.fromOffset(C.W-752,C.H-96-102),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=8,ScrollBarImageColor3=M.ink,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=80})
	-- RANDOM, and its quip under the avatar
	self.randomButton=z(kit.button(card,W.random,UDim2.fromOffset(28,C.H-86),UDim2.fromOffset(250,66),function() self:randomize() end,M.paper),1)
	self.randomButton.Font=kit.TITLE_FONT;self.randomButton.TextSize=34;self.randomButton.TextColor3=M.ink
	kit.create("UIStroke",self.randomButton,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.quip=z(kit.text(stage,"",UDim2.new(0,10,1,-44),UDim2.new(1,-20,0,36),22,M.ink,kit.VOICE_FONT or kit.BODY_FONT,Enum.TextXAlignment.Center),3)
	-- (DEV 26/11, seen in the game: NEXT, at 724 and 200 wide, covered the
	-- start of THAT'S ME) side by side, 12 apart
	self.enter=z(kit.button(card,W.confirm,UDim2.fromOffset(724+200+12,C.H-86),UDim2.fromOffset(C.W-28-(724+200+12),66),function() self:finish() end,M.red),1)
	self.enter.Font=kit.TITLE_FONT;self.enter.TextSize=40;self.enter.TextColor3=M.cream
	self.next=z(kit.button(card,"NEXT",UDim2.fromOffset(724,C.H-86),UDim2.fromOffset(200,66),function() self.step=math.min(#C.STEPS,self.step+1);self:draw() end,M.ink),1)
	self.next.Font=kit.TITLE_FONT;self.next.TextSize=34;self.next.TextColor3=M.cream
	return self
end

function C:shown() return self.root.Visible end
-- (DEV 26/11, seen at the gate: the card opens while he still runs, and the
-- copy kept his stride, leaning across the stage) The copy stands at rest
-- whatever his body was doing (Client/StylePreview.rest): drawn once.
function C:show()
	self.root.Visible=true;self:draw()
end
function C:hide() self.root.Visible=false end
function C:pick(slot,id) self.picks[slot]=id;self.quip.Text="";self:draw() end
function C:randomize(rng)
	if not rng then pcall(function() rng=Random.new() end) end
	if rng and not rng.NextInteger then rng=nil end
	self.picks=C.random(rng)
	local q=W.quips or {}
	local line=if rng and okB and Banter.pick then Banter.pick(q,self.lastQuip,rng) else q[math.random(1,math.max(1,#q))]
	self.lastQuip=line
	self.quip.Text=line or ""
	self:draw()
end
function C:finish()
	self.send("Create",{top=self.picks.top,bottom=self.picks.bottom,feet=self.picks.feet,headband=self.picks.headband,hair=self.picks.hair or "",hairColor=self.picks.hairColor})
	self:hide()
end
function C:draw()
	local kit,M=self.kit,self.M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	for i,b in self.tabs do
		b.BackgroundColor3=if i==self.step then M.ink else M.paper
		b.TextColor3=if i==self.step then M.cream else M.ink
	end
	self.next.Visible=self.step<#C.STEPS
	for _,d in self.drawn do d:Destroy() end
	table.clear(self.drawn)
	local step=C.STEPS[self.step]
	local y=0
	for _,slot in step.slots do
		if #step.slots>1 then
			local head=kit.text(self.body,Text.upper((Shop.Slots[slot] and Shop.Slots[slot].name) or slot),UDim2.fromOffset(0,y),UDim2.new(1,0,0,24),20,M.red,STRONG)
			head.ZIndex=81;table.insert(self.drawn,head);y+=28
		end
		local opts=C.options(slot)
		local per=4
		local cw=math.floor((C.W-752-14-(per-1)*10)/per)
		local ch=if #step.slots>1 then 84 else 100
		for i,o in opts do
			local col,row=(i-1)%per,(i-1)//per
			local on=self.picks[slot]==o.id
			local cell=kit.button(self.body,"",UDim2.fromOffset(col*(cw+10),y+row*(ch+10)),UDim2.fromOffset(cw,ch),function() self:pick(slot,o.id) end,if on then M.ink else M.paper)
			cell.ZIndex=81;table.insert(self.drawn,cell)
			kit.create("UIStroke",cell,{Color=if on then M.red else M.ink,Thickness=if on then 4 else 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			if o.color then
				local c=o.color
				local sw=kit.frame(cell,UDim2.fromOffset(10,10),UDim2.new(1,-20,0,ch-58),if typeof(c)=="Color3" then c else Color3.fromRGB(c[1],c[2],c[3]),0)
				sw.ZIndex=82;kit.corner(sw,4)
			end
			local t=kit.text(cell,o.name,UDim2.new(0,8,1,-44),UDim2.new(1,-16,0,38),15,if on then M.cream else M.ink,STRONG,Enum.TextXAlignment.Center)
			t.ZIndex=82;t.TextWrapped=true;t.TextScaled=true
			kit.create("UITextSizeConstraint",t,{MaxTextSize=15,MinTextSize=9})
		end
		y+=math.ceil(#opts/per)*(ch+10)+8
	end
	self.body.CanvasSize=UDim2.fromOffset(0,y)
	-- the avatar wears it
	pcall(function()
		local player=game:GetService("Players").LocalPlayer
		local ids,paint=C.wearing(self.picks)
		if self.preview and player.Character then
			self.preview:show(ids,player.Character,paint,true)
		end
	end)
	return step
end

return C
