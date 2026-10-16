-- Prodigy Tournament interface: roster/selection, online queue and fighter
-- pick, duel HUD, match intro and result framing. Presentation only; every
-- value comes from the snapshot.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Controls=require(Shared.Controls)
local MoveGraphs=require(Shared.MoveGraphs)
local Protocol=require(Shared.OnlineProtocol)
local GuiService=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local Tween=game:GetService("TweenService")
local UI={}; UI.__index=UI
local palette={
	ink=Color3.fromRGB(16,15,20),panel=Color3.fromRGB(28,26,32),paper=Color3.fromRGB(240,232,212),
	text=Color3.fromRGB(240,236,226),muted=Color3.fromRGB(170,164,150),red=Color3.fromRGB(190,40,36),
	gold=Color3.fromRGB(230,184,86),blue=Color3.fromRGB(82,177,244),crimson=Color3.fromRGB(222,70,80),
	track=Color3.fromRGB(46,42,48),locked=Color3.fromRGB(38,36,42),
}
local TITLE_FONT=Enum.Font.Bangers
local BODY_FONT=Enum.Font.GothamBold
local function create(class,parent,props)
	local x=Instance.new(class)
	for k,v in props do x[k]=v end
	x.Parent=parent; return x
end
local function frame(parent,position,size,color,transparency)
	return create("Frame",parent,{Position=position,Size=size,BackgroundColor3=color or palette.panel,BorderSizePixel=0,BackgroundTransparency=transparency or 0})
end
local function text(parent,value,position,size,fontSize,color,font,align)
	return create("TextLabel",parent,{Text=value,Position=position,Size=size,TextSize=fontSize or 16,Font=font or BODY_FONT,
		TextColor3=color or palette.text,BackgroundTransparency=1,TextXAlignment=align or Enum.TextXAlignment.Left,TextWrapped=true})
end
local function corner(parent,radius) return create("UICorner",parent,{CornerRadius=UDim.new(0,radius or 6)}) end
local function stroke(parent,color,thickness) return create("UIStroke",parent,{Color=color or palette.ink,Thickness=thickness or 2}) end
local function button(parent,value,position,size,callback,color)
	local b=create("TextButton",parent,{Text=value,Position=position,Size=size,TextSize=24,Font=TITLE_FONT,TextColor3=palette.text,
		BackgroundColor3=color or palette.panel,BorderSizePixel=0,AutoButtonColor=true})
	corner(b,6)
	b.Activated:Connect(callback); return b
end
local function accentOf(def) return Color3.fromRGB(table.unpack(def.Color)) end
-- A tiny posed figure built from the fighter's palette.
local function portrait(parent,def,position,size)
	local vp=create("ViewportFrame",parent,{Position=position,Size=size or UDim2.fromOffset(100,116),BackgroundTransparency=1,
		Ambient=Color3.fromRGB(190,186,180),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,-1)})
	local function p(sz,at,color)
		create("Part",vp,{Size=sz,CFrame=CFrame.new(at),Color=if typeof(color)=="Color3" then color else Color3.fromRGB(table.unpack(color)),Anchored=true})
	end
	p(Vector3.new(2,2,1),Vector3.zero,def.Outfit)
	p(Vector3.new(1.6,1.6,1.6),Vector3.new(0,1.7,0),def.Skin)
	p(Vector3.new(1.8,.7,1.8),Vector3.new(0,2.55,0),def.Hair)
	p(Vector3.new(1.7,.25,1.7),Vector3.new(0,2.1,0),Color3.fromRGB(28,36,58))
	for _,s in {-1,1} do p(Vector3.new(.9,2,.9),Vector3.new(s*1.45,0,0),def.Outfit) end
	local camera=create("Camera",vp,{CFrame=CFrame.lookAt(Vector3.new(3.5,2.6,-7.5),Vector3.new(0,.9,0))})
	vp.CurrentCamera=camera
	return vp
end
local ROSTER_SLOTS=20
function UI.new(parent,send)
	local self=setmetatable({player="Flashstep",bot="Mirage",send=send,selectionButtons={},introShown=nil},UI)
	self.gui=create("ScreenGui",parent,{Name="NinjaDuelHUD",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	-- ------------------------------------------------------------ selection
	self.selection=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,.08)
	local shell=frame(self.selection,UDim2.fromScale(.5,.5),UDim2.fromOffset(900,668),palette.ink,1)
	shell.AnchorPoint=Vector2.new(.5,.5)
	local scale=create("UIScale",shell,{Scale=1})
	local function resize() scale.Scale=math.min(1.2,workspace.CurrentCamera.ViewportSize.X/980,workspace.CurrentCamera.ViewportSize.Y/728) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	frame(shell,UDim2.fromOffset(0,74),UDim2.fromOffset(900,4),palette.red)
	text(shell,"PRODIGY TOURNAMENT",UDim2.fromOffset(0,0),UDim2.fromOffset(620,72),64,palette.paper,TITLE_FONT)
	text(shell,"天才忍者大会",UDim2.fromOffset(620,10),UDim2.fromOffset(280,56),40,palette.red,BODY_FONT,Enum.TextXAlignment.Right)
	text(shell,"Twenty future legends. Twelve to fourteen years old. One stage — before they become who they are meant to be.",
		UDim2.fromOffset(2,86),UDim2.fromOffset(896,40),16,palette.muted)
	-- Roster: the two prodigies who have arrived, and the slots still empty.
	local grid=frame(shell,UDim2.fromOffset(0,136),UDim2.fromOffset(900,230),palette.ink,1)
	-- CORE4, then the stress-test fighters of the next wave (DEC-015): Gaara,
	-- Rock Lee.
	local playable={"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf"}
	for index=1,ROSTER_SLOTS do
		local col=(index-1)%10;local row=math.floor((index-1)/10)
		local slot=frame(grid,UDim2.fromOffset(col*90,row*116),UDim2.fromOffset(84,108),palette.locked)
		corner(slot,6)
		local id=playable[index]
		if id then
			local def=Fighters[id]
			slot.BackgroundColor3=palette.panel
			stroke(slot,accentOf(def),2)
			portrait(slot,def,UDim2.fromOffset(2,2),UDim2.fromOffset(80,78))
			text(slot,string.upper(def.Name),UDim2.fromOffset(0,80),UDim2.fromOffset(84,26),20,accentOf(def),TITLE_FONT,Enum.TextXAlignment.Center)
			local pick=create("TextButton",slot,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=""})
			pick.Activated:Connect(function()
				if self.picking then self:choose(id);return end
				self.player=id
				if self.bot==id then self.bot=playable[index%#playable+1] end
				self:refreshSelection()
			end)
			self.selectionButtons["slot"..id]=slot
		else
			text(slot,"?",UDim2.fromOffset(0,14),UDim2.fromOffset(84,56),48,Color3.fromRGB(70,66,74),TITLE_FONT,Enum.TextXAlignment.Center)
			text(slot,"PRODIGY "..index,UDim2.fromOffset(0,78),UDim2.fromOffset(84,22),14,Color3.fromRGB(96,90,98),TITLE_FONT,Enum.TextXAlignment.Center)
		end
	end
	-- Matchup panel.
	self.matchup=text(shell,"",UDim2.fromOffset(0,372),UDim2.fromOffset(900,44),38,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.matchupNote=text(shell,"",UDim2.fromOffset(0,410),UDim2.fromOffset(900,34),13,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	-- The selected fighter's reading of the shared combo grammar.
	self.routeNote=text(shell,"",UDim2.fromOffset(0,440),UDim2.fromOffset(900,16),12,palette.gold,BODY_FONT,Enum.TextXAlignment.Center)
	text(shell,"YOU",UDim2.fromOffset(0,460),UDim2.fromOffset(200,18),14,palette.muted)
	self.opponentLabel=text(shell,"OPPONENT (AI)",UDim2.fromOffset(470,460),UDim2.fromOffset(430,18),14,palette.muted)
	-- Fighter buttons share each half of the panel, however many are playable.
	-- During an online pick the left half is yours, the right shows the opponent's.
	local stride=math.floor(430/#playable)
	for i,id in playable do
		self.selectionButtons["player"..id]=button(shell,string.upper(Fighters[id].Name),UDim2.fromOffset((i-1)*stride,480),UDim2.fromOffset(stride-6,40),function()
			if self.picking then self:choose(id);return end
			self.player=id; self:refreshSelection()
		end)
		self.selectionButtons["bot"..id]=button(shell,string.upper(Fighters[id].Name),UDim2.fromOffset(470+(i-1)*stride,480),UDim2.fromOffset(stride-6,40),function()
			if self.picking then return end
			self.bot=id; self:refreshSelection()
		end)
	end
	-- Six names share each half: a long one (ROCK LEE) shrinks to fit its
	-- button, the others keep their size.
	for _,id in playable do
		for _,side in {"player","bot"} do
			local b=self.selectionButtons[side..id]
			b.TextScaled=true
			create("UITextSizeConstraint",b,{MaxTextSize=24})
		end
	end
	self.startButton=button(shell,"ENTER THE STAGE",UDim2.fromOffset(470,540),UDim2.fromOffset(430,52),function()
		if self.picking then send("Confirm") else send("Start",{player=self.player,bot=self.bot}) end
	end,palette.red)
	self.tutorialButton=button(shell,"TRAINING (TUTORIAL)",UDim2.fromOffset(0,540),UDim2.fromOffset(430,52),function()
		if self.picking then send("Cancel") else send("Tutorial",{player=self.player,bot=self.bot}) end
	end)
	-- Online 1v1 with the fighter chosen above: casual queue, or a private duel
	-- by code (host one, or type a friend's code and join).
	self.onlineRow=frame(shell,UDim2.fromOffset(0,604),UDim2.fromOffset(900,40),palette.ink,1)
	self.queueButton=button(self.onlineRow,"ONLINE DUEL",UDim2.fromOffset(0,0),UDim2.fromOffset(290,40),function() send("Queue",{player=self.player}) end)
	self.hostButton=button(self.onlineRow,"HOST PRIVATE DUEL",UDim2.fromOffset(300,0),UDim2.fromOffset(290,40),function() send("Host",{player=self.player}) end)
	local codeBox=create("TextBox",self.onlineRow,{Position=UDim2.fromOffset(600,0),Size=UDim2.fromOffset(170,40),Text="",PlaceholderText="CODE",
		TextSize=24,Font=TITLE_FONT,TextColor3=palette.text,PlaceholderColor3=palette.muted,BackgroundColor3=palette.panel,BorderSizePixel=0,ClearTextOnFocus=false})
	corner(codeBox,6)
	codeBox:GetPropertyChangedSignal("Text"):Connect(function()
		local clean=string.sub(string.gsub(string.upper(codeBox.Text),"[^A-Z0-9]",""),1,Protocol.CodeLength)
		if clean~=codeBox.Text then codeBox.Text=clean end
	end)
	self.codeBox=codeBox
	self.joinButton=button(self.onlineRow,"JOIN",UDim2.fromOffset(780,0),UDim2.fromOffset(120,40),function() send("Join",{player=self.player,code=codeBox.Text}) end)
	self.notice=text(shell,"",UDim2.fromOffset(0,648),UDim2.fromOffset(900,18),13,palette.gold,BODY_FONT,Enum.TextXAlignment.Center)
	-- ------------------------------------------------------------------ HUD
	self.hud=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	local hudScale=create("UIScale",self.hud,{Scale=1})
	self.hudScale=hudScale
	local function plate(side)
		local right=side=="right"
		local box=frame(self.hud,if right then UDim2.new(1,-24,0,18) else UDim2.fromOffset(24,18),UDim2.fromOffset(440,92),palette.ink,.25)
		box.AnchorPoint=Vector2.new(if right then 1 else 0,0)
		corner(box,8)
		local align=if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		local name=text(box,"",UDim2.fromOffset(14,4),UDim2.fromOffset(412,34),32,palette.paper,TITLE_FONT,align)
		local title=text(box,"",UDim2.fromOffset(14,36),UDim2.fromOffset(412,16),12,palette.muted,BODY_FONT,align)
		local track=frame(box,UDim2.fromOffset(14,56),UDim2.fromOffset(412,14),palette.track)
		corner(track,4)
		local lag=frame(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(240,220,190))
		corner(lag,4)
		local fill=frame(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.gold)
		corner(fill,4)
		if right then lag.AnchorPoint=Vector2.new(1,0);lag.Position=UDim2.fromScale(1,0);fill.AnchorPoint=Vector2.new(1,0);fill.Position=UDim2.fromScale(1,0) end
		local chakraTrack=frame(box,UDim2.fromOffset(14,74),UDim2.fromOffset(412,6),palette.track)
		local chakra=frame(chakraTrack,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.blue)
		if right then chakra.AnchorPoint=Vector2.new(1,0);chakra.Position=UDim2.fromScale(1,0) end
		local status=text(box,"",UDim2.fromOffset(14,80),UDim2.fromOffset(412,12),10,palette.muted,BODY_FONT,align)
		-- Neji's chakra points closed on this fighter: four pips at the far end of
		-- the status row (both players read them), each lit as it closes.
		local points={}
		for k=1,4 do
			local pip=frame(box,UDim2.fromOffset(if right then 19+(k-1)*13 else 421-(k-1)*13,86),UDim2.fromOffset(9,9),palette.track)
			pip.AnchorPoint=Vector2.new(.5,.5);pip.Visible=false
			corner(pip,5)
			points[k]=pip
		end
		-- Substitution charges: two diamonds, the recharging one fills up.
		local pips={}
		for k=1,2 do
			local x=if right then 14+(k-1)*26 else 404-(k-1)*26
			local pip=frame(box,UDim2.fromOffset(x,12),UDim2.fromOffset(16,16),palette.track)
			pip.Rotation=45;pip.ClipsDescendants=true
			local fill=frame(pip,UDim2.fromScale(0,1),UDim2.fromScale(1,1),palette.paper)
			fill.AnchorPoint=Vector2.new(0,1)
			pips[k]={pip=pip,fill=fill}
		end
		local subLabel=text(box,"SUB",UDim2.fromOffset(if right then 68 else 314,14),UDim2.fromOffset(36,12),10,palette.muted,BODY_FONT,
			if right then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right)
		-- Round wins: small medallions under the plate.
		local medals={}
		for k=1,2 do
			local m=frame(box,UDim2.fromOffset(if right then 412-(k-1)*20 else 14+(k-1)*20,96),UDim2.fromOffset(14,14),palette.track)
			corner(m,7);table.insert(medals,m)
		end
		-- The awakening while it burns: its name, the time left and what it
		-- changes in the fight (UI.awakening), under the plate.
		local awake=text(box,"",UDim2.fromOffset(14,114),UDim2.fromOffset(412,30),13,palette.gold,TITLE_FONT,align)
		create("UIStroke",awake,{Color=palette.ink,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		return {box=box,name=name,title=title,fill=fill,lag=lag,chakra=chakra,status=status,pips=pips,subLabel=subLabel,medals=medals,points=points,pointsShown=0,awake=awake}
	end
	self.hp=plate("left")
	self.enemy=plate("right")
	self.round=text(self.hud,"ROUND 1",UDim2.new(.5,-120,0,22),UDim2.fromOffset(240,30),26,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.roundSub=text(self.hud,"PRODIGY TOURNAMENT",UDim2.new(.5,-120,0,50),UDim2.fromOffset(240,16),11,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.cue=text(self.hud,"",UDim2.new(.5,-300,0,124),UDim2.fromOffset(600,40),30,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.cue,{Color=palette.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.channel=text(self.hud,"",UDim2.new(.5,-250,0,166),UDim2.fromOffset(500,28),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.statusLine=text(self.hud,"",UDim2.new(0,24,1,-118),UDim2.fromOffset(420,16),12,palette.muted)
	-- Combo counters: yours on the left, the opponent's on you on the right.
	local function counter(side)
		local right=side=="right"
		local box=frame(self.hud,if right then UDim2.new(1,-40,.36,0) else UDim2.new(0,40,.36,0),UDim2.fromOffset(220,90),palette.ink,1)
		box.AnchorPoint=Vector2.new(if right then 1 else 0,0)
		local align=if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		local hits=text(box,"",UDim2.fromOffset(0,0),UDim2.fromOffset(220,56),54,palette.paper,TITLE_FONT,align)
		create("UIStroke",hits,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		local detail=text(box,"",UDim2.fromOffset(0,56),UDim2.fromOffset(220,18),14,palette.gold,BODY_FONT,align)
		create("UIStroke",detail,{Color=palette.ink,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		return {box=box,hits=hits,detail=detail,shown=0}
	end
	self.comboMine=counter("left")
	self.comboTheirs=counter("right")
	self.techniqueButtons={}
	for i=1,5 do
		local box=frame(self.hud,UDim2.new(.5,-440+(i-1)*178,1,-122),UDim2.fromOffset(170,58),palette.ink,.2)
		corner(box,8)
		local key=text(box,"",UDim2.fromOffset(8,4),UDim2.fromOffset(154,18),14,palette.gold,TITLE_FONT)
		local title=text(box,"",UDim2.fromOffset(8,22),UDim2.fromOffset(154,20),18,palette.paper,TITLE_FONT)
		local status=text(box,"",UDim2.fromOffset(8,43),UDim2.fromOffset(154,12),11,palette.muted)
		local cool=frame(box,UDim2.fromScale(0,1),UDim2.fromScale(1,0),palette.ink,.35)
		cool.AnchorPoint=Vector2.new(0,1);corner(cool,8)
		self.techniqueButtons[i]={box=box,key=key,title=title,status=status,cool=cool}
	end
	self.help=text(self.hud,Controls.Help,UDim2.new(.5,-640,1,-30),UDim2.fromOffset(1280,22),11,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.grammar=text(self.hud,Controls.Grammar,UDim2.new(.5,-640,1,-48),UDim2.fromOffset(1280,18),11,Color3.fromRGB(196,176,130),BODY_FONT,Enum.TextXAlignment.Center)
	self.hint=text(self.hud,"",UDim2.new(.5,-260,0,200),UDim2.fromOffset(520,30),18,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.ko=text(self.hud,"K.O.",UDim2.new(.5,-300,.3,0),UDim2.fromOffset(600,130),120,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.ko,{Color=palette.red,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.ko.Visible=false
	-- ---------------------------------------------------------------- intro
	self.intro=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	self.introLeft=frame(self.intro,UDim2.new(0,0,.62,0),UDim2.new(.5,0,0,110),palette.ink,.15)
	self.introRight=frame(self.intro,UDim2.new(.5,0,.62,0),UDim2.new(.5,0,0,110),palette.ink,.15)
	self.introLeftName=text(self.introLeft,"",UDim2.new(0,40,0,6),UDim2.new(1,-80,0,64),64,palette.paper,TITLE_FONT)
	self.introLeftTitle=text(self.introLeft,"",UDim2.new(0,42,0,70),UDim2.new(1,-80,0,26),18,palette.muted)
	self.introRightName=text(self.introRight,"",UDim2.new(0,40,0,6),UDim2.new(1,-80,0,64),64,palette.paper,TITLE_FONT,Enum.TextXAlignment.Right)
	self.introRightTitle=text(self.introRight,"",UDim2.new(0,40,0,70),UDim2.new(1,-82,0,26),18,palette.muted,BODY_FONT,Enum.TextXAlignment.Right)
	self.introVs=text(self.intro,"VS",UDim2.new(.5,-80,.62,8),UDim2.fromOffset(160,96),88,palette.red,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.introVs,{Color=palette.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.introRound=text(self.intro,"",UDim2.new(.5,-400,.5,-48),UDim2.fromOffset(800,40),30,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.introBegin=text(self.intro,"",UDim2.new(.5,-400,.38,-60),UDim2.fromOffset(800,120),120,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.introBegin,{Color=palette.red,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.intro.Visible=false
	-- --------------------------------------------------------------- result
	self.result=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,.25)
	local resultBox=frame(self.result,UDim2.new(.5,-300,.5,-170),UDim2.fromOffset(600,340),palette.ink,.1)
	corner(resultBox,10)
	stroke(resultBox,palette.red,3)
	self.resultBox=resultBox
	self.resultTitle=text(resultBox,"",UDim2.fromOffset(30,18),UDim2.fromOffset(540,70),72,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.resultName=text(resultBox,"",UDim2.fromOffset(30,92),UDim2.fromOffset(540,36),30,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.resultNote=text(resultBox,"",UDim2.fromOffset(30,132),UDim2.fromOffset(540,44),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.rematchButton=button(resultBox,"REMATCH",UDim2.fromOffset(30,196),UDim2.fromOffset(540,52),function() send("Rematch") end,palette.red)
	button(resultBox,"RETURN TO THE ROSTER",UDim2.fromOffset(30,260),UDim2.fromOffset(540,52),function() send("Selection") end)
	-- ---------------------------------------------------------- online queue
	self.queue=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,.25)
	local queueBox=frame(self.queue,UDim2.new(.5,-300,.5,-150),UDim2.fromOffset(600,300),palette.ink,.1)
	corner(queueBox,10)
	stroke(queueBox,palette.red,3)
	self.queueTitle=text(queueBox,"",UDim2.fromOffset(30,18),UDim2.fromOffset(540,56),48,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.queueCode=text(queueBox,"",UDim2.fromOffset(30,80),UDim2.fromOffset(540,70),72,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.queueNote=text(queueBox,"",UDim2.fromOffset(30,154),UDim2.fromOffset(540,44),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.cancelButton=button(queueBox,"CANCEL",UDim2.fromOffset(30,222),UDim2.fromOffset(540,52),function() send("Cancel") end)
	self.queue.Visible=false
	-- The genjutsu image carries no label: the world shows it (Presentation:illusion).
	self.tutorialPanel=frame(self.hud,UDim2.new(.5,-260,0,84),UDim2.fromOffset(520,90),palette.ink,.15)
	corner(self.tutorialPanel,8)
	self.tutorialTitle=text(self.tutorialPanel,"",UDim2.fromOffset(16,6),UDim2.fromOffset(490,30),24,palette.paper,TITLE_FONT)
	self.tutorialPrompt=text(self.tutorialPanel,"",UDim2.fromOffset(16,40),UDim2.fromOffset(490,40),14,palette.muted)
	GuiService.AutoSelectGuiEnabled=true
	-- HUD scale follows the viewport so plates and slots never leave the screen.
	local function fitHud()
		local size=workspace.CurrentCamera.ViewportSize
		local s=math.clamp(math.min(size.X/1500,size.Y/860),.55,1.25)
		-- Studio capture aid (see Camera): shrink the HUD into the visible region.
		if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("NinjaDuelCaptureShift") then s*=.66 end
		hudScale.Scale=s
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitHud);fitHud()
	self:refreshSelection(); self:render({phase="Selection"})
	return self
end
function UI:refreshSelection()
	-- During an online pick the right half shows the opponent's live choice.
	local other=if self.picking and Fighters[self.opponentPick or ""] then self.opponentPick else self.bot
	for key,b in self.selectionButtons do
		local selected=key=="player"..self.player or key=="bot"..other or key=="slot"..self.player
		b.BackgroundColor3=if selected then Color3.fromRGB(120,36,34) else palette.panel
	end
	local p,o=Fighters[self.player],Fighters[other]
	self.matchup.Text=string.upper((p.FullName or p.Name).."  VS  "..(o.FullName or o.Name))
	self.matchupNote.Text=(p.Description or "").."\n"..(o.Description or "")
	self.routeNote.Text=if p.Routes then string.upper(p.Name).." STRINGS  "..p.Routes else ""
end
-- Online pick: your fighter changes until you confirm; the server echoes it.
function UI:choose(id)
	if self.onlineInfo and self.onlineInfo.ready then return end
	self.player=id;self:refreshSelection();self.send("Pick",{player=id})
end
-- Roster, online waiting screen and online pick (the roster in versus mode).
function UI:lobby(data)
	local online=data.online
	self.picking=data.phase=="Pick" and online~=nil
	if self.picking then
		if Fighters[online.me or ""] then self.player=online.me end
		self.opponentPick=online.them
		self.opponentLabel.Text="OPPONENT  •  "..string.upper(online.opponent or "")..(if online.theirReady then "  •  READY" else "")
		self.startButton.Text=if online.ready then "READY  •  WAITING FOR OPPONENT" else "READY"
		self.tutorialButton.Text="LEAVE"
		self.notice.Text=string.format("ONLINE 1v1  •  THE DUEL STARTS IN %d s",math.ceil(online.remaining or 0))
	else
		self.opponentPick=nil
		self.opponentLabel.Text="OPPONENT (AI)"
		self.startButton.Text="ENTER THE STAGE"
		self.tutorialButton.Text="TRAINING (TUTORIAL)"
		self.notice.Text=data.notice or ""
	end
	self.onlineRow.Visible=data.phase=="Selection"
	if data.phase=="Queue" then
		local private=online~=nil and online.mode=="private"
		self.queueTitle.Text=if private then "PRIVATE DUEL" else "SEARCHING FOR AN OPPONENT"
		self.queueCode.Text=if private then (online.code or "") else ""
		self.queueNote.Text=if private then "Share this code: your friend types it next to JOIN on the roster screen."
			else "Casual 1v1  •  you meet the next player who searches."
	end
	self:refreshSelection()
end
local function fullName(actor)
	local def=Fighters[actor.fighterId]
	return string.upper(def and def.FullName or actor.fighter or "")
end
local function subtitle(actor)
	local def=Fighters[actor.fighterId]
	if not def then return "" end
	return string.format("AGE %d  •  %s",def.Age or 13,def.Title or "")
end
-- Server cues name keyboard keys; a pad player reads the pad button instead
-- (labels from Controls, so the copy cannot drift from the bindings).
function UI.padCue(cue)
	local P=Controls.PadLabel
	cue=cue:gsub("SPACE REBOUND",P.Jump.." REBOUND"):gsub("C DETACH",P.WallDetach.." DETACH")
	cue=cue:gsub("• E ","• "..P.Pursuit.." "):gsub("X TO ESCAPE",P.Substitute.." TO ESCAPE")
	cue=cue:gsub("• 1 = ","• "..Controls.TechniquePad[1].." = ")
	return cue
end
-- A plate's chakra network (Neji): four pips, lit per closed point (a fresh one
-- pops), shown whenever the opponent fights with the Gentle Fist; the chakra
-- bar dims with the recovery the points cost.
local HYUGA=Color3.fromRGB(190,208,255)
function UI.network(widget,actor,foe)
	local count=#(actor.tenketsuPoints or {})
	if count==0 then count=actor.tenketsu or 0 end
	local shown=(foe and foe.fighterId=="GentleFist") or count>0
	local severe=actor.tenketsuSevere==true
	for k,pip in widget.points do
		pip.Visible=shown
		pip.BackgroundColor3=if k<=count then (if severe then palette.paper else HYUGA) else palette.track
		if k<=count and k>widget.pointsShown then
			pip.Size=UDim2.fromOffset(15,15)
			Tween:Create(pip,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(9,9)}):Play()
		end
	end
	widget.pointsShown=count
	local regen=math.clamp(actor.chakraRegen or 1,0,1)
	widget.chakra.BackgroundColor3=if regen<1 then palette.blue:Lerp(Color3.fromRGB(112,118,138),math.min(1,(1-regen)*1.4)) else palette.blue
end
-- What each CORE4 awakening changes in the fight, said while it burns (a
-- fighter without a line here shows its name and time only).
local AWAKENED={
	Flashstep="EACH JUMP LEAVES A RETURN SEAL  •  FLASH ONTO A LAUNCHED BODY",
	GentleFist="NO BLIND SPOT  •  ONE PALM CLOSES TWO POINTS",
	Mirage="HIS GUARD READS  •  A MISS NEAR HIM IS READ",
	Lion="KICKS DO NOT LET GO  •  LAUNCHERS BECOME THE DANCING LEAF",
}
UI.AWAKENED=AWAKENED
function UI.awakening(actor)
	if (actor.awaken or 0)<=0 or (actor.health or 1)<=0 then return "" end
	local def=Fighters[actor.fighterId]
	local name=def and def.Awakening and def.Awakening.Name or "AWAKENED"
	local line=string.format("%s  %.1fs",name,actor.awaken)
	if actor.curseHunger then return line.."  •  HUNGRY: LAND A BLOW" end
	return if AWAKENED[actor.fighterId] then line.."  •  "..AWAKENED[actor.fighterId] else line
end
-- The counter a read, a repel or a caught image opened: named, with the time
-- it stays open (it closes fast; the HUD says how fast).
local COUNTER_NAME={CounterPalm="COUNTER PALM",PalmThrust="TWIN PALM"}
function UI.counterPrompt(h,pad)
	local move=(MoveGraphs[h.fighterId] or {}).readCounter
	local name=COUNTER_NAME[move or ""] or "COUNTER"
	return string.format("%s — %s  %.1fs",if pad then Controls.PadLabel.Light else Controls.KeyLabel.Light,name,h.counter or 0)
end
-- Contextual prompts for a conversion that is open right now (nil: none):
-- after a teleport the arrival strike or Rasengan, after the Dancing Leaf the
-- air finisher.
function UI.conversion(h,pad)
	local light=if pad then Controls.PadLabel.Light else Controls.KeyLabel.Light
	local heavy=if pad then Controls.PadLabel.Heavy else Controls.KeyLabel.Heavy
	if h.flash then
		local line=light.." — ARRIVAL STRIKE  •  "..heavy.." — LAUNCH"
		for i,tech in h.techniques or {} do
			if tech.id=="BurstStrike" and tech.remaining==0 and h.chakra>=tech.cost and (h.sealed or 0)<=0 then
				line..="  •  "..(if pad then Controls.TechniquePad[i] else tostring(i)).." — RASENGAN"
			end
		end
		return line
	end
	if (h.lion or 0)>0 and h.airborne then
		local finisher=(MoveGraphs[h.fighterId] or {}).airFinisher
		return heavy.." — "..(if finisher then finisher.cue else "LION COMBO")
	end
	return nil
end
function UI:render(data)
	local pad=if data.gamepad~=nil then data.gamepad else Controls.isGamepad(UIS:GetLastInputType())
	self.tutorialPanel.Visible=data.tutorial~=nil and data.phase=="Duel"
	if data.tutorial then
		self.tutorialTitle.Text=data.tutorial.index.." / "..data.tutorial.total.."  "..data.tutorial.title
		self.tutorialPrompt.Text=(if pad then data.tutorial.pad else data.tutorial.key).."  •  "..(if pad then "Touchpad to skip" else "ESC to skip")
	end
	local introActive=data.phase=="Duel" and (data.intro or 0)>0
	self.onlineInfo=data.online
	self.selection.Visible=data.phase=="Selection" or data.phase=="Pick"; self.hud.Visible=data.phase=="Duel" and not introActive; self.result.Visible=data.phase=="Result"
	self.queue.Visible=data.phase=="Queue"
	self.intro.Visible=introActive
	-- Gamepad focus moves only after the matching screen is visible.
	if self.lastPhase~=data.phase then
		GuiService.SelectedObject=if data.phase=="Selection" or data.phase=="Pick" then self.startButton elseif data.phase=="Result" then self.rematchButton
			elseif data.phase=="Queue" then self.cancelButton else nil
		self.lastPhase=data.phase
	end
	if data.phase~="Duel" and data.phase~="Result" then self:lobby(data);return end
	local h,b=data.human,data.bot
	if not h or not b then return end
	if introActive then
		self.introLeftName.Text=fullName(h);self.introLeftTitle.Text=subtitle(h)
		self.introRightName.Text=fullName(b);self.introRightTitle.Text=subtitle(b)
		self.introLeftName.TextColor3=accentOf(Fighters[h.fighterId]);self.introRightName.TextColor3=accentOf(Fighters[b.fighterId])
		self.introRound.Text="PRODIGY TOURNAMENT  —  ROUND "..(data.round or 1)..(if (data.round or 1)>1 and (data.wins and (data.wins.human==1 and data.wins.bot==1)) then "  •  FINAL ROUND" else "")
		self.introBegin.Text=if data.intro<.75 then "始め!  BEGIN" else ""
		if self.introShown~=data.epoch then
			self.introShown=data.epoch
			self.introLeft.Position=UDim2.new(-.5,0,.62,0);self.introRight.Position=UDim2.new(1,0,.62,0)
			Tween:Create(self.introLeft,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,.62,0)}):Play()
			Tween:Create(self.introRight,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,.62,0)}):Play()
		end
		return
	end
	if data.ko and not self.ko.Visible then
		self.ko.TextSize=170
		Tween:Create(self.ko,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextSize=120}):Play()
	end
	self.ko.Visible=data.ko==true
	self.round.Text=if data.matchPoint and data.ko then "MATCH" else "ROUND "..(data.round or 1)
	self.hp.name.Text=fullName(h);self.hp.title.Text=subtitle(h).."  •  YOU"
	self.enemy.name.Text=fullName(b);self.enemy.title.Text=(if data.online then string.upper(data.online.opponent or "OPPONENT") else "AI").."  •  "..subtitle(b)
	for _,pair in {{self.hp,h},{self.enemy,b}} do
		local widget,actor=pair[1],pair[2]
		local ratio=math.clamp(actor.health/actor.maxHealth,0,1)
		widget.fill.Size=UDim2.fromScale(ratio,1)
		widget.fill.BackgroundColor3=if ratio>.5 then palette.gold elseif ratio>.25 then Color3.fromRGB(236,134,60) else palette.red
		Tween:Create(widget.lag,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.25),{Size=UDim2.fromScale(ratio,1)}):Play()
		widget.chakra.Size=UDim2.fromScale(math.clamp(actor.chakra/actor.maxChakra,0,1),1)
		widget.status.Text=string.format("%d / %d",math.ceil(actor.health),actor.maxHealth)
		-- Gentle Fist effects on this fighter: the closed points (pips), what
		-- they cost (the chakra bar dims, its recovery is spelled out) and the
		-- jutsu the 64 Palms sealed.
		UI.network(widget,actor,if actor==h then b else h)
		widget.awake.Text=UI.awakening(actor)
		local tone=Fighters[actor.fighterId] and Fighters[actor.fighterId].Awakening and Fighters[actor.fighterId].Awakening.Color
		widget.awake.TextColor3=if tone then Color3.fromRGB(table.unpack(tone)) else palette.gold
		if (actor.sealed or 0)>0 then widget.status.Text..=string.format("   •   JUTSU SEALED %.1fs",actor.sealed)
		elseif (actor.chakraRegen or 1)<1 then widget.status.Text..=string.format("   •   CHAKRA REGEN -%d%%%s",math.floor((1-actor.chakraRegen)*100+.5),if actor.tenketsuSevere then "  •  NETWORK SEALED" else "") end
		local won=if actor==h then (data.wins and data.wins.human or 0) else (data.wins and data.wins.bot or 0)
		for k,m in widget.medals do
			m.Visible=(data.roundsToWin or 1)>1 and k<=(data.roundsToWin or 1)
			m.BackgroundColor3=if k<=won then palette.gold else palette.track
		end
		local charges=actor.subCharges or 0
		for k,pip in widget.pips do
			local level=if k<=charges then 1 elseif k==charges+1 and (actor.subRegen or 0)>0 then 1-math.clamp((actor.subRegen or 0)/9,0,1) else 0
			pip.fill.Size=UDim2.fromScale(1,level)
			pip.fill.BackgroundColor3=if k<=charges then palette.paper else palette.muted
		end
	end
	-- Combo counters with the damage scale of the next hit.
	for _,pair in {{self.comboMine,b},{self.comboTheirs,h}} do
		local widget,victim=pair[1],pair[2]
		local hits=victim.comboHits or 0
		if hits>=2 then
			local scale=math.max(.35,1-.12*math.max(0,hits-1))
			widget.hits.Text=hits.." HITS"
			widget.detail.Text=string.format("%d DMG  •  NEXT x%.2f",math.floor((victim.comboDamage or 0)+.5),scale)
			widget.box.Visible=true
			if hits~=widget.shown then
				widget.shown=hits
				widget.hits.TextSize=64
				Tween:Create(widget.hits,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextSize=54}):Play()
			end
		else
			widget.box.Visible=false;widget.shown=0
		end
	end
	self.statusLine.Text=string.format("STAMINA %d   •   SUBSTITUTION %d   •   %s",math.floor(h.stamina or 100),h.subCharges or 0,
		if h.wall then "WALL RUN" elseif h.dodge>0 then string.format("DASH %.1fs",h.dodge) else "DASH READY")
	-- Only decisive moments speak; routine cues stay silent.
	local cue=h.cue or ""
	local loud=cue:find("READ") or cue:find("PARRY") or cue:find("PERFECT") or cue:find("FLYING THUNDER") or cue:find("GUARD BREAK") or cue:find("WALL ")
		or cue:find("CLASH") or cue:find("SUBSTITUTION •") or cue:find("SEAL") or cue:find("COMBO LIMIT") or cue:find("GENJUTSU")
		or cue:find("PALMS") or cue:find("ROTATION") or cue:find("BYAKUGAN") or cue:find("SHARINGAN")
		or cue:find("FLOW") or cue:find("AWAKEN") or cue:find("THROW BREAK") or cue:find("KNOCK AWAY") or cue:find("RIPOSTE")
		-- Caught in wire or sand: the way out must be on screen.
		or cue:find("WIRED") or cue:find("BOUND")
	if loud and pad then cue=UI.padCue(cue) end
	self.cue.Text=if loud then cue else ""
	self.channel.Text=""
	for i,tech in h.techniques do
		local ui=self.techniqueButtons[i]
		ui.box.Visible=true
		ui.key.Text=if pad then Controls.TechniquePad[i] else string.format("%d",i)
		ui.title.Text=string.upper(tech.name)
		-- Sealed by the 64 Palms: every jutsu greys out and says why.
		local sealed=(h.sealed or 0)>0
		local ready=tech.remaining==0 and tech.condition and h.chakra>=tech.cost and not sealed
		ui.status.Text=if sealed then string.format("SEALED  •  %.1fs",h.sealed) elseif tech.remaining>0 then string.format("%.1fs",tech.remaining) elseif not tech.condition then "NEEDS A SEAL / TARGET" elseif h.chakra<tech.cost then "NEED CHAKRA" else tech.cost.." CHAKRA"
		if tech.id=="Flashstep" and #(h.seals or {})>0 and tech.remaining==0 and not sealed then
			local count=#(h.seals or {})
			ui.status.Text=count.." SEAL"..(if count>1 then "S" else "").."  •  "..ui.status.Text
		end
		ui.box.BackgroundTransparency=if ready then .05 else .35
		ui.title.TextColor3=if ready then palette.paper else palette.muted
		ui.cool.Size=UDim2.fromScale(1,math.clamp(math.max(tech.remaining/6,if sealed then h.sealed/5 else 0),0,1))
	end
	for i=#h.techniques+1,5 do self.techniqueButtons[i].box.Visible=false end
	local techOpen=h.reaction=="WallSplat" and (h.splatElapsed or 9)<.34
	local conversion=UI.conversion(h,pad)
	self.hint.Text=if techOpen then (if pad then "○ — WALL TECH" else "Q — WALL TECH")
		elseif conversion then conversion
		elseif b.reaction=="WallSplat" and h.pursuit>0 then (if pad then "× — PURSUE  •  △ — WALL BOUNCE" else Controls.KeyLabel.Pursuit.." — PURSUE  •  RMB — WALL BOUNCE")
		elseif (h.counter or 0)>0 then UI.counterPrompt(h,pad)
		elseif h.awakenReady then (if pad then "D-PAD ↓ — AWAKEN" else "T — AWAKEN")
		elseif h.wall then (if pad then "× — REBOUND  •  R1 + L1 — DETACH" else "SPACE — REBOUND  •  C — DETACH")
		elseif h.state=="Startup" and h.attackName=="Heavy" then (if pad then "R1 + L2 — FEINT" else "G — FEINT")
		elseif h.reaction=="Grabbed" then (if pad then "L2 — THROW BREAK" else "V — THROW BREAK")
		elseif h.pursuit>0 then (if pad then "× — CHASE" else Controls.KeyLabel.Pursuit.." / SPACE — CHASE")
		elseif (h.combo or 0)>=2 and h.state=="Recovery" and not h.airborne and (h.comboHits or 0)==0 and b.reaction then Controls.comboHelp(MoveGraphs[h.fighterId] or {},pad)
		else ""
	self.help.Text=if pad then Controls.HelpPad else Controls.Help
	self.grammar.Text=Controls.comboHelp(MoveGraphs[h.fighterId] or {},pad)
	local won=data.winner=="PlayerFighter"
	local winner=if won then h else b
	self.resultTitle.Text=(if won then "VICTORY" else "DEFEAT")..(if (data.roundsToWin or 1)>1 and data.wins then string.format("  %d–%d",data.wins.human or 0,data.wins.bot or 0) else "")
	self.resultTitle.TextColor3=if won then palette.gold else palette.crimson
	self.resultName.Text=fullName(winner).."  ADVANCES"
	self.resultNote.Text=if won then "The judges saw it too. The bracket waits for no one." else "Read the commitment. Find a better opening — prodigies learn fastest from defeat."
	-- Online: a rematch needs both players; a forfeit says so.
	local online=data.online
	self.rematchButton.Text=if not online then "REMATCH" elseif online.opponentLeft then "OPPONENT LEFT" elseif online.rematch then "WAITING FOR OPPONENT…"
		elseif online.theirRematch then "REMATCH  •  OPPONENT IS READY" else "REMATCH"
	if online and online.forfeit then
		self.resultTitle.Text=(if won then "VICTORY" else "DEFEAT").."  •  FORFEIT"
		self.resultNote.Text="Your opponent left the duel. The win is yours."
	end
end
return UI
