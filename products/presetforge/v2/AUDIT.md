# PresetForge V2 programme audit

2026-09-27; issue #15, design only. Canonical `73596873703054`; current package **2.0.0**.
A future catalogue-V2 release must use a new semantic version, not overwrite 2.0.0's identity.

## Real Studio path

DodgeballArena from Nexus-Battles, MIT, copied from `release/scene/PresetForge-Media.rbxl`.
Selected an actual PointLight, clicked Save Recipe, named a temporary Project recipe,
selected Brightness only, saved, selected 21 PointLights, Preview, Apply. Preview showed
4 changes and 17 already matching; native assertion verified all 21 lights at Brightness 4.
This path passed. Undo, persistence after restart and other classes were not rerun.
Full method and limits: [execution record](../../../docs/v2/studio-audit-evidence.md).

## Most important friction

**P1: a narrow restored dock hides the recipe editor behind the fixed library column.**
At roughly 190 px wide the details/actions are not usable. Closing adjacent native panes
and widening the plugin was required before capture/Preview could be completed.
`PresetForge/Modules/UIFactory.luau` has a fixed 210 px library; a minimum-size request
does not handle an already persisted docking arrangement.

Additional observed problems:
- Preview mixes already-matching rows with useful differences. On 21 lights, only four
  need changes, yet the unchanged majority consumes attention.
- "Save and Preview are read-only" is misleading for **Project** recipes: saving writes
  project storage. `Modules/Controller.luau` and `Modules/UIFactory.luau` contain this copy.
- Local/Project scope needs to remain explicit while browsing and saving. A source
  capture is not the same thing as storing it in the place.
- Forced dark panel contrasts with light Studio. Long paths consume limited row width.

## Demand, substitutes and reviews

[Preset manager request](https://devforum.roblox.com/t/preset-manager-for-organizing-and-bulk-applying-properties-attributes-tags-and-collisiongroups-to-instances/1164752)
was revived June 2026 and explicitly asks for organization/search and reusable combinations.
The old [Preset Manager competitor](https://devforum.roblox.com/t/preset-manager-plugin-bulk-apply-properties-attributes-tags-and-collisions/1187701)
already advertises search, duplication, matching objects and collision groups.
[CopyProps](https://create.roblox.com/store/asset/12545467703) offers copying/filtering
properties without a USD purchase button. Native Properties/Explorer and duplicating
a configured object are adequate for many one-off edits. None of these facts proves
customers will pay for our version. Own reviews: zero visible; no buyer complaint to cite.

## Proposed scope, in order

| Change | Evidence / value | Frequency / confidence |
|---|---|---|
| Responsive one-column editing, accessible capture fields and persistent action strip | Reproduced inability to use default restored dock | Every opening on narrow layouts; high |
| Changes-first Preview; select/frame only affected objects; clear storage/write language | 4 changes among 21 lights; source request includes matching/locating | Frequent bulk work; high |
| Search by recipe name plus duplicate-to-edit a variant | Explicit external organization request and incumbent parity; current local small library did not prove scale pain | Frequent only for growing libraries; medium |

Preserve current per-field selection, filters, Project/Local storage, migration, exact
write scope and Undo semantics. These already exist; do not sell them as new V2 functions.

## Reject / defer

Universal reflection/all Instances; arbitrary code recipes; runtime scripts; cloud
sync; generic attribute spreadsheet; presets/stacks with conflict precedence; favourites
before actual library usage evidence. A searchable bounded library is enough initially.
No cross-product framework before a second real consumer.

## Acceptance target for a later release

At 240/320/400 px dock widths, capture the arena recipe without hidden fields; Preview
shows the four changes first and can locate those four only. Apply preserves unchosen
fields, native Undo/Redo is actually verified, local/project saves have accurate labels.
For search/duplication, use a deliberately populated library and preserve original recipes.
First repair the interaction; do not expand the schema/property surface in the same pass.
