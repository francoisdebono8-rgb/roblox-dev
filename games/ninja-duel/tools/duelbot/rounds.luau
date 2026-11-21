-- The real length of a round (OUTILLEUR, 21/11; DEC-047, step 3, OUTILLEUR 3).
-- François (DEC-046): 2 rounds won, of 30 to 40 s each. The DEV measured 37 s
-- with the AI on both sides; here a player at the keys (PlayerSim "joueur":
-- he sees and presses late, guards a wind-up one time in two) faces the AI
-- of the duels (easy: the first duels; normal), at several damage scales.
--
--   lune run tools/duelbot/rounds.luau [seeds] [scales] [profiles] [levels]
--   lune run tools/duelbot/rounds.luau 2 0.6,0.8,1 joueur,debutant easy,normal
local H=require("../../tests/Harness")
local process=require("@lune/process")
H.envBase.Random={new=function(seed)
 local state=(seed or 1)*2654435761%4294967296
 local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
 return {NextNumber=function(_,a,b) local r=roll();if a and b then return a+(b-a)*r end return r end,
  NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*roll()) end}
end}
local Config=H.load("Shared/Config")
local game=H.GameDamageScale
local mods={PlayerSim=require("./PlayerSim"),AI=H.load("Server/AI"),Coach=H.load("Server/Coach"),
	FirstMinute=H.load("Shared/FirstMinute"),Config=Config}
local Sim=require("./Sim")

local seeds=tonumber(process.args[1]) or 2
local scales={}
for v in string.gmatch(process.args[2] or tostring(game),"[^,]+") do table.insert(scales,tonumber(v)) end
local profiles={}
for v in string.gmatch(process.args[3] or "joueur","[^,]+") do table.insert(profiles,v) end
local levels={}
for v in string.gmatch(process.args[4] or "easy,normal","[^,]+") do table.insert(levels,v) end
local kits={"Lion","Legion","Leaf","Flashstep","Mirage","GentleFist","Copycat","Sand"}

local function stats(list)
	table.sort(list)
	local sum=0 for _,t in list do sum+=t end
	local inside=0 for _,t in list do if t>=30 and t<=40 then inside+=1 end end
	return list[math.ceil(#list/2)],sum/#list,list[1],list[#list],inside
end

print(string.format("Rounds: a player (PlayerSim) against the duel's AI, %d seeds, the game's DamageScale %.2f",seeds,game))
for _,profile in profiles do
for _,scale in scales do
	Config.DamageScale=scale
	for _,level in levels do
		local all,won,byKit={},0,{}
		for i,kit in kits do
			local rival=kits[(i%#kits)+1]
			byKit[kit]={}
			for seed=1,seeds do
				H.clearWalls()
				local r=Sim.round(H,mods,kit,rival,level,seed,profile)
				table.insert(all,r.t);table.insert(byKit[kit],r.t)
				if r.won then won+=1 end
				print(string.format("  %-8s scale %.2f %-6s %-10s vs %-10s seed %d  %5.1f s  %s  me %3.0f%%  him %3.0f%%%s",profile,scale,level,kit,rival,seed,r.t,
					if r.won then "won " else "lost",100*r.health,100*r.hisHealth,if r.timeout then "  (150 s, no K.O.)" else ""))
			end
		end
		local median,mean,lo,hi,inside=stats(all)
		print(string.format("ROUNDS %-8s scale %.2f %-6s median %.0f s, mean %.0f s (%.0f to %.0f), %d / %d in 30-40 s, the player won %d / %d",
			profile,scale,level,median,mean,lo,hi,inside,#all,won,#all))
		local line={}
		for _,kit in kits do local m=stats(byKit[kit]);table.insert(line,string.format("%s %.0f",kit,m)) end
		print("  by kit (median s): "..table.concat(line,", "))
	end
end
end
