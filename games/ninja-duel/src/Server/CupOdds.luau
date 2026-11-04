-- The Prodigy Tournament's skipped matches (Server/Tournament): how often the
-- fighter of the row beats the one of the column, measured on the engine itself
-- (headless AI-vs-AI fights in the arena, tests/Balance.sim.luau's harness, 10
-- seeds per ordered pairing, both sides: p = (row's wins as first + column's
-- losses as first) / 20). Generated 04/11 for the eight of the beta; re-run
-- the simulation after a balance pass. Tournament:chance clamps to 10-90 %.
return {
	Legion={GentleFist=0.60,Lion=0.70,Sand=0.50,Leaf=0.40,Flashstep=0.65,Mirage=0.85,Copycat=0.40},
	GentleFist={Legion=0.40,Lion=0.60,Sand=0.20,Leaf=0.35,Flashstep=0.60,Mirage=0.55,Copycat=0.60},
	Lion={Legion=0.30,GentleFist=0.40,Sand=0.25,Leaf=0.55,Flashstep=0.25,Mirage=0.50,Copycat=0.25},
	Sand={Legion=0.50,GentleFist=0.80,Lion=0.75,Leaf=0.70,Flashstep=0.60,Mirage=0.70,Copycat=0.60},
	Leaf={Legion=0.60,GentleFist=0.65,Lion=0.45,Sand=0.30,Flashstep=0.65,Mirage=0.70,Copycat=0.40},
	Flashstep={Legion=0.35,GentleFist=0.40,Lion=0.75,Sand=0.40,Leaf=0.35,Mirage=0.55,Copycat=0.35},
	Mirage={Legion=0.15,GentleFist=0.45,Lion=0.50,Sand=0.30,Leaf=0.30,Flashstep=0.45,Copycat=0.25},
	Copycat={Legion=0.60,GentleFist=0.40,Lion=0.75,Sand=0.40,Leaf=0.60,Flashstep=0.65,Mirage=0.75},
}
