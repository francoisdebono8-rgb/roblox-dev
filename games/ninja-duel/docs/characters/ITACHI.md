# Itachi — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Mirage`**, âge affiché13 ; mouvement/clip effectif `Mirage`, armes déclarées `famille native`. Techniques présentes : `Read`, `NeedleFan`, `MirageCast`, `FireBloom`, `PhoenixFlower`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FeintStep`, up=`Launcher`. [Données](../../src/Shared/Fighters.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Read/ricochet/genjutsu déjà là ; jabs/kick Mirage et héritages air restent trop brawler → mains de contrôle, invitation/réponse visible.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. Exclusions/point de période : Susanoo/Amaterasu/Tsukuyomi non requis pour V1 ; leur disponibilité jeune n’est pas résolue par la seule étiquette13. Ne pas importer son kit adulte.

**Tenue/silhouette :** Tenue Uchiha bleu très sombre, col haut, emblème clan discret, bandeau ; posture calme et shuriken à portée de main. Tenue de mission jeune, sans cape Akatsuki.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Inviter une réponse, la lire puis la punir avec un geste plus petit que celui de l’adversaire.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Buste presque vertical, main gauche ouverte, droite près des shuriken. |
| Jambes / centre de gravité | Pied gauche avancé, poids centré légèrement arrière. |
| Avance | Demi-pas silencieux, épaules stables. |
| Recul | Pied arrière recule avant transfert du bassin. |
| Strafe | Croise peu les pieds, pivote autour du regard. |
| Sprint | Bras bas, accélération contenue plutôt que bonds. |
| Dash / rush | Court décalage oblique, vraie translation lisible. |
| Saut | Genoux relevés sans écarter les bras. |
| Chute | Main libre surveille le sol, silhouette compacte. |
| Landing | Avant-pied puis talon, relève immédiatement le regard. |
| Garde | Avant-bras gauche ferme la ligne, droite reste disponible. |
| Esquive | Épaule s’efface, pied arrière replace la garde. |
| Réaction légère | Tête/épaule absorbent, pas de pirouette. |
| Réaction lourde | Bassin cède, deux pas pour retrouver l’axe. |
| Knockdown / get-up | Chute de côté, appui de paume puis relève courte. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Gauche, tranchant de main | Extérieur→intérieur sur poignet/épaule | Pied avant +0.3, hanche presque fixe | 3.0 | 0.12/0.05/0.20 | court : Écarter la garde, main droite toujours armée. |
| L2 | Droite, talon de paume | Centre→sternum sous la main gauche | Pivot arrière +0.4, aucune rotation complète | 3.2 | 0.14/0.05/0.18 | léger délai puis sec : Déplacer le poids adverse et préparer la lecture. |
| L3 | Gauche, paume puis retrait | Oblique haut→bas sur épaule | Pied arrière retire0.6 pendant la poussée | 3.3 | 0.22/0.06/0.30 | retenu→net : Créer l’espace de shuriken ; termine sans tourner le dos. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : poignet gauche contrôle puis paume droite monte sous le bras ; launcher court, pas coup de pied générique. |
| Side après1hit | Un hit : pied arrière passe de30° sur le flanc, main gauche mime une frappe, droite touche le bras ; coûte la branche. |
| Away après2hits | Deux hits : fauche basse intérieure puis retrait de hanche ; pas de nouvelle chaîne gratuite. |
| Air après1hit aérien | Premier hit air : paume courte de côté ; vers adversaire = pousser, away = rabattre au sol, side = petit croisement borné. |
| Launcher | Paume montante sous garde ouverte, élévation faible mais suffisante pour une poursuite. |
| Air continuation | Une paume aérienne puis frappe de tranche descendante ; pas jonglage de shuriken infini. |
| Finisher | Paume de recul couverte d’un unique lancer ; le lancer remplace la fin, ne recommence pas L1. |
| Wall / sortie de mur | Près du mur : déviation contre l’épaule et recul de face ; le ricochet d’outil reste une signature. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Main gauche intercepte ; paume droite traverse court vers épaule, bassin avance0.5 puis se retire. Portée3.5 ; anticipation calme mais visible ; récupération ouverte si whiff.

**A/C/R de départ pour Heavy : .24/.07/.34s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bloque d’une main, esquive en déplaçant la ligne des épaules, contre paume après Read réussi ; revenir à portée de shuriken. Substitution = système commun, aucune double invulnérabilité.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Shuriken présents dans la main libre dès les Lights. Un lancer couvert est une sortie choisie ; pas pluie automatique à chaque contact.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Lecture Sharingan | Technique1, stance brève | Main gauche invite, tête ne bouge presque pas | Lit une attaque frontale et donne une seule riposte | Feinte, saisie ou attente battent la lecture | Riposte paume ou sortie, pas les deux |
| Géométrie des shuriken | Outil/cancel existant | Main droite lance, gauche guide un second angle | Deux trajectoires provoquent un détour/ricochet | Corps mobile et couverture du décor | Le tir de flanc peut ouvrir, jamais auto-confirmer un combo de corps |
| Katon de fermeture | Signature feu choisie | Un signe bref, pied arrière ancré | Coupe une ligne de fuite après retrait | Canalisation punissable, esquive latérale | Remplace le finisher, pas une couche permanente |

## 10. Awakening / état spécial

Lecture focalisée : une défense réussie permet une sortie d’angle couverte, pas défense automatique. Conserver GuardRead/WhiffRead s’ils remplissent cette règle ; aucune capacité Mangekyō ajoutée.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Économie du torse.
- Une main reste disponible.
- Aucun tour complet sans raison.
- Feinte identifiable au ralenti.
- Regard précède déplacement.
- Pose calme après impact.
- Le shuriken quitte réellement les doigts.

L’animateur livre préparation/contact/reprise et appuis, pas seulement une pose spectaculaire. Un calage sur les phases communes est permis ; importer exactement la chaîne visible d’un autre fighter ne l’est pas. Les lames/volumes suivent leur source ; le mouvement caméra n’ajoute pas d’impact fictif.

## 12. Hooks futurs — hors V1

| Système futur | Extension réservée, sans la construire maintenant |
|---|---|
| Chakra | Coût/état de l’action et source du contact exposés ; infusion/économie globale finales ultérieures. |
| Nature / propriété | Tag de contact et point d’origine séparés du clip ; nature ≠ forme/dōjutsu/corps. Ne pas ajouter toutes les affinités adultes. |
| Outils | Fenêtres de main libre, départ et fin du lancer déjà lisibles ; variété/maîtrise globales ultérieures. |
| Armes | Attaches fixes/configurations V1 déclarées ; aucun inventaire, loot ou moteur universel d’armes. |
| Arbre | Identifiants stables des actions ; l’identité fondamentale ne sera jamais retirée pour la vendre en nœuds. Aucun arbre dessiné ici. |
| Maîtrise | Événements qualifiés existants pourront être lus plus tard ; zéro XP/compteur/règle d’acquisition ajouté à la V1. |

## A. Animation reuse matrix — part locale

Famille de base : **F1 lecture compacte**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 déviation ; L2 paume ; L3 retrait couvert ; Heavy paume traversante ; transition Read→riposte.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P2**, lot proposé **L2-A** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Read/ricochet/genjutsu déjà là ; jabs/kick Mirage et héritages air restent trop brawler → mains de contrôle, invitation/réponse visible.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L2-A** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
