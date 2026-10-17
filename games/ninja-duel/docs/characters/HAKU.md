# Haku — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Mirror`**, âge affiché15 ; mouvement/clip effectif `Mirage`, armes déclarées `shuriken`. Techniques présentes : `WaterNeedles`, `MirrorStep`, `IceMirrors`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`IceSlide`, up=`Launcher`. [Données](../../src/Shared/Wave1.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Ring/ZoneFree et dôme réels, corps Mirage avec senbon comme outils surtout → glace et précision dans les déplacements/contacts ordinaires.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. [Source officielle des miroirs](https://naruto-official.com/fr/anime/naruto1/list/01_238) ; [source secondaire Eau/Vent](https://naruto.fandom.com/wiki/Haku), période de chaque détail à confirmer. Exclusions/point de période : Réseau de miroirs physiques cassables/HP : candidat historique, pas implémenté ni demandé pour cette passe. Aucun gel/stun infini.

**Tenue/silhouette :** Kimono/tunique vert doux avec bord clair, longs cheveux noirs attachés, masque de chasseur selon choix de visibilité ; senbon aux doigts, gestes fins.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Coudre les angles avec senbon, petits appuis de glace et sorties de miroir, sans devenir un mage immobile.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Doigts tiennent senbon, bras près du corps. |
| Jambes / centre de gravité | Pied avant léger, centre souple. |
| Avance | Pas glissés courts, talon effleure sol. |
| Recul | Retrait en diagonale, senbon en couverture. |
| Strafe | Pied dessine arc, corps reste trois-quarts. |
| Sprint | Course fine avec membres rapprochés. |
| Dash / rush | Petite glisse sur appui glacé, se termine en pied planté. |
| Saut | Saut léger genou bas. |
| Chute | Bras rassemblés, aiguille prête. |
| Landing | Petit pic au pied se brise, pas dalle massive. |
| Garde | Senbon/avant-bras détournent, pas bouclier géant. |
| Esquive | Déport souple, mince plaque sous pied seulement en appui. |
| Réaction légère | Épaule se dérobe au vrai hit sans annuler dégâts. |
| Réaction lourde | Glisse interrompue, genou au sol. |
| Knockdown / get-up | Chute souple puis appui de main et vrai relevé. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Droite, senbon au contact | Pique oblique vers épaule | Pas intérieur0.25, lame courte seulement | 3.1 | 0.11/0.05/0.18 | léger : Toucher précis, ne tire pas sept projectiles. |
| L2 | Gauche, paume et petit pic | Intérieur→avant-bras, pic naît au poignet | Glisse latérale0.4 sur plaque qui casse | 3.3 | 0.16/0.05/0.17 | fluide : Changer l’angle par contact. |
| L3 | Droite, senbon traversant de sortie | Épaule→extérieur pendant retrait | Pied extérieur freine, petit éclat marque appui | 3.5 | 0.19/0.06/0.28 | accent fin : Séparer sans grande frappe de pied. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : poignet prend appui, petit pic oblique soulève le pied adverse puis paume guide ; un launcher local. |
| Side après1hit | Un hit : glisse latérale et touche senbon, pic s’efface après le contact. |
| Away après2hits | Deux hits : pique basse puis retrait sur appui glacé, pas zone ralentissante infinie. |
| Air après1hit aérien | Hit air : senbon de corps, down pique dirigée au sol, side change d’angle vers miroir valide seulement si engagé. |
| Launcher | Pic unique au pied adverse + paume, pas pilier massif. |
| Air continuation | Un coup rapproché puis salve depuis miroir si vraie destination ; deux contacts air au plus. |
| Finisher | Pique de séparation ou volée de miroir selon position, pas les deux. |
| Wall / sortie de mur | Miroir peut fournir une destination locale visible, aucun point libre dans toute l’arène. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Avant-bras gauche s’appuie sur une courte pointe, main droite projette le senbon en poussée courte ; portée3.8, préparation lisible, faible poussée physique ; pas gros maillet de glace.

**A/C/R de départ pour Heavy : .25/.06/.32s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Garde fine et esquive sur appui court ; contre par angle senbon. Miroir est une destination choisie, pas invulnérabilité de dodge universelle.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Senbon aux doigts, glace sur les transitions et appuis ; aucun gel gratuit depuis une trace. Le dôme est un dispositif d’angles, pas la totalité du personnage.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Miroirs | Slot dôme existant | Signe court, mains encadrent le premier appui | Zone de destinations/angles de volée | Sortir/contourner et couvrir destination | RingStep réel, pas réseau moteur à réinventer |
| Traversée/volée | MirrorStep conservé | Corps entre/sort au plan du miroir choisi | Change origine du tir | Attendre l’arrivée, attaque de zone | Finisher ou reposition, pas deux chaînes |
| Senbon à distance | Slot aiguilles | Un bras lance pendant autre garde | Force garde/déplacement | Garde et déplacement transversal | Ouverture à confirmer |

## 10. Awakening / état spécial

ZoneFree : circulation plus libre uniquement dans son dôme, ressource/délai existants ; hors dispositif revient au corps léger.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Corps et aiguille ensemble.
- Glace petite hors signature.
- Appui se forme avant poussée.
- Le miroir a un plan d’entrée.
- Source de volée visible.
- Pas de mains de mage immobile.
- Départ et frein fluides.

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

Famille de base : **F2 fluidité / appui local**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 pique ; L2 paume/pic ; L3 sortie senbon ; Heavy appui/pique ; transition miroir.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L4-A** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Ring/ZoneFree et dôme réels, corps Mirage avec senbon comme outils surtout → glace et précision dans les déplacements/contacts ordinaires.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L4-A** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
