# Troubleshooting

- **No valid Preview:** select two different BaseParts in Workspace. End must be higher for stairs, level for a catwalk. The displayed validation message names the limit to fix.
- **Switchback points the wrong way:** change Left/Right. Markers represent the two entrances; their spacing is across the flights.
- **Regenerate refuses:** select the whole AccessForge assembly. Keep the original markers, Generated groups and metadata. Move children you added inside generated Parts elsewhere. Do not move owned Parts out of their groups.
- **Preview invalid after moving/Undo:** run Preview again or reload with Edit Existing.
- **Undo unavailable:** stop simulation and finish another active Studio operation before retrying.
- **Too many parts:** increase post/support spacing, reduce span/rise, or split the work into smaller assemblies.
- **Panel clipped:** widen/undock it or use its horizontal/vertical scrollbars.
- **Unanchored pieces fall apart:** output has no welds. Use Anchored for static architecture; joining dynamic assemblies is outside this plugin.

For a reproducible issue, include version 1.0.0, mode, dimensions, marker positions and the exact message. Do not send credentials or an entire private project.
