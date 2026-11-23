# Étapes 4 et 5, ANIMATEUR (DEC-048, DEC-049) : les 5 kits, la cape VIP, les rendus des offres

Tout ce qui suit a été vérifié en rendu Blender, en planche et en test headless. **Rien n'a été vu dans Studio** : c'est François qui joue. C'est un brouillon jusqu'à son avis (DEC-046).

## Étape 4

| Demande | Livré | Où |
|---|---|---|
| Les 5 kits refaits | Gardes, pas de garde, légers, lourds, balayages, saltos aériens de Neji, Gaara, Kakashi, Itachi et Minato ; la lame de Kakashi. 58 clips écrits, chacun meilleur que l'ancien. | `tools/blender/e4_strikes.py`, `e4_build.py` ; `AuthoredJutsu15..19` |
| Parcours du promeneur | `Parkour.WallRun`, `Parkour.Ledge`, `Parkour.LedgeUp` | `AuthoredJutsu14` |
| Transformation de Kakashi | Deux propositions au DEV ; recommandée : **RAIKIRI: TRACKED** (les chiens marquent, le Chidori suit la marque) | `SINCE_LAST_CLAUDE`, INBOX-ANIM-ETAPE5 |
| Export de la tour | `tower_house` dans `HubMeshData*` et `KonohaModelRef` | `konoha_models.py` |

Notes `clip_grades`, moyenne par kit avant → après : Neji 8,2 → 8,5 ; Gaara 6,7 → 8,0 ; Kakashi 6,9 → 8,6 ; Itachi 6,6 → 8,0 ; Minato 6,2 → 8,5.

## Étape 5

- **Cape VIP** (`CapeVIP`) : longue cape blanche, ourlet doré posé sur le tissu, col et fermoir dorés. Donnée avec le pass VIP (serveur : le DEV), jamais vendue.
- **THUNDER HALO et SHADOW VEIL** : 6 000 Ryō, plus de Robux.
- **Rendus des offres** : `assets/renders/offers/`, 95 PNG 512 × 512 à fond transparent (un par look vendu ou donné : 14 sets, hauts, bas, bras, pieds, 18 coupes, bandeaux, masques, capes, dos, 6 armes, 6 auras), plus `SetBundle8.png` pour le lot des 8 tenues. Planche : `offres_planche.jpg`. Outils : `tools/blender/offer_renders.py`, `offer_bundle.py`.
- **Revue de face et de dos** : `revue_face_dos_1..3.jpg` (90 looks portés sur l'avatar, la face à gauche, le dos à droite ; les armes sont sur la planche des offres). Ce que j'y vois :
  - aucun look ne passe à travers le corps, aucune pièce ne flotte ;
  - la cape VIP avait son ourlet décollé, posé au sol : corrigé, l'ourlet suit le tissu ;
  - sur les capes et les pans (capes, manteaux, jupes de robe), la doublure perçait le tissu dans les plis en petits carrés : elle est maintenant deux fois plus loin du tissu (`flap`, 0,07), plus de carrés ;
  - les bandeaux de couleur (noir, rouge) n'avaient pas de rendu : ils prennent le modèle du bandeau classique.
- **Émotes dans la rue** (contrôle headless) : aucune émote ne déplace la racine, donc rien ne glisse sur place ; les boucles se ferment (audit) ; MEDITATE et PUSH-UPS descendent la racine de 1,7 pour poser le corps au sol. À confirmer en jeu.

## Limites

- Les auras sont des particules en jeu ; sur les rendus, ce sont des formes fixes qui les évoquent (pétales, fumée, éclairs...).
- Les couleurs de chakra (`CatalogStyle`) teintent les effets, pas l'avatar : elles ne sont pas sur les planches.
- La gourde laquée n'a pas de rendu : son modèle vit dans `look_gaara.py`, hors du catalogue des armes.
- Les clips de parcours ne se jouent pas sur l'avatar Roblox du promeneur sans Animation publiées (étape LIVE).
