# V1 Boundaries

- Visual game-building geometry, not OSHA/building-code certification or structural engineering.
- Straight stairs, two-flight switchbacks and level straight catwalks only. No ladder, curved/spiral stair, terrain fit, collision detection or arbitrary path editor.
- BasePart positions are inputs; their size/rotation is not inferred as a floor boundary. Start/End must remain in Workspace. Move both markers to reposition, then regenerate; moving the output alone does not move its references.
- The target tread depth and maximum riser calculate a discrete step count. Actual tread/rise can differ and are shown before Build.
- Product safety caps: 1,000 generated Parts, 256 steps; horizontal marker span 0.5-1,000 studs; stair rise 0.2-500. Additional field/geometry limits are validated by Preview, not claimed as Roblox API limits.
- Switchback entrance spacing: Width + 0.5 through Width + 30. Landing depth at least half Width. Landing/return run derives from step count and tread target.
- Supports are vertical posts under decks/landings down to one world-Y baseline. No ground raycasting or stair-flight supports.
- Top rails are present on enabled sides; mid rails optional. The simple rail system does not auto-join separate assemblies or unrelated platforms.
- Six native materials, arbitrary RGB colors, square/cylindrical rail profile. No external meshes.
- Output is independent Parts. No welds, runtime scripts or runtime maintenance. Default Anchored is suitable for static structures.
- Regenerate replaces owned Parts, including their manual edits, while preserving unrelated additions in their folders. Custom descendants inside an owned Part cause a safe refusal. Preserve metadata and original markers to edit later.
- No preset library, networking, AI, analytics or account service. No guarantee for metadata edited by hand or third-party destructive tools.
