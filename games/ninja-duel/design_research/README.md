# Ninja Duel — Design Research Library

This folder is the long-term gameplay design library for the 32-character target roster.

Purpose: give future Claude passes a prepared catalogue of reusable combat ideas so time is spent implementing and testing rather than inventing every system from zero.

Core rule: do not copy other games mechanically. Extract useful principles, then reinterpret them for a freer Naruto-inspired Roblox arena fighter.

## Folder map

- `01_combat_grammar/COMBAT_VERBS_AND_STATES.md` — shared combat language and state transitions.
- `01_combat_grammar/COMBO_BUILDING_BLOCKS.md` — reusable combo, launcher, projection, aerial and wall-route building blocks.
- `02_character_architecture/ROSTER_ARCHETYPES_32.md` — large-roster archetype plan and differentiation rules.
- `02_character_architecture/AWAKENING_DESIGN.md` — awakening philosophy and examples.
- `03_system_interactions/SYSTEM_INTERACTION_MATRIX.md` — projectiles, terrain, movement, chakra, walls, teleports and interaction hooks.
- `04_research/RESEARCH_BACKLOG.md` — internet/video/lore research topics to continue later.
- `05_claude_handoff/CLAUDE_USAGE_GUIDE.md` — how Claude should consume this library during implementation.

## Product direction

Target the feeling of elite young prodigies in a large arena. The player should feel exceptional before pressing a flashy jutsu button. Spectacle should emerge from movement, body mechanics, transitions, space control, tool use and character identity.

The final target is not 32 completely separate combat engines. Build a small set of strong reusable systems and let each character bend them differently.

## Design pillars

1. Body first, VFX second.
2. Simple inputs can create rich outcomes through context.
3. Techniques should connect combat states, not only deal damage.
4. Arena geometry must matter.
5. Every fighter needs a visible reason why they are a prodigy.
6. Shared ninja tools should remain shared, but mastery varies by character.
7. Awakenings should change rules and options, not only numbers.
8. A large roster needs reusable mechanical families, not copy-pasted move lists.
9. The game should remain more freeform than a cinematic arena fighter.
10. Claude is free to adapt, reject or combine ideas in this library.