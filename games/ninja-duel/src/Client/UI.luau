-- Prodigy Tournament interface: roster/selection, online queue and fighter
-- pick, duel HUD, match intro and result framing. Presentation only; every
-- value comes from the snapshot.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Roster=require(Shared.Roster)
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
	-- (UI pass 02/11) A dark button on the dark menu read as disabled
	-- (TRAINING, ONLINE DUEL, HOST): a light edge says it can be pressed.
	if not color then create("UIStroke",b,{Color=palette.muted,Transparency=.55,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
	b.Activated:Connect(callback); return b
end
local function accentOf(def) return Color3.fromRGB(table.unpack(def.Color)) end
-- A prodigy in a ViewportFrame (Server/Portraits builds the posed rigs):
-- `face` frames the head for a roster tablet, `body` the whole fighter on a
-- stage, turned three quarters toward the other stage.
local function clearView(view)
	for _,c in view:GetChildren() do if c:IsA("Model") or c:IsA("Camera") or c:IsA("WorldModel") then c:Destroy() end end
end
function UI.frameFace(view,source)
	if not view or not source then return end
	clearView(view)
	local model=source:Clone()
	if not model then return end
	model.Parent=view
	local head=model:FindFirstChild("Head")
	if not head then return end
	-- The rig faces -Z, toward the camera; a quarter turn shows the face's depth.
	model:PivotTo(CFrame.Angles(0,math.rad(18),0))
	local at=head.Position+Vector3.new(0,.15,0)
	local camera=Instance.new("Camera");camera.FieldOfView=26
	camera.CFrame=CFrame.lookAt(at+Vector3.new(.9,.35,-5.4),at);camera.Parent=view
	view.CurrentCamera=camera
end
function UI.frameBody(view,source,right)
	if not view or not source then return end
	clearView(view)
	local model=source:Clone()
	if not model then return end
	model.Parent=view
	-- Facing the camera (-Z), turned toward the middle of the screen.
	model:PivotTo(CFrame.Angles(0,math.rad(if right then -28 else 28),0))
	local cf,size=model:GetBoundingBox()
	local center=cf.Position+Vector3.new(0,-.15,0)
	local camera=Instance.new("Camera");camera.FieldOfView=30
	local distance=(size.Y*.5+.6)/math.tan(math.rad(15))
	camera.CFrame=CFrame.lookAt(center+Vector3.new(0,.6,-distance),center);camera.Parent=view
	view.CurrentCamera=camera
end
function UI.new(parent,send)
	local self=setmetatable({player="Flashstep",bot="Mirage",send=send,selectionButtons={},introShown=nil},UI)
	self.gui=create("ScreenGui",parent,{Name="NinjaDuelHUD",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	-- ------------------------------------------------------------ selection
	-- (UI redesign 02/11, user: "be original in everything, you can change
	-- everything".) The tournament's call-up board: two stages where the
	-- chosen prodigies stand as they fight (the duel's own rigs, posed:
	-- Server/Portraits), a vermilion brush stroke between them, one roster of
	-- name tablets underneath. A tablet goes to the stage being chosen (yours
	-- unless you pick the other stage). Canvas 1600x900, scaled to the screen.
	self.side="player"
	self.selection=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,0)
	-- (Gradients only where the engine has them: the headless suites do not.)
	local hasSequences=ColorSequence~=nil and NumberSequence~=nil and NumberSequenceKeypoint~=nil
	if hasSequences then create("UIGradient",self.selection,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(30,26,32),Color3.fromRGB(10,9,12))}) end
	local shell=frame(self.selection,UDim2.fromScale(.5,.5),UDim2.fromOffset(1600,900),palette.ink,1)
	shell.AnchorPoint=Vector2.new(.5,.5)
	local scale=create("UIScale",shell,{Scale=1})
	local function resize() scale.Scale=math.min(1.25,workspace.CurrentCamera.ViewportSize.X/1600,workspace.CurrentCamera.ViewportSize.Y/900) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	-- The brush stroke the two stages stand on.
	local band=frame(shell,UDim2.fromOffset(800,330),UDim2.fromOffset(2100,250),palette.red,.1)
	band.AnchorPoint=Vector2.new(.5,.5);band.Rotation=-9
	if hasSequences then create("UIGradient",band,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.18,.55),NumberSequenceKeypoint.new(.5,.05),NumberSequenceKeypoint.new(.82,.55),NumberSequenceKeypoint.new(1,1)})}) end
	local band2=frame(shell,UDim2.fromOffset(800,350),UDim2.fromOffset(2100,26),palette.ink,.35)
	band2.AnchorPoint=Vector2.new(.5,.5);band2.Rotation=-9
	-- Title, top left; the hanging banner, right edge.
	local title=text(shell,"PRODIGY TOURNAMENT",UDim2.fromOffset(60,18),UDim2.fromOffset(900,70),62,palette.paper,TITLE_FONT)
	create("UIStroke",title,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	text(shell,"Twenty future legends. Twelve to fourteen years old. One stage — before they become who they are meant to be.",
		UDim2.fromOffset(62,84),UDim2.fromOffset(1100,20),15,palette.muted,Enum.Font.GothamMedium)
	local banner=frame(shell,UDim2.fromOffset(1534,0),UDim2.fromOffset(44,280),palette.paper,0)
	create("UIStroke",banner,{Color=palette.red,Thickness=2})
	text(banner,"天\n才\n忍\n者\n大\n会",UDim2.fromOffset(0,12),UDim2.fromOffset(44,240),26,palette.red,BODY_FONT,Enum.TextXAlignment.Center).LineHeight=.95
	frame(shell,UDim2.fromOffset(1553,280),UDim2.fromOffset(6,40),palette.red,0)
	-- The two stages.
	local function stage(side)
		local right=side=="bot"
		local x=if right then 960 else 60
		local box=create("TextButton",shell,{Position=UDim2.fromOffset(x,104),Size=UDim2.fromOffset(550,490),BackgroundTransparency=1,Text="",AutoButtonColor=false})
		local view=create("ViewportFrame",box,{Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(550,380),BackgroundTransparency=1,
			Ambient=Color3.fromRGB(150,140,135),LightColor=Color3.fromRGB(255,236,210),LightDirection=Vector3.new(if right then 1 else -1,-1,-.6)})
		local shadow=frame(box,UDim2.fromOffset(275,368),UDim2.fromOffset(230,26),palette.ink,.45)
		shadow.AnchorPoint=Vector2.new(.5,.5);corner(shadow,13);shadow.ZIndex=0
		local align=if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		-- The tag over the stage: YOU / OPPONENT, and which stage takes the next tablet.
		local tag=frame(box,UDim2.fromOffset(if right then 550-190 else 0,0),UDim2.fromOffset(190,30),palette.paper,0)
		local tagText=text(tag,if right then "OPPONENT (AI)" else "YOU",UDim2.fromOffset(10,0),UDim2.fromOffset(170,30),20,palette.ink,TITLE_FONT,align)
		tagText.TextScaled=true;create("UITextSizeConstraint",tagText,{MaxTextSize=20})
		local choosing=text(box,"◀ CHOOSING",UDim2.fromOffset(if right then 550-190-130 else 200,0),UDim2.fromOffset(120,30),16,palette.gold,TITLE_FONT,align)
		if not right then choosing.Text="CHOOSING ▶" end
		local name=text(box,"",UDim2.fromOffset(0,378),UDim2.fromOffset(550,54),52,palette.paper,TITLE_FONT,align)
		create("UIStroke",name,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		local sub=text(box,"",UDim2.fromOffset(2,430),UDim2.fromOffset(546,18),14,palette.gold,BODY_FONT,align)
		local note=text(box,"",UDim2.fromOffset(2,450),UDim2.fromOffset(546,40),14,palette.text,Enum.Font.GothamMedium,align)
		note.TextYAlignment=Enum.TextYAlignment.Top
		box.Activated:Connect(function() if not self.picking or side=="player" then self.side=side;self:refreshSelection() end end)
		return {box=box,view=view,tag=tag,tagText=tagText,choosing=choosing,name=name,sub=sub,note=note,shown=nil,right=right}
	end
	self.stages={player=stage("player"),bot=stage("bot")}
	self.opponentLabel=self.stages.bot.tagText
	-- VS, and the matchup line under it.
	local vs=text(shell,"VS",UDim2.fromOffset(800,300),UDim2.fromOffset(240,150),128,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	vs.AnchorPoint=Vector2.new(.5,.5);vs.Rotation=-9
	create("UIStroke",vs,{Color=palette.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.matchup=text(shell,"",UDim2.fromOffset(800,392),UDim2.fromOffset(360,40),18,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.matchup.AnchorPoint=Vector2.new(.5,0);self.matchup.Rotation=-9
	self.matchupNote=self.stages.player.note
	-- Your fighter's strings, over the roster.
	self.routeNote=text(shell,"",UDim2.fromOffset(60,572),UDim2.fromOffset(1480,18),14,palette.gold,BODY_FONT,Enum.TextXAlignment.Center)
	self.routeNote.TextScaled=true;create("UITextSizeConstraint",self.routeNote,{MaxTextSize=14})
	-- The roster: twenty name tablets, each with its prodigy's face.
	local playable=table.clone(Roster)
	self.tablets={}
	local W,H,GAP=104,88,8
	local left=(1600-(10*W+9*GAP))/2
	for index,id in playable do
		local def=Fighters[id]
		local col=(index-1)%10;local row=math.floor((index-1)/10)
		local accent=accentOf(def)
		local tablet=create("TextButton",shell,{Position=UDim2.fromOffset(left+col*(W+GAP),600+row*(H+GAP)),Size=UDim2.fromOffset(W,H),
			BackgroundColor3=accent:Lerp(palette.ink,.62),BorderSizePixel=0,AutoButtonColor=false,Text="",ClipsDescendants=true})
		corner(tablet,6)
		local edge=create("UIStroke",tablet,{Color=accent,Thickness=1.5,Transparency=.35,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local face=create("ViewportFrame",tablet,{Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(W,64),BackgroundTransparency=1,
			Ambient=Color3.fromRGB(160,150,145),LightColor=Color3.fromRGB(255,240,220),LightDirection=Vector3.new(-1,-1,-.5)})
		local strip=frame(tablet,UDim2.fromOffset(0,62),UDim2.fromOffset(W,26),palette.paper,0)
		local label=text(strip,string.upper(def.Name),UDim2.fromOffset(4,0),UDim2.fromOffset(W-8,26),18,palette.ink,TITLE_FONT,Enum.TextXAlignment.Center)
		label.TextScaled=true;create("UITextSizeConstraint",label,{MaxTextSize=18})
		local seal=text(tablet,"",UDim2.fromOffset(4,4),UDim2.fromOffset(34,18),14,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
		seal.BackgroundColor3=palette.red;seal.BackgroundTransparency=1;corner(seal,4)
		local other=text(tablet,"",UDim2.fromOffset(W-38,4),UDim2.fromOffset(34,18),14,palette.ink,TITLE_FONT,Enum.TextXAlignment.Center)
		other.BackgroundColor3=palette.paper;other.BackgroundTransparency=1;corner(other,4)
		tablet.Activated:Connect(function() self:pick(self.side,id) end)
		self.selectionButtons["slot"..id]=tablet
		self.tablets[id]={tablet=tablet,edge=edge,face=face,seal=seal,other=other,accent=accent}
	end
	-- The action row: training, online, private duel by code, and the stage.
	local below=816
	self.startButton=button(shell,"ENTER THE STAGE",UDim2.fromOffset(1140,below),UDim2.fromOffset(400,58),function()
		if self.picking then send("Confirm") else send("Start",{player=self.player,bot=self.bot}) end
	end,palette.red)
	self.startButton.TextSize=32
	create("UIStroke",self.startButton,{Color=palette.paper,Thickness=2,Transparency=.2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.tutorialButton=button(shell,"TRAINING",UDim2.fromOffset(60,below),UDim2.fromOffset(230,58),function()
		if self.picking then send("Cancel") else send("Tutorial",{player=self.player,bot=self.bot}) end
	end)
	-- Online 1v1 with the fighter chosen above: casual queue, or a private duel
	-- by code (host one, or type a friend's code and join).
	self.onlineRow=frame(shell,UDim2.fromOffset(302,below),UDim2.fromOffset(826,58),palette.ink,1)
	self.queueButton=button(self.onlineRow,"ONLINE DUEL",UDim2.fromOffset(0,0),UDim2.fromOffset(230,58),function() send("Queue",{player=self.player}) end)
	self.hostButton=button(self.onlineRow,"HOST PRIVATE DUEL",UDim2.fromOffset(242,0),UDim2.fromOffset(250,58),function() send("Host",{player=self.player}) end)
	local codeBox=create("TextBox",self.onlineRow,{Position=UDim2.fromOffset(504,0),Size=UDim2.fromOffset(196,58),Text="",PlaceholderText="FRIEND'S CODE",
		TextSize=24,Font=TITLE_FONT,TextColor3=palette.ink,PlaceholderColor3=Color3.fromRGB(120,112,100),BackgroundColor3=palette.paper,BorderSizePixel=0,ClearTextOnFocus=false})
	corner(codeBox,6)
	codeBox:GetPropertyChangedSignal("Text"):Connect(function()
		local clean=string.sub(string.gsub(string.upper(codeBox.Text),"[^A-Z0-9]",""),1,Protocol.CodeLength)
		if clean~=codeBox.Text then codeBox.Text=clean end
	end)
	self.codeBox=codeBox
	self.joinButton=button(self.onlineRow,"JOIN",UDim2.fromOffset(712,0),UDim2.fromOffset(114,58),function() send("Join",{player=self.player,code=codeBox.Text}) end)
	self.notice=text(shell,"",UDim2.fromOffset(60,794),UDim2.fromOffset(1480,18),14,palette.gold,BODY_FONT,Enum.TextXAlignment.Center)
	-- The prodigies themselves (Server/Portraits): they arrive a few seconds
	-- after the server starts; the stages and tablets fill in then.
	pcall(task.spawn,function()
		pcall(function()
			local folder=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuelPortraits",60)
			if not folder then return end
			self.portraits=folder
			for id,t in self.tablets do pcall(UI.frameFace,t.face,folder:FindFirstChild(id)) end
			self:refreshSelection()
		end)
	end)
	-- ------------------------------------------------------------------ HUD
	self.hud=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	local hudScale=create("UIScale",self.hud,{Scale=1})
	self.hudScale=hudScale
	local function plate(side)
		local right=side=="right"
		-- (UI pass 02/11) Rows re-spaced so the status line no longer sits on the
		-- ultimate bar, and every small text grows by 2-3 points: at a 1382x681
		-- viewport the HUD scale (0.79) drew them at 8-10 px.
		local box=frame(self.hud,if right then UDim2.new(1,-24,0,18) else UDim2.fromOffset(24,18),UDim2.fromOffset(440,102),palette.ink,.25)
		box.AnchorPoint=Vector2.new(if right then 1 else 0,0)
		corner(box,8)
		local align=if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		local name=text(box,"",UDim2.fromOffset(14,4),UDim2.fromOffset(412,34),32,palette.paper,TITLE_FONT,align)
		local title=text(box,"",UDim2.fromOffset(14,36),UDim2.fromOffset(412,17),14,palette.muted,BODY_FONT,align)
		local track=frame(box,UDim2.fromOffset(14,56),UDim2.fromOffset(412,14),palette.track)
		corner(track,4)
		local lag=frame(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(240,220,190))
		corner(lag,4)
		local fill=frame(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.gold)
		corner(fill,4)
		if right then lag.AnchorPoint=Vector2.new(1,0);lag.Position=UDim2.fromScale(1,0);fill.AnchorPoint=Vector2.new(1,0);fill.Position=UDim2.fromScale(1,0) end
		local chakraTrack=frame(box,UDim2.fromOffset(14,73),UDim2.fromOffset(412,5),palette.track)
		local chakra=frame(chakraTrack,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.blue)
		if right then chakra.AnchorPoint=Vector2.new(1,0);chakra.Position=UDim2.fromScale(1,0) end
		-- (Stage 6) the ultimate bar: it fills by hitting and being hit; full,
		-- it burns and the plate says how to fire it.
		local ultimateTrack=frame(box,UDim2.fromOffset(14,80),UDim2.fromOffset(412,5),palette.track)
		local ultimate=frame(ultimateTrack,UDim2.fromScale(0,0),UDim2.fromScale(0,1),Color3.fromRGB(255,150,40))
		if right then ultimate.AnchorPoint=Vector2.new(1,0);ultimate.Position=UDim2.fromScale(1,0) end
		local status=text(box,"",UDim2.fromOffset(14,86),UDim2.fromOffset(412,15),13,palette.muted,BODY_FONT,align)
		-- Neji's chakra points closed on this fighter: four pips at the far end of
		-- the status row (both players read them), each lit as it closes.
		local points={}
		for k=1,4 do
			local pip=frame(box,UDim2.fromOffset(if right then 19+(k-1)*13 else 421-(k-1)*13,93),UDim2.fromOffset(9,9),palette.track)
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
		local subLabel=text(box,"SUB",UDim2.fromOffset(if right then 68 else 306,13),UDim2.fromOffset(44,14),12,palette.muted,BODY_FONT,
			if right then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right)
		-- Round wins: small medallions under the plate.
		local medals={}
		for k=1,2 do
			local m=frame(box,UDim2.fromOffset(if right then 412-(k-1)*20 else 14+(k-1)*20,106),UDim2.fromOffset(14,14),palette.track)
			corner(m,7);table.insert(medals,m)
		end
		-- The awakening while it burns: its name, the time left and what it
		-- changes in the fight (UI.awakening), under the plate.
		local awake=text(box,"",UDim2.fromOffset(14,124),UDim2.fromOffset(412,30),15,palette.gold,TITLE_FONT,align)
		create("UIStroke",awake,{Color=palette.ink,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		return {box=box,name=name,title=title,fill=fill,lag=lag,chakra=chakra,ultimate=ultimate,status=status,pips=pips,subLabel=subLabel,medals=medals,points=points,pointsShown=0,awake=awake}
	end
	self.hp=plate("left")
	self.enemy=plate("right")
	self.round=text(self.hud,"ROUND 1",UDim2.new(.5,-120,0,22),UDim2.fromOffset(240,30),26,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.roundSub=text(self.hud,"PRODIGY TOURNAMENT",UDim2.new(.5,-120,0,50),UDim2.fromOffset(240,16),13,palette.paper,BODY_FONT,Enum.TextXAlignment.Center)
	-- (UI pass 02/11) Over the sky and the wall the grey subtitle disappeared.
	create("UIStroke",self.roundSub,{Color=palette.ink,Thickness=1.2,Transparency=.2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	create("UIStroke",self.round,{Color=palette.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.cue=text(self.hud,"",UDim2.new(.5,-300,0,124),UDim2.fromOffset(600,40),30,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.cue,{Color=palette.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.channel=text(self.hud,"",UDim2.new(.5,-250,0,166),UDim2.fromOffset(500,28),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.statusLine=text(self.hud,"",UDim2.new(0,24,1,-120),UDim2.fromOffset(396,18),14,palette.paper)
	-- It ends before the jutsu slots (centre -440) and shrinks rather than run under them.
	self.statusLine.TextScaled=true;create("UITextSizeConstraint",self.statusLine,{MaxTextSize=14})
	-- (UI pass 02/11) Grey on the sand was unreadable: light text, ink outline.
	create("UIStroke",self.statusLine,{Color=palette.ink,Thickness=1.2,Transparency=.15,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
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
		local status=text(box,"",UDim2.fromOffset(8,41),UDim2.fromOffset(154,15),13,palette.muted)
		local cool=frame(box,UDim2.fromScale(0,1),UDim2.fromScale(1,0),palette.ink,.35)
		cool.AnchorPoint=Vector2.new(0,1);corner(cool,8)
		self.techniqueButtons[i]={box=box,key=key,title=title,status=status,cool=cool}
	end
	self.help=text(self.hud,Controls.Help,UDim2.new(.5,-640,1,-30),UDim2.fromOffset(1280,22),12,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.grammar=text(self.hud,Controls.Grammar,UDim2.new(.5,-640,1,-48),UDim2.fromOffset(1280,18),12,Color3.fromRGB(196,176,130),BODY_FONT,Enum.TextXAlignment.Center)
	self.hint=text(self.hud,"",UDim2.new(.5,-260,0,200),UDim2.fromOffset(520,30),18,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.ko=text(self.hud,"K.O.",UDim2.new(.5,-300,.3,0),UDim2.fromOffset(600,130),120,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.ko,{Color=palette.red,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.ko.Visible=false
	-- ---------------------------------------------------------------- intro
	-- (Partie 1 feedback) The names sit at the bottom edge and the round title
	-- at the top, like a fighting game's entrance: the middle of the screen is
	-- left to the close-up of each fighter's pose (Camera intro shots).
	self.intro=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	self.introLeft=frame(self.intro,UDim2.new(0,0,1,-118),UDim2.new(.5,0,0,110),palette.ink,.15)
	self.introRight=frame(self.intro,UDim2.new(.5,0,1,-118),UDim2.new(.5,0,0,110),palette.ink,.15)
	self.introLeftName=text(self.introLeft,"",UDim2.new(0,40,0,6),UDim2.new(1,-80,0,64),64,palette.paper,TITLE_FONT)
	self.introLeftTitle=text(self.introLeft,"",UDim2.new(0,42,0,70),UDim2.new(1,-80,0,26),18,palette.muted)
	self.introRightName=text(self.introRight,"",UDim2.new(0,40,0,6),UDim2.new(1,-80,0,64),64,palette.paper,TITLE_FONT,Enum.TextXAlignment.Right)
	self.introRightTitle=text(self.introRight,"",UDim2.new(0,40,0,70),UDim2.new(1,-82,0,26),18,palette.muted,BODY_FONT,Enum.TextXAlignment.Right)
	self.introVs=text(self.intro,"VS",UDim2.new(.5,-80,1,-110),UDim2.fromOffset(160,96),88,palette.red,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.introVs,{Color=palette.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.introRound=text(self.intro,"",UDim2.new(.5,-400,0,70),UDim2.fromOffset(800,40),30,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
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
		-- A UIScale also shrinks the frame it scales: size the HUD up by the
		-- same factor so its bottom row sits at the bottom of the screen (the
		-- slots and help used to float mid-screen on a small viewport).
		self.hud.Size=UDim2.fromScale(1/s,1/s)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitHud);fitHud()
	self:refreshSelection(); self:render({phase="Selection"})
	return self
end
function UI:refreshSelection()
	-- During an online pick the right stage shows the opponent's live choice.
	local other=if self.picking and Fighters[self.opponentPick or ""] then self.opponentPick else self.bot
	if self.picking then self.side="player" end
	for id,t in self.tablets or {} do
		local mine,theirs=id==self.player,id==other
		t.edge.Color=if mine then palette.red elseif theirs then palette.paper else t.accent
		t.edge.Thickness=if mine or theirs then 4 else 1.5
		t.edge.Transparency=if mine or theirs then 0 else .35
		t.seal.Text=if mine then "YOU" else "";t.seal.BackgroundTransparency=if mine then 0 else 1
		t.other.Text=if theirs then (if self.picking then "P2" else "CPU") else "";t.other.BackgroundTransparency=if theirs then 0 else 1
		t.tablet.BackgroundColor3=t.accent:Lerp(palette.ink,if mine or theirs then .35 else .62)
	end
	local p,o=Fighters[self.player],Fighters[other]
	for side,id in {player=self.player,bot=other} do
		local st=self.stages and self.stages[side]
		local def=Fighters[id]
		if st and def then
			st.name.Text=string.upper(def.FullName or def.Name)
			st.name.TextColor3=accentOf(def):Lerp(palette.paper,.3)
			st.sub.Text=string.format("AGE %d  •  %s",def.Age or 13,string.upper(def.Title or ""))
			st.note.Text=def.Description or ""
			st.choosing.Visible=self.side==side and not self.picking
			st.tag.BackgroundColor3=if self.side==side and not self.picking then palette.gold else palette.paper
			if self.portraits and st.shown~=id then
				st.shown=id
				pcall(UI.frameBody,st.view,self.portraits:FindFirstChild(id),st.right)
			end
		end
	end
	self.matchup.Text=string.upper((p.Name).."  VS  "..(o.Name))
	self.routeNote.Text=if p.Routes then string.upper(p.Name).." STRINGS  "..p.Routes else ""
end
-- A tablet chosen for a stage (side "player" or "bot"). In an online pick
-- your stage is the only one you fill; the other is the opponent's choice.
function UI:pick(side,id)
	if not Fighters[id] then return end
	if self.picking then
		if side=="player" then self:choose(id) end
		return
	end
	if side=="bot" then self.bot=id
	else
		self.player=id
		if self.bot==id then
			local roster=Roster
			for i,other in roster do if other==id then self.bot=roster[i%#roster+1] break end end
		end
	end
	self:refreshSelection()
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
		self.tutorialButton.Text="TRAINING"
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
		local line=light.." — ARRIVAL STRIKE  •  "..heavy..(if h.airborne then " — SLAM" else " — LAUNCH")
		for i,tech in h.techniques or {} do
			-- (Stage 6) at 13 the arrival is cashed in with the Lightning Strike.
			local label=if tech.id=="BurstStrike" then "RASENGAN" elseif tech.id=="LightningStrike" then "LIGHTNING STRIKE" else nil
			if label and tech.remaining==0 and h.chakra>=tech.cost and (h.sealed or 0)<=0 then
				line..="  •  "..(if pad then Controls.TechniquePad[i] else tostring(i)).." — "..label
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
-- (Stage 6) the ultimate bar on a plate; full, it burns gold and (on the
-- player's own plate) says which buttons fire it.
function UI.ultimate(widget,actor,pad,mine)
	if not widget.ultimate then return end
	local level=math.clamp((actor.ultimate or 0)/100,0,1)
	widget.ultimate.Size=UDim2.fromScale(level,1)
	local ready=actor.ultimateReady==true
	local pulse=.5+.5*math.sin(os.clock()*8)
	widget.ultimate.BackgroundColor3=if ready then Color3.fromRGB(255,190+math.floor(50*pulse),60) else Color3.fromRGB(255,150,40)
	-- (UI pass 02/11) Ready was only a word in the plate's smallest text.
	widget.status.TextColor3=if ready then Color3.fromRGB(255,200,90) else palette.muted
	if ready then
		widget.status.Text..="   •   ULTIMATE READY"..(if mine then " ("..(if pad then Controls.PadLabel.Ultimate else Controls.KeyLabel.Ultimate)..")" else "")
	end
end
function UI:render(data)
	local pad=if data.gamepad~=nil then data.gamepad else Controls.isGamepad(UIS:GetLastInputType())
	self.tutorialPanel.Visible=data.tutorial~=nil and data.phase=="Duel"
	-- (User 02/11, tutorial on screen) The cue band (124) and the hint (200)
	-- sat on the tutorial panel (84-174): "SPACE REBOUND / C DETACH" was printed
	-- across the step's own instruction. Under the panel while it shows.
	self.cue.Position=UDim2.new(.5,-300,0,if self.tutorialPanel.Visible then 182 else 124)
	self.hint.Position=UDim2.new(.5,-260,0,if self.tutorialPanel.Visible then 226 else 200)
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
			self.introLeft.Position=UDim2.new(-.5,0,1,-118);self.introRight.Position=UDim2.new(1,0,1,-118)
			Tween:Create(self.introLeft,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,1,-118)}):Play()
			Tween:Create(self.introRight,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,1,-118)}):Play()
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
		-- (UI pass 02/11) The damage trail was re-tweened every frame with a
		-- 0.25 s delay: each new tween cancelled the last before it started, so
		-- the trail never drained and the lost health stayed drawn as a full
		-- light bar. Started once per change of health.
		if widget.lagTarget~=ratio then
			local healed=ratio>=(widget.lagTarget or 1)
			widget.lagTarget=ratio
			if widget.lagTween and widget.lagTween.Cancel then widget.lagTween:Cancel() end
			if healed then widget.lag.Size=UDim2.fromScale(ratio,1)
			else
				widget.lagTween=Tween:Create(widget.lag,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.25),{Size=UDim2.fromScale(ratio,1)})
				widget.lagTween:Play()
			end
		end
		widget.chakra.Size=UDim2.fromScale(math.clamp(actor.chakra/actor.maxChakra,0,1),1)
		widget.status.Text=string.format("%d / %d",math.ceil(actor.health),actor.maxHealth)
		UI.ultimate(widget,actor,pad,actor==h)
		-- Gentle Fist effects on this fighter: the closed points (pips), what
		-- they cost (the chakra bar dims, its recovery is spelled out) and the
		-- jutsu the 64 Palms sealed.
		UI.network(widget,actor,if actor==h then b else h)
		widget.awake.Text=UI.awakening(actor)
		local tone=Fighters[actor.fighterId] and Fighters[actor.fighterId].Awakening and Fighters[actor.fighterId].Awakening.Color
		widget.awake.TextColor3=if tone then Color3.fromRGB(table.unpack(tone)) else palette.gold
		if (actor.sealed or 0)>0 then widget.status.Text..=string.format("   •   JUTSU SEALED %.1fs",actor.sealed)
		elseif (actor.chakraRegen or 1)<1 then widget.status.Text..=string.format("   •   CHAKRA REGEN -%d%%%s",math.floor((1-actor.chakraRegen)*100+.5),if actor.tenketsuSevere then "  •  NETWORK SEALED" else "") end
		-- Naruto: his shadow clones out (a route's own clone is not counted).
		local clones=0
		for _,body in data.bodies or {} do if body.owner==actor.id and body.kind=="clone" and not body.ephemeral then clones+=1 end end
		if clones>0 then widget.status.Text..="   •   CLONES "..clones end
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
	self.statusLine.Text=string.format("STAMINA %d   •   SUBSTITUTION %d   •   %s   •   %s",math.floor(h.stamina or 100),h.subCharges or 0,
		if h.wall then "WALL RUN" elseif h.dodge>0 then string.format("DASH %.1fs",h.dodge) else "DASH READY",
		-- Global kunai (DEC-030): whether a blade is drawn, and how to use it.
		(function()
			local weapon=Fighters[h.fighterId or ""] and Fighters[h.fighterId].Weapon
			if weapon then return if h.armed then weapon.Name.." DRAWN (B sheathes it)" else "B: draw "..string.lower(weapon.Name) end
			return if h.armed then "KUNAI DRAWN (R throws it)" else "B: draw kunai"
		end)())
	-- Only decisive moments speak; routine cues stay silent.
	local cue=h.cue or ""
	local loud=cue:find("READ") or cue:find("PARRY") or cue:find("PERFECT") or cue:find("FLYING THUNDER") or cue:find("GUARD BREAK") or cue:find("WALL ")
		or cue:find("CLASH") or cue:find("SUBSTITUTION •") or cue:find("SEAL") or cue:find("COMBO LIMIT") or cue:find("GENJUTSU")
		or cue:find("PALMS") or cue:find("ROTATION") or cue:find("BYAKUGAN") or cue:find("SHARINGAN")
		or cue:find("FLOW") or cue:find("AWAKEN") or cue:find("THROW BREAK") or cue:find("KNOCK AWAY") or cue:find("RIPOSTE")
		-- Caught in wire or sand: the way out must be on screen.
		or cue:find("WIRED") or cue:find("BOUND")
		-- Sasuke's (and Lee's) continuations and risks must be read too: the
		-- Dancing Leaf, the Lion Combo, the curse, a Chidori and its miss.
		or cue:find("DANCING LEAF") or cue:find("LION") or cue:find("CURSE") or cue:find("CHIDORI") or cue:find("PUNISH") or cue:find("LOTUS")
		-- Naruto's clones (made, broken, swapped) and the barrage's instruction.
		or cue:find("CLONE") or cue:find("U-ZU-MA-KI")
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
		-- The Chidori's risk, from the other side: its charge can be broken.
		elseif b.castId=="Chidori" and b.state=="TechniqueChannel" then (if pad then Controls.PadLabel.Light else Controls.KeyLabel.Light).." — BREAK THE CHIDORI CHARGE"
		elseif h.awakenReady then (if pad then "D-PAD ↓ — AWAKEN" else "T — AWAKEN")
		elseif h.wall then (if pad then "× — REBOUND  •  R1 + L1 — DETACH" else "SPACE — REBOUND  •  C — DETACH")
		elseif h.state=="Startup" and h.attackName=="Heavy" then (if pad then "R1 + L2 — FEINT" else "G — FEINT")
		elseif h.reaction=="Grabbed" then (if pad then "L2 — THROW BREAK" else "V — THROW BREAK")
		elseif h.pursuit>0 then (if pad then "× — CHASE" else Controls.KeyLabel.Pursuit.." / SPACE — CHASE")
		elseif (h.combo or 0)>=2 and h.state=="Recovery" and not h.airborne and (h.comboHits or 0)==0 and b.reaction then Controls.comboHelp(MoveGraphs[h.fighterId] or {},pad)
		else ""
	self.help.Text=if pad then Controls.HelpPad else Controls.Help
	self.grammar.Text=Controls.comboHelp(MoveGraphs[h.fighterId] or {},pad)
	-- (Reference quality) The control sheet is for the first seconds of a duel
	-- (and the tutorial), not a permanent band across the fight.
	if self.helpEpoch~=data.epoch then self.helpEpoch=data.epoch;self.helpUntil=os.clock()+10 end
	local helping=data.tutorial~=nil or os.clock()<(self.helpUntil or 0)
	self.help.Visible=helping;self.grammar.Visible=helping
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
