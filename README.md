# Roblox Dev

Workspace Roblox : Ninja Duel, plugins Forge Studio historiques et Forge Playground.

## Pipeline

Research → Spec → Build → Test → Package → Publish → Measure

## Catalogue V1

- PresetForge : recettes de configuration, asset `73596873703054`.
- JointForge : joints et contraintes, asset `103958912217728`.
- CurveForge : cables et chemins, asset `90642263224333`.
- AccessForge : escaliers et passerelles, asset `127360597946823`.
- [SchemaForge](plugins/schemaforge/README.md) : contrats et audit des objets configures, asset `84085408748744`.

Cinq produits publies cote Studio. Prix, medias et distribution web de SchemaForge restent a configurer par le proprietaire. Voir [le suivi de release](docs/forge/forge-catalog-release-status.md).


## Workspaces

- [Ninja Duel](games/ninja-duel/README.md) : runtime, assets, vendor, build et tests autonomes.
- [Documentation Ninja Duel](games/ninja-duel/docs/README.md) : missions, rapports, archive et suivi courant.
- `games/ninja-duel/motion-lab/` : emplacement réservé à Motion Lab (absent de ce checkout) ; adapter vers Ninja Duel autorisé, dépendance inverse interdite.
- `plugins/*/` : tous les anciens produits Forge/BrickKit, y compris les candidats non publiés.
- [Forge Playground](plugins/forge-playground/README.md) : expérience de démonstration qui réutilise explicitement des moteurs Forge.
- [Documentation Forge](docs/forge/README.md) : catalogue, commercial, branding et programme Studio UI.
- `tools/` : outils de développement/QA ; `shared/` : composants réellement transversaux (actuellement un emplacement vide).

Les règles et commandes de validation sont dans [ARCHITECTURE.md](docs/ARCHITECTURE.md).
