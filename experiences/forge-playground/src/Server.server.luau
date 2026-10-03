local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Session = require(ServerStorage.Playground.Session)
local Protocol = require(ServerStorage.Playground.Protocol)
local sessions, buckets, slots, connections = {}, {}, {}, {}
local root = Instance.new("Folder")
root.Name, root.Parent = "ForgePlayground", workspace

local function added(player)
	if sessions[player] then return end
	local slot = 1
	while slots[slot] do slot += 1 end
	-- Bounded allocation even if a later place configuration raises MaxPlayers.
	if slot > 6 then player:Kick("This workshop is full. Please join another server."); return end
	slots[slot] = player
	local session = Session.new(root, slot)
	sessions[player], buckets[player] = session, { tokens = 4, time = os.clock() }
	session.slot = slot
	local function spawn(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if hrp and sessions[player] == session and player.Character == character then character:PivotTo(session.world.spawn) end
	end
	connections[player] = player.CharacterAdded:Connect(spawn)
	if player.Character then task.spawn(spawn, player.Character) end
end

Players.PlayerAdded:Connect(added)
for _, player in ipairs(Players:GetPlayers()) do added(player) end
Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then slots[session.slot] = nil; session:destroy() end
	if connections[player] then connections[player]:Disconnect() end
	sessions[player], buckets[player], connections[player] = nil, nil, nil
end)

ReplicatedStorage.ForgePlayground.Request.OnServerInvoke = function(player, action, id, options, index)
	local session, bucket = sessions[player], buckets[player]
	if not session then return { ok = false, message = "Workshop is loading. Try again." } end
	if not Protocol.allow(bucket, os.clock()) then return { ok = false, message = "A little slower, please." } end
	if not Protocol.validate(action, id, options, index) then return { ok = false, message = "Invalid request." } end
	if action ~= "visit" and session.current ~= id then return { ok = false, message = "Select this station first." } end
	local ok, response = pcall(function()
		if action == "visit" then
			local character = player.Character
			if character then character:PivotTo(CFrame.new(session.world.stations[id].center + Vector3.new(0, 4, 24))) end
		end
		return session:handle(action, id, options, index)
	end)
	if not ok then
		warn("[ForgePlayground] Request failed: " .. tostring(response))
		return { ok = false, message = require(ServerStorage.Playground.Visuals).message(response) }
	end
	return response
end
