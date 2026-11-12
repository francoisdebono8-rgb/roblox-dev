-- Server Authority trial, server side: one input context per player (under
-- the Player, as Server Authority requires), then the shared simulation.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local SATrial=require(ReplicatedStorage:WaitForChild("SATrial"))

local template=SATrial.makeContext()
local function give(player:Player)
	if player:FindFirstChild(SATrial.ContextName) then return end
	template:Clone().Parent=player
end
Players.PlayerAdded:Connect(give)
for _,player in Players:GetPlayers() do give(player) end
SATrial.Initialize()
print("[SATrial] server ready, AuthorityMode="..tostring(workspace.AuthorityMode))
