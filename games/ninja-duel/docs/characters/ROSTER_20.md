# Les20 Character V1 Combat Bibles

**Roster de design corrigé, brief utilisateur18/10/2026.** [Décision normative DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles) · [contrat de chorégraphie](FIGHTER_TEMPLATE.md) · [état réel](../active/CURRENT_STATE.md) · [travail/acceptation](../active/MASTER_BACKLOG.md). Aucun runtime modifié.

V1 = corps, mouvements, animations, coups/combos, réactions/défense, armes naturelles/physiques et signatures fondamentales. Reconnaissance HUD masqué en quelques secondes. Le chakra global final, les armes globales, l’arbre, la maîtrise acquise, le son/VFX/balance finaux restent ultérieurs. **Intégrer un os, un clone, le sable ou un mirage au geste fait déjà partie de V1**, ce n’est pas attendre le système final.

## Audit initial du roster réel

HEAD audité `41364ed5c79cfdac4d7a29bbcdc75b893caad622`, incluant la correction M1 de Claude. Sources : [Roster](../../src/Shared/Roster.luau), [Fighters](../../src/Shared/Fighters.luau), [Wave1](../../src/Shared/Wave1.luau), [Wave2](../../src/Shared/Wave2.luau), [Wave3](../../src/Shared/Wave3.luau), [MoveGraphs](../../src/Shared/MoveGraphs.luau), [Motion](../../src/Client/VelmoraMotionEngine.luau), [Bodies](../../src/Server/Bodies.luau). Relevé ciblé des20cibles, pas audit général du repo. Les trois nouveaux ne sont pas trouvés dans définitions/graphes/clips ; la seule mention de Hiruzen en commentaire n’est pas un kit.

**Build au 18/10 (Claude) : menu migré sur la cible DEC-026, 17 + 3.** Madara `Rival`, Hashirama `Sapling`, Hiruzen `Professor` jouables (V1 : corps, arme, routes, riposte, posture de contre, éveil qui change la riposte). Hinata/Lavender, Temari/Gale et Kabuto/Medic sortent du menu ; leur code et leurs suites restent. *(Ancien état : vingt anciens IDs, dont 17 dans la cible.)* Madara enfant/Hashirama enfant/Hiruzen enfant entrent ; pas mutation du menu dans cette mission. Claude migrera de façon atomique quand le lot sera ouvert ; préserver les anciens modules/historiques sans collision d’IDs.

Dernières preuves natives disponibles : [audit incrémental](../archive/audits/2026-10-18-feel-preparation/AUDIT.md), build Debug exactbc7faa3. Shisui4cuts/3refreshs et NagatoAbsorbed2 existent ; Sasori proxy consommait le corps (FAIL ciblé historique), corrigé en source par M1 `41364ed`, pas encore revu nativement. Ce ne sont pas des PASS des nouvelles chorégraphies. Réexécution des suites du HEAD source consignée dans CURRENT_STATE.

## Les vingt bibles — ordre demandé

| # | Bible | État runtime | Geste/grammaire irréductible |
|---|---|---|---|
| 1 | [Itachi](ITACHI.md) | `Mirage` existant | Inviter une réponse, la lire puis la punir avec un geste plus petit que celui de l’adversaire. |
| 2 | [Shisui](SHISUI.md) | `Flicker` existant | Changer d’angle par rafales de Shunshin, laisser une fausse continuité puis frapper depuis la vraie position. |
| 3 | [Sasuke](SASUKE.md) | `Lion` existant | Engager par les jambes, prendre la verticale puis choisir fil, feu ou frappe électrique engagée. |
| 4 | [Madara enfant](MADARA_CHILD.md) | **V1 jouable** `Rival` (18/10, `Shared/Wave4`) | Imposer le centre avec une escrime Uchiha frontale, provoquer le bloc puis casser l’angle par autorité physique. |
| 5 | [Hashirama enfant](HASHIRAMA_CHILD.md) | **V1 jouable** `Sapling` (18/10, `Shared/Wave4`) | Avancer comme un lutteur, encaisser avec ses appuis et faire naître de petites prises de bois au milieu de ses gestes. |
| 6 | [Hiruzen enfant](HIRUZEN_CHILD.md) | **V1 jouable** `Professor` (18/10, `Shared/Wave4`) | Répondre avec la bonne extrémité d’un bâton et un outil placé, en changeant de distance plutôt qu’en accumulant les éléments. |
| 7 | [Minato](MINATO.md) | `Flashstep` existant | Préparer une destination, prendre l’angle puis continuer un échange avant que l’adversaire ne retrouve sa ligne. |
| 8 | [Kakashi](KAKASHI.md) | `Copycat` existant | Mesurer avec la lame courte et le regard, puis engager une seule punition précise avec un coût de lecture réel. |
| 9 | [Naruto](NARUTO.md) | `Legion` existant | Déborder par plusieurs origines de coups tout en gardant un vrai corps impulsif et une préparation lisible. |
| 10 | [Gaara](GAARA.md) | `Sand` existant | Rester calme au centre pendant que le sable devient ses bras, sa garde et son contrôle de distance. |
| 11 | [Rock Lee](ROCK_LEE.md) | `Leaf` existant | Gagner par les appuis, l’extension des jambes et l’effort visible, sans magie dans les mouvements ordinaires. |
| 12 | [Neji](NEJI.md) | `GentleFist` existant | Lire le centre adverse et démonter sa posture par des paumes placées plutôt que par force ou rotation gratuite. |
| 13 | [Haku](HAKU.md) | `Mirror` existant | Coudre les angles avec senbon, petits appuis de glace et sorties de miroir, sans devenir un mage immobile. |
| 14 | [Kimimaro](KIMIMARO.md) | `Bone` existant | Faire naître l’arme au moment où le squelette frappe, garde ou change d’appui. |
| 15 | [Nagato](NAGATO.md) | `Rinnegan` existant | Déplacer le rapport de forces par de petites paumes et de grands changements de distance, avec un corps fragile et minimal. |
| 16 | [Orochimaru](OROCHIMARU.md) | `Serpent` existant | Sonder par une allonge souple, refermer une prise puis sortir de l’axe en gardant une menace aux manches. |
| 17 | [Sasori](SASORI.md) | `Puppet` existant | Contrôler deux corps avec un seul cerveau : le maître donne le rythme et la marionnette déplace l’origine du danger. |
| 18 | [Deidara](DEIDARA.md) | `Clay` existant | Toucher pour repousser ou poser une petite menace, puis gagner l’espace qui rend son argile dangereuse. |
| 19 | [Killer Bee](KILLER_BEE.md) | `Ink` existant | Faire lire une lame et frapper d’une autre configuration du corps, avec un kenjutsu multi-sabres rythmé et exposé s’il est mal engagé. |
| 20 | [Zabuza](ZABUZA.md) | `Mist` existant | Faire sentir le couperet à chaque appui, puis utiliser la brume pour masquer le départ d’une attaque lourde. |

## A. Animation reuse matrix

Le partage porte sur rig, phases et courbes locales. « Retargeter » exige un rendu distinct dans appuis/armes/angles/réactions ; changer couleur/vitesse seulement ne suffit pas.

| Famille | Combattants / points de départ | Peut réellement être partagé | Doit rester différent |
|---|---|---|---|
| F1 précision / lecture | Itachi, Minato, Kakashi | Fenêtres de parade, phase de reprise, courbe de demi-pas, attaches kunai | Itachi invite, Minato place/arrive, Kakashi mesure à la lame ; L1–L3/Heavy et mains libres propres |
| F2 trajectoire courte | Shisui, Haku | Courbe d’accélération/frein et pivot bas, état de déplacement borné | Après-image et rafale de Shisui vs appui glace/senbon/miroir de Haku ; pas même warp |
| F3 athlétique | Lee, Sasuke | Courbe de hanche, appui du kick, poursuite/retombée et captures à deux corps | Lee extension/effort, Sasuke jambes/fil/Chidori ; chaîne et réception distinctes |
| F4 armes à masse/configuration | Zabuza, Bee, Madara enfant | Attache/rangement fixe, reprise de prise, phase collision/contact, base de frein | Couperet lourd, multi-lames syncopées, sabre court frontal : aucun clip visible repris tel quel |
| F5 appui / corps renforcé | Neji, Kimimaro, Hashirama enfant | Transfert de poids court, squelette des réactions, mécanisme d’extension locale | Paume de point, os qui naît du membre, bois de lutteur ; source/prise/volume propres |
| F6 distance / préparation | Orochimaru, Deidara, Hiruzen enfant | Recul diagonal, état main occupée, release/recovery local | Manche souple, paume qui pose de l’argile, changement de prise du bâton |
| F7 deux corps | Naruto, Sasori | Bodies/proxy, propriétaire du hit, snapshots/poses et timing maître-porteur | Clone copie Naruto et est consommable ; puppet permanent commandé, maître ne mime pas ses coups |
| F8 corps calme / forces | Gaara, Nagato | Posture basse fréquence, fin de réaction, fenêtre de commande/zone | Sable avec vraie origine matérielle vs main qui attire/repousse, aucune Light3 kick recyclée |
| Réactions / get-up | Tous, par famille | Stagger/knockback/knockdown/landing states, trajectoire root, sol/physique | Amplitude locale, membre touché, poids d’arme, pause et garde de sortie ; aucune protection implicite |
| Air / mur / fin | Tous quand pertinent | Compteurs et anti-infini, poursuite, gravité, validation mur/LOS | Contacts paume/lame/porteur/sable et place de caméra ; aucune obligation de même AirKick |

**Budget d’auteur :** cinq unités prioritaires×20≈100unités (L1/L2/L3/Heavy/un geste signature), plusieurs déjà existantes. Bases locomotion/réactions en huit familles + exceptions de prise/porteur ; viser moins de200unités de conception/retargeting, pas300nouveaux clips uploads. Comptabiliser existant conservé, variante retargetée, nouvel accent et asset requis séparément. Une unité de geste peut être des poses procédurales dans Motion, pas un AnimationId distinct. Les branches réutilisent les appuis/accents de la chaîne sans être de simples clones visuels ; un seul nouveau clip de route si la dérivation ne suffit pas.

## B. Unique animation requirements

Ces unités ne peuvent pas être remplacées par une chaîne d’un voisin avec couleur différente. « Unique » décrit la chorégraphie ; conserver un clip actuel s’il satisfait déjà la bible et le prouver en Studio.

| Personnage | Unités irréductibles à livrer/valider |
|---|---|
| [Itachi](ITACHI.md#b-unique-animation-requirements) | L1 déviation ; L2 paume ; L3 retrait couvert ; Heavy paume traversante ; transition Read→riposte. |
| [Shisui](SHISUI.md#b-unique-animation-requirements) | L1 revers ; L2 décalage-paume ; L3 coupe freinée ; Heavy croisé ; transition rafale/trace sur locomotion. |
| [Sasuke](SASUKE.md#b-unique-animation-requirements) | L1 chasse-paume ; L2 kick côtes ; L3 talon borné ; Heavy genou ; transition ShadowLeaf. |
| [Madara enfant](MADARA_CHILD.md#b-unique-animation-requirements) | L1 taille descendante ; L2 pommeau ; L3 taille inverse ; Heavy taille de corps ; parade→pommeau. |
| [Hashirama enfant](HASHIRAMA_CHILD.md#b-unique-animation-requirements) | L1 prise-paume ; L2 avant-bras bois ; L3 double poussée ; Heavy gaine ; naissance/retrait racine. |
| [Hiruzen enfant](HIRUZEN_CHILD.md#b-unique-animation-requirements) | L1 estoc ; L2 talon inverse ; L3 levier ; Heavy transversal ; transition de prise/parade. |
| [Minato](MINATO.md#b-unique-animation-requirements) | L1 revers ; L2 paume sceau ; L3 genou-poussée ; Heavy couvert ; pose départ/arrivée FTG. |
| [Kakashi](KAKASHI.md#b-unique-animation-requirements) | L1 estoc ; L2 déviation avant-bras ; L3 revers retrait ; Heavy estoc corporel ; couverture/découverture œil. |
| [Naruto](NARUTO.md#b-unique-animation-requirements) | L1 crochet ; L2 direct ; L3 split Naruto/clone ; Heavy tête ; transition façonnage Rasengan. |
| [Gaara](GAARA.md#b-unique-animation-requirements) | L1 fouet ; L2 revers bas ; L3 paume sable ; Heavy masse ; transitions sable/gourde. |
| [Rock Lee](ROCK_LEE.md#b-unique-animation-requirements) | L1 placement ; L2 fouet hanche ; L3 talon ; Heavy jambe abattue ; Lotus à deux corps. |
| [Neji](NEJI.md#b-unique-animation-requirements) | L1 point sternum ; L2 point côte ; L3 double paume ; Heavy poussée ; air paume descendante. |
| [Haku](HAKU.md#b-unique-animation-requirements) | L1 pique ; L2 paume/pic ; L3 sortie senbon ; Heavy appui/pique ; transition miroir. |
| [Kimimaro](KIMIMARO.md#b-unique-animation-requirements) | L1 phalanges ; L2 coude ; L3 tibia tournant ; Heavy côtes/avant-bras ; apparition-rétraction en garde. |
| [Nagato](NAGATO.md#b-unique-animation-requirements) | L1 mesure ; L2 appel ; L3 rejet ; Heavy double paume ; transition attraction/rejet. |
| [Orochimaru](OROCHIMARU.md#b-unique-animation-requirements) | L1 prise ; L2 paume allongée ; L3 coude/serpent ; Heavy extension ; retrait de manche. |
| [Sasori](SASORI.md#b-unique-animation-requirements) | L1 commande/contact ; L2 coupe puppet ; L3 attaque croisée ; Heavy ciseaux ; reprise de fils/porteur. |
| [Deidara](DEIDARA.md#b-unique-animation-requirements) | L1 dégagement ; L2 paume-pose ; L3 poussée sortie ; Heavy motte ; mouvement de retrait-création. |
| [Killer Bee](KILLER_BEE.md#b-unique-animation-requirements) | L1 lame main ; L2 lame coude ; L3 lame genou ; Heavy X ; reprise/rangement de configuration. |
| [Zabuza](ZABUZA.md#b-unique-animation-requirements) | L1 poignée ; L2 arc ; L3 revers lourd ; Heavy diagonal ; garde/reprise couperet. |

## C. Implementation priority

Priorités de **design/effort pour V1**, pas nouveau classement de bugs P0. Les corrections runtime en cours restent prioritaires ; les lots ne s’ouvrent pas automatiquement parce que ce tableau existe.

| Groupe | Personnages | Raison / sortie attendue |
|---|---|---|
| Plus gros écart physique | Bee, Kimimaro, Sasori, Zabuza | Multi-lames absent, squelette réduit à lame, maître qui mime les coups, couperet sur clips d’éventail ; corps/arme/contacts doivent changer ensemble |
| Identité fondamentale peu portée par le corps | Shisui, Haku, Nagato, Deidara | Boutons/effets déjà là, mais Shunshin/glace/forces/pose d’argile doivent entrer dans mouvement/Light/défense |
| Trois nouveaux à construire après socles démontrés | Madara enfant, Hashirama enfant, Hiruzen enfant | Aucun kit actuel ; bibles précises mais extrapolations déclarées, réemploi des primitives déjà éprouvées |
| Convergence/retargeting | Itachi, Minato, Kakashi, Sasuke, Lee, Neji, Orochimaru | Plusieurs systèmes fonctionnent ; gestes/air/recovery et signatures à réarticuler, pas reset du kit |
| Préserver le plus possible | Naruto, Gaara | Corps multiples et sable déjà distincts ; réparer/compléter les routes/réactions plutôt que brawleriser |

## D. Current-vs-target gap

| Personnage | Actuel → manque → cible V1 |
|---|---|
| Itachi | Read/ricochet/genjutsu déjà là ; jabs/kick Mirage et héritages air restent trop brawler → mains de contrôle, invitation/réponse visible. |
| Shisui | ChainTeleport natif fonctionne ; corps Lion et FlickerStep emprunté ne donnent pas Shunshin partout → rafales, fausses continuités et coups courts cohérents. |
| Sasuke | Kicks/fil/Chidori/ShadowLeaf déjà fonctionnels ; clips hérités et tours trop génériques → chaîne de jambes engagée et fins alternatives. |
| Madara enfant | Aucune définition/clip/graphe dans le runtime → nouvelle identité physique simple, sans importer une prime adulte. |
| Hashirama enfant | Aucun fighter runtime → lutteur/Mokuton local extrapolé, pas copie de Gaara avec FX marron. |
| Hiruzen enfant | Aucun fighter runtime → prodige de distance/bâton/outils ; Enma et arsenal adulte ne sont pas prérequis. |
| Minato | Réseau de marques et conversions existent ; fin Light3 tournante et héritages obscurcissent précision → gestes de kunai/paume et destinations compréhensibles. |
| Kakashi | Kit de trois jutsus et famille Mirage présents ; tantō/lecture corporelle manquent → escrime mesurée au lieu de kick fighter avec Raikiri. |
| Naruto | Bodies/proxies et Rasengan aidé déjà substantiels ; continuer leur intégration, corriger décalages caméra/contact plutôt que refaire système de clones. |
| Gaara | Clips Sand et bouclier distincts déjà présents ; conserver, combler Side/Air/fin sans glisser vers un brawler. |
| Rock Lee | Stance/LeafRising/Lotus existent, famille Lion encore très partagée → différence d’appui/rythme et non simple vitesse augmentée. |
| Neji | Jûken/points/Rotation substantiels ; air/throws et quelques poses Mirage restent génériques → paumes et cercle jusqu’au retour au neutral. |
| Haku | Ring/ZoneFree et dôme réels, corps Mirage avec senbon comme outils surtout → glace et précision dans les déplacements/contacts ordinaires. |
| Kimimaro | Buff lame et clips Lion présents, composition réparée → squelette vivant dans coups/garde/réactions, pas épée claire sur brawler. |
| Nagato | Absorb/ReflectClear réels ; famille Mirage et RepellingPalm emprunté masquent la gestuelle → paumes et transitions de forces locales. |
| Orochimaru | Pull/poison/bind existants, corps Mirage sans arme → manches et allonge corporelle dans les Light chains. |
| Sasori | M1 (`41364ed`) restaure le porteur persistant après proxy et interdit le poison sur garde ; validation native de ce delta encore attendue. Light Sand reste porté par le maître → alternance maître/marionnette à chorégraphier. |
| Deidara | Charges/Katsu existent, corps Mirage reste générique → pression de placement/pose dès la chaîne et défense avec vrai engagement. |
| Killer Bee | Runtime Ink = lutteur sans armes, trois jutsus et famille Lion ; contredit le kenjutsu requis → plus gros chantier de rig/chaîne/poses, conserver Lariat comme option. |
| Zabuza | Cleaver main et brume ajoutés, clips Gale empruntés → masses/arcs/reprises physiques de couperet sur chaîne et défense. |

## E. Claude execution batches

Plan de conception proposé, **pas interruption ni ouverture de lots**. Les priorités/tâches opérationnelles appartiennent à [MASTER_BACKLOG](../active/MASTER_BACKLOG.md), CHR-CORE-001/002 et CHR-EXT-002. Chaque sous-lot charge seulement deux bibles ou une bible complexe. Fin de lot : comparaison native, rapport, puis suivant ; pas recréer toutes les branches en même temps.

| Lot | Périmètre / dépendance | Livrables et taille de commit |
|---|---|---|
| L1 prérequis | Valider nativement M1 livré (lifecycle proxy/poison-gardé), puis achever portées et brume cohérente | Contrats testés, pas framework neuf. Vérifier que Motion/FX savent suivre les attaches/marqueurs réels ; ajouter un helper neutre seulement si deux consommateurs le réclament |
| L2-A lecture/escrime | Itachi + Kakashi | Commit corps/Light/Heavy puis commit Read/arme/routes ; récupérer les handlers existants, aucun système Copie global |
| L2-B angle/destination | Minato + Shisui | Séparer réseau FTG et trajectoire Shunshin/trace ; locomotion avant bouton spectaculaire, deux commits de gestes/intégration puis preuve |
| L3-A jambes | Lee + Sasuke | Reprises de hanche et Heavy ; variantes air/Lotus/fil ensuite ; budget commun, pas vitesse différente comme seul travail |
| L3-B paumes | Neji + Nagato | Paumes de points vs forces minimales ; source et réactions distinctes ; conserver handlers existants |
| L3-C allonge | Orochimaru seul | Manches/extension et chaîne souple ; pas arsenal adulte ni autre ressource |
| L4-A matière corporelle | Kimimaro + Haku | Apparition/rétraction os/glace et appuis dans Lights ; les miroirs/lames longues viennent ensuite, pas shader-only |
| L4-B sable | Gaara seul | Conserver corps calme et clips Sand ; combler Side/Air/Heavy/réactions, aucune mêlée de boxe |
| L5 deux corps | Naruto + Sasori après L1 | Premier commit propriétaire/contact/persistence de porteur ; second chaînes alternées et poses maître/porteur ; Naruto consommable reste distinct du puppet persistant |
| L6 argile | Deidara seul | Chaîne défensive/pose d’objet borné ; Katsu/charges existants réutilisés ; pas nouvelle usine d’explosifs |
| L7-A couperet | Zabuza seul | Poignée/arcs/inertie/garde puis brume/fin ; primitive d’attache/rangement réutilisable |
| L7-B multi-lames | Bee seul après L7-A | Rigs/configurations fixes, L1main→L2coude→L3genou et Heavy ; ensuite Lariat/manteau ; ne pas lancer un système armes global |
| L8-A nouveau sabreur | Madara enfant après L7 | Nouveau kit simple depuis bible, aucune prime ; source/lore extrapolé explicite |
| L8-B nouveau lutteur | Hashirama enfant après L4 | Bois local dans appuis/bras, pas forêt ou guérison de prime |
| L8-C nouveau technicien | Hiruzen enfant après L2/L7 | Bâton/prise/outils et un Katon local ; pas Enma ni cinq éléments nécessaires |
| L9 migration / gate | Seulement quand3nouveaux jouables et17conservés cohérents | Migration atomique du roster cible et menus/tests, sans effacer modules anciens ; vingt sélectionnables cibles, pas23. Puis séquences continues HUD masqué, garde/whiff/air/KO/reset et manette |

**Condition pour finir un sous-lot :** corps identifiable sans jutsu ; trois Lights et Heavy ont intention/contact/transition propres ; une route sol et une fin air continues sans replacement ; arme/pouvoir physique présent au quotidien ; signature complète la boucle ; contre-jeu garde/whiff/interruption ; aucun reset infini ; source/hash et limites Studio consignés. Si une variante partagée suffit réellement, prouver au lieu de produire un asset de plus.

## Provenance et limites

[Brief utilisateur intégral](../archive/requests/2026-10-18-character-v1-combat-bibles.md). Canon principal puis sources secondaires identifiées, enfin extrapolation raisonnable. Références initiales : [enfance Madara/Hashirama, chapitres621–624](https://naruto-official.com/en/news/01_1663), [Hiruzen adulte/Enma](https://naruto-official.com/en/news/01_1287), [Bee à sept lames à une période ultérieure](https://naruto-official.com/news/01_1316). Ces pages n’attestent pas toutes les capacités à12–14 ; les bibles le disent explicitement. Les chorégraphies et adaptations de combat sont du design, pas une encyclopédie canon inventée.

Anciennes vingt fiches/contradictions de roster préservées [en archive](../archive/characters/2026-10-18-superseded-profiles/DISPOSITION.md). La cible Bee multi-sabres remplace son ancienne exclusion ; la cible Kimimaro remplace l’escrime à lame blanche comme identité de base. L’ancien gabarit de systèmes globaux n’est plus la gate V1. Aucun runtime, asset, test gameplay ou build modifié par cette mission.
