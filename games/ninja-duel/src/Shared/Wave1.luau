-- Roster 20, batch 1 (DEC-022): Haku, Zabuza, Kimimaro. This batch's shared
-- data, merged into Fighters, MoveGraphs and Attacks so batches never edit the
-- same tables (docs/characters/ROSTER_20.md).
--   fighters[id]  a Fighters entry (techniques naming a Family first)
--   graphs[id]    a MoveGraphs entry (the shared directional grammar)
--   attacks(move, attacks)  the batch's own strikes (Shared/RosterMoves)
-- Young versions only: what each of them could already do at that age.
local RosterMoves=require(script.Parent.RosterMoves)
local V=Vector3.new

local fighters={}
-- Haku (15, the Land of Waves): Ice Release. Fast and light, he fights from
-- the edge of the melee: senbon at the vital points (they slow), needles of
-- water, a step through a mirror, and the Demonic Ice Mirrors that close a
-- dome round the opponent. The dome is his network: inside it the mirror
-- step takes him from mirror to mirror round the body, a volley from each.
fighters.Mirror = {
	Name = "Haku", FullName = "Haku Yuki", Age = 15, Title = "THE ICE MIRROR", Color = { 150, 206, 240 },
	Routes = "↑ ice spike under the foot, the palm guides  ·  ↓ low senbon, backing off on ice  ·  ←→ ice slide and a senbon touch  ·  held guard: senbon to a vital point  ·  air: senbon / senbon dive / switch",
	Description = "Ice Release: senbon at the vital points, needles of water, the mirror step and the Demonic Ice Mirrors.",
	Health = 115, Chakra = 125, ChakraRegen = 8.4, Speed = 20, SprintScale = 1.12, JumpScale = 1.08, AirControlScale = 1.12, AccelerationScale = 1.12,
	CombatTravel = 1.06, CombatDamage = 0.9, DashScale = 1.12, GuardStrength = 0.1, PreferredRange = 11,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Shuriken",
	-- Three senbon at once, fast and light; each one that lands slows a little.
	ToolMastery = { Kind = "shuriken", Projectile = "senbon", Count = 3, Speed = 112, Damage = 1.4, Recover = .6, Contact = { Slow = { Scale = .85, Time = 1 } } },
	-- Awakening: inside the mirrors. Faster legs, techniques back almost at
	-- once, cheaper ice.
	-- Rule: inside his dome, travel from mirror to mirror is free and comes
	-- back at once (a storm of volleys from every side).
	Awakening = { Name = "CRYSTAL ICE MIRRORS", Speed = 1.1, Regen = 1.3, Cooldown = 0.7, ZoneFree = true, Color = { 200, 236, 255 } },
	-- Bible HAKU.md (DEC-026): his own clips (Client/Wave1Motion); senbon
	-- held between the fingers and ice born at the wrist and under the feet
	-- in the transitions (Wave1FX). The dome stays his signature.
	Motion = { body = "Mirage", clips = "Mirror", weapons = "none", springy = false,
		-- Fingers on the senbon, arms close to the body, a light front foot,
		-- three-quarter on.
		stance = {root={y=-.34,pitch=4,yaw=32},torso={pitch=2,yaw=-10},head={pitch=-2,yaw=-16},
			ra={raise=70,out=-6,twist=30,elbow=104,wrist=-10},la={raise=36,out=-10,twist=-10,elbow=70,wrist=-10},
			rf={x=.22,z=.6,yaw=34},lf={x=-.08,z=-.58,yaw=-6},breath=.8,tempo=6},
		-- The guard: a forearm and the senbon turn the blow aside (no giant shield).
		guard = {root={y=-.46,pitch=4},torso={pitch=4,yaw=-12},head={pitch=4},
			ra={raise=96,out=-36,twist=50,elbow=96},la={raise=60,out=-10,twist=10,elbow=96}} },
	AttackProfile = {
		-- Bible §3/§5 A/C/R and contact distances: L1 senbon .11/.05/.18 at 3.1,
		-- L2 palm + wrist spike .16/.05/.17 at 3.3, L3 exiting senbon
		-- .19/.06/.28 at 3.5, Heavy forearm on a spike + senbon push .25/.06/.32 at 3.8.
		Light1={startup=1.22,active=.42,recovery=.64,travel=1.06,range=5.1,depth=3.5,offset=2.3,width=3.6,contact=3.1,zone="body",kind="strike"},
		Light2={startup=1.6,active=.42,recovery=.63,travel=1.06,range=5.3,depth=3.7,offset=2.4,width=4.2,contact=3.3,zone="body",kind="palm"},
		Light3={startup=1.58,active=.43,recovery=1.17,range=5.5,depth=3.9,offset=2.5,width=4.4,contact=3.5,zone="body",kind="strike",impulseZ=48},
		Heavy={startup=.83,active=.35,recovery=.62,range=5.8,depth=4.1,offset=2.7,width=4.4,contact=3.8,kind="heavy"},
		Launcher={startup=.94,impulseY=54},DashAttack={startup=.88,travel=1.1,contact=3.2,kind="strike"},Air1={contact=3.2,kind="strike"},Air2={contact=3.4,kind="strike"},
	},
	Skin = { 238, 220, 204 }, Hair = { 30, 30, 36 }, Outfit = { 110, 140, 112 },
	Techniques = {
		{ Id = "WaterNeedles", Name = "Thousand Flying Water Needles", Family = "Projectile", Kind = "ice", Element = "Water", Cost = 16, Channel = 0.3, Active = 0.05, Recovery = 0.3, Cooldown = 4.5, Interruptible = true,
			Range = 34, Speed = 86, Damage = 2.2, Count = 7, Spread = 0.5, Radius = .7, Slow = { Scale = .8, Time = 1.4 }, Hint = "A fan of ice needles • each one slows • hard to dodge sideways" },
		{ Id = "MirrorStep", Name = "Ice Mirror Step", Family = "Teleport", Kind = "mirror", To = "Side", Distance = 3.4, Move = "SenbonStab", Damage = 7, InZone = 1.4, ZoneName = "mirrors",
			Ring = { Look = "mirror", Volley = { Count = 3, Kind = "senbon", Damage = 2.4, Speed = 120, Slow = { Scale = .75, Time = 1.2 } } },
			Cost = 14, Channel = 0.1, Active = 0.04, Recovery = 0.2, Cooldown = 3.6, Interruptible = true, Range = 30, Invuln = .15,
			Hint = "Outside the dome: out of a mirror at his flank, senbon to a vital point • inside it: from mirror to mirror round the body, a volley from each", AI = { Min = 6, Max = 28 } },
		{ Id = "IceMirrors", Name = "Demonic Ice Mirrors", Family = "Zone", Kind = "mirror", ZoneKind = "Ice", At = "Target", Element = "Water", Cost = 28, Channel = 0.55, Active = 0.2, Recovery = 0.35, Cooldown = 12, Interruptible = true,
			Range = 30, Radius = 7.5, Time = 5.5, Damage = 3, Slow = { Scale = .72 }, Hint = "A dome of mirrors round the opponent • it slows and cuts • his mirror step strikes harder inside" },
	},
}

-- Zabuza (14, the Mist's young Swordsman): the cleaver. Slow, long, heavy
-- strikes with real reach; the Hidden Mist, the Silent Killing out of it
-- (much harder while the body stands in his mist) and the Water Prison.
fighters.Mist = {
	Name = "Zabuza", FullName = "Zabuza Momochi", Age = 14, Title = "THE DEMON OF THE MIST", Color = { 120, 150, 170 },
	Routes = "↑ cleaver rise from the hip  ·  ↓ low cut backing off  ·  ←→ arc covering the flank  ·  held guard: handle riposte  ·  air: flat strike / cleaver dive",
	Description = "Kubikiribōchō: slow, long and heavy. The Hidden Mist, the Silent Killing out of it, the Water Prison.",
	Health = 150, Chakra = 110, ChakraRegen = 7, Speed = 18.5, SprintScale = 1.1, JumpScale = 1.0, AirControlScale = 0.95, AccelerationScale = 0.98,
	CombatTravel = 0.92, CombatDamage = 1.12, DashScale = 1.0, GuardStrength = 0.08, PreferredRange = 6.5,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 88, Damage = 3, Recover = .8 },
	-- Awakening: the Demon. Light blows do not stop him, the cleaver bites deeper.
	Awakening = { Name = "DEMON OF THE MIST", Speed = 1.06, Damage = 1.12, Regen = 1.2, Cooldown = 0.7, Buff = { Heavy = true }, Color = { 170, 210, 230 } },
	-- The closed-fan clips are a long heavy weapon swung two-handed: the
	-- cleaver's (GaleFX draws the fan for Temari only).
	-- Bible ZABUZA.md (DEC-026): his own clips (Client/Wave1Motion), the
	-- cleaver in both hands from the guard to the recovery (Wave1FX).
	Motion = { body = "Mirage", clips = "Mist", weapons = "none", springy = false,
		-- Feet wide, the pelvis carries the weight; the point low on the
		-- diagonal, the rear hand on the handle.
		stance = {root={y=-.58,pitch=6,yaw=26},torso={pitch=6,yaw=-10},head={pitch=-4,yaw=-14},
			ra={raise=46,out=-16,twist=-10,elbow=20,wrist=0},la={raise=52,out=-30,twist=-10,elbow=58,wrist=-10},
			rf={x=.34,z=.72,yaw=30},lf={x=-.22,z=-.7,yaw=-8},breath=.55,tempo=3.8},
		-- The guard: the blade held flat across, the face still readable.
		guard = {root={y=-.66,pitch=6},torso={pitch=4,yaw=-6},head={pitch=4},
			ra={raise=96,out=-30,twist=60,elbow=70,wrist=0},la={raise=100,out=-50,twist=50,elbow=84,wrist=-10}} },
	-- Bible §3/§5 A/C/R: L1 handle .12/.06/.23 at 3.2, L2 edge .28/.09/.30
	-- at 5.5, L3 reverse .32/.10/.40 at 5.8, Heavy .42/.10/.52 at 6 (the
	-- multipliers are those seconds over the base strike's).
	AttackProfile = {
		Light1={startup=1.33,active=.5,recovery=.82,travel=.9,range=5.4,depth=4,offset=2.6,width=4.5,contact=3.2,damage=.9,zone="body",kind="strike"},
		Light2={startup=2.8,active=.75,recovery=1.11,travel=.8,range=7.6,depth=5.8,offset=3.6,width=8.5,contact=5.5,damage=1.15,zone="body",kind="slash"},
		Light3={startup=2.67,active=.71,recovery=1.67,travel=.8,range=8,depth=6,offset=3.8,width=7,contact=5.8,impulseZ=64,damage=1.1,kind="slash"},
		Heavy={startup=1.4,active=.59,recovery=1.0,range=8.2,depth=6.2,offset=3.9,contact=6,kind="heavy"},
		DashAttack={travel=.9,range=6,contact=3.4,kind="strike"},Air1={range=7,contact=4.4,kind="strike"},Air2={range=7.2,contact=4.6,kind="slash"},
	},
	Skin = { 228, 204, 182 }, Hair = { 30, 30, 34 }, Outfit = { 120, 128, 130 },
	Techniques = {
		{ Id = "HiddenMist", Name = "Hidden Mist", Family = "Zone", Kind = "mist", ZoneKind = "Mist", At = "Self", Element = "Water", Cost = 20, Channel = 0.4, Active = 0.2, Recovery = 0.3, Cooldown = 14, Interruptible = true,
			Range = 16, Radius = 16, Time = 8, Damage = 0, Slow = { Scale = .86 }, Shroud = true,
			Hint = "A thick mist round him • inside it the opponent loses sight of him (he fades to a shadow, no lock) • the Silent Killing strikes far harder there" },
		{ Id = "SilentKilling", Name = "Silent Killing", Family = "Teleport", Kind = "mist", To = "Behind", Distance = 3.6, Move = "SilentCleave", InZone = 1.7, ZoneName = "mist",
			Cost = 22, Channel = 0.14, Active = 0.04, Recovery = 0.25, Cooldown = 6, Interruptible = true, Range = 32,
			Hint = "Gone, then the cleaver from behind • far harder in his mist", AI = { Min = 6, Max = 30 } },
		{ Id = "WaterPrison", Name = "Water Prison", Family = "Projectile", Kind = "water", Element = "Water", Cost = 24, Channel = 0.3, Active = 0.06, Recovery = 0.3, Cooldown = 10, Interruptible = true,
			Range = 16, Speed = 72, Damage = 2, Radius = 1.6, Bind = 1.6, Crush = 8, Hint = "Short range: a sphere of water holds the body • then it bursts" },
	},
}

-- Kimimaro (13, the last of the Kaguya): Shikotsumyaku. His bones are his
-- weapons and his armour: the finger bullets are his tool, the Camellia
-- draws a bone sword, the Larch bursts from his whole body and leaves the
-- floor spiked, the Willow is a lunge of bone blades. He takes less damage.
fighters.Bone = {
	Name = "Kimimaro", FullName = "Kimimaro Kaguya", Age = 13, Title = "THE LAST KAGUYA", Color = { 236, 230, 212 },
	Routes = "↑ bone forearm rises under the guard  ·  ↓ shin reap backing off  ·  ←→ flank elbow, hip arc  ·  held guard: the bone elbow  ·  air: knee / bone heel / switch",
	Description = "Shikotsumyaku: bones as blades and armour. Finger bullets, the Camellia sword, the Larch, the Willow.",
	Health = 140, Chakra = 105, ChakraRegen = 7.4, Speed = 19, SprintScale = 1.1, JumpScale = 1.04, AirControlScale = 1.0, AccelerationScale = 1.04,
	CombatTravel = 1.02, CombatDamage = 1.0, DashScale = 1.04, GuardStrength = 0.1, PreferredRange = 5,
	-- Bone under the skin: every blow that lands loses some of its weight.
	Armor = 0.12,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
	-- Teshi Sendan: bones fired from the fingertips, two at once.
	ToolMastery = { Kind = "kunai", Projectile = "bone", Count = 2, Speed = 100, Damage = 2.4, Recover = .7 },
	-- Awakening: the Kaguya bloodline unleashed. Bone armour over the body (a
	-- third of every blow, light blows do not stop him) and a deeper bite.
	Awakening = { Name = "DANCE OF THE CLEMATIS", Speed = 1.04, Damage = 1.1, Regen = 1.2, Cooldown = 0.7, Buff = { Armor = 0.3, Heavy = true }, Color = { 246, 240, 222 } },
	-- Bible KIMIMARO.md (DEC-026): his own clips (Client/Wave1Motion); the
	-- skeleton lives in the blows (Wave1FX): knuckles, elbow, shin and the
	-- forearm bones grow before the contact and retract after it. The long
	-- bone sword is the Camellia's only.
	Motion = { body = "Lion", clips = "Bone", weapons = "none", springy = false,
		-- Soft hands, elbows a little open, feet offset, the centre low and
		-- mobile (no blade held out: not a Jedi stance).
		stance = {root={y=-.5,pitch=6,yaw=24},torso={pitch=4,yaw=-8},head={pitch=-4,yaw=-12},
			ra={raise=50,out=10,twist=10,elbow=70,wrist=0},la={raise=42,out=14,twist=10,elbow=80,wrist=0},
			rf={x=.3,z=.55,yaw=30},lf={x=-.2,z=-.6,yaw=-8},breath=.7,tempo=5},
		-- The guard: the forearms up and crossed, radius and ulna out between
		-- the arms and the blow.
		guard = {root={y=-.6,pitch=6},torso={pitch=6,yaw=-4},head={pitch=6},
			ra={raise=84,out=-30,twist=40,elbow=112},la={raise=80,out=-30,twist=40,elbow=116}} },
	AttackProfile = {
		-- Bible §3/§5 A/C/R and contact distances: L1 knuckles .12/.05/.18 at
		-- 3.2, L2 bone elbow .18/.06/.21 at 3.3, L3 round kick with shin spurs
		-- .22/.07/.30 at 3.9, Heavy crossed forearms + shoulder .28/.08/.36 at 3.8.
		Light1={startup=1.33,active=.42,recovery=.64,range=5.2,depth=3.6,offset=2.4,width=4,contact=3.2,zone="body",kind="strike"},
		Light2={startup=1.8,active=.5,recovery=.78,range=5.3,depth=3.7,offset=2.4,width=4.5,contact=3.3,zone="body",kind="strike"},
		Light3={startup=1.83,active=.5,recovery=1.25,range=5.9,depth=4.2,offset=2.8,width=5.5,contact=3.9,zone="body",kind="kick",impulseZ=52},
		Heavy={startup=.93,active=.47,recovery=.69,range=5.8,depth=4.1,offset=2.7,width=5,contact=3.8,kind="heavy"},
		Launcher={startup=.98,impulseY=56},DashAttack={startup=.94,travel=1.06,contact=3.4,kind="strike"},Air1={contact=3.4,kind="kick"},Air2={contact=3.6,kind="kick"},
	},
	Skin = { 240, 226, 212 }, Hair = { 236, 234, 228 }, Outfit = { 236, 232, 224 },
	Techniques = {
		{ Id = "Camellia", Name = "Dance of the Camellia", Family = "Buff", Kind = "bonespear", Cost = 18, Channel = 0.3, Active = 0.05, Recovery = 0.2, Cooldown = 14, Interruptible = true,
			Time = 8, Damage = 1.22, Speed = 1.05, Range = 20, Hint = "A bone sword drawn from the palm: his blows hit harder for 8 s" },
		{ Id = "Larch", Name = "Dance of the Larch", Family = "Burst", Kind = "bones", Cost = 20, Channel = 0.1, Active = 0.25, Recovery = 0.32, Cooldown = 8, Interruptible = false,
			Radius = 6.5, Clear = true, Damage = 8, Knock = 36, Lift = 14, Range = 6.5, Leave = { Radius = 6, Time = 3, Damage = 3, Kind = "Bones", Look = "bones" },
			Hint = "Bones burst from his whole body • blades cut down, a close attacker thrown off • the floor stays spiked" },
		{ Id = "Willow", Name = "Dance of the Willow", Family = "Strike", Move = "WillowCut", Cost = 16, Channel = 0.18, Active = 0.05, Recovery = 0.1, Cooldown = 5, Interruptible = true,
			Range = 14, Damage = 10, Hint = "A lunge of bone blades across the gap", AI = { Min = 4, Max = 12 } },
	},
}

local graphs={
	Mirror={
		routes={up="FrostLift",down="SenbonLow",side="IceSlide",airUp="AirDrive",airDown="SenbonDive",airSide="AirSwitch"},
		disengage="Kunai",
		-- Bible §5/§6: the heavy after one is the same push; a held guard is
		-- answered by the senbon's angle (to a vital point).
		riposte="SenbonStab",
		stringCancels={MirrorStep=true,WaterNeedles=true},
		blockCancels={Tool=true},
		-- Never straight in: a quick re-entry at a wide angle.
		reengage={name="mirror",speed=1.2,arrive=3.4,angle=40,shuffle=true,chase=.26,recovery=.18},
	},
	Mist={
		routes={up="CleaverRise",down="CleaverDrop",side="CleaverArc",airUp="AirDrive",airDown="CleaverDive"},
		-- Bible §5/§6: the heavy after one is the same diagonal (no separate
		-- move); a held guard is answered with the handle.
		riposte="CleaverHilt",
		stringCancels={SilentKilling=true},
		blockCancels={},
		-- Unhurried: walks the body down, straight in, slower than most.
		reengage={name="mist",speed=.92,arrive=4.2,angle=0,minRange=6,chase=.3,recovery=.24},
	},
	Bone={
		routes={up="BoneRise",down="BoneReap",side="CamelliaArc",airUp="AirDrive",airDown="BoneHeel",airSide="AirSwitch"},
		disengage="Kunai",
		-- Bible §5/§6: the heavy after one is the same crossed forearms; a held
		-- guard is answered with the bone elbow.
		riposte="BoneElbow",
		stringCancels={Willow=true,Larch=true},
		blockCancels={},
		reengage={name="bone",speed=1.05,arrive=3,angle=12,chase=.28,recovery=.2},
	},
}

local function attacks(move,list)
	RosterMoves.add(move,list,{
		-- Haku: a senbon driven into a vital point (the body slows), and a
		-- low sliding cut on a skin of ice that keeps the string.
		SenbonStab={{.08,.1,.3,7,2.6,"HitStun",V(0,4,12),.44},{contact=3.4,range=6.4,zone="head",kind="strike",side=-1,twist=34,lean=12,arm=96,step=1.1,riders={Slow={Scale=.7,Time=1.8}}}},
		IceSlide={{.1,.14,.24,6,3.2,"HitStun",V(0,4,12),.38},{contact=3.3,range=5.6,width=5,zone="body",kind="strike",side=1,twist=40,lean=10,arm=80,step=1.1,orbit=30,chain=true}},
		-- Haku's routes (bible HAKU.md §4): one ice spike under the foot and
		-- the palm guides (a local launcher), a low senbon then a retreat on
		-- ice, the senbon driven down from the air.
		FrostLift={{.14,.14,.32,8,1.4,"Launched",V(0,52,6),1.2},{contact=3.4,range=5.8,width=5,height=8,zone="chin",kind="launch",side=1,twist=14,lean=-16,arm=110,step=1.1,breaksShield=true}},
		SenbonLow={{.12,.12,.34,7,.4,"Knockdown",V(0,6,14),.6},{contact=3.4,range=5.8,width=5,height=3.5,zone="legs",kind="sweep",side=1,twist=30,lean=18,arm=70,step=.9,retreat=1.5}},
		SenbonDive={{.1,.14,.26,7,1.5,"Spiked",V(0,-68,4),.9},{contact=3.4,range=6,width=5,height=8,zone="head",kind="spike",side=1,twist=10,lean=36,arm=120,step=1,air=true}},
		-- Zabuza: the cleaver. Long reach (he stops further out), slow, heavy.
		CleaverRise={{.17,.15,.32,9,1.4,"Launched",V(0,52,6),1.2},{contact=4.8,range=8,width=6,height=8,zone="chin",kind="launch",side=1,twist=14,lean=-26,arm=120,step=1.1,breaksShield=true}},
		CleaverDrop={{.16,.14,.38,9,.4,"Knockdown",V(0,6,16),.66},{contact=4.6,range=8,width=7,height=3.5,zone="legs",kind="sweep",side=1,twist=30,lean=20,arm=80,step=.9,retreat=1.4}},
		CleaverArc={{.13,.18,.3,7,.8,"HitStun",V(0,5,14),.4},{contact=4.6,range=8.2,width=9,height=6,zone="body",kind="slash",side=1,twist=60,lean=6,arm=84,step=1.0,chain=true,orbit=18}},
		CleaverHilt={{.1,.12,.32,9,1.6,"Knockback",V(0,12,50),.5},{contact=4.2,range=7,width=6,zone="body",kind="heavy",side=-1,twist=48,lean=12,arm=96,step=1.15}},
		CleaverDive={{.11,.14,.26,8,1.5,"Spiked",V(0,-72,4),.9},{contact=4.4,range=7.8,width=6,height=8,zone="head",kind="spike",side=1,twist=10,lean=42,arm=124,step=1,air=true}},
		SilentCleave={{.08,.16,.36,13,1.2,"Knockdown",V(0,10,30),.7},{contact=4.4,range=8,width=7,height=7,zone="body",kind="heavy",side=1,twist=60,lean=24,arm=120,step=1.2}},
		-- Kimimaro: bone through the guard's gap, the camellia's arc that
		-- keeps the string, and the willow's lunge.
		BoneThrust={{.1,.12,.32,10,3.2,"Knockback",V(0,10,58),.5},{contact=3.8,range=7,zone="body",kind="heavy",side=1,twist=24,lean=22,arm=110,step=1.25}},
		CamelliaArc={{.1,.14,.24,6,1.6,"HitStun",V(0,4,12),.38},{contact=3.4,range=5.6,width=6,zone="body",kind="strike",side=-1,twist=60,lean=8,arm=96,step=1.05,orbit=24,chain=true}},
		-- Kimimaro's routes (bible KIMIMARO.md §4/§6): the forearm bone that
		-- rises under the guard, the reaping shin that backs off, the bone
		-- elbow that answers a guard, the bone heel from the air.
		BoneRise={{.14,.14,.32,8,1.4,"Launched",V(0,54,6),1.2},{contact=3.4,range=5.8,width=5,height=8,zone="chin",kind="launch",side=1,twist=14,lean=-20,arm=120,step=1.1,breaksShield=true}},
		BoneReap={{.13,.14,.36,8,.4,"Knockdown",V(0,6,16),.66},{contact=3.8,range=6,width=6,height=3.5,zone="legs",kind="sweep",side=1,twist=40,lean=12,arm=80,step=.9,retreat=1.3}},
		BoneElbow={{.08,.12,.3,8,1.6,"Knockback",V(0,10,46),.5},{contact=3.2,range=5.4,width=5,zone="body",kind="strike",side=-1,twist=50,lean=12,arm=90,step=1.15}},
		BoneHeel={{.11,.14,.26,8,1.5,"Spiked",V(0,-70,4),.9},{contact=3.6,range=6.2,width=5,height=8,zone="head",kind="spike",side=1,twist=10,lean=40,arm=124,step=1,air=true}},
		WillowCut={{.05,.22,.42,12,10,"Knockback",V(0,12,52),.55},{contact=3.6,range=7,width=5,zone="body",kind="heavy",side=1,twist=20,lean=30,arm=110,step=1.4}},
	})
end

return {
	fighters=fighters,
	graphs=graphs,
	attacks=attacks,
}
