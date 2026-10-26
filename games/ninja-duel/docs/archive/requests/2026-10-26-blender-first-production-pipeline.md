# OVERRIDE — BLENDER-FIRST PRODUCTION PIPELINE

Date: 2026-10-26
Priority: ACTIVE NOW.

The project has reached the point where visible quality is the bottleneck. From now on, **Blender is the default production tool for anything that benefits from authored 3D animation or custom 3D assets**. Do not keep sculpting complex combat presentation only with Luau Motor6D poses when Blender can produce a better result.

This applies to the whole game, not only Sasuke and Minato.

## Simple rule

Use Blender by default for:
- signature combat animations;
- jutsu preparation/release animations;
- hand/body choreography;
- jumps, flips, wall exits and special movement clips;
- hit reactions, heavy reactions, wall impacts, falls, rolls, knockdowns and get-ups;
- weapon/tool handling animations;
- character-specific stances and transitions when they matter visually;
- kunai, blades, bones, props and other custom meshes;
- destructible environment assets and their broken states;
- rocks, walls, pillars, arena pieces and debris meshes;
- custom meshes that improve VFX silhouettes or major attack readability.

Use Roblox/Luau for:
- hit detection;
- damage;
- physics and root motion ownership;
- chakra/resource logic;
- contextual decisions;
- player freedom and input;
- projectile simulation;
- world interaction rules;
- networking/server authority;
- dynamic particles, trails, lighting, camera and sound where Roblox is the better runtime tool.

**Blender must improve presentation, not replace gameplay freedom.** Never turn the game into `press button -> locked animation -> damage -> recovery` just because an animation was authored externally.

## Required hybrid model

The target pipeline is:

`Blender-authored body/asset quality + Roblox gameplay/physics/context + Roblox VFX/camera/SFX`

Example — Chidori:
1. Blender gives Sasuke a premium formation animation, hand/shoulder/body weight and clean transitions.
2. Roblox then owns the sustained Chidori state: movement, steering, run, jump, wall, aim, miss, world collision.
3. Blender-authored contextual release/reaction clips can be used where useful, but they must inherit the actual gameplay trajectory.
4. Roblox handles lightning particles, collision, damage, destruction, hitstop, camera and sound.

Example — receiving a heavy hit:
1. Roblox computes contact direction, force, velocity, wall/world contact and damage.
2. Select/blend an appropriate Blender-authored reaction family.
3. Keep the body physically consistent with the computed trajectory instead of teleporting into a canned reaction.

## Whole-roster requirement

This is the intended production pipeline for **all fighters**, not an experiment reserved for two characters.

Every fighter should eventually receive a proper authored animation library matching their identity. Examples:
- Sasuke: Chidori, Katon, projectile/wire handling, Sharingan states, signature taijutsu.
- Minato: kunai throws, FTG arrivals/exits, Rasengan, economical spatial taijutsu.
- Itachi: fire, shuriken, crow/deception transitions, genjutsu body language.
- Lee: explosive physical mastery, gates, kicks, landings.
- Kimimaro: bone extraction/use and body-as-arsenal choreography.
- Haku: senbon and mirror/ice movement.
- Zabuza: cleaver momentum and heavy body mechanics.
- Gaara: sand-directed body language instead of generic boxing.

Do not attempt to finish all 20 at once. The current Sasuke/Minato slice remains first, but **build it using the production method we intend to reuse for everyone**.

## Immediate instruction

Before adding more hand-authored complex Luau poses, inspect whether Blender should produce the source animation/mesh instead.

If Blender is available on the workstation, use it now. If it is not installed/configured, set up a practical Blender -> Roblox import workflow before continuing the next major animation-production pass.

Start with Sasuke and Minato. Replace or supplement the weakest code-only signature animation paths with Blender-authored clips, then validate them inside the actual free gameplay system in Studio.

Do not throw away good current systems. Keep ActionContext, BodyState, world reactions, chakra, projectiles, movement and the useful continuity fixes. Blender is the **quality layer on top of those systems**.

## Acceptance

The pipeline is working only if the visible result materially approaches the mandatory Itachi benchmark video at:

`games/ninja-duel/reference/itachi-quality-benchmark.mp4`

The desired reaction is not “the animation system is technically better.” It is:

> “This character looks professionally animated, every attack feels intentional, impacts read properly, and I no longer see the underlying systems fighting each other.”

Use Blender aggressively wherever it meaningfully raises that visible quality. Do not use it blindly for things Roblox handles better at runtime.
