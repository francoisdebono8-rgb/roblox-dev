-- SETTINGS (DESIGN, step 5, DEC-049): the sound, the camera's sensitivity,
-- the controls, and on the test place REPORT A PROBLEM. A page of the manga.
--
-- What it sets, for the DEV to read (attributes on the LocalPlayer, kept for
-- the session): NinjaVolume (0..1, also applied to SoundService's groups and
-- loose sounds here) and NinjaCameraSensitivity (0.4..2). REPORT sends
-- "Report" {text, where} — the DEV records it (the test place's button).
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Controls=require(Shared.Controls)

local S={}
S.__index=S
S.W,S.H=860,620
S.STEPS={volume=.1,sensitivity=.2}
S.LIMITS={volume={0,1},sensitivity={.4,2}}
S.MAX_REPORT=300
-- What the CONTROLS block lists: the action, its key, its pad button.
S.ROWS={
	{"MOVE","WASD","LEFT STICK"},{"LIGHT / HEAVY","LMB / RMB","X / Y"},{"GUARD","F","L1"},{"DODGE","Q","B"},
	{"JUMP","SPACE","A"},{"KUNAI","R","R2"},{"CHAKRA","Z","L2"},{"SUBSTITUTE","X","D-PAD RIGHT"},
	{"TECHNIQUES","1 2 3 4","R1 + X Y A B"},{"MAP","M","—"},
}

-- ------------------------------------------------------------------ pure
function S.step(value,kind,dir)
	local lo,hi=S.LIMITS[kind][1],S.LIMITS[kind][2]
	local v=math.clamp((value or 1)+dir*S.STEPS[kind],lo,hi)
	return math.floor(v*100+.5)/100
end
function S.percent(v) return string.format("%d%%",math.floor((v or 0)*100+.5)) end
-- A report as sent: trimmed, capped, and where it was made.
function S.report(text,where)
	text=tostring(text or ""):gsub("^%s+",""):gsub("%s+$","")
	if #text==0 then return nil end
	return {text=text:sub(1,S.MAX_REPORT),where=tostring(where or "")}
end
-- Is this the test place? (the DEV's attribute on workspace)
function S.testPlace()
	local ok,on=pcall(function() return workspace:GetAttribute("NinjaTestPlace") end)
	return ok and on==true
end

-- ------------------------------------------------------------------ page
function S.new(kit,gui,send)
	local self=setmetatable({kit=kit,send=send,volume=1,sensitivity=1},S)
	local M=kit.MANGA
	self.M=M
	local STRONG=kit.STRONG_FONT or kit.BODY_FONT
	self.root=kit.frame(gui,UDim2.fromScale(0,0),UDim2.fromScale(1,1),M.ink,.35)
	self.root.ZIndex=78;self.root.Visible=false;self.root.Active=true;self.root.Name="Settings"
	local card=kit.frame(self.root,UDim2.fromScale(.5,.5),UDim2.fromOffset(S.W,S.H),M.paper,0)
	card.AnchorPoint=Vector2.new(.5,.5);card.ZIndex=79
	kit.create("UIStroke",card,{Color=M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local scale=kit.create("UIScale",card,{Scale=1})
	local function fit()
		local v=workspace.CurrentCamera.ViewportSize
		scale.Scale=kit.fitScale(Vector2.new(v.X,v.Y-58),S.W+24,S.H+24,1.1)
	end
	pcall(function() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end);fit()
	local function z(o,d) o.ZIndex=80+(d or 0);return o end
	local function ring(o,t) kit.create("UIStroke",o,{Color=M.ink,Thickness=t or 3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});return o end
	z(kit.text(card,"SETTINGS",UDim2.fromOffset(28,10),UDim2.fromOffset(500,64),60,M.ink,kit.TITLE_FONT))
	z(kit.frame(card,UDim2.fromOffset(28,70),UDim2.fromOffset(180,6),M.red,0))
	self.close=z(kit.button(card,"X",UDim2.fromOffset(S.W-88,14),UDim2.fromOffset(68,68),function() self:hide() end,M.ink),2)
	self.close.TextColor3=M.cream;self.close.TextSize=34
	-- a row: its name, − value +
	local function stepper(y,name,kind)
		z(kit.text(card,name,UDim2.fromOffset(28,y),UDim2.fromOffset(330,56),28,M.ink,kit.TITLE_FONT))
		local minus=z(kit.button(card,"−",UDim2.fromOffset(370,y),UDim2.fromOffset(64,56),function() self:set(kind,-1) end,M.paper),1)
		minus.TextSize=36;minus.TextColor3=M.ink;ring(minus)
		local value=z(kit.text(card,"",UDim2.fromOffset(444,y),UDim2.fromOffset(120,56),30,M.ink,STRONG,Enum.TextXAlignment.Center))
		local plus=z(kit.button(card,"+",UDim2.fromOffset(574,y),UDim2.fromOffset(64,56),function() self:set(kind,1) end,M.paper),1)
		plus.TextSize=36;plus.TextColor3=M.ink;ring(plus)
		return value,minus,plus
	end
	self.volumeText,self.volumeMinus,self.volumePlus=stepper(96,"SOUND","volume")
	self.sensText,self.sensMinus,self.sensPlus=stepper(164,"CAMERA","sensitivity")
	-- the controls
	z(kit.text(card,"CONTROLS",UDim2.fromOffset(28,236),UDim2.fromOffset(300,34),28,M.ink,kit.TITLE_FONT))
	z(kit.text(card,"KEYBOARD",UDim2.fromOffset(330,242),UDim2.fromOffset(200,24),15,M.red,STRONG))
	z(kit.text(card,"PAD",UDim2.fromOffset(560,242),UDim2.fromOffset(200,24),15,M.red,STRONG))
	for i,row in S.ROWS do
		local y=274+(i-1)*24
		z(kit.text(card,row[1],UDim2.fromOffset(28,y),UDim2.fromOffset(290,22),16,M.ink,STRONG))
		z(kit.text(card,row[2],UDim2.fromOffset(330,y),UDim2.fromOffset(220,22),16,M.mid or M.ink,STRONG))
		z(kit.text(card,row[3],UDim2.fromOffset(560,y),UDim2.fromOffset(260,22),16,M.mid or M.ink,STRONG))
	end
	-- REPORT A PROBLEM (the test place)
	self.reportButton=z(kit.button(card,"REPORT A PROBLEM",UDim2.fromOffset(28,S.H-76),UDim2.fromOffset(320,56),function() self:openReport() end,M.red),1)
	self.reportButton.TextColor3=M.cream;self.reportButton.TextSize=24
	self.thanks=z(kit.text(card,"",UDim2.fromOffset(364,S.H-70),UDim2.fromOffset(460,44),18,M.red,STRONG))
	-- the report's box
	local box=z(kit.frame(card,UDim2.fromScale(.5,.5),UDim2.fromOffset(700,300),M.paper,0),4)
	box.AnchorPoint=Vector2.new(.5,.5);box.Visible=false;ring(box,4)
	self.reportBox=box
	z(kit.text(box,"WHAT HAPPENED?",UDim2.fromOffset(24,14),UDim2.fromOffset(600,48),42,M.ink,kit.TITLE_FONT),5)
	z(kit.text(box,"One line. We'll know where you were.",UDim2.fromOffset(24,62),UDim2.fromOffset(640,22),16,M.mid or M.ink,kit.BODY_FONT),5)
	local field=kit.create("TextBox",box,{Position=UDim2.fromOffset(24,94),Size=UDim2.fromOffset(652,110),BackgroundColor3=M.cream,
		Text="",PlaceholderText="E.G. I FELL THROUGH THE ROOF NEAR ICHIRAKU",PlaceholderColor3=M.brown or M.ink,TextColor3=M.ink,TextSize=20,
		Font=STRONG,ClearTextOnFocus=false,TextWrapped=true,MultiLine=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=86})
	kit.create("UIPadding",field,{PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,8)})
	ring(field,2)
	self.field=field
	local cancel=z(kit.button(box,"CANCEL",UDim2.fromOffset(24,222),UDim2.fromOffset(220,56),function() box.Visible=false end,M.paper),6)
	cancel.TextColor3=M.ink;cancel.TextSize=24;ring(cancel)
	self.sendButton=z(kit.button(box,"SEND",UDim2.fromOffset(456,222),UDim2.fromOffset(220,56),function() self:sendReport() end,M.red),6)
	self.sendButton.TextColor3=M.cream;self.sendButton.TextSize=28
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
			if not self.root.Visible then return end
			if input.KeyCode==Enum.KeyCode.ButtonB or (input.KeyCode==Enum.KeyCode.Escape and not processed) then self:hide() end
		end)
	end)
	self:draw()
	return self
end

function S:shown() return self.root.Visible end
function S:show(where) self.where=where;self.root.Visible=true;self.reportBox.Visible=false;self.thanks.Text="";self:draw() end
function S:hide() self.root.Visible=false;if self.onHide then self.onHide() end end
function S:draw()
	self.volumeText.Text=S.percent(self.volume)
	self.sensText.Text=string.format("×%.1f",self.sensitivity)
	self.reportButton.Visible=S.testPlace() or self.forceReport==true
end
function S:set(kind,dir)
	self[kind]=S.step(self[kind],kind,dir)
	pcall(function()
		local player=game:GetService("Players").LocalPlayer
		if kind=="volume" then
			player:SetAttribute("NinjaVolume",self.volume)
			for _,g in game:GetService("SoundService"):GetDescendants() do
				if g:IsA("SoundGroup") then g.Volume=self.volume end
			end
		else
			player:SetAttribute("NinjaCameraSensitivity",self.sensitivity)
			UserSettings():GetService("UserGameSettings").MouseSensitivity=self.sensitivity
		end
	end)
	self:draw()
end
function S:openReport() self.field.Text="";self.reportBox.Visible=true end
function S:sendReport()
	local r=S.report(self.field.Text,self.where)
	if not r then return false end
	self.send("Report",r)
	self.reportBox.Visible=false
	self.thanks.Text="GOT IT. THANKS!"
	return true
end

return S
