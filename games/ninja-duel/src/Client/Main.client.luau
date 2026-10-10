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
local mouse=player:GetMouse()
local function send(action,extra)
	local payload={action=action,epoch=current.epoch}
	if current.phase=="Duel" and action~="Move" then payload.clientTime=workspace:GetServerTimeNow() end
	if action=="Move" then payload.direction=extra; payload.locked=camera.locked; payload.sprint=input and input.sprinting or false
	elseif type(extra)=="table" then for k,v in extra do payload[k]=v end
	elseif action=="Tool" or string.match(action,"^Technique") then
		local gamepad=game:GetService("UserInputService"):GetLastInputType().Name:match("Gamepad")~=nil
		local hit=if gamepad and current.bot then current.bot.position else mouse.Hit.Position
		if gamepad and action=="Technique1" and current.human and current.human.fighterId=="Flashstep" then hit-=Vector3.new(0,2.8,0) end
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (hit-root.Position).Magnitude<=140 then payload.aim=hit end
	end
	remote:FireServer(payload)
end
ui=UI.new(player:WaitForChild("PlayerGui"),send)
input=Input.new(send,function() return current end,function() camera.locked=not camera.locked;send("Move",input:direction(workspace.CurrentCamera)) end,camera)
-- Disable the default movement controller; server receives finite normalized intent.
local playerModule=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
require(playerModule):GetControls():Disable()
remote.OnClientEvent:Connect(function(data)
	if data.epoch<(current.epoch or 0) then return end
	if data.epoch~=current.epoch or data.phase~=current.phase then input:reset() end
	if data.epoch~=current.epoch then camera.locked=true end
	current=data; presentation.receivedAt=os.clock(); ui:render(data)
end)
local nextMove=0
RunService.RenderStepped:Connect(function(dt)
	camera:update(current,dt)
	presentation:update(current,dt)
	if current.phase=="Duel" and os.clock()>=nextMove then
		nextMove=os.clock()+0.08; send("Move",input:direction(workspace.CurrentCamera))
	end
end)
send("Ready")
print("[NinjaDuel] Client ready")
