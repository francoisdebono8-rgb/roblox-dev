-- Phone and tablet controls (audit 04/11: the experience is open to phones and
-- tablets, and a touch player reached a duel with no way to move or strike;
-- Roblox's own controls are off, Main.client).
--
-- Left half: a floating stick where the thumb lands (pushed to the edge it
-- runs). Right half, empty screen: drag to turn the camera. Bottom right, the
-- fight cluster (the pad's layout: □ strike, △ heavy, ○ dodge, × jump / chase,
-- guard held, grab, tool), above it the jutsu row (SEALS turns it to the
-- second page, the seal jutsu) and a row of the rest (substitution, kunai,
-- chakra held, lock, awaken, ultimate; the tutorial's step skip).
-- Every button sends the same packets as a key (Input); the server validates
-- them all. Shown only on a touch screen, in the player's own duel.
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Fighters=require(game:GetService("ReplicatedStorage").NinjaDuel.Fighters)

local Touch={};Touch.__index=Touch
Touch.REFERENCE=390 -- the design height (a phone held sideways)
local INK=Color3.fromRGB(14,12,18)
local PAPER=Color3.fromRGB(244,236,220)
local RED=Color3.fromRGB(196,40,46)
local GOLD=Color3.fromRGB(232,184,72)
local MUTED=Color3.fromRGB(120,112,104)

local function new(class,props,parent)
	local o=Instance.new(class)
	for k,v in props do o[k]=v end
	o.Parent=parent
	return o
end
local function round(o,r) new("UICorner",{CornerRadius=UDim.new(r or .5,0)},o) end
local function isPress(io)
	return io.UserInputType==Enum.UserInputType.Touch or io.UserInputType==Enum.UserInputType.MouseButton1
end

function Touch.new(input,send,getState,toggleLock,camera)
	local self=setmetatable({input=input,send=send,getState=getState,toggleLock=toggleLock,camera=camera,
		held={},page=false,chakra=false,buttons={},jutsu={}},Touch)
	if not UIS.TouchEnabled then return self end
	local gui=new("ScreenGui",{Name="NinjaTouch",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=8,Enabled=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling},Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.gui=gui
	-- (each group scales about its own corner; the rows are stacked by hand)
	local scale={Scale=1}
	self.scale=scale

	-- The stick (drawn where the thumb lands).
	local base=new("Frame",{Name="StickBase",Size=UDim2.fromOffset(116,116),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=INK,
		BackgroundTransparency=.55,Visible=false},gui)
	round(base);new("UIStroke",{Color=PAPER,Transparency=.6,Thickness=2},base)
	local knob=new("Frame",{Name="Knob",Size=UDim2.fromOffset(52,52),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
		BackgroundColor3=PAPER,BackgroundTransparency=.25},base)
	round(knob)
	self.base,self.knob=base,knob

	local function button(parent,name,label,center,size,color,down,up)
		local b=new("TextButton",{Name=name,Text=label,Size=UDim2.fromOffset(size,size),AnchorPoint=Vector2.new(.5,.5),
			Position=UDim2.fromOffset(center.X,center.Y),BackgroundColor3=color or INK,BackgroundTransparency=.3,AutoButtonColor=false,
			TextColor3=PAPER,Font=Enum.Font.GothamBlack,TextScaled=true,Active=true},parent)
		round(b);new("UIStroke",{Color=PAPER,Transparency=.45,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
		new("UIPadding",{PaddingLeft=UDim.new(.16,0),PaddingRight=UDim.new(.16,0),PaddingTop=UDim.new(.2,0),PaddingBottom=UDim.new(.2,0)},b)
		b.InputBegan:Connect(function(io)
			if not isPress(io) or self.held[io] then return end
			self.held[io]={button=b,up=up}
			b.BackgroundTransparency=.05
			if down then down() end
		end)
		b.InputEnded:Connect(function(io) self:release(io) end)
		self.buttons[name]=b
		return b
	end
	self.button=button

	-- The fight cluster (bottom right).
	local cluster=new("Frame",{Name="Cluster",Size=UDim2.fromOffset(250,240),AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-12),
		BackgroundTransparency=1},gui)
	local function act(action) return function() self:press(action) end end
	button(cluster,"Attack","□",Vector2.new(185,175),86,RED,act("Attack"))
	button(cluster,"Heavy","△",Vector2.new(108,110),60,nil,act("Heavy"))
	button(cluster,"Dodge","○",Vector2.new(185,82),60,nil,act("Dodge"))
	button(cluster,"Jump","×",Vector2.new(92,198),60,nil,function() self.send("PadJump");self:used() end,function() self.send("JumpOff") end)
	button(cluster,"Guard","GUARD",Vector2.new(28,128),56,nil,function()
		self.guarding=true;self.send("Guard");self:used()
	end,function() self.guarding=false;self.send("GuardOff") end)
	button(cluster,"Grab","GRAB",Vector2.new(34,214),46,nil,act("Grab"))
	button(cluster,"Tool","TOOL",Vector2.new(236,26),46,nil,act("Tool"))

	-- The jutsu row (the quick slots; SEALS: the second page).
	local row=new("Frame",{Name="Jutsu",Size=UDim2.fromOffset(250,50),AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-258),
		BackgroundTransparency=1},gui)
	for i=1,5 do
		local b=button(row,"Jutsu"..i,tostring(i),Vector2.new(23+(i-1)*51,25),46,nil,function()
			if self.page then self.send("Seal"..i) else self:press("Technique"..i) end
			self:used()
		end,function() self.send("SealRelease") end)
		b.TextScaled=true
		self.jutsu[i]=b
	end
	local seals=button(row,"Seals","SEALS",Vector2.new(-32,25),52,nil,function()
		self.page=not self.page;self:refreshPage()
	end)
	self.sealsButton=seals

	-- The rest.
	local extras=new("Frame",{Name="Extras",Size=UDim2.fromOffset(250,40),AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-312),
		BackgroundTransparency=1},gui)
	local list={{"Substitute","SUB",act("Substitute")},{"Arm","KUNAI",act("Arm")},
		{"Chakra","CHAKRA",function() self.chakra=true end,function() self.chakra=false end},
		{"Lock","LOCK",function() self.toggleLock() end},{"Awaken","AWAKEN",act("Awaken")},{"Ultimate","ULT",act("Ultimate")}}
	for i,e in list do button(extras,e[1],e[2],Vector2.new(20+(i-1)*42,20),38,nil,e[3],e[4]) end
	self.skipButton=button(gui,"SkipStep","SKIP STEP",Vector2.new(0,0),60,nil,function() self.skipAt=os.clock() end,function()
		local held=os.clock()-(self.skipAt or os.clock())
		self.send(if held>=1 then "TutorialSkip" else "TutorialStep")
	end)
	self.skipButton.AnchorPoint=Vector2.new(0,0);self.skipButton.Position=UDim2.new(0,16,0,90);self.skipButton.Size=UDim2.fromOffset(96,40)
	round(self.skipButton,.25)
	local scales={}
	for _,group in {cluster,row,extras,base,self.skipButton} do table.insert(scales,new("UIScale",{Scale=1},group)) end
	local function fit()
		local size=workspace.CurrentCamera.ViewportSize
		local s=math.clamp(math.min(size.Y/Touch.REFERENCE,size.X/(Touch.REFERENCE*1.7)),.75,1.8)
		scale.Scale=s
		for _,u in scales do u.Scale=s end
		row.Position=UDim2.new(1,-12,1,-(12+246*s))
		extras.Position=UDim2.new(1,-12,1,-(12+300*s))
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()

	-- The stick and the camera drag: touches that no button took.
	UIS.TouchStarted:Connect(function(io,processed)
		if processed or not gui.Enabled then return end
		local size=workspace.CurrentCamera.ViewportSize
		local p=io.Position
		if p.X<size.X*.45 and not self.stickTouch then
			self.stickTouch=io;self.origin=Vector2.new(p.X,p.Y)
			base.Position=UDim2.fromOffset(p.X,p.Y);base.Visible=true
			knob.Position=UDim2.fromScale(.5,.5)
			self.input.touch=true
		elseif p.X>=size.X*.45 and not self.camTouch then
			self.camTouch=io;self.camLast=Vector2.new(p.X,p.Y)
		end
	end)
	UIS.TouchMoved:Connect(function(io)
		if io==self.stickTouch and self.origin then
			local d=Vector2.new(io.Position.X,io.Position.Y)-self.origin
			local radius=52*scale.Scale
			local v=d/radius
			if v.Magnitude>1 then v=v.Unit end
			self.input.touchStick=Vector2.new(v.X,-v.Y)
			-- pushed to the edge: the run
			self.input.sprinting=v.Magnitude>.92
			knob.Position=UDim2.new(.5,v.X*52,.5,v.Y*52)
		elseif io==self.camTouch and self.camLast then
			local p=Vector2.new(io.Position.X,io.Position.Y)
			local d=p-self.camLast;self.camLast=p
			self.camera.look=Vector2.new(math.clamp(d.X/7,-1.6,1.6),math.clamp(-d.Y/9,-1.2,1.2))
			self.camDriven=os.clock()
		end
	end)
	UIS.TouchEnded:Connect(function(io)
		self:release(io)
		if io==self.stickTouch then
			self.stickTouch=nil;self.origin=nil;base.Visible=false
			self.input.touchStick=Vector2.zero;self.input.sprinting=false
		elseif io==self.camTouch then
			self.camTouch=nil;self.camera.look=Vector2.zero
		end
	end)
	-- A drag is a nudge, not a held stick: the turn eases out between moves.
	RunService.RenderStepped:Connect(function()
		if self.camTouch and self.camDriven and os.clock()-self.camDriven>.05 then self.camera.look=self.camera.look*.5 end
	end)
	UIS.LastInputTypeChanged:Connect(function(kind)
		if kind==Enum.UserInputType.Touch then self.input.touch=true
		elseif kind~=Enum.UserInputType.MouseMovement and kind~=Enum.UserInputType.Focus then self.input.touch=false end
	end)
	self.input.touch=UIS:GetLastInputType()==Enum.UserInputType.Touch or not UIS.KeyboardEnabled
	return self
end
-- A press with the chakra button held goes out infused (Input: chakraOn).
function Touch:press(action)
	if self.chakra then self.send(action,{chakra=true}) else self.send(action) end
	self:used()
end
-- The page closes after one seal jutsu, like letting go of R1 + L1.
function Touch:used()
	self.input.touch=true
end
function Touch:release(io)
	local h=self.held[io]
	if not h then return end
	self.held[io]=nil
	h.button.BackgroundTransparency=.3
	if h.up then h.up() end
	if self.page and h.button.Name:match("^Jutsu") then self.page=false;self:refreshPage() end
end
function Touch:releaseAll()
	for io in table.clone(self.held) do self:release(io) end
	if self.stickTouch then self.stickTouch=nil;self.origin=nil;if self.base then self.base.Visible=false end end
	self.input.touchStick=Vector2.zero
	if self.camTouch then self.camTouch=nil;self.camera.look=Vector2.zero end
	self.chakra=false
end
local function short(name)
	name=string.upper(tostring(name or ""))
	-- the jutsu's own word: its last one, cut to fit a thumb-sized button
	local last=name:match("([%w%-]+)%s*$") or name
	return string.sub(last,1,9)
end
function Touch:refreshPage()
	if not self.gui then return end
	self.sealsButton.BackgroundColor3=if self.page then GOLD else INK
	self.sealsButton.TextColor3=if self.page then INK else PAPER
	self:labels(self.lastHuman)
end
function Touch:labels(h)
	if not h then return end
	local def=Fighters[h.fighterId or ""]
	local list=if self.page then (def and def.SealJutsu or {}) else (h.techniques or {})
	for i,b in self.jutsu do
		local spec=list[i]
		b.Visible=spec~=nil
		if spec then
			b.Text=short(spec.name or spec.Name)
			local ready=if self.page then true else (spec.remaining or 0)==0 and (h.chakra or 0)>=(spec.cost or 0)
			b.BackgroundColor3=if self.page then Color3.fromRGB(70,52,20) else INK
			b.TextColor3=if ready then PAPER else MUTED
		end
	end
	self.sealsButton.Visible=def~=nil and def.SealJutsu~=nil
end
-- Every game packet.
function Touch:render(data)
	if not self.gui then return end
	local show=data.phase=="Duel" and not data.spectate and self.input.touch==true
	if self.gui.Enabled and not show then self:releaseAll() end
	self.gui.Enabled=show
	if not show then self.page=false;return end
	local h=data.human
	self.lastHuman=h
	self:labels(h)
	if h then
		self.buttons.Ultimate.BackgroundColor3=if h.ultimateReady then GOLD else INK
		self.buttons.Ultimate.TextColor3=if h.ultimateReady then INK else MUTED
		self.buttons.Awaken.BackgroundColor3=if h.awakenReady then RED else INK
		self.buttons.Awaken.TextColor3=if h.awakenReady then PAPER else MUTED
		self.buttons.Lock.BackgroundColor3=if self.camera.locked then RED else INK
		self.buttons.Chakra.BackgroundColor3=if self.chakra then Color3.fromRGB(60,120,220) else INK
	end
	self.skipButton.Visible=data.tutorial~=nil
end
return Touch
