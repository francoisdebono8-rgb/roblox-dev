# ROSTER 20 — BREADTH-FIRST PLAYABLE PASS

This directive does **not replace** the current V1 convergence mission. It changes the roster strategy inside it.

## Product decision

Stop treating every new fighter as a mini-project that must be nearly perfect before the next one exists.

For the first big V1 milestone, target **20 playable fighters total**.

The goal is to get the entire roster into the game at a credible playable baseline first, then polish the whole roster in waves.

Use the existing six as the starting point:
- Minato
- Itachi
- Neji
- Sasuke
- Gaara
- Rock Lee

Choose the remaining fourteen yourself from the most obvious Naruto characters, prioritizing:
- iconicity / player demand;
- mechanical diversity;
- distinct silhouette / fantasy;
- reuse of existing combat families where sensible;
- coverage of systems that stress the engine.

Do not overthink canon edge cases or spend hours debating the exact twenty. Pick the obvious strong candidates and move.

A likely candidate pool includes Naruto, Kakashi, Haku, Temari, Shikamaru, Kisame, Orochimaru, Hinata, Kiba, Shino, Choji, Kimimaro, Zabuza, Kabuto, Sakura and other equally obvious choices. You may substitute candidates if another fighter provides better gameplay diversity.

## Key production strategy

Use a **breadth-first three-tier model**.

### Tier A — Playable baseline for all 20

Get all twenty into the actual game before trying to make every one premium.

Each Tier-A fighter must have, at minimum:
- selectable character entry;
- working locomotion and stance;
- functional light string;
- heavy attack;
- at least one directional route;
- one usable air route or equivalent if the archetype intentionally avoids air combat;
- working tool;
- 2–3 functional jutsu;
- working defensive interaction with the shared systems;
- functional re-engage where appropriate;
- an awakening with at least one real gameplay change;
- basic AI usage so automated and native stress tests can exercise the kit;
- no obvious broken placeholders such as wrong projectile models, missing animations, errors or impossible inputs.

Tier A does **not** require:
- premium VFX;
- final balance;
- perfect animation polish;
- every signature move;
- final sound design;
- final cinematic presentation.

The objective is a believable playable skeleton, not a fake data-only fighter.

### Tier B — Identity pass for all 20

Once breadth is established, iterate across the roster by archetype/family instead of finishing one fighter in isolation.

Every fighter should gain:
- 2–3 identity-defining mechanics or route rules;
- signature jutsu / conversion behavior;
- recognizable combat rhythm;
- a distinct awakening rule;
- several fighter-specific poses / transitions;
- visible feedback that makes their mechanic understandable without reading documentation.

It is acceptable for fighters to share substantial infrastructure.

Reuse is a feature, not a failure.

Two characters may share 60–70% of a combat family if the remaining 30–40% meaningfully changes:
- decisions;
- route purpose;
- range;
- tempo;
- resource interaction;
- animation silhouette;
- signature techniques;
- awakening.

Do not duplicate systems merely to pretend every fighter is technologically unique.

### Tier C — Polish waves

After all twenty have meaningful Tier-B identity, polish in waves:
- animation quality;
- VFX;
- impact/reactions;
- audio;
- camera moments;
- balancing;
- matchup fixes;
- online feel.

Polish by reusable family where possible, then apply fighter-specific finishers.

## Why this strategy

The current project repeatedly discovers new engine requirements whenever a new fighter arrives.

A 20-fighter breadth pass exposes those requirements **early**:
- puppet / clone behavior;
- sand / remote-body control;
- pure taijutsu;
- counters / perception;
- traps;
- summons / companions;
- wide-area wind;
- ice / mirrors;
- weapon users;
- melee bruisers;
- transformation states;
- zoning;
- aerial pressure;
- setup characters;
- status / chakra control.

This should force the combat core to become genuinely reusable instead of accumulating per-character special cases.

## Architecture requirement

Do not let the central combat engine become a giant list of character names.

Prefer a neutral combat core with reusable hooks / traits / modules for things such as:
- beforeHit;
- onHit;
- afterHit;
- onGuard;
- onParry;
- onDodge;
- onProjectile;
- onTool;
- onRoute;
- onAwaken;
- onRecovery;
- onMovement;
- defensive trait;
- resource trait;
- projectile family;
- movement family;
- presentation family.

If new fighters repeatedly require editing the same giant central conditional tree, stop and generalize the system before continuing.

## Roster selection principle

The chosen twenty should not be twenty versions of the same fighter.

Aim for a spread such as:
- rushdown;
- all-rounder;
- zoner;
- counter/read;
- trap/setup;
- pure taijutsu;
- projectile specialist;
- weapon specialist;
- defensive controller;
- bruiser;
- mobility specialist;
- chakra-control fighter;
- transformation fighter;
- summon/companion or proxy fighter where viable.

But do not create artificial archetypes just for taxonomy. Character fantasy comes first.

## Critical rule: PLAYABLE means PLAYABLE

Do not count a fighter because:
- a sheet exists;
- data exists;
- a menu entry exists;
- tests instantiate the character;
- a jutsu name exists.

A Tier-A fighter must be selectable in the generated build and survive a real Studio fight without obvious missing core behavior.

## Validation loop

For every new fighter:
1. create the minimum kit through the production framework;
2. build the place;
3. select the fighter in Studio;
4. run basic neutral, combo, tool, jutsu, awakening and re-engage checks;
5. run at least one AI matchup;
6. fix blocking bugs;
7. move to the next fighter.

Do not spend an entire session polishing one new fighter while twelve others do not exist.

## Batch production

Work in batches when it is faster.

Example:
- add 3–4 fighters sharing a movement/combat family;
- validate all of them;
- fix the shared framework once;
- propagate the fix;
- then move to another family.

This is preferred over twenty serial bespoke implementations.

## Expected first milestone

A generated `NinjaDuel.rbxlx` with **20 actually selectable and basically playable fighters**.

At that milestone it is acceptable that:
- six to eight are substantially more polished;
- some newer fighters have simpler VFX;
- balance is rough;
- some secondary routes are not final.

It is **not** acceptable that several of the twenty are only data stubs.

## After the 20-fighter breadth pass

Immediately switch back to convergence/polish across the whole game:
- combat feel;
- competitive neutral and defense economy;
- animation quality;
- readable awakenings;
- VFX quality;
- arena function/presentation;
- online two-player validation;
- balance and matchup testing;
- progression and V1 packaging.

Do not keep expanding the roster beyond twenty just because the framework makes it easy. Twenty is the breadth target for this first phase.

## Reporting

At the end of the roster breadth pass, provide a table with all twenty fighters and classify each as:
- Tier A complete;
- Tier B partial;
- Tier B complete;
- blocked.

For every fighter, list:
- archetype / combat fantasy;
- shared family reused;
- unique mechanics;
- tools;
- jutsu implemented;
- awakening behavior;
- native Studio validation performed;
- known issues.

The success condition is not "20 character documents".

The success condition is:
**20 fighters I can actually choose and play, giving us enough breadth to expose systemic problems before the final polish phase.**
