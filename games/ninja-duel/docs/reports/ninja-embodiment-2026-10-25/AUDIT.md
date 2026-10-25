# Ninja Embodiment — audit de départ (§1)

HEAD audité : `84119ea`, puis `cd92301` (seuls les briefs ont changé entre les deux). Studio ND-Debug, combats libres IA contre IA : chakra plein, jutsus permis, 45 s par paire.

Brief et règle universelle : [mission](../../archive/requests/2026-10-25-ninja-embodiment-game-completion.md), [règle](../../archive/requests/2026-10-25-ninja-embodiment-universal-system-rule.md), [DEC-027](../../active/DECISIONS.md).

## Mesures (Studio, serveur, chaque frame)

Une « décision » est l'entrée dans Startup, TechniqueChannel, Dodging, Guarding, Rush ou Pursuit. Une frappe est dite « universelle » si elle appartient à Light1/2/3, Heavy, Launcher, Air1/2, Slam, DashAttack, AirSpike, AirDrive, Throw ou Grab. « Verrouillé » veut dire en réaction ou étourdi, donc sans contrôle.

| Paire | Décisions / 30 s | Frappes universelles | Temps verrouillé (victime, sur 45 s) | Verrous > 1,2 s | Mur | Chakra modificateur | Chaînes répétées |
|---|---|---|---|---|---|---|---|
| Sasuke – Minato | 20,7 / 46,7 | 93 % / 84 % | **19,6 s** / 5,0 s | 3 (max 2,2 s) / 0 | 0 s | 3 / 1 | Light1>Light2>Launcher ×3, Light2>Launcher>DashAttack ×3 |
| Sasuke – Kimimaro | 29,3 / 26,0 | 70 % / 91 % | 11,1 s / 13,5 s | 3 (max 3,8 s) / 1 | 0 s | 5 / 1 | Air1>Air2>Slam, BoneRise>Air1>Air2 |
| Kimimaro – Haku | 21,3 / 30,7 | 85 % / 84 % | 10,9 s / 9,4 s | 1 / 0 | 0 s | 2 / 3 | Light1>Light2>FrostLift |
| Gaara – Lee | 40,0 / 16,7 | 82 % / 76 % | 1,0 s / **21,9 s** | 0 / 5 (max 3,2 s) | 0 s | 0 / 0 | **SandPillar>Air1>Air2 ×4**, Light1>Light2>Light3 ×3 |
| Zabuza – Itachi | 24,7 / 30,0 | 68 % / 92 % | 10,7 s / 9,5 s | 3 / 2 | 0 s | 1 / 8 | DashAttack>Light2>Light3 ×3 |

Lecture des colonnes :
- **Chakra modificateur** : événements où le chakra change une action (ChakraPlant, ChakraIgnite, ChakraShock, ChakraGust, ChakraClash, MetalCharged, Clash_*). Un simple coût de jutsu n'est pas compté.
- **Mur** : temps passé en mur. Sur les 225 s jouées, il y a eu **un seul wall splat** (Lee) et **zéro** utilisation volontaire d'un mur.

Constats :
- Le victime passe **22 à 49 % du temps verrouillée**, avec des verrous de 2 à 4 s : l'attaquant tient la manette de l'autre.
- **68 à 93 % des frappes** sortent de la grammaire universelle.
- **Gaara boxe en l'air** : SandPillar puis Air1, Air2.
- Boxer Test, à l'écran (caméra de profil) : Sasuke et Minato échangent des coups de poing debout, à 3 studs, sur place. Sans les étincelles, ce sont deux boxeurs. **FAIL.**

## Sources concrètes de la répétition (code)

1. **`Attack` signifie « avancer le compteur »** ([Brawler.request](../../../src/Server/Brawler.luau)).
   - Light1, Light2 puis Light3 selon les coups confirmés ([BanglaCombo](../../../src/Shared/BanglaCombo.luau), compteur à 3).
   - Le contexte ne change l'entrée que dans quelques cas fixes :
     - sprint à plus de 28 studs/s (runStrike) ;
     - arrivée de dash ou de poursuite (DashAttack) ;
     - mur (WallDive) ;
     - air (Air1 et Air2 en alternance) ;
     - riposte.
   - Distance, angle, vitesse réelle, montée/descente, posture adverse, arme ou forme active, monde proche : rien de cela n'intervient.
2. **Les routes n'existent qu'à l'intérieur d'une chaîne confirmée.**
   - Haut, bas ou côté, uniquement à partir de combo ≥ 2 ([MoveGraphs](../../../src/Shared/MoveGraphs.luau)).
   - Même squelette pour les vingt ; seuls les noms de clips changent.
3. **Heavy suit un circuit fixe.**
   - Dans la chaîne à combo ≥ 2 : Launcher. En l'air : Slam.
   - La poursuite (`E`) enchaîne Air1/Air2 puis Slam : une boucle de jongle universelle.
4. **La victime n'a rien à jouer.**
   - Chaque coup confirmé relance HitStun ; Light3 enchaîne sur Knockback, le Launcher sur un jongle.
   - Hors substitution (une charge, du chakra), aucun choix pendant ces séquences : pas de dérive aérienne, pas de tech au sol ni au mur, pas de récupération dirigée.
5. **Le chakra ne sert presque qu'à payer.**
   - Il paie les jutsus, le rush, la poursuite et la substitution.
   - L'infusion d'outils existe ([ChakraCombat](../../../src/Server/ChakraCombat.luau)) mais reste marginale : 0 à 8 événements pour 45 s.
   - Aucun chakra de mouvement, de corps ou d'état soutenu.
6. **Le monde est indifférent.**
   - L'arène est statique : 5 rochers, murs, arbres. Pas de matériaux ni d'intégrité, pas de cassable ni de traces persistantes.
   - Le seul contact avec le monde est le wall splat, plus le mur pour la locomotion.
   - La persistance se limite à quelques objets propres à certains personnages : sceaux de Minato, miroirs, sable.
7. **L'IA joue la grammaire.**
   - Elle ouvre, enchaîne et convertit, ne touche jamais aux murs, et ne pose rien pour plus tard.
   - Même une fois le jeu changé, les combats IA contre IA ne montreront la liberté que si l'IA comprend les nouveaux verbes.

## Points de départ réutilisables

- Le pipeline ChakraCombat « objet + chakra + nature + contexte » est déjà la bonne graine (règles, signaux, conduction, ignition).
- Bodies (clones), Zones, sceaux de Minato, miroirs de Haku, sable de Gaara : ce sont déjà des objets persistants, mais chacun a son propre code.
- Motor et Place1Movement : course, mur, saut, dash, avec un état de vitesse fiable.
- Le snapshot porte déjà les objets du monde vers le client, sous autorité serveur.

## Classement de départ (règle universelle §9)

Tous **MOVESET-BOUND** : leur combat de base est la grammaire universelle. Nuances :

**PARTIAL**
- Minato : réseau de sceaux réel, mais téléport puis frappe garantie.
- Gaara : le sable existe, mais il frappe en l'air comme les autres.
- Haku : miroirs.
- Naruto : clones dans les routes.
- Sasori, Deidara : pose/repousse.

**MOVESET-BOUND**
- Sasuke, Lee, Itachi, Zabuza, Neji, Kakashi, Shisui, Kimimaro (os comme cooldowns), Killer Bee, Nagato, Orochimaru, Madara, Hashirama, Hiruzen.

Pour chacun, les capacités manquantes sont à écrire en Body / Chakra / Movement / Perception / Objects / Environment / Persistence / Defense / Improvisation / Counterplay, au fil des tranches. Suivi dans MASTER_BACKLOG, EMB-001 et suivants.
