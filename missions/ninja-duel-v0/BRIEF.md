# Mission — Ninja Duel V0: playable 1v1 vertical slice

## Objective
Build a complete, immediately playable Roblox Studio vertical slice of a tactical anime-inspired ninja arena fighter. At the end of this mission, one human player must be able to launch the game, choose one of **two original prototype fighters**, choose the opponent, and play a full **1v1 match against an AI** from start to finish.

This is a gameplay prototype, not a menu mockup. Prioritize combat feel, readability, responsiveness, interruption/counterplay, and a working AI over content volume.

Do the implementation end-to-end without stopping for review between subtasks. Make reasonable technical decisions yourself. Keep the architecture extensible so more fighters can later be added data-first.

## IP / art direction constraint
Naruto is a design reference for the fantasy of tactical young-ninja combat, but this prototype must use **original fighter names, visual identities, technique names, VFX, icons, lore and assets**. Do not copy Naruto characters, logos, costumes, named techniques, animations, audio or ripped assets. Placeholder geometry/VFX made in Studio is acceptable and preferable to copyrighted assets.

## End-state / acceptance test
A tester can:
1. Open/run the project in Roblox Studio.
2. Reach a simple fighter-selection screen.
3. Select either of the two fighters for the human player.
4. Select either fighter as the AI opponent.
5. Start the duel in one polished, readable arena.
6. Move, jump, basic attack, guard, dodge, use chakra, perform fighter techniques, interrupt techniques, be interrupted, and use the fighter's signature mechanic.
7. Fight an AI that attacks, defends, dodges, manages range/chakra, attempts techniques and can interrupt the player.
8. Win or lose through health reaching zero, see the result, and rematch or return to selection without restarting Studio.
9. Play several matches without obvious state leaks, duplicate connections, stuck characters or broken UI.

## Combat philosophy
The game is not a button-spam battleground. Techniques are **actions performed during the fight** and create commitment. Strong actions require setup, timing, positioning or a condition. Preparations can be interrupted. Players should create openings, read reactions, bait defensive actions and punish mistakes.

Power does not need to be perfectly symmetrical. Fighter identity matters. Balance comes from counterplay, commitment, resources, cooldowns, telegraphs and execution rather than making every move equivalent.

## Core combat systems
Implement a server-authoritative combat state machine with clear states such as Neutral, Attacking, Startup, Active, Recovery, Guarding, Dodging, Stunned, TechniqueChannel, TechniqueRecovery and Defeated. Exact structure is your choice, but invalid overlaps must be prevented.

Required shared mechanics:
- Health.
- Chakra resource with visible meter and regeneration rules.
- Light/basic melee chain with a short combo and final-hit consequence.
- Guard with meaningful limitations; no permanent invulnerability.
- Directional or lateral dodge with a short invulnerability/avoidance window and cooldown/stamina-style limitation if needed.
- Hit stun kept short enough that the victim still plays the game.
- Technique startup/channel and recovery windows.
- Interrupt system: qualifying hits during interruptible startup/channel cancel the technique and impose a small consequence.
- Telegraphs readable enough for counterplay.
- Cooldowns.
- Range/line-of-sight validation where relevant.
- Anti-spam rules.
- Server-side validation for damage, chakra, cooldowns, legal state and target/range. The client may request actions and handle presentation, never award itself damage.

Do not hardcode final balance as if numbers were finished. Put tunable values in central fighter/combat configuration modules.

## Prototype fighter A — `Flashstep`
Fantasy: exceptionally gifted young mobility fighter. Wins through positioning, marked anchors, fast entries and precise punishes.

Original visual placeholder identity: light-colored short hair, blue/cream training outfit, simple original triangular throwing blade. Do not recreate an existing anime costume.

Kit target:
- Basic melee chain: fast, modest damage.
- `Marked Blade`: throw a projectile. On valid surface impact it creates a temporary visible anchor. It should be possible for the opponent to see/understand the anchor.
- `Flashstep`: after an anchor exists, spend chakra to rapidly relocate to/near that anchor. Include arrival commitment/counterplay so repeatedly teleporting is not free offense.
- `Burst Strike`: quick close-range punish with a brief startup; useful after winning position, unsafe enough to punish on a miss.
- Signature gameplay loop: place anchor -> pressure from one angle -> force reaction -> reposition -> punish. The player should feel clever for using anchors, not simply press teleport for free damage.

If teleport-to-anchor proves technically awkward, implement a robust fast relocation first, but preserve server validation and clear arrival VFX.

## Prototype fighter B — `Mirage`
Fantasy: calm perception/illusion specialist. Wins by reading the opponent, creating uncertainty and punishing predictable actions.

Original visual placeholder identity: dark hair, charcoal/red training outfit, original eye/illusion VFX that does not reproduce copyrighted symbols.

Kit target:
- Basic melee chain: slightly more deliberate than Flashstep.
- `Read`: short timed stance/window. If an eligible telegraphed attack enters its read condition, reward Mirage with information or a brief counter opportunity. It must not auto-dodge everything.
- `Needle Fan`: small ranged projectile pattern used to force movement rather than deal huge damage.
- `Mirage Cast`: interruptible special technique. Requires a short channel and valid target conditions (range/line of sight/facing as appropriate). If completed, apply a **brief interactive illusion**, not a long hard stun. Good prototype effects include a decoy/false afterimage, temporarily misleading target indicator, short visual displacement, or another readable deception. Keep player agency.
- Signature gameplay loop: provoke predictable response -> read or channel at the right moment -> create confusion -> punish the resulting mistake.

The illusion must have clear start/end feedback and must clean itself up reliably.

## Special-technique execution model
This is the most important experimental system in the slice.

Every strong technique should define data/logic for:
- prerequisites;
- chakra cost;
- startup/channel duration;
- whether/when it is interruptible;
- active window;
- recovery;
- cooldown;
- cancellation behavior;
- telegraph/VFX;
- success/failure feedback.

During an interruptible channel, a qualifying hit cancels the technique before payoff. The player sees/hears a clear interruption cue. Failed techniques still consume an appropriate amount of commitment/resource so attempts matter.

Do not turn this into a complicated rhythm-game input sequence for V0. The execution challenge should initially come from finding the opening in live combat. Architect the technique system so hand-sign/input sequences could be added later without rewriting combat.

## AI opponent
Create an AI suitable for testing combat rather than a dummy with random attacks.

The AI should have a small decision loop/state machine or utility scoring system that can:
- approach/retreat based on preferred range;
- strafe/reposition;
- basic attack when appropriate;
- guard sometimes when under pressure;
- dodge telegraphed danger sometimes, with reaction delay so it is humanly beatable;
- use chakra techniques when resources/conditions permit;
- attempt signature mechanics (anchors for Flashstep, illusion/read windows for Mirage);
- interrupt a player's visible channel when close enough and able;
- avoid impossible omniscience: reaction time and imperfect choices are required.

Expose AI difficulty parameters (reaction delay, aggression, defensive tendency, technique usage) in configuration. For V0, one default difficulty is sufficient.

## Camera and controls
Use a third-person combat camera that keeps the duel readable. A soft-lock/target-lock system is acceptable and probably desirable. Do not fight Roblox's camera more than necessary.

Desktop controls are the required acceptance target. Choose sensible keys and show them in the HUD/help panel. Structure input actions through ContextActionService/UserInputService abstraction so mobile/gamepad support can be added later.

Suggested mapping (change if implementation quality benefits):
- LMB: basic attack
- F: guard
- Q: dodge
- 1/2/3: fighter techniques
- R or another clear key: signature/context action if needed
- Shift or lock key: target lock if required

## Arena
Build one compact original training arena using Roblox primitives/materials: enough obstacles/vertical detail to look intentional but not enough to break AI navigation or combat readability. Include boundaries that prevent leaving the duel.

The arena should make positioning matter while keeping both fighters easy to track.

## UI
Functional and polished enough to test, not final branding.

Selection screen:
- two fighter cards;
- short playstyle description;
- choose player fighter;
- choose AI fighter;
- Start Duel.

Combat HUD:
- player and opponent health;
- player chakra;
- technique cooldown/readiness indicators;
- fighter name;
- concise controls reminder;
- clear `INTERRUPTED`, `GUARD BREAK` or equivalent combat feedback where applicable.

End screen:
- victory/defeat;
- Rematch;
- Return to Selection.

## Architecture
Prefer clean Roblox Luau modules and a structure compatible with source control/Rojo if the repository already uses it. First inspect the existing repository and reuse its conventions rather than blindly creating a conflicting project layout.

Separate at minimum the concepts of:
- fighter definitions/configuration;
- combat/state management;
- techniques;
- hit/damage validation;
- AI;
- input/controller;
- camera;
- UI;
- match lifecycle.

Make adding Fighter C later mostly a matter of defining configuration + technique modules/assets, not editing a giant conditional script.

Use tags/attributes/components where useful. Avoid unnecessary frameworks/dependencies unless the repository already relies on them.

## Networking and reliability
Assume exploit-prone clients. The server owns match state, damage and authoritative resource/cooldown decisions. Rate-limit remote requests and validate action context.

Clean up temporary instances, effects, connections, anchors and AI tasks on death/rematch/return to selection. Match reset reliability is part of acceptance.

## Visual/audio scope
Use original procedural/primitive VFX: trails, particles, highlights, beams, tweens, camera shake used sparingly. Use placeholder sounds only if they are safe/original/available through legitimate Roblox assets; the prototype must not depend on copyrighted anime audio.

Animations: use original/basic animation work or robust placeholders appropriate for the repo workflow. Do not import ripped animations. Combat readability is more important than animation polish in this mission.

## Testing requirements
Before declaring the mission complete, test at least:
- Flashstep player vs Mirage AI;
- Mirage player vs Flashstep AI;
- mirror match if supported by selection;
- interrupting each interruptible technique;
- technique failure from insufficient chakra;
- cooldown rejection;
- dodge/guard interactions;
- death during/after a technique;
- rematch at least twice;
- return to selection then new match;
- no anchor/illusion/effect survives match reset;
- AI cannot act after defeat;
- remote requests cannot trivially bypass range/chakra/cooldowns.

If automated tests are feasible for pure modules/state transitions, add them. Also add a concise manual QA checklist.

## Deliverables
Commit a working implementation plus:
- `README` section or dedicated run instructions explaining how to open/sync/test the prototype;
- controls;
- architecture summary;
- fighter config location and how to add/tune a fighter;
- known limitations/TODOs;
- manual QA checklist.

## Definition of done
Do **not** stop at scaffolding, pseudocode, architecture documents, TODO stubs or disconnected modules. The mission is done only when the repository contains a playable vertical slice in which a human can select a fighter and complete a real 1v1 duel against a functioning AI, with the special-technique interruption system visibly working.

When finished, summarize exactly what was implemented, which files matter, how to run it, what you personally tested, and any remaining blockers. If Studio-only manual steps remain unavoidable, minimize them and document them precisely.