# Forge Motion Lab — Codex Build Brief

## Mission
Build a Roblox Studio plugin named **Forge Motion Lab** for Ninja Duel and future Forge Studio projects.

This is **not** a full character creator and **not** a replacement for Claude's final animation/game-feel work.
Its job is to make movement creation, mixing, profiling, sequencing and previewing fast enough that Claude can iterate on characters without rebuilding low-level motion setup by hand.

The plugin must be:
- visually obvious to use,
- premium-looking from V1,
- data-driven,
- directly compatible with Ninja Duel's existing movement work,
- reusable for future characters and future games,
- flexible enough that characters are NOT trapped in fixed archetypes.

Core design sentence:

> **Same combat grammar, different expression.**

---

# 1. What the plugin must let us do

## A. Mix existing character motion profiles
Example:
- Legs = Minato
- Hips = Minato
- Torso = Itachi
- Arms = Itachi
- Head/Aim = Neji
- Root Motion = Minato

The mix must be previewable immediately on an R15 rig and savable as a new preset without modifying source assets.

## B. Create new movement profiles BEFORE final animation polish
The plugin must be able to generate a first coherent motion profile for a future character.
This is a **starting point**, not final art.

Examples:
- Shisui: very high cadence, lateral mobility, low commitment, burst transitions
- Lee: extreme physical speed, lower-body dominance, pure taijutsu, aggressive chase
- Neji: stable center of gravity, Gentle Fist posture, circular footwork, short precise strikes
- Gaara: almost no body locomotion, calm torso, sand-driven state conversions
- Killer Bee: asymmetric stance, multi-weapon potential, irregular rhythm, multiple attack axes

Do NOT lock these characters into broad labels such as "Speed" or "Heavy".
Archetypes may exist only as optional starting templates.
Every parameter must remain individually editable.

## C. Build and sequence attacks
The plugin should expose reusable attack families:
- punches,
- kicks,
- knees,
- elbows,
- palms,
- sweeps,
- launchers,
- dodges,
- counters,
- reactions,
- transitions,
- locomotion,
- aerial movement,
- wall movement.

It must be possible to assemble a sequence such as:

`Jab -> Cross -> Knee -> Spin Kick`

and later let Claude refine timing/animation quality.

## D. Preview and compare
Must support:
- realtime preview,
- loop,
- speed control,
- front / side / free camera,
- grid / root-motion visibility,
- A/B preset compare,
- temporary mix preview before save.

## E. Export to Ninja Duel
The plugin must use a clean adapter layer so the core plugin is generic.

Create a `NinjaDuelAdapter` that can:
- read existing Minato / Itachi / Neji / Sasuke motion definitions where technically possible,
- expose them as Motion Lab sources,
- export saved presets/configuration in a format Ninja Duel can consume,
- avoid hard-coding the plugin itself around Naruto names.

---

# 2. Movement architecture

## Level 1 — Combat Grammar
Shared concepts across fighters:
- Strike
- Launcher
- Sweep
- Grab
- Pursue
- Counter
- Dodge
- Wall
- Aerial
- Projectile
- Reaction
- Transition

These are common states/concepts, not final animations.

## Level 2 — Motion DNA
Each profile defines HOW a body expresses those states.

Editable parameters should include at minimum:
- cadence,
- amplitude,
- apparent weight,
- groundedness,
- center-of-gravity height,
- forward pressure,
- lateral bias,
- recovery speed,
- rotation amount,
- hip involvement,
- upper-body activity,
- lower-body activity,
- asymmetry,
- step length,
- stride frequency,
- guard openness,
- precision,
- acrobatics,
- aggression,
- stiffness/looseness,
- head tracking intensity,
- root movement intensity.

The system should generate/select an initial movement set from these values, but all choices must remain overridable.

## Level 3 — Character Rules
Strong character-specific expression can override shared grammar.

Examples:
- Neji keeps a Gentle Fist-oriented posture and circular movement language.
- Gaara may convert a physical launcher into a sand-generated launcher.
- Lee prefers physical pursuit instead of technique-based pursuit.
- Minato can convert transitions into spatial repositioning.
- Shisui can reinterpret transitions as Body Flicker-like burst movement.
- Killer Bee can reinterpret attacks into asymmetric/multi-weapon routes.

These should be data/config rules rather than `if character == X` scattered through the plugin.

---

# 3. Data model

## MotionAsset
Suggested fields:
- id
- name
- category
- tags
- characterSource
- animationId OR proceduralDefinition
- compatibleBodyLayers
- defaultSpeed
- contactMarkers
- rootPolicy
- styleTags
- sourceType

## MotionPreset
- id
- name
- baseRig
- bodyLayers
- motionDNA
- locomotionSet
- sequences
- characterRules
- blendValues
- metadata

## MotionSequence
- id
- name
- orderedClips
- transitionTypes
- timings
- markers
- optional state tags

## Body layers
At minimum:
- Root
- Legs
- Hips
- Torso
- Left Arm
- Right Arm
- Head/Aim
- Optional weapon layer

The system must allow one preset/source per layer and per-layer blend strength.

---

# 4. Movement library taxonomy

## Locomotion
- idle
- walk
- run
- sprint
- strafe left/right
- diagonal run
- turn
- stop
- pivot
- jump
- land
- dash
- wall run
- wall jump

## Punches
- jab
- cross
- hook
- uppercut
- backfist
- palm

## Kicks
- front kick
- side kick
- roundhouse
- low kick
- high kick
- back kick
- spinning kick
- axe kick
- sweep

## Knees / elbows
- front knee
- rising knee
- jumping knee
- clinch knee
- horizontal elbow
- downward elbow
- spinning elbow

## Transitions
- punch -> punch
- punch -> kick
- kick -> knee
- dodge -> counter
- launcher -> aerial
- wall -> re-entry
- landing -> attack

## Reactions
- light hit
- heavy hit
- head snap
- torso twist
- stagger
- launch
- wall impact
- knockdown

V1 does NOT need dozens of perfect animations.
The architecture must support many, while the first release can ship with only a few useful samples per family.

---

# 5. UI / UX

The UI must look finished from the first build.
Do not ship a programmer/debug-looking interface.

## Main layout

### Left — Source Library
Tabs/filters:
- Characters
- Library
- Custom

Search + category filters.
Cards for movement sources/presets.

### Center — 3D Preview
Large R15 preview.
Controls:
- Play / Pause
- Loop
- speed
- front / side / free camera
- show grid
- show root motion
- show hit markers later

### Right — Body Mixer
Rows:
- Legs
- Hips
- Torso
- Left Arm
- Right Arm
- Head
- Root

Each row:
- source dropdown
- blend amount
- enable toggle

### Bottom — Sequence / Timeline
Simple block-based sequence editor.
Example:
`Jab | Cross | Knee | Spin Kick`

Support drag reorder and simple timing/transition controls.

### Presets panel
- New
- Duplicate
- Save
- Delete
- Apply to current character
- Export to game
- Compare A/B

### Advanced panel
Keep internal IDs, technical metadata and debug controls here only.

---

# 6. Core workflows

## Workflow 1 — Mix Character
1. Choose base preset.
2. Pick sources for body layers.
3. Preview immediately.
4. Adjust blends.
5. Save as new preset.

## Workflow 2 — Generate New Motion Profile
1. Create new profile.
2. Start blank OR optional archetype/template.
3. Edit Motion DNA sliders.
4. Plugin proposes a coherent first locomotion/attack set.
5. User can replace every proposed piece manually.
6. Save preset.

## Workflow 3 — Build Sequence
1. Choose movement blocks.
2. Drag into order.
3. Set transition/timing.
4. Preview.
5. Save as sequence.

## Workflow 4 — Ninja Duel export
1. Select preset.
2. Run NinjaDuelAdapter.
3. Produce config/output consumable by existing systems.
4. Do not mutate current gameplay automatically unless user explicitly applies it.

---

# 7. Important character-expression examples

These examples are mandatory sanity checks for the architecture.

## Lee
- extreme speed
- physical chase
- lower-body dominant
- near-zero ninjutsu dependence
- many taijutsu-specific routes
- high cadence
- aggressive continuation

## Neji
- Gentle Fist posture should remain visible
- circular footwork
- compact strikes
- precise palm logic
- stable center of gravity
- minimal wasted movement

## Gaara
- little body motion
- calm torso
- body should not behave like a normal brawler
- sand should be allowed to replace certain shared grammar actions

## Killer Bee
- potential multi-weapon stance
- asymmetric posture
- multiple attack axes
- irregular rhythm
- lively movement

## Minato / Itachi
Must demonstrate the mix system using current profiles.
Example expected test:

`Legs = Minato`
`Hips = Minato`
`Torso = Itachi`
`Arms = Itachi`
`Head = Neji or neutral`

The result must be previewable and savable.

---

# 8. Timeboxed implementation plan

The user wants a fast implementation. Prioritize useful end-to-end behavior over perfection.

## V1 — first ~20 minutes
Target: immediately useful in Ninja Duel.

Deliver:
- plugin shell and polished UI,
- R15 preview viewport,
- Source Library,
- Body Mixer,
- presets,
- basic load/save,
- MotionPreset / MotionAsset data model,
- ability to create a temporary Minato/Itachi body-layer mix,
- basic Motion DNA editor,
- save mixed/generated preset.

Success test:
> We can visibly make `Minato legs + Itachi upper body`, preview it and save it.

## V2 — next ~20 minutes
Deliver:
- sequence editor,
- movement family taxonomy,
- speed/blend controls,
- mirror left/right,
- A/B compare,
- better Motion DNA generation/proposals,
- reactions/transitions support,
- initial Neji/Sasuke/profile examples,
- cleaner preview controls.

Success test:
> We can create or mix a profile, build a short attack sequence, preview it, compare variants and save it.

## Final pass — finish within roughly 1 hour total
Deliver:
- NinjaDuelAdapter,
- import/export integration,
- UI polish,
- empty states,
- error handling,
- simple undo/redo where practical,
- persistence,
- QA/demo content,
- sample presets for Minato / Itachi / Neji / Sasuke,
- profile-generation examples for Lee / Gaara / Killer Bee / Shisui,
- README/usage notes kept short.

Success test:
> Claude can open the plugin and understand how to use it without reading documentation.

---

# 9. Hard constraints

- Do NOT redesign Ninja Duel combat.
- Do NOT replace current animations automatically.
- Do NOT impose one global archetype system.
- Do NOT hard-code all logic around Naruto character names.
- Do NOT spend the hour making a full professional animation editor.
- Do NOT rebuild Moon Animator / Blender.
- Do NOT prioritize backend cleanliness over usable preview workflows.

Instead:
- use existing data where possible,
- expose reusable movement pieces,
- make everything overridable,
- create sensible defaults,
- keep the architecture generic,
- make the preview/mix/generate loop extremely fast.

---

# 10. Definition of done

Forge Motion Lab is successful when Claude can:
1. inspect existing character motion sources,
2. create a new motion profile from scratch or a loose template,
3. mix body parts/layers from multiple profiles,
4. keep strong character-specific movement identities,
5. build short attack/movement sequences,
6. preview immediately,
7. save/compare variants,
8. export a selected configuration back toward Ninja Duel,
9. refine the result later without being trapped by the plugin's first choices.

The plugin should accelerate creation; it must never become a creative cage.

---

# 11. Execution mode — code first, minimal visual interruption

This mission must be executed primarily through code and repository work.

The user does **not** want Codex repeatedly opening Roblox Studio, taking over the screen, running long visual inspection loops, or stopping to show intermediate UI states.

During implementation:
- prefer editing code, configs, tests and plugin assets directly,
- keep Roblox Studio interaction to the strict minimum required to avoid obvious breakage,
- do not perform repeated visual QA passes during V1/V2/final unless a technical blocker makes them necessary,
- do not pause after each visual milestone for user approval,
- do not occupy the user's full screen with Studio for long periods,
- do not spend time polishing by visual iteration beyond what can reasonably be inferred from the existing mockup/spec,
- use automated/static checks where possible,
- preserve the ability to test later in Studio.

The expected workflow is:

`Codex builds mostly in code -> Codex performs only minimal sanity checks -> Codex commits -> user opens/tests the plugin -> user reports what is wrong -> ChatGPT/Claude prepares the targeted correction.`

The user's manual review is the main visual QA gate for this task.

At the end, report clearly:
- final commit SHA,
- files created/changed,
- what is definitely implemented,
- what remains mocked/approximate,
- exact steps for the user to open and test Forge Motion Lab in Studio.
