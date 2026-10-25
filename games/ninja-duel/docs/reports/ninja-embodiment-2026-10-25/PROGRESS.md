# Ninja Embodiment — progress by lot

Running log of the mission ([DEC-027](../../active/DECISIONS.md#dec-027--ninja-embodiment--le-joueur-devient-le-ninja), [audit](AUDIT.md)). Each lot: what changed in the shared systems, what was measured, what is still missing. Verdicts stay honest: a lot that moved a number without changing what the game *is* says so.

## Lot 1 — `db6caf7` contextual strike resolver, defender recovery, air-string cap

- `Shared/ActionContext`: the strike input reads the body's situation (drop, back, run, flank, close, reach) and each fighter declares in data what its body does there (`MoveGraphs[id].context`, defaults from its own graph). No fighter id in the resolver.
- Defender agency (`Config.Agency`): past a share of an ordinary blow the guard comes back up or the body steps out; in an air string it rights itself once per air time; a knocked-down body may tech on landing. The substitution remains the early, expensive escape. An air string drops the body after 4 blows.
- Studio, AI vs AI, 45 s per pairing: Lee locked 49 % → 16 % against Gaara, longest lock 3.8 → 2.7 s. Universal strikes still 66–88 % of all strikes: the resolver fires rarely in AI fights. **Not a breakthrough yet.**

## Lot 2 — reactive world (EMB-004)

`Server/WorldReaction` is the one rule for every contact with the arena. An impact carries a surface, an energy, a contact kind (blunt, slash, pierce, blast, energy) and an optional element; the surface's material class answers.

| Material (Enum.Material → class) | blunt | slash | pierce | blast | energy | breaks? |
|---|---|---|---|---|---|---|
| earth (Grass, Ground, Sand…) | crater | furrow | puncture + embed fact | crater | trench | never (structural) |
| wood (Wood, WoodPlanks) | crack (wear .8) | cut (1) | puncture + embed fact (.25) | splinter (1.1) | hole (1.4) | if `WorldBreakable`: trunk falls |
| stone (Slate, Concrete, Brick…) | crack (.7) | scratch (.35) | chip (.08) | crater (.8) | gouge (1) | if `WorldBreakable`: shatters to a mound |
| brittle (Ice, Glass) | crack (1.4–1.6) | crack | crack | crack | crack | if breakable |
| metal | dent | scratch | — | dent | gouge | never |

Elements add their own mark and wear: fire → scorch (wood ×1.6), lightning → char, wind → cut, water → wet.

Who feeds it (no per-technique handler; a technique only declares `spec.world` / `p.world` when the default is wrong):

- a body thrown into a surface (`Brawler` flight: speed × 1.4); a breakable surface that gives way lets the body carry on through (`SmashThrough`), otherwise the wall splat happens as before and marks the surface;
- a spike or a slam landing on the floor (crater);
- a projectile reaching a surface (kind → contact/element: blades pierce, fireball/phoenix blast + fire, wind/gale/kamatari slash + wind, sand/palm blunt);
- a swing that met no body but met the world in front of it (strike kind → contact; heavy/spike/launch ×1.6);
- an elemental zone, once, under its centre (generic family zones only by their declared Element).

States: Intact → Cracked (≤ 50 % integrity, darker) → Broken (breakable only). A broken trunk leaves a 2.2-stud stump, the rest falls over the cut with its crown in the direction of the blow; a broken boulder becomes a 38 % mound with its cap and chip as rubble. Broken parts are no longer splat surfaces and no longer hide a standing body or stop a blade at chest height. The marks of a part that breaks go with it.

Budgets (server parts, replicated): 48 marks (oldest out; a mark near one of its kind deepens it instead of adding a part), 24 rubble pieces, 16 embed facts. The arena is rebuilt per match; marks survive round resets (the fight's memory for the whole match). `NinjaDuelDev` op `world` returns the summary.

Headless (Embodiment.spec, 5 new cases, two mutation-checked: smash-through and merging): material → mark, merging, the budget, trunk crack → fall and structural wall never breaks, a body through a worn tree vs a splat on a sound one, projectile/strike/declared contacts.

Studio (ND-Debug place):

- Sasuke's Light string into a field tree, three times: splat + mark, Cracked, then the trunk broke and Gaara carried on through it (`smash 1`); the trunk fell with its crown, a 2.2 stump stayed.
- Great Fireball at Gaara behind the nearest boulder: integrity 1 → .74 → .47 (Cracked) → .21 → Broken; the boulder became a low mound with rubble and a scorch on the ground; the next fireball passes over it.
- AI vs AI, 40 s each: Sasuke–Gaara 31 impacts (15 craters, 13 scorches, 4 punctures, 2 cracks); Minato–Itachi 16; Rival–Bone 4 punctures; Gale–Leaf 0. The AI fights in the middle of the field: it never brings a fight to a tree or a boulder. **The world reacts; the AI does not yet use it** (perception / AI environment use is still open).

Still missing for EMB-004: world-aware AI, chakra actions reading the world facts (embeds, walls, stumps), materials beyond this arena, a 3-minute Studio fight that visibly tells its story.
