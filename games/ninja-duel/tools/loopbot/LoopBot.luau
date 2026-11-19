-- LoopBot (OUTILLEUR, 19/11, plan-vrai-jeu-taches-2026-11-19 § 4 OUTILLEUR 1):
-- a new player's loop played headless on the real server modules (Matches,
-- Progression, ProfileSchema on a memory store, Tutorial, Combat on harness
-- rigs, Shop, Masters, SkillTrees):
--   arrivee   the profile loads, no kit yet, not dressed
--   inspiration  one starter among three (ChooseStarter), at the gate
--   tenue     a free top, bottoms and sandals worn: dressed (the outfit card
--             opens once the inspiration is chosen: Studio, 19/11)
--   duel      the first minute (First): the prompts, the FIRST HIT really
--             landed on the partner (Move then Attack through Matches:request),
--             then the real duel won
--   gains     what the result screen gets (snapshot `progress`), its line
--   marche    duels until the cheapest look of the market is affordable, bought, worn
--   arbre     duels until the cheapest first-tier node of the kit is affordable, learned
--   garderobe every slot of the catalogue shown by the wardrobe, and a free look
--             worn in each slot that has one (vague 2: the new slots mask, cape, back)
-- Bot.collection(): every look has its icon (tools/icons/renders) and its
-- model in the game (vague 2, OUTILLEUR 2; the same without lune:
-- python3 tools/icons/catalogue.py --gate).
-- and the estimated play time until the first hit: the screens (assumptions
-- below), the walk from the gate to the three inspirations (the first duel is
-- asked at the door: "YOUR FIRST DUEL" on the master's card, Studio 19/11) and
-- the simulated first minute up to the hit. The Studio run of 19/11 (README)
-- measured what the game itself takes on each step, on PC and on a phone.
--
-- Used by tests/Loop.spec.luau (fails when a step breaks) and by
-- tools/loopbot/run.luau (the report). Run from games/ninja-duel:
--   lune run tools/loopbot/run.luau [Leaf|Lion|Legion] [--json]
-- It proves the server's loop and its numbers, NOT the screens, the camera,
-- Roblox's paths in Konoha nor a real player's pace.
local H=require("../../tests/Harness")
local fs=require("@lune/fs")
local V=H.V

local Bot={}

-- What a new player takes outside the simulation (seconds). Assumptions until
-- the Studio run (task 3) measures them; change them here, not in the spec.
Bot.UI={
	arrive=3,        -- the gate, the camera settles, the objective is read
	talk=1,          -- E (or a tap) at the inspiration: his card opens
	choose=5,        -- his card read, HE'S MY INSPIRATION
	dressPerSlot=2.5,-- one choice on the outfit card (top, bottoms, feet)
	done=1,          -- DONE on the outfit card
	askDuel=2,       -- YOUR FIRST DUEL read and pressed (the duel starts 0.2 s later in Studio)
	readPrompt=1,    -- a prompt of the first minute read before acting (in the simulation)
}
Bot.Target=60      -- the plan's goal: the first hit in under 60 s
Bot.MaxDuels=60    -- past this many duels, the market or the tree is out of reach
Bot.DuelSeconds=90 -- a duel against the AI, for the play time of the loop (assumption)
Bot.BetweenDuels=20 -- the result screen, back to Konoha, the next duel (assumption)
Bot.FirstSession=20 -- (vague 2) the first purchase should come in the first session: its length in minutes (assumption)

-- Konoha's walk speed, read from the client that sets it (Client/HubClient:
-- `Hub.WALK,Hub.RUN,... = 16,36,...`), so a change there changes the estimate.
function Bot.walkSpeeds()
	local text=fs.readFile("src/Client/HubClient.luau")
	local walk,run=string.match(text,"Hub%.WALK,Hub%.RUN[%w%.,]*=%s*([%d%.]+),%s*([%d%.]+)")
	assert(walk and run,"HubClient no longer sets Hub.WALK, Hub.RUN in one line: update Bot.walkSpeeds")
	return tonumber(walk),tonumber(run)
end

-- ----------------------------------------------------------------- the world
local clock=20000
H.workspace.GetServerTimeNow=function() return clock end
local timers={}
H.envBase.task={delay=function(t,fn,...) table.insert(timers,{at=clock+t,fn=fn,args=table.pack(...)}) end,spawn=function() end,defer=function() end,wait=function() return 0 end}
local function runTimers()
	local due={}
	for i=#timers,1,-1 do if timers[i].at<=clock then table.insert(due,1,table.remove(timers,i)) end end
	for _,t in due do t.fn(table.unpack(t.args,1,t.args.n)) end
end
local baseNew=H.envBase.Instance.new
H.envBase.Instance={new=function(class)
	local x=baseNew(class)
	if class=="Folder" then function x:ClearAllChildren() table.clear(self.children) end end
	return x
end}
-- ProfileRepository names its server with a GUID.
local getService=H.envBase.game.GetService
local guids=0
H.envBase.game.GetService=function(g,name)
	if name=="HttpService" then return {GenerateGUID=function() guids+=1;return "loopbot-"..guids end} end
	return getService(g,name)
end
local World=H.load("Server/World")
World.arena=function() end
World.rig=function(parent,def,cf,name) return H.buildRig(parent,def,cf,name) end
local Config=H.load("Shared/Config")
local Repo=H.load("Server/ProfileRepository")
local Progression=H.load("Server/Progression")
local Matches=H.load("Server/Matches")
local AntiCheat=H.load("Server/VelmoraAntiCheat")
local Shop=H.load("Shared/Shop")
local Masters=H.load("Shared/Masters")
local MastersView=H.load("Shared/MastersView")
local FirstMinute=H.load("Shared/FirstMinute")
local SkillTrees=H.load("Shared/SkillTrees")
local HubMap=H.load("Shared/HubMap")

local function flat(v) return V.new(v.X,0,v.Z) end
local function r1(x) return math.floor(x*10+.5)/10 end

-- The cheapest look of the market (sold for Ryō).
function Bot.cheapestMarket()
	local best=nil
	for _,item in Shop.Items do
		if item.ryo and (not best or item.ryo<best.ryo) then best=item end
	end
	return best
end
-- The cheapest first-tier node of a kit's tree that needs no other node.
function Bot.cheapestNode(kit)
	local tree=SkillTrees[kit]
	local best=nil
	for _,node in (tree and tree.Nodes) or {} do
		local free=node.Requires==nil and node.RequiresAny==nil
		if (node.Tier or 1)==1 and free and (not best or node.Cost<best.Cost) then best=node end
	end
	return best
end
-- (vague 2, OUTILLEUR 2) Every look of the catalogue has its icon for the
-- screens (tools/icons/renders, tools/icons/render_icons.py) and its model in
-- the game: the ANIMATEUR's modelled pieces for an outfit slot
-- (Shared/OutfitMeshes), the props the game builds itself for the weapons and
-- the headband (Client/Effects, Server/Headband).
Bot.BuiltByGame={kunai=true,shuriken=true,tanto=true,gourd=true,headband=true}
Bot.Icons="tools/icons/renders"
function Bot.collection()
	local Meshes=H.load("Shared/OutfitMeshes")
	local out={looks=0,none=0,slots={},noIcon={},noModel={},unknownSlot={}}
	for _,item in Shop.Items do
		out.slots[item.slot]=(out.slots[item.slot] or 0)+1
		if not Shop.Slots[item.slot] then table.insert(out.unknownSlot,item.id.." ("..item.slot..")") end
		if item.none then out.none+=1;continue end
		out.looks+=1
		if not fs.isFile(Bot.Icons.."/"..item.id..".png") then table.insert(out.noIcon,item.id) end
		if not (Bot.BuiltByGame[item.slot] or Meshes.forItem(item.id)) then table.insert(out.noModel,item.id) end
	end
	return out
end
-- (vague 2, DEV 5) The daily quests, once the game has them: their module.
function Bot.questsModule()
	for _,dir in {"Shared","Server"} do
		for _,name in fs.readDir("src/"..dir) do
			if string.find(name,"Quest") and string.match(name,"%.luau$") then return dir.."/"..string.gsub(name,"%.luau$","") end
		end
	end
	return nil
end
-- The walks of a new player in Konoha, straight lines at walk speed: the gate
-- to the three inspirations at the door, then to the chosen one's home.
function Bot.walks(kit)
	local walk=Bot.walkSpeeds()
	local gate=HubMap.Spawns.gate.at
	local welcome=HubMap.Welcome[kit] and HubMap.Welcome[kit].at or gate
	local home=HubMap.Masters[kit] and HubMap.Masters[kit].at or welcome
	local toDoor=flat(welcome-gate).Magnitude
	local toHome=flat(home-welcome).Magnitude
	return {toDoor=r1(toDoor),toHome=r1(toHome),walk=walk,doorSeconds=r1(toDoor/walk),homeSeconds=r1(toHome/walk)}
end

-- ----------------------------------------------------------------- one run
-- Bot.run(kit) -> report {kit, steps={{id, ok, detail}}, ok, failed, firstHit, loop, result}
function Bot.run(kit)
	kit=kit or "Leaf"
	local report={kit=kit,steps={},ok=true}
	local inbox={}
	local remote={FireClient=function(_,player,data) inbox[player]=data end}
	Config.Progression.Enabled=true
	Progression.repo=nil;Progression.init(Repo.memoryStore())
	local m=Matches.new(remote)
	Bot.runs=(Bot.runs or 0)+1
	local player={UserId=7000+Bot.runs,Name="LoopBot"..Bot.runs,DisplayName="LoopBot",Parent=H.Players}
	local s=nil
	local function send(action,extra)
		s.lastLifecycle=-10;s.bucket.tokens=100
		local payload={action=action,epoch=s.epoch}
		for k,v in extra or {} do payload[k]=v end
		m:request(player,payload)
	end
	local function step(seconds)
		for _=1,math.max(1,math.ceil(seconds/.02)) do clock+=.02;m:update(.02,clock);runTimers() end
	end
	local function move(dir)
		s.moveBucket={tokens=100,time=os.clock()}
		send("Move",{direction=dir})
		s.human.lastMove=os.clock()+60
	end
	local function press(action)
		AntiCheat.clear(s.human)
		send(action,{clientTime=clock})
	end
	local function notice() return inbox[player] and inbox[player].notice end
	local function view() return Progression.view(player) end
	-- One step: a function returning its detail; an error stops the run.
	local function stage(id,fn)
		if not report.ok then return end
		local ok,detail=pcall(fn)
		table.insert(report.steps,{id=id,ok=ok,detail=if ok then detail else tostring(detail)})
		if not ok then report.ok=false;report.failed=id end
	end
	local duels=0
	-- A duel against the AI at normal level, two different jutsu, won or lost.
	local function duel(won)
		send("Start",{player=kit,bot=FirstMinute.rival(kit) or "Lion",level="normal"})
		assert(s.phase=="Duel","the duel did not start: "..tostring(notice()))
		s.human.usedJutsu={Technique1=true,Technique2=true}
		for _=1,2 do
			if s.phase~="Duel" then break end
			if won then s.finish(s.human,s.bot) else s.finish(s.bot,s.human) end
			s.finishing=false;s.phase="Duel"
		end
		local progress=s.progress
		m:selection(player);table.clear(timers)
		duels+=1
		return progress
	end

	stage("arrivee",function()
		m:selection(player)
		s=m.sessions[player]
		assert(s and s.phase=="Selection","no session on arrival")
		assert(Progression.load(player),"the profile did not load")
		local v=view()
		assert(v and v.needStarter,"a new player already has a kit")
		assert(not Shop.dressed(v.style),"a new player arrives dressed")
		return "profil chargé, aucun kit, pas habillé"
	end)

	stage("inspiration",function()
		assert(Masters.isStarter(kit),kit.." is not one of the three starters")
		send("ChooseStarter",{player=kit})
		assert(notice()==nil,"refused: "..tostring(notice()))
		assert(Progression.owns(player,kit) and view().selected==kit,"the starter was not taken")
		return "kit "..kit.." appris et choisi"
	end)

	stage("tenue",function()
		local worn={}
		for _,slot in {"top","bottom","feet"} do
			local item=nil
			for _,x in Shop.inSlot(slot) do if x.base and not x.none then item=x;break end end
			assert(item,"no free piece for "..slot)
			send("EquipItem",{item=item.id})
			assert(notice()==nil,"refused "..item.id..": "..tostring(notice()))
			table.insert(worn,item.id)
		end
		local v=view()
		assert(Shop.dressed(v.style),"still not dressed after "..table.concat(worn,", "))
		for i,slot in {"top","bottom","feet"} do assert(v.style.equipped[slot]==worn[i],"not worn: "..worn[i]) end
		return "porte "..table.concat(worn,", ")
	end)

	-- The first minute: the prompts against the rival, the first hit landed.
	local sim={}
	stage("duel",function()
		local started=clock
		send("First",{player=kit})
		assert(s.phase=="Duel" and s.tutorial and s.tutorial.first,"the first minute did not start: "..tostring(notice()))
		local rival=s.botId
		local baseHits=(s.human.events and s.human.events.Hit) or 0
		local index,entered,moving,nextPress=nil,clock,false,0
		local hitAt=nil
		local presses=0
		while clock-started<45 do
			local t=s.tutorial
			if not t then break end
			if t.index~=index then index=t.index;entered=clock;moving=false end
			local id=t.steps[t.index].id
			if clock-entered>=Bot.UI.readPrompt then
				if id=="move" then
					if not moving then
						moving=true
						local dir=flat(s.bot.root.Position-s.human.root.Position)
						move(if dir.Magnitude>.1 then dir.Unit else V.new(0,0,-1))
					end
				else
					if moving then moving=false;move(V.zero) end
					if clock>=nextPress then
						-- a step closer when the strikes do not reach
						if presses>0 and presses%3==0 then
							local dir=flat(s.bot.root.Position-s.human.root.Position)
							if dir.Magnitude>3 then move(dir.Unit);step(.15);move(V.zero) end
						end
						press("Attack");presses+=1;nextPress=clock+.3
					end
				end
			end
			step(.02)
			if ((s.human.events and s.human.events.Hit) or 0)>baseHits then hitAt=clock;break end
		end
		assert(hitAt,string.format("no hit landed in %.0f s (prompt %s, %d presses, gap %.1f studs, state %s)",clock-started,
			tostring(s.tutorial and s.tutorial.steps[s.tutorial.index].id),presses,(s.bot.root.Position-s.human.root.Position).Magnitude,tostring(s.human.state)))
		-- the move prompt must be done by moving, not given up after its 25 s
		local moved=s.tutorial and s.tutorial.report and s.tutorial.report[1]
		assert(moved and moved.id=="move" and moved.status=="PASS","the move prompt was not passed by moving ("..tostring(moved and moved.status)..")")
		sim.firstHit=hitAt-started
		sim.presses=presses
		sim.rival=rival
		-- the rest of the prompts held to skip, as the screen offers; the real duel won
		send("TutorialSkip")
		step(.1)
		assert(s.tutorial==nil and s.firstStage=="duel" and s.phase=="Duel","holding the skip did not start the real duel")
		assert(Matches.aiLevel(s)=="easy","the first duel is not against the easy AI")
		s.finish(s.human,s.bot);step(3.2)
		if s.phase=="Duel" then s.finish(s.human,s.bot);step(3.2) end
		assert(s.phase=="Result","the first duel did not end (phase "..tostring(s.phase)..")")
		duels+=1
		return string.format("premier coup %.1f s après l'entrée en duel (%d frappes), duel contre %s gagné",sim.firstHit,presses,tostring(rival))
	end)

	stage("gains",function()
		local p=s.progress
		assert(type(p)=="table","the result screen gets nothing")
		assert(p.gained and (p.amount or 0)>0,"no mastery on the result screen")
		assert((p.ryo or 0)>0,"no Ryō on the result screen")
		assert(p.firstWin,"the day's first win is not marked")
		local line=MastersView.result(p,view())
		assert(type(line)=="string" and string.find(line,"MASTERY") and string.find(line,"RYŌ"),"the result line: "..tostring(line))
		report.result={line=line,progress=p}
		-- (plan DEV 6) what the screen should also say; not there yet
		local missing={}
		if p.nextNode==nil and p.toNode==nil then table.insert(missing,"le prochain nœud") end
		if p.nextMaster==nil and p.duelsToMaster==nil then table.insert(missing,"l'inspiration suivante") end
		report.result.missing=missing
		m:selection(player);table.clear(timers)
		return line..(if #missing>0 then "  (pas encore : "..table.concat(missing,", ")..", tâche DEV 6)" else "")
	end)

	-- The loop: duels won until the market's cheapest look and the tree's
	-- cheapest node are affordable (each counted when it first is); one look
	-- bought and worn, one node learned.
	local loop={}
	local item=Bot.cheapestMarket()
	local node=Bot.cheapestNode(kit)
	local function free() local tree=view().trees and view().trees[kit];return tree and tree.free or 0 end
	local itemAt,nodeAt=nil,nil
	local function look()
		if item and not itemAt and (view().ryo or 0)>=item.ryo then itemAt=duels end
		if node and not nodeAt and free()>=node.Cost then nodeAt=duels end
	end
	stage("marche",function()
		assert(item,"the market sells nothing for Ryō")
		look()
		while not itemAt do
			assert(duels<Bot.MaxDuels,string.format("%s (%d Ryō) still out of reach after %d duels (%d Ryō)",item.id,item.ryo,duels,view().ryo or 0))
			duel(true);look()
		end
		local before=view().ryo
		send("BuyItem",{item=item.id})
		assert(notice()==nil,"refused: "..tostring(notice()))
		local v=view()
		assert(v.style.owned[item.id] and v.style.equipped[item.slot]==item.id,"bought but not owned or worn")
		assert(v.ryo==before-item.ryo,"paid "..tostring(before-v.ryo).." for "..item.ryo)
		loop.market={item=item.id,price=item.ryo,duels=itemAt}
		return string.format("%s (%d Ryō) abordable après %d duels gagnés, acheté et porté",item.id,item.ryo,itemAt)
	end)

	stage("arbre",function()
		assert(node,kit.." has no first-tier node without a prerequisite")
		look()
		while not nodeAt do
			assert(duels<Bot.MaxDuels,string.format("%s (%d points) still out of reach after %d duels",node.Id,node.Cost,duels))
			duel(true);look()
		end
		send("LearnNode",{player=kit,node=node.Id})
		assert(notice()==nil,"refused: "..tostring(notice()))
		local tree=view().trees[kit]
		assert(table.find(tree.unlocked,node.Id) and table.find(tree.active,node.Id),"learned but not in the build")
		loop.node={node=node.Id,cost=node.Cost,duels=nodeAt}
		return string.format("%s (%d points) abordable après %d duel(s), appris",node.Id,node.Cost,nodeAt)
	end)

	-- (vague 2) The wardrobe's slots, the new ones included: each slot of the
	-- catalogue is one the wardrobe shows (Shop.SlotOrder), and a free look of
	-- each slot that has one can be worn.
	stage("garderobe",function()
		local worn,empty,hidden={},{},{}
		for slot in Shop.Slots do
			if not table.find(Shop.SlotOrder,slot) then table.insert(hidden,slot) end
		end
		table.sort(hidden)
		assert(#hidden==0,"slots the wardrobe does not show (Shop.SlotOrder): "..table.concat(hidden,", "))
		for _,slot in Shop.SlotOrder do
			local free=nil
			for _,x in Shop.inSlot(slot) do if x.base and not x.none then free=x;break end end
			if not free then table.insert(empty,slot);continue end
			send("EquipItem",{item=free.id})
			assert(notice()==nil,"refused "..free.id..": "..tostring(notice()))
			assert(view().style.equipped[slot]==free.id,free.id.." not worn in "..slot)
			table.insert(worn,slot)
		end
		report.wardrobe={slots=#Shop.SlotOrder,worn=worn,noFree=empty}
		return string.format("%d emplacements ; un objet gratuit porté dans %s%s",#Shop.SlotOrder,table.concat(worn,", "),
			if #empty>0 then " ; rien de gratuit dans "..table.concat(empty,", ") else "")
	end)

	-- (vague 2, DEV 5) The daily quests are not in the game yet: noted, not failed.
	report.pending={}
	if not Bot.questsModule() then table.insert(report.pending,"quêtes du jour (DEV 5)") end

	-- The estimate until the first hit.
	local w=Bot.walks(kit)
	local parts={
		{"arrivée, objectif lu",Bot.UI.arrive},
		{string.format("marche de la porte aux inspirations (%.0f studs)",w.toDoor),w.doorSeconds},
		{"E à l'inspiration, sa fiche",Bot.UI.talk},
		{"choix de l'inspiration",Bot.UI.choose},
		{"tenue (3 choix) et DONE",Bot.UI.dressPerSlot*3+Bot.UI.done},
		{"YOUR FIRST DUEL, à la porte",Bot.UI.askDuel},
		{"première minute jusqu'au coup (simulée)",sim.firstHit or 0},
	}
	local total=0
	for _,p in parts do total+=p[2] end
	report.firstHit={total=r1(total),parts=parts,target=Bot.Target,within=total<=Bot.Target,simulated=sim.firstHit and r1(sim.firstHit)}
	local function minutes(n) return r1(n*(Bot.DuelSeconds+Bot.BetweenDuels)/60) end
	if loop.market then
		loop.market.minutes=minutes(loop.market.duels)
		loop.market.firstSession=loop.market.minutes<=Bot.FirstSession
	end
	if loop.node then loop.node.minutes=minutes(loop.node.duels) end
	report.loop=loop
	report.duels=duels
	Progression.release(player)
	Config.Progression.Enabled=false
	return report
end

-- The report in words (French, as the discussions read it).
function Bot.text(r)
	local out={("LoopBot · %s · %s"):format(r.kit,if r.ok then "boucle complète" else "ÉCHEC à « "..tostring(r.failed).." »")}
	for _,st in r.steps do table.insert(out,("  %s %-12s %s"):format(if st.ok then "OK " else "XX ",st.id,tostring(st.detail))) end
	if r.firstHit then
		table.insert(out,("Premier coup estimé : %.0f s (objectif %d s : %s)"):format(r.firstHit.total,r.firstHit.target,if r.firstHit.within then "tenu" else "DÉPASSÉ"))
		for _,p in r.firstHit.parts do table.insert(out,("     %5.1f s  %s"):format(p[2],p[1])) end
	end
	local l=r.loop or {}
	if l.market then table.insert(out,("Premier achat au marché : %d duels (≈ %.0f min de jeu ; dans une première séance de %d min : %s)"):format(
		l.market.duels,l.market.minutes,Bot.FirstSession,if l.market.firstSession then "oui" else "NON")) end
	if l.node then table.insert(out,("Premier nœud de l'arbre : %d duels (≈ %.0f min de jeu)"):format(l.node.duels,l.node.minutes)) end
	if r.pending and #r.pending>0 then table.insert(out,"Pas encore dans le jeu : "..table.concat(r.pending,", ")) end
	return table.concat(out,"\n")
end

return Bot
