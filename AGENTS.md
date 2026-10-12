# Instructions pour les agents

- Lire uniquement les fichiers pertinents pour la tâche. Ne pas parcourir tout le dépôt sans nécessité.
- Privilégier la simplicité, la robustesse et la vitesse de mise en vente.
- En Luau/Roblox, séparer le client du serveur et valider les données côté serveur.
- Ne jamais ajouter de secrets, de code obfusqué ou de dépendances douteuses.
- Chaque produit doit être simple à installer, documenté et testable.
- Ne pas construire de framework générique avant qu'un produit réel ne l'exige.
- Réutiliser `shared` uniquement lorsqu'au moins deux produits ont réellement besoin du même composant.

## Forge product factory

When the user asks to **create a product from A to Z**, **create the next Forge product**, **publish a product**, or **promote/announce it**, treat `docs/forge/forge-product-factory.md` as the default operating procedure.

The intended end state is that Codex handles:
- demand mining and competitor validation;
- product selection;
- implementation;
- native Roblox Studio QA;
- real-project commercial media preparation;
- listing title/description;
- Studio-side plugin publication/update;
- outreach research and tailored DevForum launch/reply copy;
- DevForum posting when explicitly requested and the authenticated account has permission.

The user should normally only need to handle Creator Hub website price/media/distribution configuration and true account/authentication/permission blockers.

Do not continue a weak product merely because an issue exists. If the competitive gate fails, record the evidence, choose another candidate and continue the factory workflow.

## Current catalogue phase: Forge V2

The V1 catalogue is complete at five canonical products: PresetForge, JointForge, CurveForge, AccessForge and SchemaForge.

Unless the user explicitly asks to reopen catalogue expansion, **do not create Product 6**.

For current improvement work, follow:
- `docs/forge/v2/forge-v2-roadmap.md`
- GitHub issue #15: Forge V2 — catalogue audit, design system & relaunch

V2 priorities:
- preserve canonical asset IDs;
- improve real-project UX before adding features;
- build one coherent Forge design system without making five visual clones;
- use current DevForum/Creator Store evidence to justify product-specific V2 features;
- strengthen media/listing/outreach;
- track before/after commercial signals;
- prefer improving and marketing the existing catalogue over producing more products.

## Hard gate: Forge Studio visual UI programme

The future high-polish Forge Studio UI work is documented in `docs/forge/forge-studio-ui`.

**Do not implement that visual refactor until the functional V2 programme is complete for all five products and the user explicitly opens the UI programme.**

While any product still has unfinished functional V2 work:
- the Forge Studio UI folder is research/design reference only;
- do not modify product View/UI code merely to match the future art direction;
- do not introduce a shared Forge UI framework;
- do not delay a functional V2 release for the later visual refactor.

When the user explicitly starts the later UI programme, the agent MUST use:
- `docs/forge/forge-studio-ui/VISUAL_DIRECTION.md`
- `docs/forge/forge-studio-ui/SHARED_SYSTEM.md`
- `docs/forge/forge-studio-ui/PRODUCT_AUDITS.md`
- `docs/forge/forge-studio-ui/PRODUCT_STRUCTURES.md`
- `docs/forge/forge-studio-ui/QUALITY_GATES.md`
- `docs/forge/forge-studio-ui/WORK_ORDER_TEMPLATE.md`
- `docs/forge/forge-studio-ui/forge-ui-spec.json`

A future Forge Studio UI task is **not complete** until its applicable quality gates are recorded PASS on the exact final artifact. "Looks cleaner", successful compilation, or functional reachability alone is insufficient. Real native screenshots at the required widths/themes and the product's functional regression gate are required.\n\nFor implementation interpretation, `docs/forge/forge-studio-ui/CODEX_EXECUTION_RULES.md` is mandatory. It explicitly forbids cosmetic-only reskins, requires approved mockup-to-real-function mapping, before/after screenshot comparison, structural recomposition where documented, and continued iteration if the result still reads as an internal developer utility.


## Current phase — Forge Studio UI programme ACTIVE

All five functional/technical V2 candidates are complete and the user explicitly opened the Forge Studio UI programme on 2026-09-28.

Current sequencing:
1. SchemaForge reference implementation;
2. PresetForge to prove genuinely reusable visual primitives;
3. CurveForge;
4. AccessForge;
5. JointForge.

During this phase:
- preserve the finished technical engines and safety semantics;
- recompose product Views around the documented real workflows;
- use `docs/forge/forge-studio-ui` as the mandatory implementation contract;
- capture baseline and final **internal QA** screenshots required by the quality gates;
- do not treat a recolor/card/radius pass as completion;
- do not introduce a generic Forge workflow framework;
- do not add new engine features silently during UI work;
- do not publish/overwrite Creator Store assets yet;
- do not do commercial media, listing rewrite or outreach yet.

Internal QA screenshots are allowed and required for the UI quality gate. Commercial screenshots, listing work, publication and promotion are a later handoff after the five UI passes are complete.

A product UI pass closes only when the applicable `QUALITY_GATES.md` checks and its full technical/native regression gate pass on the exact final artifact.


## Frontières d’architecture

- `games/ninja-duel` contient uniquement Ninja Duel et son laboratoire.
- Ninja Duel ne doit importer ni embarquer de code de `plugins`, directement ou via `shared`.
- `plugins/*` (y compris Forge Playground) ne doit importer ni embarquer de code de Ninja Duel ou Motion Lab.
- Motion Lab reste exclusivement sous `games/ninja-duel/motion-lab`. Son adapter peut dépendre de Ninja Duel ; le runtime Ninja Duel ne dépend jamais de Motion Lab.
- `shared` reste réservé aux composants dont l’usage transversal est démontré. Ne pas déplacer un composant sur la seule base de son âge.
- Les documents Forge sont sous `docs/forge`. Missions, rapports, briefs archivés et suivi courant Ninja Duel sont sous `games/ninja-duel/docs/{active,combat,movement,characters,systems,research,tools,reports,archive,current}/`.
- Avant tout déplacement/suppression, rechercher les références et identifier tous les consommateurs. Conserver et signaler les usages ambigus. Aucune suppression sans preuve.
- Vérifier les frontières avec `python3 tools/check_architecture.py`, puis les builds/tests des consommateurs concernés. Les imports calculés nécessitent une revue humaine.

## Reprise persistante Ninja Duel

Pour Ninja Duel, commencer par `games/ninja-duel/CLAUDE_START_HERE.md`, puis suivre la lecture et les règles de `docs/active/EXECUTION_RULES.md`. Le backlog est cumulatif ; conserver les détails archivés et leurs liens vers les IDs. La dernière mission historique n’est pas un ordre autonome. Toute session actualise état, preuves et journal ; distinguer tests techniques et acceptation Studio/humaine. Cette règle ne modifie pas les programmes Forge.
