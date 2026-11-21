-- The things to do alone in Konoha, on screen and in the world (21/11, étape 3
-- DEV 4, DEC-047). The server runs them (Server/SoloPlay, Shared/Solo); this
-- draws what the player needs while he does them, in the manga page's ink:
--   * the prompts: the race's post, the targets' mark, a challenger's
--     ACCEPT (they send SoloRace, SoloTargets, SoloChallenge);
--   * the race: the next ring on its roof (a column of light seen from the
--     street, a halo on the roof, its number), the one after it dimmer; the
--     clock, the ring count, the countdown;
--   * the targets: the boards he hit hidden for him, the clock, hits and
--     misses; the throw (R, R2, the mouse's click, THROW on a phone) aimed
--     where he points, the kunai seen flying;
--   * the end: FINISH and the time, NEW BEST, the mastery earned; why a run
--     did not count;
--   * the board of the best times over the race's post; the challenger's line.
-- It reads the player's attributes (SoloPlay's header). Presentation only:
-- every rule is the server's. The DESIGN may restyle any of it.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local TweenService=game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Solo=require(Shared.Solo)
local HubMap=require(Shared.HubMap)

local View={}
View.__index=View
local S=HubMap.Scale or 1
local GLOW=Color3.fromRGB(255,120,48)

-- Why a run did not count, said to him.
View.FAIL={
	teleport="OFF COURSE: THE RUN DID NOT COUNT",time="TOO SLOW: TRY AGAIN",floor="THAT RUN WAS NOT POSSIBLE",
	left="RACE LEFT",quit="GIVEN UP",far="TOO FAR FROM THE MARK",
}
-- The line of an end (pure): {title, line, sub}.
function View.endLines(what,time,best,gain,new)
	if what=="finish" or what=="done" then
		local title=if what=="finish" then "FINISH" else "ALL HIT"
		local line=Solo.clock(time or 0)
		local sub=if new then "NEW BEST!" elseif best then "BEST "..Solo.clock(best) else ""
		if gain and gain>0 then sub..=(if sub~="" then "   •   " else "").."+"..gain.." MASTERY" end
		return {title=title,line=line,sub=sub}
	elseif what=="won" or what=="lost" then
		local sub=if gain and gain>0 then "+"..gain.." MASTERY" else ""
		return {title=if what=="won" then "CHALLENGE WON" else "CHALLENGE LOST",line="",sub=sub}
	end
	local why=string.match(tostring(what),"^fail:(.+)$")
	return {title="NO TIME",line="",sub=View.FAIL[why or ""] or "TRY AGAIN"}
end

function View.new(kit,gui,send,walking)
	local self=setmetatable({kit=kit,gui=gui,send=send,walking=walking or function() return true end,rings={},serial=nil,hidden={},bubbles={}},View)
	local M=kit.MANGA
	self.M=M
	-- the clock: an ink case at the top, the page's paper text
	local case=kit.frame(gui,UDim2.new(.5,-170,0,18),UDim2.fromOffset(340,108),M.ink,0)
	case.Name="SoloClock";case.Visible=false;case.ZIndex=40
	kit.create("UIStroke",case,{Color=M.paper,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	local brush=kit.frame(case,UDim2.fromOffset(18,-4),UDim2.new(.32,0,0,8),M.red,0);brush.Rotation=-1;brush.ZIndex=41
	self.what=kit.text(case,"",UDim2.fromOffset(16,8),UDim2.new(1,-32,0,22),18,M.redSoft,kit.STRONG_FONT or kit.BODY_FONT,Enum.TextXAlignment.Center);self.what.ZIndex=41
	self.clock=kit.text(case,"0:00.00",UDim2.fromOffset(16,28),UDim2.new(1,-32,0,50),46,M.paper,kit.TITLE_FONT,Enum.TextXAlignment.Center);self.clock.ZIndex=41
	self.count=kit.text(case,"",UDim2.fromOffset(16,78),UDim2.new(1,-32,0,24),18,M.cream,kit.BODY_FONT,Enum.TextXAlignment.Center);self.count.ZIndex=41
	self.case=case
	-- the countdown, big in the middle
	self.go=kit.text(gui,"",UDim2.new(.5,-150,.32,0),UDim2.fromOffset(300,140),120,M.paper,kit.TITLE_FONT,Enum.TextXAlignment.Center)
	self.go.Visible=false;self.go.ZIndex=42
	kit.create("UIStroke",self.go,{Color=M.ink,Thickness=6,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	-- the end: a red stamp on a paper case
	local stamp=kit.frame(gui,UDim2.new(.5,-230,.24,0),UDim2.fromOffset(460,170),M.paper,0)
	stamp.Visible=false;stamp.ZIndex=44;stamp.Rotation=-2
	kit.create("UIStroke",stamp,{Color=M.ink,Thickness=5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	self.stampTitle=kit.text(stamp,"",UDim2.fromOffset(16,10),UDim2.new(1,-32,0,56),52,M.red,kit.TITLE_FONT,Enum.TextXAlignment.Center);self.stampTitle.ZIndex=45
	self.stampLine=kit.text(stamp,"",UDim2.fromOffset(16,66),UDim2.new(1,-32,0,50),44,M.ink,kit.TITLE_FONT,Enum.TextXAlignment.Center);self.stampLine.ZIndex=45
	self.stampSub=kit.text(stamp,"",UDim2.fromOffset(16,118),UDim2.new(1,-32,0,40),22,M.brown or M.ink,kit.STRONG_FONT or kit.BODY_FONT,Enum.TextXAlignment.Center);self.stampSub.ZIndex=45
	self.stamp=stamp
	-- the crosshair and THROW (a phone, a pad) while the targets run
	self.cross=kit.text(gui,"+",UDim2.new(.5,-20,.5,-24),UDim2.fromOffset(40,40),40,M.paper,kit.TITLE_FONT,Enum.TextXAlignment.Center)
	self.cross.Visible=false;self.cross.ZIndex=40
	kit.create("UIStroke",self.cross,{Color=M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	self.throwButton=kit.button(gui,"THROW",UDim2.new(1,-190,1,-250),UDim2.fromOffset(150,72),function() self:throw(nil) end,M.red)
	self.throwButton.Visible=false;self.throwButton.ZIndex=40;self.throwButton.TextColor3=M.paper
	return self
end

-- ------------------------------------------------------------------ the world
local function neon(parent,name,size,cf,color,transparency)
	local p=Instance.new("Part")
	p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.Neon;p.Transparency=transparency or 0
	p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Parent=parent
	return p
end
function View:folder()
	if self.world and self.world.Parent then return self.world end
	local f=Instance.new("Folder");f.Name="NinjaSoloView";f.Parent=workspace
	self.world=f
	return f
end
-- A ring of the race: a column of light, a halo of sixteen strokes on the
-- roof, its number. `dim`: the one after the next.
function View:buildRing(i,dim)
	local at=Solo.ring(i)
	local r=Solo.Race.rings[i]
	local floor=Solo.world(r[1],r[2],r[3])
	local m=Instance.new("Model");m.Name="Ring"..i;m.Parent=self:folder()
	local alpha=if dim then .78 else .35
	neon(m,"Column",Vector3.new(90,1.6,1.6),CFrame.new(floor+Vector3.new(0,45,0))*CFrame.Angles(0,0,math.pi/2),GLOW,alpha+.15)
	local radius=Solo.Race.radius*S*.8
	local strokes={}
	for k=1,16 do
		local a=k/16*math.pi*2
		local p=neon(m,"Halo",Vector3.new(2.2,.3,.5),CFrame.new(at+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius))*CFrame.Angles(0,-a+math.pi/2,0),GLOW,alpha)
		table.insert(strokes,{part=p,a=a})
	end
	local holder=neon(m,"Number",Vector3.new(.2,.2,.2),CFrame.new(at+Vector3.new(0,6,0)),GLOW,1)
	local bill=Instance.new("BillboardGui");bill.Size=UDim2.fromOffset(90,90);bill.AlwaysOnTop=not dim;bill.LightInfluence=0;bill.MaxDistance=900
	bill.Parent=holder
	local label=self.kit.text(bill,tostring(i),UDim2.fromScale(0,0),UDim2.fromScale(1,1),if dim then 34 else 56,self.M.paper,self.kit.TITLE_FONT,Enum.TextXAlignment.Center)
	label.TextTransparency=if dim then .4 else 0
	self.kit.create("UIStroke",label,{Color=self.M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	return {model=m,strokes=strokes,at=at,radius=radius}
end
function View:showRings(next)
	local want={}
	if next and Solo.Race.rings[next] then want[next]=false end
	if next and Solo.Race.rings[next+1] then want[next+1]=true end
	for i,ring in self.rings do
		if want[i]==nil or ring.dim~=want[i] then pcall(function() ring.model:Destroy() end);self.rings[i]=nil end
	end
	for i,dim in want do
		if not self.rings[i] then local ring=self:buildRing(i,dim);ring.dim=dim;self.rings[i]=ring end
	end
end
-- The boards he hit, hidden for him only (the others still see them up).
function View:boards(up)
	local hub=workspace:FindFirstChild("NinjaDuelHub")
	local targets=hub and hub:FindFirstChild("KunaiTargets",true)
	if not targets then return end
	for i in Solo.Targets.boards do
		local down=up~=nil and string.sub(up,i,i)=="0"
		local board=targets:FindFirstChild("Target"..i)
		if board and self.hidden[i]~=down then
			self.hidden[i]=down
			for _,p in board:GetDescendants() do if p:IsA("BasePart") then p.LocalTransparencyModifier=if down then 1 else 0 end end
		end
	end
end

-- ------------------------------------------------------------------ the throw
function View:aim(screen)
	local camera=workspace.CurrentCamera
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not camera or not root then return nil end
	local ray=if screen then camera:ViewportPointToRay(screen.X,screen.Y) else camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
	local origin=root.Position+Vector3.new(0,1.5,0)
	-- the board the eye points at (the same test as the server's), else far along it
	local up={}
	local raw=Players.LocalPlayer:GetAttribute("NinjaSoloUp") or ""
	for i in Solo.Targets.boards do up[i]=string.sub(raw,i,i)~="0" end
	local i=Solo.hitBoard({up=up},ray.Origin,ray.Direction.Unit)
	local point=if i then Solo.board(i) else ray.Origin+ray.Direction.Unit*80
	return origin,(point-origin).Unit,i
end
function View:throw(screen)
	if Players.LocalPlayer:GetAttribute("NinjaSolo")~="targets" then return end
	local now=os.clock()
	if now-(self.lastThrow or 0)<Solo.Targets.gap then return end
	self.lastThrow=now
	local origin,direction=self:aim(screen)
	if not origin then return end
	self.send("SoloThrow",{toward=direction})
	-- the kunai seen flying (where the server's test will find it)
	pcall(function()
		local up={}
		local raw=Players.LocalPlayer:GetAttribute("NinjaSoloUp") or ""
		for k in Solo.Targets.boards do up[k]=string.sub(raw,k,k)~="0" end
		local _,hit,distance=Solo.hitBoard({up=up},origin,direction)
		local goal=hit or origin+direction*60
		local kunai=neon(self:folder(),"Kunai",Vector3.new(.25,.25,1.6),CFrame.lookAt(origin,goal),Color3.fromRGB(40,40,46),0)
		kunai.Material=Enum.Material.Metal
		local time=math.clamp((distance or 60)/140,.08,.45)
		TweenService:Create(kunai,TweenInfo.new(time,Enum.EasingStyle.Linear),{CFrame=CFrame.lookAt(goal,goal+direction)}):Play()
		game:GetService("Debris"):AddItem(kunai,time+(if hit then 1.2 else .05))
	end)
end

-- ------------------------------------------------------------------ the loop
function View:stampShow(lines)
	self.stampTitle.Text=lines.title;self.stampLine.Text=lines.line;self.stampSub.Text=lines.sub
	self.stampLine.Visible=lines.line~=""
	self.stamp.Visible=true
	self.stampUntil=os.clock()+4.5
end
function View:frame(dt)
	local me=Players.LocalPlayer
	local kind=me:GetAttribute("NinjaSolo")
	local walking=self.walking()
	local serverNow=workspace:GetServerTimeNow()
	local at=me:GetAttribute("NinjaSoloAt") or serverNow
	-- the end of something done: the stamp, once
	local serial=me:GetAttribute("NinjaSoloSerial")
	if self.serial==nil then self.serial=serial or 0 end
	if serial and serial~=self.serial then
		self.serial=serial
		self:stampShow(View.endLines(me:GetAttribute("NinjaSoloEnd"),me:GetAttribute("NinjaSoloTime"),me:GetAttribute("NinjaSoloBest"),me:GetAttribute("NinjaSoloGain"),me:GetAttribute("NinjaSoloNew")))
	end
	if self.stamp.Visible and os.clock()>(self.stampUntil or 0) then self.stamp.Visible=false end
	self.case.Visible=kind~=nil and walking
	local left=at-serverNow
	self.go.Visible=kind~=nil and walking and left>-.6
	if self.go.Visible then self.go.Text=if left>0 then tostring(math.ceil(left)) else "GO!" end
	if kind then
		self.clock.Text=Solo.clock(math.max(0,serverNow-at)*100)
		if kind=="race" then
			local next=me:GetAttribute("NinjaSoloNext") or 1
			self.what.Text="ROOFTOP RACE"
			self.count.Text=string.format("RING %d / %d",math.min(next,#Solo.Race.rings),#Solo.Race.rings)
			self:showRings(next)
		else
			local up=me:GetAttribute("NinjaSoloUp") or ""
			local _,hit=string.gsub(up,"0","")
			local misses=me:GetAttribute("NinjaSoloMisses") or 0
			self.what.Text="KUNAI TARGETS"
			self.count.Text=string.format("HIT %d / %d",hit,#Solo.Targets.boards)..(if misses>0 then string.format("   •   MISSED %d (+%d s)",misses,misses*Solo.Targets.miss) else "")
			self:showRings(nil)
		end
	else
		self:showRings(nil)
	end
	if kind~="race" then self:boards(if kind=="targets" then me:GetAttribute("NinjaSoloUp") else nil) end
	local throwing=kind=="targets" and walking
	self.cross.Visible=throwing and (UIS.MouseBehavior==Enum.MouseBehavior.LockCenter or UIS.TouchEnabled or UIS.GamepadEnabled)
	self.throwButton.Visible=throwing and UIS.TouchEnabled
	-- the halos turn
	self.spin=(self.spin or 0)+dt*.8
	for _,ring in self.rings do
		for _,s in ring.strokes do
			local a=s.a+self.spin
			s.part.CFrame=CFrame.new(ring.at+Vector3.new(math.cos(a)*ring.radius,math.sin(self.spin*3+s.a)*.4,math.sin(a)*ring.radius))*CFrame.Angles(0,-a+math.pi/2,0)
		end
	end
	self:extras(dt)
end
-- The board of the best times over the race's post, the challenger's line.
function View:extras(dt)
	self.slow=(self.slow or 0)-dt
	if self.slow>0 then return end
	self.slow=2
	local hub=workspace:FindFirstChild("NinjaDuelHub")
	if not hub then return end
	pcall(function()
		local post=hub:FindFirstChild("RooftopRace",true)
		local anchor=post and post:FindFirstChild("Anchor")
		if anchor and not self.board then
			local bill=Instance.new("BillboardGui");bill.Name="SoloBoard";bill.Size=UDim2.fromOffset(300,250);bill.StudsOffset=Vector3.new(0,16,0)
			bill.LightInfluence=0;bill.MaxDistance=160;bill.Parent=anchor
			local page=self.kit.frame(bill,UDim2.fromScale(0,0),UDim2.fromScale(1,1),self.M.paper,0)
			self.kit.create("UIStroke",page,{Color=self.M.ink,Thickness=4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
			self.kit.text(page,"ROOFTOP RACE",UDim2.fromOffset(10,6),UDim2.new(1,-20,0,34),30,self.M.red,self.kit.TITLE_FONT,Enum.TextXAlignment.Center)
			self.boardRows=self.kit.text(page,"",UDim2.fromOffset(14,44),UDim2.new(1,-28,1,-80),19,self.M.ink,self.kit.BODY_FONT,Enum.TextXAlignment.Left)
			self.boardRows.TextYAlignment=Enum.TextYAlignment.Top
			self.boardMine=self.kit.text(page,"",UDim2.new(0,14,1,-34),UDim2.new(1,-28,0,28),19,self.M.ink,self.kit.STRONG_FONT or self.kit.BODY_FONT,Enum.TextXAlignment.Center)
			self.board=bill
		end
		if self.boardRows then
			local lines={}
			local value=game:GetService("ReplicatedStorage"):FindFirstChild("NinjaDuelBoards")
			value=value and value:FindFirstChild("Rooftops")
			local data=value and game:GetService("HttpService"):JSONDecode(value.Value)
			for k,row in (data and data.rows) or {} do
				if k>6 then break end
				table.insert(lines,string.format("%d.  %s   %s",row.rank or k,string.sub(tostring(row.name or "?"),1,16),row.text or Solo.clock(row.value)))
			end
			self.boardRows.Text=if #lines>0 then table.concat(lines,"\n") else "No time yet: be the first!"
			local best=Players.LocalPlayer:GetAttribute("NinjaSoloBest")
			self.boardMine.Text=if best and Players.LocalPlayer:GetAttribute("NinjaSoloEnd")=="finish" then "YOUR BEST  "..Solo.clock(best) else "E AT THE POST: GO!"
		end
	end)
	-- the challenger's line over his head
	pcall(function()
		local masters=hub:FindFirstChild("Masters")
		for _,model in (masters and masters:GetChildren()) or {} do
			local line=model:GetAttribute("NinjaChallengeLine")
			if line and not self.bubbles[model] then
				local head=model:FindFirstChild("Head") or model.PrimaryPart
				if head then
					local bill=Instance.new("BillboardGui");bill.Size=UDim2.fromOffset(320,96);bill.StudsOffset=Vector3.new(0,4.5,0);bill.LightInfluence=0;bill.MaxDistance=120
					bill.Parent=head
					local page=self.kit.frame(bill,UDim2.fromScale(0,0),UDim2.new(1,0,1,-14),self.M.paper,0)
					self.kit.create("UIStroke",page,{Color=self.M.ink,Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
					self.kit.text(page,"« "..line.." »",UDim2.fromOffset(10,6),UDim2.new(1,-20,1,-12),20,self.M.ink,self.kit.VOICE_FONT or self.kit.BODY_FONT,Enum.TextXAlignment.Center)
					self.bubbles[model]=bill
				end
			end
		end
		for model in self.bubbles do if not model.Parent then self.bubbles[model]=nil end end
	end)
end

function View:start()
	PPS.PromptTriggered:Connect(function(prompt)
		if not self.walking() then return end
		local kind=prompt:GetAttribute("NinjaSolo")
		if kind=="race" then self.send("SoloRace",{}) elseif kind=="targets" then self.send("SoloTargets",{}) end
		local kit=prompt:GetAttribute("NinjaChallenge")
		if kit then self.send("SoloChallenge",{kit=kit}) end
	end)
	UIS.InputBegan:Connect(function(input,processed)
		if processed or Players.LocalPlayer:GetAttribute("NinjaSolo")~="targets" then return end
		if input.KeyCode==Enum.KeyCode.R or input.KeyCode==Enum.KeyCode.ButtonR2 then self:throw(nil)
		elseif input.UserInputType==Enum.UserInputType.MouseButton1 then self:throw(UIS:GetMouseLocation()) end
	end)
	RunService.RenderStepped:Connect(function(dt) pcall(self.frame,self,dt) end)
	return self
end

return View
