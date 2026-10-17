# Roster 20 — breadth pass (Tier A → B → C)

Directive : [`docs/missions/ROSTER_20_BREADTH_PASS.md`](../archive/missions/ROSTER_20_BREADTH_PASS.md). Règle Studio : [`docs/missions/STUDIO_VALIDATION_RULE.md`](../archive/missions/STUDIO_VALIDATION_RULE.md). Suite : [`docs/missions/PUBLIC_ALPHA_AFTER_ROSTER_20.md`](../archive/missions/PUBLIC_ALPHA_AFTER_ROSTER_20.md).

## Les vingt

| # | Id (code) | Combattant | Archétype | Famille réutilisée | État |
|---|---|---|---|---|---|
| 1 | `Flashstep` | Minato | mobilité / sceaux | — (CORE4) | jouable |
| 2 | `Mirage` | Itachi | lecture / contre | — (CORE4) | jouable |
| 3 | `GentleFist` | Neji | contrôle du chakra | — (CORE4) | jouable |
| 4 | `Lion` | Sasuke | rushdown / feu-foudre | — (CORE4) | jouable |
| 5 | `Sand` | Gaara | contrôleur défensif | — | jouable |
| 6 | `Leaf` | Rock Lee | taijutsu pur | coups de Sasuke | jouable |
| 7 | `Legion` | Naruto | corps multiples (clones) | Bodies | jouable (Studio à faire) |
| 8 | `Gale` | Temari | zoneuse vent | Zones | jouable (Studio à faire) |
| 9 | `Lavender` | Hinata | Poing souple, défensive | Neji + Families (Buff, Burst) | Tier A, Studio vu |
| 10 | `Copycat` | Kakashi | polyvalent / Sharingan | Families (Strike, Projectile) | Tier A, Studio vu |
| 11 | — | Shisui | Uchiha mobilité / genjutsu | Families + identité Uchiha distincte | à faire |
| 12 | `Serpent` | Orochimaru | serpents, allonge, saisie | Families (Projectile serpent Pull) | à faire |
| 13 | `Mirror` | Haku | projectiles / miroirs | Families (Projectile senbon, Teleport) | à faire |
| 14 | `Bone` | Kimimaro | armes d'os, armure | Families (Projectile bone, Burst, Strike) | à faire |
| 15 | — | Nagato | Rinnegan / contrôle / attraction-répulsion | Families + mécaniques propres | à faire |
| 16 | — | Sasori | marionnettes / corps déporté | Bodies/Families + marionnette dédiée | à faire |
| 17 | — | Deidara | explosifs / zoning / aérien | Families + explosifs dédiés | à faire |
| 18 | — | Killer Bee | multi-sabres / jinchūriki jeune | Families + corps/armes dédiés | à faire |
| 19 | `Mist` | Zabuza | arme lourde + brume | Families (Zone mist, Teleport, Strike) | à faire |
| 20 | — | Kabuto | médical / scalpel chakra / intelligence | Families + mécaniques propres | à faire |

> **Composition verrouillée par DEC-022 (17/10/2026).** Les anciens lots Sakura / Choji / Kiba / Shikamaru / Shino / Kisame sont abandonnés avant code pour ce roster initial. Les noms ci-dessus priment sur les anciennes notes de lots.
>
> **Règle de période :** les vingt peuvent venir de générations différentes, mais chaque personnage est construit dans une version **jeune/prodige**, avec les capacités réellement connues ou raisonnablement établies à ce stade. Ne pas importer son arsenal adulte final par défaut. Les Uchiha et autres familles/clans peuvent partager une base sans partager leur boucle de jeu. Le nombre de jutsus n'est pas standardisé : équilibrer la profondeur et les décisions, pas le nombre de techniques.

## Tier A (plancher, vérifié pour chaque entrée de `Shared/Roster`)

`tests/Roster.spec.luau` échoue tant qu'un combattant listé manque d'une pièce : définition complète, implémentation pour chaque technique, éveil qui change le jeu, famille de mouvement, graphe (routes, réengagement), trois légers qui touchent, lourd, route vers l'avant, frappe aérienne après un saut, outil, chaque technique qui résout et produit un effet mesurable, éveil qui s'ouvre, duel IA jusqu'au KO sans blocage avec usage des techniques, sélection au menu, costume propre (≥ 8 pièces), chaque objet de famille dessiné avec son propre modèle.

Puis en Studio (règle Studio) : `tools/studio/fighter_check.py <Id> [adversaire]` — choix au menu à la souris, chaîne, route, air, outil, chaque technique en visant l'adversaire à la souris, éveil, captures ; et `ai_soak.luau` sans erreur.

## Socle commun (pas de moteur par personnage)

- **`Server/Families.luau`** : familles de techniques pilotées par les données (`Projectile`, `Strike`, `Burst`, `Zone`, `Buff`, `Teleport`, `Counter`) et champs de contact (`Knock`, `Lift`, `React`, `Bind`, `Crush`, `Drain`, `Steal`, `Slow`, `Seal`, `Pull`, `Zone`). Traits lus par le cœur via des crochets : `beforeHit` (posture de contre), `damageScale` (buff, armure `def.Armor`), `withstands` (super-armure `Heavy`), `afterHit` (`def.OnHit` : drain, ralentissement), `zoneTick`, `speedScale`/`regenScale`. Éveil : `Awakening.Buff`, `Awakening.OnHit`, `Awakening.BindScale`.
- **`Shared/Looks.luau`** : l'apparence de chaque genre d'objet (forme, couleurs, lumière, traînée, impact, zone). **`Client/FamilyFX.luau`** construit les modèles (orb, needle, blade, wave, beast, serpent, swarm, shadow, boulder), leurs poses de vol, les impacts, les zones au sol, les auras de buff et de ralentissement.
- **`AI.luau`** : `familyWants` décide d'une technique de famille par sa famille et `spec.AI` (`Min`, `Max`, `Chance`, `Punish`).
- **Poses** : `VelmoraMotionEngine` donne une pose de lancer par famille (signes pendant le canal, puis projection / explosion / zone / buff / garde / arrivée) ; `spec.Pose = {channel=…, release=…}` la remplace ; `Motion.stance` (données) donne une garde propre.
- **Costumes** : `Server/Costumes.luau` (`install(dressers, kit)`), enregistrés par nom ; `World.dress` les appelle.
- **Menu** : `Shared/Roster.luau` est la seule liste ; la sélection affiche une grille de cinq colonnes par moitié.

## Notes de reprise (17/10, relevées par les anciens lots avant code)

Ces constats techniques restent utiles au socle, mais les compositions d'anciens lots qu'ils visaient ne sont plus normatives après DEC-022 :

1. `Roster.spec` refuse qu'une technique de **famille** soit refusée au lancer : une technique conditionnelle s'enregistre dans `WaveNKit.install` **sans** `Family`, avec `Requires="Bound"` ; il faut alors une ligne générique dans `AI.luau` et un cas `Requires=="Bound"` pour l'état « prêt » de la barre (`Matches.luau`).
2. `Effects.luau` enroule du fil d'acier autour de tout corps `Bound` (sauf Gaara) : une entrave de famille doit le désactiver (ex. `family.tie` dans l'instantané) et dessiner son propre lien.
3. `Families.afterHit` sort tôt sans `def.OnHit` : `Awakening.OnHit` doit s'appliquer même sans trait de base.
4. `Pull` est un vol de recul : sans plafond (ex. `PullTo` ≈ 3,5 studs devant lui) une cible proche est projetée derrière lui.
5. Une ombre au sol vole 2,2 studs sous la racine : contre une cible qui bouge, rayon ≈ 1,8 et un champ générique `Steer` (réorientation via `c:redirect`) sont nécessaires.
6. Champs génériques prévus : `Awakening.ZoneScale` (famille Zone), `Heal` optionnel sur Teleport.
7. Un coup `heavy=true` lance le corps et casse l'entrave : dégâts non lourds pendant une entrave.
8. Une frappe nouvelle sans clip prend le Light1 de sa famille de corps : la dessiner dans le FX de vague en attendant un clip.
9. Contraintes des suites : Ids de techniques globaux et uniques ; Speed × SprintScale < 24 (`Lee.spec`) ; JumpScale borné par `Regression.spec` ; toute entrée d'`Attacks` porte side/twist/lean/arm/step (`Animation.spec`).
10. `CostScale` d'éveil rembourse **toutes** les techniques (`Combat:awakenTechnique`) ; `Regen` d'un Buff agit sur le chakra, pas la santé ; un seul buff compte à la fois (`Families.buff`).
11. Une frappe nouvelle d'`Attacks` doit aussi poser `animation/feedback/chain/air/depth/offset` ; un champ `clip` lu par le moteur de mouvement permettrait d'emprunter une animation existante au lieu du Light1.
12. Un outil non kunai/shuriken est lancé comme `shuriken` ; un outil sur mesure (`Techniques.Tools`) perd les annulations de chaîne : garder `Tool="Kunai"` sauf besoin réel. L'IA de famille soignerait à pleine santé : seuil générique `spec.AI.Hurt` à prévoir.
13. La famille Zone vaut `"Fire"` par défaut (`ZoneKind`/`Zone.Kind`) et une zone sans `Kind` d'apparence est dessinée en feu : toute zone non ignée doit nommer `ZoneKind` et un `Kind` de `Looks`.
14. Une téléportation de famille est dessinée par `FX:teleport` (éclair jaune de Minato) : chaque identité doit dessiner la sienne et éteindre l'éclair générique.
15. Champs génériques prévus : `Shroud` sur une zone, `Leave` sur Burst, `Awakening.TeleportCost`.
