# Mission V0.2 — Combat Feel First

## Why this mission exists
The first playable render proved that the basic plumbing can exist, but it does **not yet feel like the game we want**. Current symptoms reported from playtesting: locomotion is stiff, fight movement is not fluid, animations are weak, jumps feel like ordinary Roblox jumps, and the experience currently reads as a character with a chakra bar plus three abilities rather than a high-speed ninja duel.

Do not add roster breadth yet. Treat the existing build as technical scaffolding and now make the moment-to-moment play feel compelling.

## North-star references
Use **Naruto Ultimate Ninja Storm** as a reference for combat spectacle, pursuit, camera energy, character acceleration, attacks carrying bodies through space, evasive repositioning and the feeling that combatants are superhumanly agile.

Use **Ninja Time (Roblox)** as a reference for how a Roblox ninja game can make traversal/movement itself enjoyable and larger-than-normal Roblox movement feel natural.

These are feel references, not instructions to copy code/assets/animations/UI/content. Keep implementation and shipped content original.

Our differentiator remains the tactical layer: chakra, interruptible techniques, setup, counters, marks, perception/genjutsu, matchup knowledge and techniques that must be earned/executed during the fight rather than merely fired from a hotbar.

## Priority order
For this mission, optimize in this order:
1. locomotion and responsiveness;
2. combat movement/target engagement;
3. animation quality and transitions;
4. camera;
5. hit feel/impact;
6. aerial movement and pursuit;
7. techniques and character identity;
8. AI adapting to the new movement;
9. UI polish last.

If running, jumping, dodging and hitting a target for 30 seconds is not already enjoyable, the mission is not done.

## Movement target
Replace ordinary Roblox-feeling locomotion with a coherent ninja locomotion controller. Tune rather than blindly use these values, but target a clearly superhuman scale.

Required sensations/capabilities:
- responsive acceleration/deceleration rather than robotic instant WalkSpeed changes;
- fast combat run/sprint with strong directional control;
- large ninja jump with materially more height/distance than default Roblox;
- variable or otherwise controllable jump if it improves feel;
- useful air control;
- ground directional dash;
- lateral combat dash around a locked target;
- at least one aerial evasive/mobility action;
- satisfying landing with short recovery only when appropriate;
- no constant sticky friction feeling;
- preserve responsiveness while attacking;
- attacks may carry the attacker forward when appropriate;
- ability to rapidly close modest distance without simply teleporting every fighter;
- movement should remain readable in a 1v1.

Prototype optional movement only if it materially improves play: short wall interaction/wall run, wall jump, rebound, chakra-assisted leap. Do not let optional traversal consume the mission before core movement is excellent.

Movement must be compatible with future PvP/network authority. Avoid fragile client-only physics hacks that will become impossible to reconcile later.

## Lock-on and spatial combat
Implement/refine a target-lock combat mode suitable for 1v1. While locked:
- movement becomes relative to target/camera where appropriate;
- lateral movement naturally circles the opponent;
- camera maintains both combatants without constant manual correction;
- forward pressure closes distance cleanly;
- dodge direction follows input;
- attacks can use conservative facing assistance/magnetism, never giant auto-teleports;
- losing/reacquiring lock is predictable.

The desired feeling is that both fighters continuously contest **angle, distance and timing**.

## Basic melee must become a movement system too
The basic combo cannot be a stationary Roblox punching sequence.

Create a polished prototype melee chain with authored timing:
- clear anticipation/startup;
- forward body travel on appropriate strikes;
- distinct hit reactions;
- at least 4 visually distinct chain beats or equivalent variation;
- final hit with controlled knockback/launch;
- possibility to chase/pursue after a launch;
- sensible combo reset;
- whiff recovery;
- interruption rules;
- directional influence if feasible;
- air-compatible follow-up if it feels reliable.

Avoid permanent stun locks. The defender must eventually regain agency.

## Aerial combat
At minimum prove the loop:
large jump -> air control -> attack/engage -> aerial dodge or reposition -> landing/recovery.

If a grounded combo launches the opponent, allow a readable pursuit/follow-up mechanic. It should look spectacular without becoming an automatic uninteractive cutscene.

## Animation bar
Animation is now a gameplay requirement, not decoration.

The player should no longer look like a default Roblox avatar executing generic actions. Build or source only legitimate/original animation assets/workflows. Do not rip anime/game animations.

Need coherent animation coverage for at least:
- idle combat stance;
- forward run/sprint;
- strafe left/right or convincing blending;
- backward movement;
- jump takeoff;
- airborne pose/fall;
- landing;
- dash/evasion;
- guard;
- hit reactions;
- melee chain;
- technique startup/channel;
- technique release/recovery;
- defeat.

Transitions matter almost as much as individual clips. Prevent snapping back to idle between rapid actions. Use priorities/blending and animation-state ownership cleanly.

If high-quality authored animations cannot be created entirely from repository code, build the best procedural/placeholder system possible and document the exact Studio animation work required. Do not pretend poor placeholders satisfy this section.

## Camera and impact
Camera should sell speed without making players nauseous.

Add/tune:
- combat framing for two fighters;
- speed-sensitive FOV changes kept restrained;
- short camera impulses/shake for meaningful hits only;
- stronger impact on combo finisher/technique;
- brief hit-stop or equivalent impact pause where technically safe;
- trails/impact VFX synchronized to actual active frames;
- sound hooks even if final audio assets are not ready.

A hit should be readable from animation + reaction + VFX + camera + sound hook, not damage numbers alone.

## Keep and integrate the tactical systems
Do not throw away working chakra/cooldown/interrupt/state/server validation code. Refactor only where necessary so it participates naturally in the new movement system.

Strong techniques remain commitments. A fighter who starts a powerful technique at a stupid moment should be punishable/interrupted.

## Character implementation policy
For V0.2 we want two prototype characters based directly on **young Minato Namikaze** and **young Itachi Uchiha** as internal design references so we can test the fantasy accurately. Treat the detailed character sheets in `CHARACTER_REFERENCE.md` as a design pool, not a requirement to cram every listed ability into V0.2.

For any public/commercial release, these references must be transformed into sufficiently original characters, names, designs, lore, symbols, animations and techniques. Do not import copyrighted models, textures, audio, animations or ripped assets now.

Pick a coherent subset of each sheet that best proves their contrast. If a character-sheet detail conflicts with good gameplay or with the chosen 12–14 version, flag it and choose the more credible version.

## AI update
The bot must understand the new locomotion enough to be a useful sparring opponent:
- sprint/close distance;
- circle/strafe;
- use ground dodge;
- react imperfectly to attacks;
- pursue after appropriate knockback;
- use jump/aerial movement sometimes, not constantly;
- preserve human-like reaction delay;
- use each character's identity rather than the exact same decision weights.

Do not spend excessive time making a tournament-grade AI before human movement feels good.

## V0.2 acceptance experience
A tester should be able to launch a duel and immediately notice, before inspecting UI, that this is no longer default Roblox locomotion.

Within one minute they should naturally be able to:
- sprint around the arena;
- make a large ninja jump;
- control themselves in air;
- dash toward/around/away from the opponent;
- lock onto the opponent;
- execute a moving melee chain;
- launch or knock the opponent away;
- pursue at least some knockbacks;
- dodge a retaliation;
- start a special technique and potentially be interrupted;
- feel visibly different playing the two prototype characters.

## Collaboration
Inspect the current implementation before replacing systems. Reuse good foundations. If a consequential technical choice would constrain future PvP, animation pipeline, character expansion or networking, ask François before locking it in. Bundle questions.

Do not ask permission for ordinary implementation choices. Execute end-to-end after consequential questions are resolved.

## Definition of done
This mission is not complete merely because all controls exist.

It is complete when:
- locomotion visibly and mechanically feels superhuman and responsive;
- large jumps and combat dashes are useful;
- melee no longer looks/feels stationary;
- animation transitions are substantially improved;
- camera and impacts communicate speed/weight;
- existing chakra/technique/interruption gameplay still functions;
- Minato-reference and Itachi-reference fighters have clearly different loops;
- the AI can participate in the revised combat;
- rematch/reset remains reliable;
- the build is ready for François to answer the question: **'Is moving and fighting already fun enough that I want another match?'**

At completion, report what changed, what was actually tested, what still looks placeholder-quality, and the 3 highest-impact improvements you would make next.