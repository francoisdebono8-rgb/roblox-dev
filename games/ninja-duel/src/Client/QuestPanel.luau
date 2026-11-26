-- Today's quests and the days in a row (vague 2 DESIGN 3; DEV's
-- Shared/DailyQuests, Progression.view `daily` = Daily.view). A page of the
-- manga (DA v3): the three quests of the day, each with its tier, its words,
-- how far he is and what it pays (a red DONE stamp once paid); under them the
-- days in a row on an ink band, the seven days of the ramp as boxes, today's
-- one red. Opened from Konoha's HUD (QUESTS). Presentation only.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
-- (26/11) capitals by Text.upper: string.upper follows the player's locale and broke « • » and « — »
local Text=require(Shared.Text)
local Daily=require(Shared.DailyQuests)
local UIS=game:GetService("UserInputService")

local Q={}
Q.__index=Q
Q.W,Q.H=820,560

-- « 5 H 12 » from seconds (pure).
function Q.clock(seconds)
	seconds=math.max(0,math.floor(seconds or 0))
	return string.format("%d H %02d",seconds//3600,(seconds%3600)//60)
end
-- The rows (pure): {tier, text, progress, goal, fill, ryo, done, count}.
function Q.rows(view)
	local out={}
	for _,q in (view and view.quests) or {} do
		local goal=math.max(1,q.goal or 1)
		local progress=math.min(q.progress or 0,goal)
		table.insert(out,{tier=q.tier or "",text=Text.upper(q.text or ""),progress=progress,goal=goal,fill=progress/goal,
			ryo=q.ryo or 0,done=q.done==true,count=string.format("%d / %d",progress,goal)})
	end
	return out
end
-- How many are done (pure): « 1/3 » for the HUD's button.
function Q.done(view)
	local n,all=0,0
	for _,q in (view and view.quests) or {} do all+=1;if q.done then n+=1 end end
	return n,all
end
-- The streak band's words (pure).
function Q.streakLine(view)
	local s=view and view.streak
	if type(s)~="table" then return "" end
	local days=s.days or 0
	if s.counted then
		return string.format("DAY %d IN A ROW  •  COME BACK TOMORROW: +%d RYŌ",days,s.tomorrow or 0)
	end
	return string.format("DAY %d IN A ROW TODAY  •  FINISH A DUEL: +%d RYŌ",days+1,s.today or 0)
end

function Q.new(kit,gui)
	local self=setmetatable({kit=kit,drawn={}},Q)
	local M=kit.MANGA
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=78;self.root.Visible=false;self.root.Active=true
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(Q.W,Q.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=79
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.card=card
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),Q.W+24,Q.H+24,1.1)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local function z(o,d) o.ZIndex=80+(d or 0);return o end
	z(kit.text(card,"TODAY'S QUESTS",UDim2.fromOffset(28,12),UDim2.fromOffset(520,64),60,M.ink,kit.TITLE_FONT))
	z(kit.frame(card,UDim2.fromOffset(28,72),UDim2.fromOffset(240,6),M.red,0))
	self.reset=z(kit.text(card,"",UDim2.fromOffset(28,84),UDim2.fromOffset(520,22),16,M.brown or M.ink,STRONG))
	self.close=z(kit.button(card,"X",UDim2.fromOffset(Q.W-88,14),UDim2.fromOffset(68,68),function() self:hide() end,M.ink),2)
	self.close.TextColor3=M.cream;self.close.TextSize=34
	self.body=z(kit.frame(card,UDim2.fromOffset(28,120),UDim2.fromOffset(Q.W-56,300),M.paper,1))
	-- the days in a row
	local band=z(kit.frame(card,UDim2.fromOffset(28,Q.H-128),UDim2.fromOffset(Q.W-56,104),M.ink,0))
	self.streak=z(kit.text(band,"",UDim2.fromOffset(16,8),UDim2.new(1,-32,0,30),24,M.cream,kit.TITLE_FONT),1)
	self.days={}
	local bw=math.floor((Q.W-56-32-6*8)/7)
	for i,ryo in Daily.Streak do
		local box=z(kit.frame(band,UDim2.fromOffset(16+(i-1)*(bw+8),44),UDim2.fromOffset(bw,48),M.cream,0),1)
		z(kit.text(box,"DAY "..i,UDim2.fromOffset(0,2),UDim2.new(1,0,0,18),13,M.ink,STRONG,Enum.TextXAlignment.Center),2)
		z(kit.text(box,"+"..ryo,UDim2.fromOffset(0,20),UDim2.new(1,0,0,26),22,M.ink,kit.TITLE_FONT,Enum.TextXAlignment.Center),2)
		self.days[i]=box
	end
	self.empty=z(kit.text(self.body,"Loading today's quests…",UDim2.fromOffset(0,20),UDim2.new(1,0,0,40),20,M.mid or M.ink,kit.BODY_FONT,Enum.TextXAlignment.Center),2)
	pcall(function()
		UIS.InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	return self
end

function Q:shown() return self.root.Visible end
function Q:show(view) self.view=view;self.root.Visible=true;self:draw() end
function Q:hide() self.root.Visible=false;if self.onHide then self.onHide() end end
function Q:refresh(view) self.view=view;if self.root.Visible then self:draw() end end

function Q:draw()
	local kit,M=self.kit,self.M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	for _,d in self.drawn do d:Destroy() end
	table.clear(self.drawn)
	local view=self.view
	local rows=Q.rows(view)
	self.empty.Visible=#rows==0
	self.reset.Text=if view and view.resetIn then "NEW QUESTS IN "..Q.clock(view.resetIn) else ""
	local RH=92
	for i,row in rows do
		local y=(i-1)*(RH+12)
		local line=kit.frame(self.body,UDim2.fromOffset(0,y),UDim2.new(1,0,0,RH),if row.done then (M.back or M.paper) else M.paper,0)
		line.ZIndex=81;table.insert(self.drawn,line)
		kit.create("UIStroke",line,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local tier=kit.frame(line,UDim2.fromOffset(12,12),UDim2.fromOffset(96,28),M.ink,0);tier.ZIndex=82
		kit.text(tier,row.tier,UDim2.fromScale(0,0),UDim2.fromScale(1,1),15,M.cream,STRONG,Enum.TextXAlignment.Center).ZIndex=83
		local words=kit.text(line,row.text,UDim2.fromOffset(122,10),UDim2.new(1,-300,0,32),24,M.ink,kit.TITLE_FONT)
		words.ZIndex=83;words.TextScaled=true
		kit.create("UITextSizeConstraint",words,{MaxTextSize=24,MinTextSize=14})
		local track=kit.frame(line,UDim2.fromOffset(122,52),UDim2.new(1,-300,0,18),M.back or M.paper,0);track.ZIndex=82
		kit.create("UIStroke",track,{Color=M.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local fill=kit.frame(track,UDim2.fromOffset(0,0),UDim2.new(row.fill,0,1,0),M.red,0);fill.ZIndex=83
		kit.text(line,row.count,UDim2.new(1,-170,0,48),UDim2.fromOffset(60,26),18,M.ink,STRONG,Enum.TextXAlignment.Right).ZIndex=83
		local pay=kit.text(line,"+"..row.ryo.." RYŌ",UDim2.new(1,-104,0,12),UDim2.fromOffset(92,68),26,M.ink,kit.TITLE_FONT,Enum.TextXAlignment.Center)
		pay.ZIndex=83
		if row.done then
			-- the red stamp, a little turned
			pay.Text="DONE";pay.TextColor3=M.cream;pay.BackgroundTransparency=0;pay.BackgroundColor3=M.red;pay.Rotation=-6
		end
	end
	self.streak.Text=Q.streakLine(view)
	local s=view and view.streak
	local today=if s then (if s.counted then s.days else (s.days or 0)+1) else 0
	local at=math.clamp(today,1,#Daily.Streak)
	for i,box in self.days do
		box.BackgroundColor3=if i==at then M.red elseif i<at then (M.off or M.cream) else M.cream
	end
	return rows
end

return Q
