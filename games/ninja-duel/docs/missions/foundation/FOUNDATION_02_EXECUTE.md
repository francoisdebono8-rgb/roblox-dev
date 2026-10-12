# FOUNDATION 02 — EXECUTE THE GAMEPLAY RUPTURE

This is an implementation mission. Do not produce another research phase or another large planning document.

Read only:
- `games/ninja-duel/docs/missions/foundation/GAMEPLAY_BIBLE_DRAFT.md`
- `games/ninja-duel/docs/missions/foundation/TECHNICAL_REFERENCE_MAP.md`
- `games/ninja-duel/docs/missions/foundation/FOUNDATION_ARCHITECTURE.md`
- `games/ninja-duel/docs/missions/foundation/HUMAN_ACCEPTANCE_MATRIX.md`
- `games/ninja-duel/docs/missions/foundation/FOUNDATION_02_PLAN.md`
- then only the game files directly needed to implement the chosen stack.

Do not reread the full mission history. Do not make a new general audit. Additional external research is allowed only for a concrete implementation blocker.

## Supreme acceptance rule

The next playable build must feel **radically different within the first 30 seconds on controller**.

If François opens the build and says “it is a little better” or “basically the same with improvements”, this mission is FAILED even if automated tests and technical gates pass.

The purpose of this mission is not to increase the number of mechanics. It is to make movement + physical combat + animation + victim reaction + camera + impact presentation work as one coherent game.

## What must be transformed together

Build the two-fighter R15 graybox foundation defined in Foundation 01. No character kits are required.

The playable loop must include and make enjoyable:
- analog ground movement with acceleration, braking and pivots;
- sprint with preserved momentum;
- jump with inherited horizontal momentum and meaningful air control;
- directional ground dash/dodge and air dash without ordinary CFrame teleporting;
- wall interaction/wallrun/wall jump with believable entry and exit momentum;
- lock-on/combat camera that keeps both bodies readable through ground/air/wall transitions;
- advancing light attacks with convincing anticipation/contact/follow-through;
- horizontal finisher;
- heavy attack with real commitment and whiff recovery;
- physical launcher that creates a real airborne victim trajectory;
- pursuit/chase that physically intercepts instead of snapping;
- aerial hits that visibly modify the victim trajectory;
- downslam that reaches ground collision, impact, knockdown and wakeup;
- guard/block;
- directional evasive/substitution-style universal escape with limited resource/counterplay;
- grab with forward and upward throw;
- wall impact/wallsplat or bounded rebound where the contact rules justify it;
- input buffering/cancel rules sufficient for continuous flow;
- victim reactions that are directional and readable;
- hit feedback: animation, motion, sound/VFX, camera impulse and optional brief hitstop used coherently rather than as camouflage.

No Minato/Itachi jutsu are needed to pass this mission. The physical loop alone must sustain repeated play.

## Architecture direction

Use the Foundation 01 recommendation as the default:
- R15 standard;
- native ControllerManager/GroundController/AirController first;
- Input Action System / one semantic input layer;
- server-authoritative outcomes with local responsiveness;
- one movement owner, one contact owner, one reaction owner, one animation owner and one camera owner;
- R15-native animation pipeline, not Bangla R6 retarget as production coverage.

Chickynoid is fallback only if the native stack fails a concrete qualification gate. Do not run both systems.

Replace or bypass Phase 6B runtime pieces that prevent the target. Bangla and Place1 are references, not architecture that must be preserved.

Do not protect old abstractions merely because they already exist.

## Token discipline

Spend tokens on code and integration.

Do NOT:
- write a new large plan;
- repeat Foundation 01 research;
- produce long interim reports;
- re-audit unrelated Forge/old mission files;
- create generic frameworks for future games;
- implement tournament, progression, shop, 20 fighters, Create-a-Ninja, AI expansion or character kits.

Work continuously until there is a playable build. Ask only if a blocker materially prevents implementation and cannot reasonably be resolved from the Foundation 01 documents.

## Human quality gate

Automated tests prove correctness, not feel.

Before calling this done, the build must support this unscripted controller sequence naturally:

`sprint -> pivot -> jump -> air steer -> wall interaction -> wall jump -> air dash -> land -> directional dodge -> advancing melee -> launcher -> pursuit -> air hits -> downslam -> knockdown/wakeup -> defend -> grab/throw -> re-engage`

No script may recognize that full sequence. It must emerge from common mechanics.

Human acceptance questions:
1. Does movement alone feel substantially better than Phase 6B?
2. Do attacks carry the fighter naturally instead of looking like poses beside a target?
3. Does every strong contact visibly change the other body?
4. Does launcher -> pursuit -> air exchange feel like one continuous interaction?
5. Can the camera follow vertical and wall exchanges without losing the fight?
6. Do misses and defensive choices create real punish/reposition decisions?
7. Can the same loop be played comfortably on controller?
8. Would two gray fighters with no jutsu already be worth playing repeatedly?

If any core answer is clearly no, fix it before declaring success.

## Definition of done

- Actual gameplay code is substantially modified/replaced; this is not a docs-only commit.
- A playable two-fighter R15 graybox/build exists.
- Movement, combat, reactions, animation and camera are integrated under the Foundation 01 ownership model.
- Old conflicting Phase 6B loops are removed/bypassed rather than layered underneath.
- Controller is fully playable.
- Build instructions are short and reproducible.
- Relevant automated tests pass, but no automated result is called human feel validation.
- Human acceptance matrix is updated only with evidence actually observed/tested.
- Commit all code/build changes.

Final response must be concise:
- commit SHA;
- exact build/place to open;
- major runtime systems replaced;
- controls;
- any genuine blocker/manual asset step;
- the shortest controller test route.

Do not write another proposal. Implement Foundation 02 now.