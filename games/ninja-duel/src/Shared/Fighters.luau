return {
	Flashstep = {
		Name = "Minato", FullName = "Minato Namikaze", Age = 13, Title = "THE FAST PRODIGY", Color = { 82, 177, 244 },
		Routes = "↑ rising kick (seals the body: 2 follows it up)  ·  ↓ spinning leg sweep (plants a marked kunai)  ·  ←→ angle step  ·  air: push kick / axe kick / flash switch",
		Description = "Decision speed. Kunai placement, angle changes and an unfinished teleport seal.",
		Health = 125, Chakra = 110, ChakraRegen = 8, Speed = 19.5, SprintScale = 1.12, JumpScale = 1.1, AirControlScale = 1.15, AccelerationScale = 1.15,
		CombatTravel = 1.18, CombatDamage = 1, DashScale = 1.15, GuardStrength = 0.10, PreferredRange = 6,
		ComboToolCancel = true, CombatStyle = "Angles", Tool = "Kunai",
		-- Shared ninja tools: everyone throws; mastery changes what a throw does.
		-- Minato: one fast kunai, the quickest recovery (the seals are his art).
		ToolMastery = { Kind = "kunai", Count = 1, Speed = 96, Damage = 3, Recover = .55 },
		-- Awakening: the Yellow Flash. Relocations chain: every Flying Thunder God
		-- leaves a seal where he stood (FlashWake), a body he launched or knocked
		-- away is a destination by itself (FlashPursuit), the arrival stays open
		-- longer; faster legs and techniques back almost at once.
		Awakening = { Name = "YELLOW FLASH", Speed = 1.18, Regen = 1.5, Cooldown = 0.4, FlashWake = true, FlashPursuit = true, Arrival = 0.8, Color = { 255, 214, 92 } },
		AttackProfile = {
			Light1={startup=.82,recovery=.9,travel=1.08,angle=.24,kind="slash"},Light2={startup=.84,recovery=.9,travel=1.12,angle=-.3,kind="palm"},
			Light3={startup=.82,recovery=.88,travel=1.2,angle=.36,impulseZ=52},Launcher={startup=.72,travel=1.16,impulseY=62},
			DashAttack={startup=.78,travel=1.16,angle=-.18},Air1={startup=.8,angle=.24},Air2={startup=.82,angle=-.3},Slam={startup=.78,recovery=.86},
		},
		Skin = { 225, 196, 166 }, Hair = { 225, 228, 212 }, Outfit = { 45, 104, 156 },
		Techniques = {
			-- Thrown while running: the seal travels as a real kunai and can be
			-- reached mid-flight by Flying Thunder God.
			{ Id = "MarkedBlade", Name = "Marked Kunai", Mobile = true, Throw = "MarkedKunai", Cost = 10, Channel = 0.12, Active = 0.02, Recovery = 0, Cooldown = 2.2, Interruptible = true, Range = 66, Damage = 6, Hint = "Plants a seal (two held at most) • a hit seals the body" },
			{ Id = "Flashstep", Name = "Flying Thunder God", Cost = 16, Channel = 0.06, Active = 0.04, Recovery = 0.2, Cooldown = 1.5, Interruptible = true, Flow = true, Range = 90, Requires = "Anchor", Hint = "Stick picks the seal and the side • strike or 3 on arrival" },
			{ Id = "BurstStrike", Name = "Rasengan", Cost = 24, Channel = 0.3, Active = 0.08, Recovery = 0.5, Cooldown = 5.5, Interruptible = true, Range = 8, Damage = 20, Hint = "Instant after a teleport • plunges when airborne • ends a clean string" },
			{ Id = "Quickstep", Name = "Quickstep", Cost = 12, Channel = 0.11, Active = 0.08, Recovery = 0.21, Cooldown = 2.3, Interruptible = true, Flow = true, Range = 12, Hint = "Create an angle • no guaranteed hit" },
			-- Thrown off the kunai's edge on the run: cuts enemy blades out of its
			-- lane; a body it cuts is thrown a step sideways with a short wind seal
			-- (Flying Thunder God lands beside it). Techniques.WindCut.
			{ Id = "WindCut", Name = "Wind Cut", Element = "Wind", Mobile = true, Throw = "Kunai", Cost = 14, Channel = 0.16, Active = 0.02, Recovery = 0, Cooldown = 3.2, Interruptible = true, Range = 40, Speed = 104, Damage = 6, Hint = "Thrown on the run • cuts blades in its lane • a cut body is marked: 2 lands beside it" },
		},
	},
	Mirage = {
		Name = "Itachi", FullName = "Itachi Uchiha", Age = 13, Title = "THE SHARINGAN PRODIGY", Color = { 222, 70, 80 },
		Routes = "↑ rising palm (shuriken cover the climb)  ·  ↓ reaping sweep  ·  ←→ feint step (an afterimage stays)  ·  air: side kick / hammer drop / hook switch",
		Description = "Sharingan already awakened. Reads, precise shuriken, deception and Katon fire.",
		Health = 145, Chakra = 125, ChakraRegen = 7.2, Speed = 18, SprintScale = 1.0, JumpScale = 0.98, AirControlScale = 0.95, AccelerationScale = 0.98,
		CombatTravel = 0.98, CombatDamage = 1.1, DashScale = 0.98, GuardStrength = 0.08, PreferredRange = 10,
		-- The Sharingan (three tomoe at 13): it sees strikes coming. Wider parry
		-- and perfect-dodge windows, each successful one opens a counter, and a
		-- raised guard tracks a teleport instead of being crossed up.
		Sharingan = { ParryWindow = 0.3, PerfectDodge = 0.22, Counter = 0.9 },
		ComboToolCancel = true, CombatStyle = "Control", Tool = "Shuriken",
		-- Itachi: a pair of shuriken; side + tool is Shuriken Geometry (a wide
		-- blade struck by a second one, redirected into the flank); his blades
		-- ricochet off walls and cover once; in the air he fans three down.
		ToolMastery = { Kind = "shuriken", Count = 2, Speed = 84, Damage = 2, Recover = .75, Geometry = true, Ricochet = true, AirSpread = 3 },
		-- Awakening: Sharingan focus. His raised guard reads (any frontal blow
		-- that meets it is parried and read: he slips aside, it bites the
		-- afterimage), every swing that misses close to him is read
		-- (WhiffRead, studs), cheaper and faster jutsu.
		Awakening = { Name = "SHARINGAN FOCUS", Speed = 1.06, Regen = 1.4, Cooldown = 0.6, CostScale = 0.6, Windows = 1.5, GuardRead = true, WhiffRead = 9, Color = { 230, 40, 50 } },
		AttackProfile = {
			Light1={startup=.96,recovery=.9,travel=.92,range=6.6},Light2={startup=.98,recovery=.88,travel=.9,range=7,chainTool=true,kind="palm"},
			Light3={startup=1.02,recovery=1.0,travel=.86,impulseZ=60,kind="kick"},Heavy={startup=.98,recovery=1.02,travel=.9},
			Launcher={startup=1.0,travel=.86,impulseY=53,impulseZ=20},DashAttack={startup=.95,travel=.92},
			Air1={startup=.98,travel=.9},Air2={startup=1.0,travel=.88},Slam={startup=1.0,recovery=1.0},
		},
		Skin = { 197, 164, 143 }, Hair = { 30, 31, 43 }, Outfit = { 69, 49, 66 },
		Techniques = {
			{ Id = "Read", Name = "Sharingan Read", Cost = 14, Channel = 0.1, Active = 1.0, Recovery = 0.2, Cooldown = 3.6, Interruptible = false, Range = 10, Hint = "Read one frontal strike: he slips aside, it bites the afterimage • strike in the stance = instant counter" },
			{ Id = "NeedleFan", Name = "Shadow Shuriken", Cost = 18, Channel = 0.26, Active = 0.08, Recovery = 0.26, Cooldown = 3.6, Interruptible = true, Flow = true, Range = 56, Damage = 2, Hint = "Five blades, then two hidden ones aimed at the dodge" },
			-- His image stays where he stood and he withdraws behind it, on the
			-- opponent's line of sight: a swing that reaches the image is caught
			-- (Techniques.MirageCast / whiffRead).
			{ Id = "MirageCast", Name = "Genjutsu: Mirage", Cost = 26, Channel = 0.42, Active = 0.06, Recovery = 0.2, Cooldown = 7, Interruptible = true, Flow = true, Range = 23, Requires = "Target", Hint = "His image stays, he withdraws behind it • a swing at the image is caught • trust the body" },
			{ Id = "FireBloom", Name = "Great Fireball", Element = "Fire", Cost = 26, Channel = 0.55, Active = 0.42, Recovery = 0.36, Cooldown = 5.5, Interruptible = true, Feintable = true, Range = 76, Speed = 58, Damage = 16, Hint = "A miss leaves the lane burning" },
			{ Id = "PhoenixFlower", Name = "Phoenix Flower", Element = "Fire", Cost = 20, Channel = 0.3, Active = 0.32, Recovery = 0.3, Cooldown = 5, Interruptible = true, Range = 60, Speed = 72, Damage = 4, Hint = "Five small flames fanned at the opponent • pressure" },
		},
	},
	-- Third prototype: the Hyuga genius at the Chunin Exam finals. Pure taijutsu
	-- with a different engine: palms that attack chakra, not health alone.
	GentleFist = {
		Name = "Neji", FullName = "Neji Hyuga", Age = 13, Title = "THE HYUGA GENIUS", Color = { 176, 196, 255 },
		Routes = "↑ palm heel under the chin  ·  ↓ low rotation sweep (closes two points)  ·  ←→ circular step onto a chakra point  ·  air: twin palms / descending palm / spinning palm",
		Description = "Byakugan and the Gentle Fist. Palms that close chakra points, a perfect rotation defence.",
		Health = 135, Chakra = 115, ChakraRegen = 7.6, Speed = 18.5, SprintScale = 1.0, JumpScale = 0.98, AirControlScale = 0.95, AccelerationScale = 1.02,
		CombatTravel = 1.0, CombatDamage = 0.95, DashScale = 1.0, GuardStrength = 0.1, PreferredRange = 5,
		ComboToolCancel = true, CombatStyle = "GentleFist", Tool = "Kunai",
		-- Neji: standard kunai, secondary to the Gentle Fist.
		ToolMastery = { Kind = "kunai", Count = 1, Speed = 86, Damage = 3, Recover = .85 },
		-- Awakening: Byakugan full field. No blind spot; he sees the whole network:
		-- a clean palm closes two chakra points (Points) and a palm that breaks a
		-- jutsu being moulded seals the techniques (ChannelCut, s); palms drain more.
		Awakening = { Name = "BYAKUGAN FULL FIELD", Speed = 1.08, Damage = 1.06, Regen = 1.5, Cooldown = 0.6, NoBlindSpot = true, Drain = 1.8, Points = 2, ChannelCut = 1.5, Color = { 200, 214, 255 } },
		-- Byakugan: near-360-degree sight. His guard covers every side except a
		-- narrow blind spot straight behind, and genjutsu decoys do not fool him.
		Byakugan = { BlindSpot = 0.9 },
		-- Gentle Fist: every palm drains chakra (even through a guard) and a clean
		-- one closes a chakra point, slowing the victim's chakra recovery.
		GentleFist = { Drain = 6, GuardDrain = 3, RegenCut = 0.15, MaxPoints = 4, Duration = 5 },
		AttackProfile = {
			Light1={startup=.92,recovery=.9,travel=1.0,range=6.4,kind="tenketsu",zone="body"},Light2={startup=.94,recovery=.9,travel=1.0,range=6.6,kind="tenketsu"},
			Light3={startup=1.0,recovery=.96,travel=1.05,impulseZ=54,kind="palm"},Heavy={startup=1.02,recovery=1.0,kind="palm"},
			Launcher={startup=.98,travel=.95,impulseY=56},DashAttack={startup=.94,travel=1.02},
			Air1={startup=.96},Air2={startup=.98},Slam={startup=1.0},
		},
		Skin = { 228, 202, 178 }, Hair = { 52, 36, 30 }, Outfit = { 226, 220, 206 },
		Techniques = {
			{ Id = "Rotation", Name = "Rotation", Cost = 24, Channel = 0.04, Active = 0.55, Recovery = 0.24, Cooldown = 6, Interruptible = false, Range = 7, Damage = 6, Hint = "Spinning dome • repels strikes and blades • counter after" },
			{ Id = "VacuumPalm", Name = "Vacuum Palm", Cost = 14, Channel = 0.18, Active = 0.06, Recovery = 0.26, Cooldown = 2.8, Interruptible = true, Flow = true, Range = 32, Speed = 96, Damage = 7, Hint = "Air-pressure palm • pushes into walls • ends a clean string" },
			{ Id = "SixtyFourPalms", Name = "64 Palms", Cost = 30, Channel = 0.22, Active = 0.12, Recovery = 0.4, Cooldown = 10, Interruptible = true, Range = 5, Damage = 3, Hint = "Point blank • each closed point adds palms and seal time • four closed: the guard collapses" },
		},
	},
	-- Fourth playable prototype: Sasuke at the Chunin Exam (12). Faster and
	-- more aggressive than his brother, a kicking taijutsu base, fire, wire and
	-- the Chidori he has just learned: one opening becomes a mobile assault,
	-- but every big commitment can be punished.
	Lion = {
		Name = "Sasuke", FullName = "Sasuke Uchiha", Age = 12, Title = "THE ROOKIE OF THE YEAR", Color = { 92, 132, 255 },
		Routes = "↑ rising kick into Shadow of the Dancing Leaf (heavy in the air: LION COMBO)  ·  ↓ low kick sweep  ·  ←→ vault over into a back kick  ·  air: drive / axe kick / switch",
		Description = "Pressure. Kicks, wire and fire. A launcher he follows into the air and a Chidori that ends everything — or him.",
		Health = 120, Chakra = 105, ChakraRegen = 7.5, Speed = 19, SprintScale = 1.1, JumpScale = 1.15, AirControlScale = 1.15, AccelerationScale = 1.12,
		CombatTravel = 1.12, CombatDamage = 1.05, DashScale = 1.08, GuardStrength = 0.08, PreferredRange = 6,
		ComboToolCancel = true, CombatStyle = "Lion", Tool = "Shuriken",
		-- Aggressive shuriken use: a fast pair and a short recovery.
		ToolMastery = { Kind = "shuriken", Count = 2, Speed = 92, Damage = 2, Recover = .6 },
		-- Two-tomoe Sharingan: smaller windows than Itachi's, the same idea.
		Sharingan = { ParryWindow = 0.24, PerfectDodge = 0.18, Counter = 0.7 },
		-- The cursed seal: faster and harder, but it eats his body while it burns.
		-- His kicks do not let go (Extension: the third kick and the air drive
		-- stagger instead of knocking away, the string stays open), every
		-- launcher becomes the Dancing Leaf (CursedLeaf), the drain doubles when
		-- he stops landing blows (Hunger) and pauses after each one (Feed, s),
		-- and the cursed body takes more (Vulnerability).
		Awakening = { Name = "CURSE MARK", Speed = 1.15, Damage = 1.12, Regen = 1.3, Cooldown = 0.6, HealthDrain = 1.4, Hunger = 2, Feed = 0.6, Vulnerability = 0.12, Extension = true, CursedLeaf = true, Color = { 120, 60, 200 } },
		AttackProfile = {
			Light1={startup=.9,recovery=.95},Light2={startup=.95,range=6.6,kind="kick"},Light3={startup=1.05,impulseZ=56,range=6.8},
			DashAttack={travel=1.1},Air1={startup=.92},Air2={startup=.92},
		},
		Skin = { 236, 210, 190 }, Hair = { 24, 26, 40 }, Outfit = { 34, 40, 72 },
		Techniques = {
			{ Id = "FireBloom", Name = "Great Fireball", Element = "Fire", Cost = 24, Channel = 0.5, Active = 0.4, Recovery = 0.36, Cooldown = 5.5, Interruptible = true, Feintable = true, Range = 70, Speed = 58, Damage = 15, Hint = "On a wired opponent: Dragon Flame runs along the wire" },
			{ Id = "PhoenixFlower", Name = "Phoenix Flower", Element = "Fire", Cost = 20, Channel = 0.28, Active = 0.32, Recovery = 0.3, Cooldown = 5, Interruptible = true, Range = 56, Speed = 72, Damage = 4, HiddenBlades = true, Hint = "Flames with two shuriken hidden inside" },
			{ Id = "WireTrap", Name = "Wire Trap", Cost = 18, Channel = 0.18, Active = 0.08, Recovery = 0.3, Cooldown = 6, Interruptible = true, Range = 34, Damage = 3, Hint = "A wired shuriken binds • then 1 for Dragon Flame" },
			{ Id = "Chidori", Name = "Chidori", Element = "Lightning", Cost = 34, Channel = 0.62, Active = 0.05, Recovery = 0.1, Cooldown = 9, Interruptible = true, Range = 20, Damage = 22, Hint = "Charge, then a lightning thrust • a miss leaves him open" },
		},
	},
	-- Fourth prototype: Gaara at the Chunin Exam (12). A slow, patient
	-- controller: the sand blocks for him, strikes at range and binds.
	Sand = {
		Name = "Gaara", FullName = "Gaara of the Sand", Age = 12, Title = "THE SAND PRODIGY", Color = { 222, 176, 112 },
		Description = "The sand fights for him: an automatic shield, long sand lashes and a coffin that binds. Slow, patient, crushing.",
		Health = 140, Chakra = 130, ChakraRegen = 7, Speed = 16.5, SprintScale = 0.85, JumpScale = 0.9, AirControlScale = 0.85, AccelerationScale = 0.85,
		CombatTravel = 0.2, CombatDamage = 1, DashScale = 1, GuardStrength = 0.1, PreferredRange = 11,
		ComboToolCancel = true, CombatStyle = "Sand", Tool = "Sand",
		-- Sand shield: while charged it stops hits by itself (not while he is
		-- attacking or already hurt). A heavy blow, a third string hit or a
		-- Rasengan breaks it outright; charges come back one at a time.
		SandShield = { Charges = 3, Regen = 3.5, Break = 17 },
		-- His heavy is not a punch: sand erupts under the opponent at range.
		HeavyMove = "SandPillar", LauncherMove = "SandPillar",
		-- Dodge: a sand body-flicker (instant reposition) instead of a roll.
		SandFlicker = { Distance = 12 },
		Awakening = { Name = "SHUKAKU'S SAND", Speed = 1.12, Damage = 1.12, Regen = 1.6, Cooldown = 0.5, ShieldRegen = 2, Color = { 222, 176, 112 } },
		AttackProfile = {
			-- Sand lashes: long, narrow volumes in front of him.
			-- Slower than a fist, long to recover and light: the reach is paid for
			-- (pokes that set up the pillar and the coffin, not a damage string).
			Light1={startup=1.45,recovery=1.3,travel=.25,range=8.5,depth=7.5,offset=4.3,width=3.4,damage=.8},Light2={startup=1.45,recovery=1.3,travel=.25,range=8.5,depth=7.5,offset=4.3,width=3.4,damage=.5},
			Light3={startup=1.5,recovery=1.35,travel=.25,range=9,depth=8,offset=4.5,width=4.2,impulseZ=56,damage=.5},DashAttack={startup=1.1,travel=.8,range=8.5},
			Air1={startup=1.1,range=8},Air2={startup=1.1,range=8},Slam={startup=1.1},
		},
		Skin = { 236, 214, 196 }, Hair = { 164, 42, 34 }, Outfit = { 52, 46, 52 },
		Techniques = {
			{ Id = "SandCoffin", Name = "Sand Coffin", Cost = 26, Channel = 0.35, Active = 0.1, Recovery = 0.35, Cooldown = 8, Interruptible = true, Range = 30, Speed = 46, Damage = 18, Hint = "A wave of sand binds, then crushes • substitution escapes" },
			{ Id = "SandShuriken", Name = "Sand Shuriken", Cost = 16, Channel = 0.25, Active = 0.08, Recovery = 0.25, Cooldown = 3.5, Interruptible = true, Range = 38, Damage = 3, Hint = "Six hardened sand blades" },
			{ Id = "DesertWave", Name = "Desert Wave", Element = "Earth", Cost = 22, Channel = 0.26, Active = 0.2, Recovery = 0.3, Cooldown = 6, Interruptible = true, Range = 12, Damage = 7, Hint = "A wall of sand throws close attackers away" },
		},
	},
	-- Stress-test fighter of the next wave (DEC-015): Rock Lee at the Chunin
	-- Exam preliminaries (13). Pure taijutsu: no ninjutsu, no genjutsu, no
	-- blade. Speed, kicks and pressure; the rising kick he follows into the air
	-- (the shared Shadow of the Dancing Leaf) ends in the Primary Lotus, paid
	-- with his own body; the Fifth Gate is his awakening. Sheet:
	-- docs/characters/ROCK_LEE.md (implementation state at its end).
	Leaf = {
		Name = "Rock Lee", FullName = "Rock Lee", Age = 13, Title = "THE TAIJUTSU PRODIGY", Color = { 64, 172, 84 },
		Routes = "↑ Leaf Rising Wind: a rising kick he follows into the air (heavy up there: PRIMARY LOTUS, paid in health)  ·  ↓ Leaf Hurricane: a low spinning kick, the string goes on  ·  ←→ Leaf Whirlwind: a wide spinning kick that catches the side step  ·  air: drive / axe kick / switch",
		Description = "No jutsu, no blade: taijutsu only. The fastest legs, kicks that never stop, a lotus paid with his own body, and the Fifth Gate.",
		Health = 125, Chakra = 100, ChakraRegen = 9.5, Speed = 20, SprintScale = 1.12, JumpScale = 1.15, AirControlScale = 1.12, AccelerationScale = 1.22,
		CombatTravel = 1.15, CombatDamage = 1, DashScale = 1.12, GuardStrength = 0.08, PreferredRange = 4.5,
		ComboToolCancel = false, CombatStyle = "Taijutsu", Tool = "Deflect",
		-- Heavy after two clean hits is the rising kick too (into the chase).
		LauncherMove = "LeafRising",
		-- Motion family (VelmoraMotionEngine.familyOf): Sasuke's kicks as the
		-- base, his own stance (one hand forward, one behind the back), intro,
		-- rising kick, low spin, lotuses; no hand weapon.
		Motion = { body = "Lion", weapons = "none", clips = "Leaf", intro = "Leaf", springy = true },
		-- No blade to throw: the tool button is a deflecting crescent kick
		-- (Techniques.deflectKick). Blades inside a frontal arc are kicked away,
		-- jutsu volumes are not; each deflection frees the next chakra dash.
		Deflect = { Radius = 6.5, Arc = 0.5, Reach = 24, Cooldown = 0.55, FreeRush = 0.6 },
		-- No kawarimi either (he cannot mould ninjutsu): the Rupture. Same key,
		-- charges and window as the substitution, but he stays where he is and a
		-- spinning kick throws a close attacker away (Combat:substitute "burst").
		Substitution = { Mode = "burst", Radius = 5.5, Damage = 4, Knockback = 40, Whiff = 0.3 },
		-- The Fifth Gate (the five gates he opened against Gaara): faster and
		-- harder, the lotus becomes the free Hidden Lotus, but the body burns
		-- (health drain, never to a KO).
		Awakening = { Name = "FIFTH GATE", Speed = 1.28, Damage = 1.1, Regen = 1.6, Cooldown = 0.5, HealthDrain = 2, Color = { 120, 230, 140 } },
		AttackProfile = {
			Light1={startup=.85,recovery=.9,travel=1.1},Light2={startup=.86,recovery=.9,range=6.6,kind="kick",damage=.8},
			Light3={startup=.9,recovery=.95,impulseZ=58,range=6.8,damage=.75},Heavy={startup=.9},
			DashAttack={startup=.9,travel=1.15},Air1={startup=.86},Air2={startup=.86},
		},
		Skin = { 238, 208, 180 }, Hair = { 16, 16, 20 }, Outfit = { 52, 140, 66 },
		Techniques = {
			-- Konoha Daisenpū: a spinning kick that crosses the gap. A taijutsu
			-- strike started by the jutsu pipeline (like the Chidori thrust).
			{ Id = "LeafGreatWhirlwind", Name = "Leaf Great Whirlwind", Cost = 10, Channel = 0.08, Active = 0.05, Recovery = 0.1, Cooldown = 2.6, Interruptible = true, Range = 15, Damage = 9, Hint = "A spinning kick across the gap • knocks away • E to chase • ends a clean string" },
		},
	},
	-- Roster wave (several bodies, hook H12): Naruto in Part I, from the Chunin
	-- Exam to the Valley of the End (13). Shadow clones (two at most) that carry
	-- his routes and are dispelled by one blow, a Rasengan he can only shape
	-- with a clone, the largest reserve; the Nine-Tails chakra takes the clones
	-- away. Server kit: Server/Bodies (the bodies), Server/Legion (his rules).
	-- Sheet: docs/characters/NARUTO.md.
	Legion = {
		Name = "Naruto", FullName = "Naruto Uzumaki", Age = 13, Title = "THE NUMBER ONE SURPRISE", Color = { 255, 140, 40 },
		Routes = "third hit: a clone out kicks from behind  ·  ↑ Uzumaki Barrage: clones kick him up (E, then heavy: NARUTO RENDAN)  ·  ↓ tackle into the legs  ·  ←→ a clone strikes from his side  ·  air: drive / axe kick / switch  ·  Z + R: the kunai turns into a clone",
		Description = "Shadow clones that carry his routes and fall to one blow, a Rasengan he can only shape with a clone, the biggest reserve — and the Nine-Tails' red chakra when it all goes wrong.",
		Health = 140, Chakra = 160, ChakraRegen = 6.5, Speed = 18.5, SprintScale = 1.12, JumpScale = 1.1, AirControlScale = 1.0, AccelerationScale = 1.08,
		CombatTravel = 1.05, CombatDamage = 1, DashScale = 1.05, GuardStrength = 0.08, PreferredRange = 6,
		ComboToolCancel = true, CombatStyle = "Legion", Tool = "Kunai",
		-- A plain kunai; with the chakra chord (Z + R) it is a clone transformed
		-- (Bodies.transform): near the target it pops back and strikes from there.
		ToolMastery = { Kind = "kunai", Count = 1, Speed = 84, Damage = 3, Recover = .7, Transform = "clone" },
		-- Heavy after two clean hits is the launcher route too (the Uzumaki Barrage).
		LauncherMove = "UzumakiKick",
		-- Shadow clones (Server/Bodies, Server/Legion): Max at once, Cost chakra
		-- each, Life seconds, one blow dispels them. On a flank a clone jabs the
		-- opponent (Strike damage, Reach studs) about every Every seconds.
		Bodies = { clone = { Max = 2, Cost = 12, Life = 6, Strike = 4, Reach = 5.4, Every = 1.9 } },
		-- Substitution with a clone out: "it was a clone!" — he swaps places
		-- with it and the body that was being hit puffs away.
		Substitution = { Mode = "clone" },
		-- Motion family: his own stance (a brawler's low open guard), gait (wide
		-- arms, a heavy bouncing stride) and string; air strings and throws from
		-- the shared families; a kunai shows in the hand only to throw it.
		Motion = { body = "Legion", weapons = "palms", clips = "Legion", intro = "Legion", springy = false },
		-- The Nine-Tails chakra (the one-tail cloak of the Valley of the End):
		-- no clones at all (they burst; clone routes become claws, the Rasengan
		-- needs no clone and almost no wind-up), a quicker body (every recovery
		-- x Recovery) and harder blows.
		Awakening = { Name = "NINE-TAILS CHAKRA", Speed = 1.15, Damage = 1.1, Regen = 1.8, Cooldown = 0.5, Recovery = 0.78, NoBodies = true, Color = { 255, 96, 40 } },
		AttackProfile = {
			-- A wide hook, a straight, a push kick: a brawler's string.
			Light1={startup=.94,recovery=.96,travel=1.12,zone="head"},Light2={startup=.96,recovery=.94,travel=1.08,zone="body"},
			Light3={startup=1.02,recovery=1.0,impulseZ=54,kind="kick"},Heavy={startup=1.0,recovery=1.04},
			DashAttack={startup=.95,travel=1.1},Air1={startup=.95},Air2={startup=.95},
		},
		Skin = { 240, 204, 170 }, Hair = { 250, 206, 70 }, Outfit = { 244, 130, 36 },
		Techniques = {
			{ Id = "ShadowClone", Name = "Shadow Clone", Cost = 12, Channel = 0.18, Active = 0.05, Recovery = 0.12, Cooldown = 1.2, Interruptible = true, Flow = true, Range = 30, Hint = "A clone at his side (two at most) • one blow dispels it • routes, the Rasengan and the swap use them" },
			{ Id = "CloneRasengan", Name = "Rasengan", Cost = 22, CloneCost = 12, Channel = 0.45, SoloChannel = 0.6, CloakChannel = 0.2, Active = 0.08, Recovery = 0.45, Cooldown = 6, Interruptible = true, Range = 10, Damage = 22, Hint = "A clone shapes it at his side • strike the clone and it fails • ends a clean string" },
			{ Id = "MassShadowClone", Name = "Multi Shadow Clone", Cost = 30, Channel = 0.3, Active = 0.08, Recovery = 0.2, Cooldown = 10, Interruptible = true, Range = 26, Hint = "Clones burst out on both sides and charge" },
		},
	},
}
