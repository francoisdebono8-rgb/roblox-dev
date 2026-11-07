-- Prodigy Tournament interface: roster/selection, online queue and fighter
-- pick, duel HUD, match intro and result framing. Presentation only; every
-- value comes from the snapshot.
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
-- (Beta 03/11) the select screen offers the beta's fighters only (Shared/BetaRoster).
local Roster=require(Shared.BetaRoster)
local Controls=require(Shared.Controls)
-- (05/11) The face button of each jutsu slot on a pad (R1 is the row's).
local PAD_FACE={"□","△","○","×","D↑"}
local ChakraMoves=require(Shared.ChakraMoves)
local FirstMinute=require(Shared.FirstMinute)
-- (B1 lot 3) the effects switch lives in the VFX kit (absent in headless tests)
local okKit,FXKit=pcall(function() return require(script.Parent.VfxKit) end)
if not okKit then FXKit=nil end
local SealJutsu=require(Shared.SealJutsu)
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
-- (User 03/11: "every banner and end screen needs one common identity".) The
-- house card: deep ink, rounded, a thin vermilion border and a vermilion
-- brush line along its top; the controls sheet, the result, the queue and
-- the tutorial panel are all this card.
local CARD=Color3.fromRGB(16,14,19)
local function inkCard(card,radius)
	card.BackgroundColor3=CARD;card.BackgroundTransparency=.04
	create("UICorner",card,{CornerRadius=UDim.new(0,radius or 12)})
	create("UIStroke",card,{Color=palette.red,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local line=create("Frame",card,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,5),BackgroundColor3=palette.red,BorderSizePixel=0})
	create("UICorner",line,{CornerRadius=UDim.new(0,radius or 12)})
	return card
end
local function inkTitle(label)
	create("UIStroke",label,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	return label
end
local function button(parent,value,position,size,callback,color)
	local b=create("TextButton",parent,{Text=value,Position=position,Size=size,TextSize=24,Font=TITLE_FONT,TextColor3=palette.text,
		BackgroundColor3=color or palette.panel,BorderSizePixel=0,AutoButtonColor=true})
	corner(b,6)
	-- (UI pass 02/11) A dark button on the dark menu read as disabled
	-- (TRAINING, ONLINE DUEL, HOST): a light edge says it can be pressed.
	if not color then create("UIStroke",b,{Color=palette.muted,Transparency=.55,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
	b.Activated:Connect(callback); return b
end
-- (Lobby, 04/11) the same look for the players-online panel (Client/LobbyPanel).
UI.kit={palette=palette,create=create,frame=frame,text=text,corner=corner,inkCard=inkCard,inkTitle=inkTitle,button=button,
	TITLE_FONT=TITLE_FONT,BODY_FONT=BODY_FONT,CARD=CARD}
local function accentOf(def) return Color3.fromRGB(table.unpack(def.Color)) end
function UI.new(parent,send)
	-- (B1 lot 2) `simple`: the first roster a player sees is PLAY and the
	-- fighters, nothing else (ALL MODES opens the rest; any finished duel too).
	local self=setmetatable({player="Flashstep",bot=FirstMinute.rival("Flashstep") or "Mirage",send=send,selectionButtons={},introShown=nil,simple=true},UI)
	self.gui=create("ScreenGui",parent,{Name="NinjaDuelHUD",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	-- ------------------------------------------------------------ selection
	-- (UI redesign 02/11, user: "be original in everything, you can change
	-- everything".) The tournament's call-up board: two stages where the
	-- chosen prodigies stand as they fight (the duel's own rigs, posed:
	-- Server/Portraits), a vermilion brush stroke between them, one roster of
	-- name tablets underneath. A tablet goes to the stage being chosen (yours
	-- unless you pick the other stage). Canvas 1600x900, scaled to the screen.
	self.side="player"
	-- Keyboard and gamepad focus in the game's own hand: a gold brush frame,
	-- not the engine's blue glow.
	pcall(function()
		local focus=Instance.new("Frame")
		focus.Name="NinjaFocus";focus.BackgroundTransparency=1;focus.Size=UDim2.new(1,10,1,10);focus.Position=UDim2.fromOffset(-5,-5)
		create("UIStroke",focus,{Color=palette.gold or Color3.fromRGB(232,190,96),Thickness=3})
		create("UICorner",focus,{CornerRadius=UDim.new(0,8)})
		parent.SelectionImageObject=focus
	end)
	-- The fighters stand in a real 3D set (Client/MenuStage) the menu camera
	-- films: the board is drawn over it, transparent where they are.
	self.selection=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	-- (Gradients only where the engine has them: the headless suites do not.)
	local hasSequences=ColorSequence~=nil and NumberSequence~=nil and NumberSequenceKeypoint~=nil
	pcall(function()
		-- The game's look on this screen (Client/WorldLook): light, grade, sky, ink lines.
		local lookModule=script.Parent:FindFirstChild("WorldLook")
		if lookModule then require(lookModule).start() end
		local stageModule=script.Parent:FindFirstChild("MenuStage")
		if stageModule then self.menuStage=require(stageModule).new() end
	end)
	local shell=frame(self.selection,UDim2.fromScale(.5,.5),UDim2.fromOffset(1600,900),palette.ink,1)
	shell.AnchorPoint=Vector2.new(.5,.5)
	self.shell=shell
	local scale=create("UIScale",shell,{Scale=1})
	local function resize() scale.Scale=math.min(1.25,workspace.CurrentCamera.ViewportSize.X/1600,workspace.CurrentCamera.ViewportSize.Y/900) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);resize()
	-- Ink at the bottom of the screen, under the roster and the actions.
	local base=frame(self.selection,UDim2.new(0,0,1,-300),UDim2.new(1,0,0,300),Color3.fromRGB(10,9,12),0)
	if hasSequences then create("UIGradient",base,{Rotation=-90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.62,.08),NumberSequenceKeypoint.new(1,1)})}) end
	base.ZIndex=0
	-- Title, top left; the hanging banner, right edge.
	-- (B0, 04/11) clear of Roblox's own buttons (top left: they covered the P)
	local title=text(shell,"PRODIGY TOURNAMENT",UDim2.fromOffset(150,18),UDim2.fromOffset(900,70),62,palette.paper,TITLE_FONT)
	create("UIStroke",title,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	text(shell,"Eight future legends to start, more every update. Twelve to fourteen years old. One stage — before they become who they are meant to be.",
		UDim2.fromOffset(152,84),UDim2.fromOffset(1100,20),15,palette.muted,Enum.Font.GothamMedium)
	local banner=frame(shell,UDim2.fromOffset(1534,0),UDim2.fromOffset(44,280),palette.paper,0)
	create("UIStroke",banner,{Color=palette.red,Thickness=2})
	text(banner,"天\n才\n忍\n者\n大\n会",UDim2.fromOffset(0,12),UDim2.fromOffset(44,240),26,palette.red,BODY_FONT,Enum.TextXAlignment.Center).LineHeight=.95
	frame(shell,UDim2.fromOffset(1553,280),UDim2.fromOffset(6,40),palette.red,0)
	self.controlsButton=button(shell,"CONTROLS  (TAB)",UDim2.fromOffset(1290,30),UDim2.fromOffset(220,40),function() self:toggleControls() end)
	self.controlsButton.TextSize=20
	-- The two stages.
	local function stage(side)
		local right=side=="bot"
		local x=if right then 960 else 60
		local box=create("TextButton",shell,{Position=UDim2.fromOffset(x,104),Size=UDim2.fromOffset(550,500),BackgroundTransparency=1,Text="",AutoButtonColor=false})
		-- The fighter stands in the 3D set behind this area; a white flash
		-- greets a new pick, a line of his colour runs under his name.
		local flash=frame(box,UDim2.fromOffset(0,36),UDim2.fromOffset(550,384),palette.paper,1)
		corner(flash,10)
		local underline=frame(box,UDim2.fromOffset(if right then 550-300 else 0,420),UDim2.fromOffset(300,4),palette.red,0)
		local align=if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		-- The tag over the stage: YOU / OPPONENT, and which stage takes the next tablet.
		local tag=frame(box,UDim2.fromOffset(if right then 550-190 else 0,0),UDim2.fromOffset(190,30),palette.paper,0)
		local tagText=text(tag,if right then "OPPONENT (AI)" else "YOU",UDim2.fromOffset(10,0),UDim2.fromOffset(170,30),20,palette.ink,TITLE_FONT,align)
		tagText.TextScaled=true;create("UITextSizeConstraint",tagText,{MaxTextSize=20})
		local choosing=text(box,"◀ CHOOSING",UDim2.fromOffset(if right then 550-190-130 else 200,0),UDim2.fromOffset(120,30),16,palette.gold,TITLE_FONT,align)
		if not right then choosing.Text="CHOOSING ▶" end
		local name=text(box,"",UDim2.fromOffset(if right then -14 else 14,368),UDim2.fromOffset(550,54),52,palette.paper,TITLE_FONT,align)
		local nameScale=create("UIScale",name,{Scale=1})
		create("UIStroke",name,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		local sub=text(box,"",UDim2.fromOffset(2,426),UDim2.fromOffset(546,18),14,palette.gold,BODY_FONT,align)
		local note=text(box,"",UDim2.fromOffset(2,446),UDim2.fromOffset(546,40),14,palette.text,Enum.Font.GothamMedium,align)
		note.TextYAlignment=Enum.TextYAlignment.Top
		box.Activated:Connect(function() if not self.picking or side=="player" then self.side=side;self:refreshSelection() end end)
		return {box=box,flash=flash,underline=underline,nameScale=nameScale,tag=tag,tagText=tagText,choosing=choosing,name=name,sub=sub,note=note,shown=nil,right=right}
	end
	self.stages={player=stage("player"),bot=stage("bot")}
	self.opponentLabel=self.stages.bot.tagText
	-- VS, and the matchup line under it.
	-- A vermilion copy a few pixels behind gives the VS depth.
	local vsShadow=text(shell,"VS",UDim2.fromOffset(808,308),UDim2.fromOffset(240,150),128,palette.red,TITLE_FONT,Enum.TextXAlignment.Center)
	vsShadow.AnchorPoint=Vector2.new(.5,.5);vsShadow.Rotation=-9
	local vs=text(shell,"VS",UDim2.fromOffset(800,300),UDim2.fromOffset(240,150),128,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	local vsScale=create("UIScale",vs,{Scale=1})
	vs.AnchorPoint=Vector2.new(.5,.5);vs.Rotation=-9
	create("UIStroke",vs,{Color=palette.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.matchup=text(shell,"",UDim2.fromOffset(800,392),UDim2.fromOffset(360,40),18,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.matchup.AnchorPoint=Vector2.new(.5,0);self.matchup.Rotation=-9
	self.matchupNote=self.stages.player.note
	-- Idle life while the board shows: the VS breathes; the set's back lights
	-- and stroke (Client/MenuStage) live on their own; the fighters keep
	-- their places on any screen shape.
	pcall(function()
		local lastView=nil
		game:GetService("RunService").RenderStepped:Connect(function()
			if self.menuStage then self.menuStage:filmed(self.selection.Visible) end
			if not self.selection.Visible then return end
			local t=os.clock()
			vsScale.Scale=1+.035*math.sin(t*2.2)
			-- The stage button's edge breathes: the next thing to press.
			if self.startStroke then self.startStroke.Transparency=.15+.5*(.5+.5*math.sin(t*3)) end
			if self.menuStage then
				local view=workspace.CurrentCamera.ViewportSize
				if view~=lastView then lastView=view;self.menuStage:layout() end
				self.menuStage:step(t)
			end
		end)
	end)
	-- Your fighter's strings, over the roster.
	self.routeNote=text(shell,"",UDim2.fromOffset(60,602),UDim2.fromOffset(1480,18),14,palette.gold,BODY_FONT,Enum.TextXAlignment.Center)
	self.routeNote.TextScaled=true;create("UITextSizeConstraint",self.routeNote,{MaxTextSize=14})
	-- The roster (user 02/11: the top and the bottom repeated each other, the
	-- faces were wrong): name plates, two rows of ten, each with a cut of its
	-- fighter's colour; a plate rises under the pointer, the picks stand
	-- raised with their tag above them. The faces are on the stages.
	local playable=table.clone(Roster)
	self.tablets={}
	local W,H,GAP=132,38,8
	-- (Beta) one row when the roster fits in it, centred under the stages.
	local perRow=math.min(#playable,10)
	local left=(1600-(perRow*W+(perRow-1)*GAP))/2
	for index,id in playable do
		local def=Fighters[id]
		local accent=accentOf(def)
		local col=(index-1)%perRow;local row=math.floor((index-1)/perRow)
		local x,y=left+col*(W+GAP),664+row*(H+12)
		local tablet=create("TextButton",shell,{Name="Tablet"..id,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(W,H),
			BackgroundColor3=Color3.fromRGB(22,19,25),BorderSizePixel=0,AutoButtonColor=false,Text="",ClipsDescendants=true})
		corner(tablet,5)
		local edge=create("UIStroke",tablet,{Color=accent,Thickness=1.5,Transparency=.55,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local glow=frame(tablet,UDim2.fromOffset(0,0),UDim2.new(0,6,1,0),accent,0)
		local label=text(tablet,string.upper(def.Name),UDim2.fromOffset(12,0),UDim2.fromOffset(W-16,H),22,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
		label.TextScaled=true;create("UITextSizeConstraint",label,{MaxTextSize=22})
		-- The pick's tag sits on the plate's top edge (above it, it covered the
		-- row above when a second-row plate was picked).
		local seal=text(shell,"",UDim2.fromOffset(x+W-52,y-7),UDim2.fromOffset(48,14),12,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
		seal.ZIndex=3
		seal.BackgroundColor3=palette.red;seal.BackgroundTransparency=1;corner(seal,4)
		tablet.Activated:Connect(function() self:pick(self.side,id) end)
		local t={tablet=tablet,edge=edge,glow=glow,label=label,seal=seal,other=seal,accent=accent,x=x,y=y,w=W,hover=false}
		pcall(function()
			tablet.MouseEnter:Connect(function() t.hover=true;self:liftTablet(t) end)
			tablet.MouseLeave:Connect(function() t.hover=false;self:liftTablet(t) end)
		end)
		self.selectionButtons["slot"..id]=tablet
		self.tablets[id]=t
	end
	-- The action row: training, online, private duel by code, and the stage.
	local below=800
	self.startButton=button(shell,"ENTER THE STAGE",UDim2.fromOffset(1140,below),UDim2.fromOffset(400,58),function()
		if self.picking then send("Confirm")
		elseif self.simple then send("First",{player=self.player})
		else send("Start",{player=self.player,bot=self.bot,level=self.aiLevel}) end
	end,palette.red)
	-- (B1, 04/11) The AI's level for a duel, opposite the tournament: easy
	-- first (B0: an idle player lost 107 of 125 health in 15 s), the server
	-- keeps the choice for the rematches. The tournament sets its own.
	self.aiLevel="easy"
	local LEVEL_NEXT={easy="normal",normal="hard",hard="easy"}
	self.levelButton=button(shell,"AI LEVEL  •  EASY",UDim2.fromOffset(600,712),UDim2.fromOffset(400,52),function()
		if self.picking then return end
		self.aiLevel=LEVEL_NEXT[self.aiLevel] or "easy"
		self.levelButton.Text="AI LEVEL  •  "..string.upper(self.aiLevel)
	end)
	self.levelButton.TextSize=24
	self.startButton.TextSize=32
	self.startStroke=create("UIStroke",self.startButton,{Color=palette.paper,Thickness=2.5,Transparency=.2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	-- (04/11) The Prodigy Tournament against the AI (Server/Tournament).
	self.cupButton=button(shell,"TOURNAMENT  •  VS AI",UDim2.fromOffset(60,712),UDim2.fromOffset(400,52),function()
		if not self.picking then send("CupStart",{player=self.player}) end
	end,palette.red)
	self.cupButton.TextSize=26
	self.tutorialButton=button(shell,"TRAINING",UDim2.fromOffset(60,below),UDim2.fromOffset(230,58),function()
		if self.picking then send("Cancel")
		elseif self.simple then self.simple=false;self:refreshSelection();if self.lastLobby then self:lobby(self.lastLobby) end
		else send("Tutorial",{player=self.player,bot=self.bot}) end
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
	self.notice=text(shell,"",UDim2.fromOffset(60,776),UDim2.fromOffset(1480,18),14,palette.gold,BODY_FONT,Enum.TextXAlignment.Center)
	-- The prodigies themselves (Server/Portraits): they arrive a few seconds
	-- after the server starts; the stages and tablets fill in then.
	pcall(task.spawn,function()
		pcall(function()
			local folder=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuelPortraits",60)
			if not folder then return end
			-- The folder arrives first and its fighters stream in after it: each
			-- is framed once all of it is here (Server/Portraits counts them).
			local function complete(model)
				return model~=nil and #model:GetDescendants()>=(model:GetAttribute("Descendants") or 0)
			end
			local started=os.clock()
			while os.clock()-started<30 do
				local done=0
				for id in self.tablets do if complete(folder:FindFirstChild(id)) then done+=1 end end
				self.portraits=folder
				self:refreshSelection()
				if done>=#Roster then break end
				task.wait(.25)
			end
		end)
	end)
	-- ------------------------------------------------------------------ HUD
	self.hud=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	local hudScale=create("UIScale",self.hud,{Scale=1})
	-- (Look pass 03/11) The fight screen's own grade, under every HUD element:
	-- a soft ink vignette at the edges; a red one that throbs in danger.
	-- (User 03/11: the speed lines streaming in from the screen edges at a
	-- run "drive me crazy". They showed while the dash recharged too, so
	-- nearly all the time: removed.)
	self.screenFx=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	self.screenFx.ZIndex=0
	local function edges(color,parent,strength)
		local out={}
		for k,spec in {{UDim2.fromScale(0,0),UDim2.fromScale(1,.16),90},{UDim2.fromScale(0,.84),UDim2.fromScale(1,.16),-90},{UDim2.fromScale(0,0),UDim2.fromScale(.1,1),0},{UDim2.fromScale(.9,0),UDim2.fromScale(.1,1),180}} do
			local f=frame(parent,spec[1],spec[2],color,0)
			if hasSequences then create("UIGradient",f,{Rotation=spec[3],Transparency=NumberSequence.new(1-strength,1)}) else f.BackgroundTransparency=1 end
			out[k]=f
		end
		return out
	end
	self.vignette=frame(self.screenFx,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	edges(Color3.fromRGB(10,8,14),self.vignette,.38)
	self.danger=create("CanvasGroup",self.screenFx,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,GroupTransparency=1})
	edges(Color3.fromRGB(200,20,30),self.danger,.8)
	self.hudScale=hudScale
	-- (UI redesign 02/11) The duel plates in the menu's language: the fighter's
	-- face in an ink medallion with a ring of his colour at the outer corner,
	-- the name in brush capitals, a long health bar with an ink edge and a
	-- light cut along its top, chakra and the ultimate gauge (four notches)
	-- under it, the status line, the round seals under the medallion.
	local function plate(side)
		local right=side=="right"
		local box=frame(self.hud,if right then UDim2.new(1,-20,0,16) else UDim2.fromOffset(20,16),UDim2.fromOffset(560,124),palette.ink,1)
		box.AnchorPoint=Vector2.new(if right then 1 else 0,0)
		local align=if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		local function X(x,w) return if right then 560-x-w else x end
		-- The medallion.
		local medallion=frame(box,UDim2.fromOffset(X(0,88),0),UDim2.fromOffset(88,88),Color3.fromRGB(14,12,17),0)
		create("UICorner",medallion,{CornerRadius=UDim.new(.5,0)})
		local ring=create("UIStroke",medallion,{Color=palette.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local glow=frame(medallion,UDim2.fromScale(.5,.45),UDim2.fromScale(.9,.9),palette.red,.7)
		glow.AnchorPoint=Vector2.new(.5,.5);create("UICorner",glow,{CornerRadius=UDim.new(.5,0)})
		-- The fighter's initial in brush capitals (a ViewportFrame cannot draw
		-- the faces: they are SurfaceGuis).
		local initial=text(medallion,"",UDim2.fromScale(0,.04),UDim2.fromScale(1,1),58,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
		create("UIStroke",initial,{Color=palette.ink,Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		-- Name, title, substitution diamonds.
		local name=text(box,"",UDim2.fromOffset(X(100,360),0),UDim2.fromOffset(360,34),32,palette.paper,TITLE_FONT,align)
		create("UIStroke",name,{Color=palette.ink,Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		local title=text(box,"",UDim2.fromOffset(X(102,400),32),UDim2.fromOffset(400,16),13,palette.paper,BODY_FONT,align)
		create("UIStroke",title,{Color=palette.ink,Thickness=1,Transparency=.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		-- Health: ink edge, dark well, the trail of lost health, the fill.
		-- A soft ink shadow under the whole plate keeps it readable on the sky.
		local shade=frame(box,UDim2.fromOffset(X(84,480),-6),UDim2.fromOffset(480,128),Color3.fromRGB(8,7,10),.55)
		shade.ZIndex=0;corner(shade,14)
		if hasSequences then create("UIGradient",shade,{Rotation=if right then 180 else 0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,.35),NumberSequenceKeypoint.new(1,1)})}) end
		local track=frame(box,UDim2.fromOffset(X(96,464),52),UDim2.fromOffset(464,22),Color3.fromRGB(20,18,24),0)
		corner(track,4)
		create("UIStroke",track,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local lag=frame(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(240,220,190))
		corner(lag,3)
		local fill=frame(track,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.gold)
		corner(fill,3)
		local shine=frame(fill,UDim2.fromOffset(0,2),UDim2.new(1,0,0,5),Color3.new(1,1,1),.6)
		corner(shine,3)
		-- Light from above on the fill and the trail; a dark well under them.
		if hasSequences then
			create("UIGradient",fill,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(170,150,130))})
			create("UIGradient",lag,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(200,180,160))})
			create("UIGradient",track,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(60,54,66),Color3.fromRGB(20,18,24))})
		end
		if right then lag.AnchorPoint=Vector2.new(1,0);lag.Position=UDim2.fromScale(1,0);fill.AnchorPoint=Vector2.new(1,0);fill.Position=UDim2.fromScale(1,0) end
		local chakraTrack=frame(box,UDim2.fromOffset(X(96,400),78),UDim2.fromOffset(400,6),Color3.fromRGB(20,18,24))
		corner(chakraTrack,3)
		local chakra=frame(chakraTrack,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.blue)
		if right then chakra.AnchorPoint=Vector2.new(1,0);chakra.Position=UDim2.fromScale(1,0) end
		-- (Stage 6) the ultimate gauge: it fills by hitting and being hit; full,
		-- it burns and the plate says how to fire it.
		local ultimateTrack=frame(box,UDim2.fromOffset(X(96,400),87),UDim2.fromOffset(400,6),Color3.fromRGB(20,18,24))
		local ultimate=frame(ultimateTrack,UDim2.fromScale(0,0),UDim2.fromScale(0,1),Color3.fromRGB(255,150,40))
		if right then ultimate.AnchorPoint=Vector2.new(1,0);ultimate.Position=UDim2.fromScale(1,0) end
		for k=1,3 do frame(ultimateTrack,UDim2.fromScale(k/4,0),UDim2.new(0,2,1,0),palette.ink,0) end
		local status=text(box,"",UDim2.fromOffset(X(98,460),96),UDim2.fromOffset(460,16),13,palette.muted,BODY_FONT,align)
		create("UIStroke",status,{Color=palette.ink,Thickness=1,Transparency=.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		-- Neji's chakra points closed on this fighter: four pips at the far end of
		-- the chakra bar (both players read them), each lit as it closes.
		local points={}
		for k=1,4 do
			local pip=frame(box,UDim2.fromOffset(X(506+(k-1)*13,9),79),UDim2.fromOffset(9,9),palette.track)
			pip.AnchorPoint=Vector2.new(.5,.5);pip.Visible=false
			corner(pip,5)
			points[k]=pip
		end
		-- Substitution charges: two diamonds at the far end of the name line.
		local pips={}
		for k=1,2 do
			local pip=frame(box,UDim2.fromOffset(X(526-(k-1)*24,16),12),UDim2.fromOffset(16,16),palette.track)
			pip.Rotation=45;pip.ClipsDescendants=true
			local pfill=frame(pip,UDim2.fromScale(0,1),UDim2.fromScale(1,1),palette.paper)
			pfill.AnchorPoint=Vector2.new(0,1)
			pips[k]={pip=pip,fill=pfill}
		end
		local subLabel=text(box,"SUB",UDim2.fromOffset(X(456,40),12),UDim2.fromOffset(40,14),12,palette.paper,BODY_FONT,
			if right then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right)
		-- Round wins: seals under the medallion.
		local medals={}
		for k=1,2 do
			local m=frame(box,UDim2.fromOffset(X(26+(k-1)*22,14),94),UDim2.fromOffset(14,14),palette.track)
			m.Rotation=45;table.insert(medals,m)
		end
		-- The awakening while it burns: its name, the time left and what it
		-- changes in the fight (UI.awakening), under the plate.
		local awake=text(box,"",UDim2.fromOffset(X(96,460),112),UDim2.fromOffset(460,26),15,palette.gold,TITLE_FONT,align)
		create("UIStroke",awake,{Color=palette.ink,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
		return {box=box,name=name,title=title,fill=fill,lag=lag,chakra=chakra,ultimate=ultimate,status=status,pips=pips,subLabel=subLabel,medals=medals,points=points,pointsShown=0,awake=awake,initial=initial,ring=ring,glow=glow,right=right}
	end
	self.hp=plate("left")
	self.enemy=plate("right")
	self.round=text(self.hud,"ROUND 1",UDim2.new(.5,-120,0,22),UDim2.fromOffset(240,30),26,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.roundSub=text(self.hud,"PRODIGY TOURNAMENT",UDim2.new(.5,-120,0,55),UDim2.fromOffset(240,16),13,palette.paper,BODY_FONT,Enum.TextXAlignment.Center)
	-- (UI pass 02/11) Over the sky and the wall the grey subtitle disappeared.
	create("UIStroke",self.roundSub,{Color=palette.ink,Thickness=1.2,Transparency=.2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	create("UIStroke",self.round,{Color=palette.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	frame(self.hud,UDim2.new(.5,-46,0,48),UDim2.fromOffset(92,3),palette.red,0)
	self.cue=text(self.hud,"",UDim2.new(.5,-300,0,124),UDim2.fromOffset(600,40),30,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.cue,{Color=palette.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.channel=text(self.hud,"",UDim2.new(.5,-250,0,166),UDim2.fromOffset(500,28),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.statusLine=text(self.hud,"",UDim2.new(0,24,1,-44),UDim2.fromOffset(396,18),14,palette.paper)
	-- (User 03/11) No key list on the fight screen: the controls sheet has it.
	self.statusLine.Visible=false
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
	-- (UI redesign 02/11) The jutsu cards leave the middle of the screen, where
	-- the camera puts the fighter's own body: a row in the bottom right corner,
	-- each card an ink slip with its key on a vermilion seal.
	for i=1,5 do
		local box=frame(self.hud,UDim2.new(1,-24-(5-i+1)*150+6,1,-84),UDim2.fromOffset(144,60),Color3.fromRGB(22,19,26),.05)
		corner(box,8)
		create("UIStroke",box,{Color=palette.paper,Thickness=1.5,Transparency=.7,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		if hasSequences then create("UIGradient",box,{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(70,62,78),Color3.fromRGB(22,19,26))}) end
		local seal=frame(box,UDim2.fromOffset(-8,-8),UDim2.fromOffset(28,28),palette.red,0)
		seal.Rotation=-6;corner(seal,5)
		create("UIStroke",seal,{Color=palette.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
		local key=text(seal,"",UDim2.fromScale(0,0),UDim2.fromScale(1,1),18,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
		-- (05/11) a word fits too (the chakra page's LMB, SPACE)
		key.TextScaled=true;create("UITextSizeConstraint",key,{MaxTextSize=18})
		local title=text(box,"",UDim2.fromOffset(26,6),UDim2.fromOffset(112,28),17,palette.paper,TITLE_FONT)
		title.TextScaled=true;create("UITextSizeConstraint",title,{MaxTextSize=18})
		local status=text(box,"",UDim2.fromOffset(10,38),UDim2.fromOffset(126,16),12,Color3.fromRGB(140,190,250))
		local cool=frame(box,UDim2.fromScale(0,1),UDim2.fromScale(1,0),palette.ink,.3)
		cool.AnchorPoint=Vector2.new(0,1);corner(cool,8)
		self.techniqueButtons[i]={box=box,key=key,title=title,status=status,cool=cool}
	end
	-- (05/11, user on the pad) "R1 + □" did not fit the 28 px seal: on a pad
	-- each seal shows its face button and the row is prefixed by the R1 it
	-- needs, lit while R1 is held.
	self.jutsuCaption=text(self.hud,"R1 +",UDim2.new(1,-80,1,-74),UDim2.fromOffset(52,40),22,palette.paper,TITLE_FONT,Enum.TextXAlignment.Right)
	self.jutsuCaption.Visible=false
	-- (DEC-032) The hand-seal jutsu: a slip above the jutsu cards (the two
	-- seals, the name, the cooldown), lit while the seals are being woven; the
	-- seals woven so far are stamped in the middle of the screen.
	self.sealPanel=frame(self.hud,UDim2.new(1,-344,1,-268),UDim2.fromOffset(320,172),Color3.fromRGB(22,19,26),.35)
	corner(self.sealPanel,8)
	create("UIStroke",self.sealPanel,{Color=palette.paper,Thickness=1.5,Transparency=.75,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.sealHead=text(self.sealPanel,"HAND SEALS",UDim2.fromOffset(10,4),UDim2.fromOffset(300,22),16,palette.gold,TITLE_FONT)
	self.sealRows={}
	for i=1,5 do
		local row=text(self.sealPanel,"",UDim2.fromOffset(10,27+(i-1)*28),UDim2.fromOffset(300,24),15,palette.paper,BODY_FONT)
		row.TextScaled=true;create("UITextSizeConstraint",row,{MaxTextSize=15})
		self.sealRows[i]=row
	end
	self.sealWeave=text(self.hud,"",UDim2.new(.5,-260,.6,0),UDim2.fromOffset(520,64),44,palette.paper,BODY_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.sealWeave,{Color=palette.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	-- The control sheet (first seconds of a duel, and the tutorial): bottom
	-- left over the status line, clear of the jutsu cards.
	self.help=text(self.hud,Controls.Help,UDim2.new(0,24,1,-104),UDim2.fromOffset(700,36),12,palette.paper,BODY_FONT)
	self.help.TextScaled=true;create("UITextSizeConstraint",self.help,{MaxTextSize=12})
	create("UIStroke",self.help,{Color=palette.ink,Thickness=1,Transparency=.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.grammar=text(self.hud,Controls.Grammar,UDim2.new(0,24,1,-126),UDim2.fromOffset(700,18),12,Color3.fromRGB(230,200,140),BODY_FONT)
	self.grammar.TextScaled=true;create("UITextSizeConstraint",self.grammar,{MaxTextSize=12})
	create("UIStroke",self.grammar,{Color=palette.ink,Thickness=1,Transparency=.3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.hint=text(self.hud,"",UDim2.new(.5,-260,0,200),UDim2.fromOffset(520,30),18,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.ko=text(self.hud,"K.O.",UDim2.new(.5,-300,.3,0),UDim2.fromOffset(600,130),120,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.ko,{Color=palette.red,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.ko.Visible=false
	-- ---------------------------------------------------------------- intro
	-- (Partie 1 feedback) The names sit at the bottom edge and the round title
	-- at the top, like a fighting game's entrance: the middle of the screen is
	-- left to the close-up of each fighter's pose (Camera intro shots).
	self.intro=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,1)
	self.introLeft=frame(self.intro,UDim2.new(0,0,1,-118),UDim2.new(.5,0,0,110),CARD,.08)
	self.introRight=frame(self.intro,UDim2.new(.5,0,1,-118),UDim2.new(.5,0,0,110),CARD,.08)
	-- The house brush line along the top of both bands.
	for _,band in {self.introLeft,self.introRight} do frame(band,UDim2.fromOffset(0,0),UDim2.new(1,0,0,5),palette.red,0) end
	self.introLeftName=text(self.introLeft,"",UDim2.new(0,40,0,6),UDim2.new(1,-80,0,64),64,palette.paper,TITLE_FONT)
	inkTitle(self.introLeftName)
	self.introLeftTitle=text(self.introLeft,"",UDim2.new(0,42,0,70),UDim2.new(1,-80,0,26),18,palette.muted)
	self.introRightName=text(self.introRight,"",UDim2.new(0,40,0,6),UDim2.new(1,-80,0,64),64,palette.paper,TITLE_FONT,Enum.TextXAlignment.Right)
	inkTitle(self.introRightName)
	self.introRightTitle=text(self.introRight,"",UDim2.new(0,40,0,70),UDim2.new(1,-82,0,26),18,palette.muted,BODY_FONT,Enum.TextXAlignment.Right)
	-- The menu's VS: paper capitals in an ink outline, tilted like the stroke.
	self.introVs=text(self.intro,"VS",UDim2.new(.5,-80,1,-118),UDim2.fromOffset(160,104),96,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	self.introVs.Rotation=-9
	create("UIStroke",self.introVs,{Color=palette.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.introRound=text(self.intro,"",UDim2.new(.5,-400,0,70),UDim2.fromOffset(800,40),30,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	inkTitle(self.introRound)
	self.introBegin=text(self.intro,"",UDim2.new(.5,-400,.38,-60),UDim2.fromOffset(800,120),120,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	create("UIStroke",self.introBegin,{Color=palette.red,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.intro.Visible=false
	-- --------------------------------------------------------------- result
	self.result=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,.25)
	local resultBox=inkCard(frame(self.result,UDim2.new(.5,-300,.5,-170),UDim2.fromOffset(600,340),CARD,0))
	self.resultBox=resultBox
	self.resultScale=create("UIScale",resultBox,{Scale=1})
	-- The judges' seal, stamped on the card: 勝 for a win, 敗 for a loss.
	self.resultSeal=text(resultBox,"",UDim2.fromOffset(600-70,-34),UDim2.fromOffset(96,96),64,palette.paper,BODY_FONT,Enum.TextXAlignment.Center)
	self.resultSeal.BackgroundColor3=palette.red;self.resultSeal.BackgroundTransparency=0;self.resultSeal.Rotation=12;corner(self.resultSeal,10)
	create("UIStroke",self.resultSeal,{Color=palette.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.resultSealScale=create("UIScale",self.resultSeal,{Scale=1})
	self.resultTitle=text(resultBox,"",UDim2.fromOffset(30,18),UDim2.fromOffset(540,70),72,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	inkTitle(self.resultTitle)
	self.resultName=text(resultBox,"",UDim2.fromOffset(30,92),UDim2.fromOffset(540,36),30,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.resultNote=text(resultBox,"",UDim2.fromOffset(30,132),UDim2.fromOffset(540,44),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	-- In a tournament the card continues the bracket instead of a rematch.
	self.rematchButton=button(resultBox,"REMATCH",UDim2.fromOffset(30,196),UDim2.fromOffset(540,52),function() send(if self.inCup then "CupBracket" else "Rematch") end,palette.red)
	self.rosterButton=button(resultBox,"RETURN TO THE ROSTER",UDim2.fromOffset(30,260),UDim2.fromOffset(540,52),function() send(if self.inCup then "CupLeave" else "Selection") end)
	-- ------------------------------------------------------------ controls
	-- (User 03/11: "the keys should be in a menu rather than on the screen
	-- all the time".) TAB (pad: START) opens the controls sheet over any
	-- screen: the moves grouped by what they are for, then the fighter's own
	-- strings and jutsu. A small chip on the HUD and a button on the roster say
	-- where it is; nothing else lists keys during a fight.
	self.controls=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),Color3.fromRGB(6,5,8),.25)
	-- (UI review 04/11, finding 11) over the bracket (40-52) and the players
	-- list (70), under an invitation (80).
	self.controls.ZIndex=75;self.controls.Visible=false
	-- (Audit 04/11) the sheet takes the clicks (they went through to the roster).
	self.controls.Active=true
	local sheet=inkCard(frame(self.controls,UDim2.fromScale(.5,.5),UDim2.fromOffset(1120,640),CARD,0))
	sheet.AnchorPoint=Vector2.new(.5,.5);sheet.ZIndex=76
	local sheetScale=create("UIScale",sheet,{Scale=1})
	local function fitSheet() local v=workspace.CurrentCamera.ViewportSize;sheetScale.Scale=math.clamp(math.min(v.X/1220,v.Y/720),.5,1.2) end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitSheet);fitSheet()
	local sheetTitle=text(sheet,"CONTROLS",UDim2.fromOffset(36,20),UDim2.fromOffset(600,52),48,palette.paper,TITLE_FONT)
	sheetTitle.ZIndex=42
	self.controlsClose=text(sheet,"",UDim2.fromOffset(1120-900,30),UDim2.fromOffset(400,30),16,palette.muted,BODY_FONT,Enum.TextXAlignment.Right)
	self.controlsClose.ZIndex=77
	-- (UI review 04/11, finding 1) a phone had no TAB: the sheet could not be
	-- closed. A real button, which the pad's focus takes when the sheet opens.
	self.controlsCloseButton=button(sheet,"CLOSE",UDim2.fromOffset(1120-236,14),UDim2.fromOffset(200,64),function() if self.controls.Visible then self:toggleControls() end end,palette.red)
	self.controlsCloseButton.ZIndex=78
	-- (B1 lot 3, B0 defect 8) EFFECTS FULL / LOW: fewer particles, no screen
	-- tint, a calmer lens (lighter phones; a duel judged with and without).
	self.effectsButton=button(sheet,"EFFECTS: FULL",UDim2.fromOffset(1120-476,14),UDim2.fromOffset(228,64),function()
		local low=not (FXKit and FXKit.calm)
		if FXKit then FXKit.setLow(low) end
		self.effectsButton.Text=if low then "EFFECTS: LOW" else "EFFECTS: FULL"
		if self.onEffects then self.onEffects(low) end
	end)
	self.effectsButton.ZIndex=78;self.effectsButton.TextSize=22
	frame(sheet,UDim2.fromOffset(36,78),UDim2.fromOffset(1048,3),palette.red,0).ZIndex=42
	self.controlsBody=frame(sheet,UDim2.fromOffset(36,96),UDim2.fromOffset(1048,520),palette.ink,1)
	self.controlsBody.ZIndex=42
	-- The HUD chip that says where the sheet is.
	self.controlsChip=text(self.hud,"",UDim2.new(0,24,1,-48),UDim2.fromOffset(260,26),15,palette.paper,TITLE_FONT)
	self.controlsChip.BackgroundColor3=Color3.fromRGB(16,14,19);self.controlsChip.BackgroundTransparency=.25;corner(self.controlsChip,6)
	create("UIPadding",self.controlsChip,{PaddingLeft=UDim.new(0,10)})
	pcall(function()
		UIS.InputBegan:Connect(function(input,processed)
			if processed then return end
			if input.KeyCode==Enum.KeyCode.Tab or input.KeyCode==Enum.KeyCode.ButtonStart then self:toggleControls() end
		end)
	end)
	-- ---------------------------------------------------------------- wipe
	-- Between screens an ink brush stroke sweeps across (UI:wipe), the same
	-- angle as the menu's stroke, its leading edge vermilion.
	self.wipe=frame(self.gui,UDim2.fromScale(-1.6,.5),UDim2.fromScale(1.6,3),Color3.fromRGB(10,9,12),0)
	self.wipe.AnchorPoint=Vector2.new(.5,.5);self.wipe.Rotation=-9;self.wipe.ZIndex=60;self.wipe.Visible=false
	local edge=frame(self.wipe,UDim2.new(1,-10,0,0),UDim2.new(0,14,1,0),palette.red,0);edge.ZIndex=61
	-- ---------------------------------------------------------- online queue
	self.queue=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.ink,.25)
	local queueBox=inkCard(frame(self.queue,UDim2.new(.5,-300,.5,-150),UDim2.fromOffset(600,300),CARD,0))
	self.queueTitle=text(queueBox,"",UDim2.fromOffset(30,18),UDim2.fromOffset(540,56),48,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
	inkTitle(self.queueTitle)
	self.queueCode=text(queueBox,"",UDim2.fromOffset(30,80),UDim2.fromOffset(540,70),72,palette.gold,TITLE_FONT,Enum.TextXAlignment.Center)
	self.queueNote=text(queueBox,"",UDim2.fromOffset(30,154),UDim2.fromOffset(540,44),15,palette.muted,BODY_FONT,Enum.TextXAlignment.Center)
	self.cancelButton=button(queueBox,"CANCEL",UDim2.fromOffset(30,222),UDim2.fromOffset(540,52),function() send("Cancel") end)
	self.queue.Visible=false
	-- The genjutsu image carries no label: the world shows it (Presentation:illusion).
	-- (UI review 04/11, finding 7; seen in Studio v37) at the centre (84) it hid
	-- the inner ends of both health bars, under them (160) the partner's head:
	-- on the left, under the player's own plate, the middle stays the fight's.
	self.tutorialPanel=inkCard(frame(self.hud,UDim2.new(0,24,0,170),UDim2.fromOffset(520,90),CARD,0),10)
	self.tutorialTitle=text(self.tutorialPanel,"",UDim2.fromOffset(16,9),UDim2.fromOffset(490,30),24,palette.paper,TITLE_FONT)
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
		-- (Studio 03/11) The player's plate starts after Roblox's own buttons
		-- in the top-left corner (they covered his medallion and name).
		local inset=0
		pcall(function() inset=GuiService.TopbarInset.Min.X end)
		if self.hp and self.hp.box then self.hp.box.Position=UDim2.fromOffset(math.max(20,(inset+8)/s),16) end
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitHud);fitHud()
	pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fitHud) end)
	self:refreshSelection(); self:render({phase="Selection"})
	return self
end
function UI:refreshSelection()
	-- During an online pick the right stage shows the opponent's live choice.
	local other=if self.picking and Fighters[self.opponentPick or ""] then self.opponentPick else self.bot
	if self.picking then self.side="player" end
	for id,t in self.tablets or {} do
		t.mine,t.theirs=id==self.player,id==other
		local picked=t.mine or t.theirs
		t.edge.Color=if t.mine then palette.red elseif t.theirs then palette.paper else t.accent
		t.edge.Thickness=if picked then 3 else 1.5
		t.edge.Transparency=if picked then 0 else .45
		t.seal.Text=if t.mine and t.theirs then "YOU • CPU" elseif t.mine then "YOU" elseif t.theirs then (if self.picking then "P2" else "CPU") else ""
		t.seal.BackgroundColor3=if t.mine then palette.red else palette.paper
		t.seal.TextColor3=if t.mine then palette.paper else palette.ink
		t.seal.BackgroundTransparency=if picked then 0 else 1
		t.tablet.BackgroundColor3=if picked then Color3.fromRGB(44,38,48) else Color3.fromRGB(22,19,25)
		self:liftTablet(t)
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
			local accent=accentOf(def)
			st.underline.BackgroundColor3=accent
			st.tag.BackgroundColor3=if self.side==side and not self.picking then palette.gold else palette.paper
			local model=self.portraits and self.portraits:FindFirstChild(id)
			if model and st.shown~=id and #model:GetDescendants()>=(model:GetAttribute("Descendants") or 0) then
				local first=st.shown==nil
				st.shown=id
				if self.menuStage then pcall(self.menuStage.show,self.menuStage,side,model,accent,not first) end
				if not first then self:enterStage(st) end
			end
		end
	end
	self.matchup.Text=string.upper((p.Name).."  VS  "..(o.Name))
	self.routeNote.Text=if p.Routes then string.upper(p.Name).." STRINGS  "..Controls.localize(p.Routes) else ""
end
-- The controls sheet: opened over any screen, built for the device in hand
-- and the fighter being played.
local GROUPS={
	{"MOVE",{{"Move","WASD","L stick"},{"Sprint","Sprint"},{"Jump","Jump"},{"Lock / unlock","Lock"},{"Wall run: into a wall","—","—"},{"Off the wall","WallDetach"}}},
	{"ATTACK",{{"Light strike (string)","Light"},{"Heavy strike","Heavy"},{"Grab, then throw","Grab"},{"Tool","Tool"},{"Kunai: draw / sheathe","Arm"},{"Chase / chakra dash","Pursuit"}}},
	{"DEFEND",{{"Guard (hold)","Guard"},{"Dodge","Dodge"},{"Escape when hit (substitution)","Substitute"},{"Feint a heavy","Feint"},{"Break a grab","Grab"}}},
	{"NINJA ARTS",{{"Jutsu 1-4","1  2  3  4","R1 + □ △ ○ ×"},{"Seal jutsu (hold the 2nd page)","hold C + 1-5","hold L2 + R1 + □△○× / D↑"},{"Jutsu 5","Technique5"},{"Chakra-infuse (hold + action)","Chakra"},{"Awaken (low health)","Awaken"},{"Ultimate (bar full)","Ultimate"}}},
}
function UI:buildControls(pad)
	local body=self.controlsBody
	body:ClearAllChildren()
	local K,P=Controls.KeyLabel,Controls.PadLabel
	local function key(entry)
		if entry[3] then return if pad then entry[3] else entry[2] end
		local label=if pad then P[entry[2]] else K[entry[2]]
		return label or entry[2]
	end
	for g,group in GROUPS do
		local x=(g-1)%2*530;local y=math.floor((g-1)/2)*200
		local head=text(body,group[1],UDim2.fromOffset(x,y),UDim2.fromOffset(500,28),24,palette.gold,TITLE_FONT);head.ZIndex=43
		for r,entry in group[2] do
			local row=y+30+(r-1)*27
			local chip=text(body,key(entry),UDim2.fromOffset(x,row),UDim2.fromOffset(150,23),15,palette.paper,TITLE_FONT,Enum.TextXAlignment.Center)
			chip.BackgroundColor3=palette.red;chip.BackgroundTransparency=.1;chip.ZIndex=43;corner(chip,4)
			chip.TextScaled=true;create("UITextSizeConstraint",chip,{MaxTextSize=15})
			local label=text(body,entry[1],UDim2.fromOffset(x+162,row),UDim2.fromOffset(350,23),15,palette.text,BODY_FONT);label.ZIndex=43
		end
	end
	-- The fighter in play (on the roster: the one picked): his strings, his jutsu.
	local h=self.lastHuman
	-- (Audit 04/11) his own fighter: in his own duel the one he plays, else
	-- the one picked (a watched match or the bracket showed someone else's).
	local own=h~=nil and not self.lastSpectate and (self.lastPhaseSeen=="Duel" or self.lastPhaseSeen=="Result")
	local id=if self.selection.Visible or not own then self.player else h.fighterId
	local def=Fighters[id or ""]
	local y=410
	local head=text(body,if def then string.upper(def.FullName or def.Name) else "YOUR FIGHTER",UDim2.fromOffset(0,y),UDim2.fromOffset(1048,28),24,palette.gold,TITLE_FONT);head.ZIndex=43
	local combo=Controls.comboHelp(MoveGraphs[id or ""] or {},pad)
	local strings=text(body,combo,UDim2.fromOffset(0,y+32),UDim2.fromOffset(1048,40),15,palette.text,BODY_FONT);strings.ZIndex=43
	if def and def.Techniques then
		local names={}
		for i,spec in def.Techniques do if i<=5 then table.insert(names,(if pad then Controls.TechniquePad[i] else tostring(i)).."  "..string.upper(spec.Name or spec.Id or "")) end end
		local jutsu=text(body,table.concat(names,"     "),UDim2.fromOffset(0,y+78),UDim2.fromOffset(1048,22),15,palette.paper,TITLE_FONT);jutsu.ZIndex=43
		jutsu.TextScaled=true;create("UITextSizeConstraint",jutsu,{MaxTextSize=15})
		if def.SealJutsu then
			local key=if pad then {"□","△","○","×","D↑"} else {"1","2","3","4","5"}
			local seals={}
			for i,spec in def.SealJutsu do table.insert(seals,key[i].."  "..string.upper(spec.Name)) end
			local sealRow=text(body,(if pad then "HOLD L2 + R1  " else "HOLD C  ")..table.concat(seals,"     "),UDim2.fromOffset(0,y+104),UDim2.fromOffset(1048,22),15,palette.gold,BODY_FONT);sealRow.ZIndex=43
			sealRow.TextScaled=true;create("UITextSizeConstraint",sealRow,{MaxTextSize=15})
		end
	end
	self.controlsClose.Text=(if pad then "START" else "TAB").." to close"
end
-- (DEC-032) The seal slip. (04/11, user: « une 2e page de jutsu ») The seal
-- jutsu are a second page of the four jutsu keys: keyboard C held + 1-5, pad
-- L2 + R1 held + □ △ ○ × (D-pad ↑ for a fifth; 05/11: it was R1 + L1, which
-- is the ultimate alone now). The slip lights up while the page is held; the
-- signs themselves are woven by the cast.
local function pageHeld(pad,flag)
	-- (Audit 04/11) The client's own page state (Input:sealPage) when it is
	-- sent; else the pad's L2 + R1 read here.
	if flag~=nil then return flag==true end
	local ok,held=pcall(function()
		if pad then
			local pressed={}
			for _,input in UIS:GetGamepadState(Enum.UserInputType.Gamepad1) do
				if input.UserInputState==Enum.UserInputState.Begin or input.Position.Z>.5 then pressed[input.KeyCode]=true end
			end
			return pressed[Controls.Gamepad.Modifier]==true and pressed[Controls.Gamepad.Chakra]==true
		end
		return UIS:IsKeyDown(Controls.Keyboard.WallDetach)
	end)
	return ok and held==true
end
function UI:sealHud(h,pad,page)
	local def=Fighters[h.fighterId or ""]
	local list=def and def.SealJutsu
	self.sealPanel.Visible=list~=nil
	if not list then self.sealWeave.Text="";return end
	local held=not h.wall and pageHeld(pad,page)
	local key=if pad then {"□","△","○","×","D↑"} else {"1","2","3","4","5"}
	self.sealHead.Text="HAND SEALS  •  "..(if pad then "HOLD L2 + R1" else "HOLD "..(Controls.KeyLabel.WallDetach or "C"))
	self.sealPanel.BackgroundTransparency=if held then .02 else .35
	local sealed=(h.sealed or 0)>0
	for i,row in self.sealRows do
		local spec=list[i]
		row.Visible=spec~=nil
		if spec then
			local state=h.sealReady and h.sealReady[i]
			local remaining=state and state.remaining or 0
			local glyphs={}
			for _,v in spec.Signs do table.insert(glyphs,SealJutsu.Glyphs[v]) end
			local ready=remaining==0 and h.chakra>=spec.Cost and not sealed
			row.Text=key[i].."   "..string.upper(spec.Name).."  "..table.concat(glyphs,"")..(if remaining>0 then string.format("   %.1fs",remaining) elseif h.chakra<spec.Cost then "   NEED CHAKRA" else "")
			row.TextColor3=if ready and held then palette.gold elseif ready then palette.paper else palette.muted
		end
	end
	self.sealWeave.Text=""
end
function UI:toggleControls()
	local open=not self.controls.Visible
	if open then
		local pad=false
		pcall(function() pad=Controls.isGamepad(UIS:GetLastInputType()) end)
		self:buildControls(pad)
	end
	self.controls.Visible=open
	if open then pcall(function() GuiService.SelectedObject=self.controlsCloseButton end)
	elseif GuiService.SelectedObject==self.controlsCloseButton then pcall(function() GuiService.SelectedObject=nil end) end
end
-- The ink stroke crosses the screen (0.5 s): the new screen is already under
-- it, uncovered by its trailing edge.
function UI:sweep()
	pcall(function()
		local w=self.wipe
		w.Visible=true
		w.Position=UDim2.fromScale(-.9,.5)
		local tween=Tween:Create(w,TweenInfo.new(.55,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Position=UDim2.fromScale(1.9,.5)})
		tween.Completed:Connect(function() w.Visible=false end)
		tween:Play()
	end)
end
-- The result card drops in and the judges' seal is stamped on it.
function UI:stampResult()
	pcall(function()
		self.resultScale.Scale=1.12
		Tween:Create(self.resultScale,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,.2),{Scale=1}):Play()
		self.resultSealScale.Scale=2.6
		Tween:Create(self.resultSealScale,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.55),{Scale=1}):Play()
	end)
end
-- A roster tile under the pointer rises; a picked one stands higher.
function UI:liftTablet(t)
	local rise=if t.mine or t.theirs then 10 elseif t.hover then 6 else 0
	local ok=pcall(function()
		Tween:Create(t.tablet,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(t.x,t.y-rise)}):Play()
		Tween:Create(t.seal,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(t.x+t.w-52,t.y-7-rise)}):Play()
	end)
	if not ok then t.tablet.Position=UDim2.fromOffset(t.x,t.y-rise) end
	t.glow.Size=UDim2.new(0,if t.mine or t.theirs then 10 elseif t.hover then 8 else 6,1,0)
	if t.label then t.label.TextColor3=if t.hover and not (t.mine or t.theirs) then palette.gold else palette.paper end
end
-- A new prodigy steps onto a stage: he slides in from the outer edge out of a
-- white flash, his name lands a beat later.
function UI:enterStage(st)
	pcall(function()
		st.flash.BackgroundTransparency=.55
		Tween:Create(st.flash,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
		st.nameScale.Scale=1.3
		Tween:Create(st.nameScale,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,.08),{Scale=1}):Play()
	end)
end
-- A tablet chosen for a stage (side "player" or "bot"). In an online pick
-- your stage is the only one you fill; the other is the opponent's choice.
function UI:pick(side,id)
	if not Fighters[id] or not table.find(Roster,id) then return end
	if self.picking then
		if side=="player" then self:choose(id) end
		return
	end
	if self.simple then side="player";self.side="player" end
	if side=="bot" then self.bot=id
	else
		self.player=id
		if self.simple then self.bot=FirstMinute.rival(id) or self.bot end
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
		self.opponentLabel.Text=if self.simple then "YOUR RIVAL" else "OPPONENT (AI)"
		self.startButton.Text=if self.simple then "PLAY" else "ENTER THE STAGE"
		self.tutorialButton.Text=if self.simple then "ALL MODES" else "TRAINING"
		self.notice.Text=data.notice or (if self.simple then "PICK YOUR NINJA, THEN PLAY  •  30 SECONDS ON THE FIELD, THEN YOUR FIRST DUEL" else "")
	end
	self.lastLobby=data
	local full=data.phase=="Selection" and not self.simple
	-- the strings' notes are for the full roster (jargon on a first look)
	self.routeNote.Visible=not self.simple
	self.onlineRow.Visible=full
	-- (Audit 04/11) not during the online pick (it did nothing there).
	self.cupButton.Visible=full
	self.levelButton.Visible=full
	if data.phase=="Queue" then
		local private=online~=nil and online.mode=="private"
		self.queueTitle.Text=if private then "PRIVATE DUEL" else "SEARCHING FOR AN OPPONENT"
		self.queueCode.Text=if private then (online.code or "") else ""
		self.queueNote.Text=if private then "Share this code: your friend types it next to JOIN on the roster screen."
			else "Casual 1v1  •  you meet the next player who searches."
		-- (Lobby, 04/11) a challenge: on the way to the duel server, then waiting there.
		local mode=online and online.mode
		if mode=="travel" or mode=="challenge" then
			self.queueTitle.Text=if mode=="travel" then "LEAVING FOR THE DUEL" else "CHALLENGE"
			self.queueCode.Text=""
			self.queueNote.Text=if mode=="travel" then "Both of you are on the way to the same arena…" else "Waiting for your opponent to arrive…"
		end
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
	-- (05/11) "SEALED • 2 TO FOLLOW UP": a jutsu key is its pad chord.
	cue=cue:gsub("%f[%w]([1-5]) TO ",function(d) return (Controls.TechniquePad[tonumber(d)] or d).." TO " end)
	-- (Audit 04/11) the keyboard keys the server's cues name, on the pad.
	cue=cue:gsub("%f[%w]E TO ",P.Pursuit.." TO "):gsub("%f[%w]E PURSUE",P.Pursuit.." PURSUE"):gsub("%f[%w]E CHASE",P.Pursuit.." CHASE")
	cue=cue:gsub("%f[%w]Q ON ",P.Dodge.." ON "):gsub("%f[%w]Q TO ",P.Dodge.." TO ")
	cue=cue:gsub("HEAVY: ",P.Heavy..": ")
	return cue
end
-- (FEEL 05/11) The server's refusal reasons, in the player's words.
local QUIET={BUSY="BUSY — STILL IN YOUR MOVE",REACTING="STILL HIT",COOLDOWN="RECHARGING",["NEED CHAKRA"]="NOT ENOUGH CHAKRA",
	["NO TARGET"]="NO TARGET",["OUT OF RANGE"]="TOO FAR",["TOO FAR"]="TOO FAR",["NO LINE OF SIGHT"]="NOT IN SIGHT",
	["TOOL RECOVERING"]="TOOL RECOVERING",["SUBSTITUTION RECOVERING"]="SUBSTITUTION RECHARGING",["NOT YET"]="NOT YET",["TOO SOON"]="TOO SOON",
	["ULTIMATE NOT READY"]="ULTIMATE NOT READY",["NO SUBSTITUTION"]="NO SUBSTITUTION LEFT"}
function UI.quietText(reason)
	return QUIET[reason] or reason
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
	self.lastSpectate=data.spectate==true;self.lastPhaseSeen=data.phase
	local pad=if data.gamepad~=nil then data.gamepad else Controls.isGamepad(UIS:GetLastInputType())
	self.tutorialPanel.Visible=data.tutorial~=nil and data.phase=="Duel"
	-- (User 02/11, tutorial on screen) The cue band (124) and the hint (200)
	-- sat on the tutorial panel (84-174): "SPACE REBOUND / C DETACH" was printed
	-- across the step's own instruction. Under the panel while it shows.
	self.cue.Position=UDim2.new(.5,-300,0,124)
	self.hint.Position=UDim2.new(.5,-260,0,200)
	if data.tutorial then
		self.tutorialTitle.Text=data.tutorial.index.." / "..data.tutorial.total.."  "..data.tutorial.title
		-- (B1; UI review 04/11: a phone was told "WASD" and "BACKSPACE")
		local tut=data.tutorial
		local keys=if data.touch then (tut.touch or tut.pad) elseif pad then tut.pad else Controls.localize(tut.key)
		local skip=if data.touch then "SKIP STEP" elseif pad then "TOUCHPAD" else "BACKSPACE"
		self.tutorialPrompt.Text=keys.."  •  "..skip..(if tut.first then " skips (hold: straight to the duel)" else " skips the step (hold: leave)")
	end
	local introActive=data.phase=="Duel" and (data.intro or 0)>0
	self.onlineInfo=data.online
	self.selection.Visible=data.phase=="Selection" or data.phase=="Pick"; self.hud.Visible=data.phase=="Duel" and not introActive; self.result.Visible=data.phase=="Result"
	self.queue.Visible=data.phase=="Queue"
	if self.screenFx then self.screenFx.Visible=data.phase=="Duel" and not introActive and not (FXKit and FXKit.calm) end
	self.intro.Visible=introActive
	-- Gamepad focus moves only after the matching screen is visible.
	if self.lastPhase~=data.phase then
		-- A change of screen passes under the ink stroke.
		if self.lastPhase~=nil then self:sweep() end
		if data.phase=="Result" then self:stampResult();self.simple=false end
		-- (UI review 04/11) a new screen closes the controls sheet.
		if self.controls.Visible then self:toggleControls() end
		local target=if data.phase=="Selection" or data.phase=="Pick" then self.startButton elseif data.phase=="Result" then self.rematchButton
			elseif data.phase=="Queue" then self.cancelButton else nil
		-- Only a button that is on screen can take the focus (the engine warns
		-- "invalid GuiObject" otherwise): wait the frame the screen appears in.
		local phase=data.phase
		local function shown()
			if not target then return false end
			local node=target
			while node and not node:IsA("LayerCollector") do
				if node:IsA("GuiObject") and not node.Visible then return false end
				node=node.Parent
			end
			-- Laid out too (the very first screen is not, the frame it is made).
			return node~=nil and node:IsA("ScreenGui") and node.Enabled and target.AbsoluteSize.X>0
		end
		task.defer(function()
			for _=1,20 do
				if self.lastPhase~=phase then return end
				local ok,on=pcall(shown)
				if ok and on then pcall(function() GuiService.SelectedObject=target end);return end
				if not target then break end
				task.wait(.1)
			end
			pcall(function() GuiService.SelectedObject=nil end)
		end)
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
		-- The knockout whitens the screen for an instant.
		pcall(function()
			self.koFlash=self.koFlash or frame(self.hud,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.paper,1)
			self.koFlash.ZIndex=0;self.koFlash.BackgroundTransparency=.35
			Tween:Create(self.koFlash,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
		end)
		self.ko.TextSize=170
		Tween:Create(self.ko,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{TextSize=120}):Play()
	end
	self.ko.Visible=data.ko==true
	self.round.Text=if data.matchPoint and data.ko then "MATCH" else "ROUND "..(data.round or 1)
	-- (in the tournament, the stage of the bracket under the round)
	self.roundSub.Text=if data.cup and data.cup.next and data.cup.next.roundName then data.cup.next.roundName else "PRODIGY TOURNAMENT"
	-- (a match watched in the tournament: neither fighter is the player)
	self.hp.name.Text=fullName(h);self.hp.title.Text=if data.spectate then "AI  •  "..subtitle(h) else subtitle(h).."  •  YOU"
	self.enemy.name.Text=fullName(b);self.enemy.title.Text=(if data.online then string.upper(data.online.opponent or "OPPONENT") else "AI").."  •  "..subtitle(b)
	for _,pair in {{self.hp,h},{self.enemy,b}} do
		local widget,actor=pair[1],pair[2]
		-- The fighter's initial in the medallion, his colour on its ring.
		if widget.faceFor~=actor.fighterId and Fighters[actor.fighterId or ""] then
			local def=Fighters[actor.fighterId]
			local accent=accentOf(def)
			widget.faceFor=actor.fighterId
			widget.ring.Color=accent;widget.glow.BackgroundColor3=accent
			widget.initial.Text=string.sub(string.upper(def.Name or "?"),1,1)
		end
		local ratio=math.clamp(actor.health/actor.maxHealth,0,1)
		widget.fill.Size=UDim2.fromScale(ratio,1)
		widget.fill.BackgroundColor3=if ratio>.5 then palette.gold elseif ratio>.25 then Color3.fromRGB(236,134,60) else palette.red
		-- In danger the bar throbs; with the ultimate full the medallion's ring burns.
		local t=os.clock()
		if ratio<=.25 and ratio>0 then widget.fill.BackgroundColor3=palette.red:Lerp(Color3.fromRGB(255,120,110),.5+.5*math.sin(t*9)) end
		if actor.ultimateReady then
			widget.ring.Color=Color3.fromRGB(255,200,80):Lerp(Color3.fromRGB(255,120,40),.5+.5*math.sin(t*6))
			widget.ring.Thickness=4
		elseif Fighters[actor.fighterId or ""] then
			widget.ring.Color=accentOf(Fighters[actor.fighterId]);widget.ring.Thickness=3
		end
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
		UI.ultimate(widget,actor,pad,actor==h and not data.spectate)
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
	-- Screen grade: the danger edges throb under a quarter of health.
	pcall(function()
		local t=os.clock()
		local ratio=math.clamp(h.health/math.max(h.maxHealth,1),0,1)
		-- (not on a match the player only watches: the danger is no one's)
		self.danger.GroupTransparency=if not data.spectate and ratio<=.25 and ratio>0 then .45+.35*(.5+.5*math.sin(t*5)) else 1
	end)
	-- Combo counters with the damage scale of the next hit.
	for _,pair in {{self.comboMine,b},{self.comboTheirs,h}} do
		local widget,victim=pair[1],pair[2]
		local hits=victim.comboHits or 0
		if hits>=2 then
			local scale=math.max(.35,1-.12*math.max(0,hits-1))
			widget.hits.Text=hits.." HITS"
			-- Paper, then gold, then vermilion as the string grows.
			widget.hits.TextColor3=if hits>=8 then Color3.fromRGB(255,96,80) elseif hits>=5 then palette.gold else palette.paper
			widget.hits.Rotation=-4
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
			local arm=if pad then Controls.PadLabel.Arm else Controls.KeyLabel.Arm
			local tool=if pad then Controls.PadLabel.Tool else Controls.KeyLabel.Tool
			if weapon then return if h.armed then weapon.Name.." DRAWN ("..arm.." sheathes it)" else arm..": draw "..string.lower(weapon.Name) end
			return if h.armed then "KUNAI DRAWN ("..tool.." throws it)" else arm..": draw kunai"
		end)())
	-- Only decisive moments speak; routine cues stay silent.
	-- (05/11) The server writes its cues with QWERTY keys: a pad reads the
	-- pad's buttons (UI.padCue), a keyboard its own letters. The two used to
	-- stack on a French Mac with a pad: "Q TO ESCAPE" became "A TO ESCAPE"
	-- before the pad's translation could find it.
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
		-- (05/11) how to get out of a blow (Combat.escapeOpen)
		or cue:find("TO ESCAPE")
		-- (06/11, Studio) the jutsu that meet (Interactions) and the steps of an
		-- awakening said nothing: steam, the water carrying lightning, the fire
		-- running the wire, Lee's gates, a summoning, a body switch.
		or cue:find("STEAM") or cue:find("WATER") or cue:find("SOAKED") or cue:find("DRAGON FLAME")
		or cue:find("GATE") or cue:find("SUMMONING") or cue:find("BODY SWITCH")
	cue=if pad then UI.padCue(cue) else Controls.localize(cue)
	self.cue.Text=if loud then cue else ""
	-- (FEEL 05/11, AVANT defect 3) The quiet line: why the last button did
	-- nothing (the server's own reason, Combat:quiet), small and grey under the
	-- band, gone in half a second. Never over a loud cue.
	self.channel.Text=if h.quiet and not loud then UI.quietText(h.quiet) else ""
	-- (05/11, user on the pad: L2 pressed alone 26 times) The chakra button
	-- held: the row shows what it infuses, the fighter's own moves.
	local chakraPage=data.chakraPage==true and not data.first and not data.touch and not data.spectate
	local K0,P0=Controls.KeyLabel,Controls.PadLabel
	if chakraPage then
		local keys=if pad then {P0.Light,P0.Heavy,P0.Jump,P0.Dodge,P0.Tool} else {K0.Light,K0.Heavy,K0.Jump,K0.Dodge,K0.Tool}
		for i,slot in ChakraMoves.Slots do
			local ui=self.techniqueButtons[i]
			ui.box.Visible=true;ui.box.Position=UDim2.new(1,-24-(5-i+1)*150+6,1,-84)
			ui.key.Text=keys[i];ui.key.TextColor3=palette.gold
			ui.title.Text=ChakraMoves.name(h.fighterId,slot);ui.title.TextColor3=palette.gold
			ui.status.Text="CHAKRA";ui.box.BackgroundTransparency=0
			ui.cool.Size=UDim2.fromScale(1,0);ui.wasReady=nil
		end
	end
	for i,tech in (if chakraPage then {} else h.techniques) do
		local ui=self.techniqueButtons[i]
		ui.box.Visible=true
		-- The row ends at the right edge whatever the kit's size.
		ui.box.Position=UDim2.new(1,-24-(#h.techniques-i+1)*150+6,1,-84)
		ui.key.Text=if pad then PAD_FACE[i] else string.format("%d",i)
		ui.title.Text=string.upper(tech.name)
		-- Sealed by the 64 Palms: every jutsu greys out and says why.
		local sealed=(h.sealed or 0)>0
		local ready=tech.remaining==0 and tech.condition and h.chakra>=tech.cost and not sealed
		-- (05/11, "NEEDS A SEAL /" cut in its 150 px box) says which one.
		local missing=if tech.requires=="Anchor" then "NEEDS A SEAL" elseif tech.requires=="Target" then "OUT OF RANGE" else "NOT NOW"
		ui.status.Text=if sealed then string.format("SEALED  •  %.1fs",h.sealed) elseif tech.remaining>0 then string.format("%.1fs",tech.remaining) elseif not tech.condition then missing elseif h.chakra<tech.cost then "NEED CHAKRA" else tech.cost.." CHAKRA"
		-- (06/11) Kakashi's copy slot: the jutsu his Sharingan copied, in red.
		if tech.copied then ui.status.Text="COPY • "..ui.status.Text end
		if tech.id=="Flashstep" and #(h.seals or {})>0 and tech.remaining==0 and not sealed then
			local count=#(h.seals or {})
			ui.status.Text=count.." SEAL"..(if count>1 then "S" else "").."  •  "..ui.status.Text
		end
		ui.box.BackgroundTransparency=if ready then .05 else .35
		-- (05/11) R1 held on a pad: the row it opens is lit, the buttons in gold.
		ui.key.TextColor3=if data.jutsuPage then palette.gold else palette.paper
		if data.jutsuPage then ui.box.BackgroundTransparency=0 end
		if ready and ui.wasReady==false then
			pcall(function()
				ui.flash=ui.flash or (function() local f=Instance.new("Frame");f.BackgroundColor3=palette.paper;f.BorderSizePixel=0;f.Size=UDim2.fromScale(1,1);f.ZIndex=5;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=f;f.Parent=ui.box;return f end)()
				ui.flash.BackgroundTransparency=.3
				Tween:Create(ui.flash,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
			end)
		end
		ui.wasReady=ready
		ui.title.TextColor3=if tech.copied then (if ready then Color3.fromRGB(255,86,86) else Color3.fromRGB(150,60,60)) elseif ready then palette.paper else palette.muted
		ui.cool.Size=UDim2.fromScale(1,math.clamp(math.max(tech.remaining/6,if sealed then h.sealed/5 else 0),0,1))
	end
	if not chakraPage then for i=#h.techniques+1,5 do self.techniqueButtons[i].box.Visible=false end end
	self:sealHud(h,pad,data.sealPage)
	local caption=self.jutsuCaption
	caption.Text=if chakraPage then (if pad then P0.Chakra else K0.Chakra).." +" else "R1 +"
	caption.TextColor3=if data.jutsuPage or chakraPage then palette.gold else palette.paper
	-- (B0, 04/11, seen on an emulated phone) on a touch screen the touch
	-- controls carry the jutsu and the seal page: the keyboard slots and the
	-- "HOLD C" slip sat under the buttons.
	if data.touch then
		for _,b in self.techniqueButtons do b.box.Visible=false end
		self.sealPanel.Visible=false
	end
	-- (B1 lot 2) the first minute and its duel: the signature's slot only,
	-- no seal page; the rest shows from the next duel on.
	if data.first then
		for i,b in self.techniqueButtons do if i~=FirstMinute.SignatureSlot then b.box.Visible=false end end
		self.sealPanel.Visible=false;self.sealWeave.Text=""
	end
	-- (Tournament) watching a match: none of these are the player's.
	if data.spectate then
		for _,b in self.techniqueButtons do b.box.Visible=false end
		self.sealPanel.Visible=false;self.sealWeave.Text=""
	end
	-- The caption sits left of the first card still shown (pad only).
	local leftmost=nil
	for i,b in self.techniqueButtons do if b.box.Visible then leftmost=leftmost or i end end
	caption.Visible=(pad or chakraPage) and leftmost~=nil
	local count=if chakraPage then 5 else #h.techniques
	if leftmost then caption.Position=UDim2.new(1,-24-(count-leftmost+1)*150+6-62,1,-74) end
	local techOpen=h.reaction=="WallSplat" and (h.splatElapsed or 9)<.34
	local conversion=UI.conversion(h,pad)
	local K,P=Controls.KeyLabel,Controls.PadLabel
	self.hint.Text=if techOpen then (if pad then P.Dodge.." — WALL TECH" else K.Dodge.." — WALL TECH")
		elseif conversion then conversion
		elseif b.reaction=="WallSplat" and h.pursuit>0 then (if pad then "× — PURSUE  •  △ — WALL BOUNCE" else Controls.KeyLabel.Pursuit.." — PURSUE  •  RMB — WALL BOUNCE")
		elseif (h.counter or 0)>0 then UI.counterPrompt(h,pad)
		-- The Chidori's risk, from the other side: its charge can be broken.
		elseif b.castId=="Chidori" and b.state=="TechniqueChannel" then (if pad then Controls.PadLabel.Light else Controls.KeyLabel.Light).." — BREAK THE CHIDORI CHARGE"
		elseif h.awakenReady then (if pad then "D-PAD ↓ — AWAKEN" else K.Awaken.." — AWAKEN")
		elseif h.wall then (if pad then "× — REBOUND  •  "..P.WallDetach.." — DETACH" else "SPACE — REBOUND  •  "..K.WallDetach.." — DETACH")
		-- (Audit 04/11) the pad's feint is R1 + R2 and its throw break L1 + □.
		elseif h.state=="Startup" and h.attackName=="Heavy" then (if pad then P.Feint.." — FEINT" else K.Feint.." — FEINT")
		elseif h.reaction=="Grabbed" then (if pad then P.Grab.." — THROW BREAK" else K.Grab.." — THROW BREAK")
		elseif h.pursuit>0 then (if pad then "× — CHASE" else Controls.KeyLabel.Pursuit.." / SPACE — CHASE")
		elseif (h.combo or 0)>=2 and h.state=="Recovery" and not h.airborne and (h.comboHits or 0)==0 and b.reaction then Controls.comboHelp(MoveGraphs[h.fighterId] or {},pad)
		else ""
	-- (Tournament, audit 04/11) watching an AI match: its prompts are not his.
	if data.spectate then self.hint.Text="";self.cue.Text="" end
	self.help.Text=if pad then Controls.HelpPad else Controls.Help
	self.grammar.Text=Controls.comboHelp(MoveGraphs[h.fighterId] or {},pad)
	-- (Reference quality) The control sheet is for the first seconds of a duel
	-- (and the tutorial), not a permanent band across the fight.
	if self.helpEpoch~=data.epoch then self.helpEpoch=data.epoch;self.helpUntil=os.clock()+10 end
	local helping=data.tutorial~=nil or os.clock()<(self.helpUntil or 0)
	-- (User 03/11) The keys live in the controls sheet (TAB), not on screen.
	self.help.Visible=false;self.grammar.Visible=false
	local _=helping
	self.lastHuman=h
	self.controlsChip.Text=(if pad then "START" else "TAB").."   CONTROLS"
	self.controlsChip.Visible=(os.clock()<(self.helpUntil or 0) or data.tutorial~=nil) and not data.touch
	local won=data.winner=="PlayerFighter"
	local winner=if won then h else b
	self.resultTitle.Text=(if won then "VICTORY" else "DEFEAT")..(if (data.roundsToWin or 1)>1 and data.wins then string.format("  %d–%d",data.wins.human or 0,data.wins.bot or 0) else "")
	self.resultTitle.TextColor3=if won then palette.gold else palette.crimson
	self.resultSeal.Text=if won then "勝" else "敗"
	self.resultSeal.BackgroundColor3=if won then palette.red else Color3.fromRGB(60,56,64)
	self.resultName.Text=fullName(winner).."  ADVANCES"
	if Fighters[winner.fighterId or ""] then self.resultName.TextColor3=accentOf(Fighters[winner.fighterId]):Lerp(palette.paper,.25) end
	self.resultNote.Text=if won then "The judges saw it too. The bracket waits for no one." else "Read the commitment. Find a better opening — prodigies learn fastest from defeat."
	-- Online: a rematch needs both players; a forfeit says so.
	local online=data.online
	self.rematchButton.Text=if not online then "REMATCH" elseif online.opponentLeft then "OPPONENT LEFT" elseif online.rematch then "WAITING FOR OPPONENT…"
		elseif online.theirRematch then "REMATCH  •  OPPONENT IS READY" else "REMATCH"
	if online and online.forfeit then
		self.resultTitle.Text=(if won then "VICTORY" else "DEFEAT").."  •  FORFEIT"
		self.resultNote.Text="Your opponent left the duel. The win is yours."
	end
	-- (Tournament) continue the bracket; a match watched names its winner.
	self.inCup=data.cup~=nil
	self.rosterButton.Text=if self.inCup then "LEAVE THE TOURNAMENT" else "RETURN TO THE ROSTER"
	if self.inCup then
		self.rematchButton.Text=if data.cup.out and not data.spectate then "SEE WHO WINS IT  •  THE BRACKET" else "CONTINUE  •  THE BRACKET"
		if data.spectate then
			local def=Fighters[winner.fighterId or ""]
			self.resultTitle.Text=string.upper(def and def.Name or "")..(if (data.roundsToWin or 1)>1 and data.wins then string.format("  %d–%d",math.max(data.wins.human or 0,data.wins.bot or 0),math.min(data.wins.human or 0,data.wins.bot or 0)) else "")
			self.resultTitle.TextColor3=palette.gold
			self.resultSeal.Text="勝";self.resultSeal.BackgroundColor3=palette.red
			self.resultNote.Text="One more name moves up the bracket."
		elseif won then
			self.resultNote.Text="Your name moves up the bracket."
		else
			self.resultNote.Text="Your tournament ends here. The bracket plays out without you."
		end
	end
end
return UI
