-- His kit in the street, on the server (26/11, passe 3, DEC-055, HUB-002).
-- The rules are Shared/HubFight's. A walker's client asks for a move on the
-- remote HubAct (the move's name); granted, his character carries it
-- (NinjaAct, NinjaActSeq: every client poses it, Client/HubBody), and at its
-- contact the blow lands on what is in front of him:
--   another player   a challenge (Server/Lobby's invite), or the riposte that
--                    accepts the one he received: the 1v1 there
--   a rogue          his street fight (Server/Thugs)
--   a challenger     the inspiration's challenge (Server/SoloPlay)
--   the bandit       the forest's fight (Server/Forest)
--   the Ōtsutsuki    the final, when it is his (Server/StoryPlay)
--   the dummy        it takes the blow
--   the world        a crate or a stump cracks, then breaks (WorldReaction),
--                    put back a little later
-- Every landed blow is told to the clients near it (the remote HubImpact:
-- {at, kind, heavy}) for its flash and its sound.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage.NinjaDuel
local Rules=require(Shared.HubFight)

local HubFight={}
HubFight.last=setmetatable({},{__mode="k"})      -- player -> grants (Rules.grant)
HubFight.challenges={}                            -- userId -> {from=userId, at}
HubFight.cooldowns={}                             -- pairKey -> time
HubFight.matches=nil
HubFight.lastBreak=0
-- The clients this far from a blow hear and see it.
HubFight.NEAR=200

local impactRemote
local function tell(at,kind,heavy,extra)
	if not impactRemote then return end
	local payload={at=at,kind=kind,heavy=heavy==true}
	if extra then for k,v in extra do payload[k]=v end end
	for _,p in Players:GetPlayers() do
		local c=p.Character
		local r=c and c:FindFirstChild("HumanoidRootPart")
		if r and (r.Position-at).Magnitude<HubFight.NEAR then impactRemote:FireClient(p,payload) end
	end
end
HubFight.tell=tell
-- A word to one player alone (Server/StoryPlay: the Ōtsutsuki not open yet).
function HubFight.say(player,at,title,text)
	if not impactRemote or typeof(at)~="Vector3" then return end
	impactRemote:FireClient(player,{at=at,kind="say",title=title,text=text})
end

-- The village's own world memory (WorldReaction's combat context, without a
-- duel): what a blow breaks, its marks, put back after Rules.RESTORE.
local ctx=nil
local function context()
	if ctx then return ctx end
	local folder=workspace:FindFirstChild("NinjaHubWorld")
	if not folder then folder=Instance.new("Folder");folder.Name="NinjaHubWorld";folder.Parent=workspace end
	ctx={now=0,match={folder=folder}}
	function ctx:pushImpact(position,style,heavy,extra)
		tell(position,style or "worldbreak",heavy,{material=extra and extra.material})
	end
	function ctx:rayParams()
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
		local list={folder}
		for _,p in Players:GetPlayers() do if p.Character then table.insert(list,p.Character) end end
		params.FilterDescendantsInstances=list
		return params
	end
	return ctx
end
HubFight.context=context

-- Whether this player walks the village (his hub body, not a duel, not a menu
-- fight): the session in Selection and his character the hub's.
local function walking(player)
	local m=HubFight.matches
	local s=m and m.sessions and m.sessions[player]
	if not s or s.phase~="Selection" or s.finishing then return false end
	local Hub=require(script.Parent.Hub)
	local body=Hub.bodies and Hub.bodies[player]
	return body~=nil and body.character~=nil and body.character==player.Character
end
HubFight.walking=walking

-- The model a part belongs to (the first Model under workspace's folders).
local function modelOf(part)
	local m=part:FindFirstAncestorOfClass("Model")
	while m and m.Parent and m.Parent:IsA("Model") do m=m.Parent end
	return m
end

-- A player struck by another walker: a challenge, or the riposte.
function HubFight.strikePlayer(player,other,now)
	local m=HubFight.matches
	local lobby=m and m.lobby
	if not lobby or not walking(other) then return "busy" end
	if other:GetAttribute("NinjaDnd")==true or other:GetAttribute("NinjaIntro")~=nil then return "busy" end
	local verdict=Rules.answer(HubFight.challenges,HubFight.cooldowns,player.UserId,other.UserId,now)
	if verdict=="wait" then return verdict end
	local pa,pb=lobby.players[player.UserId],lobby.players[other.UserId]
	if not pa or not pb then return "busy" end
	if verdict=="accept" then
		HubFight.challenges[player.UserId]=nil
		HubFight.cooldowns[Rules.pairKey(player.UserId,other.UserId)]=now
		-- his invite from the other: answered yes (Lobby:answer -> accepted -> pairHere)
		local done=false
		for id,rec in lobby.incoming do
			if rec.to==player.UserId and rec.from==other.UserId then
				pcall(lobby.answer,lobby,pa,id,true,nil,lobby.svc.now())
				done=true
				break
			end
		end
		if not done then pcall(lobby.pairHere,lobby,pb,pa,pb.fighter,pa.fighter,true) end
		return "accept"
	end
	HubFight.challenges[other.UserId]={from=player.UserId,at=now}
	-- (quick: accepted, the duel starts there, without the pick)
	pcall(lobby.challenge,lobby,pa,other.UserId,nil,lobby.svc.now(),true)
	return "challenge"
end

-- (pure) The facing a client sent with his move (a flat unit vector), or nil.
function HubFight.facing(dir)
	if typeof(dir)~="Vector3" then return nil end
	local flat=Vector3.new(dir.X,0,dir.Z)
	local m=flat.Magnitude
	if m~=m or m<.5 or m>1.5 then return nil end
	return flat.Unit
end
-- A blow's contact: what is in front of him takes it. Returns what it met.
-- `dir`: the way he turned for it (his client turned his body at the press:
-- the turn may not have reached the server by the contact).
function HubFight.land(player,character,move,now,dir)
	local spec=Rules.Moves[move]
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not spec or not root or not character.Parent then return nil end
	local frame=if dir then CFrame.lookAt(root.Position,root.Position+dir) else root.CFrame
	local cf,size=Rules.box(frame,spec)
	local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={character,context().match.folder}
	local parts=workspace:GetPartBoundsInBox(cf,size,params)
	local heavy=spec.kind=="Heavy" or move=="Light3"
	-- the nearest thing first: a body before the world
	local best,bestD,bestModel=nil,math.huge,nil
	local worldPart,worldD=nil,math.huge
	for _,part in parts do
		local d=(part.Position-root.Position).Magnitude
		local model=modelOf(part)
		local person=model and model~=character and (Players:GetPlayerFromCharacter(model)~=nil or model:GetAttribute("NinjaChallenge")~=nil or model:GetAttribute("NinjaBoss")~=nil
			or model:GetAttribute("NinjaForestBandit")~=nil or model:GetAttribute("NinjaThug")~=nil or model:FindFirstChildOfClass("Humanoid")~=nil)
		if person then
			if d<bestD then best,bestD,bestModel=part,d,model end
		elseif part.Name=="Dummy" or part.Name=="DummyArms" then
			if d<bestD then best,bestD,bestModel=part,d,nil end
		elseif part.CanCollide and part.Transparency<1 then
			if d<worldD then worldPart,worldD=part,d end
		end
	end
	local Thugs=require(script.Parent.Thugs)
	if bestModel then
		local at=best.Position
		local other=Players:GetPlayerFromCharacter(bestModel)
		if other then
			local what=HubFight.strikePlayer(player,other,now)
			tell(at,"challenge",false,{by=player.UserId,to=other.UserId,what=what})
			return "player:"..what
		end
		for _,entry in Thugs.live do
			if entry.model==bestModel then
				tell(at,"hit",heavy)
				pcall(Thugs.fight,player,entry)
				return "thug"
			end
		end
		if bestModel:GetAttribute("NinjaForestBandit") then
			local Forest=require(script.Parent.Forest)
			tell(at,"hit",heavy)
			if Forest.of(player)=="forest" then pcall(Forest.fight,player) end
			return "bandit"
		end
		-- (STORY-001) the Ōtsutsuki waiting in the hall: struck, he answers
		if bestModel:GetAttribute("NinjaBoss") then
			tell(at,"hit",heavy)
			pcall(function() require(script.Parent.StoryPlay).face(player) end)
			return "boss"
		end
		local kit=bestModel:GetAttribute("NinjaChallenge")
		if type(kit)=="string" then
			tell(at,"hit",heavy)
			local m=HubFight.matches
			local Progression=require(script.Parent.Progression)
			local h=Progression.handles and Progression.handles[player]
			local own=h and h.data and h.data.kits and h.data.kits.selected
			if m and m.solo and own and Progression.owns(player,own) then
				local c=m.solo:accept(player,kit,now)
				if c then pcall(m.challengeStart,m,player,own,c,now) end
			end
			return "challenger"
		end
		tell(at,"hit",heavy)
		return "body"
	end
	if best then
		tell(best.Position,"hit",heavy,{dummy=true})
		return "dummy"
	end
	if worldPart then
		local c=context()
		c.now=now
		local look=Vector3.new(frame.LookVector.X,0,frame.LookVector.Z)
		look=if look.Magnitude>.05 then look.Unit else Vector3.zAxis
		local WorldReaction=require(script.Parent.WorldReaction)
		local at=worldPart:GetClosestPointOnSurface(root.Position+Vector3.new(0,.3,0))
		local ok,result=pcall(WorldReaction.impact,c,{part=worldPart,position=at,normal=-look,energy=spec.energy or 20,
			contact="blunt",direction=look,source=player.UserId})
		if ok and result then
			HubFight.lastBreak=os.clock()
			if not result.broken then tell(at,result.class or "hit",heavy,{material=result.class}) end
			return if result.broken then "broke" else "world"
		end
		tell(at,"world",heavy)
		return "world"
	end
	return nil
end

-- A walker asks for `move` (the remote HubAct), turned `dir`.
function HubFight.act(player,move,now,dir)
	if type(move)~="string" or not Rules.Moves[move] then return false end
	if not walking(player) then return false end
	local intro=player:GetAttribute("NinjaIntro")
	if intro=="fight" or intro=="create" then return false end
	local last=HubFight.last[player]
	if not last then last={};HubFight.last[player]=last end
	if not Rules.grant(last,move,now) then return false end
	local character=player.Character
	local spec=Rules.Moves[move]
	character:SetAttribute("NinjaAct",move)
	character:SetAttribute("NinjaActSeq",(character:GetAttribute("NinjaActSeq") or 0)+1)
	if spec.contact then
		local facing=HubFight.facing(dir)
		task.delay(spec.contact,function()
			if player.Parent and player.Character==character and walking(player) then
				pcall(HubFight.land,player,character,move,workspace:GetServerTimeNow(),facing)
			end
		end)
	end
	return true
end

function HubFight.start(matches)
	HubFight.matches=matches
	if Shared:FindFirstChild("HubAct") then return end
	local remote=Instance.new("RemoteEvent");remote.Name="HubAct";remote.Parent=Shared
	impactRemote=Instance.new("RemoteEvent");impactRemote.Name="HubImpact";impactRemote.Parent=Shared
	remote.OnServerEvent:Connect(function(player,move,dir)
		pcall(HubFight.act,player,move,workspace:GetServerTimeNow(),dir)
	end)
	Players.PlayerRemoving:Connect(function(player)
		HubFight.last[player]=nil
		HubFight.challenges[player.UserId]=nil
	end)
	-- the broken props come back once the street is calm again
	task.spawn(function()
		while true do
			task.wait(5)
			if ctx and ctx.world and os.clock()-HubFight.lastBreak>Rules.RESTORE then
				pcall(function()
					require(script.Parent.WorldReaction).restore(ctx)
					for _,d in ctx.match.folder:GetChildren() do d:Destroy() end
					ctx.world=nil
				end)
			end
		end
	end)
end

return HubFight
