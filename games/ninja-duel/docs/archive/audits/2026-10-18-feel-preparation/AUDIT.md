# Préparation Claude — audit incrémental du 18 octobre 2026

Snapshot historique, **pas nouvelle mission autonome**. Travail actif et ordre des petits commits : [MASTER_BACKLOG, QA-004](../../../active/MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). Diagnostic vivant : [ENGINEERING_REVIEW](../../../active/ENGINEERING_REVIEW.md). État : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## Périmètre et delta

Base précédente `abcb535` ; **HEAD courant audité `bc7faa3ad28b3dc5504559a99ded339d967dae0c`**, branche réelle `claude/ninja-duel-2026-10-14`. Seulement cinq commits Claude examinés : `91d14f7` (lifecycle/composition/portées), `c9b5569` (visée/IA/gates/grille), `137cd0a` (identités), `a8824bd` (build), `bc7faa3` (constats Studio). Aucun audit général, aucun gameplay implémenté par Codex.

**28 suites / 500 cas PASS** sur ce HEAD, Lune0.10.5 / Luau0.743 : [journal](headless.log). L'ancien P1 Camellia/round est corrigé, la composition Kimimaro et Kabuto est fusionnée, les téléports refusent une cible déjà hors portée/derrière un mur à la demande ; tests Convergence couvrent ces cas. **Ne pas redonner ces corrections comme si rien n'avait changé.**

Les quatre éveils auparavant numériques ont maintenant des règles : Shisui ChainTeleport, Haku ZoneFree/Ring, Deidara ChainCharges et détonations, Nagato Absorb/ReflectClear. Sasori a un corps persistant, Zabuza une arme en main et un shroud. Les anciens WEAK ne conservent donc pas automatiquement leur ancien diagnostic.

## Studio exact — preuves ciblées, pas audit général

Le18/10, Codex a ouvert le Debug courant dans Roblox Studio. MCP officiel connecté à l'instance `4b8a532b-b221-448e-a070-a8b46d842727`. Empreinte lue dans l'artefact chargé : `fdba31aba1328dc62426f8e4ffd0fadfbb383d593ef68def532d8b7006f09194`, égale au manifeste ; SHA256 du fichier `b3ed842e0d611069fd266e978c9523997d9b4b28ebe312432266985d64712ddc`. [Trois hashes recalculés](artifacts.json), [journal natif](native.log), [console](console.json).

- **Sasori** : invocation avec la vraie touche1, corps visible et jab autonome. Une première tentative aux clics a produit Light1→Heavy ordinaire (timing du pilote), donc ne prouve pas le défaut de proxy. Le rejeu contrôlé par les vraies requêtes serveur, en attendant chainOpen, produit ensuite **Light1→PuppetBlade**, puis **bodies=[]**. Aucun coup ennemi ; [avant](screenshots/puppet-before.jpg), [après](screenshots/puppet-after-proxy.jpg). C'est un FAIL natif du lifecycle ciblé, pas une acceptation de l'ergonomie clavier complète.
- **Zabuza vu par Nagato** : brume déclenchée côté bot par requête serveur ; snapshot humain shrouded=true, corps adverse à LocalTransparencyModifier≈.82. [Capture](screenshots/mist.jpg). La caméra est toujours pilotée par la position précise dans le code inchangé ; pas de test de suivi latéral complet revendiqué.
- **Shisui** : vrai T puis quatre vraies touches1, sans replacement entre les casts : **4 cuts touchés, 3 refreshs ChainTeleport**. [Capture](screenshots/shisui-chain.jpg). Confirme une amélioration réelle de continuité ; garde/whiff et lisibilité restent à tester, pas besoin de refaire la règle de chaîne.
- **Nagato** : vrai3/Absorb, puis outil adverse via requête serveur. Premier essai avec Lee invalide (`Nothing to deflect`, aucun projectile), explicitement écarté. Rejeu avec Sasuke : outil accepté, **Absorbed=2** ; [capture](screenshots/absorb.jpg). Les HP400 artificiels du setup sont ramenés au max112 par le clamp de soin : pas une mesure de dégâts ni un bug de balance. La fenêtre réellement défensive existe ; son feedback à l'instant du contact reste à améliorer/observer.

Les captures internes servent au diagnostic ; certaines ont F8 visible. Ne pas les traiter comme validation humaine de feel ou média final. Aucune sélection exhaustive20, aucune manette physique ou session publiée revendiquée. Console : avertissements CorePackages/UIBlox internes Studio présents ; aucun crash nouveau Ninja Duel isolé dans cette passe. Retour à la sélection, bot/autopilot non laissé en duel. Sources du protocole dans les fichiers native-*-source.txt ; le helper doit recevoir l'instance courante plutôt que son ancien SID historique.

## BLOCKING / IMPORTANT / POLISH

BLOCKING signifie bloque l'acceptation du contrat combat concerné, **pas crash global ni P0**. Aucun P0 confirmé.

| Niveau | Constat actuel | Preuve / précision |
|---|---|---|
| BLOCKING | Une route portée consomme la marionnette persistante de Sasori | Sonde : 1 marionette avec19.4s restantes → PuppetBlade → 0, mode spent. Bodies.bind/carry réutilise le lifecycle consommable des clones. Confirmé ensuite en Studio par la requête serveur réelle Light1→PuppetBlade ; pas une frappe ennemie. |
| BLOCKING | Une garde frontale réussie reçoit le poison du jab autonome | Sonde : impactStyle=block, poisonedUntil encore1.78s. Bodies.hitFrom rend vrai sur block ; Wave3Kit applique ensuite poison sans distinguer garde. Les autres riders de famille distinguent ce cas. |
| BLOCKING | La nouvelle mine ignore sa portée d'implantation | ClayMine Range26 acceptée à100, charge effectivement implantée à100.00. F.Zone.check=true et position pas bornée. Demande autoritaire à valider ; la garde client à140 n'est pas la portée du kit. |
| IMPORTANT | Téléport validé avant channel, cible suivie au-delà de portée à release | SilentKilling accepté à20, cible déplacée de100 pendant channel, déplacement final105.58. Ne pas confondre avec l'ancien check à la demande, corrigé. Définir la borne release et le sort du coût si la cible s'échappe. |
| IMPORTANT | Brume partiellement perceptible, « no lock » non appliqué partout | shrouded=true et transparence adverse .82 en Studio. Camera continue à cadrer la position exacte ; releaseAim et le lancer standard peuvent réacquérir cette cible. Serveur retire déjà facing/rush homing, à conserver. |
| IMPORTANT | Compteurs de la grille trompeurs pour le feel | push=0 pour20, mesure prise après le déplacement ; distinct-technique inféré de cooldowns de fin, valeurs0 malgré plusieurs casts. Ne pas équilibrer sur cette mesure. |
| IMPORTANT | États tactiques disponibles mais lecture partielle | Charges sans armedAt/armed dans le snapshot des hazards ; fuse FX indépendant de l'état d'armement. Absorb existe mais durée/règle/objet absorbé doivent être compris sans console. |
| POLISH | Variété de rythme/contact encore à démontrer en jeu | Les durées de chaîne sont proches pour18/20 ; graphes/clips réemployés. C'est un signal à tester, pas un verdict humain dérivé du headless. Clarté lame Zabuza, jab Sasori, ring Haku et contre-gardes à confronter à l'image. |

[Sondes et reproduction](probes-source.txt), [résultats bruts](probes.log). Aucune modification de production ; fichier temporaire retiré des tests après exécution. Le déplacement de13 studs pendant un channel sort de la fenêtre snap et conserve le point ancien : fait observé, **pas bug déclaré**, car une esquive doit encore pouvoir faire rater. Préserver le contre-jeu, ne pas élargir l'auto-aim aveuglément.

## Les cinq écarts de feel les plus coûteux

1. **Action et résultat ne tiennent pas toujours la promesse** : Sasori perd son outil de combat après sa propre route ; une garde peut paraître réussie tout en appliquant du poison.
2. **Confiance dans distance/visée** : mine au-delà de sa portée, téléport suivant une fuite hors portée, snap souris à valider en mouvement. Le joueur doit pouvoir estimer engagement et sortie.
3. **Lecture du contre-jeu** : brume qui masque le corps mais laisse des aides connaître sa position ; charges/absorption dont les fenêtres restent peu explicites.
4. **Contact et poids propres aux styles** : lame, paume, os, puppet et taijutsu emploient encore largement des clips communs. Variation de nombres ne prouve pas anticipation, contact, réaction et follow-through distincts. Hypothèse ciblée à valider en natif, pas « tous identiques » affirmé.
5. **Continuité route → poursuite → air → retour au neutral** : grille headless conv=3 partout mais n'atteste ni lecture des fenêtres ni caméra ni disponibilité des touches. Tester sans téléporter/refill entre les coups ; ne pas rouvrir les conversions déjà fonctionnelles.

[Grille actuelle](grid.log) : chaînes0.51–0.59s pour18 ; Sand0.82 et Puppet0.76. Heavy souvent0.27–0.33. AIvsLeaf seed unique finit15–33s dans ce protocole. Ces chiffres ne fixent ni équilibre cible ni durée native, et ne prouvent pas toutes les techniques/synergies.

## Existe techniquement, perception encore à confirmer

| Déjà présent | Ne pas reconstruire | Ce qui manque pour le joueur |
|---|---|---|
| Puppet persistant + lunge + routes proxy | Bodies/Summon/controller/BodyViews | Continuité après route, garde honnête, geste lisible à la source du hit |
| Clay charges, trigger, Katsu distant, chaînes d'éveil | Families plant/detonate et hooks fin de projectile | Armement/expiration/détonation lisibles, portée fidèle ; pas un nouveau système d'explosifs |
| Absorb2.5s et réflexion de projectiles | Families.step + Buff.Absorb + Burst.Clear/ReflectClear | Entrée/sortie de fenêtre et récompense lisibles ; vérifier objets rapides, guard et melee qui doit rester dangereux |
| Haku ring-volley et gratuité éveillée | Teleport.Ring, ownZone, ZoneFree | Correspondance miroir d'arrivée/salve et état zone ; pas refonte des miroirs |
| Shisui chaîne au hit, stagger réduit | ChainTeleport, cooldown, FlickerCut | Différence hit/garde/whiff et fin de chaîne reconnaissables sans compteur debug |
| Kimimaro/Kabuto couches fusionnées | buff/onHit/clearState + Convergence.spec | Armure/drain/slow perceptibles et reset sans résidu ; pas réécrire les kits |
| Brume, cleaver tenu, transparence adversaire | shrouded + Wave1FX | Cohérence caméra/aide de visée et sortie de brume, contact lame |

## Réutilisation technique obligatoire pour ces petits blocs

- **Families** : check/execute, contact, releaseAim/snapAim, couches buff/onHit, clearState, traits de zone. Ajouter un contrat générique au besoin réel, jamais `if fighterId` dans Combat pour réparer une portée ou un poison.
- **Bodies** : route/bind/carry/contrôleurs/hitFrom/view ; distinguer corps persistants et consommables par donnée/contrat, préserver Naruto. Pas moteur de marionnettes parallèle.
- **Brawler + MoveGraphs + RosterMoves** : fenêtres de hit confirmé, routes/air/proxy/cancels. Conserver l'invariant avant premier hit et les anciennes entrées ; pas graphes clonés par fighter.
- **Motion / AttackProfile / poses / feedback et FX.layers** : paramètres et variantes locales de clip, anticipation/contact/reaction. Aucun nouveau moteur d'animation, de caméra ou d'impact.
- **Matches snapshots / FamilyFX / BodyViews** : serveur possède état/temps ; client montre cet état, sans recalculer le droit d'armement ou de hit. Extensions minimales de champs, pas bus/framework nouveau.
- **AI.familyWants / spec.AI** : opportunités/rotations par famille. Vérifier ce qui est réellement utilisé ; pas vingt nouvelles politiques nominatives.

## Fiches ultra-courtes des huit anciens WEAK

Chaque ligne décrit le delta courant ; ce n'est pas une réattribution automatique du statut global du dernier audit.

| Fighter | Déjà corrigé / livré | Seul prochain besoin utile |
|---|---|---|
| Shisui | ChainTeleport réel + cut stagger | 4casts/4hits/3refreshs déjà vus en natif sans replacement ; reste garde/whiff et fin de chaîne lisible. |
| Haku | Ring + volley + ZoneFree | Voir arrivée/salve aux vrais miroirs et sortie du dôme ; ne pas refaire un réseau entier. |
| Kimimaro | Camellia et éveil composés | Confirmer armure/super-armure en contact et fin au round ; pas de nouveau jutsu. |
| Nagato | Absorption défensive + ReflectClear | Fenêtre lisible et contre-jeu melee ; vérifier trajet/effets renvoyés, pas de Six Paths. |
| Sasori | Marionette persistante et proxy | Réparer consommation par ses routes et poison sur garde ; observer le jab à sa vraie source. |
| Deidara | Charges + Katsu + ChainCharges | Borne Range26 et états armé/explosion ; pas ajouter d'autres formes d'argile. |
| Zabuza | Cleaver main + Shroud | Lock/visée cohérents avec la brume, contact lame ; conserver le flow existant. |
| Kabuto | OnHit drain/slow fusionné | Retour d'information drain/slow et soin à HP produit ; pas nouvelle mécanique médicale. |

## Missions et scénarios prêts pour Claude

Les **sept missions ordonnées et leurs scénarios d'acceptation sont dans le propriétaire actif QA-004 du backlog** : M1 marionnette, M2 portées release, M3 brume, M4 mesure fiable, M5 états lisibles, M6 feel par familles, M7 gate finale vingt. Ce rapport ne crée pas d'ordre parallèle. Chaque mission = périmètre borné, tests pertinents, build exact, scénarios Studio, preuve avant/après, commit puis mise à jour de l'état.

Aucune autorisation de nouveau personnage ou système hors combat. La prochaine mission n'a pas à redécouvrir les quatre défauts : source/lignes et logs sont ici. Les améliorations de design non prouvées restent des hypothèses à confronter au natif.

## Localisation directe au HEAD audité

- [Bodies](../../../../src/Server/Bodies.luau) : bind166 et carry177–180 convertissent systématiquement le porteur en spent puis expires≤now+.22 ; distinguer persistant/éphémère.
- [Wave3Kit](../../../../src/Server/Wave3Kit.luau) : ligne31–32, poison après tout hitFrom vrai ; [Bodies.hitFrom](../../../../src/Server/Bodies.luau),215, renvoie aussi vrai sur block. Préserver les consommateurs de cette API.
- [Families.Zone](../../../../src/Server/Families.luau) :481–493, check=true et pose à l'aim sans Range ; Teleport check≈525 avant le channel, execute≈537 sans revalidation.
- [Camera](../../../../src/Client/Camera.luau) :112,130,146–163 suit target sans shrouded ; [Families](../../../../src/Server/Families.luau) releaseAim≈296 et [Combat.stepThrow](../../../../src/Server/Combat.luau)≈503 réacquièrent sans shroud.
- [Grille](../../../../tools/roster_grid.luau) : string mesure from après la boucle ; distincts lisent cooldowns en fin de duel. [Matches](../../../../src/Server/Matches.luau) hazards≈252 n'expose pas armedAt.

Validation de livraison documentaire : contrôle liens/75 IDs/sept tests de reprise PASS, frontières408 fichiers PASS, isolation9/9 PASS, diff --check PASS. Aucun src/test/build/artefact modifié par Codex. La seule exécution additionnelle de code est une sonde temporaire de lecture/provocation et la mise en situation Studio, pas une implémentation concurrente.
