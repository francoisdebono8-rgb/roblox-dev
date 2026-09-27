# Forge Product Factory — end-to-end Codex workflow

This is the default workflow when the user says anything equivalent to:

> **Create a Forge product from A to Z, publish it and promote/announce it. I only want to handle Creator Hub price and media.**

Codex should execute the pipeline autonomously and stop only for a true account/authentication/permission blocker.

## User-owned steps

The user should only need to perform Creator Hub website-only actions that cannot safely be delegated:
- set/confirm the final USD price;
- upload/arrange icon and screenshots if the website requires the user;
- enable/confirm Creator Store distribution;
- save final Creator Hub web configuration.

Do not routinely hand Studio setup, tests, packaging, listing copy, competitor research, release QA or community-post drafting back to the user.

## 1. Mine demand before inventing a product

Research in this order:

1. **Roblox DevForum → Studio Features**
   - https://devforum.roblox.com/c/feature-requests/studio-features/24
   - Look for repeated missing workflows that a plugin can solve with current APIs.

2. **Roblox DevForum → Building Support**
   - https://devforum.roblox.com/c/help-and-feedback/building-support/56
   - Confirm developers are actually struggling with the workflow in real projects.

3. **Roblox DevForum → Community Resources + `plugins` tag**
   - https://devforum.roblox.com/c/resources/community-resources/74
   - https://devforum.roblox.com/tag/plugins
   - Find current plugins, competitors, complaints, abandoned tools and community reaction.

4. **Roblox Creator Store**
   - Search the actual problem keywords.
   - Inspect free and paid competitors, public price, ratings/votes/reviews, update recency and screenshots/descriptions.

Reddit may be used as supporting evidence, especially for current community pain and willingness to pay, but should not replace the four-source Roblox-native check above.

### Candidate scoring logic

Prefer opportunities with:
- multiple independent people asking for the same workflow;
- repetitive/manual Studio work;
- a solution possible with current plugin APIs;
- an obvious before/after or time-saving story;
- proven use of older/free alternatives;
- recent complaints or missing workflow details;
- room for a simpler, safer, more polished paid implementation.

Reject or hold when:
- native Studio already solves it well;
- a maintained free competitor already provides the exact workflow cleanly;
- the request needs unavailable native APIs;
- the idea is only one person's niche request;
- the product would mostly duplicate an existing Forge plugin.

Record research in `docs/studio-features-opportunity-mine.md` and/or a product-specific competitive-gate file.

## 2. Product gate

Before coding, write a short gate with:
- exact user pain;
- 3+ source links where possible;
- current native Studio behavior;
- direct competitors;
- why the proposed paid product is materially different;
- what NOT to build.

If the gate fails, abandon the candidate and choose another automatically. Do not ask the user to approve a weak duplicate unless there is a strategic reason that genuinely requires a decision.

## 3. Build the smallest complete commercial V1

Create `products/<product>/`.

Requirements:
- focused one-sentence promise;
- clear primary workflow;
- no speculative framework;
- no network/analytics/telemetry/AI/backend unless the product genuinely requires it and the user approved it;
- Preview/read-only stages where destructive or bulk changes are involved;
- native ChangeHistoryService Undo/Redo for mutations where practical;
- transparent, non-executable metadata;
- never modify unrelated project objects;
- no tests/demo/debug content in the commercial artifact.

Use Forge naming when natural, but do not force a bad name.

## 4. Native Studio release gate

Follow `docs/forge-v1-release-checklist.md`.

The exact final commercial artifact must be exercised in real Roblox Studio edit mode.

At minimum:
- all primary customer workflows;
- Preview/read-only behavior;
- mutation scope;
- native Undo/Redo when claimed;
- Edit Existing/Regenerate when claimed;
- invalid-input safety;
- no obvious product exceptions;
- clean commercial package;
- reproducibility/source equality when practical.

Record PASS / FAIL / NON TESTED honestly. Do not publish a product whose core workflow is FAIL or NON TESTED.

## 5. Real-environment commercial media

Use a credible reusable scene/project, preferably visually different for each Forge product.

Allowed sources:
- permissively licensed open-source Roblox projects;
- official Roblox reusable samples/templates;
- Creator Store content only when the usage basis is clear.

Record source, author, URL, revision/version and license.

Create three genuine Roblox Studio screenshots that show three distinct customer outcomes. The environment should look like a real project rather than a QA lab.

No AI/mock screenshots for product UI evidence.

The user may later upload/arrange these media on Creator Hub, but Codex prepares the files and captions.

## 6. Listing and Studio publication

Prepare:
- final title;
- English Creator Store description under current field limits;
- version;
- suggested price;
- keywords/search phrasing;
- quick start;
- limitations;
- release status;
- icon brief if an icon still needs generation.

Publish the plugin asset from Roblox Studio when all gates pass:
- use the clean commercial package only;
- fill title and description;
- choose the user's creator account;
- record the resulting Roblox asset ID;
- never create a duplicate when updating an existing product.
- **New-product duplicate guard:** before submitting, check the user's current plugin creations for the exact title and any asset ID already recorded in the product release docs. If a matching asset already exists from this release attempt, update/reuse it instead of submitting again.
- Treat the first observed `Successfully submitted!` as terminal success. Immediately persist the asset ID/status and stop all further Publish/Save retries.
- Never interpret a delayed/hidden Studio confirmation as permission to submit a second time. Re-check creations/asset metadata first.
- If automation uncertainty remains after a submission, stop and inspect existing creations rather than clicking Save/Submit again.
- If a duplicate is nevertheless created, record both IDs, designate exactly one canonical asset, and flag the other for archive before any Creator Store distribution.

Do not perform website-only pricing/media/distribution steps unless explicitly authorized and safely supported.

## 7. Promotion / announcement pipeline

Every product must leave behind both **promotion research** and **ready-to-post copy**.

Research:
- DevForum Studio Features;
- Building Support;
- Community Resources;
- `plugins` tag;
- relevant older feature requests/support discussions;
- optionally Reddit for supporting outreach opportunities.

Store all targets in:
`docs/outreach/devforum-opportunities.md`

For each target record:
- URL;
- category/date/activity;
- exact problem;
- why the product fits;
- whether the thread is open at last check;
- USE / SKIP;
- a tailored short reply.

### Existing-thread replies

Only target threads where the plugin genuinely helps.

Rules:
- disclose: "I'm the developer" and that the plugin is paid when applicable;
- lead with the workflow/help, not the sale;
- do not post in a direct competitor's showcase/support thread;
- do not revive old solved threads merely to advertise;
- do not mass-post identical copy;
- no fake testimonials or pretending to be an independent user.

### Product announcement

Prepare one **Community Resources** launch post containing:
- problem statement;
- what the plugin does;
- 3 primary use cases;
- 3 screenshots/GIF references;
- price;
- Creator Store link;
- limitations;
- disclosure that it is the developer's paid plugin;
- request for feedback.

If the user has explicitly requested end-to-end promotion **and the authenticated DevForum account has posting permission**, Codex should publish the announcement and a small number of high-confidence targeted replies.

If DevForum permissions are unavailable:
- do not invent success;
- store the final announcement/replies in the outreach library;
- record the permission blocker;
- continue every other release task;
- do not ask the user to do routine manual posting until permissions actually exist.

## 8. Completion report

A full A-to-Z run is complete when:
- product opportunity passed the market gate;
- code is complete;
- native Studio gate passes;
- real-environment screenshots are ready;
- title/description are finalized;
- Studio plugin asset exists and asset ID is recorded;
- outreach targets and tailored messages are stored;
- announcement/replies were posted if account permissions allowed;
- all repo work is committed/pushed;
- only Creator Hub website price/media/distribution remains for the user, plus any unavoidable permission blocker explicitly documented.

Do not stop at "code complete".
