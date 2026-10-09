local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local shared=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
local remote=shared:WaitForChild("Action")
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health,false); game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false); game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end)
local UI=require(script.Parent.UI)
local Input=require(script.Parent.Input)
local Camera=require(script.Parent.Camera)
local camera=Camera.new(); local current={phase="Selection",epoch=0}; local ui; local input
local mouse=player:GetMouse()
local function send(action,extra)
	local payload={action=action,epoch=current.epoch}
	if action=="Move" then payload.direction=extra; payload.locked=camera.locked; payload.sprint=input and input.sprinting or false
	elseif type(extra)=="table" then for k,v in extra do payload[k]=v end
	elseif string.match(action,"^Technique") then
		local hit=mouse.Hit.Position
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (hit-root.Position).Magnitude<=140 then payload.aim=hit end
	end
	remote:FireServer(payload)
end
ui=UI.new(player:WaitForChild("PlayerGui"),send)
input=Input.new(send,function() return current end,function() camera.locked=not camera.locked end)
-- Disable the default movement controller; server receives finite normalized intent.
local playerModule=player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
require(playerModule):GetControls():Disable()
remote.OnClientEvent:Connect(function(data)
	if data.epoch<(current.epoch or 0) then return end
	if data.epoch~=current.epoch or data.phase~=current.phase then table.clear(input.keys) end
	current=data; ui:render(data)
end)
local nextMove=0
RunService.RenderStepped:Connect(function(dt)
	camera:update(current,dt)
	if current.phase=="Duel" and os.clock()>=nextMove then
		nextMove=os.clock()+0.08; send("Move",input:direction(workspace.CurrentCamera))
	end
end)
send("Ready")
print("[NinjaDuel] Client ready")
