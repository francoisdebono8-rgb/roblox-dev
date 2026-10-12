# Claude Mission — Four-Character Final Combat Pass

Technical preparation handoff: [docs/current/CLAUDE_TECHNICAL_HANDOFF.md](docs/current/CLAUDE_TECHNICAL_HANDOFF.md). Read the four-character matrix, state/tool contracts and exact motion mapping before artistic iteration. The technical pass did not approve visual/game-feel gates.

## Operating mode

You are taking over an already-advanced Roblox combat project. The user should not have to prepare files, install Git manually, move folders, or explain the repository structure to you.

Your job is to retrieve the project from GitHub, understand it completely, set up whatever local tooling you need, open and test the game in Roblox Studio, then push your work back to GitHub.

Repository: `francoisdebono8-rgb/roblox-dev`
Game: `games/ninja-duel`
Current playable builds: `games/ninja-duel/dist/NinjaDuel.rbxlx` and `games/ninja-duel/dist/NinjaDuel-QA.rbxlx`

If Git is missing, install/use Git or GitHub Desktop yourself. If another lightweight development tool is genuinely necessary, set it up yourself. Do not send the user through setup work you can perform.

Do not work directly on `main`. Create and use:

`claude/minato-itachi-final`

Push working checkpoints and the final state to GitHub.

---

# Goal

Take the existing project from a technically solid prototype to the first genuinely convincing **Naruto-like four-character combat slice** built around the current playable roster:

- **Minato**
- **Itachi**
- **Neji**
- **Sasuke**

Do not treat Minato and Itachi as the only real fighters anymore. All shared-system, movement, combo, neutral, defensive and tool decisions must be judged against the four-character roster. Character-specific sections for Minato or Itachi remain valid where they concern their unique systems, but the project-level target is now the full four-character core.

The result must be visibly different when launched. We are no longer optimizing primarily for clean architecture. We are optimizing for **combat quality, animation quality, Naruto fantasy, responsiveness, spectacle, readability and fun** while preserving the strong systems already built.

Do not restart the project and do not replace working foundations just because you would architect them differently.

Your loop is:

**audit → launch in Studio → play → observe → modify → play again → polish → repeat**

Do not stop after an audit.

---

# 1. Understand the existing project first

Before major changes:

- read the README and previous pass documents;
- inspect all relevant client/server/shared code;
- understand combat, movement, camera, AI, networking, abilities, projectiles, animation/presentation, arena and build pipeline;
- launch the current `.rbxlx` in Roblox Studio;
- play **all four current fighters** and reproduce their important combat routes yourself.

Preserve the good work already present: interpolation, server combat authority, hit detection improvements, procedural body presentation, current combos, AI, arena, QA and build pipeline unless a real defect requires changing them.

---

# 2. Roblox Studio is mandatory

You have Roblox Studio available. Use it throughout the work.

Do not finish with `visualAcceptance: PENDING` merely because code tests pass.

You must actually look at the game, play it, judge it and improve it.

Automated tests remain useful, but a test cannot tell you whether an animation looks bad, a fireball feels weak, a camera move is unpleasant, or a kunai looks fake.

---

# 3. Animation quality must take a major step forward

The current procedural Motor6D layer is a useful foundation, not the target quality bar.

Create or integrate substantially better combat animations where appropriate. Use Roblox's actual animation system when it produces a better result, while retaining procedural/additive motion where it helps.

The characters must visibly use their entire bodies.

Improve:

- combat idle;
- ninja run / sprint;
- forward/back/strafe movement;
- acceleration, stopping and turning;
- dash and dodge;
- jump, rise, apex, fall and landing;
- wall movement;
- punches and kicks;
- combo transitions;
- heavy attack;
- launcher;
- chase;
- air combo;
- slam;
- guard/parry;
- hit reactions;
- knockdown/get-up;
- grabs/throws;
- KO.

Focus on anticipation, weight transfer, foot placement, torso rotation, arm/leg arcs, contact poses and follow-through.

The result should no longer read as "a Roblox mannequin with joints being rotated".

Shared movement quality must improve without flattening character identity. Neji must not move like Minato, Sasuke must not feel like Itachi, and shared attacks should be adapted through stance, rhythm, angle, recovery and conversion rather than copied unchanged.

---

# 4. Fix the remaining jump / combo / state bugs

Aggressively test and repair:

- jump → attack;
- attack → jump;
- launcher → chase;
- air combo;
- slam;
- dash attack;
- wall interaction;
- attack immediately after teleport where relevant;
- hitstun and knockdown;
- recovery/cancel windows;
- repeated combo inputs;
- landing during combat;
- camera during vertical sequences.

Eliminate visible and gameplay problems such as:

- floating;
- snapping;
- hovering after slam;
- combos unexpectedly dying;
- visually connecting hits that miss mechanically;
- invisible hits;
- bad pursuit positioning;
- frozen states;
- animation states that fail to recover;
- incorrect momentum after aerial actions;
- camera losing the fighters.

If an input succeeds, the body and gameplay result should agree.

---

# 5. Use Ninja Storm as a combat-flow reference

Use **Naruto Ultimate Ninja Storm** as inspiration for feel, not as something to copy literally.

Study the qualities we want to evoke:

- fast approach;
- immediate attack follow-up;
- readable strings;
- smooth launcher → chase → aerial continuation;
- responsive substitution/dodge-style reactions;
- short downtime;
- anime-like speed;
- dramatic but readable impacts;
- camera that supports the exchange rather than fighting the player.

We want more flow such as:

`run → dash → combo → launcher → chase → air attacks → reposition → jutsu`

and less:

`attack → pause → cooldown → isolated ability → pause`.

Do not create unescapable endless combos. Preserve counterplay and clear recovery opportunities.

---

# 5B. Additional combat references — study the fight between combos, not only the combos

The user explicitly wants this pass to absorb lessons from these references as well as Ninja Storm:

- Roblox experience shown by the user: **[UPD 1] Voie Shinobi / Shinobi Way**;
- Roblox experience shown by the user: **Naruto — Arène de combat Shinobi ultime / Naruto Ninja Fighting Arena**;
- provided combat-system + weapons video: `https://youtu.be/uomkLDU10Lo?is=CrkR68i87Xife6tv`.

Do not copy assets, code, exact move lists or UI. **Play/inspect the experiences where accessible and study the supplied video yourself before deciding what to implement.** Extract the combat principles, interaction density and weapon/tool ideas that are useful for Ninja Duel.

The important realization is that our project has spent a lot of effort on what happens **after a clean hit starts a combo**, but a convincing ninja fighting game also needs the moments before, between and after those strings to be interesting.

The target exchange is closer to:

`run → slow/read → feint → tool/projectile → dodge/deflect → angle change → clash → short strike → counter → pursuit → conversion → disengage/reposition`

not merely:

`approach → M1 string → ability → cooldown`.

## Build a richer universal combat language without creating a second combat engine

Reuse the current combat grammar and foundations. Add or deepen only the common layers that materially improve the playable **Minato / Itachi / Neji / Sasuke** core and that can later be bent by more characters.

### A. Defense must be as expressive as offense

Evaluate and improve the current defensive loop around a compact shared language such as:

`guard → timed deflect/parry → dodge/perfect dodge → counter → substitution/kawarimi escape`

These do not need five unrelated buttons. Prefer context, timing and existing inputs where possible.

Desired outcomes:

- normal guard mitigates/absorbs appropriately;
- well-timed defense can redirect momentum or create a small punish window;
- dodge changes angle rather than merely adding invulnerability;
- substitution/kawarimi is an expensive escape/reset, not free spam;
- defense transitions naturally back into movement, tools or attacks.

The opponent must remain involved during pressure instead of simply waiting for a combo to finish.

### B. Weapons are combat states, not isolated ability buttons

Weapons/tools should alter the fighter's available body language and routes instead of behaving like detached specials.

Examples of the intended principle:

`punch → kunai draw/slash → kick → throw kunai → pursue`

or, for an appropriate sword user later:

`draw → slash → thrust → parry/clash → body strike → disengage`.

For this vertical slice, prioritize what matters to the four current fighters:

- Minato: kunai handling in-hand as well as throwing, marked destinations and immediate angle conversion;
- Itachi: shuriken integration into pressure/spacing and deceptive trajectories;
- Neji: close-range hand control, precise palm contact, deflection/counter transitions and minimal dependency on weapons;
- Sasuke: shuriken/kunai routes, wire-compatible pressure where supported, fire integration and more aggressive tool-to-taijutsu conversion;
- believable draw, grip, release, recovery and transitions;
- tools usable while moving and as bridges between ranges.

Do not turn the game into a weapon inventory simulator and do not overload the input map.

### C. Shared ninja tools should become a system

Build on the existing philosophy that common tools are shared while character mastery changes their interpretation.

Useful common families include, where they genuinely improve this slice:

- kunai;
- shuriken;
- explosive tags;
- smoke;
- wire;
- persistent embedded/projectile points.

Character interpretation matters more than quantity:

- **Minato:** marked kunai, spatial preparation, FTG destinations and angle changes;
- **Itachi:** shuriken geometry, forcing reactions, deception and delayed/redirected pressure;
- **Neji:** standard tools remain secondary; his mastery comes from perception, precision, parries/deflections and close-range chakra-point style conversion;
- **Sasuke:** aggressive shuriken/kunai usage, wire/fire routes and forward-pressure conversions.

Preserve the systemic idea:

`Object + Chakra Property/Nature + Trigger/Context → Result`

Examples for future-compatible infrastructure: marked kunai → FTG destination, wind + blade/projectile → cutting/velocity bias, lightning + metal/wire → conductive interaction, fire + projectile → ignition/area pressure.

Do not implement every combination now. Make the four-character slice prove that the grammar can support them.

### D. Clashes and contested contact

The combat should not always resolve as "whoever touched first gets a full string".

Where technically and visually appropriate, support contested moments such as:

- strike vs strike;
- weapon/tool vs weapon/tool;
- attack vs well-timed guard/parry;
- projectile vs projectile;
- strong technique vs compatible response.

Possible outcomes include:

`clash → recoil`

`clash → deflection`

`clash → small positional advantage`

`clash → both reset/reposition`

Keep clashes readable and deterministic enough for gameplay. They are not an excuse for random cinematic interruptions.

### E. More meaningful body/combat states

The existing contact → state change → transition philosophy should become more visible.

Evaluate whether the combat needs stronger support for states such as:

- neutral;
- guarded;
- staggered;
- off-balance;
- guard-open;
- launched;
- falling;
- wall-splat;
- grounded;
- recovering;
- grabbed;
- weapon-clash.

Not every state needs a new subsystem. Prefer a small reusable state vocabulary that moves can convert between.

The important design rule is:

**a move is valuable because of the state/position it creates, not because it is another animation in a list.**

### F. Grabs, catches and physical conversions

The current game should feel capable of real physical exchanges, not only strike strings.

Test/add a restrained set of useful conversions where they fit the existing controls and character identities:

- short grab/throw;
- wrist/arm catch into counter;
- caught kick into sweep/counter;
- wall conversion;
- aerial intercept/slam.

Do not create canned ten-second grab cinematics. These should be short combat verbs with clear counterplay and transitions.

### G. Arena and movement are combat verbs

Keep integrating walls, height, distance and obstacles into the exchange.

The desired range flow is:

`long-range probing → run/reposition → tools → mid-range decision → taijutsu → wall/air conversion → recovery/reset`.

The arena should create reasons to sprint, flank, pursue, wall-run and choose angles instead of causing both players to circle at the center.

### H. Preserve simplicity at the input level

Do **not** solve this by adding a button for every mechanic.

Depth should come from:

- context;
- direction;
- timing;
- current state;
- held/equipped tool;
- air/wall situation;
- character-specific interpretation.

The long-term philosophy remains:

**Storm gives actions; Ninja Duel should increasingly give systems the player combines.**

For each fighter, aim for a small number of understandable combat verbs that can produce many routes rather than 20 disconnected techniques.

### I. Character identity through the same systems

The universal layers must not make the four fighters converge toward the same playstyle.

**Minato:** speed, preparation, marked kunai, spatial network, angle changes, precision punish, rapid pursuit.

**Itachi:** calm control, shuriken geometry, fire, deception, substitution/read-based defense, forcing predictable responses and punishing them.

**Neji:** compact precision, Gentle Fist logic, circular footwork, deflection/counterplay, close-range chakra-control identity, little wasted motion.

**Sasuke:** aggressive Uchiha pressure, acrobatic taijutsu, shuriken/kunai tools, fire, early Sharingan-style reads, forward-driving transitions.

When several fighters use the same common mechanic, their timing, stance, route and conversion should still communicate who they are.

### J. Scope discipline

This is an enrichment of the existing final-pass mission, **not permission to restart architecture or build a giant generic framework before improving the game**.

Implement the highest-value pieces that make the **four-character core** visibly richer now. Reuse existing systems. Prototype in Studio, keep what improves the fights, reject what adds complexity without fun/readability.

A successful 30-second fight should contain interesting decisions even during seconds where nobody is trapped in a full combo.

---

# 6. Real Minato kunai

This is non-negotiable.

Minato needs a convincing **real 3D kunai**, not an image, debug block or placeholder-looking primitive.

It must:

- sit correctly in his hand;
- be held with a believable grip;
- be thrown by an actual arm/body animation;
- leave the hand at the correct animation frame;
- travel as a real world projectile;
- have appropriate speed and trajectory;
- orient/spin correctly;
- collide/read impacts cleanly;
- support the marked-kunai gameplay;
- remain visually readable at combat speed.

A core desired sequence is:

`throw marked kunai → it travels across the arena → Minato keeps moving → teleport to its location → immediately continue the attack from the new angle`.

This sequence should feel fast, intentional and impressive.

---

# 7. Real Itachi shuriken

Same quality requirement for Itachi.

His shuriken attacks need:

- believable draw/release animation;
- real 3D projectiles;
- proper orientation/spin;
- fast readable trajectories;
- impact feedback;
- useful integration into his combo/control game.

His motion should feel controlled and precise, not simply like a slower Minato.

---

# 8. Fireball / fire jutsu must become a real technique

The current fire presentation should be pushed substantially further.

Create a convincing fire technique with:

- clear body/hand-sign or cast startup where appropriate;
- emission from the character rather than a detached visual;
- significantly better travel distance;
- useful speed;
- three-dimensional volume;
- trails/particles appropriate to fire;
- strong but readable impact;
- environmental light/heat presence if it improves the effect without excessive cost;
- sound hooks;
- correct gameplay hit timing.

It should not look like an orange sphere, flat image, or temporary debug effect.

It should begin to evoke an actual Katon-style anime technique.

This system should support both Itachi and Sasuke without making their fire usage identical.

---

# 9. Minato must have a stronger visual identity

Minato should instantly communicate:

- speed;
- precision;
- marked kunai;
- teleportation;
- angle changes;
- instant punishment.

Improve his visual signature with restrained but polished effects such as:

- speed trails;
- brief chakra/energy aura;
- flashes at teleport entry/exit;
- subtle displacement/distortion cues;
- mark feedback;
- very fast movement accents.

Do not cover him in a huge permanent glow. His identity should primarily come from movement and timing.

His teleports must feel like deliberate combat actions, not `HumanoidRootPart` coordinate changes.

---

# 10. Itachi must have a distinct identity

Itachi should communicate:

- calm control;
- precision;
- shuriken pressure;
- fire;
- deception;
- mirage/substitution-style reads;
- punishment of predictable approaches.

Strengthen his visual and gameplay language without simply making everything red.

He should create moments where an opponent is unsure whether engaging immediately is correct.

---

# 10B. Neji must validate the precision/counter side of the combat engine

Neji is not a side prototype anymore. Treat him as one of the four current playable fighters.

He should communicate:

- Gentle Fist precision;
- circular movement and controlled angles;
- short, efficient palm strikes;
- perception/read-based defense;
- deflection/counter identity;
- chakra-point disruption style through states and consequences rather than oversized VFX.

His gameplay is an important test: if the engine only feels good with teleports, projectiles and flashy effects, the underlying taijutsu system is not good enough.

---

# 10C. Sasuke must validate aggressive mixed-range Uchiha combat

Sasuke is one of the four current playable fighters and should not be deferred as future content.

He should communicate:

- aggressive forward pressure;
- acrobatic taijutsu;
- sharp kicks and angle changes;
- shuriken/kunai integration;
- fire as a route/space-control tool rather than an isolated cooldown;
- early Sharingan-style reads where already supported;
- a more impulsive and attacking rhythm than Itachi.

Shared Uchiha systems must not make Sasuke feel like a younger recolor of Itachi.

---

# 11. Camera pass

The camera needs to feel appropriate for a fast Naruto-like duel.

Test and improve it in Roblox Studio for:

- ground combat;
- dashes;
- teleportation;
- launcher;
- chase;
- aerial combo;
- slam;
- walls;
- different arena heights;
- projectiles and jutsu.

It must preserve orientation and readability during rapid movement.

Use stronger camera treatment only for meaningful moments. Avoid constant shake or excessive FOV pumping.

The camera must remain readable not only for Minato teleport routes but also for Neji close-range circular exchanges and Sasuke's faster mixed-range pressure.

---

# 12. Arena / Naruto vibe

Improve the current arena rather than replacing it blindly.

Push it toward a convincing anime ninja duel location using what is appropriate:

- terrain variation;
- rocks;
- trees/vegetation;
- walls/structures;
- training-ground details;
- elevation changes;
- readable traversal paths;
- lighting;
- sky;
- atmosphere;
- color correction;
- dust/wind ambience.

The arena must also remain gameplay-useful for:

- wall movement;
- teleports;
- projectiles;
- vertical combat;
- line-of-sight decisions.

Avoid a generic Battlegrounds flat box.

---

# 13. Overall Naruto/anime rendering direction

The whole presentation should move toward:

**fast anime ninja combat, strong silhouettes, readable effects, energetic attacks and a recognizable Naruto-like fantasy**.

Polish where useful:

- Lighting;
- Atmosphere;
- ColorCorrection;
- trails;
- particles;
- dust;
- impact effects;
- teleport cues;
- jutsu presentation;
- contact feedback.

Do not bury the fighters under VFX. Clarity remains essential.

---

# 14. Game feel

Tune the things that make the game feel responsive rather than merely functional:

- startup;
- active timing;
- recovery;
- movement responsiveness;
- input buffering;
- combo windows;
- knockback;
- impact reactions;
- hitstop hierarchy;
- camera response;
- VFX/SFX timing.

Fast attacks should feel fast. Heavy attacks should feel heavy.

The shared game-feel layer should support four different rhythms rather than one universal timing profile.

---

# 15. Testing requirements

Run automated tests after relevant code changes, but also perform real Studio testing repeatedly.

At minimum validate full routes for **all four current characters**.

## Minato

- run/strafe/jump/wall movement;
- melee string;
- launcher/chase/aerial route;
- kunai in-hand/throw transitions;
- marked kunai teleport;
- immediate follow-up after teleport;
- tool → movement → melee conversion;
- defense/deflect/dodge/recovery;
- at least one contested/clash or counter situation where supported;
- jutsu.

## Itachi

- movement;
- melee string;
- launcher/aerial route;
- shuriken integrated into neutral/pressure rather than only isolated use;
- fireball;
- mirage/deception tools;
- defense/deflect/dodge/recovery;
- at least one counter/forced-reaction route;
- disengage/reposition.

## Neji

- movement/stance/circular repositioning;
- compact melee route;
- palm-strike transitions;
- launcher or appropriate vertical conversion if supported;
- deflect/counter flow;
- close-range pressure without relying on projectiles;
- at least one state-change route that reads as Gentle Fist/chakra-point style combat;
- recovery and defensive reset.

## Sasuke

- movement and aggressive approach;
- melee string with distinct kicks/body rhythm;
- launcher/chase/aerial route;
- shuriken/kunai integration;
- fire integration into an actual route;
- defensive/read response where supported;
- tool → taijutsu or taijutsu → tool conversion;
- disengage/re-entry.

Also validate several **neutral-to-combat exchanges with different matchups**, not only Minato vs Itachi. At minimum test examples involving Neji and Sasuke so the shared system is not accidentally tuned around two characters.

The interesting gameplay should happen before a full combo starts: spacing, approach, tool use, dodge/deflect, counter, pursuit and reset.

Play multiple full fights.

Also watch at least one full fight while deliberately ignoring the HUD and judge whether the action itself communicates what is happening.

Do not call the pass finished until the visual result is meaningfully better than the starting build.

---

# 16. Priorities if tradeoffs are required

1. Combat bugs / jump / aerial combo reliability across the four-character core
2. Animation and body-motion quality
3. Make neutral/defense/counterplay interesting between combos
4. Make Minato, Itachi, Neji and Sasuke visibly and mechanically distinct
5. Real Minato kunai + marked-kunai combat integration
6. Real Itachi/Sasuke projectile-tool integration where appropriate
7. Highest-value clash/grab/state/weapon interactions that improve the current fights
8. Fireball and major jutsu presentation
9. Neji precision/counter identity and Sasuke aggressive mixed-range identity
10. Ninja Storm + supplied-reference combat flow
11. Camera
12. Arena / Naruto atmosphere
13. General polish

Prioritize what the player can **see and feel** over speculative refactors.

---

# 17. Do not restart the foundations

The project already has substantial systems for:

- combat;
- movement;
- networking;
- Minato;
- Itachi;
- Neji;
- Sasuke;
- AI;
- camera;
- arena;
- procedural presentation;
- testing;
- build generation.

Reuse them.

Refactor only when a concrete problem justifies it.

Do not spend the mission creating a new generic combat framework.

---

# 18. Final quality bar

The target is not simply "all tests pass".

The target is that a 20–30 second clip involving **any of the four current fighters** begins to look like an actual game somebody would want to try.

We should visibly see:

- fighters running and turning naturally;
- arms and legs driving attacks;
- convincing melee strings;
- meaningful neutral/spacing/defensive decisions between strings;
- tools/weapons bridging range and melee instead of behaving like detached cooldown abilities;
- at least some contested contact/counterplay rather than every first touch becoming a guaranteed sequence;
- launchers and aerial pursuit that do not bug;
- Minato's kunai feeding his spatial game;
- Itachi's shuriken feeding his pressure/control game;
- Neji's body mechanics and precision carrying his identity without needing huge VFX;
- Sasuke mixing aggressive taijutsu, tools and fire without feeling like Itachi;
- proper impacts and reactions;
- better camera framing;
- a more Naruto-like arena and atmosphere;
- faster, smoother, more anime-like flow.

Before: **Roblox combat prototype.**

After: **first convincing four-character Naruto-like vertical slice with a real combat language between the combos.**

---

# 19. Deliverable

On completion:

1. ensure everything is committed on `claude/minato-itachi-final`;
2. push the branch to GitHub;
3. provide the final commit hash;
4. identify the exact `.rbxlx` to open;
5. provide the current controls;
6. summarize the major visible/gameplay changes;
7. list remaining known issues honestly;
8. state what still separates this build from a publishable alpha.

Do not leave meaningful work only on the local machine.
