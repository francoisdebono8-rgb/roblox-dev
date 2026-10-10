# 45-MINUTE FINAL PLAYABLE PASS

## Goal
Deliver the best visibly playable version possible within ~45 minutes. Prioritize player-facing fixes over architecture. Do not stop at an audit.

## Non-negotiable priorities

### 1) Remove visible stutter / teleporting motion
Current problem: characters visibly jump from place to place and body motion does not match displacement.

Fix aggressively:
- smooth root translation and facing during fast movement;
- eliminate visible position snapping between network/snapshot updates;
- ensure body/legs/arms match actual travel speed and direction;
- reduce foot sliding and pose mismatch during dash, chase, wall-run, teleport arrival, aerial pursuit and landing;
- make camera interpolation follow high-speed movement smoothly without late catch-up, hard recentering or micro-jumps;
- tune interpolation/extrapolation/snapshot cadence/render buffer if necessary;
- keep responsiveness: no huge visual delay just to hide stutter.

Acceptance: when sprinting, dashing, chasing, wall-running and fighting in air, a player should perceive continuous motion, not discrete position hops.

Reference target: the *idea* of Storm 4 readability/continuity at speed, not the same animation detail or locked gameplay.

### 2) Make movement/animation readable
We still do not see enough distinct body actions.

Improve:
- stronger anticipation/contact/recovery silhouettes;
- clear hips/shoulders/feet involvement;
- distinct run, dash, strafe, retreat, wall-run, jump, aerial drift, landing, pursuit and recovery poses;
- attacks should not visually collapse into the same generic motion;
- fast actions may use short arcs/afterimages, but body animation must remain the primary source of motion readability.

### 3) Taijutsu is a core pillar
Naruto combat must feel good even without jutsu.

Improve global taijutsu:
- clearer punch/kick chains;
- more impact through body mechanics, acceleration, contact timing, hit reaction and displacement — not only FX;
- add/strengthen projections/throws, launchers, aerial exchanges, ground-to-air and air-to-ground follow-ups;
- add visually impressive but controllable exchanges: knock-away -> chase -> re-entry, wall bounce -> follow-up, aerial intercept, throw/reversal opportunities where appropriate;
- hit reactions should sell where and how the body was struck.

### 4) More and better differentiated combos
Current issue: combo routes are too few and visually too similar.

For Minato, Itachi and Neji:
- create visibly different light/heavy/launcher/aerial/wall/character-specific routes;
- make route choice depend on context (distance, wall, air, seal, counter, projectile setup, chakra point state, etc.);
- preserve freedom: jutsu/special tools should integrate into routes without forcing one canned string;
- ensure each fighter has a clearly different taijutsu rhythm and spatial behavior.

Do not merely add damage variants; animations, cadence, displacement and tactical purpose must differ.

### 5) Damage should persist visually
Add lightweight but readable battle wear:
- clothing scuffs/tears/dirt or damage-state overlays where practical;
- limited blood/hit marks where appropriate and tasteful;
- stronger accumulated visual wear at low health;
- avoid gore; this is feedback, not spectacle.

The opponent should increasingly look like they have been through a fight.

### 6) Finish the arena enough to feel intentional
Do a focused arena completion pass:
- remove obvious unfinished/placeholder-looking areas;
- improve the central field, walls, tournament structures and visual composition;
- ensure walls/obstacles are usable and readable for combat;
- prevent scenery from hurting camera or collision;
- keep the tournament-of-young-prodigies identity.

### 7) Full bug sweep through the complete player journey
Before delivery, test in Studio:
selection -> intro -> combat -> fast movement -> wall interactions -> aerial -> jutsu -> substitution -> KO -> result -> rematch -> character switch.

Test all three fighters in representative matchups. Fix blockers, state locks, camera failures, visual snapping, broken HUD, missing effects, bad collisions and movement desync discovered during this pass.

## Time discipline
Target ~45 minutes total.

Suggested split:
- 20 min: stutter/root motion/camera + movement readability
- 12 min: taijutsu/combo differentiation
- 5 min: damage wear + arena obvious gaps
- 8 min: Studio bug sweep, rebuild, publish/delivery

If time runs short, sacrifice secondary visual extras before sacrificing motion smoothness, taijutsu clarity or a stable final build.

## Public + easy access delivery
At the end:
1. commit and push all work to the current branch;
2. rebuild `games/ninja-duel/dist/NinjaDuel.rbxlx`;
3. if the authenticated Roblox Studio session allows it, **publish/update a Roblox Experience** so the user can open/play the same build from both PC and Mac without downloading folders;
4. record the public/shareable Roblox experience link or exact Experience/Place identifier in `PUBLIC_BUILD.md`;
5. if publishing is blocked by account/auth/permissions, do not waste the pass fighting it: document the exact blocker in `PUBLIC_BUILD.md` and still leave the rebuilt `.rbxlx` ready.

The GitHub repository/build should remain available too.

## Final report
Keep it short. State:
- commit SHA;
- what was fixed for stutter/motion/camera;
- what changed in taijutsu/combo routes;
- arena/damage-wear changes;
- Studio tests run and remaining known issues;
- public Roblox Experience link/ID if successfully published.

Do not spend time writing a long design document.