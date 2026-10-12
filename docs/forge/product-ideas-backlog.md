# Roblox product ideas backlog

Every item below is **unvalidated**. None should enter development before a focused Creator Store competitive audit covering existing plugins, pricing, reviews, update recency, and native Studio alternatives.

| Observed pain | Possible product direction | Evidence | Status |
| --- | --- | --- | --- |
| Large authored maps accumulate inconsistent repeated instance settings. | Auditable configuration drift scanner with opt-in fixes. | High instance volume in Nexus-Battles; repeated lights, sounds, decals, and parts. | Unvalidated; audit competitors first. |
| Tags and attributes become difficult to inspect across large hierarchies. | Tag/attribute inventory and conflict report. | Frequent tag and attribute APIs in Roblox/resources. | Unvalidated; native Tag Editor may already cover enough. |
| UI assets repeat style values across many GuiObjects. | Narrow UI consistency checker for authored interfaces. | Repeated authored UI configuration in Roblox/resources. | Unvalidated; compare with Studio styles and design-system plugins. |
| Teams need reviewable changes to authored project configuration. | Read-only configuration diff/export tool for Rojo workflows. | Project recipe and version-control needs observed across authored projects. | Unvalidated; compare with Rojo diffs and existing model tools. |
| Effects and audio settings drift between copied fixtures. | Specialized light, particle, and sound audit report. | Repeated light/sound/effect instances in Nexus-Battles. | Unvalidated; may be too narrow or already solved by bulk editors. |
| Runtime-generated worlds are tedious to diagnose but should remain code-owned. | Factory output inspector that produces reports without editing source of truth. | hacker-tycoon is largely assembled by Luau factories. | Unvalidated; likely better served by tests or profiling tools. |
