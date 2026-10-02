# SchemaForge / #23 / compact inspector refinement

2026-10-02. User chose A (compact inline inspector) and asked specifically to
revisit the proposed interfaces, typography and effects. Visual acceptance is
still pending; this is not the final reference release.

## References revisited

- [Figma sidebar](https://help.figma.com/hc/en-us/articles/360039832014-Design-prototype-and-explore-layer-properties-in-the-right-sidebar): inspected its actual property-panel image. Inline labels/values, paired numeric fields, understated borders and section separators informed the inspector layout.
- [Raycast settings](https://manual.raycast.com/settings): inspected the application screenshot. Neutral layered surfaces and restrained weight informed the type and state contrast.
- [Linear project overview](https://linear.app/docs/project-overview): revisited the rendered page; earlier desktop comparison remains in the previous pass. No claim of copying its font metrics.
- [Untitled UI sidebar](https://dribbble.com/shots/18288223-Sidebar-navigation-Untitled-UI): revisited the actual reference. Quiet labels, icons and selected-row treatment inform navigation restraint.
- [Kern IDE](https://dribbble.com/shots/27451072-Kern-Agentic-IDE-AI-Code-Editor-UI-UX-Design-Dev-Tool-OPS): inspected the split-pane reference, using its hierarchy rather than copying a decorative web treatment.

Apple HIG pages returned a JavaScript shell; no claim of inspecting their full
guidance. No reference artwork, font or remote dependency enters the product.

## Implemented mapping

Only `SchemaForge/Modules/View.luau` changed in production.

| Refinement | Actual existing behavior preserved |
|---|---|
| 30px inline name/type/default rows; paired Min/Max labels beside values | Existing input owners, drafts, setters and validation |
| Trailing 14px checkbox inside a full 32px clickable row | Required, optional and missing-value repair toggles |
| Sentence-case sections; removed redundant identity/note headings | Existing field, child and contract editor branches |
| Wrapped designer-note field | Same description string and length validation |
| BuilderSans regular 13px values, 12px labels, Medium 15px editor / 18px contract title | Native font family required by the brief, no imported Inter/SF |
| Neutral text and panel tones; quieter 1px borders | Existing Light/Dark theme selection |
| Distinct subtle hover, pressed and focus surfaces | Existing mouse/focus events; no engine calls or new animation |
| Separate mint primary hover/press shades | Existing command and enablement semantics, preserving dark text contrast |

Radius is 4px on fields and 3px on checkbox marks. Inspector stack gap is 4px;
collection gap stays 2px. Long labels retain stacked fields instead of squeezing
them into the inline track. Notes retain a larger editing surface. Destructive
commands are quiet but retain their existing confirmation.

No Main/Engine/Schema/Store change, shared framework, new feature, asset update,
commercial screenshot, listing rewrite or other-product edit.

## Exact artifact and evidence

- Baseline commit: `65390454d61193a92c70351db34b0ecc1d34aa38`.
- Baseline render: [previous 560px Rules](premium-pass/light-560x600-rules.png).
- Current SHA256: `a1dec3006fa7fe5108cdc4652a6d313729b83949cb959742c2c380556199407d`.
- [Manifest](../dist/candidate-1.2.0.json), [native log](inspector-pass/native.txt).
- Temporary harness imports the exact binary, asserts all five source texts,
  and mounts the actual View. The harness is not included in the commercial file.

| Check | Result |
|---|---|
| Luau compilation / diff whitespace | PASS |
| Reproducible binary, five sources / seven instances, private/QA payload check | PASS |
| Native exact-binary Rules Light mount and geometry 560x600 | PASS |
| Native exact-binary Rules Light geometry 320x600 | PASS |
| Complete native 320/560 captures | NON TESTED: floating captures blank; docked view partially visible but clipped |
| Controlled editor / menu / focus / hover / press / save smoke | NON TESTED: foreground/window access unreliable |
| Dark-theme and other widths visual review | NON TESTED this iteration |
| Full 53-test / 41-row regression | NON TESTED: intentionally deferred until visual acceptance |
| Human acceptance / issue #23 completion | PENDING |

The partial native docked image visibly showed the new header, property alignment
and lighter typography, but does not verify the full inspector or its lower
controls. No blank/partial image is presented as successful visual evidence. The
native geometry probe checks instance bounds; it is not aesthetic validation or
a substitute for real mouse interaction. Previous PASS tests belong to previous
binaries and are not transferred to this candidate.

Next visual gate: two complete final-binary Rules captures (320 and 560), actual
field focus/edit, type menu, add/back and audit smoke, then user comparison with
the references. Full regression follows only after visual acceptance.

## Provisional pattern inventory

Reusable candidates: inline property row, paired values, restrained BuilderSans
weights, neutral border/fill states, full-row trailing checkbox and small
section separator. SchemaForge-specific: missing-value repair grouping, actual
contract/attribute/child model, inspection-versus-write semantics and its pane
breakpoint. Nothing is approved for extraction to other products yet.
