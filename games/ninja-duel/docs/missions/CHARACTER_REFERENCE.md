# Character reference pool — V0.2

These sheets exist so implementation does not reduce characters to `three cooldown buttons`. They describe **combat identity, movement, neutral game, technique opportunities, animation language, AI behavior and future possibilities**.

They are intentionally broader than V0.2. Codex should choose a coherent subset that produces the best playable contrast and keep the rest as future hooks.

Age fantasy: approximately 12–14. Where canon does not precisely document every ability at that exact age, prefer a conservative extrapolation from demonstrated prodigy/training rather than automatically giving the character famous techniques learned much later.

For commercial/public release, transform these into original IP-safe characters. These names and canon references are internal design targets only.

---

# 1 — Young Minato Namikaze

## Core fantasy
A once-in-a-generation movement and tactical prodigy. He should feel **fast because the player thinks and moves fast**, not because every button auto-teleports behind the enemy.

Young Minato's V0 identity should emphasize exceptional natural speed, reactions, body control, kunai precision, positioning and intelligence. Do **not** build the kit around later-life Naruto-era accomplishments simply because adult Minato is famous for them.

### Explicit age restraint
For the 12–14 interpretation, do not make Rasengan, Kurama powers or adult Hokage-scale techniques part of the baseline. Flying Thunder God / Hiraishin at this exact age is uncertain enough that V0 should not depend on canonically asserting it. We can still test the *design fantasy* of marks/anchors through an experimental prototype mechanic, but keep it modular and recognize that this may later belong to an older/originalized version.

## Player emotion
`I am always one step ahead.`

The player should enjoy:
- entering and leaving danger;
- changing angle before the opponent finishes reacting;
- throwing a kunai while moving;
- baiting a dodge then attacking the new position;
- converting movement skill into damage;
- escaping situations another fighter could not.

He should be one of the easiest characters to move with but one of the hardest to fully optimize.

## Physical profile
Relative prototype tendencies, not final balance numbers:
- ground speed: exceptional;
- acceleration: exceptional;
- jump control: exceptional;
- air control: high;
- dash distance: high;
- dash recovery: low/moderate;
- raw melee damage: moderate;
- durability: moderate;
- chakra pool: moderate/high;
- technique commitment: generally low/moderate, with powerful setups carrying more commitment;
- ranged damage: low/moderate;
- ranged utility: high.

## Locomotion signature
Minato is the benchmark character for V0.2 movement quality.

Animation/motion ideas:
- low forward-leaning ninja sprint;
- very fast first three steps rather than slow ramp-up;
- clean planted lateral changes;
- long athletic leap;
- compact airborne silhouette;
- fast landing into run with minimal dead time;
- lateral dodge that travels meaningfully rather than a tiny roll;
- backward disengage that preserves facing toward target;
- optional special quick-step with distinctive streak, separate from ordinary universal dodge.

## Neutral game
Ideal distance: just outside opponent's comfortable melee range.

He constantly threatens three things:
1. sudden close-in;
2. kunai/projectile forcing a reaction;
3. angle change.

He should not stand still waiting for cooldowns.

## Basic melee concept
Fast taijutsu based on precision and momentum rather than brute force.

Possible 4-hit prototype chain:
1. fast advancing palm/punch to establish contact;
2. turning body kick that carries sideways around target slightly;
3. low/side strike that maintains pursuit;
4. strong kick/palm finisher that sends opponent away at a chaseable trajectory.

Alternative input/directional branches can come later.

Desired animation language: economical, almost no wasted motion, feet constantly repositioning.

## Tool — Kunai
Kunai should be part of Minato's neutral game, not merely a special move with a giant cooldown.

Possible implementation:
- quick single kunai with low damage;
- accurate while moving;
- forces guard/dodge or checks movement;
- limited fire cadence/ammo-style rhythm to prevent spam;
- can become the basis for future marked-anchor mechanics.

## Technique pool
### A. Quickstep
Short, very fast chakra-assisted reposition in the player's input direction. Not invulnerable for the entire travel. Used to steal an angle or extend pursuit.

Counterplay: prediction, wide attack, punish recovery if spammed.

### B. Kunai Feint / Angle Entry
Throw or threaten a kunai while changing approach angle. Could combine projectile and movement without guaranteeing a hit.

Purpose: make his offense about creating two simultaneous questions for the defender.

### C. Burst Entry
A committed high-speed melee entry. Short startup, fast travel, meaningful whiff recovery. Strong punish after reading an opponent, bad when thrown randomly.

### D. Experimental Marked Anchor — optional V0 mechanic
This is a **gameplay experiment inspired by Minato's later identity**, not a claim that this exact young version canonically possesses the complete technique.

A thrown tool can create a temporary anchor. A later action allows an extremely rapid relocation to it. Requirements:
- visible/readable anchor;
- chakra cost;
- no free guaranteed damage on arrival;
- opponent can reposition relative to it;
- arrival has a small commitment/readable cue;
- anchor lifetime/quantity limited.

If this mechanic massively improves fun, keep it modular and later decide whether our original commercial character owns it.

### E. Counterstep — future candidate
A tight timing movement counter: read a committed attack, evade by inches and appear at an advantageous angle. High skill ceiling, not automatic substitution.

## What Minato should NOT become
- permanent teleport spam;
- guaranteed auto-tracking attacks;
- Rasengan bot;
- pure ranged kunai spammer;
- invincible because his lore says he is fast;
- identical universal movement with yellow VFX.

## Technique execution ideas for future
Minato is a good candidate for spatial prerequisites rather than hand-sign complexity:
- place a mark/tool;
- maintain awareness of anchors;
- choose destination during live combat;
- use directional input during startup;
- chain movement only when a prior condition has been established.

## Hit/visual language
Speed should be shown through:
- short afterimages/trails;
- dust kick on explosive acceleration;
- controlled FOV response;
- crisp arrival/stop pose;
- minimal giant particle explosions for normal attacks.

## AI personality
Minato AI should:
- move more than average;
- prefer flank angles;
- rarely stand in front trading hits;
- throw/check with kunai;
- disengage after unsafe sequences;
- punish long technique startup aggressively;
- occasionally overcommit at lower difficulty so the player can punish him.

## Skill expression
Beginner: speed makes him forgiving.
Intermediate: learns spacing and kunai pressure.
Expert: manipulates angles, movement recovery, anchors/feints and opponent reactions.

---

# 2 — Young Itachi Uchiha

## Core fantasy
A frighteningly composed prodigy. At the same nominal age he does **not** need to be portrayed as equal in development to ordinary genin. His fantasy is anticipation, precision, deceptive information, efficient ninjutsu and punishing predictable behavior.

He should feel slower than Minato in raw traversal but often appear to have known what the opponent would do before they did it.

## Player emotion
`You did exactly what I expected.`

The player should enjoy:
- watching habits;
- making the opponent afraid to attack predictably;
- forcing reactions with projectiles/fire;
- creating a small opening with perception/genjutsu;
- punishing at exactly the right moment;
- winning exchanges with efficiency rather than frantic spam.

## Physical profile
Relative prototype tendencies:
- ground speed: high, below Minato;
- acceleration: high;
- jump control: high;
- dash: high but less travel-focused than Minato;
- melee speed: high;
- raw melee damage: moderate;
- precision/punish damage: high;
- chakra efficiency: high;
- ranged control: high;
- defensive reading: exceptional when player executes correctly;
- durability: moderate;
- failed high-level read/genjutsu should create punishable recovery.

## Locomotion signature
Itachi should look controlled rather than hyperactive:
- compact run;
- minimal unnecessary upper-body movement;
- sharp stop/turn animations;
- evasions that move just enough to escape;
- calm combat stance;
- jumps are still superhuman because this is the game's universal ninja baseline, but less traversal-dominant than Minato.

## Neutral game
Ideal distance: medium-to-close transition range.

He wants to make the opponent reveal an intention. Projectile -> observe response. Brief pressure -> observe dodge. Read stance -> punish repeated pattern.

## Basic melee concept
Precise, fast and short.

Possible chain:
1. short fast strike;
2. elbow/palm or compact kick;
3. body-angle change/strike;
4. precise finisher creating enough separation to resume control.

Less forward travel than Minato; better at keeping the opponent where he wants them.

## Sharingan / perception design principle
Do not implement Sharingan as a permanent passive `+20% everything` or automatic dodge.

For gameplay, represent superior perception through **player-facing mechanics**:
- a timed Read stance/window;
- enhanced telegraph information for a brief period;
- reward for correctly reading a committed attack;
- perhaps slightly clearer enemy startup cues while active;
- counter opportunity if the read succeeds.

It should make a skilled player feel intelligent, not let the game play for them.

For the future commercial version, replace copyrighted eye iconography/naming with an original perception system.

## Technique pool
### A. Shuriken / projectile pattern
A precise multi-projectile throw used to constrain movement. Damage modest; spatial value high.

Possible behavior: slight spread or staggered timing so the defender must choose a movement response.

### B. Fire Release pressure
A committed fire technique with visible startup. Stronger area/range pressure than the shuriken but interruptible before release and punishable if used badly.

Do not make it an instant giant unavoidable sphere.

### C. Read
Short active reading stance/window.

If the opponent performs an eligible committed action in the correct range/angle during the window, Itachi receives a brief advantage: faster evasive response, short counter window, or information cue. Exact implementation can be chosen for reliability.

Failure: recovery/lockout so repeatedly mashing Read loses neutral.

### D. Genjutsu / Mirage Cast
This is one of the game's most important long-term mechanic experiments.

Activation should require an earned condition, such as:
- target in range;
- line of sight;
- facing/visual engagement;
- brief channel or read setup;
- not currently being hit.

The startup is interruptible.

On success, do **not** simply freeze the victim for 5 seconds. Attack their information for a short period. Prototype possibilities:
- one convincing false afterimage while the real Itachi changes angle;
- false target marker;
- briefly show a misleading movement direction;
- decoy that performs the first frames of an attack;
- subtle temporary visual-space distortion.

Victim keeps control. Duration short. Strong audiovisual cue indicates entering/leaving the effect.

The purpose is to make the victim make **one wrong decision**, which Itachi then has to capitalize on manually.

### E. Substitution / deception — future candidate
A limited defensive technique that, on a tight condition/timing, replaces Itachi with a decoy/log/afterimage and repositions him. Must not be a free universal escape from every combo.

### F. Clone feint — future candidate
A brief clone/afterimage used to obscure which angle contains the real attack. Prefer interactive deception over raw damage.

## Genjutsu counterplay
Future system should support multiple answers rather than one hard immunity:
- interrupt startup;
- break line of sight;
- move outside condition/range;
- recognize decoy behavior;
- defensive chakra action if later designed;
- character-specific counters for some matchups.

This is important because genjutsu should become a *game system*, not Itachi's private stun button.

## What Itachi should NOT become
- permanent auto-dodge Sharingan;
- five-second uninteractive stun character;
- giant fireball spammer;
- slower Minato with red effects;
- cutscene ultimate character;
- character whose 'intelligence' is represented by the game automatically winning exchanges.

## Technique execution ideas for future
Itachi is ideal for conditional techniques:
- establish eye contact/target condition;
- use a read window;
- perform a short sign sequence only after creating space;
- exploit opponent repetition;
- convert successful perception into a short technique opportunity.

A future hand-sign system could require a compact 2–4 input sequence during a live opening. Longer/more powerful techniques require more exposed execution time. Do not implement a full rhythm minigame now.

## Hit/visual language
- controlled red/dark perception accents without copying Sharingan symbols;
- thin, precise projectile trails;
- restrained illusion distortion;
- fire light should illuminate the immediate scene briefly;
- successful read gets a crisp micro-cue rather than giant UI text.

## AI personality
Itachi AI should:
- move less frantically than Minato;
- maintain deliberate spacing;
- use projectiles to ask questions;
- guard/read more often against predictable pressure;
- attempt genjutsu after creating an opening rather than randomly;
- punish repeated player habits with weighted decisions;
- still have reaction delay and imperfect reads so it never cheats.

## Skill expression
Beginner: projectile/control tools provide structure.
Intermediate: learns when Read is valuable and how to create genjutsu openings.
Expert: conditions the opponent, recognizes habits, layers feints and converts tiny mistakes.

---

# Optional alternative prototype — Young Shisui

If Itachi's illusion/perception systems prove too expensive to make fun during V0.2, Shisui is the preferred alternative second prototype, **not because he is weaker but because he can produce a more immediately physical contrast**.

Core fantasy: elite young movement/feint prodigy, potentially at or above young Itachi in this design framing.

Do not make him `Minato #2`. His speed identity should be about **body-flicker chains, false trajectories and feints**, whereas Minato is spatial positioning/kunai/clean angle control.

Possible loop:
feint direction -> body flicker -> force premature defensive reaction -> reappear/change vector -> precise punish.

Possible tools:
- short body-flicker burst with a visible starting tell;
- afterimage continuing original trajectory while player changes direction;
- fast melee pressure;
- projectile feint;
- perception/genjutsu as secondary rather than entire identity.

Use Shisui only if Codex concludes with François that he produces a substantially better V0 combat test than Itachi. Do not silently swap characters.

---

# Contrast test
When V0.2 is correct, a player switching characters should immediately change mindset:

**Minato reference:** `Where can I move next, and from which angle can I attack?`

**Itachi reference:** `What will they do next, and how can I make that response wrong?`

If both characters are simply sprinting around and pressing three differently colored damage abilities, the implementation has missed the point.