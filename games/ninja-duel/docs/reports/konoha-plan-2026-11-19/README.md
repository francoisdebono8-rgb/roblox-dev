# Konoha refait : le plan à valider (19/11)

Demande : plan-vrai-jeu § 3 et § 4 ANIMATEUR, tâche 1. Ce dossier contient le plan seulement, rien n'est construit dans Studio.

- `plan_a_valider.png` : la minicarte, les cases nues en rouge et les chiffres du prouveur.
- `minimap.png` : ce que dessine `Shared/KonohaLayout.luau` (points d'intérêt, quartiers, rues).
- `prouveur.txt` : `tools/syphodev/konoha_prove.py` passé sans modification sur la spec greybox, à la résolution 4 puis 2.5 : **PASS**.
  - P11 (vide) : 18 % des cases sont nues, contre 64 % aujourd'hui (objectif < 30 %, budget de la skill 22 %).
  - P3 (accès) : chaque surface est atteignable comme déclaré.
  - P6 (chevauchements) et P21 (budget) : PASS.

## Pour refaire

    python3 tools/blender/konoha_layout.py OUT   # écrit src/Shared/KonohaLayout.luau, OUT/konoha_plan_spec.json, OUT/minimap.png
    python3 tools/syphodev/konoha_prove.py OUT/konoha_plan_spec.json OUT/report.json
    python3 tools/blender/konoha_layout.py OUT   # une seconde fois : écrit OUT/plan_a_valider.png à partir du rapport

## Ce que le plan garde

Tout ce que HubMap utilise déjà reste à sa place : les spawns, les 8 maîtres, l'examinateur, les duels de rue et le trio d'accueil. Le test `tests/KonohaLayout.spec.luau` vérifie qu'aucun bâtiment ne les couvre.

## Ce qu'il ajoute

Les repères de Naruto, première partie :
- la résidence ronde du Hokage, l'hôpital et les archives au pied du rocher ;
- la terrasse des visages, avec deux escaliers ;
- la rue du thé ;
- le domaine Hyūga, muré, avec sa porte et ses halls ;
- la rivière Naka, le sanctuaire et son pont dans le quartier Uchiha muré ;
- le château d'eau du marché ;
- le stade et la Forêt de la mort, en décor hors du mur.

Six maisons réutilisées remplissent les îlots (154 au total), entre 800 et 2 000 triangles chacune. Le mur du village fait 42 de haut : on ne peut pas en sortir depuis un toit.

## Ce qu'on ne sait pas encore

Le plan est prouvé (catégorie TECHNICAL). Rien n'est encore construit ni regardé dans Studio. Ces étapes viennent après la validation :
1. les six maisons modélisées (budgets ci-dessus, mesurés à l'export) ;
2. le DEV fait construire `Server/Hub` à partir de `KonohaLayout` ;
3. le DESIGN dessine la minicarte à partir de `KonohaLayout.Pois`.
