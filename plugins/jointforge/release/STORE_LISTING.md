# Creator Store copy

Title: **JointForge — Joint & Constraint Editor**

Version: **1.0.0**

Suggested price after release validation: **USD 7.99** (within the issue's USD 6.99–9.99 target). Price is a hypothesis, not validated willingness to pay.

Tagline: **Build assemblies. See conflicts. Undo safely.**

Short description: Create and inspect common Roblox joints, batch-connect static and moving tool parts, and preview every operation in one focused Studio panel.

## Full description

JointForge brings joint setup into one clear workflow: select endpoints, choose a type, Preview, Apply.

Assemble a multi-part tool with a chosen root. Classify pieces as Static for WeldConstraint or Moving for Motor6D. Preview the complete assembly before one Undo-compatible operation. Existing connections are preserved and conflicts block Apply.

Inspect selected parts or a model, locate existing joints, select either endpoint and identify missing endpoints. Edit key constraint properties and readable C0/C1 offsets. Removing joints requires a preview and explicit confirmation.

Supports WeldConstraint, Weld, Motor6D, HingeConstraint, BallSocketConstraint, RopeConstraint, RodConstraint, SpringConstraint and NoCollisionConstraint. Reuse attachments or create them alongside a new physical constraint.

Built-in short instructions keep the workflow close at hand. No external services, analytics or telemetry.

## Limitations / privacy

Studio edit mode and Workspace objects only. Numeric offsets, not custom drag handles. Not an animation or character-rig editor. No IK/FK, asset browser or automatic physics repair. Creation preserves world poses within engine precision; editing offsets or simulating physical constraints can move parts. Existing attachment reuse requires direct BasePart children. Conservative conflict checks can reject a deliberate multi-constraint mechanism; configure that advanced case in Studio instead.

No network calls or external data collection. No account registration or persistent plugin library. Plugin UI state is temporary; Studio stores the created instances in your place.

Natural search terms: weld editor, Motor6D, tool assembly, joint inspector, Roblox constraints, hinge, rope, spring, batch weld, Studio plugin.

Upload only `../dist/JointForge-v1.0.0.rbxm`; see `../dist/manifest.json` for its hash. Do not upload tests, build tools or the demo as the plugin.
