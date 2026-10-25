# NEXT MISSION — NINJA EMBODIMENT / FREEDOM OVERHAUL / NEAR-FINAL GAME PASS

**Status: ACTIVE / SUPERSEDES ANY SMALL FOLLOW-UP PASS**

Start from the current real HEAD of `claude/ninja-duel-2026-10-14` (`a921c9b` at mission creation time; re-check before coding).

The previous convergence work is useful and must be preserved. It fixed visible seams, body penetration, substitution presentation, wall turns, air spacing, running strikes and continuity. **Do not spend the next mission doing another small combat-convergence pass.**

This mission must change what the game IS.

The current build is too repetitive because too many fighters still collapse back into the same hidden grammar:

`Light1 -> Light2 -> Light3 -> Heavy/Launcher -> Pursuit -> Air1/Air2 -> Slam + technique slots`

Even when the animations, timings and VFX differ, too much of the fight can still be read as high-level boxing / acrobatic melee with powers added on top.

That is no longer acceptable.

## Product thesis

> **The player does not select a fighter and execute a moveset. For three minutes, the player becomes that ninja.**

The ninja is a body, chakra reserve, perception model, movement capability, physical tools, persistent world interactions, elemental properties, defensive instincts and exceptional abilities.

The player should constantly ask:

> **What can I do with what this ninja is capable of right now?**

not:

> **Which combo or cooldown is available?**

### Hard quality target

After this mission, taking Sasuke, Minato, Kimimaro, Gaara, Haku, Zabuza or another sufficiently developed fighter for a 3-minute free fight should feel like being handed an exceptional supernatural body and a set of physical powers with which the player can improvise.

If the best way to play is still mainly `land opener -> watch 3–8 guaranteed hits -> repeat`, the mission FAILS.

If removing the names/VFX would make a 30-second fight plausibly look like two acrobatic MMA fighters, the mission FAILS.

---

# 1. FIRST: AUDIT THE REAL CURRENT GAME, NOT THE DESIGN DOCS

Before implementation, inspect the current HEAD and run real Studio fights.

Do not infer quality from tests or comments.

Audit at least:
- `BanglaCombo` / the 3-light-string foundation;
- `Attacks` and `RosterMoves`;
- `Brawler`, `Combat`, `Motor`, defense, pursuit and reactions;
- `Input` and control budget;
- `Fighters`, `Wave1..4`, character bibles and motion modules;
- `ChakraCombat`, `ChakraRules`, `ChakraTuning`, `Elements`;
- tools/projectiles/wires/seals/bodies/zones;
- World/arena geometry and material handling;
- current online combat path so the new systems remain multiplayer-authoritative.

Run free fights with full chakra and techniques. Observe at least:
- Sasuke vs Minato;
- Sasuke vs Kimimaro;
- Kimimaro vs Haku;
- Gaara vs Lee;
- Zabuza vs Itachi.

For each pairing, record:
1. how many distinct meaningful decisions occur in 30 s;
2. how often the attacker owns control for >1.2 s without a defender decision;
3. how often combat resolves into the same string grammar;
4. how often the environment matters;
5. how often chakra changes an action rather than merely paying a jutsu cost;
6. how often a character-specific power persists in the world or changes future decisions;
7. whether the fighter still feels supernatural with large VFX disabled.

Do not continue until the repetition sources are written down concretely.

---

# 2. BREAK THE DEPENDENCE ON `LIGHT1 -> LIGHT2 -> LIGHT3`

Do NOT simply delete light attacks.

Redefine the meaning of the basic attack input.

The basic attack should mean:

> **attack from the body's current situation**

not:

> **advance the universal combo counter**.

Build a contextual strike/action resolver using, when relevant:
- current velocity;
- relative angle to opponent;
- distance;
- grounded / airborne / wall-supported state;
- ascent / descent;
- active weapon/body form;
- current momentum;
- opponent posture;
- support foot / locomotion phase where useful;
- environment proximity;
- current fighter capability.

The same input may produce different legitimate attacks because the situation differs.

Examples:
- sprinting Sasuke attack != stationary Sasuke attack;
- Sasuke descending attack != wall-exit attack;
- Kimimaro with Camellia bone blade != bare-body Kimimaro;
- Minato arriving from FTG != Minato standing at neutral;
- Zabuza with full cleaver momentum != close-range hilt strike.

Preserve readability and competitive determinism. This is contextual authorship, not random animation selection.

A three-hit sequence may still emerge when appropriate, but the engine must stop making it the dominant universal skeleton.

---

# 3. RETURN AGENCY TO THE DEFENDER

Reduce the amount of time a defender is only watching.

Normal hits should create advantage, not automatically guarantee a long cutscene-like sequence.

Add / improve where appropriate:
- directional hit recovery;
- guard recovery windows;
- recoverable stumbles;
- air drift / defensive influence when not in a true launcher lock;
- wall recoveries;
- tech/roll/landing choices;
- substitution timing as a real decision;
- disengage options;
- whiff punish windows;
- reorientation after side swaps.

Keep truly earned conversions:
- a hard read;
- counter;
- guard break;
- clean launcher;
- trap;
- bind;
- strong wall conversion;
- resource-spending setup.

But a regular jab should not casually lead to a long guaranteed cinematic route.

### Target

A good attacker should repeatedly need to read the defender again.

Combat rhythm should become:

`threat -> response -> adaptation -> contact -> reaction -> new decision`

rather than:

`opening -> predetermined string -> reset`.

---

# 4. CHAKRA BECOMES A UNIVERSAL NINJA RESOURCE

The project already contains the right seed in `ChakraCombat`:

`OBJECT / BODY ACTION + CHAKRA + NATURE / MASTERY + CONTEXT = MODIFIED ACTION`

Expand this philosophy beyond `chakra + tool`.

Chakra must become the resource for doing things an ordinary human cannot do.

Implement a coherent, bounded foundation for at least these families:

## Movement chakra
- burst acceleration / chakra step;
- stronger directional jump where justified;
- wall adhesion / maintenance;
- extraordinary wall exit;
- controlled aerial correction where fighter mastery allows it.

Do not make normal traversal permanently consume chakra if it ruins flow. Use design judgment. The important part is that exceptional movement can become an intentional resource decision.

## Body chakra
- reinforced strike / palm where fighter mastery supports it;
- specific body states (Gentle Fist, gates, bone armour, etc.);
- contextual recovery or impact resistance only where fiction and balance support it.

## Object chakra
Preserve and expand the current infusion system:
- kunai;
- shuriken;
- wire;
- planted metal;
- character-specific projectiles;
- elemental conduction / interaction.

## Sustained chakra
Some powers should cost over time or depend on maintaining an active state rather than only one button press.

Examples to consider:
- perception modes;
- powerful body states;
- persistent barriers/constructs;
- certain movement/power continuations.

### Input rule

Do not explode the control scheme into 25 buttons.

Use:
- press / hold / release;
- chakra modifier;
- direction;
- current context;
- existing compact controls.

The player should learn a small language with many consequences.

---

# 5. CONVERT SIGNATURE TECHNIQUES FROM SLOTS INTO CAPABILITIES

A technique should not always be a self-contained animation packet.

When fiction supports it, split techniques into:

`prepare / create state -> player controls body/object -> world interaction -> release/end`

## Sasuke — Chidori vertical slice

Current Chidori is still mostly channel -> thrust.

Turn it into a real charged physical state.

Required feel:
- Sasuke forms Chidori;
- lightning exists visibly on the hand;
- he can move with it for a short bounded period;
- sprint/ground approach works;
- jump/air descent can produce a valid contextual use;
- wall-exit use is possible if physically coherent;
- small steering exists but the commitment remains punishable;
- a miss is a real miss with momentum/recovery;
- collision is not player-only;
- hitting valid destructible world geometry creates a real world consequence;
- hitting a fighter produces an appropriate unique contact/reaction;
- guard / dodge / counterplay remains readable.

Do not turn it into free omnidirectional homing.

## Minato — FTG as spatial authorship

Minato must increasingly play through a network of actual anchors and remembered space.

Required direction:
- marked kunai remain physically meaningful;
- planted/embedded/recoverable states are coherent;
- teleport destinations are world facts, not UI abstractions;
- movement + throw + placement + feint + arrival can be combined freely;
- teleport does not automatically grant the next hit;
- arrivals inherit believable orientation/momentum where appropriate;
- a Minato fight should visibly reshape the map into his network over time.

## Kimimaro — body as arsenal

Stop treating Camellia/Larch/Willow only as three cooldown slots.

Required direction:
- bones can exist as body/weapon states;
- a produced bone blade can remain equipped for a meaningful period;
- current bone state changes contextual melee;
- finger bones/projectiles feel like a body capability, not reskinned kunai;
- defensive bone use is possible where balanced;
- Larch/body-spike behavior interacts with proximity and space;
- temporary bone remains / spikes may affect the immediate battlefield where safe;
- transitions into/out of bone states are physical and readable.

These three fighters are the mandatory first vertical slices because they stress three different systems:
- spatial anchors;
- charged elemental body state;
- morphing biological weapon state.

---

# 6. REACTIVE WORLD / MATERIAL SYSTEM

The current arena is mostly static. That must change.

Do NOT build a voxel destruction engine.

Build a performant deterministic reaction layer with material + durability tiers.

At minimum, support categories equivalent to:

## Decorative / fragile
Small props, light barriers, minor branches, etc.
- break / scatter easily;
- cosmetic gameplay consequence only unless explicitly authored.

## Breakable combat geometry
Rocks, selected pillars, selected wall panels, trunks, arena props.
- authored integrity;
- intact -> damaged/fissured -> broken states;
- server-authoritative state;
- predictable collision update;
- replicated visual result.

## Structural geometry
Important arena boundaries / core geometry.
- does not disappear;
- can receive scorch marks, cuts, cracks, dust, impact decals/effects.

## Materials
At least establish reactions for:
- stone;
- earth;
- wood;
- metal;
- structural concrete/wall.

Potential interaction grammar:
- lightning / Chidori + stone -> crack / debris / break if threshold met;
- heavy body impact + weak pillar -> damage/break;
- fire + wood -> burn/scorch / eventual authored break if intended;
- kunai + wood -> embed;
- kunai + hard stone -> spark/ricochet/drop;
- lightning + metal/wire -> conduction through existing chakra rules;
- slam + earth -> crater/impact scar;
- slash + surface -> cut mark;
- body launched into wall -> wall-specific impact state.

### Critical design rule

Environment reactions must be consequences of the same combat event that would affect a fighter. Do not fake destruction with unrelated button-specific VFX.

---

# 7. THE ARENA MUST REMEMBER THE FIGHT

At the start: clean arena.

After 2–3 minutes, the battlefield should visibly tell the story of the match.

Possible persistent/temporary evidence:
- Minato anchors / embedded marked kunai;
- cracked/broken rocks;
- Chidori scars;
- burn lanes and scorch marks;
- broken props;
- impact craters;
- Haku ice traces/mirrors;
- Kimimaro bone remains/spikes;
- Gaara sand structures/marks;
- wire/trap remnants where gameplay requires them;
- wall impact damage.

Bound the count/lifetime for performance, but do not erase everything immediately.

The world must stop feeling indifferent to superhuman violence.

---

# 8. PERCEPTION IS A GAMEPLAY SYSTEM

Do not represent ocular/perception powers only as numeric windows.

Build a reusable perception layer so powers may change what information the player receives.

## Sharingan direction
Possible readable effects, balanced carefully:
- high-speed movement leaves more useful temporal information;
- attack preparation cues become more legible;
- projectile trajectories are easier to parse;
- certain feints/clones expose subtle tells;
- rapid angle changes remain readable without slowing the opponent globally.

## Byakugan direction
Different identity:
- broad awareness;
- chakra-point/body information;
- reduced deception from clone/visual tricks where canonically coherent;
- spatial awareness through specific occlusion conditions only if gameplay remains fair.

Do NOT create wallhacks that destroy competitive play.

Perception should make the player *feel* the ability through information design.

---

# 9. CHARACTER COMPLETION CONTRACT — REDEFINE `FINISHED`

A fighter is no longer considered finished because it has:

`stance + M1s + directional routes + tool + 3 techniques + awakening`.

For every production fighter, define and eventually implement enough answers to:

1. **Body** — what can this body do that others cannot?
2. **Chakra** — how does this ninja use chakra differently?
3. **Movement** — how do they traverse/reposition differently?
4. **Objects** — what can they create, carry, plant, retrieve or transform?
5. **Environment** — how do their abilities affect space/materials?
6. **Perception** — do they read the battlefield differently?
7. **Defense** — how do they survive/counter differently?
8. **Persistence** — what consequences remain after the action?
9. **Improvisation** — what systems can combine without a scripted combo entry?
10. **Counterplay** — how does an opponent understand and answer them?

If several answers are generic, the fighter is unfinished.

Do not attempt to perfect all 20 at once before the new engine proves itself.

First prove the new contract strongly on:
- Sasuke;
- Minato;
- Kimimaro.

Then port the foundation to additional contrasting fighters in this mission where practical:
- Gaara;
- Haku;
- Zabuza;
- Lee;
- Itachi.

Do not leave obviously unfinished roster characters falsely labelled final.

---

# 10. FIGHTER-SPECIFIC FREEDOM TARGETS

## Sasuke
Must feel like:
- agile taijutsu;
- free shuriken use;
- wire as actual spatial setup;
- fire creating pressure/space;
- Sharingan affecting perception;
- Chidori as a dangerous controlled physical state;
- lightning interacting with conductors/world;
- player can choose aggression, setup or punish.

## Minato
Must feel like:
- absurd but readable speed;
- precise kunai use;
- battlefield anchor network;
- optional disengagement/reposition instead of guaranteed offense;
- routes emerge from placement choices.

## Kimimaro
Must feel like:
- the body is the weapon system;
- bones appear where actions require them;
- can switch between body/bone weapon behaviors;
- defense/offense blur through Shikotsumyaku;
- no generic boxer feel between cooldowns.

## Gaara
Direction:
- sand has autonomous/persistent spatial presence;
- defense is not just a hidden charge number;
- sand can become cover/control/attack medium;
- Gaara's body should not need to box like everyone else.

## Haku
Direction:
- senbon precision;
- ice movement;
- mirrors create spatial network / trajectory possibilities;
- fight becomes about angles and information.

## Zabuza
Direction:
- enormous physical weapon commitment;
- mist changes information and navigation;
- heavy impacts interact with props/walls;
- close hilt/handle behavior differs from long-edge behavior.

## Lee
Direction:
- no jutsu disguise: pure impossible physical mastery;
- speed/momentum/body mechanics must alone pass the supernatural test;
- gates fundamentally change locomotion/body consequence, not only multipliers.

## Itachi
Direction:
- calm information control;
- real projectile geometry;
- deception affecting decisions;
- fire and perception combine without turning every exchange into a preset combo.

---

# 11. THE BOXER TEST — HARD GATE

For every fighter tested, record at least 30 seconds with large identity VFX reduced/disabled where possible.

Ask:

> **Could this still plausibly be two elite real-life fighters with flashy overlays?**

If YES -> FAIL.

Expected signatures even with reduced VFX:
- Minato: impossible space control + anchor geometry;
- Sasuke: tools/wire/perception/charged lightning mobility;
- Kimimaro: body-generated weapon transformations;
- Gaara: sand fighting as a medium;
- Haku: ice/senbon/mirror spatial control;
- Zabuza: cleaver physics + mist information warfare;
- Lee: visibly superhuman momentum and body mastery.

---

# 12. THE 3-MINUTE FREEDOM TEST — HARD GATE

For the vertical-slice fighters, run 3-minute free fights.

The player/AI should not be forced to repeat the same optimal route every opening.

Track roughly:
- distinct attack contexts used;
- tools used outside combo cancels;
- environment interactions;
- defensive recoveries;
- chakra decisions;
- persistent setup objects;
- missed attacks with real consequences;
- wall/air/ground transitions;
- technique uses that are not identical executions.

### Acceptance

At least Sasuke, Minato and Kimimaro must each support multiple visibly different valid strategies over three minutes.

Not just different combos — different *plans*.

---

# 13. ONLINE / AUTHORITY MUST SURVIVE THE OVERHAUL

Do not build these systems as local visual toys.

Preserve:
- server-authoritative hits/state/resource use;
- validated inputs;
- deterministic breakable world state;
- per-player online ownership rules;
- projectile/tool authority;
- current anti-cheat invariants;
- confirmed-hit correctness.

Where responsiveness needs prediction, use bounded client presentation and reconciliation rather than moving authority client-side.

The current online foundation remains important: the long-term product is a large online tournament where each player embodies their chosen fighter.

Do not build the full global tournament service in this mission unless core gameplay reaches the target early. The combat experience is the blocker right now.

---

# 14. NEAR-FINAL GAME FEEL, NOT A TECH DEMO

This mission should leave the project feeling much closer to a real release candidate combat game.

In addition to the systemic changes above, close obvious production gaps encountered on the way:
- broken/placeholder transitions;
- unfinished major fighter actions in the tested roster;
- obvious foot sliding during final interactions;
- object clipping/teleporting;
- camera failures created by new freedom;
- world-reaction desync;
- VFX that are detached from body/world source;
- impossible body penetration;
- unresponsive input chains;
- bad reset-to-neutral seams;
- leftover 0.4 s artificial air hover if still present;
- high-speed readability problems.

Do not spend days polishing menu cosmetics while combat is incomplete.

---

# 15. DO NOT SOLVE THIS BY ADDING MORE COOLDOWN BUTTONS

Forbidden shortcut:

> "The user wants more variety, so give everyone 7 jutsu."

That would make the UI busier while preserving the same repetitive engine.

Variety must come mainly from:

`body + context + movement + chakra + object + environment + perception + opponent state`

A small number of deep abilities is better than many isolated casts.

---

# 16. DO NOT SCRIPT A 3-MINUTE ANIME CUTSCENE

Another forbidden shortcut:
- giant canned combo chains;
- excessive homing;
- attacker rails;
- auto-follow choreography;
- uninteractive cinematics;
- fake freedom created by many authored branches that all lock the opponent.

The goal is **player-authored fights**.

Character-authored abilities, player-authored sequence.

A good player should sometimes create a strong sequence that was not explicitly authored as `Combo #17`.

---

# 17. STUDIO WORKFLOW

This mission is impossible to validate headlessly only.

Use repeated Studio loops:

`play -> record -> inspect normal speed -> inspect 0.5x / frame-sensitive moments -> identify seam/repetition -> change -> replay`

Required visual checkpoints:
1. Sasuke Chidori into opponent / miss / breakable stone;
2. Minato 30–60 s anchor network fight;
3. Kimimaro 30–60 s body-weapon fight;
4. destructible/reactive arena under real free fight;
5. defender escaping/recovering from ordinary pressure;
6. two fighters using the same basic attack input from multiple contexts;
7. online-compatible state snapshots for new persistent objects/world damage;
8. 3-minute free fight for each vertical-slice fighter.

Do not call something PASS because a debug command triggered it once.

---

# 18. PERFORMANCE BOUNDS

Freedom cannot destroy Roblox performance.

Design explicit caps for:
- persistent projectiles/anchors;
- decals/scars;
- debris;
- breakable parts;
- bone/ice/sand remnants;
- hazards/zones;
- physics fragments;
- network replication frequency.

Prefer authored pooled debris / state swaps over uncontrolled physics spam.

The arena should look increasingly damaged without becoming a network disaster.

---

# 19. EXECUTION ORDER

Use this order unless direct Studio evidence proves a better dependency order:

1. audit current free-fight repetition and document it;
2. close only blockers from the current convergence work;
3. contextual basic-action resolver / reduce universal string dominance;
4. defender agency / shorter ordinary lockouts;
5. chakra-as-universal-resource foundation;
6. reactive materials/world foundation;
7. Sasuke full vertical slice (Chidori + tools/wire/perception + world);
8. Minato full vertical slice (anchors/objects/free FTG spatial play);
9. Kimimaro full vertical slice (body weapon state / bones / world);
10. generalize shared primitives;
11. port to Gaara/Haku/Zabuza/Lee/Itachi as far as can be completed cleanly;
12. 3-minute Studio fights + Boxer Test;
13. online regression / authority / performance tests;
14. final polish only on visible blockers;
15. update active docs truthfully.

Do not stop after step 3 or 4 and call this mission complete.

---

# 20. ACCEPTANCE CRITERIA

This mission is complete only when all of the following are true:

### Core freedom
- basic combat is no longer dominated by the universal three-hit grammar;
- the defender frequently makes decisions during normal exchanges;
- whiffs, overshoots and recovery are real;
- movement / wall / air context changes actions naturally.

### Chakra
- chakra meaningfully modifies more than jutsu/tool cost;
- at least one movement use, one body use and one object use are real and player-visible;
- chakra decisions create tradeoffs.

### World
- at least several arena objects/materials react persistently to combat;
- Chidori can damage appropriate world geometry;
- strong impacts can mark/break authored structures;
- tools can meaningfully embed/ricochet where appropriate;
- arena visibly remembers a fight.

### Characters
- Sasuke, Minato and Kimimaro pass the 3-minute freedom test;
- their strongest identity is systemic, not just VFX;
- they support multiple plans, not merely multiple strings;
- additional fighters inherit the new systems without becoming clones.

### Feel
- no obvious body/object seam undermines the fantasy;
- superhuman power is visible even with reduced VFX;
- high-speed actions remain readable;
- ordinary combat does not feel like boxing with Naruto skins.

### Technical
- server authority preserved;
- normal/debug/QA builds work;
- existing regressions fixed rather than silenced;
- online foundation still functions at architecture/test level;
- performance caps documented and enforced.

---

# 21. FINAL DELIVERABLE

At the end, provide:
- final HEAD SHA;
- before/after description of what the game *is*, not only changed files;
- current 3-minute freedom verdict for Sasuke/Minato/Kimimaro;
- Boxer Test verdict per tested fighter;
- environment reaction matrix;
- chakra action matrix;
- defender-agency changes;
- which old universal combo assumptions were removed/reduced;
- Studio evidence / fights run;
- performance limits;
- online regression status;
- incomplete fighters honestly labelled incomplete;
- only the few remaining blockers between this build and a true release candidate combat core.

### Final question you must answer truthfully

> **If a new player picks Sasuke, Minato or Kimimaro for three minutes, will they now feel that they temporarily became an exceptional ninja with extraordinary physical capabilities — or are they still mostly operating a fighting-game moveset?**

If the truthful answer is still the second one, continue working.

---

# 22. NORTH STAR

> **We are not making Storm inside Roblox.**
>
> **We are not making a boxer with Naruto VFX.**
>
> **We are building a competitive ninja combat simulation where the fighter defines the capabilities, but the player authors the fight.**

The tournament is the long-term purpose.

The freedom to truly inhabit the ninja is the product.

This mission should be the biggest gameplay leap the project has made so far.