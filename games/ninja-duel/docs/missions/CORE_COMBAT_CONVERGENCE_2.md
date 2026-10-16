# MISSION — NINJA DUEL
## CORE COMBAT CONVERGENCE 2
### Accessible Combos · Character Identity · Chakra Freedom · Animation & Feel

## Context

The previous pass made Ninja Duel substantially more fun. Movement, neutral, AI behavior, pursuit and some character-specific combo routes are clearly better.

However, after hands-on testing, the core combat still does not yet deliver the game we are aiming for.

The biggest remaining problem is NOT a lack of systems on paper.

The problem is that many of the existing differences, mechanics and combo routes:
- are difficult to reliably trigger;
- are not immediately understandable when playing;
- are not visually obvious enough;
- still rely too much on hidden numerical differences;
- do not yet make each fighter feel fundamentally different in the player's hands.

This mission must therefore FINISH the unfinished visible-combat work from the previous mission while preserving the good technical foundations already added.

Do NOT spend this mission expanding:
- roster;
- online feature scope;
- progression scope;
- menus;
- monetization;
- extra game modes.

Existing online/progression/roster work should remain intact, but this pass is about the actual combat that a player sees and feels.

# PRIMARY PRODUCT TARGET

The target is:

> Storm-like accessibility of execution, with much greater systemic freedom, ninja tools, chakra interactions, movement freedom and character-specific combat identity.

Storm is a reference for:
- easy-to-understand controls;
- reliable combos;
- pursuit/re-engagement;
- visual continuity;
- readable action.

Ninja Duel must NOT simply become a Storm clone.

Its own identity must come from:
- chakra as a systemic combat resource;
- ninja tools;
- elemental interactions;
- weapon/tool infusion;
- environmental freedom;
- wall and air mobility;
- contextual conversions;
- stronger fighter individuality.

# CRITICAL DESIGN PHILOSOPHY

Do NOT make the game harder by making combo execution difficult.

The skill ceiling must come from:
- decisions;
- reads;
- defense;
- substitutions;
- parries;
- dodges;
- route choice;
- baiting;
- resource use;
- re-engagement;
- positioning;
- chakra/tool interactions.

NOT from difficult button execution.

A normal player should be able to perform a character's basic and intermediate combos quickly.

A strong opponent who knows the system should be difficult to combo because they understand:
- when to substitute;
- when to guard;
- when to parry;
- when to dodge;
- which route is coming;
- where the punish window is;
- when the attacker may re-engage.

Think:
- simple offense execution;
- deep offense decisions;
- deep defense knowledge.

# PHASE 1 — FIX THE COMBO STATE / INPUT MODEL FIRST

Before adding more combo content, audit and repair the underlying combo-input behavior.

Hands-on testing currently gives situations where:
- a button pressed before actual contact appears to count toward the combo;
- the player's “first real hit” may behave like the second step;
- combo state can feel one step ahead of player intent;
- directional routes are too easy to miss;
- theoretical routes exist but are unreliable in normal play.

This is unacceptable for an accessible fighting game.

## RULE
A combo begins on the FIRST CONFIRMED HIT.

Not on:
- button press;
- startup;
- whiff;
- buffered input;
- proximity;
- attack animation beginning.

Requirements:

1. A whiff must NEVER advance the confirmed combo count.
2. Buffered presses may prepare the next attack, but must not advance combo progression until the prior hit actually connects.
3. If the previous attack misses or the string is broken, combo state must reset cleanly.
4. The player must never feel: “I thought I was on hit 1 but the game thinks I am on hit 2.”
5. Audit combo, queuedLight, buffered, chainOpen, chainAt, lastAttack, attackName, airCombo, pursuit arrival state, technique arrival state, recovery cancels.
6. Directional route recognition must be intentionally forgiving.

Current directional interpretation is too strict for the intended game.

Use an intent buffer rather than reading one exact instantaneous stick frame.

For example:
- remember a strong directional intent for a small time window;
- accept direction shortly before the attack input;
- accept direction during a short input buffer;
- prioritize the latest strong directional intent;
- avoid accidental neutral because the stick crossed a threshold for one frame.

Do NOT make this feel automated or random. It should simply understand what the player clearly tried to do.

7. Ground strings should be easy to execute.

Example philosophy:
`Light → Light → forward + Light`
should reliably produce the appropriate launcher route.

Same for:
- `Light → side + Light`
- `Light → Light → back + Light`

when those routes exist.

8. Do not require frame-perfect timing for ordinary strings.

Good rhythm may still provide:
- slightly better recovery;
- Flow bonus;
- stylistic reward.

But normal combo execution must work without mastering hidden frame windows.

# PHASE 2 — EXPAND THE COMBO GRAMMAR WITHOUT ADDING BUTTON BLOAT

The current shared grammar is a good foundation:
- light strings;
- directional branches;
- heavy;
- launcher;
- air;
- pursuit;
- tools;
- jutsu cancels.

Keep this simplicity.

Do NOT turn Ninja Duel into a technical command-list fighter.

The goal is:
few buttons,
many contextual results.

Every CORE4 fighter should end this mission with a meaningful but accessible combat graph.

Target minimum per fighter:

## GROUND
- base light string;
- forward route;
- backward/low route;
- left/right route;
- heavy-after-early-hit route;
- normal heavy;
- running/dash attack;
- tool conversion or tool branch;
- at least one jutsu conversion;
- disengage/reset option.

## AIR
- basic air string;
- drive route;
- spike route;
- side switch;
- character-specific aerial conversion;
- slam/end route.

## RE-ENGAGE
- pursuit after knockback/launch where appropriate;
- route after pursuit;
- route after wall conversion where appropriate;
- character-specific version of re-entry.

The routes must not merely exist in data.

Each route must:
- be executable consistently;
- look different;
- have a clear purpose;
- create a meaningful next decision.

Avoid:
`Light1 -> Light2 -> Light3 -> done`

as the dominant pattern.

We want:
`opening -> route choice -> conversion -> defender decision -> extension or reset`.

# PHASE 3 — UNIVERSAL RE-ENGAGE / CHAKRA DASH

The game currently needs a more natural way to rapidly close distance again after separation.

There are already Rush/Pursuit concepts in the architecture.

Consolidate them into an intuitive combat mechanic.

Goal:
a player who knocks the opponent away can quickly decide:
- pursue;
- reset;
- throw a tool;
- cast;
- reposition.

Implement/refine a universal RE-ENGAGE / CHAKRA DASH concept.

Requirements:
- fast;
- simple input;
- contextual target tracking when locked;
- usable after appropriate knockbacks;
- usable after launcher;
- usable after some projectile situations;
- usable after substitution/reposition where appropriate;
- cancelable into basic combat options at sensible timings;
- costs a meaningful but not excessive resource;
- punishable if used predictably;
- visually distinct by fighter.

Do NOT bind a core combat action to an awkward D-pad input on controller as the primary way to use it.

The player should be able to use this instinctively.

Character expression:

### MINATO
- fastest/cleanest re-entry;
- almost surgical;
- may integrate seals / FTG if valid.

### ITACHI
- calmer approach;
- possible feint/afterimage expression;
- more deceptive than explosively fast.

### NEJI
- compact direct close-in;
- controlled, efficient, center-line focused.

### SASUKE
- explosive aggressive pursuit;
- more momentum and commitment.

This re-engage system is important to keep combat flowing.

# PHASE 4 — CORE4 CHARACTER IDENTITY PASS

This is one of the most important parts of the mission.

Currently, some differences exist mainly as:
- speed multipliers;
- damage multipliers;
- regen;
- cooldowns;
- larger defensive windows;
- chakra drain values.

These are valid mechanically, but many are not sufficiently visible or felt.

A character difference must ideally exist across FOUR layers:

1. gameplay rule;
2. body animation / movement;
3. visual/audio feedback;
4. combo consequence.

If a mechanic only changes a number, it is not enough for a major identity trait.

The player should be able to play each character for ~20 seconds and feel who they are even without reading the name.

## MINATO — ANGLES / MARKS / RELOCATION / DECISION SPEED

Current good ideas:
- body seal on launcher;
- floor seal on sweep;
- AngleStep;
- KneeStrike;
- Marked Kunai;
- FTG;
- Rasengan;
- fast movement profile.

Problem:
too much of his identity still feels like “shared fighter but faster.”

Expected next state:

His body language and combo structure should constantly communicate:
- precision;
- angles;
- short repositioning;
- mark placement;
- sudden re-entry.

Visually:
- light attacks can subtly alter angle around the opponent;
- his recovery should look economical;
- his stance remains light and coiled;
- lateral routes should visibly relocate him;
- marked targets should be clearly readable;
- floor marks / planted kunai should be visible but not visually noisy;
- FTG arrivals must feel different from ordinary dashes.

Combo examples in spirit:

`Light → Light → launcher`
→ body seal visibly appears
→ pursuit / FTG opportunity
→ air conversion
→ Rasengan or reset.

`Side route`
→ angle cut
→ seal setup
→ disengage
→ later teleport return.

`Sweep`
→ opponent falls
→ marked kunai remains at that point
→ the location becomes tactically meaningful.

FTG must be integrated into his combat flow, not feel like a disconnected special move.

Rasengan should feel like a natural conversion/finisher when conditions are right.

Review Wind Cut.

Current testing feedback:
Wind Cut does not feel very interesting or signature for Minato.

Do not keep a weak technique simply because it exists.

Either:
- redesign it so it meaningfully supports his movement/kunai/angle game;
OR
- replace/refocus it with a more Minato-specific utility.

Do not add generic spectacle. Strengthen the fighter fantasy.

Awakening:
YELLOW FLASH must visibly and mechanically change the way Minato flows.

Not just:
+speed
+regen
-cooldown.

Potential visible/mechanical changes:
- improved relocation chains;
- more fluid seal conversion;
- unique re-entry behavior;
- distinctive body/FX/audio rhythm.

## ITACHI — READ / DECEPTION / SHURIKEN / CONTROL

Current strengths:
- launcher covered by shuriken;
- FeintStep;
- afterimages;
- CounterPalm;
- Sharingan Read;
- geometry shuriken;
- ricochets;
- air shuriken;
- fire pressure.

The rising launcher with shuriken coverage is one of the BEST current examples of the desired design.

Why it works:
- simple input;
- unique result;
- instantly visible;
- creates a natural continuation;
- clearly belongs to Itachi.

Use this as a benchmark for the other fighters.

Current problem:
Mirage/Echo behavior is not convincing/reliable in testing.

Audit exactly what the player gets by default versus only through progression nodes.

A fighter's essential identity must not depend on progression to become functional.

If “deception” is core to Itachi, some meaningful version must exist in the base kit.

Expected visual behavior:
- economical punches/palms;
- calm posture;
- minimal wasted motion;
- deliberate delays;
- shuriken woven into body strings;
- afterimages that are visually readable;
- real punish when the opponent attacks the wrong image;
- Sharingan read should look like a read, not an invisible larger parry window.

When Read succeeds, the player should SEE and FEEL: “I predicted that.”

Possible feedback:
- brief eye/read cue;
- subtle visual lock;
- calm body adjustment;
- different counter timing;
- opponent attack passes through/bites on wrong target;
- immediate CounterPalm opportunity.

Do not overdo giant UI/VFX.

Make the combat itself communicate the mechanic.

Itachi combo identity:
`body attack → projectile cover → feint → opponent reaction → counter`.

His combos do not need to be the longest. They need to feel intelligent and deceptive.

Awakening:
SHARINGAN FOCUS must visibly increase his control/read identity, not merely buff stats.

## NEJI — PRECISION / TENKETSU / CHAKRA CONTROL

This fighter is mechanically interesting but currently too invisible.

Current systems:
- Gentle Fist chakra drain;
- guard drain;
- regen cut;
- tenketsu;
- CircleStep;
- PalmThrust;
- Rotation;
- Vacuum Palm;
- 64 Palms;
- Byakugan.

The problem:
too much is expressed only by bars and hidden values.

Expected next state:

Neji's attacks must visually look fundamentally unlike normal strikes.

Body language:
- compact;
- efficient;
- palms;
- short movements;
- precise center-line work;
- no unnecessary giant swings.

Every meaningful palm should communicate chakra-point contact.

Use restrained but clear feedback:
- local flash on the exact body point;
- short distinctive chakra pulse;
- different hit sound;
- tiny reaction shape;
- optional brief tenketsu mark;
- victim posture becoming slightly compromised.

Do not spam huge particles.

The opponent should understand: “Neji is closing my chakra network.”

A sequence should feel like:
`precise palm → precise palm → circular reposition → chakra point → PalmThrust / Vacuum Palm / 64 Palms threat`.

The player must SEE accumulation.

Examples:
- one point closed: subtle;
- several points closed: clearer;
- severe chakra restriction: clearly readable.

64 Palms should feel like the natural climax of his system, not just another jutsu button.

Rotation:
when Rotation wins an interaction, the follow-up counter must feel smooth and intentional.

Awakening:
BYAKUGAN FULL FIELD must visually and mechanically alter his awareness/control style.

Not just bigger windows and drain multiplier.

## SASUKE — AGGRESSION / KICKS / AIR / WIRE / CHIDORI

Sasuke is currently the closest to the intended result.

Reasons:
- LionKick changes the actual route;
- Shadow of the Dancing Leaf creates pursuit;
- heavy in air becomes Lion Combo;
- VaultKick is visually distinct;
- Chidori cancel exists.

This is the benchmark for: “a character-specific rule changes the scene.”

Preserve this.

Expand it without making execution harder.

Expected:
- kick-heavy taijutsu;
- strong verticality;
- aggressive pursuit;
- air conversions;
- wall opportunities;
- shuriken/wire integration;
- Chidori as a commitment/finisher;
- fire used as route pressure.

Wire must become meaningfully integrated with his fighting style.

We already have:
- Wire Trap;
- fire;
- Phoenix Flower;
- Chidori/lightning concept.

Use these coherently.

Possible interactions:
- shuriken + wire setup;
- wired opponent + Katon conversion;
- wire + lightning interaction where technically and visually coherent;
- Phoenix Flower hiding blades;
- wire allowing a route or positional trap.

Do not make every combo mandatory wire setup. It is an option layer.

Curse Mark:
currently one of the most visibly understandable awakenings.

Keep the strong visible transformation.

But it should also alter his combat flow:
- more aggressive extensions;
- more risk;
- potentially stronger re-engage;
- health drain remains meaningful.

# PHASE 5 — CHAKRA MUST BECOME SYSTEMIC

This is what should make Ninja Duel fundamentally different from Storm.

Currently chakra is still too close to: “resource used to cast jutsu.”

We want:
CHAKRA = COMBAT RESOURCE THAT MODIFIES ACTIONS.

Concept:

`OBJECT / BODY ACTION + CHAKRA + ELEMENT / CHARACTER MASTERY + CONTEXT = A MODIFIED ACTION`

Do NOT create 20 new buttons.

Use contextual combinations.

Potential input philosophy:
- chakra modifier + existing action.

For example:
- chakra + tool;
- chakra + dash;
- chakra + heavy;
- chakra + jump;
- chakra + contextual attack.

The exact input scheme is your design responsibility.

It must remain easy on keyboard and controller.

The point is not adding commands. The point is allowing existing actions to gain properties.

## CHAKRA TOOL INFUSION

Implement a first robust systemic version.

Examples of desired behavior:

### NORMAL KUNAI
- ordinary projectile.

### CHAKRA-REINFORCED KUNAI
- visibly reinforced;
- stronger stability/contact;
- better at contesting light projectiles or guard;
- different impact feel.

### WIND + KUNAI
- sharper cutting identity;
- different trajectory/speed behavior;
- clear wind trail;
- useful lane-control property.

### LIGHTNING + METAL/WIRE
- conductive interaction;
- particularly relevant to Sasuke.

### FIRE + TOOL / TAG / ZONE
- ignition interaction where coherent.

### PLANTED PROJECTILES
- remain relevant after impact where fighter/system supports it.

### PROJECTILE COLLISION
- tools should interact when paths meet;
- deflections/interceptions should be understandable.

### WIRE
- must become a genuine systemic object, not just a scripted attack.

The important rule:

INFUSION MUST CHANGE BEHAVIOR, not only damage.

Bad:
`chakra kunai = +15% damage`

Good:
`chakra kunai travels differently, contests differently, reacts differently, can become part of another interaction.`

## CHARACTER-SPECIFIC CHAKRA EXPRESSION

### MINATO
- seals;
- marked kunai;
- movement;
- chakra invested in re-entry/FTG;
- potentially wind/tool interaction.

### ITACHI
- precise shuriken;
- fire;
- deception/control;
- chakra spent on pressure and read setups.

### NEJI
- chakra expressed through the body;
- Gentle Fist;
- defensive chakra;
- Vacuum Palm;
- tenketsu.

### SASUKE
- lightning;
- wire;
- metal;
- fire;
- aggressive chakra movement.

The SAME systemic framework should produce DIFFERENT fighter identities.

# PHASE 6 — FINISH ANIMATION QUALITY

The previous pass improved locomotion and some attack clips.

Testing confirms:
better than before, but still not good enough.

Do a real visual animation pass.

Focus on:
- Light1;
- Light2;
- Light3;
- heavy;
- launcher;
- pursuit attack;
- running attack;
- air1;
- air2;
- spike;
- slam;
- landing after combat;
- reaction animations;
- wall reactions;
- jutsu transitions;
- combo-to-combo transitions.

The goal is NOT simply “more frames.”

The goal is body mechanics.

Every important strike should visibly show:
`support → weight transfer → acceleration → impact → follow-through → recovery`.

Avoid:
`pose A → pose B → pose C`.

Feet matter.

The support foot must make sense.
The pelvis must lead/transfer weight.
The torso must counter-rotate.
Kicks must use hips.
Punches must not look like shoulders swinging independently from the body.

Important:
the animation between attacks matters as much as each individual pose.

If two attacks are individually good but the transition snaps, the combo still looks bad.

Continue to diagnose:
- foot teleporting;
- root stepping;
- ground VFX popping;
- pose snaps;
- combo transition snaps;
- chase transitions;
- landing transitions.

Use native Studio repeatedly.

# PHASE 7 — REACTIONS & IMPACT

The attacker being animated better is only half the problem.

The victim must sell the hit.

Different attacks should generate different body reactions:
- head strike;
- stomach/body fold;
- knee strike;
- leg sweep;
- palm;
- launcher;
- air hit;
- wall splat;
- spike;
- heavy blow;
- chakra point hit.

Use:
- head snap;
- shoulder turn;
- torso compression;
- hip rotation;
- leg collapse;
- loss of footing;
- airborne body shape;
- recovery posture.

Avoid every hit feeling like:
`HP decreases + generic recoil`.

# PHASE 8 — JUTSU QUALITY PASS

Audit every CORE4 technique.

A jutsu should justify its slot as one of:

### SIGNATURE
- strongly identifies the character;

### UTILITY
- creates setup, positioning, control, defense or conversion;

### COMMITMENT / FINISHER
- powerful and risky.

If a technique is none of these, reconsider it.

Testing feedback to address:

### ITACHI
- Mirage/Echo currently not convincing / may not work as expected.
- Fix base-kit deception behavior.
- Ensure the visual decoy and gameplay consequence actually match.

### MINATO
- Wind Cut currently feels weak/generic.
- Either significantly redesign its purpose or replace/refocus it.
- It must support Minato's identity, not fill an elemental checkbox.

### ALL
- jutsu activation should connect smoothly with movement/combat;
- avoid awkward pauses;
- avoid animation freezes;
- improve hand signs and attack transition quality where necessary.

# PHASE 9 — ARENA / MOVEMENT FREEDOM

Finish the arena/gameplay freedom work that remained incomplete from the previous mission.

Ninja Duel should not feel like fighters locked into a flat circular arena.

The arena should support:
- distance;
- obstacles;
- height;
- wall routes;
- wall runs;
- wall attacks;
- splats;
- rebounds;
- pursuit;
- lateral escape;
- projectile lanes.

Do not overbuild map art.

Function first.

A 60-second duel should naturally use space.

Players should be able to:
- disengage;
- reposition;
- use a wall;
- chase;
- approach from another angle;
- fight at range;
- return to close combat.

# PHASE 10 — KEEP THE UI SIMPLE

Do not solve combo accessibility by adding huge tutorial prompts during combat.

The game itself must be intuitive.

Small contextual feedback is acceptable where genuinely useful, but avoid:
- giant combo diagrams;
- constant arrow instructions;
- excessive text;
- rhythm-game UI.

The player should learn mostly through:
- consistent controls;
- visible consequences;
- animation;
- repetition.

A future training/tutorial system can teach deeper routes.

This mission should make normal combat intuitive without requiring a manual.

# PHASE 11 — STUDIO VALIDATION LOOP

Do NOT consider code/tests sufficient for this mission.

The acceptance criterion is visual and playable.

Use this loop repeatedly:

1. launch generated place in Roblox Studio;
2. play with each CORE4 fighter;
3. record/inspect behavior;
4. identify awkward transitions;
5. change implementation;
6. rebuild place;
7. replay.

Use the existing Studio tools where useful.

For animation work:
compare actual gameplay footage / captures, not only code or tests.

# MANDATORY HUMAN-PLAY SCENARIOS

## MINATO
30–60 sec:
- ground string;
- angle route;
- body mark;
- floor mark;
- FTG re-entry;
- air conversion;
- Rasengan conversion;
- chakra-infused tool interaction;
- re-engage.

Question:
Does this visibly feel like Minato?

## ITACHI
30–60 sec:
- basic compact string;
- rising palm;
- shuriken cover;
- FeintStep;
- actual decoy interaction;
- Read;
- CounterPalm;
- projectile pressure;
- fire pressure.

Question:
Can a viewer identify deception/control without looking at the HUD?

## NEJI
30–60 sec:
- palm string;
- CircleStep;
- tenketsu accumulation;
- visible chakra interference;
- Rotation counter;
- Vacuum Palm;
- 64 Palms threat.

Question:
Can a viewer tell that Neji is attacking the chakra network, not simply health?

## SASUKE
30–60 sec:
- kick string;
- LionKick;
- Shadow of the Dancing Leaf;
- Lion Combo;
- VaultKick;
- wire interaction;
- fire conversion;
- Chidori finish;
- Curse Mark.

Question:
Does he feel aggressive, vertical and risky?

# MANDATORY CROSS-FIGHTER TEST

Play the same simple sequence with all four:

`neutral → approach → 3–5 hit exchange → directional route → knockback → re-engage → air or wall conversion → disengage`

If all four scenes look broadly the same except for colors/VFX, the mission is NOT complete.

# ACCEPTANCE CRITERIA

This mission is successful when:

1. Combo execution feels easy and reliable.
2. No phantom combo progression: the confirmed combo starts at confirmed contact.
3. Directional routes are easy to intentionally trigger.
4. A casual player can discover and perform the main combo routes within minutes.
5. A skilled defender still has significant answers.
6. Each CORE4 fighter visibly and physically feels different.
7. Minato's identity is visible through marks, angles and relocation.
8. Itachi's identity is visible through shuriken, reads and deception.
9. Neji's identity is visible through precision and chakra-point pressure.
10. Sasuke's identity is visible through kicks, air pursuit, wire/fire and Chidori.
11. Each fighter has significantly richer combo routing than the current simple strings.
12. Re-engagement is smooth and intuitive.
13. Chakra can modify at least some ordinary combat/tool actions.
14. Chakra infusion changes behavior, not only damage.
15. Weapons/tools have meaningful combat interactions.
16. Current Mirage/Echo issue is fixed or redesigned into a reliable base-kit behavior.
17. Minato's weak/generic Wind Cut situation is resolved.
18. Attack animation is visibly better than the current build.
19. Transitions between attacks are visibly better.
20. Hit reactions sell the blow much better.
21. Arena walls/space can naturally enter combat.
22. Existing online/progression/roster foundations remain intact.
23. Automated tests still pass.
24. Generated normal/debug/QA builds are updated.

# DO NOT DO

Do not:
- add more playable roster characters;
- spend time writing additional fighter design sheets;
- expand online systems beyond what is needed to avoid regressions;
- expand progression UI;
- add monetization;
- hide unfinished mechanics behind skill tree nodes;
- solve depth with difficult input commands;
- solve readability with giant UI;
- add generic elemental moves simply to fill categories;
- declare visual work complete based only on tests;
- leave major identity systems as invisible stat modifiers.

# EXPECTED DELIVERABLE

The normal generated build should make the difference immediately obvious.

After opening:

`games/ninja-duel/dist/NinjaDuel.rbxlx`

I should be able to play Minato, Itachi, Neji and Sasuke for a few minutes each and immediately notice:
- combat is easier to control;
- combos do what I intended;
- combos have more routes;
- re-engagement is faster and more natural;
- attacks connect together better visually;
- the characters feel genuinely different;
- chakra/tools create choices that Storm does not offer;
- the game feels freer without becoming harder to understand.

The objective is NOT “more code.”

The objective is:
the next build must look and feel like a major combat upgrade.

Suggested final commit title:

`feat(ninja-duel): deepen core combat identity chakra and combo flow`

At the end, write a concise report including:
- exact combo/input changes;
- exact changes per fighter;
- chakra/tool interaction changes;
- animation changes;
- jutsu changes;
- re-engage changes;
- arena changes;
- Studio tests actually performed;
- automated test result;
- remaining known weaknesses.

Do not call something visually validated unless it was actually tested in Studio.
