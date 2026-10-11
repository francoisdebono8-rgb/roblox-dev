# Movement Source Pipeline — Character-authentic choreography mining

Purpose: build a reusable bank of moves, combo fragments and transitions for Ninja Duel by studying how each Naruto character actually moves in anime/manga adaptations, official games and carefully selected fan-made material.

This file is a research protocol, not a rigid moveset spec.

## Source priority

Use this order whenever possible:
1. Canon anime/manga material at or near the target age.
2. Official Naruto games when they preserve character identity and add useful choreography.
3. Films/OVA/specials when age/power band remains appropriate.
4. High-quality fan-made fights and animations focused on the same characters or young-prodigy What-If scenarios.
5. AI/fan choreography only as inspiration for a movement idea, never as authority for lore.

## Lore filter

Tag every candidate move:
- `CANON_YOUNG`
- `PLAUSIBLE_YOUNG`
- `GAMEPLAY_LIBERTY`
- `REJECT_ADULT_ONLY`

The project explicitly allows selective gameplay liberties when they preserve the fighter's identity and make the combat better. The test is not strict timeline purity; the test is whether the move makes the young prodigy believable rather than a miniature endgame adult.

## Required record format

For every useful movement or combo fragment, record:

- Character
- Source
- Source version/approximate age
- Exact movement observed
- Starting state
- Contact type
- Footwork/body mechanics
- Opponent reaction
- Resulting combat state
- Follow-up opportunity
- Lore-fit label
- Reusable combat brick
- Character-specific expression
- Other fighters that could share the brick
- Input complexity
- Camera needs
- Wall/air compatibility
- Implementation risk

## Extraction examples

### Itachi — projectile redirection
Observed movement: one projectile changes the path/utility of another.

Gameplay extraction:
`ProjectileCollision -> RedirectTrajectory`

Reusable brick:
A projectile can carry collision/deflection properties and redirect another projectile under configured conditions.

Character expression:
Itachi gets superior precision, angle control and combo integration. Other characters may use the same physics with less mastery.

### Sasuke — aerial kick continuation
Observed movement: grounded launch transitions into acrobatic aerial kicks and downward finish.

Gameplay extraction:
`Launch -> AirPursuit -> RotationalStrike -> GroundSpike`

Reusable brick:
Generic aerial pursuit chain with character-specific animation package and timing.

Character expression:
Sasuke uses aggressive rotational kicks; Lee uses cleaner physical pursuit; Minato may replace one transition with FTG.

### Neji — limb redirection into palm counter
Observed movement: deflect/guide the attacking limb, step outside its line, immediately counter with a precise palm.

Gameplay extraction:
`RedirectDefense -> OutsideStep -> PrecisionCounter`

Reusable brick:
Directional counter state after successful close-range defense.

Character expression:
Neji converts it into chakra-point pressure. Kakashi may convert the same general state into a throw/elbow. Itachi may use a minimal counter strike.

### Minato — marked-angle continuation
Observed idea: spatial anchor already exists, allowing sudden reposition around the target.

Gameplay extraction:
`PreparedAnchor -> SideSwitch -> ShortPunish`

Reusable brick:
Persistent anchor transition system.

Character expression:
FTG remains Minato-specific even if other characters later use generic anchors/traps for different effects.

### Shisui — false trajectory
Observed idea: apparent movement continues while the real fighter exits the line.

Gameplay extraction:
`BurstMove -> DecoyTrajectory -> TrueExitAngle`

Reusable brick:
Afterimage/decoy movement state.

Character expression:
Shisui turns this into Body Flicker identity rather than teleport-anchor gameplay.

## Combo mining categories

When watching/searching material, deliberately capture examples of:
- neutral grounded strings,
- directional branches,
- jabs/crosses/hooks/palms/elbows,
- low attacks/sweeps,
- spinning kicks/360 attacks,
- launchers,
- anti-air attacks,
- aerial pursuit,
- aerial side-switch,
- ground spike/slam,
- wall splat continuation,
- wall-run attack,
- wall jump re-entry,
- grabs,
- throws/projections,
- limb controls,
- counters,
- evasive counters,
- clashes,
- projectile-to-taijutsu transitions,
- projectile redirection,
- wire usage,
- weapon catches/deflections,
- clone/afterimage transitions,
- teleport/flicker transitions,
- terrain-assisted movement,
- awakening-specific movement changes.

## Movement bank target per fighter

A mature fighter design should eventually have a research bank containing more candidates than the final playable kit. Aim for roughly:
- 5–10 grounded strike ideas,
- 3–6 lower-body/kick ideas where appropriate,
- 2–4 directional angle-change ideas,
- 2–4 launch/anti-air ideas,
- 2–4 aerial follow-ups,
- 1–3 grabs/projections or equivalent control moves,
- 2–4 defense/counter motions,
- 2–4 wall/environment interactions,
- 2–5 tool/projectile transitions if relevant,
- awakening movement variants.

Do not expose all of these as separate buttons. They are a research pool for directional branches, contextual states, cancels and character conversions.

## Initial roster research priorities

### Minato
Look for:
- short efficient strikes,
- marked-kunai angle changes,
- fast body repositioning,
- compact kicks/palms,
- aerial FTG continuation,
- sudden side/rear entry,
- Rasengan used as a conversion/finisher rather than isolated spell.

### Itachi
Look for:
- minimal evasions,
- wrist/arm control,
- short counters,
- no-look tool throws,
- shuriken redirection,
- projectile feints,
- Katon used to close routes,
- clone/crow transitions into physical attacks.

### Neji
Look for:
- palm chains,
- short circular footwork,
- limb redirection,
- stance transitions,
- tenketsu pressure,
- rotation exits,
- sweeps and low-line disruption,
- precise aerial palm follow-ups if plausible.

### Sasuke
Look for:
- Lion Combo-era movement,
- aggressive kicks,
- wall-assisted approach,
- aerial rotations,
- shuriken + wire transitions,
- fire used to create approach angles,
- Chidori as a committed conversion if retained.

### Naruto
Look for:
- clone-assisted launches,
- improvised grabs,
- awkward-but-effective body movement,
- clone feints,
- multi-angle attack sequences,
- one-tail movement changes.

### Gaara
Look for:
- automatic defense responses,
- remote grabs,
- sand launchers,
- air catches,
- terrain control,
- wall pinning,
- combos where Gaara's body barely moves but the combat state changes dramatically.

### Kakashi
Look for:
- weapon clashes,
- counters into throws,
- adaptive responses,
- clone substitutions into attack,
- compact lightning entries,
- multi-solution defense.

### Orochimaru
Look for:
- abnormal body evasions,
- extended-range attacks,
- snake-assisted control,
- underground/low-angle entries,
- unsettling recovery poses,
- weapon/body hybrid motion.

### Shisui
Look for:
- Body Flicker chains,
- decoy trajectories,
- sudden side switching,
- attacks that begin from one line and finish on another,
- tantō + mobility transitions,
- afterimage counters.

### Rock Lee
Look for:
- pure footwork,
- Dynamic Entry-style attacks,
- rising kicks,
- spinning/heel kicks,
- aggressive physical pursuit,
- Lotus transitions,
- gate-state movement changes.

## Search strategy

Research should use queries centered on the actual character and age/version, for example:
- `young Minato fight animation`
- `Minato childhood moves Naruto game`
- `young Itachi taijutsu shuriken`
- `Itachi prodigy fan animation`
- `Neji taijutsu combo game`
- `young Sasuke Lion Combo animation`
- `Shisui Body Flicker fan animation`
- `young Kakashi fight`
- `Gaara chunin exam movement`
- `Rock Lee chunin exam combo`
- `Naruto prodigy chunin exams fan animation`
- `young prodigies Naruto tournament`

When a fan-made prodigy tournament/fight is found, mine the choreography but validate each movement against the character's intended age/power band before using it.

## Final rule

Do not ask only: `Is this move cool?`

Ask:
1. Does this feel like this character?
2. Does it fit or reasonably bend our young-prodigy lore?
3. What combat state does it create or connect?
4. Can the underlying idea become a reusable brick?
5. How does this fighter express that brick differently from everyone else?
6. Does it remain player-controlled rather than becoming a canned cinematic?

Only then prototype it in Studio.