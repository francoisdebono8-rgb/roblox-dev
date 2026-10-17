# Audit roster V1 — 17 octobre 2026

Rapport historique Codex. État actif : [CURRENT_STATE](../../../active/CURRENT_STATE.md), priorités : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md), diagnostic vivant : [ENGINEERING_REVIEW](../../../active/ENGINEERING_REVIEW.md). Ce rapport ne crée aucune mission parallèle et ne rouvre aucun autre système.

## Verdict

**Oui pour commencer la convergence combat/feel/identité de DEC-021 ; non pour déclarer vingt Tier A entièrement validés.** Les vingt entrées sont réellement câblées, jouables au plancher technique et assez structurées pour arrêter le breadth pass. Aucun P0 confirmé. Trois défauts transversaux P1 doivent ouvrir le prochain bloc ; plusieurs identités restent des prototypes et quatre éveils ne changent que des nombres. Pas besoin de reconstruire vingt kits ni d'ajouter des personnages.

PASS = fondation V1 fonctionnelle et boucle distincte suffisante pour la convergence, pas qualité finale ni certification de l'artefact final en Studio. WEAK = fondation jouable mais trou important d'identité/contrat ou défaut local. BROKEN = kit principal inexploitable/crash/boutons sans implémentation : aucun confirmé. **2 PASS, 8 WEAK, 0 BROKEN** ; l'âge exact et les capacités de jeunesse restent à sourcer pour chaque fighter.

## Provenance et méthode

- Hashes recalculés et manifests conservés : [artefacts](artifacts.json).
- HEAD source audité : `de33f3d56c179d24c36435c20f50bedd38ee6b58`, branche réelle `claude/ninja-duel-2026-10-14`, après les trois lots `5a9c1d3`, `92137c2`, `067b732`. Travail documentaire isolé du main local ancien et sale.
- Lecture ciblée des vingt définitions, intégration Fighters/Attacks/MoveGraphs/Motion, familles, outils, éveils, clients FX/costumes, IA, sélection et reset. Diff des trois lots pour attribuer les risques.
- HEAD exact : **27 suites / 489 cas PASS**, Lune **0.10.5**, Luau **0.743**, [journal](headless.log). Un premier essai Lune 0.11 échouait sur la réflexion `Enum.KeyCode.Unknown` ; les 26 autres suites passaient. Le résultat retenu utilise la version compatible du projet, sans modifier les tests.
- **180 cas additionnels PASS** : vingt fighters × trois directions × neutral / premier coup whiff / premier coup bloqué avec buffer anticipé. Aucun événement Route avant hit confirmé ; en neutral l'ouverture reste Light1. [Protocole](invariant-and-state-source.txt), [résultats](invariant-and-state.log).
- Sondes ciblées : vrai `Matches.resetRound`, buff + éveil, portée des téléports et contre-poison Sasori : [source](round-and-range-source.txt), [résultats](round-and-range.log). Sondes temporaires retirées des tests après exécution ; aucune correction runtime.
- **MCP officiel Studio actif et connecté avant l'essai natif**, instance `7fde5ca2-dade-4333-ae35-f96dba349abe`, `ND-Debug-b3.rbxlx`, Play Client/Server, rosterCount=20. Le pont Mac est temporaire et hors repo.
- L'instance native correspond au Debug de **`067b732`**, empreinte `8104e6345196c85e2d4d4d9daab6aa1e9954bf42cab93d8d952e843a72429f17`, SHA256 `523e2bb3dc124cf4055ed776e16e7092a94b0872258c7b8f375eacb633035306`. Le seul changement runtime jusqu'à de33f3d est la couleur de Shisui. Les résultats fonctionnels sont pertinents ; **ils ne deviennent pas un PASS natif du fichier final**.
- Claude avait déclaré menu à vingt, sélection souris Haku/Shisui/Deidara et `DevRosterCheck` sur les dix. Codex distingue cette provenance de ses propres essais : [journal natif](native.log), [pilote utilisé](native-driver.txt), [captures](screenshots/). Le pilote appelle les vrais inputs, mais lance les duels par Debug quand le menu manque ; ne pas convertir ce fallback en preuve de sélection.

## Résultats natifs Codex et bornes de preuve

Les dix passent Light1→Light2→Light3, route avant confirmée (dont CleaverRise chez Zabuza et PuppetRise chez Sasori), Air1 après saut réel et activation des jutsus/éveils. Les attaques directes et bursts donnent des dégâts ; les projectiles sont souvent seulement « TechniqueResolved ». Le journal des touches R affiche « no new event » : ce compteur n'est pas une preuve de refus, le lancer neutral ne compte pas automatiquement un événement Tool.

[Suivi natif](native-followup.log) : appel serveur Tool accepté, dégâts3 sur cible proche. [Essai souris Haku](native-aim.log) : sélection réelle à la souris puis entrée en duel confirmée par HUD ; outil et WaterNeedles ne touchent pas à10 dans ce setup. La sonde de souris montre un raycast au sol, décalé de l'adversaire malgré la projection utilisée par le pilote. Cela explique pourquoi le pilote ne prouve pas la qualité de visée et interdit de classer les projectiles BROKEN sur ce seul résultat. Faire un protocole de visée stable et adversaire mobile lors de la prochaine gate.

Menu vingt vu par Codex ([capture](screenshots/roster20-menu.jpg)), Haku sélectionné réellement ([HUD en duel](screenshots/haku-real-menu.jpg)). Le texte de menu annonce « Twelve to fourteen years old » alors que Haku/Deidara sont déclarés15 : contradiction de copie P2 à corriger en documentant la période retenue, sans changer silencieusement les âges. Les captures persistantes prouvent dôme Haku, arme Camellia et brume. Le flash/brume de Zabuza est très lumineux sur l'image SilentKilling ; lisibilité en mouvement à revoir, pas mesure de saturation moyenne.

[Console récupérée](studio-console.json) : traces historiques DevRosterCheck de Claude présentes, avec dégâts/réactions détaillés ; aucun crash gameplay nouveau isolé dans la passe Codex. Une stack de profilage MaterialManager/React interne à Studio est présente et n'est pas attribuée au runtime Ninja Duel. Console cumulative, donc ne pas prétendre « zéro erreur Output historique » ni convertir toutes ses lignes en nouvelle exécution Codex. Retour à la sélection après les essais, pas d'autopilot laissé actif.

## Roster et intégration réels

Les vingt IDs de Shared/Roster sont uniques : Flashstep, Mirage, GentleFist, Lion, Sand, Leaf, Legion, Gale, Lavender, Copycat ; Mirror, Mist, Bone, Flicker, Serpent, Medic, Clay, Puppet, Rinnegan, Ink. La liste alimente la sélection et le test de disponibilité Fighters.

Les Wave1/2/3 fusionnent réellement leurs fighters, attacks, graphs et motion borrows dans les modules consommés. `RosterMoves.add` construit les attaques et interdit les noms dupliqués. Les `WaveNKit.install` vides ne sont pas des techniques manquantes : `Families.install` enregistre les handlers selon les données. Brawler appelle strikeHit ; Combat applique Projectile/Contact des outils ; les snapshots alimentent FamilyFX/Looks et les costumes existent.

Chaque nouveau a Light1–3, lourd, launcher, routes directionnelles/air, outil et 3–4 techniques. Une grande part des branches utilise le même graphe et des clips empruntés ; présence de routes ne signifie pas rythme distinct. Les essais natifs des dix et les preuves manquantes sont décrits plus bas.

## Les dix nouveaux

| Personnage / âge déclaré | Verdict | Boucle effectivement câblée | Lacune déterminante / passe à prévoir |
|---|---|---|---|
| Shisui / 13 | WEAK | Téléport latéral + coupe, retrait, feu, seal/slow ; route latérale orbitée ; fenêtres rapides | BodyFlicker ignore la portée déclarée ; éveil exclusivement numérique, distinction hors jutsu encore faible. Aucun Mangekyō importé. |
| Orochimaru / 12 | PASS | Serpents pull + poison, deux entraves/crush, fente venimeuse ; heavy poison ; éveil OnHit poison/BindScale | Vraie boucle harceler → tirer → venin/entrave ; préciser contre-jeu et jeunesse des capacités, valider impact natif des serpents. Aucun transfert de corps/Kusanagi final. |
| Haku / 15 | WEAK | Éventail de senbon ralentissants, dôme de miroirs, téléport/frappe renforcé dans sa zone | Dôme visible en Studio, synergie réelle ; éveil numérique, MirrorStep hors portée ; miroirs encore zone générique plutôt que réseau de déplacement. |
| Kimimaro / 13 | WEAK | Os à distance, Camellia arme/buff, Larch burst + zone d'os, WillowStrike, armor | Arme en main vue ; Camellia masque Heavy/Armor de l'éveil. Clarifier états cumulés et réactions avant polish. |
| Nagato / 12 | WEAK | Repulsion burst, Attraction projectile pull, Absorb drain/steal | Trois opérations réelles mais Absorb est un burst de drain, pas une absorption défensive de projectile ; éveil numérique ; choix tactiques et provenance jeune à préciser. Pas Six Paths/Chibaku. |
| Sasori / 14 | WEAK | PuppetThrust, FatherMother bind/crush, NeedleRain, contre-poison ; éveil poison/entrave | Marionnettes = projectiles ; aucun corps contrôlé/distant persistant. Les coups longs réutilisent Sand : fantasme du marionnettiste très partiel. Le contre-poison fonctionne dans la sonde avec vraie attaque entrante. |
| Deidara / 15 | WEAK | Oiseaux/spiders projectiles, zone clay au sol, Katsu burst | Mine = hazard de ticks, Katsu = explosion locale sans déclencher les objets posés. Pas de boucle poser/piéger/détoner ; éveil numérique. Ne pas ajouter C2/C4/vol adulte pour masquer ce manque. |
| Killer Bee / 14 | PASS | Lariat rapproché/flatten, encre slow, tentacule bind/crush ; cloak Heavy/Armor | Boucle contact/prise/encaissement distincte suffisante V1 ; jeunesse encre/manteau à sourcer, confirmer contre-jeu et impacts natifs. Pas sept sabres ni Gyūki complet. |
| Zabuza / 14 | WEAK | Allonge lente, HiddenMist, SilentKilling renforcé en brume, WaterPrison ; éveil Heavy | Cleaver statique dans le dos et clips Gale empruntés : arme/contact mal incarnés. Brume = zone slow/particules, pas perte de vision/lecture ; téléport hors portée. |
| Kabuto / 13 | WEAK | Scalpel buff OnHit slow/drain, TendonCut, retrait qui soigne, éveil OnHit slow | Boucle médicale viable, mais priorité du buff/éveil non composée : en éveil le OnHit propre de l'éveil supplante le drain du scalpel ; buff peut fuir au round suivant. Vérifier intention au lieu d'empiler des chiffres. |

La jeunesse n'est pas validée par une ligne Age. Les commentaires excluent certaines formes adultes, ce qui est positif, mais aucun registre sourcé par technique n'étaye les âges précis (notamment Nagato/Orochimaru/Kabuto/Bee). Ne pas déclarer une contradiction canonique sans preuve ; annoter version retenue, technique attestée ou liberté de design. L'[article officiel Sasori](https://naruto-official.com/en/news/01_1641) étaye les marionnettes des parents dès son enfance, pas l'ensemble du kit de poison à quatorze ans. CHR-CORE-002 couvre cette vérification sans bloquer une passe de contact.

## P0

**Aucun P0 confirmé** : pas de roster fantôme, kit principal vide, crash de suite ni route avant hit reproduits. Ne pas confondre absence de preuve et validation ; publication/online ne sont pas certifiés par cet audit.

## P1 — défauts reproduits et contrats non tenus

1. **État de buff fuit entre rounds.** Activer Camellia peu avant le KO, appeler le vrai resetRound, passer délai KO + intro : round2, buff encore actif, DamageScale=1.22. Combat.clear vide callbacks/effets mais pas `a.buff`. Le défaut de reset préexistait aux trois lots ; les nouveaux buffs l'exposent. Le counter/slow/poison-visual non nettoyés sont aussi relevés mais leur durée peut expirer pendant l'intro : ne pas prétendre qu'ils causent tous des dégâts au round2. Corriger l'inventaire de cleanup, pas seulement Camellia ; vérifier mort, round, rematch et départ.
2. **Buff temporaire masque l'éveil.** Families.buff rend immédiatement `a.buff.spec` avant Awakening.Buff : Camellia + éveil Kimimaro → Heavy=false, Armor=0 alors que l'éveil promet true/.3. L'arbitrage OnHit est séparé (`awakening → buff → base`) et peut supprimer le drain de Kabuto. Les deux politiques doivent être explicites et testées, sans multiplication non bornée.
3. **Téléports ciblés hors portée.** À distance120, BodyFlicker Range34, MirrorStep Range30, SilentKilling Range32 sont tous acceptés et déplacent près de l'adversaire. Families.Teleport.check vérifie seulement cible vivante ; le champ Range ne borne pas la demande serveur. Vérifier portée et collision/LOS selon intention ; retester bord, mur et annulation sans coût indu. Ce check préexiste au lot : extension de la surface, pas preuve de régression nouvelle des dix anciens.
4. **Quatre éveils exclusivement numériques** (Haku/Shisui/Deidara/Nagato), donc contrat « change une règle » du Tier A non satisfait. Les autres ont OnHit, Heavy/Armor ou interaction d'état réels, sous réserve du conflit ci-dessus. Ne pas faire dix refontes immédiatement : clôturer états/combats d'abord, puis une règle simple par kit au bloc identité.
5. **Signatures trompeuses ou trop abstraites.** Sasori sans corps contrôlé, Deidara sans mine/détonation liée, Zabuza arme portée au dos pendant les frappes, Nagato Absorb sans absorption défensive. Ce sont des écarts d'identité au-delà d'une couleur/VFX. Préserver familles existantes ; intégrer une interaction démontrée par besoin, au bloc identité de DEC-021.
6. **Gate Studio final ouverte.** Les outils/projectiles à vraies touches ont été déclenchés mais plusieurs traces ne prouvent aucun impact ; refaire visée et contact avec cible mobile/garde. Aucun PASS global Tier A natif sur le SHA final, manette physique ni online publié.

## P2 — dette et risques

- Tests roster permissifs : nombre >=8 au lieu de ==20, chaîne « trois » tolérant deux hits, éveil accepté sur n'importe quel bonus numérique ; techniques acceptées sur spawn/état mesurable. Roster20 ne couvre que dix nouveaux et ignore une entrée absente dans certains chemins. Remplacer les faux critères par des assertions sur comportement avant de durcir les badges.
- IA : ring headless de vingt matchups voisins, pas matrice20×20 ni usages des synergies (miroir/brume, mine, buff→éveil, contre). Sasori vs Lee non terminé en90s dans le rapport Claude : signal de létalité/IA, pas crash. Ajouter quelques matchups à risque réciproques et seeds, pas400 duels aveugles obligatoires.
- Les 10 anciens passent leurs suites spécifiques/core et les suites communes ; aucun nouveau défaut ancien reproduit. Pas de rejeu natif exhaustif CORE4/Gaara/Lee/Naruto/Temari/Hinata/Kakashi sur cet artefact : régressions visuelles, substitutions, clones, zones/infusions encore possibles.
- Risque partagé : Brawler strikeHit s'étend aux riders ; Combat change le projectile/contact des outils ; Families ajoute Poison/PullTo/Heal/InZone/Leave/OnHit. Exiger tests des consommateurs anciens, annulation et lifecycle. Infusion remplace Contact normal : politique explicite à vérifier, pas un bug déclaré sans design.
- Combat≈1886 lignes, Brawler≈1209, AI≈643 : ne pas ajouter de cascade par nom. Les nouveaux modules de données limitent correctement la duplication du cœur. Wave1/2/3 et costume helpers dupliquent du plumbing ; extraction locale seulement si un changement commun la justifie. Pas de framework ou réécriture globale.
- Graphes et motions hérités produisent un risque d'homogénéité : comparer anticipation, distance, contact, recovery et choix de routes, pas seulement noms. Réutilisation de famille correcte ≠ identité suffisante.
- Traçabilité : manifests finaux et Studio ouvert diffèrent d'une couleur. Toujours enregistrer fingerprint/SHA/commit, pas le seul titre de fenêtre/version. `DevRosterCheck` journalise beaucoup sans assert de résultat et ne prouve pas contre-jeu humain.

## Mission suivante à Claude — ordre précis, un bloc à la fois

1. **Stabilisation transversale** (QA-004 / ARC-002) : reset exhaustif des états, composition buff/éveil/OnHit, portée des téléports ciblés. Ajouter des régressions qui échouent avant correction et passent après ; aucun retuning arbitraire pour contourner le défaut.
2. **Contrats et grille des vingt** (QA-002 / CHR-EXT-002) : roster exact20 ; toute entrée requise ; Light1–3 réellement confirmés ; lourd/route/air/outils ; chaque technique touche/applique son effet ; éveil changeant une règle distingué des bonus. Conserver test neutral/whiff/block/buffer sur20.
3. **Premier bloc DEC-021, combat et feel** (COM-002/003/005, QA-004) : passe breadth-first sur20, anticipation→contact→réaction→recovery, chaînes, routes seulement après confirmation, launcher/chase/air, knockback, garde/dodge/substitution, dégâts, KO/reset. Comparaison avant/après ; commencer par défauts transversaux puis écarts de familles. Garder la base fonctionnelle de chaque kit.
4. **Revue native de sortie de ce bloc** (QA-001/005, BAL-001/AI-001) : ouvrir l'artefact final exact, sélectionner réellement les20, vraies touches/souris, outil observé en vol et contact, cible mobile/garde, counter provoqué, buff+éveil+KO, duels IA à risque réciproques, manette physique distincte. Rejouer les anciens, notamment clones/vent/infusion et CORE4.
5. **Rapport/synchronisation**, puis seulement le bloc chakra prévu par DEC-021, puis **identité** (SYS-003, CHR-CORE-001/002) : priorités de signatures Sasori/Deidara/Zabuza/Nagato, éveils Haku/Shisui/Deidara/Nagato ; garder les âges/version retenus cohérents. Ne pas transformer cet audit en autorisation de faire tous les gros systèmes ensemble.

## Validation documentaire et limites

Aucune modification gameplay/runtime/test/artefact par Codex. Les fichiers actifs antérieurs et la référence ROSTER_20 avant correction des badges sont conservés dans [before-active](before-active/). Les preuves annexes sont historiques et n'ajoutent pas de source opérationnelle. Tests de frontières : PASS (406 fichiers), isolation9/9 PASS. Contrôle documentaire + sept tests de reprise : PASS (75 IDs) ; diff --check : PASS. Les snapshots déplacés ont leurs liens relatifs recalculés. Pas de certification humaine du feel, pas de session Roblox publiée observée.

## Points de code reproductibles

- [Families.buff](../../../../src/Server/Families.luau) : ligne53, priorité buff temporaire avant éveil ; afterHit vers402 pour la politique OnHit distincte.
- [Combat.clear](../../../../src/Server/Combat.luau) : ligne1864, états famille non effacés ; [Matches.resetRound](../../../../src/Server/Matches.luau), ligne146, réutilise ces acteurs.
- [Families.Teleport](../../../../src/Server/Families.luau) : ligne314, check cible sans Range.
- [Wave1](../../../../src/Shared/Wave1.luau), [Wave2](../../../../src/Shared/Wave2.luau), [Wave3](../../../../src/Shared/Wave3.luau) : données des kits, éveils et signatures. Les lignes indiquent le HEAD audité, pas une promesse de stabilité après correction.
