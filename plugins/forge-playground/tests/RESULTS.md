# Playground #29 Native Validation

## Automated Suite

Roblox Studio 0.741.19.7411056, 2026-10-03, 13:40:56 UTC:
**27 passed / 0 failed**. The earlier 12-test toy-prototype result is superseded.
The first new-suite run found a Joint adapter member/method naming collision;
the correction was made in Playground only and the entire suite rerun.

The QA modules were imported through Studio's native Import Roblox Model command
into the local temporary QA place. The naming correction was then synchronized
into that copy before the passing run. The final responsive client was also
synchronized and the whole suite rerun; see [native-parity.log](evidence/native-parity.log).
No plugin installation, capability
override, Store update or publication was used.

Coverage in `Runtime.server.luau`:

- Protocol defaults, invalid actions/options/indexes, NaN and bounds.
- Token bucket refill and inactive-station mutation rejection.
- Access START gate; all valid modes with/without rails; production plan equality
  and generated parts; invalid endpoints preserve committed output.
- Curve Cable/Repeat path and output equality, regeneration, ghost collision
  flags and production stale-control rejection.
- Joint diagnostic equality with Graph/Planner; invalid endpoint rejection;
  endpoint repair; explicit redundant-joint removal; pivot/axis repair.
- Schema exact audit categories/counts; eight safe additive repairs; preservation
  of wrong type/range/hierarchy; stale audit rejection.
- Preset exact PreviewService sets/counts/diffs, read-only preview, Color-only
  field preservation, Color + Brightness, stale plans and fixture boundary.
- Exact reset baselines, isolation of two Session objects, navigation cleanup,
  session destruction.

Build checks: embedded Luau scripts compile; normal/QA Rojo builds pass; source
equality is checked against a second XML build of the same inputs; normal build
contains no RuntimeQA or plugin entry point. This is not independent binary
round-trip verification.
Studio's 36 native scripts (including QA) also matched final source lengths and
rolling checksums at 13:43:44 UTC. Cryptographic file hashes are in the manifest;
the native rolling checksum is an additional synchronization check.

## Native UI Evidence

Unretouched screenshots from the actual Studio Play session, for internal QA only.
They show the runtime interface, not the Studio plugin DockWidgets:

| File | Observed |
| --- | --- |
| [access-native.png](evidence/access-native.png) | START -> Preview -> Build: 14 steps, 30 parts, solid output. |
| [curve-native.png](evidence/curve-native.png) | Repeat: 12 copies, 43.9 studs, 282 adaptive samples. |
| [joint-native.png](evidence/joint-native.png) | Four joints / eight findings; broken endpoint and explicit repair. |
| [joint-repaired-native.png](evidence/joint-repaired-native.png) | Missing endpoint resolved; fresh duplicate diagnostic selected. An anchored-both finding replaces the repaired broken-endpoint finding, so the total can stay eight. |
| [schema-native.png](evidence/schema-native.png) | Real Health Expected/Actual and additive repair eligibility. |
| [preset-native.png](evidence/preset-native.png) | 18 affected / 6 matching / 48 ignored, 18 writes. |
| [preset-applied-native.png](evidence/preset-applied-native.png) | Cyan target lights, ignored white lights, 0 affected / 24 matching after Apply. |
| [mobile-landscape-native.png](evidence/mobile-landscape-native.png) | Final compact client in iPhone XR 896x414 native emulation; controls remain accessible, character touch controls hidden in demo view. |

Desktop navigation, real remote calls, Access build, Curve Repeat build, Joint
repair, Schema audit/additive repair and Preset preview/apply were exercised.
Screenshots retain Studio chrome and are not commercial media.
Desktop screenshots precede the compact-height/client movement-control adjustment;
the station engines and desktop layout are unchanged. The mobile screenshot and
final parity log follow that adjustment. The place uses Roblox's default landscape
orientation; portrait is not enabled and is not claimed as accepted.

## Remaining Release Acceptance

- Two real networked clients, disconnect/rejoin, respawn and sustained six-player
  operation: not yet accepted. Two-session isolation is not a substitute.
- Real mobile devices and controller navigation: not yet accepted.
- Full walkability and world polish: later iteration. Access parts are collidable,
  but not every generated path was traversed by a character.
- Roblox publication: not performed. This is a local/GitHub functional V1.
