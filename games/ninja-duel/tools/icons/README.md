# Icônes des objets (OUTILLEUR, 19/11)

Ce dossier rend une icône par objet du catalogue (`Shared/Shop`), à partir des modèles Blender de l'ANIMATEUR. Toutes les icônes ont le même angle (trois quarts face) et la même lumière. Ce sont des PNG transparents de 512 px, destinés à la DESIGN, qui les place dans ses écrans (`assets/ui`). La demande vient de `claude/plan-vrai-jeu-taches-2026-11-19`, § 4 OUTILLEUR 2.

- `renders/` : les 33 icônes du 19/11.
- `renders/_planche.png` : la planche pour les voir d'un coup.
- `renders/icons.json` : pour chaque objet, son emplacement, son nom, son comptoir (gratuit, marché en Ryō, SHOP en Robux), son prix en Ryō et le modèle qui a fait l'icône.

## D'où vient chaque icône

| Emplacement | Modèle | Cadrage |
|---|---|---|
| haut, bas, bras, pieds, tenue d'inspiration | `tools/blender/outfit_models.py` : les pièces que le jeu soude sur l'avatar | Mannequin R15 recadré sur l'emplacement : le buste et les bras pour un haut, les jambes pour un bas, le bras droit pour les bras, le bas des tibias et les pieds pour les sandales. Le corps entier pour une tenue |
| kunai, shuriken, tanto | `tools/blender/fx_models.py` : les objets que le jeu construit | Pointe vers le haut, inclinée. Le shuriken est de face |
| gourde | `tools/blender/look_gaara.py` (la gourde du look de Gaara) | Lancé **sans** son export ni son aperçu : rien n'est écrit dans les dossiers de l'ANIMATEUR |
| bandeau | Pas de modèle Blender : la géométrie du jeu (`Server/Headband`) | Sur la tête du mannequin |

Les couleurs de l'objet (`colors` dans `Shared/Shop`) multiplient celles du modèle, comme quand le jeu peint ses pièces (`Client/Effects.paint`, `Server/Outfit`).

Un objet « aucun » n'a pas d'icône : l'écran dessine une case vide. C'est le cas de `HeadbandNone`, `ArmsNone`, `FeetNone` et `SetNone`.

Les scripts de `tools/blender` sont seulement lus ici, jamais modifiés.

## Refaire les icônes

Quand l'ANIMATEUR ajoute ou change des modèles, ou quand le catalogue change :

```sh
# sur le Mac (Blender 5.2), depuis une copie du dépôt
blender --background --python games/ninja-duel/tools/icons/render_icons.py -- <dossier de sortie> [ids...]
```

Le rendu prend une dizaine de secondes pour tout le catalogue sur le MacBook Air. Le 19/11, il a été lancé par le MCP Blender, avec une sortie dans `~/Documents/NinjaDuel/MEDIA/ICONES/2026-11-19/`.

Pour ne rendre que les objets qui n'ont pas encore d'icône dans le dossier de sortie :

```sh
blender --background --python games/ninja-duel/tools/icons/render_icons.py -- <dossier de sortie> --manquantes
```

`icons.json` reste complet : les objets qui ne sont pas rendus cette fois gardent leur ligne.

## Ce qui manque

```sh
python3 tools/icons/catalogue.py               # chaque objet : son icône, son modèle dans le jeu, le modèle de son icône
python3 tools/icons/catalogue.py --gate        # sort en erreur si un objet n'a pas son icône ou son modèle
python3 tools/icons/catalogue.py --manquantes  # la liste des objets sans icône
```

Il lit le catalogue sans Blender : `Shop.Items` et, dès que le DEV l'ajoute, `Shared/Catalog.luau` (vague 2, DEV 2). Le robot de la boucle fait le même contrôle dans `tests/Loop.spec.luau`.

## Les nouveaux emplacements (vague 2)

| Emplacement | Cadrage | Vue |
|---|---|---|
| masque | la tête du mannequin | trois quarts face |
| cape | le buste, les bras et le haut des jambes | trois quarts **dos** |
| dos | le buste | trois quarts **dos** |

Il suffit que l'ANIMATEUR mette ces objets dans `outfit_models.ITEMS`, comme les autres pièces de tenue. Un emplacement que `render_icons.py` ne connaît pas encore est rendu comme une pièce de tenue si l'objet est dans `outfit_models.ITEMS`. Sinon, il est listé « sans icône », avec la raison.

L'arme du ninja et la pose de victoire sont réservées. Elles demanderont leur propre ligne dans `BUILD` quand leurs modèles existeront (vague 2, DEV 3 et ANIMATEUR 3).

## Limites

- Le mannequin est fait de blocs (le corps R15 standard). Il dit à quoi sert la pièce, il ne montre pas un avatar habillé.
- Les bandeaux sont rendus avec la géométrie du jeu, faute de modèle Blender.
- Aucun kanji, aucun texte : les noms viennent de l'écran.
