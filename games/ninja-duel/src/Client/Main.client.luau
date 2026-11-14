local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local shared=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
local remote=shared:WaitForChild("Action")
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health,false); game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false); game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end)
-- (Audit B01) Key names as printed on this keyboard (AZERTY: ZQSD to move,
-- A to dodge), before any text that names a key is built.
pcall(function()
	local UIS=game:GetService("UserInputService")
	require(shared:WaitForChild("Controls")).useLayout(function(code) return UIS:GetStringForKeyCode(code) end)
end)
local UI=require(script.Parent.UI)
local Input=require(script.Parent.Input)
local TouchControls=require(script.Parent.TouchControls)
local Camera=require(script.Parent.Camera)
local Presentation=require(script.Parent.Presentation)
local presentation=Presentation.new()
local camera=Camera.new(); local current={phase="Selection",epoch=0}; local ui; local input
camera.presentation=presentation
local mouse=player:GetMouse()
-- (Debug places) Flight recorder, client half: every packet sent, the
-- presses the client itself let go of (Input.dropped) and slow frames, kept
-- on the player as the attribute NdFlightClient (JSON, refreshed each second).
local flight=nil
if workspace:GetAttribute("NinjaDuelDebug")==true then
	flight={sent={},frames={},started=os.clock()}
	Input.dropped={}
	local HttpService=game:GetService("HttpService")
	local worst,count,sum,since=0,0,0,os.clock()
	RunService.Heartbeat:Connect(function(dt)
		worst=math.max(worst,dt);count+=1;sum+=dt
		local now=os.clock()
		if now-since>=1 then
			table.insert(flight.frames,{t=math.floor((now-flight.started)*10)/10,fps=math.floor(count/(now-since)),worst=math.floor(worst*1000)})
			while #flight.frames>90 do table.remove(flight.frames,1) end
			worst,count,sum,since=0,0,0,now
			local dropped={}
			for _,d in Input.dropped do table.insert(dropped,{t=math.floor((d.t-flight.started)*100)/100,name=d.name,why=d.why}) end
			pcall(function() player:SetAttribute("NdFlightClient",HttpService:JSONEncode({sent=flight.sent,frames=flight.frames,dropped=dropped,now=math.floor((now-flight.started)*100)/100})) end)
		end
	end)
end
local function send(action,extra)
	if flight and action~="Move" then
		table.insert(flight.sent,{t=math.floor((os.clock()-flight.started)*100)/100,a=action,phase=current.phase})
		while #flight.sent>120 do table.remove(flight.sent,1) end
	end
	local payload={action=action,epoch=current.epoch}
	if current.phase=="Duel" and action~="Move" then
  payload.clientTime=workspace:GetServerTimeNow()
  -- Sample intent at the press, not at the previous 80 ms movement tick.
  if input then payload.direction=input:direction(workspace.CurrentCamera);payload.sprint=input.sprinting end
 end
	if action=="Move" then payload.direction=extra; payload.locked=camera.locked; payload.sprint=input and input.sprinting or false
		-- (DEC-031) Free with the mouse: the body faces where the player looks
		-- (shift lock). Free with the pad (user 03/11, his own play: strikes
		-- thrown at the air behind him): the body faces where it goes, and the
		-- blows turn to the opponent (Combat soft lock).
		-- (B1) only the player's own lens: not the round's intro, a K.O. or an
		-- ultimate's sequence (the body turned its back to follow the intro).
		if not camera.locked and not (input and (input.pad or input.touch)) and camera:steers(current) then
			local look=workspace.CurrentCamera.CFrame.LookVector*Vector3.new(1,0,1)
			if look.Magnitude>.05 then payload.look=look.Unit end
		elseif not camera.locked then payload.look=false end
	elseif type(extra)=="table" then for k,v in extra do payload[k]=v end
	-- (Audit 04/11) the seal jutsu aim too (Minato's trap goes where he points).
	elseif action=="Tool" or string.match(action,"^Technique") or string.match(action,"^Seal%d") then
		local gamepad=input and (input.pad or input.touch)
		mouse.TargetFilter=player.Character
		local hit=if gamepad and current.bot then current.bot.position else mouse.Hit.Position
		if gamepad and action=="Technique1" and current.human and current.human.fighterId=="Flashstep" then hit-=Vector3.new(0,2.8,0) end
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (hit-root.Position).Magnitude<=140 then payload.aim=hit end
	end
	remote:FireServer(payload)
	-- (Audit 04/11) watching a tournament match: the body is the AI's, no guess.
	if current.phase=="Duel" and not current.spectate and (action=="Attack" or action=="Heavy") then presentation:predictStrike(action,current) end
	if current.phase=="Duel" and not current.spectate and (action=="Dodge" or action=="Jump" or action=="PadJump") then presentation:predictMove(action,current) end
end
ui=UI.new(player:WaitForChild("PlayerGui"),send)
-- (04/11) Players online and challenges between them (Server/Lobby).
local lobbyPanel=nil
pcall(function() lobbyPanel=require(script.Parent.LobbyPanel).new(ui,shared:WaitForChild("Lobby",20),UI.kit) end)
-- (04/11) The Prodigy Tournament: bracket, spectator banner, champion (Server/Tournament).
local cupScreen=require(script.Parent.CupScreen).new(ui,send,UI.kit)
-- (B1 lot 3) the controls sheet's EFFECTS switch also calms the lens.
ui.onEffects=function(low) camera.calm=low end
-- The roster's fighters stand in a 3D set the menu camera films (Client/MenuStage).
if ui.menuStage then camera.menuShot=function() return ui.menuStage:shot() end end
-- Debug/QA places only: the Studio dev panel (F6, DevClient). While it is open
-- Input sees a non-Duel state, so no combat binding fires behind the panel.
local dev
input=Input.new(send,function() return if dev and dev.panelOpen then dev.blocked else current end,function() camera:setLocked(not camera.locked);send("Move",input:direction(workspace.CurrentCamera)) end,camera)
-- (Audit 04/11) phones and tablets: their own controls (none existed).
local touch=nil
pcall(function()
	touch=TouchControls.new(input,send,function() return current end,function() camera:setLocked(not camera.locked);send("Move",input:direction(workspace.CurrentCamera)) end,camera)
end)
-- Disable the default movement controller; server receives finite normalized intent.
local playerModule=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
local controlModule=require(playerModule):GetControls()
controlModule:Disable()
-- (DEC-038) Konoha between duels: the walk, the masters, the proctor's board.
local hubClient=nil
pcall(function()
	local HubClient=require(script.Parent.HubClient)
	if HubClient.enabled() then
		hubClient=HubClient.new(ui,camera,send,controlModule)
		ui.onBoardClose=function() hubClient:closeBoard() end
	end
end)
remote.OnClientEvent:Connect(function(data)
	if data.epoch<(current.epoch or 0) then return end
	if data.epoch~=current.epoch or data.phase~=current.phase then input:resync() end
	-- (05/11, user on the pad) The lock is the player's choice: it used to drop
	-- back to free at every round (each round is a new epoch), and the lens
	-- swapped rigs under him until he pressed R3 again.
	data.gamepad=input.pad
	data.touch=input.touch==true
	data.sealPage=input:sealPage()
	-- (05/11) R1 held on a pad: the jutsu row lights up (what □ △ ○ × will cast).
	data.jutsuPage=input.pad==true and input.modifier==true and not data.sealPage
	-- (05/11) the chakra button held alone (pad L2, keyboard Z): the row names
	-- what it infuses (UI, Shared/ChakraMoves).
	data.chakraPage=if input.pad then input.chakraPad==true and not input.modifier else input.chakra==true and not input.sealKey
	current=data; presentation.receivedAt=os.clock(); presentation:impacts(data,camera)
	if hubClient then pcall(hubClient.render,hubClient,data) end
	-- (13/11, the shop) a thrown blade wears its thrower's look.
	pcall(function() require(script.Parent.Effects).setLooks(data) end)
	ui:render(data)
	if lobbyPanel then lobbyPanel:render(data) end
	cupScreen:render(data)
	if touch then touch:render(data) end
	if data.phase=="Duel" and data.serverNow then presentation:noteSnapshot(workspace:GetServerTimeNow()-data.serverNow) end
end)
local nextMove=0
local lastDir,lastSprint,lastLook=nil,nil,nil
local lastSentAt=0
RunService:BindToRenderStep("NinjaDuelCamera",Enum.RenderPriority.Camera.Value,function(dt)
	-- Last moment before the frame is drawn: the replicated roots have their
	-- final positions for this frame, so the smoothed bodies and the camera agree.
	presentation:smoothStep(current,dt)
	presentation:update(current,dt)
	camera.menuOpen=(dev~=nil and dev.panelOpen==true)
	mouse.TargetFilter=player.Character
	camera:update(current,dt)
	-- (DEC-030 Partie 1, responsiveness) The stick goes out the frame it
	-- changes, not on the next 80 ms tick (that alone cost up to 80 ms on every
	-- start, stop and turn); the tick stays as a heartbeat.
	if current.phase=="Duel" and current.spectate then
		presentation.inputDir=Vector3.zero;presentation.lead=nil;presentation.prediction=nil
	elseif current.phase=="Duel" then
		local dir=input:direction(workspace.CurrentCamera)
		presentation.inputDir=dir;presentation.inputSprint=input.sprinting
		presentation:observeStick(os.clock())
		local flatLook=workspace.CurrentCamera.CFrame.LookVector*Vector3.new(1,0,1)
		local turned=not camera.locked and camera:steers(current) and flatLook.Magnitude>.05 and (lastLook==nil or (flatLook.Unit-lastLook).Magnitude>.06)
		local changed=lastDir==nil or (dir-lastDir).Magnitude>.15 or input.sprinting~=lastSprint or turned
		if (changed and os.clock()-lastSentAt>=1/30) or os.clock()>=nextMove then
			lastSentAt=os.clock()
			nextMove=os.clock()+0.08;lastDir=dir;lastSprint=input.sprinting
			if flatLook.Magnitude>.05 then lastLook=flatLook.Unit end
			send("Move",dir)
		end
	end
end)
-- Studio-only diagnostics channel (created by the server's DevHooks).
if RunService:IsStudio() then
	task.spawn(function()
		local log=shared:WaitForChild("NinjaDuelDevLog",10) or game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuelDevLog",10)
		if not log then return end
		game:GetService("LogService").MessageOut:Connect(function(message,kind)
			if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then log:FireServer("log",string.sub(message,1,400)) end
		end)
		-- Smoothness probe: per rendered frame, the apparent acceleration of each
		-- fighter's head (what the eye follows) and root. A visual jump shows up
		-- as an acceleration spike.
		local probe={frames=0,headSpikes=0,rootSpikes=0,headMax=0,rootMax=0}
		local track={}
		local trace={}
		RunService:BindToRenderStep("NinjaDuelProbe",Enum.RenderPriority.Camera.Value+1,function(dt)
			if current.phase~="Duel" or dt<=0 then return end
			local folder=player.Character and player.Character.Parent
			for _,model in {player.Character,Presentation.opponent(current,folder)} do
				for _,partName in {"Head","HumanoidRootPart"} do
					local part=model and model:FindFirstChild(partName)
					if part then
						local key=model.Name..partName
						local st=track[key] or {}
						local p=part.Position
						if model==player.Character and #trace<90 and partName=="Head" then
							local vr=presentation:visualRoot("human")
							local root=model:FindFirstChild("HumanoidRootPart")
							local lt=model:FindFirstChild("LowerTorso")
							local joint=lt and lt:FindFirstChild("Root") or (root and root:FindFirstChild("Root"))
							table.insert(trace,string.format("H%.2f off%.2f lt%.2f tf%.2f",(p-(st.p or p)).Magnitude,vr and root and (vr-root.Position).Magnitude or -1,
								lt and root and (lt.Position-root.Position).Magnitude or -1,joint and joint.Transform.Position.Magnitude or -1))
						end
						if st.p then
							local v=(p-st.p)/dt
							if st.v then
								local acc=(v-st.v).Magnitude/dt
								local head=partName=="Head"
								if head then probe.frames+=1 end
								if acc>900 and v.Magnitude<150 then
									if head then probe.headSpikes+=1 else probe.rootSpikes+=1 end
								end
								if head then probe.headMax=math.max(probe.headMax,acc) else probe.rootMax=math.max(probe.rootMax,acc) end
							end
							st.v=v
						end
						st.p=p;track[key]=st
					end
				end
			end
		end)
		log.OnClientEvent:Connect(function(kind)
			if kind=="probe" then
				local out=table.clone(probe);out.trace=table.concat(trace," ")
				log:FireServer("info",{probe=out})
				probe={frames=0,headSpikes=0,rootSpikes=0,headMax=0,rootMax=0};trace={}
				return
			end
			if kind=="info" then
				local cam=workspace.CurrentCamera
				local gui={}
				local hud=player.PlayerGui:FindFirstChild("NinjaDuelHUD")
				if hud then
					for _,g in hud:GetDescendants() do
						if g:IsA("GuiObject") and #gui<40 and (g.Parent==hud or (g.Parent and g.Parent.Parent==hud)) then
							table.insert(gui,string.format("%s vis=%s pos=%s size=%s",g:GetFullName():sub(-40),tostring(g.Visible),tostring(g.AbsolutePosition),tostring(g.AbsoluteSize)))
						end
					end
				end
				log:FireServer("info",{presented=presentation.presented,camera=cam.CFrame,fov=cam.FieldOfView,focus=camera.focus,mode=camera.mode,boomAngle=camera.boomAngle,distance=camera.distance,viewport=cam.ViewportSize,gui=table.concat(gui," || ")})
			end
		end)
	end)
end
-- The normal build has no DevClient module, so this stays inert there.
local devModule=RunService:IsStudio() and script.Parent:FindFirstChild("DevClient")
if devModule then
	task.spawn(function()
		local ok,err=pcall(function()
			dev=require(devModule).install({player=player,input=input,presentation=presentation,camera=camera,ui=ui,state=function() return current end,send=send})
		end)
		if not ok then warn("[NinjaDuel] dev panel unavailable: "..tostring(err)) end
	end)
end
send("Ready")
print("[NinjaDuel] Client ready")
