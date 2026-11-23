-- (23/11, passe commune 1, DEC-051; François: « on devrait pouvoir se
-- battre contre des PNJ », « des PNJ peuvent vouloir se battre pour me
-- racketter ») Rogue ninjas who rack the walkers of Konoha.
--
-- A few of them stand near the village's street-duel places. A walker who
-- comes close (STOP) is stopped: "YOUR RYŌ OR A FIGHT", the DESIGN's racket
-- panel (Client/RacketPanel, sent on the remote NinjaDuel.Racket; his answer
-- comes back as the action "Racket" {id, choice}):
--   pay      he pays the toll (TOLL, or all he has); the rogue lets him go
--   run      he has RUN_TIME seconds to be ESCAPE studs away; caught, a fight
--   fight    a street duel against the AI, right there (Matches:thugFight);
--            won, he takes their purse (REWARD); lost, he leaves some (LOSS)
-- No answer before the fuse (FUSE): the rogue swings, a fight. A rogue paid or
-- beaten leaves, and another comes back elsewhere a little later. Once
-- racked, a walker is left alone for a while (COOLDOWN).
-- The rogue's model is a duel rig in a dark coat until the ANIMATEUR's own
-- (Passe 1, ANIMATEUR: les voyous) replaces it.
local Thugs={}
Thugs.COUNT=3
Thugs.TOLL=30
Thugs.REWARD=60
Thugs.LOSS=20
Thugs.COOLDOWN=90
Thugs.RETURN=45
Thugs.KITS={"Lion","Leaf","Mirage","Sand"}
Thugs.LEVEL="easy"
Thugs.NAME="ROGUE NINJA"
Thugs.LINE="YOUR RYŌ OR A FIGHT"
Thugs.STOP=14          -- studs: he is stopped this close
Thugs.FUSE=8           -- seconds to answer before the rogue swings
Thugs.RUN_TIME=4       -- a run: this long to get away
Thugs.ESCAPE=34        -- studs from the rogue: away

-- (pure) What a racket costs him: the toll, or all he has.
function Thugs.toll(ryo)
	return math.clamp(math.floor(ryo or 0),0,Thugs.TOLL)
end
-- (pure) The fight's purse: won, the rogue's purse; lost, some of his.
function Thugs.purse(won,ryo)
	if won then return Thugs.REWARD end
	return -math.clamp(math.floor(ryo or 0),0,Thugs.LOSS)
end
-- (pure) What the racket panel shows (Client/RacketPanel's contract).
function Thugs.offer(id,ryo)
	return {id=id,name=Thugs.NAME,line=Thugs.LINE,ask=Thugs.TOLL,purse=Thugs.REWARD,win=Thugs.REWARD,
		lose=math.clamp(math.floor(ryo or 0),0,Thugs.LOSS),ryo=math.floor(ryo or 0),seconds=Thugs.FUSE}
end
-- (pure) A run decided: escaped when he is far enough from the rogue.
function Thugs.escaped(distance) return distance>=Thugs.ESCAPE end
-- (pure) Whether a rogue racks this walker now.
function Thugs.ready(last,now)
	return last==nil or now-last>=Thugs.COOLDOWN
end
-- (pure) The places they stand: the village's street-duel places, in order,
-- `count` of them, skipping `taken` (keys).
function Thugs.spots(streets,count,taken)
	local keys={}
	for _,street in streets or {} do
		if not (taken and taken[street.key]) then table.insert(keys,street) end
	end
	table.sort(keys,function(a,b) return a.key<b.key end)
	local out={}
	for i=1,math.min(count,#keys) do table.insert(out,keys[i]) end
	return out
end

-- ------------------------------------------------------------------ the game
Thugs.live={}          -- id -> {model, street, kit}
Thugs.racked=setmetatable({},{__mode="k"}) -- player -> os.clock() of his last racket
local Config,HubMap
local function shared()
	local S=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
	Config=Config or require(S.Config)
	HubMap=HubMap or require(S.HubMap)
end
function Thugs.on()
	shared()
	local c=Config.Hub and Config.Hub.Thugs
	return Config.Hub~=nil and Config.Hub.Enabled==true and c~=false
end

local function darken(model)
	for _,d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency<1 then d.Color=d.Color:Lerp(Color3.fromRGB(24,22,30),.62) end
	end
end
local function label(root)
	local gui=Instance.new("BillboardGui")
	gui.Name="ThugTag";gui.Size=UDim2.fromOffset(220,46);gui.StudsOffset=Vector3.new(0,4.2,0)
	gui.MaxDistance=60;gui.AlwaysOnTop=false;gui.LightInfluence=0
	local name=Instance.new("TextLabel")
	name.Size=UDim2.new(1,0,.5,0);name.BackgroundTransparency=1;name.Font=Enum.Font.GothamBlack
	name.TextScaled=true;name.Text=Thugs.NAME;name.TextColor3=Color3.fromRGB(226,64,52)
	name.TextStrokeTransparency=.2;name.Parent=gui
	local line=Instance.new("TextLabel")
	line.Position=UDim2.fromScale(0,.5);line.Size=UDim2.new(1,0,.5,0);line.BackgroundTransparency=1
	line.Font=Enum.Font.GothamBold;line.TextScaled=true;line.Text=Thugs.LINE
	line.TextColor3=Color3.fromRGB(245,238,224);line.TextStrokeTransparency=.2;line.Parent=gui
	gui.Parent=root
	return gui
end

-- One rogue at a street place: a copy of a kit's portrait, darkened.
function Thugs.spawn(holder,street,kit,portraits,matches)
	local portrait=portraits and portraits:FindFirstChild(kit)
	if not portrait then
		for _,m in (portraits and portraits:GetChildren() or {}) do if m:GetAttribute("Fighter")==kit then portrait=m end end
	end
	if not portrait then return nil end
	shared()
	local model=portrait:Clone()
	model.Name="Thug_"..street.key
	model:SetAttribute("NinjaThug",kit)
	darken(model)
	local root=model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not root then model:Destroy() return nil end
	-- beside the place, facing its centre
	local centre=HubMap.Origin+street.at
	local side=Vector3.new(street.radius or 10,0,0)
	local at=centre+side
	local delta=CFrame.lookAt(at+Vector3.new(0,3,0),centre+Vector3.new(0,3,0))*root.CFrame:Inverse()
	for _,piece in model:GetDescendants() do
		if piece:IsA("BasePart") then piece.CFrame=delta*piece.CFrame;piece.Anchored=true end
	end
	model.Parent=holder
	label(root)
	local entry={model=model,root=root,street=street,kit=kit}
	Thugs.live[street.key]=entry
	return entry
end
function Thugs.leave(entry)
	if Thugs.live[entry.street.key]~=entry then return end
	Thugs.live[entry.street.key]=nil
	for player,pending in Thugs.pending do
		if pending.entry==entry then Thugs.close(player) end
	end
	if entry.model then entry.model:Destroy() end
	-- another comes back elsewhere a little later
	task.delay(Thugs.RETURN,function() pcall(Thugs.fill) end)
end

-- He pays: the toll (or all he has), the rogue goes.
function Thugs.pay(player,entry)
	local P=require(script.Parent.Progression)
	local h=P.handles and P.handles[player]
	local ryo=h and h.data and h.data.wallet and h.data.wallet.ryo or 0
	local toll=Thugs.toll(ryo)
	if toll>0 then
		local ok=P.run(player,"payRyo",{amount=toll,why="racket"})
		if not ok then return end
		if Thugs.matches then pcall(Thugs.matches.kitsLoaded,Thugs.matches,player) end
	end
	Thugs.racked[player]=os.clock()
	Thugs.close(player)
	Thugs.leave(entry)
end
-- He fights: a street duel against the AI, right there.
function Thugs.fight(player,entry,matches)
	matches=matches or Thugs.matches
	Thugs.close(player)
	if not matches or not matches.thugFight then return end
	if matches:thugFight(player,entry.kit,entry.street.key,Thugs.LEVEL) then
		Thugs.racked[player]=os.clock()
		Thugs.leave(entry)
	end
end

-- ------------------------------------------------------------ the racket
Thugs.pending=setmetatable({},{__mode="k"}) -- player -> {entry, at, run}
local remote
local function panel(player,r)
	if remote and player.Parent then remote:FireClient(player,r or false) end
end
function Thugs.close(player)
	if Thugs.pending[player] then Thugs.pending[player]=nil;panel(player,false) end
end
local function ryoOf(player)
	local P=require(script.Parent.Progression)
	local h=P.handles and P.handles[player]
	return h and h.data and h.data.wallet and h.data.wallet.ryo or 0
end
-- He is stopped: the panel, the fuse running.
function Thugs.stop(player,entry,now)
	Thugs.pending[player]={entry=entry,at=now}
	panel(player,Thugs.offer(entry.street.key,ryoOf(player)))
end
-- His answer (the action "Racket" {id, choice}).
function Thugs.answer(player,id,choice,now)
	local pending=Thugs.pending[player]
	if not pending or pending.entry.street.key~=id or Thugs.live[id]~=pending.entry then return false end
	if choice=="pay" then Thugs.pay(player,pending.entry)
	elseif choice=="fight" then Thugs.fight(player,pending.entry)
	elseif choice=="run" and not pending.run then pending.run=now or os.clock();panel(player,false)
	else return false end
	return true
end
-- Every few frames: who comes close is stopped; the fuse; the runs.
local function rootOf(player)
	local c=player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
function Thugs.tick(now,players,walking)
	for player,pending in Thugs.pending do
		local root,entry=rootOf(player),pending.entry
		local far=if root and entry.root then (root.Position-entry.root.Position).Magnitude else math.huge
		if Thugs.live[entry.street.key]~=entry or not walking(player) then
			Thugs.pending[player]=nil
		elseif pending.run then
			if Thugs.escaped(far) then Thugs.racked[player]=now;Thugs.close(player)
			elseif now-pending.run>=Thugs.RUN_TIME then Thugs.fight(player,entry) end
		elseif Thugs.escaped(far) then
			-- walked off before the fuse: let go
			Thugs.racked[player]=now;Thugs.close(player)
		elseif now-pending.at>=Thugs.FUSE then
			Thugs.fight(player,entry)
		end
	end
	for _,player in players do
		if Thugs.pending[player] or not Thugs.ready(Thugs.racked[player],now) or not walking(player) then continue end
		local root=rootOf(player)
		if not root then continue end
		for _,entry in Thugs.live do
			if entry.root and (root.Position-entry.root.Position).Magnitude<=Thugs.STOP then
				Thugs.stop(player,entry,now)
				break
			end
		end
	end
end
-- The duel decided (Matches): the purse.
function Thugs.ended(player,won)
	local P=require(script.Parent.Progression)
	local h=P.handles and P.handles[player]
	local ryo=h and h.data and h.data.wallet and h.data.wallet.ryo or 0
	local purse=Thugs.purse(won,ryo)
	if purse>0 then P.run(player,"earnRyo",{amount=purse})
	elseif purse<0 then P.run(player,"payRyo",{amount=-purse,why="racket"}) end
	return purse
end

Thugs.holder=nil
Thugs.portraits=nil
Thugs.matches=nil
function Thugs.fill()
	if not Thugs.holder or not Thugs.holder.Parent then return end
	shared()
	local taken={}
	for key in Thugs.live do taken[key]=true end
	local want=Thugs.COUNT
	for _ in Thugs.live do want-=1 end
	if want<=0 then return end
	local streets=Thugs.spots(HubMap.Streets,#(HubMap.Streets or {}),taken)
	-- a different place than before when it can
	for i=#streets,2,-1 do local j=math.random(1,i);streets[i],streets[j]=streets[j],streets[i] end
	for i=1,math.min(want,#streets) do
		Thugs.spawn(Thugs.holder,streets[i],Thugs.KITS[math.random(1,#Thugs.KITS)],Thugs.portraits,Thugs.matches)
	end
end
function Thugs.start(hubFolder,portraits,matches)
	if not Thugs.on() or not hubFolder then return end
	local holder=Instance.new("Folder");holder.Name="Thugs";holder.Parent=hubFolder
	Thugs.holder,Thugs.portraits,Thugs.matches=holder,portraits,matches
	local S=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel")
	remote=S:FindFirstChild("Racket") or Instance.new("RemoteEvent")
	remote.Name="Racket";remote.Parent=S
	Thugs.fill()
	local Players=game:GetService("Players")
	local function walking(player)
		local s=matches and matches.sessions and matches.sessions[player]
		return s~=nil and s.phase=="Selection" and not s.finishing
	end
	task.spawn(function()
		while holder.Parent do
			task.wait(.25)
			pcall(Thugs.tick,os.clock(),Players:GetPlayers(),walking)
		end
	end)
end

return Thugs
