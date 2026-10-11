# Claude Usage Guide

This library is a support system, not a replacement for judgement.

## When starting a future gameplay pass

1. Read the current playable build and current code first.
2. Use this library to find reusable ideas instead of inventing everything from zero.
3. Select only the ideas relevant to the current problem.
4. Implement small coherent groups of changes.
5. Test continuously in Roblox Studio.
6. Reject any library idea that conflicts with actual game feel.

## Priority order

When time is limited:
1. locomotion / body continuity,
2. hit readability,
3. state transitions,
4. character identity,
5. system interactions,
6. content quantity,
7. polish.

A new technique is lower priority than fixing a movement system that makes every technique look bad.

## Character implementation workflow

For a new fighter:

### Step A — Identity
Choose:
- 5–7 combat verbs,
- 1 primary movement identity,
- 1–3 mechanical families,
- taijutsu silhouette,
- ninja-tool mastery level,
- signature mechanic,
- awakening rule change.

### Step B — Shared grammar
Map that identity onto:
- neutral attack,
- directional branches,
- launcher,
- slam,
- projection,
- aerial pursuit,
- wall interaction,
- defensive answer,
- tool use.

### Step C — Signature conversions
Define at least 3 moments where the character converts a generic combat state into something uniquely theirs.

Example:
- launcher -> Minato FTG chase,
- wall splat -> Gaara sand bind,
- perfect dodge -> Itachi deceptive punish.

### Step D — Test identity without jutsu
Before adding flashy techniques, spend time fighting with basic movement + taijutsu + tools.

If the fighter does not already feel distinct, do not hide the problem behind VFX.

### Step E — Add techniques
Each technique should answer at least one:
- opens neutral,
- extends route,
- changes state,
- controls space,
- creates setup,
- punishes a behavior,
- escapes a state.

Avoid redundant attacks that only differ in particles/damage.

## Large roster rule

For 32 fighters, prefer a shared system with character reinterpretation.

Do not create a special-case engine for every fighter unless the identity truly requires it.

Before adding a unique subsystem, ask:
- can this be expressed through shared states/tags?
- will another future fighter reuse part of it?
- does abstraction harm the intended feel?

## Testing scenarios Claude should repeatedly use

- 30 seconds free movement without attacks.
- 30 seconds lock-on circling / sprint / retreat / diagonal movement.
- ground combo branches.
- launcher -> chase -> aerial -> finish.
- wall splat -> tech / follow-up.
- projectile vs movement.
- projectile vs projectile where supported.
- substitution during pressure.
- high-speed camera tracking.
- awakening enter / fight / exit.
- every character vs at least two very different archetypes.

## Quality bar

A good implementation should make the player say:
- "I understand what my body is doing."
- "I can tell why this fighter is different."
- "I chose that continuation."
- "The arena mattered."
- "That sequence looked crazy, but I still controlled it."

The target is not scripted spectacle. It is controllable spectacle.