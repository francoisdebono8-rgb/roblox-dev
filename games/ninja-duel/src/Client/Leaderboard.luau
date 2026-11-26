-- The leaderboards (DESIGN 20/11, step 1: « les tableaux de classement, dans
-- Konoha et à l'écran »). A page of the manga (DA v3): two tabs, THIS WEEK
-- and ALL TIME, and the column the board is sorted by (RATING, WINS, EXAM,
-- STREAK); one row per ninja: his place, his rank's emblem, his name, the
-- number. The player's own row is the ink band (and, when he is not in the
-- top, it is added at the foot with his place). The top three get the red
-- seal of their place. Presentation only: the rows come from the server.
--
-- What it reads (DEV, Server/Leaderboards): ReplicatedStorage.NinjaDuelBoards,
-- one StringValue per board, JSON {id, title, rows={{rank,id,name,value}}, at}.
-- `boards` here = { [id] = that table }. One tab per board, in L.TABS order;
-- the player's row is the one whose id is his UserId. The emblem: the rank of
-- the row's rating on the RANKED board (Shared/Ranked), none elsewhere.
-- A board absent or empty says « No duel counted yet ».
local UIS=game:GetService("UserInputService")

local L={}
L.__index=L
L.W,L.H=960,700
L.ROWS=10
L.TABS={{id="Rating",name="RANKED"},{id="WeekWins",name="THIS WEEK"},{id="Rooftops",name="ROOFTOPS"},{id="Merit",name="MERIT"},{id="Streak",name="STREAK"},{id="Exam",name="EXAM"}}
-- (23/11, step 4) one board per kit (Kit_<id>, its mastery): a second row of
-- tabs, the kits in Shared/Fighters' order, those the server publishes.
function L.kitTabs(boards)
	local out={}
	for id,b in boards or {} do
		if type(b)=="table" and b.kit then table.insert(out,{id=id,kit=b.kit,name=string.upper(b.kit),title=b.title}) end
	end
	local order,names={},{}
	pcall(function()
		local Shared=game:GetService("ReplicatedStorage").NinjaDuel
		for i,k in require(Shared.BetaRoster) do order[k]=i end
		local KitTexts=require(Shared.KitTexts)
		for _,t in out do names[t.kit]=KitTexts.name(t.kit) end
	end)
	for _,t in out do if names[t.kit] then t.name=string.upper(names[t.kit]) end end
	table.sort(out,function(a,c)
		local x,y=order[a.kit] or 99,order[c.kit] or 99
		if x~=y then return x<y end
		return a.id<c.id
	end)
	return out
end
-- A row's value as written: the race's clock, else the number.
function L.value(row) return if row.text then row.text else tostring(row.value or 0) end

-- The server's boards, decoded (nil-safe, outside Studio too)
function L.read()
	local out={}
	pcall(function()
		local folder=game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuelBoards")
		if not folder then return end
		local Http=game:GetService("HttpService")
		for _,v in folder:GetChildren() do
			local ok,data=pcall(Http.JSONDecode,Http,v.Value)
			if ok and type(data)=="table" then out[data.id or v.Name]=data end
		end
	end)
	return out
end

-- The rows to draw: the top L.ROWS, and the player's own row after them when
-- he is lower (pure).
function L.rows(list,me)
	local out,mine={},nil
	for i,row in list or {} do
		row.you=row.you or (me~=nil and row.id==me)
		if i<=L.ROWS then table.insert(out,row) elseif row.you then mine=row end
	end
	if mine then table.insert(out,mine) end
	return out
end

function L.new(kit,gui)
	local self=setmetatable({kit=kit,tab="Rating",drawn={},tabs={}},L)
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
	local tw=math.floor((L.W-56-(#L.TABS-1)*8)/#L.TABS)
	for i,t in L.TABS do
		local b=z(kit.button(card,t.name,UDim2.fromOffset(28+(i-1)*(tw+8),92),UDim2.fromOffset(tw,50),function() self.tab=t.id;self:draw() end,M.paper),1)
		b.Font=kit.STRONG_FONT;b.TextSize=20
		kit.create("UIStroke",b,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		self.tabs[t.id]=b
	end
	-- the kits' row: « MASTERY » then a chip per kit
	z(kit.text(card,"MASTERY",UDim2.fromOffset(28,152),UDim2.fromOffset(110,44),20,M.red,kit.STRONG_FONT))
	self.kitRow=z(kit.frame(card,UDim2.fromOffset(140,150),UDim2.fromOffset(L.W-168,48),M.paper,1))
	self.kitTabs={}
	self.boardTitle=z(kit.text(card,"",UDim2.fromOffset(28,206),UDim2.fromOffset(L.W-56,26),18,M.brown or M.ink,kit.STRONG_FONT))
	self.body=z(kit.frame(card,UDim2.fromOffset(28,238),UDim2.fromOffset(L.W-56,L.H-262),M.paper,1))
	self.empty=z(kit.text(self.body,"No duels yet. Be the first.",UDim2.fromOffset(0,20),UDim2.new(1,0,0,40),20,M.mid or M.ink,kit.BODY_FONT,Enum.TextXAlignment.Center),2)
	pcall(function()
		UIS.InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	return self
end

function L:shown() return self.root.Visible end
function L:show(boards) self.boards=boards or L.read();self.root.Visible=true;self:draw() end
function L:hide() self.root.Visible=false;if self.onHide then self.onHide() end end
function L:refresh(boards) self.boards=boards;if self.root.Visible then self:draw() end end

function L:draw()
	local kit,M=self.kit,self.M
	for _,d in self.drawn do d:Destroy() end
	table.clear(self.drawn)
	-- the kits' chips, from what the server publishes
	for _,b in self.kitTabs do b:Destroy() end
	self.kitTabs={}
	local kits=L.kitTabs(self.boards)
	local cw=if #kits>0 then math.min(150,math.floor((L.W-168-(#kits-1)*6)/#kits)) else 0
	for i,t in kits do
		local b=kit.button(self.kitRow,t.name,UDim2.fromOffset((i-1)*(cw+6),0),UDim2.fromOffset(cw,48),function() self.tab=t.id;self:draw() end,M.paper)
		b.ZIndex=82;b.Font=kit.STRONG_FONT;b.TextSize=16;b.TextScaled=true
		kit.create("UITextSizeConstraint",b,{MaxTextSize=16,MinTextSize=10})
		kit.create("UIStroke",b,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		self.kitTabs[t.id]=b
	end
	for id,b in self.tabs do b.BackgroundColor3=if id==self.tab then M.ink else M.paper;b.TextColor3=if id==self.tab then M.cream else M.ink end
	for id,b in self.kitTabs do b.BackgroundColor3=if id==self.tab then M.red else M.paper;b.TextColor3=if id==self.tab then M.cream else M.ink end
	local board=self.boards and self.boards[self.tab]
	self.boardTitle.Text=if board and board.title then board.title..(if self.tab=="Rooftops" then "  •  BEST TIME, FASTEST FIRST" else "") else ""
	self.empty.Text=if self.tab=="Rooftops" then "No times yet. The race starts at the gate." elseif self.tab:sub(1,4)=="Kit_" then "Nobody yet. Play this kit." else "No duels yet. Be the first."
	local me=nil
	pcall(function() me=game:GetService("Players").LocalPlayer.UserId end)
	local rows=L.rows(board and board.rows,me)
	self.empty.Visible=#rows==0
	local H=40
	for i,row in rows do
		local you=row.you==true
		local y=(i-1)*(H+3)+(if i>L.ROWS then 10 else 0)
		local band=kit.frame(self.body,UDim2.fromOffset(0,y),UDim2.new(1,0,0,H),if you then M.ink else (if i%2==0 then (M.back or M.paper) else M.paper),0)
		band.ZIndex=81;table.insert(self.drawn,band)
		local ink=if you then M.cream else M.ink
		local place=kit.text(band,tostring(row.rank or i),UDim2.fromOffset(8,0),UDim2.fromOffset(52,H),24,ink,kit.TITLE_FONT,Enum.TextXAlignment.Center)
		place.ZIndex=83
		if (row.rank or i)<=3 then
			-- the seal of the top three
			place.BackgroundTransparency=0;place.BackgroundColor3=M.red;place.TextColor3=M.cream
			kit.corner(place,18);place.Size=UDim2.fromOffset(36,36);place.Position=UDim2.fromOffset(16,2)
		end
		if self.tab=="Rating" and kit.Ranked and tonumber(row.value) then
			local badge=kit.rankBadge(band,kit.Ranked.rank(tonumber(row.value)),34,UDim2.fromOffset(66,3));badge.ZIndex=82
		end
		kit.text(band,(row.name or "?")..(if you then "  (YOU)" else ""),UDim2.fromOffset(110,0),UDim2.new(1,-260,1,0),20,ink,kit.STRONG_FONT).ZIndex=83
		kit.text(band,L.value(row),UDim2.new(1,-150,0,0),UDim2.fromOffset(140,H),24,ink,kit.TITLE_FONT,Enum.TextXAlignment.Right).ZIndex=83
	end
	return rows
end

return L
