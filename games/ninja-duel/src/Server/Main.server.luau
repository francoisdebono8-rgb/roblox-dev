local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
Players.CharacterAutoLoads=false
local remote=Instance.new("RemoteEvent"); remote.Name="Action"; remote.Parent=Shared
local Matches=require(script.Parent.Matches)
local matches=Matches.new(remote)
remote.OnServerEvent:Connect(function(player,payload) matches:request(player,payload) end)
Players.PlayerAdded:Connect(function(player) matches:selection(player) end)
Players.PlayerRemoving:Connect(function(player) matches:remove(player) end)
for _,player in Players:GetPlayers() do matches:selection(player) end
RunService.Heartbeat:Connect(function(dt) matches:update(dt,workspace:GetServerTimeNow()) end)
-- Available only in the separately built native QA place; never in the playable artifact.
if RunService:IsStudio() and workspace:GetAttribute("NinjaDuelQA")==true then
	task.spawn(function() require(script.Parent.NativeQA).run(matches) end)
end
print("[NinjaDuel] Ready — select a fighter and start the duel")
