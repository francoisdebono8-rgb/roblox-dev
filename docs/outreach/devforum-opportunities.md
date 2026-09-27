# Roblox Developer Forum outreach opportunities

Last researched: 2026-09-27.

Status note: the indexed DevForum pages below did not show a "Closed" notice when re-checked on 2026-09-27. Always verify again immediately before posting because topic status can change.

---

## PresetForge

### HIGH — Preset Manager for organizing and bulk-applying Properties, Attributes, Tags, and CollisionGroups

- URL: https://devforum.roblox.com/t/preset-manager-for-organizing-and-bulk-applying-properties-attributes-tags-and-collisiongroups-to-instances/1164752
- Category: Studio Features / Feature Request
- Original need: presets generated from instances; bulk apply properties, attributes and tags; select matching instances; copy/paste configuration.
- Freshness: old request, but activity includes a June 2026 bump.
- Fit: extremely high. This overlaps directly with PresetForge's safe recipe, filtered scope, Preview/diff and Apply workflow.
- Use: YES, once reply permissions are available.
- Avoid claims that PresetForge implements collision groups unless/until it actually does.

Draft reply:

> This is very close to a workflow I ended up building a Studio plugin around. Disclosure: I'm the developer and it's a paid plugin.
>
> PresetForge lets you capture selected properties, attributes and tags from an instance as a reusable recipe, preview the exact before/after changes, then apply it to a selection or filtered descendants with native Undo/Redo.
>
> It doesn't try to replace every part of the feature request, but for the "save a configuration and safely bulk-apply it" workflow it may be useful while Studio doesn't provide this natively.
>
> [CREATOR_STORE_LINK]

### HIGH — Bulk copy and paste attributes in property window

- URL: https://devforum.roblox.com/t/bulk-copy-and-paste-attributes-in-property-window/3576978
- Category: Studio Features / Feature Request
- Date: March 2025
- Need: copy multiple attributes from one instance and paste them onto one or more instances.
- Fit: high and easy to explain.
- Use: YES if still open; keep the response short because the requested native feature is simpler than the whole plugin.

Draft reply:

> I built something that can cover this workflow while the native feature is missing. Disclosure: it's my paid plugin.
>
> PresetForge can capture attributes (plus selected supported properties/tags) from a source, preview exactly what will change, then apply them to multiple selected or filtered instances with one Undo.
>
> If that's still useful for your workflow: [CREATOR_STORE_LINK]

---

## JointForge

### HIGH — Adding Joint Types to tools

- URL: https://devforum.roblox.com/t/adding-joint-types-to-tools/4352889
- Category: Engine Features / Feature Request
- Date/activity: February-March 2026
- Need: easier Weld/Motor6D workflows for tools and animated assemblies.
- Fit: high for Studio-side assembly, but JointForge does NOT replace the requested engine/runtime Tool behavior.
- Use: YES, with that limitation stated explicitly.

Draft reply:

> This wouldn't replace the engine-level Tool.JointType behavior you're requesting, but I built a Studio-side tool for the assembly part of this problem. Disclosure: I'm the developer and it's paid.
>
> JointForge lets you choose a root, batch-connect static parts with WeldConstraints and moving parts with Motor6Ds, preview the connections before applying them, inspect existing/broken joints, and undo the whole operation natively.
>
> If the painful part for you is setting up the assembly in Studio, it may help: [CREATOR_STORE_LINK]

### SKIP — competitor showcase/support threads

Do not advertise JointForge in:
- "Welds and Motors" plugin showcase
- qPerfectionWeld / Bind / other plugin resource threads

These are useful competitor/review sources, not outreach targets.

---

## CurveForge

### HIGH — Studio Feature or Plugin that repeats a pattern on scaling or resizing

- URL: https://devforum.roblox.com/t/studio-feature-or-plugin-that-repeats-a-pattern-on-scaling-or-resizing/4095587
- Category: Building Support
- Date: November 2025
- Need: stop manually duplicating the same model repeatedly; repeat geometry/patterns, including around curves.
- Fit: very high for CurveForge Repeat Model mode.
- Use: YES.

Draft reply:

> If you're still looking for this kind of workflow, I built something specifically around it. Disclosure: it's my paid plugin.
>
> CurveForge can repeat your own Part or Model along an editable 3D path. You can set spacing or copy count, optionally align the copies to the path, Preview it first, then reopen the generated path later and Regenerate after moving the control points.
>
> So it's closer to "repeat this model along a path" than stretching the source object.
>
> [CREATOR_STORE_LINK]

### MEDIUM — How do I make a 90 degree smooth curve at an upward angle?

- URL: https://devforum.roblox.com/t/how-do-i-make-a-90-degree-smooth-curve-at-an-upward-angle/3518614
- Category: Building Support
- Date: March 2025
- Need: create a smooth upward curved railing in Studio without getting good results from common tools.
- Fit: partial. CurveForge can make a smooth cable/pipe-like curved element and repeat models along a 3D curve, but it is not a general-purpose mesh/CAD railing modeller.
- Use: ONLY if a genuine CurveForge demo reproduces something close to the requested shape. Otherwise skip.

Possible reply if validated:

> I ran into a similar "3D curve inside Studio" problem and built CurveForge. Disclosure: it's my paid plugin.
>
> It can create cable/pipe-style geometry along a multi-point 3D path, or repeat your own model along that path, and the result stays editable/regeneratable. It isn't a full CAD/mesh modeller, but for a railing made from repeated pieces or a simple rail profile it may fit.
>
> [CREATOR_STORE_LINK]

---

## AccessForge

Status: product is not yet published. Do not post anything until the competitive gate passes, the product exists, and its advertised workflows pass native Studio QA.

### Candidate — Building stairs in Roblox

- URL: https://devforum.roblox.com/t/building-stairs-in-roblox/2471185
- Category: Building Support
- Date: July 2023
- Need: user finds good-looking stairs unexpectedly difficult to build and asks for practical construction guidance.
- Fit: potentially strong for automatic stairs, but the thread is old.
- Use: RECHECK after AccessForge is live; prefer a newer active thread if one exists.

### Candidate — smooth upward stair railing

- URL: https://devforum.roblox.com/t/how-do-i-make-a-90-degree-smooth-curve-at-an-upward-angle/3518614
- Category: Building Support
- Date: March 2025
- Need: difficult stair railing geometry.
- Fit: only if AccessForge's final guardrail behavior genuinely addresses the requested shape.
- Use: RECHECK after product validation; do not promise curved/90-degree rail functionality unless shipped.

### Search queries to rerun at launch

- `site:devforum.roblox.com stairs railing "Building Support" Roblox Studio`
- `site:devforum.roblox.com catwalk stairs Roblox Studio plugin`
- `site:devforum.roblox.com industrial stairs warehouse Roblox Studio`
- `site:devforum.roblox.com staircase railing plugin Roblox Studio`
- `site:devforum.roblox.com stairs difficult building Roblox Studio`

---

## Posting workflow

When the user's DevForum account gains reply permission:

1. Open the thread and verify it is still open.
2. Read the latest replies so the draft is not outdated.
3. Confirm the plugin still solves the problem exactly as described.
4. Replace `[CREATOR_STORE_LINK]` with the real public listing.
5. Shorten/customize the draft to match the conversation.
6. Clearly disclose "I'm the developer" and "paid plugin" where applicable.
7. Post once; do not bump repeatedly.
8. Record the post date/link here so the same thread is not targeted again.
