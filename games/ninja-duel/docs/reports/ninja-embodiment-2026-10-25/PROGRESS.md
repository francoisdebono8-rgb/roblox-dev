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

## Lot 3 — perception: the space around a fight

`Server/Perception` is one shared read of the space, cached per actor (0.12 s, invalidated when either body moves a stud): the surface beyond the target on the attacker's line (`behindTarget`), the surface at the attacker's own back (`behindSelf`), the nearest surface around the target (geometry over the arena's surface list, no rays), and whether the world stands between them. It owns the surface rule (NinjaWall or WorldBreakable, not Broken); `Brawler.splatSurface` delegates to it.

- Resolver: a new situation, `wall` — his back to a surface within 12 studs on this body's line. Default: the fighter's own string finisher (its Light3 throws the body), or `graph.wallStrike`. It is also read **inside a string**: with a surface behind him, the next press ends the string into it instead of playing the next light (the stick routes still come first).
- AI: a body on a wall is finished there (pins, a heavy to bounce); with its own back to a surface the bot slips out sideways; with a surface within 40 studs of the opponent it circles to put him between itself and it (1.6 s tries, 2.5 s apart); spacing at range it drifts to the scenery.
- Arena: four training posts (thin wood) and two low stones nearer the middle, plus the existing trees and boulders: the middle of the field had nothing in it.
- Headless (Embodiment.spec +2 cases, both mutation-checked): the opener with his back to the wall is the drive and he splats; inside a string the wall ends it, in the open the next light follows; a stump is no surface; the bot circles to the far side of a wall; a cornered bot slips out.

Studio, AI vs AI, 45 s per pairing (after this lot):

| Pairing | universal | locked | context events | space events | world |
|---|---|---|---|---|---|
| Sasuke–Minato | 77 % / 81 % | 28 % / 11 % | wall 1, reach 1 | herd 3, terrain 21, splat 1 | 24 impacts |
| Kimimaro–Gaara | 71 % / 78 % | 26 % / 10 % | wall 1, reach 4, run 2 | herd 13, terrain 12 | 7 impacts |
| Lee–Itachi | 63 % / 72 % | 30 % / 14 % | close, flank, wall, drop 1 each | herd 10, terrain 19, corner 1, splat 1 | 14 impacts, 1 cracked |

Verdict: the bodies now read the space and move through it (terrain and herd events every few seconds; the first wall drives and splats in free fights), but the strike vocabulary is still mostly shared: the resolver's run/reach default is the shared DashAttack, and the string still runs on lights. **Not a breakthrough yet.** Next: the fighters declare what their own body does in each situation (vertical slices Sasuke, Minato, Kimimaro), so the same situation reads differently per ninja.
