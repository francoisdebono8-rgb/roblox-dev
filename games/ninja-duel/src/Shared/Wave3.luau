-- Roster 20, batch 3 (DEC-022): Deidara, Sasori, Nagato, Killer Bee. This
-- batch's shared data, merged into Fighters, MoveGraphs and Attacks (see
-- Wave1). Young versions only: what each of them could already do then.
local RosterMoves=require(script.Parent.RosterMoves)
local V=Vector3.new

local fighters={}
-- Deidara (15, Iwa's Explosion Corps): moulded clay, C1 only. His loop is
-- set → threaten → detonate: birds and spiders that miss stay where they
-- stop as charges, a landmine is buried where he aims; a body that steps on
-- one is blasted, and "Katsu!" sets every one of them off from anywhere (and
-- pops the clay at his feet). Clay pellets as his tool.
-- No C2 dragon, no C4, no owl flight: later.
fighters.Clay = {
	Name = "Deidara", FullName = "Deidara", Age = 15, Title = "THE CLAY ARTIST", Color = { 236, 196, 90 },
	Routes = "↑ launcher  ·  ↓ sweep  ·  ←→ feint step  ·  heavy after one: clay pop (a blast that throws the body away)  ·  air: drive / spike / switch",
	Description = "Explosive clay, C1: birds, spiders, a landmine, a Katsu! burst. Art is an explosion — at range.",
	Health = 118, Chakra = 125, ChakraRegen = 8.2, Speed = 18.5, SprintScale = 1.1, JumpScale = 1.05, AirControlScale = 1.05, AccelerationScale = 1.0,
	CombatTravel = 0.95, CombatDamage = 0.9, DashScale = 1.0, GuardStrength = 0.1, PreferredRange = 16,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	-- Two clay pellets flicked from the palm; each one pops on contact.
	ToolMastery = { Kind = "kunai", Projectile = "clay", Count = 2, Speed = 80, Damage = 2.4, Recover = .7, Contact = { Knock = 18, Lift = 6 } },
	-- Awakening: art is an explosion. Every blast bites deeper, the clay comes
	-- cheaper and back sooner.
	-- Rule: his charges arm at once and a blast sets off every charge of his
	-- near it (a field of clay becomes a chain).
	Awakening = { Name = "ART IS AN EXPLOSION", Speed = 1.04, Damage = 1.1, Regen = 1.3, Cooldown = 0.7, ChainCharges = true, Color = { 255, 210, 120 } },
	Motion = { body = "Mirage", weapons = "none", springy = false,
		borrow = { ClayPop = "Heavy" },
		-- Cocky and side-on, one hand in the clay pouch at the hip, the other
		-- up with a bird already moulded in the palm.
		stance = {root={y=-.24,pitch=0,yaw=34},torso={pitch=-2,yaw=-14},head={pitch=-6,yaw=-20},
			ra={raise=-10,out=30,twist=-40,elbow=90,wrist=10},la={raise=70,out=-6,twist=-60,elbow=90,wrist=-20},
			rf={x=.22,z=.62,yaw=34},lf={x=-.08,z=-.56,yaw=-6},breath=.8,tempo=5} },
	AttackProfile = {
		Light1={startup=.96,recovery=.94,travel=.95},Light2={startup=.98,recovery=.94,travel=.95,kind="palm"},
		Light3={startup=1.02,recovery=1.0,impulseZ=58,kind="kick"},Heavy={startup=1.0},
		Launcher={startup=1.0,impulseY=54},DashAttack={startup=.96},Air1={startup=.96},Air2={startup=.98},
	},
	Skin = { 236, 214, 190 }, Hair = { 240, 210, 110 }, Outfit = { 60, 64, 80 },
	Techniques = {
		{ Id = "ClayBirds", Name = "C1: Clay Birds", Family = "Projectile", Kind = "claybird", Cost = 18, Channel = 0.3, Active = 0.06, Recovery = 0.3, Cooldown = 4.5, Interruptible = true,
			Range = 40, Speed = 54, Damage = 7, Count = 2, Spread = 0.35, Radius = 1.6, Knock = 32, Lift = 16,
			Zone = { Radius = 4, Time = 1.6, Damage = 2, Kind = "Fire", Look = "clay" },
			Charge = { Trigger = 2.8, Radius = 5, Damage = 7, Knock = 30, Lift = 18, Arm = .4, Life = 8, Look = "claycharge" },
			Hint = "Two clay birds fly at the body and burst • a bird that misses lands and waits (a charge)" },
		{ Id = "ClaySpiders", Name = "C1: Clay Spiders", Family = "Projectile", Kind = "clayspider", Ground = true, Cost = 16, Channel = 0.26, Active = 0.06, Recovery = 0.28, Cooldown = 5, Interruptible = true,
			Range = 30, Speed = 34, Damage = 5, Count = 3, Spread = 0.6, Radius = 1.2, Knock = 20, Lift = 30,
			Charge = { Trigger = 2.6, Radius = 4.5, Damage = 6, Knock = 18, Lift = 34, Arm = .5, Life = 9, Look = "claycharge" },
			Hint = "Three spiders run the floor and pop under the body (launches) • those that miss stop and wait as charges" },
		{ Id = "ClayMine", Name = "Clay Landmine", Family = "Zone", Kind = "claycharge", At = "Aim", Cost = 12, Channel = 0.2, Active = 0.1, Recovery = 0.25, Cooldown = 5, Interruptible = true,
			Range = 26, Radius = 3, Time = 12, Charge = { Trigger = 3, Radius = 5.5, Damage = 9, Knock = 30, Lift = 36, Arm = .6, Life = 12, Look = "claycharge" },
			Hint = "A charge buried where he aims • it blasts whoever steps on it • Katsu! sets it off from anywhere" },
		{ Id = "Katsu", Name = "Katsu!", Family = "Burst", Kind = "clay", Cost = 16, Channel = 0.06, Active = 0.2, Recovery = 0.3, Cooldown = 9, Interruptible = false,
			Radius = 6, Clear = true, Damage = 6, Knock = 44, Lift = 14, Range = 6, Detonate = true,
			Hint = "KATSU! Every charge he has laid goes off where it lies • and the clay at his feet bursts (a close attacker thrown far)" },
	},
}

-- Sasori (14, Suna's puppet prodigy): he barely moves; his puppets fight on
-- chakra threads. His light string is a puppet lashing at mid range (slow
-- but long, like Gaara's sand), everything he touches carries poison: the
-- needle tool, his marionette (a persistent body that holds a post and
-- strikes on its own, carries his blade from behind and his rising strike),
-- Father and Mother's embrace, a rain of needles, a puppet that takes a blow
-- for him and bites back. Break the marionette and he is exposed.
fighters.Puppet = {
	Name = "Sasori", FullName = "Sasori of the Red Sand", Age = 14, Title = "THE PUPPET MASTER", Color = { 176, 60, 50 },
	Routes = "↑ puppet rising strike  ·  ↓ low puppet sweep  ·  ←→ feint step  ·  heavy after one: puppet blade (poisons)  ·  air: drive / spike / switch",
	Description = "Puppets on chakra threads: long, slow lashes, and poison in everything they touch.",
	Health = 118, Chakra = 120, ChakraRegen = 8, Speed = 18, SprintScale = 1.06, JumpScale = 1.0, AirControlScale = 0.95, AccelerationScale = 0.98,
	CombatTravel = 0.6, CombatDamage = 0.92, DashScale = 0.98, GuardStrength = 0.1, PreferredRange = 11,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	-- The puppet (Server/Wave3Kit marionette controller, Server/Bodies).
	Bodies = { puppet = { Max = 1, Persist = true, Life = 20, Every = 2.2, Reach = 5.2, Damage = 4, Hold = 4.4, Speed = 30, Leash = 34, Poison = { Damage = .6, Time = 2, Every = .5 } } },
	ToolMastery = { Kind = "shuriken", Projectile = "poisonneedle", Count = 2, Speed = 96, Damage = 1.6, Recover = .65, Contact = { Poison = { Damage = .7, Time = 2, Every = .5 } } },
	-- Awakening: the puppet master. Every blow poisons, holds last longer,
	-- the threads come cheaper and back sooner.
	Awakening = { Name = "PUPPET MASTER", Speed = 1.04, Regen = 1.4, Cooldown = 0.5, CostScale = 0.6, BindScale = 1.4,
		OnHit = { Poison = { Damage = .5, Time = 2, Every = .5 } }, Color = { 220, 90, 70 } },
	-- Gaara's body: still and composed, his hands do the work (here, threads).
	Motion = { body = "Sand", clips = "Sand", weapons = "none", springy = false,
		borrow = { PuppetBlade = "Light3" },
		-- Upright, both hands raised in front, fingers spread: the threads.
		stance = {root={y=-.1,pitch=0,yaw=10},torso={pitch=0,yaw=-4},head={pitch=2,yaw=-6},
			ra={raise=80,out=10,twist=10,elbow=60,wrist=-30},la={raise=76,out=-14,twist=-10,elbow=64,wrist=-30},
			rf={x=.1,z=.3,yaw=12},lf={x=-.06,z=-.26,yaw=-4},breath=.4,tempo=3.8} },
	-- Puppet lashes: long and narrow, slower than a fist, light.
	AttackProfile = {
		Light1={startup=1.6,recovery=1.35,travel=.3,range=8.5,depth=7.5,offset=4.3,width=3.6,damage=.85},
		Light2={startup=1.6,recovery=1.35,travel=.3,range=8.5,depth=7.5,offset=4.3,width=3.6,damage=.6},
		Light3={startup=1.7,recovery=1.4,travel=.3,range=9,depth=8,offset=4.5,width=4.4,impulseZ=54,damage=.6},
		DashAttack={startup=1.1,travel=.8,range=8.5},Air1={startup=1.1,range=8},Air2={startup=1.1,range=8},Slam={startup=1.1},
	},
	Skin = { 238, 220, 204 }, Hair = { 176, 60, 50 }, Outfit = { 120, 110, 100 },
	Techniques = {
		{ Id = "Marionette", Name = "Puppet: Marionette", Family = "Summon", Body = "puppet", Mode = "marionette", Life = 20, LungeName = "Puppet Lunge",
			Lunge = { Damage = 7, Knock = 26, Lift = 8, Poison = { Damage = 1, Time = 3, Every = .5 } },
			Cost = 18, Channel = 0.3, Active = 0.05, Recovery = 0.2, Cooldown = 3, Interruptible = true, Range = 30,
			Hint = "His puppet on its threads: it holds a post by the opponent and strikes on its own (poison) • cast again: it lunges • one clean blow breaks it" },
		{ Id = "FatherMother", Name = "Father and Mother: Embrace", Family = "Projectile", Kind = "puppet", Count = 2, Spread = 0.5, Cost = 22, Channel = 0.34, Active = 0.08, Recovery = 0.3, Cooldown = 9, Interruptible = true,
			Range = 20, Speed = 58, Damage = 3, Radius = 1.6, Bind = 1.4, Crush = 7, Hint = "Two puppets close on the body from both sides and hold it • then crush" },
		{ Id = "NeedleRain", Name = "Poison Needle Rain", Family = "Projectile", Kind = "poisonneedle", Cost = 18, Channel = 0.3, Active = 0.06, Recovery = 0.3, Cooldown = 6, Interruptible = true,
			Range = 30, Speed = 92, Damage = 1.2, Count = 9, Spread = 0.7, Radius = .6, Poison = { Damage = .6, Time = 2.5, Every = .5 }, Hint = "A fan of poisoned needles from a puppet's arm" },
		{ Id = "PuppetShield", Name = "Puppet Shield", Family = "Counter", Kind = "puppet", Time = 0.9, Damage = 7, Poison = { Damage = 1, Time = 3, Every = .5 },
			Cost = 14, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 7, Interruptible = false, Range = 6, Radius = 6,
			Hint = "A puppet steps in front • the blow it takes is answered with a poisoned blade" },
	},
}

-- Nagato (12, the Rinnegan child of Ame): the eyes, not the paths. He fights
-- with the two forces: he pushes everything away from him (blades, bodies)
-- and pulls a body to him; his absorbing seal drinks the jutsu thrown at him
-- (a defensive window to read, not a drain button). Still and
-- thin, a controller. No Six Paths, no Chibaku Tensei: adult.
fighters.Rinnegan = {
	Name = "Nagato", FullName = "Nagato Uzumaki", Age = 12, Title = "THE RINNEGAN CHILD", Color = { 180, 150, 220 },
	Routes = "↑ launcher  ·  ↓ sweep  ·  ←→ circle step  ·  heavy after one: repelling palm (throws the body off)  ·  air: drive / spike / switch",
	Description = "The Rinnegan: repulsion clears everything round him, attraction pulls the body in, he drinks chakra.",
	Health = 112, Chakra = 140, ChakraRegen = 9, Speed = 18, SprintScale = 1.06, JumpScale = 1.0, AirControlScale = 1.0, AccelerationScale = 0.98,
	CombatTravel = 0.95, CombatDamage = 0.9, DashScale = 1.0, GuardStrength = 0.12, PreferredRange = 10,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 90, Damage = 3, Recover = .75 },
	-- Awakening: the Rinnegan open. Jutsu at half their cost and back much
	-- sooner, chakra back fast.
	-- Rule: Repulsion no longer destroys what it pushes: blades and jutsu go
	-- back at their thrower.
	Awakening = { Name = "RINNEGAN", Speed = 1.04, Regen = 1.5, Cooldown = 0.6, CostScale = 0.7, ReflectClear = true, Color = { 200, 170, 240 } },
	Motion = { body = "Mirage", weapons = "none", springy = false,
		borrow = { RepellingPalm = "Light3" },
		-- Thin and still, shoulders slightly hunched, one palm open toward the
		-- opponent.
		stance = {root={y=-.14,pitch=4,yaw=16},torso={pitch=6,yaw=-6},head={pitch=-4,yaw=-8},
			ra={raise=70,out=-4,twist=0,elbow=24,wrist=-40},la={raise=10,out=10,twist=-10,elbow=20,wrist=0},
			rf={x=.14,z=.4,yaw=18},lf={x=-.06,z=-.36,yaw=-4},breath=.5,tempo=4} },
	AttackProfile = {
		Light1={startup=.98,recovery=.96,kind="palm"},Light2={startup=1.0,recovery=.96,kind="palm"},
		Light3={startup=1.04,recovery=1.0,impulseZ=56,kind="palm"},Heavy={startup=1.02,kind="palm"},
		Launcher={startup=1.0,impulseY=54},DashAttack={startup=.98},Air1={startup=.98},Air2={startup=1.0},
	},
	Skin = { 240, 226, 214 }, Hair = { 170, 40, 40 }, Outfit = { 60, 60, 70 },
	Techniques = {
		{ Id = "Repulsion", Name = "Repulsion", Family = "Burst", Kind = "repulsion", Cost = 22, Channel = 0.1, Active = 0.2, Recovery = 0.35, Cooldown = 7, Interruptible = false,
			Radius = 8, Clear = true, Damage = 7, Knock = 52, Lift = 14, Range = 8, Hint = "Everything round him pushed away: blades, bodies (into walls)" },
		{ Id = "Attraction", Name = "Attraction", Family = "Projectile", Kind = "gravity", Cost = 16, Channel = 0.2, Active = 0.05, Recovery = 0.25, Cooldown = 4, Interruptible = true,
			Range = 30, Speed = 110, Damage = 3, Radius = 1.6, Pull = 60, PullTo = 3, Hint = "The body pulled to him • then the string, or Repulsion" },
		{ Id = "Absorb", Name = "Absorbing Seal", Family = "Buff", Kind = "gravity", Cost = 8, Channel = 0.06, Active = 0.05, Recovery = 0.15, Cooldown = 8, Interruptible = true,
			Time = 2.5, Range = 20, Absorb = { Radius = 6.5, Chakra = 2.5, Heal = .4 }, AI = { Min = 0, Max = 40, Chance = .2 },
			Hint = "2.5 s: every jutsu or blade that reaches him is drunk (chakra, a little health) • blows still land" },
	},
}

-- Killer Bee (14, the Eight-Tails' young host): a big, rhythmic brawler with
-- a jinchūriki's body. The Lariat that flattens, the octopus' ink that
-- sticks to the legs, a tentacle that grabs. Tough (more health, a solid
-- guard). Awakening: the first chakra cloak. No seven swords, no full Gyūki.
fighters.Ink = {
	Name = "Killer Bee", FullName = "Killer Bee", Age = 14, Title = "THE EIGHT-TAILS' HOST", Color = { 230, 150, 60 },
	Routes = "↑ elbow beats the guard, the blade lifts  ·  ↓ barred blades, knee-blade kick backing off  ·  ←→ grips change, one edge  ·  held guard: the elbow blade  ·  air: X finisher / blade down / switch",
	Description = "Seven blades and a rhythm of his own: hand, elbow, knee. The Lariat, the octopus' ink, a tentacle that grabs.",
	Health = 150, Chakra = 115, ChakraRegen = 7.6, Speed = 19, SprintScale = 1.1, JumpScale = 1.04, AirControlScale = 1.0, AccelerationScale = 1.02,
	CombatTravel = 1.04, CombatDamage = 1.06, DashScale = 1.06, GuardStrength = 0.12, PreferredRange = 5,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 88, Damage = 3, Recover = .75 },
	-- Awakening: the first chakra cloak. Light blows do not stop him, a
	-- quarter of every blow is taken by the cloak, harder and faster.
	Awakening = { Name = "EIGHT-TAILS CLOAK", Speed = 1.1, Damage = 1.1, Regen = 1.3, Cooldown = 0.7, Buff = { Heavy = true, Armor = 0.25 }, Color = { 240, 160, 70 } },
	-- Bible KILLER_BEE.md (DEC-026): his own clips (Client/Wave3Motion) and
	-- seven blades in configurations (Wave3FX): two in the hands, one under
	-- the left elbow, the rest sheathed; the elbow blade moves behind the
	-- right knee for the third light.
	Motion = { body = "Lion", clips = "Ink", weapons = "none", springy = false,
		-- Wide base but mobile, the weight alternating; a blade in each hand,
		-- the right point low ahead, the left one higher.
		stance = {root={y=-.5,pitch=6,yaw=18},torso={pitch=4,yaw=-6},head={pitch=-4,yaw=-10},
			ra={raise=40,out=10,twist=0,elbow=40,wrist=0},la={raise=36,out=26,twist=-20,elbow=52,wrist=0},
			rf={x=.4,z=.55,yaw=24},lf={x=-.35,z=-.55,yaw=-10},breath=.9,tempo=6},
		-- The guard: two blades crossed in front of the shoulder.
		guard = {root={y=-.62,pitch=6},torso={pitch=4,yaw=-4},head={pitch=4},
			ra={raise=118,out=-40,twist=40,elbow=40},la={raise=112,out=-44,twist=40,elbow=44}} },
	AttackProfile = {
		-- Bible §3/§5 A/C/R and contact distances (studs to the blade's
		-- contact): L1 hand .16/.06/.20 at 4.2, L2 elbow .23/.06/.18 at 4.0,
		-- L3 knee .12/.07/.34 at 4.4, Heavy X .30/.09/.42 at 4.8.
		Light1={startup=1.78,active=.5,recovery=.71,range=6.2,depth=4.4,offset=3,width=5,contact=4.2,zone="body",kind="slash",damage=1.0},
		Light2={startup=2.3,active=.5,recovery=.67,range=6,depth=4.2,offset=2.9,width=5.5,contact=4.0,zone="body",kind="slash",damage=1.05},
		Light3={startup=1.0,active=.5,recovery=1.42,range=6.4,depth=4.6,offset=3.1,width=6,contact=4.4,zone="legs",kind="slash",impulseZ=58},
		Heavy={startup=1.0,active=.53,recovery=.81,range=6.8,depth=5,offset=3.3,width=6.5,contact=4.8,kind="heavy"},
		DashAttack={startup=.96,travel=1.08,contact=3.6,kind="strike"},Air1={contact=4,kind="slash"},Air2={contact=4.2,kind="slash"},
	},
	Skin = { 120, 82, 60 }, Hair = { 236, 236, 230 }, Outfit = { 70, 76, 60 },
	Techniques = {
		{ Id = "Lariat", Name = "Lariat", Family = "Strike", Move = "Lariat", Cost = 18, Channel = 0.16, Active = 0.05, Recovery = 0.1, Cooldown = 6, Interruptible = true,
			Range = 16, Damage = 15, Hint = "Charging arm across the gap • flattens the body", AI = { Min = 4, Max = 14 } },
		{ Id = "InkMist", Name = "Octopus Ink", Family = "Zone", Kind = "ink", ZoneKind = "Ink", At = "Aim", Cost = 14, Channel = 0.2, Active = 0.1, Recovery = 0.25, Cooldown = 9, Interruptible = true,
			Range = 22, Radius = 7, Time = 5, Damage = 1, Slow = { Scale = .62 }, Hint = "A cloud of ink: legs stuck, slowed hard while in it" },
		{ Id = "OctoHold", Name = "Octopus Hold", Family = "Projectile", Kind = "tentacle", Cost = 22, Channel = 0.3, Active = 0.08, Recovery = 0.3, Cooldown = 9, Interruptible = true,
			Range = 18, Speed = 70, Damage = 4, Radius = 1.6, Bind = 1.2, Crush = 8, Hint = "A tentacle grabs the body and holds it • then slams it" },
	},
}

local graphs={
	Clay={
		routes={up="Launcher",down="Sweep",side="FeintStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="ClayPop",
		stringCancels={Katsu=true,ClayBirds=true},
		blockCancels={Tool=true},
		-- A zoner: rarely comes in, and never straight.
		reengage={name="clay",speed=.95,arrive=4,angle=35,chase=.3,recovery=.2},
	},
	Puppet={
		routes={up="PuppetRise",down="PuppetSweep",side="FeintStep",airUp="AirDrive",airDown="AirSpike"},
		heavyAfterOne="PuppetBlade",
		stringCancels={Marionette=true},
		-- With the puppet out it carries these: the blade from behind the body,
		-- the rising strike from under it (Server/Bodies proxy).
		proxy={PuppetBlade={move="PuppetBlade",body="puppet"},PuppetRise={move="PuppetRise",body="puppet"}},
		blockCancels={Tool=true},
		reengage={name="puppet",speed=.9,arrive=6,angle=20,minRange=8,chase=.32,recovery=.22},
	},
	Rinnegan={
		routes={up="Launcher",down="Sweep",side="CircleStep",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="RepellingPalm",
		stringCancels={Repulsion=true,Attraction=true},
		blockCancels={},
		reengage={name="rinnegan",speed=.95,arrive=3.4,angle=0,chase=.3,recovery=.22},
	},
	Ink={
		routes={up="BladeLift",down="KneeKick",side="BladeSwap",airUp="AirDrive",airDown="BladeFall",airSide="AirSwitch"},
		disengage="Kunai",
		-- Bible §5/§6: the heavy after one is the same X; a held guard is
		-- answered by the blade under the elbow.
		riposte="ElbowCut",
		stringCancels={Lariat=true},
		blockCancels={},
		reengage={name="ink",speed=1.15,arrive=3,angle=15,chase=.26,recovery=.2},
	},
}

local function attacks(move,list)
	RosterMoves.add(move,list,{
		-- Deidara: a pellet popped against the body at point blank.
		ClayPop={{.1,.12,.34,9,2,"Knockback",V(0,14,60),.5},{contact=3.6,range=6.4,zone="body",kind="palm",side=1,twist=20,lean=14,arm=100,step=1.15}},
		-- Sasori: the puppet's rising strike and low sweep (long, thread reach),
		-- its poisoned blade.
		PuppetRise={{.2,.14,.32,7,.4,"Launched",V(0,52,4),1.15},{contact=5,range=9,width=4.4,height=8,depth=8,offset=4.5,zone="chin",kind="launch",side=1,twist=10,lean=-6,arm=120,step=1,proxy="under"}},
		PuppetSweep={{.2,.16,.36,7,.4,"Knockdown",V(0,6,14),.66},{contact=5,range=9,width=6,height=3.5,depth=8,offset=4.5,zone="legs",kind="sweep",side=-1,twist=40,lean=10,arm=90,step=1}},
		PuppetBlade={{.16,.14,.34,8,.4,"Knockback",V(0,10,46),.5},{contact=5,range=9,width=4,depth=8,offset=4.5,zone="body",kind="slash",side=1,twist=24,lean=8,arm=110,step=1,proxy="behind",riders={Poison={Damage=1,Time=2.5,Every=.5}}}},
		-- Nagato: a palm that pushes the body away.
		RepellingPalm={{.1,.12,.34,8,2.4,"Knockback",V(0,12,66),.5},{contact=3.8,range=6.6,zone="body",kind="palm",side=1,twist=20,lean=16,arm=100,step=1.2}},
		-- Killer Bee: the blades in their grips (bible KILLER_BEE.md §4/§6), the
		-- old lariat arm (kept, no longer routed) and the charging Lariat.
		BladeLift={{.15,.14,.32,8,1.4,"Launched",V(0,54,6),1.2},{contact=4.2,range=7,width=5.5,height=8,zone="chin",kind="launch",side=1,twist=14,lean=-20,arm=120,step=1.1,breaksShield=true}},
		KneeKick={{.13,.14,.36,8,.4,"Knockdown",V(0,8,22),.62},{contact=4.2,range=6.6,width=6,height=4,zone="legs",kind="sweep",side=1,twist=36,lean=-6,arm=80,step=.9,retreat=1.4}},
		BladeSwap={{.12,.12,.28,6,.8,"HitStun",V(0,4,12),.38},{contact=4.0,range=6.6,width=7,height=6,zone="body",kind="slash",side=1,twist=60,lean=6,arm=84,step=1.0,chain=true,orbit=22}},
		ElbowCut={{.08,.12,.3,8,1.6,"Knockback",V(0,10,46),.5},{contact=3.8,range=6,width=6,zone="body",kind="slash",side=-1,twist=50,lean=10,arm=90,step=1.15}},
		BladeFall={{.11,.14,.26,8,1.5,"Spiked",V(0,-70,4),.9},{contact=4,range=7,width=5.5,height=8,zone="head",kind="spike",side=1,twist=10,lean=40,arm=124,step=1,air=true}},
		LariatArm={{.11,.14,.34,10,3.2,"Knockdown",V(0,10,40),.62},{contact=3.6,range=7,width=7,zone="head",kind="heavy",side=1,twist=50,lean=16,arm=90,step=1.3}},
		Lariat={{.06,.22,.42,15,13,"Knockdown",V(0,14,56),.7},{contact=3.4,range=7,width=7,height=6,zone="head",kind="heavy",side=1,twist=40,lean=20,arm=90,step=1.45,breaksShield=true}},
	})
end

return {
	fighters=fighters,
	graphs=graphs,
	attacks=attacks,
}
