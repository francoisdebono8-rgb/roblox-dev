-- The Ōtsutsuki in Konoha (26/11, passe 3, STORY-001, DEC-055). He waits on
-- the exam hall's dais, every server, for whoever comes: his prompt (FACE THE
-- ŌTSUTSUKI) or a blow on him (Server/HubFight) asks for the final
-- (Matches:finalFight). It is his only when his chapter says so (Shared/Story:
-- chapter 4, and each week after he won it); before, the Ōtsutsuki tells him
-- what is still missing, to him alone (HubFight.say).
-- His body is the stand-in kit's rig (Story.BOSS.kit) marked NinjaBoss: the
-- ANIMATEUR's model of him dresses it, on the duel's body as here.
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").NinjaDuel
local Story=require(Shared.Story)
local HubMap=require(Shared.HubMap)

local StoryPlay={}
StoryPlay.matches=nil
StoryPlay.model=nil
-- How near he must stand to face him (studs, flat).
StoryPlay.REACH=22
-- His answer while the final is not open, by what is missing.
StoryPlay.Words={
	forest="Out of the woods first. Then we'll see.",
	inspiration="Choose who you'll copy. Then come back.",
	challenge="%d seals of eight. Go get the rest.",
	exam="Eight seals. Now win my exam.",
	free="You beat me this week. Next week, I won't hold back.",
	taken="Someone is fighting me. Wait your turn.",
	["no kit"]="Choose your kit first.",
}

-- (pure) What the Ōtsutsuki says to a walker whose story is `view` when the
-- final is refused for `why` (Matches:finalFight's), or nil (nothing to say).
function StoryPlay.word(view,why)
	if why=="busy" or why=="start" then return nil end
	if why=="taken" or why=="no kit" then return StoryPlay.Words[why] end
	local kind=view and view.next and view.next.kind
	local w=StoryPlay.Words[kind or ""]
	if not w then return nil end
	if kind=="challenge" then return string.format(w,view.seals or 0) end
	return w
end

local function root(player)
	local ok,Hub=pcall(function() return require(script.Parent.Hub) end)
	local body=ok and Hub.bodies and Hub.bodies[player]
	local character=body and body.character
	return character and character:FindFirstChild("HumanoidRootPart")
end
local function where() return HubMap.Origin+(Story.spot(HubMap.Scale)) end

-- He faces the Ōtsutsuki (his prompt, a blow on him): the final, or a word.
function StoryPlay.face(player)
	local m=StoryPlay.matches
	if not m then return false end
	local r=root(player)
	if not r then return false end
	local at=where()
	if (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(at.X,0,at.Z)).Magnitude>StoryPlay.REACH then return false end
	local ok,why=m:finalFight(player)
	if ok then return true end
	local Progression=require(script.Parent.Progression)
	local text=StoryPlay.word(Progression.story(player),why)
	if text then pcall(function() require(script.Parent.HubFight).say(player,at+Vector3.new(0,4,0),Story.BOSS.name,text) end) end
	return false,why
end

-- His body on the dais, with his prompt.
function StoryPlay.show()
	local Hub=require(script.Parent.Hub)
	local holder=Hub.folder and Hub.folder:FindFirstChild("Masters")
	if not holder then return nil end
	local World=require(script.Parent.World)
	local B=Story.BOSS
	local def=require(Shared.Fighters)[B.kit]
	if not def then return nil end
	local at=where()
	local _,faceRel=Story.spot(HubMap.Scale)
	local face=HubMap.Origin+faceRel
	local cf=CFrame.lookAt(at+Vector3.new(0,3,0),Vector3.new(face.X,at.Y+3,face.Z))
	local model,_,rootPart=World.rig(holder,def,cf,"Otsutsuki")
	rootPart.Anchored=true
	model:SetAttribute("NinjaBoss","Otsutsuki")
	local prompt=Instance.new("ProximityPrompt")
	prompt.Name="Talk";prompt.ActionText="FACE THE ŌTSUTSUKI";prompt.ObjectText="THE FINAL  •  "..B.duel.place
	prompt.HoldDuration=0;prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false
	prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	prompt.Style=Enum.ProximityPromptStyle.Default
	prompt:SetAttribute("NinjaBoss","Otsutsuki")
	prompt.Parent=rootPart
	prompt.Triggered:Connect(function(player) pcall(StoryPlay.face,player) end)
	StoryPlay.model=model
	StoryPlay.holder=holder
	return model
end
-- While his final is fought, the one waiting steps out (one Ōtsutsuki on
-- screen); back when the hall is free.
function StoryPlay.step()
	local m,model=StoryPlay.matches,StoryPlay.model
	if not (m and model and StoryPlay.holder) then return end
	local busy=not m:siteFree(Story.BOSS.duel.key)
	if busy and model.Parent then model.Parent=nil
	elseif not busy and model.Parent==nil and StoryPlay.holder.Parent then model.Parent=StoryPlay.holder end
end

function StoryPlay.start(matches)
	StoryPlay.matches=matches
	task.spawn(function()
		-- he stands there once the village is built, and again if it is rebuilt
		while true do
			local okHub,Hub=pcall(function() return require(script.Parent.Hub) end)
			local gone=not StoryPlay.model or not (StoryPlay.holder and StoryPlay.holder.Parent)
			if okHub and Hub.built and gone then pcall(StoryPlay.show) end
			pcall(StoryPlay.step)
			task.wait(1)
		end
	end)
	-- his chapter on every player already there (Progression marks the others)
	for _,player in Players:GetPlayers() do pcall(function() require(script.Parent.Progression).storyMark(player) end) end
end

return StoryPlay
