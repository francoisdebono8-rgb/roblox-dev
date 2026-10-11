# Kimi Motion Quality Pass

## Goal
Use Kimi as the visible-motion specialist for Forge Motion Lab / Ninja Duel when Claude is unavailable.

The current presets are structurally useful but the locomotion, idles, strikes and transitions are still too generic, under-amplified or biomechanically weak.

The deliverable is NOT more infrastructure. It is visibly better movement.

## Core objective
Create movement and strike presets that are:
- less generic,
- more detailed,
- more physically logical,
- more readable,
- more character-specific,
- inspired by real visual references from anime, Naruto games, serious fan-made / What-If animations and high-quality Roblox/anime combat references,
- still compatible with our young-prodigy lore and existing Ninja Duel systems.

## Mandatory workflow
For every substantial motion idea, follow:

`visual source -> observed motion -> why it reads well -> body mechanics -> reusable motion block -> character adaptation -> Motion Lab variant -> preview -> keep/reject`

Do not simply copy whole sequences. Extract useful movement logic.

## What to improve first
### 1. Locomotion
For each target profile, improve:
- idle combat stance,
- walk forward/back,
- run,
- sprint,
- strafe,
- diagonal movement,
- turn/pivot,
- stop/deceleration,
- takeoff/landing where relevant.

Movement must show:
- foot placement,
- center-of-gravity logic,
- hip contribution,
- torso counter-rotation,
- believable arm carriage,
- cadence matching speed,
- character-specific posture.

### 2. Basic strikes
Improve and diversify:
- jab,
- cross,
- hook,
- uppercut,
- palm,
- elbow,
- front knee,
- rising knee,
- front kick,
- side kick,
- roundhouse,
- low/high kick,
- spinning kick,
- sweep,
- launcher,
- simple grab/throw where appropriate.

Each strike should have at least:
- anticipation,
- weight transfer,
- hip/torso sequencing,
- contact pose,
- follow-through,
- recovery,
- root travel appropriate to the move.

### 3. Transitions
Improve transitions so attacks do not look like disconnected poses:
- punch -> punch,
- punch -> kick,
- kick -> knee,
- dodge -> counter,
- launcher -> chase,
- ground -> air,
- wall -> re-entry,
- landing -> attack.

## Character expression sanity checks
Use shared grammar but different expression.

### Neji
- persistent Gentle Fist silhouette,
- compact palms,
- circular footwork,
- stable center,
- minimal wasted motion,
- precise short impacts.

### Lee
- extreme cadence,
- explosive physical chase,
- lower-body dominance,
- many taijutsu-specific routes,
- athletic rotations,
- no dependence on ninjutsu for movement identity.

### Itachi
- economical movement,
- calm upper body,
- short precise counters,
- deceptive transitions,
- projectile-ready hand carriage.

### Minato
- light, efficient, forward-ready locomotion,
- short explosive changes of angle,
- compact strikes,
- body always ready to convert into repositioning.

### Gaara
- near-minimal body locomotion,
- calm torso,
- do not make him move like a normal brawler,
- where appropriate let future sand actions replace physical grammar rather than forcing generic punches.

### Killer Bee
- asymmetric stance,
- lively rhythm,
- irregular attack cadence,
- multi-axis / multi-weapon-ready body language.

## Reference quality
Prioritize real, readable sources:
1. canon anime / manga-adapted motion,
2. official Naruto games where choreography is clear,
3. high-quality fan animations / What-If fights,
4. high-quality Roblox/anime combat games for Roblox-specific readability.

When direct web/video access is unavailable, work from frames/screenshots or local references provided in the repo and clearly note which motions are extrapolated.

Lore filter:
- CANON_YOUNG
- PLAUSIBLE_YOUNG
- GAMEPLAY_LIBERTY
- REJECT_ADULT_ONLY

Do not turn young characters into miniature adult/final forms.

## Motion Lab requirements
Implement improvements as editable Motion Lab variants, not irreversible hard-coded gameplay changes.

For every new motion variant expose the parameters Claude/Kimi can later retune:
- amplitude,
- hip rotation,
- torso follow,
- limb extension,
- root travel,
- anticipation,
- contact timing,
- follow-through,
- recovery,
- cadence,
- stance bias,
- mirror where relevant.

Preserve NinjaDuelAdapter compatibility.
Do not auto-apply changes to live Ninja Duel gameplay.

## Success criteria
A reviewer should be able to compare old vs new and immediately see:
- walks/runs are no longer generic,
- punches/kicks have clearer body mechanics,
- characters no longer share the same movement language,
- transitions are less mannequin-like,
- motion amplitude and logic are editable in the plugin,
- the output remains reusable by Claude later.

## First benchmark
Start with four visibly different profiles:
- Neji,
- Lee,
- Itachi,
- Gaara.

For each, deliver:
- improved idle,
- walk/run/strafe family,
- at least 5 improved strikes,
- at least 3 useful transitions,
- short notes on visual inspiration and why each motion choice fits the character.

Then, if time remains, extend to Minato / Shisui / Killer Bee.

## Hard constraints
- Do not spend the pass on architecture cleanup.
- Do not redesign the combat system.
- Do not change damage, AI, economy or networking.
- Do not hide generic motions behind VFX.
- Body mechanics first.
- Keep all output editable and data-driven.

## Final report
Return only:
1. commit SHA,
2. profiles/motions improved,
3. which references informed them,
4. what is genuinely implemented vs approximated,
5. how François can preview old vs new in Forge Motion Lab.
