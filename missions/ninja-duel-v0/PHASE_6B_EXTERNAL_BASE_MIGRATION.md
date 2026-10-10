# PHASE 6B — EXTERNAL BASE MIGRATION

## Objective

Phase 6 did not materially improve the feel because generic combat/movement systems were again implemented locally. Stop that approach.

This mission must **directly improve the existing `games/ninja-duel` game by importing and adapting proven free/open-source Roblox game code**. Do not make separate throwaway demos unless needed for a very short compatibility check. The final deliverable is the normal Ninja Duel playable place, with Minato vs Itachi still present, but its weak generic systems replaced by the best external implementations found here.

Optimize for implementation, not analysis. One pass. Minimal documentation. Do not reread old mission files unless required to understand an existing interface.

## Non-negotiable rule

**DO NOT reimplement a donor system locally merely because integration is inconvenient.**

For combat, movement, camera, hit reactions, dash, etc.:
1. inspect donor;
2. identify working implementation;
3. import/adapt that implementation;
4. connect it to Ninja Duel;
5. only write glue, compatibility code, game-specific behavior, security validation, or a genuinely missing mechanic.

If a donor component cannot legally or technically be reused, reject it explicitly and move to the next donor. "Behavioral reference + new local implementation" does NOT satisfy this mission for the core combat foundation.

Only free/open-source resources with clear reusable rights may be copied. Preserve required license notices/attribution.

---

# 1. PRIMARY DONOR — USE FIRST

Repository: `dwmk/RobloxGames`
License: MIT at repository root.

The author explicitly provides ready-to-play `.rbxl` games and permits importing scripts/models/UI into other projects.

Inspect these games in this order:

1. `Bangla Battlegrounds` — unfinished combat/abilities game inspired by The Strongest Battlegrounds. **Primary combat candidate.**
2. `Broken.` — action PvP arena; inspect for combat, NPC, match/camera/UI systems that are better than ours.
3. `Demon Hunting Paradise` — inspect only for useful combat/movement/weapon/feedback components not already supplied better by Bangla/Broken.

Do not blindly merge entire places. Extract the strongest relevant systems/assets and preserve their working relationships/dependencies.

### Combat selection criterion

Prefer the donor implementation that feels closest to a real Roblox battleground fighter:
- responsive M1
- attack movement/lunge
- hitstun/reactions
- knockback
- dash
- guard/defense if available
- combo flow
- ability integration
- animations/VFX/feedback
- victim interaction

If Bangla supplies most of this, make it the new combat foundation rather than trying to preserve our old Brawler/Combat abstractions.

---

# 2. MOVEMENT DONOR

Repository: `alexkkork/place1-movement-system`
License: MIT.

It contains full Luau source and a release `.rbxm`; supports R6 + R15 and keyboard/gamepad; includes sprint, momentum, air control, slide/slide-jump, mantle, wall hops and camera/FOV movement effects.

Use/adapt its **actual source/package** for useful ninja locomotion components rather than recreating them.

Important adaptations:
- Ninja Duel is third-person, so remove/disable its forced first-person assumptions and FPS-only camera/head-bob behavior where inappropriate.
- Retain useful momentum, sprint, air-control and wall logic.
- Our game needs wall traversal closer to ninja wall-run/wall-jump; extend the donor wall implementation only as necessary rather than replacing the whole donor movement stack.
- Add server-side validation seams for competitive movement because donor movement is client-driven.
- Preserve controller support.

Do not import slide/mantle simply because they exist if they hurt our combat. Reuse the underlying movement implementation selectively.

---

# 3. CURRENT NINJA DUEL: PRESERVE GAME-SPECIFIC VALUE, NOT WEAK ENGINES

Keep/reconnect where useful:
- Minato and Itachi selection/identity
- health/chakra/substitution concepts
- Minato-specific techniques
- Itachi-specific techniques
- Fire / kunai / shuriken / Read / genjutsu concepts
- match lifecycle
- tutorial structure
- AI goals
- controller menu flow
- server-authoritative legality/security where already useful

Do NOT preserve merely for compatibility:
- weak local M1 implementation
- weak local combo engine
- stiff local hit-reaction system
- local dash/movement if donor is materially better
- procedural attack presentation that causes the current bad feel
- abstractions whose only benefit is avoiding migration work

Deleting/replacing local modules is allowed and expected.

---

# 4. REQUIRED FINAL COMBAT IN THE REAL GAME

After migration, the normal Ninja Duel place must support at minimum:

- responsive third-person movement
- controller + keyboard
- target lock / usable combat camera
- sprint
- jump + air control
- directional dash/dodge
- wall movement using donor-derived implementation
- responsive light melee chain
- visible punches/kicks rather than static pose swaps
- attack travel/lunge
- heavy/finisher
- intentional launcher
- actual airborne victim reaction
- chase/pursuit
- aerial follow-up
- downslam/knockdown
- guard or equivalent defense
- limited substitution/evasive
- grab/throw if donor or existing implementation can be integrated cleanly
- convincing knockback/hit reaction
- Minato/Itachi techniques integrated into the same combat flow
- AI able to fight with the resulting system

The external combat foundation may use a different internal combo grammar from Phase 6. Preserve **feel and interactions**, not old API shape.

Do not spend time adding new jutsu. Existing character kit breadth is enough. Make the fight itself better.

---

# 5. CONTROLLER

The migrated system must remain fully playable with a standard controller.

Map donor actions into our semantic input layer rather than maintaining two competing input systems.

Required controller actions:
- move
- camera
- lock
- jump
- light
- heavy/launcher context
- dash/dodge
- guard
- substitution/evasive
- techniques
- character select/tutorial/rematch UI

Update tutorial prompts to the final mapping. No combat action may require mouse/keyboard.

---

# 6. ANIMATION / VFX / AUDIO

If the MIT donor contains original reusable animations, VFX, UI or other presentation assets covered by the repository license, integrate the useful ones and retain attribution/license notice.

Do not replace working donor presentation with our procedural placeholders merely to match the old architecture.

Where Roblox ownership prevents a donor animation ID from playing under our experience, preserve the choreography/timing integration and document the exact asset-publication action required. Do not silently fall back to the same stiff Phase 6 presentation and call the migration complete.

No unlicensed Toolbox assets.

---

# 7. INTEGRATION ORDER — KEEP TOKEN USE LOW

Do this directly, without writing a large report:

1. Snapshot current working Ninja Duel state in git.
2. Inspect `dwmk/RobloxGames` files/places and locate Bangla combat dependencies.
3. Import the selected combat foundation into `games/ninja-duel`.
4. Make one human-vs-dummy/AI melee loop work inside OUR arena before touching jutsu.
5. Remove/bypass conflicting old combat modules.
6. Integrate selected `place1-movement-system` source into OUR game; convert to third-person and connect server validation.
7. Reconnect controller input/camera.
8. Reconnect Minato and Itachi kits to donor combat events/action API.
9. Reconnect AI.
10. Reconnect/update tutorial.
11. Build the normal playable Ninja Duel place.
12. Run automated/native tests that are meaningful.
13. Commit.

Do not create speculative architecture docs. Do not create a second combat framework alongside the donor. Migration means the donor-backed implementation becomes the real implementation.

---

# 8. FAILURE POLICY

If Bangla's raw combat is technically unusable after direct inspection, do NOT recreate it.

Instead:
- state the concrete blocker in <=5 lines;
- immediately inspect `Broken.`;
- then `Demon Hunting Paradise`;
- use the best legally reusable implementation among them.

If none of the three contains a viable combat foundation, STOP the combat migration and report that fact. Do not consume the mission by writing another custom engine.

Movement may still use `place1-movement-system` if independently viable.

A failed donor search is preferable to another Phase 6 disguised as integration.

---

# 9. ATTRIBUTION

Update `games/ninja-duel/THIRD_PARTY.md` with only:
- repository
- license
- exact files/components/assets copied/adapted
- modifications made
- required notices

Include the MIT copyright/license text where required for distributed substantial portions.

---

# 10. ACCEPTANCE TEST

Do not mark subjective items PASS yourself. Build so François can perform this single test with a controller:

1. launch normal Ninja Duel build;
2. choose Minato;
3. move/sprint/jump/dash for 20 seconds;
4. wall move + wall jump;
5. lock Itachi;
6. perform normal melee combo;
7. deliberately launch Itachi;
8. chase into air;
9. hit aerial follow-up and slam him down;
10. block/dodge one AI sequence;
11. use substitution;
12. land kunai/Quickstep/Burst Entry or current Minato equivalents;
13. rematch as Itachi;
14. use shuriken/Fire/Read/genjutsu in the same combat flow;
15. complete/replay tutorial with controller.

The important comparison is simple:

**Does this immediately feel materially better than Phase 6 before character abilities are considered?**

If not, do not hide it with more effects/features.

---

# 11. DEFINITION OF DONE

Done means:
- actual external MIT/open-source implementation is present in the real Ninja Duel code/build;
- donor code is used for a core system, not merely cited as inspiration;
- normal Minato vs Itachi game still works;
- controller still works;
- tutorial still works;
- combat/movement foundation has actually been migrated;
- old conflicting local engine code is removed/bypassed rather than layered underneath;
- build is ready for François's controller test;
- attribution is correct.

Final response to François must be short:
1. commit SHA(s);
2. which donor became combat foundation;
3. which donor became movement foundation;
4. exact imported/adapted components;
5. build/place to open;
6. controller mapping;
7. blockers/manual asset steps;
8. the 15-step acceptance test above.

Do not propose another phase.