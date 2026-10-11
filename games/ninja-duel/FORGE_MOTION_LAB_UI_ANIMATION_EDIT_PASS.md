# Forge Motion Lab — UI+ Animation Edit Pass

## Mission
Improve the current Forge Motion Lab after visual review in Studio.

Current branch/base: `codex/forge-motion-lab`.
Create this pass on top of the existing plugin without redesigning Ninja Duel gameplay.

The current plugin is technically useful, but the UI is still too flat/generic and the motion-editing workflow is not powerful enough for Claude to correct motions that are too weak, too small, badly angled or anatomically illogical.

This pass has TWO goals:

1. **UI+** — make the plugin look and behave like a real animation/combat authoring tool, with much better hierarchy, density, discoverability and timeline editing.
2. **Animation modification** — add a lightweight but real pose/keyframe adjustment layer so Claude can modify generated/imported motion directly inside the plugin instead of only mixing presets and DNA.

Do not turn this into Blender/Moon Animator. The target is a focused combat-motion editor.

---

# 1. UI references to study before implementation

Use these interfaces as references for interaction patterns, NOT for visual copying.

## Roblox Animation Editor
Official docs:
https://create.roblox.com/docs/animation/editor

Useful ideas:
- clear separation between playback controls, track list and timeline,
- direct rig posing,
- per-track/per-keyframe editing,
- simple transport controls,
- timeline as a first-class workspace rather than a small footer.

## Blender Dope Sheet
Docs:
https://docs.blender.org/manual/en/5.4/editors/dope_sheet/introduction.html

Useful ideas:
- channels on left,
- time axis on right,
- keyframe diamonds,
- readable hierarchy,
- drag keyframes to retime,
- multi-select and stretch timing.

## Blender Graph Editor
Docs:
https://docs.blender.org/manual/en/5.4/editors/graph_editor/introduction.html

Useful ideas:
- selected property/channel focus,
- curve-based refinement,
- visually understandable easing/interpolation.

Do NOT implement a full graph editor in this pass. Borrow the idea of exposing easing/curve controls for selected transitions.

## Blender animation channel sliders
Reference:
https://docs.blender.org/manual/en/5.2/editors/graph_editor/channels/introduction.html

Useful idea:
- channel values and sliders alongside animated properties,
- clear mute/lock/visibility concepts.

---

# 2. Problems seen in current Studio UI

From the first Studio review:
- too much unused empty space in the lower half,
- sequence/timeline area is visually weak and disconnected from the preview,
- Library items are text-heavy generic cards with no motion thumbnails/mini-preview,
- main hierarchy is not immediately obvious,
- Mixer/DNA/Advanced feels like three independent forms rather than one editing workflow,
- Body Mixer is functional but visually repetitive,
- important actions are spread across the top bar,
- current preview is central but editing tools do not feel attached to the selected motion,
- user cannot directly correct a punch/kick/knee that is too small, too stiff, badly rotated, badly placed or visually illogical,
- current DNA changes global style but is too coarse for final motion correction.

Do not solve this by adding more panels. Solve it by improving hierarchy and making controls contextual.

---

# 3. New main layout

Keep a dark Forge visual language, but rebuild the layout around four clear zones.

## A. Left — Motion Browser
Width about 240–280px.

Contents:
- search,
- tabs: `Characters | Motions | Custom`,
- category chips: `Locomotion / Punch / Kick / Knee / Elbow / Palm / Dodge / Aerial / Wall / Reaction`,
- each motion card should show:
  - name,
  - small pose thumbnail or generated silhouette preview if practical,
  - source character/profile,
  - short tags,
  - favorite/pin optional.

Click = load/select.
Double-click or obvious `Add` = add to sequence.

## B. Center — Large 3D Motion Viewport
This must remain the visual center.

Add a compact contextual toolbar around it:
- Play/Pause,
- Loop,
- playback speed,
- Front/Side/Free,
- Grid,
- Root path,
- Ghost previous/next pose,
- Edit Pose toggle.

When `Edit Pose` is active, the viewport becomes an editor rather than only a preview.

## C. Right — Context Inspector
One inspector that changes according to selection.

Tabs can remain:
`Mix | DNA | Pose | Motion | Advanced`

But the selected context should control what is shown.

Examples:
- selecting a body layer -> Mix controls,
- selecting a motion -> Motion controls,
- selecting a keyframe -> Pose controls,
- selecting a DNA profile -> DNA controls.

Do not show giant unrelated forms simultaneously.

## D. Bottom — Real Timeline
Use the full width below Browser + Viewport + Inspector.
Height roughly 180–260px, resizable if practical.

Must include:
- playhead,
- time ruler,
- named event markers,
- channels/body groups,
- keyframe diamonds,
- motion blocks for sequence mode,
- drag to move/retime,
- zoom/fit,
- selected keyframe details.

The timeline must visually feel connected to what is shown in the viewport.

---

# 4. New lightweight animation modification system

This is the major functional addition.

Claude must be able to take a generated/imported motion and adjust it without leaving Forge Motion Lab.

Example:
A roundhouse kick is too small and anatomically weak.
Claude should be able to:
- select the contact keyframe,
- select RightLeg / Hips / Torso,
- increase hip rotation,
- raise the leg,
- extend the knee,
- lean the torso,
- move root slightly forward,
- increase anticipation,
- change timing,
- preview immediately,
- save as a new variant.

## 4.1 Editable key poses
For each MotionAsset/clip, support user-editable pose overrides at normalized times.

Minimum pose points:
- `Start`
- `Anticipation`
- `Contact`
- `FollowThrough`
- `Recovery`

Claude can add/remove additional pose keys later, but these five semantic keys should make common combat edits fast.

Each pose key stores per-part transform overrides.

## 4.2 Editable body controls
At minimum expose:
- Root position X/Y/Z,
- Root pitch/yaw/roll,
- Hips pitch/yaw/roll,
- Torso pitch/yaw/roll,
- Head pitch/yaw/roll,
- Left/Right shoulder raise/out/rotation,
- Left/Right elbow bend/rotation,
- Left/Right hip raise/out/rotation,
- Left/Right knee bend,
- Left/Right foot position/rotation where current rig representation supports it.

Use the current internal anatomy representation where possible; do not introduce a second incompatible pose system.

## 4.3 Direct viewport editing
Preferred:
- click/select body part in viewport,
- simple Rotate / Move gizmo or clear handles,
- changes write to selected pose override.

If reliable Studio gizmos are too expensive for this pass, provide a strong fallback:
- clickable body-part list next to viewport,
- compact numeric/slider controls,
- keyboard nudges,
- immediate preview.

The feature MUST work even if direct gizmos are delayed.

## 4.4 Quick exaggeration tools
Add one-click/slider helpers for the most common problem we currently have: moves that are not amplified enough.

For selected pose or whole motion:
- `Amplitude`
- `Hip rotation`
- `Torso follow`
- `Limb extension`
- `Root travel`
- `Impact lean`
- `Anticipation`
- `Follow-through`
- `Recovery tightness`

These are NON-DESTRUCTIVE modifiers over the base motion where practical.

Example:
`Amplitude 1.25x` should visibly exaggerate the selected motion without manually editing every joint.

## 4.5 Timing editor
For a selected motion expose:
- total duration,
- anticipation time,
- contact time,
- recovery time,
- playback speed,
- ease-in/ease-out preset,
- hold/contact pause if useful.

The user must be able to drag semantic markers on the timeline.

## 4.6 Motion path / root editing
Show root trajectory in viewport when enabled.
Allow editing at minimum:
- forward travel,
- lateral travel,
- vertical lift,
- turn/yaw,
- start/end root offsets.

This is important for lunges, spinning kicks, dodges, aerial entries and pursuit motions.

---

# 5. Motion variants

Never overwrite a source motion by default.

Workflow:
1. select existing motion,
2. `Create Variant`,
3. edit poses/timing/amplitude,
4. save with a clear name,
5. compare original vs variant,
6. optionally assign variant into a character profile/sequence.

Example names:
- `Roundhouse_A`
- `Roundhouse_Wide`
- `Roundhouse_Compact`
- `Roundhouse_NejiAdapt`

Variants should inherit from source + store only overrides where practical.

---

# 6. Character-specific adaptation workflow

Claude's intended workflow after future moveset research:

`reference movement -> generic Motion Lab block -> character-specific variant -> profile assignment -> Ninja Duel export`

Example:
1. Claude finds a young Lee movement in anime/game/fan animation.
2. Select closest kick in Motion Lab.
3. Create variant.
4. Increase cadence/leg amplitude/forward chase.
5. Edit contact/follow-through poses.
6. Save as `Lee_Roundhouse_01`.
7. Add to Lee motion profile.

For Neji:
- start from common strike/palm block,
- keep compact Gentle Fist posture,
- reduce excessive shoulder swing,
- rotate hips/feet appropriately,
- save Neji-specific variant.

For Gaara:
- body motion can remain minimal while root/arms/pose cues are edited; sand/VFX remain outside this plugin.

For Killer Bee:
- weapon-hand/asymmetry editing should remain compatible with future multi-weapon work.

The editor must therefore make shared motion -> unique expression easy.

---

# 7. Data changes

Extend current model rather than replacing it.

Suggested additions:

```luau
MotionAsset.poseOverrides = {
    { time = 0.0, semantic = "Start", parts = {...} },
    { time = 0.18, semantic = "Anticipation", parts = {...} },
    { time = 0.42, semantic = "Contact", parts = {...} },
    { time = 0.64, semantic = "FollowThrough", parts = {...} },
    { time = 1.0, semantic = "Recovery", parts = {...} },
}

MotionAsset.motionModifiers = {
    amplitude = 1,
    hipRotation = 1,
    torsoFollow = 1,
    limbExtension = 1,
    rootTravel = 1,
    impactLean = 1,
    anticipation = 1,
    followThrough = 1,
}

MotionAsset.timing = {
    duration = ...,
    contact = ...,
    recoveryStart = ...,
    easing = ...,
}
```

Exact schema is Codex's choice if a cleaner extension fits the current code.

Requirements:
- backward-compatible with existing presets,
- serializable,
- import/export preserved,
- undo/redo aware,
- variants remain data-only,
- NinjaDuelAdapter exports edited poses/timings rather than ignoring them.

---

# 8. UI quality bar

Current UI is functional; next version must feel deliberately designed.

Required visual changes:
- stronger visual hierarchy,
- fewer giant generic buttons,
- consistent iconography,
- more compact top toolbar,
- less empty space,
- timeline gets real visual weight,
- cards need thumbnails/visual cues when possible,
- inspector should use grouped sections with labels and compact sliders,
- selected states must be obvious,
- hover states and tooltips,
- important actions primary, destructive actions visually secondary,
- minimum window size still usable,
- 1180×780 should feel comfortable rather than sparse.

Do not chase decorative gradients/shadows at the expense of workflow.
The goal is professional animation-tool clarity.

---

# 9. Hard constraints

- Preserve current useful plugin behavior.
- Do not touch Ninja Duel gameplay runtime automatically.
- Do not publish assets.
- No full Blender/Moon Animator clone.
- No huge graph editor.
- Do not spend time making elaborate visual demos in Studio.
- Code first; automated/smoke checks; user will do native visual review.
- Keep plugin local and reversible.

---

# 10. Definition of done

This pass is done when:

1. UI visibly has better hierarchy and uses available space much better.
2. Timeline is a serious editable part of the workspace.
3. Claude can select an existing motion and create a variant.
4. Claude can change at least semantic key poses, body-part transforms and timing.
5. Claude can exaggerate a weak motion quickly through amplitude/hip/torso/limb/root helpers.
6. Edited motion previews immediately.
7. Edited variant saves and survives restart.
8. Original motion remains intact.
9. Edited variant can be assigned to a sequence/profile.
10. NinjaDuelAdapter exports the edited result in the existing inert/data-only workflow.
11. Tests/build remain green.
12. Final response states exactly what is native-real vs approximated/mock.

Commit message target:
`feat(motion-lab): UI+ and editable motion variants`
