# SchemaForge — Premium Visual Polish Pass

Status: **binding visual implementation brief for issue #23**.

This pass exists because the current UI architecture is now sound, but the actual
320px rendering still reads too much like a clean Roblox utility/form. The target is
a **premium professional developer tool**: restrained, precise, calm, deliberate,
and good enough that the real plugin UI can be used as product imagery without
redesigning it.

This is not a functional V2 pass and not a new QA campaign.

---

# 0. Working rule: visual decisions must not be silently invented

During this pass, do not silently resolve a high-impact visual/UX ambiguity when
different choices would materially change:
- the Forge Studio visual language;
- the user's perception of "premium";
- the reusable pattern for the other four plugins;
- navigation or information hierarchy;
- density or interaction behavior.

When such a decision appears, surface it to the user/assistant **before locking it in**.

Use this format:

## Design decision needed
**Question:** one precise implicit question.

**Why it matters:** what visible behavior/silhouette changes.

**Option A:** ...
**Option B:** ...
**Option C:** ... only if genuinely useful.

**Recommendation:** choose one and explain briefly why it best matches the references.

**Default if no answer:** state the safest reversible default.

Do not ask trivial implementation questions. Batch related questions when possible.

Maximum recommended interruption points for this pass:
1. shell / navigation / density;
2. Rules list + inspector interaction;
3. final visual comparison / remaining polish.

Examples of questions worth surfacing:
- Should wide navigation use text-only rows or 14–16px neutral icons + labels?
- Should the selected rule use a subtle filled surface or mostly border/rail treatment?
- Should Add attribute live in the Attributes section header or as a final compact list row?
- Should the Draft/Saved state be a tiny chip, dot+label, or plain metadata?
- On 320px, should selecting a rule replace the list with its inspector, or open an inline editor beneath the selected row?
- Should secondary footer actions be ghost buttons or plain text actions?
- Should Light theme preserve depth through neutral gray surfaces or use a near-white continuous canvas with separators?

Do not ask whether to use glows, giant cards, or gaming chrome: those are already rejected.

---

# 1. Real references — inspect these before changing code

These references are not interchangeable. Each contributes a specific lesson.

## A. Kern — Agentic IDE / developer tool
https://dribbble.com/shots/27451072-Kern-Agentic-IDE-AI-Code-Editor-UI-UX-Design-Dev-Tool-OPS

Use for:
- overall developer-tool silhouette;
- dense split-pane composition;
- dark neutral surfaces;
- thin separators;
- clear primary work area;
- action-state transparency;
- restrained "serious software" feel.

Do NOT copy:
- brand colors;
- AI-specific content;
- decorative effects not possible/appropriate in Roblox Studio.

## B. Untitled UI — Sidebar navigation
https://dribbble.com/shots/18288223-Sidebar-navigation-Untitled-UI

Use for:
- quiet navigation rows;
- restrained active state;
- hierarchy through spacing and typography instead of filled buttons;
- clean counts/secondary metadata;
- consistent row rhythm.

Do NOT turn every navigation item into a card.

## C. Linear — real production app
Project/details sidebar:
https://linear.app/docs/project-overview

Favorites/sidebar behavior:
https://linear.app/docs/favorites

Use for:
- list/detail relationship;
- persistent context;
- information-dense but calm sidebar;
- progressive disclosure;
- selected object detail without losing place;
- secondary information kept secondary.

Important: do not copy automatic preview/peek behavior here.
SchemaForge inspection remains explicit/local and Preview remains a separate command.

## D. Raycast Settings v2 — real production macOS app
https://manual.raycast.com/settings

Use for:
- compact settings organization;
- calm macOS-native feeling;
- few visual layers;
- clear sectioning without card-everything;
- strong settings hierarchy;
- polished low-chrome controls.

## E. Figma properties/inspection sidebar — real production app
https://help.figma.com/hc/en-us/articles/360039832014-Design-prototype-and-explore-layer-properties-in-the-right-sidebar

Use for:
- purpose-built inspector behavior;
- grouped property sections;
- compact related controls;
- selected object properties as a coherent panel;
- advanced values visually quieter than identity/core values.

## F. Apple Human Interface Guidelines — hierarchy, layout, sidebars, buttons
Layout:
https://developer.apple.com/design/human-interface-guidelines/layout

Sidebars:
https://developer.apple.com/design/human-interface-guidelines/sidebars

Buttons:
https://developer.apple.com/design/human-interface-guidelines/buttons

Use for:
- strong alignment;
- obvious hierarchy;
- grouping related information;
- controls visually distinct from content;
- compact navigation when width is limited;
- one clear role per button;
- familiar, predictable interaction.

Do NOT attempt fake Liquid Glass or platform imitation inside Roblox Studio.
We want the **discipline**, not a macOS skin.

---

# 2. Target feeling

The UI should feel closer to:

**Linear + Raycast + Figma inspector inside a compact developer tool**

than to:

**Roblox plugin settings form / SaaS dashboard / admin panel**.

Keywords:
- precise;
- quiet;
- compact;
- premium;
- deliberate;
- predictable;
- high-information-density;
- low-chrome;
- professional.

Avoid:
- playful;
- gamified;
- glossy;
- card-heavy;
- oversized;
- decorative;
- dashboard template;
- Roblox settings menu.

"Apple premium" here means:
- confidence through restraint;
- hierarchy before decoration;
- exact alignment;
- carefully controlled density;
- one dominant action at a time;
- subtle interactive feedback;
- almost no visual noise.

---

# 3. Current 320 Rules screenshot — explicit critique

The current real Light 320 screenshot is the baseline for this pass.

Problems to solve:

1. The large white rounded work card dominates the screen.
   - It reads like a mobile form container, not a professional inspector.
   - Too much visual separation from the window/background.

2. The Rules/Audit/Repairs/Library navigation is improved but still visually large.
   - The active Rules area occupies too much vertical/colored space.
   - The navigation should feel like a compact mode strip, not four large destinations.

3. Contract settings is visually floating in dead space.
   - It should behave like a compact list row / section entry.

4. The ATTRIBUTES section has too much air between rows.
   - Cost, Enabled, GrowthRate should read as one scannable collection.

5. Selected Cost is still a relatively large rounded card.
   - Selection should feel precise, not inflated.

6. The full-width Add Attribute button strongly reinforces the form-utility feeling.
   - Replace it with a compact section action or subtle final-row affordance.

7. CHILDREN repeats the same large-form rhythm.
   - It should be a second compact collection, not a new page section with excessive whitespace.

8. Footer:
   - Project contract / 1.2.0 has too much visual presence for metadata.
   - Audit and Save contract are still large rectangular controls.
   - Save should be dominant only when meaningful; Audit is secondary.

9. The screen has too many rounded rectangles.
   - Premium != more containers.
   - Use separators, alignment, typography, and surface tone first.

10. The screen lacks small affordance details that make real software feel finished:
   - precise section header/action alignment;
   - subtle disclosure/selection cues;
   - compact state labels;
   - consistent row baselines;
   - clear but quiet hover/focus states.

---

# 4. Visual system for this pass

## 4.1 Surfaces

Use no more than four meaningful depth levels:

1. window/background;
2. primary work surface;
3. selected/raised inspector or focused region;
4. interactive hover/focus state.

Rules:
- wide mode should feel mostly like **continuous split panes**, not floating cards;
- narrow mode can use one dominant surface but avoid a giant rounded white card;
- use 1px separators where they communicate structure;
- avoid drawing a border around every group;
- avoid shadow unless extremely subtle and native-looking;
- radius target: 4–6 px for most controls/surfaces;
- reserve 8 px only for a genuinely important contained block if needed.

## 4.2 Color

SchemaForge accent remains mint #63D6AE.

Target mint coverage: roughly **5% or less** in normal states.

Mint is for:
- current selection indicator;
- focus;
- repairable/safe semantics;
- active mode;
- primary action.

Do not use mint as:
- large nav fill;
- large card background;
- default text color;
- decorative wash.

Semantic error/warning colors remain independent.

### Light theme

Avoid pure white card on a gray page as the main composition.

Prefer:
- very light neutral app background;
- small tone differences between panes;
- separators;
- selected surface with restrained mint/neutral tint.

### Dark theme

Prefer:
- near-black/charcoal base;
- pane differences of only a few luminance steps;
- border/separator lower contrast than text;
- no neon glow.

## 4.3 Typography

BuilderSans remains mandatory.

Suggested hierarchy:
- Product identity: 12–13px semibold, muted.
- Contract/work title: 17–19px bold.
- Metadata: 11–12px regular/muted.
- Pane title: 14–16px semibold/bold.
- Section label: 10–11px semibold/uppercase only when useful.
- Row primary: 13–14px semibold.
- Row metadata: 11–12px regular.
- Inspector work title: 16–18px bold.
- Value emphasis: 13–15px semibold/bold.

Do not make every label semibold.
Do not use uppercase widely.
Do not use typography as decoration; use it to encode hierarchy.

## 4.4 Spacing

Adopt a strict rhythm:
- 4px micro;
- 6–8px related items;
- 10–12px pane inset;
- 14–16px section separation;
- 20px+ only for major semantic separation.

No arbitrary large vertical gaps.

At 320px, every 8–12px of vertical space must justify itself.

---

# 5. Navigation

## Wide 560+

Reference: Untitled UI + Linear.

Target:
- 120–140px rail;
- section labels quiet;
- inactive nav rows transparent;
- active nav row gets one precise indicator:
  - thin accent rail OR
  - restrained selected tint OR
  - subtle glyph/text tint;
- do not stack multiple selection effects unless necessary;
- counts right-aligned and muted;
- Library entries below as compact list rows.

Potential question to surface:
**text-only navigation vs neutral 14–16px line icons + text.**
If icons cannot be implemented consistently without low-quality assets, prefer text-only.

## Narrow 320

Navigation becomes a compact mode strip:
- 30–34px high;
- no large pill fills;
- inactive modes quiet;
- active mode indicated by thin underline / small selected tint;
- no tooltip repeating the mode label.

At 240px:
- shortened labels are acceptable only if unambiguous;
- one view at a time.

---

# 6. Rules screen — redesign target

This is the focus of this pass.

## 6.1 Narrow 320 default state

The screen should be approximately:

Header
- SchemaForge
- Greenhouse Contract
- #PlantPot · Part · Selection
- tiny Draft/Saved state

Mode strip
- Rules / Audit / Repairs / Library

Work area
- Rules title + compact action(s)
- Contract settings row
- Attributes header + count + compact add action
- Attribute rows
- Children header + count + compact add action
- Child rows

Footer/command bar
- quiet project/version metadata if needed;
- secondary Audit;
- primary Save only when appropriate.

The page should read first as a **list/inspector**, not a form.

## 6.2 Contract settings

Replace the current floating text block with a compact, deliberate row.

Example information hierarchy:
- primary: Contract settings
- secondary: #PlantPot · Part · tags configured
- optional trailing disclosure indicator

It should look clickable without looking like a button.

## 6.3 Attribute rows

Target row height: ~44–52px depending on metadata.

Each row:
- primary line = attribute name;
- secondary = type + required/optional + useful constraint summary;
- optional tiny trailing state/glyph if meaningful;
- selected row = subtle treatment;
- no unnecessary outer border on every unselected row.

Example:

Cost
number · required · min 0

Enabled
boolean · required

GrowthRate
number · required · 0–5

Use separators or spacing to make the collection scannable.

Do not show raw implementation detail if it does not help selection.

## 6.4 Add Attribute

The large full-width Add Attribute button should disappear.

Preferred options:
A. small + / Add action aligned to the ATTRIBUTES header;
B. final compact ghost row: + Add attribute.

Recommendation: **A on 320+**, because it removes a whole button block and feels more like Figma/Raycast.

If Codex believes B is materially better after rendering, surface the decision.

Same rule for Children.

## 6.5 Rule detail/editor

At narrow widths:
- selecting a rule should enter a dedicated inspector state rather than expanding a giant form into the list;
- clear Back action;
- selected rule identity pinned near top;
- grouped sections:
  1. Type & requirement
  2. Constraints
  3. Default / repair semantics
  4. Designer note
  5. destructive remove action separated at bottom.

At 560+:
- center list + right inspector remains;
- inspector should feel like Figma's properties panel:
  - compact groups;
  - aligned labels/values;
  - related inputs in rows;
  - advanced constraints visually quieter;
  - no old full-width vertical form copied verbatim.

## 6.6 Inputs

Inputs should not dominate the UI.

Rules:
- control height ~30–32px;
- labels close to controls;
- related numeric min/max fields side-by-side;
- boolean toggles/checkbox rows compact;
- dropdowns read like fields, not CTA buttons;
- errors appear next to the offending input;
- disabled states lower contrast without becoming unreadable.

---

# 7. Audit screen — preserve architecture, refine the same visual language

Do not rebuild Audit from scratch.

Keep:
- findings collection;
- selected inspector;
- Expected / Actual;
- Suggested repair;
- stable command bar;
- explicit Preview.

Refine:
- rows should use the same list rhythm as Rules;
- filters should feel like compact toolbar controls;
- selected finding treatment should match selected rule treatment;
- Expected / Actual should be a strong comparison without looking like two big cards;
- Suggested Repair can remain the strongest contained block because it is semantically valuable;
- Select in Studio remains secondary;
- no object ViewportFrame by default.

---

# 8. Footer / command bar

Reference: Raycast / Linear style restraint.

Target:
- stable 52–60px region;
- subtle top separator;
- secondary actions quiet;
- metadata extremely quiet;
- one visually dominant primary action when available.

Rules:
- no two equally loud large buttons;
- no giant outlined secondary button if plain/ghost treatment is sufficient;
- project/version text must never compete with actions;
- disabled primary should still look intentional.

Potential design decision:
ghost button vs text action for the secondary command.
Surface it if visual comparison is ambiguous.

---

# 9. Hover, focus, tooltips

Binding Forge Studio rule:

Hover:
- subtle surface change;
- subtle border change;
- no movement;
- no glow;
- no duplicated text.

Focus:
- precise accent border/ring;
- clear keyboard focus;
- must not look like selection if they represent different states.

Tooltip:
only when information is genuinely hidden:
- truncated full path/value;
- icon-only action;
- keyboard shortcut;
- unfamiliar technical symbol.

No tooltip for already-visible:
- tab names;
- button labels;
- rule names;
- finding names;
- field labels;
- section labels.

---

# 10. Motion

Do not add gratuitous animation.

If any transition is added:
- <= ~120–160ms;
- opacity/small state interpolation only;
- must not delay work;
- must be easy to remove;
- no bouncing/sliding panels.

Static precision is more important than animation.

---

# 11. Icons

Icons are optional, not mandatory.

If used:
- neutral line style;
- visually consistent stroke/size;
- 14–16px;
- familiar semantics only;
- do not use emoji;
- do not create a mixed library of unrelated symbols.

If a proper icon system cannot be implemented cleanly in Roblox Studio, use typography
and spacing instead. Bad icons are worse than no icons.

---

# 12. Wide 560 target silhouette

At ~560px:
- compact header;
- narrow rail;
- center list;
- right inspector;
- thin pane separators;
- stable footer.

The layout should look coherent even if all labels are blurred:
you should still visually perceive:
**navigation -> collection -> inspector -> command**.

Do not make each pane look like a standalone floating card.

Use the reference proportions as a guide, not an absolute:
- rail ~120–140;
- collection ~180–210;
- inspector receives remaining width.

---

# 13. Narrow 320 target silhouette

At 320px:
- compact header;
- compact top modes;
- ONE main work surface;
- no side rail;
- list OR detail, not both squeezed;
- stable command bar;
- no large decorative containers.

The current giant white rounded card should not survive unchanged.

---

# 14. Explicit premium rejection checklist

The pass is NOT done if any of these remain visually dominant:

- full-width Add Attribute / Add Child style buttons;
- big rounded cards around ordinary lists;
- equal visual weight for every button;
- huge blank gaps between rule rows;
- strong borders around every surface;
- accent filling large areas;
- large version/status metadata;
- generic stacked form in the inspector;
- visible labels reappearing as hover tooltips;
- wide layout that merely stretches the narrow layout;
- narrow layout that simply hides columns without rethinking hierarchy.

---

# 15. Design-question protocol during implementation

Before starting code:
1. inspect current 320 screenshot;
2. inspect all references above;
3. write down every high-impact visual assumption;
4. surface the first batch of useful implicit questions to the user/assistant.

During implementation:
- do not ask for approval of pixels;
- DO ask when two reasonable patterns materially change the shared Forge language;
- recommend a default;
- continue on reversible details while waiting if possible.

After the first real render:
- compare, then surface any second-order questions that only became obvious visually;
- examples: row density, tint intensity, footer emphasis, whether section actions are too hidden.

Before declaring done:
- ask one final question only if there is still a genuine unresolved aesthetic tradeoff.

---

# 16. Time allocation — do not burn this pass on QA

The user explicitly does **not** want another large test campaign during this visual iteration.

For this pass:
- do not rerun the full 53/41 suite repeatedly;
- do not spend time producing the full 240/320/400/560 × Light/Dark matrix;
- do not attempt publication;
- do not touch Engine/Schema/Store.

During iteration, only require:
- compile/build sanity;
- one real 320 render;
- one real 560 render if accessible;
- enough interaction smoke-checking to ensure the UI is not obviously broken.

After the user visually accepts the design, a single final regression can be run once.

Visual iteration comes first now.

---

# 17. Reuse for the other Forge products

Do not create a generic shared UI framework in this pass.

However, implement local SchemaForge primitives cleanly enough that we can later
extract the proven visual language.

At the end, create/update a short local pattern inventory containing:
- color tokens;
- typography roles;
- spacing;
- surfaces;
- nav row;
- list row;
- selected state;
- compact section header + action;
- inspector section;
- primary/secondary command;
- tooltip policy;
- narrow/wide breakpoint behavior.

Mark each pattern as:
- REUSABLE FORGE;
- SCHEMAFORGE-SPECIFIC.

This will accelerate PresetForge, CurveForge, AccessForge and JointForge without
forcing them into the same information architecture.

---

# 18. End state

The successful result should make a person think:

> "This looks like a real professional desktop developer tool."

not:

> "This is a very clean Roblox plugin."

The strongest evidence is the real UI itself.

Do not self-certify "premium". Show the real render and let the user/assistant
accept or request one more visual adjustment.
