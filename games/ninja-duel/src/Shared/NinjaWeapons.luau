-- The ninja's own weapon (DEC-041, user 14/11: « une arme personnelle vue dans
-- Naruto […] choisie et achetée par le joueur, indépendante du kit, avec ses
-- propres coups à puissance égale »). The contract between the DEV and the
-- ANIMATEUR (plan « vague 2 », DEV 3), written before any model or clip:
--
-- * WHAT THE ANIMATEUR MAKES, per weapon:
--   - the model `NinjaWeapon_<Id>` (Blender → the game's mesh data, like the
--     kit objects): its origin is the grip, held in the right hand; +Y runs
--     from the grip to the tip; it sits sheathed at `Rest` (Back, Hip) when
--     not drawn. Triangle budget: `Tris`.
--   - the clips, named by NinjaWeapons.clip(id, move): `Weapon.<Id>.Draw`,
--     `.Guard` (held, loops), and one per move of `Moves`. A strike's clip
--     lasts its timings (NinjaWeapons.timing: startup, active, recovery, in
--     seconds, at 60 frames a second) and lands its contact inside `active`.
-- * WHAT THE DEV DOES with them (DEV 8): drawn (the draw button, B / pad),
--   the weapon replaces the hands' strikes listed in `Moves`, as a kit's own
--   blade does today (Fighters: def.Weapon, Brawler.start: Reach, Contact,
--   Damage); never thrown unless `Throwable`.
-- * EQUAL POWER: a weapon is a style, never a stronger blade. Slower strikes
--   hit harder by exactly as much (`Damage` / `Speed` = 1, checked by
--   tests/NinjaWeapons.spec), and every stud of reach past the first is paid
--   in speed (at least 10 % slower per stud); a blade shorter than a stud
--   may be quicker, by half its shortfall at most. Kakashi's tanto (a kit object
--   earned on his tree) stays apart: it is the kit's, not the ninja's.
-- * SOLD as a look in the SHOP (Robux, CM study: 199 R) and some at the
--   market (Ryō): Shared/Catalog, slot "weapon", once its clips exist.
-- Order (vague 2): the katana and the kusarigama first, the six others after.
local W={}

-- The hands' strikes a weapon replaces when drawn (Shared/Attacks names).
W.Moves={"Light1","Light2","Light3","Heavy","DashAttack","Air1"}
-- The base timings a weapon's strike scales (Shared/Attacks at the time of the
-- contract: startup, active, recovery). The DEV keeps them in step with Attacks.
W.Base={Light1={.09,.12,.28},Light2={.10,.12,.27},Light3={.12,.14,.24},Heavy={.30,.17,.52},DashAttack={.07,.15,.27},Air1={.08,.13,.18}}

W.List={
	{Id="Katana",Name="KATANA",Kind="blade",Rest="Back",Reach=1.6,Contact=.9,Speed=1.06,Damage=1.06,Tris=1200,
		Order=1,Note="A long single-edged sword, the ANBU's: clean draws and wide cuts."},
	{Id="Kusarigama",Name="KUSARIGAMA",Kind="chain",Rest="Hip",Reach=3.2,Contact=1.2,Speed=1.25,Damage=1.25,Tris=1400,
		Order=2,Note="A sickle on a chain: the chain reaches far, the sickle comes back. Slow to wind up."},
	{Id="Tanto",Name="TANTO",Kind="blade",Rest="Hip",Reach=.8,Contact=.6,Speed=.9,Damage=.9,Tris=700,
		Order=3,Note="A short blade held close: quicker cuts, a shorter reach."},
	{Id="Greatsword",Name="GREAT SWORD",Kind="greatsword",Rest="Back",Reach=2.6,Contact=1.1,Speed=1.3,Damage=1.3,Tris=1600,
		Order=4,Note="A great cleaver of a sword (the Mist's kind, our own design): heavy swings, wide arcs."},
	{Id="ChakraBlades",Name="CHAKRA BLADES",Kind="blade",Rest="Hip",Reach=.6,Contact=.6,Speed=.85,Damage=.85,Tris=900,
		Order=5,Note="Two trench knives, one in each hand: fast, close, relentless."},
	{Id="FumaShuriken",Name="FŪMA SHURIKEN",Kind="thrown",Rest="Back",Reach=2.0,Contact=1.0,Speed=1.15,Damage=1.15,Tris=1100,Throwable=true,
		Order=6,Note="The great folding shuriken: swung close, thrown on the heavy strike."},
	{Id="WarFan",Name="WAR FAN",Kind="fan",Rest="Back",Reach=1.4,Contact=.9,Speed=1.05,Damage=1.05,Tris=1000,
		Order=7,Note="An iron fan: sweeping blows that push the body away."},
	{Id="Staff",Name="BŌ STAFF",Kind="staff",Rest="Back",Reach=2.4,Contact=1.0,Speed=1.15,Damage=1.15,Tris=500,
		Order=8,Note="A long staff: reach and rhythm, both ends strike."},
}
W.ById={}
for _,w in W.List do W.ById[w.Id]=w end
function W.get(id) return W.ById[id] end

-- The clip a weapon's move plays: `Weapon.<Id>.<Move>` (also Draw, Guard).
function W.clip(id,move) return "Weapon."..id.."."..move end

-- A strike's timings with this weapon: {startup, active, recovery} in seconds.
function W.timing(id,move)
	local w,base=W.ById[id],W.Base[move]
	if not w or not base then return nil end
	-- every phase at the weapon's pace: damage over time stays the hands' own
	return {startup=base[1]*w.Speed,active=base[2]*w.Speed,recovery=base[3]*w.Speed}
end
-- Frames of a strike's clip at 60 frames a second (what the ANIMATEUR authors).
function W.frames(id,move)
	local t=W.timing(id,move)
	if not t then return nil end
	return math.round((t.startup+t.active+t.recovery)*60)
end
-- The clips a weapon needs, in order: Draw, Guard, then each move.
function W.clips(id)
	local out={W.clip(id,"Draw"),W.clip(id,"Guard")}
	for _,move in W.Moves do table.insert(out,W.clip(id,move)) end
	return out
end
-- The shape the duel already knows for a carried blade (Fighters: def.Weapon):
-- what Brawler.start reads once the weapon is wired (DEV 8).
function W.asKitWeapon(id)
	local w=W.ById[id]
	if not w then return nil end
	local moves={}
	for _,move in W.Moves do moves[move]=true end
	return {Kind=w.Id,Name=w.Name,Reach=w.Reach,Contact=w.Contact,Damage=w.Damage,Throwable=w.Throwable==true,Moves=moves,Own=true}
end

return W
