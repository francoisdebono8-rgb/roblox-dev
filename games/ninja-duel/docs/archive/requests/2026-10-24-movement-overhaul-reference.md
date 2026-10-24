# Mission â€” Movement Overhaul and reference videos

Date: 2026-10-24
Projet: `games/ninja-duel/`
Status: design/execution brief. This document does not by itself authorize a second locomotion engine. Preserve the current combat and confirmation invariants.

## REFERENCE VIDEOS â€” MANDATORY

Two video references are versioned with this brief:

- `docs/references/movement/movement_ref_01.mp4`
- `docs/references/movement/movement_ref_02.mp4`

They are repo-friendly visual copies of the user's original recordings. The originals were about 25 MB and 38 MB respectively. These copies are 360 pixels wide, H264, silent, and intended for motion reference inside Git. They must not be treated as assets to ship in the game.

Orginal SHA256:
- ref 01: `25155cd47e5f5049f713f6f20adee7c69e5c486bb1c39471a88614b6ca84ddca`
- ref 02: `9b376c35fc8a6acdea75990e991e37c21e8a011f58a47bd57dac19fadbaa5667a`

You must watch both videos before modifying movement code.

They are not to be copied frame-for-frame. They are the visual target for the level of fluidity, ninja mobility, body continuity, contextual acrobatics and the fusion of locomotion and combat.

Focus your analysis on:
- run â€”> jump transitions;
- launched jumps that keep forward momentum;
- backflips and side flips used contextually;
- rapid angle changes;
- the body following the actual trajectory;
- attacks triggered directly from motion;
- no artificial stop before strikes;
- vertical movement;
- wall interactions;
- landing and immediate re-acceleration;
- lightness without losing impact weight;
- nonstop continuity between locomotion and combat;
- body rotation and foot placement during directional changes.

Before coding, produce a short internal map in this form:

\`\`
observed element â†’ mechanical principle â†’ current Ninja Duel state â†’ adaptation proposed
\```

Example:

\``
backflip during fast retreat â†’ backward evasion uses existing retreat momentum â†’ currently a generic dodge â†’ high-speed backward dodge can use a real rotation while keeping trajectory\n\``

The target is not to reproduce every shown animation. The target is to extract the principles that create the feel:

**momentum + continuity + anticipation + weight transfer + contextual movement + attacks integrated into locomotion.**

## 1. MAIN GOAL â€” CONTINUITY OF MOVEMENT

All actions should feel like part of one locomotion chain.

Target example:

\``
sprint â†’ long jump â†’ body rotation â†’ air attack â†’ impact â†’ pursuit â†’ wall â†’ wall-run â†’ wall-jump â†’ landing â†’ sprint resume.
\`\

The player should not feel nine separate systems.

Each transition should preserve as much as possible:
- direction;
- speed;
- orientation;
- inertia;
- the player's intent;
- body posture.

Avoid:

\```
sprint â†’ stop â†’ jump animation â†’ stop â†’ attack animation.
\`\

Prefer:

\``
sprint impulse â†’ takeoff linked to the stride â†’ body keeps forward momentum â†’ attack uses that momentum â†’ landing absorbs it.
\``

## 2. ACCELERATION AND DECELERATION

Movement should not instantly jump from 0 to max speed, except for explicit special actions such as Shunshin or FTG.

The body should show:
- subtle forward lean during acceleration;
- recovery toward neutral at cruising speed;
- counter-lean and foot planting during direction changes;
- leg and hip absorption during braking.

Keep the feel arcade/anime, not heavy simulation. The goal is believable physical illusion.

## 3. NINJA RUNNING

Running must have:
- cadence that matches actual travel;
- real leg push;
- body orientation that matches speed;
- fighter-specific arm/body language;
- non-snappy direction changes.

Variation by fighter is desirable:
- Minato: light, precise, no wasted motion.
- Itachi: economical, almost no gesticulation.
- Sasuke: aggressive, more body projection.
- Lee: athletic, strong leg pushes.
- Shisui: short bursts and angle changes.
- Zabuza: visible weight because of the cleaver.
- Gaara: much calmer body motion.

## 4. TURNS AND STRAFE

The body should not pivot like a turret.

At high speed:
- slightly wider turn radius or a controlled pivot/slide depending on the fighter.

At low speed:
- more direct rotation.

Strafe should keep attention on the target but use lateral leg work, not a normal forward run rotated 90 degrees.

## 5. JUMP

Do not use Roblox-standard jump feel.

Distinguish:

### Neutral jump
- moderate vertical rise;
- compact body.

### Launched jump
- preserve clear horizontal speed;
- longer trajectory;
- body projected forward;
- link to the previous stride.

### Backward jump
- short hop for low intent;
- backflip for fast/evasive context;
- not a flip every time.

### Side jump
- side hop, side flip or cartwheel-like motion depending on speed and fighter.

Acrobatics must have a purpose:
- evade;
- keep momentum;
- change angle;
- prepare an attack;
- exit a wall;
- cross an obstacle.

## 6. FLIPS AND ACROBATICS

We want real:
- backflips;
- side flips;
- front rotations;
- partial rotations;
- twists;
- wall flips.

But not everywhere.

Trigger based on:
- direction;
- speed;
- height;
- distance to ground;
- wall proximity;
- combat input;
- fighter state.

## 7. CONTEXTUAL ATTACKS DURING MOVEMENT

This is essential.

### Sprint + Light
Do not necessarily stop the fighter. The action can become, depending on the fighter:
- shoulder entry;
- launched punch;
- gliding kick;
- running slash.

### Jump + Forward + Light
The attack should use the existing forward momentum:
- big projected punch;
- dive kick;
- descending blade;
- palm;
- full-body strike.

The feel should be: â€œI was already moving; the attack uses that motion.â€

### Sprint + Heavy
Can use more of the entry inertia and pay for it with more recovery.

### Dodge + Light
Allow immediate flow-into riposte when appropriate.

## 8. MOMENTUM

Add real conservation of partial momentum between:
- run â†’ jump;
- jump â†’ air attack;
- air attack â†’ landing;
- dash â†’ attack;
- wall-run â†’ wall-jump;
- knockback recovery â†’ movement;
- pursuit â†’ attack.

Do not conserve 100% in all cases, but do not reset to an arbitrary fixed value at each state.

Consider:
- incoming velocity;
- direction;
- next action;
- control caps.

## 9. LANDING

Create:

### Small landing
- near instant;
- can flow directly into movement.

### Fast landing after a launched jump
- one or two absorption steps;
- keep the run.

### Heavy landing
- knee compression;
- body absorption;
- short lockout only if the drop justifies it.

### Combat landing
- recovery tied to the air attack;
- preserve orientation toward the enemy.

Never reset to idle between touchdown and the next input if it can be avoided.

## 10. WALL-RUN

The wall-run must feel like an extension of motion.

### Horizontal wall-run
If speed and entry angle are compatible:
- plant the foot;
- lean the body into the wall;
- run parallel;
- gradual speed loss;
- allow wall-jump.

### Vertical wall-run
If the player jumps/moves into a wall:
- several vertical foot plants;
- height depends on entry momentum/resource;
- allow attack, wall-jump or fall.

Avoid snapping to the wall, floating or using a standard run animation vertically.


## 11. WALL-JUMP

From a wall:
- impulse away from the wall;
- preserve part of tangential momentum;
- real body rotation;
- player can steer the exit.

A fast horizontal wall-run should not exit perpendicularly with zero tangential velocity.

## 12. ATTACKS ON/FROM WALLS

Support a simple contextual grammar:
- wall-run + Light;
- wall-jump + Light;
- very short wall contact + attack;
- descending attack from wall.

Use context, not button bloat.


## 13. AIR CONTROL

Allow air correction, but not full aerial steering.

The player can correct the trajectory and aim an attack, but should not rotate 180 degrees instantly in air.

Allow fighter-specific exceptions.

## 14. DODGES

Directions should read differently.

Forward dodge:
- short burst;
- lower center of gravity;
- slip under/off-line.

Back dodge:
- retreat;
- hop or backflip depending on speed/context.

Side dodge:
- shift laterally;
- side-step or side-flip depending on context.

The dodge must really change position, be readable and punishable, and allow select transitions into combat.

## 15. DASH

The standard dash should not be a common red VFX.

The underlying gameplay abstraction can be shared, but the body language should vary:
- Minato: clean, precise burst, subtle afterimage.
- Shisui: partial disappearance, false continuity, angle break.
- Lee: physical explosion.
- Sasuke: aggressive acceleration.
- Itachi: short, sober displacement.
- Gaara: controlled glide supported by sand.
- Haku: ice footing and fine directional changes.
- Zabuza: heavier, more inertial travel.

## 16. CAMERA

The camera should support the sensation, not create it by itself.

Use sparingly:
- small dynamic FOV at high speed;
- framing bias in travel direction;
- clean vertical framing during wall-run;
- short accent on heavy touchdown;
- stable horizon during flips.

No constant shake. Small actions should be quiet.

## 17. BODY / ROOT-MOTION ILLUSION

Even if the game is root-driven, the visual motion must agree with the actual travel.

Avoid:
- root moving while feet do not match;
- instant root rotation;
- foot sliding;
- body travel without pelvic compression/extension.

Use the existing motion architecture to create a root-motion illusion via:
- animation/Motor6D;
- impulse timing;
- orientation;
- stride matching;
- lean;
- anticipation.

## 18. TRANSITIONS â€” TOP PRIORITY

Audit these specifically:
- idle â†’ run;
- run â†’ sprint;
- sprint â†’ jump;
- sprint â†’ Light;
- sprint â†’ Heavy;
- jump â†’ attack;
- attack â†’ air continuation;
- air attack â†’ landing;
- landing â†’ sprint;
- dash â†’ attack;
- dodge â†’ attack;
- jump â†’ wall;
- wall â†’ run;
- wall-run â†’ wZ–Pµ©ÕµÀì(´İ…±°µ©ÕµÀƒŠH…ÑÑ…¬ì(´İ…±°ƒŠHÉ½Õ¹ì(´ÁÕÉÍÕ¥ĞƒŠH…¥È½µ‰¼ì(´­¹½­‘½İ¸½•ĞµÕÀƒŠHµ½Ù•µ•¹Ğ¸()9½¹”½˜Ñ¡•Í”Í¡½Õ±É•…Ñ”„Ù¥Í¥‰±”Á…ÕÍ”°Í¹…À°ÍÕ‘‘•¸½É¥•¹Ñ…Ñ¥½¸¡…¹”°É½½ĞÍÑ½À½È‰½‘äÁ½Í”É•Í•ĞÑ¡…Ğ…¸‰”…Ù½¥‘•¸((ŒŒ€Ää¸=9QaQU05=Y59PI55H()AÉ•™•È„Íµ…±°•¹ÑÉ…°Í•±•Ñ¥½¸±½¥Œ‰…Í•½¸è()qp)ÍÑ…Ñ”€¬¥¹ÁÕĞ€¬Ù•±½¥Ñä€¬‘¥É•Ñ¥½¸€¬ÍÕÉ™…”€¬½µ‰…Ğ½¹Ñ•áĞ)q€()á…µÁ±•Ìè()qp)¥É‰½É¹”€¬½Éİ…É‘Y•±½¥Ñå!¥ €¬1¥¡ĞƒŠH™½Éİ…É…•É¥…°…ÑÑ…¬¸)É½Õ¹‘•€¬MÁÉ¥¹Ñ¥¹œ€¬1¥¡ĞƒŠHÉÕ¹¹¥¹œ1¥¡Ğ¸)]…±±IÕ¸€¬)ÕµÀƒŠHİ…±°©ÕµÀ¸)É½Õ¹‘•€¬	…¬€¬½‘”€¬!¥¡MÁ••ƒŠH‰…­™±¥À¸)¥É‰½É¹”€¬9•…É]…±°€¬Q½İ…É‘]…±°ƒŠHİ…±°½¹Ñ…Ğ¸)qp()¼¹½Ğ‰Õ¥±™¥™Ñä¥Í½±…Ñ•ÍÑ…Ñ•Ì¥˜„½µÁ…ĞÉ…µµ…È…¸•áÁÉ•ÍÌÑ¡”Í…µ”‰•¡…Ù¥½È¸((ŒŒ€ÈÀ¸%!QHAIM=91%Qd()¼¹½Ğµ…­”…±°™¥¡Ñ•ÉÌ•ÅÕ…±±ä…É½‰…Ñ¥Œ¸()	…Í”ÉÕ±•Ì…¸‰”Í¡…É•°‰ÕĞİ•¥¡ĞÑ¡•´è(´1•”èµ½É”™±¥ÁÌ°ÍÑÉ½¹•Èµ½µ•¹ÑÕ´°…Ñ¡±•Ñ¥Œ‰½‘ä¸(´M¡¥ÍÕ¤è™…ÍĞ…¹±”¡…¹•Ì°™…±Í”‘•Á…ÉÑÕÉ•Ì°…™Ñ•É¥µ…•Ì¸(´5¥¹…Ñ¼èÁÉ•¥Í¥½¸…¹±•…¸ÑÉ…¹Í¥Ñ¥½¹Ì¸(´M…ÍÕ­”èÙ•ÉÑ¥…±¥Ñä…¹…É•ÍÍ¥Ù”­¥­Ì¸(´%Ñ…¡¤èµ¥¹¥µ…°µ½Ñ¥½¸°Í¡½ÉĞ•Ù…Í¥½¹Ì¸(´!…­Ôè±¥‘”°™¥¹”™½½Ñ¥¹œ°ÍÕ‰Ñ±”‘¥É•Ñ¥½¸¡…¹•Ì¸(´i…‰Õé„è¡•…Ùä¥¹•ÉÑ¥„°±•ÍÌ…¥É±¥¹”¸(´……É„è…±´‰½‘ä°Í…¹‘½•Ìµ½É”½˜Ñ¡”ÑÉ…Ù•°¸(´9……Ñ¼èµ¥¹¥µ…±¥ÍĞ…¹±•ÍÌ…É½‰…Ñ¥Œ¸(´	•”èµ½‰¥±”‰ÕĞ½¹ÍÑÉ…¥¹•‰ä‰±…‘”½¹™¥ÕÉ…Ñ¥½¹Ì¸((ŒŒ€ÈÄ¸<9=P=YI1=()Q¡”Ñ…É•Ğ¥Ì¹½Ğè(´™±¥ÁÌ½¸•Ù•Éä©ÕµÀì(´Á…ÉÑ¥±•Ì½¸•Ù•Éä‘…Í ì(´Õ¹É•…‘…‰±”ÍÁ••ì(´‘¥Í…ÁÁ•…É¥¹œ•Ù•Éåİ¡•É”ì(´½¹ÍÑ…¹Ğ…µ•É„Í¡…­”ì(´Õ¹ÁÕ¹¥Í¡…‰±”µ½Ù•µ•¹Ğì(´±½¹œ…¹¥µ…Ñ¥½¹ÌÑ¡…ĞÑ…­”…İ…ä½¹ÑÉ½°¸()Q¡”ÅÕ…±¥ÑäÍ¡½Õ±½µ”™É½´Ñ¥µ¥¹œ°ÑÉ…¹Í¥Ñ¥½¸°Á½ÍÑÕÉ”°µ½µ•¹ÑÕ´…¹½¹Ñ•áĞ¸((ŒŒ€ÈÈ¸Y%MU0AQ9()Q¡”µ¥ÍÍ¥½¸¥Ì9=PÍÕ•ÍÍ™Õ°©ÕÍĞ‰•…ÕÍ”ÍÁ••Ù…±Õ•Ì¥µÁÉ½Ù•°„‰…­™±¥À•á¥ÍÑÌ°İ…±°µÉÕ¸İ½É­Ì½È…±°Õ¹¥ĞÑ•ÍÑÌÁ…ÍÌ¸()MÑÕ‘¥¼µÕÍĞÍ¡½Üè((Ä¸„É•‘¥‰±”¹¥¹©„ÉÕ¸ì(È¸ÍÁÉ¥¹ĞƒŠH©ÕµÀİ¥Ñ¡½ÕĞ‰É•…¬ì(Ì¸±…Õ¹¡•©ÕµÀÑ¡…Ğ±•…É±ä­••ÁÌ™½Éİ…Éµ½µ•¹ÑÕ´ì(Ğ¸¹…ÑÕÉ…°‰…­™±¥Àİ¡•¸„‰…­İ…É•Ù…Í¥½¸©ÕÍÑ¥™¥•Ì¥Ğì(Ô¸…É½‰…Ñ¥ŒÍ¥‘”‘½‘”ì(Ø¸©ÕµÀ€¬…ÑÑ…¬Ñ¡…Ğ…ÑÕ…±±äµ…Ñ¡•ÌÑ¡”µ½Ñ¥½¸ì(Ü¸ÍÁÉ¥¹Ğ…ÑÑ…¬İ¥Ñ¡½ÕĞ…ÉÑ¥™¥¥…°ÍÑ½Àì(à¸±…¹‘¥¹œƒŠHÉÕ¸™±½Üì(ä¸É•‘¥‰±”¡½É¥é½¹Ñ…°İ…±°µÉÕ¸ì(ÄÀ¸É•‘¥‰±”Ù•ÉÑ¥…°İ…±°µÉÕ¸ì(ÄÄ¸İ…±°µ©ÕµÀÑ¡…ĞÁÉ•Í•ÉÙ•Ìµ½µ•¹ÑÕ´ì(ÄÈ¸İ…±°µ©ÕµÀƒŠH…ÑÑ…¬ì(ÄÌ¸ÁÕÉÍÕ¥ĞƒŠH…¥È½µ‰¼İ¥Ñ¡½ÕĞµ¥É¼µÁ…ÕÍ”ì(ÄĞ¸…µ•É„ÍÕÁÁ½ÉÑÌİ¥Ñ¡½ÕĞ‘¥ÍÕ¥Í¥¹œ‰½‘äÁÉ½‰±•µÌì(ÄÔ¸¹¼½‰Ù¥½ÕÌ™½½ĞÍ±¥‘”ì(ÄØ¸¹¼‰ÉÕÑ…°É½½ĞÉ½Ñ…Ñ¥½¸ì(ÄÜ¸¹¼Ù¥Í¥‰±”Á½Í”É•Í•Ğ‰•Ñİ••¸…Ñ¥½¹Ì¸((ŒŒ€ÈÌ¸MQU%<QMPƒŠP=9=9Q%9U=ULI=UQ()	Õ¥±„Í¡½ÉĞ½¹Ñ¥¹Õ½ÕÌÑ•ÍĞÉ½ÕÑ”¥¸Ñ¡”ÍÑ…‘¥Õ´¸()Q¡”Í…µ”™¥¡Ñ•ÈµÕÍĞ‰”…‰±”Ñ¼‘¼°İ¥Ñ¡½ÕĞÉ•Í•Ğè()q€)ÍÁÉ¥¹ĞƒŠH¡…¹”‘¥É•Ñ¥½¸ƒŠH±½¹œ©ÕµÀƒŠH…¥È1¥¡ĞƒŠH±…¹‘¥¹œÍÁÉ¥¹ĞƒŠHÍ¥‘”‘½‘”ƒŠHÉÕ¹¹¥¹œ!•…ÙäƒŠH©ÕµÀÑ½İ…Éİ…±°ƒŠHÙ•ÉÑ¥…°İ…±°µÉÕ¸ƒŠHİ…±°µ©ÕµÀƒŠH…¥È…ÑÑ…¬ƒŠH±…¹‘¥¹œƒŠH¡½É¥é½¹Ñ…°İ…±°µÉÕ¸ƒŠH•á¥Ğ™±¥ÀƒŠHÁÕÉÍÕ¥ĞÑ…É•ĞƒŠH…¥È½µ‰¼ƒŠHÉ½Õ¹É•½Ù•Éä)q€()]…Ñ Ñ¡”•¹Ñ¥É”Í•ÅÕ•¹”¸¼¹½ĞÙ…±¥‘…Ñ”•… µ•¡…¹¥Œ½¹±ä¥¸¥Í½±…Ñ¥½¸¸()Q¡”ÁÕÉÁ½Í”¥ÌÑ¼Í•”İ¡•Ñ¡•ÈÑ¡”µ½Ù•µ•¹ĞÍåÍÑ•µÌ™±½Ü¥¹Ñ¼½¹”…¹½Ñ¡•È¸((ŒŒ€ÈĞ¸Q!9%0=9MQI%9QL()AÉ•Í•ÉÙ”è(´ÕÉÉ•¹Ğ½µ‰…ĞÍÑ…‰¥±¥Ñäì(´½µ‰¼½¹™¥Éµ…Ñ¥½¸¥¹Ù…É¥…¹ÑÌì(´Í•ÉÙ•È…ÕÑ¡½É¥Ñä™½È½µ‰…Ğì(´•á¥ÍÑ¥¹œÍåÍÑ•µÌÑ¡…Ğ…±É•…‘äİ½É¬ì(´Á•É™½Éµ…¹”ì(´Í¥µÁ±”­•å‰½…É½½¹ÑÉ½±±•È¥¹ÁÕÑÌ¸()Õ‘¥Ğ™¥ÉÍĞè(´µ½Ù•µ•¹Ğ½¹ÑÉ½±±•Èì(´µ½Ñ¥½¸•¹¥¹”ì(´‘…Í ½‘½‘”ì(´©ÕµÀì(´ÁÕÉÍÕ¥Ğì(´İ…±°¥¹Ñ•É…Ñ¥½¹Ìì(´…µ•É„ì(´™¥¡Ñ•ÈµÍÁ•¥™¥Œµ½Ñ¥½¸‘…Ñ„¸()¼¹½ĞÉ•…Ñ”„Í•½¹±½½µ½Ñ¥½¸•¹¥¹”¥˜Ñ¡”•á¥ÍÑ¥¹œ½¹”…¸‰”•áÑ•¹‘•±•…¹±ä¸((ŒŒ€ÈÔ¸AI%=I%Qd=IH((Ä¸±½½µ½Ñ¥½¸½¹Ñ¥¹Õ¥Ñäì(È¸µ½µ•¹ÑÕ´ì(Ì¸©ÕµÀ…¹±…¹‘¥¹œì(Ğ¸‘½‘”…¹‘…Í ì(Ô¸İ…±°µÉÕ¸…¹İ…±°µ©ÕµÀì(Ø¸½¹Ñ•áÑÕ…°…ÑÑ…­Ì¥¸µ½Ù•µ•¹Ğì(Ü¸ÑÉ…¹Í¥Ñ¥½¹Ìì(à¸…µ•É„ì(ä¸™¥¡Ñ•ÈµÍÁ•¥™¥Œ•áÁÉ•ÍÍ¥½¸ì(ÄÀ¸Y`Á½±¥Í ¸()¼¹½ĞÍÑ…ÉĞİ¥Ñ Y`¸((ŒŒ€ÈØ¸%!QHµMA%%Y% Q	1()¼¹½Ğµ…­”•Ù•Éä™¥¡Ñ•ÈÑ¡”Í…µ”¸UÍ”Ñ¡”½µµ½¸±½½µ½Ñ¥½¸É…µµ…Èİ¥Ñ ™¥¡Ñ•ÈµÍÁ•¥™¥Œ•áÁÉ•ÍÍ¥½¸¸((´5¥¹…Ñ¼èÁÉ•¥Í”°±¥¡Ğ°±•…¸°¹¼İ…ÍÑ••ÍÑÕÉ”¸(´%Ñ…¡¤èÍµ…±°µ½Ñ¥½¹Ì°…±´°…¹‘•±¥‰•É…Ñ”¸(´M…ÍÕ­”èÙ•ÉÑ¥…°°­¥¬µ‘É¥Ù•¸°…É•ÍÍ¥Ù”¸(´M¡¥ÍÕ¤èÉ…Á¥…¹±”‰É•…­Ì…¹Í¡½ÉĞ‘¥Í…ÁÁ•…É…¹•Ì¸(´1•”è¡¥ Á¡åÍ¥…°µ½µ•¹ÑÕ´…¹…É½‰…Ñ¥Œ‘•¹Í¥Ñä¸(´!…­ÔèÍ±¥‘”°Íµ…±°™½½Ñ¥¹œ¡…¹•Ì°±¥¡Ğ…¥È¸(´i…‰Õé„è¥¹•ÉÑ¥…°°É½Õ¹‘•°İ•¥¡Ğµ±•¸(´……É„è…±´°Í…¹µÍÕÁÁ½ÉÑ•°µ¥¹¥µ…°‰½‘ä•Á•¹‘¥ÑÕÉ”¸(´9……Ñ¼èÍ¡½ÉĞ•ÍÑÕÉ•Ì°±½Ü…É½‰…Ñ¥Ì¸(´	•”èµ½‰¥±”‰ÕĞ‰½‘ä…İ…É”½˜‰±…‘”½¹™¥ÕÉ…Ñ¥½¹Ì¸((ŒŒ€ÈÜ¸<9=P1%4MUML]%Q!=UP!U580()ÕÑ½µ…Ñ•Á…ÍÍ•Ì…É”¹½Ğ•¹½Õ ¸()½È•… µ…©½È…Ñ•½Éä°…Í¬è()q€)½•Ì½ÕÈÙ•ÉÍ¥½¸¹½Ü™••°½µÁ…É…‰±”¥¸½¹Ñ¥¹Õ¥Ñä…¹‰½‘ä™±½Ü°•Ù•¸¥˜Ñ¡”•á…Ğ…¹¥µ…Ñ¥½¸¥Ì‘¥™™•É•¹Ğıq¹q€()5¥¹¥µÕ´…Ñ•½É¥•Ìè(´ÍÁÉ¥¹Ğì(´‘¥É•Ñ¥½¸¡…¹”ì(´©ÕµÀµ½µ•¹ÑÕ´ì(´‰…­İ…É‘½‘”½‰…­™±¥Àì(´Í¥‘”µ½Ù•µ•¹Ğì(´ÉÕ¹¹¥¹œ…ÑÑ…¬ì(´©ÕµÀ…ÑÑ…¬ì(´±…¹‘¥¹œì(´İ…±°µÉÕ¸ì(´İ…±°µ©ÕµÀì(´İ…±°•á¥Ğì(´ÁÕÉÍÕ¥Ğì(´…¥È½µ‰¼ÑÉ…¹Í¥Ñ¥½¸¸((ŒŒ€Èà¸1%YI1	()ĞÑ¡”•¹É•Á½ÉĞè(´•á…ĞÍåÍÑ•µÌµ½‘¥™¥•ì(´‰•™½É”½…™Ñ•È™½È•… µ…©½ÈÁÉ½‰±•´ì(´MÑÕ‘¥¼Í•ÅÕ•¹”ÕÍ•™½ÈÙ…±¥‘…Ñ¥½¸ì(´™¥¡Ñ•ÉÌ…ÑÕ…±±äÉ•Á±…å•ì(´É•µ…¥¹¥¹œ™±…İÌì(´Ñ¡”½µµ¥Ğ¡Ì¤Ñ¡…Ğ…ÉÉäÑ¡”İ½É¬¸()¼¹½Ğ½¹Í¥‘•ÈÑ¡”µ¥ÍÍ¥½¸‘½¹”©ÕÍĞ‰•…ÕÍ”…ÕÑ½µ…Ñ•Ñ•ÍÑÌÁ…ÍÌ¸()Q¡”™¥¹…°Ñ…É•Ğ¥Ì„™••°½˜…¸•áÑÉ•µ•±äµ½‰¥±”¹¥¹©„İ¡•É”Ñ¡”‰½‘ä°µ½Ù•µ•¹Ğ…¹½µ‰…ĞÉ•……Ì„Í¥¹±”½¹Ñ¥¹Õ½ÕÌÁ¥•”½˜µ½Ñ¥½¸¸(