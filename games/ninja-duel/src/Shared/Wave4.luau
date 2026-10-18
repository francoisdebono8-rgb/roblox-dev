-- DEC-026 newcomers: Madara, Hashirama and Hiruzen as children (the three
-- Combat Bibles docs/characters/{MADARA,HASHIRAMA,HIRUZEN}_CHILD.md). This
-- batch's shared data, merged into Fighters, MoveGraphs and Attacks like
-- Wave1..3. Staged (Shared/RosterStaging) until the 17+3 menu migration.
--
-- Each one is built from the body first: own lights with the bible's reach
-- and A/C/R (AttackProfile, A = startup, C = active, R = recovery; the
-- multipliers below are those seconds over the base strike's), own routes,
-- own heavy, own riposte gesture (MoveGraphs riposte) and a riposte the
-- awakening changes (Awakening.Riposte, Brawler). The weapon is real and
-- drawn on the body (Client/Wave4FX): Madara's short sword, the wood that
-- sheathes Hashirama's forearms while he strikes, Hiruzen's staff. No adult
-- power: no Susanoo or Sharingan beyond a read, no forest, no Enma.
local RosterMoves=require(script.Parent.RosterMoves)
local V=Vector3.new

local fighters={}
-- Madara (12–13, the Uchiha prodigy): a short sword drawn from the left hip
-- and a heavier base than Sasuke, no body flicker. Cuts at an angle, the
-- pommel inside, the reverse cut that sends the body off; a frontal read
-- answered with the pommel; a short Katon breath. Awakening: the young
-- Sharingan's focus (a parry opens an angled cut).
fighters.Rival = {
	Name = "Madara", FullName = "Madara Uchiha (child)", Age = 13, Title = "THE UCHIHA PRODIGY", Color = { 60, 70, 120 },
	Routes = "↑ quillon rise  ·  ↓ heel + blade barrier  ·  ←→ guard cut  ·  air: shoulder cut / pommel down  ·  parry: pommel riposte",
	Description = "A short sword and a heavy base: angled cuts, the pommel inside, a read answered with the pommel, a short Katon breath.",
	Health = 128, Chakra = 120, ChakraRegen = 8, Speed = 19, SprintScale = 1.08, JumpScale = 1.0, AirControlScale = 1.0, AccelerationScale = 1.0,
	CombatTravel = 1.0, CombatDamage = 1.04, DashScale = 1.0, GuardStrength = 0.14, PreferredRange = 4.5,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 92, Damage = 3, Recover = .7 },
	-- Awakening (GAMEPLAY_LIBERTY: a young Sharingan's focus, not the EMS):
	-- the riposte of a clean parry becomes an angled cut round the guard.
	Awakening = { Name = "YOUNG SHARINGAN", Speed = 1.04, Damage = 1.05, Riposte = { any = "SharinganCut" }, Color = { 220, 50, 50 } },
	Motion = { body = "Lion", clips = "Rival", weapons = "none", springy = false,
		-- Side-on and planted, the right hand on the hilt at the left hip, the
		-- left hand open in front of the chest.
		stance = {root={y=-.42,pitch=4,yaw=30},torso={pitch=3,yaw=-12},head={pitch=-4,yaw=-18},
			ra={raise=30,out=-30,twist=40,elbow=96,wrist=0},la={raise=58,out=-4,twist=-20,elbow=60,wrist=-20},
			rf={x=.24,z=.66,yaw=30},lf={x=-.1,z=-.6,yaw=-8},breath=.7,tempo=4.8} },
	-- Bible §3/§5: L1 .18/.07/.22 at 3.8, L2 .12/.06/.18 at 3.0, L3 .28/.08/.36
	-- at 4.2, heavy .32/.09/.42 at 4.5.
	AttackProfile = {
		Light1={startup=2.0,active=.58,recovery=.79,contact=3.8,range=6.8,zone="body",kind="slash"},
		Light2={startup=1.2,active=.5,recovery=.67,contact=3.0,range=6,zone="body",kind="palm"},
		Light3={startup=2.33,active=.57,recovery=1.5,contact=4.2,range=7.2,zone="body",kind="slash",impulseZ=56},
		Heavy={startup=1.07,active=.53,recovery=.81,contact=4.5,range=7.5,kind="slash"},
		Launcher={startup=1.0}, DashAttack={startup=1.0,kind="slash"}, Air1={startup=1.0,kind="slash"}, Air2={startup=1.0,kind="slash"},
	},
	Skin = { 236, 214, 196 }, Hair = { 24, 24, 30 }, Outfit = { 40, 46, 84 },
	Techniques = {
		{ Id = "UchihaRead", Name = "Rising Uchiha Read", Family = "Counter", Kind = "swordread", Time = 0.5, Move = "PommelRiposte",
			Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.22, Cooldown = 6, Interruptible = false, Range = 6, Radius = 6,
			Hint = "0.5 s frontal stance: the blow it reads is answered with the pommel • a feint or a whiff wastes it" },
		{ Id = "UchihaKaton", Name = "Katon: Short Breath", Family = "Burst", Kind = "firebreath", Element = "Fire", Cost = 18, Channel = 0.35, Active = 0.12, Recovery = 0.4, Cooldown = 7, Interruptible = true,
			Radius = 10, Arc = 0.55, Damage = 9, Knock = 30, Lift = 8, Range = 10,
			Hint = "A short cone of fire, 10 studs ahead • ends a string instead of the finisher • open on the sides" },
	},
}

-- Hashirama (12–13, the Senju child): a wrestler who advances on his feet;
-- small wooden grips are born inside his gestures (the forearm sheath of a
-- strike, a stump under the launcher, a root at the contact point). A short
-- root that holds a moment, a guard of young wood that breaks after one
-- answer. Awakening: controlled growth (a parry sends the root to the point
-- of contact). No forest, no healing.
fighters.Sapling = {
	Name = "Hashirama", FullName = "Hashirama Senju (child)", Age = 13, Title = "THE SENJU SAPLING", Color = { 150, 90, 50 },
	Routes = "↑ stump lift  ·  ↓ root brake  ·  ←→ wrestling step  ·  air: palm / stomp  ·  parry: shoulder riposte",
	Description = "A wrestler on his feet: palms that take a grip, a sheath of wood on the forearm, a root that holds a moment.",
	Health = 140, Chakra = 120, ChakraRegen = 8, Speed = 18.5, SprintScale = 1.06, JumpScale = 0.98, AirControlScale = 0.95, AccelerationScale = 0.98,
	CombatTravel = 1.0, CombatDamage = 1.04, DashScale = 0.98, GuardStrength = 0.16, PreferredRange = 3.6,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 86, Damage = 3, Recover = .8 },
	Awakening = { Name = "CONTROLLED GROWTH", Speed = 1.02, Damage = 1.05, Riposte = { any = "RootRise" }, Color = { 120, 200, 90 } },
	Motion = { body = "Lion", clips = "Sapling", weapons = "none", springy = false,
		-- Square, low and wide like a wrestler, both open hands forward.
		stance = {root={y=-.6,pitch=10,yaw=14},torso={pitch=8,yaw=-4},head={pitch=-8,yaw=-6},
			ra={raise=60,out=10,twist=0,elbow=70,wrist=-10},la={raise=66,out=-6,twist=0,elbow=64,wrist=-10},
			rf={x=.34,z=.5,yaw=20},lf={x=-.26,z=-.5,yaw=-10},breath=1.0,tempo=4.4} },
	-- Bible §3/§5: L1 .17/.07/.22 at 3.2, L2 .22/.08/.23 at 3.5, L3 .28/.09/.36
	-- at 3.7, heavy .34/.09/.42 at 4.
	AttackProfile = {
		Light1={startup=1.89,active=.58,recovery=.79,contact=3.2,range=6.2,zone="body",kind="palm"},
		Light2={startup=2.2,active=.67,recovery=.85,contact=3.5,range=6.5,zone="body",kind="strike"},
		Light3={startup=2.33,active=.64,recovery=1.5,contact=3.7,range=6.7,zone="body",kind="palm",impulseZ=58},
		Heavy={startup=1.13,active=.53,recovery=.81,contact=4,range=7,kind="palm"},
		Launcher={startup=1.0}, DashAttack={startup=1.0,kind="palm"}, Air1={startup=1.0,kind="palm"}, Air2={startup=1.0,kind="palm"},
	},
	Skin = { 214, 170, 130 }, Hair = { 26, 22, 20 }, Outfit = { 150, 74, 46 },
	Techniques = {
		{ Id = "ContactRoot", Name = "Wood: Contact Root", Family = "Projectile", Kind = "root", Ground = true, Cost = 16, Channel = 0.25, Active = 0.06, Recovery = 0.3, Cooldown = 6, Interruptible = true,
			Range = 6, Speed = 44, Damage = 4, Radius = 1.5, Bind = 0.6, AI = { Min = 2, Max = 5.5, Chance = .45 },
			Hint = "A root under the hand runs to the body (6 studs) and holds it a moment • jump or step before it" },
		{ Id = "WoodGuard", Name = "Young Wood Guard", Family = "Counter", Kind = "woodguard", Time = 0.6, Move = "ShoulderRiposte",
			Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.22, Cooldown = 7, Interruptible = false, Range = 6, Radius = 6,
			Hint = "Forearms crossed, the wood takes one frontal blow and breaks • a shoulder answers it" },
	},
}

-- Hiruzen (12–13, the professor as a student): a plain staff held in both
-- hands, the right end for the right distance. The point to measure, the
-- heel to punish the step in, the lever to change the distance; a lever that
-- deflects a frontal into a thrust, a shuriken to close a line while he
-- backs off, a short Katon. Awakening: ease of grip (after a parry the
-- direction picks the end). No Enma, no five natures.
fighters.Professor = {
	Name = "Hiruzen", FullName = "Hiruzen Sarutobi (child)", Age = 13, Title = "THE YOUNG PROFESSOR", Color = { 190, 140, 60 },
	Routes = "↑ staff lever  ·  ↓ heel + retreat  ·  ←→ grip switch  ·  air: thrust / beat down  ·  parry: thrust (awake: the end you choose)",
	Description = "A staff in both hands: the point measures, the heel punishes, the lever changes the distance; a shuriken, a short Katon.",
	Health = 122, Chakra = 125, ChakraRegen = 8.4, Speed = 19, SprintScale = 1.08, JumpScale = 1.0, AirControlScale = 1.0, AccelerationScale = 1.0,
	CombatTravel = 0.95, CombatDamage = 1.0, DashScale = 1.0, GuardStrength = 0.14, PreferredRange = 5,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Shuriken",
	-- One hand leaves the staff for a flat shuriken, no homing.
	ToolMastery = { Kind = "shuriken", Count = 1, Speed = 96, Damage = 2.4, Recover = .6 },
	Awakening = { Name = "EASE OF GRIP", Speed = 1.03, Cooldown = 0.85, Riposte = { any = "StaffThrust", side = "GripSwitch", back = "HeelSweep" }, Color = { 240, 200, 110 } },
	Motion = { body = "Mirage", clips = "Professor", weapons = "none", springy = false,
		-- The staff across the body, left hand forward, right hand back at the
		-- hip, the point low toward the opponent.
		stance = {root={y=-.36,pitch=4,yaw=34},torso={pitch=2,yaw=-14},head={pitch=-4,yaw=-22},
			ra={raise=20,out=10,twist=-20,elbow=80,wrist=0},la={raise=56,out=-20,twist=-10,elbow=40,wrist=0},
			rf={x=.22,z=.64,yaw=34},lf={x=-.08,z=-.58,yaw=-6},breath=.6,tempo=4.6} },
	-- Bible §3/§5: L1 .13/.05/.20 at 4.2, L2 .20/.06/.18 at 3.7, L3 .22/.07/.30
	-- at 4.5, heavy .28/.08/.36 at 5.
	AttackProfile = {
		Light1={startup=1.44,active=.42,recovery=.71,contact=4.2,range=7.4,zone="body",kind="strike"},
		Light2={startup=2.0,active=.5,recovery=.67,contact=3.7,range=6.8,zone="body",kind="slash"},
		Light3={startup=1.83,active=.5,recovery=1.25,contact=4.5,range=7.6,zone="body",kind="palm",impulseZ=46},
		Heavy={startup=.93,active=.47,recovery=.69,contact=5,range=8,kind="slash"},
		Launcher={startup=1.0}, DashAttack={startup=1.0,kind="strike"}, Air1={startup=1.0,kind="strike"}, Air2={startup=1.0,kind="slash"},
	},
	Skin = { 230, 196, 160 }, Hair = { 92, 64, 40 }, Outfit = { 176, 134, 70 },
	Techniques = {
		{ Id = "StaffLeverRead", Name = "Defensive Lever", Family = "Counter", Kind = "staffread", Time = 0.5, Move = "StaffThrust",
			Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.22, Cooldown = 6, Interruptible = false, Range = 6, Radius = 6,
			Hint = "0.5 s: the staff turns a frontal blow aside and the point answers • a feint, the flank or a grab beat it" },
		{ Id = "TrainingKaton", Name = "Katon: Training Breath", Family = "Burst", Kind = "firebreath", Element = "Fire", Cost = 18, Channel = 0.35, Active = 0.12, Recovery = 0.4, Cooldown = 7, Interruptible = true,
			Radius = 10, Arc = 0.6, Damage = 8, Knock = 32, Lift = 6, Range = 10,
			Hint = "The staff at his side, a sign, a short breath of fire • closes one line, open on the sides" },
	},
}

local graphs={
	Rival={
		routes={up="QuillonRise",down="HeelBarrier",side="GuardCut",airUp="AirDrive",airDown="PommelDrop",airSide="AirSwitch"},
		disengage="Kunai",
		riposte="PommelRiposte",
		stringCancels={UchihaKaton=true},
		blockCancels={Tool=true},
		reengage={name="rival",speed=1.0,arrive=3.8,angle=20,chase=.3,recovery=.22},
	},
	Sapling={
		routes={up="StumpRise",down="RootBrake",side="WrestleStep",airUp="AirDrive",airDown="PalmStomp",airSide="AirSwitch"},
		disengage="Kunai",
		riposte="ShoulderRiposte",
		stringCancels={ContactRoot=true},
		blockCancels={},
		reengage={name="sapling",speed=.95,arrive=3.2,angle=0,chase=.32,recovery=.24},
	},
	Professor={
		routes={up="StaffLever",down="HeelSweep",side="GripSwitch",airUp="AirDrive",airDown="StaffBeat",airSide="AirSwitch"},
		disengage="Shuriken",
		riposte="StaffThrust",
		stringCancels={TrainingKaton=true},
		blockCancels={Tool=true},
		reengage={name="professor",speed=.95,arrive=4.4,angle=25,chase=.3,recovery=.22},
	},
}

local function attacks(move,list)
	RosterMoves.add(move,list,{
		-- Madara. Forward after two: the quillon catches the guard, a short
		-- rising cut lifts (his launcher, not a knee). Side after one: an outer
		-- step and a cut on the guarding arm (the string goes on). Away after
		-- two: a low heel, the blade held across as he backs off. Air down: the
		-- pommel brought down. The pommel riposte (read, parry) and the
		-- awakening's angled cut round the guard.
		QuillonRise={{.16,.14,.3,8,2.6,"Launched",V(0,56,6),1.18},{contact=3.8,range=7,width=5,height=7,zone="chin",kind="launch",side=1,twist=10,lean=-8,arm=130,step=1.05}},
		GuardCut={{.1,.12,.22,6,1,"HitStun",V(0,4,10),.34},{contact=3.8,range=6.8,width=6,zone="body",kind="slash",side=-1,twist=40,lean=8,arm=100,step=1,chain=true,orbit=20}},
		HeelBarrier={{.12,.14,.34,7,.6,"Knockdown",V(0,6,22),.64},{contact=3.4,range=6.6,width=6,height=3.5,zone="legs",kind="sweep",side=1,twist=30,lean=10,arm=60,step=.9,retreat=.8}},
		PommelDrop={{.09,.12,.24,7,2,"Spiked",V(0,-72,6),.9},{contact=3,range=6,zone="head",kind="spike",side=1,twist=10,lean=30,arm=100,step=1,air=true}},
		PommelRiposte={{.05,.12,.26,8,1.8,"Knockback",V(0,10,40),.48},{contact=3,range=5.8,zone="body",kind="palm",side=-1,twist=20,lean=12,arm=80,step=1.1}},
		SharinganCut={{.05,.12,.24,9,1.4,"HitStun",V(0,5,12),.42},{contact=3.8,range=6.8,width=6.5,zone="body",kind="slash",side=-1,twist=60,lean=8,arm=110,step=1.05,lateral=true,orbit=24}},
		-- Hashirama. Forward after two: the shoulder pushes the body onto a low
		-- stump that lifts it (one local launcher, no tree). Side after one:
		-- the hand fixes the arm, a wrestler's step to the side (a root follows
		-- only the contact point). Away after two: he lets go, palm to the
		-- ground, a low root brakes the chase. Air down: a stomp. The shoulder
		-- riposte, and the awakening's root at the point of contact.
		StumpRise={{.18,.14,.3,8,2.4,"Launched",V(0,54,4),1.2},{contact=3.2,range=6.4,width=5.5,height=7,zone="chin",kind="launch",side=1,twist=16,lean=14,arm=60,step=1.1}},
		WrestleStep={{.1,.12,.22,6,.8,"HitStun",V(0,3,9),.36},{contact=3.0,range=6,width=6,zone="body",kind="palm",side=1,twist=50,lean=10,arm=70,step=1,chain=true,orbit=18,lateral=true}},
		RootBrake={{.14,.14,.34,7,.4,"Knockdown",V(0,6,18),.66},{contact=3.4,range=6.6,width=6,height=3.5,zone="legs",kind="sweep",side=-1,twist=20,lean=30,arm=40,step=.9}},
		PalmStomp={{.1,.12,.24,7,2,"Spiked",V(0,-74,4),.9},{contact=3,range=6,zone="head",kind="spike",side=1,twist=0,lean=34,arm=90,step=1,air=true}},
		ShoulderRiposte={{.05,.12,.28,8,2.2,"Knockback",V(0,10,44),.5},{contact=2.8,range=5.6,width=6,zone="body",kind="heavy",side=1,twist=30,lean=22,arm=40,step=1.2}},
		RootRise={{.06,.14,.28,8,0,"Launched",V(0,52,4),1.15},{contact=3.4,range=7,width=5,height=7,zone="legs",kind="launch",side=1,twist=0,lean=20,arm=40,step=.9}},
		-- Hiruzen. Forward after two: the point slipped under the arm, then the
		-- lever lifts (his launcher). Side after one: the hands swap on the
		-- staff, the heel strikes from the other side (the string goes on).
		-- Away after two: a low heel strike and a step back, the point still
		-- covering. Air down: the staff beaten down. The thrust that answers
		-- a lever or a parry.
		StaffLever={{.16,.14,.3,8,2.4,"Launched",V(0,54,6),1.18},{contact=4.4,range=7.6,width=5,height=7,zone="chin",kind="launch",side=1,twist=14,lean=-10,arm=120,step=1.05}},
		GripSwitch={{.1,.12,.22,6,.6,"HitStun",V(0,4,10),.34},{contact=4.0,range=7.2,width=6,zone="body",kind="slash",side=-1,twist=50,lean=6,arm=100,step=1,chain=true,orbit=26}},
		HeelSweep={{.12,.14,.34,7,0,"Knockdown",V(0,6,20),.62},{contact=4.2,range=7.4,width=6,height=3.5,zone="legs",kind="sweep",side=-1,twist=30,lean=16,arm=80,step=.8,retreat=1.6}},
		StaffBeat={{.09,.12,.24,7,2,"Spiked",V(0,-72,6),.9},{contact=3.8,range=7,zone="head",kind="spike",side=1,twist=10,lean=30,arm=150,step=1,air=true}},
		StaffThrust={{.05,.1,.26,8,2.2,"Knockback",V(0,8,40),.46},{contact=4.4,range=7.6,width=4,zone="body",kind="strike",side=1,twist=10,lean=10,arm=90,step=1.15}},
	})
end

return {
	fighters=fighters,
	graphs=graphs,
	attacks=attacks,
}
