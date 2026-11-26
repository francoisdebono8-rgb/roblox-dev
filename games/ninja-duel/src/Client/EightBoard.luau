-- THE 8 (DESIGN 26/11, DEC-053): the eight prodigies he has to beat in the
-- street, one head each in a row of ink frames, a red BEATEN stamp on those
-- he has beaten. Read in Progression.view's `challenges8` {beaten={kit=true},
-- count, need=8, order}. Opened from Konoha's HUD (THE 8  n/8).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local KitTexts=require(Shared.KitTexts)
local Fighters=require(Shared.Fighters)
local Text=require(Shared.Text)

local B={}
B.__index=B
B.W,B.H=1080,520

-- The cards (pure): {kit, name, title, beaten} in the board's order.
function B.cards(c)
	local out={}
	for _,kit in (c and c.order) or KitTexts.Order do
		local lines=KitTexts.of(kit)
		table.insert(out,{kit=kit,name=Text.upper(KitTexts.name(kit) or kit),title=lines and lines.title and Text.upper(lines.title) or "",beaten=(c and c.beaten and c.beaten[kit])==true})
	end
	return out
end
function B.count(c) return (c and c.count) or 0,(c and c.need) or 8 end

function B.new(kit,gui)
	local self=setmetatable({kit=kit,drawn={}},B)
	local M=kit.MANGA
	self.M=M
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=78;self.root.Visible=false;self.root.Active=true;self.root.Name="TheEight"
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(B.W,B.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=79
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),B.W+24,B.H+24,1.1)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	self.card=card
	local t=kit.text(card,"THE 8",UDim2.fromOffset(28,10),UDim2.fromOffset(300,70),70,M.ink,kit.TITLE_FONT);t.ZIndex=80
	kit.frame(card,UDim2.fromOffset(28,76),UDim2.fromOffset(150,6),M.red,0).ZIndex=80
	self.score=kit.text(card,"",UDim2.fromOffset(200,24),UDim2.fromOffset(500,44),40,M.red,kit.TITLE_FONT);self.score.ZIndex=80
	self.close=kit.button(card,"X",UDim2.fromOffset(B.W-88,14),UDim2.fromOffset(68,68),function() self:hide() end,M.ink)
	self.close.TextColor3=M.cream;self.close.TextSize=34;self.close.ZIndex=82
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	return self
end

function B:shown() return self.root.Visible end
function B:hide() self.root.Visible=false;if self.onHide then self.onHide() end end
function B:show(c) self.c=c;self.root.Visible=true;self:draw() end
function B:draw()
	local kit,M=self.kit,self.M
	for _,d in self.drawn do d:Destroy() end
	table.clear(self.drawn)
	local n,need=B.count(self.c)
	self.score.Text=string.format("%d / %d BEATEN",n,need)
	local cards=B.cards(self.c)
	local cw,ch,gap=240,190,16
	for i,c in cards do
		local col,row=(i-1)%4,(i-1)//4
		local f=kit.frame(self.card,UDim2.fromOffset(28+col*(cw+gap),104+row*(ch+gap)),UDim2.fromOffset(cw,ch),if c.beaten then M.ink else M.paper,0)
		f.ZIndex=80;f.Rotation=if i%2==0 then .6 else -.6;table.insert(self.drawn,f)
		kit.create("UIStroke",f,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		-- his colour, as the kit's band
		local def=Fighters[c.kit]
		local color=def and def.Color and Color3.fromRGB(table.unpack(def.Color)) or M.red
		kit.frame(f,UDim2.fromOffset(0,0),UDim2.new(1,0,0,14),color,0).ZIndex=81
		local name=kit.text(f,c.name,UDim2.fromOffset(12,26),UDim2.new(1,-24,0,70),40,if c.beaten then M.cream else M.ink,kit.TITLE_FONT)
		name.ZIndex=81;name.TextScaled=true;name.TextWrapped=true
		kit.create("UITextSizeConstraint",name,{MaxTextSize=40,MinTextSize=16})
		kit.text(f,c.title,UDim2.fromOffset(12,100),UDim2.new(1,-24,0,22),15,if c.beaten then M.cream else M.mid or M.ink,kit.STRONG_FONT or kit.BODY_FONT).ZIndex=81
		if c.beaten then
			local stamp=kit.text(f,"BEATEN",UDim2.new(.5,0,1,-34),UDim2.fromOffset(170,50),40,M.cream,kit.TITLE_FONT,Enum.TextXAlignment.Center)
			stamp.AnchorPoint=Vector2.new(.5,.5);stamp.BackgroundTransparency=0;stamp.BackgroundColor3=M.red;stamp.Rotation=-9;stamp.ZIndex=83
			kit.create("UIStroke",stamp,{Color=M.cream,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		else
			kit.text(f,"IN THE STREET",UDim2.new(0,12,1,-36),UDim2.new(1,-24,0,24),16,M.red,kit.STRONG_FONT or kit.BODY_FONT).ZIndex=81
		end
	end
	return cards
end

return B
