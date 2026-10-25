# Fight continuity — audit before implementation

25 October 2026. Base `aba52124c6622fc11ad66569c1d1e728fbc78e0b`, authoritative branch `claude/ninja-duel-2026-10-14`. Current user brief authorizes implementation after this audit and supersedes the earlier reviewer-only assignment for this pass. No roster expansion, new jutsu, camera spectacle or replacement engine.

Reference found locally: `ScreenRecording_10-23-2026 11-23-01_1.MP4` in Downloads, same recording stem as the requested `(2)` copy. Exact equivalence of that copy is not asserted. Whole-recording contact sheet at 1fps, close exchange at16–18s at6fps examined. The bodies remain engaged, weight shifts carry attacks, the victim folds/turns away, and recovery creates distance and another decision. These observations support continuity and two-body choreography; they do not imply copying individual moves or a new perception system.

## Architecture and findings

| Area | Existing value to preserve | Gap to reproduce/fix |
|---|---|---|
| Server locomotion/root | Place1Movement, Motor; real momentum, bounded parkour/wall rules | Normal grounded attacks block ground locomotion even when entered at speed; special runStrike alone carries motion |
| Attack geometry/lock | Brawler confirmation, bounded travel, authored orbit routes | Tracking can keep rotating an active swing to a moving target; failed air openers can hold after the target leaves |
| Two-body spacing | Motor.travel collision handling, explicit grab exceptions | Fixed push per update makes separation rate-dependent |
| Hit reaction/air exit | Direction/zone/kind reaction vocabulary; bounded action clocks | Expiring airborne reaction loses its remaining velocity after Motor.flight zeroed the assembly |
| Body/entry/exit | Velmora authored clips, family gait, IK support and damping | Second dodge can inherit the first dodge's stale timer; moving guard skips footwork; standing hit recovery tends toward a generic pose |
| Ground casting/walls | Authored casts and new horizontal wall run | Moving casts discard stepped support; wall-run cadence continues at a fixed rate as travel slows |
| Weapon/projectile | Hand-held models, shared release clock, analytical trajectory | Pending projectile emitters/light/sound may activate before release; inspect hand/origin and close contact timing |
| VFX/chakra/cleanup | Server contact feed and bounded effects | Layer frame callbacks invoked twice; aura ownership/reset incomplete |
| Camera/hitstop/audio | Restrained two-body framing, contact-driven effects, server clocks | Impact presentation arrives before the delayed projectile/body timeline; audit in fight before any camera tuning |
| Identity | Existing Minato/Itachi/Lee/Gaara families, recent weapon bodies | Keep family's guarded/restrained/physical expression while improving shared support |

## Physical/visual invariants

- State exit hands meaningful momentum/support to the next state; no generic neutral bridge is inserted.
- Every root translation has an expressed impulse, step, trajectory or hit force; whiffs keep recovery and do not steer magnetically after commitment.
- Contact and confirmation stay server-owned. No presentation-only hit confirmation, new free cancel, damage/stat change or unbounded air hold.
- Moving guard/cast use the actual stepped lower body; family upper-body/weapon language stays intact.
- An object's lifecycle is staged → held → release → flight/contact → cleanup. Dormant projectiles produce no flight light, particles or sound.
- Camera is audited; unchanged unless scenarios show a concrete framing fault. VFX confirm rather than hide contact.

## Execution and acceptance

Improve the existing body, server handoff, and object/event timelines in parallel disjoint files after this audit. Root integrates and tests repeatable continuous A(no jutsu,20s), B(Minato/Itachi tools/read/teleport), C(launcher/air/landing), D(wall approach/exit/re-entry), E(whiffs/crossings), then repeats representative identities and lower-FPS/snapshot/rapid-input coverage. Record baseline/final native sequences, inspect selected frames, run regressions and exact builds, tune, then report observable changes and remaining weaknesses. Tests are necessary; native sequence quality is a separate gate.
