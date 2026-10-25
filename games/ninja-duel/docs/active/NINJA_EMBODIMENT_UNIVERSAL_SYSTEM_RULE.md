# NINJA EMBODIMENT — UNIVERSAL SYSTEM RULE

**Status: ACTIVE / NORMATIVE ADDENDUM TO `NEXT_MISSION_NINJA_EMBODIMENT_GAME_COMPLETION.md`**

This file exists to remove any possible ambiguity from the mission.

The Sasuke / Minato / Kimimaro examples are **NOT the scope of the overhaul**. They are only three stress tests for a universal gameplay architecture.

The actual target is:

> **Every playable ninja must feel like an exceptional supernatural being whose body, chakra, perception, tools, powers and relationship with the world create free player-authored combat.**

Do not solve this by writing a bespoke minigame for Chidori, then another bespoke minigame for Kimimaro, then another bespoke minigame for FTG.

Build reusable world and combat primitives first, then let different fighters express them differently.

---

## 1. WORLD RULES FIRST, CHARACTER EXCEPTIONS SECOND

If an interaction can logically apply to multiple fighters, it must exist as a shared system.

Examples:

- a charged body colliding with breakable stone is a shared **energy/body -> material** interaction;
- a fast body hitting a wall is a shared **momentum -> world impact** interaction;
- metal conducting lightning is a shared **element -> material/object** interaction;
- a blade embedding in wood is a shared **projectile -> material** interaction;
- fire scorching/burning a valid surface is a shared **fire -> material** interaction;
- a body being projected through fragile geometry is a shared **reaction/momentum -> destruction** interaction;
- chakra reinforcement modifying a body/object action is a shared **chakra -> action** rule;
- sustained chakra modes are a shared resource model;
- perception powers use one shared information/perception layer with different character capabilities;
- persistent anchors, traps, mirrors, sand constructs, bones, wires and zones use shared persistent-world primitives where possible.

Character code should declare **capabilities, mastery and authored identity**, not duplicate the physical laws of the world.

---

## 2. THE NEW CHARACTER MODEL

Stop thinking of a fighter as:

`basic combo + directional routes + tool + 3/4 jutsu + awakening`.

A production fighter must instead be representable as a set of capabilities over shared systems:

### BODY
- physical speed / acceleration / inertia;
- unusual anatomy or weapon-bearing states;
- strike families available from different body situations;
- unique defensive body properties;
- air / wall / ground competence;
- collision / mass / impact behavior where relevant.

### CHAKRA
- reserve / recovery;
- how chakra may modify movement;
- how it may modify body actions;
- how it may modify tools;
- elemental/nature access;
- sustained modes;
- special costs / risks.

### PERCEPTION
- what the player can perceive better/differently;
- what deception they resist;
- what information their power exposes;
- how the ability changes decision-making rather than only numeric windows.

### TOOLS / CREATED OBJECTS
- what can be carried;
- created;
- transformed;
- thrown;
- planted;
- embedded;
- retrieved;
- connected;
- destroyed;
- infused;
- left in the world.

### SPACE / ENVIRONMENT
- what surfaces can be used;
- what materials can be affected;
- what persistent geometry/state the fighter can create;
- how momentum and powers affect destructible geometry;
- how the altered arena changes future decisions.

### EXCEPTIONAL CAPABILITIES
The famous named techniques are then authored manifestations of those capabilities, not the entire character.

---

## 3. ABILITY != BUTTON SLOT

For the entire roster, identify which current techniques should remain atomic attacks and which should become reusable capabilities/states/interactions.

A technique may be:

- an instantaneous authored action;
- a state that changes what existing inputs do;
- a created object;
- a persistent zone;
- an elemental property;
- a perception mode;
- a movement capability;
- a transformation;
- a held/charged action;
- a setup that can be exploited later;
- a contextual consequence of combining existing systems.

Do not assume `Technique1..5` is the final mental model merely because the input protocol currently uses those names.

The control scheme may remain compact while the interpretation becomes richer.

---

## 4. UNIVERSAL CONTEXTUAL ACTION RESOLVER

The contextual-action philosophy must apply to **all fighters**, not only the three vertical slices.

Inputs should be interpreted through relevant state such as:

`input + body state + movement vector + support + altitude + momentum + active form/weapon + chakra intent + target state + nearby world + fighter capabilities`

This can produce different actions without randomness.

Examples across the roster:

- Lee attacks differently out of full sprint, off a wall, during descent or after a hard dodge;
- Zabuza uses edge, hilt, body weight or shortened handling depending on spacing/momentum;
- Haku can convert movement into ice-assisted approaches or senbon angles;
- Gaara should not be forced into ordinary fist strings when sand is the actual combat medium;
- Neji contextualizes body/chakra contact around range, angle and opponent state;
- Naruto's clones can become real spatial resources rather than merely combo animation helpers;
- Itachi's tools, perception and deception change his available decisions;
- Sasuke's wire/fire/lightning/body states combine through shared rules;
- Kimimaro's active bone configuration changes physical actions;
- Minato's anchors change available space.

The goal is not more animations for their own sake. The goal is that **the same input has a physically and fictionally appropriate meaning in the current situation**.

---

## 5. UNIVERSAL DEFENDER AGENCY

The reduction of guaranteed strings is a global combat rule.

Do not fix defender agency only in Sasuke/Minato/Kimimaro matchups.

Across the roster:

- ordinary hitstun must be short enough to return decisions frequently;
- true locks require an earned state: launcher, bind, guard break, trap, hard counter, wall state, major resource setup, etc.;
- airborne defenders retain bounded influence when they are not in a true lock;
- wall contacts expose recovery/tech decisions where appropriate;
- side swaps and knockbacks return orientation/control coherently;
- attackers must repeatedly reacquire/read rather than ride universal magnetic strings.

The combat engine should reward pressure and reads, not removal of the opponent's controls.

---

## 6. UNIVERSAL CHAKRA LANGUAGE

Do not implement `chakra movement` as a Sasuke feature or `chakra object` as a Minato feature.

Create one coherent chakra-action language that fighter mastery enables differently.

Shared channels may include:

- chakra + movement;
- chakra + jump;
- chakra + wall/support;
- chakra + body strike;
- chakra + defense;
- chakra + tool/object;
- chakra + element;
- chakra + sustained state;
- chakra + perception;
- chakra + created construct.

A fighter's definition says what combinations they know, how effective they are, what nature/mastery applies, and what risks/costs exist.

This is how future fighters gain depth without adding entirely new parallel engines.

---

## 7. UNIVERSAL REACTIVE WORLD

World reactions must never be authored only as `if fighter == Sasuke and move == Chidori then break rock`.

The shared world interaction layer should understand at least:

- impact energy / impulse tier;
- damage/contact type (blunt, piercing, slash, explosive, elemental, etc.);
- elemental tags;
- projectile/object material;
- world material;
- integrity/break tier;
- persistence/scar type.

Then Chidori, Rasengan, a violent Lee impact, Zabuza's cleaver, Gaara's pressure, an explosive Naruto hit or future techniques can all interact through the same rules with different authored values.

The game world should react because **something physically extraordinary happened**, not because a special-case animation requested a destruction VFX.

---

## 8. UNIVERSAL PERSISTENT BATTLEFIELD

The arena-memory principle applies to everyone.

Create reusable bounded primitives for persistent combat facts:

- embedded projectile;
- mark/anchor;
- trap/wire;
- zone;
- construct;
- temporary geometry;
- surface scar;
- broken object state;
- elemental residue;
- body-created object/remnant.

Different fighters then author different meanings:

- Minato -> anchors;
- Haku -> mirrors/ice;
- Gaara -> sand;
- Kimimaro -> bones;
- Sasuke -> wire/fire/electric interactions;
- Naruto -> clone-created spatial pressure;
- etc.

Do not build eight unrelated persistence systems when one world-state grammar can support them.

---

## 9. ROSTER-WIDE EMBODIMENT AUDIT

The mission must inspect **every target production fighter**, even if only a subset receives maximum implementation depth in the first internal pass.

For each fighter, explicitly classify:

- `EMBODIED` — already strongly satisfies the new model;
- `PARTIAL` — some unique systems exist but generic combat dominates;
- `MOVESET-BOUND` — primarily slots/routes/strings;
- `INCOMPLETE` — core fantasy/capabilities absent.

For every non-EMBODIED fighter, write the missing capability set under:

`Body / Chakra / Movement / Perception / Objects / Environment / Persistence / Defense / Improvisation / Counterplay`.

No fighter may be called final only because their three techniques and animations work.

---

## 10. VERTICAL SLICES ARE ENGINE TESTS, NOT PRODUCT SCOPE

Sasuke, Minato and Kimimaro remain mandatory because they test three very different capability families:

- Sasuke: element + charge state + tools + wire + perception;
- Minato: persistent spatial anchors + extreme movement;
- Kimimaro: body morphing + created weapons + defense.

But success on those three is **only proof that the shared engine works**.

Before mission completion, prove that the architecture also transfers cleanly to several contrasting characters, at minimum selected representatives of:

- autonomous medium/controller — Gaara;
- spatial/perception projectile fighter — Haku or Itachi;
- heavy weapon/environment impact fighter — Zabuza;
- pure body mastery — Lee;
- close-range chakra anatomy fighter — Neji;
- multi-body/clone fighter — Naruto.

The point is to prove that the engine can express the roster, not to finish three heroes and leave seventeen fighters in the old game.

---

## 11. GLOBAL BOXER TEST

Run the Boxer Test across multiple fighters, not only Sasuke/Minato/Kimimaro.

For each test, hide or mentally discount major VFX and ask:

> **Could these 30 seconds still plausibly be two elite acrobatic human fighters with decorative powers?**

If yes, FAIL.

A successful roster should produce visibly different combat grammars even before spectacle:

- Lee = impossible body mastery and momentum;
- Gaara = autonomous sand and space control;
- Minato = spatial anchor network;
- Haku = mirror/ice geometry and precision;
- Zabuza = mass, blade leverage and mist information control;
- Neji = chakra anatomy / close-space dominance;
- Naruto = multi-body improvisation;
- Kimimaro = biological weapon morphology;
- Sasuke = tool/element/perception hybrid;
- Itachi = information/deception/projectile geometry.

---

## 12. THREE-MINUTE FREEDOM TEST — GLOBAL RULE

For every sufficiently implemented fighter tested in Studio, play/watch a continuous free fight of approximately three minutes.

The question is:

> **Does the player spend three minutes improvising with an exceptional capability set, or optimizing a short move list?**

Record:

- repeated sequence frequency;
- meaningful defensive decisions;
- distinct uses of chakra;
- meaningful world interactions;
- persistent battlefield consequences;
- number of character-specific verbs used outside a guaranteed combo;
- moments not explicitly authored as a predefined combo that emerged naturally from system interaction.

The mission is successful only if emergent/systemic moments become common enough to define the fight.

---

## 13. ARCHITECTURE ACCEPTANCE RULE

At review, reject any solution that is mainly:

- giant `fighterId` switch statements;
- one custom state machine per fighter for equivalent world rules;
- bespoke destruction handlers per technique;
- bespoke chakra implementations per fighter;
- bespoke projectile physics per character when shared object rules could express them;
- duplicated perception engines;
- animation count used as a substitute for new player decisions.

Character-specific code is allowed and necessary for genuinely unique fiction.

But the rule is:

> **Build the universe once; describe what each ninja can do inside it.**

That is the real Ninja Embodiment overhaul.

---

## 14. VISUAL REFERENCE WORKFLOW — `izzyfrm/roblox-ai`

Use the public reference repository `izzyfrm/roblox-ai` as an **optional visual research library** during this mission whenever animation, VFX, UI, presentation, cinematic framing, impact readability or Roblox-specific visual implementation would benefit from concrete references.

The repository is a reference library, not code to copy and not a substitute for design judgment.

### Required workflow when a visual problem is important

1. Inspect the relevant category first, for example:
   - `animations/` for movement, run lean, dash/slide, punch/sword motion and cast timing;
   - `vfx/` for hit sparks, slash trails, speed lines, anime impact frames, fire/explosion, smoke, teleport and power-up effects;
   - `ui-styles/`, `visual-refs/`, `previews/` for HUD / menus / tournament presentation;
   - `cutscenes/` for intros, finishers and tournament presentation;
   - `game-refs/` for broader Roblox readability and visual hierarchy;
   - `roblox-docs/` for Studio-specific implementation references.
2. Select only references that actually solve the current problem.
3. State internally what principle is being extracted: timing, spacing, silhouette, anticipation, impact hierarchy, trail shape, camera framing, typography, information hierarchy, etc.
4. Build an **original Ninja Duel implementation** from those principles.
5. Validate the result in the real Studio playtest at normal speed. Do not declare success because a reference exists or because the code resembles it.

### Important restrictions

- Do not copy logos, distinctive artwork, copyrighted assets or another game's exact VFX/UI composition.
- Do not import reference media into the shipped game unless licensing explicitly allows it.
- Do not let generic Roblox references override the established Ninja Embodiment philosophy.
- Do not add visual noise merely because a reference is flashy.
- Body motion, contact, readability and player agency remain more important than effect density.

### Combat-specific use

For the current overhaul, actively consult the library where useful for:

- speed readability without hiding body motion;
- hit/impact presentation;
- dash and slide presentation;
- charged/sustained power states;
- elemental impacts;
- teleport presentation;
- destruction feedback;
- wall/ground contact feedback;
- attack anticipation/recovery silhouettes.

The target is not "make it look like a reference".

The target is:

> **Use better references so the AI stops inventing mediocre Roblox presentation from vague prompts, while preserving our own combat grammar and art direction.**

This repository is a research input. The real acceptance test remains the live game in Studio.
