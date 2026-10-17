> Snapshot historique avant harmonisation des fiches le18/10/2026. Conserver les idées et preuves ; état/priorités dans docs/active, nouvelle fiche au chemin d’origine.

> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../../../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Ninja Duel — 10-Prodigy Moveset & Awakening Blueprint

This document is the gameplay roster base for future implementation. It is not the final balance sheet yet. The goal is to define a common combat grammar, then make every fighter interpret that grammar differently through movement, taijutsu, ninja-tool mastery, signature mechanics, techniques and awakening.

Core principle: do not build 10 characters that share the same brawler kit with different VFX. Each fighter should feel different before using a flashy jutsu.

## Shared combat grammar

All fighters should use the same readable core language when appropriate:
- free movement + lock-on;
- sprint / chase / reposition;
- grounded taijutsu strings;
- directional combo branches;
- launcher;
- downward/slam route;
- side branch / throw / chop / character-specific route;
- aerial follow-up;
- wall interaction;
- substitution;
- standard ninja tools when lore/gameplay appropriate;
- jutsu cancels and character-specific extensions.

Controller-oriented example grammar:
- neutral light string => standard grounded route;
- repeated light attacks + UP => launcher route;
- repeated light attacks + DOWN => low/slam route;
- light attacks + LEFT/RIGHT => lateral branch, grab, redirect, sweep or character-specific route;
- airborne directional input => alternate aerial branch;
- wall proximity => wall-specific options where appropriate.

This grammar is shared, but the animation, timing, range, purpose and route outcome must vary per character.

## Shared ninja-tool rule

Kunai and shuriken are not exclusive to Itachi.

They are a baseline ninja-tool system available to fighters where appropriate. Character identity comes from mastery and special interactions:
- Itachi is exceptionally strong with projectile geometry, ricochets, delays, deception and combo integration;
- Minato differentiates through marked kunai, seals and teleport routes;
- Sasuke uses tools more aggressively with wire, fire and pressure;
- Neji can use standard tools but they remain secondary to Gentle Fist;
- other characters can have basic, enhanced or limited tool access based on identity.

Future balance work should separate universal tool access from character-specific mastery modifiers.

## Character design framework

Every character sheet should eventually expose six layers:
1. Taijutsu identity
2. Movement identity
3. Ninja-tool mastery
4. 4–6 main techniques
5. Passive/signature mechanic
6. Awakening

Awakenings should change the rules of the character rather than act as simple +damage stat buffs.

---

# 1. Minato Namikaze — Young Prodigy

## Identity
Speed, efficiency, geometry, preparation, precision and explosive angle changes.

## Taijutsu
- extremely clean and economical strikes;
- strong palm/kick mix;
- little wasted motion;
- short strings that naturally create teleport windows;
- launcher should flow directly into aerial pursuit;
- side branches should create angle changes rather than brute-force damage.

Example route ideas:
- neutral string: palm -> body punch -> turning kick -> short displacement finisher;
- UP route: low step-in -> rising kick launcher -> FTG follow-up window;
- DOWN route: leg sweep -> marked kunai placement -> downward strike;
- LEFT/RIGHT route: sidestep around guard -> rib strike -> kunai transition.

## Movement
- fastest-feeling grounded repositioner;
- high control at sprint speed;
- can preserve target awareness without unnatural constant strafing;
- teleport is not a replacement for running: running creates the geometry, FTG exploits it.

## Ninja tools
- normal kunai access;
- marked kunai system;
- planted seal points;
- body seal / target seal where appropriate;
- throws can be integrated into taijutsu and aerial routes.

## Techniques
- Flying Thunder God
- Marked Kunai
- Rasengan
- Flash Counter / instant angle punish
- Wind Cut / short ranged option
- Seal Network control action

## Signature mechanic
**Prepared Geometry**
The arena becomes increasingly favorable as Minato places useful marks. His best routes should reward preparation, angle selection and fast decision-making.

## Awakening
**Yellow Flash Flow**
Not a magical transformation. Minato enters peak combat flow:
- faster route-to-route transitions;
- reduced recovery on successful precision actions;
- more flexible FTG chaining between valid marks;
- new teleport-assisted combo branches;
- stronger aerial re-entry;
- access to a high-impact Rasengan finisher.

Visual identity: calm posture, tiny pauses, then extreme bursts of motion.

---

# 2. Itachi Uchiha — Young Prodigy

## Identity
Reading, deception, precision, projectile mastery, calm counters and measured pressure.

## Taijutsu
- compact and precise rather than explosive;
- feints and redirects;
- short counters;
- deceptive rhythm;
- projectile inserts inside strings;
- movement should often create the impression that Itachi was one step ahead.

Example routes:
- neutral: short palm -> elbow -> shuriken insert -> kick;
- UP: controlled launcher with projectile coverage;
- DOWN: low redirect -> sweep -> fire or shuriken trap;
- LEFT/RIGHT: feint -> side reposition -> counter strike.

## Movement
- calm walk and short bursts;
- strong micro-positioning;
- minimal unnecessary animation;
- evasive steps should look deliberate rather than panicked.

## Ninja tools
Everyone can use tools; Itachi is simply elite with them.

Unique mastery ideas:
- delayed second shuriken;
- ricochet/deflection setup;
- two projectiles colliding to change trajectory;
- projectile used to force a dodge direction;
- shuriken inserted into combo gaps;
- aerial spread;
- fake projectile rhythm;
- projectile cancel into taijutsu.

## Techniques
- Great Fireball
- Phoenix Flower / fire + projectile mix
- Shadow Shuriken
- Mirage / afterimage deception
- Crow Substitution / counter
- Shuriken Geometry

## Signature mechanic
**Read & Punish**
Successful reads, parries, perfect dodges or forcing a predictable dodge should open stronger follow-ups than raw aggression.

## Awakening
**Mangekyo Sharingan**
Gameplay shift toward oppressive information and psychological pressure:
- stronger read windows;
- Tsukuyomi as a setup/counter style special rather than a generic stun button;
- Amaterasu as a dangerous positional threat;
- enhanced deceptive routing;
- optional very short Susanoo manifestation only as a later counter/ultimate concept, not as a permanent normal form.

---

# 3. Neji Hyuga — Gentle Fist Specialist

## Identity
Precision, body control, chakra denial, rotation, defensive mastery and technical taijutsu.

## Taijutsu
Almost no generic brawler animation.
- palms;
- finger strikes;
- redirections;
- short sweeps;
- rotational entries;
- chakra-point targeting.

Example routes:
- neutral: palm chain focused on torso/chakra points;
- UP: rising palm launcher;
- DOWN: rotational sweep into ground pressure;
- LEFT/RIGHT: circular step around an attack -> tenketsu strike.

## Movement
- very stable center of gravity;
- precise short steps;
- excellent circular movement;
- less flashy in travel speed, more efficient inside fighting range.

## Ninja tools
Standard access can exist, but should remain secondary.

## Techniques
- Gentle Fist
- Eight Trigrams Rotation
- Vacuum Palm
- Chakra Seal / point closure
- Sixty-Four Palms
- defensive redirection counter

## Signature mechanic
**Tenketsu Pressure**
Precise hits temporarily weaken the opponent's systems:
- slower chakra recovery;
- selected technique lockout;
- reduced movement resource efficiency;
- stronger payoff after repeated correct contact.

## Awakening
**Byakugan: Perfect Field**
- broader perception;
- stronger projectile awareness;
- improved defensive reads;
- enhanced Rotation efficiency;
- temporary weak-point targeting;
- improved punish accuracy rather than simple raw damage inflation.

---

# 4. Sasuke Uchiha — Age 12–13 Prototype

## Identity
Aggressive Uchiha prodigy, acrobatic pressure, fire, tools, rising lightning threat.

## Taijutsu
- faster and more aggressive than Itachi;
- stronger kicking emphasis;
- acrobatic movement;
- aerial pursuit;
- sudden side-switches;
- early Lion Combo flavor.

Example routes:
- neutral: punch -> kick -> turning strike -> aggressive ender;
- UP: acrobatic launcher -> aerial pursuit;
- DOWN: low kick -> sweep -> ground punish;
- LEFT/RIGHT: side vault or evasive step into back kick / wire setup.

## Movement
- energetic and reactive;
- strong burst acceleration;
- mobile in air;
- less refined than Minato, more aggressive.

## Ninja tools
- normal kunai/shuriken;
- wire-assisted shuriken;
- aggressive multi-angle throws;
- projectile + fire synergy.

## Techniques
- Great Fireball
- Phoenix Flower
- Wire Trap
- Lion Combo
- early Chidori as high-commitment, high-risk technique
- shuriken pressure action

## Signature mechanic
**Pressure Conversion**
Sasuke should be good at turning one successful opening into a mobile aggressive sequence, but should be more punishable than Itachi or Minato when overcommitting.

## Awakening
**Curse Mark**
- more violent animations;
- higher movement aggression;
- altered combo enders;
- amplified fire/lightning routes;
- stronger Chidori access;
- meaningful downside such as resource drain, self-damage pressure or limited duration.

---

# 5. Naruto Uzumaki — Unpredictable Pressure Fighter

## Identity
Chaotic creativity, clones, momentum, improvisation and unconventional attack timing.

## Taijutsu
Naruto should look less polished than Neji/Minato/Itachi but much harder to read.
- clone-assisted punches;
- improvised kicks;
- tackles;
- messy but effective aerial follow-ups;
- attacks from odd timing windows.

Example routes:
- neutral: direct rush string with clone surprise ender;
- UP: clones launch opponent upward;
- DOWN: clone grabs/anchors legs -> Naruto downward strike;
- LEFT/RIGHT: clone appears opposite side to create a fake cross-up.

## Movement
- energetic;
- slightly less technically clean;
- sudden sprinting and jumping;
- clones can alter apparent direction of approach.

## Ninja tools
Basic tools, not a mastery focus.

## Techniques
- Shadow Clone
- Clone Feint
- Uzumaki Barrage
- clone-assisted launcher
- Rasengan prototype if desired for game design continuity
- clone pursuit / aerial assist

## Signature mechanic
**Clone Routes**
Certain follow-ups can resolve through Naruto or a clone. The player controls the branch, making defensive reads difficult.

## Awakening
**One-Tail Cloak**
- more animalistic movement;
- stronger acceleration;
- violent body reactions and attacks;
- short chakra-arm extensions;
- altered combo grammar;
- reduced technical refinement but much greater pressure and resilience.

---

# 6. Gaara — Space-Control Fortress

## Identity
Zone control, automatic defense, pressure through sand, wall use and positional suffocation.

## Taijutsu
Gaara should intentionally break normal melee expectations.
- some close-range attacks are actually sand extensions;
- fewer traditional punches;
- short body motions command larger sand responses;
- grounded and deliberate.

Example routes:
- neutral: short hand/arm commands -> sand strikes;
- UP: sand pillar launcher;
- DOWN: sand sweep / floor capture;
- LEFT/RIGHT: side sand wall or lateral clamp.

## Movement
- slower direct movement;
- strong defensive posture;
- can reposition using sand bursts where appropriate;
- forces others to enter his controlled space.

## Ninja tools
Low emphasis.

## Techniques
- Sand Shield
- Sand Coffin
- Sand Wave
- Sand Clone
- Sand Burial
- sand wall / ground trap

## Signature mechanic
**Automatic Sand Defense**
Limited automatic protection against certain clean attacks, balanced by meter, cooldown, directional weakness or repeated-pressure vulnerability.

## Awakening
**Partial Shukaku**
- larger sand limb attacks;
- stronger area control;
- more oppressive defense;
- heavier slower attack commitment;
- altered movement and body silhouette;
- not a full adult-scale monster transformation.

---

# 7. Kakashi Hatake — Young Adaptive Genius

## Identity
Versatility, observation, counters, adaptation and broad technical competence.

## Taijutsu
- highly complete fundamentals;
- clean punches/kicks;
- good counters;
- balanced range transitions;
- no single extreme specialty at base.

Example routes:
- neutral: balanced technical string;
- UP: compact launcher;
- DOWN: sweep into utility technique;
- LEFT/RIGHT: evasive sidestep into counter or clone feint.

## Movement
- efficient and measured;
- good all-round response;
- less extreme than Minato/Shisui.

## Ninja tools
Strong normal proficiency.

## Techniques
- Lightning Blade / early lightning thrust prototype
- Earth Wall
- Clone Feint
- kunai + lightning interaction
- counter read
- copied-response prototype

## Signature mechanic
**Adaptation**
Repeated exposure to the same enemy option slightly improves Kakashi's defensive read or response opportunity against that pattern. Avoid hard auto-countering.

## Awakening
**Sharingan Uncovered**
- stronger anticipation;
- improved read windows;
- context-sensitive Copy Response;
- altered counter routes;
- higher technique efficiency at the cost of chakra drain if needed.

---

# 8. Orochimaru — Unnatural Range Specialist

## Identity
Unsettling body mechanics, deceptive range, serpents, unusual angles and strange mobility.

## Taijutsu
- attacks should feel physically wrong in an intentional way;
- extended body angles;
- snake-assisted reach;
- evasions that bend around attacks;
- low and unpredictable entries.

Example routes:
- neutral: body strike -> serpent extension -> close re-entry;
- UP: snake-assisted lift;
- DOWN: low body fold / sweep into bind;
- LEFT/RIGHT: unnatural side evade -> extended strike.

## Movement
- slippery;
- can reposition underground or through serpentine movement;
- difficult to read at close-medium range.

## Ninja tools
Basic tools possible, not central.

## Techniques
- Snake Bind
- Wind Burst
- Underground Shift
- Serpent Strike
- Snake Feint
- extended-body counter

## Signature mechanic
**Unnatural Reach**
Orochimaru can threaten from ranges where most taijutsu fighters cannot, but should have readable commitment or positional vulnerability to balance it.

## Awakening
**White Snake Instinct**
Gameplay liberty for the young-prodigy concept:
- longer attack reach;
- stranger evasions;
- serpent follow-ups integrated into strings;
- unusual recovery options;
- increased body deformation without using late-series giant transformations.

---

# 9. Shisui Uchiha — Body Flicker Duelist

## Identity
Continuous deceptive mobility, afterimages, speed feints and sudden angle creation.

## Taijutsu
- fast but not Minato-like;
- Minato uses prepared teleport geometry;
- Shisui uses continuous burst movement and false visual positions;
- strong tantō integration if used.

Example routes:
- neutral: rapid strike chain with afterimage ender;
- UP: flicker-through launcher;
- DOWN: sweep / low flicker cross-up;
- LEFT/RIGHT: afterimage split -> side re-entry.

## Movement
- best continuous burst movement;
- afterimage-heavy sidesteps;
- false direction cues;
- very strong mid-range closing.

## Ninja tools
Good Uchiha tool proficiency.

## Techniques
- Body Flicker Chain
- Afterimage Assault
- Tantō Rush
- Fireball
- Genjutsu Step
- flicker counter

## Signature mechanic
**Phantom Choice**
Certain movement actions create multiple short-lived afterimages; the player can select the actual re-entry point inside a brief timing window.

## Awakening
**Mangekyo — Phantom Flicker**
- stronger afterimage ambiguity;
- more flexible re-entry;
- enhanced genjutsu pressure;
- rare ultimate-style Kotoamatsukami concept reserved for later design, not a normal spammable move.

---

# 10. Rock Lee — Pure Taijutsu Stress Test

## Identity
Pure physical combat, speed, kicks, pressure, technical body control and explosive risk-reward.

Rock Lee is important because he tests whether the combat engine is actually fun without relying on jutsu spectacle.

## Taijutsu
- richest pure-body route set in the roster;
- kick-heavy;
- strong aerial chase;
- sweeps;
- spinning attacks;
- 360-degree kicks;
- launchers;
- Primary Lotus style routes.

Example routes:
- neutral: fast hand-to-kick pressure string;
- UP: Rising Leaf launcher;
- DOWN: sweep -> ground chase;
- LEFT: feint -> back kick;
- RIGHT: spinning side kick;
- heavy after aerial setup: Primary Lotus-style finisher.

## Movement
- extremely physical;
- sprinting, pivots, jumps and direction changes should look athletic and human;
- no teleport shortcuts.

## Ninja tools
Minimal or none as a mastery focus.

## Techniques
- Dynamic Entry
- Rising Leaf
- Primary Lotus
- evasive kick chain
- spinning kick route
- burst pursuit

## Signature mechanic
**Body Momentum**
Successful movement-to-attack transitions build pressure. Lee should gain advantage by preserving physical momentum rather than through projectile setups.

## Awakening
**Opening the Gates**
- dramatic movement-speed increase;
- stronger jumps and chase;
- altered taijutsu animation set;
- much more violent impacts;
- clear resource/time downside;
- post-awakening fatigue or vulnerability can be used for balance.

---

# Roster role summary

The first ten fighters intentionally cover different mechanical archetypes:
- Minato: prepared mobility / precision
- Itachi: read / deception / projectile mastery
- Neji: technical denial / close-range control
- Sasuke: aggressive hybrid pressure
- Naruto: chaos / clone routing
- Gaara: zoning / fortress control
- Kakashi: adaptive all-rounder
- Orochimaru: unnatural range / trick movement
- Shisui: continuous deceptive speed
- Rock Lee: pure taijutsu / physical execution

This diversity should guide future architecture. Systems should support character-specific movement, combo interpretation, tool mastery and awakening rules without forcing all fighters into one generic moveset template.

# Future implementation phase

Do not fully balance these characters yet.

A later dedicated system should formalize:
- move data;
- input grammar;
- damage;
- startup/active/recovery timing;
- cancel rules;
- chakra cost;
- cooldowns;
- projectile properties;
- wall/air interactions;
- awakening meter and activation;
- per-character passives;
- matchup-sensitive rules;
- AI interpretation of each fighter;
- controller/keyboard/mobile bindings.

When this phase begins, use this file as the creative source of truth, then convert each fighter into a standardized technical data sheet.
