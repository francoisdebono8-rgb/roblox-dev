# Final pass for today — fluidity, taijutsu, third fighter, bug sweep

Continue from the latest Phase 4 head. Do **not** reread or audit the whole repo unless needed. Reuse existing systems and spend tokens on implementation/testing, not long reports.

## 1) Fluidity / visual motion / camera
Make the game look and feel smoother, especially during fast movement.

Priorities:
- reduce visual judder/snaps during dashes, teleports, chase, wall-run, aerial pursuit and fast combo transitions;
- improve animation blending and body continuity at high speed;
- reduce obvious foot sliding / limb popping / pose discontinuities;
- tune camera smoothing, orbit speed, anticipation and recovery so it keeps up with fast exchanges without becoming chaotic;
- make combat rhythm more adaptive: not 100% speed all the time. Use short pauses, spacing, anticipation, acceleration and explosive bursts so fast moments feel faster and important hits breathe.

Use Studio playtests repeatedly. Prefer a coherent readable duel over maximum constant speed.

## 2) Taijutsu must become a core strength
Taijutsu is essential. Improve the base melee so it feels satisfying even with all VFX disabled.

Focus on:
- stronger body mechanics: hips/shoulders/weight transfer, believable punches, kicks, blocks and reactions;
- better contact timing between animation, hitbox and impact;
- more varied light/heavy routes and situational follow-ups;
- kicks, sweeps, launchers, aerial strikes and wall follow-ups where appropriate;
- hit reactions, knockback, sound/camera/hitstop used with restraint — impact must come from animation and motion first, FX second;
- better neutral exchanges: movement, whiff punish, guard pressure, feints, parry/dodge opportunities;
- keep Minato and Itachi distinct in taijutsu style.

Do not solve weak melee by adding more particles.

## 3) Third fighter prototype
Add **Neji** as the third playable prototype unless current architecture makes another already-planned roster fighter dramatically cheaper. Neji is preferred because he validates the taijutsu system.

He does **not** need Minato/Itachi depth yet. Deliver a clear prototype with:
- youth-tournament look (12–14 prodigy, not adult version);
- distinct stance / locomotion identity;
- functional basic combo tree;
- Byakugan identity;
- Gentle Fist / precision chakra-point style represented in gameplay;
- 2–3 signature techniques max;
- one distinctive defensive/control mechanic;
- enough AI + UI integration to fight Minato/Itachi.

Goal: prove the combat architecture can support a genuinely different third archetype, not finish the character.

## 4) Full bug sweep across the entire playable flow
During every step, actively look for and fix bugs, especially:
- character select / duel start / intro;
- spawn/reset/rematch/death/KO;
- camera loss, wrong-side framing, occlusion;
- stuck states, eaten inputs, impossible recovery states;
- substitution, clash, wall splat/tech, launch/chase/slam;
- teleports and seals;
- projectiles / hazards;
- AI edge cases;
- HUD desync / missing bars / prompts;
- collision issues with arena props/walls;
- animation freeze, limb snap, floating/ground clipping;
- switching between all three fighters.

Fix issues as discovered; do not only list them.

## 5) Delivery — make Mac testing trivial
At the end:
- commit and push all work to the shared GitHub branch;
- rebuild `games/ninja-duel/dist/NinjaDuel.rbxlx` and `NinjaDuel-QA.rbxlx`;
- ensure `NinjaDuel.rbxlx` is the latest complete playable build and opens directly in Roblox Studio on macOS;
- keep it in the public/shared repo so it can be downloaded from GitHub without local build steps;
- add only a **short** final report: commit SHA, major changes, controls for Neji, tests run, remaining blockers.

## Acceptance target
Before stopping today, the game should feel noticeably smoother, less constantly frantic, stronger in pure taijutsu, safer from flow-breaking bugs, and should include a clearly playable third-fighter prototype.

Work autonomously: implement → Studio test → tune → bug-fix → rebuild → push. Do not stop at an audit.