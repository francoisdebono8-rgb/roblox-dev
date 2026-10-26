# OVERRIDE — MAKE THE GAME FEEL LIKE THE REFERENCE

Date: 2026-10-26
Priority: HIGHEST.

## The target is simple

The supplied Itachi video is now the visual/gameplay quality bar.

Do **not** copy that Itachi moveset or its exact animations. Copy the **level of care, logic, style and detail**.

In that video, Itachi looks exceptional. His attacks make sense for him, every technique has its own identity, his body actually performs the move, the opponent reacts correctly, the VFX support the action, and the techniques can change range, rhythm, position and situation. It does not feel like the same generic melee game with different colored powers.

That is what we want.

Our current build is still far below that feeling.

## Stop doing this

Until Sasuke and Minato reach that level:

- stop spreading work across the whole roster;
- stop adding large abstract systems just because they are technically clean;
- stop counting tests/architecture as visible progress;
- stop making a technique as `animation + effect + damage + cooldown`;
- stop falling back constantly to `3 hits -> launcher -> chase -> air combo`;
- stop accepting a result because it is technically better if it still looks almost the same in Studio.

Keep the good systems and ideas already built. Do not revert useful work. Use them to finally create a much better visible game.

## What every important ability must feel like

A good ability should feel like something the ninja can actually DO, not a button that plays a packet.

For each important ability, make the whole action coherent:

**preparation -> body movement -> release/use -> opponent/world consequence -> follow-through -> clean return to control**

And when the fantasy supports it, the player should be able to use the same capability in different logical ways: while moving, in the air, from a wall, held, released later, recast, cancelled, aimed differently, or combined with another tool.

Not every power needs every variant. Every variant must make sense.

Hit, miss and block must all look intentional. Missing must be a real miss. Hitting the world must matter when it logically should.

## SASUKE

For three minutes, controlling Sasuke must feel like controlling SASUKE, not a martial artist with four jutsu slots.

His game should naturally mix:

- short taijutsu exchanges;
- shuriken/kunai;
- wire as a real spatial tool;
- Katon with different logical uses, not one identical cast every time;
- Sharingan that actually changes how the player reads combat;
- Chidori as a real capability carried by the body.

The Chidori remains one of the clearest examples of the target: Sasuke forms it, can move with it, run with it, jump with it, use it from/after a wall, plunge with it, steer within reasonable limits, genuinely miss, continue through the miss, and hit/break relevant scenery. No 360-degree homing. The body, speed, arm, VFX and impact must all agree.

But do not focus only on Chidori. **Every major Sasuke action must receive the same care.**

## MINATO

Minato must feel equally exceptional but completely different.

His fight should naturally be built around:

- real kunai throws;
- marked kunai that stay useful in the battlefield;
- throwing while moving/jumping when logical;
- teleporting to marks and useful kunai positions;
- using old placements later in the fight;
- teleport feints and angle changes;
- Rasengan treated as a dangerous capability with proper body movement, hit/miss and continuation;
- fast, economical taijutsu that connects his spatial decisions instead of replacing them.

Flying Thunder God must not simply be `teleport -> free hit`. The teleport changes the situation; the player should still own the next decision unless a specific committed action was chosen.

## The most important feeling

When I pick a character, I want to think:

**"For the next three minutes I am an exceptional ninja. I have insane abilities. How am I going to use all of this to beat this opponent?"**

I do NOT want to think:

**"Which of my three combos do I do now while my jutsu comes off cooldown?"**

Melee remains useful, but it cannot remain the backbone of almost every exchange.

The player should create sequences because the tools and powers combine logically, not because we scripted one long guaranteed combo.

## The reference-level detail we expect

Use the Itachi video as the direct comparison while working in Studio.

The target is the same feeling of:

- stylish, readable body animation;
- attacks that look logical for the character;
- strong anticipation and follow-through;
- powers with their own rhythm and geometry;
- clean, impressive VFX without hiding bad movement;
- convincing reactions from the opponent;
- good smoke/dust/impact/aftermath where appropriate;
- techniques that can create another decision after activation;
- transitions that do not visibly expose game states;
- character identity visible even without UI.

Do not underplay powers. These are superhuman ninjas. Important actions must look and feel powerful.

## Fix the visible bugs at the same time

The reference quality is impossible while our movement still visibly cuts.

Do not leave obvious:

- jump/takeoff cuts;
- jump -> attack snaps;
- launcher -> pursuit cuts;
- pursuit -> air attack cuts;
- magnetic tracking;
- body hover used to keep a combo alive;
- bad landings;
- pose snaps;
- feet sliding on important contacts;
- sudden facing changes that are not real teleport powers;
- camera obstruction;
- VFX that do not match the exact physical contact.

If a movement looks wrong at normal speed, fix the real cause. Do not hide it with more effects.

## Work method

Work in Studio, action by action, with real controls.

For every important action, LOOK at it. Do not only inspect code/tests.

Compare it to the supplied Itachi reference and ask one question:

**"Does this action have the same level of care and character fantasy?"**

If the answer is no, keep working on it.

Use our existing good ideas: free movement, contextual actions, held Chidori, reactive world, chakra, persistent objects, better defense, etc. They are foundations, not the final result.

## Deliverable before returning to the rest of the roster

First make Sasuke feel finished at this bar.

Then make Minato feel finished at this bar.

Then show:

1. a short Sasuke showcase where his important abilities are clearly visible;
2. a short Minato showcase;
3. a real Sasuke vs Minato fight using the same gameplay systems.

These are not scripted cinematics. They are proof that the actual playable game has changed.

## Final acceptance rule

The next result must not require an explanation of commits.

I should be able to watch it and immediately say:

**"Yes. This finally has the same level of detail and care as the Itachi reference. Sasuke looks like Sasuke, Minato looks like Minato, their attacks are logical and stylish, and this is obviously a different level from our old game."**

If the result still looks like our current game with extra effects or a few new mechanics, it is not finished.
