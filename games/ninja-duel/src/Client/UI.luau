local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)
local UI={}; UI.__index=UI
local palette={bg=Color3.fromRGB(14,22,30),panel=Color3.fromRGB(25,36,47),text=Color3.fromRGB(235,240,232),muted=Color3.fromRGB(154,174,181),blue=Color3.fromRGB(82,177,244),red=Color3.fromRGB(222,106,137)}
local function create(class,parent,props)
	local x=Instance.new(class)
	for k,v in props do x[k]=v end
	x.Parent=parent; return x
end
local function frame(parent,position,size,color)
	return create("Frame",parent,{Position=position,Size=size,BackgroundColor3=color or palette.panel,BorderSizePixel=0})
end
local function text(parent,value,position,size,fontSize,color)
	return create("TextLabel",parent,{Text=value,Position=position,Size=size,TextSize=fontSize or 16,Font=Enum.Font.GothamMedium,TextColor3=color or palette.text,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,value,position,size,callback,color)
	local b=create("TextButton",parent,{Text=value,Position=position,Size=size,TextSize=16,Font=Enum.Font.GothamBold,TextColor3=palette.text,BackgroundColor3=color or palette.panel,BorderSizePixel=0,AutoButtonColor=true})
	create("UICorner",b,{CornerRadius=UDim.new(0,6)})
	b.Activated:Connect(callback); return b
end
local function portrait(parent,def,position)
	local vp=create("ViewportFrame",parent,{Position=position,Size=UDim2.new(0,100,0,116),BackgroundTransparency=1,Ambient=Color3.fromRGB(185,185,185),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,-1)})
	local function p(size,at,color)
		create("Part",vp,{Size=size,CFrame=CFrame.new(at),Color=Color3.fromRGB(table.unpack(color)),Anchored=true})
	end
	p(Vector3.new(2,2,1),Vector3.zero,def.Outfit)
	p(Vector3.new(1.5,1.5,1.5),Vector3.new(0,1.6,0),def.Skin)
	p(Vector3.new(1.65,0.55,1.65),Vector3.new(0,2.12,0),def.Hair)
	for _,s in {-1,1} do p(Vector3.new(1,2,1),Vector3.new(s*1.5,0,0),def.Outfit) end
	p(Vector3.new(2.1,0.25,1.1),Vector3.new(0,-0.65,0),def.Color)
	local camera=create("Camera",vp,{CFrame=CFrame.lookAt(Vector3.new(4,2.8,-8),Vector3.new(0,0.7,0))})
	vp.CurrentCamera=camera
end
function UI.new(parent,send)
	local self=setmetatable({player="Flashstep",bot="Mirage",send=send,selectionButtons={}},UI)
	self.gui=create("ScreenGui",parent,{Name="NinjaDuelHUD",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	self.selection=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.bg)
	local shell=frame(self.selection,UDim2.new(0.5,-390,0.5,-255),UDim2.fromOffset(780,510),palette.bg)
	create("UISizeConstraint",shell,{MinSize=Vector2.new(780,510),MaxSize=Vector2.new(780,510)})
	text(shell,"NINJA DUEL",UDim2.fromOffset(0,0),UDim2.fromOffset(780,48),38)
	text(shell,"V0.2  /  THE TRAINING COURTYARD",UDim2.fromOffset(2,51),UDim2.fromOffset(760,25),13,palette.muted)
	text(shell,"A duel is won in the opening you create.",UDim2.fromOffset(2,85),UDim2.fromOffset(760,30),20)
	for i,id in {"Flashstep","Mirage"} do
		local def=Fighters[id]; local x=(i-1)*400
		local card=frame(shell,UDim2.fromOffset(x,135),UDim2.fromOffset(380,215))
		local accent=Color3.fromRGB(table.unpack(def.Color))
		frame(card,UDim2.fromOffset(0,0),UDim2.fromOffset(380,3),accent)
		portrait(card,def,UDim2.fromOffset(12,20))
		text(card,def.Name,UDim2.fromOffset(128,21),UDim2.fromOffset(235,35),26,accent)
		text(card,def.Title,UDim2.fromOffset(128,61),UDim2.fromOffset(235,20),11,palette.muted)
		text(card,def.Description,UDim2.fromOffset(128,90),UDim2.fromOffset(235,58),14)
		text(card,string.format("%d HP   •   %s",def.Health,if id=="Flashstep" then "Mobility / punishes" else "Reads / deception"),UDim2.fromOffset(18,176),UDim2.fromOffset(345,23),13,palette.muted)
	end
	text(shell,"YOUR FIGHTER",UDim2.fromOffset(0,371),UDim2.fromOffset(360,20),12,palette.muted)
	text(shell,"AI OPPONENT",UDim2.fromOffset(400,371),UDim2.fromOffset(360,20),12,palette.muted)
	for i,id in {"Flashstep","Mirage"} do
		self.selectionButtons["player"..id]=button(shell,id,UDim2.fromOffset((i-1)*194,400),UDim2.fromOffset(186,36),function() self.player=id; self:refreshSelection() end)
		self.selectionButtons["bot"..id]=button(shell,id,UDim2.fromOffset(400+(i-1)*194,400),UDim2.fromOffset(186,36),function() self.bot=id; self:refreshSelection() end)
	end
	button(shell,"START DUEL  →",UDim2.fromOffset(0,459),UDim2.fromOffset(780,45),function() send("Start",{player=self.player,bot=self.bot}) end,Color3.fromRGB(36,88,109))
	self.hud=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1)); self.hud.BackgroundTransparency=1
	local function meter(parent,name,pos,color)
		local box=frame(parent,pos,UDim2.fromOffset(310,88))
		local label=text(box,name,UDim2.fromOffset(14,7),UDim2.fromOffset(282,24),18)
		local track=frame(box,UDim2.fromOffset(14,39),UDim2.fromOffset(282,8),palette.bg)
		local fill=frame(track,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),color)
		local status=text(box,"",UDim2.fromOffset(14,56),UDim2.fromOffset(282,22),12,palette.muted)
		return {box=box,label=label,fill=fill,status=status}
	end
	self.hp=meter(self.hud,"",UDim2.fromOffset(22,20),palette.blue)
	self.enemy=meter(self.hud,"",UDim2.new(1,-332,0,20),palette.red)
	self.chakra=meter(self.hud,"CHAKRA",UDim2.new(0,22,1,-207),palette.blue)
	self.cue=text(self.hud,"",UDim2.new(0.5,-250,0,128),UDim2.fromOffset(500,36),22); self.cue.TextXAlignment=Enum.TextXAlignment.Center
	self.channel=text(self.hud,"",UDim2.new(0.5,-250,0,165),UDim2.fromOffset(500,28),15,palette.muted); self.channel.TextXAlignment=Enum.TextXAlignment.Center
	self.techniqueButtons={}
	for i=1,3 do
		local box=frame(self.hud,UDim2.new(0.5,-297+(i-1)*202,1,-110),UDim2.fromOffset(194,66))
		self.techniqueButtons[i]={title=text(box,"",UDim2.fromOffset(10,5),UDim2.fromOffset(176,26),15),status=text(box,"",UDim2.fromOffset(10,33),UDim2.fromOffset(176,22),12,palette.muted),box=box}
	end
	self.help=text(self.hud,"WASD move   CTRL sprint   SPACE ninja jump   LMB 4-hit chain   F guard   Q dash   E pursue   1/2/3 techniques   SHIFT lock",UDim2.new(0.5,-420,1,-34),UDim2.fromOffset(840,25),12,palette.muted)
	self.help.TextXAlignment=Enum.TextXAlignment.Center
	self.hint=text(self.hud,"",UDim2.new(0.5,-260,0,199),UDim2.fromOffset(520,30),13,palette.muted); self.hint.TextXAlignment=Enum.TextXAlignment.Center
	self.result=frame(self.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),palette.bg); self.result.BackgroundTransparency=0.2
	local resultBox=frame(self.result,UDim2.new(0.5,-240,0.5,-140),UDim2.fromOffset(480,280))
	self.resultTitle=text(resultBox,"",UDim2.fromOffset(30,24),UDim2.fromOffset(420,50),32)
	text(resultBox,"Read the commitment. Find a better opening.",UDim2.fromOffset(30,85),UDim2.fromOffset(420,45),15,palette.muted)
	button(resultBox,"REMATCH",UDim2.fromOffset(30,151),UDim2.fromOffset(420,42),function() send("Rematch") end,Color3.fromRGB(36,88,109))
	button(resultBox,"RETURN TO SELECTION",UDim2.fromOffset(30,211),UDim2.fromOffset(420,42),function() send("Selection") end)
	-- A small displaced indicator during Mirage; real body remains visible and controllable.
	self.echo=create("BillboardGui",self.gui,{Name="FalseTarget",Size=UDim2.fromOffset(130,38),AlwaysOnTop=true,Enabled=false})
	local echoLabel=text(self.echo,"◇  ECHO?",UDim2.fromScale(0,0),UDim2.fromScale(1,1),17,palette.red); echoLabel.TextXAlignment=Enum.TextXAlignment.Center
	self:refreshSelection(); self:render({phase="Selection"})
	return self
end
function UI:refreshSelection()
	for key,b in self.selectionButtons do
		local selected=key=="player"..self.player or key=="bot"..self.bot
		b.BackgroundColor3=if selected then Color3.fromRGB(48,96,117) else palette.panel
	end
end
function UI:render(data)
	self.selection.Visible=data.phase=="Selection"; self.hud.Visible=data.phase=="Duel"; self.result.Visible=data.phase=="Result"
	self.echo.Enabled=false
	if data.phase=="Selection" then return end
	local h,b=data.human,data.bot
	if not h or not b then return end
	self.hp.label.Text=h.fighter.."  /  YOU"; self.enemy.label.Text=b.fighter.."  /  AI"
	self.hp.fill.Size=UDim2.fromScale(math.clamp(h.health/h.maxHealth,0,1),1)
	self.enemy.fill.Size=UDim2.fromScale(math.clamp(b.health/b.maxHealth,0,1),1)
	self.hp.status.Text=string.format("%d / %d HP   •   %s",math.ceil(h.health),h.maxHealth,h.state)
	self.enemy.status.Text=string.format("%d / %d HP   •   %s",math.ceil(b.health),b.maxHealth,b.state)
	self.chakra.label.Text=string.format("CHAKRA  %d / 100",math.floor(h.chakra)); self.chakra.fill.Size=UDim2.fromScale(h.chakra/100,1)
	self.chakra.status.Text=if h.dodge>0 then string.format("Dodge %.1fs",h.dodge) else "Dodge ready • 16 chakra"
	self.cue.Text=h.cue
	self.channel.Text=if h.channel>0 then string.format("PREPARING %.1fs • vulnerable to interruption",h.channel) elseif b.channel>0 then string.format("OPPONENT PREPARING %.1fs • interrupt or evade",b.channel) else ""
	for i,tech in h.techniques do
		local ui=self.techniqueButtons[i]; ui.title.Text=i.."  "..tech.name
		ui.status.Text=if tech.remaining>0 then string.format("%.1fs cooldown",tech.remaining) elseif not tech.condition then "Setup required" elseif h.chakra<tech.cost then "Need chakra" else tech.cost.." chakra • ready"
		ui.box.BackgroundColor3=if tech.remaining==0 and tech.condition and h.chakra>=tech.cost then Color3.fromRGB(30,57,69) else palette.panel
	end
	self.hint.Text=if h.pursuit>0 then string.format("PURSUIT %.1fs • press E to close after launch",h.pursuit) elseif h.anchor then "ANCHOR ACTIVE • 2 to relocate • arrival has recovery" elseif h.read>0 then "READ ACTIVE • one frontal melee • punish after success" else Fighters[h.fighter].Description
	self.resultTitle.Text=if data.winner=="PlayerFighter" then "VICTORY" else "DEFEAT"
	if h.illusion>0 and data.phase=="Duel" then
		local character=game:GetService("Players").LocalPlayer.Character
		local folder=character and character.Parent
		local effects=folder and folder:FindFirstChild("Effects")
		local echo=effects and effects:FindFirstChild("Echo")
		if echo then self.echo.Adornee=echo; self.echo.Enabled=true end
	end
end
return UI
