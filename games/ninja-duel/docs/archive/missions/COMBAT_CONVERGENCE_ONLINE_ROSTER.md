# NINJA DUEL — COMBAT CONVERGENCE, ONLINE FOUNDATION & ROSTER EXPANSION

Work from the current remote HEAD on `claude/ninja-duel-2026-10-14`.
Do not restart from an old branch and do not discard valid technical fixes already completed.

The current project already has CORE4 playable foundations (Minato, Itachi, Neji, Sasuke), locomotion/jump/camera/animation foundations, combo grammar, air/wall states, guard/parry/substitution, projectiles and character-specific tool logic, chakra/awakening foundations, AI duel, Motion Lab, and QA/tests.

The problem is no longer “missing basic systems”. The problem is that the game still does not sufficiently FEEL like the high-level ninja fighting game we are targeting. This phase is therefore a convergence phase: systems must stop feeling like independent technical features and start behaving as one continuous combat game.

## 1. Primary product target

Target feeling:

**freedom and ninja traversal from strong Naruto-inspired Roblox games**
+
**combat continuity/readability from Naruto Storm**
+
**tool/chakra/range/pursuit ideas from Shinobi Striker**
+
**a denser, more deliberate competitive 1v1 structure**

The fight should not feel like:
`move → M1 chain → ability → cooldown → repeat`

It should feel like:
`read distance → reposition → probe → tool → evade/deflect → angle change → engage → strike exchange → counter → launcher → pursuit → air/wall conversion → substitution → disengage → neutral again`

The player must continuously make decisions.

## 2. Existing systems are not sacred

If an existing animation, locomotion behavior, combo transition, camera behavior, VFX, movement implementation, arena proportion, or tool behavior prevents the intended game feel, you may rewrite, replace, simplify, or remove it.

Do not preserve weak motion just because it already exists. Preserve working architecture when useful, avoid reckless full rewrites, and keep regression coverage where possible.

## 3. First task — visual/feel audit in Studio

The user reports:
- feet appearing to teleport slightly;
- movement happening in small visual steps;
- ground lights / VFX popping or jumping;
- combo transitions feeling discontinuous;
- running not looking enough like a combat game;
- jumps not strongly resembling the references;
- attacks still feeling too pose-based / mechanical.

Do not assume this is network lag.

Audit:
- HumanoidRootPart ownership/movement;
- Motor6D transforms;
- animation writes;
- foot IK;
- locomotion stride timing;
- acceleration/deceleration;
- render/update cadence;
- snapshot interpolation;
- VFX attachment/update logic;
- camera smoothing;
- attack transitions;
- pursuit;
- launch/slam movement.

Specifically investigate the already-noted possible `Motor.move` double integration / kinetic movement issue.

Use slow motion / frame-by-frame observation if useful.
For each snap identify:
- which system owns the transform;
- how often it updates;
- whether multiple systems write the same thing;
- whether render and simulation positions disagree;
- whether the fix should be interpolation, ownership, animation timing or physics.

Acceptance:
- no obvious foot snapping during run/sprint;
- no visible stepping during direction changes;
- combo poses connect continuously;
- VFX do not pop from one ground position to another;
- launcher/pursuit/air/wall movement feels continuous.

## 4. Use the references for real

Read and actually use:
- `GOLDEN_VISUAL_SET_READY.md`
- `VISUAL_TECHNICAL_BENCHMARK_V1.md`
- `FREE_R15_COMBAT_MOVEMENT_RESOURCES.md`

Then compare Ninja Duel directly in Studio.

Storm focus:
- combo continuity;
- pursuit;
- air transition;
- wall transition;
- character readability at speed;
- recovery into neutral;
- impact choreography.

Shinobi Striker focus:
- ninja tools integrated into neutral;
- movement-to-attack bridges;
- range closing;
- projectile pressure;
- weapon/body interaction;
- chakra/element properties.

Shindo / Shinobi Life / Shinobi Rising / Shinobi Way focus:
- traversal freedom;
- forward momentum;
- ninja movement fantasy;
- usable verticality;
- long-distance movement that still feels controllable.

You may research additional games/videos/examples if they answer a specific problem. Do not waste time gathering generic references.

## 5. Movement must look like combat movement

Refine/rebuild movement around body mechanics. The root must not visibly drag a mannequin.

Required categories:
- neutral walk;
- combat walk;
- sprint;
- forward run;
- backward retreat;
- strafe;
- strong lateral run;
- diagonal run;
- pursuit;
- quick reposition;
- direction changes;
- jump from standstill;
- running jump;
- falling;
- landing;
- wall run;
- wall recovery.

Small lateral movement = natural combat strafe.
Strong lateral input = actual lateral running, while head/upper torso maintain opponent awareness.

Body chain:
`feet → hips → torso → shoulders → arms/head`

Stride must match speed. No floating/sliding feet.
Speed should come from stride length, cadence, acceleration, posture, forward lean and restrained camera support, not just extreme WalkSpeed/FOV.

## 6. Jumps / air — preserve current fixes, push feel further

The recent jump/gravity fix is a good technical base. Do not undo it blindly.

Improve visually:
- anticipation;
- takeoff;
- horizontal momentum;
- airborne silhouette;
- air control;
- landing;
- re-entry into combat.

A forward jump should look intentionally ninja-like and useful for traversal/combat, not `Roblox jump + forward velocity`.
Preserve momentum unless gameplay requires otherwise. Heavy landing only for actual high-impact falls/slams.

## 7. Arena becomes a gameplay system

Rebuild/re-scale the Chūnin Exam arena as needed.
The current stadium must not dictate bad combat distances.

Fighters should feel relatively small compared to the environment.
The arena must support:
- long-range neutral;
- sprint/reposition;
- mid-range tool pressure;
- taijutsu engagement;
- aerial pursuit;
- wall conversion;
- disengagement.

Walls should matter without appearing in every exchange.
Use elevation, walls, limited obstacles and readable open lanes.

After rescaling, retune:
- run speed;
- sprint;
- jump distance;
- projectile speed/range;
- lock-on behavior;
- camera distance;
- AI engagement ranges.

Arena scale is allowed to invalidate old tuning.

## 8. Build a real neutral game

Neutral is the most important missing layer.
It must include:
- approach;
- retreat;
- lateral repositioning;
- feint;
- probe;
- tool use;
- projectile pressure;
- guard;
- parry / timed deflect;
- dodge;
- perfect dodge;
- counter;
- substitution;
- clash;
- reset.

The fight should have phases. Short exchanges are desirable; do not force long combos constantly.

## 9. Combo grammar — context, not button bloat

Preserve compact controls.
Depth should come from:
`movement + direction + timing + enemy state + environment + tool + defense`
not 25 buttons.

Keep contextual branches:
- neutral;
- up/launcher;
- down/slam/low;
- left/right side routes;
- air;
- wall;
- pursuit;
- grab/catch/counter.

Improve continuity between movement → strike → launcher → pursuit → air combo → wall → recover → neutral, and defense → counter.

## 10. Body reactions / impact

Every major hit should read as:
`support → weight transfer → acceleration → contact → opponent reaction → recovery`

Improve:
- head reaction;
- torso twist;
- hip displacement;
- footing loss;
- stumble;
- knockback;
- wall impact;
- launch;
- grounded recovery.

Avoid synchronized dance-like animation, pure root translation, and impact faked only by VFX.

## 11. Chakra must become systemic

Current chakra is still too close to “resource for jutsu”.
Expand toward:
`Object + Chakra Property/Nature + Context → Result`

Build generic infrastructure first.
Examples to explore:
- chakra-reinforced kunai;
- chakra-reinforced shuriken;
- wind-enhanced cutting projectile;
- lightning conducted through wire/metal;
- fire interaction with tags/traps/prepared zones;
- marked kunai as FTG anchor;
- projectile collision / deflection;
- embedded projectile becoming a tactical point.

Do not make every interaction a new button. Explore contextual application, active technique auto-application, hold/release, loadout/preset, or input modifier, and choose what best fits the game.

## 12. Character-specific interpretation

Shared systems must not make fighters homogeneous.

### Minato
- speed;
- precision;
- mark network;
- prepared positions;
- angle changes;
- punishment;
- movement as offense.

FTG should feel like a network of prepared destinations, not teleport spam.

### Itachi
- calm control;
- reads;
- deception;
- shuriken mastery;
- redirection;
- fire;
- substitution.

Tools should create geometry/pressure, not just damage.

### Neji
- close-space dominance;
- chakra-point disruption;
- counter-defense;
- Rotation;
- perception;
- precision.

His threat should spike inside preferred range.

### Sasuke
- aggressive hybrid;
- acrobatic taijutsu;
- Katon;
- shuriken/wire;
- Sharingan;
- Chidori;
- Curse Mark.

He should naturally chain tools, pressure and rush.

## 13. Start the real online foundation now

The game must stop being designed primarily around AI.
Build a real two-player PvP foundation.

Requirements:
- actual player-vs-player duel;
- server-authoritative combat state;
- client responsiveness;
- prediction where appropriate;
- reconciliation;
- lag-aware hit validation;
- robust projectile behavior;
- substitutions under latency;
- FTG under latency;
- air/wall interactions under latency;
- clash resolution;
- chakra/state sync.

Audit existing multiplayer-ready pieces first; do not blindly rebuild everything.
Simulate latency if possible: 0 ms, ~60 ms, ~100–120 ms, plus jitter/delay scenarios if Studio supports it.

## 14. Multiplayer game structure

Initial online structure should stay focused:
- casual 1v1;
- ranked 1v1 later/behind progression foundation;
- private/friend duel if cheap.

Keep flow fast:
`queue → character/build → fight → result → rematch/return`

No MMO lobby scope explosion.

## 15. Progression / skill point architecture

Add the foundation for fighter progression.
Each fighter has a skill tree.
Base fighter must already be fun and complete.
Progression deepens the fighter instead of repairing an incomplete kit.

Skill points may:
- mildly improve stats;
- improve existing technique properties;
- unlock combo routes;
- unlock air/wall variants;
- unlock counters;
- unlock substitution variants;
- unlock tool interactions;
- modify jutsu;
- improve awakenings.

Major nodes must create a visible gameplay difference.
Rule: **every major node should change what the player can DO or clearly SEE.**
Avoid `+2% damage` as the main progression.

## 16. Ranked point-budget system

Prepare ranked around ACTIVE skill-point budgets.
Example target formats:
- 50 SP: fundamentals-focused;
- 80 SP: stronger fighter identity;
- 100 SP: advanced builds;
- potential later 120+ SP: endgame/special.

A player may unlock far more points overall, but inside a 50 SP queue both players can only activate 50.

Core fairness principle:
**progression gives more build choices, not more allowed power inside the same ranked bracket.**

Implement architecture/configuration to support this. Full final ranked UI can wait.

## 17. AI should also use point-budget builds

Prepare coherent AI build budgets rather than stat cheating:
- beginner ~20–30 SP;
- medium ~40–50;
- hard ~60–70;
- tournament boss ~80+;
- legendary/endgame near-max.

This also becomes a balancing tool.

## 18. Expand the roster to test the engine

Four fighters are no longer enough to validate the engine.
Do not build twenty polished characters simultaneously.

Instead:
- support/design approximately 20 fighters at architecture level;
- make the next wave of distinct archetypes playable enough to stress-test the engine.

Priority archetypes:
- Naruto — clones / rush / large chakra / cloak;
- Gaara — defensive zoning / sand control;
- Rock Lee — pure taijutsu / speed;
- Kakashi — adaptive generalist;
- Temari — long-range zoning;
- Shikamaru — setup/control;
- Haku — angle/projectile/mobility;
- Kisame — heavy/chakra/large-range pressure.

Plus CORE4.
Then define the rest of the ~20 candidate roster around meaningful gameplay archetypes.
Do not add a character only because the name is popular. Every fighter should test or bend a useful system.

## 19. Character stage rule

Do not use a rigid universal age limit.
Select the most interesting young/prodigy stage before adult/endgame escalation destroys the game scale.
Stage matters more than exact age.

Examples:
- Naruto: Valley of the End Part I;
- Sasuke: Valley of the End Part I;
- Kakashi: pre-Mangekyō;
- Obito: pre-Mangekyō;
- Itachi: Mangekyō possible but restrained;
- Nagato: Rinnegan but not Six Paths of Pain;
- Shisui: mobility/read identity, no Koto spam.

Identity roots present. Adult scale absent.

## 20. Use FIGHTER_TEMPLATE as official contract

Every new fighter should define:
- identity;
- selected progression stage;
- movement;
- neutral;
- ground combos;
- air combos;
- wall conversions;
- tools;
- jutsus;
- defense;
- counter;
- substitution;
- pursuit;
- chakra;
- awakening;
- states;
- skill ceiling;
- signature mechanic.

Avoid `same M1 + 4 jutsus`.

## 21. Claude should contribute design ideas

You are not only an executor.
If you discover a better neutral mechanic, tool interaction, camera idea, progression node structure, arena mechanic, online solution, or character archetype, propose and implement it if it fits the vision, simplifies rather than bloats, improves player control/decision-making, and preserves readability.

Document substantial design deviations.
Do not ask for approval for every small improvement.
Reserve explicit user approval for major scope changes, roster replacement, fundamental control changes, or progression/monetization changes that contradict current rules.

## 22. Studio iteration rule

This phase cannot be validated only through tests.
Required workflow:
`Play → observe → compare reference → identify weakness → change → replay`

Use actual Studio whenever available.
For movement: watch 30 seconds without combat.
For combat: watch/play at least 60 seconds continuous exchange.
For PvP: test two real players/clients if possible.

For each major visual system classify:
`ACCEPT / IMPROVE / REBUILD / REJECT`

## 23. Acceptance targets

Movement: 30 seconds of movement alone should already feel like a ninja combat game.

Combat: 60 seconds of combat should naturally contain movement, tools, defense, exchanges, pursuit, air/wall conversions and disengagement.

Visual continuity: no obvious micro-snaps in feet, VFX or combo transitions.

Character identity: CORE4 should be recognizable by HOW they fight, even with reduced VFX.

Online: real two-player combat must function at acceptable latency.

Progression: skill-point budget architecture must exist and support example builds.

Roster: the engine must be tested by several additional archetypes, not only CORE4.

## 24. What not to do

Do not:
- create 20 half-finished characters with copied M1 chains;
- add dozens of buttons;
- hide weak animation under huge VFX;
- use camera shake to fake impact;
- redesign every system from scratch without reason;
- build full monetization now;
- build a huge MMO lobby;
- add unrelated game modes;
- sacrifice PvP readability for spectacle.

## 25. Deliverable

At the end provide:
- final HEAD SHA;
- concise list of major systems changed;
- what was rebuilt vs preserved;
- Studio acceptance notes;
- before/after observations;
- current PvP status;
- latency tests performed;
- current skill-point progression foundation;
- playable/defined roster status;
- systems still BLOCKED or DEFERRED;
- next recommended phase.

Also update the active project docs truthfully.
Do not mark visual/native acceptance PASS if it was not actually observed.

## Final principle

Ninja Duel should not become a pile of features.
It should increasingly feel like **a continuous, physical, tactical ninja fight where movement, tools, chakra, defense, environment and character identity all participate in the same exchange.**

If a feature exists but does not visibly improve that exchange, question whether it belongs.
