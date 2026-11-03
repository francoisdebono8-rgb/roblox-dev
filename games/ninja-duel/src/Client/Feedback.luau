-- The report form (beta, user 03/11): a player tells us about a bug, an idea
-- or what they think, without leaving the game. Opened from the roster
-- ("BUG / IDEA"), the controls sheet and the result card; it is the house
-- ink card (Client/UI). The text goes to the server (Server/Feedback), which
-- filters it, keeps it and forwards it to the Discord; the game adds where it
-- was sent from (screen, fighters, round, device) so a bug can be found again.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local Feedback={}
Feedback.__index=Feedback

local INK=Color3.fromRGB(16,14,19)
local RED=Color3.fromRGB(190,40,36)
local PAPER=Color3.fromRGB(240,232,212)
local MUTED=Color3.fromRGB(170,164,150)
local GOLD=Color3.fromRGB(230,184,86)
local FIELD=Color3.fromRGB(28,26,32)
local TITLE=Enum.Font.Bangers
local BODY=Enum.Font.GothamBold
local MAX=500
local KINDS={
	{"bug","BUG","Something broken or strange: what happened, and what you were doing."},
	{"idea","IDEA","Something you'd like: a move, a fighter, a mode, a change."},
	{"opinion","OPINION","What you liked, what you didn't, how it feels to play."},
}

local function create(class,parent,props)
	local x=Instance.new(class)
	for k,v in props do (x::any)[k]=v end
	x.Parent=parent
	return x
end
local function round(x,r) create("UICorner",x,{CornerRadius=UDim.new(0,r or 6)}) end

-- `context()` returns what the game knows about the moment (see Server/Feedback).
function Feedback.new(gui,context)
	local self=setmetatable({context=context,kind="bug",busy=false},Feedback)
	local veil=create("Frame",gui,{Name="Feedback",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(6,5,8),BackgroundTransparency=.3,
		BorderSizePixel=0,Visible=false,ZIndex=70,Active=true})
	self.veil=veil
	local card=create("Frame",veil,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(640,470),
		BackgroundColor3=INK,BackgroundTransparency=.02,BorderSizePixel=0,ZIndex=71})
	round(card,12)
	create("UIStroke",card,{Color=RED,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local line=create("Frame",card,{Size=UDim2.new(1,0,0,5),BackgroundColor3=RED,BorderSizePixel=0,ZIndex=72});round(line,12)
	local scale=create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=math.clamp(math.min(v.X/700,v.Y/520),.5,1.15)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local title=create("TextLabel",card,{Text="TELL US",Position=UDim2.fromOffset(30,18),Size=UDim2.fromOffset(400,50),Font=TITLE,TextSize=48,
		TextColor3=PAPER,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=72})
	create("UIStroke",title,{Color=Color3.new(0,0,0),Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	create("TextLabel",card,{Text="Beta — every report is read.",Position=UDim2.fromOffset(330,34),Size=UDim2.fromOffset(280,24),Font=BODY,TextSize=14,
		TextColor3=MUTED,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=72})
	-- Kind: three tabs.
	self.tabs={}
	for i,k in KINDS do
		local tab=create("TextButton",card,{Text=k[2],Position=UDim2.fromOffset(30+(i-1)*196,82),Size=UDim2.fromOffset(186,44),Font=TITLE,TextSize=26,
			TextColor3=PAPER,BackgroundColor3=FIELD,BorderSizePixel=0,AutoButtonColor=true,ZIndex=72})
		round(tab,6)
		local edge=create("UIStroke",tab,{Color=GOLD,Thickness=0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		tab.Activated:Connect(function() self:setKind(k[1]) end)
		self.tabs[k[1]]={button=tab,edge=edge,hint=k[3]}
	end
	self.hint=create("TextLabel",card,{Text="",Position=UDim2.fromOffset(30,134),Size=UDim2.fromOffset(580,22),Font=BODY,TextSize=14,
		TextColor3=MUTED,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=72})
	local box=create("TextBox",card,{Text="",PlaceholderText="Write here…",PlaceholderColor3=Color3.fromRGB(110,104,96),Position=UDim2.fromOffset(30,162),
		Size=UDim2.fromOffset(580,170),Font=Enum.Font.GothamMedium,TextSize=17,TextColor3=PAPER,BackgroundColor3=FIELD,BorderSizePixel=0,
		ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=72})
	round(box,8)
	create("UIPadding",box,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10)})
	self.box=box
	self.count=create("TextLabel",card,{Text="0 / "..MAX,Position=UDim2.fromOffset(430,336),Size=UDim2.fromOffset(180,20),Font=BODY,TextSize=13,
		TextColor3=MUTED,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=72})
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text>MAX then box.Text=string.sub(box.Text,1,MAX) end
		self.count.Text=#box.Text.." / "..MAX
	end)
	self.status=create("TextLabel",card,{Text="",Position=UDim2.fromOffset(30,336),Size=UDim2.fromOffset(400,20),Font=BODY,TextSize=14,
		TextColor3=GOLD,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=72})
	local function action(label,x,w,color,callback)
		local b=create("TextButton",card,{Text=label,Position=UDim2.fromOffset(x,382),Size=UDim2.fromOffset(w,56),Font=TITLE,TextSize=28,
			TextColor3=PAPER,BackgroundColor3=color,BorderSizePixel=0,AutoButtonColor=true,ZIndex=72})
		round(b,6)
		b.Activated:Connect(callback)
		return b
	end
	self.cancel=action("CLOSE",30,190,FIELD,function() self:close() end)
	create("UIStroke",self.cancel,{Color=MUTED,Transparency=.55,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.send=action("SEND",236,374,RED,function() self:submit() end)
	pcall(function()
		UIS.InputBegan:Connect(function(input)
			if veil.Visible and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) and not UIS:GetFocusedTextBox() then self:close() end
		end)
	end)
	self:setKind("bug")
	return self
end

function Feedback:setKind(kind)
	self.kind=kind
	for k,tab in self.tabs do
		local on=k==kind
		tab.button.BackgroundColor3=if on then RED else FIELD
		tab.edge.Thickness=if on then 2 else 0
		if on then self.hint.Text=tab.hint end
	end
end

function Feedback:open(kind)
	if kind then self:setKind(kind) end
	self.status.Text="";self.status.TextColor3=GOLD
	self.veil.Visible=true
	pcall(function() game:GetService("GuiService").SelectedObject=self.tabs[self.kind].button end)
end
function Feedback:close()
	self.veil.Visible=false
	pcall(function() self.box:ReleaseFocus() end)
	pcall(function() game:GetService("GuiService").SelectedObject=nil end)
end
function Feedback:isOpen() return self.veil.Visible end

function Feedback:submit()
	if self.busy then return end
	local remote=ReplicatedStorage:FindFirstChild("NinjaDuel") and ReplicatedStorage.NinjaDuel:FindFirstChild("Feedback")
	if not remote then self.status.Text="Reports are not available right now.";return end
	local context={}
	pcall(function() context=self.context() or {} end)
	self.busy=true
	self.status.TextColor3=MUTED;self.status.Text="Sending…"
	task.spawn(function()
		local ok,accepted,message=pcall(function() return remote:InvokeServer({kind=self.kind,text=self.box.Text,context=context}) end)
		self.busy=false
		if not ok then accepted,message=false,"Couldn't send it right now. Try again in a moment." end
		self.status.TextColor3=if accepted then GOLD else Color3.fromRGB(232,110,100)
		self.status.Text=message or ""
		if accepted then
			self.box.Text=""
			task.delay(1.6,function() if self.veil.Visible and self.box.Text=="" then self:close() end end)
		end
	end)
end
return Feedback
