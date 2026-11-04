-- Players online and challenges, the client's half (Server/Lobby, user 04/11:
-- see who is connected, challenge one, the other gets a notification and
-- accepts or declines). Three pieces, all in the house ink card:
--  * PLAYERS ONLINE on the roster, with the count, opens the list: each
--    player's name, fighter and state, a CHALLENGE button; friends first;
--    do not disturb at the bottom.
--  * The invitation: a card at the top of the screen on every screen (the
--    roster, a duel against the AI, the result), ACCEPT / DECLINE and the time
--    left. Keyboard: Enter accepts, Backspace declines.
--  * The status line under it: challenge sent (cancel), declined, no answer,
--    leaving for the duel.
-- The client sends ids and booleans only; players the user blocked on Roblox
-- are hidden and their invitations declined unseen.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Panel={};Panel.__index=Panel

local STATE={free="ON THE ROSTER",training="VS THE AI",queue="SEARCHING",duel="IN A DUEL"}
local function blocked()
	local set={}
	pcall(function()
		for _,id in game:GetService("StarterGui"):GetCore("GetBlockedUserIds") or {} do set[id]=true end
	end)
	return set
end

function Panel.new(ui,remote,kit)
	local K=kit
	local P=K.palette
	local self=setmetatable({ui=ui,remote=remote,kit=K,players={},invites={},rows={},sentId=nil,dnd=false,blocked=blocked(),
		lastFighter=nil,open=false,phase="Selection"},Panel)
	-- PLAYERS ONLINE, on the roster above ENTER THE STAGE.
	self.button=K.button(ui.shell,"PLAYERS ONLINE",UDim2.fromOffset(1140,712),UDim2.fromOffset(400,52),function() self:toggle(true) end)
	self.button.TextSize=26
	-- The list.
	local overlay=K.frame(ui.gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),P.ink,.35)
	overlay.ZIndex=70;overlay.Visible=false;overlay.Active=true
	self.overlay=overlay
	-- (Studio 04/11) a little under the middle: an invitation at the top of
	-- the screen never covers the list's title.
	local card=K.inkCard(K.frame(overlay,UDim2.fromScale(.5,.57),UDim2.fromOffset(760,620),K.CARD,0))
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=71
	local scale=K.create("UIScale",card,{Scale=1})
	local function fit()
		local size=workspace.CurrentCamera.ViewportSize
		scale.Scale=math.clamp(math.min(size.X/1500,size.Y/860),.5,1.2)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit);fit()
	local title=K.inkTitle(K.text(card,"PLAYERS ONLINE",UDim2.fromOffset(28,16),UDim2.fromOffset(704,50),44,P.paper,K.TITLE_FONT))
	title.ZIndex=72
	self.subtitle=K.text(card,"",UDim2.fromOffset(30,66),UDim2.fromOffset(700,20),14,P.muted,K.BODY_FONT);self.subtitle.ZIndex=72
	local list=K.create("ScrollingFrame",card,{Position=UDim2.fromOffset(24,96),Size=UDim2.fromOffset(712,420),BackgroundTransparency=1,BorderSizePixel=0,
		ScrollBarThickness=6,CanvasSize=UDim2.fromOffset(0,0),ZIndex=72})
	self.list=list
	self.empty=K.text(list,"Nobody else is online right now. Train against the AI — the list refreshes by itself.",UDim2.fromOffset(20,30),UDim2.fromOffset(660,60),18,P.muted,K.BODY_FONT,Enum.TextXAlignment.Center)
	self.empty.ZIndex=73
	self.dndButton=K.button(card,"DO NOT DISTURB: OFF",UDim2.fromOffset(24,540),UDim2.fromOffset(340,56),function()
		self:send({op="dnd",on=not self.dnd})
	end)
	self.dndButton.ZIndex=72
	local close=K.button(card,"CLOSE",UDim2.fromOffset(396,540),UDim2.fromOffset(340,56),function() self:toggle(false) end)
	close.ZIndex=72
	self.closeButton=close
	-- The invitation and the status line, above every screen.
	local top=K.frame(ui.gui,UDim2.new(.5,0,0,8),UDim2.fromOffset(620,150),P.ink,1)
	top.AnchorPoint=Vector2.new(.5,0);top.ZIndex=80
	local topScale=K.create("UIScale",top,{Scale=1})
	local function fitTop()
		local size=workspace.CurrentCamera.ViewportSize
		topScale.Scale=math.clamp(math.min(size.X/1500,size.Y/860),.55,1.2)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitTop);fitTop()
	local invite=K.inkCard(K.frame(top,UDim2.fromOffset(0,0),UDim2.fromOffset(620,112),K.CARD,0),10)
	invite.ZIndex=81;invite.Visible=false
	self.inviteCard=invite
	self.inviteText=K.inkTitle(K.text(invite,"",UDim2.fromOffset(18,10),UDim2.fromOffset(584,34),30,P.paper,K.TITLE_FONT,Enum.TextXAlignment.Center))
	self.inviteText.ZIndex=82
	self.inviteSub=K.text(invite,"",UDim2.fromOffset(18,42),UDim2.fromOffset(584,18),13,P.muted,K.BODY_FONT,Enum.TextXAlignment.Center)
	self.inviteSub.ZIndex=82
	self.acceptButton=K.button(invite,"ACCEPT",UDim2.fromOffset(18,64),UDim2.fromOffset(284,38),function() self:answer(true) end,P.red)
	self.acceptButton.ZIndex=82
	self.declineButton=K.button(invite,"DECLINE",UDim2.fromOffset(318,64),UDim2.fromOffset(284,38),function() self:answer(false) end)
	self.declineButton.ZIndex=82
	self.timer=K.frame(invite,UDim2.new(0,0,1,-4),UDim2.new(1,0,0,4),P.gold,0);self.timer.ZIndex=83
	local status=K.frame(top,UDim2.fromOffset(60,118),UDim2.fromOffset(500,30),K.CARD,.1)
	K.corner(status,6);status.ZIndex=81;status.Visible=false
	self.statusBox=status
	self.statusText=K.text(status,"",UDim2.fromOffset(12,0),UDim2.fromOffset(380,30),14,P.paper,K.BODY_FONT,Enum.TextXAlignment.Center)
	self.statusText.ZIndex=82
	self.cancelButton=K.button(status,"CANCEL",UDim2.fromOffset(398,3),UDim2.fromOffset(98,24),function()
		if self.sentId then self:send({op="cancel",id=self.sentId}) end
	end)
	self.cancelButton.TextSize=16;self.cancelButton.ZIndex=82
	-- Keyboard answers (the cursor may be held by the duel camera).
	UIS.InputBegan:Connect(function(input,processed)
		if processed or not self.invite then return end
		if input.KeyCode==Enum.KeyCode.Return then self:answer(true)
		elseif input.KeyCode==Enum.KeyCode.Backspace then self:answer(false) end
	end)
	remote.OnClientEvent:Connect(function(data) self:receive(data) end)
	-- The fighter picked on the roster is what the others see next to the name.
	task.spawn(function()
		while true do
			task.wait(1)
			local id=ui.player
			if id and id~=self.lastFighter and Fighters[id] then self.lastFighter=id;self:send({op="fighter",fighter=id}) end
			self:tickTimer()
			if self.open then self:send({op="open"}) end
		end
	end)
	return self
end
function Panel:send(payload) pcall(function() self.remote:FireServer(payload) end) end
function Panel:toggle(open)
	self.open=open
	self.overlay.Visible=open
	self:send({op=if open then "open" else "close"})
	pcall(function() game:GetService("GuiService").SelectedObject=if open then self.closeButton else nil end)
end
function Panel:status(text,tone,cancellable)
	self.statusText.Text=text or ""
	self.statusText.TextColor3=if tone=="bad" then self.kit.palette.gold else self.kit.palette.paper
	self.statusBox.Visible=text~=nil and text~=""
	self.cancelButton.Visible=cancellable==true
	self.statusSerial=(self.statusSerial or 0)+1
	local serial=self.statusSerial
	if not cancellable then
		task.delay(6,function() if self.statusSerial==serial then self.statusBox.Visible=false end end)
	end
end
function Panel:receive(data)
	if type(data)~="table" then return end
	if data.kind=="list" then
		self.players=data.players or {}
		self.dnd=data.dnd==true
		self:drawList()
	elseif data.kind=="dnd" then
		self.dnd=data.on==true
		self:drawList()
	elseif data.kind=="invite" then
		if self.blocked[data.fromId] then self:send({op="answer",id=data.id,accept=false});return end
		self.invite={id=data.id,from=data.from,fighter=data.fighter,until_=os.clock()+(data.remaining or 20),length=data.remaining or 20}
		self:drawInvite()
	elseif data.kind=="closed" then
		if self.invite and self.invite.id==data.id then self.invite=nil;self:drawInvite() end
		if self.sentId==data.id then self.sentId=nil end
		if data.text then self:status(data.text,"bad") end
	elseif data.kind=="sent" then
		self.sentId=data.id
		self:status("CHALLENGE SENT TO "..string.upper(tostring(data.to)).."  •  WAITING…","info",true)
	elseif data.kind=="status" then
		if self.sentId and data.tone=="bad" then self.sentId=nil end
		self:status(data.text,data.tone,false)
		if string.find(tostring(data.text),"LEAVING FOR THE DUEL",1,true) or string.find(tostring(data.text),"ACCEPTED",1,true) then
			self.sentId=nil;self:toggle(false)
		end
	end
end
function Panel:answer(accept)
	local invite=self.invite
	if not invite then return end
	self.invite=nil
	self:drawInvite()
	self:send({op="answer",id=invite.id,accept=accept,fighter=self.ui.player})
end
function Panel:drawInvite()
	local invite=self.invite
	self.inviteCard.Visible=invite~=nil
	if not invite then return end
	local def=Fighters[invite.fighter or ""]
	self.inviteText.Text=string.upper(invite.from).." CHALLENGES YOU"
	self.inviteSub.Text=(if def then "WITH "..string.upper(def.Name).."  •  " else "").."ENTER ACCEPTS  •  BACKSPACE DECLINES"
	self:tickTimer()
end
function Panel:tickTimer()
	local invite=self.invite
	if not invite then return end
	local left=invite.until_-os.clock()
	if left<=0 then self.invite=nil;self:drawInvite();return end
	self.timer.Size=UDim2.new(math.clamp(left/invite.length,0,1),0,0,4)
end
function Panel:drawList()
	local K,P=self.kit,self.kit.palette
	for _,row in self.rows do row:Destroy() end
	table.clear(self.rows)
	self.rowButtons={}
	local shown=0
	local free=0
	for _,e in self.players do
		if self.blocked[e.id] then continue end
		shown+=1
		local available=(e.state=="free" or e.state=="training" or e.state=="queue") and not e.dnd
		if available then free+=1 end
		local row=K.frame(self.list,UDim2.fromOffset(0,(shown-1)*64),UDim2.fromOffset(696,58),P.panel,.15)
		K.corner(row,6);row.ZIndex=73
		local def=Fighters[e.fighter or ""]
		local accent=if def then Color3.fromRGB(table.unpack(def.Color)) else P.muted
		local bar=K.frame(row,UDim2.fromOffset(0,0),UDim2.new(0,6,1,0),accent,0);bar.ZIndex=74
		local name=K.text(row,(if e.friend then "★ " else "")..string.upper(e.name),UDim2.fromOffset(18,6),UDim2.fromOffset(340,28),24,P.paper,K.TITLE_FONT)
		name.ZIndex=74;name.TextScaled=true;K.create("UITextSizeConstraint",name,{MaxTextSize=24})
		local info=(if def then string.upper(def.Name).."  •  " else "")..(if e.dnd then "DO NOT DISTURB" else STATE[e.state] or "")..(if e.here then "  •  THIS SERVER" else "")
		local sub=K.text(row,info,UDim2.fromOffset(18,34),UDim2.fromOffset(440,18),12,P.muted,K.BODY_FONT);sub.ZIndex=74
		local label=if e.pending then "SENT…" elseif available then "CHALLENGE" else "BUSY"
		local b=K.button(row,label,UDim2.fromOffset(500,8),UDim2.fromOffset(186,42),function()
			if available and not e.pending then self:send({op="challenge",to=e.id,fighter=self.ui.player}) end
		end,if available and not e.pending then P.red else nil)
		b.ZIndex=74;b.AutoButtonColor=available
		if not available or e.pending then b.TextColor3=P.muted end
		table.insert(self.rows,row)
		table.insert(self.rowButtons,b)
	end
	self.list.CanvasSize=UDim2.fromOffset(0,shown*64)
	self.empty.Visible=shown==0
	self.subtitle.Text=if shown==0 then "" else string.format("%d ONLINE  •  %d READY FOR A DUEL  •  FRIENDS FIRST",shown,free)
	self.dndButton.Text="DO NOT DISTURB: "..(if self.dnd then "ON" else "OFF")
	self.button.Text=if shown>0 then string.format("PLAYERS ONLINE  •  %d",shown) else "PLAYERS ONLINE"
end
-- Called with every game packet: the button lives on the roster only; the
-- list closes when a duel or a pick starts.
function Panel:render(data)
	self.phase=data.phase
	self.button.Visible=data.phase=="Selection"
	if self.open and data.phase~="Selection" then self:toggle(false) end
end
return Panel
