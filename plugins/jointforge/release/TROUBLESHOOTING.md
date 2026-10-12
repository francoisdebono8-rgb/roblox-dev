# Troubleshooting

- **No button:** Verify the local plugin is enabled, then reopen the place or restart Studio.
- **Endpoint rejected:** Use a BasePart inside Workspace. Existing attachments must be direct children of the correct endpoint part. Select one object when assigning an endpoint.
- **Preview blocked:** A duplicate or existing connection path was found, even if disabled. Inspect it. Explicitly remove only the joints you intend to replace, then Preview again. Nothing is silently replaced.
- **Preview stale:** Selection, field inputs, poses or connections changed. Preview again before Apply.
- **Parts do not move in Play:** Check Anchored, collisions, hinge axes and limits. JointForge does not alter those automatically. Existing attachment pivots may pull separated parts together during simulation.
- **Offsets move parts:** This is expected for C0/C1 edits. Undo once; identity reset is not a pose-preserving reset.
- **Removal rejected:** Confirm the displayed removal list. A joint containing children must be handled manually first. Attachments are intentionally retained.
- **Recording unavailable:** Stop Play and finish another active plugin operation. Preview again. Do not use the plugin while another tool is modifying the same assembly.
