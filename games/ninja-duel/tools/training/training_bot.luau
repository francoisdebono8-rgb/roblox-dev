-- The training robot (OUTILLEUR, passe commune 2, 26/11; DEC-054: « un robot
-- d'entraînement qui joue chaque étape des tutos jusqu'au bout et dit où il
-- bloque »).
--
-- A client module, injected in a Play of the game's place (DEC-052):
--   python3 tools/robots/inject.py duel training
-- It opens the practice of a kit (the remote's "Tutorial", as the select
-- screen does), then plays each step the way a player would, through the
-- game's remote only: the stick at 15 Hz, each press with its stick and its
-- aim. The moves of each step are those of Server/TutorialBot (the debug
-- places' server robot), sent as a player's presses. A step not passed in
-- Bot.GIVE_UP seconds is skipped as a player can (the panel's skip), and
-- reported "abandonné". The last step (win the practice duel) is played by
-- the duel robot's simulated player (NDDuelBot.PlayerSim) when it is there.
--
--   _G.NDTrainingBot.start({{kit="Lion",rival="Mirage"},...})
--   _G.NDTrainingBot.read()   JSON: per kit, per step: shown, how long, outcome,
--                             the cues the game showed (refusals), the prompt
-- The server's verdict of each step (PASS, STUCK, SKIP, refusals, freezes)
-- is in its [NinjaDuelTutorial] lines: NDServerLog (inject.py --server serverlog).
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remote=RS:WaitForChild("NinjaDuel"):WaitForChild("Action")
local okF,Fighters=pcall(function() return require(RS.NinjaDuel.Fighters) end)
if not okF then Fighters={} end

local Bot={}
Bot.GIVE_UP=22
Bot.WIN_LIMIT=90
local current={epoch=0,phase="?"}
local results={}
local stick,sprint,locked=Vector3.zero,false,true
local conn,hb=nil,nil
local state="idle"

local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function r1(x) return math.floor(x*10+.5)/10 end
local function save() pcall(function() player:SetAttribute("NDTrainingLog",HttpService:JSONEncode(results)) end) end
local function listen()
	if conn then return end
	conn=remote.OnClientEvent:Connect(function(data)
		if type(data)~="table" or (data.epoch or 0)<(current.epoch or 0) then return end
		current=data
	end)
end
local function send(action,extra)
	local payload={action=action,epoch=current.epoch}
	if current.phase=="Duel" and action~="Move" then payload.clientTime=workspace:GetServerTimeNow() end
	for k,v in extra or {} do payload[k]=v end
	remote:FireServer(payload)
	local audit=_G.NDDuelAudit
	if audit and audit.sent then pcall(audit.sent,action,payload) end
end
local function waitFor(test,limit)
	local t0=os.clock()
	while not test() do
		if os.clock()-t0>limit then return false end
		task.wait(.05)
	end
	return true
end
local function me() return current.human end
local function him() return current.bot end
local function toward()
	local a,b=me(),him()
	if not a or not b then return Vector3.zAxis end
	local d=flat(b.position-a.position)
	return if d.Magnitude>.1 then d.Unit else Vector3.zAxis
end
local function gap()
	local a,b=me(),him()
	if not a or not b then return 99 end
	return flat(b.position-a.position).Magnitude
end
local function press(action,aim)
	send(action,{aim=aim,direction=stick,sprint=sprint})
end
local function aimAt() local b=him();return b and b.position end

-- The moves of each step (Server/TutorialBot, as presses). `alive()` says
-- the step still runs; `wait` yields.
local function scripts(kit,alive)
	local wait=task.wait
	local def=Fighters[kit] or {}
	local function hold(v,sec) local t0=os.clock();while alive() and os.clock()-t0<sec do stick=v;wait(.05) end end
	local function chain(n,g) for _=1,n do if not alive() then return end;press("Attack");wait(g or .24) end end
	local function perp() return toward():Cross(Vector3.yAxis) end
	local S={}
	S.move=function() hold(perp(),1.5);stick=Vector3.zero end
	S.sprint=function() sprint=true;hold(perp(),1.5);sprint=false;stick=Vector3.zero end
	S.jump=function() press("Jump");wait(1.2) end
	S.lock=function() locked=false;send("Move",{direction=Vector3.zero,locked=false});wait(.3);locked=true;send("Move",{direction=Vector3.zero,locked=true});wait(.5) end
	S.dodge=function() stick=perp();press("Dodge");wait(.6);stick=Vector3.zero end
	S.wall=function()
		local t0=os.clock()
		while alive() and not (me() and me().wall) and os.clock()-t0<3 do stick=Vector3.xAxis;wait(.05) end
		wait(.15);press("Jump");wait(.6);stick=Vector3.zero
	end
	S.string=function() stick=Vector3.zero;chain((def.StringLength or 4)+1,.26);wait(.5) end
	S.heavy=function() press("Heavy");wait(1) end
	S.routeSide=function() chain(2,.28);stick=perp();press("Attack");wait(.6);stick=Vector3.zero end
	S.routeDown=function() chain(2,.28);stick=-toward();press("Attack");wait(.6);stick=Vector3.zero end
	S.launch=function() chain(2,.28);stick=toward();press("Attack");wait(.6);stick=Vector3.zero end
	S.chase=function() wait(.15);press("Pursuit");wait(.8) end
	S.air=function() press("Attack");wait(.26);press("Attack");wait(.6) end
	S.airFinish=function() press("Heavy");wait(.8) end
	S.runStrike=function()
		sprint=true
		local t0=os.clock()
		while alive() and os.clock()-t0<3 do
			stick=toward()
			if gap()<9 and (me().speed or 0)>28 then press("Attack");break end
			wait(.03)
		end
		sprint=false;wait(.6);stick=Vector3.zero
	end
	S.grab=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<1.5 and gap()>2.8 do stick=toward();wait(.03) end
		stick=Vector3.zero;press("Grab");wait(.4);press("Attack");wait(1.2)
	end
	S.tool=function()
		if def.Tool=="Deflect" then
			-- the partner's blade on its way: the kick then
			local t0=os.clock()
			while alive() and os.clock()-t0<4 do
				local mine=me()
				for _,p in current.projectiles or {} do
					if p.owner==(him() and him().id) and mine and (p.origin-mine.position).Magnitude<40 then
						press("Tool",aimAt());wait(.9);return
					end
				end
				wait(.02)
			end
			return
		end
		press("Tool",aimAt());wait(.9)
	end
	for i=1,5 do
		S["jutsu"..i]=function() press("Technique"..i,aimAt());wait(.5);send("SealRelease");wait(.9) end
	end
	S.sealPage=function() press("Seal1",aimAt());wait(.5);send("SealRelease");wait(.9) end
	S.guard=function()
		press("Guard")
		local t0=os.clock();while alive() and os.clock()-t0<3 do wait(.05) end
		press("GuardOff")
	end
	S.evade=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<4 do
			local b=him()
			if b and b.attackName=="Heavy" and b.state=="Startup" and (b.attackElapsed or 0)>.12 then
				stick=perp();press("Dodge");wait(.6);stick=Vector3.zero;return
			end
			wait(.02)
		end
	end
	S.substitute=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<4 do
			if me() and me().reaction then wait(.05);press("Dodge");wait(.6);return end
			wait(.02)
		end
	end
	S.interrupt=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<5 do
			if him() and him().state=="TechniqueChannel" then
				while alive() and him().state=="TechniqueChannel" and gap()>5 do stick=toward();wait(.03) end
				stick=Vector3.zero;press("Attack");wait(.6);return
			end
			wait(.02)
		end
	end
	S.throwBreak=function()
		local t0=os.clock()
		while alive() and os.clock()-t0<4 do
			if me() and me().reaction=="Grabbed" then press("Grab");wait(.5);return end
			wait(.02)
		end
	end
	S.awaken=function() press("Awaken");wait(1) end
	S.ultimate=function() press("Ultimate");wait(1.5) end
	return S
end

-- The stick, sent as the client sends it (15 Hz, at once when it changes).
local lastSent,lastDir=0,nil
local function startStick()
	if hb then return end
	hb=RunService.Heartbeat:Connect(function()
		if current.phase~="Duel" then return end
		local now=os.clock()
		local changed=lastDir==nil or (stick-lastDir).Magnitude>.15
		if (changed and now-lastSent>1/30) or now-lastSent>1/15 then
			lastSent=now;lastDir=stick
			remote:FireServer({action="Move",epoch=current.epoch,direction=stick,sprint=sprint,locked=locked})
			local audit=_G.NDDuelAudit
			if audit and audit.sent then pcall(audit.sent,"Move",{direction=stick}) end
		end
	end)
end

local function toSelection()
	if current.phase=="Selection" then return true end
	for _=1,6 do
		send("Selection")
		if waitFor(function() return current.phase=="Selection" end,3) then return true end
	end
	return false
end

-- The last step: the practice duel, played by the simulated player.
local function playWin(rec,alive)
	local duel=_G.NDDuelBot
	if not (duel and duel.PlayerSim) then rec.note="sans NDDuelBot : passé à la main (TutorialSkip)";return end
	local sim=duel.PlayerSim.new("joueur",1,Vector3)
	local t0=os.clock()
	while alive() and os.clock()-t0<Bot.WIN_LIMIT do
		local d=current
		if d.human and d.bot then
			local function body(x) return {pos=x.position,health=x.health,maxHealth=x.maxHealth,chakra=x.chakra,maxChakra=x.maxChakra,state=x.state,reaction=x.reaction,attackName=x.attackName,techniques=x.techniques} end
			local out=sim:tick({now=os.clock(),me=body(d.human),him=body(d.bot)},1/15)
			stick=out.move;sprint=out.sprint
			for _,p in out.presses do send(p.action,{aim=p.aim,direction=out.move,sprint=out.sprint}) end
		end
		task.wait(1/15)
	end
	stick=Vector3.zero;sprint=false
	rec.win=current.winner
end

local function practice(kit,rival)
	local out={kit=kit,rival=rival,steps={},started=os.clock()}
	table.insert(results,out);save()
	if not toSelection() then out.error="pas d'écran de sélection";save();return end
	task.wait(1)
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	send("Tutorial",{player=kit,bot=rival,here=root and root.Position})
	if not waitFor(function() return current.phase=="Duel" and current.tutorial~=nil end,12) then
		out.error="l'entraînement ne démarre pas ("..tostring(current.phase)..", "..tostring(current.notice)..")";save();return
	end
	local S=scripts(kit,function() return true end)
	local index=0
	while current.phase=="Duel" and current.tutorial do
		local tut=current.tutorial
		if tut.index~=index then
			index=tut.index
			local rec={index=tut.index,total=tut.total,id=tut.id,title=tut.title,key=tut.key,pad=tut.pad,shownAt=r1(os.clock()-out.started),tries=0,cues={}}
			table.insert(out.steps,rec);save()
			state=string.format("%s %d/%d %s",kit,tut.index,tut.total,tostring(tut.id))
			local myIndex=index
			local t0=os.clock()
			local function alive() return current.phase=="Duel" and current.tutorial~=nil and current.tutorial.index==myIndex end
			S=scripts(kit,alive)
			if tut.id=="win" then
				playWin(rec,alive)
				if alive() then send("TutorialSkip") end
				rec.seconds=r1(os.clock()-t0);rec.outcome=if rec.win=="PlayerFighter" then "gagné" else "fini sans victoire";save()
				break
			end
			local fn=S[tut.id]
			if not fn then rec.note="ce robot ne sait pas jouer cette étape" end
			while alive() and os.clock()-t0<Bot.GIVE_UP do
				rec.tries+=1
				if fn then
					local ok,err=pcall(fn)
					if not ok then rec.error=tostring(err) end
				end
				-- the cue the game shows him (a refusal: "NO CHAKRA", "COOLDOWN"…)
				local cue=me() and me().cue
				if type(cue)=="string" and cue~="" and not table.find(rec.cues,cue) then table.insert(rec.cues,cue) end
				task.wait(.25)
			end
			stick=Vector3.zero;sprint=false;locked=true
			rec.seconds=r1(os.clock()-t0)
			if alive() then
				rec.outcome="abandonné";send("TutorialStep")
				waitFor(function() return not alive() end,3)
			else
				rec.outcome="fini"
			end
			save()
		end
		task.wait(.05)
	end
	out.seconds=r1(os.clock()-out.started);out.phase=current.phase
	save()
end

function Bot.start(PLAN)
	listen();startStick();results={};save()
	task.spawn(function()
		state="ready"
		send("Ready")
		waitFor(function() return (current.epoch or 0)>0 or current.phase=="Selection" end,15)
		for i,run in PLAN do
			state=string.format("kit %d/%d %s",i,#PLAN,run.kit)
			local ok,err=pcall(practice,run.kit,run.rival)
			if not ok then table.insert(results,{kit=run.kit,error=tostring(err)});save() end
			task.wait(1.5)
		end
		toSelection()
		state="done"
	end)
	return "entraînement de "..#PLAN.." kits lancé"
end
function Bot.state() return state end
function Bot.read() return HttpService:JSONEncode({state=state,results=results}) end
function Bot.stop()
	if hb then hb:Disconnect();hb=nil end
	if conn then conn:Disconnect();conn=nil end
	state="stopped"
end
return Bot
