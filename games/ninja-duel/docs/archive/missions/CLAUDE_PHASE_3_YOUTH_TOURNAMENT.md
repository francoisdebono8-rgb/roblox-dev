# Phase 3 — Youth Tournament Core / Movesets / Arena / Vision Gap

## Context: do not lose what already works

You are continuing from the current `claude/minato-itachi-final` branch after commit `8d7023d0b8fcc7d747f6b3a9a1b5633e923c53be`.

The previous pass already delivered major value: full-body owned-pose animation, planted-feet leg IK, improved gait/ninja run, multi-key attack clips, real 3D kunai/shuriken/fireball, Flying Thunder God presentation, Rasengan, crows, Sharingan, costumes, camera fixes, Studio tooling and a playable build.

**Do not throw that work away and do not rebuild the project from scratch.**

This phase is about making the game more coherent with its real concept, deepening character-specific combat, improving the engine where the actual playtest shows weakness, and finally giving the game an arena and atmosphere that belong to its identity.

Your working loop remains:

**play in Studio -> observe -> diagnose -> change -> replay -> polish**

Use Roblox Studio throughout the phase.

---

# 1. The actual core of the game — this is now the north star

This is NOT a generic Naruto battleground and NOT a collection of miniature adult versions of famous characters.

The core concept is:

> **A tournament bringing together roughly 20 of the greatest ninja prodigies, all around 12–14 years old, before they reach their full potential.**

The fantasy is:

> the player is seeing future legends while they are still young — already extraordinary, already distinct, already dangerous, but incomplete.

This concept must now guide:

- character visual design;
- outfits;
- proportions;
- animation attitude;
- techniques;
- move selection;
- combo structure;
- strengths and weaknesses;
- arena design;
- tournament presentation;
- atmosphere;
- future roster architecture.

The two current fighters, Minato and Itachi, must become the first quality standard for this concept.

---

# 2. Correct the current adult-version drift

The previous pass deliberately prioritized recognizability and spectacle. It succeeded visually, but some details are too close to adult/iconic versions.

Examples from the current build:

- Minato currently wears a jonin vest and Hokage-style white haori with flame hem / 四代目火影 identity;
- Itachi currently wears an Akatsuki cloak and slashed headband.

Those are immediately recognizable, but they conflict with the core premise of a 12–14-year-old prodigy tournament.

### Rework the costumes and presentation

Make them clearly recognizable as **young prodigy versions** rather than adult versions shrunk down.

For Minato, aim for:

- younger silhouette;
- lighter, simpler pre-Hokage outfit;
- hints of the future visual identity without literally dressing him as Hokage;
- practical ninja gear appropriate to a gifted young shinobi;
- signature blond hair / speed / kunai language retained.

For Itachi, aim for:

- young Uchiha prodigy identity;
- no Akatsuki cloak;
- no visual implication that this is his later criminal-era self;
- Uchiha / village-era visual language;
- restrained, intelligent, disciplined silhouette;
- Sharingan can remain as a combat identity if appropriate, but should not make him feel like full-power adult Itachi.

Keep them recognizable from a distance.

Do not over-age their faces, proportions or stance attitude.

---

# 3. Technique philosophy: prodigies, not maxed-out legends

Every technique should answer two questions:

1. **Would this make sense as a prodigy-level expression of this fighter?**
2. **Does it create interesting gameplay unique to them?**

Historical/canon accuracy matters as inspiration, but gameplay is allowed a small amount of deliberate compression when it creates a much better game.

For example, Minato's Rasengan can remain as a controlled gameplay liberty if it is excellent for the kit, but it should not imply adult/master-level power. Scale presentation, damage and mastery to the young-prodigy fantasy.

Likewise, Itachi should not simply inherit his full adult endgame arsenal.

Avoid adding techniques merely because the adult character is famous for them.

Prefer early signature seeds: abilities that show **what they will become**.

---

# 4. Deepen Minato's moveset into a real character, not five cooldowns

Current Minato kit already includes:

- Marked Kunai;
- Flying Thunder God;
- Rasengan;
- Quickstep;
- Wind Cut;
- melee / launcher / aerial systems.

Do not simply add more buttons. Deepen the interactions between what exists.

## Desired Minato combat identity

Minato should feel like a young combat genius whose greatest weapon is **decision speed**.

His gameplay should emphasize:

- angle creation;
- mobility while attacking;
- marked-space control;
- fast punishment;
- prediction;
- kunai placement;
- re-entry from unexpected angles;
- short, precise strings rather than long brute-force lockouts.

## Build real Minato routes

Create several viable routes, for example:

- ground light route -> angle change -> finisher;
- dash confirm -> short string -> disengage;
- marked kunai throw while moving -> opponent response -> teleport punish;
- launcher -> chase -> aerial route -> safe exit;
- kunai hit/near-miss -> teleport cross-up -> melee follow-up;
- defensive evade -> instant punish;
- Rasengan as a committed read/finisher rather than generic damage button;
- wall/height interaction -> re-entry.

Not every route should be optimal in every situation.

Add real tradeoffs: spacing, recovery, chakra, position, risk of whiff, predictability.

---

# 5. Deepen Itachi's moveset into a fundamentally different character

Current Itachi kit already includes:

- Read;
- Shuriken Barrage;
- Genjutsu: Mirage;
- Great Fireball;
- melee / launcher / aerial systems;
- crow and Sharingan presentation.

His combat should NOT feel like Minato with different VFX.

## Desired Itachi identity

Itachi should feel like a young prodigy who wins exchanges through:

- calm control;
- precision;
- prediction;
- ranged pressure;
- timing traps;
- shuriken geometry;
- selective fire pressure;
- deception;
- punishing impulsive approaches.

## Build real Itachi routes

Examples:

- controlled melee confirm -> shuriken release -> spacing reset;
- shuriken pressure -> forced dodge -> punish the dodge timing;
- short combo -> Mirage setup -> positional trap;
- defensive read -> counter string;
- launcher -> controlled aerial finish rather than Minato-like chase spam;
- Great Fireball to deny a lane / punish predictable retreat;
- crow/mirage deception that changes a decision, not just adds spectacle.

Itachi should often make the opponent ask:

> “Do I commit now, or is that exactly what he wants?”

---

# 6. Combo system: more branches, less one-string repetition

The game needs a broader combo vocabulary.

Do not solve this by creating extremely long unescapable strings.

Instead create **branching short-to-medium routes**.

A player should have meaningful choices based on:

- attack button/timing;
- movement direction;
- distance;
- whether the opponent is grounded or airborne;
- whether the previous hit actually confirmed;
- proximity to wall;
- current height;
- character-specific resource / mark / setup state;
- dodge/substitution risk;
- desired end position.

## Desired structure

Examples of branch logic:

- light -> light -> neutral finisher;
- light -> directional input -> alternate strike;
- light confirm -> heavy = launcher;
- light confirm -> tool = projectile cancel / setup;
- dash attack -> route A or route B;
- air route -> finisher or early disengage;
- wall contact -> wall-specific follow-up;
- whiff -> meaningful recovery rather than instant reset.

Minato and Itachi should NOT share the exact same optimal combo tree.

Where appropriate, create character-specific normal attacks, enders and cancel rules rather than only swapping VFX.

---

# 7. Engine details we can now afford to care about

Earlier phases were about making the game function and then look alive. We can now address the subtle technical details that separate “good prototype” from “real combat game”.

Actively inspect these systems in Studio and improve them if they are visibly weak.

## Inputs

- input buffering;
- queue rules;
- accidental double-trigger prevention;
- held vs pressed semantics;
- contextual actions;
- late-buffer behavior near recovery end;
- no swallowed inputs without clear reason.

## Hit confirmation

- animation contact should agree with hit registration;
- projectile visual should agree with projectile contact;
- attack should not mechanically hit significantly before/after visual contact;
- whiffs should look like whiffs;
- wall and air contacts should remain stable.

## Cancels / recovery

Create a deliberate cancel philosophy:

- what can cancel on hit;
- what can cancel on block;
- what can cancel on whiff;
- character-specific cancels;
- technique-to-melee and melee-to-technique rules;
- recovery that creates real counterplay.

## Aerial combat

Re-test aggressively:

- launcher -> chase;
- chase positioning;
- air string;
- aerial directional drift;
- early escape / substitute interaction;
- slam;
- landing;
- wall proximity;
- camera framing.

Remove remaining floating, hovering, snap-back, missed pursuit and bad landing states.

## Ground movement

Now that planted-feet IK exists, tune it visually:

- reduce foot sliding;
- make acceleration/deceleration read naturally;
- turning should involve hips/legs, not only root rotation;
- backward movement should look intentional;
- strafe should preserve opponent-facing logic;
- ninja sprint should feel fast without skating.

## Attacks

Review arms and legs frame-by-frame in Studio.

Look for:

- punches that stop short;
- elbows bending unnaturally;
- kicks without hip rotation;
- attacks with no weight transfer;
- feet crossing or sliding;
- hands clipping torso/head;
- body failing to follow through;
- transition back to locomotion looking mechanical.

The previous pass built the system. This pass should **tune the actual authored motion until it looks intentional**.

---

# 8. Camera: make it support character identity and combo readability

The previous pass fixed side-swapping/orbit behavior. Keep that.

Now go further.

The camera should handle:

- Minato teleport cross-ups;
- marked kunai mid-flight teleports;
- close melee;
- launcher/chase;
- aerial strings;
- Itachi ranged pressure;
- Fireball travel;
- wall movement;
- vertical arena spaces;
- rapid opponent side changes.

Do not over-cinematize normal actions.

The camera should feel responsive and anime-like while keeping player orientation intact.

Use stronger treatment only for meaningful actions/finishers and never at the cost of control.

---

# 9. Build the first real tournament arena

The current courtyard is explicitly listed as unfinished: flat grey floor, dark walls, placeholder feel.

This is now a priority.

Do not merely “decorate the test arena”.

Create the first arena that expresses the game's core fantasy:

> **an elite youth prodigy tournament where exceptional young ninja are being tested and watched.**

## Desired emotional read

The arena should communicate:

- prestigious tournament;
- serious competition;
- ninja world;
- young elite fighters;
- spectators/judges/observation implied or represented appropriately;
- a place specifically designed to reveal skill;
- tension before a duel;
- memorable visual identity.

## Gameplay requirements

The arena must still support the combat engine.

Include useful:

- central fighting space;
- line-of-sight variation;
- walls appropriate for wall movement;
- modest elevation differences;
- obstacles that matter but do not constantly block camera;
- projectile lanes;
- teleport destinations;
- aerial space;
- clear boundaries.

Avoid random clutter.

## Visual direction

Aim for a strong anime ninja tournament/training-ground identity rather than a generic Roblox battleground.

Use a coherent combination of:

- stone / earth / wood;
- ninja architecture;
- banners / tournament markers;
- viewing or judging areas if appropriate;
- trees / cliffs / village context if it fits;
- sky and atmosphere;
- lighting;
- controlled color palette;
- dust/wind ambience;
- subtle environmental motion.

The arena should look good from the normal combat camera, not only from freecam.

---

# 10. Tournament presentation — start establishing the wider game's identity

Do not build the entire tournament mode yet, but begin making the fight feel like it belongs to one.

Where inexpensive and useful, add presentation hooks such as:

- fighter intro framing;
- matchup names;
- round start language;
- result framing;
- arena signage / tournament insignia;
- judge/spectator-space implication;
- hooks for future bracket / roster presentation.

Keep this lightweight. Combat quality remains the priority.

---

# 11. Think ahead to 20 prodigies without genericizing Minato and Itachi

The game will eventually have around 20 prodigies.

The architecture should support new fighters, but do NOT flatten everyone into the same template.

Preferred model:

> shared combat fundamentals + strongly character-specific move graphs, timings, animation vocabulary, movement traits and technique interactions.

Avoid:

> one universal character whose attacks are just parameter tables and differently colored particles.

While working on Minato and Itachi, identify which abstractions are genuinely reusable for the future roster and which should remain bespoke.

Do not spend the whole phase building a generic framework.

---

# 12. Vision Gap Audit — mandatory

At the end of your Studio work, create:

`games/ninja-duel/docs/reports/VISION_GAP.md`

This should be a serious design/development assessment, not filler.

Answer:

1. What still prevents the combat from feeling premium?
2. What still prevents Minato from feeling like a uniquely gifted young Minato?
3. What still prevents Itachi from feeling like a uniquely gifted young Itachi?
4. Which mechanics are currently too generic?
5. Which animations still look weak?
6. What camera problems remain?
7. What arena/presentation problems remain?
8. What does the game still lack to sell the “20 greatest prodigies aged 12–14” fantasy?
9. What technical risks will become painful when adding the next 18 fighters?
10. What are the five highest-value improvements after this phase?

Then, before stopping, implement **at least the highest-value improvements from your own audit that are feasible in this phase** rather than only documenting them.

Use judgment. Do not expand scope infinitely.

---

# 13. Testing standard

Use real Roblox Studio playtests continuously.

At minimum test:

## Minato

- grounded movement in all directions;
- sprint / stop / turn;
- melee branches;
- dash routes;
- launcher -> chase -> aerial routes;
- kunai while moving;
- marked kunai teleport;
- teleport -> immediate attack branches;
- Rasengan;
- wall interaction;
- recovery after every major action.

## Itachi

- grounded movement;
- melee branches;
- ranged shuriken routes;
- Shuriken Barrage;
- Read;
- Mirage;
- Great Fireball;
- launcher/aerial options;
- wall and arena interactions;
- defensive/recovery situations.

Also deliberately test weird sequences and mashy player behavior to find state bugs.

Play multiple full fights.

At least once, ignore the HUD and judge whether the combat itself communicates what is happening.

---

# 14. Preserve spectacle, improve coherence

Do NOT remove recent high-value visual work just because this phase changes the premise.

Keep and refine good things such as:

- real kunai/shuriken;
- fireball;
- Rasengan if retained under the young-prodigy philosophy;
- Flying Thunder God presentation;
- crows;
- Sharingan;
- teleport flash;
- speed trails;
- improved body animation;
- camera side-swap fix.

But re-contextualize anything that reads as adult/final-form Naruto rather than youth-tournament Naruto.

---

# 15. Delivery requirement — must be testable on the user's Mac

This is non-negotiable.

At the end of the phase:

1. commit all meaningful work to `claude/minato-itachi-final`;
2. push the branch to GitHub;
3. rebuild the complete playable artifact;
4. ensure `games/ninja-duel/dist/NinjaDuel.rbxlx` is the exact latest playable version;
5. ensure it opens directly in Roblox Studio on the user's Mac;
6. do not leave required assets or logic only on your local Windows machine;
7. provide the final commit hash;
8. list current controls;
9. summarize visible/gameplay changes;
10. list remaining known issues honestly;
11. include `../../reports/VISION_GAP.md`.

The user should be able to pull/download the repository, open `../../../dist/NinjaDuel.rbxlx` on the Mac, press Play, and test your exact final state without manual reconstruction.

---

# Final quality bar

Before this phase, the project already became visually impressive enough to prove the direction.

After this phase, it should begin to feel like **this specific game**, not simply a polished Naruto-like prototype.

The intended read is:

> **Twenty legendary future ninja, gathered as 12–14-year-old prodigies, each already exceptional but still incomplete, fighting in a prestigious tournament that exposes exactly why each of them will become extraordinary.**

Minato and Itachi should be the first two fighters that prove that concept mechanically, visually and emotionally.
