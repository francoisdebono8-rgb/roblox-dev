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
