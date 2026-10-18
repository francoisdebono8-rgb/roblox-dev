-- The playable roster, in menu order: the select screen, the AI soaks and the
-- roster-wide Tier A suite (tests/Roster.spec.luau) all read this list. A
-- fighter is listed only once it is selectable and plays (Tier A in
-- docs/characters/ROSTER_20.md); Fighters may hold a definition before that.
-- DEC-026 target roster (17 kept + 3 newcomers). Hinata (Lavender), Temari
-- (Gale) and Kabuto (Medic) leave the menu; their code and suites stay.
return {
	-- CORE4 (the first prototypes).
	"Flashstep","Mirage","GentleFist","Lion",
	-- The stress-test wave (DEC-015).
	"Sand","Leaf",
	-- Roster 20 breadth pass.
	"Legion","Copycat",
	"Mirror","Mist","Bone",
	"Flicker","Serpent",
	"Clay","Puppet","Rinnegan","Ink",
	-- DEC-026 newcomers: Madara, Hashirama, Hiruzen as children (Shared/Wave4).
	"Rival","Sapling","Professor",
}
