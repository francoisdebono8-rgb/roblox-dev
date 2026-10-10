# MISSION — Velmora adaptation to first genuinely fun Minato vs Itachi fight

## Context

The last attempted Foundation 02 failed its primary objective. The playable result regressed compared with the previous version. It was stopped before commit. Do not defend that implementation, do not continue polishing it, and do not restart another foundation rewrite.

The previous committed playable version was better than the uncommitted Foundation 02 attempt. Start from the last good committed state, not from the failed uncommitted runtime. Preserve the failed work only if needed as a private patch/reference for individual useful pieces; it must not remain the active gameplay foundation by default.

The objective now is extremely simple:

> **Take Velmora as the mature PvP donor, adapt what it already does well into Ninja Duel, and deliver the first Minato vs Itachi fight that is genuinely fun to play.**

This is not a research mission. This is not another architecture mission. This is not a new foundation experiment. This is implementation.

---

## Absolute priority

François must be able to open the resulting Ninja Duel build, choose Minato or Itachi, start a fight, and immediately feel that he is playing a real game rather than a prototype made of disconnected Roblox mechanics.

The test is human and simple:

- movement feels responsive and intentional;
- attacks visibly connect;
- enemy reactions feel convincing;
- dodge/guard/defense are readable;
- camera helps the fight;
- hit feedback has weight;
- abilities are integrated into the combat flow instead of firing like isolated old scripts;
- Minato and Itachi already feel meaningfully different;
- the fight is enjoyable enough to replay.

If the result is merely technically correct, cleaner, or "a little better", the mission failed.

---

## Core strategy: donor-first, not Codex-first

Use Velmora as the default source for mature PvP systems whenever Velmora already solves the problem better than Ninja Duel.

Do **not** rewrite a system merely because you can.

For each major system used in this build, use this rule:

1. inspect the actual Velmora implementation;
2. compare it to the currently committed Ninja Duel equivalent;
3. if Velmora is more mature, more coherent, or feels more production-ready for this use, copy/adapt the real MIT code;
4. keep Ninja Duel/Codex code only where it is clearly better for the required ninja gameplay or where Velmora does not provide the needed behavior;
5. do not maintain two competing active systems.

Velmora is the **default winner** unless there is a concrete gameplay reason not to use its implementation.

Do not merely "take inspiration" from Velmora and rewrite everything locally. Reuse/adapt the actual MIT implementation where appropriate and preserve attribution.

---

## What should preferably come from Velmora when useful

Evaluate and adapt the real implementation for as much of this as possible:

- core combat state / action flow;
- hit detection;
- block/parry/guard logic;
- dodge/evasive behavior and i-frame handling;
- whiff/recovery rules;
- combat timing and contact resolution;
- damage/impact pipeline;
- ability execution framework;
- stamina/resource patterns if useful;
- client/server combat separation;
- anti-cheat / server validation;
- training dummy or opponent plumbing;
- camera or client combat presentation where superior;
- match start/end/rematch flow where useful;
- spectating/queue/tournament infrastructure only if it helps current lifecycle without delaying the fight.

Do not import irrelevant Velmora systems just because they exist.

---

## What Ninja Duel must remain responsible for

Velmora is not the final game. Adapt it around the ninja combat vision.

Keep/build only the parts that are genuinely specific to Ninja Duel, especially:

- third-person ninja mobility beyond Velmora's baseline;
- strong jump/air freedom;
- wall movement if it already works better in committed Ninja Duel or can be added cleanly;
- launcher -> pursuit -> aerial hits -> slam flow;
- substitution/evasive if better expressed by Ninja Duel rules;
- kunai/shuriken;
- chakra;
- Minato marks / angle-changing movement;
- Itachi Read / deception;
- jutsu preparation/interruption where needed;
- future perception/genjutsu seams;
- future ~20-fighter data-driven character architecture.

Do not rebuild these generic systems from scratch if Velmora already supplies a better primitive underneath them.

---

## First playable fight: Minato vs Itachi

This mission MUST end with Minato vs Itachi playable now. Do not postpone character integration until another phase.

### Minato

At minimum preserve/adapt his current identity around:

- superior movement and repositioning;
- kunai pressure/tool;
- fast entry/Quickstep-style movement;
- Burst Entry or equivalent approach/punish;
- mark/anchor or equivalent angle-changing mechanic if it can be integrated cleanly;
- close-range melee that uses the new combat foundation rather than a separate legacy script.

He must not feel like generic fighter + yellow VFX.

### Itachi

At minimum preserve/adapt his current identity around:

- shuriken pressure;
- Fire technique;
- Read/counter window;
- deception/afterimage/genjutsu-style misinformation if current implementation is usable;
- precise punish-oriented melee integrated with the same core combat system.

He must not feel like generic fighter + red VFX.

The kits can be smaller than the final game. Quality and integration matter more than ability count.

---

## Required base combat experience

A normal fight should support a coherent version of:

- run / sprint;
- jump and air control;
- directional dodge/dash;
- lock/camera suitable for 1v1;
- responsive M1 chain;
- a meaningful heavy/finisher;
- launcher;
- pursuit/chase;
- aerial follow-up;
- slam / knockdown;
- guard/block or Velmora equivalent;
- substitution/evasive with limited use;
- convincing knockback / hit reaction;
- whiff and recovery that create punish windows;
- Minato/Itachi tools and techniques inside this same flow.

Grab/throw and advanced wall branches are welcome if they integrate cleanly, but **do not delay the first genuinely fun fight to chase optional completeness**.

---

## Feel before architecture

The previous work repeatedly failed by satisfying feature lists while the result remained unpleasant.

Therefore:

- do not spend large token budgets designing another framework;
- do not make another micro-prototype unless a blocker forces it;
- do not build a parallel runtime that is not immediately wired into the main Ninja Duel build;
- do not create systems whose value cannot be felt in the actual playable place;
- do not claim success because automated tests pass;
- do not preserve a worse system for architectural purity;
- do not replace a good Velmora implementation with a simpler Codex reimplementation;
- do not regress the last good committed build while experimenting.

Every substantial change must move the actual playable `NinjaDuel.rbxlx` toward a better fight.

---

## Iteration rule from now on

This is critical:

> **After this mission, the main gameplay systems are not to be restarted from zero on every new request.**

Movement, combat, hit detection, defense, reactions, camera, animation integration, networking and ability execution should become the stable base of the project.

Future work should improve this base incrementally:

- tune;
- extend;
- add branches;
- add characters;
- add ninja mechanics;
- improve animations/VFX/audio;
- optimize networking/security.

A future request must not trigger another wholesale replacement of the principal systems unless there is a demonstrated blocker that makes the existing base unusable.

We are trying to advance a game, not repeatedly restart an engine.

---

## Animation and presentation

Use whatever legitimate R15 animation work is already useful from the aborted Foundation 02 attempt **only if it visibly improves the fight**. Do not keep it because time was spent creating it.

Likewise, Velmora animations/assets may only be reused when license/ownership allows it. If its code is reusable but its animation IDs are not, keep the code/timings and provide working accessible R15 replacements.

The player must see:

- locomotion that no longer looks static;
- anticipation/contact/follow-through on attacks;
- clear victim reactions;
- launcher/air/slam choreography that reads immediately;
- responsive camera framing;
- restrained but convincing impact VFX/audio;
- no old placeholder-looking pose swaps on core actions.

Do not spend the mission chasing cinematic polish. Reach "real playable game" quality first.

---

## Controller

The result must be fully playable on controller. No required combat action may remain keyboard-only.

Keep one semantic input mapping. Do not run Velmora input and Ninja Duel input as competing controllers.

---

## Working-tree safety

The aborted Foundation 02 was not committed because the playable result was worse.

Before implementation:

1. identify the last good committed Ninja Duel state;
2. save the failed uncommitted Foundation 02 work only as a patch/stash/reference if there are pieces worth salvaging;
3. restore the active working tree to the good committed baseline;
4. integrate Velmora/adaptations from there;
5. do not accidentally commit the failed runtime as the new base.

Do not destroy potentially useful uncommitted work without preserving a recoverable patch if feasible, but do not let preservation delay implementation.

---

## Time/token discipline

François wants this as fast as possible.

Therefore:

- no broad new research phase;
- no new architecture report;
- no rewriting the Gameplay Bible;
- no long intermediate explanations;
- no exhaustive testing of unrelated systems;
- no building future progression/tournament/shop;
- no AI architecture work unless needed for a basic opponent;
- no premature six-character or twenty-character work.

Read only what is necessary from Velmora and Ninja Duel to integrate the relevant systems.

Use automated checks only where they catch likely breakage quickly. Spend the majority of effort on integration and the actual playable result.

---

## Definition of done

The mission is complete only when ALL of the following are true:

1. the actual main Ninja Duel build uses the selected/adapted Velmora systems, not a disconnected prototype;
2. the failed uncommitted Foundation 02 runtime is not the active base;
3. Minato vs Itachi can be selected and fought now;
4. movement/combat/camera/reactions/defense feel materially more coherent than the previous committed build;
5. launcher -> pursuit -> aerial interaction -> slam works as a real combat sequence;
6. Minato and Itachi each have at least a compact but genuinely distinct usable kit;
7. controller works for the complete fight;
8. the fight is playable without relying on debug commands or scripted showcase sequences;
9. Velmora MIT attribution and exact imported/adapted files are recorded in `THIRD_PARTY.md`;
10. `dist/NinjaDuel.rbxlx` is rebuilt and ready for François to test;
11. changes are committed.

### Primary human gate

The highest-priority acceptance criterion is:

> François should be able to play his first Minato vs Itachi fight and have fun.

If the result still feels like old placeholder Roblox combat with abilities layered on top, do not call the mission complete. Fix the most visible causes before committing the candidate.

---

## Final response

Keep it short. Return only:

- commit SHA;
- Velmora systems actually imported/adapted;
- Ninja Duel systems retained because they were better/specific;
- Minato controls/kit;
- Itachi controls/kit;
- path to the playable build;
- any single blocker that still materially affects the fight.

Do not propose a new foundation or another major rewrite.