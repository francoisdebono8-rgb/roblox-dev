-- The players met in Konoha (14/11, « passons à la suite de la bêta »): the
-- village is where the server's players walk between duels, so a duel between
-- two of them starts there. Over every other player's avatar in the village:
-- his name, the kit he fights with and its mastery (Server/Hub.badge); walk
-- up to him and hold E (pad X): CHALLENGE. The challenge is the lobby's
-- (Server/Lobby: the invitation card, accept or decline, the online pick);
-- the server checks the kit is learned. A player who does not want to be
-- disturbed (the lobby's DO NOT DISTURB) shows it and has no prompt.
-- Presentation and asking only: every decision is the server's.
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Fighters=require(Shared.Fighters)
local Text=require(Shared.Text)

local HubPlayers={}
HubPlayers.__index=HubPlayers
-- Studs: how close for the prompt, how far the name tag shows.
HubPlayers.REACH=10
HubPlayers.SEEN=80
-- Seconds between two challenges to the same player from this client (the
-- server has its own guards: Lobby Tune.Gap, MaxOut).
HubPlayers.AGAIN=3

local function nameOf(id) local def=Fighters[id] return Text.upper(def and def.Name or id) end

-- The line under a player's name: his kit and its mastery, or do not disturb.
function HubPlayers.line(player)
	if player:GetAttribute("NinjaDnd") then return "DO NOT DISTURB",true end
	local kit=player:GetAttribute("NinjaKit")
	if type(kit)~="string" then return "",false end
	local mastery=player:GetAttribute("NinjaMastery")
	-- (20/11, DEC-043) his rank on the ladder first (the DESIGN's emblem will
	-- stand beside it)
	local rank=player:GetAttribute("NinjaRank")
	local prefix=if type(rank)=="string" then rank.."  •  " else ""
	return string.format("%s%s  •  MASTERY %d",prefix,nameOf(kit),if type(mastery)=="number" then mastery else 0),false
end

-- `kit`: UI.kit; `send(payload)`: the lobby remote (LobbyPanel:send);
-- `active()`: whether this player walks the village now. `players` and
-- `holder` are for the suites (Players, the PlayerGui).
function HubPlayers.new(kit,send,active,players,holder)
	local self=setmetatable({kit=kit,send=send,active=active or function() return true end,players=players or Players,
		holder=holder,tags={},asked={}},HubPlayers)
	return self
end

-- Starts the refresh and listens to the prompts (in the game).
function HubPlayers:start()
	local me=self.players.LocalPlayer
	self.holder=self.holder or (me and me:WaitForChild("PlayerGui"))
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt) self:triggered(prompt) end)
	task.spawn(function()
		while true do
			pcall(function() self:refresh() end)
			task.wait(.5)
		end
	end)
	return self
end

function HubPlayers:untag(other)
	local t=self.tags[other]
	if not t then return end
	self.tags[other]=nil
	if t.gui then t.gui:Destroy() end
	if t.prompt then t.prompt:Destroy() end
end

-- A name tag and a CHALLENGE prompt on one player's avatar in the village.
function HubPlayers:tag(other,character)
	local K=self.kit
	local P=K.palette
	local head=character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	local root=character:FindFirstChild("HumanoidRootPart") or head
	if not head or not root then return nil end
	local gui=Instance.new("BillboardGui")
	gui.Name="NinjaTag_"..other.Name
	gui.Adornee=head;gui.Size=UDim2.fromOffset(260,78);gui.StudsOffset=Vector3.new(0,3,0)
	gui.MaxDistance=HubPlayers.SEEN;gui.LightInfluence=0;gui.AlwaysOnTop=false;gui.ResetOnSpawn=false
	-- (19/11, vague 2 DEV 5) his title of the week's exam (NinjaTitle, Server/
	-- WeeklyExam): EXAM PASSED, TOP 3 OF THE WEEK
	local title=K.text(gui,"",UDim2.fromOffset(0,0),UDim2.fromOffset(260,20),15,P.gold,K.TITLE_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",title,{Color=P.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	local name=K.text(gui,Text.upper(other.DisplayName or other.Name),UDim2.fromOffset(0,20),UDim2.fromOffset(260,32),26,P.paper,K.TITLE_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",name,{Color=P.ink,Thickness=2.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	local line=K.text(gui,"",UDim2.fromOffset(0,52),UDim2.fromOffset(260,22),15,P.gold,K.BODY_FONT,Enum.TextXAlignment.Center)
	K.create("UIStroke",line,{Color=P.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual})
	gui.Parent=self.holder
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="NinjaChallenge";prompt.ActionText="CHALLENGE";prompt.ObjectText=Text.upper(other.DisplayName or other.Name)
	prompt.HoldDuration=.4;prompt.MaxActivationDistance=HubPlayers.REACH;prompt.RequiresLineOfSight=false
	prompt:SetAttribute("NinjaChallenge",other.UserId)
	prompt.Parent=root
	local t={character=character,gui=gui,prompt=prompt,line=line,title=title}
	self.tags[other]=t
	return t
end

-- Every half second: a tag on each other player walking the village, none
-- on the others; the lines follow their kit and do-not-disturb.
function HubPlayers:refresh()
	local me=self.players.LocalPlayer
	local active=self.active()
	local seen={}
	for _,other in self.players:GetPlayers() do
		if other==me then continue end
		local character=other.Character
		if character and character.Parent and character:GetAttribute("NinjaHubBody") then
			seen[other]=true
			local t=self.tags[other]
			if t and t.character~=character then self:untag(other);t=nil end
			t=t or self:tag(other,character)
			if t then
				local text,dnd=HubPlayers.line(other)
				t.line.Text=text
				t.line.TextColor3=if dnd then self.kit.palette.muted else self.kit.palette.gold
				local title=other:GetAttribute("NinjaTitle")
				t.title.Text=if type(title)=="string" then Text.upper(title) else ""
				t.prompt.Enabled=active and not dnd
				t.gui.Enabled=active
			end
		end
	end
	for other in table.clone(self.tags) do if not seen[other] then self:untag(other) end end
end

-- E held at a player: the lobby's challenge, with the kit this player chose.
function HubPlayers:triggered(prompt)
	local id=prompt:GetAttribute("NinjaChallenge")
	if type(id)~="number" or not self.active() then return false end
	local now=os.clock()
	if now-(self.asked[id] or -math.huge)<HubPlayers.AGAIN then return false end
	self.asked[id]=now
	local me=self.players.LocalPlayer
	local kit=me and me:GetAttribute("NinjaKit")
	self.send({op="challenge",to=id,fighter=if type(kit)=="string" then kit else nil})
	return true
end

return HubPlayers
