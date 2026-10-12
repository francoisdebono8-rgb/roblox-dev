# Claude — Arena Scale, Combo Freedom & Ninja Spectacle Pass

Work from the latest state of `claude/minato-itachi-final`. Do not undo the movement-system improvements already in progress. This pass should push the game toward a real Naruto-style ninja duel: larger scale, more reason to move, richer combat inputs, clearer combo identities, stronger physical reactions, broader projectile/jutsu freedom, and a fourth playable prototype.

## 1. Fix scale and use of space

The arena still feels too small relative to the fighters. Increase the physical sense of scale.

Goals:
- Fighters should feel smaller relative to the arena walls and structures.
- Increase meaningful combat distances.
- Make crossing the arena require actual running/sprinting rather than constant small circles near center.
- Keep walls relevant, but not so close that every exchange immediately becomes wall combat.
- Preserve wall-run/wall-tech systems while creating enough space for pursuit, ranged play, teleport routes, projectile setups and long approaches.
- Re-evaluate camera framing/FOV as the scale changes so fighters remain readable at long range.

The arena should encourage phases of:
- long-range probing,
- running/repositioning,
- mid-range ninja tools,
- close taijutsu,
- wall/aerial sequences.

Do not solve this only by making the floor larger. Rebalance movement speed, sprint usefulness, camera framing, projectile ranges and AI spacing so the larger arena actually changes gameplay.

## 2. Make sprinting and directional movement matter

Right now the fight too easily collapses into circling in the middle.

I want moments where the player genuinely needs to run:
- chase a retreating opponent,
- reach a marked kunai/seal,
- reposition around terrain,
- create distance,
- close distance after a projectile exchange,
- pursue after launch/knockback,
- attack from a wall or elevated route.

Movement should still preserve target awareness without forcing unnatural strafe behavior. At higher lateral/diagonal speed, let the body actually run in the chosen direction while head/torso/aim keeps awareness of the opponent.

## 3. Replace shallow combo feel with a directional combo grammar

The current combos are still too few and too visually similar. Build a clearer input grammar that is easy to understand but creates many routes.

Use this idea as the base, especially for controller:
- repeated attack inputs + directional intent change the branch;
- e.g. 3 light attacks + UP => launcher;
- 3 light attacks + DOWN => downward/slam route if context allows;
- 2 light attacks + LEFT/RIGHT => grab/chop/side-route or character-specific branch;
- neutral string => standard grounded route;
- airborne directional input => different aerial follow-up;
- wall proximity can unlock wall-specific finishers/branches.

Do not copy these examples mechanically if a better input design works. The important goal is:
- easy base inputs,
- directional branches,
- distinct animations,
- multiple combo routes,
- visually obvious difference between routes,
- character-specific interpretation of the same grammar.

The player should be able to improvise rather than memorize one optimal string.

## 4. Make each fighter's taijutsu unmistakable

The same combo grammar must produce different martial identity.

### Minato
- concise, efficient striking;
- explosive angle changes;
- teleport-assisted pursuit;
- kicks/palms/kunai transitions;
- very little wasted motion;
- airborne teleport continuation should feel spectacular but controllable.

### Itachi
- calm, precise, deceptive;
- shuriken/kunai integrated inside taijutsu routes;
- short counters, feints, redirects;
- deceptive projectile angles;
- can use tools to force movement before entering close range.

### Neji
- Gentle Fist identity first;
- palm chains, body control, rotations, sweeps;
- very different rhythm from Minato/Itachi;
- visually technical even without jutsu.

No fighter should look like the same base brawler with different effects.

## 5. Physical reactions to hits

Every hit must visibly affect the opponent's body.

Examples:
- first punch turns head/shoulder;
- second hit can rotate torso/step the victim back;
- launcher visibly transfers weight and sends the body upward;
- kicks can twist hips/ribs;
- sweep actually removes the base of support;
- heavy hit causes a distinct stagger/rotation;
- wall hit compresses body before rebound;
- aerial hit changes trajectory.

The fantasy should become:
`right hand -> opponent's head snaps -> second strike -> launcher -> pursue/teleport -> aerial chain -> wall/ground finish`

Do not rely on particles to communicate impact. Body reaction comes first, FX second.

## 6. More spectacular transitions and ninja sequences

Add/improve transitions that make the player feel technically exceptional:
- ground -> launcher -> aerial pursuit;
- aerial exchange -> teleport/reposition -> continuation;
- ground -> wall splat -> wall follow-up;
- throw/projection -> pursuit;
- dodge -> counter route;
- clash -> advantage/escape decision;
- attack from wall-run;
- aerial down-smash;
- side-switching during combo;
- character-specific combo finishers.

These should remain player-controlled enough that the game does not become a cutscene fighter.

## 7. Broaden ninja-tool and projectile freedom

Ninja tools are a **shared baseline system**, not an Itachi-only mechanic.

All relevant fighters should be able to use basic ninja tools such as kunai/shuriken where it makes sense for the character and age. This should become part of the universal combat language of the game, like movement, guard or taijutsu.

Then differentiate characters by **how good they are with those shared tools** and by what special interactions they unlock.

Examples:
- any fighter can throw a basic kunai/shuriken;
- Minato is special because of marked kunai, seals, teleport routing and angle creation;
- Itachi is naturally more advanced with shuriken/kunai precision, deception, ricochets, delayed trajectories, forced dodges and projectile combo integration;
- Sasuke can also have strong shuriken/kunai usage, but with a more aggressive/younger style;
- Neji can use standard tools, but they should remain secondary to Gentle Fist and space control.

For Itachi specifically, it is fine to give him one or more **character-specific techniques or enhanced tool interactions** that prove he is better with ninja tools than the baseline roster, for example:
- two projectiles colliding/redirecting into a new trajectory;
- ricochet/deflection setups;
- delayed second blade aimed at a dodge;
- projectile feint into taijutsu;
- projectile inside a combo route;
- aerial multi-angle throws;
- special shuriken pattern as an actual move/technique.

But do **not** make basic kunai/shuriken exclusive to Itachi.

The broader goal is to make ninja tools part of a deep fighting system instead of a single ranged button, while character mastery changes what each fighter can do with the same baseline tools.

Do not over-engineer final balance yet. A later dedicated character-balance/loadout system will revisit exact move lists, power, cooldowns and roster balance. For now, prove the shared-tool foundation and character-specific mastery differences.

## 8. Fourth playable prototype

Add a fourth prototype fighter: **young Sasuke (around 12–13)**.

This is a prototype, not Minato/Itachi-level depth.

Target identity:
- fast Uchiha prodigy;
- more aggressive than Itachi;
- strong taijutsu base;
- fire style;
- good shared shuriken/kunai usage;
- early Sharingan if useful to gameplay;
- lightning/Chidori only if it fits the intended age/power rules and does not turn him into an adult/endgame kit.

Give him:
- distinct idle/movement language;
- at least one clearly different grounded combo route;
- launcher/aerial route;
- one stronger-than-baseline ninja-tool interaction;
- 2–4 prototype techniques;
- enough AI/UI/costume support to fight the other three.

Do not spend the whole pass polishing Sasuke. He is there to prove the combat framework can support a fourth distinct fighter.

## 9. Keep improving speed and animation fluidity

Continue the human-movement fix. The game still needs more speed, clarity and continuity.

Check especially:
- fast punches/kicks;
- transitions between strikes;
- body orientation during lateral/diagonal movement;
- run-to-attack transitions;
- launcher -> pursuit;
- aerial strings;
- teleport re-entry;
- camera during high-speed exchanges;
- no visible snap/position jump/body-part catch-up.

Aim for the readability/continuity spirit of Storm 4, not a copy and not the same animation fidelity. Keep our game more freeform with a broader player-controlled arsenal.

## 10. Bug and feel sweep

Before delivery, run complete playtests across all available fighters and major systems:
- character select;
- intro;
- long-range movement;
- sprint;
- lock-on;
- all directional combo branches;
- grabs/projections;
- launcher/aerial/slam;
- walls/wall-run/wall-tech;
- substitutions;
- shared ninja tools;
- character-specific projectile/tool interactions;
- teleports;
- jutsu;
- KO/results;
- rematch;
- all current AI matchups.

Fix any crash, stuck state, camera break, invisible hit, impossible input state, snap, obvious foot sliding or bad transition you encounter.

## 11. Delivery

Deliver this as a new playable checkpoint on the same branch:
- commit + push all work;
- rebuild `games/ninja-duel/dist/NinjaDuel.rbxlx`;
- rebuild QA artifact;
- keep the public/shared access path usable from Mac and PC;
- if the Roblox Experience is already publishable from your authenticated Studio session, update the public test build too;
- short report only: what changed, what remains visibly weak, any known bugs.

Priority order if time becomes limited:
1. arena scale + meaningful running;
2. directional combo grammar and hit reactions;
3. speed/animation/camera continuity;
4. shared ninja-tool foundation + character-specific mastery;
5. fourth fighter prototype Sasuke;
6. arena polish.

Success criterion: even before using a flashy jutsu, the player should feel like they are controlling a highly skilled young ninja in a large arena, with freedom to run, angle, launch, pursue, throw tools, fight in the air and create visibly different combo routes.