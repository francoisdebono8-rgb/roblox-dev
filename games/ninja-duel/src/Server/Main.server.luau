local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
Players.CharacterAutoLoads=false
-- (14/11) The game's light before any player joins: what a client receives
-- on joining is already the look it holds (Shared/Look).
pcall(function() require(Shared:WaitForChild("Look")).apply() end)
local remote=Instance.new("RemoteEvent"); remote.Name="Action"; remote.Parent=Shared
local Matches=require(script.Parent.Matches)
-- Blender-made costume meshes load in the background (Server/LookMeshes).
require(script.Parent.LookMeshes).preload()
require(script.Parent.ArenaMeshes).preload()
-- The select screen's fighters, built once with the duel's rig (Server/Portraits).
require(script.Parent.Portraits).start()
local matches=Matches.new(remote)
-- (DEC-038) Konoha: the village the player walks between duels, the masters
-- at home, the proctor's board of duels (Server/Hub). Built before the first
-- player's selection puts him at the gate.
if require(game:GetService("ReplicatedStorage").NinjaDuel.Config).Hub.Enabled==true then require(script.Parent.Hub).start() end
-- (DEC-037) The masters' path: profiles loaded, saved, kits learned and
-- bought (off while Config.Progression.Enabled is false).
require(script.Parent.Progression).start(function(player) matches:kitsLoaded(player) end)
-- (19/11, vague 2 DEV 5) the week's exam: titles, the week closed, the cliff
if require(game:GetService("ReplicatedStorage").NinjaDuel.Config).Exam.Enabled==true then require(script.Parent.WeeklyExam).begin() end
-- (20/11, DEC-043) the leaderboards: every board's top 10, every minute
require(script.Parent.Leaderboards).begin()
-- (04/11) Players online and challenges between them, across the servers.
-- (23/11, step 5, DEC-049) the REPORT button of the test place
pcall(function() require(script.Parent.Reports).start() end)
-- (23/11, step 5) the test place's record of each visit (tools/testread)
pcall(function() require(script.Parent.TestLog).start(matches) end)
local lobby=require(script.Parent.Lobby).new(matches)
matches.lobby=lobby
remote.OnServerEvent:Connect(function(player,payload) matches:request(player,payload) end)
Players.PlayerAdded:Connect(function(player) matches:selection(player);lobby:track(player) end)
Players.PlayerRemoving:Connect(function(player) lobby:untrack(player);matches:remove(player) end)
for _,player in Players:GetPlayers() do matches:selection(player);lobby:track(player) end
local nextLobby=0
RunService.Heartbeat:Connect(function(dt)
	matches:update(dt,workspace:GetServerTimeNow())
	local t=os.clock()
	if t>=nextLobby then nextLobby=t+.25;lobby:update() end
end)
-- Studio-only playtest hooks (no effect in a live server).
if RunService:IsStudio() and workspace:GetAttribute("NinjaDuelDebug")==true then
	require(script.Parent.DevHooks).install(matches)
end
-- Available only in the separately built native QA place; never in the playable artifact.
if RunService:IsStudio() and workspace:GetAttribute("NinjaDuelQA")==true then
	task.spawn(function() require(script.Parent.NativeQA).run(matches) end)
end
-- The build's identity (issue #45): the same RUNTIME and commit in the GAME,
-- DEV, QA and FILM places of one commit; BUILD differs by profile.
do
	local function stamp(name) local value=Shared:FindFirstChild(name) return value and value.Value or "?" end
	print("[NinjaDuel] BUILD "..Shared.BuildFingerprint.Value.." | RUNTIME "..stamp("RuntimeFingerprint").." | "..stamp("BuildProfile").." @ "..stamp("SourceCommit"))
end
print("[NinjaDuel] Ready — select a fighter and start the duel")
