# Claude Mission — Minato vs Itachi Final Combat Pass

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

Take the existing project from a technically solid prototype to the first genuinely convincing **Naruto-like Minato vs Itachi combat slice**.

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
- play both fighters and reproduce the important combat routes yourself.

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
- attack immediately after teleport;
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

The player should be able to understand a Minato teleport instead of losing track of the fight.

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

---

# 15. Testing requirements

Run automated tests after relevant code changes, but also perform real Studio testing repeatedly.

At minimum validate full routes for both characters.

## Minato

- run/strafe/jump/wall movement;
- melee string;
- launcher/chase/aerial route;
- kunai throw;
- marked kunai teleport;
- immediate follow-up after teleport;
- jutsu;
- defense/recovery.

## Itachi

- movement;
- melee string;
- launcher/aerial route;
- shuriken;
- fireball;
- mirage/deception tools;
- defense/recovery.

Play multiple full fights.

Also watch at least one full fight while deliberately ignoring the HUD and judge whether the action itself communicates what is happening.

Do not call the pass finished until the visual result is meaningfully better than the starting build.

---

# 16. Priorities if tradeoffs are required

1. Combat bugs / jump / aerial combo reliability
2. Animation quality
3. Real Minato kunai
4. Real Itachi shuriken
5. Fireball and major jutsu presentation
6. Minato teleport/aura identity
7. Ninja Storm-inspired combat flow
8. Camera
9. Arena / Naruto atmosphere
10. General polish

Prioritize what the player can **see and feel** over speculative refactors.

---

# 17. Do not restart the foundations

The project already has substantial systems for:

- combat;
- movement;
- networking;
- Minato;
- Itachi;
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

The target is that a 20–30 second clip of the duel begins to look like an actual game somebody would want to try.

We should visibly see:

- fighters running and turning naturally;
- arms and legs driving attacks;
- convincing melee strings;
- launchers and aerial pursuit that do not bug;
- a real kunai leaving Minato's hand;
- real Itachi shuriken;
- Minato teleporting around a fight in a readable way;
- a convincing traveling fire technique;
- proper impacts and reactions;
- better camera framing;
- a more Naruto-like arena and atmosphere;
- faster, smoother, more anime-like flow.

Before: **Roblox combat prototype.**

After: **first convincing Minato vs Itachi Naruto-like vertical slice.**

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
