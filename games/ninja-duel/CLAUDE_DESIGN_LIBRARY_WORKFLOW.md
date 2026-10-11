# Claude — Design Library Workflow

Use `games/ninja-duel/design_research/` as a permanent gameplay design library for future Ninja Duel work.

This is not a one-shot implementation mission. It is the shared reference system for accelerating future passes.

## Core objective

The long-term target is a roughly 32-character young-prodigy roster in a freeform Naruto-inspired arena fighter.

Do not build 32 isolated combat engines. Build strong reusable systems and let each fighter reinterpret them through movement, taijutsu, tools, state conversions, signature mechanics and awakenings.

## Read these before major future combat work

- `design_research/README.md`
- `design_research/01_combat_grammar/COMBAT_VERBS_AND_STATES.md`
- `design_research/01_combat_grammar/COMBO_BUILDING_BLOCKS.md`
- `design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md`
- `design_research/02_character_architecture/AWAKENING_DESIGN.md`
- `design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md`
- `design_research/04_research/RESEARCH_BACKLOG.md`
- `design_research/05_claude_handoff/CLAUDE_USAGE_GUIDE.md`

## Design doctrine

- Body first, VFX second.
- Locomotion must look human and intentional.
- Techniques should connect states, not just deal damage.
- Shared inputs can produce character-specific outcomes.
- Standard ninja tools can be shared, mastery must differ.
- Arena geometry is part of combat.
- Spectacle should be controllable rather than cinematic-only.
- Awakenings should alter rules/options rather than only stats.
- Every fighter must answer: why is this child considered an abnormal prodigy?

## Reusable combat stack

Think in this order:

1. Contact — punch/kick/palm/tool.
2. State change — stagger/launch/sweep/wall splat/bind.
3. Transition — chase/dash/teleport/wall run/air pursue/side switch.
4. Character conversion — the fighter turns that state into their own signature route.

Example:
`launcher` is shared.
Minato converts it into FTG pursuit.
Lee converts it into physical chase.
Gaara converts it into remote sand pressure.
Itachi converts it into projectile interception.

## Future character creation rule

Before implementing a new character, define:
- 5–7 combat verbs,
- movement identity,
- taijutsu silhouette,
- 1–3 mechanical families,
- ninja-tool mastery,
- 3+ signature state conversions,
- defensive identity,
- awakening rule change.

Then map those onto the shared combat grammar.

Do not begin with a list of jutsu.

## Research usage

When outside research is performed, store useful conclusions under `design_research/04_research/` using:

`source -> principle observed -> Ninja Duel adaptation -> affected characters -> prototype idea -> risk`

Research by topic:
- locomotion,
- taijutsu,
- combo architecture,
- projectiles,
- grappling,
- wall/air combat,
- awakenings,
- large roster design,
- specific Naruto age/lore feats,
- fan choreography.

The purpose is to convert inspiration into reusable implementation knowledge.

## Freedom

These documents are not rigid specs. If Studio testing proves an idea bad, reject it. If a stronger implementation emerges, update the library.

The library exists so future sessions spend more time building/testing and less time rediscovering the same design reasoning.