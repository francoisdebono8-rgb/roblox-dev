local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local shared=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
local remote=shared:WaitForChild("Action")
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health,false); game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false); game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end)
local UI=require(script.Parent.UI)
local Input=require(script.Parent.Input)
local Camera=require(script.Parent.Camera)
local Presentation=require(script.Parent.Presentation)
local presentation=Presentation.new()
local camera=Camera.new(); local current={phase="Selection",epoch=0}; local ui; local input
camera.presentation=presentation
local mouse=player:GetMouse()
local function send(action,extra)
	local payload={action=action,epoch=current.epoch}
	if current.phase=="Duel" and action~="Move" then
  payload.clientTime=workspace:GetServerTimeNow()
  -- Sample intent at the press, not at the previous 80 ms movement tick.
  if input then payload.direction=input:direction(workspace.CurrentCamera);payload.sprint=input.sprinting end
 end
	if action=="Move" then payload.direction=extra; payload.locked=camera.locked; payload.sprint=input and input.sprinting or false
	elseif type(extra)=="table" then for k,v in extra do payload[k]=v end
	elseif action=="Tool" or string.match(action,"^Technique") then
		local gamepad=input and input.pad
		local hit=if gamepad and current.bot then current.bot.position else mouse.Hit.Position
		if gamepad and action=="Technique1" and current.human and current.human.fighterId=="Flashstep" then hit-=Vector3.new(0,2.8,0) end
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (hit-root.Position).Magnitude<=140 then payload.aim=hit end
	end
	remote:FireServer(payload)
end
ui=UI.new(player:WaitForChild("PlayerGui"),send)
-- Debug/QA places only: the Studio dev panel (F6, DevClient). While it is open
-- Input sees a non-Duel state, so no combat binding fires behind the panel.
local dev
input=Input.new(send,function() return if dev and dev.panelOpen then dev.blocked else current end,function() camera:setLocked(not camera.locked);send("Move",input:direction(workspace.CurrentCamera)) end,camera)
-- Disable the default movement controller; server receives finite normalized intent.
local playerModule=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
require(playerModule):GetControls():Disable()
remote.OnClientEvent:Connect(function(data)
	if data.epoch<(current.epoch or 0) then return end
	if data.epoch~=current.epoch or data.phase~=current.phase then input:reset() end
	if data.epoch~=current.epoch then camera.locked=true end
	data.gamepad=input.pad
	current=data; presentation.receivedAt=os.clock(); presentation:receive(data); ui:render(data)
end)
local nextMove=0
RunService:BindToRenderStep("NinjaDuelCamera",Enum.RenderPriority.Camera.Value,function(dt)
	-- Last moment before the frame is drawn: the replicated roots have their
	-- final positions for this frame, so the smoothed bodies and the camera agree.
	local visual=presentation:frameData(current)
 presentation:smoothStep(visual,dt)
 presentation:update(visual,dt)
 presentation:flushImpacts(visual,camera)
 camera:update(visual,dt)
	if current.phase=="Duel" and os.clock()>=nextMove then
		nextMove=os.clock()+0.08; send("Move",input:direction(workspace.CurrentCamera))
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
