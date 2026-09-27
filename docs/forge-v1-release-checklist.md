# Forge V1 Release Standard

Commercial artifact -> native Studio smoke test -> reusable real scene -> three genuine screenshots -> store copy -> Studio asset publication/update -> user configures Creator Hub.

1. Rebuild and compare the commercial artifact to the committed sources. Record SHA-256. Allow only production scripts; exclude tests, demo, debug paths and dependencies.
2. Install that exact artifact locally. Use an isolated Studio edit-mode place. Execute every main customer workflow once, assert read-only preview, intended changes only, source preservation, actual native Undo/Redo and no plugin exceptions. Record PASS / FAIL / NON TESTED with logs. Compilation is not a native PASS.
3. Select a credible reusable project/scene. Record its URL, author, pinned revision and license. Reject ambiguous content. Keep external assets/code outside the commercial plugin. Prefer distinct environments across products.
4. Capture three real Studio screenshots with the actual plugin panel readable and useful scene context visible. No mock UI, AI screenshot, private paths or account details. Record order and captions.
5. Refresh English title/description, version, suggested price, keywords, limitations, quick start, package path/checksum and this product's release status.
6. Record the existing asset ID before any update. Never create a second asset for an already-published product. Update only when Studio clearly targets that ID. For a new product, publish in Studio only after the native and media gates pass. Do not accept legal terms or identity/payment steps on behalf of the user.
7. Stop after the Studio-side asset exists. The user owns Creator Hub distribution, pricing, website-only media/listing fields and final web publishing controls. Commit and push only the relevant release changes.

Do not label a product V1-ready if a primary workflow is FAIL or NON TESTED. Leave the issue open when required work is blocked. No V2 feature work, benchmark claims without measurements, exhaustive edge-case campaign or common branding redesign in this pass.
