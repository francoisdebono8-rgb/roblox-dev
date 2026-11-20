-- The leaderboards (DESIGN 20/11, step 1: « les tableaux de classement, dans
-- Konoha et à l'écran »). A page of the manga (DA v3): two tabs, THIS WEEK
-- and ALL TIME, and the column the board is sorted by (RATING, WINS, EXAM,
-- STREAK); one row per ninja: his place, his rank's emblem, his name, the
-- number. The player's own row is the ink band (and, when he is not in the
-- top, it is added at the foot with his place). The top three get the red
-- seal of their place. Presentation only: the rows come from the server.
--
-- Contract with the DEV (step 1, DEV 2-3): `boards` =
--   { week = { rating = {rows}, wins = {rows}, exam = {rows}, streak = {rows} },
--     all  = { ...same... } }
--   a row = { place = 1, name = "ShadowLeaf", rank = "genin", value = 1240,
--             you = true|nil }
-- A board absent shows « No duel counted yet ».
local UIS=game:GetService("UserInputService")

local L={}
L.__index=L
L.W,L.H=920,640
L.ROWS=10
L.TABS={{id="week",name="THIS WEEK"},{id="all",name="ALL TIME"}}
L.COLUMNS={{id="rating",name="RATING"},{id="wins",name="WINS"},{id="exam",name="RANK EXAM"},{id="streak",name="STREAK"}}

-- The rows to draw: the top L.ROWS, and the player's own row after them when
-- he is lower (pure).
function L.rows(list)
	local out,mine={},nil
	for i,row in list or {} do
		if i<=L.ROWS then table.insert(out,row) elseif row.you then mine=row end
	end
	if mine then table.insert(out,mine) end
	return out
end

function L.new(kit,gui)
	local self=setmetatable({kit=kit,tab="week",column="rating",drawn={},tabs={},columns={}},L)
	local M=kit.MANGA
	self.M=M
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=78;self.root.Visible=false;self.root.Active=true
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(L.W,L.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=79
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.card=card
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),L.W+24,L.H+24,1.1)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local function z(o,d) o.ZIndex=80+(d or 0);return o end
	z(kit.text(card,"LEADERBOARDS",UDim2.fromOffset(28,12),UDim2.fromOffset(560,64),60,M.ink,kit.TITLE_FONT))
	z(kit.frame(card,UDim2.fromOffset(28,72),UDim2.fromOffset(240,6),M.red,0))
	self.close=z(kit.button(card,"X",UDim2.fromOffset(L.W-88,14),UDim2.fromOffset(68,68),function() self:hide() end,M.ink),2)
	self.close.TextColor3=M.cream;self.close.TextSize=34
	for i,t in L.TABS do
		local b=z(kit.button(card,t.name,UDim2.fromOffset(28+(i-1)*200,92),UDim2.fromOffset(190,50),function() self.tab=t.id;self:draw() end,M.paper),1)
		b.Font=kit.STRONG_FONT;b.TextSize=20
		kit.create("UIStroke",b,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		self.tabs[t.id]=b
	end
	for i,c in L.COLUMNS do
		local b=z(kit.button(card,c.name,UDim2.fromOffset(440+(i-1)*114,96),UDim2.fromOffset(106,44),function() self.column=c.id;self:draw() end,M.paper),1)
		b.Font=kit.STRONG_FONT;b.TextSize=15
		kit.create("UIStroke",b,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		self.columns[c.id]=b
	end
	self.body=z(kit.frame(card,UDim2.fromOffset(28,158),UDim2.fromOffset(L.W-56,L.H-182),M.paper,1))
	self.empty=z(kit.text(self.body,"No duel counted yet. Every duel between two players counts.",UDim2.fromOffset(0,20),UDim2.new(1,0,0,40),20,M.mid or M.ink,kit.BODY_FONT,Enum.TextXAlignment.Center),2)
	pcall(function()
		UIS.InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	return self
end

function L:shown() return self.root.Visible end
function L:show(boards) if boards then self.boards=boards end;self.root.Visible=true;self:draw() end
function L:hide() self.root.Visible=false end
function L:refresh(boards) self.boards=boards;if self.root.Visible then self:draw() end end

function L:draw()
	local kit,M=self.kit,self.M
	for _,d in self.drawn do d:Destroy() end
	table.clear(self.drawn)
	for id,b in self.tabs do b.BackgroundColor3=if id==self.tab then M.ink else M.paper;b.TextColor3=if id==self.tab then M.cream else M.ink end
	for id,b in self.columns do b.BackgroundColor3=if id==self.column then M.red else M.paper;b.TextColor3=if id==self.column then M.cream else M.ink end
	local board=self.boards and self.boards[self.tab] and self.boards[self.tab][self.column]
	local rows=L.rows(board)
	self.empty.Visible=#rows==0
	local H=40
	for i,row in rows do
		local you=row.you==true
		local y=(i-1)*(H+3)+(if i>L.ROWS then 10 else 0)
		local band=kit.frame(self.body,UDim2.fromOffset(0,y),UDim2.new(1,0,0,H),if you then M.ink else (if i%2==0 then (M.back or M.paper) else M.paper),0)
		band.ZIndex=81;table.insert(self.drawn,band)
		local ink=if you then M.cream else M.ink
		local place=kit.text(band,tostring(row.place or i),UDim2.fromOffset(8,0),UDim2.fromOffset(52,H),24,ink,kit.TITLE_FONT,Enum.TextXAlignment.Center)
		place.ZIndex=83
		if (row.place or i)<=3 then
			-- the seal of the top three
			place.BackgroundTransparency=0;place.BackgroundColor3=M.red;place.TextColor3=M.cream
			kit.corner(place,18);place.Size=UDim2.fromOffset(36,36);place.Position=UDim2.fromOffset(16,2)
		end
		local badge=kit.rankBadge(band,row.rank,34,UDim2.fromOffset(66,3));badge.ZIndex=82
		kit.text(band,(row.name or "?")..(if you then "  (YOU)" else ""),UDim2.fromOffset(110,0),UDim2.new(1,-260,1,0),20,ink,kit.STRONG_FONT).ZIndex=83
		kit.text(band,tostring(row.value or 0),UDim2.new(1,-150,0,0),UDim2.fromOffset(140,H),24,ink,kit.TITLE_FONT,Enum.TextXAlignment.Right).ZIndex=83
	end
	return rows
end

return L
