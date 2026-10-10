# Arena scale, combo freedom & ninja spectacle — report (`0.13.0-arena-combo`)

Branch `claude/minato-itachi-final`. Playable build: `games/ninja-duel/dist/NinjaDuel.rbxlx` (Studio → Play).
Mission: `CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md`. Roster source: `ROSTER_MOVESETS_10_PRODIGIES.md`.

## What changed
**Scale and running.** Stadium wall radius 66 → 103 studs, walls 46 → 62 high; trees and cover boulders in
every sector (they stop blades and fire); rounds open 48 studs apart. Sprint 38 → 45, chakra dash range 34 → 48,
pursuit 35 → 46, thrown tools 44 → 62, Flying Thunder God 60 → 90, fire and wind ranges up. The AI probes at
tool range (8–20 studs further out), throws, then runs in; it dashes in when out-ranged. Camera: far apart, the
lens stays near the player and the opponent reads small down the field instead of the player shrinking.

**Directional combo grammar** (one language, four readings — `MoveGraphs.routes`):
- two hits + toward = launcher · two hits + away = low sweep · one hit + sideways = lateral route;
- after an air hit: toward = drive away (wall splat), away = spike (ground bounce), sideways = switch sides;
- away + tool inside a string = hop out behind a throw; heavy routes are unchanged.
- Minato: rising kick seals the body (2 = Flying Thunder God after it), spinning leg sweep plants a marked
  kunai, AngleStep. Itachi: rising palm covered by two shuriken, reaping sweep, feint step with an afterimage.
  Neji: palm heel launcher, low rotation sweep (second chakra point), circular step. Sasuke: below.
- A direction pressed early (buffered) keeps its direction; HUD grammar line, route hint during a string,
  per-fighter routes on the select screen, tutorial steps for the low and side routes.

**Hit reactions by zone and kind.** Head snaps away from a face strike, the body folds around a rib strike, a
low kick buckles a knee, launchers whip the chin back before the body is carried up, kicks turn the body, sweeps
take the legs (feet up, back down), heavy knockdowns spin in flight, spiked bodies dive and bounce, a wall hit
compresses the body before it spreads. Reactions peak within two or three frames.

**Shared ninja tools.** Everyone throws (data: `ToolMastery`). Itachi's mastery: sideways + tool is Shuriken
Geometry (a wide blade struck by a second one beside the opponent, both redirected into the flank — a frontal
guard does not cover it), his shuriken ricochet once off walls and cover, three-blade fan from the air.
Blades are judged from the side they came from.

**Sasuke (12), fourth playable.** Jab → roundhouse → spinning heel kick; Lion Kick launcher followed by Shadow of
the Dancing Leaf (glued under the rising body) and the Lion Combo heel drop; vault kick over the opponent; Great
Fireball, and Dragon Flame along a Wire Trap; Phoenix Flower with two hidden shuriken; Chidori (charge, thrust,
a miss leaves him open); two-tomoe Sharingan; Curse Mark awakening that burns his own health (never to a K.O.).
Costume, stance, gait, clips, effects, AI. Gaara is server-complete with tests (hidden until his client layer).

**Transitions.** Throw → chase window; any connected launcher can be cancelled into the chase; a strike can be
thrown out of a chase once close.

## Fixed along the way
- Fire scorch, trigrams and burning-lane marks were placed by an unfiltered floor ray: a fireball exploding on a
  fighter left a 9-stud black disc at head height. Floor rays now ignore fighters and effects.
- Dragon Flame could not be cast in time (the wire throw's recovery outlasted the bind).
- Shadow of the Dancing Leaf used the generic chase (it bobbed and fell short of a high launch).

## Verification
- Headless suites: 132 PASS (new: Tools, Sasuke, grammar, buffered direction, joint limits for every strike
  of every fighter and every new reaction).
- Studio films (side camera) of each route, the reactions, Shuriken Geometry, Lion Combo, Chidori, Wire Trap →
  Dragon Flame; server traces of each sequence.
- Studio sweep, all 16 matchups (4 × 4): intro → AI fight → K.O. over two rounds → result → rematch →
  selection, 0 stuck states, 0 server or client errors.
- AI balance sim (4 seeds per pair, single rounds): Minato 62 %, Neji 54 %, Sasuke 46 %, Itachi 38 %.

## Still visibly weak
- Animation is keyframed on a block rig: readable, not Storm-fluid; spins and flips are approximations.
- No audio pass beyond the built-in whooshes and impacts.
- The AI uses the grammar but not with intent (it does not plan wall carries or seal setups).

## Known issues
- No client-side prediction: online, inputs lag by the ping.
- AI-vs-AI fights last 45–70 s per round in the larger arena; human fights are faster but untested at scale.
- Gaara is not selectable yet (no costume or effects).
