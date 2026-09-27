# Troubleshooting

- **No path:** select 2-8 distinct BaseParts in Workspace and confirm the numbered order. Adjacent points must be at least 0.05 studs apart.
- **Preview required:** a point, source or setting changed. Preview again before Build.
- **Too many objects:** increase segment length/spacing or reduce copy count/source complexity.
- **Source rejected:** use an Archivable Part/Model with parts, no scripts and no references/joints to objects outside it.
- **Unexpected rotation:** toggle Preserve local rotation offset, or disable Tangent orientation. The path axis is local -Z; cylinders use their X axis internally.
- **Cannot edit:** select the generated parent Model, not a segment. Its original control points and repeat source must still exist.
- **Undo unavailable:** stop Play and finish any other plugin operation, then retry.
- **Tight bend or self-intersection:** spread out the controls and shorten the target segment length. CurveForge does not resolve self-intersections or simulate rope physics.
