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
	{ Id = "ShadowShuriken", Name = "Shadow Shuriken", Signs = {1,2}, Family = "Projectile", Kind = "windmill", Cost = 10, Channel = 0.16, Active = 0.04, Recovery = 0.22, Cooldown = 4, Interruptible = true,
		Range = 52, Speed = 98, Damage = 3, Count = 2, Volley = 0.14, Radius = .7, Hint = "Two shuriken, the second hidden in the shadow of the first", AI = { Min = 8, Max = 40 } },
	{ Id = "WindmillBlades", Name = "Windmill Triple Blades", Signs = {2,3}, Family = "Projectile", Kind = "fuma", Cost = 14, Channel = 0.24, Active = 0.06, Recovery = 0.26, Cooldown = 6, Interruptible = true,
		Range = 46, Speed = 82, Damage = 4, Count = 3, Spread = 0.5, Radius = 1, Slow = { Scale = .7, Time = 1.2 }, Hint = "Three blades on wires: the body they catch is slowed", AI = { Min = 6, Max = 30 } },
	{ Id = "SharinganCounter", Name = "Sharingan: Counter", Signs = {3,4}, Family = "Counter", Kind = "swordread", Time = 0.7, Move = "LionKick", Damage = 10,
		Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 7, Interruptible = false, Range = 6, Radius = 6, Hint = "The Sharingan sees the blow coming: it is answered by a kick", AI = { Min = 0, Max = 6 } },
	{ Id = "DragonFlame", Name = "Katon: Dragon Flame", Signs = {4,1}, Family = "Projectile", Kind = "firedragon", Element = "Fire", Cost = 24, Channel = 0.38, Active = 0.2, Recovery = 0.32, Cooldown = 9, Interruptible = true, Feintable = true,
		Range = 54, Speed = 58, Damage = 12, Radius = 2.2, Knock = 40, Lift = 12, Hint = "A dragon of fire runs at him and throws him back", AI = { Min = 8, Max = 40 } },
}
SealJutsu.Legion={ -- Naruto, 12: transformation, the hidden Fuma, the fox's chakra
	{ Id = "Transformation", Name = "Transformation", Signs = {1,2}, Family = "Counter", Kind = "flicker", Time = 0.9, Swap = true, Damage = 6, Knock = 24,
		Cost = 12, Channel = 0.04, Active = 0.04, Recovery = 0.2, Cooldown = 7, Interruptible = false, Range = 6, Radius = 6, Hint = "He turns into a log: the blow that meets him finds wood, and he is behind", AI = { Min = 0, Max = 6 } },
	{ Id = "HiddenFuma", Name = "Hidden Fuma Shuriken", Signs = {2,3}, Family = "Projectile", Kind = "fuma", Cost = 14, Channel = 0.26, Active = 0.06, Recovery = 0.28, Cooldown = 6, Interruptible = true,
		Range = 56, Speed = 76, Damage = 6, Count = 2, Volley = 0.22, Radius = 1.4, Knock = 22, Hint = "A big shuriken, and a second one hidden in its shadow", AI = { Min = 8, Max = 40 } },
	{ Id = "FoxChakra", Name = "Nine-Tails Chakra", Signs = {3,4}, Family = "Buff", Kind = "foxchakra", Cost = 30, Channel = 0.3, Active = 0.05, Recovery = 0.2, Cooldown = 18, Interruptible = true,
		Time = 6, Speed = 1.12, Damage = 1.15, Heavy = true, Range = 20, Hint = "The red chakra leaks: 6 s faster, harder, and a light blow does not stop him" },
	{ Id = "UzumakiCharge", Name = "Uzumaki Charge", Signs = {4,1}, Family = "Strike", Move = "Tackle", Cost = 14, Channel = 0.12, Active = 0.05, Recovery = 0.1, Cooldown = 5, Interruptible = true,
		Range = 14, Damage = 10, Knock = 34, Hint = "Head first across the gap, the way he fought Neji", AI = { Min = 4, Max = 13 } },
}
SealJutsu.Sand={ -- Gaara, 12: the sand does anything he wants
	{ Id = "SandBind", Name = "Sand Binding", Signs = {1,2}, Family = "Projectile", Kind = "sandgrab", Ground = true, Cost = 18, Channel = 0.3, Active = 0.08, Recovery = 0.3, Cooldown = 8, Interruptible = true,
		Range = 34, Speed = 54, Damage = 3, Radius = 1.6, Bind = 1.0, Crush = 6, Hint = "The sand runs along the floor and closes on his legs", AI = { Min = 6, Max = 30 } },
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
	{ Id = "LeafRisingWind", Name = "Konoha Shōfū", Signs = {1,2}, Family = "Strike", Move = "LeafRising", Cost = 12, Channel = 0.08, Active = 0.05, Recovery = 0.1, Cooldown = 4, Interruptible = true,
		Range = 12, Damage = 9, Hint = "The Leaf Rising Wind: a kick from under the chin throws him up", AI = { Min = 3, Max = 11 } },
	{ Id = "KonohaSenpu", Name = "Konoha Senpū", Signs = {2,3}, Family = "Strike", Move = "LeafWhirlwind", Cost = 14, Channel = 0.1, Active = 0.05, Recovery = 0.12, Cooldown = 5, Interruptible = true,
		Range = 10, Damage = 12, Knock = 40, Hint = "The Leaf Whirlwind: a spinning kick that throws him away", AI = { Min = 2, Max = 9 } },
	{ Id = "DrunkenFist", Name = "Drunken Fist", Signs = {3,4}, Family = "Buff", Kind = "leaf", Cost = 16, Channel = 0.24, Active = 0.05, Recovery = 0.2, Cooldown = 14, Interruptible = true,
		Time = 6, Damage = 1.15, Speed = 1.08, Armor = .15, Range = 20, Hint = "6 s of the Drunken Fist: loose, harder, hard to stop" },
	{ Id = "GateOfOpening", Name = "Gate of Opening", Signs = {4,1}, Family = "Buff", Kind = "weights", Cost = 26, Channel = 0.3, Active = 0.05, Recovery = 0.2, Cooldown = 20, Interruptible = true,
		Time = 7, Speed = 1.2, Damage = 1.2, Heavy = true, Range = 20, Hint = "The first gate opens: 7 s faster and harder, a light blow does not stop him" },
}
SealJutsu.GentleFist={ -- Neji, 13: the Gentle Fist's points, the air palm, the trigrams
	{ Id = "TenketsuStrike", Name = "Jūken: Tenketsu Strike", Signs = {1,2}, Family = "Strike", Move = "PalmThrust", Cost = 16, Channel = 0.12, Active = 0.05, Recovery = 0.12, Cooldown = 8, Interruptible = true,
		Range = 9, Damage = 6, Seal = 1.6, Drain = 14, Hint = "One palm into a chakra point: his jutsu are sealed 1.6 s", AI = { Min = 2, Max = 8 } },
	{ Id = "AirPalmVolley", Name = "Air Palm Volley", Signs = {2,3}, Family = "Projectile", Kind = "airpalm", Cost = 16, Channel = 0.2, Active = 0.06, Recovery = 0.26, Cooldown = 6, Interruptible = true,
		Range = 34, Speed = 100, Damage = 3, Count = 3, Volley = 0.14, Radius = 1.2, Knock = 18, Hint = "Three air palms in a row: each one pushes", AI = { Min = 6, Max = 30 } },
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
	{ Id = "BlindShuriken", Name = "Blind-Angle Shuriken", Signs = {3,4}, Family = "Projectile", Kind = "windmill", Cost = 12, Channel = 0.2, Active = 0.05, Recovery = 0.24, Cooldown = 5, Interruptible = true,
		Range = 50, Speed = 92, Damage = 2.5, Count = 4, Spread = 0.9, Radius = .8, Hint = "Four blades on four lines: the dodge runs into one", AI = { Min = 8, Max = 40 } },
	{ Id = "PhoenixSageFire", Name = "Katon: Phoenix Sage Fire", Signs = {4,1}, Family = "Projectile", Kind = "fireball", Element = "Fire", Cost = 20, Channel = 0.3, Active = 0.2, Recovery = 0.3, Cooldown = 7, Interruptible = true,
		Range = 50, Speed = 70, Damage = 3, Count = 5, Spread = 0.6, Radius = 1, Hint = "Five fireballs fanned out", AI = { Min = 8, Max = 40 } },
}
SealJutsu.Flashstep={ -- Minato, 13: kunai, the flash, the spiral he is working on
	{ Id = "KunaiFan", Name = "Kunai Fan", Signs = {1,2}, Family = "Projectile", Kind = "markedkunai", Cost = 10, Channel = 0.12, Active = 0.04, Recovery = 0.2, Cooldown = 5, Interruptible = true,
		Range = 60, Speed = 104, Damage = 3, Count = 3, Spread = 0.7, Radius = .7, Hint = "Three kunai fanned out: one of them reaches the dodge", AI = { Min = 8, Max = 44 } },
	{ Id = "FlashSlash", Name = "Flying Thunder God Slash", Signs = {2,3}, Family = "Teleport", Kind = "flash", To = "Behind", Distance = 3, Move = "BackStrike", Damage = 12, Invuln = 0.14,
		Cost = 18, Channel = 0.06, Active = 0.02, Recovery = 0.16, Cooldown = 7, Interruptible = true, Range = 28, Hint = "A flash behind him and one cut", AI = { Min = 4, Max = 26 } },
	{ Id = "FlashFlicker", Name = "Body Flicker", Signs = {3,4}, Family = "Teleport", Kind = "flash", To = "Side", Distance = 6, Invuln = 0.2,
		Cost = 10, Channel = 0.03, Active = 0.02, Recovery = 0.1, Cooldown = 4, Interruptible = true, Range = 30, Hint = "Gone in a flash, beside him: no blow, just the angle" },
	{ Id = "SpiralPalm", Name = "Rasengan", Signs = {4,1}, Family = "Strike", Move = "PalmThrust", Cost = 26, Channel = 0.4, Active = 0.05, Recovery = 0.14, Cooldown = 9, Interruptible = true,
		Range = 10, Damage = 16, Knock = 58, Lift = 14, Hint = "The spiral he invented, into the body: thrown far", AI = { Min = 2, Max = 9, Punish = true } },
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
