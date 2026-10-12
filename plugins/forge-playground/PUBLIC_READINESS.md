# Forge Playground / public readiness

2026-10-03, #42 under #36. **NOT READY for public release. Preparation pack ready.**
No publication, account change, production-module change or rebuilt place in this pass.

## Frozen truth
The [functional V1](STATUS.md) is a local demonstration, not an approved public world.
Use [`dist/Forge-Playground-v0.1.0.rbxl`](dist/Forge-Playground-v0.1.0.rbxl), SHA256
`a9788df03effe32aa568f0b13b7275221fb62458946423c39cf22f21f2e5dda5`.
The place uses real production planners/validators through a runtime adapter, not a
Studio plugin inside Player. No purchase, install, plugin ownership or project export
is granted by visiting. Reset rebuilds a station; it is not Studio Undo.

Prior execution: **27/27 native tests PASS**, desktop station interactions and
iPhone XR 896x414 Studio-emulator checks, as recorded in [RESULTS](tests/RESULTS.md).
Those results are retained, not rerun or relabeled as public-network/mobile-hardware QA.
The source manifest is [here](dist/manifest.json). The 36 native script matches
recorded in #29 include QA scripts, not 36 commercial modules. This pass checked
the saved binary hash and all 35 source hashes in the normal-build manifest;
that is not a new independent binary round-trip or native execution.

## World/art pass to implement before release
Status of this section: **specified, not implemented or visually accepted**. Keep
station engines, options, isolation and computed results intact.

- Retain the compact industrial workshop and five 44x42 station stages. Give the
  central spawn a clear view of product signs and unobstructed routes to all stations.
  Frame the demonstrations instead of adding decorative scenery that hides them.
- Add consistent entrances: product name, one action/result sentence, then its real
  objects. Keep each station's engine output central; no decorative fake stairs,
  repair counters or repeated props presented as generated output.
- Use existing primitive concrete/metal surfaces and simple lighting; no third-party
  models, audio, textures or uncertain asset rights. No new monetization/gameplay loop.
- Match [canonical identity](../../docs/forge/forge-studio-ui/brand/CANONICAL_COVER_FAMILY.md):
  Schema mint `#63D6AE`, Preset amber `#D1A348`, Curve blue `#4D7DD2`, Access violet
  `#A34BC5`, Joint copper `#D77A3E`. Current Catalog swaps some of these families
  (Schema purple, Access yellow, Preset teal); this is an explicit public-polish gap.
  Preserve semantic error/warning colors. Yellow rail paint is not Access branding.
- Leave adequate neutral contrast and diffuse light on output geometry. No glossy
  in-game UI, huge cover logos, flashing/bloom-heavy attractions or unreadable signs.
- Desktop: scene should remain the dominant area with readable controls beside it.
  Mobile landscape: keep the active action, current result and selected object visible;
  scroll secondary options. Do not claim phone support from an emulator screenshot alone.

## Short onboarding / station signs
Approved-for-implementation draft, not already installed text:

> Try five building and inspection workflows on sample objects. Choose a station, review its result, then Build, Apply or Repair. Reset starts that station again.

Persistent disclosure:

> Demo only. Forge Studio plugins work on your own projects in Roblox Studio. Playing does not install or unlock a plugin.

Station promises: Access "Connect two platforms"; Curve "Move a path, reshape its output";
Joint "Find and repair a connection"; Schema "Find misconfigured objects";
Preset "Change only the selected fields". These describe actual station actions.
Do not add account prompts, sales popups, purchase buttons or plugin installation claims.

## Five 10-20 second hero flows
Times are capture/edit targets, not promised user completion times. Runtime results
are not interchangeable with the plugin QA fixtures' counts.

| Station | 0-3 s problem | 3-12 s real action | 12-20 s proof / stop condition |
| --- | --- | --- | --- |
| Access | Two platforms without access | Choose START and Straight destination; Preview then Build | Actual 14 steps / 30 parts in the recorded default fixture; frame rails/endpoints. Reset restores fixture. |
| Curve | Cable/props follow a path needing adjustment | Choose Repeat, point 2, change offset, Preview then Build | Real moved path and 12 copies by default. Baseline recorded 43.9 studs; do not force that length after offset. |
| Joint | Mechanism has a missing endpoint | Scan, select broken joint, choose Handle explicitly, Repair selected, Scan | Endpoint is really assigned. Baseline 4 joints / 8 findings can remain 8 after a different diagnostic appears; never promise a lower total for every repair. |
| Schema | Configured crates contain missing/wrong data | Audit, inspect one missing/default finding, Safe repair selected, Audit | Only chosen safe additions; wrong types/ranges/children remain. Fixture has 24 tagged crates and 8 possible safe additions before selection. |
| Preset | Some lights differ, some already match | Cyan / Color, Preview, inspect a row, Apply recipe | 24 compatible / 18 affected / 6 matching; 18 Color writes, not Brightness. After apply: 0 affected / 24 matching. Fixture includes 36 lights, 72 descendants. |

## Actual routing and lifecycle
- Current server creates a workshop per player, at most six, with server-validated
  option values and rate-limited requests. Session objects are removed on leave.
  This is source inspection, not a six-client test.
- `Session.current` and the client default to Access. No product-specific launch-data
  route exists. All future listing links should use one common entrance, then the
  visible product tab. Do not publish five invented deep links.
- Server `CharacterAdded` moves the new character to the workshop spawn. Client GUI
  has `ResetOnSpawn=false` and updates the camera on respawn. Existing station state
  is in the session; rejoin creates a fresh session. Public respawn/camera behavior
  still needs real execution; do not label source code as PASS.
- Physical workshops share Workspace. Verify visitors cannot enter and obstruct
  another workshop or alter it through remote actions. Existing session isolation
  tests do not prove physical-avatar separation on a real server.

## Listing to destination mapping
| Canonical plugin | Destination after public approval | Current entry route |
| --- | --- | --- |
| SchemaForge `84085408748744` | Schema station | Common spawn / SchemaForge tab |
| PresetForge `73596873703054` | Preset station | Common spawn / PresetForge tab |
| CurveForge `90642263224333` | Curve station | Common spawn / CurveForge tab / Repeat |
| AccessForge `127360597946823` | Access station | Common spawn / AccessForge tab |
| JointForge `103958912217728` | Joint station | Common spawn / JointForge tab |

**Try-in-Roblox is conditional, not a promised plugin feature.** Roblox's March 5,
2026 [official announcement](https://devforum.roblox.com/t/try-in-roblox-for-the-creator-store/4473605)
specifies Models and MeshParts. The general [Creator Store guide](https://create.roblox.com/docs/production/creator-store)
mentions a demo configuration field without establishing eligibility for these five
plugin assets. Confirm its presence only after release authorization. If absent,
use an ordinary permitted demo link in listing copy after a real public place URL
exists. Do not create duplicate model assets to manufacture that button.

## Required acceptance before public access
All rows below are **NON TESTED for public release**, not known failures. Targets
are proposed acceptance criteria, not measured performance or marketing claims.

| Gate | Executable protocol | Accept only when |
| --- | --- | --- |
| Art/onboarding | Fresh visitor on desktop; reach each station and explain its result without assistance | No obstructed route, clipped sign/control or ambiguous plugin-ownership claim; identity matches catalogue |
| Desktop | 1280x720 and 1920x1080; all five flows, scrolling, repeated Reset, Explore/Demo view | Every action/result readable, keyboard/mouse usable, no overlay blocking the active object |
| Real mobile landscape | One physical iOS and Android phone; all five flows, rotate portrait/landscape, respawn | No trapped controls, accidental double apply, unreadable result or lost camera; document devices, not generic "mobile PASS" |
| Controller plan | Initial focus on active station; shoulders/tabs or D-pad navigation; A activates; B returns to scene; explicit focus links for dynamic lists | Every station, option, result row, Reset and Explore reachable; selection visible and recovers after rebuild. Current code has no explicit gamepad focus graph; do not enable console distribution on assumption |
| Two clients | Local server with 2 Player clients, distinct stations and divergent settings; simultaneous actions; rejected invalid requests | Other player's state/output unchanged, no cross-session writes, no remote trust bypass; record both clients and server |
| Respawn/rejoin | Build/apply at every station, respawn during preview and after apply; leave/rejoin while second client stays | Camera/controls recover, documented session state consistent; departed workshop removed; other client's work untouched |
| Six-player soak | Server + 6 real clients for 20 min; rotate all stations, each 10 preview/apply/reset cycles, repeated enter/leave and one seventh join | Six isolated workshops, seventh safely refused, no accumulating orphan outputs/connections or Output exceptions; retain counts/logs before/after |
| Performance | Record desktop + actual phone frame time, server time, memory and instance counts after warm-up and during soak | Proposed targets: p95 frame <=33 ms desktop / <=50 ms phone; no sustained stall >500 ms; no monotonic retained-memory/instance growth across 10 reset cycles. Revise with evidence, never assert PASS without measurements |
| Public-service behavior | After explicit authorization only, private Roblox server/device check of permissions/assets/rejoin | Same behavior outside Studio; no missing assets, invalid links, account/permission errors or unintended purchases |

Until those gates and final media pass, keep **NOT READY**. A later targeted fix
must rebuild the place, update its source manifest and rerun impacted parity/native
checks; it must never silently swap the five commercial plugin binaries.
