# Ninja Duel — Phase 6 candidate

Open `dist/NinjaDuel.rbxlx` in Roblox Studio, then **Test**. No plugins, paid assets or installation dependency. Choose Minato or Itachi and select **Interactive Tutorial** or **Duel**. Result offers rematch and character selection.

The candidate contains advancing punch/kick chains, heavy and launcher branches, 3D chase, aerial hits, downslam, knockdown/wakeup, directional grab/throw, guard, dodge and limited substitution. Minato emphasizes movement/kunai/angles/anchors/Wind; Itachi emphasizes precision/shuriken/Read/deception/Fire. Walls and platforms share server validation with normal combat.

## Controller

| Input | Action |
|---|---|
| Left stick / click LS | Move / toggle sprint |
| Right stick / click RS | Camera / lock target |
| A / Cross | Jump or contextual chase; wall rebound |
| X / Square | Light; horizontal finisher after fourth light; throw while grabbing |
| Y / Triangle | Heavy; launcher after two/three confirmed lights; air downslam; upward throw while grabbing |
| B / Circle | Directional dodge; substitution during a fresh hit/grab reaction |
| LB / L1 | Hold guard |
| LT / L2 | Grab |
| RT / R2 | Kunai / shuriken check |
| RB + A / X / Y / B | Equipped techniques 1 / 2 / 3 / 4 |
| D-pad up | Technique 5 (Minato Wind) |
| View / touchpad | Skip tutorial |
| D-pad / left stick + A | Select and activate menus |

Keyboard: WASD, CTRL sprint, SPACE jump, LMB light, T heavy/launcher/slam, V grab, F guard, Q dodge, X substitution, R tool, E chase, SHIFT lock, 1–5 techniques, C wall detach, G declared feint, ESC skip tutorial. Hold RMB and move mouse to orbit.

**Ground route:** light → light → light → heavy launcher → chase → air light → air light → heavy slam. Repeated lights choose the horizontal finisher. Inputs can buffer near contact; whiffs retain recovery. Throws follow left-stick direction. Knockdown protects the defender until wakeup; substitution spends a limited charge and chakra.

## Five-minute controller playtest

1. **0:00–0:45:** select Tutorial using only controller. Move, sprint, jump, lock and dash. Do the controls respond without fighting you?
2. **0:45–2:30:** follow the current objective through wall rebound, light chain, launcher/chase/air hits/slam, guard/dodge, substitution and grab/throw. Failed air exercises reset quickly. Guided incoming telegraphs are slowed where needed.
3. **2:30–3:30:** try a jutsu and interrupt the practice opponent. Skip with View/touchpad if needed, then start a Minato duel.
4. **3:30–4:30:** use kunai, Quickstep, Burst Entry and the marked anchor; try one vertical exchange. Finish or lose the duel and select rematch with controller.
5. **4:30–5:00:** return to selection, choose Itachi, test shuriken, Fire, timed Read and the afterimage. Report the first unpleasant input, camera problem or unconvincing exchange.

All feel/hardware checks are **NEEDS HUMAN TEST**. Tutorial completion normally takes longer than this smoke route; replay it fully afterward.

## Verification

From repository root:

- `python3 games/ninja-duel/build.py` and `--qa`: standalone XML and source-equality/SHA manifests.
- `luau games/ninja-duel/tests/Rules.spec.luau`: seven pure policy scenarios.
- `lune run games/ninja-duel/tests/Combat.spec.luau`: ten deterministic scenarios using actual modules and a geometry adapter; not Studio physics/rendering.
- Open `dist/NinjaDuel-QA.rbxlx` and Test for the native suite. Output starts `[NinjaDuelQA] START 0.4.0-phase6` and ends with PASS/FAIL totals. Reopen the file after a rebuild; Studio does not reload an already-open place from disk.

Current evidence: compilation and source equality PASS, policy **7 PASS**, headless combat/controller/tutorial **10 PASS**. Final-artifact native and rendered/controller QA **PENDING** because the computer-control session times out. Earlier Phase 5 native totals do not validate this candidate.

## Presentation / limitations

Original keyed R15 choreography now includes anticipation/contact/follow-through, punches/kicks, launcher, air strikes, slam, grabs, reactions and wakeup. It is rendered locally and remains below final authored production quality. Published AnimationTracks can replace it through `AnimationIds`; see `ANIMATION_TODO.md`.

Baseline feedback references Roblox's built-in sounds, with local limb trails, impacts, landing feedback and an original ghost afterimage. No downloaded animation/VFX packs are used. Resource/license audit: `THIRD_PARTY.md`.

Native collision/physics, full tutorial reachability and actual Xbox/PlayStation input must still be checked on the final build. Do not describe Phase 6 as validated/completed before those checks and one human playtest.
