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
| 11 | `Blossom` | Sakura | force / soin | Families | à faire (lot 1) |
| 12 | `Boulder` | Choji | cogneur / transformation | Families (Buff Heavy, Strike) | à faire (lot 1) |
| 13 | `Fang` | Kiba | rushdown + compagnon | Families (Strike, Projectile beast) | à faire (lot 1) |
| 14 | `Shadow` | Shikamaru | pièges / entrave | Families (Projectile shadow Bind) | à faire (lot 2) |
| 15 | `Hive` | Shino | insectes, drain, zones | Families (Zone, Projectile swarm) | à faire (lot 2) |
| 16 | `Serpent` | Orochimaru | serpents, allonge, saisie | Families (Projectile serpent Pull) | à faire (lot 2) |
| 17 | `Mirror` | Haku | projectiles / miroirs | Families (Projectile senbon, Teleport) | à faire (lot 3) |
| 18 | `Mist` | Zabuza | arme lourde + brume | Families (Zone mist, Teleport, Strike) | à faire (lot 3) |
| 19 | `Shark` | Kisame | cogneur drain (Samehada) | Families (OnHit Drain, Projectile shark) | à faire (lot 3) |
| 20 | `Bone` | Kimimaro | armes d'os, armure | Families (Projectile bone, Burst, Strike) | à faire (lot 3) |

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
