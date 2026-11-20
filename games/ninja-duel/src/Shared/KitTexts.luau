-- The CM's words for the eight prodigies (DEC-043, step 1, 20/11: « les
-- prodiges s'affichent avec les titres du CM »). One table, read by every
-- screen that names a prodigy, so a title is changed here once.
--   title  the name on screen, instead of the prodigy's own name
--          (the CM's list, vague 2 § 1; THE YELLOW FLASH chosen by François)
--   tag    the short word under the name (« AGE 13  •  TAIJUTSU ONLY »),
--          what the kit is about in three words
--   line   who he is, one funny line (his card)
--   with   what fighting like him means (his card)
--   why    « pourquoi ce kit » : one sentence, why a player picks him
--   only   what this kit does that the other seven do not
-- Words from the anime are kept for techniques (option B), never in a title,
-- a tag, a line or a sheet (tests/KitTexts.spec.luau).
-- The CM owns this file (texts). Fighters[id].Name stays the identity key
-- (dress, AI, looks): only what is shown changes.
local Fighters=require(script.Parent.Fighters)
local Text=require(script.Parent.Text)
local K={}

K.Order={"Legion","Lion","Leaf","GentleFist","Sand","Copycat","Mirage","Flashstep"}

K.Lines={
	Legion={title="THE LOUDMOUTH",tag="CLONES EVERYWHERE",
		line="Loud, reckless and not the sharpest kunai in the pouch. He never gives up, mostly because he never notices he is losing.",
		with="With him: shadow clones, ramen and shouting your attacks.",
		why="Fight ten against one: your shadow clones carry your strings, take the blows and shape your Rasengan.",
		only="Surrounds the rival with ten clones and can jump into a clone's body. The most health and chakra of the eight."},
	Lion={title="THE AVENGER",tag="LIGHTNING IN HAND",
		line="Brooding genius with a grudge against the whole world. Never smiles. Trains out of pure spite.",
		with="With him: fire, lightning and a lot of hate.",
		why="Never let go: kick the rival into the air, follow him up there and finish with a lightning strike that ends everything, or you.",
		only="Keeps his lightning charged in his hand while he runs, jumps and climbs, then dives on the rival from a wall."},
	Leaf={title="THE HARD WORKER",tag="TAIJUTSU ONLY",
		line="Cannot do a single jutsu, so he runs five hundred laps before breakfast. The most motivated boy in Konoha.",
		with="With him: pure taijutsu, ankle weights and the springtime of youth!",
		why="Let your hands do everything: no jutsu, no blade, just the fastest legs in the village and kicks that never stop.",
		only="The only kit with no jutsu at all. He opens his inner gates one by one, up to the fifth, and pays with his own health."},
	GentleFist={title="THE FATED GENIUS",tag="PALMS THAT DRAIN",
		line="Calm, proud and sure that destiny decided everything. Including that you lose.",
		with="With him: palm strikes and seeing every move coming.",
		why="Win by reading: he sees almost all around him, and every palm empties the rival's chakra, even through a guard.",
		only="Of the eight, his palms alone drain chakra through a guard and close chakra points. His spin stops everything at once."},
	Sand={title="THE UNTOUCHABLE",tag="THE SAND GUARDS HIM",
		line="Quiet kid with a gourd of sand that blocks everything. Has not slept in years. Does not want to talk about it.",
		with="With him: a sand shield, sand traps and a lot of silence.",
		why="Stay calm and let the sand work: it blocks for you, lashes from far away, binds and crushes.",
		only="Guarded without pressing a key: his sand stops blows by itself, except from behind. The slowest of the eight, he never needs to chase."},
	Copycat={title="THE COPYCAT",tag="COPIES YOUR JUTSU",
		line="Masked teen genius who copies your best move and does it better. Looks bored the whole time.",
		with="With him: copied techniques, lightning and ninja hounds.",
		why="Turn the rival's best move against him: the jutsu he casts in front of you becomes yours.",
		only="Copies the jutsu cast in front of him (one cast, 15 s) and sends hounds out of the ground to hold the rival."},
	Mirage={title="THE PERFECT BROTHER",tag="ILLUSIONS AND COUNTERS",
		line="Top of every class, polite to everyone, terrifying in every fight. Never raises his voice.",
		with="With him: illusions, crows and fire.",
		why="Make the rival miss: wider parries, perfect dodges that open counters, and an image of you that takes his swing.",
		only="Leaves an image of himself that catches swings, and freezes the rival in an illusion for 1.5 s when his awakening starts."},
	Flashstep={title="THE YELLOW FLASH",tag="KUNAI TELEPORTS",
		line="The nicest kid in the village. Also the fastest. Throws a kunai and is already there.",
		with="With him: marked kunai, teleports and blinking at the worst moment.",
		why="Be everywhere: throw a marked kunai and appear beside it before the rival can turn around.",
		only="Teleports to his kunai even while it flies, and chains teleports in his awakening. The least health of the eight."},
}

function K.of(id) return K.Lines[id] end

-- The name on screen: a prodigy's title, any other fighter's own name.
function K.name(id)
	local t=K.Lines[id]
	if t then return t.title end
	local def=Fighters[id]
	return Text.upper(def and def.Name or tostring(id or ""))
end

-- The long name (a stage, the controls sheet, a champion): a prodigy's title,
-- any other fighter's full name.
function K.fullName(id)
	local t=K.Lines[id]
	if t then return t.title end
	local def=Fighters[id]
	return Text.upper(def and (def.FullName or def.Name) or tostring(id or ""))
end

-- The short word about the kit: a prodigy's tag, any other fighter's title.
function K.tag(id)
	local t=K.Lines[id]
	if t then return t.tag end
	local def=Fighters[id]
	return Text.upper(def and def.Title or "")
end

-- The fighter id behind a Fighters Name (« Rock Lee » -> Leaf), for the
-- screens that only hold the name.
function K.idOf(name)
	for id,def in Fighters do
		if type(def)=="table" and def.Name==name then return id end
	end
	return nil
end

-- One letter for a small round badge: the first letter of the title's word
-- (THE LOUDMOUTH -> L), so the eight badges never all say « T ».
function K.initial(id)
	local word=string.match(K.name(id),"^THE%s+(%S)") or string.sub(K.name(id),1,1)
	return word
end

-- The line under the name: « AGE 13  •  TAIJUTSU ONLY ».
function K.sub(id)
	local def=Fighters[id]
	if not def then return "" end
	return string.format("AGE %d  •  %s",def.Age or 13,K.tag(id))
end

return K
