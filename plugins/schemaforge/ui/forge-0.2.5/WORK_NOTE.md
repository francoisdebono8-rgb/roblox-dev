# Issue #30 implementation record

Source of truth: #30 and master #35 fetched with body/comments on 2026-10-03.
Mandatory Forge Studio UI contract read; #35 allows parallel implementation.

## Baseline and mapping

Commit and original dirty View hash are in [baseline.json](baseline.json), together
with the prior accepted lockup/dist/engine hashes protected by the build.
Baseline captures: [320 lockup](../brand-review/lockup-dark-320.png),
[560 lockup](../brand-review/lockup-dark-560.png), and
[previous Audit composition](../brand-review/dark-560-audit.png).
The previous Audit capture predates the accepted lockup; it is workflow baseline,
not final branding evidence. These existing files were inspected and preserved.

The accepted list/detail, paired values, restrained mint and BuilderSans composition
remain the reference. #30 adds result clarity to that accepted composition.

| Visible element | Real source/action | Implementation |
| --- | --- | --- |
| Checked / Valid | Engine.audit matched / valid | AuditSummary.fromAudit |
| Objects with issues | Unique finding.instance identities | No subtraction by finding count |
| Findings / Safely repairable | All issues / issues with engine-provided fix | Never inferred from category |
| Summary stale status | Existing Engine.isFresh, schema/scope/selection invalidation | Historical counts muted, stale caption |
| Load contract -> Audit | Store.load and its original token | No automatic project write or audit |
| Capture reference -> contract settings | Schema.capture | Explicit review; defaults remain opt-in |
| Rules -> Audit | Existing Engine.audit | One action instead of navigation + action |
| Finding inspector | Original expected / actual / description | Unchanged exact engine text |
| Safe repair / Preview / Apply | Finding.fix / Engine.preview / Engine.apply | Existing additive transaction unchanged |
| Select in Studio | Original finding.instance | Existing exact selection behavior |
| Catalogue release | Native DockWidget title | Internal semver remains 1.2.0 in manifest |

Visual thesis: the audit result is readable before the detailed diagnostic.
Content hierarchy: contract -> result totals -> findings/detail -> reviewed additions.
Interaction uses existing hover, selected rows and immediate list/detail transitions;
no new ornamental motion or artwork. No shared framework and no attribute editor.

The result band uses one row at 560, three plus two metrics below 560. It remains
outside the pane scroll so filters and findings cannot hide the overall result.
Empty/no-match/all-valid are distinct. Existing footer and write guards stay stable.

Native geometry, text fit, Light/Dark contrast and before/after comparison remain
NON TESTED for this exact artifact. The additional band must be checked at 240x360;
scrollable findings must remain reachable while primary actions stay visible.
