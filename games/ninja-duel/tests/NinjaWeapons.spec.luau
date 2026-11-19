-- The ninja's own weapon (DEC-041): the contract between the DEV and the
-- ANIMATEUR (Shared/NinjaWeapons), checked before any model or clip exists.
-- Equal power: a weapon is a style, never a stronger blade.
local H=require("./Harness")
local passed=0
local function test(name,fn)
	local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)
end
local W=H.load("Shared/NinjaWeapons")
local A=H.load("Shared/Attacks")
local Attacks=A.Attacks or A

test("the eight weapons of DEC-041, each with its model, its rest place and its order",function()
	local want={"Katana","Kusarigama","Tanto","Greatsword","ChakraBlades","FumaShuriken","WarFan","Staff"}
	assert(#W.List==#want,"weapons: "..#W.List)
	for i,id in want do
		local w=W.get(id)
		assert(w and w.Name and w.Note and (w.Rest=="Back" or w.Rest=="Hip"),id.." is incomplete")
		assert(w.Tris and w.Tris>=300 and w.Tris<=2000,id.."'s triangle budget")
		assert(w.Order==i,id.." is not in the agreed order")
	end
	assert(W.get("Katana").Order==1 and W.get("Kusarigama").Order==2,"the katana and the kusarigama first")
end)

test("equal power: slower strikes hit harder by exactly as much; reach is paid in speed",function()
	for _,w in W.List do
		assert(math.abs(w.Damage/w.Speed-1)<1e-9,w.Id.." is not of equal power: damage "..w.Damage.." at speed "..w.Speed)
		-- every stud of reach past the first costs 10 % of speed; a blade
		-- shorter than a stud may be quicker by half its shortfall, no more
		local need=if w.Reach>=1 then 1+(w.Reach-1)*.1 else 1-(1-w.Reach)*.5
		assert(w.Speed>=need-1e-9,w.Id.." reaches "..w.Reach.." at speed "..w.Speed.." (at least "..need..")")
		-- damage per second over the whole string: the hands' own
		local hands,mine,ht,mt=0,0,0,0
		for _,move in W.Moves do
			local base=Attacks[move]
			local t=W.timing(w.Id,move)
			hands+=base.damage;ht+=base.startup+base.active+base.recovery
			mine+=base.damage*w.Damage;mt+=t.startup+t.active+t.recovery
		end
		assert(math.abs((mine/mt)/(hands/ht)-1)<1e-6,w.Id.." changes the damage per second")
	end
end)

test("the contract keeps in step with the hands' strikes (Shared/Attacks)",function()
	for _,move in W.Moves do
		local a,b=Attacks[move],W.Base[move]
		assert(a and b,move.." is missing")
		assert(math.abs(a.startup-b[1])<1e-6 and math.abs(a.active-b[2])<1e-6 and math.abs(a.recovery-b[3])<1e-6,
			move.." changed in Attacks: update NinjaWeapons.Base (and tell the ANIMATEUR the new frame counts)")
	end
end)

test("what the ANIMATEUR authors: clip names and frame counts; what the duel reads",function()
	local clips=W.clips("Katana")
	assert(clips[1]=="Weapon.Katana.Draw" and clips[2]=="Weapon.Katana.Guard" and #clips==2+#W.Moves,"the katana's clips")
	assert(W.frames("Katana","Light1")==math.round((.09+.12+.28)*W.get("Katana").Speed*60),"a strike's frames at 60 per second")
	assert(W.frames("Greatsword","Heavy")>W.frames("Katana","Heavy"),"the great sword is slower")
	local kw=W.asKitWeapon("Kusarigama")
	assert(kw and kw.Reach==3.2 and kw.Damage==1.25 and kw.Moves.Light1 and kw.Own and not kw.Throwable,"the shape Brawler reads")
	assert(W.asKitWeapon("FumaShuriken").Throwable,"the fūma shuriken is thrown")
	assert(W.timing("Nope","Light1")==nil and W.asKitWeapon("Nope")==nil,"an unknown weapon")
end)

print(string.format("NinjaDuel ninja weapons (DEC-041): %d PASS",passed))
