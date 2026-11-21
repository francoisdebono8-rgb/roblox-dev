-- The robot débutant on the first combat (OUTILLEUR, 21/11; DEC-047, step 3,
-- OUTILLEUR 2): a newcomer who presses late and not always the right key
-- (tools/duelbot/PlayerSim, "debutant") plays the real first combat (the
-- novice, AI "first", and Server/Coach) with each kit of the beta, as a
-- new player has it (no node of its tree), three seeds each. The proof that the first combat is short and won: he wins,
-- under 90 s of fight (the 2.6 s intro is not counted here), and meets at
-- least three of the coach's prompts. The same robot plays it in Studio,
-- through the game's remote (tools/duelbot/studio_bot.luau).
local H=require("./Harness")
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local Config=H.load("Shared/Config")
Config.DamageScale=H.GameDamageScale
local mods={PlayerSim=require("../tools/duelbot/PlayerSim"),AI=H.load("Server/AI"),Coach=H.load("Server/Coach"),
	FirstMinute=H.load("Shared/FirstMinute"),Config=Config,SkillBuilds=H.load("Server/SkillBuilds")}
local Sim=require("../tools/duelbot/Sim")

local SEEDS=3
local LIMIT=90
local passed,times,fails=0,{},{}
-- each prompt: how often it came, how often the newcomer did it
local promptSeen,promptDone,techRefused={}, {}, {}
for _,kit in {"Lion","Legion","Leaf","Flashstep","Mirage","GentleFist","Copycat","Sand"} do
	for seed=1,SEEDS do
		H.clearWalls()
		local r=Sim.first(H,mods,kit,seed,"debutant")
		local steps={}
		for _,p in r.prompts do table.insert(steps,string.format("%s@%.0f%s",p.id,p.shown,if p.done then "✓" else "")) end
		local line=string.format("%-10s vs %-10s seed %d  %5.1f s  %s  me %3.0f%%  him %3.0f%%  presses %d (refused %d)  %s",
			r.kit,r.rival,seed,r.t,if r.won then "WON " else "LOST",100*r.health,100*r.hisHealth,r.presses,r.refused,table.concat(steps," "))
		table.insert(times,r.t)
		local met,did={}, {}
		for _,p in r.prompts do met[p.id]=true;if p.done then did[p.id]=true end end
		for id in met do promptSeen[id]=(promptSeen[id] or 0)+1 end
		for id in did do promptDone[id]=(promptDone[id] or 0)+1 end
		for key,n in r.reasons do if string.match(key,"^Technique") then techRefused[key]=(techRefused[key] or 0)+n end end
		local why=nil
		if not r.won then why="the newcomer did not win"
		elseif r.t>=LIMIT then why="longer than "..LIMIT.." s"
		elseif #r.seen<3 then why="fewer than three prompts" end
		if why then table.insert(fails,line.."  <- "..why);print("FAIL "..line.."  <- "..why)
		else passed+=1;print("PASS "..line) end
	end
end
table.sort(times)
local sum=0 for _,t in times do sum+=t end
print(string.format("DuelBot first combat: %d / %d won under %d s; fight %.0f s median (%.0f to %.0f), mean %.0f",
	passed,#times,LIMIT,times[math.ceil(#times/2)],times[1],times[#times],sum/#times))
local parts={}
for _,id in {"move","strike","guard","signature","grab","tool","escape"} do
	table.insert(parts,string.format("%s %d/%d",id,promptDone[id] or 0,promptSeen[id] or 0))
end
print("DuelBot prompts done / fights where it came: "..table.concat(parts,", "))
local refused={}
for key,n in techRefused do table.insert(refused,key.." "..n) end
table.sort(refused)
print("DuelBot jutsu presses refused: "..table.concat(refused,", "))
assert(#fails==0,#fails.." first combats failed:\n"..table.concat(fails,"\n"))
print(string.format("DuelBot: %d passed",passed))
