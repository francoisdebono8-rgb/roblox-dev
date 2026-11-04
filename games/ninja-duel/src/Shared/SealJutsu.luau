-- Hand-seal jutsu (DEC-032 §3, user 03/11: « plus de variété que 4 cases
-- comme Storm » ; « Kakashi jeune est un expert du Doton, Gaara a du sable de
-- partout et devrait pouvoir faire ce qu'il veut avec, Naruto a la
-- métamorphose »). Beyond the four quick slots, each prodigy weaves two seals
-- to call a technique of his story (Combat:seal). The seals are the four jutsu
-- buttons: keyboard C (off a wall) then two of 1-4; pad R1 + L3 then two of
-- R1 + □ △ ○ ×. The jutsu goes on the second seal.
--
-- The same four sequences for everyone, so a player learns them once:
--   1-2  TIGER, SNAKE      2-3  SNAKE, RAM      3-4  RAM, RAT      4-1  RAT, TIGER
-- (Gaara has a fifth: 3-1, RAM, TIGER.)
-- Every entry is an ordinary technique spec run by its Family (Server/
-- Families) with its Looks kind (Shared/Looks); Signs is its sequence.
local SealJutsu={}
SealJutsu.Names={"TIGER","SNAKE","RAM","RAT"}
SealJutsu.Glyphs={"寅","巳","未","子"}
SealJutsu.Length=2

SealJutsu.Lion={ -- Sasuke, 12: the Uchiha's fire, the Sharingan, shuriken at every angle
	{ Id = "Soshuha", Name = "Sōshūha: Wired Shuriken", Signs = {1,2}, Family = "Projectile", Kind = "windmill", Cost = 12, Channel = 0.16, Active = 0.04, Recovery = 0.24, Cooldown = 6, Interruptible = true,
		Range = 34, Speed = 92, Damage = 4, Count = 2, Spread = 0.9, Radius = .7, Return = true,
		-- (04/11, replaces Shadow Shuriken: the hidden second blade was his own Phoenix Flower's trick)
		Hint = "Two shuriken on wires thrown wide: past him the wires pull them back and they come in from behind", AI = { Min = 6, Max = 30 } },
	{ Id = "WindmillBlades", Name = "Windmill Triple Blades", Signs = {2,3}, Family = "Projectile", Kind = "fuma", Cost = 14, Channel = 0.24, Active = 0.06, Recovery = 0.26, Cooldown = 6, Interruptible = true,
		Range = 46, Speed = 82, Damage = 4, Count = 3, Spread = 0.5, Radius = 1, Slow = { Scale = .7, Time = 1.2 }, Hint = "Three blades on wires: the body they catch is slowed", AI = { Min = 6, Max = 30 } },
	{ Id = "SharinganCounter", Name = "Sharingan: Counter", Signs = {3,4}, Family = "Counter", Kind = "swordread", Time = 0.7, Move = "LionKick", Damage = 10,
		Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 7, Interruptible = false, Range = 6, Radius = 6, Hint = "The Sharingan sees the blow coming: it is answered by a kick", AI = { Min = 0, Max = 6 } },
	{ Id = "SharinganCopy", Name = "Sharingan: Copy", Signs = {4,1}, AIAs = "Projectile", Cost = 16, Channel = 0.18, Active = 0.06, Recovery = 0.26, Cooldown = 8, Interruptible = true, Range = 40,
		-- (04/11, replaces the Dragon Flame he already breathes down the Wire Trap) The
		-- Sharingan has seen the jutsu he just used: Sasuke sends it back (Server/SealKits).
		Hint = "The Sharingan copies the last jutsu he used on you (6 s) and Sasuke sends it back at him", AI = { Min = 4, Max = 30 } },
}
SealJutsu.Legion={ -- Naruto, 12: transformation, the hidden Fuma, the fox's chakra
	{ Id = "CloneAmbush", Name = "Shadow Clone: Ambush", Signs = {1,2}, AIAs = "Projectile", Cost = 16, Channel = 0.2, Active = 0.06, Recovery = 0.24, Cooldown = 8, Interruptible = true, Range = 22, Damage = 8,
		-- (04/11, replaces Transformation: the log swap was everyone's substitution)
		Hint = "A clone bursts out of the floor under him and kicks him into the air, the way he beat Neji • E to chase", AI = { Min = 3, Max = 20 } },
	{ Id = "HiddenFuma", Name = "Hidden Fuma Shuriken", Signs = {2,3}, Family = "Projectile", Kind = "fuma", Cost = 14, Channel = 0.26, Active = 0.06, Recovery = 0.28, Cooldown = 6, Interruptible = true,
		Range = 56, Speed = 76, Damage = 6, Count = 2, Volley = 0.22, Radius = 1.4, Knock = 22, Hint = "A big shuriken, and a second one hidden in its shadow", AI = { Min = 8, Max = 40 } },
	{ Id = "SummonGamakichi", Name = "Summoning: Gamakichi", Signs = {3,4}, Family = "Projectile", Kind = "toadwater", Summon = "toad", Cost = 22, Channel = 0.34, Active = 0.08, Recovery = 0.3, Cooldown = 10, Interruptible = true,
		Range = 40, Speed = 72, Damage = 9, Radius = 1.6, Knock = 38, Lift = 8,
		-- (04/11, replaces the Nine-Tails chakra: it was his awakening)
		Hint = "Jiraiya's contract: a small toad pops out of the smoke and spits a water bullet that throws him back", AI = { Min = 8, Max = 36 } },
	{ Id = "CloneThrow", Name = "Shadow Clone: Throw", Signs = {4,1}, AIAs = "Strike", Cost = 14, Channel = 0.12, Active = 0.05, Recovery = 0.1, Cooldown = 6, Interruptible = true, Range = 20, Damage = 11,
		-- (04/11, replaces the Uzumaki Charge: it was his own low route, the tackle)
		Hint = "A clone grabs him and throws him across the field, head first into the body", AI = { Min = 6, Max = 18 } },
}
SealJutsu.Sand={ -- Gaara, 12: the sand does anything he wants
	{ Id = "ShukakuArm", Name = "Shukaku's Arm", Signs = {1,2}, Family = "Burst", Kind = "sandarm", Radius = 13, Arc = 0.25, Damage = 12, Knock = 48, Lift = 12,
		Cost = 20, Channel = 0.3, Active = 0.12, Recovery = 0.34, Cooldown = 9, Interruptible = true, Range = 13,
		-- (04/11, replaces Sand Binding: his Sand Coffin already binds)
		Hint = "A giant arm of sand grows from his shoulder and sweeps the whole field in front of him", AI = { Min = 3, Max = 12 } },
	{ Id = "SandSpikes", Name = "Sand Spikes", Signs = {2,3}, Family = "Projectile", Kind = "sandspike", Ground = true, Cost = 16, Channel = 0.24, Active = 0.06, Recovery = 0.28, Cooldown = 6, Interruptible = true,
		Range = 32, Speed = 70, Damage = 5, Count = 3, Spread = 0.4, Radius = 1.2, Lift = 30, Hint = "Three lines of spikes burst from the floor and throw him up", AI = { Min = 5, Max = 28 } },
	{ Id = "Quicksand", Name = "Quicksand", Signs = {3,4}, Family = "Zone", Kind = "quicksand", ZoneKind = "Quicksand", At = "Target", Cost = 20, Channel = 0.4, Active = 0.15, Recovery = 0.3, Cooldown = 12, Interruptible = true,
		Range = 30, Radius = 7, Time = 4, Damage = 1, Slow = { Scale = .55 }, Hint = "The floor under him turns to sand: 4 s, he wades through it", AI = { Min = 4, Max = 28 } },
	{ Id = "ThirdEye", Name = "Third Eye", Signs = {4,1}, Family = "Buff", Kind = "thirdeye", Reveal = true, ParryScale = 1.4, Cost = 14, Channel = 0.2, Active = 0.04, Recovery = 0.12, Cooldown = 12, Interruptible = true,
		Time = 6, Range = 20, Hint = "An eye of sand floats above: 6 s, clones and illusions shown, a wider parry" },
	{ Id = "SandClone", Name = "Sand Clone", Signs = {3,1}, Family = "Counter", Kind = "sandarmor", Time = 0.9, Swap = true, Damage = 4, Bind = 0.6,
		Cost = 14, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 8, Interruptible = false, Range = 6, Radius = 6, Hint = "The blow meets a clone of sand: it crumbles round his legs, Gaara is behind", AI = { Min = 0, Max = 6 } },
}
SealJutsu.Leaf={ -- Rock Lee, 13: no ninjutsu; the seals are his gates and his stances
	{ Id = "Nunchaku", Name = "Sōshūga: Nunchaku", Signs = {1,2}, Family = "Strike", Move = "Nunchaku", Damage = 11, Knock = 34, Cost = 12, Channel = 0.1, Active = 0.05, Recovery = 0.1, Cooldown = 6, Interruptible = true, Range = 8,
		-- (04/11, replaces Konoha Shōfū: it was his launcher)
		Hint = "The nunchaku comes out of his belt: a whirling blow with the weapon's reach", AI = { Min = 2, Max = 8 } },
	{ Id = "DancingLeafShadow", Name = "Shadow of the Dancing Leaf", Signs = {2,3}, AIAs = "Teleport", FollowsLaunch = true, Cost = 14, Channel = 0.04, Active = 0.04, Recovery = 0.1, Cooldown = 6, Interruptible = true, Range = 24,
		-- (04/11, replaces Konoha Senpū: it was his side route)
		Hint = "He follows a launched body into the air like its shadow, right behind it: then heavy, his lotus", AI = { Min = 0, Max = 24 } },
	{ Id = "DrunkenFist", Name = "Drunken Fist", Signs = {3,4}, Family = "Buff", Kind = "leaf", Cost = 16, Channel = 0.24, Active = 0.05, Recovery = 0.2, Cooldown = 14, Interruptible = true,
		Time = 6, Damage = 1.15, Speed = 1.08, Armor = .15, Range = 20, Hint = "6 s of the Drunken Fist: loose, harder, hard to stop" },
	{ Id = "GorikiSenpu", Name = "Konoha Gōriki Senpū", Signs = {4,1}, Family = "Strike", Move = "GorikiSenpu", Damage = 12, Lift = 44, Knock = 10, Cost = 16, Channel = 0.12, Active = 0.05, Recovery = 0.12, Cooldown = 8, Interruptible = true, Range = 7,
		-- (04/11, replaces the Gate of Opening: Remove the Weights and his Eight Gates already do it)
		Hint = "Three spinning kicks, rising: the last one throws him into the air • E to chase", AI = { Min = 1, Max = 7 } },
}
SealJutsu.GentleFist={ -- Neji, 13: the Gentle Fist's points, the air palm, the trigrams
	{ Id = "Hasangeki", Name = "Hakke Hasangeki", Signs = {1,2}, Family = "Projectile", Kind = "hasangeki", Cost = 22, Channel = 0.3, Active = 0.08, Recovery = 0.32, Cooldown = 9, Interruptible = true,
		Range = 18, Speed = 96, Damage = 12, Radius = 3.4, Knock = 56, Lift = 10, GuardBreak = true, Launch = "Palm",
		-- (04/11, replaces the Tenketsu Strike: his blows already close the points)
		Hint = "The mountain crusher: a huge wave of air thrown from both palms, it breaks a guard", AI = { Min = 3, Max = 16 } },
	{ Id = "LegPoints", Name = "Jūken: Leg Points", Signs = {2,3}, Family = "Strike", Move = "LowPalm", Damage = 6, Slow = { Scale = .65, Time = 3 }, Cost = 12, Channel = 0.06, Active = 0.04, Recovery = 0.12, Cooldown = 7, Interruptible = true, Range = 6,
		-- (04/11, replaces the Air Palm Volley: it was his Vacuum Palm again)
		Hint = "Two fingers driven into the points of the legs: for 3 s he moves at two thirds of his speed", AI = { Min = 0, Max = 6 } },
	{ Id = "GentleCounter", Name = "Gentle Step: Counter Palm", Signs = {3,4}, Family = "Counter", Kind = "byakugan", Time = 0.7, Move = "PalmThrust", Damage = 9, Drain = 10,
		Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 6, Interruptible = false, Range = 6, Radius = 6, Hint = "The Byakugan sees it coming: the blow is answered by a palm that drains", AI = { Min = 0, Max = 6 } },
	{ Id = "TrigramField", Name = "Eight Trigrams Field", Signs = {4,1}, Family = "Zone", Kind = "trigram", ZoneKind = "Trigram", At = "Self", Cost = 18, Channel = 0.3, Active = 0.12, Recovery = 0.26, Cooldown = 12, Interruptible = true,
		Range = 8, Radius = 7, Time = 4, Damage = 1, Drain = 3, Slow = { Scale = .85 }, Hint = "The trigrams drawn round him: 4 s, a body inside loses its chakra", AI = { Min = 0, Max = 7 } },
}
SealJutsu.Mirage={ -- Itachi, 13: crows, clones that explode, blades from blind angles
	{ Id = "CrowGenjutsu", Name = "Genjutsu: Crows", Signs = {1,2}, Family = "Burst", Kind = "crows", Cost = 18, Channel = 0.14, Active = 0.1, Recovery = 0.3, Cooldown = 10, Interruptible = true,
		Radius = 9, Arc = 0.3, Damage = 2, Seal = 1.5, Slow = { Scale = .72, Time = 2 }, Range = 9, Style = "look", Hint = "A flood of crows in his eyes: slowed, his jutsu sealed 1.5 s", AI = { Min = 0, Max = 8 } },
	{ Id = "ExplodingClone", Name = "Exploding Clone", Signs = {2,3}, Family = "Counter", Kind = "fireball", Time = 0.9, Swap = true, Damage = 12, Knock = 44, Lift = 16,
		Cost = 16, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 9, Interruptible = false, Range = 6, Radius = 6, Hint = "The blow meets a clone: it explodes, Itachi is behind", AI = { Min = 0, Max = 6 } },
	{ Id = "SharinganParalysis", Name = "Sharingan: Paralysis", Signs = {3,4}, AIAs = "Projectile", Cost = 16, Channel = 0.12, Active = 0.06, Recovery = 0.24, Cooldown = 9, Interruptible = true, Range = 16, Bind = 0.8,
		-- (04/11, replaces the Blind-Angle Shuriken: it was his Shadow Shuriken again)
		Hint = "If he is looking Itachi in the eyes, he cannot move for a moment", AI = { Min = 3, Max = 16 } },
	{ Id = "PhoenixSageFire", Name = "Katon: Phoenix Sage Fire", Signs = {4,1}, Family = "Projectile", Kind = "fireball", Element = "Fire", Cost = 20, Channel = 0.3, Active = 0.2, Recovery = 0.3, Cooldown = 7, Interruptible = true,
		Range = 50, Speed = 70, Damage = 3, Count = 5, Spread = 0.6, Radius = 1, Hint = "Five fireballs fanned out", AI = { Min = 8, Max = 40 } },
}
SealJutsu.Flashstep={ -- Minato, 13: Jiraiya's student, a sealing prodigy; the spiral he is inventing
	-- (04/11, user: « la plupart des attaques qu'il a en plus avec ses signes,
	-- c'est déjà les mêmes qu'il a »: Kunai Fan, the FTG Slash and the Body
	-- Flicker repeated his kunai and his teleports. Replaced by seals.)
	-- 1. The Rasengan: the spiral forms in his palm (Techniques.BurstStrike, the
	-- orb drawn by Effects): cast in the open it stays there, he runs and jumps
	-- with it and his next strike drives it (a thrust, a plunge from the air).
	{ Id = "BurstStrike", Name = "Rasengan", Signs = {1,2}, Cost = 26, Channel = 0.42, Active = 0.08, Recovery = 0.5, Cooldown = 9, Interruptible = true, Range = 8, Damage = 18,
		HoldState = { Time = 3, Drain = 5, Strike = "DashAttack", Air = "Slam", Variant = "Rasengan", AirVariant = "RasenganDrop", Damage = 18,
			Reaction = "Knockback", Impulse = Vector3.new(0, 22, 70), Stun = .62, Rasengan = true, World = { contact = "energy", element = "wind" }, Style = "burst", Name = "Rasengan", Reach = 8, Event = "Rasengan" },
		Hint = "The spiral forms in his palm: run with it, the next blow drives it • instant after a teleport • plunges from the air", AI = { Min = 2, Max = 9, Punish = true } },
	-- 2. A sealing formula written on the floor where he points: the first body
	-- that steps into it is held, its chakra points shut (Families.zoneTick Trap).
	{ Id = "SealingTrap", Name = "Fūinjutsu: Sealing Trap", Signs = {2,3}, Family = "Zone", Kind = "sealtrap", At = "Aim", Range = 20, Radius = 4.2, Time = 7, Damage = 0, ZoneKind = "Seal",
		Trap = { Bind = 1.1, Seal = 1.6 }, Cost = 16, Channel = 0.32, Active = 0.1, Recovery = 0.26, Cooldown = 10, Interruptible = true,
		Hint = "A sealing formula on the floor: the first body that steps in is held 1 s, its jutsu shut", AI = { Min = 5, Max = 20 } },
	-- 3. The space-time barrier (his fight with the masked man): what reaches him
	-- in the window is sent elsewhere - a blow's author lands far away, a thrown
	-- jutsu vanishes into the seal (Families.beforeHit / projectile Warp).
	{ Id = "SpaceTimeBarrier", Name = "Space-Time Barrier", Signs = {3,4}, Family = "Counter", Kind = "barrier", Time = 0.9, Warp = 16, Damage = 0,
		Cost = 18, Channel = 0.04, Active = 0.04, Recovery = 0.7, Cooldown = 9, Interruptible = false, Range = 6, Radius = 6,
		Hint = "For a moment the blow or the jutsu that reaches him is sent elsewhere: the attacker lands far away, a thrown jutsu vanishes", AI = { Min = 0, Max = 30 } },
	-- 4. Flying Thunder God, level two: one touch with the formula in the palm
	-- and the BODY is sent to his last marked kunai (up into the air without
	-- one) - then his own Flying Thunder God follows it there.
	{ Id = "FlyingThunderTwo", Name = "Flying Thunder God: Level Two", Signs = {4,1}, Family = "Strike", Move = "FlashTouch", Relocate = "Seal", Damage = 4,
		Cost = 20, Channel = 0.06, Active = 0.04, Recovery = 0.14, Cooldown = 8, Interruptible = true, Range = 5,
		Hint = "One touch: the body is sent to his last marked kunai (into the air without one) • 2 follows it there", AI = { Min = 0, Max = 5 } },
}
SealJutsu.Copycat={ -- Kakashi, 13: the Doton expert, his father's white tanto
	{ Id = "EarthWall", Name = "Doton: Earth Wall", Signs = {1,2}, Family = "Burst", Kind = "earthwall", Cost = 16, Channel = 0.2, Active = 0.2, Recovery = 0.3, Cooldown = 9, Interruptible = false,
		Radius = 7, Arc = 0.2, Clear = true, Damage = 4, Knock = 32, Lift = 8, Range = 7, Leave = { Radius = 4, Time = 3, Damage = 2, Kind = "Earth", Look = "earthwall" },
		Hint = "A wall of earth rises in front: blades stop in it, a close attacker is thrown off", AI = { Min = 0, Max = 7 } },
	{ Id = "EarthHeadhunter", Name = "Doton: Headhunter", Signs = {2,3}, Family = "Projectile", Kind = "earthhand", Ground = true, Cost = 18, Channel = 0.26, Active = 0.06, Recovery = 0.28, Cooldown = 8, Interruptible = true,
		Range = 28, Speed = 62, Damage = 5, Radius = 1.6, Bind = 1.0, Crush = 6, Hint = "His hand comes out of the floor under him and holds the legs", AI = { Min = 5, Max = 26 } },
	{ Id = "EarthDragon", Name = "Doton: Earth Dragon", Signs = {3,4}, Family = "Projectile", Kind = "earthdragon", Element = "Earth", Cost = 28, Channel = 0.5, Active = 0.25, Recovery = 0.34, Cooldown = 9, Interruptible = true, Feintable = true,
		Range = 50, Speed = 56, Damage = 13, Radius = 2.4, Knock = 44, Lift = 20, Hint = "A dragon of earth rises from the floor and rams him", AI = { Min = 8, Max = 40 } },
	{ Id = "WhiteChakraSabre", Name = "White Light Chakra Sabre", Signs = {4,1}, Family = "Buff", Kind = "lightning", Armed = true, Cost = 18, Channel = 0.25, Active = 0.05, Recovery = 0.2, Cooldown = 14, Interruptible = true,
		Time = 7, Damage = 1.18, Range = 20, Hint = "His father's tanto glows white: 7 s, every blow cuts harder" },
}

-- The fighter's seal jutsu whose sequence is `seq`, or nil.
function SealJutsu.find(list,seq)
	for _,spec in list or {} do
		local s=spec.Signs
		if #s==#seq then
			local same=true
			for i,v in s do if seq[i]~=v then same=false end end
			if same then return spec end
		end
	end
	return nil
end
-- Every technique of a fighter: the quick slots, then his seal jutsu.
function SealJutsu.all(def)
	local out={}
	for _,spec in (def and def.Techniques) or {} do table.insert(out,spec) end
	for _,spec in (def and def.SealJutsu) or {} do table.insert(out,spec) end
	return out
end
function SealJutsu.label(spec)
	local parts={}
	for _,v in spec.Signs do table.insert(parts,SealJutsu.Names[v]) end
	return table.concat(parts," · ")
end
return SealJutsu
