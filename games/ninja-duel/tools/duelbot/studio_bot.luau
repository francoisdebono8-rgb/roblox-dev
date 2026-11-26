-- The simulated player in Studio (OUTILLEUR, 21/11; DEC-047): PlayerSim plays
-- duels through the game's own remote, as the client does (the stick at 15 Hz,
-- each press with its stick, its aim and its clock), in a Play of the game's
-- place (DEC-052), never while someone else plays in it. It reads only the duel snapshot
-- the client gets (the two bodies, the coach's prompt). Run during a Play,
-- from the Client datamodel. Injected in the Play as _G.NDDuelBot, from
--   python3 tools/robots/inject.py duel
-- then, in the same Play (Client): _G.NDDuelBot.start(PLAN)
-- (python3 tools/duelbot/studio_code.py --first ... prints that call), PLAN
-- being the list of runs, e.g.
--   [{"mode":"first","kit":"Lion","seed":1,"profile":"debutant"},
--    {"mode":"duel","kit":"Lion","rival":"Mirage","level":"easy","seed":1,"profile":"joueur"}]
-- The results go to the local player's attribute NDBotLog (JSON), the state
-- to NDBotState; read them with another execute_luau.
--   (PlayerSim is pasted in place of the line below by studio_code.py)
local PlayerSim=nil --@PLAYERSIM
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuel"):WaitForChild("Action")

local Bot={}
local current={epoch=0,phase="?"}
local results={}
local function note(state) pcall(function() player:SetAttribute("NDBotState",state) end) end
local function save() pcall(function() player:SetAttribute("NDBotLog",HttpService:JSONEncode(results)) end) end
local conn=nil
local function listen() if conn then return end conn=remote.OnClientEvent:Connect(function(data)
	if type(data)~="table" or (data.epoch or 0)<(current.epoch or 0) then return end
	current=data
end) end
local function send(action,extra)
	local payload={action=action,epoch=current.epoch}
	if current.phase=="Duel" and action~="Move" then payload.clientTime=workspace:GetServerTimeNow() end
	for k,v in extra or {} do payload[k]=v end
	remote:FireServer(payload)
	-- (26/11, passe 2) a watcher of the duel (tools/duelaudit: NDDuelAudit) sees each press
	if Bot.observer then pcall(Bot.observer,action,payload) end
end
local function root()
	local character=player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end
local function waitFor(test,limit)
	local t0=os.clock()
	while not test() do
		if os.clock()-t0>limit then return false end
		task.wait(.05)
	end
	return true
end
local function toSelection()
	if current.phase=="Selection" then return true end
	for _=1,6 do
		send("Selection")
		if waitFor(function() return current.phase=="Selection" end,3) then return true end
	end
	return false
end
local function view(now)
	local me,him=current.human,current.bot
	local function body(d)
		if not d then return nil end
		return {pos=d.position,health=d.health,maxHealth=d.maxHealth,chakra=d.chakra,maxChakra=d.maxChakra,state=d.state,
			reaction=d.reaction,attackName=d.attackName,techniques=d.techniques}
	end
	local tut=current.tutorial
	local prompt=if tut and tut.coach then {id=tut.id,key=tut.key,done=tut.done==true} else nil
	return {now=now,me=body(me),him=body(him),prompt=prompt}
end

-- One duel, played until its result: the rounds' lengths (from the end of the
-- intro to the K.O., server time), the prompts met.
local function play(run)
	local sim=PlayerSim.new(run.profile or "debutant",run.seed or 1,Vector3)
	local rec={mode=run.mode,kit=run.kit,rival=run.rival,level=run.level,seed=run.seed,profile=run.profile,rounds={},prompts={},presses=0}
	local round=nil
	local lastMove,lastDir=0,nil
	local seenPrompt=nil
	local started=os.clock()
	local hb=RunService.Heartbeat:Connect(function(dt)
		local d=current
		if d.phase~="Duel" or not d.human or not d.bot then return end
		-- a new round (a new epoch): its clock starts when the intro ends
		if not round or round.epoch~=d.epoch then
			round={epoch=d.epoch,index=d.round or (#rec.rounds+1)}
			table.insert(rec.rounds,round)
		end
		if (d.intro or 0)>0 then return end
		if not round.start then round.start=d.serverNow;round.startClock=os.clock() end
		if d.ko or d.winner then
			if not round.finish then
				round.finish=d.serverNow;round.t=round.finish-round.start
				round.winner=d.winner;round.me=d.human.health/d.human.maxHealth;round.him=d.bot.health/d.bot.maxHealth
			end
			return
		end
		local tut=d.tutorial
		if tut and tut.coach then
			if tut.id~=seenPrompt then
				seenPrompt=tut.id
				table.insert(rec.prompts,{id=tut.id,shown=d.serverNow-round.start})
			end
			if tut.done then
				local last=rec.prompts[#rec.prompts]
				if last and last.id==tut.id and not last.done then last.done=d.serverNow-round.start end
			end
		end
		local out=sim:tick(view(os.clock()),dt)
		local now=os.clock()
		local changed=lastDir==nil or (out.move-lastDir).Magnitude>.15
		if (changed and now-lastMove>1/30) or now-lastMove>1/15 then
			lastMove=now;lastDir=out.move
			send("Move",{direction=out.move,sprint=out.sprint})
		end
		for _,press in out.presses do
			rec.presses+=1
			send(press.action,{aim=press.aim,direction=out.move,sprint=out.sprint})
		end
	end)
	local ok=waitFor(function() return current.phase=="Result" end,run.limit or 240)
	hb:Disconnect()
	rec.finished=ok;rec.wall=os.clock()-started
	rec.winner=current.winner;rec.wins=current.wins
	-- the rounds that never started (a K.O. snapshot missed) are dropped
	local kept={}
	for _,r in rec.rounds do if r.t then table.insert(kept,{index=r.index,t=math.floor(r.t*10)/10,winner=r.winner,me=r.me,him=r.him}) end end
	rec.rounds=kept
	return rec
end

-- (26/11, passe 2) for the other robots: the simulated player, the last
-- snapshot, the remote as this robot sends it.
Bot.PlayerSim=PlayerSim
function Bot.current() return current end
Bot.send=send
Bot.toSelection=function() listen();return toSelection() end

function Bot.start(PLAN)
	listen();results={};save()
	task.spawn(function()
	note("ready")
	send("Ready")
	waitFor(function() return (current.epoch or 0)>0 or current.phase=="Selection" end,15)
	local owned={}
	for i,run in PLAN do
		note(string.format("run %d/%d %s %s",i,#PLAN,run.mode,run.kit))
		if not toSelection() then table.insert(results,{error="no selection",run=run});save();break end
		task.wait(1)
		local here=root() and root().Position or nil
		if run.mode=="first" then
			send("First",{player=run.kit,here=here})
		else
			if not owned[run.kit] then
				send("ChooseStarter",{player=run.kit});owned[run.kit]=true
				task.wait(1.2)
			end
			send("Start",{player=run.kit,bot=run.rival,level=run.level,here=here})
		end
		if not waitFor(function() return current.phase=="Duel" end,10) then
			table.insert(results,{error="no duel",run=run,phase=current.phase,notice=current.notice});save()
		else
			table.insert(results,play(run));save()
		end
		task.wait(2)
	end
	note("done")
	end)
	return "started "..#PLAN.." runs"
end
return Bot
