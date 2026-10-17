# Gaara — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Sand`**, âge affiché12 ; mouvement/clip effectif `Sand`, armes déclarées `famille native`. Techniques présentes : `SandCoffin`, `SandShuriken`, `DesertWave`. Routes : down=`Sweep`, up=`SandPillar`. [Données](../../src/Shared/Fighters.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Clips Sand et bouclier distincts déjà présents ; conserver, combler Side/Air/fin sans glisser vers un brawler.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. [Source officielle examen chûnin](https://naruto-official.com/en/news/01_1282). Exclusions/point de période : Shukaku géant, tsunami et vol libre ; capacités jeunes mais trop grandes également hors échelle, pas toutes « adultes ».

**Tenue/silhouette :** Tenue sable/brun-rouge, cheveux rouges courts, gourde volumineuse et sangle ; silhouette identifiable même de dos, bras peu mobiles.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Rester calme au centre pendant que le sable devient ses bras, sa garde et son contrôle de distance.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Bras proches ou croisés, regard direct. |
| Jambes / centre de gravité | Pieds relativement proches, centre haut immobile. |
| Avance | Petits pas lents, gourde pèse. |
| Recul | Recule droit, sable couvre l’espace. |
| Strafe | Rotation du corps lente, sable tourne avant lui. |
| Sprint | Course plus retenue que le sable. |
| Dash / rush | Glisse brève de retrait sur sable, pas rush de boxe. |
| Saut | Saut sobre aidé d’une poussée locale. |
| Chute | Bras s’ouvrent légèrement, sable accompagne. |
| Landing | Sable amortit au pied, vrai corps se stabilise. |
| Garde | Sable monte, mains commandent peu. |
| Esquive | Corps dévie peu, sable prend une place bornée. |
| Réaction légère | Si bouclier touche : corps calme ; sinon vrai sursaut. |
| Réaction lourde | Gourde tire le torse, jambes reculent. |
| Knockdown / get-up | Chute lourde avec gourde, sable n’annule pas get-up. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Sable, fouet droit | Bas de gourde→épaule extérieure | Gaara déplace seulement main droite | 7.0 | 0.22/0.08/0.26 | départ posé→fouet : Éprouver l’entrée à distance. |
| L2 | Sable, revers bas | Côté gauche→hanches | Main gauche s’ouvre, pieds restent | 7.2 | 0.24/0.08/0.23 | contretemps : Fermer la poursuite latérale. |
| L3 | Sable, paume large | Devant→torse puis repousse | Deux mains se tendent légèrement | 7.5 | 0.30/0.10/0.40 | accent lourd : Recréer distance, vrai retour du sable visible. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : sable du sol monte en pilier unique ; corps ne fait pas uppercut. |
| Side après1hit | Un hit : fouet de sable vient du flanc choisi ; Gaara pivote un pied, reste lent. |
| Away après2hits | Deux hits : sable tire au niveau chevilles puis revient vers gourde ; pas boucle d’immobilisation. |
| Air après1hit aérien | Hit air du sable : projectile court/paume depuis vrai volume ; down rabat, pas kick aérien. |
| Launcher | Pilier local élève, le corps reste au sol s’il choisit conversion à distance. |
| Air continuation | Une reprise de sable puis rabattement ; pas obligation de poursuite physique universelle. |
| Finisher | Enterrement court/repoussement selon préparation ; libère l’adversaire après fin. |
| Wall / sortie de mur | Sable pousse vers surface existante ; ne crée pas prison indéfinie au mur. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Sable se rassemble en masse près de l’épaule puis pousse en arc frontal ; portée8, main de commande presque immobile. Temps de rassemblement et retour = fenêtre de rush adverse.

**A/C/R de départ pour Heavy : .38/.10/.44s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bouclier limité et garde volontaire distincts ; sable bloque pendant que corps reste calme. Whiff/attaque exposent Gaara ; esquive de pied courte, substitution commune pas bouclier infini.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Gourde et sable présents dans tous les gestes d’attaque ; hitbox depuis le sable, pas invisible depuis poing du maître.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Cercueil court | Signature existante après setup | Main ferme, sable converge depuis sol | Saisie locale avec sortie selon règles | Esquive avant fermeture/substitution | Un finisher puis neutral |
| Vague de sable | Signature existante | Deux mains guident, pieds plantés | Coupe l’approche sans boxer | Contourner/flanc/récupération | Conversion distante limitée |

## 10. Awakening / état spécial

Pression de Shukaku locale : sable agit en partie depuis une garde brisée/contre, corps plus tendu ; ne transforme pas Gaara en géant ni en invulnérabilité.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Corps peu mobile.
- Sable a une source.
- Gourde garde son poids.
- Aucun kick générique pour finir.
- Montrer rassemblement et retour.
- Défense limitée lisible.
- Le corps réagit vraiment s’il est touché.

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

Famille de base : **F8 corps calme / volume**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 fouet ; L2 revers bas ; L3 paume sable ; Heavy masse ; transitions sable/gourde.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P3**, lot proposé **L4-B** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Clips Sand et bouclier distincts déjà présents ; conserver, combler Side/Air/fin sans glisser vers un brawler.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L4-B** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
