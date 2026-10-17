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
-- dome round the opponent (his mirror step strikes harder inside it).
fighters.Mirror = {
	Name = "Haku", FullName = "Haku Yuki", Age = 15, Title = "THE ICE MIRROR", Color = { 150, 206, 240 },
	Routes = "↑ rising palm  ·  ↓ low sweep  ·  ←→ ice slide (a cut that keeps the string)  ·  heavy after one: senbon to a vital point (slows)  ·  air: drive / spike / switch",
	Description = "Ice Release: senbon at the vital points, needles of water, the mirror step and the Demonic Ice Mirrors.",
	Health = 115, Chakra = 125, ChakraRegen = 8.4, Speed = 20, SprintScale = 1.12, JumpScale = 1.08, AirControlScale = 1.12, AccelerationScale = 1.12,
	CombatTravel = 1.06, CombatDamage = 0.9, DashScale = 1.12, GuardStrength = 0.1, PreferredRange = 11,
	ComboToolCancel = true, CombatStyle = "Angles", Tool = "Shuriken",
	-- Three senbon at once, fast and light; each one that lands slows a little.
	ToolMastery = { Kind = "shuriken", Projectile = "senbon", Count = 3, Speed = 112, Damage = 1.4, Recover = .6, Contact = { Slow = { Scale = .85, Time = 1 } } },
	-- Awakening: inside the mirrors. Faster legs, techniques back almost at
	-- once, cheaper ice.
	Awakening = { Name = "CRYSTAL ICE MIRRORS", Speed = 1.15, Regen = 1.4, Cooldown = 0.45, CostScale = 0.6, Color = { 200, 236, 255 } },
	Motion = { body = "Mirage", weapons = "shuriken", springy = true,
		borrow = { SenbonStab = "Light2", IceSlide = "CircleStep" },
		-- Light and upright, weight forward; the right hand up at the face with
		-- senbon between the fingers, the left open low.
		stance = {root={y=-.28,pitch=4,yaw=30},torso={pitch=2,yaw=-10},head={pitch=-2,yaw=-16},
			ra={raise=96,out=-8,twist=40,elbow=118,wrist=-10},la={raise=30,out=-16,twist=-20,elbow=40,wrist=-20},
			rf={x=.2,z=.62,yaw=36},lf={x=-.08,z=-.6,yaw=-6},breath=.9,tempo=6.8} },
	AttackProfile = {
		Light1={startup=.88,recovery=.88,travel=1.06},Light2={startup=.9,recovery=.88,travel=1.06,kind="palm"},
		Light3={startup=.96,recovery=.95,impulseZ=48,kind="kick"},Heavy={startup=.96},
		Launcher={startup=.94,impulseY=54},DashAttack={startup=.88,travel=1.1},Air1={startup=.9},Air2={startup=.92},
	},
	Skin = { 238, 220, 204 }, Hair = { 30, 30, 36 }, Outfit = { 110, 140, 112 },
	Techniques = {
		{ Id = "WaterNeedles", Name = "Thousand Flying Water Needles", Family = "Projectile", Kind = "ice", Element = "Water", Cost = 16, Channel = 0.3, Active = 0.05, Recovery = 0.3, Cooldown = 4.5, Interruptible = true,
			Range = 34, Speed = 86, Damage = 2.2, Count = 7, Spread = 0.5, Radius = .7, Slow = { Scale = .8, Time = 1.4 }, Hint = "A fan of ice needles • each one slows • hard to dodge sideways" },
		{ Id = "MirrorStep", Name = "Ice Mirror Step", Family = "Teleport", Kind = "mirror", To = "Side", Distance = 3.4, Move = "SenbonStab", Damage = 7, InZone = 1.6, ZoneName = "mirrors",
			Cost = 14, Channel = 0.1, Active = 0.04, Recovery = 0.2, Cooldown = 3.6, Interruptible = true, Range = 30, Invuln = .15,
			Hint = "Out of a mirror at his flank • senbon to a vital point • harder inside the dome", AI = { Min = 6, Max = 28 } },
		{ Id = "IceMirrors", Name = "Demonic Ice Mirrors", Family = "Zone", Kind = "mirror", ZoneKind = "Ice", At = "Target", Element = "Water", Cost = 28, Channel = 0.55, Active = 0.2, Recovery = 0.35, Cooldown = 12, Interruptible = true,
			Range = 30, Radius = 7.5, Time = 5.5, Damage = 3, Slow = { Scale = .72 }, Hint = "A dome of mirrors round the opponent • it slows and cuts • his mirror step strikes harder inside" },
	},
}

-- Zabuza (14, the Mist's young Swordsman): the cleaver. Slow, long, heavy
-- strikes with real reach; the Hidden Mist, the Silent Killing out of it
-- (much harder while the body stands in his mist) and the Water Prison.
fighters.Mist = {
	Name = "Zabuza", FullName = "Zabuza Momochi", Age = 14, Title = "THE DEMON OF THE MIST", Color = { 120, 150, 170 },
	Routes = "↑ cleaver rising cut  ·  ↓ cleaver brought down  ·  ←→ wide arc that throws aside  ·  heavy after one: the hilt  ·  air: drive / cleaver dive",
	Description = "Kubikiribōchō: slow, long and heavy. The Hidden Mist, the Silent Killing out of it, the Water Prison.",
	Health = 150, Chakra = 110, ChakraRegen = 7, Speed = 18.5, SprintScale = 1.1, JumpScale = 1.0, AirControlScale = 0.95, AccelerationScale = 0.98,
	CombatTravel = 0.92, CombatDamage = 1.12, DashScale = 1.0, GuardStrength = 0.08, PreferredRange = 6.5,
	ComboToolCancel = true, CombatStyle = "Control", Tool = "Kunai",
	ToolMastery = { Kind = "kunai", Count = 1, Speed = 88, Damage = 3, Recover = .8 },
	-- Awakening: the Demon. Light blows do not stop him, the cleaver bites deeper.
	Awakening = { Name = "DEMON OF THE MIST", Speed = 1.06, Damage = 1.12, Regen = 1.2, Cooldown = 0.7, Buff = { Heavy = true }, Color = { 170, 210, 230 } },
	-- The closed-fan clips are a long heavy weapon swung two-handed: the
	-- cleaver's (GaleFX draws the fan for Temari only).
	Motion = { body = "Mirage", clips = "Gale", weapons = "none", springy = false,
		borrow = { CleaverRise = "Updraft", CleaverDrop = "FanSlam", CleaverArc = "FanPirouette", CleaverHilt = "FanBackhand", CleaverDive = "FanDive", SilentCleave = "Heavy" },
		-- Tall and loose, the cleaver's weight on the right shoulder, the left
		-- hand forward in the one-handed seal.
		stance = {root={y=-.3,pitch=2,yaw=28},torso={pitch=4,yaw=-12},head={pitch=0,yaw=-14},
			ra={raise=120,out=24,twist=-40,elbow=120,wrist=0},la={raise=60,out=-10,twist=-20,elbow=70,wrist=-10},
			rf={x=.24,z=.7,yaw=34},lf={x=-.12,z=-.66,yaw=-6},breath=.6,tempo=4.2} },
	AttackProfile = {
		Light1={startup=1.08,recovery=1.04,travel=.85,range=7.6,depth=5.6,offset=3.6,width=5,contact=4.8,damage=1.05,kind="slash"},
		Light2={startup=1.1,recovery=1.04,travel=.85,range=7.6,depth=5.6,offset=3.6,width=7,contact=4.8,damage=1.05,kind="slash"},
		Light3={startup=1.14,recovery=1.08,travel=.8,range=8,depth=6,offset=3.8,width=7,contact=4.8,impulseZ=64,kind="slash"},
		Heavy={startup=1.1,range=8,depth=6,offset=3.8,contact=4.8,kind="heavy"},
		DashAttack={travel=.9,range=7.6,contact=4.6},Air1={range=7.2,contact=4.6},Air2={range=7.2,contact=4.6},
	},
	Skin = { 228, 204, 182 }, Hair = { 30, 30, 34 }, Outfit = { 120, 128, 130 },
	Techniques = {
		{ Id = "HiddenMist", Name = "Hidden Mist", Family = "Zone", Kind = "mist", ZoneKind = "Mist", At = "Self", Element = "Water", Cost = 20, Channel = 0.4, Active = 0.2, Recovery = 0.3, Cooldown = 14, Interruptible = true,
			Range = 16, Radius = 16, Time = 8, Damage = 0, Slow = { Scale = .86 }, Hint = "A thick mist round him • the opponent is slowed in it • the Silent Killing strikes far harder there" },
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
	Routes = "↑ launcher  ·  ↓ sweep  ·  ←→ camellia arc (keeps the string)  ·  heavy after one: bone thrust  ·  air: drive / spike / switch",
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
	Motion = { body = "Lion", weapons = "none", springy = false,
		borrow = { BoneThrust = "Heavy", CamelliaArc = "Light3", WillowCut = "DashAttack" },
		-- A dancer's guard: upright and calm, the right arm forward along the
		-- line (the bone blade from the palm), the left back.
		stance = {root={y=-.36,pitch=2,yaw=34},torso={pitch=0,yaw=-14},head={pitch=-2,yaw=-20},
			ra={raise=84,out=-4,twist=0,elbow=20,wrist=0},la={raise=20,out=26,twist=-10,elbow=50,wrist=0},
			rf={x=.26,z=.72,yaw=40},lf={x=-.1,z=-.7,yaw=-6},breath=.6,tempo=5} },
	AttackProfile = {
		Light1={startup=.94,recovery=.92,range=6.6,kind="slash"},Light2={startup=.94,recovery=.92,range=6.6,kind="slash"},
		Light3={startup=1.0,recovery=.96,impulseZ=52},Heavy={startup=1.0,range=7},
		Launcher={startup=.98,impulseY=56},DashAttack={startup=.94,travel=1.06},Air1={startup=.94},Air2={startup=.96},
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
		routes={up="Launcher",down="Sweep",side="IceSlide",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="SenbonStab",
		stringCancels={MirrorStep=true,WaterNeedles=true},
		blockCancels={Tool=true},
		-- Never straight in: a quick re-entry at a wide angle.
		reengage={name="mirror",speed=1.2,arrive=3.4,angle=40,shuffle=true,chase=.26,recovery=.18},
	},
	Mist={
		routes={up="CleaverRise",down="CleaverDrop",side="CleaverArc",airUp="AirDrive",airDown="CleaverDive"},
		heavyAfterOne="CleaverHilt",
		stringCancels={SilentKilling=true},
		blockCancels={},
		-- Unhurried: walks the body down, straight in, slower than most.
		reengage={name="mist",speed=.92,arrive=4.2,angle=0,minRange=6,chase=.3,recovery=.24},
	},
	Bone={
		routes={up="Launcher",down="Sweep",side="CamelliaArc",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"},
		disengage="Kunai",
		heavyAfterOne="BoneThrust",
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
		IceSlide={{.1,.14,.24,6,3.2,"HitStun",V(0,4,12),.38},{contact=3.4,range=6.5,width=5,zone="legs",kind="slash",side=1,twist=40,lean=16,arm=80,step=1.1,orbit=30,chain=true}},
		-- Zabuza: the cleaver. Long reach (he stops further out), slow, heavy.
		CleaverRise={{.17,.15,.32,9,1.4,"Launched",V(0,52,6),1.2},{contact=4.8,range=8,width=6,height=8,zone="chin",kind="launch",side=1,twist=14,lean=-26,arm=120,step=1.1,breaksShield=true}},
		CleaverDrop={{.18,.14,.38,11,1.4,"Knockdown",V(0,6,14),.72},{contact=4.8,range=8,width=5,height=7,zone="head",kind="heavy",side=1,twist=10,lean=32,arm=124,step=1.15}},
		CleaverArc={{.13,.18,.3,8,.8,"Knockback",V(0,8,38),.44},{contact=4.6,range=8.2,width=9,height=6,zone="body",kind="slash",side=1,twist=92,lean=6,arm=84,step=1.0,lateral=true}},
		CleaverHilt={{.1,.12,.32,9,1.6,"Knockback",V(0,12,50),.5},{contact=4.2,range=7,width=6,zone="body",kind="heavy",side=-1,twist=48,lean=12,arm=96,step=1.15}},
		CleaverDive={{.11,.14,.26,8,1.5,"Spiked",V(0,-72,4),.9},{contact=4.4,range=7.8,width=6,height=8,zone="head",kind="spike",side=1,twist=10,lean=42,arm=124,step=1,air=true}},
		SilentCleave={{.08,.16,.36,13,1.2,"Knockdown",V(0,10,30),.7},{contact=4.4,range=8,width=7,height=7,zone="body",kind="heavy",side=1,twist=60,lean=24,arm=120,step=1.2}},
		-- Kimimaro: bone through the guard's gap, the camellia's arc that
		-- keeps the string, and the willow's lunge.
		BoneThrust={{.1,.12,.32,10,3.2,"Knockback",V(0,10,58),.5},{contact=3.8,range=7,zone="body",kind="heavy",side=1,twist=24,lean=22,arm=110,step=1.25}},
		CamelliaArc={{.1,.14,.24,6,1.6,"HitStun",V(0,4,12),.38},{contact=3.6,range=6.8,width=8,zone="body",kind="slash",side=1,twist=70,lean=8,arm=96,step=1.05,orbit=24,chain=true}},
		WillowCut={{.05,.22,.42,12,10,"Knockback",V(0,12,52),.55},{contact=3.6,range=7,width=5,zone="body",kind="heavy",side=1,twist=20,lean=30,arm=110,step=1.4}},
	})
end

return {
	fighters=fighters,
	graphs=graphs,
	attacks=attacks,
}
