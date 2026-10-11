# Claude — Design Library Workflow

Use `games/ninja-duel/design_research/` as a permanent gameplay design library for future Ninja Duel work.

This is not a one-shot implementation mission. It is the shared reference system for accelerating future passes.

## Core objective

The long-term target is a roughly 32-character young-prodigy roster in a freeform Naruto-inspired arena fighter.

Do not build 32 isolated combat engines. Build strong reusable systems and let each fighter reinterpret them through movement, taijutsu, tools, state conversions, signature mechanics and awakenings.

## Codex prework is part of the workflow

Before future major Claude gameplay passes, inspect and reuse any safe scaffolding, tooling, schemas, prototypes and test harnesses prepared by Codex.

Codex's role is not to decide the final game feel. Its role is to prepare reusable foundations so Claude can spend its time on gameplay, character identity, animation, movement, feel and Studio iteration.

When Codex has prepared a system, do not rebuild the infrastructure from zero unless Studio testing shows that the foundation is fundamentally wrong. Prefer:

`Codex prepares generic system -> Claude evaluates in Studio -> Claude selects/adapts/rejects pieces -> Claude gives the system character identity and final game feel.`

This applies especially to:
- reusable combo/state definitions,
- optional grab/projection building blocks,
- projectile/tool property systems,
- chakra infusion scaffolding,
- element/nature tags,
- object interaction rules,
- character configuration schemas,
- awakening configuration hooks,
- debug/test tools,
- performance instrumentation,
- online-safe architecture,
- automated regression tests.

Claude remains the authority on whether a prepared mechanic is actually fun, readable, fluid and appropriate for a specific fighter.

## Chakra infusion and systemic freedom

A major long-term differentiator is that chakra should not function only as mana for jutsu. The shared combat architecture should be capable of supporting chakra being applied to compatible tools, weapons, projectiles and selected environment interactions.

Think in a reusable grammar such as:

`Object + Chakra Property/Nature + Trigger/Context -> Result`

Possible generic examples:
- kunai + chakra reinforcement + throw -> improved velocity/stability/impact,
- kunai + wind -> faster/cutting projectile behaviour,
- metal tool + lightning -> conductive/stun-oriented behaviour where appropriate,
- projectile + fire -> ignition/burn/area interaction where appropriate,
- wire + compatible chakra nature -> modified trap/control behaviour,
- marked kunai + seal property -> FTG destination,
- projectile + projectile collision -> deflection/trajectory change if supported,
- tool planted into wall/ground -> persistent interaction point,
- character-specific mastery -> modifies the same shared object in a unique way.

Do not make this an overwhelming crafting menu. The player-facing control scheme should remain easy to learn. Complexity should emerge from contextual interactions and character mastery rather than requiring many extra buttons.

A new systemic mechanic should ideally pass three tests:
1. **Simple first use** — understandable without studying a manual.
2. **Depth through combination** — advanced players discover more interactions.
3. **Reusable implementation** — several fighters can reinterpret the system without copy-pasted engines.

For example, standard kunai/shuriken can remain broadly available while:
- Itachi gains superior angle/redirection/setup mastery,
- Minato converts marked kunai into spatial anchors,
- Sasuke combines tools aggressively with wire/fire/lightning-oriented routes,
- Kakashi can exploit broader nature/tool interactions,
- a future weapon specialist can push the generic system much further.

Claude should use Codex-prepared generic infrastructure for these interactions, then determine the actual timings, animation language, usability and character-specific expression through Studio testing.

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
- Chakra/tool/environment systems should create freedom without creating input overload.
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

Then map those onto the shared combat grammar and existing Codex-prepared reusable systems where appropriate.

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
- chakra/tool infusion,
- elemental/nature interactions,
- awakenings,
- large roster design,
- specific Naruto age/lore feats,
- fan choreography.

The purpose is to convert inspiration into reusable implementation knowledge.

## Freedom

These documents and Codex-prepared systems are not rigid specs. If Studio testing proves an idea bad, reject it. If a stronger implementation emerges, update the library.

The library and Codex scaffolding exist so future Claude sessions spend more time building/testing the actual game and less time rediscovering design reasoning, writing boilerplate or rebuilding reusable infrastructure.