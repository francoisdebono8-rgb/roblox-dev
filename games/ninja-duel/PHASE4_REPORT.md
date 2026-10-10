# Phase 4 — Game Feel, Arena Depth & Epic Combat: report (`0.10.0-phase4-gamefeel-arena`)

Branch `claude/minato-itachi-final`, continuing from the phase 3 build. Mission: `CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md`.

## Test it (Mac or Windows)

Pull the branch, open `games/ninja-duel/dist/NinjaDuel.rbxlx` in Roblox Studio, press **Play**, pick a prodigy,
**Enter the stage**. The file is self-contained (scripts, stadium, costumes, VFX); nothing to install.

## Controls (unchanged keys, new meanings)

WASD move · LMB light · RMB heavy · SPACE jump / chase · Q dodge · F guard · V grab · R kunai / shuriken ·
E chase · X substitution · G feint · C wall detach · CTRL sprint · SHIFT lock · 1–5 techniques.

New this phase:

| Situation | Input | Result |
|---|---|---|
| Being comboed, juggled, grabbed or pinned | **X** (or Q while hurt) | Substitution (2 charges, recharge 9 s each, 15 chakra) |
| Pinned against a wall, right on impact | **Q** | Wall tech: kick off the wall (12 chakra). Mistimed = locked out |
| Opponent pinned on the wall | LMB / blades | Pin (extends the wall phase, max 2) |
| Opponent pinned on the wall | RMB (or Rasengan / dive) | Wall bounce: back into the open for an air combo |
| Opponent pinned / after a substitution | **E** | Pursue / track the reappearance |
| Running on a wall | LMB or RMB | Wall dive at the opponent (up to 40 studs) |
| Minato, Flying Thunder God (2) | stick direction | Chooses which seal, and which side of the opponent you land on |
| Minato, right after a teleport | 3 | Instant Rasengan (no wind-up) |
| Minato, airborne | 3 | Rasengan plunge (ends the air phase in a knockdown) |
| Itachi, after a Sharingan parry / perfect dodge / Read / caught genjutsu | LMB | Counter palm |
| Itachi | 5 | Katon: Phoenix Flower (new) |

The HUD shows substitution diamonds (refilling), combo counters with the damage scale of the next hit, the
number of seals on the Flying Thunder God card, and prompts for wall tech / pursue / counter.

## What changed

**Fights last longer through structure, not HP** (health is unchanged: Minato 125, Itachi 145).
- Combo damage scaling: two full hits, then −12 % per hit (floor 35 %); a combo that reaches 11 hits drops the
  victim into a knockdown with wake-up cover.
- Substitution (Kawarimi) is a real resource: 2 charges that come back one at a time, usable while juggled,
  grabbed or pinned, never as a neutral dodge. Minato escapes onto a planted seal (spending it), Itachi
  reappears behind the attacker as a crow clone. The attacker gets a short tracking window (E), so a
  predictable substitution can still be punished.
- Finishers toned down (third light 25→18, heavy 16→14, slam 13→11), blades are chip (2–3) and a neutral throw
  costs 4 chakra. Chakra regeneration is lower (Minato 8/s, Itachi 7.2/s): techniques are decisions.
- Clashes: two strikes that become active together cancel out with a flash and push both fighters apart.

**The arena is part of combat.**
- The stadium is the same Chunin Exam finals stadium, brought in (wall radius 81.6 → 66.5) so walls are
  reachable in a fight; trees and boulders moved in proportionally.
- Wall loop: a body carried hard into the wall, a field tree or a boulder is splatted (small damage, facing the
  field, slides down slowly). Attacker: pursue, pin with lights/blades, bounce out with a heavy blow, or reset.
  Defender: tech on the impact, spend a substitution, or take it. Limits: 2 pins and 2 splats per combo,
  one bounce.
- Wall running now has an attack: the wall dive.
- Light 3 and Rasengan carry further so a string near a wall reaches it.

**Minato — Flying Thunder God as a system.** Up to two planted seals plus a seal on the opponent's body (a
marked kunai that connects); the stick picks the seal and the arrival side (default: behind); cooldown 1.5 s
so two seals can be chained; the seal can be spent as an escape (substitution). Rasengan is context-sensitive:
string finisher, instant after a teleport, plunge in the air, and it bounces a pinned body off the wall.

**Itachi — stronger, with his Sharingan** (at the user's request: he already had it at 13).
- Sharingan always awake: red glowing irises with pupil and three tomoe, flaring when he reads or casts.
- It has gameplay: wider parry (0.3 s) and perfect-dodge (0.22 s) windows, each success opens a counter; a
  raised guard tracks a Flying Thunder God teleport instead of being crossed up.
- Faster kit (startups ~1.0× instead of 1.08–1.15×), speed 27.5, damage ×1.1.
- Sharingan Read also reads Rasengan; Shadow Shuriken adds two hidden blades aimed at where the opponent
  dodged; new Katon: Phoenix Flower (five small flames fanned at the target, small burning patches).
- Great Fireball that misses leaves a wider lane of burning ground (space denial).
- Genjutsu: Mirage now creates a decision — swinging at the afterimage exposes the victim and opens a counter.

**AI** uses all of it: wall tech on impact, substitution decided once per combo, pursue / pin / bounce on a
pinned opponent, wall run into dives, instant Rasengan after a teleport, Rasengan plunge, Phoenix Flower,
guards or sidesteps incoming blades.

## Verification

- Headless suites **89 / 89 PASS** (new `tests/Phase4.spec.luau`, 16 cases: scaling and combo limit,
  substitution charges/seal escape/crow clone, wall splat/pin/bounce, wall tech timing, wall dive, clash,
  context Rasengan, multi-seal and body seal, genjutsu read, Sharingan parry and teleport tracking, Shadow
  Shuriken and Phoenix Flower volleys). The test harness now has wall planes.
- Roblox Studio: instrumented AI-vs-AI fights with a damage-by-source log. Before tuning, fights ended in
  20–33 s and blades were 40–55 % of all damage; after tuning, both fighters were still above 60 % health after
  14 s of AI play, with wall splats, techs and substitutions happening in normal play and no client error.

## Ideas tested and rejected

- **Wall tech on any dodge press during a splat** — made the wall phase disappear (always escaped). Kept a
  timed window on impact with a lock-out for mashing.
- **Dodge during a splat falling back to substitution** — a mistimed tech silently spent a charge; removed.
- **Re-opening the tech window after every pin** — the defender could always leave; pins extend the phase instead.
- **Substitution rolled every AI tick** — the bot escaped every combo; now decided once per combo.
- **Clash only when both strikes are already active** — almost never happened (the faster jab always won);
  the other swing may now be up to 0.07 s from becoming active.
- **Uniform damage cut / HP increase** — rejected per the brief; length comes from scaling, resources and blade
  economy instead.
- **Homing Phoenix Flower flames** — would break the client's exact replay of straight flights; each flame is
  re-aimed at release instead.

## Biggest remaining weaknesses

1. Fight length and balance are tuned from AI-vs-AI data; they need human playtests (especially Itachi's
   blade pressure against a real player, and how often the AI substitutes).
2. Wall combat depends on fighting near the wall; the AI goes there but a human may rarely carry a fight to
   it. A camera pass for very close wall exchanges is still owed.
3. New clips (wall dive, Rasengan plunge, sitting splat) are procedural keys like the rest; no audio pass yet.
4. On this Windows machine (150 % scaling) Studio still shows only part of the viewport; Mac is unaffected.
5. `nativeQA`, `visualAcceptance` and `controllerFeel` remain human gates in the manifest.
