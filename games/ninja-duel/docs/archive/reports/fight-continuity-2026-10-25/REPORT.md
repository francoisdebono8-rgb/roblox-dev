# Fight continuity — 25 October 2026

Source implementation: `6f0ff47`; integration of the latest movement pass: `a014262`, including remote `fe09024` (movement pass 4 `a3eb920`). Work was isolated from the dirty local main and the user's original Studio place. No publication or overwrite of that place.

**Implementation and technical regression complete. Final merged native/visual acceptance remains PENDING.** This is not a claim that the qualitative breakthrough or all twelve user acceptance criteria are closed.

## What became better during a fight

- Guarding and moving channels retain the stepping lower body. Recovery from standing hits blends into the fighter's current guard/movement. Repeated dodges restart their own body clock (the concurrent upstream fix was retained once, not stacked). Wall-run cadence follows actual travel.
- Ordinary moving openers inherit a bounded entry step, paid from the existing attack travel budget. Running-strike follow-through and real exit velocity from pass 4 remain intact. Airborne hit reactions hand back their remaining trajectory; missed jump-ins lose their suspension when the target leaves reach/sight. Bounded pulls stop short of their destination.
- Ordinary active swings commit their facing and travel direction. Explicit orbit routes retain their authored behavior. Swept body clearance prevents fast pursuit from passing through the other fighter while retaining tangential escape and jumping over them. Arrival tolerances respect resting body separation, preserving Sasuke's faster re-entry. Separation rate is independent of update frequency.
- Body state, tool release, contact sound/VFX and camera state share the existing 60 ms presentation timeline. Input, UI and hit authority still receive current server state. The killing contact survives the transition to Result.
- Projectiles are placed before entering the scene and remain silent/dark until release. Late snapshots cannot resurrect a contacted flight; bookkeeping is bounded. Volleys expose their actual count/interval to the held blade. Ordinary tools appear for families with separate melee weapons; Zabuza, Bee and Madara free the throwing hand. Sasuke's hand and wire attachment agree. Natural family tools are not replaced with generic steel.
- Effects update once per frame and clean up owned body attachments/cloth changes on reset. Interrupted held techniques dissipate without a false hit flash. No camera shake/FOV amplification or new combat engine was added.

## Tests on the merged artifact

TECHNICAL **PASS**: normal, Debug and QA each run **31 suites / 563 passing cases**. The build now includes Movement as well as the two continuity suites. Source equality is enforced by the builder. The test that reused one projectile ID for several unrelated flights now uses distinct IDs, matching the server contract; its shape/contact assertions remain intact.

The initial integration caught a real regression: Sasuke's target distance lay below the resting separation radius. His dash waited for its timeout. The corrected arrival condition restores the existing re-entry identity test; no test was weakened.

Build fingerprints and file SHA256:

| Variant | Source fingerprint | Artifact SHA256 |
|---|---|---|
| NinjaDuel | `76a6c894b7a4522c04061539529878f7033fc1db79adaecca4367b028d9c4284` | `f781a473fd7742854145d66c2dee7cb93bfff5213fe13f8919ce4122a199d042` |
| NinjaDuel-Debug | `1c366e26f691e9b6d9b81a9ab9a184c1b395a1619894f270e921e8d90c753030` | `69feea54cef2522708b0b97d9491c20d66ca2a5bb272cc080697ca6f280f445d` |
| NinjaDuel-QA | `36f91d91ffc8a06e86a9d908e7848e7f9d3ef659d8a336f7566e0950ddb6e129` | `4f5971bf0cc6184eba1330d96fb4df3510c6ab2a8146787619819892a9fbb608` |

The opened `/tmp/ND-Continuity-Merged.rbxlx` has exactly the Debug file hash above. Loading/starting a place alone does not count as playing the final build.

## Native sequences actually exercised

Baseline `aba5212` Debug: one continuous A, 20 seconds, 180 server samples. Minimum near-height root separation **1.09 studs**, **11 samples below 2 studs**. See [baseline measurements](BASELINE_NATIVE.json) and [baseline frames](BASELINE_A_FRAMES.png).

Before the final upstream integration, the revised Debug (`4f0094ad…cc9965`) ran the following continuous fights through real server requests in Studio. There is one placement and health setup before each fight, no teleporting/repositioning between actions. Legal action refusals are retained; repeated requests are not treated as hits. Bot and human use different attack cadences. [Raw results](PREMERGE_NATIVE.json).

| Sequence | Samples | Minimum near-height root gap | Gap <2 samples | Wall samples |
|---|---:|---:|---:|---:|
| A — Flashstep / Mirage | 182 | 2.88 | 0 | 0 |
| B — Flashstep / Mirage | 182 | 2.91 | 0 | 0 |
| C — Flashstep / Mirage | 182 | 2.93 | 0 | 0 |
| D — Flashstep / Mirage | 181 | 2.84 | 0 | 29 |
| E — Flashstep / Mirage | 182 | 3.00 | 0 | 0 |
| A — Leaf / Mirage | 183 | 2.90 | 0 | 0 |

A contains approach/strings, four blocked hits, a dodge, two jumps, two tools, two launches and seven chases. B resolves two marked blades, one Flying Thunder God and two Sharingan reads, including ReadSuccess/ReadSlip; eight ordinary tools were accepted across both actors. C resolves two launches, five chases and three air hits. D contains 29 wall samples, three jumps, then confirmed hits from both fighters after re-entry. E intentionally starts with attacks outside reach, then alternates evasions/pressure. Lee's A uses LeafRising rather than Minato's launcher. These are scenario observations, not a claim of twenty-fighter visual acceptance.

A separate earlier candidate had A/B/C/D inspected through recorded native frames. [Guard → dodge](A_GUARD.png), [tools/read](B_TOOLS_READ.png). These chronophotographs show actual captured poses; they omit VFX and reposition frame copies for inspection. Their timestamps are recorder-relative, not server-scenario-relative. They are pre-merge evidence and must not be presented as final merged screenshots. The air frames showed readable pursuit/fold/re-entry, but trees obscured some frames; those shots are not used as final acceptance evidence.

## Exact stopping condition and remaining weaknesses

The final eight-fight native run was prepared after integrating upstream. Roblox `execute_luau` was then rejected by automatic approval review because its usage limit was reached. The tool explicitly said this was an approval-review failure, not a finding that the action was unsafe. The final observer and fight driver did **not** execute. The restriction was not bypassed. Native measurements above remain attributed to their actual earlier fingerprint.

- **Final merged NATIVE_STUDIO: PENDING**. Replay A–E plus Lee/Itachi/Sasuke on the exact merged Debug, inspect the recorded frames and normal-speed combat, then perform real keyboard/mouse play. The probes are [fight_sequence](../../../../tools/studio/probes/fight_sequence.luau) and [fight_record](../../../../tools/studio/probes/fight_record.luau).
- **HUMAN_VISUAL/FEEL: PENDING**. The reference-level “obvious visual rupture” is not defensible solely from these measurements. Feet/contact over a full normal-speed fight still need a dedicated final inspection; broad reaction grammar and the twenty natural/held construct lifecycles are not certified bug-free.
- **LIVE_ROBLOX / two-client latency / physical controller: PENDING**, not exercised. No published session is claimed. Headless 30/60/120 Hz separation and delayed/reordered snapshot tests cover their bounded contracts, not network feel.
- Some scripted exchanges still produce repeated clashes. That is reported rather than hidden with larger effects. Camera composition was preserved, not declared perfect.

Acceptance A–L: C/E/H have targeted mechanical and pre-merge native evidence; D/F/G/I have partial representative evidence; J is verified by the scope of the diff; K passes on the merged artifact. A/B/L require the final native/normal-speed replay; none of these observations closes global human feel.

## Reproduction and preservation

Run `NINJA_DUEL_TOOLS=/path/to/tools bash games/ninja-duel/tests/run.sh`; build normal/`--debug`/`--qa`; run build isolation, architecture and project-doc checks. Open Debug, verify fingerprint, run the client observer and server fight probe. The observer does not change gameplay; the driver is Debug-only and never shipped. Select A/B/C/D/E and representative fighter IDs at its top.

The new upstream mission document was moved byte-for-byte from docs/active to [the request archive](../../requests/2026-10-25-combat-convergence-breakthrough.md), after finding no reference consumers, to retain the seven canonical active owners. SHA256 before/after: `187c56fb1315ef95139d8ace08c391b88ae1ca27630cd5b13cb2b656430999e6`. Its requirements are preserved; the mission is not silently declared complete. DEC-027 and the existing MOV/COM/TOOL/QA tickets own authority, state and remaining validation.
