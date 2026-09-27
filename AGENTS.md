# Instructions pour les agents

- Lire uniquement les fichiers pertinents pour la tâche. Ne pas parcourir tout le dépôt sans nécessité.
- Privilégier la simplicité, la robustesse et la vitesse de mise en vente.
- En Luau/Roblox, séparer le client du serveur et valider les données côté serveur.
- Ne jamais ajouter de secrets, de code obfusqué ou de dépendances douteuses.
- Chaque produit doit être simple à installer, documenté et testable.
- Ne pas construire de framework générique avant qu'un produit réel ne l'exige.
- Réutiliser `shared/` uniquement lorsqu'au moins deux produits ont réellement besoin du même composant.

## Forge product factory

When the user asks to **create a product from A to Z**, **create the next Forge product**, **publish a product**, or **promote/announce it**, treat `docs/forge-product-factory.md` as the default operating procedure.

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
- `docs/v2/forge-v2-roadmap.md`
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

The future high-polish Forge Studio UI work is documented in `docs/forge-studio-ui/`.

**Do not implement that visual refactor until the functional V2 programme is complete for all five products and the user explicitly opens the UI programme.**

While any product still has unfinished functional V2 work:
- the Forge Studio UI folder is research/design reference only;
- do not modify product View/UI code merely to match the future art direction;
- do not introduce a shared Forge UI framework;
- do not delay a functional V2 release for the later visual refactor.

When the user explicitly starts the later UI programme, the agent MUST use:
- `docs/forge-studio-ui/VISUAL_DIRECTION.md`
- `docs/forge-studio-ui/SHARED_SYSTEM.md`
- `docs/forge-studio-ui/PRODUCT_AUDITS.md`
- `docs/forge-studio-ui/PRODUCT_STRUCTURES.md`
- `docs/forge-studio-ui/QUALITY_GATES.md`
- `docs/forge-studio-ui/WORK_ORDER_TEMPLATE.md`
- `docs/forge-studio-ui/forge-ui-spec.json`

A future Forge Studio UI task is **not complete** until its applicable quality gates are recorded PASS on the exact final artifact. "Looks cleaner", successful compilation, or functional reachability alone is insufficient. Real native screenshots at the required widths/themes and the product's functional regression gate are required.
