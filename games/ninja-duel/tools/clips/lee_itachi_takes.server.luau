-- Video 01 « HE RAN INTO THE WRONG ITACHI » (storyboard CM_ANIME_GRADE_DUELS,
-- branche media-clips) : prises dirigées Lee contre Itachi, Studio Play
-- (Debug) seulement. Lancé par execute_luau (Server) après avoir installé
-- _G.devcall (le canal d'attributs NDDev de DevHooks) et démarré le duel
-- (devcall("start","Leaf","Mirage")).
--
-- Une prise = une suite de « beats ». Chaque beat repose les deux corps
-- (le montage coupe au début du beat, comme le veut la procédure des shorts)
-- puis joue de vraies requêtes du combat. Un refus ou un coup qui ne touche
-- pas est écrit dans le journal : la prise est à rejeter, jamais maquillée.
--
-- Valeurs vérifiées dans Studio le 05/11 (Lee = Leaf, Itachi = Mirage) :
--   B2 shuriken réelles, esquive diagonale de Lee : 0 PV perdu
--   B3 deux coups (130 -> 121) puis Leaf Great Whirlwind (-> 117, recul 17 studs)
--   B4 Mirage : Itachi recule de 5,5 studs, Lee frappe l'image (MirageCatch,
--      Lee étourdi 0,55 s), CounterPalm immédiat : Lee 140 -> 130,7, recul 12
--      studs. La riposte doit partir sur la capture : 0,6 s plus tard, elle rate.
--   B5 Dynamic Entry sous un autre angle, Itachi esquive : les deux restent libres
local HS=game:GetService("HttpService")
local dev=_G.devcall
assert(dev,"install _G.devcall first")
local function state() return HS:JSONDecode(dev("state")) end
local log={}
local t0=os.clock()
local function note(fmt,...) table.insert(log,string.format("%5.2f ",os.clock()-t0)..string.format(fmt,...)) end
local function snap(tag)
	local s=state()
	note("%s Lee(%s %s %.1f,%.1f hp%.1f) Itachi(%s %s %.1f,%.1f hp%.1f)",tag,s.human.state,tostring(s.human.attackName),
		s.human.position[1],s.human.position[3],s.human.health,s.bot.state,tostring(s.bot.attackName),s.bot.position[1],s.bot.position[3],s.bot.health)
	return s
end
local function act(who,action,aim)
	local r=dev("act",who,action,aim)
	local ok=r~=nil and r:find('"ok":true')~=nil
	note("  %s %s -> %s",who,action,if ok then "ok" else tostring(r))
	return ok
end
-- devcall "move" expires after ~0.4 s without a fresh packet: renewed.
local function hold(who,dir,seconds,sprint)
	local t=os.clock()
	while os.clock()-t<seconds do
		dev("move",who,dir)
		if who=="human" and sprint~=nil then dev("sprint","human",sprint) end
		task.wait(.1)
	end
end
local beatIndex=0
-- A beat starts once both bodies are free: a body still in the last beat's
-- knockback is not caught by the image (Studio: 2 of 3 misses at 0.8 s,
-- 3 of 3 caught at 1.2 s).
local function beat(name,lee,itachi,settle)
	dev("move","human",{0,0,0});dev("move","bot",{0,0,0});dev("sprint","human",false)
	dev("refill");dev("place",lee,itachi)
	beatIndex+=1
	workspace:SetAttribute("NDBeat",beatIndex)
	task.wait(settle or .7)
	note("== B%d %s",beatIndex,name)
end

function _G.LeeItachiTake(n)
	table.clear(log);t0=os.clock();beatIndex=0
	workspace:SetAttribute("NDTake",n or 1)
	dev("scripted",true);dev("freezeBot",true)
	note("TAKE %d",n or 1)
	-- B1 0.00-1.25 : Lee déjà lancé vers Itachi, change d'angle.
	beat("course",{0,3,22},{0,3,-4})
	hold("human",{0,0,-1},.3,true)
	hold("human",{.5,0,-.85},.2,true)
	snap("arrivée")
	-- B2 1.25-3.40 : les vraies shuriken, l'esquive en diagonale.
	beat("shuriken",{0,3,12},{0,3,-4})
	act("bot","Technique1",Vector3.new(0,3,12))
	task.wait(.18)
	dev("move","human",{-.7,0,-.7});act("human","Dodge")
	task.wait(.75);snap("après l'esquive")
	-- B3 3.40-5.60 : deux coups puis le grand coup de pied tournant.
	beat("échange",{0,3,1.6},{0,3,-2.4})
	act("human","Attack");task.wait(.3)
	act("human","Attack");task.wait(.35)
	act("human","Technique1");task.wait(.65)
	snap("après le Whirlwind")
	-- B4 5.60-11.20 : le Mirage, la frappe dans l'image, la vraie punition.
	beat("mirage",{0,3,8},{0,3,1},1.2)
	act("bot","Technique3")
	task.wait(.55)
	act("human","Attack")
	local caught=false
	local t=os.clock()
	while os.clock()-t<1 do
		if state().human.state=="Stunned" then caught=true;break end
		task.wait()
	end
	note("  Lee pris par l'image : %s",tostring(caught))
	-- Itachi strikes the first frame he can (his cast's recovery may still run).
	if caught then
		local t2=os.clock()
		while os.clock()-t2<.6 do
			if dev("act","bot","Attack"):find('"ok":true') then note("  bot Attack -> ok (riposte)");break end
			task.wait()
		end
	end
	task.wait(.6);snap("après la riposte")
	-- B5 11.20-14.70 : Lee répond, Dynamic Entry sous un autre angle.
	beat("retour",{9,3,10},{0,3,0})
	act("human","Technique4",Vector3.new(0,3,0))
	task.wait(.12);act("bot","Dodge")
	task.wait(.9);snap("après la Dynamic Entry")
	-- B6 14.70-17.50 : les deux repartent l'un vers l'autre (coupe sur l'élan).
	beat("relance",{0,3,14},{0,3,-2})
	for _=1,4 do dev("move","human",{0,0,-1});dev("sprint","human",true);dev("move","bot",{0,0,1});task.wait(.1) end
	act("human","Jump")
	task.wait(.6)
	dev("move","human",{0,0,0});dev("move","bot",{0,0,0});dev("sprint","human",false)
	dev("scripted",false)
	note("TAKE %d end",n or 1)
	return table.concat(log,"\n")
end
return "LeeItachiTake ready"
