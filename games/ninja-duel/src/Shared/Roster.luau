-- The playable roster, in menu order: the select screen, the AI soaks and the
-- roster-wide Tier A suite (tests/Roster.spec.luau) all read this list. A
-- fighter is listed only once it is selectable and plays (Tier A in
-- docs/characters/ROSTER_20.md); Fighters may hold a definition before that.
return {
	-- CORE4 (the first prototypes).
	"Flashstep","Mirage","GentleFist","Lion",
	-- The stress-test wave (DEC-015).
	"Sand","Leaf",
	-- Roster 20 breadth pass (ROSTER_20.md).
	"Legion","Gale","Lavender","Copycat",
	-- Locked ten (DEC-022), batch 1.
	"Mirror","Mist","Bone",
	-- Batch 2.
	"Flicker","Serpent","Medic",
}
