-- The new player's first ten minutes, played (OUTILLEUR, 23/11; étape 5,
-- DEC-049: « un robot nouveau joueur qui joue les 10 premières minutes et
-- chronomètre l'entonnoir »).
--
-- A client module, injected in a Play of the game's place (DEC-052; a fresh profile:
-- Studio starts every Play as a new player). It does what a new player is
-- led to do, in the order the game leads him, and notes when each thing
-- happened and what was on the screen then:
--   1. the first screen: he reads it, then PLAY (the first combat);
--   2. the first combat, played by the beginner (tools/duelbot, NDDuelBot);
--   3. back in Konoha: the inspiration he takes (the starter), an outfit on;
--   4. a walk to the market and back (tools/villagebot, NDVillageBot);
--   5. a duel against the AI (easy), played by the beginner;
--   6. a look bought with his Ryō, a node of his tree learned;
--   7. the rooftop race, until the ten minutes are up.
-- The server's funnel (Server/Matches.measure: joined, inspiration, dressed,
-- started, hit, duel, won, bought, node) is read from the Output after the
-- run ([NinjaDuelFirst] lines, tools/newplayer/studio_code.py --funnel).
--
-- Results: Players.LocalPlayer attribute NDNewPlayerLog (JSON), progress in
-- NDNewPlayerState. Needs _G.NDDuelBot and _G.NDVillageBot
-- (python3 tools/robots/inject.py newplayer injects all three).
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local Shared=RS:WaitForChild("NinjaDuel")
local remote=Shared:WaitForChild("Action")

local Bot={}
Bot.MINUTES=10
Bot.READ=4            -- seconds he looks at a new screen before acting
Bot.KIT="Legion"      -- the inspiration he takes (one of the three starters)

local t0=os.clock()
local log={steps={},screens={},refusals={}}
local current={phase="?",epoch=0}
local conn=nil
local function since() return math.floor((os.clock()-t0)*10+.5)/10 end
local function note(s) pcall(function() player:SetAttribute("NDNewPlayerState",s) end) end
local function save() pcall(function() player:SetAttribute("NDNewPlayerLog",HttpService:JSONEncode(log)) end) end
local function listen()
	if conn then return end
	conn=remote.OnClientEvent:Connect(function(d)
		if type(d)~="table" then return end
		if type(d.epoch)=="number" and d.epoch<(current.epoch or 0) then return end
		for k,v in d do current[k]=v end
		if d.phase then current.phase=d.phase end
		if d.notice then table.insert(log.refusals,{t=since(),notice=tostring(d.notice)}) end
	end)
end
local function send(action,extra)
	local payload={action=action,epoch=current.epoch}
	for k,v in extra or {} do payload[k]=v end
	remote:FireServer(payload)
end
local function waitFor(test,limit)
	local t=os.clock()
	while not test() do
		if os.clock()-t>limit then return false end
		task.wait(.1)
	end
	return true
end
-- What is on his screen: the visible buttons' words (what he can press).
local function shown(gui)
	local out={}
	local function visible(o)
		while o and o~=gui do
			if o:IsA("GuiObject") and not o.Visible then return false end
			if o:IsA("ScreenGui") and not o.Enabled then return false end
			o=o.Parent
		end
		return true
	end
	for _,o in gui:GetDescendants() do
		if (o:IsA("TextButton") or o:IsA("TextLabel")) and o.Text~="" and #o.Text<=40 and visible(o) and o.AbsoluteSize.X>40 then
			if o:IsA("TextButton") or (o.TextSize>=24) then table.insert(out,(if o:IsA("TextButton") then "[" else "")..o.Text..(if o:IsA("TextButton") then "]" else "")) end
		end
	end
	return out
end
local function screen(label)
	local gui=player:FindFirstChildOfClass("PlayerGui")
	local words=if gui then shown(gui) else {}
	if #words>24 then words={table.unpack(words,1,24)} end
	table.insert(log.screens,{t=since(),at=label,phase=current.phase,words=words})
	save()
end
local function step(name,ok,extra)
	local s={t=since(),step=name,ok=ok~=false}
	for k,v in extra or {} do s[k]=v end
	table.insert(log.steps,s)
	note(name)
	save()
end
local function over() return os.clock()-t0>Bot.MINUTES*60 end
local function toSelection()
	if current.phase=="Selection" then return true end
	for _=1,6 do
		send("Selection")
		if waitFor(function() return current.phase=="Selection" end,3) then return true end
	end
	return current.phase=="Selection"
end
-- A fight played by the beginner robot (tools/duelbot); returns its record.
local function fight(run)
	local Duel=_G.NDDuelBot or error("NDDuelBot absent : python3 tools/robots/inject.py newplayer")
	player:SetAttribute("NDBotState",nil)
	Duel.start({run})
	waitFor(function() return player:GetAttribute("NDBotState")=="done" end,300)
	local ok,res=pcall(function() return HttpService:JSONDecode(player:GetAttribute("NDBotLog") or "[]") end)
	return ok and res and res[1] or {}
end
local function rounds(rec)
	local out={}
	for _,r in rec.rounds or {} do table.insert(out,r.t) end
	return out
end

local function run()
	listen()
	note("start")
	-- the first screen: whatever the game shows him first
	waitFor(function() return (current.epoch or 0)>0 end,20)
	if (current.epoch or 0)==0 then send("Ready");waitFor(function() return (current.epoch or 0)>0 end,5) end
	step("joined",true,{phase=current.phase})
	screen("first screen")
	task.wait(Bot.READ)

	-- 1-2. PLAY: the first combat
	local first=fight({mode="first",kit=Bot.KIT,seed=1,profile="debutant",limit=240})
	step("first combat",first.winner~=nil,{winner=first.winner,rounds=rounds(first),wall=first.wall,
		prompts=#(first.prompts or {}),error=first.error})
	screen("after the first combat")
	task.wait(Bot.READ)
	toSelection()
	task.wait(1)
	screen("back in Konoha")

	-- 3. the inspiration, an outfit
	send("ChooseStarter",{player=Bot.KIT})
	waitFor(function() return current.kits and current.kits.starter~=nil end,5)
	step("inspiration",current.kits~=nil and current.kits.starter~=nil,{starter=current.kits and current.kits.starter})
	task.wait(Bot.READ)
	local Shop=require(Shared:WaitForChild("Shop"))
	local top=nil
	for _,item in Shop.Items do
		if item.slot=="top" and (item.base and not item.none) then top=item.id;break end
	end
	if top then
		send("EquipItem",{item=top})
		task.wait(1)
	end
	step("outfit",top~=nil,{item=top})
	screen("dressed")

	-- 4. a walk to the market and back
	local okV,Village=pcall(function() return _G.NDVillageBot or error("NDVillageBot absent") end)
	local HubMap=require(Shared:WaitForChild("HubMap"))
	if okV and Village and HubMap.Market then
		local leg=nil
		local done=false
		local orig=Village.race
		Village.race=function()
			leg=Village.walkTo(HubMap.world(HubMap.Market.at),"market",8)
			done=true
			return {walk=leg}
		end
		Village.start({routes=false,race=1})
		task.wait(.5)
		Village.race=orig
		waitFor(function() return done end,100)
		step("walk to the market",leg~=nil and leg.arrived,{walk=leg and leg.t,length=leg and leg.length})
	end
	if over() then return end

	-- 5. a duel against the AI
	local FirstMinute=require(Shared:WaitForChild("FirstMinute"))
	toSelection()
	local duel=fight({mode="duel",kit=Bot.KIT,rival=FirstMinute.rival(Bot.KIT) or "Lion",level="easy",seed=2,profile="debutant",limit=300})
	step("duel",duel.winner~=nil,{winner=duel.winner,wins=duel.wins,rounds=rounds(duel),wall=duel.wall,error=duel.error})
	screen("after the duel")
	task.wait(Bot.READ)
	toSelection()
	if over() then return end

	-- 6. a look for his Ryō (the cheapest he can pay), a node of his tree
	task.wait(1)
	local ryo=current.kits and current.kits.ryo or 0
	local cheap=nil
	for _,item in Shop.Items do
		if item.ryo and item.ryo<=ryo and not item.earned and (not cheap or item.ryo<cheap.ryo) then cheap=item end
	end
	if cheap then
		local before=#log.refusals
		send("BuyItem",{item=cheap.id})
		task.wait(1.5)
		step("bought",#log.refusals==before,{item=cheap.id,price=cheap.ryo,ryo=ryo})
	else
		step("bought",false,{ryo=ryo,why="nothing he can pay"})
	end
	local Trees=require(Shared:WaitForChild("SkillTrees"))
	local tree=Trees[Bot.KIT]
	local free=current.kits and current.kits.trees and current.kits.trees[Bot.KIT] and current.kits.trees[Bot.KIT].free or 0
	local nodes={}
	for _,n in (tree and tree.Nodes or {}) do
		if (n.Tier or 1)==1 and not n.Requires and not n.RequiresAny then table.insert(nodes,n) end
	end
	table.sort(nodes,function(a,b) return (a.Cost or 0)<(b.Cost or 0) end)
	local learned=nil
	for _,n in nodes do
		if (n.Cost or 0)<=free then
			local before=#log.refusals
			send("LearnNode",{player=Bot.KIT,node=n.Id})
			task.wait(1)
			if #log.refusals==before then learned=n.Id;break end
		end
	end
	step("node",learned~=nil,{node=learned,free=free,cheapest=nodes[1] and nodes[1].Cost})
	screen("shop and tree")

	-- 7. the rooftop race until the time is up
	while not over() and okV and Village do
		local race=nil
		local orig=Village.race
		local done=false
		Village.race=function() race=orig();done=true;return race end
		Village.start({routes=false,race=1})
		task.wait(.5)
		Village.race=orig
		waitFor(function() return done or over() end,120)
		local passed=0
		for _,r in (race and race.rings or {}) do if r.ok then passed+=1 end end
		step("rooftop race",race~=nil and race.serverTime~=nil,{time=race and race.serverTime,rings=passed,error=race and race.error})
		if not race or race.error then break end
	end
end

function Bot.start(options)
	options=options or {}
	Bot.MINUTES=options.minutes or Bot.MINUTES
	Bot.KIT=options.kit or Bot.KIT
	t0=options.t0 or os.clock()
	log={steps={},screens={},refusals={},kit=Bot.KIT,minutes=Bot.MINUTES}
	save()
	task.spawn(function()
		local ok,err=pcall(run)
		if not ok then log.error=tostring(err) end
		log.total=since()
		save()
		note("done")
	end)
	return "started"
end
return Bot
