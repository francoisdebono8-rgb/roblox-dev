# Forge Motion Lab — Common Bilateral Motion Library Pass

## Mission
Improve the shared movement library inside Forge Motion Lab so common movement is no longer generic, repetitive or one-sided.

This pass is NOT about creating final character-specific movesets. It is about building a much stronger common motion vocabulary that Claude can later reuse, edit, exaggerate and adapt for Minato, Itachi, Neji, Sasuke, Lee, Gaara, Shisui, Killer Bee and future fighters.

Core goal:

> Every common strike/movement family should exist in coherent left/right versions, with proper body mechanics and multiple useful variants.

The current problem is visible in the plugin: too many moves are unilateral, too many attacks reuse the same body logic, and several movements look like slight variations of the same generic animation.

---

# 1. Priority: bilateral coverage

For every common attack family, create both LEFT and RIGHT versions where appropriate.

Examples:
- Jab_L / Jab_R
- Cross_L / Cross_R
- Hook_L / Hook_R
- Uppercut_L / Uppercut_R
- Backfist_L / Backfist_R
- Palm_L / Palm_R
- Elbow_L / Elbow_R
- Knee_L / Knee_R
- FrontKick_L / FrontKick_R
- SideKick_L / SideKick_R
- Roundhouse_L / Roundhouse_R
- LowKick_L / LowKick_R
- HighKick_L / HighKick_R
- BackKick_L / BackKick_R
- SpinningKick_L / SpinningKick_R
- AxeKick_L / AxeKick_R
- Sweep_L / Sweep_R

Also do left/right versions for movement states where direction matters:
- StepLeft / StepRight
- PivotLeft / PivotRight
- DodgeLeft / DodgeRight
- LateralRunLeft / LateralRunRight
- SideCounterLeft / SideCounterRight
- WallExitLeft / WallExitRight where useful

Do NOT rely only on a blind mirror operation if the result produces incorrect support-foot logic, guard orientation, hip rotation, torso follow or recovery.

Mirroring may be used as a starting point, but the final left/right variants must remain individually editable Motion Lab assets.

---

# 2. Biomechanics contract for each attack

Every authored offensive movement must explicitly encode or derive:
- attacking limb,
- support foot / planted leg,
- stance side,
- center-of-gravity shift,
- hip rotation,
- torso rotation/follow,
- shoulder contribution,
- head/guard behaviour,
- root travel,
- anticipation,
- contact pose,
- follow-through,
- recovery.

The body must visually explain the strike.

For example:

`Cross_R`
- left leg can lead or brace depending on variant,
- hips rotate first,
- torso follows,
- right shoulder drives through,
- rear heel/foot mechanics should support rotation,
- left hand should not hang dead,
- recovery returns to a coherent guard.

`Roundhouse_R`
- support foot pivots,
- pelvis turns,
- torso counterbalances,
- striking leg extends through an arc,
- arms participate in balance/guard,
- recovery is not an instant snap back to idle.

---

# 3. Common variant families

For each major strike type, create several reusable variants instead of one generic version.

Target variant vocabulary:
- Compact
- Standard
- Fast
- Heavy
- Long
- Rotational
- Stepping

Not every movement needs all 7 variants, but major families should have enough contrast that the library no longer feels repetitive.

Examples:
- Jab_L_Compact
- Jab_R_Compact
- Jab_L_Long
- Jab_R_Long
- Cross_L_HipDrive
- Cross_R_HipDrive
- Hook_L_Wide
- Hook_R_Wide
- Roundhouse_L_Fast
- Roundhouse_R_Fast
- Roundhouse_L_Wide
- Roundhouse_R_Wide
- SideKick_L_Long
- SideKick_R_Long
- Knee_L_Rising
- Knee_R_Rising
- Sweep_L_Low
- Sweep_R_Low

Different variants must actually differ in silhouette/timing/body mechanics, not only speed numbers.

---

# 4. Locomotion quality

Improve common locomotion so it also stops feeling generic/unilateral.

At minimum refine:
- idle neutral,
- idle combat,
- walk forward,
- walk backward,
- run forward,
- sprint,
- strafe left/right,
- diagonal left/right,
- pivot left/right,
- stop left/right where body orientation matters,
- short dodge left/right,
- pursuit step,
- recovery step.

Requirements:
- gait cadence matches displacement,
- foot movement should better explain root motion,
- arms should react naturally to gait/profile,
- hips/torso should not remain unnaturally static,
- lateral movement should not look like a forward run rotated 90 degrees,
- left/right variants must preserve target-awareness logic where appropriate.

---

# 5. Transitions

Create reusable transitions between common movement families.

Priority transitions:
- jab -> cross
- jab -> hook
- cross -> kick
- punch -> knee
- kick -> punch
- kick -> knee
- sweep -> follow-up
- dodge left/right -> counter
- pivot left/right -> strike
- launcher -> aerial pursue
- landing -> attack
- attack -> guard recovery

Transitions should preserve stance and avoid obvious body snapping.

Where stance switches occur, encode them explicitly instead of hiding them.

---

# 6. Editable inside Motion Lab

Everything created in this pass must remain editable by Claude later.

For every generated movement/variant, expose useful editable controls through Motion Lab, including where relevant:
- amplitude,
- hip rotation,
- torso follow,
- shoulder drive,
- attacking-limb extension,
- support-foot pivot,
- root travel,
- center-height shift,
- anticipation amount,
- contact timing,
- follow-through amount,
- recovery duration,
- guard hand position,
- head tracking,
- left/right stance metadata.

Do NOT bake the whole result into opaque code that Claude cannot easily tweak later.

---

# 7. Naming/data requirements

Use explicit metadata rather than inferring everything from names.

Each motion asset should have fields/tags for:
- side = Left / Right / Neutral
- attackingLimb
- supportLimb
- stance
- family
- variant
- bodyMechanics tags
- compatible transitions
- mirrorSource if it began from a mirrored source
- independentlyEditable = true

Keep names human-readable in the UI.

---

# 8. UI requirements for this pass

Inside Forge Motion Lab, make bilateral variants easy to understand.

Expected UX:
- selecting `Roundhouse` clearly shows Left / Right variants,
- variants are grouped together,
- a user can quickly compare L/R,
- a button may create a mirrored starting point, but the result becomes an independent editable variant,
- filters for Side and Family,
- current attacking limb visible in the inspector,
- support leg/arm shown in metadata/inspector,
- preview can switch side quickly.

Do not clutter the UI with developer-only internals; keep technical metadata in Advanced.

---

# 9. Quality bar

The pass is successful if, in the plugin, it is immediately obvious that:
- right/left punches are both represented,
- right/left kicks are both represented,
- knees/elbows/sweeps are bilateral,
- attacks are no longer all the same silhouette,
- hips/torso/support-foot logic differ between punch/kick/knee families,
- variants have meaningful differences,
- transitions look more coherent,
- Claude can modify any resulting motion afterward.

This is more important than adding character-specific powers in this pass.

---

# 10. Suggested minimum deliverable

At minimum deliver editable bilateral versions for:

Punches:
- Jab
- Cross
- Hook
- Uppercut
- Backfist
- Palm

Kicks:
- Front kick
- Side kick
- Roundhouse
- Low kick
- High kick
- Back kick
- Spinning kick
- Axe kick
- Sweep

Knees/elbows:
- Front knee
- Rising knee
- Jumping knee
- Horizontal elbow
- Downward elbow
- Spinning elbow

Movement:
- strafe left/right
- lateral run left/right
- dodge left/right
- pivot left/right
- pursuit step left/right or stance-aware equivalent

For major families, include at least 2 visibly distinct variants beyond the basic one where practical.

---

# 11. Hard constraints

- Do not redesign Ninja Duel combat rules.
- Do not alter damage, AI, economy or networking.
- Do not delete existing working assets.
- Do not create character-specific exceptions everywhere.
- Do not solve the problem with VFX.
- Do not rely on simple X-axis mirroring as the final result for every move.
- Do not produce dozens of visually identical assets with different names.

Focus on common reusable body movement quality.

---

# 12. Workflow

Preferred implementation approach:

`existing common motion -> inspect asymmetry/genericness -> author bilateral pair -> add real body mechanics -> create useful variants -> expose edit controls -> test preview -> save as reusable Motion Lab assets`

Claude will later use these assets as raw material for character-specific expression.

---

# 13. Final report

At completion provide only:
1. final commit SHA,
2. total number of new/updated bilateral motion assets,
3. which families now have L/R support,
4. which families have multiple variants,
5. what remains approximate/procedural,
6. how François can compare old vs new motions in Forge Motion Lab.
