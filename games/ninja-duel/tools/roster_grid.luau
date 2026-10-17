-- Convergence grid (DEC-021): the same measurements for every fighter of the
-- roster, headless, so outliers in the shared grammar show side by side.
-- Run from games/ninja-duel:  lune run tools/roster_grid.luau
-- Columns:
--   str   time from the first press to the third light's contact (s)
--   dmg3  damage of the three lights
--   push  how far the third light sends the body (studs)
--   whiff commitment of a whiffed Light1 (s until he can act again)
--   heavy heavy's startup (s) and damage
--   conv  launcher → chase (E) → air strike: air hits landed (0..3)
--   ko    AI duel vs Leaf: seconds to the KO / techniques used (distinct)
local H=require("../tests/Harness")
local V=H.V
local Roster=H.load("Shared/Roster")
local Rules=H.load("Shared/Rules")
local AI=H.load("Server/AI")
local function place(c,a,b,gap)
	c:relocate(a,V.new(0,3,gap/2));c:relocate(b,V.new(0,3,-gap/2))
	a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);b.root.CFrame=H.C.lookAt(b.root.Position,a.root.Position)
	a.move=V.zero;b.move=V.zero
end
local function flat(v) return V.new(v.X,0,v.Z) end
local function run(c,t,f) for _=1,math.ceil(t/.01) do H.step(c,.01);if f and f() then return true end end return false end
local saved=H.envBase.Random
H.envBase.Random={new=function(seed)
	local state=(seed or 1)*2654435761%4294967296
	local function roll() state=(1103515245*state+12345)%2147483648;return state/2147483648 end
	return {NextNumber=function(_,x,y) local r=roll();if x and y then return x+(y-x)*r end return r end,NextInteger=function(_,x,y) return math.floor(x+(y-x+1)*roll()) end}
end}
print(string.format("%-10s %5s %5s %5s %5s %11s %4s %12s","fighter","str","dmg3","push","whiff","heavy","conv","ko/tech"))
for _,id in Roster do
	-- String.
	local c,a,b=H.duel(id,"Leaf");place(c,a,b,if id=="Sand" or id=="Puppet" then 7 else 3.4);b.health=999
	local t0=c.now
	local contact3=nil
	for k=1,3 do
		c:request(a,"Attack")
		run(c,.9,function()
			if k==3 and not contact3 and b.health<999 and (b.comboHits or 0)>=3 then contact3=c.now-t0 end
			return a.state=="Recovery" and a.chainOpen==true and c.now>=(a.chainAt or 0)
		end)
	end
	local from=b.root.Position
	run(c,.8)
	local dmg3=999-b.health
	local push=flat(b.root.Position-from).Magnitude
	-- Whiff.
	local c2,a2,b2=H.duel(id,"Leaf");place(c2,a2,b2,30)
	c2:request(a2,"Attack")
	local w0=c2.now
	run(c2,2,function() return Rules.canAct(a2,c2.now) and a2.state=="Neutral" and c2.now>w0+.02 end)
	local whiff=c2.now-w0
	-- Heavy.
	local c3,a3,b3=H.duel(id,"Leaf");place(c3,a3,b3,if id=="Sand" or id=="Puppet" then 7 else 3.4);b3.health=999
	c3:request(a3,"Heavy")
	local h0=c3.now;local hs=nil
	run(c3,1.2,function() if not hs and b3.health<999 then hs=c3.now-h0 end return false end)
	local heavyDmg=999-b3.health
	-- Conversion: two lights, toward = launcher, E chase, air strikes.
	local c4,a4,b4=H.duel(id,"Leaf");place(c4,a4,b4,if id=="Sand" or id=="Puppet" then 7 else 3.4);b4.health=999
	for _=1,2 do c4:request(a4,"Attack");run(c4,.9,function() return a4.state=="Recovery" and a4.chainOpen==true and c4.now>=(a4.chainAt or 0) end) end
	a4.move=flat(b4.root.Position-a4.root.Position).Unit
	c4:request(a4,"Attack");a4.move=V.zero
	run(c4,.35)
	local launched=b4.reaction=="Launched" or b4.airborne
	local airHits=0
	if launched then
		c4:request(a4,"Pursuit");run(c4,.45)
		local before=b4.health
		for _=1,3 do
			c4:request(a4,"Attack");run(c4,.35)
			if b4.health<before then airHits+=1;before=b4.health end
		end
	end
	-- AI duel.
	local c5,x,y,match=H.duel(id,"Leaf");place(c5,x,y,14)
	local one,two=AI.new(c5,x,7),AI.new(c5,y,9)
	local t=0
	while match.phase=="Duel" and t<120 do one:update(c5.now);two:update(c5.now);H.step(c5,.01);t+=.01 end
	local used,distinct=0,0
	for k,v in x.events or {} do if k=="Technique" then used=v end end
	local seen={}
	for _,spec in x.def.Techniques do if (x.cooldowns[spec.Id] or 0)>0 then seen[spec.Id]=true end end
	for _ in seen do distinct+=1 end
	print(string.format("%-10s %5s %5.1f %5.1f %5.2f %5s/%5.1f %4s %5.0fs %2d/%d %s",id,contact3 and string.format("%.2f",contact3) or "--",dmg3,push,whiff,
		hs and string.format("%.2f",hs) or "--",heavyDmg,launched and tostring(airHits) or "noL",t,used,distinct,if match.winner then (match.winner==x.id and "W" or "L") else "-"))
end
H.envBase.Random=saved
