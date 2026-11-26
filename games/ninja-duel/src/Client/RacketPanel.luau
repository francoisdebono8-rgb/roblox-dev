-- The racket (DESIGN, passe commune 1, 23/11): street thugs stop him in
-- Konoha — « your Ryō or we fight ». He PAYS, RUNS, or FIGHTS on the spot (a
-- street duel against the AI: win, he takes their Ryō; lose, he leaves some).
-- A manga panel, low on the screen so the thug stays in view: the thug's
-- line in a speech bubble, what each choice costs or brings, three buttons
-- of 64 px (keys 1 2 3, pad X Y B), and a fuse that runs out into a FIGHT.
--
-- Contract with the DEV (Server, to come): the client calls
-- RacketPanel:show(r) with r = {id, name, line, ask, purse, win, lose, ryo,
-- seconds}: the thug's name, his line (the CM's), the Ryō he asks, what a won
-- fight brings (win) and what a lost one costs (lose), his Ryō (ryo) and how
-- long before he swings (seconds, default 8). The choice is sent as
-- "Racket" {id, choice="pay"|"run"|"fight"}. A run can fail: the server says.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Text=require(Shared.Text)

local R={}
R.__index=R
R.W,R.H=860,196
R.CHOICES={"pay","run","fight"}
R.FUSE=8

-- What each button says under it (pure).
function R.lines(r)
	r=r or {}
	local ask,win,lose=r.ask or 0,r.win or 0,r.lose or 0
	return {
		pay={label="PAY "..ask,sub=if (r.ryo or 0)<ask then "YOU DON'T HAVE "..ask.." RYŌ" else "YOU LOSE "..ask.." RYŌ, NO FIGHT",ok=(r.ryo or 0)>=ask},
		run={label="RUN",sub="ESCAPE IF YOU'RE FAST ENOUGH",ok=true},
		fight={label="FIGHT",sub=string.format("WIN +%d RYŌ  •  LOSE −%d",win,lose),ok=true},
	}
end

function R.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send,buttons={}},R)
	local M=kit.MANGA
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	local root=kit.frame(gui,UDim2.new(.5,0,1,-24),UDim2.fromOffset(R.W,R.H),M.paper,0)
	root.AnchorPoint=Vector2.new(.5,1);root.ZIndex=60;root.Visible=false;root.Name="Racket";root.Rotation=0
	kit.create("UIStroke",root,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.root=root
	local scale=kit.create("UIScale",root,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=math.min(1,(v.X-24)/R.W,(v.Y*.34)/R.H)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local function z(o,d) o.ZIndex=61+(d or 0);return o end
	-- the ink band with his name, a red seal « STREET FIGHT »
	local band=z(kit.frame(root,UDim2.fromOffset(0,0),UDim2.new(1,0,0,52),M.ink,0))
	self.name=z(kit.text(band,"",UDim2.fromOffset(20,4),UDim2.new(1,-260,1,-8),36,M.cream,kit.TITLE_FONT),1)
	local seal=z(kit.text(band,"STREET FIGHT",UDim2.new(1,-220,0,8),UDim2.fromOffset(200,36),24,M.cream,kit.TITLE_FONT,Enum.TextXAlignment.Center),1)
	seal.BackgroundTransparency=0;seal.BackgroundColor3=M.red;seal.Rotation=-4
	-- (OUTILLEUR 24/11: « sa ligne écrite deux fois », half the screen) his
	-- line is his own bubble over his head; here only his name and the choice
	self.line=z(kit.text(band,"",UDim2.fromOffset(0,0),UDim2.fromOffset(0,0),1,M.cream,kit.BODY_FONT),1)
	self.line.Visible=false
	-- the three choices
	local bw=math.floor((R.W-40-2*16)/3)
	self.subs={}
	for i,choice in R.CHOICES do
		local x=20+(i-1)*(bw+16)
		local b=z(kit.button(root,"",UDim2.fromOffset(x,64),UDim2.fromOffset(bw,64),function() self:choose(choice) end,if choice=="fight" then M.red elseif choice=="pay" then M.paper else M.ink),1)
		b.TextSize=34;b.Font=kit.TITLE_FONT;b.TextColor3=if choice=="pay" then M.ink else M.cream
		kit.create("UIStroke",b,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local key=z(kit.text(b,tostring(i),UDim2.fromOffset(6,4),UDim2.fromOffset(22,22),16,if choice=="pay" then M.ink else M.cream,STRONG,Enum.TextXAlignment.Center),2)
		key.BackgroundTransparency=.6;key.BackgroundColor3=M.ink
		self.buttons[choice]=b
		self.subs[choice]=z(kit.text(root,"",UDim2.fromOffset(x,132),UDim2.fromOffset(bw,22),15,M.ink,STRONG,Enum.TextXAlignment.Center),1)
	end
	-- the fuse: it burns down; at its end, he swings (a FIGHT)
	local track=z(kit.frame(root,UDim2.fromOffset(20,R.H-36),UDim2.new(1,-40,0,12),M.back or M.paper,0))
	kit.create("UIStroke",track,{Color=M.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.fuse=z(kit.frame(track,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),M.red,0),1)
	self.fuseText=z(kit.text(root,"",UDim2.new(1,-260,1,-58),UDim2.fromOffset(240,20),14,M.red,STRONG,Enum.TextXAlignment.Right),1)
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
			if processed or not root.Visible then return end
			local k=input.KeyCode
			if k==Enum.KeyCode.One or k==Enum.KeyCode.ButtonX then self:choose("pay")
			elseif k==Enum.KeyCode.Two or k==Enum.KeyCode.ButtonB then self:choose("run")
			elseif k==Enum.KeyCode.Three or k==Enum.KeyCode.ButtonY then self:choose("fight") end
		end)
		game:GetService("RunService").Heartbeat:Connect(function() if root.Visible then self:tick(os.clock()) end end)
	end)
	return self
end

function R:shown() return self.root.Visible end
function R:show(r,now)
	self.r=r
	self.started=now or os.clock()
	self.name.Text=Text.upper(r.name or "A THUG")
	self.line.Text=r.line or "Your Ryō, or we fight."
	local lines=R.lines(r)
	for _,choice in R.CHOICES do
		local l=lines[choice]
		self.buttons[choice].Text=l.label
		self.buttons[choice].AutoButtonColor=l.ok
		self.buttons[choice].BackgroundTransparency=if l.ok then 0 else .5
		self.subs[choice].Text=l.sub
	end
	self.root.Visible=true
	self:tick(self.started)
end
function R:hide() self.root.Visible=false;self.r=nil end
function R:tick(now)
	if not self.r then return end
	local total=self.r.seconds or R.FUSE
	local left=math.max(0,total-(now-self.started))
	self.fuse.Size=UDim2.fromScale(left/total,1)
	self.fuseText.Text=string.format("HE SWINGS IN %d s",math.ceil(left))
	if left<=0 then self:choose("fight") end
end
function R:choose(choice)
	local r=self.r
	if not r then return false end
	if choice=="pay" and not R.lines(r).pay.ok then return false end
	self.send("Racket",{id=r.id,choice=choice})
	self:hide()
	return true
end

return R
