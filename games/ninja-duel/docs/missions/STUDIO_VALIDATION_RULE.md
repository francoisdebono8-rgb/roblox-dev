# Studio validation rule

From now on, anything that exists in code and is supposed to be player-facing must be validated in Roblox Studio before it is considered done.

This applies to every gameplay-visible system and interaction, including combat, movement, inputs, combos, jutsu, awakenings, chakra, tools, elements, fighter identity, VFX, reactions, camera, arena interactions, UI/HUD feedback, AI behavior and any new character mechanics.

Automated tests are necessary but not sufficient. A feature is not "done" because the code path exists or the test suite passes.

## Required workflow
1. Implement the feature.
2. Build the actual playable artifact.
3. Open/test it in Roblox Studio.
4. Trigger the feature through the real game flow whenever possible, using real keyboard/mouse/gamepad-style inputs rather than only direct debug calls.
5. Observe the result in motion, not only as frozen data or headless state.
6. Fix any visual, timing, input, animation, state, collision or integration issue found in Studio.
7. Only then report it as validated.

If a feature cannot be validated in Studio yet, report it explicitly as `IMPLEMENTED / NOT YET STUDIO-VALIDATED`, never as complete.

## Global rule
All functionality already present in the codebase but not yet observed in Studio must progressively be validated there as part of the V1 convergence pass.

The objective is to eliminate the repeated gap between "works in code/tests" and "surprises when actually played".

Do not create a parallel documentation project around this rule. Apply it directly while continuing the current V1 work.
